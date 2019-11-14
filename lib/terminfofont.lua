---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2019, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

local M = {} -- public interface
M.Version     = '0.3'
M.VersionDate = '9nov2019'

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
local function round(x)
	if not x then return nil end
	return math.floor(x+0.5)
end

local TTY = assert(io.open('/dev/tty', 'a+'))

local cols  = TI.get('cols')
local lines = TI.get('lines')
local cup   = TI.get('cup')    -- cursor_address
local rev   = TI.get('rev')    -- reverse_video
local sgr0  = TI.get('sgr0')   -- exit_attribute_mode
local civis = TI.get('civis')  -- cursor_invisible
local cnorm = TI.get('cnorm')  -- cursor_normal
local fontsize = 7
local both  = '\xe2\x96\x88'   -- by experiment with qrencode -t UTF8
local lower = '\xe2\x96\x84'
local upper = '\xe2\x96\x80'

function moveto (col, line)
	TTY:write(TI.tparm(cup, line, col))
	TTY:flush()
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

local c2width_7 = {
	['A']=12, ['B']=11, ['C']=10, ['D']=11, ['E']=10,
	['F']=10, ['G']=11, ['H']=11, ['I']=8,  ['J']=10,
	['K']=10, ['L']=10, ['M']=12, ['N']=12, ['O']=12,
	['P']=11, ['Q']=12, ['R']=11, ['S']=10, ['T']=12,
	['U']=12, ['V']=12, ['W']=12, ['X']=11, ['Y']=12, ['Z']=9,
	['a']=10, ['b']=8,  ['c']=9,  ['d']=9,  ['e']=9,
	['f']=8,  ['g']=10, ['h']=9,  ['i']=4,  ['j']=6,
	['k']=8,  ['l']=4,  ['m']=11, ['n']=9,  ['o']=10,
	['p']=9,  ['q']=9,  ['r']=7,  ['s']=8,  ['t']=7,
	['u']=9,  ['v']=10, ['w']=11, ['x']=9,  ['y']=10,
	['z']=8,  [' ']=9,  ["'"]=3, ['"']=5,
	['.']=4,  [',']=5,  [':']=4,  [';']=5, ['-']=7,
	['!']=4,  ['?']=10, ['_']=11,
	['0']=12, ['1']=8,  ['2']=9,  ['3']=9, ['4']=10,
	['5']=9,  ['6']=9,  ['7']=8,  ['8']=9,  ['9']=9,
	['+']=8,  ['=']=8,  ['>']=11, ['<']=11,
	['/']=9,  ['\\']=9, ['$']=11, 
	['|']=4,  ['@']=10, ['#']=7,  ['~']=9,
	['%']=9, ['&']=11,  ['*']=7, ['^']=8,
	['(']=6, ['[']=6, ['{']=6,
	[')']=6, [']']=6, ['}']=6,
}
local c2width = c2width_7

local function is_good_fit (a,b)
	if not b then return false end
	if (a=='F' or a=='T' or a=='"' or a=="'" or a=='/') and
	 (b=='A' or b=='C' or b=='G' or b=='O' or b=='.' or b==',' or
	  b=='Q' or b=='0' or b=='4' or b=='_' or b=='/') then
		return true
	elseif (a=='L' or a=='Q' or a=='1' or a=='\\' or
	        a=='_' or a=='.' or a==',') and
	 (b=='C' or b=='O' or b=='Q'  or b=='T' or b=='U' or
	  b=='V' or b=='Y' or b=='\\' or b=='0') then
		return true
	end
	return false
end
local function spaces (x, y, n)
	if y   < 0 or y >= lines then return nil end
	if x+n < 0 or x >= cols  then return nil end
	if x < 0 then n=n+x ; x=0 elseif x+n >= cols then n = n-(x+n-cols) end
	moveto(x,y) ; TTY:write(string.rep(' ',n))
end
local function utf2iso (raw_str)
	if string.match(raw_str, '[\194,\195]') then
		-- http://lua-users.org/lists/lua-l/2015-02/msg00173.html
		-- fails on euro-sign 
		local s_iso = string.gsub(raw_str, utf8.charpattern,
			function (c)
				return string.char(utf8.codepoint(c))
		 	end)
		return s_iso
	else
		return raw_str
	end
end
-- \344 ä  \353 ë  \366 ö  \374 ü   lowercase
-- \304 Ä  \313 Ë  \326 Ö  \334 Ü   uppercase

------------------------- uppercase ---------------------
local function char_A (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 6)
	spaces(col+2, line-4, 2)
	spaces(col+8, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+9, line-3, 2)
	spaces(col+1, line-2,10)
	spaces(col+1, line-1, 2)
	spaces(col+9, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+9, line,   2)
	TTY:write(sgr0)
	return c2width['A']
end
local function char_B (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 8)
	spaces(col+1, line-4, 2)
	spaces(col+8, line-4, 2)
	spaces(col+1, line-3, 8)
	spaces(col+1, line-2, 2)
	spaces(col+8, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+8, line-1, 2)
	spaces(col+1, line,   8)
	TTY:write(sgr0)
	return c2width['B']
end
local function char_C (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 6)
	spaces(col+2, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+3, line,   6)
	TTY:write(sgr0)
	return c2width['C']
