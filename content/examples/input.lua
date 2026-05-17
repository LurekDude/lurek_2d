-- content/examples/input.lua
-- lurek.input API examples: keyboard, mouse, gamepad, touch, action bindings, combos, and replay.
-- Run: cargo run -- content/examples/input.lua

-- =============================================================================
-- KEYBOARD
-- =============================================================================

--@api-stub: lurek.input.isDown
-- Check if one or more keyboard keys are currently held down (variadic).
do
  function lurek.process(dt)
    -- Pass multiple key names; returns true if ANY of them is held.
    -- Useful for movement where WASD and arrows should both work.
    if lurek.input.keyboard.isDown("space", "w", "up") then
      -- Player is holding a jump/up key — apply upward velocity
      lurek.log.debug("jump key held — applying upward force", "input")
    end

    -- Typical 4-direction movement pattern:
    local dx, dy = 0, 0
    if lurek.input.keyboard.isDown("a", "left")  then dx = dx - 1 end
    if lurek.input.keyboard.isDown("d", "right") then dx = dx + 1 end
    if lurek.input.keyboard.isDown("w", "up")    then dy = dy - 1 end
    if lurek.input.keyboard.isDown("s", "down")  then dy = dy + 1 end
    if dx ~= 0 or dy ~= 0 then
      lurek.log.debug("moving: dx=" .. dx .. " dy=" .. dy, "input")
    end
  end
end

--@api-stub: lurek.input.isScancodeDown
-- Check if a physical scancode is held, ignoring keyboard layout remapping.
do
  function lurek.process(dt)
    -- Scancodes refer to physical key positions (hardware layout).
    -- On AZERTY keyboards, "a" is in the QWERTY "q" position.
    -- Use scancodes when you want consistent physical positions regardless of locale.
    if lurek.input.keyboard.isScancodeDown("a") then
      lurek.log.debug("physical 'A' position held (strafe-left)", "input")
    end
  end
end

--@api-stub: lurek.input.setKeyRepeat
-- Enable or disable OS key-repeat events reaching lurek.keypressed callback.
do
  -- Enable key repeat so that holding a key fires repeated keypressed events.
  -- Useful for menu navigation: holding "down" scrolls through items.
  lurek.input.keyboard.setKeyRepeat(true)
  lurek.log.info("key repeat enabled — menus will auto-scroll on hold", "input")
end

--@api-stub: lurek.input.hasKeyRepeat
-- Query whether key-repeat is currently enabled.
do
  local enabled = lurek.input.keyboard.hasKeyRepeat()
  if not enabled then
    -- Warn during startup so designers know menu UX will be affected
    lurek.log.warn("key repeat disabled — hold-to-scroll will not work in menus", "input")
  end
end

--@api-stub: lurek.input.setTextInput
-- Enable or disable text input mode (IME composition, unicode entry).
do
  local function open_chat()
    -- When a text field gains focus, enable text input so the OS can
    -- deliver composed characters (e.g. accented letters, CJK input).
    lurek.input.keyboard.setTextInput(true)
    lurek.log.info("chat box focused — text input mode on", "input")
  end

  local function close_chat()
    -- Disable text input when leaving the field, so normal game keys resume.
    lurek.input.keyboard.setTextInput(false)
    lurek.log.info("chat box closed — text input mode off", "input")
  end

  open_chat()
  close_chat()
end

--@api-stub: lurek.input.hasTextInput
-- Query whether text input mode is active (useful to suppress game controls).
do
  function lurek.process(dt)
    if lurek.input.keyboard.hasTextInput() then
      -- Player is typing in a text field — do not process movement keys
      return
    end
    -- Normal gameplay controls continue here...
  end
end

--@api-stub: lurek.input.getScancodeFromKey
-- Convert a logical key name (layout-dependent) to its physical scancode.
do
  -- Useful for showing the player which physical key to press in tutorials.
  local sc = lurek.input.keyboard.getScancodeFromKey("space")
  if sc then
    lurek.log.debug("'space' maps to physical scancode: " .. sc, "input")
  end
end

--@api-stub: lurek.input.getKeyFromScancode
-- Convert a physical scancode to its layout-dependent key name.
do
  -- Useful for displaying keybind labels that match the player's keyboard layout.
  local key_name = lurek.input.keyboard.getKeyFromScancode("lshift")
  local label = key_name or "unbound"
  lurek.log.info("crouch is bound to: " .. label, "ui")
end

--@api-stub: lurek.input.isModifierActive
-- Check if a modifier key (ctrl, shift, alt, gui) is currently held.
do
  function lurek.process(dt)
    -- Combine modifier checks with key checks for shortcuts like Ctrl+S
    if lurek.input.keyboard.isModifierActive("ctrl") and lurek.input.keyboard.isDown("s") then
      lurek.log.info("Ctrl+S pressed — triggering quick-save", "input")
    end

    -- Shift for sprint modifier
    if lurek.input.keyboard.isModifierActive("shift") and lurek.input.keyboard.isDown("w") then
      lurek.log.debug("sprinting forward", "input")
    end
  end
end

-- =============================================================================
-- MOUSE
-- =============================================================================

