---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2019, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local MM = require 'vtfonts'
-- MM.foo()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '1nov2019'

local TI = require 'terminfo'

------------------------------ private ------------------------------
function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),' ') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end
function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end

local TTY = assert(io.open('/dev/tty', 'a+'))

local cols  = TI.get('cols')
local lines = TI.get('lines')
local cup   = TI.get('cup')    -- cursor_address
local rev   = TI.get('rev')    -- reverse_video
local sgr0  = TI.get('sgr0')   -- exit_attribute_mode
local cnorm = TI.get('cnorm')  -- cursor_normal
local function go_to (col, line)
	TTY:write(TI.tparm(cup, line, col))
end
local format = string.format
local function bg_color(i)
	local c =
	  { black=0, red=1, green=2, yellow=3, blue=4, violet=5, cyan=6, white=7 }
	if type(i) == 'string' then
		i = c[i]
		if not i then return nil end
	end
	if i < 0 or i > 7 then
		return nil, format('color %g is out of the 0..7 range',i)
	end
	TTY:write(format("\027[4%dm", i))
end
local function fg_color(i)
	local c =
	  { black=0, red=1, green=2, yellow=3, blue=4, violet=5, cyan=6, white=7 }
	if type(i) == 'string' then
		if not c[i] then return nil, 'unknown colour '..i end
		i = c[i]
	end
	if i < 0 or i > 7 then
		return nil, format('color %g is out of the 0..7 range',i)
	end
	TTY:write(format("\027[3%dm", i))
end


local c2width = {
	['A']=13, ['B']=12, ['C']=11, ['D']=12, ['E']=11,
	['F']=11, ['G']=12, ['H']=12, ['I']=9,  ['J']=11,
	['K']=11, ['L']=11, ['M']=13, ['N']=13, ['O']=13,
	['P']=12, ['Q']=13, ['R']=12, ['S']=11, ['T']=13,
	['U']=13, ['V']=13, ['W']=13, ['X']=13, ['Y']=13,
	['Z']=10,
	['a']=9,  ['b']=9,  ['c']=9,  ['d']=9,  ['e']=9,
	['f']=8,  ['g']=9,  ['h']=9,  ['i']=5,  ['j']=6,
	['k']=8,  ['l']=5,  ['m']=11, ['n']=10, ['o']=9,
	['p']=9,  ['q']=9,  ['r']=7,  ['s']=11, ['t']=11,
	['u']=11, ['v']=11, ['w']=11, ['x']=11, ['y']=11,
	['z']=11, [' ']=11, ["'"]=11, ['"']=11,
	['.']=5,  [',']=6,  [':']=5,  [';']=6,
	['!']=5,  ['?']=9,  ['_']=9,
	['0']=11, ['1']=11, ['2']=11, ['3']=11, ['4']=10,
	['5']=9,  ['6']=9,  ['7']=11, ['8']=8,  ['9']=11,
	['+']=11, ['=']=11, ['>']=11, ['<']=11,
	['/']=11,['\\']=11, ['$']=11, 
	['|']=11, ['@']=11, ['#']=11, ['~']=11,
	['%']=11, ['&']=11, ['*']=11,
	['^']=11,
	['(']=11, ['[']=11, ['{']=11,
	[')']=11, [']']=11, ['}']=11,
}


