-- Lurek2D lurek.light.* API Tests

-- Module-level functions

-- @describe lurek.light module functions
describe("lurek.light module functions", function()
    -- @covers lurek.light
    it("lurek.light is a table", function()
        expect_type("table", lurek.light)
    end)

    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("newLight returns userdata", function()
        lurek.light.clear()
        local l = lurek.light.newLight(100, 200, 50)
        expect_type("userdata", l)
        l:remove()
    end)

    -- @covers LLight:getBlendMode
    -- @covers LLight:getColor
    -- @covers LLight:getEnergy
    -- @covers LLight:getFalloff
    -- @covers LLight:getIntensity
    -- @covers LLight:getLightMask
    -- @covers LLight:getPosition
    -- @covers LLight:getRadius
    -- @covers LLight:getShadowColor
    -- @covers LLight:getShadowFilter
    -- @covers LLight:getShadowMask
    -- @covers LLight:getShadowSmooth
    -- @covers LLight:isEnabled
    -- @covers LLight:isShadowEnabled
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("newLight with opts applies settings", function()
        lurek.light.clear()
        local l = lurek.light.newLight(10, 20, 30, {
            color = {0.5, 0.6, 0.7, 0.8},
            intensity = 2.0,
            energy = 3.0,
            blend = "sub",
            falloff = "smooth",
            shadowEnabled = true,
            shadowColor = {0.1, 0.2, 0.3, 0.9},
            shadowFilter = "pcf5",
            shadowSmooth = 2.5,
            lightMask = 127,
            shadowMask = 63,
            enabled = false,
        })
        expect_type("userdata", l)
        local x, y = l:getPosition()
        expect_near(x, 10, 0.001)
        expect_near(y, 20, 0.001)
        expect_near(l:getRadius(), 30, 0.001)
        local r, g, b, a = l:getColor()
        expect_near(r, 0.5, 0.001)
        expect_near(g, 0.6, 0.001)
        expect_near(b, 0.7, 0.001)
        expect_near(a, 0.8, 0.001)
        expect_near(l:getIntensity(), 2.0, 0.001)
        expect_near(l:getEnergy(), 3.0, 0.001)
        expect_equal(l:getBlendMode(), "sub")
        expect_equal(l:getFalloff(), "smooth")
        expect_true(l:isShadowEnabled())
        local sr, sg, sb, sa = l:getShadowColor()
        expect_near(sr, 0.1, 0.001)
        expect_near(sg, 0.2, 0.001)
        expect_near(sb, 0.3, 0.001)
        expect_near(sa, 0.9, 0.001)
        expect_equal(l:getShadowFilter(), "pcf5")
        expect_near(l:getShadowSmooth(), 2.5, 0.001)
        expect_equal(l:getLightMask(), 127)
        expect_equal(l:getShadowMask(), 63)
        expect_false(l:isEnabled())
        l:remove()
    end)

    -- @covers LOccluder:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("newOccluder returns userdata for valid polygon", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 100, 0, 50, 80})
        expect_type("userdata", o)
        o:remove()
    end)

    -- @covers LOccluder:getLightMask
    -- @covers LOccluder:getOpacity
    -- @covers LOccluder:isEnabled
    -- @covers LOccluder:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("newOccluder with opts applies settings", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 100, 0, 50, 80}, {
            opacity = 0.75,
            lightMask = 42,
            enabled = false,
        })
        expect_near(o:getOpacity(), 0.75, 0.001)
        expect_equal(o:getLightMask(), 42)
        expect_false(o:isEnabled())
        o:remove()
    end)

    -- @covers lurek.light.newOccluder
    it("newOccluder errors on fewer than 6 numbers", function()
        expect_error(function()
            lurek.light.newOccluder({0, 0, 100, 0})
        end)
    end)

    -- @covers lurek.light.newOccluder
    it("newOccluder errors on odd number count", function()
        expect_error(function()
            lurek.light.newOccluder({0, 0, 100, 0, 50})
        end)
    end)

    -- @covers lurek.light.clear
    -- @covers lurek.light.getAmbient
    -- @covers lurek.light.setAmbient
    it("setAmbient / getAmbient round-trip (rgb)", function()
        lurek.light.clear()
        lurek.light.setAmbient(0.3, 0.4, 0.5)
        local r, g, b, a = lurek.light.getAmbient()
        expect_near(r, 0.3, 0.001)
        expect_near(g, 0.4, 0.001)
        expect_near(b, 0.5, 0.001)
        expect_near(a, 1.0, 0.001)
    end)

    -- @covers lurek.light.clear
    -- @covers lurek.light.getAmbient
    -- @covers lurek.light.setAmbient
    it("setAmbient / getAmbient round-trip (rgba)", function()
        lurek.light.clear()
        lurek.light.setAmbient(0.2, 0.3, 0.4, 0.8)
        local r, g, b, a = lurek.light.getAmbient()
        expect_near(r, 0.2, 0.001)
        expect_near(g, 0.3, 0.001)
        expect_near(b, 0.4, 0.001)
        expect_near(a, 0.8, 0.001)
    end)

    -- @covers lurek.light.clear
    -- @covers lurek.light.isEnabled
    -- @covers lurek.light.setEnabled
    it("setEnabled / isEnabled round-trip", function()
        lurek.light.clear()
        lurek.light.setEnabled(false)
        expect_false(lurek.light.isEnabled())
        lurek.light.setEnabled(true)
        expect_true(lurek.light.isEnabled())
    end)

    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.isEnabled
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setEnabled
    it("auto-enables after first newLight", function()
        lurek.light.clear()
        lurek.light.setEnabled(false)
        expect_false(lurek.light.isEnabled())
        local l = lurek.light.newLight(0, 0, 10)
        expect_true(lurek.light.isEnabled())
        l:remove()
    end)

    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.getLightCount
    -- @covers lurek.light.newLight
    it("getLightCount tracks add/remove", function()
        lurek.light.clear()
        expect_equal(lurek.light.getLightCount(), 0)
        local l1 = lurek.light.newLight(0, 0, 10)
        expect_equal(lurek.light.getLightCount(), 1)
        local l2 = lurek.light.newLight(50, 50, 20)
        expect_equal(lurek.light.getLightCount(), 2)
        l1:remove()
        expect_equal(lurek.light.getLightCount(), 1)
        l2:remove()
        expect_equal(lurek.light.getLightCount(), 0)
    end)

    -- @covers LOccluder:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.getOccluderCount
    -- @covers lurek.light.newOccluder
    it("getOccluderCount tracks add/remove", function()
        lurek.light.clear()
        expect_equal(lurek.light.getOccluderCount(), 0)
        local o1 = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        expect_equal(lurek.light.getOccluderCount(), 1)
        local o2 = lurek.light.newOccluder({20, 20, 30, 20, 25, 30})
        expect_equal(lurek.light.getOccluderCount(), 2)
        o1:remove()
        expect_equal(lurek.light.getOccluderCount(), 1)
        o2:remove()
        expect_equal(lurek.light.getOccluderCount(), 0)
    end)

    -- @covers lurek.light.clear
    -- @covers lurek.light.getMaxLights
    -- @covers lurek.light.setMaxLights
    it("getMaxLights / setMaxLights round-trip", function()
        lurek.light.clear()
        lurek.light.setMaxLights(128)
        expect_equal(lurek.light.getMaxLights(), 128)
    end)

    -- @covers lurek.light.getMaxLights
    -- @covers lurek.light.setMaxLights
    it("setMaxLights clamps to 1..256", function()
        lurek.light.setMaxLights(0)
        expect_equal(lurek.light.getMaxLights(), 1)
        lurek.light.setMaxLights(999)
        expect_equal(lurek.light.getMaxLights(), 256)
    end)

    -- @covers lurek.light.clear
    -- @covers lurek.light.getAmbient
    -- @covers lurek.light.getLightCount
    -- @covers lurek.light.getOccluderCount
    -- @covers lurek.light.newLight
    -- @covers lurek.light.newOccluder
    -- @covers lurek.light.setAmbient
    it("clear resets counts and ambient", function()
        local l = lurek.light.newLight(0, 0, 10)
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        lurek.light.setAmbient(1.0, 1.0, 1.0)
        lurek.light.clear()
        expect_equal(lurek.light.getLightCount(), 0)
        expect_equal(lurek.light.getOccluderCount(), 0)
        local r, g, b, a = lurek.light.getAmbient()
        expect_near(r, 0.1, 0.001)
        expect_near(g, 0.1, 0.001)
        expect_near(b, 0.1, 0.001)
        expect_near(a, 1.0, 0.001)
    end)
