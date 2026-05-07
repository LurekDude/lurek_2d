# physics

## General Info

- Module group: `Platform Services`
- Source path: `src/physics/`
- Lua API path(s): `src/lua_api/physics_api.rs`
- Primary Lua namespace: `lurek.physics`
- Rust test path(s): src/physics/world_tests.rs, inline #[cfg(test)] in body.rs, shape.rs, zone.rs, cellular.rs, terrain.rs, render.rs, collision_helpers.rs
- Lua test path(s): none found in the workspace

## Summary

The `physics` module provides Lurek2D's rigid-body physics simulation backed by rapier2d 0.32. It is a Platform Services tier module that exposes a comprehensive 2D physics API for game scripts while handling all rapier pipeline complexity internally. Physics is classified CORE-KEEP — too central to 2D games to extract as a plugin.

**World and simulation step.** `World` owns the complete rapier simulation state: rigid body set, collider set, joint set, broad-phase, narrow-phase, integration parameters, and the pipeline. `World::step(dt)` advances by one time step: syncing body property changes into rapier, running the pipeline, and reading back positions/velocities for dynamic bodies. `World::step_fixed(accumulated_dt, step_dt, max_steps)` provides fixed-timestep sub-stepping for deterministic simulation with accumulator-based variable frame rate handling. `World::get_collision_events()` returns `Vec<BodyContact>` for script-side response each frame.

**Bodies and shapes.** `Body` instances are created with `BodyType` (Dynamic, Kinematic, Static, Sensor) and `BodyShape` (Rect or Circle). Sensor bodies detect overlaps without impulse responses. The extended `Shape` enum supports polygons, edges, and chains for complex static geometry. `StandaloneShape` wraps a `Shape` with default fixture parameters for reuse across multiple bodies. Each `Body` carries mass, restitution, friction, linear/angular velocity, and a category+mask bit field for collision filtering.

**Spatial queries.** `World::raycast(origin, direction, max_distance, mask)` returns `Option<RaycastHit>` with hit point, normal, and body reference. `World::overlap_rect(rect, mask)` and `World::overlap_circle(center, radius, mask)` return lists of overlapping body IDs. `World::contact_pairs()` returns current narrow-phase `ContactInfo` snapshots for detailed per-pair inspection.

**Joints.** Revolute (pin joint with optional motor and limits), prismatic (slider), distance (spring), weld (rigid), rope (max-distance constraint), wheel (prismatic + rotation for vehicles), friction (linear/angular), motor, and mouse (spring toward a dragged target). Pulley and gear joints are stubs that fall back to distance and revolute joints.

**Physics zones.** `PhysicsZone` adds per-region gravity and damping overrides applied before each pipeline step. Zone boundaries are circles, rectangles, or convex polygons. `ZoneGravityMode` can scale world gravity, replace it, or apply an attractor/repulsor force. `ZoneEvent` fires when bodies enter or leave zones. `ZoneTracker` provides change-detection for zone membership. Used for water, low-gravity fields, and directional wind.

**Destructible terrain.** `TerrainMap` is a bitgrid-backed static collider system for Worms-style terrain deformation. The grid is divided into 16x16 `Chunk` regions, each backed by a rapier compound shape built from edge segments. `set_cell(x, y, solid)` marks cells; `flush()` rebuilds changed chunk colliders. `apply_circle_damage(cx, cy, radius)` removes all cells within a radius and marks affected chunks dirty.

**Cellular automaton.** `CellularWorld` is a falling-sand simulation independent of rapier, operating on a per-cell material grid. `CellType` variants: Sand, Water, Fire, Gas, Rock (immovable). Each `tick()` applies gravity rules, material interaction (fire spreads, water flows, gas rises). Palette configuration controls per-type colours. `to_image()` exports the current state for GPU upload.

**Collision helpers.** `collision_helpers` provides lightweight stateless geometric collision utilities (AABB, circle, point-in-shape) that complement the full rapier pipeline for scripted pre-checks without spawning physics bodies.

