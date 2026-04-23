-- ============================================================================
-- Tennis Classic — Lurek2D
-- ============================================================================
-- Category : sports
-- Source   : content/games/sports/tennis_classic/main.lua
-- Run with : cargo run -- content/games/sports/tennis_classic
-- ============================================================================
-- Complete top-down tennis with serve/return, topspin/slice, AI opponent,
-- and full tennis scoring (games → sets → match best-of-3).
-- Controls: WASD move, Space serve/hit, A/D aim, W/S spin, Escape quit
-- ============================================================================

-- ── Constants ─────────────────────────────────────────────────────
local W, H = 800, 600

-- Court dimensions (centered on screen)
local COURT_L = 100
local COURT_R = 700
local COURT_T = 60
local COURT_B = 540
local COURT_W = COURT_R - COURT_L
local COURT_H = COURT_B - COURT_T
local NET_Y = (COURT_T + COURT_B) / 2
local SERVICE_LINE_T = COURT_T + COURT_H * 0.25
local SERVICE_LINE_B = COURT_B - COURT_H * 0.25
local CENTER_X = (COURT_L + COURT_R) / 2

-- Player / ball
local PLAYER_W, PLAYER_H = 20, 20
local BALL_R = 6
local HIT_RANGE = 30
local SERVE_TOSS_H = 40
local MIN_SPEED = 300
local MAX_SPEED = 600
local CHARGE_RATE = 400

-- AI
local BASE_AI_DELAY = 0.7
local AI_SPEED_BASE = 200

-- ── States ────────────────────────────────────────────────────────
local ST = {
    TITLE     = "TITLE",
    SERVING   = "SERVING",
    PLAYING   = "PLAYING",
    POINT     = "POINT",
    SET_END   = "SET_END",
    MATCH_END = "MATCH_END",
}

-- ── Scoring helpers ───────────────────────────────────────────────
local SCORE_NAMES = { [0] = "0", [1] = "15", [2] = "30", [3] = "40" }

local function score_display(pts)
    return SCORE_NAMES[pts] or tostring(pts)
end

-- ── Game state ────────────────────────────────────────────────────
local state = ST.TITLE
local camera = nil
local title_timer = 0
local point_timer = 0
local point_msg = ""

-- Players
local player = { x = CENTER_X, y = COURT_B - 40, w = PLAYER_W, h = PLAYER_H }
local opponent = { x = CENTER_X, y = COURT_T + 40, w = PLAYER_W, h = PLAYER_H }
local ai_target_x = CENTER_X
local ai_react_timer = 0

-- Ball
local ball = { x = 0, y = 0, vx = 0, vy = 0, active = false, bounced = false, shadow_y = 0 }
local ball_height = 0   -- simulated Z for serve toss
local serve_phase = 0   -- 0=none, 1=tossed, 2=hit

-- Charging
local charging = false
local charge_power = 0

-- Direction modifiers while hitting
local aim_dir = 0    -- -1 left, 0 center, 1 right
local spin_type = 0  -- -1 slice, 0 flat, 1 topspin

-- Scoring
local server = 1  -- 1=player, 2=opponent
local serve_count = 0  -- 0=first serve, 1=second serve
local pts = { 0, 0 }
local games = { { 0, 0 }, { 0, 0 }, { 0, 0 } }
local current_set = 1
local sets_won = { 0, 0 }
local deuce = false
local advantage = 0  -- 0=none, 1=player, 2=opponent
local rally_count = 0
local last_hitter = 0

-- Particles
local dust_particles = nil
local ace_particles = nil
local net_particles = nil

-- Tweens
local score_popup = { text = "", alpha = 0, y = 0 }
local ball_trail = {}

