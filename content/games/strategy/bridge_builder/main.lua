-- ============================================================================
--  Bridge Builder — Engineer bridges across canyons
-- ----------------------------------------------------------------------------
--  Category : strategy
--  Run with : cargo run -- content/games/strategy/bridge_builder
--
--  Controls (bound as input actions — see lurek.init):
--    road         : R           — select road beam
--    steel        : S           — select steel beam
--    cable        : C           — select cable beam
--    test         : T           — send vehicle across
--    undo         : Z           — undo last beam
--    delete       : D           — toggle delete mode
--    place        : mouse1      — place node / connect
--    quit         : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local NODE_RADIUS        = 6
local SNAP_DIST          = 14
local GRAVITY            = 400
local VEHICLE_SPEED      = 80
local BEAM_BREAK_STRESS  = 1.0

-- Beam type definitions: cost, color, flags
local BEAM_TYPES = {
    road  = { cost = 10, r = 0.55, g = 0.55, b = 0.55, thick = 4, horiz_only = true,  tension_only = false, label = "Road"  },
    steel = { cost = 15, r = 0.3,  g = 0.5,  b = 0.9,  thick = 3, horiz_only = false, tension_only = false, label = "Steel" },
    cable = { cost = 5,  r = 0.5,  g = 0.8,  b = 1.0,  thick = 1, horiz_only = false, tension_only = true,  label = "Cable" },
}

-- ── Level definitions ─────────────────────────────────────────────────────
local LEVELS = {
    { gap = 160, budget = 50,  vehicle_weight = 1.0, name = "Gentle Creek"      },
    { gap = 200, budget = 60,  vehicle_weight = 1.0, name = "Rocky Stream"      },
    { gap = 250, budget = 80,  vehicle_weight = 1.2, name = "Wide River"        },
    { gap = 300, budget = 100, vehicle_weight = 1.5, name = "Deep Gorge"        },
    { gap = 340, budget = 120, vehicle_weight = 2.0, name = "Truck Pass"        },
    { gap = 380, budget = 140, vehicle_weight = 2.0, name = "Ravine Crossing"   },
    { gap = 420, budget = 170, vehicle_weight = 2.5, name = "Canyon Divide"     },
    { gap = 500, budget = 200, vehicle_weight = 3.0, name = "Grand Canyon"      },
}

-- ── States ────────────────────────────────────────────────────────────────
local STATE = { TITLE = 1, BUILDING = 2, TESTING = 3, SUCCESS = 4, FAIL = 5, LEVEL_SELECT = 6 }
local state = STATE.TITLE

-- ── Game data ─────────────────────────────────────────────────────────────
local nodes          -- array of { x, y, fixed }
local beams          -- array of { n1, n2, type, stress, broken }
local selected_node  -- index of first-clicked node for connection
local beam_type      -- "road" | "steel" | "cable"
local delete_mode    -- bool
local current_level  -- 1..8
local budget_spent
local budget_total
local levels_unlocked

-- Vehicle state (testing mode)
local vehicle        -- { x, y, vx, vy, on_beam, progress, weight, w, h }

-- Visual effects
local cam
local sparks_ps      -- construction sparks
local debris_ps      -- beam break debris
local splash_ps      -- water splash
local confetti_ps    -- success confetti
local score_display  -- { value } for tween
local title_blink    = 0
local result_msg     = ""

-- Terrain geometry (computed per level)
local cliff_left_x, cliff_right_x, cliff_y
local river_y, river_h

-- ── Helpers ───────────────────────────────────────────────────────────────

local function dist(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function dist_point_to_segment(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local len2 = dx * dx + dy * dy
    if len2 == 0 then return dist(px, py, ax, ay) end
    local t = math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / len2))
    local proj_x = ax + t * dx
    local proj_y = ay + t * dy
    return dist(px, py, proj_x, proj_y)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

--- Color interpolation for stress: green → yellow → red
local function stress_color(s)
    s = clamp(s, 0, 1)
    if s < 0.5 then
        return lerp(0.2, 1.0, s * 2), lerp(0.9, 0.9, s * 2), lerp(0.2, 0.1, s * 2)
    else
        return 1.0, lerp(0.9, 0.1, (s - 0.5) * 2), lerp(0.1, 0.1, (s - 0.5) * 2)
    end
