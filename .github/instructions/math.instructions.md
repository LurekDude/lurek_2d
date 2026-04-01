---
applyTo: "src/math/**"
---

# Math Module Instructions

Rules for working on `src/math/` — the core math library.

## Module Rules

- `math` is a **leaf dependency** — it must NOT depend on any other Luna2D module
- All other modules MAY depend on `math`
- All computation is pure CPU math — no GPU, window, or audio imports
- Float comparisons in tests: use `(a - b).abs() < 1e-5` — never `assert_eq!` on `f32`/`f64`

## Public Types

- `Vec2` — 2D vector (x, y) with full operator overloading
- `Mat3` — 3x3 matrix for 2D affine transforms
- `Rect` — axis-aligned bounding rectangle
- `Bezier` — cubic Bézier curve evaluation
- `Easing` — standard easing functions (linear, quad, cubic, sine, etc.)
- `Noise` — Perlin/simplex noise generation
- `Polygon` — convex/concave polygon operations
- `SpatialHash` — grid-based spatial partitioning for broad-phase queries
- `Tween` — property animation with easing
- Raycasting — ray-segment and ray-circle intersection

## Dependency Direction

- `math` depends on: nothing (leaf module)
- Everything else may depend on `math`

## Testing

- Tests in `tests/math_tests.rs` and `tests/math_ext_tests.rs`
- Float comparison: `assert!((val - expected).abs() < 1e-5)`
- Test edge cases: zero vectors, identity matrices, degenerate rects
- Verify Vec2 operations: add, sub, mul, normalize, dot, cross, distance, angle
