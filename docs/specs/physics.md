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

- `Body::new` (`body.rs`): Create a rectangular body at `(x,y)` with default 32×32 dimensions.
- `Body::new_circle` (`body.rs`): Create a circular body at `(x,y)` with the given `radius`.
- `Body::new_polygon` (`body.rs`): Create a polygon body at `(x,y)` from a vertex list; AABB derived from vertex bounds.
- `Body::new_edge` (`body.rs`): Create an edge (line segment) body from `v1` to `v2` anchored at `(x,y)`.
- `Body::new_chain` (`body.rs`): Create a chain (open or closed polyline) body anchored at `(x,y)`.
- `Body::bounding_box` (`body.rs`): Return the axis-aligned bounding box of this body in world space.
- `Body::collides_with_layer` (`body.rs`): Return true when this body's layer and mask are compatible with `other`.
- `Body::get_bounding_box` (`body.rs`): Return the bounding box as `(x, y, width, height)` tuple.
- `Body::get_type` (`body.rs`): Return the body type as a static string slice.
- `Body::get_world_point` (`body.rs`): Convert a local-space offset to world-space position accounting for body rotation.
- `Body::get_local_point` (`body.rs`): Convert a world-space position to a local-space offset accounting for body rotation.
- `CellType::from_u8` (`cellular.rs`): Map a raw `u8` to `CellType`; unmapped values return `Air`.
- `CellularWorld::new` (`cellular.rs`): Create an all-air grid of `width`×`height` cells.
- `CellularWorld::set_cell` (`cellular.rs`): Set the cell at `(cx,cy)` to `cell`; initializes fire lifetime when cell is Fire.
- `CellularWorld::get_cell` (`cellular.rs`): Return the cell type at `(cx,cy)`; returns Air when out of bounds.
- `CellularWorld::fill_rect` (`cellular.rs`): Fill a rectangular region with `cell`; clips to grid bounds.
- `CellularWorld::fill_circle` (`cellular.rs`): Fill a circular region of radius `r_cells` around `(cx_c,cy_c)` with `cell`.
- `CellularWorld::step` (`cellular.rs`): Advance the simulation by one tick, applying material rules to every cell.
- `CellularWorld::step_n` (`cellular.rs`): Run `n` simulation steps.
- `CellularWorld::to_image_data` (`cellular.rs`): Encode the full grid as RGBA pixel data using `palette`.
- `CellularWorld::to_image_data_region` (`cellular.rs`): Encode a rectangular sub-region as RGBA pixel data using `palette`.
- `CellularWorld::find_cells` (`cellular.rs`): Return all `(cx,cy)` positions containing `cell_type`.
- `CellularWorld::count_cells` (`cellular.rs`): Return the count of cells matching `cell_type`.
- `CellularWorld::to_bytes` (`cellular.rs`): Serialize the grid to a compact byte buffer (`width u32 LE` + `height u32 LE` + cell bytes).
- `CellularWorld::from_bytes` (`cellular.rs`): Deserialize a grid from a byte buffer produced by `to_bytes`; return `None` on malformed input.
- `default_palette` (`cellular.rs`): Returns the default RGBA colour for `cell`.
- `test_aabb` (`collision_helpers.rs`): Returns `true` when two axis-aligned bounding boxes overlap.
- `test_circles` (`collision_helpers.rs`): Returns `true` when two circles overlap.
- `test_point_aabb` (`collision_helpers.rs`): Returns `true` when point `(px, py)` lies inside the AABB at origin `(ax, ay)` with size `(aw, ah)`.
- `test_circle_aabb` (`collision_helpers.rs`): Returns `true` when a circle (centre `(cx, cy)`, radius `cr`) overlaps the AABB.
- `World::generate_render_commands` (`render.rs`): Build a list of `RenderCommand`s drawing outlines and velocity arrows for all bodies.
- `World::draw_to_image` (`render.rs`): Rasterise all bodies onto a `width`×`height` `ImageData` centered at the origin.
- `Shape::to_rapier_collider` (`shape.rs`): Convert this shape to a rapier `ColliderBuilder`; return `None` for degenerate inputs.
- `Shape::from_parts` (`shape.rs`): Parse a shape from a string type tag and flat argument list; `closed` applies to chains.
- `Shape::regular_polygon` (`shape.rs`): Create a regular convex polygon with `sides` (clamped 3–8) inscribed in `radius`.
- `StandaloneShape::new` (`shape.rs`): Create a standalone shape with default material values.
- `StandaloneShape::get_type` (`shape.rs`): Return a static string label for the shape type.
- `StandaloneShape::get_radius` (`shape.rs`): Return the circle radius when the inner shape is a `Circle`; otherwise `None`.
- `StandaloneShape::get_bounding_box` (`shape.rs`): Return the local-space AABB as `(min_x, min_y, max_x, max_y)`.
- `TerrainMap::new` (`terrain.rs`): Create an empty terrain map of `width`×`height` cells with `cell_size` world units each.
- `TerrainMap::set_cell` (`terrain.rs`): Set the solid state of cell `(cx,cy)`; marks the owning chunk dirty when the value changes.
- `TerrainMap::get_cell` (`terrain.rs`): Return whether cell `(cx,cy)` is solid; false when out of bounds.
- `TerrainMap::fill_circle` (`terrain.rs`): Set all cells within `radius` world units of `(wx,wy)` to `solid`.
- `TerrainMap::fill_rect` (`terrain.rs`): Set all cells overlapping the world-space rectangle to `solid`.
- `TerrainMap::fill_all` (`terrain.rs`): Set every cell to `solid` and mark all chunks dirty.
- `TerrainMap::is_dirty` (`terrain.rs`): Return true when any chunks are pending a `flush`.
- `TerrainMap::flush` (`terrain.rs`): Rebuild bodies in all dirty chunks and sync them into `world`.
- `TerrainMap::collapse_columns` (`terrain.rs`): Remove isolated single-cell pillars with no support; return the count removed.
- `TerrainMap::solid_cell_positions` (`terrain.rs`): Return the world-space centres of all solid cells.
- `TerrainMap::spawn_debris_at` (`terrain.rs`): Spawn a dynamic debris body in `world` for each position in `positions`; return body ids.
- `TerrainMap::to_image_data` (`terrain.rs`): Encode the terrain as RGBA pixel data using `solid_rgba` and `empty_rgba`.
- `TerrainMap::to_bytes` (`terrain.rs`): Serialise to a compact byte buffer: `width u32 LE` + `height u32 LE` + `cell_size f32 LE` + bitpacked cells.
- `TerrainMap::from_bytes` (`terrain.rs`): Deserialise from a byte buffer produced by `to_bytes`; marks all chunks dirty; return `None` on error.
- `TerrainMap::load_from_bytes` (`terrain.rs`): Load bytes into this map if dimensions match; return false on mismatch or parse error.
- `World::draw_debug_to_image` (`world.rs`): Draw all body outlines onto an RGBA `ImageData` using the given colour.
- `World::extract_shape_snapshots` (`world.rs`): Return a snapshot of all body shapes suitable for debug rendering.
- `World::new` (`world.rs`): Create a world with gravity `(gx, gy)` in pixels/s².
- `World::add_body` (`world.rs`): Insert a body into the world and return its id.
- `World::add_fixture` (`world.rs`): Add an extra collider shape to an existing body; returns the fixture index.
- `World::fixture_count` (`world.rs`): Return the number of colliders attached to `body_id`.
- `World::set_fixture_friction` (`world.rs`): Set friction on a specific fixture of `body_id`.
- `World::set_fixture_restitution` (`world.rs`): Set restitution (bounciness) on a specific fixture of `body_id`.
- `World::set_fixture_sensor` (`world.rs`): Enable or disable the sensor flag on a specific fixture of `body_id`.
- `World::get_body` (`world.rs`): Return a shared reference to body `id`, or `None` if out of range.
- `World::get_body_mut` (`world.rs`): Return a mutable reference to body `id`, or `None` if out of range.
- `World::body_count` (`world.rs`): Return the total number of bodies in the world.
- `World::add_revolute_joint` (`world.rs`): Add a revolute joint between two bodies at the given local anchor; return joint id.
- `World::raycast` (`world.rs`): Cast a ray from `(x1,y1)` to `(x2,y2)` and return the first hit, or `None`.
- `World::step` (`world.rs`): Step the simulation by `dt` seconds; synchronises body state with rapier.
- `World::apply_impulse` (`world.rs`): Apply a linear impulse `(ix, iy)` to body `id`.
- `World::get_collision_events` (`world.rs`): Return overlap events collected during the last `step`.
- `World::get_begin_contact_events` (`world.rs`): Return body-pair ids that began touching during the last `step`.
- `World::get_end_contact_events` (`world.rs`): Return body-pair ids that stopped touching during the last `step`.
- `World::add_zone` (`world.rs`): Register a trigger zone and return its id.
- `World::remove_zone` (`world.rs`): Remove the zone with the given id.
- `World::zone_mut` (`world.rs`): Return a mutable reference to zone `id`, or `None` if not found.
- `World::get_zone_events` (`world.rs`): Return zone enter/exit events from the last `step`.
- `World::apply_zone_forces` (`world.rs`): Apply per-zone gravity/damping overrides to all bodies; updates zone enter/exit events.
- `World::step_fixed` (`world.rs`): Run up to `max_steps` fixed substeps using `step_dt`; return steps taken and leftover dt.
- `World::set_body_position` (`world.rs`): Teleport body `id` to world position `(x, y)`.
- `World::apply_force` (`world.rs`): Apply a continuous force `(fx, fy)` to body `id` this step.
- `World::apply_torque` (`world.rs`): Apply a torque to body `id` this step.
- `World::set_angular_velocity` (`world.rs`): Set angular velocity of body `id` in radians/second.
- `World::get_angular_velocity` (`world.rs`): Return angular velocity of body `id` in radians/second; returns 0 if out of range.
- `World::get_body_angle` (`world.rs`): Return rotation angle of body `id` in radians; returns 0 if out of range.
- `World::set_body_angle` (`world.rs`): Set the rotation angle of body `id` in radians.
- `World::get_body_mass` (`world.rs`): Return the mass of body `id`; returns 0 if out of range.
- `World::set_body_mass` (`world.rs`): Override mass of body `id`.
- `World::set_gravity_scale` (`world.rs`): Set gravity scale multiplier on body `id`.
- `World::set_fixed_rotation` (`world.rs`): Lock or unlock rotation for body `id`.
- `World::set_linear_damping` (`world.rs`): Set linear damping coefficient on body `id`.
- `World::set_angular_damping` (`world.rs`): Set angular damping coefficient on body `id`.
- `World::get_gravity_scale` (`world.rs`): Return gravity scale of body `id`; returns 1.0 if out of range.
- `World::is_fixed_rotation` (`world.rs`): Return true if rotation is locked on body `id`.
- `World::get_linear_damping` (`world.rs`): Return linear damping of body `id`; returns 0 if out of range.
- `World::get_angular_damping` (`world.rs`): Return angular damping of body `id`; returns 0 if out of range.
- `World::set_bullet` (`world.rs`): Enable or disable CCD (continuous collision detection) on body `id`.
- `World::is_bullet` (`world.rs`): Return true if CCD is enabled on body `id`.
- `World::apply_force_at_point` (`world.rs`): Apply force `(fx, fy)` at world point `(px, py)` on body `id`.
- `World::apply_angular_impulse` (`world.rs`): Apply an angular impulse to body `id`.
- `World::get_body_ids` (`world.rs`): Return all valid body ids as a `Vec`.
- `World::get_joint_ids` (`world.rs`): Return all valid joint ids as a `Vec`.
- `World::get_body_type_str` (`world.rs`): Return the body-type string of `id`; returns "dynamic" if out of range.
- `World::set_body_type` (`world.rs`): Change the body type of `id` and rebuild its collider.
- `World::get_gravity` (`world.rs`): Return world gravity as `(gx, gy)`.
- `World::set_gravity` (`world.rs`): Set world gravity to `(gx, gy)`.
- `World::clear` (`world.rs`): Remove all bodies, joints, and zones; reset rapier sets.
- `World::set_sleeping_allowed` (`world.rs`): Allow or permanently prevent sleeping for body `id`.
- `World::is_sleeping_allowed` (`world.rs`): Return true if body `id` is permitted to sleep.
- `World::destroy_body` (`world.rs`): Disable body `id`; it will no longer participate in simulation.
- `World::joint_count` (`world.rs`): Return the number of registered joints.
- `World::add_distance_joint` (`world.rs`): Add a distance (rope) joint between two bodies; return joint id.
- `World::add_prismatic_joint` (`world.rs`): Add a prismatic (slide-axis) joint between two bodies; return joint id.
- `World::add_weld_joint` (`world.rs`): Add a weld (fixed) joint between two bodies; return joint id.
- `World::add_rope_joint` (`world.rs`): Add a rope joint with a maximum length; return joint id.
- `World::get_joint_bodies` (`world.rs`): Return the two body ids connected by `joint_id`, or `None` if not found.
- `World::destroy_joint` (`world.rs`): Remove joint `joint_id` from the simulation.
- `World::raycast_closest` (`world.rs`): Cast a ray from `(x1,y1)` in direction `(dx,dy)` up to `max_dist`; return closest hit.
- `World::raycast_all` (`world.rs`): Cast a ray from `(x1,y1)` in direction `(dx,dy)` and return all hits up to `max_dist`.
- `World::query_aabb` (`world.rs`): Return all body ids whose AABB overlaps the query rectangle.
- `World::get_body_at_point` (`world.rs`): Return the first body id whose AABB contains point `(x, y)`, or `None`.
- `World::add_wheel_joint` (`world.rs`): Add a wheel-style prismatic joint; return joint id.
- `World::add_friction_joint` (`world.rs`): Add a friction joint limiting linear and angular impulses; return joint id.
- `World::add_motor_joint` (`world.rs`): Add a spring-motor joint for position correction; return joint id.
- `World::add_mouse_joint` (`world.rs`): Create a kinematic anchor and a spring joint targeting `(target_x, target_y)`; return joint id.
- `World::set_mouse_joint_target` (`world.rs`): Reposition the kinematic anchor of mouse joint `joint_id` to `(x, y)`.
- `World::add_pulley_joint` (`world.rs`): Add a pulley joint (falls back to weld; logs a warning); return joint id.
- `World::add_gear_joint` (`world.rs`): Add a gear joint (falls back to weld; logs a warning); return joint id.
- `World::set_joint_motor_speed` (`world.rs`): Set angular motor target speed on joint `joint_id`.
- `World::get_joint_motor_speed` (`world.rs`): Return angular motor target speed on joint `joint_id`; returns 0 if not set.
- `World::set_joint_limits_enabled` (`world.rs`): Enable or disable angular limits on joint `joint_id`.
- `World::set_joint_limits` (`world.rs`): Set `[lower, upper]` angular limits on joint `joint_id`.
- `World::get_joint_limits` (`world.rs`): Return `(lower, upper)` angular limits on joint `joint_id`; returns `(0,0)` if not set.
- `World::get_joint_type` (`world.rs`): Return the type string of joint `joint_id`; returns "unknown" if out of range.
- `World::set_meter` (`world.rs`): Set the pixels-per-meter conversion ratio.
- `World::get_meter` (`world.rs`): Return the current pixels-per-meter ratio.
- `World::to_physics` (`world.rs`): Convert a pixel distance to physics-space metres.
- `World::to_pixels` (`world.rs`): Convert a physics-space metre distance to pixels.
- `World::get_contacts` (`world.rs`): Return all active contact pairs with normals and touch state.
- `World::get_body_contacts` (`world.rs`): Return contacts involving body `body_id` filtered from `get_contacts`.
- `World::set_body_one_way` (`world.rs`): Enable one-way platform behaviour: only accept collisions with a normal aligned to `(nx,ny)`.
- `World::clear_body_one_way` (`world.rs`): Remove the one-way constraint from body `id`.
- `World::get_body_one_way` (`world.rs`): Return the one-way normal for body `id`, or `None` if not set.
- `World::set_joint_break_force` (`world.rs`): Register a break force threshold for joint `jid`.
- `World::get_joint_break_force` (`world.rs`): Return the break-force threshold for joint `jid`, or `None` if not set.
- `World::is_body_sleeping` (`world.rs`): Return true if body `id` is currently asleep.
- `World::wake_up_body` (`world.rs`): Wake up body `id` from sleep.
- `World::sleep_body` (`world.rs`): Force body `id` to sleep immediately.
- `World::set_solver_iterations` (`world.rs`): Set the number of solver iterations (minimum 1).
- `World::get_solver_iterations` (`world.rs`): Return the current number of solver iterations.
- `World::add_bodies` (`world.rs`): Batch-create bodies from a list of `(x, y, BodyType)` tuples; return their ids.
- `ZoneBoundary::contains` (`zone.rs`): Return true if point `(px, py)` is inside this boundary.
- `PhysicsZone::new_rect` (`zone.rs`): Create a rectangular zone with zero gravity and default layer mask.
- `PhysicsZone::set_circle` (`zone.rs`): Replace the boundary with a circle centred at `(cx, cy)` with given `radius`.
- `PhysicsZone::set_gravity_directional` (`zone.rs`): Set constant directional gravity `(gx, gy)` for this zone.
- `PhysicsZone::set_gravity_point` (`zone.rs`): Set point-attractor gravity centred at `(cx, cy)` with given `strength`.
- `PhysicsZone::set_gravity_repulsor` (`zone.rs`): Set repulsor gravity pushing away from `(cx, cy)` with given `strength`.
- `PhysicsZone::set_gravity_zero` (`zone.rs`): Set zero gravity for this zone.
- `PhysicsZone::contains` (`zone.rs`): Return true if the zone is enabled and the point `(px, py)` is inside its boundary.
- `ZoneTracker::new` (`zone.rs`): Create an empty tracker.
- `ZoneTracker::update` (`zone.rs`): Diff `new_zones` against stored state for `body_id`; emit enter/leave events and update.
- `ZoneTracker::remove_body` (`zone.rs`): Remove all zone tracking state for `body_id`.
- `ZoneTracker::clear` (`zone.rs`): Clear all per-body zone state.

