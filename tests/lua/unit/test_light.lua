-- Lurek2D lurek.light.* API Tests

-- â”€â”€ Module-level functions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies the module table, constructors, counters, ambient state, enable state, and max-light controls all round-trip through the public API.
describe("lurek.light module functions", function()
    -- @covers lurek.light.advanceFlickers
    -- @covers lurek.light.clear
    -- @covers lurek.light.getAmbient
    -- @covers lurek.light.getGroupCount
    -- @covers lurek.light.getLightCount
    -- @covers lurek.light.getMaxLights
    -- @covers lurek.light.getOccluderCount
    -- @covers lurek.light.isEnabled
    -- @covers lurek.light.newLight
    -- @covers lurek.light.newOccluder
    -- @covers lurek.light.setAmbient
    -- @covers lurek.light.setEnabled
    -- @covers lurek.light.setGroupColor
    -- @covers lurek.light.setGroupEnabled
    -- @covers lurek.light.setGroupIntensity
    -- @covers lurek.light.setMaxLights
    -- @description Asserts that lurek.light is exposed to Lua as a table.
    it("lurek.light is a table", function()
        expect_type("table", lurek.light)
    end)

    -- @description Clears state, creates one light at 100,200 with radius 50, checks that the handle is userdata, and removes it.
    it("newLight returns userdata", function()
        lurek.light.clear()
        local l = lurek.light.newLight(100, 200, 50)
        expect_type("userdata", l)
        l:remove()
    end)

    -- @description Creates a light with every options field set and verifies position, radius, color, intensity, energy, blend, falloff, shadow settings, masks, and enabled state.
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

    -- @description Clears state, creates a triangle occluder from six coordinates, verifies the returned handle is userdata, and removes it.
    it("newOccluder returns userdata for valid polygon", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 100, 0, 50, 80})
        expect_type("userdata", o)
        o:remove()
    end)

    -- @description Creates an occluder with opacity, light mask, and disabled state options, then checks each configured value.
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

    -- @description Confirms that creating an occluder with only four numbers raises an error because there are too few vertices.
    it("newOccluder errors on fewer than 6 numbers", function()
        expect_error(function()
            lurek.light.newOccluder({0, 0, 100, 0})
        end)
    end)

    -- @description Confirms that creating an occluder with an odd number of coordinates raises an error.
    it("newOccluder errors on odd number count", function()
        expect_error(function()
            lurek.light.newOccluder({0, 0, 100, 0, 50})
        end)
    end)

    -- @description Sets ambient light with RGB only and verifies the stored RGB values plus the default alpha of 1.0.
    it("setAmbient / getAmbient round-trip (rgb)", function()
        lurek.light.clear()
        lurek.light.setAmbient(0.3, 0.4, 0.5)
        local r, g, b, a = lurek.light.getAmbient()
        expect_near(r, 0.3, 0.001)
        expect_near(g, 0.4, 0.001)
        expect_near(b, 0.5, 0.001)
        expect_near(a, 1.0, 0.001)
    end)

    -- @description Sets ambient light with RGBA and verifies that all four channels are returned unchanged.
    it("setAmbient / getAmbient round-trip (rgba)", function()
        lurek.light.clear()
        lurek.light.setAmbient(0.2, 0.3, 0.4, 0.8)
        local r, g, b, a = lurek.light.getAmbient()
        expect_near(r, 0.2, 0.001)
        expect_near(g, 0.3, 0.001)
        expect_near(b, 0.4, 0.001)
        expect_near(a, 0.8, 0.001)
    end)

    -- @description Toggles the module enabled flag off and on again and checks that isEnabled reports each state.
    it("setEnabled / isEnabled round-trip", function()
        lurek.light.clear()
        lurek.light.setEnabled(false)
        expect_false(lurek.light.isEnabled())
        lurek.light.setEnabled(true)
        expect_true(lurek.light.isEnabled())
    end)

    -- @description Starts with lighting disabled, creates one light, and verifies that the first light creation automatically re-enables lighting.
    it("auto-enables after first newLight", function()
        lurek.light.clear()
        lurek.light.setEnabled(false)
        expect_false(lurek.light.isEnabled())
        local l = lurek.light.newLight(0, 0, 10)
        expect_true(lurek.light.isEnabled())
        l:remove()
    end)

    -- @description Verifies that the light count increments for two created lights and decrements back to zero as each light is removed.
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

    -- @description Verifies that the occluder count increments for two created occluders and decrements back to zero as each one is removed.
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

    -- @description Sets the module max-light limit to 128 and verifies that the getter returns the same value.
    it("getMaxLights / setMaxLights round-trip", function()
        lurek.light.clear()
        lurek.light.setMaxLights(128)
        expect_equal(lurek.light.getMaxLights(), 128)
    end)

    -- @description Verifies that max lights clamps low values up to 1 and high values down to 256.
    it("setMaxLights clamps to 1..256", function()
        lurek.light.setMaxLights(0)
        expect_equal(lurek.light.getMaxLights(), 1)
        lurek.light.setMaxLights(999)
        expect_equal(lurek.light.getMaxLights(), 256)
    end)

    -- @description Creates one light and one occluder, changes ambient to white, clears the system, and checks that counts reset and ambient returns to the default 0.1,0.1,0.1,1.0.
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

