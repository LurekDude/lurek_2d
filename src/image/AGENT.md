# `image` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.img`                                         |
| **Source**     | `src/image/`                                         |
| **Rust Tests** | `tests/rust/unit/image_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_image.lua`                      |
| **Architecture** | —                                                  |

## Purpose

The `image` module provides CPU-side pixel-level access to RGBA image data. It is the raw pixel layer that sits beneath the GPU texture pipeline — `ImageData` is never on the GPU until explicitly uploaded via the graphics API (`luna.gfx.newImage(imgdata)`). The module covers three distinct concerns: uncompressed RGBA pixel buffers (`ImageData`), GPU-compressed DDS texture containers (`CompressedImageData`), and colour palette lookup tables for shader-based palette swapping (`PaletteLUT`).

## Source Files

| File             | Purpose                                                                     |
|------------------|-----------------------------------------------------------------------------|
| `image_data.rs`  | CPU-side RGBA8 pixel buffer with per-pixel access, paste, map, PNG encode   |
| `compressed.rs`  | DDS/DXT compressed GPU texture container with format detection and loading  |
| `palette_lut.rs` | Colour palette lookup table mapping source colours to target colours        |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/image.md`](../../specs/image.md)

_Update both this file **and** `specs/image.md` whenever source files, public types, or Lua bindings change._
