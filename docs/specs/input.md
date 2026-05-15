# input

## General Info

- Module group: `Platform Services`
- Source path: `src/input/`
- Lua API path(s): `src/lua_api/input_api.rs`
- Primary Lua namespace: `lurek.input.keyboard`
- Rust test path(s): tests/rust/unit/input_tests.rs
- Lua test path(s): tests/lua/unit/test_input.lua, tests/lua/integration/test_input_camera.lua

## Summary

The `input` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Platform Services group rather than absorb behavior owned by those neighbors.

## Files

- `combo.rs`: Combo and input-sequence detection for ordered key/button input chains.
- `gamepad.rs`: Gamepad implementation for the `input` subsystem.
- `keyboard.rs`: Keyboard implementation for the `input` subsystem.
- `mod.rs`: Mod implementation for the `input` subsystem.
- `mouse.rs`: Mouse implementation for the `input` subsystem.
- `recorder.rs`: Input recording and playback for Lurek2D.
- `touch.rs`: Touch input state tracking for Lurek2D.

## Types

- `ComboStep` (`struct`, `combo.rs`): A single step in an input combo sequence.
- `ComboProgress` (`enum`, `combo.rs`): Result returned after advancing a [`ComboDetector`].
- `ComboDetector` (`struct`, `combo.rs`): A combo detector that tracks an ordered sequence of named inputs within time windows.
- `GamepadVibrationRequest` (`struct`, `gamepad.rs`): Pending vibration command for one gamepad, queued for delivery to the OS driver.
- `GamepadState` (`struct`, `gamepad.rs`): Holds the current button and axis state for a single gamepad identified by its id.
- `GamepadMappings` (`struct`, `gamepad.rs`): Stores SDL2 GameControllerDB-format mapping strings keyed by GUID.
- `KeyboardState` (`struct`, `keyboard.rs`): Tracks which keyboard keys are currently down, just pressed, or just released.
- `SystemCursor` (`enum`, `mouse.rs`): Standard OS cursor icon variants supported by the window backend.
- `MouseState` (`struct`, `mouse.rs`): Tracks mouse cursor position and per-button pressed/down/released state.
- `CursorKind` (`enum`, `mouse.rs`): The cursor type — either a named system icon or user-supplied pixel data.
- `CursorHandle` (`struct`, `mouse.rs`): A held cursor — either a system cursor icon or custom pixel-data cursor.
- `InputEvent` (`struct`, `recorder.rs`): A single key or button event captured within one frame.
- `RecordedFrame` (`struct`, `recorder.rs`): A snapshot of all input events that occurred during a single game frame.
- `InputRecording` (`struct`, `recorder.rs`): A complete input recording consisting of one or more [`RecordedFrame`] snapshots.
- `InputRecorder` (`struct`, `recorder.rs`): Records input events frame-by-frame and replays them on demand.
- `TouchPoint` (`struct`, `touch.rs`): Snapshot of one active touch point with its screen-space position and pressure.
- `TouchState` (`struct`, `touch.rs`): Tracks all active touch points by their winit-assigned finger ID.

## Functions

