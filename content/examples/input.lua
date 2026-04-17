-- content/examples/input.lua
-- Lurek2D lurek.input API Reference
-- Run with: cargo run -- content/examples/input

-- =============================================================================
-- Input System — keyboard, mouse, gamepad, touch, action bindings,
-- combo detection, and input recording/playback
-- =============================================================================

-- ---- Stub: lurek.input.isDown --------------------------------------------
--@api-stub: lurek.input.isDown
-- Check whether movement keys are held so the player character keeps running.
-- isDown returns true for the ENTIRE duration the key is held, not just the press frame.
local moving_left  = lurek.input.isDown("a")
local moving_right = lurek.input.isDown("d")
local jumping      = lurek.input.isDown("space")
if moving_left then
    print("player running left")
elseif moving_right then
    print("player running right")
end
if jumping then
    print("player holding jump")
end

-- ---- Stub: lurek.input.isScancodeDown ------------------------------------
--@api-stub: lurek.input.isScancodeDown
-- Scancodes are layout-independent — WASD stays the same on AZERTY keyboards.
-- Use scancodes for movement so the physical key position always matches.
local sc_w = lurek.input.isScancodeDown("w")
local sc_a = lurek.input.isScancodeDown("a")
local sc_s = lurek.input.isScancodeDown("s")
local sc_d = lurek.input.isScancodeDown("d")
print("WASD (scancode) — W:" .. tostring(sc_w)
    .. " A:" .. tostring(sc_a)
    .. " S:" .. tostring(sc_s)
    .. " D:" .. tostring(sc_d))

-- ---- Stub: lurek.input.setKeyRepeat --------------------------------------
--@api-stub: lurek.input.setKeyRepeat
-- Enable key repeat for a text-based inventory search box so holding backspace
-- deletes characters continuously, like a native text field.
lurek.input.setKeyRepeat(true)
print("key repeat enabled for search box")

-- ---- Stub: lurek.input.hasKeyRepeat --------------------------------------
--@api-stub: lurek.input.hasKeyRepeat
-- Query whether key repeat is on before toggling — avoids double-enabling.
local repeat_on = lurek.input.hasKeyRepeat()
print("key repeat currently: " .. tostring(repeat_on))

-- ---- Stub: lurek.input.setTextInput --------------------------------------
--@api-stub: lurek.input.setTextInput
-- Enable Unicode text input when the player opens the chat window.
-- This triggers textinput events that include composed characters (accents, CJK).
lurek.input.setTextInput(true)
print("text input enabled — chat window open")

-- ---- Stub: lurek.input.hasTextInput --------------------------------------
--@api-stub: lurek.input.hasTextInput
-- Check text input state so we know whether to route keypresses to the chat box
-- or to the game action system.
local text_mode = lurek.input.hasTextInput()
print("text input mode active: " .. tostring(text_mode))
-- Disable when the chat window is closed
lurek.input.setTextInput(false)
print("text input disabled — back to game controls")

-- ---- Stub: lurek.input.getScancodeFromKey --------------------------------
--@api-stub: lurek.input.getScancodeFromKey
-- In a key-rebinding menu, convert the user-facing key name to the internal scancode
-- so the binding works regardless of keyboard layout.
local scancode_for_space = lurek.input.getScancodeFromKey("space")
print("scancode for 'space': " .. tostring(scancode_for_space))
local scancode_for_return = lurek.input.getScancodeFromKey("return")
print("scancode for 'return': " .. tostring(scancode_for_return))

-- ---- Stub: lurek.input.getKeyFromScancode --------------------------------
--@api-stub: lurek.input.getKeyFromScancode
-- Display the user-facing key name in the settings UI by reverse-mapping the scancode.
local key_name = lurek.input.getKeyFromScancode("space")
print("key name for scancode 'space': " .. tostring(key_name))

