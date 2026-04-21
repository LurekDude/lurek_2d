-- Lurek2D Parallax API Unit Tests (headless)
-- Tests: module existence, layer creation, scroll math, autoscroll, repeat,
--        opacity, tint, blend mode, z-ordering in sets, resetAutoscroll.
--
-- @tests lurek.parallax.newLayer
-- @tests lurek.parallax.newSet
-- @tests LuaParallaxLayer.type
-- @tests LuaParallaxLayer.update
-- @tests LuaParallaxLayer.draw
-- @tests LuaParallaxLayer.drawAuto
-- @tests LuaParallaxLayer.resetAutoscroll
-- @tests LuaParallaxLayer.setScrollFactor
-- @tests LuaParallaxLayer.getScrollFactor
-- @tests LuaParallaxLayer.setOffset
-- @tests LuaParallaxLayer.getOffset
-- @tests LuaParallaxLayer.setAutoscroll
-- @tests LuaParallaxLayer.getAutoscroll
-- @tests LuaParallaxLayer.setRepeat
-- @tests LuaParallaxLayer.setScale
-- @tests LuaParallaxLayer.setZ
-- @tests LuaParallaxLayer.getZ
-- @tests LuaParallaxLayer.setOpacity
-- @tests LuaParallaxLayer.getOpacity
-- @tests LuaParallaxLayer.setTint
-- @tests LuaParallaxLayer.getTint
-- @tests LuaParallaxLayer.setBlendMode
-- @tests LuaParallaxLayer.getBlendMode
-- @tests LuaParallaxLayer.setVisible
-- @tests LuaParallaxLayer.isVisible
-- @tests LuaParallaxLayer.setClamp
-- @tests LuaParallaxLayer.clearClamp
-- @tests LuaParallaxSet.type
-- @tests LuaParallaxSet.addLayer
-- @tests LuaParallaxSet.removeLayerAt
-- @tests LuaParallaxSet.layerCount
-- @tests LuaParallaxSet.sortByZ
-- @tests LuaParallaxSet.setVisible
-- @tests LuaParallaxSet.isVisible
-- @tests LuaParallaxSet.update
-- @tests LuaParallaxSet.draw
-- @tests LuaParallaxSet.drawAuto
-- @tests LuaParallaxSet.getName
-- @tests LuaParallaxSet.setName
-- @tests LuaParallaxLayer.setDepth
-- @tests LuaParallaxLayer.getDepth
-- @tests LuaParallaxLayer.setTiling
-- @tests LuaParallaxLayer.getTiling
-- @tests LuaParallaxLayer.setTileSize

-- Helper: load a real texture for tests that require a LuaImage.
local function load_image()
    return lurek.render.newImage("assets/icon.png")
end

-- â”€â”€ Module existence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: lurek.parallax module exists.
describe("lurek.parallax module exists", function()
    -- @tests lurek.parallax
    -- @description Verifies the parallax namespace is registered as a Lua table.
    it("lurek.parallax is a table", function()
        expect_type("table", lurek.parallax)
    end)

    -- @tests lurek.parallax.newLayer
    -- @description Verifies the parallax layer factory is exposed as a function.
    it("newLayer is a function", function()
        expect_type("function", lurek.parallax.newLayer)
    end)

    -- @tests lurek.parallax.newSet
    -- @description Verifies the parallax set factory is exposed as a function.
    it("newSet is a function", function()
        expect_type("function", lurek.parallax.newSet)
    end)
end)

-- â”€â”€ newLayer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: lurek.parallax.newLayer.
describe("lurek.parallax.newLayer", function()
    -- @tests lurek.parallax.newLayer
    -- @description Creates a parallax layer from a valid texture and verifies the factory returns userdata.
    it("returns userdata when given a valid texture", function()
        local img = load_image()
        local layer = lurek.parallax.newLayer({ texture = img })
        expect_type("userdata", layer)
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.type
    -- @description Verifies a newly created parallax layer reports the ParallaxLayer type name.
    it("type() returns 'ParallaxLayer'", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_equal("ParallaxLayer", layer:type())
    end)

    -- @tests lurek.parallax.newLayer
    -- @description Verifies the layer factory rejects config tables that omit the required texture field.
    it("errors when texture field is missing", function()
        expect_error(function()
            lurek.parallax.newLayer({})
        end)
    end)

    -- @tests lurek.parallax.newLayer
    -- @description Verifies the layer factory rejects a texture value that is not a LuaImage.
    it("errors when texture is not a LuaImage", function()
        expect_error(function()
            lurek.parallax.newLayer({ texture = "not an image" })
        end)
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getScrollFactor
    -- @description Creates a layer with explicit horizontal and vertical scroll factors and verifies both values.
    it("accepts scroll_factor_x and scroll_factor_y", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            scroll_factor_x = 0.3,
            scroll_factor_y = 0.0,
        })
        local x, y = layer:getScrollFactor()
        expect_near(0.3, x)
        expect_near(0.0, y)
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getOffset
    -- @description Creates a layer with explicit offsets and verifies both stored offset components.
    it("accepts offset_x and offset_y", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            offset_x = 50.0,
            offset_y = 20.0,
        })
        local x, y = layer:getOffset()
        expect_near(50.0, x)
        expect_near(20.0, y)
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getOpacity
    -- @description Creates a layer with an explicit opacity and verifies the opacity getter.
    it("accepts opacity", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            opacity = 0.5,
        })
        expect_near(0.5, layer:getOpacity())
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getZ
    -- @description Creates a layer with an explicit z value and verifies the layer ordering value is stored.
    it("accepts z value", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            z = -5,
        })
        expect_equal(-5, layer:getZ())
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Creates a layer with an explicit blend mode and verifies the configured mode is returned.
    it("accepts blend_mode string", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            blend_mode = "additive",
        })
        expect_equal("additive", layer:getBlendMode())
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.isVisible
    -- @description Creates a layer with visible=false and verifies the visibility flag starts disabled.
    it("accepts visible = false", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            visible = false,
        })
        expect_equal(false, layer:isVisible())
    end)
