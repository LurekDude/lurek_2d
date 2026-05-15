# image

## General Info

- Module group: `Platform Services`
- Source path: `src/image/`
- Lua API path(s): `src/lua_api/image_api.rs`
- Primary Lua namespace: `lurek.image`
- Rust test path(s): tests/rust/unit/image_tests.rs, tests/rust/stress/image_stress_tests.rs
- Lua test path(s): tests/lua/unit/test_image_core_unit.lua, tests/lua/unit/test_image.lua, tests/lua/unit/test_image_effect.lua, tests/lua/unit/test_render_core_unit.lua, tests/lua/stress/test_image_stress.lua, tests/lua/evidence/test_evidence_image_drawing.lua, tests/lua/evidence/test_evidence_imagedata.lua, tests/lua/evidence/test_evidence_image_effects.lua, tests/lua/evidence/test_evidence_imagedata_effects.lua

## Summary

The `image` module is Lurek2D's CPU-side pixel buffer and image manipulation library — a Platform Services tier module used by the asset pipeline, golden tests, save serialisation, and the debug visualisation system. It has no dependency on wgpu or the GPU render pipeline, making it fully usable in headless test contexts.

**ImageData — the core buffer.** `ImageData` is a heap-allocated RGBA8 pixel buffer (`width × height × 4` bytes) with construction from file (PNG/JPEG via the `image` crate), from raw bytes, or zeroed allocation. Per-pixel API: `get_pixel(x, y)` → `[u8;4]`, `set_pixel(x, y, rgba)`. Drawing primitives: filled rect, filled circle, Bresenham line, 3×5 bitmap font label. Bulk transforms: `resize(w, h, filter)` (nearest-neighbour, bilinear, and lanczos3), `blit(src, dst_x, dst_y)` (Porter-Duff over; opaque fast path), `fill(color)`, `get_region(x, y, w, h)` (crop), `diff(other)` (pixel-by-pixel delta image for golden tests). High-throughput transforms: `map_pixel(fn)` and `map_pixel_par(fn)` (Rayon-accelerated for images > 65K pixels). Format export: `encode_png()` → bytes.

**Image effects.** `effects.rs` extends `ImageData` with CPU-side image processing: brightness/contrast adjustment, hue-rotate, saturate, desaturate, sepia tone, invert, blur (box and Gaussian), sharpen, emboss, edge detection, pixelate, and `convolve(kernel, ksize)` for custom kernels. These effects run entirely on the CPU and do not require a GPU shader.

**Layered compositing.** `LayeredImage` and `ImageLayer` implement a Porter-Duff compositing stack. Each `ImageLayer` carries a name, visibility flag, opacity scalar, and its own `ImageData` backing store. `LayeredImage::flatten()` composites all visible layers in order into a single `ImageData`. Used for multi-layer save files (e.g., the `painting.limg` save format) and for the `effect` module's CPU-side compositing path.

**Province grid.** `ProvinceGrid` in `province_grid.rs` is a flat `Vec<u32>` spatial index built from a province-colour PNG in a single O(w×h) scan. Each unique non-black RGB is assigned a sequential province ID (1..n). Provides O(1) coordinate-to-province lookup (`get(x, y) → province_id`), single-pass adjacency detection with border-pixel counts (`adjacencies()` → `Vec<AdjacencyPair>`), and border-corner polygon extraction (`province_polygons()` / `province_polygons_simplified()`) where each vertex is a pixel-grid corner. Used by the `globe` module and strategy games that use colour-coded province maps.

The Lua-side `LProvinceGrid` userdata also exposes `drawShapes(view_x?, view_y?, view_w?, view_h?)`, which uses cached simplified polygons and the original province colours to enqueue filled polygon render commands on the Rust render queue. When a viewport is provided, off-screen shapes are culled before commands are pushed.

**Compressed image data.** `CompressedImageData` holds DDS/DXT1/DXT3/DXT5/BC7/ETC compressed GPU texture data loaded without CPU decompression, ready to upload directly to wgpu. `CompressedFormat` identifies the compression format. This path is used for large atlas textures where the file size and VRAM footprint matter.

**Palette LUT.** `PaletteLUT` is a colour palette lookup table mapping source RGBA values to target RGBA values for palette-swap effects. Used by the `effect` module's CPU palette-swap pass and the shader-side palette-swap render feature.

**Texture atlas.** `TextureAtlas` in `texture_atlas.rs` uses a shelf-packing bin-packing algorithm to arrange named rectangular regions into a fixed atlas layout. Regions can optionally carry `NineSliceInsets { left, right, top, bottom }` metadata for scalable UI/panel rendering.

**Serial format.** `serial.rs` implements the binary `.lim` (LIMG) format: zlib-compressed `ImageData` or `LayeredImage` with a fixed header. `encode_lim(image)` → bytes; `decode_lim(bytes)` → `ImageData` or `LayeredImage`. Used by the `save` module.

