-- Lurek2D Graphics API Tests (headless  tests lurek.render API existence and behaviour)

describe("lurek.render module exists", function()
    it("lurek.render is a table", function()
        expect_type("table", lurek.render)
    end)
end)

describe("lurek.render color functions", function()
    it("setColor is a function", function()
        expect_type("function", lurek.render.setColor)
    end)

    it("setColor accepts 3 args", function()
        expect_no_error(function()
            lurek.render.setColor(1, 0, 0)
        end)
    end)

    it("setColor accepts 4 args", function()
        expect_no_error(function()
            lurek.render.setColor(1, 0, 0, 0.5)
        end)
    end)

    it("setBackgroundColor is a function", function()
        expect_type("function", lurek.render.setBackgroundColor)
    end)

    it("setBackgroundColor accepts 3 args", function()
        expect_no_error(function()
            lurek.render.setBackgroundColor(0.1, 0.1, 0.1)
        end)
    end)
end)

describe("lurek.render shape functions", function()
    it("rectangle is a function", function()
        expect_type("function", lurek.render.rectangle)
    end)

    it("rectangle fill mode", function()
        expect_no_error(function()
            lurek.render.rectangle("fill", 10, 10, 100, 50)
        end)
    end)

    it("rectangle line mode", function()
        expect_no_error(function()
            lurek.render.rectangle("line", 10, 10, 100, 50)
        end)
    end)

    it("circle is a function", function()
        expect_type("function", lurek.render.circle)
    end)

    it("circle fill mode", function()
        expect_no_error(function()
            lurek.render.circle("fill", 50, 50, 25)
        end)
    end)

    it("line is a function", function()
        expect_type("function", lurek.render.line)
    end)

    it("line accepts 4 args", function()
        expect_no_error(function()
            lurek.render.line(0, 0, 100, 100)
        end)
    end)
end)

describe("lurek.render text functions", function()
    it("print is a function", function()
        expect_type("function", lurek.render.print)
    end)

    it("print accepts text and position", function()
        expect_no_error(function()
            lurek.render.print("Hello", 10, 10)
        end)
    end)
end)

describe("lurek.render image functions", function()
    it("newImage is a function", function()
        expect_type("function", lurek.render.newImage)
    end)

    it("draw is a function", function()
        expect_type("function", lurek.render.draw)
    end)
end)

describe("lurek.render advanced shapes", function()
    it("ellipse is a function", function()
        expect_type("function", lurek.render.ellipse)
    end)

    it("ellipse fill mode", function()
        expect_no_error(function()
            lurek.render.ellipse("fill", 100, 100, 50, 30)
        end)
    end)

    it("polygon is a function", function()
        expect_type("function", lurek.render.polygon)
    end)

    it("polygon fill mode with vertices", function()
        expect_no_error(function()
            lurek.render.polygon("fill", 0, 0, 100, 0, 50, 100)
        end)
    end)

    it("triangle is a function", function()
        expect_type("function", lurek.render.triangle)
    end)

    it("triangle fill mode", function()
        expect_no_error(function()
            lurek.render.triangle("fill", 0, 0, 100, 0, 50, 80)
        end)
    end)

    it("setLineWidth is a function", function()
        expect_type("function", lurek.render.setLineWidth)
    end)

    it("getLineWidth is a function", function()
        expect_type("function", lurek.render.getLineWidth)
    end)

    it("setLineWidth and getLineWidth roundtrip", function()
        lurek.render.setLineWidth(3.0)
        expect_near(3.0, lurek.render.getLineWidth())
        lurek.render.setLineWidth(1.0) -- reset
    end)

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
describe("font metrics", function()
    it("getFontLineHeight is a function", function()
        expect_type("function", lurek.render.getFontLineHeight)
    end)

    it("setFontLineHeight is a function", function()
        expect_type("function", lurek.render.setFontLineHeight)
    end)

    it("getFontAscent is a function", function()
        expect_type("function", lurek.render.getFontAscent)
    end)

    it("getFontDescent is a function", function()
        expect_type("function", lurek.render.getFontDescent)
    end)
end)

-- Nine-Slice Tests

describe("lurek.render nine-slice", function()
    it("newNineSlice is a function", function()
        expect_type("function", lurek.render.newNineSlice)
    end)

    it("drawNineSlice is a function", function()
        expect_type("function", lurek.render.drawNineSlice)
    end)

    it("creates a NineSlice from an image", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 10, 10, 10, 10)
        expect_type("userdata", ns)
    end)

    it("NineSlice:getInsets returns correct values", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 12, 8, 15, 6)
        local t, r, b, l = ns:getInsets()
        expect_near(12, t)
        expect_near(8, r)
        expect_near(15, b)
        expect_near(6, l)
    end)

    it("NineSlice:getTextureSize returns image dimensions", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        local w, h = ns:getTextureSize()
        expect_greater(w, 0, "texture width should be positive")
        expect_greater(h, 0, "texture height should be positive")
    end)

    it("drawNineSlice accepts NineSlice and rect", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 10, 10, 10, 10)
        expect_no_error(function()
            lurek.render.drawNineSlice(ns, 50, 50, 300, 200)
        end)
    end)

    it("NineSlice:draw method works", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        expect_no_error(function()
            lurek.render.drawNineSlice(ns, 10, 20, 400, 300)
        end)
    end)

    it("NineSlice:typeOf returns NineSlice", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        expect_true(ns:typeOf("NineSlice"), "should be NineSlice type")
        expect_true(ns:typeOf("Object"), "should be Object type")
    end)

    it("rejects negative border insets", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ok = pcall(function()
            lurek.render.newNineSlice(img, -5, 10, 10, 10)
        end)
        expect_false(ok, "negative insets should error")
    end)
