-- ============================================================
-- Tower Defense — Classic path-based tower defense
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/tower_defense
-- ============================================================

local W, H = 800, 600
local CELL  = 40
local COLS  = 18
local ROWS  = 12
local OX    = 20
local OY    = 50

-- Map path (list of {c,r} waypoints)
local PATH_PTS = {
    {1,6}, {3,6}, {3,2}, {7,2}, {7,10}, {12,10}, {12,4}, {16,4}, {16,9}, {18,9}
}

-- Tower types
local TOWER_TYPES = {
    basic  = { cost = 50,  dmg = 8,  range = 90,  rate = 1.0, color = {0.3,0.5,0.8,1}, name = "Basic"  },
    rapid  = { cost = 80,  dmg = 4,  range = 70,  rate = 3.0, color = {0.2,0.8,0.4,1}, name = "Rapid"  },
    sniper = { cost = 120, dmg = 25, range = 160, rate = 0.5, color = {0.7,0.3,0.8,1}, name = "Sniper" },
    splash = { cost = 150, dmg = 12, range = 80,  rate = 0.8, splash = 60, color = {0.9,0.5,0.1,1}, name = "Splash" },
}
local TYPE_ORDER = { "basic", "rapid", "sniper", "splash" }
local sel_type   = 1

-- State
local gold        = 200
local lives       = 20
local wave_num    = 0
local wave_cd     = 8.0
local spawning    = false
local spawn_q     = {}
local spawn_timer = 0
local score       = 0
local game_state  = "build"   -- build | combat | gameover | victory

local towers  = {}
local enemies = {}
local bullets = {}

-- Build map: CELL grid, {type} or nil
local build_map = {}
for r = 1, ROWS do build_map[r] = {} end

-- Mark path cells as non-buildable
local path_cells = {}
local function mark_path()
    for i = 1, #PATH_PTS - 1 do
        local a, b = PATH_PTS[i], PATH_PTS[i+1]
        if a.c == b.c then
            local r1, r2 = math.min(a.r, b.r), math.max(a.r, b.r)
            for r = r1, r2 do path_cells[r .. "," .. a.c] = true end
        else
            local c1, c2 = math.min(a.c, b.c), math.max(a.c, b.c)
            for c = c1, c2 do path_cells[a.r .. "," .. c] = true end
        end
    end
end
mark_path()

local function is_path(c, r) return path_cells[r .. "," .. c] == true end

