# `input` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.keyboard`, `luna.mouse`, `luna.gamepad`, `luna.touch` |
| **Source**     | `src/input/`                                         |
| **Rust Tests** | `tests/rust/unit/input_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_input.lua`                      |
| **Architecture** | —                                                  |

## Summary

The input module is Luna2D's Tier 1 device-state tracking layer. It converts raw OS events from winit (keyboard, mouse) and gilrs (gamepads) into clean, per-frame snapshot state that game scripts query through four Lua namespaces: `luna.keyboard`, `luna.mouse`, `luna.gamepad`, and `luna.touch`. Rather than exposing asynchronous event streams that can be missed if not polled in the right window, the module presents three stable views for every device: "just pressed this frame", "currently held", and "just released this frame". Transient per-frame state (pressed/released lists, scroll deltas, text input buffer) is cleared at the start of each frame by `begin_frame()`, so game scripts in `luna.update(dt)` always see a consistent snapshot.

The keyboard subsystem maps winit logical `Key` values and physical `KeyCode` scancodes to lowercase Luna key-name strings (`"space"`, `"left"`, `"a"`, `"f1"`), making Lua condition checks human-readable. It tracks modifier state via a bitmask (`MOD_SHIFT`, `MOD_CTRL`, `MOD_ALT`, `MOD_META`) and supports key-repeat and text-input (IME) toggling. The mouse subsystem tracks window-space cursor position, five buttons (left, right, middle, back, forward), scroll wheel deltas, cursor visibility/grab/relative-mode, system cursor shape (11 variants), and custom RGBA cursors via the `CursorHandle`/`CursorKind` types. The gamepad subsystem supports up to 16 controllers via gilrs, with per-gamepad button/axis state, hat/d-pad direction queries, GUID metadata, and SDL2 GameControllerDB mapping persistence. The touch subsystem tracks active fingers by OS-assigned ID with position and pressure.

This module intentionally does NOT own event dispatch — `engine/app.rs` processes winit/gilrs events and calls into input state setters. The module also does not process world-space transformations; mouse position is in window-space logical pixels.

## Architecture

```
winit WindowEvent / gilrs events
         |
         v
  engine/app.rs  -- event dispatch loop
         |
    +----+----------------+------------------+---------------+
    v                     v                  v               v
KeyboardState        MouseState        GamepadState [0..16]  TouchState
|- keys_down (Set)   |- x, y           |- buttons (Map)     |- touches (Map)
|- keys_pressed      |- buttons [5]    |- axes (Map)        |   +- TouchPoint
|- keys_released     |- pressed [5]    |- id, name, guid    |       (id,x,y,pressure)
|- scancodes_down    |- released [5]   |- connected         +- touch_start/move/end
|- scancodes_pressed |- scroll_x/y     |- get_hat()
|- scancodes_released|- visible/grabbed +- update_button/axis
|- modifiers (u8)    |- relative_mode
|- text_input_buffer |- cursor_type       GamepadMappings
|- key_repeat_enabled|  (SystemCursor)    |- set_mapping()
+- begin_frame()     |- CursorHandle      |- get_mapping_string()
                     |  +- CursorKind     |- load_from_file()
                     +- begin_frame()     +- save_to_file()
         |
         v
  src/lua_api/input_api.rs
  |- luna.keyboard.*  (9 functions)
  |- luna.mouse.*     (17 functions + LuaCursor userdata)
  |- luna.gamepad.*   (20 functions)
  +- luna.touch.*     (4 functions)
```

## Source Files

| File          | Purpose                                                              |
|---------------|----------------------------------------------------------------------|
| `keyboard.rs` | `KeyboardState` — key/scancode tracking, modifier bitmask, text input, winit key-name mapping |
| `mouse.rs`    | `MouseState` — cursor position, 5-button state, scroll, visibility/grab/relative mode; `SystemCursor`, `CursorKind`, `CursorHandle` |
| `gamepad.rs`  | `GamepadState` — per-controller button/axis state, hat/d-pad, GUID; `GamepadMappings` — SDL2 GameControllerDB persistence; gilrs conversion helpers |
| `touch.rs`    | `TouchPoint`, `TouchState` — multitouch tracking by OS-assigned touch ID |

