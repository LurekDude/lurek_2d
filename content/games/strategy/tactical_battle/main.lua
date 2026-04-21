-- ============================================================
-- Tactical Battle — Turn-based grid squad tactics
-- Category: strategy
-- Engine:   Lurek2D
-- Run with: cargo run -- content/games/strategy/tactical_battle
-- ============================================================

local COLS, ROWS = 12, 9
local CELL = 56
local OX   = 60
local OY   = 50
local W    = COLS * CELL + OX * 2
local H    = ROWS * CELL + OY + 70

-- Tile types
local TILE_PLAIN  = 0
local TILE_FOREST = 1  -- +1 defense
local TILE_WATER  = 2  -- impassable

-- Unit types
local UT = {
    soldier  = { hp = 20, atk = 6, def = 1, mov = 3, icon = "S" },
    archer   = { hp = 14, atk = 9, def = 0, mov = 2, rng = 3, icon = "A" },
    knight   = { hp = 30, atk = 7, def = 3, mov = 4, icon = "K" },
    mage     = { hp = 12, atk = 12, def = 0, mov = 2, rng = 2, aoe = true, icon = "M" },
}

local MAP = {
    {0,0,0,0,0,0,0,0,0,0,0,0},
    {0,1,1,0,0,2,2,0,0,1,1,0},
    {0,1,0,0,0,2,0,0,0,0,1,0},
    {0,0,0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0,0,0},
    {0,0,1,0,0,0,0,0,0,1,0,0},
    {0,0,1,0,0,2,0,0,0,1,0,0},
    {0,0,0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0,0,0},
}

local units    = {}
local next_id  = 1
local turn     = "player"   -- player | enemy
local state    = "select"   -- select | move | attack | enemy_turn | win | lose
local selected = nil
local move_tiles  = {}
local attack_tiles= {}
local log_msgs = {}
local score    = 0

-- Particle systems
local attack_sparks = nil
local death_burst   = nil
local move_dust     = nil

local function new_id()
    local id = next_id ; next_id = next_id + 1 ; return id
end

local function add_log(m)
    table.insert(log_msgs, { t = m, timer = 4.0 })
    if #log_msgs > 4 then table.remove(log_msgs, 1) end
end

local function spawn_unit(c, r, utype, team)
    local def = UT[utype]
    units[#units + 1] = {
        id    = new_id(),
        kind  = utype,
        team  = team,
        c     = c, r = r,
        hp    = def.hp, maxHp = def.hp,
        atk   = def.atk, def = def.def,
        mov   = def.mov, rng  = def.rng or 1,
        aoe   = def.aoe or false,
        icon  = def.icon,
        moved = false, attacked = false,
    }
end

local function find_unit(c, r)
    for _, u in ipairs(units) do
        if u.c == c and u.r == r and u.hp > 0 then return u end
    end
end

local function unit_at_tile(u, c, r) return u.c == c and u.r == r end

