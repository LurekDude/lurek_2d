-- Scene Management Demo for Luna2D
-- Demonstrates a Lua-side scene state machine:
--   Title Screen -> Gameplay -> Game Over
-- Press ENTER to advance scenes, ESC to go back.

-- ── Scene system ──────────────────────────────────────────────────────────

local scenes = {}
local current_scene = nil

--- Switch to a new scene, calling its enter() if defined.
local function switch_scene(scene)
    if current_scene and current_scene.exit then
        current_scene.exit()
    end
    current_scene = scene
    if scene.enter then
        scene.enter()
    end
end

-- ── Title scene ───────────────────────────────────────────────────────────

local title = {}

function title.enter()
    luna.graphics.setBackgroundColor(0.08, 0.05, 0.18)
end

function title.update(dt)
    -- Animate a gentle pulsing effect
    title.pulse = (title.pulse or 0) + dt
end

function title.draw()
    local w = luna.graphics.getWidth()
    local h = luna.graphics.getHeight()

    -- Title text
    local pulse = luna.math.sin((title.pulse or 0) * 2) * 0.15 + 0.85
    luna.graphics.setColor(0.3 * pulse, 0.6 * pulse, 1.0 * pulse)
    luna.graphics.print("LUNA2D", w / 2 - 100, h / 3, 5)

    luna.graphics.setColor(0.7, 0.7, 0.7)
    luna.graphics.print("Scene Management Demo", w / 2 - 120, h / 3 + 70, 2)

    -- Instructions
    luna.graphics.setColor(0.5, 0.5, 0.5)
    luna.graphics.print("Press ENTER to start", w / 2 - 100, h * 0.7, 2)
end

function title.keypressed(key)
    if key == "return" then
        switch_scene(scenes.gameplay)
    end
end

-- ── Gameplay scene ────────────────────────────────────────────────────────

local gameplay = {}
local player = { x = 400, y = 300, speed = 200, score = 0 }
local coins = {}

function gameplay.enter()
    luna.graphics.setBackgroundColor(0.05, 0.1, 0.05)
    player.x = 400
    player.y = 300
    player.score = 0
    coins = {}
    for i = 1, 5 do
        coins[i] = {
            x = luna.math.random(50, 750),
            y = luna.math.random(50, 550),
            collected = false,
        }
    end
end

function gameplay.update(dt)
    -- Player movement
    if luna.keyboard.isDown("up") or luna.keyboard.isDown("w") then
        player.y = player.y - player.speed * dt
    end
    if luna.keyboard.isDown("down") or luna.keyboard.isDown("s") then
        player.y = player.y + player.speed * dt
    end
    if luna.keyboard.isDown("left") or luna.keyboard.isDown("a") then
        player.x = player.x - player.speed * dt
    end
    if luna.keyboard.isDown("right") or luna.keyboard.isDown("d") then
        player.x = player.x + player.speed * dt
    end

    -- Clamp to bounds
    player.x = luna.math.clamp(player.x, 20, 780)
    player.y = luna.math.clamp(player.y, 20, 580)

    -- Coin collection
    for _, coin in ipairs(coins) do
        if not coin.collected then
            local dist = luna.math.distance(player.x, player.y, coin.x, coin.y)
            if dist < 25 then
                coin.collected = true
                player.score = player.score + 1
            end
        end
    end

    -- Win condition
    if player.score >= 5 then
        switch_scene(scenes.gameover)
    end
end

function gameplay.draw()
    -- Draw coins
    for _, coin in ipairs(coins) do
        if not coin.collected then
            luna.graphics.setColor(1.0, 0.85, 0.0)
            luna.graphics.circle("fill", coin.x, coin.y, 10)
            luna.graphics.setColor(0.8, 0.65, 0.0)
            luna.graphics.circle("line", coin.x, coin.y, 10)
        end
    end

    -- Draw player
    luna.graphics.setColor(0.3, 0.8, 1.0)
    luna.graphics.rectangle("fill", player.x - 15, player.y - 15, 30, 30)

    -- HUD
    luna.graphics.setColor(1, 1, 1)
    luna.graphics.print("Score: " .. tostring(player.score) .. " / 5", 10, 10, 2)
    luna.graphics.setColor(0.5, 0.5, 0.5)
    luna.graphics.print("WASD to move | ESC for title", 10, 570, 1.5)
end

function gameplay.keypressed(key)
    if key == "escape" then
        switch_scene(scenes.title)
    end
end

-- ── Game Over scene ──────────────────────────────────────────────────────

local gameover = {}

function gameover.enter()
    luna.graphics.setBackgroundColor(0.15, 0.05, 0.05)
    gameover.timer = 0
end

function gameover.update(dt)
    gameover.timer = (gameover.timer or 0) + dt
end

function gameover.draw()
    local w = luna.graphics.getWidth()
    local h = luna.graphics.getHeight()

    luna.graphics.setColor(0.2, 1.0, 0.3)
    luna.graphics.print("YOU WIN!", w / 2 - 80, h / 3, 4)

    luna.graphics.setColor(0.7, 0.7, 0.7)
    luna.graphics.print("All coins collected!", w / 2 - 100, h / 3 + 60, 2)

    luna.graphics.setColor(0.5, 0.5, 0.5)
    luna.graphics.print("Press ENTER to play again", w / 2 - 120, h * 0.7, 2)
    luna.graphics.print("Press ESC to return to title", w / 2 - 130, h * 0.7 + 30, 2)
end

function gameover.keypressed(key)
    if key == "return" then
        switch_scene(scenes.gameplay)
    elseif key == "escape" then
        switch_scene(scenes.title)
    end
end

-- ── Register scenes ──────────────────────────────────────────────────────

scenes.title = title
scenes.gameplay = gameplay
scenes.gameover = gameover

-- ── Luna2D callbacks ─────────────────────────────────────────────────────

function luna.load()
    luna.window.setTitle("Scene Demo - Luna2D")
    switch_scene(scenes.title)
end

function luna.update(dt)
    if current_scene and current_scene.update then
        current_scene.update(dt)
    end
end

function luna.draw()
    if current_scene and current_scene.draw then
        current_scene.draw()
    end
end

function luna.keypressed(key)
    if current_scene and current_scene.keypressed then
        current_scene.keypressed(key)
    end
end
