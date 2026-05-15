# parallax

## General Info

- Module group: `Feature Systems`
- Source path: `src/parallax/`
- Lua API path(s): `src/lua_api/parallax_api.rs`
- Primary Lua namespace: `lurek.parallax`
- Rust test path(s): tests/rust/unit/parallax_tests.rs
- Lua test path(s): tests/lua/unit/test_parallax_core_unit.lua, tests/lua/integration/test_parallax_camera.lua

## Summary

The `parallax` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `image`, `render`, `runtime`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

## Files

- `draw.rs`: Implements CPU-side image drawing for headless and test-friendly parallax output without depending on the GPU path.
- `layer.rs`: Defines `ParallaxLayer` state, scroll calculations, autoscroll behavior, and batch-building logic.
- `mod.rs`: Declares the parallax submodules and re-exports the main layer and batch types.
- `presets.rs`: Provides reusable constructors for common layer styles (`far`, `mid`, `fog`).
- `render.rs`: Converts parallax batches into `RenderCommand` sequences with color, blend mode, and repeated image draws.
- `tile_iter.rs`: Shared tiled-position iterator with stronger off-screen culling margin and safety cap.

## Types

- `ParallaxDrawBatch` (`struct`, `layer.rs`): A CPU-side batch description generated from a layer so the Lua bridge or renderer can issue the actual draw commands.
- `ParallaxLayer` (`struct`, `layer.rs`): The main scrolling background layer. It owns camera-relative scroll factors, offsets, tiling, opacity, tint, scale, bounds, and z-order.

## Functions

- `ParallaxLayer::draw_to_image` (`draw.rs`): Rasterise this layer into a solid-colour `ImageData` sized `width × height`; returns transparent image when `visible` is `false`.
- `ParallaxLayer::new` (`layer.rs`): Create a new layer for `texture_key` with the given texture dimensions and sensible defaults.
- `ParallaxLayer::update` (`layer.rs`): Advance the autoscroll accumulator by `dt` seconds and wrap it to one tile width/height.
- `ParallaxLayer::build_draw_calls` (`layer.rs`): Build a `ParallaxDrawBatch` for the current camera position; returns `None` when invisible or zero-size.
- `ParallaxLayer::reset_autoscroll` (`layer.rs`): Reset the autoscroll accumulator to `[0.0, 0.0]`.
- `ParallaxLayer::set_tiling` (`layer.rs`): Set whether tiling mode (forces repeat on both axes) is active.
- `ParallaxLayer::get_tiling` (`layer.rs`): Return `true` when tiling mode is active.
- `ParallaxLayer::set_tile_size` (`layer.rs`): Override tile size to `(w, h)` pixels; `0.0` or negative resets to texture-derived size.
- `ParallaxLayer::set_depth` (`layer.rs`): Set the depth sort value for this layer.
- `ParallaxLayer::get_depth` (`layer.rs`): Return the current depth sort value.
- `ParallaxLayer::set_effect_chain` (`layer.rs`): Replace the shader effect chain; an empty `chain` clears the existing chain.
- `ParallaxLayer::clear_effect_chain` (`layer.rs`): Remove all shader effects from this layer.
- `ParallaxLayer::effect_count` (`layer.rs`): Return the number of shader passes currently in the effect chain.
- `ParallaxLayer::set_motion_stretch` (`layer.rs`): Configure motion-stretch blur; `strength` controls pixels-per-sec sensitivity, `max_scale` caps the scale boost.
- `far_background` (`presets.rs`): Create a slow far-background layer (scroll factor ~0.15 horizontal); horizontal repeat, Z = -200, opacity 0.8.
- `mid_background` (`presets.rs`): Create a mid-speed background layer (scroll factor ~0.45 horizontal); horizontal repeat, Z = -100, opacity 0.9.
- `foreground_fog` (`presets.rs`): Create a near-screen fog layer: fast scroll, tiled, Screen blend, 35% opacity, light motion-stretch blur, Z = 50.
- `ParallaxLayer::generate_render_commands` (`render.rs`): Generate a `Vec<RenderCommand>` for this layer at the given camera position and screen size.
- `batch_to_render_commands` (`render.rs`): Converts a pre-computed [`ParallaxDrawBatch`] into render commands.
- `collect_tiled_positions` (`tile_iter.rs`): Return all `(x, y)` tile positions visible inside `screen_size` plus the cull margin; capped at `MAX_TILED_POSITIONS`.

## Lua API Reference

- Binding path(s): `src/lua_api/parallax_api.rs`
- Namespace: `lurek.parallax`

