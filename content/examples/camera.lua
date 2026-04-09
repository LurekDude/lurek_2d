-- examples/camera.lua
-- lurek.camera — Camera2D: viewport, position, zoom, follow, shake, coordinate transforms.

-- ── Construction ─────────────────────────────────────────────────────────────

-- new(viewport_w, viewport_h) → Camera2D
-- Creates a new Camera2D whose viewport covers `viewport_w` × `viewport_h` pixels.
local cam = lurek.camera.new(800, 600)

-- ── Position ──────────────────────────────────────────────────────────────────

-- setPosition(x, y) — move camera centre to world position (x, y)
cam:setPosition(400, 300)

-- getPosition() → number, number — returns x, y
local cx, cy = cam:getPosition()

-- lookAt(x, y) — instant snap to centre on world position
cam:lookAt(400, 300)

-- move(dx, dy) — translate the camera by an offset in world space
cam:move(10, 0)  -- scroll right 10 units

-- ── Zoom ──────────────────────────────────────────────────────────────────────

-- setZoom(zoom) — set uniform zoom factor; 1.0 = natural, 2.0 = doubled in
cam:setZoom(1.5)

-- getZoom() → number
local z = cam:getZoom()  -- 1.5

-- ── Rotation ─────────────────────────────────────────────────────────────────

-- setRotation(r) — rotate the viewport (radians)
cam:setRotation(math.pi / 8)  -- tilt 22.5 degrees

-- getRotation() → number
local r = cam:getRotation()

-- ── Viewport ─────────────────────────────────────────────────────────────────

-- setViewport(x, y, w, h) — set the screen-space rectangle this camera renders to
cam:setViewport(0, 0, 800, 600)

-- getViewport() → number, number, number, number (x, y, w, h)
local vx, vy, vw, vh = cam:getViewport()

-- getVisibleArea() → number, number, number, number (x, y, w, h)
-- Returns the world-space rectangle currently visible through this camera.
local wx, wy, ww, wh = cam:getVisibleArea()

-- ── World Bounds ─────────────────────────────────────────────────────────────

-- setBounds(x, y, w, h) — clamp camera position within these world bounds
-- Prevents the camera from scrolling outside the world rectangle.
cam:setBounds(0, 0, 3200, 2400)

-- removeBounds() — remove any previously set clamp bounds
cam:removeBounds()

-- ── Follow Target ─────────────────────────────────────────────────────────────

-- setTarget(x, y) — point the camera follows each update()
cam:setTarget(200, 150)

-- setFollowSmooth(speed) — interpolation speed; 0 = instant snap, higher = snappier
cam:setFollowSmooth(5.0)

-- setDeadZone(w, h) — half-extents of a box; target must leave it before camera moves
cam:setDeadZone(50, 40)

-- setLookAhead(mul) — how far ahead of the target to look (multiplied by velocity)
cam:setLookAhead(0.2)

-- clearTarget() — stop following; camera stays in current position
cam:clearTarget()

-- ── Screen Shake ─────────────────────────────────────────────────────────────

-- shake(intensity, duration) — add a decay-damped shake for `duration` seconds
cam:shake(8, 0.4)  -- 8-pixel intensity, 0.4 second duration

-- ── Update ────────────────────────────────────────────────────────────────────

-- update(dt) — advance follow logic, shake decay, and transition state.
-- Must be called every frame if using follow or shake.
cam:update(1/60)

-- ── Coordinate Transforms ─────────────────────────────────────────────────────

-- toWorld(sx, sy) → wx, wy — screen → world
local wx2, wy2 = cam:toWorld(400, 300)

-- toScreen(wx, wy) → sx, sy — world → screen
local sx, sy = cam:toScreen(wx2, wy2)  -- round-trip

-- ── Typical Usage Pattern ─────────────────────────────────────────────────────

--[[
function lurek.init()
    camera = lurek.camera.new(800, 600)
    camera:setBounds(0, 0, 3200, 1800)
    camera:setFollowSmooth(6.0)
    camera:setDeadZone(80, 60)
    player = { x = 400, y = 300 }
end

function lurek.process(dt)
    -- Move player with arrow keys
    local spd = 150 * dt
    if lurek.keyboard.isDown("right") then player.x = player.x + spd end
    if lurek.keyboard.isDown("left")  then player.x = player.x - spd end
    if lurek.keyboard.isDown("down")  then player.y = player.y + spd end
    if lurek.keyboard.isDown("up")    then player.y = player.y - spd end

    -- Keep camera on player
    camera:setTarget(player.x, player.y)
    camera:update(dt)
end

function lurek.keypressed(key)
    if key == "space" then
        camera:shake(10, 0.3)
    end
end

function lurek.render()
lurek.gfx.setCamera(camera)  would apply the transform for all draws
    -- (actual graphics-integration call depends on lurek.gfx API)
    lurek.gfx.drawCircle("fill", player.x, player.y, 16)
end
]]
