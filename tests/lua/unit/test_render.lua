-- Lurek2D Graphics API Tests (headless â€” tests lurek.render API existence and behaviour)

-- @description Verifies the graphics namespace is exposed on lurek as a table.
describe("lurek.render module exists", function()
    -- @covers lurek.render.captureScreenshot
    -- @covers lurek.render.circle
    -- @covers lurek.render.clearStencil
    -- @covers lurek.render.draw
    -- @covers lurek.render.drawNineSlice
    -- @covers lurek.render.ellipse
    -- @covers lurek.render.getDepthMode
    -- @covers lurek.render.getDimensions
    -- @covers lurek.render.getFontAscent
    -- @covers lurek.render.getFontDescent
    -- @covers lurek.render.getFontLineHeight
    -- @covers lurek.render.getLineWidth
    -- @covers lurek.render.getStencilMode
    -- @covers lurek.render.line
    -- @covers lurek.render.newImage
    -- @covers lurek.render.newNineSlice
    -- @covers lurek.render.polygon
    -- @covers lurek.render.print
    -- @covers lurek.render.rectangle
    -- @covers lurek.render.saveScreenshot
    -- @covers lurek.render.setBackgroundColor
    -- @covers lurek.render.setColor
    -- @covers lurek.render.setDepthMode
    -- @covers lurek.render.setFontLineHeight
    -- @covers lurek.render.setLineWidth
    -- @covers lurek.render.setStencilMode
    -- @covers lurek.render.triangle
    -- @description Asserts that lurek.render has Lua type "table".
    it("lurek.render is a table", function()
        expect_type("table", lurek.render)
    end)
end)

-- @description Verifies the color APIs exist and accept the supported RGB and RGBA argument counts without errors.
describe("lurek.render color functions", function()
    -- @description Asserts that lurek.render.setColor has Lua type "function".
    it("setColor is a function", function()
        expect_type("function", lurek.render.setColor)
    end)

    -- @description Confirms setColor(1, 0, 0) executes without raising an error.
    it("setColor accepts 3 args", function()
        expect_no_error(function()
            lurek.render.setColor(1, 0, 0)
        end)
    end)

    -- @description Confirms setColor(1, 0, 0, 0.5) executes without raising an error.
    it("setColor accepts 4 args", function()
        expect_no_error(function()
            lurek.render.setColor(1, 0, 0, 0.5)
        end)
    end)

    -- @description Asserts that lurek.render.setBackgroundColor has Lua type "function".
    it("setBackgroundColor is a function", function()
        expect_type("function", lurek.render.setBackgroundColor)
    end)

    -- @description Confirms setBackgroundColor(0.1, 0.1, 0.1) executes without raising an error.
    it("setBackgroundColor accepts 3 args", function()
        expect_no_error(function()
            lurek.render.setBackgroundColor(0.1, 0.1, 0.1)
        end)
    end)
end)

-- @description Verifies the basic shape drawing APIs exist and accept representative valid arguments for filled and outlined primitives.
describe("lurek.render shape functions", function()
    -- @description Asserts that lurek.render.rectangle has Lua type "function".
    it("rectangle is a function", function()
        expect_type("function", lurek.render.rectangle)
    end)

    -- @description Confirms rectangle("fill", 10, 10, 100, 50) executes without raising an error.
    it("rectangle fill mode", function()
        expect_no_error(function()
            lurek.render.rectangle("fill", 10, 10, 100, 50)
        end)
    end)

    -- @description Confirms rectangle("line", 10, 10, 100, 50) executes without raising an error.
    it("rectangle line mode", function()
        expect_no_error(function()
            lurek.render.rectangle("line", 10, 10, 100, 50)
        end)
    end)

    -- @description Asserts that lurek.render.circle has Lua type "function".
    it("circle is a function", function()
        expect_type("function", lurek.render.circle)
    end)

    -- @description Confirms circle("fill", 50, 50, 25) executes without raising an error.
    it("circle fill mode", function()
        expect_no_error(function()
            lurek.render.circle("fill", 50, 50, 25)
        end)
    end)

    -- @description Asserts that lurek.render.line has Lua type "function".
    it("line is a function", function()
        expect_type("function", lurek.render.line)
    end)

    -- @description Confirms line(0, 0, 100, 100) executes without raising an error.
    it("line accepts 4 args", function()
        expect_no_error(function()
            lurek.render.line(0, 0, 100, 100)
        end)
    end)
end)

