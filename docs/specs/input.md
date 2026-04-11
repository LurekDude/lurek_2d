# `input` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Platform Services |
| **Status** | Implemented |
| **Lua API** | `lurek.keyboard` |
| **Source** | `src/input/` |
| **Rust Tests** | `tests/rust/unit/input_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_input.lua`, `tests/lua/integration/test_input_camera.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Platform Services` |

---

## Summary

The input module is Lurek2D's device-state layer for keyboard, mouse, gamepad, and touch input. It stores per-frame snapshots that the rest of the engine and the Lua API can query synchronously instead of forcing scripts to consume raw OS event streams directly.

This module exists to turn noisy platform events into stable gameplay-facing state. `KeyboardState`, `MouseState`, `GamepadState`, and `TouchState` all keep track of what is currently down, what changed this frame, and any additional device-specific state such as scroll deltas, text input, cursor mode, gamepad mappings, or touch pressure.

It intentionally does not own event dispatch, world-space coordinate transforms, or platform window policy. The app loop receives winit and gilrs events and updates these structs, and the Lua bindings in `src/lua_api/input_api.rs` decide how that state is exposed under `lurek.keyboard`, `lurek.mouse`, `lurek.gamepad`, and `lurek.touch`. Input is a snapshot store, not an event bus.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.keyboard.* (Lua API — src/lua_api/input_api.rs)
    |
    v
src/input/mod.rs
    |- gamepad.rs - gamepad
    |- keyboard.rs - keyboard
    |- mouse.rs - mouse
    |- touch.rs - touch
