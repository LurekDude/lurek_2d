-- ============================================================================
--  Fighting Game — 1v1 Player vs AI with combos, super meter, best of 3
-- ----------------------------------------------------------------------------
--  Category : action
--  Run with : cargo run -- content/games/action/fighting_game
--
--  Controls (bound as input actions — see lurek.init):
--    left/right : A / D          punch : F
--    jump       : W              kick  : G
--    block      : H              super : Q
--    start      : Enter          quit  : Escape
--
--  lurek.* namespaces used:
--    window, render, input, time, signal, particles, tween, camera
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────────────

local SCREEN_W, SCREEN_H = 800, 600
local GROUND_Y           = 480          -- stage floor top
local GRAVITY            = 1800
local MOVE_SPEED         = 220
local JUMP_VEL           = -550
local FIGHTER_W, FIGHTER_H = 40, 80

-- Attack data
local PUNCH = { dmg = 8,  range = 50, dur = 0.15, cooldown = 0.25, stun = 0.12, name = "punch" }
local KICK  = { dmg = 15, range = 60, dur = 0.25, cooldown = 0.40, stun = 0.20, name = "kick"  }
local SUPER = { dmg = 30, range = 70, dur = 0.30, cooldown = 0.50, stun = 0.35, knockback = 300 }

-- Combo
local COMBO_WINDOW = 0.5    -- seconds between hits to chain a combo
local COMBO_BONUS  = 3      -- extra damage per combo step

-- Super meter
local METER_MAX       = 100
local METER_ON_HIT    = 5
local METER_ON_BLOCK  = 3

-- Round
local ROUNDS_TO_WIN   = 2
local ROUND_DELAY     = 2.0  -- seconds before next round starts

-- Screen shake
local SHAKE_HEAVY     = 6
local SHAKE_LIGHT     = 3

-- ── Scene state ───────────────────────────────────────────────────────────
local STATE = { TITLE = 1, FIGHTING = 2, ROUND_END = 3, MATCH_OVER = 4 }
local state = STATE.TITLE

-- ── Fighter factory ──────────────────────────────────────────────────────
local function new_fighter(x, facing, is_ai)
    return {
        x = x, y = GROUND_Y - FIGHTER_H,
        vx = 0, vy = 0,
        facing = facing,            -- 1 = right, -1 = left
        hp = 100, max_hp = 100,
        hp_display = 100,           -- for tween smooth drain
        meter = 0,
        meter_display = 0,
        wins = 0,
        grounded = true,
        blocking = false,
        stunned = 0,                -- stun timer
        atk_timer = 0,              -- active attack duration
        atk_cooldown = 0,           -- cannot attack until 0
        cur_attack = nil,           -- ref to PUNCH/KICK/SUPER
        combo = 0,
        combo_timer = 0,
        is_ai = is_ai,
    }
end

local p1, p2
local round_num      = 1
local round_timer    = 0
local round_text     = ""
local round_text_alpha = 0
local match_winner   = ""

-- Camera shake
local shake_amount = 0
local shake_timer  = 0

-- Particles
local hit_sparks    = nil
local block_sparks  = nil
local super_flash   = nil

-- Title blink
local title_blink = 0

-- ── Helpers ──────────────────────────────────────────────────────────────
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function reset_fighters()
    p1 = new_fighter(200, 1, false)
    p2 = new_fighter(560, -1, true)
end

local function start_round()
    reset_fighters()
    state = STATE.FIGHTING
    round_text = "ROUND " .. round_num
    round_text_alpha = 1.0
end

local function trigger_shake(amount)
    shake_amount = amount
    shake_timer  = 0.15
end

