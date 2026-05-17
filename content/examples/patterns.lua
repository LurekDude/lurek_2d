-- content/examples/patterns.lua
-- lurek.patterns API examples: data structures, design patterns, and game architecture utilities.
-- Run: cargo run -- content/examples/patterns.lua

--@api-stub: lurek.patterns.newEventBus
-- Create a new publish/subscribe event bus for decoupled communication between game systems
do
  -- EventBus decouples producers from consumers. Systems publish events without
  -- knowing who listens. Ideal for game-wide signals: damage dealt, level cleared,
  -- item picked up. Priority controls execution order of multiple subscribers.
  local bus = lurek.patterns.newEventBus("combat_bus")

  -- Subscribe to "hp_changed" so the HUD updates whenever any system modifies HP.
  -- Priority 100 means this runs before lower-priority listeners on the same event.
  local hud_id = bus:on("hp_changed", function(hp, max_hp)
    print("HUD: health bar " .. hp .. "/" .. max_hp)
  end, 100)

  -- A second listener with lower priority logs to analytics after HUD updates.
  bus:on("hp_changed", function(hp)
    if hp <= 0 then print("Analytics: player died") end
  end, 0)

  -- Any system can emit without knowing about listeners.
  bus:emit("hp_changed", 42, 100)

  -- Unsubscribe the HUD listener when leaving the game screen.
  bus:off(hud_id)
end

--@api-stub: lurek.patterns.newObjectPool
-- Create a new object pool for reusing pre-allocated game objects to reduce allocation overhead
do
  -- Object pools eliminate per-frame allocations for frequently spawned entities
  -- like bullets, particles, or hit effects. Pre-warm the pool at load time,
  -- then acquire/release during gameplay for zero-allocation spawning.
  local pool = lurek.patterns.newObjectPool()

  -- Pre-warm: add 32 bullet templates at scene load (not during gameplay).
  for i = 1, 32 do
    pool:add({ x = 0, y = 0, vx = 0, vy = 0, alive = false })
  end

  -- During gameplay: acquire reuses an existing bullet instead of allocating.
  ---@type {x:number, y:number, vx:number, vy:number, alive:boolean}?
  local bullet = pool:acquire()
  if bullet then
    bullet.x, bullet.y = 100, 200
    bullet.vx, bullet.vy = 300, 0
    bullet.alive = true
  end

  print("active=" .. pool:getActiveCount() .. " idle=" .. pool:getAvailableCount())
end

--@api-stub: lurek.patterns.newCommandStack
-- Create a new undo/redo command stack for recording and reversing player or editor actions
do
  -- CommandStack records forward and backward operations for undo/redo support.
  -- Essential for level editors, turn-based games, or any user action that should
  -- be reversible. maxSize=64 limits memory to the last 64 actions.
  local stack = lurek.patterns.newCommandStack(64)

  -- Simulate a tile painter in a level editor.
  local tile_x, tile_y, tile_type = 5, 3, "wall"
  local prev_type = "floor"

  -- execute() runs the forward action immediately and stores the undo.
  stack:execute("paint_tile",
    function() tile_type = "wall" end,   -- forward: paint the tile
    function() tile_type = prev_type end -- backward: restore original
  )
  print("after paint: " .. tile_type)

  -- Player hits Ctrl+Z.
  stack:undo()
  print("after undo: " .. tile_type)

  -- Player hits Ctrl+Y.
  stack:redo()
  print("after redo: " .. tile_type)
end

--@api-stub: lurek.patterns.newServiceLocator
-- Create a new service locator for registering and retrieving shared services by name at runtime
do
  -- ServiceLocator provides runtime dependency injection without globals.
  -- Register services once at startup, then any system can locate them by name.
  -- Useful for swapping implementations (e.g. real audio vs silent audio in tests).
  local services = lurek.patterns.newServiceLocator()

  -- Register core services at game boot.
  services:provide("logger", {
    info = function(msg) print("[INFO] " .. msg) end,
    warn = function(msg) print("[WARN] " .. msg) end,
  })
  services:provide("save_system", { slot = "slot1", path = "save/" })

  -- Any game system can locate what it needs without hard coupling.
  ---@type {info:fun(msg:string), warn:fun(msg:string)}?
  local log = services:locate("logger")
  if log then log.info("all services online") end

  -- Check before use to handle optional services gracefully.
  if services:has("analytics") then
    ---@type {track:fun(event:string)}
    local analytics = services:locate("analytics")
    analytics.track("session_start")
  end
end

--@api-stub: lurek.patterns.newFactory
-- Create a new factory for producing typed game objects from registered constructor functions
do
  -- Factory pattern centralizes object creation. Register constructors once,
  -- then spawn by type name from data files, spawn tables, or level scripts.
  -- Keeps spawning logic in one place and easy to extend.
  local enemies = lurek.patterns.newFactory()

  -- Register enemy constructors with position and optional stats.
  enemies:register("goblin", function(x, y)
    return { kind = "goblin", x = x, y = y, hp = 20, speed = 80 }
  end)
  enemies:register("skeleton", function(x, y)
    return { kind = "skeleton", x = x, y = y, hp = 40, speed = 50 }
  end)

  -- Spawn enemies from level data without switch/if chains.
  local spawn_list = { {"goblin", 64, 32}, {"skeleton", 128, 64} }
  for _, info in ipairs(spawn_list) do
    ---@type {kind:string, x:number, y:number, hp:number, speed:number}?
    local e = enemies:create(info[1], info[2], info[3])
    if e then print("spawned " .. e.kind .. " at " .. e.x .. "," .. e.y) end
  end
end

--@api-stub: lurek.patterns.newSimpleState
-- Create a new finite state machine with enter/exit/update callbacks per state
do
  -- Finite state machines organize game entity behavior into discrete states.
  -- Each state can have enter (setup), exit (cleanup), and update (per-frame) callbacks.
  -- Transitions automatically call exit on the old state and enter on the new one.
  local sm = lurek.patterns.newSimpleState()

  sm:addState("idle", {
    enter = function() print("  > idle: playing idle animation") end,
    exit  = function() print("  < idle: stopping idle animation") end,
  })
  sm:addState("patrol", {
    enter  = function() print("  > patrol: picking waypoint") end,
    update = function(dt) print("  . patrol: walking dt=" .. string.format("%.3f", dt)) end,
    exit   = function() print("  < patrol: reached waypoint") end,
  })
  sm:addState("chase", {
    enter  = function() print("  > chase: spotted player!") end,
    update = function(dt) print("  . chase: closing in") end,
  })

  -- Start in idle, then transition based on game events.
  sm:transitionTo("idle")
  sm:transitionTo("patrol")
  sm:update(0.016)
end

--@api-stub: lurek.patterns.newBlackboard
-- Create a new shared key-value blackboard supporting reactive watchers for game logic variables
do
  -- Blackboard is a shared data store for AI and game systems. Multiple systems
  -- can read/write values, and watchers react to changes automatically.
  -- Common use: AI reads "player_visible" set by the perception system.
  local bb = lurek.patterns.newBlackboard("ai_world")

  -- Perception system writes what it detects.
  bb:set("player_hp", 100)
  bb:set("player_visible", true)
  bb:set("alarm_active", false)

  -- AI reads the blackboard to make decisions.
  if bb:get("player_visible") and bb:get("player_hp") < 25 then
    bb:set("alarm_active", true)
  end
  print("alarm=" .. tostring(bb:get("alarm_active")))
end

--@api-stub: lurek.patterns.newObserver
-- Create a new reactive observer that stores values and notifies subscribers when they change
do
  -- Observer stores key-value pairs and fires callbacks when values change.
  -- Perfect for binding game state to UI: when score changes, the HUD auto-updates
  -- without polling. Lighter than EventBus when you just need value-change reactivity.
  local obs = lurek.patterns.newObserver("hud_bindings")

  -- The HUD subscribes to score changes and auto-refreshes its display.
  obs:subscribe("score", function(key, new_value)
    print("HUD: " .. key .. " is now " .. new_value)
  end)

  -- Game logic sets values; HUD reacts without being called directly.
  obs:set("score", 0)
  obs:set("score", 100)  -- triggers subscriber
  obs:set("score", 250)  -- triggers subscriber again
end

--@api-stub: lurek.patterns.newThrottle
-- Create a new throttle that limits how often an action can fire, enforcing a minimum interval
do
  -- Throttle enforces a cooldown between executions. Use for weapon fire rates,
  -- autosave intervals, network packet sending, or any action that should not
  -- happen more than once per N seconds regardless of how often it's triggered.
  local weapon_fire = lurek.patterns.newThrottle(0.25)  -- 4 shots per second max

  weapon_fire:onFire(function()
    print("BANG! bullet spawned")
  end)

  -- Even if the player holds the fire button every frame, shots are rate-limited.
  -- In a real game, call this in lurek.process(dt).
  weapon_fire:update(0.016)  -- not enough time passed, no fire
  weapon_fire:update(0.25)   -- interval elapsed, fires!
  print("shots fired=" .. weapon_fire:getFireCount())
end

--@api-stub: lurek.patterns.newDebounce
-- Create a new debounce that delays firing until input stops for a specified wait period
do
  -- Debounce waits for a pause in activity before firing. Unlike throttle (which fires
  -- at intervals), debounce fires ONCE after the user stops triggering for `wait` seconds.
  -- Ideal for: autosave after edits stop, search-as-you-type, resize handling.
  local autosave = lurek.patterns.newDebounce(0.5)  -- save 0.5s after last edit

  autosave:onFire(function()
    print("autosave: writing to disk")
  end)

  -- Each trigger resets the timer. Only fires when edits pause for 0.5s.
  autosave:trigger()  -- user typed
  autosave:trigger()  -- user typed again, timer resets
  -- After 0.5s of no triggers, the callback fires.
  print("pending=" .. tostring(autosave:isPending()))
end

--@api-stub: lurek.patterns.newPriorityQueue
-- Create a new priority queue that orders elements by numeric priority (highest first)
do
  -- PriorityQueue always dequeues the highest-priority item first. Use for AI task
  -- scheduling, event processing order, job systems, or any situation where items
  -- have different urgency levels.
  local ai_tasks = lurek.patterns.newPriorityQueue("ai_scheduler")

  -- Higher priority number = processed first.
  ai_tasks:push(10, { kind = "patrol", waypoint = 3 }, "low")
  ai_tasks:push(50, { kind = "attack", target = "player" }, "urgent")
  ai_tasks:push(30, { kind = "investigate", pos_x = 100 }, "medium")

  -- The AI processes the most important task first.
  ---@type {kind:string}?
  local task = ai_tasks:pop()
  if task then print("executing: " .. task.kind) end  -- "attack"
end

--@api-stub: lurek.patterns.newRing
-- Create a new fixed-size ring buffer for numeric or string values
do
  -- Ring buffer stores the last N values, overwriting the oldest when full.
  -- Perfect for FPS counters, rolling averages, recent chat messages, or any
  -- sliding-window metric. Fixed memory regardless of how long the game runs.
  local fps_log = lurek.patterns.newRing(60, "fps_tracker")

  -- Simulate 65 frames of FPS data. Only the last 60 are kept.
  for i = 1, 65 do
    fps_log:push(58 + (i % 4), "frame")
  end

  -- average() gives the rolling average over the buffer window.
  print("avg fps=" .. string.format("%.1f", fps_log:average())
    .. " samples=" .. fps_log:len())
end