end)

-- Light handle methods

-- @describe Light handle methods
describe("Light handle methods", function()
    -- @covers LLight:getPosition
    -- @covers LLight:remove
    -- @covers LLight:setPosition
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setPosition / getPosition", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setPosition(42, 99)
        local x, y = l:getPosition()
        expect_near(x, 42, 0.001)
        expect_near(y, 99, 0.001)
        l:remove()
    end)

    -- @covers LLight:getRadius
    -- @covers LLight:remove
    -- @covers LLight:setRadius
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setRadius / getRadius", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setRadius(77.5)
        expect_near(l:getRadius(), 77.5, 0.001)
        l:remove()
    end)

    -- @covers LLight:getColor
    -- @covers LLight:remove
    -- @covers LLight:setColor
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setColor / getColor (rgb)", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setColor(0.2, 0.4, 0.6)
        local r, g, b, a = l:getColor()
        expect_near(r, 0.2, 0.001)
        expect_near(g, 0.4, 0.001)
        expect_near(b, 0.6, 0.001)
        expect_near(a, 1.0, 0.001)
        l:remove()
    end)

    -- @covers LLight:getColor
    -- @covers LLight:remove
    -- @covers LLight:setColor
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setColor / getColor (rgba)", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setColor(0.1, 0.2, 0.3, 0.5)
        local r, g, b, a = l:getColor()
        expect_near(r, 0.1, 0.001)
        expect_near(g, 0.2, 0.001)
        expect_near(b, 0.3, 0.001)
        expect_near(a, 0.5, 0.001)
        l:remove()
    end)

    -- @covers LLight:getIntensity
    -- @covers LLight:remove
    -- @covers LLight:setIntensity
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setIntensity / getIntensity", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setIntensity(3.5)
        expect_near(l:getIntensity(), 3.5, 0.001)
        l:remove()
    end)

    -- @covers LLight:getEnergy
    -- @covers LLight:remove
    -- @covers LLight:setEnergy
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setEnergy / getEnergy", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setEnergy(2.0)
        expect_near(l:getEnergy(), 2.0, 0.001)
        l:remove()
    end)

    -- @covers LLight:getBlendMode
    -- @covers LLight:getFalloff
    -- @covers LLight:getShadowFilter
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("new light defaults for blend, falloff, and shadow filter", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_equal(l:getBlendMode(), "add")
        expect_equal(l:getFalloff(), "linear")
        expect_equal(l:getShadowFilter(), "none")
        l:remove()
    end)

    -- @covers LLight:getBlendMode
    -- @covers LLight:remove
    -- @covers LLight:setBlendMode
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setBlendMode / getBlendMode - add", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setBlendMode("add")
        expect_equal(l:getBlendMode(), "add")
        l:remove()
    end)

    -- @covers LLight:getBlendMode
    -- @covers LLight:remove
    -- @covers LLight:setBlendMode
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setBlendMode / getBlendMode - sub", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setBlendMode("sub")
        expect_equal(l:getBlendMode(), "sub")
        l:remove()
    end)

    -- @covers LLight:getBlendMode
    -- @covers LLight:remove
    -- @covers LLight:setBlendMode
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setBlendMode / getBlendMode - mix", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setBlendMode("mix")
        expect_equal(l:getBlendMode(), "mix")
        l:remove()
    end)

    -- @covers LLight:getFalloff
    -- @covers LLight:remove
    -- @covers LLight:setFalloff
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setFalloff / getFalloff - smooth", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setFalloff("smooth")
        expect_equal(l:getFalloff(), "smooth")
        l:remove()
    end)

    -- @covers LLight:getFalloff
    -- @covers LLight:remove
    -- @covers LLight:setFalloff
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setFalloff / getFalloff - constant", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setFalloff("constant")
        expect_equal(l:getFalloff(), "constant")
        l:remove()
    end)

    -- @covers LLight:getFalloff
    -- @covers LLight:remove
    -- @covers LLight:setFalloff
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setFalloff / getFalloff - linear", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setFalloff("linear")
        expect_equal(l:getFalloff(), "linear")
        l:remove()
    end)

    -- @covers LLight:isShadowEnabled
    -- @covers LLight:remove
    -- @covers LLight:setShadowEnabled
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setShadowEnabled / isShadowEnabled", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_false(l:isShadowEnabled())
        l:setShadowEnabled(true)
        expect_true(l:isShadowEnabled())
        l:setShadowEnabled(false)
        expect_false(l:isShadowEnabled())
        l:remove()
    end)

    -- @covers LLight:getShadowColor
    -- @covers LLight:remove
    -- @covers LLight:setShadowColor
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setShadowColor / getShadowColor", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowColor(0.1, 0.2, 0.3, 0.9)
        local r, g, b, a = l:getShadowColor()
        expect_near(r, 0.1, 0.001)
        expect_near(g, 0.2, 0.001)
        expect_near(b, 0.3, 0.001)
        expect_near(a, 0.9, 0.001)
        l:remove()
    end)

    -- @covers LLight:getShadowFilter
    -- @covers LLight:remove
    -- @covers LLight:setShadowFilter
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setShadowFilter / getShadowFilter - pcf5", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowFilter("pcf5")
        expect_equal(l:getShadowFilter(), "pcf5")
        l:remove()
    end)

    -- @covers LLight:getShadowFilter
    -- @covers LLight:remove
    -- @covers LLight:setShadowFilter
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setShadowFilter / getShadowFilter - pcf13", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowFilter("pcf13")
        expect_equal(l:getShadowFilter(), "pcf13")
        l:remove()
    end)

    -- @covers LLight:getShadowFilter
    -- @covers LLight:remove
    -- @covers LLight:setShadowFilter
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setShadowFilter / getShadowFilter - none", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowFilter("none")
        expect_equal(l:getShadowFilter(), "none")
        l:remove()
    end)

    -- @covers LLight:getShadowSmooth
    -- @covers LLight:remove
    -- @covers LLight:setShadowSmooth
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setShadowSmooth / getShadowSmooth", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowSmooth(2.0)
        expect_near(l:getShadowSmooth(), 2.0, 0.001)
        l:remove()
    end)

    -- @covers LLight:getLightMask
    -- @covers LLight:remove
    -- @covers LLight:setLightMask
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setLightMask / getLightMask", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setLightMask(255)
        expect_equal(l:getLightMask(), 255)
        l:remove()
    end)

    -- @covers LLight:getShadowMask
    -- @covers LLight:remove
    -- @covers LLight:setShadowMask
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setShadowMask / getShadowMask", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowMask(127)
        expect_equal(l:getShadowMask(), 127)
        l:remove()
    end)

    -- @covers LLight:isEnabled
    -- @covers LLight:remove
    -- @covers LLight:setEnabled
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setEnabled / isEnabled on light handle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_true(l:isEnabled())
        l:setEnabled(false)
        expect_false(l:isEnabled())
        l:setEnabled(true)
        expect_true(l:isEnabled())
        l:remove()
    end)

    -- @covers LLight:isValid
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("isValid returns true before remove", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_true(l:isValid())
        l:remove()
    end)

    -- @covers LLight:isValid
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("isValid returns false after remove", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:remove()
        expect_false(l:isValid())
    end)
