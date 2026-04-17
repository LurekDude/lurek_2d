-- Physics Puzzle Demo -- drop shapes to guide a ball to the goal
-- Click to place shapes | 1/2: toggle circle/rect | R: reset | Escape: quit
-- Run with: cargo run -- content/demos/strategy/physics_puzzle

local world = nil
local ball = nil
local ballBody = nil
local goal = { x = 650, y = 500, w = 80, h = 40 }
local placedPieces = {}
local staticBodies = {}
local maxPieces = 8
local placeMode = "circle" -- "circle" or "rect"
local placeRadius = 20
local placeW, placeH = 60, 16
local won = false
local level = 1
local message = ""
local messageTimer = 0

local levels = {
    { ballX = 100, ballY = 80, goalX = 650, goalY = 500, platforms = {
        { x = 0, y = 590, w = 800, h = 20 },
        { x = 300, y = 350, w = 150, h = 12 },
    }},
    { ballX = 400, ballY = 60, goalX = 150, goalY = 500, platforms = {
        { x = 0, y = 590, w = 800, h = 20 },
        { x = 500, y = 250, w = 120, h = 12 },
        { x = 200, y = 400, w = 100, h = 12 },
    }},
    { ballX = 700, ballY = 50, goalX = 80, goalY = 500, platforms = {
        { x = 0, y = 590, w = 800, h = 20 },
        { x = 400, y = 200, w = 180, h = 12 },
        { x = 100, y = 350, w = 140, h = 12 },
        { x = 550, y = 450, w = 100, h = 12 },
    }},
}

local function loadLevel(idx)
    if idx > #levels then idx = 1 end
    level = idx
    won = false
    placedPieces = {}
    staticBodies = {}

    local lv = levels[level]
    goal.x, goal.y = lv.goalX, lv.goalY

    world = lurek.physics.newWorld(0, 400)

    -- ball
    ballBody = world:newCircleBody(lv.ballX, lv.ballY, 12, "dynamic")
    ballBody:setRestitution(0.5)

    -- platforms
    for _, p in ipairs(lv.platforms) do
        local b = world:newBody(p.x + p.w / 2, p.y + p.h / 2, "static")
        world:addFixture(b:getId(), "rectangle", 1, 0.3, 0, false, p.w, p.h)
        table.insert(staticBodies, { body = b, x = p.x, y = p.y, w = p.w, h = p.h })
    end

    message = "Level " .. level .. " -- Get the ball to the green goal!"
    messageTimer = 3
end

function lurek.init()
    lurek.window.setTitle("Physics Puzzle")
    lurek.render.setBackgroundColor(0.12, 0.12, 0.18)
    loadLevel(1)
end

local function placePiece(mx, my)
    if won then return end
    if #placedPieces >= maxPieces then
        message = "No pieces left! Press R to reset."
        messageTimer = 2
        return
    end
    local piece = { mode = placeMode, x = mx, y = my }
    local b
    if placeMode == "circle" then
        b = world:newCircleBody(mx, my, placeRadius, "static")
        b:setRestitution(0.3)
        piece.r = placeRadius
    else
        b = world:newBody(mx, my, "static")
        world:addFixture(b:getId(), "rectangle", 1, 0.3, 0, false, placeW, placeH)
        b:setRestitution(0.3)
        piece.w, piece.h = placeW, placeH
    end
    piece.body = b
    table.insert(placedPieces, piece)
end

function lurek.process(dt)
    if won then return end

    world:step(dt)

    local bx, by = ballBody:getPosition()

    -- check goal
    if bx > goal.x and bx < goal.x + goal.w and by > goal.y and by < goal.y + goal.h then
        won = true
        message = "Level " .. level .. " Complete! Press N for next level."
        messageTimer = 99
    end

    -- ball fell off screen
    if by > 650 then
        loadLevel(level)
        message = "Ball fell! Try again."
        messageTimer = 2
    end

    if messageTimer > 0 then
        messageTimer = messageTimer - dt
    end
end

function lurek.render()
    -- goal zone
    lurek.render.setColor(0.2, 0.8, 0.2, 0.4)
    lurek.render.rectangle("fill", goal.x, goal.y, goal.w, goal.h)
    lurek.render.setColor(0.2, 1, 0.2, 1)
    lurek.render.rectangle("line", goal.x, goal.y, goal.w, goal.h)
    lurek.render.print("GOAL", goal.x + 14, goal.y + 12)

    -- static platforms
    for _, s in ipairs(staticBodies) do
        lurek.render.setColor(0.5, 0.45, 0.4, 1)
        lurek.render.rectangle("fill", s.x, s.y, s.w, s.h)
    end

    -- placed pieces
    for _, p in ipairs(placedPieces) do
        lurek.render.setColor(0.3, 0.5, 0.8, 0.9)
        if p.mode == "circle" then
            lurek.render.circle("fill", p.x, p.y, p.r)
            lurek.render.setColor(0.4, 0.6, 1, 1)
            lurek.render.circle("line", p.x, p.y, p.r)
        else
            lurek.render.rectangle("fill", p.x - p.w / 2, p.y - p.h / 2, p.w, p.h)
            lurek.render.setColor(0.4, 0.6, 1, 1)
            lurek.render.rectangle("line", p.x - p.w / 2, p.y - p.h / 2, p.w, p.h)
        end
    end

    -- ball
    local bx, by = ballBody:getPosition()
    lurek.render.setColor(1, 0.4, 0.2, 1)
    lurek.render.circle("fill", bx, by, 12)
    lurek.render.setColor(1, 0.6, 0.3, 1)
    lurek.render.circle("line", bx, by, 12)

    -- cursor preview
    if not won then
        local mx, my = lurek.mouse.getPosition()
        lurek.render.setColor(0.3, 0.5, 0.8, 0.3)
        if placeMode == "circle" then
            lurek.render.circle("line", mx, my, placeRadius)
        else
            lurek.render.rectangle("line", mx - placeW / 2, my - placeH / 2, placeW, placeH)
        end
    end

    -- HUD
    lurek.render.setColor(1, 1, 1, 1)
    lurek.render.print("Level: " .. level, 10, 10)
    lurek.render.print("Pieces: " .. (maxPieces - #placedPieces) .. "/" .. maxPieces, 10, 30)
    lurek.render.print("Mode: " .. placeMode .. "  [1] Circle  [2] Rect", 10, 50)
    lurek.render.print("Click to place | R: Reset | N: Next level", 10, 575)

    -- message
    if messageTimer > 0 then
        lurek.render.setColor(0, 0, 0, 0.6)
        lurek.render.rectangle("fill", 200, 270, 400, 40)
        lurek.render.setColor(1, 1, 0.5, 1)
        lurek.render.print(message, 220, 280)
    end

    -- won overlay
    if won then
        lurek.render.setColor(0, 0, 0, 0.5)
        lurek.render.rectangle("fill", 250, 240, 300, 80)
        lurek.render.setColor(0.2, 1, 0.4, 1)
        lurek.render.print("LEVEL COMPLETE!", 310, 255, 1.3)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print("Press N for next level", 315, 290)
    end
end

function lurek.mousepressed(x, y, button)
    if button == 1 then placePiece(x, y) end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then loadLevel(level) end
    if key == "n" then loadLevel(level + 1) end
    if key == "1" then placeMode = "circle" end
    if key == "2" then placeMode = "rect" end
end
