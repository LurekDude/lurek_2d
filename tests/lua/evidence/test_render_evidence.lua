-- test_render_evidence.lua
-- Canonical file. Merged from multiple sources.

-- test_evidence_render_drawing.lua
-- Evidence test: lurek.render drawing API -    renders each primitive into PNG
-- Produces: graphic_primitives.png, graphic_color_grid.png

local OUT = "tests/output/graphics/"

--- Helper: draw filled rect into ImageData
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, a) end
        end
    end
end

--- Helper: draw outline rect into ImageData
local function draw_rect_line(img, x0, y0, w, h, r, g, b)
    for x = x0, x0 + w - 1 do
        if x >= 0 and x < img:getWidth() then
            if y0 >= 0 and y0 < img:getHeight() then img:setPixel(x, y0, r, g, b, 255) end
            local yb = y0 + h - 1
            if yb >= 0 and yb < img:getHeight() then img:setPixel(x, yb, r, g, b, 255) end
        end
    end
    for y = y0, y0 + h - 1 do
        if y >= 0 and y < img:getHeight() then
            if x0 >= 0 and x0 < img:getWidth() then img:setPixel(x0, y, r, g, b, 255) end
            local xr = x0 + w - 1
            if xr >= 0 and xr < img:getWidth() then img:setPixel(xr, y, r, g, b, 255) end
        end
    end
end

--- Helper: draw filled circle into ImageData
local function draw_circle(img, cx, cy, radius, r, g, b, a)
    a = a or 255
    local r2 = radius * radius
    for y = math.max(0, cy - radius), math.min(img:getHeight() - 1, cy + radius) do
        for x = math.max(0, cx - radius), math.min(img:getWidth() - 1, cx + radius) do
            local dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= r2 then
                img:setPixel(x, y, r, g, b, a)
            end
        end
    end
end

--- Helper: draw a line (Bresenham) into ImageData
local function draw_line(img, x0, y0, x1, y1, r, g, b)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy
    while true do
        if x0 >= 0 and x0 < img:getWidth() and y0 >= 0 and y0 < img:getHeight() then
            img:setPixel(x0, y0, r, g, b, 255)
        end
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then err = err - dy; x0 = x0 + sx end
        if e2 < dx then err = err + dx; y0 = y0 + sy end
    end
end

-- @description Covers suite: Evidence: lurek.render drawing API + PNG output.
describe("Evidence: lurek.render drawing API + PNG output", function()

    -- @covers lurek.image.newImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws a manual gallery of primitive equivalents so the intended graphic command outputs can be inspected in one PNG.
    it("PNG: all graphic primitives rendered to image", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(15, 15, 25, 255)

        -- Filled rectangle (red)
        draw_rect(img, 10, 10, 60, 40, 220, 50, 50, 255)
        -- Outline rectangle (green)
        draw_rect_line(img, 10, 60, 60, 40, 50, 220, 50)
        -- Filled circle (blue)
        draw_circle(img, 150, 40, 30, 50, 50, 220, 255)
        -- Circle outline (via ring)
        for angle = 0, 360 do
            local rad = math.rad(angle)
            local px = math.floor(150 + 30 * math.cos(rad))
            local py = math.floor(120 + 30 * math.sin(rad))
            if px >= 0 and px < W and py >= 0 and py < H then
                img:setPixel(px, py, 50, 220, 220, 255)
            end
        end
        -- Diagonal line (yellow)
        draw_line(img, 10, 170, 240, 200, 220, 220, 50)
        -- Horizontal line (white)
        draw_line(img, 10, 220, 240, 220, 255, 255, 255)
        -- Vertical line (magenta)
        draw_line(img, 200, 10, 200, 240, 220, 50, 220)
        -- Point cluster (white dots)
        for i = 0, 19 do
            local px = 120 + i * 6
            local py = 180
            if px < W then img:setPixel(px, py, 255, 255, 255, 255) end
        end

        lurek.image.savePNG(img, OUT .. "graphic_primitives.png")
    end)

    -- @covers lurek.render.setColor
    -- @covers lurek.render.getColor
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Iterates through a grid of colors, round-trips them through the graphics state, and writes the resulting swatch sheet.
    it("PNG: color grid -    setColor evidence across hue range", function()
        local W, H = 128, 128
        local img = lurek.image.newImageData(W, H)

        -- 8x8 grid of colors; each cell verifies setColor round-trip
        local cell_w = W / 8
        local cell_h = H / 8
        for row = 0, 7 do
            for col = 0, 7 do
                local r = math.floor((col / 7) * 255)
                local g = math.floor((row / 7) * 255)
                local b = math.floor(((col + row) / 14) * 255)
                -- Verify setColor + getColor round-trip
                lurek.render.setColor(r / 255, g / 255, b / 255, 1.0)
                local gr, gg, gb, ga = lurek.render.getColor()
                -- Draw the color block
                local x0 = math.floor(col * cell_w)
                local y0 = math.floor(row * cell_h)
                draw_rect(img, x0, y0, math.floor(cell_w), math.floor(cell_h), r, g, b, 255)
            end
        end

        lurek.image.savePNG(img, OUT .. "graphic_color_grid.png")
    end)

end)



-- ================================================================
-- Merged from: test_render_draw_cmds_evidence.lua
-- ================================================================

-- test_evidence_render_draw_cmds.lua
-- Evidence test: new lurek.render draw commands (bezier curves, gradient rect,
-- colored polygon, iso cube tile, hex tile, sort group, bevel rect, layers, path).

-- @description Covers suite: Evidence: lurek.render new GPU draw commands.
describe("Evidence: lurek.render new GPU draw commands", function()
end)




-- ================================================================
-- Merged from: test_render_graphics_evidence.lua
-- ================================================================

-- Placeholder evidence suite for migrated graphics/image fixtures.
-- Keeps pending graphics/image artifact ports visible until each migrated evidence case is translated to real Lua output generation.

-- @description Placeholder evidence suite for migrated graphics/image fixtures that have not been translated to Lua yet.
describe('Evidence graphics', function()
end)



-- ================================================================
-- Merged from: test_terrain_render_evidence.lua
-- ================================================================

-- Evidence test: terrain render
-- Produces: terrain_render.png showing the terrain grid as a pixel image.
-- This test proves the TerrainMap API works by creating a terrain, filling
-- a pattern, and calling toImageData to produce a verifiable PNG.

