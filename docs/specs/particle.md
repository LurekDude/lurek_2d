# particle

## General Info

- Module group: `Feature Systems`
- Source path: `src/particle/`
- Lua API path(s): `src/lua_api/particle_api.rs`
- Primary Lua namespace: `lurek.particle`
- Rust test path(s): tests/rust/unit/particle_tests.rs
- Lua test path(s): tests/lua/unit/test_particle.lua, tests/lua/stress/test_particle_stress.lua, tests/lua/integration/test_particle_timer.lua, tests/lua/evidence/test_evidence_particle.lua

## Summary

The `particle` module implements emitter-based 2D particle systems for the Feature Systems tier. It provides a CPU-simulated particle engine with bounded memory (pool-based recycling), data-driven emitter configuration, and direct integration with the render pipeline via `RenderCommand` batches.

**Core simulation.** `ParticleSystem` owns a bounded pool of `Particle` instances (capacity set by `ParticleConfig::max_particles`). Each call to `update(dt)` advances all live particles using Euler integration: position += velocity × dt, velocity modified by drag, radial/tangential acceleration, orbital rotation, attractor gravity wells, turbulence, and optional axis-aligned bounce bounds. Particles are recycled when their lifetime expires, keeping allocation constant after the pool fills. A frame-accurate burst system supports both continuous rate-based emission and one-shot `burst(n)` calls.

**Configuration (`ParticleConfig`).** Approximately 50 fields control every aspect of emission and simulation:
- *Emission shape*: `EmissionShape` enum — Point, Circle, Rectangle, Ring (with `ring_thickness`), Line, Cone, Star, Spiral, Custom.
- *Area distribution*: `AreaDistribution` — None, Uniform, Normal, Ellipse, BorderEllipse, BorderRectangle.
- *Motion*: min/max speed and angle spread, radial acceleration, tangential acceleration, linear damping, orbital rotation rate, turbulence amplitude.
- *Rotation*: initial angle range, angular velocity range.
- *Lifetime*: min/max lifetime in seconds.
- *Visual interpolation*: multi-stop gradient curves for size, color (RGBA), and alpha over normalised lifetime [0..1].
- *Draw order*: `InsertMode` — Top, Bottom, Random.
- *World space*: `RelativeMode` — World (particles detach from emitter) or Local (particles follow emitter).
- *Death emitters*: `death_emitter: Option<Box<ParticleConfig>>` + `death_burst_count` — trigger a child burst at each particle's death position, enabling cascading effects.

**Forces.** `Attractor` structs (gravity wells with position, strength, radius) and an optional `BounceBounds` (axis-aligned rectangle with per-wall restitution) are stored on `ParticleSystem` and applied every tick, beyond the standard config-driven acceleration.

**Rendering.** `ParticleShape` is a ten-variant geometric primitive enum for texture-free rendering: Square, Circle, Triangle, Spark, Diamond, Shrapnel (n-edge polygon with deterministic per-particle seed), Ray (aspect-ratio-controlled), Puff, Ring, Capsule. For texture-based rendering, `ParticleSystem` holds an optional `TextureKey`; `expand_particle_commands` splits emitter batches into individual `DrawQuad`/`DrawImageEx` commands. `Trail` adds a fading ribbon effect via a timestamped `Vec<TrailPoint>` history — useful for smoke trails, laser beams, and motion blur.

**Sub-systems.** `ParticleSystem::sub_systems` holds child `ParticleSystem` instances that follow the parent's position and are ticked in the same update cycle, enabling compound effect trees.

**Lua surface.** `lurek.particle.newSystem(config_table)` creates an emitter from a Lua table or a TOML config string. The resulting `ParticleSystem` userdata exposes: `emit(n)`, `update(dt)`, `setPosition(x, y)`, `getPosition()`, `setRate(n)`, `getParticleCount()`, `setRelativeMode(mode)`, `addAttractor(x, y, strength, radius)`, `clearAttractors()`, `setBounceBounds(xmin, ymin, xmax, ymax, restitution)`, `pause()`, `resume()`, `stop()`, `reset()`, `addSubSystem(config_table)`, `getRenderCommands()`, and property setters for most `ParticleConfig` fields including `setMaxParticles`, `setLifetime`, `setSpeed`, `setEmissionShape`, `setTextureKey`.

