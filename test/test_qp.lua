-- If the text to be encoded does not contain many non-ASCII characters,
-- then Quoted-Printable results in a fairly readable and compact encoded
-- result. On the other hand, if the input has many 8-bit characters,
-- then Quoted-Printable becomes both unreadable and extremely inefficient.
-- Base64 is not human-readable, but has a uniform overhead for all data
-- and is the more sensible choice for binary formats
-- or text in a script other than the Latin script.

local function str2quoted_printable (s)   -- PiL p.60
    local qp = string.gsub(s, "([\128-\255=])",
        function(c) return string.format("=%02X", string.byte(c)) end
    )
    return qp
end
local function quoted_printable2str (qp)
    local s = string.gsub(qp, "=([A-F0-9][A-F0-9])",
        function(c) return string.char(tonumber("0x"..c)) end
    )
	return s
end
s = 'Der Mensch = ein Seil, geknüpft zwischen Tier und Übermensch'
qp = str2quoted_printable(s)
print(qp)
print(quoted_printable2str(qp))

-- https://en.wikipedia.org/wiki/Base64
-- see also https://github.com/iskolbin/lbase64/blob/master/base64.lua
-- luarocks install base64
-- https://github.com/iskolbin/lbase64
-- local base64 = require 'base64'
-- local encoded = base64.encode( str )
-- local decoded = base64.decode( b64str )
-- assert( str == decoded )
