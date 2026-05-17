-- content/examples/engine.lua
-- Demonstrates lurek.engine module and all engine lifecycle/input callbacks.
-- Run: cargo run -- content/examples/engine.lua

--@api-stub: lurek.engine.getVersion
-- Returns the engine crate version string embedded at build time.
do
  -- Useful for save-file headers so you can detect version mismatches on load.
  local version = lurek.engine.getVersion()
  local save_header = { engine = version, schema = 3, ts = os.time() }
  lurek.log.info("save header: engine=" .. save_header.engine .. " schema=" .. save_header.schema, "save")
end

--@api-stub: lurek.engine.getFrameBudget
-- Returns the target frame budget in milliseconds (16.67 ms for 60 FPS).
do
  -- Compare actual frame time against budget to detect heavy frames early.
  local budget_ms = lurek.engine.getFrameBudget()
  local warn_threshold = budget_ms * 0.8 -- warn at 80% budget usage
  function lurek.process(dt)
    local frame_ms = dt * 1000
    if frame_ms > warn_threshold then
      lurek.log.warn(string.format("frame budget %.1f/%.1f ms (%.0f%%)",
        frame_ms, budget_ms, (frame_ms / budget_ms) * 100), "perf")
    end
  end
end

--@api-stub: lurek.engine.memoryUsage
-- Returns a table with lua_bytes and lua_kb fields for Lua VM heap usage.
do
  -- Periodically log memory to detect leaks during development.
  local last_kb = 0
  function lurek.process(dt)
    if lurek.engine.frameCount() % 300 ~= 0 then return end
    local mem = lurek.engine.memoryUsage()
    local delta = mem.lua_kb - last_kb
    if delta > 0 then
      lurek.log.debug(string.format("lua heap: %d KB (+%d KB since last check)",
        mem.lua_kb, delta), "mem")
    end
    last_kb = mem.lua_kb
  end
end

--@api-stub: lurek.engine.platform
-- Returns "windows", "linux", "macos", or "unknown" for the current OS.
do
  -- Use platform name to select platform-specific defaults (paths, key hints).
  local os_name = lurek.engine.platform()
  local config_dir = "." -- os.getenv not available in lurek sandbox
  -- In a real deployment outside the sandbox, config_dir would be:
  -- Windows: os.getenv("APPDATA")  macOS: ~/Library/Application Support  Linux: ~/.config
  lurek.log.info("platform=" .. os_name .. " config_dir=" .. config_dir, "boot")
end

--@api-stub: lurek.engine.uptime
-- Returns total engine runtime in seconds since the process started.
do
  -- Track session play time for analytics or idle-kick detection.
  local session_start = lurek.engine.uptime()
  local idle_limit = 300 -- 5 minutes
  local last_input = session_start
  function lurek.keypressed()
    last_input = lurek.engine.uptime()
  end
  function lurek.process(dt)
    local now = lurek.engine.uptime()
    if now - last_input > idle_limit then
      lurek.log.info("player idle for " .. idle_limit .. "s", "session")
      last_input = now -- reset to avoid spamming
    end
  end
  function lurek.quit()
    local played = lurek.engine.uptime() - session_start
    lurek.log.info(string.format("session duration: %.1fs", played), "session")
  end
end

--@api-stub: lurek.engine.fps
-- Returns the current frames-per-second estimate from the runtime clock.
do
  -- Display an FPS counter in the corner of the screen during gameplay.
  local font
  function lurek.init()
    font = lurek.render.newFont(14)
  end
  function lurek.draw_ui()
    local fps = lurek.engine.fps()
    lurek.render.setFont(font)
    -- Color-code: green above 55, yellow 30-55, red below 30
    if fps >= 55 then
      lurek.render.setColor(0.2, 1, 0.2, 1)
    elseif fps >= 30 then
      lurek.render.setColor(1, 1, 0, 1)
    else
      lurek.render.setColor(1, 0.2, 0.2, 1)
    end
    lurek.render.print(string.format("FPS: %.0f", fps), 8, 8)
  end
end

--@api-stub: lurek.engine.frameCount
-- Returns the total number of frames rendered since engine start.
do
  -- Use frame count for periodic tasks that should fire every N frames.
  local autosave_interval = 600 -- every 10 seconds at 60fps
  function lurek.process(dt)
    local frame = lurek.engine.frameCount()
    if frame % autosave_interval == 0 and frame > 0 then
      lurek.log.info("autosave at frame " .. frame, "save")
      -- In a real game: serialize game state here
    end
  end
end

