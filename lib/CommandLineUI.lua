#! /usr/local/bin/lua
--------------------------------------------------------------------------
-- This Lua module is Copyright (c) 2013, Peter J Billam www.pjb.com.au --
--                                                                      --
--     This module is free software; you can redistribute it and/or     --
--             modify it under the same terms as Lua itself.            --
--------------------------------------------------------------------------

local M       = {} -- public interface
M.Version     = '1.78' -- local variables for the common string functions
M.VersionDate = '23may2020'

local P = require 'posix'    -- http://luaposix.github.io/luaposix/docs/
local T = require 'terminfo' -- http://pjb.com.au/comp/lua/terminfo.html
local K = require 'readkey'  -- http://pjb.com.au/comp/lua/readkey.html
local L = require 'readline' -- http://pjb.com.au/comp/lua/readline.html
_G.BITOPS = {}  -- global because load executes in the calling context
local B = {}

local blen  = string.len   -- length in bytes
local find  = string.find
local gsub  = string.gsub
local match = string.match

local version = gsub(_VERSION, "^%D+", "")
if tonumber(version) < 5.3 then  -- 1.74
	B = require 'bit'  -- LuaBitOp http://bitop.luajit.org/api.html
else
	local f = load([[
	_G.BITOPS.bor    = function (a,b) return a|b  end
	_G.BITOPS.band   = function (a,b) return a&b  end
	_G.BITOPS.rshift = function (a,n) return a>>n end
	]])
	f()
	B = _G.BITOPS
end

local G = require 'gdbm'     -- http://pjb.com.au/comp/lua/lgdbm.html
-- require 'DataDumper'

-------------------------- global variables ---------------------

-- my (%irow, %icol, $nrows, $clue_has_been_given, $choice, $ThisCell);
local TTY
local Irow_a       = {}  -- maintained by layout()
local Icol_a       = {}
local Irow; local Icol   -- maintained by puts, up, down, left and right
local Nrows        = 0
local ClueHasBeenGiven = false
local Choice       = ''
local ThisCell     = 1
local List         = {}
local Marked       = {}
local MaxCols      = 80
local MaxRows      = 24
local SizeChanged  = true
local OtherLines   = {}  -- set by choose; only wr_screen uses this
local IsUtf8       = false
local wantarray    = false
math.randomseed(os.time())
local Pager = os.getenv('PAGER')
if not Pager then
	for i,v in ipairs{"/usr/bin/more", "/usr/bin/less"} do
		if P.stat(v) then Pager = f end
	end
end

---------------------------- utilities -----------------------

local function deepcopy(object)  -- http://lua-users.org/wiki/CopyTable
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

local HistFile = '~/.clui_dir/'..string.sub(
  gsub(arg[0], '^.*/', ''), 1, 8)..'_history'
L.set_options{histfile=HistFile}  -- 1.70

local function homedir(user)
	if not user and os.getenv('HOME') then return os.getenv('HOME') end
	if not user then user = P.getpid('euid') end
	return P.getpasswd(user, 'dir') or '/tmp'
end
local HOME = homedir()

local function tilde_expand(filename)
	if match(filename, '^~') then
		local user = match(filename, '^~(%a+)/')
		local home = homedir(user)
		filename = gsub(filename, '^~%a*', home)
	end
	return filename
end

local function split(s, pattern, maxNb) -- http://lua-users.org/wiki/SplitJoin
	if not s or string.len(s)<2 then return {s} end
	if not pattern then return {s} end
	if maxNb and maxNb <2 then return {s} end
	local result = { }
	local theStart = 1
	local theSplitStart,theSplitEnd = find(s,pattern,theStart)
	local nb = 1
	while theSplitStart do
		table.insert( result, string.sub(s,theStart,theSplitStart-1) )
		theStart = theSplitEnd + 1
		theSplitStart,theSplitEnd = find(s,pattern,theStart)
		nb = nb + 1
		if maxNb and nb >= maxNb then break end
	end
	table.insert( result, string.sub(s,theStart,-1) )
	return result
end

local function sleep(t)
	local sec = math.floor(t)
	local ns = (1000000000 * (t-sec))
	P.nanosleep(sec,ns)
end

local function _debug(...)
	local DEBUG = io.open('/tmp/debug', 'a')
	local a = {}
	for k,v in pairs{...} do table.insert(a, tostring(v)) end
	DEBUG:write(table.concat(a),'\n') ; DEBUG:flush()
	DEBUG:close()
end

