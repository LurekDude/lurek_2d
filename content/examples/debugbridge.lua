-- content/examples/debugbridge.lua
-- Hand-written coverage of the lurek.debugbridge API (14 items).
--
-- The debug bridge exposes an in-process TCP control surface (default
-- port 17800+) so external tools can poll print history, request
-- screenshots, evaluate Lua snippets, and read frame-time stats from a
-- running game. Bind only to 127.0.0.1; ports must be >= 1024.
--
-- Run: cargo run -- content/examples/debugbridge.lua

-- â”€â”€ lurek.debugbridge.* functions â”€â”€

--@api-stub: lurek.debugbridge.start
-- Start the TCP debug server on 127.0.0.1:port.
-- Call once at boot behind a config flag; returns true on bind, errors if the port is < 1024 or already in use.
do -- lurek.debugbridge.start
  local debug_port = 17800
  local ok = pcall(function()
    local bound = lurek.debugbridge.start(debug_port)
    if bound then
      lurek.log.info("debug bridge listening on 127.0.0.1:" .. debug_port, "debugbridge")
    end
  end)
  if not ok then
    lurek.log.info("debug bridge unavailable (port in use)", "debugbridge")
  end
end

--@api-stub: lurek.debugbridge.stop
-- Stop the TCP debug server and close all connections.
-- Always call from lurek.quit() to join the listener thread cleanly before the process exits.
do -- lurek.debugbridge.stop
  function lurek.quit()
    if lurek.debugbridge.isRunning() then
      lurek.debugbridge.stop()
      lurek.log.info("debug bridge stopped", "debugbridge")
    end
  end
end

--@api-stub: lurek.debugbridge.isRunning
-- Returns whether the server is currently running.
-- Branch on this before calling stop()/getPort() so the rest of the file works whether the bridge was enabled or not.
do -- lurek.debugbridge.isRunning
  if lurek.debugbridge.isRunning() then
    lurek.log.info("debug bridge is up", "debugbridge")
  else
    lurek.log.debug("debug bridge disabled this session", "debugbridge")
  end
end

--@api-stub: lurek.debugbridge.getPort
-- Returns the server port (0 if not running).
-- Use the returned port to print a connection hint or write a discovery file external tools can pick up.
do -- lurek.debugbridge.getPort
  local port = lurek.debugbridge.getPort()
  if port > 0 then
    lurek.log.info("connect debugger to tcp://127.0.0.1:" .. port, "debugbridge")
  end
end

--@api-stub: lurek.debugbridge.getClientCount
-- Returns the number of connected TCP clients.
-- Skip expensive structured broadcasts when no client is attached to keep per-frame cost near zero.
do -- lurek.debugbridge.getClientCount
  function lurek.process(dt)
    if lurek.debugbridge.getClientCount() > 0 then
      lurek.debugbridge.broadcast("frame", '{"dt":' .. dt .. '}')
    end
  end
end

--@api-stub: lurek.debugbridge.poll
-- Poll for pending Lua-dependent requests from TCP clients.
-- Must be called every frame -- it also auto-records the current dt into the perf buffer for getPerformance().
do -- lurek.debugbridge.poll
  function lurek.process(dt)
    if lurek.debugbridge.isRunning() then
      lurek.debugbridge.poll()
    end
  end
end

--@api-stub: lurek.debugbridge.capturePrint
-- Captures a print message and broadcasts it to connected clients.
-- Override the global `print` so any third-party Lua module's output is mirrored to attached debug tools.
do -- lurek.debugbridge.capturePrint
  local _print = print
  print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
    local msg = table.concat(parts, "\t")
    lurek.debugbridge.capturePrint(msg, "main.lua", 0)
    _print(...)
  end
end

--@api-stub: lurek.debugbridge.getPrintHistory
-- Returns the print history.
-- Pass an integer to retrieve only the last N entries -- handy for an in-game console that shows the tail.
do -- lurek.debugbridge.getPrintHistory
  local recent = lurek.debugbridge.getPrintHistory(20)
  for _, entry in ipairs(recent) do
    lurek.log.debug(entry.source .. ":" .. entry.line .. " " .. entry.message, "console")
  end
