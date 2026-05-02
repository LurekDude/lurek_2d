-- test_evidence_procgen.lua
-- Evidence test: Procedural generation visualised as images

local OUT = "tests/output/procgen/"

describe("Evidence: Procedural generation", function()

    -- @evidence file
    it("visualises cellular automata cave map", function()
        local gw, gh = 64, 64
        local scale = 4
        local imgW, imgH = gw * scale, gh * scale

        local grid = lurek.procgen.cellularAutomata(gw, gh)
        local img = lurek.image.newImageData(imgW, imgH)

        -- Background
        img:drawRect(0, 0, imgW, imgH, 40, 40, 50, 255)

        for gy = 0, gh - 1 do
            for gx = 0, gw - 1 do
                local idx = gy * gw + gx + 1  -- 1-based Lua indexing
                local cell = grid[idx]
                local px, py = gx * scale, gy * scale
                if cell == 1 then
                    -- Wall: dark stone color
                    img:drawRect(px, py, scale, scale, 80, 70, 60, 255)
                else
                    -- Floor: light color
                    img:drawRect(px, py, scale, scale, 180, 190, 170, 255)
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "procgen_cellular.png")
    end)

    -- @evidence file
    it("visualises Poisson disk sampling", function()
        local W, H = 256, 256
        local minDist = 12

        local points = lurek.procgen.poissonDisk(W, H, minDist, 30, 42)
        local img = lurek.image.newImageData(W, H)

        -- Background
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        -- Draw each point as a small circle
        for _, pt in ipairs(points) do
            local px = math.floor(pt.x)
            local py = math.floor(pt.y)
            img:drawCircle(px, py, 2, 100, 200, 255, 255)
        end

        lurek.image.savePNG(img, OUT .. "procgen_poisson.png")
        -- Should have generated a reasonable number of points
    end)

end)



-- ================================================================
-- Merged from: test_evidence_procgen.lua
-- ================================================================

-- test_evidence_procgen.lua
-- Evidence test: Procedural generation visualised as images

local OUT = "tests/output/procgen/"

describe("Evidence: Procedural generation", function()

    -- @evidence file
    it("visualises cellular automata cave map", function()
        local gw, gh = 64, 64
        local scale = 4
        local imgW, imgH = gw * scale, gh * scale

        local grid = lurek.procgen.cellularAutomata(gw, gh)
        local img = lurek.image.newImageData(imgW, imgH)

        -- Background
        img:drawRect(0, 0, imgW, imgH, 40, 40, 50, 255)

        for gy = 0, gh - 1 do
            for gx = 0, gw - 1 do
                local idx = gy * gw + gx + 1  -- 1-based Lua indexing
                local cell = grid[idx]
                local px, py = gx * scale, gy * scale
                if cell == 1 then
                    -- Wall: dark stone color
                    img:drawRect(px, py, scale, scale, 80, 70, 60, 255)
                else
                    -- Floor: light color
                    img:drawRect(px, py, scale, scale, 180, 190, 170, 255)
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "procgen_cellular.png")
    end)

    -- @evidence file
    it("visualises Poisson disk sampling", function()
        local W, H = 256, 256
        local minDist = 12

        local points = lurek.procgen.poissonDisk(W, H, minDist, 30, 42)
        local img = lurek.image.newImageData(W, H)

        -- Background
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        -- Draw each point as a small circle
        for _, pt in ipairs(points) do
            local px = math.floor(pt.x)
            local py = math.floor(pt.y)
            img:drawCircle(px, py, 2, 100, 200, 255, 255)
        end

        lurek.image.savePNG(img, OUT .. "procgen_poisson.png")
        -- Should have generated a reasonable number of points
    end)

end)
test_summary()