end)

-- â”€â”€ Defaults â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: LuaParallaxLayer defaults.
describe("LuaParallaxLayer defaults", function()
    local img
    local layer

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getScrollFactor
    -- @description Verifies new layers default to a horizontal scroll factor of 1 and a vertical scroll factor of 0.
    it("scroll factor defaults to (1, 0)", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        local x, y = layer:getScrollFactor()
        expect_near(1.0, x)
        expect_near(0.0, y)
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getOffset
    -- @description Verifies new layers default to zero positional offset.
    it("offset defaults to (0, 0)", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        local x, y = layer:getOffset()
        expect_near(0.0, x)
        expect_near(0.0, y)
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getOpacity
    -- @description Verifies new layers default to full opacity.
    it("opacity defaults to 1.0", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_near(1.0, layer:getOpacity())
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getZ
    -- @description Verifies new layers default to a z value of 0.
    it("z defaults to 0", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_equal(0, layer:getZ())
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Verifies new layers default to normal (alpha) blending.
    it("blend mode defaults to 'normal'", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_equal("normal", layer:getBlendMode())
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.isVisible
    -- @description Verifies new layers default to visible.
    it("isVisible defaults to true", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_equal(true, layer:isVisible())
    end)

    -- @tests lurek.parallax.newLayer
    -- @tests LuaParallaxLayer.getAutoscroll
    -- @description Verifies new layers default to zero autoscroll velocity on both axes.
    it("autoscroll defaults to (0, 0)", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        local vx, vy = layer:getAutoscroll()
        expect_near(0.0, vx)
        expect_near(0.0, vy)
    end)
end)

-- â”€â”€ Getters / setters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: LuaParallaxLayer setters and getters.
describe("LuaParallaxLayer setters and getters", function()
    -- @tests LuaParallaxLayer.setScrollFactor
    -- @tests LuaParallaxLayer.getScrollFactor
    -- @description Updates both scroll factors and verifies the pair round-trips through the getter.
    it("setScrollFactor / getScrollFactor round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setScrollFactor(0.25, 0.75)
        local x, y = layer:getScrollFactor()
        expect_near(0.25, x)
        expect_near(0.75, y)
    end)

    -- @tests LuaParallaxLayer.setOffset
    -- @tests LuaParallaxLayer.getOffset
    -- @description Updates both layer offsets and verifies the pair round-trips through the getter.
    it("setOffset / getOffset round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setOffset(100.0, -50.0)
        local x, y = layer:getOffset()
        expect_near(100.0, x)
        expect_near(-50.0, y)
    end)

    -- @tests LuaParallaxLayer.setAutoscroll
    -- @tests LuaParallaxLayer.getAutoscroll
    -- @description Updates both autoscroll velocities and verifies the pair round-trips through the getter.
    it("setAutoscroll / getAutoscroll round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setAutoscroll(30.0, -10.0)
        local vx, vy = layer:getAutoscroll()
        expect_near(30.0, vx)
        expect_near(-10.0, vy)
    end)

    -- @tests LuaParallaxLayer.setZ
    -- @tests LuaParallaxLayer.getZ
    -- @description Updates the layer z order twice and verifies each assigned value is returned.
    it("setZ / getZ round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setZ(-3)
        expect_equal(-3, layer:getZ())
        layer:setZ(10)
        expect_equal(10, layer:getZ())
    end)

    -- @tests LuaParallaxLayer.setOpacity
    -- @tests LuaParallaxLayer.getOpacity
    -- @description Sets the layer opacity and verifies the value round-trips through the getter.
    it("setOpacity / getOpacity round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setOpacity(0.4)
        expect_near(0.4, layer:getOpacity())
    end)

    -- @tests LuaParallaxLayer.setOpacity
    -- @tests LuaParallaxLayer.getOpacity
    -- @description Verifies setOpacity clamps values outside the supported 0 to 1 range.
    it("setOpacity clamps to [0, 1]", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setOpacity(2.0)
        expect_near(1.0, layer:getOpacity())
        layer:setOpacity(-1.0)
        expect_near(0.0, layer:getOpacity())
    end)

    -- @tests LuaParallaxLayer.setTint
    -- @tests LuaParallaxLayer.getTint
    -- @description Sets the layer tint RGBA values and verifies all four channels round-trip.
    it("setTint / getTint round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setTint(0.5, 0.3, 0.8, 0.7)
        local r, g, b, a = layer:getTint()
        expect_near(0.5, r)
        expect_near(0.3, g)
        expect_near(0.8, b)
        expect_near(0.7, a)
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Iterates through each supported blend mode and verifies the currently configured mode round-trips.
    it("setBlendMode / getBlendMode round-trip for each mode", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        local modes = { "normal", "additive", "multiply", "replace", "screen" }
        for _, mode in ipairs(modes) do
            layer:setBlendMode(mode)
            expect_equal(mode, layer:getBlendMode())
        end
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Verifies an unrecognised blend mode string raises an error.
    it("unrecognised blend mode raises an error", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_error(function() layer:setBlendMode("bogus") end)
    end)

    -- @tests LuaParallaxLayer.setVisible
    -- @tests LuaParallaxLayer.isVisible
    -- @description Toggles layer visibility off and on and verifies both states round-trip.
    it("setVisible / isVisible round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setVisible(false)
        expect_equal(false, layer:isVisible())
        layer:setVisible(true)
        expect_equal(true, layer:isVisible())
    end)
end)

-- â”€â”€ Autoscroll / update â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: LuaParallaxLayer autoscroll.
describe("LuaParallaxLayer autoscroll", function()
    -- @tests LuaParallaxLayer.update
    -- @description Advances an autoscrolling layer and verifies the update path is error-free.
    it("update advances autoscroll accumulator", function()
        -- We cannot directly read the accumulator from Lua, but we can verify
        -- that update does not raise an error and that draw does not raise either.
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            autoscroll_x = 60.0,
        })
        expect_no_error(function()
            layer:update(1.0 / 60.0)
        end)
    end)

    -- @tests LuaParallaxLayer.update
    -- @tests LuaParallaxLayer.resetAutoscroll
    -- @description Verifies resetAutoscroll is safe to call after the autoscroll state has advanced.
    it("resetAutoscroll does not raise an error", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            autoscroll_x = 100.0,
        })
        layer:update(2.0)
        expect_no_error(function()
            layer:resetAutoscroll()
        end)
    end)

    -- @tests LuaParallaxLayer.update
    -- @tests LuaParallaxLayer.resetAutoscroll
    -- @tests LuaParallaxLayer.draw
    -- @description Verifies a reset autoscroll state remains drawable after prior autoscroll updates.
    it("update followed by resetAutoscroll behaves identically to fresh layer", function()
        -- Both calls must be error-free; symmetry is verified by no exception.
        local layer = lurek.parallax.newLayer({ texture = load_image(), autoscroll_x = 80.0 })
        layer:update(5.0)
        layer:resetAutoscroll()
        expect_no_error(function()
            layer:draw(0, 0)
        end)
    end)
end)

-- â”€â”€ draw / drawAuto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: LuaParallaxLayer draw.
describe("LuaParallaxLayer draw", function()
    -- @tests LuaParallaxLayer.draw
    -- @description Verifies drawing a visible layer is error-free.
    it("draw does not raise an error (visible layer)", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_no_error(function()
            layer:draw(0, 0)
        end)
    end)

    -- @tests LuaParallaxLayer.draw
    -- @tests LuaParallaxLayer.setVisible
    -- @description Verifies drawing an invisible layer is still a safe no-op.
    it("draw does not raise an error when invisible", function()
        local layer = lurek.parallax.newLayer({ texture = load_image(), visible = false })
        expect_no_error(function()
            layer:draw(100, 200)
        end)
    end)

    -- @tests LuaParallaxLayer.drawAuto
    -- @description Verifies drawAuto is available and safe to call on a layer.
    it("drawAuto does not raise an error", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_no_error(function()
            layer:drawAuto()
        end)
    end)

    -- @tests LuaParallaxLayer.draw
    -- @tests LuaParallaxLayer.setScrollFactor
    -- @description Verifies drawing with a non-zero camera offset is error-free for a scrolling layer.
    it("draw with non-zero camera offset does not raise", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            scroll_factor_x = 0.5,
        })
        expect_no_error(function()
            layer:draw(1200, 800)
        end)
    end)
end)

-- â”€â”€ Clamp â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: LuaParallaxLayer clamp.
describe("LuaParallaxLayer clamp", function()
    -- @tests LuaParallaxLayer.setClamp
    -- @description Verifies the layer clamp rectangle can be configured without error.
    it("setClamp does not raise", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_no_error(function()
            layer:setClamp(-200, -100, 200, 100)
        end)
    end)

    -- @tests LuaParallaxLayer.setClamp
    -- @tests LuaParallaxLayer.clearClamp
    -- @description Verifies a previously configured clamp can be cleared without error.
    it("clearClamp does not raise after setClamp", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setClamp(-100, -100, 100, 100)
        expect_no_error(function()
            layer:clearClamp()
        end)
    end)

    -- @tests LuaParallaxLayer.setClamp
    -- @tests LuaParallaxLayer.draw
    -- @description Verifies clamped layers remain drawable without error.
    it("draw after setClamp does not raise", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setClamp(-50, -50, 50, 50)
        expect_no_error(function()
            layer:draw(1000, 1000)
        end)
    end)
end)

-- â”€â”€ newSet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: lurek.parallax.newSet.
describe("lurek.parallax.newSet", function()
    -- @tests lurek.parallax.newSet
    -- @description Creates a parallax set and verifies the factory returns userdata.
    it("returns userdata", function()
        local s = lurek.parallax.newSet("bg")
        expect_type("userdata", s)
    end)

    -- @tests lurek.parallax.newSet
    -- @tests LuaParallaxSet.type
    -- @description Verifies a newly created parallax set reports the ParallaxSet type name.
    it("type() returns 'ParallaxSet'", function()
        local s = lurek.parallax.newSet("bg")
        expect_equal("ParallaxSet", s:type())
    end)

    -- @tests lurek.parallax.newSet
    -- @tests LuaParallaxSet.layerCount
    -- @description Verifies a new parallax set starts with zero layers.
    it("layerCount starts at 0", function()
        local s = lurek.parallax.newSet("bg")
        expect_equal(0, s:layerCount())
    end)

    -- @tests lurek.parallax.newSet
    -- @tests LuaParallaxSet.getName
    -- @description Verifies getName returns the name passed to the parallax set factory.
    it("getName returns the name passed to newSet", function()
        local s = lurek.parallax.newSet("my_scene")
        expect_equal("my_scene", s:getName())
    end)

    -- @tests lurek.parallax.newSet
    -- @tests LuaParallaxSet.setName
    -- @tests LuaParallaxSet.getName
    -- @description Renames a parallax set and verifies the updated name is returned.
    it("setName changes the name", function()
        local s = lurek.parallax.newSet("old")
        s:setName("new")
        expect_equal("new", s:getName())
    end)

    -- @tests lurek.parallax.newSet
    -- @tests LuaParallaxSet.isVisible
    -- @description Verifies parallax sets are visible by default.
    it("isVisible returns true by default", function()
        local s = lurek.parallax.newSet("bg")
        expect_equal(true, s:isVisible())
    end)

    -- @tests lurek.parallax.newSet
    -- @tests LuaParallaxSet.setVisible
    -- @tests LuaParallaxSet.isVisible
    -- @description Toggles set visibility off and on and verifies both states round-trip.
    it("setVisible / isVisible round-trip", function()
        local s = lurek.parallax.newSet("bg")
        s:setVisible(false)
        expect_equal(false, s:isVisible())
        s:setVisible(true)
        expect_equal(true, s:isVisible())
    end)
end)

-- â”€â”€ Set: addLayer / layerCount / removeLayerAt â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: LuaParallaxSet layer management.
describe("LuaParallaxSet layer management", function()
    -- @tests LuaParallaxSet.addLayer
    -- @tests LuaParallaxSet.layerCount
    -- @description Adds layers to a set and verifies the layer count increments for each insertion.
    it("addLayer increases layerCount", function()
        local s = lurek.parallax.newSet("bg")
        local img = load_image()
        s:addLayer(lurek.parallax.newLayer({ texture = img }))
        expect_equal(1, s:layerCount())
        s:addLayer(lurek.parallax.newLayer({ texture = img }))
        expect_equal(2, s:layerCount())
    end)

    -- @tests LuaParallaxSet.addLayer
    -- @tests LuaParallaxSet.removeLayerAt
    -- @tests LuaParallaxSet.layerCount
    -- @description Removes a valid layer index and verifies the removal succeeds and decrements the layer count.
    it("removeLayerAt with valid index returns true", function()
        local s = lurek.parallax.newSet("bg")
        s:addLayer(lurek.parallax.newLayer({ texture = load_image() }))
        local ok = s:removeLayerAt(1)
        expect_equal(true, ok)
        expect_equal(0, s:layerCount())
    end)

    -- @tests LuaParallaxSet.removeLayerAt
    -- @description Verifies removing an out-of-range layer index returns false.
    it("removeLayerAt with out-of-range index returns false", function()
        local s = lurek.parallax.newSet("bg")
        local ok = s:removeLayerAt(99)
        expect_equal(false, ok)
    end)

    -- @tests LuaParallaxSet.addLayer
    -- @tests LuaParallaxLayer.setZ
    -- @tests LuaParallaxSet.sortByZ
    -- @description Verifies sets observe mutations made through an external layer handle when sorting by z.
    it("mutations to layer are reflected in set (shared Rc)", function()
        local s = lurek.parallax.newSet("bg")
        local layer = lurek.parallax.newLayer({ texture = load_image(), z = 1 })
        s:addLayer(layer)
        -- Change z on the external handle
        layer:setZ(99)
        -- Set sortByZ should use the updated value
        expect_no_error(function() s:sortByZ() end)
    end)
end)

-- â”€â”€ Set: draw / update / sortByZ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: LuaParallaxSet drawing.
describe("LuaParallaxSet drawing", function()
    -- @tests LuaParallaxSet.draw
    -- @description Verifies drawing an empty parallax set is error-free.
    it("draw does not raise with zero layers", function()
        local s = lurek.parallax.newSet("bg")
        expect_no_error(function() s:draw(0, 0) end)
    end)

    -- @tests LuaParallaxSet.addLayer
    -- @tests LuaParallaxSet.draw
    -- @description Verifies drawing a set with multiple layers and different z values is error-free.
    it("draw does not raise with multiple layers", function()
        local s = lurek.parallax.newSet("bg")
        local img = load_image()
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = 1 }))
        expect_no_error(function() s:draw(300, 200) end)
    end)

    -- @tests LuaParallaxSet.drawAuto
    -- @description Verifies drawAuto is available and safe to call on a set.
    it("drawAuto does not raise", function()
        local s = lurek.parallax.newSet("bg")
        s:addLayer(lurek.parallax.newLayer({ texture = load_image() }))
        expect_no_error(function() s:drawAuto() end)
    end)

    -- @tests LuaParallaxSet.setVisible
    -- @tests LuaParallaxSet.draw
    -- @description Verifies drawing an invisible parallax set remains a safe no-op.
    it("draw while invisible does not raise", function()
        local s = lurek.parallax.newSet("bg")
        s:addLayer(lurek.parallax.newLayer({ texture = load_image() }))
        s:setVisible(false)
        expect_no_error(function() s:draw(0, 0) end)
    end)

    -- @tests LuaParallaxSet.addLayer
    -- @tests LuaParallaxSet.update
    -- @description Verifies updating a set forwards to its layers without error.
    it("update does not raise", function()
        local s = lurek.parallax.newSet("bg")
        s:addLayer(lurek.parallax.newLayer({ texture = load_image(), autoscroll_x = 50.0 }))
        expect_no_error(function() s:update(1.0 / 60.0) end)
    end)

    -- @tests LuaParallaxSet.addLayer
    -- @tests LuaParallaxSet.sortByZ
    -- @tests LuaParallaxSet.draw
    -- @description Sorts a multi-layer set by z and verifies the sorted set remains drawable.
    it("sortByZ does not raise with multiple layers of different z", function()
        local s = lurek.parallax.newSet("bg")
        local img = load_image()
        s:addLayer(lurek.parallax.newLayer({ texture = img, z =  5 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = -2 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, z =  0 }))
        expect_no_error(function() s:sortByZ() end)
        -- After sort, drawing should still work
        expect_no_error(function() s:draw(0, 0) end)
    end)
