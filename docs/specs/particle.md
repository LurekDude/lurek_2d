# `particle` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.particles`                                      |
| **Source**      | `src/particle/`                                      |
| **Rust Tests** | `tests/rust/unit/particle_tests.rs`                  |
| **Lua Tests**  | `tests/lua/unit/test_particle.lua`                   |
| **Architecture** | —                                                  |

## Summary

The particle module implements a CPU-side emitter-based 2D particle system with trail-ribbon rendering. A `ParticleSystem` spawns short-lived `Particle` entities each frame according to a ~50-field `ParticleConfig`, advances their position and velocity through gravity, radial/tangential acceleration, linear damping, quadratic drag, orbital rotation, and turbulence, then culls expired particles — keeping allocation bounded by `ParticleConfig::max_particles`. The surviving particle state is batched into a single `DrawCommand::DrawParticleSystem` for the GPU renderer to draw as textured quads or geometric shape primitives (Square, Circle, Triangle, Spark, Diamond) in one instanced draw call.

Multi-stop interpolation drives particle size, color (RGBA), and alpha over each particle's normalised lifetime (0 = birth, 1 = death). An independent `alpha_keyframes` array can override the alpha channel from the color gradient. A `color_by_speed` mode maps color stops to the particle's current speed instead of lifetime. Eight emission shapes (Point, Circle, Rectangle, Ring, Line, Cone, Star, Spiral) control where particles spawn relative to the emitter, while six area-distribution modes (None, Uniform, Normal, Ellipse, BorderEllipse, BorderRectangle) provide a secondary spatial spread layer. Particles can be detached (world-space) or attached (move with emitter) via the `RelativeMode` setting.

The `Trail` struct provides a complementary fading ribbon effect: timestamped points are pushed at the head, aged each frame, and expired points are pruned. Width tapers linearly from head to tail; head and tail colors interpolate along the ribbon. Trail and particle system are independent types — game scripts may use them separately or together.

CPU simulation was chosen over GPU-side simulation because 2D game particle counts typically range from dozens to a few thousand, well within single-core CPU budget. The synchronous Lua control interface (tweak emitter parameters live from a callback, burst-emit on game events) is simpler with CPU-local data than with GPU-side simulation state requiring readback round-trips. For games needing tens of thousands of particles the `compute/` module's GPU compute path is the recommended alternative.

## Architecture

