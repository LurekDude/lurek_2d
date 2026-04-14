# physics

## General Info

- Module group: `Platform Services.`
- Source path: `src/physics/`
- Lua API path(s): `src/lua_api/physics_api.rs`
- Primary Lua namespace: `lurek.physics`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Summary

The physics module owns the engine's 2D simulation state and the stable, script-facing data model wrapped around rapier2d. It exists so Lua code can work with bodies, shapes, joints, and collision events through stable integer IDs and plain values instead of backend handles.

Its core boundary is the `World` sync layer: scripts mutate `Body` records, `World::step` mirrors those changes into rapier, advances simulation, then reads the authoritative results back out. The module also owns collision and raycast query results plus CPU-side debug rendering helpers, but it does not own gameplay interpretation of contacts or the Lua registration code itself.

**Scope boundary**: This module currently depends on `image`, `math`, `render`, `runtime`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

## Files

- `body.rs`: Script-facing rigid-body types, constructors, bounding boxes, and local/world point helpers.
- `collision.rs`: Backward-compatible `CollisionInfo` contact record retained on the public API surface.
- `mod.rs`: Module root and public re-export surface for bodies, shapes, collision records, and the world.
- `render.rs`: Debug overlay render-command generation and CPU image export for headless inspection.
- `shape.rs`: Extended collider geometry and reusable standalone fixture descriptors.
- `world.rs`: Simulation owner for rapier sets, body and collider mappings, joints, stepping, events, and spatial queries.

## Types

- `BodyType` (`enum`, `body.rs`): Simulation mode selector for static, dynamic, kinematic, and sensor bodies.
- `BodyShape` (`enum`, `body.rs`): Lightweight common-shape enum for rectangle and circle bodies.
- `Body` (`struct`, `body.rs`): Lua-friendly rigid-body record mirrored into and out of rapier state.
- `CollisionInfo` (`struct`, `collision.rs`): Legacy compatibility record still exposed alongside newer contact models.
- `Shape` (`enum`, `shape.rs`): Extended collider enum for polygons, edges, chains, and the simple primitive cases.
- `StandaloneShape` (`struct`, `shape.rs`): Reusable shape-plus-fixture descriptor for attaching extra colliders.
- `BodyContact` (`struct`, `world.rs`): Stable-ID collision event emitted from simulation results.
- `RaycastHit` (`struct`, `world.rs`): Query result carrying hit body, hit point, normal, and distance.
- `ContactInfo` (`struct`, `world.rs`): Narrow-phase contact snapshot for detailed per-pair inspection.
- `World` (`struct`, `world.rs`): Central simulation owner for bodies, joints, queries, cached collider state, and event buffers.

## Functions

