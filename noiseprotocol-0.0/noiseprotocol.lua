---------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2011, Peter J Billam      --
--                       www.pjb.com.au                            --
--                                                                 --
--  This module is free software; you can redistribute it and/or   --
--         modify it under the same terms as Lua5 itself.          --
---------------------------------------------------------------------
-- https://rweather.github.io/noise-c/group__handshakestate.html
-- https://rweather.github.io/noise-c/group__cipherstate.html

local M = {} -- public interface
M.Version     = '0.0' -- 
M.VersionDate = '18feb2021'

------------------------------ private ------------------------------
local function warn(str) io.stderr:write(str,'\n') end
local function die(str) io.stderr:write(str,'\n') ;  os.exit(1) end
local function qw(s)  -- t = qw[[ foo  bar  baz ]]
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

----------------- from Lua Programming Gems p. 331 ----------------
local require, table = require, table -- save the used globals
local aux, prv = {}, {} -- auxiliary & private C function tables
local initialise = require 'C-noiseprotocol'
initialise(aux, prv, M) -- initialise the C lib with aux,prv & module tables

----------------- public functions  -----------------
--[[
https://rweather.github.io/noise-c/group__handshakestate.html

int  noise_handshakestate_fallback (NoiseHandshakeState *state)
  Falls back to the "XXfallback" handshake pattern.
 
int  noise_handshakestate_fallback_to
 (NoiseHandshakeState *state, int pattern_id)
  Falls back to another handshake pattern.
 
int  noise_handshakestate_free (NoiseHandshakeState *state)
  Frees a HandshakeState object after destroying all sensitive material.
 
int  noise_handshakestate_get_action (const NoiseHandshakeState *state)
  Gets the next action the application should perform
  for the handshake phase of the protocol.
 
NoiseDHState *  noise_handshakestate_get_fixed_ephemeral_dh
  (NoiseHandshakeState *state)
  Gets the DHState object that contains the local ephemeral keypair.
 
NoiseDHState *  noise_handshakestate_get_fixed_hybrid_dh
  (NoiseHandshakeState *state)
  Gets the DHState object that contains
  the local additional hybrid secrecy keypair.
 
int  noise_handshakestate_get_handshake_hash
  (const NoiseHandshakeState *state, uint8_t *hash, size_t max_len)
  Gets the handshake hash value once the handshake ends.
 
NoiseDHState *  noise_handshakestate_get_local_keypair_dh
  (const NoiseHandshakeState *state)
  Gets the DHState object that contains the local static keypair.
 
int  noise_handshakestate_get_protocol_id
  (const NoiseHandshakeState *state, NoiseProtocolId *id)
  Gets the protocol identifier associated with a HandshakeState object.
 
NoiseDHState *  noise_handshakestate_get_remote_public_key_dh
  (const NoiseHandshakeState *state)
  Gets the DHState object that contains the remote static public key.
 
int  noise_handshakestate_get_role (const NoiseHandshakeState *state)
  Gets the role that a HandshakeState object is playing.
 
int  noise_handshakestate_has_local_keypair (const NoiseHandshakeState *state)
  Determine if a HandshakeState has been configured with a local keypair.
 
int  noise_handshakestate_has_pre_shared_key
  (const NoiseHandshakeState *state)
  Determine if a HandshakeState object has already been
  configured with a pre shared key.
 
int  noise_handshakestate_has_remote_public_key
  (const NoiseHandshakeState *state)
  Determine if a HandshakeState has a remote public key.
 
int  noise_handshakestate_needs_local_keypair
  (const NoiseHandshakeState *state)
  Determine if a HandshakeState still needs to be configured
  with a local keypair.
 
int  noise_handshakestate_needs_pre_shared_key
  (const NoiseHandshakeState *state)
  Determine if a HandshakeState object requires a pre shared key.
 
int  noise_handshakestate_needs_remote_public_key
  (const NoiseHandshakeState *state)
  Determine if a HandshakeState still needs to be configured
  with a remote public key before the protocol can start.
 
int  noise_handshakestate_new_by_id (NoiseHandshakeState **state,
  const NoiseProtocolId *protocol_id, int role)
  Creates a new HandshakeState object by protocol identifier.
 
int  noise_handshakestate_new_by_name (NoiseHandshakeState **state,
  const char *protocol_name, int role)
  Creates a new HandshakeState object by protocol name.
 
int  noise_handshakestate_read_message (NoiseHandshakeState *state,
  NoiseBuffer *message, NoiseBuffer *payload)
  Reads a message payload using a HandshakeState.
 
int  noise_handshakestate_set_pre_shared_key (NoiseHandshakeState *state,
  const uint8_t *key, size_t key_len)
  Sets the pre shared key for a HandshakeState.
 
int  noise_handshakestate_set_prologue (NoiseHandshakeState *state,
  const void *prologue, size_t prologue_len)
  Sets the prologue for a HandshakeState.
 
int  noise_handshakestate_split (NoiseHandshakeState *state,
  NoiseCipherState **send, NoiseCipherState **receive)
  Splits the transport encryption CipherState objects
  out of this HandshakeState object.
 
int  noise_handshakestate_start (NoiseHandshakeState *state)
  Starts the handshake on a HandshakeState object.
 
int  noise_handshakestate_write_message (NoiseHandshakeState *state,
  NoiseBuffer *message, const NoiseBuffer *payload)
  Writes a message payload using a HandshakeState.
]]
--[[
https://rweather.github.io/noise-c/group__cipherstate.html

CipherState objects are used to encrypt or decrypt data during a
session. Once the handshake has completed, noise_symmetricstate_split()
will create two CipherState objects for encrypting packets sent to the
other party, and decrypting packets received from the other party.

int  noise_cipherstate_decrypt (NoiseCipherState *state, NoiseBuffer *buffer)
  Decrypts a block of data with this CipherState object.
 
int  noise_cipherstate_decrypt_with_ad (NoiseCipherState *state,
  const uint8_t *ad, size_t ad_len, NoiseBuffer *buffer)
  Decrypts a block of data with this CipherState object.
 
int  noise_cipherstate_encrypt (NoiseCipherState *state, NoiseBuffer *buffer)
  Encrypts a block of data with this CipherState object.
 
int  noise_cipherstate_encrypt_with_ad (NoiseCipherState *state,
  const uint8_t *ad, size_t ad_len, NoiseBuffer *buffer)
  Encrypts a block of data with this CipherState object.
 
int  noise_cipherstate_free (NoiseCipherState *state)
  Frees a CipherState object after destroying all sensitive material.
 
int  noise_cipherstate_get_cipher_id (const NoiseCipherState *state)
  Gets the algorithm identifier for a CipherState object.
 
size_t  noise_cipherstate_get_key_length (const NoiseCipherState *state)
  Gets the length of the encryption key for a CipherState object.
 
size_t  noise_cipherstate_get_mac_length (const NoiseCipherState *state)
  Gets the length of packet MAC values for a CipherState object.
 
int  noise_cipherstate_get_max_key_length (void)
  Gets the maximum key length for the supported algorithms.
 
int  noise_cipherstate_get_max_mac_length (void)
  Gets the maximum MAC length for the supported algorithms.
 
int  noise_cipherstate_has_key (const NoiseCipherState *state)
  Determine if the key has been set on a CipherState object.
 
int  noise_cipherstate_init_key (NoiseCipherState *state,
  const uint8_t *key, size_t key_len)
  Initializes the key on a CipherState object.
 
int  noise_cipherstate_new_by_id (NoiseCipherState **state, int id)
  Creates a new CipherState object by its algorithm identifier.
 
int  noise_cipherstate_new_by_name (NoiseCipherState **state,
  const char *name)
  Creates a new CipherState object by its algorithm name.
 
int  noise_cipherstate_set_nonce (NoiseCipherState *state, uint64_t nonce)
  Sets the nonce value for this cipherstate object.

]]