end)

-- Occluder handle methods

-- @describe Occluder handle methods
describe("Occluder handle methods", function()
    -- @covers LOccluder:getPosition
    -- @covers LOccluder:remove
    -- @covers LOccluder:setPosition
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("setPosition / getPosition", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        o:setPosition(15, 25)
        local x, y = o:getPosition()
        expect_near(x, 15, 0.001)
        expect_near(y, 25, 0.001)
        o:remove()
    end)

    -- @covers LOccluder:getOpacity
    -- @covers LOccluder:remove
    -- @covers LOccluder:setOpacity
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("setOpacity / getOpacity", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        o:setOpacity(0.5)
        expect_near(o:getOpacity(), 0.5, 0.001)
        o:remove()
    end)

    -- @covers LOccluder:getLightMask
    -- @covers LOccluder:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("default light mask is all bits set", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        expect_equal(o:getLightMask(), 65535)
        o:remove()
    end)

    -- @covers LOccluder:getLightMask
    -- @covers LOccluder:remove
    -- @covers LOccluder:setLightMask
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("setLightMask / getLightMask", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        o:setLightMask(0)
        expect_equal(o:getLightMask(), 0)
        o:setLightMask(255)
        expect_equal(o:getLightMask(), 255)
        o:remove()
    end)

    -- @covers LOccluder:isEnabled
    -- @covers LOccluder:remove
    -- @covers LOccluder:setEnabled
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("setEnabled / isEnabled", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        expect_true(o:isEnabled())
        o:setEnabled(false)
        expect_false(o:isEnabled())
        o:setEnabled(true)
        expect_true(o:isEnabled())
        o:remove()
    end)

    -- @covers LOccluder:isValid
    -- @covers LOccluder:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("isValid returns false after remove", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        expect_true(o:isValid())
        o:remove()
        expect_false(o:isValid())
    end)

    -- @covers LOccluder:getVertices
    -- @covers LOccluder:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("getVertices returns flat table", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({10, 20, 30, 40, 50, 60})
        local verts = o:getVertices()
        expect_type("table", verts)
        expect_equal(#verts, 6)
        expect_near(verts[1], 10, 0.001)
        expect_near(verts[2], 20, 0.001)
        expect_near(verts[3], 30, 0.001)
        expect_near(verts[4], 40, 0.001)
        expect_near(verts[5], 50, 0.001)
        expect_near(verts[6], 60, 0.001)
        o:remove()
    end)

    -- @covers LOccluder:getVertices
    -- @covers LOccluder:remove
    -- @covers LOccluder:setVertices
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("setVertices replaces vertices", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        o:setVertices({1, 2, 3, 4, 5, 6})
        local verts = o:getVertices()
        expect_near(verts[1], 1, 0.001)
        expect_near(verts[2], 2, 0.001)
        expect_near(verts[3], 3, 0.001)
        expect_near(verts[4], 4, 0.001)
        expect_near(verts[5], 5, 0.001)
        expect_near(verts[6], 6, 0.001)
        o:remove()
    end)
end)

-- Edge cases

-- @describe lurek.light edge cases
describe("lurek.light edge cases", function()
    -- @covers LLight:remove
    -- @covers LLight:setBlendMode
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("invalid blend mode string errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_error(function() l:setBlendMode("bad") end)
        l:remove()
    end)

    -- @covers LLight:remove
    -- @covers LLight:setFalloff
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("invalid falloff string errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_error(function() l:setFalloff("bad") end)
        l:remove()
    end)

    -- @covers LLight:remove
    -- @covers LLight:setShadowFilter
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("invalid shadow filter string errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_error(function() l:setShadowFilter("bad") end)
        l:remove()
    end)

    -- @covers LLight:getColor
    -- @covers LLight:getIntensity
    -- @covers LLight:getPosition
    -- @covers LLight:getRadius
    -- @covers LLight:remove
    -- @covers LLight:setColor
    -- @covers LLight:setIntensity
    -- @covers LLight:setPosition
    -- @covers LLight:setRadius
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("operations on removed light error", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:remove()
        expect_error(function() l:getPosition() end)
        expect_error(function() l:setPosition(1, 2) end)
        expect_error(function() l:getRadius() end)
        expect_error(function() l:setRadius(5) end)
        expect_error(function() l:getColor() end)
        expect_error(function() l:setColor(1, 1, 1) end)
        expect_error(function() l:getIntensity() end)
        expect_error(function() l:setIntensity(1) end)
    end)

    -- @covers LOccluder:getOpacity
    -- @covers LOccluder:getPosition
    -- @covers LOccluder:getVertices
    -- @covers LOccluder:remove
    -- @covers LOccluder:setOpacity
    -- @covers LOccluder:setPosition
    -- @covers LOccluder:setVertices
    -- @covers lurek.light.clear
    -- @covers lurek.light.newOccluder
    it("operations on removed occluder error", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        o:remove()
        expect_error(function() o:getPosition() end)
        expect_error(function() o:setPosition(1, 2) end)
        expect_error(function() o:getOpacity() end)
        expect_error(function() o:setOpacity(0.5) end)
        expect_error(function() o:getVertices() end)
        expect_error(function() o:setVertices({0, 0, 1, 0, 0, 1}) end)
    end)
end)

-- New effects: Light Type

-- @describe Light type
describe("Light type", function()
    -- @covers LLight:getLightType
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default is point", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getLightType(), "point")
        l:remove()
    end)

    -- @covers LLight:getLightType
    -- @covers LLight:remove
    -- @covers LLight:setLightType
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setLightType to spot and back", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setLightType("spot")
        expect_equal(l:getLightType(), "spot")
        l:setLightType("directional")
        expect_equal(l:getLightType(), "directional")
        l:setLightType("point")
        expect_equal(l:getLightType(), "point")
        l:remove()
    end)

    -- @covers LLight:remove
    -- @covers LLight:setLightType
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("invalid light type errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_error(function() l:setLightType("laser") end)
        l:remove()
    end)