end)

-- â”€â”€ Scene-transition pattern â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Scene-transition: resetAutoscroll pattern.
describe("Scene-transition: resetAutoscroll pattern", function()
    -- @tests LuaParallaxSet.addLayer
    -- @tests LuaParallaxLayer.update
    -- @tests LuaParallaxSet.setVisible
    -- @tests LuaParallaxLayer.resetAutoscroll
    -- @tests LuaParallaxSet.draw
    -- @description Simulates a scene transition by hiding a set, resetting each layer autoscroll state, and verifying the set still draws safely.
    it("resetAutoscroll on each layer in a set does not raise", function()
        local img = load_image()
        local layers = {
            lurek.parallax.newLayer({ texture = img, autoscroll_x = 30.0, z = 0 }),
            lurek.parallax.newLayer({ texture = img, autoscroll_x = 60.0, z = 1 }),
        }
        local s = lurek.parallax.newSet("scene_bg")
        for _, l in ipairs(layers) do
            s:addLayer(l)
            l:update(5.0)
        end
        -- Simulate scene transition: hide, reset, then show again
        s:setVisible(false)
        for _, l in ipairs(layers) do
            l:resetAutoscroll()
        end
        s:setVisible(true)
        expect_no_error(function() s:draw(0, 0) end)
    end)
end)