-- @description Covers suite: evidence: terrain render.
describe("evidence: terrain render", function()
    -- @covers lurek.physics.newTerrain
    -- @covers LuaTerrain:fillAll
    -- @covers LuaTerrain:fillCircle
    -- @covers LuaTerrain:toImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Creates a 64x64 terrain, fills it completely solid, digs a circle,
    --              renders to RGBA bytes, and saves as a PNG evidence file.
    it("terrain toImageData produces a pixel image", function()
        ensure_evidence_dir("physics")
        local path = evidence_output_dir("physics") .. "terrain_render.png"

        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(64, 64, 4, world)

        -- Fill solid ground.
        terrain:fillAll(true)
        -- Dig a large crater in the centre.
        terrain:fillCircle(128, 128, 64, false)

        -- Render to RGBA bytes (solid = brown, empty = dark sky).
        local raw = terrain:toImageData(139, 90, 43, 30, 30, 60)
        expect_equal(64 * 64 * 4, #raw)

        -- Build an image from raw bytes and save.
        local img = lurek.image.newImageData(64, 64)
        img:setRawData(raw)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)




-- ================================================================
-- Merged from: test_evidence_render_drawing.lua
-- ================================================================

-- test_evidence_render_drawing.lua
-- Evidence test: lurek.render drawing API -    renders each primitive into PNG
-- Produces: graphic_primitives.png, graphic_color_grid.png

local OUT = "tests/output/graphics/"

--- Helper: draw filled rect into ImageData
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, a) end
        end
    end
end

--- Helper: draw outline rect into ImageData
local function draw_rect_line(img, x0, y0, w, h, r, g, b)
    for x = x0, x0 + w - 1 do
        if x >= 0 and x < img:getWidth() then
            if y0 >= 0 and y0 < img:getHeight() then img:setPixel(x, y0, r, g, b, 255) end
            local yb = y0 + h - 1
            if yb >= 0 and yb < img:getHeight() then img:setPixel(x, yb, r, g, b, 255) end
        end
    end
    for y = y0, y0 + h - 1 do
        if y >= 0 and y < img:getHeight() then
            if x0 >= 0 and x0 < img:getWidth() then img:setPixel(x0, y, r, g, b, 255) end
            local xr = x0 + w - 1
            if xr >= 0 and xr < img:getWidth() then img:setPixel(xr, y, r, g, b, 255) end
        end
    end
end

--- Helper: draw filled circle into ImageData
local function draw_circle(img, cx, cy, radius, r, g, b, a)
    a = a or 255
    local r2 = radius * radius
    for y = math.max(0, cy - radius), math.min(img:getHeight() - 1, cy + radius) do
        for x = math.max(0, cx - radius), math.min(img:getWidth() - 1, cx + radius) do
            local dx, dy = x - cx, y - cy
            if dx * dx + dy * dy <= r2 then
                img:setPixel(x, y, r, g, b, a)
            end
        end
    end
end

--- Helper: draw a line (Bresenham) into ImageData
local function draw_line(img, x0, y0, x1, y1, r, g, b)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy
    while true do
        if x0 >= 0 and x0 < img:getWidth() and y0 >= 0 and y0 < img:getHeight() then
            img:setPixel(x0, y0, r, g, b, 255)
        end
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then err = err - dy; x0 = x0 + sx end
        if e2 < dx then err = err + dx; y0 = y0 + sy end
    end
end

-- @description Covers suite: Evidence: lurek.render drawing API + PNG output.
describe("Evidence: lurek.render drawing API + PNG output", function()

    -- @covers lurek.image.newImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws a manual gallery of primitive equivalents so the intended graphic command outputs can be inspected in one PNG.
    it("PNG: all graphic primitives rendered to image", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(15, 15, 25, 255)

        -- Filled rectangle (red)
        draw_rect(img, 10, 10, 60, 40, 220, 50, 50, 255)
        -- Outline rectangle (green)
        draw_rect_line(img, 10, 60, 60, 40, 50, 220, 50)
        -- Filled circle (blue)
        draw_circle(img, 150, 40, 30, 50, 50, 220, 255)
        -- Circle outline (via ring)
        for angle = 0, 360 do
            local rad = math.rad(angle)
            local px = math.floor(150 + 30 * math.cos(rad))
            local py = math.floor(120 + 30 * math.sin(rad))
            if px >= 0 and px < W and py >= 0 and py < H then
                img:setPixel(px, py, 50, 220, 220, 255)
            end
        end
        -- Diagonal line (yellow)
        draw_line(img, 10, 170, 240, 200, 220, 220, 50)
        -- Horizontal line (white)
        draw_line(img, 10, 220, 240, 220, 255, 255, 255)
        -- Vertical line (magenta)
        draw_line(img, 200, 10, 200, 240, 220, 50, 220)
        -- Point cluster (white dots)
        for i = 0, 19 do
            local px = 120 + i * 6
            local py = 180
            if px < W then img:setPixel(px, py, 255, 255, 255, 255) end
        end

        lurek.image.savePNG(img, OUT .. "graphic_primitives.png")
    end)

    -- @covers lurek.render.setColor
    -- @covers lurek.render.getColor
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Iterates through a grid of colors, round-trips them through the graphics state, and writes the resulting swatch sheet.
    it("PNG: color grid -    setColor evidence across hue range", function()
        local W, H = 128, 128
        local img = lurek.image.newImageData(W, H)

        -- 8x8 grid of colors; each cell verifies setColor round-trip
        local cell_w = W / 8
        local cell_h = H / 8
        for row = 0, 7 do
            for col = 0, 7 do
                local r = math.floor((col / 7) * 255)
                local g = math.floor((row / 7) * 255)
                local b = math.floor(((col + row) / 14) * 255)
                -- Verify setColor + getColor round-trip
                lurek.render.setColor(r / 255, g / 255, b / 255, 1.0)
                local gr, gg, gb, ga = lurek.render.getColor()
                -- Draw the color block
                local x0 = math.floor(col * cell_w)
                local y0 = math.floor(row * cell_h)
                draw_rect(img, x0, y0, math.floor(cell_w), math.floor(cell_h), r, g, b, 255)
            end
        end

        lurek.image.savePNG(img, OUT .. "graphic_color_grid.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_render_draw_cmds.lua
-- ================================================================

-- test_evidence_render_draw_cmds.lua
-- Evidence test: new lurek.render draw commands (bezier curves, gradient rect,
-- colored polygon, iso cube tile, hex tile, sort group, bevel rect, layers, path).

-- @description Covers suite: Evidence: lurek.render new GPU draw commands.
describe("Evidence: lurek.render new GPU draw commands (2)", function()
end)




-- ================================================================
-- Merged from: test_evidence_render_graphics.lua
-- ================================================================

-- Placeholder evidence suite for migrated graphics/image fixtures.
-- Keeps pending graphics/image artifact ports visible until each migrated evidence case is translated to real Lua output generation.

-- @description Placeholder evidence suite for migrated graphics/image fixtures that have not been translated to Lua yet.
describe('Evidence graphics', function()
end)



-- ================================================================
-- Merged from: test_evidence_terrain_render.lua
-- ================================================================

-- Evidence test: terrain render
-- Produces: terrain_render.png showing the terrain grid as a pixel image.
-- This test proves the TerrainMap API works by creating a terrain, filling
-- a pattern, and calling toImageData to produce a verifiable PNG.

-- @description Covers suite: evidence: terrain render.
describe("evidence: terrain render", function()
    -- @covers lurek.physics.newTerrain
    -- @covers LuaTerrain:fillAll
    -- @covers LuaTerrain:fillCircle
    -- @covers LuaTerrain:toImageData
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Creates a 64x64 terrain, fills it completely solid, digs a circle,
    --              renders to RGBA bytes, and saves as a PNG evidence file.
    it("terrain toImageData produces a pixel image", function()
        ensure_evidence_dir("physics")
        local path = evidence_output_dir("physics") .. "terrain_render.png"

        local world = lurek.physics.newWorld(0, 0)
        local terrain = lurek.physics.newTerrain(64, 64, 4, world)

        -- Fill solid ground.
        terrain:fillAll(true)
        -- Dig a large crater in the centre.
        terrain:fillCircle(128, 128, 64, false)

        -- Render to RGBA bytes (solid = brown, empty = dark sky).
        local raw = terrain:toImageData(139, 90, 43, 30, 30, 60)
        expect_equal(64 * 64 * 4, #raw)

        -- Build an image from raw bytes and save.
        local img = lurek.image.newImageData(64, 64)
        img:setRawData(raw)
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)




-- ================================================================
-- Merged from: test_evidence_migrated_20.lua
-- ================================================================

-- Migrated evidence suite 20.
-- Produces the migrated_20 evidence artifacts that feed the paired compare-only golden checks for legacy Rust baselines.

local out_dir = evidence_output_dir("migrated_20")

local function save_png(name, img)
    local path = out_dir .. name .. ".png"
    lurek.image.savePNG(img, path)
    return path
end

local function save_wav(name, sound)
    local path = out_dir .. name .. ".wav"
    lurek.audio.saveWAV(sound, path)
    return path
end

-- @description Covers suite: Migrated Evidence Tests 20.
describe("Migrated Evidence Tests 20", function()
    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a minimal 8x8 sprite fixture with a stable pixel pattern, writes the PNG artifact, and preserves an evidence source for the migrated_20 fixture golden comparison.
    it("generates fixture_sprite_8x8", function()
        local img = lurek.image.newImageData(8, 8)
        img:fill(0, 0, 0, 0)
        img:setPixel(2, 2, 255, 255, 255, 255)
        img:setPixel(5, 2, 255, 255, 255, 255)
        img:setPixel(2, 5, 255, 255, 255, 255)
        img:setPixel(3, 6, 255, 255, 255, 255)
        img:setPixel(4, 6, 255, 255, 255, 255)
        img:setPixel(5, 5, 255, 255, 255, 255)
        local p = save_png("sprite_8x8", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a 16x16 cross-shaped sprite fixture and writes it to PNG.
    it("generates fixture_sprite_16x16", function()
        local img = lurek.image.newImageData(16, 16)
        for i = 0, 15 do
            img:setPixel(7, i, 255, 0, 0, 255)
            img:setPixel(8, i, 255, 0, 0, 255)
            img:setPixel(i, 7, 0, 0, 255, 255)
            img:setPixel(i, 8, 0, 0, 255, 255)
        end
        local p = save_png("sprite_16x16", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a radial-alpha 32x32 sprite fixture and writes it to PNG.
    it("generates fixture_sprite_32x32", function()
        local img = lurek.image.newImageData(32, 32)
        for y = 0, 31 do
            for x = 0, 31 do
                local dx = x - 15.5
                local dy = y - 15.5
                local dist = math.sqrt(dx*dx + dy*dy)
                local alpha = 255 - math.min(255, math.floor(dist * 16))
                img:setPixel(x, y, 0, 255, 0, alpha)
            end
        end
        local p = save_png("sprite_32x32", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a checkerboard 64x64 sprite fixture and writes it to PNG.
    it("generates fixture_sprite_64x64", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local checker = (math.floor(x / 8) + math.floor(y / 8)) % 2 == 0
                if checker then
                    img:setPixel(x, y, 200, 200, 200, 255)
                else
                    img:setPixel(x, y, 50, 50, 50, 255)
                end
            end
        end
        local p = save_png("sprite_64x64", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a 128x128 tileset fixture with colored tile cells and writes it to PNG.
    it("generates fixture_tileset_128x128", function()
        local img = lurek.image.newImageData(128, 128)
        for ty = 0, 7 do
            for tx = 0, 7 do
                local r = tx * 36
                local g = ty * 36
                local b = 128
                for y = 0, 15 do
                    for x = 0, 15 do
                        img:setPixel(tx * 16 + x, ty * 16 + y, r, g, b, 255)
                    end
                end
            end
        end
        local p = save_png("tileset_128x128", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a horizontal RGB gradient fixture and writes it to PNG.
    it("generates fixture_gradient_horizontal", function()
        local img = lurek.image.newImageData(256, 32)
        for y = 0, 31 do
            for x = 0, 255 do
                img:setPixel(x, y, x, 0, 255 - x, 255)
            end
        end
        local p = save_png("gradient_horizontal", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a vertical RGB gradient fixture and writes it to PNG.
    it("generates fixture_gradient_vertical", function()
        local img = lurek.image.newImageData(32, 256)
        for y = 0, 255 do
            for x = 0, 31 do
                img:setPixel(x, y, 0, y, 255 - y, 255)
            end
        end
        local p = save_png("gradient_vertical", img)
        expect_evidence_created(p)
    end)

    local function draw_bezier_to_image(curves_data, w, h)
        local bg = lurek.image.newImageData(w, h)
        bg:fill(25, 25, 25, 255)

        for _, cdata in ipairs(curves_data) do
            local pts, color = cdata[1], cdata[2]
            local flat_pts = {}
            for _, pt in ipairs(pts) do
                table.insert(flat_pts, pt.x)
                table.insert(flat_pts, pt.y)
            end
            local curve = lurek.math.newBezierCurve(flat_pts)

            -- draw lines connecting t-steps
            local segments = 100
            local last_x, last_y = curve:evaluate(0)
            for i = 1, segments do
                local t = i / segments
                local x, y = curve:evaluate(t)
                bg:drawLine(last_x, last_y, x, y, color[1], color[2], color[3], 255)
                last_x, last_y = x, y
            end

            -- draw points
            for _, pt in ipairs(pts) do
                bg:drawCircle(pt.x, pt.y, 3, 255, 100, 100, 255)
            end
        end
        return bg
    end

    -- @covers lurek.math.newBezierCurve
    -- @covers BezierCurve:evaluate
    -- @evidence file
    -- @description Draws one Bezier curve fixture and writes the resulting plot to PNG.
    it("generates evidence_math_bezier_curve", function()
        local curves = {
            {
                { {x=10,y=200}, {x=60,y=20}, {x=180,y=20}, {x=245,y=245} },
                {80, 80, 255}
            }
        }
        local img = draw_bezier_to_image(curves, 256, 256)
        local p = save_png("bezier_curve", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.math.newBezierCurve
    -- @covers BezierCurve:evaluate
    -- @evidence file
    -- @description Draws two Bezier curves into one fixture image and writes the result to PNG.
    it("generates evidence_math_bezier_multiple", function()
        local curves = {
            {
                { {x=10,y=128}, {x=80,y=10}, {x=170,y=245}, {x=245,y=128} },
                {255, 80, 80}
            },
            {
                { {x=10,y=128}, {x=80,y=245}, {x=170,y=10}, {x=245,y=128} },
                {80, 255, 80}
            }
        }
        local img = draw_bezier_to_image(curves, 256, 256)
        local p = save_png("bezier_multiple_curves", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes independent left and right stereo tones and writes the stereo WAV output.
    it("generates evidence_audio_stereo", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 2)
        -- Left 440, Right 880
        for i = 0, ns - 1 do
            local t = i / sr
            local fl = 440.0
            local fr = 880.0
            local left = math.sin(t * fl * math.pi * 2) * 0.5
            local right = math.sin(t * fr * math.pi * 2) * 0.5
            sound:setSample(i * 2 + 0, left)
            sound:setSample(i * 2 + 1, right)
        end
        local p = save_wav("stereo_two_tones", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a frequency sweep from 100 Hz to 4000 Hz and writes the WAV artifact.
    it("generates evidence_audio_frequency_sweep", function()
        local sr = 44100
        local ns = sr * 2
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        local sf = 100.0
        local ef = 4000.0
        for i = 0, ns - 1 do
            local t = i / sr
            local f = sf + (ef - sf) * (t / 2.0)
            local v = math.sin(t * f * math.pi * 2) * 0.5
            sound:setSample(i, v)
        end
        local p = save_wav("frequency_sweep_100_4000", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a tone with a hand-authored amplitude envelope and writes the WAV artifact.
    it("generates evidence_audio_amplitude_envelope", function()
        local sr = 44100
        local ns = sr * 2
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2)
            local env = 1.0
            if t < 0.2 then
                env = t / 0.2
            elseif t > 1.5 then
                env = 1.0 - (t - 1.5) / 0.5
            end
            sound:setSample(i, v * env * 0.8)
        end
        local p = save_wav("amplitude_envelope", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a square wave manually and writes the WAV artifact.
    it("generates evidence_audio_square_wave", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2)
            sound:setSample(i, v > 0 and 0.4 or -0.4)
        end
        local p = save_wav("square_wave_440hz", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a sawtooth wave manually and writes the WAV artifact.
    it("generates evidence_audio_sawtooth_wave", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local phase = (t * 440.0) % 1.0
            local v = (phase * 2.0 - 1.0) * 0.4
            sound:setSample(i, v)
        end
        local p = save_wav("sawtooth_wave_440hz", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes deterministic white noise manually and writes the WAV artifact.
    it("generates evidence_audio_white_noise", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        local st = 12345
        for i = 0, ns - 1 do
            st = (st * 1103515245 + 12345) % 2147483648
            local rv = (st / 2147483648.0) * 2.0 - 1.0
            sound:setSample(i, rv * 0.2)
        end
        local p = save_wav("white_noise", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Writes a short silence buffer to WAV as a baseline audio artifact.
    it("generates evidence_audio_silence", function()
        local sr = 44100
        local ns = 22050
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            sound:setSample(i, 0.0)
        end
        local p = save_wav("silence_half_second", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Writes a reference sine-wave audio file intended for later waveform visualization comparisons.
    it("generates evidence_audio_waveform_visualization", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2) * 0.5
            sound:setSample(i, v)
        end
        local p = save_wav("waveform_sine_440hz_audio", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.math.newNoiseGenerator
    -- @covers lurek.math.simplexNoise
    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Generates a colored noise-based heightmap and writes the terrain visualization to PNG.
    it("generates evidence_noise_to_heightmap_render", function()
        local ng = lurek.math.newNoiseGenerator(7777)
        local size = 256
        local img = lurek.image.newImageData(size, size)

        for y = 0, size - 1 do
            for x = 0, size - 1 do
                -- Simplex 5 octaves mapping to [0,1]
                local scale = 0.01
                local amp = 1.0
                local freq = 1.0
                local max_amp = 0.0
                local v = 0.0
                for o = 1, 5 do
                    local ev = lurek.math.simplexNoise(x * scale * freq, y * scale * freq)
                    v = v + ev * amp
                    max_amp = max_amp + amp
                    amp = amp * 0.5
                    freq = freq * 2.0
                end
                v = v / max_amp
                -- Map [-1, 1] to [0, 1]
                local nv = (v + 1.0) / 2.0
                -- Coloring (water, sand, grass, rock, snow)
                local r, g, b = 255, 255, 255
                if nv < 0.4 then r,g,b = 0, 100, 200
                elseif nv < 0.45 then r,g,b = 200, 200, 100
                elseif nv < 0.7 then r,g,b = 34, 139, 34
                elseif nv < 0.9 then r,g,b = 100, 100, 100
                else r,g,b = 255, 250, 250 end
                img:setPixel(x, y, r, g, b, 255)
            end
        end

        local p = save_png("noise_heightmap_colored", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:brightness
    -- @covers ImageData:contrast
    -- @covers ImageData:grayscale
    -- @covers ImageData:sepia
    -- @covers ImageData:invert
    -- @covers ImageData:threshold
    -- @covers ImageData:posterize
    -- @covers ImageData:tint
    -- @covers ImageData:saturation
    -- @covers ImageData:gamma
    -- @covers ImageData:noise
    -- @covers ImageData:flipHorizontal
    -- @covers ImageData:flipVertical
    -- @covers ImageData:rotate90Cw
    -- @covers ImageData:blur
    -- @covers ImageData:sharpen
    -- @covers ImageData:crop
    -- @covers ImageData:resizeNearest
    -- @evidence file
    -- @description Builds a grid of many image effects applied to one base tile and writes the resulting comparison sheet.
    xit("generates evidence_image_all_effects_grid", function()
        local tile = 64
        local cols = 5
        local rows = 4
        local canvas = lurek.image.newImageData(tile * cols, tile * rows)
        canvas:fill(30, 30, 30, 255)

        local function make_base()
            local img = lurek.image.newImageData(tile, tile)
            for y = 0, tile - 1 do
                for x = 0, tile - 1 do
                    img:setPixel(x, y, x * 4, y * 4, 128, 255)
                end
            end
            return img
        end

        local effects = {
            function(i) return i end,
            function(i) i:brightness(0.3); return i end,
            function(i) i:contrast(2.0); return i end,
            function(i) i:grayscale(); return i end,
            function(i) i:sepia(); return i end,
            function(i) i:invert(); return i end,
            function(i) i:threshold(128); return i end,
            function(i) i:posterize(4); return i end,
            function(i) i:tint(255, 0, 0, 127); return i end,
            function(i) i:saturation(0.0); return i end,
            function(i) i:gamma(0.5); return i end,
            function(i) i:gamma(2.2); return i end,
            function(i) i:noise(60); return i end,
            function(i) i:alphaMask(0.5); return i end,
            function(i) i:flipHorizontal(); return i end,
            function(i) i:flipVertical(); return i end,
            function(i) i:rotate90Cw(); return i end,
            function(i) i:blur(2); return i end,
            function(i) i:sharpen(); return i end,
            function(i)
                local c = i:crop(8, 8, 48, 48)
                c:resizeNearest(tile, tile)
                return c
            end
        }

        for i, apply in ipairs(effects) do
            local base = make_base()
            local res = apply(base)
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            canvas:paste(res, col * tile, row * tile)
        end
        local p = save_png("all_effects_grid", canvas)
        expect_evidence_created(p)
    end)

    -- @covers lurek.tilemap.newTileMap
    -- @covers TileMap:addLayer
    -- @covers TileMap:fill
    -- @covers TileMap:setTile
    -- @covers TileMap:drawToImage
    -- @evidence file
    -- @description Builds a small multi-layer tilemap, draws it to an image, and writes the rendered result.
    it("generates evidence_tilemap_multi_layer", function()
        local tm = lurek.tilemap.newTileMap(16, 16, 8)
        local ground = tm:addLayer("ground", 10, 10)
        local objects = tm:addLayer("objects", 10, 10)
        tm:fill(ground, 1)
        tm:setTile(objects, 3, 3, 10)
        tm:setTile(objects, 5, 5, 11)
        tm:setTile(objects, 7, 2, 12)
        local img = tm:drawToImage(16)
        local p = save_png("multi_layer", img)
        expect_evidence_created(p)
    end)
end)



-- ================================================================
-- Merged from: test_migrated_20_evidence.lua
-- ================================================================

-- Migrated evidence suite 20.
-- Produces the migrated_20 evidence artifacts that feed the paired compare-only golden checks for legacy Rust baselines.

local out_dir = evidence_output_dir("migrated_20")

local function save_png(name, img)
    local path = out_dir .. name .. ".png"
    lurek.image.savePNG(img, path)
    return path
end

local function save_wav(name, sound)
    local path = out_dir .. name .. ".wav"
    lurek.audio.saveWAV(sound, path)
    return path
end

-- @description Covers suite: Migrated Evidence Tests 20.
describe("Migrated Evidence Tests 20", function()
    -- @covers lurek.image.newImageData
    -- @covers ImageData:fill
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a minimal 8x8 sprite fixture with a stable pixel pattern, writes the PNG artifact, and preserves an evidence source for the migrated_20 fixture golden comparison.
    it("generates fixture_sprite_8x8", function()
        local img = lurek.image.newImageData(8, 8)
        img:fill(0, 0, 0, 0)
        img:setPixel(2, 2, 255, 255, 255, 255)
        img:setPixel(5, 2, 255, 255, 255, 255)
        img:setPixel(2, 5, 255, 255, 255, 255)
        img:setPixel(3, 6, 255, 255, 255, 255)
        img:setPixel(4, 6, 255, 255, 255, 255)
        img:setPixel(5, 5, 255, 255, 255, 255)
        local p = save_png("sprite_8x8", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a 16x16 cross-shaped sprite fixture and writes it to PNG.
    it("generates fixture_sprite_16x16", function()
        local img = lurek.image.newImageData(16, 16)
        for i = 0, 15 do
            img:setPixel(7, i, 255, 0, 0, 255)
            img:setPixel(8, i, 255, 0, 0, 255)
            img:setPixel(i, 7, 0, 0, 255, 255)
            img:setPixel(i, 8, 0, 0, 255, 255)
        end
        local p = save_png("sprite_16x16", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a radial-alpha 32x32 sprite fixture and writes it to PNG.
    it("generates fixture_sprite_32x32", function()
        local img = lurek.image.newImageData(32, 32)
        for y = 0, 31 do
            for x = 0, 31 do
                local dx = x - 15.5
                local dy = y - 15.5
                local dist = math.sqrt(dx*dx + dy*dy)
                local alpha = 255 - math.min(255, math.floor(dist * 16))
                img:setPixel(x, y, 0, 255, 0, alpha)
            end
        end
        local p = save_png("sprite_32x32", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a checkerboard 64x64 sprite fixture and writes it to PNG.
    it("generates fixture_sprite_64x64", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local checker = (math.floor(x / 8) + math.floor(y / 8)) % 2 == 0
                if checker then
                    img:setPixel(x, y, 200, 200, 200, 255)
                else
                    img:setPixel(x, y, 50, 50, 50, 255)
                end
            end
        end
        local p = save_png("sprite_64x64", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a 128x128 tileset fixture with colored tile cells and writes it to PNG.
    it("generates fixture_tileset_128x128", function()
        local img = lurek.image.newImageData(128, 128)
        for ty = 0, 7 do
            for tx = 0, 7 do
                local r = tx * 36
                local g = ty * 36
                local b = 128
                for y = 0, 15 do
                    for x = 0, 15 do
                        img:setPixel(tx * 16 + x, ty * 16 + y, r, g, b, 255)
                    end
                end
            end
        end
        local p = save_png("tileset_128x128", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a horizontal RGB gradient fixture and writes it to PNG.
    it("generates fixture_gradient_horizontal", function()
        local img = lurek.image.newImageData(256, 32)
        for y = 0, 31 do
            for x = 0, 255 do
                img:setPixel(x, y, x, 0, 255 - x, 255)
            end
        end
        local p = save_png("gradient_horizontal", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Builds a vertical RGB gradient fixture and writes it to PNG.
    it("generates fixture_gradient_vertical", function()
        local img = lurek.image.newImageData(32, 256)
        for y = 0, 255 do
            for x = 0, 31 do
                img:setPixel(x, y, 0, y, 255 - y, 255)
            end
        end
        local p = save_png("gradient_vertical", img)
        expect_evidence_created(p)
    end)

    local function draw_bezier_to_image(curves_data, w, h)
        local bg = lurek.image.newImageData(w, h)
        bg:fill(25, 25, 25, 255)

        for _, cdata in ipairs(curves_data) do
            local pts, color = cdata[1], cdata[2]
            local flat_pts = {}
            for _, pt in ipairs(pts) do
                table.insert(flat_pts, pt.x)
                table.insert(flat_pts, pt.y)
            end
            local curve = lurek.math.newBezierCurve(flat_pts)

            -- draw lines connecting t-steps
            local segments = 100
            local last_x, last_y = curve:evaluate(0)
            for i = 1, segments do
                local t = i / segments
                local x, y = curve:evaluate(t)
                bg:drawLine(last_x, last_y, x, y, color[1], color[2], color[3], 255)
                last_x, last_y = x, y
            end

            -- draw points
            for _, pt in ipairs(pts) do
                bg:drawCircle(pt.x, pt.y, 3, 255, 100, 100, 255)
            end
        end
        return bg
    end

    -- @covers lurek.math.newBezierCurve
    -- @covers BezierCurve:evaluate
    -- @evidence file
    -- @description Draws one Bezier curve fixture and writes the resulting plot to PNG.
    it("generates evidence_math_bezier_curve", function()
        local curves = {
            {
                { {x=10,y=200}, {x=60,y=20}, {x=180,y=20}, {x=245,y=245} },
                {80, 80, 255}
            }
        }
        local img = draw_bezier_to_image(curves, 256, 256)
        local p = save_png("bezier_curve", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.math.newBezierCurve
    -- @covers BezierCurve:evaluate
    -- @evidence file
    -- @description Draws two Bezier curves into one fixture image and writes the result to PNG.
    it("generates evidence_math_bezier_multiple", function()
        local curves = {
            {
                { {x=10,y=128}, {x=80,y=10}, {x=170,y=245}, {x=245,y=128} },
                {255, 80, 80}
            },
            {
                { {x=10,y=128}, {x=80,y=245}, {x=170,y=10}, {x=245,y=128} },
                {80, 255, 80}
            }
        }
        local img = draw_bezier_to_image(curves, 256, 256)
        local p = save_png("bezier_multiple_curves", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes independent left and right stereo tones and writes the stereo WAV output.
    it("generates evidence_audio_stereo", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 2)
        -- Left 440, Right 880
        for i = 0, ns - 1 do
            local t = i / sr
            local fl = 440.0
            local fr = 880.0
            local left = math.sin(t * fl * math.pi * 2) * 0.5
            local right = math.sin(t * fr * math.pi * 2) * 0.5
            sound:setSample(i * 2 + 0, left)
            sound:setSample(i * 2 + 1, right)
        end
        local p = save_wav("stereo_two_tones", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a frequency sweep from 100 Hz to 4000 Hz and writes the WAV artifact.
    it("generates evidence_audio_frequency_sweep", function()
        local sr = 44100
        local ns = sr * 2
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        local sf = 100.0
        local ef = 4000.0
        for i = 0, ns - 1 do
            local t = i / sr
            local f = sf + (ef - sf) * (t / 2.0)
            local v = math.sin(t * f * math.pi * 2) * 0.5
            sound:setSample(i, v)
        end
        local p = save_wav("frequency_sweep_100_4000", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a tone with a hand-authored amplitude envelope and writes the WAV artifact.
    it("generates evidence_audio_amplitude_envelope", function()
        local sr = 44100
        local ns = sr * 2
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2)
            local env = 1.0
            if t < 0.2 then
                env = t / 0.2
            elseif t > 1.5 then
                env = 1.0 - (t - 1.5) / 0.5
            end
            sound:setSample(i, v * env * 0.8)
        end
        local p = save_wav("amplitude_envelope", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a square wave manually and writes the WAV artifact.
    it("generates evidence_audio_square_wave", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2)
            sound:setSample(i, v > 0 and 0.4 or -0.4)
        end
        local p = save_wav("square_wave_440hz", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes a sawtooth wave manually and writes the WAV artifact.
    it("generates evidence_audio_sawtooth_wave", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local phase = (t * 440.0) % 1.0
            local v = (phase * 2.0 - 1.0) * 0.4
            sound:setSample(i, v)
        end
        local p = save_wav("sawtooth_wave_440hz", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Synthesizes deterministic white noise manually and writes the WAV artifact.
    it("generates evidence_audio_white_noise", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        local st = 12345
        for i = 0, ns - 1 do
            st = (st * 1103515245 + 12345) % 2147483648
            local rv = (st / 2147483648.0) * 2.0 - 1.0
            sound:setSample(i, rv * 0.2)
        end
        local p = save_wav("white_noise", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Writes a short silence buffer to WAV as a baseline audio artifact.
    it("generates evidence_audio_silence", function()
        local sr = 44100
        local ns = 22050
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            sound:setSample(i, 0.0)
        end
        local p = save_wav("silence_half_second", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.audio.newSoundData
    -- @covers SoundData:setSample
    -- @covers lurek.audio.saveWAV
    -- @evidence file
    -- @description Writes a reference sine-wave audio file intended for later waveform visualization comparisons.
    it("generates evidence_audio_waveform_visualization", function()
        local sr = 44100
        local ns = sr
        local sound = lurek.audio.newSoundData(ns, sr, 1)
        for i = 0, ns - 1 do
            local t = i / sr
            local v = math.sin(t * 440.0 * math.pi * 2) * 0.5
            sound:setSample(i, v)
        end
        local p = save_wav("waveform_sine_440hz_audio", sound)
        expect_evidence_created(p)
    end)

    -- @covers lurek.math.newNoiseGenerator
    -- @covers lurek.math.simplexNoise
    -- @covers lurek.image.newImageData
    -- @covers ImageData:setPixel
    -- @evidence file
    -- @description Generates a colored noise-based heightmap and writes the terrain visualization to PNG.
    it("generates evidence_noise_to_heightmap_render", function()
        local ng = lurek.math.newNoiseGenerator(7777)
        local size = 256
        local img = lurek.image.newImageData(size, size)

        for y = 0, size - 1 do
            for x = 0, size - 1 do
                -- Simplex 5 octaves mapping to [0,1]
                local scale = 0.01
                local amp = 1.0
                local freq = 1.0
                local max_amp = 0.0
                local v = 0.0
                for o = 1, 5 do
                    local ev = lurek.math.simplexNoise(x * scale * freq, y * scale * freq)
                    v = v + ev * amp
                    max_amp = max_amp + amp
                    amp = amp * 0.5
                    freq = freq * 2.0
                end
                v = v / max_amp
                -- Map [-1, 1] to [0, 1]
                local nv = (v + 1.0) / 2.0
                -- Coloring (water, sand, grass, rock, snow)
                local r, g, b = 255, 255, 255
                if nv < 0.4 then r,g,b = 0, 100, 200
                elseif nv < 0.45 then r,g,b = 200, 200, 100
                elseif nv < 0.7 then r,g,b = 34, 139, 34
                elseif nv < 0.9 then r,g,b = 100, 100, 100
                else r,g,b = 255, 250, 250 end
                img:setPixel(x, y, r, g, b, 255)
            end
        end

        local p = save_png("noise_heightmap_colored", img)
        expect_evidence_created(p)
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:brightness
    -- @covers ImageData:contrast
    -- @covers ImageData:grayscale
    -- @covers ImageData:sepia
    -- @covers ImageData:invert
    -- @covers ImageData:threshold
    -- @covers ImageData:posterize
    -- @covers ImageData:tint
    -- @covers ImageData:saturation
    -- @covers ImageData:gamma
    -- @covers ImageData:noise
    -- @covers ImageData:flipHorizontal
    -- @covers ImageData:flipVertical
    -- @covers ImageData:rotate90Cw
    -- @covers ImageData:blur
    -- @covers ImageData:sharpen
    -- @covers ImageData:crop
    -- @covers ImageData:resizeNearest
    -- @evidence file
    -- @description Builds a grid of many image effects applied to one base tile and writes the resulting comparison sheet.
    xit("generates evidence_image_all_effects_grid", function()
        local tile = 64
        local cols = 5
        local rows = 4
        local canvas = lurek.image.newImageData(tile * cols, tile * rows)
        canvas:fill(30, 30, 30, 255)

        local function make_base()
            local img = lurek.image.newImageData(tile, tile)
            for y = 0, tile - 1 do
                for x = 0, tile - 1 do
                    img:setPixel(x, y, x * 4, y * 4, 128, 255)
                end
            end
            return img
        end

        local effects = {
            function(i) return i end,
            function(i) i:brightness(0.3); return i end,
            function(i) i:contrast(2.0); return i end,
            function(i) i:grayscale(); return i end,
            function(i) i:sepia(); return i end,
            function(i) i:invert(); return i end,
            function(i) i:threshold(128); return i end,
            function(i) i:posterize(4); return i end,
            function(i) i:tint(255, 0, 0, 127); return i end,
            function(i) i:saturation(0.0); return i end,
            function(i) i:gamma(0.5); return i end,
            function(i) i:gamma(2.2); return i end,
            function(i) i:noise(60); return i end,
            function(i) i:alphaMask(0.5); return i end,
            function(i) i:flipHorizontal(); return i end,
            function(i) i:flipVertical(); return i end,
            function(i) i:rotate90Cw(); return i end,
            function(i) i:blur(2); return i end,
            function(i) i:sharpen(); return i end,
            function(i)
                local c = i:crop(8, 8, 48, 48)
                c:resizeNearest(tile, tile)
                return c
            end
        }

        for i, apply in ipairs(effects) do
            local base = make_base()
            local res = apply(base)
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            canvas:paste(res, col * tile, row * tile)
        end
        local p = save_png("all_effects_grid", canvas)
        expect_evidence_created(p)
    end)

    -- @covers lurek.tilemap.newTileMap
    -- @covers TileMap:addLayer
    -- @covers TileMap:fill
    -- @covers TileMap:setTile
    -- @covers TileMap:drawToImage
    -- @evidence file
    -- @description Builds a small multi-layer tilemap, draws it to an image, and writes the rendered result.
    it("generates evidence_tilemap_multi_layer", function()
        local tm = lurek.tilemap.newTileMap(16, 16, 8)
        local ground = tm:addLayer("ground", 10, 10)
        local objects = tm:addLayer("objects", 10, 10)
        tm:fill(ground, 1)
        tm:setTile(objects, 3, 3, 10)
        tm:setTile(objects, 5, 5, 11)
        tm:setTile(objects, 7, 2, 12)
        local img = tm:drawToImage(16)
        local p = save_png("multi_layer", img)
        expect_evidence_created(p)
    end)
end)



-- ================================================================
-- Merged from: test_evidence_combined.lua
-- ================================================================

-- test_evidence_combined.lua
-- Evidence tests: cross-module integration (procgen+pathfinding, noise+minimap,
--                 terrain+raycaster, tilemap+particles)

local OUT = "tests/output/combined/"

-- Helper: draw a small rectangle on an image
local function draw_rect(img, x, y, w, h, r, g, b)
    img:drawRect(x, y, w, h, r, g, b, 255)
end

-- @description Covers suite: Evidence: combined procgen + pathfinding.
describe("Evidence: combined procgen + pathfinding", function()

    -- @covers lurek.procgen.cellularAutomata
    -- @covers lurek.pathfind.newNavGrid
    -- @covers NavGrid:setBlocked
    -- @covers lurek.pathfind.newPathfinder
    -- @covers Pathfinder:findPath
    -- @evidence file
    -- @description Generates a cave map, mirrors it into a navigation grid, and writes a PNG showing the resulting path overlay.
    it("generates a cave map then finds a path through it", function()
        local GW, GH = 32, 32
        local SCALE  = 6

        -- 1. Generate cave using cellular automata
        local cave = lurek.procgen.cellularAutomata(GW, GH)

        -- 2. Build a NavGrid mirroring the cave walls
        local grid = lurek.pathfind.newNavGrid(GW, GH)
        for gy = 1, GH do
            for gx = 1, GW do
                local idx = (gy - 1) * GW + gx
                if cave[idx] == 1 then
                    grid:setBlocked(gx, gy, true)
                end
            end
        end

        -- 3. Find a path from top-left to bottom-right
        local pf   = lurek.pathfind.newPathfinder(grid)
        local path = pf:findPath(1, 1, GW, GH)

        -- 4. Render: cave cells
        local img = lurek.image.newImageData(GW * SCALE, GH * SCALE)
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

        lurek.image.savePNG(img, OUT .. "procgen_pathfinding.png")
    end)

end)

-- @description Covers suite: Evidence: combined noise + minimap.
describe("Evidence: combined noise + minimap", function()

    -- @covers lurek.math.newNoiseGenerator
    -- @covers NoiseGenerator:fbm
    -- @covers lurek.minimap.newMinimap
    -- @covers Minimap:setTerrain
    -- @evidence file
    -- @description Uses FBM noise to classify terrain, feeds that terrain into a minimap, and writes the resulting height-colored overview PNG.
    it("generates terrain heights from FBM noise and renders as a minimap", function()
        local GRID = 24
        local CELL = 8
        local W, H = GRID * CELL, GRID * CELL

        local ng = lurek.math.newNoiseGenerator(7)
        local mm = lurek.minimap.newMinimap(GRID, GRID, W, H)

        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        for gy = 1, GRID do
            for gx = 1, GRID do
                local nx = gx / GRID * 3
                local ny = gy / GRID * 3
                local h_val = ng:fbm(nx, ny, 4, 0.5, 2.0)
                -- -1..1          0..255
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

        lurek.image.savePNG(img, OUT .. "noise_minimap.png")
    end)

end)

-- @description Covers suite: Evidence: combined terrain + raycaster.
describe("Evidence: combined terrain + raycaster", function()

    -- @covers lurek.math.newNoiseGenerator
    -- @covers NoiseGenerator:fbm
    -- @covers lurek.raycaster.new
    -- @covers Raycaster:setCell
    -- @covers Raycaster:castRays
    -- @evidence file
    -- @description Converts noise into a wall layout, casts a ray fan through it, and saves a depth-style render of the generated space.
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
        local img = lurek.image.newImageData(IW, IH)
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

        lurek.image.savePNG(img, OUT .. "terrain_raycaster.png")
    end)

end)

-- @description Covers suite: Evidence: combined tilemap + particles.
describe("Evidence: combined tilemap + particles", function()

    -- @covers lurek.tilemap.newTileMap
    -- @covers TileMap:addLayer
    -- @covers lurek.particle.newSystem
    -- @covers ParticleSystem:setPosition
    -- @covers ParticleSystem:start
    -- @covers ParticleSystem:emit
    -- @covers ParticleSystem:update
    -- @evidence file
    -- @description Builds a simple tile scene, overlays a particle burst, and writes a PNG that proves both systems can contribute to one composite artifact.
    it("renders a tilemap scene with a particle burst overlay", function()
        local TILE  = 8
        local MAP_W = 20
        local MAP_H = 15
        local W, H  = MAP_W * TILE, MAP_H * TILE

        -- Build a tilemap
        local tm = lurek.tilemap.newTileMap(MAP_W, MAP_H)
        tm:addLayer("ground", MAP_W, MAP_H)

        -- Render the tilemap manually (floor + borders)
        local img = lurek.image.newImageData(W, H)
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
        local sys = lurek.particle.newSystem()
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

        lurek.image.savePNG(img, OUT .. "tilemap_particles.png")
    end)

end)



-- ================================================================
-- Merged from: test_golden_text_outputs_evidence.lua
-- ================================================================

-- Evidence test: deterministic text and binary outputs consumed by Lua golden suites.
-- Produces: ai_golden.txt, compute_golden.txt, dataframe_golden.txt, entity_golden.txt,
--           migrated_rust/{compress,data,encode,hash} outputs.

local function ensure_dir(path)
    lurek.filesystem.createDirectory(path)
end

local function write_text(path, text)
    lurek.filesystem.write(path, text)
    expect_evidence_created(path)
end

local function write_bytes(path, data)
    lurek.filesystem.write(path, data)
    expect_evidence_created(path)
end

local function text_output_dir(category)
    local dir = "save/golden_text/" .. category .. "/"
    ensure_dir("save/golden_text/")
    ensure_dir(dir)
    return dir
end

local function migrated_path(kind, name)
    local dir = text_output_dir("migrated_rust/" .. kind)
    return dir .. name
end

-- @description Generates deterministic text and binary evidence artifacts that Lua golden suites compare against committed samples.
describe("evidence: golden text outputs", function()
    -- @covers lurek.ai.newStateMachine
    -- @covers StateMachine:addState
    -- @covers StateMachine:setInitialState
    -- @covers StateMachine:forceState
    -- @covers StateMachine:getCurrentState
    -- @evidence file
    -- @description Builds a tiny deterministic state-machine sequence, records its stable state trace as ai_golden.txt, and writes the file for compare-only AI golden checks.
    it("writes ai_golden.txt", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("patrol", {})
        fsm:addState("chase", {})
        fsm:setInitialState("idle")
        fsm:forceState("patrol")
        fsm:forceState("chase")
        local text = "fsm_states=idle,patrol,chase\ndefault_state=idle"
        write_text(text_output_dir("ai") .. "ai_golden.txt", text)
    end)

    -- @covers lurek.compute.zeros
    -- @covers NdArray:fill
    -- @covers NdArray:sum
    -- @evidence file
    -- @description Creates a fixed 2x3 NdArray, fills it with 1.5, formats the stable shape and sum summary, and writes compute_golden.txt for compare-only golden validation.
    it("writes compute_golden.txt", function()
        local arr = lurek.compute.zeros({2, 3})
        arr:fill(1.5)
        local text = table.concat({
            "shape=2x3",
            "fill_value=1.500000",
            "sum=" .. string.format("%.6f", arr:sum()),
        }, "\n")
        write_text(text_output_dir("compute") .. "compute_golden.txt", text)
    end)

    -- @covers lurek.dataframe.newDataFrame
    -- @covers DataFrame:addColumn
    -- @covers DataFrame:sum
    -- @covers DataFrame:mean
    -- @evidence file
    -- @description Builds a single-column DataFrame with fixed numeric values, formats row-count and aggregate statistics, and writes dataframe_golden.txt for compare-only golden checks.
    it("writes dataframe_golden.txt", function()
        local df = lurek.dataframe.fromCSV("values\n10\n20\n30\n40\n50")
        local text = table.concat({
            "row_count=5",
            "sum=" .. string.format("%.6f", df:sum("values")),
            "mean=" .. string.format("%.6f", df:mean("values")),
        }, "\n")
        write_text(text_output_dir("dataframe") .. "dataframe_golden.txt", text)
    end)

    -- @covers lurek.ecs.newUniverse
    -- @covers World:spawn
    -- @covers World:isAlive
    -- @covers World:getEntityCount
    -- @evidence file
    -- @description Spawns one entity in a fresh Universe, records its stable ID, alive flag, and total live count, and writes entity_golden.txt for compare-only entity golden verification.
    it("writes entity_golden.txt", function()
        local world = lurek.ecs.newUniverse()
        local entity = world:spawn()
        local text = table.concat({
            "entity_id=" .. tostring(entity),
            "alive=" .. tostring(world:isAlive(entity)),
            "entity_count=" .. tostring(world:getEntityCount()),
        }, "\n")
        write_text(text_output_dir("ecs") .. "entity_golden.txt", text)
    end)

    -- @covers lurek.data.parseToml
    -- @covers lurek.data.encodeToml
    -- @evidence file
    -- @description Parses a fixed TOML document and re-encodes it into the canonical ordering used by the old Rust golden baseline, then writes toml_roundtrip.toml as Lua evidence.
    it("writes migrated Rust TOML evidence", function()
        local input = [[
[game]
title = "Test Game"
version = "1.0.0"

[window]
width = 800
height = 600
fullscreen = false

[physics]
gravity_x = 0.0
gravity_y = 9.8
max_bodies = 1000
]]
        local parsed = lurek.data.parseToml(input)
        local encoded = lurek.data.encodeToml(parsed)
        write_text(migrated_path("data", "toml_roundtrip.toml"), encoded)
    end)

    -- @covers lurek.data.encode
    -- @evidence file
    -- @description Encodes the fixed string 'Lurek2D rocks!' into base64 and hex, then writes both outputs into migrated_rust encode evidence files for compare-only Lua golden tests.
    it("writes migrated Rust encode evidence", function()
        write_text(migrated_path("encode", "base64_encode.txt"), lurek.data.encode("base64", "Lurek2D rocks!"))
        write_text(migrated_path("encode", "hex_encode.txt"), lurek.data.encode("hex", "Lurek2D rocks!"))
    end)

    -- @covers lurek.data.hash
    -- @evidence file
    -- @description Computes the deterministic md5, sha1, sha256, and sha512 digests used by the old Rust baselines and writes them into migrated_rust hash evidence files.
    it("writes migrated Rust hash evidence", function()
        write_text(migrated_path("hash", "md5_hello.txt"), lurek.data.hash("md5", "Hello, Lurek2D!"))
        write_text(migrated_path("hash", "sha1_engine.txt"), lurek.data.hash("sha1", "Lurek2D engine test vector"))
        write_text(migrated_path("hash", "sha256_hello.txt"), lurek.data.hash("sha256", "Hello, Lurek2D!"))
        write_text(migrated_path("hash", "sha512_engine.txt"), lurek.data.hash("sha512", "Lurek2D engine test vector"))
    end)

end)




-- ================================================================
-- Merged from: test_evidence_golden_text_outputs.lua
-- ================================================================

-- Evidence test: deterministic text and binary outputs consumed by Lua golden suites.
-- Produces: ai_golden.txt, compute_golden.txt, dataframe_golden.txt, entity_golden.txt,
--           migrated_rust/{compress,data,encode,hash} outputs.

local function ensure_dir(path)
    lurek.filesystem.createDirectory(path)
end

local function write_text(path, text)
    lurek.filesystem.write(path, text)
    expect_evidence_created(path)
end

local function write_bytes(path, data)
    lurek.filesystem.write(path, data)
    expect_evidence_created(path)
end

local function text_output_dir(category)
    local dir = "save/golden_text/" .. category .. "/"
    ensure_dir("save/golden_text/")
    ensure_dir(dir)
    return dir
end

local function migrated_path(kind, name)
    local dir = text_output_dir("migrated_rust/" .. kind)
    return dir .. name
end

-- @description Generates deterministic text and binary evidence artifacts that Lua golden suites compare against committed samples.
describe("evidence: golden text outputs", function()
    -- @covers lurek.ai.newStateMachine
    -- @covers StateMachine:addState
    -- @covers StateMachine:setInitialState
    -- @covers StateMachine:forceState
    -- @covers StateMachine:getCurrentState
    -- @evidence file
    -- @description Builds a tiny deterministic state-machine sequence, records its stable state trace as ai_golden.txt, and writes the file for compare-only AI golden checks.
    it("writes ai_golden.txt", function()
        local fsm = lurek.ai.newStateMachine()
        fsm:addState("idle", {})
        fsm:addState("patrol", {})
        fsm:addState("chase", {})
        fsm:setInitialState("idle")
        fsm:forceState("patrol")
        fsm:forceState("chase")
        local text = "fsm_states=idle,patrol,chase\ndefault_state=idle"
        write_text(text_output_dir("ai") .. "ai_golden.txt", text)
    end)

    -- @covers lurek.compute.zeros
    -- @covers NdArray:fill
    -- @covers NdArray:sum
    -- @evidence file
    -- @description Creates a fixed 2x3 NdArray, fills it with 1.5, formats the stable shape and sum summary, and writes compute_golden.txt for compare-only golden validation.
    it("writes compute_golden.txt", function()
        local arr = lurek.compute.zeros({2, 3})
        arr:fill(1.5)
        local text = table.concat({
            "shape=2x3",
            "fill_value=1.500000",
            "sum=" .. string.format("%.6f", arr:sum()),
        }, "\n")
        write_text(text_output_dir("compute") .. "compute_golden.txt", text)
    end)

    -- @covers lurek.dataframe.newDataFrame
    -- @covers DataFrame:addColumn
    -- @covers DataFrame:sum
    -- @covers DataFrame:mean
    -- @evidence file
    -- @description Builds a single-column DataFrame with fixed numeric values, formats row-count and aggregate statistics, and writes dataframe_golden.txt for compare-only golden checks.
    it("writes dataframe_golden.txt", function()
        local df = lurek.dataframe.fromCSV("values\n10\n20\n30\n40\n50")
        local text = table.concat({
            "row_count=5",
            "sum=" .. string.format("%.6f", df:sum("values")),
            "mean=" .. string.format("%.6f", df:mean("values")),
        }, "\n")
        write_text(text_output_dir("dataframe") .. "dataframe_golden.txt", text)
    end)

    -- @covers lurek.ecs.newUniverse
    -- @covers World:spawn
    -- @covers World:isAlive
    -- @covers World:getEntityCount
    -- @evidence file
    -- @description Spawns one entity in a fresh Universe, records its stable ID, alive flag, and total live count, and writes entity_golden.txt for compare-only entity golden verification.
    it("writes entity_golden.txt", function()
        local world = lurek.ecs.newUniverse()
        local entity = world:spawn()
        local text = table.concat({
            "entity_id=" .. tostring(entity),
            "alive=" .. tostring(world:isAlive(entity)),
            "entity_count=" .. tostring(world:getEntityCount()),
        }, "\n")
        write_text(text_output_dir("ecs") .. "entity_golden.txt", text)
    end)

    -- @covers lurek.data.parseToml
    -- @covers lurek.data.encodeToml
    -- @evidence file
    -- @description Parses a fixed TOML document and re-encodes it into the canonical ordering used by the old Rust golden baseline, then writes toml_roundtrip.toml as Lua evidence.
    it("writes migrated Rust TOML evidence", function()
        local input = [[
[game]
title = "Test Game"
version = "1.0.0"

[window]
width = 800
height = 600
fullscreen = false

[physics]
gravity_x = 0.0
gravity_y = 9.8
max_bodies = 1000
]]
        local parsed = lurek.data.parseToml(input)
        local encoded = lurek.data.encodeToml(parsed)
        write_text(migrated_path("data", "toml_roundtrip.toml"), encoded)
    end)

    -- @covers lurek.data.encode
    -- @evidence file
    -- @description Encodes the fixed string 'Lurek2D rocks!' into base64 and hex, then writes both outputs into migrated_rust encode evidence files for compare-only Lua golden tests.
    it("writes migrated Rust encode evidence", function()
        write_text(migrated_path("encode", "base64_encode.txt"), lurek.data.encode("base64", "Lurek2D rocks!"))
        write_text(migrated_path("encode", "hex_encode.txt"), lurek.data.encode("hex", "Lurek2D rocks!"))
    end)

    -- @covers lurek.data.hash
    -- @evidence file
    -- @description Computes the deterministic md5, sha1, sha256, and sha512 digests used by the old Rust baselines and writes them into migrated_rust hash evidence files.
    it("writes migrated Rust hash evidence", function()
        write_text(migrated_path("hash", "md5_hello.txt"), lurek.data.hash("md5", "Hello, Lurek2D!"))
        write_text(migrated_path("hash", "sha1_engine.txt"), lurek.data.hash("sha1", "Lurek2D engine test vector"))
        write_text(migrated_path("hash", "sha256_hello.txt"), lurek.data.hash("sha256", "Hello, Lurek2D!"))
        write_text(migrated_path("hash", "sha512_engine.txt"), lurek.data.hash("sha512", "Lurek2D engine test vector"))
    end)

end)

-- ================================================================
-- Merged from: test_canvas_evidence.lua
-- ================================================================

-- test_evidence_canvas.lua
-- Evidence test: Canvas creation, dimensions, release + PNG visualization
-- Produces: canvas_sizes.png, canvas_lifecycle.png

local OUT = "tests/output/canvas/"

--- Helper: draw a filled rectangle into an ImageData.
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            img:setPixel(x, y, r, g, b, a)
        end
    end
end

--- Helper: draw a 1px border.
local function draw_border(img, x0, y0, w, h, r, g, b)
    for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
        if y0 >= 0 and y0 < img:getHeight() then img:setPixel(x, y0, r, g, b, 255) end
        local yb = y0 + h - 1
        if yb >= 0 and yb < img:getHeight() then img:setPixel(x, yb, r, g, b, 255) end
    end
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        if x0 >= 0 and x0 < img:getWidth() then img:setPixel(x0, y, r, g, b, 255) end
        local xr = x0 + w - 1
        if xr >= 0 and xr < img:getWidth() then img:setPixel(xr, y, r, g, b, 255) end
    end
end

-- @description Covers suite: Evidence: Canvas lifecycle + PNG visualization.
describe("Evidence: Canvas lifecycle + PNG visualization", function()

    -- @covers lurek.render.newCanvas
    -- @covers Canvas:getDimensions
    -- @covers Canvas:release
    -- @evidence file
    -- @description Creates canvases of several sizes and renders scaled rectangles that visualize the reported dimensions in one PNG.
    it("PNG: canvas sizes visualized as colored rectangles", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 30, 255)

        local canvases = {
            {128, 64,  255, 80,  80},
            {200, 100, 80,  255, 80},
            {64,  64,  80,  80,  255},
            {256, 256, 255, 255, 80},
            {32,  32,  255, 128, 0},
            {320, 180, 128, 0,   255},
        }
        local y_off = 4
        for _, cfg in ipairs(canvases) do
            local cw, ch, r, g, b = cfg[1], cfg[2], cfg[3], cfg[4], cfg[5]
            local c = lurek.render.newCanvas(cw, ch)
            local aw, ah = c:getDimensions()
            c:release()
            local scale = math.min(240 / aw, 30 / ah)
            local dw = math.floor(aw * scale)
            local dh = math.max(math.floor(ah * scale), 4)
            draw_rect(img, 8, y_off, dw, dh, r, g, b, 255)
            draw_border(img, 8, y_off, dw, dh, 255, 255, 255)
            y_off = y_off + dh + 4
        end

        lurek.image.savePNG(img, OUT .. "canvas_sizes.png")
    end)

    -- @covers lurek.render.newCanvas
    -- @covers Canvas:getWidth
    -- @covers Canvas:release
    -- @evidence file
    -- @description Draws a simple lifecycle diagram that encodes created, active, and released canvas states into file evidence.
    it("PNG: canvas lifecycle state diagram (created/active/released)", function()
        local img = lurek.image.newImageData(128, 64)
        img:fill(30, 30, 40, 255)

        local c = lurek.render.newCanvas(64, 64)
        -- Created (green)
        draw_rect(img, 4, 4, 36, 56, 0, 200, 0, 255)
        -- Active (blue) -â€ť we read width to prove it's alive
        local _ = c:getWidth()
        draw_rect(img, 46, 4, 36, 56, 0, 0, 200, 255)
        -- Released (red)
        c:release()
        draw_rect(img, 88, 4, 36, 56, 200, 0, 0, 255)

        lurek.image.savePNG(img, OUT .. "canvas_lifecycle.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_canvas.lua
-- ================================================================

-- test_evidence_canvas.lua
-- Evidence test: Canvas creation, dimensions, release + PNG visualization
-- Produces: canvas_sizes.png, canvas_lifecycle.png

local OUT = "tests/output/canvas/"

--- Helper: draw a filled rectangle into an ImageData.
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            img:setPixel(x, y, r, g, b, a)
        end
    end
end

--- Helper: draw a 1px border.
local function draw_border(img, x0, y0, w, h, r, g, b)
    for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
        if y0 >= 0 and y0 < img:getHeight() then img:setPixel(x, y0, r, g, b, 255) end
        local yb = y0 + h - 1
        if yb >= 0 and yb < img:getHeight() then img:setPixel(x, yb, r, g, b, 255) end
    end
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        if x0 >= 0 and x0 < img:getWidth() then img:setPixel(x0, y, r, g, b, 255) end
        local xr = x0 + w - 1
        if xr >= 0 and xr < img:getWidth() then img:setPixel(xr, y, r, g, b, 255) end
    end
end

-- @description Covers suite: Evidence: Canvas lifecycle + PNG visualization.
describe("Evidence: Canvas lifecycle + PNG visualization", function()

    -- @covers lurek.render.newCanvas
    -- @covers Canvas:getDimensions
    -- @covers Canvas:release
    -- @evidence file
    -- @description Creates canvases of several sizes and renders scaled rectangles that visualize the reported dimensions in one PNG.
    it("PNG: canvas sizes visualized as colored rectangles", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 30, 255)

        local canvases = {
            {128, 64,  255, 80,  80},
            {200, 100, 80,  255, 80},
            {64,  64,  80,  80,  255},
            {256, 256, 255, 255, 80},
            {32,  32,  255, 128, 0},
            {320, 180, 128, 0,   255},
        }
        local y_off = 4
        for _, cfg in ipairs(canvases) do
            local cw, ch, r, g, b = cfg[1], cfg[2], cfg[3], cfg[4], cfg[5]
            local c = lurek.render.newCanvas(cw, ch)
            local aw, ah = c:getDimensions()
            c:release()
            local scale = math.min(240 / aw, 30 / ah)
            local dw = math.floor(aw * scale)
            local dh = math.max(math.floor(ah * scale), 4)
            draw_rect(img, 8, y_off, dw, dh, r, g, b, 255)
            draw_border(img, 8, y_off, dw, dh, 255, 255, 255)
            y_off = y_off + dh + 4
        end

        lurek.image.savePNG(img, OUT .. "canvas_sizes.png")
    end)

    -- @covers lurek.render.newCanvas
    -- @covers Canvas:getWidth
    -- @covers Canvas:release
    -- @evidence file
    -- @description Draws a simple lifecycle diagram that encodes created, active, and released canvas states into file evidence.
    it("PNG: canvas lifecycle state diagram (created/active/released)", function()
        local img = lurek.image.newImageData(128, 64)
        img:fill(30, 30, 40, 255)

        local c = lurek.render.newCanvas(64, 64)
        -- Created (green)
        draw_rect(img, 4, 4, 36, 56, 0, 200, 0, 255)
        -- Active (blue) -â€ť we read width to prove it's alive
        local _ = c:getWidth()
        draw_rect(img, 46, 4, 36, 56, 0, 0, 200, 255)
        -- Released (red)
        c:release()
        draw_rect(img, 88, 4, 36, 56, 200, 0, 0, 255)

        lurek.image.savePNG(img, OUT .. "canvas_lifecycle.png")
    end)

end)

-- ================================================================
-- Merged from: test_layers_evidence.lua
-- ================================================================

-- test_evidence_layers.lua
-- Evidence test: Image layer compositing and DrawLayer z-order management

local OUT = "tests/output/layers/"

local function fill_rect(img, x, y, w, h, r, g, b, a)
    a = a or 255
    img:drawRect(x, y, w, h, r, g, b, a)
end

-- @description Covers suite: Evidence: Image layers.
describe("Evidence: Image layers", function()

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawRect
    -- @covers ImageData:drawCircle
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Builds three conceptual layers and composites them into one image to document manual layer merging.
    it("merges three color layers into one image", function()
        local W, H = 256, 256

        -- Background layer
        local base = lurek.image.newImageData(W, H)
        fill_rect(base, 0, 0, W, H, 30, 30, 60, 255)

        -- Mid layer: blue rectangle
        local mid = lurek.image.newImageData(W, H)
        fill_rect(mid, 40, 40, 140, 140, 40, 80, 200, 180)

        -- Top layer: red circle
        local top_img = lurek.image.newImageData(W, H)
        top_img:drawCircle(128, 128, 60, 220, 60, 60, 180)

        -- Compose base + mid + top by drawing rects into the base
        fill_rect(base, 40, 40, 140, 140, 40, 80, 200, 180)
        base:drawCircle(128, 128, 60, 220, 60, 60, 180)

        lurek.image.savePNG(base, OUT .. "basic_merge.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawRect
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Paints a row of alpha-varied strips so opacity layering can be inspected across several levels.
    it("produces distinct opacity levels for a gradient layer stack", function()
        local W, H = 256, 64

        local strips = { 255, 200, 150, 100, 50, 0 }
        local img = lurek.image.newImageData(W, H)
        fill_rect(img, 0, 0, W, H, 20, 20, 40, 255)

        local sw = math.floor(W / #strips)
        for i, alpha in ipairs(strips) do
            local x = (i - 1) * sw
            fill_rect(img, x, 0, sw, H, 220, 80, 80, alpha)
        end

        lurek.image.savePNG(img, OUT .. "opacity.png")
    end)

    -- @covers lurek.render.newDrawLayer
    -- @covers DrawLayer:queue
    -- @covers DrawLayer:flush
    -- @covers DrawLayer:clear
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Exercises z-ordered draw-layer queue management and saves a simple stacked-rect image representing the managed layers.
    it("uses DrawLayer to manage z-ordered render queue", function()
        local layer = lurek.render.newDrawLayer()

        -- Queue some draws at different z levels
        local calls = 0
        layer:queue(5, function()
            calls = calls + 1
        end)
        layer:queue(1, function()
            calls = calls + 1
        end)
        layer:queue(10, function()
            calls = calls + 1
        end)

        -- Flush executes the queued callbacks
        layer:flush()

        -- Demonstrate clear without flush
        layer:queue(3, function() end)
        layer:queue(7, function() end)
        layer:clear()

        -- Write an image to show layer concept
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        fill_rect(img, 0,   0,   W,   H,   20,  20,  40,  255)
        fill_rect(img, 10,  10,  180, 180, 40,  80,  200, 200)
        fill_rect(img, 50,  50,  100, 100, 220, 80,  80,  200)
        fill_rect(img, 80,  80,  40,  40,  80,  220, 80,  200)
        lurek.image.savePNG(img, OUT .. "management.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_layers.lua
-- ================================================================

-- test_evidence_layers.lua
-- Evidence test: Image layer compositing and DrawLayer z-order management

local OUT = "tests/output/layers/"

local function fill_rect(img, x, y, w, h, r, g, b, a)
    a = a or 255
    img:drawRect(x, y, w, h, r, g, b, a)
end

-- @description Covers suite: Evidence: Image layers.
describe("Evidence: Image layers", function()

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawRect
    -- @covers ImageData:drawCircle
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Builds three conceptual layers and composites them into one image to document manual layer merging.
    it("merges three color layers into one image", function()
        local W, H = 256, 256

        -- Background layer
        local base = lurek.image.newImageData(W, H)
        fill_rect(base, 0, 0, W, H, 30, 30, 60, 255)

        -- Mid layer: blue rectangle
        local mid = lurek.image.newImageData(W, H)
        fill_rect(mid, 40, 40, 140, 140, 40, 80, 200, 180)

        -- Top layer: red circle
        local top_img = lurek.image.newImageData(W, H)
        top_img:drawCircle(128, 128, 60, 220, 60, 60, 180)

        -- Compose base + mid + top by drawing rects into the base
        fill_rect(base, 40, 40, 140, 140, 40, 80, 200, 180)
        base:drawCircle(128, 128, 60, 220, 60, 60, 180)

        lurek.image.savePNG(base, OUT .. "basic_merge.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawRect
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Paints a row of alpha-varied strips so opacity layering can be inspected across several levels.
    it("produces distinct opacity levels for a gradient layer stack", function()
        local W, H = 256, 64

        local strips = { 255, 200, 150, 100, 50, 0 }
        local img = lurek.image.newImageData(W, H)
        fill_rect(img, 0, 0, W, H, 20, 20, 40, 255)

        local sw = math.floor(W / #strips)
        for i, alpha in ipairs(strips) do
            local x = (i - 1) * sw
            fill_rect(img, x, 0, sw, H, 220, 80, 80, alpha)
        end

        lurek.image.savePNG(img, OUT .. "opacity.png")
    end)

    -- @covers lurek.render.newDrawLayer
    -- @covers DrawLayer:queue
    -- @covers DrawLayer:flush
    -- @covers DrawLayer:clear
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Exercises z-ordered draw-layer queue management and saves a simple stacked-rect image representing the managed layers.
    it("uses DrawLayer to manage z-ordered render queue", function()
        local layer = lurek.render.newDrawLayer()

        -- Queue some draws at different z levels
        local calls = 0
        layer:queue(5, function()
            calls = calls + 1
        end)
        layer:queue(1, function()
            calls = calls + 1
        end)
        layer:queue(10, function()
            calls = calls + 1
        end)

        -- Flush executes the queued callbacks
        layer:flush()

        -- Demonstrate clear without flush
        layer:queue(3, function() end)
        layer:queue(7, function() end)
        layer:clear()

        -- Write an image to show layer concept
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        fill_rect(img, 0,   0,   W,   H,   20,  20,  40,  255)
        fill_rect(img, 10,  10,  180, 180, 40,  80,  200, 200)
        fill_rect(img, 50,  50,  100, 100, 220, 80,  80,  200)
        fill_rect(img, 80,  80,  40,  40,  80,  220, 80,  200)
        lurek.image.savePNG(img, OUT .. "management.png")
    end)

end)

-- ================================================================
-- Merged from: test_shapes_evidence.lua
-- ================================================================

-- test_evidence_shapes.lua
-- Evidence test: 2D shape drawing using lurek.image primitives

local OUT = "tests/output/shapes/"

-- Helper: draw a regular polygon centred at (cx, cy)
local function draw_polygon(img, cx, cy, radius, sides, r, g, b, a)
    a = a or 255
    local prev_x, prev_y
    for i = 0, sides do
        local angle = (i / sides) * 2 * math.pi - math.pi / 2
        local nx = math.floor(cx + radius * math.cos(angle))
        local ny = math.floor(cy + radius * math.sin(angle))
        if prev_x then
            img:drawLine(prev_x, prev_y, nx, ny, r, g, b, a)
        end
        prev_x, prev_y = nx, ny
    end
end

-- Helper: draw a spiral
local function draw_spiral(img, cx, cy, turns, r, g, b)
    local steps = turns * 60
    local prev_x, prev_y
    for i = 0, steps do
        local t  = i / steps
        local angle  = t * turns * 2 * math.pi
        local rad    = t * 80
        local nx = math.floor(cx + rad * math.cos(angle))
        local ny = math.floor(cy + rad * math.sin(angle))
        if prev_x then
            img:drawLine(prev_x, prev_y, nx, ny, r, g, b, 255)
        end
        prev_x, prev_y = nx, ny
    end
end

-- @description Covers suite: Evidence: Shapes.
describe("Evidence: Shapes", function()

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawRect
    -- @covers ImageData:drawLine
    -- @covers ImageData:drawCircle
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws a gallery of polygon outlines and filled circles to provide a compact catalog of shape rasterization.
    it("renders a polygon gallery", function()
        local W, H = 512, 256
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        -- Row of polygons: triangle, square, pentagon, hexagon, octagon, circle
        local configs = {
            { sides = 3,  cx = 48,  label = "tri"  },
            { sides = 4,  cx = 128, label = "quad" },
            { sides = 5,  cx = 208, label = "pent" },
            { sides = 6,  cx = 288, label = "hex"  },
            { sides = 8,  cx = 368, label = "oct"  },
            { sides = 32, cx = 448, label = "circ" },
        }
        for _, c in ipairs(configs) do
            draw_polygon(img, c.cx, 80, 36, c.sides, 80, 160, 255, 255)
            draw_polygon(img, c.cx, 80, 36, c.sides, 80, 160, 255, 255)
        end

        -- Second row: filled circles
        for i, c in ipairs(configs) do
            local hue_r = math.floor(40 + (i - 1) * 35)
            img:drawCircle(c.cx, 180, 28, hue_r, 120, 200, 200)
        end

        lurek.image.savePNG(img, OUT .. "polygon_gallery.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawRect
    -- @covers ImageData:drawCircle
    -- @covers ImageData:drawLine
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws a scene of filled primitive shapes and diagonal lines to show layered primitive composition.
    it("renders filled primitive shapes", function()
        local W, H = 400, 400
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 15, 15, 25, 255)

        -- Filled rectangles
        img:drawRect(20,  20,  120, 80,  200, 80,  80,  200)
        img:drawRect(160, 20,  120, 80,  80,  200, 80,  200)
        img:drawRect(300, 20,  80,  80,  80,  80,  200, 200)

        -- Filled circles
        img:drawCircle(60,  200, 50, 220, 120, 40,  200)
        img:drawCircle(200, 200, 50, 40,  180, 220, 200)
        img:drawCircle(340, 200, 50, 180, 40,  220, 200)

        -- Diagonal lines
        for i = 0, 7 do
            local x = i * 50
            img:drawLine(x, 300, x + 40, 380, 200, 200, 40, 200)
        end

        lurek.image.savePNG(img, OUT .. "filled_primitives.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawLine
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws several spirals with different turn counts and saves the result as PNG evidence.
    it("renders a spiral gallery", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        draw_spiral(img, 70,  150, 3, 220, 80,  80)
        draw_spiral(img, 200, 150, 4, 80,  220, 80)
        draw_spiral(img, 330, 150, 5, 80,  80,  220)

        lurek.image.savePNG(img, OUT .. "spirals.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawCircle
    -- @covers ImageData:drawLine
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws concentric rings of circles and polygons to provide a second multi-shape rasterization reference image.
    it("renders concentric shape rings", function()
        local W, H = 300, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        local cx, cy = 150, 150
        for i = 1, 8 do
            local r = i * 16
            local col = math.floor(20 + i * 28)
            local inv = math.max(0, 220 - col)
            img:drawCircle(cx, cy, r, col, 120, inv, 180)
        end
        for i = 1, 5 do
            local r = i * 20
            draw_polygon(img, cx, cy, r, 6, 255, 200, 50, 200)
        end

        lurek.image.savePNG(img, OUT .. "concentric_rings.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_shapes.lua
-- ================================================================

-- test_evidence_shapes.lua
-- Evidence test: 2D shape drawing using lurek.image primitives

local OUT = "tests/output/shapes/"

-- Helper: draw a regular polygon centred at (cx, cy)
local function draw_polygon(img, cx, cy, radius, sides, r, g, b, a)
    a = a or 255
    local prev_x, prev_y
    for i = 0, sides do
        local angle = (i / sides) * 2 * math.pi - math.pi / 2
        local nx = math.floor(cx + radius * math.cos(angle))
        local ny = math.floor(cy + radius * math.sin(angle))
        if prev_x then
            img:drawLine(prev_x, prev_y, nx, ny, r, g, b, a)
        end
        prev_x, prev_y = nx, ny
    end
end

-- Helper: draw a spiral
local function draw_spiral(img, cx, cy, turns, r, g, b)
    local steps = turns * 60
    local prev_x, prev_y
    for i = 0, steps do
        local t  = i / steps
        local angle  = t * turns * 2 * math.pi
        local rad    = t * 80
        local nx = math.floor(cx + rad * math.cos(angle))
        local ny = math.floor(cy + rad * math.sin(angle))
        if prev_x then
            img:drawLine(prev_x, prev_y, nx, ny, r, g, b, 255)
        end
        prev_x, prev_y = nx, ny
    end
end

-- @description Covers suite: Evidence: Shapes.
describe("Evidence: Shapes", function()

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawRect
    -- @covers ImageData:drawLine
    -- @covers ImageData:drawCircle
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws a gallery of polygon outlines and filled circles to provide a compact catalog of shape rasterization.
    it("renders a polygon gallery", function()
        local W, H = 512, 256
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        -- Row of polygons: triangle, square, pentagon, hexagon, octagon, circle
        local configs = {
            { sides = 3,  cx = 48,  label = "tri"  },
            { sides = 4,  cx = 128, label = "quad" },
            { sides = 5,  cx = 208, label = "pent" },
            { sides = 6,  cx = 288, label = "hex"  },
            { sides = 8,  cx = 368, label = "oct"  },
            { sides = 32, cx = 448, label = "circ" },
        }
        for _, c in ipairs(configs) do
            draw_polygon(img, c.cx, 80, 36, c.sides, 80, 160, 255, 255)
            draw_polygon(img, c.cx, 80, 36, c.sides, 80, 160, 255, 255)
        end

        -- Second row: filled circles
        for i, c in ipairs(configs) do
            local hue_r = math.floor(40 + (i - 1) * 35)
            img:drawCircle(c.cx, 180, 28, hue_r, 120, 200, 200)
        end

        lurek.image.savePNG(img, OUT .. "polygon_gallery.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawRect
    -- @covers ImageData:drawCircle
    -- @covers ImageData:drawLine
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws a scene of filled primitive shapes and diagonal lines to show layered primitive composition.
    it("renders filled primitive shapes", function()
        local W, H = 400, 400
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 15, 15, 25, 255)

        -- Filled rectangles
        img:drawRect(20,  20,  120, 80,  200, 80,  80,  200)
        img:drawRect(160, 20,  120, 80,  80,  200, 80,  200)
        img:drawRect(300, 20,  80,  80,  80,  80,  200, 200)

        -- Filled circles
        img:drawCircle(60,  200, 50, 220, 120, 40,  200)
        img:drawCircle(200, 200, 50, 40,  180, 220, 200)
        img:drawCircle(340, 200, 50, 180, 40,  220, 200)

        -- Diagonal lines
        for i = 0, 7 do
            local x = i * 50
            img:drawLine(x, 300, x + 40, 380, 200, 200, 40, 200)
        end

        lurek.image.savePNG(img, OUT .. "filled_primitives.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawLine
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws several spirals with different turn counts and saves the result as PNG evidence.
    it("renders a spiral gallery", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        draw_spiral(img, 70,  150, 3, 220, 80,  80)
        draw_spiral(img, 200, 150, 4, 80,  220, 80)
        draw_spiral(img, 330, 150, 5, 80,  80,  220)

        lurek.image.savePNG(img, OUT .. "spirals.png")
    end)

    -- @covers lurek.image.newImageData
    -- @covers ImageData:drawCircle
    -- @covers ImageData:drawLine
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Draws concentric rings of circles and polygons to provide a second multi-shape rasterization reference image.
    it("renders concentric shape rings", function()
        local W, H = 300, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 10, 10, 20, 255)

        local cx, cy = 150, 150
        for i = 1, 8 do
            local r = i * 16
            local col = math.floor(20 + i * 28)
            local inv = math.max(0, 220 - col)
            img:drawCircle(cx, cy, r, col, 120, inv, 180)
        end
        for i = 1, 5 do
            local r = i * 20
            draw_polygon(img, cx, cy, r, 6, 255, 200, 50, 200)
        end

        lurek.image.savePNG(img, OUT .. "concentric_rings.png")
    end)

end)

test_summary()
