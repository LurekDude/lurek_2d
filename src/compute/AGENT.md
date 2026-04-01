# src/compute/

Dense N-dimensional numerical arrays with NumPy-style operations.

## What This Module Contains

NdArray supports 1D/2D/3D row-major arrays with float32, float64, and int32 element types. Provides element-wise arithmetic, broadcasting, slicing, reshaping, reduction (sum/mean/min/max), and linear algebra basics.

## Files

| File | Purpose |
|------|---------|
| `array.rs` | `Array` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `ops.rs` | `Ops` implementation |
| `spatial.rs` | `Spatial` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/compute_tests.rs, tests/stress/compute_stress_tests.rs`
- **Lua API bindings**: `src/lua_api/compute_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
