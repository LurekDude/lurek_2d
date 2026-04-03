# `math` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundation (no deps) |
| **Lua API** | `None` |
| **Source** | `src/math/` |
| **Tests** | `tests/math_tests.rs` |

## Summary

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

## Source Files

| File | Purpose |
|------|---------|
| `bezier.rs` | Bezier curve evaluation using De Casteljau's algorithm |
| `easing.rs` | Standard easing functions for smooth animation and interpolation |
| `geometry.rs` | 2D geometry utility functions |
| `grid.rs` | 2D pathfinding grid with A*, Dijkstra, BFS, and flow field generation |
| `mat3.rs` | Mat3 implementation for the `math` subsystem |
| `noise.rs` | 2D Perlin and Simplex noise generators for procedural content |
| `polygon.rs` | Polygon utilities: ear-clipping triangulation and convexity testing |
| `procgen.rs` | Procedural generation utility functions |
| `random.rs` | Seedable random number generator for reproducible sequences |
| `raycasting.rs` | 2D raycasting and visibility utility functions |
| `rect.rs` | Rect implementation for the `math` subsystem |
| `spatial_hash.rs` | Spatial hash for efficient broad-phase AABB collision queries |
| `srgb.rs` | sRGB gamma ↔ linear color space conversion |
| `transform.rs` | 2D affine transform wrapping Mat3 with chainable methods |
| `tween.rs` | Value interpolator with easing curves |
| `vec2.rs` | Vec2 implementation for the `math` subsystem |

## Submodules

### `math::bezier`

Bezier curve evaluation using De Casteljau's algorithm.

- **`BezierCurve`** (struct): A Bezier curve defined by control points.  Uses De Casteljau's algorithm for evaluation. Minimum 2 control points...

### `math::easing`

Standard easing functions for smooth animation and interpolation.

- **`linear`** (fn): Linear interpolation — no easing. Consult the module-level documentation for the broader usage context and...
- **`ease_in_quad`** (fn): Quadratic ease-in — starts slow, accelerates.
- **`ease_out_quad`** (fn): Quadratic ease-out — starts fast, decelerates.
- **`ease_in_out_quad`** (fn): Quadratic ease-in-out — slow start and end, fast middle.
- **`ease_in_cubic`** (fn): Cubic ease-in — starts slow, accelerates sharply.
- **`ease_out_cubic`** (fn): Cubic ease-out — starts fast, decelerates sharply.
- **`ease_in_out_cubic`** (fn): Cubic ease-in-out — smooth S-curve. Consult the module-level documentation for the broader usage context and...
- **`ease_in_quart`** (fn): Quartic ease-in — very slow start. Consult the module-level documentation for the broader usage context and...
- **`ease_out_quart`** (fn): Quartic ease-out — very slow end. Consult the module-level documentation for the broader usage context and...
- **`ease_in_out_quart`** (fn): Quartic ease-in-out — pronounced S-curve.
- **`ease_in_sine`** (fn): Sinusoidal ease-in — gentle sine-based acceleration.
- **`ease_out_sine`** (fn): Sinusoidal ease-out — gentle sine-based deceleration.
- **`ease_in_out_sine`** (fn): Sinusoidal ease-in-out — gentle S-curve.
- **`ease_in_expo`** (fn): Exponential ease-in — very slow start, rapid acceleration.
- **`ease_out_expo`** (fn): Exponential ease-out — rapid start, very slow end.
- **`ease_in_out_expo`** (fn): Exponential ease-in-out — sharp S-curve with exponential tails.
- **`ease_in_elastic`** (fn): Elastic ease-in — spring-like overshoot at the start.
- **`ease_out_elastic`** (fn): Elastic ease-out — spring-like overshoot at the end.
- **`ease_out_bounce`** (fn): Bounce ease-out — simulates a bouncing ball landing.
- **`ease_in_bounce`** (fn): Bounce ease-in — simulates a bouncing ball launching.
- **`ease_in_back`** (fn): Back ease-in — pulls back before accelerating past the start.
- **`ease_out_back`** (fn): Back ease-out — overshoots the target then settles back.
- **`apply`** (fn): Looks up an easing function by name and applies it to progress value `t`.  Supported names (case-insensitive):...