**Scope boundary.** Feature Systems tier. Depends on `render`, `math`, `runtime`. Lua bridge in `src/lua_api/particle_api.rs`.

## Files

- `config.rs`: Defines ParticleConfig and the enums that control emission shape, area distribution, insert mode, emitter state, and relative motion.
- `emission.rs`: Computes spawn offsets from the configured area-distribution and emission-shape rules.
- `emitter.rs`: Defines ParticleSystem, including spawning, simulation updates, emitter lifecycle, and batched render-command generation.
- `math.rs`: Defines interpolation and random-sampling helpers used during particle updates.
- `mod.rs`: Declares the particle submodules and re-exports the public emitter, config, particle, trail, and helper types.
- `particle.rs`: Defines Particle, the live per-particle state record used during simulation.
- `physics_collision.rs`: - Bounce particles off rapier colliders using AABB overlap probes.
- `presets.rs`: - Ready-made `ParticleConfig` constructors for common visual effects (fire, smoke, rain, snow, sparks).
- `render.rs`: Provides standard `generate_render_commands` wrappers for particle systems and trails, plus `expand_particle_commands` which splits textured particles into individual `DrawQuad`/`DrawImageEx` commands.
- `shapes.rs`: Defines ParticleShape, the geometric primitive enum for untextured particle rendering.
- `trail.rs`: Defines Trail and TrailPoint for fading ribbon effects built from timestamped points.
- `visualization.rs`: Particle system visualization / diagnostic renderers.

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

