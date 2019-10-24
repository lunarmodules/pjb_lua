---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2017, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '5aug2017'
local AO = require("ao")

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
local function round(x) return math.floor(x+0.5) end
local function abs(x) if x<0 then return 0-x else return x end end

local numeric_version = string.gsub(_VERSION, "^%D+", "")
if tonumber(numeric_version) < 5.2 then
    bit = require 'bit'  -- LuaBitOp http://bitop.luajit.org/api.html
elseif _G.bit32 then
    bit = _G.bit32
else
    local f = load([[
    bit.bor    = function (a,b) return a|b  end
    bit.band   = function (a,b) return a&b  end
    bit.rshift = function (a,n) return a>>n end
    ]])
    f()
end

local device   -- stored internally, but means only one device is allowed
-- and the user might want to play live and to a file at the same time,
-- though with blocking play that's not likely to occur in practice...

AO.BUF_SIZE = 4096
-- AO.initialize()  -- this is done when requiring,
-- but can still be used if you need to restart the environment

function M.open(output_file, fmt)
	-- verbose=0 doesn't work, though see https://git.xiph.org/ adebug()
	-- https://xiph.org/ao/doc/config.html ! In /etc/libao.conf or ~/.libao,
	-- set  quiet=yes  (debug and verbose options seem to have no effect)
	local format = { bits=16; channels=2; rate=44100; byteFormat="little"; }
	if fmt then for k,v in pairs(fmt) do format[k] = v end end
	if output_file then
		if output_file == 'null' then
			M.driverid = AO.driverId('null')
			device = AO.openLive(M.driverid, format)
		else
			local x,output_format = string.match(output_file,'%.(%l%l%l%l?)$')
			if not output_format then output_format = 'wav' end
			M.driverid = AO.driverId(output_format)
			device = AO.openFile(M.driverid, output_file, false, format)
		end
	else
		M.driverid = AO.defaultDriverId()
		device = AO.openLive(M.driverid, format)
	end
	if device then return true
	else return nil,"Error opening "..output_file
	end
end

--function M.default_driver ()   -- only works before the open(),
--	--  and then the open doesn't work :-( 
--	-- couldn't open play stream: Device or resource busy
--	local id = AO.defaultDriverId()
--	print('id =',id)
--	local info = M.driver_info(AO.defaultDriverId())
--	return info['shortName']
--end

function M.driver_info (id)
	return AO.driverInfo(id or M.driverid)
end

function M.driver_info_list()   -- this list is indexed by id
	return AO.driverInfoList()
end

function M.driver_id(shortname)
	return AO.driverId(shortname)
end

function M.add_sample_to_buffer (sample_l, sample_r, buffer, sample_format) 
	-- obviously we also need -1.0...+1.0 float samples ...
	-- but 1 ? or 0 ?  we do need an argument.  could offer signed int
	if not sample_format or sample_format == 'float' then  -- -1.0 .. +1.0
		if sample_l > 1.0 then sample_l = 1.0 end
		if sample_l <-1.0 then sample_l =-1.0 end
		if sample_r > 1.0 then sample_r = 1.0 end
		if sample_r <-1.0 then sample_r =-1.0 end
		sample_l = sample_l*16383 + 16384
		sample_r = sample_r*16383 + 16384
	elseif sample_format == 'unsigned' then
	elseif sample_format == 'signed' then
		sample_l = sample_l + 16384
		sample_r = sample_r + 16384
	else 
		return nil,'add_sample_to_buffer unknown sample_format '..sample_format
	end
	sample_l = round(sample_l)
	sample_r = round(sample_r)
	-- the samples are now unsigned 16-bit integers
	local ibuf = #buffer
	local schar = string.char
    buffer[ibuf+1] = schar(bit.band(sample_l, 0xff))
    buffer[ibuf+2] = schar(bit.band(bit.rshift(sample_l,8), 0xff))
    buffer[ibuf+3] = schar(bit.band(sample_r, 0xff))
    buffer[ibuf+4] = schar(bit.band(bit.rshift(sample_r,8), 0xff))
end