end
local function char_D (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 7)
	spaces(col+1, line-4, 2)
	spaces(col+7, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+8, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+8, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+7, line-1, 2)
	spaces(col+1, line,   7)
	TTY:write(sgr0)
	return c2width['D']
end
local function char_E (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 8)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 6)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   8)
	TTY:write(sgr0)
	return c2width['E']
end
local function char_F (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 8)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 6)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['F']
end
local function char_G (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 7)
	spaces(col+2, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 4)
	spaces(col+1, line-1, 2)
	spaces(col+7, line-1, 2)
	spaces(col+2, line,   7)
	TTY:write(sgr0)
	return c2width['G']
end
local function char_H (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+8, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+8, line-4, 2)
	spaces(col+1, line-3, 9)
	spaces(col+1, line-2, 2)
	spaces(col+8, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+8, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+8, line,   2)
	TTY:write(sgr0)
	return c2width['H']
end
local function char_I (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 6)
	spaces(col+3, line-4, 2)
	spaces(col+3, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+3, line-1, 2)
	spaces(col+1, line,   6)
	TTY:write(sgr0)
	return c2width['I']
end
local function char_J (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 8)
	spaces(col+6, line-4, 2)
	spaces(col+6, line-3, 2)
	spaces(col+6, line-2, 2)
	spaces(col+5, line-1, 2)
	spaces(col+1, line,   5)
	TTY:write(sgr0)
	return c2width['J']
end
local function char_K (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+6, line-5, 3)
	spaces(col+1, line-4, 2)
	spaces(col+4, line-4, 3)
	spaces(col+1, line-3, 4)
	spaces(col+1, line-2, 2)
	spaces(col+4, line-2, 3)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+7, line,   2)
	TTY:write(sgr0)
	return c2width['K']
end
local function char_L (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   8)
	TTY:write(sgr0)
	return c2width['L']
end
local function char_M (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+9, line-5, 2)
	spaces(col+1, line-4, 3)
	spaces(col+8, line-4, 3)
	spaces(col+1, line-3, 4)
	spaces(col+7, line-3, 4)
	spaces(col+1, line-2, 2)
	spaces(col+4, line-2, 4)
	spaces(col+9, line-2, 2)
	spaces(col+5, line-1, 2)
	spaces(col+1, line-1, 2)
	spaces(col+9, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+9, line,   2)
	TTY:write(sgr0)
	return c2width['M']
end
local function char_N (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 3)
	spaces(col+9, line-5, 2)
	spaces(col+1, line-4, 4)
	spaces(col+9, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+4, line-3, 3)
	spaces(col+9, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+9, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+7, line-1, 4)
	spaces(col+1, line,   2)
	spaces(col+8, line,   3)
	TTY:write(sgr0)
	return c2width['N']
end
local function char_O (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 6)
	spaces(col+2, line-4, 2)
	spaces(col+8, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+9, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+9, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+8, line-1, 2)
	spaces(col+3, line,   6)
	TTY:write(sgr0)
	return c2width['O']
end
local function char_P (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 8)
	spaces(col+1, line-4, 2)
	spaces(col+8, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+8, line-3, 2)
	spaces(col+1, line-2, 8)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['P']
end
local function char_Q (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 5)
	spaces(col+2, line-4, 2)
	spaces(col+7, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+8, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+8, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+6, line-1, 3)
	spaces(col+3, line,   4)
	spaces(col+8, line,   3)
	TTY:write(sgr0)
	return c2width['Q']
end
local function char_R (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 8)
	spaces(col+7, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+8, line-4, 2)
	spaces(col+1, line-3, 8)
	spaces(col+1, line-2, 2)
	spaces(col+5, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 3)
	spaces(col+1, line,   2)
	spaces(col+8, line,   2)
	TTY:write(sgr0)
	return c2width['R']
end
local function char_S (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 7)
	spaces(col+1, line-4, 2)
	spaces(col+2, line-3, 6)
	spaces(col+7, line-2, 2)
	spaces(col+7, line-1, 2)
	spaces(col+1, line,   7)
	TTY:write(sgr0)
	return c2width['S']
end
local function char_T (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5,10)
	spaces(col+5, line-4, 2)
	spaces(col+5, line-3, 2)
	spaces(col+5, line-2, 2)
	spaces(col+5, line-1, 2)
	spaces(col+5, line,   2)
	TTY:write(sgr0)
	return c2width['T']
end
local function char_U (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+9, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+9, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+9, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+9, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+8, line-1, 2)
	spaces(col+3, line,   6)
	TTY:write(sgr0)
	return c2width['U']
end
local function char_V (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+9, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+9, line-4, 2)
	spaces(col+2, line-3, 2)
	spaces(col+8, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+7, line-2, 2)
	spaces(col+4, line-1, 4)
	spaces(col+5, line,   2)
	TTY:write(sgr0)
	return c2width['V']
end
local function char_W (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+9, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+9, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+5, line-3, 2)
	spaces(col+9, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+5, line-2, 2)
	spaces(col+9, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+4, line-1, 4)
	spaces(col+9, line-1, 2)
	spaces(col+2, line,   3)
	spaces(col+7, line,   3)
	TTY:write(sgr0)
	return c2width['W']
