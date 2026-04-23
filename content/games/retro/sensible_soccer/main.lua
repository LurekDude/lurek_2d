-- ============================================================================
-- Sensible Soccer — Lurek2D
-- Category: retro
-- Fast-paced top-down football inspired by Sensible Software's 1992 Amiga
-- classic. Two teams of 5, 3-minute matches, CPU AI, tackling, half-time.
-- ============================================================================
-- Controls:
--   WASD        — Move controlled player
--   Space       — Kick ball (power shot)
--   F           — Pass to nearest teammate
--   T           — Slide tackle
--   Escape      — Quit
-- ============================================================================


local STATE = { TITLE = 1, PLAYING = 2, HALFTIME = 3, FULL_TIME = 4 }
local state = STATE.TITLE

-- ── constants ─────────────────────────────────────────────────
local SCR_W, SCR_H = 800, 600
local PITCH_W, PITCH_H = 680, 500
local PITCH_X = (SCR_W - PITCH_W) / 2
local PITCH_Y = (SCR_H - PITCH_H) / 2
local GOAL_W = 90
local GOAL_DEPTH = 10
local GOAL_TOP_X = PITCH_X + (PITCH_W - GOAL_W) / 2
local GOAL_TOP_Y = PITCH_Y - GOAL_DEPTH
local GOAL_BOT_X = GOAL_TOP_X
local GOAL_BOT_Y = PITCH_Y + PITCH_H
local CENTER_X = PITCH_X + PITCH_W / 2
local CENTER_Y = PITCH_Y + PITCH_H / 2
local PLAYER_RADIUS = 6
local BALL_RADIUS = 4
local KICK_POWER = 400
local PASS_POWER = 260
local PLAYER_SPEED = 160
local CPU_SPEED = 140
local BALL_FRICTION = 0.88
local TACKLE_RANGE = 26
local TACKLE_LUNGE = 280
local MATCH_TIME = 180
local HALF_TIME = 90

-- ── state ─────────────────────────────────────────────────────
local players_green = {}
local players_red = {}
local ball = { x = CENTER_X, y = CENTER_Y, vx = 0, vy = 0 }
local controlled_idx = 1
local score_green = 0
local score_red = 0
local match_timer = 0
local half_swapped = false
local kickoff_team = "green"  -- who starts with ball
local input_dx, input_dy = 0, 0
local facing_x, facing_y = 0, -1
local tackle_timer = 0
local title_blink = 0
local goal_flash = 0
local goal_text_scale = 0
local halftime_alpha = 0

-- particles
local particles = {}

-- tweens
local tweens = {}

-- ── formation positions (relative to center) ─────────────────
local green_formation = {
    { dx =   0, dy = 100 },  -- goalkeeper
    { dx = -80, dy =  20 },  -- left back
    { dx =  80, dy =  20 },  -- right back
    { dx = -40, dy = -60 },  -- left mid
    { dx =  40, dy = -60 },  -- right mid
}
local red_formation = {
    { dx =   0, dy = -100 },
    { dx = -80, dy = - 20 },
    { dx =  80, dy = - 20 },
    { dx = -40, dy =  60 },
    { dx =  40, dy =  60 },
}

-- ── helpers ───────────────────────────────────────────────────
local function dist(x1, y1, x2, y2)
    local dx, dy = x2 - x1, y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local function normalize(x, y)
    local len = math.sqrt(x * x + y * y)
    if len < 0.001 then return 0, 0 end
    return x / len, y / len
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function spawn_particles(x, y, count, r, g, b, speed, life)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = (math.random() * 0.5 + 0.5) * speed
        particles[#particles + 1] = {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = life * (0.6 + math.random() * 0.4),
            max_life = life,
            r = r, g = g, b = b,
        }
    end
end

local function add_tween(target, field, from, to, duration, delay)
    tweens[#tweens + 1] = {
        target = target, field = field,
        from = from, to = to,
        duration = duration,
        elapsed = -(delay or 0),
    }
end

local function init_team(formation, color_tag)
    local team = {}
    for i = 1, 5 do
        team[i] = {
            x = CENTER_X + formation[i].dx,
            y = CENTER_Y + formation[i].dy,
            vx = 0, vy = 0,
            tag = color_tag,
            tackling = false,
            tackle_cd = 0,
        }
    end
    return team
end

