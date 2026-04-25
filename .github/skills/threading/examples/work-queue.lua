local queue   = lurek.thread.newChannel()
local results = lurek.thread.newChannel()

local function applyResult(result)
    lurek.log.info("worker result: " .. tostring(result), "thread")
end

local worker  = lurek.thread.newThread([[
    local q, r = ...
    while true do
        local item = q:demand()
        if item == nil then break end
        r:push(expensiveCompute(item))
    end
]])
worker:start(queue, results)

-- Main thread: post work
queue:push(42)

-- Main thread: collect results each frame (non-blocking)
function lurek.process(dt)
    local result = results:pop()
    if result then applyResult(result) end
end
