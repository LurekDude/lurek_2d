---
description: "Create a new physics body type or collision behavior in the physics engine."
---

# Create Physics Feature

## Purpose

Add a new physics feature: body type, collision shape, force type, or constraint.

## Inputs

- **Feature**: What physics capability to add
- **Body types affected**: Static, Dynamic, Kinematic, or new type
- **Collision behavior**: How it interacts with existing bodies

## Steps

1. Read current physics code in `src/physics/`
2. Design the feature respecting module isolation (physics depends only on math)
3. Implement in appropriate file (body.rs, collision.rs, or world.rs)
4. Add Lua binding in `src/lua_api/physics_api.rs`
5. Write physics tests with float tolerance assertions
6. Run `cargo test` and `cargo clippy`

## Acceptance

- [ ] Physics module depends only on `math`
- [ ] Float comparisons use tolerance
- [ ] Body IDs remain stable
- [ ] Tests cover edge cases
- [ ] `cargo test` passes

## References

- `physics-engine` skill
- `src/physics/` module
