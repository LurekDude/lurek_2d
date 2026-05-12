-- content/examples/system.lua
-- Hand-written coverage of the lurek.runtime API (28 items).
--
-- Platform queries (OS, CPU, memory, locale, clipboard) plus runtime-message
-- catalogue lookup, debug-overlay toggling, structured logging, and CLI
-- argument parsing. Most calls are safe at file scope; only batch-runner
-- helpers should usually live inside an `init`/`process` callback.
--
-- Run: cargo run -- content/examples/system.lua

-- â”€â”€ lurek.runtime.* functions â”€â”€

-- Guard: lurek.runtime is not registered in the headless test VM.
if not lurek.runtime then return end

local runtime = lurek.runtime

--@api-stub: lurek.runtime.getOS
-- Returns the host operating system name ('Windows', 'Linux', 'macOS').
-- Branch on this at startup to pick platform-specific asset paths or hot-keys.
do -- lurek.runtime.getOS
  local os_name = runtime.getOS()
  local mod_key = (os_name == "macOS") and "cmd" or "ctrl"
  lurek.log.info("running on " .. os_name .. " (modifier=" .. mod_key .. ")", "boot")
end

--@api-stub: lurek.runtime.getVersion
-- Returns the Lurek2D engine version string.
-- Stamp this into save files and crash reports so old saves can be migrated safely.
do -- lurek.runtime.getVersion
  local engine_version = runtime.getVersion()
  local save_header = "lurek2d/" .. engine_version
  lurek.log.info("save header tag: " .. save_header, "save")
end

--@api-stub: lurek.runtime.getProcessorCount
-- Returns the number of logical CPU cores available.
-- Use to size worker-thread pools; reserve at least one core for the main loop.
do -- lurek.runtime.getProcessorCount
  local cores = runtime.getProcessorCount()
  local workers = math.max(1, cores - 1)
  lurek.log.info("spawning " .. workers .. " worker threads (of " .. cores .. ")", "thread")
end

--@api-stub: lurek.runtime.getMemorySize
-- Returns the total amount of installed system RAM in megabytes.
-- Pick a texture-quality preset based on installed RAM rather than guessing.
do -- lurek.runtime.getMemorySize
  local ram_mb = runtime.getMemorySize()
  local quality = (ram_mb >= 8192) and "high" or (ram_mb >= 4096 and "medium" or "low")
  lurek.log.info("texture quality preset: " .. quality .. " (" .. ram_mb .. " MiB RAM)", "render")
end

--@api-stub: lurek.runtime.openURL
-- Opens a URL in the system's default browser.
-- Only http/https/mailto schemes are accepted; the call returns false if rejected.
do -- lurek.runtime.openURL
  local credits_url = "https://lurek2d.example/credits"
  local opened = runtime.openURL(credits_url)
  if not opened then
    lurek.log.warn("could not open credits URL: " .. credits_url, "ui")
  end
end