**Lua surface.** `lurek.physics.newWorld(gravity_x, gravity_y)`. World methods: `addBody(spec)` returns body_id, `removeBody(id)`, `getBody(id)`, `setBodyPos(id, x, y)`, `setBodyVel(id, vx, vy)`, `step(dt)`, `getCollisions()`, `raycast(ox, oy, dx, dy, dist, mask)`, `addJoint(type, id_a, id_b, params)`. Zone: `addZone(spec)` returns zone_id, `removeZone(id)`. Terrain: `newTerrain(w, h)`. Cellular: `newCellular(w, h)`.

**Scope boundary.** Platform Services tier. Depends on `math`, `runtime`, `image`, `render` (debug commands), `rapier2d`. Lua bridge in `src/lua_api/physics_api.rs`.

## Files

- `body.rs`: Script-facing rigid-body types, constructors, bounding boxes, and local/world point helpers.
- `cellular.rs`: Cellular automaton simulation: falling-sand, water, fire, and gas.
- `collision.rs`: Backward-compatible `CollisionInfo` contact record retained on the public API surface.
- `collision_helpers.rs`: Lightweight stateless geometric collision helpers.
- `mod.rs`: Module root and public re-export surface for bodies, shapes, collision records, and the world.
- `render.rs`: Debug overlay render-command generation and CPU image export for headless inspection.
- `shape.rs`: Extended collider geometry and reusable standalone fixture descriptors.
- `terrain.rs`: Destructible terrain: a bitgrid-backed static collider system for Worms-style and Tanks-style terrain deformation.
- `world.rs`: Simulation owner for rapier sets, body and collider mappings, joints, stepping, events, and spatial queries.
- `zone.rs`: Physics zone system: gravity areas, attractor/repulsor regions, and zero-gravity pockets.

## Types