-- ── Hit detection ────────────────────────────────────────────────────────
local function try_hit(attacker, defender)
    if attacker.atk_timer <= 0 or attacker.cur_attack == nil then return end
    -- Check only on first frame of attack
    if attacker.cur_attack == PUNCH and attacker.atk_timer < PUNCH.dur - 0.016 then return end
    if attacker.cur_attack == KICK  and attacker.atk_timer < KICK.dur  - 0.016 then return end
    if attacker.cur_attack == SUPER and attacker.atk_timer < SUPER.dur - 0.016 then return end

    local atk = attacker.cur_attack
    local hb_x = attacker.x + (attacker.facing == 1 and FIGHTER_W or -atk.range)
    local hb_w = atk.range

    -- Defender box
    local dx = defender.x
    local dw = FIGHTER_W

    -- AABB overlap check
    if hb_x < dx + dw and hb_x + hb_w > dx and
       attacker.y < defender.y + FIGHTER_H and attacker.y + FIGHTER_H > defender.y then

        if defender.blocking and defender.grounded then
            -- Blocked
            attacker.meter = math.min(METER_MAX, attacker.meter + METER_ON_BLOCK)
            defender.meter = math.min(METER_MAX, defender.meter + METER_ON_BLOCK)
            if block_sparks then
                local sx = (attacker.facing == 1) and (defender.x) or (defender.x + FIGHTER_W)
                lurek.particle.emit(block_sparks, sx, defender.y + FIGHTER_H * 0.5, 8)
            end
            trigger_shake(SHAKE_LIGHT)
        else
            -- Hit lands
            local combo_dmg = attacker.combo * COMBO_BONUS
            local total_dmg = atk.dmg + combo_dmg
            defender.hp = math.max(0, defender.hp - total_dmg)
            defender.stunned = atk.stun
            attacker.meter = math.min(METER_MAX, attacker.meter + METER_ON_HIT)

            -- Combo tracking
            attacker.combo = attacker.combo + 1
            attacker.combo_timer = COMBO_WINDOW

            -- Knockback for super
            if atk == SUPER and SUPER.knockback then
                defender.vx = attacker.facing * SUPER.knockback
            end

            -- Particles
            if hit_sparks then
                local sx = (attacker.facing == 1) and (defender.x) or (defender.x + FIGHTER_W)
                lurek.particle.emit(hit_sparks, sx, defender.y + FIGHTER_H * 0.4, 12)
            end
            if atk == SUPER and super_flash then
                lurek.particle.emit(super_flash, (attacker.x + defender.x) * 0.5 + FIGHTER_W * 0.5,
                    attacker.y + FIGHTER_H * 0.5, 20)
            end

            trigger_shake(atk == SUPER and SHAKE_HEAVY or SHAKE_LIGHT)

            -- Tween HP bar
            lurek.tween.to(defender, 0.3, { hp_display = defender.hp })
        end
        -- Prevent multi-hit: clear the attack
        attacker.cur_attack = nil
    end
end

-- ── Attack start ─────────────────────────────────────────────────────────
local function start_attack(fighter, atk_data)
    if fighter.atk_cooldown > 0 or fighter.stunned > 0 then return end
    if atk_data == SUPER and fighter.meter < METER_MAX then return end
    fighter.cur_attack   = atk_data
    fighter.atk_timer    = atk_data.dur
    fighter.atk_cooldown = atk_data.cooldown
    if atk_data == SUPER then
        fighter.meter = 0
        lurek.tween.to(fighter, 0.3, { meter_display = 0 })
    end
end

-- ── AI logic ─────────────────────────────────────────────────────────────
local ai_think_timer = 0

local function update_ai(dt)
    if p2.stunned > 0 then return end
    ai_think_timer = ai_think_timer - dt
    if ai_think_timer > 0 then return end
    ai_think_timer = 0.1 + math.random() * 0.15

    local dist = math.abs(p2.x - p1.x)

    -- Face player
    p2.facing = p1.x < p2.x and -1 or 1

    -- Block randomly when close
    p2.blocking = false
    if dist < 100 and math.random() < 0.3 then
        p2.blocking = true
        return
    end

    -- Attack when close
    if dist < 70 then
        if p2.meter >= METER_MAX and math.random() < 0.4 then
            start_attack(p2, SUPER)
        elseif math.random() < 0.5 then
            start_attack(p2, PUNCH)
        else
            start_attack(p2, KICK)
        end
        return
    end

    -- Approach
    if dist > 80 then
        p2.vx = p2.facing * MOVE_SPEED * 0.8
    else
        p2.vx = 0
    end

    -- Random jump
    if p2.grounded and math.random() < 0.05 then
        p2.vy = JUMP_VEL
        p2.grounded = false
    end
