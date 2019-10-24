---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2016, Peter J Billam      --
--                       www.pjb.com.au                            --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------

local M = {} -- public interface
M.Version = '1.0'
M.VersionDate = '1aug2016'

-- Translation of   ~/lua/restricted_boltzmann_machines/rbm_shorter.py
-- See  https://en.wikipedia.org/wiki/Restricted_Boltzmann_machine
-- need np.dot np.insert np.random.rand np.sum np.ones np.exp np.array
-- http://docs.scipy.org/doc/numpy/genindex.html

-- once this works, it might be good to separate the 'bias' units
-- out of the training-data, neg_visible_probs, hidden_probs, samples
-- and hard-wire it in the loops... I think the py version only rolls
-- it in (than takes it out again) so it can use the numpy library...

-- might be good to offer the energy function and its derivative,
--   see 2010_geoff_hinton video at 02.30
--  the derivative being how you change the energy during the learning
-- might be good to offer the partition function,
--   see 2010_geoff_hinton video at 02.50
-- and the probability of a visible-hidden combination 3:00
-- and the overall probability of the visibile vector  3:09
-- the most important slide in the talk is at 7:40
-- note at 9:20 that the visible units are linear (float), not 0/1 (boolean)
-- this changes the energy function 9:28 by using "parabolic containment"
-- at 28:00 the hidden units are binary, though the visible units are float
-- 29:30 predicts the next frame in a time-series (think notes in composition)
--   note the 1-of-N style categories at 32:00 !!

----------------------- private from pjblib.lua -----------------------
function warn(...)
    local a = {}
    for k,v in pairs{...} do table.insert(a, tostring(v)) end
    io.stderr:write(table.concat(a),'\n') ; io.stderr:flush()
end
function die(...) warn(...);  os.exit(1) end
function qw(s)  -- t = qw[[ foo  bar  baz ]]
	local t = {} ; for x in s:gmatch("%S+") do t[#t+1] = x end ; return t
end
local function deepcopy(object)  -- http://lua-users.org/wiki/CopyTable
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

------------------- private specific to this module ------------------

local function np_dot(a,b)
    -- http://docs.scipy.org/doc/numpy/reference/generated/numpy.dot.html
	-- In matrices, the top row is i=1 , and the left column is j=1 ,
	-- which is alphabetically the other way round from x and y !
	-- but it means a[i][j] displays correctly with DataDumper :-)
	-- require 'DataDumper'
    if type(a[1]) == 'table' then
		if type(b[1]) == 'table' then  -- matrix-product of 2D-arrays
        	local nia = #a ; local nja = #a[1]
        	local nib = #b ; local njb = #b[1]
        	if nja ~= nib then
            	warn('np_dot: matrix dimensions do not match')
				-- warn('a = ',DataDumper(a)) warn('b = ',DataDumper(b))
            	die('nia=',nia,' nja=',nja,'  nib=',nib,' njb=',njb)
        	end
        	local c = {}
        	for i_c = 1,nia do       -- loop by rows
            	c[i_c] = {}
            	for j_c = 1,njb do   -- loop by columns
                	local sum = 0.0
                	for j = 1,nja do sum = sum + a[i_c][j]*b[j][j_c] end
                	c[i_c][j_c] = sum
            	end
			end
        	return c
		else -- 2D x 1D
			die('np_dot: 2D x 1D not yet implemented')
        end
	else   -- so a is 1D ...
		if type(b[1]) == 'table' then  -- 1D x 2D
        	local nia = #a ; local nib = #b ; local njb = #b[1]
			if nia ~= nib then
            	warn('np_dot: matrix dimensions do not match')
				-- warn('a = ',DataDumper(a)) warn('b = ',DataDumper(b))
            	die('nia=',nia,'  nib=',nib,' njb=',njb)
			end
			local c = {}
			for j_b = 1,njb do
				local sum = 0.0
				for i = 1,nia do sum = sum + a[i]*b[i][j_b] end
				c[j_b] = sum
			end
			return c
    	else  -- scalar-product of 1D-arrays
        	local sum = 0.0
        	for i = 1,#a do sum = sum + a[i]*b[i] end
        	return sum
		end
    end
end

local function for_all_elems(func, a)
	if type(a) == 'number' then return func(a) end -- it was a scalar
	if  type(a[1]) == 'table' then  -- 2D-array
		local c = {}
		for irow,vrow in ipairs(a) do
			c[irow] = {}
			for icol,vcol in ipairs(vrow) do c[irow][icol] = func(vcol) end
		end
		return c
	elseif type(a) == 'table' then  -- 1D-array
		local c = {}
		for i,v in ipairs(a) do c[i] = func(v) end
		return c
	end
