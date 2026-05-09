-- test_procgen_evidence.lua
-- Evidence test: procedural generation APIs visualized as PNG outputs

local OUT = "tests/output/procgen/"

local function clamp255(v)
    if v < 0 then return 0 end
    if v > 255 then return 255 end
    return math.floor(v)
end

-- @describe Evidence: lurek.procgen API + PNG visualizations
describe("Evidence: lurek.procgen API + PNG visualizations", function()
    -- @evidence file
    it("PNG: cellular automata with flood fill overlay", function()
        local gw, gh = 64, 64
        local scale = 4
        local img = lurek.image.newImageData(gw * scale, gh * scale)

        local cave = lurek.procgen.cellularAutomata(gw, gh, { fill = 0.46, iterations = 5, seed = 17 })
        local flooded = lurek.procgen.floodFill(cave, gw, gh, math.floor(gw / 2), math.floor(gh / 2), 0, false)

        for gy = 0, gh - 1 do
            for gx = 0, gw - 1 do
                local idx = gy * gw + gx + 1
                local px, py = gx * scale, gy * scale
                if cave[idx] == 1 then
                    img:drawRect(px, py, scale, scale, 52, 48, 58, 255)
                else
                    img:drawRect(px, py, scale, scale, 150, 165, 140, 255)
                end
                if flooded[idx] == 1 then
                    img:drawRect(px + 1, py + 1, scale - 2, scale - 2, 80, 170, 230, 210)
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "procgen_cellular_flood.png")
        expect_evidence_created(OUT .. "procgen_cellular_flood.png")
    end)

    -- @evidence file
    it("PNG: poisson disk points with voronoi regions", function()
        local W, H = 300, 220
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 18, 20, 28, 255)

        local points = lurek.procgen.poissonDisk(W, H, 18, 30, 42)
        local regions, dist, dist2 = lurek.procgen.voronoi(W, H, points, { metric = "euclidean" })

        for y = 0, H - 1 do
            for x = 0, W - 1 do
                local idx = y * W + x + 1
                local rid = regions[idx] or 0
                local d = dist[idx] or 0
                local shade = clamp255(40 + d * 35)
                local r = (rid * 47) % 180 + 50
                local g = (rid * 67) % 180 + 50
                local b = (rid * 83) % 180 + 50
                img:setPixel(x, y, clamp255((r + shade) * 0.5), clamp255((g + shade) * 0.5), clamp255((b + shade) * 0.5), 255)
            end
        end

        for _, pt in ipairs(points) do
            img:drawCircle(math.floor(pt.x), math.floor(pt.y), 2, 235, 245, 255, 255)
        end

        -- use dist2 just to ensure this output path touches all 3 voronoi return tables
        if #dist2 > 0 then
            img:drawRect(4, 4, 10, 4, 255, 210, 120, 255)
        end

        lurek.image.savePNG(img, OUT .. "procgen_poisson_voronoi.png")
        expect_evidence_created(OUT .. "procgen_poisson_voronoi.png")
    end)

    -- @evidence file
    it("PNG: noise map vs parallel noise with perlin/simplex strips", function()
        local W, H = 256, 192
        local img = lurek.image.newImageData(W, H)

        local w2, h2 = 64, 48
        local a = lurek.procgen.noiseMap(w2, h2, { seed = 77, scale_x = 0.08, scale_y = 0.08, octaves = 4 })
        local b = lurek.procgen.noiseMapParallel(w2, h2, { seed = 77, scale_x = 0.08, scale_y = 0.08, octaves = 4 })

        -- left: noiseMap
        for y = 0, h2 - 1 do
            for x = 0, w2 - 1 do
                local idx = y * w2 + x + 1
                local v = a[idx] or 0
                local c = clamp255((v * 0.5 + 0.5) * 255)
                img:drawRect(x * 2, y * 2, 2, 2, c, c, c, 255)
            end
        end

        -- right: noiseMapParallel
        for y = 0, h2 - 1 do
            for x = 0, w2 - 1 do
                local idx = y * w2 + x + 1
                local v = b[idx] or 0
                local c = clamp255((v * 0.5 + 0.5) * 255)
                img:drawRect(128 + x * 2, y * 2, 2, 2, c, c, c, 255)
            end
        end

        -- bottom strips: perlin + simplex2d + simplex3d samples
        for x = 0, W - 1 do
            local p = lurek.procgen.perlinNoise(x * 0.03, 0.42, 7.0, 7.0)
            local s2 = lurek.procgen.simplex2d(x * 0.03, 0.25)
            local s3 = lurek.procgen.simplex3d(x * 0.03, 0.25, 0.75)
            img:drawRect(x, 110, 1, 18, clamp255((p * 0.5 + 0.5) * 255), 80, 100, 255)
            img:drawRect(x, 132, 1, 18, 80, clamp255((s2 * 0.5 + 0.5) * 255), 120, 255)
            img:drawRect(x, 154, 1, 18, 100, 120, clamp255((s3 * 0.5 + 0.5) * 255), 255)
        end

        lurek.image.savePNG(img, OUT .. "procgen_noise_suite.png")
        expect_evidence_created(OUT .. "procgen_noise_suite.png")
    end)

    -- @evidence file
    it("PNG: BSP and rooms dungeons side by side", function()
        local W, H = 360, 200
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 24, 25, 32, 255)

        local bsp = lurek.procgen.bspDungeon({ width = 40, height = 28, seed = 9 })
        local rooms = lurek.procgen.roomsDungeon({ width = 40, height = 28, max_rooms = 12, seed = 19 })

        -- BSP rooms (left)
        for _, r in ipairs(bsp.rooms) do
            img:drawRect(8 + r.x * 3, 8 + r.y * 3, math.max(1, r.w * 3), math.max(1, r.h * 3), 120, 190, 145, 255)
        end

        -- roomsDungeon grid (right)
        for y = 0, rooms.height - 1 do
            for x = 0, rooms.width - 1 do
                local idx = y * rooms.width + x + 1
                local v = rooms.grid[idx] or 0
                if v == 1 then
                    img:drawRect(184 + x * 3, 8 + y * 3, 3, 3, 180, 165, 110, 255)
                else
                    img:drawRect(184 + x * 3, 8 + y * 3, 3, 3, 52, 50, 58, 255)
                end
            end
        end

        lurek.image.savePNG(img, OUT .. "procgen_dungeons.png")
        expect_evidence_created(OUT .. "procgen_dungeons.png")
    end)

    -- @evidence file
    it("PNG: heightmap + world graph overlay", function()
        local W, H = 320, 240
        local img = lurek.image.newImageData(W, H)

        local hm = lurek.procgen.heightmap({ width = 80, height = 60, seed = 33, octaves = 4, persistence = 0.5 })
        local wg = lurek.procgen.worldGraph(W, H, 14, 8)

        for y = 0, hm.height - 1 do
            for x = 0, hm.width - 1 do
                local idx = y * hm.width + x + 1
                local v = hm.cells[idx] or 0
                local r = clamp255(v * 220)
                local g = clamp255(v * 255)
                local b = clamp255(90 + v * 120)
                img:drawRect(x * 4, y * 4, 4, 4, r, g, b, 255)
            end
        end

        for _, e in ipairs(wg.edges) do
            local from_region, to_region = nil, nil
            for _, r in ipairs(wg.regions) do
                if r.id == e.from then from_region = r end
                if r.id == e.to then to_region = r end
            end
            if from_region and to_region then
                img:drawLine(from_region.x, from_region.y, to_region.x, to_region.y, 30, 30, 40, 180)
            end
        end
        for _, r in ipairs(wg.regions) do
            img:drawCircle(math.floor(r.x), math.floor(r.y), 3, 245, 245, 255, 255)
        end

        lurek.image.savePNG(img, OUT .. "procgen_height_worldgraph.png")
        expect_evidence_created(OUT .. "procgen_height_worldgraph.png")
    end)

    -- @evidence file
    it("PNG: WFC tiles + L-system segments + generated names", function()
        local W, H = 320, 220
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 16, 18, 24, 255)

        local grid = lurek.procgen.wfcGenerate({
            width = 20,
            height = 14,
            seed = 12,
            max_attempts = 4,
            tiles = {
                { id = 0, weight = 1.0 },
                { id = 1, weight = 1.2 },
                { id = 2, weight = 0.8 },
            },
            adjacencies = {
                [0] = { 0, 1 },
                [1] = { 0, 1, 2 },
                [2] = { 1, 2 },
            },
        })

        for y = 0, grid.height - 1 do
            for x = 0, grid.width - 1 do
                local idx = y * grid.width + x + 1
                local t = grid.cells[idx] or 0
                if t == 0 then
                    img:drawRect(8 + x * 6, 8 + y * 6, 6, 6, 80, 95, 130, 255)
                elseif t == 1 then
                    img:drawRect(8 + x * 6, 8 + y * 6, 6, 6, 110, 160, 120, 255)
                else
                    img:drawRect(8 + x * 6, 8 + y * 6, 6, 6, 180, 140, 100, 255)
                end
            end
        end

        local segs = lurek.procgen.lsystemSegments(
            { axiom = "F+F+F+F", rules = {}, iterations = 0 },
            90,
            8.0
        )
        for _, s in ipairs(segs) do
            img:drawLine(220 + s.x1, 40 + s.y1, 220 + s.x2, 40 + s.y2, 240, 230, 160, 255)
        end

        local names = lurek.procgen.generateNames({ "Aldor", "Brenna", "Caelis", "Davor" }, 4, 4, 9, 99)
        for i, n in ipairs(names) do
            local c = clamp255(70 + i * 40)
            img:drawRect(210, 140 + (i - 1) * 16, math.min(100, #n * 8), 10, c, 200, 240, 255)
        end

        lurek.image.savePNG(img, OUT .. "procgen_wfc_lsystem_names.png")
        expect_evidence_created(OUT .. "procgen_wfc_lsystem_names.png")
    end)
end)

test_summary()
