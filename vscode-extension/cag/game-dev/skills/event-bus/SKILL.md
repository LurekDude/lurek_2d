# Event Bus

Central event system with subscribe, emit, and unsubscribe for decoupled game systems.

## Key Concepts

- **Decouple systems**: The combat system emits `"enemy_killed"` — the quest tracker and score counter listen independently.
- **on / emit / off**: Subscribe handlers, broadcast events with data, remove handlers.
- **Scene-scoped vs global**: Clear scene-specific handlers on scene change. Keep global handlers (settings, achievements).
- **Event data**: Pass a table of named fields, not positional arguments.

## Event Bus Implementation

```lua
local event_bus = { listeners = {} }

function event_bus.on(event, handler)
    if not event_bus.listeners[event] then
        event_bus.listeners[event] = {}
    end
    local list = event_bus.listeners[event]
    list[#list + 1] = handler
end

function event_bus.emit(event, data)
    local list = event_bus.listeners[event]
    if not list then return end
    for _, handler in ipairs(list) do
        handler(data)
    end
end

function event_bus.off(event, handler)
    local list = event_bus.listeners[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == handler then
            table.remove(list, i)
            return
        end
    end
end

function event_bus.clear(event)
    if event then
        event_bus.listeners[event] = nil
    else
        event_bus.listeners = {}
    end
end
```

## Usage: Decoupled Systems

```lua
-- Combat system emits
local function kill_enemy(enemy)
    enemy.alive = false
    event_bus.emit("enemy_killed", { type = enemy.type, x = enemy.x, y = enemy.y })
end

-- Quest tracker listens
event_bus.on("enemy_killed", function(data)
    notify_kill(data.type)
end)

-- Score system listens
event_bus.on("enemy_killed", function(data)
    score = score + (data.type == "boss" and 500 or 100)
end)

-- Particle system listens
event_bus.on("enemy_killed", function(data)
    spawn_effect(effects.death_explode, data.x, data.y)
end)
```

## Scene-Scoped Handlers

```lua
local scene_handlers = {}

local function scene_on(event, handler)
    event_bus.on(event, handler)
    scene_handlers[#scene_handlers + 1] = { event = event, handler = handler }
end

local function clear_scene_handlers()
    for _, entry in ipairs(scene_handlers) do
        event_bus.off(entry.event, entry.handler)
    end
    scene_handlers = {}
end

-- Call clear_scene_handlers() in scene.unload()
```

## One-Shot Handler

```lua
local function once(event, handler)
    local wrapper
    wrapper = function(data)
        handler(data)
        event_bus.off(event, wrapper)
    end
    event_bus.on(event, wrapper)
end

-- Example: play a sound only the first time
once("boss_appear", function(data)
    play_sfx("boss_intro")
end)
```

## Common Pitfalls

- **Handler leaks** — always call `off` or `clear_scene_handlers` when leaving a scene. Stale handlers fire on wrong data.
- **Emit during iteration** — if a handler calls `emit` for the same event, you get reentrancy. Guard with a queue if needed.
- **Comparing functions** — `off` compares by reference. Store the handler in a variable if you need to unsubscribe later.
- **Too many events** — don't event-bus everything. Direct function calls are fine for tightly coupled systems.
- **Missing data fields** — always check `data.field` exists in handlers. A missing field causes nil errors.
