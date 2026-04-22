-- content/examples/log.lua
-- Hand-written coverage of the lurek.log API (18 items).
--
-- Every --@api-stub: block below is a real love2d-wiki-style snippet
-- showing how to call the API in actual game context. The `tag`
-- parameter (where present) groups messages by subsystem so log
-- viewers can filter; messages themselves are plain strings, so
-- concatenate values in with `..` rather than passing extra args.
--
-- Run: cargo run -- content/examples/log.lua

-- ── lurek.log.* functions ──

--@api-stub: lurek.log.debug
-- Emits a debug-severity log message.
-- Use for hot per-frame traces that should be silenced in shipping builds via setLevel("info").
do  -- lurek.log.debug
  local player = { x = 128.5, y = 64.0 }
  lurek.log.debug("player pos x=" .. player.x .. " y=" .. player.y, "movement")
end

--@api-stub: lurek.log.info
-- Emits an info-severity log message.
-- Use for one-shot lifecycle events: level loaded, save written, network connected.
do  -- lurek.log.info
  local level_name = "forest_01"
  local entity_count = 47
  lurek.log.info("loaded level '" .. level_name .. "' with " .. entity_count .. " entities", "scene")
end

--@api-stub: lurek.log.warn
-- Emits a warn-severity log message.
-- Use for recoverable problems the player might notice: missing asset fallback, low FPS, etc.
do  -- lurek.log.warn
  local hp = 5
  if hp < 10 then
    lurek.log.warn("player hp critical: " .. hp, "combat")
  end
end

--@api-stub: lurek.log.error
-- Emits an error-severity log message.
-- Use when an operation failed and a fallback was taken; reserve panics for truly unrecoverable state.
do  -- lurek.log.error
  local asset_path = "sfx/missing_jump.ogg"
  lurek.log.error("failed to load audio asset: " .. asset_path .. " (using silent fallback)", "audio")
end

--@api-stub: lurek.log.print
-- Emits a log message at the specified level.
-- Use when the level is computed (e.g. from config) instead of hard-coded; "warning" is accepted alongside "warn".
do  -- lurek.log.print
  local severity = "warn"
  local fps = 28
  lurek.log.print(severity, "frame rate dipped to " .. fps, "perf")
end

--@api-stub: lurek.log.setLevel
-- Sets the minimum severity level for the default log channel.
-- Call once at startup; passing an unknown level raises an error, so validate config before calling.
do  -- lurek.log.setLevel
  local in_release = true
  lurek.log.setLevel(in_release and "info" or "debug")
  lurek.log.debug("this is filtered out in release builds", "boot")
  lurek.log.info("logging configured", "boot")
end

--@api-stub: lurek.log.getLevel
-- Returns the name of the currently active minimum log level.
-- Branch on the result to skip expensive tostring/serialisation work that would be filtered anyway.
do  -- lurek.log.getLevel
  local current = lurek.log.getLevel()
  if current == "debug" or current == "trace" then
    local snapshot = "entities=124 frame=8421 mem=12MB"
    lurek.log.debug("frame snapshot: " .. snapshot, "diag")
  end
end

--@api-stub: lurek.log.addSink
-- Registers a new output sink; returns its numeric id.
-- Capture the returned id at startup so you can later removeSink / readMemory / flushFile it.
do  -- lurek.log.addSink
  local mem_id = lurek.log.addSink({ type = "memory", capacity = 256, level = "warn" })
  local file_id = lurek.log.addSink({ type = "file", path = "save/session.log", level = "info" })
  lurek.log.warn("session started, mem sink=" .. mem_id .. " file sink=" .. file_id, "boot")
end

--@api-stub: lurek.log.removeSink
-- Removes a sink by id; returns true if one was removed.
-- Pair every addSink with a removeSink on shutdown / scene change so file handles do not linger.
do  -- lurek.log.removeSink
  local sink_id = lurek.log.addSink({ type = "memory", capacity = 64 })
  lurek.log.info("temporary diagnostics enabled", "diag")
  local removed = lurek.log.removeSink(sink_id)
  lurek.log.info("diagnostics removed=" .. tostring(removed), "diag")
