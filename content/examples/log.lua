-- content/examples/log.lua
-- Lurek2D lurek.log API Reference
-- Run with: cargo run -- content/examples/log

-- =============================================================================
-- lurek.log — Structured logging with configurable sinks
--
-- The log module lets game scripts emit severity-tagged messages that appear
-- alongside engine output in the console.  Messages can also be routed to
-- file sinks (for crash logs) and memory sinks (for in-game debug consoles).
-- Structured logging adds key-value fields for machine-parseable output.
-- =============================================================================

-- ---- Stub: lurek.log.setLevel --------------------------------------------
--@api-stub: lurek.log.setLevel
-- Set the minimum log level early in init so only relevant messages appear.
-- During development use "debug"; for playtesting use "warn" to reduce noise.
lurek.log.setLevel("debug")
print("log level set to: debug")

-- ---- Stub: lurek.log.getLevel --------------------------------------------
--@api-stub: lurek.log.getLevel
-- Display the current log level in the options menu so the player knows
-- how verbose the console output will be.
local current_level = lurek.log.getLevel()
print("active log level: " .. current_level)

-- ---- Stub: lurek.log.debug -----------------------------------------------
--@api-stub: lurek.log.debug
-- Emit per-frame diagnostics that are only visible when RUST_LOG includes
-- debug level.  Tag messages with a subsystem name to filter later.
lurek.log.debug("player position updated: x=312.5 y=780.0", "movement")
lurek.log.debug("collision check: 4 candidates in spatial hash cell (5,12)", "physics")
lurek.log.debug("animation frame advanced: walk_cycle -> frame 3", "anim")
print("emitted 3 debug messages")

-- ---- Stub: lurek.log.info ------------------------------------------------
--@api-stub: lurek.log.info
-- Log significant lifecycle events at info level: level loads, scene
-- transitions, checkpoint saves.  These form the backbone of a session log.
lurek.log.info("level loaded: Dungeon Floor 3", "scene")
lurek.log.info("player entered boss arena", "gameplay")
lurek.log.info("checkpoint saved at frame 12400", "save")
print("emitted 3 info messages")

-- ---- Stub: lurek.log.warn ------------------------------------------------
--@api-stub: lurek.log.warn
-- Warn about recoverable issues: missing optional assets, fallback paths
-- activated, or performance dipping below threshold.
lurek.log.warn("texture 'gold_chest.png' not found -- using fallback", "assets")
lurek.log.warn("FPS dropped to 28 for 3 consecutive frames", "perf")
lurek.log.warn("save file version mismatch -- migration applied", "save")
print("emitted 3 warning messages")

-- ---- Stub: lurek.log.error -----------------------------------------------
--@api-stub: lurek.log.error
-- Log errors that will degrade gameplay: corrupt save data, shader compile
-- failure, missing critical assets.  These should always be visible.
lurek.log.error("failed to load 'boss_phase2.lua' -- boss fight broken", "scripts")
lurek.log.error("shader compilation failed: bloom.wgsl line 42", "render")
lurek.log.error("save slot 3 is corrupted -- cannot restore progress", "save")
print("emitted 3 error messages")

-- ---- Stub: lurek.log.print -----------------------------------------------
--@api-stub: lurek.log.print
-- Use print() when the log level is determined at runtime, e.g. by a config
-- value or a debug console command.
local severity = "info"   -- could come from a config file or UI dropdown
lurek.log.print(severity, "dynamic severity message from console", "console")

-- Useful in a dev console where the user types: /log warn "something happened"
local user_level = "warn"
local user_msg   = "manual warning from dev console"
lurek.log.print(user_level, user_msg, "devconsole")
print("emitted 2 dynamic-level messages")

-- ---- Stub: lurek.log.addSink ---------------------------------------------
--@api-stub: lurek.log.addSink
-- Register a file sink for crash diagnostics and a memory sink for the
-- in-game debug console.  Each sink has its own minimum severity threshold.
local file_sink_id = lurek.log.addSink({
    type  = "file",
    path  = "logs/game_session.log",
    level = "debug",       -- capture everything to disk
})
print("file sink registered with id: " .. tostring(file_sink_id))

local mem_sink_id = lurek.log.addSink({
    type     = "memory",
    capacity = 200,        -- keep last 200 entries
    level    = "warn",     -- only warnings and errors in the console
})
print("memory sink registered with id: " .. tostring(mem_sink_id))

