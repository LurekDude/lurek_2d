-- Physics demo for Luna2D
-- Demonstrates: circle bodies, rect bodies, sensors, collision events, layer filtering
-- Run with: cargo run -- demos/simulation/physics_demo

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

-- Shape descriptor: newCircleShape returns a raw (type, radius) tuple
local _shape_type, _shape_r = luna.physics.newCircleShape(25)
print("[physics_demo] shape type:", _shape_type, "radius:", _shape_r)

function luna.init()
    luna.window.setTitle("Physics Demo -- Luna2D (Circles + Sensors + Layers)")
    luna.gfx.setBackgroundColor(0.05, 0.05, 0.15)

    world_id = luna.physics.newWorld(0, 400)

    -- Ground (static rect)
    ground_id = world_id:newBody(W/2, GROUND_Y, "static")
    world_id:addFixture(ground_id:getId(), "rectangle", 1, 0.3, 0, false, W, 50)

    -- Left and right walls
    wall_left_id = world_id:newBody(25, H/2, "static")
    world_id:addFixture(wall_left_id:getId(), "rectangle", 1, 0.3, 0, false, 50, H)

    wall_right_id = world_id:newBody(W - 25, H/2, "static")
    world_id:addFixture(wall_right_id:getId(), "rectangle", 1, 0.3, 0, false, 50, H)

    -- Dynamic circle ball (layer 1, collides with everything)
    ball_id = world_id:newCircleBody(W/2 - 60, 80, 22, "dynamic")
    ball_id:setRestitution(0.7)
    ball_id:setLayer(1); ball_id:setMask(3)

    -- Dynamic box (layer 2, collides with ground/walls and ball)
    box_id = world_id:newBody(W/2 + 40, 120, "dynamic")
    world_id:addFixture(box_id:getId(), "rectangle", 1, 0.3, 0, false, 40, 40)
    box_id:setRestitution(0.4)
    box_id:setLayer(2); box_id:setMask(3)

    -- Set ground/wall layers to collide with both
    ground_id:setLayer(3); ground_id:setMask(3)
    wall_left_id:setLayer(3); wall_left_id:setMask(3)
    wall_right_id:setLayer(3); wall_right_id:setMask(3)

    -- Sensor at bottom of play area (detects bodies passing through without stopping them)
    sensor_id = world_id:newBody(W/2, GROUND_Y - 60, "sensor")
    world_id:addFixture(sensor_id:getId(), "rectangle", 1, 0.3, 0, false, W - 100, 20)
    sensor_id:setLayer(3); sensor_id:setMask(3)

    -- Ghost ball on layer 4 -- does NOT collide with anything else
    layer_ball_id = world_id:newCircleBody(W/2, 200, 18, "dynamic")
    layer_ball_id:setRestitution(0.9)
    layer_ball_id:setLayer(4); layer_ball_id:setMask(4)
end

function luna.process(dt)
    world_id:step(dt)

    -- Read collision events
    local collisions = world_id:getCollisionEvents()
    if #collisions > 0 then
        collision_count = collision_count + #collisions
        collision_flash = 0.15
        -- Check if sensor was triggered
        for _, c in ipairs(collisions) do
            if c.bodyA == sensor_id:getId() or c.bodyB == sensor_id:getId() then
                sensor_triggered = true
            end
        end
    end

    if collision_flash > 0 then
        collision_flash = collision_flash - dt
    end

    -- Reset with SPACE
    if luna.keyboard.isDown("space") then
        ball_id:setVelocity(0, 0)
        box_id:setVelocity(0, 0)
        layer_ball_id:setVelocity(0, 0)
        sensor_triggered = false
        collision_count = 0
    end

    -- Apply random impulse with R
    if luna.keyboard.isDown("r") then
        ball_id:setVelocity(math.random(-300, 300), -300)
        box_id:setVelocity(math.random(-200, 200), -200)
    end
end

function luna.render()
    -- Ground
    local gx, gy = ground_id:getPosition()
    luna.gfx.setColor(0.25, 0.6, 0.25)
    luna.gfx.rectangle("fill", gx - W/2, gy - 25, W, 50)

    -- Walls
    luna.gfx.setColor(0.3, 0.3, 0.5)
    local lx, ly = wall_left_id:getPosition()
    luna.gfx.rectangle("fill", lx - 25, ly - H/2, 50, H)
    local rx, ry = wall_right_id:getPosition()
    luna.gfx.rectangle("fill", rx - 25, ry - H/2, 50, H)

    -- Sensor zone
    local sx, sy = sensor_id:getPosition()
    if sensor_triggered then
        luna.gfx.setColor(1.0, 1.0, 0.0, 0.35)
    else
        luna.gfx.setColor(0.8, 0.8, 0.0, 0.18)
    end
    luna.gfx.rectangle("fill", sx - (W-100)/2, sy - 10, W-100, 20)
    luna.gfx.setColor(0.8, 0.8, 0.0)
    luna.gfx.rectangle("line", sx - (W-100)/2, sy - 10, W-100, 20)

    -- Ghost ball (layer 4 -- falls through without colliding with others)
    local px, py = layer_ball_id:getPosition()
    luna.gfx.setColor(0.5, 0.5, 1.0, 0.6)
    luna.gfx.circle("fill", px, py, 18)
    luna.gfx.setColor(0.7, 0.7, 1.0)
    luna.gfx.circle("line", px, py, 18)

    -- Dynamic box
    local bx2, by2 = box_id:getPosition()
    if collision_flash > 0 then
        luna.gfx.setColor(1.0, 0.8, 0.2)
    else
        luna.gfx.setColor(0.8, 0.5, 0.2)
    end
    luna.gfx.rectangle("fill", bx2 - 20, by2 - 20, 40, 40)

    -- Dynamic circle ball
    local bx, by = ball_id:getPosition()
    if collision_flash > 0 then
        luna.gfx.setColor(1.0, 0.5, 0.5)
    else
        luna.gfx.setColor(1.0, 0.3, 0.2)
    end
    luna.gfx.circle("fill", bx, by, 22)

    -- HUD
    luna.gfx.setColor(0.9, 0.9, 0.9)
    luna.gfx.print("Physics Demo -- Circles + Sensors + Layers", 60, 10, 2)
    luna.gfx.setColor(0.7, 0.7, 0.7)
    luna.gfx.print("SPACE: reset  |  R: random impulse", 60, 35, 2)
    luna.gfx.print("Red circle (layer 1) + Orange box (layer 2) collide with each other", 60, 55, 2)
    luna.gfx.print("Blue ghost ball (layer 4) passes through everything", 60, 73, 2)
    luna.gfx.print("Yellow band = sensor zone (detects but does not block)", 60, 91, 2)

    -- Collision counter
    local cc_color = collision_flash > 0 and {1.0, 1.0, 0.2} or {0.5, 0.9, 0.5}
    luna.gfx.setColor(cc_color[1], cc_color[2], cc_color[3])
    luna.gfx.print("Total collisions: " .. tostring(collision_count), 60, 115, 2)

    if sensor_triggered then
        luna.gfx.setColor(1.0, 1.0, 0.0)
        luna.gfx.print("SENSOR TRIGGERED!", 60, 135, 2)
    end
end
