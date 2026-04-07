# image — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/image.md`
**Files**: CPU pixel operations

## Purpose

CPU-side image manipulation: load, create, read/write pixels, format conversion, palette operations. No GPU — this is the "ImageData" layer that feeds textures to graphics.

## Current Feature Summary

- `ImageData`: RGBA8 pixel buffer, create from file or dimensions
- Per-pixel get/set operations
- `CompressedImageData`: wraps encoded format bytes
- `PaletteLUT`: 256-color palette for color quantization
- Format support: PNG, JPEG (via `image` crate — also BMP, GIF, TIFF, WebP, ICO)
- Image encode to PNG/JPEG bytes
- Pixel iteration and bulk operations

## Feature Gaps

1. **No image resize/scale**: Can't resize an ImageData to different dimensions. Must create new image and manually sample.
2. **No image compositing**: No alpha blending of one ImageData onto another. Common for procedural texture generation.
3. **No flip/rotate operations**: No `image:flipH()`, `image:flipV()`, `image:rotate90()`.
4. **No color channel operations**: No grayscale conversion, channel extraction, channel swapping.
5. **No histogram**: No color histogram analysis — useful for procedural content and image analysis.
6. **No GPU readback**: Cannot capture GPU frame buffer into an ImageData for post-processing or analysis (saveScreenshot only writes to file).
7. **No image diff**: Can't compare two images pixel-by-pixel (useful for testing).
8. **No blur/sharpen/filters**: CPU-side convolution filters (even basic box blur). The `fx` module handles GPU-side post-processing, but for CPU image processing there's nothing.
9. **No sub-image extraction**: Can't extract a rectangular region from an ImageData.

## Structural Issues

- **Clear boundary with graphics**: image = CPU, graphics = GPU. This is clean and correct.
- **PaletteLUT is niche**: Palette quantization is specialized. Could be an optional utility rather than core image.
- **No streaming image decode**: Large images decode entirely into memory. For tilesets this is fine, but for background panoramas it could be an issue.

## Suggestions

1. **Add resize**: `image:resize(width, height, filter?)` — "nearest" or "bilinear". Essential for dynamic texture generation.
2. **Add flip/rotate**: `image:flipH()`, `image:flipV()`, `image:rotate(angle)` — very common operations.
3. **Add blit/composite**: `image:blit(source, x, y, blendMode?)` — draw one ImageData onto another with optional blending.
4. **Add sub-image extraction**: `image:getSubImage(x, y, w, h)` — extract region as new ImageData.
5. **Add grayscale**: `image:toGrayscale()` — collapse to luminance.
6. **Add GPU readback**: `luna.image.fromScreen()` or `canvas:toImageData()` — capture renderer output into CPU ImageData.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| ImageData | ✅ | ✅ | ❌ (display only) | ✅ (Image) |
| Per-pixel access | ✅ | ✅ | ❌ | ✅ |
| Resize | ❌ | ❌ | ❌ | ✅ |
| Compositing | ❌ | ❌ | ✅ (groups) | ✅ |
| Format support | 7+ | PNG/JPEG | PNG/JPEG | 10+ |
| Encode | ✅ | ✅ | ❌ | ✅ |
| GPU readback | ❌ | ✅ | ❌ | ✅ |

## Priority

**LOW** — Image module serves its purpose. Resize and flip/rotate would be nice. GPU readback is the highest-impact missing feature (for screenshots, testing, procedural content).
