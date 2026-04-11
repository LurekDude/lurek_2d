# `input` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.keyboard`, `lurek.mouse`, `lurek.gamepad`, `lurek.touch` |
| **Source**     | `src/input/`                                         |
| **Rust Tests** | `tests/rust/unit/input_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_input.lua`                      |
| **Architecture** | —                                                  |

## Purpose

The input module is Lurek2D's Tier 1 device-state tracking layer. It converts raw OS events from winit (keyboard, mouse) and gilrs (gamepads) into clean, per-frame snapshot state that game scripts query through four Lua namespaces: `lurek.keyboard`, `lurek.mouse`, `lurek.gamepad`, and `lurek.touch`. Rather than exposing asynchronous event streams that can be missed if not polled in the right window, the module presents three stable views for every device: "just pressed this frame", "currently held", and "just released this frame". Transient per-frame state (pressed/released lists, scroll deltas, text input buffer) is cleared at the start of each frame by `begin_frame()`, so game scripts in `lurek.update(dt)` always see a consistent snapshot.

## Source Files

| File          | Purpose                                                              |
|---------------|----------------------------------------------------------------------|
| `keyboard.rs` | `KeyboardState` — key/scancode tracking, modifier bitmask, text input, winit key-name mapping |
| `mouse.rs`    | `MouseState` — cursor position, 5-button state, scroll, visibility/grab/relative mode; `SystemCursor`, `CursorKind`, `CursorHandle` |
| `gamepad.rs`  | `GamepadState` — per-controller button/axis state, hat/d-pad, GUID; `GamepadMappings` — SDL2 GameControllerDB persistence; gilrs conversion helpers |
| `touch.rs`    | `TouchPoint`, `TouchState` — multitouch tracking by OS-assigned touch ID |
| `mod.rs` | — |

## Key Types

| Type | Description |
|------|-------------|
| `GamepadState` | Principal type for the `input` module. |
| `GamepadMappings` | Principal type for the `input` module. |
| `KeyboardState` | Principal type for the `input` module. |
| `SystemCursor` | Principal type for the `input` module. |
| `MouseState` | Principal type for the `input` module. |
| `CursorKind` | Principal type for the `input` module. |
| `CursorHandle` | Principal type for the `input` module. |
| `TouchPoint` | Principal type for the `input` module. |
| `TouchState` | Principal type for the `input` module. |

## Lua API Summary

_No `lurek.*` bindings registered for this module._

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/input.md`](../../docs/specs/input.md)

_Update both this file **and** `docs/specs/input.md` whenever source files, public types, or Lua bindings change._