-- @description Verifies the text drawing API exists and accepts a string plus x and y coordinates without error.
describe("lurek.render text functions", function()
    -- @description Asserts that lurek.render.print has Lua type "function".
    it("print is a function", function()
        expect_type("function", lurek.render.print)
    end)

    -- @description Confirms print("Hello", 10, 10) executes without raising an error.
    it("print accepts text and position", function()
        expect_no_error(function()
            lurek.render.print("Hello", 10, 10)
        end)
    end)
end)

-- @description Verifies the image creation and draw entry points are present on lurek.render.
describe("lurek.render image functions", function()
    -- @description Asserts that lurek.render.newImage has Lua type "function".
    it("newImage is a function", function()
        expect_type("function", lurek.render.newImage)
    end)

    -- @description Asserts that lurek.render.draw has Lua type "function".
    it("draw is a function", function()
        expect_type("function", lurek.render.draw)
    end)
end)

-- @description Verifies advanced shape APIs exist, accept representative arguments, and report mutable line width and positive surface dimensions.
describe("lurek.render advanced shapes", function()
    -- @description Asserts that lurek.render.ellipse has Lua type "function".
    it("ellipse is a function", function()
        expect_type("function", lurek.render.ellipse)
    end)

    -- @description Confirms ellipse("fill", 100, 100, 50, 30) executes without raising an error.
    it("ellipse fill mode", function()
        expect_no_error(function()
            lurek.render.ellipse("fill", 100, 100, 50, 30)
        end)
    end)

    -- @description Asserts that lurek.render.polygon has Lua type "function".
    it("polygon is a function", function()
        expect_type("function", lurek.render.polygon)
    end)

    -- @description Confirms polygon("fill", 0, 0, 100, 0, 50, 100) executes without raising an error.
    it("polygon fill mode with vertices", function()
        expect_no_error(function()
            lurek.render.polygon("fill", 0, 0, 100, 0, 50, 100)
        end)
    end)

    -- @description Asserts that lurek.render.triangle has Lua type "function".
    it("triangle is a function", function()
        expect_type("function", lurek.render.triangle)
    end)

    -- @description Confirms triangle("fill", 0, 0, 100, 0, 50, 80) executes without raising an error.
    it("triangle fill mode", function()
        expect_no_error(function()
            lurek.render.triangle("fill", 0, 0, 100, 0, 50, 80)
        end)
    end)

    -- @description Asserts that lurek.render.setLineWidth has Lua type "function".
    it("setLineWidth is a function", function()
        expect_type("function", lurek.render.setLineWidth)
    end)

    -- @description Asserts that lurek.render.getLineWidth has Lua type "function".
    it("getLineWidth is a function", function()
        expect_type("function", lurek.render.getLineWidth)
    end)

    -- @description Sets the line width to 3.0, expects getLineWidth() to return 3.0 within tolerance, then resets it to 1.0.
    it("setLineWidth and getLineWidth roundtrip", function()
        lurek.render.setLineWidth(3.0)
        expect_near(3.0, lurek.render.getLineWidth())
        lurek.render.setLineWidth(1.0) -- reset
    end)

    -- @description Verifies getDimensions() returns numeric width and height values and that both are greater than zero.
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
-- @description Verifies the font metric getter and setter entry points are present on lurek.render.
describe("font metrics", function()
    -- @description Asserts that lurek.render.getFontLineHeight has Lua type "function".
    it("getFontLineHeight is a function", function()
        expect_type("function", lurek.render.getFontLineHeight)
    end)

    -- @description Asserts that lurek.render.setFontLineHeight has Lua type "function".
    it("setFontLineHeight is a function", function()
        expect_type("function", lurek.render.setFontLineHeight)
    end)

    -- @description Asserts that lurek.render.getFontAscent has Lua type "function".
    it("getFontAscent is a function", function()
        expect_type("function", lurek.render.getFontAscent)
    end)

    -- @description Asserts that lurek.render.getFontDescent has Lua type "function".
    it("getFontDescent is a function", function()
        expect_type("function", lurek.render.getFontDescent)
    end)
end)

-- â”€â”€ Nine-Slice Tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies nine-slice constructors, accessors, draw paths, runtime type checks, and rejection of negative inset values.
describe("lurek.render nine-slice", function()
    -- @description Asserts that lurek.render.newNineSlice has Lua type "function".
    it("newNineSlice is a function", function()
        expect_type("function", lurek.render.newNineSlice)
    end)

    -- @description Asserts that lurek.render.drawNineSlice has Lua type "function".
    it("drawNineSlice is a function", function()
        expect_type("function", lurek.render.drawNineSlice)
    end)

    -- @description Creates a NineSlice from assets/icon.png and asserts the returned object has Lua type "userdata".
    it("creates a NineSlice from an image", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 10, 10, 10, 10)
        expect_type("userdata", ns)
    end)

    -- @description Creates a NineSlice with insets 12, 8, 15, 6 and asserts getInsets() returns those four values within tolerance.
    it("NineSlice:getInsets returns correct values", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 12, 8, 15, 6)
        local t, r, b, l = ns:getInsets()
        expect_near(12, t)
        expect_near(8, r)
        expect_near(15, b)
        expect_near(6, l)
    end)

    -- @description Creates a NineSlice and asserts getTextureSize() returns positive width and height values.
    it("NineSlice:getTextureSize returns image dimensions", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        local w, h = ns:getTextureSize()
        expect_greater(w, 0, "texture width should be positive")
        expect_greater(h, 0, "texture height should be positive")
    end)

    -- @description Confirms drawNineSlice(ns, 50, 50, 300, 200) executes without raising an error for a valid NineSlice.
    it("drawNineSlice accepts NineSlice and rect", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 10, 10, 10, 10)
        expect_no_error(function()
            lurek.render.drawNineSlice(ns, 50, 50, 300, 200)
        end)
    end)

    -- @description Confirms the NineSlice userdata draw method executes without raising an error for valid coordinates and size.
    it("NineSlice:draw method works", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        expect_no_error(function()
            ns:draw(10, 20, 400, 300)
        end)
    end)

    -- @description Asserts the NineSlice userdata reports true for typeOf("NineSlice") and typeOf("Object").
    it("NineSlice:typeOf returns NineSlice", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ns = lurek.render.newNineSlice(img, 5, 5, 5, 5)
        expect_true(ns:typeOf("NineSlice"), "should be NineSlice type")
        expect_true(ns:typeOf("Object"), "should be Object type")
    end)

    -- @description Calls newNineSlice with a negative top inset and asserts the construction fails by checking pcall returns false.
    it("rejects negative border insets", function()
        local img = lurek.render.newImage("assets/icon.png")
        local ok = pcall(function()
            lurek.render.newNineSlice(img, -5, 10, 10, 10)
        end)
        expect_false(ok, "negative insets should error")
    end)