## Lua API Reference

- Binding path(s): `src/lua_api/physics_api.rs`
- Namespace: `lurek.physics`

### Module Functions
- `lurek.physics.newWorld`: Creates a new physics world with the given gravity vector.
- `lurek.physics.step`: Steps a physics world forward by dt seconds (free-function variant).
- `lurek.physics.destroyWorld`: No-op placeholder for API parity. Worlds are freed when no longer referenced.
- `lurek.physics.newBody`: Creates a new body in a world (free-function variant).
- `lurek.physics.getBody`: Returns position and velocity of a body (free-function variant for quick queries).
- `lurek.physics.setBodyVelocity`: Sets a body's velocity (free-function variant).
- `lurek.physics.isSleepingAllowed`: Checks if sleeping is allowed on a body (free-function variant).
- `lurek.physics.setSleepingAllowed`: Sets whether a body is allowed to sleep (free-function variant).
- `lurek.physics.newRectangleShape`: Creates a rectangle collision shape with the given dimensions.
- `lurek.physics.newCircleShape`: Creates a circle collision shape with the given radius.
- `lurek.physics.newEdgeShape`: Creates an edge (line segment) collision shape between two local points.
- `lurek.physics.newPolygonShape`: Creates a convex polygon collision shape from vertex coordinate pairs.
- `lurek.physics.newChainShape`: Creates a chain (polyline) collision shape. Useful for terrain outlines.
- `lurek.physics.attachShape`: Attaches a previously created shape to a body, using the shape's stored material properties.
- `lurek.physics.getCollisions`: Returns all collision events from the last world step as {body_a, body_b} pairs.
- `lurek.physics.debugDraw`: Enables or disables automatic physics debug overlay rendering for the next frame.
- `lurek.physics.drawDebugGpu`: Queues a GPU-rendered physics debug visualization using the world's current body state.
- `lurek.physics.newTerrain`: Creates a destructible terrain grid linked to a physics world for automatic collider generation.
- `lurek.physics.newCellular`: Creates a new cellular automaton simulation grid for particle-like physics (sand, water, fire).
- `lurek.physics.testAABB`: Tests whether two axis-aligned bounding boxes overlap. Lightweight collision check without physics world.
- `lurek.physics.testCircles`: Tests whether two circles overlap. Lightweight collision check without physics world.
- `lurek.physics.testPoint`: Tests whether a point lies inside an AABB. Lightweight check without physics world.
- `lurek.physics.testCircleAABB`: Tests whether a circle overlaps an AABB. Lightweight check without physics world.

