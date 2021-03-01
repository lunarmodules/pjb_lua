package = "noiseprotocol"
version = "VERSION-0"
source = {
   url = "http://www.pjb.com.au/comp/lua/TARBALL",
   md5 = "MD5"
}
description = {
   summary = "Provides access to the noiseprotocol library",
   detailed = [[
    https://rweather.github.io/noise-c/group__handshakestate.html
    https://rweather.github.io/noise-c/group__cipherstate.html
    https://rweather.github.io/noise-c/example_echo.html
   ]],
   homepage = "http://www.pjb.com.au/comp/lua/noiseprotocol.html",
   license = "MIT/X11"
}
dependencies = {
   "lua >= 5.1, <5.4"
}
external_dependencies = {
   ALSA = {
      header  = "noise/protocol.h",
      -- library = "asound",
   }
}
build = {
   type = "builtin",
   modules = {
      ["noiseprotocol"] = "noiseprotocol.lua",
      ["C-noiseprotocol"] = {
         sources   = { "C-noiseprotocol.c" },
         -- incdirs   = { "$(ALSA_INCDIR)" },
         -- libdirs   = { "$(ALSA_LIBDIR)" },
         libraries = { "noiseprotocol" },
      }
   },
   copy_directories = { "doc", "test" }
}
