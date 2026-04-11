# `render` — Agent Reference

| Property       | Value                                                        |
|----------------|--------------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                              |
| **Status**     | Implemented — Full                                           |
| **Lua API**    | `lurek.graphic`                                          |
| **Source**     | `src/render/`                                            |
| **Rust Tests** | `tests/rust/unit/graphics_tests.rs`, `tests/rust/ext/graphics_ext_tests.rs`, `tests/rust/ext/graphics_runtime_smoke_tests.rs` |
| **Lua Tests**  | `tests/lua/unit/test_graphics.lua`                           |
| **Architecture** | `docs/architecture/engine-architecture.md` § Rendering Pipeline |

## Purpose

The graphics module owns the entire GPU rendering pipeline for Lurek2D — from the high-level draw calls that Lua scripts issue through `lurek.graphic.*`, through a deferred `RenderCommand` queue that batches all rendering work, to the wgpu GPU backend that executes those commands against the swapchain. No other module writes pixels to the screen; everything visual flows through this module.

## Source Files

| File               | Purpose                                                              |
|--------------------|----------------------------------------------------------------------|
| `canvas.rs`        | Off-screen render target metadata (`Canvas` struct with width/height) |
| `color.rs`         | Orphaned `Color` struct — not declared in `mod.rs`; active `Color` lives in `src/math/color.rs` |
| `decal_surface.rs` | Persistent surface descriptor for stamping decal textures            |
| `draw_layer.rs`    | Z-ordered draw callback queue for controlling render order           |
| `font.rs`          | TTF/OTF font loading via fontdue, glyph rasterization, shelf-packed RGBA atlas |
| `gpu_renderer.rs`  | GPU-accelerated 2D renderer backed by wgpu; processes RenderCommand queue, manages GPU resources and render passes |
| `image_effect.rs`  | Per-image shader-effect pass descriptor for the draw command pipeline |
| `mesh.rs`          | Custom geometry mesh with per-vertex position, UV, and color data    |
| `nine_slice.rs`    | Nine-slice (9-patch) image rendering for scalable UI elements        |
| `renderer.rs`      | `RenderCommand` enum (45+ variants), `BlendMode`, `DrawMode`, `TextAlign`, `StencilMode`, `TextureData`, and related types |
| `shader.rs`        | Custom WGSL shader support — source validation via naga, uniform variables, per-shader pipeline |
| `shape.rs`         | `CompoundShape` builder and `ShapeCommand` sub-enum for multi-primitive vector drawing |
| `sprite.rs`        | `Sprite` struct — texture handle + transform + tint color wrapper    |
| `sprite_batch.rs`  | Sprite batching for efficient rendering of many sprites sharing one texture |
| `sprite_sheet.rs`  | Grid-based sprite sheet with directional support and named frame groups |
| `texture.rs`       | Texture loading (PNG/JPEG/BMP), premultiplied-alpha conversion, and `TextureKey` handle |
| `texture_atlas.rs` | CPU-side bin-packing texture atlas using shelf algorithm              |
| _(camera submodule)_ | | |
| `camera/mod.rs`       | Camera and viewport submodule root; re-exports `Camera`, `Camera2D`, `Viewport`, `ViewportScale`, `ScaleMode` |
| `camera/types.rs`     | `Camera` (flat `setCamera()` API) and `Camera2D` (smooth follow, dead zone, bounds clamping, screen-shake) |
| `camera/viewport.rs`  | Virtual-resolution viewport mapping onto window using letterboxing, stretching, or pixel-perfect scaling |
| `camera/viewport_scale.rs` | Like `Viewport` but also tracks scaled content dimensions for automatic graphics transform-stack integration |
| _(effect submodule)_ | | |
| `effect/mod.rs`       | Composable visual effects submodule root; two families: post-processing (image-space) and screen overlays (world-simulation) |
| `effect/ambient.rs`   | `AmbientState` — ambient lighting with time-of-day colour cycling driven by an in-game clock |
| `effect/atmosphere.rs` | Data-only structs for clouds, fog, vignette, lightning, film grain, and heat haze overlays |
| `effect/effect.rs`    | `PostFxEffect` — single named post-processing effect with a `HashMap<String,f32>` parameter bag |
| `effect/effect_type.rs` | `PostFxEffectType` enum of all built-in effect kinds (Bloom, Blur, Crt, Godrays, Custom, …) with default parameter presets |
| `effect/image_effect.rs` | `ImageEffect` — ordered `PostFxEffect` chain for per-image draw calls; distinct from root-level `image_effect.rs` ShaderPassDescriptor |
| `effect/overlay.rs`   | `Overlay` — composable per-frame overlay aggregating ambient, atmospheric, weather, and screen-effect subsystems |
| `effect/screen_effects.rs` | `FlashState`, `FadeState`, `ShakeState` — brief full-screen transient visual feedback effects |
| `effect/stack.rs`     | `PostFxStack` — ordered capture-and-apply chain of post-processing passes processed via ping-pong canvases |
| `effect/weather.rs`   | `WeatherType`, `WeatherParticle`, `WeatherState` — rain, snow, dust, hail, and leaf particle overlay data |
| _(light submodule)_ | | |
| `light/mod.rs`        | 2D point-light submodule root; re-exports `Light2D`, enums, `Occluder`, `LightWorld` |
| `light/attenuation.rs` | `Attenuation` — constant/linear/quadratic coefficients for custom light distance falloff curves |
| `light/blend_mode.rs` | `LightBlendMode` enum controlling how light colour mixes with the scene (Add, Sub, Mix) |
| `light/falloff.rs`    | `FalloffMode` enum controlling how light intensity decays over distance (Linear, Smooth, Constant) |
| `light/flicker.rs`    | `FlickerConfig` — built-in sinusoidal intensity-flicker effect for lights |
| `light/light2d.rs`    | `Light2D` — 2D point light data container (position, radius, color, intensity, enabled flag) |
| `light/light_type.rs` | `LightType` enum for point, directional, and spot light geometry |
| `light/light_world.rs` | `LightWorld` — `SlotMap`-backed resource pool and state for the 2D lighting system |
| `light/occluder.rs`   | `Occluder` — polygon shadow caster that blocks light from point lights |
| `light/shadow.rs`     | `ShadowFilter` enum for shadow-boundary edge quality (None, Pcf5, Pcf13) |

## Key Types

| Type | Description |
|------|-------------|
| `Canvas` | Principal type for the `graphics` module. |
| `Color` | Principal type for the `graphics` module. |
| `DecalSurface` | Principal type for the `graphics` module. |
| `LayerEntry` | Principal type for the `graphics` module. |
| `DrawLayer` | Principal type for the `graphics` module. |
| `Font` | Principal type for the `graphics` module. |
| `GlyphInfo` | Principal type for the `graphics` module. |
| `RenderStats` | Principal type for the `graphics` module. |
| `GpuRenderer` | Principal type for the `graphics` module. |
| `ShaderPassDescriptor` | Principal type for the `graphics` module. |
| `MeshDrawMode` | Principal type for the `graphics` module. |
| `MeshVertex` | Principal type for the `graphics` module. |

## Lua API Summary

_No `lurek.*` bindings registered for this module._

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/graphics.md`](../../docs/specs/graphics.md)

_Update both this file **and** `docs/specs/graphics.md` whenever source files, public types, or Lua bindings change._
