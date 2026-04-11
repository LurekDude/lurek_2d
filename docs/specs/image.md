# `image` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.img`                                         |
| **Source**     | `src/image/`                                         |
| **Rust Tests** | `tests/rust/unit/image_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_image.lua`                      |
| **Architecture** | —                                                  |

## Summary

The `image` module provides CPU-side pixel-level access to RGBA image data. It is the raw pixel layer that sits beneath the GPU texture pipeline — `ImageData` is never on the GPU until explicitly uploaded via the graphics API (`lurek.graphic.newImage(imgdata)`). The module covers five distinct concerns: uncompressed RGBA pixel buffers (`ImageData`), GPU-compressed DDS texture containers (`CompressedImageData`), a compositing layer stack (`LayeredImage` / `ImageLayer`), a compressed binary serialisation format (`serial` / LIMG), and colour palette lookup tables for shader-based palette swapping (`PaletteLUT`).

`ImageData` supports loading PNG/JPEG files from disk via the `image` crate, creating blank buffers, constructing from raw bytes, per-pixel read/write (`get_pixel` / `set_pixel`), bulk transforms (`map_pixel`, `paste`), PNG encoding, and raw byte extraction. Because it is pure `Vec<u8>` arithmetic with no GPU state, operations can be called freely during `lurek.load()` or inside background thread workers.

`CompressedImageData` loads DDS files (DXT1/DXT3/DXT5/BC7 formats via the `ddsfile` crate) without CPU-side decompression, preserving raw compressed bytes for direct GPU upload. It also provides magic-number detection to distinguish DDS files from standard images.

`PaletteLUT` maps source colours to target colours, enabling team-colour recolouring and palette-swap effects at render time through shader uniform data. It pairs `Vec<Color>` source and target arrays with auto-extending set operations.

Typical uses include procedural texture generation, palette-swap effects, runtime image analysis, and screenshot compositing. The module intentionally does NOT perform any GPU operations — all rendering is delegated to the `graphics` module.

## Architecture

```
src/image/
  │
  ├── ImageData (image_data.rs)
  │     ├── Storage ── Vec<u8> RGBA8 row-major (4 bytes/pixel)
  │     ├── Pixel access ── get_pixel / set_pixel / map_pixel
  │     ├── Bulk ops ── paste, encode_png, as_bytes, get_string
  │     ├── I/O ── from_file (PNG/JPEG), from_bytes
  │     └── UserData ── Lua methods (getWidth, getHeight, etc.)
  │
  ├── CompressedImageData (compressed.rs)
  │     ├── Storage ── Vec<Vec<u8>> mipmaps (raw DDS compressed bytes)
  │     ├── Format detection ── detect_format (DXT1/3/5, BC7, ETC)
  │     ├── I/O ── from_dds (bytes), from_file (path)
  │     └── Magic check ── is_dds_magic, is_dds_file
  │
  └── PaletteLUT (palette_lut.rs)
        ├── Storage ── Vec<Color> from_colors + Vec<Color> to_colors
        └── API ── set_color, get_from_color, get_to_color, clear
```

## Source Files

| File             | Purpose                                                                                         |
|------------------|-------------------------------------------------------------------------------------------------|
| `image_data.rs`  | CPU-side RGBA8 pixel buffer with per-pixel access, paste, map, PNG encode, and `mlua::UserData` impl |
| `effects.rs`     | 20 CPU-side pixel-processing effects (brightness, blur, sepia, geometric transforms, etc.)      |
| `layers.rs`      | `ImageLayer` + `LayeredImage`: compositing stack with opacity, visibility, and Porter-Duff merge |
| `serial.rs`      | LIMG binary format: save/load `ImageData` and `LayeredImage` with zlib compression              |
| `compressed.rs`  | DDS/DXT compressed GPU texture container with format detection and loading                      |
| `palette_lut.rs` | Colour palette lookup table mapping source colours to target colours                            |

## Submodules

### `image::image_data`

CPU-side RGBA8 pixel buffer for image manipulation.

