local BulletPool = {}
BulletPool.__index = BulletPool

function BulletPool.new(max)
    local pool = {}
    for i = 1, max do
        pool[i] = { active = false, x = 0, y = 0, vx = 0, vy = 0 }
    end
    return setmetatable({ pool = pool, max = max }, BulletPool)
end

function BulletPool:fire(x, y, vx, vy)
    for i = 1, self.max do
        local b = self.pool[i]
        if not b.active then
            b.active = true
            b.x, b.y = x, y
            b.vx, b.vy = vx, vy
            return
        end
    end
end

function BulletPool:update(dt)
    for i = 1, self.max do
        local b = self.pool[i]
        if b.active then
            b.x = b.x + b.vx * dt
            b.y = b.y + b.vy * dt
            if b.y < -10 or b.y > 650 or b.x < -10 or b.x > 490 then
                b.active = false
            end
        end
    end
end

function BulletPool:draw()
    luna.graphics.setColor(1, 1, 0.3, 1)
    for i = 1, self.max do
        local b = self.pool[i]
        if b.active then
            luna.graphics.rectangle("fill", b.x - 2, b.y - 4, 4, 8)
        end
    end
    luna.graphics.setColor(1, 1, 1, 1)
end

return BulletPool
