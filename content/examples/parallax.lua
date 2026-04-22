-- content/examples/parallax.lua
-- Practical usage examples for the lurek.parallax API (43 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.parallax.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/parallax.lua

print("[example] lurek.parallax — 43 API entries")

-- ── lurek.parallax.* free functions ──

--@api-stub: lurek.parallax.newLayer
-- Creates a new parallax background layer from an options table.
-- Call when you need to create a new layer.
local ok, obj = pcall(function() return lurek.parallax.newLayer({}) end)
if ok and obj then print("created:", obj) end
print("lurek.parallax.newLayer ok=", ok)

--@api-stub: lurek.parallax.newSet
-- Creates a new empty parallax set with the given name.
-- Call when you need to create a new set.
local ok, obj = pcall(function() return lurek.parallax.newSet("name") end)
if ok and obj then print("created:", obj) end
print("lurek.parallax.newSet ok=", ok)

-- ── ParallaxLayer methods ──

--@api-stub: ParallaxLayer:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("ParallaxLayer:type ->", ok, result)
end

--@api-stub: ParallaxLayer:update
-- Advances the autonomous scroll accumulator by `dt` seconds.
-- Call when you need to invoke update.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("ParallaxLayer:update ->", ok, result)
end

--@api-stub: ParallaxLayer:render
-- Draws the layer using an explicit camera world position.
-- Call when you need to invoke render.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:render(nil, nil) end)
  print("ParallaxLayer:render ->", ok, result)
end

--@api-stub: ParallaxLayer:renderAuto
-- Draws the layer using the engine active camera position automatically.
-- Call when you need to invoke render auto.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:renderAuto() end)
  print("ParallaxLayer:renderAuto ->", ok, result)
end

--@api-stub: ParallaxLayer:resetAutoscroll
-- Resets the autonomous scroll accumulator to zero.
-- Call when you need to invoke reset autoscroll.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:resetAutoscroll() end)
  print("ParallaxLayer:resetAutoscroll ->", ok, result)
end

--@api-stub: ParallaxLayer:setScrollFactor
-- Sets the scroll factor relative to camera movement on each axis.
-- Call when you need to assign scroll factor.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setScrollFactor(0, 0) end)
  print("ParallaxLayer:setScrollFactor ->", ok, result)
end

--@api-stub: ParallaxLayer:getScrollFactor
-- Returns the scroll factor as `(x, y)`.
-- Call when you need to read scroll factor.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getScrollFactor() end)
  print("ParallaxLayer:getScrollFactor ->", ok, result)
end

--@api-stub: ParallaxLayer:setOffset
-- Sets the static world-pixel position bias added on top of camera scroll.
-- Call when you need to assign offset.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setOffset(0, 0) end)
  print("ParallaxLayer:setOffset ->", ok, result)
end

--@api-stub: ParallaxLayer:getOffset
-- Returns the static offset as `(x, y)`.
-- Call when you need to read offset.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getOffset() end)
  print("ParallaxLayer:getOffset ->", ok, result)
end

--@api-stub: ParallaxLayer:setAutoscroll
-- Sets the autonomous scroll velocity in world-pixels per second.
-- Call when you need to assign autoscroll.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setAutoscroll(0, 0) end)
  print("ParallaxLayer:setAutoscroll ->", ok, result)
end

--@api-stub: ParallaxLayer:getAutoscroll
-- Returns the autoscroll velocity as `(vx, vy)`.
-- Call when you need to read autoscroll.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getAutoscroll() end)
  print("ParallaxLayer:getAutoscroll ->", ok, result)
end

--@api-stub: ParallaxLayer:setRepeat
-- Sets whether the layer tiles on the X and Y axes.
-- Call when you need to assign repeat.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setRepeat(nil, nil) end)
  print("ParallaxLayer:setRepeat ->", ok, result)
end

--@api-stub: ParallaxLayer:setScale
-- Sets the texture display scale factor on each axis.
-- Call when you need to assign scale.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setScale(nil, nil) end)
  print("ParallaxLayer:setScale ->", ok, result)
end

--@api-stub: ParallaxLayer:setZ
-- Sets the draw-order depth.
-- Lower values render first (further back).
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setZ(0) end)
  print("ParallaxLayer:setZ ->", ok, result)
end

--@api-stub: ParallaxLayer:getZ
-- Returns the draw-order depth.
-- Call when you need to read z.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getZ() end)
  print("ParallaxLayer:getZ ->", ok, result)
end

--@api-stub: ParallaxLayer:setOpacity
-- Sets the layer-wide opacity override in `[0.0, 1.0]`.
-- Call when you need to assign opacity.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setOpacity(1) end)
  print("ParallaxLayer:setOpacity ->", ok, result)
end

--@api-stub: ParallaxLayer:getOpacity
-- Returns the current opacity.
-- Call when you need to read opacity.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getOpacity() end)
  print("ParallaxLayer:getOpacity ->", ok, result)
end

--@api-stub: ParallaxLayer:setTint
-- Sets the multiplicative RGBA tint applied to all pixels of this layer.
-- Call when you need to assign tint.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setTint(1, 1, 1, 1) end)
  print("ParallaxLayer:setTint ->", ok, result)
end

