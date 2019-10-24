#! /usr/local/bin/lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2013, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

local P = require 'posix'
-- local B = require 'bit'  -- LuaBitOp
-- require 'DataDumper'

------------------------------ private ------------------------------
local function warn(str) io.stderr:write(str,'\n') end
local function die(str)  io.stderr:write(str,'\n') ;  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
	local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end
local function exists(fn)
	-- or check if posix.stat(path) returns non-nil
	local f=io.open(fn,'r')
	if f then f:close(); return true else return false end
end
local function deepcopy(object)  -- http://lua-users.org/wiki/CopyTable
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

------------------- from TermReadKey.lua --------------------------

local Userdata2fd = {}
function descriptor2fd(file)
	if     type(file) == 'number' then   -- its a posix int fd
		return file
	elseif type(file) == 'userdata' then -- its a lua filedescriptor
		if Userdata2fd[file] then -- cached ?
print(' this time the following was cached:')
			return Userdata2fd[file]
		end
		local getpid = P.getpid() -- io.tmpfile won't do, we need a string
		local tmp = '/tmp/readkey'..tostring(getpid['pid'])
		local pid = P.fork()  -- fork:
		if pid == 0 then  -- the child straces itself to a tmpfile
			local getpid = P.getpid()
			local pid = getpid['pid']
			os.execute('strace -q -p '..pid..' -e trace=desc -o '..tmp..' &')
			-- the first seek() wins the race condition, so we loop
			for i= 1,5 do -- repeat until the tmpfile has non-zero size
				P.nanosleep(0,100000000) -- 0.1 sec
				local current = file:seek()  -- should do no damage...
				local stat = P.stat(tmp)     -- did strace capture it ?
				if stat['size'] > 1 then break end
			end
			os.exit() --  child exits, causing strace to exit
		else -- the parent waits; then parses and removes the tmpfile
			P.wait()
			local f = assert(io.open(tmp,'r'))
			local s = f:read('*all')
			f:close()
			P.unlink(tmp)
			local fd = tonumber(string.match(s,'seek%((%d+)'))
			Userdata2fd[file] = fd -- cache by userdata to save time next time
			return fd
		end
	else return 0
	end
end


----------------------------- test it ----------------------------

print('descriptor2fd(3) = '..tostring(descriptor2fd(3)))
print('descriptor2fd(io.stderr) = '..tostring(descriptor2fd(io.stderr)))
print('descriptor2fd(io.stdin) = '..tostring(descriptor2fd(io.stdin)))
print('descriptor2fd(io.stderr) = '..tostring(descriptor2fd(io.stderr)))
