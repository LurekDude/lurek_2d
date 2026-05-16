-- content/examples/debugbridge.lua
-- lurek.debugbridge API examples.
-- Run: cargo run -- content/examples/debugbridge.lua

--@api-stub: lurek.debugbridge.start
-- Starts the localhost debug bridge server on a port
do
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
-- Stops the debug bridge server and joins its server thread
do
  function lurek.quit()
    if lurek.debugbridge.isRunning() then
      lurek.debugbridge.stop()
      lurek.log.info("debug bridge stopped", "debugbridge")
    end
  end
end

--@api-stub: lurek.debugbridge.isRunning
-- Returns whether the debug bridge server is currently running
do
  if lurek.debugbridge.isRunning() then
    lurek.log.info("debug bridge is up", "debugbridge")
  else
    lurek.log.debug("debug bridge disabled this session", "debugbridge")
  end
end

--@api-stub: lurek.debugbridge.getPort
-- Returns the debug bridge TCP port
do
  local port = lurek.debugbridge.getPort()
  if port > 0 then
    lurek.log.info("connect debugger to tcp://127.0.0.1:" .. port, "debugbridge")
  end
end

--@api-stub: lurek.debugbridge.getClientCount
-- Returns the number of connected debug bridge clients
do
  function lurek.process(dt)
    if lurek.debugbridge.getClientCount() > 0 then
      lurek.debugbridge.broadcast("frame", '{"dt":' .. dt .. '}')
    end
  end
end

--@api-stub: lurek.debugbridge.poll
-- Polls pending debugger requests, evaluates supported methods, and queues responses
do
  function lurek.process(dt)
    if lurek.debugbridge.isRunning() then
      lurek.debugbridge.poll()
    end
  end
end

--@api-stub: lurek.debugbridge.capturePrint
-- Captures a print message and broadcasts it to debug bridge clients
do
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
-- Returns captured print history entries
do
  local recent = lurek.debugbridge.getPrintHistory(20)
  for _, entry in ipairs(recent) do
    lurek.log.debug(entry.source .. ":" .. entry.line .. " " .. entry.message, "console")
  end
end

--@api-stub: lurek.debugbridge.clearPrintHistory
-- Clears captured print history
do
  local function load_scene(name)
    lurek.debugbridge.clearPrintHistory()
    lurek.log.info("entering scene " .. name, "scene")
  end
  load_scene("forest_01")
end

--@api-stub: lurek.debugbridge.setMaxPrintHistory
-- Sets the maximum retained print history entry count
do
  local in_dev = true
  lurek.debugbridge.setMaxPrintHistory(in_dev and 4096 or 256)
end

--@api-stub: lurek.debugbridge.getPerformance
-- Returns debug bridge performance metrics
do
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
-- Requests a screenshot from the runtime
do
  function lurek.init()
    lurek.input.bind("f12", function()
      lurek.debugbridge.requestScreenshot(2)
      lurek.log.info("screenshot queued (scale=2)", "debugbridge")
    end)
  end
end

--@api-stub: lurek.debugbridge.isScreenshotRequested
-- Returns whether a screenshot request is pending
do
  function lurek.draw_ui()
    if lurek.debugbridge.isScreenshotRequested() then
      lurek.render.print("capturing...", 8, 8)
    end
  end
end

--@api-stub: lurek.debugbridge.broadcast
-- Queues a JSON string payload broadcast for debug bridge clients
do
  local function on_enemy_killed(enemy)
    local payload = '{"type":"' .. enemy.type .. '","x":' .. enemy.x .. ',"y":' .. enemy.y .. '}'
    lurek.debugbridge.broadcast("enemy_killed", payload)
  end
  on_enemy_killed({ type = "goblin", x = 240, y = 96 })
end

--@api-stub: lurek.debugbridge.getProtocolInfo
-- Returns debug bridge protocol version, capabilities, and handshake nonce
do
  local info = lurek.debugbridge.getProtocolInfo()
  lurek.log.info("bridge protocol v" .. info.version .. " caps=" .. #info.capabilities, "debugbridge")
end

--@api-stub: lurek.debugbridge.consumeHotReloadRequest
-- Returns and clears the pending hot reload request flag
do
  function lurek.process(dt)
    if lurek.debugbridge.consumeHotReloadRequest() then
      lurek.log.info("remote hot reload requested", "debugbridge")
    end
  end
end
