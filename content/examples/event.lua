-- content/examples/event.lua
-- Lurek2D lurek.event API Reference
-- Run with: cargo run -- content/examples/event

-- =============================================================================
-- lurek.event — Event queue and pub-sub signals
--
-- The event module provides two complementary systems: a global event queue
-- (push/poll/wait) for engine-level events like quit and restart, and a
-- Signal pub-sub dispatcher for game-level decoupled communication between
-- systems (damage events, UI notifications, achievement triggers).
-- =============================================================================

-- ---- Stub: lurek.event.push ----------------------------------------------
--@api-stub: lurek.event.push
-- Push a custom game event onto the global queue.  Other systems can poll
-- for it later in the same frame to react to cross-system happenings.
lurek.event.push("player_died", { zone = "lava_caves", cause = "spike_trap" })
lurek.event.push("item_picked_up", { item = "health_potion", slot = 3 })
lurek.event.push("checkpoint_reached", { id = "cave_entrance", time = 142.5 })
print("pushed 3 game events onto the queue")

-- ---- Stub: lurek.event.poll ----------------------------------------------
--@api-stub: lurek.event.poll
-- Drain the event queue each frame to process all pending events.  The
-- iterator returns (event_name, args_table) pairs until the queue is empty.
for name, args in lurek.event.poll() do
    if name == "player_died" then
        print("death event in zone: " .. args.zone .. " cause: " .. args.cause)
    elseif name == "item_picked_up" then
        print("picked up " .. args.item .. " into slot " .. args.slot)
    elseif name == "checkpoint_reached" then
        print("checkpoint " .. args.id .. " at t=" .. args.time)
    else
        print("unhandled event: " .. name)
    end
end

-- ---- Stub: lurek.event.pump ----------------------------------------------
--@api-stub: lurek.event.pump
-- Sync OS-level events into the queue.  In Lurek2D's push model this is a
-- no-op, but calling it at the top of your frame loop ensures compatibility
-- with engines that require explicit event pumping.
lurek.event.pump()
print("event pump called (no-op in push model)")

-- ---- Stub: lurek.event.clear ---------------------------------------------
--@api-stub: lurek.event.clear
-- Discard all pending events when transitioning between game states so
-- stale input or game events from the previous state do not leak through.
lurek.event.push("stale_event_1", {})
lurek.event.push("stale_event_2", {})
lurek.event.clear()
print("event queue cleared -- stale events discarded before scene transition")

-- ---- Stub: lurek.event.wait ----------------------------------------------
--@api-stub: lurek.event.wait
-- Block until an event arrives or a timeout elapses.  Useful in tool scripts
-- or cutscene sequencers that wait for a specific trigger.
lurek.event.push("cutscene_skip", { player = "hero_01" })
local evt = lurek.event.wait(2.0)    -- wait up to 2 seconds
if evt then
    print("received event while waiting: " .. tostring(evt))
else
    print("wait timed out -- no event in 2 seconds")
end

-- ---- Stub: lurek.event.pushDeferred --------------------------------------
--@api-stub: lurek.event.pushDeferred
-- Buffer events that should only fire at a safe point (e.g. end of physics
-- step) rather than immediately during collision callbacks.
lurek.event.pushDeferred("enemy_destroyed", { id = "skeleton_07", xp = 50 })
lurek.event.pushDeferred("loot_spawned", { item = "gold_coin", x = 200, y = 350 })
print("2 deferred events buffered -- will not appear in poll() yet")

