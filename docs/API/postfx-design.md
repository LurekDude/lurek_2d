# postfx — Post-Processing Effects Module

> **Lua namespace:** `luna.postfx`
> **Rust module:** `src/postfx/`
> **Purpose:** Provides a stackable post-processing pipeline with built-in effects (bloom, blur, CRT, godrays, vignette, colour grading, chromatic aberration) and support for custom shader passes. Effects are organized into a Stack that captures the scene, applies all enabled effects in order, and draws the final result.

## Architecture Notes

- The pipeline is: `beginCapture()` → draw your scene → `endCapture()` → `apply()` draws final result
- Stack manages two ping-pong canvases internally for multi-pass rendering
- Built-in effects carry embedded GLSL shader source compiled lazily on first use
- Custom passes wrap a user-provided `luna.graphics.Shader` — the stack handles the canvas ping-pong
- Effects are parameterized by named float values accessed via `setParameter(name, value)`
- Convenience setters (setThreshold, setIntensity, etc.) are just wrappers around `setParameter`
- Multi-pass effects (e.g., two-pass Gaussian blur) are handled internally by the Effect
- Effect insertion order determines application order — effects at position 1 run first
- Each effect can be individually enabled/disabled within the stack without removing it
- Stack `getEffect()` uses 1-based indexing

## Dependencies

- `luna.graphics` (Canvas creation, Shader compilation, rendering)

## Implementation Status

- **Tier**: Tier 1 — Basic Core
- **Rust**: `src/postfx/mod.rs` — fully implemented
- **Lua bindings**: `src/lua_api/postfx_api.rs` — fully implemented
- **Example**: `examples/postfx_demo/main.lua`

---

## Module Functions

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `newStack` | `width?: int, height?: int` | `Stack` | Create a new effect stack. Defaults to `luna.graphics.getDimensions()` |
| `newEffect` | `name: string` | `Effect` | Create a built-in effect by name (see EffectType enum) |
| `newPass` | `shader: Shader` | `Effect` | Create a custom pass wrapping a luna.graphics Shader |

---

## Type: Effect

A single post-processing effect with named float parameters.

**Created by:** `luna.postfx.newEffect(name)` or `luna.postfx.newPass(shader)`

### General Methods

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `setParameter` | `name: string, value: number` | — | Set a named float parameter |
| `getParameter` | `name: string, default?: number` | `number` | Get a parameter value (default 0.0 if not set) |
| `hasParameter` | `name: string` | `boolean` | Check if a parameter exists |
| `getParameterNames` | — | `table<string>` | List all parameter names |
| `getType` | — | `string` | Get effect type name (e.g., `"bloom"`, `"custom"`) |
| `isBuiltIn` | — | `boolean` | True if this is a built-in effect (not custom) |

### Convenience Setters

These are shortcuts for common parameters — equivalent to `setParameter(name, value)`:

| Method | Parameters | Description |
|---|---|---|
| `setThreshold` | `value: number` | Set bloom bright-pass threshold |
| `setIntensity` | `value: number` | Set bloom/godrays intensity |
| `setScanlineStrength` | `value: number` | Set CRT scanline visibility |
| `setRadius` | `value: number` | Set blur radius |
| `setStrength` | `value: number` | Set vignette/blur strength |
| `setOffset` | `value: number` | Set chromatic aberration offset |

---

## Type: Stack

An ordered chain of effects that captures and processes the rendered scene.

**Created by:** `luna.postfx.newStack(width?, height?)`

### Effect Management

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `add` | `effect: Effect` | — | Append an effect to the end of the chain |
| `remove` | `effect: Effect` | `boolean` | Remove an effect from the chain. Returns true if found |
| `insert` | `position: int, effect: Effect` | — | Insert an effect at a specific position (1-based) |
| `setEnabled` | `effect: Effect, enabled: boolean` | — | Enable/disable a specific effect in the chain |
| `isEnabled` | `effect: Effect` | `boolean` | Check if an effect is enabled |
| `getEffectCount` | — | `int` | Number of effects in the chain |
| `getEffect` | `index: int` | `Effect \| nil` | Get effect at 1-based index |

