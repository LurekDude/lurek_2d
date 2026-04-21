-- Tower Sim — SimTower-style vertical building simulation
-- Category: simulation

local state = "TITLE"
local gold = 100
local display_gold = 100
local floors = {}
local elevators = 1
local tenants = {}
local satisfaction = 50
local display_satisfaction = 50
local revenue_timer = 0
local REVENUE_INTERVAL = 15
local FLOOR_HEIGHT = 80
local FLOOR_WIDTH = 800
local MAX_FLOORS = 10
local WIN_GOLD = 2000
local WIN_FLOORS = 8
local selected_room = nil
local build_mode = false
local camera_y = 0
local target_camera_y = 0
local build_anim = {}
local dt = 0
local frame_count = 0

-- Room definitions: cost, income, description
local ROOM_TYPES = {
    office     = { key = "o", cost = 50,  income = 5,  color = {0.3, 0.5, 0.8}, icon = "OFF", label = "Office" },
    apartment  = { key = "a", cost = 40,  income = 3,  color = {0.2, 0.7, 0.3}, icon = "APT", label = "Apartment", tenants = 4 },
    shop       = { key = "s", cost = 60,  income = 8,  color = {0.9, 0.6, 0.2}, icon = "SHP", label = "Shop", max_floor = 2 },
    restaurant = { key = "r", cost = 80,  income = 10, color = {0.8, 0.2, 0.3}, icon = "RST", label = "Restaurant" },
    gym        = { key = "g", cost = 70,  income = 0,  color = {0.6, 0.2, 0.8}, icon = "GYM", label = "Gym" },
}

local SLOTS_PER_FLOOR = 5
local SLOT_WIDTH = 140
local ELEVATOR_WIDTH = 60
local ELEVATOR_X = FLOOR_WIDTH - ELEVATOR_WIDTH - 10
local SLOT_START_X = 20

-- Particles
local particles = {}
local sparkles = {}
local elev_glow = {}

-- Elevator state
local elev_people_queue = {}
local elev_pos_y = 0
local elev_target_y = 0

-- Tweens
local tweens = {}

local function add_tween(target, field, to, duration)
    table.insert(tweens, { target = target, field = field, from = target[field], to = to, duration = duration, elapsed = 0 })
end

