# IDEA.md — `math` module

> Migrated from `ideas/features/math.md` and `ideas/performance/13-math-simd-noise.md`.
> Status checked against `src/math/` and `src/lua_api/math_api.rs`.
> Lua namespace: `lurek.math`.

---

## Features

### ✅ DONE — Vec3
**Source**: features/math.md — Feature Gaps #1

`Vec3` and `LuaVec3` implemented in `math_api.rs` (lines ~176–240). Supports normalize,
dot, cross, lerp. Previous feature note referenced only a stub — it is now complete.

---

### ✅ DONE — Catmull-Rom Spline + Hermite Spline
**Source**: features/math.md — Feature Gaps #3 / Suggestions #2

`CatmullRomSpline` and `HermiteSpline` imported in `math_api.rs` (line ~22).

---

### ❌ TODO — Polygon Boolean Operations
**Source**: features/math.md — Feature Gaps #2

No polygon union/intersection/difference found. Common for destructible terrain, visibility
polygons, and 2D CSG. Requires a suitable Rust library (e.g., `geo`/`i_overlay`).

---

### ✅ DONE — Polygon Clipping (Sutherland-Hodgman)
**Source**: features/math.md — Feature Gaps #6

`lurek.math.polygonClip(polygon, nx, ny, d)` added in `math_api.rs`.
Sutherland-Hodgman single half-plane clip implemented in `src/math/polygon.rs`.
Input: flat `{x1,y1,...}` table; output: flat clipped polygon table.

---

### ❌ TODO — Voronoi Tessellation
**Source**: features/math.md — Feature Gaps #5

`procgen` module has brute-force Voronoi. `math` should own the Delaunay-dual Voronoi
primitive (`voronoi_from_delaunay()`). Move or duplicate algorithmic core here.

---

### ✅ DONE — AABB Tree
**Source**: features/math.md — Feature Gaps #7

`AabbTree` in `src/math/aabb_tree.rs` — dynamic BVH using the Box2D "best first"
surface-area heuristic for sibling selection.  Handles insert, remove, query, queryPoint,
update, contains, len, clear.  `LuaAabbTree` wrapper in `src/lua_api/math_api.rs`.
Exposed as `lurek.math.aabbTree()` with full method set.

---

### ⚠️ FIXME — Remove `log_messages` Dependency from `SpatialHash`
**Source**: features/math.md — Structural Issues

`src/math/spatial_hash.rs` imports `crate::engine::log_messages` (or similar), breaking the
leaf-module invariant. Either remove the log call or gate it behind a cfg feature. Math must
remain a zero-dependency leaf so all other modules can safely import it.

---

## Performance

### 🔇 LOW — SIMD Noise Acceleration
**Source**: performance/13-math-simd-noise.md

Perlin noise generation is scalar. SIMD (via `std::simd` or `packed_simd2`) could speed up
batch noise generation (terrain gen, per-pixel effects). Priority: **LOW** — only relevant
for large procedural maps. Profile before investing here.
