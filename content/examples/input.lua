-- content/examples/input.lua
-- Practical usage examples for the lurek.input API (80 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.input.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/input.lua

print("[example] lurek.input — 80 API entries")

-- ── lurek.input.* free functions ──

--@api-stub: lurek.input.isDown
-- Returns true if any of the given keys is currently held down.
-- Call when you need to check is down.
local ok, result = pcall(function() return lurek.input.isDown({}) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isDown ok=", ok)

--@api-stub: lurek.input.isScancodeDown
-- Returns whether the key with the given scancode is held.
-- Call when you need to check is scancode down.
local ok, result = pcall(function() return lurek.input.isScancodeDown(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isScancodeDown ok=", ok)

--@api-stub: lurek.input.setKeyRepeat
-- Enables or disables key-repeat events.
-- Call when you need to assign key repeat.
local ok, err = pcall(function() lurek.input.setKeyRepeat(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setKeyRepeat applied=", ok)

--@api-stub: lurek.input.hasKeyRepeat
-- Returns whether key-repeat is currently enabled.
-- Call when you need to check has key repeat.
local ok, result = pcall(function() return lurek.input.hasKeyRepeat() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.hasKeyRepeat ok=", ok)

--@api-stub: lurek.input.setTextInput
-- Enables or disables Unicode text input mode.
-- Call when you need to assign text input.
local ok, err = pcall(function() lurek.input.setTextInput(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setTextInput applied=", ok)

--@api-stub: lurek.input.hasTextInput
-- Returns whether text input mode is currently active.
-- Call when you need to check has text input.
local ok, result = pcall(function() return lurek.input.hasTextInput() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.hasTextInput ok=", ok)

--@api-stub: lurek.input.getScancodeFromKey
-- Returns the hardware scancode for the given key name.
-- Call when you need to read scancode from key.
local ok, value = pcall(function() return lurek.input.getScancodeFromKey("key") end)
local v = ok and value or "(unavailable)"
print("lurek.input.getScancodeFromKey ->", v)

--@api-stub: lurek.input.getKeyFromScancode
-- Returns the key name for the given hardware scancode.
-- Call when you need to read key from scancode.
local ok, value = pcall(function() return lurek.input.getKeyFromScancode(nil) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getKeyFromScancode ->", v)

--@api-stub: lurek.input.isModifierActive
-- Returns whether the named modifier key is currently held.
-- Call when you need to check is modifier active.
local ok, result = pcall(function() return lurek.input.isModifierActive(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isModifierActive ok=", ok)

--@api-stub: lurek.input.getPosition
-- Returns the current cursor position as (x, y).
-- Call when you need to read position.
local ok, value = pcall(function() return lurek.input.getPosition() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getPosition ->", v)

--@api-stub: lurek.input.getX
-- Returns the current mouse X position in window coordinates.
-- Call when you need to read x.
local ok, value = pcall(function() return lurek.input.getX() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getX ->", v)

--@api-stub: lurek.input.getY
-- Returns the current mouse Y position in window coordinates.
-- Call when you need to read y.
local ok, value = pcall(function() return lurek.input.getY() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getY ->", v)

--@api-stub: lurek.input.isDown
-- Returns whether the given mouse button is currently held down.
-- Call when you need to check is down.
local ok, result = pcall(function() return lurek.input.isDown(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isDown ok=", ok)

--@api-stub: lurek.input.setVisible
-- Shows or hides the operating-system mouse cursor.
-- Call when you need to assign visible.
local ok, err = pcall(function() lurek.input.setVisible(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setVisible applied=", ok)

--@api-stub: lurek.input.isVisible
-- Returns whether the mouse cursor is currently visible.
-- Call when you need to check is visible.
local ok, result = pcall(function() return lurek.input.isVisible() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isVisible ok=", ok)

--@api-stub: lurek.input.setGrabbed
-- Locks or unlocks the mouse cursor to the window.
-- Call when you need to assign grabbed.
local ok, err = pcall(function() lurek.input.setGrabbed(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setGrabbed applied=", ok)

--@api-stub: lurek.input.isGrabbed
-- Returns whether the mouse cursor is locked to the window.
-- Call when you need to check is grabbed.
local ok, result = pcall(function() return lurek.input.isGrabbed() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isGrabbed ok=", ok)

--@api-stub: lurek.input.setRelativeMode
-- Enables or disables raw relative mouse motion mode.
-- Call when you need to assign relative mode.
local ok, err = pcall(function() lurek.input.setRelativeMode(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setRelativeMode applied=", ok)

--@api-stub: lurek.input.getRelativeMode
-- Returns whether relative mouse mode is active.
-- Call when you need to read relative mode.
local ok, value = pcall(function() return lurek.input.getRelativeMode() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getRelativeMode ->", v)

--@api-stub: lurek.input.setPosition
-- Moves the mouse cursor to the given window-space position.
-- Call when you need to assign position.
local ok, err = pcall(function() lurek.input.setPosition(0, 0) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setPosition applied=", ok)

--@api-stub: lurek.input.setCursor
-- Sets the active mouse cursor from a Cursor handle, name string, or nil to reset.
-- Call when you need to assign cursor.
local ok, err = pcall(function() lurek.input.setCursor(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setCursor applied=", ok)

--@api-stub: lurek.input.newCursor
-- Creates a custom mouse cursor from RGBA pixel data.
-- Call when you need to create a new cursor.
local ok, obj = pcall(function() return lurek.input.newCursor() end)
if ok and obj then print("created:", obj) end
print("lurek.input.newCursor ok=", ok)

--@api-stub: lurek.input.getSystemCursor
-- Returns a system cursor object for the named cursor shape.
-- Call when you need to read system cursor.
local ok, value = pcall(function() return lurek.input.getSystemCursor("name") end)
local v = ok and value or "(unavailable)"
print("lurek.input.getSystemCursor ->", v)

--@api-stub: lurek.input.isCursorSupported
-- Returns whether cursor customisation is supported on this platform.
-- Call when you need to check is cursor supported.
local ok, result = pcall(function() return lurek.input.isCursorSupported() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isCursorSupported ok=", ok)

--@api-stub: lurek.input.getCursor
-- Returns the name of the currently active system cursor.
-- Call when you need to read cursor.
local ok, value = pcall(function() return lurek.input.getCursor() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getCursor ->", v)

--@api-stub: lurek.input.getWheelDelta
-- Returns the mouse scroll wheel delta (dx, dy) since last frame.
-- Call when you need to read wheel delta.
local ok, value = pcall(function() return lurek.input.getWheelDelta() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getWheelDelta ->", v)

--@api-stub: lurek.input.getCount
-- Returns the number of connected gamepads.
-- Call when you need to read count.
local ok, value = pcall(function() return lurek.input.getCount() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getCount ->", v)

--@api-stub: lurek.input.getJoystickCount
-- Returns the number of tracked gamepad slots.
-- Call when you need to read joystick count.
local ok, value = pcall(function() return lurek.input.getJoystickCount() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getJoystickCount ->", v)

--@api-stub: lurek.input.getJoysticks
-- Returns a list of connected gamepad IDs.
-- Call when you need to read joysticks.
local ok, value = pcall(function() return lurek.input.getJoysticks() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getJoysticks ->", v)

--@api-stub: lurek.input.isConnected
-- Returns whether the gamepad with the given ID is connected.
-- Call when you need to check is connected.
local ok, result = pcall(function() return lurek.input.isConnected(1) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isConnected ok=", ok)

--@api-stub: lurek.input.getName
-- Returns the human-readable name of a gamepad.
-- Call when you need to read name.
local ok, value = pcall(function() return lurek.input.getName(1) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getName ->", v)

--@api-stub: lurek.input.isGamepad
-- Returns whether the joystick at the given slot is a recognized gamepad.
-- Call when you need to check is gamepad.
local ok, result = pcall(function() return lurek.input.isGamepad(1) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isGamepad ok=", ok)

--@api-stub: lurek.input.getButtonCount
-- Returns the total number of buttons on the gamepad.
-- Call when you need to read button count.
local ok, value = pcall(function() return lurek.input.getButtonCount(1) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getButtonCount ->", v)

--@api-stub: lurek.input.getAxisCount
-- Returns the total number of analog axes on the gamepad.
-- Call when you need to read axis count.
local ok, value = pcall(function() return lurek.input.getAxisCount(1) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getAxisCount ->", v)

--@api-stub: lurek.input.isDown
-- Returns whether the given button on the gamepad is currently held.
-- Call when you need to check is down.
local ok, result = pcall(function() return lurek.input.isDown(1, nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isDown ok=", ok)

--@api-stub: lurek.input.getAxis
-- Returns the current value (-1 to 1) of a gamepad analog axis.
-- Call when you need to read axis.
local ok, value = pcall(function() return lurek.input.getAxis(1, nil) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getAxis ->", v)

--@api-stub: lurek.input.isVibrationSupported
-- Returns whether the gamepad supports haptic vibration.
-- Call when you need to check is vibration supported.
local ok, result = pcall(function() return lurek.input.isVibrationSupported(1) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isVibrationSupported ok=", ok)

--@api-stub: lurek.input.vibrate
-- Requests haptic vibration on a gamepad.
-- Call when you need to invoke vibrate.
local ok, result = pcall(function() return lurek.input.vibrate(1, nil, nil, nil) end)
if ok then print("lurek.input.vibrate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.input.getGUID
-- Returns the hardware GUID string of the gamepad.
-- Call when you need to read g u i d.
local ok, value = pcall(function() return lurek.input.getGUID(1) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getGUID ->", v)

--@api-stub: lurek.input.getHat
-- Returns the direction string of a hat switch on the gamepad.
-- Call when you need to read hat.
local ok, value = pcall(function() return lurek.input.getHat(1, nil) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getHat ->", v)

--@api-stub: lurek.input.setVibration
-- Triggers haptic rumble (currently a no-op stub).
-- Call when you need to assign vibration.
local ok, err = pcall(function() lurek.input.setVibration({}) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setVibration applied=", ok)

--@api-stub: lurek.input.setBackgroundEvents
-- Enable or disable receiving gamepad events when the window is not focused.
-- Call when you need to assign background events.
local ok, err = pcall(function() lurek.input.setBackgroundEvents(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setBackgroundEvents applied=", ok)

--@api-stub: lurek.input.getBackgroundEvents
-- Returns whether background gamepad events are enabled.
-- Call when you need to read background events.
local ok, value = pcall(function() return lurek.input.getBackgroundEvents() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getBackgroundEvents ->", v)

--@api-stub: lurek.input.setGamepadMapping
-- Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID.
-- Call when you need to assign gamepad mapping.
local ok, err = pcall(function() lurek.input.setGamepadMapping(1, nil) end)
if not ok then print("set skipped:", err) end
print("lurek.input.setGamepadMapping applied=", ok)

--@api-stub: lurek.input.getGamepadMappingString
-- Returns the stored mapping string for the given GUID, or nil.
-- Call when you need to read gamepad mapping string.
local ok, value = pcall(function() return lurek.input.getGamepadMappingString(1) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getGamepadMappingString ->", v)

--@api-stub: lurek.input.loadGamepadMappings
-- Loads SDL2 GameControllerDB-format mappings from a file.
-- Call when you need to load gamepad mappings.
local ok, obj = pcall(function() return lurek.input.loadGamepadMappings("path") end)
if ok and obj then print("created:", obj) end
print("lurek.input.loadGamepadMappings ok=", ok)

--@api-stub: lurek.input.saveGamepadMappings
-- Saves all stored gamepad mappings to a plain-text file.
-- Call when you need to invoke save gamepad mappings.
local ok, obj = pcall(function() return lurek.input.saveGamepadMappings("path") end)
if ok and obj then print("created:", obj) end
print("lurek.input.saveGamepadMappings ok=", ok)

--@api-stub: lurek.input.getTouches
-- Returns a table of active touch points with id, x, y, and pressure fields.
-- Call when you need to read touches.
local ok, value = pcall(function() return lurek.input.getTouches() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getTouches ->", v)

--@api-stub: lurek.input.getPosition
-- Returns the position (x, y) of the touch with the given ID.
-- Call when you need to read position.
local ok, value = pcall(function() return lurek.input.getPosition(1) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getPosition ->", v)

--@api-stub: lurek.input.getPressure
-- Returns the pressure (0-1) of the touch with the given ID.
-- Call when you need to read pressure.
local ok, value = pcall(function() return lurek.input.getPressure(1) end)
local v = ok and value or "(unavailable)"
print("lurek.input.getPressure ->", v)

--@api-stub: lurek.input.getTouchCount
-- Returns the number of currently active touch points.
-- Call when you need to read touch count.
local ok, value = pcall(function() return lurek.input.getTouchCount() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getTouchCount ->", v)

--@api-stub: lurek.input.bind
-- Maps an action name to one or more key/button names.
-- Call when you need to invoke bind.
local ok, result = pcall(function() return lurek.input.bind(nil, "keys") end)
if ok then print("lurek.input.bind ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.input.unbind
-- Removes all key bindings for the given action name.
-- Call when you need to invoke unbind.
local ok, result = pcall(function() return lurek.input.unbind(nil) end)
if ok then print("lurek.input.unbind ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.input.clearBindings
-- Removes all action bindings.
-- Call when you need to invoke clear bindings.
local ok, err = pcall(function() lurek.input.clearBindings() end)
if not ok then print("skipped:", err) end
print("lurek.input.clearBindings cleared=", ok)

--@api-stub: lurek.input.getBindings
-- Returns a table mapping each action name to its bound keys.
-- Call when you need to read bindings.
local ok, value = pcall(function() return lurek.input.getBindings() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getBindings ->", v)

--@api-stub: lurek.input.isActionDown
-- Returns true if any key bound to the action is currently held down.
-- Call when you need to check is action down.
local ok, result = pcall(function() return lurek.input.isActionDown(nil) end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isActionDown ok=", ok)

--@api-stub: lurek.input.wasActionPressed
-- Returns true if any key bound to the action was pressed this frame.
-- Call when you need to invoke was action pressed.
local ok, result = pcall(function() return lurek.input.wasActionPressed(nil) end)
if ok then print("lurek.input.wasActionPressed ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.input.wasActionReleased
-- Returns true if any key bound to the action was released this frame.
-- Call when you need to invoke was action released.
local ok, result = pcall(function() return lurek.input.wasActionReleased(nil) end)
if ok then print("lurek.input.wasActionReleased ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.input.wasActionPressedWithin
-- Was action pressed within.
-- Call when you need to invoke was action pressed within.
local ok, result = pcall(function() return lurek.input.wasActionPressedWithin(nil, nil) end)
if ok then print("lurek.input.wasActionPressedWithin ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.input.newCombo
-- Creates a new combo detector from an ordered list of steps.
-- Call when you need to create a new combo.
local ok, obj = pcall(function() return lurek.input.newCombo(nil, {}) end)
if ok and obj then print("created:", obj) end
print("lurek.input.newCombo ok=", ok)

--@api-stub: lurek.input.startRecording
-- Starts capturing input events frame-by-frame.
-- Clears any previous recording.
local ok, result = pcall(function() return lurek.input.startRecording() end)
if not ok then print("action skipped:", result) end
print("lurek.input.startRecording fired=", ok)

--@api-stub: lurek.input.stopRecording
-- Stops recording and returns an `InputRecording` userdata, or nil if not recording.
-- Call when you need to invoke stop recording.
local ok, result = pcall(function() return lurek.input.stopRecording() end)
if not ok then print("action skipped:", result) end
print("lurek.input.stopRecording fired=", ok)

--@api-stub: lurek.input.loadRecording
-- Loads a JSON-encoded recording string for playback.
-- Call when you need to load recording.
local ok, obj = pcall(function() return lurek.input.loadRecording(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.input.loadRecording ok=", ok)

--@api-stub: lurek.input.startPlayback
-- Starts playback from the beginning of the loaded recording.
-- Call when you need to invoke start playback.
local ok, result = pcall(function() return lurek.input.startPlayback() end)
if not ok then print("action skipped:", result) end
print("lurek.input.startPlayback fired=", ok)

--@api-stub: lurek.input.stopPlayback
-- Stops playback immediately.
-- Call when you need to invoke stop playback.
local ok, result = pcall(function() return lurek.input.stopPlayback() end)
if not ok then print("action skipped:", result) end
print("lurek.input.stopPlayback fired=", ok)

--@api-stub: lurek.input.isRecording
-- Returns true if input recording is currently active.
-- Call when you need to check is recording.
local ok, result = pcall(function() return lurek.input.isRecording() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isRecording ok=", ok)

--@api-stub: lurek.input.isPlayingBack
-- Returns true if input playback is currently active.
-- Call when you need to check is playing back.
local ok, result = pcall(function() return lurek.input.isPlayingBack() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.input.isPlayingBack ok=", ok)

--@api-stub: lurek.input.getPlaybackFrame
-- Returns the current playback frame index (0-based).
-- Returns 0 when not playing.
local ok, value = pcall(function() return lurek.input.getPlaybackFrame() end)
local v = ok and value or "(unavailable)"
print("lurek.input.getPlaybackFrame ->", v)

--@api-stub: lurek.input.advancePlayback
-- Advances playback by one frame and returns an array of key/button events for that.
-- Call when you need to invoke advance playback.
local ok, result = pcall(function() return lurek.input.advancePlayback() end)
if ok then print("lurek.input.advancePlayback ->", result)
else print("unavailable:", result) end

-- ── Cursor methods ──

--@api-stub: Cursor:release
-- Releases the cursor resource (no-op on desktop).
-- Call when you need to invoke release.
-- Build a Cursor via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newCursor(...)
if instance then
  local ok, result = pcall(function() return instance:release() end)
  print("Cursor:release ->", ok, result)
end

--@api-stub: Cursor:getType
-- Returns the cursor type as "system" or "custom".
-- Call when you need to read type.
-- Build a Cursor via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newCursor(...)
if instance then
  local ok, result = pcall(function() return instance:getType() end)
  print("Cursor:getType ->", ok, result)
end

-- ── Combo methods ──

--@api-stub: Combo:feed
-- Feed a key-press event into the combo detector.
-- Call when you need to invoke feed.
-- Build a Combo via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newCombo(...)
if instance then
  local ok, result = pcall(function() return instance:feed("key") end)
  print("Combo:feed ->", ok, result)
end

--@api-stub: Combo:tick
-- Advance the internal clock by `dt` seconds and check for timeouts.
-- Call when you need to invoke tick.
-- Build a Combo via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newCombo(...)
if instance then
  local ok, result = pcall(function() return instance:tick(1.0) end)
  print("Combo:tick ->", ok, result)
end

--@api-stub: Combo:reset
-- Reset the detector to its initial idle state, cancelling any in-progress sequence.
-- Call when you need to invoke reset.
-- Build a Combo via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newCombo(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("Combo:reset ->", ok, result)
end

--@api-stub: Combo:totalSteps
-- Returns the total number of steps in the combo sequence.
-- Call when you need to invoke total steps.
-- Build a Combo via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newCombo(...)
if instance then
  local ok, result = pcall(function() return instance:totalSteps() end)
  print("Combo:totalSteps ->", ok, result)
end

--@api-stub: Combo:isInProgress
-- Returns true if the detector is currently mid-sequence.
-- Call when you need to check is in progress.
-- Build a Combo via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newCombo(...)
if instance then
  local ok, result = pcall(function() return instance:isInProgress() end)
  print("Combo:isInProgress ->", ok, result)
end

--@api-stub: Combo:getStep
-- Returns the step at the given 1-based index as `{key=..., gap_ms=...}`.
-- Call when you need to read step.
-- Build a Combo via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newCombo(...)
if instance then
  local ok, result = pcall(function() return instance:getStep(1) end)
  print("Combo:getStep ->", ok, result)
end

-- ── InputRecording methods ──

--@api-stub: InputRecording:toJson
-- Serializes this recording to a JSON string for saving to disk.
-- Call when you need to invoke to json.
-- Build a InputRecording via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newInputRecording(...)
if instance then
  local ok, result = pcall(function() return instance:toJson() end)
  print("InputRecording:toJson ->", ok, result)
end

--@api-stub: InputRecording:totalFrames
-- Returns the total frame count when recording was stopped.
-- Call when you need to invoke total frames.
-- Build a InputRecording via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newInputRecording(...)
if instance then
  local ok, result = pcall(function() return instance:totalFrames() end)
  print("InputRecording:totalFrames ->", ok, result)
end

--@api-stub: InputRecording:frameCount
-- Returns the number of sparse event frames stored in this recording.
-- Call when you need to invoke frame count.
-- Build a InputRecording via the appropriate lurek.input.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.input.newInputRecording(...)
if instance then
  local ok, result = pcall(function() return instance:frameCount() end)
  print("InputRecording:frameCount ->", ok, result)
end

