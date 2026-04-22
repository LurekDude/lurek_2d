-- content/examples/input.lua
-- Hand-written coverage of the lurek.input API (80 items).
--
-- The lurek.input namespace is split into four device tables:
-- lurek.input.keyboard, lurek.input.mouse, lurek.input.gamepad,
-- and lurek.input.touch.  Top-level lurek.input.* holds higher-level
-- helpers: action bindings (bind/isActionDown), combo detectors
-- (newCombo), and frame-by-frame recording/playback.  Polling-style
-- queries are wrapped in lurek.process(dt) so they actually run.
--
-- Run: cargo run -- content/examples/input.lua


-- ── lurek.input.* functions ──

--@api-stub: lurek.input.isDown
-- Returns true if any of the given keys is currently held down.
-- Pass several key names to OR them together — useful for binding both WASD and arrow keys to the same action.
do  -- lurek.input.isDown
  function lurek.process(dt)
    if lurek.input.keyboard.isDown("space", "w", "up") then
      lurek.log.debug("jump key held", "input")
    end
  end
end

--@api-stub: lurek.input.isScancodeDown
-- Returns whether the key with the given scancode is held.
-- Use scancodes when you want layout-independent input (WASD on AZERTY keyboards still uses scancode "w").
do  -- lurek.input.isScancodeDown
  function lurek.process(dt)
    if lurek.input.keyboard.isScancodeDown("a") then
      lurek.log.debug("strafe-left scancode held", "input")
    end
  end
end

--@api-stub: lurek.input.setKeyRepeat
-- Enables or disables key-repeat events.
-- Call once at startup; enable for text fields and menu navigation, disable for action games to avoid spurious presses.
do  -- lurek.input.setKeyRepeat
  lurek.input.keyboard.setKeyRepeat(true)
  lurek.log.info("key repeat enabled for menu navigation", "input")
end

--@api-stub: lurek.input.hasKeyRepeat
-- Returns whether key-repeat is currently enabled.
-- Read after a settings reload to confirm the value the engine actually applied before persisting it back to disk.
do  -- lurek.input.hasKeyRepeat
  local enabled = lurek.input.keyboard.hasKeyRepeat()
  if not enabled then
    lurek.log.warn("key repeat disabled — menus will feel sluggish", "input")
  end
end

--@api-stub: lurek.input.setTextInput
-- Enables or disables Unicode text input mode.
-- Toggle on when a chat box or rename dialog gains focus, then off again so movement keys do not type into the world.
do  -- lurek.input.setTextInput
  local function open_chat()
    lurek.input.keyboard.setTextInput(true)
    lurek.log.info("chat box focused; text input on", "input")
  end
  open_chat()
end

--@api-stub: lurek.input.hasTextInput
-- Returns whether text input mode is currently active.
-- Branch on this in lurek.process to skip game-action key handling while the player is typing.
do  -- lurek.input.hasTextInput
  function lurek.process(dt)
    if lurek.input.keyboard.hasTextInput() then
      return  -- typing in chat: do not move the player
    end
  end
end

--@api-stub: lurek.input.getScancodeFromKey
-- Returns the hardware scancode for the given key name.
-- Save scancodes (not key names) in rebindable-controls config so layout switches keep the physical key the player chose.
do  -- lurek.input.getScancodeFromKey
  local sc = lurek.input.keyboard.getScancodeFromKey("space")
  if sc then
    lurek.log.debug("space maps to scancode " .. sc, "input")
  end
end

--@api-stub: lurek.input.getKeyFromScancode
-- Returns the key name for the given hardware scancode.
-- Use to display the human-readable label for a saved scancode binding in a controls menu.
do  -- lurek.input.getKeyFromScancode
  local key_name = lurek.input.keyboard.getKeyFromScancode("lshift")
  local label = key_name or "unbound"
  lurek.log.info("crouch is bound to: " .. label, "ui")
end

--@api-stub: lurek.input.isModifierActive
-- Returns whether the named modifier key is currently held.
-- Combine with isDown to detect chords like Ctrl+S or Shift+Click without writing two separate isDown calls.
do  -- lurek.input.isModifierActive
  function lurek.process(dt)
    if lurek.input.keyboard.isModifierActive("ctrl") and lurek.input.keyboard.isDown("s") then
      lurek.log.info("ctrl+s pressed: triggering save", "input")
    end
  end