--@api-stub: lurek.input.getPosition
-- Get the current mouse cursor position in window coordinates.
do
  function lurek.process(dt)
    -- Returns two values: x and y in pixels from top-left corner
    local mx, my = lurek.input.mouse.getPosition()
    -- Use for aiming, UI hover detection, or world-space conversion
    lurek.log.debug("cursor at (" .. mx .. ", " .. my .. ")", "input")
  end
end

--@api-stub: lurek.input.getX
-- Get just the mouse x coordinate (avoids unpacking two values).
do
  function lurek.process(dt)
    local x = lurek.input.mouse.getX()
    -- Example: horizontal slider mapped to screen width
    local screen_width = 800
    local volume = math.max(0, math.min(1, x / screen_width))
    lurek.log.debug("volume slider value: " .. string.format("%.2f", volume), "ui")
  end
end

--@api-stub: lurek.input.getY
-- Get just the mouse y coordinate.
do
  function lurek.process(dt)
    local y = lurek.input.mouse.getY()
    -- Detect cursor in a specific screen region (e.g. top menu bar)
    if y < 32 then
      lurek.log.debug("cursor in top menu strip — show toolbar", "ui")
    end
  end
end

--@api-stub: lurek.input.setVisible
-- Show or hide the OS mouse cursor.
do
  -- Hide cursor during gameplay for a custom crosshair or cinematic
  lurek.input.mouse.setVisible(false)
  lurek.log.info("cursor hidden — using custom crosshair sprite", "input")
end

--@api-stub: lurek.input.isVisible
-- Query whether the OS cursor is currently visible.
do
  -- Restore cursor when opening pause menu
  if not lurek.input.mouse.isVisible() then
    lurek.input.mouse.setVisible(true)
    lurek.log.info("pause menu opened — OS cursor restored", "ui")
  end
end

--@api-stub: lurek.input.setGrabbed
-- Confine the cursor to the game window (prevents leaving window bounds).
do
  -- Grab + relative mode is the standard FPS mouselook setup
  lurek.input.mouse.setGrabbed(true)
  lurek.input.mouse.setRelativeMode(true)
  lurek.log.info("entered mouselook mode (grabbed + relative)", "input")
end

--@api-stub: lurek.input.isGrabbed
-- Query whether the mouse is grabbed by the window.
do
  if lurek.input.mouse.isGrabbed() then
    lurek.log.debug("mouse locked to window — Alt+Tab will release", "input")
  end
end

--@api-stub: lurek.input.setRelativeMode
-- Enable relative mode: cursor is hidden and dx/dy deltas are reported.
do
  -- Relative mode reports movement deltas instead of absolute position.
  -- Essential for camera rotation in first/third-person games.
  lurek.input.mouse.setRelativeMode(true)
  lurek.log.info("relative mouse: read dx/dy from lurek.mousemoved callback", "input")
end

--@api-stub: lurek.input.getRelativeMode
-- Query whether relative mouse mode is active.
do
  function lurek.process(dt)
    if lurek.input.mouse.getRelativeMode() then
      -- In relative mode, use mousemoved dx/dy for camera rotation
      lurek.log.debug("camera integrating mouse delta this frame", "camera")
    end
  end
end

--@api-stub: lurek.input.setPosition
-- Warp the cursor to a specific window position.
do
  -- Re-center cursor after each frame in a custom mouselook implementation
  local cx, cy = 400, 300
  lurek.input.mouse.setPosition(cx, cy)
  lurek.log.debug("cursor warped to center (" .. cx .. "," .. cy .. ")", "input")
end

--@api-stub: lurek.input.setCursor
-- Set the active cursor shape from a handle, system name, or nil for default arrow.
do
  -- Pass a string for built-in system cursors
  lurek.input.mouse.setCursor("hand")
  lurek.log.debug("cursor set to 'hand' — hovering a clickable element", "ui")
end

--@api-stub: lurek.input.newCursor
-- Create a custom cursor from RGBA pixel data with hotspot coordinates.
do
  -- Create a tiny 2x2 colored cursor for debugging
  -- Pixel data is a flat array: R,G,B,A for each pixel, row by row
  local w, h = 2, 2
  local pixels = {
    255, 0,   0,   255,   -- top-left: red
    0,   255, 0,   255,   -- top-right: green
    0,   0,   255, 255,   -- bottom-left: blue
    255, 255, 255, 255,   -- bottom-right: white
  }
  -- hotx, hoty define where the "click point" is within the image
  local cur = lurek.input.mouse.newCursor(pixels, w, h, 0, 0)
  lurek.input.mouse.setCursor(cur)
  lurek.log.debug("custom 2x2 debug cursor active", "input")
end

--@api-stub: lurek.input.getSystemCursor
-- Get a system cursor handle by name (crosshair, hand, ibeam, etc.).
do
  -- Pre-load system cursors at startup for fast switching during gameplay
  local crosshair = lurek.input.mouse.getSystemCursor("crosshair")
  function lurek.process(dt)
    -- Switch to crosshair when aiming
    lurek.input.mouse.setCursor(crosshair)
  end
end

--@api-stub: lurek.input.isCursorSupported
-- Check if the platform supports custom/system cursor changes.
do
  if lurek.input.mouse.isCursorSupported() then
    lurek.input.mouse.setCursor("hand")
    lurek.log.debug("custom cursors supported on this platform", "input")
  else
    -- Fallback: draw a sprite at mouse position instead
    lurek.log.warn("custom cursors unsupported — using sprite fallback", "input")
  end