end)

-- Polymorphic draw() dispatch

describe("lurek.render.draw polymorphic dispatch", function()
    it("draw() rejects nil with an error", function()
        expect_error(function()
            lurek.render.draw(nil, 0, 0)
        end, "nil")
    end)

    it("draw() rejects a non-drawable string with an error", function()
        ---@type any
        local not_a_drawable = "not_a_drawable"
        expect_error(function()
            lurek.render.draw(not_a_drawable, 0, 0)
        end, "drawable")
    end)

    it("draw() is a function", function()
        expect_type("function", lurek.render.draw)
    end)
end)

describe("lurek.render.captureScreenshot", function()
  it("accepts a callback without error", function()
    local ok, err = pcall(lurek.render.captureScreenshot, function(img)
    end)
    expect_equal(ok, true)
  end)

  it("callback receives an ImageData userdata", function()
    local received_type = nil
    lurek.render.captureScreenshot(function(img)
      received_type = type(img)
    end)
    expect_equal(received_type, "userdata")
  end)
end)

describe("lurek.render.saveScreenshot", function()
    it("accepts a save-relative path without error", function()
        local ok = pcall(lurek.render.saveScreenshot, "save/test_render.png")
        expect_equal(ok, true)
    end)

    it("rejects paths outside save", function()
        expect_error(function()
            lurek.render.saveScreenshot("test_render.png")
        end, "save/")
    end)
end)

describe("lurek.render stencil mode", function()
  it("setStencilMode and getStencilMode round-trip correctly", function()
    lurek.render.setStencilMode("replace", "always", 1)
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "replace")
    expect_equal(compare, "always")
    expect_equal(value, 1)
  end)

  it("clearStencil resets to keep/always/0", function()
    lurek.render.setStencilMode("invert", "equal", 5)
    lurek.render.clearStencil()
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "keep")
    expect_equal(compare, "always")
    expect_equal(value, 0)
  end)

  it("setStencilMode defaults compare to always when omitted", function()
    lurek.render.setStencilMode("zero")
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "zero")
    expect_equal(compare, "always")
    expect_equal(value, 0)
  end)

  it("setStencilMode errors on unknown action", function()
    expect_error(function()
      lurek.render.setStencilMode("explode")
    end)
  end)

  it("setStencilMode is a function", function()
    expect_type("function", lurek.render.setStencilMode)
  end)

  it("getStencilMode is a function", function()
    expect_type("function", lurek.render.getStencilMode)
  end)

  it("clearStencil is a function", function()
    expect_type("function", lurek.render.clearStencil)
  end)
end)

