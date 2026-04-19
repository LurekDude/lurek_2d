# IDEA.md — `procgen` module

| Field  | Value         |
| ------ | ------------- |
| Module | procgen       |
| Path   | src/procgen/  |
| Date   | 2026-04-18    |
| Tier   | TIER-2-PLUGIN |

---

## Mission

Provide a comprehensive procedural content generation toolkit covering noise, dungeon layouts, world topology, name generation, and constraint-based tile placement — all deterministic and headless-friendly.

## Strengths

- **Broad algorithm coverage**: BSP dungeons, rooms-and-corridors, cellular automata, WFC, L-systems, Voronoi, heightmaps, Poisson disk, Markov name generation, world graphs — covers most 2D procgen needs.
- **Full determinism**: Every generator accepts a seed and uses the internal `Lcg` RNG, ensuring reproducible outputs across platforms.
- **Foundations tier**: Zero engine coupling beyond `math` — generators run headlessly in tests and pre-generation passes without window or GPU.
- **Parallel noise maps**: `generate_noise_map_parallel` uses rayon for high-throughput terrain generation on multi-core machines.
- **Rich noise library**: Perlin 1D/2D/3D/4D, Simplex 2D/3D/4D, Worley 2D/3D with three distance metrics, fBm/Ridged/Turbulence fractals, domain warping, and periodic tileable noise.

## Gaps

- No biome assignment or terrain classification built on top of noise/heightmap output.
- No Delaunay triangulation (Voronoi dual) — useful for mesh generation and organic region borders.
- No graph grammar / shape grammar generator for structured level layouts.

## Features (Competitor Citations)

1. **Biome classification layer** — Assign terrain types (forest, desert, ocean) from heightmap + moisture maps, similar to Godot's `FastNoiseLite` + custom shaders and LÖVE's `mapgen` community libraries.
2. **Delaunay triangulation** — Dual of Voronoi, useful for navmesh generation and region connectivity. Solar2D and Godot both expose triangulation utilities.
3. **Prefab room stamping** — Allow pre-designed room templates to be stamped into BSP/rooms dungeons, a pattern common in Godot's dungeon plugins and Haxe-based HaxeFlixel procgen libraries.

## Perf / Quality

- Noise map generation is O(w × h × octaves); parallel variant scales well on ≥4 cores.
- Dungeon generators (BSP, rooms, cellular) are O(w × h × iterations) — fast for typical map sizes.
- WFC propagation is worst-case O(n² × tile_count) but restarts cap total work via `max_attempts`.
- All generators use stack-allocated intermediaries; no heap churn beyond the output buffers.

## Test Gaps

- `noise.rs` (1060 lines) had **zero inline tests** — 30 tests added in sibling `noise_tests.rs` covering all public functions: determinism, value ranges, distance metrics, fractal modes, map generation.
- All other files already had adequate inline test coverage.

## TODO(dedup)

- `NoiseGenerator` methods (`perlin_2d`, `fbm`, etc.) partially overlap with standalone free functions (`perlin2d`, `fbm`). The free functions use `hash2d`-style hashing while the generator uses a permutation table. Consider deprecating the free functions in favour of `NoiseGenerator` for a single code path.
- `render.rs::NoiseGrid` duplicates heightmap-to-RGBA logic also found in `heightmap.rs::to_rgba_bytes`. Extract a shared greyscale-to-RGBA helper.

## TODO(helper)

- Add `Heightmap::from_cellular` convenience constructor that runs `cellular_automata` and wraps the result as a float heightmap.
- Add `NoiseGenerator::generate_map_parallel` method that combines the seeded permutation table with rayon parallelism (currently `generate_noise_map_parallel` always uses seed 0).

## TODO(plugin)

- `procgen` is Foundations tier but is a strong candidate for TIER-2-PLUGIN extraction: it has no engine runtime dependencies and its Lua surface (`lurek.procgen`) is self-contained. Extracting it as a Cargo feature would reduce binary size for games that don't need procgen.

## References

- Spec: [docs/specs/procgen.md](../../docs/specs/procgen.md)
- Lua API: `src/lua_api/procgen_api.rs`
- Noise tests: `src/procgen/noise_tests.rs`
- All inline tests in respective source files
