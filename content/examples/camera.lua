-- content/examples/camera.lua
-- Hand-written coverage of the lurek.camera API (36 items).
--
-- Each Camera2D owns a viewport (screen rect), a world-space position,
-- zoom, rotation, optional bounds clamp, follow target, waypoint path,
-- zoom tween, parallax factors, and effect modulators (shake, sway,
-- breathing, zoom pulse). Construct with lurek.camera.new(w, h) once,
-- then drive it from lurek.process(dt) and read transforms in render.
--
-- Run: cargo run -- content/examples/camera.lua

-- ── lurek.camera.* functions ──

--@api-stub: lurek.camera.new
-- Creates a new Camera2D with the given viewport dimensions.
-- Pass the screen size in pixels; the viewport defines the rect the camera draws into.
do  -- lurek.camera.new
  local cam = lurek.camera.new(1280, 720)
  cam:setPosition(0, 0)
  lurek.log.info("camera viewport=" .. 1280 .. "x" .. 720, "camera")
end

-- ── Camera2D methods ──

--@api-stub: Camera2D:setPosition
-- Sets the camera's world-space position.
-- Snaps the camera origin instantly; for smooth follow use setTarget + setFollowSmooth instead.
do  -- Camera2D:setPosition
  local cam = lurek.camera.new(800, 600)
  local player_x, player_y = 512, 384
  cam:setPosition(player_x - 400, player_y - 300)
end

--@api-stub: Camera2D:getPosition
-- Returns the camera's world-space position as x, y.
-- Useful for HUD overlays that need to know the camera origin to project labels back to screen space.
do  -- Camera2D:getPosition
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(120, 240)
  local cx, cy = cam:getPosition()
  lurek.log.debug("camera at " .. cx .. "," .. cy, "camera")
end

--@api-stub: Camera2D:setZoom
-- Sets the uniform zoom factor (1.0 = natural size).
-- Values >1 zoom in (pixels look bigger), values <1 zoom out; combine with effect deltas via getEffectiveZoom.
do  -- Camera2D:setZoom
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(2.0)
end

--@api-stub: Camera2D:getZoom
-- Returns the current zoom factor.
-- Read this before applying delta-zoom logic (e.g. mouse wheel) so you stack relative changes consistently.
do  -- Camera2D:getZoom
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(1.5)
  local z = cam:getZoom()
  if z > 1.0 then lurek.log.info("zoomed in: " .. z, "camera") end
end

--@api-stub: Camera2D:setRotation
-- Sets the rotation in radians.
-- Rotates the world around the camera origin; use sparingly, rotated cameras break tile-aligned art.
do  -- Camera2D:setRotation
  local cam = lurek.camera.new(800, 600)
  cam:setRotation(math.pi / 8)
end

--@api-stub: Camera2D:getRotation
-- Returns the rotation in radians.
-- Convert to degrees with `math.deg(r)` when displaying in a debug overlay.
do  -- Camera2D:getRotation
  local cam = lurek.camera.new(800, 600)
  cam:setRotation(0.5)
  local r = cam:getRotation()
  lurek.log.debug("rotation rad=" .. r .. " deg=" .. math.deg(r), "camera")
end

--@api-stub: Camera2D:getViewport
-- Returns the current viewport as x, y, w, h.
-- Use after a window resize to confirm the camera matches the new screen rect.
do  -- Camera2D:getViewport
  local cam = lurek.camera.new(1280, 720)
  local vx, vy, vw, vh = cam:getViewport()
  lurek.log.info("viewport=" .. vx .. "," .. vy .. " " .. vw .. "x" .. vh, "camera")
end

--@api-stub: Camera2D:removeBounds
-- Removes previously set world-space bounds.
-- Call this when entering a scrolling boss arena where the camera should not be clamped to the level rect.
do  -- Camera2D:removeBounds
  local cam = lurek.camera.new(800, 600)
  cam:setBounds(0, 0, 4096, 2048)
  cam:removeBounds()
