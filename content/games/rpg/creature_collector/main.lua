------------------------------------------------------------------------
-- Creature Collector — Lurek2D
-- Category: rpg
-- Pokemon-style creature collection RPG with tile-based overworld,
-- turn-based battles, type advantages, catching, and party management.
------------------------------------------------------------------------

-- Action input bindings:
-- up(w), down(s), left(a), right(d)
-- choice1(1), choice2(2), choice3(3), choice4(4)
-- move1(1), move2(2)
-- quit(escape)

------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------
local TILE = 32
local COLS = 25
local ROWS = 18
local MAP_W = COLS * TILE
local MAP_H = ROWS * TILE
local MOVE_CD = 0.15
local ENCOUNTER_CHANCE = 0.10
local MAX_PARTY = 3

------------------------------------------------------------------------
-- Tile types
------------------------------------------------------------------------
local T_PATH   = 0
local T_GRASS  = 1
local T_WATER  = 2
local T_TREE   = 3
local T_HEAL   = 4

------------------------------------------------------------------------
-- States
------------------------------------------------------------------------
local STATE_TITLE         = "TITLE"
local STATE_OVERWORLD     = "OVERWORLD"
local STATE_BATTLE        = "BATTLE"
local STATE_BATTLE_ACTION = "BATTLE_ACTION"
local STATE_WIN           = "WIN"
local STATE_GAME_OVER     = "GAME_OVER"

local state = STATE_TITLE

------------------------------------------------------------------------
-- Type effectiveness: fire>grass>water>fire
------------------------------------------------------------------------
local TYPE_ADV = { fire = "grass", grass = "water", water = "fire" }

local function type_multiplier(atk_type, def_type)
    if TYPE_ADV[atk_type] == def_type then return 1.5 end
    if TYPE_ADV[def_type] == atk_type then return 0.67 end
    return 1.0
end

------------------------------------------------------------------------
-- Creature species database
------------------------------------------------------------------------
local SPECIES = {
    {
        name = "Flamepup", type = "fire",
        color = {1.0, 0.3, 0.1}, outline = {1.0, 0.6, 0.0},
        base_hp = 40, base_atk = 14, base_def = 8,
        moves = { { name = "Ember", power = 8 }, { name = "Fire Fang", power = 12 } },
    },
    {
        name = "Aquafin", type = "water",
        color = {0.2, 0.5, 1.0}, outline = {0.1, 0.3, 0.8},
        base_hp = 45, base_atk = 11, base_def = 11,
        moves = { { name = "Splash", power = 7 }, { name = "Tidal Crash", power = 13 } },
    },
    {
        name = "Leafling", type = "grass",
        color = {0.2, 0.8, 0.2}, outline = {0.1, 0.5, 0.1},
        base_hp = 42, base_atk = 12, base_def = 10,
        moves = { { name = "Vine Whip", power = 8 }, { name = "Leaf Storm", power = 12 } },
    },
    {
        name = "Emberclaw", type = "fire",
        color = {0.9, 0.2, 0.0}, outline = {1.0, 0.5, 0.2},
        base_hp = 38, base_atk = 16, base_def = 7,
        moves = { { name = "Scratch", power = 7 }, { name = "Blaze Rush", power = 14 } },
    },
    {
        name = "Tidalink", type = "water",
        color = {0.1, 0.4, 0.9}, outline = {0.3, 0.6, 1.0},
        base_hp = 48, base_atk = 10, base_def = 12,
        moves = { { name = "Bubble", power = 7 }, { name = "Aqua Jet", power = 11 } },
    },
    {
        name = "Thornvine", type = "grass",
        color = {0.1, 0.6, 0.1}, outline = {0.4, 0.8, 0.2},
        base_hp = 44, base_atk = 13, base_def = 9,
        moves = { { name = "Thorn Jab", power = 9 }, { name = "Root Slam", power = 13 } },
    },
}

