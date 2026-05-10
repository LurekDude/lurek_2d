-- content/examples/patterns.lua
-- Hand-written coverage of the lurek.patterns API (170 items).
--
-- The patterns namespace ships reusable software design patterns as
-- Lua UserData wrappers: pub-sub buses, undo stacks, pools, FSMs,
-- priority queues, ring buffers, throttles, and basic collections
-- (Stack, Queue, List, Set). Build instances at startup with the
-- newXxx factories and store them on a long-lived module table or
-- service locator so callbacks survive across scenes.
--
-- Run: cargo run -- content/examples/patterns.lua

-- â”€â”€ lurek.patterns.* functions â”€â”€

--@api-stub: lurek.patterns.newEventBus
-- Creates a new EventBus instance.
-- Pass an optional debug name to make traces easier; share one bus across systems via a service locator.
do -- lurek.patterns.newEventBus
  local bus = lurek.patterns.newEventBus("ui_bus")
  local id = bus:on("hp_changed", function(hp) print("hp now", hp) end)
  bus:emit("hp_changed", 42)
  bus:off(id)
end

--@api-stub: lurek.patterns.newObjectPool
-- Creates a new ObjectPool instance.
-- Pre-populate with add() and reuse acquire/release inside lurek.process to avoid per-frame allocations.
do -- lurek.patterns.newObjectPool
  local pool = lurek.patterns.newObjectPool()
  pool:add({ x = 0, y = 0, vx = 0, vy = 0 })
  pool:add({ x = 0, y = 0, vx = 0, vy = 0 })
  local bullet = pool:acquire()
  if bullet then bullet.x, bullet.y = 100, 200 end
end

--@api-stub: lurek.patterns.newCommandStack
-- Creates a new CommandStack instance.
-- Pass max_size > 0 to cap memory in long editor sessions; pair every execute with an undo closure.
do -- lurek.patterns.newCommandStack
  local stack = lurek.patterns.newCommandStack(64)
  local x = 0
  stack:execute("move", function() x = x + 10 end, function() x = x - 10 end)
  print("after exec x=" .. x)
  stack:undo()
  print("after undo x=" .. x)
end

--@api-stub: lurek.patterns.newServiceLocator
-- Creates a new ServiceLocator instance.
-- Use as a single root container at startup so other modules can locate logger, audio, save, etc. by name.
do -- lurek.patterns.newServiceLocator
  local services = lurek.patterns.newServiceLocator()
  services:provide("logger", { info = function(m) print("[info] " .. m) end })
  local log = services:locate("logger")
  if log then log.info("services online") end
end

--@api-stub: lurek.patterns.newFactory
-- Creates a new Factory instance.
-- Register every entity prototype at boot then call create() with a string name read from save data or level files.
do -- lurek.patterns.newFactory
  local enemies = lurek.patterns.newFactory()
  enemies:register("goblin", function(x, y) return { kind = "goblin", x = x, y = y, hp = 20 } end)
  local g = enemies:create("goblin", 64, 32)
  print("spawned " .. g.kind .. " at " .. g.x .. "," .. g.y)
end

--@api-stub: lurek.patterns.newSimpleState
-- Creates a new SimpleState finite state machine instance.
-- Drive AI / UI mode switches; call sm:update(dt) every frame from lurek.process so the active state ticks.
do -- lurek.patterns.newSimpleState
  local sm = lurek.patterns.newSimpleState()
  sm:addState("idle", { enter = function() print("idle") end })
  sm:addState("walk", { update = function(dt) print("walking dt=" .. dt) end })
  sm:transitionTo("walk")
  sm:update(0.016)
end

--@api-stub: lurek.patterns.newBlackboard
-- Creates a new Blackboard shared key-value store.
-- Use as the cross-system fact store (player_hp, alarm_on, etc.); only bool/number/string values are accepted.
do -- lurek.patterns.newBlackboard
  local bb = lurek.patterns.newBlackboard("ai_world")
  bb:set("player_hp", 100)
  bb:set("alarm_on", false)
  if not bb:get("alarm_on") and bb:get("player_hp") < 25 then bb:set("alarm_on", true) end
  print("alarm=" .. tostring(bb:get("alarm_on")))
end

--@api-stub: lurek.patterns.newObserver
-- Creates a new reactive property Observer.
-- Use for simple reactive bindings (HUD shows score, music reacts to mode); subscribe with "*" to log all writes.
do -- lurek.patterns.newObserver
  local obs = lurek.patterns.newObserver("hud")
  obs:subscribe("score", function(_, v) print("hud score=" .. v) end)
  obs:set("score", 0)
  obs:set("score", 100)
end

--@api-stub: lurek.patterns.newThrottle
-- Creates a leading-edge rate limiter that fires at most once per interval seconds.
-- Wrap noisy player input (firing, sound triggers) so a 0.2s cooldown is enforced regardless of polling rate.
do -- lurek.patterns.newThrottle
  local fire = lurek.patterns.newThrottle(0.25)
  fire:onFire(function() print("BANG") end)
  function lurek.process(dt) if lurek.input.isDown("space") then fire:update(dt) end end
end

--@api-stub: lurek.patterns.newDebounce
-- Creates a trailing-edge debounce that fires after the input stream is idle for wait seconds.
-- Perfect for save-on-edit UX: trigger() on every keystroke, the save closure runs once after 0.5s of silence.
do -- lurek.patterns.newDebounce
  local save = lurek.patterns.newDebounce(0.5)
  save:onFire(function() print("autosave") end)
  function lurek.process(dt) save:update(dt) end
  save:trigger()
end

--@api-stub: lurek.patterns.newPriorityQueue
-- Creates a stable priority-ordered task queue.
-- Use for AI action selection or job scheduling; higher integer priority is dequeued first, ties keep insertion order.
do -- lurek.patterns.newPriorityQueue
  local jobs = lurek.patterns.newPriorityQueue("ai_jobs")
  jobs:push(10, { kind = "patrol" })
  jobs:push(50, { kind = "attack", target = "player" })
  local top = jobs:pop()
  if top then print("running job: " .. top.kind) end
end

--@api-stub: lurek.patterns.newRing
-- Creates a fixed-capacity circular history buffer.
-- Use for FPS / damage / latency rolling windows; sum() and average() operate on the numeric values directly.
do -- lurek.patterns.newRing
  local fps_log = lurek.patterns.newRing(60, "fps")
  for i = 1, 65 do fps_log:push(58 + (i % 4), "frame") end
  print("avg fps=" .. fps_log:average() .. " entries=" .. fps_log:len())
end

