# image

## General Info

- Module group: `Platform Services`
- Source path: `src/image/`
- Lua API path(s): `src/lua_api/image_api.rs`
- Primary Lua namespace: `lurek.image`
- Rust test path(s): tests/rust/unit/image_tests.rs, tests/rust/stress/image_stress_tests.rs
- Lua test path(s): tests/lua/unit/test_image.lua, tests/lua/unit/test_image_effect.lua, tests/lua/stress/test_image_stress.lua, tests/lua/evidence/test_evidence_image_drawing.lua, tests/lua/evidence/test_evidence_imagedata.lua, tests/lua/evidence/test_evidence_image_effects.lua, tests/lua/evidence/test_evidence_imagedata_effects.lua

## Summary

The `image` module provides Lurek2D's CPU-side pixel buffer type and image manipulation operations. `ImageData` is a heap-allocated RGBA8 pixel buffer (`width * height * 4` bytes) with construction from file, raw bytes, or zeroed allocation; per-pixel get/set with bounds checking; and operations including `resize` (nearest-neighbour), `blit(src, dst_x, dst_y)`, `fill`, `map_pixels(fn)`, `get_region` (crop), `diff(other)` (for golden tests), and `encode_png()`. PNG/JPEG decoding is handled via the `image` external crate.

`CompressedImageData` holds DDS/DXT compressed GPU texture data loaded without CPU decompression, ready to upload directly to the GPU. `PaletteLUT` is a color palette lookup table used for shader-based palette swapping effects. `LayeredImage` + `ImageLayer` implement a Porter-Duff compositing stack where each layer contributes to a flattened RGBA output image.

The `texture` submodule provides `Texture` (a GPU handle with dimensions, format, and filtering settings) and the `texture_atlas` submodule provides `TextureAtlas` (a named-region index into a single texture for sprite-sheet lookups). The `serial` submodule handles the binary `.lim` format for efficient ImageData/LayeredImage serialization. The `visualization` submodule provides standalone helpers for Tier 1 modules to export debug imagery without import cycles. The `render` submodule generates GPU `RenderCommand` entries from `ImageData` for direct draw calls.

**Scope boundary**: Platform Services tier. Depends on the `image` external crate for file decoding. Lua bridge in `src/lua_api/image_api.rs`.

## Files

- `compressed.rs`: Defines DDS-backed compressed image data for formats that should stay compressed until GPU upload.
- `effects.rs`: Adds CPU image-processing operations onto `ImageData`, including tone changes, geometric transforms, blur, sharpen, and other filter-style edits.
- `image_data.rs`: Defines `ImageData`, the core RGBA8 pixel buffer with load, encode, per-pixel access, drawing primitives, and bulk pixel transforms.
- `layers.rs`: Defines layered image composition with named layers, visibility, opacity, ordering, and Porter-Duff style flattening.
- `mod.rs`: Re-exports the module's public image types and groups the submodules into one CPU-side image surface.
- `palette_lut.rs`: Stores source-to-target color mappings used for palette-swap style workflows.
- `render.rs`: Converts `ImageData` into render-command descriptions without taking ownership of renderer internals.
- `serial.rs`: Implements the `.lim` binary format for saving and loading flat and layered images.
- `texture.rs`: Defines a lightweight texture handle and CPU-to-renderer texture creation helpers.
- `texture_atlas.rs`: Packs named rectangular regions into a fixed atlas layout for sprite-sheet style use cases.
- `visualization.rs`: Produces `ImageData` visualizations for other systems such as animation playback, camera debugging, noise, terrain, and easing curves.

## Types

