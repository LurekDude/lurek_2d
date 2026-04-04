local M = {}

local sprites = {}

function M.load()
    -- Create some moving sprites
    for i = 1, 20 do
        sprites[i] = {
            x = math.random(50, 750),
            y = math.random(50, 550),
            vx = math.random(-80, 80),
            vy = math.random(-80, 80),
            size = math.random(10, 30),
            r = math.random() * 0.5 + 0.5,
            g = math.random() * 0.5 + 0.5,
            b = math.random() * 0.5 + 0.5,
        }
    end
end

function M.update(dt)
    for _, s in ipairs(sprites) do
        s.x = s.x + s.vx * dt
        s.y = s.y + s.vy * dt
        if s.x < 0 or s.x > 800 then s.vx = -s.vx end
        if s.y < 0 or s.y > 580 then s.vy = -s.vy end
    end
end

function M.draw()
    luna.graphics.print("Scene 1: Bouncing Sprites", 10, 10)
    for _, s in ipairs(sprites) do
        luna.graphics.setColor(s.r, s.g, s.b, 1)
        luna.graphics.rectangle("fill", s.x, s.y, s.size, s.size)
    end
    luna.graphics.setColor(1, 1, 1, 1)
end

return M