- `ParticleConfig::from_toml_str` (`config.rs`): Parse a `ParticleConfig` from a TOML string; returns the error string on failure.
- `emission_offset` (`emission.rs`): Compute an emission offset `(dx, dy)` based on the config's area distribution.
- `emission_shape_offset` (`emission.rs`): Compute an emission offset `(dx, dy)` based on the emission shape.
- `ParticleSystem::new` (`emitter.rs`): Create a new system from `config`; allocates the particle pool upfront.
- `ParticleSystem::update` (`emitter.rs`): Advance all particles by `dt` seconds: integrate physics, retire dead particles, and spawn new ones.
- `ParticleSystem::emit` (`emitter.rs`): Burst-spawn up to `count` particles immediately, capped by `max_particles`.
- `ParticleSystem::count` (`emitter.rs`): Return the number of live particles in the pool.
- `ParticleSystem::reset` (`emitter.rs`): Clear all particles and reset the accumulator and age.
- `ParticleSystem::start` (`emitter.rs`): Transition to `Active` and reset `emitter_age` to zero.
- `ParticleSystem::stop` (`emitter.rs`): Transition to `Stopped`; existing particles continue to live but no new ones are emitted.
- `ParticleSystem::pause` (`emitter.rs`): Transition to `Paused`; update loop stops advancing but particles freeze in place.
- `ParticleSystem::resume` (`emitter.rs`): Resume from `Paused` or `Stopped`; transitions to `Active`.
- `ParticleSystem::move_to` (`emitter.rs`): Update the emitter's world-space position, recording the previous position for motion blur.
- `ParticleSystem::clone_config` (`emitter.rs`): Return a new `ParticleSystem` with the same config but no live particles.
- `ParticleSystem::is_active` (`emitter.rs`): Return `true` when the emitter state is `Active`.
- `ParticleSystem::is_paused` (`emitter.rs`): Return `true` when the emitter state is `Paused`.
- `ParticleSystem::is_stopped` (`emitter.rs`): Return `true` when the emitter state is `Stopped`.
- `ParticleSystem::is_empty` (`emitter.rs`): Return `true` when the particle pool is empty.
- `ParticleSystem::is_full` (`emitter.rs`): Return `true` when the pool has reached `max_particles`.
- `ParticleSystem::build_render_commands` (`emitter.rs`): Build `RenderCommand` values for all live particles at world offset `(ox, oy)`, including sub-systems.
- `ParticleSystem::warm_up` (`emitter.rs`): Run the update loop for up to `seconds` in 50 ms steps to pre-populate the particle pool.
- `ParticleSystem::add_attractor` (`emitter.rs`): Add a point attractor at `(x, y)` with given `strength` and influence `radius`.
- `ParticleSystem::clear_attractors` (`emitter.rs`): Remove all attractors.
- `ParticleSystem::attractor_count` (`emitter.rs`): Return the number of active attractors.
- `ParticleSystem::set_bounds` (`emitter.rs`): Set the axis-aligned bounce boundary; particles reflect on crossing any edge.
- `ParticleSystem::clear_bounds` (`emitter.rs`): Remove the bounce boundary.
- `ParticleSystem::add_sub_system` (`emitter.rs`): Append a child sub-system; returns its index in `sub_systems`.
- `ParticleSystem::sub_system_count` (`emitter.rs`): Return the number of active sub-systems.
- `ParticleSystem::drain_pending_deaths` (`emitter.rs`): Drain and return all `(world_x, world_y, vx, vy)` death events accumulated since the last call.
- `ParticleSystem::drain_custom_offsets` (`emitter.rs`): Drain and return particle pool indices that need a custom spawn-offset callback applied.
- `interpolate_sizes` (`math.rs`): Interpolate a multi-stop size array at normalised time `t` (0 = birth, 1 = death).
- `interpolate_colors` (`math.rs`): Interpolate a multi-stop color array at normalised time `t` (0 = birth, 1 = death).
- `interpolate_alphas` (`math.rs`): Interpolate a multi-stop alpha array at normalised time `t` (0 = birth, 1 = death).
- `rand_range` (`math.rs`): Sample a uniform random value in `[min, max]`.
- `rand_normal` (`math.rs`): Approximate a standard-normal random value using Box-Muller transform.
- `collide_with_world` (`physics_collision.rs`): Reflect all particles in `system` that overlap a rapier collider in `world`; uses AABB probe of `probe_radius` and `restitution` coefficient.
- `fire` (`presets.rs`): Return a `ParticleConfig` producing an upward fire effect with turbulence and RGB fade.
- `smoke` (`presets.rs`): Return a `ParticleConfig` producing rising smoke with growing size and fading alpha.
- `rain` (`presets.rs`): Return a `ParticleConfig` producing fast downward rain streaks.
- `snow` (`presets.rs`): Return a `ParticleConfig` producing slow-drifting white snowflakes with turbulence.
- `sparks` (`presets.rs`): Return a `ParticleConfig` for a burst-only spark explosion; set `emission_rate > 0` or call `emit` manually.
- `ParticleSystem::generate_render_commands` (`render.rs`): Generate render commands for this system at world offset `(0, 0)`.
- `Trail::generate_render_commands` (`render.rs`): Generate `RenderCommand` values for the trail ribbon.
- `expand_particle_commands` (`render.rs`): Expand particle render commands for textured particles.
- `Trail::new` (`trail.rs`): Create a trail with `lifetime` seconds per point and `start_width` pixels at the head.
- `Trail::push_point` (`trail.rs`): Append a point at `(x, y)` if it is at least `min_distance` from the current head.
- `Trail::update` (`trail.rs`): Advance all point ages by `dt` seconds and retire points that exceed `lifetime`.
- `Trail::set_width` (`trail.rs`): Set ribbon width; `start` is the head width and optional `end` sets the tail width.
- `Trail::set_lifetime` (`trail.rs`): Set the maximum point lifetime in seconds.
- `Trail::get_lifetime` (`trail.rs`): Return the current maximum point lifetime in seconds.
- `Trail::set_min_distance` (`trail.rs`): Set the minimum distance between consecutive trail points.
- `Trail::clear` (`trail.rs`): Remove all points.
- `Trail::get_point_count` (`trail.rs`): Return the current number of live trail points.
- `Trail::get_width` (`trail.rs`): Return the current `(start_width, end_width)` pair.
- `Trail::set_head_color` (`trail.rs`): Set the RGBA colour at the head of the trail.
- `Trail::set_tail_color` (`trail.rs`): Set the RGBA colour at the tail of the trail.
- `Trail::build_render_commands` (`trail.rs`): Build a list of `SetColor` + `Triangle` commands forming the ribbon; returns empty when fewer than 2 points.
- `Trail::draw_to_image` (`trail.rs`): Render the trail to an `ImageData` of `width` x `height`; returns a dark-filled image when fewer than 2 points.
- `draw_to_image` (`visualization.rs`): Render all live particles to an `ImageData`.
- `draw_explosion_to_image` (`visualization.rs`): Render an explosion burst: particles radiate from center with age-based red-to-yellow coloring.
- `draw_rain_to_image` (`visualization.rs`): Render particles styled as falling rain streaks.
- `draw_spark_trail_to_image` (`visualization.rs`): Render particles as hot orange sparks with short trails.
- `draw_over_image` (`visualization.rs`): Render particles over a provided background image.
- `paint_onto` (`visualization.rs`): Paint live spark particles onto an existing mutable image.
- `draw_lifecycle_to_image` (`visualization.rs`): Renders a bar chart of particle lifecycle counts over time into an `ImageData` frame.