end

--@api-stub: Camera2D:setTarget
-- Sets the follow target position.
-- Update the target every frame to the entity you want to follow; pair with setFollowSmooth for easing.
do  -- Camera2D:setTarget
  local cam = lurek.camera.new(800, 600)
  local enemy = { x = 1024, y = 512 }
  cam:setTarget(enemy.x, enemy.y)
end

--@api-stub: Camera2D:clearTarget
-- Clears the follow target so the camera stops tracking.
-- Call when switching to a cinematic path or when the followed entity dies.
do  -- Camera2D:clearTarget
  local cam = lurek.camera.new(800, 600)
  cam:setTarget(500, 500)
  cam:clearTarget()
end

--@api-stub: Camera2D:setFollowSmooth
-- Sets the follow smooth interpolation speed (0.0 = instant snap).
-- Typical values 4-10; higher = snappier; 0 makes setTarget behave like setPosition.
do  -- Camera2D:setFollowSmooth
  local cam = lurek.camera.new(800, 600)
  cam:setFollowSmooth(6.0)
end

--@api-stub: Camera2D:setDeadZone
-- Sets the dead zone half-extents for camera follow.
-- Inside this rect the camera ignores target motion; good for stopping platformer jitter on small jumps.
do  -- Camera2D:setDeadZone
  local cam = lurek.camera.new(800, 600)
  cam:setDeadZone(40, 24)
end

--@api-stub: Camera2D:setLookAhead
-- Sets the look-ahead multiplier for follow prediction.
-- Multiplier of the target's velocity offset; 0.25 nudges the camera ahead so the player sees what's coming.
do  -- Camera2D:setLookAhead
  local cam = lurek.camera.new(800, 600)
  cam:setLookAhead(0.25)
end

--@api-stub: Camera2D:shake
-- Starts a screen-shake effect.
-- Trigger on hits, explosions, landings; intensity in pixels, duration in seconds.
do  -- Camera2D:shake
  local cam = lurek.camera.new(800, 600)
  cam:shake(8.0, 0.35)
end

--@api-stub: Camera2D:update
-- Advances the camera simulation by dt seconds.
-- Call once per frame from lurek.process(dt); this advances follow, shake, and bounds clamping.
do  -- Camera2D:update
  local cam = lurek.camera.new(800, 600)
  function lurek.process(dt) cam:update(dt) end
end

--@api-stub: Camera2D:toWorld
-- Converts screen coordinates to world coordinates.
-- Use to translate a mouse click into the world point the player aimed at.
do  -- Camera2D:toWorld
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(200, 100)
  local wx, wy = cam:toWorld(400, 300)
  lurek.log.debug("click world=" .. wx .. "," .. wy, "input")
end

--@api-stub: Camera2D:toScreen
-- Converts world coordinates to screen coordinates.
-- Project entity positions to pixels for HUD pointers, damage numbers, or off-screen indicators.
do  -- Camera2D:toScreen
  local cam = lurek.camera.new(800, 600)
  local enemy_wx, enemy_wy = 1024, 512
  local sx, sy = cam:toScreen(enemy_wx, enemy_wy)
  if sx >= 0 and sx < 800 then lurek.log.debug("enemy on-screen at " .. sx .. "," .. sy, "hud") end
end

--@api-stub: Camera2D:getVisibleArea
-- Returns the visible world area as x, y, w, h.
-- Cull entities outside this rect before drawing to skip off-screen sprites.
do  -- Camera2D:getVisibleArea
  local cam = lurek.camera.new(800, 600)
  local vx, vy, vw, vh = cam:getVisibleArea()
  lurek.log.info("visible " .. vx .. "," .. vy .. " " .. vw .. "x" .. vh, "render")
end

--@api-stub: Camera2D:lookAt
-- Instantly moves the camera to look at the given position.
-- Convenience wrapper around setPosition that centres the viewport on the point; use for scene cuts.
do  -- Camera2D:lookAt
  local cam = lurek.camera.new(800, 600)
  cam:lookAt(2048, 1024)