**Visualisation helpers.** The `visualization/` submodule provides over 40 standalone helper functions that produce `ImageData` debug bitmaps without import cycles: animation frame sequence previews, audio waveform bitmaps, camera frustum diagrams, easing curves, Bezier curves, noise maps, geometry intersection diagrams, HUD bar renderings, and graph visualisations. These are used exclusively by development and documentation tooling.

**Render integration.** `render.rs` converts `ImageData` values into `RenderCommand::DrawImage` entries for direct draw calls without creating a persistent GPU texture. Used for debug overlays that change every frame.

**Lua surface.** `lurek.image.new(w, h)`, `lurek.image.load(path)`, `lurek.image.newImageDataFromBytes(w, h, bytes)`, and `lurek.image.fromScreen()` (async poll-based GPU readback). `ImageData` userdata: `get(x, y)`, `set(x, y, r, g, b, a)`, `resize(w, h, filter?)`, `blit(src, dx, dy)`, `fill(r, g, b, a)`, `region(x, y, w, h)`, `encodePng()`, `getRawBytes()`, `diff(other)`. Effects: `brightness(v)`, `blur(r)`, `convolve(kernel)`, etc. `lurek.image.newLayers()` → `LayeredImage`. `lurek.image.loadCompressed(path)` → `CompressedImageData`. `lurek.image.newAtlas()` → `TextureAtlas`. Integration path: `lurek.render.newImage(path_or_imageData, color_space?)` accepts optional `"srgb"`/`"linear"` upload hint.

**Scope boundary.** Platform Services tier. Depends on `image` external crate, `ddsfile`, `flate2`, `rayon`. Lua bridge in `src/lua_api/image_api.rs`.
`src/image/effects.rs` owns CPU pixel transforms and CPU nine-slice drawing helpers. Shader-chain composition for post-processing lives in `src/effect/image_effect.rs`.

## Files

- `compressed.rs`: Defines DDS-backed compressed image data for formats that should stay compressed until GPU upload.
- `effects.rs`: Adds CPU image-processing operations onto `ImageData`, including tone changes, geometric transforms, blur, sharpen, and other filter-style edits.
- `image_data.rs`: Defines `ImageData`, the core RGBA8 pixel buffer with load, encode, per-pixel access, drawing primitives, and bulk pixel transforms.
- `layers.rs`: Defines layered image composition with named layers, visibility, opacity, ordering, and Porter-Duff style flattening.
- `mod.rs`: Re-exports the module's public image types and groups the submodules into one CPU-side image surface.
- `palette_lut.rs`: Stores source-to-target color mappings used for palette-swap style workflows.
- `province_grid.rs`: Defines `ProvinceGrid`, a flat `Vec<u32>` spatial index built from a province-colour PNG. Provides O(1) coordinate lookup and single-pass O(w×h) adjacency detection with border-pixel counts.
- `render.rs`: Converts `ImageData` into render-command descriptions without taking ownership of renderer internals.
- `serial.rs`: Implements the `.lim` binary format for saving and loading flat and layered images.
- `texture.rs`: Defines a lightweight texture handle and CPU-to-renderer texture creation helpers.
- `texture_atlas.rs`: Packs named rectangular regions into a fixed atlas layout for sprite-sheet style use cases.
- `visualization/animation.rs`: Animation visualization helpers.
- `visualization/audio.rs`: Audio waveform visualization helpers.
- `visualization/camera.rs`: Camera visualization helpers.
- `visualization/easing.rs`: Easing curve and Bezier visualization helpers.
- `visualization/facade.rs`: Shared color conversion helpers for the `visualization` module.
- `visualization/geometry.rs`: Geometry shape and intersection visualization helpers.
- `visualization/graph.rs`: Graph visualization helpers.
- `visualization/image_ops.rs`: Image operation visualization helpers.
- `visualization/mod.rs`: Standalone visualization helpers for Tier 1 modules.
- `visualization/noise.rs`: Noise and terrain visualization helpers.
- `visualization/procgen.rs`: Procedural generation visualization helpers.
- `visualization/ui.rs`: UI and HUD visualization helpers.

## Types

