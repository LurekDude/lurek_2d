# `raycaster` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extensions                           |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.raycaster`                                     |
| **Source**      | `src/raycaster/`                                     |
| **Rust Tests** | `tests/rust/unit/raycaster_tests.rs`                 |
| **Lua Tests**  | `tests/lua/unit/test_raycaster.lua`                  |
| **Architecture** | —                                                  |

## Purpose

The `raycaster` module implements a DDA-based 2D grid raycaster designed for Wolfenstein-style retro FPS and dungeon-crawler games. It operates entirely on a flat integer cell grid (`Raycaster2D`) and produces results as plain numeric data — distances, texture coordinates, hit positions — that Lua scripts consume to drive their own column rendering via `lurek.gfx` draw calls. The module is intentionally renderer-agnostic: it never writes GPU resources, pushes draw commands, or accesses SharedState resource pools. The engine owns column drawing; the raycaster provides the geometry.

## Source Files

| File                     | Purpose                                                        |
|--------------------------|----------------------------------------------------------------|
| `mod.rs`                 | Module root; re-exports all public types and functions          |
| `dda.rs`                 | `Raycaster2D` grid struct and DDA traversal algorithms         |
| `ray_hit.rs`             | `RayHit` result struct returned per cast column                |
| `segment.rs`             | `Segment` line type and `cast_ray_2d` geometry raycaster       |
| `visibility.rs`          | `field_of_view` — visibility polygon via endpoint raycasting   |
| `projection.rs`          | `project_column` column geometry and `distance_shade` falloff  |
| `sprite_projection.rs`   | `SpriteProjection` billboard transform for screen-space sprites|
| `column_batch.rs`        | `ColumnBatch` / `ColumnData` — per-column wall rendering state |
| `depth_buffer.rs`        | `DepthBuffer` — 1D per-column depth for sprite occlusion       |
| `doors.rs`               | `Door`, `DoorManager`, `DoorDirection`, `DoorState` — sliding door animation |
| `heightmap.rs`           | `HeightMap` — per-cell variable floor and ceiling heights      |
| `lighting.rs`            | `PointLight`, `compute_lighting`, `apply_lit_shade`            |
| `minimap_overlay.rs`     | `extract_minimap` (RGBA crop) and `draw_player_arrow`          |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/raycaster.md`](../../docs/specs/raycaster.md)

_Update both this file **and** `docs/specs/raycaster.md` whenever source files, public types, or Lua bindings change._
