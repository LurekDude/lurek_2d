-- Frogger — Classic Arcade (Lurek2D demo)
-- Guide the frog across a busy road and floating river logs to reach the lily pads.
-- WASD or Arrow keys to hop. One hit = one life lost.
-- Run with: cargo run -- content/demos/arcade/frogger

-- ── Constants ────────────────────────────────────────────────────────────

local W, H = 800, 600
local CELL = 50
local COLS = W / CELL     -- 16 columns
local ROWS = H / CELL     -- 12 rows
local HOME_SLOTS = 5
local NUM_LIVES = 3

-- Lane definitions: type, y_row, speed (+/-), object width, gap range
-- Types: "road", "water", "safe"
local LANES = {
    { type = "safe",  row = 11 },  -- start/bottom safe zone
    { type = "road",  row = 10, speed = -90,  ow = 80,  color = {0.6,0.1,0.1}, label = "CAR" },
    { type = "road",  row = 9,  speed = 120,  ow = 60,  color = {0.8,0.4,0.1}, label = "CAR" },
    { type = "road",  row = 8,  speed = -140, ow = 100, color = {0.7,0.2,0.6}, label = "TRUCK" },
    { type = "road",  row = 7,  speed = 100,  ow = 70,  color = {0.5,0.5,0.1}, label = "CAR" },
    { type = "road",  row = 6,  speed = -80,  ow = 90,  color = {0.8,0.2,0.2}, label = "CAR" },
    { type = "safe",  row = 5 },   -- median safe zone
    { type = "water", row = 4,  speed = 70,   ow = 120, color = {0.4,0.6,0.2}, label = "LOG" },
    { type = "water", row = 3,  speed = -100, ow = 90,  color = {0.3,0.5,0.1}, label = "LOG" },
    { type = "water", row = 2,  speed = 80,   ow = 140, color = {0.5,0.65,0.25}, label = "LOG" },
    { type = "water", row = 1,  speed = -60,  ow = 100, color = {0.35,0.55,0.15}, label = "LOG" },
    { type = "safe",  row = 0 },   -- home row
}

-- ── State ────────────────────────────────────────────────────────────────

local frog = {}
local lane_objects = {}   -- lane_objects[row] = list of {x, w}
local homes = {}          -- homes[slot] = filled (bool)
local score, lives, level = 0, NUM_LIVES, 1
local game_state = "playing"
local hop_cd = 0
local on_log = nil   -- reference to current log when in water

-- ── Helpers ──────────────────────────────────────────────────────────────

local function frog_row()
    return math.floor(frog.y / CELL + 0.5)
end

