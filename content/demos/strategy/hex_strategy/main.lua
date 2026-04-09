-- Hex Strategy Game
-- Controls: Click hex to select, C to place city on selected hex, N for next turn, Escape to quit
-- Gather resources and expand your territory!
-- Run with: cargo run -- content/demos/strategy/hex_strategy

local HEX_SIZE = 36
local OX, OY = 400, 300
local MAP_RADIUS = 5
local hexes = {}
local selected = nil
local cities = {}
local turnNum = 1
local resources = { gold = 50, wood = 20, food = 30 }
local infoText = ""

local TERRAIN = {
    grass   = { r = 0.3, g = 0.7, b = 0.25, gold = 1, wood = 0, food = 3 },
    forest  = { r = 0.15, g = 0.45, b = 0.12, gold = 0, wood = 3, food = 1 },
    water   = { r = 0.15, g = 0.35, b = 0.8, gold = 0, wood = 0, food = 2 },
    mountain = { r = 0.5, g = 0.45, b = 0.4, gold = 3, wood = 0, food = 0 },
    desert  = { r = 0.85, g = 0.75, b = 0.4, gold = 2, wood = 0, food = 0 },
}

local function hexToPixel(q, r)
    local x = HEX_SIZE * (1.732 * q + 0.866 * r)
    local y = HEX_SIZE * 1.5 * r
    return OX + x, OY + y
end

local function pixelToHex(px, py)
    local x, y = px - OX, py - OY
    local q = (x * 0.5774 - y / 3) / HEX_SIZE
    local r = y * 0.6667 / HEX_SIZE
    -- Round to nearest hex using cube-coordinate rounding:
    -- compute the fractional cube coord, round all three, then fix the largest rounding error
    local rq, rr = math.floor(q + 0.5), math.floor(r + 0.5)
    local rs = -rq - rr
    local dq = math.abs(rq - q)
    local dr = math.abs(rr - r)
    local ds = math.abs(rs - (-q - r))
    if dq > dr and dq > ds then
        rq = -rr - rs
    elseif dr > ds then
        rr = -rq - rs
    end
    return rq, rr
end

local function hexKey(q, r)
    return q .. "," .. r
end

local function drawHex(cx, cy, size, mode)
    local verts = {}
    for i = 0, 5 do
        local angle = math.pi / 3 * i - math.pi / 6
        table.insert(verts, cx + size * math.cos(angle))
        table.insert(verts, cy + size * math.sin(angle))
    end
    lurek.gfx.polygon(mode, verts)
end

local function getRandomTerrain(q, r)
    -- Two independent simplex samples: one for elevation, one for biome
    -- Layering two noise frequencies avoids uniformly noisy or blobby maps
    local n = lurek.math.simplex2d(q * 0.4, r * 0.4)
    local n2 = lurek.math.simplex2d(q * 0.2 + 100, r * 0.2 + 100)
    if n < -0.3 then return "water" end
    if n > 0.4 then return "mountain" end
    if n2 > 0.3 then return "forest" end
    if n2 < -0.4 then return "desert" end
    return "grass"
end

function lurek.init()
    lurek.window.setTitle("Hex Strategy")
    lurek.gfx.setBackgroundColor(0.08, 0.06, 0.12)
    -- Generate hex map
    for q = -MAP_RADIUS, MAP_RADIUS do
        for r = -MAP_RADIUS, MAP_RADIUS do
            local s = -q - r
            if math.abs(s) <= MAP_RADIUS then
                local key = hexKey(q, r)
                hexes[key] = {
                    q = q, r = r,
                    terrain = getRandomTerrain(q, r),
                    hasCity = false
                }
            end
        end
    end
    -- Place starting city at center
    local ck = hexKey(0, 0)
    hexes[ck].terrain = "grass"
    hexes[ck].hasCity = true
    table.insert(cities, { q = 0, r = 0 })
end

local function gatherResources()
    for _, c in ipairs(cities) do
        -- Gather from city hex and neighbors
        for dq = -1, 1 do
            for dr = -1, 1 do
                local ds = -dq - dr
                if math.abs(ds) <= 1 and math.abs(dq) <= 1 and math.abs(dr) <= 1 then
                    local key = hexKey(c.q + dq, c.r + dr)
                    local h = hexes[key]
                    if h then
                        local t = TERRAIN[h.terrain]
                        resources.gold = resources.gold + t.gold
                        resources.wood = resources.wood + t.wood
                        resources.food = resources.food + t.food
                    end
                end
            end
        end
    end
