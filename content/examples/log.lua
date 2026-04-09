-- examples/log.lua
-- Demonstrates the luna.log API: structured log levels for Lua game scripts.
-- Messages route through Rust's `log` crate — visible in stdout under RUST_LOG.
-- Also demonstrates configurable log sinks (file + memory ring buffer).
-- Run with: cargo run -- examples/log
--
-- Control output verbosity:
--   RUST_LOG=luna2d=debug cargo run -- examples/log
--   RUST_LOG=luna2d=warn  cargo run -- examples/log

-- ─────────────────────────────────────────────────────────────────────────────
-- Severity-level shorthand functions
-- Each function emits a message at a fixed severity. All output is prefixed
-- with "[<tag>]" in the engine log so you can tell scripts apart from engine lines.
-- An optional second argument sets the tag (default "Lua").
-- ─────────────────────────────────────────────────────────────────────────────

luna.log.debug("player position updated: x=42, y=17")           -- tag defaults to "Lua"
luna.log.info("game world initialised with 64 tiles",  "World") -- custom tag "World"
luna.log.warn("texture cache miss: using fallback",    "Assets")
luna.log.error("save file corrupted — new game",       "Save")

-- ─────────────────────────────────────────────────────────────────────────────
-- Dynamic-level dispatch
-- ─────────────────────────────────────────────────────────────────────────────

local function emit(level, message, tag)
    luna.log.print(level, message, tag)
end

emit("info",  "audio subsystem ready",               "Audio")
emit("warn",  "controller disconnected during play",  "Input")
emit("error", "network socket closed unexpectedly",  "Net")

-- ─────────────────────────────────────────────────────────────────────────────
-- Runtime level management
-- ─────────────────────────────────────────────────────────────────────────────

local original_level = luna.log.getLevel()
luna.log.setLevel("debug")
luna.log.debug("verbose mode active")
luna.log.setLevel("warn")
luna.log.debug("this debug line is filtered out")
luna.log.warn("this warning is shown")
luna.log.setLevel(original_level)

-- ─────────────────────────────────────────────────────────────────────────────
-- Configurable log sinks
-- Sinks are additional output destinations beyond the default stderr channel.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Memory sink ──────────────────────────────────────────────────────────────
-- Retains a ring buffer of recent entries for later inspection (e.g. in-game console).
local mem_id = luna.log.addSink({ type = "memory", capacity = 50, level = "info" })
luna.log.info("this message lands in the memory sink", "Game")
luna.log.warn("a warning also captured", "Game")
luna.log.debug("debug lines below 'info' are filtered by the sink")

-- Read all entries from the memory sink without clearing it.
local entries = luna.log.readMemory(mem_id)
for _, e in ipairs(entries) do
    -- Each entry: { level, tag, message }
    print(string.format("[%s] (%s) %s", e.level, e.tag, e.message))
end

-- Read and drain in one call.
local drained = luna.log.readMemory(mem_id, true)
assert(#drained == #entries, "drain should return same count")

-- ── File sink ────────────────────────────────────────────────────────────────
-- Appends every entry at or above the minimum level to a UTF-8 text file.
local log_path = "save/example.log"
local ok, err = pcall(function()
    local file_id = luna.log.addSink({ type = "file", path = log_path, level = "warn" })
    luna.log.warn("wrote to file sink", "File")
    luna.log.error("error also in file", "File")
    luna.log.flushFile(file_id)

    -- Remove a specific sink by id.
    luna.log.removeSink(file_id)
end)
if not ok then
    -- File write may fail if save/ does not exist — that is fine in the example.
    luna.log.warn("file sink skipped: " .. tostring(err))
end

-- ── Sink inspection ──────────────────────────────────────────────────────────
local sinks = luna.log.listSinks()
for _, s in ipairs(sinks) do
    -- Each entry: { id, type, level, path? }
    print(string.format("Sink %d: type=%s level=%s", s.id, s.type, s.level))
end

-- Remove all sinks (default stderr channel is unaffected).
luna.log.clearSinks()
luna.log.info("all custom sinks removed — only stderr active now")

-- ─────────────────────────────────────────────────────────────────────────────
-- Practical patterns
-- ─────────────────────────────────────────────────────────────────────────────

-- Categorised log helper
local function logAI(level, msg)  luna.log.print(level, msg, "AI")  end
local function logUI(level, msg)  luna.log.print(level, msg, "UI")  end

logAI("debug", "pathfinding recalculated for entity 17")
logUI("info",  "main menu shown")
logAI("warn",  "navigation mesh stale — rebuild triggered")

-- Structured data
local stats = { hp = 100, mp = 42, level = 5 }
luna.log.debug(string.format("hp=%d mp=%d lvl=%d", stats.hp, stats.mp, stats.level), "Player")

-- ─────────────────────────────────────────────────────────────────────────────
-- Separation from luna.devtools.logger
-- luna.log  → routes to stdout via RUST_LOG / env_logger.
--             Consumed by the developer terminal and log files.
-- luna.devtools.logger (in devtools_api) → in-memory ring buffer.
--             Consumed by in-game diagnostic overlay panels.
-- These are independent channels — emitting to one does NOT affect the other.
-- ─────────────────────────────────────────────────────────────────────────────

luna.log.info("[log.lua] example complete")