end

--- Find node near a position.
local function find_node_near(mx, my)
    for i, n in ipairs(nodes) do
        if dist(mx, my, n.x, n.y) < SNAP_DIST then
            return i
        end
    end
    return nil
end

--- Check if beam already exists between two nodes.
local function beam_exists(n1, n2)
    for _, b in ipairs(beams) do
        if (b.n1 == n1 and b.n2 == n2) or (b.n1 == n2 and b.n2 == n1) then
            return true
        end
    end
    return false
end

--- Find beam near a screen position.
local function find_beam_near(mx, my)
    for i, b in ipairs(beams) do
        local a, c = nodes[b.n1], nodes[b.n2]
        if a and c then
            local d = dist_point_to_segment(mx, my, a.x, a.y, c.x, c.y)
            if d < 10 then return i end
        end
    end
    return nil
end

--- Beam length helper.
local function beam_length(b)
    local a, c = nodes[b.n1], nodes[b.n2]
    return dist(a.x, a.y, c.x, c.y)
end

--- Total cost of all beams.
local function total_cost()
    local c = 0
    for _, b in ipairs(beams) do
        c = c + BEAM_TYPES[b.type].cost
    end
    return c
end

--- Setup terrain for the current level.
local function setup_terrain()
    local lv = LEVELS[current_level]
    local gap = lv.gap
    local center_x = SCREEN_W / 2
    cliff_left_x  = center_x - gap / 2
    cliff_right_x = center_x + gap / 2
    cliff_y       = SCREEN_H * 0.55
    river_y       = SCREEN_H * 0.78
    river_h       = SCREEN_H - river_y
end

