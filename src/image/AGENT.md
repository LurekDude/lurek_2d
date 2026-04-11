# `image` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.img`                                         |
| **Source**     | `src/image/`                                         |
| **Rust Tests** | `tests/rust/unit/image_tests.rs` (62 tests)          |
| **Lua Tests**  | `tests/lua/unit/test_image.lua`                      |
| **Architecture** | See `docs/specs/image.md` — 6 source files, 20 CPU effects, layer compositor, LIMG binary format |

## Purpose

The `image` module provides CPU-side pixel-level access to RGBA image data. It is the raw pixel layer that sits beneath the GPU texture pipeline — `ImageData` is never on the GPU until explicitly uploaded via the graphics API (`lurek.gfx.newImage(imgdata)`). The module covers four distinct concerns: uncompressed RGBA pixel buffers (`ImageData`), GPU-compressed DDS texture containers (`CompressedImageData`), a compositing layer stack (`LayeredImage`), LIMG binary serialization (`serial`), and colour palette lookup tables for shader-based palette swapping (`PaletteLUT`).

## Source Files

| File             | Purpose                                                                                       |
|------------------|-----------------------------------------------------------------------------------------------|
| `image_data.rs`  | CPU-side RGBA8 pixel buffer: per-pixel access, paste, map, PNG encode, `mlua::UserData` impl |
| `effects.rs`     | 20 image-processing effects: brightness, contrast, saturation, gamma, tint, grayscale, sepia, invert, threshold, posterize, fill, noise, alpha_mask, flip_horizontal, flip_vertical, rotate_90_cw, crop, resize_nearest, blur, sharpen |
| `layers.rs`      | `ImageLayer` + `LayeredImage`: compositing layer stack with order, opacity, visibility, Porter-Duff merge |
| `serial.rs`      | LIMG binary format: save/load `ImageData` and `LayeredImage` with zlib compression            |
| `compressed.rs`  | DDS/DXT compressed GPU texture container with format detection and loading                    |
| `palette_lut.rs`      | Colour palette lookup table mapping source colours to target colours          |
| `visualization.rs`    | Standalone visualization helpers for Tier 1 modules; renders animation frame grids and camera bounds to `ImageData` without requiring a direct import of `image` in those modules. Also provides `draw_animation_to_image()` and `draw_camera_to_image()` as the standard draw-to-image entry points for those types. |
| `render.rs`           | GPU render-command generation — `generate_render_commands()` and `draw_to_image()` on `ImageData` |
| `mod.rs` | — |

## Key Types

| Type                  | Kind   | Location            | Description                                          |
|-----------------------|--------|---------------------|------------------------------------------------------|
| `ImageData`           | struct | `image_data.rs`     | CPU-side RGBA8 pixel buffer; also implements 20 effects via `effects.rs` |
| `ImageLayer`          | struct | `layers.rs`         | Single compositing layer: `name`, `opacity`, `visible`, `data: ImageData` |
| `LayeredImage`        | struct | `layers.rs`         | Stack of `ImageLayer` values; supports merge via Porter-Duff "over" |
| `CompressedImageData` | struct | `compressed.rs`     | DDS compressed texture data for direct GPU upload    |
| `CompressedFormat`    | enum   | `compressed.rs`     | Format tag: Dxt1/Dxt3/Dxt5/Bc7/Etc1/Etc2…           |
| `PaletteLUT`          | struct | `palette_lut.rs`    | Source→target colour map for palette-swap shaders    |

## Lua API Summary

| Namespace / Method                       | Description                                               |
|------------------------------------------|-----------------------------------------------------------|
| `lurek.img.newImageData(w,h)`             | Create blank RGBA8 buffer                                 |
| `lurek.img.newImageData(fn)`              | Load PNG/JPEG from game directory                         |
| `lurek.img.newCompressedData`             | Load DDS file as CompressedImageData                      |
| `lurek.img.isCompressed`                  | Check if path is a DDS file                               |
| `lurek.img.newLayeredImage(w, h)`         | Create empty LayeredImage canvas                          |
| `lurek.img.saveImage(imgdata, path)`      | Save ImageData to LIMG binary file                        |
| `lurek.img.loadImage(path)`               | Load ImageData from LIMG binary file                      |
| `lurek.img.loadLayered(path)`             | Load LayeredImage from LIMG binary file                   |
| **ImageData core**                       | `getWidth`, `getHeight`, `getDimensions`, `getPixel`, `setPixel`, `mapPixel`, `encode`, `getString`, `paste` |
| **Color/Tone (in-place)**                | `brightness`, `contrast`, `saturation`, `gamma`, `tint`  |
| **Filters (in-place)**                   | `grayscale`, `sepia`, `invert`, `threshold`, `posterize`, `fill`, `noise`, `alphaMask` |
| **Geometric in-place**                   | `flipHorizontal`, `flipVertical`                          |
| **Geometric new-image**                  | `rotate90cw`, `crop`, `resizeNearest`                     |
| **Convolution new-image**                | `blur`, `sharpen`                                         |
| **LayeredImage**                         | `getWidth`, `getHeight`, `layerCount`, `addLayer`, `removeLayer`, `getLayer`, `setLayer`, `getOpacity`, `setOpacity`, `isVisible`, `setVisible`, `getName`, `setName`, `swapLayers`, `moveLayer`, `merge`, `save` |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/image.md`](../../docs/specs/image.md)

_Update both this file **and** `docs/specs/image.md` whenever source files, public types, or Lua bindings change._
