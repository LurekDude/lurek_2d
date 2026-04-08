-- Module availability guard (added by fix_nil_module_demos.py)
-- Run with: cargo run -- demos/showcase/province_demo
if not luna.province then
    function luna.init()
        luna.gfx.setBackgroundColor(0.08, 0.08, 0.12)
        luna.gfx.print("luna.province is not available in this build", 180, 270)
    end
    return
end

-- Province Map Demo for Luna2D
-- Demonstrates: world generation, map modes, fog of war, pathfinding, objects
-- Uses the generic property system -- terrain, owner, etc. are just properties.

local map         -- ProvinceMap handle
local data        -- ProvinceData handle for properties
local selected    -- currently selected province id (or nil)
local path_ids    -- province ids along current path (or nil)
local mode_idx    -- current map mode index (1-based)
local mode_names  -- list of mode names

local terrain_types = { "land", "sea", "forest", "mountain", "desert" }
local terrain_colors = {
    land     = { 0.4, 0.7, 0.3, 1.0 },
    sea      = { 0.2, 0.3, 0.8, 1.0 },
    forest   = { 0.1, 0.5, 0.1, 1.0 },
    mountain = { 0.6, 0.5, 0.4, 1.0 },
    desert   = { 0.9, 0.8, 0.5, 1.0 },
}

function luna.init()
    -- Generate a random province world (shapes only -- no terrain assigned)
    map = luna.province.generate({
        width = 200,
        height = 150,
        provinces = 40,
        seed = 7,
    })

    -- Create property data store
    data = luna.province.newData()

    -- Assign terrain as a generic property (game developer's choice!)
    local ids = map:getProvinceIds()
    for i, pid in ipairs(ids) do
        -- Assign a quasi-random terrain type based on province index
        local ttype = terrain_types[(i % #terrain_types) + 1]
        data:setProperty(pid, "terrain", ttype)
        data:setProperty(pid, "owner", math.ceil(i / 5))
    end

    -- Set up map modes using generic property system
    map:addMapMode("source", "source")   -- raw province colours
    map:addMapMode("terrain", "property", {
        key = "terrain",
        colors = terrain_colors,
        default = { 0.5, 0.5, 0.5, 1.0 },
    })
    mode_names = { "source", "terrain" }
    mode_idx = 1
    map:setMapMode("source")

    -- Calculate positions for all provinces
    map:calculatePositions()

    -- Reveal some provinces via fog of war
    if #ids > 0 then
        map:revealRadius(ids[1], 3)
    end

    -- Place an improvement on the first province
    if #ids > 0 then
        local cx, cy = map:getCentroid(ids[1])
        map:addImprovement(ids[1], "fort", cx, cy)
    end
end

function luna.process(dt)
    -- nothing dynamic in this demo
end

function luna.render()
    if not map then return end

    local w = map:getWidth()
    local h = map:getHeight()
    local sw = luna.gfx.getWidth()
    local sh = luna.gfx.getHeight()

    -- Scale the province map to fill the window
    local sx = sw / w
    local sy = sh / h
    local scale = math.min(sx, sy)

    luna.gfx.push()
    luna.gfx.scale(scale, scale)

    -- Draw province colour buffer
    local ids = map:getProvinceIds()
    for _, pid in ipairs(ids) do
        local r, g, b = map:getProvinceColor(pid)
        luna.gfx.setColor(r / 255, g / 255, b / 255)

        -- Approximate: draw a small rect at centroid (real rendering would
        -- use the full pixel buffer, but this gives a visual indication)
        local cx, cy = map:getCentroid(pid)
        local area = map:getArea(pid)
        local side = math.sqrt(area)
        luna.gfx.rectangle("fill", cx - side / 2, cy - side / 2, side, side)
    end

    -- Highlight selected province
    if selected then
        luna.gfx.setColor(1, 1, 0, 0.5)
        local cx, cy = map:getCentroid(selected)
        luna.gfx.circle("fill", cx, cy, 5)
    end

    -- Draw path
    if path_ids then
        luna.gfx.setColor(0, 1, 0)
        for i = 1, #path_ids - 1 do
            local ax, ay = map:getCentroid(path_ids[i])
            local bx, by = map:getCentroid(path_ids[i + 1])
            luna.gfx.line(ax, ay, bx, by)
        end
    end

    luna.gfx.pop()

    -- HUD
    luna.gfx.setColor(1, 1, 1)
    luna.gfx.print("Province Demo -- click to select, right-click to path", 10, 10)
    luna.gfx.print("Mode: " .. mode_names[mode_idx] .. "  [M] to cycle", 10, 30)
    luna.gfx.print("Provinces: " .. map:getProvinceCount(), 10, 50)
    if selected then
        local terrain = data:getProperty(selected, "terrain") or "unknown"
        local owner = data:getProperty(selected, "owner") or 0
        luna.gfx.print("Selected: " .. selected .. "  terrain=" .. tostring(terrain) .. "  owner=" .. tostring(owner), 10, 70)
    end
end

function luna.mousepressed(x, y, button)
    if not map then return end

    local sw = luna.gfx.getWidth()
    local sh = luna.gfx.getHeight()
    local w = map:getWidth()
    local h = map:getHeight()
    local scale = math.min(sw / w, sh / h)

    local mx = math.floor(x / scale)
    local my = math.floor(y / scale)
    local pid = map:getProvinceAt(mx, my)

    if button == 1 and pid and pid ~= 0 then
        selected = pid
        path_ids = nil
    elseif button == 2 and selected and pid and pid ~= 0 then
        -- Find path from selected to clicked province using property-based costs
        local result = map:findPath(selected, pid, {
            propertyCosts = {
                terrain = {
                    land = 1.0,
                    sea = 2.0,
                    forest = 1.5,
                    mountain = 3.0,
                    desert = 2.0,
                },
            },
            defaultCost = 1.0,
        })
        if result then
            path_ids = result.provinces
        end
    end
end

function luna.keypressed(key)
    if key == "m" then
        mode_idx = (mode_idx % #mode_names) + 1
        map:setMapMode(mode_names[mode_idx])
    end
end