--- Place fixed anchor nodes on cliff edges.
local function setup_anchors()
    nodes = {}
    -- Left cliff anchors (top, mid, low)
    nodes[#nodes + 1] = { x = cliff_left_x,      y = cliff_y,       fixed = true }
    nodes[#nodes + 1] = { x = cliff_left_x,      y = cliff_y + 30,  fixed = true }
    nodes[#nodes + 1] = { x = cliff_left_x - 30, y = cliff_y,       fixed = true }
    -- Right cliff anchors
    nodes[#nodes + 1] = { x = cliff_right_x,      y = cliff_y,       fixed = true }
    nodes[#nodes + 1] = { x = cliff_right_x,      y = cliff_y + 30,  fixed = true }
    nodes[#nodes + 1] = { x = cliff_right_x + 30, y = cliff_y,       fixed = true }
end

--- Initialize a level.
local function start_level(lv_num)
    current_level = lv_num
    beam_type     = "road"
    delete_mode   = false
    selected_node = nil
    beams         = {}
    vehicle       = nil
    budget_total  = LEVELS[lv_num].budget
    budget_spent  = 0
    result_msg    = ""
    setup_terrain()
    setup_anchors()
    state = STATE.BUILDING
end

--- Spawn vehicle for testing.
local function spawn_vehicle()
    local lv = LEVELS[current_level]
    local w = lv.vehicle_weight >= 2.0 and 40 or 28
    local h = lv.vehicle_weight >= 2.0 and 22 or 16
    vehicle = {
        x        = cliff_left_x - 60,
        y        = cliff_y - h,
        vx       = VEHICLE_SPEED,
        vy       = 0,
        weight   = lv.vehicle_weight,
        w        = w,
        h        = h,
        on_road  = true,
        progress = 0,
    }
end

--- Get the road surface Y at a given X (from road beams).
local function road_y_at(x)
    local best_y = nil
    for _, b in ipairs(beams) do
        if b.type == "road" and not b.broken then
            local a, c = nodes[b.n1], nodes[b.n2]
            local lx = math.min(a.x, c.x)
            local rx = math.max(a.x, c.x)
            if x >= lx and x <= rx then
                local t = (x - a.x) / (c.x - a.x + 0.001)
                local y = a.y + t * (c.y - a.y)
                -- Add sag based on beam stress
                local sag = b.stress * 8
                y = y + sag
                if best_y == nil or y < best_y then
                    best_y = y
                end
            end
        end
    end
    -- On cliff surface
    if x <= cliff_left_x or x >= cliff_right_x then
        local cy = cliff_y
        if best_y == nil or cy < best_y then
            best_y = cy
        end
    end
    return best_y
end

--- Apply stress to beams based on vehicle position.
local function apply_stress()
    if not vehicle then return end
    local vx = vehicle.x + vehicle.w / 2
    local load = vehicle.weight

    for _, b in ipairs(beams) do
        if b.broken then goto continue end
        local a, c = nodes[b.n1], nodes[b.n2]
        local blen = dist(a.x, a.y, c.x, c.y)
        if blen < 1 then goto continue end

        -- Distance from vehicle center to beam
        local d = dist_point_to_segment(vx, vehicle.y + vehicle.h, a.x, a.y, c.x, c.y)
        local influence = math.max(0, 1 - d / 120)

        -- Base stress from angle (vertical beams take more stress)
        local dx = math.abs(c.x - a.x)
        local angle_factor = 1.0 - (dx / blen) * 0.3

        -- Cable cannot take compression
        local bt = BEAM_TYPES[b.type]
        local compression = (a.y < c.y) and 1.0 or 0.5
        if bt.tension_only and compression > 0.7 then
            b.stress = b.stress + influence * load * 0.1
        else
            b.stress = influence * load * angle_factor * 0.4
        end

        -- Clamp stress
        b.stress = clamp(b.stress, 0, 1.2)

        -- Break!
        if b.stress >= BEAM_BREAK_STRESS then
            b.broken = true
            if debris_ps then
                local mx = (a.x + c.x) / 2
                local my = (a.y + c.y) / 2
                debris_ps:emit(mx, my, 30)
            end
        end
        ::continue::
    end
end

--- Simulate one physics step for vehicle.
local function simulate_vehicle(dt)
    if not vehicle then return end

    local ry = road_y_at(vehicle.x + vehicle.w / 2)

    if ry and vehicle.y + vehicle.h >= ry - 2 then
        -- On road surface
        vehicle.y  = ry - vehicle.h
        vehicle.vy = 0
        vehicle.on_road = true
        vehicle.x  = vehicle.x + vehicle.vx * dt
    else
        -- Falling
        vehicle.vy = vehicle.vy + GRAVITY * vehicle.weight * dt
        vehicle.y  = vehicle.y + vehicle.vy * dt
        vehicle.x  = vehicle.x + vehicle.vx * 0.5 * dt
        vehicle.on_road = false
    end

    vehicle.progress = (vehicle.x - (cliff_left_x - 60)) / (cliff_right_x + 60 - (cliff_left_x - 60))

    -- Check success — vehicle reached far side
    if vehicle.x > cliff_right_x + 40 and vehicle.on_road then
        state = STATE.SUCCESS
        local remaining = budget_total - budget_spent
        local efficiency = math.floor((1.0 - budget_spent / budget_total) * 100)
        result_msg = string.format("Level %d Complete! Budget left: %dg  Efficiency: %d%%", current_level, remaining, efficiency)
        score_display = { value = 0 }
        lurek.tween.to(score_display, { value = remaining + efficiency }, 1.2, "outQuad")
        if confetti_ps then
            confetti_ps:emit(SCREEN_W / 2, SCREEN_H / 3, 80)
        end
        if current_level >= levels_unlocked then
            levels_unlocked = math.min(current_level + 1, #LEVELS)
        end
    end

    -- Check fail — vehicle in river
    if vehicle.y + vehicle.h > river_y then
        state = STATE.FAIL
        result_msg = string.format("Bridge collapsed on Level %d!", current_level)
        if splash_ps then
            splash_ps:emit(vehicle.x + vehicle.w / 2, river_y, 40)
        end
    end
end

-- ===========================================================================
--  lurek.init — runs ONCE before the window opens
-- ===========================================================================
function lurek.init()
    lurek.window.setTitle("Bridge Builder — Lurek2D")
    lurek.render.setBackgroundColor(0.5, 0.7, 0.9)

    cam = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Input bindings
    lurek.input.bind("road",   { "r" })
    lurek.input.bind("steel",  { "s" })
    lurek.input.bind("cable",  { "c" })
    lurek.input.bind("test",   { "t" })
    lurek.input.bind("undo",   { "z" })
    lurek.input.bind("delete", { "d" })
    lurek.input.bind("place",  { "mouse1" })
    lurek.input.bind("quit",   { "escape" })
    lurek.input.bind("confirm",{ "return", "kp_enter" })

    -- Construction sparks
    sparks_ps = lurek.particle.newSystem({
        maxParticles = 100,
        emissionRate = 0,
        lifetimeMin  = 0.15, lifetimeMax = 0.5,
        speedMin     = 40,   speedMax    = 140,
        direction    = -math.pi / 2, spread = math.pi * 0.8,
        gravityY     = 120,
        sizes        = { 2, 1.5, 1 },
        colors = {
            { 1.0, 0.9, 0.3 },
            { 1.0, 0.6, 0.1 },
            { 0.5, 0.3, 0.0, 0.0 },
        },
    })

    -- Beam break debris
    debris_ps = lurek.particle.newSystem({
        maxParticles = 200,
        emissionRate = 0,
        lifetimeMin  = 0.4, lifetimeMax = 1.2,
        speedMin     = 30,  speedMax    = 180,
        direction    = 0,   spread      = math.pi,
        gravityY     = 250,
        sizes        = { 4, 3, 2, 1 },
        colors = {
            { 0.6, 0.5, 0.4 },
            { 0.4, 0.35, 0.3 },
            { 0.3, 0.25, 0.2, 0.0 },
        },
    })

    -- Water splash
    splash_ps = lurek.particle.newSystem({
        maxParticles = 150,
        emissionRate = 0,
        lifetimeMin  = 0.3, lifetimeMax = 1.0,
        speedMin     = 50,  speedMax    = 200,
        direction    = -math.pi / 2, spread = math.pi * 0.5,
        gravityY     = 300,
        sizes        = { 3, 2.5, 2, 1 },
        colors = {
            { 0.4, 0.6, 1.0 },
            { 0.3, 0.5, 0.9, 0.6 },
            { 0.2, 0.4, 0.8, 0.0 },
        },
    })

    -- Success confetti
    confetti_ps = lurek.particle.newSystem({
        maxParticles = 300,
        emissionRate = 0,
        lifetimeMin  = 1.0, lifetimeMax = 3.0,
        speedMin     = 20,  speedMax    = 150,
        direction    = -math.pi / 2, spread = math.pi,
        gravityY     = 40,
        sizes        = { 4, 3, 2 },
        colors = {
            { 1.0, 0.8, 0.2 },
            { 0.2, 0.9, 0.3 },
            { 0.9, 0.2, 0.3 },
            { 0.2, 0.5, 1.0 },
        },
    })

    -- State init
    levels_unlocked = 1
    score_display   = { value = 0 }
    title_blink     = 0
end

-- ===========================================================================
--  lurek.process(dt) — gameplay logic
-- ===========================================================================
function lurek.process(dt)
    -- Global quit
    if lurek.input.wasActionPressed("quit") then
        if state == STATE.BUILDING or state == STATE.TESTING then
            state = STATE.LEVEL_SELECT
            return
        end
        lurek.event.quit()
        return
    end

    lurek.tween.update(dt)
    sparks_ps:update(dt)
    debris_ps:update(dt)
    splash_ps:update(dt)
    confetti_ps:update(dt)

    -- ── TITLE ─────────────────────────────────────────────────────────
    if state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("confirm") then
            state = STATE.LEVEL_SELECT
        end
        return
    end

    -- ── LEVEL SELECT ──────────────────────────────────────────────────
    if state == STATE.LEVEL_SELECT then
        for i = 1, #LEVELS do
            local key = tostring(i)
            if lurek.input.wasActionPressed(key) and i <= levels_unlocked then
                start_level(i)
                return
            end
        end
        return
    end

    -- ── SUCCESS / FAIL ────────────────────────────────────────────────
    if state == STATE.SUCCESS or state == STATE.FAIL then
        if lurek.input.wasActionPressed("confirm") then
            state = STATE.LEVEL_SELECT
        end
        return
    end

    -- ── BUILDING ──────────────────────────────────────────────────────
    if state == STATE.BUILDING then
        -- Beam type selection
        if lurek.input.wasActionPressed("road")  then beam_type = "road";  delete_mode = false end
        if lurek.input.wasActionPressed("steel") then beam_type = "steel"; delete_mode = false end
        if lurek.input.wasActionPressed("cable") then beam_type = "cable"; delete_mode = false end

        -- Delete mode toggle
        if lurek.input.wasActionPressed("delete") then
            delete_mode = not delete_mode
            selected_node = nil
        end

        -- Undo last beam
        if lurek.input.wasActionPressed("undo") and #beams > 0 then
            local removed = table.remove(beams)
            budget_spent = budget_spent - BEAM_TYPES[removed.type].cost
            -- Remove non-fixed node if orphaned
            local function node_used(idx)
                for _, b in ipairs(beams) do
                    if b.n1 == idx or b.n2 == idx then return true end
                end
                return false
            end
            for i = #nodes, 1, -1 do
                if not nodes[i].fixed and not node_used(i) then
                    table.remove(nodes, i)
                    -- Reindex beams
                    for _, b in ipairs(beams) do
                        if b.n1 > i then b.n1 = b.n1 - 1 end
                        if b.n2 > i then b.n2 = b.n2 - 1 end
                    end
                    if selected_node and selected_node > i then
                        selected_node = selected_node - 1
                    elseif selected_node == i then
                        selected_node = nil
                    end
                end
            end
        end

        -- Test mode
        if lurek.input.wasActionPressed("test") then
            -- Reset stress
            for _, b in ipairs(beams) do
                b.stress = 0
                b.broken = false
            end
            spawn_vehicle()
            state = STATE.TESTING
            return
        end

        -- Mouse interaction
        if lurek.input.wasActionPressed("place") then
            local mx, my = lurek.input.mouse.getPosition()

            if delete_mode then
                -- Delete beam near click
                local bi = find_beam_near(mx, my)
                if bi then
                    local removed = table.remove(beams, bi)
                    budget_spent = budget_spent - BEAM_TYPES[removed.type].cost
                end
            else
                -- Find or create node
                local ni = find_node_near(mx, my)

                if ni then
                    -- Clicked an existing node
                    if selected_node == nil then
                        selected_node = ni
                    elseif selected_node == ni then
                        selected_node = nil  -- deselect
                    else
                        -- Connect two nodes
                        local bt = BEAM_TYPES[beam_type]
                        local cost = bt.cost

                        -- Check budget
                        if budget_spent + cost <= budget_total then
                            -- Check horizontal-only constraint for road
                            local a, c = nodes[selected_node], nodes[ni]
                            local valid = true
                            if bt.horiz_only then
                                if math.abs(a.y - c.y) > 5 then valid = false end
                            end
                            if valid and not beam_exists(selected_node, ni) then
                                beams[#beams + 1] = {
                                    n1 = selected_node, n2 = ni,
                                    type = beam_type, stress = 0, broken = false,
                                }
                                budget_spent = budget_spent + cost
                                -- Sparks at midpoint
                                local sx = (a.x + c.x) / 2
                                local sy = (a.y + c.y) / 2
                                sparks_ps:emit(sx, sy, 12)
                            end
                        end
                        selected_node = nil
                    end
                else
                    -- Place new node in the gap area
                    if mx > cliff_left_x - 20 and mx < cliff_right_x + 20
                       and my > cliff_y - 80 and my < river_y - 10 then
                        nodes[#nodes + 1] = { x = mx, y = my, fixed = false }
                        if selected_node == nil then
                            selected_node = #nodes
                        else
                            -- Auto-connect to previously selected node
                            local new_idx = #nodes
                            local bt = BEAM_TYPES[beam_type]
                            if budget_spent + bt.cost <= budget_total then
                                local a, c = nodes[selected_node], nodes[new_idx]
                                local valid = true
                                if bt.horiz_only and math.abs(a.y - c.y) > 5 then valid = false end
                                if valid then
                                    beams[#beams + 1] = {
                                        n1 = selected_node, n2 = new_idx,
                                        type = beam_type, stress = 0, broken = false,
                                    }
                                    budget_spent = budget_spent + bt.cost
                                    sparks_ps:emit(mx, my, 12)
                                end
                            end
                            selected_node = new_idx
                        end
                    end
                end
            end
        end
        return
    end

    -- ── TESTING ───────────────────────────────────────────────────────
    if state == STATE.TESTING then
        apply_stress()
        simulate_vehicle(dt)
        return
    end
end

-- ===========================================================================
--  lurek.render() — world-space drawing (canyon, beams, vehicle)
-- ===========================================================================
function lurek.draw()
    cam:apply()

    -- ── Sky gradient (simple bands) ───────────────────────────────────
    if state ~= STATE.TITLE and state ~= STATE.LEVEL_SELECT then
        -- Distant hills
        lurek.render.setColor(0.35, 0.55, 0.35, 0.4)
        lurek.render.rectangle(0, cliff_y - 80, SCREEN_W, 80)

        -- Left cliff
        lurek.render.setColor(0.35, 0.28, 0.22)
        lurek.render.rectangle(0, cliff_y, cliff_left_x, SCREEN_H - cliff_y)
        -- Cliff top grass
        lurek.render.setColor(0.3, 0.6, 0.2)
        lurek.render.rectangle(0, cliff_y - 6, cliff_left_x, 8)

        -- Right cliff
        lurek.render.setColor(0.35, 0.28, 0.22)
        lurek.render.rectangle(cliff_right_x, cliff_y, SCREEN_W - cliff_right_x, SCREEN_H - cliff_y)
        lurek.render.setColor(0.3, 0.6, 0.2)
        lurek.render.rectangle(cliff_right_x, cliff_y - 6, SCREEN_W - cliff_right_x, 8)

        -- River
        lurek.render.setColor(0.15, 0.35, 0.7, 0.85)
        lurek.render.rectangle(cliff_left_x, river_y, cliff_right_x - cliff_left_x, river_h)
        -- River surface shimmer
        lurek.render.setColor(0.3, 0.5, 0.9, 0.3)
        lurek.render.rectangle(cliff_left_x, river_y, cliff_right_x - cliff_left_x, 3)

        -- ── Beams ─────────────────────────────────────────────────────
        for _, b in ipairs(beams) do
            local a, c = nodes[b.n1], nodes[b.n2]
            if a and c then
                local bt = BEAM_TYPES[b.type]
                if b.broken then
                    lurek.render.setColor(0.3, 0.2, 0.15, 0.5)
                elseif state == STATE.TESTING and b.stress > 0 then
                    local sr, sg, sb = stress_color(b.stress)
                    lurek.render.setColor(sr, sg, sb)
                else
                    lurek.render.setColor(bt.r, bt.g, bt.b)
                end
                -- Draw thick beam as multiple lines
                for offset = -bt.thick / 2, bt.thick / 2, 1 do
                    lurek.render.line(a.x, a.y + offset, c.x, c.y + offset)
                end
            end
        end

        -- ── Nodes ─────────────────────────────────────────────────────
        for i, n in ipairs(nodes) do
            if n.fixed then
                lurek.render.setColor(0.8, 0.7, 0.3)
            elseif i == selected_node then
                lurek.render.setColor(1.0, 1.0, 0.2)
            else
                lurek.render.setColor(0.9, 0.9, 0.9)
            end
            lurek.render.circle(n.x, n.y, NODE_RADIUS)
            -- Dark outline
            lurek.render.setColor(0.2, 0.2, 0.2)
            lurek.render.circle(n.x, n.y, NODE_RADIUS)
        end

        -- ── Vehicle ───────────────────────────────────────────────────
        if vehicle and (state == STATE.TESTING or state == STATE.SUCCESS) then
            -- Body
            if vehicle.weight >= 2.0 then
                lurek.render.setColor(0.7, 0.3, 0.2)  -- truck: red
            else
                lurek.render.setColor(0.3, 0.5, 0.7)  -- car: blue
            end
            lurek.render.rectangle(vehicle.x, vehicle.y, vehicle.w, vehicle.h)
            -- Wheels
            lurek.render.setColor(0.15, 0.15, 0.15)
            lurek.render.circle(vehicle.x + 6,            vehicle.y + vehicle.h, 4)
            lurek.render.circle(vehicle.x + vehicle.w - 6, vehicle.y + vehicle.h, 4)
            -- Window
            lurek.render.setColor(0.6, 0.8, 1.0, 0.7)
            lurek.render.rectangle(vehicle.x + vehicle.w * 0.55, vehicle.y + 2, vehicle.w * 0.3, vehicle.h * 0.45)
        end
    end

    cam:reset()
end

-- ===========================================================================
--  lurek.render_ui() — HUD overlay (budget, tools, stress info, menus)
-- ===========================================================================
function lurek.draw_ui()
    local dt_str = string.format("FPS: %d", lurek.timer.getFPS())
    lurek.render.setColor(1, 1, 1, 0.4)
    lurek.render.print(dt_str, SCREEN_W - 80, 4, 1.0)

    -- ── TITLE ─────────────────────────────────────────────────────────
    if state == STATE.TITLE then
        lurek.render.setColor(0.2, 0.15, 0.1)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1.0, 0.85, 0.3)
        lurek.render.print("BRIDGE BUILDER", SCREEN_W / 2 - 150, 140, 4)

        lurek.render.setColor(0.7, 0.6, 0.5)
        lurek.render.print("ENGINEER YOUR WAY", SCREEN_W / 2 - 100, 210, 2)

        -- Blinking prompt
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1)
            lurek.render.print("PRESS ENTER TO START", SCREEN_W / 2 - 120, 340, 2)
        end

        lurek.render.setColor(0.5, 0.45, 0.4)
        lurek.render.print("R — Road     S — Steel     C — Cable",  200, 430, 1.3)
        lurek.render.print("T — Test     Z — Undo      D — Delete", 200, 455, 1.3)
        lurek.render.print("Click to place nodes and connect beams", 200, 480, 1.3)
        lurek.render.print("Escape — Quit",                          200, 505, 1.3)
        return
    end

    -- ── LEVEL SELECT ──────────────────────────────────────────────────
    if state == STATE.LEVEL_SELECT then
        lurek.render.setColor(0.15, 0.12, 0.1)
        lurek.render.rectangle(0, 0, SCREEN_W, SCREEN_H)

        lurek.render.setColor(1.0, 0.85, 0.3)
        lurek.render.print("SELECT LEVEL", SCREEN_W / 2 - 100, 40, 3)

        for i, lv in ipairs(LEVELS) do
            local y = 100 + (i - 1) * 55
            if i <= levels_unlocked then
                lurek.render.setColor(0.9, 0.85, 0.7)
                lurek.render.print(string.format("[%d]  %s", i, lv.name), 180, y, 2)
                lurek.render.setColor(0.5, 0.5, 0.45)
                lurek.render.print(string.format("Gap: %dpx   Budget: %dg   Weight: %.1fx", lv.gap, lv.budget, lv.vehicle_weight), 220, y + 24, 1.1)
            else
                lurek.render.setColor(0.35, 0.3, 0.25)
                lurek.render.print(string.format("[%d]  LOCKED", i), 180, y, 2)
            end
        end

        lurek.render.setColor(0.5, 0.45, 0.4)
        lurek.render.print("Press 1-8 to select   |   Escape to quit", 180, SCREEN_H - 40, 1.2)
        return
    end

    -- ── BUILD / TEST HUD ──────────────────────────────────────────────
    local lv = LEVELS[current_level]

    -- Top bar background
    lurek.render.setColor(0.0, 0.0, 0.0, 0.6)
    lurek.render.rectangle(0, 0, SCREEN_W, 36)

    -- Level name
    lurek.render.setColor(1.0, 0.85, 0.3)
    lurek.render.print(string.format("Level %d: %s", current_level, lv.name), 10, 8, 1.5)

    -- Budget
    local remaining = budget_total - budget_spent
    if remaining < budget_total * 0.2 then
        lurek.render.setColor(1.0, 0.3, 0.3)
    elseif remaining < budget_total * 0.5 then
        lurek.render.setColor(1.0, 0.8, 0.2)
    else
        lurek.render.setColor(0.3, 1.0, 0.4)
    end
    lurek.render.print(string.format("Budget: %d / %dg", remaining, budget_total), SCREEN_W / 2 - 60, 8, 1.5)

    -- Beam count
    lurek.render.setColor(0.7, 0.7, 0.8)
    lurek.render.print(string.format("Beams: %d", #beams), SCREEN_W - 100, 8, 1.3)

    -- ── Tool palette (building mode only) ─────────────────────────────
    if state == STATE.BUILDING then
        local tool_y = SCREEN_H - 50
        lurek.render.setColor(0.0, 0.0, 0.0, 0.5)
        lurek.render.rectangle(0, tool_y - 5, SCREEN_W, 55)

        local tools = { "road", "steel", "cable" }
        for idx, t in ipairs(tools) do
            local tx = 20 + (idx - 1) * 180
            local bt = BEAM_TYPES[t]
            if beam_type == t and not delete_mode then
                lurek.render.setColor(1.0, 1.0, 0.3)
                lurek.render.rectangle(tx - 4, tool_y - 2, 160, 38)
            end
            lurek.render.setColor(bt.r, bt.g, bt.b)
            lurek.render.rectangle(tx, tool_y + 10, 40, bt.thick * 2)
            lurek.render.setColor(0.9, 0.9, 0.9)
            lurek.render.print(string.format("%s (%s) %dg", bt.label, string.upper(string.sub(t, 1, 1)), bt.cost), tx + 50, tool_y + 5, 1.2)
        end

        -- Delete mode indicator
        if delete_mode then
            lurek.render.setColor(1.0, 0.3, 0.2)
            lurek.render.print("DELETE MODE (D)", SCREEN_W - 160, tool_y + 10, 1.4)
        end

        -- Hint
        lurek.render.setColor(0.6, 0.6, 0.65)
        lurek.render.print("T = Test   Z = Undo   Esc = Back", SCREEN_W / 2 - 120, tool_y + 32, 1.0)
    end

    -- ── Testing progress bar ──────────────────────────────────────────
    if state == STATE.TESTING and vehicle then
        local bar_w = 200
        local bar_x = SCREEN_W / 2 - bar_w / 2
        local bar_y = SCREEN_H - 24
        lurek.render.setColor(0.2, 0.2, 0.2, 0.6)
        lurek.render.rectangle(bar_x, bar_y, bar_w, 12)
        local prog = clamp(vehicle.progress, 0, 1)
        lurek.render.setColor(0.3, 0.8, 0.4)
        lurek.render.rectangle(bar_x, bar_y, bar_w * prog, 12)
        lurek.render.setColor(1, 1, 1)
        lurek.render.print("TESTING...", bar_x + bar_w / 2 - 30, bar_y - 16, 1.2)
    end

    -- ── SUCCESS overlay ───────────────────────────────────────────────
    if state == STATE.SUCCESS then
        lurek.render.setColor(0.0, 0.0, 0.0, 0.5)
        lurek.render.rectangle(0, SCREEN_H / 2 - 80, SCREEN_W, 160)

        lurek.render.setColor(0.3, 1.0, 0.4)
        lurek.render.print("SUCCESS!", SCREEN_W / 2 - 70, SCREEN_H / 2 - 60, 3.5)

        lurek.render.setColor(1.0, 0.95, 0.7)
        lurek.render.print(result_msg, SCREEN_W / 2 - 180, SCREEN_H / 2 + 5, 1.3)

        lurek.render.setColor(1.0, 0.85, 0.3)
        lurek.render.print(string.format("Score: %d", math.floor(score_display.value)), SCREEN_W / 2 - 50, SCREEN_H / 2 + 35, 2)

        lurek.render.setColor(0.6, 0.6, 0.65)
        lurek.render.print("Press Enter to continue", SCREEN_W / 2 - 90, SCREEN_H / 2 + 65, 1.2)
    end

    -- ── FAIL overlay ──────────────────────────────────────────────────
    if state == STATE.FAIL then
        lurek.render.setColor(0.0, 0.0, 0.0, 0.5)
        lurek.render.rectangle(0, SCREEN_H / 2 - 60, SCREEN_W, 120)

        lurek.render.setColor(1.0, 0.3, 0.2)
        lurek.render.print("BRIDGE FAILED!", SCREEN_W / 2 - 110, SCREEN_H / 2 - 45, 3.5)

        lurek.render.setColor(0.9, 0.7, 0.6)
        lurek.render.print(result_msg, SCREEN_W / 2 - 140, SCREEN_H / 2 + 10, 1.3)

        lurek.render.setColor(0.6, 0.6, 0.65)
        lurek.render.print("Press Enter to try again", SCREEN_W / 2 - 95, SCREEN_H / 2 + 40, 1.2)
    end
end