- `CompressedFormat` (`enum`, `compressed.rs`): Identifies which GPU-compressed format a DDS asset uses and gives the Lua side a stable format name.
- `CompressedImageData` (`struct`, `compressed.rs`): Holds DDS payloads and mip data in compressed form so the engine can defer expansion and upload decisions to the renderer.
- `ResizeFilter` (`enum`, `effects.rs`): Resize kernels supported by the image resampler.
- `ImageData` (`struct`, `image_data.rs`): The main CPU image container. It is the module's central type for pixel storage, file decode/encode, primitive drawing, and effect application.
- `ImageLayer` (`struct`, `layers.rs`): Represents a single named layer with visibility, opacity, and its own `ImageData` backing store.
- `LayeredImage` (`struct`, `layers.rs`): Owns an ordered stack of `ImageLayer` values and merges them into a flat image when callers need a composited result.
- `PaletteLUT` (`struct`, `palette_lut.rs`): Describes palette remapping tables for effects that replace source colors with target colors.
- `AdjacencyPair` (`struct`, `province_grid.rs`): Records that `province_a` and `province_b` share a border of `border_pixels` length (public fields).
- `ProvinceGrid` (`struct`, `province_grid.rs`): Flat `Vec<u32>` spatial index for province-colour maps. Built from an `ImageData` in a single O(w×h) scan; each unique non-black RGB is assigned a sequential province ID (1..n).
- `TextureColorSpace` (`enum`, `texture.rs`): Texture color space stored alongside decoded pixels.
- `Texture` (`struct`, `texture.rs`): A lightweight texture handle and metadata wrapper used when CPU image data is inserted into renderer-owned texture storage.
- `NineSliceInsets` (`struct`, `texture_atlas.rs`): Nine-slice border distances used to preserve corners and edges.
- `AtlasRegion` (`struct`, `texture_atlas.rs`): Describes the packed rectangle for one atlas entry.# `image` — Agent Reference
- `TextureAtlas` (`struct`, `texture_atlas.rs`): Owns atlas dimensions and packed regions for named sub-images that share one backing texture.

## Functions

