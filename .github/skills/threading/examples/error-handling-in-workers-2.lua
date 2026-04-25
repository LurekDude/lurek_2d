-- Main thread checks error channel each frame:
local errors = lurek.thread.newChannel()

function lurek.process(dt)
    local err = errors:pop()
    if err then
        print("Background error: " .. err)
    end
    -- ...
end