--@api-stub: lurek.engine.isDebug
-- Returns true if the binary was built with debug assertions (cargo build).
do
  -- Enable extra diagnostics and dev tools only in debug builds.
  if lurek.engine.isDebug() then
    lurek.log.setLevel("debug")
    lurek.log.debug("debug build detected — verbose logging + dev overlays enabled", "boot")
  else
    lurek.log.setLevel("warn")
  end
end

--@api-stub: lurek.engine.setResourceBudget
-- Sets the byte budget used by getResourceStats to calculate usage percentage.
do
  -- Set a 128 MB texture budget; getResourceStats will report usage against this.
  local budget_mb = 128
  lurek.engine.setResourceBudget(budget_mb * 1024 * 1024)
  lurek.log.info("resource budget set to " .. budget_mb .. " MB", "boot")
end

--@api-stub: lurek.engine.getResourceStats
-- Returns a table with texture/font/canvas/shader counts and byte totals.
do
  -- Log resource usage every 5 seconds to track asset loading pressure.
  function lurek.process(dt)
    if lurek.engine.frameCount() % 300 ~= 0 then return end
    local stats = lurek.engine.getResourceStats()
    local used_mb = stats.total_bytes / (1024 * 1024)
    lurek.log.debug(string.format(
      "resources: tex=%d font=%d canvas=%d | %.1f MB used",
      stats.texture_count, stats.font_count, stats.canvas_count, used_mb), "mem")
  end
end

--@api-stub: lurek.engine.getFrameProfile
-- Returns a table with per-phase timings: app_tick_ms, process_ms, draw_ms, etc.
do
  -- Show a mini profiler bar in debug builds to spot which phase is heavy.
  function lurek.draw_ui()
    if not lurek.engine.isDebug() then return end
    local p = lurek.engine.getFrameProfile()
    lurek.render.setColor(1, 1, 1, 0.8)
    lurek.render.print(string.format(
      "tick=%.2fms | process=%.2fms | draw=%.2fms",
      p.app_tick_ms, p.process_ms, p.draw_ms), 8, 8)
  end
end

--@api-stub: lurek.engine.getFrameProfileText
-- Returns a pre-formatted one-line string summarizing the frame profile.
do
  -- Quick single-line profiler overlay — no formatting needed on your side.
  function lurek.draw_ui()
    lurek.render.setColor(0.8, 0.8, 0.8, 0.7)
    lurek.render.print(lurek.engine.getFrameProfileText(), 8, 28)
  end
end

--@api-stub: lurek.engine.getConfigRevision
-- Returns a counter that increments each time runtime config is hot-reloaded.
do
  -- Detect live config changes (e.g. user edits conf.toml while game runs).
  local last_rev = lurek.engine.getConfigRevision()
  function lurek.process(dt)
    local rev = lurek.engine.getConfigRevision()
    if rev ~= last_rev then
      last_rev = rev
      lurek.log.info("config hot-reloaded (revision " .. rev .. ") — re-applying settings", "config")
      -- In a real game: re-read config values, adjust volumes, resize UI, etc.
    end
  end
end

--@api-stub: lurek.init
-- Called once before the first frame to load assets and set up initial game state.
do
  function lurek.init()
    -- Load sprites, fonts, sounds, and build initial game objects.
    lurek.log.info("game initialising — loading assets", "lifecycle")
    -- Example: player = { x = 400, y = 300, speed = 200 }
  end
end

--@api-stub: lurek.ready
-- Called once after init when the window and GPU are fully ready.
do
  function lurek.ready()
    -- Safe to query window size, create canvases, or start audio here.
    local w, h = lurek.window.getDimensions()
    lurek.log.info(string.format("ready — display %dx%d", w, h), "lifecycle")
  end
end

--@api-stub: lurek.process
-- Called every frame with delta time in seconds to run game logic.
do
  function lurek.process(dt)
    -- Move entities, run AI, update timers — all per-frame logic goes here.
    -- dt is the time since last frame (typically ~0.016s at 60 FPS).
    local speed = 200
    -- Example: player.x = player.x + speed * dt
  end
end

--@api-stub: lurek.process_late
-- Called after process each frame for logic that depends on updated positions.
do
  function lurek.process_late(dt)
    -- Camera follow, UI position sync, and post-movement adjustments.
    -- Runs after all process callbacks, so entity positions are final.
    -- Example: camera.x = lerp(camera.x, player.x, 5 * dt)
  end
end

--@api-stub: lurek.process_physics
-- Called at a fixed physics timestep rate for deterministic simulation.
do
  function lurek.process_physics(dt)
    -- Apply forces, check collisions — dt is constant (e.g. 1/60).
    -- This fires at a fixed rate regardless of frame rate.
    -- Example: body:applyForce(0, gravity * dt)
  end
