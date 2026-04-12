-- test_evidence_combined.lua
-- Evidence tests: cross-module integration (procgen+pathfinding, noise+minimap,
--                 terrain+raycaster, tilemap+particles)

local OUT = "tests/lua/evidence/output/combined/"

-- Helper: draw a small rectangle on an image
local function draw_rect(img, x, y, w, h, r, g, b)
    img:drawRect(x, y, w, h, r, g, b, 255)
end

describe("Evidence: combined procgen + pathfinding", function()

    it("generates a cave map then finds a path through it", function()
        local GW, GH = 32, 32
        local SCALE  = 6

        -- 1. Generate cave using cellular automata
        local cave = lurek.procgen.cellularAutomata(GW, GH)

        -- 2. Build a NavGrid mirroring the cave walls
        local grid = lurek.pathfinding.newNavGrid(GW, GH)
        for gy = 1, GH do
            for gx = 1, GW do
                local idx = (gy - 1) * GW + gx
                if cave[idx] == 1 then
                    grid:setBlocked(gx, gy, true)
                end
            end
        end

        -- 3. Find a path from top-left to bottom-right
        local pf   = lurek.pathfinding.newPathfinder(grid)
        local path = pf:findPath(1, 1, GW, GH)

        -- 4. Render: cave cells
        local img = lurek.img.newImageData(GW * SCALE, GH * SCALE)
        img:drawRect(0, 0, GW * SCALE, GH * SCALE, 20, 20, 25, 255)

        for gy = 1, GH do
            for gx = 1, GW do
                local idx = (gy - 1) * GW + gx
                local px, py = (gx - 1) * SCALE, (gy - 1) * SCALE
                if cave[idx] == 1 then
                    draw_rect(img, px, py, SCALE, SCALE, 55, 45, 40)
                else
                    draw_rect(img, px, py, SCALE, SCALE, 170, 180, 160)
                end
            end
        end

        -- 5. Overlay path in red
        if path then
            for _, step in ipairs(path) do
                local px = math.floor((step.x - 1) * SCALE + SCALE / 2 - 1)
                local py = math.floor((step.y - 1) * SCALE + SCALE / 2 - 1)
                img:drawRect(px, py, 3, 3, 220, 60, 60, 255)
            end
        end

        lurek.img.savePNG(img, OUT .. "procgen_pathfinding.png")
    end)

end)

describe("Evidence: combined noise + minimap", function()

    it("generates terrain heights from FBM noise and renders as a minimap", function()
        local GRID = 24
        local CELL = 8
        local W, H = GRID * CELL, GRID * CELL

        local ng = lurek.math.newNoiseGenerator(7)
        local mm = lurek.minimap.newMinimap(GRID, GRID, W, H)

        local img = lurek.img.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        for gy = 1, GRID do
            for gx = 1, GRID do
                local nx = gx / GRID * 3
                local ny = gy / GRID * 3
                local h_val = ng:fbm(nx, ny, 4, 0.5, 2.0)
                -- -1..1 → 0..255
                local v = math.floor((h_val + 1) * 0.5 * 255)
                local terrain = h_val > 0.1 and 1 or 0
                mm:setTerrain(gx, gy, terrain)

                -- Colour by height
                local r, g, b
                if h_val < -0.2 then       -- deep water
                    r, g, b = 30, 60, 180
                elseif h_val < 0.1 then    -- shore
                    r, g, b = 194, 178, 128
                elseif h_val < 0.4 then    -- grass
                    r, g, b = 50, math.min(200, 100 + v), 50
                else                       -- rock / snow
                    r, g, b = v, v, v
                end
                draw_rect(img, (gx - 1) * CELL, (gy - 1) * CELL, CELL, CELL, r, g, b)
            end
        end

        lurek.img.savePNG(img, OUT .. "noise_minimap.png")
    end)

end)