### `LBody` Methods
- `LBody:getId`: Returns the unique numeric ID of this body within the world.
- `LBody:getPosition`: Returns the current world-space position of this body.
- `LBody:setPosition`: Teleports the body to a new world-space position (does not apply physics forces).
- `LBody:getX`: Returns only the X component of the body's position.
- `LBody:getY`: Returns only the Y component of the body's position.
- `LBody:getVelocity`: Returns the body's current linear velocity.
- `LBody:setVelocity`: Directly sets the body's linear velocity.
- `LBody:getAngle`: Returns the body's rotation angle in radians.
- `LBody:setAngle`: Sets the body's rotation angle directly.
- `LBody:getAngularVelocity`: Returns the body's angular (rotational) velocity.
- `LBody:setAngularVelocity`: Sets the body's angular velocity directly.
- `LBody:getMass`: Returns the body's total mass (computed from density and fixture areas).
- `LBody:setMass`: Overrides the body's mass directly.
- `LBody:getType`: Returns the body's type as a string.
- `LBody:setType`: Changes the body's type at runtime.
- `LBody:getWidth`: Returns the body's bounding width (from its primary shape).
- `LBody:getHeight`: Returns the body's bounding height (from its primary shape).
- `LBody:getFriction`: Returns the body's friction coefficient.
- `LBody:setFriction`: Sets the body's friction coefficient.
- `LBody:getRestitution`: Returns the body's restitution (bounciness) value.
- `LBody:setRestitution`: Sets the body's restitution (bounciness) value.
- `LBody:getLayer`: Returns the body's collision layer bitmask.
- `LBody:setLayer`: Sets the body's collision layer bitmask (which layers this body belongs to).
- `LBody:getMask`: Returns the body's collision mask (which layers this body can collide with).
- `LBody:setMask`: Sets the body's collision mask (which layers this body can collide with).
- `LBody:applyImpulse`: Applies an instantaneous linear impulse to the body's center of mass.
- `LBody:applyForce`: Applies a continuous force to the body's center of mass (accumulates over the step).
- `LBody:applyTorque`: Applies a rotational torque to the body.
- `LBody:applyForceAtPoint`: Applies a force at a specific world point, generating both linear and angular acceleration.
- `LBody:applyAngularImpulse`: Applies an instantaneous angular impulse (spin) to the body.
- `LBody:getGravityScale`: Returns the gravity scale multiplier for this body (1.0 = normal gravity).
- `LBody:setGravityScale`: Sets a per-body gravity scale multiplier (0 = no gravity, 2 = double gravity, -1 = inverted).
- `LBody:isFixedRotation`: Returns whether the body's rotation is locked.
- `LBody:setFixedRotation`: Locks or unlocks the body's rotation. Useful for player characters.
- `LBody:getLinearDamping`: Returns the linear damping factor (velocity decay rate, like air resistance).
- `LBody:setLinearDamping`: Sets the linear damping factor (higher = more velocity decay per step).
- `LBody:getAngularDamping`: Returns the angular damping factor (rotational decay rate).
- `LBody:setAngularDamping`: Sets the angular damping factor (higher = rotation decays faster).
- `LBody:isBullet`: Returns whether continuous collision detection (bullet mode) is enabled for this body.
- `LBody:setBullet`: Enables or disables continuous collision detection to prevent fast-moving tunneling.
- `LBody:isSleepingAllowed`: Returns whether the body is allowed to enter sleep state when at rest.
- `LBody:setSleepingAllowed`: Controls whether the body can enter sleep state. Disable for bodies that must stay active.
- `LBody:destroy`: Destroys this body, removing it from the world along with all fixtures and joints.
- `LBody:isSleeping`: Returns whether this body is currently in the sleeping (inactive) state.
- `LBody:wakeUp`: Wakes the body from sleep, making it active in the simulation again.
- `LBody:sleep`: Forces the body into sleep state, pausing its simulation until disturbed.
- `LBody:type`: Returns the type name of this object ("LBody").
- `LBody:typeOf`: Checks if this object is of a given type name.

