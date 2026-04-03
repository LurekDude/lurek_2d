# `image` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 1 — Basic Core |
| **Lua API** | `luna.image` |
| **Source** | `src/image/` |
| **Tests** | `tests/image_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_image.lua` |

## Summary

The image module provides direct pixel-level access to RGBA image data —
loading PNG and JPEG files from disk, reading and writing individual pixels,
applying global transforms (horizontal and vertical flip, 90°/180°/270°
rotation, resize with nearest-neighbour or bilinear filtering), running flood
fill, compositing two `ImageData` instances with a blend mode, and extracting
sub-images as new instances.  It is the raw CPU pixel layer that sits beneath
the GPU texture pipeline; `ImageData` is never on the GPU until explicitly
converted to a `Texture` via the graphics API.

Typical uses include procedural texture generation (generate a noise pattern
in Lua, apply a colour palette, upload the result as a texture), palette-swap
effects (load a sprite, remap specific RGBA values to new colours, upload the
modified version as a separate variant), runtime image analysis (find the
tight bounding box of all opaque pixels), and screenshot blitting for
UI previews.  Because `ImageData` is pure `Vec<u8>` arithmetic there is no
GPU state to manage and operations can be called freely in `luna.load()` or in
a background computation step.

## Architecture

```
ImageData (CPU pixel buffer)
  │
  ├── Storage ── Vec<u8> RGBA8 row-major
  │
  ├── Pixel access
  │     ├── get_pixel(x, y) → (r, g, b, a)
  │     ├── set_pixel(x, y, r, g, b, a)
  │     └── map_pixel(callback) — per-pixel transform
  │
  ├── Bulk operations
  │     ├── paste(source, x, y) — blit onto self
  │     └── encode_png() → Vec<u8> — PNG encoding
  │
  └── I/O
        ├── from_file(path) — image crate loader
        └── from_bytes(data) — in-memory decode
```

## Source Files

| File | Purpose |
|------|---------|
| `image_data.rs` | CPU-side RGBA8 pixel buffer for image manipulation |

## Submodules

### `image::image_data`

CPU-side RGBA8 pixel buffer for image manipulation.

- **`ImageData`** (struct): CPU-side pixel buffer in RGBA8 format. Fields: `width: u32`, `height: u32`, `pixels: Vec<u8>` (row-major, 4 bytes per pixel). Constructors: `new(width, height)` (zero-filled), `from_file(path) → Result<Self, String>` (PNG/JPEG via `image` crate), `from_bytes(width, height, bytes)`. Pixel access: `get_pixel(x, y) → (u8, u8, u8, u8)`, `set_pixel(x, y, r, g, b, a)`. Queries: `width()`, `height()`, `dimensions() → (u32, u32)`.

## Key Types

### Structs

#### `image::image_data::ImageData`

CPU-side pixel buffer in RGBA8 format. Wraps a `Vec<u8>` in row-major order with 4 bytes per pixel (R, G, B, A). Never backed by GPU memory — upload explicitly via the graphics API to obtain a `Texture`.

| Field | Type | Description |
|-------|------|-------------|
| `width` | `u32` | Width in pixels |
| `height` | `u32` | Height in pixels |
| `pixels` | `Vec<u8>` | RGBA8 pixel data, row-major (4 bytes per pixel) |

**Key methods**: `new(w, h)` (zero-filled), `from_file(path)` (PNG/JPEG decode), `from_bytes(w, h, bytes)`, `get_pixel(x, y) → (u8,u8,u8,u8)`, `set_pixel(x, y, r, g, b, a)`, `width()`, `height()`, `dimensions() → (u32,u32)`.

## Lua API

Exposed under `luna.image.*` by `src/lua_api/image_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `mod` | 1 |
| `struct` | 1 |
| **Total** | **2** |