- `CompressedFormat::as_str` (`compressed.rs`): Return the lowercase format label string for this variant.
- `CompressedImageData::from_dds` (`compressed.rs`): Decode DDS bytes into compressed image data or return a file-system error.
- `CompressedImageData::get_dimensions` (`compressed.rs`): Return the base image dimensions.
- `CompressedImageData::get_mipmap_count` (`compressed.rs`): Return the number of mipmap levels stored in this image.
- `CompressedImageData::get_format` (`compressed.rs`): Return the detected compressed format string.
- `CompressedImageData::is_dds_magic` (`compressed.rs`): Return whether the byte slice starts with the DDS magic header.
- `CompressedImageData::from_file` (`compressed.rs`): Read a DDS file from disk and decode it into compressed image data.
- `CompressedImageData::is_dds_file` (`compressed.rs`): Return whether a file on disk starts with the DDS magic header.
- `ResizeFilter::parse` (`effects.rs`): Parse a resize filter name and return the selected filter when recognized.
- `ImageData::brightness` (`effects.rs`): Scale RGB channels by a factor in place.
- `ImageData::contrast` (`effects.rs`): Adjust contrast around the midpoint in place.
- `ImageData::saturation` (`effects.rs`): Blend RGB channels toward luminance by the given factor.
- `ImageData::gamma` (`effects.rs`): Apply gamma correction to RGB channels in place.
- `ImageData::tint` (`effects.rs`): Blend RGB channels toward a tint color by the given factor.
- `ImageData::grayscale` (`effects.rs`): Convert the image to grayscale in place.
- `ImageData::sepia` (`effects.rs`): Apply a sepia tone in place.
- `ImageData::invert` (`effects.rs`): Invert the RGB channels in place.
- `ImageData::threshold` (`effects.rs`): Convert the image to a hard thresholded grayscale image.
- `ImageData::posterize` (`effects.rs`): Reduce color depth to the requested number of levels.
- `ImageData::fill` (`effects.rs`): Fill the whole image with a solid color.
- `ImageData::noise` (`effects.rs`): Add repeatable random noise to RGB channels.
- `ImageData::alpha_mask` (`effects.rs`): Scale the alpha channel by a factor in place.
- `ImageData::flip_horizontal` (`effects.rs`): Flip the image horizontally in place.
- `ImageData::flip_vertical` (`effects.rs`): Flip the image vertically in place.
- `ImageData::rotate_90_cw` (`effects.rs`): Return a new image rotated 90 degrees clockwise.
- `ImageData::crop` (`effects.rs`): Return a cropped copy of the image or `None` when the region is invalid.
- `ImageData::resize_nearest` (`effects.rs`): Resize the image with nearest-neighbor sampling.
- `ImageData::blur` (`effects.rs`): Blur the image with a separable box kernel and return a new image.
- `ImageData::sharpen` (`effects.rs`): Sharpen the image with a 3x3 kernel and return a new image.
- `ImageData::resize` (`effects.rs`): Resize the image with bilinear interpolation by default.
- `ImageData::resize_with_filter` (`effects.rs`): Resize the image with the requested filter and return `None` for zero-sized output.
- `ImageData::blit` (`effects.rs`): Blend another image into this image using alpha or overwrite when fully opaque.
- `ImageData::draw_nine_slice` (`effects.rs`): Draw a nine-slice region from a source image into this image.
- `ImageData::get_region` (`effects.rs`): Return a copied rectangular region or `None` when out of bounds.
- `ImageData::diff` (`effects.rs`): Compute a bytewise difference score between two images.
- `ImageData::convolve` (`effects.rs`): Convolve the image with a square kernel and return an error on invalid input.
- `ImageData::new` (`image_data.rs`): Create a zero-filled RGBA image buffer of the given size.
- `ImageData::from_file` (`image_data.rs`): Load an image from disk and return decoded RGBA bytes, or an error on failure.
- `ImageData::from_encoded_bytes` (`image_data.rs`): Decode an image from memory and return RGBA bytes, or an error on failure.
- `ImageData::from_bytes` (`image_data.rs`): Build an image from exact RGBA bytes, or return an error on length mismatch.
- `ImageData::width` (`image_data.rs`): Return the image width in pixels.
- `ImageData::height` (`image_data.rs`): Return the image height in pixels.
- `ImageData::dimensions` (`image_data.rs`): Return the image dimensions as width and height.
- `ImageData::get_pixel` (`image_data.rs`): Return the RGBA pixel at a coordinate, or `None` when out of bounds.
- `ImageData::set_pixel` (`image_data.rs`): Set a pixel at a coordinate and return false when the point is out of bounds.
- `ImageData::paste` (`image_data.rs`): Copy pixels from a source image into this image at the given offset.
- `ImageData::map_pixel` (`image_data.rs`): Map every pixel through a callback in place.
- `ImageData::draw_rect` (`image_data.rs`): Fill an axis-aligned rectangle with a solid color and alpha.
- `ImageData::draw_circle` (`image_data.rs`): Fill a circle with a solid color and alpha.
- `ImageData::draw_line` (`image_data.rs`): Draw a line with Bresenham's algorithm using a solid color and alpha.
- `ImageData::draw_label` (`image_data.rs`): Draw a small bitmap label for digits, letters, and a few punctuation marks.
- `ImageData::encode_png` (`image_data.rs`): Encode the image as PNG bytes and return an error on encode failure.
- `ImageData::as_bytes` (`image_data.rs`): Return a slice of the raw RGBA pixel bytes.
- `ImageData::get_string` (`image_data.rs`): Return a cloned copy of the raw RGBA pixel bytes.
- `ImageData::set_raw_data` (`image_data.rs`): Replace pixel data with new raw bytes and return an error on length mismatch.
- `ImageData::map_pixel_par` (`image_data.rs`): Map every pixel through a callback in place using parallel rows above the threshold.
- `ImageLayer::new` (`layers.rs`): Create a visible opaque layer with a blank canvas of the given size.
- `LayeredImage::new` (`layers.rs`): Create an empty layered image with the given canvas size.
- `LayeredImage::width` (`layers.rs`): Return the canvas width in pixels.
- `LayeredImage::height` (`layers.rs`): Return the canvas height in pixels.
- `LayeredImage::layer_count` (`layers.rs`): Return the number of layers in the stack.
- `LayeredImage::add_layer` (`layers.rs`): Append a new blank layer and return its index.
- `LayeredImage::remove_layer` (`layers.rs`): Remove a layer by index and return it when present.
- `LayeredImage::get_layer` (`layers.rs`): Return a layer by index.
- `LayeredImage::get_layer_mut` (`layers.rs`): Return a mutable layer by index.
- `LayeredImage::set_opacity` (`layers.rs`): Set a layer opacity and clamp it to the valid range.
- `LayeredImage::set_visible` (`layers.rs`): Set a layer visibility flag and return whether the layer existed.
- `LayeredImage::set_name` (`layers.rs`): Rename a layer and return whether the layer existed.
- `LayeredImage::set_layer_image` (`layers.rs`): Replace a layer image with a copied source image or a pasted canvas copy.
- `LayeredImage::swap_layers` (`layers.rs`): Swap two layers and return false when either index is invalid.
- `LayeredImage::move_layer` (`layers.rs`): Move a layer to another position and return false when either index is invalid.
- `LayeredImage::merge` (`layers.rs`): Merge visible layers front-to-back into a new image.
- `PaletteLUT::new` (`palette_lut.rs`): Create an empty palette lookup table.
- `PaletteLUT::get_color_count` (`palette_lut.rs`): Return the number of color pairs stored in the table.
- `PaletteLUT::set_color` (`palette_lut.rs`): Set a color pair at an index and grow the table when needed.
- `PaletteLUT::get_from_color` (`palette_lut.rs`): Return the source color at an index.
- `PaletteLUT::get_to_color` (`palette_lut.rs`): Return the replacement color at an index.
- `PaletteLUT::clear` (`palette_lut.rs`): Clear all stored color pairs.
- `PaletteLUT::cycle_to_colors` (`palette_lut.rs`): Rotate replacement colors by the requested offset.
- `PaletteLUT::apply` (`palette_lut.rs`): Apply the palette lookup to an image buffer in place.
- `ProvinceGrid::from_image` (`province_grid.rs`): Build a province grid from an image where non-black pixels define province ids.
- `ProvinceGrid::from_file` (`province_grid.rs`): Load an image from disk and derive province ids from it.
- `ProvinceGrid::width` (`province_grid.rs`): Return the grid width in pixels.
- `ProvinceGrid::height` (`province_grid.rs`): Return the grid height in pixels.
- `ProvinceGrid::get_at` (`province_grid.rs`): Return the province id at a coordinate, or `0` when out of bounds.
- `ProvinceGrid::province_count` (`province_grid.rs`): Return the highest province id present in the grid.
- `ProvinceGrid::province_color` (`province_grid.rs`): Return the RGB color associated with a province id, or `None` for id 0.
- `ProvinceGrid::adjacencies` (`province_grid.rs`): Return cached adjacency triples for the grid.
- `ProvinceGrid::province_spans` (`province_grid.rs`): Return horizontal spans for each province row segment.
- `ProvinceGrid::border_segments` (`province_grid.rs`): Return contiguous border segments between differing provinces.
- `ProvinceGrid::province_polygons` (`province_grid.rs`): Trace province polygons as ordered point loops.
- `ProvinceGrid::province_polygons_simplified` (`province_grid.rs`): Return simplified province polygons with redundant vertices removed.
- `ProvinceGrid::serialize_shape_data` (`province_grid.rs`): Serialize spans and border segments into a compact binary blob.
- `ProvinceGrid::deserialize_shape_data` (`province_grid.rs`): Decode serialized spans and border segments from a shape-data blob.
- `ImageData::generate_render_commands` (`render.rs`): Generate draw commands for this image buffer at the given screen position.
- `ImageData::draw_to_image` (`render.rs`): Clone the image buffer into a standalone image value.
- `save_image` (`serial.rs`): Save a flat [`ImageData`] to a LIMG binary file at the given path.
- `load_image` (`serial.rs`): Load a flat [`ImageData`] from a LIMG binary file.
- `load_image_from_bytes` (`serial.rs`): Load a flat image from raw LIMG bytes and validate the type flag.
- `save_layered` (`serial.rs`): Save a [`LayeredImage`] to a LIMG binary file at the given path.
- `load_layered` (`serial.rs`): Load a [`LayeredImage`] from a LIMG binary file.
- `load_layered_from_bytes` (`serial.rs`): Load a layered image from raw LIMG bytes and validate the type flag.
- `encode_flat` (`serial.rs`): Encode a flat [`ImageData`] into a complete LIMG binary blob.
- `decode_flat` (`serial.rs`): Decode the payload section of a flat LIMG blob.
- `parse_header` (`serial.rs`): Validate the LIMG header and return `(type_flag, payload_slice)`.
- `premultiply_alpha_rgba8_in_place` (`texture.rs`): Canonical CPU helper for premultiplying RGBA8 before texture upload.
- `Texture::parse_color_space` (`texture.rs`): Parse a texture color-space label and return the matching enum value.
- `Texture::load` (`texture.rs`): Load a texture with sRGB color space by default.
- `Texture::load_with_color_space` (`texture.rs`): Load a texture from disk, premultiply alpha, and store it in the texture pool.
- `Texture::from_rgba` (`texture.rs`): Create a texture from RGBA bytes using sRGB color space.
- `Texture::from_rgba_with_color_space` (`texture.rs`): Create a texture from RGBA bytes and store it in the texture pool.
- `TextureAtlas::new` (`texture_atlas.rs`): Create an empty atlas with the given dimensions and padding.
- `TextureAtlas::pack` (`texture_atlas.rs`): Pack a region without nine-slice metadata and return whether it fit.
- `TextureAtlas::pack_with_nine_slice` (`texture_atlas.rs`): Pack a region with optional nine-slice metadata and return whether it fit.
- `TextureAtlas::set_nine_slice` (`texture_atlas.rs`): Update the nine-slice metadata for a packed region and return whether it fit.
- `TextureAtlas::get_region` (`texture_atlas.rs`): Return a packed region by name.
- `TextureAtlas::get_region_count` (`texture_atlas.rs`): Return the number of packed regions.
- `TextureAtlas::get_dimensions` (`texture_atlas.rs`): Return the atlas dimensions.
- `TextureAtlas::get_regions` (`texture_atlas.rs`): Return all packed regions as borrowed values.
- `TextureAtlas::clear` (`texture_atlas.rs`): Remove all packed regions and shelves.
- `draw_animation_frame_grid_to_image` (`visualization/animation.rs`): Render an animation's frame grid as a strip of numbered cells.
- `draw_animation_playback_to_image` (`visualization/animation.rs`): Render an animation playback strip as snapshot columns.
- `animation_playback_control_to_image` (`visualization/animation.rs`): Render an animation playback-control timeline diagram.
- `draw_animation_to_image` (`visualization/animation.rs`): Render an animation as a CPU image for headless testing.
- `waveform_to_image` (`visualization/audio.rs`): Render audio samples as a waveform visualization.
- `waveform_stereo_to_image` (`visualization/audio.rs`): Render interleaved stereo audio samples as a two-channel waveform.
- `waveform_zoomed_to_image` (`visualization/audio.rs`): Render a zoomed-in waveform showing individual sample cycles.
- `draw_sound_waveform_to_image` (`visualization/audio.rs`): Draw a single waveform as a colored plot on a dark background.
- `draw_camera_debug_to_image` (`visualization/camera.rs`): Render a camera debug visualization showing viewport, position, and zoom.
- `draw_camera_zoom_comparison_to_image` (`visualization/camera.rs`): Render a zoom comparison showing the world at multiple zoom levels.
- `camera_rotation_to_image` (`visualization/camera.rs`): Render six camera rotation steps in a 3-column grid.
- `camera_bounds_to_image` (`visualization/camera.rs`): Render a camera bounds-clamping summary panel.
- `camera_follow_to_image` (`visualization/camera.rs`): Render a camera follow-and-deadzone trail diagram.
- `camera_shake_to_image` (`visualization/camera.rs`): Render a camera shake trail and move-by result.
- `draw_camera_rotation_grid_to_image` (`visualization/camera.rs`): Render a grid of camera rotation panels, each showing 8 coloured dots transformed through the rotation.
- `draw_camera_bounds_to_image` (`visualization/camera.rs`): Render a set of camera positions as labelled coloured rectangles.
- `draw_camera_follow_trail_to_image` (`visualization/camera.rs`): Render a camera follow trail with target points and dead-zone rectangle.
- `draw_camera_shake_trail_to_image` (`visualization/camera.rs`): Render a camera shake trail with fading circles and reference markers.
- `draw_camera_to_image` (`visualization/camera.rs`): Render a camera as a CPU image for headless testing.
- `easing_gallery_to_image` (`visualization/easing.rs`): Render a gallery of easing curves as a grid of small charts.
- `easing_comparison_to_image` (`visualization/easing.rs`): Render multiple easing curves overlaid on a single chart.
- `bezier_curves_to_image` (`visualization/easing.rs`): Render multiple cubic Bezier curves with control-point overlays.
- `draw_bezier_advanced_to_image` (`visualization/easing.rs`): Draw a bezier advanced operations overview.
- `hsv_to_rgb_viz` (`visualization/facade.rs`): Convert HSV colour to RGB bytes.
- `polygon_gallery_to_image` (`visualization/geometry.rs`): Render a gallery of regular polygons (triangle→dodecagon), a five-pointed star, and an arrow shape using `draw_line`.
- `spiral_to_image` (`visualization/geometry.rs`): Render concentric colored circles to demonstrate angular segment drawing.
- `filled_primitives_to_image` (`visualization/geometry.rs`): Render filled rectangle and circle primitives with HSV-coloured fills.
- `draw_geometry_shapes_to_image` (`visualization/geometry.rs`): Draw a comprehensive geometry shapes & queries visualization.
- `draw_geometry_intersections_to_image` (`visualization/geometry.rs`): Draw geometry intersection tests visualization.
- `draw_graph_operations_to_image` (`visualization/graph.rs`): Render a graph with explicit node positions, labels, edge list, and stats.
- `draw_graph_item_flow_to_image` (`visualization/graph.rs`): Render a pipeline graph with nodes, directional pipes, and item indicators.
- `draw_image_comparison_to_image` (`visualization/image_ops.rs`): Draw a side-by-side comparison of multiple images.
- `draw_pixel_transform_grid_to_image` (`visualization/image_ops.rs`): Draw a 4-column pixel transform grid: original, invert, grayscale, sepia.
- `draw_color_wheel_to_image` (`visualization/image_ops.rs`): Draw an HSV colour wheel.
- `noise_to_image` (`visualization/noise.rs`): Render a 2D noise function to a grayscale image.
- `noise_raw_to_image` (`visualization/noise.rs`): Render a 2D noise function where the output is already in `[0,1]` range.
- `noise_terrain_to_image` (`visualization/noise.rs`): Render a 2D noise function as a terrain-colored image.
- `heightmap_to_image` (`visualization/noise.rs`): Render a flat heightmap buffer as a colored elevation image.
- `terrain_elevation_to_image` (`visualization/noise.rs`): Render a flat heightmap buffer with terrain-band coloring.
- `noise_map_to_image` (`visualization/noise.rs`): Render a noise map buffer as a grayscale image (normalised `[-1,1]` → `[0,255]`).
- `noise_comparison_to_image` (`visualization/noise.rs`): Render multiple noise maps side by side as a horizontal strip.
- `cellular_grid_to_image` (`visualization/procgen.rs`): Render a cellular automata grid (1=alive, 0=dead) as a scaled image.
- `voronoi_to_image` (`visualization/procgen.rs`): Render a Voronoi region map as a colored image.
- `points_to_image` (`visualization/procgen.rs`): Render a set of 2D points as dots on a dark background.
- `dungeon_grid_to_image` (`visualization/procgen.rs`): Render a BSP dungeon grid (0=floor, 1=wall) as a scaled tile image.
- `colored_points_to_image` (`visualization/procgen.rs`): Render a set of 2-D points, each colored by its index in the list.
- `draw_delaunay_to_image` (`visualization/procgen.rs`): Draw Delaunay triangulation visualization.
- `panel_layout_to_image` (`visualization/ui.rs`): Render a mock settings panel with title bar, sliders, checkboxes, radio buttons, progress bar, colour swatches, and action buttons.
- `hud_bars_to_image` (`visualization/ui.rs`): Render a game HUD with HP/MP/Stamina/XP bars and skill cooldown indicators.

