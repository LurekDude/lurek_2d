-- Default: pause=200 (restart after heap grows 200%), step=200 (step multiplier)
collectgarbage("setpause", 100)    -- restart GC sooner (lower memory peak)
collectgarbage("setstepsize", 400) -- larger steps (less frequent interruptions)

-- Force a full collection (loading screen / level transitions only)
collectgarbage("collect")

-- Query current heap size in KB
local kb = collectgarbage("count")
