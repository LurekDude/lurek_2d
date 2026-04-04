local score = 0
local lives = 3
local state = "playing"

local ball = { x = 400, y = 300, vx = 200, vy = 150, r = 8 }
local paddle = { x = 350, y = 560, w = 100, h = 12 }

function luna.load()
    -- Ready to play
end

function luna.update(dt)
    if state ~= "playing" then return end

    -- Move paddle
    if luna.input.isDown("left")  or luna.input.isDown("a") then paddle.x = paddle.x - 400 * dt end
    if luna.input.isDown("right") or luna.input.isDown("d") then paddle.x = paddle.x + 400 * dt end
    paddle.x = math.max(0, math.min(800 - paddle.w, paddle.x))

    -- Move ball
    ball.x = ball.x + ball.vx * dt
    ball.y = ball.y + ball.vy * dt

    -- Wall bounces
    if ball.x <= ball.r or ball.x >= 800 - ball.r then ball.vx = -ball.vx end
    if ball.y <= ball.r then ball.vy = -ball.vy end

    -- Paddle bounce
    if ball.vy > 0 and ball.y + ball.r >= paddle.y and
       ball.x >= paddle.x and ball.x <= paddle.x + paddle.w then
        ball.vy = -ball.vy
        score = score + 10
    end

    -- Missed
    if ball.y > 620 then
        lives = lives - 1
        if lives <= 0 then
            state = "gameover"
        else
            ball.x, ball.y = 400, 300
            ball.vy = math.abs(ball.vy)
        end
    end
end

function luna.draw()
    luna.graphics.clear(0.05, 0.05, 0.1)

    -- Ball
    luna.graphics.setColor(1, 0.9, 0.2, 1)
    luna.graphics.circle("fill", ball.x, ball.y, ball.r)

    -- Paddle
    luna.graphics.setColor(0.2, 0.7, 1, 1)
    luna.graphics.rectangle("fill", paddle.x, paddle.y, paddle.w, paddle.h)

    -- UI
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Score: " .. score, 10, 10)
    luna.graphics.print("Lives: " .. lives, 710, 10)

    if state == "gameover" then
        luna.graphics.print("GAME OVER - Press R to restart", 260, 280)
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "r" and state == "gameover" then
        score = 0
        lives = 3
        state = "playing"
        ball.x, ball.y = 400, 300
    end
end
