-- Railroad — top-down railroad management simulation
-- Category: simulation

local GRID_W, GRID_H = 25, 18
local TILE = 32
local MAP_X, MAP_Y = 0, 0

-- Terrain types
local T_GRASS = 0
local T_WATER = 1
local T_MOUNTAIN = 2
local T_TOWN = 3

-- Goods
local GOOD_COAL = 1
local GOOD_WOOD = 2
local GOOD_IRON = 3
local GOOD_NAMES = { "Coal", "Wood", "Iron" }
local GOOD_COLORS = {
    { 0.45, 0.28, 0.12 }, -- coal brown
    { 0.2, 0.6, 0.2 },   -- wood green
    { 0.6, 0.6, 0.65 },  -- iron gray
}

-- States
local STATE_TITLE = 0
local STATE_PLAYING = 1
local STATE_VICTORY = 2

-- Game data
local state = STATE_TITLE
local grid = {}
local tracks = {}
local stations = {}
local trains = {}
local towns = {}
local signals = {}
local gold = 200
local total_revenue = 0
local total_expense = 0
local game_speed = 1
local mode = "track" -- track, station, signal
local title_blink = 0
local victory_time = 0
local particles = {}
local tweens_list = {}
---@type any
local _cam = nil

-- Town definitions: gx, gy, name, produces, wants
local TOWN_DEFS = {
    { gx = 3,  gy = 3,  name = "Millford",  produces = GOOD_COAL, wants = GOOD_WOOD },
    { gx = 21, gy = 3,  name = "Ashton",    produces = GOOD_WOOD, wants = GOOD_IRON },
    { gx = 4,  gy = 15, name = "Ironhaven", produces = GOOD_IRON, wants = GOOD_COAL },
    { gx = 20, gy = 14, name = "Goldcrest", produces = GOOD_COAL, wants = GOOD_IRON },
}

-------------------------------------------------
-- Helpers
-------------------------------------------------
local function grid_key(gx, gy) return gy * GRID_W + gx end
local function in_bounds(gx, gy) return gx >= 0 and gx < GRID_W and gy >= 0 and gy < GRID_H end

local function spawn_particle(x, y, r, g, b, life, vx, vy)
    particles[#particles + 1] = {
        x = x, y = y, r = r, g = g, b = b, a = 1,
        life = life, max_life = life,
        vx = vx or 0, vy = vy or (math.random() * -30 - 10),
        size = 3 + math.random() * 3,
    }
end

local function add_tween(target, field, from, to, dur, delay)
    tweens_list[#tweens_list + 1] = {
        target = target, field = field,
        from = from, to = to, dur = dur, elapsed = -(delay or 0),
    }
end

local function ease_out_quad(t)
    return 1 - (1 - t) * (1 - t)
end

-------------------------------------------------
-- Map generation
-------------------------------------------------
local function generate_map()
    math.randomseed(42)
    for gy = 0, GRID_H - 1 do
        for gx = 0, GRID_W - 1 do
            local r = math.random()
            local t = T_GRASS
            if r < 0.06 then t = T_WATER
            elseif r < 0.10 then t = T_MOUNTAIN end
            grid[grid_key(gx, gy)] = t
        end
    end
    -- Place towns
    for i, td in ipairs(TOWN_DEFS) do
        grid[grid_key(td.gx, td.gy)] = T_TOWN
        -- clear neighbors for building room
        for dy = -1, 1 do
            for dx = -1, 1 do
                local nx, ny = td.gx + dx, td.gy + dy
                if in_bounds(nx, ny) and grid[grid_key(nx, ny)] ~= T_TOWN then
                    grid[grid_key(nx, ny)] = T_GRASS
                end
            end
        end
        towns[i] = {
            gx = td.gx, gy = td.gy, name = td.name,
            produces = td.produces, wants = td.wants,
            stock = 0, stock_timer = 0,
        }
    end
    -- Clear water/mountain from direct paths between towns (make game playable)
    for gy = 0, GRID_H - 1 do
        for gx = 0, GRID_W - 1 do
            local k = grid_key(gx, gy)
            if grid[k] == T_WATER or grid[k] == T_MOUNTAIN then
                -- keep some, remove blocking ones near center corridors
                if (gy >= 7 and gy <= 10) or (gx >= 10 and gx <= 14) then
                    if math.random() < 0.7 then grid[k] = T_GRASS end
                end
            end
        end
    end
end