-- ---- Stub: lurek.input.isModifierActive ----------------------------------
--@api-stub: lurek.input.isModifierActive
-- Ctrl+click to select multiple units in an RTS — only add to selection when ctrl is held.
local ctrl_held  = lurek.input.isModifierActive("ctrl")
local shift_held = lurek.input.isModifierActive("shift")
print("ctrl held: " .. tostring(ctrl_held) .. "  shift held: " .. tostring(shift_held))
if ctrl_held then
    print("adding unit to selection group")
end

-- =============================================================================
-- Mouse — position, buttons, cursor, grab, and scroll wheel
-- =============================================================================

-- ---- Stub: lurek.input.getPosition ---------------------------------------
--@api-stub: lurek.input.getPosition
-- Read the mouse position to aim a crosshair at the cursor location.
local aim_x, aim_y = lurek.input.getPosition()
print("crosshair at: " .. tostring(aim_x) .. ", " .. tostring(aim_y))

-- ---- Stub: lurek.input.getX ----------------------------------------------
--@api-stub: lurek.input.getX
-- ---- Stub: lurek.input.getY ----------------------------------------------
--@api-stub: lurek.input.getY
-- Individually read X and Y for a parallax background offset calculation.
local mouse_x = lurek.input.getX()
local mouse_y = lurek.input.getY()
local parallax_offset_x = (mouse_x - 640) * 0.02
local parallax_offset_y = (mouse_y - 360) * 0.01
print("parallax offset: " .. parallax_offset_x .. ", " .. parallax_offset_y)

-- ---- Stub: lurek.input.isDown --------------------------------------------
--@api-stub: lurek.input.isDown
-- Detect mouse button held for drag-selection box in an RTS.
-- Button 1 = left click, 2 = right click, 3 = middle click.
local lmb_held = lurek.input.isDown(1)
local rmb_held = lurek.input.isDown(2)
if lmb_held then
    print("drawing selection rectangle from " .. tostring(aim_x) .. "," .. tostring(aim_y))
elseif rmb_held then
    print("issuing move command to " .. tostring(aim_x) .. "," .. tostring(aim_y))
end

-- ---- Stub: lurek.input.setVisible ----------------------------------------
--@api-stub: lurek.input.setVisible
-- Hide the OS cursor during gameplay (replaced by a custom sprite crosshair)
-- and show it again when opening the pause menu.
lurek.input.setVisible(false)
print("OS cursor hidden — using custom crosshair sprite")

-- ---- Stub: lurek.input.isVisible -----------------------------------------
--@api-stub: lurek.input.isVisible
-- Check cursor visibility before toggling to avoid flicker.
local cursor_visible = lurek.input.isVisible()
print("cursor visible: " .. tostring(cursor_visible))
lurek.input.setVisible(true)
print("OS cursor restored for pause menu")

-- ---- Stub: lurek.input.setGrabbed ----------------------------------------
--@api-stub: lurek.input.setGrabbed
-- Grab the mouse in a first-person view so it cannot leave the window.
lurek.input.setGrabbed(true)
print("mouse grabbed — first-person camera active")

-- ---- Stub: lurek.input.isGrabbed -----------------------------------------
--@api-stub: lurek.input.isGrabbed
-- Show an unlock hint only when the mouse is currently grabbed.
local grabbed = lurek.input.isGrabbed()
if grabbed then
    print("press ESC to release the cursor")
end
lurek.input.setGrabbed(false)
print("mouse released")

-- ---- Stub: lurek.input.setRelativeMode -----------------------------------
--@api-stub: lurek.input.setRelativeMode
-- Enable relative mouse mode for a mouselook camera — the cursor is hidden and
-- deltas are reported instead of absolute positions.
lurek.input.setRelativeMode(true)
print("relative mouse mode ON — mouselook camera active")

-- ---- Stub: lurek.input.getRelativeMode -----------------------------------
--@api-stub: lurek.input.getRelativeMode
-- Toggle relative mode off when opening the inventory overlay.
local rel_mode = lurek.input.getRelativeMode()
print("relative mode: " .. tostring(rel_mode))
lurek.input.setRelativeMode(false)
print("relative mode OFF — inventory cursor active")

