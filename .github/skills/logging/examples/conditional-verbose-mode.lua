-- conf.toml / conf.lua: expose a debug flag
function lurek.conf(t)
    t.identity.name = "mygame"
end

-- main.lua: enable verbose logging via a flag file
local VERBOSE = lurek.filesystem.exists("debug.flag")

local function dbg(msg)
    if VERBOSE then print("[DBG] " .. msg) end
end