local function update_tweens(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = math.min(tw.elapsed / tw.duration, 1.0)
        local ease = t < 0.5 and 2 * t * t or 1 - (-2 * t + 2) * (-2 * t + 2) / 2
        tw.target[tw.field] = tw.from + (tw.to - tw.from) * ease
        if t >= 1.0 then
            tw.target[tw.field] = tw.to
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end
end

local function spawn_dust(x, y)
    for _ = 1, 8 do
        table.insert(particles, {
            x = x + math.random(-30, 30), y = y + math.random(-10, 10),
            vx = math.random(-40, 40), vy = math.random(-60, -20),
            life = 0.6 + math.random() * 0.4,
            max_life = 1.0, r = 0.7, g = 0.65, b = 0.5
        })
    end
end

local function spawn_sparkle(x, y)
    for _ = 1, 5 do
        table.insert(sparkles, {
            x = x + math.random(-20, 20), y = y + math.random(-10, 10),
            vy = math.random(-50, -20),
            life = 0.8 + math.random() * 0.4,
            max_life = 1.2, r = 1.0, g = 0.9, b = 0.2
        })
    end
end

local function spawn_elev_glow(y)
    table.insert(elev_glow, {
        x = ELEVATOR_X + ELEVATOR_WIDTH / 2, y = y,
        life = 0.5, max_life = 0.5, radius = 10
    })
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 80 * dt
        p.life = p.life - dt
        if p.life <= 0 then table.remove(particles, i) else i = i + 1 end
    end
    i = 1
    while i <= #sparkles do
        local s = sparkles[i]
        s.y = s.y + s.vy * dt
        s.life = s.life - dt
        if s.life <= 0 then table.remove(sparkles, i) else i = i + 1 end
    end
    i = 1
    while i <= #elev_glow do
        local g = elev_glow[i]
        g.life = g.life - dt
        g.radius = g.radius + 40 * dt
        if g.life <= 0 then table.remove(elev_glow, i) else i = i + 1 end
    end
end

local function init_tower()
    floors = {}
    local lobby = { index = 0, rooms = {}, built = true, build_progress = 1.0 }
    lobby.rooms[1] = { type = "lobby", label = "LOBBY", color = {0.5, 0.5, 0.5} }
    table.insert(floors, lobby)
    gold = 100
    display_gold = 100
    elevators = 1
    tenants = {}
    satisfaction = 50
    display_satisfaction = 50
    revenue_timer = 0
    selected_room = nil
    build_mode = false
    particles = {}
    sparkles = {}
    elev_glow = {}
    tweens = {}
    build_anim = {}
    camera_y = 0
    target_camera_y = 0
    elev_pos_y = 0
    elev_target_y = 0
    elev_people_queue = {}
end

local function floor_count()
    return #floors
end

local function top_floor_index()
    if #floors == 0 then return -1 end
    return floors[#floors].index
end

local function get_floor_y(floor_idx)
    return 500 - floor_idx * FLOOR_HEIGHT
end

local function elevator_serves(floor_idx)
    local served = elevators * 2
    return floor_idx <= served
end

local function count_rooms_of_type(rtype)
    local c = 0
    for _, fl in ipairs(floors) do
        for _, rm in pairs(fl.rooms) do
            if rm.type == rtype then c = c + 1 end
        end
    end
    return c
end

local function count_tenants()
    local t = 0
    for _, fl in ipairs(floors) do
        for _, rm in pairs(fl.rooms) do
            if rm.type == "apartment" then t = t + (rm.tenants_in or 0) end
        end
    end
    return t
end

local function has_restaurant_nearby(floor_idx)
    for _, fl in ipairs(floors) do
        if math.abs(fl.index - floor_idx) <= 1 then
            for _, rm in pairs(fl.rooms) do
                if rm.type == "restaurant" then return true end
            end
        end
    end
    return false
end

local function has_gym_on_floor(floor_idx)
    for _, fl in ipairs(floors) do
        if fl.index == floor_idx then
            for _, rm in pairs(fl.rooms) do
                if rm.type == "gym" then return true end
            end
        end
    end
    return false
end

local function calc_satisfaction()
    local base = 50
    local penalty = 0
    local bonus = 0
    for _, fl in ipairs(floors) do
        if not elevator_serves(fl.index) and fl.index > 0 then
            penalty = penalty + 5
        end
        if has_restaurant_nearby(fl.index) then bonus = bonus + 10 end
        if has_gym_on_floor(fl.index) then bonus = bonus + 5 end
    end
    local val = math.max(0, math.min(100, base - penalty + bonus))
    if val ~= satisfaction then
        add_tween({ ref = "satisfaction" }, "ref", val, 0.5)
    end
    satisfaction = val
end

local function collect_revenue()
    local total = 0
    for _, fl in ipairs(floors) do
        for _, rm in pairs(fl.rooms) do
            local def = ROOM_TYPES[rm.type]
            if def then
                total = total + def.income
                spawn_sparkle(SLOT_START_X + 70, get_floor_y(fl.index) + 40)
            end
        end
    end
    total = total + count_tenants()
    local sat_mult = satisfaction / 100
    total = math.floor(total * (0.5 + sat_mult * 0.5))
    gold = gold + total
    add_tween({ ref = "display_gold" }, "ref", gold, 0.8)
    display_gold = gold
end

local function add_floor()
    if #floors >= MAX_FLOORS then return false end
    if gold < 30 then return false end
    gold = gold - 30
    display_gold = gold
    local idx = top_floor_index() + 1
    local fl = { index = idx, rooms = {}, built = true, build_progress = 0.0 }
    table.insert(floors, fl)
    build_anim[idx] = { progress = 0.0 }
    add_tween(build_anim[idx], "progress", 1.0, 0.6)
    spawn_dust(FLOOR_WIDTH / 2, get_floor_y(idx) + FLOOR_HEIGHT / 2)
    target_camera_y = math.max(0, (idx - 4) * FLOOR_HEIGHT)
    return true
end

local function place_room(floor_idx, slot, rtype)
    local def = ROOM_TYPES[rtype]
    if not def then return false end
    if gold < def.cost then return false end
    if def.max_floor and floor_idx > def.max_floor then return false end

    local fl = nil
    for _, f in ipairs(floors) do
        if f.index == floor_idx then fl = f; break end
    end
    if not fl then return false end
    if fl.rooms[slot] then return false end

    gold = gold - def.cost
    display_gold = gold
    local rm = { type = rtype, label = def.icon, color = def.color }
    if rtype == "apartment" then
        rm.tenants_in = 0
        rm.max_tenants = def.tenants
    end
    fl.rooms[slot] = rm
    spawn_dust(SLOT_START_X + (slot - 1) * SLOT_WIDTH + 70, get_floor_y(floor_idx) + 40)
    calc_satisfaction()
    return true
end

local function move_tenants_in()
    for _, fl in ipairs(floors) do
        for _, rm in pairs(fl.rooms) do
            if rm.type == "apartment" and rm.tenants_in < rm.max_tenants then
                if satisfaction > 30 then
                    rm.tenants_in = math.min(rm.tenants_in + 1, rm.max_tenants)
                end
            end
        end
    end
end

local function buy_elevator()
    if gold < 100 then return false end
    gold = gold - 100
    display_gold = gold
    elevators = elevators + 1
    spawn_elev_glow(300)
    calc_satisfaction()
    return true
end

local function check_victory()
    if floor_count() >= WIN_FLOORS and gold >= WIN_GOLD then
        state = "VICTORY"
    end
end

local function get_slot_from_x(mx)
    local rel = mx - SLOT_START_X
    if rel < 0 or rel >= SLOTS_PER_FLOOR * SLOT_WIDTH then return nil end
    return math.floor(rel / SLOT_WIDTH) + 1
end

local function get_floor_from_y(my)
    local world_y = my + camera_y
    for _, fl in ipairs(floors) do
        local fy = get_floor_y(fl.index)
        if world_y >= fy and world_y < fy + FLOOR_HEIGHT then
            return fl.index
        end
    end
    return nil
end

-- === Engine callbacks ===

lurek.init(function()
    lurek.window.setTitle("Tower Sim — Lurek2D")
    lurek.render.setBackgroundColor(0.6, 0.8, 1.0)

    lurek.input.bind("floor", "f")
    lurek.input.bind("office", "o")
    lurek.input.bind("apartment", "a")
    lurek.input.bind("shop", "s")
    lurek.input.bind("restaurant", "r")
    lurek.input.bind("gym", "g")
    lurek.input.bind("elevator", "e")
    lurek.input.bind("place", "mouse1")
    lurek.input.bind("quit", "escape")
end)

lurek.ready(function()
    init_tower()
end)

lurek.process(function(delta)
    dt = delta
    frame_count = frame_count + 1
    update_tweens(dt)
    update_particles(dt)

    if lurek.input.isActionJustPressed("quit") then
        if state == "PLAYING" then
            state = "TITLE"
        else
            lurek.event.quit()
        end
        return
    end

    if state == "TITLE" then
        if lurek.input.isActionJustPressed("place") then
            state = "PLAYING"
            init_tower()
        end
        return
    end

    if state == "VICTORY" then
        if lurek.input.isActionJustPressed("place") then
            state = "TITLE"
        end
        return
    end

    -- PLAYING state
    revenue_timer = revenue_timer + dt
    if revenue_timer >= REVENUE_INTERVAL then
        revenue_timer = revenue_timer - REVENUE_INTERVAL
        collect_revenue()
        move_tenants_in()
        check_victory()
    end

    -- Camera smooth follow
    camera_y = camera_y + (target_camera_y - camera_y) * math.min(1.0, 4.0 * dt)

    -- Input: select build actions
    if lurek.input.isActionJustPressed("floor") then
        build_mode = true
        selected_room = nil
    elseif lurek.input.isActionJustPressed("office") then
        selected_room = "office"; build_mode = false
    elseif lurek.input.isActionJustPressed("apartment") then
        selected_room = "apartment"; build_mode = false
    elseif lurek.input.isActionJustPressed("shop") then
        selected_room = "shop"; build_mode = false
    elseif lurek.input.isActionJustPressed("restaurant") then
        selected_room = "restaurant"; build_mode = false
    elseif lurek.input.isActionJustPressed("gym") then
        selected_room = "gym"; build_mode = false
    elseif lurek.input.isActionJustPressed("elevator") then
        buy_elevator()
        build_mode = false
        selected_room = nil
    end

    -- Place with mouse
    if lurek.input.isActionJustPressed("place") then
        local mx, my = lurek.input.getMousePosition()
        if build_mode then
            add_floor()
            build_mode = false
        elseif selected_room then
            local fi = get_floor_from_y(my)
            local sl = get_slot_from_x(mx)
            if fi and sl then
                place_room(fi, sl, selected_room)
            end
        end
    end

    -- Elevator movement
    if #elev_people_queue > 0 then
        local target = elev_people_queue[1]
        local ty = get_floor_y(target) + FLOOR_HEIGHT / 2
        elev_target_y = ty
        elev_pos_y = elev_pos_y + (elev_target_y - elev_pos_y) * math.min(1.0, 3.0 * dt)
        if math.abs(elev_pos_y - elev_target_y) < 2 then
            spawn_elev_glow(elev_pos_y)
            table.remove(elev_people_queue, 1)
        end
    end

    -- Update build animations
    for idx, anim in pairs(build_anim) do
        if anim.progress >= 1.0 then
            build_anim[idx] = nil
        end
    end
end)

lurek.render(function()
    if state ~= "PLAYING" then return end

    -- Draw sky gradient (simple two-band)
    lurek.render.drawRect(0, -camera_y, 800, 300, 0.4, 0.6, 0.9, 1.0)
    lurek.render.drawRect(0, 300 - camera_y, 800, 300, 0.6, 0.8, 1.0, 1.0)

    -- Draw ground
    lurek.render.drawRect(0, 560 - camera_y, 800, 40, 0.3, 0.6, 0.2, 1.0)

    -- Draw floors
    for _, fl in ipairs(floors) do
        local fy = get_floor_y(fl.index) - camera_y
        local anim = build_anim[fl.index]
        local scale = 1.0
        if anim then scale = anim.progress end

        -- Floor slab
        local sw = FLOOR_WIDTH * scale
        lurek.render.drawRect((FLOOR_WIDTH - sw) / 2, fy, sw, FLOOR_HEIGHT, 0.85, 0.82, 0.78, 1.0)
        lurek.render.drawRect((FLOOR_WIDTH - sw) / 2, fy, sw, 3, 0.5, 0.5, 0.5, 1.0)

        -- Rooms
        if scale >= 1.0 then
            for slot = 1, SLOTS_PER_FLOOR do
                local rm = fl.rooms[slot]
                local rx = SLOT_START_X + (slot - 1) * SLOT_WIDTH
                local rw = SLOT_WIDTH - 8
                local rh = FLOOR_HEIGHT - 16
                local ry = fy + 8

                if rm and rm.type ~= "lobby" then
                    local c = rm.color or {0.5, 0.5, 0.5}
                    lurek.render.drawRect(rx, ry, rw, rh, c[1], c[2], c[3], 0.9)
                    lurek.render.drawRect(rx, ry, rw, 2, c[1] * 0.7, c[2] * 0.7, c[3] * 0.7, 1.0)
                    lurek.render.drawText(rm.label or "?", rx + 4, ry + 4, 14)

                    -- Tenant dots for apartments
                    if rm.type == "apartment" and rm.tenants_in then
                        for t = 1, rm.tenants_in do
                            local tx = rx + 10 + (t - 1) * 12
                            local ty2 = ry + rh - 14
                            lurek.render.drawCircle(tx, ty2, 4, 0.1, 0.1, 0.8, 1.0)
                        end
                    end
                elseif rm and rm.type == "lobby" then
                    lurek.render.drawRect(rx, ry, rw * 3, rh, 0.5, 0.5, 0.5, 0.7)
                    lurek.render.drawText("LOBBY", rx + 20, ry + 20, 20)
                elseif not rm then
                    -- Empty slot outline
                    lurek.render.drawRect(rx, ry, rw, rh, 0.9, 0.9, 0.9, 0.3)
                end
            end
        end

        -- Floor number
        lurek.render.drawText(tostring(fl.index), 4, fy + FLOOR_HEIGHT / 2 - 7, 14)
    end

    -- Draw elevator shaft
    local shaft_top = get_floor_y(top_floor_index()) - camera_y
    local shaft_bottom = get_floor_y(0) + FLOOR_HEIGHT - camera_y
    lurek.render.drawRect(ELEVATOR_X, shaft_top, ELEVATOR_WIDTH, shaft_bottom - shaft_top, 0.3, 0.3, 0.35, 0.8)
    -- Elevator car
    local ecy = elev_pos_y - camera_y
    if ecy == 0 then ecy = shaft_bottom - 30 end
    lurek.render.drawRect(ELEVATOR_X + 5, ecy - 15, ELEVATOR_WIDTH - 10, 30, 0.8, 0.75, 0.2, 1.0)
    lurek.render.drawText("E:" .. elevators, ELEVATOR_X + 8, ecy - 10, 12)

    -- Particles (dust)
    for _, p in ipairs(particles) do
        local alpha = p.life / p.max_life
        lurek.render.drawCircle(p.x, p.y - camera_y, 3, p.r, p.g, p.b, alpha)
    end

    -- Sparkles (revenue)
    for _, s in ipairs(sparkles) do
        local alpha = s.life / s.max_life
        local sz = 2 + (1 - alpha) * 4
        lurek.render.drawCircle(s.x, s.y - camera_y, sz, s.r, s.g, s.b, alpha)
    end

    -- Elevator glow
    for _, g in ipairs(elev_glow) do
        local alpha = g.life / g.max_life * 0.5
        lurek.render.drawCircle(g.x, g.y - camera_y, g.radius, 1.0, 0.9, 0.3, alpha)
    end
end)

lurek.render_ui(function()
    if state == "TITLE" then
        lurek.render.drawRect(0, 0, 800, 600, 0.1, 0.1, 0.2, 1.0)
        lurek.render.drawText("TOWER SIM", 240, 160, 48)
        lurek.render.drawText("BUILD HIGHER", 270, 240, 28)
        lurek.render.drawText("Click to start", 310, 350, 18)
        lurek.render.drawText("[F] Floor  [O] Office  [A] Apt  [S] Shop", 140, 420, 14)
        lurek.render.drawText("[R] Restaurant  [G] Gym  [E] Elevator", 160, 445, 14)
        lurek.render.drawText("[ESC] Quit", 350, 480, 14)
        return
    end

    if state == "VICTORY" then
        lurek.render.drawRect(0, 0, 800, 600, 0.05, 0.15, 0.05, 0.85)
        lurek.render.drawText("VICTORY!", 280, 180, 48)
        lurek.render.drawText("Tower complete: " .. floor_count() .. " floors", 240, 270, 22)
        lurek.render.drawText("Final gold: " .. math.floor(gold), 280, 310, 22)
        lurek.render.drawText("Click to return to title", 270, 400, 18)
        return
    end

    -- HUD
    lurek.render.drawRect(0, 0, 800, 36, 0.1, 0.1, 0.15, 0.85)
    lurek.render.drawText("Gold: " .. math.floor(display_gold), 10, 8, 18)
    lurek.render.drawText("Floors: " .. floor_count() .. "/" .. MAX_FLOORS, 200, 8, 18)
    lurek.render.drawText("Tenants: " .. count_tenants(), 380, 8, 18)
    lurek.render.drawText("Elevators: " .. elevators, 530, 8, 18)

    -- Satisfaction bar
    local sat_pct = display_satisfaction / 100
    local bar_w = 120
    lurek.render.drawRect(660, 8, bar_w, 18, 0.3, 0.3, 0.3, 1.0)
    local sr = satisfaction < 40 and 0.8 or 0.2
    local sg = satisfaction >= 40 and 0.7 or 0.3
    lurek.render.drawRect(660, 8, bar_w * sat_pct, 18, sr, sg, 0.2, 1.0)
    lurek.render.drawText("Sat:" .. math.floor(satisfaction) .. "%", 665, 9, 13)

    -- Revenue timer bar
    local rev_pct = revenue_timer / REVENUE_INTERVAL
    lurek.render.drawRect(0, 36, 800 * rev_pct, 3, 1.0, 0.85, 0.2, 0.7)

    -- Selected mode indicator
    local mode_text = ""
    if build_mode then
        mode_text = "MODE: Add Floor (click anywhere)"
    elseif selected_room then
        local def = ROOM_TYPES[selected_room]
        mode_text = "MODE: Place " .. def.label .. " (" .. def.cost .. "g) — click a slot"
    else
        mode_text = "[F]loor [O]ffice [A]pt [S]hop [R]est [G]ym [E]levator"
    end
    lurek.render.drawText(mode_text, 10, 580, 14)

    -- FPS
    lurek.render.drawText("FPS: " .. lurek.timer.getFPS(), 730, 580, 12)
end)