### `LCellular` Methods
- `LCellular:setCell`: Sets a single cell in the cellular grid to a specific material type.
- `LCellular:getCell`: Returns the material type of a cell at the given grid position.
- `LCellular:fillRect`: Fills a rectangular region of cells with a material type.
- `LCellular:fillCircle`: Fills a circular region of cells with a material type.
- `LCellular:step`: Advances the cellular simulation by one tick (particles fall, flow, burn, etc.).
- `LCellular:stepN`: Advances the cellular simulation by N ticks in a single call.
- `LCellular:toImageData`: Renders the entire cellular grid to raw RGBA pixel data using the default material palette.
- `LCellular:toImageDataRegion`: Renders a rectangular sub-region of the cellular grid to raw RGBA pixel data.
- `LCellular:countCells`: Counts how many cells of a given material type exist in the grid.
- `LCellular:findCells`: Returns positions of all cells matching a material type.
- `LCellular:toBytes`: Serializes the cellular grid to a compact binary format for saving.
- `LCellular:loadFromBytes`: Restores cellular grid state from binary data previously produced by toBytes.
- `LCellular:type`: Returns the type name of this object ("LCellular").
- `LCellular:typeOf`: Checks if this object is of a given type name.

### `LPhysicsShape` Methods
- `LPhysicsShape:getType`: Returns the shape kind as a string: "circle", "rectangle", "polygon", "edge", or "chain".
- `LPhysicsShape:getRadius`: Returns the radius of a circle shape. Errors if called on a non-circle shape.
- `LPhysicsShape:getBoundingBox`: Returns the axis-aligned bounding box of the shape in local coordinates.
- `LPhysicsShape:setDensity`: Sets the density used when this shape is attached to a body (affects mass calculation).
- `LPhysicsShape:setFriction`: Sets the friction coefficient for this shape.
- `LPhysicsShape:setRestitution`: Sets the restitution (bounciness) for this shape.
- `LPhysicsShape:setSensor`: Marks this shape as a sensor (overlap detection only, no physical response).
- `LPhysicsShape:destroy`: No-op placeholder for API consistency. Shapes are freed when no longer referenced.
- `LPhysicsShape:type`: Returns the type name of this object ("LPhysicsShape").
- `LPhysicsShape:typeOf`: Checks if this object is of a given type name.

