---
name: input-handling
description: "Load this skill when working on Luna2D input: keyboard state, mouse position/buttons, gamepad support, or input event callbacks. Skip it for rendering, physics, or audio."
---

# Input Handling — Luna2D Engine

## Load When

- Modifying `src/input/` module code
- Adding new input device support
- Working on key mapping or input events
- Debugging input detection issues

## Owns

- Keyboard state tracking and key name conventions
- Mouse position and button state
- Gamepad input handling
- Input event → Lua callback pipeline

## Does Not Cover

- Game loop event processing → use `game-loop` skill




















- **No input during draw**: Input state is read-only during `luna.draw()` — mutations happen during update- **Callback firing**: Input callbacks (`luna.keypressed`, `luna.mousepressed`) fire before `luna.update(dt)`- **Button numbering**: Mouse buttons as integers: 1 (left), 2 (right), 3 (middle)- **Mouse coordinates**: Screen-space pixels, origin top-left- **Press vs held**: `keypressed` fires once on key-down; `isDown` returns true while held- **State tracking**: Track both current frame state and previous frame state for press/release detection- **Key names**: Lowercase strings matching winit key names: `"space"`, `"escape"`, `"a"`, `"left"`, `"return"`## Decision Rules- `src/lua_api/input_api.rs` — `luna.keyboard.*`, `luna.mouse.*` bindings- `src/input/gamepad.rs` — `GamepadState`, controller input- `src/input/mouse.rs` — `MouseState`, position and button tracking- `src/input/keyboard.rs` — `KeyboardState`, key press/release tracking## Live Repository Contracts- Window event handling → handled by `window` module- Lua API naming → use `lua-api-design` skill