end)

-- Light Direction and Angles

-- @describe Light direction and angles
describe("Light direction and angles", function()
    -- @covers LLight:getDirection
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default direction is 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_near(l:getDirection(), 0, 0.001)
        l:remove()
    end)

    -- @covers LLight:getDirection
    -- @covers LLight:remove
    -- @covers LLight:setDirection
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setDirection / getDirection", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setDirection(1.57)
        expect_near(l:getDirection(), 1.57, 0.001)
        l:remove()
    end)

    -- @covers LLight:getInnerAngle
    -- @covers LLight:remove
    -- @covers LLight:setInnerAngle
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setInnerAngle / getInnerAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setInnerAngle(0.3)
        expect_near(l:getInnerAngle(), 0.3, 0.001)
        l:remove()
    end)

    -- @covers LLight:getOuterAngle
    -- @covers LLight:remove
    -- @covers LLight:setOuterAngle
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setOuterAngle / getOuterAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setOuterAngle(0.6)
        expect_near(l:getOuterAngle(), 0.6, 0.001)
        l:remove()
    end)

    -- @covers LLight:getInnerAngle
    -- @covers LLight:getOuterAngle
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default angles are pi/6 and pi/4", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_near(l:getInnerAngle(), math.pi / 6, 0.001)
        expect_near(l:getOuterAngle(), math.pi / 4, 0.001)
        l:remove()
    end)
end)

-- Light Attenuation

-- @describe Light attenuation
describe("Light attenuation", function()
    -- @covers LLight:getAttenuation
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default attenuation is 1 0 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        local c, lin, q = l:getAttenuation()
        expect_near(c, 1.0, 0.001)
        expect_near(lin, 0.0, 0.001)
        expect_near(q, 0.0, 0.001)
        l:remove()
    end)

    -- @covers LLight:getAttenuation
    -- @covers LLight:remove
    -- @covers LLight:setAttenuation
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setAttenuation / getAttenuation", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setAttenuation(1.0, 0.09, 0.032)
        local c, lin, q = l:getAttenuation()
        expect_near(c, 1.0, 0.001)
        expect_near(lin, 0.09, 0.001)
        expect_near(q, 0.032, 0.001)
        l:remove()
    end)
end)

-- Light Flicker

-- @describe Light flicker
describe("Light flicker", function()
    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default flicker disabled", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:isFlickerEnabled(), false)
        l:remove()
    end)

    -- @covers LLight:getFlicker
    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers LLight:setFlicker
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setFlicker enables and sets values", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setFlicker(10.0, 0.25)
        local speed, strength = l:getFlicker()
        expect_near(speed, 10.0, 0.001)
        expect_near(strength, 0.25, 0.001)
        expect_equal(l:isFlickerEnabled(), true)
        l:remove()
    end)

    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers LLight:setFlicker
    -- @covers LLight:setFlickerEnabled
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setFlickerEnabled toggles", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setFlicker(10.0, 0.25)
        l:setFlickerEnabled(false)
        expect_equal(l:isFlickerEnabled(), false)
        l:setFlickerEnabled(true)
        expect_equal(l:isFlickerEnabled(), true)
        l:remove()
    end)

    -- @covers LLight:addFlicker
    -- @covers LLight:getFlicker
    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("addFlicker derives speed and strength from range", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:addFlicker(0.8, 1.2, 2.0)
        local speed, strength = l:getFlicker()
        expect_near(speed, math.pi * 4.0, 0.001)
        expect_near(strength, 0.2, 0.001)
        expect_equal(l:isFlickerEnabled(), true)
        l:remove()
    end)
