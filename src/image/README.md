# `src/image/` — Pixel-Level Image Manipulation

## Purpose

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

### How It Works

`ImageData` stores pixel data as a `Vec<u8>` with 4 bytes per pixel in RGBA
byte order.  All coordinate access computes `offset = (x + y * width) * 4`
with explicit bounds checking, returning an error on out-of-range access rather
than panicking.  Operations that produce a new image (crop, resize, rotate)
allocate a fresh `Vec<u8>` rather than mutating in-place, making them safe from
Lua without aliasing concerns.

The blend modes (Normal, Add, Multiply, Screen, Overlay) are implemented as
per-pixel float arithmetic: each channel is normalised to [0, 1], the blend
formula is applied, and the result is clamped back to [0, 255].  The `image`
crate handles file decoding (PNG via the pure-Rust `png` decoder, JPEG via
`jpeg-decoder`); `ImageData` takes the decoded RGBA bytes without any further
processing.

Flood fill uses a stack-based 4-connected BFS rather than recursion to avoid
stack-overflow on large uniform regions.  The target colour and replacement
colour are compared in RGBA u8 space; tolerance-based flood fill is not
currently implemented but can be approximated by iterating `get_pixel` from
Lua.

### Dependency Direction

```
image/ ──────► (none — uses `image` crate for decoding/encoding)
```

**Leaf module** — no Luna2D dependencies.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `ImageData`.

**~5 lines** — pure re-export.

---

### `image_data.rs` — `ImageData` (CPU Pixel Buffer)

**~226 lines** | RGBA8 pixel buffer with Lua UserData interface.

#### Struct: `ImageData`

```rust
pub struct ImageData {
    width: u32,
    height: u32,
    pixels: Vec<u8>,   // RGBA8, row-major: [R,G,B,A, R,G,B,A, ...]
}
```

#### Construction

| Method | Source |
|--------|--------|
| `new(w, h)` | Transparent (all zeros) |
| `from_file(path)` | Loads via `image` crate, converts to RGBA8 |
| `from_bytes(data)` | Decodes from in-memory bytes |

#### Pixel Operations

| Method | Returns | Notes |
|--------|---------|-------|
| `get_pixel(x, y)` | `Option<(u8, u8, u8, u8)>` | Returns None for out-of-bounds |
| `set_pixel(x, y, r, g, b, a)` | `bool` | Returns false for out-of-bounds |
| `paste(source, x, y)` | — | Blits source onto self at offset |
| `map_pixel(callback)` | — | Applies callback to every pixel |
| `encode_png()` | `Vec<u8>` | PNG-encoded bytes |

#### Lua UserData Methods

`getWidth`, `getHeight`, `getDimensions`, `getPixel`, `setPixel`, `encode("png")`,
`getString`, `mapPixel`.

**Design**: Row-major RGBA8 is the simplest format for pixel manipulation.
4 bytes per pixel, index = `(y * width + x) * 4`. Bounds-checked to prevent
buffer overflows from Lua.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/image_api.rs`, exposing `ImageData` as
UserData under `luna.image.*`.

### Usage from Lua

```lua
-- Create blank image
local img = luna.image.newImageData(256, 256)

-- Set pixels
for x = 0, 255 do
    for y = 0, 255 do
        img:setPixel(x, y, x, y, 128, 255)
    end
end

-- Load from file
local sprite = luna.image.newImageData("assets/hero.png")
local r, g, b, a = sprite:getPixel(10, 10)

-- Per-pixel transform
img:mapPixel(function(x, y, r, g, b, a)
    return 255 - r, 255 - g, 255 - b, a  -- invert colors
end)
```
