# particle

## General Info

- Module group: `Feature Systems`
- Source path: `src/particle/`
- Lua API path(s): `src/lua_api/particle_api.rs`
- Primary Lua namespace: `lurek.particle`
- Rust test path(s): tests/rust/unit/particle_tests.rs
- Lua test path(s): tests/lua/unit/test_particle.lua, tests/lua/stress/test_particle_stress.lua, tests/lua/integration/test_particle_timer.lua, tests/lua/evidence/test_evidence_particle.lua

## Summary

The `particle` module implements emitter-based 2D particle systems. A `ParticleSystem` manages a bounded pool of short-lived `Particle` instances, advancing position, velocity, lifetime, rotation, and visual properties each frame with Euler integration, and recycling dead particles to keep memory allocation bounded at `ParticleConfig::max_particles`.

`ParticleConfig` (~50 fields) controls all emission and simulation parameters: particles-per-second rate, `EmissionShape` (Point, Circle, Rectangle, Ring, Line, Cone, Star, Spiral), `AreaDistribution` (None, Uniform, Normal, Ellipse, BorderEllipse, BorderRectangle), velocity spread (min/max speed and angle), rotation (initial range, angular velocity range), linear damping, radial and tangential acceleration, quadratic drag, orbital rotation, turbulence, lifetime range (min/max seconds), and multi-stop gradient interpolation for size, color, and alpha over each particle's normalized life. `InsertMode` (Top, Bottom, Random) determines where new particles are placed in the draw order.

`EmitterState` tracks whether the emitter is active, paused, or stopped. `RelativeMode` selects whether particles move in world space or follow the emitter's position after spawn. Point attractors and axis-aligned bounce bounds provide additional per-frame forces. Death sub-emitters (`death_emitter` + `death_burst_count`) enable cascading particle bursts at each particle's death position. Texture support: the `ParticleSystem` holds an optional `TextureKey`; particles are rendered as textured quads with optional flipbook animation.

`ParticleShape` is an enum of ten geometric render primitives (Square, Circle, Triangle, Spark, Diamond, Shrapnel, Ray, Puff, Ring, Capsule) for texture-free particle rendering, each with deterministic shape generation via `Particle::shape_seed`. `Trail` adds a time-fading ribbon effect as a `Vec<TrailPoint>` history for smoke, laser, and motion-blur effects.

Additional emitter control methods have been added to `ParticleSystem`, enabling finer runtime manipulation of active emitter state through the Lua API. These updates extend the `ParticleConfig` parameter set with new shape and physics modifiers that game scripts can adjust mid-flight, including updated support for shrapnel emission patterns, ring-thickness control, and ray-aspect particle rendering.

**Scope boundary**: Feature Systems tier. Depends on `render`, `math`, `runtime`. Lua bridge in `src/lua_api/particle_api.rs`.

## Files

- `config.rs`: Defines ParticleConfig and the enums that control emission shape, area distribution, insert mode, emitter state, and relative motion.
- `emission.rs`: Computes spawn offsets from the configured area-distribution and emission-shape rules.
- `emitter.rs`: Defines ParticleSystem, including spawning, simulation updates, emitter lifecycle, and batched render-command generation.
- `emitter_tests.rs`: Unit tests for ParticleSystem (split from emitter.rs for file-size management).
- `math.rs`: Defines interpolation and random-sampling helpers used during particle updates.
- `mod.rs`: Declares the particle submodules and re-exports the public emitter, config, particle, trail, and helper types.
- `particle.rs`: Defines Particle, the live per-particle state record used during simulation.
- `render.rs`: Provides standard `generate_render_commands` wrappers for particle systems and trails, plus `expand_particle_commands` which splits textured particles into individual `DrawQuad`/`DrawImageEx` commands.
- `shapes.rs`: Defines ParticleShape, the geometric primitive enum for untextured particle rendering.
- `trail.rs`: Defines Trail and TrailPoint for fading ribbon effects built from timestamped points.

## Types

