-- examples/patterns.lua
-- Demonstrates luna.patterns — six reusable design-pattern primitives for game
-- architecture.  All objects are pure Lua-side; there is no rendering or physics
-- involved.  Run with: cargo run -- examples/patterns
--
-- Patterns provided:
--   EventBus      — priority-ordered pub/sub with one-shot callbacks
--   ObjectPool    — pre-allocated object recycling
--   CommandStack  — execute/undo/redo for editor or replay systems
--   ServiceLocator— runtime dependency injection (replaces global tables)
--   Factory       — registered type constructors with alias support
--   SimpleState   — simple current-state tracker with enter/exit callbacks

-- ─────────────────────────────────────────────────────────────────────────────
-- EVENT BUS
-- Ordered pub/sub.  Listeners have integer priorities (higher = called first).
-- Supports one-shot callbacks that auto-unsubscribe after their first call.
-- ─────────────────────────────────────────────────────────────────────────────

-- Create a named bus (name is for debugging; two buses with the same name are
-- independent objects)
local events = luna.patterns.newEventBus("main")

-- Subscribe: on(event, callback, priority?) → subscription id
-- Save the returned id if you need to unsubscribe later.
local id_damage_log = events:on("damage", function(data)
    -- data is whatever was passed to emit()
    luna.log.debug(string.format("[EventBus] entity %d took %d damage",
        data.entity, data.amount))
end)

-- Subscribe with an explicit priority — higher number fires first.
-- The returned id is stored so we can remove this handler later.
local id_damage_stats = events:on("damage", function(data)
    luna.log.debug("[EventBus] priority 10: record damage in stats")
    _ = data
end, 10)   -- called BEFORE the priority-0 handler above

-- An additional level-up listener
local id_level_up = events:on("levelUp", function(data)
    luna.log.info("[EventBus] level-up detected! level=" .. data.level)
end)

-- Emit an event — ALL listeners on this bus for this event are called in order
events:emit("damage", { entity = 5, amount = 30 })
events:emit("damage", { entity = 5, amount = 15 })   -- same handlers run again

events:emit("levelUp", { level = 2 })
events:emit("levelUp", { level = 3 })

-- Inspect listener count per event
local damage_count = events:getListenerCount("damage")   -- 2
luna.log.debug("[EventBus] damage listeners: " .. damage_count)

-- List registered event names
local event_list = events:getEvents()   -- { "damage", "levelUp" }
for _, name in ipairs(event_list) do
    luna.log.debug("[EventBus] registered event: " .. name)
end

-- Remove a specific listener by its subscription id
events:off(id_damage_log)   -- the log callback is now gone
_ = id_damage_stats
_ = id_level_up

-- Remove ALL listeners for a single event (require event name as argument)
events:clear("damage")   -- damage listeners = 0

-- Remove ALL listeners on ALL events
events:clearAll()

-- ─────────────────────────────────────────────────────────────────────────────
-- OBJECT POOL
-- Pre-allocate objects and recycle them to avoid GC strain under high churn
-- (bullets, particles, explosion fragments).
-- ─────────────────────────────────────────────────────────────────────────────

local pool = luna.patterns.newObjectPool()

-- Seed the pool with pre-built objects
local function makeBullet()
    return { x = 0, y = 0, vx = 0, vy = 0, active = false, damage = 10 }
end

for _ = 1, 20 do
    pool:add(makeBullet())   -- add to the available (free) list
end

-- Query pool state
luna.log.info(string.format("[Pool] total=%d  available=%d  active=%d",
    pool:getTotalCount(), pool:getAvailableCount(), pool:getActiveCount()))

-- Acquire an object — removes it from the free list and marks it active.
-- Returns nil when the pool is exhausted (caller decides to expand or skip).
local bullet = pool:acquire()
if bullet then
    -- Initialise borrowed state
    bullet.x = 100 ; bullet.y = 200
    bullet.vx = 0  ; bullet.vy = -5
    bullet.active = true

    luna.log.debug(string.format("[Pool] fired bullet at (%d, %d)", bullet.x, bullet.y))
