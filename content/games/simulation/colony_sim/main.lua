-- ============================================================
-- Colony Sim — Lurek2D
-- Category: simulation
-- Colony management: build, assign jobs, gather, defend
-- ============================================================

-- ── Constants ───────────────────────────────────────────────
local TILE_SIZE    = 32
local MAP_COLS     = 25
local MAP_ROWS     = 18
local MAP_W        = MAP_COLS * TILE_SIZE
local MAP_H        = MAP_ROWS * TILE_SIZE
local HUD_HEIGHT   = 24
local CYCLE_TIME   = 10      -- seconds per production cycle
local RAID_TIME    = 60      -- seconds between raids
local WIN_POP      = 20

-- Terrain types
local T_GRASS  = 1
local T_WATER  = 2
local T_ROCK   = 3
local T_FOREST = 4

-- Building types
local B_HOUSE    = "house"
local B_FARM     = "farm"
local B_MINE     = "mine"
local B_BARRACKS = "barracks"

-- Job types
local J_IDLE    = "I"
local J_BUILDER = "B"
local J_FARMER  = "F"
local J_MINER   = "M"
local J_GUARD   = "G"

-- Job colors
local JOB_COLORS = {
    [J_IDLE]    = {0.6, 0.6, 0.6},
    [J_BUILDER] = {0.9, 0.7, 0.2},
    [J_FARMER]  = {0.3, 0.8, 0.3},
    [J_MINER]   = {0.5, 0.5, 0.8},
    [J_GUARD]   = {0.9, 0.2, 0.2},
}

-- Terrain colors
local TERRAIN_COLORS = {
    [T_GRASS]  = {0.25, 0.55, 0.20},
    [T_WATER]  = {0.15, 0.30, 0.65},
    [T_ROCK]   = {0.45, 0.42, 0.40},
    [T_FOREST] = {0.10, 0.40, 0.15},
}

-- Building costs: {wood, stone}
local BUILD_COSTS = {
    [B_HOUSE]    = {wood = 10, stone = 0},
    [B_FARM]     = {wood = 5,  stone = 0},
    [B_MINE]     = {wood = 5,  stone = 5},
    [B_BARRACKS] = {wood = 15, stone = 10},
}

-- Building colors
local BUILD_COLORS = {
    [B_HOUSE]    = {0.7, 0.5, 0.3},
    [B_FARM]     = {0.8, 0.8, 0.2},
    [B_MINE]     = {0.5, 0.5, 0.6},
    [B_BARRACKS] = {0.8, 0.2, 0.2},
}

-- ── State ───────────────────────────────────────────────────
local state       = "TITLE"
local map         = {}          -- map[row][col] = terrain
local buildings   = {}          -- {col, row, type}
local colonists   = {}          -- {x, y, job, selected, anim_t}
local particles   = {}          -- {x, y, vx, vy, life, r, g, b, a}
local resources   = {wood = 30, stone = 15, food = 20}
local res_display = {wood = 30, stone = 15, food = 20}  -- tweened
local max_pop     = 5
local speed_mult  = 1
local cycle_timer = 0
local raid_timer  = 0
local selected_colonist = nil
local build_mode  = nil         -- nil or building type
local message     = ""
local message_timer = 0
local game_time   = 0

-- ── Map Generation ──────────────────────────────────────────
local function generate_map()
    math.randomseed(os.time())
    map = {}
    for r = 1, MAP_ROWS do
        map[r] = {}
        for c = 1, MAP_COLS do
            local rnd = math.random(100)
            if rnd <= 10 then
                map[r][c] = T_WATER
            elseif rnd <= 20 then
                map[r][c] = T_ROCK
            elseif rnd <= 35 then
                map[r][c] = T_FOREST
            else
                map[r][c] = T_GRASS
            end
        end
    end
    -- Clear center area for starting colony
    for r = 7, 11 do
        for c = 10, 15 do
            map[r][c] = T_GRASS
        end
    end
end

-- ── Colonist Helpers ────────────────────────────────────────
local function spawn_colonist(x, y)
    table.insert(colonists, {
        x = x, y = y,
        job = J_IDLE,
        selected = false,
        anim_t = 0,
        target_x = nil, target_y = nil,
    })
end

