---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2021, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
--   C = require 'minicurses'
--   C.foo()

local M = {} -- public interface
M.Version = '0.4'
M.VersionDate = '09dec2021'

-- midiedit uses:      initscr cbreak noecho nonl clear endwin refresh getch
--                     attrset clrtoeol move addstr echo getnstr clrtobot
-- midifade also uses: keypad
--    attrset (NCURSES_ATTR_T); where NCURSES_ATTR_T is an int
--    getnstr (char *, int);

-- to do: getkey (+ LEFT RIGHT UP DOWN PAGEUP PAGEDOWN HOME END)
-- therefore: echo() and noecho() must remember the state
-- !? delch() deleteln() insch(c) insertln() insstr(s) scrl(n) setscrreg(t,b)

-- man 3 border
-- The  border, wborder and box routines draw a box around the edges
-- **of a window.**
-- If any of the arguments are zero, then the corresponding
--   default values (defined in curses.h) are used instead:
-- ACS_VLINE ACS_HLINE ACS_ULCORNER ACS_URCORNER ACS_LLCORNER ACS_LRCORNER.
-- SEEMS int hline(chtype ch, int n); and int vline(chtype ch, int n);
-- might be worth a try, but 
-- https://stackoverflow.com/questions/34538814/print-unicode-characters-in-c-using-ncurses
-- ncurses defines the values ACS_HLINE, ACS_VLINE, ACS_ULCORNER,
-- ACS_URCORNER, ACS_LLCORNER and ACS_LRCORNER. You can use those constants
-- in addch and friends, which should result in your seeing the expected
-- box characters. (There's lots more ACS characters; you'll find a complete
-- list in man addch.)
-- ncurses needs to know what it is drawing because it needs to know exactly
-- where the cursor is all the time. Outputting console control sequences is
-- not a good idea; if ncurses knows how to handle the sequence, it has its
-- own abstraction for the feature and you should use that abstraction. The
-- ACS ("alternate character set") defines are one of those abstractions.

------------------------------ private ------------------------------
function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end
function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end

local isecho = false  -- is this the default set by initscr ?

----------------- from Lua Programming Gems p. 331 ----------------
local require, table = require, table -- save the used globals
local aux, prv = {}, {} -- auxiliary & private C function tables
local initialise = require 'C-minicurses'
initialise(aux, prv, M) -- initialise the C lib with aux,prv & module tables

------------------------------ public ------------------------------

function M.mvaddstr(row, col, str)
	prv.mvaddstr(tonumber(row), tonumber(col), tostring(str))
end

function M.mvgetnstr(row, col, len)    -- 0.4
	prv.move(tonumber(row), tonumber(col))
	return prv.getnstr(len)
end

function M.addstr(str)    prv.addstr(tostring(str))   end
function M.attrset(attr)  prv.attrset(tonumber(attr)) end
function M.cbreak()       prv.cbreak()   end
function M.clear()        prv.clear()    end
function M.clrtobot()     prv.clrtobot() end
function M.clrtoeol()     prv.clrtoeol() end
function M.echo()         prv.echo() ; isecho = true  end
function M.endwin()       prv.endwin()   end
function M.hline(n)       prv.hline(tonumber(n))      end
function M.initscr()
	M.LINES, M.COLS = prv.initscr()
	return M.LINES, M.COLS
end
function M.getch()        return string.char(prv.getch()) end
--	local c = prv.getch() ; io.stderr:write('c = '..tostring(c)..'\n')
--	return string.char(c)
--	end
function M.getnstr(len)   return prv.getnstr(len)       end
-- function M.keypad(bool)   prv.keypad(bool)              end --
function M.move(row, col) prv.move(tonumber(row), tonumber(col)) end
function M.noecho()       prv.noecho() ; isecho = false end
function M.nonl()         prv.nonl()     end
function M.refresh()      prv.refresh()  end
function M.vline(n)       prv.vline(tonumber(n))      end

function M.getkey()
	local c1 = M.getch()
	if c1 ~= '\27' then return c1 end
	local key = ''
	local wasecho = isecho
	if isecho then M.noecho() end
	local c2 = M.getch()
	-- should do a timeout to allow the ESC key ? or just use getch() ?
	if c2 == '[' then
		local c3 = M.getch()
		if     c3 == 'A' then key = 'UP'
		elseif c3 == 'B' then key = 'DOWN'
		elseif c3 == 'C' then key = 'RIGHT'
		elseif c3 == 'D' then key = 'LEFT'
		elseif c3 == 'F' then key = 'END'
		elseif c3 == 'H' then key = 'HOME'
		elseif c3 == '5' and M.getch() == '~' then key = 'PAGEUP'
	    elseif c3 == '6' and M.getch() == '~' then key = 'PAGEDOWN'
    	else
			if wasecho then M.echo() end
			key = M.getch() -- reject unrecognised key, return next char
			return key
		end
		if wasecho then M.echo() end
		return key
	else
		if wasecho then M.echo() end
		return c2
    end
end

function M.mvbox(y1, x1, y2, x2)
	local toprow, lftcol, botrow, rgtcol
    if     x1 < x2 then lftcol = x1 ; rgtcol = x2
    elseif x1 > x2 then lftcol = x2 ; rgtcol = x1
    else return
    end
    if     y1 < y2 then toprow = y1 ; botrow = y2
    elseif y1 > y2 then toprow = y2 ; botrow = y1
    else return
    end
	prv.mvbox(toprow, lftcol, botrow, rgtcol)
end

return M

--[=[

=pod

=head1 NAME

minicurses.lua - does whatever

=head1 SYNOPSIS

 local MC = require 'minicurses'
 MC.initscr()
  -- automatically calls cbreak(); noecho();
  -- and intrflush(stdscr, FALSE); keypad(stdscr, TRUE);
 MC.mvaddstr(0, 10, 'All those moments will be lost in time,')
 MC.mvaddstr(1, 11, 'like tears in the rain.')  
 MC.endwin()

=head1 DESCRIPTION

This module does whatever

=head1 FUNCTIONS

=over 3

=item I<initscr()>

This calls the C<ncurses> function C<initscr();>

It does not return any WINDOW as a userdata, it only provides C<stdsrc>
which it keeps to itself to avoid Lua's C<userdata> security problem.

=item I<endwin()>

This calls C<endwin();>

=back

=head1 DOWNLOAD

This module is available at
https://pjb.com.au/comp/lua/mymodule.html

=head1 AUTHOR

Peter J Billam, https://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 https://pjb.com.au/


=cut

]=]

