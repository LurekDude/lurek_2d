# math — Foundational Algorithms

| Property           | Value |
|--------------------|-------|
| **Tier**           | Baseline (leaf) |
| **Architecture**   | 15 submodule files, flat layout under `src/math/` |
| **Path**           | `src/math/` |
| **Depends on**     | `fastrand` (external); `crate::engine::log_messages` (log constants in `spatial_hash.rs` only) |
| **Depended on by** | Every other Lurek2D module |
| **Lua API**        | `lurek.math` via `src/lua_api/math_api.rs` |
| **Tests — Rust**   | `tests/rust/unit/math_tests.rs` (~60 tests, 857 lines) |
| **Tests — Lua**    | `tests/lua/unit/test_math.lua` (~20 tests, 128 lines) |
| **Inline tests**   | `easing.rs`, `tween.rs`, `spatial_hash.rs`, `geometry.rs`, `noise_generator.rs` |

## Summary

`math` is the **leaf of the dependency graph** — it has zero Tier-1+ internal Lurek2D dependencies. Every other module may freely import it. It provides the core mathematical primitives, procedural generation utilities, and interpolation tools used throughout the engine.

The module is organised as 15 flat source files, each owning one cohesive domain. All primary types (`Vec2`, `Mat3`, `Rect`, `Color`) are `Copy`, designed for zero-overhead use in per-frame game loops. Higher-level types (`BezierCurve`, `RandomGenerator`, `NoiseGenerator`, `Tween`, `SpatialHash`, `Transform`) are `Clone` and carry heap-allocated state.

**Domains covered:**