end

-- ── Physics step ─────────────────────────────────────────────────────────
local function update_fighter(f, dt)
    -- Stun
    if f.stunned > 0 then
        f.stunned = f.stunned - dt
        f.vx = f.vx * 0.85  -- friction while stunned
    end

    -- Attack timers
    if f.atk_timer > 0 then
        f.atk_timer = f.atk_timer - dt
    end
    if f.atk_cooldown > 0 then
        f.atk_cooldown = f.atk_cooldown - dt
    end

    -- Combo decay
    if f.combo_timer > 0 then
        f.combo_timer = f.combo_timer - dt
        if f.combo_timer <= 0 then
            f.combo = 0
        end
    end

    -- Gravity
    if not f.grounded then
        f.vy = f.vy + GRAVITY * dt
    end

    -- Position
    f.x = f.x + f.vx * dt
    f.y = f.y + f.vy * dt

    -- Ground collision
    if f.y + FIGHTER_H >= GROUND_Y then
        f.y = GROUND_Y - FIGHTER_H
        f.vy = 0
        f.grounded = true
    end

    -- Stage bounds
    f.x = clamp(f.x, 0, SCREEN_W - FIGHTER_W)

    -- Friction
    if f.grounded and not f.is_ai then
        f.vx = f.vx * 0.8
    end

    -- Smooth meter display
    f.meter_display = f.meter_display + (f.meter - f.meter_display) * dt * 8
end

-- ── lurek.init ────────────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Fighting Game — Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.05, 0.15)

    -- Input actions
    lurek.input.bind("left",  {"a", "left"})
    lurek.input.bind("right", {"d", "right"})
    lurek.input.bind("jump",  {"w", "up"})
    lurek.input.bind("punch", {"f"})
    lurek.input.bind("kick",  {"g"})
    lurek.input.bind("block", {"h"})
    lurek.input.bind("super", {"q"})
    lurek.input.bind("quit",  {"escape"})

    -- Particles — hit sparks (orange)
    hit_sparks = lurek.particle.new({
        maxParticles  = 60,
        emissionRate  = 0,
        lifetime      = {0.15, 0.35},
        speed         = {80, 200},
        direction     = 0,
        spread        = math.pi * 2,
        colors        = {{1.0, 0.6, 0.1, 1}, {1.0, 0.3, 0.0, 0}},
        sizes          = {4, 1},
    })

    -- Block sparks (blue)
    block_sparks = lurek.particle.new({
        maxParticles  = 40,
        emissionRate  = 0,
        lifetime      = {0.1, 0.25},
        speed         = {60, 150},
        direction     = 0,
        spread        = math.pi * 2,
        colors        = {{0.3, 0.5, 1.0, 1}, {0.1, 0.3, 0.8, 0}},
        sizes          = {3, 1},
    })

    -- Super flash (yellow)
    super_flash = lurek.particle.new({
        maxParticles  = 80,
        emissionRate  = 0,
        lifetime      = {0.2, 0.5},
        speed         = {100, 300},
        direction     = 0,
        spread        = math.pi * 2,
        colors        = {{1.0, 1.0, 0.2, 1}, {1.0, 0.8, 0.0, 0}},
        sizes          = {6, 2},
    })

    lurek.timer.setTargetFPS(60)
    reset_fighters()
end

