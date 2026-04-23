-- ============================================================================
-- Demo Game — Lurek2D
-- ============================================================================
-- Category : showcase
-- Source   : content/games/showcase/demo_game/main.lua
-- Run with : cargo run -- content/games/showcase/demo_game
-- ============================================================================
-- Physics shooting gallery: aim with mouse, fire balls at swaying targets.
-- Combo scoring, power-ups, three rounds of increasing difficulty.
-- Controls: Mouse aim, Left Click fire, Escape quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

local SCREEN_W, SCREEN_H = 800, 600
local GRAVITY = 400
local BALL_SPEED = 500
local BALL_RADIUS = 6
local BALL_LIFETIME = 3.0
local MAX_BALLS = 10
local MAX_ROUNDS = 3
local MAX_COMBO_MULT = 4

local STATE = { TITLE = 1, PLAYING = 2, ROUND_END = 3, GAME_OVER = 4 }
local current_state = STATE.TITLE

local POWERUP = { TRIPLE = 1, BIG = 2, SLOWMO = 3 }
local POWERUP_COLORS = {
    [POWERUP.TRIPLE] = { 1.0, 0.3, 0.3 },
    [POWERUP.BIG]    = { 0.3, 1.0, 0.4 },
    [POWERUP.SLOWMO] = { 0.3, 0.5, 1.0 },
}

-- Target row definitions: { y, count, w, h, points, base_speed }
local ROW_DEFS = {
    { y = 80,  count = 6, w = 60, h = 40, points = 1, base_speed = 40  },
    { y = 150, count = 7, w = 40, h = 40, points = 2, base_speed = 55  },
    { y = 220, count = 8, w = 20, h = 20, points = 3, base_speed = 70  },
    { y = 290, count = 7, w = 40, h = 40, points = 2, base_speed = 85  },
    { y = 360, count = 5, w = 60, h = 40, points = 1, base_speed = 100 },
}

-- Colors
local COL_BG           = { 0.15, 0.1, 0.05 }
local COL_CROSSHAIR    = { 1.0, 0.3, 0.2 }
local COL_BALL         = { 1.0, 0.85, 0.3 }
local COL_BALL_BIG     = { 0.6, 1.0, 0.4 }
local COL_TARGET_SMALL = { 0.9, 0.25, 0.2 }
local COL_TARGET_MED   = { 0.85, 0.6, 0.15 }
local COL_TARGET_LARGE = { 0.3, 0.65, 0.85 }
local COL_TEXT         = { 1.0, 1.0, 1.0 }
local COL_HUD          = { 1.0, 0.9, 0.7 }
local COL_COMBO        = { 1.0, 0.8, 0.2 }
local COL_TITLE        = { 1.0, 0.85, 0.4 }
local COL_SUBTITLE     = { 0.8, 0.7, 0.5 }
local COL_FLOOR        = { 0.25, 0.18, 0.1 }

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local balls = {}
local targets = {}
local powerups = {}
local score_popups = {}

local score = 0
local total_shots = 0
local total_hits = 0
local balls_remaining = MAX_BALLS
local current_round = 1
local combo = 0
local best_combo = 0
local combo_mult = 1

-- Power-up state
local triple_shots = 0      -- remaining triple-shot balls
local big_ball_shots = 0     -- remaining big-ball shots
local slowmo_timer = 0       -- seconds of slow-mo remaining
local targets_destroyed = 0  -- counter for power-up drops

-- Crosshair
local crosshair_x = SCREEN_W / 2
local crosshair_y = SCREEN_H / 2

-- Round transition
local round_timer = 0
local ROUND_DELAY = 2.0

-- Camera & particles
local camera = nil
local ps_explode = nil
local ps_trail = nil
local ps_powerup = nil

-- Tween animation values
local combo_scale = { s = 1.0 }
local title_alpha = { a = 1.0 }

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function aabb_circle(cx, cy, cr, rx, ry, rw, rh)
    local nx = clamp(cx, rx, rx + rw)
    local ny = clamp(cy, ry, ry + rh)
    local dx, dy = cx - nx, cy - ny
    return dx * dx + dy * dy <= cr * cr