- `CompressedFormat` (`enum`, `compressed.rs`): Identifies which GPU-compressed format a DDS asset uses and gives the Lua side a stable format name.
- `CompressedImageData` (`struct`, `compressed.rs`): Holds DDS payloads and mip data in compressed form so the engine can defer expansion and upload decisions to the renderer.
- `ImageData` (`struct`, `image_data.rs`): The main CPU image container. It is the module's central type for pixel storage, file decode/encode, primitive drawing, and effect application.
- `ImageLayer` (`struct`, `layers.rs`): Represents a single named layer with visibility, opacity, and its own `ImageData` backing store.
- `LayeredImage` (`struct`, `layers.rs`): Owns an ordered stack of `ImageLayer` values and merges them into a flat image when callers need a composited result.
- `PaletteLUT` (`struct`, `palette_lut.rs`): Describes palette remapping tables for effects that replace source colors with target colors.
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
- `ImageData::draw_circle_safe` (`image_data.rs`): Draw a filled circle onto the image using the midpoint algorithm.
- `ImageData::draw_circle` (`image_data.rs`): draw_circle.
- `ImageData::draw_line` (`image_data.rs`): Draw a line using Bresenham's algorithm.
- `ImageData::draw_label` (`image_data.rs`): Draw a text label using a built-in 3×5 pixel font.
- `ImageData::encode_png` (`image_data.rs`): Encode the image as PNG bytes.
- `ImageData::as_bytes` (`image_data.rs`): Get a reference to the raw pixel bytes.
- `ImageData::get_string` (`image_data.rs`): Get the raw pixel bytes as a vector (for Lua getString() compatibility).
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
- `ImageData::generate_render_commands` (`render.rs`): Generate a single `DrawImage` render command for this image.
- `ImageData::draw_to_image` (`render.rs`): Return a CPU copy of this image (identity draw-to-image).
- `save_image` (`serial.rs`): Save a flat [`ImageData`] to a LIMG binary file at the given path.
- `load_image` (`serial.rs`): Load a flat [`ImageData`] from a LIMG binary file.
- `save_layered` (`serial.rs`): Save a [`LayeredImage`] to a LIMG binary file at the given path.
- `load_layered` (`serial.rs`): Load a [`LayeredImage`] from a LIMG binary file.
- `Texture::load` (`texture.rs`): Loads an image from `path`, premultiplies alpha, and appends it to `textures`.
- `Texture::from_rgba` (`texture.rs`): Creates a texture from raw RGBA pixel data (not premultiplied).
- `TextureAtlas::new` (`texture_atlas.rs`): Creates an empty atlas with the given pixel dimensions and inter-region padding.
- `TextureAtlas::pack` (`texture_atlas.rs`): Packs a named region of size `w` x `h` into the atlas.
- `TextureAtlas::get_region` (`texture_atlas.rs`): Looks up a previously packed region by name.
- `TextureAtlas::get_region_count` (`texture_atlas.rs`): Returns the number of packed regions.
- `TextureAtlas::get_dimensions` (`texture_atlas.rs`): Returns the atlas dimensions as `(width, height)`.
- `TextureAtlas::get_regions` (`texture_atlas.rs`): Returns all packed regions in arbitrary order.
- `TextureAtlas::clear` (`texture_atlas.rs`): Removes all packed regions and shelves.
- `draw_animation_frame_grid_to_image` (`visualization.rs`): Render an animation's frame grid as a strip of numbered cells.
- `draw_animation_playback_to_image` (`visualization.rs`): Render an animation playback strip as snapshot columns.
- `draw_camera_debug_to_image` (`visualization.rs`): Render a camera debug visualization showing viewport, position, and zoom.
- `draw_camera_zoom_comparison_to_image` (`visualization.rs`): Render a zoom comparison showing the world at multiple zoom levels.
- `noise_to_image` (`visualization.rs`): Render a 2D noise function to a grayscale image.
- `noise_raw_to_image` (`visualization.rs`): Render a 2D noise function where the output is already in `[0,1]` range.
- `noise_terrain_to_image` (`visualization.rs`): Render a 2D noise function as a terrain-colored image.
- `heightmap_to_image` (`visualization.rs`): Render a flat heightmap buffer as a colored elevation image.
- `terrain_elevation_to_image` (`visualization.rs`): Render a flat heightmap buffer with terrain-band coloring.
- `easing_gallery_to_image` (`visualization.rs`): Render a gallery of easing curves as a grid of small charts.
- `easing_comparison_to_image` (`visualization.rs`): Render multiple easing curves overlaid on a single chart.
- `bezier_curves_to_image` (`visualization.rs`): Render multiple cubic Bezier curves with control-point overlays.
- `cellular_grid_to_image` (`visualization.rs`): Render a cellular automata grid (1=alive, 0=dead) as a scaled image.
- `voronoi_to_image` (`visualization.rs`): Render a Voronoi region map as a colored image.
- `points_to_image` (`visualization.rs`): Render a set of 2D points as dots on a dark background.
- `dungeon_grid_to_image` (`visualization.rs`): Render a BSP dungeon grid (0=floor, 1=wall) as a scaled tile image.
- `noise_map_to_image` (`visualization.rs`): Render a noise map buffer as a grayscale image (normalised `[-1,1]` → `[0,255]`).
- `noise_comparison_to_image` (`visualization.rs`): Render multiple noise maps side by side as a horizontal strip.
- `polygon_gallery_to_image` (`visualization.rs`): Render a gallery of regular polygons (triangle→dodecagon), a five-pointed star, and an arrow shape using `draw_line`.
- `spiral_to_image` (`visualization.rs`): Render concentric colored circles to demonstrate angular segment drawing.
- `filled_primitives_to_image` (`visualization.rs`): Render filled rectangle and circle primitives with HSV-coloured fills.
- `panel_layout_to_image` (`visualization.rs`): Render a mock settings panel with title bar, sliders, checkboxes, radio buttons, progress bar, colour swatches, and action buttons.
- `hud_bars_to_image` (`visualization.rs`): Render a game HUD with HP/MP/Stamina/XP bars and skill cooldown indicators.
- `camera_rotation_to_image` (`visualization.rs`): Render six camera rotation steps in a 3-column grid.
- `camera_bounds_to_image` (`visualization.rs`): Render a camera bounds-clamping summary panel.
- `camera_follow_to_image` (`visualization.rs`): Render a camera follow-and-deadzone trail diagram.
- `camera_shake_to_image` (`visualization.rs`): Render a camera shake trail and move-by result.
- `animation_playback_control_to_image` (`visualization.rs`): Render an animation playback-control timeline diagram.
- `waveform_to_image` (`visualization.rs`): Render audio samples as a waveform visualization.
- `waveform_stereo_to_image` (`visualization.rs`): Render interleaved stereo audio samples as a two-channel waveform.
- `waveform_zoomed_to_image` (`visualization.rs`): Render a zoomed-in waveform showing individual sample cycles.
- `colored_points_to_image` (`visualization.rs`): Render a set of 2-D points, each colored by its index in the list.
- `draw_camera_rotation_grid_to_image` (`visualization.rs`): Render a grid of camera rotation panels, each showing 8 coloured dots transformed through the rotation.
- `draw_camera_bounds_to_image` (`visualization.rs`): Render a set of camera positions as labelled coloured rectangles.
- `draw_camera_follow_trail_to_image` (`visualization.rs`): Render a camera follow trail with target points and dead-zone rectangle.
- `draw_camera_shake_trail_to_image` (`visualization.rs`): Render a camera shake trail with fading circles and reference markers.
- `draw_graph_operations_to_image` (`visualization.rs`): Render a graph with explicit node positions, labels, edge list, and stats.
- `draw_graph_item_flow_to_image` (`visualization.rs`): Render a pipeline graph with nodes, directional pipes, and item indicators.
- `draw_geometry_shapes_to_image` (`visualization.rs`): Draw a comprehensive geometry shapes & queries visualization.
- `draw_geometry_intersections_to_image` (`visualization.rs`): Draw geometry intersection tests visualization.
- `draw_delaunay_to_image` (`visualization.rs`): Draw Delaunay triangulation visualization.
- `draw_image_comparison_to_image` (`visualization.rs`): Draw a side-by-side comparison of multiple images.
- `draw_pixel_transform_grid_to_image` (`visualization.rs`): Draw a 4-column pixel transform grid: original, invert, grayscale, sepia.
- `draw_color_wheel_to_image` (`visualization.rs`): Draw an HSV colour wheel.
- `draw_sound_waveform_to_image` (`visualization.rs`): Draw a single waveform as a colored plot on a dark background.
- `draw_bezier_advanced_to_image` (`visualization.rs`): Draw a bezier advanced operations overview.
- `draw_animation_to_image` (`visualization.rs`): Render an animation as a CPU image for headless testing.
- `draw_camera_to_image` (`visualization.rs`): Render a camera as a CPU image for headless testing.

