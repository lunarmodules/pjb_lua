---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2019, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- TODO: half-height rectfill, umlauts
-- show(string, colour)
--   hpa 0   goes to horizontal position 0 for the no-y call to show ...
--   BUT this is difficult: col and line are written into every character :-(
-- cuu1 cud1    also   csr linetop linebot   also sc and rc
-- also margins: smglp

local M = {} -- public interface
M.Version     = '0.8'
M.VersionDate = '1dec2019'

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

local c2width, c2func, c2height
local convex_right, concave_left, convex_left, concave_right

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
	local c = {
	  black=0, red=1, green=2, yellow=3, blue=4, violet=5, cyan=6, white=7 }
	if type(i) == 'string' then
		if not c[i] then return nil, 'unknown colour '..i end
		i = c[i]
	end
	if i < 0 or i > 7 then
		return nil, format('color %g is out of the 0..7 range',i)
	end
	TTY:write(format("\027[3%dm", i))
end
local function utf2iso (raw_str)
	if string.match(raw_str, '[\194,\195]') then
		-- http://lua-users.org/lists/lua-l/2015-02/msg00173.html
		-- fails on euro-sign 
-- BUG XXX utf8 does not exist on 5.2 or less !
-- I should do it by hand ...
-- if first char is xC3 then delete it and add 64 to the second char
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

---------------------- 7-line ascii-based font ----------------------

local c2width_7 = {
	['A']=12, ['B']=11, ['C']=10, ['D']=11, ['E']=10,
	['F']=10, ['G']=11, ['H']=11, ['I']=8,  ['J']=10,
	['K']=10, ['L']=10, ['M']=12, ['N']=12, ['O']=12,
	['P']=11, ['Q']=12, ['R']=11, ['S']=10, ['T']=12,
	['U']=12, ['V']=12, ['W']=12, ['X']=11, ['Y']=12, ['Z']=9,
	['a']=10, ['b']=8,  ['c']=9,  ['d']=9,  ['e']=9,
	['f']=8,  ['g']=10, ['h']=9,  ['i']=4,  ['j']=6,
	['k']=8,  ['l']=5,  ['m']=11, ['n']=9,  ['o']=10,
	['p']=9,  ['q']=9,  ['r']=7,  ['s']=8,  ['t']=7,
	['u']=9,  ['v']=10, ['w']=11, ['x']=9,  ['y']=10,
	['z']=8,  [' ']=7,  ["'"]=3, ['"']=5,
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
	['\xE4']=10, ['\xF6']=10, ['\xFC']=9,  --a,o,u umlaut
}

local function is_good_fit (a,b)
	if not b then return false end
	if (a=='F' or a=='T' or a=='"' or a=="'" or a=='/') and
	 (b=='A' or b=='C' or b=='G' or b=='O' or b=='.' or b==',' or
	  b=='Q' or b=='0' or b=='4' or b=='_' or b=='/') then
		return true
	elseif (a=='L' or a=='Q' or a=='k' or a=='t' or a=='1' or a=='\\' or
	        a=='&' or a=='_' or a=='.' or a==',') and
	 (b=='C' or b=='O' or b=='Q'  or b=='T' or b=='U' or
	  b=='V' or b=='Y' or b=='l' or b=='\\' or b=='0') then
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

local c2func_7 = {
	------------------------- uppercase ---------------------
	['A'] = function (col,line)
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
	end ,
	['B'] = function (col,line)
		spaces(col+1, line-5, 8)
		spaces(col+1, line-4, 2)
		spaces(col+8, line-4, 2)
		spaces(col+1, line-3, 8)
		spaces(col+1, line-2, 2)
		spaces(col+8, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+8, line-1, 2)
		spaces(col+1, line,   8)
	end ,
	['C'] = function (col,line)
		spaces(col+3, line-5, 6)
		spaces(col+2, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+3, line,   6)
	end ,
	['D'] = function (col,line)
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
	end ,
	['E'] = function (col,line)
		spaces(col+1, line-5, 8)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 6)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+1, line,   8)
	end ,
	['F'] = function (col,line)
		spaces(col+1, line-5, 8)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 6)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+1, line,   2)
	end ,
	['G'] = function (col,line)
		spaces(col+3, line-5, 7)
		spaces(col+2, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+6, line-2, 4)
		spaces(col+1, line-1, 2)
		spaces(col+7, line-1, 2)
		spaces(col+2, line,   7)
	end ,
	['H'] = function (col,line)
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
	end ,
	['I'] = function (col,line)
		spaces(col+1, line-5, 6)
		spaces(col+3, line-4, 2)
		spaces(col+3, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+3, line-1, 2)
		spaces(col+1, line,   6)
	end ,
	['J'] = function (col,line)
		spaces(col+1, line-5, 8)
		spaces(col+6, line-4, 2)
		spaces(col+6, line-3, 2)
		spaces(col+6, line-2, 2)
		spaces(col+5, line-1, 2)
		spaces(col+1, line,   5)
	end ,
	['K'] = function (col,line)
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
	end ,
	['L'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+1, line,   8)
	end ,
	['M'] = function (col,line)
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
	end ,
	['N'] = function (col,line)
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
	end ,
	['O'] = function (col,line)
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
	end ,
	['P'] = function (col,line)
		spaces(col+1, line-5, 8)
		spaces(col+1, line-4, 2)
		spaces(col+8, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+8, line-3, 2)
		spaces(col+1, line-2, 8)
		spaces(col+1, line-1, 2)
		spaces(col+1, line,   2)
	end ,
	['Q'] = function (col,line)
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
	end ,
	['R'] = function (col,line)
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
	end ,
	['S'] = function (col,line)
		spaces(col+2, line-5, 7)
		spaces(col+1, line-4, 2)
		spaces(col+2, line-3, 6)
		spaces(col+7, line-2, 2)
		spaces(col+7, line-1, 2)
		spaces(col+1, line,   7)
	end ,
	['T'] = function (col,line)
		spaces(col+1, line-5,10)
		spaces(col+5, line-4, 2)
		spaces(col+5, line-3, 2)
		spaces(col+5, line-2, 2)
		spaces(col+5, line-1, 2)
		spaces(col+5, line,   2)
	end ,
	['U'] = function (col,line)
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
	end ,
	['V'] = function (col,line)
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
	end ,
	['W'] = function (col,line)
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
	end ,
	['X'] = function (col,line)
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
	end ,
	['Y'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+9, line-5, 2)
		spaces(col+2, line-4, 2)
		spaces(col+8, line-4, 2)
		spaces(col+3, line-3, 2)
		spaces(col+7, line-3, 2)
		spaces(col+4, line-2, 4)
		spaces(col+5, line-1, 2)
		spaces(col+5, line,   2)
	end ,
	['Z'] = function (col,line)
		spaces(col+1, line-5, 7)
		spaces(col+5, line-4, 2)
		spaces(col+4, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+1, line,   7)
	end ,
	-------------- lower case -------------------
	['a'] = function (col,line)
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
	end ,
	['\228'] = function (col,line)
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
	end ,
	['b'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+1, line-4, 5)
		spaces(col+1, line-3, 2)
		spaces(col+5, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+5, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+5, line-1, 2)
		spaces(col+1, line,   5)
	end ,
	['c'] = function (col,line)
		spaces(col+3, line-4, 5)
		spaces(col+2, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+3, line,   5)
	end ,
	['d'] = function (col,line)
		spaces(col+6, line-5, 2)
		spaces(col+3, line-4, 5)
		spaces(col+2, line-3, 2)
		spaces(col+6, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+6, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+6, line-1, 2)
		spaces(col+3, line,   5)
	end ,
	['e'] = function (col,line)
		spaces(col+3, line-4, 4)
		spaces(col+2, line-3, 2)
		spaces(col+6, line-3, 2)
		spaces(col+1, line-2, 7)
		spaces(col+2, line-1, 2)
		spaces(col+3, line,   4)
	end ,
	['f'] = function (col,line)
		spaces(col+4, line-5, 3)
		spaces(col+3, line-4, 2)
		spaces(col+3, line-3, 2)
		spaces(col+1, line-2, 6)
		spaces(col+3, line-1, 2)
		spaces(col+3, line,   2)
		spaces(col+1, line+1, 3)
	end ,
	['g'] = function (col,line)
		spaces(col+3, line-4, 4)
		spaces(col+2, line-3, 2)
		spaces(col+6, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+7, line-2, 2)
		spaces(col+2, line-1, 7)
		spaces(col+7, line,   2)
		spaces(col+2, line+1, 6)
	end ,
	['h'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 6)
		spaces(col+1, line-2, 2)
		spaces(col+6, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+6, line-1, 2)
		spaces(col+1, line,   2)
		spaces(col+6, line,   2)
	end ,
	['i'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+1, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+1, line,   2)
	end ,
	['j'] = function (col,line)
		spaces(col+3, line-5, 2)
		spaces(col+3, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+3, line-1, 2)
		spaces(col+3, line,   2)
		spaces(col+1, line+1, 3)
	end ,
	['k'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+4, line-3, 2)
		spaces(col+1, line-2, 4)
		spaces(col+1, line-1, 2)
		spaces(col+4, line-1, 2)
		spaces(col+1, line,   2)
		spaces(col+5, line,   2)
	end ,
	['l'] = function (col,line)
		spaces(col+1, line-5, 3)
		spaces(col+2, line-4, 2)
		spaces(col+2, line-3, 2)
		spaces(col+2, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+2, line,   2)
	end ,
	['m'] = function (col,line)
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
	end ,
	['n'] = function (col,line)
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
	end ,
	['o'] = function (col,line)
		spaces(col+3, line-4, 4)
		spaces(col+2, line-3, 2)
		spaces(col+6, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+7, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+6, line-1, 2)
		spaces(col+3, line,   4)
	end ,
	['\246'] = function (col,line)
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
	end ,
	['p'] = function (col,line)
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
	end ,
	['q'] = function (col,line)
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
	end ,
	['r'] = function (col,line)
		spaces(col+1, line-4, 1)
		spaces(col+3, line-4, 3)
		spaces(col+1, line-3, 3)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+1, line,   2)
	end ,
	['s'] = function (col,line)
		spaces(col+2, line-4, 5)
		spaces(col+1, line-3, 2)
		spaces(col+2, line-2, 4)
		spaces(col+5, line-1, 2)
		spaces(col+1, line,   5)
	end ,
	['t'] = function (col,line)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 5)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+2, line,   5)
	end ,
	['u'] = function (col,line)
		spaces(col+1, line-4, 2)
		spaces(col+6, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+6, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+6, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+6, line-1, 2)
		spaces(col+2, line,   5)
	end ,
	['\252'] = function (col,line)
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
	end ,
	['v'] = function (col,line)
		spaces(col+1, line-4, 2)
		spaces(col+7, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+7, line-3, 2)
		spaces(col+2, line-2, 2)
		spaces(col+6, line-2, 2)
		spaces(col+3, line-1, 4)
		spaces(col+4, line,   2)
	end ,
	['w'] = function (col,line)
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
	end ,
	['x'] = function (col,line)
		spaces(col+1, line-4, 2)
		spaces(col+6, line-4, 2)
		spaces(col+2, line-3, 2)
		spaces(col+5, line-3, 2)
		spaces(col+3, line-2, 3)
		spaces(col+2, line-1, 2)
		spaces(col+5, line-1, 2)
		spaces(col+1, line,   2)
		spaces(col+6, line,   2)
	end ,
	['y'] = function (col,line)
		spaces(col+1, line-4, 2)
		spaces(col+7, line-4, 2)
		spaces(col+2, line-3, 2)
		spaces(col+6, line-3, 2)
		spaces(col+3, line-2, 4)
		spaces(col+4, line-1, 2)
		spaces(col+4, line,   2)
	end ,
	['z'] = function (col,line)
		spaces(col+1, line-4, 6)
		spaces(col+4, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+1, line,   6)
	end ,
	--------------- punctuation -----------------
	['?'] = function (col,line)
		spaces(col+2, line-5, 6)
		spaces(col+1, line-4, 2)
		spaces(col+7, line-4, 2)
		spaces(col+6, line-3, 2)
		spaces(col+4, line-2, 3)
		spaces(col+4, line,   2)
	end ,
	['!'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+1, line,   2)
	end ,
	[':'] = function (col,line)
		spaces(col+1, line-2, 2)
		spaces(col+1, line,   2)
	end ,
	['.'] = function (col,line)
		spaces(col+1, line,   2)
	end ,
	[';'] = function (col,line)
		spaces(col+2, line-2, 2)
		spaces(col+2, line,   2)
		spaces(col+1, line+1, 2)
	end ,
	[','] = function (col,line)
		spaces(col+2, line,   2)
		spaces(col+1, line+1, 2)
	end ,
	['-'] = function (col,line)
		spaces(col+1, line-2, 5)
	end ,
	['+'] = function (col,line)
		spaces(col+3, line-3, 2)
		spaces(col+1, line-2, 6)
		spaces(col+3, line-1, 2)
	end ,
	-------------------- digits -------------------
	['0'] = function (col,line)
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
	end ,
	['1'] = function (col,line)
		spaces(col+3, line-5, 2)
		spaces(col+1, line-4, 4)
		spaces(col+3, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+3, line-1, 2)
		spaces(col+1, line,   6)
	end ,
	['2'] = function (col,line)
		spaces(col+2, line-5, 5)
		spaces(col+1, line-4, 2)
		spaces(col+6, line-4, 2)
		spaces(col+5, line-3, 2)
		spaces(col+3, line-2, 3)
		spaces(col+2, line-1, 2)
		spaces(col+1, line,   7)
	end ,
	['3'] = function (col,line)
		spaces(col+2, line-5, 5)
		spaces(col+1, line-4, 2)
		spaces(col+6, line-4, 2)
		spaces(col+4, line-3, 3)
		spaces(col+6, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+6, line-1, 2)
		spaces(col+2, line,   5)
	end ,
	['4'] = function (col,line)
		spaces(col+4, line-5, 3)
		spaces(col+3, line-4, 4)
		spaces(col+2, line-3, 2)
		spaces(col+5, line-3, 2)
		spaces(col+5, line-2, 2)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 8)
		spaces(col+5, line,   2)
	end ,
	['5'] = function (col,line)
		spaces(col+1, line-5, 6)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 6)
		spaces(col+6, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+5, line-1, 2)
		spaces(col+2, line,   4)
	end ,
	['6'] = function (col,line)
		spaces(col+2, line-5, 4)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 6)
		spaces(col+1, line-2, 2)
		spaces(col+6, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+5, line-1, 2)
		spaces(col+2, line,   4)
	end ,
	['7'] = function (col,line)
		spaces(col+1, line-5, 6)
		spaces(col+5, line-4, 2)
		spaces(col+4, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+1, line,   2)
	end ,
	['8'] = function (col,line)
		spaces(col+2, line-5, 5)
		spaces(col+1, line-4, 2)
		spaces(col+6, line-4, 2)
		spaces(col+2, line-3, 5)
		spaces(col+1, line-2, 2)
		spaces(col+6, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+6, line-1, 2)
		spaces(col+2, line,   5)
	end ,
	['9'] = function (col,line)
		spaces(col+2, line-5, 5)
		spaces(col+1, line-4, 2)
		spaces(col+6, line-4, 2)
		spaces(col+2, line-3, 6)
		spaces(col+6, line-2, 2)
		spaces(col+5, line-1, 2)
		spaces(col+2, line,   4)
	end ,
	['/'] = function (col,line)
		spaces(col+6, line-5, 2)
		spaces(col+5, line-4, 2)
		spaces(col+4, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+1, line,   2)
	end ,
	['\\'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+2, line-4, 2)
		spaces(col+3, line-3, 2)
		spaces(col+4, line-2, 2)
		spaces(col+5, line-1, 2)
		spaces(col+6, line,   2)
	end ,
	['_'] = function (col,line)
		spaces(col+1, line, 9)
	end ,
	['|'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+1, line,   2)
	end ,
	['>'] = nil ,
	['<'] = nil ,
	['='] = function (col,line)
		spaces(col+1, line-3, 6)
		spaces(col+1, line-1, 6)
	end ,
	[' '] = function (col,line)
	end ,
	['@'] = function (col,line)
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
	end ,
	['%'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+6, line-5, 2)
		spaces(col+5, line-4, 2)
		spaces(col+4, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+2, line-1, 2)
		spaces(col+1, line,   2)
		spaces(col+6, line,   2)
	end ,
	['&'] = function (col,line)
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
	end ,
	['$'] = function (col,line)
		spaces(col+4, line-5, 1) ; spaces(col+6, line-5, 1)
		spaces(col+2, line-4, 8)
		spaces(col+1, line-3, 2)
		spaces(col+4, line-3, 1) ; spaces(col+6, line-3, 1)
		spaces(col+2, line-2, 7)
		spaces(col+8, line-1, 2)
		spaces(col+4, line-1, 1) ; spaces(col+6, line-1, 1)
		spaces(col+1, line,   8)
		spaces(col+4, line+1, 1) ; spaces(col+6, line+1, 1)
	end ,
	------------------brackets -------------------
	['['] = function (col,line)
		spaces(col+1, line-5, 4)
		spaces(col+1, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+1, line,   2)
		spaces(col+1, line+1, 4)
	end ,
	[']'] = function (col,line)
		spaces(col+1, line-5, 4)
		spaces(col+3, line-4, 2)
		spaces(col+3, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+3, line-1, 2)
		spaces(col+3, line,   2)
		spaces(col+1, line+1, 4)
	end ,
	['('] = function (col,line)
		spaces(col+3, line-5, 2)
		spaces(col+2, line-4, 2)
		spaces(col+1, line-3, 2)
		spaces(col+1, line-2, 2)
		spaces(col+1, line-1, 2)
		spaces(col+2, line,   2)
		spaces(col+3, line+1, 2)
	end ,
	[')'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+2, line-4, 2)
		spaces(col+3, line-3, 2)
		spaces(col+3, line-2, 2)
		spaces(col+3, line-1, 2)
		spaces(col+2, line,   2)
		spaces(col+1, line+1, 2)
	end ,
	['{'] = function (col,line)
		spaces(col+3, line-5, 2)
		spaces(col+2, line-4, 2)
		spaces(col+2, line-3, 2)
		spaces(col+1, line-2, 3)
		spaces(col+2, line-1, 2)
		spaces(col+2, line,   2)
		spaces(col+3, line+1, 2)
	end ,
	['}'] = function (col,line)
		spaces(col+1, line-5, 2)
		spaces(col+2, line-4, 2)
		spaces(col+2, line-3, 2)
		spaces(col+2, line-2, 3)
		spaces(col+2, line-1, 2)
		spaces(col+2, line,   2)
		spaces(col+1, line+1, 2)
	end ,
	--------------------misc ----------------------
	['^'] = function (col,line)
		spaces(col+3, line-5, 2)
		spaces(col+2, line-4, 1)
		spaces(col+5, line-4, 1)
		spaces(col+1, line-3, 1)
		spaces(col+6, line-3, 1)
	end ,
	['#'] = function (col,line)
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
	end ,
	['*'] = function (col,line)
		spaces(col+2, line-3, 1)
		spaces(col+4, line-3, 1)
		spaces(col+1, line-2, 1)
		spaces(col+3, line-2, 1)
		spaces(col+5, line-2, 1)
		spaces(col+2, line-1, 1)
		spaces(col+4, line-1, 1)
	end ,
	['~'] = function (col,line)
		spaces(col+3, line-5, 1)
		spaces(col+1, line-4, 2)
		spaces(col+4, line-4, 1)
		spaces(col+6, line-4, 2)
		spaces(col+5, line-3, 1)
	end ,
	["'"] = function (col,line)
		spaces(col+1, line-5, 1)
	end ,
	['"'] = function (col,line)
		spaces(col+1, line-5, 1)
		spaces(col+3, line-5, 1)
	end ,
	['\t'] = function (col,line)
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
	end ,
	['\196'] = nil,  -- char_A_uml,
	['\214'] = nil,  -- char_O_uml,
	['\220'] = nil,  -- char_U_uml,
}
-- local c2func = c2func_7