## Submodules

### `input::keyboard`

Keyboard state tracking with logical key names and physical scancodes.

- **`KeyboardState`** (struct) — Tracks held/pressed/released keys, scancodes, modifier bitmask, key-repeat, and text-input (IME) buffer. Provides `begin_frame()` to clear transient state.
- **`MOD_SHIFT`** (const) — Bitmask `0b0001` for the Shift modifier.
- **`MOD_CTRL`** (const) — Bitmask `0b0010` for the Control modifier.
- **`MOD_ALT`** (const) — Bitmask `0b0100` for the Alt/Option modifier.
- **`MOD_META`** (const) — Bitmask `0b1000` for the Super/Meta modifier.
- **`winit_key_to_string()`** (fn) — Converts a winit 0.30 logical `Key` to a lowercase Luna key-name string.
- **`winit_scancode_to_string()`** (fn) — Converts a winit 0.30 physical `KeyCode` to a layout-independent scancode string.

### `input::mouse`

Mouse cursor position, button state, scroll, and cursor management.

- **`MouseState`** (struct) — Tracks cursor position `(x, y)`, five buttons (left/right/middle/back/forward) with pressed/released transient flags, scroll deltas, visibility, grab, relative mode, and system cursor shape.
- **`SystemCursor`** (enum) — 11 standard system cursor shapes: `Arrow`, `IBeam`, `Wait`, `Crosshair`, `Hand`, `SizeNWSE`, `SizeNESW`, `SizeWE`, `SizeNS`, `SizeAll`, `No`.
- **`CursorKind`** (enum) — Either a `System(SystemCursor)` or `Custom { pixels, width, height, hotx, hoty }` cursor.
- **`CursorHandle`** (struct) — Wraps a `CursorKind` for passing between engine and Lua.
- **`is_cursor_supported()`** (fn) — Returns `true` on desktop (always).

### `input::gamepad`

Per-controller button/axis state and SDL2 GameControllerDB mapping persistence.

- **`GamepadState`** (struct) — Holds button (`HashMap<u32, bool>`) and axis (`HashMap<u32, f32>`) state for a single gamepad. Also stores `id`, `name`, `guid`, and `connected` status. Provides `get_hat()` for d-pad direction strings.
- **`GamepadMappings`** (struct) — GUID-keyed dictionary of SDL2 GameControllerDB mapping strings. Supports `load_from_file()` and `save_to_file()` for persistence.
- **`gilrs_button_to_string()`** (fn) — Converts a `gilrs::Button` to an engine-compatible string name (e.g. `"a"`, `"leftshoulder"`, `"dpup"`).
- **`gilrs_axis_to_string()`** (fn) — Converts a `gilrs::Axis` to an engine-compatible string name (e.g. `"leftx"`, `"triggerleft"`).

### `input::touch`

Multitouch tracking by OS-assigned touch ID.

- **`TouchPoint`** (struct) — A single touch: `id` (u64), `x`, `y` (f64), `pressure` (f64).
- **`TouchState`** (struct) — Tracks active `TouchPoint` entries in a `HashMap<u64, TouchPoint>`. Manages `touch_start`, `touch_move`, `touch_end` lifecycle.

## Key Types

### Structs

#### `input::keyboard::KeyboardState`

Tracks which keyboard keys are currently down, just pressed, or just released. Also tracks physical scancodes, modifier key bitmask, key repeat, and text input (IME) state. Fields: `keys_down` (HashSet), `keys_pressed`/`keys_released` (Vec), `scancodes_down` (HashSet), `scancodes_pressed`/`scancodes_released` (Vec), `modifiers` (u8 bitmask), `key_repeat_enabled`, `text_input_enabled`, `text_input_buffer`.

#### `input::mouse::MouseState`

Tracks mouse cursor position and per-button pressed/down/released state. Supports five buttons (0=left, 1=right, 2=middle, 3=back, 4=forward). Fields: `x`, `y` (f32), `buttons`/`buttons_pressed`/`buttons_released` ([bool; 5]), `visible`, `grabbed`, `relative_mode`, `scroll_x`/`scroll_y` (f64), `cursor_type` (SystemCursor), `pending_position`.

