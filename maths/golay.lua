#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2021, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '9may2021'
local Synopsis = [[
golay [options] [filenames]
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

local function printf (...) print(string.format(...)) end

function str2bin (str)
	local arr = { string.byte(str,1,-1) }   -- PiL p.34
	local num = 0
	for i,v in ipairs(arr) do
		if v == 48 then
			num = (num<<1)
		elseif v == 49 then
			num = (num<<1) | 1
--		else
--			printf('v = %d', v)
		end
	end
	-- should ignore unless 0 or 1 !
	return num
end
function bin24_2str (num)
	return string.char(
		((num>>23)&1)+48, ((num>>22)&1)+48, ((num>>21)&1)+48,
		((num>>20)&1)+48, ((num>>19)&1)+48, ((num>>18)&1)+48,
		((num>>17)&1)+48, ((num>>16)&1)+48, ((num>>15)&1)+48,
		((num>>14)&1)+48, ((num>>13)&1)+48, ((num>>12)&1)+48, 32,
		((num>>11)&1)+48, ((num>>10)&1)+48, ((num>> 9)&1)+48,
		((num>> 8)&1)+48, ((num>> 7)&1)+48, ((num>> 6)&1)+48,
		((num>> 5)&1)+48, ((num>> 4)&1)+48, ((num>> 3)&1)+48,
		((num>> 2)&1)+48, ((num>> 1)&1)+48, (num&1)+48
	)
end
function bin12_2str (num)
	return string.char(
		((num>>11)&1)+48, ((num>>10)&1)+48, ((num>> 9)&1)+48,
		((num>> 8)&1)+48, ((num>> 7)&1)+48, ((num>> 6)&1)+48,
		((num>> 5)&1)+48, ((num>> 4)&1)+48, ((num>> 3)&1)+48,
		((num>> 2)&1)+48, ((num>> 1)&1)+48, (num&1)+48
	)
end

-- img/extended_binary_Golay_code.png
EncodingMatrix = {
	0x800, 0x400, 0x200, 0x100,
	0x080, 0x040, 0x020, 0x010,
	0x008, 0x004, 0x002, 0x001,
	0x9F1, 0x4FA, 0x27D, 0x93E,
	0xC9D, 0xE4E, 0xF25, 0xF92,
	0x7C9, 0x3E6, 0x557, 0xAAB,
}
DecodingMatrix = {
	0x8009F1, 0x4004FA, 0x20027D, 0x10093E,
	0x080C9D, 0x040E4E, 0x020F25, 0x010F92,
	0x0087C9, 0x0043E6, 0x002557, 0x001AAB,
}
--NonAdjacentFaces = { {1,4,5,6,7,8,12}, {2,5,6,7,8,9,11},
--	{3,6,7,8,9,10,12}, -- etc }
NonAdjacentFaces = {   -- for giam.southernct.edu's decoding-check
	0x8009F1, 0x4004FA, 0x20027D, 0x10093E,
	0x80C9D,   0x40E4E,  0x20F25,  0x10F92,
	0x87C9,     0x43E6,   0x2557,   0x1AAB,
}
AdjacentFaces = {
	(~0x9F1)&0xFFF, (~0x4FA)&0xFFF, (~0x27D)&0xFFF, (~0x93E)&0xFFF,
	(~0xC9D)&0xFFF, (~0xE4E)&0xFFF, (~0xF25)&0xFFF, (~0xF92)&0xFFF,
	(~0x7C9)&0xFFF, (~0x3E6)&0xFFF, (~0x557)&0xFFF, (~0xAAB)&0xFFF,
}
--for i,v in ipairs(EncodingMatrix) do
--	printf('EncodingMatrix[%2d] = %s', i, bin12_2str(EncodingMatrix[i]))
--end
--for i,v in ipairs(DecodingMatrix) do
--	printf('DecodingMatrix[%2d] = %s', i, bin24_2str(DecodingMatrix[i]))
--end
OppositeFaces = {6,7,8,9,10,1,2,3,4,5,12,11}

function hamming_weight_24 (u)
	return ((u>>23) & 1) + ((u>>22) & 1) + ((u>>21) & 1) + ((u>>20) & 1)
		 + ((u>>19) & 1) + ((u>>18) & 1) + ((u>>17) & 1) + ((u>>16) & 1)
		 + ((u>>15) & 1) + ((u>>14) & 1) + ((u>>13) & 1) + ((u>>12) & 1)
		 + ((u>>11) & 1) + ((u>>10) & 1) + ((u>>9) & 1) + ((u>>8) & 1)
	     + ((u>>7) & 1) + ((u>>6) & 1) + ((u>>5) & 1) + ((u>>4) & 1)
	     + ((u>>3) & 1) + ((u>>2) & 1) + ((u>>1) & 1) + (u & 1)
end
function hamming_weight_12 (u)
	return ((u>>11) & 1) + ((u>>10) & 1) + ((u>>9) & 1) + ((u>>8) & 1)
	     + ((u>>7) & 1) + ((u>>6) & 1) + ((u>>5) & 1) + ((u>>4) & 1)
	     + ((u>>3) & 1) + ((u>>2) & 1) + ((u>>1) & 1) + (u & 1)
end

function golay_encode (array12)
	-- https://giam.southernct.edu/DecodingGolay/encoding.html
	-- but in a different numbering-order
	local crypt24 = 0
	for i,val in ipairs(EncodingMatrix) do
		crypt24 = crypt24 | ((hamming_weight_12(val&array12)) % 2) << (24-i)
	end
	return crypt24
end

function are_adjacent(face1, face2)
	local non_adjacency = NonAdjacentFaces[face1]
	local magic_bit = non_adjacency>>(12-face2) & 1
	return magic_bit == 0
end
--for j = 1,12 do
--	printf('are_adjacent(1,%2d) = %s', j, tostring(are_adjacent(1, j)))
--end

function faces2mask(array_of_faces)
	local mask = 0
	for i,facenum in ipairs(array_of_faces) do
		mask = mask | (1 << (12-facenum))
	end
	return mask
end

function decoding_check (crypt24, i)
  -- A decoding check is made in very nearly the same way as a parity check.
  -- We place the mask over each face of the dodecahedron and count the
  -- parity of the information positions that are visible outside of it,
  -- we then add the parity check symbol that is visible in the center
  -- of the mask.  If this parity (counting 7 information positions
  -- and a single parity position) is even, the decoding check has passed,
  -- if odd, it has failed. Clearly, if no errors at all are introduced,
  -- all of the decoding checks will pass.
	local hw = hamming_weight_24(crypt24 & NonAdjacentFaces[i])
	return hw%2
end
function golay_decode (crypt24)
  -- https://giam.southernct.edu/DecodingGolay/decoding.html
  -- valid code words have Hamming weights of 0, 8, 12, 16, or 24.
	local hw = hamming_weight_24(crypt24)
	local failed_checks = {}
	local passed_checks = {}
	for i = 1, 12 do
		if decoding_check(crypt24,i)==1 then
			table.insert(failed_checks,i)
		else
			table.insert(passed_checks,i)
		end
	end
	if #failed_checks == 0 then
		print('passed all decoding checks')
	else
		printf("failed decoding checks %s", table.concat(failed_checks, ","))
	end
	-- https://giam.southernct.edu/DecodingGolay/decoding.html
	if     #failed_checks == 7 then   -- Parachute
		local adjacent = 0xFFFFFF
		for tmp,i_passed in ipairs(passed_checks) do
			adjacent = adjacent & (0xFFFFFF ~ NonAdjacentFaces[i_passed])
		end
		crypt24 = crypt24 ~ adjacent  -- it works !!
	elseif #failed_checks == 10 then -- Tropics (information block)
		if OppositeFaces[passed_checks[1]] == passed_checks[2] then
			crypt24 = crypt24 ~
			  (1<<(12-passed_checks[1]) | 1<<(12-passed_checks[2]))
		else
			printf('unsuported pair of passes %s :-)',
			  table.concat(passed_checks, ","))
		end
	elseif #failed_checks == 9 then  -- Cage or Deep-Bowl (information block)
		local  a1 = AdjacentFaces[passed_checks[1]]
		local  a2 = AdjacentFaces[passed_checks[2]]
		local  a3 = AdjacentFaces[passed_checks[3]]
		local na1 = NonAdjacentFaces[passed_checks[1]]
		local na2 = NonAdjacentFaces[passed_checks[2]]
		local na3 = NonAdjacentFaces[passed_checks[3]]
		if are_adjacent(passed_checks[1], passed_checks[2]) and
		   are_adjacent(passed_checks[1], passed_checks[3]) and
		   are_adjacent(passed_checks[2], passed_checks[3]) then  -- Deep-Bowl
			crypt24 = crypt24 ~ (a1 & na2 & na3)
			crypt24 = crypt24 ~ (na1 & a2 & na3)
			crypt24 = crypt24 ~ (na1 & na2 & a3)
		elseif not are_adjacent(passed_checks[1], passed_checks[2]) and
               not are_adjacent(passed_checks[1], passed_checks[3]) and
               not are_adjacent(passed_checks[2], passed_checks[3]) then
			crypt24 = crypt24 ~ (a1 & na2 & na3)   -- Cage, same calculation!
			crypt24 = crypt24 ~ (na1 & a2 & na3)
			crypt24 = crypt24 ~ (na1 & na2 & a3)
		end
	elseif #failed_checks == 6 then  -- Diaper, Bent-Ring
		-- Diaper has 6 failed_checks, 4 with 2 neighbors, 2 with 3 neighbours
		-- Bent-Ring has 6 failed_checks all holding hands in a ring
		local failed = faces2mask(failed_checks)
		local is_a_bent_ring = true
		local with_2_adjacent = {}
		local with_3_adjacent = {}
		for i,v in ipairs(failed_checks) do
--printf('failed            = %s', bin12_2str(failed))
--printf('AdjacentFaces[%2d] = %s', v, bin12_2str(AdjacentFaces[v]))
--printf('failed and adjac  = %s', bin12_2str(failed & AdjacentFaces[v]))
--printf('hamming_weight = %d', hamming_weight_12(failed & AdjacentFaces[v]))
			local neighbors =  hamming_weight_12(failed & AdjacentFaces[v])
			if neighbors ~= 2 then is_a_bent_ring = false end
			if neighbors == 2 then table.insert(with_2_adjacent, v)
			elseif neighbors == 3 then table.insert(with_3_adjacent, v)
			end
		end
		if #with_2_adjacent == 4 and #with_3_adjacent == 2 then
			crypt24 = crypt24 ~ faces2mask(with_3_adjacent)
		elseif is_a_bent_ring then
			local passed = faces2mask(passed_checks)
			-- 2 passed faces have 3 passed neighbors ;
			-- their mutual neighbors are in error !
			local two_passed_neighbors = {}
			for i,v in ipairs(passed_checks) do
				if hamming_weight_12(passed & AdjacentFaces[v]) == 2 then
					table.insert(two_passed_neighbors, v)
				end
--printf('two_passed_neighbors = %s', table.concat(two_passed_neighbors,','))
			end
--printf("passed decoding checks %s", table.concat(passed_checks, ","))
			crypt24 = crypt24 ~ faces2mask(two_passed_neighbors)
		end
	elseif #failed_checks == 5 then  -- Cobra, Islands or Broken-Tripod
		local  a1 = AdjacentFaces[failed_checks[1]]
		local  a2 = AdjacentFaces[failed_checks[2]]
		local  a3 = AdjacentFaces[failed_checks[3]]
		local na1 = NonAdjacentFaces[failed_checks[1]]
		local na2 = NonAdjacentFaces[failed_checks[2]]
		local na3 = NonAdjacentFaces[failed_checks[3]]
		
		-- 3 errors, but all in information positions
	end
	
	local plain12 = 0
	for i,val in ipairs(DecodingMatrix) do
		-- 20210512 confused about why this is hamming_weight_12 here ...
		plain12 = plain12 | ((hamming_weight_12(val&crypt24)) % 2) << (12-i)
	end
	return plain12
end

n = str2bin('101010110110')
printf('   n    = %s', bin12_2str(n))
local crypt_n = golay_encode(n)
printf('crypt_n = %s', bin24_2str(crypt_n))
-- print('should pass all decoding checks ...')
local plain12 = golay_decode(crypt_n)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

print('One error in the information block:')
corrupt = crypt_n ~ (2<<15)
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

print('Two errors in the information block:')
corrupt = crypt_n ~ (5<<13)
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

print('Three errors in the information block:')
corrupt = crypt_n ~ (21<<13)
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

print('One error in the checksum block in a Parachute:')
corrupt = crypt_n ~ (2<<5)
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

-- What if 2 or 3 errors are introduced? We will first consider the
-- possibility (mostly to dispose of it quickly!) that the errors are in
-- parity check symbols. If that is the case we will simply have a partial
-- dodecahedron consisting of 2 or 3 pentagons, and we will know that
-- parity check symbol errors have occurred in those same positions.

print('Two errors in the checksum block on opposite faces in a Tropics:')
corrupt = crypt_n ~ (33<<4)
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

print('Two errors in the checksum block in a Diaper:')
corrupt = crypt_n ~ 12  -- 9,10
printf('crypt_n = %s', bin24_2str(crypt_n))
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

print('Two errors in the checksum block in a Bent-Ring:')
corrupt = crypt_n ~ 9  -- 9,12
printf('crypt_n = %s', bin24_2str(crypt_n))
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

print('Three errors in the checksum block in a Deep-Bowl:')
corrupt = crypt_n ~ (1<<7 | 1<<3 | 1)  -- 5,9,12
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)

print('Three errors in the checksum block in a Cage:')
corrupt = crypt_n ~ 21  -- 8,10,12
printf('corrupt = %s', bin24_2str(corrupt))
local plain12 = golay_decode(corrupt)
if plain12 == n then errmsg = '' else errmsg = 'WRONG!' end
printf('plain12 = %s %s\n', bin12_2str(plain12), errmsg)


--[=[

=pod

=head1 NAME

 golay.lua  -- tests the extended Golay code G24 using lua bit-ops

=head1 SYNOPSIS

 golay.lua

=head1 DESCRIPTION

This script tests the encoding and decoding with the extended Golay code G24
using the Generator Matrix given in
https://en.wikipedia.org/wiki/Binary_Golay_code

So far (20210514)
it will detect and correct up to 3 errors in the information block,
or 1 error in the checksum block.

When fully implemented, any
3-bit errors can be corrected or any 7-bit errors can be detected.

=head1 ARGUMENTS

=over 3

=item I<-v>

Print the Version

=back

=head1 DOWNLOAD

This script is available at /home/pjb/lua/maths/golay.lua

=head1 AUTHOR

Peter J Billam, https://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 https://en.wikipedia.org/wiki/Binary_Golay_code
 https://en.wikipedia.org/wiki/Hamming_distance
 https://en.wikipedia.org/wiki/Hamming_weight
 https://giam.southernct.edu/DecodingGolay/introduction.html
 https://giam.southernct.edu/DecodingGolay/encoding.html
 https://giam.southernct.edu/DecodingGolay/decoding.html
 https://giam.southernct.edu/DecodingGolay/example.html
 https://giam.southernct.edu/DecodingGolay/generalizations.html
 https://giam.southernct.edu/DecodingGolay/conclusions.html
 https://giam.southernct.edu/DecodingGolay/references.html
 V. Pless, Introduction to the Theory of Error-Correcting Codes,
   second edition, Wiley, New York, 1989.
 V. Pless, Decoding the Golay codes,
   IEEE Trans. Info. Theory 32 (1986), 561-567. 
 https://pjb.com.au/

=cut

]=]
