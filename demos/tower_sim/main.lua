-- Tower Sim — Idle Stacking Tower
-- Time your clicks to stack blocks; misaligned blocks get trimmed

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end
local function lerp(a, b, t) return a + (b - a) * t end

local blocks = {}
local pendingBlock = nil
local score = 0
local highScore = 0
local combo = 0
local bestCombo = 0
local gameOver = false
local scrollY = 0
local BLOCK_H = 25
local BASE_W = 200
local BASE_X = 300
local BASE_Y = 540
local swingSpeed = 150
local swingDir = 1
local swingX = 0
local PERFECT_THRESHOLD = 4

local skyColors = {
    {0.4, 0.6, 0.9},   -- sky blue (floors 0-9)
    {0.6, 0.4, 0.8},   -- purple (10-19)
    {0.2, 0.2, 0.4},   -- twilight (20-29)
    {0.1, 0.1, 0.2},   -- night (30-39)
    {0.05, 0.02, 0.15}, -- space (40+)
}

local function getSkyColor()
    local tier = math.floor(score / 10) + 1
    if tier > #skyColors then tier = #skyColors end
    return skyColors[tier]
end

local function getBlockColor(idx)
    local h = (idx * 0.07) % 1
    -- HSV to RGB (simplified)
    local r, g, b
    local s, v = 0.7, 0.85
    local c = v * s
    local x = c * (1 - math.abs((h * 6) % 2 - 1))
    local m = v - c
    if h < 1/6 then     r, g, b = c, x, 0
    elseif h < 2/6 then r, g, b = x, c, 0
    elseif h < 3/6 then r, g, b = 0, c, x
    elseif h < 4/6 then r, g, b = 0, x, c
    elseif h < 5/6 then r, g, b = x, 0, c
    else                 r, g, b = c, 0, x end
    return r + m, g + m, b + m
end

