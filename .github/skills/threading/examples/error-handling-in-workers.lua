-- Worker script:
local inbox  = ...
local outbox = ...
local errors = ...  -- error channel

while true do
    local task = inbox:demand()
    if task == "quit" then break end

    local ok, result = pcall(function()
        return processTask(task)
    end)

    if ok then
        outbox:push(result)
    else
        errors:push("worker error: " .. tostring(result))
    end
end