-- â”€â”€ Light handle methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies per-light handle setters, getters, validity checks, and enum-like field updates on an individual light instance.
describe("Light handle methods", function()
    -- @description Moves a light to 42,99 and verifies the reported position matches those coordinates.
    it("setPosition / getPosition", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setPosition(42, 99)
        local x, y = l:getPosition()
        expect_near(x, 42, 0.001)
        expect_near(y, 99, 0.001)
        l:remove()
    end)

    -- @description Changes a light radius to 77.5 and verifies getRadius returns the updated value.
    it("setRadius / getRadius", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setRadius(77.5)
        expect_near(l:getRadius(), 77.5, 0.001)
        l:remove()
    end)

    -- @description Sets RGB color only on a light and verifies the RGB channels plus the default alpha of 1.0.
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

    -- @description Sets RGBA color on a light and verifies all four returned channels match.
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

    -- @description Sets light intensity to 3.5 and verifies the getter returns that exact value within tolerance.
    it("setIntensity / getIntensity", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setIntensity(3.5)
        expect_near(l:getIntensity(), 3.5, 0.001)
        l:remove()
    end)

    -- @description Sets light energy to 2.0 and verifies the getter returns the same value.
    it("setEnergy / getEnergy", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setEnergy(2.0)
        expect_near(l:getEnergy(), 2.0, 0.001)
        l:remove()
    end)

    -- @description Sets the blend mode to add and verifies getBlendMode returns add.
    it("setBlendMode / getBlendMode - add", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setBlendMode("add")
        expect_equal(l:getBlendMode(), "add")
        l:remove()
    end)

    -- @description Sets the blend mode to sub and verifies getBlendMode returns sub.
    it("setBlendMode / getBlendMode - sub", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setBlendMode("sub")
        expect_equal(l:getBlendMode(), "sub")
        l:remove()
    end)

    -- @description Sets the blend mode to mix and verifies getBlendMode returns mix.
    it("setBlendMode / getBlendMode - mix", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setBlendMode("mix")
        expect_equal(l:getBlendMode(), "mix")
        l:remove()
    end)

    -- @description Sets the falloff mode to smooth and verifies the getter returns smooth.
    it("setFalloff / getFalloff - smooth", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setFalloff("smooth")
        expect_equal(l:getFalloff(), "smooth")
        l:remove()
    end)

    -- @description Sets the falloff mode to constant and verifies the getter returns constant.
    it("setFalloff / getFalloff - constant", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setFalloff("constant")
        expect_equal(l:getFalloff(), "constant")
        l:remove()
    end)

    -- @description Sets the falloff mode to linear and verifies the getter returns linear.
    it("setFalloff / getFalloff - linear", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setFalloff("linear")
        expect_equal(l:getFalloff(), "linear")
        l:remove()
    end)

    -- @description Verifies shadowing starts disabled, can be enabled, and can then be disabled again on the same light.
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

    -- @description Sets the shadow RGBA color and verifies each returned shadow color channel matches.
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

    -- @description Sets the shadow filter to pcf5 and verifies the getter returns pcf5.
    it("setShadowFilter / getShadowFilter - pcf5", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowFilter("pcf5")
        expect_equal(l:getShadowFilter(), "pcf5")
        l:remove()
    end)

    -- @description Sets the shadow filter to pcf13 and verifies the getter returns pcf13.
    it("setShadowFilter / getShadowFilter - pcf13", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowFilter("pcf13")
        expect_equal(l:getShadowFilter(), "pcf13")
        l:remove()
    end)

    -- @description Sets the shadow filter to none and verifies the getter returns none.
    it("setShadowFilter / getShadowFilter - none", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowFilter("none")
        expect_equal(l:getShadowFilter(), "none")
        l:remove()
    end)

    -- @description Sets shadow smoothing to 2.0 and verifies the getter returns 2.0.
    it("setShadowSmooth / getShadowSmooth", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowSmooth(2.0)
        expect_near(l:getShadowSmooth(), 2.0, 0.001)
        l:remove()
    end)

    -- @description Sets the light mask to 255 and verifies the getter returns 255.
    it("setLightMask / getLightMask", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setLightMask(255)
        expect_equal(l:getLightMask(), 255)
        l:remove()
    end)

    -- @description Sets the shadow mask to 127 and verifies the getter returns 127.
    it("setShadowMask / getShadowMask", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:setShadowMask(127)
        expect_equal(l:getShadowMask(), 127)
        l:remove()
    end)

    -- @description Verifies a light handle starts enabled, can be disabled, and can be re-enabled.
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

    -- @description Checks that a newly created light reports itself as valid before removal.
    it("isValid returns true before remove", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_true(l:isValid())
        l:remove()
    end)

    -- @description Removes a light and verifies the handle reports invalid afterward.
    it("isValid returns false after remove", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        l:remove()
        expect_false(l:isValid())
    end)
end)

