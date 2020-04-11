---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2020, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

-- 20200313
--  1) cresc-and-dim
-- 20200314
--  2) also legarg, for articulation
--  3) cha0 left cha1 centre cha2 right; cha3 left Ped cha4 right Ped
--  4) hairpins not just for cresc and dim, but also for pitch
--  5) sequences, not just cycles   

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '21feb2020'

local MIDI = require 'MIDI'

M.so_far = 0
M.duration = 1

------------------------------ private ------------------------------
local function warn(...)
	local a = {}
	for k,v in pairs{...} do table.insert(a, tostring(v)) end
	io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
local function die(...) warn(...);  os.exit(1) end
function qw(s)  -- t = qw[[ foo  bar  baz ]]
	local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end
local function round(x)
	if not x then return nil end
	return math.floor(x+0.5)
end

local function sigmoid(x)   -- x goes from -2 to +2, returns 0 to 1
	return 0.5 + 0.5 * (1/(1 + math.exp(0-x)) - 0.5 )/0.3808
	-- I think I also need a more curvy sigmoid ...
end

local function copy_note(note)
	return { note[1],note[2],note[3],note[4],note[5],note[6] }
end


local my_score = {
	1000,  -- ticks per beat
	{    -- first track
		{'set_tempo', 5, 1000000},
		{'patch_change', 10, 0, 0},
		{'control_change', 10, 0, 64, 0},
		{'patch_change', 10, 1, 0},
		{'control_change', 10, 1, 64, 127},
	},  -- end of first track
}

------------------------------ public ------------------------------
function M.sigmoid_scale(start_time,duration,start_note,end_note,cha,vol,leg)
	-- a new note is be issued when it changes from the current note
	-- and a dt of less than 10mS would not be allowed, and omits that note
	-- the sigmoid would go from -2 to +2,
	-- and 0..1 would be divided into (end_note-start_note) steps
	-- so I need to solve the inverse sigmoid problem, eg by brute force :-)
	local score_events = {}
	local current_event = {'note', start_time, 1, cha, start_note, vol}
	local i = 1
	local previous_time = start_time
	for time = start_time , start_time+duration , 20 do
		local sig_x = -2.0 + 4.0*(time-start_time)/duration
		local pitch_frac = sigmoid(sig_x)  --
		local pitch = round((1.0-pitch_frac)*start_note + pitch_frac*end_note)
		if pitch ~= current_event[5] then
			-- finish the current note
			current_event[3] = time - previous_time
			table.insert(score_events, copy_note(current_event))
			current_event = {'note', time, 1, cha, pitch, vol}
			previous_time = time
		end
		i = i + 1
	end
	for k,v in ipairs(score_events) do table.insert(my_score[2], v) end
	return true
end

function M.new_rise (start, finish)
	return function()   -- so_far and duration are upvalues
		local normalised_so_far = M.so_far / M.duration
		return round(start*(1.0-normalised_so_far) + finish*normalised_so_far)
	end
end

function M.new_rise_and_fall (start, middle)
	return function ()   -- so_far and duration are upvalues
		local normalised = 2.0 * M.so_far / M.duration  -- range 0.0 to 2.0
		if normalised < 1.0 then
			return round(start*(1.0-normalised) + middle*normalised)
		else -- 1.0 to 2.0
			return round(middle*(2.0-normalised) + start*(normalised-1.0))
		end
	end
end