end

local function sigmoid(x) return 1 / (1 + math.exp(0-x)) end

function M.stochastic(x)
	-- x is typically = -b_i + \Sum_j s_j w_j_i 
	-- when shifting data between machines, binary data is 32 time faster :-)
	if (1/(1+math.exp(0-x))) > math.random() then return 1 else return 0 end
end
-- for the Learning-Rule see 2012_geoff_hinton_at_ipam.mp4 at 19:30
-- for the Energy-Function see 2012_geoff_hinton_at_ipam.mp4 at 36:18
function M.energy(v,h,w)   -- visible units, hidden units, weights
	-- for the Energy-Function see 2012_geoff_hinton_at_ipam.mp4 at 36:18
	-- v could be number or binary; h is quite likely binary
	-- - \Sum v_i h_j w_i_j
	local sum = 0.0
	for i = 1,#v do
		for j = 1,#h do
			sum = sum + v[i] * h[j] * w[i][j]
		end
	end
	return sum
end
function M.energy_gradient(v,h,w)   -- visible units, hidden units, weights
	-- for the Energy-Gradient see 2012_geoff_hinton_at_ipam.mp4 at 36:18
	-- v and h are binary
	-- v_i h_j = - (\Sum v_i h_j w_i_j ) / w_i_j
end
function M.partition_function(v,h)   -- visible units, hidden units, weights
	-- for the Partition-Function see 2012_geoff_hinton_at_ipam.mp4 at 38:00
end

local function logistic(a)  -- a smooth 0-to-1, crossing 0.5 at x=0
	-- http://docs.scipy.org/doc/numpy/reference/generated/numpy.exp.html
	-- which calculates the exponential of all elements in the input array
	return for_all_elems(function(x) return 1.0/(1.0+math.exp(0.0-x)) end,a)
end


local function gt_rand(a)  -- is each element greater than random [0,1) ?
	return for_all_elems(
	function(x) if x>math.random() then return 1.0 else return 0.0 end end,a)
end

function transpose(a)
	local c = {}
	for icol,vcol in ipairs(a[1]) do c[icol] = {} end
	for irow,vrow in ipairs(a) do
		for icol,vcol in ipairs(vrow) do c[icol][irow] = vcol end
	end
	return c
end

local function rand_array(d0,d1)  -- numpy.random.rand(d0, d1, ..., dn)
-- http://docs.scipy.org/doc/numpy/reference/generated/numpy.random.rand.html
	-- Create an array of the given dimensions and populate it with
	-- random samples from a uniform distribution over [0, 1)
	-- Here we only handle one or two dimensions ...
	if not d0 then return math.random() end
	local a = {}
	if not d1 then  -- return a scalar array of random [0, 1)
		for i = 1,d0 do a[i] = math.random() end
	else
		for i = 1,d0 do
			a[i] = {}
			for j = 1,d1 do a[i][j] = math.random() end
		end
	end 
	return a
end

math.randomseed(os.time())
local gaussn_a = math.random()  -- reject 1st call to rand in case it's zero
local gaussn_b
local gaussn_flag = false
local function gaussn(stddev) -- using the Box-Muller rules
	if not gaussn_flag then
		gaussn_a = math.sqrt(-2.0 * math.log(0.999*math.random()+0.001))
		gaussn_b = 6.28318531 * math.random()
		gaussn_flag = true
		return (stddev * gaussn_a * math.sin(gaussn_b))
	else
		gaussn_flag = false
		return (stddev * gaussn_a * math.cos(gaussn_b))
	end
end

------------------------------ public ------------------------------
function M.new_rbm(arg)
	local num_visible = arg[1] or arg['num_visible']
	local num_hidden  = arg[2] or arg['num_hidden']
	local labels      = arg['labels']
	local rbm         = {}
	rbm.num_visible   = num_visible
	rbm.num_hidden    = num_hidden
	rbm.learning_rate = arg['learning_rate'] or 0.1
	if labels and #labels ~= num_visible then
		die('new_rbm: labels array must have ',num_visible,' elements')
	end
	rbm.labels        = labels
    rbm.weights       = {}
    for i_vis = 1, num_visible+1 do        -- Initialize the weights matrix
        rbm.weights[i_vis]    = {}
        for i_hid = 1, num_hidden+1 do
            if i_vis == 1 then
                rbm.weights[1][i_hid] = 1.0  -- bias unit for first column
            else
                if i_hid == 1 then
                    rbm.weights[i_vis][1] = 1.0  -- bias unit in first row
                else
                    rbm.weights[i_vis][i_hid] = gaussn(0.1)
                end
            end
        end
    end
	return rbm