- `ComboDetector::new` (`combo.rs`): Create detector with the given step list and total-sequence timeout.
- `ComboDetector::feed` (`combo.rs`): Advance the sequence with `key`; returns `Completed`, `Advanced`, `Broken`, or `Idle`.
- `ComboDetector::tick` (`combo.rs`): Advance internal timers by `elapsed_ms`; returns `Broken` if any gap expired, else `Advanced` or `Idle`.
- `ComboDetector::reset` (`combo.rs`): Reset all step counters and timers to the initial state.
- `ComboDetector::is_in_progress` (`combo.rs`): Return true when at least one step has been matched and the sequence is ongoing.
- `ComboDetector::progress` (`combo.rs`): Return the index of the next required step (0 when idle).
- `ComboDetector::len` (`combo.rs`): Return the total number of steps in the sequence.
- `ComboDetector::is_empty` (`combo.rs`): Return true when the step list is empty.
- `GamepadState::new` (`gamepad.rs`): Create a disconnected slot for `id`; all buttons/axes start at default.
- `GamepadState::begin_frame` (`gamepad.rs`): Clear per-frame delta sets; call once at the start of each game frame.
- `GamepadState::update_button` (`gamepad.rs`): Record a button state change and update pressed/released delta sets.
- `GamepadState::was_button_pressed` (`gamepad.rs`): Return true when `button` transitioned to pressed this frame.
- `GamepadState::was_button_released` (`gamepad.rs`): Return true when `button` transitioned to released this frame.
- `GamepadState::update_axis` (`gamepad.rs`): Record a new axis value; replaces the previous value for `axis`.
- `GamepadState::is_button_pressed` (`gamepad.rs`): Return true when `button` is currently held down.
- `GamepadState::get_axis_value` (`gamepad.rs`): Return the current value for `axis`, or 0.0 when the axis has never been seen.
- `GamepadState::get_name` (`gamepad.rs`): Return the OS-reported controller name.
- `GamepadState::is_connected` (`gamepad.rs`): Return true when the device is currently connected.
- `GamepadState::set_connected` (`gamepad.rs`): Update connection state and set the per-frame connection-change flags.
- `GamepadState::was_connected_this_frame` (`gamepad.rs`): Return true only during the frame the device first connected.
- `GamepadState::was_disconnected_this_frame` (`gamepad.rs`): Return true only during the frame the device disconnected.
- `GamepadState::set_vibration_supported` (`gamepad.rs`): Set whether the OS driver supports force feedback for this device.
- `GamepadState::is_vibration_supported` (`gamepad.rs`): Return true when force feedback is supported.
- `GamepadState::get_button_count` (`gamepad.rs`): Return the number of distinct button codes seen on this device.
- `GamepadState::get_axis_count` (`gamepad.rs`): Return the number of distinct axis codes seen on this device.
- `GamepadState::set_guid` (`gamepad.rs`): Set the SDL2-style GUID string; crate-internal, called from the runtime event loop.
- `GamepadState::get_guid` (`gamepad.rs`): Return the SDL2-style GUID string for mapping lookup.
- `GamepadState::get_hat` (`gamepad.rs`): Return a D-pad direction string for `hat`; reads buttons 10–13 for hat 0.
- `gilrs_button_to_string` (`gamepad.rs`): Converts a `gilrs::Button` to a engine-compatible string name.
- `gilrs_axis_to_string` (`gamepad.rs`): Converts a `gilrs::Axis` to a engine-compatible string name.
- `virtual_dpad` (`gamepad.rs`): Convert a 2D stick position to four directional booleans and an 8-way direction string.
- `GamepadMappings::new` (`gamepad.rs`): Create an empty mapping store.
- `GamepadMappings::set_mapping` (`gamepad.rs`): Insert or overwrite the mapping string for `guid`.
- `GamepadMappings::load_from_string` (`gamepad.rs`): Parse SDL2 gamecontrollerdb lines from `source`; return the number of entries loaded.
- `GamepadMappings::get_mapping_string` (`gamepad.rs`): Return the raw mapping string for `guid`, or `None` when not present.
- `GamepadMappings::load_from_file` (`gamepad.rs`): Load mappings from a file at `path`; return entry count or `EngineError` on I/O failure.
- `GamepadMappings::save_to_file` (`gamepad.rs`): Write all stored mappings to a file at `path`; return `EngineError` on I/O failure.
- `KeyboardState::new` (`keyboard.rs`): Create a keyboard state with all keys up and all buffers empty.
- `KeyboardState::begin_frame` (`keyboard.rs`): Clear per-frame delta lists and the text buffer; call at the start of each game frame.
- `KeyboardState::press_scancode` (`keyboard.rs`): Record a scan-code press and add it to the pressed delta list when not already down.
- `KeyboardState::release_scancode` (`keyboard.rs`): Record a scan-code release and add it to the released delta list when it was down.
- `KeyboardState::is_scancode_down` (`keyboard.rs`): Return true when `scancode` is currently held down.
- `KeyboardState::set_key_repeat` (`keyboard.rs`): Enable or disable OS key-repeat forwarding.
- `KeyboardState::has_key_repeat` (`keyboard.rs`): Return true when key-repeat is enabled.
- `KeyboardState::set_text_input` (`keyboard.rs`): Enable or disable the text-input character buffer.
- `KeyboardState::has_text_input` (`keyboard.rs`): Return true when text-input mode is active.
- `KeyboardState::push_text_input` (`keyboard.rs`): Append a character string to the text-input buffer for this frame.
- `KeyboardState::get_text_input` (`keyboard.rs`): Return all text-input characters delivered this frame.
- `KeyboardState::set_key_down` (`keyboard.rs`): Record a logical key press; adds to the pressed delta list only on first down.
- `KeyboardState::set_key_up` (`keyboard.rs`): Record a logical key release; adds to the released delta list only when it was down.
- `KeyboardState::is_down` (`keyboard.rs`): Return true when `key` is currently held down.
- `KeyboardState::is_any_down` (`keyboard.rs`): Return true when any key in `keys` is currently held down.
- `KeyboardState::get_pressed` (`keyboard.rs`): Return all logical keys that transitioned to pressed this frame.
- `KeyboardState::get_released` (`keyboard.rs`): Return all logical keys that transitioned to released this frame.
- `KeyboardState::clear` (`keyboard.rs`): Clear all held-key sets and delta lists; does not reset modifier flags.
- `KeyboardState::is_modifier_active` (`keyboard.rs`): Return true when `modifier` name (`"shift"`, `"ctrl"`, `"alt"`, `"meta"`) flag is set.
- `KeyboardState::set_modifiers` (`keyboard.rs`): Update the packed modifier bitmask from four individual boolean flags.
- `get_scancode_from_key` (`keyboard.rs`): Resolves a logical Luna key name to the closest physical scancode string.
- `get_key_from_scancode` (`keyboard.rs`): Resolves a physical scancode string to the closest logical Luna key name.
- `winit_key_to_string` (`keyboard.rs`): Converts a `winit 0.30` logical `Key` to the lowercase string name used by the `lurek.*` API.
- `winit_scancode_to_string` (`keyboard.rs`): Converts a `winit 0.30` physical `KeyCode` to a engine-compatible scancode string.
- `SystemCursor::from_name` (`mouse.rs`): Parse a lower-case cursor name string and return the matching variant; unknown names fall back to `Arrow`.
- `SystemCursor::as_str` (`mouse.rs`): Return the lower-case name string for this variant.
- `MouseState::new` (`mouse.rs`): Create a mouse state with all buttons up, cursor visible at (0, 0).
- `MouseState::begin_frame` (`mouse.rs`): Clear per-frame button delta arrays and scroll accumulators; call at frame start.
- `MouseState::update_position` (`mouse.rs`): Update the cursor position without queuing a warp request.
- `MouseState::request_position` (`mouse.rs`): Set position and queue a warp request for the OS to move the hardware cursor.
- `MouseState::set_button` (`mouse.rs`): Record a button state change for `button` (0–4) and update pressed/released delta flags.
- `MouseState::is_down` (`mouse.rs`): Return true when `button` (0–4) is currently held down.
- `MouseState::get_position` (`mouse.rs`): Return the current cursor position as (x, y) in window pixels.
- `MouseState::set_visible` (`mouse.rs`): Show or hide the OS cursor.
- `MouseState::is_visible` (`mouse.rs`): Return true when the OS cursor is currently visible.
- `MouseState::set_grabbed` (`mouse.rs`): Confine or release the cursor from the window bounds.
- `MouseState::is_grabbed` (`mouse.rs`): Return true when the cursor is currently grabbed.
- `MouseState::set_relative_mode` (`mouse.rs`): Enable or disable relative (delta) mouse mode.
- `MouseState::get_relative_mode` (`mouse.rs`): Return true when relative mode is active.
- `MouseState::accumulate_scroll` (`mouse.rs`): Add `dx` and `dy` to the scroll accumulators for this frame.
- `MouseState::get_scroll` (`mouse.rs`): Return accumulated scroll amounts as (scroll_x, scroll_y) for this frame.
- `MouseState::set_cursor` (`mouse.rs`): Set the active system cursor shape.
- `MouseState::get_cursor` (`mouse.rs`): Return the current active system cursor shape.
- `MouseState::take_pending_position` (`mouse.rs`): Consume and return the pending warp-position request, or `None` when no warp is queued.
- `is_cursor_supported` (`mouse.rs`): Returns whether cursor customisation is supported on this platform.
- `InputRecording::to_json` (`recorder.rs`): Serialise to JSON, wrapping in a versioned envelope; return error string on failure.
- `InputRecording::from_json` (`recorder.rs`): Deserialise from JSON; returns error when the version field is unsupported.
- `InputRecorder::new` (`recorder.rs`): Create a new recorder with no active recording or playback.
- `InputRecorder::start_recording` (`recorder.rs`): Begin a new recording; clears any previous in-progress recording.
- `InputRecorder::record_frame` (`recorder.rs`): Append events for the current frame to the active recording; advances the frame counter.
- `InputRecorder::stop_recording` (`recorder.rs`): Stop recording and return the completed `InputRecording`, or `None` when nothing was recorded.
- `InputRecorder::is_recording` (`recorder.rs`): Return true when a recording is currently in progress.
- `InputRecorder::load` (`recorder.rs`): Load `recording` as the active playback source; resets the playback cursor.
- `InputRecorder::start_playback` (`recorder.rs`): Start playing back the loaded recording from the beginning; no-op when no recording is loaded.
- `InputRecorder::stop_playback` (`recorder.rs`): Stop playback immediately.
- `InputRecorder::is_playing_back` (`recorder.rs`): Return true when playback is currently in progress.
- `InputRecorder::playback_frame_index` (`recorder.rs`): Return the current frame index within the active playback.
- `InputRecorder::playback_frame` (`recorder.rs`): Return all events for the current playback frame and advance; stops playback at the end.
- `TouchState::new` (`touch.rs`): Create an empty touch state with no active contacts.
- `TouchState::begin_frame` (`touch.rs`): Clear per-frame delta sets; call at the start of each game frame.
- `TouchState::touch_start` (`touch.rs`): Record a new touch contact at `(x, y)` with the given `pressure`; adds `id` to pressed delta.
- `TouchState::touch_move` (`touch.rs`): Update position and pressure for an existing contact `id`; no-op when `id` is unknown.
- `TouchState::touch_end` (`touch.rs`): Remove a contact `id` and add it to the released delta set.
- `TouchState::was_pressed` (`touch.rs`): Return true when touch `id` first contacted the screen this frame.
- `TouchState::was_released` (`touch.rs`): Return true when touch `id` lifted from the screen this frame.
- `TouchState::get_touches` (`touch.rs`): Return all currently active touch contacts as a `Vec`.
- `TouchState::get_touch` (`touch.rs`): Return the `TouchPoint` for `id`, or `None` when that contact is not active.
- `TouchState::get_touch_count` (`touch.rs`): Return the count of currently active touch contacts.

