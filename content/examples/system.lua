-- content/examples/system.lua
-- Hand-written coverage of the lurek.system API (26 items).
--
-- Platform queries (OS, CPU, memory, locale, clipboard) plus runtime-message
-- catalogue lookup, debug-overlay toggling, structured logging, and CLI
-- argument parsing. Most calls are safe at file scope; only batch-runner
-- helpers should usually live inside an `init`/`process` callback.
--
-- Run: cargo run -- content/examples/system.lua

-- ── lurek.system.* functions ──

-- Guard: lurek.system is not registered in the headless test VM.
if not lurek.system then return end

--@api-stub: lurek.system.getOS
-- Returns the host operating system name ('Windows', 'Linux', 'macOS').
-- Branch on this at startup to pick platform-specific asset paths or hot-keys.
do  -- lurek.system.getOS
  local os_name = lurek.system.getOS()
  local mod_key = (os_name == "macOS") and "cmd" or "ctrl"
  lurek.log.info("running on " .. os_name .. " (modifier=" .. mod_key .. ")", "boot")
end

--@api-stub: lurek.system.getVersion
-- Returns the Lurek2D engine version string.
-- Stamp this into save files and crash reports so old saves can be migrated safely.
do  -- lurek.system.getVersion
  local engine_version = lurek.system.getVersion()
  local save_header = "lurek2d/" .. engine_version
  lurek.log.info("save header tag: " .. save_header, "save")
end

--@api-stub: lurek.system.getProcessorCount
-- Returns the number of logical CPU cores available.
-- Use to size worker-thread pools; reserve at least one core for the main loop.
do  -- lurek.system.getProcessorCount
  local cores = lurek.system.getProcessorCount()
  local workers = math.max(1, cores - 1)
  lurek.log.info("spawning " .. workers .. " worker threads (of " .. cores .. ")", "thread")
end

--@api-stub: lurek.system.getMemorySize
-- Returns the total amount of installed system RAM in megabytes.
-- Pick a texture-quality preset based on installed RAM rather than guessing.
do  -- lurek.system.getMemorySize
  local ram_mb = lurek.system.getMemorySize()
  local quality = (ram_mb >= 8192) and "high" or (ram_mb >= 4096 and "medium" or "low")
  lurek.log.info("texture quality preset: " .. quality .. " (" .. ram_mb .. " MiB RAM)", "render")
end

--@api-stub: lurek.system.openURL
-- Opens a URL in the system's default browser.
-- Only http/https/mailto schemes are accepted; the call returns false if rejected.
do  -- lurek.system.openURL
  local credits_url = "https://lurek2d.example/credits"
  local opened = lurek.system.openURL(credits_url)
  if not opened then
    lurek.log.warn("could not open credits URL: " .. credits_url, "ui")
  end
end

