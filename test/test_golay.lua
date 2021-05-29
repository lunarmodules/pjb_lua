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
  test_golay.lua
]]
local G = require 'golay'

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
require 'DataDumper'

local function printf (...) print(string.format(...)) end


local i_test = 0;  local Failed = 0
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
function finish()
	if     Failed == 0 then print('passed all tests') ; os.exit(0)
	elseif Failed == 1 then print('1 test failed') ; os.exit(1)
	elseif Failed  > 1 then printf('%d tests failed', Failed) ; os.exit(1)
	else print('Failed =', Failed)
	end
end


-- TESTS
n = G.str2bin('101010110110')
-- printf('   n    = %s', bin12_2str(n))
local crypt_n = G.golay_encode(n)
local plain12 = G.golay_decode(crypt_n)
ok(plain12 == n, 'golay_encode and golay_decode')

corrupt = crypt_n ~ (2<<15)
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'one error in the message block')

corrupt = crypt_n ~ (5<<13)
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'two errors in the message block')

corrupt = crypt_n ~ (21<<13)
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'three errors in the message block')

corrupt = crypt_n ~ (1<<(12-6))
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'one error in the skydiver checksum in a Parachute')

corrupt = crypt_n ~ (1<<(12-7))
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'one checksum error in the open in a Parachute')

corrupt = crypt_n ~ (1<<(12-11))
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'one checksum error in the fringe in a Parachute')

corrupt = crypt_n ~ (1<<(12-1))
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'one checksum error in the top in a Parachute')

corrupt = crypt_n ~ (2<<5 | 2<<17)
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute with message failure in the skydiver face')

corrupt = crypt_n ~ (2<<5 | 2<<22)
plain12 = G.golay_decode(corrupt)
ok(plain12 == n,
  'Parachute with message failure in the face opposite the skydiver')

corrupt = crypt_n ~ (2<<5 | 2<<23)   -- or 15,16,18,19,23
plain12 = G.golay_decode(corrupt)
ok(plain12 == n,
  'Parachute with message failure in a face adjacent to skydiver')

corrupt = crypt_n ~ (2<<5 | 2<<21)   -- or 15,16,18,19,23
plain12 = G.golay_decode(corrupt)
ok(plain12 == n,
  'Parachute with message failure in a face in the parachute fringe')

corrupt = crypt_n ~ (2<<5 | 1<<18 | 1<<23 )
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute + 2 message failures in the skydiver and top')

corrupt = crypt_n ~ (2<<5 | 1<<18 | 1<<22 )
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute + 2 message failures in the skydiver and fringe')

corrupt = crypt_n ~ (2<<5 | 1<<18 | 1<<17 )
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute + 2 message failures in the skydiver and open')

corrupt = crypt_n ~ (2<<5 | 1<<23 | 1<<14 )
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute + 2 message failures in top and fringe')

corrupt = crypt_n ~ (2<<5 | 1<<23 | 1<<16 )
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute + 2 message failures in top and open')

-- these two-failures-in-open-and-fringe case all seem to just pass !? :-)
corrupt = crypt_n ~ (1<<23 | 2<<16 | 1<<14 )
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute + 2 neighbouring failures in open and fringe')
corrupt = crypt_n ~ (1<<23 | 2<<16 | 1<<22 )
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute + 2 non-neighbour failures in open and fringe')
corrupt = crypt_n ~ (1<<23 | 2<<16 | 1<<21 )
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Parachute + 2 opposite failures in open and fringe')

corrupt = crypt_n ~ (33<<4)
plain12 = G.golay_decode(corrupt)
ok(plain12 == n,
  'two errors in the checksum block on opposite faces in a Tropics')

corrupt = crypt_n ~ (33<<4 | 1<<16)
plain12 = G.golay_decode(corrupt)
ok(plain12 == n,
  'Tropics with a message failure in one of the poles')

corrupt = crypt_n ~ (33<<4 | 1<<13)
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Tropics with a message failure on the equator')

corrupt = crypt_n ~ (1<<3 | 1<<2)  -- 12  -- 9,10
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'two errors in the checksum block in a Diaper')

corrupt = crypt_n ~ (1<<17 | 1<<3 | 1<<2)  -- + 7, 9,10
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Diaper with a message failure in an adj=2 face')

corrupt = crypt_n ~ (1<<14 | 1<<3 | 1<<2)  -- + 10, 9,10
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Diaper with a message failure in an adj=3 face')

corrupt = crypt_n ~ (1<<16 | 1<<3 | 1<<2)  -- + 8, 9,10
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Diaper with a message failure in a waistline face')

