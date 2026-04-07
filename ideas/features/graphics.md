# graphics — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/graphics.md`
**Files**: 18 source files

## Purpose

2D rendering via wgpu: draw commands, sprites, fonts, canvases, shaders, blend modes, transforms, sprite batches, texture atlases, nine-slice, compound shapes.

## Current Feature Summary

- 45+ `DrawCommand` variants queued during `luna.draw()`, processed by GPU renderer after callback returns
- 7 UserData types: LuaImage, LuaFont, LuaCanvas, LuaSpriteBatch, LuaShader, LuaMesh, LuaSpriteSheet
- 66+ Lua API functions across drawing, text, transforms, canvases, shaders
- Sprite sheets with animation frame extraction
- Texture atlas support (runtime-built from images)
- Nine-slice scaling for UI panels
- Custom WGSL shaders with uniform passing
- Canvas render-to-texture
- Transform stack (push/pop/translate/rotate/scale)
- Text rendering with alignment, wrapping, and per-glyph measurement

## Feature Gaps

1. **No texture atlas import from JSON/XML**: Can build atlases at runtime but can't load TexturePacker/Aseprite `.json` descriptors. This is table stakes for production sprite workflows.
2. **No gradient fills**: No linear/radial gradient. Competitors (Bevy, Solar2D) support gradients. Useful for backgrounds, health bars, UI.
3. **No rich text**: Can't mix fonts, colors, or sizes within a single text block. Common need for dialogue, damage numbers, UI text.
4. **No render layers/groups**: No way to assign draw calls to named layers with independent sort order. Must manage draw order manually.
5. **No instanced rendering**: Drawing 1000 identical sprites requires 1000 draw calls. Instancing would batch these on the GPU.
6. **No anti-aliased lines/shapes**: Shapes are rasterized without AA. Love2D has smooth line rendering.
7. **No SVG rendering**: Cannot render SVG files (useful for resolution-independent UI).
8. **No screenshot-to-ImageData**: `saveScreenshot` writes to file; no way to capture frame into CPU-accessible ImageData for processing.
9. **No stencil operations**: No stencil buffer control (masking, clipping to arbitrary shapes).

## Structural Issues

- **Module is too large** (18 files, 66+ Lua functions, 45+ DrawCommand variants). This is the largest module in the engine. Consider splitting:
  - `graphics/core` — renderer, draw commands, color, blend modes
  - `graphics/text` — font loading, text layout, alignment, wrapping
  - `graphics/sprite` — sprite sheets, sprite batches, texture atlases
  - `graphics/shape` — compound shapes, nine-slice, mesh
  - `graphics/shader` — custom WGSL shaders, uniforms
- **Orphaned `color.rs`**: Color type is in both `math` (Color struct) and `graphics` (color utilities). Clarify ownership.
- **Scene module's DepthSorter**: Drawing depth sorting is a graphics concern but lives in `scene`. Should be in graphics.

## Suggestions

1. **Add TextureAtlas JSON/XML import**: `luna.graphics.newAtlasFromFile(image, json_path)` — parse TexturePacker/Aseprite format. Critical for production art pipelines.
2. **Add render layers**: `luna.graphics.setLayer(name_or_index)` — assign draw calls to layers, each with independent sort and visibility. Many 2D games need "background", "entities", "UI" layers.
3. **Add gradient primitives**: `luna.graphics.drawGradientRect(x, y, w, h, color1, color2, direction)` — simple but high impact for visual polish.
4. **Add rich text**: `luna.graphics.drawRichText(markup, x, y)` — parse `[color=#ff0000]red text[/color]` or similar markup. Bevy and Solar2D both have this.
5. **Split the module**: The 18-file, 66-function surface is large enough to warrant sub-modules. Even just extracting `text` and `sprite` would reduce cognitive load.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Draw command queue | ✅ | ❌ (immediate) | ❌ (scene graph) | ✅ (batched) |
| Sprite batch | ✅ | ✅ | ❌ | ✅ |
| Texture atlas | ✅ (runtime) | ❌ | ✅ (import) | ✅ (import) |
| Custom shaders | ✅ (WGSL) | ✅ (GLSL) | ❌ | ✅ (WGSL) |
| Canvas/RT | ✅ | ✅ | ✅ | ✅ |
| Gradient fills | ❌ | ❌ | ✅ | ✅ |
| Rich text | ❌ | ❌ | ❌ | ✅ |
| Render layers | ❌ | ❌ | ✅ (groups) | ✅ |
| Anti-alias lines | ❌ | ✅ | ✅ | ❌ |

## Priority

**HIGH** — Graphics is the most-used module. Texture atlas import, render layers, and gradients are impactful. Module splitting is a structural health concern.