### `math::geometry`

2D geometry utility functions.

- **`angle_between`** (fn): Returns the angle in radians from (x1, y1) to (x2, y2).
- **`circle_contains_point`** (fn): Returns true if the point (px, py) is inside the circle centered at (cx, cy) with radius r.
- **`circle_intersects_circle`** (fn): Returns true if two circles overlap. Consult the module-level documentation for the broader usage context and...
- **`circle_intersects_line`** (fn): Line-circle intersection. Returns (intersects, hit1, hit2).
- **`circle_intersects_segment`** (fn): Segment-circle intersection. Same as line-circle but clamped to the segment.
- **`polygon_area`** (fn): Computes the signed area of a polygon using the Shoelace formula.
- **`polygon_centroid`** (fn): Computes the centroid of a polygon. Consult the module-level documentation for the broader usage context and...
- **`segment_intersects_segment`** (fn): Tests if two line segments intersect. Returns (intersects, intersection_point).
- **`closest_point_on_segment`** (fn): Returns the closest point on a line segment to a given point.
- **`point_in_polygon`** (fn): Tests if a point is inside a polygon using the ray casting algorithm.
- **`line_intersect`** (fn): Infinite line intersection. Returns the intersection point if lines are not parallel.
- **`bresenham`** (fn): Bresenham line rasterization from (x1, y1) to (x2, y2).
- **`convex_hull`** (fn): Computes the convex hull of a set of 2D points using Andrew's monotone chain algorithm.
- **`delaunay_triangulate`** (fn): Delaunay triangulation using the Bowyer-Watson algorithm.

### `math::grid`

2D pathfinding grid with A*, Dijkstra, BFS, and flow field generation.

- **`Grid`** (struct): 2D pathfinding grid with per-cell walkability and movement costs.  Supports A*, Dijkstra, and BFS pathfinding as well...

### `math::mat3`

Mat3 implementation for the `math` subsystem.

- **`Mat3`** (struct): A 3×3 column-major matrix used for 2D affine transforms (translation, rotation, scale).  Used by `Camera::view_matrix`...

### `math::noise`

2D Perlin and Simplex noise generators for procedural content.

- **`perlin2d`** (fn): Generates 2D Perlin noise at the given coordinates.
- **`simplex2d`** (fn): Generates 2D Simplex noise at the given coordinates.
- **`fbm`** (fn): Generates fractal Brownian motion noise by layering multiple octaves of Perlin noise.
- **`perlin3d`** (fn): Generates 3D Perlin noise at the given coordinates.
- **`perlin4d`** (fn): Generates 4D Perlin noise at the given coordinates.
- **`DistType`** (enum): Distance metric for Worley noise. Consult the module-level documentation for the broader usage context and...
- **`NoiseKind`** (enum): Noise algorithm kind used by fractal combinators.
- **`FractalType`** (enum): Fractal type for multi-octave noise. Consult the module-level documentation for the broader usage context and...
- **`MapGenOptions`** (struct): Options for 2D noise map generation. Consult the module-level documentation for the broader usage context and...
- **`NoiseGenerator`** (struct): Seeded procedural noise generator. Consult the module-level documentation for the broader usage context and...

### `math::polygon`

Polygon utilities: ear-clipping triangulation and convexity testing.

- **`triangulate`** (fn): Triangulate a simple polygon using the ear-clipping algorithm.
- **`is_convex`** (fn): Check if a polygon is convex. This accessor incurs no allocation; call it freely in hot paths.  Uses cross-product sign...

### `math::procgen`

Procedural generation utility functions.

- **`CellularOpts`** (struct): Options for cellular automata generation.
- **`VoronoiOpts`** (struct): Options for Voronoi diagram generation. Consult the module-level documentation for the broader usage context and...
- **`cellular_automata`** (fn): Generates a cave/dungeon map using cellular automata.
- **`voronoi_diagram`** (fn): Generates a Voronoi diagram. Consult the module-level documentation for the broader usage context and preconditions.
- **`flood_fill`** (fn): BFS flood fill on a grid. Consult the module-level documentation for the broader usage context and preconditions.
- **`poisson_disk`** (fn): Generates Poisson disk sample points using Bridson's algorithm.
- **`perlin_noise_periodic`** (fn): Periodic Perlin noise that tiles over period (px, py).

