# src/particle/

Emitter-based 2D particle effects system.

## What This Module Contains

ParticleSystem spawns short-lived particles each frame with position, velocity, lifetime, and visual properties. Supports multi-stop color/size interpolation, emission shapes (point, circle, rectangle, cone), gravity, and texture-based rendering.

## Files

| File | Purpose |
|------|---------|
| `mod.rs` | Module root — re-exports and module-level docs |
| `system.rs` | `System` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/particle_tests.rs`
- **Lua API bindings**: `src/lua_api/particle_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
