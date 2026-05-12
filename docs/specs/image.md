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
- `ImageData` (`struct`, `image_data.rs`): The main CPU image container. It is the module's central type for pixel storage, file decode/encode, primitive drawing, and effect application.
- `ImageLayer` (`struct`, `layers.rs`): Represents a single named layer with visibility, opacity, and its own `ImageData` backing store.
- `LayeredImage` (`struct`, `layers.rs`): Owns an ordered stack of `ImageLayer` values and merges them into a flat image when callers need a composited result.
- `PaletteLUT` (`struct`, `palette_lut.rs`): Describes palette remapping tables for effects that replace source colors with target colors.
- `AdjacencyPair` (`struct`, `province_grid.rs`): Records that `province_a` and `province_b` share a border of `border_pixels` length (public fields).
- `ProvinceGrid` (`struct`, `province_grid.rs`): Flat `Vec<u32>` spatial index for province-colour maps. Built from an `ImageData` in a single O(w×h) scan; each unique non-black RGB is assigned a sequential province ID (1..n).
- `Texture` (`struct`, `texture.rs`): A lightweight texture handle and metadata wrapper used when CPU image data is inserted into renderer-owned texture storage.
- `AtlasRegion` (`struct`, `texture_atlas.rs`): Describes the packed rectangle for one atlas entry.# `image` — Agent Reference
- `TextureAtlas` (`struct`, `texture_atlas.rs`): Owns atlas dimensions and packed regions for named sub-images that share one backing texture.

## Functions