-- â”€â”€ Occluder handle methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies occluder handle movement, opacity, masks, enabled state, validity, and vertex read/write behavior.
describe("Occluder handle methods", function()
    -- @description Moves an occluder to 15,25 and verifies the returned position matches those coordinates.
    it("setPosition / getPosition", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        o:setPosition(15, 25)
        local x, y = o:getPosition()
        expect_near(x, 15, 0.001)
        expect_near(y, 25, 0.001)
        o:remove()
    end)

    -- @description Sets occluder opacity to 0.5 and verifies the getter returns that value.
    it("setOpacity / getOpacity", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        o:setOpacity(0.5)
        expect_near(o:getOpacity(), 0.5, 0.001)
        o:remove()
    end)

    -- @description Sets the occluder light mask to 0 and then 255, verifying both values round-trip.
    it("setLightMask / getLightMask", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        o:setLightMask(0)
        expect_equal(o:getLightMask(), 0)
        o:setLightMask(255)
        expect_equal(o:getLightMask(), 255)
        o:remove()
    end)

    -- @description Verifies an occluder starts enabled, can be disabled, and can be enabled again.
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

    -- @description Confirms an occluder is valid before removal and invalid after remove is called.
    it("isValid returns false after remove", function()
        lurek.light.clear()
        local o = lurek.light.newOccluder({0, 0, 10, 0, 5, 10})
        expect_true(o:isValid())
        o:remove()
        expect_false(o:isValid())
    end)

    -- @description Reads occluder vertices back as a flat table and verifies both the table length and each coordinate value.
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

    -- @description Replaces an occluder vertex list and verifies all six stored coordinates were updated.
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

-- â”€â”€ Edge cases â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies that invalid enum strings and operations on removed handles all raise errors instead of silently succeeding.
describe("lurek.light edge cases", function()
    -- @description Confirms that setting an unsupported blend mode string on a light raises an error.
    it("invalid blend mode string errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_error(function() l:setBlendMode("bad") end)
        l:remove()
    end)

    -- @description Confirms that setting an unsupported falloff string on a light raises an error.
    it("invalid falloff string errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_error(function() l:setFalloff("bad") end)
        l:remove()
    end)

    -- @description Confirms that setting an unsupported shadow filter string on a light raises an error.
    it("invalid shadow filter string errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 10)
        expect_error(function() l:setShadowFilter("bad") end)
        l:remove()
    end)

    -- @description Removes a light and verifies that reading or writing position, radius, color, and intensity all error on the stale handle.
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

    -- @description Removes an occluder and verifies that position, opacity, and vertex operations all error on the stale handle.
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

-- â”€â”€ New effects: Light Type â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies the light type API defaults to point, accepts valid type transitions, and rejects invalid type strings.
describe("Light type", function()
    -- @description Creates a light and verifies its default light type is point.
    it("default is point", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getLightType(), "point")
        l:remove()
    end)

    -- @description Switches a light from point to spot to directional and back to point, verifying each reported type.
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

    -- @description Confirms that setting an unsupported light type string raises an error.
    it("invalid light type errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_error(function() l:setLightType("laser") end)
        l:remove()
    end)
end)

-- â”€â”€ Light Direction and Angles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies directional and cone angle defaults and setter/getter round-trips for directional light parameters.
describe("Light direction and angles", function()
    -- @description Creates a light and verifies its default direction is 0 radians.
    it("default direction is 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_near(l:getDirection(), 0, 0.001)
        l:remove()
    end)

    -- @description Sets light direction to 1.57 radians and verifies the getter returns that value.
    it("setDirection / getDirection", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setDirection(1.57)
        expect_near(l:getDirection(), 1.57, 0.001)
        l:remove()
    end)

    -- @description Sets the inner cone angle to 0.3 radians and verifies the getter returns 0.3.
    it("setInnerAngle / getInnerAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setInnerAngle(0.3)
        expect_near(l:getInnerAngle(), 0.3, 0.001)
        l:remove()
    end)

    -- @description Sets the outer cone angle to 0.6 radians and verifies the getter returns 0.6.
    it("setOuterAngle / getOuterAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setOuterAngle(0.6)
        expect_near(l:getOuterAngle(), 0.6, 0.001)
        l:remove()
    end)

    -- @description Verifies the default inner and outer cone angles are pi/6 and pi/4 respectively.
    it("default angles are pi/6 and pi/4", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_near(l:getInnerAngle(), math.pi / 6, 0.001)
        expect_near(l:getOuterAngle(), math.pi / 4, 0.001)
        l:remove()
    end)
end)

-- â”€â”€ Light Attenuation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies attenuation defaults and round-trips constant, linear, and quadratic attenuation coefficients.
describe("Light attenuation", function()
    -- @description Creates a light and verifies the default attenuation coefficients are 1.0, 0.0, and 0.0.
    it("default attenuation is 1 0 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        local c, lin, q = l:getAttenuation()
        expect_near(c, 1.0, 0.001)
        expect_near(lin, 0.0, 0.001)
        expect_near(q, 0.0, 0.001)
        l:remove()
    end)

    -- @description Sets attenuation coefficients to 1.0, 0.09, and 0.032 and verifies each returned coefficient.
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

-- â”€â”€ Light Flicker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies flicker defaults, configured speed and strength, and explicit enable toggling for flickering lights.
describe("Light flicker", function()
    -- @description Creates a light and verifies flicker is disabled by default.
    it("default flicker disabled", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:isFlickerEnabled(), false)
        l:remove()
    end)

    -- @description Sets flicker speed to 10.0 and strength to 0.25, then verifies both values and that flicker becomes enabled.
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

    -- @description Configures flicker, disables it, re-enables it, and verifies the enabled flag after each toggle.
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

-- â”€â”€ Light Groups â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies group IDs, per-group counts, group-wide enable changes, group intensity updates, and group color updates.
describe("Light groups", function()
    -- @description Creates a light and verifies its default group ID is 0.
    it("default group is 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getGroupId(), 0)
        l:remove()
    end)

    -- @description Assigns a light to group 5 and verifies getGroupId returns 5.
    it("setGroupId / getGroupId", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setGroupId(5)
        expect_equal(l:getGroupId(), 5)
        l:remove()
    end)

    -- @description Places two lights into group 1 and verifies that group 1 reports a count of 2 while group 0 reports 0.
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

    -- @description Disables group 2 and verifies that two lights in group 2 are disabled while a light left in group 0 remains enabled.
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

    -- @description Assigns a light to group 3, sets group intensity to 0.5, and verifies the light intensity updates to 0.5.
    it("setGroupIntensity changes group intensity", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        l1:setGroupId(3)
        lurek.light.setGroupIntensity(3, 0.5)
        expect_near(l1:getIntensity(), 0.5, 0.001)
        lurek.light.clear()
    end)

    -- @description Assigns a light to group 4, sets the group color to solid red, and verifies the light color channels match 1,0,0,1.
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

-- â”€â”€ Light Volumetric â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies volumetric lighting defaults to false and can be toggled on and back off per light.
describe("Light volumetric", function()
    -- @description Creates a light and verifies volumetric lighting is disabled by default.
    it("default not volumetric", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:isVolumetric(), false)
        l:remove()
    end)

    -- @description Enables volumetric lighting, verifies true, disables it again, and verifies false.
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

-- â”€â”€ advanceFlickers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies the module-level flicker advancement function can run on a flickering light without raising an error.
describe("advanceFlickers", function()
    -- @description Creates a flickering light, advances flickers by 0.1 seconds, and treats the absence of an error as success.
    it("advanceFlickers does not error", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setFlicker(10.0, 0.15)
        lurek.light.advanceFlickers(0.1)
        -- No error means success (phase is internal)
        l:remove()
    end)
end)

-- â”€â”€ newLight opts with new fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies that the new extended newLight options table initializes newer fields such as type, direction, angles, groups, volumetric state, flicker, and attenuation.
describe("newLight opts with new effects", function()
    -- @description Creates a light with opts.type set to spot and verifies getLightType returns spot.
    it("opts type sets light type", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { type = "spot" })
        expect_equal(l:getLightType(), "spot")
        l:remove()
    end)

    -- @description Creates a light with opts.direction set to 1.57 and verifies the stored direction matches.
    it("opts direction sets direction", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { direction = 1.57 })
        expect_near(l:getDirection(), 1.57, 0.001)
        l:remove()
    end)

    -- @description Creates a light with innerAngle 0.3 and outerAngle 0.6 in opts and verifies both stored cone angles.
    it("opts innerAngle and outerAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { innerAngle = 0.3, outerAngle = 0.6 })
        expect_near(l:getInnerAngle(), 0.3, 0.001)
        expect_near(l:getOuterAngle(), 0.6, 0.001)
        l:remove()
    end)

    -- @description Creates a light with opts.groupId set to 7 and verifies the light reports group 7.
    it("opts groupId sets group", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { groupId = 7 })
        expect_equal(l:getGroupId(), 7)
        l:remove()
    end)

    -- @description Creates a light with opts.volumetric enabled and verifies the light reports volumetric true.
    it("opts volumetric sets flag", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { volumetric = true })
        expect_equal(l:isVolumetric(), true)
        l:remove()
    end)

    -- @description Creates a light with flickerSpeed 12.0 and flickerStrength 0.3 in opts, verifies flicker is enabled, and checks both values.
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

    -- @description Creates a light with attenuation coefficients in opts and verifies constant, linear, and quadratic values round-trip.
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

