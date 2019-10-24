---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2011, Peter J Billam      --
--                       www.pjb.com.au                            --
--                                                                 --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local MM = require 'mymodule'
-- MM.foo()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '9jan2011'

------------------------------ private ------------------------------
local function warn(str) io.stderr:write(str,'\n') end
local function die(str) io.stderr:write(str,'\n') ;  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
	local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end

-- global
local wow = 'why not'

------------------------------ public ------------------------------
function M.foo()
	print(M.VersionDate)
end

return M

