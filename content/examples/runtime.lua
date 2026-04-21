-- content/examples/runtime.lua
-- Lurek2D lurek.runtime API Reference
-- Run with: cargo run -- content/examples/engine

-- =============================================================================
-- lurek.runtime — Engine introspection and runtime diagnostics
--
-- This module exposes read-only queries about the running engine: version,
-- platform, frame timing, memory usage, and resource budgets.  Use it to build
-- debug overlays, adaptive quality settings, and "about" screens.
-- =============================================================================

-- ---- Stub: lurek.runtime.getVersion ---------------------------------------
--@api-stub: lurek.runtime.getVersion
-- Display the engine version on a title screen or debug overlay so players
-- and testers always know which build they are running.
local version = lurek.runtime.getVersion()
print("Lurek2D engine version: " .. version)
-- Typically shown in a corner of the title screen:
-- lurek.render.print("v" .. version, screen_w - 100, screen_h - 20)

-- ---- Stub: lurek.runtime.getFrameBudget -----------------------------------
--@api-stub: lurek.runtime.getFrameBudget
-- Read the target frame budget to decide whether to enable expensive visual
-- effects.  At 60 FPS the budget is ~16.67 ms; at 30 FPS it is ~33.33 ms.
local budget_ms = lurek.runtime.getFrameBudget()
print("frame budget: " .. string.format("%.2f ms", budget_ms))
local enable_particles = budget_ms >= 16.0
print("particle effects enabled: " .. tostring(enable_particles))

-- ---- Stub: lurek.runtime.memoryUsage --------------------------------------
--@api-stub: lurek.runtime.memoryUsage
-- Query Lua and engine heap usage to show in a developer console.  This helps
-- detect memory leaks during extended play sessions.
local mem = lurek.runtime.memoryUsage()
local lua_kb  = mem.lua_bytes / 1024
print(string.format("Lua heap:    %.1f KB", lua_kb))
if mem.rss_bytes then
    local rss_mb = mem.rss_bytes / (1024 * 1024)
    print(string.format("Process RSS: %.1f MB", rss_mb))
end
-- Warn the player if Lua is using more than 50 MB
if lua_kb > 50 * 1024 then
    print("WARNING: Lua memory exceeds 50 MB -- possible leak")
end

-- ---- Stub: lurek.runtime.platform -----------------------------------------
--@api-stub: lurek.runtime.platform
-- Detect the host OS at runtime to choose platform-specific default paths
-- or enable OS-specific workarounds (e.g. different line endings for logs).
local os_name = lurek.runtime.platform()
print("running on: " .. os_name)

local save_dir
if os_name == "windows" then
    save_dir = "C:/Users/Player/AppData/Local/MyGame/saves"
elseif os_name == "macos" then
    save_dir = "~/Library/Application Support/MyGame/saves"
else
    save_dir = "~/.local/share/MyGame/saves"
end
print("save directory: " .. save_dir)

-- ---- Stub: lurek.runtime.uptime -------------------------------------------
--@api-stub: lurek.runtime.uptime
-- Show total play session length on the pause screen.  uptime() returns the
-- cumulative delta time since engine start, in seconds.
local total_sec = lurek.runtime.uptime()
local minutes   = math.floor(total_sec / 60)
local seconds   = math.floor(total_sec % 60)
print(string.format("session length: %d min %d sec", minutes, seconds))

-- ---- Stub: lurek.runtime.fps ----------------------------------------------
--@api-stub: lurek.runtime.fps
-- Display a live FPS counter in the debug overlay.  When FPS drops below 30
-- the overlay turns red to alert the developer.
local current_fps = lurek.runtime.fps()
print("current FPS: " .. string.format("%.1f", current_fps))
if current_fps < 30 then
    print("PERFORMANCE WARNING: FPS below 30 -- consider reducing draw calls")
elseif current_fps < 55 then
    print("FPS slightly below target -- monitor for dips")
else
    print("FPS is healthy")
end

-- ---- Stub: lurek.runtime.frameCount ---------------------------------------
--@api-stub: lurek.runtime.frameCount
-- Use frameCount to schedule periodic tasks like auto-save every 3600 frames
-- (~60 seconds at 60 FPS) without tracking elapsed time manually.
local frames = lurek.runtime.frameCount()
print("total frames rendered: " .. frames)
local autosave_interval = 3600
if frames % autosave_interval == 0 and frames > 0 then
    print("auto-save triggered at frame " .. frames)
end

