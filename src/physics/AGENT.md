# physics

## Module Info
- Group: Platform Services.
- Source: `src/physics/`.
- Spec: `docs/specs/physics.md`.
- Lua bridge: `src/lua_api/physics_api.rs` registers `lurek.physics`.
- Runtime focus: rapier-backed 2D rigid bodies, joints, contacts, raycasts, and query helpers.

## Module Purpose
The physics module owns the engine's 2D simulation state and the stable, script-facing data model wrapped around rapier2d. It exists so Lua code can work with bodies, shapes, joints, and collision events through stable integer IDs and plain values instead of backend handles.

Its core boundary is the `World` sync layer: scripts mutate `Body` records, `World::step` mirrors those changes into rapier, advances simulation, then reads the authoritative results back out. The module also owns collision and raycast query results plus CPU-side debug rendering helpers, but it does not own gameplay interpretation of contacts or the Lua registration code itself.

## Files
- `mod.rs`: Module root and public re-export surface for bodies, shapes, collision records, and the world.
- `body.rs`: Script-facing rigid-body types, constructors, bounding boxes, and local/world point helpers.
- `collision.rs`: Backward-compatible `CollisionInfo` contact record retained on the public API surface.
- `shape.rs`: Extended collider geometry and reusable standalone fixture descriptors.
- `world.rs`: Simulation owner for rapier sets, body and collider mappings, joints, stepping, events, and spatial queries.
- `render.rs`: Debug overlay render-command generation and CPU image export for headless inspection.

## Key Types
- `World`: Central simulation owner for bodies, joints, queries, cached collider state, and event buffers.
- `Body`: Lua-friendly rigid-body record mirrored into and out of rapier state.
- `BodyType`: Simulation mode selector for static, dynamic, kinematic, and sensor bodies.
- `BodyShape`: Lightweight common-shape enum for rectangle and circle bodies.
- `Shape`: Extended collider enum for polygons, edges, chains, and the simple primitive cases.
- `StandaloneShape`: Reusable shape-plus-fixture descriptor for attaching extra colliders.
- `BodyContact`: Stable-ID collision event emitted from simulation results.
- `RaycastHit`: Query result carrying hit body, hit point, normal, and distance.
- `ContactInfo`: Narrow-phase contact snapshot for detailed per-pair inspection.
- `CollisionInfo`: Legacy compatibility record still exposed alongside newer contact models.
