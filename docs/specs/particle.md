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

- `ParticleConfig::from_toml_str` (`config.rs`): Parses a TOML string into a `ParticleConfig`.
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
- `ParticleSystem::add_sub_system` (`emitter.rs`): Adds a child emitter that updates and renders alongside this system.
- `ParticleSystem::sub_system_count` (`emitter.rs`): Returns the number of direct child sub-systems.
- `ParticleSystem::drain_pending_deaths` (`emitter.rs`): Takes and returns all entries from `pending_deaths`, leaving the vec empty.
- `ParticleSystem::drain_custom_offsets` (`emitter.rs`): Takes and returns all entries from `pending_custom_offsets`, leaving the vec empty.
- `interpolate_sizes` (`math.rs`): Interpolate a multi-stop size array at normalised time `t` (0 = birth, 1 = death).
- `interpolate_colors` (`math.rs`): Interpolate a multi-stop color array at normalised time `t` (0 = birth, 1 = death).
- `interpolate_alphas` (`math.rs`): Interpolate a multi-stop alpha array at normalised time `t` (0 = birth, 1 = death).
- `rand_range` (`math.rs`): Sample a uniform random value in `[min, max]`.
- `rand_normal` (`math.rs`): Approximate a standard-normal random value using Box-Muller transform.
- `ParticleSystem::generate_render_commands` (`render.rs`): Generate render commands for all live particles at world origin.
- `Trail::generate_render_commands` (`render.rs`): Generate render commands for the trail ribbon.
- `expand_particle_commands` (`render.rs`): Expand particle render commands for textured particles.
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
- `lurek.particle.newSystem`: Creates a new particle system and stores it in the engine pool.
- `lurek.particle.newTrail`: Creates a new trail ribbon effect.
- `lurek.particle.fromTOML`: Creates a new particle system from a TOML config file.