- `CompressedFormat::as_str` (`compressed.rs`): Return the Lua-facing format name string.
- `CompressedImageData::from_dds` (`compressed.rs`): Load compressed texture data from DDS file bytes.
- `CompressedImageData::get_dimensions` (`compressed.rs`): Return image dimensions as `(width, height)`.
- `CompressedImageData::get_mipmap_count` (`compressed.rs`): Return the number of mipmap levels stored.
- `CompressedImageData::get_format` (`compressed.rs`): Return the Lua-facing format name string.
- `CompressedImageData::is_dds_magic` (`compressed.rs`): Check whether the given bytes start with the DDS magic number (`0x44 0x44 0x53 0x20`).
- `CompressedImageData::from_file` (`compressed.rs`): Load compressed texture data from a DDS file on disk.
- `CompressedImageData::is_dds_file` (`compressed.rs`): Check whether the file at `path` starts with the DDS magic number.
- `ImageData::brightness` (`effects.rs`): Multiply every RGB channel by `factor`, leaving alpha unchanged.
- `ImageData::contrast` (`effects.rs`): Adjust the contrast of every RGB channel, leaving alpha unchanged.
- `ImageData::saturation` (`effects.rs`): Scale the colour saturation of every pixel, leaving alpha unchanged.
- `ImageData::gamma` (`effects.rs`): Apply gamma correction to every RGB channel, leaving alpha unchanged.
- `ImageData::tint` (`effects.rs`): Blend every RGB pixel toward a target tint colour, leaving alpha unchanged.
- `ImageData::grayscale` (`effects.rs`): Convert every pixel to greyscale using perceptual luminance weights, leaving alpha unchanged.
- `ImageData::sepia` (`effects.rs`): Apply a classic sepia-tone filter to every pixel, leaving alpha unchanged.
- `ImageData::invert` (`effects.rs`): Invert every RGB channel (`new = 255 - ch`), leaving alpha unchanged.
- `ImageData::threshold` (`effects.rs`): Convert each pixel to black or white based on its luminance, leaving alpha unchanged.
- `ImageData::posterize` (`effects.rs`): Reduce the number of distinct colour levels per channel, leaving alpha unchanged.
- `ImageData::fill` (`effects.rs`): Fill the entire image with a single solid colour.
- `ImageData::noise` (`effects.rs`): Add pseudo-random noise to every RGB channel, leaving alpha unchanged.
- `ImageData::alpha_mask` (`effects.rs`): Multiply the alpha channel of every pixel by `factor`, leaving RGB unchanged.
- `ImageData::flip_horizontal` (`effects.rs`): Flip the image horizontally in-place (left ↔ right mirror).
- `ImageData::flip_vertical` (`effects.rs`): Flip the image vertically in-place (top ↔ bottom mirror).
- `ImageData::rotate_90_cw` (`effects.rs`): Rotate the image 90° clockwise and return the result as a new `ImageData`.
- `ImageData::crop` (`effects.rs`): Extract a rectangular sub-region and return it as a new `ImageData`.
- `ImageData::resize_nearest` (`effects.rs`): Scale the image to new dimensions using nearest-neighbour interpolation.
- `ImageData::blur` (`effects.rs`): Apply a box blur with the given radius and return the result as a new `ImageData`.
- `ImageData::sharpen` (`effects.rs`): Apply a 3×3 sharpen kernel and return the result as a new `ImageData`.
- `ImageData::resize` (`effects.rs`): Scale the image to new dimensions using bilinear interpolation.
- `ImageData::blit` (`effects.rs`): Blit (composite) `src` onto this image at `(dst_x, dst_y)` using Porter-Duff *over*.
- `ImageData::get_region` (`effects.rs`): Extract a rectangular sub-region and return it as a new `ImageData`.
- `ImageData::diff` (`effects.rs`): Compute the total absolute per-channel difference between two images.
- `ImageData::convolve` (`effects.rs`): Apply an arbitrary NxN convolution kernel to the RGB channels and return a new `ImageData`.
- `ImageData::new` (`image_data.rs`): Create a new blank (transparent black) image.
- `ImageData::from_file` (`image_data.rs`): Load an image from a file path.
- `ImageData::from_bytes` (`image_data.rs`): Create from raw RGBA bytes.
- `ImageData::width` (`image_data.rs`): Get the width of the image.
- `ImageData::height` (`image_data.rs`): Get the height of the image.
- `ImageData::dimensions` (`image_data.rs`): Get both dimensions.
- `ImageData::get_pixel` (`image_data.rs`): Get the RGBA values of a pixel at (x, y).
- `ImageData::set_pixel` (`image_data.rs`): Set the RGBA values of a pixel at (x, y).
- `ImageData::paste` (`image_data.rs`): Paste source image onto self at position (dx, dy).
- `ImageData::map_pixel` (`image_data.rs`): Apply a function to every pixel, replacing each (r,g,b,a) with the return value.
- `ImageData::draw_rect` (`image_data.rs`): Draw a filled rectangle onto the image.
- `ImageData::draw_circle` (`image_data.rs`): Draw a filled circle onto the image.
- `ImageData::draw_line` (`image_data.rs`): Draw a line using Bresenham's algorithm.
- `ImageData::draw_label` (`image_data.rs`): Draw a text label using a built-in 3×5 pixel font.
- `ImageData::encode_png` (`image_data.rs`): Encode the image as PNG bytes.
- `ImageData::as_bytes` (`image_data.rs`): Get a reference to the raw pixel bytes.
- `ImageData::get_string` (`image_data.rs`): Get the raw pixel bytes as a vector (for Lua getString() compatibility).
- `ImageData::set_raw_data` (`image_data.rs`): Replace all pixel data from a raw RGBA byte slice.
- `ImageData::map_pixel_par` (`image_data.rs`): Apply a per-pixel transform in parallel for large images.
- `ImageLayer::new` (`layers.rs`): Create a new transparent layer with the given canvas dimensions.
- `LayeredImage::new` (`layers.rs`): Create an empty layer stack with no layers.
- `LayeredImage::width` (`layers.rs`): Canvas width shared by all layers.
- `LayeredImage::height` (`layers.rs`): Canvas height shared by all layers.
- `LayeredImage::layer_count` (`layers.rs`): Number of layers currently in the stack.
- `LayeredImage::add_layer` (`layers.rs`): Append a new blank (transparent) layer on top of the stack and return its index.
- `LayeredImage::remove_layer` (`layers.rs`): Remove the layer at the given index and return it.
- `LayeredImage::get_layer` (`layers.rs`): Immutable access to a layer by index.
- `LayeredImage::get_layer_mut` (`layers.rs`): Mutable access to a layer by index.
- `LayeredImage::set_opacity` (`layers.rs`): Set the opacity of a layer.
- `LayeredImage::set_visible` (`layers.rs`): Set the visibility of a layer.
- `LayeredImage::set_name` (`layers.rs`): Rename a layer.
- `LayeredImage::set_layer_image` (`layers.rs`): Replace a layer's pixel buffer with a clone of the given [`ImageData`].
- `LayeredImage::swap_layers` (`layers.rs`): Swap two layers by index within the stack, changing their compositing order.
- `LayeredImage::move_layer` (`layers.rs`): Move a layer from `from_index` to `to_index`, shifting all layers in between.
- `LayeredImage::merge` (`layers.rs`): Flatten all visible layers into a single [`ImageData`] using Porter-Duff "over" compositing.
- `PaletteLUT::new` (`palette_lut.rs`): Creates an empty palette lookup table.
- `PaletteLUT::get_color_count` (`palette_lut.rs`): Returns the number of color mappings.
- `PaletteLUT::set_color` (`palette_lut.rs`): Sets the color mapping at the given 0-based index.
- `PaletteLUT::get_from_color` (`palette_lut.rs`): Returns the source color at the given 0-based index, if it exists.
- `PaletteLUT::get_to_color` (`palette_lut.rs`): Returns the target color at the given 0-based index, if it exists.
- `PaletteLUT::clear` (`palette_lut.rs`): Removes all color mappings.
- `PaletteLUT::apply` (`palette_lut.rs`): Applies this palette lookup table to an image in place.
- `ProvinceGrid::from_image` (`province_grid.rs`): Build a `ProvinceGrid` from an already-loaded [`ImageData`].
- `ProvinceGrid::from_file` (`province_grid.rs`): Load a province map PNG from disk and build the grid.
- `ProvinceGrid::width` (`province_grid.rs`): Returns the grid width in pixels.
- `ProvinceGrid::height` (`province_grid.rs`): Returns the grid height in pixels.
- `ProvinceGrid::get_at` (`province_grid.rs`): Returns the province ID at pixel coordinates `(x, y)`.
- `ProvinceGrid::province_count` (`province_grid.rs`): Returns the number of unique non-zero province IDs in the grid.
- `ProvinceGrid::adjacencies` (`province_grid.rs`): Returns a slice of `(province_a, province_b, border_pixel_count)` tuples, sorted by `(province_a, province_b)`.
- `ProvinceGrid::province_spans` (`province_grid.rs`): Returns horizontal fill spans for all non-zero provinces.
- `ProvinceGrid::border_segments` (`province_grid.rs`): Returns merged border segments between neighboring provinces.
- `ProvinceGrid::province_polygons` (`province_grid.rs`): Returns province polygon loops built from border pixel corner points (top-left corner grid).
- `ProvinceGrid::province_polygons_simplified` (`province_grid.rs`): Returns polygon loops simplified by removing collinear points and 45-degree staircase midpoints.
- `ProvinceGrid::serialize_shape_data` (`province_grid.rs`): Serializes province geometry for shape-based rendering into a binary cache.
- `ProvinceGrid::deserialize_shape_data` (`province_grid.rs`): Deserializes province geometry from shape cache binary.
- `ImageData::generate_render_commands` (`render.rs`): Generate a single `DrawImage` render command for this image.
- `ImageData::draw_to_image` (`render.rs`): Return a CPU copy of this image (identity draw-to-image).
- `save_image` (`serial.rs`): Save a flat [`ImageData`] to a LIMG binary file at the given path.
- `load_image` (`serial.rs`): Load a flat [`ImageData`] from a LIMG binary file.
- `save_layered` (`serial.rs`): Save a [`LayeredImage`] to a LIMG binary file at the given path.
- `load_layered` (`serial.rs`): Load a [`LayeredImage`] from a LIMG binary file.
- `encode_flat` (`serial.rs`): Encode a flat [`ImageData`] into a complete LIMG binary blob.
- `decode_flat` (`serial.rs`): Decode the payload section of a flat LIMG blob.
- `parse_header` (`serial.rs`): Validate the LIMG header and return `(type_flag, payload_slice)`.
- `Texture::load` (`texture.rs`): Loads an image from `path`, premultiplies alpha, and appends it to `textures`.
- `Texture::load_with_color_space` (`texture.rs`): Loads an image from `path` with explicit `srgb`/`linear` GPU format hint.
- `Texture::from_rgba` (`texture.rs`): Creates a texture from raw RGBA pixel data (not premultiplied).
- `Texture::from_rgba_with_color_space` (`texture.rs`): Creates a texture from raw RGBA pixel data with explicit `srgb`/`linear` hint.
- `premultiply_alpha_rgba8_in_place` (`texture.rs`): Canonical CPU helper for premultiplying RGBA8 before texture upload.
- `TextureAtlas::new` (`texture_atlas.rs`): Creates an empty atlas with the given pixel dimensions and inter-region padding.
- `TextureAtlas::pack` (`texture_atlas.rs`): Packs a named region of size `w` x `h` into the atlas.
- `TextureAtlas::pack_with_nine_slice` (`texture_atlas.rs`): Packs a named region with optional nine-slice insets.
- `TextureAtlas::set_nine_slice` (`texture_atlas.rs`): Sets or clears nine-slice metadata for an existing region.
- `TextureAtlas::get_region` (`texture_atlas.rs`): Looks up a previously packed region by name.
- `TextureAtlas::get_region_count` (`texture_atlas.rs`): Returns the number of packed regions.
- `TextureAtlas::get_dimensions` (`texture_atlas.rs`): Returns the atlas dimensions as `(width, height)`.
- `TextureAtlas::get_regions` (`texture_atlas.rs`): Returns all packed regions in arbitrary order.
- `TextureAtlas::clear` (`texture_atlas.rs`): Removes all packed regions and shelves.
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
- `lurek.image.newImageData`: Creates a new blank ImageData or loads one from a file.
- `lurek.image.newImageDataFromBytes`: Creates an ImageData from a raw RGBA8 byte string. Width Ă— height Ă— 4 bytes required.
- `lurek.image.newCompressedData`: Loads compressed texture data from a DDS file.
- `lurek.image.isCompressed`: Returns true if the file at the given path is a DDS file.
- `lurek.image.newLayeredImage`: Creates a new empty LayeredImage canvas with no layers.
- `lurek.image.saveImage`: Saves a flat ImageData to a LIMG binary file at the given path.
- `lurek.image.savePNG`: Saves a flat ImageData as a PNG file at the given path.
- `lurek.image.loadImage`: Loads an ImageData from a LIMG binary file.
- `lurek.image.loadLayered`: Loads a LayeredImage from a LIMG binary file.
- `lurek.image.newPaletteLut`: Creates a new empty `PaletteLUT` used to remap colours in an image.
- `lurek.image.newProvinceGrid`: Loads a province map PNG and builds an O(1) spatial index with adjacency data.
- `lurek.image.fromScreen`: Returns captured framebuffer `ImageData` when ready, or nil and queues capture for the next frame.