### `math::random`

Seedable random number generator for reproducible sequences.

- **`RandomGenerator`** (struct): Seedable random number generator exposed as a Lua object.  Wraps `fastrand::Rng` with engine-compatible API for...

### `math::raycasting`

2D raycasting and visibility utility functions.

- **`Segment`** (struct): A line segment for raycasting. Consult the module-level documentation for the broader usage context and preconditions.
- **`cast_ray_2d`** (fn): Casts a ray from (ox, oy) in direction (dx, dy) against a list of segments.
- **`field_of_view`** (fn): Computes a visibility polygon by casting rays at segment endpoints.
- **`project_column`** (fn): Projects a wall column distance to screen-space drawing parameters.
- **`distance_shade`** (fn): Distance-based shading. Returns brightness in [0, 1].
- **`RayHit`** (struct): Result of a single ray cast. Consult the module-level documentation for the broader usage context and preconditions.
- **`SpriteProjection`** (struct): Sprite projection result. Consult the module-level documentation for the broader usage context and preconditions.
- **`Raycaster2D`** (struct): 2D grid-based raycaster using DDA traversal.  The grid stores wall types as `u32` values: 0 = empty, >0 = wall....

### `math::rect`

Rect implementation for the `math` subsystem.

- **`Rect`** (struct): An axis-aligned rectangle defined by its top-left corner and dimensions.  Used for AABB collision detection, UI layout,...

### `math::spatial_hash`

Spatial hash for efficient broad-phase AABB collision queries.

- **`SpatialItem`** (struct): Entry in the spatial hash. Consult the module-level documentation for the broader usage context and preconditions.
- **`SpatialHash`** (struct): Spatial hash for AABB queries. Consult the module-level documentation for the broader usage context and preconditions. ...

### `math::srgb`

sRGB gamma ↔ linear color space conversion.

- **`gamma_to_linear`** (fn): Convert a single sRGB gamma-space color component to linear space.  Input and output in `[0.0, 1.0]`. Uses the standard...
- **`linear_to_gamma`** (fn): Convert a single linear-space color component to sRGB gamma space.  Input and output in `[0.0, 1.0]`. Uses the standard...

### `math::transform`

2D affine transform wrapping Mat3 with chainable methods.

- **`Transform`** (struct): 2D affine transform exposed as a Lua object.  Wraps `Mat3` with chainable transformation methods matching the standard...

### `math::tween`

Value interpolator with easing curves.

- **`TweenValue`** (struct): A start-to-target value pair for interpolation.
- **`Tween`** (struct): Value interpolator using easing functions.  Animates one or more values from start to target over a given duration,...

### `math::vec2`

Vec2 implementation for the `math` subsystem.

- **`Vec2`** (struct): A 2D floating-point vector used throughout the engine for positions, velocities, and directions.  Implements standard...

## Key Types

### Structs

#### `math::bezier::BezierCurve`

A Bezier curve defined by control points.  Uses De Casteljau's algorithm for evaluation. Minimum 2 control points...

#### `math::procgen::CellularOpts`

Options for cellular automata generation.

#### `math::grid::Grid`

2D pathfinding grid with per-cell walkability and movement costs.  Supports A*, Dijkstra, and BFS pathfinding as well...

#### `math::noise::MapGenOptions`

Options for 2D noise map generation. Consult the module-level documentation for the broader usage context and...

#### `math::mat3::Mat3`

A 3×3 column-major matrix used for 2D affine transforms (translation, rotation, scale).  Used by `Camera::view_matrix`...

#### `math::noise::NoiseGenerator`

Seeded procedural noise generator. Consult the module-level documentation for the broader usage context and...

#### `math::random::RandomGenerator`

Seedable random number generator exposed as a Lua object.  Wraps `fastrand::Rng` with engine-compatible API for...

#### `math::raycasting::RayHit`

Result of a single ray cast. Consult the module-level documentation for the broader usage context and preconditions.

#### `math::raycasting::Raycaster2D`

