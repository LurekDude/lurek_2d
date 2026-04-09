-- Bridge Builder — Place nodes and beams, then test with physics
-- Run with: cargo run -- content/demos/strategy/bridge_builder

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local W, H = 800, 600
local CLIFF_H = 350
local LEFT_EDGE = 150
local RIGHT_EDGE = 650
local GAP_Y = CLIFF_H

local nodes = {}
local beams = {}
local selected_node = nil
local material = 1 -- 1=Wood, 2=Steel
local mode = "build" -- "build" or "test"
local test_timer = 0
local vehicle = nil
local budget = 500
local score = 0
local result_text = nil
local world = nil

local MAT = {
    { name = "Wood",  cost = 15, max_stress = 1.0,  r = 0.6, g = 0.4, b = 0.2 },
    { name = "Steel", cost = 30, max_stress = 2.5,  r = 0.6, g = 0.6, b = 0.7 },
}

local function dist(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function find_node_at(mx, my)
    for i, n in ipairs(nodes) do
        if dist(mx, my, n.x, n.y) < 12 then return i end
    end
    return nil
end

local function beam_exists(a, b)
    for _, beam in ipairs(beams) do
        if (beam.a == a and beam.b == b) or (beam.a == b and beam.b == a) then
            return true
        end
    end
    return false
end

local function reset_build()
    nodes = {}
    beams = {}
    selected_node = nil
    budget = 500
    score = 0
    result_text = nil
    mode = "build"
    vehicle = nil
    world = nil
    -- add anchor nodes on cliffs
    nodes[1] = { x = LEFT_EDGE, y = GAP_Y, anchored = true }
    nodes[2] = { x = LEFT_EDGE, y = GAP_Y - 50, anchored = true }
    nodes[3] = { x = RIGHT_EDGE, y = GAP_Y, anchored = true }
    nodes[4] = { x = RIGHT_EDGE, y = GAP_Y - 50, anchored = true }
end

function lurek.init()
    lurek.window.setTitle("Bridge Builder")
    lurek.gfx.setBackgroundColor(0.4, 0.7, 0.95)
    reset_build()
end

local function start_test()
    if #beams == 0 then result_text = "No beams placed!"; return end
    mode = "test"
    test_timer = 0
    result_text = nil

    -- compute beam stress based on length and load
    for _, beam in ipairs(beams) do
        beam.stress = 0
        beam.broken = false
        local n1 = nodes[beam.a]
        local n2 = nodes[beam.b]
        beam.rest_len = dist(n1.x, n1.y, n2.x, n2.y)
    end

    -- simple vehicle
    vehicle = { x = LEFT_EDGE - 20, y = GAP_Y - 30, w = 40, h = 20, vx = 60, vy = 0 }
end

local function get_bridge_y_at(vx)
    -- find the beam the vehicle is over and interpolate y
    local best_y = H + 100
    for _, beam in ipairs(beams) do
        if beam.broken then goto continue end
        local n1 = nodes[beam.a]
        local n2 = nodes[beam.b]
        local lx = clamp(vx, clamp(n1.x, 0, W), clamp(n2.x, 0, W))
        local rx = (n1.x < n2.x) and n1 or n2
        local rr = (n1.x < n2.x) and n2 or n1
        if vx >= rx.x and vx <= rr.x and rr.x > rx.x then
            local t = (vx - rx.x) / (rr.x - rx.x)
            local by = lerp(rx.y, rr.y, t)
            if by < best_y then best_y = by end
        end
        ::continue::
    end
    return best_y
end

function lurek.process(dt)
    if mode ~= "test" then return end
    test_timer = test_timer + dt

    -- move vehicle
    vehicle.vy = vehicle.vy + 400 * dt
    vehicle.x = vehicle.x + vehicle.vx * dt
    vehicle.y = vehicle.y + vehicle.vy * dt

    -- check bridge surface
    local bridge_y = get_bridge_y_at(vehicle.x + vehicle.w / 2)
    if vehicle.y + vehicle.h > bridge_y then
        vehicle.y = bridge_y - vehicle.h
        vehicle.vy = 0
    end

    -- check on cliffs
    if vehicle.x + vehicle.w / 2 < LEFT_EDGE then
        if vehicle.y + vehicle.h > GAP_Y then
            vehicle.y = GAP_Y - vehicle.h
            vehicle.vy = 0
        end
    end
    if vehicle.x + vehicle.w / 2 > RIGHT_EDGE then
        if vehicle.y + vehicle.h > GAP_Y then
            vehicle.y = GAP_Y - vehicle.h
            vehicle.vy = 0
        end
    end

    -- stress beams near vehicle
    for _, beam in ipairs(beams) do
        if beam.broken then goto continue end
        local n1 = nodes[beam.a]
        local n2 = nodes[beam.b]
        local mx = (n1.x + n2.x) / 2
        local my = (n1.y + n2.y) / 2
        local vd = dist(vehicle.x + vehicle.w / 2, vehicle.y + vehicle.h, mx, my)
        if vd < beam.rest_len then
            beam.stress = beam.stress + dt * (1.5 - vd / beam.rest_len)
        else
            beam.stress = clamp(beam.stress - dt * 0.5, 0, 10)
        end
        local mat = MAT[beam.mat]
        if beam.stress > mat.max_stress then
            beam.broken = true
        end
        ::continue::
    end

    -- fell off
    if vehicle.y > H + 50 then
        result_text = "Bridge collapsed! The vehicle fell."
        mode = "result"
    end

    -- crossed!
    if vehicle.x > RIGHT_EDGE + 30 then
        local spent = 500 - budget
        score = clamp(500 - spent, 0, 500)
        result_text = "SUCCESS! Score: " .. score .. " (Budget saved: $" .. budget .. ")"
        mode = "result"
    end
end

local function stress_color(stress, max_s)
    local t = clamp(stress / max_s, 0, 1)
    if t < 0.5 then
        return lerp(0, 1, t * 2), 1, 0
    else
        return 1, lerp(1, 0, (t - 0.5) * 2), 0
    end
end

function lurek.render()
    -- water
    lurek.gfx.setColor(0.15, 0.3, 0.6, 1)
    lurek.gfx.rectangle("fill", 0, H - 80, W, 80)

    -- cliffs
    lurek.gfx.setColor(0.35, 0.25, 0.15, 1)
    lurek.gfx.rectangle("fill", 0, GAP_Y, LEFT_EDGE, H - GAP_Y)
    lurek.gfx.rectangle("fill", RIGHT_EDGE, GAP_Y, W - RIGHT_EDGE, H - GAP_Y)
    -- grass
    lurek.gfx.setColor(0.2, 0.6, 0.2, 1)
    lurek.gfx.rectangle("fill", 0, GAP_Y - 8, LEFT_EDGE, 8)
    lurek.gfx.rectangle("fill", RIGHT_EDGE, GAP_Y - 8, W - RIGHT_EDGE, 8)

    -- beams
    for _, beam in ipairs(beams) do
        local n1 = nodes[beam.a]
        local n2 = nodes[beam.b]
        if beam.broken then
            lurek.gfx.setColor(0.3, 0.3, 0.3, 0.4)
        elseif mode == "test" or mode == "result" then
            local mat = MAT[beam.mat]
            local cr, cg, cb = stress_color(beam.stress, mat.max_stress)
            lurek.gfx.setColor(cr, cg, cb, 1)
        else
            local mat = MAT[beam.mat]
            lurek.gfx.setColor(mat.r, mat.g, mat.b, 1)
        end
        lurek.gfx.setLineWidth(beam.mat == 2 and 4 or 3)
        lurek.gfx.line(n1.x, n1.y, n2.x, n2.y)
    end
    lurek.gfx.setLineWidth(1)

    -- nodes
    for i, n in ipairs(nodes) do
        if n.anchored then
            lurek.gfx.setColor(0.7, 0.7, 0.7, 1)
        elseif i == selected_node then
            lurek.gfx.setColor(1, 1, 0, 1)
        else
            lurek.gfx.setColor(1, 1, 1, 1)
        end
        lurek.gfx.circle("fill", n.x, n.y, 6)
    end

    -- vehicle
    if vehicle and (mode == "test" or mode == "result") then
        lurek.gfx.setColor(0.8, 0.2, 0.2, 1)
        lurek.gfx.rectangle("fill", vehicle.x, vehicle.y, vehicle.w, vehicle.h)
        -- wheels
        lurek.gfx.setColor(0.2, 0.2, 0.2, 1)
        lurek.gfx.circle("fill", vehicle.x + 8, vehicle.y + vehicle.h, 6)
        lurek.gfx.circle("fill", vehicle.x + vehicle.w - 8, vehicle.y + vehicle.h, 6)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.6)
    lurek.gfx.rectangle("fill", 0, 0, W, 40)
    lurek.gfx.setColor(1, 1, 1, 1)
    local mat = MAT[material]
    lurek.gfx.print("Material: " .. mat.name .. " ($" .. mat.cost .. ")  |  Budget: $" .. budget, 10, 10, 1)
    lurek.gfx.print("1/2=Material  T=Test  R=Reset", W - 280, 10, 0.9)

    if mode == "build" then
        lurek.gfx.setColor(0.8, 0.8, 0.2, 0.7)
        lurek.gfx.print("Click to place nodes. Click two nodes to connect. T to test.", 10, H - 25, 0.9)
    end

    if result_text then
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", W / 2 - 200, H / 2 - 30, 400, 60)
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print(result_text, W / 2 - 180, H / 2 - 15, 0.9)
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then reset_build(); return end
    if key == "1" then material = 1 end
    if key == "2" then material = 2 end
    if key == "t" and mode == "build" then start_test() end
end

function lurek.mousepressed(mx, my, button)
    if mode ~= "build" then return end

    local clicked = find_node_at(mx, my)
    if clicked then
        if selected_node and selected_node ~= clicked then
            if not beam_exists(selected_node, clicked) then
                local cost = MAT[material].cost
                if budget >= cost then
                    beams[#beams + 1] = { a = selected_node, b = clicked, mat = material, stress = 0, broken = false, rest_len = 0 }
                    budget = budget - cost
                end
            end
            selected_node = nil
        else
            selected_node = clicked
        end
    else
        -- place new node in the gap area
        if mx > LEFT_EDGE - 20 and mx < RIGHT_EDGE + 20 and my > 100 and my < H - 100 then
            nodes[#nodes + 1] = { x = mx, y = my, anchored = false }
            if selected_node then
                local new_id = #nodes
                if not beam_exists(selected_node, new_id) then
                    local cost = MAT[material].cost
                    if budget >= cost then
                        beams[#beams + 1] = { a = selected_node, b = new_id, mat = material, stress = 0, broken = false, rest_len = 0 }
                        budget = budget - cost
                    end
                end
            end
            selected_node = #nodes
        end
    end
end