local function reset_positions()
    for i = 1, 5 do
        players_green[i].x = CENTER_X + green_formation[i].dx
        players_green[i].y = CENTER_Y + green_formation[i].dy
        players_green[i].vx = 0
        players_green[i].vy = 0
        players_green[i].tackling = false
        players_green[i].tackle_cd = 0
        players_red[i].x = CENTER_X + red_formation[i].dx
        players_red[i].y = CENTER_Y + red_formation[i].dy
        players_red[i].vx = 0
        players_red[i].vy = 0
        players_red[i].tackling = false
        players_red[i].tackle_cd = 0
    end
    ball.vx = 0
    ball.vy = 0
    if kickoff_team == "green" then
        ball.x = CENTER_X
        ball.y = CENTER_Y + 15
    else
        ball.x = CENTER_X
        ball.y = CENTER_Y - 15
    end
    tackle_timer = 0
end

local function nearest_to_ball(team)
    local best_i, best_d = 1, 99999
    for i = 1, #team do
        local d = dist(team[i].x, team[i].y, ball.x, ball.y)
        if d < best_d then best_i, best_d = i, d end
    end
    return best_i, best_d
end

local function nearest_teammate(team, idx)
    local best_i, best_d = idx, 99999
    for i = 1, #team do
        if i ~= idx then
            local d = dist(team[i].x, team[i].y, team[idx].x, team[idx].y)
            if d < best_d then best_i, best_d = i, d end
        end
    end
    return best_i
end

-- ── load ──────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("Sensible Soccer — Lurek2D")
    lurek.render.setBackgroundColor(0.15, 0.4, 0.1)

    players_green = init_team(green_formation, "green")
    players_red   = init_team(red_formation, "red")
    reset_positions()
end