end)

-- Light Groups

-- @describe Light groups
describe("Light groups", function()
    -- @covers LLight:getGroupId
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default group is 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getGroupId(), 0)
        l:remove()
    end)

    -- @covers LLight:getGroupId
    -- @covers LLight:remove
    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setGroupId / getGroupId", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setGroupId(5)
        expect_equal(l:getGroupId(), 5)
        l:remove()
    end)

    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.getGroupCount
    -- @covers lurek.light.newLight
    it("getGroupCount returns count", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        local l2 = lurek.light.newLight(10, 10, 50)
        l1:setGroupId(1)
        l2:setGroupId(1)
        expect_equal(lurek.light.getGroupCount(1), 2)
        expect_equal(lurek.light.getGroupCount(0), 0)
        lurek.light.clear()
    end)

    -- @covers LLight:isEnabled
    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setGroupEnabled
    it("setGroupEnabled disables a group", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        local l2 = lurek.light.newLight(10, 10, 50)
        local l3 = lurek.light.newLight(20, 20, 50)
        l1:setGroupId(2)
        l2:setGroupId(2)
        -- l3 stays group 0
        lurek.light.setGroupEnabled(2, false)
        expect_equal(l1:isEnabled(), false)
        expect_equal(l2:isEnabled(), false)
        expect_equal(l3:isEnabled(), true) -- unaffected
        lurek.light.clear()
    end)

    -- @covers LLight:getIntensity
    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setGroupIntensity
    it("setGroupIntensity changes group intensity", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        l1:setGroupId(3)
        lurek.light.setGroupIntensity(3, 0.5)
        expect_near(l1:getIntensity(), 0.5, 0.001)
        lurek.light.clear()
    end)

    -- @covers LLight:getColor
    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setGroupColor
    it("setGroupColor changes group color", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        l1:setGroupId(4)
        lurek.light.setGroupColor(4, 1.0, 0.0, 0.0, 1.0)
        local r, g, b, a = l1:getColor()
        expect_near(r, 1.0, 0.001)
        expect_near(g, 0.0, 0.001)
        expect_near(b, 0.0, 0.001)
        expect_near(a, 1.0, 0.001)
        lurek.light.clear()
    end)
end)

-- Light Volumetric

-- @describe Light volumetric
describe("Light volumetric", function()
    -- @covers LLight:isVolumetric
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default not volumetric", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:isVolumetric(), false)
        l:remove()
    end)

    -- @covers LLight:isVolumetric
    -- @covers LLight:remove
    -- @covers LLight:setVolumetric
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setVolumetric / isVolumetric", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setVolumetric(true)
        expect_equal(l:isVolumetric(), true)
        l:setVolumetric(false)
        expect_equal(l:isVolumetric(), false)
        l:remove()
    end)
end)

-- advanceFlickers

-- @describe advanceFlickers
describe("advanceFlickers", function()
    -- @covers LLight:remove
    -- @covers LLight:setFlicker
    -- @covers lurek.light.advanceFlickers
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("advanceFlickers does not error", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setFlicker(10.0, 0.15)
        lurek.light.advanceFlickers(0.1)
        -- No error means success (phase is internal)
        l:remove()
    end)
end)

-- newLight opts with new fields

-- @describe newLight opts with new effects
describe("newLight opts with new effects", function()
    -- @covers LLight:getLightType
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts type sets light type", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { type = "spot" })
        expect_equal(l:getLightType(), "spot")
        l:remove()
    end)

    -- @covers LLight:getDirection
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts direction sets direction", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { direction = 1.57 })
        expect_near(l:getDirection(), 1.57, 0.001)
        l:remove()
    end)

    -- @covers LLight:getInnerAngle
    -- @covers LLight:getOuterAngle
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts innerAngle and outerAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { innerAngle = 0.3, outerAngle = 0.6 })
        expect_near(l:getInnerAngle(), 0.3, 0.001)
        expect_near(l:getOuterAngle(), 0.6, 0.001)
        l:remove()
    end)

    -- @covers LLight:getGroupId
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts groupId sets group", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { groupId = 7 })
        expect_equal(l:getGroupId(), 7)
        l:remove()
    end)

    -- @covers LLight:isVolumetric
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts volumetric sets flag", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { volumetric = true })
        expect_equal(l:isVolumetric(), true)
        l:remove()
    end)

    -- @covers LLight:getFlicker
    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts flickerSpeed and flickerStrength enable flicker", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, {
            flickerSpeed = 12.0,
            flickerStrength = 0.3
        })
        expect_equal(l:isFlickerEnabled(), true)
        local speed, strength = l:getFlicker()
        expect_near(speed, 12.0, 0.001)
        expect_near(strength, 0.3, 0.001)
        l:remove()
    end)

    -- @covers LLight:getAttenuation
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts attenuation coefficients", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, {
            attConstant = 1.0,
            attLinear = 0.09,
            attQuadratic = 0.032,
        })
        local c, lin, q = l:getAttenuation()
        expect_near(c, 1.0, 0.001)
        expect_near(lin, 0.09, 0.001)
        expect_near(q, 0.032, 0.001)
        l:remove()
    end)
end)

-- New effects: Light Type

-- @describe Light type
describe("Light type", function()
    -- @covers LLight:getLightType
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default is point", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getLightType(), "point")
        l:remove()
    end)

    -- @covers LLight:getLightType
    -- @covers LLight:remove
    -- @covers LLight:setLightType
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setLightType to spot and back", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setLightType("spot")
        expect_equal(l:getLightType(), "spot")
        l:setLightType("directional")
        expect_equal(l:getLightType(), "directional")
        l:setLightType("point")
        expect_equal(l:getLightType(), "point")
        l:remove()
    end)

    -- @covers LLight:remove
    -- @covers LLight:setLightType
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("invalid light type errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_error(function() l:setLightType("laser") end)
        l:remove()
    end)
end)

-- Light Direction and Angles