local function spawnPending()
    local prevW = BASE_W
    if #blocks > 0 then
        prevW = blocks[#blocks].w
    end
    swingX = -200
    swingDir = 1
    -- Speed increases with height
    swingSpeed = 150 + score * 8
    if swingSpeed > 500 then swingSpeed = 500 end
    pendingBlock = {
        w = prevW,
        placed = false,
    }
end

local function placeBlock()
    if not pendingBlock or gameOver then return end

    local prevX, prevW
    if #blocks == 0 then
        prevX = BASE_X
        prevW = BASE_W
    else
        prevX = blocks[#blocks].x
        prevW = blocks[#blocks].w
    end

    local newX = swingX + 400 - pendingBlock.w / 2
    -- Calculate overlap
    local left = clamp(newX, prevX, prevX + prevW)
    local right = clamp(newX + pendingBlock.w, prevX, prevX + prevW)
    local overlapW = right - left

    if overlapW <= 0 then
        -- No overlap — game over
        gameOver = true
        if score > highScore then highScore = score end
        if combo > bestCombo then bestCombo = combo end
        pendingBlock = nil
        return
    end

    local offset = math.abs((newX + pendingBlock.w / 2) - (prevX + prevW / 2))
    local isPerfect = offset <= PERFECT_THRESHOLD

    if isPerfect then
        -- Perfect placement: keep full width, snap to center
        overlapW = pendingBlock.w
        left = prevX + prevW / 2 - overlapW / 2
        combo = combo + 1
    else
        combo = 0
    end

    table.insert(blocks, {
        x = left,
        w = overlapW,
        perfect = isPerfect,
    })

    score = score + 1
    if combo > bestCombo then bestCombo = combo end

    -- Scroll camera up
    local targetScroll = (#blocks - 12) * BLOCK_H
    if targetScroll > scrollY then scrollY = targetScroll end

    spawnPending()
end

local function drawStars()
    if score < 20 then return end
    local t = luna.timer.getTime()
    for i = 1, 40 do
        local sx = (i * 137 + math.floor(t * 10)) % 800
        local sy = (i * 91) % 300
        local brightness = 0.3 + 0.3 * math.sin(t * 2 + i)
        luna.graphics.setColor(1, 1, 1, brightness)
        luna.graphics.circle("fill", sx, sy, 1)
    end
end

function luna.load()
    spawnPending()
end

function luna.update(dt)
    if gameOver then return end
    if not pendingBlock then return end

    -- Swing the pending block
    swingX = swingX + swingDir * swingSpeed * dt
    if swingX > 250 then swingDir = -1 end
    if swingX < -250 then swingDir = 1 end

    -- Smooth scroll
    local targetScroll = clamp((#blocks - 12) * BLOCK_H, 0, 99999)
    scrollY = lerp(scrollY, targetScroll, dt * 3)
end

function luna.keypressed(key)
    if key == "space" or key == "return" then
        if gameOver then
            -- Restart
            blocks = {}
            score = 0
            combo = 0
            scrollY = 0
            gameOver = false
            spawnPending()
        else
            placeBlock()
        end
    end
    if key == "escape" then luna.event.quit() end
end

function luna.mousepressed(mx, my, btn)
    if btn == 1 then
        if gameOver then
            blocks = {}
            score = 0
            combo = 0
            scrollY = 0
            gameOver = false
            spawnPending()
        else
            placeBlock()
        end
    end
end

function luna.draw()
    local sky = getSkyColor()
    luna.graphics.setBackgroundColor(sky[1], sky[2], sky[3])

    drawStars()

    -- Draw ground
    local groundY = BASE_Y + BLOCK_H - scrollY
    luna.graphics.setColor(0.3, 0.25, 0.2, 1)
    luna.graphics.rectangle("fill", 0, groundY, 800, 200)

    -- Foundation
    luna.graphics.setColor(0.5, 0.5, 0.55, 1)
    luna.graphics.rectangle("fill", BASE_X, groundY - BLOCK_H, BASE_W, BLOCK_H)

    -- Placed blocks
    for i, b in ipairs(blocks) do
        local r, g, bl = getBlockColor(i)
        luna.graphics.setColor(r, g, bl, 1)
        local by = groundY - (i + 1) * BLOCK_H
        luna.graphics.rectangle("fill", b.x, by, b.w, BLOCK_H - 1)

        -- Perfect indicator
        if b.perfect then
            luna.graphics.setColor(1, 1, 1, 0.4)
            luna.graphics.rectangle("fill", b.x, by, b.w, BLOCK_H - 1)
        end

        -- Edge outlines
        luna.graphics.setColor(r * 0.7, g * 0.7, bl * 0.7, 1)
        luna.graphics.rectangle("line", b.x, by, b.w, BLOCK_H - 1)
    end

    -- Pending block (swinging)
    if pendingBlock and not gameOver then
        local pendingIdx = #blocks + 1
        local r, g, bl = getBlockColor(pendingIdx)
        luna.graphics.setColor(r, g, bl, 0.85)
        local px = swingX + 400 - pendingBlock.w / 2
        local py = groundY - (pendingIdx + 1) * BLOCK_H
        luna.graphics.rectangle("fill", px, py, pendingBlock.w, BLOCK_H - 1)

        -- Guide line from previous block
        local prevX, prevW
        if #blocks == 0 then
            prevX, prevW = BASE_X, BASE_W
        else
            prevX, prevW = blocks[#blocks].x, blocks[#blocks].w
        end
        luna.graphics.setColor(1, 1, 1, 0.15)
        luna.graphics.setLineWidth(1)
        luna.graphics.line(prevX, py, prevX, py + BLOCK_H)
        luna.graphics.line(prevX + prevW, py, prevX + prevW, py + BLOCK_H)
    end

    -- HUD
    luna.graphics.setColor(0, 0, 0, 0.6)
    luna.graphics.rectangle("fill", 0, 0, 800, 50)

    -- Score
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("Height: " .. score, 20, 5, 1.5)

    -- High score
    luna.graphics.setColor(0.8, 0.8, 0.5, 1)
    luna.graphics.print("Best: " .. highScore, 200, 10)

    -- Combo
    if combo > 0 then
        local comboAlpha = clamp(1, 0.5, 1)
        luna.graphics.setColor(1, 0.8, 0.2, comboAlpha)
        luna.graphics.print("COMBO x" .. combo, 350, 8, 1.3)
    end

    -- Floor indicator
    local floor = math.floor(score / 10)
    local floorNames = {"Sky", "Clouds", "Twilight", "Night", "Space"}
    local fi = clamp(floor + 1, 1, #floorNames)
    luna.graphics.setColor(0.6, 0.6, 0.8, 1)
    luna.graphics.print("Zone: " .. floorNames[fi], 600, 10)
    luna.graphics.setColor(0.5, 0.5, 0.5, 1)
    luna.graphics.print("Best combo: " .. bestCombo, 600, 30)

    -- Controls hint
    luna.graphics.setColor(0.5, 0.5, 0.5, 0.8)
    luna.graphics.print("Click or Space to place block", 250, 35)

    -- Game over overlay
    if gameOver then
        luna.graphics.setColor(0, 0, 0, 0.7)
        luna.graphics.rectangle("fill", 200, 200, 400, 160)

        luna.graphics.setColor(1, 0.4, 0.3, 1)
        luna.graphics.print("GAME OVER", 310, 215, 1.8)

        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("Final Height: " .. score, 310, 270)
        luna.graphics.print("Best Combo: " .. bestCombo, 310, 295)
        if score >= highScore and score > 0 then
            luna.graphics.setColor(1, 1, 0, 1)
            luna.graphics.print("NEW HIGH SCORE!", 310, 320)
        else
            luna.graphics.setColor(0.7, 0.7, 0.7, 1)
            luna.graphics.print("Click or Space to retry", 310, 320)
        end
    end
end