local function init_colonists()
    colonists = {}
    for i = 1, 5 do
        local cx = (11 + i) * TILE_SIZE + TILE_SIZE * 0.5
        local cy = 9 * TILE_SIZE + TILE_SIZE * 0.5
        spawn_colonist(cx, cy)
    end
end

-- ── Building Helpers ────────────────────────────────────────
local function get_building_at(col, row)
    for _, b in ipairs(buildings) do
        if b.col == col and b.row == row then return b end
    end
    return nil
end

local function count_buildings(btype)
    local n = 0
    for _, b in ipairs(buildings) do
        if b.type == btype then n = n + 1 end
    end
    return n
end

local function count_job(job)
    local n = 0
    for _, c in ipairs(colonists) do
        if c.job == job then n = n + 1 end
    end
    return n
end

local function can_afford(btype)
    local cost = BUILD_COSTS[btype]
    return resources.wood >= cost.wood and resources.stone >= cost.stone
end

local function pay_cost(btype)
    local cost = BUILD_COSTS[btype]
    resources.wood  = resources.wood  - cost.wood
    resources.stone = resources.stone - cost.stone
end

local function show_message(msg)
    message = msg
    message_timer = 3
end

-- ── Particle System ─────────────────────────────────────────
local function emit_particles(x, y, count, r, g, b)
    for _ = 1, count do
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * 80,
            vy = (math.random() - 0.5) * 80 - 30,
            life = 0.6 + math.random() * 0.6,
            r = r, g = g, b = b, a = 1.0,
        })
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 60 * dt
        p.life = p.life - dt
        p.a = math.max(0, p.life / 1.2)
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ── Resource Tween ──────────────────────────────────────────
local function tween_resources(dt)
    local speed = 30
    for k, v in pairs(resources) do
        local d = v - res_display[k]
        if math.abs(d) < 0.5 then
            res_display[k] = v
        else
            res_display[k] = res_display[k] + d * math.min(1, speed * dt)
        end
    end
end