-------------------------------------------------
-- Track / Station / Signal helpers
-------------------------------------------------
local function has_track(gx, gy) return tracks[grid_key(gx, gy)] ~= nil end

local function find_station_at(gx, gy)
    for _, s in ipairs(stations) do
        if s.gx == gx and s.gy == gy then return s end
    end
    return nil
end

local function find_town_at(gx, gy)
    for _, tw in ipairs(towns) do
        if tw.gx == gx and tw.gy == gy then return tw end
    end
    return nil
end

local function track_neighbors(gx, gy)
    local dirs = { { 0, -1 }, { 1, 0 }, { 0, 1 }, { -1, 0 } }
    local n = {}
    for _, d in ipairs(dirs) do
        local nx, ny = gx + d[1], gy + d[2]
        if in_bounds(nx, ny) and has_track(nx, ny) then
            n[#n + 1] = { gx = nx, gy = ny }
        end
    end
    return n
end

-------------------------------------------------
-- Pathfinding (BFS along tracks)
-------------------------------------------------
local function find_path(sx, sy, ex, ey)
    if not has_track(sx, sy) or not has_track(ex, ey) then return nil end
    local queue = { { gx = sx, gy = sy } }
    local visited = {}
    local parent = {}
    visited[grid_key(sx, sy)] = true
    local head = 1
    while head <= #queue do
        local cur = queue[head]; head = head + 1
        if cur.gx == ex and cur.gy == ey then
            -- reconstruct
            local path = {}
            local k = grid_key(ex, ey)
            while k do
                local pg = parent[k]
                path[#path + 1] = { gx = k % GRID_W, gy = math.floor(k / GRID_W) }
                k = pg
            end
            -- reverse
            local rev = {}
            for i = #path, 1, -1 do rev[#rev + 1] = path[i] end
            return rev
        end
        local nb = track_neighbors(cur.gx, cur.gy)
        for _, n in ipairs(nb) do
            local nk = grid_key(n.gx, n.gy)
            if not visited[nk] then
                visited[nk] = true
                parent[nk] = grid_key(cur.gx, cur.gy)
                queue[#queue + 1] = n
            end
        end
    end
    return nil
end

-------------------------------------------------
-- Train logic
-------------------------------------------------
local TRAIN_SPEED = 64  -- px/s
local MAX_TRAINS = 5
local train_colors = {
    { 0.9, 0.2, 0.2 }, { 0.2, 0.5, 0.9 }, { 0.9, 0.7, 0.1 },
    { 0.8, 0.3, 0.8 }, { 0.2, 0.8, 0.6 },
}

local route_pick = nil -- { station1 = s } waiting for second pick

local function create_train(s1, s2)
    if #trains >= MAX_TRAINS then return false end
    local path = find_path(s1.gx, s1.gy, s2.gx, s2.gy)
    if not path then return false end
    local rev_path = find_path(s2.gx, s2.gy, s1.gx, s1.gy)
    if not rev_path then return false end
    if gold < 100 then return false end
    gold = gold - 100
    total_expense = total_expense + 100
    local idx = #trains + 1
    local col = train_colors[((idx - 1) % #train_colors) + 1]
    trains[idx] = {
        path = path, rev_path = rev_path,
        seg = 1, progress = 0, forward = true,
        x = path[1].gx * TILE + TILE / 2,
        y = path[1].gy * TILE + TILE / 2,
        color = col,
        carrying = nil, -- good type or nil
        station1 = s1, station2 = s2,
        smoke_timer = 0,
    }
    return true
end

local function update_trains(dt)
    for _, tr in ipairs(trains) do
        local cur_path = tr.forward and tr.path or tr.rev_path
        if not cur_path or #cur_path < 2 then goto continue_train end

        tr.smoke_timer = tr.smoke_timer + dt
        if tr.smoke_timer > 0.15 then
            tr.smoke_timer = 0
            spawn_particle(tr.x, tr.y - 4, 0.5, 0.5, 0.5, 0.8)
        end

        local dist = TRAIN_SPEED * dt * game_speed
        tr.progress = tr.progress + dist

        while tr.progress >= TILE and tr.seg < #cur_path do
            tr.progress = tr.progress - TILE
            tr.seg = tr.seg + 1
        end

        if tr.seg >= #cur_path then
            -- arrived at end
            local dest = tr.forward and tr.station2 or tr.station1
            local src = tr.forward and tr.station1 or tr.station2
            local dest_town = find_town_at(dest.gx, dest.gy)
            local src_town = find_town_at(src.gx, src.gy)

            -- deliver goods
            if tr.carrying and dest_town and dest_town.wants == tr.carrying then
                gold = gold + 10
                total_revenue = total_revenue + 10
                -- delivery sparkle
                for _ = 1, 8 do
                    spawn_particle(tr.x, tr.y, 1, 0.85, 0.2, 0.6,
                        math.random() * 60 - 30, math.random() * -40 - 10)
                end
                tr.carrying = nil
            end

            -- pick up goods
            if not tr.carrying and src_town and src_town.stock > 0 then
                -- actually dest is where we arrived, pick up there
            end
            if not tr.carrying and dest_town and dest_town.stock > 0 then
                tr.carrying = dest_town.produces
                dest_town.stock = dest_town.stock - 1
                -- loading glow
                for _ = 1, 5 do
                    local gc = GOOD_COLORS[tr.carrying]
                    spawn_particle(tr.x, tr.y, gc[1], gc[2], gc[3], 0.5,
                        math.random() * 20 - 10, math.random() * -20)
                end
            end

            -- reverse direction
            tr.forward = not tr.forward
            tr.seg = 1
            tr.progress = 0
        end

        -- interpolate position
        local s1 = cur_path[tr.seg]
        local s2 = cur_path[math.min(tr.seg + 1, #cur_path)]
        local frac = tr.progress / TILE
        if frac > 1 then frac = 1 end
        tr.x = (s1.gx + (s2.gx - s1.gx) * frac) * TILE + TILE / 2
        tr.y = (s1.gy + (s2.gy - s1.gy) * frac) * TILE + TILE / 2

        ::continue_train::
    end
end

-------------------------------------------------
-- Input handling
-------------------------------------------------
local function handle_click(mx, my)
    local gx = math.floor((mx - MAP_X) / TILE)
    local gy = math.floor((my - MAP_Y) / TILE)
    if not in_bounds(gx, gy) then return end
    local terrain = grid[grid_key(gx, gy)]

    if route_pick then
        -- picking second station for train route
        local s2 = find_station_at(gx, gy)
        if s2 and s2 ~= route_pick.station1 then
            create_train(route_pick.station1, s2)
        end
        route_pick = nil
        return
    end

    if mode == "station" then
        if terrain == T_TOWN and not find_station_at(gx, gy) then
            if gold >= 50 then
                gold = gold - 50
                total_expense = total_expense + 50
                stations[#stations + 1] = { gx = gx, gy = gy, anim = 0 }
                -- also place track on station tile
                tracks[grid_key(gx, gy)] = { gx = gx, gy = gy, anim = 1 }
                -- station loading glow
                for _ = 1, 6 do
                    spawn_particle(gx * TILE + TILE / 2, gy * TILE + TILE / 2,
                        0.9, 0.8, 0.2, 0.7, math.random() * 40 - 20, math.random() * -30)
                end
            end
        end
        mode = "track"
        return
    end

    if mode == "signal" then
        if has_track(gx, gy) and not signals[grid_key(gx, gy)] then
            if gold >= 10 then
                gold = gold - 10
                total_expense = total_expense + 10
                signals[grid_key(gx, gy)] = { gx = gx, gy = gy }
            end
        end
        mode = "track"
        return
    end

    -- track placement
    if terrain == T_GRASS or terrain == T_TOWN then
        if not has_track(gx, gy) then
            if gold >= 5 then
                gold = gold - 5
                total_expense = total_expense + 5
                tracks[grid_key(gx, gy)] = { gx = gx, gy = gy, anim = 0 }
                add_tween(tracks[grid_key(gx, gy)], "anim", 0, 1, 0.3)
            end
        end
    end
end

-------------------------------------------------
-- Callbacks
-------------------------------------------------
lurek.render.setBackgroundColor(0.1, 0.12, 0.08)

lurek.input.bind("place", "mouse1")
lurek.input.bind("station_mode", "s")
lurek.input.bind("buy_train", "t")
lurek.input.bind("signal_mode", "g")
lurek.input.bind("speed1", "1")
lurek.input.bind("speed2", "2")
lurek.input.bind("speed3", "3")
lurek.input.bind("quit", "escape")

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
    lurek.window.setTitle("Railroad — Lurek2D")
    _cam = lurek.camera.new()
    generate_map()
end

local function _ready_setup()
    _cam:setPosition(0, 0)
end

function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    if state == STATE_TITLE then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("place") then
            state = STATE_PLAYING
        end
        return
    end

    if state == STATE_VICTORY then
        victory_time = victory_time + dt
        return
    end

    -- Speed controls
    if lurek.input.wasActionPressed("speed1") then game_speed = 1 end
    if lurek.input.wasActionPressed("speed2") then game_speed = 2 end
    if lurek.input.wasActionPressed("speed3") then game_speed = 3 end

    -- Mode switches
    if lurek.input.wasActionPressed("station_mode") then mode = "station" end
    if lurek.input.wasActionPressed("signal_mode") then mode = "signal" end
    if lurek.input.wasActionPressed("buy_train") then
        -- pick first station
        if #stations >= 2 and #trains < MAX_TRAINS and gold >= 100 then
            mode = "track"
            -- find a station near mouse or use first available pair
            local mx, my = lurek.input.mouse.getPosition()
            local gx = math.floor((mx - MAP_X) / TILE)
            local gy = math.floor((my - MAP_Y) / TILE)
            local nearest = nil
            local best_dist = 999999
            for _, s in ipairs(stations) do
                local d = math.abs(s.gx - gx) + math.abs(s.gy - gy)
                if d < best_dist then best_dist = d; nearest = s end
            end
            if nearest then
                route_pick = { station1 = nearest }
            end
        end
    end

    -- Click handling
    if lurek.input.wasActionPressed("place") and not route_pick then
        local mx, my = lurek.input.mouse.getPosition()
        handle_click(mx, my)
    elseif lurek.input.wasActionPressed("place") and route_pick then
        local mx, my = lurek.input.mouse.getPosition()
        handle_click(mx, my)
    end

    -- Town production
    for _, tw in ipairs(towns) do
        tw.stock_timer = tw.stock_timer + dt * game_speed
        if tw.stock_timer >= 3.0 then
            tw.stock_timer = tw.stock_timer - 3.0
            if tw.stock < 5 then
                tw.stock = tw.stock + 1
            end
        end
    end

    -- Update trains
    update_trains(dt)

    -- Update particles
    local alive = {}
    for _, p in ipairs(particles) do
        p.life = p.life - dt
        if p.life > 0 then
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
            p.a = p.life / p.max_life
            p.size = p.size * (0.98)
            alive[#alive + 1] = p
        end
    end
    particles = alive

    -- Update tweens
    local active_tweens = {}
    for _, tw in ipairs(tweens_list) do
        tw.elapsed = tw.elapsed + dt
        if tw.elapsed >= 0 then
            local t = math.min(tw.elapsed / tw.dur, 1)
            local e = ease_out_quad(t)
            tw.target[tw.field] = tw.from + (tw.to - tw.from) * e
            if t < 1 then
                active_tweens[#active_tweens + 1] = tw
            else
                tw.target[tw.field] = tw.to
            end
        else
            active_tweens[#active_tweens + 1] = tw
        end
    end
    tweens_list = active_tweens

    -- Victory check
    if gold >= 1000 then
        local all_connected = #stations >= 4
        if all_connected then
            state = STATE_VICTORY
            victory_time = 0
        end
    end
end

-------------------------------------------------
-- Render: map, tracks, trains
-------------------------------------------------
function lurek.draw()
    if state == STATE_TITLE then
        return
    end

    -- Draw terrain
    for gy = 0, GRID_H - 1 do
        for gx = 0, GRID_W - 1 do
            local t = grid[grid_key(gx, gy)]
            local px, py = MAP_X + gx * TILE, MAP_Y + gy * TILE
            if t == T_GRASS then
                lurek.render.setColor(0.25, 0.45, 0.2, 1)
                rect(px, py, TILE, TILE)
                -- grass texture hint
                if (gx + gy) % 3 == 0 then
                    lurek.render.setColor(0.28, 0.50, 0.22, 1)
                    rect(px + 4, py + 4, 4, 4)
                end
            elseif t == T_WATER then
                lurek.render.setColor(0.15, 0.35, 0.65, 1)
                rect(px, py, TILE, TILE)
                lurek.render.setColor(0.2, 0.4, 0.7, 0.5)
                rect(px + 8, py + 12, 16, 4)
            elseif t == T_MOUNTAIN then
                lurek.render.setColor(0.45, 0.40, 0.35, 1)
                rect(px, py, TILE, TILE)
                lurek.render.setColor(0.55, 0.50, 0.45, 1)
                rect(px + 8, py + 4, 16, 12)
                lurek.render.setColor(0.7, 0.7, 0.7, 1)
                rect(px + 12, py + 2, 8, 6)
            elseif t == T_TOWN then
                lurek.render.setColor(0.55, 0.42, 0.3, 1)
                rect(px, py, TILE, TILE)
                -- building
                lurek.render.setColor(0.7, 0.55, 0.4, 1)
                rect(px + 6, py + 6, 20, 20)
                lurek.render.setColor(0.85, 0.7, 0.5, 1)
                rect(px + 10, py + 10, 12, 12)
            end
            -- grid line
            lurek.render.setColor(0, 0, 0, 0.1)
            rect(px, py, TILE, TILE)
        end
    end

    -- Draw tracks
    for _, tr in pairs(tracks) do
        local px = MAP_X + tr.gx * TILE
        local py = MAP_Y + tr.gy * TILE
        local a = tr.anim or 1
        -- rail bed
        lurek.render.setColor(0.35, 0.3, 0.25, a)
        rect(px + 4, py + 4, TILE - 8, TILE - 8)
        -- rail lines based on neighbors
        local nb = track_neighbors(tr.gx, tr.gy)
        lurek.render.setColor(0.5, 0.5, 0.5, a)
        for _, n in ipairs(nb) do
            local dx = n.gx - tr.gx
            local dy = n.gy - tr.gy
            local cx, cy = px + TILE / 2, py + TILE / 2
            if dx ~= 0 then
                -- horizontal rail
                rect(cx - 2, cy - 6, TILE / 2 * dx + 4, 3)
                rect(cx - 2, cy + 3, TILE / 2 * dx + 4, 3)
            end
            if dy ~= 0 then
                -- vertical rail
                rect(cx - 6, cy - 2, 3, TILE / 2 * dy + 4)
                rect(cx + 3, cy - 2, 3, TILE / 2 * dy + 4)
            end
        end
        if #nb == 0 then
            -- isolated track piece
            rect(px + 8, py + TILE / 2 - 1, TILE - 16, 3)
        end
        -- crossties
        lurek.render.setColor(0.4, 0.3, 0.2, a)
        rect(px + 6, py + 8, 3, TILE - 16)
        rect(px + TILE - 9, py + 8, 3, TILE - 16)
    end

    -- Draw signals
    for _, sig in pairs(signals) do
        local px = MAP_X + sig.gx * TILE + TILE / 2
        local py = MAP_Y + sig.gy * TILE + 2
        -- pole
        lurek.render.setColor(0.3, 0.3, 0.3, 1)
        rect(px - 1, py, 3, TILE - 4)
        -- light
        lurek.render.setColor(0.1, 0.9, 0.1, 1)
        rect(px - 3, py, 7, 7)
    end

    -- Draw stations
    for _, st in ipairs(stations) do
        local px = MAP_X + st.gx * TILE
        local py = MAP_Y + st.gy * TILE
        lurek.render.setColor(0.8, 0.7, 0.2, 1)
        rect(px + 2, py + 2, TILE - 4, TILE - 4)
        lurek.render.setColor(0.9, 0.85, 0.4, 1)
        rect(px + 6, py + 6, TILE - 12, TILE - 12)
        -- S marker
        lurek.render.setColor(0.2, 0.1, 0, 1)
        rect(px + 12, py + 10, 8, 3)
        rect(px + 12, py + 15, 8, 3)
        rect(px + 12, py + 20, 8, 3)
    end

    -- Draw town names
    for _, tw in ipairs(towns) do
        local px = MAP_X + tw.gx * TILE + TILE / 2
        local py = MAP_Y + tw.gy * TILE - 12
        lurek.render.setColor(1, 1, 1, 0.9)
        text_(tw.name, px - 20, py)
        -- stock indicator
        if tw.stock > 0 then
            local gc = GOOD_COLORS[tw.produces]
            for i = 1, tw.stock do
                lurek.render.setColor(gc[1], gc[2], gc[3], 1)
                rect(
                    MAP_X + tw.gx * TILE + TILE + 2,
                    MAP_Y + tw.gy * TILE + (i - 1) * 6,
                    5, 4)
            end
        end
    end

    -- Draw trains
    for _, tr in ipairs(trains) do
        local c = tr.color
        -- body
        lurek.render.setColor(c[1], c[2], c[3], 1)
        rect(tr.x - 8, tr.y - 5, 16, 10)
        -- cabin
        lurek.render.setColor(c[1] * 0.7, c[2] * 0.7, c[3] * 0.7, 1)
        rect(tr.x - 5, tr.y - 7, 10, 3)
        -- cargo indicator
        if tr.carrying then
            local gc = GOOD_COLORS[tr.carrying]
            lurek.render.setColor(gc[1], gc[2], gc[3], 1)
            rect(tr.x - 3, tr.y - 3, 6, 6)
        end
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        lurek.render.setColor(p.r, p.g, p.b, p.a)
        rect(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size)
    end
end

-------------------------------------------------
-- Render UI: stats, mode indicator, title/victory
-------------------------------------------------
function lurek.draw_ui()
    if state == STATE_TITLE then
        -- Title screen
        lurek.render.setColor(0.9, 0.8, 0.3, 1)
        text_("R A I L R O A D", 260, 180)
        local blink_a = 0.5 + 0.5 * math.sin(title_blink * 3)
        lurek.render.setColor(0.8, 0.8, 0.8, blink_a)
        text_("BUILD YOUR NETWORK", 270, 240)
        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        text_("Click to start", 320, 320)
        lurek.render.setColor(0.4, 0.4, 0.4, 1)
        text_("S=Station  T=Train  G=Signal  1/2/3=Speed", 180, 400)
        return
    end

    if state == STATE_VICTORY then
        lurek.render.setColor(1, 0.85, 0.1, 1)
        text_("VICTORY!", 340, 200)
        lurek.render.setColor(0.9, 0.9, 0.9, 1)
        text_("You connected all towns and earned 1000 gold!", 180, 260)
        text_("Revenue: " .. total_revenue .. "  Expense: " .. total_expense, 240, 310)
        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        text_("Press Escape to quit", 300, 400)
        return
    end

    -- HUD background
    lurek.render.setColor(0, 0, 0, 0.7)
    rect(0, GRID_H * TILE, 800, 600 - GRID_H * TILE)

    local hud_y = GRID_H * TILE + 4

    -- Gold
    lurek.render.setColor(1, 0.85, 0.2, 1)
    text_("Gold: " .. gold, 10, hud_y)

    -- Revenue / Expense
    lurek.render.setColor(0.5, 0.9, 0.5, 1)
    text_("Rev: " .. total_revenue, 140, hud_y)
    lurek.render.setColor(0.9, 0.5, 0.5, 1)
    text_("Exp: " .. total_expense, 250, hud_y)

    -- Trains
    lurek.render.setColor(0.7, 0.8, 1, 1)
    text_("Trains: " .. #trains .. "/" .. MAX_TRAINS, 360, hud_y)

    -- Stations
    lurek.render.setColor(0.8, 0.7, 0.2, 1)
    text_("Stations: " .. #stations, 500, hud_y)

    -- Speed
    lurek.render.setColor(1, 1, 1, 1)
    text_("Speed: x" .. game_speed, 630, hud_y)

    -- Mode indicator
    local mode_text = "Mode: TRACK (click)"
    if route_pick then
        mode_text = "SELECT 2nd STATION"
    elseif mode == "station" then
        mode_text = "Mode: STATION (click town)"
    elseif mode == "signal" then
        mode_text = "Mode: SIGNAL (click track)"
    end
    lurek.render.setColor(1, 1, 0.6, 1)
    text_(mode_text, 10, hud_y + 18)

    -- Goal tracker
    local goal_pct = math.min(gold / 1000, 1) * 100
    lurek.render.setColor(0.6, 0.6, 0.6, 1)
    text_(string.format("Goal: %d/1000 gold (%.0f%%)", gold, goal_pct), 360, hud_y + 18)

    -- FPS
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.5, 0.5, 0.5, 1)
    text_("FPS: " .. fps, 740, hud_y + 18)

    -- Goods legend (bottom right)
    for i = 1, 3 do
        local gc = GOOD_COLORS[i]
        lurek.render.setColor(gc[1], gc[2], gc[3], 1)
        rect(640, hud_y + 36 + (i - 1) * 14, 10, 10)
        lurek.render.setColor(0.8, 0.8, 0.8, 1)
        text_(GOOD_NAMES[i], 655, hud_y + 35 + (i - 1) * 14)
    end

    -- Town info
    for i, tw in ipairs(towns) do
        local prodName = GOOD_NAMES[tw.produces]
        local wantName = GOOD_NAMES[tw.wants]
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        text_(tw.name .. ": " .. prodName .. "→" .. wantName ..
            " [" .. tw.stock .. "]", 10, hud_y + 36 + (i - 1) * 14)
    end
end
