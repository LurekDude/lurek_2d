local Player = {}
Player.__index = Player

local SPEED = 160
local JUMP_VEL = -420
local GRAVITY = 900
local FLOOR_Y = 500

function Player.new(x, y)
    return setmetatable({
        x = x, y = y,
        vx = 0, vy = 0,
        grounded = false,
        width = 32, height = 48,
    }, Player)
end

function Player:update(dt)
    -- Horizontal
    self.vx = 0
    if luna.input.isDown("left") or luna.input.isDown("a") then self.vx = -SPEED end
    if luna.input.isDown("right") or luna.input.isDown("d") then self.vx = SPEED end
    self.x = self.x + self.vx * dt

    -- Gravity
    self.vy = self.vy + GRAVITY * dt
    self.y = self.y + self.vy * dt

    -- Floor
    if self.y >= FLOOR_Y then
        self.y = FLOOR_Y
        self.vy = 0
        self.grounded = true
    end
end

function Player:keypressed(key)
    if (key == "space" or key == "up" or key == "w") and self.grounded then
        self.vy = JUMP_VEL
        self.grounded = false
    end
end

function Player:draw()
    luna.graphics.setColor(0.2, 0.8, 0.3, 1)
    luna.graphics.rectangle("fill", self.x, self.y - self.height, self.width, self.height)
    luna.graphics.setColor(1, 1, 1, 1)
end

return Player