- **`ImageData`** (struct): Row-major `Vec<u8>` pixel buffer (4 bytes per pixel). Constructors: `new(w, h)` (zero-filled), `from_file(path)` (PNG/JPEG via `image` crate), `from_bytes(w, h, bytes)`. Pixel access: `get_pixel`, `set_pixel`. Transforms: `map_pixel`, `paste`. Export: `encode_png`, `as_bytes`, `get_string`. Also implements `mlua::UserData` with Lua methods: `getWidth`, `getHeight`, `getDimensions`, `getPixel`, `setPixel`, `encode`, `getString`, `mapPixel`.

### `image::compressed`

DDS/DXT compressed GPU texture data, loaded without CPU decompression.

- **`CompressedFormat`** (enum): Format identifier — `Dxt1`, `Dxt3`, `Dxt5`, `Bc7`, `Etc1`, `Etc2Rgb`, `Etc2Rgba`, `Unknown`. Method: `as_str()`.
- **`CompressedImageData`** (struct): Raw compressed bytes per mip level. Fields: `format`, `width`, `height`, `mipmaps`. Constructors: `from_dds(bytes)`, `from_file(path)`. Queries: `get_dimensions`, `get_mipmap_count`, `get_format`. Utilities: `is_dds_magic(bytes)`, `is_dds_file(path)`.

### `image::palette_lut`

Colour palette lookup table for shader-based palette swapping.

- **`PaletteLUT`** (struct): Pairs `Vec<Color>` source and target arrays. Methods: `new()`, `get_color_count()`, `set_color(index, from, to)`, `get_from_color(index)`, `get_to_color(index)`, `clear()`. Implements `Default`.

## Key Types

### Structs

#### `image::image_data::ImageData`

CPU-side pixel buffer in RGBA8 format. Wraps a `Vec<u8>` in row-major order with 4 bytes per pixel (R, G, B, A). Never backed by GPU memory — upload explicitly via the graphics API to obtain a `Texture`.

| Field    | Type      | Description                                       |
|----------|-----------|---------------------------------------------------|
| `width`  | `u32`     | Width in pixels                                   |
| `height` | `u32`     | Height in pixels                                  |
| `pixels` | `Vec<u8>` | RGBA8 pixel data, row-major (4 bytes per pixel)   |

**Key methods**: `new(w, h)`, `from_file(path)`, `from_bytes(w, h, bytes)`, `get_pixel(x, y)`, `set_pixel(x, y, r, g, b, a)`, `paste(source, dx, dy)`, `map_pixel(f)`, `encode_png()`, `as_bytes()`, `get_string()`, `width()`, `height()`, `dimensions()`.

**Effect methods** (defined in `effects.rs` as `impl ImageData` — all accessible via the same `ImageData` type):

| Method | Signature | Returns | Description |
|--------|-----------|---------|-------------|
| `brightness` | `(factor: f32)` | `()` | Multiply all RGB channels by `factor`; alpha unchanged |
| `contrast` | `(factor: f32)` | `()` | Scale each channel distance from mid-grey (128); alpha unchanged |
| `saturation` | `(factor: f32)` | `()` | 0 = greyscale, 1 = original, >1 = boosted saturation |
| `gamma` | `(gamma: f32)` | `()` | Gamma-correct each RGB channel; alpha unchanged |
| `tint` | `(tr, tg, tb: u8, factor: f32)` | `()` | Blend pixels toward tint colour; alpha unchanged |
| `grayscale` | `()` | `()` | Convert to greyscale using perceptual weights |
| `sepia` | `()` | `()` | Apply the standard sepia tone matrix |
| `invert` | `()` | `()` | Invert RGB channels (`255 - ch`); alpha unchanged |
| `threshold` | `(value: u8)` | `()` | Pixels with luma ≥ value → white; below → black |
| `posterize` | `(levels: u8)` | `()` | Reduce each channel to N evenly-spaced levels (min 2) |
| `fill` | `(r, g, b, a: u8)` | `()` | Overwrite every pixel with solid colour including alpha |
| `noise` | `(amount: u8)` | `()` | Add pseudo-random ±amount noise to each RGB channel |
| `alpha_mask` | `(factor: f32)` | `()` | Multiply alpha channel by `factor`; RGB unchanged |
| `flip_horizontal` | `()` | `()` | Mirror image left ↔ right in-place |
| `flip_vertical` | `()` | `()` | Mirror image top ↔ bottom in-place |
| `rotate_90_cw` | `()` | `ImageData` | Return new image rotated 90° clockwise (dims swapped) |
| `crop` | `(x, y, w, h: u32)` | `Option<ImageData>` | Extract sub-rectangle; `None` if out of bounds |
| `resize_nearest` | `(w, h: u32)` | `ImageData` | Return new image scaled to `w×h` using nearest-neighbour |
| `blur` | `(radius: u32)` | `ImageData` | Return new image blurred with two-pass box filter |
| `sharpen` | `()` | `ImageData` | Return new image sharpened with 3×3 unsharp kernel |

