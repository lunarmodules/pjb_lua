#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2021, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '8jan2021'
local Synopsis = [[
program_name [options] [filenames]
]]
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

ED = require('edit_distance')

local Test = 73 ; local i_test = 0; local Failed = 0;
function ok(b,s)
    i_test = i_test + 1
    if b then
        io.write('ok '..i_test..' - '..s.."\n")
        return true
    else
        io.write('not ok '..i_test..' - '..s.."\n")
        Failed = Failed + 1
        return false
    end
end
function summary()
	if     Failed == 0 then print("passed all tests :-)")
	elseif Failed == 1 then print("failed 1 test")
	else   print("failed "..Failed .." tests" )
	end
end

ok(ED.damerau_levenshtein("gloop", "gloop") == 0, "no change")
ok(ED.damerau_levenshtein("gloop", "golop") == 1, "exchange")
ok(ED.damerau_levenshtein("gloop", "bloop") == 1, "substitution")
ok(ED.damerau_levenshtein("gloop", "gl0op") == 1, "substitution")
ok(ED.damerau_levenshtein("gloop", "glop")  == 1, "deletion")
ok(ED.damerau_levenshtein("gloop","gloopx") == 1, "addition")
ok(ED.damerau_levenshtein("CA", "ABC")      == 2, "addition and exchange")
ok(ED.is_a_word('ever'), "ever is a word")
ok(not ED.is_a_word('xvfr'), "xvfr is not a word")
ok(ED.candidates('ever') == 'ever', "candidates() thinks ever is a word")
local t = ED.candidates('evex')
ok(type(t) == 'table',
  "candidates('evex') returns {'"..table.concat(t, "','").."'}"
)
local t = ED.candidates('oo')
ok(type(t) == 'table',
  "candidates('oo') returns {'"..table.concat(t, "','").."'}"
)
local t = ED.candidates('xvfr')
ok(type(t) == 'table' and #t == 0, "candidates('xvfr') returns {}")
summary()
-- for i,v in ipairs(ED.test_load_words()) do print(v) end

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
