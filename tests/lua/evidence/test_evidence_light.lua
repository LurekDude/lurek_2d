-- test_evidence_light.lua
-- Evidence test: lurek.light API + renders light falloff / multi-light to PNG
-- Produces: light_single_falloff.png, light_multi_scene.png

local OUT = "tests/lua/evidence/output/light/"

-- @description Covers suite: Evidence: lurek.light API + PNG visualization.
describe("Evidence: lurek.light API + PNG visualization", function()
    -- @covers lurek.light.newLight
    -- @covers LightSource:setColor
    -- @covers LightSource:getPosition
    -- @covers LightSource:getRadius
    -- @covers LightSource:getColor
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Rasterizes a single point light's radial falloff into a PNG using the light's reported position, radius, and color.
    it("PNG: single point light with radial falloff", function()
        local W, H = 128, 128
        local img = lurek.image.newImageData(W, H)

        -- Create a light and read its properties
        local light = lurek.light.newLight(64, 64, 60)
        light:setColor(1.0, 0.8, 0.3, 1.0)
        light:setIntensity(1.0)
        local lx, ly = light:getPosition()
        local lr = light:getRadius()
        local cr, cg, cb = light:getColor()

        -- Render radial falloff onto ImageData
        for y = 0, H - 1 do
            for x = 0, W - 1 do
                local dx, dy = x - lx, y - ly
                local dist = math.sqrt(dx * dx + dy * dy)
                local attenuation = math.max(0, 1.0 - dist / lr)
                local pr = math.floor(cr * attenuation * 255)
                local pg = math.floor(cg * attenuation * 255)
                local pb = math.floor(cb * attenuation * 255)
                img:setPixel(x, y, pr, pg, pb, 255)
            end
        end

        lurek.image.savePNG(img, OUT .. "light_single_falloff.png")
    end)

    -- @covers lurek.light.newLight
    -- @covers LightSource:setColor
    -- @covers LightSource:getPosition
    -- @covers LightSource:getRadius
    -- @covers LightSource:getColor
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Composites three colored point lights into one scene and saves the combined illumination as PNG evidence.
    it("PNG: multi-light scene with colored point lights", function()
        local W, H = 256, 256
        local img = lurek.image.newImageData(W, H)

        local lights = {
            lurek.light.newLight(64,  64,  80),
            lurek.light.newLight(192, 64,  80),
            lurek.light.newLight(128, 192, 80),
        }
        lights[1]:setColor(1.0, 0.2, 0.2, 1.0)
        lights[2]:setColor(0.2, 1.0, 0.2, 1.0)
        lights[3]:setColor(0.2, 0.2, 1.0, 1.0)

        for y = 0, H - 1 do
            for x = 0, W - 1 do
                local tr, tg, tb = 0, 0, 0
                for _, l in ipairs(lights) do
                    local lx, ly = l:getPosition()
                    local lr = l:getRadius()
                    local cr, cg, cb = l:getColor()
                    local dx, dy = x - lx, y - ly
                    local dist = math.sqrt(dx * dx + dy * dy)
                    local att = math.max(0, 1.0 - dist / lr)
                    tr = tr + cr * att
                    tg = tg + cg * att
                    tb = tb + cb * att
                end
                img:setPixel(x, y,
                    math.min(255, math.floor(tr * 255)),
                    math.min(255, math.floor(tg * 255)),
                    math.min(255, math.floor(tb * 255)), 255)
            end
        end

        lurek.image.savePNG(img, OUT .. "light_multi_scene.png")
    end)

end)
test_summary()