-- ── Utility ───────────────────────────────────────────────────────
local function dist(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function lerp(a, b, t) return a + (b - a) * t end

-- ── Scoring logic ─────────────────────────────────────────────────
local function award_point(winner)
    local loser = (winner == 1) and 2 or 1
    rally_count = 0

    -- Deuce logic
    if pts[1] >= 3 and pts[2] >= 3 then
        if advantage == winner then
            -- wins game
        elseif advantage == loser then
            advantage = 0
            deuce = true
            point_msg = "Deuce"
            point_timer = 1.5
            state = ST.POINT
            return
        elseif deuce then
            advantage = winner
            point_msg = (winner == 1) and "Advantage Player" or "Advantage Opponent"
            point_timer = 1.5
            state = ST.POINT
            return
        end
    end

    if not deuce and pts[winner] < 3 then
        pts[winner] = pts[winner] + 1
        point_msg = (winner == 1) and "Point: Player" or "Point: Opponent"
        point_timer = 1.2
        state = ST.POINT

        -- Check deuce
        if pts[1] == 3 and pts[2] == 3 then
            deuce = true
        end
        return
    end

    -- Win game
    local g = games[current_set]
    g[winner] = g[winner] + 1
    pts = { 0, 0 }
    deuce = false
    advantage = 0
    serve_count = 0
    server = (server == 1) and 2 or 1

    point_msg = (winner == 1) and "Game: Player" or "Game: Opponent"

    -- Check set
    local tiebreak = (g[1] == 6 and g[2] == 6)
    local set_won = false
    if g[winner] >= 6 and g[winner] - g[loser] >= 2 then
        set_won = true
    elseif tiebreak and g[winner] == 7 then
        set_won = true
    end

    if set_won then
        sets_won[winner] = sets_won[winner] + 1
        point_msg = (winner == 1) and "Set: Player" or "Set: Opponent"

        -- Check match
        if sets_won[winner] >= 2 then
            point_msg = (winner == 1) and "Match: Player Wins!" or "Match: Opponent Wins!"
            point_timer = 3.0
            state = ST.MATCH_END

            if ace_particles then
                lurek.particle.emit(ace_particles, CENTER_X, NET_Y, 40)
            end
            return
        end

        current_set = current_set + 1
        point_timer = 2.5
        state = ST.SET_END
        return
    end

    point_timer = 1.5
    state = ST.POINT
end

local function start_serve()
    state = ST.SERVING
    serve_phase = 0
    ball.active = false
    ball_height = 0
    charge_power = 0
    charging = false
    rally_count = 0
    aim_dir = 0
    spin_type = 0
    ball_trail = {}

    if server == 1 then
        player.x = CENTER_X
        player.y = COURT_B - 40
        ball.x = player.x
        ball.y = player.y - 15
    else
        opponent.x = CENTER_X
        opponent.y = COURT_T + 40
        ball.x = opponent.x
        ball.y = opponent.y + 15
    end
end

local function reset_for_point()
    start_serve()
end

-- ── Ball out/bounce checks ────────────────────────────────────────
local function is_in_court(bx, by)
    return bx >= COURT_L and bx <= COURT_R and by >= COURT_T and by <= COURT_B
end

local function is_in_service_box(bx, by, serving_from_bottom)
    if serving_from_bottom then
        -- Must land in top service area
        local left = (serve_count == 0) and CENTER_X or COURT_L
        local right = (serve_count == 0) and COURT_R or CENTER_X
        return bx >= left and bx <= right and by >= COURT_T and by <= SERVICE_LINE_T
    else
        local left = (serve_count == 0) and COURT_L or CENTER_X
        local right = (serve_count == 0) and CENTER_X or COURT_R
        return bx >= left and bx <= right and by >= SERVICE_LINE_B and by <= COURT_B
    end
end

-- ── Input bindings ────────────────────────────────────────────────

function lurek.init()
    lurek.render.setBackgroundColor(0.2, 0.4, 0.2)
    lurek.window.setTitle("Tennis Classic — Lurek2D")

    camera = lurek.camera.new()
    camera:apply()

    lurek.input.bind("move_up", "w")
    lurek.input.bind("move_down", "s")
    lurek.input.bind("move_left", "a")
    lurek.input.bind("move_right", "d")
    lurek.input.bind("hit", "space")
    lurek.input.bind("quit", "escape")

    -- Particles
    dust_particles = lurek.particle.newSystem(50)
    lurek.particle.setLifetime(dust_particles, 0.2, 0.5)
    lurek.particle.setSpeed(dust_particles, 20, 80)
    lurek.particle.setColors(dust_particles, 0.8, 0.7, 0.5, 1.0, 0.8, 0.7, 0.5, 0.0)
    lurek.particle.setSizes(dust_particles, 3, 1)

    ace_particles = lurek.particle.newSystem(80)
    lurek.particle.setLifetime(ace_particles, 0.3, 0.8)
    lurek.particle.setSpeed(ace_particles, 50, 200)
    lurek.particle.setColors(ace_particles, 1.0, 1.0, 0.0, 1.0, 1.0, 0.5, 0.0, 0.0)
    lurek.particle.setSizes(ace_particles, 5, 1)
    lurek.particle.setSpread(ace_particles, math.pi * 2)

    net_particles = lurek.particle.newSystem(30)
    lurek.particle.setLifetime(net_particles, 0.1, 0.3)
    lurek.particle.setSpeed(net_particles, 10, 40)
    lurek.particle.setColors(net_particles, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0)
    lurek.particle.setSizes(net_particles, 2, 1)
end

-- ── Process ───────────────────────────────────────────────────────
function lurek.process(dt)
    if lurek.input.pressed("quit") then
        lurek.event.quit()
        return
    end

    title_timer = title_timer + dt

    -- Update particles
    lurek.particle.update(dust_particles, dt)
    lurek.particle.update(ace_particles, dt)
    lurek.particle.update(net_particles, dt)

    -- Score popup fade
    if score_popup.alpha > 0 then
        score_popup.alpha = score_popup.alpha - dt * 1.5
        score_popup.y = score_popup.y - dt * 30
    end

    -- ── TITLE ─────────────────────────────────────────────────────
    if state == ST.TITLE then
        if lurek.input.pressed("hit") then
            pts = { 0, 0 }
            games = { { 0, 0 }, { 0, 0 }, { 0, 0 } }
            sets_won = { 0, 0 }
            current_set = 1
            server = 1
            serve_count = 0
            deuce = false
            advantage = 0
            start_serve()
        end
        return
    end

    -- ── POINT / SET_END / MATCH_END timers ────────────────────────
    if state == ST.POINT or state == ST.SET_END then
        point_timer = point_timer - dt
        if point_timer <= 0 then
            reset_for_point()
        end
        return
    end

    if state == ST.MATCH_END then
        point_timer = point_timer - dt
        if point_timer <= 0 then
            state = ST.TITLE
        end
        return
    end

    -- ── Player movement ───────────────────────────────────────────
    local spd = 250 * dt
    if lurek.input.down("move_up") then
        player.y = clamp(player.y - spd, NET_Y + 10, COURT_B - 10)
    end
    if lurek.input.down("move_down") then
        player.y = clamp(player.y + spd, NET_Y + 10, COURT_B - 10)
    end
    if lurek.input.down("move_left") then
        player.x = clamp(player.x - spd, COURT_L + 10, COURT_R - 10)
        aim_dir = -1
    end
    if lurek.input.down("move_right") then
        player.x = clamp(player.x + spd, COURT_L + 10, COURT_R - 10)
        aim_dir = 1
    end
    -- Spin modifier
    if lurek.input.down("move_up") then spin_type = 1 end   -- topspin
    if lurek.input.down("move_down") then spin_type = -1 end -- slice

    -- ── SERVING ───────────────────────────────────────────────────
    if state == ST.SERVING then
        if server == 1 then
            -- Player serves
            if serve_phase == 0 and lurek.input.pressed("hit") then
                serve_phase = 1
                ball_height = 0
                ball.x = player.x
                ball.y = player.y - 15
            elseif serve_phase == 1 then
                ball_height = ball_height + dt * 80
                ball.y = player.y - 15 - math.sin(ball_height / SERVE_TOSS_H * math.pi) * SERVE_TOSS_H

                if lurek.input.pressed("hit") then
                    serve_phase = 2
                    ball.active = true
                    ball_height = 0
                    local speed = lerp(MIN_SPEED, MAX_SPEED, 0.6)
                    local angle_offset = aim_dir * 0.3
                    ball.vx = math.sin(angle_offset) * speed
                    ball.vy = -speed
                    ball.bounced = false
                    last_hitter = 1
                    state = ST.PLAYING
                    lurek.particle.emit(dust_particles, ball.x, ball.y, 8)
                end

                if ball_height > math.pi then
                    serve_phase = 0
                end
            end
        else
            -- AI serves automatically
            ai_react_timer = ai_react_timer + dt
            if ai_react_timer > 0.8 then
                ai_react_timer = 0
                serve_phase = 2
                ball.x = opponent.x
                ball.y = opponent.y + 15
                ball.active = true
                local speed = lerp(MIN_SPEED, MAX_SPEED, 0.5)
                local aim = (math.random() - 0.5) * 0.4
                ball.vx = math.sin(aim) * speed
                ball.vy = speed
                ball.bounced = false
                last_hitter = 2
                state = ST.PLAYING
                lurek.particle.emit(dust_particles, ball.x, ball.y, 8)
            end
        end
        return
    end

    -- ── PLAYING ───────────────────────────────────────────────────
    if state == ST.PLAYING and ball.active then
        -- Move ball
        -- Apply spin effects
        local gravity = 0
        if spin_type == 1 and last_hitter == 1 then gravity = 80 end   -- topspin: dips
        if spin_type == -1 and last_hitter == 1 then gravity = -20 end -- slice: floats

        ball.x = ball.x + ball.vx * dt
        ball.y = ball.y + (ball.vy + gravity) * dt

        -- Ball trail
        table.insert(ball_trail, { x = ball.x, y = ball.y, t = 0.3 })
        if #ball_trail > 20 then table.remove(ball_trail, 1) end
        for i = #ball_trail, 1, -1 do
            ball_trail[i].t = ball_trail[i].t - dt
            if ball_trail[i].t <= 0 then table.remove(ball_trail, i) end
        end

        -- Net check (simplified: ball crossing net y)
        local prev_y = ball.y - ball.vy * dt
        if (prev_y < NET_Y and ball.y >= NET_Y) or (prev_y > NET_Y and ball.y <= NET_Y) then
            -- Check if ball speed is too low (net fault simulation)
            local spd_total = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
            if spd_total < 100 then
                -- Net fault
                lurek.particle.emit(net_particles, ball.x, NET_Y, 15)
                ball.active = false
                award_point((last_hitter == 1) and 2 or 1)
                return
            end
        end

        -- Side walls (bounce off court edges)
        if ball.x < COURT_L then
            ball.x = COURT_L
            ball.vx = -ball.vx * 0.5
        elseif ball.x > COURT_R then
            ball.x = COURT_R
            ball.vx = -ball.vx * 0.5
        end

        -- Ball crosses top/bottom baselines
        if ball.y < COURT_T - 20 or ball.y > COURT_B + 20 then
            -- Out of bounds
            ball.active = false
            if serve_phase == 2 and not ball.bounced then
                -- Serve out
                serve_count = serve_count + 1
                if serve_count >= 2 then
                    -- Double fault
                    serve_count = 0
                    point_msg = "Double Fault!"
                    score_popup = { text = "DOUBLE FAULT", alpha = 1.0, y = H / 2 }
                    award_point((server == 1) and 2 or 1)
                else
                    point_msg = "Fault"
                    score_popup = { text = "FAULT", alpha = 1.0, y = H / 2 }
                    point_timer = 1.0
                    state = ST.POINT
                end
            else
                award_point(last_hitter)
            end
            return
        end

        -- Bounce detection (ball in opponent/player half)
        if ball.vy < 0 and ball.y < NET_Y and not ball.bounced then
            -- Ball in opponent half, first bounce
            if ball.y <= COURT_T + 5 then
                ball.bounced = true
                lurek.particle.emit(dust_particles, ball.x, ball.y, 5)

                -- Service box check for serves
                if serve_phase == 2 and last_hitter == 1 then
                    if not is_in_service_box(ball.x, ball.y, true) then
                        serve_count = serve_count + 1
                        ball.active = false
                        if serve_count >= 2 then
                            serve_count = 0
                            award_point(2)
                        else
                            point_msg = "Fault"
                            score_popup = { text = "FAULT", alpha = 1.0, y = H / 2 }
                            point_timer = 1.0
                            state = ST.POINT
                        end
                        return
                    end
                end
            end
        end

        if ball.vy > 0 and ball.y > NET_Y and not ball.bounced then
            if ball.y >= COURT_B - 5 then
                ball.bounced = true
                lurek.particle.emit(dust_particles, ball.x, ball.y, 5)

                if serve_phase == 2 and last_hitter == 2 then
                    if not is_in_service_box(ball.x, ball.y, false) then
                        serve_count = serve_count + 1
                        ball.active = false
                        if serve_count >= 2 then
                            serve_count = 0
                            award_point(1)
                        else
                            point_msg = "Fault"
                            point_timer = 1.0
                            state = ST.POINT
                        end
                        return
                    end
                end
            end
        end

        -- Second bounce = point for other player
        if ball.bounced then
            if ball.vy < 0 and ball.y < COURT_T + 10 then
                ball.active = false
                award_point(1)
                return
            end
            if ball.vy > 0 and ball.y > COURT_B - 10 then
                ball.active = false
                award_point(2)
                return
            end
        end

        -- ── Player hit ────────────────────────────────────────────
        if last_hitter == 2 and ball.vy > 0 then
            local d = dist(player.x, player.y, ball.x, ball.y)
            if d < HIT_RANGE then
                if lurek.input.pressed("hit") then
                    charging = true
                    charge_power = 0
                end
                if lurek.input.released("hit") and charging then
                    charging = false
                    local pwr = clamp(charge_power, 0, 1)
                    local speed = lerp(MIN_SPEED, MAX_SPEED, pwr)
                    local angle_off = aim_dir * 0.35
                    ball.vx = math.sin(angle_off) * speed * 0.6
                    ball.vy = -speed
                    ball.bounced = false
                    last_hitter = 1
                    serve_phase = 0
                    rally_count = rally_count + 1
                    aim_dir = 0
                    spin_type = 0
                    lurek.particle.emit(dust_particles, ball.x, ball.y, 6)

                    if rally_count >= 10 then
                        score_popup = { text = "Rally: " .. rally_count, alpha = 1.0, y = H / 2 - 40 }
                    end
                end
            end
        end

        if charging then
            charge_power = charge_power + dt * (CHARGE_RATE / MAX_SPEED)
            charge_power = clamp(charge_power, 0, 1)
        end

        -- ── AI opponent ───────────────────────────────────────────
        local set_bonus = (current_set - 1) * 0.15
        local ai_delay = math.max(0.2, BASE_AI_DELAY - set_bonus)
        local ai_speed = AI_SPEED_BASE + current_set * 40

        if ball.vy < 0 and last_hitter == 1 then
            ai_react_timer = ai_react_timer + dt
            if ai_react_timer >= ai_delay then
                -- Move toward ball
                local dx = ball.x - opponent.x
                if math.abs(dx) > 5 then
                    opponent.x = opponent.x + (dx > 0 and 1 or -1) * ai_speed * dt
                end
                opponent.x = clamp(opponent.x, COURT_L + 10, COURT_R - 10)

                -- AI hit
                local d = dist(opponent.x, opponent.y, ball.x, ball.y)
                if d < HIT_RANGE + 10 then
                    local speed = lerp(MIN_SPEED, MAX_SPEED, 0.4 + set_bonus)
                    local aim_choices = { -0.3, 0, 0.3 }
                    local pick = aim_choices[math.random(#aim_choices)]
                    ball.vx = math.sin(pick) * speed * 0.5
                    ball.vy = speed
                    ball.bounced = false
                    last_hitter = 2
                    serve_phase = 0
                    rally_count = rally_count + 1
                    ai_react_timer = 0
                    lurek.particle.emit(dust_particles, ball.x, ball.y, 6)
                end
            end
        else
            -- Return to center slowly
            local cx = CENTER_X
            local dx = cx - opponent.x
            if math.abs(dx) > 5 then
                opponent.x = opponent.x + (dx > 0 and 1 or -1) * ai_speed * 0.3 * dt
            end
            ai_react_timer = 0
        end
    end
end

-- ── Render (world-space: court, players, ball) ────────────────────
function lurek.draw()
    -- Court background (green)
    lurek.render.rectangle(COURT_L, COURT_T, COURT_W, COURT_H, 0.18, 0.55, 0.18, 1.0)

    -- Court lines (white)
    local lw = 2
    -- Outer boundary
    lurek.render.rectangle(COURT_L, COURT_T, COURT_W, COURT_H, 1, 1, 1, 1)
    -- Center service line (vertical)
    lurek.render.line(CENTER_X, SERVICE_LINE_T, CENTER_X, SERVICE_LINE_B, 1, 1, 1, 1)
    -- Service lines (horizontal)
    lurek.render.line(COURT_L, SERVICE_LINE_T, COURT_R, SERVICE_LINE_T, 1, 1, 1, 1)
    lurek.render.line(COURT_L, SERVICE_LINE_B, COURT_R, SERVICE_LINE_B, 1, 1, 1, 1)
    -- Net
    lurek.render.line(COURT_L - 10, NET_Y, COURT_R + 10, NET_Y, 1, 1, 1, 0.8)
    -- Net posts
    lurek.render.rectangle(COURT_L - 12, NET_Y - 3, 6, 6, 0.6, 0.6, 0.6, 1)
    lurek.render.rectangle(COURT_R + 6, NET_Y - 3, 6, 6, 0.6, 0.6, 0.6, 1)
    -- Center marks
    lurek.render.line(CENTER_X, COURT_B - 15, CENTER_X, COURT_B, 1, 1, 1, 1)
    lurek.render.line(CENTER_X, COURT_T, CENTER_X, COURT_T + 15, 1, 1, 1, 1)

    if state == ST.TITLE then
        return
    end

    -- Ball trail
    for _, t in ipairs(ball_trail) do
        local a = t.t / 0.3
        lurek.render.circleFill(t.x, t.y, BALL_R * 0.6, 1, 1, 0.7, a * 0.3)
    end

    -- Player (blue)
    lurek.render.rectangle(
        player.x - PLAYER_W / 2, player.y - PLAYER_H / 2,
        PLAYER_W, PLAYER_H, 0.2, 0.4, 1.0, 1.0
    )

    -- Opponent (red)
    lurek.render.rectangle(
        opponent.x - PLAYER_W / 2, opponent.y - PLAYER_H / 2,
        PLAYER_W, PLAYER_H, 1.0, 0.3, 0.3, 1.0
    )

    -- Ball
    if ball.active or state == ST.SERVING then
        local br = BALL_R
        -- Shadow
        lurek.render.circleFill(ball.x + 2, ball.y + 2, br, 0, 0, 0, 0.3)
        -- Ball
        lurek.render.circleFill(ball.x, ball.y, br, 1.0, 1.0, 1.0, 1.0)
    end

    -- Charge indicator
    if charging then
        local bar_w = 30 * charge_power
        lurek.render.rectangle(player.x - 15, player.y + PLAYER_H / 2 + 4, bar_w, 4,
            1.0, 1.0 - charge_power, 0, 1)
    end

    -- Particles
    lurek.particle.draw(dust_particles)
    lurek.particle.draw(ace_particles)
    lurek.particle.draw(net_particles)
end

-- ── Render UI (screen-space: score, messages) ─────────────────────
function lurek.draw_ui()
    local fps = lurek.timer.getFPS()

    if state == ST.TITLE then
        -- Title screen
        local blink = math.abs(math.sin(title_timer * 2))
        lurek.render.print("TENNIS CLASSIC", W / 2 - 120, H / 2 - 60, 32, 1, 1, 1, 1)
        lurek.render.print("GAME  SET  MATCH", W / 2 - 100, H / 2 - 20, 18, 0.8, 0.8, 0.8, 1)
        lurek.render.print("Press SPACE to start", W / 2 - 80, H / 2 + 40, 16, 1, 1, 1, blink)
        lurek.render.print("FPS: " .. fps, 10, H - 20, 12, 0.5, 0.5, 0.5, 1)
        return
    end

    -- Scoreboard background
    lurek.render.rectangle(0, 0, W, 28, 0, 0, 0, 0.6)

    -- Score display
    local score_str
    if deuce then
        if advantage == 0 then
            score_str = "Deuce"
        elseif advantage == 1 then
            score_str = "Ad-Player"
        else
            score_str = "Ad-Opponent"
        end
    else
        score_str = score_display(pts[1]) .. " - " .. score_display(pts[2])
    end

    -- Sets
    local sets_str = ""
    for i = 1, current_set do
        local g = games[i]
        if g then
            if i > 1 then sets_str = sets_str .. "  " end
            sets_str = sets_str .. "S" .. i .. ": " .. g[1] .. "-" .. g[2]
        end
    end

    local server_str = (server == 1) and " [P serve]" or " [O serve]"

    lurek.render.print("Score: " .. score_str .. server_str, 10, 6, 14, 1, 1, 1, 1)
    lurek.render.print(sets_str, W / 2 - 60, 6, 14, 0.9, 0.9, 0.5, 1)

    -- Rally counter
    if rally_count > 0 and state == ST.PLAYING then
        lurek.render.print("Rally: " .. rally_count, W - 100, 6, 14, 0.5, 1.0, 0.5, 1)
    end

    -- Point / set / match messages
    if state == ST.POINT or state == ST.SET_END or state == ST.MATCH_END then
        lurek.render.print(point_msg, W / 2 - 80, H / 2, 24, 1, 1, 0.3, 1)
    end

    -- Score popup (tween-like fade)
    if score_popup.alpha > 0 then
        lurek.render.print(score_popup.text, W / 2 - 60, score_popup.y, 20,
            1, 1, 0.2, score_popup.alpha)
    end

    -- Serve instruction
    if state == ST.SERVING and server == 1 then
        local msg = (serve_phase == 0) and "Press SPACE to toss" or "Press SPACE to hit!"
        if serve_count == 1 then msg = "Second serve — " .. msg end
        lurek.render.print(msg, W / 2 - 90, H - 30, 14, 1, 1, 1, 0.8)
    end

    -- FPS
    lurek.render.print("FPS: " .. fps, W - 70, H - 20, 12, 0.5, 0.5, 0.5, 1)
end