-- ── Production Cycle ────────────────────────────────────────
local function run_production_cycle()
    -- Lumberjacks: each builder near forest produces 2 wood
    local builders = count_job(J_BUILDER)
    local forest_count = 0
    for r = 1, MAP_ROWS do
        for c = 1, MAP_COLS do
            if map[r][c] == T_FOREST then forest_count = forest_count + 1 end
        end
    end
    local wood_gain = math.min(builders * 2, forest_count)
    resources.wood = resources.wood + wood_gain

    -- Farmers: each farmer with a farm produces 2 food
    local farmers = count_job(J_FARMER)
    local farms   = count_buildings(B_FARM)
    local food_gain = math.min(farmers, farms) * 2
    resources.food = resources.food + food_gain

    -- Miners: each miner with a mine produces 3 stone
    local miners = count_job(J_MINER)
    local mines  = count_buildings(B_MINE)
    local stone_gain = math.min(miners, mines) * 3
    resources.stone = resources.stone + stone_gain

    -- Food consumption
    local pop = #colonists
    resources.food = resources.food - pop
    if resources.food < 0 then
        resources.food = 0
        -- Starvation: lose a colonist
        if #colonists > 0 then
            local idx = math.random(#colonists)
            local c = colonists[idx]
            emit_particles(c.x, c.y, 8, 0.8, 0.2, 0.2)
            table.remove(colonists, idx)
            selected_colonist = nil
            show_message("A colonist left due to starvation!")
        end
    end

    -- Gather sparkle at resource buildings
    for _, b in ipairs(buildings) do
        if b.type == B_FARM then
            emit_particles(b.col * TILE_SIZE + 16, b.row * TILE_SIZE + 16, 4, 0.4, 0.9, 0.3)
        elseif b.type == B_MINE then
            emit_particles(b.col * TILE_SIZE + 16, b.row * TILE_SIZE + 16, 4, 0.5, 0.5, 0.8)
        end
    end

    -- New colonist arrival
    local houses = count_buildings(B_HOUSE)
    local max_pop_now = 5 + houses * 2
    max_pop = max_pop_now
    if #colonists < max_pop_now and resources.food >= #colonists + 1 then
        local cx = (10 + math.random(5)) * TILE_SIZE + 16
        local cy = (7 + math.random(4)) * TILE_SIZE + 16
        spawn_colonist(cx, cy)
        emit_particles(cx, cy, 12, 0.9, 0.9, 0.3)
        show_message("A new colonist arrived!")
    end

    show_message(string.format("+%d wood, +%d food, +%d stone", wood_gain, food_gain, stone_gain))
end

-- ── Raid Event ──────────────────────────────────────────────
local function run_raid()
    local guards = count_job(J_GUARD)
    local barracks = count_buildings(B_BARRACKS)
    local defense = guards + barracks

    -- Flash warning particles
    for _ = 1, 30 do
        local px = math.random(MAP_W)
        local py = math.random(MAP_H)
        emit_particles(px, py, 3, 1.0, 0.1, 0.1)
    end

    if defense >= 2 then
        show_message("Raiders repelled! Your guards held the line.")
    elseif defense == 1 then
        local loss_wood  = math.min(resources.wood, 5)
        local loss_stone = math.min(resources.stone, 3)
        resources.wood  = resources.wood  - loss_wood
        resources.stone = resources.stone - loss_stone
        show_message("Raiders broke through partially! Lost some resources.")
    else
        local loss_wood  = math.min(resources.wood, 15)
        local loss_stone = math.min(resources.stone, 10)
        local loss_food  = math.min(resources.food, 10)
        resources.wood  = resources.wood  - loss_wood
        resources.stone = resources.stone - loss_stone
        resources.food  = resources.food  - loss_food
        show_message("Raiders pillaged your colony! Heavy losses!")
    end
end

-- ── Colonist Movement ───────────────────────────────────────
local function update_colonists(dt)
    for _, c in ipairs(colonists) do
        c.anim_t = c.anim_t + dt * 2

        -- Wander toward work targets
        if not c.target_x or math.abs(c.x - c.target_x) < 4 then
            -- Pick a random nearby tile
            local tc = math.random(MAP_COLS)
            local tr = math.random(MAP_ROWS)
            c.target_x = tc * TILE_SIZE + 16
            c.target_y = tr * TILE_SIZE + 16
        end
        local dx = (c.target_x - c.x)
        local dy = (c.target_y - c.y)
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 2 then
            local move_speed = 40
            c.x = c.x + (dx / dist) * move_speed * dt
            c.y = c.y + (dy / dist) * move_speed * dt
        end

        -- Clamp to map
        c.x = math.max(8, math.min(MAP_W - 8, c.x))
        c.y = math.max(8, math.min(MAP_H - 8, c.y))
    end
end

-- ── Place Building ──────────────────────────────────────────
local function try_place_building(mx, my, btype)
    local col = math.floor(mx / TILE_SIZE) + 1
    local row = math.floor(my / TILE_SIZE) + 1
    if col < 1 or col > MAP_COLS or row < 1 or row > MAP_ROWS then return end

    local terrain = map[row][col]
    if terrain == T_WATER then
        show_message("Cannot build on water!")
        return
    end
    if get_building_at(col, row) then
        show_message("Tile already occupied!")
        return
    end
    if not can_afford(btype) then
        show_message("Not enough resources!")
        return
    end

    pay_cost(btype)
    table.insert(buildings, {col = col, row = row, type = btype})
    emit_particles(col * TILE_SIZE + 16, row * TILE_SIZE + 16, 10, 0.8, 0.7, 0.5)
    build_mode = nil

    if btype == B_HOUSE then
        max_pop = 5 + count_buildings(B_HOUSE) * 2
    end
    show_message("Built " .. btype .. "!")
end

-- ── Select Colonist ─────────────────────────────────────────
local function try_select_colonist(mx, my)
    selected_colonist = nil
    for i, c in ipairs(colonists) do
        local dx = mx - c.x
        local dy = my - c.y
        if dx * dx + dy * dy < 16 * 16 then
            selected_colonist = i
            c.selected = true
            show_message("Colonist selected — press B/F/M/G to assign job")
            return
        end
    end
end

-- ── Init ────────────────────────────────────────────────────

-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Colony Sim — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.15, 0.1)

    lurek.input.bind("build_house",    "h")
    lurek.input.bind("build_farm",     "a")
    lurek.input.bind("build_mine",     "n")
    lurek.input.bind("build_barracks", "k")
    lurek.input.bind("assign_builder", "b")
    lurek.input.bind("assign_farmer",  "f")
    lurek.input.bind("assign_miner",   "m")
    lurek.input.bind("assign_guard",   "g")
    lurek.input.bind("speed_1",        "1")
    lurek.input.bind("speed_2",        "2")
    lurek.input.bind("speed_3",        "3")
    lurek.input.bind("select",         "mouse1")
    lurek.input.bind("quit",           "escape")
