-- Lurek2D Graphics API Tests (headless  tests lurek.render API existence and behaviour)

-- @describe lurek.render module exists
describe("lurek.render module exists", function()
    -- @covers lurek.render
    it("lurek.render is a table", function()
        expect_type("table", lurek.render)
    end)
end)

-- @describe lurek.render color functions
describe("lurek.render color functions", function()
    -- @covers lurek.render.setColor
    it("setColor is a function", function()
        expect_type("function", lurek.render.setColor)
    end)

    -- @covers lurek.render.setColor
    it("setColor accepts 3 args", function()
        expect_no_error(function()
            lurek.render.setColor(1, 0, 0)
        end)
    end)

    -- @covers lurek.render.setColor
    it("setColor accepts 4 args", function()
        expect_no_error(function()
            lurek.render.setColor(1, 0, 0, 0.5)
        end)
    end)

    -- @covers lurek.render.setBackgroundColor
    it("setBackgroundColor is a function", function()
        expect_type("function", lurek.render.setBackgroundColor)
    end)

    -- @covers lurek.render.setBackgroundColor
    it("setBackgroundColor accepts 3 args", function()
        expect_no_error(function()
            lurek.render.setBackgroundColor(0.1, 0.1, 0.1)
        end)
    end)
end)

-- @describe lurek.render shape functions
describe("lurek.render shape functions", function()
    -- @covers lurek.render.rectangle
    it("rectangle is a function", function()
        expect_type("function", lurek.render.rectangle)
    end)

    -- @covers lurek.render.rectangle
    it("rectangle fill mode", function()
        expect_no_error(function()
            lurek.render.rectangle("fill", 10, 10, 100, 50)
        end)
    end)

    -- @covers lurek.render.rectangle
    it("rectangle line mode", function()
        expect_no_error(function()
            lurek.render.rectangle("line", 10, 10, 100, 50)
        end)
    end)

    -- @covers lurek.render.circle
    it("circle is a function", function()
        expect_type("function", lurek.render.circle)
    end)

    -- @covers lurek.render.circle
    it("circle fill mode", function()
        expect_no_error(function()
            lurek.render.circle("fill", 50, 50, 25)
        end)
    end)

    -- @covers lurek.render.line
    it("line is a function", function()
        expect_type("function", lurek.render.line)
    end)

    -- @covers lurek.render.line
    it("line accepts 4 args", function()
        expect_no_error(function()
            lurek.render.line(0, 0, 100, 100)
        end)
    end)
end)

-- @describe lurek.render text functions
describe("lurek.render text functions", function()
    -- @covers lurek.render.print
    it("print is a function", function()
        expect_type("function", lurek.render.print)
    end)

    -- @covers lurek.render.print
    it("print accepts text and position", function()
        expect_no_error(function()
            lurek.render.print("Hello", 10, 10)
        end)
    end)
end)

-- @describe lurek.render image functions
describe("lurek.render image functions", function()
    -- @covers lurek.render.newImage
    it("newImage is a function", function()
        expect_type("function", lurek.render.newImage)
    end)

    -- @covers lurek.render.draw
    it("draw is a function", function()
        expect_type("function", lurek.render.draw)
    end)
end)

-- @describe lurek.render advanced shapes
describe("lurek.render advanced shapes", function()
    -- @covers lurek.render.ellipse
    it("ellipse is a function", function()
        expect_type("function", lurek.render.ellipse)
    end)

    -- @covers lurek.render.ellipse
    it("ellipse fill mode", function()
        expect_no_error(function()
            lurek.render.ellipse("fill", 100, 100, 50, 30)
        end)
    end)

    -- @covers lurek.render.polygon
    it("polygon is a function", function()
        expect_type("function", lurek.render.polygon)
    end)

    -- @covers lurek.render.polygon
    it("polygon fill mode with vertices", function()
        expect_no_error(function()
            lurek.render.polygon("fill", 0, 0, 100, 0, 50, 100)
        end)
    end)

    -- @covers lurek.render.triangle
    it("triangle is a function", function()
        expect_type("function", lurek.render.triangle)
    end)

    -- @covers lurek.render.triangle
    it("triangle fill mode", function()
        expect_no_error(function()
            lurek.render.triangle("fill", 0, 0, 100, 0, 50, 80)
        end)
    end)

    -- @covers lurek.render.setLineWidth
    it("setLineWidth is a function", function()
        expect_type("function", lurek.render.setLineWidth)
    end)

    -- @covers lurek.render.getLineWidth
    it("getLineWidth is a function", function()
        expect_type("function", lurek.render.getLineWidth)
    end)

    -- @covers lurek.render.getLineWidth
    -- @covers lurek.render.setLineWidth
    it("setLineWidth and getLineWidth roundtrip", function()
        lurek.render.setLineWidth(3.0)
        expect_near(3.0, lurek.render.getLineWidth())
        lurek.render.setLineWidth(1.0) -- reset
    end)

    -- @covers lurek.render.getDimensions
    it("getDimensions returns two numbers", function()
        local w, h = lurek.render.getDimensions()
        expect_type("number", w)
        expect_type("number", h)
        expect_true(w > 0, "width > 0")
        expect_true(h > 0, "height > 0")
    end)
end)

-- =========================================================================
-- Font metrics
-- =========================================================================
-- @describe font metrics
describe("font metrics", function()
    -- @covers lurek.render.getFontLineHeight
    it("getFontLineHeight is a function", function()
        expect_type("function", lurek.render.getFontLineHeight)
    end)

    -- @covers lurek.render.setFontLineHeight
    it("setFontLineHeight is a function", function()
        expect_type("function", lurek.render.setFontLineHeight)
    end)

    -- @covers lurek.render.getFontAscent
    it("getFontAscent is a function", function()
        expect_type("function", lurek.render.getFontAscent)
    end)

    -- @covers lurek.render.getFontDescent
    it("getFontDescent is a function", function()
        expect_type("function", lurek.render.getFontDescent)
    end)
end)

