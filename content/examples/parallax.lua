-- content/examples/parallax.lua
-- Scaffolded coverage of the lurek.parallax API (43 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/parallax_api.rs   (Lua binding, arg types, return shape)
--   * src/parallax/                 (semantics, side effects)
--   * docs/specs/parallax.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/parallax.lua

-- ── lurek.parallax.* functions ──

--@api-stub: lurek.parallax.newLayer
-- Creates a new parallax background layer from an options table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: lurek.parallax.newLayer
  local _todo = "TODO: write a real lurek.parallax.newLayer usage example"
  print(_todo)
end

--@api-stub: lurek.parallax.newSet
-- Creates a new empty parallax set with the given name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: lurek.parallax.newSet
  local _todo = "TODO: write a real lurek.parallax.newSet usage example"
  print(_todo)
end

-- ── ParallaxLayer methods ──

--@api-stub: ParallaxLayer:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:type
  local _todo = "TODO: write a real ParallaxLayer:type usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:update
-- Advances the autonomous scroll accumulator by `dt` seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:update
  local _todo = "TODO: write a real ParallaxLayer:update usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:render
-- Draws the layer using an explicit camera world position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:render
  local _todo = "TODO: write a real ParallaxLayer:render usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:renderAuto
-- Draws the layer using the engine active camera position automatically.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:renderAuto
  local _todo = "TODO: write a real ParallaxLayer:renderAuto usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:resetAutoscroll
-- Resets the autonomous scroll accumulator to zero.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:resetAutoscroll
  local _todo = "TODO: write a real ParallaxLayer:resetAutoscroll usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setScrollFactor
-- Sets the scroll factor relative to camera movement on each axis.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setScrollFactor
  local _todo = "TODO: write a real ParallaxLayer:setScrollFactor usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getScrollFactor
-- Returns the scroll factor as `(x, y)`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getScrollFactor
  local _todo = "TODO: write a real ParallaxLayer:getScrollFactor usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setOffset
-- Sets the static world-pixel position bias added on top of camera scroll.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setOffset
  local _todo = "TODO: write a real ParallaxLayer:setOffset usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getOffset
-- Returns the static offset as `(x, y)`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getOffset
  local _todo = "TODO: write a real ParallaxLayer:getOffset usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setAutoscroll
-- Sets the autonomous scroll velocity in world-pixels per second.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setAutoscroll
  local _todo = "TODO: write a real ParallaxLayer:setAutoscroll usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getAutoscroll
-- Returns the autoscroll velocity as `(vx, vy)`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getAutoscroll
  local _todo = "TODO: write a real ParallaxLayer:getAutoscroll usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setRepeat
-- Sets whether the layer tiles on the X and Y axes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setRepeat
  local _todo = "TODO: write a real ParallaxLayer:setRepeat usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setScale
-- Sets the texture display scale factor on each axis.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setScale
  local _todo = "TODO: write a real ParallaxLayer:setScale usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setZ
-- Sets the draw-order depth.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setZ
  local _todo = "TODO: write a real ParallaxLayer:setZ usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getZ
-- Returns the draw-order depth.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getZ
  local _todo = "TODO: write a real ParallaxLayer:getZ usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setOpacity
-- Sets the layer-wide opacity override in `[0.0, 1.0]`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setOpacity
  local _todo = "TODO: write a real ParallaxLayer:setOpacity usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getOpacity
-- Returns the current opacity.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getOpacity
  local _todo = "TODO: write a real ParallaxLayer:getOpacity usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setTint
-- Sets the multiplicative RGBA tint applied to all pixels of this layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setTint
  local _todo = "TODO: write a real ParallaxLayer:setTint usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getTint
-- Returns the current tint as `(r, g, b, a)`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getTint
  local _todo = "TODO: write a real ParallaxLayer:getTint usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setBlendMode
-- Sets the GPU blend mode for this layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setBlendMode
  local _todo = "TODO: write a real ParallaxLayer:setBlendMode usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getBlendMode
-- Returns the current blend mode as a string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getBlendMode
  local _todo = "TODO: write a real ParallaxLayer:getBlendMode usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setVisible
-- Shows or hides this layer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setVisible
  local _todo = "TODO: write a real ParallaxLayer:setVisible usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:isVisible
-- Returns `true` if the layer is currently visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:isVisible
  local _todo = "TODO: write a real ParallaxLayer:isVisible usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:clearClamp
-- Removes scroll clamping so the layer scrolls freely.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:clearClamp
  local _todo = "TODO: write a real ParallaxLayer:clearClamp usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setTiling
-- Enables or disables seamless infinite tiling on both axes simultaneously.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setTiling
  local _todo = "TODO: write a real ParallaxLayer:setTiling usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getTiling
-- Returns `true` if seamless infinite tiling is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getTiling
  local _todo = "TODO: write a real ParallaxLayer:getTiling usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setTileSize
-- Sets explicit tile dimensions in logical pixels, overriding the default.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setTileSize
  local _todo = "TODO: write a real ParallaxLayer:setTileSize usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:setDepth
-- Sets the floating-point draw depth for fine-grained layer ordering.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:setDepth
  local _todo = "TODO: write a real ParallaxLayer:setDepth usage example"
  print(_todo)
end

--@api-stub: ParallaxLayer:getDepth
-- Returns the current floating-point depth.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxLayer:getDepth
  local _todo = "TODO: write a real ParallaxLayer:getDepth usage example"
  print(_todo)
end

-- ── ParallaxSet methods ──

--@api-stub: ParallaxSet:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:type
  local _todo = "TODO: write a real ParallaxSet:type usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:addLayer
-- Adds a layer to this set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:addLayer
  local _todo = "TODO: write a real ParallaxSet:addLayer usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:removeLayerAt
-- Removes the layer at the given 1-based index.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:removeLayerAt
  local _todo = "TODO: write a real ParallaxSet:removeLayerAt usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:layerCount
-- Returns the number of layers in this set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:layerCount
  local _todo = "TODO: write a real ParallaxSet:layerCount usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:sortByZ
-- Re-sorts all layers by ascending `z` value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:sortByZ
  local _todo = "TODO: write a real ParallaxSet:sortByZ usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:setVisible
-- Shows or hides all layers in this set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:setVisible
  local _todo = "TODO: write a real ParallaxSet:setVisible usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:isVisible
-- Returns `true` if the set is currently visible.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:isVisible
  local _todo = "TODO: write a real ParallaxSet:isVisible usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:update
-- Advances the autoscroll accumulator of every layer by `dt` seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:update
  local _todo = "TODO: write a real ParallaxSet:update usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:render
-- Draws all visible layers in ascending `z` order using an explicit camera position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:render
  local _todo = "TODO: write a real ParallaxSet:render usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:renderAuto
-- Draws all visible layers using the engine active camera position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:renderAuto
  local _todo = "TODO: write a real ParallaxSet:renderAuto usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:getName
-- Returns the name of this set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:getName
  local _todo = "TODO: write a real ParallaxSet:getName usage example"
  print(_todo)
end

--@api-stub: ParallaxSet:setName
-- Sets the name of this set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/parallax_api.rs and docs/specs/parallax.md).
do  -- TODO: ParallaxSet:setName
  local _todo = "TODO: write a real ParallaxSet:setName usage example"
  print(_todo)
end

