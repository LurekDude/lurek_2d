-- examples/input.lua
-- Luna2D luna.keyboard / luna.mouse / luna.gamepad / luna.touch API Reference
-- This file is documentation code, not a runnable game.
-- Call these from luna.process, luna.keypressed, luna.mousepressed, etc.

-- ─────────────────────────────────────────────────────────────────────────────
-- Keyboard — luna.keyboard
-- ─────────────────────────────────────────────────────────────────────────────

-- Check if a key is currently held (polling, call from luna.process)
-- Key names are lowercase strings: "a"–"z", "0"–"9", "space", "return", "escape",
-- "backspace", "tab", "left", "right", "up", "down", "lshift", "rshift",
-- "lctrl", "rctrl", "lalt", "ralt", "f1"–"f12", etc.
local moving_left  = luna.keyboard.isDown("left")  or luna.keyboard.isDown("a")
local moving_right = luna.keyboard.isDown("right") or luna.keyboard.isDown("d")

-- Multiple keys in one call (logical OR)
local any_jump = luna.keyboard.isDown("space", "up", "w")

-- Check by scancode (hardware position, layout-independent)
local sc_held = luna.keyboard.isScancodeDown("scancode_a")

-- Key repeat (fires repeated keypressed events when held)
luna.keyboard.setKeyRepeat(true)
local repeat_on = luna.keyboard.hasKeyRepeat()

-- Text input mode (enables luna.textinput callback and IME composition)
luna.keyboard.setTextInput(true)   -- call before showing a text field
luna.keyboard.setTextInput(false)  -- call when the text field loses focus
local text_on = luna.keyboard.hasTextInput()

-- Translate between key name and scancode
local sc  = luna.keyboard.getScancodeFromKey("a")   -- → "scancode_a"
local key = luna.keyboard.getKeyFromScancode(sc)     -- → "a"

-- Check modifier keys (returns true while held)
-- modifiers: "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "lgui", "rgui"
local shifted = luna.keyboard.isModifierActive("lshift")

-- ── Callback examples ────────────────────────────────────────────────────────

function luna.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        luna.signal.quit()
    end
    if key == "f" and not isrepeat then
        luna.window.setFullscreen(not luna.window.getFullscreen())
    end
end

function luna.keyreleased(key, scancode)
    -- key was just released
end

function luna.textinput(text)
    -- UTF-8 text entered (after luna.keyboard.setTextInput(true))
    -- Use this for typing in text fields; do NOT use keypressed for text input.
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Mouse — luna.mouse
-- ─────────────────────────────────────────────────────────────────────────────

-- Current cursor position relative to window (in virtual pixels)
local mx, my = luna.mouse.getPosition()
local x = luna.mouse.getX()
local y = luna.mouse.getY()

-- Check if a button is held (1=left, 2=right, 3=middle)
local left_held  = luna.mouse.isDown(1)
local right_held = luna.mouse.isDown(2)
local mid_held   = luna.mouse.isDown(3)

-- Show / hide the system cursor
luna.mouse.setVisible(false)   -- hide when drawing a custom cursor
local visible = luna.mouse.isVisible()

-- Constrain cursor to window (grab)
luna.mouse.setGrabbed(true)
local grabbed = luna.mouse.isGrabbed()

-- Relative (FPS) mode: raw delta, cursor stays hidden and centred
luna.mouse.setRelativeMode(true)
local rel = luna.mouse.getRelativeMode()

-- Warp the cursor to a position
luna.mouse.setPosition(400, 300)

-- Scroll wheel delta since last frame (use inside luna.process or in luna.wheelmoved)
local sx, sy = luna.mouse.getWheelDelta()  -- sy > 0 = scrolled up

-- ── Custom cursors ────────────────────────────────────────────────────────────

-- Create a cursor from an ImageData (pixel grid), with a hotspot offset
-- local img_data = luna.img.newImageData("cursor.png")
-- local custom_cursor = luna.mouse.newCursor(img_data, 32, 32, 0, 0)

-- Load a built-in OS cursor by name
-- names: "arrow", "ibeam", "wait", "crosshair", "sizenwse", "sizenesw",
--         "sizewe", "sizens", "sizeall", "no", "hand"
local arrow    = luna.mouse.getSystemCursor("arrow")
local hand     = luna.mouse.getSystemCursor("hand")
local ibeam    = luna.mouse.getSystemCursor("ibeam")

-- Activate a cursor object
luna.mouse.setCursor(arrow)

-- Get the current active cursor
local current = luna.mouse.getCursor()

-- Check if the platform supports custom cursors at all
local supported = luna.mouse.isCursorSupported()

-- ── Callback examples ────────────────────────────────────────────────────────

function luna.mousepressed(x, y, button, istouch, presses)
    -- presses = consecutive click count (2 = double-click)
    if button == 1 then
        print("left click at", x, y, "(clicks:", presses, ")")
    end
end

function luna.mousereleased(x, y, button, istouch, presses)
    -- button just released
end

function luna.mousemoved(x, y, dx, dy, istouch)
    -- dx, dy: delta from previous position
end

function luna.wheelmoved(x, y)
    -- y > 0 = scroll up; y < 0 = scroll down; x = horizontal scroll
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Gamepad — luna.gamepad
-- ─────────────────────────────────────────────────────────────────────────────

