---
name: image-manipulation
description: "Load this skill when working with Luna2D CPU-side image manipulation: ImageData pixel read/write, procedural texture generation, or pixel-level operations. Skip it for GPU rendering, asset loading, or sprite display."
---

# Image Manipulation — Luna2D Engine

## Load When

- Reading or writing individual pixels in an ImageData buffer
- Generating procedural textures on the CPU
- Performing pixel-level operations (fill, sample, compare)
- Converting between image formats
- Using `luna.image.*` API functions

## Owns

- `src/image/mod.rs` — `ImageData` CPU-side pixel buffer
- `src/lua_api/image_api.rs` — `luna.image.*` Lua bindings

## Does Not Cover

- GPU texture rendering → use `software-rendering` skill
- Asset loading from disk → use `asset-pipeline` skill
- Sprite display and animation → use `animation-system` skill
- Font glyph rasterization → use `font-rendering` skill

## Live Repository Contracts

- `src/image/mod.rs` — `ImageData` struct (RGBA8 pixel buffer)
- `tests/image_tests.rs` — pixel read/write tests

## Key Facts

- **RGBA8 format** — each pixel is 4 bytes (red, green, blue, alpha), values 0–255
- **CPU-side only** — ImageData lives in system memory, not on GPU
- **Width × Height** — pixel at (x, y) is at index `(y * width + x) * 4`
- **Zero-indexed** — pixel coordinates start at (0, 0) top-left
- **Mutable** — pixels can be read and written after creation
- **Upload to GPU** — ImageData can be converted to a GPU texture for rendering

## Best Practices

- Use ImageData for procedural generation, then upload to GPU texture once
- Batch pixel writes — don't upload to GPU after every pixel change
- Keep ImageData sizes reasonable — large images (4096x4096) use significant CPU memory
- Use for offline processing (level generation, noise maps) not per-frame rendering

## Anti-Patterns

- **Per-frame pixel manipulation**: Modifying ImageData every frame — use shaders instead
- **Huge buffers**: Creating 8192x8192 ImageData — CPU memory hog, use tiled approach
- **GPU round-trip**: Reading back from GPU to ImageData for modification — expensive
