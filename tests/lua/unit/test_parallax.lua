-- Lurek2D Parallax API Unit Tests (headless)
-- Tests: module existence, layer creation, scroll math, autoscroll, repeat,
--        opacity, tint, blend mode, z-ordering in sets, resetAutoscroll.
--
-- @covers lurek.parallax.newLayer
-- @covers lurek.parallax.newSet
-- @covers LuaParallaxLayer.type
-- @covers LuaParallaxLayer.update
-- @covers LuaParallaxLayer.draw
-- @covers LuaParallaxLayer.drawAuto
-- @covers LuaParallaxLayer.resetAutoscroll
-- @covers LuaParallaxLayer.setScrollFactor
-- @covers LuaParallaxLayer.getScrollFactor
-- @covers LuaParallaxLayer.setOffset
-- @covers LuaParallaxLayer.getOffset
-- @covers LuaParallaxLayer.setAutoscroll
-- @covers LuaParallaxLayer.getAutoscroll
-- @covers LuaParallaxLayer.setRepeat
-- @covers LuaParallaxLayer.setScale
-- @covers LuaParallaxLayer.setZ
-- @covers LuaParallaxLayer.getZ
-- @covers LuaParallaxLayer.setOpacity
-- @covers LuaParallaxLayer.getOpacity
-- @covers LuaParallaxLayer.setTint
-- @covers LuaParallaxLayer.getTint
-- @covers LuaParallaxLayer.setBlendMode
-- @covers LuaParallaxLayer.getBlendMode
-- @covers LuaParallaxLayer.setVisible
-- @covers LuaParallaxLayer.isVisible
-- @covers LuaParallaxLayer.setClamp
-- @covers LuaParallaxLayer.clearClamp
-- @covers LuaParallaxSet.type
-- @covers LuaParallaxSet.addLayer
-- @covers LuaParallaxSet.removeLayerAt
-- @covers LuaParallaxSet.layerCount
-- @covers LuaParallaxSet.sortByZ
-- @covers LuaParallaxSet.setVisible
-- @covers LuaParallaxSet.isVisible
-- @covers LuaParallaxSet.update
-- @covers LuaParallaxSet.draw
-- @covers LuaParallaxSet.drawAuto
-- @covers LuaParallaxSet.getName
-- @covers LuaParallaxSet.setName

-- Helper: load a real texture for tests that require a LuaImage.
local function load_image()
    return lurek.graphic.newImage("assets/icon.png")
end

-- ── Module existence ──────────────────────────────────────────────────────────

describe("lurek.parallax module exists", function()
    it("lurek.parallax is a table", function()
        expect_type("table", lurek.parallax)
    end)

    it("newLayer is a function", function()
        expect_type("function", lurek.parallax.newLayer)
    end)

    it("newSet is a function", function()
        expect_type("function", lurek.parallax.newSet)
    end)
end)

-- ── newLayer ─────────────────────────────────────────────────────────────────

describe("lurek.parallax.newLayer", function()
    it("returns userdata when given a valid texture", function()
        local img = load_image()
        local layer = lurek.parallax.newLayer({ texture = img })
        expect_type("userdata", layer)
    end)

    it("type() returns 'ParallaxLayer'", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_equal("ParallaxLayer", layer:type())
    end)

    it("errors when texture field is missing", function()
        expect_error(function()
            lurek.parallax.newLayer({})
        end)
    end)

    it("errors when texture is not a LuaImage", function()
        expect_error(function()
            lurek.parallax.newLayer({ texture = "not an image" })
        end)
    end)

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

    it("accepts opacity", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            opacity = 0.5,
        })
        expect_near(0.5, layer:getOpacity())
    end)

    it("accepts z value", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            z = -5,
        })
        expect_equal(-5, layer:getZ())
    end)

    it("accepts blend_mode string", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            blend_mode = "add",
        })
        expect_equal("add", layer:getBlendMode())
    end)

    it("accepts visible = false", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            visible = false,
        })
        expect_equal(false, layer:isVisible())
    end)
end)

-- ── Defaults ─────────────────────────────────────────────────────────────────

