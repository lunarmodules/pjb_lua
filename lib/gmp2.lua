---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2020, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local MM = require 'gmp2'
-- MM.foo()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '21feb2020'
gmp = require "gmp"

-- See: /home/ports/lgmp/lgmp.htm
--      http://gmplib.org/manual
-- begging to be added ie: by me :-( ...
--      https://gmplib.org/manual/Rational-Number-Functions.html

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

------------------------------ public ------------------------------

function M.absz(x)
	if type(x) ~= 'userdata' then x = M.newz(x) end
	return x:abs()
end
function M.addz(x,y)
	if type(x) ~= 'userdata' then x = M.newz(x) end
	if type(y) ~= 'userdata' then y = M.newz(y) end
	return x:add(y)
end
function M.gcdz(x,y)   -- greatest common denominator
	if type(x) ~= 'userdata' then x = M.newz(x) end
	if type(y) ~= 'userdata' then y = M.newz(y) end
	return x:gcd(y)
end
function M.cmpz(x,y)   -- if x<y then -1 , if x=y then 0, if x>y then 1
	if type(x) ~= 'userdata' then x = M.newz(x) end
	if type(y) ~= 'userdata' then y = M.newz(y) end
	return x:cmp(y)
end
function M.strz(x, base)   -- convert to string
	if type(x) ~= 'userdata' then x = M.newz(x) end
	return x:get_str(base)
end
function M.lcmz(x,y)   -- lowest common multiple
	if type(x) ~= 'userdata' then x = M.newz(x) end
	if type(y) ~= 'userdata' then y = M.newz(y) end
	return x:lcm(y)
end
function M.modz(x,y)   -- x%y
	if type(x) ~= 'userdata' then x = M.newz(x) end
	if type(y) ~= 'userdata' then y = M.newz(y) end
	return x:mod(y)
end
function M.mulz(x,y)
	if type(x) ~= 'userdata' then x = M.newz(x) end
	if type(y) ~= 'userdata' then y = M.newz(y) end
	return x:mul(y)
end
function M.negz(x)
	if type(x) ~= 'userdata' then x = M.newz(x) end
	return x:neg()
end
function M.newz(x)
	return gmp.z(x)
end
function M.nextprimez(x)
	if type(x) ~= 'userdata' then x = M.newz(x) end
	return x:nextprime()
end
function M.powz(z,a)   -- z^a
	if type(z) ~= 'userdata' then z = M.newz(z) end
	return z:pow(a)
end
function M.powmz(z,a,k)   -- (z^a)%k
	if type(z) ~= 'userdata' then z = M.newz(z) end
	if type(k) ~= 'userdata' then k = M.newz(k) end
	return z:powm(a,k)
end
function M.probab_primez(z, a) -- z is probably a prime? default a=10 tests
	if type(z) ~= 'userdata' then z = M.newz(z) end
	return z:probab_prime(a)
end
function M.setz(x, y)
	if type(x) ~= 'userdata' then x = M.newz(x) end
	if type(y) ~= 'userdata' then y = M.newz(y) end
	x:set(y)
	return true
end
function M.sgnz(x)
	if type(x) ~= 'userdata' then x = M.newz(x) end
	return x:sgn()
end

--[[


> -- returns nothing but sets “self” to new integer value
> =x:set "123456789123456789123456789"
> =x
123456789123456789123456789

--]]

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

return M

--[=[

=pod

=head1 NAME

mymodule.lua - does whatever

=head1 SYNOPSIS

 local M = require 'mymodule'
 a = { 6,8,7,9,8 }
 b = { 4,7,5,4,5,6,4 }
 local probability_of_hypothesis_being_wrong = M.ttest(a,b,'b>a')

=head1 DESCRIPTION

This module does whatever

=head1 FUNCTIONS

=over 3

=item I<ttest(a,b, hypothesis)>

The arguments I<a> and I<b> are arrays of numbers

The I<hypothesis> can be one of 'a>b', 'a<b', 'b>a', 'b<a',
'a~=b' or 'a<b'.

I<ttest> returns the probability of your hypothesis being wrong.

=back

=head1 DOWNLOAD

This module is available at
http://pjb.com.au/comp/lua/mymodule.html

=head1 AUTHOR

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://pjb.com.au/


=cut

]=]
