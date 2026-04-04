local M = {}

local particles = {}
local time = 0

function M.update(dt)
    time = time + dt

    -- Emit particles
    if #particles < 200 then
        local angle = math.random() * math.pi * 2
        local speed = math.random(20, 100)
        particles[#particles + 1] = {
            x = 400, y = 300,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 2 + math.random() * 2,
            age = 0,
        }
    end

    -- Update particles
    for i = #particles, 1, -1 do
        local p = particles[i]
        p.age = p.age + dt
        if p.age >= p.life then
            table.remove(particles, i)
        else
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
        end
    end
end

function M.draw()
    luna.graphics.print("Scene 3: Particles", 10, 10)
    for _, p in ipairs(particles) do
        local alpha = 1 - (p.age / p.life)
        luna.graphics.setColor(1, 0.5 + alpha * 0.5, 0.1, alpha)
        luna.graphics.circle("fill", p.x, p.y, 3)
    end
    luna.graphics.setColor(1, 1, 1, 1)
end

return M
