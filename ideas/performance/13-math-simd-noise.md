# Math Module — SIMD and Parallel Opportunities

## Module Covered
- `src/math/noise.rs` — Simplex/Perlin noise, FBM
- `src/math/vec2.rs` — 2D vector types
- `src/math/easing.rs` — interpolation curves

---

## Noise — The Most Expensive Math Operation

### Current State

FBM (Fractional Brownian Motion) calls `perlin2d()` or `simplex2d()` once
per octave, typically 6–8 octaves. Generating a 256×256 procedural map
calls FBM **65,536 times**, each call computing 6+ noise samples with
gradient lookups, interpolation, and hash operations.

Cost estimate: ~500ns per FBM call × 65,536 calls = **~33ms per map**.
That exceeds a 16ms frame budget by 2×.

---

## Opportunity 1: Rayon Parallel Noise Map Generation

```rust
// src/math/noise.rs
use rayon::prelude::*;

pub fn generate_fbm_map(
    width: usize, height: usize,
    seed: u32, octaves: u32,
    scale: f32, persistence: f32, lacunarity: f32
) -> Vec<f32> {
    let mut map = vec![0.0f32; width * height];
    map.par_chunks_mut(width)
        .enumerate()
        .for_each(|(y, row)| {
            for (x, cell) in row.iter_mut().enumerate() {
                *cell = fbm(
                    x as f32 * scale,
                    y as f32 * scale,
                    seed, octaves, persistence, lacunarity
                );
            }
        });
    map
}
```

**Speedup**: ~4× on quad-core (33ms → ~8ms). Each row is independent.

---

## Opportunity 2: GPU Noise Texture Generation

For 512×512+ procedural terrain/cloud textures, generate on GPU:

```wgsl
// noise_gen.wgsl
@group(0) @binding(0) var output: texture_storage_2d<r32float, write>;
@group(0) @binding(1) var<uniform> params: NoiseParams;

// Simplex noise implemented inline in shader
fn hash2(p: vec2<f32>) -> f32 { ... }
fn simplex2d(p: vec2<f32>) -> f32 { ... }
fn fbm(p: vec2<f32>, octaves: u32) -> f32 { ... }

@compute @workgroup_size(8, 8)
fn main(@builtin(global_invocation_id) id: vec3<u32>) {
    let uv = vec2<f32>(f32(id.x), f32(id.y)) * params.scale;
    let val = fbm(uv + params.offset, params.octaves);
    textureStore(output, vec2<i32>(i32(id.x), i32(id.y)), vec4<f32>(val, 0.0, 0.0, 1.0));
}
```

**Speedup**: 100–1000× for 512×512 (GPU parallel per-texel).
Generate in a single dispatch call, result available as GPU texture.

**Luna API**:
```lua
-- CPU (current): slow for large maps
local map = lurek.math.noiseMap(512, 512, {octaves=6, seed=42})

-- GPU (proposed): instant
local tex = lurek.math.noiseTexture(512, 512, {octaves=6, seed=42})
lurek.gfx.draw(tex, 0, 0)
```

---

## Opportunity 3: SIMD Vec2 Batch Operations

Vec2 operations are called millions of times per frame (particles, physics,
AI steering). Current per-vec implementations process one Vec2 at a time.

**Struct-of-Arrays layout for SIMD**:

```rust
// src/math/vec2_batch.rs
/// 4 Vec2s stored as [f32; 4] X + [f32; 4] Y for SIMD processing
pub struct Vec2x4 {
    pub x: [f32; 4],
    pub y: [f32; 4],
}

impl Vec2x4 {
    pub fn length_squared(&self) -> [f32; 4] {
        // Can use std::simd f32x4
        let mut result = [0.0f32; 4];
        for i in 0..4 {
            result[i] = self.x[i] * self.x[i] + self.y[i] * self.y[i];
        }
        result
    }

    pub fn normalize_all(&mut self) {
        let len_sq = self.length_squared();
        for i in 0..4 {
            if len_sq[i] > 0.0 {
                let inv_len = 1.0 / len_sq[i].sqrt();
                self.x[i] *= inv_len;
                self.y[i] *= inv_len;
            }
        }
    }
}
```

Using `std::simd` (stable Rust ≥ 1.80):
```rust
use std::simd::f32x4;

pub fn add_batch(ax: &[f32], ay: &[f32], bx: &[f32], by: &[f32], rx: &mut [f32], ry: &mut [f32]) {
    for i in (0..ax.len()).step_by(4) {
        let ax4 = f32x4::from_slice(&ax[i..]);
        let bx4 = f32x4::from_slice(&bx[i..]);
        (ax4 + bx4).copy_to_slice(&mut rx[i..]);
        let ay4 = f32x4::from_slice(&ay[i..]);
        let by4 = f32x4::from_slice(&by[i..]);
        (ay4 + by4).copy_to_slice(&mut ry[i..]);
    }
}
```

**Use case**: Particle system positions (`[f32; N]` X, Y arrays).

---

## Opportunity 4: Easing Function Batch Application

Tweens apply easing functions per-object. With 1000 active tweens,
1000 `eease_in_out_cubic(t)` calls per frame.

Vectorize with SIMD: if tween t values are stored in a contiguous slice,
apply cubic polynomial `3t² - 2t³` to 4 values at once:

```rust
// src/math/easing.rs
pub fn ease_in_out_cubic_batch(t: &[f32], out: &mut [f32]) {
    use std::simd::f32x4;
    let two = f32x4::splat(2.0);
    let three = f32x4::splat(3.0);
    for i in (0..t.len()).step_by(4) {
        let t4 = f32x4::from_slice(&t[i..]);
        let t2 = t4 * t4;
        let result = t2 * (three - two * t4);
        result.copy_to_slice(&mut out[i..]);
    }
}
```

**Use case**: `src/lua_api/tween_api.rs` updating all active tweens each frame.

---

## Summary Table

| Opportunity | File | Effort | Speedup | Scale |
|-------------|------|--------|---------|-------|
| Parallel noise map | `noise.rs` | 1 day | 4× | 128×128+ maps |
| GPU noise texture | New compute shader | 1 week | 100–1000× | 512×512+ textures |
| Vec2 SIMD batch | New `vec2_batch.rs` | 3 days | 2–4× | 1000+ particles |
| Easing SIMD batch | `easing.rs` | 2 days | 2–4× | 500+ active tweens |
