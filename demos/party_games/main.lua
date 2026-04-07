-- Party Games — Luna2D Demo
-- Menu selects mini-game, M returns to menu

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local state = "menu" -- "menu","quickdraw","memory","dodge","scores"
local totalScore = 0
local gameScores = { 0, 0, 0 }
local gameNames = { "Quick Draw", "Memory Match", "Dodge Ball" }

-- Quick Draw
local qd = {}
local function qdReset()
    qd = { phase = "wait", timer = math.random() * 2 + 1.5, result = "", reactionTime = 0, startTime = 0, roundScore = 0 }
end

-- Memory Match
local mm = {}
local function mmReset()
    local colors = { {1,0.2,0.2}, {0.2,0.8,0.2}, {0.2,0.3,1}, {1,0.8,0.1}, {0.8,0.2,0.8}, {0.2,0.8,0.8}, {1,0.5,0.2}, {0.6,0.6,0.6} }
    local cards = {}
    for i = 1, 8 do
        cards[#cards + 1] = { color = colors[i], matched = false, revealed = false, id = i }
        cards[#cards + 1] = { color = colors[i], matched = false, revealed = false, id = i }
    end
    -- shuffle
    for i = #cards, 2, -1 do
        local j = math.random(1, i)
        cards[i], cards[j] = cards[j], cards[i]
    end
    mm = { cards = cards, first = nil, second = nil, checkTimer = 0, pairs = 0, moves = 0, done = false }
end

-- Dodge Ball
local db = {}
local function dbReset()
    db = { px = 400, balls = {}, timer = 30, spawnCD = 0, alive = true, dodged = 0 }
end

function luna.load()
    luna.window.setTitle("Party Games")
    luna.graphics.setBackgroundColor(0.08, 0.08, 0.15)
end

function luna.update(dt)
    if state == "quickdraw" then
        if qd.phase == "wait" then
            qd.timer = qd.timer - dt
            if qd.timer <= 0 then
                qd.phase = "go"
                qd.startTime = luna.timer.getTime()
            end
        elseif qd.phase == "done" then
            qd.timer = qd.timer - dt
            if qd.timer <= 0 then state = "scores" end
        end

    elseif state == "memory" then
        if mm.checkTimer > 0 then
            mm.checkTimer = mm.checkTimer - dt
            if mm.checkTimer <= 0 then
                if mm.first and mm.second then
                    if mm.cards[mm.first].id == mm.cards[mm.second].id then
                        mm.cards[mm.first].matched = true
                        mm.cards[mm.second].matched = true
                        mm.pairs = mm.pairs + 1
                        if mm.pairs == 8 then
                            mm.done = true
                            local sc = clamp(200 - mm.moves * 5, 10, 200)
                            gameScores[2] = gameScores[2] + sc
                        end
                    else
                        mm.cards[mm.first].revealed = false
                        mm.cards[mm.second].revealed = false
                    end
                    mm.first, mm.second = nil, nil
                end
            end
        end

    elseif state == "dodge" then
        if db.alive then
            db.timer = db.timer - dt
            if luna.keyboard.isDown("left") then db.px = db.px - 400 * dt end
            if luna.keyboard.isDown("right") then db.px = db.px + 400 * dt end
            db.px = clamp(db.px, 20, 780)

            db.spawnCD = db.spawnCD - dt
            if db.spawnCD <= 0 then
                table.insert(db.balls, { x = math.random(20, 780), y = -15, r = 10, speed = math.random(200, 400) })
                db.spawnCD = clamp(0.5 - db.dodged * 0.01, 0.1, 0.5)
            end

            for i = #db.balls, 1, -1 do
                local b = db.balls[i]
                b.y = b.y + b.speed * dt
                if b.y > 600 then
                    table.remove(db.balls, i)
                    db.dodged = db.dodged + 1
                else
                    local dx = b.x - db.px
                    local dy = b.y - 560
                    if math.sqrt(dx * dx + dy * dy) < b.r + 14 then
                        db.alive = false
                        gameScores[3] = gameScores[3] + db.dodged * 2
                    end
                end
            end
            if db.timer <= 0 then
                db.alive = false
                gameScores[3] = gameScores[3] + db.dodged * 2 + 50
            end
        end
    end
end

function luna.draw()
    if state == "menu" then
        luna.graphics.setColor(1, 0.85, 0.3, 1)
        luna.graphics.print("PARTY GAMES", 300, 60, 1.8)
        for i, name in ipairs(gameNames) do
            luna.graphics.setColor(0.4, 0.6, 1, 1)
            luna.graphics.rectangle("fill", 280, 140 + i * 70, 240, 50)
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print(i .. ") " .. name, 310, 155 + i * 70, 1.2)
        end
        luna.graphics.setColor(0.7, 0.7, 0.7, 1)
        luna.graphics.print("Total Score: " .. totalScore, 310, 500)

    elseif state == "quickdraw" then
        if qd.phase == "wait" then
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print("Wait for GREEN...", 290, 280, 1.3)
            luna.graphics.setColor(0.8, 0.2, 0.2, 1)
            luna.graphics.circle("fill", 400, 200, 60)
        elseif qd.phase == "go" then
            luna.graphics.setColor(0.1, 0.9, 0.1, 1)
            luna.graphics.circle("fill", 400, 200, 60)
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print("PRESS SPACE NOW!", 280, 300, 1.5)
        elseif qd.phase == "done" then
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print(qd.result, 260, 250, 1.2)
            luna.graphics.print("Score: +" .. qd.roundScore, 330, 300)
        elseif qd.phase == "early" then
            luna.graphics.setColor(1, 0.3, 0.3, 1)
            luna.graphics.print("TOO EARLY! Press Space to retry", 230, 280, 1.1)
        end

    elseif state == "memory" then
        local cols = 4
        for i, c in ipairs(mm.cards) do
            local cx = ((i - 1) % cols) * 90 + 220
            local cy = math.floor((i - 1) / cols) * 90 + 100
            if c.matched then
                luna.graphics.setColor(0.15, 0.15, 0.15, 1)
            elseif c.revealed then
                luna.graphics.setColor(c.color[1], c.color[2], c.color[3], 1)
            else
                luna.graphics.setColor(0.35, 0.35, 0.5, 1)
            end
            luna.graphics.rectangle("fill", cx, cy, 75, 75)
        end
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("Moves: " .. mm.moves .. "  Pairs: " .. mm.pairs .. "/8", 10, 10)
        if mm.done then
            luna.graphics.setColor(0, 1, 0.4, 1)
            luna.graphics.print("COMPLETE! Press M for menu", 260, 520)
        end

    elseif state == "dodge" then
        -- player
        luna.graphics.setColor(0.2, 0.7, 1, 1)
        luna.graphics.circle("fill", db.px, 560, 14)
        -- balls
        luna.graphics.setColor(1, 0.3, 0.2, 1)
        for _, b in ipairs(db.balls) do
            luna.graphics.circle("fill", b.x, b.y, b.r)
        end
        -- HUD
        luna.graphics.setColor(1, 1, 1, 1)
        luna.graphics.print("Time: " .. math.floor(db.timer) .. "  Dodged: " .. db.dodged, 10, 10)
        if not db.alive then
            luna.graphics.setColor(1, 0.3, 0.3, 1)
            luna.graphics.print(db.timer <= 0 and "TIME UP!" or "HIT!", 360, 300, 1.5)
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print("Press M for menu", 320, 350)
        end

    elseif state == "scores" then
        luna.graphics.setColor(1, 0.9, 0.3, 1)
        luna.graphics.print("SCOREBOARD", 310, 80, 1.5)
        for i, name in ipairs(gameNames) do
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print(name .. ": " .. gameScores[i], 280, 140 + i * 40)
        end
        totalScore = gameScores[1] + gameScores[2] + gameScores[3]
        luna.graphics.setColor(0.3, 1, 0.5, 1)
        luna.graphics.print("Total: " .. totalScore, 320, 360, 1.3)
        luna.graphics.setColor(0.7, 0.7, 0.7, 1)
        luna.graphics.print("Press M for menu", 310, 440)
    end

    -- global nav
    luna.graphics.setColor(0.5, 0.5, 0.5, 1)
    luna.graphics.print("M=Menu  ESC=Quit", 600, 580)
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "m" then state = "menu"; return end

    if state == "menu" then
        if key == "1" then state = "quickdraw"; qdReset() end
        if key == "2" then state = "memory"; mmReset() end
        if key == "3" then state = "dodge"; dbReset() end
    elseif state == "quickdraw" then
        if key == "space" then
            if qd.phase == "wait" then
                qd.phase = "early"
            elseif qd.phase == "go" then
                qd.reactionTime = luna.timer.getTime() - qd.startTime
                local ms = math.floor(qd.reactionTime * 1000)
                qd.roundScore = clamp(300 - ms, 10, 300)
                qd.result = "Reaction: " .. ms .. "ms"
                gameScores[1] = gameScores[1] + qd.roundScore
                qd.phase = "done"
                qd.timer = 2
            elseif qd.phase == "early" then
                qdReset()
            end
        end
    elseif state == "scores" then
        if key == "space" then state = "menu" end
    end
end

function luna.mousepressed(x, y, button)
    if state == "memory" and not mm.done and mm.checkTimer <= 0 then
        local cols = 4
        for i, c in ipairs(mm.cards) do
            local cx = ((i - 1) % cols) * 90 + 220
            local cy = math.floor((i - 1) / cols) * 90 + 100
            if x >= cx and x <= cx + 75 and y >= cy and y <= cy + 75 then
                if not c.matched and not c.revealed then
                    c.revealed = true
                    if mm.first == nil then
                        mm.first = i
                    elseif mm.second == nil and i ~= mm.first then
                        mm.second = i
                        mm.moves = mm.moves + 1
                        mm.checkTimer = 0.6
                    end
                end
                return
            end
        end
    end
end
