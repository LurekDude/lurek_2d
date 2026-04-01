# `src/math/` — Mathematics, Geometry, Noise, and Pathfinding

## Purpose

The math module is the foundational layer that every other Luna2D module is
permitted to depend on.  At its core are four types used universally across the
engine: `Vec2` (2D vector with full operator overloading for positions, velocities,
and directions), `Mat3` (3×3 homogeneous transformation matrix for 2D affine
transforms), `Rect` (axis-aligned bounding box with intersection and containment
tests), and `Transform` (a chainable wrapper that composes translate, rotate, and
scale operations into a matrix).

Beyond the core types the module is a comprehensive mathematical toolkit
covering: 24 easing functions (quadratic, cubic, quartic, quintic, sine,
exponential, circular, elastic, bounce, back) for smooth animation; multiple
noise generators (Perlin 2D/3D/4D, Simplex 2D, fractal Brownian motion, ridged,
turbulence, and Worley cellular noise) for procedural generation; a seeded
`RandomGenerator` with uniform and Gaussian distributions; complex numbers;
polynomial evaluation; Catmull-Rom and B-Spline curve interpolation; geometry
algorithms (convex hull, Delaunay triangulation, Bresenham line); and a spatial
hash table for broad-phase overlap queries.

The pathfinding subsystem — A*, Dijkstra, BFS, hierarchical A* (HPA*), and
async flow fields via a thread pool — lives in `math/pathfinding/` because it
depends on grid math and predates the dedicated `ai/` module.  The math module
is the sole exception to the no-cross-module-dependency rule and is explicitly
permitted as a direct import by `physics/`, `graphics/`, `tilemap/`, `ai/`,
and every other domain module.

## Architecture

```
math/
  │
  ├── Core types
  │     ├── Vec2 ── 2D vector (x, y: f32)
  │     ├── Mat3 ── 3×3 matrix (affine transforms)
  │     ├── Rect ── axis-aligned rectangle
  │     └── Transform ── chainable 2D transform wrapper
  │
  ├── Curves and animation
  │     ├── BezierCurve ── arbitrary-order Bézier curves
  │     ├── Tween ── easing-based value interpolation
  │     └── Easing ── 24 easing functions (quad, cubic, elastic, bounce, ...)
  │
  ├── Noise and procedural generation
  │     ├── perlin2d/3d/4d, simplex2d
  │     ├── fbm, fractal, ridged, turbulence, worley
  │     ├── NoiseGenerator ── configurable multi-octave noise
  │     └── ProcGen ── cellular automata, voronoi, poisson disk
  │
  ├── Geometry
  │     ├── geometry.rs ── intersection, convex hull, Delaunay, Bresenham
  │     ├── polygon.rs ── ear-clipping triangulation, convexity test
  │     └── color.rs ── gamma/linear conversion
  │
  ├── Spatial
  │     ├── Grid ── 2D walkable grid with A*/Dijkstra/BFS
  │     ├── SpatialHash ── spatial partitioning for broad-phase
  │     └── Raycaster2D / raycasting.rs ── Wolfenstein-style raycasting
  │
  ├── Tile navigation
  │     └── TileWalker ── grid-based first-person movement (Facing enum)
  │
  ├── Random
  │     └── RandomGenerator ── seeded PRNG with normal distribution
  │
  └── pathfinding/ ── advanced pathfinding subsystem
        ├── astar.rs ── A* with line-of-sight smoothing
        ├── nav_grid.rs ── NavGrid with diagonal modes and chunk dirty tracking
        ├── unit_pathfinder.rs ── cached pathfinder with partial paths
        ├── flow_field.rs ── BFS flow fields for group movement
        ├── hpa.rs ── Hierarchical Pathfinding A* (HPA*)
        └── async_pool.rs ── thread pool for background pathfinding
```

### How It Works

`Vec2` is `#[derive(Copy, Clone)]` with `f32` components and implements
`std::ops::{Add, Sub, Mul, Div, Neg}`.  The `*` operator is element-wise
(Hadamard) multiplication, not dot product; dot product is an explicit
`.dot(other)` method.  This matches the most common game-engine convention and
prevents ambiguity when scaling a vector by a scalar vs. element-wise by
another vector.