- `Body::new` (`body.rs`): Creates a new rectangular `Body` at position `(x, y)` of the given `body_type`.
- `Body::new_circle` (`body.rs`): Creates a new circular `Body` at position `(x, y)` of the given `body_type`.
- `Body::new_polygon` (`body.rs`): Creates a new polygon `Body` at position `(x, y)` with the given vertices.
- `Body::new_edge` (`body.rs`): Creates a new edge (line segment) `Body` between two local points.
- `Body::new_chain` (`body.rs`): Creates a new chain `Body` from a series of connected vertices.
- `Body::bounding_box` (`body.rs`): Returns the axis-aligned bounding box for this body centered at `position`.
- `Body::collides_with_layer` (`body.rs`): Returns `true` if this body participates in collision layer filtering with `other`.
- `Body::get_bounding_box` (`body.rs`): Returns the AABB of this body as a flat `(x, y, width, height)` tuple.
- `Body::get_type` (`body.rs`): Returns the body type as a static string slice.
- `Body::get_world_point` (`body.rs`): Transforms a point from body-local coordinates to world coordinates.
- `Body::get_local_point` (`body.rs`): Transforms a point from world coordinates to body-local coordinates.
- `World::generate_render_commands` (`render.rs`): Generate debug render commands for all physics bodies.
- `World::draw_to_image` (`render.rs`): Render the physics world to a CPU image for headless testing or export.
- `Shape::to_rapier_collider` (`shape.rs`): Converts this shape into a rapier2d `ColliderBuilder`.
- `Shape::from_parts` (`shape.rs`): Creates a `Shape` from a type string and flat float argument list.
- `Shape::regular_polygon` (`shape.rs`): Creates a regular polygon with the given radius and number of sides.
- `StandaloneShape::new` (`shape.rs`): Creates a new `StandaloneShape` with default fixture parameters.
- `StandaloneShape::get_type` (`shape.rs`): Returns the shape type name.
- `StandaloneShape::get_radius` (`shape.rs`): Returns the radius for circle shapes.
- `StandaloneShape::get_bounding_box` (`shape.rs`): Returns an axis-aligned bounding box for this shape as `(min_x, min_y, max_x, max_y)`.
- `World::new` (`world.rs`): Creates a new empty physics world with the given gravity vector.
- `World::add_body` (`world.rs`): Adds a `body` to the world and returns its stable integer id.
- `World::add_fixture` (`world.rs`): Adds an extra fixture (collider) to an existing body.
- `World::fixture_count` (`world.rs`): Returns the number of fixtures on a body (1 = primary only).
- `World::set_fixture_friction` (`world.rs`): Sets the friction of a fixture by index.
- `World::set_fixture_restitution` (`world.rs`): Sets the restitution of a fixture by index.
- `World::set_fixture_sensor` (`world.rs`): Sets whether a fixture is a sensor.
- `World::get_body` (`world.rs`): Returns an immutable reference to body `id`, or `None` if out of range.
- `World::get_body_mut` (`world.rs`): Returns a mutable reference to body `id`, or `None` if out of range.
- `World::body_count` (`world.rs`): Returns the total number of bodies.
- `World::add_revolute_joint` (`world.rs`): Creates a revolute (pin) joint between two bodies at a local anchor on body_a.
- `World::raycast` (`world.rs`): Casts a ray from `(x1, y1)` toward `(x2, y2)` and returns the nearest hit.
- `World::step` (`world.rs`): Advances the simulation by `dt` seconds.
- `World::apply_impulse` (`world.rs`): Applies a linear impulse directly to a body in the rapier simulation.
- `World::get_collision_events` (`world.rs`): Returns all collision events that occurred during the last `step()` call.
- `World::get_begin_contact_events` (`world.rs`): Returns begin-contact events from the last `step()`.
- `World::get_end_contact_events` (`world.rs`): Returns end-contact events from the last `step()`.
- `World::set_body_position` (`world.rs`): Teleports a body to a new position.
- `World::apply_force` (`world.rs`): Applies a continuous force to a body (accumulated over the next step).
- `World::apply_torque` (`world.rs`): Applies a torque (rotational force) to a body.
- `World::set_angular_velocity` (`world.rs`): Sets the angular velocity (spin rate) of a body.
- `World::get_angular_velocity` (`world.rs`): Returns the angular velocity of a body.
- `World::get_body_angle` (`world.rs`): Returns the angle (rotation) of a body in radians.
- `World::set_body_angle` (`world.rs`): Sets the angle (rotation) of a body in radians.
- `World::get_body_mass` (`world.rs`): Returns the mass of a body.
- `World::set_body_mass` (`world.rs`): Sets the mass of a body.
- `World::set_gravity_scale` (`world.rs`): Sets the per-body gravity multiplier.
- `World::set_fixed_rotation` (`world.rs`): Locks or unlocks rotation for a body.
- `World::set_linear_damping` (`world.rs`): Sets linear damping (air resistance) for a body.
- `World::set_angular_damping` (`world.rs`): Sets angular damping (rotational resistance) for a body.
- `World::get_gravity_scale` (`world.rs`): Returns the gravity scale multiplier for a body.
- `World::is_fixed_rotation` (`world.rs`): Returns `true` if the body has rotation locked.
- `World::get_linear_damping` (`world.rs`): Returns the linear damping coefficient for a body.
- `World::get_angular_damping` (`world.rs`): Returns the angular damping coefficient for a body.
- `World::set_bullet` (`world.rs`): Enables or disables continuous collision detection (CCD) for a body.
- `World::is_bullet` (`world.rs`): Returns whether CCD is enabled for a body.
- `World::apply_force_at_point` (`world.rs`): Applies a force at a specific world-space point on a body.
- `World::apply_angular_impulse` (`world.rs`): Applies an angular (rotational) impulse to a body.
- `World::get_body_ids` (`world.rs`): Returns all active body IDs in insertion order (including destroyed slots).
- `World::get_joint_ids` (`world.rs`): Returns all active joint IDs in insertion order.
- `World::get_body_type_str` (`world.rs`): Returns the body type as a string.
- `World::set_body_type` (`world.rs`): Changes the body type of an existing body.
- `World::get_gravity` (`world.rs`): Returns the current gravity vector `(gx, gy)`.
- `World::set_gravity` (`world.rs`): Sets the gravity vector.
- `World::clear` (`world.rs`): Destroys all bodies and joints, resetting the world to an empty state.
- `World::set_sleeping_allowed` (`world.rs`): Sets whether sleeping is allowed for a body.
- `World::is_sleeping_allowed` (`world.rs`): Returns whether sleeping is allowed for a body.
- `World::destroy_body` (`world.rs`): Removes a body from the world by disabling it in rapier.
- `World::joint_count` (`world.rs`): Returns the total number of joints.
- `World::add_distance_joint` (`world.rs`): Creates a distance joint that tries to maintain a fixed distance between two bodies.
- `World::add_prismatic_joint` (`world.rs`): Creates a prismatic (slider) joint allowing motion along one axis.
- `World::add_weld_joint` (`world.rs`): Creates a weld (rigid) joint that locks two bodies together.
- `World::add_rope_joint` (`world.rs`): Creates a rope joint with a maximum distance constraint.
- `World::get_joint_bodies` (`world.rs`): Returns the two body IDs connected by a joint.
- `World::destroy_joint` (`world.rs`): Removes a joint from the world.
- `World::raycast_closest` (`world.rs`): Casts a ray and returns the closest hit using the query pipeline.
- `World::raycast_all` (`world.rs`): Casts a ray and returns all hits along it.
- `World::query_aabb` (`world.rs`): Returns body IDs with colliders intersecting the given AABB.
- `World::get_body_at_point` (`world.rs`): Returns the first body whose collider contains the given world-space point.
- `World::add_wheel_joint` (`world.rs`): Creates a wheel joint (prismatic + rotation) between two bodies.
- `World::add_friction_joint` (`world.rs`): Creates a friction joint that resists relative motion between two bodies.
- `World::add_motor_joint` (`world.rs`): Creates a motor joint that drives body_b toward body_a's frame.
- `World::add_mouse_joint` (`world.rs`): Creates a mouse joint that connects a body to a target point via a spring.
- `World::set_mouse_joint_target` (`world.rs`): Updates the target position of a mouse joint.
- `World::add_pulley_joint` (`world.rs`): Stub: pulley joint is not supported by rapier2d.
- `World::add_gear_joint` (`world.rs`): Stub: gear joint is not supported by rapier2d.
- `World::set_joint_motor_speed` (`world.rs`): Sets the motor speed on the angular axis of a joint.
- `World::get_joint_motor_speed` (`world.rs`): Returns the motor target velocity on the angular axis of a joint.
- `World::set_joint_limits_enabled` (`world.rs`): Enables or disables limits on the angular axis of a joint.
- `World::set_joint_limits` (`world.rs`): Sets the angular limits (lower, upper) on a joint in radians.
- `World::get_joint_limits` (`world.rs`): Returns the angular limits `(lower, upper)` on a joint.
- `World::get_joint_type` (`world.rs`): Returns the type name of a joint.
- `World::set_meter` (`world.rs`): Sets the pixels-per-meter scaling factor.
- `World::get_meter` (`world.rs`): Returns the pixels-per-meter scaling factor.
- `World::to_physics` (`world.rs`): Converts a pixel value to physics units.
- `World::to_pixels` (`world.rs`): Converts a physics-unit value to pixels.
- `World::get_contacts` (`world.rs`): Returns all contact pairs from the narrow phase.
- `World::get_body_contacts` (`world.rs`): Returns contacts involving a specific body.