--@api-stub: lurek.patterns.newFunnel
-- Creates a time-windowed event aggregator. window=0 means flush on every push.
-- Batch noisy log/network/analytics events and process them in groups every N seconds or after M entries.
do -- lurek.patterns.newFunnel
  local analytics = lurek.patterns.newFunnel(2.0, 32, "events")
  analytics:onFlush(function(batch) print("flushing " .. #batch .. " events") end)
  analytics:push("level_start", 1)
  analytics:push("kill", 5)
  function lurek.process(dt) analytics:update(dt) end
end

--@api-stub: lurek.patterns.newRelationshipManager
-- Creates a new entity relationship manager.
-- Track per-pair faction values (-100..100) and named diplomatic levels ("ally", "hostile") between ECS entity ids.
do -- lurek.patterns.newRelationshipManager
  local rel = lurek.patterns.newRelationshipManager()
  rel:defineType("diplomacy", { "hostile", "neutral", "friendly", "ally" }, "neutral")
  rel:setValue(101, 202, -50)
  rel:setLevel(101, 202, "diplomacy", "hostile")
  print("level=" .. rel:getLevel(101, 202, "diplomacy"))
end

--@api-stub: lurek.patterns.newMediator
-- Creates a new named-channel message broker.
-- Use when systems must talk through named topics ("chat", "telemetry") without holding direct references.
do -- lurek.patterns.newMediator
  local hub = lurek.patterns.newMediator()
  hub:on("chat", function(user, msg) print(user .. ": " .. msg) end)
  hub:send("chat", "alice", "gg")
end

--@api-stub: lurek.patterns.newStrategy
-- Creates a new strategy registry.
-- Swap algorithms (pathfinding heuristic, damage formula) at runtime by name without if/elseif ladders.
do -- lurek.patterns.newStrategy
  local damage = lurek.patterns.newStrategy()
  damage:register("normal", function(atk, def) return math.max(1, atk - def) end)
  damage:register("crit", function(atk, def) return math.max(1, atk * 2 - def) end)
  damage:set("crit")
  print("dmg=" .. damage:execute(20, 5))
end

--@api-stub: lurek.patterns.newStack
-- Creates a LIFO stack. capacity=0 means unlimited.
-- Use for scene/menu navigation history; pass a positive capacity to bound memory.
do -- lurek.patterns.newStack
  local nav = lurek.patterns.newStack(8)
  nav:push("main_menu")
  nav:push("options")
  print("top=" .. nav:peek() .. " depth=" .. nav:len())
  nav:pop()
end

--@api-stub: lurek.patterns.newQueue
-- Creates a FIFO queue. capacity=0 means unlimited.
-- Use for chat messages, network packet inboxes, AI command queues; bounded capacity drops new pushes when full.
do -- lurek.patterns.newQueue
  local mail = lurek.patterns.newQueue(0)
  mail:enqueue("hello")
  mail:enqueue("ready?")
  print("front=" .. mail:front() .. " size=" .. mail:len())
end

--@api-stub: lurek.patterns.newList
-- Creates an ordered, resizable list.
-- Use as a 1-indexed managed array with explicit add/get/set/remove; safer than raw Lua tables for shared state.
do -- lurek.patterns.newList
  local quests = lurek.patterns.newList()
  quests:add("Find the key")
  quests:add("Open the chest")
  quests:set(1, "Find the brass key")
  print("quest[1]=" .. quests:get(1))
end

--@api-stub: lurek.patterns.newSet
-- Creates an unordered set that rejects duplicate values (by string key).
-- Use for membership tests (unlocked levels, picked-up items); add() returns false when the key was already present.
do -- lurek.patterns.newSet
  local unlocked = lurek.patterns.newSet()
  unlocked:add("level_1")
  unlocked:add("level_2")
  if unlocked:has("level_2") then print("portal open") end
end

--@api-stub: LEventBus:on
-- Registers a listener callback for an event.
-- Capture the returned id so you can later remove this exact listener with bus:off(id).
do -- EventBus:on
  local bus = lurek.patterns.newEventBus("game")
  local id = bus:on("level_clear", function(lvl) print("cleared " .. lvl) end, 100)
  bus:emit("level_clear", "forest_01")
  bus:off(id)
end

--@api-stub: LEventBus:off
-- Removes a previously registered event listener by subscription ID.
-- Always pair every on() in a scene with an off() in scene teardown to avoid stale closures firing.
do -- EventBus:off
  local bus = lurek.patterns.newEventBus()
  local id = bus:on("ping", function() print("pong") end)
  bus:off(id)
  bus:emit("ping")  -- no listener now
  print("listeners=" .. bus:getListenerCount("ping"))
end

--@api-stub: LEventBus:emit
-- Dispatches an event, calling all registered listeners in priority order.
-- Pass any extra args after the event name; they are forwarded verbatim to every listener.
do -- EventBus:emit
  local bus = lurek.patterns.newEventBus()
  bus:on("damage", function(amount, src) print(src .. " dealt " .. amount) end)
  bus:emit("damage", 12, "goblin")
  bus:emit("damage", 30, "boss")
end

--@api-stub: LEventBus:clear
-- Removes all listeners for a specific event.
-- Use when retiring a single feature (e.g. unloading a minigame) without disturbing other event channels.
do -- EventBus:clear
  local bus = lurek.patterns.newEventBus()
  bus:on("minigame_score", function(s) print("score " .. s) end)
  bus:on("minigame_score", function(s) print("hud " .. s) end)
  bus:clear("minigame_score")
  print("after clear: " .. bus:getListenerCount("minigame_score"))
end

--@api-stub: LEventBus:clearAll
-- Removes all listeners on this EventBus.
-- Call on full scene unload to release every closure registered since the bus was created.
do -- EventBus:clearAll
  local bus = lurek.patterns.newEventBus()
  bus:on("a", function() end)
  bus:on("b", function() end)
  bus:clearAll()
  print("events left=" .. #bus:getEvents())
end

--@api-stub: LEventBus:getListenerCount
-- Returns the number of listeners registered for an event.
-- Useful in tests and HUDs to verify hot-reload didnâ€™t double-subscribe handlers.
do -- EventBus:getListenerCount
  local bus = lurek.patterns.newEventBus()
  bus:on("hit", function() end)
  bus:on("hit", function() end)
  local n = bus:getListenerCount("hit")
  if n > 1 then print("warning: " .. n .. " hit listeners") end
end

--@api-stub: LEventBus:getEvents
-- Returns all event names that have at least one listener.
-- Great for a debug HUD listing live event channels; iterate the returned array with ipairs.
do -- EventBus:getEvents
  local bus = lurek.patterns.newEventBus()
  bus:on("save", function() end)
  bus:on("quit", function() end)
  for _, name in ipairs(bus:getEvents()) do print("ch:" .. name) end
end

--@api-stub: LObjectPool:add
-- Inserts a pre-built object into the available pool.
-- Call repeatedly at boot to prewarm the pool with the maximum number of concurrent objects you expect.
do -- ObjectPool:add
  local bullets = lurek.patterns.newObjectPool()
  for i = 1, 32 do bullets:add({ x = 0, y = 0, alive = false }) end
  print("pre-warmed bullets=" .. bullets:getAvailableCount())
end

--@api-stub: LObjectPool:acquire
-- Acquires an available object from the pool; returns nil if empty.
-- Always nil-check the result; reset the borrowed objectâ€™s fields before use because state is not auto-cleared.
do -- ObjectPool:acquire
  local pool = lurek.patterns.newObjectPool()
  pool:add({ x = 0, y = 0, vx = 0, vy = 0 })
  local b = pool:acquire()
  if b then b.x, b.y, b.vx = 50, 50, 200 end
  print("active=" .. pool:getActiveCount())
end

--@api-stub: LObjectPool:release
-- Returns an object to the available pool.
-- Pass back the SAME object reference you got from acquire(); the pool tracks oldest-first via an internal queue.
do -- ObjectPool:release
  local pool = lurek.patterns.newObjectPool()
  pool:add({ alive = false })
  local p = pool:acquire()
  p.alive = false
  pool:release(p)
  print("idle=" .. pool:getAvailableCount())
end

--@api-stub: LObjectPool:getActiveCount
-- Returns the number of currently active (acquired) objects.
-- Display in a debug HUD to spot pool leaks (acquire without matching release).
do -- ObjectPool:getActiveCount
  local pool = lurek.patterns.newObjectPool()
  pool:add({}); pool:add({})
  pool:acquire(); pool:acquire()
  local n = pool:getActiveCount()
  if n > 100 then print("WARN pool leak: " .. n) end
end

--@api-stub: LObjectPool:getAvailableCount
-- Returns the number of available (idle) objects in the pool.
-- Use to decide whether to grow the pool with another add() before acquiring under load.
do -- ObjectPool:getAvailableCount
  local pool = lurek.patterns.newObjectPool()
  for i = 1, 4 do pool:add({}) end
  pool:acquire()
  if pool:getAvailableCount() < 2 then pool:add({}) end
  print("idle now=" .. pool:getAvailableCount())
end

--@api-stub: LObjectPool:getTotalCount
-- Returns the total number of tracked objects (active + available).
-- Reflects the poolâ€™s peak allocation; useful for budgeting and tuning the prewarm count.
do -- ObjectPool:getTotalCount
  local pool = lurek.patterns.newObjectPool()
  for i = 1, 16 do pool:add({}) end
  pool:acquire()
  print("total=" .. pool:getTotalCount() .. " active=" .. pool:getActiveCount())
end

--@api-stub: LObjectPool:clearAll
-- Clears all objects from the pool, releasing Lua registry values.
-- Call on scene change to drop every borrowed and idle object so they can be garbage-collected.
do -- ObjectPool:clearAll
  local pool = lurek.patterns.newObjectPool()
  pool:add({}); pool:add({})
  pool:clearAll()
  print("after clear total=" .. pool:getTotalCount())
end

--@api-stub: LCommandStack:execute
-- Executes a named command and records it in undo/redo history.
-- Both closures should capture the data they need; the exec runs immediately, the undo runs only on stack:undo().
do -- CommandStack:execute
  local stack = lurek.patterns.newCommandStack(0)
  local doc = { text = "hello" }
  local function run(s) local prev = doc.text; doc.text = doc.text .. s; return prev end
  local prev = doc.text
  stack:execute("append", function() doc.text = doc.text .. "!" end, function() doc.text = prev end)
  print("doc=" .. doc.text)
end

--@api-stub: LCommandStack:undo
-- Undoes the most recent command. Returns true if successful.
-- Returns false when the history is empty or the last command was registered without an undo closure.
do -- CommandStack:undo
  local stack = lurek.patterns.newCommandStack(0)
  local x = 5
  stack:execute("inc", function() x = x + 1 end, function() x = x - 1 end)
  local ok = stack:undo()
  print("undone=" .. tostring(ok) .. " x=" .. x)
end

--@api-stub: LCommandStack:redo
-- Re-executes the next undone command. Returns true if successful.
-- Calling execute() after an undo wipes the redo branch, mirroring most editor undo trees.
do -- CommandStack:redo
  local stack = lurek.patterns.newCommandStack(0)
  local n = 0
  stack:execute("step", function() n = n + 1 end, function() n = n - 1 end)
  stack:undo()
  stack:redo()
  print("after redo n=" .. n)
end

--@api-stub: LCommandStack:canUndo
-- Returns true if the most recent command can be undone.
-- Bind to your Edit > Undo menu itemâ€™s enabled state so users see when thereâ€™s nothing to undo.
do -- CommandStack:canUndo
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("noop", function() end, function() end)
  if stack:canUndo() then print("undo enabled") else print("undo disabled") end
end

--@api-stub: LCommandStack:canRedo
-- Returns true if there is a command available to redo.
-- Pair with canUndo() to drive Edit > Redo menu state in editors and level designers.
do -- CommandStack:canRedo
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("noop", function() end, function() end)
  stack:undo()
  if stack:canRedo() then print("redo enabled") end
end

--@api-stub: LCommandStack:getHistorySize
-- Returns the total number of recorded commands (undo + redo).
-- Useful for HUD breadcrumbs (â€śstep 7 of 12â€ť) and to detect accidental memory growth.
do -- CommandStack:getHistorySize
  local stack = lurek.patterns.newCommandStack(0)
  for i = 1, 5 do stack:execute("op_" .. i, function() end, function() end) end
  print("history=" .. stack:getHistorySize())
end

--@api-stub: LCommandStack:getCurrentName
-- Returns the name of the most recently executed command, or nil.
-- Display in the status bar so the next undoâ€™s effect is visible to the user before they press it.
do -- CommandStack:getCurrentName
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("paint", function() end, function() end)
  local name = stack:getCurrentName()
  if name then print("undo will revert: " .. name) end
end

--@api-stub: LCommandStack:clearAll
-- Clears all command history, releasing Lua registry values.
-- Call when loading a fresh document so the previous fileâ€™s undo history is dropped.
do -- CommandStack:clearAll
  local stack = lurek.patterns.newCommandStack(0)
  stack:execute("a", function() end, function() end)
  stack:clearAll()
  print("history after clear=" .. stack:getHistorySize())
end

--@api-stub: LServiceLocator:provide
-- Registers a named service with an associated Lua value.
-- Call once at boot per service; providing the same name again replaces the previous registration.
do -- ServiceLocator:provide
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("clock", { now = function() return 42.0 end })
  sl:provide("save", { path = "save/slot1.dat" })
  print("services=" .. #sl:getServices())
end

--@api-stub: LServiceLocator:locate
-- Retrieves a registered service by name; returns nil if not found.
-- Always nil-check before use so unregistered subsystems fail loudly instead of crashing on a method call.
do -- ServiceLocator:locate
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("audio", { volume = 0.8 })
  local audio = sl:locate("audio")
  if audio then print("vol=" .. audio.volume) end
end

--@api-stub: LServiceLocator:has
-- Returns true if a service with the given name is registered.
-- Branch on this for optional dependencies (analytics, mod loader) so the game runs without them too.
do -- ServiceLocator:has
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("analytics", {})
  if sl:has("analytics") then print("telemetry on") end
end

--@api-stub: LServiceLocator:remove
-- Unregisters and removes a named service.
-- Call on shutdown of the providing module so other systems checking has() see the truth.
do -- ServiceLocator:remove
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("net", { online = true })
  sl:remove("net")
  print("net registered=" .. tostring(sl:has("net")))
end

--@api-stub: LServiceLocator:getServices
-- Returns a table of all registered service names.
-- Iterate with ipairs to render a debug overlay of every active subsystem.
do -- ServiceLocator:getServices
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("a", 1); sl:provide("b", 2)
  for _, name in ipairs(sl:getServices()) do print("svc: " .. name) end
end

--@api-stub: LServiceLocator:clearAll
-- Removes all registered services.
-- Use during integration tests to reset the container between cases.
do -- ServiceLocator:clearAll
  local sl = lurek.patterns.newServiceLocator()
  sl:provide("x", 1); sl:provide("y", 2)
  sl:clearAll()
  print("count=" .. #sl:getServices())
end

--@api-stub: LFactory:register
-- Registers a named type constructor function.
-- Wire prototypes at boot from a single data table; constructors should be pure factories returning a new instance.
do -- Factory:register
  local f = lurek.patterns.newFactory()
  f:register("orc", function(x, y) return { kind = "orc", hp = 30, x = x, y = y } end)
  f:register("troll", function(x, y) return { kind = "troll", hp = 80, x = x, y = y } end)
  print("registered=" .. #f:getTypes())
end

--@api-stub: LFactory:create
-- Creates an instance of the named type by invoking its constructor.
-- Accepts both canonical names and aliases; extra arguments are forwarded to the constructor verbatim.
do -- Factory:create
  local f = lurek.patterns.newFactory()
  f:register("coin", function(v) return { kind = "coin", value = v } end)
  local c = f:create("coin", 50)
  print("dropped " .. c.value .. " gold")
end

--@api-stub: LFactory:has
-- Returns true if the named type (or alias) is registered.
-- Use as an early guard to keep create() from raising on data-driven spawns from level files.
do -- Factory:has
  local f = lurek.patterns.newFactory()
  f:register("npc", function() return { kind = "npc" } end)
  if f:has("npc") then print("npc factory ready") end
end

--@api-stub: LFactory:alias
-- Registers an alias pointing to an existing canonical type name.
-- Use to support legacy level data: alias â€śmonster_v1â€ť â†’ â€śgoblinâ€ť without rewriting save files.
do -- Factory:alias
  local f = lurek.patterns.newFactory()
  f:register("goblin", function() return { kind = "goblin" } end)
  f:alias("monster_v1", "goblin")
  local m = f:create("monster_v1")
  print("created via alias: " .. m.kind)
end

--@api-stub: LFactory:getTypes
-- Returns a table of all registered type names.
-- Render in level-editor dropdowns so designers always see the live list of spawnable types.
do -- Factory:getTypes
  local f = lurek.patterns.newFactory()
  f:register("a", function() end); f:register("b", function() end)
  for _, name in ipairs(f:getTypes()) do print("type:" .. name) end
end

--@api-stub: LFactory:remove
-- Unregisters a type constructor (and any aliases pointing to it).
-- Use during hot-reload to drop the old constructor before re-registering the new one.
do -- Factory:remove
  local f = lurek.patterns.newFactory()
  f:register("temp", function() return {} end)
  f:remove("temp")
  print("temp still registered=" .. tostring(f:has("temp")))
end

--@api-stub: LFactory:clearAll
-- Removes all registered type constructors and aliases.
-- Ideal for test setup to reset between cases without rebuilding the factory object.
do -- Factory:clearAll
  local f = lurek.patterns.newFactory()
  f:register("x", function() end)
  f:clearAll()
  print("types after clear=" .. #f:getTypes())
end

--@api-stub: LSimpleState:addState
-- Registers a named state with optional enter, exit, and update callbacks.
-- Pass a callbacks table with any combination of enter/exit/update; re-adding the same name replaces the callbacks.
do -- SimpleState:addState
  local sm = lurek.patterns.newSimpleState()
  sm:addState("idle", { enter = function() print("> idle") end, exit = function() print("< idle") end })
  sm:addState("attack", { update = function(dt) print("attacking " .. dt) end })
  print("states=" .. #sm:getStates())
end

--@api-stub: LSimpleState:transitionTo
-- Transitions to a named state, calling exit/enter callbacks as needed.
-- Returns false when the target state is not registered, so guard transitions read from data.
do -- SimpleState:transitionTo
  local sm = lurek.patterns.newSimpleState()
  sm:addState("menu", {})
  sm:addState("game", { enter = function() print("game start") end })
  sm:transitionTo("menu")
  sm:transitionTo("game")
end

--@api-stub: LSimpleState:update
-- Calls the update callback of the current state with the given delta time.
-- Drive once per frame from lurek.process(dt); states without an update callback are no-ops.
do -- SimpleState:update
  local sm = lurek.patterns.newSimpleState()
  sm:addState("run", { update = function(dt) print("tick " .. dt) end })
  sm:transitionTo("run")
  function lurek.process(dt) sm:update(dt) end
end

--@api-stub: LSimpleState:getCurrent
-- Returns the name of the current state, or nil if none is active.
-- Branch on this for HUD labels and to drive input mapping (menu vs combat vs cutscene).
do -- SimpleState:getCurrent
  local sm = lurek.patterns.newSimpleState()
  sm:addState("paused", {})
  sm:transitionTo("paused")
  if sm:getCurrent() == "paused" then print("game is paused") end
end

--@api-stub: LSimpleState:hasState
-- Returns true if a state with the given name is registered.
-- Useful when transitions are driven by save data â€” test the name before calling transitionTo.
do -- SimpleState:hasState
  local sm = lurek.patterns.newSimpleState()
  sm:addState("boss", {})
  if sm:hasState("boss") then sm:transitionTo("boss") end
end

--@api-stub: LSimpleState:getStates
-- Returns a table of all registered state names.
-- Render in a debug overlay so designers see exactly which states this FSM owns.
do -- SimpleState:getStates
  local sm = lurek.patterns.newSimpleState()
  sm:addState("a", {}); sm:addState("b", {}); sm:addState("c", {})
  for _, name in ipairs(sm:getStates()) do print("state:" .. name) end
end

--@api-stub: LSimpleState:clearAll
-- Removes all states and callbacks from this state machine.
-- Call on scene unload so closures captured by enter/exit/update are released.
do -- SimpleState:clearAll
  local sm = lurek.patterns.newSimpleState()
  sm:addState("x", {})
  sm:clearAll()
  print("states left=" .. #sm:getStates())
end

--@api-stub: LBlackboard:set
-- Sets a fact on the blackboard. Accepts boolean, number, or string values.
-- Setting nil clears the key; tables/userdata raise an error so keep the schema flat.
do -- Blackboard:set
  local bb = lurek.patterns.newBlackboard()
  bb:set("hp", 100)
  bb:set("name", "Aria")
  bb:set("alarm", true)
  print("name=" .. bb:get("name"))
end

--@api-stub: LBlackboard:get
-- Gets a fact from the blackboard. Returns nil if not set.
-- Type-narrow at the call site; a missing key reads as nil so guard with `or` for defaults.
do -- Blackboard:get
  local bb = lurek.patterns.newBlackboard()
  bb:set("ammo", 12)
  local ammo = bb:get("ammo") or 0
  if ammo <= 0 then print("reload!") else print("ammo=" .. ammo) end
end

--@api-stub: LBlackboard:has
-- Returns true when the key has a non-nil value.
-- Distinguishes â€śnever setâ€ť from â€śset to nilâ€ť when you need that semantics for AI conditions.
do -- Blackboard:has
  local bb = lurek.patterns.newBlackboard()
  bb:set("seen_player", true)
  if bb:has("seen_player") then print("AI is alerted") end
end

--@api-stub: LBlackboard:clear
-- Removes a fact from the blackboard.
-- Use to reset transient AI state (target, last_seen_at) on level transitions.
do -- Blackboard:clear
  local bb = lurek.patterns.newBlackboard()
  bb:set("target", "player")
  bb:clear("target")
  print("target set=" .. tostring(bb:has("target")))
end

--@api-stub: LBlackboard:keys
-- Returns all set fact keys as a table.
-- Iterate with ipairs to dump the AI world state for debug overlays or save snapshots.
do -- Blackboard:keys
  local bb = lurek.patterns.newBlackboard()
  bb:set("hp", 50); bb:set("mode", "patrol")
  for _, k in ipairs(bb:keys()) do print(k .. "=" .. tostring(bb:get(k))) end
end

--@api-stub: LBlackboard:watch
-- Subscribes to changes on a specific key (or "*" for all changes).
-- Capture the returned id and pass to unwatch on teardown; pass â€ś*â€ť as the key to log every write.
do -- Blackboard:watch
  local bb = lurek.patterns.newBlackboard()
  local id = bb:watch("hp", function(k, v) print(k .. " changed to " .. v) end)
  bb:set("hp", 75)
  bb:unwatch(id)
end

--@api-stub: LBlackboard:unwatch
-- Removes a watcher subscription by id.
-- Always call from the same scope that set up watch() so closures donâ€™t survive a scene unload.
do -- Blackboard:unwatch
  local bb = lurek.patterns.newBlackboard()
  local id = bb:watch("*", function(k) print("write to " .. k) end)
  bb:set("debug", "on")
  bb:unwatch(id)
end

--@api-stub: LBlackboard:getRevision
-- Returns the monotonic revision counter (incremented on every write).
-- Use to skip expensive recomputation â€” cache the rev seen and only recompute when it bumps.
do -- Blackboard:getRevision
  local bb = lurek.patterns.newBlackboard()
  local last_rev = bb:getRevision()
  bb:set("k", 1)
  if bb:getRevision() ~= last_rev then print("dirty") end
end

--@api-stub: LBlackboard:snapshot
-- Returns all facts as a flat keyâ†’value table.
-- Use for save files or to diff state across frames; only scalar values are emitted.
do -- Blackboard:snapshot
  local bb = lurek.patterns.newBlackboard()
  bb:set("hp", 80); bb:set("mode", "alert")
  local snap = bb:snapshot()
  for k, v in pairs(snap) do print(k .. "=" .. tostring(v)) end
end

--@api-stub: LBlackboard:clearAll
-- Clears all facts from the blackboard.
-- Call between integration test cases or when starting a fresh game to reset the world fact store.
do -- Blackboard:clearAll
  local bb = lurek.patterns.newBlackboard()
  bb:set("hp", 100)
  bb:clearAll()
  print("keys after clear=" .. #bb:keys())
end

--@api-stub: LObserver:set
-- Sets a property value and fires subscribed watchers.
-- Lighter than Blackboard â€” accepts any Lua value; useful for HUD-bound reactive properties.
do -- Observer:set
  local o = lurek.patterns.newObserver("player")
  o:subscribe("hp", function(_, v) print("hud hp=" .. v) end)
  o:set("hp", 100)
  o:set("hp", 75)
end

--@api-stub: LObserver:get
-- Gets a property value, or nil if not set.
-- Pair with set() for one-way data binding from game state to HUD widgets.
do -- Observer:get
  local o = lurek.patterns.newObserver()
  o:set("score", 1500)
  local s = o:get("score") or 0
  print("score now " .. s)
end

--@api-stub: LObserver:subscribe
-- Subscribes to changes on a property key (or "*" for all).
-- Pass once=true to receive a single notification then auto-unsubscribe â€” great for one-shot tutorial triggers.
do -- Observer:subscribe
  local o = lurek.patterns.newObserver()
  local id = o:subscribe("*", function(k, v) print("write " .. k .. "=" .. tostring(v)) end)
  o:set("a", 1); o:set("b", "two")
  o:unsubscribe(id)
end

--@api-stub: LObserver:unsubscribe
-- Removes a subscription by id.
-- Tear down all per-scene subscriptions in lurek.quit or scene_exit so callbacks donâ€™t leak.
do -- Observer:unsubscribe
  local o = lurek.patterns.newObserver()
  local id = o:subscribe("k", function() end)
  o:unsubscribe(id)
  print("subs left=" .. o:getCount())
end

--@api-stub: LObserver:getCount
-- Returns the total number of active subscriptions.
-- Show in a debug HUD to spot reactive subscription leaks after hot-reloading scripts.
do -- Observer:getCount
  local o = lurek.patterns.newObserver()
  o:subscribe("a", function() end)
  o:subscribe("b", function() end)
  print("active subs=" .. o:getCount())
end

--@api-stub: LThrottle:onFire
-- Sets the callback invoked when the throttle fires.
-- Calling onFire again replaces the previous callback; pass a no-op to disable without dropping the throttle.
do -- Throttle:onFire
  local t = lurek.patterns.newThrottle(0.5)
  t:onFire(function() print("tick at " .. os.time()) end)
  function lurek.process(dt) t:update(dt) end
end

--@api-stub: LThrottle:update
-- Advances the timer by dt seconds; fires the callback if the interval elapsed.
-- Returns true on the frame the callback fires; call from lurek.process so timing follows the engine clock.
do -- Throttle:update
  local t = lurek.patterns.newThrottle(0.25)
  t:onFire(function() print("autosave check") end)
  function lurek.process(dt) if t:update(dt) then print("just fired") end end
end

--@api-stub: LThrottle:reset
-- Resets the elapsed counter without firing.
-- Use after a manual save or scene change so the next throttled save isnâ€™t triggered too soon.
do -- Throttle:reset
  local t = lurek.patterns.newThrottle(1.0)
  t:onFire(function() end)
  t:update(0.7)
  t:reset()
  print("progress after reset=" .. t:getProgress())
end

--@api-stub: LThrottle:getProgress
-- Returns the normalised progress through the current interval [0, 1].
-- Drive cooldown ring HUDs (1 - progress) so the player sees how soon the action becomes available.
do -- Throttle:getProgress
  local t = lurek.patterns.newThrottle(2.0)
  t:onFire(function() end)
  t:update(0.5)
  local pct = math.floor(t:getProgress() * 100)
  print("cooldown filled " .. pct .. "%")
end

--@api-stub: LThrottle:getFireCount
-- Returns the total number of times this throttle has fired.
-- Use in tests and analytics to verify the throttle ran exactly N times across a scenario.
do -- Throttle:getFireCount
  local t = lurek.patterns.newThrottle(0.1)
  t:onFire(function() end)
  for i = 1, 5 do t:update(0.1) end
  print("fires=" .. t:getFireCount())
end

--@api-stub: LThrottle:setEnabled
-- Enables or disables the throttle.
-- Disable while the player is on the menu so background timers donâ€™t accumulate fires.
do -- Throttle:setEnabled
  local t = lurek.patterns.newThrottle(0.5)
  t:onFire(function() print("fire") end)
  t:setEnabled(false)
  t:update(1.0)  -- no fire because disabled
  print("fires=" .. t:getFireCount())
end

--@api-stub: LDebounce:onFire
-- Sets the callback invoked when the debounce fires.
-- Replace the callback any time â€” the most recent registration wins on the next idle expiration.
do -- Debounce:onFire
  local d = lurek.patterns.newDebounce(0.3)
  d:onFire(function() print("settled") end)
  d:trigger()
  function lurek.process(dt) d:update(dt) end
end

--@api-stub: LDebounce:trigger
-- Records an input event, resetting the idle timer.
-- Call on every keystroke / drag tick â€” the callback only fires once the stream has been idle for `wait` seconds.
do -- Debounce:trigger
  local d = lurek.patterns.newDebounce(0.5)
  d:onFire(function() print("autosave!") end)
  d:trigger()
  d:trigger()
  print("pending=" .. tostring(d:isPending()))
end

--@api-stub: LDebounce:update
-- Advances the idle timer by dt seconds; fires the callback if idle wait expired.
-- Returns true on the frame the callback runs; mirror Throttle:update by calling from lurek.process.
do -- Debounce:update
  local d = lurek.patterns.newDebounce(0.4)
  d:onFire(function() print("done typing") end)
  d:trigger()
  function lurek.process(dt) if d:update(dt) then print("fired") end end
end

--@api-stub: LDebounce:cancel
-- Cancels the pending trigger without firing.
-- Call when the user explicitly aborts (e.g. closes the dialog) so the deferred action never runs.
do -- Debounce:cancel
  local d = lurek.patterns.newDebounce(1.0)
  d:onFire(function() print("commit") end)
  d:trigger()
  d:cancel()
  print("pending after cancel=" .. tostring(d:isPending()))
end

--@api-stub: LDebounce:isPending
-- Returns true when a trigger is pending.
-- Use in HUD (â€śsavingâ€¦â€ť spinner) to indicate the debounced action is queued but not yet committed.
do -- Debounce:isPending
  local d = lurek.patterns.newDebounce(0.6)
  d:onFire(function() end)
  d:trigger()
  if d:isPending() then print("waiting for idle") end
end

--@api-stub: LDebounce:getFireCount
-- Returns the total number of times this debounce has fired.
-- Track in tests to confirm a noisy stream collapses into the expected single fire per quiet period.
do -- Debounce:getFireCount
  local d = lurek.patterns.newDebounce(0.1)
  d:onFire(function() end)
  d:trigger()
  d:update(0.2)
  print("fires=" .. d:getFireCount())
end

--@api-stub: LPriorityQueue:push
-- Inserts an item with a priority. Higher priorities are dequeued first.
-- Pass an optional label to make queue dumps human-readable; ties keep insertion order (stable).
do -- PriorityQueue:push
  local pq = lurek.patterns.newPriorityQueue("ai")
  pq:push(10, { kind = "patrol" }, "low")
  pq:push(50, { kind = "attack" }, "urgent")
  pq:push(20, { kind = "talk" }, "med")
  print("queued=" .. pq:len())
end

--@api-stub: LPriorityQueue:pop
-- Removes and returns the highest-priority item, or nil if empty.
-- Always nil-check; used in main loop tickers to drain ready jobs each frame.
do -- PriorityQueue:pop
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "low"); pq:push(99, "high")
  local job = pq:pop()
  if job then print("running " .. job) end
end

--@api-stub: LPriorityQueue:peek
-- Returns the highest-priority item without removing it, or nil if empty.
-- Use to glance at the next job (HUD: â€śnext: rebuild lightingâ€ť) without consuming it.
do -- PriorityQueue:peek
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(5, "build"); pq:push(20, "render")
  local next_job = pq:peek()
  if next_job then print("next: " .. next_job) end
end

--@api-stub: LPriorityQueue:len
-- Returns the number of items in the queue.
-- Use for backpressure: if len exceeds a threshold, defer enqueuing more low-priority work.
do -- PriorityQueue:len
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "a"); pq:push(2, "b"); pq:push(3, "c")
  if pq:len() > 100 then print("queue saturated") end
  print("size=" .. pq:len())
end

--@api-stub: LPriorityQueue:isEmpty
-- Returns true when the queue has no items.
-- Use as the loop guard: `while not pq:isEmpty() do local job = pq:pop() ... end`.
do -- PriorityQueue:isEmpty
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "task")
  while not pq:isEmpty() do print("processing " .. pq:pop()) end
end

--@api-stub: LPriorityQueue:clearAll
-- Removes all items from the queue.
-- Use on scene/level reset to drop pending jobs that no longer apply to the new context.
do -- PriorityQueue:clearAll
  local pq = lurek.patterns.newPriorityQueue()
  pq:push(1, "x"); pq:push(2, "y")
  pq:clearAll()
  print("after clear len=" .. pq:len())
end

--@api-stub: LRing:push
-- Pushes a value (number or string) with an optional tag. Overwrites oldest on overflow.
-- Tag entries by source (â€śframeâ€ť, â€śnetâ€ť) so toArray dumps stay readable.
do -- Ring:push
  local r = lurek.patterns.newRing(8)
  for i = 1, 10 do r:push(i * 1.5, "sample") end
  print("len=" .. r:len() .. " full=" .. tostring(r:isFull()))
end

--@api-stub: LRing:latest
-- Returns the most recently pushed entry, or nil.
-- Returns a table with id/tag/value/text fields; use for last-event HUDs (last damage, last error).
do -- Ring:latest
  local r = lurek.patterns.newRing(4)
  r:push("hello", "msg")
  r:push("world", "msg")
  local last = r:latest()
  if last then print("last text=" .. last.text) end
end

--@api-stub: LRing:toArray
-- Returns all entries (oldest first) as an array of {id, tag, value?, text?} tables.
-- Iterate with ipairs to render a scrolling history view (chat, damage log, FPS graph).
do -- Ring:toArray
  local r = lurek.patterns.newRing(4)
  r:push(60, "fps"); r:push(58, "fps"); r:push(61, "fps")
  for _, e in ipairs(r:toArray()) do print(e.tag .. "=" .. e.value) end
end

--@api-stub: LRing:sum
-- Returns the sum of all numeric values in the ring.
-- Combine with len() to compute custom stats (median is not provided; use sum/len for mean).
do -- Ring:sum
  local r = lurek.patterns.newRing(16)
  for i = 1, 10 do r:push(i * 0.1, "lat") end
  print("total latency=" .. r:sum() .. "s")
end

--@api-stub: LRing:average
-- Returns the average of all numeric values, or 0 if empty.
-- Cheaper than computing on the Lua side; perfect for rolling FPS or ms-per-frame readouts.
do -- Ring:average
  local r = lurek.patterns.newRing(60)
  for i = 1, 60 do r:push(58 + (i % 4), "fps") end
  print("avg fps=" .. string.format("%.1f", r:average()))
end

--@api-stub: LRing:len
-- Returns the number of entries currently in the ring.
-- Use to check how much history has accumulated before computing statistics.
do -- Ring:len
  local r = lurek.patterns.newRing(10)
  r:push(1, "x"); r:push(2, "x"); r:push(3, "x")
  if r:len() >= 3 then print("got enough samples") end
end

--@api-stub: LRing:isFull
-- Returns true when the ring is at capacity.
-- Use to avoid recomputing rolling averages until the ring has wrapped at least once.
do -- Ring:isFull
  local r = lurek.patterns.newRing(4)
  for i = 1, 4 do r:push(i, "v") end
  if r:isFull() then print("warm: avg=" .. r:average()) end
end

--@api-stub: LRing:clear
-- Removes all entries from the ring.
-- Call on level transition so the new sceneâ€™s rolling stats start clean.
do -- Ring:clear
  local r = lurek.patterns.newRing(8)
  r:push(10, "x"); r:push(20, "x")
  r:clear()
  print("len after clear=" .. r:len())
end

--@api-stub: LFunnel:onFlush
-- Sets a callback invoked when the funnel flushes. Receives a table of {tag, value} entries.
-- Set this once at boot; the callback receives the full batch so handle bulk inserts (DB writes, network sends) here.
do -- Funnel:onFlush
  local f = lurek.patterns.newFunnel(1.0, 0)
  f:onFlush(function(batch) print("flushed " .. #batch .. " events") end)
  function lurek.process(dt) f:update(dt) end
end

--@api-stub: LFunnel:push
-- Adds an event to the funnel. Immediately flushes if max_entries reached or window is 0.
-- Pass a numeric value alongside the tag so onFlush sees per-event metrics, not just counts.
do -- Funnel:push
  local f = lurek.patterns.newFunnel(0, 4)
  f:onFlush(function(b) print("batch=" .. #b) end)
  f:push("kill", 1); f:push("kill", 1); f:push("kill", 1); f:push("kill", 1)
  print("pending=" .. f:pendingCount())
end

--@api-stub: LFunnel:update
-- Advances the window timer by dt seconds; flushes when window expires.
-- Returns true on the frame the flush happens; call from lurek.process so timing tracks the engine clock.
do -- Funnel:update
  local f = lurek.patterns.newFunnel(0.5, 0)
  f:onFlush(function(b) print("auto flush " .. #b) end)
  f:push("hit", 5)
  function lurek.process(dt) if f:update(dt) then print("fired") end end
end

--@api-stub: LFunnel:flush
-- Manually flushes all pending entries, invoking the onFlush callback.
-- Call on app quit or scene change so no buffered events get dropped without delivery.
do -- Funnel:flush
  local f = lurek.patterns.newFunnel(60.0, 0)
  f:onFlush(function(b) print("manual flush " .. #b) end)
  f:push("crash", 1)
  f:flush()
end

--@api-stub: LFunnel:discard
-- Discards all buffered entries without flushing.
-- Use when an error invalidates the buffered batch (e.g. session became invalid mid-aggregation).
do -- Funnel:discard
  local f = lurek.patterns.newFunnel(2.0, 0)
  f:onFlush(function() end)
  f:push("a", 1); f:push("b", 2)
  f:discard()
  print("pending after discard=" .. f:pendingCount())
end

--@api-stub: LFunnel:pendingCount
-- Returns the number of buffered entries not yet flushed.
-- Display in a debug overlay to monitor backpressure on analytics or networking pipelines.
do -- Funnel:pendingCount
  local f = lurek.patterns.newFunnel(5.0, 0)
  f:onFlush(function() end)
  f:push("x", 1); f:push("y", 2); f:push("z", 3)
  print("buffered=" .. f:pendingCount())
end

--@api-stub: LFunnel:getFlushCount
-- Returns the total number of flushes performed.
-- Useful in tests and metrics: assert that an N-second run produced exactly N/window flushes.
do -- Funnel:getFlushCount
  local f = lurek.patterns.newFunnel(0, 1)
  f:onFlush(function() end)
  for i = 1, 3 do f:push("e", i) end
  print("flushes=" .. f:getFlushCount())
end

--@api-stub: LRelationshipManager:defineType
-- Defines a relationship type with ordered levels.
-- Pass levels in escalation order (â€śhostileâ€ť â†’ â€śallyâ€ť) and an optional default applied to new pairs.
do -- RelationshipManager:defineType
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("faction", { "hostile", "neutral", "ally" }, "neutral")
  rm:defineType("trust", { "low", "med", "high" }, "low")
  print("types=" .. #rm:typeNames())
end

--@api-stub: LRelationshipManager:removeType
-- Removes a relationship type definition.
-- Use during hot-reload to drop a stale rule set before re-defining it from updated data.
do -- RelationshipManager:removeType
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("temp", { "a", "b" }, "a")
  rm:removeType("temp")
  print("types left=" .. #rm:typeNames())
end

--@api-stub: LRelationshipManager:typeNames
-- Returns all defined relationship type names.
-- Iterate to render a debug panel showing every diplomatic axis the game tracks.
do -- RelationshipManager:typeNames
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("diplomacy", { "war", "peace" }, "peace")
  rm:defineType("trade", { "off", "on" }, "off")
  for _, t in ipairs(rm:typeNames()) do print("type:" .. t) end
end

--@api-stub: LRelationshipManager:setValue
-- Sets the numeric relationship value between two entities.
-- Pair entity ids are unordered: setValue(a,b,v) is the same edge as setValue(b,a,v).
do -- RelationshipManager:setValue
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(101, 202, 35)
  print("v=" .. rm:getValue(101, 202))
  print("pairs=" .. rm:pairCount())
end

--@api-stub: LRelationshipManager:getValue
-- Returns the numeric relationship value between two entities (default 0.0).
-- Use as an input to AI utility scoring or shop price modifiers.
do -- RelationshipManager:getValue
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(1, 2, 50)
  local price_mult = 1.0 - rm:getValue(1, 2) * 0.005
  print("multiplier=" .. price_mult)
end

--@api-stub: LRelationshipManager:adjustValue
-- Adjusts the numeric relationship value by a delta.
-- Drive from gameplay events: kill -> -50, gift -> +20; clamp on your side if you need bounds.
do -- RelationshipManager:adjustValue
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(1, 2, 0)
  rm:adjustValue(1, 2, 25)  -- gift accepted
  rm:adjustValue(1, 2, -10) -- minor offence
  print("net=" .. rm:getValue(1, 2))
end

--@api-stub: LRelationshipManager:setLevel
-- Sets a named level for a typed relationship between two entities.
-- Returns false when the type or level isnâ€™t in the definition; useful as a validation guard.
do -- RelationshipManager:setLevel
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("faction", { "hostile", "neutral", "ally" }, "neutral")
  local ok = rm:setLevel(1, 2, "faction", "ally")
  print("set ok=" .. tostring(ok))
end

--@api-stub: LRelationshipManager:getLevel
-- Returns the named level for a typed relationship, or nil.
-- Branch AI behaviour on the level string (â€śhostileâ€ť -> attack, â€śallyâ€ť -> defend).
do -- RelationshipManager:getLevel
  local rm = lurek.patterns.newRelationshipManager()
  rm:defineType("faction", { "hostile", "ally" }, "hostile")
  rm:setLevel(1, 2, "faction", "ally")
  local lvl = rm:getLevel(1, 2, "faction")
  if lvl == "ally" then print("hold fire") end
end

--@api-stub: LRelationshipManager:removePair
-- Removes all relationship data between two entities.
-- Call when an entity dies or leaves the simulation so stale pairs donâ€™t accumulate.
do -- RelationshipManager:removePair
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(1, 2, 50)
  rm:removePair(1, 2)
  print("pairs=" .. rm:pairCount())
end

--@api-stub: LRelationshipManager:pairCount
-- Returns the total number of stored relationship pairs.
-- Watch in a debug HUD; large worlds with O(nÂ˛) growth become a memory red flag.
do -- RelationshipManager:pairCount
  local rm = lurek.patterns.newRelationshipManager()
  rm:setValue(1, 2, 10); rm:setValue(2, 3, -10)
  if rm:pairCount() > 10000 then print("WARN large relationship graph") end
  print("pairs=" .. rm:pairCount())
end

--@api-stub: LMediator:on
-- Registers a handler callback on a channel; returns handler ID.
-- Capture the id and pass to off() for targeted unregister; one channel can have many handlers.
do -- Mediator:on
  local m = lurek.patterns.newMediator()
  local id = m:on("net", function(msg) print("net msg: " .. msg) end)
  m:send("net", "hello")
  m:off("net", id)
end

--@api-stub: LMediator:off
-- Unregisters a handler by ID.
-- Both the channel name and the id are required; calling off on a missing id is a silent no-op.
do -- Mediator:off
  local m = lurek.patterns.newMediator()
  local id = m:on("ui", function() print("ui tick") end)
  m:off("ui", id)
  print("handlers=" .. m:handlerCount("ui"))
end

--@api-stub: LMediator:send
-- Dispatches a message to all handlers on a channel.
-- Extra args after the channel name are forwarded to every handler verbatim, just like EventBus.
do -- Mediator:send
  local m = lurek.patterns.newMediator()
  m:on("damage", function(amount, src) print(src .. " hit for " .. amount) end)
  m:send("damage", 12, "spike_trap")
end

--@api-stub: LMediator:broadcast
-- Dispatches a message to all handlers across all channels.
-- Use sparingly â€” ideal for global signals like â€śpauseâ€ť or â€śsaveâ€ť that every system listens for.
do -- Mediator:broadcast
  local m = lurek.patterns.newMediator()
  m:on("audio", function(s) print("audio got " .. s) end)
  m:on("video", function(s) print("video got " .. s) end)
  m:broadcast("pause")
end

--@api-stub: LMediator:handlerCount
-- Returns the number of handlers on a channel.
-- Useful in tests to assert subscription bookkeeping; also reveals listener leaks after hot-reload.
do -- Mediator:handlerCount
  local m = lurek.patterns.newMediator()
  m:on("save", function() end)
  m:on("save", function() end)
  print("save handlers=" .. m:handlerCount("save"))
end

--@api-stub: LMediator:channels
-- Returns all registered channel names.
-- Iterate to render a debug overlay listing every active topic on the mediator.
do -- Mediator:channels
  local m = lurek.patterns.newMediator()
  m:on("a", function() end); m:on("b", function() end)
  for _, c in ipairs(m:channels()) do print("ch:" .. c) end
end

--@api-stub: LMediator:removeChannel
-- Removes a channel and all its handlers.
-- Use when a feature module unloads; cheaper than walking handlers and calling off() one by one.
do -- Mediator:removeChannel
  local m = lurek.patterns.newMediator()
  m:on("temp", function() end)
  m:removeChannel("temp")
  print("temp handlers=" .. m:handlerCount("temp"))
end

--@api-stub: LMediator:clear
-- Removes all channels and handlers.
-- Call on full app teardown so no closures captured by handlers survive into the next session.
do -- Mediator:clear
  local m = lurek.patterns.newMediator()
  m:on("x", function() end); m:on("y", function() end)
  m:clear()
  print("channels left=" .. #m:channels())
end

--@api-stub: LStrategy:register
-- Registers a named strategy function.
-- Wire all algorithms at boot; later set() picks the active one by name without re-registration.
do -- Strategy:register
  local s = lurek.patterns.newStrategy()
  s:register("euclid", function(ax, ay, bx, by) return math.sqrt((ax-bx)^2 + (ay-by)^2) end)
  s:register("manhattan", function(ax, ay, bx, by) return math.abs(ax-bx) + math.abs(ay-by) end)
  print("strategies=" .. #s:names())
end

--@api-stub: LStrategy:set
-- Sets the active strategy by name. Returns false if not registered.
-- Always check the boolean return when the name comes from config or save data.
do -- Strategy:set
  local s = lurek.patterns.newStrategy()
  s:register("simple", function(x) return x * 2 end)
  local ok = s:set("simple")
  if not ok then print("strategy missing!") end
end

--@api-stub: LStrategy:execute
-- Calls the currently active strategy function with the given arguments.
-- Forwards every arg to the active strategy; returns whatever the strategy returns (including multiple values).
do -- Strategy:execute
  local s = lurek.patterns.newStrategy()
  s:register("crit", function(atk, def) return atk * 2 - def end)
  s:set("crit")
  local dmg = s:execute(20, 5)
  print("dmg=" .. dmg)
end

--@api-stub: LStrategy:getCurrent
-- Returns the name of the active strategy, or nil.
-- Display in a debug HUD or settings dropdown so the player sees the current AI/damage formula.
do -- Strategy:getCurrent
  local s = lurek.patterns.newStrategy()
  s:register("normal", function(x) return x end)
  s:set("normal")
  local name = s:getCurrent()
  if name then print("active strategy: " .. name) end
end

--@api-stub: LStrategy:has
-- Returns true if a strategy with this name is registered.
-- Guard config-driven set() calls so a typo in TOML doesnâ€™t crash on the first execute().
do -- Strategy:has
  local s = lurek.patterns.newStrategy()
  s:register("legacy", function() end)
  if s:has("legacy") then s:set("legacy") end
end

--@api-stub: LStrategy:remove
-- Removes a strategy by name.
-- Use when retiring an old algorithm during hot-reload; returns true if the strategy was actually removed.
do -- Strategy:remove
  local s = lurek.patterns.newStrategy()
  s:register("old", function() end)
  local removed = s:remove("old")
  print("removed=" .. tostring(removed))
end

--@api-stub: LStrategy:names
-- Returns all registered strategy names.
-- Render in option menus so the player can pick the active variant by name at runtime.
do -- Strategy:names
  local s = lurek.patterns.newStrategy()
  s:register("a", function() end); s:register("b", function() end)
  for _, n in ipairs(s:names()) do print("strat:" .. n) end
end

--@api-stub: LStrategy:clear
-- Removes all strategies and clears the active selection.
-- Use in tests to reset the registry between cases without rebuilding the Strategy object.
do -- Strategy:clear
  local s = lurek.patterns.newStrategy()
  s:register("x", function() end)
  s:clear()
  print("strategies=" .. #s:names())
end

--@api-stub: LStack:push
-- Pushes a value onto the stack. Returns false if capacity is full.
-- Always check the boolean return when the stack has a capacity cap; full stacks reject silently otherwise.
do -- Stack:push
  local s = lurek.patterns.newStack(4)
  s:push("scene_main")
  s:push("scene_options")
  local ok = s:push("scene_extra")
  print("ok=" .. tostring(ok) .. " depth=" .. s:len())
end

--@api-stub: LStack:pop
-- Removes and returns the top value, or nil if empty.
-- Drives back-button navigation: pop the current scene to return to the previous one.
do -- Stack:pop
  local s = lurek.patterns.newStack(0)
  s:push("menu"); s:push("game")
  local top = s:pop()
  print("popped " .. top .. ", new top=" .. (s:peek() or "<empty>"))
end

--@api-stub: LStack:peek
-- Returns the top value without removing it, or nil if empty.
-- Use to inspect the active scene/screen without disturbing the navigation history.
do -- Stack:peek
  local s = lurek.patterns.newStack(0)
  s:push("hud"); s:push("dialog")
  local top = s:peek()
  if top == "dialog" then print("dialog is showing") end
end

--@api-stub: LStack:len
-- Returns the number of items on the stack.
-- Show as a HUD breadcrumb depth (â€śback x3â€ť) so users know how deep their navigation goes.
do -- Stack:len
  local s = lurek.patterns.newStack(0)
  s:push("a"); s:push("b"); s:push("c")
  print("depth=" .. s:len())
end

--@api-stub: LStack:isEmpty
-- Returns true if the stack is empty.
-- Use as a back-action guard: if isEmpty(), exit to the title instead of popping.
do -- Stack:isEmpty
  local s = lurek.patterns.newStack(0)
  s:push("only")
  s:pop()
  if s:isEmpty() then print("at root â€” quit to menu") end
end

--@api-stub: LStack:isFull
-- Returns true if the stack is at its capacity limit.
-- Useful when sizing modal dialog stacks; show â€śtoo many dialogsâ€ť before pushing.
do -- Stack:isFull
  local s = lurek.patterns.newStack(2)
  s:push("a"); s:push("b")
  if s:isFull() then print("dialog stack saturated") end
end

--@api-stub: LStack:clear
-- Removes all values from the stack.
-- Call on hard scene reset so leftover navigation history doesnâ€™t survive.
do -- Stack:clear
  local s = lurek.patterns.newStack(0)
  s:push("a"); s:push("b")
  s:clear()
  print("len after clear=" .. s:len())
end

--@api-stub: LStack:toArray
-- Returns all items as a Lua table (bottom to top).
-- Iterate with ipairs to render a breadcrumb trail (Main > Options > Audio).
do -- Stack:toArray
  local s = lurek.patterns.newStack(0)
  s:push("Main"); s:push("Options"); s:push("Audio")
  for i, v in ipairs(s:toArray()) do print(i .. ": " .. v) end
end

--@api-stub: LQueue:enqueue
-- Adds a value to the back of the queue. Returns false if capacity is full.
-- Capacity 0 means unbounded; with a cap, callers should branch on the boolean to drop or retry.
do -- Queue:enqueue
  local q = lurek.patterns.newQueue(0)
  q:enqueue("packet_a"); q:enqueue("packet_b")
  local ok = q:enqueue("packet_c")
  print("ok=" .. tostring(ok) .. " size=" .. q:len())
end

--@api-stub: LQueue:dequeue
-- Removes and returns the front value, or nil if empty.
-- Drain in batches inside lurek.process so back-pressured systems donâ€™t starve the frame.
do -- Queue:dequeue
  local q = lurek.patterns.newQueue(0)
  q:enqueue("msg1"); q:enqueue("msg2")
  local m = q:dequeue()
  if m then print("processed " .. m) end
end

--@api-stub: LQueue:front
-- Returns the front value without removing it, or nil if empty.
-- Use to peek at the next packet for prioritisation logic without consuming it.
do -- Queue:front
  local q = lurek.patterns.newQueue(0)
  q:enqueue("first"); q:enqueue("second")
  local f = q:front()
  if f then print("next is " .. f) end
end

--@api-stub: LQueue:len
-- Returns the number of items in the queue.
-- Show in a network or chat HUD to indicate how many messages are still queued for processing.
do -- Queue:len
  local q = lurek.patterns.newQueue(0)
  for i = 1, 4 do q:enqueue("e" .. i) end
  print("queue size=" .. q:len())
end

--@api-stub: LQueue:isEmpty
-- Returns true if the queue is empty.
-- Use as the drain loop guard: while not q:isEmpty() do handle(q:dequeue()) end.
do -- Queue:isEmpty
  local q = lurek.patterns.newQueue(0)
  q:enqueue("only")
  while not q:isEmpty() do print("got " .. q:dequeue()) end
end

--@api-stub: LQueue:isFull
-- Returns true if the queue is at its capacity limit.
-- Use to apply backpressure: drop or coalesce inputs once the queue is saturated.
do -- Queue:isFull
  local q = lurek.patterns.newQueue(2)
  q:enqueue("a"); q:enqueue("b")
  if q:isFull() then print("dropping new inputs") end
end

--@api-stub: LQueue:clear
-- Removes all values from the queue.
-- Call on disconnect / scene change so stale messages from the previous session donâ€™t process.
do -- Queue:clear
  local q = lurek.patterns.newQueue(0)
  q:enqueue("x"); q:enqueue("y")
  q:clear()
  print("size after clear=" .. q:len())
end

--@api-stub: LQueue:toArray
-- Returns all items as a Lua table (front to back).
-- Iterate with ipairs to render the queue contents in a debug HUD without consuming them.
do -- Queue:toArray
  local q = lurek.patterns.newQueue(0)
  q:enqueue("a"); q:enqueue("b"); q:enqueue("c")
  for i, v in ipairs(q:toArray()) do print(i .. ": " .. v) end
end

--@api-stub: List:add
-- Appends a value to the end of the list.
-- Mirrors table.insert(); use this when you want enforced 1-indexed semantics across systems.
do -- List:add
  local l = lurek.patterns.newList()
  l:add("sword"); l:add("shield"); l:add("potion")
  print("inventory size=" .. l:len())
end

--@api-stub: List:get
-- Returns the value at a 1-based index, or nil.
-- Returns nil for index 0 or beyond len; safer than raw t[i] when indexes come from user input.
do -- List:get
  local l = lurek.patterns.newList()
  l:add("apple"); l:add("bread")
  local item = l:get(1)
  if item then print("first: " .. item) end
end

--@api-stub: List:set
-- Replaces the value at a 1-based index.
-- Raises if index is 0 or > len; only call after a get() / len() check or on indices you control.
do -- List:set
  local l = lurek.patterns.newList()
  l:add("placeholder")
  l:set(1, "real_value")
  print("now: " .. l:get(1))
end

--@api-stub: List:remove
-- Removes and returns the value at a 1-based index.
-- Returns nil for out-of-range indices; shifts remaining items left so use len() carefully in loops.
do -- List:remove
  local l = lurek.patterns.newList()
  l:add("a"); l:add("b"); l:add("c")
  local removed = l:remove(2)
  print("removed " .. removed .. ", remaining=" .. l:len())
end

--@api-stub: List:len
-- Returns the number of items in the list.
-- Use as the standard 1..len iteration bound: for i = 1, list:len() do ... end.
do -- List:len
  local l = lurek.patterns.newList()
  for i = 1, 5 do l:add("item_" .. i) end
  print("count=" .. l:len())
end

--@api-stub: List:isEmpty
-- Returns true if the list is empty.
-- Cheaper and clearer than `list:len() == 0` for guard clauses in UI code.
do -- List:isEmpty
  local l = lurek.patterns.newList()
  if l:isEmpty() then print("inventory empty") end
  l:add("ring")
  print("after add empty=" .. tostring(l:isEmpty()))
end

--@api-stub: List:contains
-- Returns true if the list contains a value equal to the given Lua value (string/number/boolean).
-- Linear scan â€” prefer Set for hot membership checks; use this only for small UI lists.
do -- List:contains
  local l = lurek.patterns.newList()
  l:add("key"); l:add("map"); l:add("torch")
  if l:contains("key") then print("door can be opened") end
end

--@api-stub: List:clear
-- Removes all values from the list.
-- Call on inventory reset or scene unload to drop everything in one call.
do -- List:clear
  local l = lurek.patterns.newList()
  l:add("x"); l:add("y")
  l:clear()
  print("len after clear=" .. l:len())
end

--@api-stub: List:toArray
-- Returns all items as a Lua table.
-- Use when handing the list off to APIs (rendering, save) that expect a plain Lua table.
do -- List:toArray
  local l = lurek.patterns.newList()
  l:add("a"); l:add("b"); l:add("c")
  for i, v in ipairs(l:toArray()) do print(i .. "=" .. v) end
end

--@api-stub: LSet:add
-- Adds a string key to the set. Returns true if it was not already present.
-- Use the boolean return to detect first-time pickups (achievements, tutorial flags).
do -- Set:add
  local s = lurek.patterns.newSet()
  local was_new = s:add("collected_gem")
  if was_new then print("first gem!") end
  s:add("collected_gem")  -- returns false on second add
end

--@api-stub: LSet:remove
-- Removes a key from the set. Returns true if it was present.
-- Use the return value to confirm the removal actually happened (prevents double-revoke bugs).
do -- Set:remove
  local s = lurek.patterns.newSet()
  s:add("buff_speed")
  local existed = s:remove("buff_speed")
  print("removed=" .. tostring(existed) .. " size=" .. s:len())
end

--@api-stub: LSet:has
-- Returns true if the key is in the set.
-- Cheaper than List:contains for hot membership checks (frame-by-frame ability checks).
do -- Set:has
  local s = lurek.patterns.newSet()
  s:add("flying")
  if s:has("flying") then print("ignore gravity") end
end

--@api-stub: LSet:len
-- Returns the number of distinct keys in the set.
-- Show in stats screens (â€ś47/100 monsters defeatedâ€ť) by counting unique kill keys.
do -- Set:len
  local s = lurek.patterns.newSet()
  s:add("orc"); s:add("goblin"); s:add("orc")
  print("unique enemies killed=" .. s:len())
end

--@api-stub: LSet:isEmpty
-- Returns true if the set is empty.
-- Cleaner than `len() == 0` when guarding feature unlocks (â€śdoor opens when keys set is non-emptyâ€ť).
do -- Set:isEmpty
  local s = lurek.patterns.newSet()
  if s:isEmpty() then print("no keys yet") end
  s:add("brass_key")
  print("empty=" .. tostring(s:isEmpty()))
end

--@api-stub: LSet:toArray
-- Returns all keys as a Lua table (unordered).
-- Iteration order is undefined â€” sort the resulting array if you need a deterministic display.
do -- Set:toArray
  local s = lurek.patterns.newSet()
  s:add("red"); s:add("green"); s:add("blue")
  for _, k in ipairs(s:toArray()) do print("color:" .. k) end
end

--@api-stub: LSet:clear
-- Removes all keys from the set.
-- Use on level transition to reset transient flags without rebuilding the Set.
do -- Set:clear
  local s = lurek.patterns.newSet()
  s:add("seen_intro"); s:add("opened_chest")
  s:clear()
  print("size=" .. s:len())
end

--@api-stub: LSet:union
-- Returns the union of this set and another as a new Set.
-- Combine â€śinventoryâ€ť + â€śquest itemsâ€ť into one membership check without mutating either source.
do -- Set:union
  local a = lurek.patterns.newSet(); a:add("sword"); a:add("shield")
  local b = lurek.patterns.newSet(); b:add("shield"); b:add("bow")
  local both = a:union(b)
  print("union size=" .. both:len())
end

--@api-stub: LSet:intersection
-- Returns the intersection of this set and another as a new Set.
-- Use to find common items between two collections (player items vs quest required items).
do -- Set:intersection
  local have = lurek.patterns.newSet(); have:add("key"); have:add("map")
  local need = lurek.patterns.newSet(); need:add("map"); need:add("torch")
  local got = have:intersection(need)
  print("matched needs=" .. got:len())
end

-- =============================================================================
-- COVERAGE: 150 uncovered lurek.patterns API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LList methods
-- -----------------------------------------------------------------------------

-- ---- Example: LList:add -----------------------------------------------------
--@api-stub: LList:add
-- Appends a value to the end of the list.
-- Use as a type-safe growable array for game objects or event queues.
do -- LList:add
  local lst = lurek.patterns.newList()
  lst:add("sword")
  lst:add("shield")
  lst:add("potion")
  lurek.log.info("list size=" .. lst:len(), "patterns")
end
--@api-stub: LList:get
-- Returns the value at a 1-based index, or nil.
-- Use to read items without removing them.
do -- LList:get
  local lst = lurek.patterns.newList()
  lst:add("apple")
  lst:add("banana")
  local item = lst:get(2)   -- 1-based index
  lurek.log.info("item[2]=" .. tostring(item), "patterns")
end
--@api-stub: LList:set
-- Replaces the value at a 1-based index.
-- Use to update a specific slot without shifting other items.
do -- LList:set
  local lst = lurek.patterns.newList()
  lst:add("iron_sword")
  lst:add("leather_boots")
  lst:set(1, "mythril_sword")
  lurek.log.info("slot 1=" .. tostring(lst:get(1)), "patterns")
end
--@api-stub: LList:remove
-- Removes and returns the value at a 1-based index.
-- Use to consume items from a queue or unequip from a slot.
do -- LList:remove
  local lst = lurek.patterns.newList()
  lst:add("quest_a")
  lst:add("quest_b")
  lst:add("quest_c")
  local removed = lst:remove(2)
  lurek.log.info("removed=" .. tostring(removed) .. " remaining=" .. lst:len(), "patterns")
end
--@api-stub: LList:len
-- Returns the number of items in the list.
-- Check before iterating to avoid out-of-bounds reads.
do -- LList:len
  local lst = lurek.patterns.newList()
  for i = 1, 5 do lst:add(i * 10) end
  lurek.log.info("list length=" .. lst:len(), "patterns")
end
--@api-stub: LList:isEmpty
-- Returns true if the list is empty.
-- Use as a guard before attempting to read from the list.
do -- LList:isEmpty
  local lst = lurek.patterns.newList()
  lurek.log.info("before add: " .. tostring(lst:isEmpty()), "patterns")
  lst:add("item")
  lurek.log.info("after add: " .. tostring(lst:isEmpty()), "patterns")
end
--@api-stub: LList:contains
-- Returns true if the list contains a value equal to the given Lua value.
-- Use for membership checks on small collections like equipped items.
do -- LList:contains
  local lst = lurek.patterns.newList()
  lst:add("fire")
  lst:add("ice")
  lst:add("thunder")
  lurek.log.info("has fire: " .. tostring(lst:contains("fire")), "patterns")
  lurek.log.info("has wind: " .. tostring(lst:contains("wind")), "patterns")
end
--@api-stub: LList:clear
-- Removes all values from the list.
-- Use when a list is reused across scenes or rounds.
do -- LList:clear
  local lst = lurek.patterns.newList()
  lst:add("a")
  lst:add("b")
  lst:clear()
  lurek.log.info("length after clear=" .. lst:len(), "patterns")
end
--@api-stub: LList:toArray
-- Returns all items as a Lua table.
-- Use when you need a snapshot for sorting or serialising list contents.
do -- LList:toArray
  local lst = lurek.patterns.newList()
  lst:add(10)
  lst:add(20)
  lst:add(30)
  local arr = lst:toArray()
  lurek.log.info("arr[2]=" .. tostring(arr[2]), "patterns")
end
