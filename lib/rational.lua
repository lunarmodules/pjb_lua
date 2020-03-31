-- ----------------------------------------------------------------- --
--      This Lua5 module is Copyright (c) 2010, Peter J Billam       --
--                        www.pjb.com.au                             --
--                                                                   --
--   This module is free software; you can redistribute it and/or    --
--          modify it under the same terms as Lua5 itself.           --
-- ----------------------------------------------------------------- --
-- to do: binomial (n,r)   must extend to non-integer n ! p.78
local M = {} -- public interface
M.Version = 'VERSION'
M.VersionDate = 'DATESTAMP'

--------------------- infrastructure ----------------------
local function warn(str)
    io.stderr:write(str,'\n')
end
local function die(str)
	io.stderr:write(str,'\n')
	os.exit(1)
end
local function round(x)
	if not x then return nil end
	return math.floor(x+0.5)
end

-- https://en.wikipedia.org/wiki/List_of_prime_numbers
Primes = {
2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71, 73,79,83,89,97,
101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,
179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,
263,269,271,277,281,283,293,307,311,313,317,331,337,347,349,
353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,
443,449,457,461,463,467,479,487,491,499,503,509,521,523,541,
547,557,563,569,571,577,587,593,599,601,607,613,617,619,631,
641,643,647,653,659,661,673,677,683,691,701,709,719,727,733,
739,743,751,757,761,769,773,787,797,809,811,821,823,827,829,
839,853,857,859,863,877,881,883,887,907,911,919,929,937,941,
947,953,967,971,977,983,991,997,1009,1013,
1019, 1021,1031,1033,1039,1049,1051,1061,1063,1069,
1087,1091,1093,1097,1103,1109,1117,1123,1129,1151,
1153,1163,1171,1181,1187,1193,1201,1213,1217,1223,
1229,1231,1237,1249,1259,1277,1279,1283,1289,1291,
1297,1301,1303,1307,1319,1321,1327,1361,1367,1373,
1381,1399,1409,1423,1427,1429,1433,1439,1447,1451,
1453,1459,1471,1481,1483,1487,1489,1493,1499,1511,
1523,1531,1543,1549,1553,1559,1567,1571,1579,1583,
1597,1601,1607,1609,1613,1619,1621,1627,1637,1657,
1663,1667,1669,1693,1697,1699,1709,1721,1723,1733,
1741,1747,1753,1759,1777,1783,1787,1789,1801,1811,
1823,1831,1847,1861,1867,1871,1873,1877,1879,1889,
1901,1907,1913,1931,1933,1949,1951,1973,1979,1987,
1993,1997,1999,2003,2011,2017,2027,2029,2039,2053,
2063,2069,2081,2083,2087,2089,2099,2111,2113,2129,
2131,2137,2141,2143,2153,2161,2179,2203,2207,2213,
2221,2237,2239,2243,2251,2267,2269,2273,2281,2287,
2293,2297,2309,2311,2333,2339,2341,2347,2351,2357,
2371,2377,2381,2383,2389,2393,2399,2411,2417,2423,
2437,2441,2447,2459,2467,2473,2477,2503,2521,2531,
2539,2543,2549,2551,2557,2579,2591,2593,2609,2617,
2621,2633,2647,2657,2659,2663,2671,2677,2683,2687,
2689,2693,2699,2707,2711,2713,2719,2729,2731,2741,
2749,2753,2767,2777,2789,2791,2797,2801,2803,2819,
2833,2837,2843,2851,2857,2861,2879,2887,2897,2903,
2909,2917,2927,2939,2953,2957,2963,2969,2971,2999,
3001,3011,3019,3023,3037,3041,3049,3061,3067,3079,
3083,3089,3109,3119,3121,3137,3163,3167,3169,3181,
3187,3191,3203,3209,3217,3221,3229,3251,3253,3257,
3259,3271,3299,3301,3307,3313,3319,3323,3329,3331,
3343,3347,3359,3361,3371,3373,3389,3391,3407,3413,
3433,3449,3457,3461,3463,3467,3469,3491,3499,3511,
3517,3527,3529,3533,3539,3541,3547,3557,3559,3571,
3581,3583,3593,3607,3613,3617,3623,3631,3637,3643,
3659,3671,3673,3677,3691,3697,3701,3709,3719,3727,
3733,3739,3761,3767,3769,3779,3793,3797,3803,3821,
3823,3833,3847,3851,3853,3863,3877,3881,3889,3907,
3911,3917,3919,3923,3929,3931,3943,3947,3967,3989,
4001,4003,4007,4013,4019,4021,4027,4049,4051,4057,
4073,4079,4091,4093,4099,4111,4127,4129,4133,4139,
4153,4157,4159,4177,4201,4211,4217,4219,4229,4231,
4241,4243,4253,4259,4261,4271,4273,4283,4289,4297,
4327,4337,4339,4349,4357,4363,4373,4391,4397,4409,
4421,4423,4441,4447,4451,4457,4463,4481,4483,4493,
4507,4513,4517,4519,4523,4547,4549,4561,4567,4583,
4591,4597,4603,4621,4637,4639,4643,4649,4651,4657,
4663,4673,4679,4691,4703,4721,4723,4729,4733,4751,
4759,4783,4787,4789,4793,4799,4801,4813,4817,4831,
4861,4871,4877,4889,4903,4909,4919,4931,4933,4937,
4943,4951,4957,4967,4969,4973,4987,4993,4999,5003,
5009,5011,5021,5023,5039,5051,5059,5077,5081,5087,
5099,5101,5107,5113,5119,5147,5153,5167,5171,5179,
5189,5197,5209,5227,5231,5233,5237,5261,5273,5279,
5281,5297,5303,5309,5323,5333,5347,5351,5381,5387,
5393,5399,5407,5413,5417,5419,5431,5437,5441,5443,
5449,5471,5477,5479,5483,5501,5503,5507,5519,5521,
5527,5531,5557,5563,5569,5573,5581,5591,5623,5639,
5641,5647,5651,5653,5657,5659,5669,5683,5689,5693,
5701,5711,5717,5737,5741,5743,5749,5779,5783,5791,
5801,5807,5813,5821,5827,5839,5843,5849,5851,5857,
5861,5867,5869,5879,5881,5897,5903,5923,5927,5939,
5953,5981,5987,6007,6011,6029,6037,6043,6047,6053,
6067,6073,6079,6089,6091,6101,6113,6121,6131,6133,
6143,6151,6163,6173,6197,6199,6203,6211,6217,6221,
6229,6247,6257,6263,6269,6271,6277,6287,6299,6301,
6311,6317,6323,6329,6337,6343,6353,6359,6361,6367,
6373,6379,6389,6397,6421,6427,6449,6451,6469,6473,
6481,6491,6521,6529,6547,6551,6553,6563,6569,6571,
6577,6581,6599,6607,6619,6637,6653,6659,6661,6673,
6679,6689,6691,6701,6703,6709,6719,6733,6737,6761,
6763,6779,6781,6791,6793,6803,6823,6827,6829,6833,
6841,6857,6863,6869,6871,6883,6899,6907,6911,6917,
6947,6949,6959,6961,6967,6971,6977,6983,6991,6997,
7001,7013,7019,7027,7039,7043,7057,7069,7079,7103,
7109,7121,7127,7129,7151,7159,7177,7187,7193,7207,
7211,7213,7219,7229,7237,7243,7247,7253,7283,7297,
7307,7309,7321,7331,7333,7349,7351,7369,7393,7411,
7417,7433,7451,7457,7459,7477,7481,7487,7489,7499,
7507,7517,7523,7529,7537,7541,7547,7549,7559,7561,
7573,7577,7583,7589,7591,7603,7607,7621,7639,7643,
7649,7669,7673,7681,7687,7691,7699,7703,7717,7723,
7727,7741,7753,7757,7759,7789,7793,7817,7823,7829,
7841,7853,7867,7873,7877,7879,7883,7901,7907,7919,
7927,7933,7937,7949,7951,7963,7993,8009,8011,8017,8039,8053,8059,8069,
8081,8087,8089,8093,8101,8111,8117,8123,8147,8161,8167,8171,8179,8191,
8209,8219,8221,8231,8233,8237,8243,8263,8269,8273,8287,8291,8293,8297,
8311,8317,8329,8353,8363,8369,8377,8387,8389,8419,8423,8429,8431,8443,
8447,8461,8467,8501,8513,8521,8527,8537,8539,8543,8563,8573,8581,8597,
8599,8609,8623,8627,8629,8641,8647,8663,8669,8677,8681,8689,8693,8699,
8707,8713,8719,8731,8737,8741,8747,8753,8761,8779,8783,8803,8807,8819,
8821,8831,8837,8839,8849,8861,8863,8867,8887,8893,8923,8929,8933,8941,
8951,8963,8969,8971,8999,9001,9007,9011,9013,9029,9041,9043,9049,9059,
9067,9091,9103,9109,9127,9133,9137,9151,9157,9161,9173,9181,9187,9199,
9203,9209,9221,9227,9239,9241,9257,9277,9281,9283,9293,9311,9319,9323,
9337,9341,9343,9349,9371,9377,9391,9397,9403,9413,9419,9421,9431,9433,
9437,9439,9461,9463,9467,9473,9479,9491,9497,9511,9521,9533,9539,9547,
9551,9587,9601,9613,9619,9623,9629,9631,9643,9649,9661,9677,9679,9689,
9697,9719,9721,9733,9739,9743,9749,9767,9769,9781,9787,9791,9803,9811,
9817,9829,9833,9839,9851,9857,9859,9871,9883,9887,9901,9907,9923,9929,
9931,9941,9949,9967,9973,
}