end

--@api-stub: lurek.debugbridge.clearPrintHistory
-- Clears the print history.
-- Call on scene transitions so the in-game console starts each level with a clean buffer.
do -- lurek.debugbridge.clearPrintHistory
  local function load_scene(name)
    lurek.debugbridge.clearPrintHistory()
    lurek.log.info("entering scene " .. name, "scene")
  end
  load_scene("forest_01")
end

--@api-stub: lurek.debugbridge.setMaxPrintHistory
-- Sets the maximum print history size.
-- Bump high while debugging memory leaks (slow logs); keep low (~256) in shipping builds to bound RAM.
do -- lurek.debugbridge.setMaxPrintHistory
  local in_dev = true
  lurek.debugbridge.setMaxPrintHistory(in_dev and 4096 or 256)
end

--@api-stub: lurek.debugbridge.getPerformance
-- Returns performance statistics.
-- Sample once per second to drive an HUD overlay; the table holds avg/min/max frame deltas in seconds.
do -- lurek.debugbridge.getPerformance
  local accum = 0
  function lurek.process(dt)
    accum = accum + dt
    if accum >= 1.0 then
      accum = 0
      local perf = lurek.debugbridge.getPerformance()
      lurek.log.info_fields("perf sample", perf)
    end
  end
end

--@api-stub: lurek.debugbridge.requestScreenshot
-- Flags a screenshot request for the next frame.
-- Optional scale (1..8) downsamples to keep transfer small; the bridge writes the PNG at end of frame.
do -- lurek.debugbridge.requestScreenshot
  function lurek.init()
    lurek.input.bind("f12", function()
      lurek.debugbridge.requestScreenshot(2)
      lurek.log.info("screenshot queued (scale=2)", "debugbridge")
    end)
  end
end

--@api-stub: lurek.debugbridge.isScreenshotRequested
-- Returns whether a screenshot is currently requested.
-- Use to draw a "capturing..." toast for one frame, or to skip expensive UI before the capture.
do -- lurek.debugbridge.isScreenshotRequested
  function lurek.draw_ui()
    if lurek.debugbridge.isScreenshotRequested() then
      lurek.render.print("capturing...", 8, 8)
    end
  end
end

--@api-stub: lurek.debugbridge.broadcast
-- Broadcasts a JSON event to all connected clients.
-- Fire on gameplay milestones so attached tools can chart events; keep payloads small and pre-encoded.
do -- lurek.debugbridge.broadcast
  local function on_enemy_killed(enemy)
    local payload = '{"type":"' .. enemy.type .. '","x":' .. enemy.x .. ',"y":' .. enemy.y .. '}'
    lurek.debugbridge.broadcast("enemy_killed", payload)
  end
  on_enemy_killed({ type = "goblin", x = 240, y = 96 })
end

--@api-stub: lurek.debugbridge.getProtocolInfo
-- Returns protocol metadata (version, capabilities, nonce).
-- Use this when writing a local bridge client in Lua to inspect compatibility and surface diagnostics.
do -- lurek.debugbridge.getProtocolInfo
  local info = lurek.debugbridge.getProtocolInfo()
  lurek.log.info("bridge protocol v" .. info.version .. " caps=" .. #info.capabilities, "debugbridge")
end

--@api-stub: lurek.debugbridge.consumeHotReloadRequest
-- Consumes and clears a pending remote hot-reload request.
-- Poll once per frame and trigger your module reload pipeline exactly once when it returns true.
do -- lurek.debugbridge.consumeHotReloadRequest
  function lurek.process(dt)
    if lurek.debugbridge.consumeHotReloadRequest() then
      lurek.log.info("remote hot reload requested", "debugbridge")
    end
  end
end
-- content/examples/debugbridge.lua
-- EXAMPLEed coverage of the lurek.debugbridge API (14 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/debugbridge_api.rs   (Lua binding, arg types, return shape)
--   * src/debugbridge/                 (semantics, side effects)
--   * docs/specs/debugbridge.md        (canonical reference)
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
-- Run: cargo run -- content/examples/debugbridge.lua

-- â”€â”€ lurek.debugbridge.* functions â”€â”€
