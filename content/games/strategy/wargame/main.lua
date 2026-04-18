-- ============================================================
-- Wargame — Hex-grid turn-based wargame with supply lines
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/wargame
-- ============================================================

local W, H = 880, 600

-- Hex grid (offset coords, flat-top hexes)
local COLS, ROWS = 14, 9
local HEX_W      = 54
local HEX_H      = 48
local OX         = 50
local OY         = 60

local function hex_to_pixel(c, r)
    local x = OX + (c - 1) * HEX_W + (r % 2 == 0 and HEX_W / 2 or 0)
    local y = OY + (r - 1) * HEX_H * 0.75
    return x, y
end

local function pixel_to_hex(px, py)
    local r = math.round and math.round((py - OY) / (HEX_H * 0.75)) + 1
           or math.floor((py - OY) / (HEX_H * 0.75) + 0.5) + 1
    local c_offset = (r % 2 == 0) and HEX_W / 2 or 0
    local c = math.floor((px - OX - c_offset) / HEX_W + 0.5) + 1
    return c, r
end

-- Terrain types
local T_PLAIN    = 0
local T_FOREST   = 1   -- def +1, mov -1
local T_MOUNTAIN = 2   -- def +2, impassable for tanks
local T_CITY     = 3   -- def +2, supply source

-- Simple map (cols × rows)
local MAP = {}
for r = 1, ROWS do
    MAP[r] = {}
    for c = 1, COLS do MAP[r][c] = T_PLAIN end
end
-- Add terrain variety
local function set(c, r, t)
    if MAP[r] and c >= 1 and c <= COLS then MAP[r][c] = t end
end
set(3,2,T_FOREST) ; set(4,2,T_FOREST) ; set(5,3,T_FOREST)
set(8,4,T_MOUNTAIN); set(9,4,T_MOUNTAIN); set(9,5,T_MOUNTAIN)
set(2,7,T_CITY)   ; set(10,3,T_CITY)   ; set(12,7,T_CITY)
set(6,1,T_FOREST) ; set(7,2,T_FOREST)

-- Unit types
local UT = {
    infantry  = { hp = 10, atk = 5, def = 1, mov = 2, rng = 1, icon = "INF" },
    tank      = { hp = 16, atk = 9, def = 2, mov = 3, rng = 1, icon = "TNK" },
    artillery = { hp = 8,  atk = 12, def = 0, mov = 1, rng = 3, icon = "ART" },
    recon     = { hp = 6,  atk = 3,  def = 0, mov = 4, rng = 2, icon = "RCN" },
}

-- Units
local units   = {}
local next_id = 1
local selected_unit = nil
local reachable     = {}
local attackable    = {}
local turn    = "player"   -- player | enemy
local state   = "select"   -- select | move | attack | enemy_turn | win | lose
local score   = 0
local log     = {}

local attack_sparks = nil
local death_sparks  = nil
local move_dust     = nil

local function add_log(m)
    table.insert(log, { t = m, timer = 4.0 })
    if #log > 5 then table.remove(log, 1) end
end

local function new_unit(c, r, utype, team)
    local def = UT[utype]
    units[#units + 1] = {
        id    = next_id,
        kind  = utype,
        team  = team,
        c     = c, r = r,
        hp    = def.hp, maxHp = def.hp,
        atk   = def.atk, def = def.def,
        mov   = def.mov, rng  = def.rng,
        icon  = def.icon,
        moved = false, attacked = false,
    }
    next_id = next_id + 1
end

local function find_unit(c, r)
    for _, u in ipairs(units) do if u.c == c and u.r == r and u.hp > 0 then return u end end
end

local function hex_dist(c1, r1, c2, r2)
    -- Convert offset to cube coords
    local function to_cube(c, r)
        local x = c - (r - (r % 2)) / 2
        local z = r
        return x, -x - z, z
    end
    local ax, ay, az = to_cube(c1, r1)
    local bx, by, bz = to_cube(c2, r2)
    return math.max(math.abs(ax-bx), math.abs(ay-by), math.abs(az-bz))
end

