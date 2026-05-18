-- content/examples/event.lua
-- Demonstrates every lurek.event function and LSignal class method with realistic game usage.
-- Run: cargo run -- content/examples/event.lua

--@api-stub: lurek.event.newSignal
-- Creates an isolated signal dispatcher for decoupled Lua-side pub/sub communication
do
  -- Use signals to decouple game systems: combat emits damage, UI listens and updates HUD
  local combat_bus = lurek.event.newSignal()
  combat_bus:register("damage_dealt", function(target, amount)
    lurek.log.info(target .. " took " .. amount .. " damage", "combat")
  end)
  combat_bus:emit("damage_dealt", "skeleton_warrior", 25)
end

--@api-stub: lurek.event.push
-- Pushes a named event with arguments into the shared queue for cross-system communication
do
  -- Push game events that other systems poll during the frame loop
  lurek.event.push("enemy_spawned", "goblin", 128, 256)
  lurek.event.push("coin_collected", 10)
  -- Events accumulate in the queue until polled or cleared
  for name, a, b in lurek.event.poll() do
    if name == "coin_collected" then
      lurek.log.info("player gained " .. tostring(a) .. " coins", "game")
    end
  end
end

--@api-stub: lurek.event.pushPriority
-- Pushes an event with explicit priority so high-priority events are polled first
do
  -- High-priority events jump ahead in the queue, useful for system-critical signals
  lurek.event.push("background_music", "forest_theme")
  lurek.event.pushPriority("player_death", "high", "hero", "lava")
  -- When polling, "player_death" appears before "background_music"
  for name, a, b in lurek.event.poll() do
    if name == "player_death" then
      lurek.log.info(tostring(a) .. " died from " .. tostring(b), "game")
    end
  end
end