-- Get path world position at parametric t (0=start, 1=end)
local function path_world(progress)
    -- progress in cells along path
    local total = 0
    local segs  = {}
    for i = 1, #PATH_PTS - 1 do
        local a, b = PATH_PTS[i], PATH_PTS[i+1]
        local d = math.abs(a.c - b.c) + math.abs(a.r - b.r)
        segs[i] = { a = a, b = b, len = d }
        total = total + d
    end
    local rem = progress
    for _, seg in ipairs(segs) do
        if rem <= seg.len then
            local t = rem / seg.len
            local cx = seg.a.c + (seg.b.c - seg.a.c) * t
            local cr = seg.a.r + (seg.b.r - seg.a.r) * t
            return OX + (cx - 1) * CELL + CELL/2, OY + (cr - 1) * CELL + CELL/2, total
        end
        rem = rem - seg.len
    end
    -- At end
    local last = PATH_PTS[#PATH_PTS]
    return OX + (last.c - 1) * CELL + CELL/2, OY + (last.r - 1) * CELL + CELL/2, total
end

local path_total_len = 0
for i = 1, #PATH_PTS - 1 do
    local a, b = PATH_PTS[i], PATH_PTS[i+1]
    path_total_len = path_total_len + math.abs(a.c - b.c) + math.abs(a.r - b.r)
end

local next_eid = 1
local function spawn_enemy(hp, spd, reward)
    enemies[#enemies + 1] = {
        id       = next_eid,
        progress = 0,
        hp       = hp,
        maxHp    = hp,
        speed    = spd,
        reward   = reward,
    }
    next_eid = next_eid + 1
end

local function queue_wave(wn)
    spawn_q = {}
    local count = 5 + wn * 3
    local hp    = 20 + wn * 12
    local spd   = 2.0 + wn * 0.3
    for _ = 1, count do
        spawn_q[#spawn_q + 1] = { hp = hp + math.random(-4, 4), spd = spd, reward = 8 + wn }
    end
end

-- Particle systems
local hit_sparks  = nil
local death_burst = nil
local place_flash = nil

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("place",      "mouse1")
lurek.input.bind("next_type",  "tab")
lurek.input.bind("prev_type",  "q")
lurek.input.bind("send_wave",  "space")
lurek.input.bind("quit",       "escape")

local hover_c, hover_r = 0, 0

-- ── Init ──────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Tower Defense — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.08, 0.05, 1.0)
    math.randomseed(os.time())

    hit_sparks = lurek.particle.newSystem({
        maxParticles = 40,
        emitRate     = 0,
        lifetime     = { 0.1, 0.3 },
        speed        = { 20, 60 },
        startColor   = { 1.0, 0.7, 0.2, 1.0 },
        endColor     = { 0.6, 0.1, 0.0, 0.0 },
        startSize    = 4, endSize = 1,
        spread       = math.pi * 2,
    })

    death_burst = lurek.particle.newSystem({
        maxParticles = 30,
        emitRate     = 0,
        lifetime     = { 0.2, 0.6 },
        speed        = { 40, 130 },
        startColor   = { 0.9, 0.3, 0.1, 1.0 },
        endColor     = { 0.4, 0.0, 0.0, 0.0 },
        startSize    = 5, endSize = 1,
        spread       = math.pi * 2,
    })

    place_flash = lurek.particle.newSystem({
        maxParticles = 12,
        emitRate     = 0,
        lifetime     = { 0.2, 0.4 },
        speed        = { 15, 40 },
        startColor   = { 0.4, 0.7, 1.0, 0.9 },
        endColor     = { 0.1, 0.3, 0.6, 0.0 },
        startSize    = 4, endSize = 1,
        spread       = math.pi * 2,
    })
end

-- ── Process ───────────────────────────────────────────────
lurek.process(function(dt)
    if hit_sparks  then hit_sparks:update(dt)  end
    if death_burst then death_burst:update(dt) end
    if place_flash then place_flash:update(dt) end

    if lurek.input.isActionJustPressed("quit") then lurek.event.quit() return end
    if game_state == "gameover" or game_state == "victory" then return end

    local mx, my = lurek.input.getMousePosition()
    hover_c = math.floor((mx - OX) / CELL) + 1
    hover_r = math.floor((my - OY) / CELL) + 1

    -- Tower type cycling
    if lurek.input.isActionJustPressed("next_type") then sel_type = (sel_type % #TYPE_ORDER) + 1 end
    if lurek.input.isActionJustPressed("prev_type") then sel_type = (sel_type - 2) % #TYPE_ORDER + 1 end

    -- Place tower
    if lurek.input.isActionJustPressed("place") then
        local c, r = hover_c, hover_r
        if c >= 1 and c <= COLS and r >= 1 and r <= ROWS and not is_path(c, r) and not build_map[r][c] then
            local ttype = TYPE_ORDER[sel_type]
            local td    = TOWER_TYPES[ttype]
            if gold >= td.cost then
                gold = gold - td.cost
                build_map[r][c] = ttype
                towers[#towers + 1] = {
                    c = c, r = r,
                    x = OX + (c-1)*CELL + CELL/2,
                    y = OY + (r-1)*CELL + CELL/2,
                    ttype   = ttype,
                    cooldown = 0,
                }
                local wx = OX + (c-1)*CELL + CELL/2
                local wy = OY + (r-1)*CELL + CELL/2
                if place_flash then place_flash:emit(wx, wy, 8) end
            end
        end
    end

    -- Send wave
    if lurek.input.isActionJustPressed("send_wave") and game_state == "build" then
        wave_num  = wave_num + 1
        queue_wave(wave_num)
        game_state = "combat"
        spawn_timer = 0
        spawning   = true
    end

    if game_state == "combat" then
        -- Spawn enemies
        if spawning and #spawn_q > 0 then
            spawn_timer = spawn_timer - dt
            if spawn_timer <= 0 then
                spawn_timer = 0.4
                local e = table.remove(spawn_q, 1)
                spawn_enemy(e.hp, e.spd, e.reward)
                if #spawn_q == 0 then spawning = false end
            end
        end

        -- Move enemies
        for i = #enemies, 1, -1 do
            local e = enemies[i]
            e.progress = e.progress + e.speed * dt
            if e.progress >= path_total_len then
                lives = lives - 1
                table.remove(enemies, i)
                if lives <= 0 then game_state = "gameover" end
            end
        end

        -- Tower firing
        for _, tower in ipairs(towers) do
            tower.cooldown = tower.cooldown - dt
            if tower.cooldown <= 0 then
                local td = TOWER_TYPES[tower.ttype]
                local best, bd = nil, 1e9
                for _, e in ipairs(enemies) do
                    local ex, ey = path_world(e.progress)
                    local d = math.sqrt((tower.x-ex)^2 + (tower.y-ey)^2)
                    if d <= td.range and e.progress > bd or (not best and d <= td.range) then
                        -- pick furthest along path
                        if not best or e.progress > best.progress then
                            if d <= td.range then best = e end
                        end
                    end
                end
                if best then
                    tower.cooldown = 1 / td.rate
                    local ex, ey = path_world(best.progress)
                    bullets[#bullets + 1] = {
                        x = tower.x, y = tower.y,
                        tx = ex, ty = ey,
                        t  = 0.12,
                        tmax = 0.12,
                        dmg    = td.dmg,
                        splash = td.splash,
                        target = best,
                        tower  = tower,
                    }
                end
            end
        end

        -- Move bullets
        for i = #bullets, 1, -1 do
            local b = bullets[i]
            b.t = b.t - dt
            if b.t <= 0 then
                -- Deal damage
                if b.target and b.target.hp > 0 then
                    if b.splash then
                        local bx, by = path_world(b.target.progress)
                        for _, e in ipairs(enemies) do
                            local ex, ey = path_world(e.progress)
                            if math.sqrt((bx-ex)^2+(by-ey)^2) < b.splash then
                                e.hp = e.hp - b.dmg
                                if hit_sparks then hit_sparks:emit(ex, ey, 3) end
                            end
                        end
                    else
                        b.target.hp = b.target.hp - b.dmg
                        if hit_sparks then hit_sparks:emit(b.tx, b.ty, 3) end
                    end
                end
                table.remove(bullets, i)
            end
        end

        -- Remove dead enemies
        for i = #enemies, 1, -1 do
            if enemies[i].hp <= 0 then
                local ex, ey = path_world(enemies[i].progress)
                if death_burst then death_burst:emit(ex, ey, 6) end
                gold  = gold + enemies[i].reward
                score = score + 10
                table.remove(enemies, i)
            end
        end

        -- Check wave complete
        if not spawning and #enemies == 0 and #spawn_q == 0 then
            if wave_num >= 6 then
                game_state = "victory"
            else
                game_state = "build"
                gold = gold + 30
            end
        end
    end
end)

-- ── Render world ──────────────────────────────────────────
lurek.render(function()
    -- Grid
    for r = 1, ROWS do
        for c = 1, COLS do
            local col = is_path(c, r) and {0.22,0.18,0.12,1} or {0.1,0.14,0.1,1}
            lurek.render.rectangle(OX + (c-1)*CELL, OY + (r-1)*CELL, CELL-1, CELL-1, { color = col })
        end
    end

    -- Hover
    if hover_c >= 1 and hover_c <= COLS and hover_r >= 1 and hover_r <= ROWS
       and not is_path(hover_c, hover_r) and not build_map[hover_r][hover_c] then
        lurek.render.rectangle(OX + (hover_c-1)*CELL, OY + (hover_r-1)*CELL, CELL-1, CELL-1, { color = {1,1,1,0.18} })
    end

    -- Path direction arrows (simple)
    for i = 1, #PATH_PTS - 1 do
        local a = PATH_PTS[i]
        local ax = OX + (a.c-1)*CELL + CELL/2 - 3
        local ay = OY + (a.r-1)*CELL + CELL/2 - 3
        lurek.render.rectangle(ax, ay, 6, 6, { color = {0.4,0.35,0.2,1} })
    end

    -- Towers
    for _, t in ipairs(towers) do
        local td  = TOWER_TYPES[t.ttype]
        lurek.render.rectangle(t.x - CELL/2 + 4, t.y - CELL/2 + 4, CELL - 10, CELL - 10, { color = td.color })
        lurek.render.circle(t.x, t.y, 5, { color = {1,1,1,0.7}, segments = 6 })
    end

    -- Enemies
    for _, e in ipairs(enemies) do
        local ex, ey = path_world(e.progress)
        lurek.render.rectangle(ex - 8, ey - 8, 16, 16, { color = {0.8,0.2,0.2,1} })
        local hw = math.floor(16 * e.hp / e.maxHp)
        lurek.render.rectangle(ex - 8, ey - 12, hw, 3, { color = {0.2,0.8,0.2,1} })
    end

    -- Bullets
    for _, b in ipairs(bullets) do
        local t  = 1.0 - b.t / b.tmax
        local bx = b.x + (b.tx - b.x) * t
        local by = b.y + (b.ty - b.y) * t
        lurek.render.rectangle(bx - 2, by - 2, 5, 5, { color = {1,0.9,0.3,1} })
    end

    if hit_sparks  then hit_sparks:draw()  end
    if death_burst then death_burst:draw() end
    if place_flash then place_flash:draw() end
end)

-- ── Render UI ─────────────────────────────────────────────
function lurek.render_ui()
    -- Top bar
    lurek.render.rectangle(0, 0, W, OY - 2, { color = {0.08,0.1,0.08,1} })
    lurek.render.print("Gold: " .. gold, 12, 6, { color = {1,0.85,0.2,1}, size = 14 })
    lurek.render.print("Lives: " .. lives, 130, 6, { color = {0.3,1,0.3,1}, size = 14 })
    lurek.render.print("Wave: " .. wave_num .. "/6", 250, 6, { color = {0.7,0.7,1,1}, size = 14 })
    lurek.render.print("Score: " .. score, 370, 6, { color = {1,1,1,1}, size = 14 })

    -- Selected tower info
    local td = TOWER_TYPES[TYPE_ORDER[sel_type]]
    lurek.render.print("[" .. td.name .. " $" .. td.cost .. "]  Tab=next  Q=prev  Space=start wave", 480, 6, { color = {0.5,0.7,1.0,1}, size = 12 })

    if game_state == "build" then
        lurek.render.print("BUILD PHASE — place towers then press SPACE", 220, H - 18, { color = {0.4,0.8,0.4,1}, size = 13 })
    elseif game_state == "combat" then
        lurek.render.print("WAVE " .. wave_num .. " — enemies: " .. #enemies, 300, H - 18, { color = {1,0.5,0.3,1}, size = 13 })
    elseif game_state == "gameover" then
        lurek.render.rectangle(180, 220, 440, 100, { color = {0,0,0,0.88} })
        lurek.render.print("GAME OVER", 290, 245, { color = {0.9,0.2,0.2,1}, size = 36 })
        lurek.render.print("Score: " .. score, 340, 295, { color = {1,1,1,1}, size = 18 })
    elseif game_state == "victory" then
        lurek.render.rectangle(180, 220, 440, 100, { color = {0,0,0,0.88} })
        lurek.render.print("VICTORY!", 300, 245, { color = {1,0.9,0.2,1}, size = 36 })
        lurek.render.print("Score: " .. score, 340, 295, { color = {1,1,1,1}, size = 18 })
    end
end
