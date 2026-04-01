# `src/input/` — Keyboard, Mouse, Gamepad, and Touch Input

## Purpose

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

### How It Works

Input state is double-buffered each frame: `begin_frame()` copies the
"current-frame pressed/released" bitmask into the "previous-frame" slot and
clears the current slot; then as winit events arrive, `key_pressed(key)` and
`key_released(key)` set bits in the current slot.  This ensures that a key
pressed and released between two consecutive `update()` ticks is still
visible as "pressed this frame" in the Lua callback — no input events are
silently dropped.

Gamepad state is polled from `gilrs::Gilrs::next_event()` at the start of each
frame before the Lua callback fires.  Dead zones are configurable per-axis
(`set_dead_zone`) and are applied by clamping values within ±dead_zone to 0.0
before they reach Lua.  Newly connected and disconnected gamepads trigger
`luna.gamepadconnected` and `luna.gamepaddisconnected` callbacks in the next
frame's event phase.

Scancodes are exposed alongside key names for the rare cases (rhythm games,
multimedia keys) where the physical position of a key matters more than its
label.  `getScancodes()` returns a table of currently-held scancode integers
that Lua can compare against `luna.keyboard.scancode_for("a")` etc.

### Dependency Direction

```
input/ ──────► (none — uses winit + gilrs types for conversion only)
```

**Leaf module** — no Luna2D module dependencies. Free functions convert between
winit/gilrs key/button types and Luna2D string names.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `GamepadState`, `KeyboardState`, `MouseState`, `SystemCursor`,
`TouchPoint`, `TouchState`, and conversion functions.

**~17 lines** — re-exports.

---

### `keyboard.rs` — `KeyboardState`

**~425+ lines** | Full keyboard state tracking with scancode support.

#### Struct: `KeyboardState`

```rust
pub struct KeyboardState {
    keys_down: HashSet<String>,           // currently held keys
    keys_pressed: Vec<String>,            // pressed this frame (transient)
    keys_released: Vec<String>,           // released this frame (transient)
    scancodes_down: HashSet<u32>,
    scancodes_pressed: Vec<u32>,
    scancodes_released: Vec<u32>,
    key_repeat_enabled: bool,
    text_input_enabled: bool,
    text_input_buffer: Vec<String>,
}
```

#### Frame Lifecycle

| Method | When Called | Purpose |
|--------|-----------|---------|
| `begin_frame()` | Start of each frame | Clears pressed/released/text buffers |
| `set_key_down(key)` | On key press event | Adds to down + pressed |
| `set_key_up(key)` | On key release event | Removes from down + adds to released |

#### Query Methods

| Method | Returns |
|--------|---------|
| `is_down(key)` | `bool` — currently held |
| `get_pressed()` | `&[String]` — pressed this frame |
| `get_released()` | `&[String]` — released this frame |
| `is_scancode_down(code)` | `bool` |
| `get_text_input()` | `&[String]` — text input characters |

#### Conversion Functions (free)

| Function | Purpose |
|----------|---------|
| `winit_key_to_string(key)` | winit `Key` → Luna2D string name |
| `winit_scancode_to_string(code)` | winit scancode → string |
| `get_scancode_from_key(key)` | Key name → scancode |
| `get_key_from_scancode(code)` | Scancode → key name |

**Design**: Dual tracking (logical keys + scancodes) supports both layout-dependent
(WASD) and layout-independent (scancode) input patterns.

---

### `mouse.rs` — `MouseState`

**~300+ lines** | Mouse position, buttons, scroll, and cursor management.

#### Enum: `SystemCursor` (11 variants)

```
Arrow | IBeam | Wait | Crosshair | Hand |
SizeNWSE | SizeNESW | SizeWE | SizeNS | SizeAll | No
```

#### Struct: `MouseState`

```rust
pub struct MouseState {
    x: f32,
    y: f32,
    buttons: [bool; 5],           // currently down
    pressed: [bool; 5],           // pressed this frame
    released: [bool; 5],          // released this frame
    visible: bool,
    grabbed: bool,
    relative_mode: bool,
    scroll_x: f32,
    scroll_y: f32,
    cursor_type: SystemCursor,
    pending_position: Option<(f32, f32)>,
}
```

#### Methods

| Method | Purpose |
|--------|---------|
| `begin_frame()` | Clear per-frame state (pressed/released/scroll) |
| `update_position(x, y)` | Update cursor position |
| `set_button(btn, down)` | Press or release button (0–4) |
| `is_down(btn)` | Check if button is currently held |
| `get_position()` | `(f32, f32)` cursor position |
| `set_visible(bool)` | Show/hide system cursor |
| `set_grabbed(bool)` | Confine cursor to window |
| `set_relative_mode(bool)` | Raw delta mode |
| `accumulate_scroll(dx, dy)` | Accumulate scroll per frame |
| `get_scroll()` | `(f32, f32)` accumulated scroll |
| `set_cursor(SystemCursor)` | Change cursor appearance |
| `request_position(x, y)` | Move cursor (pending until applied) |

---

### `gamepad.rs` — `GamepadState`

**~200+ lines** | Per-gamepad state with button/axis tracking and gilrs integration.

#### Struct: `GamepadState`

```rust
pub struct GamepadState {
    id: u32,
    name: String,
    connected: bool,
    guid: Option<String>,
    buttons: HashMap<u32, bool>,
    axes: HashMap<u32, f32>,
}
```

#### Methods

| Method | Purpose |
|--------|---------|
| `update_button(id, pressed)` | Set button state |
| `update_axis(id, value)` | Set axis value (-1.0 to 1.0) |
| `is_button_pressed(id)` | Check button state |
| `get_axis_value(id)` | Get axis value |
| `get_hat()` | D-pad direction from axes/buttons |
| `get_name()` / `is_connected()` | Metadata |

#### Conversion Functions (free)

| Function | Purpose |
|----------|---------|
| `gilrs_button_to_string(btn)` | gilrs button → Luna2D name |
| `gilrs_axis_to_string(axis)` | gilrs axis → Luna2D name |

---

### `touch.rs` — `TouchState` (Multitouch)

**~100+ lines** | Touch point tracking with pressure support.

#### Struct: `TouchPoint`

```rust
#[derive(Copy, Clone)]
pub struct TouchPoint {
    pub id: u64,
    pub x: f64,
    pub y: f64,
    pub pressure: f64,
}
```

#### Struct: `TouchState`

```rust
pub struct TouchState {
    touches: HashMap<u64, TouchPoint>,
}
```

Methods: `new`, `touch_start(id, x, y, pressure)`, `touch_move(id, x, y, pressure)`,
`touch_end(id)`, `get_touches()`, `get_touch(id)`, `get_touch_count()`.

---

## Cross-Cutting Concerns

### Thread Safety

All input types are single-threaded — winit delivers events on the main thread,
and input state is queried during the Lua `update()` callback.

### Lua Integration

The Lua bridge lives in `src/lua_api/input_api.rs` (~370 lines), exposing
functions across four namespaces: `luna.keyboard.*`, `luna.mouse.*`,
`luna.gamepad.*`, `luna.touch.*`.

### Usage from Lua

```lua
-- Keyboard
if luna.keyboard.isDown("space") then
    player:jump()
end

-- Mouse
local mx, my = luna.mouse.getPosition()
if luna.mouse.isDown(1) then
    shoot(mx, my)
end

-- Gamepad
if luna.gamepad.isDown(1, "a") then
    player:attack()
end
local lx = luna.gamepad.getAxis(1, "leftx")
```
