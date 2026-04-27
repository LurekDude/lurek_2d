-- God Game — Populous-style god simulation
-- Category: simulation

local GRID_W, GRID_H = 30, 22
local TILE = 26
local WORLD_W, WORLD_H = GRID_W * TILE, GRID_H * TILE

-- Terrain types
local WATER    = 0
local SAND     = 1
local GRASS    = 2
local FOREST   = 3
local MOUNTAIN = 4

local TERRAIN_COLORS = {
    [WATER]    = {0.15, 0.30, 0.60},
    [SAND]     = {0.76, 0.70, 0.50},
    [GRASS]    = {0.30, 0.65, 0.25},
    [FOREST]   = {0.12, 0.42, 0.15},
    [MOUNTAIN] = {0.50, 0.45, 0.40},
}

-- States
local TITLE     = "TITLE"
local PLAYING   = "PLAYING"
local VICTORY   = "VICTORY"
local GAME_OVER = "GAME_OVER"

-- Game state
local state = TITLE
local grid = {}
local display_colors = {}
local villagers = {}
local rival_villagers = {}
local houses = {}
local walls = {}
local particles = {}
local tweens_active = {}

local population = 0
local food = 10
local faith = 0
local faith_timer = 0
local game_speed = 1
local game_time = 0
local rival_timer = 0
local food_timer = 0
local build_timer = 0
local spawn_timer = 0
local rival_spawn_timer = 0

local mouse_held_left = false
local mouse_held_right = false
local cursor_gx, cursor_gy = 0, 0

local cam_x, cam_y = 0, 0

local WIN_POP = 50

-- ─── Helpers ───────────────────────────────────────────────

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function in_grid(gx, gy) return gx >= 1 and gx <= GRID_W and gy >= 1 and gy <= GRID_H end
local function lerp(a, b, t) return a + (b - a) * t end

local function lerp_color(c1, c2, t)
    return {lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t), lerp(c1[3], c2[3], t)}
end

local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function screen_to_grid(sx, sy)
    local gx = math.floor((sx + cam_x) / TILE) + 1
    local gy = math.floor((sy + cam_y) / TILE) + 1
    return gx, gy
end

local function grid_to_screen(gx, gy)
    return (gx - 1) * TILE - cam_x, (gy - 1) * TILE - cam_y
end

-- ─── World Generation ──────────────────────────────────────

local function generate_world()
    grid = {}
    display_colors = {}
    for y = 1, GRID_H do
        grid[y] = {}
        display_colors[y] = {}
        for x = 1, GRID_W do
            local nx = x / GRID_W
            local ny = y / GRID_H
            local center_dist = dist(nx, ny, 0.5, 0.5)
            local base = math.sin(nx * 6.28) * 0.2 + math.cos(ny * 4.71) * 0.2 + (1 - center_dist)
            base = base + (math.random() - 0.5) * 0.3
            local terrain
            if base < 0.3 then terrain = WATER
            elseif base < 0.45 then terrain = SAND
            elseif base < 0.7 then terrain = GRASS
            elseif base < 0.85 then terrain = FOREST
            else terrain = MOUNTAIN end
            grid[y][x] = terrain
            local c = TERRAIN_COLORS[terrain]
            display_colors[y][x] = {c[1], c[2], c[3]}
        end
    end
end

local function set_terrain(gx, gy, new_t)
    if not in_grid(gx, gy) then return end
    grid[gy][gx] = new_t
    local target = TERRAIN_COLORS[new_t]
    local current = display_colors[gy][gx]
    local tween_id = gx .. "_" .. gy
    tweens_active[tween_id] = {gx = gx, gy = gy, from = {current[1], current[2], current[3]}, to = target, t = 0, dur = 0.3}
end

-- ─── Villager Logic ────────────────────────────────────────

local function spawn_villager(faction, gx, gy)
    local v = {
        x = (gx - 0.5) * TILE,
        y = (gy - 0.5) * TILE,
        gx = gx, gy = gy,
        target_x = nil, target_y = nil,
        move_timer = 0,
        faction = faction,
        alive = true,
    }
    if faction == "player" then
        table.insert(villagers, v)
    else
        table.insert(rival_villagers, v)
    end
end