- `AreaDistribution` (`enum`, `config.rs`): Enum controlling secondary spread across rectangular or elliptical areas.
- `InsertMode` (`enum`, `config.rs`): Insert mode controlling where new particles are placed in the particle list.
- `EmitterState` (`enum`, `config.rs`): Enum tracking whether an emitter is active, paused, or stopped.
- `EmissionShape` (`enum`, `config.rs`): Enum controlling where particles spawn relative to the emitter. Variants: `Point`, `Circle`, `Rectangle`, `Ring`, `Line`, `Cone`, `Star`, `Spiral`, `Custom { callback_id: u32 }`. Derives `serde::Serialize + Deserialize`.
- `RelativeMode` (`enum`, `config.rs`): Enum controlling whether particles remain in world space or move with the emitter.
- `Attractor` (`struct`, `config.rs`): Gravity well applied to live particles. Fields: `x: f32`, `y: f32`, `strength: f32`, `radius: f32`. Positive strength pulls; negative repels.
- `BounceBounds` (`struct`, `config.rs`): Axis-aligned bounding rectangle. Particles that cross a wall have their velocity component reversed and scaled by `restitution`. Fields: `x_min`, `x_max`, `y_min`, `y_max`, `restitution: f32`.
- `ParticleConfig` (`struct`, `config.rs`): Main emitter configuration object controlling spawn rate, lifetime, forces, interpolation curves, rendering shape, and batching limits. Fields added: `death_emitter: Option<Box<ParticleConfig>>`, `death_burst_count: u32`, `shrapnel_edges: u8`, `ray_aspect: f32`, `ring_thickness: f32`.
- `ParticleSystem` (`struct`, `emitter.rs`): Main emitter simulation that owns the live particle pool and advances it each frame. Fields added: `attractors: Vec<Attractor>`, `bounce_bounds: Option<BounceBounds>`, `sub_systems: Vec<ParticleSystem>`.
- `Particle` (`struct`, `particle.rs`): Per-particle runtime state including position, velocity, lifetime, rotation, and acceleration terms. Field added: `shape_seed: u32` — assigned at spawn for deterministic `Shrapnel` polygon generation.
- `ParticleShape` (`enum`, `shapes.rs`): Enum selecting the geometric primitive used for untextured particles. Variants: `Square`, `Circle`, `Triangle`, `Spark`, `Diamond`, `Shrapnel { edges: u8 }`, `Ray { aspect: f32 }`, `Puff`, `Ring { thickness: f32 }`, `Capsule`.
- `TrailPoint` (`struct`, `trail.rs`): Individual point stored inside a Trail.
- `Trail` (`struct`, `trail.rs`): Fading ribbon effect that stores and ages trail points over time.

## Functions