end)

-- â”€â”€ Polymorphic draw() dispatch â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies polymorphic draw() rejects invalid inputs and remains exposed as a callable function.
describe("lurek.render.draw polymorphic dispatch", function()
    -- @description Asserts draw(nil, 0, 0) raises an error containing "nil".
    it("draw() rejects nil with an error", function()
        expect_error(function()
            lurek.render.draw(nil, 0, 0)
        end, "nil")
    end)

    -- @description Asserts draw("not_a_drawable", 0, 0) raises an error containing "drawable".
    it("draw() rejects a non-drawable string with an error", function()
        expect_error(function()
            lurek.render.draw("not_a_drawable", 0, 0)
        end, "drawable")
    end)

    -- @description Asserts that lurek.render.draw has Lua type "function".
    it("draw() is a function", function()
        expect_type("function", lurek.render.draw)
    end)
end)

-- @description Verifies captureScreenshot accepts a callback and passes an ImageData userdata into that callback.
describe("lurek.render.captureScreenshot", function()
  -- @description Calls captureScreenshot with a callback under pcall and asserts the call succeeds with ok == true.
  it("accepts a callback without error", function()
    local ok, err = pcall(lurek.render.captureScreenshot, function(img)
      -- callback fires synchronously in stub mode; img is ImageData userdata
    end)
    expect_equal(ok, true)
  end)

  -- @description Captures the callback argument type and asserts captureScreenshot passes a userdata value.
  it("callback receives an ImageData userdata", function()
    local received_type = nil
    lurek.render.captureScreenshot(function(img)
      received_type = type(img)
    end)
    expect_equal(received_type, "userdata")
  end)
end)

