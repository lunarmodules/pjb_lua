---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2015, Peter J Billam      --
--                       www.pjb.com.au                            --
--                                                                 --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- Example usage:
-- local MM = require 'mymodule'
-- MM.foo()
-- Experimental Design and Statistics, Steve Miller, p.81
--   https://en.wikipedia.org/wiki/Student%27s_t-test    equal variances
--   https://en.wikipedia.org/wiki/Welch%27s_t_test    unequal variances
-- from https://help.libreoffice.org/Calc/Statistical_Functions_Part_Five#TTEST
--   Returns the probability associated with a Student's t-Test.
--   TTEST(Data1; Data2; Mode; Type)
--   Data1 is the dependent array or range of data for the first record.
--   Data2 is the dependent array or range of data for the second record.
--   Mode = 1 calculates the one-tailed test, Mode = 2 the two-tailed test.
--   Type is the kind of t-test to perform. Type 1 means paired.
--   Type 2 means two samples,  equal variance  (homoscedastic).
--   Type 3 means two samples, unequal variance (heteroscedastic).
--   Example =TTEST(A1:A50;B1:B50;2;2)
-- https://en.wikipedia.org/wiki/Statistical_significance
-- https://en.wikipedia.org/wiki/Statistical_hypothesis_testing
-- https://en.wikipedia.org/wiki/Test_statistic
-- Two-sample unpooled t-test, unequal variances 
-- https://en.wikipedia.org/wiki/P-value
-- I need the algorithm that replaces the table p.133 ...

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '23oct2015'

------------------------------ private ------------------------------
local function warn(str) io.stderr:write(str,'\n') end
local function die(str) io.stderr:write(str,'\n') ;  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
	local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end
local df_to_t_to_p = {
-- p = .10    .05    .02  (two-tailed), indexed by degrees_of_freedom, p.133
	{ 6.314,12.706,31.821 },
	{ 2.920, 4.303, 6.965 },
	{ 2.353, 3.182, 4.541 },
	{ 2.132, 2.776, 3.747 },
	{ 2.015, 2.571, 3.365 },

	{ 1.943, 2.447, 3.143 },
	{ 1.895, 2.365, 2.998 },
	{ 1.860, 2.306, 2.896 },
	{ 1.883, 2.262, 2.821 },
	{ 1.812, 2.228, 2.764 },

	{ 1.796, 2.201, 2.718 },
	{ 1.782, 2.179, 2.681 },
	{ 1.771, 2.160, 2.650 },
	{ 1.761, 2.145, 2.624 },
	{ 1.753, 2.131, 2.602 },

	{ 1.746, 2.120, 2.583 },
	{ 1.740, 2.110, 2.567 },
	{ 1.734, 2.101, 2.552 },
	{ 1.729, 2.093, 2.539 },
	{ 1.725, 2.086, 2.528 },

	{ 1.721, 2.080, 2.518 },
	{ 1.717, 2.074, 2.508 },
	{ 1.714, 2.069, 2.500 },
	{ 1.711, 2.064, 2.492 },
	{ 1.708, 2.060, 2.485 },

	{ 1.706, 2.056, 2.479 },
	{ 1.703, 2.052, 2.473 },
	{ 1.701, 2.048, 2.467 },
	{ 1.699, 2.045, 2.462 },
	{ 1.697, 2.042, 2.457 },
}

function t_to_p (t, df, mode)
	local t10,t05,t02 = 1.645,1.960,2.326
	if df <= #df_to_t_to_p then
		t10,t05,t02 = unpack(df_to_t_to_p[df])
		-- print("t10 =",t10, "t05 =",t05, "t02 =",t02)
	elseif df <= 40 then
		local r = (df-30) / 10
		t10 = 1.697 - 0.013*r
		t05 = 2.042 - 0.021*r
		t02 = 2.457 - 0.034*r
	elseif df <= 60 then
		local r = (df-40) / 20
		t10 = 1.684 - 0.013*r
		t05 = 2.021 - 0.021*r
		t02 = 2.423 - 0.033*r
	elseif df <= 120 then
		local r =  (df-40) / 60
		t10 = 1.671 - 0.013*r
		t05 = 2.000 - 0.021*r
		t02 = 2.390 - 0.033*r
	end
	local p = 0
	if t <= t10 then
		local r = (t/t05) / (t05-t10)   -- print("r = ",r)
		p = 0.10 ^ (1/r)
	elseif t >= t02 then
		local r = (t/t02) / (t02-t05)   -- print("r = ",r)
		p = 0.02 * (t02-t05) ^ r
	elseif t <= t05 then p = 0.10 - 0.05*((t-t10)/(t05-t10))
	elseif t >= t05 then p = 0.05 - 0.03*((t-t05)/(t02-t05))
	end
	if mode == 1 then p = p * 0.5 end
	return p