### `LCompressedImageData` Methods
- `LCompressedImageData:getWidth`: Returns the width of the base mip level in pixels.
- `LCompressedImageData:getHeight`: Returns the height of the base mip level in pixels.
- `LCompressedImageData:getDimensions`: Returns the width and height of the base mip level.
- `LCompressedImageData:getMipmapCount`: Returns the number of mipmap levels stored.
- `LCompressedImageData:getFormat`: Returns the compressed format name string.
- `LCompressedImageData:type`: Returns the type name of this object.
- `LCompressedImageData:typeOf`: Returns true if this object is of the given type.

### `LImageData` Methods
- `LImageData:getWidth`: Returns the width of the image in pixels.
- `LImageData:getHeight`: Returns the height of the image in pixels.
- `LImageData:getDimensions`: Returns the width and height of the image as two integers.
- `LImageData:getPixel`: Returns the RGBA colour components of the pixel at (x, y) as four integers (0-255).
- `LImageData:setPixel`: Sets the RGBA colour of the pixel at (x, y); returns an error if coordinates are out of bounds.
- `LImageData:encode`: Encodes the image into a byte string in the specified format (currently "png").
- `LImageData:getString`: Returns the raw pixel bytes of the image as a Lua string.
- `LImageData:mapPixel`: Calls func(x, y, r, g, b, a) for each pixel and writes the returned RGBA back.
- `LImageData:brightness`: Adjusts the brightness of every pixel by the given factor (< 1.0 darkens, > 1.0 brightens).
- `LImageData:contrast`: Adjusts the contrast of every pixel by the given factor (< 1.0 reduces, > 1.0 increases).
- `LImageData:saturation`: Adjusts colour saturation; 0.0 produces grayscale, 1.0 is unchanged, > 1.0 boosts saturation.
- `LImageData:gamma`: Applies gamma correction; values < 1.0 brighten shadows, > 1.0 darken them.
- `LImageData:tint`: Blends an RGB tint colour into every pixel, controlled by factor (0.0 = no change, 1.0 = full tint).
- `LImageData:grayscale`: Converts the image to grayscale using luminance weights (BT.601).
- `LImageData:sepia`: Applies a warm sepia tone to the image using standard sepia matrix weights.
- `LImageData:invert`: Inverts every colour channel (subtracts each R/G/B value from 255); alpha is preserved.
- `LImageData:threshold`: Converts the image to black-and-white: pixels above value become white, at or below become black.
- `LImageData:posterize`: Reduces each channel to `levels` discrete steps, creating a flat poster-paint look.
- `LImageData:fill`: Fills every pixel with the given solid RGBA colour, overwriting all existing content.
- `LImageData:noise`: Adds random noise to every pixel channel; amount controls the maximum per-channel perturbation.
- `LImageData:alphaMask`: Scales every pixel's alpha channel by factor; use to fade an image in or out uniformly.
- `LImageData:flipHorizontal`: Flips the image left-to-right (mirror across vertical axis), modifying in place.
- `LImageData:flipVertical`: Flips the image top-to-bottom (mirror across horizontal axis), modifying in place.
- `LImageData:rotate90cw`: Returns a new ImageData rotated 90 degrees clockwise; the original is not modified.
- `LImageData:crop`: Returns a new ImageData containing the rectangular sub-region at (x, y) of the given width and height.
- `LImageData:resizeNearest`: Returns a new ImageData scaled to (new_w, new_h) using nearest-neighbour interpolation.
- `LImageData:blur`: Returns a new ImageData with a box blur applied using the given pixel radius.
- `LImageData:sharpen`: Returns a new ImageData with a sharpening convolution kernel applied.
- `LImageData:drawRect`: Draws a filled rectangle onto the image.
- `LImageData:drawCircle`: Draws a filled circle onto the image.
- `LImageData:drawLine`: Draws a line using Bresenham's algorithm.
- `LImageData:resize`: Returns an interpolated copy of the image at the given dimensions (default `bilinear`, optional `lanczos3`).
- `LImageData:blit`: Blits the source ImageData onto this image at (dst_x, dst_y) using Porter-Duff over.
- `LImageData:getRegion`: Returns a copy of the rectangular sub-region as a new ImageData.
- `LImageData:getRawBytes`: Returns the raw RGBA8 pixel data as a Lua string (width Ă— height Ă— 4 bytes).
- `LImageData:diff`: Returns the sum of absolute per-channel pixel differences with another ImageData.
- `LImageData:mapPixels`: Applies a function to every pixel in-place.
- `LImageData:convolve`: Applies a custom NxN convolution kernel to the image and returns a new ImageData.
- `LImageData:applyPaletteLut`: Applies a `PaletteLUT` to the image in place, replacing exact colour matches.
- `LImageData:drawNineSlice`: Draws a nine-slice patch from atlas/source image data into this image.
- `LImageData:setRawData`: Replaces all pixel data from a raw RGBA byte string.
- `LImageData:paste`: Copies pixels from `source` onto this image starting at (dx, dy).
- `LImageData:type`: Returns the type name of this object.
- `LImageData:typeOf`: Returns true if this object is of the given type name.