```

---

## Source Files

| File | Purpose |
|------|---------|
| `gamepad.rs` | Gamepad implementation for the `input` subsystem. |
| `keyboard.rs` | Keyboard implementation for the `input` subsystem. |
| `mod.rs` | Mod implementation for the `input` subsystem. |
| `mouse.rs` | Mouse implementation for the `input` subsystem. |
| `touch.rs` | Touch input state tracking for Lurek2D. |

---

## Submodules

### `input::gamepad`

Gamepad implementation for the `input` subsystem.

- **`GamepadState`** (struct): Holds the current button and axis state for a single gamepad identified by its id.
- **`GamepadMappings`** (struct): Stores SDL2 GameControllerDB-format mapping strings keyed by GUID.

### `input::keyboard`

Keyboard implementation for the `input` subsystem.

- **`KeyboardState`** (struct): Tracks which keyboard keys are currently down, just pressed, or just released.

### `input::mouse`

Mouse implementation for the `input` subsystem.

- **`SystemCursor`** (enum): Standard OS cursor icon variants supported by the window backend.
- **`MouseState`** (struct): Tracks mouse cursor position and per-button pressed/down/released state.
- **`CursorKind`** (enum): The cursor type — either a named system icon or user-supplied pixel data.
- **`CursorHandle`** (struct): A held cursor — either a system cursor icon or custom pixel-data cursor.

### `input::touch`

Touch input state tracking for Lurek2D.

- **`TouchPoint`** (struct): Snapshot of one active touch point with its screen-space position and pressure.
- **`TouchState`** (struct): Tracks all active touch points by their winit-assigned finger ID.

---

## Key Types

### Public Types

#### `GamepadState`

Holds the current button and axis state for a single gamepad identified by its id.

#### `GamepadMappings`

Stores SDL2 GameControllerDB-format mapping strings keyed by GUID.

#### `KeyboardState`

Tracks which keyboard keys are currently down, just pressed, or just released.

#### `SystemCursor`

Standard OS cursor icon variants supported by the window backend.

#### `MouseState`

Tracks mouse cursor position and per-button pressed/down/released state.

#### `CursorKind`

The cursor type — either a named system icon or user-supplied pixel data.

#### `CursorHandle`

A held cursor — either a system cursor icon or custom pixel-data cursor.

#### `TouchPoint`

Snapshot of one active touch point with its screen-space position and pressure.

---

## Lua API

Exposed under `lurek.keyboard.*` by `src/lua_api/input_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.input.isDown` | Returns true if any of the given keys is currently held down. |
| `lurek.input.isScancodeDown` | Returns whether the key with the given scancode is held. |
| `lurek.input.setKeyRepeat` | Enables or disables key-repeat events. |
| `lurek.input.hasKeyRepeat` | Returns whether key-repeat is currently enabled. |
| `lurek.input.setTextInput` | Enables or disables Unicode text input mode. |
| `lurek.input.hasTextInput` | Returns whether text input mode is currently active. |
| `lurek.input.getScancodeFromKey` | Returns the hardware scancode for the given key name. |
| `lurek.input.getKeyFromScancode` | Returns the key name for the given hardware scancode. |
| `lurek.input.isModifierActive` | Returns whether the named modifier key is currently held. |
| `lurek.input.getPosition` | Returns the current cursor position as (x, y). |
| `lurek.input.getX` | Returns the current mouse X position in window coordinates. |
| `lurek.input.getY` | Returns the current mouse Y position in window coordinates. |
| `lurek.input.isDown` | Returns whether the given mouse button is currently held down. |
| `lurek.input.setVisible` | Shows or hides the operating-system mouse cursor. |
| `lurek.input.isVisible` | Returns whether the mouse cursor is currently visible. |
| `lurek.input.setGrabbed` | Locks or unlocks the mouse cursor to the window. |
| `lurek.input.isGrabbed` | Returns whether the mouse cursor is locked to the window. |
| `lurek.input.setRelativeMode` | Enables or disables raw relative mouse motion mode. |
| `lurek.input.getRelativeMode` | Returns whether relative mouse mode is active. |
| `lurek.input.setPosition` | Moves the mouse cursor to the given window-space position. |
| `lurek.input.setCursor` | Sets the active mouse cursor from a Cursor handle, name string, or nil to reset. |
| `lurek.input.newCursor` | Creates a custom mouse cursor from RGBA pixel data. |
| `lurek.input.getSystemCursor` | Returns a system cursor object for the named cursor shape. |
| `lurek.input.isCursorSupported` | Returns whether cursor customisation is supported on this platform. |
| `lurek.input.getCursor` | Returns the name of the currently active system cursor. |
| `lurek.input.getWheelDelta` | Returns the mouse scroll wheel delta (dx, dy) since last frame. |
| `lurek.input.getCount` | Returns the number of connected gamepads. |
| `lurek.input.getJoystickCount` | Returns the number of tracked gamepad slots. |
| `lurek.input.getJoysticks` | Returns a list of connected gamepad IDs. |
| `lurek.input.isConnected` | Returns whether the gamepad with the given ID is connected. |
| `lurek.input.getName` | Returns the human-readable name of a gamepad. |
| `lurek.input.isGamepad` | Returns whether the joystick at the given slot is a recognized gamepad. |
| `lurek.input.getButtonCount` | Returns the total number of buttons on the gamepad. |
| `lurek.input.getAxisCount` | Returns the total number of analog axes on the gamepad. |
| `lurek.input.isDown` | Returns whether the given button on the gamepad is currently held. |
| `lurek.input.getAxis` | Returns the current value (-1 to 1) of a gamepad analog axis. |
| `lurek.input.isVibrationSupported` | Returns whether the gamepad supports haptic vibration. |
| `lurek.input.getGUID` | Returns the hardware GUID string of the gamepad. |
| `lurek.input.getHat` | Returns the direction string of a hat switch on the gamepad. |
| `lurek.input.setVibration` | Triggers haptic rumble (currently a no-op stub). |
| `lurek.input.setBackgroundEvents` | Enable or disable receiving gamepad events when the window is not focused. |
| `lurek.input.getBackgroundEvents` | Returns whether background gamepad events are enabled. |
| `lurek.input.setGamepadMapping` | Stores or replaces the SDL2 GameControllerDB mapping string for the given GUID. |
| `lurek.input.getGamepadMappingString` | Returns the stored mapping string for the given GUID, or nil. |
| `lurek.input.loadGamepadMappings` | Loads SDL2 GameControllerDB-format mappings from a file. |
| `lurek.input.saveGamepadMappings` | Saves all stored gamepad mappings to a plain-text file. |
| `lurek.input.getTouches` | Returns a table of active touch points with id, x, y, and pressure fields. |
| `lurek.input.getPosition` | Returns the position (x, y) of the touch with the given ID. |
| `lurek.input.getPressure` | Returns the pressure (0-1) of the touch with the given ID. |
| `lurek.input.getTouchCount` | Returns the number of currently active touch points. |

### `Cursor` Methods

| Method | Description |
|--------|-------------|
| `cursor:release(...)` | Releases the cursor resource (no-op on desktop). |
| `cursor:getType(...)` | Returns the cursor type as "system" or "custom". |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.keyboard.
if lurek.keyboard then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 7 |
| `enum` | 2 |
| `fn` (Lua API) | 52 |
| **Total** | **61** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Platform Services to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/input/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
