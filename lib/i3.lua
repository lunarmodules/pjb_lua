---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2019, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local I3 = require 'i3'
-- I3.foo()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '29mar2019'

local JSON = require 'lunajson'   -- https://github.com/grafi-tt/lunajson
-- http://lua-users.org/wiki/JsonModules
-- https://www.kyne.com.au/~mark/software/lua-cjson.php ?

------------------------------ private ------------------------------
local function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
local function die(...) warn(...);  os.exit(1) end

local function i3_msg (str)
	local p = assert(io.popen('i3-msg '..str , 'r'))
	local rv = p:read('l') ; p:close()
	return rv
end

------------------------------ public ------------------------------
function M.get_workspaces(fmt)
	local j = i3_msg('-t get_workspaces')
	if fmt == 'raw' then return j else return JSON.decode(j) end
end

function M.get_outputs(fmt)
	local j = i3_msg('-t get_outputs')
	if fmt == 'raw' then return j else return JSON.decode(j) end
end

function M.get_tree(fmt)
	local j = i3_msg('-t get_tree')
	if fmt == 'raw' then return j else return JSON.decode(j) end
end

function M.get_marks(fmt)
	local j = i3_msg('-t get_marks')
	if fmt == 'raw' then return j else return JSON.decode(j) end
end

function M.get_bar_config(fmt)
	local j = i3_msg('-t get_bar_config')
	if fmt == 'raw' then return j else return JSON.decode(j) end
end

function M.get_version(fmt)
	local j = i3_msg('-t get_version')
	if fmt == 'raw' then return j else return JSON.decode(j) end
end

function M.command(content)
	local j = i3_msg(content..' 2>/dev/null')
	local l = JSON.decode(j)
	return l[1]['success'], l[1]
end

return M

--[=[

=pod

=head1 NAME

i3.lua - runs I<i3-msg>, and converts its output to lua

=head1 SYNOPSIS

 local I3 = require 'i3'
 local workspaces     = I3.get_workspaces() 
 -- the 'raw' option returns the json text
 local workspaces_txt = I3.get_workspaces('raw') 
 -- the 'raw' option works also with the following five functions:
 local outputs        = I3.get_outputs() 
 local tree           = I3.get_tree() 
 local marks          = I3.get_marks() 
 local bar_config     = I3.get_bar_config() 
 local version        = I3.get_version() 

 local success, details_table = I3.command('workspace 2')
 -- returns true, { success=true }
 local success, details_table = I3.command('wurkspice 2') -- wrong!
 -- returns false, { success=false, error=(string), input=(string),
 --                  errorposition=(string), parse_error=(boolean) }
 -- where details_table['error'] is your helpful error-message :-)
 -- See:  https://i3wm.org/docs/userguide.html

=head1 DESCRIPTION

This module uses the executable I<i3-msg> to communicate with your
running I<i3> window-manager.
It depends on I<i3-msg>, which should be available wherever I<i3> is installed.
It also depends on the I<lunajson> module, available from I<luarocks.org>

The available commands for the command() function are:

  '[', 'move', 'exec', 'exit', 'restart', 'reload', 'shmlog',
  'debuglog', 'border', 'layout', 'append_layout', 'workspace',
  'focus', 'kill', 'open', 'fullscreen', 'split', 'floating', 'mark',
  'unmark', 'resize', 'rename', 'nop', 'scratchpad', 'mode', 'bar'

followed by their respective arguments. Some examples,

  bar mode invisible
  focus left|right|down|up
  move  left|right|down|up
  resize shrink width 200 px
  split vertical|horizontal

See:

  https://i3wm.org/docs/ipc.html#_sending_messages_to_i3
  less ~/.i3/config

=head1 FUNCTIONS

=over 3

=item I<get_workspaces()> or I<get_workspaces('raw')>

Returns, by default, a lua table describing your workspaces.

If the argument 'raw' is given it returns the raw JSON text
exactly as I<i3-msg> outputs it.

=item I<get_outputs()> or I<get_outputs('raw')>

Returns, by default, a lua table describing your outputs
(your different screens).

If the argument 'raw' is given it returns the raw JSON text
exactly as I<i3-msg> outputs it.

=item I<get_tree()> or I<get_tree('raw')>

Returns, by default, a lua table describing a tree of the whole current
state of what I<i3> is displaying.

If the argument 'raw' is given it returns the raw JSON text
exactly as I<i3-msg> outputs it.

=item I<get_marks()> or I<get_marks('raw')>

Returns, by default, a lua table describing your marks.

If the argument 'raw' is given it returns the raw JSON text
exactly as I<i3-msg> outputs it.

=item I<get_bar_config()> or I<get_bar_config('raw')>

Returns, by default, a lua table describing the bar
at the bottom of the screen.

If the argument 'raw' is given it returns the raw JSON text
exactly as I<i3-msg> outputs it.

=item I<get_version()> or I<get_version('raw')>

Returns, by default, a lua table describing the version of your I<i3>.

If the argument 'raw' is given it returns the raw JSON text
exactly as I<i3-msg> outputs it.

=back

=head1 DOWNLOAD

This module is available at
http://www.pjb.com.au/comp/lua/i3.html

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 https://i3wm.org/docs/userguide.html
 man i3-msg
 man aeson-pretty
 https://github.com/acrisci/i3ipc-lua
 https://github.com/acrisci/i3ipc-python
 https://metacpan.org/pod/AnyEvent::I3
 https://www.kyne.com.au/~mark/software/lua-cjson-manual.html
 http://www.pjb.com.au/


=cut

]=]

