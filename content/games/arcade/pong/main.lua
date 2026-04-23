-- ============================================================================
--  Pong — Classic two-player paddle game
-- ----------------------------------------------------------------------------
--  Category : arcade
--  Source   : ../../../../content/demos/arcade/pong   (original demo)
--  Run with : cargo run -- content/games/arcade/pong
--
--  Upgrade  : action-based input, scene states, particle sparks on paddle
--             hits, tween score pop, render/render_ui split, FPS counter
-- ============================================================================

-- ── Constants ────────────────────────────────────────────────────────────


local W, H          = 800, 600
local PADDLE_W      = 14
local PADDLE_H      = 80
local BALL_SIZE     = 12
local PADDLE_SPEED  = 320
local BASE_BALL_SPEED = 280
local MAX_BALL_SPEED  = 620
local WIN_SCORE     = 7

-- ── Scene states ─────────────────────────────────────────────────────────

local STATE = { TITLE = 1, PLAYING = 2, GAME_OVER = 3 }
local state = STATE.TITLE

-- ── Game objects ──────────────────────────────────────────────────────────

local p1 = { x = 20, y = H / 2 - PADDLE_H / 2, score = 0 }
local p2 = { x = W - 20 - PADDLE_W, y = H / 2 - PADDLE_H / 2, score = 0 }
local ball = { x = W / 2, y = H / 2, vx = 0, vy = 0 }
local winner = 0
local flash_timer = 0

-- ── Score pop tween state ────────────────────────────────────────────────

local score_pop = { scale = 1.0 }

-- ── Particle system handle ───────────────────────────────────────────────

local sparks = nil

-- ── Title screen blink ───────────────────────────────────────────────────

local title_blink = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

local function ball_reset(dir)
    ball.x = W / 2
    ball.y = H / 2
    local angle = math.random() * 0.6 - 0.3
    ball.vx = BASE_BALL_SPEED * dir
    ball.vy = BASE_BALL_SPEED * math.sin(angle)
    flash_timer = 0.5
end

local function rect_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

local function full_reset()
    p1.score = 0
    p2.score = 0
    p1.y = H / 2 - PADDLE_H / 2
    p2.y = H / 2 - PADDLE_H / 2
    winner = 0
    flash_timer = 0
    score_pop.scale = 1.0
    ball_reset(1)
end

-- ── Init ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.window.setTitle("Pong — Lurek2D")
    lurek.render.setBackgroundColor(0.05, 0.05, 0.05)

    -- Action-based input bindings
    lurek.input.bind("p1_up",   {"w"})
    lurek.input.bind("p1_down", {"s"})
    lurek.input.bind("p2_up",   {"up"})
    lurek.input.bind("p2_down", {"down"})
    lurek.input.bind("start",   {"return"})
    lurek.input.bind("restart", {"r"})

    -- Particle system for paddle-hit sparks
    sparks = lurek.particle.newSystem({
        maxParticles   = 64,
        emissionRate   = 0,
        lifetime       = { 0.15, 0.4 },
        speed          = { 80, 220 },
        spread         = math.pi * 0.5,
        sizeStart      = 4,
        sizeEnd        = 1,
        colorStart     = { 1, 1, 0.5, 1 },
        colorEnd       = { 1, 0.4, 0, 0 },
    })

    ball_reset(1)
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    -- Tween update (runs in all states for smooth finish)
    lurek.tween.update(dt)

    -- Particle update
    if sparks then
        sparks:update(dt)
    end

    -- ── TITLE state ──────────────────────────────────────────────────────
    if state == STATE.TITLE then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("start") then
            state = STATE.PLAYING
            full_reset()
        end
        return
    end

    -- ── GAME_OVER state ──────────────────────────────────────────────────
    if state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("restart") then
            full_reset()
            state = STATE.PLAYING
        end
        return
    end

    -- ── PLAYING state ────────────────────────────────────────────────────
    flash_timer = math.max(0, flash_timer - dt)

    -- Player 1 input
    if lurek.input.isActionDown("p1_up")   then p1.y = p1.y - PADDLE_SPEED * dt end
    if lurek.input.isActionDown("p1_down") then p1.y = p1.y + PADDLE_SPEED * dt end

    -- Player 2 input
    if lurek.input.isActionDown("p2_up")   then p2.y = p2.y - PADDLE_SPEED * dt end
    if lurek.input.isActionDown("p2_down") then p2.y = p2.y + PADDLE_SPEED * dt end

    p1.y = clamp(p1.y, 0, H - PADDLE_H)
    p2.y = clamp(p2.y, 0, H - PADDLE_H)

    -- Ball movement
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Top / bottom bounce
    if ball.y <= 0 then
        ball.y = 0
        ball.vy = math.abs(ball.vy)
    end
    if ball.y + BALL_SIZE >= H then
        ball.y = H - BALL_SIZE
        ball.vy = -math.abs(ball.vy)
    end

    -- Paddle 1 collision (ball moving left)
    if ball.vx < 0 and rect_overlap(ball.x, ball.y, BALL_SIZE, BALL_SIZE,
                                     p1.x, p1.y, PADDLE_W, PADDLE_H) then
        ball.vx = math.min(math.abs(ball.vx) * 1.06, MAX_BALL_SPEED)
        local rel = (ball.y + BALL_SIZE / 2 - (p1.y + PADDLE_H / 2)) / (PADDLE_H / 2)
        ball.vy = rel * BASE_BALL_SPEED

        -- Emit sparks at contact point
        if sparks then
            sparks:setPosition(p1.x + PADDLE_W, ball.y + BALL_SIZE / 2)
            sparks:setDirection(0)  -- right
            sparks:emit(12)
        end
    end

    -- Paddle 2 collision (ball moving right)
    if ball.vx > 0 and rect_overlap(ball.x, ball.y, BALL_SIZE, BALL_SIZE,
                                     p2.x, p2.y, PADDLE_W, PADDLE_H) then
        ball.vx = -math.min(math.abs(ball.vx) * 1.06, MAX_BALL_SPEED)
        local rel = (ball.y + BALL_SIZE / 2 - (p2.y + PADDLE_H / 2)) / (PADDLE_H / 2)
        ball.vy = rel * BASE_BALL_SPEED

        -- Emit sparks at contact point
        if sparks then
            sparks:setPosition(p2.x, ball.y + BALL_SIZE / 2)
            sparks:setDirection(math.pi)  -- left
            sparks:emit(12)
        end
    end

    -- Scoring
    if ball.x < 0 then
        p2.score = p2.score + 1
        score_pop.scale = 2.0
        lurek.tween.to(score_pop, 0.3, { scale = 1.0 })
        if p2.score >= WIN_SCORE then
            state = STATE.GAME_OVER
            winner = 2
        else
            ball_reset(-1)
        end
    end
    if ball.x > W then
        p1.score = p1.score + 1
        score_pop.scale = 2.0
        lurek.tween.to(score_pop, 0.3, { scale = 1.0 })
        if p1.score >= WIN_SCORE then
            state = STATE.GAME_OVER
            winner = 1
        else
            ball_reset(1)
        end
    end
