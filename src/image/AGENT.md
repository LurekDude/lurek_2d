# `image` — Agent Reference

## Module Info

- Module name: `image`
- Module group: Platform Services
- Spec path: `docs/specs/image.md`
- Lua API path(s): `src/lua_api/image_api.rs`
- Rust test path(s): `tests/rust/unit/image_tests.rs`, `tests/rust/stress/image_stress_tests.rs`
- Lua test path(s): `tests/lua/unit/test_image.lua`, `tests/lua/unit/test_image_effect.lua`, `tests/lua/stress/test_image_stress.lua`, `tests/lua/evidence/test_evidence_image_drawing.lua`, `tests/lua/evidence/test_evidence_imagedata.lua`, `tests/lua/evidence/test_evidence_image_effects.lua`, `tests/lua/evidence/test_evidence_imagedata_effects.lua`

## Module Purpose

The `image` module owns CPU-side image data and image manipulation. It gives the engine a place to load pixels from disk, construct images procedurally, inspect or edit pixels one by one, compose layered images, and serialize image data without requiring a live GPU resource.

This module exists so higher-level systems can work with pixels as ordinary Rust data. Animation tooling, procedural generation, screenshot export, asset preprocessing, and Lua scripts can all build or transform images here before those images are turned into renderable textures elsewhere. The `visualization` helpers also let Tier 1 modules expose debug or authoring images without importing GPU code.

The module intentionally does not own GPU upload, draw submission, swapchain behavior, or shader execution. It can describe data that the renderer will later consume, but actual rendering belongs to `render`, resource lifetime belongs to runtime state and resource keys, and window presentation belongs to `window`.

## Files

- `mod.rs`: Re-exports the module's public image types and groups the submodules into one CPU-side image surface.
- `image_data.rs`: Defines `ImageData`, the core RGBA8 pixel buffer with load, encode, per-pixel access, drawing primitives, and bulk pixel transforms.
- `effects.rs`: Adds CPU image-processing operations onto `ImageData`, including tone changes, geometric transforms, blur, sharpen, and other filter-style edits.
- `compressed.rs`: Defines DDS-backed compressed image data for formats that should stay compressed until GPU upload.
- `palette_lut.rs`: Stores source-to-target color mappings used for palette-swap style workflows.
- `layers.rs`: Defines layered image composition with named layers, visibility, opacity, ordering, and Porter-Duff style flattening.
- `serial.rs`: Implements the `.lim` binary format for saving and loading flat and layered images.
- `render.rs`: Converts `ImageData` into render-command descriptions without taking ownership of renderer internals.
- `texture.rs`: Defines a lightweight texture handle and CPU-to-renderer texture creation helpers.
- `texture_atlas.rs`: Packs named rectangular regions into a fixed atlas layout for sprite-sheet style use cases.
- `visualization.rs`: Produces `ImageData` visualizations for other systems such as animation playback, camera debugging, noise, terrain, and easing curves.

## Key Types

- `ImageData`: The main CPU image container. It is the module's central type for pixel storage, file decode/encode, primitive drawing, and effect application.
- `CompressedImageData`: Holds DDS payloads and mip data in compressed form so the engine can defer expansion and upload decisions to the renderer.
- `CompressedFormat`: Identifies which GPU-compressed format a DDS asset uses and gives the Lua side a stable format name.
- `PaletteLUT`: Describes palette remapping tables for effects that replace source colors with target colors.
- `ImageLayer`: Represents a single named layer with visibility, opacity, and its own `ImageData` backing store.
- `LayeredImage`: Owns an ordered stack of `ImageLayer` values and merges them into a flat image when callers need a composited result.
- `Texture`: A lightweight texture handle and metadata wrapper used when CPU image data is inserted into renderer-owned texture storage.
- `TextureAtlas`: Owns atlas dimensions and packed regions for named sub-images that share one backing texture.
- `AtlasRegion`: Describes the packed rectangle for one atlas entry.# `image` — Agent Reference
