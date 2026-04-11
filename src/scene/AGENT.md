# `scene` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.scene`                                         |
| **Source**      | `src/scene/`                                         |
| **Rust Tests** | `tests/rust/unit/scene_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_scene.lua`                      |

## Purpose

The scene module implements a push-down automaton for game state management — the
industry-standard pattern for navigating between a game's distinct modes (title
screen, main gameplay, pause menu, inventory screen, game-over). Scenes are
pushed onto a LIFO stack; the top scene receives `update(dt)` calls each frame;
`draw()` dispatches to every scene bottom-to-top so that overlay scenes (pause
menus, HUDs) render on top of their parent. Popping a scene returns control to
the one below it, with its full state intact.

## Source Files

| File              | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| `mod.rs`          | Module declaration, re-exports `SceneStack`, `ActiveTransition`, `TransitionType`, `DepthSorter` |
| `stack.rs`        | LIFO scene stack with named registry, inter-scene data store, and transition integration |
| `transition.rs`   | `TransitionType` enum with Lua string parsing, `ActiveTransition` timer with progress tracking |
| `depth_sorter.rs` | Per-frame depth-sorted draw batcher with function and object callback support |
| `render.rs`       | Render-command generation — `generate_render_commands()` and `draw_to_image()` on `SceneStack` |

## Key Types

| Type | Description |
|------|-------------|
| `DepthEntry` | Principal type for the `scene` module. |
| `DepthSorter` | Principal type for the `scene` module. |
| `SceneStack` | Principal type for the `scene` module. |
| `TransitionType` | Principal type for the `scene` module. |
| `ActiveTransition` | Principal type for the `scene` module. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/scene.md`](../../docs/specs/scene.md)

_Update both this file **and** `docs/specs/scene.md` whenever source files, public types, or Lua bindings change._
