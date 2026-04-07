-- Rhythm Game Demo — 4-lane note highway with timing windows
-- Keys: D, F, J, K to hit notes | Space to start/restart | Escape to quit

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local lanes = {
    { key = "d", x = 0, color = {1, 0.3, 0.3} },
    { key = "f", x = 0, color = {0.3, 1, 0.3} },
    { key = "j", x = 0, color = {0.3, 0.3, 1} },
    { key = "k", x = 0, color = {1, 1, 0.3} },
}

local notes = {}
local hitY = 0
local laneWidth = 80
local noteHeight = 20
local scrollSpeed = 350
local bpm = 120
local beatInterval = 60 / bpm

local score = 0
local combo = 0
local maxCombo = 0
local totalNotes = 0
local hitNotes = 0
local perfectHits = 0
local goodHits = 0
local misses = 0

local started = false
local gameTime = 0
local nextBeat = 0
local songLength = 30

local flashes = {}
local feedbacks = {}

local function resetGame()
    notes = {}
    score = 0
    combo = 0
    maxCombo = 0
    totalNotes = 0
    hitNotes = 0
    perfectHits = 0
    goodHits = 0
    misses = 0
    gameTime = 0
    nextBeat = 0
    flashes = {}
    feedbacks = {}
    started = true
end

local function spawnNote(laneIdx, time)
    table.insert(notes, { lane = laneIdx, spawnTime = time, y = -noteHeight, hit = false, missed = false })
    totalNotes = totalNotes + 1
end

local function generateBeat(time)
    local base = math.sin(time * 1.7) * 0.5 + 0.5
    for i = 1, 4 do
        local threshold = 0.3 + math.sin(time * 0.9 + i * 1.5) * 0.25
        if base > threshold then
            spawnNote(i, time)
        end
    end
end

local function addFlash(laneIdx, r, g, b)
    table.insert(flashes, { lane = laneIdx, alpha = 1.0, r = r, g = g, b = b })
end

local function addFeedback(x, text, r, g, b)
    table.insert(feedbacks, { x = x, y = hitY - 40, text = text, alpha = 1.5, r = r, g = g, b = b })
end

function luna.load()
    luna.window.setTitle("Rhythm Game")
    luna.graphics.setBackgroundColor(0.08, 0.08, 0.12)
    local screenW = 800
    local totalWidth = #lanes * laneWidth
    local startX = (screenW - totalWidth) / 2
    for i, lane in ipairs(lanes) do
        lane.x = startX + (i - 1) * laneWidth
    end
    hitY = 520
end

function luna.update(dt)
    if not started then return end
    gameTime = gameTime + dt

    -- generate beats
    while nextBeat <= gameTime do
        generateBeat(nextBeat)
        nextBeat = nextBeat + beatInterval
    end

    -- move notes
    for i = #notes, 1, -1 do
        local n = notes[i]
        local elapsed = gameTime - n.spawnTime
        n.y = elapsed * scrollSpeed - 200
        -- miss detection
        if not n.hit and not n.missed and n.y > hitY + 60 then
            n.missed = true
            misses = misses + 1
            combo = 0
        end
        -- remove off-screen
        if n.y > 650 then
            table.remove(notes, i)
        end
    end

    -- update flashes
    for i = #flashes, 1, -1 do
        flashes[i].alpha = flashes[i].alpha - dt * 4
        if flashes[i].alpha <= 0 then table.remove(flashes, i) end
    end

    -- update feedbacks
    for i = #feedbacks, 1, -1 do
        local fb = feedbacks[i]
        fb.y = fb.y - dt * 60
        fb.alpha = fb.alpha - dt
        if fb.alpha <= 0 then table.remove(feedbacks, i) end
    end

    -- end song
    if gameTime > songLength then
        started = false
    end
end

