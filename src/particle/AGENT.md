# `particle` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Engine Extensions |
| **Lua API** | `luna.particle` |
| **Source** | `src/particle/` |
| **Tests** | `tests/particle_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_particle.lua` |

## Summary

The particle module implements a CPU-side particle emitter system.  An emitter
configuration declares spawn rate, particle lifetime range, initial velocity
spread (angle range and speed range), gravity scale, a colour gradient from
birth to death, an alpha fade curve, and a size curve over lifetime.  Each
`update(dt)` call advances all active particles, ages them, and culls expired
ones; the surviving particle state is pushed as a `DrawCommand::DrawParticleSystem`
for the GPU renderer to draw as textured quads in a single instanced draw call.

CPU simulation was chosen over GPU-side simulation for Luna2D's particle system
because 2D game particle counts typically range from dozens to a few thousand,
well within single-core CPU budget, and the synchronous Lua control interface
(tweak emitter parameters live from a callback, burst-emit on game events) is
simpler with CPU-local data than with GPU-side simulation state that requires
readback round-trips.  For games that genuinely need tens of thousands of
particles the `compute/` module's GPU compute path is the recommended
alternative.

## Architecture

```
ParticleSystem (main container)
  │
  ├── ParticleConfig (~50 fields)
  │     ├── Emission: rate, burst_count, lifetime, spread
  │     ├── Physics: speed, gravity, acceleration, damping
  │     ├── Appearance: start/end size, colors, rotation
  │     ├── Animation: size_variation, spin, orientation
  │     └── Control: max_particles, buffer_mode
  │
  ├── EmissionShape (8 variants)
  │     Point | Circle | Rectangle | Ring |
  │     Line | Cone | Star | Spiral
  │
  ├── Particle (per-particle state)
  │     ├── x, y, vx, vy (position + velocity)
  │     ├── life, max_life (lifetime tracking)
  │     ├── rotation, spin (angular motion)
  │     ├── radial_accel, tangential_accel
  │     ├── linear_damping, size_variation
  │     └── origin_x, origin_y (emitter origin at spawn)
  │
  └── Update pipeline (per frame)
        ├── Phase 1: Emit new particles (sub-frame interpolation)
        ├── Phase 2: Apply physics (gravity, accel, damping)
        ├── Phase 3: Update position (integrate velocity)
        ├── Phase 4: Age particles (reduce lifetime)
        └── Phase 5: Remove dead particles
```

## Source Files

| File | Purpose |
|------|---------|
| `system.rs` | Particle system module providing emitter-based 2D particle effects |

## Submodules

### `particle::system`

Particle system module providing emitter-based 2D particle effects.

- **`AreaDistribution`** (enum): Area distribution mode for particle emission.
- **`InsertMode`** (enum): Insert mode controlling where new particles are placed in the particle list.
- **`EmitterState`** (enum): Emitter lifecycle state. Delivery is immediate and synchronous; all connected handlers run before this method returns.
- **`EmissionShape`** (enum): Emission shape controlling where new particles spawn relative to the emitter.
- **`RelativeMode`** (enum): Relative mode controlling whether particles move with the emitter.
- **`ParticleConfig`** (struct): Configuration for a particle emitter. Consult the module-level documentation for the broader usage context and...
- **`Particle`** (struct): A single particle managed by a `ParticleSystem`.
- **`ParticleSystem`** (struct): An emitter-based particle system. Consult the module-level documentation for the broader usage context and...
- **`lerp`** (fn): Linearly interpolate between `a` and `b` by factor `t`.
- **`interpolate_sizes`** (fn): Interpolate a multi-stop size array at normalised time `t` (0 = birth, 1 = death).
- **`interpolate_colors`** (fn): Interpolate a multi-stop color array at normalised time `t` (0 = birth, 1 = death).
- **`interpolate_alphas`** (fn): Interpolate a multi-stop alpha array at normalised time `t` (0 = birth, 1 = death).

## Key Types

### Structs

#### `particle::system::Particle`

A single particle managed by a `ParticleSystem`.

#### `particle::system::ParticleConfig`

Configuration for a particle emitter. Consult the module-level documentation for the broader usage context and...

#### `particle::system::ParticleSystem`

An emitter-based particle system. Consult the module-level documentation for the broader usage context and...

### Enums

#### `particle::system::AreaDistribution`

Area distribution mode for particle emission.

#### `particle::system::EmissionShape`

Emission shape controlling where new particles spawn relative to the emitter.

#### `particle::system::EmitterState`

Emitter lifecycle state. Delivery is immediate and synchronous; all connected handlers run before this method returns.

#### `particle::system::InsertMode`

Insert mode controlling where new particles are placed in the particle list.

#### `particle::system::RelativeMode`

Relative mode controlling whether particles move with the emitter.

## Public Functions

- **`interpolate_alphas()`** `system::` — Interpolate a multi-stop alpha array at normalised time `t` (0 = birth, 1 = death).
- **`interpolate_colors()`** `system::` — Interpolate a multi-stop color array at normalised time `t` (0 = birth, 1 = death).
- **`interpolate_sizes()`** `system::` — Interpolate a multi-stop size array at normalised time `t` (0 = birth, 1 = death).
- **`lerp()`** `system::` — Linearly interpolate between `a` and `b` by factor `t`.

## Lua API

Exposed under `luna.particle.*` by `src/lua_api/particle_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 5 |
| `fn` | 4 |
| `mod` | 1 |
| `struct` | 3 |
| **Total** | **13** |