## Lua API Reference

- Binding path(s): `src/lua_api/image_api.rs`
- Namespace: `lurek.image`

### Module Functions
- `lurek.image.newImageData`: Creates empty image data from dimensions or decodes image data from a GameFS filename.
- `lurek.image.newImageDataFromBytes`: Creates image data from raw RGBA bytes and explicit dimensions.
- `lurek.image.newCompressedData`: Loads DDS compressed image data from GameFS.
- `lurek.image.isCompressed`: Returns whether a GameFS image file begins with DDS compressed image magic bytes.
- `lurek.image.newLayeredImage`: Creates a layered image stack with one or more blank layers.
- `lurek.image.saveImage`: Saves an image data object to a path under the current game directory.
- `lurek.image.savePNG`: Encodes image data as PNG and writes it under the current game directory.
- `lurek.image.loadImage`: Loads and decodes image data from GameFS.
- `lurek.image.loadLayered`: Loads a serialized layered image stack from GameFS.
- `lurek.image.newPaletteLut`: Creates an empty palette lookup table.
- `lurek.image.newProvinceGrid`: Loads a province id grid from an image file under the current game directory.
- `lurek.image.fromScreen`: Returns a completed screen capture image or requests one for a future call.

### `LCompressedImageData` Methods
- `LCompressedImageData:getWidth`: Returns compressed image width.
- `LCompressedImageData:getHeight`: Returns compressed image height.
- `LCompressedImageData:getDimensions`: Returns compressed image dimensions.
- `LCompressedImageData:getMipmapCount`: Returns the number of mipmap levels in this compressed image.
- `LCompressedImageData:getFormat`: Returns the compressed image format name.
- `LCompressedImageData:type`: Returns the Lua-visible type name for this compressed image handle.
- `LCompressedImageData:typeOf`: Returns whether this compressed image handle matches a supported type name.