- `BodyType` (`enum`, `body.rs`): Simulation mode selector for static, dynamic, kinematic, and sensor bodies.
- `BodyShape` (`enum`, `body.rs`): Lightweight common-shape enum for rectangle and circle bodies.
- `Body` (`struct`, `body.rs`): Lua-friendly rigid-body record mirrored into and out of rapier state.
- `CellType` (`enum`, `cellular.rs`): The material type of a single cell in a [`CellularWorld`].
- `CellularWorld` (`struct`, `cellular.rs`): A falling-sand cellular automaton grid.
- `CollisionInfo` (`struct`, `collision.rs`): Legacy compatibility record still exposed alongside newer contact models.
- `Shape` (`enum`, `shape.rs`): Extended collider enum for polygons, edges, chains, and the simple primitive cases.
- `StandaloneShape` (`struct`, `shape.rs`): Reusable shape-plus-fixture descriptor for attaching extra colliders.
- `ChunkId` (`struct`, `terrain.rs`): Identifies a `CHUNK_SIZE Ã— CHUNK_SIZE` cell block by its position in chunk coordinate space.
- `TerrainMap` (`struct`, `terrain.rs`): Bitgrid-backed destructible terrain with chunked static physics colliders.
- `BodyContact` (`struct`, `world.rs`): Stable-ID collision event emitted from simulation results.
- `RaycastHit` (`struct`, `world.rs`): Query result carrying hit body, hit point, normal, and distance.
- `ContactInfo` (`struct`, `world.rs`): Narrow-phase contact snapshot for detailed per-pair inspection.
- `PhysicsShapeSnapshot` (`struct`, `world.rs`): Geometry snapshot of a single physics body for GPU debug rendering.
- `World` (`struct`, `world.rs`): Central simulation owner for bodies, joints, queries, cached collider state, and event buffers.
- `ZoneId` (`type`, `zone.rs`): Stable integer handle for a [`PhysicsZone`].
- `ZonePriority` (`type`, `zone.rs`): Ordering value used when multiple zones overlap the same body.
- `ZoneGravityMode` (`enum`, `zone.rs`): Describes how a [`PhysicsZone`] overrides world gravity for bodies inside it.
- `ZoneBoundary` (`enum`, `zone.rs`): Spatial boundary of a [`PhysicsZone`].
- `ZoneEventKind` (`enum`, `zone.rs`): Direction of a body-zone transition.
- `ZoneEvent` (`struct`, `zone.rs`): Records a body entering or leaving a [`PhysicsZone`] during a [`World::step`](super::world::World::step).
- `PhysicsZone` (`struct`, `zone.rs`): A spatial region that overrides gravity and damping for bodies inside it.
- `ZoneTracker` (`struct`, `zone.rs`): Tracks which zones each body is currently inside and produces [`ZoneEvent`]s when the membership changes.

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
- `CellType::from_u8` (`cellular.rs`): Converts a raw `u8` from serialised data into a `CellType`.
- `CellularWorld::new` (`cellular.rs`): Creates an empty cellular world filled with `Air`.
- `CellularWorld::set_cell` (`cellular.rs`): Sets the cell at `(cx, cy)` to the given material.
- `CellularWorld::get_cell` (`cellular.rs`): Returns the cell material at `(cx, cy)`.
- `CellularWorld::fill_rect` (`cellular.rs`): Fills a rectangle of cells with a given material.
- `CellularWorld::fill_circle` (`cellular.rs`): Fills a circle of cells centred at `(cx_c, cy_c)` with radius `r_cells`.
- `CellularWorld::step` (`cellular.rs`): Advances the simulation by one tick.
- `CellularWorld::step_n` (`cellular.rs`): Advances the simulation by `n` ticks.
- `CellularWorld::to_image_data` (`cellular.rs`): Generates an RGBA pixel buffer for the full grid.
- `CellularWorld::to_image_data_region` (`cellular.rs`): Generates an RGBA pixel buffer for a rectangular sub-region of the grid.
- `CellularWorld::find_cells` (`cellular.rs`): Returns all cell positions of a given material type.
- `CellularWorld::count_cells` (`cellular.rs`): Counts the number of cells of a given material.
- `CellularWorld::to_bytes` (`cellular.rs`): Serialises the cell grid to a byte buffer.
- `CellularWorld::from_bytes` (`cellular.rs`): Deserialises a cellular world from bytes produced by [`to_bytes`](CellularWorld::to_bytes).
- `default_palette` (`cellular.rs`): Returns the default RGBA colour for `cell`.
- `test_aabb` (`collision_helpers.rs`): Returns `true` when two axis-aligned bounding boxes overlap.
- `test_circles` (`collision_helpers.rs`): Returns `true` when two circles overlap.
- `test_point_aabb` (`collision_helpers.rs`): Returns `true` when point `(px, py)` lies inside the AABB at origin `(ax, ay)` with size `(aw, ah)`.
- `test_circle_aabb` (`collision_helpers.rs`): Returns `true` when a circle (centre `(cx, cy)`, radius `cr`) overlaps the AABB.
- `World::generate_render_commands` (`render.rs`): Generate debug render commands for all physics bodies.
- `World::draw_to_image` (`render.rs`): Render the physics world to a CPU image for headless testing or export.
- `Shape::to_rapier_collider` (`shape.rs`): Converts this shape into a rapier2d `ColliderBuilder`.
- `Shape::from_parts` (`shape.rs`): Creates a `Shape` from a type string and flat float argument list.
- `Shape::regular_polygon` (`shape.rs`): Creates a regular polygon with the given radius and number of sides.
- `StandaloneShape::new` (`shape.rs`): Creates a new `StandaloneShape` with default fixture parameters.
- `StandaloneShape::get_type` (`shape.rs`): Returns the shape type name.
- `StandaloneShape::get_radius` (`shape.rs`): Returns the radius for circle shapes.
- `StandaloneShape::get_bounding_box` (`shape.rs`): Returns an axis-aligned bounding box for this shape as `(min_x, min_y, max_x, max_y)`.
- `TerrainMap::new` (`terrain.rs`): Creates an empty terrain map (all cells non-solid, no dirty chunks).
- `TerrainMap::set_cell` (`terrain.rs`): Sets a single cell solid or empty, marking the containing chunk dirty.
- `TerrainMap::get_cell` (`terrain.rs`): Returns `true` if the cell at `(cx, cy)` is solid.
- `TerrainMap::fill_circle` (`terrain.rs`): Fills a circle of cells centred at world position `(wx, wy)`.
- `TerrainMap::fill_rect` (`terrain.rs`): Fills an axis-aligned rectangle of cells whose world extent covers `(wx, wy, w, h)`.
- `TerrainMap::fill_all` (`terrain.rs`): Sets every cell in the grid to `solid` and marks all chunks dirty.
- `TerrainMap::is_dirty` (`terrain.rs`): Returns `true` when at least one chunk is dirty and needs flushing.
- `TerrainMap::flush` (`terrain.rs`): Rebuilds physics bodies for all dirty chunks and clears the dirty set.
- `TerrainMap::collapse_columns` (`terrain.rs`): Removes unsupported cells, simulating gravity-driven column collapse.
- `TerrainMap::solid_cell_positions` (`terrain.rs`): Returns the world-space centres of all currently solid cells.
- `TerrainMap::spawn_debris_at` (`terrain.rs`): Spawns a dynamic debris body at each position in `positions`.
- `TerrainMap::to_image_data` (`terrain.rs`): Generates an RGBA pixel buffer for the terrain grid.
- `TerrainMap::to_bytes` (`terrain.rs`): Serialises the terrain to a compact byte buffer.
- `TerrainMap::from_bytes` (`terrain.rs`): Deserialises a terrain from bytes produced by [`to_bytes`](TerrainMap::to_bytes).
- `TerrainMap::load_from_bytes` (`terrain.rs`): Replaces this terrain's cell data with data deserialized from `bytes`.
- `World::draw_debug_to_image` (`world.rs`): Draw debug physics colliders to an ImageData target.
- `World::extract_shape_snapshots` (`world.rs`): Returns a snapshot of each body's shape geometry for GPU debug rendering.
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
- `World::add_zone` (`world.rs`): Registers a new gravity/damping zone and returns its stable `ZoneId`.
- `World::remove_zone` (`world.rs`): Removes a zone by ID.
- `World::zone_mut` (`world.rs`): Returns a mutable reference to the zone with the given ID, if it exists.
- `World::get_zone_events` (`world.rs`): Returns all zone enter/leave events from the most recent `step`.
- `World::apply_zone_forces` (`world.rs`): Applies zone gravity and damping overrides to all dynamic bodies.
- `World::step_fixed` (`world.rs`): Steps the simulation a variable number of fixed sub-steps to consume an accumulated time delta without accumulating spiral-of-death lag.
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
- `World::set_body_one_way` (`world.rs`): Marks body `id` as a one-way platform with outward normal `(nx, ny)`.
- `World::clear_body_one_way` (`world.rs`): Clears the one-way configuration for a body, making it fully solid.
- `World::get_body_one_way` (`world.rs`): Returns the one-way normal for a body, if configured.
- `World::set_joint_break_force` (`world.rs`): Sets the relative-velocity break threshold for a joint.
- `World::get_joint_break_force` (`world.rs`): Returns the break threshold for a joint, if set.
- `World::is_body_sleeping` (`world.rs`): Returns whether a body is currently sleeping (inactive).
- `World::wake_up_body` (`world.rs`): Forcibly wakes up a sleeping body.
- `World::sleep_body` (`world.rs`): Puts a body to sleep immediately, regardless of velocity.
- `World::set_solver_iterations` (`world.rs`): Sets the number of constraint solver iterations per physics step.
- `World::get_solver_iterations` (`world.rs`): Returns the current number of constraint solver iterations per step.
- `World::add_bodies` (`world.rs`): Creates multiple bodies in a single call.
- `ZoneBoundary::contains` (`zone.rs`): Returns `true` when `(px, py)` lies inside this boundary.
- `PhysicsZone::new_rect` (`zone.rs`): Creates a new rectangular zone with zero-gravity mode, affecting all layers.
- `PhysicsZone::set_circle` (`zone.rs`): Replaces the zone boundary with a circle.
- `PhysicsZone::set_gravity_directional` (`zone.rs`): Sets directional gravity inside the zone.
- `PhysicsZone::set_gravity_point` (`zone.rs`): Sets point-attractor gravity inside the zone.
- `PhysicsZone::set_gravity_repulsor` (`zone.rs`): Sets point-repulsor gravity inside the zone.
- `PhysicsZone::set_gravity_zero` (`zone.rs`): Sets the zone to suppress gravity (zero-gravity pocket).
- `PhysicsZone::contains` (`zone.rs`): Returns `true` when position `(px, py)` lies inside the zone boundary.
- `ZoneTracker::new` (`zone.rs`): Creates an empty tracker.
- `ZoneTracker::update` (`zone.rs`): Updates membership for `body_id` and returns any enter/leave events.
- `ZoneTracker::remove_body` (`zone.rs`): Removes all tracking state for a body.
- `ZoneTracker::clear` (`zone.rs`): Purges all tracking state.