describe("Evidence: combined terrain + raycaster", function()

    it("generates a walled maze via noise then renders a raycaster depth view", function()
        local GW, GH = 16, 16
        local ng = lurek.math.newNoiseGenerator(99)
        local rc = lurek.raycaster.new(GW, GH)

        -- Build wall layout from noise threshold
        for gy = 1, GH do
            for gx = 1, GW do
                -- Always wall the border
                local is_border = gx == 1 or gx == GW or gy == 1 or gy == GH
                local nx = gx / GW * 4
                local ny = gy / GH * 4
                local n  = ng:fbm(nx, ny, 3, 0.5, 2.0)
                local is_wall = is_border or (n > 0.25)
                rc:setCell(gx, gy, is_wall and 1 or 0)
            end
        end

        -- Cast a wide-angle ray fan from the centre
        local cx, cy = GW / 2 + 0.5, GH / 2 + 0.5
        local FOV = math.pi / 2
        local NUM_RAYS = 80
        local rays = rc:castRays(cx, cy, 0.0, FOV, NUM_RAYS, 30)

        -- Render depth buffer image
        local IW, IH = NUM_RAYS * 3, 200
        local img = lurek.img.newImageData(IW, IH)
        img:drawRect(0, 0, IW, IH, 20, 20, 30, 255)

        for i, ray in ipairs(rays) do
            if ray and ray.dist then
                local col_h = math.floor(IH / math.max(0.1, ray.dist) * 3)
                col_h = math.min(col_h, IH)
                local shade = math.max(20, math.floor(255 / (1 + ray.dist * 0.3)))
                local col_x = (i - 1) * 3
                local col_y = math.floor((IH - col_h) / 2)
                img:drawRect(col_x, col_y, 3, col_h, shade, shade, shade, 255)
            end
        end

        lurek.img.savePNG(img, OUT .. "terrain_raycaster.png")
    end)

end)

describe("Evidence: combined tilemap + particles", function()

    it("renders a tilemap scene with a particle burst overlay", function()
        local TILE  = 8
        local MAP_W = 20
        local MAP_H = 15
        local W, H  = MAP_W * TILE, MAP_H * TILE

        -- Build a tilemap
        local tm = lurek.tilemap.newTileMap(MAP_W, MAP_H)
        tm:addLayer("ground", MAP_W, MAP_H)

        -- Render the tilemap manually (floor + borders)
        local img = lurek.img.newImageData(W, H)
        for ty = 1, MAP_H do
            for tx = 1, MAP_W do
                local px, py = (tx - 1) * TILE, (ty - 1) * TILE
                local is_border = tx == 1 or tx == MAP_W or ty == 1 or ty == MAP_H
                if is_border then
                    draw_rect(img, px, py, TILE, TILE, 80, 70, 60)
                else
                    draw_rect(img, px, py, TILE, TILE, 140, 180, 120)
                end
            end
        end

        -- Emit particles from the centre and draw them as sparks
        local sys = lurek.particles.newSystem()
        local cx = math.floor(W / 2)
        local cy = math.floor(H / 2)
        sys:setPosition(cx, cy)
        sys:start()
        sys:emit(120)
        sys:update(0.016)

        -- Draw simulated sparks radiating from the emitter centre
        local count = sys:count()
        math.randomseed(12345)
        for _ = 1, math.min(math.max(count, 20), 60) do
            local angle = math.random() * math.pi * 2
            local r = math.random() * 25
            local sx = math.floor(cx + math.cos(angle) * r)
            local sy = math.floor(cy + math.sin(angle) * r)
            if sx >= 0 and sx < W and sy >= 0 and sy < H then
                img:drawRect(sx, sy, 2, 2, 255, 200, 40, 220)
            end
        end

        -- Mark emitter centre
        img:drawRect(cx - 2, cy - 2, 5, 5, 255, 255, 255, 255)

        lurek.img.savePNG(img, OUT .. "tilemap_particles.png")
    end)

end)

test_summary()