end

--@api-stub: lurek.input.getPosition
-- Returns the current cursor position as (x, y).
-- Read once per frame in lurek.process; reading inside lurek.render gives the same value but mixes input with drawing.
do  -- lurek.input.getPosition
  function lurek.process(dt)
    local mx, my = lurek.input.mouse.getPosition()
    lurek.log.debug("cursor at " .. mx .. "," .. my, "input")
  end
end

--@api-stub: lurek.input.getX
-- Returns the current mouse X position in window coordinates.
-- Cheaper than getPosition when you only need one axis (e.g. a horizontal slider).
do  -- lurek.input.getX
  function lurek.process(dt)
    local x = lurek.input.mouse.getX()
    local volume = math.max(0, math.min(1, x / 800))
    lurek.log.debug("volume slider: " .. volume, "ui")
  end
end

--@api-stub: lurek.input.getY
-- Returns the current mouse Y position in window coordinates.
-- Y grows downward in window space; subtract from window height when you need bottom-origin coordinates.
do  -- lurek.input.getY
  function lurek.process(dt)
    local y = lurek.input.mouse.getY()
    if y < 32 then
      lurek.log.debug("cursor in top menu strip", "ui")
    end
  end
end

--@api-stub: lurek.input.isDown
-- Returns whether the given mouse button is currently held down.
-- Button names are "left", "right", and "middle"; pass several to detect chord clicks (e.g. left+right for camera pan).
do  -- lurek.input.isDown
  function lurek.process(dt)
    if lurek.input.mouse.isDown("left") then
      lurek.log.debug("left mouse held: dragging selection", "input")
    end
  end
end

--@api-stub: lurek.input.setVisible
-- Shows or hides the operating-system mouse cursor.
-- Hide during cinematics or first-person mouselook; restore when control returns to UI.
do  -- lurek.input.setVisible
  lurek.input.mouse.setVisible(false)
  lurek.log.info("cursor hidden for cinematic", "input")
end

--@api-stub: lurek.input.isVisible
-- Returns whether the mouse cursor is currently visible.
-- Useful when toggling a pause menu — only re-show the cursor if it was hidden by gameplay.
do  -- lurek.input.isVisible
  if not lurek.input.mouse.isVisible() then
    lurek.input.mouse.setVisible(true)
    lurek.log.info("pause menu opened: cursor restored", "ui")
  end
end

--@api-stub: lurek.input.setGrabbed
-- Locks or unlocks the mouse cursor to the window.
-- Pair with setRelativeMode(true) for first-person mouselook so the cursor never escapes during fast turns.
do  -- lurek.input.setGrabbed
  lurek.input.mouse.setGrabbed(true)
  lurek.input.mouse.setRelativeMode(true)
  lurek.log.info("entered mouselook mode", "input")
end

--@api-stub: lurek.input.isGrabbed
-- Returns whether the mouse cursor is locked to the window.
-- Check before alt-tabbing logic so you can release the grab and restore it after focus returns.
do  -- lurek.input.isGrabbed
  if lurek.input.mouse.isGrabbed() then
    lurek.log.debug("cursor locked to window: focus changes will need to release", "input")
  end
end

--@api-stub: lurek.input.setRelativeMode
-- Enables or disables raw relative mouse motion mode.
-- In relative mode getX/getY stop changing; consume motion via the mousemoved event’s dx/dy instead.
do  -- lurek.input.setRelativeMode
  lurek.input.mouse.setRelativeMode(true)
  lurek.log.info("relative mouse mode on — read dx/dy from mousemoved", "input")
end

--@api-stub: lurek.input.getRelativeMode
-- Returns whether relative mouse mode is active.
-- Branch on this so your camera code knows to read motion deltas instead of absolute positions.
do  -- lurek.input.getRelativeMode
  function lurek.process(dt)
    if lurek.input.mouse.getRelativeMode() then
      lurek.log.debug("camera should integrate dx/dy this frame", "camera")
    end
  end
end