## Lua API Reference

- Binding path(s): `src/lua_api/physics_api.rs`
- Namespace: `lurek.physics`

### Module Functions
- `lurek.physics.newWorld`: Creates a new physics world with the given gravity vector.
- `lurek.physics.step`: Advances the physics world by dt seconds.
- `lurek.physics.destroyWorld`: Marks a physics world for destruction. Subsequent operations on the world
- `lurek.physics.newBody`: Creates a new rectangular body in the given world.
- `lurek.physics.getBody`: Returns the position and velocity of a body (x, y, vx, vy).
- `lurek.physics.setBodyVelocity`: Sets the velocity of a body.
- `lurek.physics.isSleepingAllowed`: Returns whether the body is allowed to sleep.
- `lurek.physics.setSleepingAllowed`: Sets whether the body is allowed to sleep.
- `lurek.physics.newRectangleShape`: Creates a rectangle shape userdata.
- `lurek.physics.newCircleShape`: Creates a circle shape userdata.
- `lurek.physics.newEdgeShape`: Creates an edge (line segment) shape userdata.
- `lurek.physics.newPolygonShape`: Creates a convex polygon shape userdata from flat variadic vertex pairs.
- `lurek.physics.newChainShape`: Creates a chain shape userdata from flat variadic vertex pairs.
- `lurek.physics.attachShape`: Attaches a standalone shape to a body as an additional fixture.
- `lurek.physics.getCollisions`: Returns all collision events from the last simulation step.
- `lurek.physics.debugDraw`: Enables or disables the physics debug overlay (AABB boxes and velocity vectors).

