-- Pong — Classic Arcade (Luna2D demo)
-- Two-player Pong: Player 1 = W/S, Player 2 = Up/Down arrow keys.
-- First to 7 points wins.

-- ── State ────────────────────────────────────────────────────────────────

local W, H = 800, 600
local PADDLE_W, PADDLE_H = 14, 80
local BALL_SIZE = 12
local PADDLE_SPEED = 320
local BASE_BALL_SPEED = 280
local WIN_SCORE = 7

local p1 = { x = 20, y = H/2 - PADDLE_H/2, score = 0 }
local p2 = { x = W - 20 - PADDLE_W, y = H/2 - PADDLE_H/2, score = 0 }
local ball = { x = W/2, y = H/2, vx = 0, vy = 0 }
local game_over = false
local winner = 0
local flash_timer = 0

-- ── Helpers ──────────────────────────────────────────────────────────────

local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end

local function ball_reset(dir)
    ball.x = W / 2
    ball.y = H / 2
    local angle = (math.random() * 0.6 - 0.3)
    ball.vx = BASE_BALL_SPEED * dir
    ball.vy = BASE_BALL_SPEED * math.sin(angle)
    flash_timer = 0.5
end

local function rect_overlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- ── Load ─────────────────────────────────────────────────────────────────

function luna.load()
    luna.graphics.setBackgroundColor(0.05, 0.05, 0.05)
    ball_reset(1)
end

-- ── Update ───────────────────────────────────────────────────────────────

function luna.update(dt)
    flash_timer = math.max(0, flash_timer - dt)
    if game_over then return end

    -- Player 1 input (W/S)
    if luna.input.isKeyDown("w") then p1.y = p1.y - PADDLE_SPEED * dt end
    if luna.input.isKeyDown("s") then p1.y = p1.y + PADDLE_SPEED * dt end
    -- Player 2 input (Up/Down)
    if luna.input.isKeyDown("up")   then p2.y = p2.y - PADDLE_SPEED * dt end
    if luna.input.isKeyDown("down") then p2.y = p2.y + PADDLE_SPEED * dt end

    p1.y = clamp(p1.y, 0, H - PADDLE_H)
    p2.y = clamp(p2.y, 0, H - PADDLE_H)

    -- Ball movement
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Top/bottom bounce
    if ball.y <= 0 then ball.y = 0; ball.vy = math.abs(ball.vy) end
    if ball.y + BALL_SIZE >= H then ball.y = H - BALL_SIZE; ball.vy = -math.abs(ball.vy) end

    -- Paddle collisions — slightly speed up on each hit
    if ball.vx < 0 and rect_overlap(ball.x, ball.y, BALL_SIZE, BALL_SIZE,
                                     p1.x, p1.y, PADDLE_W, PADDLE_H) then
        ball.vx = math.min(math.abs(ball.vx) * 1.06, 620)
        local rel = (ball.y + BALL_SIZE/2 - (p1.y + PADDLE_H/2)) / (PADDLE_H/2)
        ball.vy = rel * BASE_BALL_SPEED
    end
    if ball.vx > 0 and rect_overlap(ball.x, ball.y, BALL_SIZE, BALL_SIZE,
                                     p2.x, p2.y, PADDLE_W, PADDLE_H) then
        ball.vx = -math.min(math.abs(ball.vx) * 1.06, 620)
        local rel = (ball.y + BALL_SIZE/2 - (p2.y + PADDLE_H/2)) / (PADDLE_H/2)
        ball.vy = rel * BASE_BALL_SPEED
    end

    -- Scoring
    if ball.x < 0 then
        p2.score = p2.score + 1
        if p2.score >= WIN_SCORE then game_over = true; winner = 2 else ball_reset(-1) end
    end
    if ball.x > W then
        p1.score = p1.score + 1
        if p1.score >= WIN_SCORE then game_over = true; winner = 1 else ball_reset(1) end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function luna.draw()
    -- Center dashed line
    luna.graphics.setColor(0.25, 0.25, 0.25)
    for i = 0, H, 24 do
        luna.graphics.rectangle("fill", W/2 - 2, i, 4, 12)
    end

    -- Paddles
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.rectangle("fill", p1.x, p1.y, PADDLE_W, PADDLE_H)
    luna.graphics.rectangle("fill", p2.x, p2.y, PADDLE_W, PADDLE_H)

    -- Ball (flash white/yellow after score)
    if flash_timer > 0 then
        luna.graphics.setColor(1, 1, 0)
    else
        luna.graphics.setColor(1, 1, 1)
    end
    luna.graphics.rectangle("fill", ball.x, ball.y, BALL_SIZE, BALL_SIZE)

    -- Scores
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print(tostring(p1.score), W/2 - 70, 18, 4)
    luna.graphics.print(tostring(p2.score), W/2 + 38, 18, 4)

    -- Controls hint
    luna.graphics.setColor(0.4, 0.4, 0.4)
    luna.graphics.print("P1: W/S", 8, H - 18, 1)
    luna.graphics.print("P2: Up/Down", W - 112, H - 18, 1)

    -- Game-over overlay
    if game_over then
        luna.graphics.setColor(0, 0, 0, 0.6)
        luna.graphics.rectangle("fill", 0, 0, W, H)
        luna.graphics.setColor(1, 0.9, 0.1)
        luna.graphics.print("Player " .. winner .. " Wins!", W/2 - 130, H/2 - 30, 3)
        luna.graphics.setColor(0.7, 0.7, 0.7)
        luna.graphics.print("Press R to restart", W/2 - 100, H/2 + 20, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" and game_over then
        p1.score = 0; p2.score = 0
        game_over = false; winner = 0
        ball_reset(1)
    end
end
