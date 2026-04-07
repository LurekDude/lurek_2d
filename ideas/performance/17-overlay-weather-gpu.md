# Overlay & Weather Particles — GPU Particle System

## Module Covered
- `src/overlay/` — weather.rs, state.rs, effects.rs
- Closely related to `src/particle/system.rs` (covered in 03-particle-audio.md)

---

## Current State

Overlay weather particles (rain, snow, dust) are updated each frame:

```rust
// Approximate current code in src/overlay/weather.rs
pub fn tick(&mut self, dt: f32, wind: Vec2) {
    for p in &mut self.particles {
        p.x += (p.vx + wind.x) * dt;
        p.y += (p.vy + wind.y) * dt;
        p.lifetime -= dt;
    }
    self.particles.retain(|p| p.lifetime > 0.0 && in_bounds(p.x, p.y));
    self.spawn_new_particles(); // replenish dead particles
}
```

For 300 rain drops: 300 iterations + 300 retain checks + 300 bounds checks
= **900 operations per frame** just for position updates.

---

## The .retain() Problem (Same as Graph)

`retain()` after particle death scans entire Vec and moves surviving elements.
For 1000 particles with ~5% dying per frame, retain moves 950 elements
unnecessarily.

### Fix: Swap-Remove Dead Particles

```rust
pub fn tick(&mut self, dt: f32, wind: Vec2) {
    let mut i = 0;
    while i < self.particles.len() {
        let p = &mut self.particles[i];
        p.x += (p.vx + wind.x) * dt;
        p.y += (p.vy + wind.y) * dt;
        p.lifetime -= dt;
        if p.lifetime <= 0.0 || !in_bounds(p.x, p.y) {
            // swap_remove: O(1) instead of O(n) shift
            self.particles.swap_remove(i);
        } else {
            i += 1;
        }
    }
    self.spawn_new_particles();
}
```

**Result**: O(n) single pass vs O(n) + O(n) for retain. Constant-factor win.

---

## rayon Parallel Weather Particle Update

```rust
// src/overlay/weather.rs
use rayon::prelude::*;

pub fn tick_parallel(&mut self, dt: f32, wind: Vec2) {
    // Parallel position update (independent per particle)
    self.particles.par_iter_mut().for_each(|p| {
        p.x += (p.vx + wind.x) * dt;
        p.y += (p.vy + wind.y) * dt;
        p.lifetime -= dt;
    });
    // Serial removal (retain doesn't parallelize; use swap-remove loop)
    let mut i = 0;
    while i < self.particles.len() {
        if self.particles[i].lifetime <= 0.0 { self.particles.swap_remove(i); }
        else { i += 1; }
    }
    self.spawn_new_particles();
}
```

**Threshold**: Use parallel only when `count > 500`. For 300 rain drops,
rayon overhead exceeds savings. For 5000 snowflakes (blizzard), 4–8× win.

---

## GPU Particle System for Overlay Effects

For large particle counts (blizzard, sandstorm, heavy rain), offload entirely
to GPU using a compute + draw pipeline:

### Architecture

```
CPU: Write spawn data to GPU buffer once
GPU Compute: Update all particle positions each frame (N threads = N particles)
GPU Draw: Instance-draw all alive particles in one draw call
CPU: No per-frame particle work
```

### Particle Buffer Layout

```rust
// src/overlay/gpu_weather.rs
#[repr(C)]
struct GpuParticle {
    pos:      [f32; 2],   // x, y
    vel:      [f32; 2],   // vx, vy
    lifetime: f32,
    max_life: f32,
    size:     f32,
    _pad:     f32,
}
```

### WGSL Compute Shader

```wgsl
// weather_sim.wgsl
@group(0) @binding(0) var<storage, read_write> particles: array<GpuParticle>;
@group(0) @binding(1) var<uniform> sim: SimParams;

struct SimParams { dt: f32, wind_x: f32, wind_y: f32, gravity: f32 }

@compute @workgroup_size(64)
fn update(@builtin(global_invocation_id) id: vec3<u32>) {
    let i = id.x;
    if i >= arrayLength(&particles) { return; }
    var p = particles[i];
    p.pos.x += (p.vel.x + sim.wind_x) * sim.dt;
    p.pos.y += (p.vel.y + sim.wind_y + sim.gravity) * sim.dt;
    p.lifetime -= sim.dt;
    // Wrap around screen edges instead of spawning new particles
    if p.pos.y > 1.0 { p.pos.y = 0.0; p.pos.x = fract(p.pos.x + 0.3); }
    if p.lifetime <= 0.0 { p.lifetime = p.max_life; p.pos.y = 0.0; }
    particles[i] = p;
}
```

### Instanced Draw: Zero CPU Per Frame

```rust
// After compute dispatch, issue instanced draw
render_pass.set_pipeline(&self.draw_pipeline);
render_pass.set_vertex_buffer(0, self.quad_vbuf.slice(..));
render_pass.set_vertex_buffer(1, self.particle_buf.slice(..)); // instanced data
render_pass.draw(0..6, 0..particle_count);  // ONE draw call for all particles
```

**Performance comparison** (10,000 rain particles):
- CPU update + draw: ~3ms CPU + ~1ms GPU (separate passes)
- GPU compute + instanced draw: ~0.1ms CPU + ~0.3ms GPU

---

## Overlay Screen Effects

Beyond particles, the overlay module manages screen-space ambient effects:
ambient light tint, heat shimmer, underwater ripples. These are all ideal
for fragment/compute shaders:

### Heat Shimmer (Distortion Effect)

```wgsl
// heat_shimmer.wgsl
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let time = params.time;
    let wobble = sin(uv.y * 20.0 + time * 3.0) * params.strength;
    let distorted_uv = vec2<f32>(uv.x + wobble, uv.y);
    return textureSample(scene, samp, distorted_uv);
}
```

### Underwater Ripple

```wgsl
@fragment
fn underwater(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let t = params.time;
    let ripple = sin(uv.x * 15.0 + t) * sin(uv.y * 10.0 + t * 0.7) * 0.01;
    let tinted = textureSample(scene, samp, uv + ripple) * vec4<f32>(0.7, 0.85, 1.0, 1.0);
    return tinted;
}
```

Both effects are pure GPU: 1 fragment shader pass, no CPU involvement.

---

## Summary

| Opportunity | CPU Cost Now | Effort | GPU/CPU After |
|-------------|-------------|--------|---------------|
| swap_remove (no retain) | 2× scan | 30 min | 1× scan |
| rayon particle update | n operations | 1 day | n/4 operations |
| GPU compute particles | ~3ms/frame | 1 week | ~0.1ms/frame |
| Heat shimmer shader | N/A (not implemented) | 1 day | ~0.1ms GPU |
| Underwater shader | N/A (not implemented) | 1 day | ~0.1ms GPU |