-- ---- Stub: lurek.input.setPosition ---------------------------------------
--@api-stub: lurek.input.setPosition
-- Snap the cursor to the centre of the screen when entering aim-down-sights mode.
local center_x, center_y = 640, 360
lurek.input.setPosition(center_x, center_y)
print("cursor snapped to screen center: " .. center_x .. ", " .. center_y)

-- ---- Stub: lurek.input.setCursor -----------------------------------------
--@api-stub: lurek.input.setCursor
-- Switch to a crosshair system cursor when hovering over an enemy.
-- Pass a Cursor handle, a system cursor name string, or nil to reset.
lurek.input.setCursor("crosshair")
print("cursor set to crosshair for targeting")

-- ---- Stub: lurek.input.newCursor -----------------------------------------
--@api-stub: lurek.input.newCursor
-- Create a custom cursor from RGBA pixel data for a pixel-art game.
-- Arguments: width, height, hotspot_x, hotspot_y, pixel_data_table
local pixel_data = {}
for i = 1, 16 * 16 * 4 do pixel_data[i] = 255 end  -- solid white 16x16
local custom_cursor = lurek.input.newCursor(16, 16, 0, 0, pixel_data)
print("custom 16x16 cursor created, type: " .. type(custom_cursor))

-- ---- Stub: lurek.input.getSystemCursor -----------------------------------
--@api-stub: lurek.input.getSystemCursor
-- Retrieve a platform system cursor (arrow, hand, ibeam, crosshair, etc.)
-- for use in UI hover states.
local hand_cursor = lurek.input.getSystemCursor("hand")
print("system hand cursor: " .. type(hand_cursor))
local arrow_cursor = lurek.input.getSystemCursor("arrow")
print("system arrow cursor: " .. type(arrow_cursor))

-- ---- Stub: lurek.input.isCursorSupported ---------------------------------
--@api-stub: lurek.input.isCursorSupported
-- Check platform support before attempting to create custom cursors.
local cursor_supported = lurek.input.isCursorSupported()
print("custom cursors supported: " .. tostring(cursor_supported))

-- ---- Stub: lurek.input.getCursor -----------------------------------------
--@api-stub: lurek.input.getCursor
-- Query which cursor is currently active to restore it after a tooltip hover.
local current_cursor_name = lurek.input.getCursor()
print("active cursor: " .. tostring(current_cursor_name))

-- ---- Stub: lurek.input.getWheelDelta -------------------------------------
--@api-stub: lurek.input.getWheelDelta
-- Use the scroll wheel to zoom the camera in a strategy game.
-- Returns (dx, dy) — dy > 0 means scroll up (zoom in).
local wheel_dx, wheel_dy = lurek.input.getWheelDelta()
print("scroll wheel delta: dx=" .. tostring(wheel_dx) .. " dy=" .. tostring(wheel_dy))
if wheel_dy and wheel_dy > 0 then
    print("zooming camera in")
elseif wheel_dy and wheel_dy < 0 then
    print("zooming camera out")
end

-- =============================================================================
-- Gamepad — enumerate, query buttons/axes, vibration, mappings
-- =============================================================================

-- ---- Stub: lurek.input.getCount ------------------------------------------
--@api-stub: lurek.input.getCount
-- Show connected gamepad count on the title screen.
local gamepad_count = lurek.input.getCount()
print("gamepads connected: " .. tostring(gamepad_count))

-- ---- Stub: lurek.input.getJoystickCount ----------------------------------
--@api-stub: lurek.input.getJoystickCount
-- Total tracked joystick slots (may differ from connected count).
local joystick_slots = lurek.input.getJoystickCount()
print("joystick slots tracked: " .. tostring(joystick_slots))

