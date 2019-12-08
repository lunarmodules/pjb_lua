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
local line = 0
local dx, dy
TIF.civis()
TIF.setfontsize(7)

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

tmp = io.stdin:read('l')
os.execute('clear')
line = 0
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

tmp = io.stdin:read('l')
os.execute('clear')
line = 0
dx,dy = TIF.show(1, line, '#*\'~"', 6)
line = line + dy
dx,dy = TIF.show(3, line, 'iso:\228\246\252', 0)
line = line + dy
dx,dy = TIF.show(1, line, 'utf:äöü', 1)
line = line + dy
dx,dy = TIF.show(1, line, 'Lärm ltle', 2)
line = line + dy
dx,dy = TIF.show(1, line, 'Gör Züge', 3)

tmp = io.stdin:read('l')
os.execute('clear')
-- Weimarer Republic
TIF.rectfill(0,0, TIF.cols, TIF.lines, 'black')
TIF.rectfill(0,0, TIF.cols, TIF.lines*0.66667, 'red')
TIF.rectfill(0,0, TIF.cols, TIF.lines*0.33333, 'yellow')
-- could also do Eire, France, Switzerland, Belgium, Netherland, Russia,
-- Finland, Crimea, Catalunia, Turingia etc etc
-- many others. See   https://en.wikipedia.org/wiki/Flags_of_Europe
-- note the many flags of the European Coal and Steel Community :-(

tmp = io.stdin:read('l')
os.execute('clear')
TIF.civis()
-- TIF.rectfill(0,TIF.lines-1, TIF.cols, TIF.lines, 'cyan')
-- TIF.bg_color('cyan')
-- width,height = TIF.stringwidth('Size=4...')
-- dx,dy = TIF.show((TIF.cols-width)/2, 0, 'Size=4...', 'cyan')
TIF.setfontsize(4)
x=0 ; y=0
dx,dy = TIF.show(x, y, 'ABCDEFGHIJKLMNO', 'red')
x=0 ; y = y+dy
x = x + TIF.show(x, y, 'P', 'violet')
x = x + TIF.show(x, y, 'Q', 'red')
x = x + TIF.show(x, y, 'R', 'blue')
x = x + TIF.show(x, y, ':', 'black')
x = x + TIF.show(x, y, 'S', 'green')
x = x + TIF.show(x, y, 'T', 'violet')
x = x + TIF.show(x, y, 'U', 'red')
x = x + TIF.show(x, y, 'V', 'green')
x = x + TIF.show(x, y, 'W', 'blue')
x = x + TIF.show(x, y, ',', 'black')
x = x + TIF.show(x, y, 'X', 'green')
x = x + TIF.show(x, y, 'Y', 'violet')
x = x + TIF.show(x, y, 'Z', 'red')
x = x + TIF.show(x, y, '?', 'green')
x = x + TIF.show(x, y, '!', 'blue')
x=0 ; y = y + 4
x = x + TIF.show(x, y, ':', 'blue')
x = x + TIF.show(x, y, ';', 'red')
x = x + TIF.show(x, y, '0', 'red')
x = x + TIF.show(x, y, '1', 'green')
x = x + TIF.show(x, y, '2', 'blue')
x = x + TIF.show(x, y, '3', 'violet')
x = x + TIF.show(x, y, '4', 'black')
x = x + TIF.show(x, y, '/', 'blue')
x = x + TIF.show(x, y, '\\', 'green')
x = x + TIF.show(x, y, '5', 'red')
x = x + TIF.show(x, y, '+', 'violet')
x = x + TIF.show(x, y, '6', 'green')
x = x + TIF.show(x, y, '7', 'blue')
x = x + TIF.show(x, y, '-', 'red')
x = x + TIF.show(x, y, '8', 'black')
x = x + TIF.show(x, y, '=', 'red')
x = x + TIF.show(x, y, '9', 'green')
x=0 ; y = y + 4
x = x + TIF.show(x, y, '*', 'blue')
x = x + TIF.show(x, y, '$', 'red')
x = x + TIF.show(x, y, '#', 'green')
x = x + TIF.show(x, y, '_', 'blue')
x = x + TIF.show(x, y, '(', 'red')
x = x + TIF.show(x, y, ')', 'green')
x = x + TIF.show(x, y, '[', 'red')
x = x + TIF.show(x, y, '"', 'blue')
x = x + TIF.show(x, y, '|', 'green')
x = x + TIF.show(x, y, '"', 'blue')
x = x + TIF.show(x, y, ']', 'red')
x = x + TIF.show(x, y, '{', 'green')
x = x + TIF.show(x, y, "'", 'blue')
x = x + TIF.show(x, y, '!', 'green')
x = x + TIF.show(x, y, "'", 'blue')
x = x + TIF.show(x, y, '}', 'green')
x = x + TIF.show(x, y, '~', 'blue')
x = x + TIF.show(x, y, '^', 'red')
x = x + TIF.show(x, y, '>', 'green')
x=0 ; y = y + 4
x = x + TIF.show(x, y, '<', 'blue')
x = x + TIF.show(x, y, '@', 'red')
x = x + TIF.show(x, y, '%', 'green')
x = x + TIF.show(x, y, '&', 'blue')
x = x + TIF.show(x, y, 'a', 'red')
x = x + TIF.show(x, y, 'b', 'green')
x = x + TIF.show(x, y, 'c', 'blue')
x = x + TIF.show(x, y, 'd', 'red')
x = x + TIF.show(x, y, 'e', 'green')
x = x + TIF.show(x, y, 'f', 'blue')
x = x + TIF.show(x, y, 'g', 'red')
x = x + TIF.show(x, y, 'h', 'green')
x = x + TIF.show(x, y, 'i', 'blue')
x = x + TIF.show(x, y, 'j', 'red')
x = x + TIF.show(x, y, 'l', 'green')
x = x + TIF.show(x, y, 'k', 'red')
x=0 ; y = y + 4
x = x + TIF.show(x, y, 'm', 'blue')
x = x + TIF.show(x, y, 'n', 'violet')
x = x + TIF.show(x, y, 'o', 'red')
x = x + TIF.show(x, y, 'p', 'green')
x = x + TIF.show(x, y, 'q', 'blue')
x = x + TIF.show(x, y, 'r', 'violet')
x = x + TIF.show(x, y, 's', 'red')
x = x + TIF.show(x, y, 't', 'green')
x = x + TIF.show(x, y, 'u', 'blue')
x = x + TIF.show(x, y, 'v', 'violet')
x = x + TIF.show(x, y, 'w', 'red')
x = x + TIF.show(x, y, 'x', 'green')
x = x + TIF.show(x, y, 'y ', 'blue')
x = x + TIF.show(x, y, 'z', 'violet')
x=0 ; y = y + 4
dx,dy = TIF.show(x+2, y, '(o)[-]{+}(co)kokc', 'blue') ; y = y+dy
-- TIF.setfontsize(2)
-- dx,dy = TIF.show(0,y, 'Back to the vt100 !  ', 'red') ; x = x+dx
-- dx,dy = TIF.show(x,y, string.format('dx = %d  dy = %d', dx,dy), 'black')
TIF.setfontsize(1)
TIF.bold() ; dx,dy = TIF.centreshow(y, 'The Title', 'red')  ; y = y+dy
TIF.setfontsize(2)
TIF.bold() ; dx,dy = TIF.centreshow(y, 'The Title', 'blue') ; y = y+dy
TIF.setfontsize(4)
dx,dy = TIF.centreshow(y, 'The Title', 'violet') ; y = y+dy
TIF.setfontsize(7)
dx,dy = TIF.centreshow(y, 'The Title', 'red') ; y = y+dy

tmp = io.stdin:read('l')
TIF.sgr0() ; TIF.cnorm() ; TIF.moveto(0, TIF.lines-1)

os.exit()

