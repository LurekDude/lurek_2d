# `physics` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.physics`                                       |
| **Source**      | `src/physics/`                                       |
| **Rust Tests** | `tests/unit/physics_tests.rs`                        |
| **Lua Tests**  | `tests/lua/unit/test_physics.lua`                    |
| **Architecture** | —                                                  |

## Summary

The physics module provides 2D rigid-body simulation backed by rapier2d 0.32. It wraps the rapier2d pipeline behind a Luna2D-native API surface that exposes stable integer body and joint IDs suitable for Lua storage and serialization, hiding rapier's opaque internal handles entirely.

The central type is `World`, which owns a `Vec<Body>` sync buffer alongside parallel rapier `RigidBodySet` and `ColliderSet` instances. The sync-buffer pattern decouples Lua property access from rapier internals: scripts read and write `Body` fields freely, and the `World::step()` method flushes those mutations into rapier, runs the simulation pipeline, then reads back computed positions, velocities, and angles for dynamic and kinematic bodies. Change detection caches (shape, restitution, friction, layer/mask) trigger automatic collider rebuilds only when a property actually changes, avoiding unnecessary rapier resource churn.

Four body types cover standard 2D game patterns: `Dynamic` (full simulation), `Static` (immovable terrain), `Kinematic` (script-controlled platforms), and `Sensor` (overlap detection without forces). Five collision shapes are supported: axis-aligned rectangles, circles, convex polygons (max 8 vertices), edges (line segments), and chains (connected polylines, optionally closed). Bodies support multi-fixture attachment via `add_fixture`, enabling compound collision geometry on a single body.

Ten joint types are available: Revolute, Distance, Prismatic, Weld, Rope, Wheel, Friction, Motor, Mouse, plus stubs for Pulley and Gear (which fall back to weld joints with a warning). Joints support motor speed, angular limits, and target position updates. Three raycast variants (brute-force, query-pipeline closest, query-pipeline all) and two spatial queries (AABB intersection, point query) enable line-of-sight checks, hit detection, and area triggers.

The module intentionally exposes a simplified subset of rapier2d. Complex solver parameters, soft bodies, multi-body constraints, and custom integration callbacks are not bound — the design targets 95% of 2D game physics needs with a small, learnable API.

## Architecture

```
luna.physics.newWorld(gx, gy)
        |
        v
    +--------------------------------------------------------------------+
    |  World                                                             |
    |                                                                    |
    |  +------------------------------+  +------------------------+     |
    |  | Body Sync Buffer (Vec<Body>) |  | Rapier Pipeline        |     |
    |  | +- position, velocity, angle |  | +- RigidBodySet        |     |
    |  | +- mass, restitution, friction|  | +- ColliderSet         |     |
    |  | +- body_type, layer, mask    |  | +- ImpulseJointSet     |     |
    |  | +- shape / shape_ext         |  | +- BroadPhaseBvh       |     |
    |  +------------------------------+  | +- NarrowPhase         |     |
    |                 |                  | +- CCDSolver            |     |
    |  +--------------v--------------+   | +- PhysicsPipeline     |     |
    |  | Change Detection Caches     |   +------------------------+     |
    |  | +- cached_shapes            |                                  |
    |  | +- cached_restitutions      |   +------------------------+     |
    |  | +- cached_frictions         |   | Handle Mappings        |     |
    |  | +- cached_layers            |   | +- body_handles        |     |
    |  +-----------------------------+   | +- collider_handles    |     |
    |                                    | +- extra_collider_hdls  |     |
    |  step(dt) flow:                    | +- collider_to_body    |     |
    |  (1) Detect changed props ->       | +- joint_handles       |     |
    |     rebuild_collider()             | +- mouse_joint_anchors |     |
    |  (2) Sync Body -> rapier rb        +------------------------+     |
    |  (3) pipeline.step() w/ events                                    |
    |  (4) Read back pos/vel/angle       +------------------------+     |
    |  (5) Map CollisionEvent ->         | Event Buffers          |     |
    |     BodyContact { body_a, body_b } | +- collision_events    |     |
    |                                    | +- begin_contact_events|     |
    |                                    | +- end_contact_events  |     |
    |                                    +------------------------+     |
    +--------------------------------------------------------------------+

    Joints (10 types)              Shapes (5 types)
    +- Revolute (pin)              +- Rect { width, height }
    +- Distance (fixed length)     +- Circle { radius }
    +- Prismatic (slider)          +- Polygon { vertices } (max 8)
    +- Weld (rigid)                +- Edge { v1, v2 }
    +- Rope (max distance)         +- Chain { vertices, closed }
    +- Wheel (spring + rotation)
    +- Friction (velocity damping) Queries
    +- Motor (force-driven)        +- raycast (brute-force nearest)
    +- Mouse (spring to target)    +- raycastClosest (query pipeline)
    +- Pulley (stub -> weld)       +- raycastAll (all hits)
    +- Gear (stub -> weld)         +- queryAABB (bodies in rect)
                                   +- getBodyAtPoint (point query)
```