### `LParticleSystem` Methods
- `LParticleSystem:update`: Advances the particle simulation by dt seconds.
- `LParticleSystem:emit`: Emits a burst of the given number of particles.
- `LParticleSystem:start`: Starts or restarts particle emission.
- `LParticleSystem:stop`: Stops particle emission immediately.
- `LParticleSystem:pause`: Pauses particle emission; existing particles continue to simulate.
- `LParticleSystem:resume`: Resumes a paused emitter.
- `LParticleSystem:reset`: Removes all particles and resets the emitter.
- `LParticleSystem:moveTo`: Moves the emitter to the given world position.
- `LParticleSystem:count`: Returns the number of living particles.
- `LParticleSystem:isActive`: Returns true if the emitter is currently emitting or has live particles.
- `LParticleSystem:isPaused`: Returns true if the emitter is paused.
- `LParticleSystem:isStopped`: Returns true if the emitter is stopped.
- `LParticleSystem:isEmpty`: Returns true if there are no live particles.
- `LParticleSystem:isFull`: Returns true if the system has reached max_particles.
- `LParticleSystem:release`: Removes the particle system from the engine, freeing its slot.
- `LParticleSystem:getCount`: Returns the number of living particles (alias for count).
- `LParticleSystem:type`: Returns the type name "ParticleSystem".
- `LParticleSystem:typeOf`: Returns true if this matches the given type name.
- `LParticleSystem:setPosition`: Sets the emitter world position.
- `LParticleSystem:getPosition`: Returns the emitter world position.
- `LParticleSystem:setEmissionRate`: Sets particles emitted per second.
- `LParticleSystem:getEmissionRate`: Returns particles emitted per second.
- `LParticleSystem:setParticleLifetime`: Sets min and max particle lifetime in seconds.
- `LParticleSystem:getParticleLifetime`: Returns min and max particle lifetime.
- `LParticleSystem:setEmitterLifetime`: Sets how long the emitter runs before auto-stopping. Negative = infinite.
- `LParticleSystem:getEmitterLifetime`: Returns the emitter lifetime.
- `LParticleSystem:setSpeed`: Sets min/max initial speed.
- `LParticleSystem:getSpeed`: Returns min/max initial speed.
- `LParticleSystem:setDirection`: Sets emission direction in radians.
- `LParticleSystem:getDirection`: Returns emission direction in radians.
- `LParticleSystem:setSpread`: Sets emission spread (half-angle cone) in radians.
- `LParticleSystem:getSpread`: Returns the half-angle spread in radians for the emission cone.
- `LParticleSystem:setLinearAcceleration`: Sets linear acceleration range.
- `LParticleSystem:getLinearAcceleration`: Returns linear acceleration range.
- `LParticleSystem:setRadialAcceleration`: Sets radial acceleration range.
- `LParticleSystem:getRadialAcceleration`: Returns radial acceleration range.
- `LParticleSystem:setTangentialAcceleration`: Sets tangential acceleration range.
- `LParticleSystem:getTangentialAcceleration`: Returns tangential acceleration range.
- `LParticleSystem:setLinearDamping`: Sets linear damping range.
- `LParticleSystem:getLinearDamping`: Returns linear damping range.
- `LParticleSystem:setSizes`: Sets size keyframes (varargs: each number is one keyframe).
- `LParticleSystem:getSizes`: Returns size keyframes as a Lua table.
- `LParticleSystem:setSizeVariation`: Sets size variation (0-1).
- `LParticleSystem:getSizeVariation`: Returns the maximum random size variation applied to newly emitted particles.
- `LParticleSystem:setRotation`: Sets initial rotation range in radians.
- `LParticleSystem:getRotation`: Returns initial rotation range.
- `LParticleSystem:setSpin`: Sets angular velocity range.
- `LParticleSystem:getSpin`: Returns angular velocity range.
- `LParticleSystem:setSpinVariation`: Sets spin variation (0-1).
- `LParticleSystem:getSpinVariation`: Returns the maximum random angular velocity variation for new particles.
- `LParticleSystem:setRelativeRotation`: Sets whether particle rotation follows velocity direction.
- `LParticleSystem:hasRelativeRotation`: Returns whether relative rotation is enabled.
- `LParticleSystem:setColors`: Sets color keyframes. Each arg is a table {r, g, b, a}.
- `LParticleSystem:getColors`: Returns color keyframes as a table of {r,g,b,a} tables.
- `LParticleSystem:setOffset`: Sets the render origin offset.
- `LParticleSystem:getOffset`: Returns the render origin offset.
- `LParticleSystem:setInsertMode`: Sets the insert mode: "top", "bottom", or "random".
- `LParticleSystem:getInsertMode`: Returns the insert mode as a string.
- `LParticleSystem:setBufferSize`: Sets the maximum number of particles (resizes the pool).
- `LParticleSystem:getBufferSize`: Returns the maximum particle count.
- `LParticleSystem:setEmissionArea`: Sets emission area distribution and size.
- `LParticleSystem:getEmissionArea`: Returns emission area: dist-string, w, h.
- `LParticleSystem:setShape`: Sets the particle draw shape.
- `LParticleSystem:getShape`: Returns the particle draw shape as a string.
- `LParticleSystem:getGravity`: Returns the gravity acceleration applied to particles as two numbers `gx, gy`.
- `LParticleSystem:setGravity`: Sets the gravity acceleration applied to all active particles each frame.
- `LParticleSystem:render`: Renders all live particles to the GPU command queue.
- `LParticleSystem:clone`: Creates a copy of this particle system (config only, no live particles).
- `LParticleSystem:drawToImage`: Renders all live particles to a CPU ImageData.
- `LParticleSystem:toImage`: Alias for `drawToImage`. Renders all live particles to a CPU ImageData.
- `LParticleSystem:warmUp`: Pre-simulates the particle system for `seconds` so it appears fully
- `LParticleSystem:addAttractor`: Adds a gravity well that pulls (positive strength) or repels
- `LParticleSystem:clearAttractors`: Removes all attractors from this particle system.
- `LParticleSystem:getAttractorCount`: Returns the number of attractors currently registered on this system.
- `LParticleSystem:setBounds`: Constrains all particles to an axis-aligned bounding rectangle.
- `LParticleSystem:clearBounds`: Removes the bounding rectangle so particles can move freely.
- `LParticleSystem:addSubEmitter`: Attaches a sub-emitter that bursts when a particle dies.
- `LParticleSystem:setFlipbook`: Configures sprite-sheet flipbook animation by dividing the texture into a grid.
- `LParticleSystem:getFlipbook`: Returns the current flipbook configuration as `(cols, rows, fps)`, or `nil` if not set.
- `LParticleSystem:addSubSystem`: Adds a child emitter that updates and renders with this system.
- `LParticleSystem:subSystemCount`: Returns the number of direct child sub-systems attached to this emitter.
- `LParticleSystem:setCustomEmissionShape`: Sets a Lua function that returns (offset_x, offset_y) for each newly spawned
- `LParticleSystem:setOnDeathBatch`: Sets a Lua function called after each update() with all particles that died

### `LTrail` Methods
- `LTrail:pushPoint`: Appends a new point to the trail head.
- `LTrail:update`: Ages trail points and removes expired ones.
- `LTrail:setWidth`: Sets the start and end width of the trail ribbon.
- `LTrail:getWidth`: Returns the start and end width.
- `LTrail:setLifetime`: Sets how long each trail point persists in seconds.
- `LTrail:getLifetime`: Returns the trail point lifetime in seconds.
- `LTrail:setMinDistance`: Sets the minimum distance between trail points.
- `LTrail:setHeadColor`: Sets the colour at the newest end of the trail.
- `LTrail:setTailColor`: Sets the colour at the oldest end of the trail.
- `LTrail:getPointCount`: Returns the number of active trail points.
- `LTrail:clear`: Removes all trail points.
- `LTrail:drawToImage`: Renders the trail ribbon to a CPU ImageData.
- `LTrail:type`: Returns the type name of this object.
- `LTrail:typeOf`: Returns true if this object is of the given type.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/particle/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

## 2026-05 Backlog Closure

- Added built-in preset package in `src/particle/presets.rs`:
	- `fire()`, `smoke()`, `rain()`, `snow()`, `sparks()`.
- Added optional particle-vs-physics collision helper in `src/particle/physics_collision.rs`.
- Added Lua API methods on `LParticleSystem`:
	- `setCollidesWithPhysics(world, probe_radius?, restitution?)`
	- `clearCollidesWithPhysics()`
	- `hasCollidesWithPhysics()`
- Added module function:
	- `lurek.particle.newPreset(name)`
- Added tests:
	- Rust: border-rectangle statistical test and fuzz-like update stability.
	- Lua: preset creation and collision toggle API coverage.
