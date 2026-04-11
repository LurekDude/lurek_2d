# parallax — Parallax Background Layer System

## Overview

Provides a CPU-driven, multi-layer 2D parallax background system.  Each
`ParallaxLayer` scrolls at a different speed relative to the camera, supports
autonomous drift (autoscroll), horizontal and vertical tiling, per-layer blend
modes, opacity, tint, and z-ordering.  Multiple layers can be grouped into a
`ParallaxSet` for scene-level management.

## Metadata

| Key | Value |
|---|---|
| **Module tier** | Tier 2 (depends on `engine`, `graphics`; no Tier 1↔Tier 1 cross-imports) |
| **Status** | Implemented |
| **Lua API namespace** | `lurek.parallax` |
| **Source** | `src/parallax/` |
| **Lua bridge** | `src/lua_api/parallax_api.rs` |
| **Tests** | `tests/lua/unit/test_parallax.lua`, `tests/lua/integration/test_parallax_camera.lua` |
| **Full specification** | `docs/specs/parallax.md` |

## Source Files

| File | Purpose |
|---|---|
| `src/parallax/mod.rs` | Module root, re-exports `ParallaxLayer`, `ParallaxDrawBatch` |
| `src/parallax/layer.rs` | Pure-Rust domain logic: scroll math, tiling, draw batch building, 9 unit tests |
| `layer.rs` | — |
| `mod.rs` | — |

## Full Specification

See [`docs/specs/parallax.md`](../../../docs/specs/parallax.md) for:
- Scroll formula and pixel offset calculation
- All `ParallaxLayer` fields with types and defaults
- Full `lurek.parallax.*` Lua API reference table
- GPU optimisation notes (future `DrawTiledImage` path)
- Threading notes (why update is single-threaded)
- Physics integration patterns at the Lua script level
- Scene transition recipes
- Performance guidance