--@api-stub: lurek.input.setPosition
-- Moves the mouse cursor to the given window-space position.
-- Use to snap the cursor back to a pause-menu button or to the centre of the window after closing a modal.
do  -- lurek.input.setPosition
  local cx, cy = 400, 300
  lurek.input.mouse.setPosition(cx, cy)
  lurek.log.debug("cursor recentred to " .. cx .. "," .. cy, "input")
end

--@api-stub: lurek.input.setCursor
-- Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
-- Pass a name string for quick swaps ("hand", "ibeam", "crosshair"); pass nil to restore the default arrow.
do  -- lurek.input.setCursor
  lurek.input.mouse.setCursor("hand")
  lurek.log.debug("cursor: hand (over clickable link)", "ui")
end

--@api-stub: lurek.input.newCursor
-- Creates a custom mouse cursor from RGBA pixel data.
-- pixels is a flat array of bytes (R,G,B,A repeated) sized width*height*4; hotx/hoty default to 0,0 (top-left).
do  -- lurek.input.newCursor
  local w, h = 2, 2
  local pixels = { 255,0,0,255,  0,255,0,255,  0,0,255,255,  255,255,255,255 }
  local cur = lurek.input.mouse.newCursor(pixels, w, h, 0, 0)
  lurek.input.mouse.setCursor(cur)
end

--@api-stub: lurek.input.getSystemCursor
-- Returns a system cursor object for the named cursor shape.
-- Cache the returned handle once and reuse it instead of re-resolving the name string every frame.
do  -- lurek.input.getSystemCursor
  local crosshair = lurek.input.mouse.getSystemCursor("crosshair")
  function lurek.process(dt)
    lurek.input.mouse.setCursor(crosshair)
  end
end

--@api-stub: lurek.input.isCursorSupported
-- Returns whether cursor customisation is supported on this platform.
-- Gate any newCursor / setCursor calls on this so headless and exotic platforms degrade gracefully.
do  -- lurek.input.isCursorSupported
  if lurek.input.mouse.isCursorSupported() then
    lurek.input.mouse.setCursor("hand")
  else
    lurek.log.warn("custom cursors unsupported — keeping default arrow", "input")
  end
end

--@api-stub: lurek.input.getCursor
-- Returns the name of the currently active system cursor.
-- Use to confirm a setCursor call took effect, e.g. in a settings dialog that previews the chosen cursor.
do  -- lurek.input.getCursor
  local name = lurek.input.mouse.getCursor()
  lurek.log.debug("active cursor shape: " .. name, "ui")
end

--@api-stub: lurek.input.getWheelDelta
-- Returns the mouse scroll wheel delta (dx, dy) since last frame.
-- Read every frame and reset implicitly by reading; positive dy is scroll-up on most platforms.
do  -- lurek.input.getWheelDelta
  function lurek.process(dt)
    local dx, dy = lurek.input.mouse.getWheelDelta()
    if dy ~= 0 then
      lurek.log.debug("zoom by " .. dy, "camera")
    end
  end
end

--@api-stub: lurek.input.getCount
-- Returns the number of connected gamepads.
-- Read at startup and on the joystickadded/removed events to update a player-select screen.
do  -- lurek.input.getCount
  local n = lurek.input.gamepad.getCount()
  lurek.log.info("connected gamepads: " .. n, "input")
end

--@api-stub: lurek.input.getJoystickCount
-- Returns the number of tracked gamepad slots.
-- Slot count includes recently disconnected pads so previously-bound IDs stay valid until the next reconnect.
do  -- lurek.input.getJoystickCount
  local slots = lurek.input.gamepad.getJoystickCount()
  if slots == 0 then
    lurek.log.info("no gamepads tracked yet", "input")
  end
end

--@api-stub: lurek.input.getJoysticks
-- Returns a list of connected gamepad IDs.
-- Iterate this list rather than assuming IDs 0..N-1; disconnected pads create gaps.
do  -- lurek.input.getJoysticks
  local ids = lurek.input.gamepad.getJoysticks()
  for i, id in ipairs(ids) do
    lurek.log.debug("player " .. i .. " is gamepad id " .. id, "input")
  end
end

--@api-stub: lurek.input.isConnected
-- Returns whether the gamepad with the given ID is connected.
-- Check before reading axes/buttons so you can show a "reconnect controller" overlay instead of zeroed input.
do  -- lurek.input.isConnected
  local id = 0
  if not lurek.input.gamepad.isConnected(id) then
    lurek.log.warn("player 1 controller disconnected", "input")
  end