--@api-stub: ParallaxLayer:getTint
-- Returns the current tint as `(r, g, b, a)`.
-- Call when you need to read tint.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getTint() end)
  print("ParallaxLayer:getTint ->", ok, result)
end

--@api-stub: ParallaxLayer:setBlendMode
-- Sets the GPU blend mode for this layer.
-- Call when you need to assign blend mode.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setBlendMode(nil) end)
  print("ParallaxLayer:setBlendMode ->", ok, result)
end

--@api-stub: ParallaxLayer:getBlendMode
-- Returns the current blend mode as a string.
-- Call when you need to read blend mode.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getBlendMode() end)
  print("ParallaxLayer:getBlendMode ->", ok, result)
end

--@api-stub: ParallaxLayer:setVisible
-- Shows or hides this layer.
-- Call when you need to assign visible.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setVisible(nil) end)
  print("ParallaxLayer:setVisible ->", ok, result)
end

--@api-stub: ParallaxLayer:isVisible
-- Returns `true` if the layer is currently visible.
-- Call when you need to check is visible.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:isVisible() end)
  print("ParallaxLayer:isVisible ->", ok, result)
end

--@api-stub: ParallaxLayer:clearClamp
-- Removes scroll clamping so the layer scrolls freely.
-- Call when you need to invoke clear clamp.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:clearClamp() end)
  print("ParallaxLayer:clearClamp ->", ok, result)
end

--@api-stub: ParallaxLayer:setTiling
-- Enables or disables seamless infinite tiling on both axes simultaneously.
-- Call when you need to assign tiling.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setTiling(nil) end)
  print("ParallaxLayer:setTiling ->", ok, result)
end

--@api-stub: ParallaxLayer:getTiling
-- Returns `true` if seamless infinite tiling is enabled.
-- Call when you need to read tiling.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getTiling() end)
  print("ParallaxLayer:getTiling ->", ok, result)
end

--@api-stub: ParallaxLayer:setTileSize
-- Sets explicit tile dimensions in logical pixels, overriding the default.
-- Call when you need to assign tile size.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setTileSize(100, 100) end)
  print("ParallaxLayer:setTileSize ->", ok, result)
end

--@api-stub: ParallaxLayer:setDepth
-- Sets the floating-point draw depth for fine-grained layer ordering.
-- Call when you need to assign depth.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:setDepth(0) end)
  print("ParallaxLayer:setDepth ->", ok, result)
end

--@api-stub: ParallaxLayer:getDepth
-- Returns the current floating-point depth.
-- Call when you need to read depth.
-- Build a ParallaxLayer via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxLayer(...)
if instance then
  local ok, result = pcall(function() return instance:getDepth() end)
  print("ParallaxLayer:getDepth ->", ok, result)
end

-- ── ParallaxSet methods ──

--@api-stub: ParallaxSet:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("ParallaxSet:type ->", ok, result)
end

--@api-stub: ParallaxSet:addLayer
-- Adds a layer to this set.
-- Call when you need to add layer.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:addLayer(nil) end)
  print("ParallaxSet:addLayer ->", ok, result)
end

--@api-stub: ParallaxSet:removeLayerAt
-- Removes the layer at the given 1-based index.
-- Call when you need to remove layer at.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:removeLayerAt(1) end)
  print("ParallaxSet:removeLayerAt ->", ok, result)
end

--@api-stub: ParallaxSet:layerCount
-- Returns the number of layers in this set.
-- Call when you need to invoke layer count.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:layerCount() end)
  print("ParallaxSet:layerCount ->", ok, result)
end

--@api-stub: ParallaxSet:sortByZ
-- Re-sorts all layers by ascending `z` value.
-- Call when you need to invoke sort by z.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:sortByZ() end)
  print("ParallaxSet:sortByZ ->", ok, result)
end

--@api-stub: ParallaxSet:setVisible
-- Shows or hides all layers in this set.
-- Call when you need to assign visible.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:setVisible(nil) end)
  print("ParallaxSet:setVisible ->", ok, result)
end

--@api-stub: ParallaxSet:isVisible
-- Returns `true` if the set is currently visible.
-- Call when you need to check is visible.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:isVisible() end)
  print("ParallaxSet:isVisible ->", ok, result)
end

--@api-stub: ParallaxSet:update
-- Advances the autoscroll accumulator of every layer by `dt` seconds.
-- Call when you need to invoke update.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("ParallaxSet:update ->", ok, result)
end

--@api-stub: ParallaxSet:render
-- Draws all visible layers in ascending `z` order using an explicit camera position.
-- Call when you need to invoke render.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:render(nil, nil) end)
  print("ParallaxSet:render ->", ok, result)
end

--@api-stub: ParallaxSet:renderAuto
-- Draws all visible layers using the engine active camera position.
-- Call when you need to invoke render auto.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:renderAuto() end)
  print("ParallaxSet:renderAuto ->", ok, result)
end

--@api-stub: ParallaxSet:getName
-- Returns the name of this set.
-- Call when you need to read name.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("ParallaxSet:getName ->", ok, result)
end

--@api-stub: ParallaxSet:setName
-- Sets the name of this set.
-- Call when you need to assign name.
-- Build a ParallaxSet via the appropriate lurek.parallax.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.parallax.newParallaxSet(...)
if instance then
  local ok, result = pcall(function() return instance:setName("name") end)
  print("ParallaxSet:setName ->", ok, result)
end

