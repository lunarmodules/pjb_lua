#!/usr/local/bin/lua
---------------------------------------------------------------------
--     This Lua5 script is Copyright (c) 2017, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This script is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
local Version = '1.5  for Lua5'
local VersionDate  = '24jul2018';
local Synopsis = [[
test_randomdist.lua [options] [filenames]
]]

local R = require 'randomdist'

local Test = 14 ; local i_test = 0; local Failed = 0;
function ok(b,s)
	i_test = i_test + 1
	if b then
		io.write('ok '..i_test..' - '..s.."\n")
	else
		io.write('not ok '..i_test..' - '..s.."\n")
		Failed = Failed + 1
	end
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
local function abs(x) if x<0 then return 0-x else return x end end


math.randomseed(os.time())
local n = 10000

print('# Gaussian Random Distribution :')
local grand1 = R.new_grand(10,3)
local grand2 = R.new_grand(100,3)
local a1 = {}
local a2 = {}
for i = 1,n do
	-- print( grand1(), grand2())
	a1[i] = grand1()
	a2[i] = grand2()
end
local sum1 = 0
local sum2 = 0
for i = 1,n do
	sum1 = sum1 + a1[i]
	sum2 = sum2 + a2[i]
end
local av1 = sum1 / n
local av2 = sum2 / n
-- print('av1 =',av1,' av2 =',av2)
ok((abs(av1 - 10)<0.5), 'av1 was '..tostring(av1))
ok((abs(av2 -100)<5.0), 'av2 was '..tostring(av2))
local stddev1 = 0
local stddev2 = 0
for i = 1,n do
	stddev1 = stddev1 + (a1[i] - av1)^2
	stddev2 = stddev2 + (a2[i] - av2)^2
end
stddev1 = math.sqrt(stddev1 / n)
stddev2 = math.sqrt(stddev2 / n)
ok((abs(stddev1 - 3)<0.2), 'stddev1 was '..tostring(stddev1))
ok((abs(stddev2 - 3)<0.2), 'stddev2 was '..tostring(stddev2))

math.randomseed(10200960)
local x1 = grand1()
local x2 = grand1('reset')
ok((x2 == nil), "grand1('reset') returns "..tostring(x2))
math.randomseed(10200960)
local x3 = grand1()
ok((x1 == x3), "grand1('reset') resets successfully")

print('# Gaussian Random Ensemble :')
local gue_irand1 = R.new_gue_irand(4)
local gue_irand2 = R.new_gue_irand(20)
a1 = {}
a2 = {}
for i = 1,n do
    a1[i] = gue_irand1()
    a2[i] = gue_irand2()
end
sum1 = 0
sum2 = 0
for i = 1,n do
    sum1 = sum1 + a1[i]
    sum2 = sum2 + a2[i]
end
av1 = sum1 / n
av2 = sum2 / n

ok((abs(av1 - 4)<0.5), 'av1 was '..tostring(av1))
ok((abs(av2 -20)<5.0), 'av2 was '..tostring(av2))

-- local a = {'cold', 'cool', 'warm', 'hot'}
-- for i = 1,20 do print( R.randomget(a)) end

print('# Rayleigh Distribution :')
-- https://en.wikipedia.org/wiki/Variance
-- https://en.wikipedia.org/wiki/Rayleigh_distribution#Properties
local a1 = {}
local a2 = {}
for i = 1,n do
	a1[i] = (R.rayleigh_rand(1))
	a2[i] = (R.rayleigh_rand(6))
end
local sum1 = 0
local sum2 = 0
for i = 1,n do
	sum1 = sum1 + a1[i]
	sum2 = sum2 + a2[i]
end
local av1 = sum1 / n
local av2 = sum2 / n
ok((abs(av1 - 1.253*1)<0.02), 'av1 was '..tostring(av1))
ok((abs(av2 - 1.253*6)<0.10), 'av2 was '..tostring(av2))
local stddev1 = 0
local stddev2 = 0
for i = 1,n do
	stddev1 = stddev1 + (a1[i] - av1)^2
	stddev2 = stddev2 + (a2[i] - av2)^2
