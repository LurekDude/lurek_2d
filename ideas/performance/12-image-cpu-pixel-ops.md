# Image CPU Pixel Operations — CPU Threading and GPU Offload

## Module Covered
- `src/image/image_data.rs` — CPU pixel manipulation, ImageData

---

## Current State

`ImageData` exposes `get_pixel`, `set_pixel`, `fill`, and likely `copy_region`
as CPU operations. When game scripts call these in nested loops for effects,
they create O(w × h) main-thread work.

**Worst case: software convolution kernel**
```lua
-- Lua script may call set_pixel in a nested loop (100k+ calls)
for y = 0, img:getHeight() - 1 do
  for x = 0, img:getWidth() - 1 do
    img:setPixel(x, y, r, g, b, a)  -- Lua→Rust boundary each call
  end
end
```

A 512×512 image = **262,144 Lua→Rust boundary crossings per operation**.

---

## Opportunity 1: Bulk Pixel Operations (Highest ROI)

Expose batch operations that avoid the Lua→Rust boundary per pixel:

```rust
// src/image/image_data.rs
impl ImageData {
    /// Fill a rectangular region — no per-pixel Lua overhead
    pub fn fill_rect(&mut self, x: u32, y: u32, w: u32, h: u32, color: [u8; 4]) {
        let pitch = self.width as usize * 4;
        for row in y..y+h {
            let base = row as usize * pitch + x as usize * 4;
            for px in 0..w as usize {
                self.pixels[base + px*4..base + px*4 + 4].copy_from_slice(&color);
            }
        }
    }

    /// Apply a per-pixel mapping function (closure)
    pub fn map_pixels<F: Fn([u8;4]) -> [u8;4] + Send + Sync>(&mut self, f: F) {
        use rayon::prelude::*;
        self.pixels.par_chunks_mut(4).for_each(|px| {
            let result = f([px[0], px[1], px[2], px[3]]);
            px.copy_from_slice(&result);
        });
    }
}
```

**Luna API**:
```lua
-- Instead of 262k Lua calls:
img:mapPixels(function(r, g, b, a)
    return r * 0.5, g * 0.5, b * 0.5, a  -- darken
end)
-- Single Lua→Rust call; Rust does the inner loop
```

---

## Opportunity 2: rayon Parallel Pixel Processing

```rust
// src/image/image_data.rs
use rayon::prelude::*;

impl ImageData {
    pub fn parallel_map_pixels<F>(&mut self, f: F)
    where F: Fn(u32, u32, [u8;4]) -> [u8;4] + Send + Sync
    {
        let width = self.width as usize;
        self.pixels
            .par_chunks_mut(width * 4)   // one row per thread task
            .enumerate()
            .for_each(|(y, row)| {
                for x in 0..width {
                    let base = x * 4;
                    let px = [row[base], row[base+1], row[base+2], row[base+3]];
                    let result = f(x as u32, y as u32, px);
                    row[base..base+4].copy_from_slice(&result);
                }
            });
    }

    pub fn convolve(&mut self, kernel: &[[f32; 3]; 3]) {
        // Split into horizontal scanlines, process in parallel
        // Kernel overlap handled by read source / write dest double buffer
        let src = self.pixels.clone();  // read from source
        let width = self.width as usize;
        let height = self.height as usize;
        self.pixels
            .par_chunks_mut(width * 4)
            .enumerate()
            .for_each(|(y, dst_row)| {
                // apply kernel across row using src
                apply_kernel_row(y, width, height, &src, dst_row, kernel);
            });
    }
}
```

**Speedup**: 4–8× for 512×512 operations on quad-core.

---

## Opportunity 3: GPU Texture Pass (Largest Scales)

For blur, gaussian, Sobel edge detection, dithering on 1024×1024+:

```rust
// Hypothetical src/image/gpu_effects.rs
// Uses existing wgpu device from SharedState
impl GpuRenderer {
    pub fn gpu_blur_image(&self, image: &ImageData, radius: u32) -> ImageData {
        // 1. Upload pixels to GPU texture (input)
        // 2. Run compute shader (separable gaussian)
        // 3. Read back result texture to CPU
        // Net: 100× faster than CPU for large images
    }
}
```

**WGSL compute shader for Gaussian blur**:
```wgsl
@group(0) @binding(0) var input: texture_2d<f32>;
@group(0) @binding(1) var output: texture_storage_2d<rgba8unorm, write>;

@compute @workgroup_size(8, 8)
fn blur_horizontal(@builtin(global_invocation_id) id: vec3<u32>) {
    let coord = vec2<i32>(i32(id.x), i32(id.y));
    var sum = vec4<f32>(0.0);
    var weight = 0.0;
    for (var i = -4; i <= 4; i++) {
        let s = exp(-f32(i*i) / 8.0);
        sum += textureLoad(input, coord + vec2<i32>(i, 0), 0) * s;
        weight += s;
    }
    textureStore(output, coord, sum / weight);
}
```

---

## Opportunity 4: SIMD Pixel Blending

For alpha-compositing two 512×512 images (common in image editing tools):

```rust
// Blend 4 RGBA pixels at once using u8x4 SIMD
// Using std::simd (nightly) or manual NEON/SSE intrinsics:
fn blend_rows_simd(src: &[u8], dst: &mut [u8], alpha: u8) {
    // Process 16 bytes = 4 RGBA pixels per iteration
    for (s, d) in src.chunks_exact(16).zip(dst.chunks_exact_mut(16)) {
        // Manual SIMD blend: d = s * alpha/255 + d * (1-alpha/255)
        for i in 0..16 {
            d[i] = ((s[i] as u16 * alpha as u16
                   + d[i] as u16 * (255 - alpha as u16)) / 255) as u8;
        }
    }
}
```

Using `std::simd` (stable in Rust 1.80+):
```rust
use std::simd::{u8x16, SimdUint};
fn blend_simd(src: &[u8], dst: &mut [u8], alpha: u16) { ... }
```

---

## Effort vs Impact Matrix

| Opportunity | Effort | Speedup | When Beneficial |
|-------------|--------|---------|-----------------|
| `mapPixels` Lua API | 1 day | 100× (boundary savings) | Any per-pixel effect |
| rayon parallel map | 2 days | 4–8× | 256×256+ images |
| rayon convolve | 3 days | 4–8× | Blur, sharpen |
| GPU blur compute | 1 week | 10–100× | 1024×1024+ |
| SIMD blend | 3 days | 2–4× | Compositing pipeline |
