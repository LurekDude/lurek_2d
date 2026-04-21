-- test_evidence_effect_overlay.lua
-- Evidence test: lurek.effect overlay API + renders overlay effects to PNG
-- Produces: overlay_flash.png, overlay_fade.png, overlay_combined.png

local OUT = "tests/lua/evidence/output/overlay/"

--- Helper: draw filled rect
local function draw_rect(img, x0, y0, w, h, r, g, b, a)
    a = a or 255
    for y = y0, math.min(y0 + h - 1, img:getHeight() - 1) do
        for x = x0, math.min(x0 + w - 1, img:getWidth() - 1) do
            if x >= 0 and y >= 0 then img:setPixel(x, y, r, g, b, a) end
        end
    end
end

--- Helper: blend a color over a base color
local function blend(base_r, base_g, base_b, over_r, over_g, over_b, alpha)
    local a = alpha
    local ia = 1.0 - a
    return math.floor(base_r * ia + over_r * a),
           math.floor(base_g * ia + over_g * a),
           math.floor(base_b * ia + over_b * a)
end

-- @description Covers suite: Evidence: lurek.effect overlay API + PNG visualization.
describe("Evidence: lurek.effect overlay API + PNG visualization", function()
    -- @covers Overlay:triggerFlash
    -- @covers Overlay:getFlashAlpha
    -- @covers Overlay:update
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples flash alpha decay over several time steps and writes the resulting strip to a PNG.
    it("PNG: flash effect at multiple time steps", function()
        local W, H = 256, 64
        local img = lurek.image.newImageData(W, H)

        local ov = lurek.effect.newOverlay(W, H)
        ov:triggerFlash(1.0, 0.0, 0.0, 1.0, 1.0) -- red flash, 1s

        -- Render 8 time steps showing flash decay
        local steps = 8
        local cell_w = W / steps
        for step = 0, steps - 1 do
            local alpha = ov:getFlashAlpha()
            -- Draw a column showing the flash color at this alpha
            for y = 0, H - 1 do
                for x = math.floor(step * cell_w), math.min(math.floor((step + 1) * cell_w) - 1, W - 1) do
                    local br, bg, bb = blend(40, 40, 60, 255, 0, 0, math.max(0, alpha))
                    img:setPixel(x, y, br, bg, bb, 255)
                end
            end
            ov:update(1.0 / steps)
        end

        lurek.image.savePNG(img, OUT .. "overlay_flash.png")
    end)

    -- @covers Overlay:triggerFade
    -- @covers Overlay:update
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Samples a fade-to-black effect across several time slices and writes the progression to PNG evidence.
    it("PNG: fade-to-black effect over time", function()
        local W, H = 256, 64
        local img = lurek.image.newImageData(W, H)

        local ov = lurek.effect.newOverlay(W, H)
        ov:triggerFade(0, 0, 0, 1.0, 1.0) -- fade to black

        local steps = 8
        local cell_w = W / steps
        for step = 0, steps - 1 do
            local flash_a = ov:getFlashAlpha()
            local t = step / steps -- progress
            for y = 0, H - 1 do
                for x = math.floor(step * cell_w), math.min(math.floor((step + 1) * cell_w) - 1, W - 1) do
                    -- Base scene is bright blue
                    local br, bg, bb = blend(100, 150, 255, 0, 0, 0, t)
                    img:setPixel(x, y, br, bg, bb, 255)
                end
            end
            ov:update(1.0 / steps)
        end

        lurek.image.savePNG(img, OUT .. "overlay_fade.png")
    end)

    -- @covers Overlay:triggerFlash
    -- @covers Overlay:clear
    -- @covers Overlay:triggerLightning
    -- @covers Overlay:getFlashAlpha
    -- @covers Overlay:getLightningAlpha
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Combines flash and lightning overlays into one comparison PNG to document multiple transient overlay modes.
    it("PNG: combined effects â€” flash + lightning visualization", function()
        local W, H = 128, 128
        local img = lurek.image.newImageData(W, H)
        img:fill(20, 20, 40, 255)

        local ov = lurek.effect.newOverlay(W, H)

        -- Flash in top half (red)
        ov:triggerFlash(1.0, 0.2, 0.0, 0.8, 0.5)
        local flash_a = ov:getFlashAlpha()
        for y = 0, 63 do
            for x = 0, W - 1 do
                local br, bg, bb = blend(20, 20, 40, 255, 50, 0, math.max(0, flash_a))
                img:setPixel(x, y, br, bg, bb, 255)
            end
        end

        -- Lightning in bottom half (white flash)
        ov:clear()
        ov:triggerLightning()
        local lightning_a = ov:getLightningAlpha()
        for y = 64, H - 1 do
            for x = 0, W - 1 do
                local br, bg, bb = blend(20, 20, 40, 255, 255, 255, math.max(0, lightning_a * 0.5))
                img:setPixel(x, y, br, bg, bb, 255)
            end
        end

        lurek.image.savePNG(img, OUT .. "overlay_combined.png")
    end)

end)
test_summary()