#### `input::mouse::CursorHandle`

A held cursor — either a system cursor icon or custom pixel-data cursor. Contains a `kind: CursorKind` field.

#### `input::gamepad::GamepadState`

Holds the current button and axis state for a single gamepad identified by its `id`. Public fields: `id` (u32), `name` (String), `connected` (bool). Private: `guid`, `buttons` (HashMap), `axes` (HashMap). Provides `get_hat()` for d-pad direction as a one-or-two-character string.

#### `input::gamepad::GamepadMappings`

Stores SDL2 GameControllerDB-format mapping strings keyed by GUID. Provides `set_mapping()`, `get_mapping_string()`, `load_from_file()` (reads a plain-text DB file), and `save_to_file()` (writes all entries).

#### `input::touch::TouchPoint`

Information about a single touch point. Fields: `id` (u64), `x` (f64), `y` (f64), `pressure` (f64).

#### `input::touch::TouchState`

Tracks active touch points in a `HashMap<u64, TouchPoint>`. Lifecycle: `touch_start()`, `touch_move()`, `touch_end()`. Queries: `get_touches()`, `get_touch()`, `get_touch_count()`.

### Enums

#### `input::mouse::SystemCursor`

Standard system cursor shapes with 11 variants: `Arrow` (default), `IBeam`, `Wait`, `Crosshair`, `Hand`, `SizeNWSE`, `SizeNESW`, `SizeWE`, `SizeNS`, `SizeAll`, `No`. Provides `from_name(&str)` (unrecognized names default to `Arrow`) and `as_str()`.

#### `input::mouse::CursorKind`

The cursor type — either `System(SystemCursor)` for a named OS cursor, or `Custom { pixels, width, height, hotx, hoty }` for an RGBA pixel-data cursor.

## Lua API

Registered by `src/lua_api/input_api.rs` across four namespaces. The file also defines the `LuaCursor` UserData type for cursor objects.

### `luna.keyboard`

| Function | Signature | Description |
|----------|-----------|-------------|
| `isDown` | `(keys: string...) -> boolean` | Returns `true` if any of the given keys is currently held down |
| `isScancodeDown` | `(scancode: string) -> boolean` | Returns whether the key with the given physical scancode is held |
| `setKeyRepeat` | `(enabled: boolean) -> nil` | Enables or disables key-repeat events |
| `hasKeyRepeat` | `() -> boolean` | Returns whether key-repeat is currently enabled |
| `setTextInput` | `(enabled: boolean) -> nil` | Enables or disables Unicode text input mode (IME) |
| `hasTextInput` | `() -> boolean` | Returns whether text input mode is currently active |
| `getScancodeFromKey` | `(key: string) -> string?` | Returns the hardware scancode for the given key name |
| `getKeyFromScancode` | `(scancode: string) -> string?` | Returns the key name for the given hardware scancode |
| `isModifierActive` | `(modifier: string) -> boolean` | Returns whether a modifier key is held (`"shift"`, `"ctrl"`, `"alt"`, `"meta"`, `"super"`) |

### `luna.mouse`

