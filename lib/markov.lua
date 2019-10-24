---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2018, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '27jan2018'

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

math.randomseed(os.time())
-- require 'DataDumper'
local stats  = false

function prefix (...) return table.concat({...}, " ") end

-- local NOWORD = "\n"
local NOWORD = ""

------------------------------ public ------------------------------

local UsingStdinAsAFile = false
function M.file2words(filename)
	-- this bit from midi_markov.lua  function file2millisec(filename)
	local filehandle = nil
	if filename == '-' then
		if UsingStdinAsAFile then die("can't read STDIN twice") end
		UsingStdinAsAFile = true
		filehandle = io.stdin
	elseif string.find(filename, '^|%s*(.+)') then  -- 4.8
		local command = string.match(filename, '^|%s*(.+)')  -- 4.8
		local err_fn = os.tmpname()
		filehandle = assert(io.popen(command..' 2>'..err_fn, 'r'))
	elseif string.find(filename, '^[a-z]+:/') then  -- 3.8
		pcall(function() require 'curl' end)
		if not curl then pcall(function() require 'luacurl' end) end
		if not curl then
			die([[you need to install lua-curl or luacurl, e.g.:
  luarocks install luacurl
or, if that doesn't work:
  aptitude install liblua5.1-curl0  (or equivalent on non-debian sytems)
]])
		end
		local text = wget(filename)
		local tmpf = os.tmpname()
		assert(io.open(tmpf, 'wb'))
		io.write(tmpf, text)
		io.close(tmpf)
		filehandle = assert(io.open(tmpf, 'rb'))
	else
		filehandle = assert(io.open(filename, 'rb'))
	end
	-- the rest from markov_4.lua  function stdin2words ()
	local line = filehandle:read()  -- current line
	local pos = 1           -- current position in the line
	return function ()      -- operator function
		while line do
			local w, e = string.match(line, "(%S+)()", pos)
			-- utf8 chars    [\xC2-\xF4][\x80-\xBF]*
			if w then       -- found a word ?
				pos = e     -- update next position
				return w
			else
				line = filehandle:read()  -- word not found - try next line
				pos = 1     -- restart at start of line
			end
		end
		return nil          -- no more lines: end of traversal
	end
end

