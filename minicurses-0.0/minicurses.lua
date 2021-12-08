---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2021, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local MM = require 'minicurses'
-- MM.foo()

local M = {} -- public interface
M.Version = '0.4'
M.VersionDate = '09dec2021'

-- midiedit uses:      initscr cbreak noecho nonl clear endwin refresh getch
--                     attrset clrtoeol move addstr echo getnstr clrtobot
-- midifade also uses: keypad
--    attrset (NCURSES_ATTR_T); where NCURSES_ATTR_T is an int
--    getnstr (char *, int);

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

----------------- from Lua Programming Gems p. 331 ----------------
local require, table = require, table -- save the used globals
local aux, prv = {}, {} -- auxiliary & private C function tables
local initialise = require 'C-minicurses'
initialise(aux, prv, M) -- initialise the C lib with aux,prv & module tables

------------------------------ public ------------------------------

function M.addstr(str)
	prv.addstr(tostring(str))
end

function M.attrset(attr)
	prv.attrset(tonumber(attr))
end

function M.getch()
	return string.char(prv.getch())
end

function M.getnstr(len)
	return prv.getnstr(len)
end

function M.keypad(bool)
	prv.keypad(bool)
end

function M.move(row, col)
	prv.move(tonumber(row), tonumber(col))
end

function M.mvaddstr(row, col, str)
	prv.mvaddstr(tonumber(row), tonumber(col), tostring(str))
end

function M.cbreak()   prv.cbreak()   end
function M.clear()    prv.clear()    end
function M.clrtobot() prv.clrtobot() end
function M.clrtoeol() prv.clrtoeol() end
function M.echo()     prv.echo()     end
function M.endwin()   prv.endwin()   end
function M.initscr()  prv.initscr()  end
function M.noecho()   prv.noecho()   end
function M.nonl()     prv.nonl()     end
function M.refresh()  prv.refresh()  end

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