-- @describe Light direction and angles
describe("Light direction and angles", function()
    -- @covers LLight:getDirection
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default direction is 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_near(l:getDirection(), 0, 0.001)
        l:remove()
    end)

    -- @covers LLight:getDirection
    -- @covers LLight:remove
    -- @covers LLight:setDirection
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setDirection / getDirection", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setDirection(1.57)
        expect_near(l:getDirection(), 1.57, 0.001)
        l:remove()
    end)

    -- @covers LLight:getInnerAngle
    -- @covers LLight:remove
    -- @covers LLight:setInnerAngle
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setInnerAngle / getInnerAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setInnerAngle(0.3)
        expect_near(l:getInnerAngle(), 0.3, 0.001)
        l:remove()
    end)

    -- @covers LLight:getOuterAngle
    -- @covers LLight:remove
    -- @covers LLight:setOuterAngle
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setOuterAngle / getOuterAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setOuterAngle(0.6)
        expect_near(l:getOuterAngle(), 0.6, 0.001)
        l:remove()
    end)

    -- @covers LLight:getInnerAngle
    -- @covers LLight:getOuterAngle
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default angles are pi/6 and pi/4", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_near(l:getInnerAngle(), math.pi / 6, 0.001)
        expect_near(l:getOuterAngle(), math.pi / 4, 0.001)
        l:remove()
    end)
end)

-- Light Attenuation

-- @describe Light attenuation
describe("Light attenuation", function()
    -- @covers LLight:getAttenuation
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default attenuation is 1 0 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        local c, lin, q = l:getAttenuation()
        expect_near(c, 1.0, 0.001)
        expect_near(lin, 0.0, 0.001)
        expect_near(q, 0.0, 0.001)
        l:remove()
    end)

    -- @covers LLight:getAttenuation
    -- @covers LLight:remove
    -- @covers LLight:setAttenuation
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setAttenuation / getAttenuation", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setAttenuation(1.0, 0.09, 0.032)
        local c, lin, q = l:getAttenuation()
        expect_near(c, 1.0, 0.001)
        expect_near(lin, 0.09, 0.001)
        expect_near(q, 0.032, 0.001)
        l:remove()
    end)
end)

-- Light Flicker

-- @describe Light flicker
describe("Light flicker", function()
    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default flicker disabled", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:isFlickerEnabled(), false)
        l:remove()
    end)

    -- @covers LLight:getFlicker
    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers LLight:setFlicker
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setFlicker enables and sets values", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setFlicker(10.0, 0.25)
        local speed, strength = l:getFlicker()
        expect_near(speed, 10.0, 0.001)
        expect_near(strength, 0.25, 0.001)
        expect_equal(l:isFlickerEnabled(), true)
        l:remove()
    end)

    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers LLight:setFlicker
    -- @covers LLight:setFlickerEnabled
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setFlickerEnabled toggles", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setFlicker(10.0, 0.25)
        l:setFlickerEnabled(false)
        expect_equal(l:isFlickerEnabled(), false)
        l:setFlickerEnabled(true)
        expect_equal(l:isFlickerEnabled(), true)
        l:remove()
    end)
end)

-- Light Groups

-- @describe Light groups
describe("Light groups", function()
    -- @covers LLight:getGroupId
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default group is 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getGroupId(), 0)
        l:remove()
    end)

    -- @covers LLight:getGroupId
    -- @covers LLight:remove
    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setGroupId / getGroupId", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setGroupId(5)
        expect_equal(l:getGroupId(), 5)
        l:remove()
    end)

    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.getGroupCount
    -- @covers lurek.light.newLight
    it("getGroupCount returns count", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        local l2 = lurek.light.newLight(10, 10, 50)
        l1:setGroupId(1)
        l2:setGroupId(1)
        expect_equal(lurek.light.getGroupCount(1), 2)
        expect_equal(lurek.light.getGroupCount(0), 0)
        lurek.light.clear()
    end)

    -- @covers LLight:isEnabled
    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setGroupEnabled
    it("setGroupEnabled disables a group", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        local l2 = lurek.light.newLight(10, 10, 50)
        local l3 = lurek.light.newLight(20, 20, 50)
        l1:setGroupId(2)
        l2:setGroupId(2)
        -- l3 stays group 0
        lurek.light.setGroupEnabled(2, false)
        expect_equal(l1:isEnabled(), false)
        expect_equal(l2:isEnabled(), false)
        expect_equal(l3:isEnabled(), true) -- unaffected
        lurek.light.clear()
    end)

    -- @covers LLight:getIntensity
    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setGroupIntensity
    it("setGroupIntensity changes group intensity", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        l1:setGroupId(3)
        lurek.light.setGroupIntensity(3, 0.5)
        expect_near(l1:getIntensity(), 0.5, 0.001)
        lurek.light.clear()
    end)

    -- @covers LLight:getColor
    -- @covers LLight:setGroupId
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    -- @covers lurek.light.setGroupColor
    it("setGroupColor changes group color", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        l1:setGroupId(4)
        lurek.light.setGroupColor(4, 1.0, 0.0, 0.0, 1.0)
        local r, g, b, a = l1:getColor()
        expect_near(r, 1.0, 0.001)
        expect_near(g, 0.0, 0.001)
        expect_near(b, 0.0, 0.001)
        expect_near(a, 1.0, 0.001)
        lurek.light.clear()
    end)
end)

-- Light Volumetric

-- @describe Light volumetric
describe("Light volumetric", function()
    -- @covers LLight:isVolumetric
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("default not volumetric", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:isVolumetric(), false)
        l:remove()
    end)

    -- @covers LLight:isVolumetric
    -- @covers LLight:remove
    -- @covers LLight:setVolumetric
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setVolumetric / isVolumetric", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setVolumetric(true)
        expect_equal(l:isVolumetric(), true)
        l:setVolumetric(false)
        expect_equal(l:isVolumetric(), false)
        l:remove()
    end)
end)

-- advanceFlickers

-- @describe advanceFlickers
describe("advanceFlickers", function()
    -- @covers LLight:remove
    -- @covers LLight:setFlicker
    -- @covers lurek.light.advanceFlickers
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("advanceFlickers does not error", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setFlicker(10.0, 0.15)
        lurek.light.advanceFlickers(0.1)
        -- No error means success (phase is internal)
        l:remove()
    end)
end)

-- newLight opts with new fields