------------------------------------------------------------------------
-- Create a creature instance from a species index at a given level
------------------------------------------------------------------------
local function make_creature(species_idx, level)
    local sp = SPECIES[species_idx]
    local lv = level or 1
    local hp = sp.base_hp + (lv - 1) * 3
    return {
        species = species_idx,
        name = sp.name,
        type = sp.type,
        color = sp.color,
        outline = sp.outline,
        moves = sp.moves,
        level = lv,
        max_hp = hp,
        hp = hp,
        atk = sp.base_atk + (lv - 1) * 2,
        def = sp.base_def + (lv - 1) * 1,
        xp = 0,
        xp_next = 20 + (lv - 1) * 10,
    }
end

------------------------------------------------------------------------
-- Map generation
------------------------------------------------------------------------
local map = {}

local function generate_map()
    map = {}
    math.randomseed(os.time())
    for r = 1, ROWS do
        map[r] = {}
        for c = 1, COLS do
            local v = math.random()
            if r == 1 or r == ROWS or c == 1 or c == COLS then
                map[r][c] = T_TREE
            elseif v < 0.08 then
                map[r][c] = T_WATER
            elseif v < 0.18 then
                map[r][c] = T_TREE
            elseif v < 0.55 then
                map[r][c] = T_GRASS
            else
                map[r][c] = T_PATH
            end
        end
    end
    -- place healing spot
    map[3][3] = T_HEAL
    -- ensure spawn area is clear
    for dr = -1, 1 do
        for dc = -1, 1 do
            local rr = ROWS - 2 + dr
            local cc = 3 + dc
            if rr >= 2 and rr <= ROWS - 1 and cc >= 2 and cc <= COLS - 1 then
                map[rr][cc] = T_PATH
            end
        end
    end
    map[ROWS - 2][3] = T_PATH
end

------------------------------------------------------------------------
-- Player
------------------------------------------------------------------------
local player = { col = 3, row = ROWS - 2, move_cd = 0 }
local party = {}
local active_idx = 1
local total_caught = 0
local total_battles = 0

------------------------------------------------------------------------
-- Battle state
------------------------------------------------------------------------
local enemy = nil
local battle_menu = 1       -- 1=Fight,2=Catch,3=Switch,4=Run
local fight_move = 0        -- 0=choosing, 1 or 2
local battle_log = {}
local battle_phase = "menu" -- menu, fight_select, enemy_turn, result
local switch_menu = 1

------------------------------------------------------------------------
-- Visual FX
------------------------------------------------------------------------
local particles = {}
local tweens_list = {}
local shake_x, shake_y = 0, 0
local shake_time = 0
local hp_bar_display = 1.0
local enemy_hp_display = 1.0
local popup_text = ""
local popup_timer = 0
local popup_x, popup_y = 0, 0
local title_pulse = 0

------------------------------------------------------------------------
-- Tile colors
------------------------------------------------------------------------
local TILE_COLORS = {
    [T_PATH]  = {0.76, 0.70, 0.50},
    [T_GRASS] = {0.25, 0.60, 0.20},
    [T_WATER] = {0.15, 0.35, 0.75},
    [T_TREE]  = {0.10, 0.35, 0.10},
    [T_HEAL]  = {1.00, 0.85, 0.90},
}

------------------------------------------------------------------------
-- Particle helpers
------------------------------------------------------------------------
local function spawn_particles(x, y, count, r, g, b, speed, life)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = speed * (0.5 + math.random() * 0.5)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = life * (0.7 + math.random() * 0.6),
            max_life = life,
            r = r, g = g, b = b,
            size = 3 + math.random() * 4,
        })
    end
end

local function type_particles(x, y, ctype)
    if ctype == "fire" then
        spawn_particles(x, y, 20, 1.0, 0.4, 0.0, 120, 0.6)
    elseif ctype == "water" then
        spawn_particles(x, y, 20, 0.2, 0.5, 1.0, 100, 0.7)
    elseif ctype == "grass" then
        spawn_particles(x, y, 20, 0.3, 0.9, 0.2, 90, 0.65)
    end
end

local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.vy = p.vy + 40 * dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

------------------------------------------------------------------------
-- Tween helpers
------------------------------------------------------------------------
local function add_tween(target, field, from, to, dur, on_done)
    table.insert(tweens_list, {
        target = target, field = field,
        from = from, to = to,
        duration = dur, elapsed = 0,
        on_done = on_done,
    })
end

