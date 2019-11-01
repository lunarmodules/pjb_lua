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


-- these are classic 5x7 constant-width
-- but I should also do variable-width,
-- constant-smooth, variable-smooth,
-- constant-thin, variable-thin

local function char_A (col,line, is_thin)
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('      ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
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
local function char_B (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('        ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('        ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_C (col,line, is_thin)
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('        ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_D (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('        ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_E (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('          ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('        ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('          ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_F (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('          ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('        ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_G (col,line, is_thin)
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+8, line-2) ; TTY:write('    ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_H (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('          ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+10, line)  ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_I (col,line, is_thin)
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('      ')
	go_to(col+6, line-4) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_J (col,line, is_thin)
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('        ')
	go_to(col+8, line-4) ; TTY:write('  ')
	go_to(col+8, line-3) ; TTY:write('  ')
	go_to(col+8, line-2) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_K (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+8, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+6, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('    ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+10, line)  ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_L (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('          ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_M (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('    ')
	go_to(col+8, line-4) ; TTY:write('    ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+10, line)  ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_N (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('    ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+8, line-2) ; TTY:write('    ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+10, line)  ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_O (col,line, is_thin)
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('      ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_P (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('        ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_Q (col,line, is_thin)
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('      ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+8, line-2) ; TTY:write('    ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('    ')
	go_to(col+4, line)   ; TTY:write('    ')
	go_to(col+10,line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_R (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+8, line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('        ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+8, line-1) ; TTY:write('    ')
	go_to(col+2, line)   ; TTY:write('  ')
	go_to(col+10,line)  ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_S (col,line, is_thin)
	TTY:write(rev)
	go_to(col+4, line-5) ; TTY:write('        ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+4, line-3) ; TTY:write('      ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('        ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_T (col,line, is_thin)
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
local function char_U (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+2, line-3) ; TTY:write('  ')
	go_to(col+10,line-3) ; TTY:write('  ')
	go_to(col+2, line-2) ; TTY:write('  ')
	go_to(col+10,line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+4, line)   ; TTY:write('      ')
	TTY:write(sgr0)
	return 13  -- width
end
local function char_V (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+4, line-3) ; TTY:write('  ')
	go_to(col+8, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('  ')
	go_to(col+8, line-2) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+6, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_W (col,line, is_thin)
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
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('    ')
	go_to(col+8, line)   ; TTY:write('    ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_X (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('  ')
	go_to(col+10,line-5) ; TTY:write('  ')
	go_to(col+2, line-4) ; TTY:write('  ')
	go_to(col+10,line-4) ; TTY:write('  ')
	go_to(col+4, line-3) ; TTY:write('  ')
	go_to(col+8, line-3) ; TTY:write('  ')
	go_to(col+6, line-2) ; TTY:write('  ')
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+6, line)   ; TTY:write('  ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_Y (col,line, is_thin)
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
	go_to(col+6, line-1) ; TTY:write('  ')
	go_to(col+10,line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('    ')
	go_to(col+8, line)   ; TTY:write('    ')
	TTY:write(sgr0)
	return 13  -- width
end

local function char_Z (col,line, is_thin)
	TTY:write(rev)
	go_to(col+2, line-5) ; TTY:write('        ')
	go_to(col+8, line-4) ; TTY:write('  ')
	go_to(col+6, line-3) ; TTY:write('  ')
	go_to(col+4, line-2) ; TTY:write('  ')
	go_to(col+2, line-1) ; TTY:write('  ')
	go_to(col+2, line)   ; TTY:write('        ')
	TTY:write(sgr0)
	return 13  -- width
end

local col  = 1
local line = 7
col = col + char_A(col, line)
col = col + char_B(col, line)
col = col + char_C(col, line)
col = col + char_D(col, line)
col = col + char_E(col, line)
col = col + char_F(col, line)
col = 1 ; line = line + 8 ; fg_color('red')
col = col + char_G(col, line)
col = col + char_H(col, line)
col = col + char_I(col, line) - 1
col = col + char_J(col, line)
col = col + char_K(col, line)
col = col + char_L(col, line)
col = 1 ; line = line + 8 ; fg_color('blue')
col = col + char_M(col, line)
col = col + char_N(col, line)
col = col + char_O(col, line)
col = col + char_P(col, line) - 1
col = col + char_Q(col, line)
col = col + char_R(col, line)
col = 1 ; line = line + 8 fg_color('green')
col = col + char_S(col, line)
col = col + char_T(col, line) - 1
col = col + char_U(col, line)
col = col + char_V(col, line)
col = col + char_W(col, line)
col = col + char_X(col, line)
col = 0 ; line = line + 8 fg_color('black')
col = col + char_Y(col, line)
col = col + char_Z(col, line)
go_to(1, cols)
os.exit()

------------------------------ public ------------------------------
function M.foo()
	print(M.VersionDate)
end

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


=cut

]=]