-- @describe newLight opts with new effects
describe("newLight opts with new effects", function()
    -- @covers LLight:getLightType
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts type sets light type", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { type = "spot" })
        expect_equal(l:getLightType(), "spot")
        l:remove()
    end)

    -- @covers LLight:getDirection
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts direction sets direction", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { direction = 1.57 })
        expect_near(l:getDirection(), 1.57, 0.001)
        l:remove()
    end)

    -- @covers LLight:getInnerAngle
    -- @covers LLight:getOuterAngle
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts innerAngle and outerAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { innerAngle = 0.3, outerAngle = 0.6 })
        expect_near(l:getInnerAngle(), 0.3, 0.001)
        expect_near(l:getOuterAngle(), 0.6, 0.001)
        l:remove()
    end)

    -- @covers LLight:getGroupId
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts groupId sets group", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { groupId = 7 })
        expect_equal(l:getGroupId(), 7)
        l:remove()
    end)

    -- @covers LLight:isVolumetric
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts volumetric sets flag", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { volumetric = true })
        expect_equal(l:isVolumetric(), true)
        l:remove()
    end)

    -- @covers LLight:getFlicker
    -- @covers LLight:isFlickerEnabled
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts flickerSpeed and flickerStrength enable flicker", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, {
            flickerSpeed = 12.0,
            flickerStrength = 0.3
        })
        expect_equal(l:isFlickerEnabled(), true)
        local speed, strength = l:getFlicker()
        expect_near(speed, 12.0, 0.001)
        expect_near(strength, 0.3, 0.001)
        l:remove()
    end)

    -- @covers LLight:getAttenuation
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("opts attenuation coefficients", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, {
            attConstant = 1.0,
            attLinear = 0.09,
            attQuadratic = 0.032,
        })
        local c, lin, q = l:getAttenuation()
        expect_near(c, 1.0, 0.001)
        expect_near(lin, 0.09, 0.001)
        expect_near(q, 0.032, 0.001)
        l:remove()
    end)
end)

--  Ambient Bridge & God-Ray Hints (merged from test_light_godrays.lua)

-- @describe API exposure
describe("API exposure", function()
    -- @covers lurek.light.syncAmbient
    it("exposes syncAmbient", function()
        expect_type("function", lurek.light.syncAmbient)
    end)

    -- @covers lurek.light.getGodRayHints
    it("exposes getGodRayHints", function()
        expect_type("function", lurek.light.getGodRayHints)
    end)
end)

-- @describe syncAmbient()
describe("syncAmbient()", function()
    -- @covers lurek.light.syncAmbient
    it("returns four numeric values", function()
        local r, g, b, a = lurek.light.syncAmbient()
        expect_type("number", r)
        expect_type("number", g)
        expect_type("number", b)
        expect_type("number", a)
    end)

    -- @covers lurek.light.syncAmbient
    it("alpha component is in [0, 1]", function()
        local _, _, _, a = lurek.light.syncAmbient()
        expect_true(a >= 0.0 and a <= 1.0,
            "alpha out of [0,1]: " .. tostring(a))
    end)

    -- @covers lurek.light.setAmbient
    -- @covers lurek.light.syncAmbient
    it("reflects setAmbient changes", function()
        lurek.light.setAmbient(0.2, 0.4, 0.6, 0.8)
        local r, g, b, a = lurek.light.syncAmbient()
        expect_near(0.2, r, 0.001)
        expect_near(0.4, g, 0.001)
        expect_near(0.6, b, 0.001)
        expect_near(0.8, a, 0.001)
    end)

    -- @covers lurek.light.getAmbient
    -- @covers lurek.light.setAmbient
    -- @covers lurek.light.syncAmbient
    it("matches getAmbient values", function()
        lurek.light.setAmbient(0.1, 0.3, 0.5, 1.0)
        local r1, g1, b1, a1 = lurek.light.getAmbient()
        local r2, g2, b2, a2 = lurek.light.syncAmbient()
        expect_near(r1, r2, 0.001)
        expect_near(g1, g2, 0.001)
        expect_near(b1, b2, 0.001)
        expect_near(a1, a2, 0.001)
    end)
end)