local function update_tweens(dt)
    local i = 1
    while i <= #tweens_list do
        local tw = tweens_list[i]
        tw.elapsed = tw.elapsed + dt
        local t = math.min(tw.elapsed / tw.duration, 1.0)
        -- ease out quad
        local val = tw.from + (tw.to - tw.from) * (1 - (1 - t) * (1 - t))
        if tw.target and tw.field then
            tw.target[tw.field] = val
        end
        if t >= 1.0 then
            if tw.on_done then tw.on_done() end
            table.remove(tweens_list, i)
        else
            i = i + 1
        end
    end
end

------------------------------------------------------------------------
-- Battle log helper
------------------------------------------------------------------------
local function blog(msg)
    table.insert(battle_log, msg)
    if #battle_log > 5 then table.remove(battle_log, 1) end
end

------------------------------------------------------------------------
-- Damage calc
------------------------------------------------------------------------
local function calc_damage(attacker, move, defender)
    local mult = type_multiplier(attacker.type, defender.type)
    local raw = (attacker.atk * move.power) / math.max(defender.def, 1)
    local dmg = math.max(1, math.floor(raw * mult + 0.5))
    return dmg, mult
end

------------------------------------------------------------------------
-- XP / level up
------------------------------------------------------------------------
local function grant_xp(creature, amount)
    creature.xp = creature.xp + amount
    while creature.xp >= creature.xp_next do
        creature.xp = creature.xp - creature.xp_next
        creature.level = creature.level + 1
        local sp = SPECIES[creature.species]
        creature.max_hp = sp.base_hp + (creature.level - 1) * 3
        creature.hp = creature.max_hp
        creature.atk = sp.base_atk + (creature.level - 1) * 2
        creature.def = sp.base_def + (creature.level - 1) * 1
        creature.xp_next = 20 + (creature.level - 1) * 10
        blog(creature.name .. " grew to Lv." .. creature.level .. "!")
        spawn_particles(400, 300, 30, 1.0, 1.0, 0.3, 100, 0.8)
    end
end

