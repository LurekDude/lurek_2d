local Player = {}
Player.__index = Player

local SPEED = 300
local FIRE_RATE = 0.12

function Player.new(x, y)
    return setmetatable({
        x = x, y = y,
        width = 24, height = 24,
        fire_timer = 0,
    }, Player)
end

function Player:update(dt, bullets)
    if lurek.input.isDown("left")  or lurek.input.isDown("a") then self.x = self.x - SPEED * dt end
    if lurek.input.isDown("right") or lurek.input.isDown("d") then self.x = self.x + SPEED * dt end
    if lurek.input.isDown("up")    or lurek.input.isDown("w") then self.y = self.y - SPEED * dt end
    if lurek.input.isDown("down")  or lurek.input.isDown("s") then self.y = self.y + SPEED * dt end

    -- Clamp to screen
    self.x = math.max(0, math.min(480 - self.width, self.x))
    self.y = math.max(0, math.min(640 - self.height, self.y))

    -- Auto-fire
    self.fire_timer = self.fire_timer - dt
    if lurek.input.isDown("space") and self.fire_timer <= 0 then
        bullets:fire(self.x + self.width / 2, self.y, 0, -600)
        self.fire_timer = FIRE_RATE
    end
end

function Player:draw()
    lurek.render.setColor(0.2, 0.8, 1, 1)
    lurek.render.rectangle("fill", self.x, self.y, self.width, self.height)
    lurek.render.setColor(1, 1, 1, 1)
end

return Player