-------------------- spacing, kerning -----------------
local c2height_4 = {
	[',']=5, [';']=5, ['g']=5, ['j']=5, ['p']=5, ['q']=5, ['y']=5,
	['[']=5, [']']=5, ['(']=5, [')']=5, ['{']=5, ['}']=5, ['#']=5,
}
local c2height_7 = {
	[',']=8, [';']=8, ['f']=8, ['g']=8, ['j']=8, ['p']=8, ['q']=8, ['y']=8,
	['[']=8, [']']=8, ['(']=8, [')']=8, ['{']=8, ['}']=8, ['#']=8,
}
-- for better kerning in show(), see also function is_good_fit(a,b) ...
local convex_right_7 = {
	['b']=true, ['o']=true, ['p']=true, ['-']=true, ['+']=true, ['^']=true,
	['6']=true,
}
local concave_left_7 = {
	['I']=true, ['J']=true, ['L']=true, ['T']=true, ['Z']=true,
	['j']=true, ['z']=true, ['.']=true, [',']=true, [')']=true,
	[']']=true, ['}']=true, ['_']=true, ["'"]=true, ['"']=true,
}
local convex_left_7 = {
	['a']=true, ['c']=true, ['d']=true, ['e']=true, ['o']=true,
	['q']=true, ['-']=true, ['+']=true,
}
local concave_right_7 = {
	['C']=true, ['F']=true, ['I']=true, ['T']=true, ['Z']=true,
	['c']=true, ['z']=true, ['.']=true, ['(']=true, ['[']=true,
	['{']=true, ['_']=true, ["'"]=true, ['"']=true,
}