function M.strerror(err)
	
end

function M.handshakestate_fallback(dhstate_id)
	-- Falls back to the "XXfallback" handshake pattern
	local err = c_handshakestate_fallback(dhstate_id)
	if err ~= NOISE_ERROR_NONE then return nil, c_strerror(err) end
	return true
end
function M.handshakestate_fallback_to(dhstate_id)
	-- Falls back to another handshake pattern
	local err = c_handshakestate_fallback_to(dhstate_id)
	if err ~= NOISE_ERROR_NONE then return nil, c_strerror(err) end
	return true
end
function M.handshakestate_free(dhstate_id)
	-- Frees a HandshakeState object after destroying all sensitive material
	local err = c_handshakestate_free(dhstate_id)
	if err ~= NOISE_ERROR_NONE then return nil, c_strerror(err) end
	return nil
end
function M.handshakestate_get_action(dhstate_id)
	-- Gets the next action the application should perform
	--  for the handshake phase of the protocol
	local err = c_handshakestate_get_action(dhstate_id)
	if err ~= NOISE_ERROR_NONE then return nil, c_strerror(err) end
	return nil
end
function M.handshakestate_get_fixed_ephemeral_dh(dhstate_id)
	-- Gets the DHState object that contains the local ephemeral keypair
	local dhstate = c_handshakestate_get_fixed_ephemeral_dh(dhstate_id)
	return dhstate
end
function M.handshakestate_get_fixed_hybrid_dh(dhstate_id)
	-- Gets the DHState object that contains
	-- the local additional hybrid secrecy keypair
	local dhstate = c_handshakestate_get_fixed_hybrid_dh(dhstate_id)
	return dhstate
end
function M.handshakestate_get_handshake_hash(dhstate_id)
	-- Gets the handshake hash value once the handshake ends
	local dhstate = c_handshakestate_get_handshake_hash(dhstate_id)
	return dhstate