-- Total number of connected gamepads
local n = luna.gamepad.getCount()

-- Get all connected joystick IDs as a table
local ids = luna.gamepad.getJoysticks()  -- e.g. {1, 2}

-- Check if specific ID is still connected
local ok = luna.gamepad.isConnected(1)

-- Device name (platform string, e.g. "Xbox Controller")
local name = luna.gamepad.getName(1)

-- Button held — button name strings:
-- "a", "b", "x", "y", "back", "guide", "start",
-- "leftstick", "rightstick", "leftshoulder", "rightshoulder",
-- "dpup", "dpdown", "dpleft", "dpright", "misc1"
local jump    = luna.gamepad.isDown(1, "a")
local sprint  = luna.gamepad.isDown(1, "rightshoulder")
local picking = luna.gamepad.isDown(1, "x")

-- Axis value in [-1, 1]
-- axes: "leftx", "lefty", "rightx", "righty", "triggerleft", "triggerright"
local lx = luna.gamepad.getAxis(1, "leftx")   -- left stick horizontal
local ly = luna.gamepad.getAxis(1, "lefty")   -- left stick vertical (+ = down)
local rx = luna.gamepad.getAxis(1, "rightx")  -- right stick horizontal
local ry = luna.gamepad.getAxis(1, "righty")  -- right stick vertical
local lt = luna.gamepad.getAxis(1, "triggerleft")   -- left trigger  [0, 1]
local rt = luna.gamepad.getAxis(1, "triggerright")  -- right trigger [0, 1]

-- Apply a dead zone manually (values below threshold treated as zero)
local DEAD_ZONE = 0.15
local move_x = math.abs(lx) > DEAD_ZONE and lx or 0.0
local move_y = math.abs(ly) > DEAD_ZONE and ly or 0.0

-- ── Callback examples ────────────────────────────────────────────────────────

function luna.gamepadpressed(id, button)
    print("gamepad", id, "pressed", button)
end

function luna.gamepadreleased(id, button)
    print("gamepad", id, "released", button)
end

function luna.gamepadaxis(id, axis, value)
    -- fires when any axis crosses a threshold
end

function luna.joystickadded(id)
    print("gamepad connected:", id)
end

function luna.joystickremoved(id)
    print("gamepad disconnected:", id)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Touch — luna.touch
-- ─────────────────────────────────────────────────────────────────────────────

-- Get all active touch points as a list
-- Each touch: {id, x, y, dx, dy, pressure}
local touches = luna.touch.getTouches()
for _, touch in ipairs(touches) do
    local tid      = touch.id
    local tx, ty   = touch.x, touch.y
    local dxtd     = touch.dx
    local dydir    = touch.dy
    local pressure = touch.pressure  -- 0–1
end

-- Get a specific touch by ID (nil if not active)
local t = luna.touch.getTouch(1)

-- ── Callback examples ────────────────────────────────────────────────────────

function luna.touchpressed(id, x, y, dx, dy, pressure)
    print("finger down:", id, x, y)
end

function luna.touchmoved(id, x, y, dx, dy, pressure)
    -- finger dragged
end

function luna.touchreleased(id, x, y, dx, dy, pressure)
    print("finger up:", id)
end

-- ─── Cursor ────────────────────────────────────────────────────────────────────

local type_val = cursor:getType()  -- Returns the cursor type as "system" or "custom"
cursor:release()  -- Releases the cursor resource (no-op on desktop)

-- ─── luna.input ────────────────────────────────────────────────────────────────
local axis_count = luna.input.getAxisCount(1)  -- Returns the total number of analog axes on the gamepad
local background_events = luna.input.getBackgroundEvents()  -- Returns whether background gamepad events are enabled
local button_count = luna.input.getButtonCount(1)  -- Returns the total number of buttons on the gamepad
local g_u_i_d = luna.input.getGUID(1)  -- Returns the hardware GUID string of the gamepad
local gamepad_mapping_string = luna.input.getGamepadMappingString("01000000...")  -- Returns stored mappingpping string for the given GUID, or nil
local hat = luna.input.getHat(1, 1)  -- Returns the direction string of a hat switch on the gamepad
local joystick_count = luna.input.getJoystickCount()  -- Returns the number of tracked gamepad slots
local pressure = luna.input.getPressure(1)  -- Returns the pressure (0-1) of the touch with the given ID
local touch_count = luna.input.getTouchCount()  -- Returns the number of currently active touch points
local is_gamepad = luna.input.isGamepad(1)  -- Returns whether the joystick at the given slot is a recognized gamepad
local is_vibration_supported = luna.input.isVibrationSupported(1)  -- Returns whether the gamepad supports haptic vibration
local load_gamepad_mappings = luna.input.loadGamepadMappings("path/to/file")  -- Loads SDL2 GameControllerDB-format mappings from a file
luna.input.saveGamepadMappings("path/to/file")  -- Saves all stored gamepad mappings to a plain-text file
luna.input.setBackgroundEvents(false)  -- Enable or disable receiving gamepad events when the window is not focused
luna.input.setGamepadMapping("gamepad_guid", sdl_mapping_string)  -- Stores or replaces a GameControllerDB mappinging string for the given GUID
local set_vibration = luna.input.setVibration(any)  -- Triggers haptic rumble (currently a no-op stub)
