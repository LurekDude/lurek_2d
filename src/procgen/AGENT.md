# procgen

## Module Info
- Group: Foundations.
- Source: `src/procgen/`.
- Spec: `docs/specs/procgen.md`.
- Lua bridge: `src/lua_api/procgen_api.rs` registers `lurek.procgen`.
- Runtime focus: deterministic CPU-side map, point-set, and field generation helpers.

## Module Purpose
The procgen module owns reusable procedural-generation algorithms that return plain data structures instead of engine-owned objects. It exists so gameplay and content code can generate caves, reachability masks, tileable noise, point distributions, and Voronoi regions without reimplementing seeded randomness or spatial traversal logic.

Its public surface is intentionally stateless from the caller's perspective: configuration is passed through function arguments or small option structs, while internal helpers such as the private LCG stay inside the module. It does not own tilemap editing, scene placement, or general renderer behavior, although it does include a small `NoiseGrid` debug-visualization type for turning sampled noise into render commands or CPU images.

## Files
- `mod.rs`: Module root and re-export surface for the public generation functions and option structs.
- `cellular.rs`: Cellular automata map generation with configurable fill, birth, survive, and iteration settings.
- `flood_fill.rs`: Threshold-based BFS flood fill over flat byte grids.
- `lcg.rs`: Internal deterministic random generator shared by the generation algorithms.
- `noise_ext.rs`: Periodic Perlin noise that tiles cleanly across configurable wrap periods.
- `poisson.rs`: Bridson-style Poisson-disk sampling for evenly spaced point placement.
- `render.rs`: `NoiseGrid` sampling and visualization helpers for command-queue or CPU-image inspection.
- `voronoi.rs`: Voronoi region, nearest-distance, and second-distance field generation with optional warp.

## Key Types
- `CellularOpts`: Configuration bundle for cellular automata generation.
- `VoronoiOpts`: Configuration bundle for Voronoi generation and optional domain warping.
- `NoiseGrid`: Sampled noise buffer that can be exported as render commands or a CPU image.
- `Lcg`: Internal deterministic RNG used to keep the public algorithms reproducible.