2D grid-based raycaster using DDA traversal.  The grid stores wall types as `u32` values: 0 = empty, >0 = wall....

#### `math::rect::Rect`

An axis-aligned rectangle defined by its top-left corner and dimensions.  Used for AABB collision detection, UI layout,...

#### `math::raycasting::Segment`

A line segment for raycasting. Consult the module-level documentation for the broader usage context and preconditions.

#### `math::spatial_hash::SpatialHash`

Spatial hash for AABB queries. Consult the module-level documentation for the broader usage context and preconditions. ...

#### `math::spatial_hash::SpatialItem`

Entry in the spatial hash. Consult the module-level documentation for the broader usage context and preconditions.

#### `math::raycasting::SpriteProjection`

Sprite projection result. Consult the module-level documentation for the broader usage context and preconditions.

#### `math::transform::Transform`

2D affine transform exposed as a Lua object.  Wraps `Mat3` with chainable transformation methods matching the standard...

#### `math::tween::Tween`

Value interpolator using easing functions.  Animates one or more values from start to target over a given duration,...

#### `math::tween::TweenValue`

A start-to-target value pair for interpolation.

#### `math::vec2::Vec2`

A 2D floating-point vector used throughout the engine for positions, velocities, and directions.  Implements standard...

#### `math::procgen::VoronoiOpts`

Options for Voronoi diagram generation. Consult the module-level documentation for the broader usage context and...

### Enums

#### `math::noise::DistType`

Distance metric for Worley noise. Consult the module-level documentation for the broader usage context and...

#### `math::noise::FractalType`

Fractal type for multi-octave noise. Consult the module-level documentation for the broader usage context and...

#### `math::noise::NoiseKind`

Noise algorithm kind used by fractal combinators.

## Public Functions

