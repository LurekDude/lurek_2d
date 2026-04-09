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

## Summary

The `procgen` module provides five stateless procedural-generation algorithms for world-building and content creation during game initialization or runtime generation phases. Every function is CPU-only, fully deterministic when given the same seed, and returns plain data (flat arrays or point lists) — there is no GPU, audio, or window dependency. Results are intended to be post-processed into tilemaps, spawn tables, noise textures, or region maps before or during gameplay.

The five algorithms are:

* **Cellular automata** (`cellular.rs`) — iterative birth/survive rules on a seeded random binary grid to produce cave-like or room-like structures. The user configures fill probability, birth/survive neighbor thresholds, iteration count, and RNG seed via a `CellularOpts` struct with sensible defaults.
* **Flood fill** (`flood_fill.rs`) — BFS region discovery on a flat grid, returning a binary mask of all cells reachable from a seed coordinate that satisfy a threshold condition (above or below). Useful for isolating rooms, tagging connected regions after a cellular pass, or detecting unreachable areas.
* **Periodic Perlin noise** (`noise_ext.rs`) — tileable gradient noise that wraps seamlessly over configurable X/Y periods. Uses a hash-based permutation scheme with a quintic fade curve. Useful for scrolling backgrounds, terrain heightmaps, and texture generation.
* **Poisson-disk sampling** (`poisson.rs`) — Bridson's fast algorithm for placing points in a 2D area with a guaranteed minimum inter-point distance. Useful for object placement (trees, enemies, pickups) that avoids clumping while looking natural.
* **Voronoi diagram** (`voronoi.rs`) — nearest-point assignment of every grid cell to its closest seed point, returning region IDs, distances, and second-closest distances. Supports optional domain warping via hash-based noise for organic, irregular region boundaries.

All algorithms share an internal `Lcg` (linear congruential generator) struct (`pub(crate)`) for fast deterministic randomness. The `Lcg` is not exposed to Lua or to other modules.

The module depends only on Baseline (`engine` for log messages). It does **not** import from `math`, any Tier 1 module, or any other Tier 2 module. All five algorithms are exposed to Lua under `lurek.procgen.*` by `src/lua_api/procgen_api.rs`.

## Architecture

```
src/procgen/
  │
  mod.rs ─────── module root, re-exports public API
  │
  ├── cellular.rs ──── CellularOpts + cellular_automata()
  │                     └── uses Lcg for seeded initial fill
  │
  ├── flood_fill.rs ── flood_fill()
  │                     └── pure BFS, no RNG dependency
  │
  ├── noise_ext.rs ─── perlin_noise_periodic()
  │                     └── self-contained hash + fade + lerp
  │
  ├── poisson.rs ───── poisson_disk()
  │                     └── uses Lcg for candidate generation
  │
  ├── voronoi.rs ───── VoronoiOpts + voronoi_diagram()
  │                     ├── uses Lcg for warp noise seed
  │                     └── simple_hash_noise() (private helper)
  │
  └── lcg.rs ───────── Lcg (pub(crate))
                        └── shared deterministic RNG

  src/lua_api/
  └── procgen_api.rs ── registers lurek.procgen.* table
                         └── imports all 5 public functions + 2 opts structs
```

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

## Submodules

### `procgen::cellular`

Cellular automata cave and dungeon generation.

- **`CellularOpts`** (struct) — Configuration for `cellular_automata`: fill ratio, iteration count, birth/survive thresholds, seed. Implements `Default`.
- **`cellular_automata(width, height, opts) -> Vec<u8>`** (fn) — Runs seeded random fill followed by `opts.iterations` rounds of neighbor-count smoothing. Returns a flat row-major grid where `1` = wall and `0` = open.

### `procgen::flood_fill`

BFS reachability fill on a flat grid.

- **`flood_fill(data, width, height, sx, sy, threshold, above) -> Vec<u8>`** (fn) — Returns a binary mask (`1` = filled, `0` = not) of all cells reachable from `(sx, sy)` that satisfy the threshold condition. Uses 4-connected BFS (no diagonals).

### `procgen::noise_ext`

Tileable periodic Perlin noise.

- **`perlin_noise_periodic(x, y, px, py) -> f64`** (fn) — Evaluates seamlessly tileable 2D Perlin noise at `(x, y)` with wrap period `(px, py)`. Uses a coordinate-based hash for gradient selection and a quintic fade curve.

### `procgen::poisson`

Poisson-disk point sampling.