end

--@api-stub: Camera2D:move
-- Translates the camera by dx, dy in world space.
-- Wire to WASD-style free-look during edit mode, scaled by dt for frame-rate independence.
do  -- Camera2D:move
  local cam = lurek.camera.new(800, 600)
  function lurek.process(dt) cam:move(200 * dt, 0) end
end

--@api-stub: Camera2D:stopPath
-- Cancels the active camera path animation.
-- Call when the player regains control mid-cutscene so the camera returns to follow mode.
do  -- Camera2D:stopPath
  local cam = lurek.camera.new(800, 600)
  cam:followPath({ {0, 0}, {500, 500} }, 3.0)
  cam:stopPath()
end

--@api-stub: Camera2D:updatePath
-- Advances the path animation by `dt` seconds and applies the resulting position.
-- Returns true while the path is still active; switch back to follow when it returns false.
do  -- Camera2D:updatePath
  local cam = lurek.camera.new(800, 600)
  cam:followPath({ {0, 0}, {800, 600}, {0, 600} }, 4.0)
  function lurek.process(dt) if not cam:updatePath(dt) then cam:setTarget(400, 300) end end
end

--@api-stub: Camera2D:pathProgress
-- Returns the fractional progress `[0, 1]` of the active path, or `1` if none is running.
-- Drive a cinematic letterbox fade out as progress approaches 1.0.
do  -- Camera2D:pathProgress
  local cam = lurek.camera.new(800, 600)
  cam:followPath({ {0, 0}, {1000, 0} }, 2.0)
  local p = cam:pathProgress()
  lurek.log.debug("path " .. math.floor(p * 100) .. "%", "cutscene")
end

--@api-stub: Camera2D:zoomTo
-- Smoothly tweens the camera zoom from its current level to target_zoom over duration seconds.
-- Use for boss-intro pull-back or pull-in punch zooms; pair with updateZoom each frame.
do  -- Camera2D:zoomTo
  local cam = lurek.camera.new(800, 600)
  cam:zoomTo(2.5, 0.8)
end

--@api-stub: Camera2D:stopZoom
-- Cancels the active zoom tween.
-- Call when the player interrupts a cutscene zoom so the current zoom freezes in place.
do  -- Camera2D:stopZoom
  local cam = lurek.camera.new(800, 600)
  cam:zoomTo(3.0, 1.0)
  cam:stopZoom()
end

--@api-stub: Camera2D:updateZoom
-- Advances the zoom tween by dt seconds and applies the resulting zoom level.
-- Returns true while still tweening; check this to know when to fire the next stage of a sequence.
do  -- Camera2D:updateZoom
  local cam = lurek.camera.new(800, 600)
  cam:zoomTo(1.5, 0.6)
  function lurek.process(dt) if not cam:updateZoom(dt) then lurek.log.debug("zoom done", "camera") end end
end

--@api-stub: Camera2D:getParallaxFactor
-- Returns the parallax factor for the named layer, or `1.0` if unset.
-- Multiply layer scroll positions by this when drawing background tiles to fake depth.
do  -- Camera2D:getParallaxFactor
  local cam = lurek.camera.new(800, 600)
  cam:setParallaxFactor("clouds", 0.2)
  local f = cam:getParallaxFactor("clouds")
  lurek.log.debug("clouds parallax=" .. f, "render")
end

--@api-stub: Camera2D:clearParallaxFactors
-- Removes all parallax factor overrides.
-- Reset when loading a new level so old layer names from the previous scene do not leak.
do  -- Camera2D:clearParallaxFactors
  local cam = lurek.camera.new(800, 600)
  cam:setParallaxFactor("sky", 0.1)
  cam:clearParallaxFactors()
end