end

-- ── World rendering ──────────────────────────────────────────────────────

function lurek.draw()
    -- ── TITLE state ──────────────────────────────────────────────────────
    if state == STATE.TITLE then
        -- Title
        lurek.render.setColor(1, 1, 1)
        lurek.render.print("PONG", W / 2 - 80, H / 3 - 20, 5)

        -- Blinking prompt
        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(0.8, 0.8, 0.8)
            lurek.render.print("PRESS ENTER TO START", W / 2 - 150, H / 2 + 20, 2)
        end

        -- Controls info
        lurek.render.setColor(0.4, 0.4, 0.4)
        lurek.render.print("P1: W / S       P2: Up / Down", W / 2 - 175, H * 0.7, 1.5)
        lurek.render.print("First to " .. WIN_SCORE .. " wins", W / 2 - 80, H * 0.7 + 30, 1.5)
        return
    end

    -- ── PLAYING / GAME_OVER shared world ─────────────────────────────────

    -- Center dashed line
    lurek.render.setColor(0.25, 0.25, 0.25)
    for i = 0, H, 24 do
        lurek.render.rectangle("fill", W / 2 - 2, i, 4, 12)
    end

    -- Paddles
    lurek.render.setColor(1, 1, 1)
    lurek.render.rectangle("fill", p1.x, p1.y, PADDLE_W, PADDLE_H)
    lurek.render.rectangle("fill", p2.x, p2.y, PADDLE_W, PADDLE_H)

    -- Ball (flash yellow after score)
    if flash_timer > 0 then
        lurek.render.setColor(1, 1, 0)
    else
        lurek.render.setColor(1, 1, 1)
    end
    lurek.render.rectangle("fill", ball.x, ball.y, BALL_SIZE, BALL_SIZE)

    -- Particle sparks
    if sparks then
        sparks:draw()
    end

    -- Game-over overlay
    if state == STATE.GAME_OVER then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle("fill", 0, 0, W, H)
        lurek.render.setColor(1, 0.9, 0.1)
        lurek.render.print("Player " .. winner .. " Wins!", W / 2 - 130, H / 2 - 30, 3)
        lurek.render.setColor(0.7, 0.7, 0.7)
        lurek.render.print("Press R to restart", W / 2 - 100, H / 2 + 20, 2)
    end
end

-- ── HUD / overlay rendering ─────────────────────────────────────────────

function lurek.draw_ui()
    if state == STATE.TITLE then return end

    -- Score display with tween pop effect
    local s = score_pop.scale
    lurek.render.setColor(1, 1, 1)
    lurek.render.print(tostring(p1.score), W / 2 - 70, 18, 4 * s)
    lurek.render.print(tostring(p2.score), W / 2 + 38, 18, 4 * s)

    -- Controls hint
    lurek.render.setColor(0.4, 0.4, 0.4)
    lurek.render.print("P1: W/S", 8, H - 18, 1)
    lurek.render.print("P2: Up/Down", W - 112, H - 18, 1)

    -- FPS counter
    local fps = lurek.timer.getFPS()
    lurek.render.setColor(0.3, 0.3, 0.3)
    lurek.render.print("FPS: " .. math.floor(fps), W - 80, 4, 1)
end

-- ── Input events ─────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then
        lurek.event.quit()
    end
end