Noise functions use permutation tables seeded at initialisation.
`NoiseGenerator` wraps the raw functions with configurable octaves,
lacunarity, persistence, and scale, outputting values in [−1, 1] or [0, 1]
depending on the normalise mode.  `ProcGen` lifts noise into higher-level
spatial structures: cellular-automata cave passes, Voronoi region partitioning,
and Poisson-disc scatter for natural distribution of objects.

The `pathfinding/` subsystem uses `NavGrid` — a flat `Vec<u8>` with per-cell
walkability flags and movement costs — as the shared spatial structure for all
algorithms.  `UnitPathfinder` caches the last computed path per entity ID and
re-runs A* only when the destination changes or a dirty cell lies on the cached
path.  `AsyncPool` dispatches heavy pathfinding jobs to a `rayon` thread pool
and returns poll-able handles so Lua can check results over multiple frames
without blocking the main thread.

### Dependency Direction

```
math/ ──────► (none)
```

**Foundation module** — zero Luna2D dependencies. Other modules (graphics, physics,
ai, tilemap, etc.) depend on math types, but math depends on nothing.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports all public types and functions from 20 sub-modules plus the
`pathfinding` sub-module.

---

### `vec2.rs` — `Vec2` (2D Vector)

**~269 lines** | Core 2D vector type used throughout the engine.

#### Struct: `Vec2`

```rust
#[derive(Clone, Copy, Debug, PartialEq)]
pub struct Vec2 {
    pub x: f32,
    pub y: f32,
}
```

#### Constants

`ZERO`, `ONE`, `UP`, `DOWN`, `LEFT`, `RIGHT`

#### Methods

| Method | Returns |
|--------|---------|
| `new(x, y)` | Construct |
| `zero()` / `splat(v)` | Special constructors |
| `dot(other)` | Dot product |
| `length()` / `length_squared()` | Magnitude |
| `normalize()` | Unit vector |
| `distance(other)` | Euclidean distance |
| `lerp(other, t)` | Linear interpolation |
| `angle()` | Angle in radians (atan2) |

Operator overloads: `Add`, `Sub`, `Mul`, `Div`, `Neg`.

---

### `mat3.rs` — `Mat3` (3×3 Matrix)

**~156 lines** | Affine transformation matrix.

#### Struct: `Mat3`

```rust
pub struct Mat3 {
    pub m: [[f32; 3]; 3],
}
```

Methods: `identity`, `from_row_major`, `from_translation`, `from_rotation`,
`from_shear`, `from_scale`, `inverse`, `transform_point`.

Operator overloads: `Mul<Mat3>`.

---

### `rect.rs` — `Rect` (Axis-Aligned Rectangle)

**~97 lines**

```rust
pub struct Rect {
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
}
```

Methods: `new`, `center`, `area`, `contains(point)`, `intersects(other)`.

---

### `transform.rs` — `Transform` (Chainable 2D Transform)

**~219 lines** | Wraps `Mat3` with chainable builder-style API.

Methods: `new`, `from_components`, `translate`, `rotate`, `scale`, `shear`,
`reset`, `set_transformation`, `transform_point`, `inverse_transform_point`,
`inverse`, `matrix`. All transform methods return `&mut Self` for chaining.

---

### `bezier.rs` — `BezierCurve`

**~244 lines** | Arbitrary-order Bézier curves.

```rust
pub struct BezierCurve {
    control_points: Vec<Vec2>,
}
```

Methods: `new`, `evaluate(t)`, `render(segments)`, `get_derivative`,
`get/set/insert/remove_control_point`, `translate`, `rotate`, `scale`.

---

### `easing.rs` — 24 Easing Functions

**~450+ lines** | Standard easing functions plus an `apply(name, t)` dispatcher.

| Easing Type | In | Out | InOut |
|------------|-----|-----|-------|
| Quad | ✓ | ✓ | ✓ |
| Cubic | ✓ | ✓ | ✓ |
| Quart | ✓ | ✓ | ✓ |
| Sine | ✓ | ✓ | ✓ |
| Expo | ✓ | ✓ | ✓ |
| Elastic | ✓ | ✓ | ✓ |
| Bounce | ✓ | ✓ | ✓ |
| Back | ✓ | ✓ | ✓ |

Plus `linear` — 25 total functions.

---

### `tween.rs` — `Tween` (Value Interpolation)

**~272 lines** | Time-based value interpolation using easing functions.

