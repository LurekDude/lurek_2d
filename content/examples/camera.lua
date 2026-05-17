-- content/examples/camera.lua
-- lurek.camera API examples.
-- Run: cargo run -- content/examples/camera.lua

-- =============================================================================
-- Constructor functions
-- =============================================================================

--@api-stub: lurek.camera.new
-- Creates a 2D camera with optional virtual viewport size
do
  -- The virtual viewport defines how many world units the camera "sees".
  -- A 1280x720 camera shows a 1280x720 rectangle of the game world at zoom 1.0.
  -- If you omit the arguments, the defaults are 800x600.
  local cam = lurek.camera.new(1280, 720)

  -- The camera starts at position (0,0), meaning the top-left of the viewport
  -- maps to world origin. Use setPosition or lookAt to center it elsewhere.
  cam:setPosition(0, 0)
  lurek.log.info("camera viewport=1280x720", "camera")
end

--@api-stub: lurek.camera.newCamera
-- Creates a 2D camera with optional virtual viewport size
do
  -- newCamera is an alias for lurek.camera.new — use whichever reads better.
  -- Common pattern: create one camera per game scene or layer.
  local cam = lurek.camera.newCamera(800, 600)
  cam:setPosition(400, 300)
  cam:setZoom(1.0)
  lurek.log.info("named camera created", "camera")
end

