local Player = {}
Player.__index = Player

local SPEED = 120

function Player.new(x, y)
    return setmetatable({
        x = x, y = y,
        width = 24, height = 24,
        hp = 100, max_hp = 100,
        dir = "down",
    }, Player)
end

function Player:update(dt)
    local dx, dy = 0, 0
    if luna.input.isDown("left")  or luna.input.isDown("a") then dx = dx - 1 end
    if luna.input.isDown("right") or luna.input.isDown("d") then dx = dx + 1 end
    if luna.input.isDown("up")    or luna.input.isDown("w") then dy = dy - 1 end
    if luna.input.isDown("down")  or luna.input.isDown("s") then dy = dy + 1 end

    -- Normalize diagonal movement
    if dx ~= 0 and dy ~= 0 then
        local len = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / len, dy / len
    end

    self.x = self.x + dx * SPEED * dt
    self.y = self.y + dy * SPEED * dt

    -- Track facing direction
    if     dx > 0 then self.dir = "right"
    elseif dx < 0 then self.dir = "left"
    elseif dy > 0 then self.dir = "down"
    elseif dy < 0 then self.dir = "up"
    end
end

function Player:draw()
    luna.graphics.setColor(0.3, 0.6, 0.9, 1)
    luna.graphics.rectangle("fill", self.x - self.width / 2, self.y - self.height / 2, self.width, self.height)
    luna.graphics.setColor(1, 1, 1, 1)
end

return Player