### `Body` Methods
- `Body:getId`: Returns the body's integer ID.
- `Body:getPosition`: Returns the body position (x, y).
- `Body:setPosition`: Sets the body position.
- `Body:getX`: Returns the body X position.
- `Body:getY`: Returns the body Y position.
- `Body:getVelocity`: Returns the body velocity (vx, vy).
- `Body:setVelocity`: Sets the body velocity.
- `Body:getAngle`: Returns the body angle in radians.
- `Body:setAngle`: Sets the body angle in radians.
- `Body:getAngularVelocity`: Returns the angular velocity in radians/s.
- `Body:setAngularVelocity`: Sets the angular velocity.
- `Body:getMass`: Returns the body mass.
- `Body:setMass`: Sets the body mass.
- `Body:getType`: Returns the body type as a string.
- `Body:setType`: Sets the body type.
- `Body:getWidth`: Returns the body width.
- `Body:getHeight`: Returns the body height.
- `Body:getFriction`: Returns the body friction coefficient.
- `Body:setFriction`: Sets the body friction coefficient.
- `Body:getRestitution`: Returns the body restitution (bounciness).
- `Body:setRestitution`: Sets the body restitution (bounciness).
- `Body:getLayer`: Returns the collision layer bitmask.
- `Body:setLayer`: Sets the collision layer bitmask.
- `Body:getMask`: Returns the collision mask bitmask.
- `Body:setMask`: Sets the collision mask bitmask.
- `Body:applyImpulse`: Applies a linear impulse to the body.
- `Body:applyForce`: Applies a continuous force to the body.
- `Body:applyTorque`: Applies a torque (rotational force).
- `Body:applyAngularImpulse`: Applies an angular impulse.
- `Body:getGravityScale`: Returns the per-body gravity multiplier.
- `Body:setGravityScale`: Sets the per-body gravity multiplier.
- `Body:isFixedRotation`: Returns whether rotation is locked.
- `Body:setFixedRotation`: Locks or unlocks rotation.
- `Body:getLinearDamping`: Returns the linear damping coefficient.
- `Body:setLinearDamping`: Sets the linear damping coefficient.
- `Body:getAngularDamping`: Returns the angular damping coefficient.
- `Body:setAngularDamping`: Sets the angular damping coefficient.
- `Body:isBullet`: Returns whether CCD is enabled.
- `Body:setBullet`: Enables or disables CCD.
- `Body:isSleepingAllowed`: Returns whether the body can sleep.
- `Body:setSleepingAllowed`: Sets whether the body can sleep.
- `Body:destroy`: Removes this body from the world.