function M.play_buffer (buffer)
	if not device then
		return nil, "play_buffer: you need to call open() first"
	end
	local rv = device:play(table.concat(buffer), #buffer-4)
	if rv then return true
	else return nil, "error plaing buffer"
	end
	-- http://lua-users.org/lists/lua-l/2008-05/msg00490.html
	-- cqueues        https://luarocks.org/modules/daurnimator/cqueues
	--                http://25thandclement.com/~william/projects/cqueues.html
	-- lua-llthreads2 https://github.com/moteus/lua-llthreads2
	-- Lanes          https://luarocks.org/modules/benoitgermain/lanes
	-- copas_async    https://luarocks.org/modules/hisham/copas-async

end

return M

--[=[

=pod

=head1 NAME

aowrapper.lua - wraps the ao luarock module

=head1 SYNOPSIS

 local A = require 'aowrapper'
 A.open()
 for k,v in pairs(A.driver_info()) do  -- driverinfo
    if type(v) == 'table' then
       warn('  ',k," = { '",table.concat(v,"', '"), "' }")
    else
       warn('  ',k,' = ',v)
    end
 end
 local twopi = 2 * math.pi
 local buffer = {}
 for i=1, 44100
    sample = 0.75 * math.sin(twopi * i*262/44100)
    A.add_sample_to_buffer(sample,sample,buffer)
 end
 A.play_buffer(buffer)

=head1 DESCRIPTION

This module offers a slightly more lua-centric interface
to the pure-C 'lao' module

Once you have your program working, you may want to edit
I</etc/libao.conf> or I<~/.libao>, to set I<quiet=yes>

It is hoped that in the future the I<cqueues> module,
or at least Lua I<coroutines>,
could be used to provide an asynchronous
equivalent to I<play_buffer()>

=head1 FUNCTIONS

=over 3

=item I<open( 'filename.wav' )>

If the argument is I<nil>, the output goes live to your default audio output.
The available output-formats can be seen as the I<shortName> fields
in the output of I<driver_info_list()> whose I<type> is "live",
For example on my system they are "pulse", "esd", "sndio","oss" and "nss".

If the argument is the string 'null', the output is thrown away.

Otherwise, the output-format is taken from the filename-extension.
The available output-formats can be seen as the I<shortName> fields
in the output of I<driver_info_list()> whose I<type> is "file".
For example on my system they are "wav", "raw" and "au".

=item I<add_sample_to_buffer( sample_l, sample_r, buffer, sample_format )>

The first two arguments are left and right stereo samples,
in a format specified by I<sample_format>

The third argument I<buffer> must be a predeclared table, eg

 local buffer = {}

If the fourth argument I<sample_format> is present,
it must be one of 'float', 'unsigned', or 'signed'.
'float' means a number between -1.0 and +1.0,
and 'unsigned', 'signed' mean unsigned or signed 16-bit integers.
If I<sample_format> is not given, it defaults to 'float'.

=item I<play_buffer(buffer)>

This plays the data in your buffer to the output-device you have opened.
It only returns after all the audio has been output.

=item I<driver_info()>

This returns a table of information about the driver used by I<open()>.
One of the items, 'options', is an array of the options that have been set.

=item I<driver_info_list()>

This returns an array of tables of information about the available drivers.
The array-index is the I<driverId> that I<libao> uses internally.

=item I<driver_id('wav')>

This example returns the I<driverId> of the driver whose I<shortName> is "wav"

=back

=head1 DOWNLOAD

This module is available at
http://www.pjb.com.au/comp/lua/aowrapper.html

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

The I<libao> C-library, on which the I<lao> lua module depends:

  https://xiph.org/ao/doc/libao-api.html
  https://xiph.org/ao/doc/drivers.html
  https://xiph.org/ao/doc/ao_driver_id.html
  https://xiph.org/ao/doc/config.html
  /etc/libao.conf
  ~/.libao

The I<lao> lua module, on which I<aowrapper> depends:

  http://thelinx.github.io/lao/
  http://thelinx.github.io/lao/install.html
  http://thelinx.github.io/lao/overview.html
  http://thelinx.github.io/lao/reference.html
  http://thelinx.github.io/lao/ao_driver_info_list.html
  http://thelinx.github.io/lao/ao_driver_id.html
  http://thelinx.github.io/lao/ao_default_driver_id.html
  http://thelinx.github.io/lao/ao_driver_info.html
  http://thelinx.github.io/lao/sample_format.html
  http://thelinx.github.io/lao/ao_open_live.html
  http://thelinx.github.io/lao/device_play.html
  http://thelinx.github.io/lao/device_close.html
  https://raw.githubusercontent.com/TheLinx/lao/master/src/ao_example.lua

  https://en.wikipedia.org/wiki/Asynchronous_method_invocation
  http://www.lua.org/manual/5.3/manual.html#2.6   (coroutines)
  https://stackoverflow.com/questions/5128375/what-are-lua-coroutines-even-for-why-doesnt-this-code-work-as-i-expect-it

  http://www.pjb.com.au/

=cut

]=]

