-- content/examples/input.lua
-- Scaffolded coverage of the lurek.input API (80 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/input_api.rs   (Lua binding, arg types, return shape)
--   * src/input/                 (semantics, side effects)
--   * docs/specs/input.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/input.lua

-- ── lurek.input.* functions ──

--@api-stub: lurek.input.isDown
-- Returns true if any of the given keys is currently held down.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isDown
  local _todo = "TODO: write a real lurek.input.isDown usage example"
  print(_todo)
end

--@api-stub: lurek.input.isScancodeDown
-- Returns whether the key with the given scancode is held.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isScancodeDown
  local _todo = "TODO: write a real lurek.input.isScancodeDown usage example"
  print(_todo)
end

--@api-stub: lurek.input.setKeyRepeat
-- Enables or disables key-repeat events.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setKeyRepeat
  local _todo = "TODO: write a real lurek.input.setKeyRepeat usage example"
  print(_todo)
end

--@api-stub: lurek.input.hasKeyRepeat
-- Returns whether key-repeat is currently enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.hasKeyRepeat
  local _todo = "TODO: write a real lurek.input.hasKeyRepeat usage example"
  print(_todo)
end

--@api-stub: lurek.input.setTextInput
-- Enables or disables Unicode text input mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setTextInput
  local _todo = "TODO: write a real lurek.input.setTextInput usage example"
  print(_todo)
end

--@api-stub: lurek.input.hasTextInput
-- Returns whether text input mode is currently active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.hasTextInput
  local _todo = "TODO: write a real lurek.input.hasTextInput usage example"
  print(_todo)
end

--@api-stub: lurek.input.getScancodeFromKey
-- Returns the hardware scancode for the given key name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getScancodeFromKey
  local _todo = "TODO: write a real lurek.input.getScancodeFromKey usage example"
  print(_todo)
end

--@api-stub: lurek.input.getKeyFromScancode
-- Returns the key name for the given hardware scancode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getKeyFromScancode
  local _todo = "TODO: write a real lurek.input.getKeyFromScancode usage example"
  print(_todo)
end

--@api-stub: lurek.input.isModifierActive
-- Returns whether the named modifier key is currently held.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isModifierActive
  local _todo = "TODO: write a real lurek.input.isModifierActive usage example"
  print(_todo)
end

--@api-stub: lurek.input.getPosition
-- Returns the current cursor position as (x, y).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getPosition
  local _todo = "TODO: write a real lurek.input.getPosition usage example"
  print(_todo)
end

--@api-stub: lurek.input.getX
-- Returns the current mouse X position in window coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getX
  local _todo = "TODO: write a real lurek.input.getX usage example"
  print(_todo)
end

--@api-stub: lurek.input.getY
-- Returns the current mouse Y position in window coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getY
  local _todo = "TODO: write a real lurek.input.getY usage example"
  print(_todo)
end

--@api-stub: lurek.input.isDown
-- Returns whether the given mouse button is currently held down.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isDown
  local _todo = "TODO: write a real lurek.input.isDown usage example"
  print(_todo)
end

--@api-stub: lurek.input.setVisible
-- Shows or hides the operating-system mouse cursor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setVisible
  local _todo = "TODO: write a real lurek.input.setVisible usage example"
  print(_todo)
end

--@api-stub: lurek.input.isVisible
-- Returns whether the mouse cursor is currently visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isVisible
  local _todo = "TODO: write a real lurek.input.isVisible usage example"
  print(_todo)
end

--@api-stub: lurek.input.setGrabbed
-- Locks or unlocks the mouse cursor to the window.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setGrabbed
  local _todo = "TODO: write a real lurek.input.setGrabbed usage example"
  print(_todo)
end

--@api-stub: lurek.input.isGrabbed
-- Returns whether the mouse cursor is locked to the window.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isGrabbed
  local _todo = "TODO: write a real lurek.input.isGrabbed usage example"
  print(_todo)
end

--@api-stub: lurek.input.setRelativeMode
-- Enables or disables raw relative mouse motion mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setRelativeMode
  local _todo = "TODO: write a real lurek.input.setRelativeMode usage example"
  print(_todo)
end

--@api-stub: lurek.input.getRelativeMode
-- Returns whether relative mouse mode is active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getRelativeMode
  local _todo = "TODO: write a real lurek.input.getRelativeMode usage example"
  print(_todo)
end

--@api-stub: lurek.input.setPosition
-- Moves the mouse cursor to the given window-space position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setPosition
  local _todo = "TODO: write a real lurek.input.setPosition usage example"
  print(_todo)
end

--@api-stub: lurek.input.setCursor
-- Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setCursor
  local _todo = "TODO: write a real lurek.input.setCursor usage example"
  print(_todo)
end

--@api-stub: lurek.input.newCursor
-- Creates a custom mouse cursor from RGBA pixel data.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.newCursor
  local _todo = "TODO: write a real lurek.input.newCursor usage example"
  print(_todo)
end

--@api-stub: lurek.input.getSystemCursor
-- Returns a system cursor object for the named cursor shape.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getSystemCursor
  local _todo = "TODO: write a real lurek.input.getSystemCursor usage example"
  print(_todo)
end

--@api-stub: lurek.input.isCursorSupported
-- Returns whether cursor customisation is supported on this platform.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isCursorSupported
  local _todo = "TODO: write a real lurek.input.isCursorSupported usage example"
  print(_todo)
end

--@api-stub: lurek.input.getCursor
-- Returns the name of the currently active system cursor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getCursor
  local _todo = "TODO: write a real lurek.input.getCursor usage example"
  print(_todo)
end

--@api-stub: lurek.input.getWheelDelta
-- Returns the mouse scroll wheel delta (dx, dy) since last frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getWheelDelta
  local _todo = "TODO: write a real lurek.input.getWheelDelta usage example"
  print(_todo)
end

--@api-stub: lurek.input.getCount
-- Returns the number of connected gamepads.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getCount
  local _todo = "TODO: write a real lurek.input.getCount usage example"
  print(_todo)
end

--@api-stub: lurek.input.getJoystickCount
-- Returns the number of tracked gamepad slots.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getJoystickCount
  local _todo = "TODO: write a real lurek.input.getJoystickCount usage example"
  print(_todo)
end

--@api-stub: lurek.input.getJoysticks
-- Returns a list of connected gamepad IDs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getJoysticks
  local _todo = "TODO: write a real lurek.input.getJoysticks usage example"
  print(_todo)
end

--@api-stub: lurek.input.isConnected
-- Returns whether the gamepad with the given ID is connected.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isConnected
  local _todo = "TODO: write a real lurek.input.isConnected usage example"
  print(_todo)
end

--@api-stub: lurek.input.getName
-- Returns the human-readable name of a gamepad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getName
  local _todo = "TODO: write a real lurek.input.getName usage example"
  print(_todo)
end

--@api-stub: lurek.input.isGamepad
-- Returns whether the joystick at the given slot is a recognized gamepad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isGamepad
  local _todo = "TODO: write a real lurek.input.isGamepad usage example"
  print(_todo)
end

--@api-stub: lurek.input.getButtonCount
-- Returns the total number of buttons on the gamepad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getButtonCount
  local _todo = "TODO: write a real lurek.input.getButtonCount usage example"
  print(_todo)
end

--@api-stub: lurek.input.getAxisCount
-- Returns the total number of analog axes on the gamepad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getAxisCount
  local _todo = "TODO: write a real lurek.input.getAxisCount usage example"
  print(_todo)
end

--@api-stub: lurek.input.isDown
-- Returns whether the given button on the gamepad is currently held.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isDown
  local _todo = "TODO: write a real lurek.input.isDown usage example"
  print(_todo)
end

--@api-stub: lurek.input.getAxis
-- Returns the current value (-1 to 1) of a gamepad analog axis.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getAxis
  local _todo = "TODO: write a real lurek.input.getAxis usage example"
  print(_todo)
end

--@api-stub: lurek.input.isVibrationSupported
-- Returns whether the gamepad supports haptic vibration.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isVibrationSupported
  local _todo = "TODO: write a real lurek.input.isVibrationSupported usage example"
  print(_todo)
end

--@api-stub: lurek.input.vibrate
-- Requests haptic vibration on a gamepad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.vibrate
  local _todo = "TODO: write a real lurek.input.vibrate usage example"
  print(_todo)
end

--@api-stub: lurek.input.getGUID
-- Returns the hardware GUID string of the gamepad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getGUID
  local _todo = "TODO: write a real lurek.input.getGUID usage example"
  print(_todo)
end

--@api-stub: lurek.input.getHat
-- Returns the direction string of a hat switch on the gamepad.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getHat
  local _todo = "TODO: write a real lurek.input.getHat usage example"
  print(_todo)
end

--@api-stub: lurek.input.setVibration
-- Triggers haptic rumble (currently a no-op stub).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setVibration
  local _todo = "TODO: write a real lurek.input.setVibration usage example"
  print(_todo)
end

--@api-stub: lurek.input.setBackgroundEvents
-- Enable or disable receiving gamepad events when the window is not focused.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setBackgroundEvents
  local _todo = "TODO: write a real lurek.input.setBackgroundEvents usage example"
  print(_todo)
end

--@api-stub: lurek.input.getBackgroundEvents
-- Returns whether background gamepad events are enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getBackgroundEvents
  local _todo = "TODO: write a real lurek.input.getBackgroundEvents usage example"
  print(_todo)
end

--@api-stub: lurek.input.setGamepadMapping
-- Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.setGamepadMapping
  local _todo = "TODO: write a real lurek.input.setGamepadMapping usage example"
  print(_todo)
end

--@api-stub: lurek.input.getGamepadMappingString
-- Returns the stored mapping string for the given GUID, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getGamepadMappingString
  local _todo = "TODO: write a real lurek.input.getGamepadMappingString usage example"
  print(_todo)
end

--@api-stub: lurek.input.loadGamepadMappings
-- Loads SDL2 GameControllerDB-format mappings from a file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.loadGamepadMappings
  local _todo = "TODO: write a real lurek.input.loadGamepadMappings usage example"
  print(_todo)
end

--@api-stub: lurek.input.saveGamepadMappings
-- Saves all stored gamepad mappings to a plain-text file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.saveGamepadMappings
  local _todo = "TODO: write a real lurek.input.saveGamepadMappings usage example"
  print(_todo)
end

--@api-stub: lurek.input.getTouches
-- Returns a table of active touch points with id, x, y, and pressure fields.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getTouches
  local _todo = "TODO: write a real lurek.input.getTouches usage example"
  print(_todo)
end

--@api-stub: lurek.input.getPosition
-- Returns the position (x, y) of the touch with the given ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getPosition
  local _todo = "TODO: write a real lurek.input.getPosition usage example"
  print(_todo)
end

--@api-stub: lurek.input.getPressure
-- Returns the pressure (0-1) of the touch with the given ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getPressure
  local _todo = "TODO: write a real lurek.input.getPressure usage example"
  print(_todo)
end

--@api-stub: lurek.input.getTouchCount
-- Returns the number of currently active touch points.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getTouchCount
  local _todo = "TODO: write a real lurek.input.getTouchCount usage example"
  print(_todo)
end

--@api-stub: lurek.input.bind
-- Maps an action name to one or more key/button names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.bind
  local _todo = "TODO: write a real lurek.input.bind usage example"
  print(_todo)
end

--@api-stub: lurek.input.unbind
-- Removes all key bindings for the given action name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.unbind
  local _todo = "TODO: write a real lurek.input.unbind usage example"
  print(_todo)
end

--@api-stub: lurek.input.clearBindings
-- Removes all action bindings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.clearBindings
  local _todo = "TODO: write a real lurek.input.clearBindings usage example"
  print(_todo)
end

--@api-stub: lurek.input.getBindings
-- Returns a table mapping each action name to its bound keys.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getBindings
  local _todo = "TODO: write a real lurek.input.getBindings usage example"
  print(_todo)
end

--@api-stub: lurek.input.isActionDown
-- Returns true if any key bound to the action is currently held down.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isActionDown
  local _todo = "TODO: write a real lurek.input.isActionDown usage example"
  print(_todo)
end

--@api-stub: lurek.input.wasActionPressed
-- Returns true if any key bound to the action was pressed this frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.wasActionPressed
  local _todo = "TODO: write a real lurek.input.wasActionPressed usage example"
  print(_todo)
end

--@api-stub: lurek.input.wasActionReleased
-- Returns true if any key bound to the action was released this frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.wasActionReleased
  local _todo = "TODO: write a real lurek.input.wasActionReleased usage example"
  print(_todo)
end

--@api-stub: lurek.input.wasActionPressedWithin
-- Was action pressed within.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.wasActionPressedWithin
  local _todo = "TODO: write a real lurek.input.wasActionPressedWithin usage example"
  print(_todo)
end

--@api-stub: lurek.input.newCombo
-- Creates a new combo detector from an ordered list of steps.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.newCombo
  local _todo = "TODO: write a real lurek.input.newCombo usage example"
  print(_todo)
end

--@api-stub: lurek.input.startRecording
-- Starts capturing input events frame-by-frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.startRecording
  local _todo = "TODO: write a real lurek.input.startRecording usage example"
  print(_todo)
end

--@api-stub: lurek.input.stopRecording
-- Stops recording and returns an `InputRecording` userdata, or nil if not recording.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.stopRecording
  local _todo = "TODO: write a real lurek.input.stopRecording usage example"
  print(_todo)
end

--@api-stub: lurek.input.loadRecording
-- Loads a JSON-encoded recording string for playback.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.loadRecording
  local _todo = "TODO: write a real lurek.input.loadRecording usage example"
  print(_todo)
end

--@api-stub: lurek.input.startPlayback
-- Starts playback from the beginning of the loaded recording.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.startPlayback
  local _todo = "TODO: write a real lurek.input.startPlayback usage example"
  print(_todo)
end

--@api-stub: lurek.input.stopPlayback
-- Stops playback immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.stopPlayback
  local _todo = "TODO: write a real lurek.input.stopPlayback usage example"
  print(_todo)
end

--@api-stub: lurek.input.isRecording
-- Returns true if input recording is currently active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isRecording
  local _todo = "TODO: write a real lurek.input.isRecording usage example"
  print(_todo)
end

--@api-stub: lurek.input.isPlayingBack
-- Returns true if input playback is currently active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.isPlayingBack
  local _todo = "TODO: write a real lurek.input.isPlayingBack usage example"
  print(_todo)
end

--@api-stub: lurek.input.getPlaybackFrame
-- Returns the current playback frame index (0-based).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.getPlaybackFrame
  local _todo = "TODO: write a real lurek.input.getPlaybackFrame usage example"
  print(_todo)
end

--@api-stub: lurek.input.advancePlayback
-- Advances playback by one frame and returns an array of key/button events for that.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: lurek.input.advancePlayback
  local _todo = "TODO: write a real lurek.input.advancePlayback usage example"
  print(_todo)
end

-- ── Cursor methods ──

--@api-stub: Cursor:release
-- Releases the cursor resource (no-op on desktop).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: Cursor:release
  local _todo = "TODO: write a real Cursor:release usage example"
  print(_todo)
end

--@api-stub: Cursor:getType
-- Returns the cursor type as "system" or "custom".
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: Cursor:getType
  local _todo = "TODO: write a real Cursor:getType usage example"
  print(_todo)
end

-- ── Combo methods ──

--@api-stub: Combo:feed
-- Feed a key-press event into the combo detector.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: Combo:feed
  local _todo = "TODO: write a real Combo:feed usage example"
  print(_todo)
end

--@api-stub: Combo:tick
-- Advance the internal clock by `dt` seconds and check for timeouts.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: Combo:tick
  local _todo = "TODO: write a real Combo:tick usage example"
  print(_todo)
end

--@api-stub: Combo:reset
-- Reset the detector to its initial idle state, cancelling any in-progress sequence.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: Combo:reset
  local _todo = "TODO: write a real Combo:reset usage example"
  print(_todo)
end

--@api-stub: Combo:totalSteps
-- Returns the total number of steps in the combo sequence.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: Combo:totalSteps
  local _todo = "TODO: write a real Combo:totalSteps usage example"
  print(_todo)
end

--@api-stub: Combo:isInProgress
-- Returns true if the detector is currently mid-sequence.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: Combo:isInProgress
  local _todo = "TODO: write a real Combo:isInProgress usage example"
  print(_todo)
end

--@api-stub: Combo:getStep
-- Returns the step at the given 1-based index as `{key=..., gap_ms=...}`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: Combo:getStep
  local _todo = "TODO: write a real Combo:getStep usage example"
  print(_todo)
end

-- ── InputRecording methods ──

--@api-stub: InputRecording:toJson
-- Serializes this recording to a JSON string for saving to disk.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: InputRecording:toJson
  local _todo = "TODO: write a real InputRecording:toJson usage example"
  print(_todo)
end

--@api-stub: InputRecording:totalFrames
-- Returns the total frame count when recording was stopped.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: InputRecording:totalFrames
  local _todo = "TODO: write a real InputRecording:totalFrames usage example"
  print(_todo)
end

--@api-stub: InputRecording:frameCount
-- Returns the number of sparse event frames stored in this recording.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/input_api.rs and docs/specs/input.md).
do  -- TODO: InputRecording:frameCount
  local _todo = "TODO: write a real InputRecording:frameCount usage example"
  print(_todo)
end

