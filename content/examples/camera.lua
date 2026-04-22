-- content/examples/camera.lua
-- Practical usage examples for the lurek.camera API (36 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.camera.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/camera.lua

print("[example] lurek.camera — 36 API entries")

-- ── lurek.camera.* free functions ──

--@api-stub: lurek.camera.new
-- Creates a new Camera2D with the given viewport dimensions.
-- Call when you need to invoke new.
local ok, obj = pcall(function() return lurek.camera.new(nil, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.camera.new ok=", ok)

-- ── Camera2D methods ──

--@api-stub: Camera2D:setPosition
-- Sets the camera's world-space position.
-- Call when you need to assign position.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:setPosition(0, 0) end)
  print("Camera2D:setPosition ->", ok, result)
end

--@api-stub: Camera2D:getPosition
-- Returns the camera's world-space position as x, y.
-- Call when you need to read position.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:getPosition() end)
  print("Camera2D:getPosition ->", ok, result)
end

--@api-stub: Camera2D:setZoom
-- Sets the uniform zoom factor (1.0 = natural size).
-- Call when you need to assign zoom.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:setZoom(nil) end)
  print("Camera2D:setZoom ->", ok, result)
end

--@api-stub: Camera2D:getZoom
-- Returns the current zoom factor.
-- Call when you need to read zoom.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:getZoom() end)
  print("Camera2D:getZoom ->", ok, result)
end

--@api-stub: Camera2D:setRotation
-- Sets the rotation in radians.
-- Call when you need to assign rotation.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:setRotation(1) end)
  print("Camera2D:setRotation ->", ok, result)
end

--@api-stub: Camera2D:getRotation
-- Returns the rotation in radians.
-- Call when you need to read rotation.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:getRotation() end)
  print("Camera2D:getRotation ->", ok, result)
end

--@api-stub: Camera2D:getViewport
-- Returns the current viewport as x, y, w, h.
-- Call when you need to read viewport.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:getViewport() end)
  print("Camera2D:getViewport ->", ok, result)
end

--@api-stub: Camera2D:removeBounds
-- Removes previously set world-space bounds.
-- Call when you need to remove bounds.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:removeBounds() end)
  print("Camera2D:removeBounds ->", ok, result)
end

--@api-stub: Camera2D:setTarget
-- Sets the follow target position.
-- Call when you need to assign target.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:setTarget(0, 0) end)
  print("Camera2D:setTarget ->", ok, result)
end

--@api-stub: Camera2D:clearTarget
-- Clears the follow target so the camera stops tracking.
-- Call when you need to invoke clear target.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:clearTarget() end)
  print("Camera2D:clearTarget ->", ok, result)
end

--@api-stub: Camera2D:setFollowSmooth
-- Sets the follow smooth interpolation speed (0.0 = instant snap).
-- Call when you need to assign follow smooth.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:setFollowSmooth(nil) end)
  print("Camera2D:setFollowSmooth ->", ok, result)
end

--@api-stub: Camera2D:setDeadZone
-- Sets the dead zone half-extents for camera follow.
-- Call when you need to assign dead zone.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:setDeadZone(100, 100) end)
  print("Camera2D:setDeadZone ->", ok, result)
end

--@api-stub: Camera2D:setLookAhead
-- Sets the look-ahead multiplier for follow prediction.
-- Call when you need to assign look ahead.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:setLookAhead(nil) end)
  print("Camera2D:setLookAhead ->", ok, result)
end

--@api-stub: Camera2D:shake
-- Starts a screen-shake effect.
-- Call when you need to invoke shake.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:shake(nil, 1.0) end)
  print("Camera2D:shake ->", ok, result)
end

--@api-stub: Camera2D:update
-- Advances the camera simulation by dt seconds.
-- Call when you need to invoke update.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("Camera2D:update ->", ok, result)
end

--@api-stub: Camera2D:toWorld
-- Converts screen coordinates to world coordinates.
-- Call when you need to invoke to world.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:toWorld(nil, nil) end)
  print("Camera2D:toWorld ->", ok, result)
end

--@api-stub: Camera2D:toScreen
-- Converts world coordinates to screen coordinates.
-- Call when you need to invoke to screen.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:toScreen(nil, nil) end)
  print("Camera2D:toScreen ->", ok, result)
end

