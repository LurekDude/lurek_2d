-- Brick Breaker (Arkanoid)
-- Mouse to move paddle. Ball bounces off bricks, walls, paddle.
-- Power-ups: wider paddle, multi-ball, slow ball. 3 lives.
-- Run with: cargo run -- demos/action/brick_breaker

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600

local paddle = {}
local balls = {}
local bricks = {}
local powerups = {}
local particles = {}

local state = {}

local BRICK_W = 70
local BRICK_H = 20
local BRICK_COLS = 10
local BRICK_GAP = 3
local BRICK_OFFSET_X = 35
local BRICK_OFFSET_Y = 60

local function make_bricks(level)
    bricks = {}
    local rows = 4 + level
    if rows > 8 then rows = 8 end
    for r = 1, rows do
        for c = 1, BRICK_COLS do
            local hp = 1
            if r <= 2 then hp = 3
            elseif r <= 4 then hp = 2
            end
            bricks[#bricks + 1] = {
                x = BRICK_OFFSET_X + (c - 1) * (BRICK_W + BRICK_GAP),
                y = BRICK_OFFSET_Y + (r - 1) * (BRICK_H + BRICK_GAP),
                w = BRICK_W, h = BRICK_H,
                hp = hp, alive = true
            }
        end
    end
end

local function make_ball(x, y, vx, vy)
    return { x = x, y = y, vx = vx, vy = vy, radius = 5 }
end