```rust
pub struct Tween {
    duration: f64,
    easing_fn: fn(f64) -> f64,
    easing_name: String,
    clock: f64,
    values: Vec<TweenValue>,
}
```

Methods: `new`, `add_value(start, target)`, `update(dt) → bool` (true when complete),
`get_value(index)`, `get_all_values`, `reset`, `set_time`, `is_complete`.

---

### `noise.rs` — Noise Functions

**~550+ lines** | Standalone noise functions.

Functions: `perlin2d`, `simplex2d`, `fbm`, `perlin3d`, `perlin4d`.

---

### `noise_generator.rs` — `NoiseGenerator`

**~500+ lines** | Configurable noise generator with multiple algorithms.

```rust
pub struct NoiseGenerator {
    seed: u64,
    perm: Vec<u8>,
}
```

Methods: `new`, `set_seed`, `perlin_1d/2d/3d/4d`, `simplex_1d/2d/3d/4d`,
`fractal_fbm/ridged/turbulence`, `worley_2d/3d`.

Enums: `DistType`, `NoiseKind`, `FractalType`, `MapGenOptions`.

---

### `geometry.rs` — Geometry Algorithms

**~550+ lines** | Classical computational geometry.

| Function | Algorithm |
|----------|-----------|
| `angle_between(a, b)` | Angle between two vectors |
| `circle_contains/intersects` | Circle queries |
| `polygon_area/centroid` | Polygon properties |
| `segment_intersects` | Line segment intersection |
| `closest_point_on_segment` | Point-segment distance |
| `point_in_polygon` | Point containment (ray cast) |
| `line_intersect` | Line-line intersection |
| `bresenham(x0, y0, x1, y1)` | Rasterized line |
| `convex_hull(points)` | Graham scan |
| `delaunay_triangulate(points)` | Delaunay triangulation |

---

### `polygon.rs` — Polygon Triangulation

**~260 lines** | Ear-clipping triangulation.

Functions: `triangulate(vertices) → Vec<[usize; 3]>`, `is_convex(vertices) → bool`.

---

### `grid.rs` — `Grid` (Walkable Grid)

**~500+ lines** | 2D grid with pathfinding.

```rust
pub struct Grid {
    width: u32,
    height: u32,
    walkable: Vec<bool>,
    costs: Vec<f32>,
}
```

Methods: `new`, `set/is_walkable`, `set/get_cost`, `find_path_astar`,
`find_path_dijkstra`, `find_path_bfs`, `build_flow_field`.

---

### `random.rs` — `RandomGenerator`

**~195 lines** | Seeded PRNG.

Methods: `new`, `with_seed`, `random`, `random_int`, `random_float`,
`random_normal`, `set/get_seed`, `get/set_state`.

---

### `spatial_hash.rs` — `SpatialHash`

**~480 lines** | Spatial partitioning for broad-phase collision.

```rust
pub struct SpatialHash {
    cell_size: f32,
    items: HashMap<u64, SpatialItem>,
    buckets: HashMap<(i32, i32), Vec<u64>>,
}
```

Methods: `new`, `insert`, `remove`, `update`, `clear`, `query_rect`,
`query_circle`, `query_segment`.

---

### `raycaster2d.rs` — `Raycaster2D` (Wolfenstein-Style)

**~450+ lines** | Grid-based raycasting for pseudo-3D rendering.

```rust
pub struct Raycaster2D {
    width: u32,
    height: u32,
    cells: Vec<u32>,
}
```

Methods: `new`, `set/get_cell`, `set_cells`, `is_blocked`, `cast_ray`,
`cast_rays`, `cast_rays_flat`, `line_of_sight`, `project_sprite`.

Returns `RayHit { distance, raw_distance, cell_value, side, tex_u, hit_x, hit_y, hit }`.

---

### `raycasting.rs` — 2D Raycasting Utilities

**~250 lines** | Line-segment raycasting.

Functions: `cast_ray_2d`, `field_of_view`, `project_column`, `distance_shade`.

---

### `tile_walker.rs` — `TileWalker`

**~380 lines** | Grid-based first-person movement.

```rust
pub struct TileWalker {
    x: i32,
    y: i32,
    facing: Facing,
    prev_x: i32, prev_y: i32, prev_facing: Facing,
    raycaster: Option<Raycaster2D>,
}
```

Enum `Facing`: `North | East | South | West`.