- **`angle_between()`** `geometry::` — Returns the angle in radians from (x1, y1) to (x2, y2).
- **`apply()`** `easing::` — Looks up an easing function by name and applies it to progress value `t`.  Supported names (case-insensitive):...
- **`bresenham()`** `geometry::` — Bresenham line rasterization from (x1, y1) to (x2, y2).
- **`cast_ray_2d()`** `raycasting::` — Casts a ray from (ox, oy) in direction (dx, dy) against a list of segments.
- **`cellular_automata()`** `procgen::` — Generates a cave/dungeon map using cellular automata.
- **`circle_contains_point()`** `geometry::` — Returns true if the point (px, py) is inside the circle centered at (cx, cy) with radius r.
- **`circle_intersects_circle()`** `geometry::` — Returns true if two circles overlap. Consult the module-level documentation for the broader usage context and...
- **`circle_intersects_line()`** `geometry::` — Line-circle intersection. Returns (intersects, hit1, hit2).
- **`circle_intersects_segment()`** `geometry::` — Segment-circle intersection. Same as line-circle but clamped to the segment.
- **`closest_point_on_segment()`** `geometry::` — Returns the closest point on a line segment to a given point.
- **`convex_hull()`** `geometry::` — Computes the convex hull of a set of 2D points using Andrew's monotone chain algorithm.
- **`delaunay_triangulate()`** `geometry::` — Delaunay triangulation using the Bowyer-Watson algorithm.
- **`distance_shade()`** `raycasting::` — Distance-based shading. Returns brightness in [0, 1].
- **`ease_in_back()`** `easing::` — Back ease-in — pulls back before accelerating past the start.
- **`ease_in_bounce()`** `easing::` — Bounce ease-in — simulates a bouncing ball launching.
- **`ease_in_cubic()`** `easing::` — Cubic ease-in — starts slow, accelerates sharply.
- **`ease_in_elastic()`** `easing::` — Elastic ease-in — spring-like overshoot at the start.
- **`ease_in_expo()`** `easing::` — Exponential ease-in — very slow start, rapid acceleration.
- **`ease_in_out_cubic()`** `easing::` — Cubic ease-in-out — smooth S-curve. Consult the module-level documentation for the broader usage context and...
- **`ease_in_out_expo()`** `easing::` — Exponential ease-in-out — sharp S-curve with exponential tails.
- **`ease_in_out_quad()`** `easing::` — Quadratic ease-in-out — slow start and end, fast middle.
- **`ease_in_out_quart()`** `easing::` — Quartic ease-in-out — pronounced S-curve.
- **`ease_in_out_sine()`** `easing::` — Sinusoidal ease-in-out — gentle S-curve.
- **`ease_in_quad()`** `easing::` — Quadratic ease-in — starts slow, accelerates.
- **`ease_in_quart()`** `easing::` — Quartic ease-in — very slow start. Consult the module-level documentation for the broader usage context and...
- **`ease_in_sine()`** `easing::` — Sinusoidal ease-in — gentle sine-based acceleration.
- **`ease_out_back()`** `easing::` — Back ease-out — overshoots the target then settles back.
- **`ease_out_bounce()`** `easing::` — Bounce ease-out — simulates a bouncing ball landing.
- **`ease_out_cubic()`** `easing::` — Cubic ease-out — starts fast, decelerates sharply.
- **`ease_out_elastic()`** `easing::` — Elastic ease-out — spring-like overshoot at the end.
- **`ease_out_expo()`** `easing::` — Exponential ease-out — rapid start, very slow end.
- **`ease_out_quad()`** `easing::` — Quadratic ease-out — starts fast, decelerates.
- **`ease_out_quart()`** `easing::` — Quartic ease-out — very slow end. Consult the module-level documentation for the broader usage context and...
- **`ease_out_sine()`** `easing::` — Sinusoidal ease-out — gentle sine-based deceleration.
- **`fbm()`** `noise::` — Generates fractal Brownian motion noise by layering multiple octaves of Perlin noise.
- **`field_of_view()`** `raycasting::` — Computes a visibility polygon by casting rays at segment endpoints.
- **`flood_fill()`** `procgen::` — BFS flood fill on a grid. Consult the module-level documentation for the broader usage context and preconditions.
- **`gamma_to_linear()`** `srgb::` — Convert a single sRGB gamma-space color component to linear space.  Input and output in `[0.0, 1.0]`. Uses the standard...
- **`is_convex()`** `polygon::` — Check if a polygon is convex. This accessor incurs no allocation; call it freely in hot paths.  Uses cross-product sign...
- **`line_intersect()`** `geometry::` — Infinite line intersection. Returns the intersection point if lines are not parallel.
- **`linear()`** `easing::` — Linear interpolation — no easing. Consult the module-level documentation for the broader usage context and...
- **`linear_to_gamma()`** `srgb::` — Convert a single linear-space color component to sRGB gamma space.  Input and output in `[0.0, 1.0]`. Uses the standard...
- **`perlin2d()`** `noise::` — Generates 2D Perlin noise at the given coordinates.
- **`perlin3d()`** `noise::` — Generates 3D Perlin noise at the given coordinates.
- **`perlin4d()`** `noise::` — Generates 4D Perlin noise at the given coordinates.
- **`perlin_noise_periodic()`** `procgen::` — Periodic Perlin noise that tiles over period (px, py).
- **`point_in_polygon()`** `geometry::` — Tests if a point is inside a polygon using the ray casting algorithm.
- **`poisson_disk()`** `procgen::` — Generates Poisson disk sample points using Bridson's algorithm.
- **`polygon_area()`** `geometry::` — Computes the signed area of a polygon using the Shoelace formula.
- **`polygon_centroid()`** `geometry::` — Computes the centroid of a polygon. Consult the module-level documentation for the broader usage context and...
- **`project_column()`** `raycasting::` — Projects a wall column distance to screen-space drawing parameters.
- **`segment_intersects_segment()`** `geometry::` — Tests if two line segments intersect. Returns (intersects, intersection_point).
- **`simplex2d()`** `noise::` — Generates 2D Simplex noise at the given coordinates.
- **`triangulate()`** `polygon::` — Triangulate a simple polygon using the ear-clipping algorithm.
- **`voronoi_diagram()`** `procgen::` — Generates a Voronoi diagram. Consult the module-level documentation for the broader usage context and preconditions.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 3 |
| `fn` | 55 |
| `mod` | 16 |
| `struct` | 19 |
| **Total** | **93** |