function M.new_markov (arg)
	local allwords
	if  type(arg) == 'function' then allwords = arg
	elseif type(arg) == 'table' then
		local i = 0
		allwords = function (arg) ; i = i + 1 ; return arg[i] end
	end
	local input_words = 0
	local found = {0,0,0,0}

	local statetab_1 = {}   -- indexed by the current word only
	local statetab_2 = {}   -- indexed by the last two words
	local statetab_3 = {}   -- indexed by the last three words
	local statetab_4 = {}   -- indexed by the last four words
	function insert (w1, w2, w3, w4, value)
		local list1 = statetab_1[w4]
		if list1 == nil then statetab_1[w4] = {value}
		else              list1[#list1 + 1] = value
		end
		local p2 = prefix(w3, w4)
		local list2 = statetab_2[p2]
		if list2 == nil then statetab_2[p2] = {value}
		else              list2[#list2 + 1] = value
		end
		local p3 = prefix(w2, w3, w4)
		local list3 = statetab_3[p3]
		if list3 == nil then statetab_3[p3] = {value}
		else              list3[#list3 + 1] = value
		end
		local p4 = prefix(w1, w2, w3, w4)
		local list4 = statetab_4[p4]
		if list4 == nil then statetab_4[p4] = {value}
		else              list4[#list4 + 1] = value
		end
	end

	-- build table
	local w1,w2,w3,w4 = NOWORD, NOWORD, NOWORD, NOWORD   -- initialise
	for nextword in allwords do
		insert(w1, w2, w3, w4, nextword)
		w1 = w2 ; w2 = w3 ; w3 = w4 ; w4 = nextword
		input_words = input_words + 1
	end
	insert(w1, w2, w3, w4, NOWORD)

	-- generate text
	w1 = NOWORD ; w2 = NOWORD ; w3 = NOWORD ; w4 = NOWORD  -- reinitialise
	local seeds = {}
	return function (opt, ...)
		if opt == 'stats' then
			local s = "input_words="..tostring(input_words)..",  "
			for i = #found,1,-1 do
				s = s .. "found["..tostring(i).."]="..tostring(found[i]).." "
			end
			return s
		end
		if opt == 'seed' then
			seeds = {...}
			for i = 1, #seeds do
				seeds[i] = tostring(seeds[i])
				if statetab_1[seeds[i]] then
					w1 = w2 ; w2 = w3 ; w3 = w4 ; w4 = seeds[i]
				end
			end
			return nil
		end
		if #seeds > 0 then  -- still some seeds left; regurgitate the seed
			local w = table.remove(seeds, 1)
			return w
		end
		local nextword
		local list2 = statetab_2[prefix(w3,w4)]
		local list3 = statetab_3[prefix(w2,w3,w4)]
		local list4 = statetab_4[prefix(w1,w2,w3,w4)]
		if list4 and #list4 > 1 then
			nextword = list4[math.random(#list4)]  -- choose a random word
			found[4] = found[4] + 1
		elseif list3 and #list3 > 1 then
			nextword = list3[math.random(#list3)]  -- choose a random word
			found[3] = found[3] + 1
		elseif list2 and #list2 > 1 then
			nextword = list2[math.random(#list2)]
			found[2] = found[2] + 1
		else
			local list1 = statetab_1[w4]
			if not list1 then return end
			nextword = list1[math.random(#list1)]
			found[1] = found[1] + 1
		end
		-- if nextword ~= NOWORD then io.stdout:write(nextword, " ") end
		-- if it's a NOWORD, we should try the next one ...
		w1 = w2 ; w2 = w3 ; w3 = w4 ; w4 = nextword
		return nextword
	end
end

return M

--[=[

=pod

=head1 NAME

markov.lua - Markov-chain text-reconstruction

=head1 SYNOPSIS

  local MA = require 'markov'
  local my_markov = MA.new_markov(input_words)
  my_markov('seed','The','European','Commission')
  for i = 1,300 do io.stdout:write(tostring(my_markov())..' ') end 
  local stats = my_markov('stats')

=head1 DESCRIPTION

Markov.lua evolved from the code on p.184 of PiL.4.

Markov.lua maintains N=1, N=2, N=3 and N=4 lists,
and if there's more than one item in the
N=4 list then it chooses from there before trying the N=3, N=2 and N=1 lists.

The goal of asking for more than one item to choose from
is to break up the long literal quoted passages,
and the goal of N=3 and N=4 is to to use the higher-quality style
and grammar when it's available.

Subsequently, a I<r = 0.15> randomise-option may be introduced,
so that if a list is only one item long,
then 0.15 of the time that item is chosen,
and the other 0.85 of the time the next list is consulted.
The default behaviour is I<r = 0.0>, which works well.

=head1 FUNCTIONS

The API only contains one function:

=over 3

=item I<local my_markov = new_markov(allwords)>

I<new_markov> returns a closure - a function that lies within a
context of local variables which implement the markov generator.
You can then call this closure with no argument,
and it will return the next suggested word.

The parameter I<allwords> can be an array of words,
or it can be another closure function (for example I<ipairs>)
and I<new_markov> will detect the argument-type and behave accordingly.

The returned closure I<my_markov> can be called in several ways:

=item I<local nextword = my_markov()>

When called with no argument (or an unrecognised argument),
the closure returns another word for you to use.

=item I<my_markov('seed','The','European','Commission')>

When called with I<'seed'> as the first argument,
then the other arguments are taken as the first word or several words
that you wish your generated text to start with.

This invocation would typically be made before the start of
the main loop, which calls I<my_markov> with no arguments.
It returns I<nil>.

In this example, the generated text will start "The European Commission",
after which it will continue selecting plausible continuations of these
three words, as usual.

=item I<my_markov('stats')>

When called with I<'stats'> as the first argument,
then it returns a string with a few statistics about how things ran:
the number of words in the input, the number of matches found in the
N=4 list, the N=3 list, the N=2 list, and the N=1 list. For example:

  input_words=11719,  found[4]=7 found[3]=16 found[2]=88 found[1]=186

This invocation would typically be made after the main loop has finished.

=back

=head1 DOWNLOAD

The source is pure lua, and available at
I<http://www.pjb.com.au/comp/lua/markov.lua>

Because it uses my own additions to the standard Markov calculations,
and is subject to upredictable development with no guarantee of
backward-compatibility, it is not available on I<luarocks.org>.
But you can still install it using I<luarocks> with:

   luarocks install http://www.pjb.com.au/comp/lua/markov-1.1-0.rockspec

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 http://www.pjb.com.au/
 https://github.com/dromozoa/dromozoa-utf8/
 https://github.com/dromozoa/dromozoa-utf8/blob/master/build_is_white_space.lua

=cut

]=]