end
function M.handshakestate_get_local_keypair_dh(dhstate_id)
	-- Gets the DHState object that contains the local static keypair
	local dhstate = c_handshakestate_get_local_keypair_dh(dhstate_id)
	return dhstate
end
function M.handshakestate_get_protocol_id(dhstate_id)
	-- Gets the protocol identifier associated with a HandshakeState object
	local err = c_handshakestate_get_protocol_id(dhstate_id, protocol_id)
	return protocol_id
end
function M.handshakestate_get_remote_public_key_dh(dhstate_id)
	-- Gets the DHState object that contains the remote static public key
	local err = c_handshakestate_get_remote_public_key_dh(dhstate_id)
	return protocol_id
end
function M.handshakestate_get_role(dhstate_id)
	-- Gets the role that a HandshakeState object is playing
	local err = c_handshakestate_get_role(dhstate_id)
	return err
end
function M.handshakestate_has_local_keypair(dhstate_id)
	-- Determine if a HandshakeState has been configured with a local keypair
	local err = c_handshakestate_get_role(dhstate_id)
	return err
end
function M.handshakestate_has_pre_shared_key(dhstate_id)
	-- Determine if a HandshakeState object has already been
	-- configured with a pre shared key
	local err = c_handshakestate_has_pre_shared_key(dhstate_id)
	return err
end
function M.handshakestate_has_remote_public_key(dhstate_id)
	-- Determine if a HandshakeState has a remote public key
	local err = c_handshakestate_has_remote_public_key(dhstate_id)
	return err
end
function M.handshakestate_needs_local_keypair(dhstate_id)
	-- Determine if a HandshakeState still needs to be configured
	-- with a local keypair
	local err = c_handshakestate_needs_local_keypair(dhstate_id)
	return err
end
function M.handshakestate_needs_pre_shared_key(dhstate_id)
	-- Determine if a HandshakeState object requires a pre shared key
	local err = c_handshakestate_needs_pre_shared_key(dhstate_id)
	return err
end
function M.handshakestate_needs_remote_public_key(dhstate_id)
	-- Determine if a HandshakeState still needs to be configured
	-- with a remote public key before the protocol can start.
	local err = c_handshakestate_needs_remote_public_key(dhstate_id)
	return err
end
function M.handshakestate_new_by_id(dhstate_id, protocol_id, role)
	-- Creates a new HandshakeState object by protocol identifier
	local err = c_handshakestate_new_by_id(dhstate_id, protocol_id, role)
	return err
end
function M.handshakestate_new_by_name(dhstate_id, protocol_name, role)
	-- Creates a new HandshakeState object by protocol name
	local err = c_handshakestate_new_by_name(dhstate_id, protocol_name, role)
	return err
end
function M.handshakestate_read_message(dhstate_id)
	-- Reads a message payload using a HandshakeState
	local err = c_handshakestate_read_message(dhstate_id, message, payload)
	return message, payload
end
function M.handshakestate_set_pre_shared_key(dhstate_id, key)
	-- Sets the pre shared key for a HandshakeState
	local err = c_handshakestate_set_pre_shared_key(dhstate_id, key, key_len)
	return message, payload
end
function M.handshakestate_set_prologue(dhstate_id, prologue)
	-- Sets the prologue for a HandshakeState
	local err = c_handshakestate_set_prologue(dhstate_id, key, key_len)
	return message, payload
end
function M.handshakestate_split(dhstate_id, prologue)
	-- Splits the transport encryption CipherState objects
	-- out of this HandshakeState object
	local err = c_handshakestate_split(dhstate_id, send, receive)
	return message, payload
end
function M.handshakestate_start(dhstate_id)
	-- Starts the handshake on a HandshakeState object
	local err = c_handshakestate_start(dhstate_id, key, key_len)
	return message, payload
end
function M.handshakestate_write_message(dhstate_id, message, payload)
	-- Writes a message payload using a HandshakeState
	local err = c_handshakestate_write_message(dhstate_id, message, payload)
	return message, payload
end

-- CipherState objects are used to encrypt or decrypt data during a
-- session. Once the handshake has completed, noise_symmetricstate_split()
-- will create two CipherState objects for encrypting packets sent to the
-- other party, and decrypting packets received from the other party.

function M.cipherstate_decrypt(cistate_id, buffer)
	-- Decrypts a block of data with this CipherState object
	local err = c_cipherstate_decrypt(cistate_id, buffer)
	return err
end
function M.cipherstate_decrypt_with_ad(cistate_id, ad, buffer)
	-- Decrypts a block of data with this CipherState object
	local err = c_cipherstate_decrypt_with_ad(cistate_id, buffer)
	return err
end
function M.cipherstate_encrypt(cistate_id, buffer)
	-- Decrypts a block of data with this CipherState object
	local err = c_cipherstate_encrypt(cistate_id, buffer)
	return err
