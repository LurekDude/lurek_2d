# physics — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/physics.md`
**Files**: rapier2d wrapper

## Purpose

2D rigid body physics simulation via rapier2d: worlds, bodies, colliders, shapes, joints, raycasting, collision events.

## Current Feature Summary

- `PhysicsWorld` wrapping rapier2d pipeline (gravity, stepping, queries)
- 4 body types: Dynamic, Static, Kinematic, KinematicVelocity
- 5 collider shapes: Circle, Rectangle, Capsule, ConvexPolygon, Segment
- 10 joint types: Revolute, Prismatic, Fixed, Ball, Rope, Spring, Distance, Weld, Wheel, Pulley
- Raycasting (first hit, all hits)
- AABB queries (test_point, test_overlap, intersections_with_rect)
- Collision events via `getContactPairs()` polling — not callbacks
- Material properties: friction, restitution, density
- Collision groups and filters (bitmask)
- Physics-to-pixel coordinate conversion (PPM scaling)

## Feature Gaps

1. **No one-way platforms**: Extremely common 2D platformer need. Body passes through from one side, collides from the other. Rapier supports this via collision modification hooks but it's not exposed.
2. **No collision callbacks**: Events are polled via `getContactPairs()`. Most engines provide `onCollisionBegin`/`onCollisionEnd` callbacks. Polling is lower overhead but less ergonomic for beginners.
3. **No continuous collision detection (CCD)**: Fast-moving bodies can tunnel through thin walls. Rapier supports CCD per body — not exposed.
4. **No trigger volumes with data**: Can create sensors but there's no built-in data attachment. Common pattern: "enter zone → get quest marker."
5. **No compound shapes**: Can't group multiple colliders into a single rigid body from Lua (must create separately and attach).
6. **No soft bodies / cloth**: Rapier doesn't support soft bodies natively, but spring networks can simulate cloth.
7. **No physics debug draw**: No way to visualize collider shapes, joints, raycasts. Critical for development.
8. **No buoyancy/fluid simulation**: Not even basic buoyancy forces.
9. **No breakable joints**: Joints can't be configured to break at a force threshold.

## Structural Issues

- **Rapier dependency is heavy**: rapier2d pulls in ~30 crates. For games that only need AABB collision (no rigid bodies), this is excessive. Consider a lightweight collision-only mode.
- **No standalone collision module**: Many 2D games need simple overlap detection (AABB, circle-circle) without a full physics world. Currently must create a PhysicsWorld even for simple collision checks.
- **Coordinate system**: PPM (pixels-per-meter) conversion is manual. Some engines auto-convert.

## Suggestions

1. **Add one-way platforms**: `body:setOneWay(true, direction)` — essential for platformers. This alone would unlock a major genre.
2. **Add collision callbacks**: `world:setBeginContact(fn)` / `world:setEndContact(fn)` — more ergonomic than polling. Keep polling as an alternative.
3. **Add debug draw**: `world:debugDraw()` — renders all collider wireframes, joint lines, contact points. Use DrawCommand queue like everything else.
4. **Add CCD flag**: `body:setCCD(enabled)` — prevent tunneling for bullets, fast projectiles.
5. **Create lightweight collision module** (new): `luna.collision.testAABB(a, b)`, `luna.collision.testCircles(...)` — no physics world needed. Many game types (puzzle, RPG, visual novel with interactable regions) need overlap detection without simulation.
6. **Add breakable joints**: `joint:setBreakForce(max)` — enables destructible structures, a popular game mechanic.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Physics engine | rapier2d | Box2D | Box2D | rapier (same!) |
| One-way platforms | ❌ | ✅ | ✅ | ❌ |
| Collision callbacks | ❌ (polling) | ✅ | ✅ | ✅ |
| Debug draw | ❌ | ❌ (manual) | ✅ (built-in) | ✅ |
| CCD | ❌ | ✅ | ✅ | ✅ |
| Joint types | 10 | 8 | 8 | 8 |
| Raycasting | ✅ | ✅ | ✅ | ✅ |
| Collision groups | ✅ | ✅ | ✅ | ✅ |

## Priority

**HIGH** — One-way platforms, collision callbacks, and debug draw are critical for the platformer genre (one of the most common 2D game types). Standalone collision detection is important for non-physics games.