end

--@api-stub: lurek.fixedUpdate
-- Alias for process_physics — called at fixed timestep for deterministic updates.
do
  function lurek.fixedUpdate(dt)
    -- Same purpose as process_physics. Use one or the other, not both.
    -- Useful if you prefer Unity-style naming.
  end
end

--@api-stub: lurek.draw
-- Called each frame after process to submit world-space draw commands.
do
  function lurek.draw()
    -- All world-space rendering: sprites, tilemaps, particles, debug lines.
    -- Camera transforms are active here; coordinates are in world space.
    lurek.render.setColor(0.3, 0.6, 1, 1)
    lurek.render.rectangle("fill", 100, 100, 64, 64)
  end
end

--@api-stub: lurek.draw_ui
-- Called after draw for screen-space HUD and UI overlay rendering.
do
  function lurek.draw_ui()
    -- No camera transform — pixel coordinates match screen pixels.
    -- Draw health bars, score, menus, debug text here.
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Score: 0", 10, 10)
  end
end

--@api-stub: lurek.quit
-- Called when the window close is requested. Return true to cancel the quit.
do
  function lurek.quit()
    -- Save progress before the engine shuts down.
    lurek.log.info("saving game state before exit", "lifecycle")
    -- Return true here to cancel the quit (e.g. show "are you sure?" dialog)
    return false
  end
end

--@api-stub: lurek.exit
-- Called during engine shutdown after quit — final cleanup opportunity.
do
  function lurek.exit()
    -- Release external resources, close network connections, flush logs.
    lurek.log.info("engine shutdown complete", "lifecycle")
  end
end

--@api-stub: lurek.resize
-- Called when the window is resized with the new pixel dimensions.
do
  function lurek.resize(w, h)
    -- Recalculate UI layout, recreate canvases, adjust camera viewport.
    lurek.log.info(string.format("window resized to %dx%d", w, h), "window")
    -- Example: canvas = lurek.render.newCanvas(w, h)
  end
end

--@api-stub: lurek.focus
-- Called when the window gains or loses input focus.
do
  function lurek.focus(has_focus)
    -- Pause the game when the window loses focus to avoid unfair deaths.
    if not has_focus then
      lurek.log.debug("window lost focus — pausing", "window")
      -- Example: game_paused = true
    else
      lurek.log.debug("window regained focus", "window")
    end
  end
end

--@api-stub: lurek.visible
-- Called when the window is shown or hidden (minimized/restored).
do
  function lurek.visible(is_visible)
    -- Stop expensive rendering or audio when the window is not visible.
    if not is_visible then
      lurek.log.debug("window hidden — reducing work", "window")
    end
  end
end

--@api-stub: lurek.keypressed
-- Called when a key is pressed with key name, scancode, and repeat flag.
do
  function lurek.keypressed(key, scancode, is_repeat)
    -- Handle discrete key actions: menu navigation, ability triggers.
    -- is_repeat is true when the OS sends repeated key events while held.
    if key == "escape" and not is_repeat then
      lurek.exit()
    elseif key == "f11" and not is_repeat then
      -- Toggle fullscreen
      lurek.log.info("fullscreen toggle requested", "input")
    end
  end
end

--@api-stub: lurek.keyreleased
-- Called when a key is released with key name and scancode.
do
  function lurek.keyreleased(key, scancode)
    -- Detect key-up for charge attacks or hold-to-sprint mechanics.
    if key == "space" then
      lurek.log.debug("jump key released — end variable jump", "input")
    end
  end
end

--@api-stub: lurek.textinput
-- Called when the user types a printable character (UTF-8 string).
do
  function lurek.textinput(char)
    -- Append typed characters to a text input buffer (chat, name entry).
    -- Unlike keypressed, this respects keyboard layout and IME.
    lurek.log.debug("text input: " .. char, "input")
    -- Example: input_buffer = input_buffer .. char
  end
end

--@api-stub: lurek.textedited
-- Called during IME composition with partial text, cursor start, and length.
do
  function lurek.textedited(text, start, length)
    -- Show the in-progress IME composition (e.g. Chinese/Japanese input).
    -- text is the partial composition; start/length indicate the cursor.
    lurek.log.debug(string.format("IME composing: '%s' cursor=%d len=%d",
      text, start, length), "input")
  end
end

--@api-stub: lurek.mousepressed
-- Called when a mouse button is pressed with pixel position and button index.
do
  function lurek.mousepressed(x, y, button)
    -- button 1=left, 2=right, 3=middle
    if button == 1 then
      lurek.log.debug(string.format("click at (%d, %d)", x, y), "input")
      -- Example: check UI hit, select unit, fire weapon
    elseif button == 2 then
      -- Right-click: context menu or secondary action
    end
  end
