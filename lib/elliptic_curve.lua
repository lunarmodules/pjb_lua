---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2020, Peter J Billam      --
--                         pjb.com.au                              --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local EL = require 'elliptic_curve'
-- EL.foo()

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '25feb2020'

------------------------------ private ------------------------------
local function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
local function die(...) warn(...);  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end

local floor     = math.floor
local tointeger = math.tointeger
local RA        = nil -- rational.lua will be required if needed

function gcd (small, big)   -- consult urls.html
	small = tointeger(small)
	big   = tointeger(big)
	if small == big then return small end
	if small > big then small, big = big, small end
	local remainder
	while true do
		remainder = big % small
		if remainder == 0 then return small end
		big = small ; small = remainder
	end
end

function inverse (a, n) -- see urls.html "extended Euclidean algorithm"
	n = tointeger(n) -- if n is not already prime then n and a must be coprime
	-- print('before tointeger, a =', a)
	a = tointeger(a) -- % n
	if a == 1 then return 1 end  -- is its own inverse
	if a == 0 then die('inverse called with a = 0') end
	if a == 0 then return nil, 'inverse called with a = 0' end
--print('1: n='..n..'  a='..a)
	if gcd(a,n)>1 then return nil,tostring(a)..' and '..n..' not coprime' end
	local quotient = {[-1]=1, [0]=1}
	local remainder
	-- local x = {0, 1}
	local x = {0, 1}
	local i = 1 ; while true do
--print('2: n='..n..'  a='..a)
--print('quotient['..tostring(i-2)..'] = '..tostring(quotient[i-2]))
		quotient[i]  = floor(n/a)
		if not x[i] then -- inline i==1 and 1==2 because of quotient[i-2]
			x[i] = x[i-2] - x[i-1] * quotient[i-2]
		end
		remainder = n % a
		-- print('step '..i..' '..n..'÷'..a..'  quotient='..quotient[i]..
		-- ' remainder='..remainder..'   x='..x[i])
		-- if i>1 and remainder == 0 then -- BUG
-- warn('i=',i,', ',n,'÷',a,', q[',i,']=',quotient[i],
-- ', remainder=',remainder,', x[',i,']=',x[i])
		if remainder == 0 then -- BUG
-- warn('  returning ',x[i-1] - x[i] * quotient[i-1])
			return x[i-1] - x[i] * quotient[i-1]
		end
		n = a
		a = remainder
		i = i + 1
	end
end

-- inverse(15,26) ; os.exit()

function mul (a, b, n)
	return (a*b) % n   -- could test for maxint etc
end

function mod_div (i, j, p)
-- print('i='..i..'  j='..j..'  p='..p)
	return mul(i, inverse(j,p), p)
end