- **Vectors & matrices** — `Vec2` (2D vector, arithmetic overloads, directional constants), `Mat3` (3×3 row-major affine matrix with inverse)
- **Geometry** — `Rect` (AABB), circle/segment/polygon intersection tests, `polygon_area`, `polygon_centroid`, `point_in_polygon`, `convex_hull` (Andrew's monotone chain), `delaunay_triangulate` (Bowyer-Watson), `bresenham` line rasterization, `line_intersect`
- **Color** — `Color` (sRGB `[f32; 4]`, clamped), `gamma_to_linear` / `linear_to_gamma` (IEC 61966-2-1)
- **Noise** — standalone functions (`perlin2d`/`3d`/`4d`, `simplex2d`, `fbm`); `NoiseGenerator` with Perlin (1D–4D), Simplex (1D–3D), Worley/cellular (2D–3D, three distance metrics), fractal combinators (fBm, ridged, turbulence), domain warping, and 2D map generation
- **Easing** — 22 named easing functions + case-insensitive `apply(name, t)` lookup
- **Random** — `RandomGenerator` (fastrand wrapper, Box-Muller normal distribution, state serialization)
- **Transform** — `Transform` (`Mat3` wrapper with fluent translate/rotate/scale/shear API)
- **Bézier** — `BezierCurve` (arbitrary-order De Casteljau evaluation, rendering, derivatives, arc length)
- **Triangulation** — Ear-clipping `triangulate`, `is_convex` predicate
- **Spatial indexing** — `SpatialHash` (grid-based broad-phase with rect/circle/segment queries)
## Source Files

| File | Contents |
|------|----------|
| `mod.rs` | Module root — re-exports all public items from submodules |
| `vec2.rs` | `Vec2` struct — arithmetic ops, normalization, dot product, lerp, rotation, directional constants |
| `mat3.rs` | `Mat3` 3×3 matrix — identity, translation, rotation, scale, shear, inverse, multiply |
| `rect.rs` | `Rect` AABB — center, area, contains, intersects |
| `color.rs` | `Color` sRGB — constructors, `from_u8`/`to_u8`/`to_rgb_u32`, named constants, `gamma_to_linear`/`linear_to_gamma` |
| `bezier.rs` | `BezierCurve` — De Casteljau evaluation, render, derivative, arc length, control-point CRUD |
| `easing.rs` | 22 easing functions + `apply(name, t)` case-insensitive lookup with alias support |
| `geometry.rs` | Free geometry functions — angle, circle tests, polygon area/centroid, segment intersection, Bresenham, convex hull, Delaunay, point-in-polygon, line intersect |
| `noise_functions.rs` | Standalone noise — `perlin2d`/`3d`/`4d`, `simplex2d`, `simplex_noise_2d`/`3d`, `fbm` |
| `noise_generator.rs` | `NoiseGenerator` — seeded permutation-table noise with Perlin/Simplex/Worley, fractal combinators, domain warping, 2D map generation; `NoiseKind`, `DistType`, `FractalType`, `MapGenOptions` |
| `polygon.rs` | `triangulate` (ear-clipping, CCW enforcement), `is_convex` |
| `random.rs` | `RandomGenerator` — fastrand wrapper, normal distribution, state serialization |
| `spatial_hash.rs` | `SpatialHash`, `SpatialItem` — grid-based broad-phase with rect/circle/segment queries |
| `transform.rs` | `Transform` — `Mat3` wrapper with fluent translate/rotate/scale/shear/reset API |
| `tween.rs` | `Tween`, `TweenValue` — multi-value interpolation with named easing resolution |

## Key Types

### Vec2

```rust
pub struct Vec2 { pub x: f32, pub y: f32 }
```

Copy type with arithmetic operator overloads (`Add`, `Sub`, `Mul`, `Div`, `Neg`, `AddAssign`, `SubAssign`, `MulAssign`). Directional constants: `ZERO`, `ONE`, `UP` (0,−1), `DOWN` (0,1), `LEFT` (−1,0), `RIGHT` (1,0).

Methods: `new`, `zero`, `splat`, `dot`, `length`, `length_squared`, `normalize`, `distance`, `lerp`, `angle`, `rotate`, `perpendicular`, `cross`.

### Mat3

```rust
pub struct Mat3 { pub m: [[f32; 3]; 3] }
```

Row-major 3×3 affine matrix (`m[row][col]`). Factory methods: `identity`, `from_row_major`, `from_translation`, `from_rotation`, `from_scale`, `from_shear`. Operations: `inverse` (returns identity for zero determinant), `transform_point`, `Mul<Mat3>`.

### Rect

```rust
pub struct Rect { pub x: f32, pub y: f32, pub width: f32, pub height: f32 }
```

Axis-aligned bounding box. Methods: `new`, `center` → `Vec2`, `area`, `contains(x, y)`, `intersects(&Rect)`.

### Color

```rust
pub struct Color { pub r: f32, pub g: f32, pub b: f32, pub a: f32 }
```

sRGB color clamped to `[0.0, 1.0]`. Constants: `WHITE`, `BLACK`, `RED`, `GREEN`, `BLUE`, `LUNA_BG` (dark purple), `LUNA_ACCENT` (warm gold). Methods: `new` (const, clamping), `from_u8`, `to_u8`, `to_rgb_u32`. Free functions: `gamma_to_linear(f32) -> f32`, `linear_to_gamma(f32) -> f32`.

### BezierCurve

```rust
pub struct BezierCurve { control_points: Vec<Vec2> }  // private field
```

Arbitrary-order Bézier curve using De Casteljau's algorithm. Methods: `new` (panics if <2 points), `evaluate(t)`, `render(segments)`, `render_segment(t0, t1, steps)`, `get_derivative()`, `get_control_point(i)`, `set_control_point(i, p)`, `insert_control_point(p, index?)`, `remove_control_point(i)`, `get_control_point_count()`, `translate(dx, dy)`, `rotate(angle, ox, oy)`, `scale(s, ox, oy)`, `length()`, `get_interpolated_position`, `get_interpolated_angle`. Implements `Clone`.

### NoiseGenerator

```rust
pub struct NoiseGenerator { seed: u64, perm: [u8; 512] }
```

Seeded generator with a 512-entry permutation table. Methods:

- **Perlin**: `perlin_1d(x)`, `perlin_2d(x, y)`, `perlin_3d(x, y, z)`, `perlin_4d(x, y, z, w)`
- **Simplex**: `simplex_1d(x)`, `simplex_2d(x, y)`, `simplex_3d(x, y, z)`
- **Worley**: `worley_2d(x, y, dist, f2)`, `worley_3d(x, y, z, dist, f2)` — `DistType::Euclidean|Manhattan|Chebyshev`, `f2` selects F2−F1 mode
- **Fractal**: `fbm(x, y, octaves, lac, pers, kind)`, `ridged(...)`, `turbulence(...)`
- **Advanced**: `warp_domain(x, y, strength)`, `generate_map(width, height, opts)`
- **Seed**: `new(seed)`, `set_seed(seed)`, `seed()`

Supporting enums: `NoiseKind` (`Perlin`, `Simplex`), `FractalType` (`Fbm`, `Ridged`, `Turbulence`), `DistType` (`Euclidean`, `Manhattan`, `Chebyshev`).

Config struct: `MapGenOptions` — `scale_x`, `scale_y`, `octaves`, `lacunarity`, `persistence`, `kind`, `fractal`, `offset_x`, `offset_y`.

### RandomGenerator

```rust
pub struct RandomGenerator { rng: Rng, seed: u64 }  // fastrand::Rng
```

Methods: `new` (OS entropy), `with_seed`, `random` (f64 [0,1)), `random_int` (inclusive), `random_float`, `random_normal` (Box-Muller), `set_seed`, `get_seed`, `get_state`/`set_state` (string serialization). Implements `Clone` (clone from same seed, not state copy) and `Default`.

### Transform

```rust
pub struct Transform { matrix: Mat3 }  // private field
```

`Mat3` wrapper with a fluent mutation API. Methods: `new` (identity), `from_components(x, y, angle, sx, sy, ox, oy, kx, ky)`, `translate`, `rotate`, `scale`, `shear`, `reset`, `set_transformation`, `transform_point`, `inverse_transform_point`, `inverse`, `matrix()`. All mutation methods return `&mut Self` for chaining. Implements `Copy`, `Clone`.

### Tween

```rust
pub struct TweenValue { start: f64, target: f64 }
pub struct Tween { duration: f64, easing_fn: fn(f32)->f32, easing_name: String, clock: f64, values: Vec<TweenValue> }
```

Multi-value interpolation driver. `Tween::new(duration, easing_name)` resolves easing case-insensitively with alias support (e.g. `"inquad"`, `"easeinquad"`, `"inQuad"` all resolve to `ease_in_quad`). Unknown names fall back to `linear`. Methods: `add_value(start, target)` → index, `update(dt)` → bool (complete?), `get_value(i)`, `get_all_values()`, `reset`, `set_time`, `is_complete`, `value_count`, `easing_name`, `duration`, `clock`.

### TweenValue

\ust
pub struct TweenValue { pub start: f64, pub target: f64 }
\
A single interpolated channel inside a Tween. start is the initial value and 	arget is the destination. Managed automatically by Tween::new and Tween::add_value.

### SpatialHash / SpatialItem

```rust
pub struct SpatialItem { pub id: String, pub x: f32, pub y: f32, pub w: f32, pub h: f32 }
pub struct SpatialHash { cell_size: f32, items: HashMap<String, SpatialItem>, buckets: HashMap<(i32,i32), HashSet<String>> }
```

Grid-based broad-phase spatial indexing. Methods: `new(cell_size)`, `insert(id, x, y, w, h)`, `remove(id)`, `update(id, x, y, w, h)`, `clear()`, `query_rect(x, y, w, h)`, `query_circle(cx, cy, radius)`, `query_segment(x1, y1, x2, y2)`, `cell_size()`, `item_count()`. Query methods return deduplicated ID lists.

### Functions (geometry.rs)

Free functions taking raw `f32` coordinates:

| Function | Signature | Description |
|----------|-----------|-------------|
| `angle_between` | `(x1, y1, x2, y2) -> f32` | Angle in radians from point 1 to point 2 |
| `circle_contains_point` | `(cx, cy, r, px, py) -> bool` | Point inside circle test |
| `circle_intersects_circle` | `(cx1, cy1, r1, cx2, cy2, r2) -> bool` | Circle-circle overlap |
| `circle_intersects_line` | `(cx, cy, r, x1, y1, x2, y2) -> bool` | Circle-infinite-line overlap |
| `circle_intersects_segment` | `(cx, cy, r, x1, y1, x2, y2) -> bool` | Circle-segment overlap |
| `polygon_area` | `(vertices: &[(f32,f32)]) -> f32` | Signed area (Shoelace formula) |
| `polygon_centroid` | `(vertices: &[(f32,f32)]) -> (f32,f32)` | Centroid via integration |
| `segment_intersects_segment` | `(...) -> (bool, Option<(f32,f32)>)` | Segment intersection with point |
| `closest_point_on_segment` | `(px,py, x1,y1, x2,y2) -> (f32,f32)` | Nearest point on segment |
| `point_in_polygon` | `(x, y, vertices) -> bool` | Ray-casting point-in-polygon |
| `line_intersect` | `(x1,y1, x2,y2, x3,y3, x4,y4) -> Option<(f32,f32)>` | Infinite line intersection |
| `bresenham` | `(x1, y1, x2, y2) -> Vec<(i32,i32)>` | Bresenham line rasterization |
| `convex_hull` | `(points: &[f32]) -> Vec<f32>` | Andrew's monotone chain (flat coords) |
| `delaunay_triangulate` | `(points: &[(f64,f64)]) -> Vec<[f64;6]>` | Bowyer-Watson triangulation |

### Functions (polygon.rs)

| Function | Signature | Description |
|----------|-----------|-------------|
| `triangulate` | `(polygon: &[Vec2]) -> Result<Vec<[Vec2;3]>, String>` | Ear-clipping, auto-CCW |
| `is_convex` | `(polygon: &[Vec2]) -> bool` | Cross-product sign consistency |

### DistType

```rust
pub enum DistType { Euclidean, Manhattan, Chebyshev }
```

Distance metric used by Worley/cellular noise. `Euclidean` uses standard distance, `Manhattan` uses taxicab distance, `Chebyshev` uses chessboard distance.

### FractalType

```rust
pub enum FractalType { Fbm, Ridged, PingPong, DomainWarpProgressive, DomainWarpIndependent }
```

Multi-octave fractal combinator type used with `NoiseGenerator`. Controls how successive octaves are combined.

### MapGenOptions

```rust
pub struct MapGenOptions { /* seed, noise type, fractal type, frequency, octaves, ... */ }
```

Configuration options for procedural map generation via `NoiseGenerator`. Bundles noise kind, fractal type, frequency, lacunarity, gain, and optional domain warp settings.

### NoiseKind

```rust
pub enum NoiseKind { Perlin, Simplex }
```

Selects the base noise algorithm for `NoiseGenerator`: `Perlin` for classic gradient noise, `Simplex` for smoother simplex noise.

### SpatialItem

```rust
pub struct SpatialItem { pub id: String, pub x: f32, pub y: f32, pub w: f32, pub h: f32 }
```

An item stored in a `SpatialHash`. `id` is a unique string identifier; `x`, `y`, `w`, `h` define its axis-aligned bounding box.

### DistType

```rust
pub enum DistType { Euclidean, Manhattan, Chebyshev }
```

Distance metric used by Worley/cellular noise. `Euclidean` uses standard distance, `Manhattan` uses taxicab distance, `Chebyshev` uses chessboard distance.

### FractalType

```rust
pub enum FractalType { Fbm, Ridged, PingPong, DomainWarpProgressive, DomainWarpIndependent }
```

Multi-octave fractal combinator type used with `NoiseGenerator`. Controls how successive octaves are combined.

### MapGenOptions

```rust
pub struct MapGenOptions { /* seed, noise type, fractal type, frequency, octaves, ... */ }
```

Configuration options for procedural map generation via `NoiseGenerator`. Bundles noise kind, fractal type, frequency, lacunarity, gain, and optional domain warp settings.

### NoiseKind

```rust
pub enum NoiseKind { Perlin, Simplex }
```

Selects the base noise algorithm for `NoiseGenerator`: `Perlin` for classic gradient noise, `Simplex` for smoother simplex noise.

### SpatialItem

```rust
pub struct SpatialItem { pub id: String, pub x: f32, pub y: f32, pub w: f32, pub h: f32 }
```

An item stored in a `SpatialHash`. `id` is a unique string identifier; `x`, `y`, `w`, `h` define its axis-aligned bounding box.

## Architecture Diagram

```
                          ┌───────────┐
                          │  mod.rs   │  re-exports all public items
                          └─────┬─────┘
    ┌───┬───┬───┬───┬───┬───┬──┴──┬───┬───┬───┬───┬───┬───┬───┐
    ▼   ▼   ▼   ▼   ▼   ▼   ▼     ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼
  vec2 mat3 rect color bezier easing geom noise noise poly rand spat xform tween
                                          _fn   _gen            _hash

Internal file dependencies:
  vec2       → (none)
  mat3       → vec2
  rect       → vec2
  color      → (none)
  bezier     → vec2
  easing     → (none)
  geometry   → (none — raw f32 coordinates)
  noise_fn   → (none)
  noise_gen  → (none)
  polygon    → vec2
  random     → fastrand (external)
  spatial_hash → std HashMap/HashSet, crate::engine::log_messages
  transform  → mat3
  tween      → easing (resolve_easing)
```

## Lua API Surface

Registered via `src/lua_api/math_api.rs` as `lurek.math`.

### Factory Functions

| Lua Function | Returns | Description |
|---|---|---|
| `lurek.math.newRandomGenerator(seed?)` | `RandomGenerator` | New RNG, optionally seeded |
| `lurek.math.newTransform(x?,y?,angle?,sx?,sy?,ox?,oy?,kx?,ky?)` | `Transform` | Affine transform (identity if no args) |
| `lurek.math.newBezierCurve(points)` | `BezierCurve` | From flat `{x1,y1, x2,y2, ...}` table (≥ 4 numbers) |
| `lurek.math.newTween(duration, easingName?)` | `Tween` | Multi-value interpolation driver |
| `lurek.math.newSpatialHash(cellSize)` | `SpatialHash` | Grid-based spatial query structure |
| `lurek.math.newNoiseGenerator(seed?)` | `NoiseGenerator` | Seeded procedural noise generator |

### Free Noise Functions

| Lua Function | Description |
|---|---|
| `lurek.math.perlin2d(x, y, seed?)` | 2D Perlin noise |
| `lurek.math.perlin3d(x, y, z, seed?)` | 3D Perlin noise |
| `lurek.math.simplex2d(x, y, seed?)` | 2D Simplex noise |
| `lurek.math.fbm(x, y, seed?, octaves?, lac?, gain?)` | Fractal Brownian motion |

### Easing Functions

`lurek.math.applyEasing(name, t)` — case-insensitive lookup across all 22 easing names.

22 individual functions: `linear`, `inQuad`, `outQuad`, `inOutQuad`, `inCubic`, `outCubic`, `inOutCubic`, `inQuart`, `outQuart`, `inOutQuart`, `inSine`, `outSine`, `inOutSine`, `inExpo`, `outExpo`, `inOutExpo`, `inElastic`, `outElastic`, `outBounce`, `inBounce`, `inBack`, `outBack`.

### Geometry / Color Functions

| Lua Function | Returns | Description |
|---|---|---|
| `lurek.math.triangulate(polygon)` | table of triangle tables | Ear-clipping triangulation (flat `{x1,y1,...}` input) |
| `lurek.math.isConvex(polygon)` | boolean | Convexity test (flat input) |
| `lurek.math.gammaToLinear(c)` | number | sRGB → linear color space |
| `lurek.math.linearToGamma(c)` | number | Linear → sRGB color space |

### UserData Methods — RandomGenerator

| Method | Returns | Description |
|---|---|---|
| `random()` | number | Uniform [0, 1) |
| `randomFloat(min, max)` | number | Uniform [min, max) |
| `randomInt(min, max)` | integer | Uniform [min, max] inclusive |
| `randomNormal(stddev?, mean?)` | number | Gaussian (defaults: σ=1, μ=0) |
| `getSeed()` | integer | Current seed |
| `setSeed(seed)` | nil | Reset to new seed |
| `getState()` | string | Serialise full state |
| `setState(state)` | nil | Restore serialised state |

### UserData Methods — Transform

| Method | Returns | Description |
|---|---|---|
| `translate(dx, dy)` | nil | Apply translation |
| `rotate(angle)` | nil | Apply rotation (radians) |
| `scale(sx, sy?)` | nil | Apply scale (uniform if sy omitted) |
| `shear(kx, ky)` | nil | Apply shear |
| `reset()` | nil | Reset to identity |
| `setTransformation(x, y, angle?, sx?, sy?, ox?, oy?, kx?, ky?)` | nil | Full replacement |
| `transformPoint(x, y)` | number, number | Local → world |
| `inverseTransformPoint(x, y)` | number, number | World → local |
| `inverse()` | Transform | New inverse transform |
| `clone()` | Transform | Deep copy |
| `getMatrix()` | table | Flat 9-element row-major table |

### UserData Methods — BezierCurve

| Method | Returns | Description |
|---|---|---|
| `evaluate(t)` | number, number | Point at parameter t |
| `render(segments)` | table | Polyline as `{{x,y}, ...}` |
| `getDerivative()` | BezierCurve | First derivative curve |
| `getControlPoint(index)` | number?, number? | 1-based; nil if out of range |
| `setControlPoint(index, x, y)` | boolean | Success flag |
| `insertControlPoint(x, y, index?)` | nil | Insert at position |
| `removeControlPoint(index)` | boolean | False if would go below 2 |
| `getControlPointCount()` | integer | Number of control points |
| `length()` | number | Approximate arc length |
| `translate(dx, dy)` | nil | Translate all points |
| `rotate(angle, ox, oy)` | nil | Rotate around pivot |
| `scale(s, ox, oy)` | nil | Scale around pivot |

### UserData Methods — Tween

| Method | Returns | Description |
|---|---|---|
| `update(dt)` | boolean | Advance clock; true when complete |
| `reset()` | nil | Reset clock to 0 |
| `getValue(index)` | number | Interpolated value (1-based) |
| `getAllValues()` | table | All interpolated values |
| `isComplete()` | boolean | Whether tween finished |
| `getValueCount()` | integer | Number of value pairs |
| `getEasingName()` | string | Resolved easing name |
| `getDuration()` | number | Total duration in seconds |
| `getTime()` | number | Current clock time |
| `setTime(t)` | nil | Jump to time (clamped) |
| `addValue(start, target)` | integer | Add pair, returns 1-based index |

### UserData Methods — SpatialHash

| Method | Returns | Description |
|---|---|---|
| `insert(id, x, y, w, h)` | nil | Insert an AABB item |
| `update(id, x, y, w, h)` | nil | Update existing item's AABB |
| `remove(id)` | nil | Remove by ID |
| `clear()` | nil | Remove all items |
| `queryRect(x, y, w, h)` | table | IDs overlapping query rect |
| `queryCircle(cx, cy, radius)` | table | IDs overlapping query circle |
| `getCellSize()` | number | Grid cell size |
| `getItemCount()` | integer | Total item count |

### UserData Methods — NoiseGenerator

| Method | Returns | Description |
|---|---|---|
| `perlin1d(x)` | number | 1D Perlin noise |
| `perlin2d(x, y)` | number | 2D Perlin noise |
| `perlin3d(x, y, z)` | number | 3D Perlin noise |
| `perlin4d(x, y, z, w)` | number | 4D Perlin noise |
| `simplex1d(x)` | number | 1D Simplex noise |
| `simplex2d(x, y)` | number | 2D Simplex noise |
| `simplex3d(x, y, z)` | number | 3D Simplex noise |
| `worley2d(x, y, distType?, f2?)` | number | 2D Worley/cellular noise |
| `worley3d(x, y, z, distType?, f2?)` | number | 3D Worley/cellular noise |
| `fbm(x, y, octaves?, lac?, pers?, kind?)` | number | Fractal Brownian motion |
| `ridged(x, y, octaves?, lac?, pers?, kind?)` | number | Ridged multi-fractal |
| `turbulence(x, y, octaves?, lac?, pers?, kind?)` | number | Turbulence noise |
| `warpDomain(x, y, strength)` | number, number | Domain-warped coordinates |
| `generateMap(w, h, opts?)` | table | Flat row-major noise map |
| `getSeed()` | integer | Current seed |
| `setSeed(seed)` | nil | Set seed, rebuild permutation |


### Additional API

| Function | Description |
|---|---|
| `abs(x)` | Absolute value |
| `acos(x)` | Arc cosine (radians) |
| `angleBetween(x1,y1,x2,y2)` | Angle from point 1 to point 2 (radians) |
| `atan(y, x?)` | Arc tangent; two-arg form = atan2 |
| `atan2(y, x)` | Arc tangent of y/x (radians) |
| `bresenham(x0,y0,x1,y1)` | Bresenham line integer grid points |
| `ceil(x)` | Ceiling (round up to nearest integer) |
| `circleContainsPoint(cx,cy,r,px,py)` | True if point is inside circle |
| `circleIntersectsCircle(ax,ay,ar,bx,by,br)` | True if two circles overlap |
| `circleIntersectsLine(cx,cy,r,x1,y1,x2,y2)` | True if circle intersects infinite line |
| `circleIntersectsSegment(cx,cy,r,x1,y1,x2,y2)` | True if circle intersects segment |
| `closestPointOnSegment(px,py,ax,ay,bx,by)` | Nearest point on segment to point |
| `convexHull(points)` | Convex hull of a point cloud |
| `cos(x)` | Cosine (radians) |
| `deg(x)` | Radians to degrees |
| `delaunayTriangulate(points)` | Delaunay triangulation of point cloud |
| `distance(x1,y1,x2,y2)` | Euclidean distance between two points |
| `distanceSq(x1,y1,x2,y2)` | Squared distance (avoids sqrt) |
| `exp(x)` | e^x |
| `floor(x)` | Floor (round down to nearest integer) |
| `fmod(x, y)` | Floating-point modulo |
| `huge` | Infinity constant (math.huge) |
| `lerp(a, b, t)` | Linear interpolation from a to b by t |
| `lineIntersect(ax,ay,bx,by,cx,cy,dx,dy)` | Intersection point of two infinite lines |
| `log(x, base?)` | Natural log or log base |
| `pointInPolygon(px,py,vertices)` | True if point is inside polygon |
| `polygonArea(vertices)` | Signed area of polygon |
| `polygonCentroid(vertices)` | Centroid (cx, cy) of polygon |
| `pow(x, y)` | x raised to power y |
| `segmentIntersectsSegment(ax,ay,bx,by,cx,cy,dx,dy)` | True if two segments intersect |
| `sign(x)` | Sign of x: -1, 0, or 1 |
| `simplexNoise(x, y?)` | 1D or 2D simplex noise value |
| `sqrt(x)` | Square root |
| `tan(x)` | Tangent (radians) |
| `tau` | 2*pi constant |

## Invariants

1. `Vec2`, `Mat3`, `Rect`, `Color`, `Transform` are all `Copy` — no heap allocation, safe to pass by value in per-frame code.
2. `Color::new` is `const` and clamps all components to `[0.0, 1.0]` at construction.
3. `Vec2::normalize` returns a zero vector when length is zero — never produces `NaN`.
4. `Mat3::inverse` returns the identity matrix when the determinant is zero (degenerate input).
5. `BezierCurve::new` panics if constructed with fewer than 2 control points. All indices in the Lua API are 1-based.
6. `RandomGenerator::clone()` produces a fresh generator from the same seed, not a copy of the current internal state.
7. `Tween::new` resolves easing names case-insensitively with alias support; unknown names fall back to `linear` silently.
8. `SpatialHash::query_*` returns deduplicated ID lists — an item spanning multiple grid cells appears exactly once.
9. `NoiseGenerator` is fully deterministic for the same seed — output is reproducible across runs and platforms.
10. `triangulate` ensures CCW winding order; CW input is automatically reversed before ear-clipping.
11. `gamma_to_linear` / `linear_to_gamma` implement the IEC 61966-2-1 sRGB transfer function with the linear segment below the 0.04045 threshold.

## Dependencies

- **External crate**: `fastrand` — used by `RandomGenerator` for fast PRNG.
- **Internal**: `crate::engine::log_messages` — used by `SpatialHash` for log-message constants (`HX01`, `HX02`) only. No logic dependency on the engine module.
- **Downstream**: every Lurek2D module may import `crate::math::*`.

## Testing

### Rust Integration Tests

**File**: `tests/unit/math_tests.rs` — 857 lines, ~60+ `#[test]` functions.

| Domain | Tests |
|--------|-------|
| Vec2 | addition, subtraction, scalar mul, length, normalize, dot, distance, lerp |
| Mat3 | identity, translation, rotation, shear, inverse (identity, translation, rotation, composite roundtrips), `from_row_major` |
| Rect | construction, contains |
| Color | `gamma_to_linear`↔`linear_to_gamma` roundtrip, known values, boundary (0.0, 1.0) |
| Easing | all-start-at-zero, most-end-at-one, unknown returns None, individual midpoints (quad, cubic, quart, sine, expo, elastic, bounce) |
| Noise | Perlin deterministic, Simplex deterministic, varies with position, fbm single-octave matches perlin, 3D/4D deterministic + range, remapped [0,1] |
| Random | same seed same sequence, different seeds differ, int/float range, normal distribution mean, seed reset, state save/restore, clone independence |
| Transform | identity, translate, rotate 90°, scale, chaining, inverse roundtrip, reset, from_components, clone independence |
| BezierCurve | endpoint evaluation, midpoint quadratic, render segment count, render_segment range, derivative reduction, control-point CRUD, translate, scale |
| Polygon | triangulate triangle/square/concave-L-shape, too-few-vertices error, is_convex triangle/square/concave |

### Lua BDD Tests

**File**: `tests/lua/unit/test_math.lua` — 128 lines, ~20 `it` blocks.

Covers: constants (`pi`), trigonometry (`sin`, `cos`, `tan`, `atan2`), basic functions (`sqrt`, `abs`, `floor`, `ceil`), `min`/`max`/`clamp`, `distance`, `random`.

### Inline Tests (`#[cfg(test)]`)

| File | Scope |
|------|-------|
| `easing.rs` | Boundary and midpoint verification for all 22 functions |
| `tween.rs` | Linear tween, complete flag, reset, quad easing curve, multiple values, unknown easing fallback |
| `spatial_hash.rs` | Insert+query, miss, remove, circle filter, multiple items same cell |
| `geometry.rs` | `angle_between`, `circle_contains_point`, `circle_intersects_circle`, `segment_intersects_segment` |
| `noise_generator.rs` | Deterministic same-seed, different-seeds-differ |

## Sync Contracts

| This File | Must Stay in Sync With | What to Check |
|-----------|----------------------|---------------|
| `mod.rs` re-exports | All submodule `pub` items | Every new public type/function must be re-exported |
| `easing.rs` function list | `math_api.rs` easing bindings | New easing → add Lua binding |
| Source types | `math_api.rs` UserData impls | New Rust method → add Lua method |
| `noise_generator.rs` methods | `math_api.rs` LuaNoiseGenerator | New noise method → add Lua binding |
| `spatial_hash.rs` methods | `math_api.rs` LuaSpatialHash | New query method → add Lua binding |
| `tween.rs` methods | `math_api.rs` LuaTween | New tween method → add Lua binding |
| All public API | `tests/unit/math_tests.rs` | New public item → at least one test |
| All `lurek.math.*` functions | `tests/lua/unit/test_math.lua` | New Lua function → at least one Lua test |

## Extension Points

- **New easing function**: add the function to `easing.rs`, add a match arm in `apply()`, expose as `tbl.set("name", ...)` in `math_api.rs`.
- **New noise type**: add a method to `NoiseGenerator`, expose in `LuaNoiseGenerator` UserData methods in `math_api.rs`.
- **New geometry function**: add to `geometry.rs`, expose via a `tbl.set(...)` in the register function of `math_api.rs`.
- **New UserData type**: create a `Lua*` wrapper struct implementing `LuaUserData`, add a `new*` factory function in the register function. Follow the pattern of `LuaTween` or `LuaSpatialHash`.

## Submodules

### `vec2` — 2D Vector
- `Vec2` — Copy 2D vector with arithmetic overloads, normalization, dot, lerp, rotate, directional constants.

### `mat3` — 3×3 Matrix
- `Mat3` — Row-major affine matrix: identity, translation, rotation, scale, shear, inverse, multiply.

### `rect` — Axis-Aligned Bounding Box
- `Rect` — AABB with center, area, contains, and intersects.

### `color` — sRGB Color
- `Color` — Clamped sRGB `[f32; 4]` with named constants, `from_u8`, `to_u8`, gamma conversion.

### `bezier` — Bézier Curves
- `BezierCurve` — Arbitrary-order De Casteljau curve with render, derivative, and arc-length methods.

### `easing` — Easing Functions
- 22 named easing functions + case-insensitive `apply(name, t)` dispatcher.

### `geometry` — Geometry Functions
- Free functions: angle, circle tests, polygon area/centroid, segment intersection, Bresenham, convex hull, Delaunay triangulation, point-in-polygon, line intersect.

### `noise_functions` — Standalone Noise
- Free functions: `perlin2d`/`3d`/`4d`, `simplex2d`, `simplex_noise_2d`/`3d`, `fbm`.

### `noise_generator` — Seeded Noise Generator
- `NoiseGenerator` — Seeded Perlin/Simplex/Worley generator with fractal combinators and map generation.
- `NoiseKind` — `Perlin` or `Simplex` base algorithm selection.
- `FractalType` — `Fbm`, `Ridged`, `PingPong`, `DomainWarpProgressive`, `DomainWarpIndependent`.
- `DistType` — `Euclidean`, `Manhattan`, or `Chebyshev` distance metric for Worley noise.
- `MapGenOptions` — Configuration for procedural 2D map generation.

### `polygon` — Polygon Utilities
- `triangulate(polygon)` — Ear-clipping triangulation with auto-CCW enforcement.
- `is_convex(polygon)` — Cross-product consistency convexity test.

### `random` — Pseudorandom Number Generator
- `RandomGenerator` — fastrand wrapper with normal distribution and state serialization.

### `spatial_hash` — Grid Spatial Index
- `SpatialHash` — Grid-based broad-phase spatial index with rect/circle/segment queries.
- `SpatialItem` — Stored item with string ID and AABB.

### `transform` — Affine Transform
- `Transform` — Fluent `Mat3` wrapper with translate/rotate/scale/shear/reset API.

### `tween` — Math-Level Interpolation
- `Tween` — Multi-value interpolation driver with easing name resolution.
- `TweenValue` — Single interpolated channel (start, target f64 pair).

---

## Lua Examples

```lua
-- Easing and interpolation
print(lurek.math.applyEasing("cubicOut", 0.5))  -- ~0.875

-- Random number generator
local rng = lurek.math.newRandomGenerator(42)
print(rng:randomInt(1, 6))        -- dice roll
print(rng:randomNormal(1.0, 0.0)) -- Gaussian sample

-- Affine transform
local t = lurek.math.newTransform()
t:translate(100, 200)
t:rotate(math.pi / 4)
local px, py = t:transformPoint(10, 0)

-- Bézier curve
local curve = lurek.math.newBezierCurve({0,0, 100,0, 100,100, 200,100})
local pt = curve:evaluate(0.5)   -- midpoint

-- Spatial hash
local sh = lurek.math.newSpatialHash(64)
sh:insert("player", 100, 200, 32, 32)
sh:insert("enemy",  150, 210, 32, 32)
local hits = sh:queryRect(90, 190, 100, 100)
for _, id in ipairs(hits) do print("near:", id) end

-- Noise
local gen = lurek.math.newNoiseGenerator(12345)
local v = gen:perlin2d(1.23, 4.56)
print(string.format("noise: %.4f", v))

-- Polygon triangulation
local tris = lurek.math.triangulate({0,0, 100,0, 50,80})
for _, tri in ipairs(tris) do
    -- tri is a table of 3 {x,y} points
end
```

## Item Summary

| Kind                | Count |
|---------------------|-------|
| Structs             | 9     |
| Enums               | 4     |
| Free Functions      | 20+   |
| Functions (Lua API) | 60+   |
| **Total**           | **90+** |

## References

| Module       | Relationship                                                                 |
|--------------|------------------------------------------------------------------------------|
| `runtime`    | `spatial_hash.rs` imports `crate::runtime::log_messages` for log constants. |
| `tween`      | `src/tween/state.rs` imports `crate::math::easing` for easing resolution.   |
| `render`     | Imports `Color`, `Vec2`, `Mat3`, `Rect` as foundational geometry types.      |
| `physics`    | Imports `Vec2` for rigid-body positions and impulse vectors.                 |
| `camera`     | Imports `Vec2`, `Mat3`, `Rect` for viewport transform computations.          |
| `lua_api`    | `math_api.rs` registers all UserData and free functions under `lurek.math`.  |
| All modules  | `Vec2`, `Mat3`, `Rect`, `Color` are imported by virtually every other module. |

## Notes

- **Baseline leaf**: `math` has zero internal Lurek2D dependencies (except `crate::runtime::log_messages` in `spatial_hash.rs`). It is safe to import from any tier.
- **`Copy` types**: `Vec2`, `Mat3`, `Rect`, `Color`, `Transform` are all `Copy` — no heap allocation on use.
- **`math::Tween` vs `tween` module**: `src/math/tween.rs` is a low-level single-value interpolation primitive. The full property-animation system lives in `src/tween/` (Tier 1).
- **Easing alias support**: All 22 easing names accept multiple capitalisation forms (e.g. `"cubicOut"`, `"outCubic"`, `"CubicOut"`) via the `apply(name, t)` dispatcher.
- **Breaking change surface**: Removing a named easing function or changing geometry function signatures is a breaking change for any Lua scripts using `lurek.math.*`.