--@api-stub: lurek.runtime.getPreferredLocales
-- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
-- Walk the list and stop at the first locale your translations actually support.
do -- lurek.runtime.getPreferredLocales
  local locales = runtime.getPreferredLocales()
  local picked = locales[1] or "en_US"
  lurek.log.info("ui locale = " .. picked .. " (offered " .. #locales .. ")", "i18n")
end

--@api-stub: lurek.runtime.getPowerInfo
-- Returns battery state, percentage charged, and estimated time remaining.
-- On laptops, drop the frame cap when on battery to extend playtime.
do -- lurek.runtime.getPowerInfo
  local state, percent, _seconds = runtime.getPowerInfo()
  local fps_cap = (state == "battery" and (percent or 100) < 30) and 30 or 60
  lurek.log.info("power=" .. state .. " fps_cap=" .. fps_cap, "perf")
end

--@api-stub: lurek.runtime.getInfo
-- Returns a table of system information including OS name, CPU model, and installed RAM.
-- Dump this once at startup so bug reports include the full host fingerprint.
do -- lurek.runtime.getInfo
  local info = runtime.getInfo()
  local line = info.engine .. " " .. info.version .. " on " .. info.os ..
    " (" .. info.processors .. " cores, " .. info.memory .. " MiB)"
  lurek.log.info(line, "boot")
end

--@api-stub: lurek.runtime.getMessage
-- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
-- Prefer message IDs over hard-coded English strings so localisation can swap them.
do -- lurek.runtime.getMessage
  local message_id = "L001"
  local text = runtime.getMessage(message_id)
  lurek.log.info(message_id .. ": " .. text, "i18n")
end

--@api-stub: lurek.runtime.hasMessage
-- Returns true when the runtime message catalog contains the given stable message ID.
-- Guard `getMessage` with `hasMessage` when an ID comes from data that may be stale.
do -- lurek.runtime.hasMessage
  local candidate = "L999"
  if runtime.hasMessage(candidate) then
    lurek.log.info("catalogue has " .. candidate, "i18n")
  else
    lurek.log.warn("missing message id: " .. candidate, "i18n")
  end
end

--@api-stub: lurek.runtime.getMessageCount
-- Returns the total number of message entries loaded into the runtime message catalog.
-- Useful as a smoke check after loading translation packs at startup.
do -- lurek.runtime.getMessageCount
  local n = runtime.getMessageCount()
  if n < 1 then
    lurek.log.warn("message catalogue is empty", "i18n")
  end
  lurek.log.info("loaded " .. n .. " runtime messages", "i18n")
end

--@api-stub: lurek.runtime.setClipboardText
-- Replaces the system clipboard contents with the given string.
-- Pair with a confirmation toast so the player knows the value was copied.
do -- lurek.runtime.setClipboardText
  local seed = "world-seed-4815162342"
  runtime.setClipboardText(seed)
  lurek.log.info("copied seed to clipboard: " .. seed, "ui")
end

--@api-stub: lurek.runtime.getClipboardText
-- Returns the current contents of the system clipboard.
-- Trim whitespace before parsing â€” users often copy a trailing newline.
do -- lurek.runtime.getClipboardText
  local raw = runtime.getClipboardText() or ""
  local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
  if #trimmed > 0 then
    lurek.log.info("clipboard payload: '" .. trimmed .. "'", "ui")
  end
end

--@api-stub: lurek.runtime.setDebugOverlay
-- Shows or hides the FPS/draw-call debug overlay.
-- Bind to a function key in development; never leave it on in shipped builds.
do -- lurek.runtime.setDebugOverlay
  function lurek.init()
    runtime.setDebugOverlay(true)
    lurek.log.info("debug overlay enabled at startup", "dev")
  end
end

--@api-stub: lurek.runtime.getDebugOverlay
-- Returns whether the debug overlay is currently visible.
-- Read this before drawing your own perf HUD so you don't double-render counters.
do -- lurek.runtime.getDebugOverlay
  function lurek.process(_dt)
    if runtime.getDebugOverlay() then
      lurek.log.debug("engine overlay is on, skipping custom HUD", "dev")
    end
  end
end

--@api-stub: lurek.runtime.setLogLevel
-- Sets the minimum severity level for runtime log messages.
-- Read the level from your config file; unknown level names will raise an error.
do -- lurek.runtime.setLogLevel
  local desired_level = "info"
  runtime.setLogLevel(desired_level)
  lurek.log.info("log level set to " .. desired_level, "boot")
end

--@api-stub: lurek.runtime.getLogLevel
-- Returns the name of the current minimum log level for runtime messages.
-- Echo it on the debug overlay so testers can confirm the active filter.
do -- lurek.runtime.getLogLevel
  local level = runtime.getLogLevel()
  if level == "debug" then
    lurek.log.warn("log level is debug â€” output will be very chatty", "boot")
  end
end

--@api-stub: lurek.runtime.log
-- Emit a log message from Lua at the specified level.
-- Use this when the level is dynamic; otherwise prefer lurek.log.info/warn/error.
do -- lurek.runtime.log
  local severity = "warn"
  local frame_ms = 22.5
  runtime.log(severity, "frame budget exceeded: " .. frame_ms .. " ms")
end

--@api-stub: lurek.runtime.getLastError
-- Returns the last unhandled error message, or nil.
-- Drain it once per frame in dev to surface engine errors as in-game toasts.
do -- lurek.runtime.getLastError
  function lurek.process(_dt)
    local err = runtime.getLastError()
    if err then
      lurek.log.error("[" .. err.code .. "] " .. err.message, err.category)
    end
  end
end

--@api-stub: lurek.runtime.errorSnapshot
-- Serialises an engine error message to a compact JSON string.
-- Attach the JSON to crash uploads so the reporter has the full structured error.
do -- lurek.runtime.errorSnapshot
  local raw_error = "asset not found: hero.png"
  local json = runtime.errorSnapshot(raw_error)
  lurek.log.error("crash snapshot: " .. json, "crash")
end

--@api-stub: lurek.runtime.getArch
-- Returns the CPU architecture string for the current machine.
-- Pick SIMD code paths or shader variants based on 'x86_64' vs 'aarch64'.
do -- lurek.runtime.getArch
  local arch = runtime.getArch()
  local use_neon = (arch == "aarch64") or (arch == "arm64")
  lurek.log.info("arch=" .. arch .. " neon=" .. tostring(use_neon), "boot")
end

--@api-stub: lurek.runtime.getEnv
-- Returns the value of an environment variable, or nil if not set.
-- Use for opt-in dev knobs (e.g. LUREK_PROFILE=1) â€” never read secrets here.
do -- lurek.runtime.getEnv
  local profile_flag = runtime.getEnv("LUREK_PROFILE")
  if profile_flag == "1" then
    lurek.log.info("profiling mode enabled via LUREK_PROFILE", "dev")
  end
end

--@api-stub: lurek.runtime.getArgs
-- Returns the command-line arguments as a table.
-- Walk the table to pick up positional inputs like a level path or save slot.
do -- lurek.runtime.getArgs
  local args = runtime.getArgs()
  for i = 2, #args do
    lurek.log.info("argv[" .. i .. "] = " .. args[i], "boot")
  end
end

--@api-stub: lurek.runtime.parseArgs
-- Parses a command-line argument string and returns a structured key/value table.
-- Returns three sub-tables: flags, options (--key=value), and positional.
do -- lurek.runtime.parseArgs
  local input = { "--level=forest_01", "--debug", "save1.dat" }
  local parsed = runtime.parseArgs(input)
  local level = parsed.options.level or "intro"
  local debug_on = parsed.flags.debug == true
  lurek.log.info("level=" .. level .. " debug=" .. tostring(debug_on), "boot")
end

--@api-stub: lurek.runtime.runBatch
-- Runs a list of shell commands in parallel and returns immediately without blocking.
-- Each task is a Lua function; the call is synchronous and returns a results table.
do -- lurek.runtime.runBatch
  local tasks = {
    warmup_cache = function() return true end,
    preload_audio = function() return true end,
  }
  local results = runtime.runBatch(tasks, { stopOnError = true })
  lurek.log.info("batch completed: warmup=" .. results.warmup_cache.status, "boot")
end

--@api-stub: lurek.system.reloadConfig
-- are refreshed without restarting the engine.
do -- lurek.runtime.reloadConfig
  function lurek.init()
    -- Example: a key-bind that forces conf.toml to be re-read immediately.
    lurek.log.info("requesting conf.toml hot-reload", "dev")
    runtime.reloadConfig()
  end
end

--@api-stub: lurek.system.getConfig
-- Returns a snapshot table of the active runtime-mutable configuration values.
-- Fields: physics_tick_rate, fixed_update_tick_rate, frame_budget_warn_ms,
--         vsync, log_level, config_reload_revision.
do -- lurek.runtime.getConfig
  local cfg = runtime.getConfig()
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
-- Returns the output table from the most recently completed runBatch call.
-- Tally the (passed, failed, skipped) trio to gate startup on critical jobs.
do -- lurek.runtime.getBatchResults
  local results = runtime.runBatch({
    ok_task = function() return true end,
    bad_task = function() error("intentional") end,
  })
  local passed, failed, skipped = runtime.getBatchResults(results)
  lurek.log.info("batch tally passed=" .. passed .. " failed=" .. failed .. " skipped=" .. skipped, "boot")
end

-- =============================================================================
-- COVERAGE: 26 uncovered lurek.system API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Example: lurek.system.getOS --------------------------------------------
--@api-stub: lurek.system.getOS
-- Returns the host operating system name ('Windows', 'Linux', 'macOS').
-- lurek.system.getOS()  -- -> string

-- ---- Example: lurek.system.getVersion ---------------------------------------
--@api-stub: lurek.system.getVersion
-- Returns the Lurek2D engine version string.
-- lurek.system.getVersion()  -- -> string

-- ---- Example: lurek.system.getProcessorCount --------------------------------
--@api-stub: lurek.system.getProcessorCount
-- Returns the number of logical CPU cores available.
-- lurek.system.getProcessorCount()  -- -> integer

-- ---- Example: lurek.system.getMemorySize ------------------------------------
--@api-stub: lurek.system.getMemorySize
-- Returns the total amount of installed system RAM in megabytes.
-- lurek.system.getMemorySize()  -- -> integer

-- ---- Example: lurek.system.openURL ------------------------------------------
--@api-stub: lurek.system.openURL
-- Opens a URL in the system's default browser.
-- lurek.system.openURL(url)  -- -> boolean

-- ---- Example: lurek.system.getPreferredLocales ------------------------------
--@api-stub: lurek.system.getPreferredLocales
-- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
-- lurek.system.getPreferredLocales()  -- -> table

-- ---- Example: lurek.system.getPowerInfo -------------------------------------
--@api-stub: lurek.system.getPowerInfo
-- Returns battery state, percentage charged, and estimated time remaining.
-- lurek.system.getPowerInfo()  -- -> string

-- ---- Example: lurek.system.getInfo ------------------------------------------
--@api-stub: lurek.system.getInfo
-- Returns a table of system information including OS name, CPU model, and installed RAM.
-- lurek.system.getInfo()  -- -> table

-- ---- Example: lurek.system.getMessage ---------------------------------------
--@api-stub: lurek.system.getMessage
-- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
-- lurek.system.getMessage(1)  -- -> string

-- ---- Example: lurek.system.hasMessage ---------------------------------------
--@api-stub: lurek.system.hasMessage
-- Returns true when the runtime message catalog contains the given stable message ID.
-- lurek.system.hasMessage(1)  -- -> boolean

-- ---- Example: lurek.system.getMessageCount ----------------------------------
--@api-stub: lurek.system.getMessageCount
-- Returns the total number of message entries loaded into the runtime message catalog.
-- lurek.system.getMessageCount()  -- -> integer

-- ---- Example: lurek.system.setClipboardText ---------------------------------
--@api-stub: lurek.system.setClipboardText
-- Replaces the system clipboard contents with the given string.
-- lurek.system.setClipboardText("Hello, world!")

-- ---- Example: lurek.system.getClipboardText ---------------------------------
--@api-stub: lurek.system.getClipboardText
-- Returns the current contents of the system clipboard.
-- lurek.system.getClipboardText()  -- -> string

-- ---- Example: lurek.system.setDebugOverlay ----------------------------------
--@api-stub: lurek.system.setDebugOverlay
-- Shows or hides the FPS/draw-call debug overlay.
-- lurek.system.setDebugOverlay(true)

-- ---- Example: lurek.system.getDebugOverlay ----------------------------------
--@api-stub: lurek.system.getDebugOverlay
-- Returns whether the debug overlay is currently visible.
-- lurek.system.getDebugOverlay()  -- -> boolean

-- ---- Example: lurek.system.setLogLevel --------------------------------------
--@api-stub: lurek.system.setLogLevel
-- Sets the minimum severity level for runtime log messages.
-- lurek.system.setLogLevel(level)

-- ---- Example: lurek.system.getLogLevel --------------------------------------
--@api-stub: lurek.system.getLogLevel
-- Returns the name of the current minimum log level for runtime messages.
-- lurek.system.getLogLevel()  -- -> string

-- ---- Example: lurek.system.log ----------------------------------------------
--@api-stub: lurek.system.log
-- Emit a log message from Lua at the specified level.
-- lurek.system.log(level, message)

-- ---- Example: lurek.system.getLastError -------------------------------------
--@api-stub: lurek.system.getLastError
-- Returns the last unhandled error message, or nil.
-- lurek.system.getLastError()  -- -> table

-- ---- Example: lurek.system.errorSnapshot ------------------------------------
--@api-stub: lurek.system.errorSnapshot
-- Serialises an engine error message to a compact JSON string.
-- lurek.system.errorSnapshot("level_complete")  -- -> string

-- ---- Example: lurek.system.getArch ------------------------------------------
--@api-stub: lurek.system.getArch
-- Returns the CPU architecture string for the current machine.
-- lurek.system.getArch()  -- -> string

-- ---- Example: lurek.system.getEnv -------------------------------------------
--@api-stub: lurek.system.getEnv
-- Returns the value of an environment variable, or nil if not set.
-- lurek.system.getEnv("hero")  -- -> string

-- ---- Example: lurek.system.getArgs ------------------------------------------
--@api-stub: lurek.system.getArgs
-- Returns the command-line arguments as a table.
-- lurek.system.getArgs()  -- -> table

-- ---- Example: lurek.system.parseArgs ----------------------------------------
--@api-stub: lurek.system.parseArgs
-- Parses a command-line argument string and returns a structured key/value table.
-- lurek.system.parseArgs(args)  -- -> table

-- ---- Example: lurek.system.runBatch -----------------------------------------
--@api-stub: lurek.system.runBatch
-- Runs a list of shell commands in parallel and returns immediately without blocking.
-- lurek.system.runBatch(tasks, opts)  -- -> table

-- ---- Example: lurek.system.getBatchResults ----------------------------------
--@api-stub: lurek.system.getBatchResults
-- Returns the output table from the most recently completed runBatch call.
-- lurek.system.getBatchResults(results)  -- -> integer