-- @description Verifies saveScreenshot allows save-relative paths and rejects paths outside the save sandbox.
describe("lurek.render.saveScreenshot", function()
    -- @description Calls saveScreenshot("save/test_render.png") under pcall and asserts the call succeeds.
    it("accepts a save-relative path without error", function()
        local ok = pcall(lurek.render.saveScreenshot, "save/test_render.png")
        expect_equal(ok, true)
    end)

    -- @description Asserts saveScreenshot("test_render.png") raises an error mentioning the required save/ prefix.
    it("rejects paths outside save", function()
        expect_error(function()
            lurek.render.saveScreenshot("test_render.png")
        end, "save/")
    end)
end)

-- @description Verifies stencil mode state can be set, queried, reset to defaults, and rejects invalid actions while exposing all three stencil functions.
describe("lurek.render stencil mode", function()
  -- @description Sets stencil mode to replace/always/1 and asserts getStencilMode() returns exactly those three values.
  it("setStencilMode and getStencilMode round-trip correctly", function()
    lurek.render.setStencilMode("replace", "always", 1)
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "replace")
    expect_equal(compare, "always")
    expect_equal(value, 1)
  end)

  -- @description Sets a non-default stencil mode, clears it, and asserts the state resets to keep, always, and 0.
  it("clearStencil resets to keep/always/0", function()
    lurek.render.setStencilMode("invert", "equal", 5)
    lurek.render.clearStencil()
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "keep")
    expect_equal(compare, "always")
    expect_equal(value, 0)
  end)

  -- @description Calls setStencilMode("zero") with omitted compare and value and asserts getStencilMode() reports zero, always, and 0.
  it("setStencilMode defaults compare to always when omitted", function()
    lurek.render.setStencilMode("zero")
    local action, compare, value = lurek.render.getStencilMode()
    expect_equal(action, "zero")
    expect_equal(compare, "always")
    expect_equal(value, 0)
  end)

  -- @description Asserts setStencilMode("explode") raises an error for an unknown action.
  it("setStencilMode errors on unknown action", function()
    expect_error(function()
      lurek.render.setStencilMode("explode")
    end)
  end)

  -- @description Asserts that lurek.render.setStencilMode has Lua type "function".
  it("setStencilMode is a function", function()
    expect_type("function", lurek.render.setStencilMode)
  end)

  -- @description Asserts that lurek.render.getStencilMode has Lua type "function".
  it("getStencilMode is a function", function()
    expect_type("function", lurek.render.getStencilMode)
  end)

  -- @description Asserts that lurek.render.clearStencil has Lua type "function".
  it("clearStencil is a function", function()
    expect_type("function", lurek.render.clearStencil)
  end)
end)

-- @description Verifies depth mode state can be set and queried, defaults write to false when omitted, rejects invalid modes, and exposes both depth functions.
describe("lurek.render depth mode", function()
  -- @description Sets depth mode to less with write enabled and asserts getDepthMode() returns "less" and true.
  it("setDepthMode and getDepthMode round-trip correctly", function()
    lurek.render.setDepthMode("less", true)
    local mode, write = lurek.render.getDepthMode()
    expect_equal(mode, "less")
    expect_equal(write, true)
  end)

  -- @description Calls setDepthMode("always") without the write flag and asserts getDepthMode() returns "always" and false.
  it("setDepthMode write defaults to false", function()
    lurek.render.setDepthMode("always")
    local mode, write = lurek.render.getDepthMode()
    expect_equal(mode, "always")
    expect_equal(write, false)
  end)

  -- @description Asserts setDepthMode("turbo") raises an error for an unknown depth mode.
  it("setDepthMode errors on unknown mode", function()
    expect_error(function()
      lurek.render.setDepthMode("turbo")
    end)
  end)

  -- @description Asserts that lurek.render.setDepthMode has Lua type "function".
  it("setDepthMode is a function", function()
    expect_type("function", lurek.render.setDepthMode)
  end)

  -- @description Asserts that lurek.render.getDepthMode has Lua type "function".
  it("getDepthMode is a function", function()
    expect_type("function", lurek.render.getDepthMode)
  end)
end)
test_summary()

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