```
luna.particles.newSystem(config)
       |
       v
+------------------------------------------------------+
| ParticleSystem                                       |
| +-- ParticleConfig (~50 fields)                      |
| |   +-- Emission: rate, lifetime, speed, spread      |
| |   +-- Physics: gravity, accel, damping, drag       |
| |   +-- Appearance: sizes[], colors[], alpha[], shape |
| |   +-- Animation: quads[], animated_frames, fps     |
| |   +-- Control: max_particles, insert_mode          |
| |                                                    |
| +-- EmissionShape (8 variants)                       |
| |   Point|Circle|Rect|Ring|Line|Cone|Star|Spiral     |
| |                                                    |
| +-- AreaDistribution (6 variants)                    |
| |   None|Uniform|Normal|Ellipse|BorderEllipse|Rect   |
| |                                                    |
| +-- Vec<Particle> (pool, capacity = max_particles)   |
| |   +-- x, y, vx, vy          (position + velocity) |
| |   +-- life, max_life         (lifetime tracking)   |
| |   +-- rotation, spin         (angular motion)      |
| |   +-- radial_accel, tangential_accel               |
| |   +-- linear_damping, size_variation               |
| |   +-- origin_x, origin_y    (radial ref point)    |
| |                                                    |
| +-- EmitterState: Active | Paused | Stopped          |
|                                                      |
| update(dt)                                           |
| +-- 1. Check emitter lifetime -> auto-stop           |
| +-- 2. Physics: radial + tangential accel            |
| +-- 3. Gravity (linear accel)                        |
| +-- 4. Linear damping + quadratic drag               |
| +-- 5. Orbital rotation + turbulence                 |
| +-- 6. Integrate position (vx*dt, vy*dt)             |
| +-- 7. Update rotation (relative or spin)            |
| +-- 8. Age particles (life -= dt)                    |
| +-- 9. Remove dead particles                         |
| +-- 10. Emit new particles if active                 |
|                                                      |
| draw_commands(ox, oy)                                |
| +-- Batch all particles into one                     |
|     DrawCommand::DrawParticleSystem                  |
|     +-- interpolate_sizes(t)                         |
|     +-- interpolate_colors(t) or color_by_speed      |
|     +-- interpolate_alphas(t) override               |
|     +-- ParticleInstance per particle                 |
+------------------------------------------------------+

luna.particles.newTrail(lifetime, start_width)
       |
       v
+------------------------------------------------------+
| Trail                                                |
| +-- Vec<TrailPoint> { x, y, age }                    |
| +-- lifetime, min_distance                           |
| +-- start_width -> end_width (linear taper)          |
| +-- head_color -> tail_color (color gradient)        |
|                                                      |
| push_point(x, y) -> insert at head if > min_distance |
| update(dt)        -> age all points, prune expired    |
+------------------------------------------------------+
```

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs`      | Module entry point, re-exports all public types, tier and sub-file table in module-level docs |
| `config.rs`   | `ParticleConfig` (~50 fields) and enums: `AreaDistribution`, `InsertMode`, `EmitterState`, `EmissionShape`, `RelativeMode` |
| `shapes.rs`   | `ParticleShape` enum — five geometric render primitives (Square, Circle, Triangle, Spark, Diamond) |
| `particle.rs` | `Particle` struct — per-particle live state (position, velocity, lifetime, rotation, acceleration) |
| `emitter.rs`  | `ParticleSystem` struct — simulation loop, physics integration, `draw_commands()` builder, and inline unit tests |
| `math.rs`     | Math helpers: `lerp`, `interpolate_sizes`, `interpolate_colors`, `interpolate_alphas`, `rand_range`, `rand_normal` |
| `emission.rs` | Spawn-offset calculators for area distribution (`emission_offset`) and emission shapes (`emission_shape_offset`) |
| `trail.rs`    | `Trail` and `TrailPoint` — time-fading ribbon effect with width taper and color gradient |

## Submodules

### `config`

| Type | Name | Description |
|------|------|-------------|
| `struct` | `ParticleConfig` | ~50-field emitter configuration: emission rate, lifetime, speed, gravity, multi-stop size/color/alpha curves, spin, acceleration, damping, drag, turbulence, orbit, texture, shape, emission shape, area distribution, insert mode, relative mode |
| `enum` | `AreaDistribution` | Area spread mode for emission: None, Uniform, Normal, Ellipse, BorderEllipse, BorderRectangle |
| `enum` | `InsertMode` | Where new particles are placed in the list: Top (end), Bottom (front), Random |
| `enum` | `EmitterState` | Emitter lifecycle: Active, Paused, Stopped |
| `enum` | `EmissionShape` | Spawn position distribution: Point, Circle, Rectangle, Ring, Line, Cone, Star, Spiral |
| `enum` | `RelativeMode` | Whether particles move with emitter: Detached (world-space), Attached (emitter-relative) |

### `shapes`

| Type | Name | Description |
|------|------|-------------|
| `enum` | `ParticleShape` | Geometric primitive for untextured particles: Square, Circle, Triangle, Spark, Diamond. Mirrored as `ParticleRenderShape` in `src/graphics/renderer.rs` |

### `particle`

| Type | Name | Description |
|------|------|-------------|
| `struct` | `Particle` | Per-particle live state: position (x, y), velocity (vx, vy), life/max_life, rotation, spin, radial/tangential acceleration, linear damping, size variation, origin coordinates |

### `emitter`

| Type | Name | Description |
|------|------|-------------|
| `struct` | `ParticleSystem` | Main emitter container: holds config, particle pool, emitter position, accumulator, lifecycle state, and previous-frame position for move interpolation |

### `math`

| Type | Name | Description |
|------|------|-------------|
| `fn` | `lerp(a, b, t)` | Linear interpolation between two floats |
| `fn` | `interpolate_sizes(sizes, t, variation)` | Multi-stop size array interpolation at normalised time t with variation factor |
| `fn` | `interpolate_colors(colors, t)` | Multi-stop RGBA color array interpolation at normalised time t |
| `fn` | `interpolate_alphas(alphas, t)` | Multi-stop alpha array interpolation at normalised time t |
| `fn` | `rand_range(min, max)` | Uniform random float in [min, max] (pub(crate)) |
| `fn` | `rand_normal()` | Standard-normal random via Box-Muller transform (pub(crate)) |

### `emission`

| Type | Name | Description |
|------|------|-------------|
| `fn` | `emission_offset(config)` | Compute spawn offset (dx, dy) based on area distribution settings (pub(crate)) |
| `fn` | `emission_shape_offset(shape)` | Compute spawn offset (dx, dy) based on emission shape geometry (pub(crate)) |

### `trail`

| Type | Name | Description |
|------|------|-------------|
| `struct` | `TrailPoint` | A point in a trail with x, y position and age tracking |
| `struct` | `Trail` | Fading ribbon renderer with point list, lifetime, start/end width, head/tail color, and min distance threshold |

## Key Types

### Structs

#### `particle::config::ParticleConfig`

~50-field configuration struct that fully specifies emitter behaviour. Includes emission rate, particle lifetime range, speed range, emission direction and spread, gravity (X/Y), multi-stop size and color arrays, spin range, rotation range, spin/size variation, linear acceleration (X/Y min/max), radial/tangential acceleration, linear damping, area distribution with width/height/angle, emitter lifetime, insert mode, offset, relative rotation, optional texture key, quad sub-regions for sprite sheets, alpha keyframes, emission shape, relative mode, turbulence, quadratic drag, orbit speed, animated frames with frame rate, color-by-speed mode, and geometric particle shape. Implements `Default` with sensible values (256 max particles, 10/s emission rate, upward direction, 45-degree spread, white-to-transparent fade, 4px to 1px size).

#### `particle::particle::Particle`

Per-particle live state held in the `ParticleSystem` pool. Fields: position (x, y) relative to emitter origin, velocity (vx, vy), remaining life and max life for interpolation ratio, rotation and spin (angular velocity), per-particle radial and tangential acceleration, linear damping factor, size variation factor, and birth origin coordinates for radial direction reference.

#### `particle::emitter::ParticleSystem`

The main emitter struct. Holds a `ParticleConfig`, a `Vec<Particle>` pool (pre-allocated to `max_particles` capacity), emitter world position, a fractional emit accumulator for sub-frame emission accuracy, lifecycle state (`EmitterState`), accumulated emitter age, and previous-frame position for move interpolation. Public methods: `new`, `update`, `emit`, `count`, `reset`, `start`, `stop`, `pause`, `resume`, `move_to`, `clone_config`, `is_active`, `is_paused`, `is_stopped`, `is_empty`, `is_full`, `draw_commands`.

#### `particle::trail::TrailPoint`

A point in a trail with `x`, `y` world-space position and an `age` field tracking how long the point has existed in seconds.

#### `particle::trail::Trail`

Fading ribbon renderer. Points are pushed at the head via `push_point(x, y)` (subject to `min_distance` threshold) and automatically removed once their age exceeds the configured `lifetime`. Width tapers linearly from `start_width` at the head to `end_width` at the tail. Colors interpolate from `head_color` to `tail_color`. Public methods: `new`, `push_point`, `update`, `set_width`, `get_width`, `set_lifetime`, `get_lifetime`, `set_min_distance`, `set_head_color`, `set_tail_color`, `clear`, `get_point_count`.

### Enums

#### `particle::config::AreaDistribution`

Area distribution mode for particle emission. 6 variants: `None` (spawn at center), `Uniform` (random inside rectangle), `Normal` (Gaussian-approximated inside rectangle), `Ellipse` (random inside ellipse), `BorderEllipse` (on ellipse border), `BorderRectangle` (on rectangle border). Used alongside `area_width`, `area_height`, and `area_angle` config fields.

#### `particle::config::InsertMode`

Controls where new particles are placed in the particle list. 3 variants: `Top` (end of list, drawn on top — default), `Bottom` (front, drawn behind), `Random` (random position). Affects visual layering of overlapping particles.

#### `particle::config::EmitterState`

Emitter lifecycle state. 3 variants: `Active` (emitting and updating), `Paused` (frozen in place, no new emissions or physics updates), `Stopped` (no new emissions, existing particles continue ageing until dead).

#### `particle::config::EmissionShape`

Controls where new particles spawn relative to the emitter. 8 variants: `Point` (center), `Circle { radius, fill }` (within or on edge), `Rectangle { width, height }` (within rectangle), `Ring { inner_radius, outer_radius }` (annulus), `Line { length, angle }` (along line segment), `Cone { radius, angle, spread }` (cone sector), `Star { points, outer_radius, inner_radius }` (star polygon edges), `Spiral { revolutions, radius }` (Archimedean spiral). When set to anything other than `Point`, overrides the `AreaDistribution` for spawn offset calculation.

#### `particle::config::RelativeMode`

Controls whether particles follow the emitter. 2 variants: `Detached` (particles remain in world space after emission — default), `Attached` (particles move with the emitter position each frame).

#### `particle::shapes::ParticleShape`

Geometric shape for untextured particle rendering. 5 variants: `Square` (axis-aligned filled square — default), `Circle` (filled circle), `Triangle` (filled equilateral triangle), `Spark` (thin line along velocity direction, length = size x 3), `Diamond` (square rotated 45 degrees). Ignored when `texture_id` is set. Mirrored on the GPU side as `ParticleRenderShape` in `src/graphics/renderer.rs`.

## Lua API

Registered by `src/lua_api/particle_api.rs` under `luna.particles`. The module exposes two factory functions on the `luna.particles` table and UserData methods on the returned objects.

### Module Functions

| Function | Description |
|----------|-------------|
| `luna.particles.newSystem(config?)` | Create a new `ParticleSystem`. Accepts an optional config table with camelCase keys (e.g. `maxParticles`, `emissionRate`, `lifetimeMin`). Returns a ParticleSystem userdata. |
| `luna.particles.newTrail(lifetime, start_width)` | Create a new `Trail` ribbon effect with the given point lifetime (seconds) and head width (pixels). Returns a Trail userdata. |

### ParticleSystem Methods

| Method | Description |
|--------|-------------|
| `ps:update(dt)` | Advance simulation by `dt` seconds |
| `ps:emit(count)` | Burst-emit `count` particles immediately |
| `ps:start()` | Activate emitter (resets emitter age) |
| `ps:stop()` | Stop emitting; existing particles drain |
| `ps:pause()` | Freeze all particles in place |
| `ps:resume()` | Resume from paused or stopped state |
| `ps:reset()` | Kill all live particles and reset accumulator |
| `ps:moveTo(x, y)` | Move emitter to world position |
| `ps:count()` | Return number of live particles |
| `ps:isActive()` | Return true if emitting |
| `ps:isPaused()` | Return true if paused |
| `ps:isStopped()` | Return true if stopped |
| `ps:isEmpty()` | Return true if no live particles |
| `ps:isFull()` | Return true if at max_particles cap |
| `ps:release()` | Remove from engine pool, free the slot |

### Trail Methods

| Method | Description |
|--------|-------------|
| `trail:pushPoint(x, y)` | Append a new point at the trail head |
| `trail:update(dt)` | Age points and remove expired ones |
| `trail:setWidth(start, end?)` | Set ribbon start and optional end width |
| `trail:getWidth()` | Return `start_width, end_width` |
| `trail:setLifetime(lifetime)` | Set max point age in seconds |
| `trail:getLifetime()` | Return max point age |
| `trail:setMinDistance(distance)` | Set minimum distance between points |
| `trail:setHeadColor(r, g, b, a)` | Set color at newest end |
| `trail:setTailColor(r, g, b, a)` | Set color at oldest end |
| `trail:getPointCount()` | Return number of active points |
| `trail:clear()` | Remove all points |

### Config Table Keys

The config table passed to `newSystem()` supports these camelCase keys (all optional, defaults in parentheses):

| Key | Type | Default |
|-----|------|---------|
| `maxParticles` | integer | 256 |
| `emissionRate` | number | 10.0 |
| `lifetimeMin` / `lifetimeMax` | number | 1.0 / 2.0 |
| `speedMin` / `speedMax` | number | 50.0 / 100.0 |
| `direction` | number (radians) | -pi/2 (upward) |
| `spread` | number (radians) | pi/4 |
| `gravityX` / `gravityY` | number | 0.0 |
| `sizes` | table of numbers | {4.0, 1.0} |
| `colors` | table of {r,g,b,a} | white to transparent |
| `alphaKeyframes` | table of numbers | {} |
| `spinMin` / `spinMax` | number | 0.0 |
| `rotationMin` / `rotationMax` | number | 0.0 |
| `spinVariation` / `sizeVariation` | number | 0.0 |
| `linearAccelXMin` / `linearAccelXMax` | number | 0.0 |
| `linearAccelYMin` / `linearAccelYMax` | number | 0.0 |
| `radialAccelMin` / `radialAccelMax` | number | 0.0 |
| `tangentialAccelMin` / `tangentialAccelMax` | number | 0.0 |
| `linearDampingMin` / `linearDampingMax` | number | 0.0 |
| `emitterLifetime` | number | -1 (infinite) |
| `areaDistribution` | string | "none" |
| `areaWidth` / `areaHeight` | number | 0.0 |
| `areaAngle` | number | 0.0 |
| `areaDirectionRelative` | boolean | false |
| `insertMode` | string | "top" |
| `offsetX` / `offsetY` | number | 0.0 |
| `relativeRotation` | boolean | false |
| `emissionShape` | string | "point" |
| `relativeMode` | string | "detached" |
| `turbulence` | number | 0.0 |
| `drag` | number | 0.0 |
| `orbitSpeed` | number | 0.0 |
| `animatedFrames` | integer | 0 |
| `frameRate` | number | 12.0 |
| `colorBySpeed` | boolean | false |
| `speedColorMin` / `speedColorMax` | number | 0.0 / 200.0 |
| `shape` | string | "square" |

## Lua Examples

```lua
-- Fire emitter with gravity and alpha fade
function luna.init()
    fire = luna.particles.newSystem({
        maxParticles = 500,
        emissionRate = 80,
        lifetimeMin  = 0.5,
        lifetimeMax  = 1.5,
        speedMin     = 30,
        speedMax     = 80,
        direction    = -math.pi / 2,
        spread       = math.pi / 6,
        gravityY     = -20,
        sizes        = {6, 3, 1},
        colors       = {
            {1.0, 0.8, 0.2, 1.0},
            {1.0, 0.3, 0.0, 0.8},
            {0.3, 0.1, 0.1, 0.0},
        },
        shape        = "circle",
    })
