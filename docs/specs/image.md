# `image` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Platform Services |
| **Status** | Implemented |
| **Lua API** | `lurek.image` |
| **Source** | `src/image/` |
| **Rust Tests** | `tests/rust/unit/image_tests.rs`, `tests/rust/stress/image_stress_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_image.lua`, `tests/lua/unit/test_image_effect.lua`, `tests/lua/stress/test_image_stress.lua`, `tests/lua/evidence/test_evidence_image_drawing.lua`, `tests/lua/evidence/test_evidence_imagedata.lua`, `tests/lua/evidence/test_evidence_image_effects.lua`, `tests/lua/evidence/test_evidence_imagedata_effects.lua` |
| **Architecture** | `docs/architecture/engine-architecture.md § Platform Services` |

---

## Summary

The `image` module owns CPU-side image data and image manipulation. It gives the engine a place to load pixels from disk, construct images procedurally, inspect or edit pixels one by one, compose layered images, and serialize image data without requiring a live GPU resource.

This module exists so higher-level systems can work with pixels as ordinary Rust data. Animation tooling, procedural generation, screenshot export, asset preprocessing, and Lua scripts can all build or transform images here before those images are turned into renderable textures elsewhere. The `visualization` helpers also let Tier 1 modules expose debug or authoring images without importing GPU code.

The module intentionally does not own GPU upload, draw submission, swapchain behavior, or shader execution. It can describe data that the renderer will later consume, but actual rendering belongs to `render`, resource lifetime belongs to runtime state and resource keys, and window presentation belongs to `window`.

**Scope boundary**: This module currently depends on `animation`, `camera`, `math`, `render`, `runtime`. It stays within the Platform Services responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.image.* (Lua API — src/lua_api/image_api.rs)
    |
    v
src/image/mod.rs
    |- compressed.rs - compressed
    |- effects.rs - effects
    |- image_data.rs - image_data
    |- layers.rs - layers
    |- palette_lut.rs - palette_lut
    |- render.rs - render
    |- serial.rs - serial
    |- texture.rs - texture
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `compressed.rs` | Defines DDS-backed compressed image data for formats that should stay compressed until GPU upload. |
| `effects.rs` | Adds CPU image-processing operations onto `ImageData`, including tone changes, geometric transforms, blur, sharpen, and other filter-style edits. |
| `image_data.rs` | Defines `ImageData`, the core RGBA8 pixel buffer with load, encode, per-pixel access, drawing primitives, and bulk pixel transforms. |
| `layers.rs` | Defines layered image composition with named layers, visibility, opacity, ordering, and Porter-Duff style flattening. |
| `mod.rs` | Re-exports the module's public image types and groups the submodules into one CPU-side image surface. |
| `palette_lut.rs` | Stores source-to-target color mappings used for palette-swap style workflows. |
| `render.rs` | Converts `ImageData` into render-command descriptions without taking ownership of renderer internals. |
| `serial.rs` | Implements the `.lim` binary format for saving and loading flat and layered images. |
| `texture.rs` | Defines a lightweight texture handle and CPU-to-renderer texture creation helpers. |
| `texture_atlas.rs` | Packs named rectangular regions into a fixed atlas layout for sprite-sheet style use cases. |
| `visualization.rs` | Produces `ImageData` visualizations for other systems such as animation playback, camera debugging, noise, terrain, and easing curves. |

---

## Submodules

### `image::compressed`

Defines DDS-backed compressed image data for formats that should stay compressed until GPU upload.

- **`CompressedFormat`** (enum): GPU-compressed texture format identifier.
- **`CompressedImageData`** (struct): CPU-side holder for GPU-compressed texture data loaded from a DDS file.

### `image::effects`

Adds CPU image-processing operations onto `ImageData`, including tone changes, geometric transforms, blur, sharpen, and other filter-style edits.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `image::image_data`

Defines `ImageData`, the core RGBA8 pixel buffer with load, encode, per-pixel access, drawing primitives, and bulk pixel transforms.