local function expect_image_data_contract(img)
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
        if type(lurek.spine.new) == "function" then
            local sk = try_call(lurek.spine.new, { name = "contract" })
            if sk ~= nil then
                return sk
            end
        end
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
        if type(lurek.ui.panel) == "function" then
            local panel = try_call(lurek.ui.panel, {})
            if panel ~= nil then
                return panel
            end
        end
        if type(lurek.ui.newPanel) == "function" then
            return lurek.ui.newPanel()
        end
    end
    error("No usable UI panel constructor available for contract test")
end

local function make_particle_subject()
    if lurek.particle ~= nil and type(lurek.particle.new) == "function" then
        local ps = try_call(lurek.particle.new, { max_count = 8, emit_rate = 0 })
        if ps ~= nil then
            return ps
        end
    end
    if lurek.particle ~= nil and type(lurek.particle.newSystem) == "function" then
        return lurek.particle.newSystem({ maxParticles = 8, emissionRate = 0 })
    end
    error("No usable particle constructor available for contract test")
end

local function make_tilemap_subject()
    if lurek.tilemap ~= nil then
        if type(lurek.tilemap.new) == "function" then
            local map = try_call(lurek.tilemap.new, { width = 4, height = 4, tile_width = 16, tile_height = 16 })
            if map ~= nil then
                return map
            end
        end
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
        if type(lurek.minimap.new) == "function" then
            local mini = try_call(lurek.minimap.new, {
                tile_data = {
                    1, 1, 0, 0,
                    0, 1, 1, 0,
                    0, 0, 1, 1,
                    1, 0, 0, 1,
                },
                width = 4,
                height = 4,
                pixel_size = 4,
            })
            if mini ~= nil then
                return mini
            end
        end
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
        if type(lurek.effect.new) == "function" then
            local ov = try_call(lurek.effect.new)
            if ov ~= nil then
                return ov
            end
        end
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
        if type(lurek.parallax.new) == "function" then
            local bg = try_call(lurek.parallax.new, { layers = {} })
            if bg ~= nil then
                return bg
            end
        end
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