end

function luna.process(dt)
    fire:update(dt)
    fire:moveTo(400, 500)
end

function luna.render()
    luna.gfx.draw(fire, 0, 0)
end
```

```lua
-- Trail ribbon following the mouse
function luna.init()
    ribbon = luna.particles.newTrail(0.8, 12)
    ribbon:setHeadColor(0.2, 0.6, 1.0, 1.0)
    ribbon:setTailColor(0.2, 0.6, 1.0, 0.0)
end

function luna.process(dt)
    local mx, my = luna.mouse.getPosition()
    ribbon:pushPoint(mx, my)
    ribbon:update(dt)
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 5     |
| `enum`     | 6     |
| `fn` (pub) | 33    |
| `mod`      | 7     |
| **Total**  | **51**|

## References

| Module      | Relationship  | Notes                                              |
|-------------|---------------|----------------------------------------------------|
| `engine`    | Imports from  | Uses `SharedState`, `ParticleKey` (SlotMap key)    |
| `math`      | Imports from  | `Color` type for trail head/tail colors            |
| `graphics`  | Related       | Pushes `DrawCommand::DrawParticleSystem` into draw queue; `ParticleRenderShape` mirrors `ParticleShape` |
| `lua_api`   | Imported by   | `src/lua_api/particle_api.rs` registers `luna.particles.*` with `LuaParticleSystem` and `LuaTrail` UserData |
| `compute`   | Alternative   | GPU compute path recommended for >10K particles; particle module is CPU-only |
| `graphics::renderer` | Bridge | `ParticleInstance` and `ParticleRenderShape` are the GPU-side data types consumed by the renderer |