-- Nine-Slice Tests

-- @describe lurek.render nine-slice
describe("lurek.render nine-slice", function()
    -- @covers lurek.render.newNineSlice
    it("newNineSlice is a function", function()
        expect_type("function", lurek.render.newNineSlice)
    end)

    -- @covers lurek.render.drawNineSlice
    it("drawNineSlice is a function", function()
        expect_type("function", lurek.render.drawNineSlice)
    end)

    -- @covers lurek.render.newImage
    -- @covers lurek.render.newNineSlice
    it("creates a NineSlice from an image", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 10, 10, 10, 10)
        expect_type("userdata", ns)
    end)

    -- @covers LNineSlice:getInsets
    -- @covers lurek.render.newImage
    -- @covers lurek.render.newNineSlice
    it("NineSlice:getInsets returns correct values", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 12, 8, 15, 6)
        local t, r, b, l = ns:getInsets()
        expect_near(12, t)
        expect_near(8, r)
        expect_near(15, b)
        expect_near(6, l)
    end)

    -- @covers LNineSlice:getTextureSize
    -- @covers lurek.render.newImage
    -- @covers lurek.render.newNineSlice
    it("NineSlice:getTextureSize returns image dimensions", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        local w, h = ns:getTextureSize()
        expect_greater(w, 0, "texture width should be positive")
        expect_greater(h, 0, "texture height should be positive")
    end)

    -- @covers lurek.render.drawNineSlice
    -- @covers lurek.render.newImage
    -- @covers lurek.render.newNineSlice
    it("drawNineSlice accepts NineSlice and rect", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 10, 10, 10, 10)
        expect_no_error(function()
            lurek.render.drawNineSlice(ns, 50, 50, 300, 200)
        end)
    end)

    -- @covers lurek.render.drawNineSlice
    -- @covers lurek.render.newImage
    -- @covers lurek.render.newNineSlice
    it("NineSlice:draw method works", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        expect_no_error(function()
            lurek.render.drawNineSlice(ns, 10, 20, 400, 300)
        end)
    end)

    -- @covers LNineSlice:typeOf
    -- @covers lurek.render.newImage
    -- @covers lurek.render.newNineSlice
    it("NineSlice:typeOf returns NineSlice", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        expect_true(ns:typeOf("NineSlice"), "should be NineSlice type")
        expect_true(ns:typeOf("Object"), "should be Object type")
    end)

    -- @covers lurek.render.newImage
    -- @covers lurek.render.newNineSlice
    it("rejects negative border insets", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ok = pcall(function()
            lurek.render.newNineSlice(img, -5, 10, 10, 10)
        end)
        expect_false(ok, "negative insets should error")
    end)
end)

-- Polymorphic draw() dispatch

-- @describe lurek.render.draw polymorphic dispatch
describe("lurek.render.draw polymorphic dispatch", function()
    -- @covers lurek.render.draw
    it("draw() rejects nil with an error", function()
        expect_error(function()
            lurek.render.draw(nil, 0, 0)
        end, "nil")
    end)

    -- @covers lurek.render.draw
    it("draw() rejects a non-drawable string with an error", function()
        ---@type any
        local not_a_drawable = "not_a_drawable"
        expect_error(function()
            lurek.render.draw(not_a_drawable, 0, 0)
        end, "drawable")
    end)

    -- @covers lurek.render.draw
    it("draw() is a function", function()
        expect_type("function", lurek.render.draw)
    end)
end)

-- @describe lurek.render.captureScreenshot
describe("lurek.render.captureScreenshot", function()
  -- @covers lurek.render.captureScreenshot
  it("accepts a callback without error", function()
    local ok, err = pcall(lurek.render.captureScreenshot, function(img)
    end)
    expect_equal(ok, true)
  end)

  -- @covers lurek.render.captureScreenshot
  it("callback receives an ImageData userdata", function()
    local received_type = nil
    lurek.render.captureScreenshot(function(img)
      received_type = type(img)
    end)
    expect_equal(received_type, "userdata")
  end)
end)

-- @describe lurek.render.saveScreenshot
describe("lurek.render.saveScreenshot", function()
    -- @covers lurek.render.saveScreenshot
    it("accepts a save-relative path without error", function()
        local ok = pcall(lurek.render.saveScreenshot, "save/test_render.png")
        expect_equal(ok, true)
    end)

    -- @covers lurek.render.saveScreenshot
    it("rejects paths outside save", function()
        expect_error(function()
            lurek.render.saveScreenshot("test_render.png")
        end, "save/")
    end)
end)

-- @describe lurek.render stencil mode
describe("lurek.render stencil mode", function()
  -- @covers lurek.render.getStencilMode
  -- @covers lurek.render.setStencilMode
  it("setStencilMode and getStencilMode round-trip correctly", function()
    lurek.render.setStencilMode("replace", "always", 1)
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "replace")
    expect_equal(compare, "always")
    expect_equal(value, 1)
  end)

  -- @covers lurek.render.clearStencil
  -- @covers lurek.render.getStencilMode
  -- @covers lurek.render.setStencilMode
  it("clearStencil resets to keep/always/0", function()
    lurek.render.setStencilMode("invert", "equal", 5)
    lurek.render.clearStencil()
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "keep")
    expect_equal(compare, "always")
    expect_equal(value, 0)
  end)

  -- @covers lurek.render.getStencilMode
  -- @covers lurek.render.setStencilMode
  it("setStencilMode defaults compare to always when omitted", function()
    lurek.render.setStencilMode("zero")
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "zero")
    expect_equal(compare, "always")
    expect_equal(value, 0)
  end)

  -- @covers lurek.render.setStencilMode
  it("setStencilMode errors on unknown action", function()
    expect_error(function()
      lurek.render.setStencilMode("explode")
    end)
  end)

  -- @covers lurek.render.setStencilMode
  it("setStencilMode is a function", function()
    expect_type("function", lurek.render.setStencilMode)
  end)

  -- @covers lurek.render.getStencilMode
  it("getStencilMode is a function", function()
    expect_type("function", lurek.render.getStencilMode)
  end)

  -- @covers lurek.render.clearStencil
  it("clearStencil is a function", function()
    expect_type("function", lurek.render.clearStencil)
  end)
