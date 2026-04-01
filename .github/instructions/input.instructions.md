---
applyTo: "src/input/**"
---

# Input Module Instructions

Rules for working on `src/input/` — keyboard, mouse, gamepad, and touch input.

## Module Rules

- Input state is **polled per frame** — `KeyboardState`, `MouseState`, `GamepadState`, `TouchState` update each frame
- Key names are **lowercase strings** (`"space"`, `"escape"`, `"a"`, `"left"`)
- Input events flow: winit event → engine/app.rs → InputState update → Lua callback dispatch
- gilrs handles gamepad hardware abstraction

## Key Types

- `KeyboardState` — tracks pressed/released keys, key-to-string mapping
- `MouseState` — position (x, y), button state, wheel delta
- `GamepadState` — per-gamepad button/axis state via gilrs
- `TouchState` — multi-touch tracking with id, position, pressure

## Dependency Direction

- `input` depends on `math` (Vec2 for positions)
- `input` must NOT depend on `graphics`, `physics`, `audio`, or `engine`
- `engine/app.rs` translates winit events into input state updates

## Callbacks

- `luna.keypressed(key)` / `luna.keyreleased(key)` — keyboard
- `luna.textinput(text)` — text input (character, not key)
- `luna.mousepressed(x, y, btn)` / `luna.mousereleased(x, y, btn)` — mouse buttons
- `luna.wheelmoved(x, y)` — mouse wheel
- `luna.gamepadpressed(id, btn)` / `luna.gamepadreleased(id, btn)` — gamepad buttons
- `luna.gamepadaxis(id, axis, val)` — gamepad axes
- `luna.joystickadded(id)` / `luna.joystickremoved(id)` — gamepad connect/disconnect
- `luna.touchpressed/touchmoved/touchreleased(id, x, y, dx, dy, pressure)` — touch

## Testing

- Tests in `tests/input_tests.rs`
- Test key name mapping, state transitions, gamepad count
- Touch tests verify record shape (id, x, y, pressure)
- Tests must be headless-safe — no actual window or input device required
