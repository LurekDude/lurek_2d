-- content/examples/system.lua
-- lurek.runtime and lurek.engine API examples.
-- Run: cargo run -- content/examples/system.lua

--@api-stub: lurek.runtime.getOS
-- Returns the name of the host operating system as a string
do
  local os_name = lurek.runtime.getOS()
  -- Use the OS name to pick platform-appropriate keybinds
  local mod_key = (os_name == "macOS") and "cmd" or "ctrl"
  lurek.log.info("running on " .. os_name .. " (modifier=" .. mod_key .. ")", "boot")
end

--@api-stub: lurek.runtime.getVersion
-- Returns the semantic version string of the Lurek2D engine
do
  local engine_version = lurek.runtime.getVersion()
  -- Embed the engine version in save file headers to detect incompatibility
  local save_header = "lurek2d/" .. engine_version
  lurek.log.info("save header tag: " .. save_header, "save")
end

--@api-stub: lurek.runtime.getProcessorCount
-- Returns the number of logical processors available on the host machine
do
  local cores = lurek.runtime.getProcessorCount()
  -- Reserve one core for the main thread, use the rest for workers
  local workers = math.max(1, cores - 1)
  lurek.log.info("spawning " .. workers .. " worker threads (of " .. cores .. ")", "thread")
end

--@api-stub: lurek.runtime.getMemorySize
-- Returns the total physical memory of the host system in megabytes
do
  local ram_mb = lurek.runtime.getMemorySize()
  -- Auto-detect texture quality based on available RAM
  local quality = (ram_mb >= 8192) and "high" or (ram_mb >= 4096 and "medium" or "low")
  lurek.log.info("texture quality preset: " .. quality .. " (" .. ram_mb .. " MiB RAM)", "render")
end

--@api-stub: lurek.runtime.openURL
-- Opens a URL in the default system browser (non-headless; do not call in automated tests)
do
  local credits_url = "https://lurek2d.example/credits"
  -- Only http/https/mailto schemes are allowed; returns false on failure
  -- Verify the function exists without calling it (non-headless operation)
  assert(type(lurek.runtime.openURL) == "function", "openURL must be a function")
  lurek.log.info("openURL available for: " .. credits_url, "system")
end

