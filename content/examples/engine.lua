-- content/examples/engine.lua
-- Hand-written coverage of the lurek.engine API (10 items).
--
-- The lurek.engine namespace exposes read-only runtime introspection
-- (version, platform, uptime, fps, frame budget, memory) plus the
-- texture-memory budget knob. All getters are cheap and safe to call
-- every frame; setResourceBudget is a one-shot startup configuration.
--
-- Run: cargo run -- content/examples/engine.lua

-- -- lurek.engine.* functions --

--@api-stub: lurek.engine.getVersion
-- Returns the engine version string (from `Cargo.toml`).
-- Stamp the version into save files and crash logs so old saves can branch on schema differences.
do -- lurek.engine.getVersion
  local version = lurek.engine.getVersion()
  local save_header = { engine = version, schema = 3, ts = os.time() }
  lurek.log.info("save header engine=" .. save_header.engine, "save")
end

--@api-stub: lurek.engine.getFrameBudget
-- Returns the target frame budget in milliseconds (default: 1000 / 60 ~= 16.667 ms).
-- Compare your measured frame time against this to decide when to skip optional per-frame work.
do -- lurek.engine.getFrameBudget
  local budget_ms = lurek.engine.getFrameBudget()
  local headroom_ms = budget_ms * 0.5
  function lurek.process(dt)
    if dt * 1000 > headroom_ms then
      lurek.log.warn("frame over half-budget: " .. (dt * 1000) .. "ms / " .. budget_ms, "perf")
    end
  end
end

--@api-stub: lurek.engine.memoryUsage
-- Returns a table with `lua_bytes` (Lua GC heap usage in bytes) and `lua_kb` (kilobytes).
-- Sample once per second rather than every frame; spikes between samples indicate per-frame allocation churn.
do -- lurek.engine.memoryUsage
  local accum = 0
  function lurek.process(dt)
    accum = accum + dt
    if accum >= 1.0 then
      accum = 0
      local mem = lurek.engine.memoryUsage()
      lurek.log.debug("lua heap=" .. mem.lua_kb .. "KB (" .. mem.lua_bytes .. " bytes)", "mem")
    end
  end
end

--@api-stub: lurek.engine.platform
-- Returns a string identifying the host operating system: `"windows"`, `"linux"`, or `"macos"`.
-- Use to pick platform-specific paths or hotkeys; compare against the literal strings, never substrings.
do -- lurek.engine.platform
  local os_name = lurek.engine.platform()
  local quit_hint = (os_name == "macos") and "Cmd+Q to quit" or "Alt+F4 to quit"
  lurek.log.info("running on " .. os_name .. " - " .. quit_hint, "boot")
end

--@api-stub: lurek.engine.uptime
-- Returns the total engine uptime in seconds (sum of all processed deltas).
-- Prefer this over os.time() for in-game timers - it pauses with the engine and survives wall-clock changes.
do -- lurek.engine.uptime
  local session_start = lurek.engine.uptime()
  function lurek.quit()
    local played = lurek.engine.uptime() - session_start
    lurek.log.info("session lasted " .. string.format("%.1f", played) .. "s", "session")
  end
end

--@api-stub: lurek.engine.fps
-- Returns the current measured frames-per-second.
-- Read every frame for a HUD overlay; it is already smoothed by the engine, no extra averaging needed.
do -- lurek.engine.fps
  local font
  function lurek.init() font = lurek.render.newFont(14) end
  function lurek.draw_ui()
    local fps = lurek.engine.fps()
    lurek.render.setFont(font)
    lurek.render.setColor(1, 1, 0, 1)
    lurek.render.print(string.format("FPS: %.0f", fps), 8, 8)
  end
end

--@api-stub: lurek.engine.frameCount
-- Returns the total number of frames processed since engine start.
-- Use as a cheap monotonic tick for "do work every N frames" scheduling without floating-point drift.
do -- lurek.engine.frameCount
  function lurek.process(_)
    if lurek.engine.frameCount() % 600 == 0 then
      lurek.log.info("autosave tick at frame " .. lurek.engine.frameCount(), "save")
    end
  end
end

--@api-stub: lurek.engine.isDebug
-- Returns `true` if the engine was compiled in debug mode.
-- Gate expensive validation, asserts, and on-screen debug overlays so they are stripped from release builds.
do -- lurek.engine.isDebug
  if lurek.engine.isDebug() then
    lurek.log.setLevel("debug")
    lurek.log.debug("debug build - verbose logging enabled", "boot")
  else
    lurek.log.setLevel("info")
  end
end

--@api-stub: lurek.engine.setResourceBudget
-- Sets the maximum resident texture memory budget in bytes; `0` disables the budget.
-- Set once at startup based on platform; pass 0 on desktop with plenty of VRAM, lower on integrated GPUs.
do -- lurek.engine.setResourceBudget
  local mb = 256
  lurek.engine.setResourceBudget(mb * 1024 * 1024)
  lurek.log.info("texture budget set to " .. mb .. " MB", "boot")
end

--@api-stub: lurek.engine.getResourceStats
-- Returns a table with `texture_bytes`, `budget_bytes`, and `texture_count`.
-- Watch the ratio texture_bytes/budget_bytes; sustained >0.9 means you are about to evict useful textures.
do -- lurek.engine.getResourceStats
  function lurek.process(_)
    if lurek.engine.frameCount() % 300 ~= 0 then return end
    local stats = lurek.engine.getResourceStats()
    local mb = stats.total_bytes / (1024 * 1024)
    lurek.log.debug(string.format("tex=%d font=%d canvas=%d total=%.2fMB", stats.texture_count, stats.font_count, stats.canvas_count, mb), "mem")
  end
end

--@api-stub: lurek.engine.getFrameProfile
-- Returns per-callback CPU timing for the last completed frame.
-- Use this to locate expensive callbacks before reaching for external profilers.
do -- lurek.engine.getFrameProfile
  function lurek.draw_ui()
    local p = lurek.engine.getFrameProfile()
    lurek.render.print(string.format("tick=%.2fms process=%.2fms draw=%.2fms", p.app_tick_ms, p.process_ms, p.draw_ms), 8, 28)
  end
end

--@api-stub: lurek.engine.getFrameProfileText
-- Returns one compact text line with the latest frame timing buckets.
-- Useful for low-overhead HUD debugging when you do not need table fields.
do -- lurek.engine.getFrameProfileText
  function lurek.draw_ui()
    lurek.render.print(lurek.engine.getFrameProfileText(), 8, 46)
  end
end

--@api-stub: lurek.engine.getConfigRevision
-- Returns a monotonic counter that increments after `conf.toml` hot-reload.
-- Cache this value to refresh gameplay knobs only when config actually changes.
do -- lurek.engine.getConfigRevision
  local last = lurek.engine.getConfigRevision()
  function lurek.process(_)
    local now = lurek.engine.getConfigRevision()
    if now ~= last then
      last = now
      lurek.log.info("config revision changed to " .. now, "boot")
    end
  end
end
-- content/examples/engine.lua
-- EXAMPLEed coverage of the lurek.engine API (10 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/engine_api.rs   (Lua binding, arg types, return shape)
--   * src/engine/                 (semantics, side effects)
--   * docs/specs/engine.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.draw() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/engine.lua

-- â”€â”€ lurek.engine.* functions â”€â”€
