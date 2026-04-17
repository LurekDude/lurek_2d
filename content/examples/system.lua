-- content/examples/system.lua
-- Lurek2D lurek.system API Reference
-- Run with: cargo run -- content/examples/system

-- =============================================================================
-- lurek.system — Host platform queries, clipboard, debug overlays
--
-- The system module exposes read-only queries about the host machine (OS,
-- architecture, CPU count, RAM), clipboard access for copy-paste, a message
-- queue for inter-system notifications, debug overlay toggles, and a batch
-- command runner for tool scripts.
-- =============================================================================

-- ---- Stub: lurek.system.getOS --------------------------------------------
--@api-stub: lurek.system.getOS
-- Detect the host OS to choose platform-appropriate default paths and
-- workarounds (e.g. line endings, save directories, font fallbacks).
local os_name = lurek.system.getOS()
print("host OS: " .. os_name)
local path_sep = (os_name == "windows") and "\\" or "/"
print("path separator: " .. path_sep)

-- ---- Stub: lurek.system.getArch ------------------------------------------
--@api-stub: lurek.system.getArch
-- Report the CPU architecture for telemetry or to choose optimized code
-- paths (e.g. SIMD vs scalar math on x86_64 vs ARM).
local arch = lurek.system.getArch()
print("CPU architecture: " .. arch)
if arch == "x86_64" then
    print("  -> SIMD acceleration available")
elseif arch == "aarch64" then
    print("  -> ARM NEON available")
end

-- ---- Stub: lurek.system.getVersion ---------------------------------------
--@api-stub: lurek.system.getVersion
-- Show the engine version string in an "About" dialog or crash report header
-- so support tickets always include the build number.
local version = lurek.system.getVersion()
print("Lurek2D version: " .. version)

-- ---- Stub: lurek.system.getProcessorCount --------------------------------
--@api-stub: lurek.system.getProcessorCount
-- Decide how many background worker threads to spawn for pathfinding or
-- asset loading based on the available logical cores.
local cores = lurek.system.getProcessorCount()
print("logical cores: " .. cores)
local worker_count = math.max(1, cores - 2)   -- reserve 2 for main + render
print("spawning " .. worker_count .. " worker threads")

-- ---- Stub: lurek.system.getMemorySize ------------------------------------
--@api-stub: lurek.system.getMemorySize
-- Query total system RAM to pick a texture quality preset.  Systems with
-- less than 4 GB get low-res textures to avoid swapping.
local ram_mb = lurek.system.getMemorySize()
print("system RAM: " .. ram_mb .. " MB")
local quality
if ram_mb >= 8192 then
    quality = "high"
elseif ram_mb >= 4096 then
    quality = "medium"
else
    quality = "low"
end
print("texture quality preset: " .. quality)

-- ---- Stub: lurek.system.getInfo ------------------------------------------
--@api-stub: lurek.system.getInfo
-- Collect a combined system info table for the crash report and telemetry.
local info = lurek.system.getInfo()
print("system info:")
for key, val in pairs(info) do
    print(string.format("  %s = %s", key, tostring(val)))
end

-- ---- Stub: lurek.system.openURL ------------------------------------------
--@api-stub: lurek.system.openURL
-- Open the game's community page in the default browser when the player
-- clicks "Join Discord" in the main menu.
local discord_url = "https://discord.gg/example-game-community"
if false then
    -- Guarded: would actually open the browser
    lurek.system.openURL(discord_url)
end
print("openURL would open: " .. discord_url)

-- ---- Stub: lurek.system.getPreferredLocales ------------------------------
--@api-stub: lurek.system.getPreferredLocales
-- Read the OS locale list to auto-select the game language on first launch
-- without requiring the player to pick from a dropdown.
local locales = lurek.system.getPreferredLocales()
print("preferred locales:")
for i, loc in ipairs(locales) do
    print(string.format("  [%d] %s", i, loc))
end
local game_lang = locales[1] or "en"
print("auto-selected language: " .. game_lang)

-- ---- Stub: lurek.system.getPowerInfo -------------------------------------
--@api-stub: lurek.system.getPowerInfo
-- Show battery level in the HUD when running on laptop.  Enable aggressive
-- power saving (lower FPS cap, reduced particles) below 20%.
local power = lurek.system.getPowerInfo()
print("power source: " .. (power.state or "unknown"))
if power.percent then
    print("battery: " .. power.percent .. "%")
    if power.percent < 20 then
        print("  -> enabling power-save mode: 30 FPS cap, particles reduced")
    end
end

-- ---- Stub: lurek.system.setClipboardText ---------------------------------
--@api-stub: lurek.system.setClipboardText
-- Copy the current level seed to the clipboard so players can share it with
-- friends for the same procedural dungeon layout.
local level_seed = "DUNGEON-7F3A-2024"
lurek.system.setClipboardText(level_seed)
print("copied seed to clipboard: " .. level_seed)

-- ---- Stub: lurek.system.getClipboardText ---------------------------------
--@api-stub: lurek.system.getClipboardText
-- Paste a seed from the clipboard into the "Enter Seed" text field in the
-- new-game dialog.
local pasted = lurek.system.getClipboardText()
print("clipboard contents: " .. (pasted or "(empty)"))

