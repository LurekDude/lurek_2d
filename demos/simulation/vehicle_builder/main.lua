-- Vehicle Builder — Physics-Based Construction & Test Track
-- Build a vehicle from parts, then test it on a track with physics

local mode = "build"  -- "build" or "test"
local GRID = 20
local BUILD_OX, BUILD_OY = 100, 320
local BUILD_W, BUILD_H = 12, 8

local parts = {}    -- {gx, gy, type}   type: "chassis", "wheel", "engine", "wing"
local budget = 500
local partCosts = { chassis = 20, wheel = 50, engine = 80, wing = 40 }
local partColors = {
    chassis = {0.4, 0.4, 0.5},
    wheel   = {0.2, 0.2, 0.2},
    engine  = {0.8, 0.3, 0.2},
    wing    = {0.3, 0.6, 0.8},
}
local selectedPart = "chassis"

-- Test mode state
local world, vehicleBodies
local testX, testY = 0, 0
local testVx = 0
local trackScroll = 0
local testScore = 0
local testActive = false
local obstacles = {}
local ramps = {}
local testMsg = ""
local testMsgTimer = 0

local function getTotalCost()
    local t = 0
    for _, p in ipairs(parts) do t = t + partCosts[p.type] end
    return t
end

local function getCenterOfMass()
    if #parts == 0 then return 0, 0 end
    local sx, sy, w = 0, 0, 0
    for _, p in ipairs(parts) do
        local mass = (p.type == "chassis") and 2 or (p.type == "wheel" and 1 or (p.type == "engine" and 3 or 0.5))
        sx = sx + p.gx * mass
        sy = sy + p.gy * mass
        w = w + mass
    end
    return sx / w, sy / w
end

local function partAt(gx, gy)
    for i, p in ipairs(parts) do
        if p.gx == gx and p.gy == gy then return i end
    end
    return nil
end

local function buildTrack()
    obstacles = {}
    ramps = {}
    for i = 1, 8 do
        table.insert(obstacles, { x = 300 + i * 250, w = 30, h = 20 + math.random(10, 40) })
    end
    for i = 1, 5 do
        table.insert(ramps, { x = 500 + i * 400, w = 60, h = 20 })
    end
end

local function startTest()
    if #parts == 0 then return end

    -- Count parts for physics
    local hasWheel = false
    local hasEngine = false
    local totalMass = 0
    for _, p in ipairs(parts) do
        if p.type == "wheel" then hasWheel = true end
        if p.type == "engine" then hasEngine = true end
        local m = (p.type == "chassis") and 2 or (p.type == "wheel" and 1 or (p.type == "engine" and 3 or 0.5))
        totalMass = totalMass + m
    end

    if not hasWheel then
        testMsg = "Need at least one wheel!"
        testMsgTimer = 2
        return
    end

    mode = "test"
    testX = 100
    testY = 200
    testVx = 0
    trackScroll = 0
    testScore = 0
    testActive = true
    buildTrack()

    -- Use physics world
    world = luna.physics.newWorld(0, 300)

    vehicleBodies = {}
    -- Ground
    local ground = luna.physics.newBody(world, 2000, 290, "static")
    luna.physics.setBodySize(world, ground, 8000, 20)

    -- Vehicle body as single physics entity
    local cx, cy = getCenterOfMass()
    local vw = 0
    local vh = 0
    for _, p in ipairs(parts) do
        local dx = math.abs(p.gx - cx)
        local dy = math.abs(p.gy - cy)
        if dx > vw then vw = dx end
        if dy > vh then vh = dy end
    end
    vw = (vw + 1) * GRID
    vh = (vh + 1) * GRID

    local body = luna.physics.newBody(world, testX, testY, "dynamic")
    luna.physics.setBodySize(world, body, vw, vh)
    luna.physics.setBodyRestitution(world, body, 0.2)
    vehicleBodies.main = body
    vehicleBodies.mass = totalMass
    vehicleBodies.hasEngine = hasEngine
    vehicleBodies.wingCount = 0
    vehicleBodies.wheelCount = 0
    for _, p in ipairs(parts) do
        if p.type == "wing" then vehicleBodies.wingCount = vehicleBodies.wingCount + 1 end
        if p.type == "wheel" then vehicleBodies.wheelCount = vehicleBodies.wheelCount + 1 end
    end

    -- Ramp and obstacle bodies
    for _, r in ipairs(ramps) do
        local rb = luna.physics.newBody(world, r.x, 280 - r.h, "static")
        luna.physics.setBodySize(world, rb, r.w, r.h)
    end
    for _, o in ipairs(obstacles) do
        local ob = luna.physics.newBody(world, o.x, 290 - o.h, "static")
        luna.physics.setBodySize(world, ob, o.w, o.h)
    end