end

--@api-stub: lurek.input.getName
-- Returns the human-readable name of a gamepad.
-- Display in player-assignment UI; names like "Xbox Wireless Controller" help players pick the right pad.
do  -- lurek.input.getName
  local id = 0
  local name = lurek.input.gamepad.getName(id)
  lurek.log.info("gamepad " .. id .. ": " .. name, "input")
end

--@api-stub: lurek.input.isGamepad
-- Returns whether the joystick at the given slot is a recognized gamepad.
-- Generic joysticks return false; only mapped pads (via SDL2 GameControllerDB) return true and accept getAxis names.
do  -- lurek.input.isGamepad
  local id = 0
  if lurek.input.gamepad.isGamepad(id) then
    lurek.log.debug("slot " .. id .. " has a recognised gamepad mapping", "input")
  end
end

--@api-stub: lurek.input.getButtonCount
-- Returns the total number of buttons on the gamepad.
-- Use to size a per-button debug overlay or to validate a saved binding still references a valid button index.
do  -- lurek.input.getButtonCount
  local id = 0
  local nbtn = lurek.input.gamepad.getButtonCount(id)
  lurek.log.debug("gamepad " .. id .. " has " .. nbtn .. " buttons", "input")
end

--@api-stub: lurek.input.getAxisCount
-- Returns the total number of analog axes on the gamepad.
-- Standard pads report 6 (two sticks + two triggers); racing wheels and flight sticks report more.
do  -- lurek.input.getAxisCount
  local id = 0
  local naxis = lurek.input.gamepad.getAxisCount(id)
  if naxis < 4 then
    lurek.log.warn("gamepad " .. id .. " has only " .. naxis .. " axes — dual-stick aiming unavailable", "input")
  end
end

--@api-stub: lurek.input.isDown
-- Returns whether the given button on the gamepad is currently held.
-- Button names match SDL2 controller buttons: "a", "b", "x", "y", "start", "back", "leftshoulder", etc.
do  -- lurek.input.isDown
  function lurek.process(dt)
    if lurek.input.gamepad.isDown(0, "a") then
      lurek.log.debug("player 1 pressed A: jump", "input")
    end
  end
end

--@api-stub: lurek.input.getAxis
-- Returns the current value (-1 to 1) of a gamepad analog axis.
-- Apply a small dead-zone (e.g. abs(v) < 0.15 → 0) so resting sticks do not drift the player.
do  -- lurek.input.getAxis
  function lurek.process(dt)
    local lx = lurek.input.gamepad.getAxis(0, "leftx")
    if math.abs(lx) > 0.15 then
      lurek.log.debug("player 1 left stick X = " .. lx, "input")
    end
  end
end

--@api-stub: lurek.input.isVibrationSupported
-- Returns whether the gamepad supports haptic vibration.
-- winit 0.30 has no haptics backend yet so this currently returns false on every platform; gate vibrate calls.
do  -- lurek.input.isVibrationSupported
  local id = 0
  if lurek.input.gamepad.isVibrationSupported(id) then
    lurek.log.info("gamepad " .. id .. " supports rumble", "input")
  end
end

--@api-stub: lurek.input.vibrate
-- Requests haptic vibration on a gamepad.
-- Args are (id, low_freq, high_freq, duration_ms) all clamped to 0..1 for frequencies; returns false on unsupported platforms.
do  -- lurek.input.vibrate
  local ok = lurek.input.gamepad.vibrate(0, 0.4, 0.8, 250)
  if not ok then
    lurek.log.debug("rumble request ignored (no haptics backend)", "input")
  end
end

--@api-stub: lurek.input.getGUID
-- Returns the hardware GUID string of the gamepad.
-- Persist alongside saved bindings so reconnects on a different USB port still match the same controller.
do  -- lurek.input.getGUID
  local guid = lurek.input.gamepad.getGUID(0)
  if guid ~= "" then
    lurek.log.debug("gamepad 0 GUID: " .. guid, "input")
  end
end

