# `particle` — Agent Reference

| Property | Value |
|----------|-------|
| **Status** | Implemented — Full (CPU simulation, GPU rendering via DrawParticleSystem) |
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
| `src/particle/mod.rs`      | Module entry point, re-exports, tier and sub-file table |
| `src/particle/config.rs`   | Enums + `ParticleConfig` (~50 fields) |
| `src/particle/shapes.rs`   | `ParticleShape` enum (5 variants) |
| `src/particle/particle.rs` | `Particle` live state struct |
| `src/particle/emitter.rs`  | `ParticleSystem` simulation + `draw_commands()` |
| `src/particle/math.rs`     | Math helpers (`lerp`, `interpolate_*`, `rand_*`) |
| `src/particle/emission.rs` | Emission offset helpers for area distribution and shapes |

## Key Types

### Structs

#### `particle::ParticleConfig`

~50-field configuration struct that fully specifies emitter behaviour: spawn
rate, lifetime range, speed range, emission spread, gravity, multi-stop
size/color/alpha curves, spin, radial/tangential acceleration, linear damping,
drag, turbulence, orbit speed, texture, animated frames, and shape.

#### `particle::Particle`

Per-particle live state: position, velocity, lifetime, rotation, spin,
per-particle radial/tangential acceleration, linear damping, size variation,
and spawn origin for radial direction reference.

#### `particle::ParticleSystem`

The main emitter struct.  Holds a `ParticleConfig`, a `Vec<Particle>` pool,
emitter world position, accumulator for sub-frame emission, lifecycle state
(`EmitterState`), and previous-frame position for move interpolation.

### Enums

#### `particle::ParticleShape`

Geometric primitive used to render untextured particles.  Variants:
`Square` | `Circle` | `Triangle` | `Spark` | `Diamond`.
Mirrored on the GPU side as `ParticleRenderShape` in `src/graphics/renderer.rs`.

#### `particle::EmissionShape`

Controls where new particles spawn relative to the emitter.  8 variants:
`Point` | `Circle` | `Rectangle` | `Ring` | `Line` | `Cone` | `Star` | `Spiral`.

#### `particle::EmitterState`

Lifecycle state: `Active` (emitting) | `Paused` (frozen) | `Stopped` (draining).

#### `particle::AreaDistribution`

Secondary spawn-area spread: `None` | `Uniform` | `Normal` | `Ellipse` |
`BorderEllipse` | `BorderRectangle`.

#### `particle::InsertMode`

Controls list insertion order for new particles: `Top` (end, default) | `Bottom` (front) | `Random`.

#### `particle::RelativeMode`

`Detached` (world-space, default) | `Attached` (moves with emitter).

### GPU Bridge Types (in `src/graphics/renderer.rs`)

| Type | Purpose |
|------|---------|
| `DrawCommand::DrawParticleSystem` | Batched GPU render command -- one per `ParticleSystem::draw_commands()` call |
| `ParticleInstance` | Per-particle render data (pos, color, size, rotation, shape, texture) |
| `ParticleRenderShape` | Tier 1 mirror of `ParticleShape` used by the GPU renderer |

## Lua API Summary

Exposed under `luna.particle.*` by `src/lua_api/particle_api/`.

| Function | Description |
|----------|-------------|
| `luna.particle.new(cfg)` | Create a new `ParticleSystem` from a config table |
| `ps:update(dt)` | Advance simulation by `dt` seconds |
| `ps:draw()` | Queue a `DrawParticleSystem` command |
| `ps:emit(n)` | Burst-emit `n` particles immediately |
| `ps:start()` | Activate emitter (resets age) |
| `ps:stop()` | Stop emitting; existing particles drain |
| `ps:reset()` | Kill all live particles and reset accumulator |
| `ps:count()` | Return number of live particles |
| `ps:setShape(name)` | Set shape: "square", "circle", "triangle", "spark", "diamond" |
| `ps:getShape()` | Return current shape name |

Gravity is set via config fields `gravity_x` / `gravity_y` in `luna.particle.new(cfg)`.

## Test Coverage

| Suite | Description |
|-------|-------------|
| `tests/particle_tests.rs` | >=12 Rust integration tests covering spawn, update, emit, shapes, config defaults |
| `tests/lua/unit/test_particle.lua` | Lua BDD tests (62 assertions including the full particle suite) |

## Examples

| Example | Description |
|---------|-------------|
| `examples/particles_demo/main.lua` | Full showcase: fire, explosion, smoke, sparks, magic, and snow emitters |

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 6 (`AreaDistribution`, `InsertMode`, `EmitterState`, `EmissionShape`, `RelativeMode`, `ParticleShape`) |
| `fn` | 4 (`lerp`, `interpolate_sizes`, `interpolate_colors`, `interpolate_alphas`) |
| `mod` | 6 (`config`, `emission`, `emitter`, `math`, `particle`, `shapes`) |
| `struct` | 3 (`ParticleConfig`, `Particle`, `ParticleSystem`) |
| **Total** | **19** |
