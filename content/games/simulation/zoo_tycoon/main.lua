-- Zoo Tycoon — Lurek2D
-- Category: simulation
-- Build enclosures, buy animals, manage welfare, reach 5 stars

------------------------------------------------------------
-- Constants
------------------------------------------------------------
local GRID_COLS   = 20
local GRID_ROWS   = 14
local TILE_SIZE   = 40
local GRID_X      = 0
local GRID_Y      = 40   -- leave top strip for HUD

local TILE_EMPTY  = 0
local TILE_PATH   = 1
local TILE_GRASS  = 2
local TILE_WATER  = 3
local TILE_FENCE  = 4
local TILE_FOOD   = 5
local TILE_SHOP   = 6
local TILE_BENCH  = 7

local TILE_COLORS = {
    [TILE_EMPTY] = {0.18, 0.22, 0.15},
    [TILE_PATH]  = {0.55, 0.55, 0.50},
    [TILE_GRASS] = {0.25, 0.60, 0.20},
    [TILE_WATER] = {0.20, 0.40, 0.80},
    [TILE_FENCE] = {0.50, 0.35, 0.18},
    [TILE_FOOD]  = {0.85, 0.65, 0.15},
    [TILE_SHOP]  = {0.80, 0.30, 0.70},
    [TILE_BENCH] = {0.60, 0.50, 0.30},
}

local TILE_COSTS = {
    [TILE_PATH]  = 5,
    [TILE_FENCE] = 10,
    [TILE_WATER] = 15,
    [TILE_FOOD]  = 20,
    [TILE_SHOP]  = 50,
    [TILE_BENCH] = 10,
}

local ANIMAL_DEFS = {
    { name = "Lion",     cost = 200, emoji = "L", color = {0.85,0.70,0.20}, needW = 4, needH = 4, needWater = false, attraction = 10 },
    { name = "Penguin",  cost = 150, emoji = "P", color = {0.30,0.30,0.35}, needW = 3, needH = 3, needWater = true,  attraction = 8  },
    { name = "Monkey",   cost = 100, emoji = "M", color = {0.65,0.45,0.20}, needW = 3, needH = 3, needWater = false, attraction = 5  },
    { name = "Bear",     cost = 250, emoji = "B", color = {0.50,0.35,0.20}, needW = 5, needH = 5, needWater = false, attraction = 15 },
    { name = "Elephant", cost = 300, emoji = "E", color = {0.55,0.55,0.55}, needW = 6, needH = 4, needWater = false, attraction = 20 },
}

local FOOD_RANGE       = 5
local REVENUE_INTERVAL = 15
local FEED_INTERVAL    = 10
local HUNGER_INTERVAL  = 8
local VISITOR_BASE     = 2  -- gold per visitor per cycle

local STATE_TITLE   = "TITLE"
local STATE_PLAYING = "PLAYING"
local STATE_VICTORY = "VICTORY"

------------------------------------------------------------
-- Game state
------------------------------------------------------------
local state       = STATE_TITLE
local gold        = 300
local displayGold = 300
local rating      = 1.0
local displayRating = 1.0

local grid = {}       -- grid[row][col] = tile type
local animals = {}    -- { def, row, col, hunger, hopY, feedTimer }
local visitors = {}   -- { x, y, tx, ty, timer, satisfaction }
local particles = {}
local tweens    = {}

local buildMode   = nil   -- nil | TILE_* constant
local shopOpen    = false -- animal shop overlay
local deleteMode  = false
local revenueTimer = 0
local hungerTimer  = 0
local visitorCount = 0
local totalEarned  = 0

local camera
local fps = 0
local titleBlink = 0

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function tileToScreen(row, col)
    return GRID_X + (col - 1) * TILE_SIZE, GRID_Y + (row - 1) * TILE_SIZE
end

local function screenToTile(mx, my)
    local col = math.floor((mx - GRID_X) / TILE_SIZE) + 1
    local row = math.floor((my - GRID_Y) / TILE_SIZE) + 1
    if col >= 1 and col <= GRID_COLS and row >= 1 and row <= GRID_ROWS then
        return row, col
    end
    return nil, nil