end

function luna.init()
    buildTrack()
end

function luna.process(dt)
    if testMsgTimer > 0 then testMsgTimer = testMsgTimer - dt end

    if mode == "test" and testActive then
        -- Controls
        local accel = 0
        if luna.keyboard.isDown("right") and vehicleBodies.hasEngine then
            accel = 150 / (vehicleBodies.mass * 0.3)
        end
        if luna.keyboard.isDown("left") then
            accel = -80
        end

        -- Wing lift reduces effective gravity slightly
        local lift = vehicleBodies.wingCount * 20

        local bx, by = luna.physics.getBody(world, vehicleBodies.main)
        testVx = testVx + accel * dt
        testVx = testVx * (1 - 0.3 * dt) -- friction
        luna.physics.setBodyVelocity(world, vehicleBodies.main, testVx * 50, -lift)

        luna.physics.step(world, dt)

        bx, by = luna.physics.getBody(world, vehicleBodies.main)
        testX = bx
        testY = by
        trackScroll = bx - 200

        -- Score based on distance
        local dist = math.floor(bx / 10)
        if dist > testScore then testScore = dist end

        -- Check if fallen or stuck
        if by > 400 then
            testActive = false
            testMsg = "Vehicle fell! Score: " .. testScore
            testMsgTimer = 5
        end
        if bx > 3000 then
            testActive = false
            testMsg = "Track complete! Score: " .. testScore
            testMsgTimer = 5
        end
    end
end

function luna.keypressed(key)
    if key == "t" and mode == "build" then startTest() end
    if key == "r" and mode == "test" then mode = "build"; testActive = false end
    if key == "c" and mode == "build" then parts = {} end
    if key == "escape" then luna.signal.quit() end
    if mode == "build" then
        if key == "1" then selectedPart = "chassis" end
        if key == "2" then selectedPart = "wheel" end
        if key == "3" then selectedPart = "engine" end
        if key == "4" then selectedPart = "wing" end
    end
end

function luna.mousepressed(mx, my, btn)
    if mode ~= "build" then return end
    local gx = math.floor((mx - BUILD_OX) / GRID)
    local gy = math.floor((my - BUILD_OY) / GRID)
    if gx < 0 or gx >= BUILD_W or gy < 0 or gy >= BUILD_H then return end

    if btn == 1 then
        local existing = partAt(gx, gy)
        if not existing then
            local cost = partCosts[selectedPart]
            if getTotalCost() + cost <= budget then
                table.insert(parts, { gx = gx, gy = gy, type = selectedPart })
            end
        end
    elseif btn == 2 then
        local existing = partAt(gx, gy)
        if existing then table.remove(parts, existing) end
    end
end