### `LLayeredImage` Methods
- `LLayeredImage:getWidth`: Returns the canvas width shared by all layers.
- `LLayeredImage:getHeight`: Returns the canvas height shared by all layers.
- `LLayeredImage:layerCount`: Returns the number of layers in the stack.
- `LLayeredImage:addLayer`: Appends a new blank transparent layer on top and returns its 1-based index.
- `LLayeredImage:removeLayer`: Removes the layer at the given 1-based index. Returns true on success.
- `LLayeredImage:getLayer`: Returns a copy of the layer's pixel buffer as an ImageData.
- `LLayeredImage:setLayer`: Replaces a layer's pixel buffer with a copy of the given ImageData.
- `LLayeredImage:getOpacity`: Returns the opacity of a layer in [0.0, 1.0].
- `LLayeredImage:setOpacity`: Sets the opacity of a layer. Value is clamped to [0.0, 1.0].
- `LLayeredImage:isVisible`: Returns whether a layer is visible.
- `LLayeredImage:setVisible`: Shows or hides a layer during compositing.
- `LLayeredImage:getName`: Returns the name of a layer.
- `LLayeredImage:setName`: Renames the layer at the given index to the new name string.
- `LLayeredImage:swapLayers`: Swaps two layers by their 1-based indices, changing their compositing order.
- `LLayeredImage:moveLayer`: Moves a layer from one position to another, shifting layers in between.
- `LLayeredImage:merge`: Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
- `LLayeredImage:save`: Saves the layered image to a LIMG binary file at the given path.
- `LLayeredImage:type`: Returns the type name of this object.
- `LLayeredImage:typeOf`: Returns true if this object is of the given type.