end

-- Acquire several more
local bullets = {}
for _ = 1, 5 do
    local b = pool:acquire()
    if b then table.insert(bullets, b) end
end

luna.log.info(string.format("[Pool] after 6 acquires — active=%d  available=%d",
    pool:getActiveCount(), pool:getAvailableCount()))

-- Release back to the pool (does NOT clear the object; caller should reset it)
if bullet then
    bullet.active = false
    pool:release(bullet)
end
for _, b in ipairs(bullets) do
    b.active = false
    pool:release(b)
end

luna.log.info(string.format("[Pool] after release — active=%d  available=%d",
    pool:getActiveCount(), pool:getAvailableCount()))

-- Destroy everything and start over
pool:clearAll()

-- ─────────────────────────────────────────────────────────────────────────────
-- COMMAND STACK
-- Encapsulates actions as objects with do/undo.  Supports redo.  Ideal for
-- level editors, replay systems, and undoable player moves.
-- ─────────────────────────────────────────────────────────────────────────────

-- Optional maxSize limits history depth (oldest entries discarded when exceeded)
local commands = luna.patterns.newCommandStack(50)

-- execute(name, exec_fn, undo_fn?) — exec_fn is called IMMEDIATELY; undo_fn is
-- stored for later and called by undo().
--
-- Close over the state you want to mutate so undo/redo can share it.
local player = { x = 0, y = 0 }

local function move(dx, dy)
    commands:execute(
        string.format("Move(%.0f, %.0f)", dx, dy),
        function()   -- do
            player.x = player.x + dx
            player.y = player.y + dy
            luna.log.debug(string.format("[Command] moved to (%d, %d)", player.x, player.y))
        end,
        function()   -- undo
            player.x = player.x - dx
            player.y = player.y - dy
            luna.log.debug(string.format("[Command] reverted to (%d, %d)", player.x, player.y))
        end
    )
end

move(10, 0)   -- exec called immediately: player: (10, 0)
move( 0, 5)   -- player: (10, 5)
move( 3, 0)   -- player: (13, 5)

luna.log.info(string.format("[Command] position: (%d, %d)", player.x, player.y))  -- (13, 5)

-- canUndo / canRedo are safe to call at any time
if commands:canUndo() then
    local last_name = commands:getCurrentName()   -- "Move(3, 0)"
    luna.log.debug("[Command] undoing: " .. last_name)
    commands:undo()   -- player: (10, 5)
end

if commands:canUndo() then
    commands:undo()   -- player: (10, 0)
end

-- Redo re-applies the undone commands in order
if commands:canRedo() then
    commands:redo()   -- player: (10, 5)
end

luna.log.info(string.format("[Command] history size: %d", commands:getHistorySize()))

-- Clear the full undo/redo history
commands:clearAll()
luna.log.debug(string.format("[Command] after clearAll — canUndo=%s canRedo=%s",
    tostring(commands:canUndo()), tostring(commands:canRedo())))

-- ─────────────────────────────────────────────────────────────────────────────
-- SERVICE LOCATOR
-- A registry that maps string service names to objects.  Avoids global
-- variables while keeping services accessible across game modules.
-- ─────────────────────────────────────────────────────────────────────────────

local services = luna.patterns.newServiceLocator()

-- Provide (register) a service by name
local FakeAudio = { play = function(self, clip) luna.log.debug("[Service] play: " .. clip) end }
local FakeInput = { isDown = function(self, k) return k == "space" end }

services:provide("audio", FakeAudio)
services:provide("input", FakeInput)

-- Check existence before locating (avoids errors on optional services)
if services:has("audio") then
    local audio = services:locate("audio")
    audio:play("jump.wav")
end

-- locate() raises a LuaError if the service is not found — so always guard with has()
local ok, err = pcall(function() return services:locate("network") end)
if not ok then
    luna.log.warn("[Service] expected error: " .. tostring(err))
