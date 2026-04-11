# `particle` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.particle` |
| **Source** | `src/particle/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The particle module owns emitter-driven 2D particles and trail ribbons. It defines emitter configuration, particle spawning rules, lifetime interpolation, motion updates, trail point aging, and the render-command payloads that describe how those effects should be drawn.

This module exists so transient visual effects can be expressed as reusable CPU simulations instead of one-off draw code. It decides how particles spawn, move, age, and fade, but it does not own gameplay triggers, scene membership, or GPU execution. The renderer consumes the batched particle and trail command data after this module has already produced the effect state.

**Scope boundary**: This module currently depends on `image`, `math`, `render`, `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.particle.* (Lua API — src/lua_api/particle_api.rs)
    |
    v
src/particle/mod.rs
    |- config.rs - config
    |- emission.rs - emission
    |- emitter.rs - emitter
    |- math.rs - math
    |- particle.rs - particle
    |- render.rs - render
    |- shapes.rs - shapes
    |- trail.rs - trail
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `config.rs` | Defines ParticleConfig and the enums that control emission shape, area distribution, insert mode, emitter state, and relative motion. |
| `emission.rs` | Computes spawn offsets from the configured area-distribution and emission-shape rules. |
| `emitter.rs` | Defines ParticleSystem, including spawning, simulation updates, emitter lifecycle, and batched render-command generation. |
| `math.rs` | Defines interpolation and random-sampling helpers used during particle updates. |
| `mod.rs` | Declares the particle submodules and re-exports the public emitter, config, particle, trail, and helper types. |
| `particle.rs` | Defines Particle, the live per-particle state record used during simulation. |
| `render.rs` | Provides standard generate_render_commands wrappers for particle systems and trails. |
| `shapes.rs` | Defines ParticleShape, the geometric primitive enum for untextured particle rendering. |
| `trail.rs` | Defines Trail and TrailPoint for fading ribbon effects built from timestamped points. |

---

## Submodules

### `particle::config`

Defines ParticleConfig and the enums that control emission shape, area distribution, insert mode, emitter state, and relative motion.

- **`AreaDistribution`** (enum): Area distribution mode for particle emission.
- **`InsertMode`** (enum): Insert mode controlling where new particles are placed in the particle list.
- **`EmitterState`** (enum): Emitter lifecycle state controlling whether the system emits and updates particles.
- **`EmissionShape`** (enum): Emission shape controlling where new particles spawn relative to the emitter.
- **`RelativeMode`** (enum): Relative mode controlling whether particles move with the emitter.
- **`ParticleConfig`** (struct): Configuration for a particle emitter.

### `particle::emission`

Computes spawn offsets from the configured area-distribution and emission-shape rules.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `particle::emitter`

Defines ParticleSystem, including spawning, simulation updates, emitter lifecycle, and batched render-command generation.

- **`ParticleSystem`** (struct): An emitter-based particle system.

### `particle::math`

Defines interpolation and random-sampling helpers used during particle updates.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `particle::particle`

Defines Particle, the live per-particle state record used during simulation.

- **`Particle`** (struct): A single particle managed by a `ParticleSystem`.

### `particle::render`

Provides standard generate_render_commands wrappers for particle systems and trails.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `particle::shapes`

Defines ParticleShape, the geometric primitive enum for untextured particle rendering.

- **`ParticleShape`** (enum): Geometric shape used when drawing untextured particles.

### `particle::trail`

Defines Trail and TrailPoint for fading ribbon effects built from timestamped points.

- **`TrailPoint`** (struct): A point in a trail with age tracking.
- **`Trail`** (struct): Fading textured ribbon renderer.

---

## Key Types

### Public Types

#### `ParticleConfig`

Main emitter configuration object controlling spawn rate, lifetime, forces, interpolation curves, rendering shape, and batching limits.

#### `ParticleSystem`

Main emitter simulation that owns the live particle pool and advances it each frame.

