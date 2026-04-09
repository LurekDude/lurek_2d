-- examples/input.lua
-- Lurek2D lurek.keyboard / lurek.mouse / lurek.gamepad / lurek.touch API Reference
-- Call these from lurek.process, lurek.keypressed, lurek.mousepressed, etc.

-- ─────────────────────────────────────────────────────────────────────────────
-- Keyboard — lurek.keyboard
-- ─────────────────────────────────────────────────────────────────────────────

-- Check if a key is currently held (polling, call from lurek.process)
-- Key names are lowercase strings: "a"–"z", "0"–"9", "space", "return", "escape",
-- "backspace", "tab", "left", "right", "up", "down", "lshift", "rshift",
-- "lctrl", "rctrl", "lalt", "ralt", "f1"–"f12", etc.
local moving_left  = lurek.keyboard.isDown("left")  or lurek.keyboard.isDown("a")
local moving_right = lurek.keyboard.isDown("right") or lurek.keyboard.isDown("d")

-- Multiple keys in one call (logical OR)
local any_jump = lurek.keyboard.isDown("space", "up", "w")

-- Check by scancode (hardware position, layout-independent)
local sc_held = lurek.keyboard.isScancodeDown("scancode_a")

-- Key repeat (fires repeated keypressed events when held)
lurek.keyboard.setKeyRepeat(true)
local repeat_on = lurek.keyboard.hasKeyRepeat()

-- Text input mode (enables lurek.textinput callback and IME composition)
lurek.keyboard.setTextInput(true)   -- call before showing a text field
lurek.keyboard.setTextInput(false)  -- call when the text field loses focus
local text_on = lurek.keyboard.hasTextInput()

-- Translate between key name and scancode
local sc  = lurek.keyboard.getScancodeFromKey("a")   -- → "scancode_a"
local key = lurek.keyboard.getKeyFromScancode(sc)     -- → "a"

-- Check modifier keys (returns true while held)
-- modifiers: "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt", "lgui", "rgui"
local shifted = lurek.keyboard.isModifierActive("lshift")

-- ── Callback examples ────────────────────────────────────────────────────────

function lurek.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        lurek.signal.quit()
    end
    if key == "f" and not isrepeat then
        lurek.window.setFullscreen(not lurek.window.getFullscreen())
    end
end

function lurek.keyreleased(key, scancode)
    -- key was just released
end

function lurek.textinput(text)
    -- UTF-8 text entered (after lurek.keyboard.setTextInput(true))
    -- Use this for typing in text fields; do NOT use keypressed for text input.
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Mouse — lurek.mouse
-- ─────────────────────────────────────────────────────────────────────────────

-- Current cursor position relative to window (in virtual pixels)
local mx, my = lurek.mouse.getPosition()
local x = lurek.mouse.getX()
local y = lurek.mouse.getY()

-- Check if a button is held (1=left, 2=right, 3=middle)
local left_held  = lurek.mouse.isDown(1)
local right_held = lurek.mouse.isDown(2)
local mid_held   = lurek.mouse.isDown(3)

-- Show / hide the system cursor
lurek.mouse.setVisible(false)   -- hide when drawing a custom cursor
local visible = lurek.mouse.isVisible()

-- Constrain cursor to window (grab)
lurek.mouse.setGrabbed(true)
local grabbed = lurek.mouse.isGrabbed()

-- Relative (FPS) mode: raw delta, cursor stays hidden and centred
lurek.mouse.setRelativeMode(true)
local rel = lurek.mouse.getRelativeMode()

-- Warp the cursor to a position
lurek.mouse.setPosition(400, 300)

-- Scroll wheel delta since last frame (use inside lurek.process or in lurek.wheelmoved)
local sx, sy = lurek.mouse.getWheelDelta()  -- sy > 0 = scrolled up

-- ── Custom cursors ────────────────────────────────────────────────────────────

-- Create a cursor from an ImageData (pixel grid), with a hotspot offset
local img_data = lurek.img.newImageData("cursor.png")
local custom_cursor = lurek.mouse.newCursor(img_data, 32, 32, 0, 0)

-- Load a built-in OS cursor by name
-- names: "arrow", "ibeam", "wait", "crosshair", "sizenwse", "sizenesw",
"sizewe", "sizens", "sizeall", "no", "hand"
local arrow    = lurek.mouse.getSystemCursor("arrow")
local hand     = lurek.mouse.getSystemCursor("hand")
local ibeam    = lurek.mouse.getSystemCursor("ibeam")

-- Activate a cursor object
lurek.mouse.setCursor(arrow)

-- Get the current active cursor
local current = lurek.mouse.getCursor()

-- Check if the platform supports custom cursors at all
local supported = lurek.mouse.isCursorSupported()

-- ── Callback examples ────────────────────────────────────────────────────────

function lurek.mousepressed(x, y, button, istouch, presses)
    -- presses = consecutive click count (2 = double-click)
    if button == 1 then
        print("left click at", x, y, "(clicks:", presses, ")")
    end
end

function lurek.mousereleased(x, y, button, istouch, presses)
    -- button just released
end

function lurek.mousemoved(x, y, dx, dy, istouch)
    -- dx, dy: delta from previous position
end

function lurek.wheelmoved(x, y)
    -- y > 0 = scroll up; y < 0 = scroll down; x = horizontal scroll
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Gamepad — lurek.gamepad
-- ─────────────────────────────────────────────────────────────────────────────

