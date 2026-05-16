-- content/examples/engine.lua
-- lurek.engine API examples.
-- Run: cargo run -- content/examples/engine.lua

--@api-stub: lurek.engine.getVersion
-- Returns the engine crate version string embedded at build time
do
  local version = lurek.engine.getVersion()
  local save_header = { engine = version, schema = 3, ts = os.time() }
  lurek.log.info("save header engine=" .. save_header.engine, "save")
end

--@api-stub: lurek.engine.getFrameBudget
-- Returns the target frame budget for a 60 FPS update loop
do
  local budget_ms = lurek.engine.getFrameBudget()
  local headroom_ms = budget_ms * 0.5
  function lurek.process(dt)
    if dt * 1000 > headroom_ms then
      lurek.log.warn("frame over half-budget: " .. (dt * 1000) .. "ms / " .. budget_ms, "perf")
    end
  end
end

--@api-stub: lurek.engine.memoryUsage
-- Returns Lua VM memory usage as bytes and rounded kilobytes
do
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
-- Returns the current desktop operating system name
do
  local os_name = lurek.engine.platform()
  local quit_hint = (os_name == "macos") and "Cmd+Q to quit" or "Alt+F4 to quit"
  lurek.log.info("running on " .. os_name .. " - " .. quit_hint, "boot")
end

--@api-stub: lurek.engine.uptime
-- Returns total engine runtime accumulated by the main loop
do
  local session_start = lurek.engine.uptime()
  function lurek.quit()
    local played = lurek.engine.uptime() - session_start
    lurek.log.info("session lasted " .. string.format("%.1f", played) .. "s", "session")
  end
end

--@api-stub: lurek.engine.fps
-- Returns the latest frames-per-second value stored by the runtime
do
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
-- Returns the number of frames counted by the shared runtime clock
do
  function lurek.process(_)
    if lurek.engine.frameCount() % 600 == 0 then
      lurek.log.info("autosave tick at frame " .. lurek.engine.frameCount(), "save")
    end
  end
end

--@api-stub: lurek.engine.isDebug
-- Returns whether the engine binary was built with debug assertions
do
  if lurek.engine.isDebug() then
    lurek.log.setLevel("debug")
    lurek.log.debug("debug build - verbose logging enabled", "boot")
  else
    lurek.log.setLevel("info")
  end
end

--@api-stub: lurek.engine.setResourceBudget
-- Sets the resource memory budget used by resource statistics reporting
do
  local mb = 256
  lurek.engine.setResourceBudget(mb * 1024 * 1024)
  lurek.log.info("texture budget set to " .. mb .. " MB", "boot")
end

--@api-stub: lurek.engine.getResourceStats
-- Returns current resource memory usage and object counts by resource kind
do
  function lurek.process(_)
    if lurek.engine.frameCount() % 300 ~= 0 then return end
    local stats = lurek.engine.getResourceStats()
    local mb = stats.total_bytes / (1024 * 1024)
    lurek.log.debug(string.format("tex=%d font=%d canvas=%d total=%.2fMB", stats.texture_count, stats.font_count, stats.canvas_count, mb), "mem")
  end
end

--@api-stub: lurek.engine.getFrameProfile
-- Returns the latest frame timing profile split by engine phase
do
  function lurek.draw_ui()
    local p = lurek.engine.getFrameProfile()
    lurek.render.print(string.format("tick=%.2fms process=%.2fms draw=%.2fms", p.app_tick_ms, p.process_ms, p.draw_ms), 8, 28)
  end
end

--@api-stub: lurek.engine.getFrameProfileText
-- Returns the latest frame timing profile formatted as one text line
do
  function lurek.draw_ui()
    lurek.render.print(lurek.engine.getFrameProfileText(), 8, 46)
  end
end

--@api-stub: lurek.engine.getConfigRevision
-- Returns the configuration reload revision counter
do
  local last = lurek.engine.getConfigRevision()
  function lurek.process(_)
    local now = lurek.engine.getConfigRevision()
    if now ~= last then
      last = now
      lurek.log.info("config revision changed to " .. now, "boot")
    end
  end
end

--@api-stub: lurek.init
-- Called once before the first frame to load assets and initialise game state.
do
  function lurek.init()
    lurek.log.debug("init", "engine")
  end
end

--@api-stub: lurek.ready
-- Called once after init when the window and GPU are fully ready for rendering.
do
  function lurek.ready()
    lurek.log.debug("ready", "engine")
  end
end

--@api-stub: lurek.process
-- Called every frame with the delta time in seconds to run game logic.
do
  function lurek.process(dt)
    lurek.log.debug("dt=" .. dt, "engine")
  end
end

--@api-stub: lurek.process_late
-- Called after process each frame for logic that must run after all updates.
do
  function lurek.process_late(dt)
    lurek.log.debug("late dt=" .. dt, "engine")
  end
end

--@api-stub: lurek.process_physics
-- Called every physics step with the fixed timestep in seconds.
do
  function lurek.process_physics(dt)
    lurek.log.debug("phys dt=" .. dt, "engine")
  end
end

--@api-stub: lurek.fixedUpdate
-- Called at a fixed rate independent of frame time for deterministic physics updates.
do
  function lurek.fixedUpdate(dt)
    lurek.log.debug("fixed dt=" .. dt, "engine")
  end