end
stddev1 = stddev1 / n
stddev2 = stddev2 / n
ok((abs(stddev1 - 0.429*1*1)<0.1), 'stddev1 was '..tostring(stddev1))
ok((abs(stddev2 - 0.429*6*6)<0.5), 'stddev2 was '..tostring(stddev2))

print('# Zipf Distribution :')
-- https://en.wikipedia.org/wiki/Zipf%27s_law
-- > 1e6 / (8 * (1 + 1/2 + 1/3 + 1/4 + 1/5 + 1/6 + 1/7 + 1/8))
-- > math.sqrt(45992)
-- > 4 * math.sqrt(45992)
-- > 45992.115637319 + 857.82981995265
-- > 45992.115637319 - 857.82981995265
-- > 1e6 / (1 * (1 + 1/2 + 1/3 + 1/4 + 1/5 + 1/6 + 1/7 + 1/8))
-- > 4 * math.sqrt(367936.92509855)
-- > 367936.92509855 + 2426.3121813932
-- > 367936.92509855 - 2426.3121813932
local a = { 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', }
local my_zipf =  R.new_zipf(a)
local histogram = {}
for i = 1,1e6 do
    local z = my_zipf()
    histogram[z] = (histogram[z] or 0) + 1
end
ok( histogram['a'] > 365500 and histogram['a'] < 370400,
  'new_zipf with an array a = '..tostring(histogram['a']))
ok( histogram['h'] > 45134 and histogram['h'] < 46850,
  'new_zipf with an array h = '..tostring(histogram['h']))
my_zipf =  R.new_zipf(8)
histogram = {}
for i = 1,1e6 do
    local z = my_zipf()
    histogram[z] = (histogram[z] or 0) + 1
end
ok( histogram[1] > 365500 and histogram[1] < 370400,
  'new_zipf with a number 1 = '..tostring(histogram[1]))
ok( histogram[8] > 45134 and histogram[8] < 46850,
  'new_zipf with a number 8 = '..tostring(histogram[8]))

local s_equals_one = {
    one=1000,
    half=500,
    third=333,
    quarter=250,
    fifth=200,
    sixth=167,
    seventh=143,
    eighth=125,
    ninth=111,
    tenth=100,
    eleventh=91,
    twelfth=83,
    thirteenth=77,
}
local s_equals_half = {
    one=1000,
    root_half=707,
    root_third=577,
    root_quarter=500,
    root_fifth=447,
    root_sixth=408,
    root_seventh=337,
    root_eighth=353,
    root_ninth=333,
    root_tenth=316,
    root_eleventh=301.5,
    root_twelfth=289,
    root_thirteenth=277,
}
s, stddev = R.wordcount2zipf(s_equals_one)
ok(s>.999 and s<1.001, 'wordcount2zipf(s_equals_one) gives s correctly')
ok(stddev<.002, 'wordcount2zipf(s_equals_one) gives stddev correctly')
s, stddev = R.wordcount2zipf(s_equals_half)
ok(s>.495 and s<.509, 'wordcount2zipf(s_equals_half) gives s correctly')
ok(stddev<.02, 'wordcount2zipf(s_equals_half) gives stddev correctly')


print('# Random get n from an array :')
math.randomseed(os.time())
local arr = R.randomgetn({
  'white', 'black', 'red', 'orange', 'yellow', 'blue', 'violet', 'green',
}, 5)
-- print(table.unpack(arr))
ok(#arr == 5, "randomgetn({...} , 5) returns 5 items")
local t = {}
for i,v in ipairs(arr) do t[v] = true end
local num_distinct = 0
for k,v in pairs(t) do num_distinct = num_distinct+1 end
ok(num_distinct == 5, "those 5 items are all distinct")

os.exit()


