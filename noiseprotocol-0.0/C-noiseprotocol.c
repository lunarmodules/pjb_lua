/*
    C-noiseprotocol.c - noiseprotocol noise-c bindings for Lua

   This Lua5 module is Copyright (c) 2011, Peter J Billam
                     www.pjb.com.au

 This module is free software; you can redistribute it and/or
       modify it under the same terms as Lua5 itself.
*/

#include <noise/protocol.h>
#include <strings.h>   /*  */
#include <lua.h>
#include <lauxlib.h>

int handshakestate_id = -1;
int max_cistate_id    = -1;
NoiseHandshakeState *dhstate_by_id[10];
NoiseProtocolId     *protocol_by_id[10];
NoiseBuffer         *buffer_by_id[10];
NoiseCipherState    *cistate_by_id[10];

static int c_handshakestate_fallback(lua_State *L) {
	/* Falls back to the "XXfallback" handshake pattern */
	lua_Integer id      = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[id];
	int rc = noise_handshakestate_fallback(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_fallback_to(lua_State *L) {
	/* Falls back to another handshake pattern */
	lua_Integer id         = lua_tointeger(L, 1);
	lua_Integer pattern_id = lua_tointeger(L, 2);
	NoiseHandshakeState *state = dhstate_by_id[id];
	int rc = noise_handshakestate_fallback_to(state, pattern_id);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_free(lua_State *L) {
	/* Frees a object after destroying all sensitive material */
	lua_Integer id         = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[id];
	int rc = noise_handshakestate_free(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_get_action (lua_State *L) {
	/* Gets the next action the application should perform
       for the handshake phase of the protocol. */
	lua_Integer id         = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[id];
	int rc = noise_handshakestate_get_action(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_get_fixed_ephemeral_dh(lua_State *L) {
	/* Gets the DHState object that contains the local ephemeral keypair */
	lua_Integer id         = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[id];
	NoiseDHState * rc = noise_handshakestate_get_fixed_ephemeral_dh(state);
	lua_pushinteger(L, (lua_Integer) rc);
	return 1;
}

static int c_handshakestate_get_fixed_hybrid_dh(lua_State *L) {
	/* Gets the DHState object that contains the
       local additional hybrid secrecy keypair */
	lua_Integer id             = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[id];
	NoiseDHState * rc = noise_handshakestate_get_fixed_ephemeral_dh(state);
	lua_pushinteger(L, (lua_Integer) rc);
	return 1;
}

static int c_handshakestate_get_handshake_hash (lua_State *L) {
	/* Gets the handshake hash value once the handshake ends */
	lua_Integer id             = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[id];
	size_t max_len = noise_cipherstate_get_max_key_length();
	uint8_t hash[10000];
	int rc = noise_handshakestate_get_handshake_hash(state, hash, max_len);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_get_local_keypair_dh(lua_State *L) {
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	/* Gets the DHState object that contains the local static keypair */
	lua_Integer rc = (lua_Integer) noise_handshakestate_get_local_keypair_dh(state);
//must save this pointer in a local array
	lua_pushinteger(L, (lua_Integer) rc);
	return 1;
}

static int c_handshakestate_get_protocol_id(lua_State *L) {
	/* Gets the protocol identifier associated with a HandshakeState object */
	lua_Integer state_id       = lua_tointeger(L, 1);
	lua_Integer protocol_id    = lua_tointeger(L, 2);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_get_protocol_id(state,
	  (NoiseProtocolId *) protocol_id);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_get_remote_public_key_dh(lua_State *L) {
	/* Gets the DHState object that contains the remote static public key */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = (lua_Integer) noise_handshakestate_get_remote_public_key_dh(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_get_role(lua_State *L) {
	/* Gets the role that a HandshakeState object is playing */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_get_role(state);
	lua_pushinteger(L, (lua_Integer) rc);
	return 1;
}

static int c_handshakestate_has_local_keypair(lua_State *L) {
	/* Determine if HandshakeState has been configured with a local keypair */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_has_local_keypair(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_has_pre_shared_key(lua_State *L) {
	/* Determine if a HandshakeState object has already been
	   configured with a pre shared key */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_has_pre_shared_key(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_has_remote_public_key(lua_State *L) {
	/* Determine if a HandshakeState has a remote public key */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_has_remote_public_key(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_needs_local_keypair(lua_State *L) {
	/* Determine if a HandshakeState still needs to be configured
	   with a local keypair */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_needs_local_keypair(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_needs_pre_shared_key(lua_State *L) {
	/* Determine if a HandshakeState object requires a pre shared key */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_needs_pre_shared_key(state);
	if (handshakestate_id < 0) { lua_pushinteger(L,0) ; return 1; }  /* ?? */
	return 1;
}

static int c_handshakestate_needs_remote_public_key(lua_State *L) {
	/* Determine if a HandshakeState still needs to be configured
	   with a remote public key before the protocol can start */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_needs_remote_public_key(state);
	lua_pushinteger(L, rc);
	return 1;
}


static int c_handshakestate_new_by_id(lua_State *L) {
	/* Creates a new HandshakeState object by protocol identifier */
	lua_Integer state_id       = lua_tointeger(L, 1);
	lua_Integer protocol_id    = lua_tointeger(L, 2);
	lua_Integer role           = lua_tointeger(L, 3);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	NoiseProtocolId *protocol  = protocol_by_id[protocol_id];
	int rc = noise_handshakestate_new_by_id(&state, protocol, role);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_new_by_name(lua_State *L) {
	/* Creates a new HandshakeState object by protocol name */
	lua_Integer state_id       = lua_tointeger(L, 1);
	size_t len;
    const char *protocol_name  = lua_tolstring(L, 2, &len);
	lua_Integer role           = lua_tointeger(L, 3);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_new_by_name(&state, protocol_name, role);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_read_message(lua_State *L) {
	/* Reads a message payload using a HandshakeState
	   noise/protocol/buffer.h */
	lua_Integer state_id       = lua_tointeger(L, 1);
	lua_Integer message_id     = lua_tointeger(L, 2);
	lua_Integer payload_id     = lua_tointeger(L, 3);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	NoiseBuffer *message       = buffer_by_id[message_id];
	NoiseBuffer *payload       = buffer_by_id[payload_id];
	int rc = noise_handshakestate_read_message(state, message, payload);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_set_pre_shared_key(lua_State *L) {
	/* Sets the pre shared key for a HandshakeState */
	lua_Integer state_id       = lua_tointeger(L, 1);
	size_t key_len             = (size_t) lua_tointeger(L, 3);
	const uint8_t * key        = lua_tolstring(L, 2, &key_len);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_set_pre_shared_key(state, key, key_len);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_set_prologue(lua_State *L) {
	/* Sets the prologue for a HandshakeState */
	lua_Integer state_id       = lua_tointeger(L, 1);
	size_t prologue_len        = (size_t) lua_tointeger(L, 3);
	const uint8_t * prologue   = lua_tolstring(L, 2, &prologue_len);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_set_prologue(state, prologue, prologue_len);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_split(lua_State *L) {
	/* Splits the transport encryption CipherState objects
	   out of this HandshakeState object. */
	lua_Integer state_id       = lua_tointeger(L, 1);
	lua_Integer send_id        = lua_tointeger(L, 2);
	lua_Integer receive_id     = lua_tointeger(L, 3);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	NoiseCipherState    *send  = cistate_by_id[send_id];
	NoiseCipherState *receive  = cistate_by_id[receive_id];
	int rc = noise_handshakestate_split(state, &send, &receive);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_start(lua_State *L) {
	/* Starts the handshake on a HandshakeState object */
	lua_Integer state_id       = lua_tointeger(L, 1);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	int rc = noise_handshakestate_start(state);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_handshakestate_write_message(lua_State *L) {
	/* Writes a message payload using a HandshakeState */
	lua_Integer state_id       = lua_tointeger(L, 1);
	lua_Integer message_id     = lua_tointeger(L, 2);
	lua_Integer payload_id     = lua_tointeger(L, 3);
	NoiseHandshakeState *state = dhstate_by_id[state_id];
	NoiseBuffer *message       = buffer_by_id[message_id];
	NoiseBuffer *payload       = buffer_by_id[payload_id];
	int rc = noise_handshakestate_write_message(state, message, payload);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_decrypt(lua_State *L) {
	/* Decrypts a block of data with this CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	lua_Integer buffer_id     = lua_tointeger(L, 2);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	NoiseBuffer *buffer       = buffer_by_id[buffer_id];
	int rc = noise_cipherstate_decrypt(cistate, buffer);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_decrypt_with_ad(lua_State *L) {
	/* Decrypts a block of data with this CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	size_t ad_len             = (size_t) lua_tointeger(L, 3);
	const uint8_t * ad        = lua_tolstring(L, 2, &ad_len);
	lua_Integer buffer_id     = lua_tointeger(L, 4);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	NoiseBuffer *buffer       = buffer_by_id[buffer_id];
	int rc = noise_cipherstate_decrypt_with_ad(cistate, ad, ad_len, buffer);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_encrypt(lua_State *L) {
	/* Encrypts a block of data with this CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	lua_Integer buffer_id     = lua_tointeger(L, 2);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	NoiseBuffer *buffer       = buffer_by_id[buffer_id];
	int rc = noise_cipherstate_encrypt(cistate, buffer);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_encrypt_with_ad(lua_State *L) {
	/* Encrypts a block of data with this CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	size_t ad_len             = (size_t) lua_tointeger(L, 3);
	const uint8_t * ad        = lua_tolstring(L, 2, &ad_len);
	lua_Integer buffer_id     = lua_tointeger(L, 4);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	NoiseBuffer *buffer       = buffer_by_id[buffer_id];
	int rc = noise_cipherstate_encrypt_with_ad(cistate, ad, ad_len, buffer);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_free(lua_State *L) {
	/* Frees a CipherState object after destroying all sensitive material */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	int rc = noise_cipherstate_free(cistate);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_get_cipher_id(lua_State *L) {
	/* Gets the algorithm identifier for a CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	int rc = noise_cipherstate_get_cipher_id(cistate);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_get_key_length(lua_State *L) {
	/* Gets the length of the encryption key for a CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	int rc = noise_cipherstate_get_key_length(cistate);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_get_mac_length(lua_State *L) {
	/* Gets the length of packet MAC values for a CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	int rc = noise_cipherstate_get_mac_length(cistate);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_get_max_key_length(lua_State *L) {
	/* Gets the maximum key length for the supported algorithms */
	int rc = noise_cipherstate_get_max_key_length();
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_get_max_mac_length(lua_State *L) {
	/* Gets the maximum MAC length for the supported algorithms */
	int rc = noise_cipherstate_get_max_mac_length();
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_has_key(lua_State *L) {
	/* Determine if the key has been set on a CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
    NoiseCipherState *cistate = cistate_by_id[cistate_id];
	int rc = noise_cipherstate_has_key(cistate);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_init_key(lua_State *L) {
	/* Initializes the key on a CipherState object */
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	size_t key_len             = (size_t) lua_tointeger(L, 3);
	const uint8_t * key        = lua_tolstring(L, 2, &key_len);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	int rc = noise_cipherstate_init_key(cistate, key, key_len);
	lua_pushinteger(L, rc);
	return 1;
}

static int c_cipherstate_new_by_id(lua_State *L) {
	/* Creates a new CipherState object by its algorithm identifier */
	lua_Integer algorithm_id    = lua_tointeger(L, 1);
	NoiseCipherState * new_cistate ;
	int rc = noise_cipherstate_new_by_id(&new_cistate, algorithm_id);
	cistate_by_id[max_cistate_id] = new_cistate;
	lua_pushinteger(L, max_cistate_id);
	max_cistate_id++;
	return 1;
}

static int c_cipherstate_new_by_name(lua_State *L) {
	/* Creates a new CipherState object by its algorithm name */
    const char *algorithm_name  = lua_tostring(L, 1);
	NoiseCipherState * new_cistate ;
	int rc = noise_cipherstate_new_by_name(&new_cistate, algorithm_name);
	cistate_by_id[max_cistate_id] = new_cistate;
	lua_pushinteger(L, max_cistate_id);
	max_cistate_id++;
	return 1;
}

static int c_cipherstate_set_nonce(lua_State *L) {
	lua_Integer cistate_id    = lua_tointeger(L, 1);
	uint64_t nonce            = (uint64_t) lua_tointeger(L, 2);
	NoiseCipherState *cistate = cistate_by_id[cistate_id];
	int rc = noise_cipherstate_set_nonce(cistate, nonce);
	lua_pushinteger(L, rc);
	return 1;
}

struct constant {  /* Gems p. 334 */
	const char * name;
	int value;
};
static const struct constant constants[] = {  /* noise/protocol/constants.h */
	{"NOISE_CIPHER_NONE",       NOISE_CIPHER_NONE},
	{"NOISE_CIPHER_CATEGORY",   NOISE_CIPHER_CATEGORY},
	{"NOISE_CIPHER_CHACHAPOLY", NOISE_CIPHER_CHACHAPOLY},
	{"NOISE_CIPHER_AESGCM",     NOISE_CIPHER_AESGCM},
	{"NOISE_HASH_NONE",     NOISE_HASH_NONE},
	{"NOISE_HASH_CATEGORY", NOISE_HASH_CATEGORY},
	{"NOISE_HASH_BLAKE2s",  NOISE_HASH_BLAKE2s},
	{"NOISE_HASH_BLAKE2b",  NOISE_HASH_BLAKE2b},
	{"NOISE_HASH_SHA256",   NOISE_HASH_SHA256},
	{"NOISE_HASH_SHA512",   NOISE_HASH_SHA512},
	{"NOISE_DH_NONE",       NOISE_DH_NONE},
	{"NOISE_DH_CATEGORY",   NOISE_DH_CATEGORY},
	{"NOISE_DH_CURVE25519", NOISE_DH_CURVE25519},
	{"NOISE_DH_CURVE448",   NOISE_DH_CURVE448},
	{"NOISE_DH_NEWHOPE",    NOISE_DH_NEWHOPE},
	{"NOISE_PATTERN_NONE",     NOISE_PATTERN_NONE},
	{"NOISE_PATTERN_CATEGORY", NOISE_PATTERN_CATEGORY},
	{"NOISE_PATTERN_N",        NOISE_PATTERN_N},
	{"NOISE_PATTERN_X",        NOISE_PATTERN_X},
	{"NOISE_PATTERN_K",        NOISE_PATTERN_K},
	{"NOISE_PATTERN_NN",       NOISE_PATTERN_NN},
	{"NOISE_PATTERN_NK",       NOISE_PATTERN_NK},
	{"NOISE_PATTERN_NX",       NOISE_PATTERN_NX},
	{"NOISE_PATTERN_XN",       NOISE_PATTERN_XN},
	{"NOISE_PATTERN_XK",       NOISE_PATTERN_XK},
	{"NOISE_PATTERN_XX",       NOISE_PATTERN_XX},
	{"NOISE_PATTERN_KN",       NOISE_PATTERN_KN},
	{"NOISE_PATTERN_KK",       NOISE_PATTERN_KK},
	{"NOISE_PATTERN_KX",       NOISE_PATTERN_KX},
	{"NOISE_PATTERN_IN",       NOISE_PATTERN_IN},
	{"NOISE_PATTERN_IK",       NOISE_PATTERN_IK},
	{"NOISE_PATTERN_IX",       NOISE_PATTERN_IX},
	{"NOISE_PATTERN_XX_FALLBACK", NOISE_PATTERN_XX_FALLBACK},
	{"NOISE_PATTERN_X_NOIDH",  NOISE_PATTERN_X_NOIDH},
	{"NOISE_PATTERN_NX_NOIDH", NOISE_PATTERN_NX_NOIDH},
	{"NOISE_PATTERN_XX_NOIDH", NOISE_PATTERN_XX_NOIDH},
	{"NOISE_PATTERN_KX_NOIDH", NOISE_PATTERN_KX_NOIDH},
	{"NOISE_PATTERN_IK_NOIDH", NOISE_PATTERN_IK_NOIDH},
	{"NOISE_PATTERN_IX_NOIDH", NOISE_PATTERN_IX_NOIDH},
	{"NOISE_PATTERN_NN_HFS",   NOISE_PATTERN_NN_HFS},
	{"NOISE_PATTERN_NK_HFS",   NOISE_PATTERN_NK_HFS},
	{"NOISE_PATTERN_NX_HFS",   NOISE_PATTERN_NX_HFS},
	{"NOISE_PATTERN_XN_HFS",   NOISE_PATTERN_XN_HFS},
	{"NOISE_PATTERN_XK_HFS",   NOISE_PATTERN_XK_HFS},
	{"NOISE_PATTERN_XX_HFS",   NOISE_PATTERN_XX_HFS},
	{"NOISE_PATTERN_KN_HFS",   NOISE_PATTERN_KN_HFS},
	{"NOISE_PATTERN_KK_HFS",   NOISE_PATTERN_KK_HFS},
	{"NOISE_PATTERN_KX_HFS",   NOISE_PATTERN_KX_HFS},
	{"NOISE_PATTERN_IN_HFS",   NOISE_PATTERN_IN_HFS},
	{"NOISE_PATTERN_IK_HFS",   NOISE_PATTERN_IK_HFS},
	{"NOISE_PATTERN_IX_HFS",   NOISE_PATTERN_IX_HFS},
	{"NOISE_PATTERN_XX_FALLBACK_HFS", NOISE_PATTERN_XX_FALLBACK_HFS},
	{"NOISE_PATTERN_NX_NOIDH_HFS", NOISE_PATTERN_NX_NOIDH_HFS},
	{"NOISE_PATTERN_XX_NOIDH_HFS", NOISE_PATTERN_XX_NOIDH_HFS},
	{"NOISE_PATTERN_KX_NOIDH_HFS", NOISE_PATTERN_KX_NOIDH_HFS},
	{"NOISE_PATTERN_IK_NOIDH_HFS", NOISE_PATTERN_IK_NOIDH_HFS},
	{"NOISE_PATTERN_IX_NOIDH_HFS", NOISE_PATTERN_IX_NOIDH_HFS},
	{"NOISE_PREFIX_NONE",     NOISE_PREFIX_NONE},
	{"NOISE_PREFIX_CATEGORY", NOISE_PREFIX_CATEGORY},
	{"NOISE_PREFIX_STANDARD", NOISE_PREFIX_STANDARD},
	{"NOISE_PREFIX_PSK",      NOISE_PREFIX_PSK},
	{"NOISE_SIGN_NONE",       NOISE_SIGN_NONE},
	{"NOISE_SIGN_CATEGORY",   NOISE_SIGN_CATEGORY},
	{"NOISE_SIGN_ED25519",    NOISE_SIGN_ED25519},
	{"NOISE_ROLE_INITIATOR",  NOISE_ROLE_INITIATOR},
	{"NOISE_ROLE_RESPONDER",  NOISE_ROLE_RESPONDER},
	{"NOISE_ACTION_NONE",          NOISE_ACTION_NONE},
	{"NOISE_ACTION_WRITE_MESSAGE", NOISE_ACTION_WRITE_MESSAGE},
	{"NOISE_ACTION_READ_MESSAGE",  NOISE_ACTION_READ_MESSAGE},
	{"NOISE_ACTION_FAILED",        NOISE_ACTION_FAILED},
	{"NOISE_ACTION_SPLIT",         NOISE_ACTION_SPLIT},
	{"NOISE_ACTION_COMPLETE",      NOISE_ACTION_COMPLETE},
	{"NOISE_PADDING_ZERO",   NOISE_PADDING_ZERO},
	{"NOISE_PADDING_RANDOM", NOISE_PADDING_RANDOM},
	{"NOISE_FINGERPRINT_BASIC", NOISE_FINGERPRINT_BASIC},
	{"NOISE_FINGERPRINT_FULL",  NOISE_FINGERPRINT_FULL},
	{"NOISE_ERROR_NONE",                NOISE_ERROR_NONE},
	{"NOISE_ERROR_NO_MEMORY",           NOISE_ERROR_NO_MEMORY},
	{"NOISE_ERROR_UNKNOWN_ID",          NOISE_ERROR_UNKNOWN_ID},
	{"NOISE_ERROR_UNKNOWN_NAME",        NOISE_ERROR_UNKNOWN_NAME},
	{"NOISE_ERROR_MAC_FAILURE",         NOISE_ERROR_MAC_FAILURE},
	{"NOISE_ERROR_NOT_APPLICABLE",      NOISE_ERROR_NOT_APPLICABLE},
	{"NOISE_ERROR_SYSTEM",              NOISE_ERROR_SYSTEM},
	{"NOISE_ERROR_REMOTE_KEY_REQUIRED", NOISE_ERROR_REMOTE_KEY_REQUIRED},
	{"NOISE_ERROR_LOCAL_KEY_REQUIRED",  NOISE_ERROR_LOCAL_KEY_REQUIRED},
	{"NOISE_ERROR_PSK_REQUIRED",        NOISE_ERROR_PSK_REQUIRED},
	{"NOISE_ERROR_INVALID_LENGTH",      NOISE_ERROR_INVALID_LENGTH},
	{"NOISE_ERROR_INVALID_PARAM",       NOISE_ERROR_INVALID_PARAM},
	{"NOISE_ERROR_INVALID_STATE",       NOISE_ERROR_INVALID_STATE},
	{"NOISE_ERROR_INVALID_NONCE",       NOISE_ERROR_INVALID_NONCE},
	{"NOISE_ERROR_INVALID_PRIVATE_KEY", NOISE_ERROR_INVALID_PRIVATE_KEY},
	{"NOISE_ERROR_INVALID_PUBLIC_KEY",  NOISE_ERROR_INVALID_PUBLIC_KEY},
	{"NOISE_ERROR_INVALID_FORMAT",      NOISE_ERROR_INVALID_FORMAT},
	{"NOISE_ERROR_INVALID_SIGNATURE",   NOISE_ERROR_INVALID_SIGNATURE},
	{"NOISE_MAX_PAYLOAD_LEN",      NOISE_MAX_PAYLOAD_LEN},
	{"NOISE_MAX_PROTOCOL_NAME",    NOISE_MAX_PROTOCOL_NAME},
	{"NOISE_MAX_FINGERPRINT_LEN",  NOISE_MAX_FINGERPRINT_LEN},
	{NULL, 0}
};

static const luaL_Reg prv[] = {  /* private functions */
	{"handshakestate_fallback",    c_handshakestate_fallback},
	{"handshakestate_fallback_to", c_handshakestate_fallback_to},
	{"handshakestate_free",        c_handshakestate_free},
	{"handshakestate_get_action ", c_handshakestate_get_action },
	{"handshakestate_get_fixed_ephemeral_dh",    c_handshakestate_get_fixed_ephemeral_dh},
	{"handshakestate_get_fixed_hybrid_dh",     c_handshakestate_get_fixed_hybrid_dh},
	{"handshakestate_get_handshake_hash", c_handshakestate_get_handshake_hash},
	{"handshakestate_get_local_keypair_dh",   c_handshakestate_get_local_keypair_dh},
	{"handshakestate_get_protocol_id",    c_handshakestate_get_protocol_id},
	{"handshakestate_get_remote_public_key_dh",          c_handshakestate_get_remote_public_key_dh},
	{"handshakestate_has_local_keypair",  c_handshakestate_has_local_keypair},
	{"handshakestate_has_pre_shared_key", c_handshakestate_has_pre_shared_key},
	{"handshakestate_has_remote_public_key", c_handshakestate_has_remote_public_key},
	{"handshakestate_needs_local_keypair",   c_handshakestate_needs_local_keypair},
	{"handshakestate_needs_pre_shared_key",  c_handshakestate_needs_pre_shared_key},
	{"handshakestate_needs_remote_public_key", c_handshakestate_needs_remote_public_key},
	{"handshakestate_new_by_id",          c_handshakestate_new_by_id},
	{"handshakestate_new_by_name",        c_handshakestate_new_by_name},
	{"handshakestate_read_message",       c_handshakestate_read_message},
	{"handshakestate_set_pre_shared_key", c_handshakestate_set_pre_shared_key},
	{"handshakestate_set_prologue",       c_handshakestate_set_prologue},
	{"handshakestate_split",     c_handshakestate_split},
	{"handshakestate_start",     c_handshakestate_start},
	{"handshakestate_write_message",      c_handshakestate_write_message},
	{"cipherstate_decrypt",      c_cipherstate_decrypt},
	{"cipherstate_decrypt_with_ad",       c_cipherstate_decrypt_with_ad},
	{"cipherstate_encrypt",      c_cipherstate_encrypt},
	{"cipherstate_encrypt_with_ad",       c_cipherstate_encrypt_with_ad},
	{"cipherstate_free",         c_cipherstate_free},
	{"cipherstate_get_cipher_id",         c_cipherstate_get_cipher_id},
	{"cipherstate_get_key_length",        c_cipherstate_get_key_length},
	{"cipherstate_get_mac_length",        c_cipherstate_get_mac_length},
	{"cipherstate_get_max_key_length",    c_cipherstate_get_max_key_length},
	{"cipherstate_get_max_mac_length",    c_cipherstate_get_max_mac_length},
	{"cipherstate_has_key",      c_cipherstate_has_key},
	{"cipherstate_init_key",     c_cipherstate_init_key},
	{"cipherstate_new_by_id",    c_cipherstate_new_by_id},
	{"cipherstate_new_by_name",      c_cipherstate_new_by_name},
	{"cipherstate_set_nonce",     c_cipherstate_set_nonce},
	{NULL, NULL}
};

static int initialise(lua_State *L) {  /* Lua Programming Gems p. 335 */
	/* Lua stack: aux table, prv table, dat table */
	int index;  /* define constants in module namespace */
	for (index = 0; constants[index].name != NULL; ++index) {
		lua_pushinteger(L, constants[index].value);
		lua_setfield(L, 3, constants[index].name);
	}
	/* lua_pushvalue(L, 1);   * set the aux table as environment */
	/* lua_replace(L, LUA_ENVIRONINDEX);
	   unnecessary here, fortunately, because it fails in 5.2 */
	lua_pushvalue(L, 2); /* register the private functions */
#if LUA_VERSION_NUM >= 502
	luaL_setfuncs(L, prv, 0);    /* 5.2 */
	return 0;
#else
	luaL_register(L, NULL, prv); /* 5.1 */
	return 0;
#endif
}

int luaopen_noiseprotocol(lua_State *L) {
	lua_pushcfunction(L, initialise);
	return 1;
}
