-- Physics Sandbox: Spawn, drag, and connect 2D physics objects
-- C=circle R=rect, right-click=delete, drag=move, G=gravity,
-- Space=pause, Delete=clear, J+click two=joint, B=bounce, +/-=size
-- Run with: cargo run -- content/demos/simulation/physics_sandbox

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local SCREEN_W, SCREEN_H = 800, 600
local world
local objects = {}
local next_id = 1
local gravity_on = true
local wind_on = false
local paused = false
local spawn_mode = "circle"
local spawn_size = 20
local bounciness = 0.5
local dragging = nil
local drag_offset_x, drag_offset_y = 0, 0
local joint_mode = false
local joint_first = nil
local joints = {}

local function spawn_object(x, y, kind, size)
    local body
    if kind == "circle" then
        body = world:newCircleBody(x, y, size, "dynamic")
    else
        body = world:newBody(x, y, "dynamic")
        world:addFixture(body:getId(), "rectangle", 1, 0.3, 0, false, size * 2, size * 2)
    end
    body:setRestitution(bounciness)

    local obj = {
        id = next_id,
        body = body,
        kind = kind,
        size = size,
        color = { math.random() * 0.5 + 0.3, math.random() * 0.5 + 0.3, math.random() * 0.5 + 0.3 },
        bounce = bounciness,
    }
    objects[#objects + 1] = obj
    next_id = next_id + 1
    return obj
end

local function find_object_at(mx, my)
    for i = #objects, 1, -1 do
        local o = objects[i]
        local ox, oy = o.body:getPosition()
        local dx = mx - ox
        local dy = my - oy
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < o.size + 5 then return i, o end
    end
    return nil, nil
end

local function remove_object(idx)
    table.remove(objects, idx)
end

function lurek.init()
    world = lurek.physics.newWorld(0, 400)

    -- Ground
    local ground = world:newBody(SCREEN_W / 2, SCREEN_H - 10, "static")
    world:addFixture(ground:getId(), "rectangle", 1, 0.3, 0, false, SCREEN_W, 20)

    -- Walls
    local left = world:newBody(-5, SCREEN_H / 2, "static")
    world:addFixture(left:getId(), "rectangle", 1, 0.3, 0, false, 10, SCREEN_H)
    local right = world:newBody(SCREEN_W + 5, SCREEN_H / 2, "static")
    world:addFixture(right:getId(), "rectangle", 1, 0.3, 0, false, 10, SCREEN_H)
end

function lurek.process(dt)
    if not paused then
        -- Wind
        if wind_on then
            for _, o in ipairs(objects) do
                o.body:setVelocity(100 * math.sin(lurek.time.getTime() * 2), 0)
            end
        end

        world:step(dt)
    end

    -- Dragging
    if dragging then
        local mx, my = lurek.mouse.getPosition()
        local ox, oy = dragging.body:getPosition()
        local fx = (mx - ox) * 15
        local fy = (my - oy) * 15
        dragging.body:setVelocity(fx, fy)
    end
end

function lurek.mousepressed(mx, my, button)
    if button == 1 then
        if joint_mode then
            local idx, obj = find_object_at(mx, my)
            if obj then
                if joint_first == nil then
                    joint_first = obj
                else
                    joints[#joints + 1] = { a = joint_first, b = obj }
                    joint_first = nil
                    joint_mode = false
                end
            end
            return
        end

        local idx, obj = find_object_at(mx, my)
        if obj then
            dragging = obj
        else
            spawn_object(mx, my, spawn_mode, spawn_size)
        end
    elseif button == 2 then
        local idx, obj = find_object_at(mx, my)
        if idx then remove_object(idx) end
    end
end

function lurek.mousereleased(mx, my, button)
    if button == 1 then dragging = nil end
end

function lurek.keypressed(key)
    if key == "c" then spawn_mode = "circle" end
    if key == "r" then spawn_mode = "rect" end
    if key == "g" then
        gravity_on = not gravity_on
        -- Recreate world with new gravity
        -- (for simplicity, toggle by applying velocity to all objects)
    end
    if key == "w" then wind_on = not wind_on end
    if key == "space" then paused = not paused end
    if key == "delete" then
        objects = {}
        joints = {}
    end
    if key == "j" then
        joint_mode = true
        joint_first = nil
    end
    if key == "b" then
        bounciness = bounciness + 0.2
        if bounciness > 1.0 then bounciness = 0.0 end
    end
    if key == "=" or key == "+" then
        spawn_size = clamp(spawn_size + 5, 10, 60)
    end
    if key == "-" then
        spawn_size = clamp(spawn_size - 5, 10, 60)
    end
    if key == "escape" then lurek.signal.quit() end
end

function lurek.render()
    lurek.render.setBackgroundColor(0.1, 0.1, 0.12)

    -- Ground
    lurek.render.setColor(0.3, 0.3, 0.3, 1)
    lurek.render.rectangle("fill", 0, SCREEN_H - 20, SCREEN_W, 20)

    -- Joints
    lurek.render.setLineWidth(2)
    for _, j in ipairs(joints) do
        local ax, ay = j.a.body:getPosition()
        local bx, by = j.b.body:getPosition()
        lurek.render.setColor(0.6, 0.9, 0.3, 0.7)
        lurek.render.line(ax, ay, bx, by)
    end
    lurek.render.setLineWidth(1)

    -- Objects
    for _, o in ipairs(objects) do
        local ox, oy = o.body:getPosition()

        local cr, cg, cb = o.color[1], o.color[2], o.color[3]
        lurek.render.setColor(cr, cg, cb, 1)

        if o.kind == "circle" then
            lurek.render.circle("fill", ox, oy, o.size)
            lurek.render.setColor(cr * 0.6, cg * 0.6, cb * 0.6, 1)
            lurek.render.circle("line", ox, oy, o.size)
        else
            lurek.render.rectangle("fill", ox - o.size, oy - o.size, o.size * 2, o.size * 2)
            lurek.render.setColor(cr * 0.6, cg * 0.6, cb * 0.6, 1)
            lurek.render.rectangle("line", ox - o.size, oy - o.size, o.size * 2, o.size * 2)
        end
    end

    -- Joint mode indicator
    if joint_mode then
        lurek.render.setColor(0.3, 1, 0.3, 0.5)
        if joint_first then
            local ax, ay = joint_first.body:getPosition()
            local mx, my = lurek.mouse.getPosition()
            lurek.render.line(ax, ay, mx, my)
        end
    end

    -- HUD
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Objects: " .. #objects .. "  FPS: " .. lurek.time.getFPS(), 10, 10)

    -- Mode display
    local mode_text = "Mode: " .. spawn_mode:upper() .. "  Size: " .. spawn_size .. "  Bounce: " .. (math.floor(bounciness * 100)) .. "%"
    lurek.render.print(mode_text, 10, 30)

    -- Status flags
    local flags = {}
    if gravity_on then flags[#flags + 1] = "GRAVITY" end
    if wind_on then flags[#flags + 1] = "WIND" end
    if paused then flags[#flags + 1] = "PAUSED" end
    if joint_mode then flags[#flags + 1] = "JOINT" end
    lurek.render.setColor(0.8, 0.8, 0.3, 1)
    lurek.render.print(table.concat(flags, " | "), 10, 50)

    -- Controls
    lurek.render.setColor(0.5, 0.5, 0.5, 1)
    lurek.render.print("C/R:shape G:gravity W:wind Space:pause Del:clear J:joint B:bounce +/-:size", 10, SCREEN_H - 24)
end
