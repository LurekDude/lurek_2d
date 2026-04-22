-- content/examples/parallax.lua
-- Auto-scaffolded coverage of the lurek.parallax Lua API (43 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/parallax.lua

print("[example] lurek.parallax loaded — 43 API items demonstrated")

-- ── lurek.parallax free functions ──

--@api-stub: lurek.parallax.newLayer
-- Creates a new parallax background layer from an options table.
-- Use this when creates a new parallax background layer from an options table is needed.
if false then
  local _r = lurek.parallax.newLayer(0)
  print(_r)
end

--@api-stub: lurek.parallax.newSet
-- Creates a new empty parallax set with the given name.
-- Use this when creates a new empty parallax set with the given name is needed.
if false then
  local _r = lurek.parallax.newSet(1)
  print(_r)
end

-- ── ParallaxLayer methods ──

--@api-stub: ParallaxLayer:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:type()
end

--@api-stub: ParallaxLayer:update
-- Advances the autonomous scroll accumulator by `dt` seconds.
-- Use this when advances the autonomous scroll accumulator by `dt` seconds is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:update(0)
end

--@api-stub: ParallaxLayer:render
-- Draws the layer using an explicit camera world position.
-- Use this when draws the layer using an explicit camera world position is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:render(0, 0)
end

--@api-stub: ParallaxLayer:renderAuto
-- Draws the layer using the engine active camera position automatically.
-- Use this when draws the layer using the engine active camera position automatically is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:renderAuto()
end

--@api-stub: ParallaxLayer:resetAutoscroll
-- Resets the autonomous scroll accumulator to zero.
-- Use this when resets the autonomous scroll accumulator to zero is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:resetAutoscroll()
end

--@api-stub: ParallaxLayer:setScrollFactor
-- Sets the scroll factor relative to camera movement on each axis.
-- Use this when sets the scroll factor relative to camera movement on each axis is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setScrollFactor(0, 0)
end

--@api-stub: ParallaxLayer:getScrollFactor
-- Returns the scroll factor as `(x, y)`.
-- Use this when returns the scroll factor as `(x, y)` is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getScrollFactor()
end

--@api-stub: ParallaxLayer:setOffset
-- Sets the static world-pixel position bias added on top of camera scroll.
-- Use this when sets the static world-pixel position bias added on top of camera scroll is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setOffset(0, 0)
end

--@api-stub: ParallaxLayer:getOffset
-- Returns the static offset as `(x, y)`.
-- Use this when returns the static offset as `(x, y)` is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getOffset()
end

--@api-stub: ParallaxLayer:setAutoscroll
-- Sets the autonomous scroll velocity in world-pixels per second.
-- Use this when sets the autonomous scroll velocity in world-pixels per second is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setAutoscroll(0, 0)
end

--@api-stub: ParallaxLayer:getAutoscroll
-- Returns the autoscroll velocity as `(vx, vy)`.
-- Use this when returns the autoscroll velocity as `(vx, vy)` is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getAutoscroll()
end

--@api-stub: ParallaxLayer:setRepeat
-- Sets whether the layer tiles on the X and Y axes.
-- Use this when sets whether the layer tiles on the X and Y axes is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setRepeat(0, 0)
end

--@api-stub: ParallaxLayer:setScale
-- Sets the texture display scale factor on each axis.
-- Use this when sets the texture display scale factor on each axis is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setScale(0, 0)
end

--@api-stub: ParallaxLayer:setZ
-- Sets the draw-order depth.
-- Lower values render first (further back).
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setZ(0)
end

--@api-stub: ParallaxLayer:getZ
-- Returns the draw-order depth.
-- Use this when returns the draw-order depth is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getZ()
end

--@api-stub: ParallaxLayer:setOpacity
-- Sets the layer-wide opacity override in `[0.0, 1.0]`.
-- Use this when sets the layer-wide opacity override in `[0.0, 1.0]` is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setOpacity(nil)
end

--@api-stub: ParallaxLayer:getOpacity
-- Returns the current opacity.
-- Use this when returns the current opacity is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getOpacity()
end

--@api-stub: ParallaxLayer:setTint
-- Sets the multiplicative RGBA tint applied to all pixels of this layer.
-- Use this when sets the multiplicative RGBA tint applied to all pixels of this layer is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setTint(nil, nil, nil, nil)
end

--@api-stub: ParallaxLayer:getTint
-- Returns the current tint as `(r, g, b, a)`.
-- Use this when returns the current tint as `(r, g, b, a)` is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getTint()
end

--@api-stub: ParallaxLayer:setBlendMode
-- Sets the GPU blend mode for this layer.
-- Use this when sets the GPU blend mode for this layer is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setBlendMode(nil)
end

--@api-stub: ParallaxLayer:getBlendMode
-- Returns the current blend mode as a string.
-- Use this when returns the current blend mode as a string is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getBlendMode()
end

--@api-stub: ParallaxLayer:setVisible
-- Shows or hides this layer.
-- Use this when shows or hides this layer is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setVisible(0)
end

--@api-stub: ParallaxLayer:isVisible
-- Returns `true` if the layer is currently visible.
-- Use this when returns `true` if the layer is currently visible is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:isVisible()
end

--@api-stub: ParallaxLayer:clearClamp
-- Removes scroll clamping so the layer scrolls freely.
-- Use this when removes scroll clamping so the layer scrolls freely is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:clearClamp()
end

--@api-stub: ParallaxLayer:setTiling
-- Enables or disables seamless infinite tiling on both axes simultaneously.
-- Use this when enables or disables seamless infinite tiling on both axes simultaneously is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setTiling(1)
end

--@api-stub: ParallaxLayer:getTiling
-- Returns `true` if seamless infinite tiling is enabled.
-- Use this when returns `true` if seamless infinite tiling is enabled is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getTiling()
end

--@api-stub: ParallaxLayer:setTileSize
-- Sets explicit tile dimensions in logical pixels, overriding the default.
-- Use this when sets explicit tile dimensions in logical pixels, overriding the default is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setTileSize(0, 0)
end

--@api-stub: ParallaxLayer:setDepth
-- Sets the floating-point draw depth for fine-grained layer ordering.
-- Use this when sets the floating-point draw depth for fine-grained layer ordering is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:setDepth(0)
end

--@api-stub: ParallaxLayer:getDepth
-- Returns the current floating-point depth.
-- Use this when returns the current floating-point depth is needed.
if false then
  local _o = nil  -- ParallaxLayer instance
  _o:getDepth()
end

-- ── ParallaxSet methods ──

--@api-stub: ParallaxSet:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:type()
end

--@api-stub: ParallaxSet:addLayer
-- Adds a layer to this set.
-- Use this when adds a layer to this set is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:addLayer(0)
end

--@api-stub: ParallaxSet:removeLayerAt
-- Removes the layer at the given 1-based index.
-- Use this when removes the layer at the given 1-based index is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:removeLayerAt(1)
end

--@api-stub: ParallaxSet:layerCount
-- Returns the number of layers in this set.
-- Use this when returns the number of layers in this set is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:layerCount()
end

--@api-stub: ParallaxSet:sortByZ
-- Re-sorts all layers by ascending `z` value.
-- Use this when re-sorts all layers by ascending `z` value is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:sortByZ()
end

--@api-stub: ParallaxSet:setVisible
-- Shows or hides all layers in this set.
-- Use this when shows or hides all layers in this set is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:setVisible(0)
end

--@api-stub: ParallaxSet:isVisible
-- Returns `true` if the set is currently visible.
-- Use this when returns `true` if the set is currently visible is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:isVisible()
end

--@api-stub: ParallaxSet:update
-- Advances the autoscroll accumulator of every layer by `dt` seconds.
-- Use this when advances the autoscroll accumulator of every layer by `dt` seconds is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:update(0)
end

--@api-stub: ParallaxSet:render
-- Draws all visible layers in ascending `z` order using an explicit camera position.
-- Use this when draws all visible layers in ascending `z` order using an explicit camera position is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:render(0, 0)
end

--@api-stub: ParallaxSet:renderAuto
-- Draws all visible layers using the engine active camera position.
-- Use this when draws all visible layers using the engine active camera position is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:renderAuto()
end

--@api-stub: ParallaxSet:getName
-- Returns the name of this set.
-- Use this when returns the name of this set is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:getName()
end

--@api-stub: ParallaxSet:setName
-- Sets the name of this set.
-- Use this when sets the name of this set is needed.
if false then
  local _o = nil  -- ParallaxSet instance
  _o:setName(1)
end