local function terrain_preference(terrain, faction)
    if terrain == WATER then return -10 end
    if terrain == MOUNTAIN then return -5 end
    if terrain == GRASS then return 3 end
    if terrain == FOREST then return 2 end
    if terrain == SAND then return 0 end
    return 0
end

local function pick_wander_target(v)
    local best_x, best_y, best_score = v.gx, v.gy, -999
    for dy = -2, 2 do
        for dx = -2, 2 do
            if dx ~= 0 or dy ~= 0 then
                local nx, ny = v.gx + dx, v.gy + dy
                if in_grid(nx, ny) then
                    local t = grid[ny][nx]
                    local score = terrain_preference(t, v.faction) + (math.random() - 0.5) * 2
                    -- Avoid walls for rivals
                    if v.faction == "rival" then
                        for _, w in ipairs(walls) do
                            if w.gx == nx and w.gy == ny then
                                score = score - 20
                            end
                        end
                    end
                    if score > best_score then
                        best_score = score
                        best_x, best_y = nx, ny
                    end
                end
            end
        end
    end
    v.target_x = (best_x - 0.5) * TILE
    v.target_y = (best_y - 0.5) * TILE
end

local function update_villager(v, dt)
    if not v.alive then return end
    v.move_timer = v.move_timer - dt * game_speed
    if v.move_timer <= 0 then
        pick_wander_target(v)
        v.move_timer = 0.8 + math.random() * 0.6
    end
    if v.target_x and v.target_y then
        local spd = 30 * dt * game_speed
        local dx, dy = v.target_x - v.x, v.target_y - v.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d > 1 then
            v.x = v.x + (dx / d) * spd
            v.y = v.y + (dy / d) * spd
        end
    end
    v.gx = clamp(math.floor(v.x / TILE) + 1, 1, GRID_W)
    v.gy = clamp(math.floor(v.y / TILE) + 1, 1, GRID_H)
    -- Drown in water
    if in_grid(v.gx, v.gy) and grid[v.gy][v.gx] == WATER then
        v.alive = false
    end
end

-- ─── Particles ─────────────────────────────────────────────

local function spawn_particle(x, y, r, g, b, vx, vy, life)
    table.insert(particles, {
        x = x, y = y, r = r, g = g, b = b, a = 1,
        vx = vx or 0, vy = vy or 0,
        life = life or 1.0, max_life = life or 1.0,
    })
end

local function spawn_miracle_particles(kind, cx, cy)
    if kind == "rain" then
        for _ = 1, 40 do
            spawn_particle(cx + math.random(-80, 80), cy + math.random(-60, 60),
                0.3, 0.5, 0.9, 0, 40 + math.random() * 30, 0.8 + math.random() * 0.4)
        end
    elseif kind == "earthquake" then
        for _ = 1, 30 do
            spawn_particle(cx + math.random(-60, 60), cy + math.random(-60, 60),
                0.6, 0.45, 0.25, (math.random() - 0.5) * 60, -20 - math.random() * 40, 0.6 + math.random() * 0.3)
        end
    elseif kind == "lightning" then
        for _ = 1, 25 do
            spawn_particle(cx + math.random(-20, 20), cy + math.random(-20, 20),
                1.0, 1.0, 0.7, (math.random() - 0.5) * 80, (math.random() - 0.5) * 80, 0.3 + math.random() * 0.2)
        end
    elseif kind == "blessing" then
        for _ = 1, 20 do
            spawn_particle(cx + math.random(-30, 30), cy + math.random(-30, 30),
                0.9, 0.85, 0.3, 0, -15 - math.random() * 20, 1.0 + math.random() * 0.5)
        end
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.a = clamp(p.life / p.max_life, 0, 1)
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ─── Miracles ──────────────────────────────────────────────

local function miracle_rain()
    if faith < 10 then return end
    faith = faith - 10
    spawn_miracle_particles("rain", 400, 300)
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            if grid[y][x] == GRASS then
                set_terrain(x, y, FOREST)
            end
        end
    end
    food = food + population * 2
end

