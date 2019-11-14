#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2019, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '3nov2019'
local Synopsis = [[
  lua test_vfonts.lua
  https://pjb.com.au/comp/lua/terminfofont.html
]]
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
local TIF = require 'terminfofont'
os.execute('clear')
local line = 6
local dx, dy
TIF.civis()

TIF.rectfill(10,21, 40,15, 'black')

dx,dy = TIF.show(1, line, 'ABCDEFG', 6)
line = line + dy
dx,dy = TIF.show(1, line, 'HIJKLMN', 1)
line = line + dy
dx,dy = TIF.show(1, line, '"OPQRST"',  2)
line = line + dy
dx,dy = TIF.show(1, line, 'UVWXYZ', 3)
line = line + dy
dx,dy = TIF.show(1, line, '?!:.;,-0123', 4)
line = line + dy
dx,dy = TIF.show(1,line, '456789+$',  5)
--[[

-- TIF.moveto(0, TIF.lines-1) ; os.exit()
tmp = io.stdin:read('l')
os.execute('clear')
line = 6
dx,dy = TIF.show(1, line, '/\\_|=@%&', 6)
line = line + dy
dx,dy = TIF.show(1, line, 'abcdefghi',  5)
line = line + dy-1
dx,dy = TIF.show(1, line, 'jklmnopqr',  4)
line = line + dy
dx,dy = TIF.show(1, line, "'stuvwxyz'",   3)
line = line + dy -1
dx,dy = TIF.show(1, line, 'pjb.com.au', 2)
line = line + dy
dx,dy = TIF.show(0, line, '[x][o]()^{}', 'blue')
]]

tmp = io.stdin:read('l')
os.execute('clear')
line = 6
dx,dy = TIF.show(1, line, '#*\'~"', 6)
line = line + dy
dx,dy = TIF.show(3, line, 'iso:\228\246\252', 0)
line = line + dy
dx,dy = TIF.show(1, line, 'utf:äöü', 1)
line = line + dy
dx,dy = TIF.show(1, line, 'Lärm', 2)
line = line + dy
dx,dy = TIF.show(1, line, 'Gör Züge', 3)

tmp = io.stdin:read('l')
os.execute('clear')
-- Weimarer Republic
TIF.rectfill(0,TIF.lines-1, TIF.cols, TIF.lines, 'black')
TIF.rectfill(0,TIF.lines-1, TIF.cols, TIF.lines*0.66667, 'red')
TIF.rectfill(0,TIF.lines-1, TIF.cols, TIF.lines*0.33333, 'yellow')
-- could also do Eire, France, Switzerland, Belgium, Netherland, Russia,
-- Finland, Crimea, Catalunia, Turingia etc etc
-- many others. See   https://en.wikipedia.org/wiki/Flags_of_Europe
-- note the many flags of the European Coal and Steel Community :-(

tmp = io.stdin:read('l')
os.execute('clear')
TIF.civis()
x=0 ; y = 4
x = x + TIF.utf8char_A(x, y, 'red')
x = x + TIF.utf8char_B(x, y, 'blue')
x = x + TIF.utf8char_C(x, y, 'green')
x = x + TIF.utf8char_D(x, y, 'violet')
x = x + TIF.utf8char_E(x, y, 'red')
x = x + TIF.utf8char_F(x, y, 'blue')
x = x + TIF.utf8char_G(x, y, 'green')
x = x + TIF.utf8char_H(x, y, 'violet')
x = x + TIF.utf8char_I(x, y, 'red')
x = x + TIF.utf8char_J(x, y, 'blue')
x = x + TIF.utf8char_K(x, y, 'green')
x = x + TIF.utf8char_L(x, y, 'violet')
x = x + TIF.utf8char_M(x, y, 'red')
x = x + TIF.utf8char_N(x, y, 'green')
x = x + TIF.utf8char_O(x, y, 'blue')
x=0 ; y = y + 4
x = x + TIF.utf8char_P(x, y, 'violet')
x = x + TIF.utf8char_Q(x, y, 'red')
x = x + TIF.utf8char_R(x, y, 'blue')
x = x + TIF.utf8char_dot(x, y, 'black')
x = x + TIF.utf8char_S(x, y, 'green')
x = x + TIF.utf8char_T(x, y, 'violet')
x = x + TIF.utf8char_U(x, y, 'red')
x = x + TIF.utf8char_V(x, y, 'green')
x = x + TIF.utf8char_W(x, y, 'blue')
x = x + TIF.utf8char_comma(x, y, 'black')
x = x + TIF.utf8char_X(x, y, 'green')
x = x + TIF.utf8char_Y(x, y, 'violet')
x = x + TIF.utf8char_Z(x, y, 'red')
x = x + TIF.utf8char_question(x, y, 'green')
x = x + TIF.utf8char_exclamation(x, y, 'blue')
x=0 ; y = y + 4
x = x + TIF.utf8char_X(x, y, 'green')
x = x + TIF.utf8char_colon(x, y, 'blue')
x = x + TIF.utf8char_Z(x, y, 'black')
x = x + TIF.utf8char_semicolon(x, y, 'red')
x = x + TIF.utf8char_W(x, y, 'black')



tmp = io.stdin:read('l')
TIF.cnorm() ; TIF.moveto(0, TIF.lines)

os.exit()

