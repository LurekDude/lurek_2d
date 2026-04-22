-- content/examples/camera.lua
-- Scaffolded coverage of the lurek.camera API (36 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/camera_api.rs   (Lua binding, arg types, return shape)
--   * src/camera/                 (semantics, side effects)
--   * docs/specs/camera.md        (canonical reference)
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
-- Run: cargo run -- content/examples/camera.lua

-- ── lurek.camera.* functions ──

--@api-stub: lurek.camera.new
-- Creates a new Camera2D with the given viewport dimensions.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: lurek.camera.new
  local _todo = "TODO: write a real lurek.camera.new usage example"
  print(_todo)
end

-- ── Camera2D methods ──

--@api-stub: Camera2D:setPosition
-- Sets the camera's world-space position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:setPosition
  local _todo = "TODO: write a real Camera2D:setPosition usage example"
  print(_todo)
end

--@api-stub: Camera2D:getPosition
-- Returns the camera's world-space position as x, y.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:getPosition
  local _todo = "TODO: write a real Camera2D:getPosition usage example"
  print(_todo)
end

--@api-stub: Camera2D:setZoom
-- Sets the uniform zoom factor (1.0 = natural size).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:setZoom
  local _todo = "TODO: write a real Camera2D:setZoom usage example"
  print(_todo)
end

--@api-stub: Camera2D:getZoom
-- Returns the current zoom factor.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:getZoom
  local _todo = "TODO: write a real Camera2D:getZoom usage example"
  print(_todo)
end

--@api-stub: Camera2D:setRotation
-- Sets the rotation in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:setRotation
  local _todo = "TODO: write a real Camera2D:setRotation usage example"
  print(_todo)
end

--@api-stub: Camera2D:getRotation
-- Returns the rotation in radians.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:getRotation
  local _todo = "TODO: write a real Camera2D:getRotation usage example"
  print(_todo)
end

--@api-stub: Camera2D:getViewport
-- Returns the current viewport as x, y, w, h.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:getViewport
  local _todo = "TODO: write a real Camera2D:getViewport usage example"
  print(_todo)
end

--@api-stub: Camera2D:removeBounds
-- Removes previously set world-space bounds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:removeBounds
  local _todo = "TODO: write a real Camera2D:removeBounds usage example"
  print(_todo)
end

--@api-stub: Camera2D:setTarget
-- Sets the follow target position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:setTarget
  local _todo = "TODO: write a real Camera2D:setTarget usage example"
  print(_todo)
end

--@api-stub: Camera2D:clearTarget
-- Clears the follow target so the camera stops tracking.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:clearTarget
  local _todo = "TODO: write a real Camera2D:clearTarget usage example"
  print(_todo)
end

--@api-stub: Camera2D:setFollowSmooth
-- Sets the follow smooth interpolation speed (0.0 = instant snap).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:setFollowSmooth
  local _todo = "TODO: write a real Camera2D:setFollowSmooth usage example"
  print(_todo)
end

--@api-stub: Camera2D:setDeadZone
-- Sets the dead zone half-extents for camera follow.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:setDeadZone
  local _todo = "TODO: write a real Camera2D:setDeadZone usage example"
  print(_todo)
end

--@api-stub: Camera2D:setLookAhead
-- Sets the look-ahead multiplier for follow prediction.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:setLookAhead
  local _todo = "TODO: write a real Camera2D:setLookAhead usage example"
  print(_todo)
end

--@api-stub: Camera2D:shake
-- Starts a screen-shake effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:shake
  local _todo = "TODO: write a real Camera2D:shake usage example"
  print(_todo)
end

--@api-stub: Camera2D:update
-- Advances the camera simulation by dt seconds.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:update
  local _todo = "TODO: write a real Camera2D:update usage example"
  print(_todo)
end

--@api-stub: Camera2D:toWorld
-- Converts screen coordinates to world coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:toWorld
  local _todo = "TODO: write a real Camera2D:toWorld usage example"
  print(_todo)
end

--@api-stub: Camera2D:toScreen
-- Converts world coordinates to screen coordinates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:toScreen
  local _todo = "TODO: write a real Camera2D:toScreen usage example"
  print(_todo)
end

--@api-stub: Camera2D:getVisibleArea
-- Returns the visible world area as x, y, w, h.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:getVisibleArea
  local _todo = "TODO: write a real Camera2D:getVisibleArea usage example"
  print(_todo)
end

--@api-stub: Camera2D:lookAt
-- Instantly moves the camera to look at the given position.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:lookAt
  local _todo = "TODO: write a real Camera2D:lookAt usage example"
  print(_todo)
end

--@api-stub: Camera2D:move
-- Translates the camera by dx, dy in world space.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:move
  local _todo = "TODO: write a real Camera2D:move usage example"
  print(_todo)
end

--@api-stub: Camera2D:stopPath
-- Cancels the active camera path animation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:stopPath
  local _todo = "TODO: write a real Camera2D:stopPath usage example"
  print(_todo)
end

--@api-stub: Camera2D:updatePath
-- Advances the path animation by `dt` seconds and applies the.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:updatePath
  local _todo = "TODO: write a real Camera2D:updatePath usage example"
  print(_todo)
end

--@api-stub: Camera2D:pathProgress
-- Returns the fractional progress `[0, 1]` of the active path, or.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:pathProgress
  local _todo = "TODO: write a real Camera2D:pathProgress usage example"
  print(_todo)
end

--@api-stub: Camera2D:zoomTo
-- Smoothly tweens the camera zoom from its current level to.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:zoomTo
  local _todo = "TODO: write a real Camera2D:zoomTo usage example"
  print(_todo)
end

--@api-stub: Camera2D:stopZoom
-- Cancels the active zoom tween.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:stopZoom
  local _todo = "TODO: write a real Camera2D:stopZoom usage example"
  print(_todo)
end

--@api-stub: Camera2D:updateZoom
-- Advances the zoom tween by `dt` seconds and applies the resulting.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:updateZoom
  local _todo = "TODO: write a real Camera2D:updateZoom usage example"
  print(_todo)
end

--@api-stub: Camera2D:getParallaxFactor
-- Returns the parallax factor for the named layer, or `1.0` if unset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:getParallaxFactor
  local _todo = "TODO: write a real Camera2D:getParallaxFactor usage example"
  print(_todo)
end

--@api-stub: Camera2D:clearParallaxFactors
-- Removes all parallax factor overrides.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:clearParallaxFactors
  local _todo = "TODO: write a real Camera2D:clearParallaxFactors usage example"
  print(_todo)
end

--@api-stub: Camera2D:zoomPulse
-- Triggers a momentary zoom-in that decays back via a sine envelope.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:zoomPulse
  local _todo = "TODO: write a real Camera2D:zoomPulse usage example"
  print(_todo)
end

--@api-stub: Camera2D:stopSway
-- Stops the active sway effect immediately.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:stopSway
  local _todo = "TODO: write a real Camera2D:stopSway usage example"
  print(_todo)
end

--@api-stub: Camera2D:isSway
-- Returns true if the sway effect is currently active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:isSway
  local _todo = "TODO: write a real Camera2D:isSway usage example"
  print(_todo)
end

--@api-stub: Camera2D:stopBreathing
-- Stops the active breathing effect.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:stopBreathing
  local _todo = "TODO: write a real Camera2D:stopBreathing usage example"
  print(_todo)
end

--@api-stub: Camera2D:isBreathing
-- Returns true if the breathing effect is currently active.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:isBreathing
  local _todo = "TODO: write a real Camera2D:isBreathing usage example"
  print(_todo)
end

--@api-stub: Camera2D:getEffectiveZoom
-- Returns the current zoom level including zoom pulse and breathing deltas.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:getEffectiveZoom
  local _todo = "TODO: write a real Camera2D:getEffectiveZoom usage example"
  print(_todo)
end

--@api-stub: Camera2D:getEffectOffset
-- Returns the current sway x, y world-space offset.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/camera_api.rs and docs/specs/camera.md).
do  -- TODO: Camera2D:getEffectOffset
  local _todo = "TODO: write a real Camera2D:getEffectOffset usage example"
  print(_todo)
end

