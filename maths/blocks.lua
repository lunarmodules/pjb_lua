#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2021, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '8may2021'
local Synopsis = [[
  blocks [options] [filenames]
]]
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

function n_blocks (n_unique, n_per_block, n_letters)
	-- see Symmetry and the Monster p. 240
	local numer = n_letters
	for i = 1, n_unique-1 do numer = numer * (n_letters-i) end
	local denom = n_per_block
	for i = 1, n_unique-1 do denom = denom * (n_per_block-i) end
	return math.tointeger( numer / denom )
end

function blocks (n_unique, n_per_block, n_letters)
	local nblocks = n_blocks(n_unique, n_per_block, n_letters)
	if not nblocks then return nil end
	-- eg     (2,3,7) gives (7*6)/(3*2) = 7 blocks
	--       (2,4,13) gives (13*12)/(4*3) = 13 blocks
	-- witt  (5,8,24) gives (24*23*22*21*20)/(8*7*6*5*4) = 759 blocks
end

-- print(n_blocks(2,3,7)) ; print(n_blocks(2,4,13)) ; print(n_blocks(5,8,24))

n_unique = 5 ; n_per_block = 8
print('n_unique = '..tostring(n_unique)..'   n_per_block = '..tostring(n_per_block))
print('possible n_letters and the resulting n_blocks are :')
for n_letters = n_per_block+1, n_per_block+50 do
	local nb = n_blocks(n_unique, n_per_block, n_letters)
	if nb then print ('n_letters = '..tostring(n_letters)..'  n_blocks = '..tostring(nb)) end
end

--[=[

=pod

=head1 NAME

blocks - what it does

=head1 SYNOPSIS

 blocks infile > outfile

=head1 DESCRIPTION

See the blocks as described in "Symmetry and the Monster"
by Mark Ronan pp. 109, 133, 240

Question: why is Witt's (5,8,24) so much more important than other possible
combinations of (n_unique, n_per_block, n_letters) ?

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

 https://en.wikipedia.org/wiki/Leech_lattice
 https://en.wikipedia.org/wiki/Leech_lattice#Constructions
 https://en.wikipedia.org/wiki/Leech_lattice#Witt's_construction
 https://pjb.com.au/

=cut

]=]
