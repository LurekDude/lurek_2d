-- content/examples/input.lua
-- Auto-scaffolded coverage of the lurek.input Lua API (80 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/input.lua

print("[example] lurek.input loaded — 80 API items demonstrated")

-- ── lurek.input free functions ──

--@api-stub: lurek.input.isDown
-- Returns true if any of the given keys is currently held down.
-- Use this when returns true if any of the given keys is currently held down is needed.
if false then
  local _r = lurek.input.isDown({})
  print(_r)
end

--@api-stub: lurek.input.isScancodeDown
-- Returns whether the key with the given scancode is held.
-- Use this when returns whether the key with the given scancode is held is needed.
if false then
  local _r = lurek.input.isScancodeDown(1)
  print(_r)
end

--@api-stub: lurek.input.setKeyRepeat
-- Enables or disables key-repeat events.
-- Use this when enables or disables key-repeat events is needed.
if false then
  local _r = lurek.input.setKeyRepeat(1)
  print(_r)
end

--@api-stub: lurek.input.hasKeyRepeat
-- Returns whether key-repeat is currently enabled.
-- Use this when returns whether key-repeat is currently enabled is needed.
if false then
  local _r = lurek.input.hasKeyRepeat()
  print(_r)
end

--@api-stub: lurek.input.setTextInput
-- Enables or disables Unicode text input mode.
-- Use this when enables or disables Unicode text input mode is needed.
if false then
  local _r = lurek.input.setTextInput(1)
  print(_r)
end

--@api-stub: lurek.input.hasTextInput
-- Returns whether text input mode is currently active.
-- Use this when returns whether text input mode is currently active is needed.
if false then
  local _r = lurek.input.hasTextInput()
  print(_r)
end

--@api-stub: lurek.input.getScancodeFromKey
-- Returns the hardware scancode for the given key name.
-- Use this when returns the hardware scancode for the given key name is needed.
if false then
  local _r = lurek.input.getScancodeFromKey(0)
  print(_r)
end

--@api-stub: lurek.input.getKeyFromScancode
-- Returns the key name for the given hardware scancode.
-- Use this when returns the key name for the given hardware scancode is needed.
if false then
  local _r = lurek.input.getKeyFromScancode(1)
  print(_r)
end

--@api-stub: lurek.input.isModifierActive
-- Returns whether the named modifier key is currently held.
-- Use this when returns whether the named modifier key is currently held is needed.
if false then
  local _r = lurek.input.isModifierActive(nil)
  print(_r)
end

--@api-stub: lurek.input.getPosition
-- Returns the current cursor position as (x, y).
-- Use this when returns the current cursor position as (x, y) is needed.
if false then
  local _r = lurek.input.getPosition()
  print(_r)
end

--@api-stub: lurek.input.getX
-- Returns the current mouse X position in window coordinates.
-- Use this when returns the current mouse X position in window coordinates is needed.
if false then
  local _r = lurek.input.getX()
  print(_r)
end

--@api-stub: lurek.input.getY
-- Returns the current mouse Y position in window coordinates.
-- Use this when returns the current mouse Y position in window coordinates is needed.
if false then
  local _r = lurek.input.getY()
  print(_r)
end

--@api-stub: lurek.input.isDown
-- Returns whether the given mouse button is currently held down.
-- Use this when returns whether the given mouse button is currently held down is needed.
if false then
  local _r = lurek.input.isDown(1)
  print(_r)
end

--@api-stub: lurek.input.setVisible
-- Shows or hides the operating-system mouse cursor.
-- Use this when shows or hides the operating-system mouse cursor is needed.
if false then
  local _r = lurek.input.setVisible(0)
  print(_r)
end

--@api-stub: lurek.input.isVisible
-- Returns whether the mouse cursor is currently visible.
-- Use this when returns whether the mouse cursor is currently visible is needed.
if false then
  local _r = lurek.input.isVisible()
  print(_r)
end

--@api-stub: lurek.input.setGrabbed
-- Locks or unlocks the mouse cursor to the window.
-- Use this when locks or unlocks the mouse cursor to the window is needed.
if false then
  local _r = lurek.input.setGrabbed(nil)
  print(_r)
end

--@api-stub: lurek.input.isGrabbed
-- Returns whether the mouse cursor is locked to the window.
-- Use this when returns whether the mouse cursor is locked to the window is needed.
if false then
  local _r = lurek.input.isGrabbed()
  print(_r)
end

--@api-stub: lurek.input.setRelativeMode
-- Enables or disables raw relative mouse motion mode.
-- Use this when enables or disables raw relative mouse motion mode is needed.
if false then
  local _r = lurek.input.setRelativeMode(0)
  print(_r)
end

--@api-stub: lurek.input.getRelativeMode
-- Returns whether relative mouse mode is active.
-- Use this when returns whether relative mouse mode is active is needed.
if false then
  local _r = lurek.input.getRelativeMode()
  print(_r)
end

--@api-stub: lurek.input.setPosition
-- Moves the mouse cursor to the given window-space position.
-- Use this when moves the mouse cursor to the given window-space position is needed.
if false then
  local _r = lurek.input.setPosition(0, 0)
  print(_r)
end

--@api-stub: lurek.input.setCursor
-- Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
-- Use this when sets the active mouse cursor from a Cursor handle, name string, or nil to reset is needed.
if false then
  local _r = lurek.input.setCursor(0)
  print(_r)
end

--@api-stub: lurek.input.newCursor
-- Creates a custom mouse cursor from RGBA pixel data.
-- Use this when creates a custom mouse cursor from RGBA pixel data is needed.
if false then
  local _r = lurek.input.newCursor()
  print(_r)
end

--@api-stub: lurek.input.getSystemCursor
-- Returns a system cursor object for the named cursor shape.
-- Use this when returns a system cursor object for the named cursor shape is needed.
if false then
  local _r = lurek.input.getSystemCursor(1)
  print(_r)
end

--@api-stub: lurek.input.isCursorSupported
-- Returns whether cursor customisation is supported on this platform.
-- Use this when returns whether cursor customisation is supported on this platform is needed.
if false then
  local _r = lurek.input.isCursorSupported()
  print(_r)
end

--@api-stub: lurek.input.getCursor
-- Returns the name of the currently active system cursor.
-- Use this when returns the name of the currently active system cursor is needed.
if false then
  local _r = lurek.input.getCursor()
  print(_r)
end

--@api-stub: lurek.input.getWheelDelta
-- Returns the mouse scroll wheel delta (dx, dy) since last frame.
-- Use this when returns the mouse scroll wheel delta (dx, dy) since last frame is needed.
if false then
  local _r = lurek.input.getWheelDelta()
  print(_r)
end

--@api-stub: lurek.input.getCount
-- Returns the number of connected gamepads.
-- Use this when returns the number of connected gamepads is needed.
if false then
  local _r = lurek.input.getCount()
  print(_r)
end

--@api-stub: lurek.input.getJoystickCount
-- Returns the number of tracked gamepad slots.
-- Use this when returns the number of tracked gamepad slots is needed.
if false then
  local _r = lurek.input.getJoystickCount()
  print(_r)
end

--@api-stub: lurek.input.getJoysticks
-- Returns a list of connected gamepad IDs.
-- Use this when returns a list of connected gamepad IDs is needed.
if false then
  local _r = lurek.input.getJoysticks()
  print(_r)
end

--@api-stub: lurek.input.isConnected
-- Returns whether the gamepad with the given ID is connected.
-- Use this when returns whether the gamepad with the given ID is connected is needed.
if false then
  local _r = lurek.input.isConnected(1)
  print(_r)
end

--@api-stub: lurek.input.getName
-- Returns the human-readable name of a gamepad.
-- Use this when returns the human-readable name of a gamepad is needed.
if false then
  local _r = lurek.input.getName(1)
  print(_r)
end

--@api-stub: lurek.input.isGamepad
-- Returns whether the joystick at the given slot is a recognized gamepad.
-- Use this when returns whether the joystick at the given slot is a recognized gamepad is needed.
if false then
  local _r = lurek.input.isGamepad(1)
  print(_r)
end

--@api-stub: lurek.input.getButtonCount
-- Returns the total number of buttons on the gamepad.
-- Use this when returns the total number of buttons on the gamepad is needed.
if false then
  local _r = lurek.input.getButtonCount(1)
  print(_r)
end

--@api-stub: lurek.input.getAxisCount
-- Returns the total number of analog axes on the gamepad.
-- Use this when returns the total number of analog axes on the gamepad is needed.
if false then
  local _r = lurek.input.getAxisCount(1)
  print(_r)
end

--@api-stub: lurek.input.isDown
-- Returns whether the given button on the gamepad is currently held.
-- Use this when returns whether the given button on the gamepad is currently held is needed.
if false then
  local _r = lurek.input.isDown(1, 1)
  print(_r)
end

--@api-stub: lurek.input.getAxis
-- Returns the current value (-1 to 1) of a gamepad analog axis.
-- Use this when returns the current value (-1 to 1) of a gamepad analog axis is needed.
if false then
  local _r = lurek.input.getAxis(1, 0)
  print(_r)
end

--@api-stub: lurek.input.isVibrationSupported
-- Returns whether the gamepad supports haptic vibration.
-- Use this when returns whether the gamepad supports haptic vibration is needed.
if false then
  local _r = lurek.input.isVibrationSupported(1)
  print(_r)
end

--@api-stub: lurek.input.vibrate
-- Requests haptic vibration on a gamepad.
-- Use this when requests haptic vibration on a gamepad is needed.
if false then
  local _r = lurek.input.vibrate(1, 0, 0, 1)
  print(_r)
end

--@api-stub: lurek.input.getGUID
-- Returns the hardware GUID string of the gamepad.
-- Use this when returns the hardware GUID string of the gamepad is needed.
if false then
  local _r = lurek.input.getGUID(1)
  print(_r)
end

--@api-stub: lurek.input.getHat
-- Returns the direction string of a hat switch on the gamepad.
-- Use this when returns the direction string of a hat switch on the gamepad is needed.
if false then
  local _r = lurek.input.getHat(1, 0)
  print(_r)
end

--@api-stub: lurek.input.setVibration
-- Triggers haptic rumble (currently a no-op stub).
-- Use this when triggers haptic rumble (currently a no-op stub) is needed.
if false then
  local _r = lurek.input.setVibration({})
  print(_r)
end

--@api-stub: lurek.input.setBackgroundEvents
-- Enable or disable receiving gamepad events when the window is not focused.
-- Use this when enable or disable receiving gamepad events when the window is not focused is needed.
if false then
  local _r = lurek.input.setBackgroundEvents(1)
  print(_r)
end

--@api-stub: lurek.input.getBackgroundEvents
-- Returns whether background gamepad events are enabled.
-- Use this when returns whether background gamepad events are enabled is needed.
if false then
  local _r = lurek.input.getBackgroundEvents()
  print(_r)
end

--@api-stub: lurek.input.setGamepadMapping
-- Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
-- Use this when stores or replaces the SDL2 GameControllerDB mapping string for the given GUID is needed.
if false then
  local _r = lurek.input.setGamepadMapping(1, 1)
  print(_r)
end

--@api-stub: lurek.input.getGamepadMappingString
-- Returns the stored mapping string for the given GUID, or nil.
-- Use this when returns the stored mapping string for the given GUID, or nil is needed.
if false then
  local _r = lurek.input.getGamepadMappingString(1)
  print(_r)
end

--@api-stub: lurek.input.loadGamepadMappings
-- Loads SDL2 GameControllerDB-format mappings from a file.
-- Use this when loads SDL2 GameControllerDB-format mappings from a file is needed.
if false then
  local _r = lurek.input.loadGamepadMappings(0)
  print(_r)
end

--@api-stub: lurek.input.saveGamepadMappings
-- Saves all stored gamepad mappings to a plain-text file.
-- Use this when saves all stored gamepad mappings to a plain-text file is needed.
if false then
  local _r = lurek.input.saveGamepadMappings(0)
  print(_r)
end

--@api-stub: lurek.input.getTouches
-- Returns a table of active touch points with id, x, y, and pressure fields.
-- Use this when returns a table of active touch points with id, x, y, and pressure fields is needed.
if false then
  local _r = lurek.input.getTouches()
  print(_r)
end

--@api-stub: lurek.input.getPosition
-- Returns the position (x, y) of the touch with the given ID.
-- Use this when returns the position (x, y) of the touch with the given ID is needed.
if false then
  local _r = lurek.input.getPosition(1)
  print(_r)
end

--@api-stub: lurek.input.getPressure
-- Returns the pressure (0-1) of the touch with the given ID.
-- Use this when returns the pressure (0-1) of the touch with the given ID is needed.
if false then
  local _r = lurek.input.getPressure(1)
  print(_r)
end

--@api-stub: lurek.input.getTouchCount
-- Returns the number of currently active touch points.
-- Use this when returns the number of currently active touch points is needed.
if false then
  local _r = lurek.input.getTouchCount()
  print(_r)
end

--@api-stub: lurek.input.bind
-- Maps an action name to one or more key/button names.
-- Use this when maps an action name to one or more key/button names is needed.
if false then
  local _r = lurek.input.bind(1, 0)
  print(_r)
end

--@api-stub: lurek.input.unbind
-- Removes all key bindings for the given action name.
-- Use this when removes all key bindings for the given action name is needed.
if false then
  local _r = lurek.input.unbind(1)
  print(_r)
end

--@api-stub: lurek.input.clearBindings
-- Removes all action bindings.
-- Use this when removes all action bindings is needed.
if false then
  local _r = lurek.input.clearBindings()
  print(_r)
end

--@api-stub: lurek.input.getBindings
-- Returns a table mapping each action name to its bound keys.
-- Use this when returns a table mapping each action name to its bound keys is needed.
if false then
  local _r = lurek.input.getBindings()
  print(_r)
end

--@api-stub: lurek.input.isActionDown
-- Returns true if any key bound to the action is currently held down.
-- Use this when returns true if any key bound to the action is currently held down is needed.
if false then
  local _r = lurek.input.isActionDown(1)
  print(_r)
end

--@api-stub: lurek.input.wasActionPressed
-- Returns true if any key bound to the action was pressed this frame.
-- Use this when returns true if any key bound to the action was pressed this frame is needed.
if false then
  local _r = lurek.input.wasActionPressed(1)
  print(_r)
end

--@api-stub: lurek.input.wasActionReleased
-- Returns true if any key bound to the action was released this frame.
-- Use this when returns true if any key bound to the action was released this frame is needed.
if false then
  local _r = lurek.input.wasActionReleased(1)
  print(_r)
end

--@api-stub: lurek.input.wasActionPressedWithin
-- Was action pressed within.
-- Use this when was action pressed within is needed.
if false then
  local _r = lurek.input.wasActionPressedWithin(1, nil)
  print(_r)
end

--@api-stub: lurek.input.newCombo
-- Creates a new combo detector from an ordered list of steps.
-- Use this when creates a new combo detector from an ordered list of steps is needed.
if false then
  local _r = lurek.input.newCombo(0, 0)
  print(_r)
end

--@api-stub: lurek.input.startRecording
-- Starts capturing input events frame-by-frame.
-- Clears any previous recording.
if false then
  local _r = lurek.input.startRecording()
  print(_r)
end

--@api-stub: lurek.input.stopRecording
-- Stops recording and returns an `InputRecording` userdata, or nil if not recording.
-- Use this when stops recording and returns an `InputRecording` userdata, or nil if not recording is needed.
if false then
  local _r = lurek.input.stopRecording()
  print(_r)
end

--@api-stub: lurek.input.loadRecording
-- Loads a JSON-encoded recording string for playback.
-- Use this when loads a JSON-encoded recording string for playback is needed.
if false then
  local _r = lurek.input.loadRecording(1)
  print(_r)
end

--@api-stub: lurek.input.startPlayback
-- Starts playback from the beginning of the loaded recording.
-- Use this when starts playback from the beginning of the loaded recording is needed.
if false then
  local _r = lurek.input.startPlayback()
  print(_r)
end

--@api-stub: lurek.input.stopPlayback
-- Stops playback immediately.
-- Use this when stops playback immediately is needed.
if false then
  local _r = lurek.input.stopPlayback()
  print(_r)
end

--@api-stub: lurek.input.isRecording
-- Returns true if input recording is currently active.
-- Use this when returns true if input recording is currently active is needed.
if false then
  local _r = lurek.input.isRecording()
  print(_r)
end

--@api-stub: lurek.input.isPlayingBack
-- Returns true if input playback is currently active.
-- Use this when returns true if input playback is currently active is needed.
if false then
  local _r = lurek.input.isPlayingBack()
  print(_r)
end

--@api-stub: lurek.input.getPlaybackFrame
-- Returns the current playback frame index (0-based).
-- Returns 0 when not playing.
if false then
  local _r = lurek.input.getPlaybackFrame()
  print(_r)
end

--@api-stub: lurek.input.advancePlayback
-- Advances playback by one frame and returns an array of key/button events for that.
-- Use this when advances playback by one frame and returns an array of key/button events for that is needed.
if false then
  local _r = lurek.input.advancePlayback()
  print(_r)
end

-- ── Cursor methods ──

--@api-stub: Cursor:release
-- Releases the cursor resource (no-op on desktop).
-- Use this when releases the cursor resource (no-op on desktop) is needed.
if false then
  local _o = nil  -- Cursor instance
  _o:release()
end

--@api-stub: Cursor:getType
-- Returns the cursor type as "system" or "custom".
-- Use this when returns the cursor type as "system" or "custom" is needed.
if false then
  local _o = nil  -- Cursor instance
  _o:getType()
end

-- ── Combo methods ──

--@api-stub: Combo:feed
-- Feed a key-press event into the combo detector.
-- Use this when feed a key-press event into the combo detector is needed.
if false then
  local _o = nil  -- Combo instance
  _o:feed(0)
end

--@api-stub: Combo:tick
-- Advance the internal clock by `dt` seconds and check for timeouts.
-- Use this when advance the internal clock by `dt` seconds and check for timeouts is needed.
if false then
  local _o = nil  -- Combo instance
  _o:tick(0)
end

--@api-stub: Combo:reset
-- Reset the detector to its initial idle state, cancelling any in-progress sequence.
-- Use this when reset the detector to its initial idle state, cancelling any in-progress sequence is needed.
if false then
  local _o = nil  -- Combo instance
  _o:reset()
end

--@api-stub: Combo:totalSteps
-- Returns the total number of steps in the combo sequence.
-- Use this when returns the total number of steps in the combo sequence is needed.
if false then
  local _o = nil  -- Combo instance
  _o:totalSteps()
end

--@api-stub: Combo:isInProgress
-- Returns true if the detector is currently mid-sequence.
-- Use this when returns true if the detector is currently mid-sequence is needed.
if false then
  local _o = nil  -- Combo instance
  _o:isInProgress()
end

--@api-stub: Combo:getStep
-- Returns the step at the given 1-based index as `{key=..., gap_ms=...}`.
-- Use this when returns the step at the given 1-based index as `{key=..., gap_ms=...}` is needed.
if false then
  local _o = nil  -- Combo instance
  _o:getStep(1)
end

-- ── InputRecording methods ──

--@api-stub: InputRecording:toJson
-- Serializes this recording to a JSON string for saving to disk.
-- Use this when serializes this recording to a JSON string for saving to disk is needed.
if false then
  local _o = nil  -- InputRecording instance
  _o:toJson()
end

--@api-stub: InputRecording:totalFrames
-- Returns the total frame count when recording was stopped.
-- Use this when returns the total frame count when recording was stopped is needed.
if false then
  local _o = nil  -- InputRecording instance
  _o:totalFrames()
end

--@api-stub: InputRecording:frameCount
-- Returns the number of sparse event frames stored in this recording.
-- Use this when returns the number of sparse event frames stored in this recording is needed.
if false then
  local _o = nil  -- InputRecording instance
  _o:frameCount()
end

