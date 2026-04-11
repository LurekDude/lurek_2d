# `minimap` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.minimap`                                       |
| **Source**     | `src/minimap/`                                       |
| **Rust Tests** | `tests/rust/game/minimap_tests.rs`                   |
| **Lua Tests**  | `tests/lua/unit/test_minimap.lua`                    |
| **Architecture** | —                                                  |

## Purpose

The `minimap` module provides a self-contained, grid-based minimap data model for overhead map displays commonly used in strategy, RPG, and open-world games. It is a **Tier 2 Engine Extension** that operates as a **pure CPU data-model module** — it has zero GPU or wgpu dependencies. All rendering responsibility is delegated to the `lua_api` bridge layer, which reads the minimap state and produces draw commands or texture uploads.

## Source Files

| File         | Purpose                                                                                  |
|--------------|------------------------------------------------------------------------------------------|
| `minimap.rs` | Core `Minimap` data model: terrain grid, fog of war, objects, pings, markers, zoom/pan, coordinate conversion, and time-based update. Includes `pings()` and `markers_iter()` accessors for sibling render modules. |
| `render.rs`  | GPU render-command generation: `Minimap::generate_render_commands(screen_x, screen_y)` emits background, terrain cells (fog-dimmed), viewport outline, and ping circles. |
| `types.rs`   | Supporting type definitions: `ColorMode` and `FogLevel` enums, `MinimapObjectType`, `MinimapObject`, `MinimapPing`, and `MinimapMarker` plain data structs. |
| `mod.rs` | — |

## Key Types

| Type | Description |
|------|-------------|
| `Minimap` | Principal type for the `minimap` module. |
| `ColorMode` | Principal type for the `minimap` module. |
| `FogLevel` | Principal type for the `minimap` module. |
| `MinimapObjectType` | Principal type for the `minimap` module. |
| `MinimapObject` | Principal type for the `minimap` module. |
| `MinimapPing` | Principal type for the `minimap` module. |
| `MinimapMarker` | Principal type for the `minimap` module. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/minimap.md`](../../docs/specs/minimap.md)

_Update both this file **and** `docs/specs/minimap.md` whenever source files, public types, or Lua bindings change._
