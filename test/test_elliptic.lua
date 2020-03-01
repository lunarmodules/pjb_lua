#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2019, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

EL = require 'elliptic_curve'

local Version = '1.0  for Lua5'
local VersionDate  = '25feb2019'
local Synopsis = [[
  lua test_elliptic.lua
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

function eq (a,b,eps)
	if not eps then eps = .000001 end
	return math.abs(a-b) < eps
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


rc = EL.set_numberfield('Q')
if not ok(rc == true, "set_numberfield('Q') returns true") then
	print(rc)
end

rc = EL.set_numberfield('Z/pZ')
if not ok(rc == true, "set_numberfield('Z/pZ') returns true") then
	print(rc)
end

rc,msg = EL.set_numberfield('foo')
if not ok(rc == nil, "set_numberfield('foo') returns nil") then
	print('  '..msg)
end

rc = EL.set_numberfield('R')
if not ok(rc == true, "set_numberfield('R') returns true") then
	print(rc)
end

rc,msg = EL.add_gen(-3,2)
if not ok(rc ==nil, 'add_gen(-3,2) returns nil') then
	print('  '..msg)
end

rc,msg = EL.scalarmul_gen(-3,2)
if not ok(rc ==nil, 'scalarmul_gen(-3,2) returns nil') then
	print('  '..msg)
end

rc = EL.set_numberfield('Z/pZ')
if not ok(rc == true, "set_numberfield('Z/pZ') returns true") then
	print(rc)
end
local add_mod = EL.add_gen(2,2,17)   -- see 12:45
xr,yr = add_mod(5,1, 5,1)   -- G+G see 14:39
if not ok(xr==6 and yr==3, 'add_mod(5,1, 5,1) returns 6,3') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(5,1, 6,3)   -- G+G see 15:14, 15:20 !!
if not ok(xr==10 and yr==6, 'add_mod(5,1, 6,3) returns 10,6') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(10,6, 5,1)   -- G+G see 15:14, 15:20 !!
if not ok(xr==3 and yr==1, 'add_mod(10,6, 5,1) returns 3,1') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(5,1, 3,1)   -- G+G see 15:14, 15:20 !!
if not ok(xr==9 and yr==16, 'add_mod(5,1, 3,1) returns 9,16') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(3,1, 10,6)   -- G+G see 15:14, 15:20 !!
if not ok(xr==0 and yr==6, 'add_mod(3,1, 10,6) returns 0,6') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(9,16, 5,1)   -- G+G see 15:14, 15:20 !!
if not ok(xr==16 and yr==13, 'add_mod(9,16, 5,1) returns 16,13') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(10,6, 9,16)   -- G+G see 15:14, 15:20 !!
if not ok(xr==13 and yr==7, 'add_mod(10,6, 9,16) returns 13,7') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(6,3, 0,6)   -- G+G see 15:14, 15:20 !!
if not ok(xr==7 and yr==6, 'add_mod(6,3, 0,6) returns 7,6') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(16,13, 13,7)   -- G+G see 15:14, 15:20 !!
if not ok(xr==9 and yr==1, 'add_mod(16,13, 13,7) returns 9,1') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(9,1, 3,1)   -- G+G see 15:14, 15:20 !!
if not ok(xr==5 and yr==16, 'add_mod(9,1, 3,1) returns 5,16') then
	print('xr='..xr..' yr='..yr)
end
xr,yr = add_mod(5,16, 5,1)   -- G+G see 15:14, 15:20 !!
if not ok(xr==0 and yr=='infty', 'add_mod(5,16, 5,1) returns 0,"infty"') then
	print('xr='..xr..' yr='..yr)
end

f = sqrt_modp(17)
rc = f(1)
if not ok(rc==1, 'sqrt_modp(1, 17) returns 1') then
	print('rc='..rc)
end
rc = f(2)
if not ok(rc==6, 'sqrt_modp(2, 17) returns 6') then
	print('rc='..rc)
end
rc = f(3)
if not ok(rc==nil, 'sqrt_modp(3, 17) returns nil') then
	print('rc='..rc)
end
rc = f(4)
if not ok(rc==2, 'sqrt_modp(4, 17) returns 2') then
	print('rc='..rc)
end
rc = f(5)
if not ok(rc==nil, 'sqrt_modp(5, 17) returns nil') then
	print('rc='..rc)
end
rc = f(6)
if not ok(rc==nil, 'sqrt_modp(6, 17) returns nil') then
	print('rc='..rc)
end
rc = f(7)
if not ok(rc==nil, 'sqrt_modp(7, 17) returns nil') then
	print('rc='..rc)
end
rc = f(8)
if not ok(rc==5, 'sqrt_modp(8, 17) returns 5') then
	print('rc='..rc)
end
rc = f(9)
if not ok(rc==3, 'sqrt_modp(9, 17) returns 3') then
	print('rc='..rc)
end
rc = f(10)
if not ok(rc==nil, 'sqrt_modp(10, 17) returns nil') then
	print('rc='..rc)
end
rc = f(11)
if not ok(rc==nil, 'sqrt_modp(11, 17) returns nil') then
	print('rc='..rc)
end
rc = f(12)
if not ok(rc==nil, 'sqrt_modp(12, 17) returns nil') then
	print('rc='..rc)
end
rc = f(13)
if not ok(rc==8, 'sqrt_modp(13, 17) returns 8') then
	print('rc='..rc)
end
rc = f(14)
if not ok(rc==nil, 'sqrt_modp(14, 17) returns nil') then
	print('rc='..rc)
end
rc = f(15)
if not ok(rc==7, 'sqrt_modp(15, 17) returns 7') then
	print('rc='..rc)
end
rc = f(16)
if not ok(rc==4, 'sqrt_modp(16, 17) returns 4') then
	print('rc='..rc)
end

-- pcall(function() rc = EL.cancel(true) end)

-- pcall(function() rc = EL.cancel(true) end)
-- ok(not rc, 'cancel raises error if called with a boolean')

