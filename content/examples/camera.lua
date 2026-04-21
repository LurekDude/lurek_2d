-- content/examples/camera.lua
-- Lurek2D lurek.camera API Reference
-- Run with: cargo run -- content/examples/camera
--
-- Scenario: A side-scrolling platformer with a smooth-following camera that
-- tracks the player, supports screen shake on hit, zoom transitions, parallax,
-- cinematic paths, and viewport bounds to prevent showing out-of-world areas.

print("=== lurek.camera — 2D Camera System ===\n")

-- =============================================================================
-- Camera Creation
-- =============================================================================

--@api-stub: lurek.camera.new
local cam = lurek.camera.new()
print("camera created")

-- =============================================================================
-- Position & Basic Movement
-- =============================================================================

--@api-stub: Camera2D:setPosition
cam:setPosition(400, 300)

--@api-stub: Camera2D:getPosition
local cx, cy = cam:getPosition()
print("camera at: " .. cx .. "," .. cy)

--@api-stub: Camera2D:lookAt
-- Instantly center the camera on a point.
cam:lookAt(500, 250)

--@api-stub: Camera2D:move
-- Pan the camera by a relative offset.
cam:move(10, 0)

-- =============================================================================
-- Zoom
-- =============================================================================

--@api-stub: Camera2D:setZoom
cam:setZoom(1.0)

--@api-stub: Camera2D:getZoom
print("zoom: " .. cam:getZoom())

--@api-stub: Camera2D:getEffectiveZoom
print("effective zoom: " .. cam:getEffectiveZoom())

--@api-stub: Camera2D:zoomTo
-- Smooth zoom from current to target over 0.5 seconds.
cam:zoomTo(1.5, 0.5)

--@api-stub: Camera2D:updateZoom
cam:updateZoom(1/60)

--@api-stub: Camera2D:stopZoom
cam:stopZoom()

--@api-stub: Camera2D:zoomPulse
-- Quick zoom-in pulse on item pickup.
cam:zoomPulse(1.1, 0.2)

-- =============================================================================
-- Rotation
-- =============================================================================

--@api-stub: Camera2D:setRotation
cam:setRotation(0)

--@api-stub: Camera2D:getRotation
print("rotation: " .. cam:getRotation())

-- =============================================================================
-- Viewport & Bounds
-- =============================================================================

--@api-stub: Camera2D:setViewport
cam:setViewport(0, 0, 800, 600)

--@api-stub: Camera2D:getViewport
local vx, vy, vw, vh = cam:getViewport()
print("viewport: " .. vx .. "," .. vy .. " " .. vw .. "x" .. vh)

--@api-stub: Camera2D:setBounds
-- Prevent the camera from showing areas outside the world.
cam:setBounds(0, 0, 3200, 2400)

--@api-stub: Camera2D:removeBounds
-- cam:removeBounds()

--@api-stub: Camera2D:getVisibleArea
local ax, ay, aw, ah = cam:getVisibleArea()
print("visible: " .. ax .. "," .. ay .. " " .. aw .. "x" .. ah)

-- =============================================================================
-- Following a Target
-- =============================================================================

--@api-stub: Camera2D:setTarget
-- Set the player entity as the follow target.
cam:setTarget({x = 400, y = 300})

--@api-stub: Camera2D:clearTarget
-- cam:clearTarget()

--@api-stub: Camera2D:setFollowSmooth
-- Smooth lerp following (0.1 = slow follow, 1.0 = instant).
cam:setFollowSmooth(0.08)

--@api-stub: Camera2D:setDeadZone
-- Dead zone: camera doesn't move until target exits this rectangle.
cam:setDeadZone(80, 60)

--@api-stub: Camera2D:setLookAhead
-- Look ahead in the direction of movement.
cam:setLookAhead(50, 30)

-- =============================================================================
-- Screen Shake
-- =============================================================================

--@api-stub: Camera2D:shake
-- Shake on player damage (intensity, duration, frequency).
cam:shake(8.0, 0.3, 30)

--@api-stub: Camera2D:getEffectOffset
local ox, oy = cam:getEffectOffset()
print("shake offset: " .. ox .. "," .. oy)

-- =============================================================================
-- Camera Update
-- =============================================================================

--@api-stub: Camera2D:update
cam:update(1/60)

-- =============================================================================
-- Coordinate Conversion
-- =============================================================================

--@api-stub: Camera2D:toWorld
-- Convert screen coordinates to world coordinates (for mouse picking).
local wx, wy = cam:toWorld(400, 300)
print("screen center in world: " .. wx .. "," .. wy)

--@api-stub: Camera2D:toScreen
-- Convert world coordinates to screen for HUD indicators.
local scrx, scry = cam:toScreen(500, 250)
print("world (500,250) on screen: " .. scrx .. "," .. scry)

-- =============================================================================
-- Cinematic Camera Paths
-- =============================================================================

--@api-stub: Camera2D:followPath
-- Move the camera along a predefined path for cutscenes.
cam:followPath({{100,100}, {400,200}, {700,100}}, 3.0)

--@api-stub: Camera2D:updatePath
cam:updatePath(1/60)

--@api-stub: Camera2D:pathProgress
print("path progress: " .. cam:pathProgress())

--@api-stub: Camera2D:stopPath
cam:stopPath()

-- =============================================================================
-- Parallax Integration
-- =============================================================================

--@api-stub: Camera2D:setParallaxFactor
-- Set depth factor for a named parallax layer.
cam:setParallaxFactor("sky", 0.2)
cam:setParallaxFactor("mountains", 0.5)

--@api-stub: Camera2D:getParallaxFactor
print("sky parallax: " .. cam:getParallaxFactor("sky"))

--@api-stub: Camera2D:clearParallaxFactors
-- cam:clearParallaxFactors()

-- =============================================================================
-- Breathing & Sway Effects
-- =============================================================================

--@api-stub: Camera2D:startBreathing
-- Subtle idle camera breathing for atmosphere.
cam:startBreathing(2.0, 1.5)

--@api-stub: Camera2D:isBreathing
print("breathing: " .. tostring(cam:isBreathing()))

--@api-stub: Camera2D:stopBreathing
cam:stopBreathing()

--@api-stub: Camera2D:stopSway
cam:stopSway()

--@api-stub: Camera2D:isSway
print("swaying: " .. tostring(cam:isSway()))

print("\n-- camera.lua example complete --")

-- =============================================================================
-- STUBS: 4 uncovered lurek.camera API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- ---- Stub: lurek.camera.newCamera ----------------------------------------
--@api-stub: lurek.camera.newCamera
-- (no description)
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
lurek.camera.newCamera([vw], [vh])

-- -----------------------------------------------------------------------------
-- Camera2D methods
-- -----------------------------------------------------------------------------

-- ---- Stub: Camera2D:removeBounds -----------------------------------------
--@api-stub: Camera2D:removeBounds
-- Removes previously set world-space bounds.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- camera2D_stub:removeBounds()
-- (replace camera2D_stub with your real Camera2D instance above)

-- ---- Stub: Camera2D:clearTarget ------------------------------------------
--@api-stub: Camera2D:clearTarget
-- Clears the follow target so the camera stops tracking.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- camera2D_stub:clearTarget()
-- (replace camera2D_stub with your real Camera2D instance above)

-- ---- Stub: Camera2D:clearParallaxFactors ---------------------------------
--@api-stub: Camera2D:clearParallaxFactors
-- Removes all parallax factor overrides.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- camera2D_stub:clearParallaxFactors()
-- (replace camera2D_stub with your real Camera2D instance above)