end

--@api-stub: lurek.mousereleased
-- Called when a mouse button is released with position and button index.
do
  function lurek.mousereleased(x, y, button)
    -- End drag operations, confirm box selections, release held abilities.
    if button == 1 then
      lurek.log.debug(string.format("released at (%d, %d)", x, y), "input")
    end
  end
end

--@api-stub: lurek.mousemoved
-- Called when the mouse cursor moves with position and delta values.
do
  function lurek.mousemoved(x, y, dx, dy)
    -- Track cursor for hover effects, tooltips, or camera rotation.
    -- dx/dy give the movement since last frame (useful for mouselook).
    -- Example: camera_angle = camera_angle + dx * sensitivity
  end
end

--@api-stub: lurek.wheelmoved
-- Called when the mouse wheel scrolls with horizontal and vertical deltas.
do
  function lurek.wheelmoved(x, y)
    -- y > 0 = scroll up, y < 0 = scroll down. Common uses: zoom, scroll lists.
    if y > 0 then
      lurek.log.debug("zoom in", "input")
      -- Example: zoom_level = math.min(zoom_level + 0.1, 3.0)
    elseif y < 0 then
      lurek.log.debug("zoom out", "input")
      -- Example: zoom_level = math.max(zoom_level - 0.1, 0.5)
    end
  end
end

--@api-stub: lurek.gamepadpressed
-- Called when a gamepad button is pressed with controller id and button name.
do
  function lurek.gamepadpressed(id, button)
    -- button names: "a", "b", "x", "y", "start", "back", "dpup", etc.
    if button == "a" then
      lurek.log.debug("gamepad " .. id .. ": jump", "input")
    elseif button == "start" then
      lurek.log.debug("gamepad " .. id .. ": pause menu", "input")
    end
  end
end

--@api-stub: lurek.gamepadreleased
-- Called when a gamepad button is released with controller id and button name.
do
  function lurek.gamepadreleased(id, button)
    if button == "a" then
      lurek.log.debug("gamepad " .. id .. ": jump released", "input")
    end
  end
end

--@api-stub: lurek.gamepadaxis
-- Called when a gamepad analog axis changes value (-1.0 to 1.0).
do
  function lurek.gamepadaxis(id, axis, value)
    -- axis names: "leftx", "lefty", "rightx", "righty", "triggerleft", "triggerright"
    -- Apply deadzone to avoid drift from resting stick position.
    local deadzone = 0.15
    if math.abs(value) < deadzone then value = 0 end
    if axis == "leftx" then
      -- Example: player.vx = value * player.speed
    elseif axis == "lefty" then
      -- Example: player.vy = value * player.speed
    end
  end
end

--@api-stub: lurek.joystickadded
-- Called when a gamepad or joystick is connected with the device id.
do
  function lurek.joystickadded(id)
    -- Assign the new controller to a player slot.
    lurek.log.info("controller " .. id .. " connected — ready for player assignment", "input")
  end
end

--@api-stub: lurek.joystickremoved
-- Called when a gamepad or joystick is disconnected with the device id.
do
  function lurek.joystickremoved(id)
    -- Pause the game and show "reconnect controller" prompt.
    lurek.log.info("controller " .. id .. " disconnected", "input")
    -- Example: show_reconnect_prompt(id)
  end
end

--@api-stub: lurek.touchpressed
-- Called when a touch begins with id, position, delta, and pressure.
do
  function lurek.touchpressed(id, x, y, dx, dy, pressure)
    -- Track active touches for multi-touch gestures (pinch, rotate).
    lurek.log.debug(string.format("touch %d start at (%.0f, %.0f) pressure=%.2f",
      id, x, y, pressure), "input")
    -- Example: active_touches[id] = { x = x, y = y, start_time = lurek.engine.uptime() }
  end
end

--@api-stub: lurek.touchreleased
-- Called when a touch point ends with id, final position, delta, and pressure.
do
  function lurek.touchreleased(id, x, y, dx, dy, pressure)
    -- Detect taps (short duration touches) vs drags.
    lurek.log.debug(string.format("touch %d ended at (%.0f, %.0f)", id, x, y), "input")
    -- Example: active_touches[id] = nil
  end
end

--@api-stub: lurek.touchmoved
-- Called when a touch point moves with id, position, delta, and pressure.
do
  function lurek.touchmoved(id, x, y, dx, dy, pressure)
    -- Use dx/dy for swipe detection or virtual joystick movement.
    -- Example: virtual_stick.x = virtual_stick.x + dx
  end
end

print("content/examples/engine.lua")