-- ---- Stub: lurek.event.flushDeferred -------------------------------------
--@api-stub: lurek.event.flushDeferred
-- Move all deferred events into the main queue at a safe point in the frame,
-- e.g. after physics is done but before rendering.
local flushed = lurek.event.flushDeferred()
if flushed then
    print("flushed " .. #flushed .. " deferred events into main queue")
    for _, evt in ipairs(flushed) do
        print("  -> " .. tostring(evt))
    end
else
    print("no deferred events to flush")
end

-- ---- Stub: lurek.event.enableHistory -------------------------------------
--@api-stub: lurek.event.enableHistory
-- Enable event history recording for post-mortem debugging.  Keep the last
-- 100 events so we can inspect what happened before a crash.
lurek.event.enableHistory(100)
print("event history enabled -- keeping last 100 events")

-- ---- Stub: lurek.event.getHistory ----------------------------------------
--@api-stub: lurek.event.getHistory
-- Retrieve the event history ring buffer for display in a debug console.
-- Each entry is a {name, args} table.
lurek.event.push("wave_started", { wave = 3, enemy_count = 12 })
lurek.event.push("boss_spawned", { boss = "dragon", hp = 5000 })
lurek.event.clear()   -- clear queue, but history retains them

local history = lurek.event.getHistory()
print("event history: " .. #history .. " entries")
for i, entry in ipairs(history) do
    print(string.format("  [%d] %s", i, tostring(entry.name or entry[1] or "?")))
end

-- ---- Stub: lurek.event.clearHistory --------------------------------------
--@api-stub: lurek.event.clearHistory
-- Clear the history buffer when starting a new play session so past events
-- do not confuse post-mortem analysis.
lurek.event.clearHistory()
print("event history cleared for new session")

-- ---- Stub: lurek.event.exit ----------------------------------------------
--@api-stub: lurek.event.exit
-- Request the engine to shut down with an exit code.  Use exit(0) for normal
-- quit, or exit(1) to signal an error to external launchers.
if false then
    -- Guarded: calling exit() would terminate this example
    lurek.event.exit(0)
end
print("lurek.event.exit(0) would cleanly shut down the engine")

-- ---- Stub: lurek.event.quit ----------------------------------------------
--@api-stub: lurek.event.quit
-- Alias for exit() -- requests the engine to stop at end of frame.  Prefer
-- quit() in menu code because the name reads naturally: "player pressed quit".
if false then
    lurek.event.quit()
end
print("lurek.event.quit() is an alias for exit()")

-- ---- Stub: lurek.event.restart -------------------------------------------
--@api-stub: lurek.event.restart
-- Request an engine restart.  The game reloads main.lua from scratch, which
-- is useful for "return to title" or hot-reload during development.
if false then
    lurek.event.restart()
end
print("lurek.event.restart() would reload main.lua from scratch")


-- =============================================================================
-- Signal — pub-sub event dispatcher for decoupled game systems
-- =============================================================================

-- ---- Stub: lurek.event.newSignal -----------------------------------------
--@api-stub: lurek.event.newSignal
-- Create a Signal dispatcher to decouple game systems.  The combat system
-- emits "hit" and "heal" events; the UI, audio, and particle systems each
-- subscribe independently without knowing about each other.
local signal = lurek.event.newSignal()
print("signal dispatcher created: " .. tostring(signal))

-- Subscribe the UI to display floating damage numbers
local ui_handle = signal:on("hit", function(target, damage)
    print(string.format("  [UI] floating text: -%d on %s", damage, target))
end)

-- Subscribe the audio system to play impact sounds
local sfx_handle = signal:on("hit", function(target, damage)
    if damage > 50 then
        print("  [SFX] play critical_hit.ogg")
    else
        print("  [SFX] play light_hit.ogg")
    end
end)

-- Subscribe a heal listener
local heal_handle = signal:on("heal", function(target, amount)
    print(string.format("  [UI] green text: +%d HP on %s", amount, target))
end)

-- ---- Stub: Signal:emit ---------------------------------------------------
--@api-stub: Signal:emit
-- Fire events from the combat system.  All subscribers for that event name
-- are called synchronously with the provided arguments.
signal:emit("hit", "skeleton_07", 35)
signal:emit("hit", "boss_dragon", 120)
signal:emit("heal", "hero", 50)
print("emitted 2 hit events and 1 heal event")

-- ---- Stub: Signal:getCount -----------------------------------------------
--@api-stub: Signal:getCount
-- Check how many listeners are subscribed to a specific event.  Useful for
-- debugging when events seem to fire but nothing responds.
local hit_count = signal:getCount("hit")
local heal_count = signal:getCount("heal")
print("hit listeners: " .. hit_count .. "  heal listeners: " .. heal_count)

-- ---- Stub: Signal:getTotalCount ------------------------------------------
--@api-stub: Signal:getTotalCount
-- Report the total number of subscriptions across all event names for
-- diagnostics in a debug overlay.
local total = signal:getTotalCount()
print("total signal subscriptions: " .. total)

-- ---- Stub: Signal:remove -------------------------------------------------
--@api-stub: Signal:remove
-- Unsubscribe the audio system from hit events when the player mutes SFX.
-- The UI listener remains active.
local removed = signal:remove(sfx_handle)
print("SFX hit listener removed: " .. tostring(removed))
signal:emit("hit", "bat_03", 15)
-- Only the UI listener fires now

-- ---- Stub: Signal:clear --------------------------------------------------
--@api-stub: Signal:clear
-- Remove all listeners for a specific event when leaving a combat zone.
-- Heal listeners in the overworld are no longer needed.
local cleared = signal:clear("heal")
print("cleared heal listeners: " .. tostring(cleared))

-- ---- Stub: Signal:clearAll -----------------------------------------------
--@api-stub: Signal:clearAll
-- Remove every subscription when tearing down the game state before
-- returning to the title screen.
local total_cleared = signal:clearAll()
print("all signal listeners cleared: " .. tostring(total_cleared))

-- ---- Stub: Signal:type ---------------------------------------------------
--@api-stub: Signal:type
-- ---- Stub: Signal:typeOf -------------------------------------------------
--@api-stub: Signal:typeOf
-- Utility queries for runtime type checking (e.g. in a generic serializer).
print("signal type:     " .. signal:type())
print("is Signal?       " .. tostring(signal:typeOf("Signal")))
print("is SoundSource?  " .. tostring(signal:typeOf("SoundSource")))
-- content/examples/event.lua
-- Lurek2D lurek.event API Reference
-- Run with: cargo run -- content/examples/event

-- =============================================================================
-- STUBS: 22 uncovered lurek.event API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.event.exit ----------------------------------------------
--@api-stub: lurek.event.exit
-- Pushes an exit event, requesting the engine to stop.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.exit([code])

-- ---- Stub: lurek.event.poll ----------------------------------------------
--@api-stub: lurek.event.poll
-- Returns an iterator function that pops events from the queue.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.poll()  -- -> function

-- ---- Stub: lurek.event.clear ---------------------------------------------
--@api-stub: lurek.event.clear
-- Discards all pending events in the queue.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.clear()

-- ---- Stub: lurek.event.newSignal -----------------------------------------
--@api-stub: lurek.event.newSignal
-- Creates a new pub-sub Signal dispatcher.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.newSignal()  -- -> Signal

-- ---- Stub: lurek.event.pump ----------------------------------------------
--@api-stub: lurek.event.pump
-- Syncs OS-level events into the queue (no-op in Lurek2D push model).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.pump()

-- ---- Stub: lurek.event.wait ----------------------------------------------
--@api-stub: lurek.event.wait
-- Blocks until the next event arrives or the optional timeout elapses.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.wait([timeout])  -- -> string?

-- ---- Stub: lurek.event.restart -------------------------------------------
--@api-stub: lurek.event.restart
-- Requests that the engine restart at the beginning of the next frame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.restart()

-- ---- Stub: lurek.event.quit ----------------------------------------------
--@api-stub: lurek.event.quit
-- Alias for `exit()` — requests the engine to stop at the end of the current frame.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.quit()

-- ---- Stub: lurek.event.pushDeferred --------------------------------------
--@api-stub: lurek.event.pushDeferred
-- Pushes a named event to the deferred buffer; it will not reach the main queue
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.pushDeferred(args)

-- ---- Stub: lurek.event.flushDeferred -------------------------------------
--@api-stub: lurek.event.flushDeferred
-- Moves all buffered deferred events into the main event queue and clears the buffer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.flushDeferred()  -- -> table|nil

-- ---- Stub: lurek.event.enableHistory -------------------------------------
--@api-stub: lurek.event.enableHistory
-- Enables event history recording, keeping the last `capacity` pushed events.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.enableHistory(capacity)

-- ---- Stub: lurek.event.getHistory ----------------------------------------
--@api-stub: lurek.event.getHistory
-- Returns an array of recent events as `{name, args}` tables.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.getHistory()  -- -> table

-- ---- Stub: lurek.event.clearHistory --------------------------------------
--@api-stub: lurek.event.clearHistory
-- Clears all recorded event history.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.clearHistory()

-- ---- Stub: lurek.event.push ----------------------------------------------
--@api-stub: lurek.event.push
-- Adds an event item to the end of the event queue for processing.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.event.push(args)

-- -----------------------------------------------------------------------------
-- Signal methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Signal:emit ---------------------------------------------------
--@api-stub: Signal:emit
-- Emits the named event, calling all registered callbacks with extra arguments.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- signal_stub:emit(args)
-- (replace signal_stub with your real Signal instance above)

-- ---- Stub: Signal:remove -------------------------------------------------
--@api-stub: Signal:remove
-- Removes a subscription by handle ID.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- signal_stub:remove(handle)  -- -> boolean
-- (replace signal_stub with your real Signal instance above)

-- ---- Stub: Signal:clear --------------------------------------------------
--@api-stub: Signal:clear
-- Removes all callbacks for the named event.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- signal_stub:clear("hero")  -- -> integer
-- (replace signal_stub with your real Signal instance above)

-- ---- Stub: Signal:clearAll -----------------------------------------------
--@api-stub: Signal:clearAll
-- Removes all callbacks across all events.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- signal_stub:clearAll()  -- -> integer
-- (replace signal_stub with your real Signal instance above)

-- ---- Stub: Signal:getCount -----------------------------------------------
--@api-stub: Signal:getCount
-- Returns the callback count for the named event.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- signal_stub:getCount("hero")  -- -> integer
-- (replace signal_stub with your real Signal instance above)

-- ---- Stub: Signal:getTotalCount ------------------------------------------
--@api-stub: Signal:getTotalCount
-- Returns the total callback count across all events.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- signal_stub:getTotalCount()  -- -> integer
-- (replace signal_stub with your real Signal instance above)

-- ---- Stub: Signal:type ---------------------------------------------------
--@api-stub: Signal:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- signal_stub:type()  -- -> string
-- (replace signal_stub with your real Signal instance above)

-- ---- Stub: Signal:typeOf -------------------------------------------------
--@api-stub: Signal:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- signal_stub:typeOf("hero")  -- -> boolean
-- (replace signal_stub with your real Signal instance above)
