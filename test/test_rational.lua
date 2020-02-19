#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2019, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

RA = require 'rational'

local Version = '1.0  for Lua5'
local VersionDate  = '24feb2019'
local Synopsis = [[
program_name [options] [filenames]
]]

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

local n = 1
for i = 10001, 10101, 2 do
    if RA.is_prime(i) then
		if n%12 == 0 then print(i..',')
		else io.stdout:write(i..',')
		end
		n = n + 1
	end
end
print('')

pcall(function() rc = RA.cancel(true) end)
ok(not rc, 'cancel raises error if called with a boolean')

rc = RA.cancel(3)
if not ok(rc[1]==3 and rc[2]==0 and rc[3]==1, 'cancel(3) returns {3,0,1}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ 3, 15 })
if not ok(rc[1]==1 and rc[2]==5, 'cancel({3,15}) returns {1,5}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ 3, 2, 14 })
if not ok(rc[1]==3 and rc[2]==1 and rc[3]== 7,
  'cancel({3,2,14}) returns {3,1,7}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ 126, 189 })
if not ok(rc[1]==2 and rc[2]==3, 'cancel({126,189}) returns {2,3}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ 15, 3 })
if not ok(rc[1]==5 and rc[2]==1, 'cancel({15,3}) returns {5,1}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ 3, 14, 2 })
if not ok(rc[1]==3 and rc[2]==7 and rc[3]== 1,
  'cancel({3,14,2}) returns {3,7,1}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ 189, 126 })
if not ok(rc[1]==3 and rc[2]==2, 'cancel({189,126}) returns {3,2}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel2({ 189, 126 })
if not ok(rc[1]==3 and rc[2]==2, 'cancel2({189,126}) returns {3,2}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ 98, 294 })
if not ok(rc[1]==1 and rc[2]==3, 'cancel({98,294}) returns {1,3}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ -98, 294 })
if not ok(rc[1]==-1 and rc[2]==3, 'cancel({-98,294}) returns {-1,3}') then
	print(rc[1], rc[2], rc[3])
end
rc = RA.cancel2({ -98, 294 })
if not ok(rc[1]==-1 and rc[2]==3, 'cancel2({-98,294}) returns {-1,3}') then
	print(rc[1], rc[2], rc[3])
end
os.exit()

rc = RA.cancel({ 98, -294 })
if not ok(rc[1]==-1 and rc[2]==3, 'cancel({98,-294}) returns {-1,3}') then
	print(rc[1], rc[2], rc[3])
end

rc = RA.cancel({ -98, -294 })
if not ok(rc[1]==1 and rc[2]==3, 'cancel({-98,-294}) returns {1,3}') then
	print(rc[1], rc[2], rc[3])
end

rc = assert(RA.rat2float({ 1, 1, 2 }))
if not ok(rc == 1.5, 'rat2float({1,1,2}) returns 1.5') then
	print(rc)
end

rc = assert(RA.rat2float({ 21,6 }))
if not ok(rc == 3.5, 'rat2float({21,6}) returns 3.5') then
	print(rc)
end

rc = assert(RA.add({3,4}, {1,3}))
if not ok(rc[1]==13 and rc[2]==12, 'add({3,4},{1,3}) returns {13,12}') then
	print(table.unpack(rc))
end

rc = assert(RA.add({1,3,4}, {1,3}))
if not ok(rc[1]==25 and rc[2]==12, 'add({1,3,4},{1,3}) returns {25,12}') then
	print(table.unpack(rc))
end

rc = assert(RA.add({3,4}, {1,3}, {-2,4}))
if not ok(rc[1]==7 and rc[2]==12, 'add({3,4},{1,3},{-2,4}) returns {7,12}') then
	print(table.unpack(rc))
end

rc = assert(RA.sub({3,4}, {1,3}))
if not ok(rc[1]==5 and rc[2]==12, 'sub({3,4},{1,3}) returns {5,12}') then
	print(table.unpack(rc))
end

rc = assert(RA.inv({1,3,4}))
if not ok(rc[1]==4 and rc[2]==7, 'inv({1,3,4}) returns {4,7}') then
	print(table.unpack(rc))
end

rc = assert(RA.neg({1,3,4}))
if not ok(rc[1]== -7 and rc[2]==4, 'neg({1,3,4}) returns {-7,4}') then
	print(table.unpack(rc))
end

rc = assert(RA.mul({1,3,4}, {1,3}, {6,5}))
if not ok(rc[1]==7 and rc[2]==10,'mul({1,3,4},{1,3},{6,5)} returns {7,10}') then
	print(table.unpack(rc))
end

rc = assert(RA.mul(3, {6,5}))
if not ok(rc[1]==18 and rc[2]==5,'mul(3,{6,5}) returns {18,5}') then
	print(table.unpack(rc))
end

rc = assert(RA.div({1,11,14}, {5,7}))
if not ok(rc[1]==5 and rc[2]==2, 'div({1,11,14},{5,7}) returns {5,2}') then
	print(table.unpack(rc))
end

rc = assert(RA.rat2latek({25,14}))
if not ok(rc=='\\frac{25}{14}',
  "rat2latek({25,14}}) returns '\\frac{25}{14}'") then
	print(rc)
end

rc = assert(RA.rat2latek({1,11,14}))
if not ok(rc=='1 \\frac{11}{14}',
  "rat2latek({1,11,14}}) returns '1 \\frac{11}{14}'") then
	print(rc)
end

function close(a,b)
	if math.abs(a-b) < 0.00001*math.sqrt(math.abs(a*b)) then
		return true
	else
		return false
	end
end

rc = assert(RA.binomial(4,1))
if not ok(rc==4, 'binomial(4,1) returns 4') then
	print(rc)
end

rc = assert(RA.binomial(4.0,1))
if not ok(close(rc, 4.0), 'binomial(4.0,1) returns 4.0') then
	print(rc)
	os.exit()
end

rc = assert(RA.binomial(4,2))
if not ok(rc==6, 'binomial(4,2) returns 6') then
	print(rc)
end

rc = assert(RA.binomial(4.0,2))
if not ok(close(rc, 6.0), 'binomial(4.0,2) returns 6.0') then
	print(rc)
	os.exit()
end

rc = assert(RA.binomial(5,1))
if not ok(rc==5, 'binomial(5,1) returns 5') then
	print(rc)
end

rc = assert(RA.binomial(5,2))
if not ok(rc==10, 'binomial(5,2) returns 10') then
	print(rc)
end

rc = assert(RA.binomial(14,6))
if not ok(rc==3003, 'binomial(14,6) returns 3003') then
	print(rc)
end

rc = assert(RA.binomial(15,6))
if not ok(rc==5005, 'binomial(15,6) returns 5005') then
	print(rc)
	os.exit()
end

rc = assert(RA.binomial(15.0,6))
if not ok(close(rc, 5005.0), 'binomial(15.0,6) returns 5005.0') then
	print(rc)
	os.exit()
end

rc = assert(RA.binomial(18,2))
if not ok(rc==153, 'binomial(18,2) returns 153') then
	print(rc)
end

rc = assert(RA.binomial(4.5,2))
if not ok(close(rc, 7.875), 'binomial(4.5,2) returns 7.875') then
	print(rc)
	os.exit()
end

rc = assert(RA.binomial({4,1},2))
if not ok(rc == 6, 'binomial({4,1},2) returns 6') then
	print(rc)
	os.exit()
end

rc = assert(RA.binomial({9,2},2))
if not ok(rc[1]==63 and rc[2]==8, 'binomial({9,2},2) returns {63,8}') then
	print(table.concat(rc,", "))
	os.exit()
end

rc = assert(RA.bernoulli_num(2))
if not ok(rc[1]==1 and rc[2]==6, 'bernoulli_num(2) returns {1,6}') then
	print(table.unpack(rc))
end

rc = assert(RA.bernoulli_num(3))
if not ok(rc[1]==0 and rc[2]==1, 'bernoulli_num(3) returns {0,1}') then
	print(table.unpack(rc))
end

rc = assert(RA.bernoulli_num(4))
if not ok(rc[1]==-1 and rc[2]==30, 'bernoulli_num(4) returns {-1,30}') then
	print(table.unpack(rc))
end

rc = assert(RA.bernoulli_num(6))
if not ok(rc[1]==1 and rc[2]==42, 'bernoulli_num(6) returns {1,42}') then
	print(table.unpack(rc))
end

rc = assert(RA.bernoulli_num(10))
if not ok(rc[1]==5 and rc[2]==66,
  'bernoulli_num(10) returns {5,66}') then
	print(table.unpack(rc))
end

rc = assert(RA.bernoulli_num(12))
if not ok(rc[1]==-691 and rc[2]==2730,
  'bernoulli_num(12) returns {-691,2730}') then
	print(table.unpack(rc))
end

rc = assert(RA.bernoulli_num(14))
if not ok(rc[1]==7 and rc[2]==6,
  'bernoulli_num(14) returns {7,6}') then
	print(table.unpack(rc))
end

rc = assert(RA.bernoulli_num(16))
if not ok(rc[1]==-3617 and rc[2]==510,
  'bernoulli_num(16) returns {-3617,510}') then
	print(table.unpack(rc))
end

rc = assert(RA.bernoulli_num(18))
if not ok(rc[1]==43867 and rc[2]==798,
  'bernoulli_num(18) returns {43867,798}') then
	print(table.unpack(rc))
end

-- local x = 1.6
-- print(x^5 - (5/2)*x^4 + (5/3)*x^3 - (1/6)*x)
-- https://en.wikipedia.org/wiki/Bernoulli_polynomials#Explicit_expressions_for_low_degrees
-- B(1,x) = x - 1/2
-- B(2,x) = x^2 - x + 1/6
-- B(3,x) = x^3 - (3/2)*x^2 + (1/2)*x
-- B(4,x) = x^4 - 2*x^3 + x^2 - 1/30
-- B(5,x) = x^5 - (5/2)*x^4 + (5/3)*x^3 - (1/6)*x     0.66176


local x = 0.9
rc = assert(RA.bernoulli_poly(1,x))
local should_be = x - (1/2)
if not ok( close(rc,should_be),
	string.format('bernoulli_poly(1, %g) returns %g',x,should_be)) then
	print('  was', rc, ' should be', should_be)
end

local x = 0.9
rc = assert(RA.bernoulli_poly(2,x))
local should_be = x^2 - x + (1/6)
if not ok( close(rc, should_be),
	string.format('bernoulli_poly(2, %g) returns %g',x,should_be)) then
	print('  was', rc, ' should be', should_be)
end

local x = 0.9
rc = assert(RA.bernoulli_poly(3,x))
local should_be = x^3 - (3/2)*x^2 + (1/2)*x
if not ok(close(rc, should_be),
	string.format('bernoulli_poly(3, %g) returns %g',x,should_be)) then
	print('  was', rc, ' should be', should_be)
end

local x = 0.9
rc = assert(RA.bernoulli_poly(4,x))
local should_be = x^4 - 2*x^3 + x^2 - 1/30
if not ok(close(rc, should_be),
	string.format('bernoulli_poly(4, %g) returns %g',x,should_be)) then
	print('  was', rc, ' should be', should_be)
end

local x = 1.6
rc = assert(RA.bernoulli_poly(5,x))
local should_be = x^5 - (5/2)*x^4 + (5/3)*x^3 - (1/6)*x
if not ok(close(rc, should_be),
	string.format('bernoulli_poly(5, %g) returns %g',x,should_be)) then
	print('  was', rc, ' should be', should_be)
end

-- B(6,x) = x^6 - 3*x^5 + (5/2)*x^4 - (1/2)*x^2 + 1/42
local x = -1.1
rc = assert(RA.bernoulli_poly(6,x))
should_be = x^6 - 3*x^5 + (5/2)*x^4 - (1/2)*x^2 + 1/42
if not ok(close(rc, should_be),
	string.format('bernoulli_poly(6, %g) returns %g',x,should_be)) then
	print('  was', rc, ' should be', should_be)
end

rc = assert(RA.polygonal_num(3,3))
should_be = 6
if not ok(close(rc, should_be),
	string.format('polygonal_num(3,3) returns %g',should_be)) then
	print('  was', rc, ' should be', should_be)
end

rc = assert(RA.polygonal_num(4,5))
should_be = 25 
if not ok(close(rc, should_be),
	string.format('polygonal_num(4,5) returns %g',should_be)) then
	print('  was', rc, ' should be', should_be)
end

rc = assert(RA.polygonal_num(5,5))
should_be = 35
if not ok(close(rc, should_be),
	string.format('polygonal_num(5,5) returns %g',should_be)) then
	print('  was', rc, ' should be', should_be)
end

rc = assert(RA.polygonal_num(6,7))
should_be = 91  -- 2*n*n - n
if not ok(close(rc, should_be),
	string.format('polygonal_num(6,7) returns %g',should_be)) then
	print('  was', rc, ' should be', should_be)
end

rc = assert(RA.polygonal_num(20,10))
should_be = 820
if not ok(close(rc, should_be),
	string.format('polygonal_num(20,10) returns %g',should_be)) then
	print('  was', rc, ' should be', should_be)
end

rc = assert(RA.mat2x2det({1,3,4,11}))
should_be = -1
if not ok(close(rc, should_be),
	string.format('mat2x2det({1,3,4,11}) returns %g',should_be)) then
	print('  was', rc, ' should be', should_be)
end

rc = assert(RA.mat2x2mul({1,3,4,11},{1,0,0,1}))
should_be = '1,3,4,11'
if not ok(table.concat(rc,',') == should_be,
	string.format('mat2x2mul({1,3,4,11},{1,0,0,1}) returns %s',should_be)) then
	print('  was', table.concat(rc,','), ' should be', should_be)
end

rc = assert(RA.mat2x2inv({1,2,3,4}))
should_be = {-2, 1, 1.5, -0.5}
s = table.concat(should_be,',')
if not ok(rc[1]==should_be[1] and rc[2]==should_be[2]
      and close(rc[3],should_be[3]) and close(rc[4],should_be[4]),
	string.format('mat2x2inv({1,2,3,4}) returns %s',s)) then
	print('  was', table.concat(rc,','), ' should be', s)
end