- `emission_offset` (`emission.rs`): Compute an emission offset `(dx, dy)` based on the config's area distribution.
- `emission_shape_offset` (`emission.rs`): Compute an emission offset `(dx, dy)` based on the emission shape.
- `ParticleSystem::new` (`emitter.rs`): Creates a new particle system with the given configuration positioned at `(0, 0)`.
- `ParticleSystem::update` (`emitter.rs`): Updates the particle system by `dt` seconds.
- `ParticleSystem::emit` (`emitter.rs`): Emits a burst of `count` particles immediately, respecting the max_particles cap.
- `ParticleSystem::count` (`emitter.rs`): Returns the number of live particles.
- `ParticleSystem::reset` (`emitter.rs`): Resets the system, killing all particles and zeroing the accumulator and emitter age.
- `ParticleSystem::start` (`emitter.rs`): Activates the emitter, beginning particle emission.
- `ParticleSystem::stop` (`emitter.rs`): Stops the emitter.
- `ParticleSystem::pause` (`emitter.rs`): Pauses the emitter.
- `ParticleSystem::resume` (`emitter.rs`): Resumes a paused emitter.
- `ParticleSystem::move_to` (`emitter.rs`): Moves the emitter to a new position, updating previous position tracking.
- `ParticleSystem::clone_config` (`emitter.rs`): Creates a new `ParticleSystem` with a clone of this system's config but no particles.
- `ParticleSystem::is_active` (`emitter.rs`): Returns `true` if the emitter is actively emitting particles.
- `ParticleSystem::is_paused` (`emitter.rs`): Returns `true` if the emitter is paused.
- `ParticleSystem::is_stopped` (`emitter.rs`): Returns `true` if the emitter is stopped.
- `ParticleSystem::is_empty` (`emitter.rs`): Returns `true` if there are no live particles.
- `ParticleSystem::is_full` (`emitter.rs`): Returns `true` if the particle count has reached `max_particles`.
- `ParticleSystem::build_render_commands` (`emitter.rs`): Generates `RenderCommand`s for rendering all live particles.
- `ParticleSystem::warm_up` (`emitter.rs`): Runs the particle system forward by `seconds` in fixed 0.05 s steps to pre-populate particles.
- `ParticleSystem::add_attractor` (`emitter.rs`): Adds a point attractor (or repeller) to this system.
- `ParticleSystem::clear_attractors` (`emitter.rs`): Removes all attractors from this system.
- `ParticleSystem::attractor_count` (`emitter.rs`): Returns the number of attractors currently attached to this system.
- `ParticleSystem::set_bounds` (`emitter.rs`): Sets axis-aligned bounce boundaries with a restitution coefficient.
- `ParticleSystem::clear_bounds` (`emitter.rs`): Removes the bounce boundaries from this system.
- `ParticleSystem::draw_to_image` (`emitter.rs`): Each particle is drawn with its color interpolated from age.
- `ParticleSystem::draw_explosion_to_image` (`emitter.rs`): Render an explosion burst: particles radiate from center with age-based red-to-yellow coloring.
- `ParticleSystem::draw_rain_to_image` (`emitter.rs`): Render particles styled as falling rain streaks.
- `ParticleSystem::draw_spark_trail_to_image` (`emitter.rs`): Render particles as hot orange sparks with short trails.
- `ParticleSystem::draw_over_image` (`emitter.rs`): Render a lifecycle strip showing the particle count at each step.
- `ParticleSystem::paint_onto` (`emitter.rs`): Paint live spark particles onto an existing mutable image.
- `ParticleSystem::draw_lifecycle_to_image` (`emitter.rs`): Renders a bar chart of particle lifecycle counts over time into an `ImageData` frame.
- `lerp` (`math.rs`): Linearly interpolate between `a` and `b` by factor `t`.
- `interpolate_sizes` (`math.rs`): Interpolate a multi-stop size array at normalised time `t` (0 = birth, 1 = death).
- `interpolate_colors` (`math.rs`): Interpolate a multi-stop color array at normalised time `t` (0 = birth, 1 = death).
- `interpolate_alphas` (`math.rs`): Interpolate a multi-stop alpha array at normalised time `t` (0 = birth, 1 = death).
- `rand_range` (`math.rs`): Sample a uniform random value in `[min, max]`.
- `rand_normal` (`math.rs`): Approximate a standard-normal random value using Box-Muller transform.
- `ParticleSystem::generate_render_commands` (`render.rs`): Generate render commands for all live particles at world origin.
- `Trail::generate_render_commands` (`render.rs`): Generate render commands for the trail ribbon.
- `Trail::new` (`trail.rs`): Creates a new trail with the given lifetime and starting width.
- `Trail::push_point` (`trail.rs`): Pushes a new point at the head of the trail.
- `Trail::update` (`trail.rs`): Advances point ages by `dt` seconds and removes expired points.
- `Trail::set_width` (`trail.rs`): Sets the ribbon width.
- `Trail::set_lifetime` (`trail.rs`): Sets the maximum point lifetime in seconds.
- `Trail::get_lifetime` (`trail.rs`): Returns the maximum point lifetime in seconds.
- `Trail::set_min_distance` (`trail.rs`): Sets the minimum distance a new point must be from the last one.
- `Trail::clear` (`trail.rs`): Removes all trail points.
- `Trail::get_point_count` (`trail.rs`): Returns the current number of trail points.
- `Trail::get_width` (`trail.rs`): Returns the ribbon width as `(start_width, end_width)`.
- `Trail::set_head_color` (`trail.rs`): Sets the color at the head (newest) end of the trail.
- `Trail::set_tail_color` (`trail.rs`): Sets the color at the tail (oldest) end of the trail.
- `Trail::build_render_commands` (`trail.rs`): Generates render commands to draw the trail as a tapered quad strip.
- `Trail::draw_to_image` (`trail.rs`): Render the trail ribbon to an image with color interpolation.