-- ── lurek.process ─────────────────────────────────────────────────────────
function lurek.process(dt)
    title_blink = title_blink + dt

    -- Shake decay
    if shake_timer > 0 then
        shake_timer = shake_timer - dt
        if shake_timer <= 0 then shake_amount = 0 end
    end

    -- Round text fade
    if round_text_alpha > 0 then
        round_text_alpha = round_text_alpha - dt * 0.8
        if round_text_alpha < 0 then round_text_alpha = 0 end
    end

    -- Quit
    if lurek.input.wasActionPressed("quit") then
        lurek.event.quit()
        return
    end

    -- ── TITLE ─────────────────────────────────────────────────────────
    if state == STATE.TITLE then
        if lurek.input.isKeyJustPressed("return") then
            round_num = 1
            start_round()
        end
        return
    end

    -- ── MATCH OVER ────────────────────────────────────────────────────
    if state == STATE.MATCH_OVER then
        if lurek.input.isKeyJustPressed("return") then
            round_num = 1
            state = STATE.TITLE
        end
        return
    end

    -- ── ROUND END ─────────────────────────────────────────────────────
    if state == STATE.ROUND_END then
        round_timer = round_timer - dt
        if round_timer <= 0 then
            -- Check for match win
            if p1.wins >= ROUNDS_TO_WIN then
                match_winner = "PLAYER WINS!"
                state = STATE.MATCH_OVER
            elseif p2.wins >= ROUNDS_TO_WIN then
                match_winner = "AI WINS!"
                state = STATE.MATCH_OVER
            else
                round_num = round_num + 1
                start_round()
            end
        end
        return
    end

    -- ── FIGHTING ──────────────────────────────────────────────────────

    -- Player input
    p1.blocking = false
    if p1.stunned <= 0 then
        if lurek.input.isActionDown("left") then
            p1.vx = -MOVE_SPEED
            p1.facing = -1
        elseif lurek.input.isActionDown("right") then
            p1.vx = MOVE_SPEED
            p1.facing = 1
        end
        if lurek.input.wasActionPressed("jump") and p1.grounded then
            p1.vy = JUMP_VEL
            p1.grounded = false
        end
        if lurek.input.wasActionPressed("punch") then start_attack(p1, PUNCH) end
        if lurek.input.wasActionPressed("kick")  then start_attack(p1, KICK)  end
        if lurek.input.wasActionPressed("super") then start_attack(p1, SUPER) end
        if lurek.input.isActionDown("block") then
            p1.blocking = true
        end
    end

    -- AI
    update_ai(dt)

    -- Physics
    update_fighter(p1, dt)
    update_fighter(p2, dt)

    -- Face each other (player keeps manual facing, AI auto-faces)
    p2.facing = p1.x < p2.x and -1 or 1

    -- Hit detection
    try_hit(p1, p2)
    try_hit(p2, p1)

    -- Particles update
    lurek.particle.update(hit_sparks, dt)
    lurek.particle.update(block_sparks, dt)
    lurek.particle.update(super_flash, dt)

    -- Check KO
    if p2.hp <= 0 then
        p1.wins = p1.wins + 1
        round_text = p1.wins >= ROUNDS_TO_WIN and "PLAYER WINS!" or ("ROUND " .. round_num .. " — P1 WINS")
        round_text_alpha = 1.0
        state = STATE.ROUND_END
        round_timer = ROUND_DELAY
    elseif p1.hp <= 0 then
        p2.wins = p2.wins + 1
        round_text = p2.wins >= ROUNDS_TO_WIN and "AI WINS!" or ("ROUND " .. round_num .. " — AI WINS")
        round_text_alpha = 1.0
        state = STATE.ROUND_END
        round_timer = ROUND_DELAY
    end
end

