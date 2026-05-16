-- content/examples/system.lua
-- lurek.system API examples.
-- Run: cargo run -- content/examples/system.lua

--@api-stub: lurek.runtime.getOS
-- Returns the name of the host operating system as a string
do
  local os_name = runtime.getOS()
  local mod_key = (os_name == "macOS") and "cmd" or "ctrl"
  lurek.log.info("running on " .. os_name .. " (modifier=" .. mod_key .. ")", "boot")
end

--@api-stub: lurek.runtime.getVersion
-- Returns the semantic version string of the Lurek2D engine
do
  local engine_version = runtime.getVersion()
  local save_header = "lurek2d/" .. engine_version
  lurek.log.info("save header tag: " .. save_header, "save")
end

--@api-stub: lurek.runtime.getProcessorCount
-- Returns the number of logical processors available on the host machine
do
  local cores = runtime.getProcessorCount()
  local workers = math.max(1, cores - 1)
  lurek.log.info("spawning " .. workers .. " worker threads (of " .. cores .. ")", "thread")
end

--@api-stub: lurek.runtime.getMemorySize
-- Returns the total physical memory of the host system in megabytes
do
  local ram_mb = runtime.getMemorySize()
  local quality = (ram_mb >= 8192) and "high" or (ram_mb >= 4096 and "medium" or "low")
  lurek.log.info("texture quality preset: " .. quality .. " (" .. ram_mb .. " MiB RAM)", "render")
end

--@api-stub: lurek.runtime.openURL
-- Opens a URL in the default system browser
do
  local credits_url = "https://lurek2d.example/credits"
  local opened = runtime.openURL(credits_url)
  if not opened then
    lurek.log.warn("could not open credits URL: " .. credits_url, "ui")
  end
end