### `LTerrain` Methods
- `LTerrain:setCell`: Sets a single terrain cell to solid or empty.
- `LTerrain:getCell`: Returns whether a cell is solid.
- `LTerrain:fillCircle`: Fills or clears a circular region of terrain cells.
- `LTerrain:fillRect`: Fills or clears a rectangular region of terrain cells.
- `LTerrain:fillAll`: Sets all terrain cells to either solid or empty.
- `LTerrain:flush`: Regenerates physics colliders from the current terrain grid state. Call after modifying cells.
- `LTerrain:isDirty`: Returns true if terrain cells have been modified since the last flush.
- `LTerrain:collapseColumns`: Optimizes terrain by merging vertically adjacent solid cells into larger colliders.
- `LTerrain:solidPositions`: Returns all solid cell positions as a table of {x, y} entries.
- `LTerrain:spawnDebris`: Spawns small dynamic debris bodies at the given positions (for destruction effects).
- `LTerrain:toImageData`: Renders the terrain grid to raw RGBA pixel data with solid and empty colors.
- `LTerrain:toBytes`: Serializes the terrain grid to a compact binary format for saving.
- `LTerrain:loadFromBytes`: Restores terrain grid state from binary data previously produced by toBytes.
- `LTerrain:type`: Returns the type name of this object ("LTerrain").
- `LTerrain:typeOf`: Checks if this object is of a given type name.