| Function | Signature | Description |
|----------|-----------|-------------|
| `getPosition` | `() -> number, number` | Returns the current cursor position as (x, y) |
| `getX` | `() -> number` | Returns the current mouse X position |
| `getY` | `() -> number` | Returns the current mouse Y position |
| `isDown` | `(button: integer) -> boolean` | Returns whether a mouse button is held (1=left, 2=right, 3=middle, 4=back, 5=forward) |
| `setVisible` | `(visible: boolean) -> nil` | Shows or hides the OS mouse cursor |
| `isVisible` | `() -> boolean` | Returns whether the mouse cursor is visible |
| `setGrabbed` | `(grabbed: boolean) -> nil` | Locks or unlocks the cursor to the window |
| `isGrabbed` | `() -> boolean` | Returns whether the cursor is locked to the window |
| `setRelativeMode` | `(relative: boolean) -> nil` | Enables or disables raw relative mouse motion mode |
| `getRelativeMode` | `() -> boolean` | Returns whether relative mouse mode is active |
| `setPosition` | `(x: number, y: number) -> nil` | Moves the cursor to the given window-space position |
| `setCursor` | `(cursor: Cursor/string/nil) -> nil` | Sets the active cursor from a Cursor handle, name string, or nil to reset |
| `newCursor` | `(pixels, w, h, hotx?, hoty?) -> Cursor` | Creates a custom cursor from RGBA pixel data |
| `getSystemCursor` | `(name: string) -> Cursor` | Returns a system cursor object for the named shape |
| `isCursorSupported` | `() -> boolean` | Returns whether cursor customisation is supported |
| `getCursor` | `() -> string` | Returns the name of the currently active system cursor |
| `getWheelDelta` | `() -> number, number` | Returns scroll wheel delta (dx, dy) since last frame |

### `luna.gamepad`

| Function | Signature | Description |
|----------|-----------|-------------|
| `getCount` | `() -> integer` | Returns the number of connected gamepads |
| `getJoystickCount` | `() -> integer` | Returns the number of tracked gamepad slots |
| `getJoysticks` | `() -> table` | Returns a list of connected gamepad IDs |
| `isConnected` | `(id: integer) -> boolean` | Returns whether the gamepad is connected |
| `getName` | `(id: integer) -> string` | Returns the human-readable gamepad name |
| `isGamepad` | `(id: integer) -> boolean` | Returns whether the slot is a recognized gamepad |
| `getButtonCount` | `(id: integer) -> integer` | Returns the number of buttons on the gamepad |
| `getAxisCount` | `(id: integer) -> integer` | Returns the number of analog axes |
| `isDown` | `(id: integer, button: integer) -> boolean` | Returns whether the button is held |
| `getAxis` | `(id: integer, axis: integer) -> number` | Returns the axis value (-1 to 1) |
| `isVibrationSupported` | `(id: integer) -> boolean` | Returns whether haptic vibration is supported (stub, always false) |
| `getGUID` | `(id: integer) -> string` | Returns the hardware GUID string |
| `getHat` | `(id: integer, hat: integer) -> string` | Returns the d-pad hat direction string |
| `setVibration` | `(args...) -> boolean` | Triggers haptic rumble (stub, always false) |
| `setBackgroundEvents` | `(enable: boolean) -> nil` | Enable or disable gamepad events when window is unfocused |
| `getBackgroundEvents` | `() -> boolean` | Returns whether background gamepad events are enabled |
| `setGamepadMapping` | `(guid: string, mapping: string) -> nil` | Stores an SDL2 GameControllerDB mapping string |
| `getGamepadMappingString` | `(guid: string) -> string?` | Returns the stored mapping for the GUID |
| `loadGamepadMappings` | `(path: string) -> integer` | Loads mappings from a GameControllerDB file |
| `saveGamepadMappings` | `(path: string) -> nil` | Saves all stored mappings to a file |

### `luna.touch`

| Function | Signature | Description |
|----------|-----------|-------------|
| `getTouches` | `() -> table` | Returns a table of active touch points with id, x, y, pressure |
| `getPosition` | `(id: integer) -> number, number` | Returns the position of the touch with the given ID |
| `getPressure` | `(id: integer) -> number` | Returns the pressure (0-1) of the touch |
| `getTouchCount` | `() -> integer` | Returns the number of active touch points |

### UserData: `LuaCursor`

Returned by `luna.mouse.newCursor()` and `luna.mouse.getSystemCursor()`.

| Method | Signature | Description |
|--------|-----------|-------------|
| `release` | `() -> nil` | Releases the cursor resource (no-op on desktop) |
| `getType` | `() -> string` | Returns `"system"` or `"custom"` |

## Lua Examples