-- â”€â”€ New effects: Light Type â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies the light type API defaults to point, accepts valid type transitions, and rejects invalid type strings.
describe("Light type", function()
    -- @description Creates a light and verifies its default light type is point.
    it("default is point", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getLightType(), "point")
        l:remove()
    end)

    -- @description Switches a light from point to spot to directional and back to point, verifying each reported type.
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

    -- @description Confirms that setting an unsupported light type string raises an error.
    it("invalid light type errors", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_error(function() l:setLightType("laser") end)
        l:remove()
    end)
end)

-- â”€â”€ Light Direction and Angles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies directional and cone angle defaults and setter/getter round-trips for directional light parameters.
describe("Light direction and angles", function()
    -- @description Creates a light and verifies its default direction is 0 radians.
    it("default direction is 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_near(l:getDirection(), 0, 0.001)
        l:remove()
    end)

    -- @description Sets light direction to 1.57 radians and verifies the getter returns that value.
    it("setDirection / getDirection", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setDirection(1.57)
        expect_near(l:getDirection(), 1.57, 0.001)
        l:remove()
    end)

    -- @description Sets the inner cone angle to 0.3 radians and verifies the getter returns 0.3.
    it("setInnerAngle / getInnerAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setInnerAngle(0.3)
        expect_near(l:getInnerAngle(), 0.3, 0.001)
        l:remove()
    end)

    -- @description Sets the outer cone angle to 0.6 radians and verifies the getter returns 0.6.
    it("setOuterAngle / getOuterAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setOuterAngle(0.6)
        expect_near(l:getOuterAngle(), 0.6, 0.001)
        l:remove()
    end)

    -- @description Verifies the default inner and outer cone angles are pi/6 and pi/4 respectively.
    it("default angles are pi/6 and pi/4", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_near(l:getInnerAngle(), math.pi / 6, 0.001)
        expect_near(l:getOuterAngle(), math.pi / 4, 0.001)
        l:remove()
    end)
end)