-- ── Draw fighter ─────────────────────────────────────────────────────────
local function draw_fighter(f, body_r, body_g, body_b, accent_r, accent_g, accent_b)
    local x, y = f.x, f.y

    -- Legs (two small rectangles)
    lurek.render.setColor(body_r * 0.7, body_g * 0.7, body_b * 0.7, 1)
    lurek.render.rectangle("fill", x + 4, y + FIGHTER_H - 16, 12, 16)
    lurek.render.rectangle("fill", x + FIGHTER_W - 16, y + FIGHTER_H - 16, 12, 16)

    -- Body
    lurek.render.setColor(body_r, body_g, body_b, 1)
    lurek.render.rectangle("fill", x, y, FIGHTER_W, FIGHTER_H - 16)

    -- Head accent stripe
    lurek.render.setColor(accent_r, accent_g, accent_b, 1)
    lurek.render.rectangle("fill", x + 8, y + 4, FIGHTER_W - 16, 12)

    -- Arm (extends toward facing)
    if f.atk_timer > 0 and f.cur_attack then
        -- Attacking arm — extended
        local arm_len = f.cur_attack.range * 0.6
        local arm_x = f.facing == 1 and (x + FIGHTER_W) or (x - arm_len)
        lurek.render.setColor(accent_r, accent_g, accent_b, 1)
        lurek.render.rectangle("fill", arm_x, y + 20, arm_len, 10)
    else
        -- Resting arm
        local arm_x = f.facing == 1 and (x + FIGHTER_W - 4) or (x - 8)
        lurek.render.setColor(body_r * 0.8, body_g * 0.8, body_b * 0.8, 1)
        lurek.render.rectangle("fill", arm_x, y + 22, 12, 8)
    end

    -- Block indicator
    if f.blocking then
        lurek.render.setColor(1, 1, 1, 0.3)
        lurek.render.rectangle("fill", x - 4, y - 4, FIGHTER_W + 8, FIGHTER_H + 4)
    end

    -- Stun indicator
    if f.stunned > 0 then
        lurek.render.setColor(1, 1, 0, 0.4)
        lurek.render.rectangle("fill", x, y - 6, FIGHTER_W, 4)
    end

    -- Attack hitbox overlay
    if f.atk_timer > 0 and f.cur_attack then
        local atk = f.cur_attack
        local hb_x = f.facing == 1 and (x + FIGHTER_W) or (x - atk.range)
        local alpha = atk == SUPER and 0.35 or 0.2
        local hr, hg, hb = 1, 0.3, 0.3
        if atk == SUPER then hr, hg, hb = 1, 1, 0.2 end
        lurek.render.setColor(hr, hg, hb, alpha)
        lurek.render.rectangle("fill", hb_x, y, atk.range, FIGHTER_H)
    end
end

-- ── lurek.render ─────────────────────────────────────────────────────────
function lurek.draw()
    -- Camera shake offset
    local ox, oy = 0, 0
    if shake_timer > 0 then
        ox = (math.random() - 0.5) * shake_amount * 2
        oy = (math.random() - 0.5) * shake_amount * 2
    end
    lurek.camera.setPosition(ox, oy)

    if state == STATE.TITLE then
        -- Title background accents
        lurek.render.setColor(0.15, 0.08, 0.25, 1)
        lurek.render.rectangle("fill", 100, 180, 600, 200)
        return
    end

    -- Stage floor
    lurek.render.setColor(0.35, 0.22, 0.12, 1)
    lurek.render.rectangle("fill", 0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y)

    -- Stage floor line
    lurek.render.setColor(0.5, 0.35, 0.18, 1)
    lurek.render.rectangle("fill", 0, GROUND_Y, SCREEN_W, 3)

    -- Stage side walls (decorative)
    lurek.render.setColor(0.2, 0.12, 0.08, 1)
    lurek.render.rectangle("fill", 0, GROUND_Y - 120, 8, 120)
    lurek.render.rectangle("fill", SCREEN_W - 8, GROUND_Y - 120, 8, 120)

    -- Fighters
    draw_fighter(p1, 0.2, 0.4, 0.9,  0.3, 0.8, 0.9)   -- blue body, cyan accent
    draw_fighter(p2, 0.9, 0.2, 0.2,  1.0, 0.5, 0.2)    -- red body, orange accent

    -- Particles
    lurek.particle.draw(hit_sparks)
    lurek.particle.draw(block_sparks)
    lurek.particle.draw(super_flash)
