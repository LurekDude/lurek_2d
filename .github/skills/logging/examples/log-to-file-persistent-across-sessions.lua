-- Append log lines to a file in the save directory
local LOG_FILE = "game.log"

local function logToFile(level, msg)
    local line = string.format("[%s] %.3f  %s\n", level, lurek.timer.getTime(), msg)
    lurek.filesystem.append(LOG_FILE, line)
end

logToFile("INFO",  "Level 1 started")
logToFile("WARN",  "missing texture: player_jump.png")
logToFile("ERROR", "physics body nil at spawn point")