### `LWorld` Methods
- `LWorld:drawDebug`: Renders a debug visualization of all physics bodies onto a software ImageData target.
- `LWorld:step`: Advances the physics simulation by a time delta and fires any registered contact callbacks.
- `LWorld:clear`: Removes all bodies and joints from the world, resetting it to an empty state.
- `LWorld:getGravity`: Returns the current world gravity vector.
- `LWorld:setGravity`: Sets the world gravity vector. Affects all dynamic bodies.
- `LWorld:setMeter`: Sets the pixels-per-meter scale used to convert between pixel coordinates and physics units.
- `LWorld:getMeter`: Returns the current pixels-per-meter scale.
- `LWorld:toPhysics`: Converts a pixel measurement to physics-world meters using the current meter scale.
- `LWorld:toPixels`: Converts a physics-world meter measurement to pixels using the current meter scale.
- `LWorld:getBodyCount`: Returns the total number of active bodies in the world.
- `LWorld:getBodyIds`: Returns a sequential table of all body IDs currently in the world.
- `LWorld:destroyBody`: Removes a body from the world by its ID, along with all attached fixtures and joints.
- `LWorld:newBody`: Creates a new physics body at the given position with the specified type.
- `LWorld:newCircleBody`: Creates a new body with a circle collider already attached.
- `LWorld:newPolygonBody`: Creates a new body with a convex polygon collider defined by vertex pairs.
- `LWorld:newEdgeBody`: Creates a new body with an edge (line segment) collider between two local points.
- `LWorld:newChainBody`: Creates a new body with a chain (polyline) collider. Useful for terrain edges.
- `LWorld:addFixture`: Attaches a new collider shape to an existing body with material properties.
- `LWorld:fixtureCount`: Returns how many fixtures (colliders) are attached to a body.
- `LWorld:setFixtureFriction`: Updates the friction coefficient of a specific fixture on a body.
- `LWorld:setFixtureRestitution`: Updates the restitution (bounciness) of a specific fixture on a body.
- `LWorld:setFixtureSensor`: Toggles whether a fixture acts as a sensor (overlap detection only, no physical response).
- `LWorld:addRevoluteJoint`: Creates a revolute (hinge) joint connecting two bodies at an anchor point. Bodies can rotate freely around the anchor.
- `LWorld:addDistanceJoint`: Creates a distance joint that keeps two bodies at a fixed distance apart, like a rigid rod.
- `LWorld:addPrismaticJoint`: Creates a prismatic (slider) joint that constrains body B to move along an axis relative to body A.
- `LWorld:addWeldJoint`: Creates a weld joint that rigidly connects two bodies at an anchor point (no relative movement).
- `LWorld:addRopeJoint`: Creates a rope joint limiting the maximum distance between two anchor points on two bodies.
- `LWorld:addWheelJoint`: Creates a wheel joint simulating a suspension: allows rotation and linear movement along an axis.
- `LWorld:addFrictionJoint`: Creates a friction joint that applies resistance to relative motion between two bodies.
- `LWorld:addMotorJoint`: Creates a motor joint that drives body B toward a target offset from body A using a correction factor.
- `LWorld:addMouseJoint`: Creates a mouse joint that pulls a body toward a world target point with spring-like force.
- `LWorld:addPulleyJoint`: Creates a pulley joint connecting two bodies so that movement of one affects the other inversely.
- `LWorld:addGearJoint`: Creates a gear joint that synchronizes rotation between two bodies at an anchor.
- `LWorld:jointCount`: Returns the total number of joints in the world.
- `LWorld:getJointIds`: Returns a sequential table of all joint IDs currently in the world.
- `LWorld:getJointBodies`: Returns the two body IDs connected by a joint.
- `LWorld:destroyJoint`: Removes a joint from the world, disconnecting the two bodies it linked.
- `LWorld:getJointType`: Returns the type name of a joint (e.g. "revolute", "distance", "prismatic").
- `LWorld:setJointMotorSpeed`: Sets the motor speed on a motorized joint (revolute or prismatic).
- `LWorld:getJointMotorSpeed`: Returns the current motor speed setting of a joint.
- `LWorld:setJointLimitsEnabled`: Enables or disables angular/linear limits on a joint.
- `LWorld:setJointLimits`: Sets the lower and upper bounds for a joint's limited range of motion.
- `LWorld:getJointLimits`: Returns the lower and upper limit values for a joint.
- `LWorld:setMouseJointTarget`: Moves the target position of a mouse joint, causing the attached body to follow.
- `LWorld:raycast`: Casts a ray from point (x1,y1) to (x2,y2) and returns the first body hit, or nil.
- `LWorld:raycastClosest`: Casts a directional ray from a point and returns the closest hit within max distance.
- `LWorld:raycastAll`: Casts a directional ray and returns all bodies hit within max distance as a table of results.
- `LWorld:queryAABB`: Returns all body IDs whose axis-aligned bounding boxes overlap the given rectangle.
- `LWorld:getBodyAtPoint`: Returns the body ID at a specific world point, or nil if no body is there.
- `LWorld:getCollisionEvents`: Returns all collision events from the last step as a table of {bodyA, bodyB} pairs.
- `LWorld:getBeginContactEvents`: Returns contact-begin events from the last step (pairs of bodies that started touching).
- `LWorld:getEndContactEvents`: Returns contact-end events from the last step (pairs of bodies that stopped touching).
- `LWorld:getContacts`: Returns all currently active contact manifolds with normals and touching state.
- `LWorld:getBodyContacts`: Returns all contacts involving a specific body.
- `LWorld:setBodyType`: Changes the type of an existing body (e.g. from "dynamic" to "static").
- `LWorld:getBodyType`: Returns the type name of a body as a string.
- `LWorld:setBeginContact`: Registers a callback function invoked whenever two bodies begin touching.
- `LWorld:clearBeginContact`: Removes the begin-contact callback so it is no longer called.
- `LWorld:setEndContact`: Registers a callback function invoked whenever two bodies stop touching.
- `LWorld:clearEndContact`: Removes the end-contact callback so it is no longer called.
- `LWorld:setBodyData`: Attaches arbitrary Lua data to a body ID for later retrieval (e.g. entity reference, tag).
- `LWorld:getBodyData`: Retrieves the Lua data previously attached to a body, or nil if none was set.
- `LWorld:clearBodyData`: Removes and releases the Lua data attached to a body.
- `LWorld:setBodyCCD`: Enables or disables continuous collision detection (bullet mode) on a body to prevent tunneling.
- `LWorld:getBodyCCD`: Returns whether continuous collision detection is enabled on a body.
- `LWorld:setBodyOneWay`: Marks a body as a one-way platform: other bodies can pass through from the opposite side of the normal.
- `LWorld:clearBodyOneWay`: Removes the one-way platform behavior from a body, making it block from all directions.
- `LWorld:getBodyOneWay`: Returns the one-way platform normal for a body, or nil,nil if not set.
- `LWorld:setJointBreakForce`: Sets the maximum force a joint can withstand before it breaks and is automatically destroyed.
- `LWorld:getJointBreakForce`: Returns the break force threshold for a joint.
- `LWorld:isBodySleeping`: Returns whether a body is currently in the sleeping (inactive) state.
- `LWorld:wakeUpBody`: Forces a sleeping body to wake up and participate in simulation again.
- `LWorld:sleepBody`: Forces a body into the sleeping state, pausing its simulation until disturbed.
- `LWorld:setSolverIterations`: Sets the number of velocity solver iterations. Higher values improve stability at the cost of performance.
- `LWorld:getSolverIterations`: Returns the current number of velocity solver iterations.
- `LWorld:newBodies`: Batch-creates multiple bodies at once for better performance. Each entry is {x, y, type}.
- `LWorld:stepFixed`: Performs fixed-timestep physics stepping, consuming accumulated time. Returns the leftover time.
- `LWorld:addZone`: Creates a rectangular physics zone for area-based effects (custom gravity, damping overrides).
- `LWorld:getZoneEvents`: Returns all zone enter/leave events from the last step.
- `LWorld:type`: Returns the type name of this object ("LWorld").
- `LWorld:typeOf`: Checks if this object is of a given type name. Supports inheritance (always matches "Object").