--@api-stub: lurek.system.getPreferredLocales
-- Returns an ordered list of the user's preferred locale strings (e.g. 'en-US').
-- Walk the list and stop at the first locale your translations actually support.
do  -- lurek.system.getPreferredLocales
  local locales = lurek.system.getPreferredLocales()
  local picked = locales[1] or "en_US"
  lurek.log.info("ui locale = " .. picked .. " (offered " .. #locales .. ")", "i18n")
end

--@api-stub: lurek.system.getPowerInfo
-- Returns battery state, percentage charged, and estimated time remaining.
-- On laptops, drop the frame cap when on battery to extend playtime.
do  -- lurek.system.getPowerInfo
  local state, percent, _seconds = lurek.system.getPowerInfo()
  local fps_cap = (state == "battery" and (percent or 100) < 30) and 30 or 60
  lurek.log.info("power=" .. state .. " fps_cap=" .. fps_cap, "perf")
end

--@api-stub: lurek.system.getInfo
-- Returns a table of system information including OS name, CPU model, and installed RAM.
-- Dump this once at startup so bug reports include the full host fingerprint.
do  -- lurek.system.getInfo
  local info = lurek.system.getInfo()
  local line = info.engine .. " " .. info.version .. " on " .. info.os ..
    " (" .. info.processors .. " cores, " .. info.memory .. " MiB)"
  lurek.log.info(line, "boot")
end

--@api-stub: lurek.system.getMessage
-- Resolves a stable runtime message ID such as 'L001' to its human-readable text.
-- Prefer message IDs over hard-coded English strings so localisation can swap them.
do  -- lurek.system.getMessage
  local message_id = "L001"
  local text = lurek.system.getMessage(message_id)
  lurek.log.info(message_id .. ": " .. text, "i18n")
end

--@api-stub: lurek.system.hasMessage
-- Returns true when the runtime message catalog contains the given stable message ID.
-- Guard `getMessage` with `hasMessage` when an ID comes from data that may be stale.
do  -- lurek.system.hasMessage
  local candidate = "L999"
  if lurek.system.hasMessage(candidate) then
    lurek.log.info("catalogue has " .. candidate, "i18n")
  else
    lurek.log.warn("missing message id: " .. candidate, "i18n")
  end
end

--@api-stub: lurek.system.getMessageCount
-- Returns the total number of message entries loaded into the runtime message catalog.
-- Useful as a smoke check after loading translation packs at startup.
do  -- lurek.system.getMessageCount
  local n = lurek.system.getMessageCount()
  if n < 1 then
    lurek.log.warn("message catalogue is empty", "i18n")
  end
  lurek.log.info("loaded " .. n .. " runtime messages", "i18n")
end

--@api-stub: lurek.system.setClipboardText
-- Replaces the system clipboard contents with the given string.
-- Pair with a confirmation toast so the player knows the value was copied.
do  -- lurek.system.setClipboardText
  local seed = "world-seed-4815162342"
  lurek.system.setClipboardText(seed)
  lurek.log.info("copied seed to clipboard: " .. seed, "ui")
end

--@api-stub: lurek.system.getClipboardText
-- Returns the current contents of the system clipboard.
-- Trim whitespace before parsing — users often copy a trailing newline.
do  -- lurek.system.getClipboardText
  local raw = lurek.system.getClipboardText() or ""
  local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
  if #trimmed > 0 then
    lurek.log.info("clipboard payload: '" .. trimmed .. "'", "ui")
  end
end

--@api-stub: lurek.system.setDebugOverlay
-- Shows or hides the FPS/draw-call debug overlay.
-- Bind to a function key in development; never leave it on in shipped builds.
do  -- lurek.system.setDebugOverlay
  function lurek.init()
    lurek.system.setDebugOverlay(true)
    lurek.log.info("debug overlay enabled at startup", "dev")
  end
end

--@api-stub: lurek.system.getDebugOverlay
-- Returns whether the debug overlay is currently visible.
-- Read this before drawing your own perf HUD so you don't double-render counters.
do  -- lurek.system.getDebugOverlay
  function lurek.process(_dt)
    if lurek.system.getDebugOverlay() then
      lurek.log.debug("engine overlay is on, skipping custom HUD", "dev")
    end
  end
end

--@api-stub: lurek.system.setLogLevel
-- Sets the minimum severity level for runtime log messages.
-- Read the level from your config file; unknown level names will raise an error.
do  -- lurek.system.setLogLevel
  local desired_level = "info"
  lurek.system.setLogLevel(desired_level)
  lurek.log.info("log level set to " .. desired_level, "boot")
end

--@api-stub: lurek.system.getLogLevel
-- Returns the name of the current minimum log level for runtime messages.
-- Echo it on the debug overlay so testers can confirm the active filter.
do  -- lurek.system.getLogLevel
  local level = lurek.system.getLogLevel()
  if level == "debug" then
    lurek.log.warn("log level is debug — output will be very chatty", "boot")
  end
end

--@api-stub: lurek.system.log
-- Emit a log message from Lua at the specified level.
-- Use this when the level is dynamic; otherwise prefer lurek.log.info/warn/error.
do  -- lurek.system.log
  local severity = "warn"
  local frame_ms = 22.5
  lurek.system.log(severity, "frame budget exceeded: " .. frame_ms .. " ms")
end

--@api-stub: lurek.system.getLastError
-- Returns the last unhandled error message, or nil.
-- Drain it once per frame in dev to surface engine errors as in-game toasts.
do  -- lurek.system.getLastError
  function lurek.process(_dt)
    local err = lurek.system.getLastError()
    if err then
      lurek.log.error("[" .. err.code .. "] " .. err.message, err.category)
    end
  end
end

--@api-stub: lurek.system.errorSnapshot
-- Serialises an engine error message to a compact JSON string.
-- Attach the JSON to crash uploads so the reporter has the full structured error.
do  -- lurek.system.errorSnapshot
  local raw_error = "asset not found: hero.png"
  local json = lurek.system.errorSnapshot(raw_error)
  lurek.log.error("crash snapshot: " .. json, "crash")
end

--@api-stub: lurek.system.getArch
-- Returns the CPU architecture string for the current machine.
-- Pick SIMD code paths or shader variants based on 'x86_64' vs 'aarch64'.
do  -- lurek.system.getArch
  local arch = lurek.system.getArch()
  local use_neon = (arch == "aarch64") or (arch == "arm64")
  lurek.log.info("arch=" .. arch .. " neon=" .. tostring(use_neon), "boot")
end

--@api-stub: lurek.system.getEnv
-- Returns the value of an environment variable, or nil if not set.
-- Use for opt-in dev knobs (e.g. LUREK_PROFILE=1) — never read secrets here.
do  -- lurek.system.getEnv
  local profile_flag = lurek.system.getEnv("LUREK_PROFILE")
  if profile_flag == "1" then
    lurek.log.info("profiling mode enabled via LUREK_PROFILE", "dev")
  end
end

--@api-stub: lurek.system.getArgs
-- Returns the command-line arguments as a table.
-- Walk the table to pick up positional inputs like a level path or save slot.
do  -- lurek.system.getArgs
  local args = lurek.system.getArgs()
  for i = 2, #args do
    lurek.log.info("argv[" .. i .. "] = " .. args[i], "boot")
  end
end

--@api-stub: lurek.system.parseArgs
-- Parses a command-line argument string and returns a structured key/value table.
-- Returns three sub-tables: flags, options (--key=value), and positional.
do  -- lurek.system.parseArgs
  local input = { "--level=forest_01", "--debug", "save1.dat" }
  local parsed = lurek.system.parseArgs(input)
  local level = parsed.options.level or "intro"
  local debug_on = parsed.flags.debug == true
  lurek.log.info("level=" .. level .. " debug=" .. tostring(debug_on), "boot")
end

--@api-stub: lurek.system.runBatch
-- Runs a list of shell commands in parallel and returns immediately without blocking.
-- Each task is a Lua function; the call is synchronous and returns a results table.
do  -- lurek.system.runBatch
  local tasks = {
    warmup_cache = function() return true end,
    preload_audio = function() return true end,
  }
  local results = lurek.system.runBatch(tasks, { stopOnError = true })
  lurek.log.info("batch completed: warmup=" .. results.warmup_cache.status, "boot")
end

--@api-stub: lurek.system.getBatchResults
-- Returns the output table from the most recently completed runBatch call.
-- Tally the (passed, failed, skipped) trio to gate startup on critical jobs.
do  -- lurek.system.getBatchResults
  local results = lurek.system.runBatch({
    ok_task = function() return true end,
    bad_task = function() error("intentional") end,
  })
  local passed, failed, skipped = lurek.system.getBatchResults(results)
  lurek.log.info("batch tally passed=" .. passed .. " failed=" .. failed .. " skipped=" .. skipped, "boot")
end
