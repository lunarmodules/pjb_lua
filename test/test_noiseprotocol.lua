#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2021, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '27feb2021'
local Synopsis = [[
program_name [options] [filenames]
]]
NP = require 'noiseprotocol'
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

--[=[

=pod

=head1 NAME

program_name - what it does

=head1 SYNOPSIS

 program_name infile > outfile

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

Peter J Billam, https://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 https://pjb.com.au/

=cut

]=]
