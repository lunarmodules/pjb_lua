#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2020, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '20feb2020'
local Synopsis = [[
program_name [options] [filenames]
]]
gmp = require "gmp"
local iarg=1; while arg[iarg] ~= nil do
	if not string.find(arg[iarg], '^-[a-z]') then break end
	local first_letter = string.sub(arg[iarg],2,2)
	if first_letter == 'v' then
		print('libgmp version '..gmp.version)
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

print('See: lynx /home/ports/lgmp/lgmp.htm')
print('     lynx http://gmplib.org/manual')

local Test = 14 ; local i_test = 0; local Failed = 0;
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

-- create two gmp integers
x = gmp.z(123)
y = gmp.z(456)
rc = x:add(y)
if not ok(rc:cmp(gmp.z(579)) == 0, '123+456 = 579') then
    print(rc:get_str())
end
if not ok(x:cmp(gmp.z(123)) == 0, 'x was left unchanged at 123') then
    print(' x = ', x:get_str())
end
if not ok(y:cmp(gmp.z(456)) == 0, 'y was left unchanged at 456') then
    print(' y = ', y:get_str())
end

-- for k,v in pairs(gmp) do print(k,v) end

-- compute sum, update and return x
rc = x:add(y,x)
-- x is updated
if not ok(x:cmp(gmp.z(579)) == 0, 'x was updated to 579') then
    print(' x = ', x:get_str())
end

-- compute quotient and remainder 1	123
quotient, remainder = x:fdiv_qr(y)
if not ok(quotient:cmp(gmp.z(1)) == 0, '456/123 quotient was 1') then
    print(' quotient = ', quotient:get_str())
end
if not ok(remainder:cmp(gmp.z(123)) == 0, '456/123 remainder was 123') then
    print(' remainder = ', remainder:get_str())
end
if not ok(x:cmp(gmp.z(579)) == 0, 'x was left unchanged at 579') then
    print(' x = ', x:get_str())
end
if not ok(y:cmp(gmp.z(456)) == 0, 'y was left unchanged at 456') then
    print(' y = ', y:get_str())
end

quotient, remainder = x:fdiv_qr(y, nil, y)
if not ok(quotient:cmp(gmp.z(1)) == 0, '456/123 quotient was 1') then
    print(' quotient = ', quotient:get_str())
end
if not ok(remainder:cmp(gmp.z(123)) == 0, '456/123 remainder was 123') then
    print(' remainder = ', remainder:get_str())
end
if not ok(x:cmp(gmp.z(579)) == 0, 'x was left unchanged at 579') then
    print(' x = ', x:get_str())
end
if not ok(y:cmp(gmp.z(123)) == 0, 'y was updated to 123') then
    print(' y = ', y:get_str())
end

quotient, remainder = x:fdiv_qr(y, x, y)
if not ok(quotient:cmp(gmp.z(4)) == 0, '456/123 quotient was 4') then
    print(' quotient = ', quotient:get_str())
end
if not ok(remainder:cmp(gmp.z(87)) == 0, '456/123 remainder was 87') then
    print(' remainder = ', remainder:get_str())
end
if not ok(x:cmp(gmp.z(4)) == 0, 'x was updated to 4') then
    print(' x = ', x:get_str())
end
if not ok(y:cmp(gmp.z(87)) == 0, 'y was updated to 87') then
    print(' y = ', y:get_str())
end
-- returns nothing but updates “self”
x:addmul(y, 3)
if not ok(x:cmp(gmp.z(4 + 87*3)) == 0, 'x:addmul(y,3) set x to 265') then
    print(' x = ', rc:get_str())
end
if not ok(y:cmp(gmp.z(87)) == 0, 'y was left unchanged at 87') then
    print(' y = ', y:get_str())
end

k = gmp.z(1024)
g = k:pow(3)
if not ok(g:cmp(gmp.z(1073741824)) == 0, '1024^3 = 1073741824') then
	print(' g = ',g:get_str())
end
if not ok(g:sgn() == 1, 'sgn(g)  = 1') then
	print(' g:sgn() = ',g:sgn())
