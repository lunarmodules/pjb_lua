#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2020, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '20feb2020'
local Synopsis = [[
program_name [options] [filenames]
]]
G2 = require "gmp2"
local iarg=1; while arg[iarg] ~= nil do
	if not string.find(arg[iarg], '^-[a-z]') then break end
	local first_letter = string.sub(arg[iarg],2,2)
	if first_letter == 'v' then
		print('libgmp version '..gmp.version)
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

-- for k,v in pairs(G2) do print(k,v) end

print('See: lynx /home/ports/lgmp/lgmp.htm')
print('     lynx http://gmplib.org/manual')

local Test = 14 ; local i_test = 0; local Failed = 0;
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

g = G2.powz(1024,3)
if not ok(G2.cmpz(g,1073741824) == 0, 'powz(1024,3) = 1073741824') then
	print(' g = ',G2.strz(g))
end
if not ok(G2.strz(g) == '1073741824', "strz(g) = '1073741824'") then
	print(' g = ',G2.strz(g))
end
-- g = newz(1024) ; x = g:powm(3,newz(1000000))
x = G2.powmz(1024,3,1000000)
if not ok(x:cmp(x,741824) == 0, 'powmz(1024,3,1000000) = 741824') then
	print(' x = ',G2.strz(x))
end

x = G2.nextprimez(1000)
if not ok(G2.cmpz(x,1009) == 0, 'nextprimez(1000) = 1009') then
	print(G2.strz(x))
end

x = G2.nextprimez(15000)
if not ok(G2.cmpz(x,15013) == 0, 'nextprimez(15000) = 15013') then
	print(G2.strz(x))
end

x = G2.nextprimez(25000)
if not ok(G2.cmpz(x,25013) == 0, 'nextprimez(25000) = 25013') then
	print(G2.strz(x))
end

if not ok(G2.sgnz(-3579) == -1, 'sgnz(-3579) == -1') then
	print(G2.sgnz(-3579))
end
if not ok(G2.sgnz(0) == 0, 'sgnz(0) == 0') then
	print(G2.sgnz(0))
end
if not ok(G2.sgnz(3579) == 1, 'sgnz(3579) == 1') then
	print(G2.sgnz(3579))
end
if not ok(G2.negz(3579):cmp(-3579) == 0, 'negz(3579) == -3579') then
	print(G2.negz(3579))
end
if not ok(G2.probab_primez(1008)==false,'probab_primez(1008) returns false') then
	print(G2.probab_primez(1008))
end
if not ok(G2.probab_primez(1009) == 2, 'probab_primez(1009) returns 2') then
	print(G2.probab_primez(1009))
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

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://pjb.com.au/

=cut

]=]