local function get_reachable(u)
    local tiles = {}
    for r = 1, ROWS do
        for c = 1, COLS do
            if hex_dist(u.c, u.r, c, r) <= u.mov and not find_unit(c, r) then
                local ter = MAP[r][c]
                if ter ~= T_MOUNTAIN or u.kind ~= "tank" then
                    tiles[#tiles + 1] = { c = c, r = r }
                end
            end
        end
    end
    return tiles
end

local function get_attackable(u)
    local tiles = {}
    for r = 1, ROWS do
        for c = 1, COLS do
            if hex_dist(u.c, u.r, c, r) >= 1 and hex_dist(u.c, u.r, c, r) <= u.rng then
                tiles[#tiles + 1] = { c = c, r = r }
            end
        end
    end
    return tiles
end

local function do_attack(att, target)
    local ter_def = (MAP[target.r][target.c] == T_FOREST and 1 or 0)
                  + (MAP[target.r][target.c] == T_MOUNTAIN and 2 or 0)
                  + (MAP[target.r][target.c] == T_CITY and 2 or 0)
    local dmg = math.max(1, att.atk - target.def - ter_def)
    target.hp = target.hp - dmg
    add_log(att.team .. " " .. att.icon .. " → " .. target.team .. " " .. target.icon .. " -" .. dmg)
    local tx, ty = hex_to_pixel(target.c, target.r)
    if attack_sparks then attack_sparks:emit(tx + HEX_W/2, ty + HEX_H/2, 8) end
    if target.hp <= 0 then
        add_log(target.icon .. " destroyed!")
        local ex, ey = hex_to_pixel(target.c, target.r)
        if death_sparks then death_sparks:emit(ex + HEX_W/2, ey + HEX_H/2, 12) end
        if target.team == "enemy" then score = score + 25 end
        for i, u in ipairs(units) do if u.id == target.id then table.remove(units, i) break end end
    end
end

local enemy_timer = 0

local function enemy_ai(dt)
    enemy_timer = enemy_timer - dt
    if enemy_timer > 0 then return end
    enemy_timer = 0.5

    local acted = false
    for _, e in ipairs(units) do
        if e.team ~= "enemy" or e.hp <= 0 or e.attacked then goto cont end

        -- Try attack
        local atiles = get_attackable(e)
        for _, t in ipairs(atiles) do
            local target = find_unit(t.c, t.r)
            if target and target.team == "player" then
                do_attack(e, target)
                e.attacked = true
                acted = true
                goto cont
            end
        end

        -- Move toward nearest player
        if not e.moved then
            local best_pu, bd = nil, 1e9
            for _, pu in ipairs(units) do
                if pu.team == "player" and pu.hp > 0 then
                    local d = hex_dist(e.c, e.r, pu.c, pu.r)
                    if d < bd then best_pu = pu ; bd = d end
                end
            end
            if best_pu then
                local mtiles = get_reachable(e)
                local best_mt, bmd = nil, 1e9
                for _, mt in ipairs(mtiles) do
                    local d = hex_dist(mt.c, mt.r, best_pu.c, best_pu.r)
                    if d < bmd then best_mt = mt ; bmd = d end
                end
                if best_mt then
                    e.c = best_mt.c ; e.r = best_mt.r ; e.moved = true
                    acted = true
                end
            end
        end

        ::cont::
    end

    local all_done = true
    for _, e in ipairs(units) do
        if e.team == "enemy" and e.hp > 0 and not (e.moved and e.attacked) then
            all_done = false ; break
        end
    end

    if all_done or not acted then
        -- End enemy turn
        turn = "player"
        state = "select"
        for _, u in ipairs(units) do
            if u.team == "player" then u.moved = false ; u.attacked = false end
        end
        -- Check win/lose
        local p, en = 0, 0
        for _, u in ipairs(units) do
            if u.team == "player" then p = p + 1 else en = en + 1 end
        end
        if en == 0 then state = "win"  end
        if p  == 0 then state = "lose" end
    end
end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("click",     "mouse1")
lurek.input.bind("end_turn",  "return")
lurek.input.bind("quit",      "escape")

local hover_c, hover_r = 0, 0

-- ── Init ──────────────────────────────────────────────────
lurek.init(function()
    lurek.window.setTitle("Wargame — Lurek2D")
    lurek.render.setBackgroundColor(0.07, 0.07, 0.05, 1.0)
    math.randomseed(os.time())

    attack_sparks = lurek.particles.newSystem({
        maxParticles = 40,
        emitRate = 0, lifetime = {0.2,0.5}, speed = {40,120},
        startColor = {1,0.6,0.1,1}, endColor = {0.6,0.1,0,0},
        startSize = 4, endSize = 1, spread = math.pi*2
    })
    death_sparks = lurek.particles.newSystem({
        maxParticles = 30,
        emitRate = 0, lifetime = {0.3,0.7}, speed = {60,200},
        startColor = {0.9,0.3,0.1,1}, endColor = {0.3,0,0,0},
        startSize = 6, endSize = 1, spread = math.pi*2
    })
    move_dust = lurek.particles.newSystem({
        maxParticles = 16,
        emitRate = 0, lifetime = {0.2,0.4}, speed = {8,25},
        startColor = {0.6,0.5,0.3,0.5}, endColor = {0.4,0.3,0.2,0},
        startSize = 3, endSize = 1, spread = math.pi*2
    })

    -- Player units (left half)
    new_unit(2,2,"infantry","player"); new_unit(2,5,"infantry","player")
    new_unit(1,4,"tank","player");     new_unit(3,7,"tank","player")
    new_unit(1,8,"artillery","player");new_unit(2,3,"recon","player")

    -- Enemy units (right half)
    new_unit(13,2,"infantry","enemy"); new_unit(13,6,"infantry","enemy")
    new_unit(14,4,"tank","enemy");     new_unit(12,8,"tank","enemy")
    new_unit(14,8,"artillery","enemy");new_unit(13,3,"recon","enemy")
end)

-- ── Process ───────────────────────────────────────────────
lurek.process(function(dt)
    if attack_sparks then attack_sparks:update(dt) end
    if death_sparks  then death_sparks:update(dt)  end
    if move_dust     then move_dust:update(dt)     end

    for i = #log, 1, -1 do
        log[i].timer = log[i].timer - dt
        if log[i].timer <= 0 then table.remove(log, i) end
    end

    if lurek.input.isActionJustPressed("quit") then lurek.signal.quit() return end
    if state == "win" or state == "lose" then return end

    if state == "enemy_turn" then enemy_ai(dt) return end

    local mx, my = lurek.input.getMousePosition()
    hover_c, hover_r = pixel_to_hex(mx, my)

    if lurek.input.isActionJustPressed("end_turn") and turn == "player" then
        for _, u in ipairs(units) do
            if u.team == "enemy" then u.moved = false ; u.attacked = false end
        end
        turn  = "enemy"
        state = "enemy_turn"
        enemy_timer = 0
        selected_unit = nil ; reachable = {} ; attackable = {}
        return
    end

    if lurek.input.isActionJustPressed("click") then
        local hc, hr = hover_c, hover_r
        if hc < 1 or hc > COLS or hr < 1 or hr > ROWS then return end

        if state == "select" then
            local u = find_unit(hc, hr)
            if u and u.team == "player" and not (u.moved and u.attacked) then
                selected_unit = u
                reachable  = not u.moved    and get_reachable(u)   or {}
                attackable = not u.attacked and get_attackable(u)  or {}
                state = "move"
            end

        elseif state == "move" then
            -- Check move
            for _, t in ipairs(reachable) do
                if t.c == hc and t.r == hr then
                    local ox, oy = hex_to_pixel(selected_unit.c, selected_unit.r)
                    if move_dust then move_dust:emit(ox + HEX_W/2, oy + HEX_H/2, 5) end
                    selected_unit.c = hc ; selected_unit.r = hr
                    selected_unit.moved = true
                    reachable = {}
                    attackable = not selected_unit.attacked and get_attackable(selected_unit) or {}
                    state = "attack"
                    return
                end
            end
            -- Check attack
            for _, t in ipairs(attackable) do
                if t.c == hc and t.r == hr then
                    local target = find_unit(hc, hr)
                    if target and target.team == "enemy" then
                        do_attack(selected_unit, target)
                        selected_unit.attacked = true
                        selected_unit = nil ; reachable = {} ; attackable = {}
                        state = "select"

                        local p, en = 0, 0
                        for _, u in ipairs(units) do if u.team == "player" then p=p+1 else en=en+1 end end
                        if en == 0 then state = "win"  end
                        if p  == 0 then state = "lose" end
                        return
                    end
                end
            end
            -- Deselect
            selected_unit = nil ; reachable = {} ; attackable = {} ; state = "select"

        elseif state == "attack" then
            for _, t in ipairs(attackable) do
                if t.c == hc and t.r == hr then
                    local target = find_unit(hc, hr)
                    if target and target.team == "enemy" then
                        do_attack(selected_unit, target)
                        selected_unit.attacked = true
                    end
                end
            end
            selected_unit = nil ; reachable = {} ; attackable = {} ; state = "select"
            local p, en = 0, 0
            for _, u in ipairs(units) do if u.team == "player" then p=p+1 else en=en+1 end end
            if en == 0 then state = "win"  end
            if p  == 0 then state = "lose" end
        end
    end
end)

-- ── Render world ──────────────────────────────────────────
lurek.render(function()
    -- Hex tiles
    for r = 1, ROWS do
        for c = 1, COLS do
            local ter = MAP[r][c]
            local col = ter == T_FOREST   and {0.15,0.3,0.12,1}
                     or ter == T_MOUNTAIN and {0.4,0.35,0.3,1}
                     or ter == T_CITY     and {0.3,0.3,0.45,1}
                     or                       {0.1,0.14,0.1,1}
            local hx, hy = hex_to_pixel(c, r)
            lurek.render.drawRect(hx, hy, HEX_W - 2, HEX_H - 2, { color = col })
        end
    end

    -- Reachable / attackable highlight
    for _, t in ipairs(reachable) do
        local hx, hy = hex_to_pixel(t.c, t.r)
        lurek.render.drawRect(hx, hy, HEX_W-2, HEX_H-2, { color = {0.3,0.6,1.0,0.3} })
    end
    for _, t in ipairs(attackable) do
        local hx, hy = hex_to_pixel(t.c, t.r)
        lurek.render.drawRect(hx, hy, HEX_W-2, HEX_H-2, { color = {0.9,0.2,0.2,0.3} })
    end

    -- Hover
    if hover_c >= 1 and hover_c <= COLS and hover_r >= 1 and hover_r <= ROWS then
        local hx, hy = hex_to_pixel(hover_c, hover_r)
        lurek.render.drawRect(hx, hy, HEX_W-2, HEX_H-2, { color = {1,1,1,0.12} })
    end

    -- Units
    for _, u in ipairs(units) do
        if u.hp <= 0 then goto skip end
        local hx, hy = hex_to_pixel(u.c, u.r)
        local col = u.team == "player" and {0.3,0.6,1.0,1} or {0.8,0.3,0.2,1}
        if u.moved and u.attacked then col[4] = 0.45 end
        lurek.render.drawRect(hx + 5, hy + 5, HEX_W - 12, HEX_H - 12, { color = col })
        lurek.render.drawText(u.icon, hx + 7, hy + 14, { color = {1,1,1,1}, size = 10 })
        -- HP
        lurek.render.drawRect(hx + 2, hy + HEX_H - 10, HEX_W - 6, 5, { color = {0.2,0,0,1} })
        lurek.render.drawRect(hx + 2, hy + HEX_H - 10, math.floor((HEX_W-6) * u.hp / u.maxHp), 5, { color = {0.2,0.8,0.2,1} })

        if selected_unit and selected_unit.id == u.id then
            lurek.render.drawRect(hx + 1, hy + 1, HEX_W-4, HEX_H-4, { color = {1,1,0.3,0.3} })
        end
        ::skip::
    end

    if attack_sparks then attack_sparks:draw() end
    if death_sparks  then death_sparks:draw()  end
    if move_dust     then move_dust:draw()     end
end)

-- ── Render UI ─────────────────────────────────────────────
lurek.render_ui(function()
    lurek.render.drawRect(0, 0, W, OY - 4, { color = {0.08,0.08,0.06,1} })
    local turn_col = turn == "player" and {0.3,0.9,0.4,1} or {0.9,0.3,0.3,1}
    lurek.render.drawText(turn == "player" and "YOUR TURN" or "ENEMY TURN", 12, 8, { color = turn_col, size = 16 })
    lurek.render.drawText("Score: " .. score, 400, 8, { color = {1,1,1,1}, size = 14 })
    lurek.render.drawText("Enter=end turn  Esc=quit", 600, 8, { color = {0.4,0.4,0.4,1}, size = 12 })

    -- Combat log
    for i, msg in ipairs(log) do
        local a = math.min(1.0, msg.timer)
        lurek.render.drawText(msg.t, 12, H - 12 - (i-1)*16, { color = {0.8,0.8,0.6,a}, size = 11 })
    end

    if state == "win" then
        lurek.render.drawRect(240, 220, 400, 100, { color = {0,0,0,0.88} })
        lurek.render.drawText("VICTORY!", 340, 248, { color = {1,0.9,0.2,1}, size = 36 })
    elseif state == "lose" then
        lurek.render.drawRect(240, 220, 400, 100, { color = {0,0,0,0.88} })
        lurek.render.drawText("DEFEATED", 320, 248, { color = {0.9,0.2,0.2,1}, size = 34 })
    end
end)