end

-- List all registered service names
local all_services = services:getServices()   -- { "audio", "input" }
luna.log.info("[Service] registered: " .. table.concat(all_services, ", "))

-- Remove a service by name
services:remove("input")
luna.log.debug("[Service] has input: " .. tostring(services:has("input")))   -- false

-- Clear all registrations
services:clearAll()

-- ─────────────────────────────────────────────────────────────────────────────
-- FACTORY
-- Maps string type-keys to constructor functions.  Supports type aliases and
-- runtime registration (e.g. load from mods).
-- ─────────────────────────────────────────────────────────────────────────────

local factory = luna.patterns.newFactory()

-- Register constructors — receives an optional config table
factory:register("enemy.goblin", function(config)
    config = config or {}
    return {
        type = "enemy.goblin",
        hp   = config.hp   or 30,
        atk  = config.atk  or 5,
    }
end)

factory:register("enemy.troll", function(config)
    config = config or {}
    return {
        type = "enemy.troll",
        hp   = config.hp   or 120,
        atk  = config.atk  or 18,
    }
end)

factory:register("item.sword", function(config)
    config = config or {}
    return { type = "item.sword", damage = config.damage or 12 }
end)

-- Create instances — calls the registered constructor
local goblin = factory:create("enemy.goblin")
local troll  = factory:create("enemy.troll", { hp = 200, atk = 25 })   -- custom stats
local sword  = factory:create("item.sword")

luna.log.info(string.format("[Factory] goblin hp=%d  troll hp=%d  sword dmg=%d",
    goblin.hp, troll.hp, sword.damage))

-- Aliases let you create canonical names for variants
factory:alias("enemy.bigTroll", "enemy.troll")   -- bigTroll → troll constructor
local big = factory:create("enemy.bigTroll", { hp = 500 })
luna.log.debug("[Factory] bigTroll hp=" .. big.hp)

-- Inspect registered type names (aliases included)
local types = factory:getTypes()   -- { "enemy.goblin", "enemy.troll", "item.sword", "enemy.bigTroll" }
luna.log.info("[Factory] types: " .. table.concat(types, ", "))

-- Check if a type (or alias) is registered before creating
if factory:has("enemy.goblin") then
    local g2 = factory:create("enemy.goblin")
    luna.log.debug("[Factory] second goblin created, type=" .. g2.type)
end

-- Remove a type (by exact name, NOT aliases)
factory:remove("item.sword")
luna.log.debug("[Factory] has sword: " .. tostring(factory:has("item.sword")))   -- false

-- Clear all types and aliases
factory:clearAll()

-- ─────────────────────────────────────────────────────────────────────────────
-- SIMPLE STATE
-- Tracks a current named state and fires optional enter/exit callbacks on each
-- transition.  Use for game-mode FSMs (menu → playing → paused → game_over).
-- For full hierarchical FSMs see ideas/features/state_machine.md.
-- ─────────────────────────────────────────────────────────────────────────────

local game_fsm = luna.patterns.newSimpleState()

-- addState(name, callbacks) — callbacks table is optional
game_fsm:addState("menu", {
    enter = function(prev)
        luna.log.info(string.format("[FSM] entering 'menu'  (from '%s')", tostring(prev)))
    end,
    exit = function(next)
        luna.log.info(string.format("[FSM] leaving 'menu'  (to '%s')", tostring(next)))
    end,
    update = function(dt)
        -- Called every frame from your process() via game_fsm:update(dt)
        _ = dt
    end,
})

game_fsm:addState("playing", {
    enter = function(prev)
        luna.log.info(string.format("[FSM] entering 'playing'  (from '%s')", tostring(prev)))
    end,
    exit  = function(next)
        luna.log.info(string.format("[FSM] leaving 'playing'  (to '%s')", tostring(next)))
    end,
    update = function(dt)
        -- per-frame game logic delegated here
        _ = dt
    end,
})

