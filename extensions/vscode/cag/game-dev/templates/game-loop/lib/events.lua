local Events = {}
local handlers = {}

function Events.on(event, fn)
    handlers[event] = handlers[event] or {}
    handlers[event][#handlers[event] + 1] = fn
end

function Events.off(event, fn)
    local list = handlers[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == fn then table.remove(list, i) end
    end
end

function Events.emit(event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do list[i](...) end
end

return Events