end

--@api-stub: lurek.input.getCursor
-- Get the name of the currently active cursor.
do
  local name = lurek.input.mouse.getCursor()
  lurek.log.debug("active cursor: " .. name, "ui")
end

--@api-stub: lurek.input.getWheelDelta
-- Get mouse wheel scroll delta this frame (horizontal, vertical).
do
  function lurek.process(dt)
    local dx, dy = lurek.input.mouse.getWheelDelta()
    -- dy > 0 = scroll up (zoom in), dy < 0 = scroll down (zoom out)
    if dy ~= 0 then
      lurek.log.debug("zoom delta: " .. dy, "camera")
    end
    -- dx is for horizontal scroll wheels or trackpad gestures
    if dx ~= 0 then
      lurek.log.debug("horizontal scroll: " .. dx, "ui")
    end
  end
end

-- =============================================================================
-- GAMEPAD
-- =============================================================================

--@api-stub: lurek.input.getCount
-- Get the number of gamepad slots currently tracked by the runtime.
do
  local n = lurek.input.gamepad.getCount()
  lurek.log.info("gamepad slots tracked: " .. n, "input")
end

--@api-stub: lurek.input.getJoystickCount
-- Get the number of joystick slots tracked (may differ from gamepad count).
do
  local slots = lurek.input.gamepad.getJoystickCount()
  if slots == 0 then
    lurek.log.info("no joystick devices detected", "input")
  end
end

--@api-stub: lurek.input.getJoysticks
-- Get an array of connected gamepad IDs for iterating players.
do
  local ids = lurek.input.gamepad.getJoysticks()
  -- Assign each connected gamepad to a player slot
  for i, id in ipairs(ids) do
    lurek.log.debug("player " .. i .. " assigned to gamepad id " .. id, "input")
  end
end

--@api-stub: lurek.input.isConnected
-- Check if a specific gamepad ID is currently connected.
do
  local id = 0
  if not lurek.input.gamepad.isConnected(id) then
    -- Show "press Start to join" or fall back to keyboard
    lurek.log.warn("player 1 controller not connected", "input")
  end
end

--@api-stub: lurek.input.getName
-- Get the human-readable display name of a gamepad.
do
  local id = 0
  local name = lurek.input.gamepad.getName(id)
  -- Show in options menu so players know which controller is which
  lurek.log.info("gamepad " .. id .. " name: " .. name, "input")
end

--@api-stub: lurek.input.isGamepad
-- Check if a joystick slot has a recognized gamepad mapping (SDL layout).
do
  local id = 0
  if lurek.input.gamepad.isGamepad(id) then
    -- Has standard A/B/X/Y/LB/RB/triggers/sticks mapping
    lurek.log.debug("slot " .. id .. " is a mapped gamepad (standard layout)", "input")
  else
    -- Raw joystick — button indices may vary
    lurek.log.debug("slot " .. id .. " is an unmapped joystick", "input")
  end
end

--@api-stub: lurek.input.getButtonCount
-- Get the number of buttons on a gamepad.
do
  local id = 0
  local nbtn = lurek.input.gamepad.getButtonCount(id)
  lurek.log.debug("gamepad " .. id .. " has " .. nbtn .. " buttons", "input")
end

--@api-stub: lurek.input.getAxisCount
-- Get the number of axes on a gamepad (sticks + triggers).
do
  local id = 0
  local naxis = lurek.input.gamepad.getAxisCount(id)
  -- Standard controller: 6 axes (2 sticks x2 + 2 triggers)
  if naxis < 4 then
    lurek.log.warn("gamepad " .. id .. " has only " .. naxis .. " axes — dual-stick unavailable", "input")
  end
end

--@api-stub: lurek.input.getAxis
-- Read an analog axis value (-1.0 to 1.0 for sticks, 0.0 to 1.0 for triggers).
do
  function lurek.process(dt)
    -- Axis 0 = left stick X, axis 1 = left stick Y (typically)
    local lx = lurek.input.gamepad.getAxis(0, 0)
    local ly = lurek.input.gamepad.getAxis(0, 1)

    -- Apply deadzone to avoid drift from resting stick position
    local deadzone = 0.15
    if math.abs(lx) < deadzone then lx = 0 end
    if math.abs(ly) < deadzone then ly = 0 end

    if lx ~= 0 or ly ~= 0 then
      lurek.log.debug("left stick: (" .. string.format("%.2f", lx) .. ", " .. string.format("%.2f", ly) .. ")", "input")
    end
  end
end

--@api-stub: lurek.input.isVibrationSupported
-- Check if a gamepad supports haptic feedback (rumble).
do
  local id = 0
  if lurek.input.gamepad.isVibrationSupported(id) then
    lurek.log.info("gamepad " .. id .. " supports rumble — haptics enabled", "input")
  else
    lurek.log.info("gamepad " .. id .. " has no rumble motor", "input")
  end
end

