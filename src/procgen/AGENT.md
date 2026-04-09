# `procgen` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.procgen`                                       |
| **Source**     | `src/procgen/`                                       |
| **Rust Tests** | `tests/rust/unit/procgen_tests.rs`                   |
| **Lua Tests**  | `tests/lua/unit/test_procgen.lua`                    |
| **Architecture** | —                                                  |

## Purpose

The `procgen` module provides five stateless procedural-generation algorithms for world-building and content creation during game initialization or runtime generation phases. Every function is CPU-only, fully deterministic when given the same seed, and returns plain data (flat arrays or point lists) — there is no GPU, audio, or window dependency. Results are intended to be post-processed into tilemaps, spawn tables, noise textures, or region maps before or during gameplay.

## Source Files

| File             | Purpose                                                              |
|------------------|----------------------------------------------------------------------|
| `mod.rs`         | Module root; declares submodules, re-exports public API items        |
| `cellular.rs`    | Cellular automata grid generation with configurable birth/survive rules |
| `flood_fill.rs`  | BFS flood fill returning a binary reachability mask                  |
| `noise_ext.rs`   | Seamlessly tileable periodic Perlin noise via hash-based gradients    |
| `poisson.rs`     | Bridson's Poisson-disk sampling for well-distributed point sets       |
| `voronoi.rs`     | Voronoi region assignment + distance fields with optional domain warping |
| `lcg.rs`         | Internal linear congruential generator (`pub(crate)`, not public)     |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/procgen.md`](../../docs/specs/procgen.md)

_Update both this file **and** `docs/specs/procgen.md` whenever source files, public types, or Lua bindings change._