--@api-stub: Camera2D:zoomPulse
-- Triggers a momentary zoom-in that decays back via a sine envelope.
-- Use for impact feedback (criticals, parries); amplitude ~0.05 is subtle, 0.15 is dramatic.
do  -- Camera2D:zoomPulse
  local cam = lurek.camera.new(800, 600)
  cam:zoomPulse(0.08, 0.25)
end

--@api-stub: Camera2D:stopSway
-- Stops the active sway effect immediately.
-- Call when the player leaves the boat / vehicle that started the sway.
do  -- Camera2D:stopSway
  local cam = lurek.camera.new(800, 600)
  cam:startSway(4, 2, 0.8)
  cam:stopSway()
end

--@api-stub: Camera2D:isSway
-- Returns true if the sway effect is currently active.
-- Use to gate a UI prompt like "press E to disembark" only while sway is running.
do  -- Camera2D:isSway
  local cam = lurek.camera.new(800, 600)
  cam:startSway(3, 1.5, 0.5)
  if cam:isSway() then lurek.log.debug("on swaying surface", "camera") end
end

--@api-stub: Camera2D:stopBreathing
-- Stops the active breathing effect.
-- Call when entering a held-breath stealth section so the camera goes perfectly still.
do  -- Camera2D:stopBreathing
  local cam = lurek.camera.new(800, 600)
  cam:startBreathing(0.005, 0.2)
  cam:stopBreathing()
end

--@api-stub: Camera2D:isBreathing
-- Returns true if the breathing effect is currently active.
-- Useful for tests that assert the "living camera" toggle is correctly turned off in pause menus.
do  -- Camera2D:isBreathing
  local cam = lurek.camera.new(800, 600)
  cam:startBreathing()
  if cam:isBreathing() then lurek.log.debug("breathing on", "camera") end
end

--@api-stub: Camera2D:getEffectiveZoom
-- Returns the current zoom level including zoom pulse and breathing deltas.
-- Use this (not getZoom) when projecting world geometry so pulse/breath visually affect rendering.
do  -- Camera2D:getEffectiveZoom
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(1.5)
  cam:zoomPulse(0.1, 0.3)
  local ez = cam:getEffectiveZoom()
  lurek.log.debug("effective zoom=" .. ez, "render")
end

--@api-stub: Camera2D:getEffectOffset
-- Returns the current sway x, y world-space offset.
-- Add to the camera position when computing per-frame draw offsets so sway is visible on screen.
do  -- Camera2D:getEffectOffset
  local cam = lurek.camera.new(800, 600)
  cam:startSway(6, 3, 0.6)
  local ox, oy = cam:getEffectOffset()
  lurek.log.debug("sway offset " .. ox .. "," .. oy, "camera")
end

--@api-stub: Camera2D:apply
-- Applies the camera transform to the render stack.
-- Call inside lurek.render() before drawing world-space objects; pop with lurek.render.pop().
do  -- Camera2D:apply
  local cam = lurek.camera.new()
  cam:setPosition(400, 300)
  cam:setZoom(1.5)
  cam:apply()
  lurek.log.info("camera applied", "camera")
end

--@api-stub: Camera2D:attach
-- Attaches the camera so it is automatically applied each render frame.
-- No manual apply() call needed; the engine uses the last attached camera.
do  -- Camera2D:attach
  local cam = lurek.camera.new()
  cam:setPosition(200, 150)
  cam:attach()
  lurek.log.info("camera attached", "camera")
end

--@api-stub: Camera2D:detach
-- Detaches the camera from automatic rendering, restoring the identity transform.
-- Call when switching to HUD or UI rendering that uses screen-space coordinates.
do  -- Camera2D:detach
  local cam = lurek.camera.new()
  cam:attach()
  cam:detach()
  lurek.log.info("camera detached", "camera")
end

--@api-stub: Camera2D:followPath
-- Makes the camera follow a pre-defined waypoint path over time.
-- Pass a table of {x, y} waypoints and a speed; fires a callback when the path ends.
do  -- Camera2D:followPath
  local cam = lurek.camera.new()
  local path = {{x=0,y=0},{x=200,y=100},{x=400,y=0}}
  cam:followPath(path, 120)
  lurek.log.info("following path", "camera")