end
function M.cipherstate_encrypt_with_ad(cistate_id, ad, buffer)
	-- Decrypts a block of data with this CipherState object
	local err = c_cipherstate_encrypt_with_ad(cistate_id, buffer)
	return err
end
function M.cipherstate_free(cistate_id)
	-- Frees a CipherState object after destroying all sensitive material
	local err = c_cipherstate_free(cistate_id, buffer)
	return err
end
function M.cipherstate_get_cipher_id(cistate_id)
	-- Gets the algorithm identifier for a CipherState object
	local err = c_cipherstate_get_cipher_id(cistate_id, buffer)
	return err
end
function M.cipherstate_get_key_length(cistate_id)
	-- Gets the length of the encryption key for a CipherState object
	local len = c_cipherstate_get_key_length(cistate_id, buffer)
	return len
end
function M.cipherstate_get_mac_length(cistate_id)
	-- Gets the length of packet MAC values for a CipherState object
	local len = c_cipherstate_get_mac_length(cistate_id, buffer)
	return len
end
function M.cipherstate_get_max_key_length()
	-- Gets the maximum key length for the supported algorithms
	local len = c_cipherstate_get_max_key_length()
	return len
end
function M.cipherstate_get_max_mac_length()
	-- Gets the maximum MAC length for the supported algorithms
	local len = c_cipherstate_get_max_mac_length()
	return len
end
function M.cipherstate_has_key(cistate_id)
	-- Determine if the key has been set on a CipherState object
	local rc = c_cipherstate_has_key(cistate_id)
	return rc ~= 0
