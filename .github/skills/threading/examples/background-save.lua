local saveChannel = lurek.thread.newChannel()
local gameState = { player = { x = 10, y = 20 } }

local saver = lurek.thread.newThread([[
    local ch = ...
    while true do
        local json = ch:demand()
        if json == nil then break end
        lurek.filesystem.write("save.json", json)
    end
]])
saver:start(saveChannel)

-- Trigger save from main thread (non-blocking):
saveChannel:push(lurek.serial.toJson(gameState))