---------------------- 4-line utf8-based font ----------------------
local c2width_4 = {
	['A']=5, ['B']=5,  ['C']=5, ['D']=5, ['E']=5,
	['F']=5, ['G']=5,  ['H']=5, ['I']=4, ['J']=5,
	['K']=6, ['L']=5,  ['M']=6, ['N']=6, ['O']=5,
	['P']=5, ['Q']=6,  ['R']=6, ['S']=5, ['T']=6,
	['U']=5, ['V']=6,  ['W']=6, ['X']=6, ['Y']=6, ['Z']=6,
	['a']=6, ['b']=5,  ['c']=4, ['d']=5, ['e']=5,
	['f']=4, ['g']=5,  ['h']=5, ['i']=2, ['j']=4,
	['k']=5, ['l']=3,  ['m']=6, ['n']=5, ['o']=5,
	['p']=5, ['q']=5,  ['r']=4, ['s']=5, ['t']=4,
	['u']=5, ['v']=6,  ['w']=6, ['x']=6, ['y']=5,
	['z']=5, [' ']=4,  ["'"]=2, ['"']=4,
	['.']=2, [',']=3,  [':']=2, [';']=3, ['-']=4,
	['!']=2, ['?']=6,  ['_']=5,
	['0']=6, ['1']=4,  ['2']=5, ['3']=5, ['4']=5,
	['5']=5, ['6']=5,  ['7']=5, ['8']=5, ['9']=5,
	['+']=4, ['=']=4,  ['>']=4, ['<']=4,
	['/']=6, ['\\']=6, ['$']=6, 
	['|']=2, ['@']=6,  ['#']=5, ['~']=6,
	['%']=6, ['&']=6,  ['*']=6, ['^']=6,
	['(']=4, ['[']=3,  ['{']=4,
	[')']=4, [']']=3,  ['}']=4,
}