## Lua API Reference

- Binding path(s): `src/lua_api/physics_api.rs`
- Namespace: `lurek.physics`

### Module Functions
- `lurek.physics.newWorld`: Creates a new physics world with the given gravity vector.
- `lurek.physics.step`: Advances the physics world by dt seconds.
- `lurek.physics.destroyWorld`: Marks a physics world for destruction.
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
- `lurek.physics.drawDebugGpu`: Queues a GPU physics debug draw command for the current frame.
- `lurek.physics.newTerrain`: Creates a destructible terrain grid.
- `lurek.physics.newCellular`: Creates a falling-sand cellular automaton grid.
- `lurek.physics.testAABB`: Returns true when two axis-aligned bounding boxes overlap.
- `lurek.physics.testCircles`: Returns true when two circles overlap.
- `lurek.physics.testPoint`: Returns true when point (px, py) lies inside the AABB.
- `lurek.physics.testCircleAABB`: Returns true when a circle overlaps an AABB.

### `LBody` Methods
- `LBody:getId`: Returns the body's integer ID.
- `LBody:getPosition`: Returns the body position (x, y).
- `LBody:setPosition`: Teleports the body to the given world-space position, bypassing collision.
- `LBody:getX`: Returns the body X position.
- `LBody:getY`: Returns the body Y position.
- `LBody:getVelocity`: Returns the body velocity (vx, vy).
- `LBody:setVelocity`: Sets the body's linear velocity in world units per second.
- `LBody:getAngle`: Returns the body angle in radians.
- `LBody:setAngle`: Sets the body angle in radians.
- `LBody:getAngularVelocity`: Returns the angular velocity in radians/s.
- `LBody:setAngularVelocity`: Sets the angular velocity.
- `LBody:getMass`: Returns the body mass in kilograms used for force and impulse calculations.
- `LBody:setMass`: Sets the body mass; affects how forces and impulses change velocity.
- `LBody:getType`: Returns the body type as a string.
- `LBody:setType`: Changes the body type: `"dynamic"`, `"static"`, or `"kinematic"`.
- `LBody:getWidth`: Returns the width of this body's primary collider shape in world units.
- `LBody:getHeight`: Returns the height of this body's primary collider shape in world units.
- `LBody:getFriction`: Returns the body friction coefficient.
- `LBody:setFriction`: Sets the body friction coefficient.
- `LBody:getRestitution`: Returns the body restitution (bounciness).
- `LBody:setRestitution`: Sets the body restitution (bounciness).
- `LBody:getLayer`: Returns the collision layer bitmask.
- `LBody:setLayer`: Sets the collision layer bitmask.
- `LBody:getMask`: Returns the collision mask bitmask.
- `LBody:setMask`: Sets the collision mask bitmask.
- `LBody:applyImpulse`: Applies a linear impulse to the body.
- `LBody:applyForce`: Applies a continuous force to the body.
- `LBody:applyTorque`: Applies a torque (rotational force).
- `LBody:applyForceAtPoint`: Applies a force at a specific world-space point.
- `LBody:applyAngularImpulse`: Applies an angular impulse.
- `LBody:getGravityScale`: Returns the per-body gravity multiplier.
- `LBody:setGravityScale`: Sets the per-body gravity multiplier.
- `LBody:isFixedRotation`: Returns whether rotation is locked.
- `LBody:setFixedRotation`: Locks or unlocks rotation.
- `LBody:getLinearDamping`: Returns the linear damping coefficient.
- `LBody:setLinearDamping`: Sets the linear damping coefficient.
- `LBody:getAngularDamping`: Returns the angular damping coefficient.
- `LBody:setAngularDamping`: Sets the angular damping coefficient.
- `LBody:isBullet`: Returns whether CCD is enabled.
- `LBody:setBullet`: Enables or disables continuous collision detection (CCD) for fast-moving bodies.
- `LBody:isSleepingAllowed`: Returns whether the body can sleep.
- `LBody:setSleepingAllowed`: Sets whether the body can sleep.
- `LBody:destroy`: Removes this body from the world.
- `LBody:isSleeping`: Returns true if this body is currently sleeping (inactive).
- `LBody:wakeUp`: Forcibly wakes up this body.
- `LBody:sleep`: Puts this body to sleep immediately.
- `LBody:type`: Returns the type name of this object.
- `LBody:typeOf`: Returns true if this object is of the given type.