## Notes

- **CPU simulation only**: All particle positions are updated in Rust each frame. The GPU renderer only receives the final per-particle instance data via `DrawCommand::DrawParticleSystem`. No GPU-side simulation or readback.
- **Pool size fixed at creation**: The particle pool is pre-allocated to `max_particles` capacity via `Vec::with_capacity`. The pool never grows beyond this cap. New particles are silently dropped when the pool is full.
- **Sub-frame emission accuracy**: The `emit_accumulator` field tracks fractional particles between frames, ensuring consistent visual density regardless of frame rate.
- **Emission shape vs area distribution**: When `emission_shape` is anything other than `Point`, it takes precedence over `area_distribution`. Both systems compute a spawn offset `(dx, dy)` but only one is used per particle.
- **Texture is optional**: Untextured particles render as geometric shapes from `ParticleShape`. When a texture is set, quad sub-regions can cycle via lifetime progress or animated frame playback.
- **Trail is independent**: `Trail` is a standalone type, not coupled to `ParticleSystem`. It does not produce `DrawCommand`s itself — the rendering integration is handled by the Lua API or user code.
- **Inline unit tests**: `emitter.rs` contains 29 inline `#[cfg(test)]` unit tests covering default config, emission, death, state transitions, interpolation, emission shapes, alpha keyframes, and clone.
- **External crate**: Uses `fastrand` for all random sampling (uniform and Box-Muller normal). No thread-local RNG state — safe for single-threaded particle updates but not deterministically reproducible across runs.
- **Breaking change surface**: Renaming config table keys in `particle_api.rs::config_from_table` breaks existing Lua game scripts. The camelCase key names (`emissionRate`, `lifetimeMin`, etc.) are the stable API contract.
- **Frame-rate independence**: Always pass `dt` to `ps:update(dt)`. Never assume fixed 60 FPS — the accumulator-based emission model handles variable frame rates correctly.
