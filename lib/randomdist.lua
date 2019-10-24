---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2017, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- https://en.wikipedia.org/wiki/Brownian_noise
-- https://en.wikipedia.org/wiki/Pink_noise
-- There are no simple mathematical models to create pink noise. Although
-- self-organised criticality has been able to reproduce pink noise in
-- sandpile models, these do not have a Gaussian distribution or other
-- expected statistical qualities.[27][28] It is usually generated by
-- filtering white noise[29][30][31] or inverse Fourier transform.[32}
-- 27 Milotti, Edoardo (2002-04-12). "1/f noise: a pedagogical review".
--   Bibcode:2002physics...4033M. arXiv:physics/0204033 Freely accessible.
--   https://arxiv.org/abs/physics/0204033   ~/sci/2002_pink_noise_milotti.pdf
-- 28 O’Brien, Kevin P.; Weissman, M. B. (1992-10-01). "Statistical signatures
--   of self-organization". Physical Review A. 46 (8): R4475–R4478.
--   Bibcode:1992PhRvA..46.4475O. doi:10.1103/PhysRevA.46.R4475.
-- 28 "Noise in Man-generated Images and Sound". mlab.uiah.fi. Retrieved
--   2015-11-14.
-- 30 "DSP Generation of Pink Noise". www.firstpr.com.au. Retrieved 2015-11-14.
-- 31 McClain, D (May 1, 2001). "Numerical Simulation of Pink Noise" (PDF).
--   Preprint. Archived from the original (PDF) on 2011-10-04.
-- 32 Timmer, J.; König, M. (1995-01-01). "On Generating Power Law Noise".
--   Astronomy and Astrophysics. 300: 707–710. Bibcode:1995A&A...300..707T.
-- http://linkage.rockefeller.edu/wli/1fnoise    -- no longer there :-(

local M = {} -- public interface
M.Version = '1.5'   -- add wordcount2zipf
M.VersionDate = '24jul2018'

------------------------------ private ------------------------------
function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),' ') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end
function qw(s)  -- t = qw[[ foo  bar  baz ]]
    local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end

------------------------------ public ------------------------------
-- http://www.design.caltech.edu/erik/Misc/Gaussian.html
-- The polar form of the Box-Muller transformation is faster and more robust:
--   float x1, x2, w, y1, y2;
--   do {
--      x1 = 2.0 * ranf() - 1.0;
--      x2 = 2.0 * ranf() - 1.0;
--      w = x1 * x1 + x2 * x2;
--   } while ( w >= 1.0 );
--   w = sqrt( (-2.0 * log( w ) ) / w );
--   y1 = x1 * w;
--   y2 = x2 * w;
-- where ranf() obtains a random number uniformly distributed in [0,1]
function M.new_grand (mean,stddev)
	local already = false
	local x1, x2, y1, y2
	return function (arg)
		if arg and type(arg) == 'string' and arg == 'reset' then
			already = false ; return nil
		end
		if already then already = false ; return mean + stddev*y2  end
		local w
		while true do
			x1 = 2.0*math.random() - 1.0
			x2 = 2.0*math.random() - 1.0
			w  = x1*x1 + x2*x2
			if w <= 1.0 then  break end
		end
		w  = math.sqrt( -2.0*math.log(w) / w )
		y1 = x1 * w
		y2 = x2 * w
		already = true
		return mean + stddev*y1
	end
end

function M.new_gue_irand (av)
    -- from av, we put together a sufficient array of probabilites
    -- of the various integers around av
	local pi  = math.pi
	local sin = math.sin
	local e   = 2.718281828
    local cumul = {}
    cumul[0] = 0
    for is = 1, math.floor(4*av + 0.5) do
        local s = is / av
        cumul[is] = cumul[is-1] + (32 / pi^2) * s^2 * e^((-4/pi) * s^2) / av
    end
    return function ()
        -- use math.random() to choose one of those integers ...
        local ran = math.random()   -- 0..1
        for i in ipairs(cumul) do
            if cumul[i] > ran then return i end
        end
        return #cumul   -- just in case ran is extremely close to 1.0
    end
end