--@api-stub: lurek.input.vibrate
-- Trigger gamepad vibration with asymmetric motor strengths and duration.
do
  -- low_freq = heavy motor (body rumble), high_freq = light motor (texture feel)
  -- duration_ms = how long the vibration lasts
  local id = 0
  local low_freq = 0.4   -- gentle body thump
  local high_freq = 0.8  -- strong buzz
  local duration_ms = 250
  local ok = lurek.input.gamepad.vibrate(id, low_freq, high_freq, duration_ms)
  if not ok then
    lurek.log.debug("vibrate request ignored (no haptics backend)", "input")
  end
end

--@api-stub: lurek.input.getGUID
-- Get the unique hardware GUID for a gamepad (for mapping lookups).
do
  local guid = lurek.input.gamepad.getGUID(0)
  if guid ~= "" then
    -- GUIDs identify controller hardware for custom mapping databases
    lurek.log.debug("gamepad 0 GUID: " .. guid, "input")
  end
end

--@api-stub: lurek.input.getHat
-- Read a gamepad hat (d-pad on older controllers) direction string.
do
  -- Hat returns a direction code: "c"=center, "u"=up, "d"=down, "l"=left, "r"=right,
  -- "lu"=left-up, "ld"=left-down, "ru"=right-up, "rd"=right-down
  local dir = lurek.input.gamepad.getHat(0, 0)
  if dir ~= "c" then
    lurek.log.debug("d-pad hat direction: " .. dir, "input")
  end
end

--@api-stub: lurek.input.setVibration
-- Alternate vibration API with same signature as vibrate.
do
  local id = 0
  local ok = lurek.input.gamepad.setVibration(id, 0.5, 0.5, 200)
  lurek.log.debug("setVibration queued: " .. tostring(ok), "input")
end

--@api-stub: lurek.input.wasPressed
-- Check if a gamepad button was pressed THIS frame (edge-triggered, not held).
do
  function lurek.process(dt)
    -- Button 0 is typically "A" on Xbox / "Cross" on PlayStation
    if lurek.input.gamepad.wasPressed(0, 0) then
      -- Use for one-shot actions: jump, confirm, interact
      lurek.log.info("gamepad A pressed — jump triggered", "input")
    end
  end
end

--@api-stub: lurek.input.wasReleased
-- Check if a gamepad button was released THIS frame (edge-triggered).
do
  function lurek.process(dt)
    -- Useful for charged attacks: start charge on press, release on release
    if lurek.input.gamepad.wasReleased(0, 0) then
      lurek.log.info("gamepad A released — charged shot fired", "input")
    end
  end
end

--@api-stub: lurek.input.wasConnected
-- Check if a gamepad connected during this frame (hot-plug detection).
do
  function lurek.process(dt)
    if lurek.input.gamepad.wasConnected(0) then
      -- Show "controller connected" notification, assign to player slot
      lurek.log.info("player 1 controller connected — switching to gamepad mode", "input")
    end
  end
end

--@api-stub: lurek.input.wasDisconnected
-- Check if a gamepad disconnected during this frame.
do
  function lurek.process(dt)
    if lurek.input.gamepad.wasDisconnected(0) then
      -- Pause the game and show reconnection prompt
      lurek.log.warn("controller disconnected — pausing game", "input")
    end
  end
end

--@api-stub: lurek.input.virtualDpad
-- Convert analog stick values into a virtual d-pad with direction and booleans.
do
  function lurek.process(dt)
    local lx = lurek.input.gamepad.getAxis(0, 0)
    local ly = lurek.input.gamepad.getAxis(0, 1)

    -- virtualDpad applies a deadzone and returns: up, down, left, right (booleans)
    -- and direction (string: "c", "u", "d", "l", "r", "lu", "ld", "ru", "rd")
    local pad = lurek.input.gamepad.virtualDpad(lx, ly, 0.25)

    if pad.direction ~= "c" then
      lurek.log.debug("virtual dpad: " .. pad.direction, "input")
    end

    -- Use booleans for grid-based movement
    if pad.up then
      lurek.log.debug("dpad UP — move character north", "input")
    end
  end
end

--@api-stub: lurek.input.setBackgroundEvents
-- Enable or disable gamepad input while the window is unfocused.
do
  -- Useful for streaming overlays or multi-window setups
  lurek.input.gamepad.setBackgroundEvents(true)
  lurek.log.info("gamepad input continues while window is unfocused", "input")
end

--@api-stub: lurek.input.getBackgroundEvents
-- Query whether background gamepad events are enabled.
do
  local on = lurek.input.gamepad.getBackgroundEvents()
  lurek.log.debug("background gamepad events: " .. tostring(on), "input")
end

--@api-stub: lurek.input.setGamepadMapping
-- Store a custom SDL-style mapping string for a specific gamepad GUID.
do
  -- SDL mapping format: GUID,Name,button:bN,axis:aN,...
  local guid = "030000005e040000130b000011050000"
  local mapping = guid .. ",My Custom Pad,a:b0,b:b1,x:b2,y:b3,start:b7,back:b6,"
  lurek.input.gamepad.setGamepadMapping(guid, mapping)
  lurek.log.info("custom mapping stored for GUID " .. guid, "input")
end