end

--@api-stub: lurek.draw
-- Called each frame after process to submit world-space draw commands.
do
  function lurek.draw()
    -- draw world-space geometry here
  end
end

--@api-stub: lurek.draw_ui
-- Called each frame after draw to submit HUD and UI draw commands in screen space.
do
  function lurek.draw_ui()
    -- draw UI elements here
  end
end

--@api-stub: lurek.quit
-- Called when the window is about to close so the game can save state and clean up.
do
  function lurek.quit()
    lurek.log.info("quitting", "engine")
  end
end

--@api-stub: lurek.resize
-- Called whenever the window is resized with the new width and height in pixels.
do
  function lurek.resize(w, h)
    lurek.log.debug("resize " .. w .. "x" .. h, "engine")
  end
end

--@api-stub: lurek.focus
-- Called when the window gains or loses focus with a boolean argument.
do
  function lurek.focus(has_focus)
    lurek.log.debug("focus=" .. tostring(has_focus), "engine")
  end
end

--@api-stub: lurek.visible
-- Called when the window is shown or hidden with a boolean visibility argument.
do
  function lurek.visible(is_visible)
    lurek.log.debug("visible=" .. tostring(is_visible), "engine")
  end
end

--@api-stub: lurek.exit
-- Signals the engine to close the window and exit the game loop cleanly.
do
  lurek.exit()
end

--@api-stub: lurek.keypressed
-- Called when a keyboard key is pressed with the key name, scan code, and repeat flag.
do
  function lurek.keypressed(key, scancode, is_repeat)
    if key == "escape" then lurek.exit() end
  end
end

--@api-stub: lurek.keyreleased
-- Called when a keyboard key is released with the key name and scan code.
do
  function lurek.keyreleased(key, scancode)
    lurek.log.debug("released " .. key, "engine")
  end
end

--@api-stub: lurek.textinput
-- Called when printable text is entered by the user as a UTF-8 character string.
do
  function lurek.textinput(char)
    lurek.log.debug("text=" .. char, "engine")
  end
end

--@api-stub: lurek.textedited
-- Called during IME composition with the in-progress text and cursor position.
do
  function lurek.textedited(text, start, length)
    lurek.log.debug("ime=" .. text, "engine")
  end
end

--@api-stub: lurek.mousepressed
-- Called when a mouse button is pressed with pixel coordinates and button index.
do
  function lurek.mousepressed(x, y, button)
    lurek.log.debug("press " .. button .. " at " .. x .. "," .. y, "engine")
  end
end

--@api-stub: lurek.mousereleased
-- Called when a mouse button is released with pixel coordinates and button index.
do
  function lurek.mousereleased(x, y, button)
    lurek.log.debug("release " .. button, "engine")
  end
end

--@api-stub: lurek.mousemoved
-- Called each frame a mouse move occurs with current position and delta.
do
  function lurek.mousemoved(x, y, dx, dy)
    lurek.log.debug("mouse " .. x .. "," .. y, "engine")
  end
end

--@api-stub: lurek.wheelmoved
-- Called when the mouse wheel is scrolled with the x and y scroll deltas.
do
  function lurek.wheelmoved(x, y)
    lurek.log.debug("wheel " .. x .. "," .. y, "engine")
  end
end

--@api-stub: lurek.gamepadpressed
-- Called when a gamepad button is pressed with joystick id and button name.
do
  function lurek.gamepadpressed(id, button)
    lurek.log.debug("gp press " .. button, "engine")
  end
end

--@api-stub: lurek.gamepadreleased
-- Called when a gamepad button is released with joystick id and button name.
do
  function lurek.gamepadreleased(id, button)
    lurek.log.debug("gp release " .. button, "engine")
  end
end

--@api-stub: lurek.gamepadaxis
-- Called when a gamepad axis changes value with joystick id, axis name, and value.
do
  function lurek.gamepadaxis(id, axis, value)
    lurek.log.debug("axis " .. axis .. "=" .. value, "engine")
  end
end

--@api-stub: lurek.joystickadded
-- Called when a joystick or gamepad is connected with the joystick id.
do
  function lurek.joystickadded(id)
    lurek.log.info("joystick added id=" .. id, "engine")
  end
end

--@api-stub: lurek.joystickremoved
-- Called when a joystick or gamepad is disconnected with the joystick id.
do
  function lurek.joystickremoved(id)
    lurek.log.info("joystick removed id=" .. id, "engine")
  end
end

--@api-stub: lurek.touchpressed
-- Called when a touch point starts with touch id, position, and pressure.
do
  function lurek.touchpressed(id, x, y, dx, dy, pressure)
    lurek.log.debug("touch start " .. id, "engine")
  end
end

--@api-stub: lurek.touchreleased
-- Called when a touch point ends with touch id and final position.
do
  function lurek.touchreleased(id, x, y, dx, dy, pressure)
    lurek.log.debug("touch end " .. id, "engine")
  end
end

--@api-stub: lurek.touchmoved
-- Called when a touch point moves with touch id, current position, and delta.
do
  function lurek.touchmoved(id, x, y, dx, dy, pressure)
    lurek.log.debug("touch move " .. id, "engine")
  end
end
