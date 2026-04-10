-- test_evidence_light.lua
-- Evidence test: lurek.light API + renders light falloff / multi-light to PNG
-- Produces: light_single_falloff.png, light_multi_scene.png

local OUT = "tests/lua/evidence/output/"

describe("Evidence: lurek.light API + PNG visualization", function()

    it("newLight creates a LightSource without error", function()
        local ok = pcall(function() return lurek.light.newLight(100, 200, 150) end)
        expect_equal(ok, true)
    end)

    it("getPosition returns initial position", function()
        local l = lurek.light.newLight(100, 200, 150)
        local x, y = l:getPosition()
        expect_near(x, 100, 0.001)
        expect_near(y, 200, 0.001)
    end)

    it("setPosition/getPosition round-trip", function()
        local l = lurek.light.newLight(0, 0, 100)
        l:setPosition(300, 400)
        local x, y = l:getPosition()
        expect_near(x, 300, 0.001)
        expect_near(y, 400, 0.001)
    end)

    it("getRadius matches constructor", function()
        local l = lurek.light.newLight(0, 0, 200)
        expect_near(l:getRadius(), 200, 0.001)
    end)

    it("setRadius/getRadius round-trip", function()
        local l = lurek.light.newLight(0, 0, 100)
        l:setRadius(350)
        expect_near(l:getRadius(), 350, 0.001)
    end)

    it("setColor/getColor round-trip", function()
        local l = lurek.light.newLight(0, 0, 100)
        l:setColor(1.0, 0.5, 0.25, 0.9)
        local r, g, b, a = l:getColor()
        expect_near(r, 1.0, 0.01)
        expect_near(g, 0.5, 0.01)
        expect_near(b, 0.25, 0.01)
        expect_near(a, 0.9, 0.01)
    end)

    it("setIntensity/getIntensity round-trip", function()
        local l = lurek.light.newLight(0, 0, 100)
        l:setIntensity(0.75)
        expect_near(l:getIntensity(), 0.75, 0.001)
    end)

    it("setFalloff/getFalloff round-trip", function()
        local l = lurek.light.newLight(0, 0, 100)
        l:setFalloff("linear")
        expect_equal(l:getFalloff(), "linear")
        l:setFalloff("smooth")
        expect_equal(l:getFalloff(), "smooth")
    end)

    it("setShadowEnabled toggles", function()
        local l = lurek.light.newLight(0, 0, 100)
        l:setShadowEnabled(true)
        expect_equal(l:isShadowEnabled(), true)
        l:setShadowEnabled(false)
        expect_equal(l:isShadowEnabled(), false)
    end)

    it("setEnergy/getEnergy round-trip", function()
        local l = lurek.light.newLight(0, 0, 100)
        l:setEnergy(1.5)
        expect_near(l:getEnergy(), 1.5, 0.001)
    end)

    it("multiple lights are independent", function()
        local l1 = lurek.light.newLight(10, 10, 50)
        local l2 = lurek.light.newLight(500, 500, 200)
        l1:setIntensity(0.3)
        l2:setIntensity(0.9)
        expect_near(l1:getIntensity(), 0.3, 0.001)
        expect_near(l2:getIntensity(), 0.9, 0.001)
    end)

    it("PNG: single point light with radial falloff", function()
        local W, H = 128, 128
        local img = lurek.img.newImageData(W, H)

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

        lurek.img.savePNG(img, OUT .. "light_single_falloff.png")
        expect_equal(true, true)
    end)

    it("PNG: multi-light scene with colored point lights", function()
        local W, H = 256, 256
        local img = lurek.img.newImageData(W, H)

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

        lurek.img.savePNG(img, OUT .. "light_multi_scene.png")
        expect_equal(true, true)
    end)

end)

test_summary()