## Lua API Reference

- Binding path(s): `src/lua_api/input_api.rs`
- Namespace: `lurek.input.keyboard`

### Module Functions
- `lurek.input.keyboard.isDown`: Returns whether any supplied keyboard key is currently down.
- `lurek.input.keyboard.isScancodeDown`: Returns whether a scancode is currently down.
- `lurek.input.keyboard.setKeyRepeat`: Enables or disables key repeat tracking.
- `lurek.input.keyboard.hasKeyRepeat`: Returns whether key repeat tracking is enabled.
- `lurek.input.keyboard.setTextInput`: Enables or disables text input tracking.
- `lurek.input.keyboard.hasTextInput`: Returns whether text input tracking is enabled.
- `lurek.input.keyboard.getScancodeFromKey`: Converts a key name to its scancode name when known.
- `lurek.input.keyboard.getKeyFromScancode`: Converts a scancode name to its key name when known.
- `lurek.input.keyboard.isModifierActive`: Returns whether a named keyboard modifier is active.
- `lurek.input.mouse.getPosition`: Returns the current mouse position.
- `lurek.input.mouse.getX`: Returns the current mouse x coordinate.
- `lurek.input.mouse.getY`: Returns the current mouse y coordinate.
- `lurek.input.mouse.isDown`: Returns whether a one-based mouse button index is down.
- `lurek.input.mouse.setVisible`: Sets mouse cursor visibility.
- `lurek.input.mouse.isVisible`: Returns whether the mouse cursor is visible.
- `lurek.input.mouse.setGrabbed`: Sets whether the mouse is grabbed by the window.
- `lurek.input.mouse.isGrabbed`: Returns whether the mouse is grabbed by the window.
- `lurek.input.mouse.setRelativeMode`: Sets relative mouse mode.
- `lurek.input.mouse.getRelativeMode`: Returns whether relative mouse mode is enabled.
- `lurek.input.mouse.setPosition`: Requests a mouse cursor position change.
- `lurek.input.mouse.setCursor`: Sets the active cursor from a cursor handle, system cursor name, or nil for arrow.
- `lurek.input.mouse.newCursor`: Creates a custom cursor handle from RGBA pixels and hotspot coordinates.
- `lurek.input.mouse.getSystemCursor`: Creates a system cursor handle from a cursor name.
- `lurek.input.mouse.isCursorSupported`: Returns whether the current platform supports cursor changes.
- `lurek.input.mouse.getCursor`: Returns the current system cursor name.
- `lurek.input.mouse.getWheelDelta`: Returns the current mouse wheel delta.
- `lurek.input.gamepad.getCount`: Returns the number of gamepad slots tracked by the runtime.
- `lurek.input.gamepad.getJoystickCount`: Returns the number of joystick slots tracked by the runtime.
- `lurek.input.gamepad.getJoysticks`: Returns ids for currently connected gamepads.
- `lurek.input.gamepad.isConnected`: Returns whether a gamepad id is currently connected.
- `lurek.input.gamepad.getName`: Returns a gamepad display name.
- `lurek.input.gamepad.isGamepad`: Returns whether a connected gamepad exists at an id.
- `lurek.input.gamepad.getButtonCount`: Returns the button count for a gamepad.
- `lurek.input.gamepad.getAxisCount`: Returns the axis count for a gamepad.
- `lurek.input.gamepad.isDown`: Returns whether a gamepad button is currently down.
- `lurek.input.gamepad.getAxis`: Returns a gamepad axis value.
- `lurek.input.gamepad.virtualDpad`: Converts analog x and y values into virtual d-pad booleans and direction.
- `lurek.input.gamepad.isVibrationSupported`: Returns whether a gamepad supports vibration requests.
- `lurek.input.gamepad.vibrate`: Requests gamepad vibration with low and high frequency motor strengths.
- `lurek.input.gamepad.getGUID`: Returns the GUID string for a gamepad.
- `lurek.input.gamepad.getHat`: Returns hat direction for a gamepad hat index.
- `lurek.input.gamepad.setVibration`: Requests gamepad vibration with low and high frequency motor strengths.
- `lurek.input.gamepad.wasPressed`: Returns whether a gamepad button was pressed this frame.
- `lurek.input.gamepad.wasReleased`: Returns whether a gamepad button was released this frame.
- `lurek.input.gamepad.wasConnected`: Returns whether a gamepad connected this frame.
- `lurek.input.gamepad.wasDisconnected`: Returns whether a gamepad disconnected this frame.
- `lurek.input.gamepad.setBackgroundEvents`: Enables or disables background gamepad event processing.
- `lurek.input.gamepad.getBackgroundEvents`: Returns whether background gamepad event processing is enabled.
- `lurek.input.gamepad.setGamepadMapping`: Stores a controller mapping string for a gamepad GUID.
- `lurek.input.gamepad.getGamepadMappingString`: Returns a stored mapping string for a gamepad GUID.
- `lurek.input.gamepad.loadGamepadMappings`: Loads gamepad mapping strings from a file.
- `lurek.input.gamepad.saveGamepadMappings`: Saves gamepad mapping strings to a file.
- `lurek.input.touch.getTouches`: Returns active touch points with id, position, and pressure.
- `lurek.input.touch.getPosition`: Returns the position of a touch id.
- `lurek.input.touch.getPressure`: Returns pressure for a touch id.
- `lurek.input.touch.getTouchCount`: Returns the current active touch count.
- `lurek.input.touch.wasPressed`: Returns whether a touch id began this frame.
- `lurek.input.touch.wasReleased`: Returns whether a touch id ended this frame.
- `lurek.input.bind`: Adds one or more keyboard/gamepad bindings to an action.
- `lurek.input.newMapping`: Creates an action mapping table with isDown, wasPressed, and wasReleased helper functions.
- `lurek.input.isDown`: Lua-facing function documented in the binding source.
- `lurek.input.wasPressed`: Lua-facing function documented in the binding source.
- `lurek.input.wasReleased`: Lua-facing function documented in the binding source.
- `lurek.input.unbind`: Removes all bindings for an action.
- `lurek.input.clearBindings`: Removes all action bindings.
- `lurek.input.getBindings`: Returns all action bindings.
- `lurek.input.isActionDown`: Returns whether any binding for an action is currently down.
- `lurek.input.wasActionPressed`: Returns whether any binding for an action was pressed this frame and records the frame.
- `lurek.input.wasActionReleased`: Returns whether any binding for an action was released this frame.
- `lurek.input.wasActionPressedWithin`: Returns whether an action was pressed within a recent frame window.
- `lurek.input.newCombo`: Creates a combo detector from string steps or step tables with optional timing.
- `lurek.input.startRecording`: Starts recording input events into the module recorder.
- `lurek.input.stopRecording`: Stops input recording and returns the captured recording when one is active.
- `lurek.input.loadRecording`: Loads recording JSON into the module recorder.
- `lurek.input.startPlayback`: Starts playback of the loaded recording.
- `lurek.input.stopPlayback`: Stops playback of the loaded recording.
- `lurek.input.isRecording`: Returns whether the module recorder is currently recording.
- `lurek.input.isPlayingBack`: Returns whether the module recorder is currently playing back.
- `lurek.input.getPlaybackFrame`: Returns the current playback frame index.
- `lurek.input.advancePlayback`: Advances playback by one frame and returns events for that frame.