corrupt = crypt_n ~ (1<<20 | 1<<3 | 1<<2)  -- + 4, 9,10
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Diaper with a message failure in a head|foot face')

corrupt = crypt_n ~ (1<<18 | 1<<3 | 1<<2)  -- + 6, 9,10
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Diaper with a message failure in a elbow|knee face')

corrupt = crypt_n ~ 9  -- 9,12
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'two errors in the checksum block in a Bent-Ring')

corrupt = crypt_n ~ (9 | 1<<19)  -- + 5, 9,12
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Bent-Ring with a message failure in an inside face')

corrupt = crypt_n ~ (9 | 1<<15)  -- + 9, 9,12
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Bent-Ring with a message failure in a checksum-error face')

corrupt = crypt_n ~ (9 | 1<<14)  -- + 10, 9,12
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Bent-Ring with a message failure in a shoulder face')

corrupt = crypt_n ~ (9 | 1<<13)  -- + 11, 9,12
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Bent-Ring with a message failure in a points-in face')

corrupt = crypt_n ~ (9 | 1<<16)  -- + 8, 9,12
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'Bent-Ring with a message failure in a points-out face')

corrupt = crypt_n ~ 21  -- 8,10,12
local plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'three errors in the checksum block in a Cage')

corrupt = crypt_n ~ (1<<9 | 1<<8 | 1<<1)  -- 3,4,11
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'three errors in the checksum block in a Cobra')

corrupt = crypt_n ~ (1<<9 | 1<<6 | 1<<1)  -- 3,6,11
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'three errors in the checksum block in a Islands')

corrupt = crypt_n ~ (1<<10 | 1<<1 | 1)  -- 2,11,12
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'three errors in the checksum block in a Broken-Tripod')

corrupt = crypt_n ~ (1<<7 | 1<<3 | 1)  -- 5,9,12
plain12 = G.golay_decode(corrupt)
ok(plain12 == n, 'three errors in the checksum block in a Deep-Bowl')

function enc_dec_all_possible_plaintexts()
	for p = 0,4095 do
		local c = G.golay_encode(p)
		if G.golay_decode(c) ~= p then return false end
	end
	return true
end
ok(enc_dec_all_possible_plaintexts(),
  'encode and decode all possible plaintexts')

function all_one_bit_errors()
	for i = 1, 24 do
		local corrupt = crypt_n ~ (1<<(24-i))
		local plain12 = G.golay_decode(corrupt)
		if plain12 ~= n then
			printf('i = %d   corrupt = %s   plain12 = %s',
			  i, bin24_2str(corrupt), bin12_2str(plain12))
			return false
		end
	end
	return true
end
ok(all_one_bit_errors(), 'all possible single-bit errors')

function all_two()
	for i = 1, 23 do
		local corrupt1 = crypt_n ~ (1<<(24-i))
		for j = i+1, 24 do 
			local corrupt2= corrupt1 ~ (1<<(24-j))
			local plain12 = G.golay_decode(corrupt2)
			if plain12 ~= n then
				printf('  i=%d j=%d  corrupt2 = %s   plain12 = %s',
				  i, j, bin24_2str(corrupt2), bin12_2str(plain12))
				return false
			end
		end
	end
	return true
end
ok(all_two(), 'all possible two-bit errors')

function all_three()
	for i = 1, 23 do
		local corrupt1 = crypt_n ~ (1<<(24-i))
		for j = i+1, 24 do 
			local corrupt2= corrupt1 ~ (1<<(24-j))
			for k = j+1, 24 do 
				local corrupt3= corrupt2 ~ (1<<(24-k))
				local plain12 = G.golay_decode(corrupt2)
				if plain12 ~= n then
					printf('  i=%d j=%d k=%d   corrupt3=%s   plain12=%s',
				  	i, j, k, bin24_2str(corrupt3), bin12_2str(plain12))
					return false
				end
			end
		end
	end
	return true
end
ok(all_three(), 'all possible three-bit errors')

local s1 = 'ABCXYZ'
local b1 = G.str2msgblocks(s1)
local co = G.msgblocks2golayblocks(b1)
local b2 = G.golayblocks2msgblocks(co)
local s2 = G.msgblocks2str(b2)
ok(s1 == s2, 'str2msgblocks and msgblocks2str')
-- XXXX

finish()


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
it will detect and correct up to 3 errors in the message block,
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
 https://gcc.gnu.org/onlinedocs/gcc/Using-Assembly-Language-with-C.html
 https://pjb.com.au/

=cut

]=]