-- ── update ────────────────────────────────────────────────────
function lurek.process(dt)
    title_blink = title_blink + dt

    -- tween update
    local alive_tweens = {}
    for i = 1, #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        if tw.elapsed >= 0 then
            local t = clamp(tw.elapsed / tw.duration, 0, 1)
            -- ease out quad
            local et = 1 - (1 - t) * (1 - t)
            if tw.target == "goal" then
                if tw.field == "scale" then goal_text_scale = tw.from + (tw.to - tw.from) * et end
                if tw.field == "flash" then goal_flash = tw.from + (tw.to - tw.from) * et end
            elseif tw.target == "halftime" then
                if tw.field == "alpha" then halftime_alpha = tw.from + (tw.to - tw.from) * et end
            end
        end
        if tw.elapsed < tw.duration then alive_tweens[#alive_tweens + 1] = tw end
    end
    tweens = alive_tweens

    -- particles
    local alive = {}
    for i = 1, #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life > 0 then alive[#alive + 1] = p end
    end
    particles = alive

    -- ── TITLE state ───────────────────────────────────────────
    if state == STATE.TITLE then
        return
    end

    -- ── HALFTIME state ────────────────────────────────────────
    if state == STATE.HALFTIME then
        if match_timer > HALF_TIME + 3 then
            state = STATE.PLAYING
            halftime_alpha = 0
        else
            match_timer = match_timer + dt
        end
        return
    end

    -- ── FULL_TIME state ───────────────────────────────────────
    if state == STATE.FULL_TIME then
        return
    end

    -- ── PLAYING state ─────────────────────────────────────────
    match_timer = match_timer + dt

    -- half-time check
    if not half_swapped and match_timer >= HALF_TIME then
        half_swapped = true
        -- swap formations
        for i = 1, 5 do
            green_formation[i].dy = -green_formation[i].dy
            red_formation[i].dy   = -red_formation[i].dy
        end
        reset_positions()
        state = STATE.HALFTIME
        add_tween("halftime", "alpha", 0, 1, 0.5, 0)
        add_tween("halftime", "alpha", 1, 0, 0.5, 2.0)
        return
    end

    -- full-time check
    if match_timer >= MATCH_TIME then
        state = STATE.FULL_TIME
        return
    end

    -- auto-select nearest green player
    controlled_idx = nearest_to_ball(players_green)

    -- read input
    input_dx, input_dy = 0, 0
    if lurek.input.isDown("w") then input_dy = -1 end
    if lurek.input.isDown("s") then input_dy =  1 end
    if lurek.input.isDown("a") then input_dx = -1 end
    if lurek.input.isDown("d") then input_dx =  1 end
    local idx_len = math.sqrt(input_dx * input_dx + input_dy * input_dy)
    if idx_len > 0 then
        input_dx = input_dx / idx_len
        input_dy = input_dy / idx_len
        facing_x = input_dx
        facing_y = input_dy
    end

    -- move controlled player
    local cp = players_green[controlled_idx]
    cp.x = cp.x + input_dx * PLAYER_SPEED * dt
    cp.y = cp.y + input_dy * PLAYER_SPEED * dt
    cp.x = clamp(cp.x, PITCH_X + PLAYER_RADIUS, PITCH_X + PITCH_W - PLAYER_RADIUS)
    cp.y = clamp(cp.y, PITCH_Y + PLAYER_RADIUS, PITCH_Y + PITCH_H - PLAYER_RADIUS)

    -- non-controlled green players drift toward formation
    for i = 1, 5 do
        if i ~= controlled_idx then
            local p = players_green[i]
            local tx = CENTER_X + green_formation[i].dx
            local ty = CENTER_Y + green_formation[i].dy
            local nx, ny = normalize(tx - p.x, ty - p.y)
            p.x = p.x + nx * PLAYER_SPEED * 0.4 * dt
            p.y = p.y + ny * PLAYER_SPEED * 0.4 * dt
            p.x = clamp(p.x, PITCH_X + PLAYER_RADIUS, PITCH_X + PITCH_W - PLAYER_RADIUS)
            p.y = clamp(p.y, PITCH_Y + PLAYER_RADIUS, PITCH_Y + PITCH_H - PLAYER_RADIUS)
        end
    end

    -- CPU AI
    local cpu_chase_idx = nearest_to_ball(players_red)
    for i = 1, 5 do
        local p = players_red[i]
        if i == cpu_chase_idx then
            local nx, ny = normalize(ball.x - p.x, ball.y - p.y)
            p.x = p.x + nx * CPU_SPEED * dt
            p.y = p.y + ny * CPU_SPEED * dt
            -- CPU kick when near ball
            local bd = dist(p.x, p.y, ball.x, ball.y)
            if bd < PLAYER_RADIUS + BALL_RADIUS + 4 then
                -- kick toward green goal (bottom if first half, top if swapped)
                local goal_y = half_swapped and (PITCH_Y) or (PITCH_Y + PITCH_H)
                local kx, ky = normalize(CENTER_X - ball.x, goal_y - ball.y)
                ball.vx = kx * KICK_POWER * 0.7
                ball.vy = ky * KICK_POWER * 0.7
                spawn_particles(ball.x, ball.y, 4, 0.8, 0.6, 0.3, 60, 0.3)
            end
        else
            local tx = CENTER_X + red_formation[i].dx
            local ty = CENTER_Y + red_formation[i].dy
            local nx, ny = normalize(tx - p.x, ty - p.y)
            p.x = p.x + nx * CPU_SPEED * 0.35 * dt
            p.y = p.y + ny * CPU_SPEED * 0.35 * dt
        end
        p.x = clamp(p.x, PITCH_X + PLAYER_RADIUS, PITCH_X + PITCH_W - PLAYER_RADIUS)
        p.y = clamp(p.y, PITCH_Y + PLAYER_RADIUS, PITCH_Y + PITCH_H - PLAYER_RADIUS)
    end

    -- tackle cooldown
    if tackle_timer > 0 then tackle_timer = tackle_timer - dt end
    for _, team in ipairs({ players_green, players_red }) do
        for i = 1, #team do
            if team[i].tackle_cd > 0 then team[i].tackle_cd = team[i].tackle_cd - dt end
            if team[i].tackling then
                team[i].x = team[i].x + team[i].vx * dt
                team[i].y = team[i].y + team[i].vy * dt
                team[i].vx = team[i].vx * 0.92
                team[i].vy = team[i].vy * 0.92
                if math.abs(team[i].vx) < 5 and math.abs(team[i].vy) < 5 then
                    team[i].tackling = false
                end
                -- tackle slide dust
                if math.random() < 0.4 then
                    spawn_particles(team[i].x, team[i].y, 1, 0.6, 0.5, 0.3, 30, 0.2)
                end
            end
            team[i].x = clamp(team[i].x, PITCH_X + PLAYER_RADIUS, PITCH_X + PITCH_W - PLAYER_RADIUS)
            team[i].y = clamp(team[i].y, PITCH_Y + PLAYER_RADIUS, PITCH_Y + PITCH_H - PLAYER_RADIUS)
        end
    end

    -- ball physics
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt
    ball.vx = ball.vx * BALL_FRICTION
    ball.vy = ball.vy * BALL_FRICTION
    if math.abs(ball.vx) < 1 then ball.vx = 0 end
    if math.abs(ball.vy) < 1 then ball.vy = 0 end

    -- ball trail particles
    local ball_speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
    if ball_speed > 80 then
        spawn_particles(ball.x, ball.y, 1, 1, 1, 1, 10, 0.15)
    end

    -- ball bounce off pitch edges (not goal openings)
    if ball.x < PITCH_X + BALL_RADIUS then
        ball.x = PITCH_X + BALL_RADIUS
        ball.vx = -ball.vx * 0.7
    elseif ball.x > PITCH_X + PITCH_W - BALL_RADIUS then
        ball.x = PITCH_X + PITCH_W - BALL_RADIUS
        ball.vx = -ball.vx * 0.7
    end
    -- top/bottom: bounce except in goal opening
    local in_goal_x = ball.x > GOAL_TOP_X and ball.x < GOAL_TOP_X + GOAL_W
    if ball.y < PITCH_Y + BALL_RADIUS and not in_goal_x then
        ball.y = PITCH_Y + BALL_RADIUS
        ball.vy = -ball.vy * 0.7
    elseif ball.y > PITCH_Y + PITCH_H - BALL_RADIUS and not in_goal_x then
        ball.y = PITCH_Y + PITCH_H - BALL_RADIUS
        ball.vy = -ball.vy * 0.7
    end

    -- goal detection — top goal
    if ball.y < GOAL_TOP_Y + GOAL_DEPTH and in_goal_x then
        -- goal scored at top
        if half_swapped then
            score_green = score_green + 1
            kickoff_team = "red"
        else
            score_red = score_red + 1
            kickoff_team = "green"
        end
        spawn_particles(ball.x, ball.y, 20, 1, 1, 0, 120, 0.6)
        goal_text_scale = 0
        goal_flash = 1
        add_tween("goal", "scale", 0, 2.5, 0.6, 0)
        add_tween("goal", "flash", 1, 0, 1.0, 0.3)
        reset_positions()
    end
    -- goal detection — bottom goal
    if ball.y > GOAL_BOT_Y + GOAL_DEPTH and in_goal_x then
        if half_swapped then
            score_red = score_red + 1
            kickoff_team = "green"
        else
            score_green = score_green + 1
            kickoff_team = "red"
        end
        spawn_particles(ball.x, ball.y, 20, 1, 1, 0, 120, 0.6)
        goal_text_scale = 0
        goal_flash = 1
        add_tween("goal", "scale", 0, 2.5, 0.6, 0)
        add_tween("goal", "flash", 1, 0, 1.0, 0.3)
        reset_positions()
    end

    -- player-ball collision (any player near ball gains control momentum)
    for _, team in ipairs({ players_green, players_red }) do
        for i = 1, #team do
            local p = team[i]
            local d = dist(p.x, p.y, ball.x, ball.y)
            if d < PLAYER_RADIUS + BALL_RADIUS + 2 and not p.tackling then
                -- nudge ball away
                local nx, ny = normalize(ball.x - p.x, ball.y - p.y)
                ball.x = p.x + nx * (PLAYER_RADIUS + BALL_RADIUS + 2)
                ball.y = p.y + ny * (PLAYER_RADIUS + BALL_RADIUS + 2)
                -- dribble: ball follows player movement slightly
                ball.vx = ball.vx * 0.3
                ball.vy = ball.vy * 0.3
            end
        end
    end
end

-- ── draw ──────────────────────────────────────────────────────
function lurek.draw()
    -- pitch background
    lurek.render.setColor(0.18, 0.5, 0.15, 1)
    lurek.render.rectangle("fill", PITCH_X, PITCH_Y, PITCH_W, PITCH_H)

    -- pitch lines
    lurek.render.setColor(1, 1, 1, 0.7)
    lurek.render.rectangle("line", PITCH_X, PITCH_Y, PITCH_W, PITCH_H)
    -- halfway line
    lurek.render.line(PITCH_X, CENTER_Y, PITCH_X + PITCH_W, CENTER_Y)
    -- center circle
    lurek.render.circle("line", CENTER_X, CENTER_Y, 50)
    -- center spot
    lurek.render.circle("fill", CENTER_X, CENTER_Y, 3)

    -- penalty boxes
    local pbox_w = 200
    local pbox_h = 70
    local pbox_x = PITCH_X + (PITCH_W - pbox_w) / 2
    lurek.render.rectangle("line", pbox_x, PITCH_Y, pbox_w, pbox_h)
    lurek.render.rectangle("line", pbox_x, PITCH_Y + PITCH_H - pbox_h, pbox_w, pbox_h)

    -- goals
    lurek.render.setColor(1, 1, 1, 0.9)
    lurek.render.rectangle("fill", GOAL_TOP_X, GOAL_TOP_Y, GOAL_W, GOAL_DEPTH)
    lurek.render.rectangle("fill", GOAL_BOT_X, GOAL_BOT_Y, GOAL_W, GOAL_DEPTH)

    -- particles (behind players)
    for i = 1, #particles do
        local p = particles[i]
        local a = clamp(p.life / p.max_life, 0, 1)
        lurek.render.setColor(p.r, p.g, p.b, a * 0.8)
        lurek.render.circle("fill", p.x, p.y, 2)
    end

    -- draw players
    for i = 1, 5 do
        local p = players_green[i]
        if i == controlled_idx and state == STATE.PLAYING then
            lurek.render.setColor(1, 1, 0, 0.5)
            lurek.render.circle("line", p.x, p.y, PLAYER_RADIUS + 3)
        end
        lurek.render.setColor(0.2, 0.8, 0.2, 1)
        lurek.render.circle("fill", p.x, p.y, PLAYER_RADIUS)
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.circle("line", p.x, p.y, PLAYER_RADIUS)
    end
    for i = 1, 5 do
        local p = players_red[i]
        lurek.render.setColor(0.9, 0.2, 0.2, 1)
        lurek.render.circle("fill", p.x, p.y, PLAYER_RADIUS)
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.circle("line", p.x, p.y, PLAYER_RADIUS)
    end

    -- ball
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.circle("fill", ball.x, ball.y, BALL_RADIUS)
    lurek.render.setColor(0, 0, 0, 0.5)
    lurek.render.circle("line", ball.x, ball.y, BALL_RADIUS)
end

-- ── UI ────────────────────────────────────────────────────────
function lurek.draw_ui()
    -- TITLE state
    if state == STATE.TITLE then
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("SENSIBLE SOCCER", SCR_W / 2 - 100, SCR_H / 2 - 60)
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 0, 1)
            lurek.render.print("KICK OFF!", SCR_W / 2 - 55, SCR_H / 2)
        end
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("Press SPACE to start", SCR_W / 2 - 90, SCR_H / 2 + 50)
        lurek.render.print("WASD=Move  SPACE=Kick  F=Pass  T=Tackle", SCR_W / 2 - 165, SCR_H / 2 + 80)
        return
    end

    -- score bar
    lurek.render.setColor(0, 0, 0, 0.6)
    lurek.render.rectangle("fill", 0, 0, SCR_W, 24)

    -- team labels + score
    lurek.render.setColor(0.3, 1, 0.3, 1)
    lurek.render.print("GREEN " .. score_green, 10, 4)
    lurek.render.setColor(1, 0.3, 0.3, 1)
    lurek.render.print(score_red .. " RED", SCR_W - 75, 4)

    -- timer
    local remaining = math.max(0, MATCH_TIME - match_timer)
    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    local timer_str = string.format("%d:%02d", mins, secs)
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print(timer_str, SCR_W / 2 - 18, 4)

    -- half indicator
    local half_str = match_timer < HALF_TIME and "1st HALF" or "2nd HALF"
    lurek.render.setColor(0.8, 0.8, 0.8, 0.7)
    lurek.render.print(half_str, SCR_W / 2 - 28, SCR_H - 20)

    -- goal flash + text
    if goal_flash > 0 then
        lurek.render.setColor(1, 1, 1, goal_flash * 0.3)
        lurek.render.rectangle("fill", 0, 0, SCR_W, SCR_H)
    end
    if goal_text_scale > 0.1 then
        lurek.render.setColor(1, 1, 0, clamp(goal_text_scale / 2, 0, 1))
        lurek.render.print("GOAL!", SCR_W / 2 - 30, SCR_H / 2 - 20)
    end

    -- HALFTIME overlay
    if state == STATE.HALFTIME then
        lurek.render.setColor(0, 0, 0, halftime_alpha * 0.7)
        lurek.render.rectangle("fill", 0, 0, SCR_W, SCR_H)
        lurek.render.setColor(1, 1, 1, halftime_alpha)
        lurek.render.print("HALF TIME", SCR_W / 2 - 55, SCR_H / 2 - 20)
        lurek.render.print(score_green .. " - " .. score_red, SCR_W / 2 - 20, SCR_H / 2 + 10)
    end

    -- FULL TIME overlay
    if state == STATE.FULL_TIME then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 0, 0, SCR_W, SCR_H)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("FULL TIME", SCR_W / 2 - 55, SCR_H / 2 - 40)
        lurek.render.print(score_green .. " - " .. score_red, SCR_W / 2 - 20, SCR_H / 2)
        local result = "DRAW"
        if score_green > score_red then result = "GREEN WINS!" end
        if score_red > score_green then result = "RED WINS!" end
        lurek.render.setColor(1, 1, 0, 1)
        lurek.render.print(result, SCR_W / 2 - 45, SCR_H / 2 + 30)
        lurek.render.setColor(0.7, 0.7, 0.7, 1)
        lurek.render.print("Press SPACE for rematch", SCR_W / 2 - 95, SCR_H / 2 + 70)
    end

    -- FPS
    lurek.render.setColor(1, 1, 1, 0.4)
    lurek.render.print("FPS: " .. lurek.timer.getFPS(), SCR_W - 80, SCR_H - 20)