Methods: `new`, `move_forward/backward/strafe_left/right`,
`can_move_forward/backward/strafe_left/right`, `turn_left/right/around`,
`begin_move`, `get_interpolated_position/angle`.

---

### `procgen.rs` — Procedural Generation

**~480 lines** | World generation algorithms.

| Function | Algorithm |
|----------|-----------|
| `cellular_automata(opts)` | Birth/survival rules |
| `voronoi_diagram(opts)` | Voronoi with warp |
| `flood_fill(grid, x, y, val)` | 4-connected fill |
| `poisson_disk(w, h, r, seed)` | Blue noise sampling |
| `perlin_noise_periodic(w, h, opts)` | Tileable Perlin |

---

### `color.rs` — Color Space Conversion

**~35 lines** | Gamma/linear conversion.

Functions: `gamma_to_linear(f32) → f32`, `linear_to_gamma(f32) → f32`.

---

### `pathfinding/` — Advanced Pathfinding Subsystem

#### `pathfinding/mod.rs` — Re-exports

**~11 lines** — re-exports all pathfinding types.

#### `pathfinding/astar.rs` — A* with Smoothing

**~260 lines** | A* search with line-of-sight path smoothing.

Functions: `astar(grid, start, goal, unit_size, max_nodes)`, `line_of_sight`,
`smooth_path`.

#### `pathfinding/nav_grid.rs` — `NavGrid`

**~400+ lines** | Advanced navigation grid with chunks and dirty tracking.

```rust
pub struct NavGrid {
    width: u32,
    height: u32,
    costs: Vec<f32>,
    chunk_size: u32,
    diagonal_mode: DiagonalMode,
    dirty_rects: Vec<(u32, u32, u32, u32)>,
}
```

Enum `DiagonalMode`: `None | Always | NoCornerCut`.

20+ methods including `from_costs`, `fill`, `fill_rect`, `load/save_from_bytes`,
`set_chunk_size`, `set_diagonal_mode`, `neighbors`, `snapshot`.

#### `pathfinding/unit_pathfinder.rs` — `UnitPathfinder`

**~340 lines** | Cached pathfinder with partial paths and nearest-walkable search.

Methods: `find_path`, `find_path_smooth`, `get_path_length/cost`,
`find_partial_path`, `find_nearest_walkable`, `is_reachable`,
`heuristic_distance`, `line_of_sight`, cache management.

#### `pathfinding/flow_field.rs` — `FlowField`

**~250 lines** | BFS-based flow field for group movement.

Methods: `new`, `calculate/calculate_multi`, `get_direction/angle`,
`get_cost_to_target`, `is_calculated`, `get_targets`, `steer`.

#### `pathfinding/hpa.rs` — HPA* (Hierarchical Pathfinding)

**~450+ lines** | Hierarchical Pathfinding A*.

Types: `AbstractEdge`, `AbstractNode`, `Chunk`, `AbstractGraph`.

Functions: `build_abstract(grid, chunk_size)`, `hpa_star(graph, start, goal)`,
`is_reachable(graph, start, goal)`.

#### `pathfinding/async_pool.rs` — `PathThreadPool`

**~210 lines** | Thread pool for background pathfinding.

```rust
pub struct PathThreadPool {
    tx: Sender<PathRequest>,
    rx: Receiver<PathResult>,
    cancelled: Arc<Mutex<HashSet<u64>>>,
    thread_count: usize,
    pending: usize,
}
```

Methods: `new`, `submit`, `poll`, `cancel`, `pending_count`,
`set/get_thread_count`.

---

## Cross-Cutting Concerns

### Error Handling

Most math functions return concrete values. Invalid operations (e.g., normalizing
a zero vector) return `Vec2::ZERO` rather than panicking.

### Lua Integration

The Lua bridge lives in `src/lua_api/math_api.rs` (~400 lines) and
`src/lua_api/math_ext_api.rs` (~200 lines), plus `src/lua_api/pathfinding_api.rs`
(~500 lines).

### Usage from Lua

```lua
-- Vectors
local pos = luna.math.newVec2(100, 200)
local dist = luna.math.distance(pos, target)

-- Noise
local val = luna.math.noise(x * 0.1, y * 0.1)

-- Pathfinding
local grid = luna.pathfinding.newNavGrid(100, 100)
local path = luna.pathfinding.findPath(grid, 0, 0, 99, 99)
```