### `LImageData` Methods
- `LImageData:getWidth`: Returns image width.
- `LImageData:getHeight`: Returns image height.
- `LImageData:getDimensions`: Returns image dimensions.
- `LImageData:getPixel`: Returns RGBA channels at a pixel coordinate.
- `LImageData:setPixel`: Sets RGBA channels at a pixel coordinate.
- `LImageData:encode`: Encodes image data in a supported format.
- `LImageData:getString`: Returns raw image bytes as a Lua string.
- `LImageData:mapPixel`: Applies a Lua callback to every pixel and replaces each pixel with returned RGBA values.
- `LImageData:brightness`: Applies a brightness factor to this image in place.
- `LImageData:contrast`: Applies a contrast factor to this image in place.
- `LImageData:saturation`: Applies a saturation factor to this image in place.
- `LImageData:gamma`: Applies gamma correction to this image in place.
- `LImageData:tint`: Blends this image toward a tint color in place.
- `LImageData:grayscale`: Converts this image to grayscale in place.
- `LImageData:sepia`: Applies a sepia filter to this image in place.
- `LImageData:invert`: Inverts image color channels in place.
- `LImageData:threshold`: Applies a threshold filter to this image in place.
- `LImageData:posterize`: Reduces image colors to a fixed number of levels in place.
- `LImageData:fill`: Fills the whole image with one RGBA color.
- `LImageData:noise`: Adds noise to this image in place.
- `LImageData:alphaMask`: Multiplies this image alpha channel by a factor in place.
- `LImageData:flipHorizontal`: Flips this image horizontally in place.
- `LImageData:flipVertical`: Flips this image vertically in place.
- `LImageData:rotate90cw`: Returns a new image rotated ninety degrees clockwise.
- `LImageData:crop`: Returns a cropped image region.
- `LImageData:resizeNearest`: Returns a resized image using nearest-neighbor sampling.
- `LImageData:blur`: Returns a blurred copy of this image.
- `LImageData:sharpen`: Returns a sharpened copy of this image.
- `LImageData:drawRect`: Draws a filled rectangle into this image.
- `LImageData:drawCircle`: Draws a filled circle into this image.
- `LImageData:drawLine`: Draws a line into this image.
- `LImageData:resize`: Returns a resized image using an optional named filter.
- `LImageData:blit`: Copies a source image into this image at a destination coordinate.
- `LImageData:drawNineSlice`: Draws a nine-slice region from a source image into this image.
- `LImageData:getRegion`: Returns an image region when the requested rectangle is inside bounds.
- `LImageData:getRawBytes`: Returns raw image bytes as a Lua string.
- `LImageData:diff`: Computes a difference metric against another image.
- `LImageData:mapPixels`: Applies a Lua callback to every pixel and replaces each pixel with returned RGBA values.
- `LImageData:convolve`: Applies a convolution kernel and returns the filtered image.
- `LImageData:applyPaletteLut`: Applies a palette lookup table to this image in place.
- `LImageData:setRawData`: Replaces the image byte buffer with raw bytes.
- `LImageData:paste`: Pastes a source image into this image at unsigned destination coordinates.
- `LImageData:type`: Returns the Lua-visible type name for this image data handle.
- `LImageData:typeOf`: Returns whether this image data handle matches the `ImageData` type name.