end

local function spawnParticle(x, y, r, g, b, count, spread)
    for _ = 1, (count or 8) do
        local s = spread or 20
        table.insert(particles, {
            x = x, y = y,
            vx = (math.random() - 0.5) * s * 2,
            vy = (math.random() - 0.5) * s * 2 - 15,
            life = 0.5 + math.random() * 0.5,
            maxLife = 1.0,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        })
    end
end

local function addTween(target, field, from, to, duration)
    table.insert(tweens, {
        target = target, field = field,
        from = from, to = to,
        duration = duration, elapsed = 0,
    })
end

local function updateParticles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function updateTweens(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = math.min(tw.elapsed / tw.duration, 1.0)
        -- ease out quad
        local eased = 1 - (1 - t) * (1 - t)
        tw.target[tw.field] = tw.from + (tw.to - tw.from) * eased
        if t >= 1.0 then
            tw.target[tw.field] = tw.to
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end
end

-- Check if a rectangular area is fully enclosed by fence on its border
local function isEnclosed(startRow, startCol, w, h)
    -- Check border tiles are all fence
    for c = startCol, startCol + w - 1 do
        if c < 1 or c > GRID_COLS then return false end
        if startRow < 1 or startRow + h - 1 > GRID_ROWS then return false end
        if grid[startRow][c] ~= TILE_FENCE then return false end
        if grid[startRow + h - 1][c] ~= TILE_FENCE then return false end
    end
    for r = startRow, startRow + h - 1 do
        if grid[r][startCol] ~= TILE_FENCE then return false end
        if grid[r][startCol + w - 1] ~= TILE_FENCE then return false end
    end
    -- Interior must be grass or water (not empty/path/fence)
    for r = startRow + 1, startRow + h - 2 do
        for c = startCol + 1, startCol + w - 2 do
            local t = grid[r][c]
            if t ~= TILE_GRASS and t ~= TILE_WATER and t ~= TILE_FOOD then
                return false
            end
        end
    end
    return true
end

local function hasWaterInside(startRow, startCol, w, h)
    for r = startRow + 1, startRow + h - 2 do
        for c = startCol + 1, startCol + w - 2 do
            if grid[r][c] == TILE_WATER then return true end
        end
    end
    return false
end

-- Find a valid enclosure for an animal definition starting from click pos
local function findEnclosure(row, col, def)
    local w, h = def.needW, def.needH
    -- Search around the clicked tile for a valid enclosure
    for dr = -(h - 1), 0 do
        for dc = -(w - 1), 0 do
            local sr, sc = row + dr, col + dc
            if sr >= 1 and sc >= 1 and sr + h - 1 <= GRID_ROWS and sc + w - 1 <= GRID_COLS then
                if isEnclosed(sr, sc, w, h) then
                    if not def.needWater or hasWaterInside(sr, sc, w, h) then
                        -- Check no animal already in this enclosure
                        local occupied = false
                        for _, a in ipairs(animals) do
                            if a.row >= sr and a.row <= sr + h - 1 and
                               a.col >= sc and a.col <= sc + w - 1 then
                                occupied = true
                                break
                            end
                        end
                        if not occupied then
                            return sr, sc
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

local function isFoodNear(row, col)
    for r = math.max(1, row - FOOD_RANGE), math.min(GRID_ROWS, row + FOOD_RANGE) do
        for c = math.max(1, col - FOOD_RANGE), math.min(GRID_COLS, col + FOOD_RANGE) do
            if grid[r][c] == TILE_FOOD then return true end
        end
    end
    return false
end

local function countTileType(tileType)
    local n = 0
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            if grid[r][c] == tileType then n = n + 1 end
        end
    end
    return n
end

local function countUniqueSpecies()
    local seen = {}
    for _, a in ipairs(animals) do
        seen[a.def.name] = true
    end
    local n = 0
    for _ in pairs(seen) do n = n + 1 end
    return n
end

local function computeRating()
    local score = 0
    -- Animal variety (0–2 points)
    local species = countUniqueSpecies()
    score = score + math.min(species * 0.5, 2.0)
    -- Animal welfare (0–1 point)
    local happyCount = 0
    for _, a in ipairs(animals) do
        if a.hunger < 30 then happyCount = happyCount + 1 end
    end
    if #animals > 0 then
        score = score + (happyCount / #animals)
    end
    -- Paths and amenities (0–1 point)
    local paths = countTileType(TILE_PATH)
    local benches = countTileType(TILE_BENCH)
    local shops = countTileType(TILE_SHOP)
    score = score + math.min((paths * 0.02) + (benches * 0.05) + (shops * 0.1), 1.0)
    -- Animal count bonus (0–1 point)
    score = score + math.min(#animals * 0.15, 1.0)
    return math.max(1.0, math.min(5.0, score))
end

local function spawnVisitors(count)
    for _ = 1, count do
        local side = math.random(1, 4)
        local sx, sy
        if side == 1 then sx = 0; sy = math.random(GRID_Y, GRID_Y + GRID_ROWS * TILE_SIZE)
        elseif side == 2 then sx = 800; sy = math.random(GRID_Y, GRID_Y + GRID_ROWS * TILE_SIZE)
        elseif side == 3 then sx = math.random(0, 800); sy = GRID_Y
        else sx = math.random(0, 800); sy = GRID_Y + GRID_ROWS * TILE_SIZE
        end
        -- Target a random path tile
        local pathTiles = {}
        for r = 1, GRID_ROWS do
            for c = 1, GRID_COLS do
                if grid[r][c] == TILE_PATH then
                    table.insert(pathTiles, {r = r, c = c})
                end
            end
        end
        local tx, ty = 400, 300
        if #pathTiles > 0 then
            local pt = pathTiles[math.random(#pathTiles)]
            tx, ty = tileToScreen(pt.r, pt.c)
            tx = tx + TILE_SIZE * 0.5
            ty = ty + TILE_SIZE * 0.5
        end
        table.insert(visitors, {
            x = sx, y = sy, tx = tx, ty = ty,
            timer = 8 + math.random() * 6,
            satisfaction = 0.5 + math.random() * 0.5,
        })
        spawnParticle(sx, sy, 0.2, 0.8, 0.2, 5, 15)
    end
end

------------------------------------------------------------
-- Initialization
------------------------------------------------------------

-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

function lurek.init()
    lurek.window.setTitle("Zoo Tycoon — Lurek2D")
    lurek.render.setBackgroundColor(0.1, 0.15, 0.1)
    camera = lurek.camera.new()

    -- Initialize grid with grass
    for r = 1, GRID_ROWS do
        grid[r] = {}
        for c = 1, GRID_COLS do
            grid[r][c] = TILE_GRASS
        end
    end
    -- Starting entrance path
    for c = 9, 12 do
        grid[GRID_ROWS][c] = TILE_PATH
    end
end

------------------------------------------------------------
-- Input bindings
------------------------------------------------------------
local function _ready_setup()
    lurek.input.bind("build_path",    "1")
    lurek.input.bind("build_fence",   "2")
    lurek.input.bind("build_water",   "3")
    lurek.input.bind("build_food",    "4")
    lurek.input.bind("build_shop",    "5")
    lurek.input.bind("build_bench",   "6")
    lurek.input.bind("animals",       "a")
    lurek.input.bind("delete",        "d")
    lurek.input.bind("select",        "mouse1")
    lurek.input.bind("quit",          "escape")
    lurek.input.bind("buy1",          "1")
    lurek.input.bind("buy2",          "2")
    lurek.input.bind("buy3",          "3")
    lurek.input.bind("buy4",          "4")
    lurek.input.bind("buy5",          "5")
end

------------------------------------------------------------
-- Update
------------------------------------------------------------
function lurek.process(dt)
    fps = lurek.timer.getFPS()
    titleBlink = titleBlink + dt

    -- Title screen
    if state == STATE_TITLE then
        if lurek.input.wasActionPressed("select") then
            state = STATE_PLAYING
        end
        return
    end

    -- Victory screen
    if state == STATE_VICTORY then
        if lurek.input.wasActionPressed("quit") then
            lurek.event.quit()
        end
        return
    end

    -- Quit
    if lurek.input.wasActionPressed("quit") then
        if shopOpen then
            shopOpen = false
        else
            lurek.event.quit()
        end
        return
    end

    -- Animal shop toggle
    if lurek.input.wasActionPressed("animals") then
        shopOpen = not shopOpen
        buildMode = nil
        deleteMode = false
    end

    -- Animal shop purchases
    if shopOpen then
        for i = 1, 5 do
            if lurek.input.wasActionPressed("buy" .. i) then
                local def = ANIMAL_DEFS[i]
                if gold >= def.cost then
                    -- Place animal: user must click a valid enclosure next
                    buildMode = nil
                    deleteMode = false
                    -- We store pending buy and wait for click
                    shopOpen = false
                    buildMode = "animal_" .. i
                end
            end
        end
    else
        -- Build mode selection (only when shop is closed)
        if not shopOpen then
            if lurek.input.wasActionPressed("build_path")  then buildMode = TILE_PATH;  deleteMode = false; shopOpen = false end
            if lurek.input.wasActionPressed("build_fence") then buildMode = TILE_FENCE; deleteMode = false; shopOpen = false end
            if lurek.input.wasActionPressed("build_water") then buildMode = TILE_WATER; deleteMode = false; shopOpen = false end
            if lurek.input.wasActionPressed("build_food")  then buildMode = TILE_FOOD;  deleteMode = false; shopOpen = false end
            if lurek.input.wasActionPressed("build_shop")  then buildMode = TILE_SHOP;  deleteMode = false; shopOpen = false end
            if lurek.input.wasActionPressed("build_bench") then buildMode = TILE_BENCH; deleteMode = false; shopOpen = false end
        end
    end

    -- Delete mode
    if lurek.input.wasActionPressed("delete") then
        deleteMode = not deleteMode
        buildMode = nil
        shopOpen = false
    end

    -- Click to build / delete / place animal
    if lurek.input.wasActionPressed("select") and not shopOpen then
        local mx, my = lurek.input.mouse.getPosition()
        local row, col = screenToTile(mx, my)
        if row and col then
            if deleteMode then
                -- Remove tile (revert to grass), also remove animal if present
                local oldTile = grid[row][col]
                if oldTile ~= TILE_GRASS then
                    grid[row][col] = TILE_GRASS
                    spawnParticle(mx, my, 0.6, 0.4, 0.2, 6, 20)
                end
                -- Remove animal at this position
                for i = #animals, 1, -1 do
                    if animals[i].row == row and animals[i].col == col then
                        table.remove(animals, i)
                    end
                end
            elseif type(buildMode) == "string" and buildMode:sub(1, 7) == "animal_" then
                local idx = tonumber(buildMode:sub(8))
                local def = ANIMAL_DEFS[idx]
                if def and gold >= def.cost then
                    local er, ec = findEnclosure(row, col, def)
                    if er then
                        gold = gold - def.cost
                        -- Place animal in center of enclosure
                        local ar = er + math.floor(def.needH / 2)
                        local ac = ec + math.floor(def.needW / 2)
                        table.insert(animals, {
                            def = def, row = ar, col = ac,
                            hunger = 0, hopY = 0, feedTimer = 0,
                        })
                        local ax, ay = tileToScreen(ar, ac)
                        spawnParticle(ax + TILE_SIZE * 0.5, ay + TILE_SIZE * 0.5,
                            def.color[1], def.color[2], def.color[3], 12, 25)
                        addTween(animals[#animals], "hopY", -10, 0, 0.4)
                    end
                end
                buildMode = nil
            elseif type(buildMode) == "number" then
                local cost = TILE_COSTS[buildMode] or 0
                if gold >= cost and grid[row][col] ~= buildMode then
                    -- Don't build over animals
                    local animalHere = false
                    for _, a in ipairs(animals) do
                        if a.row == row and a.col == col then animalHere = true; break end
                    end
                    if not animalHere then
                        gold = gold - cost
                        grid[row][col] = buildMode
                        local sx, sy = tileToScreen(row, col)
                        spawnParticle(sx + TILE_SIZE * 0.5, sy + TILE_SIZE * 0.5,
                            0.7, 0.6, 0.4, 6, 18)
                    end
                end
            end
        end
    end

    -- Animal hunger
    hungerTimer = hungerTimer + dt
    if hungerTimer >= HUNGER_INTERVAL then
        hungerTimer = hungerTimer - HUNGER_INTERVAL
        for _, a in ipairs(animals) do
            if isFoodNear(a.row, a.col) then
                a.hunger = math.max(0, a.hunger - 20)
                local ax, ay = tileToScreen(a.row, a.col)
                spawnParticle(ax + TILE_SIZE * 0.5, ay + TILE_SIZE * 0.5,
                    1.0, 0.9, 0.3, 5, 12)
                addTween(a, "hopY", -6, 0, 0.3)
            else
                a.hunger = math.min(100, a.hunger + 15)
            end
        end
    end

    -- Revenue cycle
    revenueTimer = revenueTimer + dt
    if revenueTimer >= REVENUE_INTERVAL then
        revenueTimer = revenueTimer - REVENUE_INTERVAL
        -- Calculate visitors attracted
        local attraction = 0
        for _, a in ipairs(animals) do
            if a.hunger < 60 then
                attraction = attraction + a.def.attraction
            else
                attraction = attraction - 2  -- sick animals repel
            end
        end
        local newVisitors = math.max(0, math.floor(attraction * 0.5))
        visitorCount = newVisitors

        -- Revenue
        local revenue = newVisitors * VISITOR_BASE
        -- Gift shop bonus
        local shopCount = countTileType(TILE_SHOP)
        revenue = revenue + math.min(shopCount * 5, newVisitors * 5)

        local oldGold = gold
        gold = gold + revenue
        totalEarned = totalEarned + revenue
        addTween({ displayGold = displayGold }, "displayGold", displayGold, gold, 0.8)

        -- Spawn visual visitors
        if newVisitors > 0 then
            spawnVisitors(math.min(newVisitors, 10))
        end

        -- Update rating
        local newRating = computeRating()
        addTween({ displayRating = displayRating }, "displayRating", displayRating, newRating, 1.0)
        rating = newRating

        -- Check victory
        if rating >= 4.8 and gold >= 500 then
            state = STATE_VICTORY
        end
    end

    -- Update visitors
    local vi = 1
    while vi <= #visitors do
        local v = visitors[vi]
        -- Move toward target
        local dx = v.tx - v.x
        local dy = v.ty - v.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 2 then
            local speed = 40 + math.random() * 20
            v.x = v.x + (dx / dist) * speed * dt
            v.y = v.y + (dy / dist) * speed * dt
        end
        v.timer = v.timer - dt
        if v.timer <= 0 then
            table.remove(visitors, vi)
        else
            vi = vi + 1
        end
    end

    -- Update gold display tween manually (simple approach)
    local goldDiff = gold - displayGold
    if math.abs(goldDiff) > 0.5 then
        displayGold = displayGold + goldDiff * dt * 4
    else
        displayGold = gold
    end

    -- Rating display tween
    local ratingDiff = rating - displayRating
    if math.abs(ratingDiff) > 0.01 then
        displayRating = displayRating + ratingDiff * dt * 3
    else
        displayRating = rating
    end

    updateParticles(dt)
    updateTweens(dt)
end

------------------------------------------------------------
-- Render — zoo grid, animals, visitors
------------------------------------------------------------
function lurek.draw()
    camera:attach()

    -- Draw grid
    for r = 1, GRID_ROWS do
        for c = 1, GRID_COLS do
            local t = grid[r][c]
            local clr = TILE_COLORS[t] or TILE_COLORS[TILE_EMPTY]
            local x, y = tileToScreen(r, c)
            rect(x, y, TILE_SIZE - 1, TILE_SIZE - 1, clr[1], clr[2], clr[3], 1.0)

            -- Tile icons
            if t == TILE_FOOD then
                text_("F", x + 14, y + 10, 16, 1, 1, 1, 1)
            elseif t == TILE_SHOP then
                text_("$", x + 14, y + 10, 16, 1, 1, 0.8, 1)
            elseif t == TILE_BENCH then
                text_("=", x + 12, y + 12, 14, 0.9, 0.8, 0.6, 1)
            end
        end
    end

    -- Draw animals
    for _, a in ipairs(animals) do
        local ax, ay = tileToScreen(a.row, a.col)
        local offy = a.hopY or 0
        local clr = a.def.color
        -- Body
        rect(ax + 6, ay + 6 + offy, TILE_SIZE - 12, TILE_SIZE - 12,
            clr[1], clr[2], clr[3], 1.0)
        -- Label
        text_(a.def.emoji, ax + 13, ay + 10 + offy, 18, 1, 1, 1, 1)
        -- Hunger indicator
        local hr, hg, hb = 0.2, 0.85, 0.2
        if a.hunger > 30 and a.hunger <= 60 then hr, hg, hb = 0.9, 0.85, 0.1
        elseif a.hunger > 60 then hr, hg, hb = 0.9, 0.2, 0.15 end
        local barW = math.max(0, (1 - a.hunger / 100) * (TILE_SIZE - 12))
        rect(ax + 6, ay + TILE_SIZE - 6 + offy, barW, 3, hr, hg, hb, 0.9)
    end

    -- Draw visitors
    for _, v in ipairs(visitors) do
        local alpha = math.min(v.timer / 2.0, 1.0)
        rect(v.x - 3, v.y - 6, 6, 12, 0.9, 0.85, 0.7, alpha)
        rect(v.x - 3, v.y - 9, 6, 4, 0.95, 0.8, 0.6, alpha)
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        local alpha = math.max(0, p.life / p.maxLife)
        rect(p.x - p.size * 0.5, p.y - p.size * 0.5,
            p.size, p.size, p.r, p.g, p.b, alpha)
    end

    camera:detach()
end

------------------------------------------------------------
-- Render UI — HUD, menus, stats, rating
------------------------------------------------------------
function lurek.draw_ui()
    if state == STATE_TITLE then
        -- Title screen
        rect(0, 0, 800, 600, 0.05, 0.1, 0.05, 1)
        text_("ZOO TYCOON", 240, 160, 48, 0.4, 0.9, 0.3, 1)
        text_("BUILD THE PERFECT ZOO", 250, 230, 22, 0.7, 0.85, 0.6, 1)
        -- Animal icons row
        local names = {"Lion", "Penguin", "Monkey", "Bear", "Elephant"}
        for i, name in ipairs(names) do
            local clr = ANIMAL_DEFS[i].color
            rect(200 + (i - 1) * 90, 290, 60, 40, clr[1], clr[2], clr[3], 0.8)
            text_(ANIMAL_DEFS[i].emoji, 222 + (i - 1) * 90, 298, 22, 1, 1, 1, 1)
        end
        local blinkAlpha = 0.5 + 0.5 * math.abs(math.sin(titleBlink * 2.5))
        text_("Click to Start", 310, 380, 20, 0.8, 0.9, 0.7, blinkAlpha)
        text_("FPS: " .. fps, 10, 580, 14, 0.5, 0.5, 0.5, 0.6)
        return
    end

    if state == STATE_VICTORY then
        rect(100, 100, 600, 400, 0.05, 0.15, 0.05, 0.95)
        rect(102, 102, 596, 396, 0.1, 0.25, 0.1, 1)
        text_("5-STAR ZOO!", 260, 160, 42, 1.0, 0.85, 0.2, 1)
        text_("Congratulations! Your zoo is world-class!", 190, 230, 18, 0.8, 0.9, 0.7, 1)
        text_("Animals: " .. #animals, 300, 280, 18, 0.7, 0.9, 0.6, 1)
        text_("Species: " .. countUniqueSpecies(), 300, 305, 18, 0.7, 0.9, 0.6, 1)
        text_("Gold Earned: " .. math.floor(totalEarned), 300, 330, 18, 1, 0.85, 0.3, 1)
        -- Draw 5 gold stars
        for i = 1, 5 do
            text_("*", 290 + (i - 1) * 40, 370, 36, 1.0, 0.85, 0.15, 1)
        end
        text_("Press ESC to exit", 310, 430, 16, 0.6, 0.7, 0.5, 0.8)
        return
    end

    -- HUD bar
    rect(0, 0, 800, 38, 0.08, 0.08, 0.06, 0.95)
    text_("Gold: " .. math.floor(displayGold), 10, 10, 18, 1.0, 0.85, 0.2, 1)

    -- Rating stars
    local starStr = ""
    for i = 1, 5 do
        if i <= math.floor(displayRating + 0.5) then
            starStr = starStr .. "*"
        else
            starStr = starStr .. "."
        end
    end
    text_("Rating: " .. starStr .. " (" .. string.format("%.1f", displayRating) .. ")",
        200, 10, 16, 0.9, 0.85, 0.4, 1)

    text_("Visitors: " .. visitorCount, 450, 10, 16, 0.7, 0.9, 0.7, 1)
    text_("Animals: " .. #animals, 600, 10, 16, 0.7, 0.85, 0.6, 1)
    text_("FPS: " .. fps, 740, 10, 14, 0.5, 0.5, 0.5, 0.6)

    -- Build mode indicator
    local modeText = "None"
    if deleteMode then
        modeText = "DELETE (click to remove)"
    elseif type(buildMode) == "number" then
        local names = {[TILE_PATH]="Path",[TILE_FENCE]="Fence",[TILE_WATER]="Water",
            [TILE_FOOD]="Food Stn",[TILE_SHOP]="Gift Shop",[TILE_BENCH]="Bench"}
        modeText = "Build: " .. (names[buildMode] or "?")
    elseif type(buildMode) == "string" and buildMode:sub(1, 7) == "animal_" then
        local idx = tonumber(buildMode:sub(8))
        if idx then modeText = "Place: " .. ANIMAL_DEFS[idx].name .. " (click enclosure)" end
    end
    text_("Mode: " .. modeText, 10, 582, 14, 0.7, 0.8, 0.6, 0.9)

    -- Build toolbar
    rect(0, 560, 800, 40, 0.08, 0.08, 0.06, 0.9)
    local tools = {"1:Path(5)", "2:Fence(10)", "3:Water(15)", "4:Food(20)", "5:Shop(50)", "6:Bench(10)", "A:Animals", "D:Delete"}
    for i, label in ipairs(tools) do
        local tx = 10 + (i - 1) * 98
        text_(label, tx, 565, 12, 0.6, 0.75, 0.5, 0.9)
    end

    -- Animal shop overlay
    if shopOpen then
        rect(150, 120, 500, 350, 0.06, 0.12, 0.06, 0.96)
        rect(152, 122, 496, 346, 0.1, 0.2, 0.1, 1)
        text_("ANIMAL SHOP", 310, 135, 24, 0.4, 0.9, 0.3, 1)
        text_("Press 1-5 to buy, ESC to close", 260, 165, 14, 0.6, 0.7, 0.5, 0.8)

        for i, def in ipairs(ANIMAL_DEFS) do
            local y = 195 + (i - 1) * 52
            local clr = def.color
            -- Icon
            rect(175, y, 36, 36, clr[1], clr[2], clr[3], 0.9)
            text_(def.emoji, 185, y + 8, 20, 1, 1, 1, 1)
            -- Info
            local canBuy = gold >= def.cost
            local textAlpha = canBuy and 1.0 or 0.4
            text_(i .. ". " .. def.name, 225, y + 2, 18, 0.9, 0.9, 0.8, textAlpha)
            text_("Cost: " .. def.cost .. "g", 225, y + 22, 13, 1.0, 0.85, 0.2, textAlpha)
            local needStr = def.needW .. "x" .. def.needH .. " fenced"
            if def.needWater then needStr = needStr .. " + water" end
            needStr = needStr .. "  (+" .. def.attraction .. " visitors)"
            text_(needStr, 380, y + 12, 12, 0.6, 0.75, 0.5, textAlpha)
        end
    end
end