end

--@api-stub: lurek.camera.newCamera
-- Creates a named Camera2D and registers it with the camera manager.
-- Named cameras can be retrieved later by name for scene-switching.
do  -- lurek.camera.newCamera
  local cam = lurek.camera.newCamera(800, 600)
  cam:setPosition(400, 300)
  cam:setZoom(1.0)
  lurek.log.info("named camera created", "camera")
end

--@api-stub: Camera2D:reset
-- Resets position, zoom, and rotation to defaults and clears all active effects.
-- Use at scene transitions to avoid leftover state from the previous scene.
do  -- Camera2D:reset
  local cam = lurek.camera.new()
  cam:setZoom(2.5)
  cam:reset()
  lurek.log.info("zoom after reset: " .. cam:getZoom(), "camera")
end

--@api-stub: Camera2D:setBounds
-- Clamps camera movement so the visible area never exceeds the given world rectangle.
-- Prevents the camera from showing empty space past level edges.
do  -- Camera2D:setBounds
  local cam = lurek.camera.new()
  cam:setBounds(0, 0, 3200, 2400)
  cam:setPosition(400, 300)
  lurek.log.info("bounds set", "camera")
end

--@api-stub: Camera2D:setParallaxFactor
-- Sets the scroll factor for a named parallax layer relative to the camera.
-- factor=0 pins the layer (sky), factor=1 moves with the world.
do  -- Camera2D:setParallaxFactor
  local cam = lurek.camera.new()
  cam:setParallaxFactor("bg_mountains", 0.3)
  cam:setParallaxFactor("bg_clouds", 0.15)
  lurek.log.info("parallax factors set", "camera")
end

--@api-stub: Camera2D:setViewport
-- Restricts rendering to a sub-region of the window (split-screen or minimap).
-- Values are in window pixels; set to nil to restore full-window rendering.
do  -- Camera2D:setViewport
  local cam = lurek.camera.new()
  cam:setViewport(0, 0, 640, 480)
  lurek.log.info("viewport set", "camera")
end

--@api-stub: Camera2D:startBreathing
-- Starts a subtle breathing oscillation that adds life to a static camera.
-- amplitude controls pixel displacement; period controls cycle time in seconds.
do  -- Camera2D:startBreathing
  local cam = lurek.camera.new()
  cam:startBreathing(2.0, 4.0)
  lurek.log.info("breathing: " .. tostring(cam:isBreathing()), "camera")
end

--@api-stub: Camera2D:startSway
-- Starts a sinusoidal lateral sway effect (boat rocking, earthquake tremor).
-- amplitude is pixels, frequency is cycles-per-second, damping decays the effect.
do  -- Camera2D:startSway
  local cam = lurek.camera.new()
  cam:startSway(5.0, 0.8, 0.95)
  lurek.log.info("sway active: " .. tostring(cam:isSway()), "camera")
end

-- =============================================================================
-- STUBS: 2 uncovered lurek.camera API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Camera2D methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Camera2D:type -------------------------------------------------
--@api-stub: Camera2D:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- camera2D_stub:type()  -- -> string
-- (replace camera2D_stub with your real Camera2D instance above)

-- ---- Stub: Camera2D:typeOf -----------------------------------------------
--@api-stub: Camera2D:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- camera2D_stub:typeOf("hero")  -- -> boolean
-- (replace camera2D_stub with your real Camera2D instance above)

-- =============================================================================
-- STUBS: 2 uncovered lurek.camera API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LCamera methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCamera:type --------------------------------------------------
--@api-stub: LCamera:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:type()  -- -> string
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:typeOf ------------------------------------------------
--@api-stub: LCamera:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:typeOf("hero")  -- -> boolean
-- (replace lCamera_stub with your real LCamera instance above)