- **`poisson_disk(width, height, min_dist, max_attempts, seed) -> Vec<(f32, f32)>`** (fn) — Generates a set of points in `[0, width) × [0, height)` with at least `min_dist` separation between any pair. Uses Bridson's algorithm with a background acceleration grid.

### `procgen::voronoi`

Voronoi region and distance field generation.

- **`VoronoiOpts`** (struct) — Configuration for domain warping: `warp_scale`, `warp_strength`, `seed`. Implements `Default`.
- **`voronoi_diagram(width, height, points, opts) -> (Vec<u32>, Vec<f32>, Vec<f32>)`** (fn) — Assigns every cell to its nearest seed point and returns three flat arrays: region indices, closest distances, and second-closest distances.

### `procgen::lcg` (pub(crate))

Internal deterministic random number generator.

- **`Lcg`** (struct) — Linear congruential generator with methods `new(seed)`, `next() -> u64`, and `next_f32() -> f32`. Uses constants from Knuth's MMIX LCG. Not exported outside the `procgen` crate module.

## Key Types

### Structs

#### `procgen::cellular::CellularOpts`

Configuration for cellular automata generation. Implements `Default` and `Clone`.

| Field        | Type  | Default  | Description                                        |
|--------------|-------|----------|----------------------------------------------------|
| `fill`       | `f32` | `0.45`   | Initial fill probability (0.0–1.0)                 |
| `iterations` | `u32` | `5`      | Number of birth/survive smoothing rounds            |
| `birth`      | `u32` | `6`      | Neighbor count that births a new wall cell          |
| `survive`    | `u32` | `4`      | Neighbor count that keeps an existing wall alive    |
| `seed`       | `u64` | `12345`  | RNG seed for initial random fill                   |

#### `procgen::voronoi::VoronoiOpts`

Configuration for Voronoi domain warping. Implements `Default` and `Clone`.

| Field            | Type  | Default | Description                                     |
|------------------|-------|---------|-------------------------------------------------|
| `warp_scale`     | `f32` | `0.1`   | Noise frequency used for domain warp             |
| `warp_strength`  | `f32` | `0.0`   | Warp displacement magnitude (0 = no warp)        |
| `seed`           | `u64` | `0`     | RNG seed for warp noise                          |

#### `procgen::lcg::Lcg` (pub(crate))

Internal linear congruential generator. Not public.

| Field   | Type  | Description        |
|---------|-------|--------------------|
| `state` | `u64` | Current RNG state  |

### Enums

No public enums in this module.

## Lua API

All functions are registered under `lurek.procgen.*` by `src/lua_api/procgen_api.rs`. The table is added to the `luna` global as `lurek.procgen`. The registration function signature is `pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()>`. The `_state` parameter is unused — all algorithms are stateless.

| Lua function | Parameters | Returns | Description |
|---|---|---|---|
| `lurek.procgen.cellularAutomata(w, h, opts?)` | `w: integer`, `h: integer`, `opts: {fill, iterations, birth, survive, seed}?` | flat `{integer}` of size `w*h` (0=open, 1=wall) | Generate a cave/dungeon map via cellular automata |
| `lurek.procgen.floodFill(data, w, h, sx, sy, threshold?, above?)` | `data: {integer}`, `w, h, sx, sy: integer` (0-based), `threshold: integer` (default 128), `above: boolean` (default false) | flat `{integer}` mask of size `w*h` (0/1) | BFS flood fill from seed coordinate |
| `lurek.procgen.perlinNoise(x, y, px, py)` | `x, y, px, py: number` | `number` in approximately `[-1, 1]` | Evaluate periodic tileable Perlin noise |
| `lurek.procgen.poissonDisk(w, h, minDist, maxAttempts?, seed?)` | `w, h, minDist: number`, `maxAttempts: integer` (default 30), `seed: integer` (default 0) | `{{x=n, y=n}, ...}` table of point objects | Generate Poisson-disk distributed points |
| `lurek.procgen.voronoi(w, h, pts, opts?)` | `w, h: integer`, `pts: {{x=n, y=n}, ...}`, `opts: {warp_scale, warp_strength, seed}?` | `regions, distances, secondDistances` (three flat tables) | Generate Voronoi diagram; region indices are 1-based |

**Note on Voronoi regions**: The Lua binding adds 1 to the raw Rust region indices (`*r + 1`) so that region IDs are 1-based, matching Lua table conventions.

**Note on flood fill coordinates**: `sx` and `sy` are 0-based grid coordinates passed directly to the Rust function.

## Lua Examples