local function init()
    frog = { x = W/2 - CELL/2, y = (ROWS - 1) * CELL, w = CELL - 4, h = CELL - 4 }
    hop_cd = 0

    -- Spawn lane objects with gaps
    lane_objects = {}
    for _, lane in ipairs(LANES) do
        if lane.type == "road" or lane.type == "water" then
            local objs = {}
            local x = math.random() * W
            for i = 1, 5 do
                objs[#objs+1] = { x = x, w = lane.ow + math.random(-10, 20) }
                x = x + lane.ow + 80 + math.random(40, 120)
            end
            lane_objects[lane.row] = objs
        end
    end

    -- Home slots
    homes = {}
    for i = 1, HOME_SLOTS do homes[i] = false end

    on_log = nil
    game_state = "playing"
end

-- ── Load ─────────────────────────────────────────────────────────────────

function lurek.init()
    lurek.gfx.setBackgroundColor(0.05, 0.1, 0.05)
    score = 0; lives = NUM_LIVES; level = 1
    init()
end

-- ── Update ───────────────────────────────────────────────────────────────

function lurek.process(dt)
    if game_state ~= "playing" then return end
    hop_cd = math.max(0, hop_cd - dt)

    -- Move lane objects
    for _, lane in ipairs(LANES) do
        if lane.type ~= "safe" then
            local objs = lane_objects[lane.row]
            if objs then
                for _, obj in ipairs(objs) do
                    obj.x = obj.x + lane.speed * dt
                    -- Wrap around screen
                    if lane.speed > 0 and obj.x > W + 50 then obj.x = -obj.w - 20 end
                    if lane.speed < 0 and obj.x + obj.w < -50 then obj.x = W + 20 end
                end
            end
        end
    end

    -- Move frog with log
    local row = frog_row()
    local on_water = false
    on_log = nil
    for _, lane in ipairs(LANES) do
        if lane.type == "water" and lane.row == row then
            on_water = true
            local objs = lane_objects[lane.row]
            if objs then
                for _, obj in ipairs(objs) do
                    if frog.x + frog.w/2 >= obj.x and frog.x + frog.w/2 <= obj.x + obj.w then
                        on_log = obj
                        frog.x = frog.x + lane.speed * dt
                        break
                    end
                end
            end
            if not on_log then
                -- In water, no log = die
                lives = lives - 1
                if lives <= 0 then game_state = "gameover" else init() end
                return
            end
        end
    end

    -- Frog out of screen
    if frog.x < -CELL or frog.x > W then
        lives = lives - 1
        if lives <= 0 then game_state = "gameover" else init() end
        return
    end

    -- Collision with road vehicles
    for _, lane in ipairs(LANES) do
        if lane.type == "road" and lane.row == row then
            local objs = lane_objects[lane.row]
            if objs then
                for _, obj in ipairs(objs) do
                    if frog.x + 2 < obj.x + obj.w and frog.x + frog.w - 2 > obj.x and
                       frog.y + 2 < lane.row * CELL + CELL and frog.y + frog.h - 2 > lane.row * CELL then
                        lives = lives - 1
                        if lives <= 0 then game_state = "gameover" else init() end
                        return
                    end
                end
            end
        end
    end

    -- Reached home row
    if row == 0 then
        local slot = math.floor((frog.x + CELL/4) / (W / HOME_SLOTS)) + 1
        slot = math.max(1, math.min(HOME_SLOTS, slot))
        if not homes[slot] then
            homes[slot] = true
            score = score + 100 + math.max(0, 200 - math.floor(hop_cd))
        else
            -- Already filled — die
            lives = lives - 1
            if lives <= 0 then game_state = "gameover" else init() end
            return
        end
        -- Check all homes filled
        local all = true
        for _, h in ipairs(homes) do if not h then all = false; break end end
        if all then
            level = level + 1
            score = score + 500
            init()
        else
            frog.x = W/2 - CELL/2
            frog.y = (ROWS - 1) * CELL
        end
    end
end

-- ── Draw ─────────────────────────────────────────────────────────────────

function lurek.render()
    -- Draw lane backgrounds
    for _, lane in ipairs(LANES) do
        local ly = lane.row * CELL
        if lane.type == "safe" then
            lurek.gfx.setColor(0.15, 0.3, 0.1)
        elseif lane.type == "road" then
            lurek.gfx.setColor(0.2, 0.2, 0.2)
        else -- water
            lurek.gfx.setColor(0.05, 0.15, 0.45)
        end
        lurek.gfx.rectangle("fill", 0, ly, W, CELL)
    end

    -- Lane dividers (road)
    lurek.gfx.setColor(0.5, 0.5, 0.1, 0.4)
    for _, lane in ipairs(LANES) do
        if lane.type == "road" then
            local ly = lane.row * CELL + CELL/2
            for x = 0, W, 30 do
                lurek.gfx.rectangle("fill", x, ly - 2, 16, 4)
            end
        end
    end

    -- Home row lily pads
    local slot_w = W / HOME_SLOTS
    for i = 1, HOME_SLOTS do
        local hx = (i - 1) * slot_w + slot_w/2 - 20
        local hy = 4
        if homes[i] then
            lurek.gfx.setColor(0.1, 0.8, 0.2)
        else
            lurek.gfx.setColor(0.1, 0.4, 0.15)
        end
        lurek.gfx.circle("fill", (i - 1) * slot_w + slot_w/2, CELL/2, 20)
    end

    -- Lane objects (cars / logs)
    for _, lane in ipairs(LANES) do
        if lane.type ~= "safe" then
            local objs = lane_objects[lane.row]
            if objs then
                for _, obj in ipairs(objs) do
                    local ly = lane.row * CELL + 4
                    lurek.gfx.setColor(lane.color[1], lane.color[2], lane.color[3])
                    lurek.gfx.rectangle("fill", obj.x, ly, obj.w, CELL - 8)
                    -- Highlight
                    if lane.type == "road" then
                        lurek.gfx.setColor(1, 1, 0.5, 0.4)
                        lurek.gfx.circle("fill", obj.x + 12, ly + 8, 6)
                        lurek.gfx.circle("fill", obj.x + obj.w - 12, ly + 8, 6)
                    end
                end
            end
        end
    end

    -- Frog
    local fx = frog.x + 2
    local fy = frog.y + 2
    local fw = frog.w - 4
    local fh = frog.h - 4
    lurek.gfx.setColor(0.2, 0.8, 0.2)
    lurek.gfx.rectangle("fill", fx + fw/4, fy, fw/2, fh)
    lurek.gfx.rectangle("fill", fx, fy + fh/3, fw, fh/3)
    -- Eyes
    lurek.gfx.setColor(1, 1, 0)
    lurek.gfx.circle("fill", fx + fw/4, fy + 5, 4)
    lurek.gfx.circle("fill", fx + fw*3/4, fy + 5, 4)

    -- HUD
    lurek.gfx.setColor(1, 1, 1)
    lurek.gfx.print("Score: " .. score, 8, H - 20, 1.5)
    lurek.gfx.setColor(1, 0.4, 0.4)
    local life_str = ""
    for i = 1, lives do life_str = life_str .. "🐸" end
    lurek.gfx.print("Lives: " .. lives, W/2 - 50, H - 20, 1.5)
    lurek.gfx.setColor(0.5, 0.8, 0.5)
    lurek.gfx.print("Level " .. level, W - 90, H - 20, 1.5)

    -- Overlay
    if game_state == "gameover" then
        lurek.gfx.setColor(0, 0, 0, 0.7)
        lurek.gfx.rectangle("fill", 0, 0, W, H)
        lurek.gfx.setColor(1, 0.3, 0.3)
        lurek.gfx.print("GAME OVER", W/2 - 80, H/2 - 25, 3)
        lurek.gfx.setColor(1, 1, 1)
        lurek.gfx.print("Score: " .. score, W/2 - 50, H/2 + 15, 2)
        lurek.gfx.setColor(0.6, 0.6, 0.6)
        lurek.gfx.print("Press R to restart", W/2 - 100, H/2 + 48, 2)
    end
end

-- ── Input ────────────────────────────────────────────────────────────────

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "r" then score = 0; lives = NUM_LIVES; level = 1; init() end
    if game_state ~= "playing" then return end
    if hop_cd > 0 then return end

    local moved = false
    if key == "up" or key == "w" then
        frog.y = frog.y - CELL; moved = true
    elseif key == "down" or key == "s" then
        frog.y = math.min(frog.y + CELL, (ROWS - 1) * CELL); moved = true
    elseif key == "left" or key == "a" then
        frog.x = frog.x - CELL; moved = true
    elseif key == "right" or key == "d" then
        frog.x = frog.x + CELL; moved = true
    end

    if moved then
        hop_cd = 0.12
        score = score + 1
    end
end