end

local function target_color(pts)
    if pts == 3 then return COL_TARGET_SMALL end
    if pts == 2 then return COL_TARGET_MED end
    return COL_TARGET_LARGE
end

-- ---------------------------------------------------------------------------
-- Target generation
-- ---------------------------------------------------------------------------
local function generate_targets(round)
    targets = {}
    targets_destroyed = 0
    local speed_mult = 1.0 + (round - 1) * 0.35

    for _, row in ipairs(ROW_DEFS) do
        local spacing = (SCREEN_W - 80) / row.count
        for i = 1, row.count do
            local base_x = 40 + (i - 1) * spacing + spacing / 2 - row.w / 2
            targets[#targets + 1] = {
                x = base_x, y = row.y, w = row.w, h = row.h,
                points = row.points,
                base_x = base_x,
                speed = row.base_speed * speed_mult,
                phase = math.random() * 6.28,
                alive = true,
            }
        end
    end
end

-- ---------------------------------------------------------------------------
-- Shooting
-- ---------------------------------------------------------------------------
local function spawn_ball(origin_x, origin_y, target_x, target_y)
    local dx = target_x - origin_x
    local dy = target_y - origin_y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then dx, dy = 0, -1; len = 1 end
    dx, dy = dx / len, dy / len

    local radius = BALL_RADIUS
    if big_ball_shots > 0 then
        radius = BALL_RADIUS * 2
        big_ball_shots = big_ball_shots - 1
    end

    balls[#balls + 1] = {
        x = origin_x, y = origin_y,
        vx = dx * BALL_SPEED, vy = dy * BALL_SPEED,
        radius = radius, life = BALL_LIFETIME,
    }
end

local function fire(cx, cy)
    if balls_remaining <= 0 then return end
    local ox, oy = SCREEN_W / 2, SCREEN_H - 30

    if triple_shots > 0 then
        triple_shots = triple_shots - 1
        local dx = cx - ox
        local dy = cy - oy
        local ang = math.atan2(dy, dx)
        local spread = 0.15
        for _, offset in ipairs({ -spread, 0, spread }) do
            local a = ang + offset
            local tx = ox + math.cos(a) * 400
            local ty = oy + math.sin(a) * 400
            spawn_ball(ox, oy, tx, ty)
        end
        balls_remaining = balls_remaining - 1
        total_shots = total_shots + 1
    else
        spawn_ball(ox, oy, cx, cy)
        balls_remaining = balls_remaining - 1
        total_shots = total_shots + 1
    end
end

-- ---------------------------------------------------------------------------
-- Power-up spawning and collection
-- ---------------------------------------------------------------------------
local function spawn_powerup(x, y)
    local kind = math.random(1, 3)
    powerups[#powerups + 1] = {
        x = x, y = y, vy = 60, kind = kind,
        life = 6.0, t = 0,
    }
end

local function collect_powerup(pu)
    if pu.kind == POWERUP.TRIPLE then
        triple_shots = triple_shots + 3
    elseif pu.kind == POWERUP.BIG then
        big_ball_shots = big_ball_shots + 3
    elseif pu.kind == POWERUP.SLOWMO then
        slowmo_timer = slowmo_timer + 5.0
    end
    if ps_powerup then ps_powerup:emit(pu.x, pu.y, 20) end
end