end

function M.train(rbm, data, max_epochs)
	if not max_epochs then max_epochs = 1000 end
	num_examples = #data
	data = deepcopy(data) -- I think we need to deepcopy before the insert ...
	local err = 0.0
	for i,t in ipairs(data) do table.insert(t,1,1.0) end -- insert bias unit 1
	for epoch = 1,max_epochs do
		-- Clamp to the data and sample from the hidden units. 
		-- (This is the "positive CD phase", aka the reality phase.)
		-- pjb: "activation" seems to mean "activation energy" ie: "energy"
		local pos_hidden_activations = np_dot(data, rbm.weights) -- matrix mul
	 	local pos_hidden_probs = logistic(pos_hidden_activations)
	 	local pos_hidden_states = gt_rand(pos_hidden_probs)
		local pos_associations = np_dot(transpose(data), pos_hidden_probs)
		-- Reconstruct the visible units and sample again from the hidden units
		-- (This is the "negative CD phase", aka the daydreaming phase.)
		local neg_visible_activations = np_dot(
		  pos_hidden_states, transpose(rbm.weights))
		local neg_visible_probs = logistic(neg_visible_activations)
		for i,t in ipairs(neg_visible_probs) do t[1] = 1.0 end -- bias unit=1
		local neg_hidden_activations = np_dot(neg_visible_probs, rbm.weights)
		local neg_hidden_probs = logistic(neg_hidden_activations)
		-- Again, we're using the activation *probabilities*, not the states
		local neg_associations = np_dot(
		  transpose(neg_visible_probs), neg_hidden_probs)
        for irow,vrow in ipairs(rbm.weights) do   -- Update weights
            for icol,vcol in ipairs(vrow) do
				rbm.weights[irow][icol] = rbm.weights[irow][icol] +
				  rbm.learning_rate * (pos_associations[irow][icol]
				   - neg_associations[irow][icol]) / num_examples
			end
        end
		err = 0.0
        for irow,vrow in ipairs(data) do   -- calculate error terms
            for icol,vcol in ipairs(vrow) do err = err + (
				  data[irow][icol] - neg_visible_probs[irow][icol]) ^ 2
			end
        end

	end
	warn('train: after ',max_epochs,' iterations error was ',err)
end

function M.vis2hid(rbm, data)
	-- find the activations and then the probabilities of the hidden units
	-- we write this out in full so as to skip the bias units in col=1
	local hidden_activations = {}
	local nia = #data ;        local nja = #data[1]
	local nib = #rbm.weights ; local njb = #rbm.weights[1]
	for i_c = 1,nia do       -- loop by rows
		hidden_activations[i_c] = {}
		for j_c = 2,njb do   -- skip the bias then loop by columns
			local sum = 0.0
			for j=1,nja do sum = sum + data[i_c][j]*rbm.weights[j][j_c] end
			hidden_activations[i_c][j_c-1] = sum
		end
	end
	-- unlike the py, hidden_activations already has no bias units in col 1
	local hidden_probs = logistic(hidden_activations)
	local hidden_states = {} -- turn hidden units on with their probabilities
	for irow,vrow in ipairs(hidden_probs) do
		hidden_states[irow] = {}
		for icol = 1,#vrow do -- hidden_activations already has no bias units
			if hidden_probs[irow][icol] > math.random() then
				 hidden_states[irow][icol] = 1.0
			else
				 hidden_states[irow][icol] = 0.0
			end
		end
	end
	return hidden_states
end

function M.hid2vis(rbm, data)
    local num_examples = #data
	data = deepcopy(data) -- I think we need to deepcopy before the insert ...
    for i,t in ipairs(data) do table.insert(t,1,1.0) end -- insert bias unit 1
    local visible_activations = np_dot(data, transpose(rbm.weights))
    local visible_probs = logistic(visible_activations)
    local visible_states = {} -- turn visible units on with their probabilities.
	for irow,vrow in ipairs(visible_probs) do
		visible_states[irow] = {}
		for icol = 2,#vrow do -- visible_activations has bias units
			if visible_probs[irow][icol] > math.random() then
				 visible_states[irow][icol-1] = 1.0
			else
				 visible_states[irow][icol-1] = 0.0
			end
		end
	end
    return visible_states
end