--@api-stub: lurek.event.poll
-- Returns a polling iterator that drains queued events one at a time
do
  -- Typical frame-loop pattern: pump OS events, then poll game events
  lurek.event.push("input_action", "jump")
  lurek.event.push("input_action", "attack")
  local actions = {}
  for name, action in lurek.event.poll() do
    if name == "input_action" then
      actions[#actions + 1] = action
    end
  end
  lurek.log.info("processed " .. #actions .. " input actions this frame", "input")
end

--@api-stub: lurek.event.pump
-- Pumps the OS/engine event queue so new events become visible to poll
do
  -- Call pump once per frame before polling to ensure fresh events are available
  lurek.event.pump()
  -- After pump, all OS input events from this frame are queued and ready
  for name in lurek.event.poll() do
    lurek.log.debug("event: " .. name, "input")
  end
end

--@api-stub: lurek.event.wait
-- Blocks until an event arrives or timeout elapses; useful for tool scripts
do
  -- In a level editor tool, wait for user input before proceeding
  local ok, name, args = lurek.event.wait(0.1)
  if ok then
    lurek.log.info("received '" .. name .. "' with " .. #args .. " args", "tool")
  else
    lurek.log.info("no event within timeout, continuing idle loop", "tool")
  end
end

--@api-stub: LSignal:clear
-- Removes all pending events from the shared queue
do
  -- Clear stale input events when transitioning between scenes
  lurek.event.push("old_scene_action", "stale_jump")
  lurek.event.push("old_scene_action", "stale_attack")
  lurek.event.clear()
  -- After clear, poll returns nothing — no accidental input from the previous scene
  local count = 0
  for _ in lurek.event.poll() do count = count + 1 end
  lurek.log.info("events after scene transition clear: " .. count, "scene")
end

--@api-stub: lurek.event.pushDeferred
-- Queues an event into the deferred buffer, not the live queue
do
  -- Deferred events are useful during iteration: push now, deliver later
  -- Example: spawning enemies at end-of-frame to avoid modifying lists mid-loop
  for i = 1, 5 do
    lurek.event.pushDeferred("spawn_enemy", "skeleton", i * 64, 100)
  end
  -- Events sit in the deferred buffer until flushed
  lurek.log.info("queued 5 deferred spawn events", "spawner")
end

--@api-stub: lurek.event.pushDeferredPriority
-- Queues a prioritized event into the deferred buffer
do
  -- Mix priorities in deferred batch: boss spawn is urgent, minions are normal
  lurek.event.pushDeferredPriority("spawn_boss", "high", "dragon", 512, 300)
  lurek.event.pushDeferredPriority("spawn_minion", "normal", "imp", 100, 200)
  lurek.event.pushDeferredPriority("spawn_minion", "normal", "imp", 200, 200)
  lurek.log.info("deferred priority batch queued", "spawner")
end

--@api-stub: lurek.event.flushDeferred
-- Moves all deferred events into the live queue and returns the count moved
do
  -- End-of-frame pattern: flush deferred events so next frame can poll them
  lurek.event.pushDeferred("loot_drop", "sword", 64, 128)
  lurek.event.pushDeferred("loot_drop", "shield", 80, 128)
  lurek.event.pushDeferred("xp_gained", 150)
  local moved = lurek.event.flushDeferred()
  lurek.log.info("flushed " .. moved .. " end-of-frame events", "game")
end

--@api-stub: lurek.event.enableHistory
-- Enables event history with a fixed capacity for replay or debugging
do
  -- Enable history early in development to replay the last N events on crash
  lurek.event.enableHistory(128)
  lurek.event.push("player_move", 10, 20)
  lurek.event.push("player_attack", "slash")
  -- History retains push calls up to capacity for post-mortem inspection
  lurek.log.info("event history enabled with capacity 128", "debug")
end

--@api-stub: lurek.event.getHistory
-- Returns the retained event history as an array of {name, args} entries
do
  lurek.event.enableHistory(64)
  lurek.event.push("quest_accepted", "slay_dragon")
  lurek.event.push("quest_progress", "slay_dragon", 1, 3)
  -- Inspect history for debugging or building a replay system
  local history = lurek.event.getHistory()
  for _, entry in ipairs(history) do
    local arg_str = table.concat(entry.args, ", ")
    lurek.log.debug("history: " .. entry.name .. "(" .. arg_str .. ")", "replay")
  end
end

--@api-stub: lurek.event.clearHistory
-- Clears retained event history without disabling future recording
do
  lurek.event.enableHistory(32)
  lurek.event.push("temp_debug_marker", "checkpoint_A")
  -- After clearing, old entries are gone but new events still record
  lurek.event.clearHistory()
  lurek.event.push("real_event", "level_start")
  local h = lurek.event.getHistory()
  lurek.log.info("history after clear has " .. #h .. " entry", "debug")
end

--@api-stub: lurek.event.quit
-- Requests a graceful engine shutdown with exit code 0
do
  -- Typical main menu quit button handler
  local function on_quit_confirmed()
    lurek.log.info("saving progress before quit", "save")
    lurek.event.quit()
  end
  on_quit_confirmed()
end

--@api-stub: lurek.event.exit
-- Requests engine shutdown with a specific process exit code
do
  -- Use non-zero exit codes to signal errors to external launchers or CI
  local init_ok = true
  if not init_ok then
    lurek.log.error("critical init failure, exiting with code 1", "boot")
    lurek.event.exit(1)
  else
    lurek.event.exit(0)
  end
end

--@api-stub: lurek.event.restart
-- Requests a full engine restart, reloading conf.lua and all scripts
do
  -- Restart after applying settings that require a fresh engine state
  local function apply_language_change(lang)
    lurek.log.info("switching language to '" .. lang .. "', restarting engine", "i18n")
    lurek.event.restart()
  end
  apply_language_change("pl")
end

--@api-stub: LSignal:register
-- Registers a persistent callback for a named signal event
do
  -- Build a damage system where multiple listeners react to one event
  local sig = lurek.event.newSignal()
  local hp_listener = sig:register("hit", function(target, dmg)
    lurek.log.info(target .. " HP reduced by " .. dmg, "combat")
  end)
  local fx_listener = sig:register("hit", function(target, dmg)
    lurek.log.info("play hit particles on " .. target, "vfx")
  end)
  -- Both listeners fire when the signal emits
  sig:emit("hit", "orc", 15)
  lurek.log.info("registered handles: " .. hp_listener .. ", " .. fx_listener, "event")
end

--@api-stub: LSignal:emit
-- Emits a signal event, invoking all matching callbacks with the provided arguments
do
  -- Emit signals from game logic; listeners handle side effects
  local inventory = lurek.event.newSignal()
  inventory:register("item_added", function(item, qty)
    lurek.log.info("added " .. qty .. "x " .. item .. " to inventory", "ui")
  end)
  inventory:register("item_added", function(item, qty)
    if item == "health_potion" and qty >= 5 then
      lurek.log.info("achievement: potion hoarder!", "achievement")
    end
  end)
  -- Emit passes all extra args to every matching callback
  inventory:emit("item_added", "health_potion", 5)
end

--@api-stub: LSignal:connect
-- Registers a callback for an exact name or wildcard pattern
do
  -- Use wildcard "*" to build a debug logger that sees every signal
  local sig = lurek.event.newSignal()
  local debug_id = sig:connect("*", function(...)
    local args = {...}
    lurek.log.debug("signal wildcard caught " .. #args .. " args", "debug")
  end)
  sig:connect("player.jump", function()
    lurek.log.info("jump animation triggered", "anim")
  end)
  -- The wildcard listener fires for all emissions, specific ones only for their name
  sig:emit("player.jump")
  sig:emit("player.land")
  lurek.log.info("wildcard listener id: " .. debug_id, "event")
end

--@api-stub: LSignal:once
-- Registers a one-shot callback that auto-removes after first matching emission
do
  -- Perfect for one-time triggers like tutorial prompts or cutscene starts
  local sig = lurek.event.newSignal()
  sig:once("first_enemy_seen", function(enemy_type)
    lurek.log.info("tutorial: press X to attack the " .. enemy_type, "tutorial")
  end)
  -- First emit fires the callback
  sig:emit("first_enemy_seen", "slime")
  -- Second emit does nothing — the listener was already removed
  sig:emit("first_enemy_seen", "goblin")
  lurek.log.info("once listener count: " .. sig:getCount("first_enemy_seen"), "event")
end

--@api-stub: LSignal:registerWithFilter
-- Registers a callback that only fires when a filter predicate returns true
do
  -- Filter incoming damage events to only react to critical hits
  local combat = lurek.event.newSignal()
  combat:registerWithFilter(
    "damage",
    function(data)
      lurek.log.info("CRITICAL HIT! " .. data.amount .. " damage to " .. data.target, "combat")
    end,
    function(data)
      return data.critical == true
    end
  )
  -- Only the critical hit passes the filter
  combat:emit("damage", {target = "boss", amount = 50, critical = true})
  combat:emit("damage", {target = "boss", amount = 10, critical = false})
end

--@api-stub: LSignal:remove
-- Removes a specific callback by its subscription handle
do
  -- Temporarily listen for an event, then unsubscribe when done
  local sig = lurek.event.newSignal()
  local handle = sig:register("tick", function()
    lurek.log.debug("tick received", "timer")
  end)
  -- Simulate unsubscribing after the listener is no longer needed
  local removed = sig:remove(handle)
  lurek.log.info("removed listener " .. handle .. ": " .. tostring(removed), "event")
  -- Emit after removal: no callback fires
  sig:emit("tick")
end

--@api-stub: LSignal:clear
-- Removes all callbacks registered under one specific event name
do
  -- Clear all listeners for a specific event when a system shuts down
  local sig = lurek.event.newSignal()
  sig:register("update", function() end)
  sig:register("update", function() end)
  sig:register("draw", function() end)
  -- Only clears "update" listeners, "draw" remains
  local removed = sig:clear("update")
  lurek.log.info("cleared " .. removed .. " update listeners, draw remains: " .. sig:getCount("draw"), "event")
end

--@api-stub: LSignal:clearAll
-- Removes every callback from this signal regardless of event name
do
  -- Full reset of a signal dispatcher, e.g. when reloading a level
  local sig = lurek.event.newSignal()
  sig:register("enemy_spawn", function() end)
  sig:register("coin_pickup", function() end)
  sig:register("player_death", function() end)
  local total = sig:clearAll()
  lurek.log.info("level unload: removed " .. total .. " signal listeners", "scene")
end

--@api-stub: LSignal:getCount
-- Returns the number of callbacks registered for one specific event name
do
  -- Check listener count before emitting to avoid unnecessary work
  local sig = lurek.event.newSignal()
  sig:register("explosion", function() end)
  sig:register("explosion", function() end)
  local count = sig:getCount("explosion")
  if count > 0 then
    sig:emit("explosion", 200, 150)
    lurek.log.info("emitted to " .. count .. " explosion listeners", "vfx")
  end
end

--@api-stub: LSignal:getTotalCount
-- Returns the total number of callbacks across all event names in this signal
do
  -- Monitor signal subscription growth for debugging memory leaks
  local sig = lurek.event.newSignal()
  sig:register("frame_start", function() end)
  sig:register("frame_end", function() end)
  sig:register("input_poll", function() end)
  local total = sig:getTotalCount()
  lurek.log.info("signal has " .. total .. " total subscriptions", "diag")
end

--@api-stub: LSignal:type
-- Returns the Lua-visible type name string for this signal handle
do
  -- Use type() for runtime type inspection in generic code
  local sig = lurek.event.newSignal()
  local type_name = sig:type()
  lurek.log.info("signal handle type: " .. type_name, "diag")
end

--@api-stub: LSignal:typeOf
-- Returns true if this handle matches a given type name
do
  -- Guard functions can verify argument types before using them
  local sig = lurek.event.newSignal()
  local function register_safe(obj, name, fn)
    if not obj:typeOf("Signal") then
      lurek.log.error("expected Signal, got " .. obj:type(), "error")
      return
    end
    obj:register(name, fn)
  end
  register_safe(sig, "test", function() end)
  lurek.log.info("typeOf Signal=" .. tostring(sig:typeOf("Signal")) .. " Object=" .. tostring(sig:typeOf("Object")), "diag")
end

print("content/examples/event.lua")

-- ---- Stub: lurek.event.clear ---------------------------------------------
--@api-stub: lurek.event.clear
-- Removes all listeners for a named event, or all events if no name given.
do
  -- Create a signal to verify clear behaviour.
  local sig = lurek.event.newSignal()
  lurek.event.clear()
  lurek.log.debug("event cleared; sig ok: " .. tostring(sig ~= nil), "example")
end
