-- test_evidence_minimap.lua
-- Evidence test: lurek.minimap API + renders minimap grid to PNG
-- Produces: minimap_terrain.png, minimap_fog.png

local OUT = "tests/output/minimap/"

--- Helper: draw filled rect
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, a) end
        end
    end
end

describe("Evidence: lurek.minimap API + PNG visualization", function()
    -- @evidence file
    it("PNG: terrain grid rendered as colored cells", function()
        local GRID = 16
        local CELL = 8
        local W, H = GRID * CELL, GRID * CELL
        local img = lurek.image.newImageData(W, H)
        img:fill(0, 0, 0, 255)

        local mm = lurek.minimap.newMinimap(GRID, GRID, W, H)

        -- Define terrain types
        local terrain_colors = {
            [0] = {20, 80, 20},      -- grass (default)
            [1] = {60, 40, 20},      -- dirt
            [2] = {30, 30, 200},     -- water
            [3] = {120, 120, 120},   -- stone
            [4] = {0, 100, 0},       -- forest
        }
        for id, c in pairs(terrain_colors) do
            mm:setTerrainColor(id, c[1]/255, c[2]/255, c[3]/255, 1.0)
        end

        -- Paint a landscape pattern
        for y = 1, GRID do
            for x = 1, GRID do
                local t = 0 -- grass
                -- Water river down the middle
                if x >= 7 and x <= 9 then t = 2 end
                -- Stone mountains at top
                if y <= 3 and (x < 7 or x > 9) then t = 3 end
                -- Forest patches
                if y >= 12 and x <= 5 then t = 4 end
                -- Dirt paths
                if y == 8 then t = 1 end
                mm:setTerrain(x, y, t)
            end
        end

        -- Render to ImageData
        for gy = 1, GRID do
            for gx = 1, GRID do
                local t = mm:getTerrain(gx, gy)
                local c = terrain_colors[t] or terrain_colors[0]
                draw_rect(img, (gx - 1) * CELL, (gy - 1) * CELL, CELL, CELL, c[1], c[2], c[3])
            end
        end

        lurek.image.savePNG(img, OUT .. "minimap_terrain.png")
    end)

    -- @evidence file
    it("PNG: fog-of-war overlay on terrain", function()
        local GRID = 16
        local CELL = 8
        local W, H = GRID * CELL, GRID * CELL
        local img = lurek.image.newImageData(W, H)

        local mm = lurek.minimap.newMinimap(GRID, GRID, W, H)
        mm:setFogEnabled(true)

        -- Set terrain + fog levels
        for y = 1, GRID do
            for x = 1, GRID do
                mm:setTerrain(x, y, 0)
                -- Fog: revealed in center, dark at edges
                local cx, cy = GRID / 2, GRID / 2
                local dist = math.sqrt((x - cx)^2 + (y - cy)^2)
                local fog = math.min(255, math.floor(dist * 30))
                mm:setFogLevel(x, y, fog)
            end
        end

        -- Render terrain with fog overlay
        local base_color = {60, 160, 60}
        for gy = 1, GRID do
            for gx = 1, GRID do
                local fog = mm:getFogLevel(gx, gy)
                local darkness = 1.0 - (fog / 255)
                local r = math.floor(base_color[1] * darkness)
                local g = math.floor(base_color[2] * darkness)
                local b = math.floor(base_color[3] * darkness)
                draw_rect(img, (gx - 1) * CELL, (gy - 1) * CELL, CELL, CELL, r, g, b)
            end
        end

        lurek.image.savePNG(img, OUT .. "minimap_fog.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_minimap.lua
-- ================================================================

-- test_evidence_minimap.lua
-- Evidence test: lurek.minimap API + renders minimap grid to PNG
-- Produces: minimap_terrain.png, minimap_fog.png

local OUT = "tests/output/minimap/"

--- Helper: draw filled rect
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, a) end
        end
    end
end

describe("Evidence: lurek.minimap API + PNG visualization", function()
    -- @evidence file
    it("PNG: terrain grid rendered as colored cells", function()
        local GRID = 16
        local CELL = 8
        local W, H = GRID * CELL, GRID * CELL
        local img = lurek.image.newImageData(W, H)
        img:fill(0, 0, 0, 255)

        local mm = lurek.minimap.newMinimap(GRID, GRID, W, H)

        -- Define terrain types
        local terrain_colors = {
            [0] = {20, 80, 20},      -- grass (default)
            [1] = {60, 40, 20},      -- dirt
            [2] = {30, 30, 200},     -- water
            [3] = {120, 120, 120},   -- stone
            [4] = {0, 100, 0},       -- forest
        }
        for id, c in pairs(terrain_colors) do
            mm:setTerrainColor(id, c[1]/255, c[2]/255, c[3]/255, 1.0)
        end

        -- Paint a landscape pattern
        for y = 1, GRID do
            for x = 1, GRID do
                local t = 0 -- grass
                -- Water river down the middle
                if x >= 7 and x <= 9 then t = 2 end
                -- Stone mountains at top
                if y <= 3 and (x < 7 or x > 9) then t = 3 end
                -- Forest patches
                if y >= 12 and x <= 5 then t = 4 end
                -- Dirt paths
                if y == 8 then t = 1 end
                mm:setTerrain(x, y, t)
            end
        end

        -- Render to ImageData
        for gy = 1, GRID do
            for gx = 1, GRID do
                local t = mm:getTerrain(gx, gy)
                local c = terrain_colors[t] or terrain_colors[0]
                draw_rect(img, (gx - 1) * CELL, (gy - 1) * CELL, CELL, CELL, c[1], c[2], c[3])
            end
        end

        lurek.image.savePNG(img, OUT .. "minimap_terrain.png")
    end)

    -- @evidence file
    it("PNG: fog-of-war overlay on terrain", function()
        local GRID = 16
        local CELL = 8
        local W, H = GRID * CELL, GRID * CELL
        local img = lurek.image.newImageData(W, H)

        local mm = lurek.minimap.newMinimap(GRID, GRID, W, H)
        mm:setFogEnabled(true)

        -- Set terrain + fog levels
        for y = 1, GRID do
            for x = 1, GRID do
                mm:setTerrain(x, y, 0)
                -- Fog: revealed in center, dark at edges
                local cx, cy = GRID / 2, GRID / 2
                local dist = math.sqrt((x - cx)^2 + (y - cy)^2)
                local fog = math.min(255, math.floor(dist * 30))
                mm:setFogLevel(x, y, fog)
            end
        end

        -- Render terrain with fog overlay
        local base_color = {60, 160, 60}
        for gy = 1, GRID do
            for gx = 1, GRID do
                local fog = mm:getFogLevel(gx, gy)
                local darkness = 1.0 - (fog / 255)
                local r = math.floor(base_color[1] * darkness)
                local g = math.floor(base_color[2] * darkness)
                local b = math.floor(base_color[3] * darkness)
                draw_rect(img, (gx - 1) * CELL, (gy - 1) * CELL, CELL, CELL, r, g, b)
            end
        end

        lurek.image.savePNG(img, OUT .. "minimap_fog.png")
    end)

end)
test_summary()