function M.new_gen07(t)   -- (t_so_far, duration, pitch)
--[[
local my_gen07 = M.new_gen07 ({a, n1, b, n2, c, n3, .... n9, k})
	Constructs sequences from segments of straight lines; modelled
	on the Csound GEN07 routine. The a, b, c, etc are ordinate values.
	The n1, n2, n3, etc are the lengths of each segment;
	they should be integers, and they may not be negative,
	but zero is meaningful for specifying discontinuous waveforms.
	Their total will be the size, the period of the final sequence.
	The values returned by my_gen07() will be integers.
]]
    if #t%2 < 0.5 then
        warn('new_gen07: there must be an odd number of params, but were '..#t)
        return nil
    end
    local ordinates = {}; local lengths = {}; local size = 0; local i=1
    while i < #t do
        ordinates[#ordinates+1] = t[i];  i = i+1
        lengths[#lengths+1]     = t[i];  size = size + t[i];  i = i+1
    end
    ordinates[#ordinates+1] = t[i]
    if size < 0.5 then
        warn('new_gen07: size (sum of lengths) must not be zero')
        return nil
    end
    local a = {}   -- will contain one cycle of 'size' timesteps
    local i_t = 1  -- index of timestep
    for i_l = 1, #lengths do  -- for each length
        local initial = ordinates[i_l]
        local final = ordinates[i_l+1]
        for i_q = 1, lengths[i_l] do  -- for each timestep within the length
            a[i_t] = initial + (final-initial) * (i_q-1) / lengths[i_l]
            a[i_t] = round(a[i_t])
            i_t = i_t + 1
        end
    end
    return function () -- use M.so_far/M.duration like the other new_
        local i = 1 + round(size*M.so_far/M.duration) % size
        if i>#a then  -- Unnecessary. This can't happen.
			warn('i=',i, '  #a=',#a, '  size=',size,
			  '  M.so_far=',M.so_far, '  M.duration=',M.duration)
			return nil
		end
        return a[i]
    end
end

function M.new_igrand (mean,stddev)
    local already = false
    local x1, x2, y1, y2
    return function (arg)
        if arg and type(arg) == 'string' and arg == 'reset' then
            already = false ; return nil
        end
        if already then already=false ; return round(mean + stddev*y2) end
        local w
        while true do
            x1 = 2.0*math.random() - 1.0
            x2 = 2.0*math.random() - 1.0
            w  = x1*x1 + x2*x2
            if w <= 1.0 then  break end
        end
        w  = math.sqrt( -2.0*math.log(w) / w )
        y1 = x1 * w
        y2 = x2 * w
        already = true
        return round(mean + stddev*y1)
    end
end

function M.randomget(a)
    return a[ math.random(#a) ]
end

function M.rayleigh_irand(sigma)
    return round( sigma * math.sqrt(-2 * math.log(1-math.random())) )
end

-- function new_random_walk  ? and other random shapes ?

local function new_num (dtarg) -- (t_so_far, duration, pitch)
	-- used by trill and sequence ; returns a closure function
	if type(dtarg) == 'number' then
		return function() return dtarg end
	elseif type(dtarg) == 'table' then
		local dt_i = 1
		local dt_n = #dtarg
		return function ()
			local dt = dtarg[dt_i]
			dt_i = dt_i+1 ; if dt_i>dt_n then dt_i=1 end
			return dt
		end
	elseif type(dtarg) == 'function' then
		return dtarg
	end
end

function M.trill(start_time,duration,note1,note2,dtarg,cha,volarg,leg)
	local score_events = {}
	local time = start_time
	local end_time = start_time + duration
	M.so_far = 0            -- THIS SHOULD BE AN ARG TO new_num
	M.duration = duration   -- THIS SHOULD BE AN ARG TO new_num
	local dt_func  = new_num(dtarg)
	local vol_func = new_num(volarg)
	local dt, dtleg, vol
	while time < end_time do
		dt = dt_func() ; dtleg = round(dt * leg / 100) ; vol = vol_func()
		table.insert(score_events, {'note', time, dtleg, cha, note1, vol})
		time = time + dt ; M.so_far = time - start_time
		if time >= end_time then break end
		dt = dt_func() ; dtleg = round(dt * leg / 100) ; vol = vol_func()
		table.insert(score_events, {'note', time, dtleg, cha, note2, vol})
		time = time + dt ; M.so_far = time - start_time
	end
	for k,v in ipairs(score_events) do table.insert(my_score[2], v) end
	return true
end

function M.sequence(start_time,duration,note1,intervals,dtarg,cha,volarg,leg)
	-- intervals is an array of semitone increments eg {4,4,4,-9} or {5,4,-9}
	local note = note1
	local score_events = {}
	local time = start_time
	local end_time = start_time + duration
	M.so_far = 0            -- THIS SHOULD BE AN ARG TO new_num
	M.duration = duration   -- THIS SHOULD BE AN ARG TO new_num
	local i = 1
	local dt_func = new_num(dtarg)
	local vol_func = new_num(volarg)
	while time < end_time do
		local dt = dt_func()   -- SHOULD BE  (t_so_far, duration, pitch)
		local dtleg = round(dt * leg / 100)
		local vol = vol_func() -- SHOULD BE  (t_so_far, duration, pitch)
		table.insert(score_events, {'note', time, dtleg, cha, note, vol})
		note = note + intervals[i]
		time = time + dt ; M.so_far = M.so_far + dt
		i = i+1 ; if i >#intervals then i = 1 end
	end
	for k,v in ipairs(score_events) do table.insert(my_score[2], v) end
	return true
end

function M.chord(start_time,duration,notes,cha,vol)  -- volarg !
	local score_events = {}
	for i, note in ipairs(notes) do
		table.insert(score_events, {'note',start_time,duration,cha,note,vol})
	end
	for k,v in ipairs(score_events) do table.insert(my_score[2], v) end
	return true
end

function M.pedal(start_time,duration,cha)
	table.insert(my_score[2], {'control_change', start_time, cha, 64, 127})
	table.insert(my_score[2], {'control_change',start_time+duration,cha,64,0})
	return true
end

function M.add_event(event)
	if not type(event) == 'table' then
	  die('add_event: arg must be a table, not a ',type(event))
	end
	table.insert(my_score[2], event)
end

function M.write_score()
	io.stdout:write(MIDI.score2midi(my_score))
end

function M.new_score()
	my_score = {
		1000,  -- ticks per beat
		{    -- first track
			{'set_tempo', 5, 1000000},
			{'patch_change', 10, 0, 0},
			{'control_change', 10, 0, 64, 0},
			{'patch_change', 10, 1, 0},
			{'control_change', 10, 1, 64, 127},
		},  -- end of first track
	}
end

return M

--[=[

=pod

=head1 NAME

midigenerators.lua - helps in automatic generation of MIDI

=head1 AUTHOR

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 ~/mus/conlon2/conlon.lua
 http://pjb.com.au/

=cut

]=]