--@api-stub: lurek.input.getHat
-- Returns the direction string of a hat switch on the gamepad.
-- Returns "c" for centred plus "u"/"d"/"l"/"r" and the four diagonals; flight sticks expose hats as the POV.
do  -- lurek.input.getHat
  local dir = lurek.input.gamepad.getHat(0, 0)
  if dir ~= "c" then
    lurek.log.debug("hat 0 = " .. dir, "input")
  end
end

--@api-stub: lurek.input.setVibration
-- Triggers haptic rumble (currently a no-op stub).
-- Legacy alias kept for love2d-style code; always returns false today — prefer gamepad.vibrate(...) for new code.
do  -- lurek.input.setVibration
  local ok = lurek.input.gamepad.setVibration(0, 0.5, 0.5, 200)
  lurek.log.debug("setVibration returned " .. tostring(ok), "input")
end

--@api-stub: lurek.input.setBackgroundEvents
-- Enable or disable receiving gamepad events when the window is not focused.
-- Useful for streamers or split-screen-on-couch setups; default is off so unfocused windows do not eat input.
do  -- lurek.input.setBackgroundEvents
  lurek.input.gamepad.setBackgroundEvents(true)
  lurek.log.info("gamepad input continues while window is unfocused", "input")
end

--@api-stub: lurek.input.getBackgroundEvents
-- Returns whether background gamepad events are enabled.
-- Read at startup to mirror the saved setting back into a settings UI checkbox.
do  -- lurek.input.getBackgroundEvents
  local on = lurek.input.gamepad.getBackgroundEvents()
  if on then
    lurek.log.debug("background gamepad events: enabled", "input")
  end
end

--@api-stub: lurek.input.setGamepadMapping
-- Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
-- Use to ship per-game overrides for obscure controllers; mapping format follows SDL_GameControllerAddMapping.
do  -- lurek.input.setGamepadMapping
  local guid = "030000005e040000130b000011050000"
  local mapping = guid .. ",My Custom Pad,a:b0,b:b1,x:b2,y:b3,start:b7,back:b6,"
  lurek.input.gamepad.setGamepadMapping(guid, mapping)
  lurek.log.info("custom mapping stored for " .. guid, "input")
end

