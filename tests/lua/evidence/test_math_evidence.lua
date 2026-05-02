-- Evidence suite for math module core operations.

describe("evidence: math", function()
    before_each(function()
        ensure_evidence_dir("math")
    end)

    it("records Vec2 arithmetic results as CSV", function()
        local dir  = evidence_output_dir("math")
        local path = dir .. "vec2_arithmetic.csv"
        local f = io.open(path, "w")
        expect_true(f, "could not open math evidence CSV")
        f:write("op,ax,ay,bx,by,result\n")

        local function v2(x, y) return lurek.math.newVec2(x, y) end
        local pairs_list = {
            { v2(3,4), v2(0,0) }, { v2(1,0), v2(0,1) },
            { v2(2,3), v2(5,7) }, { v2(-1,2), v2(3,-4) },
        }
        for _, p in ipairs(pairs_list) do
            local a, b = p[1], p[2]
            f:write(string.format("length,%.3f,%.3f,,,%.5f\n",  a.x, a.y, a:length()))
            f:write(string.format("dot,%.3f,%.3f,%.3f,%.3f,%.5f\n", a.x, a.y, b.x, b.y, a:dot(b)))
            f:write(string.format("dist,%.3f,%.3f,%.3f,%.3f,%.5f\n", a.x, a.y, b.x, b.y, a:distance(b)))
        end
        f:close()
        expect_evidence_created(path)
    end)

    it("renders Vec2 normalize on unit circle PNG", function()
        local dir  = evidence_output_dir("math")
        local path = dir .. "vec2_unit_circle.png"
        local W, H = 200, 200
        local img = lurek.image.newImageData(W, H)
        img:fill(240, 240, 240, 255)
        local cx, cy, r = 100, 100, 80
        img:drawCircle(cx, cy, r, 180, 180, 200, 255)
        for i = 0, 35 do
            local angle = (i / 36) * math.pi * 2
            local v = lurek.math.newVec2(math.cos(angle), math.sin(angle))
            local n = v:normalize()
            local ex = math.floor(cx + n.x * r + 0.5)
            local ey = math.floor(cy + n.y * r + 0.5)
            img:setPixel(math.max(0,math.min(W-1,ex)), math.max(0,math.min(H-1,ey)), 60, 100, 220, 255)
        end
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    it("records seeded random sequences as CSV", function()
        local dir  = evidence_output_dir("math")
        local path = dir .. "random_sequences.csv"
        local f = io.open(path, "w")
        expect_true(f, "could not open random CSV")
        f:write("seed,r1,r2,r3,r4,r5\n")
        for _, seed in ipairs({ 1, 42, 999, 12345 }) do
            lurek.math.randomSeed(seed)
            local vals = {}
            for _ = 1, 5 do
                vals[#vals + 1] = string.format("%.6f", lurek.math.random())
            end
            f:write(seed .. "," .. table.concat(vals, ",") .. "\n")
        end
        f:close()
        expect_evidence_created(path)
    end)
end)



-- ================================================================
-- Merged from: test_evidence_migrated_15.lua
-- ================================================================

-- Migrated 15 tests from Rust evidence
local OUT = "tests/output/migrated_15/"

describe("evidence: migrated 15", function()
    before_each(function()
        ensure_evidence_dir("migrated_15")
    end)

    -- @evidence file
    it("evidence_image_new_blank", function()
        local img = lurek.image.newImageData(64, 64)
        local path = OUT .. "new_blank_64x64.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_image_fill_solid", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(255, 128, 0, 255)
        local path = OUT .. "fill_orange.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_image_set_pixel_pattern", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(0, 0, 0, 255)
        for i = 0, 63 do
            img:setPixel(i, i, 255, 255, 0, 255)
            if i < 63 then
                img:setPixel(63 - i, i, 0, 255, 255, 255)
            end
        end
        local path = OUT .. "diagonal_cross.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_image_draw_shapes_combined", function()
        local img = lurek.image.newImageData(256, 256)
        img:fill(20, 20, 40, 255)
        for i = 0, 255, 16 do
            img:drawLine(i, 0, i, 255, 40, 40, 60, 255)
            img:drawLine(0, i, 255, i, 40, 40, 60, 255)
        end
        img:drawRect(60, 140, 80, 80, 180, 120, 60, 255)
        img:drawRect(85, 180, 30, 40, 100, 60, 30, 255)
        img:drawRect(70, 155, 20, 20, 150, 200, 255, 255)
        img:drawRect(110, 155, 20, 20, 150, 200, 255, 255)
        img:drawLine(55, 140, 100, 90, 200, 50, 50, 255)
        img:drawLine(100, 90, 145, 140, 200, 50, 50, 255)
        img:drawLine(55, 140, 145, 140, 200, 50, 50, 255)
        img:drawCircle(200, 50, 25, 255, 220, 50, 255)
        for angle_deg = 0, 359, 45 do
            local angle = math.rad(angle_deg)
            local sx, sy = 200 + 30 * math.cos(angle), 50 + 30 * math.sin(angle)
            local ex, ey = 200 + 45 * math.cos(angle), 50 + 45 * math.sin(angle)
            img:drawLine(sx, sy, ex, ey, 255, 220, 50, 255)
        end
        img:drawRect(0, 220, 256, 36, 40, 120, 40, 255)
        local path = OUT .. "shapes_combined_scene.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_image_paste_composite", function()
        local bg = lurek.image.newImageData(128, 128)
        bg:fill(40, 40, 80, 255)
        local sprite = lurek.image.newImageData(32, 32)
        sprite:drawCircle(16, 16, 14, 255, 200, 0, 255)
        bg:paste(sprite, 10, 10)
        bg:paste(sprite, 50, 30)
        bg:paste(sprite, 80, 70)
        local path = OUT .. "paste_composite.png"
        lurek.image.savePNG(bg, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_noise", function()
        local img = lurek.image.newImageData(128, 128)
        img:fill(128, 128, 128, 255)
        local noisy = img:crop(0, 0, 128, 128)
        noisy:noise(80)
        local path = OUT .. "noise_after.png"
        lurek.image.savePNG(noisy, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_flip_horizontal", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 31 do img:setPixel(x, y, 255, 0, 0, 255) end
            for x = 32, 63 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        local flipped = img:crop(0, 0, 64, 64)
        flipped:flipHorizontal()
        local path = OUT .. "flip_h_after.png"
        lurek.image.savePNG(flipped, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_flip_vertical", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 31 do
            for x = 0, 63 do img:setPixel(x, y, 255, 0, 0, 255) end
        end
        for y = 32, 63 do
            for x = 0, 63 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        local flipped = img:crop(0, 0, 64, 64)
        flipped:flipVertical()
        local path = OUT .. "flip_v_after.png"
        lurek.image.savePNG(flipped, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_rotate", function()
        local img = lurek.image.newImageData(64, 32)
        img:fill(255, 255, 0, 255)
        local rotated = img:rotate90cw()
        local path = OUT .. "rotate_90cw.png"
        lurek.image.savePNG(rotated, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_crop", function()
        local img = lurek.image.newImageData(128, 128)
        img:fill(200, 200, 200, 255)
        img:drawRect(32, 32, 64, 64, 255, 0, 0, 255)
        local cropped = img:crop(32, 32, 64, 64)
        local path = OUT .. "crop_center.png"
        lurek.image.savePNG(cropped, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_resize", function()
        local img = lurek.image.newImageData(32, 32)
        img:fill(255, 0, 255, 255)
        img:drawCircle(16, 16, 10, 0, 0, 0, 255)
        local big = img:resizeNearest(128, 128)
        local path = OUT .. "resize_upscaled_128.png"
        lurek.image.savePNG(big, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_alpha_mask", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(0, 255, 0, 255)
        local mask = lurek.image.newImageData(64, 64)
        mask:fill(128, 128, 128, 128) -- 50% opacity
        local masked = img:crop(0, 0, 64, 64)
        -- missing specific multiply_alpha, we assume mapPixel
        masked:mapPixel(function(x, y, r, g, b, a)
            local _, _, _, ma = mask:getPixel(x, y)
            return r, g, b, (a * ma) / 255
        end)
        local path = OUT .. "alpha_mask_50pct.png"
        lurek.image.savePNG(masked, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_pipeline", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(100, 100, 100, 255)
        img:drawCircle(32, 32, 20, 200, 50, 50, 255)
        local blurred = img:crop(0, 0, 64, 64)
        blurred:blur(2.0)
        local path = OUT .. "pipeline_05_blur.png"
        lurek.image.savePNG(blurred, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_math_noise_colored_terrain", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local n = math.min(1, math.max(0, (lurek.math.perlinFast(x * 0.1, y * 0.1) + 1.0) * 0.5))
                local r, g, b = 0, 0, 0
                if n < 0.4 then r, g, b = 0, 0, 150
                elseif n < 0.6 then r, g, b = 200, 200, 100
                else r, g, b = 50, 150, 50 end
                img:setPixel(x, y, r, g, b, 255)
            end
        end
        local path = OUT .. "noise_terrain_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_math_generate_map", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local n = lurek.math.simplex(x * 0.1, y * 0.1)
                local v = math.floor((n + 1.0) * 127)
                img:setPixel(x, y, v, v, v, 255)
            end
        end
        local path = OUT .. "generate_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)



-- ================================================================
-- Merged from: test_migrated_15_evidence.lua
-- ================================================================

-- Migrated 15 tests from Rust evidence
local OUT = "tests/output/migrated_15/"

describe("evidence: migrated 15", function()
    before_each(function()
        ensure_evidence_dir("migrated_15")
    end)

    -- @evidence file
    it("evidence_image_new_blank", function()
        local img = lurek.image.newImageData(64, 64)
        local path = OUT .. "new_blank_64x64.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_image_fill_solid", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(255, 128, 0, 255)
        local path = OUT .. "fill_orange.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_image_set_pixel_pattern", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(0, 0, 0, 255)
        for i = 0, 63 do
            img:setPixel(i, i, 255, 255, 0, 255)
            if i < 63 then
                img:setPixel(63 - i, i, 0, 255, 255, 255)
            end
        end
        local path = OUT .. "diagonal_cross.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_image_draw_shapes_combined", function()
        local img = lurek.image.newImageData(256, 256)
        img:fill(20, 20, 40, 255)
        for i = 0, 255, 16 do
            img:drawLine(i, 0, i, 255, 40, 40, 60, 255)
            img:drawLine(0, i, 255, i, 40, 40, 60, 255)
        end
        img:drawRect(60, 140, 80, 80, 180, 120, 60, 255)
        img:drawRect(85, 180, 30, 40, 100, 60, 30, 255)
        img:drawRect(70, 155, 20, 20, 150, 200, 255, 255)
        img:drawRect(110, 155, 20, 20, 150, 200, 255, 255)
        img:drawLine(55, 140, 100, 90, 200, 50, 50, 255)
        img:drawLine(100, 90, 145, 140, 200, 50, 50, 255)
        img:drawLine(55, 140, 145, 140, 200, 50, 50, 255)
        img:drawCircle(200, 50, 25, 255, 220, 50, 255)
        for angle_deg = 0, 359, 45 do
            local angle = math.rad(angle_deg)
            local sx, sy = 200 + 30 * math.cos(angle), 50 + 30 * math.sin(angle)
            local ex, ey = 200 + 45 * math.cos(angle), 50 + 45 * math.sin(angle)
            img:drawLine(sx, sy, ex, ey, 255, 220, 50, 255)
        end
        img:drawRect(0, 220, 256, 36, 40, 120, 40, 255)
        local path = OUT .. "shapes_combined_scene.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_image_paste_composite", function()
        local bg = lurek.image.newImageData(128, 128)
        bg:fill(40, 40, 80, 255)
        local sprite = lurek.image.newImageData(32, 32)
        sprite:drawCircle(16, 16, 14, 255, 200, 0, 255)
        bg:paste(sprite, 10, 10)
        bg:paste(sprite, 50, 30)
        bg:paste(sprite, 80, 70)
        local path = OUT .. "paste_composite.png"
        lurek.image.savePNG(bg, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_noise", function()
        local img = lurek.image.newImageData(128, 128)
        img:fill(128, 128, 128, 255)
        local noisy = img:crop(0, 0, 128, 128)
        noisy:noise(80)
        local path = OUT .. "noise_after.png"
        lurek.image.savePNG(noisy, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_flip_horizontal", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 31 do img:setPixel(x, y, 255, 0, 0, 255) end
            for x = 32, 63 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        local flipped = img:crop(0, 0, 64, 64)
        flipped:flipHorizontal()
        local path = OUT .. "flip_h_after.png"
        lurek.image.savePNG(flipped, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_flip_vertical", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 31 do
            for x = 0, 63 do img:setPixel(x, y, 255, 0, 0, 255) end
        end
        for y = 32, 63 do
            for x = 0, 63 do img:setPixel(x, y, 0, 0, 255, 255) end
        end
        local flipped = img:crop(0, 0, 64, 64)
        flipped:flipVertical()
        local path = OUT .. "flip_v_after.png"
        lurek.image.savePNG(flipped, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_rotate", function()
        local img = lurek.image.newImageData(64, 32)
        img:fill(255, 255, 0, 255)
        local rotated = img:rotate90cw()
        local path = OUT .. "rotate_90cw.png"
        lurek.image.savePNG(rotated, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_crop", function()
        local img = lurek.image.newImageData(128, 128)
        img:fill(200, 200, 200, 255)
        img:drawRect(32, 32, 64, 64, 255, 0, 0, 255)
        local cropped = img:crop(32, 32, 64, 64)
        local path = OUT .. "crop_center.png"
        lurek.image.savePNG(cropped, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_resize", function()
        local img = lurek.image.newImageData(32, 32)
        img:fill(255, 0, 255, 255)
        img:drawCircle(16, 16, 10, 0, 0, 0, 255)
        local big = img:resizeNearest(128, 128)
        local path = OUT .. "resize_upscaled_128.png"
        lurek.image.savePNG(big, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_alpha_mask", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(0, 255, 0, 255)
        local mask = lurek.image.newImageData(64, 64)
        mask:fill(128, 128, 128, 128) -- 50% opacity
        local masked = img:crop(0, 0, 64, 64)
        -- missing specific multiply_alpha, we assume mapPixel
        masked:mapPixel(function(x, y, r, g, b, a)
            local _, _, _, ma = mask:getPixel(x, y)
            return r, g, b, (a * ma) / 255
        end)
        local path = OUT .. "alpha_mask_50pct.png"
        lurek.image.savePNG(masked, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_effect_pipeline", function()
        local img = lurek.image.newImageData(64, 64)
        img:fill(100, 100, 100, 255)
        img:drawCircle(32, 32, 20, 200, 50, 50, 255)
        local blurred = img:crop(0, 0, 64, 64)
        blurred:blur(2.0)
        local path = OUT .. "pipeline_05_blur.png"
        lurek.image.savePNG(blurred, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_math_noise_colored_terrain", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local n = math.min(1, math.max(0, (lurek.math.perlinFast(x * 0.1, y * 0.1) + 1.0) * 0.5))
                local r, g, b = 0, 0, 0
                if n < 0.4 then r, g, b = 0, 0, 150
                elseif n < 0.6 then r, g, b = 200, 200, 100
                else r, g, b = 50, 150, 50 end
                img:setPixel(x, y, r, g, b, 255)
            end
        end
        local path = OUT .. "noise_terrain_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)

    -- @evidence file
    it("evidence_math_generate_map", function()
        local img = lurek.image.newImageData(64, 64)
        for y = 0, 63 do
            for x = 0, 63 do
                local n = lurek.math.simplex(x * 0.1, y * 0.1)
                local v = math.floor((n + 1.0) * 127)
                img:setPixel(x, y, v, v, v, 255)
            end
        end
        local path = OUT .. "generate_map.png"
        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)



-- ================================================================
-- Merged from: test_evidence_misc.lua
-- ================================================================


describe('Evidence misc', function()
end)



-- ================================================================
-- Merged from: test_misc_evidence.lua
-- ================================================================


describe('Evidence misc', function()
end)

-- ================================================================
-- Merged from: test_bezier_evidence.lua
-- ================================================================

-- test_evidence_bezier.lua
-- Evidence test: BezierCurve creation, evaluation, and visualisation

local OUT = "tests/output/bezier/"

local function plot_point(img, x, y, r, g, b, size)
    size = size or 2
    local ix = math.floor(x)
    local iy = math.floor(y)
    img:drawRect(ix - math.floor(size / 2), iy - math.floor(size / 2), size, size, r, g, b, 255)
end

local function plot_control_points(img, curve)
    local count = curve:getControlPointCount()
    for i = 1, count do
        local cx, cy = curve:getControlPoint(i)
        if cx then
            img:drawCircle(math.floor(cx), math.floor(cy), 4, 255, 0, 0, 255)
        end
    end
end

describe("Evidence: Bezier curves", function()

    -- @evidence file
    it("quadratic bezier (3 control points)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({50, 250, 200, 30, 350, 250})

        -- Plot curve
        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 100, 200, 255, 3)
        end

        -- Plot control points
        plot_control_points(img, curve)

        -- Draw control polygon
        img:drawLine(50, 250, 200, 30, 80, 80, 80, 255)
        img:drawLine(200, 30, 350, 250, 80, 80, 80, 255)

        lurek.image.savePNG(img, OUT .. "bezier_quadratic.png")
    end)

    -- @evidence file
    it("cubic bezier (4 control points)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({30, 250, 100, 30, 300, 30, 370, 250})

        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 255, 180, 50, 3)
        end

        plot_control_points(img, curve)

        -- Control polygon
        img:drawLine(30, 250, 100, 30, 80, 80, 80, 255)
        img:drawLine(100, 30, 300, 30, 80, 80, 80, 255)
        img:drawLine(300, 30, 370, 250, 80, 80, 80, 255)

        lurek.image.savePNG(img, OUT .. "bezier_cubic.png")
    end)

    -- @evidence file
    it("complex bezier (7 control points)", function()
        local W, H = 500, 400
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({
            30, 350,
            80, 50,
            180, 350,
            250, 50,
            320, 350,
            400, 50,
            470, 350,
        })

        local steps = 300
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 50, 255, 100, 3)
        end

        plot_control_points(img, curve)

        -- Control polygon
        local count = curve:getControlPointCount()
        for i = 1, count - 1 do
            local x1, y1 = curve:getControlPoint(i)
            local x2, y2 = curve:getControlPoint(i + 1)
            if x1 and x2 then
                img:drawLine(
                    math.floor(x1), math.floor(y1),
                    math.floor(x2), math.floor(y2),
                    60, 60, 60, 255
                )
            end
        end

        lurek.image.savePNG(img, OUT .. "bezier_complex.png")
    end)

    -- @evidence file
    it("derivative visualisation (tangent lines)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({30, 250, 100, 30, 300, 30, 370, 250})
        local deriv = curve:getDerivative()

        -- Plot the original curve
        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 100, 200, 255, 2)
        end

        -- Plot tangent lines at regular intervals
        local tangent_steps = 10
        local tangent_len = 30
        for i = 0, tangent_steps do
            local t = i / tangent_steps
            local px, py = curve:evaluate(t)
            local dx, dy = deriv:evaluate(t)
            -- Normalize the tangent
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0.001 then
                dx = dx / len * tangent_len
                dy = dy / len * tangent_len
                img:drawLine(
                    math.floor(px), math.floor(py),
                    math.floor(px + dx), math.floor(py + dy),
                    255, 100, 100, 255
                )
            end
            -- Mark the point
            img:drawCircle(math.floor(px), math.floor(py), 3, 255, 255, 0, 255)
        end

        plot_control_points(img, curve)

        lurek.image.savePNG(img, OUT .. "bezier_tangents.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_bezier.lua
-- ================================================================

-- test_evidence_bezier.lua
-- Evidence test: BezierCurve creation, evaluation, and visualisation

local OUT = "tests/output/bezier/"

local function plot_point(img, x, y, r, g, b, size)
    size = size or 2
    local ix = math.floor(x)
    local iy = math.floor(y)
    img:drawRect(ix - math.floor(size / 2), iy - math.floor(size / 2), size, size, r, g, b, 255)
end

local function plot_control_points(img, curve)
    local count = curve:getControlPointCount()
    for i = 1, count do
        local cx, cy = curve:getControlPoint(i)
        if cx then
            img:drawCircle(math.floor(cx), math.floor(cy), 4, 255, 0, 0, 255)
        end
    end
end

describe("Evidence: Bezier curves", function()

    -- @evidence file
    it("quadratic bezier (3 control points)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({50, 250, 200, 30, 350, 250})

        -- Plot curve
        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 100, 200, 255, 3)
        end

        -- Plot control points
        plot_control_points(img, curve)

        -- Draw control polygon
        img:drawLine(50, 250, 200, 30, 80, 80, 80, 255)
        img:drawLine(200, 30, 350, 250, 80, 80, 80, 255)

        lurek.image.savePNG(img, OUT .. "bezier_quadratic.png")
    end)

    -- @evidence file
    it("cubic bezier (4 control points)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({30, 250, 100, 30, 300, 30, 370, 250})

        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 255, 180, 50, 3)
        end

        plot_control_points(img, curve)

        -- Control polygon
        img:drawLine(30, 250, 100, 30, 80, 80, 80, 255)
        img:drawLine(100, 30, 300, 30, 80, 80, 80, 255)
        img:drawLine(300, 30, 370, 250, 80, 80, 80, 255)

        lurek.image.savePNG(img, OUT .. "bezier_cubic.png")
    end)

    -- @evidence file
    it("complex bezier (7 control points)", function()
        local W, H = 500, 400
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({
            30, 350,
            80, 50,
            180, 350,
            250, 50,
            320, 350,
            400, 50,
            470, 350,
        })

        local steps = 300
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 50, 255, 100, 3)
        end

        plot_control_points(img, curve)

        -- Control polygon
        local count = curve:getControlPointCount()
        for i = 1, count - 1 do
            local x1, y1 = curve:getControlPoint(i)
            local x2, y2 = curve:getControlPoint(i + 1)
            if x1 and x2 then
                img:drawLine(
                    math.floor(x1), math.floor(y1),
                    math.floor(x2), math.floor(y2),
                    60, 60, 60, 255
                )
            end
        end

        lurek.image.savePNG(img, OUT .. "bezier_complex.png")
    end)

    -- @evidence file
    it("derivative visualisation (tangent lines)", function()
        local W, H = 400, 300
        local img = lurek.image.newImageData(W, H)
        img:drawRect(0, 0, W, H, 20, 20, 30, 255)

        local curve = lurek.math.newBezierCurve({30, 250, 100, 30, 300, 30, 370, 250})
        local deriv = curve:getDerivative()

        -- Plot the original curve
        local steps = 200
        for i = 0, steps do
            local t = i / steps
            local x, y = curve:evaluate(t)
            plot_point(img, x, y, 100, 200, 255, 2)
        end

        -- Plot tangent lines at regular intervals
        local tangent_steps = 10
        local tangent_len = 30
        for i = 0, tangent_steps do
            local t = i / tangent_steps
            local px, py = curve:evaluate(t)
            local dx, dy = deriv:evaluate(t)
            -- Normalize the tangent
            local len = math.sqrt(dx * dx + dy * dy)
            if len > 0.001 then
                dx = dx / len * tangent_len
                dy = dy / len * tangent_len
                img:drawLine(
                    math.floor(px), math.floor(py),
                    math.floor(px + dx), math.floor(py + dy),
                    255, 100, 100, 255
                )
            end
            -- Mark the point
            img:drawCircle(math.floor(px), math.floor(py), 3, 255, 255, 0, 255)
        end

        plot_control_points(img, curve)

        lurek.image.savePNG(img, OUT .. "bezier_tangents.png")
    end)

end)

-- ================================================================
-- Merged from: test_geometry_evidence.lua
-- ================================================================

-- test_evidence_geometry.lua
-- Evidence test: geometry shapes, intersection tests, and Delaunay triangulation
-- @evidence file

require("tests/lua/init")

local OUT = "tests/output/geometry/"

local function draw_dot(img, cx, cy, radius, r, g, b)
    local r2 = radius * radius
    for y = math.max(0, cy - radius), math.min(img:getHeight() - 1, cy + radius) do
        for x = math.max(0, cx - radius), math.min(img:getWidth() - 1, cx + radius) do
            if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2 then
                img:setPixel(x, y, r, g, b, 255)
            end
        end
    end
end

describe("Evidence: geometry shapes and queries", function()

    -- @evidence file
    it("polygon gallery (triangle, quad, pentagon, hexagon)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 30, 255)
        -- Draw regular polygons
        local shapes = {
            {cx=64,  cy=64,  r=40, sides=3,  color={255,100,100}},
            {cx=192, cy=64,  r=40, sides=4,  color={100,255,100}},
            {cx=64,  cy=192, r=40, sides=5,  color={100,100,255}},
            {cx=192, cy=192, r=40, sides=6,  color={255,255,100}},
        }
        for _, s in ipairs(shapes) do
            for i = 0, s.sides - 1 do
                local a1 = (2 * math.pi * i / s.sides) - math.pi/2
                local a2 = (2 * math.pi * (i+1) / s.sides) - math.pi/2
                local x1 = math.floor(s.cx + s.r * math.cos(a1))
                local y1 = math.floor(s.cy + s.r * math.sin(a1))
                local x2 = math.floor(s.cx + s.r * math.cos(a2))
                local y2 = math.floor(s.cy + s.r * math.sin(a2))
                -- Draw line segment
                for t = 0, 1, 0.005 do
                    local px = math.floor(x1 + (x2 - x1) * t)
                    local py = math.floor(y1 + (y2 - y1) * t)
                    if px >= 0 and px < W and py >= 0 and py < H then
                        img:setPixel(px, py, s.color[1], s.color[2], s.color[3], 255)
                    end
                end
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_polygon_gallery.png")
    end)

    -- @evidence file
    it("filled primitives (circles and rectangles)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(15, 15, 25, 255)
        -- Filled circles
        draw_dot(img, 64, 64, 30, 255, 80, 80)
        draw_dot(img, 192, 64, 25, 80, 255, 80)
        draw_dot(img, 128, 192, 35, 80, 80, 255)
        -- Filled rects
        for y = 100, 140 do
            for x = 20, 80 do
                img:setPixel(x, y, 255, 200, 50, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_filled_primitives.png")
    end)

    -- @evidence file
    it("spirals (Archimedean spiral)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(10, 10, 20, 255)
        local cx, cy = 128, 128
        for i = 0, 1000 do
            local t = i * 0.01
            local r = t * 8
            local x = math.floor(cx + r * math.cos(t * 2))
            local y = math.floor(cy + r * math.sin(t * 2))
            if x >= 0 and x < W and y >= 0 and y < H then
                local c = math.floor(255 * (1 - t / 10))
                img:setPixel(x, y, c, math.floor(c * 0.6), 255, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_spirals.png")
    end)
        end)


-- ================================================================
-- Merged from: test_evidence_geometry.lua
-- ================================================================

-- test_evidence_geometry.lua
-- Evidence test: geometry shapes, intersection tests, and Delaunay triangulation
-- @evidence file

require("tests/lua/init")

local OUT = "tests/output/geometry/"

local function draw_dot(img, cx, cy, radius, r, g, b)
    local r2 = radius * radius
    for y = math.max(0, cy - radius), math.min(img:getHeight() - 1, cy + radius) do
        for x = math.max(0, cx - radius), math.min(img:getWidth() - 1, cx + radius) do
            if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r2 then
                img:setPixel(x, y, r, g, b, 255)
            end
        end
    end
end

describe("Evidence: geometry shapes and queries", function()

    -- @evidence file
    it("polygon gallery (triangle, quad, pentagon, hexagon)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 30, 255)
        -- Draw regular polygons
        local shapes = {
            {cx=64,  cy=64,  r=40, sides=3,  color={255,100,100}},
            {cx=192, cy=64,  r=40, sides=4,  color={100,255,100}},
            {cx=64,  cy=192, r=40, sides=5,  color={100,100,255}},
            {cx=192, cy=192, r=40, sides=6,  color={255,255,100}},
        }
        for _, s in ipairs(shapes) do
            for i = 0, s.sides - 1 do
                local a1 = (2 * math.pi * i / s.sides) - math.pi/2
                local a2 = (2 * math.pi * (i+1) / s.sides) - math.pi/2
                local x1 = math.floor(s.cx + s.r * math.cos(a1))
                local y1 = math.floor(s.cy + s.r * math.sin(a1))
                local x2 = math.floor(s.cx + s.r * math.cos(a2))
                local y2 = math.floor(s.cy + s.r * math.sin(a2))
                -- Draw line segment
                for t = 0, 1, 0.005 do
                    local px = math.floor(x1 + (x2 - x1) * t)
                    local py = math.floor(y1 + (y2 - y1) * t)
                    if px >= 0 and px < W and py >= 0 and py < H then
                        img:setPixel(px, py, s.color[1], s.color[2], s.color[3], 255)
                    end
                end
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_polygon_gallery.png")
    end)

    -- @evidence file
    it("filled primitives (circles and rectangles)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(15, 15, 25, 255)
        -- Filled circles
        draw_dot(img, 64, 64, 30, 255, 80, 80)
        draw_dot(img, 192, 64, 25, 80, 255, 80)
        draw_dot(img, 128, 192, 35, 80, 80, 255)
        -- Filled rects
        for y = 100, 140 do
            for x = 20, 80 do
                img:setPixel(x, y, 255, 200, 50, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_filled_primitives.png")
    end)

    -- @evidence file
    it("spirals (Archimedean spiral)", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)
        img:fill(10, 10, 20, 255)
        local cx, cy = 128, 128
        for i = 0, 1000 do
            local t = i * 0.01
            local r = t * 8
            local x = math.floor(cx + r * math.cos(t * 2))
            local y = math.floor(cy + r * math.sin(t * 2))
            if x >= 0 and x < W and y >= 0 and y < H then
                local c = math.floor(255 * (1 - t / 10))
                img:setPixel(x, y, c, math.floor(c * 0.6), 255, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "shapes_spirals.png")
    end)
        end)

-- ================================================================
-- Merged from: test_noise_evidence.lua
-- ================================================================

-- test_evidence_noise.lua
-- Evidence test: Noise functions visualised as grayscale images

local OUT = "tests/output/noise/"

local function noise_to_byte(v)
    -- Map [-1, 1] â†’ [0, 255]
    local clamped = math.max(-1, math.min(1, v))
    return math.floor((clamped + 1) * 0.5 * 255 + 0.5)
end

describe("Evidence: Noise generation", function()

    -- @evidence file
    it("generates Perlin 2D noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:perlin2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_perlin2d.png")
    end)

    -- @evidence file
    it("generates Simplex 2D noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:simplex2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_simplex2d.png")
    end)

    -- @evidence file
    it("generates FBM noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:fbm(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_fbm.png")
    end)

    -- @evidence file
    it("generates Worley 2D noise image", function()
        local size = 256
        local scale = 30
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:worley2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_worley2d.png")
    end)

    -- @evidence file
    it("generates Ridged noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:ridged(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_ridged.png")
    end)

    -- @evidence file
    it("generates Turbulence noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:turbulence(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_turbulence.png")
    end)

end)



-- ================================================================
-- Merged from: test_evidence_noise.lua
-- ================================================================

-- test_evidence_noise.lua
-- Evidence test: Noise functions visualised as grayscale images

local OUT = "tests/output/noise/"

local function noise_to_byte(v)
    -- Map [-1, 1] â†’ [0, 255]
    local clamped = math.max(-1, math.min(1, v))
    return math.floor((clamped + 1) * 0.5 * 255 + 0.5)
end

describe("Evidence: Noise generation", function()

    -- @evidence file
    it("generates Perlin 2D noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:perlin2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_perlin2d.png")
    end)

    -- @evidence file
    it("generates Simplex 2D noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:simplex2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_simplex2d.png")
    end)

    -- @evidence file
    it("generates FBM noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:fbm(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_fbm.png")
    end)

    -- @evidence file
    it("generates Worley 2D noise image", function()
        local size = 256
        local scale = 30
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:worley2d(x / scale, y / scale)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_worley2d.png")
    end)

    -- @evidence file
    it("generates Ridged noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:ridged(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_ridged.png")
    end)

    -- @evidence file
    it("generates Turbulence noise image", function()
        local size = 256
        local scale = 50
        local img = lurek.image.newImageData(size, size)
        local ng = lurek.math.newNoiseGenerator(42)
        for y = 0, size - 1 do
            for x = 0, size - 1 do
                local v = ng:turbulence(x / scale, y / scale, 4, 2.0, 0.5)
                local c = noise_to_byte(v)
                img:setPixel(x, y, c, c, c, 255)
            end
        end
        lurek.image.savePNG(img, OUT .. "noise_turbulence.png")
    end)

end)
test_summary()