end

function lurek.process(dt)
end

function lurek.render()
    -- Draw hexes
    for _, h in pairs(hexes) do
        local px, py = hexToPixel(h.q, h.r)
        local t = TERRAIN[h.terrain]
        lurek.gfx.setColor(t.r, t.g, t.b, 1)
        drawHex(px, py, HEX_SIZE - 1, "fill")
        lurek.gfx.setColor(0.1, 0.1, 0.1, 0.5)
        drawHex(px, py, HEX_SIZE - 1, "line")

        -- City marker
        if h.hasCity then
            lurek.gfx.setColor(1, 0.85, 0.2, 1)
            lurek.gfx.rectangle("fill", px - 8, py - 10, 16, 14)
            lurek.gfx.setColor(0.9, 0.6, 0.1, 1)
            lurek.gfx.polygon("fill", { px - 10, py - 10, px, py - 18, px + 10, py - 10 })
            lurek.gfx.setColor(1, 1, 1, 1)
            lurek.gfx.print("C", px - 4, py - 8)
        end
    end

    -- Selection highlight
    if selected then
        local px, py = hexToPixel(selected.q, selected.r)
        lurek.gfx.setColor(1, 1, 0, 0.7)
        lurek.gfx.setLineWidth(3)
        drawHex(px, py, HEX_SIZE, "line")
        lurek.gfx.setLineWidth(1)
    end

    -- HUD panel
    lurek.gfx.setColor(0, 0, 0, 0.7)
    lurek.gfx.rectangle("fill", 0, 0, 220, 130)
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Turn: " .. turnNum, 10, 10)
    lurek.gfx.setColor(1, 0.85, 0.2, 1)
    lurek.gfx.print("Gold: " .. resources.gold, 10, 30)
    lurek.gfx.setColor(0.5, 0.35, 0.15, 1)
    lurek.gfx.print("Wood: " .. resources.wood, 10, 50)
    lurek.gfx.setColor(0.4, 0.85, 0.3, 1)
    lurek.gfx.print("Food: " .. resources.food, 10, 70)
    lurek.gfx.setColor(0.8, 0.8, 0.8, 1)
    lurek.gfx.print("Cities: " .. #cities, 10, 90)
    lurek.gfx.print("[N] Next Turn  [C] Place City", 10, 110)

    -- Info panel for selected hex
    if selected then
        local key = hexKey(selected.q, selected.r)
        local h = hexes[key]
        if h then
            local t = TERRAIN[h.terrain]
            lurek.gfx.setColor(0, 0, 0, 0.7)
            lurek.gfx.rectangle("fill", 580, 0, 220, 110)
            lurek.gfx.setColor(1, 1, 1, 1)
            lurek.gfx.print("Hex (" .. h.q .. "," .. h.r .. ")", 590, 10)
            lurek.gfx.print("Terrain: " .. h.terrain, 590, 30)
            lurek.gfx.print("Gold/turn: " .. t.gold, 590, 50)
            lurek.gfx.print("Wood/turn: " .. t.wood, 590, 70)
            lurek.gfx.print("Food/turn: " .. t.food, 590, 90)
        end
    end

    -- Info text
    if infoText ~= "" then
        lurek.gfx.setColor(1, 1, 0.5, 1)
        lurek.gfx.print(infoText, 240, 570)
    end
end

function lurek.mousepressed(x, y, button)
    local q, r = pixelToHex(x, y)
    local key = hexKey(q, r)
    if hexes[key] then
        selected = { q = q, r = r }
        infoText = ""
    end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "n" then
        turnNum = turnNum + 1
        gatherResources()
        infoText = "Resources gathered!"
    end
    if key == "c" and selected then
        local hk = hexKey(selected.q, selected.r)
        local h = hexes[hk]
        if h and not h.hasCity and h.terrain ~= "water" and h.terrain ~= "mountain" then
            if resources.gold >= 30 and resources.wood >= 15 then
                resources.gold = resources.gold - 30
                resources.wood = resources.wood - 15
                h.hasCity = true
                table.insert(cities, { q = selected.q, r = selected.r })
                infoText = "City built!"
            else
                infoText = "Need 30 gold + 15 wood"
            end
        elseif h and h.hasCity then
            infoText = "Already has a city"
        elseif h then
            infoText = "Can't build on " .. h.terrain
        end
    end
end