-- ---- Stub: lurek.log.listSinks -------------------------------------------
--@api-stub: lurek.log.listSinks
-- Enumerate all active sinks in the dev tools panel so the developer can
-- see where log output is being routed.
local sinks = lurek.log.listSinks()
print("active sinks: " .. #sinks)
for _, sink in ipairs(sinks) do
    local desc = string.format("  id=%d  type=%s  level=%s",
        sink.id, sink.type or "?", sink.level or "?")
    if sink.path then
        desc = desc .. "  path=" .. sink.path
    end
    print(desc)
end

-- ---- Stub: lurek.log.readMemory ------------------------------------------
--@api-stub: lurek.log.readMemory
-- Read entries from the memory sink to populate the in-game debug console.
-- Pass drain=true to clear the buffer after reading so old messages do not
-- accumulate between console refreshes.
lurek.log.warn("low ammo: 3 rounds remaining", "gameplay")
lurek.log.error("enemy AI stuck in wall at (200, 450)", "ai")

local entries = lurek.log.readMemory(mem_sink_id, true)   -- true = drain
if entries then
    print("memory sink entries (drained):")
    for _, e in ipairs(entries) do
        print(string.format("  [%s] %s", e.level or "?", e.message or ""))
    end
else
    print("memory sink empty or invalid id")
end

-- ---- Stub: lurek.log.flushFile -------------------------------------------
--@api-stub: lurek.log.flushFile
-- Flush the file sink before a potentially dangerous operation (e.g. loading
-- untrusted mod code) so the log is complete if the engine crashes.
lurek.log.info("about to load mod: dark_dungeon_pack.zip", "mods")
lurek.log.flushFile(file_sink_id)
print("file sink flushed -- log is durable on disk")

-- ---- Stub: lurek.log.removeSink ------------------------------------------
--@api-stub: lurek.log.removeSink
-- Remove the memory sink when the player closes the debug console to free
-- the ring buffer memory.
local removed = lurek.log.removeSink(mem_sink_id)
print("memory sink removed: " .. tostring(removed))

-- ---- Stub: lurek.log.clearSinks ------------------------------------------
--@api-stub: lurek.log.clearSinks
-- Remove all custom sinks when transitioning from dev mode to release mode.
-- The default stderr output is unaffected.
lurek.log.clearSinks()
local after = lurek.log.listSinks()
print("sinks after clearSinks: " .. #after)

-- ---- Stub: lurek.log.struct ----------------------------------------------
--@api-stub: lurek.log.struct
-- Emit a structured log entry with key-value fields for machine-parseable
-- output.  External log aggregators (ELK, Loki) can index these fields.
lurek.log.struct("info", "item_purchased", {
    item_id   = "sword_003",
    cost      = 250,
    currency  = "gold",
    player_id = "hero_01",
    zone      = "town_market",
})
print("structured log emitted: item_purchased")

-- ---- Stub: lurek.log.debug_fields ----------------------------------------
--@api-stub: lurek.log.debug_fields
-- Shorthand for struct("debug", ...).  Log per-frame physics state with
-- named fields so replays can be reconstructed from the log.
lurek.log.debug_fields("physics_step", {
    body_count    = 42,
    active_bodies = 18,
    step_ms       = 1.23,
    island_count  = 3,
})
print("debug_fields emitted: physics_step")

-- ---- Stub: lurek.log.info_fields -----------------------------------------
--@api-stub: lurek.log.info_fields
-- Log a player achievement unlock with context fields for analytics.
lurek.log.info_fields("achievement_unlocked", {
    achievement = "dragon_slayer",
    player      = "hero_01",
    play_time   = 3420,
    zone        = "volcano_peak",
})
print("info_fields emitted: achievement_unlocked")

-- ---- Stub: lurek.log.warn_fields -----------------------------------------
--@api-stub: lurek.log.warn_fields
-- Warn about a performance regression with fields that help pinpoint the cause.
lurek.log.warn_fields("frame_budget_exceeded", {
    frame_ms    = 22.5,
    budget_ms   = 16.67,
    draw_calls  = 380,
    zone        = "particle_heavy_arena",
    particle_ct = 12000,
})
print("warn_fields emitted: frame_budget_exceeded")

-- ---- Stub: lurek.log.error_fields ----------------------------------------
--@api-stub: lurek.log.error_fields
-- Log a critical save failure with enough context for post-mortem debugging.
lurek.log.error_fields("save_write_failed", {
    slot      = 2,
    path      = "saves/slot2.sav",
    errno     = 28,
    disk_free = "0 MB",
    save_size = "4.2 MB",
})
print("error_fields emitted: save_write_failed")
