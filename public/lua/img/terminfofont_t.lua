#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2019, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
TIF = require 'terminfofont'
TIF.civis()
TIF.setfontsize(4)
TIF.clear()
x=0 ; y = 4
x = x + TIF.show(8, y, 'font size 4 :', 'cyan')
x=0 ; y = y+5
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
x = x + TIF.show(x, y, 'y', 'blue')
x = x + TIF.show(x, y, 'z', 'violet')
x=0 ; y = y + 4
x = x + TIF.show(x+2, y, '(o)[-]{+}co', 'orange')
x=0 ; y = y + 7
TIF.setfontsize(7)
  x = x + TIF.show(x, y, 'fontsize 7', 'cyan')


TIF.fg_color('black') ;
-- TIF.bg_color('white')
TIF.cnorm() ; TIF.moveto(0, TIF.lines)

os.exit()

