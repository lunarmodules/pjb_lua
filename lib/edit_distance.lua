---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2021, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local MM = require 'mymodule'
-- MM.foo()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '15jan2021'

------------------------------ private ------------------------------
function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end
function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end


-- default dict in /usr/share/dict/ and .gz's in /usr/share/aspell/
-- and /etc/dictionaries-common/words and /var/cache/dictionaries-common/
-- should make a copy separating the words by their lengths
-- how does ispell do it ? www.lasr.cs.ucla.edu/geoff/ispell.html
-- but lasr.cs.ucla.edu is unpingable :-(
-- aptitude search wamerican ; aptitude search iamerican ...

local function minimum (...)   -- PiL p.53
	local min = math.maxinteger
	for k,v in ipairs{...} do
		if min > v then min = v end
	end
	return min
end
local function utf8get (s, i)
	-- return utf8.codepoint(s, utf8.offset(s, i))
	return utf8.char(utf8.codepoint(s, utf8.offset(s, i)))
end

------------------------------ public ------------------------------

function M.damerau_levenshtein (a, b)
	-- https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
	local len_a = utf8.len(a)
	local len_b = utf8.len(b)
	local da = {}
	local maxdist = len_a + len_b
-- print("a = ",a,"  b =",b, "  maxdist = ", maxdist)
	local d = {[-1] = {}, [0] = {} }
	d[-1][-1] = maxdist
	for i = 0, len_a do
		d[i] = {}
		d[i][-1] = maxdist
		d[i][0] = i
		for j = 1,len_b do d[i][j] = 0 end
	end
	for j = 0, len_b do
		d[-1][j] = maxdist
		d[0][j] = j
	end
	for i = 1, len_a do
		local db = 0
		for j = 1, len_b do
			local k = da[utf8get(b,j)] or 0
			local db_tmp = db
			local cost
			if utf8get(a,i) == utf8get(b,j) then
				cost = 0
				db = j
			else
				cost = 1
			end
			d[i][j] = minimum(
				d[i-1][j-1] + cost,  -- substitution
				d[i][j-1] + 1,       -- insertion
				d[i-1][j] + 1,       -- deletion
				d[k-1][db_tmp-1] + i-k-1 + 1 + j-db_tmp-1 -- transposition
			)
-- but the transposition seems ineffective, it gets handled as 2 substitutions
-- I think I've confused it with the OSA-algorithm ... if utf8 what is Sigma ?
-- can I do da with dictionaries instead of arrays ?
		da[utf8get(a,i)] = i
		end
	end
	return d[len_a][len_b]
end

return M

--[=[

=pod

=head1 NAME

edit_distance - what it does

=head1 SYNOPSIS

 edit_distance infile > outfile

=head1 DESCRIPTION

This script calculates the Damerau-Levenshtein,  Needleman-Wunsch
or Smith-Waterman  distance

https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
gives: "this algorithm requires as an additional parameter the size of
the alphabet Sigma, so that all entries of the arrays are in [0, |Sigma|)"
Of course in utf8, the "size of the alphabet" is unclear,
so I have tried to use dictionaries ...

 algorithm DL-distance is
    input: strings a[1..length(a)], b[1..length(b)]
    output: distance, integer
    
    da := new array of |Sigma| integers
    for i := 1 to |Sigma| inclusive do
        da[i] := 0
    
    let d[−1..length(a), −1..length(b)]
    // d is a 2-D array of integers, dimensions length(a)+2, length(b)+2
    // note that d has indices starting at −1,
    // while a, b and da are one-indexed.
    
    maxdist := length(a) + length(b)
    d[−1, −1] := maxdist
    for i := 0 to length(a) inclusive do
        d[i, −1] := maxdist
        d[i, 0] := i
    for j := 0 to length(b) inclusive do
        d[−1, j] := maxdist
        d[0, j] := j
    
    for i := 1 to length(a) inclusive do
        db := 0
        for j := 1 to length(b) inclusive do
            k := da[b[j]]
            db_tmp := db
            if a[i] = b[j] then
                cost := 0
                db := j
            else
                cost := 1
            d[i, j] := minimum(
                d[i−1, j−1] + cost,  //substitution
                d[i,   j−1] + 1,     //insertion
                d[i−1, j  ] + 1,     //deletion
                d[k−1, db_tmp−1] + (i−k−1)+1+(j-db_tmp−1)) // transposition
        da[a[i]] := i
    return d[length(a), length(b)]


=head1 ARGUMENTS

=over 3

=item I<-v>

Print the Version

=back

=head1 DOWNLOAD

This at is available at

=head1 AUTHOR

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 https://en.wikipedia.org/wiki/Levenshtein_distance
 https://en.wikipedia.org/wiki/Damerau%E2%80%93Levenshtein_distance
 https://pjb.com.au/

=cut

]=]