### Render Pipeline

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `beginCapture` | — | — | Start capturing scene drawing to the stack's source canvas |
| `endCapture` | — | — | Stop capturing and finalize the source frame |
| `apply` | — | — | Apply all enabled effects in order and draw the final result to screen |

### Dimensions

| Method | Parameters | Returns | Description |
|---|---|---|---|
| `resize` | `width, height` | — | Recreate internal canvases at a new resolution |
| `getWidth` | — | `int` | Get canvas width |
| `getHeight` | — | `int` | Get canvas height |
| `getDimensions` | — | `int, int` | Get both canvas dimensions |

---

## Enums

### EffectType

Built-in effect names passed to `luna.postfx.newEffect(name)`:

| Value | String | Description |
|---|---|---|
| 0 | `"bloom"` | HDR bloom with threshold + intensity parameters |
| 1 | `"blur"` | Gaussian blur with radius parameter |
| 2 | `"crt"` | CRT monitor simulation with scanline strength |
| 3 | `"godrays"` | Light ray/god ray effect with intensity |
| 4 | `"vignette"` | Screen edge darkening with strength |
| 5 | `"colourgrade"` | Color grading / tone mapping |
| 6 | `"chromatic"` | Chromatic aberration with offset |
| 7 | `"custom"` | Custom shader pass (created via `newPass()`) |

---

## Usage Example

```lua
local stack, bloom, blur

function luna.load()
    stack = luna.postfx.newStack()
    bloom = luna.postfx.newEffect("bloom")
    bloom:setThreshold(0.6)
    bloom:setIntensity(1.2)

    blur = luna.postfx.newEffect("blur")
    blur:setRadius(2.0)

    stack:add(bloom)
    stack:add(blur)
    stack:setEnabled(blur, false)  -- blur off by default
end

function luna.draw()
    stack:beginCapture()
        -- Draw your entire scene here
        luna.graphics.circle("fill", 400, 300, 100)
    stack:endCapture()

    stack:apply()  -- renders final post-processed result
end

function luna.resize(w, h)
    stack:resize(w, h)
end

-- Toggle blur with a key
function luna.keypressed(key)
    if key == "b" then
        stack:setEnabled(blur, not stack:isEnabled(blur))
    end
end
```

---

## Game Design Role

- **Visual polish**: Bloom for lights, blur for depth, CRT for retro feel — without manual canvas management.
- **Screen-space effects**: God-rays, chromatic aberration, vignette — full-screen, frame-consistent.
- **Dynamic enable/disable**: Toggle effects at runtime (quality settings, pause screen, cutscenes).
- **Effect parameters**: Each pass exposes named uniform setters (`bloom:setThreshold(0.8)`).
- **Ordered blending**: Effects compose in declared order; order matters for quality.

---

## Module Boundaries

**vs luna.graphics (Canvas + Shader)** — Graphics draws scenes and supports canvases/shaders manually. PostFX wraps that setup into an ordered pipeline with ping-pong management and built-in effects. Use postfx for full-screen pipelines; graphics for per-object shading.

**vs luna.graphics (Light2D)** — Light2D is a scene-space 2D lighting layer. PostFX god-rays are a screen-space approximation. Different quality/overhead trade-offs.

**vs luna.graphics (ParticleSystem)** — Particles are drawn as part of the scene before `endCapture()`. PostFX then processes the captured frame.

---

## Recipes & Workflows

- **Retro games**: CRT scanlines + colour grade for authentic pixel-art look
- **Horror games**: Desaturate + vignette on low health; chromatic aberration on hit
- **Magic effects**: Bloom on glowing items and light sources
- **Underwater scenes**: Blur + chromatic aberration + colour shift
- **Pause screen**: Blur the game world behind the pause overlay
- **Boss intro cutscene**: God-rays + vignette for dramatic lighting
