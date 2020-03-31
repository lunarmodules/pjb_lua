---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2010, Peter J Billam      --
--                       www.pjb.com.au                            --
--                                                                 --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
--local S = require 'Sequence'
--S.bar()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '15sep2010'

-- require 'DataDumper'
--  http://www.pjb.com.au/comp/lua/test_se.lua
-- requires the DataDumper.lua module.

------------------------------ private ------------------------------
local function warn(str) io.stderr:write(str,'\n') end

local function die(str) io.stderr:write(str,'\n') ; os.exit(1) end

local function round(r) return(math.floor(r+0.5)) end

local function copy(t)
	local t2 = {}
	for k, v in pairs(t) do t2[k] = v end
	return t2
end

local function append(...)
	local t = {}
	for k,v in ipairs{...} do
		if type(v) == 'table' then for k2,v2 in ipairs(v) do t[#t+1] = v2 end
		else t[#t+1] = v end
	end
	return t
end

------------------------------ public ------------------------------

-- 20160510
-- NO !! this needs rewriting, using the routines in muscript_lua
-- and getting rid of this "return a fixed-size array" rubbish ...
-- I use it in panfarm and midiwaw

function M.cycle(t)
	local n = t['n'] or 16
	local i_n = 0 -- index of n
	local i_t = 0 -- index of t
	return function ()
		-- i_t = (i_t % #t) + 1
		i_t = i_t + 1
		if i_t > #t then i_t = 1 end
		i_n = i_n + 1
		if i_n > n then return nil else return t[i_t] end
	end
end

function M.leibnitz(t)
	local n = t['n'] or 16
	if 2^#t <= n then
		warn('Sequence.leibnitz: just '..#t
		.." args can't generate "..n..' terms')
		return nil
	end
	local l = {1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5}
	while #l < n do
		for i_l = 1,#l do l[#l+1] = 1 + l[i_l] end
	end
	local i_n = 0 -- index of n
	return function ()
		i_n = i_n + 1
		if i_n > n then return nil else return t[l[i_n]] end
	end
end

function M.morse_thue(t)
	local n = t['n'] or 16
	local l = {}
	for i_l = 1,#t do l[#l+1] = i_l end   -- bootstrap
	while n<0.5 or #l<n do
		local new_l = {}
		for i_l = 1,#l do
			local old = l[i_l]
			for i_t = 1,#t do
				new_l[#new_l+1] = ((old + l[i_t] - 2) % #t) + 1
			end
			l = new_l
		end
	end
	local i_n = 0 -- index of n
	return function ()
		i_n = i_n + 1
		if i_n > n then return nil else return t[l[i_n]] end
	end

end

function M.rabbit(t)
	local n = t['n'] or 21
	local previous_l = {1,2,1,1,2,1,2,1}
	local          l = {1,2,1,1,2,1,2,1,1,2,1,1,2}
	while n<0.5 or #l<n do
		local new_previous_l = copy(l)
		for i_l = 1,#l do
			for i = 1,#previous_l do
				l[#l+1] = previous_l[i]
			end
			previous_l = new_previous_l
		end
	end
	local i_n = 0 -- index of n
	return function ()
		i_n = i_n + 1
		if i_n > n then return nil else return t[l[i_n]] end
	end
end

function M.push_and_half_shift(t)
	local n = t['n'] or 9999  -- desired length of output-array
	local a = {t[1]}      -- output-array
	local b = {t[1]}  -- this iteration's addition to the output-array
	local i = 2       -- index into the input-array
	local k = #t      -- length of the input-array
	while (n > #a) do
		if i > k then break end
		table.insert(b,t[i])  -- push
		-- print("1: b= "..table.concat(b,", "))
		a = append(a,b)
		-- print("   a= "..table.concat(a,", ").."\n")
		i = i + 1
		if i > k then break end
		table.insert(b,t[i])  -- push
		table.remove(b,1)     -- shift
		-- print("2: b= "..table.concat(b,", "))
		a = append(a,b)
		-- print("   a= "..table.concat(a,", ").."\n")
		i = i + 1
	end
	while n > #a do
		-- print("3: b= "..table.concat(b,", "))
		a = append(a,b)
		-- print("   a= "..table.concat(a,", ").."\n")
		table.remove(b,1)
		-- print("4: b= "..table.concat(b,", "))
		if #b == 0 then break end
		a = append(a,b)
		-- print("   a= "..table.concat(a,", ").."\n")
		if #b == 1 then break end
	end
	if n < #a then a[n+1] = nil end
	return a
end

function M.gen07(t)
	local int = t['int'] or false
	if #t%2 < 0.5 then
		warn('Sequence.gen07: there must be an odd number of params, but were '..#t)
		return nil
	end
	local ordinates = {}; local lengths = {}; local size = 0; local i=1
	while i < #t do
		ordinates[#ordinates+1] = t[i];  i = i+1
		lengths[#lengths+1]     = t[i];  size = size + t[i];  i = i+1
	end
	ordinates[#ordinates+1] = t[i];
	if size < 0.5 then
		warn('Sequence.gen07: size (sum of lengths) must not be zero')
		return nil
	end
	local n = t['n'] or 3*size
	local a = {}   -- will contain one cycle of 'size' timesteps
	local i_t = 1  -- index of timestep
	for i_l = 1, #lengths do  -- for each length
		local initial = ordinates[i_l]
		local final = ordinates[i_l+1]
		for i_q = 1, lengths[i_l] do  -- for each timestep within the length
			a[i_t] = initial + (final-initial) * (i_q-1) / lengths[i_l]
			if int then a[i_t] = round(a[i_t]) end
			i_t = i_t + 1
		end
	end
	i_t = 0  -- reset
	return function ()
		i_t = i_t + 1
		if n>0.5 and i_t>n then return nil end
		return a[(i_t-1) % size + 1]
	end
end

function M.gen09(t)
	local size = t['n'] or 21
	local n = t['n'] or 3*size
	local min = t['min'] or -1.0
	local max = t['max'] or 1.0
	local int = t['int'] or false
	if #t%2 > 0.5 then
		warn('Sequence.gen07: there must be an even number of params, but were '..#t)
		return nil
	end
end

return M

--[=[

=pod

=head1 NAME

Sequence.lua - Reading, writing and manipulating MIDI data

=head1 SYNOPSIS

 local SEQ = require 'Sequence'

=head1 DESCRIPTION

This module offers functions:  
cycle(), leibnitz(), morse_thue(), rabbit(),
push_and_half_shift(), gen07() and gen09()
It provides at the Lua level what
http://www.pjb.com.au/midi/sequence.html
provides at the command line - and more :-)

The Morse-Thue, Leibnitz and Rabbit sequences are fractal and scale-free.

The Morse-Thue sequence, according to Schroeder, is named in honour of
the Norwegian mathematician Axel Thue (1863-1922), who introduced it in
1906 as an aperiodic, recursively computable sequence, and after Marston
Morse of Princeton (1892-1977) who discovered its significance in the
symbolic dynamics of certain nonlinear systems. The sequence for K=2
can be generated by taking the modulo 2 of the number of one-bits in
the binary nonnegative integers; or, starting with a 0, by repeatedly
applying the mapping 0 -> 0 1 and 1 -> 1 0; or by repeatedly appending
the complement. The first five stages are 0, then 0 1, then 0 1 1 0,
then 0 1 1 0 1 0 0 1, then 0 1 1 0 1 0 0 1 1 0 0 1 0 1 1 0.

With K=3 it can be generated by taking the modulo 3 of the number of
one-bits in the binary nonnegative integers; or recursively by adding
1 and then 2, modulo 3. The first three stages are 0, then 0 1 2, then
0 1 2 1 2 0 2 0 1.

The Leibnitz sequence can be generated by counting the one-bits in the
binary nonnegative integers; or by repeatedly appending the current
sequence with one added to it. The first five stages are 0, then 0 1,
then 0 1 1 2, then 0 1 1 2 1 2 2 3, then 0 1 1 2 1 2 2 3 1 2 2 3 2 3 3 4.

The Rabbit sequence (named by Schroeder) arises from Fibonacci's
rabbit-problem in the Liber Abaci (1202). The sequence can be generated by
starting with 1 and repeatedly applying the mapping 0 -> 1 and 1 -> 1 0;
or by starting with the first two stages 1, then 1 0, and then appending
to each stage the previous stage, so the next four stages are 1 0 1,
then 1 0 1 1 0, then 1 0 1 1 0 1 0 1, then 1 0 1 1 0 1 0 1 1 0 1 1 0.

The Push_and_Half_Shift sequence (my own ad-hoccery :-()
expands a smaller input-sequence (length N) into an output-sequence
about N**2 / 2

=head1 FUNCTIONS

=over 3

=item I<cycle> ({arg1,arg2,arg3,..., ['n']=16})

Outputs its array-arguments in a Cycle.
The named argument B<n> specifies the number of iterations
that will be returned before a I<nil> value; the default is 16.

=item I<leibnitz> ({arg1,arg2,arg3,..., ['n']=16})

Outputs its array-arguments in a Leibnitz sequence.  If N terms are to be
output, there must be at least enough arguments (K) so that:
2^K > N
The named argument B<n> specifies the number of iterations
that will be returned before a I<nil> value; the default is 16.

=item I<morse_thue> ({arg1,arg2,arg3,..., ['n']=16})

Outputs its array-arguments in a Morse-Thue sequence.
The named argument B<n> specifies the number of iterations
that will be returned before a I<nil> value; the default is 16.

=item I<rabbit> ({arg1,arg2, ['n']=21})

Outputs its array-arguments in a Rabbit sequence.
There must be two arguments (if there are more, the others are ignored).
The named argument B<n> specifies the number of iterations
that will be returned before a I<nil> value; the default is 21.

=item I<push_and_half_shift> ({arg1,arg2,arg3,..., ['n']=999})

Expands its arguments with a homebrew push-and-half-shift algorithm,
by repeatedly outputting a sub-block of those arguments.
The block starts with just the initial argument, and this is output.
At each stage, for as long as there are arguments left
the next argument is pushed onto to the end of the block,
and every alternate stage, the first note is shifted off the beginning;
then the block is appended to the output.

By this method,
the output starts at the first argument and ends at the last argument.
But it takes longer to make the journey:
for example, 4 arguments expand to 16, 5 expand to 19,
6 to 30, 7 to 34, and 8 to 48.

=item I<gen07> ({a, n1, b, n2, c, n3 ...., size=24, n=72, int=false})

Constructs sequences from segments of straight lines;
modelled on the Csound GEN07 routine.
The I<a, b, c, etc> are ordinate values.
The I<n1, n2, n3, etc> are the lengths of each segment;
they should be integers, and they may not be negative,
but zero is meaningful for specifying discontinuous waveforms.
Their total will be the B<size>, the period of the final sequence.

The named argument B<n> specifies the number of iterations
that will be returned before a I<nil> value;
the default is three times the B<size>.
If B<n> is zero, the iterator will not terminate.

The named argument B<int> specifies if the values
should be rounded to integers; the default is B<false>

=item I<gen09> ({pna,stra,phsa,  pnb,strb,phsb,  etc.., size=24, n=72, min=-1.0, max=1.0, int=false})

Constructs sequences by summing sine-waves;
modelled on the Csound GEN09 routine.
B<pna, pnb,> etc are the I<Partial numbers>,
relative to a fundamental that would occupy B<n> locations per cycle;
these must be positive, but do not have to be integers.

B<stra, strb,> etc are the Strengths of the partials pna, pnb etc.
There are relative strengths,
since the composite waveform may be rescaled later.
Negative values would imply phase-inversion.

B<phsa, phsb,> etc are the initial Phases of the partials pna, pnb etc,
expressed in degrees.

The named arguments B<n> and B<int> are as described in B<gen07>,
plus three new ones:

The named argument B<size> specifies the period of the cycle;
the default is 24.

The named argument B<min> specifies the minimum value
in the composite waveform; the default is -1.

The named argument B<max> specifies the maximum value
in the composite waveform; the default is +1.

=back

=head1 DOWNLOAD

This module may soon be available as a LuaRock...

The source is available in
http://www.pjb.com.au/comp/lua/Sequence.lua
for you to install in your LUA_PATH

The test script used during development is
http://www.pjb.com.au/comp/lua/test_se.lua
which requires the DataDumper.lua module.

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 "Fractals, Chaos, Power Laws", Manfred Schroeder, Freeman, 1991
 http://www.pjb.com.au/
 http://www.pjb.com.au/comp/index.html#lua
 http://www.pjb.com.au/comp/lua/Sequence.html
 http://www.pjb.com.au/comp/lua/Sequence.lua
 http://www.pjb.com.au/comp/lua/test_se
 http://www.pjb.com.au/comp/lua/MIDI.html
 http://www.pjb.com.au/midi/sequence.html
 http://www.csounds.com/
 http://www.csounds.com/manual/html/ScoreGenRef.html

=cut

]=]