-- @describe getGodRayHints()
describe("getGodRayHints()", function()
    -- @covers lurek.light.getGodRayHints
    it("returns a table", function()
        local hints = lurek.light.getGodRayHints()
        expect_type("table", hints)
    end)

    -- @covers lurek.light.clear
    -- @covers lurek.light.getGodRayHints
    it("returns empty table with no directional lights", function()
        lurek.light.clear()
        local hints = lurek.light.getGodRayHints()
        expect_equal(0, #hints)
    end)

    -- @covers LLight:setDirection
    -- @covers LLight:setEnabled
    -- @covers lurek.light.clear
    -- @covers lurek.light.getGodRayHints
    -- @covers lurek.light.newLight
    it("each hint has x, y, angle fields", function()
        lurek.light.clear()
        local light = lurek.light.newLight(100, 200, 50, { type = "directional" })
        light:setDirection(1.57)  -- near pi/2
        light:setEnabled(true)
        local hints = lurek.light.getGodRayHints()
        expect_equal(1, #hints)
        local h = hints[1]
        expect_type("number", h.x)
        expect_type("number", h.y)
        expect_type("number", h.angle)
        expect_near(100, h.x, 0.001)
        expect_near(200, h.y, 0.001)
        expect_near(1.57, h.angle, 0.001)
    end)

    -- @covers LLight:setEnabled
    -- @covers lurek.light.clear
    -- @covers lurek.light.getGodRayHints
    -- @covers lurek.light.newLight
    it("disabled lights are excluded", function()
        lurek.light.clear()
        local light = lurek.light.newLight(0, 0, 50, { type = "directional" })
        light:setEnabled(false)
        local hints = lurek.light.getGodRayHints()
        expect_equal(0, #hints)
    end)
end)

-- =========================================================================
-- Additional Light coverage
-- =========================================================================

-- @describe Missing API Coverage
describe("Missing API Coverage", function()
    -- @covers LLight:addFlicker
    -- @covers LLight:getFlicker
    -- @covers LLight:remove
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("covers Light:addFlicker", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:addFlicker(0.9, 1.1, 3.0)
        local speed, strength = l:getFlicker()
        expect_near(speed, math.pi * 6.0, 0.001)
        expect_near(strength, 0.1, 0.001)
        l:remove()
    end)

    -- @covers LLight:getColor
    -- @covers LLight:getIntensity
    -- @covers LLight:getRadius
    -- @covers LLight:remove
    -- @covers LLight:transitionProgress
    -- @covers LLight:transitionTo
    -- @covers LLight:updateTransition
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("covers Light:updateTransition", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 100)
        l:transitionTo({ color = {0.0, 0.0, 0.0, 1.0}, intensity = 0.0, radius = 50.0 }, 2.0)
        expect_near(l:transitionProgress(), 0.0, 0.001)
        expect_equal(l:updateTransition(1.0), true)

        local r, g, b, a = l:getColor()
        expect_near(r, 0.5, 0.001)
        expect_near(g, 0.5, 0.001)
        expect_near(b, 0.5, 0.001)
        expect_near(a, 1.0, 0.001)
        expect_near(l:getIntensity(), 0.5, 0.001)
        expect_near(l:getRadius(), 75.0, 0.001)
        expect_near(l:transitionProgress(), 0.5, 0.001)

        expect_equal(l:updateTransition(1.0), true)
        local r2, g2, b2, a2 = l:getColor()
        expect_near(r2, 0.0, 0.001)
        expect_near(g2, 0.0, 0.001)
        expect_near(b2, 0.0, 0.001)
        expect_near(a2, 1.0, 0.001)
        expect_near(l:getIntensity(), 0.0, 0.001)
        expect_near(l:getRadius(), 50.0, 0.001)
        expect_near(l:transitionProgress(), 1.0, 0.001)
        expect_equal(l:updateTransition(0.1), false)
        l:remove()
    end)

    -- @covers LLight:remove
    -- @covers LLight:stopTransition
    -- @covers LLight:transitionTo
    -- @covers LLight:updateTransition
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("covers Light:stopTransition", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 20)
        l:transitionTo({ radius = 10.0 }, 1.0)
        l:stopTransition()
        expect_equal(l:updateTransition(0.1), false)
        l:remove()
    end)

    -- @covers LLight:getCookie
    -- @covers LLight:remove
    -- @covers LLight:setCookie
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("covers Light:setCookie", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setCookie("assets/lights/cookie.png")
        expect_equal(l:getCookie(), "assets/lights/cookie.png")
        l:remove()
    end)

    -- @covers LLight:getCookie
    -- @covers LLight:remove
    -- @covers LLight:setCookie
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("covers Light:getCookie", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getCookie(), nil)
        l:setCookie("assets/lights/window.png")
        expect_equal(l:getCookie(), "assets/lights/window.png")
        l:remove()
    end)

    -- @covers LLight:clearCookie
    -- @covers LLight:getCookie
    -- @covers LLight:remove
    -- @covers LLight:setCookie
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("covers Light:clearCookie", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setCookie("assets/lights/cookie.png")
        l:clearCookie()
        expect_equal(l:getCookie(), nil)
        l:remove()
    end)

end)

-- @describe light enhancements: soft shadows and normal-map hints
describe("light enhancements: soft shadows and normal-map hints", function()
    -- @covers LLight:getShadowSoftness
    -- @covers LLight:remove
    -- @covers LLight:setShadowSoftness
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setShadowSoftness / getShadowSoftness", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setShadowSoftness(1.75)
        expect_near(l:getShadowSoftness(), 1.75, 0.001)
        l:remove()
    end)

    -- @covers LLight:getNormalMap
    -- @covers LLight:getNormalStrength
    -- @covers LLight:remove
    -- @covers LLight:setNormalMap
    -- @covers LLight:setNormalStrength
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("setNormalMap / getNormalMap and setNormalStrength / getNormalStrength", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setNormalMap("assets/textures/normals/torch.png")
        l:setNormalStrength(0.65)
        expect_equal(l:getNormalMap(), "assets/textures/normals/torch.png")
        expect_near(l:getNormalStrength(), 0.65, 0.001)
        l:remove()
    end)

    -- @covers LLight:clearNormalMap
    -- @covers LLight:getNormalMap
    -- @covers LLight:remove
    -- @covers LLight:setNormalMap
    -- @covers lurek.light.clear
    -- @covers lurek.light.newLight
    it("clearNormalMap resets path to nil", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setNormalMap("assets/textures/normals/clear_me.png")
        l:clearNormalMap()
        expect_equal(l:getNormalMap(), nil)
        l:remove()
    end)

    -- @covers LLight:remove
    -- @covers LLight:setNormalMap
    -- @covers LLight:setNormalStrength
    -- @covers lurek.light.clear
    -- @covers lurek.light.getNormalMapHints
    -- @covers lurek.light.newLight
    it("getNormalMapHints returns mapped enabled lights", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(10, 20, 30)
        l1:setNormalMap("assets/textures/normals/brick.png")
        l1:setNormalStrength(1.2)

        local l2 = lurek.light.newLight(40, 50, 60)
        l2:setNormalMap("assets/textures/normals/disabled.png")
        l2:setEnabled(false)

        local hints = lurek.light.getNormalMapHints()
        expect_type("table", hints)
        expect_equal(#hints, 1)
        expect_equal(hints[1].normalMap, "assets/textures/normals/brick.png")
        expect_near(hints[1].x, 10, 0.001)
        expect_near(hints[1].y, 20, 0.001)
        expect_near(hints[1].strength, 1.2, 0.001)

        l1:remove()
        l2:remove()
    end)
end)

-- @describe light strict: LLight type/typeOf
describe("light strict: LLight type/typeOf", function()
    -- @covers LLight:type
    -- @covers LLight:typeOf
    -- @covers lurek.light.newLight
    it("LLight type and typeOf are callable", function()
        local l = lurek.light.newLight(0, 0, 50)
        expect_type("string", l:type())
        expect_type("boolean", l:typeOf("Object"))
        l:remove()
    end)

end)

-- @describe light strict: LOccluder type/typeOf
describe("light strict: LOccluder type/typeOf", function()
    -- @covers LOccluder:type
    -- @covers LOccluder:typeOf
    -- @covers lurek.light.newOccluder
    it("LOccluder type and typeOf are callable", function()
        local ok, oc = pcall(function()
            return lurek.light.newOccluder({{0,0},{10,0},{10,10},{0,10}})
        end)
        if ok and oc ~= nil then
            expect_type("string", oc:type())
            expect_type("boolean", oc:typeOf("Object"))
        else
            expect_false(ok and oc ~= nil)
        end
    end)
end)

test_summary()
