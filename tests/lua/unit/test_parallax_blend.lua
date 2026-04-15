-- Lurek2D Parallax Blend Mode Unit Tests (headless)
-- Tests: setBlendMode / getBlendMode canonical string names (normal, additive,
-- multiply, screen, replace) and error handling for unknown modes.
--
-- @covers LuaParallaxLayer.setBlendMode
-- @covers LuaParallaxLayer.getBlendMode

-- Helper: create a layer backed by a real texture.
local function make_layer()
    local img = lurek.graphic.newImage("assets/icon.png")
    return lurek.parallax.newLayer({ texture = img })
end

-- ── default blend mode ────────────────────────────────────────────────────────

-- @description Covers suite: parallax per-layer blend mode.
describe("parallax blend modes", function()
    -- @covers LuaParallaxLayer.getBlendMode
    -- @description Verifies the default blend mode is 'normal' (alpha blending).
    it("default blend mode is 'normal'", function()
        local layer = make_layer()
        expect_equal("normal", layer:getBlendMode())
    end)

    -- @covers LuaParallaxLayer.setBlendMode
    -- @covers LuaParallaxLayer.getBlendMode
    -- @description Sets mode to 'additive' and verifies it round-trips.
    it("setBlendMode 'additive' works", function()
        local layer = make_layer()
        layer:setBlendMode("additive")
        expect_equal("additive", layer:getBlendMode())
    end)

    -- @covers LuaParallaxLayer.setBlendMode
    -- @covers LuaParallaxLayer.getBlendMode
    -- @description Sets mode to 'multiply' and verifies it round-trips.
    it("setBlendMode 'multiply' works", function()
        local layer = make_layer()
        layer:setBlendMode("multiply")
        expect_equal("multiply", layer:getBlendMode())
    end)

    -- @covers LuaParallaxLayer.setBlendMode
    -- @covers LuaParallaxLayer.getBlendMode
    -- @description Sets mode to 'screen' and verifies it round-trips.
    it("setBlendMode 'screen' works", function()
        local layer = make_layer()
        layer:setBlendMode("screen")
        expect_equal("screen", layer:getBlendMode())
    end)

    -- @covers LuaParallaxLayer.setBlendMode
    -- @covers LuaParallaxLayer.getBlendMode
    -- @description Sets mode to 'replace' and verifies it round-trips.
    it("setBlendMode 'replace' works", function()
        local layer = make_layer()
        layer:setBlendMode("replace")
        expect_equal("replace", layer:getBlendMode())
    end)

    -- @covers LuaParallaxLayer.setBlendMode
    -- @covers LuaParallaxLayer.getBlendMode
    -- @description Verifies the legacy alias 'alpha' maps to 'normal'.
    it("legacy alias 'alpha' maps to 'normal'", function()
        local layer = make_layer()
        layer:setBlendMode("alpha")
        expect_equal("normal", layer:getBlendMode())
    end)

    -- @covers LuaParallaxLayer.setBlendMode
    -- @covers LuaParallaxLayer.getBlendMode
    -- @description Verifies the legacy alias 'add' maps to 'additive'.
    it("legacy alias 'add' maps to 'additive'", function()
        local layer = make_layer()
        layer:setBlendMode("add")
        expect_equal("additive", layer:getBlendMode())
    end)

    -- @covers LuaParallaxLayer.setBlendMode
    -- @description Verifies an unrecognised blend mode string raises a Lua error.
    it("invalid blend mode 'glow' raises an error", function()
        local layer = make_layer()
        expect_error(function() layer:setBlendMode("glow") end)
    end)

    -- @covers LuaParallaxLayer.setBlendMode
    -- @description Verifies blend mode can be changed multiple times.
    it("blend mode can be changed multiple times", function()
        local layer = make_layer()
        layer:setBlendMode("additive")
        layer:setBlendMode("multiply")
        layer:setBlendMode("normal")
        expect_equal("normal", layer:getBlendMode())
    end)
end)

test_summary()