```lua
function lurek.init()
    -- Generate a 40x30 cave map with cellular automata
    local cave = lurek.procgen.cellularAutomata(40, 30, {
        fill = 0.45,
        iterations = 5,
        birth = 6,
        survive = 4,
        seed = 42
    })

    -- Find all open cells reachable from the center
    local reachable = lurek.procgen.floodFill(cave, 40, 30, 20, 15, 1, false)
    -- reachable[i] == 1 means cell i is connected to (20,15) via open cells

    -- Sample points for object placement (trees, rocks, etc.)
    local points = lurek.procgen.poissonDisk(200, 200, 15, 30, 123)
    for _, p in ipairs(points) do
        print(string.format("Object at %.1f, %.1f", p.x, p.y))
    end

    -- Generate Voronoi regions for a province map
    local seeds = {
        { x = 25, y = 25 },
        { x = 75, y = 25 },
        { x = 50, y = 75 },
    }
    local regions, dist, dist2 = lurek.procgen.voronoi(100, 100, seeds)
    -- regions[i] is 1, 2, or 3 (1-based seed index)
end

function lurek.render()
    -- Use periodic noise for a scrolling background
    for x = 0, 199 do
        for y = 0, 149 do
            local n = lurek.procgen.perlinNoise(x * 0.05, y * 0.05, 10.0, 7.5)
            local brightness = (n + 1) * 0.5  -- map [-1,1] to [0,1]
            lurek.gfx.setColor(brightness, brightness, brightness)
            lurek.gfx.points(x, y)
        end
    end
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 3 (2 public + 1 pub(crate)) |
| `enum`     | 0     |
| `fn`       | 7 (5 public + 1 pub(crate) struct with 3 methods + 1 private helper) |
| Lua bindings | 5   |
| Source files | 7   |
| **Total public items** | **7** |

## References

| Module        | Relationship | Notes                                                    |
|---------------|-------------|----------------------------------------------------------|
| `engine`      | Imports from | Uses `log_messages` constants (`PG01_CELLULAR_START`, `PG02_CELLULAR_DONE`, `VR01`, `VR02`) and `log_msg!` macro |
| `lua_api`     | Imported by  | `src/lua_api/procgen_api.rs` registers `lurek.procgen.*`  |
| `tilemap`     | Related      | Generated cave/dungeon grids are typically stored as tilemap data |
| `pathfinding` | Related      | Generated dungeon grids can feed into pathfinding navigation grids |
| `math`        | Similar      | `math` provides `Noise` (simplex/Perlin/fBm) and `RandomGenerator`; `procgen` provides higher-level generation algorithms (cellular automata, Voronoi, Poisson disk) that use an internal `Lcg` instead of importing `math::random` |

**Differentiation from `math`**: The `math` module provides low-level noise primitives (`Noise` struct with simplex, Perlin, fBm, ridged) and a general-purpose `RandomGenerator`. The `procgen` module provides complete generation *algorithms* that compose noise, RNG, and spatial data structures into usable map/point/region data. `procgen` intentionally does **not** depend on `math` — it uses its own internal `Lcg` for deterministic seeding.

## Notes

- All generation functions are **deterministic**: the same seed always produces the same output. This is enforced by using the internal `Lcg` rather than any system RNG.
- The `Lcg` uses Knuth's MMIX constants: multiplier `6364136223846793005`, increment `1442695040888963407`. The seed is offset by `+1` to avoid a zero initial state.
- `cellular_automata` treats out-of-bounds cells as walls during neighbor counting, which naturally produces solid borders around the generated map.
- `flood_fill` uses 4-connected BFS (cardinal directions only, no diagonals). The returned mask is `Vec<u8>` (not `Vec<bool>`), with `1` = filled and `0` = not filled.
- `perlin_noise_periodic` uses a coordinate-hashing scheme rather than a permutation table, making it fully self-contained with no static state.
- `poisson_disk` uses a background grid of cell size `min_dist / sqrt(2)` for O(1) neighbor lookups. The `max_attempts` parameter controls how hard the algorithm tries to place a new point before giving up on an active sample (higher values → denser packing, slower generation).
- `voronoi_diagram` uses brute-force nearest-point search (O(cells × seeds)). For large seed counts (>1000), performance may degrade. The `simple_hash_noise` private helper provides cheap deterministic noise for domain warping.
- The module imports `crate::engine::log_messages` for structured debug logging in `cellular.rs` and `voronoi.rs`. Other submodules produce no log output.
- No `unsafe` code anywhere in the module.
- Breaking change surface: renaming or removing any of the five `lurek.procgen.*` functions will break Lua game scripts that use procedural generation.