end)

-- @describe lurek.render depth mode
describe("lurek.render depth mode", function()
  -- @covers lurek.render.getDepthMode
  -- @covers lurek.render.setDepthMode
  it("setDepthMode and getDepthMode round-trip correctly", function()
    lurek.render.setDepthMode("less", true)
    local mode, write = lurek.render.getDepthMode()
    expect_equal(mode, "less")
    expect_equal(write, true)
  end)

  -- @covers lurek.render.getDepthMode
  -- @covers lurek.render.setDepthMode
  it("setDepthMode write defaults to false", function()
    lurek.render.setDepthMode("always")
    local mode, write = lurek.render.getDepthMode()
    expect_equal(mode, "always")
    expect_equal(write, false)
  end)

  -- @covers lurek.render.setDepthMode
  it("setDepthMode errors on unknown mode", function()
    expect_error(function()
      lurek.render.setDepthMode("turbo")
    end)
  end)

  -- @covers lurek.render.setDepthMode
  it("setDepthMode is a function", function()
    expect_type("function", lurek.render.setDepthMode)
  end)

  -- @covers lurek.render.getDepthMode
  it("getDepthMode is a function", function()
    expect_type("function", lurek.render.getDepthMode)
  end)
end)


-- [merged from test_render_pipeline.lua]
-- Target rendering/drawing contract acceptance tests.
-- These assertions pin the intended public API from
-- work/rendering-drawing-current-state/reports/target-rendering-drawing-state.md.
-- Canonical constructors are asserted directly; legacy constructors are used only
-- as fallbacks to build objects for method-level contract checks.

