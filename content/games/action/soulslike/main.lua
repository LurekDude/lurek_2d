-- ============================================================================
--  Soulslike — Precision boss fight with stamina, dodges, and 3-phase AI
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/soulslike
--
--  Controls (bound as input actions — see lurek.init):
--    move       : W / A / S / D
--    light_atk  : J          heavy_atk : K
--    dodge      : L          block     : Space (hold)
--    heal       : E          start     : Enter
--    quit       : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────
-- Capture lurek.render API table before `function lurek.render()` shadows it.
local gfx = lurek.render

local SCREEN_W, SCREEN_H = 800, 600
local ARENA_X, ARENA_Y   = 80, 100
local ARENA_W, ARENA_H   = 640, 400

local PLAYER_W, PLAYER_H = 20, 30
local PLAYER_SPEED       = 160
local PLAYER_MAX_HP      = 100
local PLAYER_MAX_STAM    = 100
local STAM_REGEN         = 30
local EXHAUST_DUR        = 1.0

local BOSS_W, BOSS_H     = 40, 50
local BOSS_MAX_HP        = 300

-- Attack data
local LIGHT = { dmg = 12, dur = 0.30, cost = 15, name = "light" }
local HEAVY = { dmg = 25, dur = 0.60, cost = 30, name = "heavy" }
local DODGE = { dur = 0.30, cost = 20, dist = 100 }
local BLOCK_REDUCTION    = 0.75
local BLOCK_COST_PER_HIT = 20

local ESTUS_HEAL     = 30
local ESTUS_MAX      = 3
local ESTUS_LOCK_DUR = 1.0

local HITLAG_DUR     = 0.05

-- Boss attack types
local BOSS_MELEE  = { dmg = 18, range = 55, dur = 0.35, name = "melee"  }
local BOSS_DASH   = { dmg = 22, range = 80, dur = 0.25, speed = 500, name = "dash" }
local BOSS_SLAM   = { dmg = 30, radius = 90, dur = 0.50, name = "slam"  }
local BOSS_PROJ   = { dmg = 10, speed = 300, dur = 0.20, name = "proj"  }

-- ── State enum ────────────────────────────────────────────────────────────
local STATE = { TITLE = 1, COMBAT = 2, PLAYER_DIED = 3, VICTORY = 4 }
local game_state = STATE.TITLE

-- ── Mutable state ─────────────────────────────────────────────────────────
local player = {}
local boss   = {}
local projectiles = {}

-- Particles
local hit_ps, dodge_ps, block_ps, enrage_ps, death_ps

-- Timers / tweens
local hitlag       = 0
local death_timer  = 0
local death_alpha  = 0
local victory_timer = 0
local title_blink  = 0

