# `particle` � Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 � Reusable Engine Extensions                  |
| **Status**     | Implemented � Full                                   |
| **Lua API**    | `lurek.particles`                                      |
| **Source**      | `src/particle/`                                      |
| **Rust Tests** | `tests/rust/unit/particle_tests.rs`                  |
| **Lua Tests**  | `tests/lua/unit/test_particle.lua`                   |
| **Architecture** | �                                                  |

## Purpose

The particle module implements a CPU-side emitter-based 2D particle system with trail-ribbon rendering. A `ParticleSystem` spawns short-lived `Particle` entities each frame according to a ~50-field `ParticleConfig`, advances their position and velocity through gravity, radial/tangential acceleration, linear damping, quadratic drag, orbital rotation, and turbulence, then culls expired particles � keeping allocation bounded by `ParticleConfig::max_particles`. The surviving particle state is batched into a single `DrawCommand::DrawParticleSystem` for the GPU renderer to draw as textured quads or geometric shape primitives (Square, Circle, Triangle, Spark, Diamond) in one instanced draw call.

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs`      | Module entry point, re-exports all public types, tier and sub-file table in module-level docs |
| `config.rs`   | `ParticleConfig` (~50 fields) and enums: `AreaDistribution`, `InsertMode`, `EmitterState`, `EmissionShape`, `RelativeMode` |
| `shapes.rs`   | `ParticleShape` enum � five geometric render primitives (Square, Circle, Triangle, Spark, Diamond) |
| `particle.rs` | `Particle` struct � per-particle live state (position, velocity, lifetime, rotation, acceleration) |
| `emitter.rs`  | `ParticleSystem` struct � simulation loop, physics integration, `draw_commands()` builder, and inline unit tests |
| `math.rs`     | Math helpers: `lerp`, `interpolate_sizes`, `interpolate_colors`, `interpolate_alphas`, `rand_range`, `rand_normal` |
| `emission.rs` | Spawn-offset calculators for area distribution (`emission_offset`) and emission shapes (`emission_shape_offset`) |
| `trail.rs`    | `Trail` and `TrailPoint` � time-fading ribbon effect with width taper and color gradient |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

� [`docs/specs/particle.md`](../../docs/specs/particle.md)

_Update both this file **and** `docs/specs/particle.md` whenever source files, public types, or Lua bindings change._