## Source Files

| File           | Purpose                                                      |
|----------------|--------------------------------------------------------------|
| `body.rs`      | `Body` struct, `BodyType`/`BodyShape` enums, constructors, coordinate transforms, bounding box |
| `collision.rs` | `CollisionInfo` struct — legacy penetration/normal data (retained for backward compatibility) |
| `shape.rs`     | Extended `Shape` enum (polygon, edge, chain), `StandaloneShape` value type, rapier collider conversion |
| `world.rs`     | `World` simulation manager, body/joint CRUD, step pipeline, raycasting, spatial queries, collision events |

## Submodules

### `physics::body`

Body types, shapes, and the `Body` struct used by the physics world.

- **`BodyType`** (enum) — Determines whether a physics body is affected by forces and gravity. Variants: `Static`, `Dynamic`, `Kinematic`, `Sensor`.
- **`BodyShape`** (enum) — Describes basic collision geometry: `Rect { width, height }` or `Circle { radius }`.
- **`Body`** (struct) — A rigid body with position, velocity, mass, shape, and restitution. Bodies live in a `World` and are identified by stable integer indices. Provides five constructors (`new`, `new_circle`, `new_polygon`, `new_edge`, `new_chain`), bounding box computation, collision layer filtering, body type name accessor, and local/world coordinate transforms.

### `physics::collision`

Legacy collision contact data retained for backward compatibility.

- **`CollisionInfo`** (struct) — Stores penetration depth and separating normal between two bodies. Not actively used by the rapier-backed simulation; collision detection is handled internally by rapier. See `World::get_collision_events()` for the current event API.

### `physics::shape`

Extended shape types beyond basic rect/circle.

- **`Shape`** (enum) — Five collision shape variants: `Rect`, `Circle`, `Polygon` (convex, max 8 vertices), `Edge` (line segment), `Chain` (connected edges, optionally closed). Provides `to_rapier_collider()` (crate-internal) for converting to rapier `ColliderBuilder` and `regular_polygon()` for generating regular N-gon vertices.
- **`StandaloneShape`** (struct) — A shape value holding geometry plus default fixture parameters (density, friction, restitution, sensor flag). Created via `luna.physics.newCircleShape` et al. and attached to bodies with `world:addFixture`. Can be reused across multiple bodies.

### `physics::world`

The core simulation manager wrapping the rapier2d pipeline.

- **`BodyContact`** (struct) — Collision event with stable integer body IDs (`body_a`, `body_b`). Generated by `World::step()` when two bodies start overlapping.
- **`RaycastHit`** (struct) — Raycast result containing `body_id`, hit `point`, surface `normal`, and distance `toi`.
- **`ContactInfo`** (struct) — Narrow-phase contact data with body IDs, contact normal, and `is_touching` flag.
- **`World`** (struct) — Simulates a 2D physics world using rapier2d. Owns the body sync buffer, rapier pipeline fields, handle mappings, joint table, collision event buffers, and meter scaling. Provides 78 public methods covering body management, joint creation, simulation stepping, raycasting, spatial queries, and contact retrieval.