game_fsm:addState("paused", {
    enter = function(prev) luna.log.info("[FSM] game paused") _ = prev end,
    exit  = function(next) luna.log.info("[FSM] game resumed") _ = next end,
})

game_fsm:addState("game_over", {
    enter = function(prev) luna.log.info("[FSM] GAME OVER") _ = prev end,
})

-- Initial state — fires the 'menu' enter callback (prev = nil)
game_fsm:transitionTo("menu")
luna.log.debug("[FSM] current: " .. game_fsm:getCurrent())   -- "menu"

-- Transition — fires exit("playing") on "menu", then enter("menu") on "playing"
game_fsm:transitionTo("playing")
game_fsm:transitionTo("paused")
game_fsm:transitionTo("playing")
game_fsm:transitionTo("game_over")

-- dispatch per-frame update to the active state's update function
-- In a real game: inside luna.process(dt) — game_fsm:update(dt)
game_fsm:update(0.016)   -- no-op: game_over has no update handler

-- Check if a state is registered
luna.log.debug("[FSM] has 'menu': "    .. tostring(game_fsm:hasState("menu")))    -- true
luna.log.debug("[FSM] has 'flying': "  .. tostring(game_fsm:hasState("flying")))  -- false

-- List all registered state names
local states = game_fsm:getStates()   -- { "menu", "playing", "paused", "game_over" }
luna.log.info("[FSM] registered states: " .. table.concat(states, ", "))

-- Remove all state registrations and reset current state
game_fsm:clearAll()
luna.log.debug("[FSM] after clearAll, current: " .. tostring(game_fsm:getCurrent()))  -- nil

luna.log.info("[patterns.lua] example complete")


-- REACTIVE & DATA-STRUCTURE PATTERNS

-- ─────────────────────────────────────────────────────────────────────────────
-- Blackboard
-- A shared key-value store for data-driven communication between subsystems.
-- ─────────────────────────────────────────────────────────────────────────────

local board = luna.patterns.newBlackboard("game_state")

board:set("paused", false)
board:set("score",  0)
board:set("player", "Hero")

local paused   = board:get("paused")    -- false
local all_keys = board:keys()           -- { "paused", "score", "player" }
local snap     = board:snapshot()       -- { paused=false, score=0, player="Hero" }
local rev      = board:getRevision()    -- 3

local watch_id = board:watch("score", function(key, val, old)
    luna.log.info(string.format("[Board] score: %d -> %d", old or 0, val))
end)

board:set("score", 100)   -- fires watcher
board:unwatch(watch_id)

-- ─────────────────────────────────────────────────────────────────────────────
-- Observer
-- Reactive properties: subscribe to individual property changes.
-- ─────────────────────────────────────────────────────────────────────────────

local obs = luna.patterns.newObserver("player_props")

local sub_id = obs:subscribe("health", function(key, val)
    luna.log.info(string.format("[Observer] %s = %d", key, val))
end)

obs:set("health", 100)   -- fires subscriber
obs:set("health", 80)    -- fires again

local hp = obs:get("health")         -- 80
local n  = obs:getCount()            -- 1 (one active subscription)

obs:unsubscribe(sub_id)              -- remove listener

-- "once" subscription: fires once, then auto-removes
obs:subscribe("level", function(key, val)
    luna.log.info("[Observer] level up: " .. tostring(val))
end, true)   -- once=true
obs:set("level", 2)    -- fires and unsubscribes
obs:set("level", 3)    -- no output

-- ─────────────────────────────────────────────────────────────────────────────
-- Debounce
-- Trailing-edge rate limiter: fires callback after input stream is idle.
-- Useful for search boxes, auto-save, or resize handlers.
-- ─────────────────────────────────────────────────────────────────────────────

local debounce = luna.patterns.newDebounce(0.3)   -- idle for 0.3 s before firing

debounce:onFire(function()
    luna.log.info("[Debounce] input stream settled — commit changes")
end)

debounce:trigger()   -- resets the idle timer
debounce:trigger()   -- reset again