------------------------------------------------------------------------
-- Start a wild encounter
------------------------------------------------------------------------
local function start_battle()
    local idx = math.random(1, #SPECIES)
    local lv = math.max(1, party[active_idx].level + math.random(-1, 1))
    enemy = make_creature(idx, lv)
    enemy_hp_display = 1.0
    battle_menu = 1
    fight_move = 0
    battle_phase = "menu"
    battle_log = {}
    state = STATE_BATTLE
    total_battles = total_battles + 1
    blog("A wild " .. enemy.name .. " (Lv." .. enemy.level .. ") appeared!")
    -- battle start flash
    spawn_particles(400, 300, 40, 1.0, 1.0, 1.0, 200, 0.4)
    shake_time = 0.2
end

------------------------------------------------------------------------
-- Enemy turn
------------------------------------------------------------------------
local function enemy_turn()
    if not enemy or enemy.hp <= 0 then return end
    local me = party[active_idx]
    if not me or me.hp <= 0 then return end
    local mv = enemy.moves[math.random(1, 2)]
    local dmg, mult = calc_damage(enemy, mv, me)
    me.hp = math.max(0, me.hp - dmg)
    local eff = ""
    if mult > 1.0 then eff = " Super effective!" end
    if mult < 1.0 then eff = " Not very effective..." end
    blog(enemy.name .. " used " .. mv.name .. "! " .. dmg .. " dmg." .. eff)
    if mult > 1.0 then
        type_particles(250, 320, enemy.type)
    end
    popup_text = "-" .. dmg
    popup_x, popup_y = 250, 280
    popup_timer = 0.8
    -- tween player hp bar
    local ratio = me.hp / me.max_hp
    add_tween({ val = hp_bar_display }, "val", hp_bar_display, ratio, 0.3)
    hp_bar_display = ratio
    if me.hp <= 0 then
        blog(me.name .. " fainted!")
        -- find next alive creature
        local found = false
        for i = 1, #party do
            if party[i].hp > 0 then
                active_idx = i
                blog("Go, " .. party[active_idx].name .. "!")
                found = true
                break
            end
        end
        if not found then
            state = STATE_GAME_OVER
        end
    end
end

------------------------------------------------------------------------
-- lurek.input — action bindings
------------------------------------------------------------------------
lurek.input.bind("up", "w")
lurek.input.bind("up", "up")
lurek.input.bind("down", "s")
lurek.input.bind("down", "down")
lurek.input.bind("left", "a")
lurek.input.bind("left", "left")
lurek.input.bind("right", "d")
lurek.input.bind("right", "right")
lurek.input.bind("choice1", "1")
lurek.input.bind("choice2", "2")
lurek.input.bind("choice3", "3")
lurek.input.bind("choice4", "4")
lurek.input.bind("quit", "escape")

------------------------------------------------------------------------
-- lurek.init
------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Creature Collector — Lurek2D")
    lurek.render.setBackgroundColor(0.2, 0.4, 0.15)
    generate_map()
    -- starter creature: random from first 3
    local starter = math.random(1, 3)
    party = { make_creature(starter, 3) }
    active_idx = 1
end

------------------------------------------------------------------------
-- lurek.process — game logic
------------------------------------------------------------------------
lurek.process(function(dt)
    local fps = lurek.timer.getFPS()
    lurek.window.setTitle("Creature Collector — Lurek2D | FPS: " .. math.floor(fps))

    update_particles(dt)
    update_tweens(dt)
    title_pulse = title_pulse + dt

    -- shake decay
    if shake_time > 0 then
        shake_time = shake_time - dt
        shake_x = (math.random() - 0.5) * 6
        shake_y = (math.random() - 0.5) * 6
    else
        shake_x, shake_y = 0, 0
    end

    -- popup decay
    if popup_timer > 0 then
        popup_timer = popup_timer - dt
        popup_y = popup_y - 30 * dt
    end

    -- quit
    if lurek.input.isActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -------------------------------------------------------
    -- TITLE
    -------------------------------------------------------
    if state == STATE_TITLE then
        if lurek.input.isActionPressed("choice1") then
            state = STATE_OVERWORLD
        end

    -------------------------------------------------------
    -- OVERWORLD
    -------------------------------------------------------
    elseif state == STATE_OVERWORLD then
        player.move_cd = math.max(0, player.move_cd - dt)
        if player.move_cd <= 0 then
            local dc, dr = 0, 0
            if lurek.input.isActionDown("up")    then dr = -1 end
            if lurek.input.isActionDown("down")  then dr =  1 end
            if lurek.input.isActionDown("left")  then dc = -1 end
            if lurek.input.isActionDown("right") then dc =  1 end
            if dc ~= 0 or dr ~= 0 then
                -- prefer one axis
                if dc ~= 0 and dr ~= 0 then dr = 0 end
                local nc = player.col + dc
                local nr = player.row + dr
                if nc >= 1 and nc <= COLS and nr >= 1 and nr <= ROWS then
                    local tile = map[nr][nc]
                    if tile ~= T_WATER and tile ~= T_TREE then
                        player.col = nc
                        player.row = nr
                        player.move_cd = MOVE_CD
                        -- heal spot
                        if tile == T_HEAL then
                            for _, c in ipairs(party) do
                                c.hp = c.max_hp
                            end
                            spawn_particles(nc * TILE - TILE/2, nr * TILE - TILE/2, 15, 1.0, 0.7, 0.9, 60, 0.5)
                        end
                        -- encounter on grass
                        if tile == T_GRASS and math.random() < ENCOUNTER_CHANCE then
                            if party[active_idx].hp > 0 then
                                start_battle()
                            end
                        end
                    end
                end
            end
        end

        -- check win
        if total_caught >= 6 then
            state = STATE_WIN
        end

    -------------------------------------------------------
    -- BATTLE — choosing action
    -------------------------------------------------------
    elseif state == STATE_BATTLE then
        if lurek.input.isActionPressed("choice1") then
            battle_phase = "fight_select"
            fight_move = 0
        elseif lurek.input.isActionPressed("choice2") then
            -- catch attempt
            local hp_ratio = enemy.hp / enemy.max_hp
            local chance = 0.30
            if hp_ratio <= 0.25 then chance = 0.70
            elseif hp_ratio <= 0.50 then chance = 0.40 end
            spawn_particles(550, 300, 12, 1.0, 1.0, 0.5, 80, 0.5)
            shake_time = 0.15
            if math.random() < chance then
                blog("Gotcha! " .. enemy.name .. " was caught!")
                spawn_particles(550, 300, 30, 1.0, 0.9, 0.0, 120, 0.7)
                if #party < MAX_PARTY then
                    table.insert(party, enemy)
                    blog(enemy.name .. " joined your party!")
                else
                    blog("Party full. " .. enemy.name .. " was released.")
                end
                total_caught = total_caught + 1
                grant_xp(party[active_idx], 15 + enemy.level * 3)
                enemy = nil
                state = STATE_OVERWORLD
            else
                blog("Oh no! " .. enemy.name .. " broke free!")
                enemy_turn()
            end
        elseif lurek.input.isActionPressed("choice3") then
            battle_phase = "switch"
            switch_menu = 1
        elseif lurek.input.isActionPressed("choice4") then
            blog("Got away safely!")
            enemy = nil
            state = STATE_OVERWORLD
        end

    -------------------------------------------------------
    -- BATTLE_ACTION — fight move selection or switch
    -------------------------------------------------------
    elseif state == STATE_BATTLE_ACTION then
        -- handled in BATTLE fight_select / switch below
    end

    -- fight_select sub-phase
    if battle_phase == "fight_select" and (state == STATE_BATTLE or state == STATE_BATTLE_ACTION) then
        state = STATE_BATTLE_ACTION
        if lurek.input.isActionPressed("choice1") then
            fight_move = 1
        elseif lurek.input.isActionPressed("choice2") then
            fight_move = 2
        end
        if fight_move > 0 and enemy then
            local me = party[active_idx]
            local mv = me.moves[fight_move]
            local dmg, mult = calc_damage(me, mv, enemy)
            enemy.hp = math.max(0, enemy.hp - dmg)
            local eff = ""
            if mult > 1.0 then
                eff = " Super effective!"
                type_particles(550, 300, me.type)
                shake_time = 0.25
            end
            if mult < 1.0 then eff = " Not very effective..." end
            blog(me.name .. " used " .. mv.name .. "! " .. dmg .. " dmg." .. eff)
            popup_text = "-" .. dmg
            popup_x, popup_y = 550, 260
            popup_timer = 0.8
            -- tween enemy hp bar
            local ratio = enemy.hp / enemy.max_hp
            add_tween({ val = enemy_hp_display }, "val", enemy_hp_display, ratio, 0.3)
            enemy_hp_display = ratio
            if enemy.hp <= 0 then
                blog(enemy.name .. " fainted!")
                grant_xp(me, 10 + enemy.level * 2)
                spawn_particles(550, 300, 25, 0.8, 0.8, 0.8, 100, 0.5)
                enemy = nil
                state = STATE_OVERWORLD
            else
                fight_move = 0
                battle_phase = "menu"
                state = STATE_BATTLE
                enemy_turn()
            end
        end
    end

    -- switch sub-phase
    if battle_phase == "switch" and (state == STATE_BATTLE or state == STATE_BATTLE_ACTION) then
        state = STATE_BATTLE_ACTION
        for i = 1, math.min(#party, 3) do
            if lurek.input.isActionPressed("choice" .. i) then
                if party[i].hp > 0 then
                    active_idx = i
                    blog("Go, " .. party[active_idx].name .. "!")
                    battle_phase = "menu"
                    state = STATE_BATTLE
                    enemy_turn()
                else
                    blog(party[i].name .. " has fainted!")
                end
            end
        end
    end
end)

------------------------------------------------------------------------
-- lurek.render — overworld (map + player), camera follows player
------------------------------------------------------------------------
lurek.render(function()
    if state == STATE_OVERWORLD then
        local cam_x = player.col * TILE - 400
        local cam_y = player.row * TILE - 300
        cam_x = math.max(0, math.min(cam_x, MAP_W - 800))
        cam_y = math.max(0, math.min(cam_y, MAP_H - 600))

        lurek.camera.set(-cam_x + shake_x, -cam_y + shake_y)

        -- draw tiles
        for r = 1, ROWS do
            for c = 1, COLS do
                local tile = map[r][c]
                local col = TILE_COLORS[tile] or {0.5, 0.5, 0.5}
                local tx = (c - 1) * TILE
                local ty = (r - 1) * TILE
                lurek.render.rectangle(tx, ty, TILE, TILE, col[1], col[2], col[3])
                -- grass detail spots
                if tile == T_GRASS then
                    local seed = r * 100 + c
                    math.randomseed(seed)
                    for _ = 1, 3 do
                        local sx = tx + math.random(4, TILE - 4)
                        local sy = ty + math.random(4, TILE - 4)
                        lurek.render.rectangle(sx, sy, 3, 3, 0.15, 0.45, 0.12)
                    end
                    math.randomseed(os.time())
                end
                -- heal marker
                if tile == T_HEAL then
                    lurek.render.rectangle(tx + 12, ty + 8, 8, 16, 1.0, 0.3, 0.3)
                    lurek.render.rectangle(tx + 8, ty + 12, 16, 8, 1.0, 0.3, 0.3)
                end
            end
        end

        -- draw player
        local px = (player.col - 1) * TILE + 4
        local py = (player.row - 1) * TILE + 4
        lurek.render.rectangle(px, py, TILE - 8, TILE - 8, 0.2, 0.4, 1.0)
        lurek.render.rectangle(px + 2, py + 2, TILE - 12, TILE - 12, 0.3, 0.5, 1.0)

        lurek.camera.reset()
    end

    -- battle scene background
    if state == STATE_BATTLE or state == STATE_BATTLE_ACTION then
        lurek.render.rectangle(shake_x, shake_y, 800, 600, 0.12, 0.18, 0.10)
        -- ground
        lurek.render.rectangle(shake_x, 350 + shake_y, 800, 250, 0.22, 0.35, 0.18)

        -- draw player creature (left side)
        local me = party[active_idx]
        if me then
            lurek.render.circle(200 + shake_x, 320 + shake_y, 40, me.outline[1], me.outline[2], me.outline[3])
            lurek.render.circle(200 + shake_x, 320 + shake_y, 34, me.color[1], me.color[2], me.color[3])
        end

        -- draw enemy creature (right side)
        if enemy then
            lurek.render.circle(550 + shake_x, 280 + shake_y, 44, enemy.outline[1], enemy.outline[2], enemy.outline[3])
            lurek.render.circle(550 + shake_x, 280 + shake_y, 38, enemy.color[1], enemy.color[2], enemy.color[3])
        end
    end

    -- particles (all states)
    for _, p in ipairs(particles) do
        local alpha = p.life / p.max_life
        local sz = p.size * alpha
        lurek.render.rectangle(p.x - sz/2, p.y - sz/2, sz, sz, p.r, p.g, p.b, alpha)
    end
end)

------------------------------------------------------------------------
-- lurek.render_ui — HUD, battle overlays, menus
------------------------------------------------------------------------
lurek.render_ui(function()
    -------------------------------------------------------
    -- TITLE screen
    -------------------------------------------------------
    if state == STATE_TITLE then
        lurek.render.rectangle(0, 0, 800, 600, 0.05, 0.08, 0.05)
        local pulse = 0.7 + 0.3 * math.sin(title_pulse * 2)
        lurek.render.print("CREATURE COLLECTOR", 140, 180, 36, pulse, pulse, 0.2)
        lurek.render.print("GOTTA CATCH 'EM ALL!", 210, 240, 20, 0.8, 0.8, 0.5)
        lurek.render.print("Press 1 to Start", 290, 350, 18, 0.6, 0.6, 0.6)
        lurek.render.print("WASD — Move  |  1-4 — Actions  |  ESC — Quit", 130, 500, 14, 0.4, 0.4, 0.4)
        -- draw sample creatures
        for i = 1, #SPECIES do
            local sp = SPECIES[i]
            local cx = 120 + (i - 1) * 100
            lurek.render.circle(cx, 430, 18, sp.outline[1], sp.outline[2], sp.outline[3])
            lurek.render.circle(cx, 430, 14, sp.color[1], sp.color[2], sp.color[3])
        end

    -------------------------------------------------------
    -- OVERWORLD HUD
    -------------------------------------------------------
    elseif state == STATE_OVERWORLD then
        -- party bar
        lurek.render.rectangle(0, 0, 800, 32, 0.0, 0.0, 0.0, 0.6)
        local me = party[active_idx]
        if me then
            lurek.render.print(me.name .. " Lv." .. me.level, 10, 6, 16, 1.0, 1.0, 1.0)
            -- HP bar
            local hp_ratio = me.hp / me.max_hp
            lurek.render.rectangle(200, 8, 150, 14, 0.2, 0.2, 0.2)
            local bar_r = hp_ratio > 0.5 and 0.2 or (hp_ratio > 0.25 and 1.0 or 1.0)
            local bar_g = hp_ratio > 0.5 and 0.8 or (hp_ratio > 0.25 and 0.7 or 0.2)
            local bar_b = hp_ratio > 0.5 and 0.2 or 0.1
            lurek.render.rectangle(200, 8, math.floor(150 * hp_ratio), 14, bar_r, bar_g, bar_b)
            lurek.render.print(me.hp .. "/" .. me.max_hp, 360, 6, 14, 1.0, 1.0, 1.0)
        end
        lurek.render.print("Party: " .. #party .. "/" .. MAX_PARTY, 500, 6, 14, 0.8, 0.8, 0.8)
        lurek.render.print("Caught: " .. total_caught .. "/6", 650, 6, 14, 0.8, 0.8, 0.8)

        -- minimap
        local mm_x, mm_y = 660, 460
        local mm_s = 5
        lurek.render.rectangle(mm_x - 2, mm_y - 2, COLS * mm_s + 4, ROWS * mm_s + 4, 0.0, 0.0, 0.0, 0.5)
        for r = 1, ROWS do
            for c = 1, COLS do
                local col = TILE_COLORS[map[r][c]]
                if col then
                    lurek.render.rectangle(mm_x + (c-1)*mm_s, mm_y + (r-1)*mm_s, mm_s, mm_s, col[1], col[2], col[3], 0.7)
                end
            end
        end
        -- player dot on minimap
        lurek.render.rectangle(mm_x + (player.col-1)*mm_s, mm_y + (player.row-1)*mm_s, mm_s, mm_s, 1.0, 1.0, 0.0)

    -------------------------------------------------------
    -- BATTLE HUD
    -------------------------------------------------------
    elseif state == STATE_BATTLE or state == STATE_BATTLE_ACTION then
        local me = party[active_idx]

        -- player creature info (top-left)
        if me then
            lurek.render.rectangle(10, 10, 220, 60, 0.0, 0.0, 0.0, 0.7)
            lurek.render.print(me.name .. " Lv." .. me.level, 18, 14, 16, 1.0, 1.0, 1.0)
            lurek.render.print("HP:", 18, 36, 14, 0.8, 0.8, 0.8)
            local hp_ratio = me.hp / me.max_hp
            lurek.render.rectangle(50, 38, 150, 12, 0.2, 0.2, 0.2)
            local bar_r = hp_ratio > 0.5 and 0.2 or (hp_ratio > 0.25 and 1.0 or 1.0)
            local bar_g = hp_ratio > 0.5 and 0.8 or (hp_ratio > 0.25 and 0.7 or 0.2)
            lurek.render.rectangle(50, 38, math.floor(150 * hp_ratio), 12, bar_r, bar_g, 0.1)
            lurek.render.print(me.hp .. "/" .. me.max_hp, 206, 36, 12, 1.0, 1.0, 1.0)
            lurek.render.print("XP: " .. me.xp .. "/" .. me.xp_next, 18, 54, 11, 0.6, 0.8, 0.6)
        end

        -- enemy creature info (top-right)
        if enemy then
            lurek.render.rectangle(530, 10, 260, 50, 0.0, 0.0, 0.0, 0.7)
            lurek.render.print(enemy.name .. " Lv." .. enemy.level .. " [" .. enemy.type .. "]", 538, 14, 16, 1.0, 0.8, 0.8)
            local ehp = enemy.hp / enemy.max_hp
            lurek.render.rectangle(538, 38, 200, 12, 0.2, 0.2, 0.2)
            lurek.render.rectangle(538, 38, math.floor(200 * ehp), 12, 0.8, 0.2, 0.2)
            lurek.render.print(enemy.hp .. "/" .. enemy.max_hp, 744, 36, 12, 1.0, 1.0, 1.0)
        end

        -- battle log (bottom)
        lurek.render.rectangle(0, 440, 800, 160, 0.0, 0.0, 0.0, 0.8)
        for i, msg in ipairs(battle_log) do
            lurek.render.print(msg, 16, 446 + (i - 1) * 18, 14, 0.9, 0.9, 0.8)
        end

        -- menu panel
        if battle_phase == "menu" then
            lurek.render.rectangle(500, 440, 290, 155, 0.1, 0.1, 0.1, 0.9)
            lurek.render.print("1) Fight", 520, 455, 16, 1.0, 1.0, 0.6)
            lurek.render.print("2) Catch", 520, 480, 16, 1.0, 0.8, 0.4)
            lurek.render.print("3) Switch", 520, 505, 16, 0.6, 0.8, 1.0)
            lurek.render.print("4) Run", 520, 530, 16, 0.7, 0.7, 0.7)
        elseif battle_phase == "fight_select" and me then
            lurek.render.rectangle(500, 440, 290, 155, 0.1, 0.1, 0.1, 0.9)
            lurek.render.print("Choose move:", 520, 455, 16, 1.0, 1.0, 1.0)
            for i, mv in ipairs(me.moves) do
                lurek.render.print(i .. ") " .. mv.name .. " (pow:" .. mv.power .. ")", 520, 475 + (i-1)*25, 15, 0.9, 0.9, 0.6)
            end
        elseif battle_phase == "switch" then
            lurek.render.rectangle(500, 440, 290, 155, 0.1, 0.1, 0.1, 0.9)
            lurek.render.print("Switch to:", 520, 455, 16, 1.0, 1.0, 1.0)
            for i, c in ipairs(party) do
                local alive = c.hp > 0 and "" or " [FAINTED]"
                local act = i == active_idx and " *" or ""
                lurek.render.print(i .. ") " .. c.name .. " HP:" .. c.hp .. "/" .. c.max_hp .. alive .. act, 520, 475 + (i-1)*22, 13, 0.8, 0.9, 0.8)
            end
        end

        -- damage popup
        if popup_timer > 0 then
            local alpha = math.min(1.0, popup_timer / 0.4)
            lurek.render.print(popup_text, popup_x, popup_y, 22, 1.0, 0.2, 0.2, alpha)
        end

    -------------------------------------------------------
    -- WIN screen
    -------------------------------------------------------
    elseif state == STATE_WIN then
        lurek.render.rectangle(0, 0, 800, 600, 0.0, 0.05, 0.0, 0.9)
        lurek.render.print("YOU CAUGHT THEM ALL!", 180, 200, 32, 1.0, 0.9, 0.2)
        lurek.render.print("All 6 species collected!", 240, 260, 20, 0.8, 0.8, 0.6)
        lurek.render.print("Battles: " .. total_battles, 320, 320, 16, 0.7, 0.7, 0.7)
        lurek.render.print("Party:", 320, 360, 16, 0.7, 0.7, 0.7)
        for i, c in ipairs(party) do
            lurek.render.print(c.name .. " Lv." .. c.level, 340, 380 + (i-1)*20, 14, 0.6, 0.9, 0.6)
        end
        lurek.render.print("Press ESC to quit", 300, 500, 16, 0.5, 0.5, 0.5)

    -------------------------------------------------------
    -- GAME OVER screen
    -------------------------------------------------------
    elseif state == STATE_GAME_OVER then
        lurek.render.rectangle(0, 0, 800, 600, 0.08, 0.0, 0.0, 0.9)
        lurek.render.print("GAME OVER", 280, 220, 36, 1.0, 0.2, 0.2)
        lurek.render.print("All your creatures fainted...", 230, 280, 18, 0.7, 0.4, 0.4)
        lurek.render.print("Caught: " .. total_caught .. "/6  |  Battles: " .. total_battles, 220, 340, 16, 0.6, 0.6, 0.6)
        lurek.render.print("Press ESC to quit", 300, 500, 16, 0.5, 0.5, 0.5)
    end
end)
