# particle - Agent Reference

## Module Info

- Module: particle
- Group: Feature Systems
- Spec: docs/specs/particle.md
- Lua API: src/lua_api/particle_api.rs
- Rust tests: tests/rust/unit/particle_tests.rs
- Lua tests: tests/lua/unit/test_particle.lua, tests/lua/stress/test_particle_stress.lua, tests/lua/integration/test_particle_timer.lua, tests/lua/evidence/test_evidence_particle.lua

## Module Purpose

The particle module owns emitter-driven 2D particles and trail ribbons. It defines emitter configuration, particle spawning rules, lifetime interpolation, motion updates, trail point aging, and the render-command payloads that describe how those effects should be drawn.

This module exists so transient visual effects can be expressed as reusable CPU simulations instead of one-off draw code. It decides how particles spawn, move, age, and fade, but it does not own gameplay triggers, scene membership, or GPU execution. The renderer consumes the batched particle and trail command data after this module has already produced the effect state.

## Files

- mod.rs: Declares the particle submodules and re-exports the public emitter, config, particle, trail, and helper types.
- config.rs: Defines ParticleConfig and the enums that control emission shape, area distribution, insert mode, emitter state, and relative motion.
- emission.rs: Computes spawn offsets from the configured area-distribution and emission-shape rules.
- emitter.rs: Defines ParticleSystem, including spawning, simulation updates, emitter lifecycle, and batched render-command generation.
- particle.rs: Defines Particle, the live per-particle state record used during simulation.
- math.rs: Defines interpolation and random-sampling helpers used during particle updates.
- shapes.rs: Defines ParticleShape, the geometric primitive enum for untextured particle rendering.
- trail.rs: Defines Trail and TrailPoint for fading ribbon effects built from timestamped points.
- render.rs: Provides standard generate_render_commands wrappers for particle systems and trails.

## Key Types

- ParticleConfig: Main emitter configuration object controlling spawn rate, lifetime, forces, interpolation curves, rendering shape, and batching limits.
- ParticleSystem: Main emitter simulation that owns the live particle pool and advances it each frame.
- Particle: Per-particle runtime state including position, velocity, lifetime, rotation, and acceleration terms.
- ParticleShape: Enum selecting the geometric primitive used for untextured particles.
- EmissionShape: Enum controlling where particles spawn relative to the emitter.
- AreaDistribution: Enum controlling secondary spread across rectangular or elliptical areas.
- EmitterState: Enum tracking whether an emitter is active, paused, or stopped.
- RelativeMode: Enum controlling whether particles remain in world space or move with the emitter.
- Trail: Fading ribbon effect that stores and ages trail points over time.
- TrailPoint: Individual point stored inside a Trail.
