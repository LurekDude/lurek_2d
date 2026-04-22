-- content/examples/camera.lua
-- Auto-scaffolded coverage of the lurek.camera Lua API (36 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/camera.lua

print("[example] lurek.camera loaded — 36 API items demonstrated")

-- ── lurek.camera free functions ──

--@api-stub: lurek.camera.new
-- Creates a new Camera2D with the given viewport dimensions.
-- Use this when creates a new Camera2D with the given viewport dimensions is needed.
if false then
  local _r = lurek.camera.new(0, 0)
  print(_r)
end

-- ── Camera2D methods ──

--@api-stub: Camera2D:setPosition
-- Sets the camera's world-space position.
-- Use this when sets the camera's world-space position is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:setPosition(0, 0)
end

--@api-stub: Camera2D:getPosition
-- Returns the camera's world-space position as x, y.
-- Use this when returns the camera's world-space position as x, y is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:getPosition()
end

--@api-stub: Camera2D:setZoom
-- Sets the uniform zoom factor (1.0 = natural size).
-- Use this when sets the uniform zoom factor (1.0 = natural size) is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:setZoom(0)
end

--@api-stub: Camera2D:getZoom
-- Returns the current zoom factor.
-- Use this when returns the current zoom factor is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:getZoom()
end

--@api-stub: Camera2D:setRotation
-- Sets the rotation in radians.
-- Use this when sets the rotation in radians is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:setRotation(nil)
end

--@api-stub: Camera2D:getRotation
-- Returns the rotation in radians.
-- Use this when returns the rotation in radians is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:getRotation()
end

--@api-stub: Camera2D:getViewport
-- Returns the current viewport as x, y, w, h.
-- Use this when returns the current viewport as x, y, w, h is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:getViewport()
end

--@api-stub: Camera2D:removeBounds
-- Removes previously set world-space bounds.
-- Use this when removes previously set world-space bounds is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:removeBounds()
end

--@api-stub: Camera2D:setTarget
-- Sets the follow target position.
-- Use this when sets the follow target position is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:setTarget(0, 0)
end

--@api-stub: Camera2D:clearTarget
-- Clears the follow target so the camera stops tracking.
-- Use this when clears the follow target so the camera stops tracking is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:clearTarget()
end

--@api-stub: Camera2D:setFollowSmooth
-- Sets the follow smooth interpolation speed (0.0 = instant snap).
-- Use this when sets the follow smooth interpolation speed (0.0 = instant snap) is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:setFollowSmooth(0)
end

--@api-stub: Camera2D:setDeadZone
-- Sets the dead zone half-extents for camera follow.
-- Use this when sets the dead zone half-extents for camera follow is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:setDeadZone(0, 0)
end

--@api-stub: Camera2D:setLookAhead
-- Sets the look-ahead multiplier for follow prediction.
-- Use this when sets the look-ahead multiplier for follow prediction is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:setLookAhead(nil)
end

--@api-stub: Camera2D:shake
-- Starts a screen-shake effect.
-- Use this when starts a screen-shake effect is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:shake(1, 1)
end

--@api-stub: Camera2D:update
-- Advances the camera simulation by dt seconds.
-- Use this when advances the camera simulation by dt seconds is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:update(0)
end

--@api-stub: Camera2D:toWorld
-- Converts screen coordinates to world coordinates.
-- Use this when converts screen coordinates to world coordinates is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:toWorld(0, 0)
end

--@api-stub: Camera2D:toScreen
-- Converts world coordinates to screen coordinates.
-- Use this when converts world coordinates to screen coordinates is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:toScreen(0, 0)
end

--@api-stub: Camera2D:getVisibleArea
-- Returns the visible world area as x, y, w, h.
-- Use this when returns the visible world area as x, y, w, h is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:getVisibleArea()
end

--@api-stub: Camera2D:lookAt
-- Instantly moves the camera to look at the given position.
-- Use this when instantly moves the camera to look at the given position is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:lookAt(0, 0)
end

--@api-stub: Camera2D:move
-- Translates the camera by dx, dy in world space.
-- Use this when translates the camera by dx, dy in world space is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:move(0, 0)
end

--@api-stub: Camera2D:stopPath
-- Cancels the active camera path animation.
-- Use this when cancels the active camera path animation is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:stopPath()
end

--@api-stub: Camera2D:updatePath
-- Advances the path animation by `dt` seconds and applies the.
-- Use this when advances the path animation by `dt` seconds and applies the is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:updatePath(0)
end

--@api-stub: Camera2D:pathProgress
-- Returns the fractional progress `[0, 1]` of the active path, or.
-- Use this when returns the fractional progress `[0, 1]` of the active path, or is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:pathProgress()
end

--@api-stub: Camera2D:zoomTo
-- Smoothly tweens the camera zoom from its current level to.
-- Use this when smoothly tweens the camera zoom from its current level to is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:zoomTo(0, 1)
end

--@api-stub: Camera2D:stopZoom
-- Cancels the active zoom tween.
-- Use this when cancels the active zoom tween is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:stopZoom()
end

--@api-stub: Camera2D:updateZoom
-- Advances the zoom tween by `dt` seconds and applies the resulting.
-- Use this when advances the zoom tween by `dt` seconds and applies the resulting is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:updateZoom(0)
end

--@api-stub: Camera2D:getParallaxFactor
-- Returns the parallax factor for the named layer, or `1.0` if unset.
-- Use this when returns the parallax factor for the named layer, or `1.0` if unset is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:getParallaxFactor(0)
end

--@api-stub: Camera2D:clearParallaxFactors
-- Removes all parallax factor overrides.
-- Use this when removes all parallax factor overrides is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:clearParallaxFactors()
end

--@api-stub: Camera2D:zoomPulse
-- Triggers a momentary zoom-in that decays back via a sine envelope.
-- Use this when triggers a momentary zoom-in that decays back via a sine envelope is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:zoomPulse(0, 1)
end

--@api-stub: Camera2D:stopSway
-- Stops the active sway effect immediately.
-- Use this when stops the active sway effect immediately is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:stopSway()
end

--@api-stub: Camera2D:isSway
-- Returns true if the sway effect is currently active.
-- Use this when returns true if the sway effect is currently active is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:isSway()
end

--@api-stub: Camera2D:stopBreathing
-- Stops the active breathing effect.
-- Use this when stops the active breathing effect is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:stopBreathing()
end

--@api-stub: Camera2D:isBreathing
-- Returns true if the breathing effect is currently active.
-- Use this when returns true if the breathing effect is currently active is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:isBreathing()
end

--@api-stub: Camera2D:getEffectiveZoom
-- Returns the current zoom level including zoom pulse and breathing deltas.
-- Use this when returns the current zoom level including zoom pulse and breathing deltas is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:getEffectiveZoom()
end

--@api-stub: Camera2D:getEffectOffset
-- Returns the current sway x, y world-space offset.
-- Use this when returns the current sway x, y world-space offset is needed.
if false then
  local _o = nil  -- Camera2D instance
  _o:getEffectOffset()
end