local c2func_4 = {
	['A'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..lower)
		moveto(col, line-1) ; TTY:write(both..lower..lower..both)
		moveto(col, line)   ; TTY:write(both..'  '..both)
		TTY:flush()
		return c2width_4['A']
	end ,
	['B'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..upper..upper..lower)
		moveto(col, line-1) ; TTY:write(both..upper..upper..lower)
		moveto(col, line)   ; TTY:write(both..lower..lower..upper)
		TTY:flush()
		return c2width_4['B']
	end ,
	['C'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..upper)
		moveto(col, line-1) ; TTY:write(both)
		moveto(col, line)   ; TTY:write(upper..lower..lower..lower)
		TTY:flush()
		return c2width_4['C']
	end ,
	['D'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..upper..upper..lower)
		moveto(col, line-1) ; TTY:write(both..'  '..both)
		moveto(col, line)   ; TTY:write(both..lower..lower..upper)
		TTY:flush()
		return c2width_4['D']
	end ,
	['E'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..upper..upper..upper)
		moveto(col, line-1) ; TTY:write(both..upper..upper)
		moveto(col, line)   ; TTY:write(both..lower..lower..lower)
		TTY:flush()
		return c2width_4['E']
	end ,
	['F'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..upper..upper..upper)
		moveto(col, line-1) ; TTY:write(both..upper..upper)
		moveto(col, line)   ; TTY:write(both)
		TTY:flush()
		return c2width_4['F']
	end ,
	['G'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..upper)
		moveto(col, line-1) ; TTY:write(both..' '..lower..lower)
		moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['G']
	end ,
	['H'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..'  '..both)
		moveto(col, line-1) ; TTY:write(both..upper..upper..both)
		moveto(col, line)   ; TTY:write(both..'  '..both)
		TTY:flush()
		return c2width_4['H']
	end ,
	['I'] = function (col,line)
		moveto(col, line-2) ; TTY:write(upper..both..upper)
		moveto(col, line-1) ; TTY:write(' '..both)
		moveto(col, line)   ; TTY:write(lower..both..lower)
		TTY:flush()
		return c2width_4['I']
	end ,
	['J'] = function (col,line)
		moveto(col, line-2) ; TTY:write(' '..upper..both..upper)
		moveto(col, line-1) ; TTY:write('  '..both)
		moveto(col, line)   ; TTY:write(lower..lower..upper)
		TTY:flush()
		return c2width_4['J']
	end ,
	['K'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..' '..lower..upper)
		moveto(col, line-1) ; TTY:write(both..upper..lower)
		moveto(col, line)   ; TTY:write(both..'  '..upper..lower)
		TTY:flush()
		return c2width_4['K']
	end ,
	['L'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both)
		moveto(col, line-1) ; TTY:write(both)
		moveto(col, line)   ; TTY:write(both..lower..lower..lower)
		TTY:flush()
		return c2width_4['L']
	end ,
	['M'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..lower..' '..lower..both)
		moveto(col, line-1) ; TTY:write(both..' '..upper..' '..both)
		moveto(col, line)   ; TTY:write(both..'   '..both)
		TTY:flush()
		return c2width_4['M']
	end ,
	['N'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..lower..'  '..both)
		moveto(col, line-1) ; TTY:write(both..' '..upper..lower..both)
		moveto(col, line)   ; TTY:write(both..'   '..both)
		TTY:flush()
		return c2width_4['M']
	end ,
	['O'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..lower)
		moveto(col, line-1) ; TTY:write(both..'  '..both)
		moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['O']
	end ,
	['P'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..upper..upper..lower)
		moveto(col, line-1) ; TTY:write(both..lower..lower..upper)
		moveto(col, line)   ; TTY:write(both)
		TTY:flush()
		return c2width_4['P']
	end ,
	['Q'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..upper..lower)
		moveto(col, line-1) ; TTY:write(both..'  '..lower..both)
		moveto(col, line)   ; TTY:write(upper..lower..both..upper..lower)
		TTY:flush()
		return c2width_4['Q']
	end ,
	['R'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..upper..upper..upper..lower)
		moveto(col, line-1) ; TTY:write(both..upper..both..upper)
		moveto(col, line)   ; TTY:write(both..'  '..upper..both)
		TTY:flush()
		return c2width_4['R']
	end ,
	['S'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..upper)
		moveto(col, line-1) ; TTY:write(' '..upper..upper..lower)
		moveto(col, line)   ; TTY:write(lower..lower..lower..upper)
		TTY:flush()
		return c2width_4['S']
	end ,
	['T'] = function (col,line)
		moveto(col, line-2) ; TTY:write(upper..upper..both..upper..upper)
		moveto(col+2, line-1) ; TTY:write(both)
		moveto(col+2, line)   ; TTY:write(both)
		TTY:flush()
		return c2width_4['T']
	end ,
	['U'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..'  '..both)
		moveto(col, line-1) ; TTY:write(both..'  '..both)
		moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['U']
	end ,
	['V'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..'   '..both)
		moveto(col+1, line-1) ; TTY:write(both..' '..both)
		moveto(col+2, line)   ; TTY:write(both)
		TTY:flush()
		return c2width_4['V']
	end ,
	['W'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..'   '..both)
		moveto(col, line-1) ; TTY:write(both..' '..both..' '..both)
		moveto(col, line)   ; TTY:write(both..lower..upper..lower..both)
		TTY:flush()
		return c2width_4['W']
	end ,
	['X'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..'   '..both)
		moveto(col+1, line-1) ; TTY:write(upper..lower..upper)
		moveto(col, line)   ; TTY:write(lower..upper..' '..upper..lower)
		TTY:flush()
		return c2width_4['X']
	end ,
	['Y'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..'   '..both)
		moveto(col+1, line-1) ; TTY:write(upper..lower..upper)
		moveto(col+2, line)   ; TTY:write(both)
		TTY:flush()
		return c2width_4['Y']
	end ,
	['Z'] = function (col,line)
		moveto(col, line-2) ; TTY:write(upper..upper..upper..both..upper)
		moveto(col+1, line-1) ; TTY:write(lower..upper)
		moveto(col, line)   ; TTY:write(both..lower..lower..lower..lower)
		TTY:flush()
		return c2width_4['Z']
	end ,
	['?'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..upper..lower)
		moveto(col+2, line-1) ; TTY:write(lower..upper)
		moveto(col+2, line)   ; TTY:write(lower)
		TTY:flush()
		return c2width_4['?']
	end ,
	['!'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both)
		moveto(col, line-1) ; TTY:write(both)
		moveto(col, line)   ; TTY:write(lower)
		TTY:flush()
		return c2width_4['!']
	end ,
	['.'] = function (col,line)
		moveto(col, line)   ; TTY:write(lower)
		TTY:flush()
		return c2width_4['.']
	end ,
	[','] = function (col,line)
		moveto(col+1, line)   ; TTY:write(lower)
		moveto(col, line+1) ; TTY:write(upper)
		TTY:flush()
		return c2width_4[',']
	end ,
	[':'] = function (col,line)
		moveto(col, line-1) ; TTY:write(lower)
		moveto(col, line)   ; TTY:write(lower)
		TTY:flush()
		return c2width_4[':']
	end ,
	[';'] = function (col,line)
		moveto(col+1, line-1) ; TTY:write(lower)
		moveto(col+1, line)   ; TTY:write(lower)
		moveto(col, line+1)   ; TTY:write(upper)
		TTY:flush()
		return c2width_4[';']
	end ,
	['0'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..upper..lower)
		moveto(col, line-1) ; TTY:write(both..' '..lower..upper..both)
		moveto(col, line)   ; TTY:write(upper..both..lower..lower..upper)
		TTY:flush()
		return c2width_4['0']
	end ,
	['1'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..both)
		moveto(col+1, line-1) ; TTY:write(both)
		moveto(col, line)   ; TTY:write(lower..both..lower)
		TTY:flush()
		return c2width_4['1']
	end ,
	['2'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..lower)
		moveto(col+2, line-1) ; TTY:write(lower..upper)
		moveto(col, line)   ; TTY:write(lower..both..lower..lower)
		TTY:flush()
		return c2width_4['2']
	end ,
	['3'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..lower)
		moveto(col+2, line-1) ; TTY:write(upper..lower)
		moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['3']
	end ,
	['4'] = function (col,line)
		moveto(col+1, line-2) ; TTY:write(lower..both)
		moveto(col, line-1)   ; TTY:write(both..lower..both..lower)
		moveto(col+2, line)   ; TTY:write(both)
		TTY:flush()
		return c2width_4['4']
	end ,
	['5'] = function (col,line)
		moveto(col, line-2) ; TTY:write(both..upper..upper..upper)
		moveto(col, line-1)   ; TTY:write(upper..upper..upper..lower)
		moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['5']
	end ,
	['6'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper)
		moveto(col, line-1)   ; TTY:write(both..upper..upper..lower)
		moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['6']
	end ,
	['7'] = function (col,line)
		moveto(col, line-2) ; TTY:write(upper..upper..upper..both)
		moveto(col+2, line-1)   ; TTY:write(lower..upper)
		moveto(col+1, line)   ; TTY:write(both)
		TTY:flush()
		return c2width_4['7']
	end ,
	['8'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..lower)
		moveto(col, line-1)   ; TTY:write(lower..upper..upper..lower)
		moveto(col, line)   ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['8']
	end ,
	['9'] = function (col,line)
		moveto(col, line-2) ; TTY:write(lower..upper..upper..lower)
		moveto(col, line-1)   ; TTY:write(upper..lower..lower..both)
		moveto(col+1, line)   ; TTY:write(lower..lower..upper)
		TTY:flush()
		return c2width_4['9']
	end ,
	['+'] = function (col,line)
		moveto(col, line-1)   ; TTY:write(lower..both..lower)
		moveto(col+1, line)   ; TTY:write(upper)
		TTY:flush()
		return c2width_4['+']
	end ,
	['-'] = function (col,line)
		moveto(col, line-1)   ; TTY:write(lower..lower..lower)
		TTY:flush()
		return c2width_4['-']
	end ,
	['='] = function (col,line)
		moveto(col, line-1)   ; TTY:write(upper..upper..upper)
		moveto(col, line)     ; TTY:write(upper..upper..upper)
		TTY:flush()
		return c2width_4['=']
	end ,
	['/'] = function (col,line)
		moveto(col+3, line-2)   ; TTY:write(lower..both)
		moveto(col+1, line-1)   ; TTY:write(lower..both..upper)
		moveto(col,   line)     ; TTY:write(both..upper)
		TTY:flush()
		return c2width_4['/']
	end ,
	['\\'] = function (col,line)
		moveto(col,   line-2)   ; TTY:write(both..lower)
		moveto(col+1, line-1)   ; TTY:write(upper..both..lower)
		moveto(col+3, line)     ; TTY:write(upper..both)
		TTY:flush()
		return c2width_4['\\']
	end ,
	['*'] = function (col,line)
		moveto(col+1, line-2)   ; TTY:write(lower..' '..lower)
		moveto(col, line-1)   ; TTY:write(upper..lower..upper..lower..upper)
		TTY:flush()
		return c2width_4['*']
	end ,
	['$'] = function (col,line)
		moveto(col+1, line-2)   ; TTY:write(lower..both..lower)
		moveto(col,   line-1)   ; TTY:write(upper..lower..both..lower)
		moveto(col,   line)     ; TTY:write(lower..lower..both..lower..upper)
		moveto(col+2, line+1)   ; TTY:write(upper)
		TTY:flush()
		return c2width_4['$']
	end ,
	['#'] = function (col,line)
		moveto(col+1, line-2)   ; TTY:write(both..' '..both)
		moveto(col,   line-1)   ; TTY:write(upper..both..upper..both..upper)
		moveto(col,   line)     ; TTY:write(upper..both..upper..both..upper)
		moveto(col+1, line+1)   ; TTY:write(upper..' '..upper)
		TTY:flush()
		return c2width_4['#']
	end ,
	['_'] = function (col,line)
		moveto(col, line+1)   ; TTY:write(upper..upper..upper..upper)
		TTY:flush()
		return c2width_4['_']
	end ,
	['('] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..upper)
		moveto(col,   line-1)  ; TTY:write(both..both)
		moveto(col,   line)    ; TTY:write(upper..both)
		moveto(col+2, line+1)  ; TTY:write(upper)
		TTY:flush()
		return c2width_4['(']
	end ,
	[')'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(upper..lower)
		moveto(col+1, line-1)  ; TTY:write(both..both)
		moveto(col+1, line)    ; TTY:write(both..upper)
		moveto(col,   line+1)  ; TTY:write(upper)
		TTY:flush()
		return c2width_4[')']
	end ,
	['['] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(both..upper)
		moveto(col,   line-1)  ; TTY:write(both)
		moveto(col,   line)    ; TTY:write(both)
		moveto(col,   line+1)  ; TTY:write(upper..upper)
		TTY:flush()
		return c2width_4['[']
	end ,
	[']'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(upper..both)
		moveto(col+1, line-1)  ; TTY:write(both)
		moveto(col+1, line)    ; TTY:write(both)
		moveto(col,   line+1)  ; TTY:write(upper..upper)
		TTY:flush()
		return c2width_4[']']
	end ,
	['{'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(both..upper)
		moveto(col,   line-1)  ; TTY:write(lower..both)
		moveto(col+1, line)    ; TTY:write(both)
		moveto(col+1, line+1)  ; TTY:write(upper..upper)
		TTY:flush()
		return c2width_4['{']
	end ,
	['}'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(upper..both)
		moveto(col+1, line-1)  ; TTY:write(both..lower)
		moveto(col+1, line)    ; TTY:write(both)
		moveto(col,   line+1)  ; TTY:write(upper..upper)
		TTY:flush()
		return c2width_4['}']
	end ,
	["'"] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(both)
		TTY:flush()
		return c2width_4["'"]
	end ,
	['"'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(both..' '..both)
		TTY:flush()
		return c2width_4['"']
	end ,
	['~'] = function (col,line)
		moveto(col,   line-1)  ; TTY:write(lower..upper..lower..' '..lower)
		moveto(col+3, line)    ; TTY:write(upper)
		TTY:flush()
		return c2width_4['~']
	end ,
	['|'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(both)
		moveto(col,   line-1)  ; TTY:write(both)
		moveto(col,   line)    ; TTY:write(both)
		moveto(col,   line+1)  ; TTY:write(upper)
		TTY:flush()
		return c2width_4['|']
	end ,
	['^'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..upper..lower)
		moveto(col,   line-1)  ; TTY:write(upper..'   '..upper)
		TTY:flush()
		return c2width_4['^']
	end ,
	['>'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower)
		moveto(col+1, line-1)  ; TTY:write(upper..lower)
		moveto(col,   line)   ; TTY:write(lower..upper)
		TTY:flush()
		return c2width_4['>']
	end ,
	['<'] = function (col,line)
		moveto(col+2, line-2)  ; TTY:write(lower)
		moveto(col,   line-1)  ; TTY:write(lower..upper)
		moveto(col+1, line)    ; TTY:write(upper..lower)
		TTY:flush()
		return c2width_4['<']
	end ,
	['@'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..upper..upper..upper..lower)
		moveto(col,   line-1)  ; TTY:write(both..' '..both..lower..upper)
		moveto(col,   line)    ; TTY:write(upper..lower..lower..lower)
		TTY:flush()
		return c2width_4['@']
	end ,
	['%'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(upper..'  '..both)
		moveto(col+1, line-1)  ; TTY:write(lower..both..upper)
		moveto(col,   line)    ; TTY:write(both..'  '..lower)
		TTY:flush()
		return c2width_4['%']
	end ,
	['&'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..upper..lower)
		moveto(col,   line-1)  ; TTY:write(lower..upper..upper..lower)
		moveto(col,   line)    ; TTY:write(upper..lower..upper..upper..lower)
		TTY:flush()
		return c2width_4['&']
	end ,
	['a'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower..' '..lower)
		moveto(col,   line-1)  ; TTY:write(both..'  '..upper..both)
		moveto(col,   line)    ; TTY:write(upper..lower..lower..upper..both)
		TTY:flush()
		return c2width_4['a']
	end ,
	['b'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(both..lower..lower)
		moveto(col,   line-1)  ; TTY:write(both..' '..upper..both)
		moveto(col,   line)    ; TTY:write(both..lower..both..upper)
		TTY:flush()
		return c2width_4['b']
	end ,
	['c'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower)
		moveto(col,   line-1)  ; TTY:write(both)
		moveto(col,   line)    ; TTY:write(upper..lower..lower)
		TTY:flush()
		return c2width_4['c']
	end ,
	['d'] = function (col,line)
		moveto(col+3, line-2)  ; TTY:write(both)
		moveto(col,   line-1)  ; TTY:write(lower..upper..upper..both)
		moveto(col,   line)    ; TTY:write(upper..lower..lower..both)
		TTY:flush()
		return c2width_4['d']
	end ,
	['e'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower)
		moveto(col,   line-1)  ; TTY:write(both..lower..lower..both)
		moveto(col,   line)    ; TTY:write(upper..lower..lower)
		TTY:flush()
		return c2width_4['e']
	end ,
	['f'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..upper)
		moveto(col,   line-1)  ; TTY:write(lower..both..lower)
		moveto(col+1, line)    ; TTY:write(both)
		moveto(col,   line+1)  ; TTY:write(upper)
		TTY:flush()
		return c2width_4['f']
	end ,
	['g'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower..lower)
		moveto(col,   line-1)  ; TTY:write(both..'  '..both)
		moveto(col+1, line)    ; TTY:write(upper..upper..both)
		moveto(col,   line+1)  ; TTY:write(upper..upper..upper)
		TTY:flush()
		return c2width_4['g']
	end ,
	['h'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(both)
		moveto(col,   line-1)  ; TTY:write(both..upper..upper..lower)
		moveto(col,   line)    ; TTY:write(both..'  '..both)
		TTY:flush()
		return c2width_4['h']
	end ,
	['i'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(upper)
		moveto(col,   line-1)  ; TTY:write(both)
		moveto(col,   line)    ; TTY:write(both)
		TTY:flush()
		return c2width_4['i']
	end ,
	['j'] = function (col,line)
		moveto(col+2, line-2)  ; TTY:write(upper)
		moveto(col+2, line-1)  ; TTY:write(both)
		moveto(col+2, line)    ; TTY:write(both)
		moveto(col,   line+1)  ; TTY:write(upper..upper)
		TTY:flush()
		return c2width_4['j']
	end ,
	['k'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(both)
		moveto(col,   line-1)  ; TTY:write(both..lower..upper)
		moveto(col,   line)    ; TTY:write(both..' '..upper..lower)
		TTY:flush()
		return c2width_4['k']
	end ,
	['l'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(upper..both)
		moveto(col+1, line-1)  ; TTY:write(both)
		moveto(col+1, line)    ; TTY:write(both)
		TTY:flush()
		return c2width_4['l']
	end ,
	['m'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower..lower)
		moveto(col,   line-1)  ; TTY:write(both..' '..both..' '..both)
		moveto(col,   line)    ; TTY:write(both..'   '..both)
		TTY:flush()
		return c2width_4['m']
	end ,
	['n'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..lower..lower)
		moveto(col,   line-1)  ; TTY:write(both..'  '..both)
		moveto(col,   line)    ; TTY:write(both..'  '..both)
		TTY:flush()
		return c2width_4['n']
	end ,
	['o'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower)
		moveto(col,   line-1)  ; TTY:write(both..'  '..both)
		moveto(col,   line)    ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['o']
	end ,
	['p'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..lower..lower)
		moveto(col,   line-1)  ; TTY:write(both..'  '..both)
		moveto(col,   line)    ; TTY:write(both..upper..upper)
		moveto(col,   line+1)  ; TTY:write(upper)
		TTY:flush()
		return c2width_4['p']
	end ,
	['q'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower..lower)
		moveto(col,   line-1)  ; TTY:write(both..'  '..both)
		moveto(col+1, line)    ; TTY:write(upper..upper..both)
		moveto(col+3, line+1)  ; TTY:write(upper)
		TTY:flush()
		return c2width_4['q']
	end ,
	['r'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower)
		moveto(col,   line-1)  ; TTY:write(both)
		moveto(col,   line)    ; TTY:write(both)
		TTY:flush()
		return c2width_4['r']
	end ,
	['s'] = function (col,line)
		moveto(col+1, line-2)  ; TTY:write(lower..lower..lower)
		moveto(col,   line-1)  ; TTY:write(upper..lower..lower)
		moveto(col,   line)    ; TTY:write(lower..lower..lower..upper)
		TTY:flush()
		return c2width_4['s']
	end ,
	['t'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower)
		moveto(col,   line-1)  ; TTY:write(both..upper)
		moveto(col,   line)    ; TTY:write(upper..lower..lower)
		TTY:flush()
		return c2width_4['t']
	end ,
	['u'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..'  '..lower)
		moveto(col,   line-1)  ; TTY:write(both..'  '..both)
		moveto(col,   line)    ; TTY:write(upper..lower..lower..upper)
		TTY:flush()
		return c2width_4['u']
	end ,
	['v'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..'   '..lower)
		moveto(col,   line-1)  ; TTY:write(upper..lower..' '..lower..upper)
		moveto(col+1, line)    ; TTY:write(upper..lower..upper)
		TTY:flush()
		return c2width_4['v']
	end ,
	[' '] = function (col,line)
		return c2width_4[' ']
	end ,
	['w'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..' '..lower..' '..lower)
		moveto(col,   line-1)  ; TTY:write(both..' '..both..' '..both)
		moveto(col,   line)    ; TTY:write(upper..lower..upper..lower..upper)
		TTY:flush()
		return c2width_4['w']
	end ,
	['x'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..'   '..lower)
		moveto(col+1, line-1)  ; TTY:write(upper..lower..upper)
		moveto(col,   line)    ; TTY:write(lower..upper..' '..upper..lower)
		TTY:flush()
		return c2width_4['x']
	end ,
	['y'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..'  '..lower)
		moveto(col,   line-1)  ; TTY:write(upper..lower..lower..both)
		moveto(col+3, line)    ; TTY:write(both)
		moveto(col,   line+1)  ; TTY:write(upper..upper..upper)
		TTY:flush()
		return c2width_4['y']
	end ,
	['z'] = function (col,line)
		moveto(col,   line-2)  ; TTY:write(lower..lower..lower..lower)
		moveto(col+2, line-1)  ; TTY:write(lower..upper)
		moveto(col,   line)    ; TTY:write(lower..both..lower..lower)
		TTY:flush()
		return c2width_4['z']
	end ,


['\t']=utfchar_test,
['\196']=utfchar_A_uml,
	['\214']=utfchar_O_uml, ['\220']=utfchar_U_uml, ['\228']=utfchar_a_uml,
	['\246']=utfchar_o_uml, ['\252']=utfchar_u_uml,
}

-- for better kerning in show(), see also function is_good_fit(a,b) ...
local convex_right_4 = {
	['p']=true, ['-']=true, ['+']=true, ['^']=true,
}
local concave_left_4 = {
	['I']=true, ['J']=true, ['L']=true, ['T']=true, ['Z']=true,
	['j']=true, ['l']=true, ['z']=true, ['.']=true, [',']=true, [')']=true,
	[']']=true, ['}']=true, ['_']=true, ["'"]=true, ['"']=true,
}
local convex_left_4 = {
	['q']=true, ['-']=true, ['+']=true,
}
local concave_right_4 = {
	['C']=true, ['F']=true, ['I']=true, ['T']=true, ['Z']=true,
	['c']=true, ['z']=true, ['.']=true, ['(']=true, ['[']=true,
	['{']=true, ['_']=true, ["'"]=true, ['"']=true,
}

------------------------------------------------------------

local function show_1 (col,line, str, colour)
	col = round(col) ; line = round(line)
	fg_color(colour)
	moveto(col, line)   ; TTY:write(str)
	TTY:write(sgr0)
	TTY:flush()
	return string.len(str), 1
end

local function show_2 (col,line, str, colour)
	col = math.floor(col / 2) ; line = round(line)
	fg_color(colour)
	moveto(col, line)   ; TTY:write('\x1B#3'..str)
	moveto(col, line+1) ; TTY:write('\x1B#4'..str)
	TTY:write(sgr0)
	TTY:flush()
	return 2*string.len(str), 2
end

local function show_4 (col,line, str, colour)
	col = round(col) ; line = round(line) + 3   -- 0.5 
	str = utf2iso(str) -- the string has to be either iso OR utf, not a mix !
	-- str = string.gsub(str, '\194', '')
	-- str = string.gsub(str, '\195(.)', '') -- see p.210, add 128 to byte(.)
	local width = 0
	local height = 4
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
		local func = c2func_4[c]
		if not func then return 0,0 end
		fg_color(colour)
		charwidth = func(col,line) or 0
		width = width + charwidth
		col = col + charwidth
		if c2height_4[c] then height = c2height_4[c] end
		previous_c = c
	end
	TTY:write(sgr0)
	TTY:flush()
	return width, height
end

local function show_7 (col,line, str, colour)
	col = round(col) ; line = round(line) + 6   -- 0.5 
	str = utf2iso(str) -- the string has to be either iso OR utf, not a mix !
	local width = 0
	local height = 7
	local previous_c = nil
	TTY:write(rev)
	for i = 1, str:len() do
		local c = string.sub(str,i,i)
		if previous_c then  -- kerning
			if  (concave_right[previous_c] and convex_left[c])
			  or (convex_right[previous_c] and concave_left[c])
			  or is_good_fit(previous_c, c)  then
				col = col - 1
			end
		end
		local func = c2func_7[c]
		if not func then return 0,0 end
		fg_color(colour)
		func(col,line)
		local charwidth = c2width_7[c] or 0
		width = width + charwidth
		col = col + charwidth
		if c2height_7[c] then height = c2height_7[c] end
		previous_c = c
	end
	TTY:write(sgr0)
	TTY:flush()
	return width, height
end

------------------------------ public ------------------------------

M.fg_color = fg_color
M.bg_color = bg_color

function M.stringwidth (str)
	if fontsize == 1 then return string.len(str), 1 end
	if fontsize == 2 then return 2*string.len(str), 2 end
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
		if c2height[c] then height = c2height[c] end
		previous_c = c
	end
	if fontsize == 4 then return width, 4 else return width, height end
end

function M.centreshow(y, str, colour)
	local w,h = M.stringwidth(str)
	cols  = TI.get('cols')  -- update cols
	local dx = round( (cols-w) / 2 )
	M.show(dx, y, str, colour)
	return dx+w, h
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
	for i = 0, height-1 do spaces(col, line+i, width) end   -- 0.5
	TTY:write(sgr0)
	TTY:flush()
	return true
end

function M.setfontsize (nlines)
	if nlines == 1 then
		M.show  = show_1
		fontsize = 1
	elseif nlines == 2 then
		M.show  = show_2
		fontsize = 2
	elseif nlines == 4 then
		c2width  = c2width_4
		c2height = c2height_4
		c2func   = c2func_4
		convex_right  = convex_right_4
		concave_left  = concave_left_4
		convex_left   = convex_left_4
		concave_right = concave_right_4
		M.show  = show_4
		fontsize = 4
	elseif nlines == 7 then
		c2width  = c2width_7
		c2height = c2height_7
		c2func   = c2func_7
		convex_right  = convex_right_7
		concave_left  = concave_left_7
		convex_left   = convex_left_7
		concave_right = concave_right_7
		M.show  = show_7
		fontsize = 7
	else
		warn('fontsize must be either 7 or 4, not', nlines)
	end
end
M.setfontsize (4)  -- the default

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
function M.bold ()
	TTY:write(TI.get('bold'))
	TTY:flush()
end
function M.sgr0 ()
	TTY:write(sgr0)
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

TTY:write(TI.get('sc'))   -- save current cursor position
TTY:write(TI.get('rc'))   -- restore cursor position to the saved
TTY:write(TI.tput(TI.get('csr '), 10,TI.lines-1)) -- change scrolling-region

note:
  echo -n 'https://pjb.com.au' | qrencode -m 1 -t UTF8 -o /tmp/t.txt
shows that UTF8 can give me the half-height characters !
  print('\xe2\x96\x88\x20\xe2\x96\x84\xe2\x96\x80')
prints black, white, lower-half black, upper-half black

Detecting whether the background is light or dark:
1) clear
2) scrot -u /tmp/tmpfile.$$.png
3) https://www.imagemagick.org/discourse-server/viewtopic.php?t=11304

If you are using IM 6.4.0-11 or later:
  convert <image> -colorspace Gray -format "%[fx:quantumrange*image.mean]" info:

If you are using IM 6.3.9-1 or later
  convert <image> -colorspace Gray -format "%[mean]" info:

Or if prior to that:
  data=`convert <image> -colorspace gray -verbose info:`
mean=`echo "$data" | sed -n '/^.*[Mm]ean:.*[(]\([0-9.]*\).*$/{ s//\1/; p; q; }'`
convert xc: -format "%[fx:quantumrange*$mean]" info:

All values will be returned in the range of 0 to quantumrange
(Q8=255, Q16=65535)

Alternately, if you want your mean value to be returned in the range of 0-1
then use:
  convert <image> -colorspace Gray -format "%[fx:image.mean]" info:
or
  mean=`convert <image> -colorspace Gray -format "%[mean]" info:`
  convert xc: -format "%[fx:$mean/quantumrange]" info:
or
  data=`convert <image> -colorspace gray -verbose info:`
  echo "$data" | sed -n '/^.*[Mm]ean:.*[(]\([0-9.]*\).*$/{ s//\1/; p; q; }'

Conclusion:
  convert /tmp/t.png -colorspace Gray -format "%[mean]" info:
and divide by 65535 !!  and it works :-)
BUT BETTER because it's already 0 .. 1.0
  convert /tmp/t.png -colorspace Gray -format "%[fx:image.mean]" info:

OR:
  pstree -p | grep $PPID
then look for the "xterm(3491)" string, then
  ps -f -q 3491
and hope it contains -fg and -bg; if so, look up the colours in
  /usr/share/X11/rgb.txt and /usr/X11R6/lib/X11/rgb.txt
and see which is darker.  Unfortunately, if there is
no explicit -fg and -bg, then finding the defaults gets ugly :-(

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