-- =============================================================================
-- STUBS: 45 uncovered lurek.camera API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LCamera methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LCamera:setPosition -------------------------------------------
--@api-stub: LCamera:setPosition
-- Sets the camera's world-space position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setPosition(0.0, 0.0)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:getPosition -------------------------------------------
--@api-stub: LCamera:getPosition
-- Returns the camera's world-space position as x, y.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:getPosition()  -- -> number, number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setZoom -----------------------------------------------
--@api-stub: LCamera:setZoom
-- Sets the uniform zoom factor (1.0 = natural size).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setZoom(zoom)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:getZoom -----------------------------------------------
--@api-stub: LCamera:getZoom
-- Returns the current zoom factor.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:getZoom()  -- -> number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setRotation -------------------------------------------
--@api-stub: LCamera:setRotation
-- Sets the rotation in radians.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setRotation(1.0)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:getRotation -------------------------------------------
--@api-stub: LCamera:getRotation
-- Returns the rotation in radians.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:getRotation()  -- -> number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setViewport -------------------------------------------
--@api-stub: LCamera:setViewport
-- Sets the viewport rectangle in screen pixels.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setViewport(0.0, 0.0, 64.0, 64.0)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:getViewport -------------------------------------------
--@api-stub: LCamera:getViewport
-- Returns the current viewport as x, y, w, h.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:getViewport()  -- -> number, number, number, number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setBounds ---------------------------------------------
--@api-stub: LCamera:setBounds
-- Sets world-space bounds for camera clamping.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setBounds(0.0, 0.0, 64.0, 64.0)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:removeBounds ------------------------------------------
--@api-stub: LCamera:removeBounds
-- Removes previously set world-space bounds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:removeBounds()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setTarget ---------------------------------------------
--@api-stub: LCamera:setTarget
-- Sets the follow target position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setTarget(0.0, 0.0)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:clearTarget -------------------------------------------
--@api-stub: LCamera:clearTarget
-- Clears the follow target so the camera stops tracking.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:clearTarget()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setFollowSmooth ---------------------------------------
--@api-stub: LCamera:setFollowSmooth
-- Sets the follow smooth interpolation speed (0.0 = instant snap).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setFollowSmooth(120.0)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setDeadZone -------------------------------------------
--@api-stub: LCamera:setDeadZone
-- Sets the dead zone half-extents for camera follow.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setDeadZone(64.0, 64.0)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setLookAhead ------------------------------------------
--@api-stub: LCamera:setLookAhead
-- Sets the look-ahead multiplier for follow prediction.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setLookAhead(mul)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:shake -------------------------------------------------
--@api-stub: LCamera:shake
-- Starts a screen-shake effect.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:shake(intensity, duration)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:update ------------------------------------------------
--@api-stub: LCamera:update
-- Advances the camera simulation by dt seconds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:update(0.016)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:toWorld -----------------------------------------------
--@api-stub: LCamera:toWorld
-- Converts screen coordinates to world coordinates.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:toWorld(1.0, 1.0)  -- -> number, number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:toScreen ----------------------------------------------
--@api-stub: LCamera:toScreen
-- Converts world coordinates to screen coordinates.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:toScreen(wx, wy)  -- -> number, number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:getVisibleArea ----------------------------------------
--@api-stub: LCamera:getVisibleArea
-- Returns the visible world area as x, y, w, h.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:getVisibleArea()  -- -> number, number, number, number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:lookAt ------------------------------------------------
--@api-stub: LCamera:lookAt
-- Instantly moves the camera to look at the given position.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:lookAt(0.0, 0.0)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:move --------------------------------------------------
--@api-stub: LCamera:move
-- Translates the camera by dx, dy in world space.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:move(dx, dy)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:followPath --------------------------------------------
--@api-stub: LCamera:followPath
-- Animates the camera along a sequence of world-space waypoints over
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:followPath(points, duration)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:stopPath ----------------------------------------------
--@api-stub: LCamera:stopPath
-- Cancels the active camera path animation.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:stopPath()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:updatePath --------------------------------------------
--@api-stub: LCamera:updatePath
-- Advances the path animation by `dt` seconds and applies the
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:updatePath(0.016)  -- -> boolean
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:pathProgress ------------------------------------------
--@api-stub: LCamera:pathProgress
-- Returns the fractional progress `[0, 1]` of the active path, or
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:pathProgress()  -- -> number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:zoomTo ------------------------------------------------
--@api-stub: LCamera:zoomTo
-- Smoothly tweens the camera zoom from its current level to
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:zoomTo(target_zoom, duration)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:stopZoom ----------------------------------------------
--@api-stub: LCamera:stopZoom
-- Cancels the active zoom tween.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:stopZoom()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:updateZoom --------------------------------------------
--@api-stub: LCamera:updateZoom
-- Advances the zoom tween by `dt` seconds and applies the resulting
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:updateZoom(0.016)  -- -> boolean
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:setParallaxFactor -------------------------------------
--@api-stub: LCamera:setParallaxFactor
-- Sets the parallax scroll factor for the named render layer.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:setParallaxFactor(1, factor)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:getParallaxFactor -------------------------------------
--@api-stub: LCamera:getParallaxFactor
-- Returns the parallax factor for the named layer, or `1.0` if unset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:getParallaxFactor(1)  -- -> number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:clearParallaxFactors ----------------------------------
--@api-stub: LCamera:clearParallaxFactors
-- Removes all parallax factor overrides.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:clearParallaxFactors()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:apply -------------------------------------------------
--@api-stub: LCamera:apply
-- Applies this camera's transform to the render stack.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:apply()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:reset -------------------------------------------------
--@api-stub: LCamera:reset
-- Pops the camera transform from the render stack.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:reset()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:attach ------------------------------------------------
--@api-stub: LCamera:attach
-- Alias for `apply()`. Applies this camera's transform to the render stack.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:attach()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:detach ------------------------------------------------
--@api-stub: LCamera:detach
-- Alias for `reset()`. Pops the camera transform from the render stack.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:detach()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:zoomPulse ---------------------------------------------
--@api-stub: LCamera:zoomPulse
-- Triggers a momentary zoom-in that decays back via a sine envelope.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:zoomPulse(amplitude, duration)
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:startSway ---------------------------------------------
--@api-stub: LCamera:startSway
-- Starts a sinusoidal x/y offset oscillation (e.g., boat rocking).
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:startSway(amplitude_x, amplitude_y, frequency, [decay])
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:stopSway ----------------------------------------------
--@api-stub: LCamera:stopSway
-- Stops the active sway effect immediately.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:stopSway()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:isSway ------------------------------------------------
--@api-stub: LCamera:isSway
-- Returns true if the sway effect is currently active.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:isSway()  -- -> boolean
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:startBreathing ----------------------------------------
--@api-stub: LCamera:startBreathing
-- Starts a subtle periodic zoom oscillation for a "living camera" feel.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:startBreathing([amplitude], [rate])
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:stopBreathing -----------------------------------------
--@api-stub: LCamera:stopBreathing
-- Stops the active breathing effect.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:stopBreathing()
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:isBreathing -------------------------------------------
--@api-stub: LCamera:isBreathing
-- Returns true if the breathing effect is currently active.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:isBreathing()  -- -> boolean
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:getEffectiveZoom --------------------------------------
--@api-stub: LCamera:getEffectiveZoom
-- Returns the current zoom level including zoom pulse and breathing deltas.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:getEffectiveZoom()  -- -> number
-- (replace lCamera_stub with your real LCamera instance above)

-- ---- Stub: LCamera:getEffectOffset ---------------------------------------
--@api-stub: LCamera:getEffectOffset
-- Returns the current sway x, y world-space offset.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lCamera_stub:getEffectOffset()  -- -> number, number
-- (replace lCamera_stub with your real LCamera instance above)