local function miracle_earthquake()
    if faith < 20 then return end
    faith = faith - 20
    local sx, sy = screen_to_grid(lurek.input.mouse.getX(), lurek.input.mouse.getY())
    spawn_miracle_particles("earthquake", lurek.input.mouse.getX(), lurek.input.mouse.getY())
    for dy = -2, 2 do
        for dx = -2, 2 do
            local gx, gy = sx + dx, sy + dy
            if in_grid(gx, gy) and grid[gy][gx] > WATER then
                set_terrain(gx, gy, grid[gy][gx] - 1)
            end
        end
    end
end

local function miracle_lightning()
    if faith < 15 then return end
    faith = faith - 15
    local gx, gy = screen_to_grid(lurek.input.mouse.getX(), lurek.input.mouse.getY())
    spawn_miracle_particles("lightning", lurek.input.mouse.getX(), lurek.input.mouse.getY())
    if in_grid(gx, gy) and grid[gy][gx] == FOREST then
        set_terrain(gx, gy, GRASS)
    end
    -- Damage rival villagers nearby
    for _, rv in ipairs(rival_villagers) do
        if rv.alive and dist(rv.gx, rv.gy, gx, gy) < 3 then
            rv.alive = false
        end
    end
end

local function miracle_blessing()
    if faith < 5 then return end
    faith = faith - 5
    local max_housing = #houses * 3
    local can_add = math.min(3, max_housing - population)
    if can_add < 1 then can_add = 1 end
    for _ = 1, can_add do
        -- Spawn near a house
        if #houses > 0 then
            local h = houses[math.random(#houses)]
            spawn_villager("player", h.gx + math.random(-1, 1), h.gy + math.random(-1, 1))
            spawn_miracle_particles("blessing", (h.gx - 0.5) * TILE - cam_x, (h.gy - 0.5) * TILE - cam_y)
        end
    end
end

-- ─── Houses & Walls ────────────────────────────────────────

local function try_build_house()
    -- Find a grass tile near villagers without a house
    for _, v in ipairs(villagers) do
        if v.alive and in_grid(v.gx, v.gy) and grid[v.gy][v.gx] == GRASS then
            local has_house = false
            for _, h in ipairs(houses) do
                if h.gx == v.gx and h.gy == v.gy then has_house = true break end
            end
            if not has_house then
                table.insert(houses, {gx = v.gx, gy = v.gy})
                return true
            end
        end
    end
    return false
end

local function place_wall()
    if faith < 5 then return end
    local gx, gy = screen_to_grid(lurek.input.mouse.getX(), lurek.input.mouse.getY())
    if not in_grid(gx, gy) then return end
    for _, w in ipairs(walls) do
        if w.gx == gx and w.gy == gy then return end
    end
    faith = faith - 5
    table.insert(walls, {gx = gx, gy = gy})
end

-- ─── Rival AI ──────────────────────────────────────────────

local function update_rival(dt)
    rival_timer = rival_timer - dt * game_speed
    if rival_timer <= 0 then
        rival_timer = 3.0
        -- Auto-expand: spawn a new rival if less than population
        if #rival_villagers < population + 5 then
            local spawn_x = GRID_W - math.random(0, 4)
            local spawn_y = math.random(1, GRID_H)
            if in_grid(spawn_x, spawn_y) and grid[spawn_y][spawn_x] ~= WATER then
                spawn_villager("rival", spawn_x, spawn_y)
            end
        end
    end
    -- Rivals attack player villagers if close
    for _, rv in ipairs(rival_villagers) do
        if rv.alive then
            for _, pv in ipairs(villagers) do
                if pv.alive and dist(rv.gx, rv.gy, pv.gx, pv.gy) < 2 then
                    -- 30% chance to kill
                    if math.random() < 0.3 * dt * game_speed then
                        pv.alive = false
                    end
                end
            end
        end
    end
end

-- ─── Update ────────────────────────────────────────────────

local function update_tweens(dt)
    local to_remove = {}
    for id, tw in pairs(tweens_active) do
        tw.t = tw.t + dt / tw.dur
        if tw.t >= 1 then
            display_colors[tw.gy][tw.gx] = {tw.to[1], tw.to[2], tw.to[3]}
            to_remove[#to_remove + 1] = id
        else
            display_colors[tw.gy][tw.gx] = lerp_color(tw.from, tw.to, tw.t)
        end
    end
    for _, id in ipairs(to_remove) do tweens_active[id] = nil end
end

local function count_alive(list)
    local n = 0
    for _, v in ipairs(list) do if v.alive then n = n + 1 end end
    return n
end

local function clean_dead(list)
    local i = 1
    while i <= #list do
        if not list[i].alive then
            table.remove(list, i)
        else
            i = i + 1
        end
    end
end

-- ─── Input Bindings ────────────────────────────────────────

lurek.input.bind("raise", "mouse1")
lurek.input.bind("lower", "mouse2")
lurek.input.bind("rain", "r")
lurek.input.bind("earthquake", "e")
lurek.input.bind("lightning", "l")
lurek.input.bind("blessing", "b")
lurek.input.bind("wall", "w")
lurek.input.bind("speed1", "1")
lurek.input.bind("speed2", "2")
lurek.input.bind("speed3", "3")
lurek.input.bind("quit", "escape")

-- ─── Callbacks ─────────────────────────────────────────────

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
local function ln(...)
    local x1, y1, x2, y2, c, r, g, b = ...
    if type(c) == "number" then
        _gfx.setColor(c or 1, r or 1, g or 1, b or 1)
    elseif type(c) == "table" then
        _sc(c)
    end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("God Game — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.1, 0.15)
    generate_world()

    -- Place starting villagers on left side
    for i = 1, 10 do
        local gx = math.random(2, 8)
        local gy = math.random(2, GRID_H - 1)
        if grid[gy][gx] == GRASS or grid[gy][gx] == FOREST then
            spawn_villager("player", gx, gy)
        else
            spawn_villager("player", 4, math.floor(GRID_H / 2) + i - 5)
        end
    end
    -- Initial rival villagers on right side
    for i = 1, 5 do
        local gx = GRID_W - math.random(1, 5)
        local gy = math.random(3, GRID_H - 2)
        spawn_villager("rival", gx, gy)
    end
end

function lurek.process(dt)
    if state == TITLE then
        if lurek.input.wasActionPressed("raise") then
            state = PLAYING
        end
        return
    end

    if state == VICTORY or state == GAME_OVER then
        if lurek.input.wasActionPressed("raise") then
            -- Restart
            state = TITLE
            villagers = {}
            rival_villagers = {}
            houses = {}
            walls = {}
            particles = {}
            tweens_active = {}
            faith = 0
            food = 10
            game_time = 0
            generate_world()
        end
        return
    end

    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- Game speed
    if lurek.input.wasActionPressed("speed1") then game_speed = 1 end
    if lurek.input.wasActionPressed("speed2") then game_speed = 2 end
    if lurek.input.wasActionPressed("speed3") then game_speed = 3 end

    game_time = game_time + dt * game_speed

    -- Cursor grid pos
    cursor_gx, cursor_gy = screen_to_grid(lurek.input.mouse.getX(), lurek.input.mouse.getY())

    -- Terrain sculpting
    if lurek.input.isActionDown("raise") then
        if in_grid(cursor_gx, cursor_gy) and grid[cursor_gy][cursor_gx] < MOUNTAIN then
            set_terrain(cursor_gx, cursor_gy, grid[cursor_gy][cursor_gx] + 1)
        end
    end
    if lurek.input.isActionDown("lower") then
        if in_grid(cursor_gx, cursor_gy) and grid[cursor_gy][cursor_gx] > WATER then
            set_terrain(cursor_gx, cursor_gy, grid[cursor_gy][cursor_gx] - 1)
        end
    end

    -- Miracles
    if lurek.input.wasActionPressed("rain") then miracle_rain() end
    if lurek.input.wasActionPressed("earthquake") then miracle_earthquake() end
    if lurek.input.wasActionPressed("lightning") then miracle_lightning() end
    if lurek.input.wasActionPressed("blessing") then miracle_blessing() end
    if lurek.input.wasActionPressed("wall") then place_wall() end

    -- Update villagers
    for _, v in ipairs(villagers) do update_villager(v, dt) end
    for _, rv in ipairs(rival_villagers) do update_villager(rv, dt) end

    -- Clean dead
    clean_dead(villagers)
    clean_dead(rival_villagers)
    population = count_alive(villagers)

    -- Faith generation: 1 per second per 5 villagers
    faith_timer = faith_timer + dt * game_speed
    if faith_timer >= 1.0 then
        faith_timer = faith_timer - 1.0
        faith = faith + math.floor(population / 5)
    end

    -- Food production
    food_timer = food_timer + dt * game_speed
    if food_timer >= 2.0 then
        food_timer = food_timer - 2.0
        local forest_count = 0
        for y = 1, GRID_H do
            for x = 1, GRID_W do
                if grid[y][x] == FOREST then forest_count = forest_count + 1 end
            end
        end
        food = food + math.floor(forest_count / 8)
    end

    -- Population growth
    spawn_timer = spawn_timer + dt * game_speed
    if spawn_timer >= 3.0 then
        spawn_timer = spawn_timer - 3.0
        local max_housing = math.max(#houses * 3, 10)
        if food > population and population < max_housing then
            food = food - 1
            -- Spawn near existing villager
            if #villagers > 0 then
                local parent = villagers[math.random(#villagers)]
                spawn_villager("player", parent.gx + math.random(-1, 1), parent.gy + math.random(-1, 1))
            end
        end
    end

    -- Auto-build houses when needed
    build_timer = build_timer + dt * game_speed
    if build_timer >= 4.0 then
        build_timer = build_timer - 4.0
        if population > #houses * 3 then
            try_build_house()
        end
    end

    -- Rival AI
    update_rival(dt)

    -- Tweens and particles
    update_tweens(dt)
    update_particles(dt)

    -- Win/lose checks
    if population >= WIN_POP then state = VICTORY end
    if population <= 0 and game_time > 5 then state = GAME_OVER end
end

function lurek.draw()
    if state == TITLE then
        return
    end

    -- Draw terrain
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local sx, sy = grid_to_screen(x, y)
            local c = display_colors[y][x]
            rect(sx, sy, TILE, TILE, c[1], c[2], c[3], 1)
        end
    end

    -- Grid lines (subtle)
    for y = 0, GRID_H do
        local sy = y * TILE - cam_y
        ln(0 - cam_x, sy, WORLD_W - cam_x, sy, 0.2, 0.2, 0.2, 0.15)
    end
    for x = 0, GRID_W do
        local sx = x * TILE - cam_x
        ln(sx, 0 - cam_y, sx, WORLD_H - cam_y, 0.2, 0.2, 0.2, 0.15)
    end

    -- Walls
    for _, w in ipairs(walls) do
        local sx, sy = grid_to_screen(w.gx, w.gy)
        rect(sx + 2, sy + 2, TILE - 4, TILE - 4, 0.55, 0.45, 0.35, 0.9)
        rect(sx + 4, sy + 4, TILE - 8, TILE - 8, 0.65, 0.55, 0.40, 0.8)
    end

    -- Houses
    for _, h in ipairs(houses) do
        local sx, sy = grid_to_screen(h.gx, h.gy)
        local cx, cy = sx + TILE / 2, sy + TILE / 2
        -- Base
        rect(cx - 6, cy - 4, 12, 10, 0.7, 0.55, 0.3, 0.9)
        -- Roof
        rect(cx - 8, cy - 6, 16, 4, 0.6, 0.2, 0.15, 0.9)
    end

    -- Player villagers (blue circles)
    for _, v in ipairs(villagers) do
        if v.alive then
            local sx, sy = v.x - cam_x, v.y - cam_y
            circ(sx, sy, 4, 0.3, 0.5, 0.95, 1)
            circ(sx, sy, 2, 0.5, 0.7, 1.0, 1)
        end
    end

    -- Rival villagers (red circles)
    for _, rv in ipairs(rival_villagers) do
        if rv.alive then
            local sx, sy = rv.x - cam_x, rv.y - cam_y
            circ(sx, sy, 4, 0.85, 0.2, 0.15, 1)
            circ(sx, sy, 2, 1.0, 0.35, 0.25, 1)
        end
    end

    -- Cursor highlight
    if state == PLAYING and in_grid(cursor_gx, cursor_gy) then
        local sx, sy = grid_to_screen(cursor_gx, cursor_gy)
        rect(sx, sy, TILE, TILE, 1, 1, 1, 0.15)
    end

    -- Particles
    for _, p in ipairs(particles) do
        circ(p.x, p.y, 2, p.r, p.g, p.b, p.a)
    end
end

function lurek.draw_ui()
    if state == TITLE then
        text_("GOD GAME", 240, 180, 48, 0.9, 0.85, 0.6, 1)
        text_("SHAPE THE WORLD", 260, 250, 20, 0.7, 0.7, 0.6, 0.8)
        text_("Click to Start", 310, 350, 16, 0.6, 0.6, 0.5, 0.6 + math.sin(lurek.timer.getTime() * 3) * 0.3)
        text_("Left Click: Raise  |  Right Click: Lower", 180, 420, 14, 0.5, 0.5, 0.5, 0.7)
        text_("R-Rain  E-Earthquake  L-Lightning  B-Blessing  W-Wall", 130, 445, 14, 0.5, 0.5, 0.5, 0.7)
        return
    end

    if state == VICTORY then
        rect(150, 180, 500, 200, 0.05, 0.15, 0.05, 0.85)
        text_("DIVINE VICTORY!", 260, 220, 36, 0.9, 0.85, 0.4, 1)
        text_("Your people flourish — " .. population .. " souls", 245, 280, 18, 0.7, 0.8, 0.6, 0.9)
        text_("Click to play again", 310, 340, 14, 0.6, 0.6, 0.5, 0.6)
        return
    end

    if state == GAME_OVER then
        rect(150, 180, 500, 200, 0.15, 0.05, 0.05, 0.85)
        text_("YOUR PEOPLE PERISHED", 220, 220, 32, 0.9, 0.3, 0.2, 1)
        text_("The land is silent.", 300, 280, 18, 0.7, 0.5, 0.4, 0.9)
        text_("Click to try again", 310, 340, 14, 0.6, 0.6, 0.5, 0.6)
        return
    end

    -- HUD background
    rect(0, 0, 800, 32, 0.05, 0.05, 0.1, 0.8)

    -- Population
    local pop_color_r = population >= WIN_POP * 0.8 and 0.3 or 0.8
    local pop_color_g = population >= WIN_POP * 0.8 and 0.9 or 0.8
    text_("Pop: " .. population .. "/" .. WIN_POP, 10, 8, 16, pop_color_r, pop_color_g, 0.7, 1)

    -- Food
    text_("Food: " .. food, 160, 8, 16, 0.7, 0.8, 0.5, 1)

    -- Faith bar
    local faith_display = math.min(faith, 100)
    rect(290, 6, 102, 18, 0.2, 0.2, 0.3, 0.8)
    rect(291, 7, faith_display, 16, 0.6, 0.5, 0.9, 0.9)
    text_("Faith: " .. faith, 300, 8, 14, 0.85, 0.8, 1, 1)

    -- Houses
    text_("Houses: " .. #houses, 430, 8, 14, 0.7, 0.6, 0.4, 0.9)

    -- Rivals
    local rival_count = count_alive(rival_villagers)
    text_("Rivals: " .. rival_count, 530, 8, 14, 0.9, 0.4, 0.3, 0.9)

    -- Speed indicator
    text_("Speed: " .. game_speed .. "x", 640, 8, 14, 0.6, 0.6, 0.6, 0.8)

    -- FPS
    text_("FPS: " .. lurek.timer.getFPS(), 730, 8, 12, 0.4, 0.4, 0.4, 0.6)

    -- Bottom bar — miracle costs
    rect(0, 572, 800, 28, 0.05, 0.05, 0.1, 0.7)
    text_("[R] Rain:10  [E] Quake:20  [L] Lightning:15  [B] Bless:5  [W] Wall:5", 100, 578, 13, 0.55, 0.55, 0.6, 0.8)

    -- Terrain info at cursor
    if in_grid(cursor_gx, cursor_gy) then
        local terrain_names = {[WATER]="Water", [SAND]="Sand", [GRASS]="Grass", [FOREST]="Forest", [MOUNTAIN]="Mountain"}
        local t = grid[cursor_gy][cursor_gx]
        local name = terrain_names[t] or "?"
        text_(name .. " (" .. cursor_gx .. "," .. cursor_gy .. ")", 10, 555, 12, 0.5, 0.5, 0.5, 0.7)
    end
end