end
local function char_X (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+8, line-5, 2)
	spaces(col+2, line-4, 2)
	spaces(col+7, line-4, 2)
	spaces(col+3, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+4, line-2, 3)
	spaces(col+3, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+8, line,   2)
	TTY:write(sgr0)
	return c2width['X']
end
local function char_Y (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+9, line-5, 2)
	spaces(col+2, line-4, 2)
	spaces(col+8, line-4, 2)
	spaces(col+3, line-3, 2)
	spaces(col+7, line-3, 2)
	spaces(col+4, line-2, 4)
	spaces(col+5, line-1, 2)
	spaces(col+5, line,   2)
	TTY:write(sgr0)
	return c2width['Y']
end
local function char_Z (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 7)
	spaces(col+5, line-4, 2)
	spaces(col+4, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+1, line,   7)
	TTY:write(sgr0)
	return c2width['Z']
end

-------------- lower case -------------------
local function char_a (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-4, 4)
	spaces(col+8, line-4, 1)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 3)
	spaces(col+1, line-2, 2)
	spaces(col+7, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+6, line-1, 3)
	spaces(col+3, line,   4)
	spaces(col+8, line,   1)
	TTY:write(sgr0)
	return c2width['a']
end
local function char_a_uml (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 1)
	spaces(col+6, line-5, 1)
	-- spaces(col+3, line-4, 4)
	spaces(col+4, line-4, 2)
	spaces(col+8, line-4, 1)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 3)
	spaces(col+1, line-2, 2)
	spaces(col+7, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+6, line-1, 3)
	spaces(col+3, line,   4)
	spaces(col+8, line,   1)
	TTY:write(sgr0)
	return c2width['a']
end
local function char_b (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+1, line-4, 5)
	spaces(col+1, line-3, 2)
	spaces(col+5, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+5, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+5, line-1, 2)
	spaces(col+1, line,   5)
	TTY:write(sgr0)
	return c2width['b']
end
local function char_c (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-4, 5)
	spaces(col+2, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+3, line,   5)
	TTY:write(sgr0)
	return c2width['c']
end
local function char_d (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+6, line-5, 2)
	spaces(col+3, line-4, 5)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+3, line,   5)
	TTY:write(sgr0)
	return c2width['d']
end
local function char_e (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-4, 4)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+1, line-2, 7)
	spaces(col+2, line-1, 2)
	spaces(col+3, line,   4)
	TTY:write(sgr0)
	return c2width['e']
end
local function char_f (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+4, line-5, 3)
	spaces(col+3, line-4, 2)
	spaces(col+3, line-3, 2)
	spaces(col+1, line-2, 6)
	spaces(col+3, line-1, 2)
	spaces(col+3, line,   2)
	spaces(col+1, line+1, 3)
	TTY:write(sgr0)
	return c2width['f']
end
local function char_g (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-4, 4)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+7, line-2, 2)
	spaces(col+2, line-1, 7)
	spaces(col+7, line,   2)
	spaces(col+2, line+1, 6)
	TTY:write(sgr0)
	return c2width['g']
end
local function char_h (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 6)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+6, line,   2)
	TTY:write(sgr0)
	return c2width['h']
end
local function char_i (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['i']
end
local function char_j (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 2)
	spaces(col+3, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+3, line-1, 2)
	spaces(col+3, line,   2)
	spaces(col+1, line+1, 3)
	TTY:write(sgr0)
	return c2width['j']
end
local function char_k (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+4, line-3, 2)
	spaces(col+1, line-2, 4)
	spaces(col+1, line-1, 2)
	spaces(col+4, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+5, line,   2)
	TTY:write(sgr0)
	return c2width['k']
end
local function char_l (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['l']
end
local function char_m (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-4, 3)
	spaces(col+6, line-4, 3)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-3, 2)
	spaces(col+4, line-3, 3)
	spaces(col+8, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+5, line-2, 1)
	spaces(col+8, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+8, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+8, line,   2)
	TTY:write(sgr0)
	return c2width['m']
end
local function char_n (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 1)
	spaces(col+3, line-4, 3)
	spaces(col+1, line-3, 2)
	spaces(col+5, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+6, line,   2)
	TTY:write(sgr0)
	return c2width['n']
end
local function char_o (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-4, 4)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+7, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+3, line,   4)
	TTY:write(sgr0)
	return c2width['o']
end
local function char_o_uml (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 1)
	spaces(col+6, line-5, 1)
	-- spaces(col+3, line-4, 4)
	spaces(col+4, line-4, 2)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+7, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+3, line,   4)
	TTY:write(sgr0)
	return c2width['o']
end
local function char_p (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 1)
	spaces(col+3, line-4, 3)
	spaces(col+1, line-3, 2)
	spaces(col+5, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+5, line-1, 2)
	spaces(col+1, line,   5)
	spaces(col+1, line+1, 2)
	TTY:write(sgr0)
	return c2width['p']
end
local function char_q (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-4, 3)
	spaces(col+7, line-4, 1)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+3, line,   5)
	spaces(col+6, line+1, 2)
	TTY:write(sgr0)
	return c2width['q']
end
local function char_r (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 1)
	spaces(col+3, line-4, 3)
	spaces(col+1, line-3, 3)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['r']
