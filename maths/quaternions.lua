#!/usr/bin/env lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2022, Peter J Billam      --
--                         pjb.com.au                              --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.0  for Lua5'
local VersionDate  = '23apr2022'
local Synopsis = [[
quaternions [options] [filenames]
]]
local function printf (...) io.stdout:write(string.format(...)) end
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
if arg[iarg] then F = assert(io.open(arg[iarg], 'r')) else F = io.stdin end
-- c = {utf8.codepoint(F:read('a'),1,-1)}

local function printf (...) print(string.format(...)) end
local format = string.format
local function fmt_plu_min (x)
	if x < 0 then return format('%g',x)
	else return format('+%g',x) end
end
function qprint (q)
	printf('%s%si%sj%sk',
	  fmt_plu_min(q[1]),fmt_plu_min(q[2]),fmt_plu_min(q[3]),fmt_plu_min(q[4])
	)
end
function conjugate (q)
	return {q[1], 0-q[2], 0-q[3], 0-q[4]}
end
function add (q1,q2)
	return {q1[1]+q2[1], q1[2]+q2[2], q1[3]+q2[3], q1[4]+q2[4]}
end
function neg (q)
	return {0-q[1], 0-q[2], 0-q[3], 0-q[4]}
end
function mul(q1,q2)
	-- https://en.wikipedia.org/wiki/Quaternion#Hamilton_product
	local a1=q1[1] ; local b1=q1[2] ; local c1=q1[3] ; local d1=q1[4]
	local a2=q2[1] ; local b2=q2[2] ; local c2=q2[3] ; local d2=q2[4]
	return {
		a1*a2 - b1*b2 - c1*c2 - d1*d2,
		a1*b2 + b1*a2 + c1*d2 - d1*c2,
		a1*c2 - b1*d2 + c1*a2 + d1*b2,
		a1*d2 + b1*c2 - c1*b2 + d1*a2
	}
end
function norm(q)
	return math.sqrt(q[1]^2 + q[2]^2 + q[3]^2 + q[4]^2)
end
function reciprocal (q)
	local norm2 = norm(q)^2
	local conjq = conjugate(q)
	return {conjq[1]/norm2, conjq[2]/norm2, conjq[3]/norm2, conjq[4]/norm2}
end

q1 = { 1,2,3,4 }   -- meaning 1 + 2*i + 3*j + 4*k
q2 = { 5,6,7,8 }
one = {1,0,0,0}

qprint(q2)
qprint(conjugate(q2))
qprint(add(q1,q2))
qprint(neg(q1))
qprint(one)
print(norm(one))
qprint(mul(one, q1))
qprint(mul(q1, q2))
print(norm(mul(q1, q2)))
print(norm(q1)*norm(q2))
qprint(reciprocal(q1))
qprint(mul(q1, reciprocal(q1)))
print(norm(mul(q1, reciprocal(q1))))

--[=[

=pod

=head1 NAME

quaternions - what it does

=head1 SYNOPSIS

 quaternions infile > outfile

=head1 DESCRIPTION

\mathbb {H} is unicode U+210D which in utf8 is e2 84 8d = '\242\132\141'

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

 https://en.wikipedia.org/wiki/Quaternion
 https://en.wikipedia.org/wiki/Quaternion#Hamilton_product
 https://en.wikipedia.org/wiki/Blackboard_bold
 https://pjb.com.au/

=cut

]=]
