# src/physics/

Physics simulation backed by rapier2d for rigid-body dynamics.

## What This Module Contains

World manages the rapier2d physics pipeline (gravity, stepping, collision detection). Body represents rigid bodies (dynamic, static, kinematic) with circle and rectangle shapes. Shape defines collider geometry. CollisionInfo records contact events. Supports sensors, raycasting, joints, force/impulse application, and velocity control.

## Files

| File | Purpose |
|------|---------|
| `body.rs` | `Body` implementation |
| `collision.rs` | `Collision` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `shape.rs` | `Shape` implementation |
| `world.rs` | `World` implementation |

## Navigation

- **Owner agent**: `Physicist`
- **Tests**: `tests/physics_tests.rs, tests/stress/physics_stress_tests.rs`
- **Lua API bindings**: `src/lua_api/physics_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
