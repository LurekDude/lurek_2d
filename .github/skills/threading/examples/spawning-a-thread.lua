-- lurek.thread.newThread(code: string) -> Thread
-- code is a complete Lua script string; it runs in an isolated VM
local worker = lurek.thread.newThread([[
    local inbox  = ...   -- first argument via thread:start()
    local outbox = ...   -- second argument

    while true do
        local task = inbox:demand()   -- blocking: wait for work
        if task == "quit" then break end

        local result = task * 2  -- do work
        outbox:push(result)
    end
]])