--@api-stub: Camera2D:getVisibleArea
-- Returns the visible world area as x, y, w, h.
-- Call when you need to read visible area.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:getVisibleArea() end)
  print("Camera2D:getVisibleArea ->", ok, result)
end

--@api-stub: Camera2D:lookAt
-- Instantly moves the camera to look at the given position.
-- Call when you need to invoke look at.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:lookAt(0, 0) end)
  print("Camera2D:lookAt ->", ok, result)
end

--@api-stub: Camera2D:move
-- Translates the camera by dx, dy in world space.
-- Call when you need to invoke move.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:move(0, 0) end)
  print("Camera2D:move ->", ok, result)
end

--@api-stub: Camera2D:stopPath
-- Cancels the active camera path animation.
-- Call when you need to invoke stop path.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:stopPath() end)
  print("Camera2D:stopPath ->", ok, result)
end

--@api-stub: Camera2D:updatePath
-- Advances the path animation by `dt` seconds and applies the.
-- Call when you need to invoke update path.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:updatePath(1.0) end)
  print("Camera2D:updatePath ->", ok, result)
end

--@api-stub: Camera2D:pathProgress
-- Returns the fractional progress `[0, 1]` of the active path, or.
-- Call when you need to invoke path progress.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:pathProgress() end)
  print("Camera2D:pathProgress ->", ok, result)
end

--@api-stub: Camera2D:zoomTo
-- Smoothly tweens the camera zoom from its current level to.
-- Call when you need to invoke zoom to.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:zoomTo(nil, 1.0) end)
  print("Camera2D:zoomTo ->", ok, result)
end

--@api-stub: Camera2D:stopZoom
-- Cancels the active zoom tween.
-- Call when you need to invoke stop zoom.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:stopZoom() end)
  print("Camera2D:stopZoom ->", ok, result)
end

--@api-stub: Camera2D:updateZoom
-- Advances the zoom tween by `dt` seconds and applies the resulting.
-- Call when you need to invoke update zoom.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:updateZoom(1.0) end)
  print("Camera2D:updateZoom ->", ok, result)
end

--@api-stub: Camera2D:getParallaxFactor
-- Returns the parallax factor for the named layer, or `1.0` if unset.
-- Call when you need to read parallax factor.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:getParallaxFactor(nil) end)
  print("Camera2D:getParallaxFactor ->", ok, result)
end

--@api-stub: Camera2D:clearParallaxFactors
-- Removes all parallax factor overrides.
-- Call when you need to invoke clear parallax factors.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:clearParallaxFactors() end)
  print("Camera2D:clearParallaxFactors ->", ok, result)
end

--@api-stub: Camera2D:zoomPulse
-- Triggers a momentary zoom-in that decays back via a sine envelope.
-- Call when you need to invoke zoom pulse.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:zoomPulse(nil, 1.0) end)
  print("Camera2D:zoomPulse ->", ok, result)
end

--@api-stub: Camera2D:stopSway
-- Stops the active sway effect immediately.
-- Call when you need to invoke stop sway.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:stopSway() end)
  print("Camera2D:stopSway ->", ok, result)
end

--@api-stub: Camera2D:isSway
-- Returns true if the sway effect is currently active.
-- Call when you need to check is sway.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:isSway() end)
  print("Camera2D:isSway ->", ok, result)
end

--@api-stub: Camera2D:stopBreathing
-- Stops the active breathing effect.
-- Call when you need to invoke stop breathing.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:stopBreathing() end)
  print("Camera2D:stopBreathing ->", ok, result)
end

--@api-stub: Camera2D:isBreathing
-- Returns true if the breathing effect is currently active.
-- Call when you need to check is breathing.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:isBreathing() end)
  print("Camera2D:isBreathing ->", ok, result)
end

--@api-stub: Camera2D:getEffectiveZoom
-- Returns the current zoom level including zoom pulse and breathing deltas.
-- Call when you need to read effective zoom.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:getEffectiveZoom() end)
  print("Camera2D:getEffectiveZoom ->", ok, result)
end

--@api-stub: Camera2D:getEffectOffset
-- Returns the current sway x, y world-space offset.
-- Call when you need to read effect offset.
-- Build a Camera2D via the appropriate lurek.camera.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.camera.newCamera2D(...)
if instance then
  local ok, result = pcall(function() return instance:getEffectOffset() end)
  print("Camera2D:getEffectOffset ->", ok, result)
end