function add_gen_modp (a, b, p)
	-- a closure-generator add_gen_modp, because p,a,b rarely change
	-- elliptic equation is y^2 = x^3 + a*x + b
	-- a,b, xp,yp, xq,yq, s, xr,yr all Z/pZ
	-- the integer needed for crypto is the Elliptic Curve Discrete Logarithm
	-- we calculate a Z/pZ gradient, using modular arithmetic
	-- he adopts Z/pZ only from 07:00 onward
	-- at 10:48 he clearly gives points on the curve as xA,yA and xB,yB
	-- and at 11:25 he say a point on the curve is an ordered pair.
	-- see 12:20 for the example! 13:25 "remember, we're computing in mod 17"!
	-- so use mod_div()    20200226 passes first test :-)
	local infty = 'infty'   -- the point at infinity
	return function (xp, yp, xq, yq)   -- (
		if yp == infty then return xq,yq end
		if yq == infty then return xp,yp end
		if xp == xq then
			if yp == yq then   -- same point; use the tangent
				local s  = mod_div((3*xp*xp + a)%p, 2*yp, p)  -- 04:28
				local xr = s*s - 2*xp                     -- 04:40
				local yr = s*(xp-xr) - yp              -- 04:51
				return xr % p, yr % p
			else
				return 0,infty
			end
		end
-- print('yp='..yp,'  yq=',yq)
		local s  = mod_div((yq-yp)%p, (xq-xp)%p, p)
		local xr = s*s - (xp+xq)   -- 03:40
		local yr = s*(xp-xr) - yp  -- 03:43
		return xr % p, yr % p
	end
end

function scalarmul_gen_modp (a, b, p)
	-- a closure-generator add_gen_modp, because p,a,b rarely change
	-- elliptic equation is y^2 = x^3 + a*x + b  mod p
	return function (xp, yp, k)   -- 06:00
		local total_x = xp
		local total_y = yp
		local addfunc = add_gen_modp (a, b, p)
		for i = 2,k do
			total_x, total_y = addfunc(total_x, total_y, xp, yp)
		end
		return total_x, total_y
	end
end

-- The Discrete Logarithm Problem is hard!  07:10
-- The Generator G and its Order            07:43
-- the Order n is the smallest positive integer k such that k*G = infty
-- the Cofactor h is the number of points on the elliptic curve defined by G
-- the Cofactor should be as small as possible, 1 is ideal
-- Domain parameters are { p,a,b,G,n,h }    08:32

function add_gen_real (a, b)
	-- a closure-generator add_gen_real, because a,b rarely change
	-- elliptic equation is y^2 = x^3 + a*x + b
	if 4*a*a*a + 27*b*b == 0 then return nil,
		'4*a^3 + 27*b^2 must not be zero; a='..tostring(a)..' b='..tostring(b)
	end
	local infty = 'infty'   -- the point at infinity. Here, a string
	return function (xp, yp, xq, yq)
		if yp == infty then return xq,yq end
		if yq == infty then return xp,yp end
		if xp == xq then
			if yp == yq then   -- same point; use the tangent
				local s  = ((3*xp*xp) + a) / (2*yp)  -- 04:28
				local xr = s*s - 2*xp                  -- 04:40
				local yr = s*(xp-xr) - yp              -- 04:51
				return xr, yr
			else
				return infty
			end
		end
		local s  = (yq-yp) / (xq-xp)
		local xr = s*s - (xp+xq)
		local yr = s*(xp-xr) - yp
	end
end

function scalarmul_gen_real (a, b)
	-- a closure-generator add_gen_real, because a,b rarely change
	-- elliptic equation is y^2 = x^3 + a*x + b
	if 4*a*a*a + 27*b*b == 0 then return nil,
		'4*a^3 + 27*b^2 must not be zero; a='..tostring(a)..' b='..tostring(b)
	end
	return function (xp, yp, k)   -- 06:00
		local total_x = xp
		local total_y = yp
		local addfunc = add_gen_real (a, b)
		for i = 2,k do
			total_x, total_y = addfunc(total_x, total_y, xp, yp)
		end
		return total_x, total_y
	end
end

function add_gen_rat (a, b)
	-- a closure-generator add_gen_rat, because a,b rarely change
	-- elliptic equation is y^2 = x^3 + a*x + b
	local infty = 'infty'   -- the point at infinity
	return function (xp, yp, xq, yq)
		-- use rational.lua! a,b integer; xp,yp, xq,yq, s, xr,yr all rational
		if yp == infty then return xq,yq end
		if yq == infty then return xp,yp end
		if xp == xq then
			if yp == yq then   -- same point; use the tangent
				local s  = ((3*xp*xp)%p + a) / (2*yp)  -- 04:28
				local xr = s*s - 2*xp                  -- 04:40
				local yr = s*(xp-xr) - yp              -- 04:51
				return xr % p, yr % p
			else
				return 0,infty
			end
		end
		local s  = (yq-yp) / (xq-xp) -- xq,yq are integers so s is rational
		local xr = s*s - (xp+xq)   -- 03:40
		local yr = s*(xp-xr) - yp  -- 03:43
		return xr % p, yr % p
	end
end

function scalarmul_gen_rat (a, b, p)
	-- a closure-generator add_gen_rat, because p,a,b rarely change
	-- elliptic equation is y^2 = x^3 + a*x + b  mod p
	return function (xp, yp, k)   -- 06:00
		local total_x = xp
		local total_y = yp
		local addfunc = add_gen_rat (a, b, p)
		for i = 2,k do
			total_x, total_y = addfunc(total_x, total_y, xp, yp)
		end
		return total_x, total_y
	end
end

------------------------------ public ------------------------------

M.Version = "1.0  for Lua5"
M.VersionDate  = '17feb2020'
M.Synopsis = [[
  local EL = require 'elliptic_curve'
]]

-- the default is Z/pZ
M.add_gen       = add_gen_modp
M.scalarmul_gen = scalarmul_gen_modp

function M.set_numberfield (s)
	-- this is the numberfield of a and b, possibly also of xp,yp, xq,yq
	if     s == 'Q'    or string.find(s, '^rat') then
		if not RA then RA = require 'rational' end
		-- if xp,yp, xq,yq are rational then so is the gradient, and xr,yr
		-- but even if x is rational, y involves srqt and thus must be real!
		M.add_gen       = add_gen_rat
		M.scalarmul_gen = scalarmul_gen_rat
		return true
	elseif s == 'R'    or string.find(s, '^real') then
		M.add_gen       = add_gen_real
		M.scalarmul_gen = scalarmul_gen_real
		return true
	elseif s == 'C'    or string.find(s, '^complex') then
		M.add_gen       = add_gen_complex
		M.scalarmul_gen = scalarmul_gen_complex
		return true
	elseif s == 'Z/pZ' or string.find(s, '^mod') then
		M.add_gen       = add_gen_modp
		M.scalarmul_gen = scalarmul_gen_modp
		return true
	else
		return nil, 'unrecognised numberfield '..tostring(s)
	end
end

return M

--[=[

=pod

=head1 NAME

elliptic.lua - some functions needed by elliptic curves in Z/pZ, R and Q

=head1 SYNOPSIS

 local EL = require 'elliptic'
 EL.set_numbers('Q') -- rational; can also be 'F', 'Z/pZ'

=head1 DESCRIPTION

This module provides some functions needed by elliptic curves
in Z/pZ (modular arithmetic), R (real numbers) and Q (rational numbers)

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
http://pjb.com.au/comp/lua/elliptic.html

=head1 AUTHOR

Peter J Billam, http://pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://pjb.com.au/

=cut

]=]