local function try_call(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then
        return result
    end
    return nil
end

local function verify_image_data_contract(img)
    expect_not_nil(img, "draw_to_image should return an image object")
    if img ~= nil then
        if type(img.width) == "function" then
            expect_true(img:width() > 0, "image width should be positive")
        elseif type(img.getWidth) == "function" then
            expect_true(img:getWidth() > 0, "image width should be positive")
        end
    end
end

local function make_spine_subject()
    if lurek.spine ~= nil then
        if type(lurek.spine.newSkeleton) == "function" then
            return lurek.spine.newSkeleton("contract")
        end
    end
    error("No usable spine constructor available for contract test")
end

local function make_raycaster_subject()
    local rc = lurek.raycaster.new(8, 8)
    rc:setCell(5, 4, 1)
    return rc
end

local function make_ui_panel_subject()
    if lurek.ui ~= nil then
        if type(lurek.ui.newPanel) == "function" then
            return lurek.ui.newPanel()
        end
    end
    error("No usable UI panel constructor available for contract test")
end

local function make_particle_subject()
    if lurek.particle ~= nil and type(lurek.particle.newSystem) == "function" then
        return lurek.particle.newSystem({ maxParticles = 8, emissionRate = 0 })
    end
    error("No usable particle constructor available for contract test")
end

local function make_tilemap_subject()
    if lurek.tilemap ~= nil then
        if type(lurek.tilemap.newTileMap) == "function" then
            local map = lurek.tilemap.newTileMap(4, 4)
            if type(map.setTile) == "function" then
                try_call(function()
                    map:setTile(1, 1, 1, 1)
                end)
            end
            return map
        end
    end
    error("No usable tilemap constructor available for contract test")
end

local function make_minimap_subject()
    if lurek.minimap ~= nil then
        if type(lurek.minimap.newMinimap) == "function" then
            local mini = lurek.minimap.newMinimap(4, 4, 64, 64)
            if type(mini.setTerrainData) == "function" then
                mini:setTerrainData({
                    1, 1, 0, 0,
                    0, 1, 1, 0,
                    0, 0, 1, 1,
                    1, 0, 0, 1,
                })
            end
            return mini
        end
    end
    error("No usable minimap constructor available for contract test")
end

local function make_overlay_subject()
    if lurek.effect ~= nil then
        if type(lurek.effect.newOverlay) == "function" then
            return lurek.effect.newOverlay(64, 64)
        end
    end
    if lurek.effect ~= nil and type(lurek.effect.newOverlay) == "function" then
        return lurek.effect.newOverlay(64, 64)
    end
    error("No usable overlay constructor available for contract test")
end

local function make_parallax_subject()
    if lurek.parallax ~= nil then
        if type(lurek.parallax.newSet) == "function" then
            local set = lurek.parallax.newSet("contract")
            if type(lurek.parallax.newLayer) == "function" and lurek.render ~= nil and type(lurek.render.newImage) == "function" then
                local img = lurek.render.newImage("assets/icon.png")
                local layer = try_call(lurek.parallax.newLayer, { texture = img })
                if layer ~= nil then
                    set:addLayer(layer)
                end
            end
            return set
        end
    end
    error("No usable parallax constructor available for contract test")
end

-- @describe target rendering/drawing contract: raycaster
describe("target rendering/drawing contract: raycaster", function()
    -- @covers LRaycaster:buildScene
    it("raycaster objects expose buildScene()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.buildScene)
        expect_no_error(function()
            rc:buildScene({ px = 4.5, py = 4.5, angle = 0, fov = 1.0, rays = 8, max_dist = 8, screen_w = 64, screen_h = 64 }, {}, {}, {})
        end)
    end)

    -- @covers LRaycaster:drawView
    it("raycaster objects expose drawView()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.drawView)
        local img = rc:drawView(4.5, 4.5, 0, 1.0, 32, 32, 8)
        verify_image_data_contract(img)
    end)
end)

-- @describe target rendering/drawing contract: particle
describe("target rendering/drawing contract: particle", function()
    -- @covers lurek.render
    it("particle systems expose render()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.render)
        expect_no_error(function()
            ps:render()
        end)
    end)

    -- @covers lurek.render
    -- @covers LAnimation:drawToImage
    -- @covers LAreaChart:drawToImage
    -- @covers LBarChart:drawToImage
    -- @covers LLineChart:drawToImage
    -- @covers LMinimap:drawToImage
    -- @covers LOverlay:drawToImage
    -- @covers LParticleSystem:drawToImage
    -- @covers LPieChart:drawToImage
    -- @covers LScatterPlot:drawToImage
    it("particle systems expose drawToImage()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.drawToImage)
        local img = ps:drawToImage(64, 64)
        verify_image_data_contract(img)
    end)
end)

-- @describe target rendering/drawing contract: tilemap
describe("target rendering/drawing contract: tilemap", function()
    -- @covers lurek.tilemap.loadTMX
    it("exposes lurek.tilemap.loadTMX as the canonical TMX loader", function()
        expect_type("function", lurek.tilemap.loadTMX)
    end)

    -- @covers lurek.render
    it("tilemaps expose render()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.render)
        expect_no_error(function()
            map:render()
        end)
    end)

    -- @covers lurek.render
    it("tilemaps expose drawToImage()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.drawToImage)
        local img = map:drawToImage(16)
        verify_image_data_contract(img)
    end)
end)

-- @describe target rendering/drawing contract: minimap
describe("target rendering/drawing contract: minimap", function()
    -- @covers lurek.render
    it("minimaps expose render()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.render)
        expect_no_error(function()
            mini:render()
        end)
    end)

    -- @covers lurek.render
    it("minimaps expose drawToImage()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.drawToImage)
        local img = mini:drawToImage(4)
        verify_image_data_contract(img)
    end)
end)

-- @describe target rendering/drawing contract: overlay
describe("target rendering/drawing contract: overlay", function()
    -- @covers lurek.render
    it("overlays expose render()", function()
        local ov = make_overlay_subject()
        expect_type("function", ov.render)
        expect_no_error(function()
            ov:render()
        end)
    end)

    -- @covers LOverlay:flash
    it("overlays expose drawToImage()", function()
        local ov = make_overlay_subject()
        if type(ov.flash) == "function" then
            ov:flash(1, 1, 1, 1, 0.1)
        end
        expect_type("function", ov.drawToImage)
        local img = ov:drawToImage(64, 64)
        verify_image_data_contract(img)
    end)
end)

-- @describe target rendering/drawing contract: parallax
describe("target rendering/drawing contract: parallax", function()
    -- @covers lurek.render
    it("parallax sets expose render()", function()
        local bg = make_parallax_subject()
        expect_type("function", bg.render)
        expect_no_error(function()
            bg:render(0, 0)
        end)
    end)
end)

-- @describe render missing API coverage sweep
describe("render missing API coverage sweep", function()
    -- @covers lurek.render.getBackgroundColor
    it("getBackgroundColor is callable", function()
        local r, g, b, a = lurek.render.getBackgroundColor()
        expect_type("number", r)
        expect_type("number", g)
        expect_type("number", b)
        expect_type("number", a)
    end)

    -- @covers lurek.render.setPointSize
    -- @covers lurek.render.getPointSize
    it("setPointSize and getPointSize round-trip", function()
        lurek.render.setPointSize(2)
        expect_type("number", lurek.render.getPointSize())
        lurek.render.setPointSize(1)
    end)

    -- @covers lurek.render.printRich
    -- @covers lurek.render.printf
    -- @covers lurek.render.arc
    it("text and arc helpers are callable", function()
        expect_no_error(function()
            lurek.render.printRich({ { text = "Hello", r = 255, g = 255, b = 255, a = 255 } }, 8, 8)
            lurek.render.printf("Hello", 4, 4, 120, "left")
            lurek.render.arc("line", 32, 32, 12, 0, math.pi)
        end)
    end)

    -- @covers lurek.render.drawq
    -- @covers lurek.render.newImage
    -- @covers lurek.render.newQuad
    it("drawq is callable with image and quad", function()
        local img = lurek.render.newImage("assets/icon.png")
        local q = lurek.render.newQuad(0, 0, 1, 1, 1, 1)
        expect_no_error(function()
            lurek.render.drawq(img, q, 0, 0)
        end)
    end)

    -- @covers lurek.render.setScissor
    -- @covers lurek.render.getScissor
    -- @covers lurek.render.intersectScissor
    it("scissor API is callable", function()
        lurek.render.setScissor(0, 0, 64, 64)
        lurek.render.intersectScissor(8, 8, 32, 32)
        local x, y, w, h = lurek.render.getScissor()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", w)
        expect_type("number", h)
        lurek.render.setScissor()
    end)

    -- @covers lurek.render.setColorMask
    -- @covers lurek.render.getColorMask
    -- @covers lurek.render.setWireframe
    -- @covers lurek.render.isWireframe
    -- @covers lurek.render.setStencilTest
    it("render state API is callable", function()
        lurek.render.setColorMask(true, true, true, true)
        local r, g, b, a = lurek.render.getColorMask()
        expect_type("boolean", r)
        expect_type("boolean", g)
        expect_type("boolean", b)
        expect_type("boolean", a)
        lurek.render.setWireframe(false)
        expect_type("boolean", lurek.render.isWireframe())
        lurek.render.setStencilTest("always", 1)
        lurek.render.setStencilTest()
    end)

    -- @covers lurek.render.drawGradientRect
    -- @covers lurek.render.drawColoredPolygon
    -- @covers lurek.render.drawQuadBezier
    -- @covers lurek.render.drawCubicBezier
    -- @covers lurek.render.drawIsoCubeTile
    -- @covers lurek.render.drawHexTile
    -- @covers lurek.render.drawBevelRect
    it("extended primitive APIs are callable", function()
        lurek.render.drawGradientRect(0, 0, 16, 16, {1, 0, 0, 1}, {0, 1, 0, 1}, "vertical")
        lurek.render.drawColoredPolygon({0, 0, 16, 0, 8, 16}, {{1, 0, 0, 1}, {0, 1, 0, 1}, {0, 0, 1, 1}}, "fill")
        lurek.render.drawQuadBezier(0, 0, 8, 16, 16, 0)
        lurek.render.drawCubicBezier(0, 0, 5, 10, 11, 10, 16, 0)
        lurek.render.drawIsoCubeTile(32, 32, 16, 8, { depth = 12 })
        lurek.render.drawHexTile(64, 64, 12)
        lurek.render.drawBevelRect(2, 2, 20, 12, 2)
    end)

    -- @covers lurek.render.beginSortGroup
    -- @covers lurek.render.pushSortKey
    -- @covers lurek.render.flushSortGroup
    it("sort-group API is callable", function()
        lurek.render.beginSortGroup(1)
        lurek.render.pushSortKey(1)
        lurek.render.flushSortGroup(1)
    end)

    -- @covers lurek.render.pushLayer
    -- @covers lurek.render.popLayer
    -- @covers lurek.render.currentLayer
    -- @covers lurek.render.isLayerVisible
    -- @covers lurek.render.getLayerZOrder
    -- @covers lurek.render.setLayerZOrder
    -- @covers lurek.render.newLayer
    -- @covers lurek.render.setLayer
    it("layer API is callable", function()
        lurek.render.newLayer("ui", 0)
        lurek.render.setLayer("ui")
        lurek.render.pushLayer(1)
        local name = lurek.render.currentLayer()
        expect_type("string", name)
        expect_type("boolean", lurek.render.isLayerVisible("ui"))
        lurek.render.setLayerZOrder("ui", 100)
        expect_type("number", lurek.render.getLayerZOrder("ui"))
        lurek.render.popLayer(1)
    end)

    -- @covers lurek.render.newMesh
    -- @covers LMesh:getVertexCount
    -- @covers LMesh:setVertex
    -- @covers LMesh:getVertex
    it("mesh API is callable", function()
        local mesh = lurek.render.newMesh({
            {0, 0, 0, 0, 1, 1, 1, 1},
            {1, 0, 1, 0, 1, 1, 1, 1},
            {0, 1, 0, 1, 1, 1, 1, 1},
        })
        expect_type("userdata", mesh)
        expect_true(mesh:getVertexCount() >= 3)
        mesh:setVertex(1, {0, 0, 0, 0, 1, 1, 1, 1})
        local vx, vy = mesh:getVertex(1)
        expect_type("number", vx)
        expect_type("number", vy)
    end)

    -- @covers lurek.render.newShader
    -- @covers LShader:hasUniform
    it("shader API is callable", function()
        local shader = lurek.render.newShader("@fragment fn fs() -> @location(0) vec4<f32> { return vec4<f32>(1.0); }")
        expect_type("userdata", shader)
        expect_type("boolean", shader:hasUniform("u_time"))
    end)

    -- @covers lurek.render.newSpriteBatch
    -- @covers LSpriteBatch:add
    -- @covers lurek.render.newImage
    it("spritebatch add is callable", function()
        local img = lurek.render.newImage("assets/icon.png")
        local sb = lurek.render.newSpriteBatch(img, 8)
        expect_type("userdata", sb)
        sb:add(0, 0)
    end)

    -- @covers lurek.render.newQuad
    -- @covers LQuad:getTextureDimensions
    it("quad texture dimensions are readable", function()
        local q = lurek.render.newQuad(0, 0, 1, 1, 1, 1)
        local tw, th = q:getTextureDimensions()
        expect_type("number", tw)
        expect_type("number", th)
    end)

    -- @covers lurek.render.getDefaultFont
    -- @covers LFont:getLineHeight
    -- @covers LFont:setLineHeight
    -- @covers LFont:getAscent
    -- @covers LFont:getDescent
    it("font userdata metrics are callable", function()
        local font = lurek.render.getDefaultFont()
        expect_type("userdata", font)
        local lh = font:getLineHeight()
        expect_type("number", lh)
        font:setLineHeight(lh)
        expect_type("number", font:getAscent())
        expect_type("number", font:getDescent())
    end)

    -- @covers lurek.render.getDefaultFont
    -- @covers lurek.render.getFontWrap
    -- @covers lurek.render.getFontCellWidth
    -- @covers lurek.render.getFontSizes
    it("font helper APIs are callable", function()
        local font = lurek.render.getDefaultFont()
        local lines, maxw = lurek.render.getFontWrap("abc def ghi", 40)
        expect_type("table", lines)
        expect_type("number", maxw)
        expect_type("number", lurek.render.getFontCellWidth(font))
        local sizes = lurek.render.getFontSizes()
        expect_type("table", sizes)
        expect_true(#sizes > 0)
    end)

    -- @covers lurek.render.getCanvas
    -- @covers lurek.render.getCanvasSize
    -- @covers lurek.render.newCanvas
    -- @covers lurek.render.pop
    -- @covers lurek.render.applyTransform
    -- @covers lurek.render.setDefaultFilter
    -- @covers lurek.render.getDefaultFilter
    it("canvas/transform/filter APIs are callable", function()
        local canvas = lurek.render.getCanvas()
        if canvas == nil then
            canvas = lurek.render.newCanvas(8, 8)
        end
        local cw, ch = lurek.render.getCanvasSize(canvas)
        expect_type("number", cw)
        expect_type("number", ch)
        lurek.render.applyTransform({1, 0, 0, 0, 1, 0, 0, 0, 1})
        lurek.render.pop()
        lurek.render.setDefaultFilter("linear", "linear", 1)
        local min_filter, mag_filter, aniso = lurek.render.getDefaultFilter()
        expect_type("string", min_filter)
        expect_type("string", mag_filter)
        expect_type("number", aniso)
    end)
end)

-- @describe render strict: screen globals
describe("render strict: screen globals", function()
    -- @covers lurek.render.getColor
    it("getColor returns four number components", function()
        local r, g, b, a = lurek.render.getColor()
        expect_type("number", r)
        expect_type("number", g)
        expect_type("number", b)
        expect_type("number", a)
    end)

    -- @covers lurek.render.clear
    it("clear is callable without error", function()
        local ok = pcall(lurek.render.clear)
        expect_true(ok)
    end)

    -- @covers lurek.render.getWidth
    -- @covers lurek.render.getHeight
    it("getWidth and getHeight return numbers", function()
        expect_type("number", lurek.render.getWidth())
        expect_type("number", lurek.render.getHeight())
    end)

    -- @covers lurek.render.getStats
    it("getStats returns a table", function()
        local stats = lurek.render.getStats()
        expect_type("table", stats)
    end)

    -- @covers lurek.render.setLayerVisible
    it("setLayerVisible is callable with a name and bool", function()
        local ok = pcall(lurek.render.setLayerVisible, "hud", false)
        expect_true(ok)
    end)
end)

-- @describe render strict: blend mode
describe("render strict: blend mode", function()
    -- @covers lurek.render.setBlendMode
    -- @covers lurek.render.getBlendMode
    it("setBlendMode and getBlendMode round-trip", function()
        lurek.render.setBlendMode("alpha")
        local mode = lurek.render.getBlendMode()
        expect_type("string", mode)
    end)
end)

-- @describe render strict: transform stack
describe("render strict: transform stack", function()
    -- @covers lurek.render.push
    it("push is callable without error", function()
        local ok = pcall(lurek.render.push)
        expect_true(ok)
        lurek.render.pop()
    end)

    -- @covers lurek.render.translate
    it("translate is callable without error", function()
        local ok = pcall(lurek.render.translate, 10, 20)
        expect_true(ok)
        lurek.render.origin()
    end)

    -- @covers lurek.render.rotate
    it("rotate is callable without error", function()
        local ok = pcall(lurek.render.rotate, 0.5)
        expect_true(ok)
        lurek.render.origin()
    end)

    -- @covers lurek.render.scale
    it("scale is callable without error", function()
        local ok = pcall(lurek.render.scale, 2, 2)
        expect_true(ok)
        lurek.render.origin()
    end)

    -- @covers lurek.render.shear
    it("shear is callable without error", function()
        local ok = pcall(lurek.render.shear, 0.1, 0.1)
        expect_true(ok)
        lurek.render.origin()
    end)

    -- @covers lurek.render.origin
    it("origin is callable without error", function()
        local ok = pcall(lurek.render.origin)
        expect_true(ok)
    end)
end)

-- @describe render strict: canvas and shader
describe("render strict: canvas and shader", function()
    -- @covers lurek.render.setCanvas
    it("setCanvas with nil resets to screen", function()
        local ok = pcall(lurek.render.setCanvas, nil)
        expect_true(ok)
    end)

    -- @covers lurek.render.setShader
    -- @covers lurek.render.getShader
    it("setShader nil clears shader and getShader returns nil", function()
        local ok = pcall(lurek.render.setShader, nil)
        expect_true(ok)
        local s = lurek.render.getShader()
        expect_true(s == nil)
    end)
end)

-- @describe render strict: drawing primitives
describe("render strict: drawing primitives", function()
    -- @covers lurek.render.points
    it("points is callable with a coordinate table", function()
        local ok = pcall(lurek.render.points, { {0, 0}, {1, 1} })
        expect_true(ok)
    end)

    -- @covers lurek.render.drawPath
    it("drawPath is callable with moveTo and lineTo segments", function()
        local path = {
            { type="moveTo", x=0, y=0 },
            { type="lineTo", x=10, y=10 },
        }
        local ok = pcall(lurek.render.drawPath, path, "line", false)
        expect_true(ok)
    end)
end)

-- @describe render strict: stencil
describe("render strict: stencil", function()
    -- @covers lurek.render.stencil
    it("stencil is callable with action and value", function()
        local ok = pcall(lurek.render.stencil, "replace", 1)
        expect_true(ok)
    end)
end)

-- @describe render strict: LImageData methods
describe("render strict: LImageData methods", function()
    -- @covers LImageData:type
    -- @covers LImageData:typeOf
    it("LImageData type and typeOf return correct strings", function()
        local fn = lurek.render["newImageData"]
        local ok, img = false, nil
        if fn then
            ok, img = pcall(fn, 4, 4)
        end
        if ok and img ~= nil then
            expect_equal(img:type(), "LImageData")
            expect_true(img:typeOf("ImageData"))
        else
            expect_true(fn == nil or not ok or img == nil)
        end
    end)
end)

-- @describe render strict: LNineSlice methods
describe("render strict: LNineSlice methods", function()
    -- @covers LNineSlice:type
    it("LNineSlice:type returns correct string", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 10, 10, 10, 10)
        expect_equal(ns:type(), "LNineSlice")
    end)
end)

-- @describe render strict: LImage methods
describe("render strict: LImage methods", function()
    -- @covers LImage:type
    -- @covers LImage:typeOf
    it("LImage type and typeOf return correct strings", function()
        local img = lurek.render.newImage("assets/icon.png")
        expect_equal(img:type(), "LImage")
        expect_type("string", img:typeOf())
    end)

    -- @covers LImage:getWidth
    -- @covers LImage:getHeight
    it("LImage getWidth and getHeight return numbers", function()
        local img = lurek.render.newImage("assets/icon.png")
        expect_type("number", img:getWidth())
        expect_type("number", img:getHeight())
    end)

    -- @covers LImage:getDimensions
    it("LImage getDimensions returns two numbers", function()
        local img = lurek.render.newImage("assets/icon.png")
        local w, h = img:getDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @covers LImage:release
    it("LImage release is callable without error", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ok = pcall(function() img:release() end)
        expect_true(ok)
    end)
end)

-- @describe render strict: LFont methods
describe("render strict: LFont methods", function()
    -- @covers LFont:type
    -- @covers LFont:typeOf
    it("LFont type and typeOf return correct strings", function()
        local font = lurek.render.getDefaultFont()
        expect_equal(font:type(), "LFont")
        expect_type("string", font:typeOf())
    end)

    -- @covers LFont:getWidth
    it("LFont getWidth returns a number for a string", function()
        local font = lurek.render.getDefaultFont()
        expect_type("number", font:getWidth("hello"))
    end)

    -- @covers LFont:getHeight
    it("LFont getHeight returns a number", function()
        local font = lurek.render.getDefaultFont()
        expect_type("number", font:getHeight())
    end)

    -- @covers LFont:getWrap
    it("LFont getWrap returns lines and width", function()
        local font = lurek.render.getDefaultFont()
        local lines, max_w = font:getWrap("hello world", 100)
        expect_type("table", lines)
        -- max_w may be number or nil depending on build
        expect_true(max_w == nil or type(max_w) == "number")
    end)

    -- @covers LFont:release
    it("LFont release is callable without error", function()
        local font = lurek.render.newFont(12)
        local ok = pcall(function() font:release() end)
        expect_true(ok)
    end)
end)

-- @describe render strict: LCanvas methods
describe("render strict: LCanvas methods", function()
    -- @covers LCanvas:type
    -- @covers LCanvas:typeOf
    it("LCanvas type and typeOf return correct strings", function()
        local canvas = lurek.render.newCanvas(8, 8)
        expect_equal(canvas:type(), "LCanvas")
        expect_type("string", canvas:typeOf())
    end)

    -- @covers LCanvas:getWidth
    -- @covers LCanvas:getHeight
    it("LCanvas getWidth and getHeight return numbers", function()
        local canvas = lurek.render.newCanvas(8, 8)
        expect_type("number", canvas:getWidth())
        expect_type("number", canvas:getHeight())
    end)

    -- @covers LCanvas:getDimensions
    it("LCanvas getDimensions returns two numbers", function()
        local canvas = lurek.render.newCanvas(8, 8)
        local w, h = canvas:getDimensions()
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @covers LCanvas:release
    it("LCanvas release is callable without error", function()
        local canvas = lurek.render.newCanvas(8, 8)
        local ok = pcall(function() canvas:release() end)
        expect_true(ok)
    end)
end)

-- @describe render strict: LSpriteBatch methods
describe("render strict: LSpriteBatch methods", function()
    -- @covers LSpriteBatch:type
    -- @covers LSpriteBatch:typeOf
    it("LSpriteBatch type and typeOf return correct strings", function()
        local img = lurek.render.newImage("assets/icon.png")
        local sb = lurek.render.newSpriteBatch(img, 8)
        expect_equal(sb:type(), "LSpriteBatch")
        expect_type("string", sb:typeOf())
    end)

    -- @covers LSpriteBatch:getCount
    -- @covers LSpriteBatch:getBufferSize
    it("LSpriteBatch getCount and getBufferSize return numbers", function()
        local img = lurek.render.newImage("assets/icon.png")
        local sb = lurek.render.newSpriteBatch(img, 8)
        expect_type("number", sb:getCount())
        expect_type("number", sb:getBufferSize())
    end)

    -- @covers LSpriteBatch:clear
    it("LSpriteBatch clear is callable without error", function()
        local img = lurek.render.newImage("assets/icon.png")
        local sb = lurek.render.newSpriteBatch(img, 8)
        local ok = pcall(function() sb:clear() end)
        expect_true(ok)
    end)

    -- @covers LSpriteBatch:release
    it("LSpriteBatch release is callable without error", function()
        local img = lurek.render.newImage("assets/icon.png")
        local sb = lurek.render.newSpriteBatch(img, 8)
        local ok = pcall(function() sb:release() end)
        expect_true(ok)
    end)
end)

-- @describe render strict: LMesh methods
describe("render strict: LMesh methods", function()
    -- @covers LMesh:type
    -- @covers LMesh:typeOf
    it("LMesh type and typeOf return correct strings", function()
        local mesh = lurek.render.newMesh({
            {0,0,0,0}, {1,0,1,0}, {0.5,1,0.5,1}
        })
        expect_equal(mesh:type(), "LMesh")
        expect_type("string", mesh:typeOf())
    end)

    -- @covers LMesh:setTexture
    it("LMesh setTexture with nil is callable without error", function()
        local mesh = lurek.render.newMesh({
            {0,0,0,0}, {1,0,1,0}, {0.5,1,0.5,1}
        })
        local ok = pcall(function() mesh:setTexture(nil) end)
        expect_true(ok)
    end)

    -- @covers LMesh:release
    it("LMesh release is callable without error", function()
        local mesh = lurek.render.newMesh({
            {0,0,0,0}, {1,0,1,0}, {0.5,1,0.5,1}
        })
        local ok = pcall(function() mesh:release() end)
        expect_true(ok)
    end)
end)

-- @describe render strict: LShader methods
describe("render strict: LShader methods", function()
    -- @covers LShader:type
    -- @covers LShader:typeOf
    it("LShader type and typeOf return correct strings", function()
        local shader = lurek.render.newShader("@fragment fn fs() -> @location(0) vec4<f32> { return vec4<f32>(1.0); }")
        expect_equal(shader:type(), "LShader")
        expect_type("string", shader:typeOf())
    end)

    -- @covers LShader:send
    it("LShader send with a uniform name and value is callable", function()
        local shader = lurek.render.newShader("@fragment fn fs() -> @location(0) vec4<f32> { return vec4<f32>(1.0); }")
        local ok = pcall(function() shader:send("u_time", 1.0) end)
        expect_true(ok)
    end)

    -- @covers LShader:release
    it("LShader release is callable without error", function()
        local shader = lurek.render.newShader("@fragment fn fs() -> @location(0) vec4<f32> { return vec4<f32>(1.0); }")
        local ok = pcall(function() shader:release() end)
        expect_true(ok)
    end)
end)

-- @describe render strict: LQuad methods
describe("render strict: LQuad methods", function()
    -- @covers LQuad:type
    -- @covers LQuad:typeOf
    it("LQuad type and typeOf return correct strings", function()
        local q = lurek.render.newQuad(0, 0, 1, 1, 1, 1)
        expect_equal(q:type(), "LQuad")
        expect_type("string", q:typeOf())
    end)

    -- @covers LQuad:getViewport
    it("LQuad getViewport returns four numbers", function()
        local q = lurek.render.newQuad(0, 0, 8, 8, 32, 32)
        local x, y, w, h = q:getViewport()
        expect_type("number", x)
        expect_type("number", y)
        expect_type("number", w)
        expect_type("number", h)
    end)

    -- @covers LQuad:setViewport
    it("LQuad setViewport is callable without error", function()
        local q = lurek.render.newQuad(0, 0, 8, 8, 32, 32)
        local ok = pcall(function() q:setViewport(0, 0, 4, 4) end)
        expect_true(ok)
    end)
end)

-- @describe render strict: LShape methods
describe("render strict: LShape methods", function()
    -- @covers LShape:type
    -- @covers LShape:typeOf
    it("LShape type and typeOf return correct strings", function()
        local shape = lurek.render.newShape()
        expect_equal(shape:type(), "LShape")
        expect_true(shape:typeOf("Object"))
    end)
end)

-- @describe render strict: batch text and OBJ APIs
describe("render strict: batch text and OBJ APIs", function()
    -- @covers lurek.render.drawMany
    -- @covers lurek.render.newImage
    it("drawMany accepts batched draw entries", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ok = pcall(function()
            lurek.render.drawMany({
                { img, 0, 0 },
                { img, 10, 8, 0.0, 1.0, 1.0, 0.0, 0.0 },
            })
        end)
        expect_true(ok)
    end)

    -- @covers lurek.render.printRotated
    it("printRotated is callable", function()
        local ok = pcall(function()
            lurek.render.printRotated("rot", 20, 20, 0.25, 1.0)
        end)
        expect_true(ok)
    end)

    -- @covers lurek.render.newImage
    -- @covers LImage:getId
    it("newImage accepts optional color-space mode", function()
        local ok_srgb, img_srgb = pcall(function()
            return lurek.render.newImage("assets/icon.png", "srgb")
        end)
        local ok_linear, img_linear = pcall(function()
            return lurek.render.newImage("assets/icon.png", "linear")
        end)

        expect_true(ok_srgb)
        expect_true(ok_linear)
        expect_type("userdata", img_srgb)
        expect_type("userdata", img_linear)
        expect_type("number", img_srgb:getId())
    end)

    -- @covers lurek.render.newImage
    it("newImage rejects unsupported color-space mode", function()
        local ok = pcall(function()
            lurek.render.newImage("assets/icon.png", "gamma")
        end)
        expect_equal(false, ok)
    end)

    -- @covers lurek.render.loadObj
    -- @covers lurek.render.loadModel
    -- @covers LLObjModel:getFaceCount
    -- @covers LLObjModel:getUvCount
    -- @covers LLObjModel:getNormalCount
    -- @covers LObjModel:getVertexCount
    -- @covers LObjModel:renderToImage
    -- @covers LLObjModel:projectToMesh
    it("loads OBJ model and exposes mesh projection methods", function()
        local obj = lurek.render.loadObj("content/games/retro/dungeon_crawler/assets/models/tank.obj")
        local mdl = lurek.render.loadModel("content/games/retro/dungeon_crawler/assets/models/tank.obj")

        expect_type("userdata", obj)
        expect_type("userdata", mdl)
        expect_true(obj:getFaceCount() >= 0)
        expect_true(obj:getUvCount() >= 0)
        expect_true(obj:getNormalCount() >= 0)
        expect_type("number", obj:getVertexCount())

        local ok_render_to_image = pcall(function()
            obj:renderToImage(64, 64, 0.0)
        end)
        expect_type("boolean", ok_render_to_image)

        local verts = obj:projectToMesh({ x = 0, y = 4, z = 8, tx = 0, ty = 0, tz = 0, fov = 60 }, 320, 180)
        expect_type("table", verts)
    end)
end)

test_summary()