### `LCombo` Methods
- `LCombo:feed`: Feeds one key into the combo detector and returns progress status.
- `LCombo:tick`: Advances combo timeout state and returns progress status.
- `LCombo:reset`: Resets combo progress and elapsed time.
- `LCombo:progress`: Returns the current combo step index reached.
- `LCombo:totalSteps`: Returns the number of steps in this combo sequence.
- `LCombo:isInProgress`: Returns whether the combo sequence is partially matched.
- `LCombo:getStep`: Returns step data by one-based index.
- `LCombo:type`: Returns the Lua-visible type name for this combo handle.
- `LCombo:typeOf`: Returns whether this combo handle matches a supported type name.

### `LCursor` Methods
- `LCursor:release`: Releases cursor resources; currently a no-op for managed cursor handles.
- `LCursor:getType`: Returns whether this cursor is a system cursor or custom cursor.
- `LCursor:type`: Returns the Lua-visible type name for this cursor handle.
- `LCursor:typeOf`: Returns whether this cursor handle matches a supported type name.

### `LInputRecording` Methods
- `LInputRecording:toJson`: Serializes this input recording to JSON text.
- `LInputRecording:totalFrames`: Returns total frame count stored in this recording.
- `LInputRecording:frameCount`: Returns the number of event frames stored in this recording.
- `LInputRecording:type`: Returns the Lua-visible type name for this input recording handle.
- `LInputRecording:typeOf`: Returns whether this input recording handle matches a supported type name.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/input/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### New in 1.0.9-fix.44

- `lurek.input.gamepad.vibrate(id, low_freq, high_freq, duration_ms)` and `lurek.input.gamepad.setVibration(...)` now queue real rumble requests via `gilrs::ff` when force-feedback is supported.
- Added frame-perfect gamepad edge queries:
	- `lurek.input.gamepad.wasPressed(id, button)`
	- `lurek.input.gamepad.wasReleased(id, button)`
	- `lurek.input.gamepad.wasConnected(id)`
	- `lurek.input.gamepad.wasDisconnected(id)`
- Added frame-perfect touch edge queries:
	- `lurek.input.touch.wasPressed(id)`
	- `lurek.input.touch.wasReleased(id)`
- Added `lurek.input.newMapping(name, keys)` convenience constructor returning a mapping object with `isDown()`, `wasPressed()`, and `wasReleased()`.
- Action mappings now accept gamepad button bindings in `gamepad:<id>:<button>` format.
- Input recording JSON now includes a schema envelope field: `"version": 1`.
	- `InputRecording::from_json` remains backward-compatible with legacy payloads that omit `version`.
