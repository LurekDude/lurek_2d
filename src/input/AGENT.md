# `input` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.input` |
| **Source** | `src/input/` |
| **Tests** | `tests/input_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_input.lua` |

## Summary

The input module tracks the state of all input devices between frames —
keyboard, mouse, up to 16 gamepads via `gilrs`, and multi-touch.  Rather than
exposing raw asynchronous OS events (which can be missed if not polled in the
right window), it presents a clean per-frame snapshot: each device state
provides "just pressed this frame", "currently held", and "just released this
frame" views that are stable for the entire duration of `luna.update(dt)`.

The keyboard state maps `winit` physical key codes to Luna key-name strings
(lowercase: `"space"`, `"left"`, `"a"`) at the winit-event boundary, making
Lua condition checks human-readable.  Mouse state includes both window-space
and world-space position (after applying the inverse camera transform), wheel
delta, and all five button states.  Touch state tracks each active finger by
its OS-assigned ID with position, delta between frames, and pressure, making
single-finger touch transparently visible through the mouse API for games
that do not distinguish touch from mouse input.

## Architecture

```
Input System
  │
  ├── KeyboardState ── key tracking with scancodes
  │     ├── Persistent: keys_down, scancodes_down (HashSet)
  │     ├── Transient: keys_pressed/released, scancodes_pressed/released (Vec)
  │     ├── Text input: buffer for IME/character input
  │     └── begin_frame() clears transient state
  │
  ├── MouseState ── position, buttons, scroll, cursor
  │     ├── Position: x, y (f32)
  │     ├── Buttons: [bool; 5] for down/pressed/released
  │     ├── Scroll: accumulated x, y per frame
  │     ├── Cursor: SystemCursor (11 variants), visibility, grab
  │     └── Relative mode: raw mouse delta without cursor
  │
  ├── GamepadState ── per-gamepad state
  │     ├── Buttons: HashMap<u32, bool>
  │     ├── Axes: HashMap<u32, f32>
  │     ├── Metadata: name, GUID, connected status
  │     └── Hat/d-pad: derived from axis/button state
  │
  └── TouchState ── multitouch tracking
        ├── Active touches: HashMap<u64, TouchPoint>
        ├── TouchPoint: id, x, y, pressure
        └── Lifecycle: touch_start / touch_move / touch_end
```

## Source Files

| File | Purpose |
|------|---------|
| `gamepad.rs` | Gamepad implementation for the `input` subsystem |
| `keyboard.rs` | Keyboard implementation for the `input` subsystem |
| `mouse.rs` | Mouse implementation for the `input` subsystem |
| `touch.rs` | Touch input state tracking for Luna2D |

## Submodules

### `input::gamepad`

Gamepad implementation for the `input` subsystem.

- **`GamepadState`** (struct): Holds the current button and axis state for a single gamepad identified by its id.
- **`gilrs_button_to_string`** (fn): Converts a `gilrs::Button` to a engine-compatible string name.
- **`gilrs_axis_to_string`** (fn): Converts a `gilrs::Axis` to a engine-compatible string name.

### `input::keyboard`

Keyboard implementation for the `input` subsystem.

- **`KeyboardState`** (struct): Tracks which keyboard keys are currently down, just pressed, or just released.  Also tracks physical scancodes, key...
- **`get_scancode_from_key`** (fn): Resolves a logical Luna key name to the closest physical scancode string.
- **`get_key_from_scancode`** (fn): Resolves a physical scancode string to the closest logical Luna key name.
- **`winit_key_to_string`** (fn): Converts a `winit 0.30` logical `Key` to the lowercase string name used by the `luna.*` API.  Returns `Some(name)` for...
- **`winit_scancode_to_string`** (fn): Converts a `winit 0.30` physical `KeyCode` to a engine-compatible scancode string.  Scancodes represent physical key...

### `input::mouse`

Mouse implementation for the `input` subsystem.

- **`SystemCursor`** (enum): Standard system cursor shapes. Consult the module-level documentation for the broader usage context and preconditions.
- **`MouseState`** (struct): Tracks mouse cursor position and per-button pressed/down/released state.

### `input::touch`

Touch input state tracking for Luna2D.

- **`TouchPoint`** (struct): Information about a single touch point. Consult the module-level documentation for the broader usage context and...
- **`TouchState`** (struct): Tracks active touch points. Consult the module-level documentation for the broader usage context and preconditions.

## Key Types

### Structs

#### `input::gamepad::GamepadState`

Holds the current button and axis state for a single gamepad identified by its id.

#### `input::keyboard::KeyboardState`

Tracks which keyboard keys are currently down, just pressed, or just released.  Also tracks physical scancodes, key...

#### `input::mouse::MouseState`

Tracks mouse cursor position and per-button pressed/down/released state.

#### `input::touch::TouchPoint`

Information about a single touch point. Consult the module-level documentation for the broader usage context and...

#### `input::touch::TouchState`

Tracks active touch points. Consult the module-level documentation for the broader usage context and preconditions.

### Enums

#### `input::mouse::SystemCursor`

Standard system cursor shapes. Consult the module-level documentation for the broader usage context and preconditions.

## Public Functions

- **`get_key_from_scancode()`** `keyboard::` — Resolves a physical scancode string to the closest logical Luna key name.
- **`get_scancode_from_key()`** `keyboard::` — Resolves a logical Luna key name to the closest physical scancode string.
- **`gilrs_axis_to_string()`** `gamepad::` — Converts a `gilrs::Axis` to a engine-compatible string name.
- **`gilrs_button_to_string()`** `gamepad::` — Converts a `gilrs::Button` to a engine-compatible string name.
- **`winit_key_to_string()`** `keyboard::` — Converts a `winit 0.30` logical `Key` to the lowercase string name used by the `luna.*` API.  Returns `Some(name)` for...
- **`winit_scancode_to_string()`** `keyboard::` — Converts a `winit 0.30` physical `KeyCode` to a engine-compatible scancode string.  Scancodes represent physical key...

## Lua API

Exposed under `luna.input.*` by `src/lua_api/input_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 1 |
| `fn` | 6 |
| `mod` | 4 |
| `struct` | 5 |
| **Total** | **16** |