--@api-stub: lurek.input.getGamepadMappingString
-- Retrieve the stored mapping string for a gamepad GUID.
do
  local guid = "030000005e040000130b000011050000"
  local mapping = lurek.input.gamepad.getGamepadMappingString(guid)
  if mapping then
    lurek.log.debug("mapping for " .. guid .. ": " .. #mapping .. " chars", "input")
  else
    lurek.log.debug("no custom mapping for " .. guid, "input")
  end
end

--@api-stub: lurek.input.loadGamepadMappings
-- Load gamepad mappings from a file (SDL GameControllerDB format).
do
  -- Wrap in pcall because the file may not exist in headless/test environments
  local ok, n = pcall(lurek.input.gamepad.loadGamepadMappings, "save/gamecontrollerdb.txt")
  if ok then
    lurek.log.info("loaded controller mappings from file", "input")
  else
    lurek.log.debug("gamecontrollerdb.txt not found — using built-in mappings", "input")
  end
end

--@api-stub: lurek.input.saveGamepadMappings
-- Save all current gamepad mappings to a file for persistence.
do
  -- Save user's custom mappings so they persist across sessions
  lurek.input.gamepad.saveGamepadMappings("save/user_mappings.txt")
  lurek.log.info("user gamepad mappings saved to disk", "input")
end

-- =============================================================================
-- TOUCH
-- =============================================================================

--@api-stub: lurek.input.getTouches
-- Get all active touch points with id, position, and pressure.
do
  function lurek.process(dt)
    local touches = lurek.input.touch.getTouches()
    -- Each touch has: id (unique per finger), x, y, pressure
    for _, tp in ipairs(touches) do
      lurek.log.debug("touch " .. tp.id .. " at (" .. tp.x .. ", " .. tp.y .. ")", "input")
    end
  end
end

--@api-stub: lurek.input.getPressure
-- Get pressure value for a specific touch ID (0.0 to 1.0).
do
  function lurek.process(dt)
    local touches = lurek.input.touch.getTouches()
    if touches[1] then
      local p = lurek.input.touch.getPressure(touches[1].id)
      -- Use pressure for brush size in a drawing app
      if p > 0.5 then
        lurek.log.debug("firm press (pressure " .. string.format("%.2f", p) .. ")", "input")
      end
    end
  end
end

--@api-stub: lurek.input.getTouchCount
-- Get the number of currently active touch points.
do
  function lurek.process(dt)
    local count = lurek.input.touch.getTouchCount()
    -- Detect pinch-to-zoom gesture (two fingers)
    if count >= 2 then
      lurek.log.debug("multi-touch: " .. count .. " fingers — pinch gesture?", "input")
    end
  end
end

-- =============================================================================
-- ACTION BINDINGS (rebindable input layer)
-- =============================================================================

--@api-stub: lurek.input.bind
-- Bind one or more keys to a named action (supports string or array of strings).
do
  -- Single key binding
  lurek.input.bind("jump", "space")

  -- Multiple keys for one action — player can use any of them
  lurek.input.bind("move_left", { "a", "left" })
  lurek.input.bind("move_right", { "d", "right" })
  lurek.input.bind("attack", { "left", "gamepad:0:0" })  -- mouse left OR gamepad A

  lurek.log.info("default action bindings installed", "input")
end

--@api-stub: lurek.input.unbind
-- Remove all bindings for a named action. Returns true if the action existed.
do
  lurek.input.bind("jump", "space")
  -- Player clears a binding in the options menu
  local existed = lurek.input.unbind("jump")
  lurek.log.debug("unbind 'jump': had bindings = " .. tostring(existed), "input")
end

--@api-stub: lurek.input.clearBindings
-- Remove ALL action bindings (reset to empty before loading new profile).
do
  lurek.input.bind("jump", "space")
  lurek.input.bind("fire", "left")
  -- Clear everything before loading a new keybind profile
  lurek.input.clearBindings()
  lurek.log.info("all bindings cleared — ready to load new profile", "input")
end

--@api-stub: lurek.input.getBindings
-- Get a table of all current action bindings (action_name -> {keys}).
do
  lurek.input.bind("jump", "space")
  lurek.input.bind("move_left", { "a", "left" })

  -- Useful for displaying current bindings in an options screen
  local bindings = lurek.input.getBindings()
  for action, keys in pairs(bindings) do
    lurek.log.debug(action .. " bound to: " .. table.concat(keys, ", "), "input")
  end
end

--@api-stub: lurek.input.isActionDown
-- Check if any key bound to an action is currently held (continuous).
do
  lurek.input.bind("jump", { "space", "w" })
  function lurek.process(dt)
    -- Use for continuous actions like holding jump for variable height
    if lurek.input.isActionDown("jump") then
      lurek.log.debug("jump action held — extending jump height", "input")
    end
  end
end

--@api-stub: lurek.input.wasActionPressed
-- Check if any key bound to an action was pressed THIS frame (edge-triggered).
do
  lurek.input.bind("confirm", "return")
  function lurek.process(dt)
    -- Use for one-shot actions: menu select, interact, fire
    if lurek.input.wasActionPressed("confirm") then
      lurek.log.info("menu: option confirmed", "ui")
    end
  end
end

--@api-stub: lurek.input.wasActionReleased
-- Check if any key bound to an action was released THIS frame.
do
  lurek.input.bind("shoot", "left")
  function lurek.process(dt)
    -- Release-triggered actions: charged attacks, bow release
    if lurek.input.wasActionReleased("shoot") then
      lurek.log.info("charged shot released — firing projectile", "combat")
    end
  end
end

--@api-stub: lurek.input.wasActionPressedWithin
-- Check if an action was pressed within a recent frame window (input buffering).
do
  lurek.input.bind("jump", "space")
  function lurek.process(dt)
    -- Input buffering: accept jump input if pressed within last 6 frames.
    -- This makes platformers feel responsive — player can press jump slightly
    -- before landing and it still registers.
    if lurek.input.wasActionPressedWithin("jump", 6) then
      lurek.log.debug("buffered jump accepted (within 6-frame window)", "input")
    end
  end
end

--@api-stub: lurek.input.newMapping
-- Create a mapping object that bundles an action with isDown/wasPressed/wasReleased closures.
do
  -- newMapping creates and binds in one call, returning a query table.
  -- Cleaner than separate bind() + isActionDown() calls for per-character abilities.
  local dash = lurek.input.newMapping("dash", { "shift", "gamepad:0:0" })

  function lurek.process(dt)
    -- The mapping object has .isDown(), .wasPressed(), .wasReleased() closures
    if dash.wasPressed() then
      lurek.log.info("dash triggered!", "input")
    end
    if dash.isDown() then
      lurek.log.debug("dash held — maintaining velocity", "input")
    end
  end
end

-- =============================================================================
-- COMBO SYSTEM
-- =============================================================================

--@api-stub: lurek.input.newCombo
-- Create a combo detector for sequential key inputs with optional timing constraints.
do
  -- Simple combo: press down, right, then attack in sequence
  -- opts.total_gap limits how long the entire sequence can take (ms)
  local hadouken = lurek.input.newCombo(
    { "down", { key = "right", gap = 300 }, "a" },
    { total_gap = 1500 }
  )
  -- gap per step = max ms allowed between that step and the previous one
  -- total_gap = max ms for the entire combo from first to last input
  lurek.log.info("hadouken combo ready (" .. hadouken:totalSteps() .. " steps)", "combat")
end

-- =============================================================================
-- RECORDING & PLAYBACK (replay system)
-- =============================================================================

--@api-stub: lurek.input.startRecording
-- Begin recording all input events into the internal recorder.
do
  -- Start recording at the beginning of a level for replay/ghost data
  lurek.input.startRecording()
  lurek.log.info("input recording started", "replay")
end

--@api-stub: lurek.input.stopRecording
-- Stop recording and get the captured LInputRecording handle.
do
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    -- rec is an LInputRecording handle — serialize with :toJson()
    lurek.log.info("captured " .. rec:totalFrames() .. " frames of input", "replay")
  end
end

--@api-stub: lurek.input.loadRecording
-- Load a JSON recording string into the recorder for playback.
do
  -- Load a previously saved recording (e.g. from a file)
  local json = '{"version":1,"total_frames":1,"frames":[]}'
  lurek.input.loadRecording(json)
  lurek.log.info("recording loaded — ready for playback", "replay")
end

--@api-stub: lurek.input.startPlayback
-- Begin playing back the loaded recording (replays input events each frame).
do
  local json = '{"version":1,"total_frames":1,"frames":[]}'
  lurek.input.loadRecording(json)
  -- Once started, advancePlayback() returns events each frame
  lurek.input.startPlayback()
  lurek.log.info("playback started — live input suppressed", "replay")
end

--@api-stub: lurek.input.stopPlayback
-- Stop playback and return to live input.
do
  lurek.input.stopPlayback()
  lurek.log.info("playback stopped — live input restored", "replay")
end

--@api-stub: lurek.input.isRecording
-- Query whether the recorder is currently capturing input.
do
  if lurek.input.isRecording() then
    -- Show a red "REC" indicator in the HUD
    lurek.log.debug("REC indicator should be visible", "ui")
  end
end

--@api-stub: lurek.input.isPlayingBack
-- Query whether the recorder is currently replaying.
do
  function lurek.process(dt)
    if lurek.input.isPlayingBack() then
      -- During playback, skip live input processing
      return
    end
    -- Normal live input handling...
  end
end

--@api-stub: lurek.input.getPlaybackFrame
-- Get the current frame index during playback.
do
  function lurek.process(dt)
    local f = lurek.input.getPlaybackFrame()
    -- Show progress bar in replay viewer
    if f > 0 and f % 60 == 0 then
      lurek.log.debug("replay at frame " .. f .. " (second " .. (f / 60) .. ")", "replay")
    end
  end
end

--@api-stub: lurek.input.advancePlayback
-- Advance playback by one frame and get the events for that frame.
do
  function lurek.process(dt)
    -- Each call returns an array of event records: {kind="press", name="space"}
    local events = lurek.input.advancePlayback()
    for _, ev in ipairs(events) do
      -- Feed events into the game as if they were live input
      lurek.log.debug("replay event: " .. ev.kind .. " " .. ev.name, "replay")
    end
  end
end

-- =============================================================================
-- CURSOR HANDLE METHODS
-- =============================================================================

--@api-stub: Cursor:release
-- Release cursor resources (no-op on desktop, but good practice for cleanup).
do
  local cur = lurek.input.mouse.getSystemCursor("hand")
  -- Call release when done with a cursor to signal intent (future-proofs for mobile)
  cur:release()
  lurek.log.debug("cursor handle released", "input")
end

--@api-stub: Cursor:getType
-- Get whether this cursor is "system" or "custom".
do
  local cur = lurek.input.mouse.getSystemCursor("crosshair")
  local kind = cur:getType()
  -- Returns "system" for getSystemCursor results, "custom" for newCursor results
  lurek.log.debug("cursor type: " .. kind, "input")
end

-- =============================================================================
-- COMBO HANDLE METHODS
-- =============================================================================

--@api-stub: Combo:feed
-- Feed a key press into the combo detector. Returns progress status string.
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  -- feed() returns: "completed", "advanced", "broken", or "idle"
  local result = combo:feed("down")
  lurek.log.debug("fed 'down' to combo — result: " .. result, "combat")
  -- "advanced" means the key matched the next expected step
  -- "completed" means the full sequence was entered successfully
  -- "broken" means wrong key broke the sequence
  -- "idle" means no combo is in progress and key did not start one
end

--@api-stub: Combo:tick
-- Update combo timeout state. Call every frame to expire stale combos.
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  function lurek.process(dt)
    -- tick() returns: "expired", "in_progress", or "idle"
    local status = combo:tick(dt)
    if status == "expired" then
      -- Player took too long between inputs — combo window closed
      lurek.log.debug("combo timed out", "combat")
    end
  end
end

--@api-stub: Combo:reset
-- Manually reset combo progress (e.g. after player gets hit/staggered).
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  combo:feed("down")
  -- Player got interrupted — clear combo progress
  combo:reset()
  lurek.log.debug("combo reset after stagger", "combat")
end

--@api-stub: Combo:totalSteps
-- Get the total number of steps in this combo sequence.
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  local total = combo:totalSteps()
  -- Useful for drawing a combo step indicator in the HUD
  lurek.log.debug("combo has " .. total .. " steps", "combat")
end

--@api-stub: Combo:isInProgress
-- Check if the combo has been partially matched (player started the sequence).
do
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  combo:feed("down")
  if combo:isInProgress() then
    -- Show combo progress indicator in the HUD
    lurek.log.debug("combo in progress — show HUD indicator", "ui")
  end
end

--@api-stub: Combo:getStep
-- Get step data by 1-based index (returns table with key and gap_ms fields).
do
  local combo = lurek.input.newCombo({ "down", { key = "right", gap = 300 }, "a" })
  local step = combo:getStep(2)
  if step then
    -- step.key = the key name, step.gap_ms = max time allowed for this step
    lurek.log.debug("step 2: key=" .. step.key .. " gap=" .. step.gap_ms .. "ms", "combat")
  end
end

-- =============================================================================
-- INPUT RECORDING HANDLE METHODS
-- =============================================================================

--@api-stub: InputRecording:toJson
-- Serialize the recording to JSON for saving to disk.
do
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    -- Save replay data to a file for later playback
    local json = rec:toJson()
    lurek.log.debug("recording serialized: " .. #json .. " bytes", "replay")
    -- Could write to file: lurek.filesystem.write("replay.json", json)
  end
end

--@api-stub: InputRecording:totalFrames
-- Get the total number of frames in this recording.
do
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    -- Use totalFrames for progress bar length in replay viewer
    lurek.log.info("recording length: " .. rec:totalFrames() .. " frames", "replay")
  end
end

--@api-stub: InputRecording:frameCount
-- Get the number of event-containing frames (frames that had input activity).
do
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec and rec:frameCount() == 0 then
    -- No input was captured (recording was too short or player was idle)
    lurek.log.warn("recording has no input events — nothing to replay", "replay")
  end
end

--@api-stub: Combo:progress
-- Get the number of completed combo steps so far.
do
  local combo = lurek.input.newCombo({ "right", "right", "attack" })
  combo:feed("right")
  local steps_done = combo:progress()
  -- Use for HUD: highlight completed steps in the combo display
  lurek.log.info("combo progress: " .. steps_done .. "/" .. combo:totalSteps(), "input")
end

--@api-stub: lurek.input.gamepad.loadGamepadMappings
-- Load gamepad mappings from file (alternate call path via gamepad sub-table).
do
  -- Same as lurek.input.gamepad.loadGamepadMappings above; pcall for safety
  local ok, count = pcall(lurek.input.gamepad.loadGamepadMappings, "assets/gamecontrollerdb.txt")
  lurek.log.info("loadGamepadMappings ok=" .. tostring(ok), "input")
end

-- =============================================================================
-- TYPE INTROSPECTION (handle type checks)
-- =============================================================================

--@api-stub: LCombo:type
-- Returns the Lua-visible type name for this combo handle.
do
  local ok ---@type boolean
  local combo_obj ---@type LCombo?
  ok, combo_obj = pcall(lurek.input.newCombo, {"a","b"}, {})
  if not ok then combo_obj = nil end
  local t = combo_obj and combo_obj:type() or "LInputCombo"
  lurek.log.info("LCombo:type = " .. t, "input")
end

--@api-stub: LCombo:typeOf
-- Check if a combo handle matches a given type name.
do
  local ok_c2 ---@type boolean
  local combo_obj2 ---@type LCombo?
  ok_c2, combo_obj2 = pcall(lurek.input.newCombo, {"a","b"}, {})
  if not ok_c2 then combo_obj2 = nil end
  -- typeOf checks against "LCombo" and "Object"
  lurek.log.info("is LCombo: " .. tostring(combo_obj2 and combo_obj2:typeOf("LCombo") or false), "input")
  lurek.log.info("is wrong: " .. tostring(combo_obj2 and combo_obj2:typeOf("Unknown") or false), "input")
end

--@api-stub: LCursor:type
-- Returns the Lua-visible type name for this cursor handle.
do
  local ok_c, cursor_obj = pcall(lurek.input.mouse.newCursor)
  if ok_c and cursor_obj then
    local t = cursor_obj:type()
    lurek.log.info("LCursor:type = " .. t, "input")
  else
    lurek.log.info("LCursor:type = skipped", "input")
  end
end

--@api-stub: LCursor:typeOf
-- Check if a cursor handle matches a given type name.
do
  local ok_c2, cursor_obj = pcall(lurek.input.mouse.newCursor)
  if ok_c2 and cursor_obj then
    lurek.log.info("is LCursor: " .. tostring(cursor_obj:typeOf("LCursor")), "input")
    lurek.log.info("is wrong: " .. tostring(cursor_obj:typeOf("Unknown")), "input")
  else
    lurek.log.info("LCursor:typeOf = skipped", "input")
  end
end

--@api-stub: LInputRecording:type
-- Returns the Lua-visible type name for this input recording handle.
do
  local obj = lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    local _ = rec:toJson()
  end
  local t = obj and obj:type() or "LInputRecording"
  lurek.log.info("LInputRecording:type = " .. t, "input")
end

--@api-stub: LInputRecording:typeOf
-- Check if an input recording handle matches a given type name.
do
  local obj = lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    local _ = rec:toJson()
  end
  lurek.log.info("is LInputRecording: " .. tostring(obj and obj:typeOf("LInputRecording") or false), "input")
  lurek.log.info("is wrong: " .. tostring(obj and obj:typeOf("Unknown") or false), "input")
end

print("content/examples/input.lua")

-- =============================================================================
-- STUBS: 12 uncovered lurek.input API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LCombo methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCombo:feed ---------------------------------------------------
--@api-stub: LCombo:feed
-- Feeds one key into the combo detector and returns progress status.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCombo_stub:feed("player_score")  -- -> string
-- (replace lCombo_stub with your real LCombo instance above)

-- ---- Stub: LCombo:tick ---------------------------------------------------
--@api-stub: LCombo:tick
-- Advances combo timeout state and returns progress status.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCombo_stub:tick(0.016)  -- -> string
-- (replace lCombo_stub with your real LCombo instance above)

-- ---- Stub: LCombo:reset --------------------------------------------------
--@api-stub: LCombo:reset
-- Resets combo progress and elapsed time.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCombo_stub:reset()
-- (replace lCombo_stub with your real LCombo instance above)

-- ---- Stub: LCombo:progress -----------------------------------------------
--@api-stub: LCombo:progress
-- Returns the current combo step index reached.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCombo_stub:progress()  -- -> integer
-- (replace lCombo_stub with your real LCombo instance above)

-- ---- Stub: LCombo:totalSteps ---------------------------------------------
--@api-stub: LCombo:totalSteps
-- Returns the number of steps in this combo sequence.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCombo_stub:totalSteps()  -- -> integer
-- (replace lCombo_stub with your real LCombo instance above)

-- ---- Stub: LCombo:isInProgress -------------------------------------------
--@api-stub: LCombo:isInProgress
-- Returns whether the combo sequence is partially matched.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCombo_stub:isInProgress()  -- -> boolean
-- (replace lCombo_stub with your real LCombo instance above)

-- ---- Stub: LCombo:getStep ------------------------------------------------
--@api-stub: LCombo:getStep
-- Returns step data by one-based index.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCombo_stub:getStep(1)  -- -> LuaValue
-- (replace lCombo_stub with your real LCombo instance above)

-- -----------------------------------------------------------------------------
-- LCursor methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCursor:release -----------------------------------------------
--@api-stub: LCursor:release
-- Releases cursor resources; currently a no-op for managed cursor handles.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCursor_stub:release()
-- (replace lCursor_stub with your real LCursor instance above)

-- ---- Stub: LCursor:getType -----------------------------------------------
--@api-stub: LCursor:getType
-- Returns whether this cursor is a system cursor or custom cursor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCursor_stub:getType()  -- -> string
-- (replace lCursor_stub with your real LCursor instance above)

-- -----------------------------------------------------------------------------
-- LInputRecording methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LInputRecording:toJson ----------------------------------------
--@api-stub: LInputRecording:toJson
-- Serializes this input recording to JSON text.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInputRecording_stub:toJson()  -- -> string
-- (replace lInputRecording_stub with your real LInputRecording instance above)

-- ---- Stub: LInputRecording:totalFrames -----------------------------------
--@api-stub: LInputRecording:totalFrames
-- Returns total frame count stored in this recording.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInputRecording_stub:totalFrames()  -- -> integer
-- (replace lInputRecording_stub with your real LInputRecording instance above)

-- ---- Stub: LInputRecording:frameCount ------------------------------------
--@api-stub: LInputRecording:frameCount
-- Returns the number of event frames stored in this recording.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lInputRecording_stub:frameCount()  -- -> integer
-- (replace lInputRecording_stub with your real LInputRecording instance above)