-- ── Helpers ───────────────────────────────────────────────────────────────
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function dist(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function arena_clamp_x(x, w)
    return clamp(x, ARENA_X + 4, ARENA_X + ARENA_W - w - 4)
end

local function arena_clamp_y(y, h)
    return clamp(y, ARENA_Y + 4, ARENA_Y + ARENA_H - h - 4)
end

-- ── Reset ─────────────────────────────────────────────────────────────────
local function reset_player()
    player.x        = ARENA_X + 80
    player.y        = ARENA_Y + ARENA_H * 0.5 - PLAYER_H * 0.5
    player.hp       = PLAYER_MAX_HP
    player.hp_disp  = PLAYER_MAX_HP
    player.stamina  = PLAYER_MAX_STAM
    player.stam_disp = PLAYER_MAX_STAM
    player.facing   = 1
    player.atk_timer    = 0
    player.atk_data     = nil
    player.dodge_timer  = 0
    player.dodge_dir    = 1
    player.blocking     = false
    player.exhausted    = 0
    player.heal_timer   = 0
    player.estus        = ESTUS_MAX
    player.hit_cd       = 0
end

local function reset_boss()
    boss.x          = ARENA_X + ARENA_W - 120
    boss.y          = ARENA_Y + ARENA_H * 0.5 - BOSS_H * 0.5
    boss.hp         = BOSS_MAX_HP
    boss.hp_disp    = BOSS_MAX_HP
    boss.facing     = -1
    boss.phase      = 1
    boss.atk_timer  = 0
    boss.atk_data   = nil
    boss.windup     = 0
    boss.combo_left = 0
    boss.combo_gap  = 0
    boss.think_cd   = 1.5
    boss.dash_vx    = 0
    boss.slam_x     = 0
    boss.slam_y     = 0
    boss.slam_show  = 0
    boss.enraged    = false
    boss.flash      = 0
    boss.hit_cd     = 0
    projectiles     = {}
end

local function start_combat()
    reset_player()
    reset_boss()
    hitlag      = 0
    death_timer = 0
    death_alpha = 0
    game_state  = STATE.COMBAT
end

-- ── Boss phase check ──────────────────────────────────────────────────────
local function update_boss_phase()
    local ratio = boss.hp / BOSS_MAX_HP
    if ratio <= 0.33 and boss.phase < 3 then
        boss.phase   = 3
        boss.enraged = true
        boss.flash   = 0.6
        if enrage_ps then lurek.particle.emit(enrage_ps, boss.x + BOSS_W * 0.5, boss.y + BOSS_H * 0.5, 30) end
    elseif ratio <= 0.66 and boss.phase < 2 then
        boss.phase = 2
        boss.flash = 0.4
    end
end

-- ── Player attack logic ──────────────────────────────────────────────────
local function player_start_attack(atk)
    if player.atk_timer > 0 or player.dodge_timer > 0 or player.exhausted > 0 or player.heal_timer > 0 then return end
    if player.stamina < atk.cost then return end
    player.stamina  = player.stamina - atk.cost
    player.atk_timer = atk.dur
    player.atk_data  = atk
    player.blocking  = false
end

local function player_try_hit_boss()
    if not player.atk_data or player.hit_cd > 0 then return end
    local atk = player.atk_data
    local hb_x = player.facing == 1 and (player.x + PLAYER_W) or (player.x - 40)
    if aabb(hb_x, player.y, 40, PLAYER_H, boss.x, boss.y, BOSS_W, BOSS_H) then
        boss.hp = math.max(0, boss.hp - atk.dmg)
        lurek.tween.to(boss, 0.3, { hp_disp = boss.hp })
        player.hit_cd = player.atk_data.dur
        hitlag = HITLAG_DUR
        lurek.camera.shake(3, 0.1)
        if hit_ps then
            lurek.particle.emit(hit_ps, boss.x + BOSS_W * 0.5, boss.y + BOSS_H * 0.3, 10)
        end
        update_boss_phase()
        if boss.hp <= 0 then
            game_state   = STATE.VICTORY
            victory_timer = 0
        end
    end
end

-- ── Boss AI ───────────────────────────────────────────────────────────────
local function boss_pick_attack()
    local attacks = { BOSS_MELEE, BOSS_MELEE }
    if boss.phase >= 2 then
        attacks[#attacks + 1] = BOSS_DASH
        attacks[#attacks + 1] = BOSS_SLAM
    end
    if boss.phase >= 3 then
        attacks[#attacks + 1] = BOSS_PROJ
        attacks[#attacks + 1] = BOSS_PROJ
        attacks[#attacks + 1] = BOSS_DASH
    end
    return attacks[math.random(#attacks)]
end

local function boss_start_attack(atk)
    boss.windup   = 0.5
    boss.atk_data = atk
    boss.flash    = 0.5
end

local function boss_execute_attack()
    local atk = boss.atk_data
    if not atk then return end
    boss.atk_timer = atk.dur
    boss.hit_cd    = 0

    if atk.name == "dash" then
        boss.dash_vx = boss.facing * atk.speed
    elseif atk.name == "slam" then
        boss.slam_x = boss.x + BOSS_W * 0.5
        boss.slam_y = boss.y + BOSS_H
        boss.slam_show = 0.5
    elseif atk.name == "proj" then
        for i = -1, 1 do
            projectiles[#projectiles + 1] = {
                x  = boss.x + BOSS_W * 0.5,
                y  = boss.y + BOSS_H * 0.3 + i * 20,
                vx = boss.facing * atk.speed,
                vy = i * 40,
                life = 3.0,
            }
        end
    end
end

local function boss_deal_damage(dmg)
    if player.dodge_timer > 0 then return end  -- i-frames
    if player.blocking and player.stamina > 0 then
        local reduced = dmg * (1 - BLOCK_REDUCTION)
        player.hp = math.max(0, player.hp - reduced)
        player.stamina = math.max(0, player.stamina - BLOCK_COST_PER_HIT)
        if block_ps then
            lurek.particle.emit(block_ps, player.x + PLAYER_W * 0.5, player.y + PLAYER_H * 0.3, 8)
        end
        lurek.camera.shake(2, 0.08)
    else
        player.hp = math.max(0, player.hp - dmg)
        lurek.camera.shake(4, 0.12)
        hitlag = HITLAG_DUR
    end
    lurek.tween.to(player, 0.3, { hp_disp = player.hp })
    if player.hp <= 0 then
        game_state  = STATE.PLAYER_DIED
        death_timer = 0
        death_alpha = 0
        if death_ps then lurek.particle.emit(death_ps, player.x + PLAYER_W * 0.5, player.y + PLAYER_H * 0.5, 25) end
    end
end

local function boss_try_hit_player()
    if boss.hit_cd > 0 then return end
    local atk = boss.atk_data
    if not atk then return end

    if atk.name == "melee" or atk.name == "dash" then
        local hb_x = boss.facing == 1 and (boss.x + BOSS_W) or (boss.x - atk.range)
        local range = atk.range or 55
        if aabb(hb_x, boss.y, range, BOSS_H, player.x, player.y, PLAYER_W, PLAYER_H) then
            boss_deal_damage(atk.dmg)
            boss.hit_cd = atk.dur
        end
    elseif atk.name == "slam" then
        local d = dist(player.x + PLAYER_W * 0.5, player.y + PLAYER_H * 0.5, boss.slam_x, boss.slam_y)
        if d < atk.radius then
            boss_deal_damage(atk.dmg)
            boss.hit_cd = atk.dur
        end
    end
end

-- ── Update ────────────────────────────────────────────────────────────────
local function update_player(dt)
    -- Exhaustion
    if player.exhausted > 0 then
        player.exhausted = player.exhausted - dt
        player.blocking  = false
        return
    end

    -- Heal lock
    if player.heal_timer > 0 then
        player.heal_timer = player.heal_timer - dt
        return
    end

    -- Dodge roll
    if player.dodge_timer > 0 then
        player.dodge_timer = player.dodge_timer - dt
        player.x = player.x + player.dodge_dir * (DODGE.dist / DODGE.dur) * dt
        player.x = arena_clamp_x(player.x, PLAYER_W)
        if dodge_ps and player.dodge_timer < DODGE.dur * 0.5 then
            lurek.particle.emit(dodge_ps, player.x + PLAYER_W * 0.5, player.y + PLAYER_H, 3)
        end
        return
    end

    -- Attack timer
    if player.atk_timer > 0 then
        player.atk_timer = player.atk_timer - dt
        if player.atk_timer > player.atk_data.dur * 0.5 then
            player_try_hit_boss()
        end
        if player.atk_timer <= 0 then
            player.atk_data = nil
            player.hit_cd   = 0
        end
        return
    end

    -- Movement
    local mx, my = 0, 0
    if lurek.input.isActionDown("left")  then mx = mx - 1 end
    if lurek.input.isActionDown("right") then mx = mx + 1 end
    if lurek.input.isActionDown("up")    then my = my - 1 end
    if lurek.input.isActionDown("down")  then my = my + 1 end
    if mx ~= 0 or my ~= 0 then
        local len = math.sqrt(mx * mx + my * my)
        mx, my = mx / len, my / len
        player.x = player.x + mx * PLAYER_SPEED * dt
        player.y = player.y + my * PLAYER_SPEED * dt
        if mx ~= 0 then player.facing = mx > 0 and 1 or -1 end
    end
    player.x = arena_clamp_x(player.x, PLAYER_W)
    player.y = arena_clamp_y(player.y, PLAYER_H)

    -- Block
    player.blocking = lurek.input.isActionDown("block")

    -- Stamina regen (not while blocking or attacking)
    if not player.blocking and player.atk_timer <= 0 then
        player.stamina = math.min(PLAYER_MAX_STAM, player.stamina + STAM_REGEN * dt)
    end
    lurek.tween.to(player, 0.15, { stam_disp = player.stamina })

    -- Exhaustion trigger
    if player.stamina <= 0 then
        player.exhausted = EXHAUST_DUR
        player.blocking  = false
    end
end

local function update_boss_ai(dt)
    -- Face player
    boss.facing = player.x < boss.x and -1 or 1

    -- Windup
    if boss.windup > 0 then
        boss.windup = boss.windup - dt
        if boss.windup <= 0 then
            boss_execute_attack()
        end
        return
    end

    -- Active attack
    if boss.atk_timer > 0 then
        boss.atk_timer = boss.atk_timer - dt
        -- Dash movement
        if boss.atk_data and boss.atk_data.name == "dash" then
            boss.x = boss.x + boss.dash_vx * dt
            boss.x = arena_clamp_x(boss.x, BOSS_W)
        end
        boss_try_hit_player()
        if boss.atk_timer <= 0 then
            boss.atk_data = nil
            boss.hit_cd   = 0
            -- Combo continuation
            if boss.combo_left > 0 then
                boss.combo_left = boss.combo_left - 1
                boss.combo_gap  = 0.25
            else
                local gaps = { 1.5, 1.0, 0.6 }
                boss.think_cd = gaps[boss.phase] or 0.6
            end
        end
        return
    end

    -- Combo gap
    if boss.combo_gap > 0 then
        boss.combo_gap = boss.combo_gap - dt
        if boss.combo_gap <= 0 then
            boss_start_attack(BOSS_MELEE)
        end
        return
    end

    -- Slow move toward player
    local dx = player.x - boss.x
    local move_speed = 60 + boss.phase * 20
    if math.abs(dx) > 60 then
        boss.x = boss.x + (dx > 0 and 1 or -1) * move_speed * dt
        boss.x = arena_clamp_x(boss.x, BOSS_W)
    end

    -- Think cooldown
    boss.think_cd = boss.think_cd - dt
    if boss.think_cd <= 0 then
        local atk = boss_pick_attack()
        boss_start_attack(atk)
        -- Combo count
        local combos = { 2, 2, math.random(3, 4) }
        if atk.name == "melee" then
            boss.combo_left = (combos[boss.phase] or 2) - 1
        else
            boss.combo_left = 0
        end
    end
end

local function update_projectiles(dt)
    local i = 1
    while i <= #projectiles do
        local p = projectiles[i]
        p.x    = p.x + p.vx * dt
        p.y    = p.y + p.vy * dt
        p.life = p.life - dt

        -- Hit player
        if player.dodge_timer <= 0 and aabb(p.x - 4, p.y - 4, 8, 8, player.x, player.y, PLAYER_W, PLAYER_H) then
            boss_deal_damage(BOSS_PROJ.dmg)
            table.remove(projectiles, i)
        elseif p.life <= 0 or p.x < ARENA_X or p.x > ARENA_X + ARENA_W then
            table.remove(projectiles, i)
        else
            i = i + 1
        end
    end
end

-- ── Callbacks ─────────────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Soulslike — Lurek2D")
    gfx.setBackgroundColor(0.04, 0.03, 0.06)

    -- Input actions
    lurek.input.addAction("left",        {"a", "left"})
    lurek.input.addAction("right",       {"d", "right"})
    lurek.input.addAction("up",          {"w", "up"})
    lurek.input.addAction("down",        {"s", "down"})
    lurek.input.addAction("light_attack",{"j"})
    lurek.input.addAction("heavy_attack",{"k"})
    lurek.input.addAction("dodge",       {"l"})
    lurek.input.addAction("block",       {"space"})
    lurek.input.addAction("heal",        {"e"})
    lurek.input.addAction("start",       {"return"})
    lurek.input.addAction("quit",        {"escape"})

    -- Particle systems
    hit_ps    = lurek.particle.new({ maxParticles = 30, lifetime = 0.25,
        speed = 200, spread = math.pi, colors = {{1,0.9,0.6,1},{1,0.5,0.1,0}} })
    dodge_ps  = lurek.particle.new({ maxParticles = 15, lifetime = 0.2,
        speed = 60, spread = math.pi * 0.5, colors = {{0.7,0.7,0.6,0.8},{0.5,0.5,0.4,0}} })
    block_ps  = lurek.particle.new({ maxParticles = 20, lifetime = 0.2,
        speed = 150, spread = math.pi * 0.8, colors = {{0.4,0.6,1,1},{0.2,0.3,0.8,0}} })
    enrage_ps = lurek.particle.new({ maxParticles = 40, lifetime = 0.5,
        speed = 120, spread = math.pi, colors = {{1,0.2,0,1},{1,0.6,0,0}} })
    death_ps  = lurek.particle.new({ maxParticles = 50, lifetime = 0.8,
        speed = 80, spread = math.pi, colors = {{0.8,0.1,0.1,1},{0.3,0,0,0}} })
end

function lurek.process(dt)
    -- FPS display
    lurek.window.setTitle("Soulslike — Lurek2D | FPS: " .. lurek.timer.getFPS())

    -- Quit
    if lurek.input.isActionPressed("quit") then lurek.event.quit() end

    -- Title
    if game_state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.isActionPressed("start") then start_combat() end
        return
    end

    -- Death screen
    if game_state == STATE.PLAYER_DIED then
        death_timer = death_timer + dt
        death_alpha = math.min(1, death_timer / 1.5)
        if death_timer > 2.5 and lurek.input.isActionPressed("start") then
            start_combat()
        end
        return
    end

    -- Victory
    if game_state == STATE.VICTORY then
        victory_timer = victory_timer + dt
        if victory_timer > 3.0 and lurek.input.isActionPressed("start") then
            game_state = STATE.TITLE
        end
        return
    end

    -- Hitlag freeze
    if hitlag > 0 then
        hitlag = hitlag - dt
        return
    end

    -- Boss flash decay
    if boss.flash > 0 then boss.flash = boss.flash - dt * 2 end

    -- Slam indicator decay
    if boss.slam_show > 0 then boss.slam_show = boss.slam_show - dt end

    -- Player input: attacks, dodge, heal
    if lurek.input.isActionPressed("light_attack") then player_start_attack(LIGHT) end
    if lurek.input.isActionPressed("heavy_attack") then player_start_attack(HEAVY) end
    if lurek.input.isActionPressed("dodge") then
        if player.atk_timer <= 0 and player.dodge_timer <= 0 and player.exhausted <= 0
           and player.heal_timer <= 0 and player.stamina >= DODGE.cost then
            player.stamina     = player.stamina - DODGE.cost
            player.dodge_timer = DODGE.dur
            player.dodge_dir   = player.facing
            player.blocking    = false
        end
    end
    if lurek.input.isActionPressed("heal") then
        if player.estus > 0 and player.atk_timer <= 0 and player.dodge_timer <= 0
           and player.exhausted <= 0 and player.heal_timer <= 0 and player.hp < PLAYER_MAX_HP then
            player.estus     = player.estus - 1
            player.heal_timer = ESTUS_LOCK_DUR
            player.hp        = math.min(PLAYER_MAX_HP, player.hp + ESTUS_HEAL)
            lurek.tween.to(player, 0.4, { hp_disp = player.hp })
        end
    end

    update_player(dt)
    update_boss_ai(dt)
    update_projectiles(dt)

    -- Enrage fire particles
    if boss.enraged and math.random() < 0.3 then
        if enrage_ps then
            lurek.particle.emit(enrage_ps,
                boss.x + math.random() * BOSS_W,
                boss.y + math.random() * BOSS_H, 2)
        end
    end
end

-- ── Render: arena, fighters, effects ──────────────────────────────────────
function lurek.render()
    if game_state == STATE.TITLE then
        -- Title screen
        local cx = SCREEN_W * 0.5
        gfx.print("SOULSLIKE", cx - 90, 180, 40, {0.8, 0.15, 0.1, 1})
        gfx.print("PREPARE TO DIE", cx - 100, 240, 20, {0.6, 0.1, 0.1, 1})
        local a = math.abs(math.sin(title_blink * 2))
        gfx.print("PRESS ENTER", cx - 70, 360, 16, {0.9, 0.85, 0.7, a})
        return
    end

    -- Arena background — stone
    gfx.setColor(0.18, 0.16, 0.14, 1)
    gfx.rectangle("fill", ARENA_X, ARENA_Y, ARENA_W, ARENA_H)
    -- Arena border
    gfx.setColor(0.35, 0.30, 0.25, 1)
    gfx.rectangle("line", ARENA_X, ARENA_Y, ARENA_W, ARENA_H)
    -- Decorative inner border
    gfx.setColor(0.28, 0.24, 0.20, 1)
    gfx.rectangle("line", ARENA_X + 4, ARENA_Y + 4, ARENA_W - 8, ARENA_H - 8)

    -- Ground slam AoE indicator
    if boss.slam_show > 0 then
        local sa = boss.slam_show * 0.6
        gfx.setColor(1, 0.3, 0.1, sa)
        gfx.circle("fill", boss.slam_x, boss.slam_y, BOSS_SLAM.radius)
    end

    -- Projectiles
    for _, p in ipairs(projectiles) do
        gfx.setColor(1, 0.3, 0.8, 0.9)
        gfx.circle("fill", p.x, p.y, 4)
    end

    -- Boss
    local br, bg, bb = 0.55, 0.08, 0.08
    if boss.flash and boss.flash > 0 then
        br = br + boss.flash * 0.4
        bg = bg + boss.flash * 0.3
        bb = bb + boss.flash * 0.2
    end
    if boss.enraged then
        br = math.min(1, br + 0.15 + math.sin(lurek.timer.getTime() * 8) * 0.08)
    end
    gfx.setColor(br, bg, bb, 1)
    gfx.rectangle("fill", boss.x, boss.y, BOSS_W, BOSS_H)
    -- Glowing eyes
    local ey = boss.y + 8
    local ex1 = boss.facing == -1 and boss.x + 8 or boss.x + BOSS_W - 14
    gfx.setColor(1, 0.3, 0.1, 0.9)
    gfx.rectangle("fill", ex1, ey, 3, 3)
    gfx.rectangle("fill", ex1 + 6, ey, 3, 3)
    -- Boss windup telegraph
    if boss.windup > 0 then
        local wa = math.abs(math.sin(boss.windup * 20))
        gfx.setColor(1, 1, 0.5, wa * 0.5)
        gfx.rectangle("line", boss.x - 3, boss.y - 3, BOSS_W + 6, BOSS_H + 6)
    end

    -- Player
    local pa = (player.dodge_timer > 0) and 0.4 or 1
    local heal_glow = player.heal_timer > 0
    if player.exhausted > 0 then
        gfx.setColor(0.3, 0.3, 0.5, pa)
    elseif heal_glow then
        gfx.setColor(0.3, 0.9, 0.3, pa)
    elseif player.blocking then
        gfx.setColor(0.3, 0.5, 0.9, pa)
    else
        gfx.setColor(0.25, 0.35, 0.8, pa)
    end
    gfx.rectangle("fill", player.x, player.y, PLAYER_W, PLAYER_H)
    -- Player attack indicator
    if player.atk_timer > 0 and player.atk_data then
        local ax = player.facing == 1 and (player.x + PLAYER_W) or (player.x - 30)
        gfx.setColor(1, 1, 0.8, 0.5)
        gfx.rectangle("fill", ax, player.y + 4, 30, PLAYER_H - 8)
    end
    -- Block shield
    if player.blocking then
        local sx = player.facing == 1 and (player.x + PLAYER_W + 2) or (player.x - 6)
        gfx.setColor(0.4, 0.7, 1, 0.6)
        gfx.rectangle("fill", sx, player.y + 2, 4, PLAYER_H - 4)
    end

    -- Death fade
    if game_state == STATE.PLAYER_DIED then
        gfx.setColor(0, 0, 0, death_alpha * 0.7)
        gfx.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)
    end
end

-- ── Render UI: HP bars, stamina, estus, boss phase ────────────────────────
function lurek.render_ui()
    if game_state == STATE.TITLE then return end

    -- Player HP bar
    local php = SCREEN_W * 0.05
    local bar_w = 160
    gfx.setColor(0.2, 0.2, 0.2, 0.8)
    gfx.rectangle("fill", php, 16, bar_w, 14)
    local hp_frac = (player.hp_disp or player.hp) / PLAYER_MAX_HP
    gfx.setColor(0.8, 0.15, 0.1, 1)
    gfx.rectangle("fill", php, 16, bar_w * hp_frac, 14)
    gfx.setColor(1, 1, 1, 0.9)
    gfx.print("HP", php + 2, 17, 11, {1,1,1,0.9})

    -- Player stamina bar
    gfx.setColor(0.15, 0.15, 0.15, 0.8)
    gfx.rectangle("fill", php, 34, bar_w, 10)
    local st_frac = (player.stam_disp or player.stamina) / PLAYER_MAX_STAM
    local st_r, st_g = 0.1, 0.7
    if player.exhausted > 0 then st_r, st_g = 0.6, 0.3 end
    gfx.setColor(st_r, st_g, 0.15, 1)
    gfx.rectangle("fill", php, 34, bar_w * st_frac, 10)
    gfx.setColor(1, 1, 1, 0.7)
    gfx.print("STA", php + 2, 34, 9, {1,1,1,0.7})

    -- Estus charges
    for i = 1, ESTUS_MAX do
        local ex = php + (i - 1) * 18
        local ey = 50
        if i <= player.estus then
            gfx.setColor(0.9, 0.6, 0.1, 1)
        else
            gfx.setColor(0.3, 0.2, 0.1, 0.5)
        end
        gfx.rectangle("fill", ex, ey, 12, 16)
    end

    -- Exhausted warning
    if player.exhausted > 0 then
        local wa = math.abs(math.sin(player.exhausted * 10))
        gfx.print("EXHAUSTED", php, 70, 12, {1, 0.3, 0.1, wa})
    end

    -- Boss HP bar (top right)
    local bhp_x = SCREEN_W - 220
    local bhp_w = 200
    gfx.setColor(0.2, 0.2, 0.2, 0.8)
    gfx.rectangle("fill", bhp_x, 16, bhp_w, 18)
    local boss_frac = (boss.hp_disp or boss.hp) / BOSS_MAX_HP
    local bossR = boss.enraged and 0.9 or 0.6
    gfx.setColor(bossR, 0.08, 0.12, 1)
    gfx.rectangle("fill", bhp_x, 16, bhp_w * boss_frac, 18)
    -- Phase markers
    gfx.setColor(1, 1, 1, 0.3)
    gfx.rectangle("fill", bhp_x + bhp_w * 0.66, 16, 1, 18)
    gfx.rectangle("fill", bhp_x + bhp_w * 0.33, 16, 1, 18)
    -- Phase label
    gfx.print("BOSS  P" .. boss.phase, bhp_x + 4, 18, 12, {1,1,1,0.9})

    -- Death overlay
    if game_state == STATE.PLAYER_DIED then
        if death_timer > 1.0 then
            local ta = math.min(1, (death_timer - 1.0) / 0.8)
            gfx.print("YOU DIED", SCREEN_W * 0.5 - 80, SCREEN_H * 0.4, 36, {0.7, 0.1, 0.05, ta})
            if death_timer > 2.5 then
                local ra = math.abs(math.sin(death_timer * 2))
                gfx.print("Press ENTER to retry", SCREEN_W * 0.5 - 90, SCREEN_H * 0.55, 14, {0.8, 0.7, 0.6, ra})
            end
        end
    end

    -- Victory overlay
    if game_state == STATE.VICTORY then
        local va = math.min(1, victory_timer / 1.0)
        gfx.print("VICTORY", SCREEN_W * 0.5 - 70, SCREEN_H * 0.4, 36, {1, 0.85, 0.2, va})
        if victory_timer > 1.5 then
            gfx.print("HEIR OF FIRE DESTROYED", SCREEN_W * 0.5 - 110, SCREEN_H * 0.5, 16, {0.9, 0.8, 0.6, va})
        end
        if victory_timer > 3.0 then
            local ra = math.abs(math.sin(victory_timer * 2))
            gfx.print("Press ENTER", SCREEN_W * 0.5 - 55, SCREEN_H * 0.6, 14, {0.8, 0.7, 0.6, ra})
        end
    end
end