-- Total number of connected gamepads
local n = lurek.gamepad.getCount()

-- Get all connected joystick IDs as a table
local ids = lurek.gamepad.getJoysticks()  -- e.g. {1, 2}

-- Check if specific ID is still connected
local ok = lurek.gamepad.isConnected(1)

-- Device name (platform string, e.g. "Xbox Controller")
local name = lurek.gamepad.getName(1)

-- Button held — button name strings:
-- "a", "b", "x", "y", "back", "guide", "start",
-- "leftstick", "rightstick", "leftshoulder", "rightshoulder",
-- "dpup", "dpdown", "dpleft", "dpright", "misc1"
local jump    = lurek.gamepad.isDown(1, "a")
local sprint  = lurek.gamepad.isDown(1, "rightshoulder")
local picking = lurek.gamepad.isDown(1, "x")

-- Axis value in [-1, 1]
-- axes: "leftx", "lefty", "rightx", "righty", "triggerleft", "triggerright"
local lx = lurek.gamepad.getAxis(1, "leftx")   -- left stick horizontal
local ly = lurek.gamepad.getAxis(1, "lefty")   -- left stick vertical (+ = down)
local rx = lurek.gamepad.getAxis(1, "rightx")  -- right stick horizontal
local ry = lurek.gamepad.getAxis(1, "righty")  -- right stick vertical
local lt = lurek.gamepad.getAxis(1, "triggerleft")   -- left trigger  [0, 1]
local rt = lurek.gamepad.getAxis(1, "triggerright")  -- right trigger [0, 1]

-- Apply a dead zone manually (values below threshold treated as zero)
local DEAD_ZONE = 0.15
local move_x = math.abs(lx) > DEAD_ZONE and lx or 0.0
local move_y = math.abs(ly) > DEAD_ZONE and ly or 0.0

-- ── Callback examples ────────────────────────────────────────────────────────

function lurek.gamepadpressed(id, button)
    print("gamepad", id, "pressed", button)
end

function lurek.gamepadreleased(id, button)
    print("gamepad", id, "released", button)
end

function lurek.gamepadaxis(id, axis, value)
    -- fires when any axis crosses a threshold
end

function lurek.joystickadded(id)
    print("gamepad connected:", id)
end

function lurek.joystickremoved(id)
    print("gamepad disconnected:", id)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Touch — lurek.touch
-- ─────────────────────────────────────────────────────────────────────────────

-- Get all active touch points as a list
-- Each touch: {id, x, y, dx, dy, pressure}
local touches = lurek.touch.getTouches()
for _, touch in ipairs(touches) do
    local tid      = touch.id
    local tx, ty   = touch.x, touch.y
    local dxtd     = touch.dx
    local dydir    = touch.dy
    local pressure = touch.pressure  -- 0–1
end

-- Get a specific touch by ID (nil if not active)
local t = lurek.touch.getTouch(1)

-- ── Callback examples ────────────────────────────────────────────────────────

function lurek.touchpressed(id, x, y, dx, dy, pressure)
    print("finger down:", id, x, y)
end

function lurek.touchmoved(id, x, y, dx, dy, pressure)
    -- finger dragged
end

function lurek.touchreleased(id, x, y, dx, dy, pressure)
    print("finger up:", id)
end

-- ─── Cursor ────────────────────────────────────────────────────────────────────

local type_val = cursor:getType()  -- Returns the cursor type as "system" or "custom"
cursor:release()  -- Releases the cursor resource (no-op on desktop)

-- ─── lurek.input ────────────────────────────────────────────────────────────────
local axis_count = lurek.input.getAxisCount(1)  -- Returns the total number of analog axes on the gamepad
local background_events = lurek.input.getBackgroundEvents()  -- Returns whether background gamepad events are enabled
local button_count = lurek.input.getButtonCount(1)  -- Returns the total number of buttons on the gamepad
local g_u_i_d = lurek.input.getGUID(1)  -- Returns the hardware GUID string of the gamepad
local gamepad_mapping_string = lurek.input.getGamepadMappingString("01000000...")  -- Returns stored mappingpping string for the given GUID, or nil
local hat = lurek.input.getHat(1, 1)  -- Returns the direction string of a hat switch on the gamepad
local joystick_count = lurek.input.getJoystickCount()  -- Returns the number of tracked gamepad slots
local pressure = lurek.input.getPressure(1)  -- Returns the pressure (0-1) of the touch with the given ID
local touch_count = lurek.input.getTouchCount()  -- Returns the number of currently active touch points
local is_gamepad = lurek.input.isGamepad(1)  -- Returns whether the joystick at the given slot is a recognized gamepad
local is_vibration_supported = lurek.input.isVibrationSupported(1)  -- Returns whether the gamepad supports haptic vibration
local load_gamepad_mappings = lurek.input.loadGamepadMappings("path/to/file")  -- Loads SDL2 GameControllerDB-format mappings from a file
lurek.input.saveGamepadMappings("path/to/file")  -- Saves all stored gamepad mappings to a plain-text file
lurek.input.setBackgroundEvents(false)  -- Enable or disable receiving gamepad events when the window is not focused
lurek.input.setGamepadMapping("gamepad_guid", sdl_mapping_string)  -- Stores or replaces a GameControllerDB mappinging string for the given GUID
local set_vibration = lurek.input.setVibration(any)  -- Triggers haptic rumble (currently a no-op stub)