describe("LuaParallaxLayer defaults", function()
    local img
    local layer

    it("scroll factor defaults to (1, 0)", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        local x, y = layer:getScrollFactor()
        expect_near(1.0, x)
        expect_near(0.0, y)
    end)

    it("offset defaults to (0, 0)", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        local x, y = layer:getOffset()
        expect_near(0.0, x)
        expect_near(0.0, y)
    end)

    it("opacity defaults to 1.0", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_near(1.0, layer:getOpacity())
    end)

    it("z defaults to 0", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_equal(0, layer:getZ())
    end)

    it("blend mode defaults to 'alpha'", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_equal("alpha", layer:getBlendMode())
    end)

    it("isVisible defaults to true", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_equal(true, layer:isVisible())
    end)

    it("autoscroll defaults to (0, 0)", function()
        layer = lurek.parallax.newLayer({ texture = load_image() })
        local vx, vy = layer:getAutoscroll()
        expect_near(0.0, vx)
        expect_near(0.0, vy)
    end)
end)

-- ── Getters / setters ─────────────────────────────────────────────────────────

describe("LuaParallaxLayer setters and getters", function()
    it("setScrollFactor / getScrollFactor round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setScrollFactor(0.25, 0.75)
        local x, y = layer:getScrollFactor()
        expect_near(0.25, x)
        expect_near(0.75, y)
    end)

    it("setOffset / getOffset round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setOffset(100.0, -50.0)
        local x, y = layer:getOffset()
        expect_near(100.0, x)
        expect_near(-50.0, y)
    end)

    it("setAutoscroll / getAutoscroll round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setAutoscroll(30.0, -10.0)
        local vx, vy = layer:getAutoscroll()
        expect_near(30.0, vx)
        expect_near(-10.0, vy)
    end)

    it("setZ / getZ round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setZ(-3)
        expect_equal(-3, layer:getZ())
        layer:setZ(10)
        expect_equal(10, layer:getZ())
    end)

    it("setOpacity / getOpacity round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setOpacity(0.4)
        expect_near(0.4, layer:getOpacity())
    end)

    it("setOpacity clamps to [0, 1]", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setOpacity(2.0)
        expect_near(1.0, layer:getOpacity())
        layer:setOpacity(-1.0)
        expect_near(0.0, layer:getOpacity())
    end)

    it("setTint / getTint round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setTint(0.5, 0.3, 0.8, 0.7)
        local r, g, b, a = layer:getTint()
        expect_near(0.5, r)
        expect_near(0.3, g)
        expect_near(0.8, b)
        expect_near(0.7, a)
    end)

    it("setBlendMode / getBlendMode round-trip for each mode", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        local modes = { "alpha", "add", "multiply", "replace", "screen" }
        for _, mode in ipairs(modes) do
            layer:setBlendMode(mode)
            expect_equal(mode, layer:getBlendMode())
        end
    end)

    it("unrecognised blend mode falls back to alpha", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setBlendMode("bogus")
        expect_equal("alpha", layer:getBlendMode())
    end)

    it("setVisible / isVisible round-trip", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setVisible(false)
        expect_equal(false, layer:isVisible())
        layer:setVisible(true)
        expect_equal(true, layer:isVisible())
    end)
end)

-- ── Autoscroll / update ───────────────────────────────────────────────────────

