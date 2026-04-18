-- ============================================================================
-- Province Demo — Lurek2D
-- Category: showcase
-- Procedural Voronoi-like province map with terrain, ownership, fog of war,
-- pathfinding, and multiple visualization modes on a 40x30 grid.
-- ============================================================================

-- ── Constants ──────────────────────────────────────────────────────────
local SCREEN_W      = 800
local SCREEN_H      = 600
local GRID_W        = 40
local GRID_H        = 30
local CELL_SIZE     = 20
local NUM_SEEDS     = 40

local TERRAIN_PLAINS   = 1
local TERRAIN_FOREST   = 2
local TERRAIN_MOUNTAIN = 3
local TERRAIN_DESERT   = 4
local TERRAIN_COAST    = 5

local TERRAIN_NAMES = {
    [TERRAIN_PLAINS]   = "Plains",
    [TERRAIN_FOREST]   = "Forest",
    [TERRAIN_MOUNTAIN] = "Mountain",
    [TERRAIN_DESERT]   = "Desert",
    [TERRAIN_COAST]    = "Coast",
}

local TERRAIN_COLORS = {
    [TERRAIN_PLAINS]   = {0.40, 0.70, 0.30},
    [TERRAIN_FOREST]   = {0.15, 0.45, 0.15},
    [TERRAIN_MOUNTAIN] = {0.55, 0.45, 0.35},
    [TERRAIN_DESERT]   = {0.85, 0.78, 0.45},
    [TERRAIN_COAST]    = {0.30, 0.55, 0.80},
}

local TERRAIN_COSTS = {
    [TERRAIN_PLAINS]   = 1,
    [TERRAIN_FOREST]   = 2,
    [TERRAIN_MOUNTAIN] = 3,
    [TERRAIN_DESERT]   = 2,
    [TERRAIN_COAST]    = 1,
}

local OWNER_NONE  = 0
local OWNER_RED   = 1
local OWNER_BLUE  = 2
local OWNER_GREEN = 3

local OWNER_NAMES = {
    [OWNER_NONE]  = "Neutral",
    [OWNER_RED]   = "Red",
    [OWNER_BLUE]  = "Blue",
    [OWNER_GREEN] = "Green",
}

local OWNER_COLORS = {
    [OWNER_NONE]  = {0.45, 0.45, 0.45},
    [OWNER_RED]   = {0.85, 0.25, 0.20},
    [OWNER_BLUE]  = {0.25, 0.40, 0.85},
    [OWNER_GREEN] = {0.20, 0.75, 0.30},
}

local MODE_TERRAIN    = 1
local MODE_OWNER      = 2
local MODE_POPULATION = 3
local MODE_NAMES = { "Terrain", "Owner", "Population" }

local PROVINCE_PREFIXES = {
    "North", "South", "East", "West", "Upper", "Lower", "Old", "New", "Great", "Inner"
}
local PROVINCE_ROOTS = {
    "heim", "shire", "vale", "march", "dale", "reach", "hold", "fell", "glen", "moor",
    "crest", "haven", "ford", "brook", "ridge", "peak", "shore", "wood", "stone", "field"
}

local STATE_TITLE   = "TITLE"
local STATE_VIEWING = "VIEWING"

-- ── State ──────────────────────────────────────────────────────────────
local state         = STATE_TITLE
local grid          = {}        -- grid[y][x] = province_id
local provinces     = {}        -- provinces[id] = {name, terrain, owner, population, cells, cx, cy, neighbors}
local selected_id   = nil
local path_cells    = {}
local display_mode  = MODE_TERRAIN
local fog_enabled   = false

local title_alpha       = 0
local title_sub_alpha   = 0
local detail_panel_x    = SCREEN_W
local detail_target_x   = SCREEN_W
local stats_alpha       = 1

local color_blend       = 0     -- 0..1 for mode transition
local prev_mode_colors  = {}
local next_mode_colors  = {}

local particles     = {}
local tweens        = {}

local fps_timer     = 0
local fps_display   = 0
local frame_count   = 0

-- ── Helpers ────────────────────────────────────────────────────────────

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function ease_out(t)
    return 1 - (1 - t) * (1 - t)
end