end
local function char_s (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-4, 5)
	spaces(col+1, line-3, 2)
	spaces(col+2, line-2, 4)
	spaces(col+5, line-1, 2)
	spaces(col+1, line,   5)
	TTY:write(sgr0)
	return c2width['s']
end
local function char_t (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 5)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+2, line,   5)
	TTY:write(sgr0)
	return c2width['t']
end
local function char_u (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 2)
	spaces(col+6, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+2, line,   5)
	TTY:write(sgr0)
	return c2width['u']
end
local function char_u_uml (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 1)
	spaces(col+5, line-5, 1)
	spaces(col+1, line-4, 1)
	spaces(col+7, line-4, 1)
	spaces(col+1, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+2, line,   5)
	TTY:write(sgr0)
	return c2width['u']
end
local function char_v (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 2)
	spaces(col+7, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+7, line-3, 2)
	spaces(col+2, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+3, line-1, 4)
	spaces(col+4, line,   2)
	TTY:write(sgr0)
	return c2width['v']
end
local function char_w (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 2)
	spaces(col+8, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+5, line-3, 1)
	spaces(col+8, line-3, 2)
	spaces(col+2, line-2, 1)
	spaces(col+8, line-2, 1)
	spaces(col+4, line-2, 3)
	spaces(col+2, line-1, 3)
	spaces(col+6, line-1, 3)
	spaces(col+3, line,   2)
	spaces(col+6, line,   2)
	TTY:write(sgr0)
	return c2width['w']
end
local function char_x (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 2)
	spaces(col+6, line-4, 2)
	spaces(col+2, line-3, 2)
	spaces(col+5, line-3, 2)
	spaces(col+3, line-2, 3)
	spaces(col+2, line-1, 2)
	spaces(col+5, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+6, line,   2)
	TTY:write(sgr0)
	return c2width['x']
end
local function char_y (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 2)
	spaces(col+7, line-4, 2)
	spaces(col+2, line-3, 2)
	spaces(col+6, line-3, 2)
	spaces(col+3, line-2, 4)
	spaces(col+4, line-1, 2)
	spaces(col+4, line,   2)
	TTY:write(sgr0)
	return c2width['y']
end
local function char_z (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-4, 6)
	spaces(col+4, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+1, line,   6)
	TTY:write(sgr0)
	return c2width['z']
end

--------------- punctuation -----------------
local function char_question (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 6)
	spaces(col+1, line-4, 2)
	spaces(col+7, line-4, 2)
	spaces(col+6, line-3, 2)
	spaces(col+4, line-2, 3)
	spaces(col+4, line,   2)
	TTY:write(sgr0)
	return c2width['?']
end
local function char_exclamation (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['!']
end
local function char_colon (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-2, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width[':']
end
local function char_dot (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['.']
end
local function char_semicolon (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-2, 2)
	spaces(col+2, line,   2)
	spaces(col+1, line+1, 2)
	TTY:write(sgr0)
	return c2width[';']
end
local function char_comma (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line,   2)
	spaces(col+1, line+1, 2)
	TTY:write(sgr0)
	return c2width[',']
end
local function char_dash (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-2, 5)
	TTY:write(sgr0)
	return c2width['-']
end
local function char_plus (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-3, 2)
	spaces(col+1, line-2, 6)
	spaces(col+3, line-1, 2)
	TTY:write(sgr0)
	return c2width['+']
end

-------------------- digits -------------------
local function char_0 (col,line, colour)  -- zero
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 6)
	spaces(col+2, line-4, 2)
	spaces(col+7, line-4, 3)
	spaces(col+1, line-3, 2)
	spaces(col+6, line-3, 1)
	spaces(col+9, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+5, line-2, 1)
	spaces(col+9, line-2, 2)
	spaces(col+2, line-1, 3)
	spaces(col+8, line-1, 2)
	spaces(col+3, line,   6)
	TTY:write(sgr0)
	return c2width['0']
end
local function char_1 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 2)
	spaces(col+1, line-4, 4)
	spaces(col+3, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+3, line-1, 2)
	spaces(col+1, line,   6)
	TTY:write(sgr0)
	return c2width['1']
end
local function char_2 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 5)
	spaces(col+1, line-4, 2)
	spaces(col+6, line-4, 2)
	spaces(col+5, line-3, 2)
	spaces(col+3, line-2, 3)
	spaces(col+2, line-1, 2)
	spaces(col+1, line,   7)
	TTY:write(sgr0)
	return c2width['2']
end
local function char_3 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 5)
	spaces(col+1, line-4, 2)
	spaces(col+6, line-4, 2)
	spaces(col+4, line-3, 3)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+2, line,   5)
	TTY:write(sgr0)
	return c2width['3']
end
local function char_4 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+4, line-5, 3)
	spaces(col+3, line-4, 4)
	spaces(col+2, line-3, 2)
	spaces(col+5, line-3, 2)
	spaces(col+5, line-2, 2)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 8)
	spaces(col+5, line,   2)
	TTY:write(sgr0)
	return c2width['4']
end
local function char_5 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 6)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 6)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+5, line-1, 2)
	spaces(col+2, line,   4)
	TTY:write(sgr0)
	return c2width['5']
