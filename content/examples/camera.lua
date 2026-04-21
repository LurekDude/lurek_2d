-- content/examples/camera.lua
-- Lurek2D lurek.camera API Reference
-- Run with: cargo run -- content/examples/camera
--
Scenario: A side-scrolling platformer with a smooth-following camera that
-- tracks the player, supports screen shake on hit, zoom transitions, parallax,
-- cinematic paths, and viewport bounds to prevent showing out-of-world areas.

print("=== lurek.camera — 2D Camera System ===\n")

-- =============================================================================
-- Camera Creation
-- =============================================================================

local cam = lurek.camera.new()
print("camera created")

-- =============================================================================
-- Position & Basic Movement
-- =============================================================================

cam:setPosition(400, 300)

local cx, cy = cam:getPosition()
print("camera at: " .. cx .. "," .. cy)

-- Instantly center the camera on a point.
cam:lookAt(500, 250)

-- Pan the camera by a relative offset.
cam:move(10, 0)

-- =============================================================================
-- Zoom
-- =============================================================================

cam:setZoom(1.0)

print("zoom: " .. cam:getZoom())

print("effective zoom: " .. cam:getEffectiveZoom())

-- Smooth zoom from current to target over 0.5 seconds.
cam:zoomTo(1.5, 0.5)

cam:updateZoom(1/60)

cam:stopZoom()

-- Quick zoom-in pulse on item pickup.
cam:zoomPulse(1.1, 0.2)

-- =============================================================================
-- Rotation
-- =============================================================================

cam:setRotation(0)

print("rotation: " .. cam:getRotation())

-- =============================================================================
-- Viewport & Bounds
-- =============================================================================

cam:setViewport(0, 0, 800, 600)

local vx, vy, vw, vh = cam:getViewport()
print("viewport: " .. vx .. "," .. vy .. " " .. vw .. "x" .. vh)

-- Prevent the camera from showing areas outside the world.
cam:setBounds(0, 0, 3200, 2400)

cam:removeBounds()

local ax, ay, aw, ah = cam:getVisibleArea()
print("visible: " .. ax .. "," .. ay .. " " .. aw .. "x" .. ah)

-- =============================================================================
-- Following a Target
-- =============================================================================

-- Set the player entity as the follow target.
cam:setTarget({x = 400, y = 300})

cam:clearTarget()

-- Smooth lerp following (0.1 = slow follow, 1.0 = instant).
cam:setFollowSmooth(0.08)

-- Dead zone: camera doesn't move until target exits this rectangle.
cam:setDeadZone(80, 60)

-- Look ahead in the direction of movement.
cam:setLookAhead(50, 30)

-- =============================================================================
-- Screen Shake
-- =============================================================================

-- Shake on player damage (intensity, duration, frequency).
cam:shake(8.0, 0.3, 30)

local ox, oy = cam:getEffectOffset()
print("shake offset: " .. ox .. "," .. oy)

-- =============================================================================
-- Camera Update
-- =============================================================================

cam:update(1/60)

-- =============================================================================
-- Coordinate Conversion
-- =============================================================================

-- Convert screen coordinates to world coordinates (for mouse picking).
local wx, wy = cam:toWorld(400, 300)
print("screen center in world: " .. wx .. "," .. wy)

-- Convert world coordinates to screen for HUD indicators.
local scrx, scry = cam:toScreen(500, 250)
print("world (500,250) on screen: " .. scrx .. "," .. scry)

-- =============================================================================
-- Cinematic Camera Paths
-- =============================================================================

-- Move the camera along a predefined path for cutscenes.
cam:followPath({{100,100}, {400,200}, {700,100}}, 3.0)

cam:updatePath(1/60)

print("path progress: " .. cam:pathProgress())

cam:stopPath()

-- =============================================================================
-- Parallax Integration
-- =============================================================================

-- Set depth factor for a named parallax layer.
cam:setParallaxFactor("sky", 0.2)
cam:setParallaxFactor("mountains", 0.5)

print("sky parallax: " .. cam:getParallaxFactor("sky"))

cam:clearParallaxFactors()

-- =============================================================================
-- Breathing & Sway Effects
-- =============================================================================

-- Subtle idle camera breathing for atmosphere.
cam:startBreathing(2.0, 1.5)

print("breathing: " .. tostring(cam:isBreathing()))

cam:stopBreathing()

cam:stopSway()

print("swaying: " .. tostring(cam:isSway()))

print("\n-- camera.lua example complete --")

-- =============================================================================
-- Advanced Edge Cases and Extra API Demonstrations
-- =============================================================================

-- (no description)
lurek.camera.newCamera([vw], [vh])

-- -----------------------------------------------------------------------------
-- Camera2D methods
-- -----------------------------------------------------------------------------

-- Removes previously set world-space bounds.
-- camera2D_stub:removeBounds()
-- Clears the follow target so the camera stops tracking.
-- camera2D_stub:clearTarget()
-- Removes all parallax factor overrides.
-- camera2D_stub:clearParallaxFactors()