## Lua API Reference

- Binding path(s): `src/lua_api/image_api.rs`
- Namespace: `lurek.image`

### Module Functions
- `lurek.image.newImageData`: Creates a new blank ImageData or loads one from a file.
- `lurek.image.newCompressedData`: Loads compressed texture data from a DDS file.
- `lurek.image.isCompressed`: Returns true if the file at the given path is a DDS file.
- `lurek.image.newLayeredImage`: Creates a new empty LayeredImage canvas with no layers.
- `lurek.image.saveImage`: Saves a flat ImageData to a LIMG binary file at the given path.
- `lurek.image.savePNG`: Saves a flat ImageData as a PNG file at the given path.
- `lurek.image.loadImage`: Loads an ImageData from a LIMG binary file.
- `lurek.image.loadLayered`: Loads a LayeredImage from a LIMG binary file.

### `CompressedImageData` Methods
- `CompressedImageData:getWidth`: Returns the width of the base mip level in pixels.
- `CompressedImageData:getHeight`: Returns the height of the base mip level in pixels.
- `CompressedImageData:getDimensions`: Returns the width and height of the base mip level.
- `CompressedImageData:getMipmapCount`: Returns the number of mipmap levels stored.
- `CompressedImageData:getFormat`: Returns the compressed format name string.