local function tryHit(laneIdx)
    if not started then return end
    local bestNote = nil
    local bestDist = 999
    for _, n in ipairs(notes) do
        if n.lane == laneIdx and not n.hit and not n.missed then
            local dist = math.abs(n.y - hitY)
            if dist < bestDist then
                bestDist = dist
                bestNote = n
            end
        end
    end
    local c = lanes[laneIdx].color
    if bestNote and bestDist < 80 then
        bestNote.hit = true
        hitNotes = hitNotes + 1
        combo = combo + 1
        if combo > maxCombo then maxCombo = combo end
        local multiplier = clamp(math.floor(combo / 10) + 1, 1, 4)
        if bestDist < 25 then
            score = score + 300 * multiplier
            perfectHits = perfectHits + 1
            addFeedback(lanes[laneIdx].x + laneWidth / 2, "PERFECT", 1, 1, 0)
        elseif bestDist < 50 then
            score = score + 100 * multiplier
            goodHits = goodHits + 1
            addFeedback(lanes[laneIdx].x + laneWidth / 2, "GOOD", 0.3, 1, 0.3)
        else
            score = score + 50 * multiplier
            goodHits = goodHits + 1
            addFeedback(lanes[laneIdx].x + laneWidth / 2, "OK", 0.6, 0.6, 0.6)
        end
        addFlash(laneIdx, c[1], c[2], c[3])
    else
        combo = 0
        addFeedback(lanes[laneIdx].x + laneWidth / 2, "MISS", 1, 0.2, 0.2)
    end
end

function luna.draw()
    -- draw lanes
    for i, lane in ipairs(lanes) do
        luna.graphics.setColor(0.15, 0.15, 0.2, 1)
        luna.graphics.rectangle("fill", lane.x, 0, laneWidth, 600)
        luna.graphics.setColor(0.25, 0.25, 0.35, 1)
        luna.graphics.rectangle("line", lane.x, 0, laneWidth, 600)
    end

    -- hit zone
    luna.graphics.setColor(1, 1, 1, 0.3)
    for _, lane in ipairs(lanes) do
        luna.graphics.rectangle("fill", lane.x, hitY - 10, laneWidth, noteHeight + 20)
    end

    -- draw flashes
    for _, fl in ipairs(flashes) do
        local a = clamp(fl.alpha, 0, 1)
        luna.graphics.setColor(fl.r, fl.g, fl.b, a * 0.5)
        luna.graphics.rectangle("fill", lanes[fl.lane].x, 0, laneWidth, 600)
    end

    -- draw notes
    for _, n in ipairs(notes) do
        if not n.hit then
            local c = lanes[n.lane].color
            if n.missed then
                luna.graphics.setColor(0.3, 0.3, 0.3, 0.5)
            else
                luna.graphics.setColor(c[1], c[2], c[3], 1)
            end
            luna.graphics.rectangle("fill", lanes[n.lane].x + 4, n.y, laneWidth - 8, noteHeight)
        end
    end

    -- key labels
    luna.graphics.setColor(1, 1, 1, 0.8)
    for i, lane in ipairs(lanes) do
        luna.graphics.print(string.upper(lane.key), lane.x + laneWidth / 2 - 6, hitY + 30)
    end

    -- feedbacks
    for _, fb in ipairs(feedbacks) do
        local a = clamp(fb.alpha, 0, 1)
        luna.graphics.setColor(fb.r, fb.g, fb.b, a)
        luna.graphics.print(fb.text, fb.x - 20, fb.y)
    end

    -- HUD
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("SCORE: " .. score, 10, 10)
    luna.graphics.print("COMBO: " .. combo, 10, 30)
    local mult = clamp(math.floor(combo / 10) + 1, 1, 4)
    luna.graphics.print("x" .. mult, 10, 50)
    luna.graphics.print("BPM: " .. bpm, 680, 10)
    local accuracy = 0
    if totalNotes > 0 then
        accuracy = math.floor((hitNotes / totalNotes) * 100)
    end
    luna.graphics.print("ACC: " .. accuracy .. "%", 680, 30)
    luna.graphics.print("FPS: " .. luna.timer.getFPS(), 680, 50)

    if not started then
        luna.graphics.setColor(0, 0, 0, 0.7)
        luna.graphics.rectangle("fill", 200, 220, 400, 180)
        luna.graphics.setColor(1, 1, 1, 1)
        if gameTime > 0 then
            luna.graphics.print("SONG COMPLETE!", 310, 240, 1.5)
            luna.graphics.print("Score: " .. score, 320, 280)
            luna.graphics.print("Perfect: " .. perfectHits .. "  Good: " .. goodHits .. "  Miss: " .. misses, 260, 310)
            luna.graphics.print("Max Combo: " .. maxCombo, 320, 340)
        end
        luna.graphics.print("[SPACE] to " .. (gameTime > 0 and "restart" or "start"), 310, 370)
    end
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    if key == "space" then resetGame() return end
    for i, lane in ipairs(lanes) do
        if key == lane.key then tryHit(i) end
    end
end