------------------------- uppercase ---------------------
local function char_A (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('      ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+9, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('          ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+10,line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_B (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+9, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('        ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+9, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+9, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('        ')
	TTY:write(sgr0)
	return 12  -- width
end

local function char_C (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('      ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 11  -- width
end

local function char_D (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('       ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+8, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+9, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+9, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('       ')
	TTY:write(sgr0)
	return 12  -- width
end

local function char_E (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('      ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('        ')
	TTY:write(sgr0)
	return 11  -- width
end

local function char_F (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('      ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 11  -- width
end
local function char_G (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('       ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('    ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('       ')
	TTY:write(sgr0)
	return 12  -- width
end
local function char_H (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+9, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+9, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('         ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+9, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+9, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+9, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 12  -- width
end

local function char_I (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('      ')
	go_to(col+4, line-4) ; TTY:write('  ')
	go_to(col+4, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('  ')
	go_to(col+4, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return  9  -- width
end

local function char_J (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+7, line-4) ; TTY:write('  ')
	go_to(col+7, line-3) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('     ')
	TTY:write(sgr0)
	return 11  -- width
end

local function char_K (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+7, line-5) ; TTY:write('   ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+5, line-4) ; TTY:write('   ')
	go_to(col+2, line-3) ; TTY:write('    ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+5, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+7, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+8,  line)  ; TTY:write('  ')
	TTY:write(sgr0)
	return 11  -- width
end

local function char_L (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('        ')
	TTY:write(sgr0)
	return 11  -- width
end
local function char_M (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('   ')
	go_to(col+9, line-4) ; TTY:write('   ')
	go_to(col+2, line-3) ; TTY:write('    ')
	go_to(col+8, line-3) ; TTY:write('    ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+5, line-2) ; TTY:write('    ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+10, line)  ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_N (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('   ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('    ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+5, line-3) ; TTY:write('   ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('    ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+9, line)   ; TTY:write('   ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_O (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('      ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+9, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+9, line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_P (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+9, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+9, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('        ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 12  -- width
end
local function char_Q (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('     ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+8, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+9, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+9, line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('     ')
	go_to(col+10,line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_R (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+8, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+9, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('        ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+7, line-1) ; TTY:write('   ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+9, line)  ; TTY:write('  ')
	TTY:write(sgr0)
	return 12  -- width
end
local function char_S (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-5) ; TTY:write('       ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+3, line-3) ; TTY:write('      ')
	go_to(col+8, line-2) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('       ')
	TTY:write(sgr0)
	return 11  -- width
end
local function char_T (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('          ')
	go_to(col+6, line-4) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+6, line)   ; TTY:write('  ')
	TTY:write(sgr0)   -- alas ! this sets fg to black :-(
	return 13  -- width
end
local function char_U (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+9, line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_V (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+3, line-3) ; TTY:write('  ')
	go_to(col+9, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('  ')
	go_to(col+8, line-2) ; TTY:write('  ')
	go_to(col+5, line-1) ; TTY:write('    ')
	-- go_to(col+8, line-2) ; TTY:write('  ')
	go_to(col+6, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_W (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+5, line-1) ; TTY:write('    ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('   ')
	go_to(col+8, line)   ; TTY:write('   ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_X (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+9, line-4) ; TTY:write('  ')
	go_to(col+4, line-3) ; TTY:write('  ')
	go_to(col+8, line-3) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+4, line-1) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+10,line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_Y (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+9, line-4) ; TTY:write('  ')
	go_to(col+4, line-3) ; TTY:write('  ')
	go_to(col+8, line-3) ; TTY:write('  ')
	go_to(col+5, line-2) ; TTY:write('    ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+6, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_Z (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('       ')
	go_to(col+6, line-4) ; TTY:write('  ')
	go_to(col+5, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('       ')
	TTY:write(sgr0)
	return 10  -- width
end
-------------- lower case -------------------
local function char_a (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-4) ; TTY:write('    ')
	go_to(col+8, line-4) ; TTY:write(' ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('   ')
	go_to(col+1, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('   ')
	go_to(col+3, line)   ; TTY:write('    ')
	go_to(col+8, line)   ; TTY:write(' ')
	TTY:write(sgr0)
	return c2width['a']
end

local function char_b (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('     ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('     ')
	TTY:write(sgr0)
	return c2width['b']
end
local function char_c (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-4) ; TTY:write('     ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+1, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('     ')
	TTY:write(sgr0)
	return c2width['c']
end

local function char_d (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+6, line-5) ; TTY:write('  ')
	go_to(col+3, line-4) ; TTY:write('     ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+1, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('     ')
	TTY:write(sgr0)
	return c2width['d']
end
local function char_e (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-4) ; TTY:write('    ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+1, line-2) ; TTY:write('       ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('    ')
	TTY:write(sgr0)
	return c2width['e']
end
local function char_f (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('   ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+3, line-3) ; TTY:write('  ')
	go_to(col+1, line-2) ; TTY:write('      ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('  ')
	go_to(col+1, line+1) ; TTY:write('   ')
	TTY:write(sgr0)
	return c2width['f']
end
local function char_g (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-4) ; TTY:write('    ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+1, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('       ')
	go_to(col+7, line)   ; TTY:write('  ')
	go_to(col+2, line+1) ; TTY:write('      ')
	TTY:write(sgr0)
	return c2width['g']
end
local function char_h (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('      ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+7, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+7, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['h']
end
local function char_i (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['i']
end

local function char_j (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-5) ; TTY:write('  ')
	go_to(col+3, line-3) ; TTY:write('  ')
	go_to(col+3, line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('  ')
	go_to(col+1, line+1) ; TTY:write('   ')
	TTY:write(sgr0)
	return c2width['j']
end
local function char_k (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+5, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('    ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+5, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+6, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['k']
end
local function char_l (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['l']
end
local function char_m (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-4) ; TTY:write('   ')
	go_to(col+7, line-4) ; TTY:write('   ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write(' ')
	go_to(col+9, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write(' ')
	go_to(col+9, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+9, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+9, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['m']
end
local function char_n (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-4) ; TTY:write(' ')
	go_to(col+4, line-4) ; TTY:write('   ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+7, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+7, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['n']
end

local function char_o (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-4) ; TTY:write('    ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+1, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('    ')
	TTY:write(sgr0)
	return c2width['o']
end
local function char_p (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-4) ; TTY:write(' ')
	go_to(col+4, line-4) ; TTY:write('   ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('     ')
	go_to(col+2, line+1) ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['p']
end

local function char_q (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-4) ; TTY:write('   ')
	go_to(col+7, line-4) ; TTY:write(' ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+1, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('     ')
	go_to(col+6, line+1) ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['q']
end
local function char_r (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-4) ; TTY:write(' ')
	go_to(col+4, line-4) ; TTY:write('   ')
	go_to(col+2, line-3) ; TTY:write('   ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['r']
end

--------------- punctuation -----------------
local function char_question (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('      ')
	go_to(col+1, line-4) ; TTY:write('  ')
	go_to(col+7, line-4) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('   ')
	go_to(col+4, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['?']
end

local function char_exclamation (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return  5  -- width
end

local function char_colon (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 5   -- width
end
local function char_dot (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 5   -- width
end
local function char_semicolon (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-2) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('  ')
	go_to(col+2, line+1) ; TTY:write('  ')
	TTY:write(sgr0)
	return 6   -- width
end
local function char_comma (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line)   ; TTY:write('  ')
	go_to(col+2, line+1) ; TTY:write('  ')
	TTY:write(sgr0)
	return 6   -- width
end
local function char_dash (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-2) ; TTY:write('     ')
	TTY:write(sgr0)
	return 8   -- width
end
local function char_plus (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('      ')
	go_to(col+4, line-1) ; TTY:write('  ')
	TTY:write(sgr0)
	return 9   -- width
end

local function char_0 (col,line, colour)  -- zero
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('      ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+8, line-4) ; TTY:write('   ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+7, line-3) ; TTY:write(' ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write(' ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('   ')
	go_to(col+9, line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_1 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('    ')
	go_to(col+4, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('  ')
	go_to(col+4, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return  9  -- width
end
local function char_2 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-5) ; TTY:write('     ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+7, line-4) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('   ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('       ')
	TTY:write(sgr0)
	return 10  -- width
end
local function char_3 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-5) ; TTY:write('     ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+7, line-4) ; TTY:write('  ')
	go_to(col+5, line-3) ; TTY:write('   ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+7, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('     ')
	TTY:write(sgr0)
	return 10  -- width
end
local function char_4 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+5, line-5) ; TTY:write('   ')
	go_to(col+4, line-4) ; TTY:write('    ')
	go_to(col+3, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('        ')
	go_to(col+6, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return c2width['4']
end

local function char_5 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('      ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('      ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('    ')
	TTY:write(sgr0)
	return c2width['5']
end

local function char_6 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-5) ; TTY:write('    ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('      ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('    ')
	TTY:write(sgr0)
	return c2width['6']
end

local function char_7 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('      ')
	go_to(col+6, line-4) ; TTY:write('  ')
	go_to(col+5, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 9  -- width
end

local function char_8 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('     ')
	go_to(col+1, line-4) ; TTY:write('  ')
	go_to(col+6, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('     ')
	go_to(col+1, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+1, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('     ')
	TTY:write(sgr0)
	return c2width['8']
end

local function char_9 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+3, line-5) ; TTY:write('     ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+7, line-4) ; TTY:write('  ')
	go_to(col+3, line-3) ; TTY:write('      ')
	go_to(col+7, line-2) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+3, line)   ; TTY:write('    ')
	TTY:write(sgr0)
	return 10  -- width
end
local function char_slash (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+7, line-5) ; TTY:write('  ')
	go_to(col+6, line-4) ; TTY:write('  ')
	go_to(col+5, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('  ')
	go_to(col+3, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 10  -- width
end
local function char_backslash (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+3, line-4) ; TTY:write('  ')
	go_to(col+4, line-3) ; TTY:write('  ')
	go_to(col+5, line-2) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+7, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 10  -- width
end
local function char_underscore (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+1, line)   ; TTY:write('         ')
	TTY:write(sgr0)
	return 10  -- width
end

local function char_bar (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return  5  -- width
end
local function char_equals (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	go_to(col+2, line-3) ; TTY:write('      ')
	go_to(col+2, line-1) ; TTY:write('      ')
	TTY:write(sgr0)
	return  9  -- width
end
local function char_space (col,line, colour)
	return  8  -- width
end

local c2func = {
	['A']=char_A, ['B']=char_B, ['C']=char_C, ['D']=char_D, ['E']=char_E,
	['F']=char_F, ['G']=char_G, ['H']=char_H, ['I']=char_I, ['J']=char_J,
	['K']=char_K, ['L']=char_L, ['M']=char_M, ['N']=char_N, ['O']=char_O,
	['P']=char_P, ['Q']=char_Q, ['R']=char_R, ['S']=char_S, ['T']=char_T,
	['U']=char_U, ['V']=char_V, ['W']=char_W, ['X']=char_X, ['Y']=char_Y,
	['Z']=char_Z,
	['a']=char_a, ['b']=char_b, ['c']=char_c, ['d']=char_d, ['e']=char_e,
	['f']=char_f, ['g']=char_g, ['h']=char_h, ['i']=char_i, ['j']=char_j,
	['k']=char_k, ['l']=char_l, ['m']=char_m, ['n']=char_n, ['o']=char_o,
	['p']=char_p, ['q']=char_q, ['r']=char_r, ['s']=char_s, ['t']=char_t,
	['u']=char_u, ['v']=char_v, ['w']=char_w, ['x']=char_x, ['y']=char_y,
	['z']=char_z, [' ']=char_space, ["'"]=char_quote, ['"']=char_doublequote,
	['.']=char_dot, [',']=char_comma, [':']=char_colon, [';']=char_semicolon,
	['!']=char_exclamation, ['?']=char_question, ['_']=char_underscore,
	['0']=char_0, ['1']=char_1, ['2']=char_2, ['3']=char_3, ['4']=char_4,
	['5']=char_5, ['6']=char_6, ['7']=char_7, ['8']=char_8, ['9']=char_9,
	['+']=char_plus, ['=']=char_equals, ['>']=char_gt, ['<']=char_lt,
	['/']=char_slash, ['\\']=char_backslash, ['$']=char_dollar, 
	['|']=char_bar, ['@']=char_snail, ['#']=char_hash, ['~']=char_tilde,
	['%']=char_percent, ['&']=char_ampersand, ['*']=char_asterisc,
	['^']=char_caret,
	['(']=char_openbracket,  ['[']=char_opensquare,  ['{']=char_opencurly,
	[')']=char_closebracket, [']']=char_closesquare, ['}']=char_closecurly,
}

------------------------------ public ------------------------------

function M.show_char (col,line, c, colour)
	local func = c2func[c]
	if not func then return 0 end
	return func(col,line,colour)
end
function M.show (col,line, str, colour)
	local width = 0
	for i = 1, str:len() do
		charwidth = M.show_char(col,line, string.sub(str,i,i), colour)
		width = width + charwidth
		col = col + charwidth
	end
	return width
end

-- just testing :-)
local col  = 0
local line = 0 
-- line = line+7 ; M.show(0, line, 'ABCDEF',     math.random(7)-1)
-- line = line+7 ; M.show(0, line, 'GHIJKLM', math.random(7)-1)
-- line = line+7 ; M.show(0, line, 'NOPQRS',  math.random(7)-1)
line = line+7 ; M.show(0, line, 'TUVWXY',     math.random(7)-1)
line = line+7 ; M.show(0, line, 'Z?!:.;,-01', math.random(7)-1)
line = line+8 ; M.show(-1,line, '23456789',   math.random(7)-1)
line = line+7 ; M.show(0, line, '+/\\_| =',   math.random(7)-1)
line = line+7 ; M.show(0, line, 'abcdefghi',  math.random(7)-1)
line = line+7 ; M.show(0, line, 'jklmnopqr',   math.random(7)-1)
go_to(1, cols) ; os.exit()


return M

--[=[

=pod

=head1 NAME

vtfonts.lua - does whatever

=head1 SYNOPSIS

 local M = require 'vtfonts'
 a = { 6,8,7,9,8 }
 b = { 4,7,5,4,5,6,4 }
 local probability_of_hypothesis_being_wrong = M.ttest(a,b,'b>a')

=head1 DESCRIPTION

This module does whatever

=head1 FUNCTIONS

=over 3

=item I<ttest(a,b, hypothesis)>

The arguments I<a> and I<b> are arrays of numbers

The I<hypothesis> can be one of 'a>b', 'a<b', 'b>a', 'b<a',
'a~=b' or 'a<b'.

I<ttest> returns the probability of your hypothesis being wrong.

=back

=head1 DOWNLOAD

This module is available at
http://pjb.com.au/comp/lua/vtfonts.html

=head1 AUTHOR

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://pjb.com.au/
 https://luarocks.org/modules/kikito/ansicolors
 https://github.com/kikito/ansicolors.lua

=cut

]=]