end
local function char_6 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 4)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 6)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+5, line-1, 2)
	spaces(col+2, line,   4)
	TTY:write(sgr0)
	return c2width['6']
end
local function char_7 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 6)
	spaces(col+5, line-4, 2)
	spaces(col+4, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['7']
end
local function char_8 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 5)
	spaces(col+1, line-4, 2)
	spaces(col+6, line-4, 2)
	spaces(col+2, line-3, 5)
	spaces(col+1, line-2, 2)
	spaces(col+6, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+2, line,   5)
	TTY:write(sgr0)
	return c2width['8']
end
local function char_9 (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 5)
	spaces(col+1, line-4, 2)
	spaces(col+6, line-4, 2)
	spaces(col+2, line-3, 6)
	spaces(col+6, line-2, 2)
	spaces(col+5, line-1, 2)
	spaces(col+2, line,   4)
	TTY:write(sgr0)
	return c2width['9']
end
local function char_slash (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+6, line-5, 2)
	spaces(col+5, line-4, 2)
	spaces(col+4, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['/']
end
local function char_backslash (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+2, line-4, 2)
	spaces(col+3, line-3, 2)
	spaces(col+4, line-2, 2)
	spaces(col+5, line-1, 2)
	spaces(col+6, line,   2)
	TTY:write(sgr0)
	return c2width['\\']
end
local function char_underscore (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line, 9)
	TTY:write(sgr0)
	return c2width['_']
end
local function char_bar (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   2)
	TTY:write(sgr0)
	return c2width['|']
end
local function char_equals (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-3, 6)
	spaces(col+1, line-1, 6)
	TTY:write(sgr0)
	return c2width['=']
end
local function char_space (col,line, colour)
	return c2width[' ']
end
local function char_snail (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 6)
	spaces(col+1, line-4, 2)
	spaces(col+7, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+4, line-3, 2)
	spaces(col+7, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+4, line-2, 4)
	spaces(col+1, line-1, 2)
	spaces(col+2, line,   6)
	TTY:write(sgr0)
	return c2width['@']
end
local function char_percent (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+6, line-5, 2)
	spaces(col+5, line-4, 2)
	spaces(col+4, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+2, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+6, line,   2)
	TTY:write(sgr0)
	return c2width['%']
end
local function char_ampersand (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+4, line-5, 4)
	spaces(col+3, line-4, 2)
	spaces(col+7, line-4, 2)
	spaces(col+4, line-3, 4)
	spaces(col+2, line-2, 3)
	spaces(col+7, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+6, line-1, 2)
	spaces(col+2, line,   5)
	spaces(col+8, line,   2)
	TTY:write(sgr0)
	return c2width['&']
end
local function char_dollar (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+4, line-5, 1) ; spaces(col+6, line-5, 1)
	spaces(col+2, line-4, 8)
	spaces(col+1, line-3, 2)
	spaces(col+4, line-3, 1) ; spaces(col+6, line-3, 1)
	spaces(col+2, line-2, 7)
	spaces(col+8, line-1, 2)
	spaces(col+4, line-1, 1) ; spaces(col+6, line-1, 1)
	spaces(col+1, line,   8)
	spaces(col+4, line+1, 1) ; spaces(col+6, line+1, 1)
	TTY:write(sgr0)
	return c2width['$']
end
------------------brackets -------------------
local function char_opensquare (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 4)
	spaces(col+1, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+1, line,   2)
	spaces(col+1, line+1, 4)
	TTY:write(sgr0)
	return c2width['[']
end
local function char_closesquare (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 4)
	spaces(col+3, line-4, 2)
	spaces(col+3, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+3, line-1, 2)
	spaces(col+3, line,   2)
	spaces(col+1, line+1, 4)
	TTY:write(sgr0)
	return c2width[']']
end
local function char_openbracket (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 2)
	spaces(col+2, line-4, 2)
	spaces(col+1, line-3, 2)
	spaces(col+1, line-2, 2)
	spaces(col+1, line-1, 2)
	spaces(col+2, line,   2)
	spaces(col+3, line+1, 2)
	TTY:write(sgr0)
	return c2width['(']
end
local function char_closebracket (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+2, line-4, 2)
	spaces(col+3, line-3, 2)
	spaces(col+3, line-2, 2)
	spaces(col+3, line-1, 2)
	spaces(col+2, line,   2)
	spaces(col+1, line+1, 2)
	TTY:write(sgr0)
	return c2width['(']
end
local function char_opencurly (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 2)
	spaces(col+2, line-4, 2)
	spaces(col+2, line-3, 2)
	spaces(col+1, line-2, 3)
	spaces(col+2, line-1, 2)
	spaces(col+2, line,   2)
	spaces(col+3, line+1, 2)
	TTY:write(sgr0)
	return c2width['{']
end
local function char_closecurly (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 2)
	spaces(col+2, line-4, 2)
	spaces(col+2, line-3, 2)
	spaces(col+2, line-2, 3)
	spaces(col+2, line-1, 2)
	spaces(col+2, line,   2)
	spaces(col+1, line+1, 2)
	TTY:write(sgr0)
	return c2width['}']
end
--------------------misc ----------------------
local function char_caret (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 2)
	spaces(col+2, line-4, 1)
	spaces(col+5, line-4, 1)
	spaces(col+1, line-3, 1)
	spaces(col+6, line-3, 1)
	TTY:write(sgr0)
	return c2width['^']
end
local function char_hash (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-5, 1)
	spaces(col+4, line-5, 1)
	spaces(col+2, line-4, 1)
	spaces(col+4, line-4, 1)
	spaces(col+1, line-3, 5)
	spaces(col+2, line-2, 1)
	spaces(col+4, line-2, 1)
	spaces(col+1, line-1, 5)
	spaces(col+2, line,   1)
	spaces(col+4, line,   1)
	spaces(col+2, line+1, 1)
	spaces(col+4, line+1, 1)
	TTY:write(sgr0)
	return c2width['#']
end
local function char_asterisc (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+2, line-3, 1)
	spaces(col+4, line-3, 1)
	spaces(col+1, line-2, 1)
	spaces(col+3, line-2, 1)
	spaces(col+5, line-2, 1)
	spaces(col+2, line-1, 1)
	spaces(col+4, line-1, 1)
	TTY:write(sgr0)
	return c2width['*']
end
local function char_tilde (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+3, line-5, 1)
	spaces(col+1, line-4, 2)
	spaces(col+4, line-4, 1)
	spaces(col+6, line-4, 2)
	spaces(col+5, line-3, 1)
	TTY:write(sgr0)
	return c2width['~']
end
local function char_quote (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 1)
	TTY:write(sgr0)
	return c2width["'"]
end
local function char_doublequote (col,line, colour)
	if colour then fg_color(colour) end
	TTY:write(rev)
	spaces(col+1, line-5, 1)
	spaces(col+3, line-5, 1)
	TTY:write(sgr0)
	return c2width['"']
end
-- XXX
local function char_test (col,line, colour)
	TTY:write(rev)
	fg_color('black')  ; moveto(col, line-5) ; TTY:write('  ')
	fg_color('yellow') ; moveto(col, line-4) ; TTY:write('  ')
	fg_color('black')  ; moveto(col, line-3) ; TTY:write('  ')
	fg_color('yellow') ; moveto(col, line-2) ; TTY:write('  ')
	fg_color('black')  ; moveto(col, line-1) ; TTY:write('  ')
	fg_color('yellow') ; moveto(col, line)   ; TTY:write('  ')
	fg_color('black')  ; moveto(col, line+1) ; TTY:write('  ')
	TTY:write(sgr0)
	return 2
end

-------------------- spacing, kerning -----------------
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
	['-']=char_dash, ['/']=char_slash, ['\\']=char_backslash,
	['$']=char_dollar, ['|']=char_bar, ['@']=char_snail, ['#']=char_hash,
	['~']=char_tilde, ['%']=char_percent, ['&']=char_ampersand,
	['*']=char_asterisc, ['^']=char_caret,
	['(']=char_openbracket,  ['[']=char_opensquare,  ['{']=char_opencurly,
	[')']=char_closebracket, [']']=char_closesquare, ['}']=char_closecurly,
	['\t']=char_test,
	['\196']=char_A_uml, ['\214']=char_O_uml, ['\220']=char_U_uml,
	['\228']=char_a_uml, ['\246']=char_o_uml, ['\252']=char_u_uml,
}
local c2height = {
	[',']=8, [';']=8, ['f']=8, ['g']=8, ['j']=8, ['p']=8, ['q']=8, ['y']=8,
	['[']=8, [']']=8, ['(']=8, [')']=8, ['{']=8, ['}']=8, ['#']=8,
}
-- for better kerning in M.show(), see also function is_good_fit(a,b) ...
local convex_right = {
	['b']=true, ['o']=true, ['p']=true, ['-']=true, ['+']=true, ['^']=true,
	['6']=true,
}
local concave_left = {
	['I']=true, ['J']=true, ['L']=true, ['T']=true, ['j']=true,
	['.']=true, [',']=true, [')']=true, [']']=true, ['_']=true,
	["'"]=true, ['"']=true,
}
local convex_left = {
	['a']=true, ['c']=true, ['d']=true, ['e']=true, ['o']=true,
	['q']=true, ['-']=true, ['+']=true,
}
local concave_right = {
	['C']=true, ['F']=true, ['I']=true, ['T']=true,
	['c']=true, ['.']=true, ['(']=true, ['[']=true, ['_']=true,
	["'"]=true, ['"']=true,
}