### `PhysicsShape` Methods
- `PhysicsShape:getType`: Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
- `PhysicsShape:getRadius`: Returns the radius. Only valid for circle shapes.
- `PhysicsShape:getBoundingBox`: Returns the axis-aligned bounding box (x1, y1, x2, y2).
- `PhysicsShape:setDensity`: Sets the density for this shape (used when attaching to a body).
- `PhysicsShape:setFriction`: Sets the friction coefficient.
- `PhysicsShape:setRestitution`: Sets the restitution (bounciness) coefficient.
- `PhysicsShape:setSensor`: Sets whether this shape is a sensor (non-colliding trigger).
- `PhysicsShape:destroy`: Releases this shape handle (GC handles cleanup).

### `World` Methods
- `World:step`: Advances the physics simulation by dt seconds.
- `World:clear`: Resets the world, removing all bodies and joints.
- `World:getGravity`: Returns the gravity vector (gx, gy).
- `World:setGravity`: Sets the gravity vector.
- `World:setMeter`: Sets the pixels-per-meter scaling factor.
- `World:getMeter`: Returns the pixels-per-meter scaling factor.
- `World:toPhysics`: Converts a pixel value to physics units.
- `World:toPixels`: Converts a physics-unit value to pixels.
- `World:getBodyCount`: Returns the total number of bodies in the world.
- `World:getBodyIds`: Returns all body IDs in the world.
- `World:destroyBody`: Removes a body from the world.
- `World:newBody`: Creates a new rectangular body and adds it to the world.
- `World:fixtureCount`: Returns the number of fixtures on a body.
- `World:jointCount`: Returns the total number of joints.
- `World:getJointIds`: Returns all joint IDs.
- `World:getJointBodies`: Returns the two body IDs connected by a joint.
- `World:destroyJoint`: Removes a joint from the world.
- `World:getJointType`: Returns the type name of a joint.
- `World:getJointMotorSpeed`: Returns the motor speed on a joint's angular axis.
- `World:getJointLimits`: Returns the angular limits on a joint.
- `World:getBodyAtPoint`: Returns the body ID at a world-space point, or nil.
- `World:getCollisionEvents`: Returns collision events from the last step.
- `World:getBeginContactEvents`: Returns begin-contact events from the last step.
- `World:getEndContactEvents`: Returns end-contact events from the last step.
- `World:getContacts`: Returns all contact pairs from the narrow phase.
- `World:getBodyContacts`: Returns contacts involving a specific body.
- `World:setBodyType`: Changes the body type.
- `World:getBodyType`: Returns the body type as a string.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## GPU Physics Debug (v0.7.26)

### `PhysicsShapeSnapshot` (src/physics/world.rs)

Geometry-only snapshot of a single physics body. Does not depend on `crate::render`.

| Field | Type | Description |
|---|---|---|
| `x`, `y` | `f32` | Body centre in world space. |
| `half_w`, `half_h` | `f32` | Half-extents (or radius for circles). |
| `angle` | `f32` | Rotation in radians. |
| `is_static` | `bool` | True for Static / Kinematic bodies. |
| `is_sensor` | `bool` | True for Sensor bodies. |
| `is_circle` | `bool` | True when shape is a circle. |
| `hull_verts` | `Vec<[f32; 2]>` | Local-space polygon vertices; empty for box / circle. |

`World::extract_shape_snapshots()` returns `Vec<PhysicsShapeSnapshot>` for all bodies.

### `lurek.physics.drawDebugGpu(world, config?)`

Extracts shape snapshots from `world` and queues a `RenderCommand::DrawPhysicsDebug` for the current frame.
Call from `lurek.render` or `lurek.render_ui`.

**Config table fields** (all optional):

| Key | Type | Default | Description |
|---|---|---|---|
| `bodyColor` | `{f32,f32,f32,f32}` | `{0,1,0,1}` | Dynamic body outline. |
| `staticColor` | `{f32,f32,f32,f32}` | `{0.5,0.5,0.5,1}` | Static/kinematic outline. |
| `sleepColor` | `{f32,f32,f32,f32}` | `{0,0.4,0,1}` | Sleeping body outline. |
| `sensorColor` | `{f32,f32,f32,f32}` | `{0,1,1,0.7}` | Sensor (trigger) outline. |
| `lineWidth` | `number` | `1.0` | Outline thickness in pixels. |

## Notes

- Keep this module reference synchronized with `src/physics/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