## Lua API Reference

- Binding path(s): `src/lua_api/particle_api.rs`
- Namespace: `lurek.particle`

### Module Functions
- `lurek.particle.newSystem`: Creates a new particle system and stores it in the engine pool.
- `lurek.particle.newTrail`: Creates a new trail ribbon effect.

### `ParticleSystem` Methods
- `ParticleSystem:update`: Advances the particle simulation by dt seconds.
- `ParticleSystem:emit`: Emits a burst of the given number of particles.
- `ParticleSystem:start`: Starts or restarts particle emission.
- `ParticleSystem:stop`: Stops particle emission immediately.
- `ParticleSystem:pause`: Pauses particle emission; existing particles continue to simulate.
- `ParticleSystem:resume`: Resumes a paused emitter.
- `ParticleSystem:reset`: Removes all particles and resets the emitter.
- `ParticleSystem:moveTo`: Moves the emitter to the given world position.
- `ParticleSystem:count`: Returns the number of living particles.
- `ParticleSystem:isActive`: Returns true if the emitter is currently emitting or has live particles.
- `ParticleSystem:isPaused`: Returns true if the emitter is paused.
- `ParticleSystem:isStopped`: Returns true if the emitter is stopped.
- `ParticleSystem:isEmpty`: Returns true if there are no live particles.
- `ParticleSystem:isFull`: Returns true if the system has reached max_particles.
- `ParticleSystem:release`: Removes the particle system from the engine, freeing its slot.
- `ParticleSystem:getCount`: Returns the number of living particles (alias for count).
- `ParticleSystem:type`: Returns the type name "ParticleSystem".
- `ParticleSystem:typeOf`: Returns true if this matches the given type name.
- `ParticleSystem:setPosition`: Sets the emitter world position.
- `ParticleSystem:getPosition`: Returns the emitter world position.
- `ParticleSystem:setEmissionRate`: Sets particles emitted per second.
- `ParticleSystem:getEmissionRate`: Returns particles emitted per second.
- `ParticleSystem:setParticleLifetime`: Sets min and max particle lifetime in seconds.
- `ParticleSystem:getParticleLifetime`: Returns min and max particle lifetime.
- `ParticleSystem:setEmitterLifetime`: Sets how long the emitter runs before auto-stopping. Negative = infinite.
- `ParticleSystem:getEmitterLifetime`: Returns the emitter lifetime.
- `ParticleSystem:setSpeed`: Sets min/max initial speed.
- `ParticleSystem:getSpeed`: Returns min/max initial speed.
- `ParticleSystem:setDirection`: Sets emission direction in radians.
- `ParticleSystem:getDirection`: Returns emission direction in radians.
- `ParticleSystem:setSpread`: Sets emission spread (half-angle cone) in radians.
- `ParticleSystem:getSpread`: Returns the half-angle spread in radians for the emission cone.
- `ParticleSystem:getLinearAcceleration`: Returns linear acceleration range.
- `ParticleSystem:getRadialAcceleration`: Returns radial acceleration range.
- `ParticleSystem:getTangentialAcceleration`: Returns tangential acceleration range.
- `ParticleSystem:setLinearDamping`: Sets linear damping range.
- `ParticleSystem:getLinearDamping`: Returns linear damping range.
- `ParticleSystem:setSizes`: Sets size keyframes (varargs: each number is one keyframe).
- `ParticleSystem:getSizes`: Returns size keyframes as a Lua table.
- `ParticleSystem:setSizeVariation`: Sets size variation (0–1).
- `ParticleSystem:getSizeVariation`: Returns the maximum random size variation applied to newly emitted particles.
- `ParticleSystem:setRotation`: Sets initial rotation range in radians.
- `ParticleSystem:getRotation`: Returns initial rotation range.
- `ParticleSystem:setSpin`: Sets angular velocity range.
- `ParticleSystem:getSpin`: Returns angular velocity range.
- `ParticleSystem:setSpinVariation`: Sets spin variation (0–1).
- `ParticleSystem:getSpinVariation`: Returns the maximum random angular velocity variation for new particles.
- `ParticleSystem:setRelativeRotation`: Sets whether particle rotation follows velocity direction.
- `ParticleSystem:hasRelativeRotation`: Returns whether relative rotation is enabled.
- `ParticleSystem:setColors`: Sets color keyframes. Each arg is a table {r, g, b, a}.
- `ParticleSystem:getColors`: Returns color keyframes as a table of {r,g,b,a} tables.
- `ParticleSystem:setOffset`: Sets the render origin offset.
- `ParticleSystem:getOffset`: Returns the render origin offset.
- `ParticleSystem:setInsertMode`: Sets the insert mode: "top", "bottom", or "random".
- `ParticleSystem:getInsertMode`: Returns the insert mode as a string.
- `ParticleSystem:setBufferSize`: Sets the maximum number of particles (resizes the pool).
- `ParticleSystem:getBufferSize`: Returns the maximum particle count.
- `ParticleSystem:setEmissionArea`: Sets emission area distribution and size.
- `ParticleSystem:getEmissionArea`: Returns emission area: dist-string, w, h.
- `ParticleSystem:setShape`: Sets the particle draw shape.
- `ParticleSystem:getShape`: Returns the particle draw shape as a string.
- `ParticleSystem:getGravity`: Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
- `ParticleSystem:setGravity`: Sets the gravity acceleration applied to all active particles each frame.
- `ParticleSystem:render`: Renders all live particles to the GPU command queue.
- `ParticleSystem:clone`: Creates a copy of this particle system (config only, no live particles).
- `ParticleSystem:drawToImage`: Renders all live particles to a CPU ImageData.
- `ParticleSystem:toImage`: Alias for `drawToImage`. Renders all live particles to a CPU ImageData.
- `ParticleSystem:warmUp`: Pre-simulates the particle system for `seconds` so it appears fully
- `ParticleSystem:clearAttractors`: Removes all attractors from this particle system.
- `ParticleSystem:getAttractorCount`: Returns the number of attractors currently registered on this system.
- `ParticleSystem:clearBounds`: Removes the bounding rectangle so particles can move freely.
- `ParticleSystem:addSubEmitter`: Attaches a sub-emitter that bursts when a particle dies.
- `ParticleSystem:setFlipbook`: Configures sprite-sheet flipbook animation by dividing the texture into a grid.
- `ParticleSystem:getFlipbook`: Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
- `ParticleSystem:addSubSystem`: Adds a persistent child emitter that updates and renders alongside this system. Returns a 1-based index.
- `ParticleSystem:subSystemCount`: Returns the number of direct child sub-systems.
- `ParticleSystem:setCustomEmissionShape`: Registers a Lua `function() -> (offset_x, offset_y)` callback invoked for each newly spawned particle when using the `Custom` emission shape.
- `ParticleSystem:setOnDeathBatch`: Registers a Lua `function(batch)` callback invoked after each `update()` with a table array of `{x, y, vx, vy}` entries for all particles that died that frame.
- `lurek.particle.fromTOML`: Loads a TOML-serialized `ParticleConfig` from a file path and returns a new `ParticleSystem`.

### `Trail` Methods
- `Trail:pushPoint`: Appends a new point to the trail head.
- `Trail:update`: Ages trail points and removes expired ones.
- `Trail:setWidth`: Sets the start and end width of the trail ribbon.
- `Trail:getWidth`: Returns the start and end width.
- `Trail:setLifetime`: Sets how long each trail point persists in seconds.
- `Trail:getLifetime`: Returns the trail point lifetime in seconds.
- `Trail:setMinDistance`: Sets the minimum distance between trail points.
- `Trail:getPointCount`: Returns the number of active trail points.
- `Trail:clear`: Removes all trail points.
- `Trail:drawToImage`: Renders the trail ribbon to a CPU ImageData.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/particle/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