end

local function _ready_setup()
    generate_map()
    init_colonists()
end

-- ── Process ─────────────────────────────────────────────────
function lurek.process(dt)
    dt = dt * speed_mult

    if state == "TITLE" then
        if lurek.input.wasActionPressed("select") then
            state = "PLAYING"
        end
        if lurek.input.wasActionPressed("quit") then
            lurek.event.quit()
        end
        return
    end

    if state == "VICTORY" or state == "GAME_OVER" then
        if lurek.input.wasActionPressed("select") then
            -- Restart
            state = "PLAYING"
            resources = {wood = 30, stone = 15, food = 20}
            res_display = {wood = 30, stone = 15, food = 20}
            buildings = {}
            particles = {}
            selected_colonist = nil
            build_mode = nil
            cycle_timer = 0
            raid_timer = 0
            game_time = 0
            generate_map()
            init_colonists()
        end
        if lurek.input.wasActionPressed("quit") then
            lurek.event.quit()
        end
        return
    end

    -- PLAYING state
    game_time = game_time + dt

    -- Timers
    cycle_timer = cycle_timer + dt
    if cycle_timer >= CYCLE_TIME then
        cycle_timer = cycle_timer - CYCLE_TIME
        run_production_cycle()
    end

    raid_timer = raid_timer + dt
    if raid_timer >= RAID_TIME then
        raid_timer = raid_timer - RAID_TIME
        run_raid()
    end

    -- Message decay
    if message_timer > 0 then
        message_timer = message_timer - dt
        if message_timer <= 0 then message = "" end
    end

    -- Input: speed
    if lurek.input.wasActionPressed("speed_1") then speed_mult = 1; show_message("Speed: 1x") end
    if lurek.input.wasActionPressed("speed_2") then speed_mult = 2; show_message("Speed: 2x") end
    if lurek.input.wasActionPressed("speed_3") then speed_mult = 4; show_message("Speed: 4x") end

    -- Input: build mode
    if lurek.input.wasActionPressed("build_house")    then build_mode = B_HOUSE;    show_message("Click to place House (10 wood)") end
    if lurek.input.wasActionPressed("build_farm")     then build_mode = B_FARM;     show_message("Click to place Farm (5 wood)") end
    if lurek.input.wasActionPressed("build_mine")     then build_mode = B_MINE;     show_message("Click to place Mine (5w+5s)") end
    if lurek.input.wasActionPressed("build_barracks") then build_mode = B_BARRACKS; show_message("Click to place Barracks (15w+10s)") end

    -- Input: assign job
    if selected_colonist and colonists[selected_colonist] then
        if lurek.input.wasActionPressed("assign_builder") then colonists[selected_colonist].job = J_BUILDER; show_message("Assigned Builder") end
        if lurek.input.wasActionPressed("assign_farmer")  then colonists[selected_colonist].job = J_FARMER;  show_message("Assigned Farmer") end
        if lurek.input.wasActionPressed("assign_miner")   then colonists[selected_colonist].job = J_MINER;   show_message("Assigned Miner") end
        if lurek.input.wasActionPressed("assign_guard")   then colonists[selected_colonist].job = J_GUARD;    show_message("Assigned Guard") end
    end

    -- Input: click
    if lurek.input.wasActionPressed("select") then
        local mx, my = lurek.input.mouse.getPosition()
        if build_mode then
            try_place_building(mx, my, build_mode)
        else
            -- Deselect all
            for _, c in ipairs(colonists) do c.selected = false end
            try_select_colonist(mx, my)
        end
    end

    -- Input: quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
    end

    -- Update
    update_colonists(dt)
    update_particles(dt)
    tween_resources(dt)

    -- Win/lose checks
    if #colonists >= WIN_POP then
        state = "VICTORY"
    elseif #colonists == 0 and state == "PLAYING" then
        state = "GAME_OVER"
    end