function M.daydream(rbm, num_samples)
	-- Create a matrix, where each row is to be a sample of the
	-- visible units (with an extra bias unit)
	local samples = {}
	for i_sample = 1, num_samples do     -- initialize a samples matrix
		samples[i_sample]    = {}
		for i_vis = 1, rbm.num_visible+1 do
			if i_vis == 1 then samples[i_sample][1] = 1.0  -- bias unit
			else samples[i_sample][i_vis] = math.random()  -- uniform
			end
		end
	end
	-- Start the alternating Gibbs sampling. Note we keep the hidden units
	-- binary states, but leave the visible units as real probabilities.
	-- See section 3 of Hinton's guideTR.pdf for why...
	for i = 1, num_samples do
		local visible = samples[i]
		-- Calculate the activations of the hidden units
		local hidden_activations = np_dot(visible, rbm.weights)	    
		-- Calculate the probabilities of turning the hidden units on
		local hidden_probs = logistic(hidden_activations)
		-- Turn the hidden units on with their specified probabilities
		local hidden_states = gt_rand(hidden_probs)
		hidden_states[1] = 1.0  -- and restore the bias unit to 1
		-- Recalculate the probabilities that the visible units are on.
		local visible_activations=np_dot(hidden_states,transpose(rbm.weights))
		local visible_probs = logistic(visible_activations)
		local visible_states = gt_rand(visible_probs)
		samples[i] = visible_states
	end
	for i,t in ipairs(samples) do table.remove(t,1) end -- remove bias unit
	return samples
end