#### `Particle`

Per-particle runtime state including position, velocity, lifetime, rotation, and acceleration terms.

#### `ParticleShape`

Enum selecting the geometric primitive used for untextured particles.

#### `EmissionShape`

Enum controlling where particles spawn relative to the emitter.

#### `AreaDistribution`

Enum controlling secondary spread across rectangular or elliptical areas.

#### `EmitterState`

Enum tracking whether an emitter is active, paused, or stopped.

#### `RelativeMode`

Enum controlling whether particles remain in world space or move with the emitter.

#### `Trail`

Fading ribbon effect that stores and ages trail points over time.

#### `TrailPoint`

Individual point stored inside a Trail.

---

## Lua API

Exposed under `lurek.particle.*` by `src/lua_api/particle_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.particle.newSystem` | Creates a new particle system and stores it in the engine pool. |
| `lurek.particle.newTrail` | Creates a new trail ribbon effect. |

### `ParticleSystem` Methods

| Method | Description |
|--------|-------------|
| `particlesystem:update(...)` | Advances the particle simulation by dt seconds. |
| `particlesystem:emit(...)` | Emits a burst of the given number of particles. |
| `particlesystem:start(...)` | Starts or restarts particle emission. |
| `particlesystem:stop(...)` | Stops particle emission immediately. |
| `particlesystem:pause(...)` | Pauses the emitter. |
| `particlesystem:resume(...)` | Resumes a paused emitter. |
| `particlesystem:reset(...)` | Removes all particles and resets the emitter. |
| `particlesystem:moveTo(...)` | Moves the emitter to the given world position. |
| `particlesystem:count(...)` | Returns the number of living particles. |
| `particlesystem:isActive(...)` | Returns true if the emitter is currently emitting or has live particles. |
| `particlesystem:isPaused(...)` | Returns true if the emitter is paused. |
| `particlesystem:isStopped(...)` | Returns true if the emitter is stopped. |
| `particlesystem:isEmpty(...)` | Returns true if there are no live particles. |
| `particlesystem:isFull(...)` | Returns true if the system has reached max_particles. |
| `particlesystem:release(...)` | Removes the particle system from the engine, freeing its slot. |
| `particlesystem:getCount(...)` | Returns the number of living particles (alias for count). |
| `particlesystem:type(...)` | Returns the type name "ParticleSystem". |
| `particlesystem:typeOf(...)` | Returns true if this matches the given type name. |
| `particlesystem:setPosition(...)` | Sets the emitter world position. |
| `particlesystem:getPosition(...)` | Returns the emitter world position. |
| `particlesystem:setEmissionRate(...)` | Sets particles emitted per second. |
| `particlesystem:getEmissionRate(...)` | Returns particles emitted per second. |
| `particlesystem:setParticleLifetime(...)` | Sets min and max particle lifetime in seconds. |
| `particlesystem:getParticleLifetime(...)` | Returns min and max particle lifetime. |
| `particlesystem:setEmitterLifetime(...)` | Sets how long the emitter runs before auto-stopping. Negative = infinite. |
| `particlesystem:getEmitterLifetime(...)` | Returns the emitter lifetime. |
| `particlesystem:setSpeed(...)` | Sets min/max initial speed. |
| `particlesystem:getSpeed(...)` | Returns min/max initial speed. |
| `particlesystem:setDirection(...)` | Sets emission direction in radians. |
| `particlesystem:getDirection(...)` | Returns emission direction in radians. |
| `particlesystem:setSpread(...)` | Sets emission spread (half-angle cone) in radians. |
| `particlesystem:getSpread(...)` | Returns emission spread. |
| `particlesystem:setLinearAcceleration(...)` | Sets linear acceleration range. |
| `particlesystem:getLinearAcceleration(...)` | Returns linear acceleration range. |
| `particlesystem:setRadialAcceleration(...)` | Sets radial acceleration range. |
| `particlesystem:getRadialAcceleration(...)` | Returns radial acceleration range. |
| `particlesystem:setTangentialAcceleration(...)` | Sets tangential acceleration range. |
| `particlesystem:getTangentialAcceleration(...)` | Returns tangential acceleration range. |
| `particlesystem:setLinearDamping(...)` | Sets linear damping range. |
| `particlesystem:getLinearDamping(...)` | Returns linear damping range. |
| `particlesystem:setSizes(...)` | Sets size keyframes (varargs: each number is one keyframe). |
| `particlesystem:getSizes(...)` | Returns size keyframes as a Lua table. |
| `particlesystem:setSizeVariation(...)` | Sets size variation (0–1). |
| `particlesystem:getSizeVariation(...)` | Returns size variation. |
| `particlesystem:setRotation(...)` | Sets initial rotation range in radians. |
| `particlesystem:getRotation(...)` | Returns initial rotation range. |
| `particlesystem:setSpin(...)` | Sets angular velocity range. |
| `particlesystem:getSpin(...)` | Returns angular velocity range. |
| `particlesystem:setSpinVariation(...)` | Sets spin variation (0–1). |
| `particlesystem:getSpinVariation(...)` | Returns spin variation. |
| `particlesystem:setRelativeRotation(...)` | Sets whether particle rotation follows velocity direction. |
| `particlesystem:hasRelativeRotation(...)` | Returns whether relative rotation is enabled. |
| `particlesystem:setColors(...)` | Sets color keyframes. Each arg is a table {r, g, b, a}. |
| `particlesystem:getColors(...)` | Returns color keyframes as a table of {r,g,b,a} tables. |
| `particlesystem:setOffset(...)` | Sets the render origin offset. |
| `particlesystem:getOffset(...)` | Returns the render origin offset. |
| `particlesystem:setInsertMode(...)` | Sets the insert mode: "top", "bottom", or "random". |
| `particlesystem:getInsertMode(...)` | Returns the insert mode as a string. |
| `particlesystem:setBufferSize(...)` | Sets the maximum number of particles (resizes the pool). |
| `particlesystem:getBufferSize(...)` | Returns the maximum particle count. |
| `particlesystem:setEmissionArea(...)` | Sets emission area distribution and size. |
| `particlesystem:getEmissionArea(...)` | Returns emission area: dist-string, w, h. |
| `particlesystem:setShape(...)` | Sets the particle draw shape. |
| `particlesystem:getShape(...)` | Returns the particle draw shape as a string. |
| `particlesystem:getGravity(...)` | Returns gravity (x, y). |
| `particlesystem:setGravity(...)` | Sets gravity (x, y). |
| `particlesystem:render(...)` | Renders all live particles to the GPU command queue. |
| `particlesystem:clone(...)` | Creates a copy of this particle system (config only, no live particles). |
| `particlesystem:drawToImage(...)` | Renders all live particles to a CPU ImageData. |

### `Trail` Methods

| Method | Description |
|--------|-------------|
| `trail:pushPoint(...)` | Appends a new point to the trail head. |
| `trail:update(...)` | Ages trail points and removes expired ones. |
| `trail:setWidth(...)` | Sets the start and end width of the trail ribbon. |
| `trail:getWidth(...)` | Returns the start and end width. |
| `trail:setLifetime(...)` | Sets how long each trail point persists in seconds. |
| `trail:getLifetime(...)` | Returns the trail point lifetime in seconds. |
| `trail:setMinDistance(...)` | Sets the minimum distance between trail points. |
| `trail:getPointCount(...)` | Returns the number of active trail points. |
| `trail:clear(...)` | Removes all trail points. |
| `trail:drawToImage(...)` | Renders the trail ribbon to a CPU ImageData. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.particle.
if lurek.particle then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 5 |
| `enum` | 6 |
| `fn` (Lua API) | 81 |
| **Total** | **92** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Feature Systems to Foundations. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Feature Systems to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/particle/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
