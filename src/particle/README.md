# `src/particle/` — Particle Systems

## Purpose

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

### How It Works

Each `ParticleSystem` owns a pre-allocated pool of `Particle` structs in a
`Vec` sized to the declared maximum particle count.  Inactive particles are
kept at the end of the live prefix via swap-and-pop removal, so iteration
during `update()` is contiguous and cache-friendly regardless of the
alive/dead ratio.

The spawn accumulator pattern ensures smooth rates across variable frame
times: `spawn_accumulator += spawn_rate * dt` each tick, and whole particles
are spawned per tick.  A tick with a long delta may spawn multiple particles;
a tick with a very short delta may spawn zero.  Burst mode injects `count`
particles instantaneously while respecting the pool maximum — excess burst
particles are silently dropped rather than growing the pool.

Particle colour and size over lifetime use a linear multi-stop gradient sampled
at `age / max_lifetime`.  The gradient is evaluated per-particle per frame
using a binary search for the enclosing stops followed by linear interpolation
— this is intentionally simple and allocates nothing.

### Dependency Direction

```
particle/ ──────► engine::resource_keys (TextureKey)
              ──► graphics::renderer (DrawCommand, DrawMode)
```

---

## File-by-File Analysis

### `mod.rs` — Complete Particle System (Single File Module)

**~900 lines** | Full particle system implementation.

#### Enums

| Enum | Variants | Purpose |
|------|----------|---------|
| `AreaDistribution` | 6 variants | Particle spawn distribution pattern |
| `InsertMode` | Top, Bottom, Random | Where new particles go in the list |
| `EmitterState` | Active, Paused, Stopped | Emitter lifecycle state |
| `EmissionShape` | Point, Circle, Rectangle, Ring, Line, Cone, Star, Spiral | Spawn area shape |
| `RelativeMode` | Detached, Attached | Particle movement reference frame |

#### Struct: `ParticleConfig` (~50 fields)

```rust
pub struct ParticleConfig {
    // Emission
    pub emission_rate: f32,
    pub particle_lifetime: (f32, f32),   // min, max
    pub max_particles: usize,
    pub emission_shape: EmissionShape,
    
    // Physics
    pub speed: (f32, f32),
    pub direction: f32,
    pub spread: f32,
    pub gravity_x: f32,
    pub gravity_y: f32,
    pub radial_acceleration: (f32, f32),
    pub tangential_acceleration: (f32, f32),
    pub linear_damping: (f32, f32),
    
    // Appearance
    pub sizes: Vec<f32>,          // multi-stop keyframes
    pub colors: Vec<(f32, f32, f32, f32)>,  // RGBA keyframes
    pub rotation: (f32, f32),
    pub spin: (f32, f32),
    // ... and more
}
```

#### Struct: `Particle`

```rust
pub struct Particle {
    x: f32, y: f32,
    vx: f32, vy: f32,
    life: f32, max_life: f32,
    rotation: f32, spin: f32,
    radial_accel: f32,
    tangential_accel: f32,
    linear_damping: f32,
    size_variation: f32,
    origin_x: f32, origin_y: f32,
}
```

#### Struct: `ParticleSystem`

```rust
pub struct ParticleSystem {
    config: ParticleConfig,
    particles: Vec<Particle>,
    emitter_x: f32, emitter_y: f32,
    prev_emitter_x: f32, prev_emitter_y: f32,
    emit_accumulator: f32,
    state: EmitterState,
    emitter_age: f32,
}
```

#### Methods

| Method | Purpose |
|--------|---------|
| `new(config)` | Create particle system |
| `update(dt)` | 5-phase update pipeline |
| `emit(count)` | Manually emit N particles |
| `start()` / `stop()` / `pause()` / `resume()` / `reset()` | Lifecycle |
| `move_to(x, y)` | Reposition emitter |
| `clone_config()` | Get config copy |
| `count()` | Active particle count |
| `is_active/paused/stopped/empty/full()` | State queries |
| `draw_commands()` | Generate DrawCommand list |

#### Helpers (internal)

| Helper | Purpose |
|--------|---------|
| `lerp(a, b, t)` | Linear interpolation |
| `interpolate_sizes(life_ratio)` | Multi-stop size keyframe |
| `interpolate_colors(life_ratio)` | Multi-stop color keyframe |
| `interpolate_alphas(life_ratio)` | Multi-stop alpha keyframe |
| `rand_range(min, max)` | Random float (fastrand) |
| `rand_normal()` | Normal distribution sample |
| `emission_offset(shape)` | Position within emission shape |

**Design**: Sub-frame emission prevents clumping — when the emitter moves fast,
particles are spawned at interpolated positions along the emitter's path.
Multi-stop keyframes allow complex color/size gradients over particle lifetime.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/particle_api.rs` (~700 lines), exposing
particle systems under `luna.particle.*`.

### Usage from Lua

```lua
-- Create particle system
local ps = luna.particle.newParticleSystem(texture, 1000)
ps:setEmissionRate(100)
ps:setParticleLifetime(0.5, 2.0)
ps:setSpeed(50, 200)
ps:setSizes(1.0, 0.5, 0.0)  -- shrink over lifetime
ps:setColors(1,1,0,1, 1,0,0,1, 0,0,0,0)  -- yellow → red → transparent
ps:start()

-- In update
ps:update(dt)
ps:moveTo(player.x, player.y)

-- In draw
luna.graphics.draw(ps)
```
