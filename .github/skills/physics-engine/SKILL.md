---
name: physics-engine
description: "Load this skill when working on Luna2D physics: AABB collision detection, rigid body simulation, world stepping, impulse resolution, or body types. Skip it for rendering, audio, or Lua scripting."
---

# Physics Engine — Luna2D Engine

## Load When

- Modifying `src/physics/` module code
- Implementing collision detection or response
- Working on body types (Static, Dynamic, Kinematic)
- Debugging physics behavior (tunneling, jittering, stuck bodies)

## Owns

- AABB collision detection algorithm
- Impulse-based collision response
- Rigid body simulation (velocity, acceleration, forces)
- Body type behavior (Static, Dynamic, Kinematic)
- World container and step function

## Does Not Cover

- Collision visualization → use `software-rendering` skill
- Physics API naming → use `lua-api-design` skill
- Complex joints or constraints → not yet implemented

## Live Repository Contracts

- `src/physics/body.rs` — `Body` struct, `BodyType` enum
- `src/physics/collision.rs` — `CollisionInfo`, AABB intersection
- `src/physics/world.rs` — `World` struct, `step()` function
- `src/math/vec2.rs` — `Vec2` for positions, velocities, forces
- `src/math/rect.rs` — `Rect` for AABB bounds

## Decision Rules

- **AABB only**: Axis-aligned bounding boxes for collision detection — no rotated or circular colliders yet
- **Impulse resolution**: Apply equal and opposite impulses at collision; conserve momentum
- **Body types**: Static (mass=∞, never moves), Dynamic (full simulation), Kinematic (user-controlled velocity)
- **Force clearing**: Clear accumulated forces after each world step
- **Float tolerance**: Use epsilon comparisons (`(a-b).abs() < EPSILON`) — never `==` on floats
- **Module isolation**: Physics module depends on `math` only — no imports from graphics, audio, etc.
- **Stable IDs**: Body IDs must remain stable across frames for Lua reference tracking
- **Iteration safety**: Never modify body collection while iterating for collision detection
- **Gravity**: Applied as a constant force to all Dynamic bodies each step
- **Overlap resolution**: Separate overlapping bodies by minimum translation vector before applying impulse
