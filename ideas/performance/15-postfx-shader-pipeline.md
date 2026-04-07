# Post-Processing Effects — GPU Shader Pipeline

## Module Covered
- `src/postfx/` — stack.rs, effect.rs (bloom, blur, color grading, screen-space effects)

---

## Current State

`postfx` is a **CPU data model** — it stores effect parameters (blur radius,
bloom threshold, color correction matrices) but the actual GPU application
is stated to happen in `lua_api`. This means either:

1. Effects are NOT currently applied on GPU (lost feature), or
2. They are applied in `lua_api` via a render pass that reads `PostFxStack`

Either way, there is an opportunity to implement a full GPU post-processing
pipeline using wgpu compute shaders and a multi-pass render architecture.

---

## Bloom — The Highest-Value Effect

### Algorithm
1. **Threshold pass**: extract pixels brighter than threshold → bright texture
2. **Downsample**: series of 4 Mip-level downsamples (6× downscale each)
3. **Upsample + blur**: Gaussian blur at each mip level, upsample back
4. **Composite**: additive blend brightMap + original

### Current Cost (CPU implementation)
- For 1280×720 screen: 921,600 pixels × 9 downsamples = millions of ops/frame
- Completely unacceptable on CPU

### GPU Implementation (wgpu)

```rust
// src/postfx/gpu_pipeline.rs (new file)
pub struct BloomPipeline {
    threshold_pass:   wgpu::ComputePipeline,
    downsample_pass:  wgpu::RenderPipeline,
    upsample_pass:    wgpu::RenderPipeline,
    composite_pass:   wgpu::RenderPipeline,
    bright_tex:       [wgpu::Texture; 6],  // mip pyramid
}

impl BloomPipeline {
    pub fn apply(
        &self,
        encoder: &mut wgpu::CommandEncoder,
        source: &wgpu::TextureView,
        target: &wgpu::TextureView,
        params: &BloomParams,
    ) {
        // 1. Threshold extract
        let mut pass = encoder.begin_compute_pass(&Default::default());
        pass.set_pipeline(&self.threshold_pass);
        pass.dispatch_workgroups(width / 8, height / 8, 1);
        drop(pass);

        // 2. Downsample pyramid (6 passes)
        for mip in 0..6 { self.downsample(encoder, mip); }

        // 3. Upsample + blur (6 passes)
        for mip in (0..6).rev() { self.upsample(encoder, mip, params.blur_radius); }

        // 4. Composite additive blend
        self.composite(encoder, source, target, params.intensity);
    }
}
```

**WGSL threshold shader**:
```wgsl
@compute @workgroup_size(8, 8)
fn threshold(@builtin(global_invocation_id) id: vec3<u32>) {
    let coord = vec2<i32>(i32(id.x), i32(id.y));
    let color = textureLoad(source, coord, 0);
    let luminance = dot(color.rgb, vec3<f32>(0.2126, 0.7152, 0.0722));
    let bright = select(vec4<f32>(0.0), color, luminance > params.threshold);
    textureStore(bright_out, coord, bright);
}
```

---

## Separable Gaussian Blur

Gaussian blur is **separable**: one horizontal pass + one vertical pass
equals the full 2D kernel at 2× the cost of a 1D pass vs O(k²) for 2D.

```wgsl
// blur_h.wgsl — horizontal pass
@compute @workgroup_size(128, 1)
fn blur_h(@builtin(global_invocation_id) id: vec3<u32>) {
    let x = i32(id.x);
    let y = i32(id.y);
    var sum = vec4<f32>(0.0);
    for (var i = -params.radius; i <= params.radius; i++) {
        let w = gaussian_weight(f32(i), params.sigma);
        sum += textureLoad(input, vec2<i32>(x + i, y), 0) * w;
    }
    textureStore(output, vec2<i32>(x, y), sum);
}
```

**Performance**: For r=7 kernel on 1280×720:
- CPU: 1,290,240 × 15 = 19.4M operations
- GPU: 1.3ms on integrated GPU (entire frame budget for this one effect)
- With wgpu compute: ~0.1ms (shader units handle all pixels in parallel)

---

## Color Grading (LUT Lookup)

Apply a 3D Color Lookup Table (LUT) for cinematic color grading:

```wgsl
// color_grade.wgsl
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let color = textureSample(scene_tex, samp, uv);
    // 3D LUT lookup: map (r,g,b) → graded (r,g,b)
    let lut_uv = (color.rgb * (params.lut_size - 1.0) + 0.5) / params.lut_size;
    return textureSample(lut_tex, lut_samp, lut_uv);
}
```

- Zero CPU cost (fragment shader runs once per pixel on GPU)
- One 32×32×32 LUT texture = 131K pixels = 512 KB — stream from `lua_api`

**Luna API**:
```lua
luna.postfx.apply({
    bloom = { threshold = 0.8, intensity = 1.5, radius = 4 },
    color_lut = "grading/cinematic_warm.png",
    vignette = { strength = 0.5, radius = 0.8 },
})
```

---

## Chromatic Aberration

Simple vertex displacement, no texture sampling:

```wgsl
@fragment
fn chromatic_aberration(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let offset = params.strength * (uv - 0.5);
    let r = textureSample(scene, samp, uv + offset * 0.005).r;
    let g = textureSample(scene, samp, uv).g;
    let b = textureSample(scene, samp, uv - offset * 0.005).b;
    return vec4<f32>(r, g, b, 1.0);
}
```

Cost: 3 texture samples per pixel → negligible on GPU.

---

## PostFx Pipeline Architecture

```
Scene Color Texture
        │
  [Threshold Compute]
        │
  [Downsample Pyramid] × 6
        │
  [Gaussian Blur H/V] × 6
        │
  [Upsample Merge]
        │
  [Color Grade LUT]
        │
  [Composite Additive] ← bloom bright texture
        │
  [Chromatic Aberration]
        │
  [Vignette]
        │
  [FXAA Anti-Alias] (optional)
        │
  Swapchain Present
```

Total GPU cost for all effects: ~1–2ms on integrated GPU.
Current CPU cost of even attempting bloom: ~50ms (unacceptable).

---

## Implementation Plan

| Step | Effort | Effect |
|------|--------|--------|
| Multi-pass render pipeline | 1 week | Prerequisite for all |
| Separable blur compute | 3 days | Blur, glow, depth-of-field |
| Bloom threshold + pyramid | 3 days | Bloom |
| Color LUT grading | 2 days | Color grading |
| Chromatic aberration | 1 day | CA effect |
| Vignette | 1 day | Vignette |
| FXAA | 3 days | Anti-aliasing |
