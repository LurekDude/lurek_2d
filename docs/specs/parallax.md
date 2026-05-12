# parallax

## General Info

- Module group: `Feature Systems`
- Source path: `src/parallax/`
- Lua API path(s): `src/lua_api/parallax_api.rs`
- Primary Lua namespace: `lurek.parallax`
- Rust test path(s): `tests/rust/unit/parallax_tests.rs`
- Lua test path(s): `tests/lua/unit/test_parallax_core_unit.lua`, `tests/lua/integration/test_parallax_camera.lua`

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

- `ParallaxLayer::draw_to_image` (`draw.rs`): Render this parallax layer to a CPU image for headless testing.
- `ParallaxLayer::new` (`layer.rs`): Creates a new `ParallaxLayer` with sensible defaults.
- `ParallaxLayer::update` (`layer.rs`): Advances the autonomous scroll accumulator by `dt` seconds.
- `ParallaxLayer::build_draw_calls` (`layer.rs`): Builds the draw tile batch for this layer.
- `ParallaxLayer::reset_autoscroll` (`layer.rs`): Resets the autoscroll accumulator to zero.
- `ParallaxLayer::set_tiling` (`layer.rs`): Enables or disables seamless infinite tiling on both axes.
- `ParallaxLayer::get_tiling` (`layer.rs`): Returns `true` if seamless infinite tiling is enabled.
- `ParallaxLayer::set_tile_size` (`layer.rs`): Sets an explicit tile size override, bypassing the scaled texture dimensions (with a safety minimum to avoid draw-call explosions).
- `ParallaxLayer::set_depth` (`layer.rs`): Sets the floating-point draw depth for this layer.
- `ParallaxLayer::get_depth` (`layer.rs`): Returns the floating-point draw depth.
- `ParallaxLayer::set_effect_chain` (`layer.rs`): Replaces the per-layer shader pass chain.
- `ParallaxLayer::clear_effect_chain` (`layer.rs`): Clears all per-layer shader passes.
- `ParallaxLayer::effect_count` (`layer.rs`): Returns the number of per-layer shader passes.
- `ParallaxLayer::set_motion_stretch` (`layer.rs`): Enables/disables velocity-based stretch and configures limits.
- `ParallaxLayer::generate_render_commands` (`render.rs`): Produces render commands for this layer given the current camera and screen.
- `batch_to_render_commands` (`render.rs`): Converts a pre-computed [`ParallaxDrawBatch`] into render commands.

## Lua API Reference

- Binding path(s): `src/lua_api/parallax_api.rs`
- Namespace: `lurek.parallax`

### Module Functions
- `lurek.parallax.newLayer`: Creates a new parallax background layer from an options table.
- `lurek.parallax.newSet`: Creates a new empty parallax set with the given name.
- `lurek.parallax.newPresetLayer`: Creates a new parallax layer from built-in presets (`far`, `mid`, `fog`).

### `LParallaxLayer` Methods
- `LParallaxLayer:type`: Returns the type name of this object.
- `LParallaxLayer:update`: Advances the autonomous scroll accumulator by `dt` seconds.
- `LParallaxLayer:render`: Draws the layer using an explicit camera world position.
- `LParallaxLayer:renderAuto`: Draws the layer using the engine active camera position automatically.
- `LParallaxLayer:resetAutoscroll`: Resets the autonomous scroll accumulator to zero.
- `LParallaxLayer:setScrollFactor`: Sets the scroll factor relative to camera movement on each axis.
- `LParallaxLayer:getScrollFactor`: Returns the scroll factor as `(x, y)`.
- `LParallaxLayer:setOffset`: Sets the static world-pixel position bias added on top of camera scroll.
- `LParallaxLayer:getOffset`: Returns the static offset as `(x, y)`.
- `LParallaxLayer:setAutoscroll`: Sets the autonomous scroll velocity in world-pixels per second.
- `LParallaxLayer:getAutoscroll`: Returns the autoscroll velocity as `(vx, vy)`.
- `LParallaxLayer:setRepeat`: Sets whether the layer tiles on the X and Y axes.
- `LParallaxLayer:setScale`: Sets the texture display scale factor on each axis.
- `LParallaxLayer:setZ`: Sets the draw-order depth. Lower values render first (further back).
- `LParallaxLayer:getZ`: Returns the draw-order depth.
- `LParallaxLayer:setOpacity`: Sets the layer-wide opacity override in `[0.0, 1.0]`.
- `LParallaxLayer:getOpacity`: Returns the current opacity.
- `LParallaxLayer:setTint`: Sets the multiplicative RGBA tint applied to all pixels of this layer.
- `LParallaxLayer:getTint`: Returns the current tint as `(r, g, b, a)`.
- `LParallaxLayer:setBlendMode`: Sets the GPU blend mode for this layer.
- `LParallaxLayer:getBlendMode`: Returns the current blend mode as a string.
- `LParallaxLayer:setVisible`: Shows or hides this layer.
- `LParallaxLayer:isVisible`: Returns `true` if the layer is currently visible.
- `LParallaxLayer:setClamp`: Clamps the scroll offset to a world-pixel range on each axis.
- `LParallaxLayer:clearClamp`: Removes scroll clamping so the layer scrolls freely.
- `LParallaxLayer:setTiling`: Enables or disables seamless infinite tiling on both axes simultaneously.
- `LParallaxLayer:getTiling`: Returns `true` if seamless infinite tiling is enabled.
- `LParallaxLayer:setTileSize`: Sets explicit tile dimensions in logical pixels.
- `LParallaxLayer:setDepth`: Sets the floating-point draw depth for fine-grained layer ordering.
- `LParallaxLayer:getDepth`: Returns the current floating-point depth.
- `LParallaxLayer:addEffectPass`: Appends one shader pass to this layer effect chain.
- `LParallaxLayer:clearEffects`: Clears all per-layer effect passes.
- `LParallaxLayer:effectCount`: Returns effect-pass count for this layer.
- `LParallaxLayer:setMotionStretch`: Enables/disables velocity-based stretch and sets strength/limit.
- `LParallaxLayer:getMotionStretch`: Returns current motion-stretch config.

### `LParallaxSet` Methods
- `LParallaxSet:type`: Returns the type name of this object.
- `LParallaxSet:addLayer`: Adds a layer to this set.
- `LParallaxSet:removeLayerAt`: Removes the layer at the given 1-based index.
- `LParallaxSet:layerCount`: Returns the number of layers in this set.
- `LParallaxSet:getLayerZAt`: Returns the layer `z` value at a given 1-based sorted index, or `nil` when out of range.
- `LParallaxSet:sortByZ`: Re-sorts all layers by ascending `z` value.
- `LParallaxSet:setVisible`: Shows or hides all layers in this set.
- `LParallaxSet:isVisible`: Returns `true` if the set is currently visible.
- `LParallaxSet:update`: Advances the autoscroll accumulator of every layer by `dt` seconds.
- `LParallaxSet:render`: Draws all visible layers in ascending `z` order using an explicit camera position.
- `LParallaxSet:renderAuto`: Draws all visible layers using the engine active camera position.
- `LParallaxSet:getName`: Returns the name of this set.
- `LParallaxSet:setName`: Sets the name of this set.

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
