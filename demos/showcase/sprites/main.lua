-- Sprites example for Luna2D
-- Move a rectangle with arrow keys
-- Demonstrates luna.gfx.draw() polymorphic dispatch

local x, y = 400, 300
local speed = 200
local size = 40
local icon  -- Image handle created from local ImageData
local smokeMode = false
local smokeScreenshotPath = "save/sprites_smoke.png"
local smokeRequested = false
local smokeQuitNextFrame = false

local function initSmokeMode()
    local args = luna.platform.getArgs()
    local screenshotPrefix = "--smoke-screenshot="

    for i = 1, #args do
        local arg = args[i]
        if arg == "--smoke-sprites" then
            smokeMode = true
        elseif arg:sub(1, #screenshotPrefix) == screenshotPrefix then
            smokeMode = true
            smokeScreenshotPath = arg:sub(#screenshotPrefix + 1)
        end
    end
end

local function createIcon()
    local imageData = luna.img.newImageData(16, 16)

    for py = 0, 15 do
        for px = 0, 15 do
            if px == 0 or px == 15 or py == 0 or py == 15 then
                imageData:setPixel(px, py, 0, 0, 0, 0)
            elseif px == py or px + py == 15 then
                imageData:setPixel(px, py, 255, 255, 255, 255)
            elseif py < 8 then
                imageData:setPixel(px, py, 64, 160, 255, 255)
            else
                imageData:setPixel(px, py, 32, 96, 220, 255)
            end
        end
    end

    return luna.gfx.newImage(imageData)
end

function luna.init()
    initSmokeMode()
    luna.window.setTitle("Movement Demo - Luna2D")
    luna.gfx.setBackgroundColor(0.08, 0.08, 0.18)
    -- Create a small sprite image locally; luna.gfx.draw() dispatches based on type
    icon = createIcon()
end

function luna.process(dt)
    if smokeQuitNextFrame then
        luna.signal.quit()
        return
    end

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
    local w = luna.gfx.getWidth()
    local h = luna.gfx.getHeight()
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    if x > w - size then x = w - size end
    if y > h - size then y = h - size end
end

function luna.render()
    -- Trail circles
    luna.gfx.setColor(0.2, 0.3, 0.6, 0.5)
    luna.gfx.circle("fill", x + size/2, y + size/2, size)

    -- Player square
    luna.gfx.setColor(0.3, 0.8, 1.0)
    luna.gfx.rectangle("fill", x, y, size, size)

    -- Draw icon using polymorphic luna.gfx.draw(drawable, x, y)
    luna.gfx.setColor(1, 1, 1)
    if icon then
        luna.gfx.draw(icon, x + size + 4, y)
    end

    -- Outline
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.rectangle("line", x, y, size, size)

    -- Instructions
    luna.gfx.setColor(0.6, 0.6, 0.6)
    luna.gfx.print("WASD or Arrow Keys to move", 250, 20, 2)

    -- Position info
    luna.gfx.print("X:" .. tostring(math.floor(x)) .. " Y:" .. tostring(math.floor(y)), 10, 570, 2)

    if smokeMode and not smokeRequested then
        luna.gfx.saveScreenshot(smokeScreenshotPath)
        smokeRequested = true
        smokeQuitNextFrame = true
    end
end