### `LLayeredImage` Methods
- `LLayeredImage:getWidth`: Returns the layered image width.
- `LLayeredImage:getHeight`: Returns the layered image height.
- `LLayeredImage:layerCount`: Returns the number of layers in the stack.
- `LLayeredImage:addLayer`: Adds a blank layer with an optional name.
- `LLayeredImage:removeLayer`: Removes a layer by one-based index.
- `LLayeredImage:getLayer`: Returns image data for a layer by one-based index.
- `LLayeredImage:setLayer`: Replaces a layer's image data by one-based index.
- `LLayeredImage:getOpacity`: Returns a layer opacity by one-based index.
- `LLayeredImage:setOpacity`: Sets a layer opacity by one-based index.
- `LLayeredImage:isVisible`: Returns layer visibility by one-based index.
- `LLayeredImage:setVisible`: Sets layer visibility by one-based index.
- `LLayeredImage:getName`: Returns a layer name by one-based index.
- `LLayeredImage:setName`: Sets a layer name by one-based index.
- `LLayeredImage:swapLayers`: Swaps two layers by one-based indices.
- `LLayeredImage:moveLayer`: Moves a layer from one one-based index to another.
- `LLayeredImage:merge`: Merges visible layers into a single image data object.
- `LLayeredImage:save`: Saves the layered image stack to a file.
- `LLayeredImage:type`: Returns the Lua-visible type name for this layered image handle.
- `LLayeredImage:typeOf`: Returns whether this layered image handle matches a supported type name.

