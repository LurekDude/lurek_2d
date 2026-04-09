---
name: visual-effects
description: "Load this skill when implementing visual post-processing effects, image filters, or shader-based rendering techniques in Lurek2D: full-screen passes using canvas render-to-texture, custom WGSL fragment shaders for blur/bloom/distortion/colour grading, screen-space overlays, or multi-pass render pipelines. Use for: CRT scanlines, vignette, colour correction, bloom, distortion, pixelation, palette swap. Skip it for basic sprite/image drawing (use gpu-programming), or 3D-style rendering (out of scope for Lurek2D)."
---

# Visual Effects — Lurek2D

## Load When

- Adding a full-screen post-processing effect (bloom, blur, vignette, CRT, etc.)
- Writing a WGSL fragment shader to transform rendered output
- Building a multi-pass render pipeline: render scene → apply effect → present
- Implementing palette swaps, colour grading, or per-pixel image filters
- Combining multiple effects in a layered pipeline
- Optimising effects for integrated GPU (frame budget constraints)

## Owns

- Canvas render-to-texture as the post-processing substrate
- Custom WGSL fragment shader authoring patterns
- Multi-pass pipeline (scene → FX canvas → screen)
- Built-in shader auto-uniforms (`luna_Time`, `luna_ScreenSize`)
- Common effect recipes (blur, bloom, vignette, CRT, distortion)
- Performance budget for full-screen passes on integrated GPU
- CPU-side image filter via `lurek.img` (offline/load-time effects)

---

## How Post-Processing Works in Lurek2D

Lurek2D has no dedicated post-processing pipeline. Effects are implemented using the **canvas + custom shader** pattern:

```
1. Render the scene to a Canvas (off-screen texture)
2. Apply a custom shader that samples the Canvas as input
3. Draw the Canvas to the screen — the shader transforms each pixel
```

This single pattern covers every post-processing effect. Multi-pass effects chain multiple canvases.

---

## Single-Pass Effect

```lua
local sceneCanvas   -- off-screen render target
local effectShader  -- WGSL shader that reads from the canvas

function lurek.init()
    local w, h = lurek.window.getWidth(), lurek.window.getHeight()
    sceneCanvas = lurek.gfx.newCanvas(w, h)

    effectShader = lurek.gfx.newShader([[
        @group(0) @binding(0) var tex: texture_2d<f32>;
        @group(0) @binding(1) var smp: sampler;

        @fragment
        fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
            let colour = textureSample(tex, smp, uv);

            // Example: vignette
            let center = uv - vec2<f32>(0.5, 0.5);
            let dist   = length(center);
            let vignette = 1.0 - smoothstep(0.4, 0.8, dist);

            return vec4<f32>(colour.rgb * vignette, colour.a);
        }
    ]])
end

function lurek.render()
    -- Phase 1: render scene to canvas
    lurek.gfx.setCanvas(sceneCanvas)
    lurek.gfx.clear()
    drawScene()           -- all normal draw calls go here
    lurek.gfx.setCanvas(nil)

    -- Phase 2: draw canvas through effect shader
    lurek.gfx.setShader(effectShader)
    lurek.gfx.draw(sceneCanvas, 0, 0)
    lurek.gfx.setShader(nil)
end
```

---

## Built-In Shader Auto-Uniforms

These variables are automatically updated every frame — no manual upload needed:

| WGSL name | Type | Value |
|-----------|------|-------|
| `luna_Time` | `f32` | Elapsed time in seconds |
| `luna_ScreenSize` | `vec2<f32>` | Window width × height in pixels |

```wgsl
// Access in any custom fragment shader:
@group(0) @binding(2) var<uniform> luna_Time: f32;
@group(0) @binding(3) var<uniform> luna_ScreenSize: vec2<f32>;
```

---

## Effect Recipes

### Greyscale / Desaturate

```wgsl
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let c = textureSample(tex, smp, uv);
    let grey = dot(c.rgb, vec3<f32>(0.299, 0.587, 0.114));
    let amount = 0.8;  -- 0 = full colour, 1 = full grey
    return vec4<f32>(mix(c.rgb, vec3<f32>(grey), amount), c.a);
}
```

### CRT Scanlines