- **`ImageData`** (struct): CPU-side pixel buffer in RGBA8 format.

### `image::layers`

Defines layered image composition with named layers, visibility, opacity, ordering, and Porter-Duff style flattening.

- **`ImageLayer`** (struct): A single compositing layer inside a [`LayeredImage`] stack.
- **`LayeredImage`** (struct): A compositing stack of [`ImageLayer`] values sharing the same canvas size.

### `image::palette_lut`

Stores source-to-target color mappings used for palette-swap style workflows.

- **`PaletteLUT`** (struct): Color palette lookup table mapping source colors to target colors.

### `image::render`

Converts `ImageData` into render-command descriptions without taking ownership of renderer internals.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `image::serial`

Implements the `.lim` binary format for saving and loading flat and layered images.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `image::texture`

Defines a lightweight texture handle and CPU-to-renderer texture creation helpers.

- **`Texture`** (struct): A loaded image asset referenced by its index into the renderer's texture list.

### `image::texture_atlas`

Packs named rectangular regions into a fixed atlas layout for sprite-sheet style use cases.

- **`AtlasRegion`** (struct): A named rectangular region packed into the atlas.
- **`TextureAtlas`** (struct): CPU-side bin-packing atlas for sprite regions.

### `image::visualization`

Produces `ImageData` visualizations for other systems such as animation playback, camera debugging, noise, terrain, and easing curves.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

---

## Key Types

### Public Types

#### `ImageData`

The main CPU image container.

#### `CompressedImageData`

Holds DDS payloads and mip data in compressed form so the engine can defer expansion and upload decisions to the renderer.

#### `CompressedFormat`

Identifies which GPU-compressed format a DDS asset uses and gives the Lua side a stable format name.

#### `PaletteLUT`

Describes palette remapping tables for effects that replace source colors with target colors.

#### `ImageLayer`

Represents a single named layer with visibility, opacity, and its own `ImageData` backing store.

#### `LayeredImage`

Owns an ordered stack of `ImageLayer` values and merges them into a flat image when callers need a composited result.

#### `Texture`

A lightweight texture handle and metadata wrapper used when CPU image data is inserted into renderer-owned texture storage.

#### `TextureAtlas`

Owns atlas dimensions and packed regions for named sub-images that share one backing texture.

#### `AtlasRegion`

Describes the packed rectangle for one atlas entry.# `image` — Agent Reference

---

## Lua API

Exposed under `lurek.image.*` by `src/lua_api/image_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.image.newImageData` | Creates a new blank ImageData or loads one from a file. |
| `lurek.image.newCompressedData` | Loads compressed texture data from a DDS file. |
| `lurek.image.isCompressed` | Returns true if the file at the given path is a DDS file. |
| `lurek.image.newLayeredImage` | Creates a new empty LayeredImage canvas with no layers. |
| `lurek.image.saveImage` | Saves a flat ImageData to a LIMG binary file at the given path. |
| `lurek.image.savePNG` | Saves a flat ImageData as a PNG file at the given path. |
| `lurek.image.loadImage` | Loads an ImageData from a LIMG binary file. |
| `lurek.image.loadLayered` | Loads a LayeredImage from a LIMG binary file. |

### `CompressedImageData` Methods

| Method | Description |
|--------|-------------|
| `compressedimagedata:getWidth(...)` | Returns the width of the base mip level in pixels. |
| `compressedimagedata:getHeight(...)` | Returns the height of the base mip level in pixels. |
| `compressedimagedata:getDimensions(...)` | Returns the width and height of the base mip level. |
| `compressedimagedata:getMipmapCount(...)` | Returns the number of mipmap levels stored. |
| `compressedimagedata:getFormat(...)` | Returns the compressed format name string. |

### `LayeredImage` Methods