local function random_name()
    local prefix = PROVINCE_PREFIXES[math.random(#PROVINCE_PREFIXES)]
    local root   = PROVINCE_ROOTS[math.random(#PROVINCE_ROOTS)]
    return prefix .. root
end

-- ── Tween engine ───────────────────────────────────────────────────────

local function tween_to(tbl, key, target, dur, ease_fn)
    for i = #tweens, 1, -1 do
        if tweens[i].tbl == tbl and tweens[i].key == key then
            table.remove(tweens, i)
        end
    end
    table.insert(tweens, {
        tbl = tbl, key = key, start = tbl[key],
        target = target, dur = dur, elapsed = 0,
        ease = ease_fn or "linear",
    })
end

local function tweens_update(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = clamp(tw.elapsed / tw.dur, 0, 1)
        if tw.ease == "ease_out" then t = ease_out(t)
        elseif tw.ease == "ease_in" then t = t * t end
        tw.tbl[tw.key] = lerp(tw.start, tw.target, t)
        if tw.elapsed >= tw.dur then
            tw.tbl[tw.key] = tw.target
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end
end

-- ── Particle engine ────────────────────────────────────────────────────

local function particle_burst(x, y, count, r, g, b, spread, life)
    spread = spread or 30
    life   = life or 0.7
    for _ = 1, count do
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * spread,
            vy = (math.random() - 0.5) * spread,
            life = life, max_life = life,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        })
    end
end

local function particles_update(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

-- ── Province generation (Voronoi flood fill) ───────────────────────────

local function generate_map()
    math.randomseed(os.time() + math.random(10000))
    grid = {}
    provinces = {}
    selected_id = nil
    path_cells = {}

    -- Initialize grid
    for y = 1, GRID_H do
        grid[y] = {}
        for x = 1, GRID_W do
            grid[y][x] = 0
        end
    end

    -- Place seeds
    local seeds = {}
    for i = 1, NUM_SEEDS do
        local sx = math.random(1, GRID_W)
        local sy = math.random(1, GRID_H)
        seeds[i] = {x = sx, y = sy}
        grid[sy][sx] = i
        local terrain_roll = math.random(100)
        local terrain
        if terrain_roll <= 35 then terrain = TERRAIN_PLAINS
        elseif terrain_roll <= 55 then terrain = TERRAIN_FOREST
        elseif terrain_roll <= 70 then terrain = TERRAIN_MOUNTAIN
        elseif terrain_roll <= 85 then terrain = TERRAIN_DESERT
        else terrain = TERRAIN_COAST end

        provinces[i] = {
            id        = i,
            name      = random_name(),
            terrain   = terrain,
            owner     = OWNER_NONE,
            population = math.random(100, 1000),
            cells     = {{x = sx, y = sy}},
            cx        = sx,
            cy        = sy,
            neighbors = {},
        }
    end

    -- Flood fill
    local queue = {}
    for i, s in ipairs(seeds) do
        table.insert(queue, {x = s.x, y = s.y, id = i})
    end

    local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
    -- Shuffle queue for more organic shapes
    for i = #queue, 2, -1 do
        local j = math.random(1, i)
        queue[i], queue[j] = queue[j], queue[i]
    end

    local head = 1
    while head <= #queue do
        local cur = queue[head]
        head = head + 1
        for _, d in ipairs(dirs) do
            local nx, ny = cur.x + d[1], cur.y + d[2]
            if nx >= 1 and nx <= GRID_W and ny >= 1 and ny <= GRID_H then
                if grid[ny][nx] == 0 then
                    grid[ny][nx] = cur.id
                    table.insert(provinces[cur.id].cells, {x = nx, y = ny})
                    table.insert(queue, {x = nx, y = ny, id = cur.id})
                end
            end
        end
    end

    -- Compute centroids and neighbors
    for _, prov in ipairs(provinces) do
        local sx, sy = 0, 0
        for _, c in ipairs(prov.cells) do
            sx = sx + c.x
            sy = sy + c.y
        end
        prov.cx = sx / #prov.cells
        prov.cy = sy / #prov.cells
        prov.neighbors = {}
    end

    -- Find neighbor relationships
    local neighbor_set = {}
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local pid = grid[y][x]
            for _, d in ipairs(dirs) do
                local nx, ny = x + d[1], y + d[2]
                if nx >= 1 and nx <= GRID_W and ny >= 1 and ny <= GRID_H then
                    local nid = grid[ny][nx]
                    if nid ~= pid then
                        local key = pid < nid and (pid .. "_" .. nid) or (nid .. "_" .. pid)
                        if not neighbor_set[key] then
                            neighbor_set[key] = true
                            table.insert(provinces[pid].neighbors, nid)
                            table.insert(provinces[nid].neighbors, pid)
                        end
                    end
                end
            end
        end
    end

    -- Randomly assign some provinces to factions
    for i = 1, math.min(4, NUM_SEEDS) do
        local idx = math.random(1, NUM_SEEDS)
        provinces[idx].owner = math.random(1, 3)
    end
end

-- ── Pathfinding (A*) ───────────────────────────────────────────────────

local function find_path(from_id, to_id)
    if from_id == to_id then return {from_id} end

    local open    = {[from_id] = true}
    local closed  = {}
    local g_score = {[from_id] = 0}
    local f_score = {[from_id] = 0}
    local came_from = {}

    while true do
        -- Find lowest f_score in open
        local current = nil
        local best_f  = math.huge
        for id in pairs(open) do
            if f_score[id] < best_f then
                best_f = f_score[id]
                current = id
            end
        end
        if not current then return nil end
        if current == to_id then
            -- Reconstruct path
            local path = {to_id}
            local node = to_id
            while came_from[node] do
                node = came_from[node]
                table.insert(path, 1, node)
            end
            return path
        end
        open[current] = nil
        closed[current] = true

        for _, nid in ipairs(provinces[current].neighbors) do
            if not closed[nid] then
                local cost = TERRAIN_COSTS[provinces[nid].terrain] or 1
                local tent_g = g_score[current] + cost
                if not g_score[nid] or tent_g < g_score[nid] then
                    came_from[nid] = current
                    g_score[nid] = tent_g
                    -- Heuristic: Euclidean distance between centroids
                    local dx = provinces[to_id].cx - provinces[nid].cx
                    local dy = provinces[to_id].cy - provinces[nid].cy
                    f_score[nid] = tent_g + math.sqrt(dx * dx + dy * dy) * 0.5
                    open[nid] = true
                end
            end
        end
    end
end

-- ── Color helpers ──────────────────────────────────────────────────────

local function get_cell_color(pid)
    local prov = provinces[pid]
    if not prov then return 0.2, 0.2, 0.2 end

    if display_mode == MODE_TERRAIN then
        local c = TERRAIN_COLORS[prov.terrain]
        return c[1], c[2], c[3]
    elseif display_mode == MODE_OWNER then
        local c = OWNER_COLORS[prov.owner]
        return c[1], c[2], c[3]
    else -- MODE_POPULATION
        local t = (prov.population - 100) / 900
        t = clamp(t, 0, 1)
        return lerp(0.1, 1.0, t), lerp(0.2, 0.3, t), lerp(0.8, 0.1, t)
    end
end

local function is_border_cell(x, y)
    local pid = grid[y][x]
    local dirs = {{0,-1},{0,1},{-1,0},{1,0}}
    for _, d in ipairs(dirs) do
        local nx, ny = x + d[1], y + d[2]
        if nx >= 1 and nx <= GRID_W and ny >= 1 and ny <= GRID_H then
            if grid[ny][nx] ~= pid then return true end
        else
            return true
        end
    end
    return false
end

local function is_visible(pid)
    if not fog_enabled then return true end
    local prov = provinces[pid]
    return prov and prov.owner ~= OWNER_NONE
end

-- ── Province at mouse ──────────────────────────────────────────────────

local function province_at_mouse(mx, my)
    local gx = math.floor(mx / CELL_SIZE) + 1
    local gy = math.floor(my / CELL_SIZE) + 1
    if gx >= 1 and gx <= GRID_W and gy >= 1 and gy <= GRID_H then
        return grid[gy][gx]
    end
    return nil
end

-- ── Input bindings ─────────────────────────────────────────────────────

local function setup_bindings()
    lurek.input.bind("mode",    {"m"})
    lurek.input.bind("fog",     {"f"})
    lurek.input.bind("generate",{"g"})
    lurek.input.bind("owner1",  {"1"})
    lurek.input.bind("owner2",  {"2"})
    lurek.input.bind("owner3",  {"3"})
    lurek.input.bind("select",  {"mouse1"})
    lurek.input.bind("path",    {"mouse2"})
    lurek.input.bind("quit",    {"escape"})
end

-- ── Statistics ─────────────────────────────────────────────────────────

local function compute_stats()
    local counts = {[OWNER_NONE] = 0, [OWNER_RED] = 0, [OWNER_BLUE] = 0, [OWNER_GREEN] = 0}
    local total_pop = 0
    local terrain_dist = {}
    for _, prov in ipairs(provinces) do
        counts[prov.owner] = (counts[prov.owner] or 0) + 1
        total_pop = total_pop + prov.population
        local tn = TERRAIN_NAMES[prov.terrain]
        terrain_dist[tn] = (terrain_dist[tn] or 0) + 1
    end
    return counts, total_pop, terrain_dist
end

-- ── lurek callbacks ────────────────────────────────────────────────────

function lurek.init()
    lurek.window.setTitle("Province Demo — Lurek2D")
    lurek.gfx.setBackgroundColor(0.05, 0.08, 0.1)

    setup_bindings()
    generate_map()

    -- Title fade in
    local _t = {alpha = 0, sub = 0}
    title_alpha = 0
    title_sub_alpha = 0
    tween_to(_t, "alpha", 1, 0.8, "ease_out")
    -- We'll use the raw values in render
end

function lurek.process(dt)
    tweens_update(dt)
    particles_update(dt)

    -- FPS counter
    frame_count = frame_count + 1
    fps_timer = fps_timer + dt
    if fps_timer >= 1.0 then
        fps_display = frame_count
        frame_count = 0
        fps_timer = fps_timer - 1.0
        if state == STATE_VIEWING then
            lurek.window.setTitle("Province Demo — " .. MODE_NAMES[display_mode] .. " — FPS: " .. fps_display)
        end
    end

    if state == STATE_TITLE then
        title_alpha = math.min(title_alpha + dt * 1.2, 1)
        title_sub_alpha = math.min(title_sub_alpha + dt * 0.8, 1)
        if lurek.input.actionPressed("select") or lurek.input.actionPressed("mode") then
            state = STATE_VIEWING
            particle_burst(SCREEN_W / 2, SCREEN_H / 2, 30, 0.4, 0.7, 1.0, 80, 1.0)
        end
        return
    end

    -- ── VIEWING state input ────────────────────────────────────────
    if lurek.input.actionPressed("quit") then
        lurek.signal.quit()
    end

    if lurek.input.actionPressed("mode") then
        display_mode = display_mode % 3 + 1
        color_blend = 0
        tween_to({}, "unused", 0, 0, "linear") -- trigger re-render smoothly
        particle_burst(SCREEN_W / 2, 20, 15, 0.8, 0.8, 0.2, 60, 0.5)
    end

    if lurek.input.actionPressed("fog") then
        fog_enabled = not fog_enabled
        particle_burst(SCREEN_W / 2, 20, 10, 0.5, 0.5, 0.8, 40, 0.5)
    end

    if lurek.input.actionPressed("generate") then
        generate_map()
        selected_id = nil
        path_cells = {}
        detail_panel_x = SCREEN_W
        detail_target_x = SCREEN_W
        particle_burst(SCREEN_W / 2, SCREEN_H / 2, 40, 0.2, 0.9, 0.4, 100, 1.0)
    end

    -- Ownership assignment
    if selected_id and provinces[selected_id] then
        if lurek.input.actionPressed("owner1") then
            provinces[selected_id].owner = OWNER_RED
            local c = OWNER_COLORS[OWNER_RED]
            particle_burst(provinces[selected_id].cx * CELL_SIZE, provinces[selected_id].cy * CELL_SIZE, 12, c[1], c[2], c[3], 30, 0.6)
        end
        if lurek.input.actionPressed("owner2") then
            provinces[selected_id].owner = OWNER_BLUE
            local c = OWNER_COLORS[OWNER_BLUE]
            particle_burst(provinces[selected_id].cx * CELL_SIZE, provinces[selected_id].cy * CELL_SIZE, 12, c[1], c[2], c[3], 30, 0.6)
        end
        if lurek.input.actionPressed("owner3") then
            provinces[selected_id].owner = OWNER_GREEN
            local c = OWNER_COLORS[OWNER_GREEN]
            particle_burst(provinces[selected_id].cx * CELL_SIZE, provinces[selected_id].cy * CELL_SIZE, 12, c[1], c[2], c[3], 30, 0.6)
        end
    end

    -- Province selection (left click)
    if lurek.input.actionPressed("select") then
        local mx, my = lurek.input.getMousePosition()
        local pid = province_at_mouse(mx, my)
        if pid and is_visible(pid) then
            selected_id = pid
            path_cells = {}
            detail_target_x = SCREEN_W - 200
            local px = provinces[pid].cx * CELL_SIZE
            local py = provinces[pid].cy * CELL_SIZE
            particle_burst(px, py, 20, 1.0, 0.9, 0.3, 50, 0.8)
        else
            selected_id = nil
            path_cells = {}
            detail_target_x = SCREEN_W
        end
    end

    -- Pathfinding (right click)
    if lurek.input.actionPressed("path") and selected_id then
        local mx, my = lurek.input.getMousePosition()
        local target = province_at_mouse(mx, my)
        if target and target ~= selected_id and is_visible(target) then
            local p = find_path(selected_id, target)
            if p then
                path_cells = p
                -- Sparkle along path
                for _, pid in ipairs(p) do
                    local prov = provinces[pid]
                    particle_burst(prov.cx * CELL_SIZE, prov.cy * CELL_SIZE, 5, 0.2, 0.8, 1.0, 20, 1.0)
                end
            else
                path_cells = {}
            end
        end
    end

    -- Slide detail panel
    detail_panel_x = detail_panel_x + (detail_target_x - detail_panel_x) * math.min(dt * 10, 1)
end

-- ── Render (world-space map) ───────────────────────────────────────────

function lurek.render()
    if state == STATE_TITLE then
        -- Title background gradient effect
        for y = 0, 5 do
            local a = 0.03 + y * 0.01
            lurek.gfx.setColor(0.1, 0.15, 0.25, a)
            lurek.gfx.rectangle("fill", 0, y * 100, SCREEN_W, 100)
        end
        return
    end

    -- Draw province cells
    for y = 1, GRID_H do
        for x = 1, GRID_W do
            local pid = grid[y][x]
            local px = (x - 1) * CELL_SIZE
            local py = (y - 1) * CELL_SIZE

            if is_visible(pid) then
                local r, g, b = get_cell_color(pid)

                -- Highlight selected province
                if pid == selected_id then
                    r = math.min(r + 0.15, 1)
                    g = math.min(g + 0.15, 1)
                    b = math.min(b + 0.15, 1)
                end

                -- Highlight path
                local in_path = false
                for _, pp in ipairs(path_cells) do
                    if pp == pid then in_path = true; break end
                end
                if in_path then
                    r = math.min(r + 0.2, 1)
                    b = math.min(b + 0.3, 1)
                end

                lurek.gfx.setColor(r, g, b, 1)
                lurek.gfx.rectangle("fill", px, py, CELL_SIZE, CELL_SIZE)

                -- Border cells: darker outline
                if is_border_cell(x, y) then
                    lurek.gfx.setColor(r * 0.5, g * 0.5, b * 0.5, 0.8)
                    lurek.gfx.rectangle("line", px, py, CELL_SIZE, CELL_SIZE)
                end
            else
                -- Fog
                lurek.gfx.setColor(0.08, 0.08, 0.1, 1)
                lurek.gfx.rectangle("fill", px, py, CELL_SIZE, CELL_SIZE)
            end
        end
    end

    -- Draw path lines
    if #path_cells > 1 then
        lurek.gfx.setColor(0.3, 0.85, 1.0, 0.9)
        for i = 1, #path_cells - 1 do
            local a = provinces[path_cells[i]]
            local b = provinces[path_cells[i + 1]]
            if a and b then
                lurek.gfx.line(a.cx * CELL_SIZE, a.cy * CELL_SIZE, b.cx * CELL_SIZE, b.cy * CELL_SIZE)
            end
        end
        -- Path endpoints
        local s = provinces[path_cells[1]]
        local e = provinces[path_cells[#path_cells]]
        if s then
            lurek.gfx.setColor(0.2, 1.0, 0.4, 1)
            lurek.gfx.circle("fill", s.cx * CELL_SIZE, s.cy * CELL_SIZE, 4)
        end
        if e then
            lurek.gfx.setColor(1.0, 0.3, 0.2, 1)
            lurek.gfx.circle("fill", e.cx * CELL_SIZE, e.cy * CELL_SIZE, 4)
        end
    end

    -- Particles (world space)
    for _, p in ipairs(particles) do
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.gfx.setColor(p.r, p.g, p.b, a * 0.8)
        lurek.gfx.circle("fill", p.x, p.y, p.size * a)
    end
end

-- ── Render UI (screen-space overlays) ──────────────────────────────────

function lurek.render_ui()
    if state == STATE_TITLE then
        lurek.gfx.setColor(0.4, 0.7, 1.0, title_alpha)
        lurek.gfx.print("PROVINCE MAP", SCREEN_W / 2 - 100, SCREEN_H / 2 - 40)
        lurek.gfx.setColor(0.6, 0.8, 0.9, title_sub_alpha * 0.7)
        lurek.gfx.print("PROCEDURAL WORLD", SCREEN_W / 2 - 80, SCREEN_H / 2 + 10)
        lurek.gfx.setColor(0.5, 0.5, 0.6, math.abs(math.sin(title_alpha * 3.14)) * 0.6)
        lurek.gfx.print("Click to begin", SCREEN_W / 2 - 55, SCREEN_H / 2 + 60)
        return
    end

    -- Top HUD bar
    lurek.gfx.setColor(0.0, 0.0, 0.0, 0.6)
    lurek.gfx.rectangle("fill", 0, 0, SCREEN_W, 22)
    lurek.gfx.setColor(0.9, 0.9, 0.9, 1)
    lurek.gfx.print("Mode: " .. MODE_NAMES[display_mode] .. " (M)  |  Fog: " .. (fog_enabled and "ON" or "OFF") .. " (F)  |  G=New Map  |  1/2/3=Assign Owner", 8, 4)

    -- FPS
    lurek.gfx.setColor(0.6, 0.6, 0.3, 1)
    lurek.gfx.print("FPS: " .. fps_display, SCREEN_W - 70, 4)

    -- Detail panel (right side)
    if selected_id and provinces[selected_id] then
        local prov = provinces[selected_id]
        local px = detail_panel_x
        local pw = 190
        local ph = 160

        -- Panel background
        lurek.gfx.setColor(0.05, 0.05, 0.1, 0.85)
        lurek.gfx.rectangle("fill", px, 30, pw, ph)
        lurek.gfx.setColor(0.3, 0.5, 0.8, 0.8)
        lurek.gfx.rectangle("line", px, 30, pw, ph)

        -- Province details
        lurek.gfx.setColor(1.0, 0.9, 0.5, 1)
        lurek.gfx.print(prov.name, px + 8, 38)

        lurek.gfx.setColor(0.8, 0.8, 0.8, 1)
        lurek.gfx.print("Terrain: " .. TERRAIN_NAMES[prov.terrain], px + 8, 58)
        lurek.gfx.print("Owner: " .. OWNER_NAMES[prov.owner], px + 8, 74)
        lurek.gfx.print("Population: " .. prov.population, px + 8, 90)
        lurek.gfx.print("Cells: " .. #prov.cells, px + 8, 106)

        local ncount = #prov.neighbors
        lurek.gfx.print("Neighbors: " .. ncount, px + 8, 122)

        if #path_cells > 1 then
            local total_cost = 0
            for _, pid in ipairs(path_cells) do
                total_cost = total_cost + (TERRAIN_COSTS[provinces[pid].terrain] or 1)
            end
            lurek.gfx.setColor(0.3, 0.85, 1.0, 1)
            lurek.gfx.print("Path cost: " .. total_cost, px + 8, 145)
        end

        -- Owner color swatch
        local oc = OWNER_COLORS[prov.owner]
        lurek.gfx.setColor(oc[1], oc[2], oc[3], 1)
        lurek.gfx.rectangle("fill", px + pw - 20, 38, 12, 12)
    end

    -- Statistics panel (bottom)
    local counts, total_pop, terrain_dist = compute_stats()
    local sy = SCREEN_H - 60
    lurek.gfx.setColor(0.0, 0.0, 0.0, 0.6)
    lurek.gfx.rectangle("fill", 0, sy, SCREEN_W, 60)
    lurek.gfx.setColor(0.8, 0.8, 0.8, 1)
    lurek.gfx.print("Provinces: " .. #provinces .. "  |  Total Pop: " .. total_pop, 8, sy + 4)

    -- Owner counts
    local ox = 8
    local oy = sy + 22
    for owner = 0, 3 do
        local c = OWNER_COLORS[owner]
        lurek.gfx.setColor(c[1], c[2], c[3], 1)
        lurek.gfx.rectangle("fill", ox, oy, 10, 10)
        lurek.gfx.setColor(0.8, 0.8, 0.8, 1)
        lurek.gfx.print(OWNER_NAMES[owner] .. ": " .. counts[owner], ox + 14, oy)
        ox = ox + 110
    end

    -- Terrain distribution
    local tx = 8
    local ty = sy + 40
    for _, name in ipairs({"Plains", "Forest", "Mountain", "Desert", "Coast"}) do
        local cnt = terrain_dist[name] or 0
        lurek.gfx.setColor(0.6, 0.7, 0.6, 1)
        lurek.gfx.print(name .. ":" .. cnt, tx, ty)
        tx = tx + 100
    end
end