#### `image::compressed::CompressedImageData`

CPU-side holder for GPU-compressed texture data loaded from DDS files. Does NOT decompress pixels — raw compressed bytes are for direct GPU upload.

| Field      | Type              | Description                                           |
|------------|-------------------|-------------------------------------------------------|
| `format`   | `CompressedFormat` | Detected compressed format                           |
| `width`    | `u32`             | Width of the base mip level in pixels                |
| `height`   | `u32`             | Height of the base mip level in pixels               |
| `mipmaps`  | `Vec<Vec<u8>>`    | Raw compressed bytes per mip level (index 0 = base)  |

**Key methods**: `from_dds(bytes)`, `from_file(path)`, `get_dimensions()`, `get_mipmap_count()`, `get_format()`, `is_dds_magic(bytes)`, `is_dds_file(path)`.

#### `image::palette_lut::PaletteLUT`

Colour palette lookup table mapping source colours to target colours for shader-based palette swapping.

| Field         | Type         | Description                                    |
|---------------|--------------|------------------------------------------------|
| `from_colors` | `Vec<Color>` | Source colours to match against                |
| `to_colors`   | `Vec<Color>` | Replacement colours in the same order          |

**Key methods**: `new()`, `get_color_count()`, `set_color(index, from, to)`, `get_from_color(index)`, `get_to_color(index)`, `clear()`.

### Enums

#### `image::compressed::CompressedFormat`

GPU-compressed texture format identifier. Used by `CompressedImageData` to report the detected format.

| Variant    | Description                          |
|------------|--------------------------------------|
| `Dxt1`     | DXT1 / BC1 format                    |
| `Dxt3`     | DXT3 / BC2 format                    |
| `Dxt5`     | DXT5 / BC3 format                    |
| `Bc7`      | BC7 format                           |
| `Etc1`     | ETC1 format                          |
| `Etc2Rgb`  | ETC2 RGB format                      |
| `Etc2Rgba` | ETC2 RGBA format                     |
| `Unknown`  | Unknown or unsupported format        |

**Key methods**: `as_str()` — returns the Lua-facing format name string.


#### `image::layered::ImageLayer`

A single layer within a `LayeredImage`. Holds an `ImageData` buffer and a string `name`. Layers are composited top-to-bottom using alpha blending when the parent is flattened.

#### `image::layered::LayeredImage`

A stack of named `ImageLayer` objects. Created with `lurek.image.newLayeredImage(w, h)` or `lurek.image.loadLayered(path)`. Supports add/remove, per-layer pixel manipulation, and `flattenToImageData()` export.
## Lua API

Exposed under `lurek.img.*` by `src/lua_api/image_api.rs`. The Lua wrapper also defines `LuaCompressedImageData` as a UserData type wrapping `CompressedImageData`.

### Module Functions

| Function                           | Description                                                                 |
|------------------------------------|-----------------------------------------------------------------------------|
| `lurek.img.newImageData(w, h)`    | Creates a new blank RGBA8 pixel buffer of the given dimensions              |
| `lurek.img.newImageData(filename)`| Loads an image file (PNG/JPEG) from the game directory as `ImageData`       |
| `lurek.img.newCompressedData(filename)` | Loads compressed texture data from a DDS file                         |
| `lurek.img.isCompressed(filename)`| Returns `true` if the file at the given path is a DDS file                  |

### ImageData Methods (UserData)

#### Core

| Method                                  | Description                                              |
|-----------------------------------------|----------------------------------------------------------|
| `img:getWidth()`                        | Returns width in pixels                                  |
| `img:getHeight()`                       | Returns height in pixels                                 |
| `img:getDimensions()`                   | Returns width and height                                 |
| `img:getPixel(x, y)`                    | Returns RGBA values (0–255) at the given coordinates     |
| `img:setPixel(x, y, r, g, b, a)`       | Sets RGBA values (0–255) at the given coordinates        |
| `img:mapPixel(fn)`                      | Applies a function to every pixel `(x, y, r, g, b, a) → (r, g, b, a)` |
| `img:encode("png")`                     | Encodes the image as PNG bytes                           |
| `img:getString()`                       | Returns the raw RGBA pixel bytes                         |
| `img:paste(src, dx, dy)`               | Copy all pixels from `src` onto self at `(dx, dy)`       |

