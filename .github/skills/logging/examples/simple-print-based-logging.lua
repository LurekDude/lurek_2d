-- Log levels via prefix convention
local function logInfo(msg)  print("[INFO]  " .. msg) end
local function logWarn(msg)  print("[WARN]  " .. msg) end
local function logError(msg) print("[ERROR] " .. msg) end

logInfo("Game loaded � level 1")
logWarn("save file missing, starting fresh")