end

-- ── Render (world) ──────────────────────────────────────────
function lurek.draw()
    if state == "TITLE" then
        text_("COLONY SIM", 200, 180, {size = 48, color = {0.9, 0.8, 0.3, 1}})
        text_("BUILD YOUR SETTLEMENT", 220, 250, {size = 20, color = {0.7, 0.7, 0.7, 1}})
        text_("Click to Start", 310, 350, {size = 16, color = {0.5, 0.5, 0.5, 1}})
        return
    end

    if state == "VICTORY" then
        text_("VICTORY!", 270, 200, {size = 48, color = {0.9, 0.85, 0.2, 1}})
        text_("Colony reached " .. WIN_POP .. " colonists!", 230, 270, {size = 20, color = {0.8, 0.8, 0.8, 1}})
        text_("Click to play again", 300, 350, {size = 16, color = {0.5, 0.5, 0.5, 1}})
        return
    end

    if state == "GAME_OVER" then
        text_("GAME OVER", 260, 200, {size = 48, color = {0.9, 0.2, 0.2, 1}})
        text_("All colonists are gone...", 250, 270, {size = 20, color = {0.7, 0.5, 0.5, 1}})
        text_("Click to try again", 305, 350, {size = 16, color = {0.5, 0.5, 0.5, 1}})
        return
    end

    -- Draw terrain grid
    for r = 1, MAP_ROWS do
        for c = 1, MAP_COLS do
            local t = map[r][c]
            local clr = TERRAIN_COLORS[t]
            local px = (c - 1) * TILE_SIZE
            local py = (r - 1) * TILE_SIZE
            rect(px, py, TILE_SIZE, TILE_SIZE, {color = {clr[1], clr[2], clr[3], 1}})
            -- Grid line
            rect(px, py, TILE_SIZE, TILE_SIZE, {color = {0, 0, 0, 0.1}, mode = "line"})
        end
    end

    -- Draw buildings
    for _, b in ipairs(buildings) do
        local px = (b.col - 1) * TILE_SIZE + 2
        local py = (b.row - 1) * TILE_SIZE + 2
        local clr = BUILD_COLORS[b.type]
        rect(px, py, TILE_SIZE - 4, TILE_SIZE - 4, {color = {clr[1], clr[2], clr[3], 0.9}})
        -- Label
        local label = string.upper(string.sub(b.type, 1, 1))
        text_(label, px + 10, py + 8, {size = 14, color = {1, 1, 1, 1}})
    end

    -- Draw colonists
    for i, c in ipairs(colonists) do
        local clr = JOB_COLORS[c.job]
        local bob = math.sin(c.anim_t * 3) * 2
        local cx, cy = c.x, c.y + bob

        -- Selection ring
        if c.selected or i == selected_colonist then
            circ(cx, cy, 10, {color = {1, 1, 0, 0.6}, mode = "line"})
        end

        -- Body
        circ(cx, cy, 6, {color = {clr[1], clr[2], clr[3], 1}})

        -- Job letter
        text_(c.job, cx - 4, cy - 18, {size = 10, color = {1, 1, 1, 0.9}})
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        circ(p.x, p.y, 2, {color = {p.r, p.g, p.b, p.a}})
    end

    -- Build mode cursor
    if build_mode then
        local mx, my = lurek.input.mouse.getPosition()
        local col = math.floor(mx / TILE_SIZE)
        local row = math.floor(my / TILE_SIZE)
        local px = col * TILE_SIZE
        local py = row * TILE_SIZE
        local clr = BUILD_COLORS[build_mode] or {1, 1, 1}
        rect(px, py, TILE_SIZE, TILE_SIZE, {color = {clr[1], clr[2], clr[3], 0.4}})
    end
end