-- for i = 10001, 20001, 2 do
--     if is_prime(i) then print (i) end
-- end 

-- negative numbers ? how to interpret {-1,1,2} ?
-- and perhaps I should only use the numer,denom format internally ?

BernouilliNums = {
	[0] = 1, [1]={-1,2}, [2]={1,6},
	[4]={-1,30}, [6]={1,42}, [8]={-1,30}, [10]={5,66},
}

local function tab2numden (rat)
	if type(rat) == 'number' then return round(rat), 1  end
	if type(rat) ~= 'table' then
		return nil,'argument must be a table, not a '..type(rat)
	end
	local numer, denom
	if #rat == 3 then numer = rat[2] + rat[1]*rat[3] ; denom = rat[3]
	elseif #rat == 2 then numer = rat[1] ; denom = rat[2]
	else return nil, 'table argument size was '..tostring(#rat)
	end
	if denom == 0 then return nil, 'denominator must not be zero' end
	return numer, denom
end

local function tab2intnumden (rat)
	if type(rat) == 'number' then return rat, 0, 1  end
	if type(rat) ~= 'table' then
		return nil,'argument must be a table, not a '..type(rat)
	end
	local integ = 0
	local numer, denom
	if #rat == 3 then integ = rat[1] ; numer = rat[2] ; denom = rat[3]
	elseif #rat == 2 then numer = rat[1] ; denom = rat[2]
	else return nil, 'table argument size was '..tostring(#rat)
	end
	if denom == 0 then return nil, 'denominator must not be zero' end
	return integ, numer, denom
end

local tointeger = math.tointeger or round
local function gcd (small, big) -- see ~/lua/modular_arithmetic/urls.html
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

------------------------ EXPORT stuff ---------------------------

function M.is_prime (n)
	for i,p in ipairs(Primes) do
		if n%p == 0 then return false end
		if p*p > n then return true end
	end
	return nil, "sorry, can't test numbers as big as "..tostring(n)
end

function M.factorial (n)
	local f = 1
	for i = 2,n do f = f * i end
	return f
end

-- math.tointeger (x)
-- If the value x is convertible to an integer, returns that integer.
-- Otherwise, returns nil.
-- math.type (x)
-- Returns "integer" if x is an integer, "float" if it is a float,
-- or nil if x is not a number. 

function M.binomial (n, r)   -- 20191014 tweaking for speed and robustness
	-- http://mathworld.wolfram.com/BinomialNumber.html
	-- 20191018 extended to allow float or rational n, see A&G p.78
	if r == 0 then return 1 end
	if type(n) == 'table' then
		if n[2] == 1 then n = n[1]  end
	end
	if type(n) == 'table' then          -- n is a rational number
		local product = {1,1}
		for i = 1, r do
			product = M.mul( product, M.div(M.sub(n, {i-1,1}), {i,1}) )
		end
		return product
	end
	if r<0 or r>n then return nil end
	if math.type(n) == 'float' then     -- n is a float
		local product = 1.0
		for i = 1, r do
			product = product * (n - (1.0 * (i - 1))) / i
		end
		return 1.0 * product
	end
	if math.type(n) == 'integer' then   -- n is an integer
		if 2*r > n then r = n - r end
		local numerators = {}
		for i = 0, r-1 do numerators[i+1] = n - i end
		local couldnt_be_found = 1
		for denominator = r, 1, -1 do  -- cancel
			local found = false
			for j = 1,#numerators do
				if numerators[j] % denominator == 0 then
					local ratio =  round(numerators[j] / denominator)
					numerators[j] = round(numerators[j] / denominator)
					numerators[j] = ratio
					found = true
					break
				end
			end
			if not found then
				couldnt_be_found = couldnt_be_found * denominator
			end
		end
		local product = 1
		for j = 1,#numerators do
			if product > math.maxinteger / numerators[j] then
				print('product is too big ! j =',j,' product =',product)
			end
			product = product * numerators[j]
		end
		return round(product / couldnt_be_found)
	else
		warn('binomial(n,r): n was a '..type(n))
	end
--    	if 2*r > n then r = n - r end
--		local b = 1
--		local f = M.factorial (r)
--		local already = false
--		for i = n-r+1, n do
--			if b > math.maxinteger/i then print('b*1 is too big ! i =',i) end
--			b = b * i   -- could check that b < (math.maxinteger / i)
--			if b > f and not already then
--				b = b / f
--				already = true
--			end
--		end
--		return round(b)
-- return round( M.factorial(n)/(M.factorial(r)*M.factorial(n-r)) )
end

-- \frac{te^{tx}}{e^t - 1} = \sum_{k=0}^{intfy} B_k(x) \frac{t^k}{f!}  p.60
-- see p.103 for a connection with the zeta function !
function M.bernoulli_num(km1)  -- argument is mk1, following eq.6.8 p.65
	if BernouilliNums[km1] then return BernouilliNums[km1] end
	if km1%2 == 1 then return {0,1} end
	-- if km1 == 0 then return {1,1} end
	-- if km1 == 1 then return {-1,2} end
	-- see Ash and Gross 'Summing It Up' p.65 eq.6.8
	local k = km1 + 1
	local rhs = {1,1}
	for i = 1, k-2 do
		rhs = M.add(rhs, M.mul(M.binomial(k,i), M.bernoulli_num(i)))
	end
	local b = M.neg(M.div(rhs, {k,1}))
	BernouilliNums[km1] = b
	return b
end
function M.bernoulli_poly(k,x)
	-- https://en.wikipedia.org/wiki/Bernoulli_polynomials
	local sum = x^k
	for i = 1,k-1 do  -- p.64
		sum = sum + (M.binomial(k,i)*M.rat2float(M.bernoulli_num(i))*x^(k-i))
	end
	return sum + M.rat2float(M.bernoulli_num(k))
end
function M.polygonal_num(k, n)  -- the n't k-agonal number
	-- pp.47,109  https://en.wikipedia.org/wiki/Polygonal_number
	return round((n*(k-2) - (k-4)) * n / 2)
end

function M.cancel(rat)
	local integ, numer, denom = tab2intnumden(rat)
	if not integ then return nil, 'cancel: '..numer end
	-- print(index,numer,denom)
	if numer == 0 then return { integ, 0, 1 } end
	local lesser, greater
	if denom == numer then
	   denom = 1 ; numer = 1
	else
		if numer < denom then
			lesser = numer ; greater = denom
		else   -- denom < numer
			lesser = denom ; greater = numer
		end
		-- deduplicate this block by working with lesser and greater
		if greater%lesser == 0 then  -- BUT lesser might be zero, eg: 0/1
			greater = round(greater / lesser)
			lesser = 1
		else
			local biggest_p = math.abs(lesser)
			for i,p in ipairs(Primes) do
				if p > biggest_p then break end
				while true do
					local found = false
					if lesser%p == 0 and greater%p == 0  then
							found = true
							lesser  = round(lesser  / p)
							greater = round(greater / p)
					end
					if not found then break end  -- try the next prime
				end
				if i == #Primes then -- invoke cancel2 to finish the job
					return M.cancel2({ numer, denom })   -- 20200222
				end
			end
		end
		if numer < denom then
			numer = lesser ; denom = greater
		else   -- denom < numer
			denom = lesser ; numer = greater
		end
		-- if integ ~= 0, we might reduce numer and increment integ ...
	end
	if denom < 0 then numer = 0-numer ; denom = 0-denom end  -- 20200222
	if integ == 0 then return { numer, denom }
	else return { integ, numer, denom }  -- should integerise this
	end
end
function M.cancel2(rat)  -- uses the euclidian algorithm
	-- 20200220 surprisingly, it's slower; but it sees larger factors.
	local numer, denom = tab2numden(rat)
	local is_positive = true
	if numer < 0 then numer = 0-numer ; is_positive = false end
	if denom < 0 then denom = 0-denom ; is_positive = not is_positive end
	local g = gcd(numer,denom)
	if is_positive then
		return { round(numer/g), round(denom/g) }
	else
		return { 0-round(numer/g), round(denom/g) }
	end
end

function M.add(...)
	local sumnumer = 0
	local sumdenom = 1
	for i,rat in ipairs({...}) do
		local numer, denom = tab2numden(rat)
		sumnumer = sumnumer*denom + numer*sumdenom
		sumdenom = sumdenom * denom
	end
	return M.cancel({ sumnumer, sumdenom })
end

function M.sub(a, b)  -- a-b
	return M.add(a, M.neg(b))
end

function M.mul(...)
	local prodnumer = 1
	local proddenom = 1
	for i,rat in ipairs({...}) do
		local numer, denom = tab2numden(rat)
		proddenom = proddenom * denom
		prodnumer = prodnumer*numer
	end
	return M.cancel({ prodnumer, proddenom })
end

function M.inv(rat)  -- inverse
	local numer, denom = tab2numden(rat)
	if numer==0 then return nil, "inv: can't find the inverse of zero" end
	return M.cancel({ denom, numer })
end

function M.div(a,b)  -- a/b
	return M.mul(a, M.inv(b))
end

function M.neg(rat)  -- -rat
	local numer, denom = tab2numden(rat)
	return { 0-numer, denom }
end

function M.eq(rat1, rat2)  -- -rat
	rat1 = M.cancel(rat1)
	rat2 = M.cancel(rat2)
	local numer1, denom1 = tab2numden(rat1)
	local numer2, denom2 = tab2numden(rat2)
	if numer1==numer2 and denom1==denom2 then return true end
	return false
end

function M.integerise(rat)   -- converts 3/2 to 1 1/2 - but -3/2 ?
	local integ, numer, denom = tab2intnumden(rat)
	if not integ then return nil, 'integerise: '..numer end
end

function M.fractionise(rat)   -- converts 1 1/2 to 3/2 - but -1,1,2 ?
	local integ, numer, denom = tab2intnumden(rat)
	if not integ then return nil, 'fractionise: '..numer end
end

function M.rat2float(rat)  -- converts {1,1,2} to 1.5
	local integ, numer, denom = tab2intnumden(rat)
	if not integ then return nil, 'rat2float: '..numer end
	return integ + numer/denom
end

function M.rat2latek(rat)
	local integ, numer, denom = tab2intnumden(rat)
	if integ == 0 then
		return string.format('\\frac{%d}{%d}', numer, denom)
	else
		return string.format('%d \\frac{%d}{%d}', integ, numer, denom)
	end
end

function M.mat2x2mul (j,k) -- only handles 2x2 matrices ! aimed at SL2(Z)
-- a b    1 2   see p.139-146
-- c d    3 4
	return( { j[1]*k[1]+j[2]*k[3], j[1]*k[2]+j[2]*k[4],
              j[3]*k[1]+j[4]*k[3], j[3]*k[2]+j[4]*k[4] } )
end

function M.mat2x2det (j)   -- only handles 2x2 matrices ! aimed at SL2(Z)
	return( j[1]*j[4] - j[2]*j[3] )
end

function M.mat2x2inv (j)   -- only handles 2x2 matrices ! aimed at SL2(Z)
	local det = M.mat2x2det (j)  -- p.140
	return( { j[4]/det, (0-j[2])/det, (0-j[3])/det, j[1]/det } )
end

-- could also do gamma(matrix, z) p.149,155 but this needs complex numbers
-- likewise the Eisenstein series p.167-169
-- complex numbers are arrays with 2 elements, just like rationals :-(

return M

--[[

=pod

=head1 NAME

rational.lua - Rational arithmetic

=head1 SYNOPSIS

 local RA = require 'rational'

=head1 DESCRIPTION

These routines implement rational arithemtic operations,
operating on numbers that are the ratio of whole numbers.

A rational number is normally expressed as a table,
whose elements are integers.
If the table has one element, it is considered to be an integer.
All functions convert integers to their corresponding one-element tables.

If the table has two elements, the number is taken to be their ratio.
For example 22/7 is expressed as {22,7}

If the table has three elements, the number is taken to be the first element
plus the ratio of the second and third elements.
For example 22/7 can also be expressed as {3,1,7}

The routines are all motivated by "Summing it Up" by Ash and Gross.

Version 1.18

=head1 FUNCTIONS

=over 3

=item I<is_prime>(n)

The argument I<n> is a whole number.

=head1 MATHEMATICS

There exist linear transformations converting
between Logical Convolution and the normal Arithmetic Convolution,
and between the Walsh Power Spectrum and the normal Fourier Power Spectrum.

=head1 INSTALLATION



=head1 AUTHOR

Peter J Billam, www.pjb.com.au/comp/contact.html

=head1 REFERENCES

Hi.

=head1 SEE ALSO

 http://www.pjb.com.au/
 http://www.pjb.com.au/comp/lua/WalshTransform.html
 http://search.cpan.org/perldoc?Math::WalshTransform
 Math::Evol    http://search.cpan.org/perldoc?Math::Evol
 Term::Clui    http://search.cpan.org/perldoc?Term::Clui
 Crypt::Tea_JS http://search.cpan.org/perldoc?Crypt::Tea_JS
 http://en.wikipedia.org/wiki/Thue-Morse_sequence
 http://mathworld.wolfram.com/WalshTransform.html
 http://arxiv.org/abs/nlin/0510009
 http://arxiv.org/abs/cs/0703057
 perl(1).

]]