### `LCellular` Methods
- `LCellular:setCell`: Sets the material of a cell.
- `LCellular:getCell`: Returns the material at `(cx, cy)` as an integer constant.
- `LCellular:fillRect`: Fills a rectangular region of cells with the given material.
- `LCellular:fillCircle`: Fills a circle of cells with the given material.
- `LCellular:step`: Advances the simulation by one tick.
- `LCellular:stepN`: Advances the simulation by `n` ticks.
- `LCellular:toImageData`: Returns the full grid as an RGBA byte string using the default colour palette.
- `LCellular:toImageDataRegion`: Returns a sub-region as an RGBA byte string.
- `LCellular:countCells`: Counts cells of the given material type.
- `LCellular:findCells`: Returns positions of all cells of the given material as an array of `{x, y}` tables.
- `LCellular:toBytes`: Serialises the grid to a byte string.
- `LCellular:loadFromBytes`: Loads grid data from bytes produced by `toBytes`.
- `LCellular:type`: Returns the type name of this object.
- `LCellular:typeOf`: Returns true if this object is of the given type.

### `LPhysicsShape` Methods
- `LPhysicsShape:getType`: Returns the shape type string: "circle", "rectangle", "polygon", "edge", or "chain".
- `LPhysicsShape:getRadius`: Returns the radius. Only valid for circle shapes.
- `LPhysicsShape:getBoundingBox`: Returns the axis-aligned bounding box (x1, y1, x2, y2).
- `LPhysicsShape:setDensity`: Sets the density for this shape (used when attaching to a body).
- `LPhysicsShape:setFriction`: Sets the friction coefficient.
- `LPhysicsShape:setRestitution`: Sets the restitution (bounciness) coefficient.
- `LPhysicsShape:setSensor`: Sets whether this shape is a sensor (non-colliding trigger).
- `LPhysicsShape:destroy`: Releases this shape handle (GC handles cleanup).
- `LPhysicsShape:type`: Returns the type name of this object.
- `LPhysicsShape:typeOf`: Returns true if this object is of the given type.

