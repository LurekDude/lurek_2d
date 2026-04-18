local saveChannel = lurek.thread.newChannel()

local saver = lurek.thread.newThread([[
    local ch = ...
    while true do
        local json = ch:demand()
        if json == nil then break end
        lurek.fs.write("save.json", json)
    end
]])
saver:start(saveChannel)

-- Trigger save from main thread (non-blocking):
saveChannel:push(lurek.data.toJSON(gameState))