--@api-stub: lurek.input.getGamepadMappingString
-- Returns the stored mapping string for the given GUID, or nil.
-- Returns nil when no override exists — SDL2’s built-in DB is consulted internally instead.
do  -- lurek.input.getGamepadMappingString
  local guid = "030000005e040000130b000011050000"
  local mapping = lurek.input.gamepad.getGamepadMappingString(guid)
  if mapping then
    lurek.log.debug("override mapping length: " .. #mapping, "input")
  end
end

--@api-stub: lurek.input.loadGamepadMappings
-- Loads SDL2 GameControllerDB-format mappings from a file.
-- Returns the number of mappings parsed; ship a curated gamecontrollerdb.txt with your game and load it once at startup.
do  -- lurek.input.loadGamepadMappings
  local ok, n = pcall(lurek.input.gamepad.loadGamepadMappings, "save/gamecontrollerdb.txt")
  if ok then lurek.log.info("loaded " .. n .. " controller mappings", "input") end
end

--@api-stub: lurek.input.saveGamepadMappings
-- Saves all stored gamepad mappings to a plain-text file.
-- Call after the player customises a binding so the next launch picks up their mapping without re-prompting.
do  -- lurek.input.saveGamepadMappings
  lurek.input.gamepad.saveGamepadMappings("save/user_mappings.txt")
  lurek.log.info("user gamepad mappings written", "input")
end

--@api-stub: lurek.input.getTouches
-- Returns a table of active touch points with id, x, y, and pressure fields.
-- Iterate to support multi-touch gestures; on desktop builds this is usually empty unless a touchscreen is attached.
do  -- lurek.input.getTouches
  function lurek.process(dt)
    local touches = lurek.input.touch.getTouches()
    for _, tp in ipairs(touches) do
      lurek.log.debug("touch " .. tp.id .. " at " .. tp.x .. "," .. tp.y, "input")
    end
  end
end

--@api-stub: lurek.input.getPosition
-- Returns the position (x, y) of the touch with the given ID.
-- Pass an id you obtained from getTouches; reading an unknown id returns 0, 0 rather than erroring.
do  -- lurek.input.getPosition
  function lurek.process(dt)
    local touches = lurek.input.touch.getTouches()
    if touches[1] then
      local x, y = lurek.input.touch.getPosition(touches[1].id)
      lurek.log.debug("primary touch at " .. x .. "," .. y, "input")
    end
  end
end

--@api-stub: lurek.input.getPressure
-- Returns the pressure (0-1) of the touch with the given ID.
-- Many touchscreens report only 0 or 1; treat anything above ~0.5 as a firm press for stylus-aware UIs.
do  -- lurek.input.getPressure
  function lurek.process(dt)
    local touches = lurek.input.touch.getTouches()
    if touches[1] then
      local p = lurek.input.touch.getPressure(touches[1].id)
      if p > 0.5 then
        lurek.log.debug("firm touch (pressure " .. p .. ")", "input")
      end
    end
  end
end

--@api-stub: lurek.input.getTouchCount
-- Returns the number of currently active touch points.
-- Use as a fast guard so you only allocate tables in lurek.process when there is actually multi-touch input.
do  -- lurek.input.getTouchCount
  function lurek.process(dt)
    if lurek.input.touch.getTouchCount() >= 2 then
      lurek.log.debug("multi-touch gesture in progress", "input")
    end
  end
end

--@api-stub: lurek.input.bind
-- Maps an action name to one or more key/button names.
-- Pass a single string for one key or an array for several; calling bind again on the same action appends, it does not replace.
do  -- lurek.input.bind
  lurek.input.bind("jump", "space")
  lurek.input.bind("move_left", { "a", "left" })
  lurek.log.info("default bindings installed", "input")
end

--@api-stub: lurek.input.unbind
-- Removes all key bindings for the given action name.
-- Returns true if the action existed; use before reassigning to a single key in a settings UI.
do  -- lurek.input.unbind
  lurek.input.bind("jump", "space")
  local existed = lurek.input.unbind("jump")
  lurek.log.debug("unbind jump returned " .. tostring(existed), "input")
end

--@api-stub: lurek.input.clearBindings
-- Removes all action bindings.
-- Call before applying a fresh control profile so stale bindings from the previous profile do not leak through.
do  -- lurek.input.clearBindings
  lurek.input.bind("jump", "space")
  lurek.input.clearBindings()
  lurek.log.info("all action bindings cleared", "input")
end

--@api-stub: lurek.input.getBindings
-- Returns a table mapping each action name to its bound keys.
-- Walk the result to draw a controls screen, or to serialise to TOML/JSON for the next launch.
do  -- lurek.input.getBindings
  lurek.input.bind("jump", "space")
  local bindings = lurek.input.getBindings()
  for action, keys in pairs(bindings) do
    lurek.log.debug(action .. " <- " .. table.concat(keys, ","), "input")
  end
end

--@api-stub: lurek.input.isActionDown
-- Returns true if any key bound to the action is currently held down.
-- Prefer over isDown("space") so rebinding does not require touching gameplay code.
do  -- lurek.input.isActionDown
  lurek.input.bind("jump", { "space", "w" })
  function lurek.process(dt)
    if lurek.input.isActionDown("jump") then
      lurek.log.debug("jump action held", "input")
    end
  end
end

--@api-stub: lurek.input.wasActionPressed
-- Returns true if any key bound to the action was pressed this frame.
-- Edge-triggered: fires once per press; use for menu confirms and one-shot abilities, not held movement.
do  -- lurek.input.wasActionPressed
  lurek.input.bind("confirm", "return")
  function lurek.process(dt)
    if lurek.input.wasActionPressed("confirm") then
      lurek.log.info("menu: option selected", "ui")
    end
  end
end

--@api-stub: lurek.input.wasActionReleased
-- Returns true if any key bound to the action was released this frame.
-- Use for charge-and-release attacks: integrate while the action is down, fire on release.
do  -- lurek.input.wasActionReleased
  lurek.input.bind("shoot", "left")
  function lurek.process(dt)
    if lurek.input.wasActionReleased("shoot") then
      lurek.log.info("charged shot released", "combat")
    end
  end
end

--@api-stub: lurek.input.wasActionPressedWithin
-- Was action pressed within.
-- Implements input buffering: returns true if the action was pressed in the last N frames, so jumps queued just before landing still fire.
do  -- lurek.input.wasActionPressedWithin
  lurek.input.bind("jump", "space")
  function lurek.process(dt)
    if lurek.input.wasActionPressedWithin("jump", 6) then
      lurek.log.debug("buffered jump within last 6 frames", "input")
    end
  end
end

--@api-stub: lurek.input.newCombo
-- Creates a new combo detector from an ordered list of steps.
-- Each step is a key string or {key=..., gap=ms} table; opts.total_gap caps the whole sequence (default 2000 ms).
do  -- lurek.input.newCombo
  local hadouken = lurek.input.newCombo(
    { "down", { key = "right", gap = 300 }, "a" },
    { total_gap = 1500 }
  )
  lurek.log.info("combo detector ready (" .. hadouken:totalSteps() .. " steps)", "combat")
end

--@api-stub: lurek.input.startRecording
-- Starts capturing input events frame-by-frame.
-- Clears any previous recording; pair with stopRecording at the end of a replay segment to capture a finite take.
do  -- lurek.input.startRecording
  lurek.input.startRecording()
  lurek.log.info("input recording started", "replay")
end

--@api-stub: lurek.input.stopRecording
-- Stops recording and returns an `InputRecording` userdata, or nil if not recording.
-- Returns nil when called without a prior startRecording so you can guard saves with `if rec then ...`.
do  -- lurek.input.stopRecording
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    lurek.log.info("captured " .. rec:totalFrames() .. " frames", "replay")
  end
end

--@api-stub: lurek.input.loadRecording
-- Loads a JSON-encoded recording string for playback.
-- JSON usually comes from a previous InputRecording:toJson() saved to disk via lurek.fs.write.
do  -- lurek.input.loadRecording
  local json = '{"total_frames":1,"frames":[]}'
  lurek.input.loadRecording(json)
  lurek.log.info("recording loaded for playback", "replay")
end

--@api-stub: lurek.input.startPlayback
-- Starts playback from the beginning of the loaded recording.
-- Call after loadRecording; advancePlayback should then be driven once per simulation frame.
do  -- lurek.input.startPlayback
  local json = '{"total_frames":1,"frames":[]}'
  lurek.input.loadRecording(json)
  lurek.input.startPlayback()
  lurek.log.info("playback armed", "replay")
end

--@api-stub: lurek.input.stopPlayback
-- Stops playback immediately.
-- Call when the user takes manual control again so live input is no longer overridden by the recording.
do  -- lurek.input.stopPlayback
  lurek.input.stopPlayback()
  lurek.log.info("playback halted; live input restored", "replay")
end

--@api-stub: lurek.input.isRecording
-- Returns true if input recording is currently active.
-- Use to drive a red REC dot in the UI without tracking the state in your own variable.
do  -- lurek.input.isRecording
  if lurek.input.isRecording() then
    lurek.log.debug("REC indicator: visible", "ui")
  end
end

--@api-stub: lurek.input.isPlayingBack
-- Returns true if input playback is currently active.
-- Branch on this so live input handlers do not double-fire on top of the recording-driven events.
do  -- lurek.input.isPlayingBack
  function lurek.process(dt)
    if lurek.input.isPlayingBack() then
      return  -- skip live-input branch this frame
    end
  end
end

--@api-stub: lurek.input.getPlaybackFrame
-- Returns the current playback frame index (0-based).
-- Display in a scrubber UI; returns 0 when no playback is active so a divide-by-total is always safe.
do  -- lurek.input.getPlaybackFrame
  function lurek.process(dt)
    local f = lurek.input.getPlaybackFrame()
    if f > 0 and f % 60 == 0 then
      lurek.log.debug("playback at frame " .. f, "replay")
    end
  end
end

--@api-stub: lurek.input.advancePlayback
-- Advances playback by one frame and returns an array of key/button events for that.
-- Each event is `{kind="down"|"up", name=string}`; iterate to feed the events back into your input system.
do  -- lurek.input.advancePlayback
  function lurek.process(dt)
    local events = lurek.input.advancePlayback()
    for _, ev in ipairs(events) do
      lurek.log.debug("playback event " .. ev.kind .. " " .. ev.name, "replay")
    end
  end
end

-- ── Cursor methods ──

--@api-stub: Cursor:release
-- Releases the cursor resource (no-op on desktop).
-- Provided for love2d API parity; safe to call but does nothing on Windows/Linux/macOS targets.
do  -- Cursor:release
  local cur = lurek.input.mouse.getSystemCursor("hand")
  cur:release()
  lurek.log.debug("cursor handle released (no-op on desktop)", "input")
end

--@api-stub: Cursor:getType
-- Returns the cursor type as "system" or "custom".
-- Use to choose between a name-string update path and a pixel-data update path when refreshing a saved cursor.
do  -- Cursor:getType
  local cur = lurek.input.mouse.getSystemCursor("crosshair")
  local kind = cur:getType()
  lurek.log.debug("cursor kind: " .. kind, "input")
end

-- ── Combo methods ──

--@api-stub: Combo:feed
-- Feed a key-press event into the combo detector.
-- Returns "idle"/"advanced"/"completed"/"broken"; call from a key-down event handler, not every frame.
do  -- Combo:feed
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  local progress = combo:feed("down")
  lurek.log.debug("combo step result: " .. progress, "combat")
end

--@api-stub: Combo:tick
-- Advance the internal clock by `dt` seconds and check for timeouts.
-- Call once per frame even when no key is pressed so partially-entered combos can expire on time.
do  -- Combo:tick
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  function lurek.process(dt)
    local status = combo:tick(dt)
    if status == "expired" then
      lurek.log.debug("combo window expired", "combat")
    end
  end
end

--@api-stub: Combo:reset
-- Reset the detector to its initial idle state, cancelling any in-progress sequence.
-- Call when the player gets hit or pauses so a buffered partial combo does not fire after the interruption.
do  -- Combo:reset
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  combo:feed("down")
  combo:reset()
  lurek.log.debug("combo cleared after stagger", "combat")
end

--@api-stub: Combo:totalSteps
-- Returns the total number of steps in the combo sequence.
-- Use to drive a UI progress bar: combo:progress() / combo:totalSteps().
do  -- Combo:totalSteps
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  local total = combo:totalSteps()
  lurek.log.debug("combo length: " .. total, "combat")
end

--@api-stub: Combo:isInProgress
-- Returns true if the detector is currently mid-sequence.
-- Read in lurek.render to draw a glowing combo HUD only while the player has actually started entering a sequence.
do  -- Combo:isInProgress
  local combo = lurek.input.newCombo({ "down", "right", "a" })
  combo:feed("down")
  if combo:isInProgress() then
    lurek.log.debug("combo HUD: visible", "ui")
  end
end

--@api-stub: Combo:getStep
-- Returns the step at the given 1-based index as `{key=..., gap_ms=...}`.
-- Returns nil for out-of-range indices; iterate 1..combo:totalSteps() to render combo notation in a tutorial.
do  -- Combo:getStep
  local combo = lurek.input.newCombo({ "down", { key = "right", gap = 300 }, "a" })
  local step = combo:getStep(2)
  if step then
    lurek.log.debug("step 2: key=" .. step.key .. " gap=" .. step.gap_ms .. "ms", "combat")
  end
end

-- ── InputRecording methods ──

--@api-stub: InputRecording:toJson
-- Serializes this recording to a JSON string for saving to disk.
-- Pair with lurek.fs.write to persist a take; reload via lurek.input.loadRecording on the next session.
do  -- InputRecording:toJson
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    local json = rec:toJson()
    lurek.log.debug("serialised recording: " .. #json .. " bytes", "replay")
  end
end

--@api-stub: InputRecording:totalFrames
-- Returns the total frame count when recording was stopped.
-- Use as the denominator for a playback scrubber: lurek.input.getPlaybackFrame() / rec:totalFrames().
do  -- InputRecording:totalFrames
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec then
    lurek.log.info("recorded " .. rec:totalFrames() .. " frames", "replay")
  end
end

--@api-stub: InputRecording:frameCount
-- Returns the number of sparse event frames stored in this recording.
-- Cheaper than totalFrames as a quality signal: a 600-frame recording with frameCount() == 0 captured nothing.
do  -- InputRecording:frameCount
  lurek.input.startRecording()
  local rec = lurek.input.stopRecording()
  if rec and rec:frameCount() == 0 then
    lurek.log.warn("recording has no input events", "replay")
  end
end
