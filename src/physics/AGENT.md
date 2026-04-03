# `physics` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.physics` |
| **Source** | `src/physics/` |
| **Tests** | `tests/physics_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_physics.lua` |

## Summary

The physics module wraps rapier2d — a production-quality 2D rigid-body
simulation engine — behind a Luna2D-native API surface optimised for the most
common 2D game physics needs.  It manages a `World` that owns all `RigidBody`
and `Collider` rapier resources, steps the simulation at a fixed timestep, and
maps rapier's opaque internal handles to stable integer IDs that Lua scripts
can store in variables and serialise to save files without worrying about
handle invalidation.

Three body types cover the standard patterns: `Dynamic` bodies respond to
forces and collisions (players, enemies, projectiles); `Static` bodies are
immovable collision geometry with effectively infinite mass (tiles, walls, floors);
`Kinematic` bodies are moved by script position but still collide and push
dynamic bodies (moving platforms, kinematic character controllers);
and `Sensor` bodies detect overlap without generating contact forces (trigger
zones, pick-up areas).  Ten joint types — revolute, distance, prismatic, weld,
rope, wheel, friction, motor, and stubs for pulley and gear — cover the
mechanical needs of most 2D games without requiring direct rapier knowledge.

The module deliberately exposes a simplified subset of rapier2d.  Complex
solver configuration, soft bodies, multi-body constraints, and custom
integration callbacks are intentionally not bound — the design goal is to cover
95% of 2D game physics needs with a small, learnable surface rather than
providing a complete 1:1 rapier binding that game developers would still need
to consult rapier documentation to use.

## Architecture

```
World (physics simulation)
  │
  ├── Body sync buffer ── Vec<Body> mirrors rapier state
  │     ├── User-facing integer IDs (stable, Lua-friendly)
  │     ├── Internal rapier RigidBodyHandle + ColliderHandle mappings
  │     └── Change detection: cached shapes/restitutions/layers/frictions
  │
  ├── Body types
  │     ├── Dynamic ── full physics simulation
  │     ├── Static ── immovable, infinite mass
  │     ├── Kinematic ── user-controlled position
  │     └── Sensor ── collision detection only, no forces
  │
  ├── Shapes
  │     ├── Rect { width, height }
  │     ├── Circle { radius }
  │     ├── Polygon { vertices } ── convex only
  │     ├── Edge { v1, v2 } ── line segment
  │     └── Chain { vertices, closed } ── connected edges
  │
  ├── Joints (10 types)
  │     ├── Revolute ── rotation around a point
  │     ├── Distance ── fixed-length connection
  │     ├── Prismatic ── sliding along an axis
  │     ├── Weld ── rigid attachment
  │     ├── Rope ── max-distance constraint
  │     ├── Wheel ── spring + damper
  │     ├── Friction ── velocity damping
  │     ├── Motor ── force/torque driven
  │     ├── Mouse ── follow target (spring)
  │     └── Pulley / Gear ── stubs (not implemented)
  │
  ├── Queries
  │     ├── raycast / raycast_closest / raycast_all
  │     ├── query_aabb ── bodies in rectangle
  │     └── getContacts ── active contact info
  │
  ├── Collision events ── LocalEventCollector
  │     ├── rapier EventHandler impl
  │     ├── Mutex<Vec<CollisionEvent>>
  │     └── Maps rapier events → BodyContact { body_a, body_b }
  │
  └── Step pipeline (per frame)
        ├── Phase 1: Rebuild colliders for changed shapes
        ├── Phase 2: Sync Body properties → rapier
        ├── Phase 3: rapier physics step
        ├── Phase 4: Read back positions/velocities from rapier
        └── Phase 5: Map collision events to stable IDs
```

## Source Files

| File | Purpose |
|------|---------|
| `body.rs` | Body implementation for the `physics` subsystem |
| `collision.rs` | Collision implementation for the `physics` subsystem |
| `shape.rs` | Extended shape types for physics bodies |
| `world.rs` | Rapier2d-backed physics world with backward-compatible Luna2D API |

## Submodules

### `physics::body`

Body implementation for the `physics` subsystem.

- **`BodyType`** (enum): Determines whether a physics body is affected by forces and gravity.
- **`BodyShape`** (enum): Describes the collision geometry of a body.
- **`Body`** (struct): A rigid body with position, velocity, mass, shape, and restitution.  Bodies live in a `World` and are identified by...

### `physics::collision`

Collision implementation for the `physics` subsystem.

- **`CollisionInfo`** (struct): Collision contact data: penetration depth and separating normal.  Retained for backward compatibility; collision...

### `physics::shape`

Extended shape types for physics bodies.

- **`Shape`** (enum): Extended collision shape for physics bodies.  Goes beyond `BodyShape` to support convex polygons, edges, and chains.

### `physics::world`

Rapier2d-backed physics world with backward-compatible Luna2D API.

- **`BodyContact`** (struct): Collision event generated by `World::step` when two bodies start overlapping.  Contains stable integer body IDs for the...
- **`RaycastHit`** (struct): Result of a `World::raycast` query. Consult the module-level documentation for the broader usage context and...
- **`ContactInfo`** (struct): Contact information between two bodies from the narrow phase.
- **`World`** (struct): Simulates a 2D physics world using rapier2d.  Bodies are stored as a `Vec<Body>` for backward-API compatibility. Each...

## Key Types

### Structs

#### `physics::body::Body`

A rigid body with position, velocity, mass, shape, and restitution.  Bodies live in a `World` and are identified by...

#### `physics::world::BodyContact`

Collision event generated by `World::step` when two bodies start overlapping.  Contains stable integer body IDs for the...

#### `physics::collision::CollisionInfo`

Collision contact data: penetration depth and separating normal.  Retained for backward compatibility; collision...

#### `physics::world::ContactInfo`

Contact information between two bodies from the narrow phase.

#### `physics::world::RaycastHit`

Result of a `World::raycast` query. Consult the module-level documentation for the broader usage context and...

#### `physics::world::World`

Simulates a 2D physics world using rapier2d.  Bodies are stored as a `Vec<Body>` for backward-API compatibility. Each...

### Enums

#### `physics::body::BodyShape`

Describes the collision geometry of a body.

#### `physics::body::BodyType`

Determines whether a physics body is affected by forces and gravity.

#### `physics::shape::Shape`

Extended collision shape for physics bodies.  Goes beyond `BodyShape` to support convex polygons, edges, and chains.

## Lua API

Exposed under `luna.physics.*` by `src/lua_api/physics_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 3 |
| `mod` | 4 |
| `struct` | 6 |
| **Total** | **13** |