```lua
-- Movement with keyboard + mouse aiming
function luna.update(dt)
    -- Keyboard movement with modifier check
    local speed = 200
    if luna.keyboard.isModifierActive("shift") then
        speed = 400
    end
    if luna.keyboard.isDown("left", "a") then
        player_x = player_x - speed * dt
    end
    if luna.keyboard.isDown("right", "d") then
        player_x = player_x + speed * dt
    end

    -- Mouse position and clicks
    local mx, my = luna.mouse.getPosition()
    if luna.mouse.isDown(1) then
        shoot(mx, my)
    end

    -- Scroll wheel zoom
    local _, sy = luna.mouse.getWheelDelta()
    if sy ~= 0 then
        zoom = zoom + sy * 0.1
    end
end

function luna.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        luna.event.push("quit")
    end
    if key == "f" then
        luna.mouse.setRelativeMode(not luna.mouse.getRelativeMode())
    end
end

-- Gamepad support
function luna.gamepadpressed(id, button)
    if button == "a" then
        player_jump()
    end
end

function luna.gamepadaxis(id, axis, value)
    if axis == "leftx" then
        player_vx = value * 200
    end
end

-- Custom cursor
function luna.load()
    local hand = luna.mouse.getSystemCursor("hand")
    luna.mouse.setCursor(hand)
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 7     |
| `enum`     | 2     |
| `const`    | 4     |
| `fn`       | 62    |
| `mod`      | 4     |
| **Total**  | **79** |

## References

| Module       | Relationship  | Notes                                                         |
|--------------|---------------|---------------------------------------------------------------|
| `math`       | Imports from  | Leaf module; no direct import but types like Vec2 are used in the broader input pipeline |
| `engine`     | Imports from  | Uses `SharedState` (keyboard, mouse, gamepads, touch fields), `EngineError`, log message constants |
| `event`      | Related       | `input` delivers hardware events; `event` is a user-level queue |
| `automation` | Related       | `automation` can record/replay the events delivered by `input` |
| `window`     | Related       | Window focus/visibility state affects input delivery           |
| `lua_api`    | Imported by   | `src/lua_api/input_api.rs` registers `luna.keyboard.*`, `luna.mouse.*`, `luna.gamepad.*`, `luna.touch.*` |

## Notes

- **Key names** follow lowercase ASCII: `"space"`, `"escape"`, `"a"`, `"left"`, `"f1"`. Unknown keys are silently skipped by `winit_key_to_string()`.
- **Scancodes** are physical key positions, layout-independent. `winit_scancode_to_string()` maps `KeyCode` variants to strings like `"lshift"`, `"kp+"`.
- **Modifier bitmask** uses four constants (`MOD_SHIFT`, `MOD_CTRL`, `MOD_ALT`, `MOD_META`). Modifiers are set by `engine/app.rs` via `set_modifiers()` on each `KeyboardInput` event.
- **Frame lifecycle**: `begin_frame()` must be called at the start of each frame on `KeyboardState` and `MouseState` to clear transient state (pressed/released lists, scroll deltas, text input buffer).
- **Mouse button indices** in Lua are 1-based (1=left, 2=right, 3=middle, 4=back, 5=forward); Rust uses 0-based. The Lua binding applies `saturating_sub(1)`.
- **Mouse position** is in logical pixels (DPI-unscaled). Multiply by `luna.window.getDPIScale()` for physical pixels.
- **Gamepad IDs** start from 0 and may be sparse if controllers are disconnected mid-session. Up to 16 gamepads are tracked.
- **Gamepad mapping persistence** uses SDL2 GameControllerDB format. `loadGamepadMappings()` reads a text file, `saveGamepadMappings()` writes one.
- **Touch events** mirror mouse events for single-touch scenarios for cross-platform compatibility.
- **Cursor support**: `is_cursor_supported()` always returns `true` on desktop. Custom cursors via `newCursor()` store RGBA pixel data but the actual winit cursor update is handled in `engine/app.rs`.
- **Vibration**: `setVibration()` and `isVibrationSupported()` are stubs that always return `false` — gilrs does not expose rumble on all platforms.
- **External crate versions**: winit 0.30 (keyboard/mouse/touch events), gilrs 0.11 (gamepad events).
- **Breaking change surface**: Renaming key-name strings or changing button indices would break all Lua scripts that use string comparisons in `luna.keypressed` callbacks.
