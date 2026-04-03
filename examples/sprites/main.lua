-- Sprites example for Luna2D
-- Move a rectangle with arrow keys
-- Demonstrates luna.graphics.draw() polymorphic dispatch

local x, y = 400, 300
local speed = 200
local size = 40
local icon  -- Image handle loaded via newImage

function luna.load()
    luna.window.setTitle("Movement Demo - Luna2D")
    luna.graphics.setBackgroundColor(0.08, 0.08, 0.18)
    -- Load an Image; luna.graphics.draw() dispatches based on type
    icon = luna.graphics.newImage("assets/icon.png"
    luna.window.setTitle("Movement Demo - Luna2D")
    luna.graphics.setBackgroundColor(0.08, 0.08, 0.18)
    -- Load an Image; luna.graphics.draw() dispatches based on type
    icon = luna.graphics.newImage("assets/icon.png")
end

function luna.update(dt)
    if luna.keyboard.isDown("up") or luna.keyboard.isDown("w") then
        y = y - speed * dt
    end
    if luna.keyboard.isDown("down") or luna.keyboard.isDown("s") then
        y = y + speed * dt
    end
    if luna.keyboard.isDown("left") or luna.keyboard.isDown("a") then
        x = x - speed * dt
    end
    if luna.keyboard.isDown("right") or luna.keyboard.isDown("d") then
        x = x + speed * dt
    end

    -- Keep in bounds
    local w = luna.graphics.getWidth()
    local h = luna.graphics.getHeight()
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    if x > w - size then x = w - size end
    if y > h - size then y = h - size end
end

function luna.draw()
    -- Trail circles
    luna.graphics.setColor(0.2, 0.3, 0.6, 0.5)
    luna.graphics.circle("fill", x + size/2, y + size/2, size)

    -- Player square
    luna.graphics.setColor(0.3, 0.8, 1.0)
    luna.graphics.rectangle("fill", x, y, size, size)

    -- Draw icon using polymorphic luna.graphics.draw(drawable, x, y)
    luna.graphics.setColor(1, 1, 1)
    if icon then
        luna.graphics.draw(icon, x + size + 4, y)
    end

    -- Outline
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.rectangle("line", x, y, size, size)

    -- Draw icon using polymorphic luna.graphics.draw(drawable, x, y)
    luna.graphics.setColor(1, 1, 1)
    if icon then
        luna.graphics.draw(icon, x + size + 4, y)
    end

    -- Instructions
    luna.graphics.setColor(0.6, 0.6, 0.6)
    luna.graphics.print("WASD or Arrow Keys to move", 250, 20, 2)

    -- Position info
    luna.graphics.print("X:" .. tostring(luna.math.floor(x)) .. " Y:" .. tostring(luna.math.floor(y)), 10, 570, 2)
end