local function reachable_tiles(u)
    local tiles = {}
    for dc = -u.mov, u.mov do
        for dr = -u.mov, u.mov do
            if math.abs(dc) + math.abs(dr) <= u.mov then
                local nc, nr = u.c + dc, u.r + dr
                if nc >= 1 and nc <= COLS and nr >= 1 and nr <= ROWS then
                    if MAP[nr][nc] ~= TILE_WATER and not find_unit(nc, nr) then
                        tiles[#tiles + 1] = { c = nc, r = nr }
                    end
                end
            end
        end
    end
    return tiles
end

local function attack_range_tiles(u)
    local tiles = {}
    for dc = -u.rng, u.rng do
        for dr = -u.rng, u.rng do
            if math.abs(dc) + math.abs(dr) <= u.rng and not (dc == 0 and dr == 0) then
                local nc, nr = u.c + dc, u.r + dr
                if nc >= 1 and nc <= COLS and nr >= 1 and nr <= ROWS then
                    tiles[#tiles + 1] = { c = nc, r = nr }
                end
            end
        end
    end
    return tiles
end

local function do_attack(attacker, target)
    local terrain_def = (MAP[target.r][target.c] == TILE_FOREST) and 1 or 0
    local dmg = math.max(0, attacker.atk - target.def - terrain_def)
    target.hp = target.hp - dmg
    add_log(attacker.team .. " " .. attacker.kind .. " → " .. target.team .. " " .. target.kind .. " (" .. dmg .. " dmg)")
    if attack_sparks then
        local tx = OX + (target.c - 1) * CELL + CELL/2 - CELL/2
        local ty = OY + (target.r - 1) * CELL + CELL/2 - OY/2
        attack_sparks:emit(tx, ty, 8)
    end
    if target.hp <= 0 then
        add_log(target.kind .. " defeated!")
        if death_burst then
            death_burst:emit(OX + (target.c-1)*CELL + CELL/2 - CELL/2, OY + (target.r-1)*CELL + CELL/2 - OY/2, 12)
        end
        if target.team == "enemy" then score = score + 20 end
        for i, u in ipairs(units) do if u.id == target.id then table.remove(units, i) break end end
    end
end

local function end_player_turn()
    -- Reset player unit flags
    for _, u in ipairs(units) do
        if u.team == "player" then u.moved = false ; u.attacked = false end
    end
    turn     = "enemy"
    state    = "enemy_turn"
    selected = nil
    move_tiles  = {}
    attack_tiles= {}
end

local function end_enemy_turn()
    for _, u in ipairs(units) do
        if u.team == "enemy" then u.moved = false ; u.attacked = false end
    end
    turn  = "player"
    state = "select"
    -- Check win / lose
    local p, e = 0, 0
    for _, u in ipairs(units) do
        if u.team == "player" then p = p + 1 else e = e + 1 end
    end
    if e == 0 then state = "win"  ; add_log("Victory!") end
    if p == 0 then state = "lose" ; add_log("Defeated!") end
end

local enemy_think_timer = 0.0

local function enemy_ai(dt)
    enemy_think_timer = enemy_think_timer - dt
    if enemy_think_timer > 0 then return end
    enemy_think_timer = 0.5

    local did_something = false
    for _, e in ipairs(units) do
        if e.team ~= "enemy" or e.hp <= 0 then goto continue end
        if e.attacked then goto continue end

        -- Try to attack
        local atiles = attack_range_tiles(e)
        for _, t in ipairs(atiles) do
            local target = find_unit(t.c, t.r)
            if target and target.team == "player" then
                do_attack(e, target)
                e.attacked = true
                did_something = true
                goto continue
            end
        end

        -- Move toward nearest player unit
        if not e.moved then
            local best, bd = nil, 1e9
            for _, p in ipairs(units) do
                if p.team == "player" and p.hp > 0 then
                    local d = math.abs(p.c - e.c) + math.abs(p.r - e.r)
                    if d < bd then best = p ; bd = d end
                end
            end
            if best then
                local mtiles = reachable_tiles(e)
                local bmtile, bmd = nil, 1e9
                for _, mt in ipairs(mtiles) do
                    local d = math.abs(best.c - mt.c) + math.abs(best.r - mt.r)
                    if d < bmd then bmtile = mt ; bmd = d end
                end
                if bmtile then
                    e.c     = bmtile.c
                    e.r     = bmtile.r
                    e.moved = true
                    did_something = true
                end
            end
        end

        ::continue::
    end

    -- All enemies acted
    local all_done = true
    for _, e in ipairs(units) do
        if e.team == "enemy" and e.hp > 0 and (not e.moved or not e.attacked) then
            all_done = false ; break
        end
    end
    if all_done or not did_something then end_enemy_turn() end
end

-- ── Input bindings ────────────────────────────────────────
lurek.input.bind("click",      "mouse1")
lurek.input.bind("end_turn",   "return")
lurek.input.bind("quit",       "escape")

local hover_c, hover_r = 0, 0

-- ── Init ──────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Tactical Battle — Lurek2D")
    lurek.render.setBackgroundColor(0.06, 0.08, 0.12, 1.0)
    math.randomseed(os.time())

    attack_sparks = lurek.particle.newSystem({
        maxParticles = 40,
        emitRate     = 0,
        lifetime     = { 0.1, 0.4 },
        speed        = { 40, 120 },
        startColor   = { 1.0, 0.7, 0.1, 1.0 },
        endColor     = { 0.8, 0.2, 0.0, 0.0 },
        startSize    = 4, endSize = 1,
        spread       = math.pi * 2,
    })

    death_burst = lurek.particle.newSystem({
        maxParticles = 30,
        emitRate     = 0,
        lifetime     = { 0.3, 0.7 },
        speed        = { 60, 180 },
        startColor   = { 0.9, 0.3, 0.1, 1.0 },
        endColor     = { 0.4, 0.0, 0.0, 0.0 },
        startSize    = 6, endSize = 1,
        spread       = math.pi * 2,
    })

    move_dust = lurek.particle.newSystem({
        maxParticles = 20,
        emitRate     = 0,
        lifetime     = { 0.2, 0.5 },
        speed        = { 10, 30 },
        startColor   = { 0.7, 0.6, 0.4, 0.6 },
        endColor     = { 0.5, 0.4, 0.2, 0.0 },
        startSize    = 4, endSize = 1,
        spread       = math.pi * 2,
    })

    -- Player squad (left side)
    spawn_unit(1, 2, "soldier", "player")
    spawn_unit(1, 5, "soldier", "player")
    spawn_unit(1, 8, "knight",  "player")
    spawn_unit(2, 4, "archer",  "player")
    spawn_unit(2, 6, "mage",    "player")

    -- Enemy squad (right side)
    spawn_unit(12, 2, "soldier", "enemy")
    spawn_unit(12, 5, "soldier", "enemy")
    spawn_unit(12, 8, "knight",  "enemy")
    spawn_unit(11, 4, "archer",  "enemy")
    spawn_unit(11, 6, "mage",    "enemy")
end

-- ── Process ───────────────────────────────────────────────
lurek.process(function(dt)
    if attack_sparks then attack_sparks:update(dt) end
    if death_burst   then death_burst:update(dt)   end
    if move_dust     then move_dust:update(dt)     end

    for i = #log_msgs, 1, -1 do
        log_msgs[i].timer = log_msgs[i].timer - dt
        if log_msgs[i].timer <= 0 then table.remove(log_msgs, i) end
    end

    if lurek.input.isActionJustPressed("quit") then lurek.event.quit() return end
    if state == "win" or state == "lose" then return end

    if state == "enemy_turn" then
        enemy_ai(dt)
        return
    end

    local mx, my = lurek.input.getMousePosition()
    hover_c = math.floor((mx - OX) / CELL) + 1
    hover_r = math.floor((my - OY) / CELL) + 1

    if lurek.input.isActionJustPressed("end_turn") and turn == "player" then
        end_player_turn()
        return
    end

    if lurek.input.isActionJustPressed("click") then
        local hc, hr = hover_c, hover_r
        if hc < 1 or hc > COLS or hr < 1 or hr > ROWS then return end

        if state == "select" then
            local u = find_unit(hc, hr)
            if u and u.team == "player" then
                selected     = u
                move_tiles   = not u.moved    and reachable_tiles(u)   or {}
                attack_tiles = not u.attacked and attack_range_tiles(u) or {}
                state        = "move"
            end

        elseif state == "move" then
            -- Check if clicking move tile
            if selected and not selected.moved then
                for _, t in ipairs(move_tiles) do
                    if t.c == hc and t.r == hr then
                        if move_dust then move_dust:emit(OX + (selected.c-1)*CELL + CELL/2, OY + (selected.r-1)*CELL + CELL/2, 5) end
                        selected.c     = hc
                        selected.r     = hr
                        selected.moved = true
                        move_tiles     = {}
                        attack_tiles   = not selected.attacked and attack_range_tiles(selected) or {}
                        state          = "attack"
                        return
                    end
                end
            end
            -- Check attack tile
            if selected and not selected.attacked then
                for _, t in ipairs(attack_tiles) do
                    if t.c == hc and t.r == hr then
                        local target = find_unit(hc, hr)
                        if target and target.team == "enemy" then
                            do_attack(selected, target)
                            selected.attacked = true
                            state = "select"
                            selected = nil
                            move_tiles   = {}
                            attack_tiles = {}
                            return
                        end
                    end
                end
            end
            -- Deselect
            state = "select" ; selected = nil ; move_tiles = {} ; attack_tiles = {}

        elseif state == "attack" then
            if selected and not selected.attacked then
                for _, t in ipairs(attack_tiles) do
                    if t.c == hc and t.r == hr then
                        local target = find_unit(hc, hr)
                        if target and target.team == "enemy" then
                            do_attack(selected, target)
                            selected.attacked = true
                        end
                    end
                end
            end
            state = "select" ; selected = nil ; move_tiles = {} ; attack_tiles = {}
        end

        local p, e = 0, 0
        for _, u in ipairs(units) do
            if u.team == "player" then p = p + 1 else e = e + 1 end
        end
        if e == 0 then state = "win"  end
        if p == 0 then state = "lose" end
    end
end)

-- ── Render world ──────────────────────────────────────────
lurek.render(function()
    -- Tiles
    for r = 1, ROWS do
        for c = 1, COLS do
            local v   = MAP[r][c]
            local col = v == TILE_FOREST and {0.15,0.3,0.15,1} or v == TILE_WATER and {0.1,0.2,0.45,1} or {0.1,0.12,0.1,1}
            lurek.render.rectangle(OX + (c-1)*CELL, OY + (r-1)*CELL, CELL-1, CELL-1, { color = col })
        end
    end

    -- Move/attack overlay
    for _, t in ipairs(move_tiles) do
        lurek.render.rectangle(OX + (t.c-1)*CELL, OY + (t.r-1)*CELL, CELL-1, CELL-1, { color = {0.2,0.6,1.0,0.35} })
    end
    for _, t in ipairs(attack_tiles) do
        lurek.render.rectangle(OX + (t.c-1)*CELL, OY + (t.r-1)*CELL, CELL-1, CELL-1, { color = {0.9,0.2,0.2,0.35} })
    end

    -- Hover
    if hover_c >= 1 and hover_c <= COLS and hover_r >= 1 and hover_r <= ROWS then
        lurek.render.rectangle(OX + (hover_c-1)*CELL, OY + (hover_r-1)*CELL, CELL-1, CELL-1, { color = {1,1,1,0.12} })
    end

    -- Units
    for _, u in ipairs(units) do
        if u.hp <= 0 then goto skip end
        local ux = OX + (u.c-1)*CELL
        local uy = OY + (u.r-1)*CELL
        local col = u.team == "player" and {0.3,0.6,1.0,1} or {0.8,0.3,0.2,1}
        if (u.moved and u.attacked) then col[4] = 0.5 end
        lurek.render.rectangle(ux + 6, uy + 6, CELL - 14, CELL - 14, { color = col })
        lurek.render.print(u.icon, ux + 18, uy + 16, { color = {1,1,1,1}, size = 18 })
        -- HP bar
        lurek.render.rectangle(ux + 2, uy + CELL - 10, CELL - 6, 6, { color = {0.2,0,0,1} })
        lurek.render.rectangle(ux + 2, uy + CELL - 10, math.floor((CELL-6) * u.hp / u.maxHp), 6, { color = {0.2,0.8,0.2,1} })

        if selected and selected.id == u.id then
            lurek.render.rectangle(ux + 2, uy + 2, CELL - 6, CELL - 6, { color = {1,1,0.3,0.3} })
        end
        ::skip::
    end

    if attack_sparks then attack_sparks:draw() end
    if death_burst   then death_burst:draw()   end
    if move_dust     then move_dust:draw()     end
end)

-- ── Render UI ─────────────────────────────────────────────
lurek.render_ui(function()
    lurek.render.print(turn == "player" and "YOUR TURN" or "ENEMY TURN", 14, 8, { color = turn == "player" and {0.3,0.9,0.4,1} or {0.9,0.3,0.3,1}, size = 16 })
    lurek.render.print("Score: " .. score, 400, 8, { color = {1,1,1,1}, size = 14 })
    lurek.render.print("Click unit to select → move tile → attack tile   Enter=end turn", 14, H - 26, { color = {0.4,0.4,0.4,1}, size = 11 })

    if selected then
        lurek.render.print(selected.kind .. " HP:" .. selected.hp .. "/" .. selected.maxHp, 320, 8, { color = {0.9,0.9,0.4,1}, size = 13 })
    end

    -- Log
    for i, msg in ipairs(log_msgs) do
        local a = math.min(1.0, msg.timer)
        lurek.render.print(msg.t, 14, ROWS * CELL + OY + 8 + (i-1) * 16, { color = {0.8,0.8,0.6, a}, size = 11 })
    end

    if state == "win" then
        lurek.render.rectangle(200, 220, 400, 100, { color = {0,0,0,0.85} })
        lurek.render.print("VICTORY!", 300, 246, { color = {1,0.9,0.2,1}, size = 36 })
    elseif state == "lose" then
        lurek.render.rectangle(200, 220, 400, 100, { color = {0,0,0,0.85} })
        lurek.render.print("DEFEATED", 290, 246, { color = {0.9,0.2,0.2,1}, size = 36 })
    end
end)