local function splice(array, offset, length, list)
	-- 1 <= offset <= (#array+1)
	-- returns the spliced array, not the items that got removed
	local result = {}
	if not offset then return result end
	if not length then length = -1 end
	for i = 1,(offset-1) do result[#result+1] = array[i] end
	if type(list) == 'table' then
		for i,v in pairs(list) do result[#result+1] = v end
	else
		result[#result+1] = list
	end
	if length < 0 then
		for i = offset, (#array+1-length) do result[#result+1] = array[i] end
	else
		for i = (offset+length), #array   do result[#result+1] = array[i] end
	end
	return result
end

local function is_textfile (fn)
	local f=io.open(fn,'r')
	if not f then return false end
	local s = f:read(8192)
	f:close()
	local n_ascii = 0
	local n = blen(s)
	for i = 1,n do if string.byte(s,i)<127 then n_ascii = n_ascii+1 end end
	return n_ascii > (0.85*n)
end

local function which(s)
	local f
	for i,d in ipairs(split(os.getenv('PATH'), ':')) do
		f=d..'/'..s; if P.access(f, 'x') then return f end
	end
end

------------------------ vt100 stuff -------------------------

local A_NORMAL    =  0
local A_BOLD      =  1
local A_UNDERLINE =  2
local A_REVERSE   =  4
local KEY_UP     = 0403  -- hmm; these were octal, but in lua are decimal..
local KEY_LEFT   = 0404
local KEY_RIGHT  = 0405
local KEY_DOWN   = 0402
local KEY_ENTER  = "\r"
local KEY_INSERT = 0525
local KEY_DELETE = 0524
local KEY_HOME   = 0523
local KEY_END    = 0522
local KEY_PPAGE  = 0521
local KEY_NPAGE  = 0520
local KEY_BTAB   = 0541
local AbsCursX   = 0
local AbsCursY   = 0
local TopRow     = 0
local CursorRow;
local LastEventWasPress = false;  -- in order to ignore left-over button-ups
--local SpecialKey = {  -- 1.51, used by narrow_the_search to ignore these:
--	[KEY_UP]=true,   [KEY_LEFT]=true,   [KEY_RIGHT]=true, [KEY_DOWN]=true,
--	[KEY_HOME]=true, [KEY_END]=true,    [KEY_PPAGE]=true, [KEY_NPAGE]=true,
--	[KEY_BTAB]=true, [KEY_INSERT]=true, [KEY_DELETE]=true
--}

local TI = {}
TI['clr_eol']      = T.get('clr_eol')      or "\027[K"
TI['clr_eos']      = T.get('clr_eos')      or "\027[J"
TI['cursor_up']    = T.get('cursor_up')    or "\027[A"
TI['cursor_down']  = T.get('cursor_down')  or "\n"
TI['cursor_left']  = T.get('cursor_left')  or "\027[D"
TI['cursor_right'] = T.get('cursor_right') or "\027[C"
TI['clear_screen'] = T.get('clear_screen') or "\027[H\027[J"

local function utf8len(str)
	if not str then return 0 end   -- 1.75  20170525
--[[	  UCS code      :       Bytes    (see man 7 utf8)
	x00000000-0x0000007F 0xxxxxxx
	x00000080-0x000007FF 110xxxxx 10xxxxxx
	x00000800-0x0000FFFF 1110xxxx 10xxxxxx 10xxxxxx
	x00010000-0x001FFFFF 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
	x00200000-0x03FFFFFF 111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
	x04000000-0x7FFFFFFF 1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
--]]
	local length = 0
	local i = 1
	while i <= string.len(str) do
		local c = string.byte(str, i) 
		length = length + 1
		if     B.band(c, 128) == 0   then i = i + 1
		elseif B.band(c, 224) == 192 then i = i + 2
		elseif B.band(c, 240) == 224 then i = i + 3
		elseif B.band(c, 248) == 240 then i = i + 4
		elseif B.band(c, 252) == 248 then i = i + 5
		elseif B.band(c, 254) == 252 then i = i + 6
		else
			i = 1 + 1  -- ill-formed
			io.stderr:write(
			  'utf8len: bad byte '..tostring(i)..' = '..tostring(c)..'\n')
		end
	end
	return length
end

-- length in characters ; this will change this if it's a utf8 locale ...
local clen   = string.len
do
	local lang = os.getenv('LANG')
	local lc   = os.getenv('LC_TYPE')   
	if lang and find(string.lower(lang), 'utf8') then
		clen = utf8len ; IsUtf8 = true
	elseif lc and find(string.lower(lc), 'utf8') then
		clen = utf8len ; IsUtf8 = true
	end
end
-- x = 'Aéŝ'; print(x..' is '..tostring(len(x))..' characters long')

local function puts(s)
	if type(s) == 'table' then s = table.concat(s, '') end
	if not s then return end
	Irow = Irow + select(2, gsub(s, '\n', '\n'))  -- PiL p.179
	if find(s, '\r\n?$') then
		Icol = 0
	else
		Icol = Icol + clen(s)
	end
	TTY:write(s) ; TTY:flush()
end

-- could terminfo sgr0, bold, rev ...
local function attrset(attr)
	if not attr or attr==0 then
		TTY:write("\027[0m")
	else
		if B.band(attr,A_BOLD) > 0      then TTY:write("\027[1m") end
		if B.band(attr,A_REVERSE) > 0   then TTY:write("\027[7m") end
		if B.band(attr,A_UNDERLINE) > 0 then TTY:write("\027[4m") end
	end
	TTY:flush()
end
local function beep     ()  TTY:write("\007")    TTY:flush() end
local function clear    ()  TTY:write(TI['clear_screen']) TTY:flush() end
local function clrtoeol ()  TTY:write(TI['clr_eol'])      TTY:flush() end
local function black    ()  TTY:write("\027[30m") TTY:flush() end
local function red      ()  TTY:write("\027[31m") TTY:flush() end
local function green    ()  TTY:write("\027[32m") TTY:flush() end
local function blue     ()  TTY:write("\027[34m") TTY:flush() end
local function violet   ()  TTY:write("\027[35m") TTY:flush() end

local function getc_wrapper (timeout)
	local c = K.ReadKey(timeout, TTY)
	-- if c is nil and SizeChanged, then we should check_size and try again
	-- can check_size be called whenever this getc_wrapper has been called?
	return c
end

local function wr_cell(t) end

local function handle_mouse (x, y, button_pressed, button_drag) -- 1.50 
	TopRow = AbsCursY - CursorRow;
	if LastEventWasPress then LastEventWasPress = false; return false end
	if y < TopRow then return false end
	local mouse_row = y - TopRow
	local mouse_col = x - 1
	local ifound = nil
	for i =1,#Irow_a do
		if Irow_a[i] == mouse_row then
			if Icol_a[i] < mouse_col
			 and ((Icol_a[i] + clen(List[i])) >= mouse_col) then
				ifound = i; break
			end
			if Irow_a[i] > mouse_row then break end
		end
	end
	if not ifound then return false end
	-- if xterm doesn't receive a button-up event it thinks it's dragging
	local return_char = ''
	if button_pressed == 1 and button_drag == 0 then
		LastEventWasPress = true
		return_char = KEY_ENTER;
	elseif button_pressed == 3 and button_drag == 0 then
		LastEventWasPress = true
		return_char = ' '
	end
	if ifound ~= ThisCell then
		local t = ThisCell; ThisCell = ifound
		wr_cell(t)
		wr_cell(ThisCell)  -- needs global List
	end
	return return_char
end

local function getch()  -- return multiple bytes if utf8
	local c = getc_wrapper(0)
	if c == "\027" then
		c = getc_wrapper(0.10)

		if c == nil then return "\027" end
		if c == 'A' then return KEY_UP end
		if c == 'B' then return KEY_DOWN end
		if c == 'C' then return KEY_RIGHT end
		if c == 'D' then return KEY_LEFT end
		if c == '2' then getc_wrapper(0); return KEY_INSERT end
		if c == '3' then getc_wrapper(0); return KEY_DELETE end -- 1.54
		if c == '5' then getc_wrapper(0); return KEY_PPAGE end
		if c == '6' then getc_wrapper(0); return KEY_NPAGE end
		if c == 'Z' then return KEY_BTAB end
		if c == 'O' then   -- 1.68 Haiku wierdness, inherited from an old Suse
			c = getc_wrapper(0)
			if c == 'A' then return KEY_UP end    -- 1.68
			if c == 'B' then return KEY_DOWN end  -- 1.68
			if c == 'C' then return KEY_RIGHT end -- 1.68
			if c == 'D' then return KEY_LEFT end  -- 1.68
			if c == 'F' then return KEY_END end   -- 1.68
			if c == 'H' then return KEY_HOME end  -- 1.68
			return(c);
		end
		if c == '[' then
			c = getc_wrapper(0)
			if c == 'A' then return KEY_UP end
			if c == 'B' then return KEY_DOWN end
			if c == 'C' then return KEY_RIGHT end
			if c == 'D' then return KEY_LEFT end
			if c == 'F' then return KEY_END end   -- 1.67
			if c == 'H' then return KEY_HOME end  -- 1.67
			if c == 'M' then   -- mouse report - we must be in BYTES !
				-- http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
				local event_type = B.band(127,string.byte(getc_wrapper(0)))-32
				local x = B.band(127,string.byte(getc_wrapper(0)))-32
				local y = B.band(127,string.byte(getc_wrapper(0)))-32
				-- local $shift   = $event_type & 0x04; -- used by wm
				-- local $meta	= $event_type & 0x08;   -- used by wm
				-- local $control = $event_type & 0x10; -- used by xterm
				local button_drag = B.rshift(B.band(event_type, 32), 5)
				local button_pressed;
				local low3bits = B.band(event_type, 3)
				if low3bits == 3 then
					button_pressed = 0
				else  -- button 4 means wheel-up, button 5 means wheel-down
					if B.band(event_type, 64) ~= 0 then
						button_pressed = low3bits + 4
					else
						button_pressed = low3bits + 1
					end
				end
				return handle_mouse(x,y,button_pressed,button_drag) or getch()
			end
			if match(c, '%d') then
				local c1 = getc_wrapper(0);
				if c1 == '~' then
					if c == '2' then return KEY_INSERT
					elseif c == '3' then return KEY_DELETE
					elseif c == '5' then return KEY_PPAGE
					elseif c == '6' then return KEY_NPAGE
					end
				else   -- cursor-position report, response to \027[6n
					AbsCursY = tonumber(c)
					while true do
						if c1 == ';' then break end
						AbsCursY = 10*AbsCursY + (tonumber(c1) or 0) -- 1.76
						c1 = TTY:read(1)
					end
					AbsCursX = 0
					while true do
						c1 = TTY:read(1)
						if c1 == 'R' or not c1 then break end -- 1.73
						AbsCursX = 10*AbsCursX + (tonumber(c1) or 0) -- 1.76
					end
					return getch()
				end
			end
			if c == 'Z' then return KEY_BTAB end
			return c
		end
		return c
	elseif IsUtf8 then
		local b = string.byte(c)
		local nbytes = 1
		if     B.band(b, 224) == 192 then nbytes = 2
		elseif B.band(b, 240) == 224 then nbytes = 3
		elseif B.band(b, 248) == 240 then nbytes = 4
		elseif B.band(b, 252) == 248 then nbytes = 5
		elseif B.band(b, 254) == 252 then nbytes = 6
		end
		if nbytes == 1 then return c end
		local str_a = {c}  -- it's a uft8 character
		for i = 2,nbytes do str_a[#str_a+1] = getc_wrapper(0) end
		return table.concat(str_a, '')
	else
		return c
	end
end
local function up(n)
	-- if n < 0 then down(0-n); return end
	TTY:write(string.rep(TI['cursor_up'], n)); TTY:flush()
	Irow = Irow - n
end
local function down(n)
	-- if n < 0 then up(0-n); return end
	TTY:write(string.rep(TI['cursor_down'], n)); TTY:flush()
	Irow = Irow + n
end
local function right(n)
	-- if n < 0 then left(0-n); return end
	TTY:write(string.rep(TI['cursor_right'], n)); TTY:flush()
	Icol = Icol + n
end
local function left(n)
	-- if n < 0 then right(0-n); return end
	TTY:write(string.rep(TI['cursor_left'], n)); TTY:flush()
	Icol = Icol - n
end
local function go_to ( newcol, newrow)
	if newcol == 0 then TTY:write("\r"); TTY:flush(); Icol = 0
	elseif newcol > Icol then right(newcol-Icol)
	elseif newcol < Icol then left(Icol-newcol)
	end
	if newrow > Irow     then down(newrow-Irow)
	elseif newrow < Irow then up(Irow-newrow)
	end
end
-- sub move { my ($ix,$iy) = @_; printf TTY "\027[%d;%dH",$iy+1,$ix+1; }

local InitscrAlreadyRun = 0;   -- increments and decrements
local IsMouseMode       = false;
local WasMouseMode      = false;

local function enter_mouse_mode()   -- 1.50
	if os.getenv('CLUI_MOUSE') == 'OFF' then return false end   -- 1.62
	if IsMouseMode then
		io.stderr:write("enter_mouse_mode but already IsMouseMode\r\n")
		return false
	end
	TTY:write("\027[?1003h"); TTY:flush()  -- sets SET_ANY_EVENT_MOUSE mode
	IsMouseMode = true
	return true
end
local function leave_mouse_mode()   -- 1.50
	if os.getenv('CLUI_MOUSE') == 'OFF' then return false end   -- 1.62
	if not IsMouseMode then
		io.stderr:write("leave_mouse_mode but not IsMouseMode\r\n")
		return false
	end
	TTY:write("\027[?1003l"); TTY:flush() -- cancels SET_ANY_EVENT_MOUSE mode
	IsMouseMode = false
	return true
end

local function initscr(args)
	local mouse_mode = args['mouse_mode']		  -- for mouse-handling
	if os.getenv('CLUI_MOUSE') == 'OFF' then mouse_mode = nil end  -- 1.62
	if InitscrAlreadyRun > 0 then
		InitscrAlreadyRun = InitscrAlreadyRun + 1
		if not mouse_mode and IsMouseMode then
			if not leave_mouse_mode() then return nil end
		elseif mouse_mode and not IsMouseMode then
			if not enter_mouse_mode() then return nil end
		end
		WasMouseMode = IsMouseMode
		Icol = 0; Irow = 0
		return
	end
	TTY = assert(io.open(P.ctermid(), 'a+')) -- the controlling terminal
	if mouse_mode then
		IsMouseMode = true
		TTY:write("\027[?1003h"); TTY:flush() -- sets SET_ANY_EVENT_MOUSE mode
	else
		IsMouseMode = false
	end

	K.ReadMode('ultra-raw', TTY);
	Icol = 0; Irow = 0; InitscrAlreadyRun = 1
end

function endwin()
	TTY:write("\027[0m"); TTY:flush()
	if InitscrAlreadyRun > 1 then
		if     (IsMouseMode and not WasMouseMode) then leave_mouse_mode()
		elseif (not IsMouseMode and WasMouseMode) then enter_mouse_mode()
		end
		InitscrAlreadyRun = InitscrAlreadyRun - 1
	end
	TTY:write("\027[?1003l"); TTY:flush();  IsMouseMode = 0
	K.ReadMode('restore', TTY)
	TTY:close() -- close TTYIN;
	InitscrAlreadyRun = 0
end


-------------------------- infrastructure -------------------------

local function erase_lines(n)  -- leaves cursor at beginning of line n
	go_to(0, n); TTY:write(TI['clr_eos']); TTY:flush()
end

local function fmt (text, options)
	-- Used by ask ,choose, confirm and tiview; formats text within MaxCols
	if not options then options = {} end
	local i_words = {}
	local i_lines = split(text, '\r?\n\r?')
	local o_lines = {}
	local o_line = ''
	local o_length = 0
	local last_line_empty = false
	local w_length = 0
	local initial_space = ''
	for k,i_line in ipairs(i_lines) do
		if find(i_line, '^%s*$') then   -- blank line ?
			if o_line ~= '' then
				o_lines[#o_lines+1] = o_line; o_line=''; o_length=0
			end
			if not last_line_empty then
				o_lines[#o_lines+1]=""; last_line_empty=true
			end
			-- next;  :-(
		else  -- not a blank line
			last_line_empty = false
			if options['nofill'] then
				o_lines[#o_lines+1] = string.sub(i_line, 1, MaxCols-1)
				i_line = string.sub(i_line, MaxCols, -1)
				-- next;  :-(
			else
				if find(i_line, '^%s+') then
					initial_space, i_line = match(i_line, '^(%s+)(.*)')
					initial_space = gsub(initial_space, '\t', '   ')
					if o_line ~= '' then o_lines[#o_lines+1] = o_line end
					o_line = initial_space
					o_length = blen(initial_space)
				else
					initial_space = ''
				end
				i_words = split(i_line, ' ')
				for k,i_word in ipairs(i_words) do
					w_length = clen(i_word)
					if o_length + w_length >= MaxCols then
						o_lines[#o_lines+1] = o_line
						o_line = initial_space
						o_length = blen(initial_space)
					end
					if w_length >= MaxCols then  -- chop it !
						o_lines[#o_lines+1] = string.sub(i_word, 1, MaxCols-1)
						i_word = string.sub(i_word, MaxCols, -1)
						-- next; :-(
					else
						if o_line ~= '' then
							o_line = o_line..' '; o_length = o_length+1
						end
						o_line = o_line..i_word; o_length = o_length+w_length
					end
				end
			end
		end
	end
	if o_line~='' then o_lines[#o_lines+1] = o_line end
	if #o_lines < MaxRows-2 then return o_lines
	else
		for i = (MaxRows-2), #o_lines do o_lines[i] = nil end
		return o_lines
	end
end


local function check_size() -- size handling
	-- debug('check_size: SizeChanged=',SizeChanged)
	if not SizeChanged then return end
	MaxCols, MaxRows = K.GetTerminalSize(TTY)
	MaxCols = tonumber(MaxCols) - 1
	MaxRows = tonumber(MaxRows)
	-- _debug('MaxCols=',MaxCols,' MaxRows=',MaxRows)
	if OtherLines and #OtherLines > 0 then
		OtherLines = fmt(table.concat(OtherLines, "\n"))
	end
	SizeChanged = false
end
check_size()

-- $SIG{'WINCH'} = sub { $SizeChanged = 1; };
-- http://luaposix.github.io/luaposix/docs/index.html
-- P.signal (signum, handler, flags)
-- SIGWINCH is not part of POSIX; asm-generic/signal.h says it's 28
P.signal (28, function()
	SizeChanged=true
	-- _debug('detected SIGWINCH')
end, 0)  -- 1.70
-- luaposix only has SA_RESETHAND SA_NOCLDSTOP SA_NODEFER SA_NOCLDWAIT
-- asm-generic/signal.h says SA_RESTART is 0x10000000 which is 268435456

local function display_otherlines(question)
	local a = split(question, '\r?\n', 2)
	local otherlines = fmt(a[2])
	if otherlines and #otherlines>0 then
		local tty = io.open(P.ctermid(), 'a')
		tty:write("\n\n"..table.concat(otherlines,"\n"))
		tty:write(string.rep("\r\27[A", #otherlines+1))
		tty:flush()
		tty:close()
	end
	return a[1]  -- return firstline
end

------------------------ ask stuff -------------------------

function M.ask_filename (question)
	return M.ask(question)  -- filename-completion is the default
end

function M.ask_password(question)  -- no echo - use for passwords
	if not question then question = 'Password ? ' end
	local firstline = display_otherlines(question)
	local tty = io.open(P.ctermid(), 'a+') -- the controlling terminal
	K.ReadMode( 'noecho', tty )
	local p = K.ReadLine(firstline..' ', '')
	K.ReadMode( 'restore', tty )
	tty:write("\n")
	tty:write(TI['clr_eos'])
	tty:close()
	return p
end

function M.ask (question)
	local firstline = display_otherlines(question)
	local answer = K.ReadLine(firstline..' ', HistFile)
	local tty = io.open(P.ctermid(),'a+')
	tty:write(TI['clr_eos']); tty:close()
	return answer
end

----------------------- choose stuff -------------------------

local function dbm_file()
	local db_dir
	if os.getenv('CLUI_DIR') then
		if find(string.lower(os.getenv('CLUI_DIR'), 'off')) then
			return nil
		end
		db_dir = tilde_expand(os.getenv('CLUI_DIR'))
	else
		db_dir = HOME..'/.clui_dir'
	end
	P.mkdir(db_dir)
	return db_dir..'/choices.gdbm'
end

function M.get_default (question)
	if os.getenv('CLUI_DIR') and
	  find(string.lower(os.getenv('CLUI_DIR'), 'off')) then
		return nil
	end
	if not question then return nil end
	local db
	local dbfile = dbm_file()
	for n_tries=1,5 do
		db = G.open(dbfile, "c")
		if db then break end
		sleep( 0.25 * math.random() )
	end
	local choices = split(db:fetch(question) or '', '\28')  -- Perl $;
	db:close()
	if wantarray then return choices else return choices[1] end
end

function M.set_default (question, ...)
	local s = table.concat({...}, '\28')  -- Perl $;
	if os.getenv('CLUI_DIR')
	  and find(string.lower(os.getenv('CLUI_DIR'), 'off')) then
		return nil
	end
	if not question then return nil end
	local db
	local dbfile = dbm_file()
	for n_tries=1,5 do
		db = G.open(dbfile, "w")
		if db then break end
		sleep( 0.35 * math.random() )
	end
	if not db:insert(question,s) then db:replace(question,s) end
	db:close()
	return s
end

local function layout (list)
	ThisCell = 1
	local irow = 1; local icol = 0;  local l = {}
	for i,v in ipairs(list) do
		l[i] = clen(v) + 2
		if l[i] > (MaxCols-1) then l[i] = MaxCols-1 end  -- 1.42
		if icol + l[i] >= MaxCols  then irow=irow+1; icol=0 end
		if irow > MaxRows then return irow end  -- save time
		Irow_a[i] = irow; Icol_a[i] = icol;
		icol = icol + l[i]
		if v == Choice then ThisCell = i end
	end
	return irow  -- would it be premature to set Nrows immediately ?
end

wr_cell = function (i)
	local no_tabs = gsub(List[i], '\t', ' ')
	go_to(Icol_a[i], Irow_a[i]);
	if Marked[i] then attrset(B.bor(A_BOLD, A_UNDERLINE)) end
	if i == ThisCell then attrset(A_REVERSE) end
	puts(string.sub(" "..no_tabs.." ", 1, MaxCols))  -- 1.42, 1.54
	if Marked[i] or i == ThisCell then attrset(A_NORMAL) end
end

local function wr_screen()
	for i = 1,#List do
		if i ~= ThisCell then wr_cell(i) end
	end
	if #OtherLines>0 and (Nrows+#OtherLines) < MaxRows then
		puts("\r\n\n"..table.concat(OtherLines,"\r\n").."\r")
	end
	wr_cell(ThisCell)
end

local function size_and_layout(list, erase_rows)
	check_size()
	if erase_rows>0 then
		if erase_rows > MaxRows then erase_rows = MaxRows end -- XXX?
		erase_lines(1)
	end
	Nrows = layout(list)
	return Nrows
end

local function ask_for_clue (nchoices, i, s)
	if nchoices > 0 then
		if s and blen(s) > 0  then
			local headstr = "the choices won't fit; there are still";
			go_to(0,1); puts(headstr..' '..nchoices..' of them'); clrtoeol()
			go_to(0,2); puts('lengthen the clue : '); right(i-1)
		else
			local headstr = "the choices won't fit; there are";
			go_to(0,1); puts(headstr..' '..nchoices..' of them'); clrtoeol()
			go_to(0,2)
			puts("   give me a clue :             (or ctrl-X to quit)");
			left(31);   -- 1.62
		end
	else
		go_to(0,1); puts("No choices fit this clue !"); clrtoeol();
		go_to(0,2); puts(" shorten the clue : "); right(i)
	end
end

local function narrow_the_search (biglist)
	local nchoices = #biglist
	local i = 1
	local ss = ''
	local s = {} -- each element of s is a Character, and can be several Bytes
	local list = deepcopy(biglist)
	ClueHasBeenGiven = true
	leave_mouse_mode()
	ask_for_clue(nchoices, i, ss)
	while true do
		local c = getch()
		local next_please = false
		if SizeChanged then
			size_and_layout(list, 0)
			if Nrows < MaxRows then
				erase_lines(1); enter_mouse_mode(); return list
			end
		end
		if c == KEY_LEFT then
			if i > 1 then i = i-1; left(1) end
			next_please = true
		elseif c == KEY_RIGHT then
			if i <= #s then puts(s[i]); i=i+1 end
			next_please = true
		elseif (c == "\b") or (c == "\127") then
			if i > 1 then
			 	i = i-1
				s = splice(s, i, 1); left(1)
			  	for j = i,#s do puts(s[j]) end
				clrtoeol(); left(#s-i); next_please = true
			end
		elseif c == "\3" then  -- 1.56
			erase_lines(1); endwin()
			io.stderr:write("^C\r\n")
			P.kill(P.getpid('pid'), P.SIGINT)
			enter_mouse_mode(); return {}  -- 1.71
		elseif c == "\24" or c == "\4" then  -- ^X, ^D, clear ...
			if not s or #s < 1 then   -- 20070305 ?
				ClueHasBeenGiven = false; erase_lines(1)
				enter_mouse_mode(); return {}
			end
			left(i-1); i = 1; s = {}; clrtoeol()
		elseif c == "\1" then left(i-1); i = 1;  next_please = true
		elseif c == "\5" then right(#s-i); i = #s; next_please = true
		elseif c == "\f" then  -- ignore it
		-- elseif (SpecialKey[c]) then beep()
		elseif type(c) == 'number' then next_please = true
		elseif string.byte(c) >= 32 then  -- 1.51
			s = splice(s, i, 0, c)
			i=i+1; puts(c)
			for j = i,#s do puts(s[j]) end
			clrtoeol(); left(#s-i)
		else beep()  -- exercise in futility
		end
		-- we test if next was wanted, and if so skip the remainder...
		-- grep, and if nchoices=1 return
		if not next_please then  -- the clue has been changed: re-grep...
			ss = table.concat(s, "")
			list = {}
			for k,v in ipairs(biglist) do
				if find(v, ss) then list[#list+1] = v end
			end
			nchoices = #list
			Nrows = layout(list)
			if nchoices==1 or (nchoices>1 and Nrows<MaxRows) then
				puts("\r"); clrtoeol(); up(1); clrtoeol();
				enter_mouse_mode(); return list
			end
			ask_for_clue(nchoices, i, ss)
		end
	end
	io.stderr:write("narrow_the_search: shouldn't reach here ...\r\n")
end

function M.choose (question, a_list, options)
	if not a_list or #a_list == 0 then return nil end
	if not options then options = {} end
	check_size()
	wantarray = false
	if options['multichoice'] then wantarray = true end
	-- local list = {}
	-- grep (($_ =~ s/[\r\n]+$//) and 0, @list);	-- chop final newlines
	List = {}  -- 1.70
	for k,v in ipairs(a_list) do List[k] = gsub(v, '%s$', '') end
	local biglist = deepcopy(List)
	local icell
	Marked = {}
	gsub(question, '^[\n\r]+', '')  -- strip initial newline(s)
	gsub(question, '[\n\r]+$', '')  -- strip final newline(s)
	local firstline = question
	local remainder = ''
	if find(question, '\n') then
		firstline, remainder = match(question,'^([^\n\r]*)\r?\n\r?(.*)')
	end
	local firstlinelength = clen(firstline)

	Choice = M.get_default(firstline)
	-- If wantarray ? Is remembering multiple choices safe ?

	initscr{mouse_mode=true}
	size_and_layout(List, 0)
	-- in Term::Clui, this was local; but that may be a bug...
	OtherLines  = fmt(remainder)
	if wantarray then
		if firstlinelength < (MaxCols-30) then
			puts(firstline.." (multiple choice with spacebar)\n\r");
		elseif firstlinelength < (MaxCols-16) then
			puts(firstline.." (multiple choice)\n\r");
		elseif firstlinelength < (MaxCols-9) then
			puts(firstline.." (multiple)\n\r");
		else
			puts(firstline.."\n\r");
		end
	else
		puts(firstline.."\n\r");
	end
	if Nrows >= MaxRows then
		List = narrow_the_search(List);
		if #List == 0 then
			up(1); clrtoeol(); endwin(); ClueHasBeenGiven = false
			if wantarray then return {} else return nil end
		end
	end
	wr_screen() -- the cursor is now on ThisCell, not on the question
	TTY:write("\027[6n"); TTY:flush() -- terminfo u7, will set AbsCursX,AbsCursY
	CursorRow = Irow_a[ThisCell]  -- global, needed by handle_mouse

	while true do
		local c = getch();
		local next_please = false
		if SizeChanged then
			-- _debug('choose: SizeChanged was true')
			size_and_layout(List, Nrows)
			if Nrows >= MaxRows then
				List = narrow_the_search(List);
				if #list == 0 then
					up(1); clrtoeol(); endwin(); ClueHasBeenGiven = false
					if wantarray then return {} else return nil end
				end
			end
			wr_screen()
		end
		if c == "q" or c == "\4" or c == "\24" then
			erase_lines(1)
			if ClueHasBeenGiven then
				local re_clue = M.confirm("Do you want to change your clue ?")
				up(1); clrtoeol()   -- erase the confirm
				if re_clue then
					Irow = 1
					List = biglist
					List = narrow_the_search(List); wr_screen()
					next_please = true
				else
					up(1); clrtoeol(); endwin(); ClueHasBeenGiven = false
					if wantarray then return {} else return nil end
				end
			end
			if not next_please then
				go_to(0,0); clrtoeol(); endwin(); ClueHasBeenGiven = false
				if wantarray then return {} else return nil end
			end
		elseif (c == "\t") and (ThisCell < #List) then
			ThisCell = ThisCell+1;
			wr_cell(ThisCell-1); wr_cell(ThisCell); 
		elseif ((c == "l") or (c == KEY_RIGHT)) and (ThisCell < #List)
			and (Irow_a[ThisCell] == Irow_a[ThisCell+1]) then
			ThisCell = ThisCell+1
			wr_cell(ThisCell-1); wr_cell(ThisCell);
		elseif ((c == "\8") or (c == KEY_BTAB)) and (ThisCell > 1) then
			ThisCell = ThisCell - 1
			wr_cell(ThisCell+1); wr_cell(ThisCell);
		elseif ((c == "h") or (c == KEY_LEFT)) and (ThisCell > 1)
			and (Irow_a[ThisCell] == Irow_a[ThisCell-1]) then
			ThisCell = ThisCell-1
			wr_cell(ThisCell+1); wr_cell(ThisCell); 
		elseif (((c == "j") or (c == KEY_DOWN)) and (Irow < Nrows)) then
			local mid_col = Icol_a[ThisCell] + 0.5*clen(List[ThisCell]) -- 1.71
			local left_of_target = 1000 -- 1.71
			local inew = ThisCell + 1   -- 1.71
			while inew < #List do  -- <=?
				if Icol_a[inew] < mid_col then break end	-- skip rest of row
				inew = inew + 1
			end
			local new_mid_col = 0  -- 1.70
			while inew < #List do  -- <=?
				new_mid_col = Icol_a[inew] + 0.5*clen(List[inew]);
				if new_mid_col >= mid_col then break end  -- we've reached it
				if Icol_a[inew+1] <= Icol_a[inew] then break end -- EOL
				left_of_target = mid_col - new_mid_col
				inew = inew + 1
			end
			if (new_mid_col-mid_col) > left_of_target then inew = inew-1 end
			local iold = ThisCell; ThisCell = inew  -- 1.71
			wr_cell(iold); wr_cell(ThisCell)
		elseif ((c == "k") or (c == KEY_UP)) and (Irow > 1) then
			local mid_col = Icol_a[ThisCell] + 0.5*clen(List[ThisCell]) -- 1.71
			local right_of_target = 1000   -- 1.71
			local inew = ThisCell - 1      -- 1.71
			while inew > 1 do  -- 1 ?  yes 1.70
				if Irow_a[inew] < Irow_a[ThisCell] then break end
				inew = inew - 1
			end
			local new_mid_col = 0  -- 1.70
			while inew > 1 do -- 1 ?  yes 1.70
				if Icol_a[inew] < 1 then break end
				new_mid_col = Icol_a[inew] + 0.5*clen(List[inew])
				if new_mid_col <= mid_col then break end  -- 1.78 <=
				right_of_target = new_mid_col - mid_col
				inew = inew - 1
			end
			if (mid_col - new_mid_col) > right_of_target then
				inew = inew + 1
			end
			local iold = ThisCell; ThisCell = inew  -- 1.71
			wr_cell(iold); wr_cell(ThisCell)
		elseif c == "\f" then
			if SizeChanged then
				size_and_layout(List, Nrows)
				if Nrows >= MaxRows then
					List = narrow_the_search(List)
					if #List == 0 then
						up(1); clrtoeol(); endwin()
						ClueHasBeenGiven = false
						if wantarray then return {} else return nil end
					end
				end
			end
			wr_screen()
		elseif c == "\3" then  -- 1.56
			erase_lines(1); endwin()
			io.stderr:write("^C\r\n")
--			P.kill(P.getpid('pid'), P.SIGINT)   -- XXX 20171128 superfluous?
-- the trouble is, this causes a
-- /usr/local/bin/lua: /home/pjb/lua/lib/CommandLineUI.lua:1014: interrupted!
-- stack traceback:
--     [C]: in function 'posix.kill'
-- and stackdump.  Was there a good reason why I avoided os.exit() ?
-- Was it because the calling app might have set up a signal handler ?
-- Perhaps just     if wantarray then return {} else return nil end
-- like for "q" ?    or just return nil and skip the kill ?
			return nil
		elseif c == "\r" then
			erase_lines(1); go_to(firstlinelength+1, 0);
			local chosen = {}
			if wantarray then
				for i,v in ipairs(List) do
					if Marked[i] or i==ThisCell then
						chosen[#chosen+1] = List[i]
					end
				end
				clrtoeol();
				local remaining = MaxCols-firstlinelength
				local last = table.remove(chosen)
				local dotsprinted
				for k,v in ipairs(chosen) do
					if remaining - clen(v) < 4 then
						dotsprinted = true; puts("...")
						remaining = remaining-3; break
					else
						puts(v..', ')
						remaining = remaining - 2 - clen(v)
					end
				end
				if not dotsprinted then
					if (remaining - clen(last)) > 0 then puts(last)
					elseif remaining > 2 then puts('...')
					end
				end
				puts("\n\r")
				chosen[#chosen+1] = last
			else
				puts(List[ThisCell].."\n\r")
			end
			endwin()
			M.set_default(firstline, List[ThisCell]); -- join($,,@chosen) ?
			ClueHasBeenGiven = false
			if wantarray then return chosen else return List[ThisCell] end
		elseif c == " " then
			if wantarray then
				Marked[ThisCell] = not Marked[ThisCell]
				wr_cell(ThisCell)
			end
		elseif c == "?" then
			io.stderr:write("help\r\n")  -- BUG: extremely unhelpful :-(
			-- should maybe set OtherLines to help_text('choose') and redraw
		end
	end
	endwin()
	io.stderr:write("choose: shouldn't reach here ...\r\n")
end

function M.help_text(mode) -- 1.54
	local text
	if mode == 'ask' then
		return "\nLeft, Right, Backspace, Delete; ctrl-A=beginning; "
		 .. "ctrl-E=end; Tab-completion; Up,Down=history; then Return."
	end
	if find(mode, 'pass') then
		return "\nLeft, Right, Backspace, Delete; ctrl-A=beginning; "
		 .. "ctrl-E=end; then Return."
	end
	-- default is choose ...
	if os.getenv('CLUI_MOUSE') == 'OFF' then
		text = "\nmove around with Arrowkeys (or hjkl);"
	else
		text = "\nmove around with Mouse or Arrowkeys (or hjkl);"
	end
	if match(mode, 'multi') then
		text = text.." multiselect with Rightclick or Spacebar;"
	end
	text = text.." then either q or ctrl-X for quit,"
	if os.getenv('CLUI_MOUSE') == 'OFF' then
		text = text.." or Return to choose."
	else
		text = text.." or choose with Leftclick or Return."
	end
	return text
end

----------------------- confirm stuff -------------------------

function M.confirm (question)  -- asks user Yes|No, returns true|false
	if not question or blen(question)<1 then return end
	local firstline = display_otherlines(question);
	local tty = io.open(P.ctermid(),'a+')
	tty:write(firstline.." (y/n) ")
	tty:flush()
	K.ReadMode('ultra-raw', tty)
	local response = ''
	while true do
		response = K.ReadKey(0, tty)
		if response == "\3" then   -- ^C 1.56
			-- erase_lines(1); endwin(); warn("^C\n")
			K.ReadMode('restore', tty); tty:flush(); tty:close()
			P.kill(P.getpid('pid'), P.SIGINT)
			return nil
		end
		if find(response, '[yYnN]') then break end
	end
	tty:write(string.rep(TI['cursor_left'], 6))
	tty:write(TI['clr_eos'])
	if find(response, '[yY]') then
		tty:write("Yes\r\n")
	else
		tty:write("No\r\n")
	end
	K.ReadMode('restore', tty); tty:flush(); tty:close()
	if find(response, '[yY]') then return true else return false end
end

----------------------- edit stuff -------------------------

function M.edit (title, text)
	local dirname, basename, rcsdir, rcsfile, rcs_ok, tmpdir
	local editor = os.getenv('EDITOR') or "vi" -- should check ~/db/choices.db
	if not title then	-- start editor session with no preloaded file
		os.execute(editor)
	elseif text then
		-- must create tmp file with title embedded in name
		local tmpdir = '/tmp/'
		local safename = gsub(title, '[%W_]+', '_')
		local file = tmpdir..safename..'_'..P.getpid('pid')
		local F = assert(io.open(file, 'w'))
		if not F then return '' end
		F:write(text); F:close()
		os.execute(editor..' '..file)
		F = assert(io.open(file, 'r'))
		if not F then return '' end
		text = F:read('*all')
		F:close(); os.remove(file); return text
	else  -- its a file, we will try RCS ...
		local file = title
		-- weed out no-go situations needs require 'lfs', lfs.attributes(file)
		--if (-d $file) then
		--	M.sorry("$file is already a directory\n"); return 0
		--end
		--if (-B _ and -s _) then
		--	M.sorry("$file is not a text file\n"); return 0
		--end
		--if (-T _ and !-w _) then view($file); return 1; end
		-- it's a writeable text file, so work out the locations
		if find(file, '/') then
			dirname  = P.dirname(file)
			basename = P.basename(file)
			rcsdir   = dirname..'/RCS'
		else
			basename = file
			rcsdir   = "RCS"
		end
		rcsfile = rcsdir..'/'..basename..',v';
		local rcslog = rcsdir..'/log'
		-- we no longer create the RCS directory if it doesn't exist,
		-- so `mkdir RCS' to enable rcs in a directory ...
		rcs_ok = false
		if P.stat(rcsdir) and P.dir(rcsdir) then rcs_ok = true end
		--if (-d _ and ! -w _) then
		--	rcs_ok = false
		--	warn("can't write in $rcsdir\n")
		--end
		-- if the file doesn't exist, but the RCS does, then check it out
		if rcs_ok and P.stat(rcsfile) and not P.stat(file) then
			os.ececute("co -l '"..file.."' '"..rcsfile.."'")
		end

		local starttime = os.time()
		os.execute(editor..' '..file)
		local elapsedtime = os.time() - starttime
		-- could be output or logged, for worktime accounting
	
		if rcs_ok and P.stat(file) then  -- check it in
			if not P.stat(rcsfile) then
				local msg = ask(file..' is new. Please describe it:')
				local quotedmsg = gsub(msg, "'", "'\"'\"'")
				if msg and blen(msg)>0 then
					os.execute(
					  "ci -q -l -t-'"..quotedmsg.."' -i "..file..' '..rcsfile)
					logit(rcslog, basename, msg)
				end
			else
				local msg = ask("What changes have you made to $file ?")
				local quotedmsg = gsub(msg, "'", "'\"'\"'")
				if msg and blen(msg)>0 then
					os.execute(
					  "ci -q -l -m'"..quotedmsg.."' "..file.." "..rcsfile)
					logit(rcslog, basename, msg)
				end
			end
		end
	end
end
local function logit (rcslog, file, msg)
	local F = io.open(rcslog, 'a')
	if not F then  M.sorry("can't open "..rcslog) return nil end
	local pid = P.fork()  -- log in background for better response time
		if not pid then  -- child
			local user = P.getpid('euid')
			F.write(M.timestamp.." "..file.." "..user.." "..msg.."\n")
			F:close()
			os.exit(0)
		end
end

function M.timestamp() -- current date&time in "199403011 113520" format
	return(os.date('%Y%m%d %H%M%S'))  -- Lua wins this one :-)
end

----------------------- sorry stuff -------------------------

function M.sorry(msg) -- warns user of an error condition
	io.stderr:write("Sorry, "..msg.."\r\n")
end
function M.inform (msg)
	msg = gsub(msg, '\n*$', '\n')
	local tty = io.open(P.ctermid(), 'a')
	if tty then
		tty:write(msg); tty:close()
	else
		io.stderr:write(msg)
	end
end

----------------------- view stuff -------------------------

local function tiview (title, text)
	if not text or text == '' then return end
	-- local ($[) = 0;
	title = gsub(title, '\t', ' ')
	local titlelength = clen(title)
	check_size()
	local rows = fmt(text, {nofill=true})
	initscr{}
	if 3 > #rows then
		puts(title.."\r\n"..table.concat(rows,"\r\n").."\r\n");
		endwin(); return true
	end
	if titlelength > (MaxCols-35) then puts(title.."\r\n")
	else puts(title.."   (<enter> to continue, q to clear)\r\n")
	end
	puts{"\r", table.concat(rows, "\027[K\r\n"), "\r"}
	Icol = 0; Irow = #rows; go_to(titlelength+1, 0)
	
	while true do
		local c = getch()
		if c == 'q' or c == "\24" or c == "\23" or c == "\26"
		  or c == "\3" or c == "\28" then -- ^X ^W ^Z ^C ^\
			erase_lines(0); endwin(); return true
		elseif c == "\r" then  -- <enter> retains text on screen
			clrtoeol(); go_to(0, #rows+1); endwin(); return true
		elseif c == "\f" then
			puts("\r"); endwin(); tiview(title,text); return true
		end
	end
	io.stderr:write("tiview: shouldn't reach here\r\n")
end

function M.view (title, text)  -- or (filename) =
	if not text and find(string.lower(title),'%.doc$')
	  and P.access(title, 'r') then
		local wvText = which('wvText')
		if wvText then
			local tmpf = "/tmp/wv"..P.getpid('pid')
			os.execute(wvText.." '"..title.."' "..tmpf)
			os.execute(Pager..' '..tmpf)
			os.remove(tmpf); return true
		end
		local antiword = which('antiword')
		if antiword then
			os.execute(antiword.." -i 1 '"..title.."' | "..Pager)
			return true
		end
		local catdoc = which('catdoc')
		if catdoc then
			os.execute(catdoc.." '"..title.."' | "..Pager)
			return true
		end
		M.sorry("it's a .doc file; you should install wv, antiword or catdoc");
		return false
	elseif not text and is_textfile(title) then
		local F = assert(io.open(title, 'r'))
		local lines = {}
		while true do
			lines[#lines+1] = F:read('*line')
			if not F:read(0) then break end  -- EOF yet?
			if #lines > (0.6*MaxRows) then
				F:close(); os.execute(Pager.."  '"..title.."'"); return true
			end
		end
		lines[#lines+1] = F:read('*all')
		tiview(title, table.concat(lines, "\n"))
	else
		local lines = split(text, '\r?\n', MaxRows);
		if #lines <= (0.6*MaxRows) then
			tiview(title, text)
		else
			local safetitle = gsub(title, '[^a-zA-Z0-9]+', '_')
			local tmp = "/tmp/"..safetitle..P.getpid('pid')
			local TMP = assert(io.open(tmp, 'w'))
			TMP:write(text);	TMP:close()
			os.execute(Pager.." "..tmp)
			os.remove(tmp)
			return true
		end
	end
end


function M.back_up(n)
	if type(n) ~= 'number' or n < 1 then n = 1 end
	local tty = io.open(P.ctermid(), 'a')
	local msg = string.rep("\r\027[K\027[A\027[K", n)
	if tty then tty:write(msg); tty:close() else io.stderr:write(msg) end
end

return M

--[[

=pod

=head1 NAME

CommandLineUI - Lua module offering a Command-Line User Interface

=head1 SYNOPSIS

 local C = require 'CommandLineUI'
 print(C.Version, C.VersionDate)

 -- uses arrow-keys, or hjkl, or mouse ...
 choice  = C.choose("Which item ?", a_list)  -- single choice
 -- multi-line question-texts are fine ...
 choice  = C.choose("Which item ?"..C.help_text('choose'), a_list)
 choices = C.choose("Which items ?", a_list, {multichoice=true})

 if C.confirm("OK to proceed ?") then do_something() end

 answer   = C.ask(question)  -- with History and Tab-completion
 answer   = C.ask(question..C.help_text('ask'))
 password = C.ask_password("Enter password:")
 filename = C.ask_filename("Which file ?") -- synonym for C.ask()

 newtext = C.edit(title, oldtext) -- if title is _not_ a filename
 C.edit(textfile)     -- if textfile _is_ a filename

 C.view(title, text)  -- if title is _not_ a filename
 C.view(textfile)     -- if textfile _is_ a filename

 local P = require 'posix'
 C.edit(C.choose("Edit which file ?", P.glob('*.txt')))

=head1 DESCRIPTION

I<CommandLineUI>
offers a high-level user interface to give the user of
command-line applications a consistent "look and feel".
Its metaphor for the computer is as a human-like conversation-partner,
and as each question/response is completed it is summarised onto one line,
and remains on screen, so that the history of the session gradually
accumulates on the screen and is available for review,
or for highlight/paste.

This user interface can therefore be intermixed with
standard applications which write to STDOUT or STDERR,
such as I<make>, I<pgp>, I<rcs>, I<slrn>, I<mplayer>,
I<alpine>, I<wget>, I<luarocks> etc.

For the user, I<choose()> uses either the mouse,
or arrow keys (or hjkl) and Return;
also B<q> to quit, and SpaceBar or Button3 to highlight multiple choices.
I<confirm()> expects B<y>, B<Y>, B<n> or B<N>.
In general, ctrl-L redraws the (currently active bit of the) screen.
I<edit()> and I<view()> use the default EDITOR and PAGER if possible.  

It's fast and simple to use.
It depends on I<posix> but
doesn't use I<curses> (which is a whole-of-screen interface);
it uses a small subset of vt100 sequences which are very portable,
and also the I<SET_ANY_EVENT_MOUSE> and I<kmous> (terminfo) sequences,
which are supported by all I<xterm>, I<rxvt>, I<konsole>, I<screen>,
I<linux>, I<gnome> and I<putty> terminals.

It's a slightly leaner descendant of the Perl CPAN module I<Term::Clui>
and the Python3 module I<TermClui.py>,
which were in turn based on some old Perl4 libraries, I<ask.pl>, I<choose.pl>,
I<confirm.pl>, I<edit.pl>, I<sorry.pl>, I<inform.pl> and I<view.pl>,
which were in turn based on some even older curses-based programs in I<C>.

It is intended to keep the Perl, Python and Lua version-numbers
approximately synchronised.
This is I<CommandLineUI> version 1.72

=head1 WINDOW-SIZE

I<CommandLineUI> attempts to handle the WINCH signal.
If the window size is changed,
then as soon as the user enters the next keystroke (such as ctrl-L)
the current question/response will be redisplayed to fit the new size.

The first line of the question, the one which will remain on-screen, is
not re-formatted, but is left to be dealt with by the width of the window.
Subsequent lines are split into blank-separated words which are
filled into the available width; lines beginning with white-space
are treated as the beginning of a new indented paragraph,
individual words which will not fit onto one line are truncated,
and successive blank lines are collapsed into one.
If the question will not fit within the available rows, it is truncated.

If the available choice items in a I<choose()> overflow the screen,
the user is asked to enter "clue" letters,
and as soon as the items matching them will fit onto the screen
they are displayed as a choice.

The WINCH signal, unfortunately, is not defined by core POSIX,
and so is hardcoded here to 28. The command I<kill -l>
should tell you if this number is correct on your system.

=head1 FUNCTIONS

=over 3

=item I<ask( question )>

Asks the user the I<question> and returns a string answer,
with no newline character at the end.

This function uses I<Gnu Readline> to provide filename-completion with
the I<Tab> key, and history with the Up and Down arrow keys,
just like in the I<bash> shell.

It also displays multi-line questions in the
same way as I<confirm> and I<choose> do;
if the I<question> is multi-line,
the entry-field is at the top to the right of the first line,
and the subsequent lines are formatted within the
screen width and displayed beneath, as with I<choose> and I<confirm>.

For the user, left and right arrow keys move backward and forward
through the string, delete and backspace erase the previous character,
ctrl-A moves to the beginning, ctrl-E to the end,
and ctrl-D or ctrl-X clear the current string.

=item I<ask_password( question )>

Does the same as I<ask>, but with no echo, as used for password entry.

=item I<ask_filename( question )>

In this Lua module, Tab-filename-completion is enabled by default,
and this function is just a synonym for I<ask>

=item I<choose( question, a_list [, {multichoice=true}] )>

Displays the question, and formats the list items onto the lines beneath it.

If the I<multichoice> option is not set,
the user can choose an item using arrow keys (or hjkl) and Return,
or with the mouse-left-click,
or cancel the choice with a "q".
I<choose> then returns the chosen string,
or I<nil> if the choice was cancelled.

If the I<multichoice> option is set,
the user can also mark an item with the SpaceBar, or the mouse-right-click.
I<choose> then returns an array of the marked items,
(including the item highlit when Return was pressed),
or an empty array if the choice was cancelled.

A I<GDBM> database is maintained of the I<question> and its chosen response.
The next time the user is offered a choice with the same question,
if that response is still in the list it is highlighted
as the default; otherwise the first item is highlighted.
Different parts of the code, or different applications using I<CommandLineUI>,
can therefore share defaults simply by using the same question words,
such as "Which printer ?".
Multiple choices are not remembered, as the danger exists
that the user might fail to notice some of the highlit items
(for example, all the items might not fit onto one screen).

The database I<~/.clui_dir/choices.gdbm> or I<$CLUI_DIR/choices.gdbm>
is available to be read or written if lower-level manipulation is needed,
and the functions I<get_default>(question) and
I<set_default>(question, choice) should be used for this purpose,
as they handle DBM's problem with concurrent accesses.
The whole default database mechanism can be disabled by
I<CLUI_DIR=OFF> if you really want to :-(

If the items won't fit on the screen, the user is asked to enter
a substring as a clue. As soon as the matching items will fit,
they are displayed to be chosen as normal. If the user pressed B<q>
at this choice, they are asked if they wish to change their substring
clue; if they reply "n" to this, choose quits and returns I<nil>.

If the I<question> is multi-line,
the first line is put at the top as usual with the choices
arranged beneath it; the subsequent lines are formatted within the
screen width and displayed at the bottom.
After the choice is made, all but the first line is erased,
and the first line remains on-screen with the choice appended after it.
You should therefore try to arrange multi-line questions
so that the first line is the question in short form,
and subsequent lines are explanation.
The function I<help_text()> exists to provide general User-Interface help.

=item I<confirm( question )>

Asks the I<question>, and takes B<y>, B<n>, B<Y> or B<N> as a response.
If the I<question> is multi-line, after the response, all but the first
line is erased, and the first line remains on-screen with I<Yes> or I<No>
appended after it; you should therefore try to arrange multi-line
questions so that the first line is the question in short form,
and subsequent lines are explanatory.

Returns I<true> or I<false>.

=item I<edit( title, text )>  OR  I<edit( filename )>

Uses the environment variable EDITOR ( or I<vi> :-)
Uses I<rcs> if the directory RCS/ exists

=item I<sorry( message )>

Similar to I<io.stderr:write("Sorry, "..message.."\r\n")>

=item I<inform( message )>

Similar to I<io.stderr:write(message.."\r\n")> except that it
doesn't add the newline at the end if there already is one,
and it uses I</dev/tty> rather than I<STDERR> if it can.

=item I<view( title, text )>  OR  I<view( filename )>

If the I<text> is longer than a screenful, uses the environment
variable PAGER ( or I<less> ) to display it.
If it is one or two lines it just omits the title and displays it.
Otherwise it uses a simple built-in routine which expects either B<q>
or I<Return> from the user; if the user presses I<Return>
the displayed text remains on the screen and the dialogue continues
after it, if the user presses B<q> the text is erased.

If there is only one argument and it's a filename,
then the user's PAGER displays it,
except if it's a I<.doc> file, when either
I<wvText>, I<antiword> or I<catdoc> is used to extract its contents first.

=item I<help_text( mode )>

This returns a short help message for the user.
If I<mode> is "ask" then the text describes the keys the user has available
when responding to an I<ask> question;
If I<mode> contains the string "pass" then the text describes the keys the user has available
when responding to an I<ask_password> question;
If I<mode> is "multi" then the text describes the keys
and mouse actions the user has available
when responding to a multiple-choice I<choose> question;
otherwise, the text describes the keys
and mouse actions the user has available
when responding to a single-choice I<choose>.

=item I<beep()>

Beeps. Usually this has no effect; beeping is considered old-fashioned.

=item I<timestamp()>

Returns a sortable timestamp string in "YYYYMMDD hhmmss" form.

=item I<get_default( question )>

Consults the database I<~/.clui_dir/choices.gdbm> or
I<$CLUI_DIR/choices.gdbm> and returns the choice that
the user made the last time this I<question> was asked.
This is better than opening the database directly
as it handles DBM's problem with concurrent accesses.

=item I<set_default( question, new_default )>

Opens the database I<~/.clui_dir/choices.gdbm> or
I<$CLUI_DIR/choices.gdbm> and sets the default response which will
be offered to the user made the next time this I<question> is asked.
This is better than opening the database directly
as it handles DBM's problem with concurrent accesses.

=item I<back_up( nlines )>

This moves the cursor back up I<nlines> lines and erases all the
text beneath its new position. You don't often need it, but
sometimes in an application it can be neat to clear up a few lines.

=back

=head1 DEPENDENCIES

Requires the I<luarock> modules
I<luaposix>, I<terminfo>, I<readkey>, I<readline>, I<luabitop>, and I<lgdbm>.

See the SEE ALSO section below.

=head1 ENVIRONMENT

The environment variable I<CLUI_DIR> can be used (by programmer or user)
to override I<~/.clui_dir> as the directory in which I<choose()> keeps
its database of previous choices.
The whole default database mechanism can be disabled by
I<CLUI_DIR = OFF> if you really want to :-(

If the variable I<CLUI_MOUSE> is set to I<OFF>
then I<choose()> will not interpret mouse-clicks as making a choice.
The advantage of this is that the mouse can then be used
to highlight and paste text from this window as usual.

If the variables I<LANG> or I<LC_TYPE> contain the string I<utf8>
then all strings will be displayed assuming they are I<utf8> strings.
(It's a question of calculating the length of the string correctly.)

I<CommandLineUI.lua> also consults the environment variables
I<HOME>, I<EDITOR> and I<PAGER>, if they are set.

=head1 DOWNLOAD

This module is available as a LuaRock in
http://luarocks.org/modules/peterbillam
so you should be able to install it with the command:

 $ su
 Password:
 # luarocks install commandlineui

or:

 # luarocks install http://www.pjb.com.au/comp/lua/commandlineui-1.78-0.rockspec

The Perl module is available from CPAN at
http://search.cpan.org/perldoc?Term::Clui

=head1 CHANGES

 20200523 1.78 local variables for the common string functions
 20180630 1.77 KEY_UP gets the right column
 20171008 1.76 defend against a race condition in line 403
 20170525 1.75 fix bug with nil str in line 222
 20150422 1.74 works with lua 5.3
 20140718 1.73 insure against nil in line 387
 20140607 1.72 switch pod and doc over to using moonrocks
 20131101 1.71 various undeclared global variables declared as local
 20131031      multichoice choose() consistently returns {} if cancelled
 20131019 1.70 check_size() repositioned after fmt(); new_mid_col defined=0
 20131010      calls to absent warn() eliminated; is_executable() redundant
 20131004 1.69 first working version in Lua

=head1 AUTHOR

Peter J Billam www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 bash
 http://search.cpan.org/perldoc?Term::Clui
 http://cpansearch.perl.org/src/PJB/Term-Clui-1.72/py/TermClui.py
 http://www.pjb.com.au/
 http://www.pjb.com.au/comp/index.html#lua
 http://invisible-island.net/xterm/ctlseqs/ctlseqs.html
 http://search.cpan.org/~pjb
 http://luarocks.org/modules/gvvaughan/luaposix
 http://luaposix.github.io/luaposix/docs/
 http://luarocks.org/modules/peterbillam/terminfo
 http://pjb.com.au/comp/lua/terminfo.html
 http://luarocks.org/modules/peterbillam/readkey
 http://pjb.com.au/comp/lua/readkey.html
 http://luarocks.org/modules/peterbillam/readline
 http://pjb.com.au/comp/lua/readline.html
 http://luarocks.org/modules/luarocks/lgdbm
 http://pjb.com.au/comp/lua/lgdbm.html
 http://luarocks.org/modules/luarocks/luabitop
 http://bitop.luajit.org/api.html
 http://luarocks.org/modules/peterbillam/commandlineui

=cut

--]]