--@api-stub: lurek.camera.newRig
-- Creates an empty named camera rig
do
  -- A camera rig manages multiple named cameras with automatic viewport layout.
  -- Use it for split-screen, minimap, or picture-in-picture setups.
  local rig = lurek.camera.newRig()

  -- splitScreen creates "left" and "right" cameras covering half the window each.
  rig:splitScreen(1280, 720)
  local names = rig:names()
  lurek.log.info("rig camera count=" .. tostring(#names), "camera")
end

-- =============================================================================
-- Camera2D methods (legacy interface — same object, different type name)
-- =============================================================================

--@api-stub: LCameraRig:setPosition
-- Sets the position of this camera2d.
do
  -- Camera position is the world coordinate at the top-left of the viewport.
  -- To center the camera on the player, offset by half the viewport size.
  local cam = lurek.camera.new(800, 600)
  local player_x, player_y = 512, 384
  -- Center the player in the viewport:
  cam:setPosition(player_x - 400, player_y - 300)
end

--@api-stub: LCamera:getPosition
-- Returns the position of this camera2d.
do
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(120, 240)
  -- Returns two values: x and y in world units
  local cx, cy = cam:getPosition()
  lurek.log.debug("camera at " .. cx .. "," .. cy, "camera")
end

--@api-stub: LCameraRig:setZoom
-- Sets the zoom of this camera2d.
do
  -- Zoom > 1.0 magnifies (shows less world area).
  -- Zoom < 1.0 shrinks (shows more world area).
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(2.0) -- 2x magnification, viewport shows 400x300 world units
end

--@api-stub: LCamera:getZoom
-- Returns the zoom of this camera2d.
do
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(1.5)
  local z = cam:getZoom()
  if z > 1.0 then lurek.log.info("zoomed in: " .. z, "camera") end
end

--@api-stub: LCamera:setRotation
-- Sets the rotation of this camera2d.
do
  -- Rotation is in radians. The world rotates around the camera center.
  -- Use sparingly — good for tilt effects on hit or vehicle banking.
  local cam = lurek.camera.new(800, 600)
  cam:setRotation(math.pi / 8) -- 22.5 degrees
end

--@api-stub: LCamera:getRotation
-- Returns the rotation of this camera2d.
do
  local cam = lurek.camera.new(800, 600)
  cam:setRotation(0.5)
  local r = cam:getRotation()
  lurek.log.debug("rotation rad=" .. r .. " deg=" .. math.deg(r), "camera")
end

--@api-stub: LCameraRig:getViewport
-- Returns the viewport of this camera2d.
do
  -- Returns x, y, width, height of the screen rectangle this camera renders into.
  local cam = lurek.camera.new(1280, 720)
  local vx, vy, vw, vh = cam:getViewport()
  lurek.log.info("viewport=" .. vx .. "," .. vy .. " " .. vw .. "x" .. vh, "camera")
end

--@api-stub: LCamera:removeBounds
-- Removes a bounds from this camera2d.
do
  -- After removing bounds, the camera is free to move anywhere.
  local cam = lurek.camera.new(800, 600)
  cam:setBounds(0, 0, 4096, 2048)
  cam:removeBounds()
end

--@api-stub: LCameraRig:setTarget
-- Sets the target of this camera2d.
do
  -- Setting a target makes the camera follow that world point.
  -- Combine with setFollowSmooth for gradual lerp movement.
  local cam = lurek.camera.new(800, 600)
  local enemy = { x = 1024, y = 512 }
  cam:setTarget(enemy.x, enemy.y)
end

--@api-stub: LCamera:clearTarget
-- Clears all target items from this camera2d.
do
  -- After clearing, the camera stops moving toward any target.
  -- Use when switching from follow mode to manual camera control.
  local cam = lurek.camera.new(800, 600)
  cam:setTarget(500, 500)
  cam:clearTarget()
end

--@api-stub: LCamera:setFollowSmooth
-- Sets the follow smooth of this camera2d.
do
  -- Higher values = camera catches up faster. Lower = more cinematic lag.
  -- A value of 6.0 is responsive for action games; 2.0 is slow and cinematic.
  local cam = lurek.camera.new(800, 600)
  cam:setFollowSmooth(6.0)
end

--@api-stub: LCamera:setDeadZone
-- Sets the dead zone of this camera2d.
do
  -- The dead zone is a rectangle around screen center where the target
  -- can move without the camera following. Good for platformers where
  -- small horizontal movement shouldn't trigger camera motion.
  local cam = lurek.camera.new(800, 600)
  cam:setDeadZone(40, 24) -- 40px wide, 24px tall
end

--@api-stub: LCamera:setLookAhead
-- Sets the look ahead of this camera2d.
do
  -- Look-ahead shifts the camera in the direction of target movement,
  -- showing more of the world ahead of the player. A multiplier of 0.25
  -- means the camera leads the target by 25% of its velocity.
  local cam = lurek.camera.new(800, 600)
  cam:setLookAhead(0.25)
end

--@api-stub: LCamera:shake
-- Performs the shake operation on this camera2d.
do
  -- Screen shake is essential for game feel: explosions, hits, landing impacts.
  -- intensity = max pixel offset per frame; duration = seconds until decay ends.
  local cam = lurek.camera.new(800, 600)
  cam:shake(8.0, 0.35) -- 8px intensity, lasts 0.35 seconds
end

--@api-stub: LCamera:update
-- Advances this camera2d by the given delta time.
do
  -- Call update() every frame to advance follow interpolation, shake decay,
  -- breathing, and sway effects. Without it, effects stay frozen.
  local cam = lurek.camera.new(800, 600)
  function lurek.process(dt) cam:update(dt) end
end

--@api-stub: LCamera:toWorld
-- Performs the to world operation on this camera2d.
do
  -- Convert mouse click screen coordinates to world position.
  -- Essential for selecting objects, placing buildings, aiming weapons.
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(200, 100)
  local wx, wy = cam:toWorld(400, 300) -- screen center -> world coords
  lurek.log.debug("click world=" .. wx .. "," .. wy, "input")
end

--@api-stub: LCamera:toScreen
-- Performs the to screen operation on this camera2d.
do
  -- Convert a world-space object position to screen coordinates.
  -- Use for HUD indicators, health bars above entities, or visibility checks.
  local cam = lurek.camera.new(800, 600)
  local enemy_wx, enemy_wy = 1024, 512
  local sx, sy = cam:toScreen(enemy_wx, enemy_wy)
  if sx >= 0 and sx < 800 then lurek.log.debug("enemy on-screen at " .. sx .. "," .. sy, "hud") end
end

--@api-stub: LCamera:getVisibleArea
-- Returns the visible area of this camera2d.
do
  -- Returns x, y, width, height in world units of what the camera currently sees.
  -- Use for culling: skip drawing objects outside this rectangle.
  local cam = lurek.camera.new(800, 600)
  local vx, vy, vw, vh = cam:getVisibleArea()
  lurek.log.info("visible " .. vx .. "," .. vy .. " " .. vw .. "x" .. vh, "render")
end

--@api-stub: LCamera:lookAt
-- Performs the look at operation on this camera2d.
do
  -- lookAt centers the camera so that (x, y) is in the middle of the viewport.
  -- Unlike setPosition, you give the center point, not the top-left corner.
  local cam = lurek.camera.new(800, 600)
  cam:lookAt(2048, 1024) -- center camera on (2048, 1024)
end

--@api-stub: LCamera:move
-- Performs the move operation on this camera2d.
do
  -- Move adds a delta to the current position. Good for editor-style panning
  -- with keyboard or dragging.
  local cam = lurek.camera.new(800, 600)
  function lurek.process(dt) cam:move(200 * dt, 0) end -- pan right at 200 units/s
end

--@api-stub: LCamera:stopPath
-- Stops the current operation or playback on this camera2d.
do
  -- Halts a followPath in progress, freezing the camera at its current position.
  local cam = lurek.camera.new(800, 600)
  cam:followPath({ {0, 0}, {500, 500} }, 3.0)
  cam:stopPath()
end

--@api-stub: LCamera:updatePath
-- Advances path this camera2d by the given delta time.
do
  -- updatePath returns true while the path is still in progress,
  -- and false once it finishes. Use this to chain into normal follow mode.
  local cam = lurek.camera.new(800, 600)
  cam:followPath({ {0, 0}, {800, 600}, {0, 600} }, 4.0)
  function lurek.process(dt)
    if not cam:updatePath(dt) then
      -- Path finished — switch to player follow
      cam:setTarget(400, 300)
    end
  end
end

--@api-stub: LCamera:pathProgress
-- Performs the path progress operation on this camera2d.
do
  -- Returns 0.0 at path start, 1.0 at completion.
  -- Use for HUD progress bars during cutscene camera movements.
  local cam = lurek.camera.new(800, 600)
  cam:followPath({ {0, 0}, {1000, 0} }, 2.0)
  local p = cam:pathProgress()
  lurek.log.debug("path " .. math.floor(p * 100) .. "%", "cutscene")
end

--@api-stub: LCamera:zoomTo
-- Performs the zoom to operation on this camera2d.
do
  -- Smooth zoom tween over time. Good for focus transitions:
  -- zooming into a dialogue or pulling back to reveal the map.
  local cam = lurek.camera.new(800, 600)
  cam:zoomTo(2.5, 0.8) -- target zoom 2.5x over 0.8 seconds
end

--@api-stub: LCamera:stopZoom
-- Stops the current operation or playback on this camera2d.
do
  -- Halts a zoomTo tween in progress, keeping the current zoom level.
  local cam = lurek.camera.new(800, 600)
  cam:zoomTo(3.0, 1.0)
  cam:stopZoom()
end

--@api-stub: LCamera:updateZoom
-- Advances zoom this camera2d by the given delta time.
do
  -- Like updatePath, returns true while the tween is active, false when done.
  local cam = lurek.camera.new(800, 600)
  cam:zoomTo(1.5, 0.6)
  function lurek.process(dt)
    if not cam:updateZoom(dt) then
      lurek.log.debug("zoom done", "camera")
    end
  end
end

--@api-stub: LCamera:getParallaxFactor
-- Returns the parallax factor of this camera2d.
do
  -- Factor = how much a layer scrolls relative to the camera.
  -- 1.0 = moves with camera (foreground). 0.0 = static (sky/background).
  -- 0.2 = slow scroll, good for distant clouds.
  local cam = lurek.camera.new(800, 600)
  cam:setParallaxFactor("clouds", 0.2)
  local f = cam:getParallaxFactor("clouds")
  lurek.log.debug("clouds parallax=" .. f, "render")
end

--@api-stub: LCamera:clearParallaxFactors
-- Clears all parallax factors items from this camera2d.
do
  -- Resets all named layers back to the default factor of 1.0.
  local cam = lurek.camera.new(800, 600)
  cam:setParallaxFactor("sky", 0.1)
  cam:clearParallaxFactors()
end

--@api-stub: LCamera:zoomPulse
-- Performs the zoom pulse operation on this camera2d.
do
  -- A short zoom burst that decays — great for hit feedback or pickups.
  -- amplitude = additional zoom factor; duration = decay time.
  local cam = lurek.camera.new(800, 600)
  cam:zoomPulse(0.08, 0.25) -- +8% zoom pulse decaying over 0.25s
end

--@api-stub: LCamera:stopSway
-- Stops the current operation or playback on this camera2d.
do
  local cam = lurek.camera.new(800, 600)
  cam:startSway(4, 2, 0.8)
  cam:stopSway()
end

--@api-stub: LCamera:isSway
-- Returns true if this camera2d sway.
do
  local cam = lurek.camera.new(800, 600)
  cam:startSway(3, 1.5, 0.5)
  if cam:isSway() then lurek.log.debug("on swaying surface", "camera") end
end

--@api-stub: LCamera:stopBreathing
-- Stops the current operation or playback on this camera2d.
do
  local cam = lurek.camera.new(800, 600)
  cam:startBreathing(0.005, 0.2)
  cam:stopBreathing()
end

--@api-stub: LCamera:isBreathing
-- Returns true if this camera2d breathing.
do
  local cam = lurek.camera.new(800, 600)
  cam:startBreathing()
  if cam:isBreathing() then lurek.log.debug("breathing on", "camera") end
end

--@api-stub: LCamera:getEffectiveZoom
-- Returns the effective zoom of this camera2d.
do
  -- getEffectiveZoom includes pulse and breathing effects on top of the base zoom.
  -- Use this for rendering calculations instead of getZoom when effects are active.
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(1.5)
  cam:zoomPulse(0.1, 0.3)
  local ez = cam:getEffectiveZoom()
  lurek.log.debug("effective zoom=" .. ez, "render")
end

--@api-stub: LCamera:getEffectOffset
-- Returns the effect offset of this camera2d.
do
  -- Returns the combined X, Y pixel offset from sway + shake effects.
  -- Useful if you need to counter-offset UI elements or debug the effect state.
  local cam = lurek.camera.new(800, 600)
  cam:startSway(6, 3, 0.6)
  local ox, oy = cam:getEffectOffset()
  lurek.log.debug("sway offset " .. ox .. "," .. oy, "camera")
end

--@api-stub: LCameraRig:apply
-- Applies  to this camera2d.
do
  -- apply() pushes a render command that transforms all subsequent drawing
  -- by this camera's position, zoom, and rotation. Call reset() when done.
  local cam = lurek.camera.new()
  cam:setPosition(400, 300)
  cam:setZoom(1.5)
  cam:apply()
  -- ... draw world-space sprites here ...
  lurek.log.info("camera applied", "camera")
end

--@api-stub: LCamera:attach
-- Performs the attach operation on this camera2d.
do
  -- attach/detach is an alternative to apply/reset — same effect, different naming.
  -- Use whichever reads better for your game loop style.
  local cam = lurek.camera.new()
  cam:setPosition(200, 150)
  cam:attach()
  -- ... render game world between attach/detach ...
  lurek.log.info("camera attached", "camera")
end

--@api-stub: LCamera:detach
-- Performs the detach operation on this camera2d.
do
  -- detach restores the render transform so HUD drawing is screen-relative again.
  local cam = lurek.camera.new()
  cam:attach()
  cam:detach()
  lurek.log.info("camera detached", "camera")
end

--@api-stub: LCamera:followPath
-- Performs the follow path operation on this camera2d.
do
  -- followPath takes an array of {x, y} waypoint tables and a total duration.
  -- The camera interpolates linearly between each waypoint over the given time.
  -- Great for intro cutscenes or scripted camera pans.
  local cam = lurek.camera.new()
  local path = {{x=0,y=0},{x=200,y=100},{x=400,y=0}}
  cam:followPath(path, 120) -- traverse 3 waypoints over 120 seconds
  lurek.log.info("following path", "camera")
end

--@api-stub: LCamera:reset
-- Resets this camera2d to its default state.
do
  -- reset() removes the camera transform from the render pipeline.
  -- Draw HUD elements after reset() so they appear at screen coordinates.
  local cam = lurek.camera.new()
  cam:setZoom(2.5)
  cam:reset()
  lurek.log.info("zoom after reset: " .. cam:getZoom(), "camera")
end

--@api-stub: LCamera:setBounds
-- Sets the bounds of this camera2d.
do
  -- Bounds constrain the camera so it never shows area outside the world.
  -- Set to your tilemap dimensions to prevent seeing void at the edges.
  -- The camera auto-clamps its position to stay within these bounds.
  local cam = lurek.camera.new()
  cam:setBounds(0, 0, 3200, 2400) -- world is 3200x2400
  cam:setPosition(400, 300)
  lurek.log.info("bounds set", "camera")
end

--@api-stub: LCamera:setParallaxFactor
-- Sets the parallax factor of this camera2d.
do
  -- Assign different speeds to background layers for depth illusion.
  -- Mountains scroll at 30% camera speed, clouds at 15%.
  local cam = lurek.camera.new()
  cam:setParallaxFactor("bg_mountains", 0.3)
  cam:setParallaxFactor("bg_clouds", 0.15)
  lurek.log.info("parallax factors set", "camera")
end

--@api-stub: LCamera:setViewport
-- Sets the viewport of this camera2d.
do
  -- Viewport defines the screen rectangle this camera renders into.
  -- Use for split-screen: each player camera gets a portion of the window.
  local cam = lurek.camera.new()
  cam:setViewport(0, 0, 640, 480) -- render to left half
  lurek.log.info("viewport set", "camera")
end

--@api-stub: LCamera:startBreathing
-- Performs the start breathing operation on this camera2d.
do
  -- Breathing is a subtle oscillating zoom that adds life to idle cameras.
  -- amplitude = max zoom offset (0.005 = 0.5%); rate = oscillation frequency.
  local cam = lurek.camera.new()
  cam:startBreathing(2.0, 4.0)
  lurek.log.info("breathing: " .. tostring(cam:isBreathing()), "camera")
end

--@api-stub: LCamera:startSway
-- Performs the start sway operation on this camera2d.
do
  -- Sway moves the camera in a figure-eight pattern.
  -- Use for boat rocking, wind effects, or underwater drifting.
  -- Params: amplitude_x, amplitude_y, frequency, decay (optional).
  local cam = lurek.camera.new()
  cam:startSway(5.0, 0.8, 0.95)
  lurek.log.info("sway active: " .. tostring(cam:isSway()), "camera")
end

-- -----------------------------------------------------------------------------
-- Camera2D methods (type introspection)
-- -----------------------------------------------------------------------------

--@api-stub: LCameraRig:type
-- Returns the Lua-visible type name string for this camera2d handle.
do
  local cam = lurek.camera.new(800, 600)
  local t = cam:type()
  lurek.log.info("Camera2D:type=" .. t, "camera")
end

--@api-stub: LCameraRig:typeOf
-- Returns true if this camera2d handle matches the given type name string.
do
  -- typeOf checks inheritance: "LCamera" and "Object" both return true.
  local cam = lurek.camera.new(800, 600)
  lurek.log.info("is Camera2D: " .. tostring(cam:typeOf("Camera2D")), "camera")
  lurek.log.info("is wrong: " .. tostring(cam:typeOf("Unknown")), "camera")
end

-- =============================================================================
-- LCamera methods (full featured camera API)
-- =============================================================================

--@api-stub: LCameraRig:setPosition
-- Sets the camera world position
do
  -- Position sets the camera's top-left corner in world space.
  -- For centering on a player, subtract half-viewport from player coords.
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(256, 128)
  local x, y = cam:getPosition()
  lurek.log.info("position=" .. x .. "," .. y, "camera")
end

--@api-stub: LCamera:getPosition
-- Returns the camera world position
do
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(100, 200)
  local x, y = cam:getPosition()
  lurek.log.info("x=" .. x .. " y=" .. y, "camera")
end

--@api-stub: LCameraRig:setZoom
-- Sets the camera zoom factor
do
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(2.0) -- 2x magnification: each world pixel is 2 screen pixels
  lurek.log.info("zoom=" .. cam:getZoom(), "camera")
end

--@api-stub: LCamera:getZoom
-- Returns the camera zoom factor
do
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(0.5) -- 0.5x = zoomed out, shows 1600x1200 of world in 800x600 viewport
  lurek.log.info("zoom=" .. cam:getZoom(), "camera")
end

--@api-stub: LCamera:setRotation
-- Sets the camera rotation
do
  local cam = lurek.camera.new(800, 600)
  cam:setRotation(math.pi / 8) -- tilt 22.5 degrees
  lurek.log.info("rotation=" .. cam:getRotation(), "camera")
end

--@api-stub: LCamera:getRotation
-- Returns the camera rotation
do
  local cam = lurek.camera.new(800, 600)
  cam:setRotation(math.pi / 4) -- 45 degree tilt
  lurek.log.info("rotation=" .. cam:getRotation(), "camera")
end

--@api-stub: LCamera:setViewport
-- Sets the camera viewport rectangle
do
  -- Viewport = screen rectangle to render into.
  -- Split-screen example: left player uses left half of window.
  local cam = lurek.camera.new(800, 600)
  cam:setViewport(0, 0, 640, 480) -- render to a 640x480 portion at top-left
  local x, y, w, h = cam:getViewport()
  lurek.log.info("viewport=" .. w .. "x" .. h, "camera")
end

--@api-stub: LCameraRig:getViewport
-- Returns the camera viewport rectangle
do
  local cam = lurek.camera.new(800, 600)
  cam:setViewport(0, 0, 800, 600)
  local x, y, w, h = cam:getViewport()
  lurek.log.info("viewport " .. w .. "x" .. h, "camera")
end

--@api-stub: LCamera:setBounds
-- Sets camera world bounds
do
  -- Bounds prevent the camera from scrolling past the world edges.
  -- For a 2048x1024 tilemap: camera will never show pixels outside that rect.
  local cam = lurek.camera.new(800, 600)
  cam:setBounds(0, 0, 2048, 1024)
  lurek.log.info("bounds set", "camera")
end

--@api-stub: LCamera:removeBounds
-- Removes active camera bounds
do
  -- Free the camera for unbounded panning (debug mode, editor, cutscenes).
  local cam = lurek.camera.new(800, 600)
  cam:setBounds(0, 0, 1024, 768)
  cam:removeBounds()
  lurek.log.info("bounds removed", "camera")
end

--@api-stub: LCameraRig:setTarget
-- Sets a world-space follow target
do
  -- Setting a target activates the follow system: the camera smoothly
  -- moves toward that world point every frame (when update() is called).
  -- Combine with setFollowSmooth, setDeadZone, and setLookAhead for tuning.
  local cam = lurek.camera.new(800, 600)
  cam:setFollowSmooth(5.0)
  cam:setTarget(320, 240) -- follow this point
  cam:update(0.016) -- advance one frame to see movement
  local x, y = cam:getPosition()
  lurek.log.info("after follow: x=" .. x .. " y=" .. y, "camera")
end

--@api-stub: LCamera:clearTarget
-- Clears the follow target
do
  -- Stop following — camera stays at its current position.
  local cam = lurek.camera.new(800, 600)
  cam:setTarget(400, 300)
  cam:clearTarget()
  lurek.log.info("follow target cleared", "camera")
end

--@api-stub: LCamera:setFollowSmooth
-- Sets follow smoothing speed
do
  -- Smoothing speed controls how fast the camera converges on the target.
  -- Higher = snappier (action games use 8-12). Lower = cinematic (2-4).
  local cam = lurek.camera.new(800, 600)
  cam:setFollowSmooth(4.0)
  cam:setTarget(200, 100)
  cam:update(0.1)
  local x, y = cam:getPosition()
  lurek.log.info("smoothed pos=" .. x .. "," .. y, "camera")
end

--@api-stub: LCamera:setDeadZone
-- Sets follow dead-zone dimensions
do
  -- Dead zone: the target can move this many pixels from center without
  -- triggering camera movement. Prevents jitter from small player movements.
  -- Platformer tip: use wide horizontal dead zone, narrow vertical.
  local cam = lurek.camera.new(800, 600)
  cam:setFollowSmooth(10.0)
  cam:setDeadZone(64, 32) -- 64px horizontal, 32px vertical
  cam:setTarget(100, 100)
  cam:update(0.1)
  lurek.log.info("dead zone configured", "camera")
end

--@api-stub: LCamera:setLookAhead
-- Sets follow look-ahead multiplier
do
  -- Look-ahead offsets the camera in the direction the target is moving.
  -- Players see more of what's coming. Value is a multiplier on velocity.
  local cam = lurek.camera.new(800, 600)
  cam:setFollowSmooth(5.0)
  cam:setLookAhead(2.0) -- 2x velocity look-ahead
  cam:setTarget(400, 300)
  cam:update(0.016)
  lurek.log.info("look-ahead set", "camera")
end

--@api-stub: LCamera:shake
-- Starts a camera shake effect
do
  -- Shake adds random high-frequency offset that decays over the given duration.
  -- Use for: explosions, player damage, heavy landings, boss attacks.
  local cam = lurek.camera.new(800, 600)
  cam:shake(0.5, 8.0) -- duration=0.5s, intensity=8 pixels
  lurek.log.info("shake started", "camera")
end

--@api-stub: LCamera:update
-- Advances camera follow, shake, and effect state
do
  -- update(dt) must be called every frame. It advances:
  -- follow interpolation, shake decay, sway animation, and breathing.
  local cam = lurek.camera.new(800, 600)
  cam:shake(1.0, 4.0)
  cam:update(0.016) -- advance one frame at 60 fps
  lurek.log.info("camera updated", "camera")
end

--@api-stub: LCamera:toWorld
-- Converts screen coordinates to world coordinates
do
  -- Screen-to-world conversion respects position, zoom, and rotation.
  -- Essential for mouse picking: convert click coords to world position.
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(100, 100)
  cam:setZoom(2.0)
  local wx, wy = cam:toWorld(400, 300) -- screen center -> world coords
  lurek.log.info("world(" .. wx .. "," .. wy .. ")", "camera")
end

--@api-stub: LCamera:toScreen
-- Converts world coordinates to screen coordinates
do
  -- World-to-screen: check if an object is visible, or position a health bar.
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(0, 0)
  cam:setZoom(1.0)
  local sx, sy = cam:toScreen(100, 50)
  lurek.log.info("screen(" .. sx .. "," .. sy .. ")", "camera")
end

--@api-stub: LCamera:getVisibleArea
-- Returns the world-space area visible through this camera
do
  -- Returns x, y, w, h of the world rectangle currently on screen.
  -- Use for efficient culling: don't draw objects outside this rect.
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(0, 0)
  cam:setZoom(1.0)
  local x, y, w, h = cam:getVisibleArea()
  lurek.log.info("visible=" .. w .. "x" .. h .. " at " .. x .. "," .. y, "camera")
end

--@api-stub: LCamera:lookAt
-- Centers the camera on a world position
do
  -- lookAt sets position so the given world point is at viewport center.
  -- Simpler than manual setPosition math for centering on objects.
  local cam = lurek.camera.new(800, 600)
  cam:lookAt(512, 256) -- world point (512, 256) is now at screen center
  local x, y = cam:getPosition()
  lurek.log.info("camera now at " .. x .. "," .. y, "camera")
end

--@api-stub: LCamera:move
-- Moves the camera by a delta
do
  -- Additive movement — good for keyboard-driven camera pan in editors.
  local cam = lurek.camera.new(800, 600)
  cam:lookAt(0, 0)
  cam:move(50, 25) -- shift 50 right, 25 down
  local x, y = cam:getPosition()
  lurek.log.info("after move: " .. x .. "," .. y, "camera")
end

--@api-stub: LCamera:followPath
-- Starts camera movement along an array of waypoint tables
do
  -- Path follow: array of {x, y} waypoints + total duration in seconds.
  -- Camera interpolates linearly through them. Use for intro flybys, reveals.
  -- Waypoints use numeric indices: {100, 200} means x=100, y=200.
  local cam = lurek.camera.new(800, 600)
  local waypoints = {{0, 0}, {200, 100}, {400, 200}}
  cam:followPath(waypoints, 3.0) -- traverse over 3 seconds
  lurek.log.info("path started, progress=" .. cam:pathProgress(), "camera")
end

--@api-stub: LCamera:updatePath
-- Advances the active camera path and applies its position
do
  -- Returns true while path is active, false when finished or no path set.
  local cam = lurek.camera.new(800, 600)
  cam:followPath({{0, 0}, {200, 0}}, 2.0)
  cam:updatePath(0.5) -- advance 0.5 seconds
  lurek.log.info("path progress=" .. cam:pathProgress(), "camera")
end

--@api-stub: LCamera:pathProgress
-- Returns active path progress
do
  -- Returns normalized 0..1 value. Use for progress bars or timed events.
  local cam = lurek.camera.new(800, 600)
  cam:followPath({{0, 0}, {400, 0}}, 4.0)
  cam:updatePath(1.0) -- 25% done
  lurek.log.info("path progress=" .. cam:pathProgress(), "camera")
end

--@api-stub: LCamera:zoomTo
-- Starts a zoom tween toward a target zoom factor
do
  -- Smooth animated zoom over time. Optional third param selects easing:
  -- "linear", "smoothstep", or "easeout" (default).
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(1.0)
  cam:zoomTo(2.5, 0.8) -- zoom to 2.5x over 0.8 seconds
  cam:updateZoom(0.4) -- advance halfway
  lurek.log.info("zoom=" .. cam:getZoom(), "camera")
end

--@api-stub: LCamera:stopZoom
-- Stops the active zoom tween
do
  -- Freezes zoom at whatever level it reached. Use when player interrupts.
  local cam = lurek.camera.new(800, 600)
  cam:zoomTo(3.0, 2.0)
  cam:stopZoom()
  lurek.log.info("zoom tween stopped", "camera")
end

--@api-stub: LCamera:updateZoom
-- Advances the active zoom tween and applies its zoom value
do
  -- Returns true while active, false when done. Call each frame.
  local cam = lurek.camera.new(800, 600)
  cam:zoomTo(2.0, 1.0)
  cam:updateZoom(0.5) -- advance halfway through the tween
  lurek.log.info("zoom mid-tween=" .. cam:getZoom(), "camera")
end

--@api-stub: LCamera:setParallaxFactor
-- Sets a parallax factor for a named layer
do
  -- Each named layer can have a different scroll speed relative to the camera.
  -- factor=0.0: layer is static (far background).
  -- factor=1.0: layer scrolls with camera (default, same as foreground).
  -- factor>1.0: layer scrolls faster (foreground parallax, rare).
  local cam = lurek.camera.new(800, 600)
  cam:setParallaxFactor("bg_clouds", 0.3) -- clouds scroll at 30%
  cam:setParallaxFactor("bg_hills", 0.6)  -- hills scroll at 60%
  lurek.log.info("parallax bg_clouds=" .. cam:getParallaxFactor("bg_clouds"), "camera")
end

--@api-stub: LCamera:getParallaxFactor
-- Returns a parallax factor for a named layer
do
  -- Returns 1.0 for layers that have no override set.
  local cam = lurek.camera.new(800, 600)
  cam:setParallaxFactor("sky", 0.1)
  lurek.log.info("sky factor=" .. cam:getParallaxFactor("sky"), "camera")
  lurek.log.info("unset factor=" .. cam:getParallaxFactor("foreground"), "camera") -- returns 1.0
end

--@api-stub: LCamera:clearParallaxFactors
-- Clears all layer parallax factor overrides
do
  -- After clearing, all layers default back to factor 1.0 (full scroll).
  local cam = lurek.camera.new(800, 600)
  cam:setParallaxFactor("clouds", 0.4)
  cam:clearParallaxFactors()
  lurek.log.info("parallax factor after clear=" .. cam:getParallaxFactor("clouds"), "camera")
end

--@api-stub: LCameraRig:apply
-- Appends render commands that apply this camera transform
do
  -- apply/reset pattern: everything drawn between apply() and reset()
  -- is transformed by camera position, zoom, and rotation.
  -- Draw HUD elements AFTER reset() so they stay screen-fixed.
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(100, 50)
  cam:setZoom(1.5)
  cam:apply()
  -- ... draw world-space sprites, tilemaps, particles here ...
  cam:reset()
  -- ... draw HUD, menus, debug text here (screen-space) ...
  lurek.log.info("camera applied and reset", "camera")
end

--@api-stub: LCamera:reset
-- Appends a render command that removes the active camera transform
do
  -- After reset(), coordinates are screen-space again.
  local cam = lurek.camera.new(800, 600)
  cam:apply()
  -- ... draw game world ...
  cam:reset()
  lurek.log.info("render transform restored", "camera")
end

--@api-stub: LCamera:attach
-- Appends render commands that attach this camera transform
do
  -- attach/detach is an alternative naming to apply/reset.
  -- Identical behavior — use whichever naming convention you prefer.
  local cam = lurek.camera.new(800, 600)
  cam:setPosition(0, 0)
  cam:attach()
  -- ... render world geometry ...
  cam:detach()
  lurek.log.info("attach/detach cycle complete", "camera")
end

--@api-stub: LCamera:detach
-- Appends a render command that detaches the active camera transform
do
  -- Always pair with attach(). Failing to detach means HUD draws wrong.
  local cam = lurek.camera.new(800, 600)
  cam:attach()
  cam:detach()
  lurek.log.info("detached, transforms restored", "camera")
end

--@api-stub: LCamera:zoomPulse
-- Triggers a temporary zoom pulse effect
do
  -- Zoom pulse adds a quick burst to the effective zoom that decays.
  -- Perfect for: collecting a powerup, critical hit, bass drop in music.
  local cam = lurek.camera.new(800, 600)
  cam:zoomPulse(0.3, 0.5) -- +30% zoom burst decaying over 0.5s
  cam:update(0.016)
  lurek.log.info("pulse zoom=" .. cam:getEffectiveZoom(), "camera")
end

--@api-stub: LCamera:startSway
-- Starts camera sway offset animation
do
  -- Sway oscillates the camera position for ambient motion.
  -- Use for: boat rocking, earthquake tremor, wind in treetops, underwater drift.
  -- amplitude_x, amplitude_y = max offset; frequency = speed; decay = optional damping.
  local cam = lurek.camera.new(800, 600)
  cam:startSway(4.0, 1.5, 0.3, 2.0) -- gentle horizontal sway
  cam:update(0.016)
  lurek.log.info("sway active=" .. tostring(cam:isSway()), "camera")
end

--@api-stub: LCamera:stopSway
-- Stops camera sway offset animation
do
  local cam = lurek.camera.new(800, 600)
  cam:startSway(3.0, 1.0, 0.5, 1.0)
  cam:stopSway()
  lurek.log.info("sway=" .. tostring(cam:isSway()), "camera")
end

--@api-stub: LCamera:isSway
-- Returns whether camera sway is active
do
  local cam = lurek.camera.new(800, 600)
  lurek.log.info("before sway: " .. tostring(cam:isSway()), "camera")
  cam:startSway(2.0, 1.0, 0.5, 0.5)
  lurek.log.info("after start: " .. tostring(cam:isSway()), "camera")
end

--@api-stub: LCamera:startBreathing
-- Starts subtle breathing zoom animation
do
  -- Breathing adds a slow sine-wave zoom oscillation.
  -- Amplitude 0.02 = 2% zoom variation. Rate = oscillation speed.
  -- Gives idle scenes a subtle "alive" feeling.
  local cam = lurek.camera.new(800, 600)
  cam:startBreathing(0.02, 0.4) -- 2% amplitude, 0.4 Hz
  cam:update(0.016)
  lurek.log.info("breathing=" .. tostring(cam:isBreathing()), "camera")
end

--@api-stub: LCamera:stopBreathing
-- Stops breathing zoom animation
do
  local cam = lurek.camera.new(800, 600)
  cam:startBreathing(0.02, 0.3)
  cam:stopBreathing()
  lurek.log.info("breathing=" .. tostring(cam:isBreathing()), "camera")
end

--@api-stub: LCamera:isBreathing
-- Returns whether breathing zoom animation is active
do
  local cam = lurek.camera.new(800, 600)
  cam:startBreathing(0.01, 0.5)
  lurek.log.info("breathing=" .. tostring(cam:isBreathing()), "camera")
  cam:stopBreathing()
  lurek.log.info("after stop=" .. tostring(cam:isBreathing()), "camera")
end

--@api-stub: LCamera:getEffectiveZoom
-- Returns zoom after camera effects are applied
do
  -- This is the ACTUAL zoom used for rendering, combining base zoom + pulse + breathing.
  -- Use this instead of getZoom() when you need pixel-accurate calculations.
  local cam = lurek.camera.new(800, 600)
  cam:setZoom(1.0)
  cam:zoomPulse(0.2, 1.0)
  cam:update(0.016)
  lurek.log.info("effective_zoom=" .. cam:getEffectiveZoom(), "camera")
end

--@api-stub: LCamera:getEffectOffset
-- Returns combined camera effect offset
do
  -- Returns the total pixel offset from sway + shake combined.
  -- Useful for manual offset of UI elements that need to counter-shake.
  local cam = lurek.camera.new(800, 600)
  cam:startSway(5.0, 2.0, 0.5, 1.0)
  cam:update(0.25)
  local ox, oy = cam:getEffectOffset()
  lurek.log.info("sway_offset=" .. ox .. "," .. oy, "camera")
end

--@api-stub: LCamera:setFollowEasing
-- Sets target follow easing mode
do
  -- Controls the interpolation curve used during follow movement.
  -- "linear" = constant speed. "smoothstep" = ease-in-out. "easeout" = fast start, slow stop.
  local cam = lurek.camera.new(800, 600)
  cam:setFollowEasing("smoothstep")
  lurek.log.info("follow easing set", "camera")
end

--@api-stub: LCamera:getFollowEasing
-- Returns target follow easing mode
do
  local cam = lurek.camera.new(800, 600)
  cam:setFollowEasing("easeout")
  lurek.log.info("follow easing=" .. cam:getFollowEasing(), "camera")
end

--@api-stub: LCamera:onWindowResize
-- Updates camera viewport state after a window resize
do
  -- Call this from your lurek.resize callback to keep the camera viewport
  -- synchronized with the window dimensions.
  local cam = lurek.camera.new(800, 600)
  cam:onWindowResize(1920, 1080)
  local x, y, w, h = cam:getViewport()
  lurek.log.info("resized viewport=" .. x .. "," .. y .. " " .. w .. "x" .. h, "camera")
end

--@api-stub: LCamera:onWindowResizeScaled
-- Updates camera viewport state using a virtual game size and scale mode
do
  -- For pixel-art or fixed-resolution games: define a virtual game size
  -- and a scale mode to handle different window/monitor aspect ratios.
  -- Modes: "letterbox" (black bars), "stretch" (distort), "pixelperfect" (integer scale).
  local cam = lurek.camera.new(800, 600)
  cam:onWindowResizeScaled(800, 600, 1200, 600, "letterbox")
  local x, y, w, h = cam:getViewport()
  lurek.log.info("scaled viewport=" .. x .. "," .. y .. " " .. w .. "x" .. h, "camera")
end

-- =============================================================================
-- LCameraRig methods (multi-camera management)
-- =============================================================================

--@api-stub: LCameraRig:splitScreen
-- Applies a split-screen layout using the current window size
do
  -- splitScreen creates "left" and "right" cameras, each covering half the window.
  -- For a 2-player co-op: each player gets their own camera following them.
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  local ok, x, y, w, h = rig:getViewport("left")
  if ok then
    lurek.log.info("left viewport=" .. x .. "," .. y .. " " .. w .. "x" .. h, "camera")
  end
end

--@api-stub: LCameraRig:minimap
-- Applies a minimap layout using the current window size and optional ratio
do
  -- minimap creates "main" and "minimap" cameras.
  -- The minimap gets a small inset viewport (default 25% of window height).
  local rig = lurek.camera.newRig()
  rig:minimap(1280, 720, 0.25)
  local ok, x, y, w, h = rig:getViewport("minimap")
  if ok then
    lurek.log.info("minimap viewport=" .. x .. "," .. y .. " " .. w .. "x" .. h, "camera")
  end
end

--@api-stub: LCameraRig:pictureInPicture
-- Applies a picture-in-picture layout using optional inset size
do
  -- Creates "main" and "pip" cameras. PiP defaults to 320x180 in bottom-right.
  -- Use for: rear-view mirror, security camera feed, dialogue close-up.
  local rig = lurek.camera.newRig()
  rig:pictureInPicture(1280, 720, 320, 180)
  local ok, x, y, w, h = rig:getViewport("pip")
  if ok then
    lurek.log.info("pip viewport=" .. x .. "," .. y .. " " .. w .. "x" .. h, "camera")
  end
end

--@api-stub: LCamera:getBounds
-- Returns camera bounds with a leading availability flag
do
  -- First return is a boolean indicating whether bounds are set.
  -- If true, the next four values are x, y, width, height.
  local cam = lurek.camera.new(800, 600)
  cam:setBounds(0, 0, 100, 50)
  local ok, x, y, w, h = cam:getBounds()
  lurek.log.info("getBounds ok=" .. tostring(ok) .. " w=" .. w .. " h=" .. h, "camera")
end

--@api-stub: LCamera:getDeadZone
-- Returns follow dead-zone dimensions with a leading availability flag
do
  -- First return is boolean (has dead zone), then width and height.
  local cam = lurek.camera.new(800, 600)
  cam:setDeadZone(40, 20)
  local ok, w, h = cam:getDeadZone()
  lurek.log.info("getDeadZone ok=" .. tostring(ok) .. " " .. w .. "x" .. h, "camera")
end

--@api-stub: LCamera:getFollowSmooth
-- Returns follow smoothing speed
do
  local cam = lurek.camera.new(800, 600)
  cam:setFollowSmooth(3.0)
  lurek.log.info("follow smooth=" .. cam:getFollowSmooth(), "camera")
end

--@api-stub: LCamera:getLookAhead
-- Returns follow look-ahead multiplier
do
  local cam = lurek.camera.new(800, 600)
  cam:setLookAhead(0.4)
  lurek.log.info("lookAhead=" .. cam:getLookAhead(), "camera")
end

--@api-stub: LCamera:getRenderOffset
-- Returns current render offset after camera effects
do
  -- This is the total pixel offset applied to rendering from all active effects.
  local cam = lurek.camera.new(800, 600)
  local x, y = cam:getRenderOffset()
  lurek.log.info("render offset=" .. x .. "," .. y, "camera")
end

--@api-stub: LCamera:getRotationConstraints
-- Returns rotation constraints with availability flags
do
  -- Returns: has_min, min_value, has_max, max_value
  local cam = lurek.camera.new(800, 600)
  cam:setRotationConstraints(-1.0, 1.0)
  local has_min, min_v, has_max, max_v = cam:getRotationConstraints()
  lurek.log.info("rot constraints=" .. tostring(has_min) .. "," .. min_v .. "," .. tostring(has_max) .. "," .. max_v, "camera")
end

--@api-stub: LCamera:getRotationDamping
-- Returns rotation damping
do
  local cam = lurek.camera.new(800, 600)
  cam:setRotationDamping(0.5)
  lurek.log.info("rotation damping=" .. cam:getRotationDamping(), "camera")
end

--@api-stub: LCamera:getShakeOffset
-- Returns current camera shake offset
do
  -- During an active shake, this returns the random offset applied this frame.
  -- Use to manually offset certain UI elements that should shake with the camera.
  local cam = lurek.camera.new(800, 600)
  cam:shake(3.0, 0.4)
  cam:update(0.1)
  local x, y = cam:getShakeOffset()
  lurek.log.info("shake offset=" .. x .. "," .. y, "camera")
end

--@api-stub: LCamera:getTarget
-- Returns the follow target with a leading availability flag
do
  -- First return is boolean (has target), then x, y of the target position.
  local cam = lurek.camera.new(800, 600)
  cam:setTarget(12, 34)
  local ok, x, y = cam:getTarget()
  lurek.log.info("target=" .. tostring(ok) .. " " .. x .. "," .. y, "camera")
end

--@api-stub: LCamera:getZoomConstraints
-- Returns zoom constraints with availability flags
do
  -- Returns: has_min, min_value, has_max, max_value
  -- Use constraints to prevent players from zooming too far in/out.
  local cam = lurek.camera.new(800, 600)
  cam:setZoomConstraints(0.5, 2.5) -- clamp between 0.5x and 2.5x
  local has_min, min_v, has_max, max_v = cam:getZoomConstraints()
  lurek.log.info("zoom constraints=" .. tostring(has_min) .. "," .. min_v .. "," .. tostring(has_max) .. "," .. max_v, "camera")
end

--@api-stub: LCamera:getZoomDamping
-- Returns zoom damping
do
  local cam = lurek.camera.new(800, 600)
  cam:setZoomDamping(0.25)
  lurek.log.info("zoom damping=" .. cam:getZoomDamping(), "camera")
end

--@api-stub: LCamera:hasBounds
-- Returns whether camera bounds are active
do
  local cam = lurek.camera.new(800, 600)
  lurek.log.info("hasBounds(before)=" .. tostring(cam:hasBounds()), "camera")
  cam:setBounds(0, 0, 100, 100)
  lurek.log.info("hasBounds(after)=" .. tostring(cam:hasBounds()), "camera")
end

--@api-stub: LCamera:presetAggressiveFollow
-- Applies the aggressive follow camera preset
do
  -- Presets configure follow smooth, dead zone, look-ahead, and easing
  -- in one call. "Aggressive" = fast, nearly 1:1 follow with minimal lag.
  -- Good for fast-paced action, bullet hell, or racing games.
  local cam = lurek.camera.new(800, 600)
  cam:presetAggressiveFollow()
  lurek.log.info("preset aggressive", "camera")
end

--@api-stub: LCamera:presetBalancedFollow
-- Applies the balanced follow camera preset
do
  -- Balanced is a good default for most games: responsive but smooth.
  local cam = lurek.camera.new(800, 600)
  cam:presetBalancedFollow()
  lurek.log.info("preset balanced", "camera")
end

--@api-stub: LCamera:presetCinematicFollow
-- Applies the cinematic follow camera preset
do
  -- Cinematic = slow, floaty follow with large dead zone and strong look-ahead.
  -- Use for exploration, walking simulators, or story-heavy moments.
  local cam = lurek.camera.new(800, 600)
  cam:presetCinematicFollow()
  lurek.log.info("preset cinematic", "camera")
end

--@api-stub: LCamera:presetTightFollow
-- Applies the tight follow camera preset
do
  -- Tight = very fast convergence, small dead zone.
  -- The camera stays glued to the player with minimal overshoot.
  local cam = lurek.camera.new(800, 600)
  cam:presetTightFollow()
  lurek.log.info("preset tight", "camera")
end

--@api-stub: LCamera:setRotationConstraints
-- Sets optional minimum and maximum rotation constraints
do
  -- Clamp rotation to a range. Pass nil for either to leave that side unconstrained.
  -- Example: limit tilt to +/- 12 degrees for a vehicle camera.
  local cam = lurek.camera.new(800, 600)
  cam:setRotationConstraints(-0.2, 0.2) -- approx +/- 11.5 degrees
end

--@api-stub: LCamera:setRotationDamping
-- Sets rotation damping
do
  -- Damping slows down rotation changes, creating smoother transitions.
  -- Higher = more sluggish rotation response.
  local cam = lurek.camera.new(800, 600)
  cam:setRotationDamping(0.3)
end

--@api-stub: LCamera:setZoomConstraints
-- Sets optional minimum and maximum zoom constraints
do
  -- Prevent the player from zooming beyond useful ranges.
  -- min=0.6 keeps things readable; max=2.2 prevents excessive close-up.
  local cam = lurek.camera.new(800, 600)
  cam:setZoomConstraints(0.6, 2.2)
end

--@api-stub: LCamera:setZoomDamping
-- Sets zoom damping
do
  -- Damping smooths out zoom changes (e.g., from mouse wheel input).
  local cam = lurek.camera.new(800, 600)
  cam:setZoomDamping(0.2)
end

--@api-stub: LCameraRig:apply
-- Appends render commands for a named camera in this rig
do
  -- rig:apply("name") sets up the viewport and transform for that camera.
  -- Returns true if the camera exists, false otherwise.
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  lurek.log.info("rig apply left=" .. tostring(rig:apply("left")), "camera")
end

--@api-stub: LCameraRig:getViewport
-- Returns a named rig camera viewport with a leading availability flag
do
  -- Returns: has_camera, x, y, width, height
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  local ok, x, y, w, h = rig:getViewport("right")
  lurek.log.info("rig viewport ok=" .. tostring(ok) .. " " .. w .. "x" .. h, "camera")
end

--@api-stub: LCameraRig:has
-- Returns whether this rig contains a named camera
do
  local rig = lurek.camera.newRig()
  rig:minimap(1280, 720, 0.25)
  lurek.log.info("has minimap=" .. tostring(rig:has("minimap")), "camera")
end

--@api-stub: LCameraRig:names
-- Returns all camera names in this rig
do
  -- Returns a Lua table array of all camera name strings in this rig.
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  local names = rig:names()
  lurek.log.info("rig names count=" .. tostring(#names), "camera")
end

--@api-stub: LCameraRig:remove
-- Removes a named camera from this rig
do
  -- Returns true if the camera existed and was removed.
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  lurek.log.info("removed left=" .. tostring(rig:remove("left")), "camera")
end

--@api-stub: LCameraRig:setPosition
-- Sets the position of a named rig camera, creating it if needed
do
  -- If the named camera doesn't exist yet, it's auto-created.
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  rig:setPosition("left", 50, 75)
end

--@api-stub: LCameraRig:setTarget
-- Sets the follow target of a named rig camera, creating it if needed
do
  -- Useful for split-screen: each player's camera follows their character.
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  rig:setTarget("left", 100, 150)  -- player 1's position
  rig:setTarget("right", 900, 400) -- player 2's position
end

--@api-stub: LCameraRig:setZoom
-- Sets the zoom of a named rig camera, creating it if needed
do
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  rig:setZoom("left", 1.2) -- player 1 slightly zoomed in
end

--@api-stub: LCameraRig:type
-- Returns the Lua-visible type name for this camera rig handle
do
  local rig = lurek.camera.newRig()
  lurek.log.info("rig type=" .. rig:type(), "camera") -- "LCameraRig"
end

--@api-stub: LCameraRig:typeOf
-- Returns whether this camera rig handle matches a supported type name
do
  -- Matches "LCameraRig" and "Object".
  local rig = lurek.camera.newRig()
  lurek.log.info("rig typeOf LCameraRig=" .. tostring(rig:typeOf("LCameraRig")), "camera")
end

--@api-stub: LCameraRig:updateAll
-- Advances every camera in this rig
do
  -- Call once per frame to update follow, shake, and effects for ALL rig cameras.
  local rig = lurek.camera.newRig()
  rig:splitScreen(1280, 720)
  rig:setTarget("left", 100, 200)
  rig:setTarget("right", 800, 400)
  rig:updateAll(0.016) -- advance all cameras by one frame
end

--@api-stub: LCamera:stopPath
-- Stops any active camera path follow and leaves the camera at its current position.
do
  -- Use when the player presses a button to skip a cutscene path.
  local cam = lurek.camera.new(800, 600)
  cam:followPath({{0, 0}, {500, 500}}, 5.0)
  cam:updatePath(1.0) -- advance 1 second
  cam:stopPath() -- freeze here, don't complete the path
end

print("content/examples/camera.lua")

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

--@api-stub: LCamera:type
-- Returns the Lua-visible type name for this camera handle.
do
  -- Use type() to identify a handle for serialization or debug output.
  local cam = lurek.camera.new(800, 600)
  local name = cam:type()
  lurek.log.info("camera type name: " .. name, "camera")
end

--@api-stub: LCamera:typeOf
-- Returns whether this camera handle matches a supported type name.
do
  -- typeOf checks if the handle matches a type string (useful for polymorphic APIs).
  local cam = lurek.camera.new(800, 600)
  local is_cam = cam:typeOf("LCamera")
  local is_img = cam:typeOf("LImage")
  lurek.log.info("is LCamera=" .. tostring(is_cam) .. " is LImage=" .. tostring(is_img), "camera")
end