| Method | Description |
|--------|-------------|
| `layeredimage:getWidth(...)` | Returns the canvas width shared by all layers. |
| `layeredimage:getHeight(...)` | Returns the canvas height shared by all layers. |
| `layeredimage:layerCount(...)` | Returns the number of layers in the stack. |
| `layeredimage:addLayer(...)` | Appends a new blank transparent layer on top and returns its 1-based index. |
| `layeredimage:removeLayer(...)` | Removes the layer at the given 1-based index. Returns true on success. |
| `layeredimage:getLayer(...)` | Returns a copy of the layer's pixel buffer as an ImageData. |
| `layeredimage:getOpacity(...)` | Returns the opacity of a layer in [0.0, 1.0]. |
| `layeredimage:setOpacity(...)` | Sets the opacity of a layer. Value is clamped to [0.0, 1.0]. |
| `layeredimage:isVisible(...)` | Returns whether a layer is visible. |
| `layeredimage:setVisible(...)` | Shows or hides a layer during compositing. |
| `layeredimage:getName(...)` | Returns the name of a layer. |
| `layeredimage:setName(...)` | Renames a layer. |
| `layeredimage:swapLayers(...)` | Swaps two layers by their 1-based indices, changing their compositing order. |
| `layeredimage:merge(...)` | Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing. |
| `layeredimage:save(...)` | Saves the layered image to a LIMG binary file at the given path. |

### `mlua` Methods

| Method | Description |
|--------|-------------|
| `mlua:getWidth(...)` | Lua-facing function documented in the binding source. |
| `mlua:getHeight(...)` | Lua-facing function documented in the binding source. |
| `mlua:getDimensions(...)` | Lua-facing function documented in the binding source. |
| `mlua:getPixel(...)` | Lua-facing function documented in the binding source. |
| `mlua:encode(...)` | Lua-facing function documented in the binding source. |
| `mlua:getString(...)` | Lua-facing function documented in the binding source. |
| `mlua:mapPixel(...)` | Lua-facing function documented in the binding source. |
| `mlua:brightness(...)` | Lua-facing function documented in the binding source. |
| `mlua:contrast(...)` | Lua-facing function documented in the binding source. |
| `mlua:saturation(...)` | Lua-facing function documented in the binding source. |
| `mlua:gamma(...)` | Lua-facing function documented in the binding source. |
| `mlua:grayscale(...)` | Lua-facing function documented in the binding source. |
| `mlua:sepia(...)` | Lua-facing function documented in the binding source. |
| `mlua:invert(...)` | Lua-facing function documented in the binding source. |
| `mlua:threshold(...)` | Lua-facing function documented in the binding source. |
| `mlua:posterize(...)` | Lua-facing function documented in the binding source. |
| `mlua:fill(...)` | Lua-facing function documented in the binding source. |
| `mlua:noise(...)` | Lua-facing function documented in the binding source. |
| `mlua:alphaMask(...)` | Lua-facing function documented in the binding source. |
| `mlua:flipHorizontal(...)` | Lua-facing function documented in the binding source. |
| `mlua:flipVertical(...)` | Lua-facing function documented in the binding source. |
| `mlua:rotate90cw(...)` | Lua-facing function documented in the binding source. |
| `mlua:crop(...)` | Lua-facing function documented in the binding source. |
| `mlua:resizeNearest(...)` | Lua-facing function documented in the binding source. |
| `mlua:blur(...)` | Lua-facing function documented in the binding source. |
| `mlua:sharpen(...)` | Lua-facing function documented in the binding source. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.image.
if lurek.image then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 8 |
| `enum` | 1 |
| `fn` (Lua API) | 54 |
| **Total** | **63** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `animation` | Imports or references `animation` from `src/animation/`. | Cross-group dependency from Platform Services to Feature Systems. |
| `camera` | Imports or references `camera` from `src/camera/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `math` | Imports or references `math` from `src/math/`. | Cross-group dependency from Platform Services to Foundations. |
| `render` | Imports or references `render` from `src/render/`. | Same responsibility group; allowed when the dependency graph stays acyclic. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Platform Services to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/image/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