### `LayeredImage` Methods
- `LayeredImage:getWidth`: Returns the canvas width shared by all layers.
- `LayeredImage:getHeight`: Returns the canvas height shared by all layers.
- `LayeredImage:layerCount`: Returns the number of layers in the stack.
- `LayeredImage:addLayer`: Appends a new blank transparent layer on top and returns its 1-based index.
- `LayeredImage:removeLayer`: Removes the layer at the given 1-based index. Returns true on success.
- `LayeredImage:getLayer`: Returns a copy of the layer's pixel buffer as an ImageData.
- `LayeredImage:getOpacity`: Returns the opacity of a layer in [0.0, 1.0].
- `LayeredImage:setOpacity`: Sets the opacity of a layer. Value is clamped to [0.0, 1.0].
- `LayeredImage:isVisible`: Returns whether a layer is visible.
- `LayeredImage:setVisible`: Shows or hides a layer during compositing.
- `LayeredImage:getName`: Returns the name of a layer.
- `LayeredImage:setName`: Renames a layer.
- `LayeredImage:swapLayers`: Swaps two layers by their 1-based indices, changing their compositing order.
- `LayeredImage:merge`: Flattens all visible layers into a single ImageData using Porter-Duff "over" compositing.
- `LayeredImage:save`: Saves the layered image to a LIMG binary file at the given path.

### `mlua` Methods
- `mlua:getWidth`: Returns the width.
- `mlua:getHeight`: Returns the height.
- `mlua:getDimensions`: Returns the dimensions.
- `mlua:getPixel`: Returns the pixel.
- `mlua:encode`: Encode.
- `mlua:getString`: Returns the string.
- `mlua:mapPixel`: Map pixel.
- `mlua:brightness`: Brightness.
- `mlua:contrast`: Contrast.
- `mlua:saturation`: Saturation.
- `mlua:gamma`: Gamma.
- `mlua:grayscale`: Grayscale.
- `mlua:sepia`: Sepia.
- `mlua:invert`: Invert.
- `mlua:threshold`: Threshold.
- `mlua:posterize`: Posterize.
- `mlua:fill`: Fill.
- `mlua:noise`: Noise.
- `mlua:alphaMask`: Alpha mask.
- `mlua:flipHorizontal`: Flip horizontal.
- `mlua:flipVertical`: Flip vertical.
- `mlua:rotate90cw`: Rotate90cw.
- `mlua:crop`: Crop.
- `mlua:resizeNearest`: Resize nearest.
- `mlua:blur`: Blur.
- `mlua:sharpen`: Sharpen.
- `mlua:resize`: Returns a bilinear-interpolated copy of the image at the given dimensions.
- `mlua:diff`: Returns the sum of absolute per-channel pixel differences with another ImageData.
- `mlua:mapPixels`: Applies a function to every pixel in-place.

## References

- `animation`: Imports or references `animation` from `src/animation/`.
- `camera`: Imports or references `camera` from `src/camera/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/image/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