## Key Types

### Structs

#### `physics::body::Body`

A rigid body with position, velocity, mass, shape, and restitution. Fields: `position` (Vec2), `velocity` (Vec2), `mass` (f32), `body_type` (BodyType), `shape` (BodyShape), `restitution` (f32), `layer`/`mask` (u32 bitmasks), `width`/`height` (convenience), `friction` (f32), `angle` (f32), `angular_velocity` (f32), `shape_ext` (Option<Shape>). Constructors: `new()` (rect), `new_circle()`, `new_polygon()`, `new_edge()`, `new_chain()`. Methods: `bounding_box()`, `collides_with_layer()`, `get_bounding_box()`, `get_type()`, `get_world_point()`, `get_local_point()`.

#### `physics::collision::CollisionInfo`

Legacy collision contact data: `penetration` (f32) and `normal` (Vec2). Retained for backward compatibility; the active API uses `World::get_collision_events()`.

#### `physics::shape::StandaloneShape`

Standalone shape value with default fixture parameters. Fields: `shape` (Shape), `density` (f32, default 1.0), `friction` (f32, default 0.5), `restitution` (f32, default 0.0), `sensor` (bool, default false). Methods: `new()`, `get_type()`, `get_radius()`, `get_bounding_box()`.

#### `physics::world::BodyContact`

Collision event produced by `World::step()`. Fields: `body_a` (usize), `body_b` (usize).

#### `physics::world::RaycastHit`

Raycast query result. Fields: `body_id` (usize), `point` ((f32, f32)), `normal` ((f32, f32)), `toi` (f32).

#### `physics::world::ContactInfo`

Narrow-phase contact pair. Fields: `body_a` (usize), `body_b` (usize), `normal_x` (f32), `normal_y` (f32), `is_touching` (bool).

#### `physics::world::World`

