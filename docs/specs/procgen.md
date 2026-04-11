# `procgen` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.procgen` |
| **Source** | `src/procgen/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The procgen module owns reusable procedural-generation algorithms that return plain data structures instead of engine-owned objects. It exists so gameplay and content code can generate caves, reachability masks, tileable noise, point distributions, and Voronoi regions without reimplementing seeded randomness or spatial traversal logic.

Its public surface is intentionally stateless from the caller's perspective: configuration is passed through function arguments or small option structs, while internal helpers such as the private LCG stay inside the module. It does not own tilemap editing, scene placement, or general renderer behavior, although it does include a small `NoiseGrid` debug-visualization type for turning sampled noise into render commands or CPU images.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Foundations responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.procgen.* (Lua API — src/lua_api/procgen_api.rs)
    |
    v
src/procgen/mod.rs
    |- cellular.rs - cellular
    |- flood_fill.rs - flood_fill
    |- lcg.rs - lcg
    |- noise_ext.rs - noise_ext
    |- poisson.rs - poisson
    |- render.rs - render
    |- voronoi.rs - voronoi
```

---

## Source Files

| File | Purpose |
|------|---------|
| `cellular.rs` | Cellular automata map generation with configurable fill, birth, survive, and iteration settings. |
| `flood_fill.rs` | Threshold-based BFS flood fill over flat byte grids. |
| `lcg.rs` | Internal deterministic random generator shared by the generation algorithms. |
| `mod.rs` | Module root and re-export surface for the public generation functions and option structs. |
| `noise_ext.rs` | Periodic Perlin noise that tiles cleanly across configurable wrap periods. |
| `poisson.rs` | Bridson-style Poisson-disk sampling for evenly spaced point placement. |
| `render.rs` | `NoiseGrid` sampling and visualization helpers for command-queue or CPU-image inspection. |
| `voronoi.rs` | Voronoi region, nearest-distance, and second-distance field generation with optional warp. |

---

## Submodules

### `procgen::cellular`

Cellular automata map generation with configurable fill, birth, survive, and iteration settings.

- **`CellularOpts`** (struct): Options for cellular automata generation.

### `procgen::flood_fill`

Threshold-based BFS flood fill over flat byte grids.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `procgen::lcg`

Internal deterministic random generator shared by the generation algorithms.

- **`Lcg`** (struct): Simple LCG (Linear Congruential Generator) for deterministic random numbers.

### `procgen::noise_ext`

Periodic Perlin noise that tiles cleanly across configurable wrap periods.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `procgen::poisson`

Bridson-style Poisson-disk sampling for evenly spaced point placement.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `procgen::render`

`NoiseGrid` sampling and visualization helpers for command-queue or CPU-image inspection.

- **`NoiseGrid`** (struct): A precomputed 2-D noise grid sampled from periodic Perlin noise.

### `procgen::voronoi`

Voronoi region, nearest-distance, and second-distance field generation with optional warp.

- **`VoronoiOpts`** (struct): Options for Voronoi diagram generation.

---

## Key Types

### Public Types

#### `CellularOpts`

Configuration bundle for cellular automata generation.

#### `VoronoiOpts`

Configuration bundle for Voronoi generation and optional domain warping.

#### `NoiseGrid`

Sampled noise buffer that can be exported as render commands or a CPU image.

#### `Lcg`

Internal deterministic RNG used to keep the public algorithms reproducible.

---

## Lua API

Exposed under `lurek.procgen.*` by `src/lua_api/procgen_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.procgen.cellularAutomata` | Generates a cave-like map using cellular automata. |
| `lurek.procgen.floodFill` | BFS flood fill on a flat grid of bytes. |
| `lurek.procgen.perlinNoise` | Evaluates periodic Perlin noise at a point. |
| `lurek.procgen.poissonDisk` | Generates Poisson disk sample points using Bridson's algorithm. |
| `lurek.procgen.voronoi` | Generates a Voronoi diagram for a set of seed points. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.procgen.
if lurek.procgen then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 4 |
| `enum` | 0 |
| `fn` (Lua API) | 5 |
| **Total** | **9** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Foundations to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Foundations to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Foundations to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/procgen/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
