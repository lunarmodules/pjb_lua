#!/usr/local/bin/lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2018, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '1aug2018'
local Synopsis = [[
program_name [options] [filenames]
]]

local MIDI = require 'MIDI'


local iarg=1; while arg[iarg] ~= nil do
	if not string.find(arg[iarg], '^-[a-z]') then break end
	local first_letter = string.sub(arg[iarg],2,2)
	if first_letter == 'v' then
		local n = string.gsub(arg[0],"^.*/","",1)
		print(n.." version "..Version.."  "..VersionDate)
		os.exit(0)
	elseif first_letter == 'c' then
		whatever()
	else
		local n = string.gsub(arg[0],"^.*/","",1)
		print(n.." version "..Version.."  "..VersionDate.."\n\n"..Synopsis)
		os.exit(0)
	end
	iarg = iarg+1
end

local inptxt = [[

 e|3-0---------|--0-----0---|--3--02-02-3|---3--3--3-3|
 B|---3-0------|-----3-----0|--2---3--3-0|---0-0--12-3|
 G|------3-02-0|1----1------|------2--2-0|------------|
 D|---0-----0--|---0-----0--|---2--0-----|---3--2--1--|
 A|------------|------------|0--------0--|------------|
 E|3---x-3-----|0--x--0-----|------------|3------x----|
   G            E            Am    D      G  G7 C  Cm

 e|--0---------|--0-----0---|--3--02-02-3|---3--3--3-3|
 B|---3-0------|-----3-----0|--2---3--3-0|---0-0--12-3|
 G|------3-02-0|1----1------|------2--2-0|------------|
 D|---0-----0--|---0-----0--|---2--0-----|---3--2--1--|
 A|------------|------------|0--------0--|------------|
 E|3-----3-----|0-----0-----|------------|3-----------|
   G            E            D            D
]]

local function split(s, pattern, maxNb) -- http://lua-users.org/wiki/SplitJoin
    if not s or string.len(s)<2 then return {s} end
    if not pattern then return {s} end
    if maxNb and maxNb <2 then return {s} end
    local result = { }
    local theStart = 1
    local theSplitStart,theSplitEnd = string.find(s,pattern,theStart)
    local nb = 1
    while theSplitStart do
        table.insert( result, string.sub(s,theStart,theSplitStart-1) )
        theStart = theSplitEnd + 1
        theSplitStart,theSplitEnd = string.find(s,pattern,theStart)
        nb = nb + 1
        if maxNb and nb >= maxNb then break end
    end
    table.insert( result, string.sub(s,theStart,-1) )
    return result
end

function openstring2midipitch (string_number, strtxt)
	strtxt = string.gsub(strtxt, '^ +', '')
	local default_midipitch = { 64, 59, 55, 50, 45, 40 }
	local strtxt2midipitch = {
		-- will be octave-adjusted to fit the string's default
		A=45, ['A#']=46, Bb=46, B=47, C=48, ['C#']=49, Db=49,
		D=50, ['D#']=51, Eb=51, E=52, F=53, ['F#']=54, Gb=54,
		G=55, ['G#']=56, Ab=56, A=57, ['A#']=58, Bb=58, B=59,
		a=45, ['a#']=46, bb=46, b=47, c=48, ['c#']=49, db=49,
		d=50, ['d#']=51, eb=51, e=52, f=53, ['f#']=54, gb=54,
		g=55, ['g#']=56, ab=56, a=57, ['a#']=58, bb=58, b=59,
	}
	local default = default_midipitch[string_number]
	local openstr = strtxt2midipitch[strtxt]
	if (openstr-default)%12 == 0 then return default end
	if openstr > default then
		while true do
			local gap = openstr - default
			if gap <= 4 and gap >= -7 then return openstr end
			openstr = openstr - 12
		end
	end
	if openstr < default then
		while true do
			local gap = openstr - default
			if gap <= 4 and gap >= -7 then return openstr end
			openstr = openstr + 12
		end
	end
	return nil
end

stringnumber = 0
MsPerBar   = 2400  -- or MsPerPulse ?
MsPerPulse = 200   -- or MsPerBar ?

local my_scoretrack = {
	{'set_tempo', 5, 1000000},
	{'patch_change', 10, 1, 25},
}
local time_at_start_of_line = 15
local str2on_note = {}   -- start with no on_notes
local current_time = time_at_start_of_line

local lines = split(inptxt, '\r?\n')
for i,line in ipairs(lines) do
	if string.match(line, '^ ?[a-gA-G][b#]?|') then
		if inbetween_systems then  -- a new system
			inbetween_systems = false
			time_at_start_of_line = current_time
		else    -- a new string in the same system
			current_time = time_at_start_of_line
		end
		stringnumber = stringnumber + 1
		local strtxt,strline = string.match(line, '^ ?([a-gA-G][b#]?)(|.*)$')
		local openstring = openstring2midipitch(stringnumber,strtxt)
		for j = 1, #strline do
			local c = string.sub(strline, j, j)
			if c == '|' then
			elseif c == '-' then
				current_time = current_time + MsPerPulse
			elseif string.find(c,'[0-9]') then
				if str2on_note[stringnumber] then
					local time,  pitch =
					  table.unpack(str2on_note[stringnumber])
					table.insert(my_scoretrack,
						{'note', time, current_time - time, 1, pitch, 98}
					)
				end
				local midipitch = openstring + tonumber(c)
				str2on_note[stringnumber] = { current_time, midipitch }
				current_time = current_time + MsPerPulse
			end
		end
	else
		stringnumber = 0
		inbetween_systems = true
	end
end
for stringnumber = 1,6 do
	if str2on_note[stringnumber] then
		local time,  pitch = table.unpack(str2on_note[stringnumber])
		table.insert(my_scoretrack,
		  {'note', time, current_time - time, 1, pitch, 98}
		)
		str2on_note[stringnumber] = nil  -- not exactly necessary :-)
	end
end

io.stdout:write(MIDI.score2midi({ 1000, my_scoretrack, }))


--[=[

=pod

=head1 NAME

program_name - what it does

=head1 SYNOPSIS

 program_name infile > outfile

=head1 DESCRIPTION

This script

=head1 ARGUMENTS

=over 3

=item I<-v>

Print the Version

=back

=head1 DOWNLOAD

This at is available at

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://www.pjb.com.au/

=cut

]=]