--@api-stub: lurek.patterns.newFunnel
-- Create a new batching funnel that collects events over a time window and flushes them together
do
  -- Funnel batches many small events into periodic bulk flushes. Use for analytics,
  -- network batching, or any case where you want to aggregate events over a time
  -- window instead of processing them one by one.
  local analytics = lurek.patterns.newFunnel(2.0, 32, "game_events")

  analytics:onFlush(function(batch)
    -- In production, this would send the batch to a server.
    print("flushing " .. #batch .. " analytics events")
  end)

  -- Individual events accumulate silently.
  analytics:push("level_start", 1)
  analytics:push("enemy_killed", 5)
  analytics:push("item_collected", 1)
  -- After 2 seconds or 32 events, onFlush fires with the full batch.
  print("buffered=" .. analytics:pendingCount())
end

--@api-stub: lurek.patterns.newRelationshipManager
-- Create a new relationship manager for tracking numeric values and named levels between entity pairs
do
  -- RelationshipManager tracks pairwise relationships between entities. Stores both
  -- a numeric value (reputation score) and named levels (hostile/neutral/ally).
  -- Ideal for faction systems, NPC disposition, diplomacy in strategy games.
  local rel = lurek.patterns.newRelationshipManager()

  -- Define relationship types with ordered levels.
  rel:defineType("diplomacy", { "hostile", "neutral", "friendly", "ally" }, "neutral")

  -- Set numeric affinity between two faction IDs.
  local player_id, merchant_id = 101, 202
  rel:setValue(player_id, merchant_id, 50)

  -- Set the named level based on game events.
  rel:setLevel(player_id, merchant_id, "diplomacy", "friendly")

  -- Query relationships for gameplay decisions.
  local level = rel:getLevel(player_id, merchant_id, "diplomacy")
  local value = rel:getValue(player_id, merchant_id)
  print("merchant is " .. tostring(level) .. " (score=" .. tostring(value) .. ")")
end

--@api-stub: lurek.patterns.newMediator
-- Create a new mediator for channel-based message passing between decoupled game systems
do
  -- Mediator provides named channels for message passing. Unlike EventBus (which uses
  -- event names), Mediator is designed for system-to-system communication where you
  -- want explicit channel control. Supports broadcast to all channels at once.
  local hub = lurek.patterns.newMediator()

  -- Systems register on their channels.
  hub:on("chat", function(user, msg)
    print("[chat] " .. user .. ": " .. msg)
  end)
  hub:on("combat_log", function(attacker, target, dmg)
    print("[combat] " .. attacker .. " hit " .. target .. " for " .. dmg)
  end)

  -- Any system sends messages to the appropriate channel.
  hub:send("chat", "alice", "gg")
  hub:send("combat_log", "warrior", "dragon", 150)
end

--@api-stub: lurek.patterns.newStrategy
-- Create a new strategy pattern container for hot-swappable algorithm implementations
do
  -- Strategy pattern lets you swap algorithms at runtime without conditionals.
  -- Register multiple implementations, then switch between them based on game state.
  -- Example: different damage formulas for normal vs critical vs magical attacks.
  local damage_calc = lurek.patterns.newStrategy()

  damage_calc:register("normal", function(atk, def)
    return math.max(1, atk - def)
  end)
  damage_calc:register("critical", function(atk, def)
    return math.max(1, atk * 2 - def)
  end)
  damage_calc:register("magical", function(atk, def)
    -- Magic ignores half of defense.
    return math.max(1, atk - math.floor(def / 2))
  end)

  -- Switch strategy based on combat conditions.
  damage_calc:set("critical")
  local dmg = damage_calc:execute(20, 5)
  print("critical hit dmg=" .. dmg)
end

--@api-stub: lurek.patterns.newStack
-- Create a new LIFO stack with optional capacity limit
do
  -- Stack is last-in first-out. Use for navigation history (back button), undo stacks,
  -- scene layering (push dialog on top of game), or bracket matching.
  -- Capacity 8 prevents unbounded growth from bugs.
  local scene_stack = lurek.patterns.newStack(8)

  -- Push scenes as the player navigates deeper.
  scene_stack:push("main_menu")
  scene_stack:push("world_map")
  scene_stack:push("inventory")

  -- Peek shows current scene without modifying the stack.
  print("current=" .. scene_stack:peek() .. " depth=" .. scene_stack:len())

  -- Pop returns to the previous scene (like pressing Back).
  scene_stack:pop()
  print("back to=" .. scene_stack:peek())
end

--@api-stub: lurek.patterns.newQueue
-- Create a new FIFO queue with optional capacity limit
do
  -- Queue is first-in first-out. Use for message queues, turn order, AI command
  -- queues, or any pipeline where items are processed in arrival order.
  -- Capacity 0 means unlimited.
  local mail = lurek.patterns.newQueue(0)

  -- Messages arrive from different systems.
  mail:enqueue("quest_accepted")
  mail:enqueue("item_received")
  mail:enqueue("achievement_unlocked")

  -- Process in order: first message sent is first message handled.
  print("next=" .. mail:front() .. " total=" .. mail:len())
end

--@api-stub: lurek.patterns.newList
-- Create a new dynamic array list with indexed access, insertion, removal, and search
do
  -- List is a dynamic array with 1-based indexing. Use for inventory slots, quest logs,
  -- ordered collections where you need random access by index. Grows as needed.
  local quest_log = lurek.patterns.newList()

  quest_log:add("Find the lost sword")
  quest_log:add("Defeat the dragon")
  quest_log:add("Return to the village")

  -- Update a quest description.
  quest_log:set(1, "Find the enchanted sword")
  print("active quest: " .. quest_log:get(1))
  print("total quests: " .. quest_log:len())
end

--@api-stub: lurek.patterns.newSet
-- Create a new string set with add/remove/has operations and set algebra (union, intersection)
do
  -- Set stores unique strings with O(1) lookup. Use for tracking collected items,
  -- visited rooms, unlocked achievements, or active status effects.
  -- Supports union/intersection for comparing player inventories or requirements.
  local unlocked = lurek.patterns.newSet()

  unlocked:add("level_1")
  unlocked:add("level_2")
  unlocked:add("boss_key")

  -- Fast membership check for game logic.
  if unlocked:has("boss_key") then
    print("boss door: access granted")
  end
  print("unlocked " .. unlocked:len() .. " items")
end

--@api-stub: LMediator:on
-- Subscribe a callback to a named event with optional priority ordering
do
  local bus = lurek.patterns.newEventBus("game")

  -- Priority 100 ensures this listener fires before default-priority (0) listeners.
  -- Returns a numeric ID for later unsubscription.
  local id = bus:on("level_clear", function(level_name)
    print("  level cleared: " .. level_name)
  end, 100)

  bus:emit("level_clear", "forest_01")
  bus:off(id)
end

--@api-stub: LMediator:off
-- Unsubscribe a listener by its subscription ID
do
  local bus = lurek.patterns.newEventBus()
  local id = bus:on("ping", function() print("pong") end)

  -- Unsubscribe when the listener's owner is destroyed or no longer relevant.
  bus:off(id)
  bus:emit("ping")  -- no output: listener was removed
  print("listeners=" .. bus:getListenerCount("ping"))
end

--@api-stub: LEventBus:emit
-- Emit an event, invoking all listeners in priority order with payload arguments
do
  local bus = lurek.patterns.newEventBus()

  -- Listeners receive all arguments passed after the event name.
  bus:on("damage", function(amount, source)
    print("  " .. source .. " dealt " .. amount .. " damage")
  end)

  -- Multiple emits, each with different payloads.
  bus:emit("damage", 12, "goblin")
  bus:emit("damage", 30, "boss")
end

--@api-stub: LMap:clear
-- Remove all listeners for a specific event name
do
  local bus = lurek.patterns.newEventBus()
  bus:on("minigame_end", function(score) print("  score: " .. score) end)
  bus:on("minigame_end", function(score) print("  hud update: " .. score) end)

  -- When the minigame scene unloads, clear all its listeners at once.
  bus:clear("minigame_end")
  print("after clear: " .. bus:getListenerCount("minigame_end") .. " listeners")
end

--@api-stub: LPatternGraph:clearAll
-- Remove all listeners from every event on this bus
do
  local bus = lurek.patterns.newEventBus()
  bus:on("save", function() end)
  bus:on("load", function() end)

  -- Full reset when transitioning between major game states.
  bus:clearAll()
  print("events remaining=" .. #bus:getEvents())
end

--@api-stub: LEventBus:getListenerCount
-- Return the number of active listeners for a given event
do
  local bus = lurek.patterns.newEventBus()
  bus:on("hit", function() end)
  bus:on("hit", function() end)

  -- Use to detect listener leaks during development.
  local n = bus:getListenerCount("hit")
  if n > 10 then print("WARNING: " .. n .. " hit listeners, possible leak") end
  print("hit listeners=" .. n)
end

--@api-stub: LEventBus:getEvents
-- Return an array of all event names that have at least one listener
do
  local bus = lurek.patterns.newEventBus()
  bus:on("save", function() end)
  bus:on("quit", function() end)

  -- Useful for debug overlays showing active event channels.
  for _, name in ipairs(bus:getEvents()) do
    print("  active channel: " .. name)
  end
end

--@api-stub: LWeightedRandom:add
-- Add an object to the pool's idle set for future acquisition
do
  local bullets = lurek.patterns.newObjectPool()

  -- Pre-warm at load time: create all objects up front to avoid runtime allocation.
  for i = 1, 32 do
    bullets:add({ x = 0, y = 0, alive = false, sprite_id = i })
  end
  print("pool pre-warmed: " .. bullets:getAvailableCount() .. " bullets ready")
end

--@api-stub: LObjectPool:acquire
-- Take an idle object from the pool and mark it active
do
  local pool = lurek.patterns.newObjectPool()
  pool:add({ x = 0, y = 0, vx = 0, vy = 0 })

  -- acquire() returns nil if the pool is exhausted, so always check.
  ---@type {x:number, y:number, vx:number, vy:number}?
  local b = pool:acquire()
  if b then
    -- Reset the object for its new life. The pool reuses memory.
    b.x, b.y = 50, 50
    b.vx = 200
  end
  print("active=" .. pool:getActiveCount())
end

--@api-stub: LObjectPool:release
-- Return an active object back to the pool's idle set for reuse
do
  local pool = lurek.patterns.newObjectPool()
  pool:add({ alive = false })

  ---@type {alive:boolean}?
  local obj = pool:acquire()
  obj.alive = true

  -- When the bullet leaves the screen or hits something, release it back.
  obj.alive = false
  pool:release(obj)
  print("returned to pool, idle=" .. pool:getAvailableCount())
end

--@api-stub: LObjectPool:getActiveCount
-- Return how many objects are currently checked out from the pool
do
  local pool = lurek.patterns.newObjectPool()
  pool:add({}); pool:add({})
  pool:acquire(); pool:acquire()

  -- Monitor for pool leaks: if active count grows unbounded, something is not releasing.
  local n = pool:getActiveCount()
  if n > 100 then print("WARN: pool leak detected, active=" .. n) end
  print("active=" .. n)
end

--@api-stub: LObjectPool:getAvailableCount
-- Return how many idle objects are ready for acquisition
do
  local pool = lurek.patterns.newObjectPool()
  for i = 1, 4 do pool:add({}) end
  pool:acquire()

  -- Dynamically grow the pool if it's running low.
  if pool:getAvailableCount() < 2 then
    pool:add({})  -- add more capacity under pressure
  end
  print("idle=" .. pool:getAvailableCount())
end

--@api-stub: LObjectPool:getTotalCount
-- Return the total number of objects managed (active + idle)
do
  local pool = lurek.patterns.newObjectPool()
  for i = 1, 16 do pool:add({}) end
  pool:acquire()

  -- Total = active + available. Useful for memory budget monitoring.
  print("total=" .. pool:getTotalCount() .. " active=" .. pool:getActiveCount())
end

--@api-stub: LPatternGraph:clearAll
-- Destroy all objects (active and idle) and reset the pool to empty
do
  local pool = lurek.patterns.newObjectPool()
  pool:add({}); pool:add({})

  -- Use when changing levels or scenes to free all pooled resources.
  pool:clearAll()
  print("after clearAll: total=" .. pool:getTotalCount())
end

--@api-stub: LStrategy:execute
-- Execute a named command, recording it in history for undo/redo
do
  local stack = lurek.patterns.newCommandStack(0)
  local doc = { text = "hello" }

  -- Store state before the edit so undo can restore it.
  local prev_text = doc.text
  stack:execute("append_excl",
    function() doc.text = doc.text .. "!" end,  -- forward
    function() doc.text = prev_text end         -- undo restores previous
  )
  print("doc=" .. doc.text)
end

--@api-stub: LCommandStack:undo
-- Undo the most recent command by calling its undo function
do
  local stack = lurek.patterns.newCommandStack(0)
  local x = 5

  stack:execute("increment", function() x = x + 1 end, function() x = x - 1 end)
  local ok = stack:undo()
  print("undone=" .. tostring(ok) .. " x=" .. x)  -- x is back to 5
end

--@api-stub: LCommandStack:redo
-- Redo a previously undone command by re-calling its execute function
do
  local stack = lurek.patterns.newCommandStack(0)
  local n = 0

  stack:execute("step", function() n = n + 1 end, function() n = n - 1 end)
  stack:undo()   -- n=0
  stack:redo()   -- n=1 again
  print("after redo n=" .. n)
end

--@api-stub: LCommandStack:canUndo
-- Check whether an undo operation is possible
do
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("action", function() end, function() end)

  -- Use to enable/disable the undo button in UI.
  if stack:canUndo() then print("undo button: enabled") end
end

--@api-stub: LCommandStack:canRedo
-- Check whether a redo operation is possible
do
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("action", function() end, function() end)
  stack:undo()

  -- Use to enable/disable the redo button in UI.
  if stack:canRedo() then print("redo button: enabled") end
end

--@api-stub: LCommandStack:getHistorySize
-- Return the total number of commands in history
do
  local stack = lurek.patterns.newCommandStack(0)
  for i = 1, 5 do
    stack:execute("op_" .. i, function() end, function() end)
  end
  print("history depth=" .. stack:getHistorySize())
end

--@api-stub: LCommandStack:getCurrentName
-- Return the name of the most recently executed command
do
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("paint_red", function() end, function() end)

  -- Show in UI: "Undo: paint_red"
  local name = stack:getCurrentName()
  if name then print("undo will revert: " .. name) end
end

--@api-stub: LPatternGraph:clearAll
-- Discard all command history and free callbacks
do
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("a", function() end, function() end)

  -- Clear when starting a new document or level.
  stack:clearAll()
  print("history after clear=" .. stack:getHistorySize())
end

--@api-stub: LServiceLocator:provide
-- Register a service instance under a given name
do
  local sl = lurek.patterns.newServiceLocator()

  -- Register services at startup. Each has a unique name.
  sl:provide("clock", { now = function() return 42.0 end })
  sl:provide("save_manager", { path = "save/slot1.dat" })
  print("registered services=" .. #sl:getServices())
end

--@api-stub: LServiceLocator:locate
-- Retrieve a registered service by name (returns nil if not found)
do
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("audio", { volume = 0.8, muted = false })

  -- locate() returns the exact table/value that was provided.
  ---@type {volume:number, muted:boolean}?
  local audio = sl:locate("audio")
  if audio then print("volume=" .. audio.volume) end
end

--@api-stub: LMap:has
-- Check whether a service with the given name is registered
do
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("analytics", { enabled = true })

  -- Guard optional services before use.
  if sl:has("analytics") then print("telemetry active") end
end

--@api-stub: LWeightedRandom:remove
-- Unregister and discard a service by name
do
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("network", { online = true })

  -- Remove when going offline or shutting down a subsystem.
  sl:remove("network")
  print("network registered=" .. tostring(sl:has("network")))
end

--@api-stub: LServiceLocator:getServices
-- Return an array of all registered service names
do
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("renderer", {}); sl:provide("physics", {})

  -- Debug overlay: list all active services.
  for _, name in ipairs(sl:getServices()) do print("  service: " .. name) end
end

--@api-stub: LPatternGraph:clearAll
-- Remove all registered services and reset the locator
do
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("x", 1); sl:provide("y", 2)

  -- Full reset between game sessions.
  sl:clearAll()
  print("services after clear=" .. #sl:getServices())
end

--@api-stub: LStrategy:register
-- Register a constructor function for a given type name
do
  local f = lurek.patterns.newFactory()

  -- Each type gets a constructor that returns a fresh instance.
  f:register("orc", function(x, y) return { kind = "orc", hp = 30, x = x, y = y } end)
  f:register("troll", function(x, y) return { kind = "troll", hp = 80, x = x, y = y } end)
  print("registered types=" .. #f:getTypes())
end

--@api-stub: LFactory:create
-- Create a new object by type name, forwarding arguments to the constructor
do
  local f = lurek.patterns.newFactory()
  f:register("coin", function(value) return { kind = "coin", value = value } end)

  -- Arguments after type name are forwarded to the constructor.
  ---@type {kind:string, value:number}?
  local c = f:create("coin", 50)
  if c then print("dropped " .. c.value .. " gold") end
end

--@api-stub: LMap:has
-- Check whether a constructor is registered for the given type
do
  local f = lurek.patterns.newFactory()
  f:register("npc", function() return { kind = "npc" } end)

  -- Guard before create() to avoid silent nil returns.
  if f:has("npc") then print("npc factory ready") end
end

--@api-stub: LFactory:alias
-- Create an alias that maps to an existing type name
do
  local f = lurek.patterns.newFactory()
  f:register("goblin", function() return { kind = "goblin" } end)

  -- Alias lets old level data reference new type names without migration.
  f:alias("monster_v1", "goblin")
  ---@type {kind:string}?
  local m = f:create("monster_v1")
  if m then print("created via alias: " .. m.kind) end
end

--@api-stub: LFactory:getTypes
-- Return an array of all registered type names
do
  local f = lurek.patterns.newFactory()
  f:register("warrior", function() end); f:register("mage", function() end)

  -- Useful for editor dropdowns or spawn-menu population.
  for _, name in ipairs(f:getTypes()) do print("  type: " .. name) end
end

--@api-stub: LWeightedRandom:remove
-- Unregister a type and discard its constructor
do
  local f = lurek.patterns.newFactory()
  f:register("temp_enemy", function() return {} end)

  -- Remove deprecated types to prevent accidental spawning.
  f:remove("temp_enemy")
  print("temp still registered=" .. tostring(f:has("temp_enemy")))
end

--@api-stub: LPatternGraph:clearAll
-- Remove all registered types and reset the factory
do
  local f = lurek.patterns.newFactory()
  f:register("x", function() end)

  -- Full reset when loading a new mod or level pack.
  f:clearAll()
  print("types after clear=" .. #f:getTypes())
end

--@api-stub: LSimpleState:addState
-- Register a named state with optional enter, exit, and update callbacks
do
  local sm = lurek.patterns.newSimpleState()

  -- Each state can have any combination of enter/exit/update.
  sm:addState("idle", {
    enter = function() print("  > entering idle") end,
    exit  = function() print("  < leaving idle") end,
  })
  sm:addState("attack", {
    update = function(dt) print("  . attacking, dt=" .. dt) end,
  })
  print("registered states=" .. #sm:getStates())
end

--@api-stub: LSimpleState:transitionTo
-- Transition to a new state, calling exit on current and enter on target
do
  local sm = lurek.patterns.newSimpleState()
  sm:addState("menu", { enter = function() print("  > menu shown") end })
  sm:addState("game", { enter = function() print("  > game started") end })

  -- Transition calls menu:exit (if defined) then game:enter.
  sm:transitionTo("menu")
  sm:transitionTo("game")
end

--@api-stub: LFunnel:update
-- Call the current state's update callback with frame delta time
do
  local sm = lurek.patterns.newSimpleState()
  sm:addState("run", {
    update = function(dt) print("  . running at dt=" .. dt) end,
  })
  sm:transitionTo("run")

  -- Call each frame with the real delta time.
  sm:update(0.016)
end

--@api-stub: LStrategy:getCurrent
-- Return the name of the currently active state
do
  local sm = lurek.patterns.newSimpleState()
  sm:addState("paused", {})
  sm:transitionTo("paused")

  -- Use for conditional logic outside the FSM.
  if sm:getCurrent() == "paused" then print("game is paused") end
end

--@api-stub: LSimpleState:hasState
-- Check whether a state with the given name is registered
do
  local sm = lurek.patterns.newSimpleState()
  sm:addState("boss_fight", {})

  -- Guard transitions to prevent errors on missing states.
  if sm:hasState("boss_fight") then sm:transitionTo("boss_fight") end
end

--@api-stub: LSimpleState:getStates
-- Return an array of all registered state names
do
  local sm = lurek.patterns.newSimpleState()
  sm:addState("idle", {}); sm:addState("walk", {}); sm:addState("jump", {})

  -- Debug: list all possible states.
  for _, name in ipairs(sm:getStates()) do print("  state: " .. name) end
end

--@api-stub: LPatternGraph:clearAll
-- Remove all states and their callbacks, resetting the state machine
do
  local sm = lurek.patterns.newSimpleState()
  sm:addState("temp", {})

  -- Reset when loading a completely new entity configuration.
  sm:clearAll()
  print("states left=" .. #sm:getStates())
end

--@api-stub: LMap:set
-- Store a value (bool, number, string, or nil to clear) under a key
do
  local bb = lurek.patterns.newBlackboard()

  -- Supports multiple value types. nil clears the key.
  bb:set("hp", 100)
  bb:set("name", "Aria")
  bb:set("is_hostile", true)
  print("name=" .. bb:get("name"))
end

--@api-stub: LMap:get
-- Retrieve a value by key (returns nil if not set)
do
  local bb = lurek.patterns.newBlackboard()
  bb:set("ammo", 12)

  -- Always handle nil for keys that might not exist yet.
  local ammo = bb:get("ammo") or 0
  if ammo <= 0 then print("reload needed!") else print("ammo=" .. ammo) end
end

--@api-stub: LMap:keys
-- Return an array of all keys currently stored on the blackboard
do
  local bb = lurek.patterns.newBlackboard()
  bb:set("hp", 50); bb:set("mode", "patrol")

  -- Iterate all stored data for serialization or debug display.
  for _, k in ipairs(bb:keys()) do
    print("  " .. k .. "=" .. tostring(bb:get(k)))
  end
end

--@api-stub: LBlackboard:watch
-- Register a watcher callback that fires when a key changes (use "*" for all keys)
do
  local bb = lurek.patterns.newBlackboard()

  -- Watch a specific key. Callback receives (key, newValue).
  local id = bb:watch("hp", function(key, value)
    print("  " .. key .. " changed to " .. tostring(value))
  end)

  bb:set("hp", 75)  -- triggers watcher
  bb:unwatch(id)    -- stop watching
end

--@api-stub: LBlackboard:unwatch
-- Remove a previously registered watcher by its ID
do
  local bb = lurek.patterns.newBlackboard()

  -- "*" watches ALL key changes on this blackboard.
  local id = bb:watch("*", function(k) print("  write to " .. k) end)
  bb:set("debug", "on")  -- triggers

  -- Remove watcher when the observing system is destroyed.
  bb:unwatch(id)
  bb:set("debug", "off")  -- no trigger
end

--@api-stub: LWeightedRandom:getRevision
-- Return the revision counter (increments on every value change)
do
  local bb = lurek.patterns.newBlackboard()
  local last_rev = bb:getRevision()

  bb:set("k", 1)
  -- Use revision to detect if anything changed since last check (dirty flag pattern).
  if bb:getRevision() ~= last_rev then print("blackboard is dirty") end
end

--@api-stub: LBlackboard:snapshot
-- Return a table copy of all key-value pairs (useful for serialization or debug)
do
  local bb = lurek.patterns.newBlackboard()
  bb:set("hp", 80); bb:set("mode", "alert")

  -- snapshot() returns a plain Lua table you can serialize or inspect.
  local snap = bb:snapshot()
  for k, v in pairs(snap) do print("  " .. k .. "=" .. tostring(v)) end
end

--@api-stub: LPatternGraph:clearAll
-- Remove all keys and values from the blackboard
do
  local bb = lurek.patterns.newBlackboard()
  bb:set("hp", 100)

  -- Reset between encounters or when loading a new AI context.
  bb:clearAll()
  print("keys after clear=" .. #bb:keys())
end

--@api-stub: LMap:set
-- Set a value by key and notify all subscribers watching that key
do
  local o = lurek.patterns.newObserver("player_data")

  -- Subscriber fires every time the value changes.
  o:subscribe("hp", function(key, value)
    print("  HUD: " .. key .. "=" .. value)
  end)

  o:set("hp", 100)  -- triggers subscriber
  o:set("hp", 75)   -- triggers again with new value
end

--@api-stub: LMap:get
-- Retrieve the current value for a key (returns nil if not set)
do
  local o = lurek.patterns.newObserver()
  o:set("score", 1500)

  -- Read current value without triggering any notifications.
  local s = o:get("score") or 0
  print("current score=" .. s)
end

--@api-stub: LObserver:subscribe
-- Subscribe to changes on a key; callback receives (key, newValue) on each change
do
  local o = lurek.patterns.newObserver()

  -- Subscribe returns an ID for later unsubscription.
  local id = o:subscribe("lives", function(k, v)
    print("  " .. k .. " is now " .. tostring(v))
  end)

  o:set("lives", 3)
  o:set("lives", 2)
  o:unsubscribe(id)
end

--@api-stub: LObserver:unsubscribe
-- Remove a subscription by its ID
do
  local o = lurek.patterns.newObserver()
  local id = o:subscribe("key", function() end)

  -- Always unsubscribe when the subscriber is destroyed to prevent leaks.
  o:unsubscribe(id)
  print("subscriptions remaining=" .. o:getCount())
end

--@api-stub: LObserver:getCount
-- Return the total number of active subscriptions across all keys
do
  local o = lurek.patterns.newObserver()
  o:subscribe("a", function() end)
  o:subscribe("b", function() end)

  -- Monitor subscription count to detect leaks.
  print("active subscriptions=" .. o:getCount())
end

--@api-stub: LDebounce:onFire
-- Set the callback function to invoke each time the throttle fires
do
  local t = lurek.patterns.newThrottle(0.5)

  -- onFire sets the action that executes when the interval elapses.
  t:onFire(function()
    print("  periodic tick")
  end)
  -- In a real game: function lurek.process(dt) t:update(dt) end
end

--@api-stub: LFunnel:update
-- Advance the throttle timer; returns true if it fired this frame
do
  local t = lurek.patterns.newThrottle(0.25)
  t:onFire(function() print("  autosave check") end)

  -- update() returns true on the frame the throttle fires.
  -- Use the return value to trigger additional logic.
  local fired = t:update(0.30)
  if fired then print("  additional post-fire logic") end
end

--@api-stub: LThrottle:reset
-- Reset the throttle timer back to zero without firing
do
  local t = lurek.patterns.newThrottle(1.0)
  t:onFire(function() end)
  t:update(0.7)  -- 70% through interval

  -- Reset when the player changes weapon or cancels an action.
  t:reset()
  print("progress after reset=" .. t:getProgress())  -- 0.0
end

--@api-stub: LThrottle:getProgress
-- Return how far through the current interval (0.0 to 1.0)
do
  local t = lurek.patterns.newThrottle(2.0)
  t:onFire(function() end)
  t:update(0.5)

  -- Use progress for cooldown bar UI visualization.
  local pct = math.floor(t:getProgress() * 100)
  print("cooldown: " .. pct .. "% filled")
end

--@api-stub: LDebounce:getFireCount
-- Return the total number of times this throttle has fired since creation
do
  local t = lurek.patterns.newThrottle(0.1)
  t:onFire(function() end)

  -- Simulate several intervals passing.
  for i = 1, 5 do t:update(0.1) end
  print("total fires=" .. t:getFireCount())
end

--@api-stub: LThrottle:setEnabled
-- Enable or disable the throttle (disabled throttle does not accumulate time)
do
  local t = lurek.patterns.newThrottle(0.5)
  t:onFire(function() print("  fire") end)

  -- Disable during pause menu or cutscenes.
  t:setEnabled(false)
  t:update(1.0)  -- no fire because disabled
  print("fires while disabled=" .. t:getFireCount())
end

--@api-stub: LDebounce:onFire
-- Set the callback to invoke when the debounce fires after the wait period
do
  local d = lurek.patterns.newDebounce(0.3)

  -- The callback fires once after 0.3s of no new triggers.
  d:onFire(function()
    print("  input settled, executing action")
  end)
  d:trigger()
  -- In a real game: function lurek.process(dt) d:update(dt) end
end

--@api-stub: LDebounce:trigger
-- Signal input activity, resetting the wait timer
do
  local d = lurek.patterns.newDebounce(0.5)
  d:onFire(function() print("  autosave triggered") end)

  -- Each trigger() resets the countdown. Only fires after 0.5s of silence.
  d:trigger()  -- timer starts
  d:trigger()  -- timer resets back to 0
  print("pending=" .. tostring(d:isPending()))
end

--@api-stub: LFunnel:update
-- Advance the debounce timer; returns true if it fired this frame
do
  local d = lurek.patterns.newDebounce(0.4)
  d:onFire(function() print("  typing paused, run search") end)
  d:trigger()

  -- Returns true on the frame the debounce fires.
  local fired = d:update(0.5)  -- 0.5 > 0.4 wait, so it fires
  print("fired=" .. tostring(fired))
end

--@api-stub: LDebounce:cancel
-- Cancel any pending debounce without firing
do
  local d = lurek.patterns.newDebounce(1.0)
  d:onFire(function() print("  commit changes") end)
  d:trigger()

  -- Cancel if the user explicitly discards their edits.
  d:cancel()
  print("pending after cancel=" .. tostring(d:isPending()))
end

--@api-stub: LDebounce:isPending
-- Check whether the debounce is waiting to fire
do
  local d = lurek.patterns.newDebounce(0.6)
  d:onFire(function() end)
  d:trigger()

  -- Use to show a "saving..." indicator in the UI.
  if d:isPending() then print("waiting for idle before save...") end
end

--@api-stub: LDebounce:getFireCount
-- Return the total number of times this debounce has fired since creation
do
  local d = lurek.patterns.newDebounce(0.1)
  d:onFire(function() end)
  d:trigger()
  d:update(0.2)  -- fires

  print("total fires=" .. d:getFireCount())
end

--@api-stub: LList:push
-- Add an item with a numeric priority (higher = dequeued sooner)
do
  local pq = lurek.patterns.newPriorityQueue("ai")

  -- Third argument is an optional label for debugging.
  pq:push(10, { kind = "patrol" }, "low_priority")
  pq:push(50, { kind = "attack" }, "urgent")
  pq:push(20, { kind = "investigate" }, "medium")
  print("queued=" .. pq:len())
end

--@api-stub: LList:pop
-- Remove and return the highest-priority item
do
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "low_task"); pq:push(99, "critical_task")

  -- Always returns the highest priority item first.
  local job = pq:pop()
  if job then print("executing: " .. job) end  -- "critical_task"
end

--@api-stub: LStack:peek
-- Return the highest-priority item without removing it
do
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(5, "build_wall"); pq:push(20, "render_frame")

  -- Peek to check what's next without consuming it.
  local next_job = pq:peek()
  if next_job then print("next up: " .. next_job) end
end

--@api-stub: LWeightedRandom:len
-- Return the current number of items in the queue
do
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "a"); pq:push(2, "b"); pq:push(3, "c")

  -- Use len() to check load and shed low-priority work if overwhelmed.
  if pq:len() > 100 then print("queue saturated, shedding tasks") end
  print("queue size=" .. pq:len())
end

--@api-stub: LWeightedRandom:isEmpty
-- Check whether the queue contains no items
do
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "process_input")

  -- Drain loop: process all tasks in priority order.
  while not pq:isEmpty() do
    print("  processing: " .. pq:pop())
  end
end

--@api-stub: LPatternGraph:clearAll
-- Remove all items from the priority queue
do
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "x"); pq:push(2, "y")

  -- Clear when switching AI contexts or resetting the scheduler.
  pq:clearAll()
  print("after clear: len=" .. pq:len())
end

--@api-stub: LList:push
-- Push a value into the ring (overwrites oldest when full)
do
  local r = lurek.patterns.newRing(8)

  -- Push more than capacity: oldest values are silently dropped.
  for i = 1, 10 do r:push(i * 1.5, "latency") end
  print("len=" .. r:len() .. " full=" .. tostring(r:isFull()))
end

--@api-stub: LRing:latest
-- Return the most recently pushed entry as a table
do
  local r = lurek.patterns.newRing(4)
  r:push("player joined", "event")
  r:push("enemy spawned", "event")

  -- latest() returns {id, tag, value, text} of the newest entry.
  local last = r:latest()
  if last then print("last event: " .. last.text) end
end

--@api-stub: LSet:toArray
-- Return all entries as an ordered array (oldest to newest)
do
  local r = lurek.patterns.newRing(4)
  r:push(60, "fps"); r:push(58, "fps"); r:push(61, "fps")

  -- Iterate for debug display or graph rendering.
  for _, entry in ipairs(r:toArray()) do
    print("  " .. entry.tag .. "=" .. entry.value)
  end
end

--@api-stub: LRing:sum
-- Return the sum of all numeric values in the ring
do
  local r = lurek.patterns.newRing(16)
  for i = 1, 10 do r:push(i * 0.1, "latency") end

  -- sum() for total accumulated latency over the window.
  print("total latency=" .. string.format("%.2f", r:sum()) .. "s")
end

--@api-stub: LRing:average
-- Return the arithmetic mean of all numeric values in the ring
do
  local r = lurek.patterns.newRing(60)
  for i = 1, 60 do r:push(58 + (i % 4), "fps") end

  -- Rolling average for smooth FPS display.
  print("avg fps=" .. string.format("%.1f", r:average()))
end

--@api-stub: LWeightedRandom:len
-- Return the number of entries currently in the ring
do
  local r = lurek.patterns.newRing(10)
  r:push(1, "x"); r:push(2, "x"); r:push(3, "x")

  -- Check if we have enough samples for a meaningful average.
  if r:len() >= 3 then print("enough samples for analysis") end
end

--@api-stub: LQueue:isFull
-- Check whether the ring has reached its maximum capacity
do
  local r = lurek.patterns.newRing(4)
  for i = 1, 4 do r:push(i, "warmup") end

  -- Only report average once the ring is fully warmed up.
  if r:isFull() then print("warm: avg=" .. string.format("%.1f", r:average())) end
end

--@api-stub: LMap:clear
-- Remove all entries from the ring
do
  local r = lurek.patterns.newRing(8)
  r:push(10, "x"); r:push(20, "x")

  -- Clear when switching measurement contexts.
  r:clear()
  print("len after clear=" .. r:len())
end

--@api-stub: LFunnel:onFlush
-- Set the callback invoked when the funnel flushes its batch
do
  local f = lurek.patterns.newFunnel(1.0, 0)

  -- Callback receives an array of {tag, value} entries.
  f:onFlush(function(batch)
    print("  flushed " .. #batch .. " events to server")
  end)
  -- In a real game: function lurek.process(dt) f:update(dt) end
end

--@api-stub: LList:push
-- Push a tagged event into the funnel (may trigger immediate flush if at max entries)
do
  local f = lurek.patterns.newFunnel(60.0, 4)  -- max 4 entries before forced flush
  f:onFlush(function(b) print("  batch size=" .. #b) end)

  -- When maxEntries is reached, flush fires immediately.
  f:push("kill", 1); f:push("kill", 1); f:push("kill", 1); f:push("kill", 1)
  print("pending after max-flush=" .. f:pendingCount())
end

--@api-stub: LFunnel:update
-- Advance the funnel's time window; returns true if it flushed this frame
do
  local f = lurek.patterns.newFunnel(0.5, 0)
  f:onFlush(function(b) print("  auto flush " .. #b .. " events") end)
  f:push("hit", 5)

  -- Returns true when the time window elapses and batch is flushed.
  local flushed = f:update(0.6)
  print("flushed=" .. tostring(flushed))
end

--@api-stub: LFunnel:flush
-- Force an immediate flush of all pending entries
do
  local f = lurek.patterns.newFunnel(60.0, 0)
  f:onFlush(function(b) print("  emergency flush: " .. #b .. " events") end)
  f:push("crash_report", 1)

  -- Force flush on critical events that cannot wait for the time window.
  f:flush()
end

--@api-stub: LFunnel:discard
-- Discard all pending entries without flushing or calling the callback
do
  local f = lurek.patterns.newFunnel(2.0, 0)
  f:onFlush(function() end)
  f:push("stale_event", 1); f:push("stale_event", 2)

  -- Discard when the batch is no longer relevant (e.g. player disconnected).
  f:discard()
  print("pending after discard=" .. f:pendingCount())
end

--@api-stub: LFunnel:pendingCount
-- Return the number of entries waiting to be flushed
do
  local f = lurek.patterns.newFunnel(5.0, 0)
  f:onFlush(function() end)
  f:push("x", 1); f:push("y", 2); f:push("z", 3)

  -- Monitor buffer fill level.
  print("buffered events=" .. f:pendingCount())
end

--@api-stub: LFunnel:getFlushCount
-- Return the total number of times this funnel has flushed since creation
do
  local f = lurek.patterns.newFunnel(0, 1)  -- flush every 1 entry
  f:onFlush(function() end)
  for i = 1, 3 do f:push("evt", i) end

  -- Track how many batches were sent for monitoring.
  print("total flushes=" .. f:getFlushCount())
end

--@api-stub: LRelationshipManager:defineType
-- Define a relationship type with named levels in order
do
  local rm = lurek.patterns.newRelationshipManager()

  -- Levels are ordered: index determines thresholds.
  rm:defineType("faction", { "hostile", "neutral", "ally" }, "neutral")
  rm:defineType("trust", { "low", "medium", "high" }, "low")
  print("defined types=" .. #rm:typeNames())
end

--@api-stub: LRelationshipManager:removeType
-- Remove a relationship type definition
do
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("temp_rel", { "a", "b" }, "a")

  -- Remove types that are no longer used by the current game mode.
  rm:removeType("temp_rel")
  print("types remaining=" .. #rm:typeNames())
end

--@api-stub: LRelationshipManager:typeNames
-- Return all defined relationship type names
do
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("diplomacy", { "war", "peace" }, "peace")
  rm:defineType("trade", { "embargo", "open" }, "open")

  for _, t in ipairs(rm:typeNames()) do print("  type: " .. t) end
end

--@api-stub: LRelationshipManager:setValue
-- Set the numeric relationship value between two entity IDs
do
  local rm = lurek.patterns.newRelationshipManager()

  -- Numeric values track continuous affinity (reputation, friendship score).
  rm:setValue(101, 202, 35)
  print("value=" .. rm:getValue(101, 202) .. " pairs=" .. rm:pairCount())
end

--@api-stub: LRelationshipManager:getValue
-- Get the numeric relationship value between two entity IDs (0 if not set)
do
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(1, 2, 50)

  -- Use value for shop price modifiers: higher affinity = better prices.
  local affinity = rm:getValue(1, 2)
  local discount = affinity * 0.005
  print("shop discount=" .. (discount * 100) .. "%")
end

--@api-stub: LRelationshipManager:adjustValue
-- Add a delta to the relationship value between two entities
do
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(1, 2, 0)

  -- Incremental changes from game events.
  rm:adjustValue(1, 2, 25)   -- gift accepted: +25
  rm:adjustValue(1, 2, -10)  -- minor offence: -10
  print("net affinity=" .. rm:getValue(1, 2))  -- 15
end

--@api-stub: LRelationshipManager:setLevel
-- Set the named level for a relationship type between two entities
do
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("faction", { "hostile", "neutral", "ally" }, "neutral")

  -- Discrete level assignment (e.g. after a quest changes faction standing).
  local ok = rm:setLevel(1, 2, "faction", "ally")
  print("set ally=" .. tostring(ok))
end

--@api-stub: LRelationshipManager:getLevel
-- Get the named level for a relationship type between two entities
do
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("faction", { "hostile", "ally" }, "hostile")
  rm:setLevel(1, 2, "faction", "ally")

  -- Use level for game logic decisions.
  local lvl = rm:getLevel(1, 2, "faction")
  if lvl == "ally" then print("hold fire - they are allies") end
end

--@api-stub: LRelationshipManager:removePair
-- Remove all relationship data between two entities
do
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(1, 2, 50)

  -- Remove when an entity is destroyed or relationship is forgotten.
  rm:removePair(1, 2)
  print("pairs after removal=" .. rm:pairCount())
end

--@api-stub: LRelationshipManager:pairCount
-- Return the total number of tracked entity pairs
do
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(1, 2, 10); rm:setValue(2, 3, -10)

  -- Monitor relationship graph size for performance budgeting.
  if rm:pairCount() > 10000 then print("WARN: large relationship graph") end
  print("tracked pairs=" .. rm:pairCount())
end

--@api-stub: LMediator:on
-- Register a handler callback on a named channel
do
  local m = lurek.patterns.newMediator()

  -- Returns a handler ID for later removal.
  local id = m:on("network", function(msg)
    print("  net received: " .. msg)
  end)
  m:send("network", "player_joined")
  m:off("network", id)
end

--@api-stub: LMediator:off
-- Unregister a handler from a channel by its ID
do
  local m = lurek.patterns.newMediator()
  local id = m:on("ui_events", function() print("  ui tick") end)

  -- Remove handler when the UI screen is closed.
  m:off("ui_events", id)
  print("handlers on ui_events=" .. m:handlerCount("ui_events"))
end

--@api-stub: LMediator:send
-- Send a message to all handlers on a specific channel
do
  local m = lurek.patterns.newMediator()
  m:on("damage_log", function(amount, source)
    print("  " .. source .. " dealt " .. amount .. " damage")
  end)

  -- All handlers on "damage_log" receive the same arguments.
  m:send("damage_log", 12, "spike_trap")
end

--@api-stub: LMediator:broadcast
-- Send a message to all handlers on ALL channels
do
  local m = lurek.patterns.newMediator()
  m:on("audio", function(cmd) print("  audio: " .. cmd) end)
  m:on("video", function(cmd) print("  video: " .. cmd) end)

  -- Broadcast reaches every handler on every channel.
  -- Use for global commands like "pause" or "shutdown".
  m:broadcast("pause")
end

--@api-stub: LMediator:handlerCount
-- Return the number of handlers on a specific channel
do
  local m = lurek.patterns.newMediator()
  m:on("save", function() end)
  m:on("save", function() end)

  -- Debug: verify expected handler count.
  print("save handlers=" .. m:handlerCount("save"))
end

--@api-stub: LMediator:channels
-- Return an array of all channel names with at least one handler
do
  local m = lurek.patterns.newMediator()
  m:on("input", function() end); m:on("physics", function() end)

  -- List active channels for debug overlay.
  for _, ch in ipairs(m:channels()) do print("  channel: " .. ch) end
end

--@api-stub: LMediator:removeChannel
-- Remove an entire channel and all its handlers
do
  local m = lurek.patterns.newMediator()
  m:on("minigame", function() end)

  -- Remove the whole channel when that system shuts down.
  m:removeChannel("minigame")
  print("minigame handlers=" .. m:handlerCount("minigame"))
end

--@api-stub: LMap:clear
-- Remove all channels and handlers, resetting the mediator
do
  local m = lurek.patterns.newMediator()
  m:on("x", function() end); m:on("y", function() end)

  -- Full reset between game sessions.
  m:clear()
  print("channels after clear=" .. #m:channels())
end

--@api-stub: LStrategy:register
-- Register a named strategy implementation function
do
  local s = lurek.patterns.newStrategy()

  -- Register multiple algorithms for the same task.
  s:register("euclidean", function(ax, ay, bx, by)
    return math.sqrt((ax-bx)^2 + (ay-by)^2)
  end)
  s:register("manhattan", function(ax, ay, bx, by)
    return math.abs(ax-bx) + math.abs(ay-by)
  end)
  print("registered strategies=" .. #s:names())
end

--@api-stub: LMap:set
-- Switch to a named strategy for future execute() calls
do
  local s = lurek.patterns.newStrategy()
  s:register("fast", function(x) return x * 2 end)

  -- set() returns false if the strategy name does not exist.
  local ok = s:set("fast")
  if not ok then print("ERROR: strategy not found") end
end

--@api-stub: LStrategy:execute
-- Execute the currently active strategy, forwarding arguments
do
  local s = lurek.patterns.newStrategy()
  s:register("crit", function(atk, def) return atk * 2 - def end)
  s:set("crit")

  -- Arguments and return values pass through to the active implementation.
  local dmg = s:execute(20, 5)
  print("critical damage=" .. dmg)
end

--@api-stub: LStrategy:getCurrent
-- Return the name of the currently active strategy (nil if none)
do
  local s = lurek.patterns.newStrategy()
  s:register("normal", function(x) return x end)
  s:set("normal")

  -- Use to display current mode in UI.
  local name = s:getCurrent()
  if name then print("active strategy: " .. name) end
end

--@api-stub: LMap:has
-- Check whether a strategy with the given name is registered
do
  local s = lurek.patterns.newStrategy()
  s:register("legacy", function() return 0 end)

  -- Guard before set() to handle missing strategies gracefully.
  if s:has("legacy") then s:set("legacy") end
end

--@api-stub: LWeightedRandom:remove
-- Remove a named strategy (clears selection if it was active)
do
  local s = lurek.patterns.newStrategy()
  s:register("deprecated", function() end)

  local removed = s:remove("deprecated")
  print("removed=" .. tostring(removed))
end

--@api-stub: LStrategy:names
-- Return an array of all registered strategy names
do
  local s = lurek.patterns.newStrategy()
  s:register("alpha", function() end); s:register("beta", function() end)

  for _, n in ipairs(s:names()) do print("  strategy: " .. n) end
end

--@api-stub: LMap:clear
-- Remove all strategies and reset the selection
do
  local s = lurek.patterns.newStrategy()
  s:register("x", function() end)

  -- Reset when loading new configuration.
  s:clear()
  print("strategies after clear=" .. #s:names())
end

--@api-stub: LList:push
-- Push a value onto the top of the stack (returns false if at capacity)
do
  local s = lurek.patterns.newStack(4)

  s:push("scene_main")
  s:push("scene_options")
  local ok = s:push("scene_keybinds")
  -- ok is false if capacity is reached.
  print("pushed=" .. tostring(ok) .. " depth=" .. s:len())
end

--@api-stub: LList:pop
-- Remove and return the top value (nil if empty)
do
  local s = lurek.patterns.newStack(0)
  s:push("menu"); s:push("gameplay")

  -- Pop returns to the previous "screen" in the navigation stack.
  local top = s:pop()
  print("popped=" .. top .. " now at=" .. (s:peek() or "<empty>"))
end

--@api-stub: LStack:peek
-- Return the top value without removing it
do
  local s = lurek.patterns.newStack(0)
  s:push("hud_layer"); s:push("dialog_layer")

  -- Peek to check current state without modifying.
  local top = s:peek()
  if top == "dialog_layer" then print("dialog is showing") end
end

--@api-stub: LWeightedRandom:len
-- Return the current number of items in the stack
do
  local s = lurek.patterns.newStack(0)
  s:push("a"); s:push("b"); s:push("c")
  print("stack depth=" .. s:len())
end

--@api-stub: LWeightedRandom:isEmpty
-- Check whether the stack contains no items
do
  local s = lurek.patterns.newStack(0)
  s:push("only_item")
  s:pop()

  -- Empty stack = user navigated all the way back.
  if s:isEmpty() then print("at root, quit to main menu") end
end

--@api-stub: LQueue:isFull
-- Check whether the stack has reached its capacity limit
do
  local s = lurek.patterns.newStack(2)
  s:push("a"); s:push("b")

  -- Prevent pushing more dialogs when at max depth.
  if s:isFull() then print("dialog stack full, close one first") end
end

--@api-stub: LMap:clear
-- Remove all items from the stack
do
  local s = lurek.patterns.newStack(0)
  s:push("a"); s:push("b")

  -- Clear on major state transition (e.g. returning to title screen).
  s:clear()
  print("len after clear=" .. s:len())
end

--@api-stub: LSet:toArray
-- Return all items as an array table (bottom to top)
do
  local s = lurek.patterns.newStack(0)
  s:push("Main"); s:push("Settings"); s:push("Audio")

  -- Useful for breadcrumb display: Main > Settings > Audio
  for i, v in ipairs(s:toArray()) do print("  " .. i .. ": " .. v) end
end

--@api-stub: LQueue:enqueue
-- Add a value to the back of the queue (returns false if at capacity)
do
  local q = lurek.patterns.newQueue(0)

  q:enqueue("packet_a"); q:enqueue("packet_b")
  local ok = q:enqueue("packet_c")
  print("enqueued=" .. tostring(ok) .. " size=" .. q:len())
end

--@api-stub: LQueue:dequeue
-- Remove and return the front value (nil if empty)
do
  local q = lurek.patterns.newQueue(0)
  q:enqueue("first_msg"); q:enqueue("second_msg")

  -- FIFO: dequeue returns the oldest message first.
  local msg = q:dequeue()
  if msg then print("processing: " .. msg) end
end

--@api-stub: LQueue:front
-- Return the front value without removing it
do
  local q = lurek.patterns.newQueue(0)
  q:enqueue("urgent"); q:enqueue("normal")

  -- Peek at what's next without consuming it.
  local f = q:front()
  if f then print("next in queue: " .. f) end
end

--@api-stub: LWeightedRandom:len
-- Return the current number of items in the queue
do
  local q = lurek.patterns.newQueue(0)
  for i = 1, 4 do q:enqueue("event_" .. i) end
  print("queue size=" .. q:len())
end

--@api-stub: LWeightedRandom:isEmpty
-- Check whether the queue contains no items
do
  local q = lurek.patterns.newQueue(0)
  q:enqueue("task")

  -- Drain loop pattern.
  while not q:isEmpty() do
    print("  handled: " .. q:dequeue())
  end
end

--@api-stub: LQueue:isFull
-- Check whether the queue has reached its capacity limit
do
  local q = lurek.patterns.newQueue(2)
  q:enqueue("a"); q:enqueue("b")

  -- Drop new inputs when the queue is saturated.
  if q:isFull() then print("queue full, dropping input") end
end

--@api-stub: LMap:clear
-- Remove all items from the queue
do
  local q = lurek.patterns.newQueue(0)
  q:enqueue("x"); q:enqueue("y")

  -- Clear pending commands when aborting an action sequence.
  q:clear()
  print("size after clear=" .. q:len())
end

--@api-stub: LSet:toArray
-- Return all items as an array table (front to back)
do
  local q = lurek.patterns.newQueue(0)
  q:enqueue("alpha"); q:enqueue("beta"); q:enqueue("gamma")

  for i, v in ipairs(q:toArray()) do print("  " .. i .. ": " .. v) end
end

--@api-stub: LWeightedRandom:add
-- Append a value to the end of the list
do
  local l = lurek.patterns.newList()

  -- Build an inventory by adding items as they are collected.
  l:add("sword"); l:add("shield"); l:add("potion")
  print("inventory size=" .. l:len())
end

--@api-stub: LMap:get
-- Get the value at a 1-based index (nil if out of range)
do
  local l = lurek.patterns.newList()
  l:add("apple"); l:add("bread")

  -- 1-based indexing matches Lua convention.
  local item = l:get(1)
  if item then print("first item: " .. item) end
end

--@api-stub: LMap:set
-- Replace the value at a 1-based index
do
  local l = lurek.patterns.newList()
  l:add("placeholder")

  -- Overwrite at a specific slot (e.g. equipment slot swap).
  l:set(1, "enchanted_sword")
  print("slot 1: " .. l:get(1))
end

--@api-stub: LWeightedRandom:remove
-- Remove and return the value at a 1-based index
do
  local l = lurek.patterns.newList()
  l:add("quest_a"); l:add("quest_b"); l:add("quest_c")

  -- Remove shifts subsequent items left (like removing from an array).
  local removed = l:remove(2)
  print("removed=" .. removed .. " remaining=" .. l:len())
end

--@api-stub: LWeightedRandom:len
-- Return the number of items in the list
do
  local l = lurek.patterns.newList()
  for i = 1, 5 do l:add("item_" .. i) end
  print("count=" .. l:len())
end

--@api-stub: LWeightedRandom:isEmpty
-- Check whether the list is empty
do
  local l = lurek.patterns.newList()
  if l:isEmpty() then print("inventory is empty") end
  l:add("ring")
  print("after add: empty=" .. tostring(l:isEmpty()))
end

--@api-stub: LList:contains
-- Check whether the list contains a specific value
do
  local l = lurek.patterns.newList()
  l:add("key"); l:add("map"); l:add("torch")

  -- Fast membership check for quest prerequisites.
  if l:contains("key") then print("door can be opened") end
end

--@api-stub: LMap:clear
-- Remove all items from the list
do
  local l = lurek.patterns.newList()
  l:add("x"); l:add("y")

  -- Clear when the player drops all items.
  l:clear()
  print("len after clear=" .. l:len())
end

--@api-stub: LSet:toArray
-- Return all items as a plain Lua array table
do
  local l = lurek.patterns.newList()
  l:add("fire"); l:add("ice"); l:add("lightning")

  -- Convert to plain table for iteration or serialization.
  for i, v in ipairs(l:toArray()) do print("  " .. i .. "=" .. v) end
end

--@api-stub: LWeightedRandom:add
-- Add a string to the set (returns true if newly added)
do
  local s = lurek.patterns.newSet()

  -- Returns true only on the first add (detects duplicates).
  local was_new = s:add("collected_gem")
  if was_new then print("first gem collected!") end
  s:add("collected_gem")  -- returns false, already present
end

--@api-stub: LWeightedRandom:remove
-- Remove a string from the set (returns true if it was present)
do
  local s = lurek.patterns.newSet()
  s:add("buff_speed")

  -- Remove when an effect expires.
  local existed = s:remove("buff_speed")
  print("removed=" .. tostring(existed) .. " size=" .. s:len())
end

--@api-stub: LMap:has
-- Check whether a string is in the set
do
  local s = lurek.patterns.newSet()
  s:add("flying")

  -- O(1) membership check for status effects.
  if s:has("flying") then print("ignore gravity") end
end

--@api-stub: LWeightedRandom:len
-- Return the number of items in the set
do
  local s = lurek.patterns.newSet()
  s:add("orc"); s:add("goblin"); s:add("orc")  -- duplicate ignored

  -- Unique count only.
  print("unique enemies killed=" .. s:len())
end

--@api-stub: LWeightedRandom:isEmpty
-- Check whether the set is empty
do
  local s = lurek.patterns.newSet()
  if s:isEmpty() then print("no keys collected yet") end
  s:add("brass_key")
  print("empty=" .. tostring(s:isEmpty()))
end

--@api-stub: LSet:toArray
-- Return all items as an array table
do
  local s = lurek.patterns.newSet()
  s:add("red"); s:add("green"); s:add("blue")

  -- Convert for serialization or display.
  for _, k in ipairs(s:toArray()) do print("  color: " .. k) end
end

--@api-stub: LMap:clear
-- Remove all items from the set
do
  local s = lurek.patterns.newSet()
  s:add("seen_intro"); s:add("opened_chest")

  -- Clear when starting a new game.
  s:clear()
  print("size after clear=" .. s:len())
end

--@api-stub: LSet:union
-- Return a new set containing all items from both sets
do
  local a = lurek.patterns.newSet(); a:add("sword"); a:add("shield")
  local b = lurek.patterns.newSet(); b:add("shield"); b:add("bow")

  -- Union combines both inventories (duplicates are collapsed).
  local combined = a:union(b)
  print("union size=" .. combined:len())  -- 3: sword, shield, bow
end

--@api-stub: LSet:intersection
-- Return a new set containing only items present in both sets
do
  local player_has = lurek.patterns.newSet(); player_has:add("key"); player_has:add("map")
  local door_needs = lurek.patterns.newSet(); door_needs:add("map"); door_needs:add("torch")

  -- Intersection shows which requirements the player already meets.
  local matched = player_has:intersection(door_needs)
  print("requirements met=" .. matched:len())  -- 1: map
end

-- -----------------------------------------------------------------------------
-- Extended LList methods (push, unshift, insert, indexOf, reverse, pop, shift)
-- -----------------------------------------------------------------------------

--@api-stub: LWeightedRandom:add
-- Append a value to the end of the list
do
  local lst = lurek.patterns.newList()
  -- add() is the primary way to grow the list.
  lst:add("sword")
  lst:add("shield")
  lst:add("potion")
  print("list size=" .. lst:len())
end

--@api-stub: LMap:get
-- Get the value at a 1-based index
do
  local lst = lurek.patterns.newList()
  lst:add("apple")
  lst:add("banana")
  -- 1-based: index 2 is the second element.
  local item = lst:get(2)
  print("item[2]=" .. tostring(item))
end

--@api-stub: LMap:set
-- Replace the value at a 1-based index
do
  local lst = lurek.patterns.newList()
  lst:add("iron_sword")
  lst:add("leather_boots")
  -- Overwrite slot 1 with an upgraded item.
  lst:set(1, "mythril_sword")
  print("slot 1=" .. tostring(lst:get(1)))
end

--@api-stub: LWeightedRandom:remove
-- Remove and return the value at a 1-based index
do
  local lst = lurek.patterns.newList()
  lst:add("quest_a")
  lst:add("quest_b")
  lst:add("quest_c")
  -- Removes quest_b, shifts quest_c down to index 2.
  local removed = lst:remove(2)
  print("removed=" .. tostring(removed) .. " remaining=" .. lst:len())
end

--@api-stub: LWeightedRandom:len
-- Return the number of items in the list
do
  local lst = lurek.patterns.newList()
  for i = 1, 5 do lst:add(i * 10) end
  print("list length=" .. lst:len())
end

--@api-stub: LWeightedRandom:isEmpty
-- Check whether the list is empty
do
  local lst = lurek.patterns.newList()
  print("before add: empty=" .. tostring(lst:isEmpty()))
  lst:add("item")
  print("after add: empty=" .. tostring(lst:isEmpty()))
end

--@api-stub: LList:contains
-- Check whether the list contains a specific value
do
  local lst = lurek.patterns.newList()
  lst:add("fire")
  lst:add("ice")
  lst:add("thunder")
  -- Linear search for the value.
  print("has fire: " .. tostring(lst:contains("fire")))
  print("has wind: " .. tostring(lst:contains("wind")))
end

--@api-stub: LMap:clear
-- Remove all items from the list
do
  local lst = lurek.patterns.newList()
  lst:add("a")
  lst:add("b")
  lst:clear()
  print("length after clear=" .. lst:len())
end

--@api-stub: LSet:toArray
-- Return all items as an array table
do
  local lst = lurek.patterns.newList()
  lst:add('10')
  lst:add('20')
  lst:add('30')
  -- toArray() returns a plain Lua table for iteration.
  local arr = lst:toArray()
  print("arr[2]=" .. tostring(arr[2]))
end

--@api-stub: new
-- Create new pattern instances (WeightedRandom, BehaviorTree, Graph)
do
  -- All newXxx() constructors return ready-to-use pattern objects.
  local wr = lurek.patterns.newWeightedRandom()
  local bt = lurek.patterns.newBehaviorTree()
  local g = lurek.patterns.newGraph()
  if wr and bt and g then
    print("all pattern factories operational")
  end
end

--@api-stub: LWeightedRandom
-- Weighted random selection pool for loot tables, spawn variety, and procedural generation
do
  local wr = lurek.patterns.newWeightedRandom()

  -- Weight determines relative probability. 9.0 "common" vs 1.0 "rare"
  -- means ~90% chance of common, ~10% rare.
  local id_common = wr:add(9.0, "common_drop", "common")
  local id_rare = wr:add(1.0, "rare_drop", "rare")

  -- Adjust weights dynamically (e.g. pity system increasing rare chance).
  wr:setWeight(id_rare, 2.0)

  -- pick() takes a random sample in [0, 1). Use math.random() in production.
  local result = wr:pick(0.85)
  print("picked: " .. tostring(result))

  -- pickN() selects multiple unique items.
  local batch = wr:pickN(2, { 0.1, 0.9 })
  print("batch size=" .. #batch .. " total_weight=" .. wr:totalWeight())

  -- Track changes with revision counter.
  local rev = wr:getRevision()
  wr:remove(id_common)
  print("revision changed: " .. tostring(wr:getRevision() ~= rev))
  wr:clearAll()
end

--@api-stub: LBehaviorTree
-- Behavior tree for AI decision-making with sequences, selectors, parallels, and leaf actions
do
  local bt = lurek.patterns.newBehaviorTree()

  -- Build tree structure: root sequence runs children in order.
  local root_seq = bt:addSequence("root")
  -- Selector tries children until one succeeds (fallback logic).
  local fallback = bt:addSelector("try_actions")
  -- Parallel runs children simultaneously, succeeds if minSuccess children pass.
  local parallel = bt:addParallel(1, "concurrent")
  -- Inverter flips child result: success becomes failure and vice versa.
  local inverter = bt:addInverter("negate")
  -- Repeater runs its child N times.
  local repeater = bt:addRepeat(2, "do_twice")
  -- Leaves are the actual actions that return "success", "failure", or "running".
  local leaf_patrol = bt:addLeaf("patrol", "patrol_action")
  local leaf_attack = bt:addLeaf("attack", "attack_action")

  -- Wire up the tree hierarchy.
  bt:addChild(root_seq, fallback)
  bt:addChild(fallback, parallel)
  bt:addChild(parallel, inverter)
  bt:addChild(inverter, repeater)
  bt:addChild(repeater, leaf_patrol)
  bt:addChild(fallback, leaf_attack)

  -- Register leaf implementations. These run the actual game logic.
  bt:setLeaf("patrol", function() return "success" end)
  bt:setLeaf("attack", function() return "failure" end)

  -- Set root and tick once per AI update.
  bt:setRoot(root_seq)
  local status = bt:tick()
  print("AI decision: " .. status .. " (nodes=" .. bt:nodeCount() .. ")")

  -- Reset running state between encounters.
  bt:resetState()
  bt:clearAll()
end

--@api-stub: LPatternGraph:addNode
--@api-stub: LPatternGraph:removeNode
--@api-stub: LPatternGraph:getNodeValue
--@api-stub: LPatternGraph:addEdge
--@api-stub: LPatternGraph:removeEdge
--@api-stub: LPatternGraph:neighbors
--@api-stub: LPatternGraph:bfs
--@api-stub: LPatternGraph:dfs
--@api-stub: LPatternGraph:isConnected
--@api-stub: LPatternGraph:hasNode
--@api-stub: LPatternGraph:nodeCount
--@api-stub: LPatternGraph:edgeCount
--@api-stub: LPatternGraph:clearAll
-- Graph data structure with directed/undirected edges, BFS, DFS, and connectivity queries
do
  -- Create undirected graph (edges go both ways).
  ---@type LPatternGraph
  local g = lurek.patterns.newGraph(true)

  -- Add nodes with optional labels and payload data.
  local town_a = g:addNode("Riverdale", { population = 500 })
  local town_b = g:addNode("Hillcrest", { population = 300 })
  local town_c = g:addNode("Lakewood", { population = 800 })

  -- Connect nodes with weighted edges (distance between towns).
  local road1 = g:addEdge(town_a, town_b, 15.0, "dirt_road")
  g:addEdge(town_b, town_c, 22.0, "paved_road")

  -- Query node data.
  local data = g:getNodeValue(town_a)
  print("Riverdale pop=" .. (data and data.population or 0))

  -- Membership check.
  local exists = g:hasNode(town_a)
  print("town_a exists=" .. tostring(exists))

  -- Pathfinding queries.
  local neighbors = g:neighbors(town_a)
  local bfs_order = g:bfs(town_a)
  local dfs_order = g:dfs(town_a)
  local connected = g:isConnected(town_a, town_c)

  print("neighbors=" .. #neighbors
    .. " bfs=" .. #bfs_order
    .. " dfs=" .. #dfs_order
    .. " a-c connected=" .. tostring(connected))

  -- Modify graph: remove a road and a town.
  g:removeEdge(road1)
  g:removeNode(town_c)
  print("nodes=" .. g:nodeCount() .. " edges=" .. g:edgeCount())
  g:clearAll()
end

--@api-stub: lurek.patterns.newMap
-- Create a new string-keyed dictionary (map) with keys/values/entries access and merge support
do
  -- Map provides a proper dictionary with iteration support, merge operations,
  -- and entries/keys/values accessors. Use when you need more than a plain table.
  local config = lurek.patterns.newMap()
  config:set("volume", 0.8)
  config:set("fullscreen", true)
  print("map has volume=" .. tostring(config:has("volume")))
end

--@api-stub: LStack
-- Extended Stack operations: pushBottom, peekBottom, insertAt, moveWithin, removeAt, popMany, popBottom
do
  local s = lurek.patterns.newStack(10)

  -- pushBottom inserts at the base of the stack.
  s:push("middle")
  s:pushBottom("bottom")

  -- insertAt places at a specific 1-based index.
  s:insertAt(3, "top")

  -- Peek at different positions without modifying.
  local bottom = s:peekBottom()
  local at2 = s:peekAt(2)

  -- moveWithin reorders items without remove+push.
  s:moveWithin(3, 2)

  -- removeAt extracts from a specific position.
  local removed = s:removeAt(2)

  -- popMany gets multiple items at once.
  local batch = s:popMany(1)

  -- popBottom removes from the base.
  local from_bottom = s:popBottom()

  print("bottom=" .. tostring(bottom)
    .. " at2=" .. tostring(at2)
    .. " removed=" .. tostring(removed)
    .. " batch=" .. #batch
    .. " popBottom=" .. tostring(from_bottom))
end

--@api-stub: LQueue
-- Extended Queue operations: enqueueFront, dequeueBack, insertAt, peekAt, removeAt, back
do
  local q = lurek.patterns.newQueue(10)

  -- enqueueFront inserts at the front (priority insertion).
  q:enqueue("normal")
  q:enqueueFront("urgent")
  q:enqueue("low")

  -- insertAt places at a specific position.
  q:insertAt(3, "medium")

  -- Peek at back and specific positions.
  local back = q:back()
  local at2 = q:peekAt(2)

  -- removeAt extracts from a specific position.
  local removed = q:removeAt(3)

  -- dequeueBack removes from the back (opposite of dequeue).
  local from_back = q:dequeueBack()

  print("back=" .. tostring(back)
    .. " peekAt2=" .. tostring(at2)
    .. " removeAt3=" .. tostring(removed)
    .. " dequeueBack=" .. tostring(from_back))
end

--@api-stub: LList
-- Extended List operations: push, unshift, insert, indexOf, reverse, pop, shift
do
  local l = lurek.patterns.newList()

  -- push is an alias for add (append to end).
  l:push("beta")
  -- unshift prepends to the beginning.
  l:unshift("alpha")
  -- insert at a specific 1-based index.
  l:insert(3, "gamma")

  -- indexOf returns the 1-based position of a value.
  local idx = l:indexOf("beta")

  -- reverse the entire list in-place.
  l:reverse()

  -- pop removes from the end, shift removes from the beginning.
  local popped = l:pop()
  local shifted = l:shift()

  print("indexOf(beta)=" .. tostring(idx)
    .. " pop=" .. tostring(popped)
    .. " shift=" .. tostring(shifted))
end

--@api-stub: LMap
-- Map operations: set, get, has, len, isEmpty, keys, values, entries, merge, remove, clear
do
  local stats = lurek.patterns.newMap()

  -- Set key-value pairs.
  stats:set("hp", 100)
  stats:set("name", "hero")
  stats:set("level", 5)

  -- Query operations.
  local hp = stats:get("hp")
  local has_hp = stats:has("hp")
  local count = stats:len()
  local empty = stats:isEmpty()

  -- Iteration helpers.
  local keys = stats:keys()
  local values = stats:values()
  local entries = stats:entries()

  -- Merge another map (overwrites matching keys).
  local buffs = lurek.patterns.newMap()
  buffs:set("hp", 120)  -- buff overwrites base hp
  buffs:set("mp", 50)
  stats:merge(buffs)

  -- Remove a key.
  local removed = stats:remove("name")

  -- Clear all entries.
  stats:clear()

  print("hp=" .. tostring(hp)
    .. " has_hp=" .. tostring(has_hp)
    .. " count=" .. tostring(count)
    .. " empty=" .. tostring(empty)
    .. " keys=" .. #keys
    .. " vals=" .. #values
    .. " entries=" .. #entries
    .. " removed=" .. tostring(removed))
end

print("content/examples/patterns.lua")

-- =============================================================================
-- Additional individual method examples
-- =============================================================================

--@api-stub: lurek.patterns.newWeightedRandom
-- Create a new weighted random selection pool. Add items with weights and pick random selections.
do
  -- Loot tables use weighted random to control drop rarity.
  local loot = lurek.patterns.newWeightedRandom()
  loot:add(70.0, "common_herb", "common")
  loot:add(25.0, "rare_gem", "rare")
  loot:add(5.0, "legendary_sword", "legendary")
  local drop = loot:pick(math.random())
  print("monster dropped: " .. tostring(drop))
end

--@api-stub: lurek.patterns.newBehaviorTree
-- Create a new behavior tree for AI decision-making with sequences, selectors, parallels, and leaf actions.
do
  -- Guard AI: patrol until player spotted, then chase.
  local bt = lurek.patterns.newBehaviorTree()
  local root = bt:addSelector("guard_ai")
  local chase = bt:addLeaf("chase", "chase_leaf")
  local patrol = bt:addLeaf("patrol", "patrol_leaf")
  bt:addChild(root, chase)
  bt:addChild(root, patrol)
  bt:setLeaf("chase", function() return "failure" end)
  bt:setLeaf("patrol", function() return "success" end)
  bt:setRoot(root)
  print("guard decision: " .. bt:tick())
end

--@api-stub: lurek.patterns.newGraph
-- Create a new graph data structure with directed or undirected edges, BFS, DFS, and connectivity queries.
do
  -- Quest dependency graph: directed edges show unlock order.
  local g = lurek.patterns.newGraph(false)
  local start = g:addNode("tutorial")
  local mid = g:addNode("dungeon_1")
  local boss = g:addNode("final_boss")
  g:addEdge(start, mid, 1.0)
  g:addEdge(mid, boss, 1.0)
  print("quest graph: " .. g:nodeCount() .. " quests, " .. g:edgeCount() .. " dependencies")
end

-- -----------------------------------------------------------------------------
-- LBehaviorTree methods
-- -----------------------------------------------------------------------------

--@api-stub: LBehaviorTree:addSequence
-- Create a sequence composite node. All children must succeed for this node to succeed.
do
  -- Sequence: eat then sleep. Both must succeed for "rest" to succeed.
  local bt = lurek.patterns.newBehaviorTree()
  local seq = bt:addSequence("rest_routine")
  local eat = bt:addLeaf("eat", "eat_action")
  local sleep = bt:addLeaf("sleep", "sleep_action")
  bt:addChild(seq, eat)
  bt:addChild(seq, sleep)
  bt:setLeaf("eat", function() return "success" end)
  bt:setLeaf("sleep", function() return "success" end)
  bt:setRoot(seq)
  print("rest_routine: " .. bt:tick())
end

--@api-stub: LBehaviorTree:addSelector
-- Create a selector (fallback) composite node. Succeeds if any child succeeds.
do
  -- Selector: try ranged attack, fallback to melee.
  local bt = lurek.patterns.newBehaviorTree()
  local sel = bt:addSelector("attack_choice")
  local ranged = bt:addLeaf("ranged", "try_ranged")
  local melee = bt:addLeaf("melee", "try_melee")
  bt:addChild(sel, ranged)
  bt:addChild(sel, melee)
  bt:setLeaf("ranged", function() return "failure" end)  -- out of ammo
  bt:setLeaf("melee", function() return "success" end)
  bt:setRoot(sel)
  print("attack: " .. bt:tick())  -- falls back to melee
end

--@api-stub: LBehaviorTree:addParallel
-- Create a parallel composite node that runs all children simultaneously.
do
  -- Parallel: run and shoot at the same time (needs 1 success minimum).
  local bt = lurek.patterns.newBehaviorTree()
  local par = bt:addParallel(1, "run_and_gun")
  local run = bt:addLeaf("run", "run_action")
  local shoot = bt:addLeaf("shoot", "shoot_action")
  bt:addChild(par, run)
  bt:addChild(par, shoot)
  bt:setLeaf("run", function() return "success" end)
  bt:setLeaf("shoot", function() return "running" end)
  bt:setRoot(par)
  print("parallel: " .. bt:tick())
end

--@api-stub: LBehaviorTree:addInverter
-- Create a decorator node that inverts its child's result (success ↔ failure).
do
  -- Inverter: "is NOT hungry" check. Inverts the hunger leaf result.
  local bt = lurek.patterns.newBehaviorTree()
  local inv = bt:addInverter("not_hungry")
  local hungry = bt:addLeaf("hungry", "check_hunger")
  bt:addChild(inv, hungry)
  bt:setLeaf("hungry", function() return "failure" end)  -- not hungry
  bt:setRoot(inv)
  print("not_hungry: " .. bt:tick())  -- inverted failure -> success
end

--@api-stub: LBehaviorTree:addRepeat
-- Create a decorator node that repeats its child a fixed number of times.
do
  -- Repeat: swing sword 3 times in a combo attack.
  local bt = lurek.patterns.newBehaviorTree()
  local rep = bt:addRepeat(3, "triple_slash")
  local slash = bt:addLeaf("slash", "slash_action")
  bt:addChild(rep, slash)
  local count = 0
  bt:setLeaf("slash", function() count = count + 1; return "success" end)
  bt:setRoot(rep)
  bt:tick()
  print("slashes executed=" .. count)
end

--@api-stub: LBehaviorTree:addLeaf
-- Create a leaf (action) node that will invoke a named callback function on tick.
do
  -- Leaf nodes are the actual game actions at the bottom of the tree.
  local bt = lurek.patterns.newBehaviorTree()
  local leaf = bt:addLeaf("gather_wood", "gather_action")
  bt:setLeaf("gather_wood", function()
    return "success"
  end)
  bt:setRoot(leaf)
  print("gather result: " .. bt:tick())
end

--@api-stub: LBehaviorTree:addChild
-- Attach a child node to a parent composite or decorator node.
do
  -- Build a tree by wiring children to composites.
  local bt = lurek.patterns.newBehaviorTree()
  local root = bt:addSequence("main")
  local a = bt:addLeaf("step_a", "action_a")
  local b = bt:addLeaf("step_b", "action_b")
  local ok1 = bt:addChild(root, a)
  local ok2 = bt:addChild(root, b)
  print("wired=" .. tostring(ok1) .. "," .. tostring(ok2) .. " nodes=" .. bt:nodeCount())
end

--@api-stub: LBehaviorTree:setRoot
-- Designate a node as the tree's root. Tick evaluation starts here.
do
  -- Must set root before tick() or tree has nothing to evaluate.
  local bt = lurek.patterns.newBehaviorTree()
  local node = bt:addLeaf("idle", "idle_leaf")
  bt:setLeaf("idle", function() return "success" end)
  local ok = bt:setRoot(node)
  print("root set=" .. tostring(ok))
end

--@api-stub: LBehaviorTree:setLeaf
-- Register or replace the callback function for a named leaf. The function must return "success", "failure", or "running".
do
  -- Hot-swap leaf behavior for different AI states.
  local bt = lurek.patterns.newBehaviorTree()
  local leaf = bt:addLeaf("move", "move_action")
  bt:setRoot(leaf)
  bt:setLeaf("move", function() return "running" end)
  print("first tick: " .. bt:tick())
  bt:setLeaf("move", function() return "success" end)  -- arrived
  print("second tick: " .. bt:tick())
end

--@api-stub: LBehaviorTree:tick
-- Execute one tick of the behavior tree from the root. Returns the root node's status.
do
  -- Call tick() once per AI update frame.
  local bt = lurek.patterns.newBehaviorTree()
  local root = bt:addLeaf("think", "think_action")
  bt:setLeaf("think", function() return "running" end)
  bt:setRoot(root)
  local status = bt:tick()
  print("AI status: " .. status)  -- "running" means still processing
end

--@api-stub: LBehaviorTree:resetState
-- Reset the tree's running state. Use between encounters or when restarting AI logic.
do
  -- Reset between combat encounters so AI starts fresh.
  local bt = lurek.patterns.newBehaviorTree()
  local root = bt:addLeaf("fight", "fight_leaf")
  bt:setLeaf("fight", function() return "running" end)
  bt:setRoot(root)
  bt:tick()
  bt:resetState()
  print("state reset, ready for next encounter")
end

--@api-stub: LBehaviorTree:nodeCount
-- Return the total number of nodes in the tree.
do
  -- Monitor tree complexity for debugging.
  local bt = lurek.patterns.newBehaviorTree()
  bt:addSequence("a")
  bt:addSelector("b")
  bt:addLeaf("c", "leaf_c")
  print("tree nodes=" .. bt:nodeCount())
end

--@api-stub: LBehaviorTree:clearAll
-- Remove all nodes and leaf functions, resetting the tree to empty.
do
  -- Clear and rebuild when loading a different AI profile.
  local bt = lurek.patterns.newBehaviorTree()
  bt:addSequence("temp")
  bt:addLeaf("x", "x_leaf")
  bt:clearAll()
  print("after clear: nodes=" .. bt:nodeCount())
end

-- -----------------------------------------------------------------------------
-- LBlackboard methods
-- -----------------------------------------------------------------------------

--@api-stub: LBlackboard:set
-- Set a key to a value (boolean, number, string, or nil to clear). Notifies registered watchers if value changed.
do
  -- AI perception system writes detected info to the shared blackboard.
  local bb = lurek.patterns.newBlackboard("perception")
  bb:set("player_distance", 45.0)
  bb:set("player_visible", true)
  bb:set("cover_nearby", false)
  print("distance=" .. bb:get("player_distance"))
end

--@api-stub: LBlackboard:get
-- Retrieve the value stored under a key. Returns nil if the key does not exist.
do
  -- AI decision code reads blackboard values set by other systems.
  local bb = lurek.patterns.newBlackboard()
  bb:set("threat_level", 3)
  local threat = bb:get("threat_level") or 0
  if threat > 2 then print("high alert!") end
end

--@api-stub: LBlackboard:has
-- Check whether a key exists on the blackboard.
do
  -- Guard reads before using values that might not be set yet.
  local bb = lurek.patterns.newBlackboard()
  bb:set("waypoint_x", 100)
  if bb:has("waypoint_x") then print("waypoint assigned") end
  print("has target=" .. tostring(bb:has("target_id")))
end

--@api-stub: LBlackboard:clear
-- Remove a single key from the blackboard.
do
  -- Clear a key when the information becomes stale.
  local bb = lurek.patterns.newBlackboard()
  bb:set("last_sound_pos", 50)
  bb:clear("last_sound_pos")
  print("after clear: " .. tostring(bb:get("last_sound_pos")))  -- nil
end

--@api-stub: LBlackboard:keys
-- Return an array of all keys currently stored on the blackboard.
do
  -- Debug display of all blackboard data for AI inspector.
  local bb = lurek.patterns.newBlackboard()
  bb:set("hp", 80); bb:set("stance", "aggressive")
  local all_keys = bb:keys()
  print("blackboard has " .. #all_keys .. " entries")
end

--@api-stub: LBlackboard:getRevision
-- Return the current revision counter. Increments on every value change.
do
  -- Use revision as a dirty flag to avoid re-evaluating unchanged data.
  local bb = lurek.patterns.newBlackboard()
  local rev1 = bb:getRevision()
  bb:set("score", 10)
  local rev2 = bb:getRevision()
  print("changed=" .. tostring(rev2 > rev1))
end

--@api-stub: LBlackboard:clearAll
-- Remove all keys and values from the blackboard.
do
  -- Reset blackboard between AI encounters.
  local bb = lurek.patterns.newBlackboard()
  bb:set("a", 1); bb:set("b", 2)
  bb:clearAll()
  print("keys remaining=" .. #bb:keys())
end

-- -----------------------------------------------------------------------------
-- LCommandStack methods
-- -----------------------------------------------------------------------------

--@api-stub: LCommandStack:execute
-- Execute a named command immediately, recording it in history. Discards any redo history ahead of the current position.
do
  -- Level editor: record tile placement for undo support.
  local stack = lurek.patterns.newCommandStack(32)
  local grid = { [1] = "grass" }
  local prev = grid[1]
  stack:execute("place_wall",
    function() grid[1] = "wall" end,
    function() grid[1] = prev end
  )
  print("tile[1]=" .. grid[1])  -- "wall"
end

--@api-stub: LCommandStack:clearAll
-- Discard all command history and free associated callbacks.
do
  -- Clear history when opening a new document.
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("op1", function() end, function() end)
  stack:execute("op2", function() end, function() end)
  stack:clearAll()
  print("history after clear=" .. stack:getHistorySize())
end

-- -----------------------------------------------------------------------------
-- LDebounce methods
-- -----------------------------------------------------------------------------

--@api-stub: LDebounce:update
-- Advance the debounce timer. If the wait period elapsed since last trigger, fires the callback and returns true.
do
  -- Search-as-you-type: only search after player stops typing for 0.3s.
  local search = lurek.patterns.newDebounce(0.3)
  search:onFire(function() print("  executing search query") end)
  search:trigger()
  local fired = search:update(0.35)  -- waited long enough
  print("search fired=" .. tostring(fired))
end

--@api-stub: LEventBus:on
-- Subscribe a callback to a named event. Higher priority listeners fire first.
do
  -- HUD subscribes to score changes; high priority ensures it updates first.
  local bus = lurek.patterns.newEventBus()
  local id = bus:on("score_changed", function(new_score)
    print("  HUD: score=" .. new_score)
  end, 100)
  bus:emit("score_changed", 500)
  print("listener id=" .. id)
end

--@api-stub: LEventBus:off
-- Unsubscribe a listener by its subscription ID. Removes the callback from the event bus.
do
  -- Remove listener when the subscribing system is destroyed.
  local bus = lurek.patterns.newEventBus()
  local id = bus:on("tick", function() print("tick") end)
  bus:off(id)
  bus:emit("tick")  -- no output
  print("removed, count=" .. bus:getListenerCount("tick"))
end

--@api-stub: LEventBus:clear
-- Remove all listeners subscribed to a specific event name.
do
  -- Clear all listeners for a minigame event when exiting the minigame.
  local bus = lurek.patterns.newEventBus()
  bus:on("puzzle_move", function() end)
  bus:on("puzzle_move", function() end)
  bus:clear("puzzle_move")
  print("puzzle listeners=" .. bus:getListenerCount("puzzle_move"))
end

--@api-stub: LEventBus:clearAll
-- Remove all listeners from every event on this bus. Resets the bus to empty.
do
  -- Full reset when transitioning between major game modes.
  local bus = lurek.patterns.newEventBus()
  bus:on("a", function() end)
  bus:on("b", function() end)
  bus:clearAll()
  print("events after clearAll=" .. #bus:getEvents())
end

--@api-stub: LFactory:register
-- Register a constructor function for a given type name. Future `create()` calls with this type will invoke it.
do
  -- Register enemy constructors for data-driven spawning.
  local factory = lurek.patterns.newFactory()
  factory:register("bat", function(x, y)
    return { kind = "bat", x = x, y = y, hp = 10 }
  end)
  print("registered bat factory")
end

--@api-stub: LFactory:has
-- Check whether a constructor is registered for the given type name.
do
  -- Guard before spawning to handle unknown types gracefully.
  local factory = lurek.patterns.newFactory()
  factory:register("slime", function() return { kind = "slime" } end)
  if factory:has("slime") then print("slime spawner ready") end
  print("has dragon=" .. tostring(factory:has("dragon")))
end

--@api-stub: LFactory:remove
-- Unregister a type and discard its constructor function.
do
  -- Remove deprecated enemy types from the spawn table.
  local factory = lurek.patterns.newFactory()
  factory:register("old_enemy", function() return {} end)
  factory:remove("old_enemy")
  print("old_enemy registered=" .. tostring(factory:has("old_enemy")))
end

--@api-stub: LFactory:clearAll
-- Remove all registered types and constructors, resetting the factory.
do
  -- Reset factory when loading a different mod or expansion pack.
  local factory = lurek.patterns.newFactory()
  factory:register("a", function() end)
  factory:register("b", function() end)
  factory:clearAll()
  print("types after clear=" .. #factory:getTypes())
end

-- -----------------------------------------------------------------------------
-- LFunnel methods
-- -----------------------------------------------------------------------------

--@api-stub: LFunnel:push
-- Push a tagged event into the funnel. May trigger an immediate flush if the max entry count is reached.
do
  -- Batch analytics events to reduce network calls.
  local funnel = lurek.patterns.newFunnel(5.0, 10)
  funnel:onFlush(function(batch) print("  sent " .. #batch .. " events") end)
  funnel:push("player_move", 1)
  funnel:push("item_pickup", 1)
  print("buffered=" .. funnel:pendingCount())
end

--@api-stub: LGraph:addNode
-- Add a node to the graph with an optional label and payload value.
do
  -- Add cities to a trade route graph.
  local g = lurek.patterns.newGraph(true)
  local city_a = g:addNode("Ironforge", { gold = 5000 })
  local city_b = g:addNode("Stormwind", { gold = 8000 })
  print("added nodes: " .. city_a .. ", " .. city_b)
end

--@api-stub: LGraph:removeNode
-- Remove a node and all its connected edges. Returns true if the node existed.
do
  -- Remove a destroyed city from the travel network.
  local g = lurek.patterns.newGraph(true)
  local n = g:addNode("doomed_city")
  local ok = g:removeNode(n)
  print("removed=" .. tostring(ok) .. " nodes=" .. g:nodeCount())
end

--@api-stub: LGraph:getNodeValue
-- Retrieve the payload value stored on a node. Returns nil if no payload.
do
  -- Read quest metadata stored on graph nodes.
  local g = lurek.patterns.newGraph(false)
  local quest = g:addNode("rescue_villager", { reward = 50, xp = 200 })
  local data = g:getNodeValue(quest)
  if data then print("reward=" .. data.reward .. " xp=" .. data.xp) end
end

--@api-stub: LGraph:addEdge
-- Add a directed (or undirected) edge between two nodes with optional weight and label.
do
  -- Connect skill tree nodes with prerequisite edges.
  local g = lurek.patterns.newGraph(false)
  local basic = g:addNode("basic_attack")
  local power = g:addNode("power_strike")
  local edge_id = g:addEdge(basic, power, 1.0, "requires")
  print("edge " .. edge_id .. " connects skills")
end

--@api-stub: LGraph:removeEdge
-- Remove an edge by its ID. Returns true if it existed.
do
  -- Break a connection when a bridge is destroyed.
  local g = lurek.patterns.newGraph(true)
  local a = g:addNode("north_bank")
  local b = g:addNode("south_bank")
  local bridge = g:addEdge(a, b, 5.0, "bridge")
  g:removeEdge(bridge)
  print("bridge destroyed, edges=" .. g:edgeCount())
end

--@api-stub: LGraph:neighbors
-- Return an array of node IDs directly connected to the given node.
do
  -- Find all towns reachable from the current location.
  local g = lurek.patterns.newGraph(true)
  local home = g:addNode("home")
  local market = g:addNode("market")
  local tavern = g:addNode("tavern")
  g:addEdge(home, market, 1.0)
  g:addEdge(home, tavern, 2.0)
  local nearby = g:neighbors(home)
  print("reachable from home: " .. #nearby .. " places")
end

--@api-stub: LGraph:bfs
-- Perform a breadth-first search from a node. Returns visited node IDs in BFS order.
do
  -- BFS finds shortest path (by hops) through a dungeon room graph.
  local g = lurek.patterns.newGraph(true)
  local entrance = g:addNode("entrance")
  local hall = g:addNode("hall")
  local treasure = g:addNode("treasure")
  g:addEdge(entrance, hall, 1.0)
  g:addEdge(hall, treasure, 1.0)
  local order = g:bfs(entrance)
  print("BFS visit order: " .. #order .. " rooms")
end

--@api-stub: LGraph:dfs
-- Perform a depth-first search from a node. Returns visited node IDs in DFS order.
do
  -- DFS explores deep branches first, useful for maze solving.
  local g = lurek.patterns.newGraph(true)
  local start = g:addNode("start")
  local fork = g:addNode("fork")
  local dead_end = g:addNode("dead_end")
  g:addEdge(start, fork, 1.0)
  g:addEdge(fork, dead_end, 1.0)
  local visited = g:dfs(start)
  print("DFS explored " .. #visited .. " nodes")
end

--@api-stub: LGraph:isConnected
-- Check whether there is any path from one node to another.
do
  -- Check if two quest objectives are connected (dependency chain).
  local g = lurek.patterns.newGraph(false)
  local q1 = g:addNode("find_key")
  local q2 = g:addNode("open_door")
  local q3 = g:addNode("side_quest")
  g:addEdge(q1, q2, 1.0)
  print("key->door connected=" .. tostring(g:isConnected(q1, q2)))
  print("key->side connected=" .. tostring(g:isConnected(q1, q3)))
end

--@api-stub: LGraph:hasNode
-- Check whether a node with the given ID exists in the graph.
do
  -- Validate node references before operating on them.
  local g = lurek.patterns.newGraph(true)
  local n = g:addNode("valid")
  print("exists=" .. tostring(g:hasNode(n)))
  print("fake=" .. tostring(g:hasNode(9999)))
end

--@api-stub: LGraph:nodeCount
-- Return the total number of nodes in the graph.
do
  -- Monitor graph size for performance budgeting.
  local g = lurek.patterns.newGraph(true)
  g:addNode("a"); g:addNode("b"); g:addNode("c")
  print("total nodes=" .. g:nodeCount())
end

--@api-stub: LGraph:edgeCount
-- Return the total number of edges in the graph.
do
  -- Track connection density for pathfinding cost estimates.
  local g = lurek.patterns.newGraph(true)
  local a = g:addNode("x"); local b = g:addNode("y")
  g:addEdge(a, b, 1.0)
  print("total edges=" .. g:edgeCount())
end

--@api-stub: LGraph:clearAll
-- Remove all nodes, edges, and payloads from the graph.
do
  -- Reset graph when loading a new level or map.
  local g = lurek.patterns.newGraph(true)
  g:addNode("temp1"); g:addNode("temp2")
  g:clearAll()
  print("after clear: nodes=" .. g:nodeCount() .. " edges=" .. g:edgeCount())
end

-- -----------------------------------------------------------------------------
-- LList methods
-- -----------------------------------------------------------------------------

--@api-stub: LList:unshift
-- Insert a value at the beginning of the list.
do
  -- Prepend urgent messages to a notification queue.
  local notifications = lurek.patterns.newList()
  notifications:add("old message")
  notifications:unshift("URGENT: server restart")
  print("first=" .. notifications:get(1))
end

--@api-stub: LList:insert
-- Insert a value at a 1-based index, shifting subsequent items right.
do
  -- Insert a priority quest at a specific position in the log.
  local quests = lurek.patterns.newList()
  quests:add("explore cave")
  quests:add("talk to elder")
  quests:insert(2, "defend village")  -- inserted between the two
  print("quest 2=" .. quests:get(2) .. " total=" .. quests:len())
end

--@api-stub: LList:shift
-- Remove and return the first value. Returns nil if empty.
do
  -- Process events in FIFO order from a list used as a queue.
  local events = lurek.patterns.newList()
  events:add("spawn_wave_1")
  events:add("spawn_wave_2")
  local first = events:shift()
  print("processing: " .. tostring(first) .. " remaining=" .. events:len())
end

--@api-stub: LList:indexOf
-- Find the 1-based index of the first occurrence of a value. Returns nil if not found.
do
  -- Find where a specific item is in the inventory for UI highlighting.
  local inv = lurek.patterns.newList()
  inv:add("sword"); inv:add("shield"); inv:add("potion")
  local idx = inv:indexOf("shield")
  print("shield is at slot " .. tostring(idx))
end

--@api-stub: LList:reverse
-- Reverse the order of all items in the list in-place.
do
  -- Reverse a path for backtracking navigation.
  local path = lurek.patterns.newList()
  path:add("town"); path:add("forest"); path:add("cave")
  path:reverse()
  print("backtrack start=" .. path:get(1))  -- "cave"
end

-- -----------------------------------------------------------------------------
-- LMap methods
-- -----------------------------------------------------------------------------

--@api-stub: LMap:remove
-- Remove a key from the map. Returns true if it was present.
do
  -- Remove a consumed buff from the active effects map.
  local effects = lurek.patterns.newMap()
  effects:set("speed_boost", 1.5)
  effects:set("shield", 100)
  local removed = effects:remove("speed_boost")
  print("removed speed_boost=" .. tostring(removed) .. " remaining=" .. effects:len())
end

--@api-stub: LMap:len
-- Return the number of key-value pairs.
do
  -- Check how many config options are loaded.
  local config = lurek.patterns.newMap()
  config:set("volume", 0.8); config:set("difficulty", "hard")
  print("config entries=" .. config:len())
end

--@api-stub: LMap:isEmpty
-- Check whether the map has no entries.
do
  -- Guard against operating on an empty inventory.
  local bag = lurek.patterns.newMap()
  if bag:isEmpty() then print("inventory is empty, nothing to sell") end
  bag:set("gold_ring", 1)
  print("empty after add=" .. tostring(bag:isEmpty()))
end

--@api-stub: LMap:values
-- Return an array of all values in the map.
do
  -- Sum all stat bonuses from equipped items.
  local bonuses = lurek.patterns.newMap()
  bonuses:set("helmet", 5); bonuses:set("armor", 12); bonuses:set("boots", 3)
  local total = 0
  for _, v in ipairs(bonuses:values()) do total = total + v end
  print("total defense=" .. total)
end

--@api-stub: LMap:entries
-- Return an array of {key, value} tables for all entries.
do
  -- Serialize all settings for save file.
  local settings = lurek.patterns.newMap()
  settings:set("music", 0.7); settings:set("sfx", 1.0)
  for _, entry in ipairs(settings:entries()) do
    print("  " .. tostring(entry[1]) .. "=" .. tostring(entry[2]))
  end
end

--@api-stub: LMap:merge
-- Copy all entries from another LMap into this map. Existing keys are overwritten.
do
  -- Merge default settings with user overrides.
  local defaults = lurek.patterns.newMap()
  defaults:set("volume", 0.5); defaults:set("lang", "en")
  local overrides = lurek.patterns.newMap()
  overrides:set("volume", 0.9)  -- user prefers louder
  defaults:merge(overrides)
  print("final volume=" .. defaults:get("volume"))
end

--@api-stub: LMediator:clear
-- Remove all channels and handlers, resetting the mediator.
do
  -- Full mediator reset when transitioning between game modes.
  local m = lurek.patterns.newMediator()
  m:on("old_channel", function() end)
  m:clear()
  print("channels after clear=" .. #m:channels())
end

-- -----------------------------------------------------------------------------
-- LObjectPool methods
-- -----------------------------------------------------------------------------

--@api-stub: LObjectPool:add
-- Add an object to the pool's idle set, making it available for future acquisition.
do
  -- Pre-warm particle pool at scene load.
  local particles = lurek.patterns.newObjectPool()
  for i = 1, 16 do
    particles:add({ x = 0, y = 0, life = 0, color = "white" })
  end
  print("particle pool ready: " .. particles:getAvailableCount() .. " idle")
end

--@api-stub: LObjectPool:clearAll
-- Destroy all objects (active and idle) and reset the pool to empty.
do
  -- Free all pooled objects when unloading a scene.
  local pool = lurek.patterns.newObjectPool()
  pool:add({}); pool:add({})
  pool:acquire()
  pool:clearAll()
  print("after clearAll: total=" .. pool:getTotalCount())
end

-- -----------------------------------------------------------------------------
-- LObserver methods
-- -----------------------------------------------------------------------------

--@api-stub: LObserver:set
-- Set a value by key and notify all subscribers watching that key.
do
  -- Score changes automatically update the HUD through subscription.
  local obs = lurek.patterns.newObserver()
  obs:subscribe("gold", function(k, v) print("  wallet: " .. v .. " gold") end)
  obs:set("gold", 100)
  obs:set("gold", 150)  -- triggers notification again
end

--@api-stub: LObserver:get
-- Retrieve the current value for a key. Returns nil if not set.
do
  -- Read the current value without triggering notifications.
  local obs = lurek.patterns.newObserver()
  obs:set("level", 5)
  local lvl = obs:get("level") or 1
  print("player level=" .. lvl)
end

--@api-stub: LPriorityQueue:push
-- Add an item with a numeric priority. Higher priority items are dequeued first.
do
  -- AI task scheduler: urgent tasks processed before idle ones.
  local tasks = lurek.patterns.newPriorityQueue()
  tasks:push(10, "sweep_floor", "low")
  tasks:push(90, "extinguish_fire", "critical")
  tasks:push(40, "restock_shelves", "medium")
  print("queued " .. tasks:len() .. " tasks")
end

--@api-stub: LPriorityQueue:pop
-- Remove and return the highest-priority item. Returns nil if the queue is empty.
do
  -- Process the most urgent job from the queue.
  local jobs = lurek.patterns.newPriorityQueue()
  jobs:push(5, "low_priority_job")
  jobs:push(99, "critical_fix")
  local top = jobs:pop()
  print("processing: " .. tostring(top))  -- "critical_fix"
end

--@api-stub: LPriorityQueue:peek
-- Return the highest-priority item without removing it. Returns nil if empty.
do
  -- Preview what's next without consuming it.
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(50, "render_pass")
  local next_item = pq:peek()
  print("next job: " .. tostring(next_item) .. " still queued=" .. pq:len())
end

--@api-stub: LPriorityQueue:len
-- Return the number of items currently in the queue.
do
  -- Monitor queue backlog for load shedding decisions.
  local pq = lurek.patterns.newPriorityQueue()
  for i = 1, 5 do pq:push(i, "task_" .. i) end
  print("backlog=" .. pq:len())
end

--@api-stub: LPriorityQueue:isEmpty
-- Check whether the queue contains no items.
do
  -- Drain loop: process all pending AI decisions.
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "decide_move")
  while not pq:isEmpty() do
    print("  AI decided: " .. tostring(pq:pop()))
  end
end

--@api-stub: LPriorityQueue:clearAll
-- Remove all items from the queue. This method is available to Lua scripts.
do
  -- Flush all pending tasks when aborting an AI plan.
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "x"); pq:push(2, "y")
  pq:clearAll()
  print("after clear: len=" .. pq:len())
end

-- -----------------------------------------------------------------------------
-- LQueue methods
-- -----------------------------------------------------------------------------

--@api-stub: LQueue:enqueueFront
-- Add a value to the front of the queue (priority insertion). Returns false if at capacity.
do
  -- Priority messages jump to the front of the processing queue.
  local q = lurek.patterns.newQueue(10)
  q:enqueue("normal_msg")
  q:enqueueFront("URGENT_msg")
  print("front=" .. q:front())  -- "URGENT_msg"
end

--@api-stub: LQueue:dequeueBack
-- Remove and return the back value. Returns nil if empty.
do
  -- Remove the least recent item (opposite of normal FIFO dequeue).
  local q = lurek.patterns.newQueue(0)
  q:enqueue("first"); q:enqueue("second"); q:enqueue("third")
  local back = q:dequeueBack()
  print("removed from back: " .. tostring(back))  -- "third"
end

--@api-stub: LQueue:back
-- Return the back value without removing it. Returns nil if empty.
do
  -- Peek at the newest item in the queue.
  local q = lurek.patterns.newQueue(0)
  q:enqueue("oldest"); q:enqueue("newest")
  print("back=" .. tostring(q:back()))  -- "newest"
end

--@api-stub: LQueue:peekAt
-- Return the value at a 1-based index without removing it. Returns nil if out of range.
do
  -- Inspect queue contents at specific positions for debug display.
  local q = lurek.patterns.newQueue(0)
  q:enqueue("alpha"); q:enqueue("beta"); q:enqueue("gamma")
  print("position 2=" .. tostring(q:peekAt(2)))  -- "beta"
end

--@api-stub: LQueue:insertAt
-- Insert a value at a 1-based index in the queue. Returns false if at capacity.
do
  -- Insert a priority item at a specific position.
  local q = lurek.patterns.newQueue(10)
  q:enqueue("a"); q:enqueue("c")
  q:insertAt(2, "b")  -- insert between a and c
  print("order: " .. q:peekAt(1) .. "," .. q:peekAt(2) .. "," .. q:peekAt(3))
end

--@api-stub: LQueue:removeAt
-- Remove and return the value at a 1-based index. Returns nil if out of range.
do
  -- Cancel a specific pending command by position.
  local q = lurek.patterns.newQueue(0)
  q:enqueue("move"); q:enqueue("attack"); q:enqueue("heal")
  local removed = q:removeAt(2)
  print("cancelled: " .. tostring(removed) .. " remaining=" .. q:len())
end

--@api-stub: LQueue:len
-- Return the current number of items in the queue.
do
  -- Monitor queue depth for backpressure.
  local q = lurek.patterns.newQueue(0)
  q:enqueue("x"); q:enqueue("y"); q:enqueue("z")
  print("queue depth=" .. q:len())
end

--@api-stub: LQueue:isEmpty
-- Check whether the queue is empty. This method is available to Lua scripts.
do
  -- Check before dequeue to avoid nil handling.
  local q = lurek.patterns.newQueue(0)
  q:enqueue("last_item")
  q:dequeue()
  if q:isEmpty() then print("all commands processed") end
end

--@api-stub: LQueue:clear
-- Remove all items from the queue. This method is available to Lua scripts.
do
  -- Flush pending input commands on scene change.
  local q = lurek.patterns.newQueue(0)
  q:enqueue("stale_input_1"); q:enqueue("stale_input_2")
  q:clear()
  print("cleared, len=" .. q:len())
end

--@api-stub: LQueue:toArray
-- Return all queue items as an array table (front to back).
do
  -- Export queue contents for save file serialization.
  local q = lurek.patterns.newQueue(0)
  q:enqueue("cmd_1"); q:enqueue("cmd_2"); q:enqueue("cmd_3")
  local arr = q:toArray()
  print("exported " .. #arr .. " commands")
end

-- -----------------------------------------------------------------------------
-- LRing methods
-- -----------------------------------------------------------------------------

--@api-stub: LRing:push
-- Push a number or string value into the ring. Overwrites the oldest entry if the ring is full.
do
  -- Track frame times for rolling performance analysis.
  local frame_times = lurek.patterns.newRing(120)
  for i = 1, 130 do
    frame_times:push(16.0 + (i % 3), "ms")
  end
  print("ring samples=" .. frame_times:len())  -- capped at 120
end

--@api-stub: LRing:toArray
-- Return all entries in the ring as an ordered array of tables (oldest to newest).
do
  -- Export ring data for charting or file logging.
  local r = lurek.patterns.newRing(4)
  r:push(10, "latency"); r:push(12, "latency"); r:push(8, "latency")
  local entries = r:toArray()
  print("exported " .. #entries .. " ring entries")
end

--@api-stub: LRing:len
-- Return the number of entries currently in the ring.
do
  -- Check if enough samples collected for meaningful statistics.
  local r = lurek.patterns.newRing(60)
  r:push(1, "x"); r:push(2, "x")
  if r:len() < 10 then print("warming up, only " .. r:len() .. " samples") end
end

--@api-stub: LRing:isFull
-- Check whether the ring has reached its maximum capacity.
do
  -- Only show average after ring is fully warmed up.
  local r = lurek.patterns.newRing(3)
  r:push(60, "fps"); r:push(59, "fps"); r:push(61, "fps")
  if r:isFull() then print("stable avg=" .. string.format("%.1f", r:average())) end
end

--@api-stub: LRing:clear
-- Remove all entries from the ring. This method is available to Lua scripts.
do
  -- Clear ring data when switching measurement contexts.
  local r = lurek.patterns.newRing(16)
  r:push(1, "old"); r:push(2, "old")
  r:clear()
  print("after clear: len=" .. r:len())
end

-- -----------------------------------------------------------------------------
-- LServiceLocator methods
-- -----------------------------------------------------------------------------

--@api-stub: LServiceLocator:has
-- Check whether a service with the given name is currently registered.
do
  -- Guard optional services before attempting to use them.
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("audio", { play = function() end })
  if sl:has("audio") then print("audio system available") end
  print("has network=" .. tostring(sl:has("network")))
end

--@api-stub: LServiceLocator:remove
-- Unregister and discard a service by name.
do
  -- Remove a service when shutting down a subsystem.
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("multiplayer", { connected = true })
  sl:remove("multiplayer")
  print("multiplayer active=" .. tostring(sl:has("multiplayer")))
end

--@api-stub: LServiceLocator:clearAll
-- Remove all registered services and reset the locator.
do
  -- Full reset between game sessions.
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("a", 1); sl:provide("b", 2)
  sl:clearAll()
  print("services after reset=" .. #sl:getServices())
end

-- -----------------------------------------------------------------------------
-- LSet methods
-- -----------------------------------------------------------------------------

--@api-stub: LSet:add
-- Add a string to the set. Returns true if it was not already present.
do
  -- Track unique achievements unlocked during gameplay.
  local achievements = lurek.patterns.newSet()
  local new1 = achievements:add("first_kill")
  local new2 = achievements:add("first_kill")  -- duplicate
  print("first add=" .. tostring(new1) .. " second=" .. tostring(new2))
end

--@api-stub: LSet:remove
-- Remove a string from the set. Returns true if it was present.
do
  -- Remove an expired status effect.
  local effects = lurek.patterns.newSet()
  effects:add("poisoned")
  local was_there = effects:remove("poisoned")
  print("removed poison=" .. tostring(was_there) .. " size=" .. effects:len())
end

--@api-stub: LSet:has
-- Check whether a string is in the set.
do
  -- Check if player has required key before opening a door.
  local keys = lurek.patterns.newSet()
  keys:add("silver_key")
  if keys:has("silver_key") then print("silver door: unlocked") end
  if not keys:has("gold_key") then print("gold door: locked") end
end

--@api-stub: LSet:len
-- Return the number of items in the set.
do
  -- Count unique rooms visited for exploration percentage.
  local visited = lurek.patterns.newSet()
  visited:add("room_1"); visited:add("room_2"); visited:add("room_1")
  print("unique rooms visited=" .. visited:len())
end

--@api-stub: LSet:isEmpty
-- Check whether the set is empty. This method is available to Lua scripts.
do
  -- Check if player has any active buffs.
  local buffs = lurek.patterns.newSet()
  if buffs:isEmpty() then print("no active buffs") end
  buffs:add("haste")
  print("empty after buff=" .. tostring(buffs:isEmpty()))
end

--@api-stub: LSet:clear
-- Remove all items from the set. This method is available to Lua scripts.
do
  -- Clear all visited flags for a new game.
  local flags = lurek.patterns.newSet()
  flags:add("intro_seen"); flags:add("tutorial_done")
  flags:clear()
  print("flags after new game=" .. flags:len())
end

--@api-stub: LSimpleState:update
-- Call the current state's update callback with the frame delta time.
do
  -- Per-frame state logic: enemy moves while in "patrol" state.
  local sm = lurek.patterns.newSimpleState()
  sm:addState("patrol", {
    update = function(dt) print("  patrolling dt=" .. dt) end,
  })
  sm:transitionTo("patrol")
  sm:update(0.016)
end

--@api-stub: LSimpleState:getCurrent
-- Return the name of the currently active state, or nil if no state is set.
do
  -- Use current state for conditional logic outside the FSM.
  local sm = lurek.patterns.newSimpleState()
  sm:addState("idle", {}); sm:addState("combat", {})
  sm:transitionTo("combat")
  local state = sm:getCurrent()
  if state == "combat" then print("showing combat UI") end
end

--@api-stub: LSimpleState:clearAll
-- Remove all states and their callbacks, resetting the state machine.
do
  -- Reset FSM when loading a completely different entity type.
  local sm = lurek.patterns.newSimpleState()
  sm:addState("old_state", {})
  sm:clearAll()
  print("states after clear=" .. #sm:getStates())
end

-- -----------------------------------------------------------------------------
-- LStack methods
-- -----------------------------------------------------------------------------

--@api-stub: LStack:push
-- Push a value onto the top of the stack. Returns false if the stack is at capacity.
do
  -- Push dialog screens onto a navigation stack.
  local nav = lurek.patterns.newStack(8)
  local ok = nav:push("main_menu")
  nav:push("settings")
  print("pushed=" .. tostring(ok) .. " depth=" .. nav:len())
end

--@api-stub: LStack:pushBottom
-- Push a value onto the bottom of the stack. Returns false if at capacity.
do
  -- Insert a persistent base layer under existing screens.
  local layers = lurek.patterns.newStack(8)
  layers:push("game_hud")
  layers:pushBottom("background")
  print("bottom=" .. layers:peekBottom() .. " top=" .. layers:peek())
end

--@api-stub: LStack:pop
-- Remove and return the top value. Returns nil if the stack is empty.
do
  -- Pop to go back to previous screen.
  local screens = lurek.patterns.newStack(0)
  screens:push("world"); screens:push("inventory")
  local closed = screens:pop()
  print("closed " .. tostring(closed) .. ", now at " .. tostring(screens:peek()))
end

--@api-stub: LStack:popBottom
-- Remove and return the bottom value. Returns nil if empty.
do
  -- Remove the oldest entry from the bottom of a history stack.
  local history = lurek.patterns.newStack(0)
  history:push("page_1"); history:push("page_2"); history:push("page_3")
  local oldest = history:popBottom()
  print("removed oldest: " .. tostring(oldest))
end

--@api-stub: LStack:popMany
-- Pop up to `count` values from the top and return them as an array table.
do
  -- Close multiple dialog layers at once (e.g., force-close all popups).
  local dialogs = lurek.patterns.newStack(0)
  dialogs:push("confirm"); dialogs:push("tooltip"); dialogs:push("dropdown")
  local closed = dialogs:popMany(2)
  print("closed " .. #closed .. " dialogs, remaining=" .. dialogs:len())
end

--@api-stub: LStack:peekBottom
-- Return the bottom value without removing it. Returns nil if empty.
do
  -- Check the base screen without modifying the stack.
  local nav = lurek.patterns.newStack(0)
  nav:push("title_screen"); nav:push("options")
  print("base screen=" .. tostring(nav:peekBottom()))
end

--@api-stub: LStack:peekAt
-- Return the value at a 1-based index without removing it. Returns nil if out of range.
do
  -- Inspect a specific position for breadcrumb display.
  local breadcrumbs = lurek.patterns.newStack(0)
  breadcrumbs:push("Home"); breadcrumbs:push("Shop"); breadcrumbs:push("Weapons")
  print("breadcrumb[2]=" .. tostring(breadcrumbs:peekAt(2)))
end

--@api-stub: LStack:insertAt
-- Insert a value at a 1-based index in the stack, shifting items above it. Returns false if at capacity.
do
  -- Insert a layer between existing layers (e.g., notification between HUD and dialog).
  local layers = lurek.patterns.newStack(10)
  layers:push("hud"); layers:push("dialog")
  layers:insertAt(2, "notification")
  print("middle layer=" .. tostring(layers:peekAt(2)))
end

--@api-stub: LStack:removeAt
-- Remove and return the value at a 1-based index. Returns nil if out of range.
do
  -- Remove a specific item from the middle of the stack.
  local cards = lurek.patterns.newStack(0)
  cards:push("ace"); cards:push("king"); cards:push("queen")
  local removed = cards:removeAt(2)
  print("removed=" .. tostring(removed) .. " remaining=" .. cards:len())
end

--@api-stub: LStack:moveWithin
-- Move an item from one 1-based index to another within the stack.
do
  -- Reorder layers (move a UI element to a different z-depth).
  local z_order = lurek.patterns.newStack(0)
  z_order:push("background"); z_order:push("entities"); z_order:push("effects")
  z_order:moveWithin(1, 3)  -- move background to top
  print("new top=" .. tostring(z_order:peek()))
end

--@api-stub: LStack:len
-- Return the current number of items in the stack.
do
  -- Check stack depth for navigation breadcrumb display.
  local nav = lurek.patterns.newStack(0)
  nav:push("a"); nav:push("b"); nav:push("c")
  print("navigation depth=" .. nav:len())
end

--@api-stub: LStack:isEmpty
-- Check whether the stack is empty. This method is available to Lua scripts.
do
  -- If stack is empty, player has navigated all the way back.
  local nav = lurek.patterns.newStack(0)
  nav:push("only_screen")
  nav:pop()
  if nav:isEmpty() then print("at root, show exit prompt") end
end

--@api-stub: LStack:isFull
-- Check whether the stack has reached its capacity limit (if one was set).
do
  -- Prevent pushing more screens when at max depth.
  local nav = lurek.patterns.newStack(3)
  nav:push("a"); nav:push("b"); nav:push("c")
  if nav:isFull() then print("max dialog depth reached") end
end

--@api-stub: LStack:clear
-- Remove all items from the stack. This method is available to Lua scripts.
do
  -- Clear navigation stack when returning to title screen.
  local nav = lurek.patterns.newStack(0)
  nav:push("game"); nav:push("pause")
  nav:clear()
  print("stack cleared, len=" .. nav:len())
end

--@api-stub: LStack:toArray
-- Return all stack items as an array table (bottom to top).
do
  -- Export stack contents for breadcrumb trail UI.
  local trail = lurek.patterns.newStack(0)
  trail:push("Home"); trail:push("World"); trail:push("Dungeon")
  local arr = trail:toArray()
  print("trail: " .. table.concat(arr, " > "))
end

-- -----------------------------------------------------------------------------
-- LStrategy methods
-- -----------------------------------------------------------------------------

--@api-stub: LStrategy:set
-- Switch to a named strategy. Future `execute()` calls will use this implementation.
do
  -- Switch pathfinding algorithm based on terrain type.
  local pathfinder = lurek.patterns.newStrategy()
  pathfinder:register("astar", function(from, to) return "path_via_astar" end)
  pathfinder:register("dijkstra", function(from, to) return "path_via_dijkstra" end)
  local ok = pathfinder:set("astar")
  print("set astar=" .. tostring(ok))
end

--@api-stub: LStrategy:has
-- Check whether a strategy with the given name is registered.
do
  -- Validate strategy exists before switching.
  local s = lurek.patterns.newStrategy()
  s:register("fast", function() return 1 end)
  if s:has("fast") then print("fast strategy available") end
  print("has slow=" .. tostring(s:has("slow")))
end

--@api-stub: LStrategy:remove
-- Remove a named strategy. If it was the active strategy, no strategy will be selected.
do
  -- Remove a deprecated algorithm.
  local s = lurek.patterns.newStrategy()
  s:register("old_algo", function() return 0 end)
  local removed = s:remove("old_algo")
  print("removed=" .. tostring(removed))
end

--@api-stub: LStrategy:clear
-- Remove all strategies and reset the selection.
do
  -- Reset when loading a new configuration that defines fresh strategies.
  local s = lurek.patterns.newStrategy()
  s:register("a", function() end); s:register("b", function() end)
  s:clear()
  print("strategies after clear=" .. #s:names())
end

-- -----------------------------------------------------------------------------
-- LThrottle methods
-- -----------------------------------------------------------------------------

--@api-stub: LThrottle:onFire
-- Set the callback function to invoke each time the throttle fires.
do
  -- Rate-limit network position updates to 10 per second.
  local net_send = lurek.patterns.newThrottle(0.1)
  net_send:onFire(function()
    print("  sending position update to server")
  end)
  net_send:update(0.1)  -- fires
end

--@api-stub: LThrottle:update
-- Advance the throttle timer. If the interval has elapsed, fires the callback and returns true.
do
  -- Weapon cooldown: fire rate limited to 2 shots/second.
  local weapon = lurek.patterns.newThrottle(0.5)
  weapon:onFire(function() print("  shot fired!") end)
  local fired1 = weapon:update(0.3)  -- not enough time
  local fired2 = weapon:update(0.3)  -- total 0.6 > 0.5, fires
  print("attempt1=" .. tostring(fired1) .. " attempt2=" .. tostring(fired2))
end

--@api-stub: LThrottle:getFireCount
-- Return the total number of times this throttle has fired since creation.
do
  -- Track total shots fired for statistics.
  local t = lurek.patterns.newThrottle(0.1)
  t:onFire(function() end)
  t:update(0.1); t:update(0.1); t:update(0.1)
  print("total fires=" .. t:getFireCount())
end

--@api-stub: LWeightedRandom:setWeight
-- Change the weight of an existing entry.
do
  -- Pity system: increase rare drop chance after each failed attempt.
  local loot = lurek.patterns.newWeightedRandom()
  local rare_id = loot:add(5.0, "epic_sword", "rare")
  loot:add(95.0, "common_coin", "common")
  -- After 10 failed rolls, boost the rare weight.
  loot:setWeight(rare_id, 25.0)
  print("rare weight boosted, total=" .. string.format("%.1f", loot:totalWeight()))
end

--@api-stub: LWeightedRandom:pick
-- Pick one item using a random sample value in [0, 1). Returns its value or nil.
do
  -- Roll a loot drop using a random number.
  local loot = lurek.patterns.newWeightedRandom()
  loot:add(80.0, "gold", "common")
  loot:add(20.0, "diamond", "rare")
  local drop = loot:pick(math.random())
  print("dropped: " .. tostring(drop))
end

--@api-stub: LWeightedRandom:pickN
-- Pick multiple unique items. Requires an array of random samples.
do
  -- Generate a loot chest with 3 unique drops.
  local pool = lurek.patterns.newWeightedRandom()
  pool:add(40.0, "potion", "consumable")
  pool:add(30.0, "arrow_bundle", "ammo")
  pool:add(20.0, "gem", "material")
  pool:add(10.0, "rare_ring", "equip")
  local drops = pool:pickN(3, { math.random(), math.random(), math.random() })
  print("chest contains " .. #drops .. " items")
end

--@api-stub: LWeightedRandom:totalWeight
-- Return the sum of all entry weights.
do
  -- Verify weight distribution sums correctly for probability display.
  local wr = lurek.patterns.newWeightedRandom()
  wr:add(60.0, "common", "tier_1")
  wr:add(30.0, "uncommon", "tier_2")
  wr:add(10.0, "rare", "tier_3")
  print("total weight=" .. wr:totalWeight())  -- 100.0
end

--@api-stub: LWeightedRandom:clearAll
-- Remove all entries from the pool. This method is available to Lua scripts.
do
  -- Reset loot table when switching between dungeon floors.
  local wr = lurek.patterns.newWeightedRandom()
  wr:add(50.0, "floor_1_loot", "f1")
  wr:clearAll()
  print("entries after clear=" .. wr:len())
end
