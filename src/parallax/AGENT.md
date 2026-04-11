# `parallax` — Agent Reference

| Property         | Value                                                                         |
|------------------|-------------------------------------------------------------------------------|
| **Tier**         | Tier 2 — Engine Extensions                                                    |
| **Status**       | Implemented — Full                                                            |
| **Lua API**      | `lurek.parallax` (25 functions, 2 UserData types)                             |
| **Source**       | `src/parallax/`                                                               |
| **Rust Tests**   | inline in `src/parallax/layer.rs`                                             |
| **Lua Tests**    | `tests/lua/unit/test_parallax.lua`, `tests/lua/integration/test_parallax_camera.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md` § Tier 2 Modules                  |

## Purpose

`src/parallax/` provides a CPU-driven, multi-layer 2D scrolling background system. Each
`ParallaxLayer` scrolls at a configurable speed relative to the camera, supports autonomous
drift (autoscroll), horizontal and vertical tiling, z-ordering, opacity, tint, and per-layer
blend modes. Multiple layers can be grouped into a `ParallaxSet` for batch update and draw.
The Lua bridge lives in `src/lua_api/parallax_api.rs`.

## Source Files

| File      | Purpose                                                                     |
|-----------|-----------------------------------------------------------------------------|
| `mod.rs`  | Module root; re-exports `ParallaxLayer` and `ParallaxDrawBatch`.            |
| `layer.rs`| `ParallaxLayer` scroll logic, `ParallaxDrawBatch`, 9 inline unit tests.     |

## Full Specification

Full spec: [`docs/specs/parallax.md`](../../../docs/specs/parallax.md)