-- @description Covers suite: target rendering/drawing contract: spine.
describe("target rendering/drawing contract: spine", function()
    -- @covers lurek.spine.load
    -- @description Verifies the canonical Spine constructor is exposed as lurek.spine.load.
    it("exposes lurek.spine.load as the canonical constructor", function()
        expect_type("function", lurek.spine.load)
    end)

    -- @covers Skeleton:render
    -- @description Builds a skeleton subject and verifies render() is exposed and callable without error.
    it("skeleton objects expose render()", function()
        local sk = make_spine_subject()
        expect_type("function", sk.render)
        expect_no_error(function()
            sk:render()
        end)
    end)

    -- @covers Skeleton:draw_to_image
    -- @description Builds a skeleton subject and verifies draw_to_image() returns an image-like object with dimensions.
    it("skeleton objects expose draw_to_image()", function()
        local sk = make_spine_subject()
        expect_type("function", sk.draw_to_image)
        local img = sk:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: raycaster.
describe("target rendering/drawing contract: raycaster", function()
    -- @covers Raycaster:render
    -- @description Verifies raycaster userdata exposes render() and the render call is safe.
    it("raycaster objects expose render()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.render)
        expect_no_error(function()
            rc:render()
        end)
    end)

    -- @covers Raycaster:draw_to_image
    -- @description Verifies raycaster userdata exposes draw_to_image() and returns an image-like result.
    it("raycaster objects expose draw_to_image()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.draw_to_image)
        local img = rc:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: ui.
describe("target rendering/drawing contract: ui", function()
    -- @covers lurek.ui.panel
    -- @description Asserts the canonical panel constructor is exposed as lurek.ui.panel.
    it("exposes lurek.ui.panel as the canonical panel constructor", function()
        expect_type("function", lurek.ui.panel)
    end)

    -- @covers Panel:render
    -- @description Verifies panel widgets expose render() directly and that rendering is callable without error.
    it("panel widgets expose render() instead of relying only on lurek.ui.draw()", function()
        local panel = make_ui_panel_subject()
        expect_type("function", panel.render)
        expect_no_error(function()
            panel:render()
        end)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: particle.
describe("target rendering/drawing contract: particle", function()
    -- @covers lurek.particle.new
    -- @description Verifies lurek.particle.new is available as the canonical particle system constructor.
    it("exposes lurek.particle.new as the canonical constructor", function()
        expect_type("table", lurek.particle)
        expect_type("function", lurek.particle.new)
    end)

    -- @covers ParticleSystem:render
    -- @description Builds a particle system and verifies render() is exposed and callable.
    it("particle systems expose render()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.render)
        expect_no_error(function()
            ps:render()
        end)
    end)

    -- @covers ParticleSystem:draw_to_image
    -- @description Builds a particle system and verifies draw_to_image() returns an image-like object.
    it("particle systems expose draw_to_image()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.draw_to_image)
        local img = ps:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: tilemap.
describe("target rendering/drawing contract: tilemap", function()
    -- @covers lurek.tilemap.load
    -- @description Asserts the canonical tilemap loader is exposed as lurek.tilemap.load.
    it("exposes lurek.tilemap.load as the canonical loader", function()
        expect_type("function", lurek.tilemap.load)
    end)

    -- @covers TileMap:render
    -- @description Builds a tilemap subject and verifies render() is exposed and callable without error.
    it("tilemaps expose render()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.render)
        expect_no_error(function()
            map:render()
        end)
    end)

    -- @covers TileMap:draw_to_image
    -- @description Builds a tilemap subject and verifies draw_to_image() returns an image-like object.
    it("tilemaps expose draw_to_image()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.draw_to_image)
        local img = map:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: minimap.
describe("target rendering/drawing contract: minimap", function()
    -- @covers lurek.minimap.new
    -- @description Verifies the canonical minimap constructor is exposed as lurek.minimap.new.
    it("exposes lurek.minimap.new as the canonical constructor", function()
        expect_type("function", lurek.minimap.new)
    end)

    -- @covers Minimap:render
    -- @description Builds a minimap subject and verifies render() is exposed and callable safely.
    it("minimaps expose render()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.render)
        expect_no_error(function()
            mini:render()
        end)
    end)

    -- @covers Minimap:draw_to_image
    -- @description Builds a minimap subject and verifies draw_to_image() returns an image-like object.
    it("minimaps expose draw_to_image()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.draw_to_image)
        local img = mini:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: overlay.
describe("target rendering/drawing contract: overlay", function()
    -- @covers lurek.effect.new
    -- @description Verifies lurek.effect.new is available as the canonical overlay constructor.
    it("exposes lurek.effect.new as the canonical constructor", function()
        expect_type("table", lurek.effect)
        expect_type("function", lurek.effect.new)
    end)

    -- @covers Overlay:render
    -- @description Builds an overlay subject and verifies render() is exposed and callable.
    it("overlays expose render()", function()
        local ov = make_overlay_subject()
        expect_type("function", ov.render)
        expect_no_error(function()
            ov:render()
        end)
    end)

    -- @covers Overlay:flash
    -- @covers Overlay:draw_to_image
    -- @description Optionally primes the overlay with flash() and verifies draw_to_image() returns an image-like object.
    it("overlays expose draw_to_image()", function()
        local ov = make_overlay_subject()
        if type(ov.flash) == "function" then
            ov:flash(1, 1, 1, 1, 0.1)
        end
        expect_type("function", ov.draw_to_image)
        local img = ov:draw_to_image()
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: parallax.
describe("target rendering/drawing contract: parallax", function()
    -- @covers lurek.parallax.new
    -- @description Verifies the canonical parallax constructor is exposed as lurek.parallax.new.
    it("exposes lurek.parallax.new as the canonical constructor", function()
        expect_type("function", lurek.parallax.new)
    end)

    -- @covers ParallaxSet:render
    -- @description Builds a parallax set and verifies render() is exposed and callable without error.
    it("parallax sets expose render()", function()
        local bg = make_parallax_subject()
        expect_type("function", bg.render)
        expect_no_error(function()
            bg:render()
        end)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: entity.
describe("target rendering/drawing contract: entity", function()
    -- @covers lurek.ecs.newUniverse
    -- @covers Universe:render
    -- @description Verifies newUniverse() returns a world object that exposes a render() method.
    it("world objects expose render()", function()
        local world = lurek.ecs.newUniverse()
        expect_type("function", world.render)
    end)

    -- @covers Universe:addSystem
    -- @covers Universe:render
    -- @description Verifies world:render() dispatches system render() callbacks and does not fall back to draw().
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

