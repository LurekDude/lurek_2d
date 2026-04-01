-- Physics demo for Luna2D
-- Demonstrates: circle bodies, rect bodies, sensors, collision events, layer filtering

local world_id
local ground_id
local wall_left_id
local wall_right_id
local ball_id        -- circle (dynamic)
local box_id         -- rect (dynamic)
local sensor_id      -- circle sensor at bottom
local layer_ball_id  -- circle on different layer (won't collide with others)

local GROUND_Y = 550
local W = 800
local H = 600

local collision_flash = 0  -- seconds left for collision flash display
local collision_count = 0
local sensor_triggered = false

function luna.load()
    luna.window.setTitle("Physics Demo — Luna2D (Circles + Sensors + Layers)")
    luna.graphics.setBackgroundColor(0.05, 0.05, 0.15)

    world_id = luna.physics.newWorld(0, 400)

    -- Ground (static rect)
    ground_id = luna.physics.newBody(world_id, W/2, GROUND_Y, "static")
    luna.physics.setBodySize(world_id, ground_id, W, 50)

    -- Left and right walls
    wall_left_id = luna.physics.newBody(world_id, 25, H/2, "static")
    luna.physics.setBodySize(world_id, wall_left_id, 50, H)

    wall_right_id = luna.physics.newBody(world_id, W - 25, H/2, "static")
    luna.physics.setBodySize(world_id, wall_right_id, 50, H)

    -- Dynamic circle ball (layer 1, collides with everything)
    ball_id = luna.physics.newCircleBody(world_id, W/2 - 60, 80, 22, "dynamic")
    luna.physics.setBodyRestitution(world_id, ball_id, 0.7)
    luna.physics.setBodyLayer(world_id, ball_id, 1, 3)  -- layer 1, collides with layer 1+2

    -- Dynamic box (layer 2, collides with ground/walls and ball)
    box_id = luna.physics.newBody(world_id, W/2 + 40, 120, "dynamic")
    luna.physics.setBodySize(world_id, box_id, 40, 40)
    luna.physics.setBodyRestitution(world_id, box_id, 0.4)
    luna.physics.setBodyLayer(world_id, box_id, 2, 3)  -- layer 2, collides with layer 1+2

    -- Set ground/wall layers to collide with both
    luna.physics.setBodyLayer(world_id, ground_id, 3, 3)
    luna.physics.setBodyLayer(world_id, wall_left_id, 3, 3)
    luna.physics.setBodyLayer(world_id, wall_right_id, 3, 3)

    -- Sensor at bottom of play area (detects bodies passing through without stopping them)
    sensor_id = luna.physics.newBody(world_id, W/2, GROUND_Y - 60, "sensor")
    luna.physics.setBodySize(world_id, sensor_id, W - 100, 20)
    luna.physics.setBodyLayer(world_id, sensor_id, 3, 3)

    -- Ghost ball on layer 4 — does NOT collide with anything else
    layer_ball_id = luna.physics.newCircleBody(world_id, W/2, 200, 18, "dynamic")
    luna.physics.setBodyRestitution(world_id, layer_ball_id, 0.9)
    luna.physics.setBodyLayer(world_id, layer_ball_id, 4, 4)  -- only collides with layer 4
end

function luna.update(dt)
    luna.physics.step(world_id, dt)

    -- Read collision events
    local collisions = luna.physics.getCollisions(world_id)
    if #collisions > 0 then
        collision_count = collision_count + #collisions
        collision_flash = 0.15  -- display for 0.15s
        -- Check if sensor was triggered
        for _, c in ipairs(collisions) do
            if c.body_a == sensor_id or c.body_b == sensor_id then
                sensor_triggered = true
            end
        end
    end

    if collision_flash > 0 then
        collision_flash = collision_flash - dt
    end

    -- Reset with SPACE
    if luna.keyboard.isDown("space") then
        luna.physics.setBodyVelocity(world_id, ball_id, 0, 0)
        luna.physics.setBodyVelocity(world_id, box_id, 0, 0)
        luna.physics.setBodyVelocity(world_id, layer_ball_id, 0, 0)
        sensor_triggered = false
        collision_count = 0
    end

    -- Apply random impulse with R
    if luna.keyboard.isDown("r") then
        luna.physics.setBodyVelocity(world_id, ball_id, math.random(-300, 300), -300)
        luna.physics.setBodyVelocity(world_id, box_id, math.random(-200, 200), -200)
    end
end

function luna.draw()
    -- Ground
    local gx, gy = luna.physics.getBody(world_id, ground_id)
    luna.graphics.setColor(0.25, 0.6, 0.25)
    luna.graphics.rectangle("fill", gx - W/2, gy - 25, W, 50)

    -- Walls
    luna.graphics.setColor(0.3, 0.3, 0.5)
    local lx, ly = luna.physics.getBody(world_id, wall_left_id)
    luna.graphics.rectangle("fill", lx - 25, ly - H/2, 50, H)
    local rx, ry = luna.physics.getBody(world_id, wall_right_id)
    luna.graphics.rectangle("fill", rx - 25, ry - H/2, 50, H)

    -- Sensor zone
    local sx, sy = luna.physics.getBody(world_id, sensor_id)
    if sensor_triggered then
        luna.graphics.setColor(1.0, 1.0, 0.0, 0.35)
    else
        luna.graphics.setColor(0.8, 0.8, 0.0, 0.18)
    end
    luna.graphics.rectangle("fill", sx - (W-100)/2, sy - 10, W-100, 20)
    luna.graphics.setColor(0.8, 0.8, 0.0)
    luna.graphics.rectangle("line", sx - (W-100)/2, sy - 10, W-100, 20)

    -- Ghost ball (layer 4 — falls through without colliding with others)
    local px, py = luna.physics.getBody(world_id, layer_ball_id)
    luna.graphics.setColor(0.5, 0.5, 1.0, 0.6)
    luna.graphics.circle("fill", px, py, 18)
    luna.graphics.setColor(0.7, 0.7, 1.0)
    luna.graphics.circle("line", px, py, 18)

    -- Dynamic box
    local bx2, by2 = luna.physics.getBody(world_id, box_id)
    if collision_flash > 0 then
        luna.graphics.setColor(1.0, 0.8, 0.2)
    else
        luna.graphics.setColor(0.8, 0.5, 0.2)
    end
    luna.graphics.rectangle("fill", bx2 - 20, by2 - 20, 40, 40)

    -- Dynamic circle ball
    local bx, by = luna.physics.getBody(world_id, ball_id)
    if collision_flash > 0 then
        luna.graphics.setColor(1.0, 0.5, 0.5)
    else
        luna.graphics.setColor(1.0, 0.3, 0.2)
    end
    luna.graphics.circle("fill", bx, by, 22)

    -- HUD
    luna.graphics.setColor(0.9, 0.9, 0.9)
    luna.graphics.print("Physics Demo — Circles + Sensors + Layers", 60, 10, 2)
    luna.graphics.setColor(0.7, 0.7, 0.7)
    luna.graphics.print("SPACE: reset  |  R: random impulse", 60, 35, 2)
    luna.graphics.print("Red circle (layer 1) + Orange box (layer 2) collide with each other", 60, 55, 2)
    luna.graphics.print("Blue ghost ball (layer 4) passes through everything", 60, 73, 2)
    luna.graphics.print("Yellow band = sensor zone (detects but does not block)", 60, 91, 2)

    -- Collision counter
    local cc_color = collision_flash > 0 and {1.0, 1.0, 0.2} or {0.5, 0.9, 0.5}
    luna.graphics.setColor(cc_color[1], cc_color[2], cc_color[3])
    luna.graphics.print("Total collisions: " .. tostring(collision_count), 60, 115, 2)

    if sensor_triggered then
        luna.graphics.setColor(1.0, 1.0, 0.0)
        luna.graphics.print("SENSOR TRIGGERED!", 60, 135, 2)
    end
end