--@api-stub: lurek.runtime.getPreferredLocales
-- Returns a list of the user's preferred locale identifiers from the operating system
do
  local locales = runtime.getPreferredLocales()
  local picked = locales[1] or "en_US"
  lurek.log.info("ui locale = " .. picked .. " (offered " .. #locales .. ")", "i18n")
end

--@api-stub: lurek.runtime.getPowerInfo
-- Returns the current power supply state, battery percentage, and estimated time remaining
do
  local state, percent, _seconds = runtime.getPowerInfo()
  local fps_cap = (state == "battery" and (percent or 100) < 30) and 30 or 60
  lurek.log.info("power=" .. state .. " fps_cap=" .. fps_cap, "perf")
end

--@api-stub: lurek.runtime.getInfo
-- Returns a table with comprehensive engine and host information
do
  local info = runtime.getInfo()
  local line = info.engine .. " " .. info.version .. " on " .. info.os ..
    " (" .. info.processors .. " cores, " .. info.memory .. " MiB)"
  lurek.log.info(line, "boot")
end

--@api-stub: lurek.runtime.getMessage
-- Resolves a message string by its identifier from the engine message catalog
do
  local message_id = "L001"
  local text = runtime.getMessage(message_id)
  lurek.log.info(message_id .. ": " .. text, "i18n")
end

--@api-stub: lurek.runtime.hasMessage
-- Checks whether a message identifier exists in the engine message catalog
do
  local candidate = "L999"
  if runtime.hasMessage(candidate) then
    lurek.log.info("catalogue has " .. candidate, "i18n")
  else
    lurek.log.warn("missing message id: " .. candidate, "i18n")
  end
end

--@api-stub: lurek.runtime.getMessageCount
-- Returns the total number of messages registered in the engine message catalog
do
  local n = runtime.getMessageCount()
  if n < 1 then
    lurek.log.warn("message catalogue is empty", "i18n")
  end
  lurek.log.info("loaded " .. n .. " runtime messages", "i18n")
end

--@api-stub: lurek.runtime.setClipboardText
-- Copies a string to the system clipboard
do
  local seed = "world-seed-4815162342"
  runtime.setClipboardText(seed)
  lurek.log.info("copied seed to clipboard: " .. seed, "ui")
end

--@api-stub: lurek.runtime.getClipboardText
-- Reads the current text content from the system clipboard
do
  local raw = runtime.getClipboardText() or ""
  local trimmed = raw:gsub("^%s+", ""):gsub("%s+$", "")
  if #trimmed > 0 then
    lurek.log.info("clipboard payload: '" .. trimmed .. "'", "ui")
  end
end

--@api-stub: lurek.runtime.setDebugOverlay
-- Enables or disables the on-screen debug overlay that shows FPS, draw calls, and other diagnostics
do
  function lurek.init()
    runtime.setDebugOverlay(true)
    lurek.log.info("debug overlay enabled at startup", "dev")
  end
end

--@api-stub: lurek.runtime.getDebugOverlay
-- Returns whether the on-screen debug overlay is currently enabled
do
  function lurek.process(_dt)
    if runtime.getDebugOverlay() then
      lurek.log.debug("engine overlay is on, skipping custom HUD", "dev")
    end
  end
end

--@api-stub: lurek.runtime.setLogLevel
-- Sets the engine-wide log verbosity level at runtime
do
  local desired_level = "info"
  runtime.setLogLevel(desired_level)
  lurek.log.info("log level set to " .. desired_level, "boot")
end

--@api-stub: lurek.runtime.getLogLevel
-- Returns the current engine log verbosity level as a string
do
  local level = runtime.getLogLevel()
  if level == "debug" then
    lurek.log.warn("log level is debug â€” output will be very chatty", "boot")
  end
end

--@api-stub: lurek.runtime.log
-- Writes a message to the engine log at the specified severity level
do
  local severity = "warn"
  local frame_ms = 22.5
  runtime.log(severity, "frame budget exceeded: " .. frame_ms .. " ms")
end

--@api-stub: lurek.runtime.getLastError
-- Returns the last error for Lua scripts in this module
do
  function lurek.process(_dt)
    local err = runtime.getLastError()
    if err then
      lurek.log.error("[" .. err.code .. "] " .. err.message, err.category)
    end
  end
end

--@api-stub: lurek.runtime.errorSnapshot
-- Creates a JSON-encoded error snapshot from a message string, useful for diagnostics and error reporting
do
  local raw_error = "asset not found: hero.png"
  local json = runtime.errorSnapshot(raw_error)
  lurek.log.error("crash snapshot: " .. json, "crash")
end

--@api-stub: lurek.runtime.getArch
-- Returns the CPU architecture of the host system
do
  local arch = runtime.getArch()
  local use_neon = (arch == "aarch64") or (arch == "arm64")
  lurek.log.info("arch=" .. arch .. " neon=" .. tostring(use_neon), "boot")
end

--@api-stub: lurek.runtime.getEnv
-- Reads an environment variable by name
do
  local profile_flag = runtime.getEnv("LUREK_PROFILE")
  if profile_flag == "1" then
    lurek.log.info("profiling mode enabled via LUREK_PROFILE", "dev")
  end
end

--@api-stub: lurek.runtime.getArgs
-- Returns the command-line arguments passed to the engine as a 1-indexed table of strings
do
  local args = runtime.getArgs()
  for i = 2, #args do
    lurek.log.info("argv[" .. i .. "] = " .. args[i], "boot")
  end
end

--@api-stub: lurek.runtime.parseArgs
-- Parses command-line arguments into structured flags, options, and positional values
do
  local input = { "--level=forest_01", "--debug", "save1.dat" }
  local parsed = runtime.parseArgs(input)
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
  local results = runtime.runBatch(tasks, { stopOnError = true })
  lurek.log.info("batch completed: warmup=" .. results.warmup_cache.status, "boot")
end

--@api-stub: lurek.runtime.reloadConfig
-- Requests a reload of the engine configuration from `conf
do
  function lurek.init()
    -- Example: a key-bind that forces conf.toml to be re-read immediately.
    lurek.log.info("requesting conf.toml hot-reload", "dev")
    runtime.reloadConfig()
  end
end

--@api-stub: lurek.runtime.getConfig
-- Returns a table containing the current engine runtime configuration values
do
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
-- Summarizes batch results by counting passed, failed, and skipped tasks
do
  local results = runtime.runBatch({
    ok_task = function() return true end,
    bad_task = function() error("intentional") end,
  })
  local passed, failed, skipped = runtime.getBatchResults(results)
  lurek.log.info("batch tally passed=" .. passed .. " failed=" .. failed .. " skipped=" .. skipped, "boot")
end

