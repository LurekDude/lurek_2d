-- content/examples/event.lua
-- Hand-written coverage of the lurek.event API (22 items).
--
-- The event module exposes two layers: a per-frame event queue (push / poll /
-- wait, plus deferred buffering and an optional history ring) and a Signal
-- userdata for in-process pub-sub. Signals are independent of the queue and
-- fire callbacks synchronously.
--
-- Run: cargo run -- content/examples/event.lua

-- ── lurek.event.* functions ──

--@api-stub: lurek.event.exit
-- Pushes an exit event, requesting the engine to stop.
-- Pass a non-zero code from CI / smoke runs so the wrapping shell sees the failure.
do  -- lurek.event.exit
  local fatal = false
  if fatal then
    lurek.event.exit(1)
  else
    lurek.event.exit(0)
  end
end

--@api-stub: lurek.event.poll
-- Returns an iterator function that pops events from the queue.
-- Drain the iterator once per frame in lurek.process so no event lingers across ticks.
do  -- lurek.event.poll
  function lurek.process(dt)
    for name, a, b in lurek.event.poll() do
      if name == "keypressed" and a == "escape" then
        lurek.event.quit()
      end
    end
  end
end

--@api-stub: lurek.event.clear
-- Discards all pending events in the queue.
-- Call on scene transitions to drop stale input that arrived during a loading screen.
do  -- lurek.event.clear
  local function load_level(name)
    lurek.event.clear()
    lurek.log.info("loaded " .. name .. "; input queue flushed", "scene")
  end
  load_level("forest_01")
end

--@api-stub: lurek.event.newSignal
-- Creates a new pub-sub Signal dispatcher.
-- Create one Signal per subsystem (combat, ui, world) so callback churn stays scoped.
do  -- lurek.event.newSignal
  local combat = lurek.event.newSignal()
  combat:register("damage", function(target, amount)
    lurek.log.info(target .. " took " .. amount .. " hp", "combat")
  end)
  combat:emit("damage", "goblin", 12)
end

--@api-stub: lurek.event.pump
-- Syncs OS-level events into the queue (no-op in Lurek2D push model).
-- Provided for love2d portability; safe to leave in main loops ported from love.
do  -- lurek.event.pump
  function lurek.process(dt)
    lurek.event.pump()
    for name in lurek.event.poll() do
      lurek.log.debug("event: " .. name, "input")
    end
  end
end

--@api-stub: lurek.event.wait
-- Blocks until the next event arrives or the optional timeout elapses.
-- Use only in headless tools / editor modes; in a game loop it stalls rendering.
do  -- lurek.event.wait
  local name = lurek.event.wait(0.5)
  if name then
    lurek.log.info("got event '" .. name .. "' within timeout", "tool")
  else
    lurek.log.info("wait timed out, continuing idle", "tool")
  end
end

--@api-stub: lurek.event.restart
-- Requests that the engine restart at the beginning of the next frame.
-- Use after applying graphics settings that need a fresh window / GPU device.
do  -- lurek.event.restart
  local function apply_graphics_preset(preset)
    lurek.log.info("applied preset '" .. preset .. "', restarting", "boot")
    lurek.event.restart()
  end
  apply_graphics_preset("high")
end

--@api-stub: lurek.event.quit
-- Alias for `exit()` — requests the engine to stop at the end of the current frame.
-- Wire to a confirmed "Quit to desktop" menu button; exit code is always 0.
do  -- lurek.event.quit
  local function on_quit_button()
    lurek.log.info("user requested quit", "ui")
    lurek.event.quit()
  end
  on_quit_button()
end

--@api-stub: lurek.event.pushDeferred
-- Pushes a named event to the deferred buffer; it will not reach the main queue.
-- Use mid-iteration to avoid mutating the queue you are currently polling.
do  -- lurek.event.pushDeferred
  for i = 1, 3 do
    lurek.event.pushDeferred("spawn", "enemy", i * 64, 0)
  end
  lurek.event.flushDeferred()
end

--@api-stub: lurek.event.flushDeferred
-- Moves all buffered deferred events into the main event queue and clears the buffer.
-- Returns the number of events flushed; call once at the end of each tick.
do  -- lurek.event.flushDeferred
  lurek.event.pushDeferred("save", "slot1")
  lurek.event.pushDeferred("save", "slot2")
  local moved = lurek.event.flushDeferred()
  lurek.log.info("flushed " .. moved .. " deferred events", "event")
end

--@api-stub: lurek.event.enableHistory
-- Enables event history recording, keeping the last `capacity` pushed events.
-- Pass 0 to disable. Useful for debug overlays or post-mortem crash dumps.
do  -- lurek.event.enableHistory
  lurek.event.enableHistory(64)
  lurek.event.push("checkpoint", "boss_arena")
  lurek.event.push("achievement", "first_blood")
end

