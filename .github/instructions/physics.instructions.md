---
applyTo: "src/physics/**"
---

# Physics Module Instructions

`src/physics/` owns AABB collision detection, rigid body simulation, world gravity, and impulse resolution. All physics operates in world-space pixel coordinates at `f32` precision.

## Core Rules

- **AABB only** — no circle-circle or polygon collision; all bodies are axis-aligned rectangles
- **Body::new signature**: `Body::new(x: f32, y: f32, body_type: BodyType)` — not `(Vec2, BodyType)`
- **BodyType variants**: `Dynamic` (affected by gravity and collision) and `Static` (immovable, infinite mass)
- **World::step(dt: f32)**: apply gravity → update positions → resolve collisions in that order every frame
- **Impulse resolution**: use coefficient of restitution (`body.restitution`) for bounce; default `0.3`

## Layer / Boundary Rules

- `physics/` must NOT import from `graphics/`, `audio/`, `lua_api/`, `input/`, or `timer/`
- `physics/` may import from `math/` for `Vec2` and `Rect`
- Collision detection logic lives in `collision.rs` — `world.rs` calls `collision::detect_aabb()`
- `Body` exposes `bounding_box() -> Rect` for use by the collision system

## Compliance

- `World::body_count() -> usize` must remain public and return accurate body count
- `World::get_body()` and `World::get_body_mut()` return `Option<&Body>` / `Option<&mut Body>`
- Split borrow pattern required for collision: `self.bodies.split_at_mut(j)` — no unsafe pointer tricks

## Avoid

- Implementing CPU-expensive broad-phase queries — simple O(n²) is acceptable for Luna2D scale
- Storing `Vec2` positions as `i32` — keep `f32` throughout
- Gravity stored as `f32` hardcoded — always use `World.gravity: Vec2`
- Adding `Body::new(Vec2, BodyType)` overload — that was a previous bug; always use `(f32, f32, BodyType)`
- Physics sleeping / island detection — scope is intentionally minimal
