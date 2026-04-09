local Camera = {}
Camera.__index = Camera

function Camera.new()
    return setmetatable({ x = 0, y = 0, speed = 8 }, Camera)
end

function Camera:follow(target, dt)
    self.x = self.x + (target.x - 400 - self.x) * self.speed * dt
    self.y = self.y + (target.y - 300 - self.y) * self.speed * dt
end

function Camera:apply()
    lurek.gfx.push()
    lurek.gfx.translate(-self.x, -self.y)
end

function Camera:reset()
    lurek.gfx.pop()
end

return Camera