```wgsl
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let c    = textureSample(tex, smp, uv);
    let line = floor(uv.y * luna_ScreenSize.y) % 2.0;
    let scan = mix(1.0, 0.75, line);   -- darken every other row
    return vec4<f32>(c.rgb * scan, c.a);
}
```

### Animated Wave Distortion

```wgsl
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let offset = sin(uv.y * 30.0 + luna_Time * 3.0) * 0.005;
    let distorted = vec2<f32>(uv.x + offset, uv.y);
    return textureSample(tex, smp, distorted);
}
```

### Pixelation

```wgsl
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    let pixel_size = vec2<f32>(4.0, 4.0) / luna_ScreenSize;
    let snapped    = floor(uv / pixel_size) * pixel_size;
    return textureSample(tex, smp, snapped);
}
```

### Colour Correction (Brightness / Contrast / Saturation)

```wgsl
@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    var c = textureSample(tex, smp, uv);

    // Brightness
    c = vec4<f32>(c.rgb + 0.05, c.a);

    // Contrast
    c = vec4<f32>((c.rgb - 0.5) * 1.2 + 0.5, c.a);

    // Saturation
    let lum = dot(c.rgb, vec3<f32>(0.299, 0.587, 0.114));
    c = vec4<f32>(mix(vec3<f32>(lum), c.rgb, 1.3), c.a);

    return clamp(c, vec4<f32>(0.0), vec4<f32>(1.0));
}
```

---

## Multi-Pass Pipeline

Chain effects by using multiple canvases as intermediate render targets:

```lua
local sceneCanvas, blurH, blurV  -- three render targets

function lurek.init()
    local w, h = lurek.window.getWidth(), lurek.window.getHeight()
    sceneCanvas = lurek.gfx.newCanvas(w, h)
    blurH       = lurek.gfx.newCanvas(w, h)
    blurV       = lurek.gfx.newCanvas(w, h)
    blurHShader = lurek.gfx.newShader(BLUR_H_WGSL)
    blurVShader = lurek.gfx.newShader(BLUR_V_WGSL)
end

function lurek.render()
    -- Pass 1: scene → sceneCanvas
    lurek.gfx.setCanvas(sceneCanvas) ; drawScene() ; lurek.gfx.setCanvas(nil)

    -- Pass 2: horizontal blur
    lurek.gfx.setCanvas(blurH)
    lurek.gfx.setShader(blurHShader)
    lurek.gfx.draw(sceneCanvas, 0, 0)
    lurek.gfx.setCanvas(nil) ; lurek.gfx.setShader(nil)

    -- Pass 3: vertical blur → screen
    lurek.gfx.setShader(blurVShader)
    lurek.gfx.draw(blurH, 0, 0)
    lurek.gfx.setShader(nil)
end
```

---

## CPU-Side Image Filters (Offline / Load-Time)

For effects that only need to run once (level load, asset generation):

```lua
-- Load image into CPU buffer
local imgData = lurek.img.newImageData("tiles.png")

-- Apply pixel-level filter
imgData:mapPixel(function(x, y, r, g, b, a)
    -- Palette swap: replace specific colour
    if r > 0.9 and g < 0.1 and b < 0.1 then
        return 0.1, 0.1, 0.9, a   -- red → blue
    end
    return r, g, b, a
end)

-- Upload to GPU
local img = lurek.gfx.newImage(imgData)
```

---

## Performance Budget

Full-screen shader passes are expensive on integrated GPUs. Target: **≤ 2ms total** for all FX passes per frame.

| Effect type | Cost (1080p, Intel UHD) | Notes |
|-------------|------------------------|-------|
| Simple colour math (vignette, greyscale) | ~0.3ms | Safe |
| Texture sample + math (CRT, distortion) | ~0.5ms | Safe |
| Box blur 5×5 | ~1.2ms | Acceptable |
| Gaussian blur 13-tap | ~2.5ms | Tight — consider half-res |
| 3+ chained passes | > 3ms | Risky — profile before shipping |

**Rule**: Halve the canvas resolution for effects that don't need pixel-level precision (bloom, blur). Draw final composite at full resolution:

```lua
-- Half-resolution bloom canvas
local bloomCanvas = lurek.gfx.newCanvas(w // 2, h // 2)
```