### Module Functions
- `lurek.parallax.newLayer`: Creates a parallax layer from an options table.
- `lurek.parallax.newSet`: Creates an empty parallax layer set.
- `lurek.parallax.newPresetLayer`: Creates a parallax layer from a named preset and texture image.

### `LParallaxLayer` Methods
- `LParallaxLayer:type`: Returns the Lua-visible type name for this parallax layer handle.
- `LParallaxLayer:update`: Advances parallax layer autoscroll by delta time.
- `LParallaxLayer:render`: Enqueues render commands using explicit camera coordinates.
- `LParallaxLayer:renderAuto`: Enqueues render commands using the runtime camera.
- `LParallaxLayer:resetAutoscroll`: Resets layer autoscroll offset.
- `LParallaxLayer:setScrollFactor`: Sets layer scroll factor.
- `LParallaxLayer:getScrollFactor`: Returns layer scroll factor.
- `LParallaxLayer:setOffset`: Sets layer offset.
- `LParallaxLayer:getOffset`: Returns layer offset.
- `LParallaxLayer:setAutoscroll`: Sets layer autoscroll velocity.
- `LParallaxLayer:getAutoscroll`: Returns layer autoscroll velocity.
- `LParallaxLayer:setRepeat`: Sets horizontal and vertical repeat flags.
- `LParallaxLayer:setScale`: Sets layer scale.
- `LParallaxLayer:setZ`: Sets layer z order.
- `LParallaxLayer:getZ`: Returns layer z order.
- `LParallaxLayer:setOpacity`: Sets layer opacity, clamped to 0..1.
- `LParallaxLayer:getOpacity`: Returns layer opacity.
- `LParallaxLayer:setTint`: Sets layer tint color.
- `LParallaxLayer:getTint`: Returns layer tint color.
- `LParallaxLayer:setBlendMode`: Sets layer blend mode by name.
- `LParallaxLayer:getBlendMode`: Returns layer blend mode name.
- `LParallaxLayer:setVisible`: Sets layer visibility.
- `LParallaxLayer:isVisible`: Returns layer visibility.
- `LParallaxLayer:setClamp`: Sets clamp bounds for layer movement.
- `LParallaxLayer:clearClamp`: Clears layer clamp bounds.
- `LParallaxLayer:setTiling`: Enables or disables layer tiling.
- `LParallaxLayer:getTiling`: Returns whether layer tiling is enabled.
- `LParallaxLayer:setTileSize`: Sets tile size for tiling.
- `LParallaxLayer:setDepth`: Sets parallax depth.
- `LParallaxLayer:getDepth`: Returns parallax depth.
- `LParallaxLayer:addEffectPass`: Adds a shader effect pass to this layer.
- `LParallaxLayer:clearEffects`: Clears shader effect passes from this layer.
- `LParallaxLayer:effectCount`: Returns shader effect pass count.
- `LParallaxLayer:setMotionStretch`: Sets motion stretch settings.
- `LParallaxLayer:getMotionStretch`: Returns motion stretch settings.

### `LParallaxSet` Methods
- `LParallaxSet:type`: Returns the Lua-visible type name for this parallax set handle.
- `LParallaxSet:addLayer`: Adds a parallax layer to this set.
- `LParallaxSet:removeLayerAt`: Removes a layer by one-based index.
- `LParallaxSet:layerCount`: Returns the number of layers in this set.
- `LParallaxSet:getLayerZAt`: Returns z order for a layer by one-based index.
- `LParallaxSet:sortByZ`: Sorts layers by z order.
- `LParallaxSet:setVisible`: Sets set visibility.
- `LParallaxSet:isVisible`: Returns set visibility.
- `LParallaxSet:update`: Updates all layers in this set.
- `LParallaxSet:render`: Enqueues render commands for all visible set layers using explicit camera coordinates.
- `LParallaxSet:renderAuto`: Enqueues render commands for all visible set layers using the runtime camera.
- `LParallaxSet:getName`: Returns this set name.
- `LParallaxSet:setName`: Sets this set name.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Runtime behavior notes:
	- `setTiling(true)` forces tiling on both axes even if `repeat_x` and `repeat_y` are false.
	- `setTileSize(w, h)` enforces a small minimum tile size to protect against pathological tile counts.
	- `build_draw_calls` now uses a shared tiled iterator helper with expanded culling bounds and an upper safety cap for generated positions.
	- `DrawImageEx.effect` is now populated from per-layer effect passes configured on `LParallaxLayer`.
	- Motion-stretch can scale tiles based on autoscroll velocity and can append a `motion_blur` pass dynamically.
- Keep this module reference synchronized with `src/parallax/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
