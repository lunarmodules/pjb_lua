#!/usr/local/bin/lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2018, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '27apr2018';
local Synopsis = [[
program_name [options] [filenames]
]]

local MM = require 'midi_markov'
require 'DataDumper'

---------------------------------------------------------------------
local function split(s, pattern, maxNb) -- http://lua-users.org/wiki/SplitJoin
	if not s or string.len(s)<2 then return {s} end
	if not pattern then return {s} end
	if maxNb and maxNb <2 then return {s} end
	local result = { }
	local theStart = 1
	local theSplitStart,theSplitEnd = string.find(s,pattern,theStart)
	local nb = 1
	while theSplitStart do
		table.insert( result, string.sub(s,theStart,theSplitStart-1) )
		theStart = theSplitEnd + 1
		theSplitStart,theSplitEnd = string.find(s,pattern,theStart)
		nb = nb + 1
		if maxNb and nb >= maxNb then break end
	end
	table.insert( result, string.sub(s,theStart,-1) )
	return result
end
function warn(...)
	local a = {}
	for k,v in pairs{...} do table.insert(a, tostring(v)) end
	io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end

local eps = .000000001
function equal(x, y)   -- print('#x='..#x..' #y='..#y)
	if #x ~= #y then return false end
	local i; for i=1,#x do
		if math.abs(x[i]-y[i]) > eps then return false end
	end
	return true
end
local Test = 12 ; local i_test = 0; local Failed = 0;
function ok(b,s)
	i_test = i_test + 1
	if b then
		io.write('ok '..i_test..' - '..s.."\n")
		return true
	else
		io.write('not ok '..i_test..' - '..s.."\n")
		Failed = Failed + 1
		return false
	end
end


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

-- MM.reigning_chord()
local chord = {channels={4,15,0,3},absolute={43,53,59,68}}
local r = MM.absolute2octavised(chord)
if not ok(equal(r['octavised'], {0,10,6,9} ),
  'absolute2octavised {43,53,59,68}') then
	print('returned',DataDumper(r['octavised']))
end
r = MM.incremental2absolute('-1,0,+1,0', chord)
if not ok(equal(r, {42,53,60,68}), 'incremental2absolute -1,0,+1,0') then
	print('r =',DataDumper(r))
end
r = MM.incremental2absolute('-1,0,X,0', chord)
if not ok(equal(r, {42,53,68}), 'incremental2absolute -1,0,X,0') then
	print('r =',DataDumper(r))
end
r = MM.incremental2absolute('-1,0,-1&+1,0', chord)
if not ok(equal(r, {42,53,58,60,68}), 'incremental2absolute -1,0,-1&+1,0') then
	print('r =',DataDumper(r))
end
r = MM.absabs2incremental({43,53,59,68}, {42,53,60,68})
if not ok(r=='-1,0,+1,0','absabs2incremental {43,53,59,68},{42,53,60,68}') then
	print('r =',r)
end

MM.reigning_chord()

--[=[

=pod

=head1 NAME

miditurtle - Reading, writing and manipulating MIDI data

=head1 SYNOPSIS

 miditurtle in.mid out.mid <<EOT
 at 30.7 back 3.2 c3cc74=30
 EOT

=head1 DESCRIPTION

This script

=head1 ARGUMENTS

=over 3

=item I<-v>

Print the Version

=back

=head1 DOWNLOAD

This at is available at

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://www.pjb.com.au/

=cut

]=]