-- ---- Stub: lurek.system.getMessage ---------------------------------------
--@api-stub: lurek.system.getMessage
-- Pop the next inter-system message from the queue.  Messages are used for
-- engine-to-script communication (e.g. "file_dropped", "focus_lost").
local msg = lurek.system.getMessage()
if msg then
    print("system message: " .. msg.type .. " -> " .. tostring(msg.data))
else
    print("no pending system messages")
end

-- ---- Stub: lurek.system.hasMessage ---------------------------------------
--@api-stub: lurek.system.hasMessage
-- Check whether there are pending messages before entering a blocking loop.
local has = lurek.system.hasMessage()
print("has pending messages: " .. tostring(has))

-- ---- Stub: lurek.system.getMessageCount ----------------------------------
--@api-stub: lurek.system.getMessageCount
-- Show the number of queued messages in a debug overlay status bar.
local count = lurek.system.getMessageCount()
print("queued system messages: " .. count)

-- ---- Stub: lurek.system.setDebugOverlay ----------------------------------
--@api-stub: lurek.system.setDebugOverlay
-- Toggle the engine debug overlay (FPS, draw calls, memory) with a hotkey.
-- The overlay is useful during development and hidden in release builds.
lurek.system.setDebugOverlay(true)
print("debug overlay enabled -- shows FPS, draw calls, memory")

-- ---- Stub: lurek.system.getDebugOverlay ----------------------------------
--@api-stub: lurek.system.getDebugOverlay
-- Read the overlay state to update a checkbox in the options menu.
local overlay_on = lurek.system.getDebugOverlay()
print("debug overlay active: " .. tostring(overlay_on))

-- ---- Stub: lurek.system.setLogLevel --------------------------------------
--@api-stub: lurek.system.setLogLevel
-- Change the runtime log verbosity from the dev console.  During normal
-- gameplay use "warn"; switch to "debug" when investigating a bug.
lurek.system.setLogLevel("debug")
print("log level set to: debug")

-- ---- Stub: lurek.system.getLogLevel --------------------------------------
--@api-stub: lurek.system.getLogLevel
-- Display the current log level in the options menu dropdown.
local lvl = lurek.system.getLogLevel()
print("current log level: " .. lvl)

-- ---- Stub: lurek.system.log ----------------------------------------------
--@api-stub: lurek.system.log
-- Emit a system-level log message at a chosen severity.  Prefer lurek.log.*
-- for game messages; use system.log for platform-level diagnostics.
lurek.system.log("info", "GPU driver version: 31.0.15.5161")
lurek.system.log("warn", "swap chain recreated after minimize")
print("2 system log messages emitted")

-- ---- Stub: lurek.system.getLastError -------------------------------------
--@api-stub: lurek.system.getLastError
-- Retrieve the most recent engine error to show in a user-facing dialog
-- instead of a raw crash.
local err = lurek.system.getLastError()
if err then
    print("last error: " .. err)
else
    print("no errors recorded")
end

-- ---- Stub: lurek.system.getEnv -------------------------------------------
--@api-stub: lurek.system.getEnv
-- Read an environment variable to detect CI or custom install paths.
-- Games check LUREK_DATA_DIR for override asset locations during testing.
local data_dir = lurek.system.getEnv("LUREK_DATA_DIR")
if data_dir then
    print("custom data dir: " .. data_dir)
else
    print("LUREK_DATA_DIR not set -- using default asset path")
end

-- ---- Stub: lurek.system.getArgs ------------------------------------------
--@api-stub: lurek.system.getArgs
-- Read raw command-line arguments to detect flags like --windowed or --mute.
local args = lurek.system.getArgs()
print("command-line arguments:")
for i, arg in ipairs(args) do
    print(string.format("  [%d] %s", i, arg))
end

-- ---- Stub: lurek.system.parseArgs ----------------------------------------
--@api-stub: lurek.system.parseArgs
-- Parse command-line arguments into a structured table with named flags.
-- e.g. "--width 1280 --height 720 --fullscreen" -> { width=1280, height=720, fullscreen=true }
local parsed = lurek.system.parseArgs()
print("parsed args:")
for key, val in pairs(parsed) do
    print(string.format("  %s = %s", key, tostring(val)))
end

-- ---- Stub: lurek.system.runBatch -----------------------------------------
--@api-stub: lurek.system.runBatch
-- Run a batch of shell commands for asset pipeline processing.  The batch
-- runs asynchronously and results are polled later.
local cmds = {
    "echo preprocessing textures...",
    "echo compiling shaders...",
    "echo done",
}
local batch_id = lurek.system.runBatch(cmds)
print("batch started with id: " .. tostring(batch_id))

-- ---- Stub: lurek.system.getBatchResults ----------------------------------
--@api-stub: lurek.system.getBatchResults
-- Poll for batch results after submitting a command set.
local results = lurek.system.getBatchResults(batch_id)
if results then
    print("batch results:")
    for i, r in ipairs(results) do
        print(string.format("  [%d] exit=%d  output=%s", i, r.exit_code or -1, r.output or ""))
    end
else
    print("batch still running or invalid id")
end