end
function M.cipherstate_init_key(cistate_id, key)
	-- Initializes the key on a CipherState object
	local err = c_cipherstate_init_key(cistate_id, key, #key)
	return err
end
function M.cipherstate_new_by_id(cistate_id, alg_id)
	-- Creates a new CipherState object by its algorithm identifier
	local cs_id = c_cipherstate_new_by_id(cistate_id, alg_id)
	return cs_id
end
function M.cipherstate_new_by_name(cistate_id, name)
	-- Creates a new CipherState object by its algorithm name
	local cs_id = c_cipherstate_new_by_name(cistate_id, name)
	return cs_id
end
function M.cipherstate_set_nonce(cistate_id, name)
	-- Sets the nonce value for this cipherstate object
	local err = c_cipherstate_set_nonce(cistate_id, name)
	return err
end

-- make M readOnly, very classy...
-- BUT it backfires;  for k,v in pairs(ALSA) do print(k) end  fails :-(
-- local readonly_proxy = {}
-- local mt = { -- create metatable, see Programming in Lua p.127
-- 	__index = M,
-- 	__newindex = function (M,k,v)
-- 		warn('midialsa: attempt to update the module table')
-- 	end
-- }
-- setmetatable(readonly_proxy, mt)
-- return readonly_proxy
return M  -- 20111028

--[=[

=pod

=head1 NAME

noiseprotocol.lua - the noiseprotocol library, plus some interface functions

=head1 SYNOPSIS

 local NP = require 'noiseprotocol'
 NP.client( 'Lua client', 1, 1, false )
 NP.connectfrom( 0, 20, 0 )    --  input port is lower (0)
 NP.connectto( 1, 'TiMidity' )  -- output port is higher (1)
 while true do
     local alsaevent = NP.input()
     if alsaevent[1] == NP.SND_SEQ_EVENT_PORT_UNSUBSCRIBED then break end
     if alsaevent[1] == NP.SND_SEQ_EVENT_NOTEON then 
         local channel  = alsaevent[8][1]
         local pitch    = alsaevent[8][2]
         local velocity = alsaevent[8][3]
     elseif alsaevent[1] == NP.SND_SEQ_EVENT_CONTROLLER then
         local channel    = alsaevent[8][1]
         local controller = alsaevent[8][5]
         local value      = alsaevent[8][6]
     end
     NP.output( alsaevent )
 end

=head1 DESCRIPTION

This module offers a Lua interface to the I<noiseprotocol> library.

=head1 FUNCTIONS

Functions based on those in I<alsaseq.py>:
client(), connectfrom(), connectto(), disconnectfrom(), disconnectto(), fd(),
id(), input(), inputpending(), output(), start(), status(), stop(), syncoutput()

Functions based on those in I<alsamidi.py>:
noteevent(), noteonevent(), noteoffevent(), pgmchangeevent(),
pitchbendevent(), controllerevent(), chanpress(), sysex()

Functions to interface with I<MIDI.lua>:
alsa2scoreevent(), scoreevent2alsa()

Functions to get the current ALSA status:
listclients(), listnumports(), listconnectedto(), listconnectedfrom(),
parse_address()

=over 3

=item I<client>(name, ninputports, noutputports, createqueue)

Create an ALSA sequencer client with zero or more input or output
ports, and optionally a timing queue.  ninputports and noutputports
are created if the quantity requested is between 1 and 64 for each.
If createqueue = true, it creates a queue for stamping the arrival time
of incoming events and scheduling future start times of outgoing events.

For full ALSA functionality, the I<name>
should contain only letters, digits, underscores or spaces,
and should contain at least one letter.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

=item I<connectfrom>( inputport, src_client, src_port )

Connect from src_client:src_port to inputport. Each input port can connect
from more than one client. The input() function will receive events
from any intput port and any of the clients connected to each of them.
Events from each client can be distinguised by their source field.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

Unlike in the I<alsaseq.py> Python module,
if I<src_client> is a string and I<src_port> is undefined,
then I<parse_address(src_client)> automatically gets invoked.
This allows you, if you have already invoked I<client(...)>,
to refer to the I<src_client> by name, for example
connectfrom(inputport,'Virtual:1') will connect from
port 1 of the 'Virtual Raw MIDI' client.

=item I<connectto>( outputport, dest_client, dest_port )

Connect outputport to dest_client:dest_port. Each outputport can be
Connected to more than one client. Events sent to an output port using
the output()  funtion will be sent to all clients that are connected to
it using this function.

Unlike in the I<alsaseq.py> Python module, it returns success or failure.

Unlike in the I<alsaseq.py> Python module,
if I<dest_client> is a string and I<dest_port> is undefined,
then I<parse_address(dest_client)> automatically gets invoked.
This allows you, if you have already invoked I<client(...)>,
to refer to the I<dest_client> by name, for example
connectto(outputport,'Roland XV-2020') will connect to
port 0 of the 'Roland XV-2020' client.


=item I<disconnectfrom>( inputport, src_client, src_port )

Disconnect the connection
from the remote I<src_client:src_port> to my I<inputport>.
Returns success or failure.

Unlike in the I<alsaseq.py> Python module,
if I<src_client> is a string and I<src_port> is undefined,
then I<parse_address(src_client)> automatically gets invoked.
This allows you to refer to the remote I<src_client> by name, for example
disconnectfrom(inputport,'Virtual:1') will disconnect from
port 1 of the 'Virtual Raw MIDI' client.

=item I<disconnectto>( outputport, dest_client, dest_port )

Disconnect the connection
from my I<outputport> to the remote I<dest_client:dest_port>.
Returns success or failure.

Unlike in the I<alsaseq.py> Python module,
if I<dest_client> is a string and I<dest_port> is undefined,
then I<parse_address(dest_client)> automatically gets invoked.
This allows you to refer to the I<dest_client> by name, for example
disconnectto(outputport,'Virtual:2') will disconnect to
port 2 of the 'Virtual Raw MIDI' client.

=item I<fd>()

Return fileno of sequencer.

=item I<id>()

Return the client number, or 0 if the client is not yet created.

=item I<input>()

Wait for an ALSA event in any of the input ports and return it.
ALSA events are returned as an array with 8 elements:

 {type, flags, tag, queue, time, source, destination, data}

Unlike in the I<alsaseq.py> Python module,
the time element is in floating-point seconds.
The last three elements are also arrays:

 source = { src_client,  src_port }
 destination = { dest_client,  dest_port }
 data = { varies depending on type }

The I<source> and I<destination> arrays may be useful within an application
for handling events differently according to their source or destination.
The event-type constants, beginning with SND_SEQ_,
are available as module variables:

 ALSA = require 'midialsa'
 for k,v in pairs(ALSA) do print(k) end

The data array is mostly as documented in
http://alsa-project.org/alsa-doc/alsa-lib/seq.html.
For NOTE events,  the elements are
{ channel, pitch, velocity, unused, duration };
where since version 1.15 the I<duration> is in floating-point seconds
(unlike in the I<alsaseq.py> Python module where it is in milliseconds).
For SYSEX events, the data array contains just one element:
the byte-string, including any F0 and F7 bytes.
For most other events,  the elements are
{ channel, unused,unused,unused, param, value }

The I<channel> element is always 0..15

In the SND_SEQ_EVENT_PITCHBEND event
the I<value> element is from -8192..+8191 (not 0..16383)

If a connection terminates, then input() returns,
and the next event will be of type SND_SEQ_EVENT_PORT_UNSUBSCRIBED

Note that if the event is of type SND_SEQ_EVENT_PORT_SUBSCRIBED
or SND_SEQ_EVENT_PORT_UNSUBSCRIBED,
then that message has come from the System,
and its I<dest_port> tells you which of your ports is involved.
But its I<src_client> and I<src_port> do not tell you which other client
disconnected;  you'll need to use I<listconnectedfrom()>
or I<listconnectedto()> to see what's happened.

=item I<inputpending>()

Returns the number of bytes available in the input buffer.
Use before input() to check whether an event is ready to be read. 

=item I<output>( {type, flags, tag, queue, time, source, destination, data} )

Send an ALSA-event from an output port.
The format of the event is as discussed in input() above.
The event will be output immediately
either if no queue was created in the client
or if the I<queue> parameter is set to SND_SEQ_QUEUE_DIRECT,
and otherwise it will be queued and scheduled.

The I<source> is an array with two elements: {src_client, src_port},
specifying the local output-port from which the event will be sent.
If only one output-port exists, all events are sent from it.
If two or more exist, the I<src_port> determines which to use.
The smallest available port-number (as created by I<client>())
will be used if I<src_port> is less than it,
and the largest available will be used if I<src_port> is greater than it.

The I<destination> is an array with two elements: {dest_client, dest_port},
specifying the remote client/port to which the event will be sent.
If I<dest_client> is zero
(as generated by I<scoreevent2alsa()> or I<noteevent()>),
or is the same as the local client
(as generated by I<input()>),
then the event will be sent to all clients that the local port is connected to
(see I<connectto>() and I<listconnectedto()>).
But if you set I<dest_client> to a remote client,
then the event will be sent to that
I<dest_client:dest_port> and nowhere else.

It is possible to send an event to a destination to which there
is no connection, but it's not usually
the right thing to do. Normally, you should set up a connection,
to allow the underlying RawMIDI ports to remain open while
playing - otherwise, ALSA will reset the port after every event.

If the queue buffer is full, output() will wait
until space is available to output the event.
Use status() to know how many events are scheduled in the queue.

=item I<start>()

Start the queue. It is ignored if the client does not have a queue. 

=item I<status>()

Return { status, time, events } of the queue.

 Status: 0 if stopped, 1 if running.
 Time: current time in seconds.
 Events: number of output events scheduled in the queue.

If the client does not have a queue the value {0,0,0} is returned.
Unlike in the I<alsaseq.py> Python module,
the I<time> element is in floating-point seconds.

=item I<stop>()

Stop the queue. It is ignored if the client does not have a queue. 

=item I<syncoutput>()

Wait until output events are processed.

=item I<noteevent>( ch, key, vel, start, duration )

Returns an ALSA-event-array, to be scheduled by output().
Unlike in the I<alsaseq.py> Python module,
the I<start> and I<duration> elements are in floating-point seconds.

=item I<noteonevent>( ch, key, vel, start )

Returns an ALSA-event-array, to be scheduled by output().
If I<start> is not used, the event will be sent directly.
Unlike in the I<alsaseq.py> Python module.
if I<start> is provided, the event will be scheduled in a queue. 
The I<start> element, when provided, is in floating-point seconds.

=item I<noteoffevent>( ch, key, vel, start )

Returns an ALSA-event-array, to be scheduled by output().
If I<start> is not used, the event will be sent directly.
Unlike in the I<alsaseq.py> Python module,
if I<start> is provided, the event will be scheduled in a queue. 
The I<start> element, when provided, is in floating-point seconds.


=item I<pgmchangeevent>( ch, value, start )

Returns an ALSA-event-array for a I<patch_change> event to be sent by output().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item I<pitchbendevent>( ch, value, start )

Returns an ALSA-event-array to be sent by output().
The value is from -8192 to 8191.
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item I<controllerevent>( ch, controllernum, value, start )

Returns an ALSA-event-array to be sent by output().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item I<chanpress>( ch, value, start )

Returns an ALSA-event-array to be sent by output().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
Unlike in the I<alsaseq.py> Python module,
the I<start> element, when provided, is in floating-point seconds.

=item sysex( $ch, $string, $start )

Returns an ALSA-event-array to be sent by output().
If I<start> is not used, the event will be sent directly;
if I<start> is provided, the event will be scheduled in a queue. 
The string should start with your Manufacturer ID,
but should not contain any of the F0 or F7 bytes,
they will be added automatically;
indeed the string must not contain any bytes with the top-bit set.

=item I<alsa2scoreevent>( alsaevent )

Returns an event in the millisecond-tick score-format
used by the I<MIDI.lua> and I<MIDI.py> modules,
based on the score-format in Sean Burke's MIDI-Perl CPAN module. See:
 http://www.pjb.com.au/comp/lua/MIDI.html#events

Since it combines a I<note_on> and a I<note_off> event into one note event,
it will return I<nil> when called with the I<note_on> event;
the calling loop must therefore detect I<nil>
and not, for example, try to index it.

=item I<scoreevent2alsa>( event )

Returns an ALSA-event-array to be scheduled in a queue by output().
The input is an event in the millisecond-tick score-format
used by the I<MIDI.lua> and I<MIDI.py> modules,
based on the score-format in Sean Burke's MIDI-Perl CPAN module. See:
http://www.pjb.com.au/comp/lua/MIDI.html#events 
For example:

 ALSA.output(ALSA.scoreevent2alsa{'note',4000,1000,0,62,110})

Some events in a .mid file have no equivalent
real-time-midi event, which is the sort that ALSA deals in;
these events will cause scoreevent2alsa() to return nil.
Therefore if you are going through the events in a midi score
converting them with scoreevent2alsa(),
you should check that the result is not nil before doing anything further.

=item listclients()

Returns a table with the client-numbers as key
and the descriptive strings of the ALSA client as value :

 local clientnumber2clientname = ALSA.listclients()

=item listnumports()

Returns a table with the client-numbers as key
and how many ports they are running as value,
so if a client is running 4 ports they will be numbered 0..3

 local clientnumber2howmanyports = ALSA.listnumports()

=item listconnectedto()

Returns an array of three-element arrays
{ {outputport, dest_client, dest_port}, }
with the same data as might have been passed to connectto(),
or which could be passed to disconnectto().

=item listconnectedfrom()

Returns an array of three-element arrays
{ {inputport, src_client, src_port}, }
with the same data as might have been passed to connectfrom(),
or which could be passed to disconnectfrom().

=item parse_address( client_name )

Given a string, this function returns two integers,
client_number and port_number,
as might be needed by I<connectto>() or I<connectfrom>().
For example, even if I<client>() has not been called,
"24" will return 24,0 and "25:1" will return 25,1

If the local client is running, then parse_address() 
also looks up names. For example, if C<aconnect -oil>
reveals a I<timidity> client:

 client 128: 'TiMidity' [type=user]

then parse_address("TiM") will return 128,0
and parse_address("TiMi:1") will return 128,1
because it finds the first client with a start-of-string
case-sensitive match to the given name.
parse_address() is called automatically by I<connectto>(),
I<connectfrom>(), I<disconnectto>() and I<disconnectfrom>()
if they are called with the second argument a string 
and the third argument undefined.
parse_address() was introduced in version 1.11 and is not present in
the alsaseq.py Python module.

=back

=head1 CONSTANTS

SND_SEQ_EVENT_BOUNCE    SND_SEQ_EVENT_CHANPRESS   SND_SEQ_EVENT_CLIENT_CHANGE
SND_SEQ_EVENT_CLIENT_EXIT SND_SEQ_EVENT_CLIENT_START SND_SEQ_EVENT_CLOCK
SND_SEQ_EVENT_CONTINUE  SND_SEQ_EVENT_CONTROL14   SND_SEQ_EVENT_CONTROLLER
SND_SEQ_EVENT_ECHO      SND_SEQ_EVENT_KEYPRESS    SND_SEQ_EVENT_KEYSIGN
SND_SEQ_EVENT_NONE      SND_SEQ_EVENT_NONREGPARAM SND_SEQ_EVENT_NOTE
SND_SEQ_EVENT_NOTEOFF   SND_SEQ_EVENT_NOTEON      SND_SEQ_EVENT_OSS
SND_SEQ_EVENT_PGMCHANGE SND_SEQ_EVENT_PITCHBEND   SND_SEQ_EVENT_PORT_CHANGE
SND_SEQ_EVENT_PORT_EXIT SND_SEQ_EVENT_PORT_START  SND_SEQ_EVENT_PORT_SUBSCRIBED
SND_SEQ_EVENT_PORT_UNSUBSCRIBED SND_SEQ_EVENT_QFRAME SND_SEQ_EVENT_QUEUE_SKEW
SND_SEQ_EVENT_REGPARAM  SND_SEQ_EVENT_RESET       SND_SEQ_EVENT_RESULT
SND_SEQ_EVENT_SENSING   SND_SEQ_EVENT_SETPOS_TICK SND_SEQ_EVENT_SETPOS_TIME
SND_SEQ_EVENT_SONGPOS   SND_SEQ_EVENT_SONGSEL     SND_SEQ_EVENT_START
SND_SEQ_EVENT_STOP      SND_SEQ_EVENT_SYNC_POS    SND_SEQ_EVENT_SYSEX
SND_SEQ_EVENT_SYSTEM    SND_SEQ_EVENT_TEMPO       SND_SEQ_EVENT_TICK
SND_SEQ_EVENT_TIMESIGN  SND_SEQ_EVENT_TUNE_REQUEST SND_SEQ_EVENT_USR0
SND_SEQ_EVENT_USR1      SND_SEQ_EVENT_USR2        SND_SEQ_EVENT_USR3
SND_SEQ_EVENT_USR4      SND_SEQ_EVENT_USR5        SND_SEQ_EVENT_USR6
SND_SEQ_EVENT_USR7      SND_SEQ_EVENT_USR8        SND_SEQ_EVENT_USR9
SND_SEQ_EVENT_USR_VAR0  SND_SEQ_EVENT_USR_VAR1    SND_SEQ_EVENT_USR_VAR2
SND_SEQ_EVENT_USR_VAR3  SND_SEQ_EVENT_USR_VAR4    SND_SEQ_QUEUE_DIRECT
SND_SEQ_TIME_STAMP_REAL

The MIDI standard specifies that a NOTEON event with velocity=0 means
the same as a NOTEOFF event; so you may find a little function like
this convenient:

 local function is_noteoff(alsaevent)
    if alsaevent[1] == ALSA.SND_SEQ_EVENT_NOTEOFF then return true end
    if alsaevent[1] == ALSA.SND_SEQ_EVENT_NOTEON
      and alsaevent[8][3] == 0 then
        return true
    end
    return false
 end

Since Version 1.20, the output-ports are marked as WRITE,
so they can receive
SND_SEQ_EVENT_PORT_SUBSCRIBED or SND_SEQ_EVENT_PORT_UNSUBSCRIBED
events from I<System Announce>.
Up until Version 1.19, and in the original Python module,
output-ports created by client() were not so marked;
in those days, if knowing about connections and disconnections to the
output-port was important, you had to listen to all notifications from
I<System Announce>:
C<ALSA.connectfrom(0,'System:1')>
This alerted you unnecessarily to events which didn't involve your client,
and the connection showed up confusingly
in the output of C<aconnect -oil>

=head1 DOWNLOAD

This module is available as a LuaRock in
http://luarocks.org/modules/peterbillam
so you should be able to install it with the command:

 $ su
 Password:
 # luarocks install midialsa

or:

 # luarocks install http://www.pjb.com.au/comp/lua/midialsa-1.24-0.rockspec

The Perl version is available from CPAN at
http://search.cpan.org/perldoc?MIDI::ALSA

=head1 CHANGES

 20150425 1.24 
 20150421 1.23 include lua5.3, and move pod and doc back to luarocks.org
 20150416 1.22 asound and asoundlib.h specified as external dependencies
 20140609 1.21 switch pod and doc over to using moonrocks
 20140416 1.20 output-ports marked WRITE so they can receive UNSUBSCRIBED
 20140404 1.19 (dis)connect(to,from) use the new parse_address; some doc fixes
 20130514 1.18 parse_address matches startofstring to hide alsa-lib 1.0.24 bug
 20130211      noteonevent and noteoffevent accept a start parameter
 20121208 1.17 test script handles alsa_1.0.16 quirk
 20121205 1.16 queue_id; test script prints better diagnostics; 5.2-compatible
 20111112 1.15 (dis)?connect(from|to) return nil if parse_address fails
 20111112 1.14 but output() does broadcast if destination is self
 20111108 1.12 output() does not broadcast if destination is set
 20111101 1.11 add parse_address() & call automatically from connectto() etc
 20110624 1.09 maximum_nports increased from 4 to 64
 20110428 1.06 fix bug in status() in the time return-value
 20110323 1.05 controllerevent() 
 20110303 1.04 output, input, *2alsa and alsa2* now handle sysex events
 20110228 1.03 add listclients, listconnectedto and listconnectedfrom
 20110213 1.02 add disconnectto and disconnectfrom
 20110210 1.01 output() no longer floors the time to the nearest second
 20110209 1.01 pitchbendevent() and chanpress() return correct data
 20110129 1.00 first working version

=head1 TO DO

Perhaps there should be a general connect_between() mechanism,
allowing the interconnection of two other clients,
a bit like I<aconnect 32 20>

If an event is of type SND_SEQ_EVENT_PORT_UNSUBSCRIBED
then the remote client and port are zeroed-out,
which makes it hard to know which client has just disconnected.

ALSA does not transmit Meta-Events like I<text_event>,
and there's not much can be done about that.

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

 aconnect -oil
 http://pp.com.mx/python/alsaseq
 http://search.cpan.org/perldoc?MIDI::ALSA
 http://www.pjb.com.au/comp/lua/midialsa.html
 http://luarocks.org/modules/peterbillam/midialsa
 http://www.pjb.com.au/comp/lua/MIDI.html
 http://www.pjb.com.au/comp/lua/MIDI.html#events
 http://alsa-project.org/alsa-doc/alsa-lib/seq.html
 http://alsa-project.org/alsa-doc/alsa-lib/structsnd__seq__ev__note.html
 http://alsa-project.org/alsa-doc/alsa-lib/structsnd__seq__ev__ctrl.html
 http://alsa-project.org/alsa-doc/alsa-lib/structsnd__seq__ev__queue__control.html
 http://alsa-project.org/alsa-doc/alsa-lib/group___seq_client.html
 http://alsa-utils.sourcearchive.com/documentation/1.0.20/aconnect_8c-source.html 
 http://alsa-utils.sourcearchive.com/documentation/1.0.8/aplaymidi_8c-source.html
 snd_seq_client_info_event_filter_clear
 snd_seq_get_any_client_info
 snd_seq_get_client_info
 snd_seq_client_info_t

=cut

]=]