#### Color / Tone Effects (in-place, return `nil`)

| Method                              | Description                                                        |
|-------------------------------------|--------------------------------------------------------------------|
| `img:brightness(factor)`            | Multiply RGB by `factor`; >1 brightens, <1 darkens                 |
| `img:contrast(factor)`              | Scale each channel's distance from mid-grey (128)                  |
| `img:saturation(factor)`            | 0 = greyscale, 1 = unchanged, >1 = boosted                        |
| `img:gamma(gamma)`                  | Apply gamma correction per channel                                 |
| `img:tint(tr, tg, tb, factor)`      | Blend pixels toward tint colour by `factor` (0–1)                  |

#### Filter Effects (in-place, return `nil`)

| Method                              | Description                                                        |
|-------------------------------------|--------------------------------------------------------------------|
| `img:grayscale()`                   | Convert to greyscale (perceptual luminance weights)                |
| `img:sepia()`                       | Apply classic sepia tone matrix                                    |
| `img:invert()`                      | Invert RGB channels; alpha unchanged                               |
| `img:threshold(value)`              | Luminance ≥ value → white; below → black                           |
| `img:posterize(levels)`             | Reduce each channel to N evenly-spaced levels (min 2)              |
| `img:fill(r, g, b, a)`             | Overwrite every pixel with solid RGBA colour                       |
| `img:noise(amount)`                 | Add pseudo-random ±amount noise to each RGB channel                |
| `img:alphaMask(factor)`             | Multiply alpha by `factor`; 0 = transparent, 1 = unchanged         |

#### Geometric Effects — In-place (return `nil`)

| Method                              | Description                                                        |
|-------------------------------------|--------------------------------------------------------------------|
| `img:flipHorizontal()`              | Mirror left ↔ right; dimensions unchanged                          |
| `img:flipVertical()`                | Mirror top ↔ bottom; dimensions unchanged                          |

#### Geometric Effects — New Image (return `ImageData`)

| Method                              | Description                                                        |
|-------------------------------------|--------------------------------------------------------------------|
| `img:rotate90cw()`                  | Rotate 90° clockwise; new_w = old_h, new_h = old_w                |
| `img:crop(x, y, w, h)`             | Extract sub-rectangle; **errors** if out of bounds                 |
| `img:resizeNearest(w, h)`           | Scale to `w×h` via nearest-neighbour interpolation                 |

#### Convolution Effects — New Image (return `ImageData`)

| Method                              | Description                                                        |
|-------------------------------------|--------------------------------------------------------------------|
| `img:blur(radius)`                  | Two-pass box blur; radius=0 returns a copy                         |
| `img:sharpen()`                     | 3×3 unsharp kernel; edge pixels clamped                            |

### CompressedImageData Methods (UserData)

| Method                  | Description                                     |
|-------------------------|-------------------------------------------------|
| `cid:getWidth()`        | Returns base mip width                          |
| `cid:getHeight()`       | Returns base mip height                         |
| `cid:getDimensions()`   | Returns base mip width and height               |
| `cid:getMipmapCount()`  | Returns the number of mipmap levels              |
| `cid:getFormat()`       | Returns the compressed format name string        |

### Layered Image Functions

| Function | Description |
|---|---|
| `lurek.image.newLayeredImage(w, h)` | Creates a new layered `ImageData` with given dimensions |
| `lurek.image.saveImage(data, path)` | Saves an `ImageData` to a PNG file |
| `lurek.image.loadImage(path)` | Loads an image file and returns an `ImageData` |
| `lurek.image.loadLayered(path)` | Loads a layered image and returns a `LayeredImage` |

| `lid:getLayer(n)` | Returns the nth `ImageLayer` from a `LayeredImage` |
| `lid:addLayer(name)` | Adds a named layer to the `LayeredImage` |
| `lid:removeLayer(n)` | Removes the nth layer |
| `lid:flattenToImageData()` | Merges all layers into one `ImageData` |

