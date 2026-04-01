# src/input/

Input handling for keyboard, mouse, gamepad, and touch devices.

## What This Module Contains

KeyboardState tracks key press/release with string key names. MouseState tracks position, buttons, scroll. GamepadState wraps gilrs for cross-platform gamepad support (buttons, axes, hotplug). TouchState tracks multi-touch with pressure.

## Files

| File | Purpose |
|------|---------|
| `gamepad.rs` | `Gamepad` implementation |
| `keyboard.rs` | `Keyboard` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `mouse.rs` | `Mouse` implementation |
| `touch.rs` | `Touch` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/input_tests.rs`
- **Lua API bindings**: `src/lua_api/input_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