-- â”€â”€ Light Attenuation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies attenuation defaults and round-trips constant, linear, and quadratic attenuation coefficients.
describe("Light attenuation", function()
    -- @description Creates a light and verifies the default attenuation coefficients are 1.0, 0.0, and 0.0.
    it("default attenuation is 1 0 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        local c, lin, q = l:getAttenuation()
        expect_near(c, 1.0, 0.001)
        expect_near(lin, 0.0, 0.001)
        expect_near(q, 0.0, 0.001)
        l:remove()
    end)

    -- @description Sets attenuation coefficients to 1.0, 0.09, and 0.032 and verifies each returned coefficient.
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

-- â”€â”€ Light Flicker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies flicker defaults, configured speed and strength, and explicit enable toggling for flickering lights.
describe("Light flicker", function()
    -- @description Creates a light and verifies flicker is disabled by default.
    it("default flicker disabled", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:isFlickerEnabled(), false)
        l:remove()
    end)

    -- @description Sets flicker speed to 10.0 and strength to 0.25, then verifies both values and that flicker becomes enabled.
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

    -- @description Configures flicker, disables it, re-enables it, and verifies the enabled flag after each toggle.
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

-- â”€â”€ Light Groups â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies group IDs, per-group counts, group-wide enable changes, group intensity updates, and group color updates.
describe("Light groups", function()
    -- @description Creates a light and verifies its default group ID is 0.
    it("default group is 0", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:getGroupId(), 0)
        l:remove()
    end)

    -- @description Assigns a light to group 5 and verifies getGroupId returns 5.
    it("setGroupId / getGroupId", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setGroupId(5)
        expect_equal(l:getGroupId(), 5)
        l:remove()
    end)

    -- @description Places two lights into group 1 and verifies that group 1 reports a count of 2 while group 0 reports 0.
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

    -- @description Disables group 2 and verifies that two lights in group 2 are disabled while a light left in group 0 remains enabled.
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

    -- @description Assigns a light to group 3, sets group intensity to 0.5, and verifies the light intensity updates to 0.5.
    it("setGroupIntensity changes group intensity", function()
        lurek.light.clear()
        local l1 = lurek.light.newLight(0, 0, 50)
        l1:setGroupId(3)
        lurek.light.setGroupIntensity(3, 0.5)
        expect_near(l1:getIntensity(), 0.5, 0.001)
        lurek.light.clear()
    end)

    -- @description Assigns a light to group 4, sets the group color to solid red, and verifies the light color channels match 1,0,0,1.
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

-- â”€â”€ Light Volumetric â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies volumetric lighting defaults to false and can be toggled on and back off per light.
describe("Light volumetric", function()
    -- @description Creates a light and verifies volumetric lighting is disabled by default.
    it("default not volumetric", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        expect_equal(l:isVolumetric(), false)
        l:remove()
    end)

    -- @description Enables volumetric lighting, verifies true, disables it again, and verifies false.
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

-- â”€â”€ advanceFlickers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies the module-level flicker advancement function can run on a flickering light without raising an error.
describe("advanceFlickers", function()
    -- @description Creates a flickering light, advances flickers by 0.1 seconds, and treats the absence of an error as success.
    it("advanceFlickers does not error", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50)
        l:setFlicker(10.0, 0.15)
        lurek.light.advanceFlickers(0.1)
        -- No error means success (phase is internal)
        l:remove()
    end)
end)

-- â”€â”€ newLight opts with new fields â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies that the new extended newLight options table initializes newer fields such as type, direction, angles, groups, volumetric state, flicker, and attenuation.
describe("newLight opts with new effects", function()
    -- @description Creates a light with opts.type set to spot and verifies getLightType returns spot.
    it("opts type sets light type", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { type = "spot" })
        expect_equal(l:getLightType(), "spot")
        l:remove()
    end)

    -- @description Creates a light with opts.direction set to 1.57 and verifies the stored direction matches.
    it("opts direction sets direction", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { direction = 1.57 })
        expect_near(l:getDirection(), 1.57, 0.001)
        l:remove()
    end)

    -- @description Creates a light with innerAngle 0.3 and outerAngle 0.6 in opts and verifies both stored cone angles.
    it("opts innerAngle and outerAngle", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { innerAngle = 0.3, outerAngle = 0.6 })
        expect_near(l:getInnerAngle(), 0.3, 0.001)
        expect_near(l:getOuterAngle(), 0.6, 0.001)
        l:remove()
    end)

    -- @description Creates a light with opts.groupId set to 7 and verifies the light reports group 7.
    it("opts groupId sets group", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { groupId = 7 })
        expect_equal(l:getGroupId(), 7)
        l:remove()
    end)

    -- @description Creates a light with opts.volumetric enabled and verifies the light reports volumetric true.
    it("opts volumetric sets flag", function()
        lurek.light.clear()
        local l = lurek.light.newLight(0, 0, 50, { volumetric = true })
        expect_equal(l:isVolumetric(), true)
        l:remove()
    end)

    -- @description Creates a light with flickerSpeed 12.0 and flickerStrength 0.3 in opts, verifies flicker is enabled, and checks both values.
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

    -- @description Creates a light with attenuation coefficients in opts and verifies constant, linear, and quadratic values round-trip.
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