### `LTerrain` Methods
- `LTerrain:setCell`: Sets a single terrain cell to solid or empty.
- `LTerrain:getCell`: Returns whether a cell is solid.
- `LTerrain:fillCircle`: Fills a circle of cells centred at world position `(wx, wy)`.
- `LTerrain:fillRect`: Fills a rectangular region of cells.
- `LTerrain:fillAll`: Sets every cell in the grid to `solid`.
- `LTerrain:flush`: Rebuilds physics bodies for all dirty chunks.
- `LTerrain:isDirty`: Returns `true` when at least one chunk needs flushing.
- `LTerrain:collapseColumns`: Removes unsupported cells, returning the number of cells that fell.
- `LTerrain:solidPositions`: Returns the world-space centres of all solid cells as an array of `{x, y}` tables.
- `LTerrain:spawnDebris`: Spawns dynamic debris bodies at the given positions.
- `LTerrain:toImageData`: Returns the terrain as an RGBA byte string.
- `LTerrain:toBytes`: Serialises the terrain grid to a byte string for save/load.
- `LTerrain:loadFromBytes`: Loads terrain cell data from bytes produced by `toBytes`.
- `LTerrain:type`: Returns the type name of this object.
- `LTerrain:typeOf`: Returns true if this object is of the given type.