-- ── Render UI (HUD overlay) ─────────────────────────────────
function lurek.draw_ui()
    if state ~= "PLAYING" then return end

    local W = 800

    -- Top bar background
    rect(0, 0, W, HUD_HEIGHT, {color = {0, 0, 0, 0.7}})

    -- Resources with tweened bars
    local bar_w = 60
    local bar_h = 8
    local max_res = 100

    -- Wood
    text_("Wood:", 10, 4, {size = 12, color = {0.8, 0.6, 0.3, 1}})
    rect(55, 8, bar_w, bar_h, {color = {0.2, 0.2, 0.2, 0.8}})
    local w_fill = math.min(1, res_display.wood / max_res) * bar_w
    rect(55, 8, w_fill, bar_h, {color = {0.7, 0.5, 0.2, 1}})
    text_(tostring(math.floor(res_display.wood)), 120, 4, {size = 12, color = {1, 1, 1, 1}})

    -- Stone
    text_("Stone:", 160, 4, {size = 12, color = {0.6, 0.6, 0.7, 1}})
    rect(210, 8, bar_w, bar_h, {color = {0.2, 0.2, 0.2, 0.8}})
    local s_fill = math.min(1, res_display.stone / max_res) * bar_w
    rect(210, 8, s_fill, bar_h, {color = {0.5, 0.5, 0.7, 1}})
    text_(tostring(math.floor(res_display.stone)), 275, 4, {size = 12, color = {1, 1, 1, 1}})

    -- Food
    text_("Food:", 320, 4, {size = 12, color = {0.4, 0.8, 0.3, 1}})
    rect(365, 8, bar_w, bar_h, {color = {0.2, 0.2, 0.2, 0.8}})
    local f_fill = math.min(1, res_display.food / max_res) * bar_w
    rect(365, 8, f_fill, bar_h, {color = {0.3, 0.7, 0.2, 1}})
    text_(tostring(math.floor(res_display.food)), 430, 4, {size = 12, color = {1, 1, 1, 1}})

    -- Population
    local pop_str = string.format("Pop: %d/%d", #colonists, max_pop)
    text_(pop_str, 480, 4, {size = 12, color = {0.9, 0.9, 0.9, 1}})

    -- Speed indicator
    local spd_str = string.format("Speed: %dx", speed_mult)
    text_(spd_str, 580, 4, {size = 12, color = {0.7, 0.7, 0.4, 1}})

    -- FPS
    local fps = lurek.timer.getFPS()
    text_(string.format("FPS: %d", fps), W - 70, 4, {size = 12, color = {0.5, 0.5, 0.5, 1}})

    -- Cycle / raid timers at bottom
    local bottom_y = 600 - 40
    rect(0, bottom_y, W, 40, {color = {0, 0, 0, 0.5}})

    local cycle_pct = cycle_timer / CYCLE_TIME
    text_("Next cycle:", 10, bottom_y + 4, {size = 12, color = {0.7, 0.7, 0.7, 1}})
    rect(100, bottom_y + 8, 100, 6, {color = {0.2, 0.2, 0.2, 0.8}})
    rect(100, bottom_y + 8, cycle_pct * 100, 6, {color = {0.3, 0.8, 0.3, 1}})

    local raid_pct = raid_timer / RAID_TIME
    text_("Next raid:", 230, bottom_y + 4, {size = 12, color = {0.9, 0.4, 0.4, 1}})
    rect(320, bottom_y + 8, 100, 6, {color = {0.2, 0.2, 0.2, 0.8}})
    rect(320, bottom_y + 8, raid_pct * 100, 6, {color = {0.9, 0.2, 0.2, 1}})

    -- Build mode indicator
    if build_mode then
        text_("PLACING: " .. string.upper(build_mode), 460, bottom_y + 4, {size = 12, color = {1, 0.9, 0.3, 1}})
    end

    -- Job summary
    local job_str = string.format("B:%d F:%d M:%d G:%d I:%d",
        count_job(J_BUILDER), count_job(J_FARMER), count_job(J_MINER), count_job(J_GUARD), count_job(J_IDLE))
    text_(job_str, 10, bottom_y + 22, {size = 11, color = {0.6, 0.6, 0.6, 1}})

    -- Win target
    text_(string.format("Goal: %d/%d colonists", #colonists, WIN_POP), 230, bottom_y + 22,
        {size = 11, color = {0.8, 0.8, 0.4, 1}})

    -- Message display
    if message ~= "" then
        text_(message, 10, bottom_y - 20, {size = 13, color = {1, 1, 0.7, math.min(1, message_timer)}})
    end
end