end

--@api-stub: lurek.log.clearSinks
-- Removes all registered sinks (the default stderr channel is unaffected).
-- Useful in tests and at scene boundaries to reset the sink registry without tracking individual ids.
do  -- lurek.log.clearSinks
  lurek.log.addSink({ type = "memory", capacity = 32 })
  lurek.log.addSink({ type = "memory", capacity = 32, level = "error" })
  lurek.log.clearSinks()
  lurek.log.info("sinks cleared; stderr still active", "boot")
end

--@api-stub: lurek.log.listSinks
-- Returns a table describing all registered sinks.
-- Iterate the result to render an in-game debug overlay or to assert sink wiring in tests.
do  -- lurek.log.listSinks
  lurek.log.addSink({ type = "memory", capacity = 100, level = "info" })
  local sinks = lurek.log.listSinks()
  for _, s in ipairs(sinks) do
    lurek.log.info("sink #" .. s.id .. " type=" .. s.type .. " level=" .. s.level, "diag")
  end
end

--@api-stub: lurek.log.readMemory
-- Reads entries from a memory sink; if drain=true the buffer is cleared.
-- Use this to surface recent warnings inside an in-game console or to ship the buffer with a crash report.
do  -- lurek.log.readMemory
  local mem_id = lurek.log.addSink({ type = "memory", capacity = 16, level = "warn" })
  lurek.log.warn("collision spike on enemy 7", "physics")
  local entries = lurek.log.readMemory(mem_id, true)
  for _, e in ipairs(entries or {}) do
    print("[" .. e.level .. "][" .. e.tag .. "] " .. e.message)
  end
end

--@api-stub: lurek.log.flushFile
-- Flushes the OS write buffer for a file sink.
-- Call right before a controlled shutdown or after writing a crash report so the disk copy is complete.
do  -- lurek.log.flushFile
  local file_id = lurek.log.addSink({ type = "file", path = "save/crash.log", level = "error" })
  lurek.log.error("uncaught script error: nil player.body", "panic")
  lurek.log.flushFile(file_id)
end

--@api-stub: lurek.log.struct
-- Emits a structured log message with key-value fields.
-- Prefer this over string concatenation when downstream tooling parses the log; values are stringified.
do  -- lurek.log.struct
  lurek.log.struct("info", "enemy spawned", {
    enemy_type = "goblin",
    x = 240,
    y = 96,
    hp = 30,
  })
end

--@api-stub: lurek.log.debug_fields
-- Emits a debug structured log message; shorthand for struct("debug", ...).
-- Use for high-frequency structured traces (per-frame sampling) that you want to filter out in release.
do  -- lurek.log.debug_fields
  local dt = 0.01666
  lurek.log.debug_fields("frame", {
    dt_ms = dt * 1000,
    draw_calls = 42,
    entities = 128,
  })
end

--@api-stub: lurek.log.info_fields
-- Emits an info structured log message; shorthand for struct("info", ...).
-- Use for one-shot structured events worth keeping in shipping logs (saves, level loads, transactions).
do  -- lurek.log.info_fields
  lurek.log.info_fields("checkpoint reached", {
    checkpoint = "forest_clearing",
    play_time_s = 1842,
    deaths = 3,
  })
end

--@api-stub: lurek.log.warn_fields
-- Emits a warn structured log message; shorthand for struct("warn", ...).
-- Use when a measurable threshold is crossed so dashboards can chart value against limit.
do  -- lurek.log.warn_fields
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
-- Emits an error structured log message; shorthand for struct("error", ...).
-- Use to capture the full failure context (operation, path, errno) so post-mortem analysis is possible.
do  -- lurek.log.error_fields
  lurek.log.error_fields("save failed", {
    operation = "write",
    path = "save/slot1.dat",
    reason = "disk full",
    bytes_attempted = 4096,
  })
end
-- content/examples/log.lua
-- Scaffolded coverage of the lurek.log API (18 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/log_api.rs   (Lua binding, arg types, return shape)
--   * src/log/                 (semantics, side effects)
--   * docs/specs/log.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/log.lua

-- ── lurek.log.* functions ──
