# input

## Module Info
- Module name: `input`
- Module group: `Platform Services`
- Spec path: `docs/specs/input.md`
- Lua API path(s): `src/lua_api/input_api.rs`
- Rust test path(s): `tests/rust/unit/input_tests.rs`
- Lua test path(s): `tests/lua/unit/test_input.lua`, `tests/lua/integration/test_input_camera.lua`

## Module Purpose

The input module is Lurek2D's device-state layer for keyboard, mouse, gamepad, and touch input. It stores per-frame snapshots that the rest of the engine and the Lua API can query synchronously instead of forcing scripts to consume raw OS event streams directly.

This module exists to turn noisy platform events into stable gameplay-facing state. `KeyboardState`, `MouseState`, `GamepadState`, and `TouchState` all keep track of what is currently down, what changed this frame, and any additional device-specific state such as scroll deltas, text input, cursor mode, gamepad mappings, or touch pressure.

It intentionally does not own event dispatch, world-space coordinate transforms, or platform window policy. The app loop receives winit and gilrs events and updates these structs, and the Lua bindings in `src/lua_api/input_api.rs` decide how that state is exposed under `lurek.keyboard`, `lurek.mouse`, `lurek.gamepad`, and `lurek.touch`. Input is a snapshot store, not an event bus.

## Files
- `mod.rs` is the module root and re-export surface. It gathers the device-specific state types and helper functions into one import point.
- `keyboard.rs` implements keyboard and scancode tracking, modifier state, key-repeat settings, and text-input buffering. It is the source of truth for key-name conversion and per-frame keyboard lifecycle.
- `mouse.rs` implements mouse position, button state, scroll tracking, cursor visibility and grab state, relative mode, and cursor type management. It is the right file for all cursor and pointer behavior.
- `gamepad.rs` implements per-gamepad button and axis snapshots plus persistent SDL-style mapping data. It is the main integration layer between gilrs state and the engine's gamepad API.
- `touch.rs` implements the active-touch registry keyed by touch ID. It owns multitouch bookkeeping and simple touch-point queries.

## Key Types
- `KeyboardState` is the module's keyboard snapshot object. It tracks held keys, keys pressed this frame, keys released this frame, scancodes, modifiers, text input, and repeat settings.
- `MouseState` is the central mouse snapshot object. It stores cursor position, button states, scroll deltas, visibility, grab mode, relative mode, and the currently selected cursor shape.
- `SystemCursor` defines the supported built-in cursor shapes. It matters because cursor selection is part of the public scripting contract.
- `CursorKind` is the mouse cursor payload enum for either a system cursor or custom RGBA cursor data. It marks the ownership boundary between generic cursor requests and their concrete representation.
- `CursorHandle` is the object wrapper used to pass cursor values around, especially through the Lua API. It is small but important for cursor lifecycle.
- `GamepadState` is the per-controller snapshot for buttons, axes, identity, and connection state. It is the main gamepad state object scripts reason about.
- `GamepadMappings` stores SDL GameControllerDB-style mapping strings keyed by GUID. It is the persistence object behind custom gamepad mapping support.
- `TouchPoint` is the immutable snapshot of one active touch. It carries the touch ID, position, and pressure.
- `TouchState` is the multitouch registry. It tracks all active touches and exposes add, move, end, and query operations.
- `MOD_SHIFT`, `MOD_CTRL`, `MOD_ALT`, and `MOD_META` are small constants, but they define the internal modifier bitmask contract used by keyboard state.
- `winit_key_to_string()` and `winit_scancode_to_string()` are key boundary helpers for the module. They define how platform key identifiers become the lowercase string names the rest of the engine uses.
- `LuaCursor` in `src/lua_api/input_api.rs` is the Lua-facing cursor object for this module. It is the important bridge when scripts create or inspect cursor resources.