## Lua API Reference

- Binding path(s): `src/lua_api/particle_api.rs`
- Namespace: `lurek.particle`

### Module Functions
- `lurek.particle.newSystem`: Creates a particle system from an optional config table.
- `lurek.particle.newTrail`: Creates a trail effect.
- `lurek.particle.fromTOML`: Creates a particle system from a TOML config file.
- `lurek.particle.newPreset`: Creates a particle system from a named preset.

### `LParticleSystem` Methods
- `LParticleSystem:update`: Updates the particle system, applies optional physics collision, and invokes pending callbacks.
- `LParticleSystem:emit`: Emits particles immediately.
- `LParticleSystem:start`: Starts particle emission.
- `LParticleSystem:stop`: Stops particle emission.
- `LParticleSystem:pause`: Pauses particle emission and updates.
- `LParticleSystem:resume`: Resumes a paused particle system.
- `LParticleSystem:reset`: Resets particles and emitter state.
- `LParticleSystem:moveTo`: Moves the particle emitter.
- `LParticleSystem:count`: Returns the current particle count.
- `LParticleSystem:isActive`: Returns whether the particle system is active.
- `LParticleSystem:isPaused`: Returns whether the particle system is paused.
- `LParticleSystem:isStopped`: Returns whether the particle system is stopped or missing.
- `LParticleSystem:isEmpty`: Returns whether the particle system has no particles or is missing.
- `LParticleSystem:isFull`: Returns whether the particle system has reached capacity.
- `LParticleSystem:release`: Releases the particle system from shared storage.
- `LParticleSystem:getCount`: Returns particle count and errors if the handle was released.
- `LParticleSystem:type`: Returns the Lua-visible type name for this particle system handle.
- `LParticleSystem:typeOf`: Returns whether this particle system handle matches a supported type name.
- `LParticleSystem:setPosition`: Sets emitter position.
- `LParticleSystem:getPosition`: Returns emitter position.
- `LParticleSystem:setEmissionRate`: Sets emission rate.
- `LParticleSystem:getEmissionRate`: Returns emission rate.
- `LParticleSystem:setParticleLifetime`: Sets particle lifetime range.
- `LParticleSystem:getParticleLifetime`: Returns particle lifetime range.
- `LParticleSystem:setEmitterLifetime`: Sets emitter lifetime.
- `LParticleSystem:getEmitterLifetime`: Returns emitter lifetime.
- `LParticleSystem:setSpeed`: Sets particle speed range.
- `LParticleSystem:getSpeed`: Returns particle speed range.
- `LParticleSystem:setDirection`: Sets emission direction.
- `LParticleSystem:getDirection`: Returns emission direction.
- `LParticleSystem:setSpread`: Sets emission spread.
- `LParticleSystem:getSpread`: Returns emission spread.
- `LParticleSystem:setLinearAcceleration`: Sets linear acceleration range.
- `LParticleSystem:getLinearAcceleration`: Returns linear acceleration range.
- `LParticleSystem:setRadialAcceleration`: Sets radial acceleration range.
- `LParticleSystem:getRadialAcceleration`: Returns radial acceleration range.
- `LParticleSystem:setTangentialAcceleration`: Sets tangential acceleration range.
- `LParticleSystem:getTangentialAcceleration`: Returns tangential acceleration range.
- `LParticleSystem:setLinearDamping`: Sets linear damping range.
- `LParticleSystem:getLinearDamping`: Returns linear damping range.
- `LParticleSystem:setSizes`: Sets particle size keyframes from numeric arguments.
- `LParticleSystem:getSizes`: Returns particle size keyframes.
- `LParticleSystem:setSizeVariation`: Sets size variation.
- `LParticleSystem:getSizeVariation`: Returns size variation.
- `LParticleSystem:setRotation`: Sets particle rotation range.
- `LParticleSystem:getRotation`: Returns particle rotation range.
- `LParticleSystem:setSpin`: Sets particle spin range.
- `LParticleSystem:getSpin`: Returns particle spin range.
- `LParticleSystem:setSpinVariation`: Sets spin variation.
- `LParticleSystem:getSpinVariation`: Returns spin variation.
- `LParticleSystem:setRelativeRotation`: Sets whether particle rotation is relative to movement.
- `LParticleSystem:hasRelativeRotation`: Returns whether relative rotation is enabled.
- `LParticleSystem:setColors`: Sets particle color keyframes from RGBA tables.
- `LParticleSystem:getColors`: Returns particle color keyframes.
- `LParticleSystem:setOffset`: Sets particle spawn offset.
- `LParticleSystem:getOffset`: Returns particle spawn offset.
- `LParticleSystem:setInsertMode`: Sets particle insert mode.
- `LParticleSystem:getInsertMode`: Returns particle insert mode.
- `LParticleSystem:setBufferSize`: Sets maximum particle buffer size.
- `LParticleSystem:getBufferSize`: Returns maximum particle buffer size.
- `LParticleSystem:setEmissionArea`: Sets emission area distribution and size.
- `LParticleSystem:getEmissionArea`: Returns emission area distribution and size.
- `LParticleSystem:setShape`: Sets particle shape.
- `LParticleSystem:getShape`: Returns particle shape.
- `LParticleSystem:getGravity`: Returns particle gravity.
- `LParticleSystem:setGravity`: Sets particle gravity.
- `LParticleSystem:render`: Enqueues particle render commands with an optional offset.
- `LParticleSystem:clone`: Clones this particle system configuration into a new system handle.
- `LParticleSystem:drawToImage`: Draws particles to image data.
- `LParticleSystem:toImage`: Draws particles to image data.
- `LParticleSystem:warmUp`: Advances the system by a warm-up duration.
- `LParticleSystem:addAttractor`: Adds an attractor to the particle system.
- `LParticleSystem:clearAttractors`: Clears all attractors.
- `LParticleSystem:getAttractorCount`: Returns attractor count.
- `LParticleSystem:setBounds`: Sets collision bounds for particles.
- `LParticleSystem:clearBounds`: Clears collision bounds.
- `LParticleSystem:setCollidesWithPhysics`: Enables particle collision against a physics world.
- `LParticleSystem:clearCollidesWithPhysics`: Disables particle collision against a physics world.
- `LParticleSystem:hasCollidesWithPhysics`: Returns whether particle physics collision is enabled.
- `LParticleSystem:addSubEmitter`: Configures a death sub-emitter from a config table.
- `LParticleSystem:setFlipbook`: Sets flipbook grid and frame rate.
- `LParticleSystem:getFlipbook`: Returns flipbook grid and frame rate when configured.
- `LParticleSystem:addSubSystem`: Adds a particle sub-system from a config table.
- `LParticleSystem:subSystemCount`: Returns particle sub-system count.
- `LParticleSystem:setCustomEmissionShape`: Sets a Lua callback for custom emission positions.
- `LParticleSystem:setOnDeathBatch`: Sets a Lua callback invoked with batched particle death records.

### `LTrail` Methods
- `LTrail:pushPoint`: Adds a point to the trail.
- `LTrail:update`: Updates trail point lifetimes.
- `LTrail:setWidth`: Sets trail start and optional end width.
- `LTrail:getWidth`: Returns trail width settings.
- `LTrail:setLifetime`: Sets trail point lifetime.
- `LTrail:getLifetime`: Returns trail point lifetime.
- `LTrail:setMinDistance`: Sets minimum distance between trail points.
- `LTrail:setHeadColor`: Sets trail head color.
- `LTrail:setTailColor`: Sets trail tail color.
- `LTrail:getPointCount`: Returns trail point count.
- `LTrail:clear`: Clears all trail points.
- `LTrail:drawToImage`: Draws the trail to image data.
- `LTrail:type`: Returns the Lua-visible type name for this trail handle.
- `LTrail:typeOf`: Returns whether this trail handle matches a supported type name.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `physics`: Imports or references `src/physics/`. Cross-group dependency from `Feature Systems` into `Platform Services`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/particle/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