describe("lurek.render depth mode", function()
  it("setDepthMode and getDepthMode round-trip correctly", function()
    lurek.render.setDepthMode("less", true)
    local mode, write = lurek.render.getDepthMode()
    expect_equal(mode, "less")
    expect_equal(write, true)
  end)

  it("setDepthMode write defaults to false", function()
    lurek.render.setDepthMode("always")
    local mode, write = lurek.render.getDepthMode()
    expect_equal(mode, "always")
    expect_equal(write, false)
  end)

  it("setDepthMode errors on unknown mode", function()
    expect_error(function()
      lurek.render.setDepthMode("turbo")
    end)
  end)

  it("setDepthMode is a function", function()
    expect_type("function", lurek.render.setDepthMode)
  end)

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

describe("target rendering/drawing contract: spine", function()
    it("exposes lurek.spine.newSkeleton as the canonical constructor", function()
        expect_type("function", lurek.spine.newSkeleton)
    end)

    it("skeleton objects expose drawToImage()", function()
        local sk = make_spine_subject()
        expect_type("function", sk.drawToImage)
        expect_no_error(function()
            sk:drawToImage(64, 64)
        end)
    end)

    it("skeleton objects expose drawToImage()", function()
        local sk = make_spine_subject()
        expect_type("function", sk.drawToImage)
        local img = sk:drawToImage(64, 64)
        verify_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: raycaster", function()
    it("raycaster objects expose buildScene()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.buildScene)
        expect_no_error(function()
            rc:buildScene({ px = 4.5, py = 4.5, angle = 0, fov = 1.0, rays = 8, max_dist = 8, screen_w = 64, screen_h = 64 }, {}, {}, {})
        end)
    end)

    it("raycaster objects expose drawView()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.drawView)
        local img = rc:drawView(4.5, 4.5, 0, 1.0, 32, 32, 8)
        verify_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: ui", function()
    it("exposes lurek.ui.newPanel as the canonical panel constructor", function()
        expect_type("function", lurek.ui.newPanel)
    end)

    it("panel widgets render through lurek.ui.draw()", function()
        local panel = make_ui_panel_subject()
        expect_type("function", panel.setTitle)
        expect_type("function", lurek.ui.draw)
        expect_no_error(function()
            panel.setTitle("contract")
            lurek.ui.draw()
        end)
    end)
end)

describe("target rendering/drawing contract: particle", function()
    it("exposes lurek.particle.newSystem as the canonical constructor", function()
        expect_type("table", lurek.particle)
        expect_type("function", lurek.particle.newSystem)
    end)

    it("particle systems expose render()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.render)
        expect_no_error(function()
            ps:render()
        end)
    end)

    it("particle systems expose drawToImage()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.drawToImage)
        local img = ps:drawToImage(64, 64)
        verify_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: tilemap", function()
    it("exposes lurek.tilemap.loadTMX as the canonical TMX loader", function()
        expect_type("function", lurek.tilemap.loadTMX)
    end)

    it("tilemaps expose render()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.render)
        expect_no_error(function()
            map:render()
        end)
    end)

    it("tilemaps expose drawToImage()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.drawToImage)
        local img = map:drawToImage(16)
        verify_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: minimap", function()
    it("exposes lurek.minimap.newMinimap as the canonical constructor", function()
        expect_type("function", lurek.minimap.newMinimap)
    end)

    it("minimaps expose render()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.render)
        expect_no_error(function()
            mini:render()
        end)
    end)

    it("minimaps expose drawToImage()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.drawToImage)
        local img = mini:drawToImage(4)
        verify_image_data_contract(img)
    end)
end)

describe("target rendering/drawing contract: overlay", function()
    it("exposes lurek.effect.newOverlay as the canonical constructor", function()
        expect_type("table", lurek.effect)
        expect_type("function", lurek.effect.newOverlay)
    end)

    it("overlays expose render()", function()
        local ov = make_overlay_subject()
        expect_type("function", ov.render)
        expect_no_error(function()
            ov:render()
        end)
    end)

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

describe("target rendering/drawing contract: parallax", function()
    it("exposes lurek.parallax.newSet as the canonical constructor", function()
        expect_type("function", lurek.parallax.newSet)
    end)

    it("parallax sets expose render()", function()
        local bg = make_parallax_subject()
        expect_type("function", bg.render)
        expect_no_error(function()
            bg:render(0, 0)
        end)
    end)
end)

describe("target rendering/drawing contract: entity", function()
    it("world objects expose render()", function()
        local world = lurek.ecs.newUniverse()
        expect_type("function", world.render)
    end)

    it("world:render() dispatches render() and not draw() on systems", function()
        local world = lurek.ecs.newUniverse()
        local render_count = 0
        local draw_count = 0

        local sys = {}
        function sys:render(_world)
            render_count = render_count + 1
        end

        function sys:draw(_world)
            draw_count = draw_count + 1
        end

        world:addSystem(sys)
        world:render()

        expect_equal(1, render_count)
        expect_equal(0, draw_count)
    end)
end)
test_summary()