### `LPaletteLUT` Methods
- `LPaletteLUT:setColor`: Adds a color mapping from source RGBA channels to destination RGBA channels.
- `LPaletteLUT:getColorCount`: Returns the number of color mappings in this palette lookup table.
- `LPaletteLUT:clear`: Removes every color mapping from this palette lookup table.
- `LPaletteLUT:cycle`: Cycles palette mappings by an offset.
- `LPaletteLUT:type`: Returns the Lua-visible type name for this palette lookup table handle.
- `LPaletteLUT:typeOf`: Returns whether this palette lookup table handle matches a supported type name.

### `LProvinceGrid` Methods
- `LProvinceGrid:getWidth`: Returns the province grid width.
- `LProvinceGrid:getHeight`: Returns the province grid height.
- `LProvinceGrid:getAt`: Returns the province id stored at grid coordinates.
- `LProvinceGrid:provinceCount`: Returns the number of distinct provinces in the grid.
- `LProvinceGrid:adjacencies`: Returns province adjacency records and shared border pixel counts.
- `LProvinceGrid:provinceSpans`: Returns horizontal province spans by row.
- `LProvinceGrid:borderSegments`: Returns border line segments between neighboring provinces.
- `LProvinceGrid:getPolygons`: Returns polygon rings for every province.
- `LProvinceGrid:getPolygonsSimplified`: Returns simplified polygon rings for every province.
- `LProvinceGrid:drawShapes`: Queues filled polygon draw commands for province shapes, optionally culled to a viewport.
- `LProvinceGrid:type`: Returns the Lua-visible type name for this province grid handle.
- `LProvinceGrid:typeOf`: Returns whether this province grid handle matches a supported type name.
- `LProvinceGrid:serializeShapeData`: Serializes province span and border shape data into a binary Lua string.
- `LProvinceGrid:deserializeShapeData`: Decodes serialized province shape data into span and segment tables.

## References

- `animation`: Imports or references `animation` from `src/animation/`.
- `camera`: Imports or references `camera` from `src/camera/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/image/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
### New in 0.14.2

- `ProvinceGrid` — new type in `province_grid.rs`. Flat `Vec<u32>` spatial index built from a province-colour PNG in a single O(w×h) scan. Replaces the 2–8 s Lua `pixel_lookup` hash construction with ~15–30 ms Rust scan for 2400×1200 maps.
- `lurek.image.newProvinceGrid(filename)` — registered in `image_api.rs`, returns `LuaProvinceGrid` userdata with `getWidth`, `getHeight`, `getAt`, `provinceCount`, `adjacencies` methods.
- `content/library/province_map`: new `M.newFromPng(png_path, defs)` constructor uses `lurek.image.newProvinceGrid` when available; all prior constructors and logic unchanged.
### New in 0.14.1

- 11 pixel transforms now use `map_pixel_par` (rayon, 65 536-pixel threshold): `brightness`, `contrast`, `saturation`, `gamma`, `tint`, `grayscale`, `sepia`, `invert`, `threshold`, `posterize`, `fill`.
- `tint()` refactored to inline closure for `Send + Sync` compliance.
- `threshold()` and `posterize()` use `move` closures to capture `Copy` values.