local pending   = debounce:isPending()    -- true (timer is running)
local fire_cnt  = debounce:getFireCount() -- 0 (not fired yet)

-- Cancel the pending trigger without firing
debounce:cancel()
local pending2  = debounce:isPending()    -- false

-- ─────────────────────────────────────────────────────────────────────────────
-- Throttle
-- Leading-edge rate limiter: fires at most once per interval.
-- ─────────────────────────────────────────────────────────────────────────────

local throttle = luna.patterns.newThrottle(0.5)   -- at most once per 0.5 s

throttle:onFire(function()
    luna.log.info("[Throttle] fired!")
end)

-- Check progress through the current interval (0.0 = just fired, 1.0 = ready)
local prog = throttle:getProgress()     -- 0.0 (fresh)

-- Fire count since creation
local tfires = throttle:getFireCount()

-- Disable / re-enable
throttle:setEnabled(false)   -- suppresses all future fires
throttle:setEnabled(true)

-- Reset elapsed timer without firing
throttle:reset()

-- ─────────────────────────────────────────────────────────────────────────────
-- Funnel
-- Time-windowed event aggregator: buffers events and flushes as a batch.
-- ─────────────────────────────────────────────────────────────────────────────

local funnel = luna.patterns.newFunnel(0.1, 20, "damage_funnel")
-- window=0.1 s, max_entries=20 (auto-flush at capacity)

funnel:onFlush(function(entries)
    luna.log.info("[Funnel] batch: " .. #entries .. " events")
    for _, e in ipairs(entries) do
        luna.log.debug(string.format("  tag=%s val=%s", e.tag, tostring(e.value)))
    end
end)

funnel:push("hit",  { damage=10 })
funnel:push("hit",  { damage=25 })
funnel:push("heal", { amount=5  })

local pending_cnt = funnel:pendingCount()   -- 3
local flush_cnt   = funnel:getFlushCount()  -- 0

-- Force-flush without waiting for the window
funnel:flush()   -- invokes onFlush with all 3 entries

-- Discard buffered entries without flushing
funnel:push("hit", { damage=5 })
funnel:discard()                            -- silently clears the buffer

-- ─────────────────────────────────────────────────────────────────────────────
-- Ring Buffer
-- Fixed-capacity circular history log. Oldest value is overwritten on overflow.
-- Useful for frame-time histories, damage logs, rolling averages.
-- ─────────────────────────────────────────────────────────────────────────────

local ring = luna.patterns.newRing(8, "frame_times")

ring:push(16.0)
ring:push(17.5)
ring:push(15.8)
ring:push(18.1)

local latest = ring:latest()       -- 18.1
local count  = ring:len()          -- 4
local full   = ring:isFull()       -- false (capacity = 8)
local avg    = ring:average()      -- (16.0+17.5+15.8+18.1)/4 = 16.85
local total  = ring:sum()          -- 67.4
local arr    = ring:toArray()      -- { {id,tag,value=16.0}, ... } oldest first

-- ─────────────────────────────────────────────────────────────────────────────
-- PriorityQueue
-- Stable max-priority task queue. Items with higher priority dequeue first.
-- ─────────────────────────────────────────────────────────────────────────────

local pq = luna.patterns.newPriorityQueue("task_queue")

pq:push(10, { task="render_shadows" }, "render_shadows")
pq:push(50, { task="handle_input"   }, "handle_input")
pq:push(30, { task="update_ai"      }, "update_ai")

local len   = pq:len()      -- 3
local empty = pq:isEmpty()  -- false

-- Peek at highest-priority item without removing it
local top = pq:peek()       -- { task="handle_input" }  (priority 50)

-- Dequeue in priority order
local first  = pq:pop()     -- { task="handle_input"   }
local second = pq:pop()     -- { task="update_ai"      }
local third  = pq:pop()     -- { task="render_shadows" }
local none   = pq:pop()     -- nil (queue is empty)

luna.log.info("[patterns.lua] reactive/data-structure patterns example complete")
