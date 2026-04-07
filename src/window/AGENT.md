# `window` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.window`                                        |
| **Source**     | `src/window/`                                        |
| **Rust Tests** | `tests/rust/unit/window_tests.rs`                    |
| **Lua Tests**  | `tests/lua/unit/test_window.lua`                     |
| **Architecture** | —                                                  |

## Purpose

The `window` module is a Tier 1 core engine subsystem that manages all window lifecycle properties and viewport coordinate-space transforms. It provides pure Rust helper functions that read and mutate `WindowState` fields stored inside `SharedState`. **No winit or wgpu calls are made anywhere in this module.** Instead, operations that require OS interaction — title changes, fullscreen toggles, resizing, icon updates, minimize/maximize — are written into `pending_*` fields on `WindowState`. The engine's `App` event loop (in `engine::app`) consumes those pending fields at the start of the next frame and applies them to the actual winit `Window` handle. This deferred-write architecture keeps the module fully testable without a display server or GPU context, which is critical for headless CI and the Lua BDD test harness.

## Source Files

| File             | Purpose                                                                                              |
|------------------|------------------------------------------------------------------------------------------------------|
| `mod.rs`         | Module root — declares submodules and re-exports all public functions and types from `management` and `viewport`. |
| `event_loop.rs`  | Reserved placeholder for future platform-specific event-loop integration. Currently contains no public items. |
| `management.rs`  | Window chrome operations — title, fullscreen, VSync, position, size, minimize, maximize, restore, close, icon, focus, visibility, DPI scale, native message box. All functions take `&WindowState` or `&mut WindowState`; deferred writes go to `pending_*` fields. |
| `viewport.rs`    | Viewport coordinate-space utilities — logical game dimensions, scale mode (`none`/`letterbox`/`stretch`/`pixel`), and bidirectional pixel ↔ game-space coordinate conversion using pre-computed scale and offset values. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/window.md`](../../specs/window.md)

_Update both this file **and** `specs/window.md` whenever source files, public types, or Lua bindings change._