function M.vis2labels (rbm, data)
	if not rbm.labels then return data end
	if type(data[1]) == 'table' then
		local a = {}
		for i,v in ipairs(data) do a[i] = M.vis2labels(rbm, v) end
		return a
	end
	local a = {}
	for i,v in ipairs(data) do
		if v > 0.5 then a[#a+1] = rbm.labels[i] end
	end
	return a
end

-------------------------- from Word2vec -----------------------

function M.cosineSimilarity(a, b)
	-- In cosine similarity, "no similarity" of 0 is a 90 degree angle,
	-- while "total similarity" of 1 is a 0 degree angle
	if type(a) == 'string' then a = {a:byte(1,-1)} end  -- PiL2 p.177
	if type(b) == 'string' then b = {b:byte(1,-1)} end
	local dotProduct = 0.0
	local norm_a     = 0.0
	local norm_b     = 0.0
	-- Could subtract the array's averages, to get similarity of the _shapes_
	-- Or for text, could just count the length of the diff ...
	-- http://sputnik.freewisdom.org/lib/diff/  does not look useful :-(
	-- so see analyze.c in http://gnu.uberglobalmirror.com/diffutils/
	-- tar xvJf /home/dist/diffutils-3.4.tar.xz   20Kb ...
	-- but that fails to recognise the kinship between transpositions :-(
	for i = 1,#a do
		if i > #b then break end
		dotProduct = dotProduct + a[i]*b[i]
		norm_a     = norm_a + a[i]*a[i]
		norm_b     = norm_b + b[i]*b[i]
	end
	return dotProduct / (math.sqrt(norm_a) * math.sqrt(norm_b))
end

return M

--[=[

=pod

=head1 NAME

rbm.lua - a re-expression in lua of rbm.py

=head1 SYNOPSIS

  RBM = require 'rbm'
  r = RBM.new_rbm({ 6, 2,
   labels={'Potter','Avatar','LOTR3','Gladiator','Titanic','Glitter'}
  }) -- 6 visibles; 2 hiddens wanted
  training_data = {
    {1,1,1,0,0,0}, {1,0,1,0,0,0}, {1,1,1,0,0,0},
    {0,0,1,1,1,0}, {0,0,1,1,0,0}, {0,0,1,1,1,0}
  }
  RBM.train(r, training_data, 5000)
  -- r stores internally the weights learned during training
  visible_data  = { {0,0,0,1,1,0} }
  -- now which category does this new visible data belong to ?
  hidden_states  = RBM.vis2hid(r, visible_data)
  -- which set of visible data do these hiddens best express ?
  visible_states = RBM.hid2vis(r, hidden_states)
  -- can iterate freely from a random start (ie: daydream)
  samples = RBM.daydream(r, 100) -- iterate 100 times
  sample_labels = RBM.vis2labels(r, samples)  -- make human-readable

=head1 DESCRIPTION

This module is a re-expression in I<Lua> of the file I<rbm.py> in
L<https://github.com/echen/restricted-boltzmann-machines>

Restricted Boltzmann Machines perform a binary version of factor analysis.
Training the RBM tries to discover hidden patterns that categorise
the various configurations of the set of the visible input-variables.

A Restricted Boltzmann Machine is a stochastic neural network,
where "neural" means we have neuron-like units whose binary
activations depend on the neighbors they're connected to,
and "stochastic" means these activations have a probabilistic element.
"Activation" seems to be what Geoff Hinton's 2010 talk (at 2min 30sec)
refers to as "energy" ...
L<https://www.youtube.com/watch?v=VdIURAu1-aU>

An RBM consists of a layer of visible units, and a layer of hidden units.
Each visible unit depends on all the hidden units;
and this connection is undirected,
so also each hidden unit depends on all the visible units.
(Internally, there is also a hidden bias unit, always set to 1.0,
and connected to all the visible units and all the hidden units,
which you shouldn't ever have to worry about.)

The word "I<Restricted>" means that we restrict the network
so that no visible unit is connected to any other visible unit,
and no hidden unit is connected to any other hidden unit.
This makes it equally easy to deduce hidden from visible variables
as the other way round.
This makes it easy to iterate between visible and hidden,
in search of the best correlation.

Much to do ...
See Geoff Hinton 2010 talk, 2min30sec - 10min30sec
Multiple levels !
Back propagation !
Real (not boolean) units ! 9min20sec - 10min30sec
though that talks of real values with a gaussian variation.
For handling I<midi>, perhaps I need L<http://deeplearning4j.org/word2vec>
or some variant ...  Picking out tunes may be more like econometrics ?

=head1 RULES OF THUMB

A rule of thumb for B<choosing the number of hidden units>:
Estimate how many bits it would take to describe each data vector
if you were using a good model (i.e. estimate the typical
negative log2 probability of a datavector under a good model).
Multiply that by the number of training cases, then divide by about ten.
If the training cases are highly redundant, as they typically are
for large training-sets, you'll need to use fewer hidden-units.

The rules are quoted from Geoff Hinton's C<guideTR.pdf>

=head1 FUNCTIONS

=over 3

=item I<rbm = new_rbm{num_visible, num_hidden, learning_rate=0.1,
 labels={'Potter','Avatar','LOTR3','Gladiator','Titanic','Glitter'}}>

This creates a new Recursive Boltzmann Machine,
which will study I<num_visible> variables and
summarise their relationships in I<num_hidden> hidden variables.
The other variables are optional.

If the I<learning_rate> is not given it defaults to 0.1

The I<labels> refer to the visible variables;
therefore, there should be I<num_visible> labels in the list.

=item I<train(rbm, training_data, max_epochs)>

This trains the weights in your new Recursive Boltzmann Machine
on a 2D array of I<training_data>, each element of which is an array of
I<num_visible> numbers.

The function returns nothing, since the weights are stored inside the C<rbm>

If the I<max_epochs> is not given it defaults to 1000

=item I<new_hidden = vis2hid(rbm, visible_data)>

This uses the trained weights to derive the hidden variables from the 
given visible variables.

=item I<new_visible = hid2vis(rbm, hidden_data)>

This uses the trained weights to derive a set of visible variables
back from a set of hidden variables.

=item I<daydream(rbm, num_samples)>

This generates I<num_samples> plausible sets of sample-data.
For each set, it starts with random visible data,
then using I<rbm.weights> to extract the corresponding hidden data,
then using I<rbm.weights> again to generate a plausible set of visible data.

=item I<vis2labels (rbm, visible_data)>

This converts the I<visible_data> in its {0,0,1,0,1,0} form
into a list of the labels

=back

=head1 DOWNLOAD

This module is available at
L<http://www.pjb.com.au/comp/lua/rbm.html>

=head1 AUTHOR

Peter J Billam, L<http://www.pjb.com.au/comp/contact.html>

=head1 SEE ALSO

 http://www.pjb.com.au/
 http://www.pjb.com.au/comp/lua/rbm.html
 https://github.com/echen/restricted-boltzmann-machines
 http://blog.echen.me/2011/07/18/introduction-to-restricted-boltzmann-machines/
 http://deeplearning4j.org/restrictedboltzmannmachine.html
 http://deeplearning4j.org/understandingRBMs.html
 http://learning.cs.toronto.edu
 http://www.cs.toronto.edu/~hinton/
 https://en.wikipedia.org/wiki/Geoffrey_Hinton
 http://www.cs.toronto.edu/~hinton/absps/guideTR.pdf
 http://docs.scipy.org/doc/numpy/reference/generated/numpy.dot.html
 https://www.youtube.com/watch?v=VdIURAu1-aU      2010 google talk
 https://www.youtube.com/watch?v=GJdWESd543Y      2012 IPAM summer school

=cut

]=]