### `LWorld` Methods
- `LWorld:drawDebug`: Draws physics objects into an image for debugging.
- `LWorld:step`: Advances the physics simulation by `dt` seconds.
- `LWorld:clear`: Resets the world, removing all bodies and joints.
- `LWorld:getGravity`: Returns the gravity vector (gx, gy).
- `LWorld:setGravity`: Sets the world gravity vector; default is `(0, 9.81)` (downward).
- `LWorld:setMeter`: Sets the pixels-per-meter scaling factor.
- `LWorld:getMeter`: Returns the pixels-per-meter scaling factor.
- `LWorld:toPhysics`: Converts a pixel value to physics units.
- `LWorld:toPixels`: Converts a physics-unit value to pixels.
- `LWorld:getBodyCount`: Returns the total number of bodies in the world.
- `LWorld:getBodyIds`: Returns all body IDs in the world.
- `LWorld:destroyBody`: Removes a body from the world.
- `LWorld:newBody`: Creates a new rectangular body and adds it to the world.
- `LWorld:newCircleBody`: Creates a new circular body and adds it to the world.
- `LWorld:newPolygonBody`: Creates a new polygon body from a flat vertex table and adds it to the world.
- `LWorld:newEdgeBody`: Creates a new edge (line segment) body and adds it to the world.
- `LWorld:newChainBody`: Creates a new chain body from a flat vertex table and adds it to the world.
- `LWorld:addFixture`: Adds an extra fixture (collider) to a body.
- `LWorld:fixtureCount`: Returns the number of fixtures on a body.
- `LWorld:setFixtureFriction`: Sets friction on a fixture by index.
- `LWorld:setFixtureRestitution`: Sets restitution on a fixture by index.
- `LWorld:setFixtureSensor`: Sets whether a fixture is a sensor.
- `LWorld:addRevoluteJoint`: Creates a revolute (pin) joint between two bodies.
- `LWorld:addDistanceJoint`: Creates a distance joint between two bodies.
- `LWorld:addPrismaticJoint`: Creates a prismatic (slider) joint between two bodies.
- `LWorld:addWeldJoint`: Creates a weld (rigid) joint between two bodies.
- `LWorld:addRopeJoint`: Creates a rope joint with a maximum distance.
- `LWorld:addWheelJoint`: Creates a wheel joint (prismatic + rotation).
- `LWorld:addFrictionJoint`: Creates a friction joint that resists relative motion.
- `LWorld:addMotorJoint`: Creates a motor joint that drives body_b toward body_a.
- `LWorld:addMouseJoint`: Creates a mouse joint connecting a body to a target point.
- `LWorld:addPulleyJoint`: Creates a pulley joint (stub - falls back to weld joint).
- `LWorld:addGearJoint`: Creates a gear joint (stub - falls back to weld joint).
- `LWorld:jointCount`: Returns the total number of joints.
- `LWorld:getJointIds`: Returns a table of integer IDs for every joint attached to this world.
- `LWorld:getJointBodies`: Returns the two body IDs connected by a joint.
- `LWorld:destroyJoint`: Removes a joint from the world.
- `LWorld:getJointType`: Returns the type name of a joint.
- `LWorld:setJointMotorSpeed`: Sets the motor speed on a joint's angular axis.
- `LWorld:getJointMotorSpeed`: Returns the motor speed on a joint's angular axis.
- `LWorld:setJointLimitsEnabled`: Enables or disables angular limits on a joint.
- `LWorld:setJointLimits`: Sets the angular limits on a joint.
- `LWorld:getJointLimits`: Returns the angular limits on a joint.
- `LWorld:setMouseJointTarget`: Updates the target position of a mouse joint.
- `LWorld:raycast`: Casts a ray and returns the nearest hit, or nil.
- `LWorld:raycastClosest`: Casts a ray and returns the closest hit using the query pipeline.
- `LWorld:raycastAll`: Casts a ray and returns all hits.
- `LWorld:queryAABB`: Returns body IDs within an axis-aligned bounding box.
- `LWorld:getBodyAtPoint`: Returns the body ID at a world-space point, or nil.
- `LWorld:getCollisionEvents`: Returns collision events from the last step.
- `LWorld:getBeginContactEvents`: Returns begin-contact events from the last step.
- `LWorld:getEndContactEvents`: Returns end-contact events from the last step.
- `LWorld:getContacts`: Returns all contact pairs from the narrow phase.
- `LWorld:getBodyContacts`: Returns contacts involving a specific body.
- `LWorld:setBodyType`: Changes the simulation type of the body: `"dynamic"`, `"static"`, or `"kinematic"`.
- `LWorld:getBodyType`: Returns the body type as a string.
- `LWorld:setBeginContact`: Registers a callback fired when two bodies begin touching.
- `LWorld:clearBeginContact`: Removes the begin-contact callback.
- `LWorld:setEndContact`: Registers a callback fired when two bodies stop touching.
- `LWorld:clearEndContact`: Removes the end-contact callback.
- `LWorld:setBodyData`: Attaches arbitrary Lua data to a body for later retrieval.
- `LWorld:getBodyData`: Returns the Lua data previously attached to a body, or nil if none is set.
- `LWorld:clearBodyData`: Removes the Lua data attached to a body.
- `LWorld:setBodyCCD`: Enables or disables Continuous Collision Detection for a body.
- `LWorld:getBodyCCD`: Returns whether CCD is enabled for a body.
- `LWorld:setBodyOneWay`: Marks a body as a one-way platform.
- `LWorld:clearBodyOneWay`: Removes the one-way platform flag from a body.
- `LWorld:getBodyOneWay`: Returns the one-way normal for a body, or nil if not configured.
- `LWorld:setJointBreakForce`: Sets the relative-velocity threshold above which a joint breaks.
- `LWorld:getJointBreakForce`: Returns the break threshold for a joint, or nil if not set.
- `LWorld:isBodySleeping`: Returns true if a body is currently sleeping (inactive).
- `LWorld:wakeUpBody`: Forcibly wakes up a sleeping body.
- `LWorld:sleepBody`: Puts a body to sleep immediately.
- `LWorld:setSolverIterations`: Sets the number of constraint solver iterations per step.
- `LWorld:getSolverIterations`: Returns the current number of solver iterations per step.
- `LWorld:newBodies`: Creates multiple bodies in one call.
- `LWorld:stepFixed`: Steps the world using a fixed sub-step size to consume accumulated time.
- `LWorld:addZone`: Creates a rectangular gravity or damping zone.
- `LWorld:getZoneEvents`: Returns zone enter and leave events from the most recent step.
- `LWorld:type`: Returns the type name of this object.
- `LWorld:typeOf`: Returns true if this object is of the given type.

### `LZone` Methods
- `LZone:getId`: Returns the zone's integer ID.
- `LZone:setEnabled`: Enables or disables the zone.
- `LZone:setPriority`: Sets the zone priority; higher values win over lower when zones overlap.
- `LZone:setLayerMask`: Sets the layer bitmask; only bodies whose `layer & mask != 0` are affected.
- `LZone:setCircle`: Replaces the zone boundary with a circle.
- `LZone:setGravityDirectional`: Sets directional gravity inside the zone.
- `LZone:setGravityPoint`: Sets point-attractor gravity inside the zone.
- `LZone:setGravityRepulsor`: Sets point-repulsor gravity inside the zone.
- `LZone:setGravityZero`: Suppresses gravity inside the zone (zero-g pocket).
- `LZone:setLinearDampingOverride`: Sets an optional linear damping override for bodies inside the zone.
- `LZone:setAngularDampingOverride`: Sets an optional angular damping override for bodies inside the zone.
- `LZone:destroy`: Removes the zone from the world.
- `LZone:type`: Returns the type name of this object.
- `LZone:typeOf`: Returns true if this object is of the given type.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/physics/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
