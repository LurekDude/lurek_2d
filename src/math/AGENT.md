# math

## Module Info
- Module name: `math`
- Module group: `Foundations`
- Spec path: `docs/specs/math.md`
- Lua API path(s): `src/lua_api/math_api.rs`
- Rust test path(s): `tests/rust/unit/math_tests.rs`; inline tests in `src/math/vec2.rs`, `src/math/mat3.rs`, `src/math/rect.rs`, `src/math/color.rs`, `src/math/bezier.rs`, `src/math/easing.rs`, `src/math/geometry.rs`, `src/math/noise_functions.rs`, `src/math/noise_generator.rs`, `src/math/polygon.rs`, `src/math/random.rs`, `src/math/spatial_hash.rs`, `src/math/transform.rs`, `src/math/tween.rs`
- Lua test path(s): `tests/lua/unit/test_math.lua`

## Module Purpose
The `math` module is Lurek2D's shared foundation for numeric types and algorithms that many higher-level systems depend on. It owns the engine's core 2D value types such as vectors, matrices, rectangles, and colors, plus reusable geometric helpers, easing curves, seeded randomness, procedural noise, and broad-phase spatial indexing.

This module exists so rendering, physics, animation, UI, pathfinding, and Lua bindings can share one consistent set of primitives instead of re-implementing math logic in each subsystem. Its APIs are mostly pure, lightweight, and allocation-conscious, which makes them safe to use in hot update and render paths.

`math` intentionally does not own engine state, ECS data, resource handles, scene objects, or frame scheduling. It provides building blocks like `Tween`, `Transform`, and `SpatialHash`, but it does not own the higher-level animation system in `src/tween/`, scene transforms, or gameplay orchestration.

## Files
- `mod.rs`: Re-exports the public math surface so other modules and the Lua bridge can depend on one stable module root.
- `vec2.rs`: Defines the engine's primary 2D vector type and common arithmetic, direction, interpolation, and geometric helpers.
- `mat3.rs`: Implements the 3x3 affine matrix used for 2D transforms, point transforms, composition, and inversion.
- `rect.rs`: Provides axis-aligned rectangles for overlap, containment, and intersection queries used across gameplay and rendering code.
- `color.rs`: Defines the shared RGBA value type plus byte conversion, packed RGB output, HSV conversion, and gamma helpers.
- `bezier.rs`: Implements arbitrary-order Bezier curves with evaluation, derivative, editing, rendering, and transform helpers.
- `easing.rs`: Houses the named easing curve functions and the string-based dispatcher used by tweening code and Lua bindings.
- `geometry.rs`: Collects free-standing geometry utilities such as circle tests, polygon measurements, segment tests, line rasterization, convex hull, and triangulation helpers.
- `noise_functions.rs`: Exposes standalone Perlin, Simplex, and FBM helpers for callers that do not need a reusable generator object.
- `noise_generator.rs`: Owns the seeded `NoiseGenerator` and the richer procedural toolset for Perlin, Simplex, Worley, fractal layering, domain warping, and map generation.
- `polygon.rs`: Provides polygon-specific helpers centered on convexity testing and ear-clipping triangulation.
- `random.rs`: Wraps `fastrand` in a deterministic, serializable RNG API that matches engine and Lua expectations.
- `spatial_hash.rs`: Implements a uniform-grid broad-phase index for fast rectangle, circle, and segment spatial queries.
- `transform.rs`: Wraps `Mat3` in a mutable 2D transform object with chainable translate, rotate, scale, and shear operations.
- `tween.rs`: Implements low-level numeric interpolation over one or more values and explicitly stays below the higher-level `src/tween/` feature system.

## Key Types
- `Vec2`: Core 2D vector used pervasively for positions, directions, offsets, and interpolation. It is the default math currency for most engine subsystems.
- `Mat3`: Affine 2D matrix for transform composition and point mapping. Higher-level transform code builds on this instead of rolling custom matrix math.
- `Rect`: Axis-aligned rectangle for cheap containment and overlap checks. It is the basic AABB type used by layout and collision-adjacent code.
- `Color`: Shared RGBA value type for color transport across rendering-facing APIs. It keeps color conversion logic out of renderer-specific code.
- `BezierCurve`: Editable Bezier curve object for path sampling, tangents, and authorable curve manipulation. It supports both math-heavy tooling and Lua scripting use cases.
- `RandomGenerator`: Deterministic RNG wrapper with seed and state control. It exists so engine code and Lua scripts can reproduce runs reliably.
- `NoiseGenerator`: Seeded procedural noise engine with multiple algorithms and fractal modes. It centralizes world-generation style noise work instead of scattering implementations.
- `NoiseKind`: Selects the base noise family for generator and fractal operations. It keeps algorithm switching explicit at call sites.
- `FractalType`: Selects how multiple octaves are combined when generating layered noise. It distinguishes smooth FBM from ridged or turbulence-style outputs.
- `DistType`: Selects the distance metric used by Worley noise queries. This lets callers choose the visual character of cellular patterns without changing generator internals.
- `MapGenOptions`: Bundles the parameters for 2D map generation into one stable config object. It prevents wide argument lists in higher-level generation code.
- `SpatialItem`: Stored record for an object indexed by `SpatialHash`. It keeps the query structure decoupled from any particular gameplay object type.
- `SpatialHash`: Broad-phase query structure for coarse spatial lookup by AABB, circle, or segment. It is a utility index, not a full collision or physics system.
- `Transform`: Mutable 2D transform object that exposes a script-friendly API over `Mat3`. It is the ergonomic surface for composition and point conversion.
- `TweenValue`: Holds one start-target numeric pair inside a low-level tween. It is intentionally minimal and exists mainly to support `Tween`.
- `Tween`: Low-level multi-channel numeric interpolator driven by easing functions and an internal clock. It does not own callbacks, sequences, or property animation workflows.