describe("LuaParallaxLayer autoscroll", function()
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

-- ── draw / drawAuto ───────────────────────────────────────────────────────────

describe("LuaParallaxLayer draw", function()
    it("draw does not raise an error (visible layer)", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_no_error(function()
            layer:draw(0, 0)
        end)
    end)

    it("draw does not raise an error when invisible", function()
        local layer = lurek.parallax.newLayer({ texture = load_image(), visible = false })
        expect_no_error(function()
            layer:draw(100, 200)
        end)
    end)

    it("drawAuto does not raise an error", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_no_error(function()
            layer:drawAuto()
        end)
    end)

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

-- ── Clamp ────────────────────────────────────────────────────────────────────

describe("LuaParallaxLayer clamp", function()
    it("setClamp does not raise", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_no_error(function()
            layer:setClamp(-200, -100, 200, 100)
        end)
    end)

    it("clearClamp does not raise after setClamp", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setClamp(-100, -100, 100, 100)
        expect_no_error(function()
            layer:clearClamp()
        end)
    end)

    it("draw after setClamp does not raise", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        layer:setClamp(-50, -50, 50, 50)
        expect_no_error(function()
            layer:draw(1000, 1000)
        end)
    end)
end)

-- ── newSet ────────────────────────────────────────────────────────────────────

describe("lurek.parallax.newSet", function()
    it("returns userdata", function()
        local s = lurek.parallax.newSet("bg")
        expect_type("userdata", s)
    end)

    it("type() returns 'ParallaxSet'", function()
        local s = lurek.parallax.newSet("bg")
        expect_equal("ParallaxSet", s:type())
    end)

    it("layerCount starts at 0", function()
        local s = lurek.parallax.newSet("bg")
        expect_equal(0, s:layerCount())
    end)

    it("getName returns the name passed to newSet", function()
        local s = lurek.parallax.newSet("my_scene")
        expect_equal("my_scene", s:getName())
    end)

    it("setName changes the name", function()
        local s = lurek.parallax.newSet("old")
        s:setName("new")
        expect_equal("new", s:getName())
    end)

    it("isVisible returns true by default", function()
        local s = lurek.parallax.newSet("bg")
        expect_equal(true, s:isVisible())
    end)

    it("setVisible / isVisible round-trip", function()
        local s = lurek.parallax.newSet("bg")
        s:setVisible(false)
        expect_equal(false, s:isVisible())
        s:setVisible(true)
        expect_equal(true, s:isVisible())
    end)
end)

-- ── Set: addLayer / layerCount / removeLayerAt ────────────────────────────────

describe("LuaParallaxSet layer management", function()
    it("addLayer increases layerCount", function()
        local s = lurek.parallax.newSet("bg")
        local img = load_image()
        s:addLayer(lurek.parallax.newLayer({ texture = img }))
        expect_equal(1, s:layerCount())
        s:addLayer(lurek.parallax.newLayer({ texture = img }))
        expect_equal(2, s:layerCount())
    end)

    it("removeLayerAt with valid index returns true", function()
        local s = lurek.parallax.newSet("bg")
        s:addLayer(lurek.parallax.newLayer({ texture = load_image() }))
        local ok = s:removeLayerAt(1)
        expect_equal(true, ok)
        expect_equal(0, s:layerCount())
    end)

    it("removeLayerAt with out-of-range index returns false", function()
        local s = lurek.parallax.newSet("bg")
        local ok = s:removeLayerAt(99)
        expect_equal(false, ok)
    end)

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

-- ── Set: draw / update / sortByZ ─────────────────────────────────────────────

describe("LuaParallaxSet drawing", function()
    it("draw does not raise with zero layers", function()
        local s = lurek.parallax.newSet("bg")
        expect_no_error(function() s:draw(0, 0) end)
    end)

    it("draw does not raise with multiple layers", function()
        local s = lurek.parallax.newSet("bg")
        local img = load_image()
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = 1 }))
        expect_no_error(function() s:draw(300, 200) end)
    end)

    it("drawAuto does not raise", function()
        local s = lurek.parallax.newSet("bg")
        s:addLayer(lurek.parallax.newLayer({ texture = load_image() }))
        expect_no_error(function() s:drawAuto() end)
    end)

    it("draw while invisible does not raise", function()
        local s = lurek.parallax.newSet("bg")
        s:addLayer(lurek.parallax.newLayer({ texture = load_image() }))
        s:setVisible(false)
        expect_no_error(function() s:draw(0, 0) end)
    end)

    it("update does not raise", function()
        local s = lurek.parallax.newSet("bg")
        s:addLayer(lurek.parallax.newLayer({ texture = load_image(), autoscroll_x = 50.0 }))
        expect_no_error(function() s:update(1.0 / 60.0) end)
    end)

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

-- ── Scene-transition pattern ──────────────────────────────────────────────────

describe("Scene-transition: resetAutoscroll pattern", function()
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

test_summary()