local function spawn_powerup(x, y)
    if math.random() > 0.3 then return end
    local types = { "wide", "multi", "slow" }
    local t = types[math.random(1, #types)]
    powerups[#powerups + 1] = { x = x, y = y, w = 20, h = 10, type = t, vy = 80 }
end

local function spawn_particles(x, y, r, g, b, count)
    for _ = 1, count do
        local angle = math.random() * math.pi * 2
        local spd = math.random(30, 120)
        particles[#particles + 1] = {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = math.random() * 0.5 + 0.2,
            r = r, g = g, b = b
        }
    end
end

function luna.init()
    paddle = { x = W / 2 - 50, y = H - 40, w = 100, h = 12 }
    balls = { make_ball(W / 2, H - 60, 180, -220) }
    powerups = {}
    particles = {}
    state.score = 0
    state.combo = 0
    state.lives = 3
    state.level = 1
    state.game_over = false
    state.serving = true
    state.wide_timer = 0
    state.slow_timer = 0
    make_bricks(1)
end

function luna.process(dt)
    if state.game_over then return end

    -- paddle follows mouse
    local mx = luna.mouse.getPosition()
    paddle.x = clamp(mx - paddle.w / 2, 0, W - paddle.w)

    -- wide paddle timer
    if state.wide_timer > 0 then
        state.wide_timer = state.wide_timer - dt
        paddle.w = 150
        if state.wide_timer <= 0 then paddle.w = 100 end
    end

    -- slow timer
    local speed_mult = 1
    if state.slow_timer > 0 then
        state.slow_timer = state.slow_timer - dt
        speed_mult = 0.5
    end

    -- serving: ball sticks to paddle
    if state.serving then
        balls[1].x = paddle.x + paddle.w / 2
        balls[1].y = paddle.y - balls[1].radius - 1
        return
    end

    -- update balls
    local dead_balls = {}
    for bi, ball in ipairs(balls) do
        ball.x = ball.x + ball.vx * dt * speed_mult
        ball.y = ball.y + ball.vy * dt * speed_mult

        -- wall bounces
        if ball.x - ball.radius < 0 then
            ball.x = ball.radius; ball.vx = math.abs(ball.vx)
        end
        if ball.x + ball.radius > W then
            ball.x = W - ball.radius; ball.vx = -math.abs(ball.vx)
        end
        if ball.y - ball.radius < 0 then
            ball.y = ball.radius; ball.vy = math.abs(ball.vy)
        end

        -- fell off bottom
        if ball.y > H + 20 then
            dead_balls[#dead_balls + 1] = bi
        end

        -- paddle collision
        if ball.vy > 0 and
            ball.x > paddle.x and ball.x < paddle.x + paddle.w and
            ball.y + ball.radius >= paddle.y and ball.y + ball.radius <= paddle.y + paddle.h + 5 then
            ball.vy = -math.abs(ball.vy)
            -- angle based on hit position
            local hit_pos = (ball.x - paddle.x) / paddle.w -- 0..1
            local angle_range = 1.2 -- radians from center
            local angle = -math.pi / 2 + (hit_pos - 0.5) * angle_range
            local spd = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
            ball.vx = math.cos(angle) * spd
            ball.vy = math.sin(angle) * spd
            state.combo = 0
        end

        -- brick collision
        for _, brick in ipairs(bricks) do
            if brick.alive then
                if ball.x + ball.radius > brick.x and ball.x - ball.radius < brick.x + brick.w and
                    ball.y + ball.radius > brick.y and ball.y - ball.radius < brick.y + brick.h then
                    brick.hp = brick.hp - 1
                    if brick.hp <= 0 then
                        brick.alive = false
                        state.combo = state.combo + 1
                        state.score = state.score + 10 * state.combo
                        spawn_powerup(brick.x + brick.w / 2, brick.y + brick.h / 2)
                        local cr, cg, cb = 0.3, 1, 0.3
                        if state.combo > 3 then cr, cg, cb = 1, 1, 0.3 end
                        spawn_particles(brick.x + brick.w / 2, brick.y + brick.h / 2, cr, cg, cb, 6)
                    end

                    -- bounce direction
                    local overlap_x = math.abs(ball.x - (brick.x + brick.w / 2)) - brick.w / 2
                    local overlap_y = math.abs(ball.y - (brick.y + brick.h / 2)) - brick.h / 2
                    if overlap_x > overlap_y then
                        ball.vx = -ball.vx
                    else
                        ball.vy = -ball.vy
                    end
                    break
                end
            end
        end
    end

    -- remove dead balls
    for i = #dead_balls, 1, -1 do
        table.remove(balls, dead_balls[i])
    end

    if #balls == 0 then
        state.lives = state.lives - 1
        state.combo = 0
        if state.lives <= 0 then
            state.game_over = true
        else
            balls = { make_ball(W / 2, H - 60, 180, -220) }
            state.serving = true
        end
    end

    -- check level clear
    local all_dead = true
    for _, brick in ipairs(bricks) do
        if brick.alive then all_dead = false; break end
    end
    if all_dead then
        state.level = state.level + 1
        make_bricks(state.level)
        balls = { make_ball(W / 2, H - 60, 200 + state.level * 10, -240 - state.level * 10) }
        state.serving = true
        state.combo = 0
    end

    -- powerups
    local dead_pu = {}
    for pi, pu in ipairs(powerups) do
        pu.y = pu.y + pu.vy * dt
        if pu.y > H then
            dead_pu[#dead_pu + 1] = pi
        elseif pu.x > paddle.x and pu.x < paddle.x + paddle.w and
            pu.y + pu.h > paddle.y and pu.y < paddle.y + paddle.h then
            if pu.type == "wide" then state.wide_timer = 8 end
            if pu.type == "slow" then state.slow_timer = 6 end
            if pu.type == "multi" and #balls < 8 then
                local b = balls[1]
                if b then
                    balls[#balls + 1] = make_ball(b.x, b.y, b.vx + 40, b.vy - 20)
                    balls[#balls + 1] = make_ball(b.x, b.y, b.vx - 40, b.vy - 20)
                end
            end
            dead_pu[#dead_pu + 1] = pi
        end
    end
    for i = #dead_pu, 1, -1 do table.remove(powerups, dead_pu[i]) end

    -- particles
    local dead_p = {}
    for pi, p in ipairs(particles) do
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then dead_p[#dead_p + 1] = pi end
    end
    for i = #dead_p, 1, -1 do table.remove(particles, dead_p[i]) end
end

function luna.mousepressed(x, y, button)
    if state.serving and not state.game_over then
        state.serving = false
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.signal.quit() end
    if key == "r" then luna.signal.restart() end
    if key == "space" and state.serving then state.serving = false end
end

local function brick_color(hp)
    if hp >= 3 then return 1, 0.25, 0.2 end
    if hp == 2 then return 1, 0.85, 0.2 end
    return 0.3, 0.9, 0.3
end

function luna.render()
    luna.gfx.setBackgroundColor(0.08, 0.08, 0.14)

    -- bricks
    for _, brick in ipairs(bricks) do
        if brick.alive then
            local r, g, b = brick_color(brick.hp)
            luna.gfx.setColor(r, g, b, 1)
            luna.gfx.rectangle("fill", brick.x, brick.y, brick.w, brick.h)
            luna.gfx.setColor(r * 0.6, g * 0.6, b * 0.6, 1)
            luna.gfx.rectangle("line", brick.x, brick.y, brick.w, brick.h)
        end
    end

    -- particles
    for _, p in ipairs(particles) do
        local a = clamp(p.life * 3, 0, 1)
        luna.gfx.setColor(p.r, p.g, p.b, a)
        luna.gfx.circle("fill", p.x, p.y, 3)
    end

    -- powerups
    for _, pu in ipairs(powerups) do
        if pu.type == "wide" then luna.gfx.setColor(0.2, 0.6, 1, 1)
        elseif pu.type == "multi" then luna.gfx.setColor(1, 0.4, 1, 1)
        else luna.gfx.setColor(0.4, 1, 0.4, 1) end
        luna.gfx.rectangle("fill", pu.x - pu.w / 2, pu.y, pu.w, pu.h)
        luna.gfx.setColor(1, 1, 1, 0.8)
        local label = pu.type:sub(1, 1):upper()
        luna.gfx.print(label, pu.x - 3, pu.y)
    end

    -- paddle
    luna.gfx.setColor(0.3, 0.5, 1, 1)
    luna.gfx.rectangle("fill", paddle.x, paddle.y, paddle.w, paddle.h)
    if state.wide_timer > 0 then
        luna.gfx.setColor(0.5, 0.8, 1, 0.4)
        luna.gfx.rectangle("fill", paddle.x - 2, paddle.y - 2, paddle.w + 4, paddle.h + 4)
    end

    -- balls
    for _, ball in ipairs(balls) do
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.circle("fill", ball.x, ball.y, ball.radius)
        if state.slow_timer > 0 then
            luna.gfx.setColor(0.4, 1, 0.4, 0.3)
            luna.gfx.circle("fill", ball.x, ball.y, ball.radius + 3)
        end
    end

    -- HUD
    luna.gfx.setColor(1, 1, 1, 1)
    luna.gfx.print("Score: " .. state.score, 10, 10)
    luna.gfx.print("Level: " .. state.level, 10, 30)
    luna.gfx.print("Combo: x" .. state.combo, W / 2 - 30, 10)

    -- lives
    luna.gfx.setColor(1, 0.3, 0.3, 1)
    for i = 1, state.lives do
        luna.gfx.circle("fill", W - 20 * i, 20, 7)
    end

    -- serving prompt
    if state.serving and not state.game_over then
        luna.gfx.setColor(1, 1, 0.5, 0.7 + math.sin(luna.time.getTime() * 5) * 0.3)
        luna.gfx.print("Click or press Space to launch!", W / 2 - 100, H / 2)
    end

    -- active effects
    if state.wide_timer > 0 then
        luna.gfx.setColor(0.2, 0.6, 1, 0.8)
        luna.gfx.print("Wide: " .. math.floor(state.wide_timer) .. "s", W - 100, 40)
    end
    if state.slow_timer > 0 then
        luna.gfx.setColor(0.4, 1, 0.4, 0.8)
        luna.gfx.print("Slow: " .. math.floor(state.slow_timer) .. "s", W - 100, 55)
    end

    -- game over
    if state.game_over then
        luna.gfx.setColor(0, 0, 0, 0.6)
        luna.gfx.rectangle("fill", 0, H / 2 - 40, W, 80)
        luna.gfx.setColor(1, 0.3, 0.3, 1)
        luna.gfx.print("GAME OVER", W / 2 - 60, H / 2 - 25, 2)
        luna.gfx.setColor(1, 1, 1, 1)
        luna.gfx.print("Score: " .. state.score .. "  |  R to restart", W / 2 - 80, H / 2 + 15)
    end

    luna.gfx.setColor(0.5, 0.5, 0.5, 0.5)
    luna.gfx.print("FPS: " .. luna.time.getFPS(), W - 70, H - 20)
end