### `LPaletteLUT` Methods
- `LPaletteLUT:setColor`: Appends a colour mapping entry to the palette: when a pixel exactly matching
- `LPaletteLUT:getColorCount`: Returns the number of colour mapping entries.
- `LPaletteLUT:clear`: Removes all colour mapping entries.
- `LPaletteLUT:cycle`: Rotates destination palette entries for palette-cycling animation.
- `LPaletteLUT:type`: Returns the type name of this object.
- `LPaletteLUT:typeOf`: Returns true if this object is of the given type.

### `LProvinceGrid` Methods
- `LProvinceGrid:getWidth`: Returns the grid width in pixels.
- `LProvinceGrid:getHeight`: Returns the grid height in pixels.
- `LProvinceGrid:getAt`: Returns the province ID at pixel coordinates (x, y). Returns 0 for background or out-of-bounds.
- `LProvinceGrid:provinceCount`: Returns the number of unique non-zero province IDs detected in the map.
- `LProvinceGrid:adjacencies`: Returns an array of adjacency records. Each record is {province_a, province_b, border_pixels}.
- `LProvinceGrid:provinceSpans`: Returns province fill spans as { province_id, y, x0, x1 } records (x1 exclusive).
- `LProvinceGrid:borderSegments`: Returns merged border segments as
- `LProvinceGrid:type`: Returns the type name of this object.
- `LProvinceGrid:typeOf`: Returns true if this object is of the given type.
- `LProvinceGrid:serializeShapeData`: Serializes province geometry (spans and borders) to raw bytes.
- `LProvinceGrid:deserializeShapeData`: Deserializes province geometry from raw bytes produced by serializeShapeData.

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