function luna.render()
    if mode == "build" then
        luna.gfx.setBackgroundColor(0.12, 0.12, 0.15)

        -- Track preview (top half)
        luna.gfx.setColor(0.2, 0.2, 0.25, 1)
        luna.gfx.rectangle("fill", 0, 0, 800, 300)
        luna.gfx.setColor(0.3, 0.5, 0.3, 1)
        luna.gfx.rectangle("fill", 0, 280, 800, 20)
        luna.gfx.setColor(0.6, 0.6, 0.6, 1)
        luna.gfx.print("TRACK PREVIEW (press T to test)", 280, 140)

        -- Ramps in preview
        luna.gfx.setColor(0.5, 0.4, 0.2, 1)
        for _, r in ipairs(ramps) do
            local rx = r.x * 0.2 + 50
            if rx < 800 then
                luna.gfx.rectangle("fill", rx, 280 - r.h * 0.5, r.w * 0.3, r.h * 0.5)
            end
        end

        -- Build grid
        luna.gfx.setColor(0.2, 0.2, 0.25, 1)
        for gy = 0, BUILD_H - 1 do
            for gx = 0, BUILD_W - 1 do
                luna.gfx.rectangle("line", BUILD_OX + gx * GRID, BUILD_OY + gy * GRID, GRID, GRID)
            end
        end

        -- Parts
        for _, p in ipairs(parts) do
            local c = partColors[p.type]
            luna.gfx.setColor(c[1], c[2], c[3], 1)
            if p.type == "wheel" then
                luna.gfx.circle("fill", BUILD_OX + p.gx * GRID + GRID/2, BUILD_OY + p.gy * GRID + GRID/2, GRID/2 - 1)
            else
                luna.gfx.rectangle("fill", BUILD_OX + p.gx * GRID + 1, BUILD_OY + p.gy * GRID + 1, GRID - 2, GRID - 2)
            end
            -- Label
            luna.gfx.setColor(1, 1, 1, 0.7)
            local label = p.type:sub(1, 1):upper()
            luna.gfx.print(label, BUILD_OX + p.gx * GRID + 5, BUILD_OY + p.gy * GRID + 3)
        end

        -- Center of mass
        if #parts > 0 then
            local cx, cy = getCenterOfMass()
            luna.gfx.setColor(1, 1, 0, 1)
            luna.gfx.circle("fill", BUILD_OX + cx * GRID + GRID/2, BUILD_OY + cy * GRID + GRID/2, 4)
            luna.gfx.print("CoM", BUILD_OX + cx * GRID + GRID/2 + 6, BUILD_OY + cy * GRID + GRID/2 - 6)
        end

        -- HUD
        luna.gfx.setColor(0, 0, 0, 0.8)
        luna.gfx.rectangle("fill", 0, 560, 800, 40)
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.print("Budget: $" .. (budget - getTotalCost()) .. "/" .. budget, 10, 568)
        luna.gfx.print("[1]Chassis($20) [2]Wheel($50) [3]Engine($80) [4]Wing($40)", 200, 568)
        luna.gfx.setColor(0.5, 1, 0.5, 1)
        luna.gfx.print("Selected: " .. selectedPart, 10, 548)
        luna.gfx.print("[T]Test [C]Clear [RClick]Remove", 500, 548)

    else
        -- Test mode
        luna.gfx.setBackgroundColor(0.3, 0.5, 0.8)

        local sx = -trackScroll

        -- Ground
        luna.gfx.setColor(0.3, 0.5, 0.3, 1)
        luna.gfx.rectangle("fill", sx, 280, 8000, 40)

        -- Ramps
        luna.gfx.setColor(0.6, 0.5, 0.2, 1)
        for _, r in ipairs(ramps) do
            luna.gfx.rectangle("fill", r.x + sx, 280 - r.h, r.w, r.h)
        end

        -- Obstacles
        luna.gfx.setColor(0.5, 0.3, 0.3, 1)
        for _, o in ipairs(obstacles) do
            luna.gfx.rectangle("fill", o.x + sx, 290 - o.h, o.w, o.h)
        end

        -- Vehicle
        for _, p in ipairs(parts) do
            local c = partColors[p.type]
            luna.gfx.setColor(c[1], c[2], c[3], 1)
            local px = testX + p.gx * GRID - 40 + sx
            local py = testY + p.gy * GRID - 60
            if p.type == "wheel" then
                luna.gfx.circle("fill", px + GRID/2, py + GRID/2, GRID/2)
            else
                luna.gfx.rectangle("fill", px, py, GRID, GRID)
            end
        end

        -- HUD
        luna.gfx.setColor(0, 0, 0, 0.7)
        luna.gfx.rectangle("fill", 0, 0, 800, 30)
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.print("Distance: " .. testScore .. "m   [R] Return to build   [Left/Right] Brake/Accel", 10, 6)
    end

    -- Messages
    if testMsgTimer > 0 then
        luna.gfx.setColor(1, 1, 0.5, 1)
        luna.gfx.print(testMsg, 250, 150, 1.3)
    end
end