function M.randomget(a)
	return a[ math.random(#a) ]
end

function M.randomgetn(arr_in, n)
	local arr = {}
	for i = 1,#arr_in do arr[i] = arr_in[i] end
	if n > #arr then return arr end  -- 1.3 allows n==#arr meaning shuffle
	local arr_out = {}
	for i = 1,n do
		local j = math.random(#arr)
		arr_out[i] = arr[j]
		table.remove(arr,j)
	end
	return arr_out
end

function M.rayleigh_rand(sigma)
	return sigma * math.sqrt( -2 * math.log(1-math.random()) )
end

function M.new_zipf (a, s)  -- https://en.wikipedia.org/wiki/Zipf%27s_law
	-- ALERT: but Manfred Schroeder, in Fractals, Chaos and Power Laws
	-- gives   f(k) = 1 (k*log(1.78*N))
	-- where k is the rank, and N is the total number of different words.
	-- This look different - but it's just an approxinmation to H_{m,s}

	-- BUT:  https://en.wikipedia.org/wiki/Zipf%27s_law
	-- says    f(k) = (1 / k^s) / H_{N,s}
	-- where H_{m,s} = Generalised Harmonic Number = Sum_{k=1}^n 1/(k^s)
 -- https://en.wikipedia.org/wiki/Harmonic_number#Generalized_harmonic_numbers
	-- In any case, I've omitted the division by H_{m,s}
	-- but isn't this because it's just the sum ?

	local is_array = false
	local N
	if type(a) == 'table' then is_array = true ; N = #a else N = a end
	if not s then s = 1.0 end
	local harmonic_number = 0.0
	for k = 1,N do harmonic_number = harmonic_number + (1 / k^s) end
	local rel_freq = {}
	local sum = 0
	for n = 1,N do   -- rel_freq[n] = (1/n^s) / harmonic_number
		rel_freq[n] = 1/n^s
		sum = sum + rel_freq[n]
	end
	-- for i,v in ipairs(rel_freq) do print(i,v) end
	-- print('sum =', sum)
	local switchpoints = { 1/sum, }
	for k = 2, N-1 do
		switchpoints[k] = switchpoints[k-1] + rel_freq[k]/sum
	end
	-- for i,v in ipairs(switchpoints) do print(i,v) end
	if is_array then
		return function ()
			local r = math.random()
			for i = 1,N-1 do
				if r < switchpoints[i] then return a[i] end
			end
			return a[N]
		end
	else
		return function ()
			local r = math.random()
			for i = 1,N-1 do
				if r < switchpoints[i] then return i end
			end
			return N
		end
	end
end

local function sorted_keys(t, f)
    local a = {}
    for k,v in pairs(t) do a[#a+1] = k end table.sort(a, f)
    return  a
end

function M.wordcount2zipf (word2count)
    -- it must be able to find the Zipf s for eg: city-populations
    -- so it handles the table word2count directly !
    local hitparade = sorted_keys (
        word2count,   function (a,b) return word2count[b]<word2count[a] end
    )
    local sses = {}
    local first_count = word2count[hitparade[1]]
    local j = 2 ; while j <= #hitparade do
        local w = hitparade[j]
        local f_j = word2count[w] / first_count
        local s = -1.0*math.log(f_j) / math.log(j)
        sses[#sses+1] = s
        j = j + 1
    end
    local sum = 0.0
    for i,s in ipairs(sses) do sum = sum + s end
    local average_s = sum / #sses
    local square_sum = 0.0
    for i,s in ipairs(sses) do square_sum = square_sum + (s - average_s)^2 end
    return average_s, math.sqrt(square_sum / #sses)
end

return M

--[=[

=pod

=head1 NAME

randomdist.lua - 
a few simple functions for generating random numbers.

=head1 SYNOPSIS

 local R = require 'randomdist'

 grand1 = R.new_grand(10,3)
 grand2 = R.new_grand(100,3)
 for i = 1,20 do print( grand1(), grand2() ) end

 gue_irand1 = R.new_gue_irand(4)
 gue_irand2 = R.new_gue_irand(20)
 for i = 1,20 do print( gue_irand1(), gue_irand2() ) end

 for i = 1,20 do print(R.rayleigh_rand(3)) end

 a = {'cold', 'cool', 'warm', 'hot'}
 for i = 1,20 do print(R.randomget(a)) end

 word2count = {
   the=983, ['and']=421, of=340, to=286, I=263, it=252, -- etc
 }
 s, stddev = R.wordcount2zipf(word2count)
 eo_words = {'la', 'kaj', 'de', 'al', 'mi', 'gxi'}
 random_word = R.new_zipf(eo_words, s)
 for i = 1,1000 do print(random_word()) end

=head1 DESCRIPTION

This module implements in Lua a few simple functions
for generating random numbers according to various distributions.

=head1 FUNCTIONS

=over 3

=item I<new_grand( mean, stddev)>

This function returns a closure, which is a function which you
can then call to return a Gaussian (or Normal) Random distribution of numbers
with the given I<mean> and I<standard deviation>.

It keeps some internal local state, but because it is a closure, 
you may run different Gaussian Random generators simultaneously,
for example with different means and standard-deviations,
without them interfering with each other.

It uses the algorithm given by Erik Carter which used to be at
http://www.design.caltech.edu/erik/Misc/Gaussian.html

This algorithm generates results in pairs, but returns them one by one.
Therefore if you are using I<math.randomseed> to reset the random-number
generator to a known state, and your code happens to make an odd number
of calls to your closure, and you want your program to run consistently,
then you should call your closure (eg: I<grand1>) with the
argument 'reset' each time you call I<math.randomseed>. Eg:

 grand1 = R.new_grand(10,3)
 ... grand1() ... etc ...
 math.randomseed(244823040) ; grand1('reset')

=item I<new_gue_irand( average )>

This function returns a closure, which is a function which you can then
call to return a Gaussian-Random-Ensemble distribution of integers.

The Gaussian Unitary Ensemble models Hamiltonians lacking
time-reversal symmetry.
Considering a hermitian matrix with gaussian-random values;
from the ordered sequence of eigenvalues,
one defines the normalized spacings

 s = (\lambda_{n+1}-\lambda_n) / <s>

where <s> = is the mean spacing.
The probability distribution of spacings is approximately given by

  p_2(s) = (32 / pi^2) * s^2 * e^((-4/pi) * s^2)

These numerical constants are such that p_2 (s) is normalized:
and the mean spacing is 1.

  \int_0^\infty ds p_2(s) = 1 
  \int_0^\infty ds s p_2(s) = 1

Montgomery's pair correlation conjecture is a conjecture made by Hugh
Montgomery (1973) that the pair correlation between pairs of zeros of
the Riemann zeta function (normalized to have unit average spacing) is:

  1 - ({sin(pi u)}/{pi u}})^2 + \delta(u)

which, as Freeman Dyson pointed out to him, is the same as the pair
correlation function of random Hermitian matrices.

=item I<rayleigh_rand( sigma )>

This function returns a random number according to the Rayleigh Distribution,
which is a continuous probability distribution for positive-valued
random variables.  It occurs, for example, when random complex numbers
whose real and imaginary components are independent Gaussian distributions
with equal variance and zero mean, in which case,
the absolute value of the complex number is Rayleigh-distributed.

 f(x; sigma) = x exp(-x^2 / 2*sigma^2) / sigma^2      for x>=0

The algorithm contains no internal state,
hence I<rayleigh_rand> directly returns a number.

=item I<randomget( an_array )>

This example gets a random element from the given array.
For example, the following executes one of the four given procedures at random:

   randomget( {bassclef, trebleclef, sharp, natural} ) ()

=item I<randomgetn( an_array, n )>

This example returns an array containing B<n> random elements,
with distinct indices, from the given array.

=item I<new_zipf (an_array, s)>

=item I<new_zipf (n, s)>

This function returns a closure, which is a function which you can then
call to return a
https://en.wikipedia.org/wiki/Zipf%27s_law
Zipf-Distribution of array elements, or of integers.

The first example takes an array argument and returns a function which
will return one of the items in the array, the first item being returned
most frequently.

The second example takes an number argument and returns a function which
will return a number from 1 to n, with 1 being the most frequent.

If B<s> is not given it defaults to 1.0 

=item I<s, stddev = wordcount2zipf (a_word_to_number_table)>

This function can supply the B<s> parameter used by
B<new_zipf()>

The argument is a table, for example:

    city2population = {
      Chongqing=30165500,
      Shanghai=24183300,
      Beijing=21707000,
      Lagos=16060303,
      Istanbul=15029231,
      Karachi=14910352,   -- etc , etc ...
    }

It returns two numbers: the parameter B<s>,
and its standard deviation B<stddev>
from which you can guess how reliable your parameter B<s> is.

=back

=head1 DOWNLOAD

This module is available at
http://www.pjb.com.au/comp/lua/randomdist.html

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 https://en.wikipedia.org/wiki/Normal_distribution
 http://www.design.caltech.edu/erik/Misc/Gaussian.html
 https://en.wikipedia.org/wiki/Random_matrix#Gaussian_ensembles
 https://en.wikipedia.org/wiki/Random_matrix#Distribution_of_level_spacings
 https://en.wikipedia.org/wiki/Montgomery%27s_pair_correlation_conjecture
 https://en.wikipedia.org/wiki/Radial_distribution_function
 https://en.wikipedia.org/wiki/Pair_distribution_function
 https://en.wikipedia.org/wiki/Rayleigh_distribution
 https://en.wikipedia.org/wiki/Zipf%27s_law
 https://luarocks.org/modules/luarocks/lrandom
 http://www.pjb.com.au/comp/randomdist.html
 http://www.pjb.com.au/comp/index.html

 Montgomery, Hugh L. (1973), "The pair correlation of zeros of the zeta
 function", Analytic number theory, Proc. Sympos. Pure Math., XXIV,
 Providence, R.I.: American Mathematical Society, pp. 181-193, MR 0337821

 Odlyzko, A. M. (1987), "On the distribution of spacings between zeros
 of the zeta function", Mathematics of Computation, American Mathematical
 Society, 48 (177): 273-308, ISSN 0025-5718, JSTOR 2007890, MR 866115,
 doi:10.2307/2007890

 "Prime Obsession", by John Derbyshire, p.288

=cut

]=]