---------------------- 4-line utf8-based font ----------------------

function M.utf8char_A (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(lower..upper..upper..lower)
	moveto(col, line-1) ; TTY:write(both..lower..lower..both)
	moveto(col, line)   ; TTY:write(both..'  '..both)
	TTY:flush()
	return 5
end
function M.utf8char_B (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..upper..upper..lower)
	moveto(col, line-1) ; TTY:write(both..upper..upper..lower)
	moveto(col, line)   ; TTY:write(both..lower..lower..upper)
	TTY:flush()
	return 5
end
function M.utf8char_C (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(lower..upper..upper..upper)
	moveto(col, line-1) ; TTY:write(both)
	moveto(col, line)   ; TTY:write(upper..lower..lower..lower)
	TTY:flush()
	return 5
end
function M.utf8char_D (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..upper..upper..lower)
	moveto(col, line-1) ; TTY:write(both..'  '..both)
	moveto(col, line)   ; TTY:write(both..lower..lower..upper)
	TTY:flush()
	return 5
end
function M.utf8char_E (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..upper..upper..upper)
	moveto(col, line-1) ; TTY:write(both..upper..upper)
	moveto(col, line)   ; TTY:write(both..lower..lower..lower)
	TTY:flush()
	return 5
end
function M.utf8char_F (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..upper..upper..upper)
	moveto(col, line-1) ; TTY:write(both..upper..upper)
	moveto(col, line)   ; TTY:write(both)
	TTY:flush()
	return 5
end
function M.utf8char_G (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(lower..upper..upper..upper)
	moveto(col, line-1) ; TTY:write(both..' '..lower..lower)
	moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
	TTY:flush()
	return 5
end
function M.utf8char_H (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..'  '..both)
	moveto(col, line-1) ; TTY:write(both..upper..upper..both)
	moveto(col, line)   ; TTY:write(both..'  '..both)
	TTY:flush()
	return 5
end
function M.utf8char_I (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(upper..both..upper)
	moveto(col, line-1) ; TTY:write(' '..both)
	moveto(col, line)   ; TTY:write(lower..both..lower)
	TTY:flush()
	return 4
end
function M.utf8char_J (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(' '..upper..both..upper)
	moveto(col, line-1) ; TTY:write('  '..both)
	moveto(col, line)   ; TTY:write(lower..lower..upper)
	TTY:flush()
	return 5
end
function M.utf8char_K (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..' '..lower..upper)
	moveto(col, line-1) ; TTY:write(both..upper..lower)
	moveto(col, line)   ; TTY:write(both..'  '..upper..lower)
	TTY:flush()
	return 6
end
function M.utf8char_L (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both)
	moveto(col, line-1) ; TTY:write(both)
	moveto(col, line)   ; TTY:write(both..lower..lower..lower)
	TTY:flush()
	return 5
end
function M.utf8char_M (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..lower..' '..lower..both)
	moveto(col, line-1) ; TTY:write(both..' '..upper..' '..both)
	moveto(col, line)   ; TTY:write(both..'   '..both)
	TTY:flush()
	return 6
end
function M.utf8char_N (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..lower..'  '..both)
	moveto(col, line-1) ; TTY:write(both..' '..upper..lower..both)
	moveto(col, line)   ; TTY:write(both..'   '..both)
	TTY:flush()
	return 6
end
function M.utf8char_O (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(lower..upper..upper..lower)
	moveto(col, line-1) ; TTY:write(both..'  '..both)
	moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
	TTY:flush()
	return 5
end
function M.utf8char_P (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..upper..upper..lower)
	moveto(col, line-1) ; TTY:write(both..lower..lower..upper)
	moveto(col, line)   ; TTY:write(both)
	TTY:flush()
	return 5
end
function M.utf8char_Q (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(lower..upper..upper..upper..lower)
	moveto(col, line-1) ; TTY:write(both..'  '..lower..both)
	moveto(col, line)   ; TTY:write(upper..lower..both..upper..lower)
	TTY:flush()
	return 6
end
function M.utf8char_R (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..upper..upper..upper..lower)
	moveto(col, line-1) ; TTY:write(both..upper..both..upper)
	moveto(col, line)   ; TTY:write(both..'  '..upper..both)
	TTY:flush()
	return 6
end
function M.utf8char_S (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(lower..upper..upper..upper)
	moveto(col, line-1) ; TTY:write(' '..upper..upper..lower)
	moveto(col, line)   ; TTY:write(lower..lower..lower..upper)
	TTY:flush()
	return 5
end
function M.utf8char_T (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(upper..upper..both..upper..upper)
	moveto(col+2, line-1) ; TTY:write(both)
	moveto(col+2, line)   ; TTY:write(both)
	TTY:flush()
	return 6
end
function M.utf8char_U (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..'  '..both)
	moveto(col, line-1) ; TTY:write(both..'  '..both)
	moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
	TTY:flush()
	return 5
end
function M.utf8char_V (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..'   '..both)
	moveto(col+1, line-1) ; TTY:write(both..' '..both)
	moveto(col+2, line)   ; TTY:write(both)
	TTY:flush()
	return 6
end
function M.utf8char_W (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..'   '..both)
	moveto(col, line-1) ; TTY:write(both..' '..both..' '..both)
	moveto(col, line)   ; TTY:write(both..lower..upper..lower..both)
	TTY:flush()
	return 6
end
function M.utf8char_X (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..'   '..both)
	moveto(col+1, line-1) ; TTY:write(upper..lower..upper)
	moveto(col, line)   ; TTY:write(lower..upper..' '..upper..lower)
	TTY:flush()
	return 6
end
function M.utf8char_Y (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both..'   '..both)
	moveto(col+1, line-1) ; TTY:write(upper..lower..upper)
	moveto(col+2, line)   ; TTY:write(both)
	TTY:flush()
	return 6
end
function M.utf8char_Z (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(upper..upper..upper..both..upper)
	moveto(col+1, line-1) ; TTY:write(lower..upper)
	moveto(col, line)   ; TTY:write(both..lower..lower..lower..lower)
	TTY:flush()
	return 6
end
function M.utf8char_question (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(lower..upper..upper..upper..lower)
	moveto(col+2, line-1) ; TTY:write(lower..upper)
	moveto(col+2, line)   ; TTY:write(lower)
	TTY:flush()
	return 6
end
function M.utf8char_exclamation (col,line, colour)
	fg_color(colour)
	moveto(col, line-2) ; TTY:write(both)
	moveto(col, line-1) ; TTY:write(both)
	moveto(col, line)   ; TTY:write(lower)
	TTY:flush()
	return 2
end
function M.utf8char_dot (col,line, colour)
	fg_color(colour)
	moveto(col, line)   ; TTY:write(lower)
	TTY:flush()
	return 2
end
function M.utf8char_comma (col,line, colour)
	fg_color(colour)
	moveto(col+1, line)   ; TTY:write(lower)
	moveto(col, line+1) ; TTY:write(upper)
	TTY:flush()
	return 3
end
function M.utf8char_colon (col,line, colour)
	fg_color(colour)
	moveto(col, line-1) ; TTY:write(lower)
	moveto(col, line)   ; TTY:write(lower)
	TTY:flush()
	return 2
end
function M.utf8char_semicolon (col,line, colour)
	fg_color(colour)
	moveto(col+1, line-1) ; TTY:write(lower)
	moveto(col+1, line)   ; TTY:write(lower)
	moveto(col, line+1)   ; TTY:write(upper)
	TTY:flush()
	return 3
end

------------------------------ public ------------------------------

function M.show_char (col,line, c, colour)
	local func = c2func[c]
	if not func then return 0 end
	return func(col,line,colour)
end

function M.show (col,line, str, colour)
	col = round(col) ; line = round(line)  -- should be integers
	str = utf2iso(str) -- the string has to be either iso OR utf, not a mix !
	-- str = string.gsub(str, '\194', '')
	-- str = string.gsub(str, '\195(.)', '') -- see p.210, add 128 to byte(.)
	local width = 0
	local height = 7
	local previous_c = nil
	for i = 1, str:len() do
		local c = string.sub(str,i,i)
		if previous_c then  -- kerning
			if  (concave_right[previous_c] and convex_left[c])
			  or (convex_right[previous_c] and concave_left[c])
			  or is_good_fit(previous_c, c)  then
				col = col - 1
			end
		end
		charwidth = M.show_char(col,line, c, colour)
		width = width + charwidth
		col = col + charwidth
		if c2height[c] then height = 8 end
		previous_c = c
	end
	TTY:flush()
	return width, height
end

function M.stringwidth (str)
	local width  = 0
	local height = 7
	local previous_c = nil
	for i = 1, str:len() do
		local c = string.sub(str,i,i)
		if previous_c then  -- kerning
			if  (concave_right[previous_c] and convex_left[c])
			  or (convex_right[previous_c] and concave_left[c])
			  or is_good_fit(c, string.sub(str,i+1,i+1))  then
				width = width - 1
			end
		end
		width = width + c2width[c]
		if c2height[c] then height = 8 end
		previous_c = c
	end
	return width, height
end

function M.rectfill (col,line, width,height, colour)
	if not col    then return nil,'rectfill: col was nil'    end
	if not line   then return nil,'rectfill: line was nil'   end
	if not width  then return nil,'rectfill: width was nil'  end
	if not height then return nil,'rectfill: height was nil' end
	col   = round(col)   ; line   = round(line)    -- should be integers
	width = round(width) ; height = round(height)  -- should be integers
	TTY:write(rev)
	if colour then fg_color(colour) end
	for i = 0, height-1 do spaces(col, line-i, width) end
	TTY:write(sgr0)
	TTY:flush()
	return true
end

function M.setfontsize (nlines)
	if nlines == 4 or nlines == 7 then
		fontsize = nlines
	else
		warn('fontsize must be either 7 or 4, not', nlines)
	end
end

function M.clear ()
	M.moveto(0,0)
	TTY:write(TI.get('ed'))
	TTY:flush()
end
function M.civis ()
	TTY:write(civis)
	TTY:flush()
end
function M.cnorm ()
	TTY:write(cnorm)
	TTY:flush()
end

M.lines  = lines
M.cols   = cols
M.moveto = moveto

return M

--[=[

=pod

=head1 NAME

terminfofont.lua - does whatever

=head1 SYNOPSIS

 local M = require 'terminfofont'
 a = { 6,8,7,9,8 }
 b = { 4,7,5,4,5,6,4 }
 local probability_of_hypothesis_being_wrong = M.ttest(a,b,'b>a')

=head1 DESCRIPTION

This module does whatever

note:
  echo -n 'https://pjb.com.au' | qrencode -m 1 -t UTF8 -o /tmp/t.txt
shows that UTF8 can give me the half-height characters !
  print('\xe2\x96\x88\x20\xe2\x96\x84\xe2\x96\x80')
prints black, white, lower-half black, upper-half black

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
http://pjb.com.au/comp/lua/terminfofont.html

=head1 AUTHOR

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://pjb.com.au/
 https://luarocks.org/modules/kikito/ansicolors
 https://github.com/kikito/ansicolors.lua

=cut

]=]

