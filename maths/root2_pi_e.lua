#!/usr/local/bin/lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2019, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '12feb2019'
local Synopsis = [[
root_two [options] [filenames]
]]

local function abs(x) if x<0 then return 0-x else return x end end

local function round(x)
    if not x then return nil end
    return math.floor(x+0.5)
end

local function printf (...) print(string.format(...)) end

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

root2 = math.sqrt(2.0)
i = 5
smallest_err = 1.0
while true do
	local j = round(i * root2)
	result = j*j / (i*i)
	local err = abs(2.0 - result)
	if err < smallest_err then
		printf('%4d / %3d squared %f', j, i, result)
		smallest_err = err
	end
	i = i + 1 ; if i > 10000 then break end
end
print()

i = 7
smallest_err = 1.0
while true do
    local j = round(i * math.pi)
    result = j / i
    local err = abs(math.pi - result)
    if err < smallest_err then
        printf('%4d / %3d gives %f', j, i, result)
        smallest_err = err
    end
    i = i + 1 ; if i > 10000 then break end
end
print()

i = 7
local e = math.exp(1.0)
smallest_err = 1.0
while true do
    local j = round(i * e)
    result = j / i
    local err = abs(e - result)
    if err < smallest_err then
        printf('%4d / %3d gives %f', j, i, result)
        smallest_err = err
    end
    i = i + 1 ; if i > 1000 then break end
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

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://www.pjb.com.au/

=cut

]=]
