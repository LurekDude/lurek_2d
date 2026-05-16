-- content/examples/log.lua
-- lurek.log API examples.
-- Run: cargo run -- content/examples/log.lua

--@api-stub: lurek.log.debug
-- Logs a debug message with an optional tag
do
  local player = { x = 128.5, y = 64.0 }
  lurek.log.debug("player pos x=" .. player.x .. " y=" .. player.y, "movement")
end

--@api-stub: lurek.log.info
-- Logs an info message with an optional tag
do
  local level_name = "forest_01"
  local entity_count = 47
  lurek.log.info("loaded level '" .. level_name .. "' with " .. entity_count .. " entities", "scene")
end

--@api-stub: lurek.log.warn
-- Logs a warning message with an optional tag
do
  local hp = 5
  if hp < 10 then
    lurek.log.warn("player hp critical: " .. hp, "combat")
  end
end

--@api-stub: lurek.log.error
-- Logs an error message with an optional tag
do
  local asset_path = "sfx/missing_jump.ogg"
  lurek.log.error("failed to load audio asset: " .. asset_path .. " (using silent fallback)", "audio")
end

--@api-stub: lurek.log.print
-- Logs a message at a runtime-selected level with an optional tag
do
  local severity = "warn"
  local fps = 28
  lurek.log.print(severity, "frame rate dipped to " .. fps, "perf")
end

--@api-stub: lurek.log.setLevel
-- Sets the global log level
do
  local in_release = true
  lurek.log.setLevel(in_release and "info" or "debug")
  lurek.log.debug("this is filtered out in release builds", "boot")
  lurek.log.info("logging configured", "boot")
end

--@api-stub: lurek.log.getLevel
-- Returns the global log level string
do
  local current = lurek.log.getLevel()
  if current == "debug" or current == "trace" then
    local snapshot = "entities=124 frame=8421 mem=12MB"
    lurek.log.debug("frame snapshot: " .. snapshot, "diag")
  end
end

--@api-stub: lurek.log.addSink
-- Adds a memory, file, rotating, or callback sink from a config table
do
  local mem_id = lurek.log.addSink({ type = "memory", capacity = 256, level = "warn" })
  local file_id = lurek.log.addSink({ type = "file", path = "save/session.log", level = "info" })
  lurek.log.warn("session started, mem sink=" .. mem_id .. " file sink=" .. file_id, "boot")
end

--@api-stub: lurek.log.removeSink
-- Removes a sink by id and releases any callback registry key
do
  local sink_id = lurek.log.addSink({ type = "memory", capacity = 64 })
  lurek.log.info("temporary diagnostics enabled", "diag")
  local removed = lurek.log.removeSink(sink_id)
  lurek.log.info("diagnostics removed=" .. tostring(removed), "diag")
end

--@api-stub: lurek.log.clearSinks
-- Removes all sinks and releases callback registry keys
do
  lurek.log.addSink({ type = "memory", capacity = 32 })
  lurek.log.addSink({ type = "memory", capacity = 32, level = "error" })
  lurek.log.clearSinks()
  lurek.log.info("sinks cleared; stderr still active", "boot")
end

--@api-stub: lurek.log.listSinks
-- Returns metadata for all registered sinks
do
  lurek.log.addSink({ type = "memory", capacity = 100, level = "info" })
  local sinks = lurek.log.listSinks()
  for _, s in ipairs(sinks) do
    lurek.log.info("sink #" .. s.id .. " type=" .. s.type .. " level=" .. s.level, "diag")
  end
end

--@api-stub: lurek.log.readMemory
-- Reads entries from a memory sink and optionally drains them
do
  local mem_id = lurek.log.addSink({ type = "memory", capacity = 16, level = "warn" })
  lurek.log.warn("collision spike on enemy 7", "physics")
  local entries = lurek.log.readMemory(mem_id, true)
  for _, e in ipairs(entries) do
    print("[" .. e.level .. "][" .. e.tag .. "] " .. e.message)
  end
end

--@api-stub: lurek.log.flushFile
-- Flushes a file-backed sink by id when it exists
do
  local file_id = lurek.log.addSink({ type = "file", path = "save/crash.log", level = "error" })
  lurek.log.error("uncaught script error: nil player.body", "panic")
  lurek.log.flushFile(file_id)
end

--@api-stub: lurek.log.struct
-- Logs a structured message at a runtime-selected level
do
  lurek.log.struct("info", "enemy spawned", {
    enemy_type = "goblin",
    x = 240,
    y = 96,
    hp = 30,
  })
end

--@api-stub: lurek.log.debug_fields
-- Logs a debug message with structured fields
do
  local dt = 0.01666
  lurek.log.debug_fields("frame", {
    dt_ms = dt * 1000,
    draw_calls = 42,
    entities = 128,
  })
end

--@api-stub: lurek.log.info_fields
-- Logs an info message with structured fields
do
  lurek.log.info_fields("checkpoint reached", {
    checkpoint = "forest_clearing",
    play_time_s = 1842,
    deaths = 3,
  })
end

--@api-stub: lurek.log.warn_fields
-- Logs a warning message with structured fields
do
  local fps, target = 28, 60
  if fps < target * 0.8 then
    lurek.log.warn_fields("frame rate dropped", {
      fps = fps,
      target = target,
      scene = "boss_arena",
    })
  end
end

--@api-stub: lurek.log.error_fields
-- Logs an error message with structured fields
do
  lurek.log.error_fields("save failed", {
    operation = "write",
    path = "save/slot1.dat",
    reason = "disk full",
    bytes_attempted = 4096,
  })
end
-- content/examples/log.lua
-- EXAMPLEed coverage of the lurek.log API (18 items).
--
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/log_api.rs   (Lua binding, arg types, return shape)
--   * src/log/                 (semantics, side effects)
--   * docs/specs/log.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.draw() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/log.lua

-- lurek.log.* functions