end

-- ── keypressed ────────────────────────────────────────────────
function lurek._keypressed(key)
    if key == "escape" then lurek.event.quit() end

    if state == STATE.TITLE then
        if key == "space" then
            state = STATE.PLAYING
            match_timer = 0
            score_green = 0
            score_red = 0
            half_swapped = false
            kickoff_team = "green"
            -- restore formations in case of rematch after swap
            green_formation = {
                { dx =   0, dy = 100 },
                { dx = -80, dy =  20 },
                { dx =  80, dy =  20 },
                { dx = -40, dy = -60 },
                { dx =  40, dy = -60 },
            }
            red_formation = {
                { dx =   0, dy = -100 },
                { dx = -80, dy = - 20 },
                { dx =  80, dy = - 20 },
                { dx = -40, dy =  60 },
                { dx =  40, dy =  60 },
            }
            players_green = init_team(green_formation, "green")
            players_red   = init_team(red_formation, "red")
            reset_positions()
        end
        return
    end

    if state == STATE.FULL_TIME then
        if key == "space" then
            state = STATE.TITLE
        end
        return
    end

    if state ~= STATE.PLAYING then return end

    -- kick
    if key == "space" then
        local cp = players_green[controlled_idx]
        local d = dist(cp.x, cp.y, ball.x, ball.y)
        if d < PLAYER_RADIUS + BALL_RADIUS + 10 then
            ball.vx = facing_x * KICK_POWER
            ball.vy = facing_y * KICK_POWER
            spawn_particles(ball.x, ball.y, 6, 0.8, 0.7, 0.4, 80, 0.3)
        end
    end

    -- pass
    if key == "f" then
        local cp = players_green[controlled_idx]
        local d = dist(cp.x, cp.y, ball.x, ball.y)
        if d < PLAYER_RADIUS + BALL_RADIUS + 10 then
            local ti = nearest_teammate(players_green, controlled_idx)
            local target = players_green[ti]
            local nx, ny = normalize(target.x - ball.x, target.y - ball.y)
            ball.vx = nx * PASS_POWER
            ball.vy = ny * PASS_POWER
            spawn_particles(ball.x, ball.y, 4, 0.6, 0.8, 0.4, 50, 0.25)
        end
    end

    -- tackle
    if key == "t" then
        local cp = players_green[controlled_idx]
        if cp.tackle_cd <= 0 and not cp.tackling then
            local d = dist(cp.x, cp.y, ball.x, ball.y)
            if d < TACKLE_RANGE * 3 then
                cp.tackling = true
                cp.tackle_cd = 0.8
                local nx, ny = normalize(ball.x - cp.x, ball.y - cp.y)
                cp.vx = nx * TACKLE_LUNGE
                cp.vy = ny * TACKLE_LUNGE
                spawn_particles(cp.x, cp.y, 5, 0.5, 0.4, 0.2, 60, 0.35)
            end
        end
    end
end