--@api-stub: lurek.runtime.getPreferredLocales
-- Returns a list of the user's preferred locale identifiers from the operating system
do
  local locales = lurek.runtime.getPreferredLocales()
  -- Use the first locale as the default; fall back to en_US if empty
  local picked = locales[1] or "en_US"
  lurek.log.info("ui locale = " .. picked .. " (offered " .. #locales .. ")", "i18n")
end

--@api-stub: lurek.runtime.getPowerInfo
-- Returns the current power supply state, battery percentage, and estimated time remaining
do
  local state, percent, _seconds = lurek.runtime.getPowerInfo()
  -- Cap FPS on battery with low charge to save power
  local fps_cap = (state == "battery" and (percent or 100) < 30) and 30 or 60
  lurek.log.info("power=" .. state .. " fps_cap=" .. fps_cap, "perf")
end

--@api-stub: lurek.runtime.getInfo
-- Returns a table with comprehensive engine and host information
do
  local info = lurek.runtime.getInfo()
  -- info contains: engine, version, lua_version, renderer, os, processors, memory
  local line = info.engine .. " " .. info.version .. " on " .. info.os ..
    " (" .. info.processors .. " cores, " .. info.memory .. " MiB)"
  lurek.log.info(line, "boot")
end

--@api-stub: lurek.runtime.getMessage
-- Resolves a message string by its identifier from the engine message catalog
do
  local message_id = "L001"
  -- Look up a localised engine message by its identifier code
  local text = lurek.runtime.getMessage(message_id)
  lurek.log.info(message_id .. ": " .. text, "i18n")
end

--@api-stub: lurek.runtime.hasMessage
-- Checks whether a message identifier exists in the engine message catalog
do
  local candidate = "L999"
  -- Check existence before resolving to avoid nil errors
  if lurek.runtime.hasMessage(candidate) then
    lurek.log.info("catalogue has " .. candidate, "i18n")
  else
    lurek.log.warn("missing message id: " .. candidate, "i18n")
  end
end

--@api-stub: lurek.runtime.getMessageCount
-- Returns the total number of messages registered in the engine message catalog
do
  local n = lurek.runtime.getMessageCount()
  -- Guard against an empty catalogue at startup
  if n < 1 then
    lurek.log.warn("message catalogue is empty", "i18n")
  end
  lurek.log.info("loaded " .. n .. " runtime messages", "i18n")
end

--@api-stub: lurek.runtime.setClipboardText
-- Copies a string to the system clipboard
do
  local seed = "world-seed-4815162342"
  -- Let the player share their world seed by copying it to clipboard
  lurek.runtime.setClipboardText(seed)
  lurek.log.info("copied seed to clipboard: " .. seed, "ui")
end

--@api-stub: lurek.runtime.getClipboardText
-- Reads the current text content from the system clipboard
do
  local raw = lurek.runtime.getClipboardText()
  -- Trim whitespace from pasted input before processing
  local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
  if #trimmed > 0 then
    lurek.log.info("clipboard payload: '" .. trimmed .. "'", "ui")
  end
end

--@api-stub: lurek.runtime.setDebugOverlay
-- Enables or disables the on-screen debug overlay that shows FPS, draw calls, and other diagnostics
do
  -- Toggle the built-in debug overlay on game start for development builds
  lurek.runtime.setDebugOverlay(true)
  lurek.log.info("debug overlay enabled at startup", "dev")
end

--@api-stub: lurek.runtime.getDebugOverlay
-- Returns whether the on-screen debug overlay is currently enabled
do
  -- Skip drawing a custom FPS counter if the engine overlay is already active
  if lurek.runtime.getDebugOverlay() then
    lurek.log.debug("engine overlay is on, skipping custom HUD", "dev")
  end
end

--@api-stub: lurek.runtime.setLogLevel
-- Sets the engine-wide log verbosity level at runtime
do
  -- Reduce log noise after initialization completes
  local desired_level = "info"
  lurek.runtime.setLogLevel(desired_level)
  lurek.log.info("log level set to " .. desired_level, "boot")
end

--@api-stub: lurek.runtime.getLogLevel
-- Returns the current engine log verbosity level as a string
do
  local level = lurek.runtime.getLogLevel()
  -- Warn developers when debug logging is active (produces large logs)
  if level == "debug" then
    lurek.log.warn("log level is debug - output will be very chatty", "boot")
  end
end

--@api-stub: lurek.runtime.log
-- Writes a message to the engine log at the specified severity level
do
  -- Use runtime.log for severity-specific messages without lurek.log wrappers
  local severity = "warn"
  local frame_ms = 22.5
  lurek.runtime.log(severity, "frame budget exceeded: " .. frame_ms .. " ms")
end

--@api-stub: lurek.runtime.getLastError
-- Returns the last error for Lua scripts in this module
do
  -- Poll for Lua-side errors in the update loop for custom error display
  local err = lurek.runtime.getLastError()
  if err then
    lurek.log.error("[" .. err.code .. "] " .. err.message, err.category)
  end
end

--@api-stub: lurek.runtime.errorSnapshot
-- Creates a JSON-encoded error snapshot from a message string, useful for diagnostics and error reporting
do
  local raw_error = "asset not found: hero.png"
  -- Capture a structured snapshot with stack info for crash reporting
  local json = lurek.runtime.errorSnapshot(raw_error)
  lurek.log.error("crash snapshot: " .. json, "crash")
end

--@api-stub: lurek.runtime.getArch
-- Returns the CPU architecture of the host system
do
  local arch = lurek.runtime.getArch()
  -- Detect ARM for SIMD strategy selection
  local use_neon = (arch == "aarch64") or (arch == "arm64")
  lurek.log.info("arch=" .. arch .. " neon=" .. tostring(use_neon), "boot")
end

--@api-stub: lurek.runtime.getEnv
-- Reads an environment variable by name
do
  -- Check for a developer-set environment variable to toggle profiling
  local profile_flag = lurek.runtime.getEnv("LUREK_PROFILE")
  if profile_flag == "1" then
    lurek.log.info("profiling mode enabled via LUREK_PROFILE", "dev")
  end
end

--@api-stub: lurek.runtime.getArgs
-- Returns the command-line arguments passed to the engine as a 1-indexed table of strings
do
  local args = lurek.runtime.getArgs()
  -- Skip argv[1] (the script path) and iterate user-supplied arguments
  for i = 2, #args do
    lurek.log.info("argv[" .. i .. "] = " .. args[i], "boot")
  end
end

--@api-stub: lurek.runtime.parseArgs
-- Parses command-line arguments into structured flags, options, and positional values
do
  local input = { "--level=forest_01", "--debug", "save1.dat" }
  -- parseArgs splits into flags (booleans), options (key=value), positional (rest)
  local parsed = lurek.runtime.parseArgs(input)
  local level = parsed.options.level or "intro"
  local debug_on = parsed.flags.debug == true
  lurek.log.info("level=" .. level .. " debug=" .. tostring(debug_on), "boot")
end

--@api-stub: lurek.runtime.runBatch
-- Executes a table of named task functions sequentially, collecting pass/fail results and elapsed time for each
do
  local tasks = {
    warmup_cache = function() return true end,
    preload_audio = function() return true end,
  }
  -- stopOnError skips remaining tasks after the first failure
  local results = lurek.runtime.runBatch(tasks, { stopOnError = true })
  local warmup_result = results["warmup_cache"]
  lurek.log.info("batch completed: warmup=" .. warmup_result.status, "boot")
end

--@api-stub: lurek.runtime.reloadConfig
-- Requests a reload of the engine configuration from conf.lua (deferred until next frame)
do
  -- Trigger a hot-reload of conf.toml to pick up changed settings
  lurek.log.info("requesting conf.toml hot-reload", "dev")
  lurek.runtime.reloadConfig()
end

--@api-stub: lurek.runtime.getConfig
-- Returns a table containing the current engine runtime configuration values
do
  local cfg = lurek.runtime.getConfig()
  -- The config table reflects conf.toml fields: physics rate, vsync, log level, etc.
  lurek.log.info(
    ("config rev=%d physics=%.0f Hz vsync=%s level=%s"):format(
      cfg.config_reload_revision,
      cfg.physics_tick_rate,
      tostring(cfg.vsync),
      cfg.log_level
    ),
    "boot"
  )
  if cfg.frame_budget_warn_ms then
    lurek.log.info("frame budget warn threshold: " .. cfg.frame_budget_warn_ms .. " ms", "perf")
  end
end

--@api-stub: lurek.runtime.getBatchResults
-- Summarizes batch results by counting passed, failed, and skipped tasks
do
  local results = lurek.runtime.runBatch({
    ok_task = function() return true end,
    bad_task = function() error("intentional") end,
  })
  -- Quickly tally the batch outcome without iterating the full results table
  local passed, failed, skipped = lurek.runtime.getBatchResults(results)
  lurek.log.info("batch tally passed=" .. passed .. " failed=" .. failed .. " skipped=" .. skipped, "boot")
end

--@api-stub: lurek.engine.fps
-- Returns the latest frames-per-second value stored by the runtime
do
  local current_fps = lurek.engine.fps()
  -- Use the FPS reading to toggle quality dynamically
  if current_fps < 30 then
    lurek.log.warn("FPS below threshold: " .. current_fps, "perf")
  end
end

--@api-stub: lurek.engine.frameCount
-- Returns the number of frames counted by the shared runtime clock
do
  local frames = lurek.engine.frameCount()
  -- Run expensive work only every 60 frames (roughly once per second at 60 FPS)
  if frames % 60 == 0 then
    lurek.log.debug("periodic check at frame " .. frames, "perf")
  end
end

--@api-stub: lurek.engine.getConfigRevision
-- Returns the configuration reload revision counter
do
  local rev = lurek.engine.getConfigRevision()
  -- Detect when the config was hot-reloaded since last check
  lurek.log.info("config revision: " .. rev, "boot")
end

--@api-stub: lurek.engine.getFrameBudget
-- Returns the target frame budget for a 60 FPS update loop
do
  local budget_ms = lurek.engine.getFrameBudget()
  -- Compare actual frame time against the budget to detect jank
  lurek.log.info("frame budget: " .. budget_ms .. " ms", "perf")
end

--@api-stub: lurek.engine.getFrameProfile
-- Returns the latest frame timing profile split by engine phase
do
  local profile = lurek.engine.getFrameProfile()
  -- profile is a table of phase timings in milliseconds
  for phase, ms in pairs(profile) do
    if ms > 5.0 then
      lurek.log.warn("slow phase: " .. phase .. " = " .. ms .. " ms", "perf")
    end
  end
end

--@api-stub: lurek.engine.getFrameProfileText
-- Returns the latest frame timing profile formatted as one text line
do
  local text = lurek.engine.getFrameProfileText()
  -- Display the full profile summary in one line (useful for on-screen debug)
  lurek.log.info(text, "perf")
end

--@api-stub: lurek.engine.getResourceStats
-- Returns current resource memory usage and object counts by resource kind
do
  local stats = lurek.engine.getResourceStats()
  -- stats contains byte totals, budget, and texture/font/canvas/shader counts
  lurek.log.info(
    ("resources: textures=%d fonts=%d usage=%d/%d bytes"):format(
      stats.texture_count or 0,
      stats.font_count or 0,
      stats.total_bytes or 0,
      stats.budget_bytes or 0
    ),
    "perf"
  )
end

--@api-stub: lurek.runtime.getVersion
-- Returns the engine crate version string embedded at build time
do
  local version = lurek.engine.getVersion()
  -- Use engine.getVersion for the Cargo.toml version (vs runtime.getVersion for semver)
  lurek.log.info("engine crate version: " .. version, "boot")
end

--@api-stub: lurek.engine.isDebug
-- Returns whether the engine binary was built with debug assertions
do
  local debug_build = lurek.engine.isDebug()
  -- Enable extra validation only in debug builds to avoid performance cost
  if debug_build then
    lurek.log.info("debug build: extra asserts are active", "dev")
  end
end

--@api-stub: lurek.engine.memoryUsage
-- Returns Lua VM memory usage as bytes and rounded kilobytes
do
  local mem = lurek.engine.memoryUsage()
  -- Monitor Lua heap size to catch memory leaks in scripts
  lurek.log.info("lua memory: " .. mem.lua_kb .. " KB (" .. mem.lua_bytes .. " bytes)", "perf")
end

--@api-stub: lurek.engine.platform
-- Returns the current desktop operating system name
do
  local plat = lurek.engine.platform()
  -- Pick platform-specific asset paths or defaults
  local config_dir = (plat == "windows") and "%APPDATA%/mygame" or "~/.config/mygame"
  lurek.log.info("platform=" .. plat .. " config_dir=" .. config_dir, "boot")
end

--@api-stub: lurek.engine.setResourceBudget
-- Sets the resource memory budget used by resource statistics reporting
do
  -- Set a 256 MB resource budget; getResourceStats will report usage against this
  local budget = 256 * 1024 * 1024
  lurek.engine.setResourceBudget(budget)
  lurek.log.info("resource budget set to " .. (budget / 1024 / 1024) .. " MB", "perf")
end

--@api-stub: lurek.engine.uptime
-- Returns total engine runtime accumulated by the main loop
do
  local seconds = lurek.engine.uptime()
  -- Show how long the engine has been running (useful for session length tracking)
  local minutes = math.floor(seconds / 60)
  lurek.log.info("engine uptime: " .. minutes .. " min (" .. ("%.1f"):format(seconds) .. " s)", "perf")
end

print("content/examples/system.lua")