end
if not ok(gmp.z(0):sgn() == 0, 'sgn(0)  = 0') then
	print(' gmp.z(0):sgn() = ',gmp.z(0):sgn())
end
n = g:neg()   -- print(' n = ',n:get_str())
if not ok(n:sgn() == -1, 'sgn(-g) = -1') then
	print(' n:sgn() = ',n:sgn())
end

function absz(x)
	if type(x) ~= 'userdata' then x = newz(x) end
	return x:abs()
end
function addz(x,y)
	if type(x) ~= 'userdata' then x = newz(x) end
	if type(y) ~= 'userdata' then y = newz(y) end
	return x:add(y)
end
function gcdz(x,y)   -- greatest common denominator
	if type(x) ~= 'userdata' then x = newz(x) end
	if type(y) ~= 'userdata' then y = newz(y) end
	return x:gcd(y)
end
function lcmz(x,y)   -- lowest common multiple
	if type(x) ~= 'userdata' then x = newz(x) end
	if type(y) ~= 'userdata' then y = newz(y) end
	return x:lcm(y)
end
function modz(x,y)   -- x%y
	if type(x) ~= 'userdata' then x = newz(x) end
	if type(y) ~= 'userdata' then y = newz(y) end
	return x:mod(y)
end
function mulz(x,y)
	if type(x) ~= 'userdata' then x = newz(x) end
	if type(y) ~= 'userdata' then y = newz(y) end
	return x:mul(y)
end
function negz(x)
	if type(x) ~= 'userdata' then x = newz(x) end
	return x:neg()
end
function newz(x) return gmp.z(x) end
function nextprimez(x)
	if type(x) ~= 'userdata' then x = newz(x) end
	return x:nextprime()
end
function powz(z,a)   -- z^a
	if type(z) ~= 'userdata' then z = newz(z) end
	return z:pow(a)
end
function powmz(z,a,k)   -- (z^a)%k
	if type(z) ~= 'userdata' then z = newz(z) end
	if type(k) ~= 'userdata' then k = newz(k) end
	return z:powm(a,k)
end
function probab_primez(z, a)   -- z is probably a prime, default a = 10 tests
	if type(z) ~= 'userdata' then z = newz(z) end
	return z:probab_prime(a)
end
function setz(x, y)
	if type(x) ~= 'userdata' then x = newz(x) end
	if type(y) ~= 'userdata' then y = newz(y) end
	x:set(y)
	return true
end
function sgnz(x)
	if type(x) ~= 'userdata' then x = newz(x) end
	return x:sgn()
end

g = powz(1024,3)
if not ok(g:cmp(gmp.z(1073741824)) == 0, 'powz(1024,3) = 1073741824') then
	print(' g = ',g:get_str())
end
-- g = newz(1024) ; x = g:powm(3,newz(1000000))
x = powmz(1024,3,1000000)
if not ok(x:cmp(741824) == 0, 'powmz(1024,3,1000000) = 741824') then
	print(' x = ',x:get_str())
end

x = nextprimez(1000)
if not ok(x:cmp(1009) == 0, 'nextprimez(1000) = 1009') then
	print(x:get_str())
end

if not ok(sgnz(-3579) == -1, 'sgnz(-3579) == -1') then
	print(sgnz(-3579))
end
if not ok(sgnz(0) == 0, 'sgnz(0) == 0') then
	print(sgnz(0))
end
if not ok(sgnz(3579) == 1, 'sgnz(3579) == 1') then
	print(sgnz(3579))
end
if not ok(negz(3579):cmp(-3579) == 0, 'negz(3579) == -3579') then
	print(negz(3579))
end
if not ok(probab_primez(1008) == false, 'probab_primez(1008) returns false') then
	print(probab_primez(1008))
end
if not ok(probab_primez(1009) == 2, 'probab_primez(1009) returns 2') then
	print(probab_primez(1009))
end

--[[


> -- returns nothing but sets “self” to new integer value
> =x:set "123456789123456789123456789"
> =x
123456789123456789123456789

--]]

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

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://pjb.com.au/

=cut

]=]