### `LZone` Methods
- `LZone:getId`: Returns the unique ID of this zone.
- `LZone:setEnabled`: Enables or disables this zone. Disabled zones have no effect on bodies.
- `LZone:setPriority`: Sets the priority of this zone. Higher-priority zones take precedence when overlapping.
- `LZone:setLayerMask`: Sets a bitmask controlling which body layers this zone affects.
- `LZone:setCircle`: Changes this zone's shape to a circle (overrides the initial rectangle).
- `LZone:setGravityDirectional`: Sets the zone to apply a constant directional gravity to bodies inside.
- `LZone:setGravityPoint`: Sets the zone to attract bodies toward a center point with a given strength.
- `LZone:setGravityRepulsor`: Sets the zone to push bodies away from a center point with a given strength.
- `LZone:setGravityZero`: Sets the zone to cancel all gravity for bodies inside (zero-G area).
- `LZone:setLinearDampingOverride`: Overrides the linear damping of bodies inside this zone, or nil to use each body's own value.
- `LZone:setAngularDampingOverride`: Overrides the angular damping of bodies inside this zone, or nil to use each body's own value.
- `LZone:destroy`: Removes this zone from the world. Bodies will no longer be affected by it.
- `LZone:type`: Returns the type name of this object ("LZone").
- `LZone:typeOf`: Checks if this object is of a given type name.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/physics/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