-- ---- Stub: lurek.input.getJoysticks --------------------------------------
--@api-stub: lurek.input.getJoysticks
-- Enumerate all connected gamepads to build a player-assignment screen.
local joystick_ids = lurek.input.getJoysticks()
print("connected joystick IDs: " .. tostring(#joystick_ids))
for i, jid in ipairs(joystick_ids) do
    print("  slot " .. i .. ": joystick " .. tostring(jid))
end

-- ---- Stub: lurek.input.isConnected ---------------------------------------
--@api-stub: lurek.input.isConnected
-- Before reading gamepad input, verify the controller is still plugged in
-- to avoid stale data from a disconnected device.
local pad1_connected = lurek.input.isConnected(1)
print("gamepad 1 connected: " .. tostring(pad1_connected))

-- ---- Stub: lurek.input.getName -------------------------------------------
--@api-stub: lurek.input.getName
-- Display the gamepad name in the controller-select screen.
local pad1_name = lurek.input.getName(1)
print("gamepad 1 name: " .. tostring(pad1_name))

-- ---- Stub: lurek.input.isGamepad -----------------------------------------
--@api-stub: lurek.input.isGamepad
-- Distinguish gamepads from generic joysticks (flight sticks, steering wheels)
-- to apply the correct button prompts.
local is_standard_pad = lurek.input.isGamepad(1)
print("slot 1 is standard gamepad: " .. tostring(is_standard_pad))

-- ---- Stub: lurek.input.getButtonCount ------------------------------------
--@api-stub: lurek.input.getButtonCount
-- Query button count to build a dynamic remapping UI for the controller.
local btn_count = lurek.input.getButtonCount(1)
print("gamepad 1 buttons: " .. tostring(btn_count))

-- ---- Stub: lurek.input.getAxisCount --------------------------------------
--@api-stub: lurek.input.getAxisCount
-- Query axis count to know how many analog sticks / triggers are available.
local axis_count = lurek.input.getAxisCount(1)
print("gamepad 1 axes: " .. tostring(axis_count))

-- ---- Stub: lurek.input.isDown --------------------------------------------
--@api-stub: lurek.input.isDown
-- Check if the A button (button 1) is held for a charged jump.
-- First arg is gamepad ID, second is button index.
local a_held = lurek.input.isDown(1, 1)
if a_held then
    print("gamepad 1: A button held — charging jump power")
end

-- ---- Stub: lurek.input.getAxis -------------------------------------------
--@api-stub: lurek.input.getAxis
-- Read the left stick X axis (-1.0 = full left, 1.0 = full right)
-- and apply a deadzone before moving the player.
local left_stick_x = lurek.input.getAxis(1, 1)
local deadzone = 0.15
if math.abs(left_stick_x) > deadzone then
    local move_speed = left_stick_x * 200.0  -- pixels per second
    print("moving player at speed: " .. string.format("%.1f", move_speed))
else
    print("left stick inside deadzone — player idle")
end

-- ---- Stub: lurek.input.isVibrationSupported ------------------------------
--@api-stub: lurek.input.isVibrationSupported
-- Only trigger rumble effects on controllers that support them.
local vib_ok = lurek.input.isVibrationSupported(1)
print("gamepad 1 vibration supported: " .. tostring(vib_ok))

-- ---- Stub: lurek.input.vibrate -------------------------------------------
--@api-stub: lurek.input.vibrate
-- Trigger a strong rumble when the player takes damage.
-- Args: gamepad_id, low_frequency_intensity, high_frequency_intensity, duration_ms
if vib_ok then
    lurek.input.vibrate(1, 0.8, 0.4, 250)
    print("damage rumble: heavy low-freq, light high-freq, 250ms")
end

-- ---- Stub: lurek.input.getGUID -------------------------------------------
--@api-stub: lurek.input.getGUID
-- Read the hardware GUID to look up custom mapping overrides in a config file.
local guid = lurek.input.getGUID(1)
print("gamepad 1 GUID: " .. tostring(guid))

-- ---- Stub: lurek.input.getHat --------------------------------------------
--@api-stub: lurek.input.getHat
-- Read the D-pad (hat switch) direction for menu navigation.
local hat_dir = lurek.input.getHat(1, 1)
print("gamepad 1 hat direction: " .. tostring(hat_dir))

-- ---- Stub: lurek.input.setVibration --------------------------------------
--@api-stub: lurek.input.setVibration
-- Alternative vibration API — set ongoing rumble intensity (currently a no-op stub).
local vib_result = lurek.input.setVibration(1, 0.5, 0.3)
print("setVibration result: " .. tostring(vib_result))

-- ---- Stub: lurek.input.setBackgroundEvents -------------------------------
--@api-stub: lurek.input.setBackgroundEvents
-- Enable background gamepad events so a rhythm game keeps reading input even when
-- the player alt-tabs to check a guide.
lurek.input.setBackgroundEvents(true)
print("background gamepad events enabled")

-- ---- Stub: lurek.input.getBackgroundEvents -------------------------------
--@api-stub: lurek.input.getBackgroundEvents
-- Confirm background events are active before the match starts.
local bg_events = lurek.input.getBackgroundEvents()
print("background events: " .. tostring(bg_events))
lurek.input.setBackgroundEvents(false)

-- ---- Stub: lurek.input.setGamepadMapping ---------------------------------
--@api-stub: lurek.input.setGamepadMapping
-- Override the button layout for a specific third-party controller using
-- an SDL2 GameControllerDB mapping string.
local example_guid    = "03000000c82d00001090000000000000"
local example_mapping = "03000000c82d00001090000000000000,8Bitdo SN30,a:b0,b:b1,x:b3,y:b4,platform:Windows,"
lurek.input.setGamepadMapping(example_guid, example_mapping)
print("custom mapping set for 8Bitdo SN30")

-- ---- Stub: lurek.input.getGamepadMappingString ---------------------------
--@api-stub: lurek.input.getGamepadMappingString
-- Read back the stored mapping to display it in the controller config screen.
local stored_mapping = lurek.input.getGamepadMappingString(example_guid)
print("stored mapping: " .. tostring(stored_mapping))

-- ---- Stub: lurek.input.loadGamepadMappings -------------------------------
--@api-stub: lurek.input.loadGamepadMappings
-- Bulk-load community gamepad mappings from an SDL GameControllerDB text file
-- shipped with the game. Returns the number of mappings loaded.
local ok_load, load_count = pcall(function()
    return lurek.input.loadGamepadMappings("assets/gamecontrollerdb.txt")
end)
print("loadGamepadMappings: " .. tostring(ok_load) .. " count=" .. tostring(load_count))

-- ---- Stub: lurek.input.saveGamepadMappings -------------------------------
--@api-stub: lurek.input.saveGamepadMappings
-- Export all current mappings (built-in + user overrides) to a file
-- so they persist across sessions.
local ok_save = pcall(function()
    lurek.input.saveGamepadMappings("save/gamepad_mappings.txt")
end)
print("saveGamepadMappings: " .. tostring(ok_save))

-- =============================================================================
-- Touch — multi-touch queries (mobile / touchscreen laptops)
-- =============================================================================

-- ---- Stub: lurek.input.getTouches ----------------------------------------
--@api-stub: lurek.input.getTouches
-- Enumerate all active touch points to support multi-finger gestures.
-- Each entry has id, x, y, and pressure fields.
local touches = lurek.input.getTouches()
print("active touch points: " .. #touches)
for i, touch in ipairs(touches) do
    print("  touch " .. touch.id .. " at (" .. touch.x .. ", " .. touch.y
        .. ") pressure=" .. string.format("%.2f", touch.pressure))
end

-- ---- Stub: lurek.input.getPosition ---------------------------------------
--@api-stub: lurek.input.getPosition
-- Read a specific touch by ID for a virtual joystick thumb tracking.
local touch_x, touch_y = lurek.input.getPosition(1)
print("touch #1 position: " .. tostring(touch_x) .. ", " .. tostring(touch_y))

-- ---- Stub: lurek.input.getPressure ---------------------------------------
--@api-stub: lurek.input.getPressure
-- Use touch pressure for a painting app — harder press = thicker brush stroke.
local pressure = lurek.input.getPressure(1)
print("touch #1 pressure: " .. tostring(pressure))
local brush_size = 4 + (pressure or 0) * 20
print("brush size: " .. string.format("%.1f", brush_size))

-- ---- Stub: lurek.input.getTouchCount -------------------------------------
--@api-stub: lurek.input.getTouchCount
-- Quick count check — only process pinch-zoom when exactly 2 fingers are down.
local finger_count = lurek.input.getTouchCount()
print("fingers down: " .. tostring(finger_count))
if finger_count == 2 then
    print("pinch-zoom gesture detected")
end

-- =============================================================================
-- Action Bindings — abstract named actions mapped to physical keys
-- =============================================================================

-- ---- Stub: lurek.input.bind ----------------------------------------------
--@api-stub: lurek.input.bind
-- Bind game actions to keys. Multiple keys per action allow keyboard + gamepad.
-- The player can rebind these from the settings menu.
lurek.input.bind("jump",   {"space", "gamepad_a"})
lurek.input.bind("attack", {"z", "gamepad_x"})
lurek.input.bind("dash",   {"lshift", "gamepad_b"})
lurek.input.bind("interact", {"e", "gamepad_y"})
print("actions bound: jump, attack, dash, interact")

-- ---- Stub: lurek.input.unbind --------------------------------------------
--@api-stub: lurek.input.unbind
-- Remove the dash binding during a cutscene where movement is disabled.
local unbound = lurek.input.unbind("dash")
print("dash unbound: " .. tostring(unbound))

-- ---- Stub: lurek.input.clearBindings -------------------------------------
--@api-stub: lurek.input.clearBindings
-- Clear everything before loading a custom binding preset from the save file.
lurek.input.clearBindings()
print("all bindings cleared — ready to load custom preset")

-- ---- Stub: lurek.input.getBindings ---------------------------------------
--@api-stub: lurek.input.getBindings
-- Re-bind from scratch and display the current mapping table.
lurek.input.bind("jump",   {"space", "gamepad_a"})
lurek.input.bind("attack", {"z", "gamepad_x"})
local bindings = lurek.input.getBindings()
print("current bindings:")
for action, keys in pairs(bindings) do
    print("  " .. action .. " -> " .. table.concat(keys, ", "))
end

-- ---- Stub: lurek.input.isActionDown --------------------------------------
--@api-stub: lurek.input.isActionDown
-- Use action names instead of raw keys for gameplay logic — this automatically
-- works with both keyboard and gamepad.
local jump_held = lurek.input.isActionDown("jump")
if jump_held then
    print("player is holding jump — increase jump height")
end

-- ---- Stub: lurek.input.wasActionPressed ----------------------------------
--@api-stub: lurek.input.wasActionPressed
-- Detect the exact frame the attack button was pressed for responsive combat.
local attack_pressed = lurek.input.wasActionPressed("attack")
if attack_pressed then
    print("attack started — play swing animation")
end

-- ---- Stub: lurek.input.wasActionReleased ---------------------------------
--@api-stub: lurek.input.wasActionReleased
-- Detect button release to fire a charged attack when the player lets go.
local attack_released = lurek.input.wasActionReleased("attack")
if attack_released then
    print("attack released — fire charged projectile")
end

-- ---- Stub: lurek.input.wasActionPressedWithin ----------------------------
--@api-stub: lurek.input.wasActionPressedWithin
-- Allow a 6-frame input buffer for the jump action so the player can press
-- jump slightly before landing and still get an immediate jump.
local buffered_jump = lurek.input.wasActionPressedWithin("jump", 6)
if buffered_jump then
    print("buffered jump detected — executing jump on landing")
end

-- =============================================================================
-- Combo Detection — multi-key input sequences (fighting game combos)
-- =============================================================================

-- ---- Stub: lurek.input.newCombo ------------------------------------------
--@api-stub: lurek.input.newCombo
-- Define a three-key hadouken combo: down, down-forward, forward + punch.
-- Each step has a max gap (ms) before the combo resets.
local combo = lurek.input.newCombo(
    { "down", "down+right", "right", "z" },
    { timeout_ms = 500 }
)
print("hadouken combo created with " .. combo:totalSteps() .. " steps")

-- ---- Stub: Combo:feed ----------------------------------------------------
--@api-stub: Combo:feed
-- Feed key-press events into the combo detector as they arrive from the input
-- callback. The detector tracks whether the sequence is being followed.
combo:feed("down")
print("fed 'down' — progress: " .. combo:progress() .. "/" .. combo:totalSteps())
combo:feed("down+right")
print("fed 'down+right' — progress: " .. combo:progress() .. "/" .. combo:totalSteps())

-- ---- Stub: Combo:tick ----------------------------------------------------
--@api-stub: Combo:tick
-- Advance the combo timer every frame. If the gap between two inputs exceeds
-- the timeout, the combo resets automatically.
local dt = 0.016  -- ~60 FPS frame time
combo:tick(dt)
print("combo ticked by " .. dt .. "s — still in progress: " .. tostring(combo:isInProgress()))

-- ---- Stub: Combo:reset ---------------------------------------------------
--@api-stub: Combo:reset
-- Manually reset the combo when the player gets hit mid-sequence.
combo:reset()
print("combo reset by damage — progress back to " .. combo:progress())

-- ---- Stub: Combo:progress ------------------------------------------------
--@api-stub: Combo:progress
-- Display a combo progress bar in the fighting game HUD.
-- Feed some steps again after the reset to show progress climbing.
combo:feed("down")
combo:feed("down+right")
local matched = combo:progress()
print("combo progress: " .. matched .. " of " .. combo:totalSteps() .. " steps matched")

-- ---- Stub: Combo:totalSteps ----------------------------------------------
--@api-stub: Combo:totalSteps
-- Show total steps in the moves list / tutorial screen.
local total = combo:totalSteps()
print("this combo requires " .. total .. " sequential inputs")

-- ---- Stub: Combo:isInProgress --------------------------------------------
--@api-stub: Combo:isInProgress
-- Highlight the combo meter in the HUD when the player is mid-sequence.
local in_progress = combo:isInProgress()
if in_progress then
    print("combo meter glowing — keep going!")
else
    print("combo idle — start with 'down'")
end

-- ---- Stub: Combo:getStep -------------------------------------------------
--@api-stub: Combo:getStep
-- Display each step in a tutorial tooltip: the expected key and the max gap.
for i = 1, combo:totalSteps() do
    local step = combo:getStep(i)
    print("step " .. i .. ": key=" .. tostring(step.key)
        .. " gap_ms=" .. tostring(step.gap_ms))
end

-- =============================================================================
-- Cursor Object — custom and system cursor handles
-- =============================================================================

-- ---- Stub: Cursor:release ------------------------------------------------
--@api-stub: Cursor:release
-- Release the custom cursor when leaving the aiming state to free resources.
-- On desktop this is typically a no-op, but it is good practice.
if custom_cursor then
    custom_cursor:release()
    print("custom cursor released")
end

-- ---- Stub: Cursor:getType ------------------------------------------------
--@api-stub: Cursor:getType
-- Check whether the active cursor is a custom image or a system cursor
-- so the UI knows whether to show a software-rendered fallback.
local cursor_type = hand_cursor:getType()
print("hand cursor type: " .. tostring(cursor_type))
-- Expect "system" for getSystemCursor results, "custom" for newCursor results

-- =============================================================================
-- Input Recording & Playback — replay system for testing and demos
-- =============================================================================

-- ---- Stub: lurek.input.startRecording ------------------------------------
--@api-stub: lurek.input.startRecording
-- Begin recording player inputs for an automated replay / QA test.
lurek.input.startRecording()
print("input recording started")

-- ---- Stub: lurek.input.isRecording ---------------------------------------
--@api-stub: lurek.input.isRecording
-- Show a red REC indicator in the corner while recording is active.
local is_rec = lurek.input.isRecording()
print("recording active: " .. tostring(is_rec))

-- ---- Stub: lurek.input.stopRecording -------------------------------------
--@api-stub: lurek.input.stopRecording
-- Stop recording after the test sequence and get the recording object.
local rec = lurek.input.stopRecording()
print("recording stopped — got recording: " .. tostring(rec ~= nil))

-- ---- Stub: InputRecording:toJson -----------------------------------------
--@api-stub: InputRecording:toJson
-- Serialize the recording to JSON so it can be saved to disk and replayed later.
if rec then
    local json_str = rec:toJson()
    print("recording JSON length: " .. #json_str .. " bytes")
    print("first 80 chars: " .. json_str:sub(1, 80))
end

-- ---- Stub: InputRecording:totalFrames ------------------------------------
--@api-stub: InputRecording:totalFrames
-- Display the total frame count of the recording in the replay browser.
if rec then
    local total_frames = rec:totalFrames()
    print("recording total frames: " .. tostring(total_frames))
end

-- ---- Stub: InputRecording:frameCount -------------------------------------
--@api-stub: InputRecording:frameCount
-- The frameCount is the number of sparse event frames (frames that had input),
-- which is typically much smaller than totalFrames (wall-clock frames).
if rec then
    local event_frames = rec:frameCount()
    print("sparse event frames: " .. tostring(event_frames))
    print("compression ratio: " .. tostring(event_frames) .. " / " .. tostring(rec:totalFrames()))
end

-- ---- Stub: lurek.input.loadRecording -------------------------------------
--@api-stub: lurek.input.loadRecording
-- Load a previously saved recording from its JSON representation for playback.
if rec then
    local json_data = rec:toJson()
    lurek.input.loadRecording(json_data)
    print("recording loaded for playback")
end

-- ---- Stub: lurek.input.startPlayback -------------------------------------
--@api-stub: lurek.input.startPlayback
-- Begin replaying the loaded recording from frame 0.
lurek.input.startPlayback()
print("playback started from frame 0")

-- ---- Stub: lurek.input.isPlayingBack -------------------------------------
--@api-stub: lurek.input.isPlayingBack
-- Show a PLAY indicator while playback is running.
local is_playing = lurek.input.isPlayingBack()
print("playback active: " .. tostring(is_playing))

-- ---- Stub: lurek.input.getPlaybackFrame ----------------------------------
--@api-stub: lurek.input.getPlaybackFrame
-- Display the current playback position in a progress bar.
local current_frame = lurek.input.getPlaybackFrame()
print("playback at frame: " .. tostring(current_frame))

-- ---- Stub: lurek.input.advancePlayback -----------------------------------
--@api-stub: lurek.input.advancePlayback
-- Step through the recording one frame at a time for slow-motion debug replay.
-- Returns a table of key/button events that occurred on that frame.
local events = lurek.input.advancePlayback()
print("frame events: " .. tostring(#events) .. " input(s)")
for _, evt in ipairs(events) do
    print("  event: " .. tostring(evt))
end

-- ---- Stub: lurek.input.stopPlayback --------------------------------------
--@api-stub: lurek.input.stopPlayback
-- Stop playback and return to live input when the replay is done or skipped.
lurek.input.stopPlayback()
print("playback stopped — returning to live input")

print("\n-- input.lua example complete --")