## Lua Examples

```lua
function lurek.init()
    -- Create a CPU-side pixel buffer and fill with a gradient
    imgdata = lurek.img.newImageData(64, 64)
    for y = 0, 63 do
        for x = 0, 63 do
            imgdata:setPixel(x, y, x * 4, y * 4, 128, 255)
        end
    end

    -- Upload to GPU for rendering
    tex = lurek.graphic.newImage(imgdata)
end

function lurek.render()
    lurek.graphic.draw(tex, 100, 100)
end
```

```lua
-- Load an image file, invert its colours, and upload the result
function lurek.init()
    local src = lurek.img.newImageData("sprites/player.png")
    src:mapPixel(function(x, y, r, g, b, a)
        return 255 - r, 255 - g, 255 - b, a
    end)
    inverted = lurek.graphic.newImage(src)
end
```

```lua
-- Check whether a file is a compressed DDS texture
if lurek.img.isCompressed("textures/terrain.dds") then
    local cid = lurek.img.newCompressedData("textures/terrain.dds")
    print("Format:", cid:getFormat())
    print("Size:", cid:getWidth(), "x", cid:getHeight())
    print("Mipmaps:", cid:getMipmapCount())
end
```

## Item Summary

| Kind           | Count |
|----------------|-------|
| `struct`       | 5     |
| `enum`         | 1     |
| `fn` (Rust)    | 66    |
| Lua methods    | 42    |
| Effects        | 20    |
| **Total items**| **70**|

## References

| Module     | Relationship  | Notes                                                                        |
|------------|---------------|------------------------------------------------------------------------------|
| `engine`   | Imports from  | Uses `EngineError` for `CompressedImageData` error handling                  |
| `math`     | Imports from  | `Color` type used by `PaletteLUT`                                            |
| `graphics` | Related       | `image` is CPU-side; `graphics` uploads `ImageData` to GPU via `newImage(imgdata)` |
| `data`     | Related       | `data` holds raw bytes (`ByteData`); `image` decodes them into RGBA pixel buffers |
| `sound`    | Similar       | `sound` is the audio equivalent — CPU-side PCM samples vs CPU-side pixels    |
| `lua_api`  | Imported by   | `src/lua_api/image_api.rs` registers `lurek.img.*`                          |

## Notes

- `ImageData` is a CPU-side RGBA8 buffer; it has no GPU resources until `lurek.graphic.newImage(imgdata)` is called.
- `ImageData` implements `mlua::UserData` directly in `image_data.rs`, exposing Lua methods alongside the Rust API.
- `mapPixel(fn)` calls the Lua function for every pixel — avoid for large images due to Lua→Rust boundary overhead per pixel.
- PNG encoding via `encode("png")` is blocking and allocates; offload to a thread worker for non-blocking export of large images.
- `LayeredImage::merge()` uses Porter-Duff "over" compositing: each layer's per-pixel alpha is multiplied by its layer `opacity` before blending, then layers are composited from bottom to top.
- `LayeredImage` layers are 0-indexed in Rust but **1-indexed in Lua** (matching Lua array conventions).
- The LIMG binary format uses magic bytes `LIMG`, a version byte, and a type flag (0=flat, 1=layered). Pixel data is zlib-compressed. The format is self-describing and forward-extension-safe for unknown future flags.
- `serial::save_image` / `load_image` handle only flat `ImageData`. Calling `load_image` on a layered LIMG file returns a descriptive error.
- `CompressedImageData` depends on the `ddsfile` crate for DDS parsing. It does NOT decompress — raw bytes are for direct GPU upload.
- `PaletteLUT` is a pure data structure with no GPU dependency; it is designed to be consumed by a shader uniform for palette-swap rendering.
- `PaletteLUT::set_color` auto-extends the internal vectors with `Color::WHITE` filler entries if the index exceeds the current length.
- The Lua API resolves file paths relative to the game directory via `state.borrow().game_dir.join(filename)`.
- `CompressedFormat` supports DXT1/3/5, BC7, ETC1, and ETC2 variants; unrecognised DDS formats report `Unknown` rather than erroring.
- The `image` crate (external) handles PNG/JPEG decoding and PNG encoding; `ddsfile` crate handles DDS parsing; `flate2` crate handles LIMG zlib compression.
