-- Sprites example for Lurek2D
-- Move a rectangle with arrow keys
-- Demonstrates lurek.render.draw() polymorphic dispatch
-- Run with: cargo run -- content/demos/showcase/sprites

local x, y = 400, 300
local speed = 200
local size = 40
local icon  -- Image handle created from local ImageData
local smokeMode = false
local smokeScreenshotPath = "save/sprites_smoke.png"
local smokeRequested = false
local smokeQuitNextFrame = false

local function initSmokeMode()
    local args = lurek.platform.getArgs()
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
    local imageData = lurek.img.newImageData(16, 16)

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

    return lurek.render.newImage(imageData)
end

function lurek.init()
    initSmokeMode()
    lurek.window.setTitle("Movement Demo - Lurek2D")
    lurek.render.setBackgroundColor(0.08, 0.08, 0.18)
    -- Create a small sprite image locally; lurek.render.draw() dispatches based on type
    icon = createIcon()
end

function lurek.process(dt)
    if smokeQuitNextFrame then
        lurek.signal.quit()
        return
    end

    if lurek.keyboard.isDown("up") or lurek.keyboard.isDown("w") then
        y = y - speed * dt
    end
    if lurek.keyboard.isDown("down") or lurek.keyboard.isDown("s") then
        y = y + speed * dt
    end
    if lurek.keyboard.isDown("left") or lurek.keyboard.isDown("a") then
        x = x - speed * dt
    end
    if lurek.keyboard.isDown("right") or lurek.keyboard.isDown("d") then
        x = x + speed * dt
    end

    -- Keep in bounds
    local w = lurek.render.getWidth()
    local h = lurek.render.getHeight()
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end
    if x > w - size then x = w - size end
    if y > h - size then y = h - size end
end

function lurek.render()
    -- Trail circles
    lurek.render.setColor(0.2, 0.3, 0.6, 0.5)
    lurek.render.circle("fill", x + size/2, y + size/2, size)

    -- Player square
    lurek.render.setColor(0.3, 0.8, 1.0)
    lurek.render.rectangle("fill", x, y, size, size)

    -- Draw icon using polymorphic lurek.render.draw(drawable, x, y)
    lurek.render.setColor(1, 1, 1)
    if icon then
        lurek.render.draw(icon, x + size + 4, y)
    end

    -- Outline
    lurek.render.setColor(1, 1, 1)
    lurek.render.rectangle("line", x, y, size, size)

    -- Instructions
    lurek.render.setColor(0.6, 0.6, 0.6)
    lurek.render.print("WASD or Arrow Keys to move", 250, 20, 2)

    -- Position info
    lurek.render.print("X:" .. tostring(math.floor(x)) .. " Y:" .. tostring(math.floor(y)), 10, 570, 2)

    if smokeMode and not smokeRequested then
        lurek.render.saveScreenshot(smokeScreenshotPath)
        smokeRequested = true
        smokeQuitNextFrame = true
    end
end
