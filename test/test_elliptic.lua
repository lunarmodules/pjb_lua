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

rc = EL.set_numberfield('R')
if not ok(rc == true, "set_numberfield('R') returns true") then
	print(rc)
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

pcall(function() rc = EL.cancel(true) end)
ok(not rc, 'cancel raises error if called with a boolean')

