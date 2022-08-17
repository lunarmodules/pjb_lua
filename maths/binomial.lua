#!/usr/local/bin/lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2019, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- see ~/lua/lib/rational.lua
local Version = '1.0  for Lua5'
local VersionDate  = '12feb2019'
local Synopsis = [[
program_name [options] [filenames]
]]

local function round(x)
    if not x then return nil end
    return math.floor(x+0.5)
end

function factorial (n)
	local f = 1
	for i = 2,n do f = f * i end
	return f
end

-- math.tointeger (x)
--   If the value x is convertible to an integer, returns that integer,
--   otherwise, returns nil.
-- math.type (x)
--   Returns "integer" if x is an integer, "float" if it is a float,
--   or nil if x is not a number. 

function binomial (n, r)  -- 20191014 tweaking for speed and robustness
	if r<0 or r>n then return nil end
	if 2*r > n then r = n - r end
	local b = 1
	local f = factorial (r)
	-- could pick off the factors individually ... slow but robust ...
	local already = false
	for i = n-r+1, n do
		b = b * i
		if b > f and not already then
			b = b / f
			already = true
		end
	end
	return round(b)
end
function binomial2 (n, r)
	if r<1 or r>n then return nil end
	if 2*r > n then r = n - r end
	-- This is slower and fails if n>20
	return round ( factorial(n) / ( factorial(r) * factorial(n-r) ) )
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

--print(factorial(5))
for n = 26,35 do
  print(n, binomial(n,1),binomial(n,2),binomial(n,3),
    binomial(n,5),binomial(n,round(n/2)),
    binomial(n,n-5),binomial(n,n-2),binomial(n,n-1))
end
-- os.exit()

s0 = os.clock()
n = 25
for j = 1, 100000 do
  b1 = binomial(n, 2)
  b1 = binomial(n, 3)
  bX = binomial(n, 4)
  b1 = binomial(n, 5)
  b1 = binomial(n, 6)
  b1 = binomial(n, 7)
  b1 = binomial(n, 8)
  b1 = binomial(n, 9)
end
s1 = os.clock()
print(bX, s1-s0)
for j = 1, 100000 do
  b2 = binomial2(n, 2)
  b2 = binomial2(n, 3)
  bX = binomial2(n, 4)
  b2 = binomial2(n, 5)
  b2 = binomial2(n, 6)
  b2 = binomial2(n, 7)
  b2 = binomial2(n, 8)
  b2 = binomial2(n, 9)
end
s2 = os.clock()
print(bX, s2-s1)


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