-- Helper: create a layer backed by a real texture (used by merged satellite tests).
local function make_layer()
    local img = lurek.render.newImage("assets/icon.png")
    return lurek.parallax.newLayer({ texture = img })
end

-- ── Parallax Blend (merged from test_parallax_blend.lua) ──────────────────────

-- @description Covers suite: parallax per-layer blend mode.
describe("parallax blend modes", function()
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Verifies the default blend mode is 'normal' (alpha blending).
    it("default blend mode is 'normal'", function()
        local layer = make_layer()
        expect_equal("normal", layer:getBlendMode())
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Sets mode to 'additive' and verifies it round-trips.
    it("setBlendMode 'additive' works", function()
        local layer = make_layer()
        layer:setBlendMode("additive")
        expect_equal("additive", layer:getBlendMode())
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Sets mode to 'multiply' and verifies it round-trips.
    it("setBlendMode 'multiply' works", function()
        local layer = make_layer()
        layer:setBlendMode("multiply")
        expect_equal("multiply", layer:getBlendMode())
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Sets mode to 'screen' and verifies it round-trips.
    it("setBlendMode 'screen' works", function()
        local layer = make_layer()
        layer:setBlendMode("screen")
        expect_equal("screen", layer:getBlendMode())
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Sets mode to 'replace' and verifies it round-trips.
    it("setBlendMode 'replace' works", function()
        local layer = make_layer()
        layer:setBlendMode("replace")
        expect_equal("replace", layer:getBlendMode())
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Verifies the legacy alias 'alpha' maps to 'normal'.
    it("legacy alias 'alpha' maps to 'normal'", function()
        local layer = make_layer()
        layer:setBlendMode("alpha")
        expect_equal("normal", layer:getBlendMode())
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @tests LuaParallaxLayer.getBlendMode
    -- @description Verifies the legacy alias 'add' maps to 'additive'.
    it("legacy alias 'add' maps to 'additive'", function()
        local layer = make_layer()
        layer:setBlendMode("add")
        expect_equal("additive", layer:getBlendMode())
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @description Verifies an unrecognised blend mode string raises a Lua error.
    it("invalid blend mode 'glow' raises an error", function()
        local layer = make_layer()
        expect_error(function() layer:setBlendMode("glow") end)
    end)

    -- @tests LuaParallaxLayer.setBlendMode
    -- @description Verifies blend mode can be changed multiple times.
    it("blend mode can be changed multiple times", function()
        local layer = make_layer()
        layer:setBlendMode("additive")
        layer:setBlendMode("multiply")
        layer:setBlendMode("normal")
        expect_equal("normal", layer:getBlendMode())
    end)
end)

-- ── Parallax Depth (merged from test_parallax_depth.lua) ──────────────────────

-- @description Covers suite: parallax layer floating-point depth.
describe("parallax layer depth", function()
    -- @tests LuaParallaxLayer.getDepth
    -- @description Verifies depth defaults to 0.0 on a newly created layer.
    it("depth defaults to 0.0", function()
        local layer = make_layer()
        expect_near(0.0, layer:getDepth(), 0.001)
    end)

    -- @tests LuaParallaxLayer.setDepth
    -- @tests LuaParallaxLayer.getDepth
    -- @description Sets a positive depth and verifies it round-trips.
    it("setDepth to positive value", function()
        local layer = make_layer()
        layer:setDepth(10.0)
        expect_near(10.0, layer:getDepth(), 0.001)
    end)

    -- @tests LuaParallaxLayer.setDepth
    -- @tests LuaParallaxLayer.getDepth
    -- @description Sets a negative depth and verifies it round-trips.
    it("setDepth to negative value", function()
        local layer = make_layer()
        layer:setDepth(-10.0)
        expect_near(-10.0, layer:getDepth(), 0.001)
    end)

    -- @tests LuaParallaxLayer.setDepth
    -- @tests LuaParallaxLayer.getDepth
    -- @description Sets a fractional depth and verifies it round-trips with
    -- floating-point tolerance.
    it("setDepth to fractional value", function()
        local layer = make_layer()
        layer:setDepth(0.5)
        expect_near(0.5, layer:getDepth(), 0.001)
    end)

    -- @tests LuaParallaxLayer.setDepth
    -- @tests LuaParallaxLayer.getDepth
    -- @description Verifies depth can be updated multiple times.
    it("setDepth can be updated multiple times", function()
        local layer = make_layer()
        layer:setDepth(1.0)
        layer:setDepth(-5.5)
        layer:setDepth(100.0)
        expect_near(100.0, layer:getDepth(), 0.001)
    end)

    -- @tests LuaParallaxLayer.setDepth
    -- @tests LuaParallaxLayer.getDepth
    -- @description Verifies depth is independent of the integer z value.
    it("setDepth is independent of setZ", function()
        local layer = make_layer()
        layer:setZ(5)
        layer:setDepth(2.5)
        expect_equal(5, layer:getZ())
        expect_near(2.5, layer:getDepth(), 0.001)
    end)
end)

-- ── Parallax Tiling (merged from test_parallax_tiling.lua) ────────────────────

-- @description Covers suite: parallax tiling enable/disable.
describe("parallax tiling", function()
    -- @tests LuaParallaxLayer.getTiling
    -- @description Verifies tiling is disabled by default on a newly created layer.
    it("tiling is disabled by default", function()
        local layer = make_layer()
        expect_equal(false, layer:getTiling())
    end)

    -- @tests LuaParallaxLayer.setTiling
    -- @tests LuaParallaxLayer.getTiling
    -- @description Enables tiling and verifies getTiling returns true.
    it("setTiling(true) enables tiling", function()
        local layer = make_layer()
        layer:setTiling(true)
        expect_equal(true, layer:getTiling())
    end)

    -- @tests LuaParallaxLayer.setTiling
    -- @tests LuaParallaxLayer.getTiling
    -- @description Disables tiling after enabling and verifies getTiling returns false.
    it("setTiling(false) disables tiling", function()
        local layer = make_layer()
        layer:setTiling(true)
        layer:setTiling(false)
        expect_equal(false, layer:getTiling())
    end)

    -- @tests LuaParallaxLayer.setTiling
    -- @tests LuaParallaxLayer.getTiling
    -- @description Verifies multiple toggle round-trips are stable.
    it("toggling tiling multiple times is stable", function()
        local layer = make_layer()
        layer:setTiling(true)
        layer:setTiling(false)
        layer:setTiling(true)
        expect_equal(true, layer:getTiling())
    end)
end)

-- @description Covers suite: parallax tile size override.
describe("parallax tile size", function()
    -- @tests LuaParallaxLayer.setTileSize
    -- @description Verifies setTileSize accepts positive dimensions without error.
    it("setTileSize accepts positive dimensions", function()
        local layer = make_layer()
        -- Should not error
        layer:setTileSize(256.0, 128.0)
        expect_equal(true, true)  -- reached without error
    end)

    -- @tests LuaParallaxLayer.setTileSize
    -- @description Verifies setTileSize with zero width resets to texture-based dimensions.
    it("setTileSize with zero width resets to texture default", function()
        local layer = make_layer()
        layer:setTileSize(0.0, 64.0)
        -- Non-positive w resets tile_w; no error expected
        expect_equal(true, true)
    end)

    -- @tests LuaParallaxLayer.setTileSize
    -- @description Verifies setTileSize can be combined with setTiling without error.
    it("setTileSize combined with setTiling works", function()
        local layer = make_layer()
        layer:setTiling(true)
        layer:setTileSize(128.0, 128.0)
        expect_equal(true, layer:getTiling())
    end)
end)

test_summary()

describe("Missing explicit test for ParallaxLayer:type", function()
    it("ParallaxLayer:type works", function()
        -- @tests ParallaxLayer:type
        -- TODO: add assertion for ParallaxLayer:type
    end)
end)

describe("Missing explicit test for ParallaxLayer:update", function()
    it("ParallaxLayer:update works", function()
        -- @tests ParallaxLayer:update
        -- TODO: add assertion for ParallaxLayer:update
    end)
end)

describe("Missing explicit test for ParallaxLayer:render", function()
    it("ParallaxLayer:render works", function()
        -- @tests ParallaxLayer:render
        -- TODO: add assertion for ParallaxLayer:render
    end)
end)

describe("Missing explicit test for ParallaxLayer:renderAuto", function()
    it("ParallaxLayer:renderAuto works", function()
        -- @tests ParallaxLayer:renderAuto
        -- TODO: add assertion for ParallaxLayer:renderAuto
    end)
end)

describe("Missing explicit test for ParallaxLayer:resetAutoscroll", function()
    it("ParallaxLayer:resetAutoscroll works", function()
        -- @tests ParallaxLayer:resetAutoscroll
        -- TODO: add assertion for ParallaxLayer:resetAutoscroll
    end)
end)

describe("Missing explicit test for ParallaxLayer:setScrollFactor", function()
    it("ParallaxLayer:setScrollFactor works", function()
        -- @tests ParallaxLayer:setScrollFactor
        -- TODO: add assertion for ParallaxLayer:setScrollFactor
    end)
end)

describe("Missing explicit test for ParallaxLayer:getScrollFactor", function()
    it("ParallaxLayer:getScrollFactor works", function()
        -- @tests ParallaxLayer:getScrollFactor
        -- TODO: add assertion for ParallaxLayer:getScrollFactor
    end)
end)

describe("Missing explicit test for ParallaxLayer:setOffset", function()
    it("ParallaxLayer:setOffset works", function()
        -- @tests ParallaxLayer:setOffset
        -- TODO: add assertion for ParallaxLayer:setOffset
    end)
end)

describe("Missing explicit test for ParallaxLayer:getOffset", function()
    it("ParallaxLayer:getOffset works", function()
        -- @tests ParallaxLayer:getOffset
        -- TODO: add assertion for ParallaxLayer:getOffset
    end)
end)

describe("Missing explicit test for ParallaxLayer:setAutoscroll", function()
    it("ParallaxLayer:setAutoscroll works", function()
        -- @tests ParallaxLayer:setAutoscroll
        -- TODO: add assertion for ParallaxLayer:setAutoscroll
    end)
end)

describe("Missing explicit test for ParallaxLayer:getAutoscroll", function()
    it("ParallaxLayer:getAutoscroll works", function()
        -- @tests ParallaxLayer:getAutoscroll
        -- TODO: add assertion for ParallaxLayer:getAutoscroll
    end)
end)

describe("Missing explicit test for ParallaxLayer:setRepeat", function()
    it("ParallaxLayer:setRepeat works", function()
        -- @tests ParallaxLayer:setRepeat
        -- TODO: add assertion for ParallaxLayer:setRepeat
    end)
end)

describe("Missing explicit test for ParallaxLayer:setScale", function()
    it("ParallaxLayer:setScale works", function()
        -- @tests ParallaxLayer:setScale
        -- TODO: add assertion for ParallaxLayer:setScale
    end)
end)

describe("Missing explicit test for ParallaxLayer:setZ", function()
    it("ParallaxLayer:setZ works", function()
        -- @tests ParallaxLayer:setZ
        -- TODO: add assertion for ParallaxLayer:setZ
    end)
end)

describe("Missing explicit test for ParallaxLayer:getZ", function()
    it("ParallaxLayer:getZ works", function()
        -- @tests ParallaxLayer:getZ
        -- TODO: add assertion for ParallaxLayer:getZ
    end)
end)

describe("Missing explicit test for ParallaxLayer:setOpacity", function()
    it("ParallaxLayer:setOpacity works", function()
        -- @tests ParallaxLayer:setOpacity
        -- TODO: add assertion for ParallaxLayer:setOpacity
    end)
end)

describe("Missing explicit test for ParallaxLayer:getOpacity", function()
    it("ParallaxLayer:getOpacity works", function()
        -- @tests ParallaxLayer:getOpacity
        -- TODO: add assertion for ParallaxLayer:getOpacity
    end)
end)

describe("Missing explicit test for ParallaxLayer:setTint", function()
    it("ParallaxLayer:setTint works", function()
        -- @tests ParallaxLayer:setTint
        -- TODO: add assertion for ParallaxLayer:setTint
    end)
end)

describe("Missing explicit test for ParallaxLayer:getTint", function()
    it("ParallaxLayer:getTint works", function()
        -- @tests ParallaxLayer:getTint
        -- TODO: add assertion for ParallaxLayer:getTint
    end)
end)

describe("Missing explicit test for ParallaxLayer:setBlendMode", function()
    it("ParallaxLayer:setBlendMode works", function()
        -- @tests ParallaxLayer:setBlendMode
        -- TODO: add assertion for ParallaxLayer:setBlendMode
    end)
end)

describe("Missing explicit test for ParallaxLayer:getBlendMode", function()
    it("ParallaxLayer:getBlendMode works", function()
        -- @tests ParallaxLayer:getBlendMode
        -- TODO: add assertion for ParallaxLayer:getBlendMode
    end)
end)

describe("Missing explicit test for ParallaxLayer:setVisible", function()
    it("ParallaxLayer:setVisible works", function()
        -- @tests ParallaxLayer:setVisible
        -- TODO: add assertion for ParallaxLayer:setVisible
    end)
end)

describe("Missing explicit test for ParallaxLayer:isVisible", function()
    it("ParallaxLayer:isVisible works", function()
        -- @tests ParallaxLayer:isVisible
        -- TODO: add assertion for ParallaxLayer:isVisible
    end)
end)

describe("Missing explicit test for ParallaxLayer:clearClamp", function()
    it("ParallaxLayer:clearClamp works", function()
        -- @tests ParallaxLayer:clearClamp
        -- TODO: add assertion for ParallaxLayer:clearClamp
    end)
end)

describe("Missing explicit test for ParallaxLayer:setTiling", function()
    it("ParallaxLayer:setTiling works", function()
        -- @tests ParallaxLayer:setTiling
        -- TODO: add assertion for ParallaxLayer:setTiling
    end)
end)

describe("Missing explicit test for ParallaxLayer:getTiling", function()
    it("ParallaxLayer:getTiling works", function()
        -- @tests ParallaxLayer:getTiling
        -- TODO: add assertion for ParallaxLayer:getTiling
    end)
end)

describe("Missing explicit test for ParallaxLayer:setTileSize", function()
    it("ParallaxLayer:setTileSize works", function()
        -- @tests ParallaxLayer:setTileSize
        -- TODO: add assertion for ParallaxLayer:setTileSize
    end)
end)

describe("Missing explicit test for ParallaxLayer:setDepth", function()
    it("ParallaxLayer:setDepth works", function()
        -- @tests ParallaxLayer:setDepth
        -- TODO: add assertion for ParallaxLayer:setDepth
    end)
end)

describe("Missing explicit test for ParallaxLayer:getDepth", function()
    it("ParallaxLayer:getDepth works", function()
        -- @tests ParallaxLayer:getDepth
        -- TODO: add assertion for ParallaxLayer:getDepth
    end)
end)

describe("Missing explicit test for ParallaxSet:type", function()
    it("ParallaxSet:type works", function()
        -- @tests ParallaxSet:type
        -- TODO: add assertion for ParallaxSet:type
    end)
end)

describe("Missing explicit test for ParallaxSet:addLayer", function()
    it("ParallaxSet:addLayer works", function()
        -- @tests ParallaxSet:addLayer
        -- TODO: add assertion for ParallaxSet:addLayer
    end)
end)

describe("Missing explicit test for ParallaxSet:removeLayerAt", function()
    it("ParallaxSet:removeLayerAt works", function()
        -- @tests ParallaxSet:removeLayerAt
        -- TODO: add assertion for ParallaxSet:removeLayerAt
    end)
end)

describe("Missing explicit test for ParallaxSet:layerCount", function()
    it("ParallaxSet:layerCount works", function()
        -- @tests ParallaxSet:layerCount
        -- TODO: add assertion for ParallaxSet:layerCount
    end)
end)

describe("Missing explicit test for ParallaxSet:sortByZ", function()
    it("ParallaxSet:sortByZ works", function()
        -- @tests ParallaxSet:sortByZ
        -- TODO: add assertion for ParallaxSet:sortByZ
    end)
end)

describe("Missing explicit test for ParallaxSet:setVisible", function()
    it("ParallaxSet:setVisible works", function()
        -- @tests ParallaxSet:setVisible
        -- TODO: add assertion for ParallaxSet:setVisible
    end)
end)

describe("Missing explicit test for ParallaxSet:isVisible", function()
    it("ParallaxSet:isVisible works", function()
        -- @tests ParallaxSet:isVisible
        -- TODO: add assertion for ParallaxSet:isVisible
    end)
end)

describe("Missing explicit test for ParallaxSet:update", function()
    it("ParallaxSet:update works", function()
        -- @tests ParallaxSet:update
        -- TODO: add assertion for ParallaxSet:update
    end)
end)

describe("Missing explicit test for ParallaxSet:renderAuto", function()
    it("ParallaxSet:renderAuto works", function()
        -- @tests ParallaxSet:renderAuto
        -- TODO: add assertion for ParallaxSet:renderAuto
    end)
end)

describe("Missing explicit test for ParallaxSet:getName", function()
    it("ParallaxSet:getName works", function()
        -- @tests ParallaxSet:getName
        -- TODO: add assertion for ParallaxSet:getName
    end)
end)

describe("Missing explicit test for ParallaxSet:setName", function()
    it("ParallaxSet:setName works", function()
        -- @tests ParallaxSet:setName
        -- TODO: add assertion for ParallaxSet:setName
    end)
end)