--@api-stub: lurek.event.getHistory
-- Returns an array of recent events as `{name, args}` tables.
-- Walk the result to render a rolling event log, or to dump on crash for repro.
do  -- lurek.event.getHistory
  lurek.event.enableHistory(32)
  lurek.event.push("damage", "player", 5)
  for _, entry in ipairs(lurek.event.getHistory()) do
    lurek.log.debug("hist: " .. entry.name .. " #args=" .. #entry.args, "event")
  end
end

--@api-stub: lurek.event.clearHistory
-- Clears all recorded event history.
-- Call when entering a new level so the debug overlay does not show prior-level events.
do  -- lurek.event.clearHistory
  lurek.event.enableHistory(16)
  lurek.event.push("temp_event")
  lurek.event.clearHistory()
  lurek.log.info("history cleared, entries=" .. #lurek.event.getHistory(), "event")
end

--@api-stub: lurek.event.push
-- Adds an event item to the end of the event queue for processing.
-- Extra args travel with the event and surface as additional return values from poll().
do  -- lurek.event.push
  lurek.event.push("damage", "player", 12)
  for name, target, amount in lurek.event.poll() do
    if name == "damage" then
      lurek.log.info(target .. " took " .. tostring(amount), "combat")
    end
  end
end

-- ── Signal methods ──

--@api-stub: Signal:emit
-- Emits the named event, calling all registered callbacks with extra arguments.
-- Synchronous: callbacks run on the calling thread before emit returns.
do  -- Signal:emit
  local sig = lurek.event.newSignal()
  sig:register("level_up", function(actor, new_level)
    lurek.log.info(actor .. " reached level " .. new_level, "rpg")
  end)
  sig:emit("level_up", "hero", 7)
end

--@api-stub: Signal:remove
-- Removes a subscription by handle ID.
-- Capture the handle returned by :register and remove it when the listener is destroyed.
do  -- Signal:remove
  local sig = lurek.event.newSignal()
  local handle = sig:register("tick", function() end)
  local removed = sig:remove(handle)
  lurek.log.info("unsubscribed handle=" .. handle .. " ok=" .. tostring(removed), "event")
end

--@api-stub: Signal:clear
-- Removes all callbacks for the named event.
-- Use on scene unload to drop every listener for one event without tracking handles.
do  -- Signal:clear
  local sig = lurek.event.newSignal()
  sig:register("damage", function() end)
  sig:register("damage", function() end)
  local n = sig:clear("damage")
  lurek.log.info("dropped " .. n .. " damage listeners", "event")
end

--@api-stub: Signal:clearAll
-- Removes all callbacks across all events.
-- Heavy hammer; reserve for full Signal teardown when the owning subsystem shuts down.
do  -- Signal:clearAll
  local sig = lurek.event.newSignal()
  sig:register("a", function() end)
  sig:register("b", function() end)
  local total = sig:clearAll()
  lurek.log.info("dispatcher reset, removed=" .. total, "event")
end

--@api-stub: Signal:getCount
-- Returns the callback count for the named event.
-- Branch on it to skip building expensive emit args when no one is listening.
do  -- Signal:getCount
  local sig = lurek.event.newSignal()
  sig:register("frame", function() end)
  if sig:getCount("frame") > 0 then
    sig:emit("frame", 0.016)
  end
end

--@api-stub: Signal:getTotalCount
-- Returns the total callback count across all events.
-- Surface in a debug overlay to spot listener leaks (count climbing each frame).
do  -- Signal:getTotalCount
  local sig = lurek.event.newSignal()
  sig:register("a", function() end)
  sig:register("b", function() end)
  lurek.log.debug("signal listener count=" .. sig:getTotalCount(), "diag")
end

--@api-stub: Signal:type
-- Returns the type name of this object.
-- Use in generic helpers that accept multiple userdata kinds and need to dispatch on type.
do  -- Signal:type
  local sig = lurek.event.newSignal()
  local kind = sig:type()
  lurek.log.info("created object of type=" .. kind, "diag")
end

--@api-stub: Signal:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- Use as a guard in library code that should accept any Signal-derived dispatcher.
do  -- Signal:typeOf
  local sig = lurek.event.newSignal()
  if sig:typeOf("Signal") and sig:typeOf("Object") then
    lurek.log.info("dispatcher passes Signal+Object guard", "diag")
  end
end

--@api-stub: Signal:connect
-- Short-hand for register: adds a callback and returns an id for later removal.
-- connect is an alias that emphasises the observer-pattern usage style.
do  -- Signal:connect
  local sig = lurek.event.newSignal()
  local id = sig:connect(function(data)
    lurek.log.info("received: " .. tostring(data), "event")
  end)
  sig:emit("hello")
  lurek.log.info("listener id: " .. id, "event")
end

--@api-stub: Signal:once
-- Registers a one-shot listener that automatically removes itself after the first emission.
-- Use to wait for a single event (load complete, door open) without manual cleanup.
do  -- Signal:once
  local sig = lurek.event.newSignal()
  sig:once(function(val)
    lurek.log.info("once fired: " .. tostring(val), "event")
  end)
  sig:emit(42)
  sig:emit(99)
  lurek.log.info("count after once: " .. sig:getCount(), "event")
end

--@api-stub: Signal:register
-- Registers a persistent callback and returns a listener id.
-- Listeners fire in registration order; remove with signal:remove(id).
do  -- Signal:register
  local sig = lurek.event.newSignal()
  local id = sig:register(function(payload)
    lurek.log.info("payload: " .. tostring(payload), "event")
  end)
  sig:emit("damage")
  lurek.log.info("registered id: " .. id, "event")
end

--@api-stub: Signal:registerWithFilter
-- Registers a callback with a filter predicate; only fires when predicate(payload) is truthy.
-- Reduces boilerplate for event buses where many listeners share a single Signal.
do  -- Signal:registerWithFilter
  local sig = lurek.event.newSignal()
  sig:registerWithFilter(
    function(evt) return evt.type == "damage" end,
    function(evt) lurek.log.info("damage event", "event") end
  )
  sig:emit({type="damage", amount=10})
  sig:emit({type="heal", amount=5})
  lurek.log.info("filtered listener ok", "event")
end