-- ── Ambient Bridge & God-Ray Hints (merged from test_light_godrays.lua) ─────

-- @description Covers suite: lurek.light ambient bridge and god-ray hints.
describe("lurek.light ambient bridge", function()
    -- @description Covers suite: API exposure.
    describe("API exposure", function()
        -- @covers lurek.light.syncAmbient
        -- @description syncAmbient is exposed as a function.
        it("exposes syncAmbient", function()
            expect_type("function", lurek.light.syncAmbient)
        end)

        -- @covers lurek.light.getGodRayHints
        -- @description getGodRayHints is exposed as a function.
        it("exposes getGodRayHints", function()
            expect_type("function", lurek.light.getGodRayHints)
        end)
    end)

    -- @description Covers suite: syncAmbient().
    describe("syncAmbient()", function()
        -- @covers lurek.light.syncAmbient
        -- @description Returns four numbers.
        it("returns four numeric values", function()
            local r, g, b, a = lurek.light.syncAmbient()
            expect_type("number", r)
            expect_type("number", g)
            expect_type("number", b)
            expect_type("number", a)
        end)

        -- @covers lurek.light.syncAmbient
        -- @description Alpha is in [0, 1].
        it("alpha component is in [0, 1]", function()
            local _, _, _, a = lurek.light.syncAmbient()
            assert(a >= 0.0 and a <= 1.0,
                "alpha out of [0,1]: " .. tostring(a))
        end)

        -- @covers lurek.light.setAmbient
        -- @covers lurek.light.syncAmbient
        -- @description After setAmbient, syncAmbient reflects the new colour.
        it("reflects setAmbient changes", function()
            lurek.light.setAmbient(0.2, 0.4, 0.6, 0.8)
            local r, g, b, a = lurek.light.syncAmbient()
            expect_near(0.2, r, 0.001)
            expect_near(0.4, g, 0.001)
            expect_near(0.6, b, 0.001)
            expect_near(0.8, a, 0.001)
        end)

        -- @covers lurek.light.setAmbient
        -- @covers lurek.light.syncAmbient
        -- @description syncAmbient matches getAmbient.
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

    -- @description Covers suite: getGodRayHints().
    describe("getGodRayHints()", function()
        -- @covers lurek.light.getGodRayHints
        -- @description Returns a table.
        it("returns a table", function()
            local hints = lurek.light.getGodRayHints()
            expect_type("table", hints)
        end)

        -- @covers lurek.light.getGodRayHints
        -- @description Returns empty table when no directional lights exist.
        it("returns empty table with no directional lights", function()
            lurek.light.clearAll()
            local hints = lurek.light.getGodRayHints()
            expect_equal(0, #hints)
        end)

        -- @covers lurek.light.newLight
        -- @covers lurek.light.getGodRayHints
        -- @description Each hint entry has x, y, and angle fields.
        it("each hint has x, y, angle fields", function()
            lurek.light.clearAll()
            local light = lurek.light.newLight("directional", 100, 200)
            light:setDirection(1.57)  -- ~pi/2
            light:setEnabled(true)
            local hints = lurek.light.getGodRayHints()
            if #hints > 0 then
                local h = hints[1]
                expect_type("number", h.x)
                expect_type("number", h.y)
                expect_type("number", h.angle)
            end
        end)

        -- @covers lurek.light.getGodRayHints
        -- @description Disabled directional lights are not included.
        it("disabled lights are excluded", function()
            lurek.light.clearAll()
            local light = lurek.light.newLight("directional", 0, 0)
            light:setEnabled(false)
            local hints = lurek.light.getGodRayHints()
            expect_equal(0, #hints)
        end)
    end)
end)

test_summary()
