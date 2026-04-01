# src/image/

CPU-side pixel-level image manipulation.

## What This Module Contains

ImageData for reading and writing individual pixels in RGBA8 format. Used for procedural texture generation and pixel-level operations outside the GPU pipeline.

## Files

| File | Purpose |
|------|---------|
| `image_data.rs` | `ImageData` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/image_tests.rs, tests/stress/image_stress_tests.rs`
- **Lua API bindings**: `src/lua_api/image_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