-- ---------------------------------------------------------------------------
-- Score popup
-- ---------------------------------------------------------------------------
local function add_score_popup(x, y, value, mult)
    local text = "+" .. tostring(value)
    if mult > 1 then text = text .. " x" .. tostring(mult) end
    local popup = { x = x, y = y, text = text, life = 1.0, max_life = 1.0 }
    score_popups[#score_popups + 1] = popup
    lurek.tween.to(popup, 1.0, { y = y - 50 }, "outQuad")
end

-- ---------------------------------------------------------------------------
-- Reset round / game
-- ---------------------------------------------------------------------------
local function start_round(round)
    current_round = round
    balls_remaining = MAX_BALLS
    balls = {}
    powerups = {}
    score_popups = {}
    combo = 0
    combo_mult = 1
    triple_shots = 0
    big_ball_shots = 0
    slowmo_timer = 0
    generate_targets(round)
end

local function start_game()
    score = 0
    total_shots = 0
    total_hits = 0
    best_combo = 0
    current_state = STATE.PLAYING
    start_round(1)
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------
function lurek.init()
    lurek.window.setTitle("Demo Game — Lurek2D")
    lurek.render.setBackgroundColor(COL_BG[1], COL_BG[2], COL_BG[3])

    lurek.input.bind("shoot", { "mouse1" })
    lurek.input.bind("quit",  { "escape" })

    camera = lurek.camera.new(SCREEN_W, SCREEN_H)

    -- Explosion particles (target hit)
    ps_explode = lurek.particle.newSystem({
        maxParticles = 150, emissionRate = 0,
        lifetimeMin = 0.15, lifetimeMax = 0.4,
        speedMin = 80, speedMax = 220, direction = 0, spread = 6.28,
        gravityY = 100,
        sizes = { 4, 2, 0 },
        colors = { 1, 0.7, 0.2, 1, 0.9, 0.3, 0.05, 0 },
    })

    -- Ball trail particles
    ps_trail = lurek.particle.newSystem({
        maxParticles = 200, emissionRate = 0,
        lifetimeMin = 0.05, lifetimeMax = 0.2,
        speedMin = 10, speedMax = 40, direction = 0, spread = 6.28,
        sizes = { 3, 1 },
        colors = { 1, 0.9, 0.4, 0.8, 1, 0.5, 0.1, 0 },
    })

    -- Power-up glow particles
    ps_powerup = lurek.particle.newSystem({
        maxParticles = 60, emissionRate = 0,
        lifetimeMin = 0.2, lifetimeMax = 0.5,
        speedMin = 30, speedMax = 80, direction = -1.57, spread = 1.2,
        sizes = { 3, 1 },
        colors = { 1, 1, 0.6, 1, 0.5, 1, 0.3, 0 },
    })
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
function lurek.process(dt)
    if lurek.input.wasActionPressed("quit") then lurek.event.quit() end

    -- Update particles
    ps_explode:update(dt)
    ps_trail:update(dt)
    ps_powerup:update(dt)
    lurek.tween.update(dt)

    -- Mouse position for crosshair
    crosshair_x, crosshair_y = lurek.input.mouse.getPosition()

    -- ── TITLE ─────────────────────────────────────────────────
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("shoot") then
            start_game()
        end
        return
    end

    -- ── ROUND END ─────────────────────────────────────────────
    if current_state == STATE.ROUND_END then
        round_timer = round_timer - dt
        if round_timer <= 0 then
            if current_round >= MAX_ROUNDS then
                current_state = STATE.GAME_OVER
            else
                start_round(current_round + 1)
                current_state = STATE.PLAYING
            end
        end
        return
    end

    -- ── GAME OVER ─────────────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("shoot") then
            current_state = STATE.TITLE
        end
        return
    end

    -- ── PLAYING ───────────────────────────────────────────────
    local sway_mult = slowmo_timer > 0 and 0.5 or 1.0
    if slowmo_timer > 0 then
        slowmo_timer = slowmo_timer - dt
        if slowmo_timer < 0 then slowmo_timer = 0 end
    end

    -- Fire
    if lurek.input.wasActionPressed("shoot") then
        fire(crosshair_x, crosshair_y)
    end

    -- Update targets (sway)
    local time = lurek.timer.getTime()
    for i = 1, #targets do
        local t = targets[i]
        if t.alive then
            t.x = t.base_x + math.sin(time * (t.speed / 30) + t.phase) * (40 * sway_mult)
        end
    end

    -- Update balls
    local new_balls = {}
    for i = 1, #balls do
        local b = balls[i]
        b.vy = b.vy + GRAVITY * dt
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.life = b.life - dt

        -- Trail particles
        ps_trail:emit(b.x, b.y, 2)

        -- Check collision with targets
        local hit = false
        for j = 1, #targets do
            local t = targets[j]
            if t.alive and aabb_circle(b.x, b.y, b.radius, t.x, t.y, t.w, t.h) then
                t.alive = false
                hit = true
                total_hits = total_hits + 1
                targets_destroyed = targets_destroyed + 1

                -- Combo
                combo = combo + 1
                if combo > best_combo then best_combo = combo end
                combo_mult = math.min(combo, MAX_COMBO_MULT)

                -- Score
                local gained = t.points * combo_mult
                score = score + gained
                add_score_popup(t.x + t.w / 2, t.y, gained, combo_mult)

                -- Combo text pulse
                combo_scale.s = 1.6
                lurek.tween.to(combo_scale, 0.3, { s = 1.0 }, "outElastic")

                -- Explosion particles
                local col = target_color(t.points)
                ps_explode:emit(t.x + t.w / 2, t.y + t.h / 2, 25)

                -- Power-up drop
                if targets_destroyed % 5 == 0 then
                    spawn_powerup(t.x + t.w / 2, t.y + t.h / 2)
                end

                break
            end
        end

        if hit then
            -- Ball consumed on hit
        elseif b.life > 0 and b.x > -50 and b.x < SCREEN_W + 50 and b.y < SCREEN_H + 50 then
            new_balls[#new_balls + 1] = b
        else
            -- Miss resets combo
            if not hit then
                combo = 0
                combo_mult = 1
            end
        end
    end
    balls = new_balls

    -- Update power-ups
    local new_pus = {}
    for i = 1, #powerups do
        local pu = powerups[i]
        pu.y = pu.y + pu.vy * dt
        pu.life = pu.life - dt
        pu.t = pu.t + dt

        -- Glow particles
        if math.floor(pu.t * 10) % 3 == 0 then
            ps_powerup:emit(pu.x, pu.y, 1)
        end

        -- Collect if ball touches power-up
        local collected = false
        for j = 1, #balls do
            local b = balls[j]
            if aabb_circle(b.x, b.y, b.radius, pu.x - 10, pu.y - 10, 20, 20) then
                collect_powerup(pu)
                collected = true
                break
            end
        end

        if not collected and pu.life > 0 and pu.y < SCREEN_H + 20 then
            new_pus[#new_pus + 1] = pu
        end
    end
    powerups = new_pus

    -- Update score popups
    local new_popups = {}
    for i = 1, #score_popups do
        local p = score_popups[i]
        p.life = p.life - dt
        if p.life > 0 then
            new_popups[#new_popups + 1] = p
        end
    end
    score_popups = new_popups

    -- Check round end: no balls left and no balls in flight
    if balls_remaining <= 0 and #balls == 0 then
        round_timer = ROUND_DELAY
        current_state = STATE.ROUND_END
    end

    -- Also end round if all targets destroyed
    local any_alive = false
    for i = 1, #targets do
        if targets[i].alive then any_alive = true; break end
    end
    if not any_alive then
        round_timer = ROUND_DELAY
        current_state = STATE.ROUND_END
    end
end

-- ---------------------------------------------------------------------------
-- Render (world space)
-- ---------------------------------------------------------------------------
function lurek.draw()
    camera:attach()

    -- Floor
    lurek.render.setColor(COL_FLOOR[1], COL_FLOOR[2], COL_FLOOR[3], 1)
    lurek.render.rectangle("fill", 0, SCREEN_H - 20, SCREEN_W, 20)

    -- Launcher base
    lurek.render.setColor(0.4, 0.3, 0.2, 1)
    lurek.render.rectangle("fill", SCREEN_W / 2 - 15, SCREEN_H - 35, 30, 15)
    lurek.render.setColor(0.5, 0.4, 0.25, 1)
    lurek.render.circle("fill", SCREEN_W / 2, SCREEN_H - 35, 10)

    -- Targets
    for i = 1, #targets do
        local t = targets[i]
        if t.alive then
            local col = target_color(t.points)
            lurek.render.setColor(col[1], col[2], col[3], 1)
            lurek.render.rectangle("fill", t.x, t.y, t.w, t.h)
            -- Highlight edge
            lurek.render.setColor(col[1] + 0.2, col[2] + 0.2, col[3] + 0.2, 0.6)
            lurek.render.rectangle("line", t.x, t.y, t.w, t.h)
        end
    end

    -- Power-ups
    for i = 1, #powerups do
        local pu = powerups[i]
        local col = POWERUP_COLORS[pu.kind]
        local pulse = 0.7 + 0.3 * math.sin(pu.t * 6)
        lurek.render.setColor(col[1], col[2], col[3], pulse)
        lurek.render.rectangle("fill", pu.x - 8, pu.y - 8, 16, 16)
        lurek.render.setColor(1, 1, 1, pulse * 0.5)
        lurek.render.rectangle("fill", pu.x - 4, pu.y - 4, 8, 8)
    end

    -- Balls
    for i = 1, #balls do
        local b = balls[i]
        local col = b.radius > BALL_RADIUS and COL_BALL_BIG or COL_BALL
        lurek.render.setColor(col[1], col[2], col[3], 1)
        lurek.render.circle("fill", b.x, b.y, b.radius)
        -- Bright core
        lurek.render.setColor(1, 1, 0.9, 0.7)
        lurek.render.circle("fill", b.x, b.y, b.radius * 0.4)
    end

    -- Score popups
    for i = 1, #score_popups do
        local p = score_popups[i]
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(COL_COMBO[1], COL_COMBO[2], COL_COMBO[3], a)
        lurek.render.print(p.text, p.x - 15, p.y, 16)
    end

    -- Particles
    lurek.render.setColor(1, 1, 1, 1)
    ps_explode:draw()
    ps_trail:draw()
    ps_powerup:draw()

    -- Crosshair
    lurek.render.setColor(COL_CROSSHAIR[1], COL_CROSSHAIR[2], COL_CROSSHAIR[3], 0.9)
    lurek.render.circle("line", crosshair_x, crosshair_y, 12)
    lurek.render.line(crosshair_x - 16, crosshair_y, crosshair_x - 6, crosshair_y)
    lurek.render.line(crosshair_x + 6, crosshair_y, crosshair_x + 16, crosshair_y)
    lurek.render.line(crosshair_x, crosshair_y - 16, crosshair_x, crosshair_y - 6)
    lurek.render.line(crosshair_x, crosshair_y + 6, crosshair_x, crosshair_y + 16)

    -- Aim line
    lurek.render.setColor(1, 1, 1, 0.15)
    lurek.render.line(SCREEN_W / 2, SCREEN_H - 35, crosshair_x, crosshair_y)

    camera:detach()
end

-- ---------------------------------------------------------------------------
-- Render UI (screen space)
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    -- ── TITLE SCREEN ──────────────────────────────────────────
    if current_state == STATE.TITLE then
        lurek.render.setColor(COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        lurek.render.print("SHOOTING GALLERY", SCREEN_W / 2 - 130, SCREEN_H / 2 - 60, 32)

        lurek.render.setColor(COL_SUBTITLE[1], COL_SUBTITLE[2], COL_SUBTITLE[3], 1)
        lurek.render.print("AIM AND FIRE", SCREEN_W / 2 - 75, SCREEN_H / 2, 20)

        local blink = 0.5 + 0.5 * math.sin(lurek.timer.getTime() * 4)
        lurek.render.setColor(1, 1, 1, blink)
        lurek.render.print("Click to Start", SCREEN_W / 2 - 65, SCREEN_H / 2 + 60, 16)
        return
    end

    -- ── GAME OVER SCREEN ──────────────────────────────────────
    if current_state == STATE.GAME_OVER then
        lurek.render.setColor(COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 80, 120, 32)

        lurek.render.setColor(COL_TEXT[1], COL_TEXT[2], COL_TEXT[3], 1)
        lurek.render.print("Final Score: " .. tostring(score), SCREEN_W / 2 - 80, 200, 20)

        local accuracy = 0
        if total_shots > 0 then accuracy = math.floor(total_hits / total_shots * 100) end
        lurek.render.print("Accuracy: " .. tostring(accuracy) .. "%", SCREEN_W / 2 - 80, 240, 20)
        lurek.render.print("Best Combo: " .. tostring(best_combo) .. "x", SCREEN_W / 2 - 80, 280, 20)

        local blink = 0.5 + 0.5 * math.sin(lurek.timer.getTime() * 4)
        lurek.render.setColor(1, 1, 1, blink)
        lurek.render.print("Click to Continue", SCREEN_W / 2 - 80, 360, 16)
        return
    end

    -- ── ROUND END ─────────────────────────────────────────────
    if current_state == STATE.ROUND_END then
        lurek.render.setColor(COL_TITLE[1], COL_TITLE[2], COL_TITLE[3], 1)
        if current_round >= MAX_ROUNDS then
            lurek.render.print("ALL ROUNDS COMPLETE!", SCREEN_W / 2 - 130, SCREEN_H / 2 - 20, 28)
        else
            lurek.render.print("ROUND " .. tostring(current_round) .. " COMPLETE", SCREEN_W / 2 - 120, SCREEN_H / 2 - 20, 28)
        end
        return
    end

    -- ── PLAYING HUD ───────────────────────────────────────────
    -- Score
    lurek.render.setColor(COL_HUD[1], COL_HUD[2], COL_HUD[3], 1)
    lurek.render.print("Score: " .. tostring(score), 16, 12, 20)

    -- Round
    lurek.render.print("Round: " .. tostring(current_round) .. "/" .. tostring(MAX_ROUNDS), 16, 38, 16)

    -- Balls remaining
    lurek.render.print("Balls: " .. tostring(balls_remaining), 16, 58, 16)

    -- Combo
    if combo > 1 then
        local cs = combo_scale.s
        lurek.render.setColor(COL_COMBO[1], COL_COMBO[2], COL_COMBO[3], 1)
        local combo_text = "COMBO " .. tostring(combo) .. "x"
        lurek.render.print(combo_text, SCREEN_W / 2 - 40, 12, math.floor(20 * cs))
    end

    -- Active power-ups
    local pu_y = 12
    if triple_shots > 0 then
        lurek.render.setColor(POWERUP_COLORS[POWERUP.TRIPLE][1], POWERUP_COLORS[POWERUP.TRIPLE][2], POWERUP_COLORS[POWERUP.TRIPLE][3], 1)
        lurek.render.print("TRIPLE x" .. tostring(triple_shots), SCREEN_W - 130, pu_y, 14)
        pu_y = pu_y + 18
    end
    if big_ball_shots > 0 then
        lurek.render.setColor(POWERUP_COLORS[POWERUP.BIG][1], POWERUP_COLORS[POWERUP.BIG][2], POWERUP_COLORS[POWERUP.BIG][3], 1)
        lurek.render.print("BIG BALL x" .. tostring(big_ball_shots), SCREEN_W - 130, pu_y, 14)
        pu_y = pu_y + 18
    end
    if slowmo_timer > 0 then
        lurek.render.setColor(POWERUP_COLORS[POWERUP.SLOWMO][1], POWERUP_COLORS[POWERUP.SLOWMO][2], POWERUP_COLORS[POWERUP.SLOWMO][3], 1)
        lurek.render.print("SLOW-MO " .. string.format("%.1f", slowmo_timer) .. "s", SCREEN_W - 130, pu_y, 14)
    end

    -- FPS
    lurek.render.setColor(0.6, 0.6, 0.6, 0.7)
    lurek.render.print("FPS: " .. tostring(lurek.timer.getFPS()), SCREEN_W - 80, SCREEN_H - 22, 12)
end