end

-- ── lurek.render_ui ──────────────────────────────────────────────────────
function lurek.draw_ui()
    lurek.render.setColor(1, 1, 1, 1)

    -- ── TITLE SCREEN ─────────────────────────────────────────────────
    if state == STATE.TITLE then
        lurek.render.setColor(0.3, 0.6, 1.0, 1)
        lurek.render.print("FIGHTING GAME", SCREEN_W * 0.5 - 130, 200, 0, 3, 3)
        lurek.render.setColor(0.9, 0.4, 0.2, 1)
        lurek.render.print("Player vs AI — Best of 3 Rounds", SCREEN_W * 0.5 - 145, 260, 0, 1.2, 1.2)

        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1, 0.9)
            lurek.render.print("PRESS ENTER", SCREEN_W * 0.5 - 75, 340, 0, 1.5, 1.5)
        end

        -- Controls
        lurek.render.setColor(0.6, 0.6, 0.6, 1)
        lurek.render.print("A/D = Move   W = Jump   F = Punch   G = Kick", 160, 430)
        lurek.render.print("H = Block   Q = Super   ESC = Quit", 200, 455)

        lurek.render.setColor(0.4, 0.4, 0.4, 1)
        lurek.render.print("FPS: " .. lurek.timer.getFPS(), 4, SCREEN_H - 18)
        return
    end

    -- ── HP BARS ──────────────────────────────────────────────────────
    local bar_w = 300
    local bar_h = 20
    local bar_y = 20

    -- P1 HP bar (left side)
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.rectangle("fill", 20, bar_y, bar_w, bar_h)
    local p1_frac = clamp(p1.hp_display / p1.max_hp, 0, 1)
    local p1r = 0.2 + (1 - p1_frac) * 0.8
    local p1g = p1_frac * 0.8
    lurek.render.setColor(p1r, p1g, 0.1, 1)
    lurek.render.rectangle("fill", 20, bar_y, bar_w * p1_frac, bar_h)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("P1", 24, bar_y + 2)
    lurek.render.print(math.floor(p1.hp) .. " HP", 20 + bar_w - 50, bar_y + 2)

    -- P2 HP bar (right side)
    local p2_bar_x = SCREEN_W - 20 - bar_w
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.rectangle("fill", p2_bar_x, bar_y, bar_w, bar_h)
    local p2_frac = clamp(p2.hp_display / p2.max_hp, 0, 1)
    local p2r = 0.2 + (1 - p2_frac) * 0.8
    local p2g = p2_frac * 0.8
    lurek.render.setColor(p2r, p2g, 0.1, 1)
    lurek.render.rectangle("fill", p2_bar_x + bar_w * (1 - p2_frac), bar_y, bar_w * p2_frac, bar_h)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("AI", p2_bar_x + bar_w - 24, bar_y + 2)
    lurek.render.print(math.floor(p2.hp) .. " HP", p2_bar_x + 4, bar_y + 2)

    -- ── SUPER METER ─────────────────────────────────────────────────
    local meter_w = 120
    local meter_h = 8
    local meter_y = bar_y + bar_h + 6

    -- P1 meter
    lurek.render.setColor(0.15, 0.15, 0.15, 0.7)
    lurek.render.rectangle("fill", 20, meter_y, meter_w, meter_h)
    local m1_frac = clamp(p1.meter_display / METER_MAX, 0, 1)
    if p1.meter >= METER_MAX then
        lurek.render.setColor(1.0, 0.9, 0.1, 1)
    else
        lurek.render.setColor(0.2, 0.5, 0.9, 0.9)
    end
    lurek.render.rectangle("fill", 20, meter_y, meter_w * m1_frac, meter_h)
    lurek.render.setColor(0.7, 0.7, 0.7, 1)
    lurek.render.print("SUPER", 20 + meter_w + 6, meter_y - 2, 0, 0.8, 0.8)

    -- P2 meter
    local m2_x = SCREEN_W - 20 - meter_w
    lurek.render.setColor(0.15, 0.15, 0.15, 0.7)
    lurek.render.rectangle("fill", m2_x, meter_y, meter_w, meter_h)
    local m2_frac = clamp(p2.meter_display / METER_MAX, 0, 1)
    if p2.meter >= METER_MAX then
        lurek.render.setColor(1.0, 0.9, 0.1, 1)
    else
        lurek.render.setColor(0.9, 0.3, 0.2, 0.9)
    end
    lurek.render.rectangle("fill", m2_x + meter_w * (1 - m2_frac), meter_y, meter_w * m2_frac, meter_h)
    lurek.render.setColor(0.7, 0.7, 0.7, 1)
    lurek.render.print("SUPER", m2_x - 50, meter_y - 2, 0, 0.8, 0.8)

    -- ── ROUND SCORE ─────────────────────────────────────────────────
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("ROUND " .. round_num, SCREEN_W * 0.5 - 30, 8)

    -- Win dots
    for i = 1, ROUNDS_TO_WIN do
        local dot_r = i <= p1.wins and 0.3 or 0.2
        local dot_g = i <= p1.wins and 0.8 or 0.2
        local dot_b = i <= p1.wins and 1.0 or 0.2
        lurek.render.setColor(dot_r, dot_g, dot_b, 1)
        lurek.render.rectangle("fill", 20 + (i - 1) * 18, 8, 12, 12)
    end
    for i = 1, ROUNDS_TO_WIN do
        local dot_r = i <= p2.wins and 1.0 or 0.2
        local dot_g = i <= p2.wins and 0.3 or 0.2
        local dot_b = 0.2
        lurek.render.setColor(dot_r, dot_g, dot_b, 1)
        lurek.render.rectangle("fill", SCREEN_W - 20 - i * 18, 8, 12, 12)
    end

    -- ── COMBO COUNTER ───────────────────────────────────────────────
    if p1.combo > 1 then
        lurek.render.setColor(1.0, 0.8, 0.1, 1)
        lurek.render.print(p1.combo .. " HIT COMBO!", p1.x - 20, p1.y - 30, 0, 1.2, 1.2)
    end
    if p2.combo > 1 then
        lurek.render.setColor(1.0, 0.4, 0.1, 1)
        lurek.render.print(p2.combo .. " HIT COMBO!", p2.x - 20, p2.y - 30, 0, 1.2, 1.2)
    end

    -- ── ROUND TEXT OVERLAY ──────────────────────────────────────────
    if round_text_alpha > 0.01 then
        lurek.render.setColor(1, 1, 1, round_text_alpha)
        lurek.render.print(round_text, SCREEN_W * 0.5 - 100, SCREEN_H * 0.4, 0, 2, 2)
    end

    -- ── MATCH OVER ──────────────────────────────────────────────────
    if state == STATE.MATCH_OVER then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle("fill", 0, SCREEN_H * 0.3, SCREEN_W, 120)
        lurek.render.setColor(1, 0.9, 0.2, 1)
        lurek.render.print(match_winner, SCREEN_W * 0.5 - 120, SCREEN_H * 0.35, 0, 3, 3)
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1, 0.8)
            lurek.render.print("PRESS ENTER", SCREEN_W * 0.5 - 75, SCREEN_H * 0.35 + 60, 0, 1.5, 1.5)
        end
    end

    -- FPS
    lurek.render.setColor(0.4, 0.4, 0.4, 1)
    lurek.render.print("FPS: " .. lurek.timer.getFPS(), 4, SCREEN_H - 18)
end