The 2D physics simulation. Key internal fields: `bodies` (Vec<Body>), rapier pipeline components (`pipeline`, `rbodies`, `rcolliders`, `impulse_joints`, etc.), handle mappings (`body_handles`, `collider_handles`, `collider_to_body`), change detection caches, collision event buffers, `joint_types` (Vec<&'static str>), `mouse_joint_anchors` (HashMap), `pixels_per_meter` (f32).

### Enums

#### `physics::body::BodyType`

Body simulation mode. Variants: `Static` (immovable), `Dynamic` (full physics), `Kinematic` (script-controlled position), `Sensor` (overlap detection only).

#### `physics::body::BodyShape`

Basic collision geometry. Variants: `Rect { width, height }`, `Circle { radius }`.

#### `physics::shape::Shape`

Extended collision geometry. Variants: `Rect { width, height }`, `Circle { radius }`, `Polygon { vertices }` (convex, max 8 vertices), `Edge { v1, v2 }` (line segment), `Chain { vertices, closed }` (connected edges).

## Lua API

Exposed under `luna.physics.*` by `src/lua_api/physics_api.rs`. The API provides two UserData types (`LuaWorld` and `LuaBody`) plus module-level factory functions.

### Module-level functions (`luna.physics.*`)

| Function | Description |
|----------|-------------|
| `newWorld(gx, gy)` | Create a physics world with given gravity vector |
| `newRectangleShape(w, h)` | Create a rectangle shape descriptor |
| `newCircleShape(radius)` | Create a circle shape descriptor |
| `newEdgeShape(x1, y1, x2, y2)` | Create an edge shape descriptor |

### World methods (`world:*`)

| Method | Description |
|--------|-------------|
| `step(dt)` | Advance simulation by dt seconds |
| `clear()` | Remove all bodies and joints |
| `getGravity()` | Returns (gx, gy) |
| `setGravity(gx, gy)` | Set gravity vector |
| `setMeter(ppm)` | Set pixels-per-meter scale |
| `getMeter()` | Get pixels-per-meter scale |
| `toPhysics(px)` | Convert pixels to physics units |
| `toPixels(m)` | Convert physics units to pixels |
| `getBodyCount()` | Total body count |
| `getBodyIds()` | All body IDs as table |
| `destroyBody(id)` | Remove a body |
| `newBody(x, y, type)` | Create rectangular body |
| `newCircleBody(x, y, r, type)` | Create circular body |
| `newPolygonBody(x, y, verts, type)` | Create polygon body |
| `newEdgeBody(x, y, x1, y1, x2, y2, type)` | Create edge body |
| `newChainBody(x, y, verts, closed, type)` | Create chain body |
| `addFixture(bodyId, shapeType, density, friction, restitution, sensor, ...)` | Add extra collider |
| `fixtureCount(bodyId)` | Fixture count on body |
| `setFixtureFriction(bodyId, idx, friction)` | Set fixture friction |
| `setFixtureRestitution(bodyId, idx, restitution)` | Set fixture restitution |
| `setFixtureSensor(bodyId, idx, sensor)` | Set fixture sensor flag |
| `addRevoluteJoint(a, b, ax, ay)` | Pin joint |
| `addDistanceJoint(a, b, ax1, ay1, ax2, ay2, len)` | Fixed-length joint |
| `addPrismaticJoint(a, b, ax, ay, axisX, axisY)` | Slider joint |
| `addWeldJoint(a, b, ax, ay)` | Rigid attachment |
| `addRopeJoint(a, b, ax1, ay1, ax2, ay2, max)` | Max-distance joint |
| `addWheelJoint(a, b, ax, ay, axisX, axisY)` | Spring + rotation |
| `addFrictionJoint(a, b, ax, ay, maxF, maxT)` | Velocity damping |
| `addMotorJoint(a, b, factor)` | Force-driven joint |
| `addMouseJoint(bodyId, tx, ty, maxF)` | Spring to target point |
| `addPulleyJoint(a, b, ax, ay)` | Stub (falls back to weld) |
| `addGearJoint(a, b, ax, ay)` | Stub (falls back to weld) |
| `jointCount()` | Total joint count |
| `getJointIds()` | All joint IDs |
| `getJointBodies(jid)` | Bodies connected by joint |
| `destroyJoint(jid)` | Remove a joint |
| `getJointType(jid)` | Joint type name |
| `setJointMotorSpeed(jid, speed)` | Set angular motor speed |
| `getJointMotorSpeed(jid)` | Get angular motor speed |
| `setJointLimitsEnabled(jid, enabled)` | Enable/disable angular limits |
| `setJointLimits(jid, lower, upper)` | Set angular limits |
| `getJointLimits(jid)` | Get angular limits (lower, upper) |
| `setMouseJointTarget(jid, x, y)` | Update mouse joint target |
| `raycast(x1, y1, x2, y2)` | Nearest hit (brute-force) |
| `raycastClosest(x1, y1, dx, dy, maxDist)` | Nearest hit (query pipeline) |
| `raycastAll(x1, y1, dx, dy, maxDist)` | All hits |
| `queryAABB(x, y, w, h)` | Body IDs in rectangle |
| `getBodyAtPoint(x, y)` | Body at point (or nil) |
| `getCollisionEvents()` | Collision events from last step |
| `getBeginContactEvents()` | Begin-contact events |
| `getEndContactEvents()` | End-contact events |
| `getContacts()` | All narrow-phase contacts |
| `getBodyContacts(bodyId)` | Contacts for a specific body |
| `setBodyType(bodyId, type)` | Change body type |
| `getBodyType(bodyId)` | Get body type string |

### Body methods (`body:*`)

| Method | Description |
|--------|-------------|
| `getId()` | Stable integer ID |
| `getPosition()` | Returns (x, y) |
| `setPosition(x, y)` | Teleport body |
| `getX()` | X position |
| `getY()` | Y position |
| `getVelocity()` | Returns (vx, vy) |
| `setVelocity(vx, vy)` | Set linear velocity |
| `getAngle()` | Rotation in radians |
| `setAngle(angle)` | Set rotation |
| `getAngularVelocity()` | Spin rate (rad/s) |
| `setAngularVelocity(omega)` | Set spin rate |
| `getMass()` | Body mass |
| `setMass(mass)` | Set body mass |
| `getType()` | Body type string |
| `setType(type)` | Change body type |
| `getWidth()` | Body width |
| `getHeight()` | Body height |
| `getFriction()` | Friction coefficient |
| `setFriction(friction)` | Set friction |
| `getRestitution()` | Bounciness |
| `setRestitution(restitution)` | Set bounciness |
| `getLayer()` | Collision layer bitmask |
| `setLayer(layer)` | Set collision layer |
| `getMask()` | Collision mask bitmask |
| `setMask(mask)` | Set collision mask |
| `applyImpulse(ix, iy)` | Apply linear impulse |
| `applyForce(fx, fy)` | Apply continuous force |
| `applyTorque(torque)` | Apply rotational force |
| `applyForceAtPoint(fx, fy, px, py)` | Force at world point |
| `applyAngularImpulse(impulse)` | Apply angular impulse |
| `getGravityScale()` | Per-body gravity multiplier |
| `setGravityScale(scale)` | Set gravity multiplier |
| `isFixedRotation()` | Rotation locked? |
| `setFixedRotation(fixed)` | Lock/unlock rotation |
| `getLinearDamping()` | Linear damping coefficient |
| `setLinearDamping(damping)` | Set linear damping |
| `getAngularDamping()` | Angular damping coefficient |
| `setAngularDamping(damping)` | Set angular damping |
| `isBullet()` | CCD enabled? |
| `setBullet(bullet)` | Enable/disable CCD |
| `isSleepingAllowed()` | Can body sleep? |
| `setSleepingAllowed(allowed)` | Allow/disallow sleeping |
| `destroy()` | Remove body from world |

## Lua Examples

```lua
function luna.init()
    -- Create a world with downward gravity
    world = luna.physics.newWorld(0, 9.81)

    -- Static ground platform
    ground = world:newBody(400, 580, "static")
    ground:setFriction(0.8)
    ground:setRestitution(0.0)

    -- Dynamic bouncing ball
    ball = world:newCircleBody(400, 100, 20, "dynamic")
    ball:setRestitution(0.7)
    ball:setLinearDamping(0.1)

    -- Kinematic moving platform
    platform = world:newBody(300, 400, "kinematic")

    -- Sensor trigger zone
    trigger = world:newBody(600, 300, "sensor")
end

function luna.process(dt)
    world:step(dt)

    -- Read ball state
    local x, y = ball:getPosition()
    local vx, vy = ball:getVelocity()
    local angle = ball:getAngle()

    -- Move kinematic platform
    platform:setPosition(300 + math.sin(luna.time.getTime()) * 100, 400)

    -- Check collision events
    local events = world:getBeginContactEvents()
    for _, evt in ipairs(events) do
        if evt.bodyA == trigger:getId() or evt.bodyB == trigger:getId() then
            -- Trigger zone entered
        end
    end

    -- Raycast for line-of-sight
    local hit = world:raycast(0, 300, 800, 300)
    if hit then
        local hitId = hit.bodyId
        local hx, hy = hit.x, hit.y
    end
end

function luna.render()
    -- Draw ball
    local bx, by = ball:getPosition()
    luna.gfx.circle("fill", bx, by, 20)

    -- Draw ground
    local gx, gy = ground:getPosition()
    luna.gfx.rectangle("fill", gx - 400, gy - 10, 800, 20)
end
```

### Joints example

```lua
function luna.init()
    world = luna.physics.newWorld(0, 9.81)

    -- Two bodies connected by a revolute joint
    anchor = world:newBody(400, 200, "static")
    pendulum = world:newBody(400, 300, "dynamic")
    joint = world:addRevoluteJoint(anchor:getId(), pendulum:getId(), 0, 0)

    -- Distance joint
    bodyA = world:newBody(200, 200, "dynamic")
    bodyB = world:newBody(300, 200, "dynamic")
    world:addDistanceJoint(bodyA:getId(), bodyB:getId(), 0, 0, 0, 0, 100)

    -- Mouse joint for dragging
    draggable = world:newBody(500, 300, "dynamic")
    mouseJoint = world:addMouseJoint(draggable:getId(), 500, 300, 1000)
end

function luna.process(dt)
    -- Update mouse joint target to cursor position
    local mx, my = luna.mouse.getPosition()
    world:setMouseJointTarget(mouseJoint, mx, my)

    world:step(dt)
end
```

## Item Summary

| Kind       | Count  |
|------------|--------|
| `struct`   | 7      |
| `enum`     | 3      |
| `fn`       | 94     |
| **Total**  | **104** |

## References

| Module     | Relationship | Notes                                                    |
|------------|-------------|----------------------------------------------------------|
| `engine`   | Imports from | Uses `SharedState`, `PhysicsWorldKey`, `PhysicsBodyKey`  |
| `math`     | Imports from | `Vec2`, `Rect` for positions and shapes                  |
| `lua_api`  | Imported by  | `src/lua_api/physics_api.rs` registers `luna.physics.*`  |
| `graphics` | Related      | Physics debug rendering draws body outlines via draw commands; no direct import |

**Similar modules**: None — physics is the only simulation module. The `math` module provides linear algebra primitives but no physics simulation. The `particle` module (Tier 2) handles visual particle effects, not rigid-body physics.

## Notes

- **rapier2d 0.32** is the underlying physics engine. All rapier types are internal; Lua scripts interact only with stable integer body/joint IDs.
- **Sync-buffer pattern**: Lua writes to `Body` fields -> changes flushed to rapier at `step()` -> results read back. Change detection (shape, restitution, friction, layer/mask) avoids unnecessary collider rebuilds.
- **`step(dt)` call frequency**: Call once per frame with the real delta time. The module does not perform fixed-timestep subdivision internally; the caller controls the timestep.
- **Body destruction preserves IDs**: `destroy_body()` disables the rapier rigid body and marks the slot as static rather than removing it from the `Vec<Body>`. This keeps all other body indices stable. Destroyed body slots are never reused.
- **Sensor bodies** generate `beginContact`/`endContact` events but exert no physical forces. They map to rapier `Fixed` rigid bodies with collider `sensor = true`.
- **Kinematic bodies** use `set_next_kinematic_translation` / `set_next_kinematic_rotation` in rapier, enabling smooth interpolation rather than teleporting.
- **Pulley and Gear joints** are stubs that fall back to weld joints with a `log::warn!` message, because rapier2d 0.32 has no direct equivalent.
- **Mouse joint** creates an internal kinematic anchor body and a spring joint. The anchor body is tracked in `mouse_joint_anchors` and repositioned via `set_mouse_joint_target`.
- **Thread safety**: The `World` uses `Rc<RefCell<World>>` in Lua bindings and cannot be shared across threads. Create separate worlds per thread if needed.
- **`LocalEventCollector`** uses `Mutex<Vec<CollisionEvent>>` because rapier2d 0.32 requires `EventHandler: Send + Sync`, even though the physics pipeline runs single-threaded.
- **Polygon vertices**: Maximum 8 vertices for `Shape::Polygon`. The polygon must be convex; rapier's `convex_hull` builder handles winding order.
- **Multi-fixture bodies**: `add_fixture()` attaches additional colliders to an existing body. The primary collider uses index 0; extras start at 1. Fixture friction, restitution, and sensor flag can be set per-fixture.
- **Breaking change surface**: Renaming or removing any Lua-facing method on `LuaWorld` or `LuaBody` will break user scripts. Body ID stability is a hard contract — never change the index assignment scheme.
