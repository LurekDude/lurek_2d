-- examples/event.lua
-- Lurek2D lurek.signal API Reference
-- Covers the Signal event bus and the engine event queue.

-- ─────────────────────────────────────────────────────────────────────────────
-- Signal — named publish/subscribe event bus
-- ─────────────────────────────────────────────────────────────────────────────

-- Create a standalone signal object (not tied to a name)
local signal = lurek.signal.newSignal()

-- Subscribe a listener; returns an opaque handle for later removal
local handle = signal:register("player_died", function(player_id, cause)
    print("player", player_id, "died from", cause)
end)

-- Emit: calls all listeners registered under that name
signal:emit("player_died", 1, "falling")   -- passes any extra args to each callback

-- Remove a specific listener by handle
signal:remove(handle)

-- Remove all listeners for a name
local removed_count = signal:clear("player_died")

-- Remove every listener on this signal
local total_removed = signal:clearAll()

-- Count listeners for a name
local n = signal:getCount("player_died")

-- Count all listeners across all names
local total = signal:getTotalCount()

-- ── Named global signals ─────────────────────────────────────────────────────

-- Get (or create) a globally named signal — same name returns the same object
local ui_events = lurek.signal.getSignal("ui")
local sfx_bus   = lurek.signal.getSignal("sfx")

-- Multiple subscribers on the same signal
local h1 = ui_events:register("button_click", function(id)
    print("UI heard click on", id)
end)

local h2 = ui_events:register("button_click", function(id)
    -- another system can also listen
    -- audio system plays a click sound
end)

ui_events:emit("button_click", "start_button")

-- ── Typical usage pattern ────────────────────────────────────────────────────

-- Define all game events in one place:
local events = {
    game_over = lurek.signal.newSignal(),
    item_picked_up = lurek.signal.newSignal(),
    level_complete = lurek.signal.newSignal(),
}

-- Subscribe from different systems:
events.game_over:register("game_over", function(score)
    -- show game-over screen
end)

events.item_picked_up:register("item_picked_up", function(item_id, player_id)
    -- update inventory HUD
end)

-- Trigger an event:
events.item_picked_up:emit("item_picked_up", "health_potion", 1)

-- ─────────────────────────────────────────────────────────────────────────────
-- Engine Event Queue  (push/poll for one-time cross-frame events)
-- ─────────────────────────────────────────────────────────────────────────────

-- Push a custom event into the queue with optional payload values
lurek.signal.push("score_changed", 1500)
lurek.signal.push("cutscene_start", "intro")
lurek.signal.push("achievement_unlocked", "first_kill", { icon = "sword" })

-- Count events currently waiting in the queue
local queued = lurek.signal.getCount()

-- Poll the next event from the queue (returns name + extra values, or nil if empty)
local name, a1, a2 = lurek.signal.poll()
if name then
    print("event:", name, a1, a2)
end

-- Process all queued events in a loop (typical main loop pattern):
function lurek.process(dt)
    local ev, v1, v2, v3
    local safety = 0
    repeat
        ev, v1, v2, v3 = lurek.signal.poll()
        if ev == "score_changed" then
            -- update score display using v1
        elseif ev == "cutscene_start" then
            -- trigger cutscene v1
        elseif ev == "achievement_unlocked" then
            -- show achievement toast using v1 name and v2 table
        end
        safety = safety + 1
    until ev == nil or safety > 1000
end

-- Discard all remaining queued events
lurek.signal.clear()

-- ─────────────────────────────────────────────────────────────────────────────
-- Quitting
-- ─────────────────────────────────────────────────────────────────────────────

-- Request the engine to exit cleanly (runs lurek.quit() callback if defined)
lurek.signal.quit()

-- Request exit with a specific process exit code
lurek.signal.quit(1)  -- non-zero = error exit

-- ─── Signal ────────────────────────────────────────────────────────────────────

local signal_type = signal:type()  -- "Signal"
local signal_is_type = signal:typeOf("Signal")  -- Returns true if the given type name matches this object's type or any parent type

-- ─── lurek.signal ───────────────────────────────────────────────────────────────
lurek.signal.exit()  -- Pushes an exit event, requesting the engine to stop
lurek.signal.pump()  -- Syncs OS-level events into the queue (no-op in Lurek2D push model)
lurek.signal.restart()  -- Requests that the engine restart at the beginning of the next frame
local wait = lurek.signal.wait()  -- Blocks until the next event arrives or the optional timeout elapses
