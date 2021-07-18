local function str2quoted_printable (s)   -- PiL p.60
    local pq = string.gsub(s, "([\128-\255=])",
        function(c) return string.format("=%02X", string.byte(c)) end
    )
    return pq
end
local function quoted_printable2str (pq)
    local s = string.gsub(pq, "=([A-F0-9][A-F0-9])",
        function(c) return string.char(tonumber("0x"..c)) end
    )
	return s
end
s = 'Der Mensch = ein Seil, geknüpft zwischen Tier und Übermensch'
pq = str2quoted_printable(s)
print(pq)
print(quoted_printable2str(pq))
