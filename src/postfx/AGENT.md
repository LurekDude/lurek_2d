# `postfx` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 |
| **Status** | Implemented — Full |
| **Lua API** | `luna.postfx` |
| **Source** | `src/postfx/` |
| **Rust Tests** | *(none — logic covered by Lua tests)* |
| **Lua Tests** | `tests/lua/unit/test_image_effect.lua` (47 assertions) |

## Summary

The `postfx` module provides a two-track post-processing system:

1. **Full-screen effects** via `PostFxStack` — captures the entire rendered
   frame into an off-screen texture, applies a chain of effects, and composites
   the result back onto the swapchain.

2. **Per-image effects** via `ImageEffect` — binds an ordered effect chain to
   a single drawable image at draw time, processed before the image is
   composited into the scene.

Both tracks share the same 15 built-in effect types and parameter model.

## Built-in Effect Types

| Name | `PostFxEffectType` variant | Key parameters |
|---|---|---|
| `bloom` | `Bloom` | `threshold`, `intensity` |
| `blur` | `Blur` | `radius` |
| `crt` | `Crt` | `scanline_strength`, `curvature` |
| `godrays` | `Godrays` | `intensity`, `decay` |
| `vignette` | `Vignette` | `strength`, `radius` |
| `colourgrade` | `ColourGrade` | `brightness`, `contrast`, `saturation` |
| `chromatic` | `ChromaticAberration` | `offset` |
| `pixelate` | `Pixelate` | `size` |
| `sepia` | `Sepia` | — |
| `grayscale` | `Grayscale` | — |
| `invert` | `Invert` | — |
| `scanlines` | `Scanlines` | `scanline_strength` |
| `edgedetect` | `EdgeDetect` | `strength` |
| `hueshift` | `HueShift` | `angle` |
| `noise` | `Noise` | `strength` |

## Key Types

| Type | Role |
|---|---|
| `PostFxEffect` | A single effect instance with enabled flag and parameter map |
| `PostFxEffectType` | Enum of the 15 valid effect names; provides `from_name` and `type_name` |
| `PostFxStack` | Full-screen capture pipeline: `beginCapture → draw scene → endCapture → apply` |
| `ImageEffect` | Ordered chain of `Rc<RefCell<PostFxEffect>>` for per-image application |
| `ImageEffectPass` | Lightweight Tier-1 data struct used inside `DrawCommand` variants |

## Lua API Summary

```lua
-- Per-image effects
local fx = luna.postfx.newImageEffect()                   -- empty chain
local fx = luna.postfx.newImageEffect("blur")             -- single effect
local fx = luna.postfx.newImageEffect("blur", {radius=4}) -- effect with params
local fx = luna.postfx.newImageEffect({"blur","bloom"})   -- chain
local fx = luna.postfx.loadImageEffect("effects/warm.toml")

local effect = fx:addEffect("blur")    -- returns PostFxEffect, shared reference
local effect = fx:getEffect(1)         -- by 1-based index
local effect = fx:getEffect("blur")    -- by type name (first match)
local count  = fx:effectCount()
fx:removeEffect(1)                     -- by index
fx:removeEffect("blur")               -- by type name
fx:clearEffects()
local copy   = fx:clone()
fx:save("effects/warm.toml")          -- relative paths only; no path traversal

-- Apply at draw time
luna.graphics.draw(img, {x=100, y=200, effect=fx})

-- Full-screen stack
local stack = luna.postfx.newStack()
local e     = luna.postfx.newEffect("bloom")
stack:add(e)
stack:beginCapture()
  -- draw scene here
stack:endCapture()
stack:apply()

-- Effect parameter control
effect:setParameter("radius", 6.0)
effect:getParameter("radius")    -- returns float
effect:setEnabled(true)
effect:isEnabled()               -- returns bool
effect:getType()                 -- returns string, e.g. "blur"
-- Convenience setters (also validate is_finite)
effect:setRadius(6)
effect:setIntensity(1.2)
effect:setThreshold(0.8)
effect:setScanlineStrength(0.5)
effect:setStrength(0.7)
effect:setOffset(2)
effect:setBrightness(1.0)
effect:setContrast(1.1)
effect:setSaturation(0.9)
```

## TOML Effect Preset Format

```toml
name = "warm_glow"

[[effects]]
type    = "bloom"
enabled = true

[effects.params]
threshold = 0.6
intensity = 1.4

[[effects]]
type    = "vignette"
enabled = true

[effects.params]
strength = 0.4
```

## Architecture

```
ImageEffect (Tier 2 — src/postfx/image_effect.rs)
  └── effects: Vec<Rc<RefCell<PostFxEffect>>>
        │  shared with LuaPostFxEffect handles
        ▼
  to_passes() → Vec<ImageEffectPass>  (Tier 1 data)
        │
        ▼  placed in DrawCommand::DrawImage { effect: Option<Vec<ImageEffectPass>>, ... }
        │
        ▼  GPU renderer applies passes during rendering
```

## Security Notes

- `save()` and `loadImageEffect()` block `..`, absolute paths, and prefix components to prevent path traversal outside the game directory.
- All float parameters (both `setParameter` and the 9 convenience setters) validate `is_finite()` at the Lua boundary — `inf` and `NaN` are rejected with a descriptive error.