-- ---- Stub: lurek.runtime.isDebug ------------------------------------------
--@api-stub: lurek.runtime.isDebug
-- Gate expensive diagnostics behind a debug-build check so release builds
-- skip the overhead entirely.
local debug_build = lurek.runtime.isDebug()
print("debug build: " .. tostring(debug_build))
if debug_build then
    print("  -> collision boxes will be drawn")
    print("  -> frame profiler overlay is available (F3)")
else
    print("  -> release mode: diagnostics disabled")
end

-- ---- Stub: lurek.runtime.setResourceBudget --------------------------------
--@api-stub: lurek.runtime.setResourceBudget
-- Cap texture memory to 256 MB on integrated GPUs so the game does not
-- trigger OS-level memory pressure.  On discrete GPUs, allow 512 MB.
local gpu_budget = 256 * 1024 * 1024   -- 256 MB for integrated GPU
lurek.runtime.setResourceBudget(gpu_budget)
print(string.format("texture budget set to %d MB", gpu_budget / (1024 * 1024)))

-- A high-end path might double the budget:
-- local discrete_budget = 512 * 1024 * 1024
-- lurek.runtime.setResourceBudget(discrete_budget)

-- ---- Stub: lurek.runtime.getResourceStats ---------------------------------
--@api-stub: lurek.runtime.getResourceStats
-- Read resource pool stats to display a memory bar in the debug overlay and
-- warn when nearing the budget cap.
local stats = lurek.runtime.getResourceStats()
print("resource stats:")
if stats.texture_bytes then
    local used_mb  = stats.texture_bytes / (1024 * 1024)
    print(string.format("  textures: %.1f MB resident", used_mb))
end
if stats.texture_count then
    print("  texture slots: " .. stats.texture_count)
end
if stats.font_count then
    print("  font slots:    " .. stats.font_count)
end
-- If usage exceeds 80% of budget, log a warning
if stats.texture_bytes and gpu_budget then
    local pct = stats.texture_bytes / gpu_budget * 100
    if pct > 80 then
        print(string.format("  WARNING: %.0f%% of texture budget used", pct))
    end
end
-- content/examples/runtime.lua
-- Lurek2D lurek.runtime API Reference
-- Run with: cargo run -- content/examples/engine

-- =============================================================================
-- STUBS: 10 uncovered lurek.runtime API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.runtime.getVersion ---------------------------------------
--@api-stub: lurek.runtime.getVersion
-- Returns the engine version string (from `Cargo.toml`).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.getVersion()  -- -> string

-- ---- Stub: lurek.runtime.getFrameBudget -----------------------------------
--@api-stub: lurek.runtime.getFrameBudget
-- Returns the target frame budget in milliseconds (default: 1000 / 60 ≈ 16.667 ms).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.getFrameBudget()  -- -> number

-- ---- Stub: lurek.runtime.memoryUsage --------------------------------------
--@api-stub: lurek.runtime.memoryUsage
-- Returns a table with `lua_bytes` (Lua GC heap usage in bytes) and
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.memoryUsage()  -- -> table

-- ---- Stub: lurek.runtime.platform -----------------------------------------
--@api-stub: lurek.runtime.platform
-- Returns a string identifying the host operating system:
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.platform()  -- -> string

-- ---- Stub: lurek.runtime.uptime -------------------------------------------
--@api-stub: lurek.runtime.uptime
-- Returns the total engine uptime in seconds (sum of all processed deltas).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.uptime()  -- -> number

-- ---- Stub: lurek.runtime.fps ----------------------------------------------
--@api-stub: lurek.runtime.fps
-- Returns the current measured frames-per-second.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.fps()  -- -> number

-- ---- Stub: lurek.runtime.frameCount ---------------------------------------
--@api-stub: lurek.runtime.frameCount
-- Returns the total number of frames processed since engine start.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.frameCount()  -- -> integer

-- ---- Stub: lurek.runtime.isDebug ------------------------------------------
--@api-stub: lurek.runtime.isDebug
-- Returns `true` if the engine was compiled in debug mode.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.isDebug()  -- -> boolean

-- ---- Stub: lurek.runtime.setResourceBudget --------------------------------
--@api-stub: lurek.runtime.setResourceBudget
-- Sets the maximum resident texture memory budget in bytes.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.setResourceBudget(budget_bytes)

-- ---- Stub: lurek.runtime.getResourceStats ---------------------------------
--@api-stub: lurek.runtime.getResourceStats
-- Returns a table with resident resource memory statistics.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.runtime.getResourceStats()  -- -> table