end

------------------------------ public ------------------------------
function M.mean(a)
	local sum = 0.0
	for i = 1,#a do sum = sum + a[i] end
	return sum/#a
end

function M.mean_varsquared(a)
	local m = M.mean(a)
	local sum = 0.0
	for i = 1,#a do sum = sum + a[i]*a[i] end
	return m, sum/#a - m*m
end

function M.mean_stddev(a)
	local mean,varsquared = M.mean_varsquared(a)
	return mean, varsquared^0.5
end

function M.ttest(a,b, hypothesis)
	-- we have to know whether the prediction is ma>mb, or mb>ma !
	-- No point reporting a low p if the sign was wrong !
	local na = #a
	local ma,va = M.mean_varsquared(a)
	local nb = #b
	local mb,vb = M.mean_varsquared(b)
	local mode = 1   -- one-tailed
	if hypothesis == 'a>b' or hypothesis == 'b<a' then
		if ma < mb then return 1.0 end
	elseif hypothesis == 'a<b' or hypothesis == 'b>a' then
		if ma > mb then return 1.0 end
	elseif hypothesis == 'a~=b' or hypothesis == 'b~=a' then
		mode = 2     -- two-tailed
	else
		warn("ttest: hypothesis must be a>b or a<b or a~=b")
		return nil
	end
	local df = na+nb-2   -- degrees of freedom
	if df < 1 then
		warn("ttest: a has "..tostring(na).." and b "..tostring(nb).." elements; that's not enough")
		return nil
	end
	local t = ((ma-mb) * (df*na*nb)^0.5) / ((na*va + nb*vb)*(na+nb))^0.5
	local p = t_to_p(t, df, mode)
	return p
end

return M 

--[=[

=pod

=head1 NAME

Stats.lua - t-test

=head1 SYNOPSIS

 local Stats = require 'Stats'
 a = { 6,8,7,9,8 }
 b = { 4,7,5,4,5,6,4 }
 local mean,stddev = Stats.mean_stddev(a)
 local probability_of_hypothesis_being_wrong = Stats.ttest(a,b,'a>b')

=head1 DESCRIPTION

This module implements the t-test.
This test is used in statistics when there are there are two arrays of
measurements of some value (I<a> and I<b>),
made under somewhat different conditions,
and you have a hypothesis that the change in conditions should cause
a change in the value.

=head1 FUNCTIONS

=over 3

=item I<mean_stddev(a)>

The argument I<a> is an array of numbers,
assumed to have an approximately normal distribution.
I<mean_stddev> returns two numbers: the mean and the standard deviation
of the numbers in I<a>.

=item I<ttest(a,b, hypothesis)>

The arguments I<a> and I<b> are arrays of numbers.
Each array is assumed to contain measurements of something,
assumed to have approximately normal distributions.
The arrays do not have to be of the same size,
and their standard-deviations do not have to be the same.

The I<hypothesis> is a string;
it can be one of 'a>b', 'a<b', 'b>a', 'b<a', 'a~=b' or 'b~=a'.

I<ttest> returns the probability of your hypothesis being wrong.
So if this probability is less than, for example, 0.02, you may
reasonably claim that your hypothesis has been confirmed by measurement.

=back

=head1 DOWNLOAD

This module is currently available only at I<~/lua/lib/Stats.lua>

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 https://en.wikipedia.org/wiki/Statistics
 https://en.wikipedia.org/wiki/Statistics#Examples
 https://en.wikipedia.org/wiki/Ordinary_least_squares
 https://en.wikipedia.org/wiki/Student%27s_t-test    (equal variances)
 https://en.wikipedia.org/wiki/Welch%27s_t_test    (unequal variances)
 https://en.wikipedia.org/wiki/Statistical_significance
 https://en.wikipedia.org/wiki/Statistical_hypothesis_testing
 https://en.wikipedia.org/wiki/Test_statistic
 https://en.wikipedia.org/wiki/P-value
 https://en.wikipedia.org/wiki/Polynomial_interpolation
 https://en.wikipedia.org/wiki/Lagrange_polynomial
 Experimental Design and Statistics, Steve Miller, p.81
 http://www.pjb.com.au/

=cut

]=]
