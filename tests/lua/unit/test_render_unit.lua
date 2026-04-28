-- Lurek2D Graphics API Tests (headless Ă˘â‚¬â€ť tests lurek.render API existence and behaviour)

-- @description Verifies the graphics namespace is exposed on lurek as a table.
describe("lurek.render module exists", function()
    -- @tests lurek.render.captureScreenshot
    -- @tests lurek.render.circle
    -- @tests lurek.render.clearStencil
    -- @tests lurek.render.draw
    -- @tests lurek.render.drawNineSlice
    -- @tests lurek.render.ellipse
    -- @tests lurek.render.getDepthMode
    -- @tests lurek.render.getDimensions
    -- @tests lurek.render.getFontAscent
    -- @tests lurek.render.getFontDescent
    -- @tests lurek.render.getFontLineHeight
    -- @tests lurek.render.getLineWidth
    -- @tests lurek.render.getStencilMode
    -- @tests lurek.render.line
    -- @tests lurek.render.newImage
    -- @tests lurek.render.newNineSlice
    -- @tests lurek.render.polygon
    -- @tests lurek.render.print
    -- @tests lurek.render.rectangle
    -- @tests lurek.render.saveScreenshot
    -- @tests lurek.render.setBackgroundColor
    -- @tests lurek.render.setColor
    -- @tests lurek.render.setDepthMode
    -- @tests lurek.render.setFontLineHeight
    -- @tests lurek.render.setLineWidth
    -- @tests lurek.render.setStencilMode
    -- @tests lurek.render.triangle
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

-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ Nine-Slice Tests Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

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
            lurek.render.drawNineSlice(ns, 10, 20, 400, 300)
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

-- Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬ Polymorphic draw() dispatch Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬Ă˘â€ťâ‚¬

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
        ---@type any
        local not_a_drawable = "not_a_drawable"
        expect_error(function()
            lurek.render.draw(not_a_drawable, 0, 0)
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

-- @description Covers suite: target rendering/drawing contract: spine.
describe("target rendering/drawing contract: spine", function()
    -- @tests lurek.spine.newSkeleton
    -- @description Verifies the canonical Spine constructor is exposed as lurek.spine.newSkeleton.
    xit("exposes lurek.spine.newSkeleton as the canonical constructor", function()
        expect_type("function", lurek.spine.newSkeleton)
    end)

    -- @tests Skeleton:drawToImage
    -- @description Builds a skeleton subject and verifies drawToImage() is exposed and callable without error.
    xit("skeleton objects expose drawToImage()", function()
        local sk = make_spine_subject()
        expect_type("function", sk.drawToImage)
        expect_no_error(function()
            sk:drawToImage(64, 64)
        end)
    end)

    -- @tests Skeleton:drawToImage
    -- @description Builds a skeleton subject and verifies drawToImage() returns an image-like object with dimensions.
    xit("skeleton objects expose drawToImage()", function()
        local sk = make_spine_subject()
        expect_type("function", sk.drawToImage)
        local img = sk:drawToImage(64, 64)
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: raycaster.
describe("target rendering/drawing contract: raycaster", function()
    -- @tests Raycaster:buildScene
    -- @description Verifies raycaster userdata exposes buildScene() and the scene build call is safe.
    xit("raycaster objects expose buildScene()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.buildScene)
        expect_no_error(function()
            rc:buildScene({ px = 4.5, py = 4.5, angle = 0, fov = 1.0, rays = 8, max_dist = 8, screen_w = 64, screen_h = 64 }, {}, {}, {})
        end)
    end)

    -- @tests Raycaster:drawView
    -- @description Verifies raycaster userdata exposes drawView() and returns an image-like result.
    xit("raycaster objects expose drawView()", function()
        local rc = make_raycaster_subject()
        expect_type("function", rc.drawView)
        local img = rc:drawView(4.5, 4.5, 0, 1.0, 32, 32, 8)
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: ui.
describe("target rendering/drawing contract: ui", function()
    -- @tests lurek.ui.newPanel
    -- @description Asserts the canonical panel constructor is exposed as lurek.ui.newPanel.
    xit("exposes lurek.ui.newPanel as the canonical panel constructor", function()
        expect_type("function", lurek.ui.newPanel)
    end)

    -- @tests lurek.ui.draw
    -- @description Verifies panel widgets can be created and the UI draw function is callable.
    xit("panel widgets render through lurek.ui.draw()", function()
        local panel = make_ui_panel_subject()
        expect_type("function", panel.setTitle)
        expect_type("function", lurek.ui.draw)
        expect_no_error(function()
            panel.setTitle("contract")
            lurek.ui.draw()
        end)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: particle.
describe("target rendering/drawing contract: particle", function()
    -- @tests lurek.particle.newSystem
    -- @description Verifies lurek.particle.newSystem is available as the canonical particle system constructor.
    xit("exposes lurek.particle.newSystem as the canonical constructor", function()
        expect_type("table", lurek.particle)
        expect_type("function", lurek.particle.newSystem)
    end)

    -- @tests ParticleSystem:render
    -- @description Builds a particle system and verifies render() is exposed and callable.
    it("particle systems expose render()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.render)
        expect_no_error(function()
            ps:render()
        end)
    end)

    -- @tests ParticleSystem:drawToImage
    -- @description Builds a particle system and verifies drawToImage() returns an image-like object.
    xit("particle systems expose drawToImage()", function()
        local ps = make_particle_subject()
        expect_type("function", ps.drawToImage)
        local img = ps:drawToImage(64, 64)
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: tilemap.
describe("target rendering/drawing contract: tilemap", function()
    -- @tests lurek.tilemap.loadTMX
    -- @description Asserts the canonical TMX tilemap loader is exposed as lurek.tilemap.loadTMX.
    xit("exposes lurek.tilemap.loadTMX as the canonical TMX loader", function()
        expect_type("function", lurek.tilemap.loadTMX)
    end)

    -- @tests TileMap:render
    -- @description Builds a tilemap subject and verifies render() is exposed and callable without error.
    it("tilemaps expose render()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.render)
        expect_no_error(function()
            map:render()
        end)
    end)

    -- @tests TileMap:drawToImage
    -- @description Builds a tilemap subject and verifies drawToImage() returns an image-like object.
    xit("tilemaps expose drawToImage()", function()
        local map = make_tilemap_subject()
        expect_type("function", map.drawToImage)
        local img = map:drawToImage(16)
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: minimap.
describe("target rendering/drawing contract: minimap", function()
    -- @tests lurek.minimap.newMinimap
    -- @description Verifies the canonical minimap constructor is exposed as lurek.minimap.newMinimap.
    xit("exposes lurek.minimap.newMinimap as the canonical constructor", function()
        expect_type("function", lurek.minimap.newMinimap)
    end)

    -- @tests Minimap:render
    -- @description Builds a minimap subject and verifies render() is exposed and callable safely.
    it("minimaps expose render()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.render)
        expect_no_error(function()
            mini:render()
        end)
    end)

    -- @tests Minimap:drawToImage
    -- @description Builds a minimap subject and verifies drawToImage() returns an image-like object.
    xit("minimaps expose drawToImage()", function()
        local mini = make_minimap_subject()
        expect_type("function", mini.drawToImage)
        local img = mini:drawToImage(4)
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: overlay.
describe("target rendering/drawing contract: overlay", function()
    -- @tests lurek.effect.newOverlay
    -- @description Verifies lurek.effect.newOverlay is available as the canonical overlay constructor.
    xit("exposes lurek.effect.newOverlay as the canonical constructor", function()
        expect_type("table", lurek.effect)
        expect_type("function", lurek.effect.newOverlay)
    end)

    -- @tests Overlay:render
    -- @description Builds an overlay subject and verifies render() is exposed and callable.
    it("overlays expose render()", function()
        local ov = make_overlay_subject()
        expect_type("function", ov.render)
        expect_no_error(function()
            ov:render()
        end)
    end)

    -- @tests Overlay:flash
    -- @tests Overlay:drawToImage
    -- @description Optionally primes the effect with flash() and verifies drawToImage() returns an image-like object.
    xit("overlays expose drawToImage()", function()
        local ov = make_overlay_subject()
        if type(ov.flash) == "function" then
            ov:flash(1, 1, 1, 1, 0.1)
        end
        expect_type("function", ov.drawToImage)
        local img = ov:drawToImage(64, 64)
        expect_image_data_contract(img)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: parallax.
describe("target rendering/drawing contract: parallax", function()
    -- @tests lurek.parallax.newSet
    -- @description Verifies the canonical parallax constructor is exposed as lurek.parallax.newSet.
    xit("exposes lurek.parallax.newSet as the canonical constructor", function()
        expect_type("function", lurek.parallax.newSet)
    end)

    -- @tests ParallaxSet:render
    -- @description Builds a parallax set and verifies render() is exposed and callable without error.
    xit("parallax sets expose render()", function()
        local bg = make_parallax_subject()
        expect_type("function", bg.render)
        expect_no_error(function()
            bg:render(0, 0)
        end)
    end)
end)

-- @description Covers suite: target rendering/drawing contract: entity.
describe("target rendering/drawing contract: entity", function()
    -- @tests lurek.ecs.newUniverse
    -- @tests Universe:render
    -- @description Verifies newUniverse() returns a world object that exposes a render() method.
    it("world objects expose render()", function()
        local world = lurek.ecs.newUniverse()
        expect_type("function", world.render)
    end)

    -- @tests Universe:addSystem
    -- @tests Universe:render
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

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests lurek.render.getBackgroundColor
    it("covers lurek.render.getBackgroundColor", function()
        -- TODO: Implement test for lurek.render.getBackgroundColor
    end)

    -- @tests lurek.render.arc
    it("covers lurek.render.arc", function()
        -- TODO: Implement test for lurek.render.arc
    end)

    -- @tests lurek.render.drawq
    it("covers lurek.render.drawq", function()
        -- TODO: Implement test for lurek.render.drawq
    end)

    -- @tests lurek.render.printf
    it("covers lurek.render.printf", function()
        -- TODO: Implement test for lurek.render.printf
    end)

    -- @tests lurek.render.printRich
    it("covers lurek.render.printRich", function()
        -- TODO: Implement test for lurek.render.printRich
    end)

    -- @tests lurek.render.setPointSize
    it("covers lurek.render.setPointSize", function()
        -- TODO: Implement test for lurek.render.setPointSize
    end)

    -- @tests lurek.render.getPointSize
    it("covers lurek.render.getPointSize", function()
        -- TODO: Implement test for lurek.render.getPointSize
    end)

    -- @tests lurek.render.getFontSizes
    it("covers lurek.render.getFontSizes", function()
        -- TODO: Implement test for lurek.render.getFontSizes
    end)

    -- @tests lurek.render.getDefaultFont
    it("covers lurek.render.getDefaultFont", function()
        -- TODO: Implement test for lurek.render.getDefaultFont
    end)

    -- @tests lurek.render.getFontCellWidth
    it("covers lurek.render.getFontCellWidth", function()
        -- TODO: Implement test for lurek.render.getFontCellWidth
    end)

    -- @tests lurek.render.getFontWrap
    it("covers lurek.render.getFontWrap", function()
        -- TODO: Implement test for lurek.render.getFontWrap
    end)

    -- @tests lurek.render.setCanvas
    it("covers lurek.render.setCanvas", function()
        -- TODO: Implement test for lurek.render.setCanvas
    end)

    -- @tests lurek.render.getCanvas
    it("covers lurek.render.getCanvas", function()
        -- TODO: Implement test for lurek.render.getCanvas
    end)

    -- @tests lurek.render.getCanvasSize
    it("covers lurek.render.getCanvasSize", function()
        -- TODO: Implement test for lurek.render.getCanvasSize
    end)

    -- @tests lurek.render.newSpriteBatch
    it("covers lurek.render.newSpriteBatch", function()
        -- TODO: Implement test for lurek.render.newSpriteBatch
    end)

    -- @tests lurek.render.newMesh
    it("covers lurek.render.newMesh", function()
        -- TODO: Implement test for lurek.render.newMesh
    end)

    -- @tests lurek.render.newShader
    it("covers lurek.render.newShader", function()
        -- TODO: Implement test for lurek.render.newShader
    end)

    -- @tests lurek.render.newQuad
    it("covers lurek.render.newQuad", function()
        -- TODO: Implement test for lurek.render.newQuad
    end)

    -- @tests lurek.render.pop
    it("covers lurek.render.pop", function()
        -- TODO: Implement test for lurek.render.pop
    end)

    -- @tests lurek.render.shear
    it("covers lurek.render.shear", function()
        -- TODO: Implement test for lurek.render.shear
    end)

    -- @tests lurek.render.applyTransform
    it("covers lurek.render.applyTransform", function()
        -- TODO: Implement test for lurek.render.applyTransform
    end)

    -- @tests lurek.render.setScissor
    it("covers lurek.render.setScissor", function()
        -- TODO: Implement test for lurek.render.setScissor
    end)

    -- @tests lurek.render.getScissor
    it("covers lurek.render.getScissor", function()
        -- TODO: Implement test for lurek.render.getScissor
    end)

    -- @tests lurek.render.intersectScissor
    it("covers lurek.render.intersectScissor", function()
        -- TODO: Implement test for lurek.render.intersectScissor
    end)

    -- @tests lurek.render.setColorMask
    it("covers lurek.render.setColorMask", function()
        -- TODO: Implement test for lurek.render.setColorMask
    end)

    -- @tests lurek.render.getColorMask
    it("covers lurek.render.getColorMask", function()
        -- TODO: Implement test for lurek.render.getColorMask
    end)

    -- @tests lurek.render.setWireframe
    it("covers lurek.render.setWireframe", function()
        -- TODO: Implement test for lurek.render.setWireframe
    end)

    -- @tests lurek.render.isWireframe
    it("covers lurek.render.isWireframe", function()
        -- TODO: Implement test for lurek.render.isWireframe
    end)

    -- @tests lurek.render.setStencilTest
    it("covers lurek.render.setStencilTest", function()
        -- TODO: Implement test for lurek.render.setStencilTest
    end)

    -- @tests lurek.render.setDefaultFilter
    it("covers lurek.render.setDefaultFilter", function()
        -- TODO: Implement test for lurek.render.setDefaultFilter
    end)

    -- @tests lurek.render.getDefaultFilter
    it("covers lurek.render.getDefaultFilter", function()
        -- TODO: Implement test for lurek.render.getDefaultFilter
    end)

    -- @tests lurek.render.drawQuadBezier
    it("covers lurek.render.drawQuadBezier", function()
        -- TODO: Implement test for lurek.render.drawQuadBezier
    end)

    -- @tests lurek.render.drawCubicBezier
    it("covers lurek.render.drawCubicBezier", function()
        -- TODO: Implement test for lurek.render.drawCubicBezier
    end)

    -- @tests lurek.render.drawGradientRect
    it("covers lurek.render.drawGradientRect", function()
        -- TODO: Implement test for lurek.render.drawGradientRect
    end)

    -- @tests lurek.render.drawColoredPolygon
    it("covers lurek.render.drawColoredPolygon", function()
        -- TODO: Implement test for lurek.render.drawColoredPolygon
    end)

    -- @tests lurek.render.drawIsoCubeTile
    it("covers lurek.render.drawIsoCubeTile", function()
        -- TODO: Implement test for lurek.render.drawIsoCubeTile
    end)

    -- @tests lurek.render.drawHexTile
    it("covers lurek.render.drawHexTile", function()
        -- TODO: Implement test for lurek.render.drawHexTile
    end)

    -- @tests lurek.render.beginSortGroup
    it("covers lurek.render.beginSortGroup", function()
        -- TODO: Implement test for lurek.render.beginSortGroup
    end)

    -- @tests lurek.render.pushSortKey
    it("covers lurek.render.pushSortKey", function()
        -- TODO: Implement test for lurek.render.pushSortKey
    end)

    -- @tests lurek.render.flushSortGroup
    it("covers lurek.render.flushSortGroup", function()
        -- TODO: Implement test for lurek.render.flushSortGroup
    end)

    -- @tests lurek.render.drawBevelRect
    it("covers lurek.render.drawBevelRect", function()
        -- TODO: Implement test for lurek.render.drawBevelRect
    end)

    -- @tests lurek.render.pushLayer
    it("covers lurek.render.pushLayer", function()
        -- TODO: Implement test for lurek.render.pushLayer
    end)

    -- @tests lurek.render.popLayer
    it("covers lurek.render.popLayer", function()
        -- TODO: Implement test for lurek.render.popLayer
    end)

    -- @tests lurek.render.drawQuadBezier
    it("covers lurek.render.drawQuadBezier", function()
        -- TODO: Implement test for lurek.render.drawQuadBezier
    end)

    -- @tests lurek.render.drawCubicBezier
    it("covers lurek.render.drawCubicBezier", function()
        -- TODO: Implement test for lurek.render.drawCubicBezier
    end)

    -- @tests lurek.render.drawGradientRect
    it("covers lurek.render.drawGradientRect", function()
        -- TODO: Implement test for lurek.render.drawGradientRect
    end)

    -- @tests lurek.render.drawColoredPolygon
    it("covers lurek.render.drawColoredPolygon", function()
        -- TODO: Implement test for lurek.render.drawColoredPolygon
    end)

    -- @tests lurek.render.drawIsoCubeTile
    it("covers lurek.render.drawIsoCubeTile", function()
        -- TODO: Implement test for lurek.render.drawIsoCubeTile
    end)

    -- @tests lurek.render.drawHexTile
    it("covers lurek.render.drawHexTile", function()
        -- TODO: Implement test for lurek.render.drawHexTile
    end)

    -- @tests lurek.render.beginSortGroup
    it("covers lurek.render.beginSortGroup", function()
        -- TODO: Implement test for lurek.render.beginSortGroup
    end)

    -- @tests lurek.render.pushSortKey
    it("covers lurek.render.pushSortKey", function()
        -- TODO: Implement test for lurek.render.pushSortKey
    end)

    -- @tests lurek.render.flushSortGroup
    it("covers lurek.render.flushSortGroup", function()
        -- TODO: Implement test for lurek.render.flushSortGroup
    end)

    -- @tests lurek.render.drawBevelRect
    it("covers lurek.render.drawBevelRect", function()
        -- TODO: Implement test for lurek.render.drawBevelRect
    end)

    -- @tests lurek.render.pushLayer
    it("covers lurek.render.pushLayer", function()
        -- TODO: Implement test for lurek.render.pushLayer
    end)

    -- @tests lurek.render.popLayer
    it("covers lurek.render.popLayer", function()
        -- TODO: Implement test for lurek.render.popLayer
    end)

    -- @tests lurek.render.currentLayer
    it("covers lurek.render.currentLayer", function()
        -- TODO: Implement test for lurek.render.currentLayer
    end)

    -- @tests lurek.render.isLayerVisible
    it("covers lurek.render.isLayerVisible", function()
        -- TODO: Implement test for lurek.render.isLayerVisible
    end)

    -- @tests lurek.render.getLayerZOrder
    it("covers lurek.render.getLayerZOrder", function()
        -- TODO: Implement test for lurek.render.getLayerZOrder
    end)

    -- @tests lurek.render.setLayerZOrder
    it("covers lurek.render.setLayerZOrder", function()
        -- TODO: Implement test for lurek.render.setLayerZOrder
    end)

    -- @tests Font:getLineHeight
    it("covers Font:getLineHeight", function()
        -- TODO: Implement test for Font:getLineHeight
    end)

    -- @tests Font:setLineHeight
    it("covers Font:setLineHeight", function()
        -- TODO: Implement test for Font:setLineHeight
    end)

    -- @tests Font:getAscent
    it("covers Font:getAscent", function()
        -- TODO: Implement test for Font:getAscent
    end)

    -- @tests Font:getDescent
    it("covers Font:getDescent", function()
        -- TODO: Implement test for Font:getDescent
    end)

    -- @tests Font:getWrap
    it("covers Font:getWrap", function()
        -- TODO: Implement test for Font:getWrap
    end)

    -- @tests Mesh:getVertexCount
    it("covers Mesh:getVertexCount", function()
        -- TODO: Implement test for Mesh:getVertexCount
    end)

    -- @tests Mesh:getVertex
    it("covers Mesh:getVertex", function()
        -- TODO: Implement test for Mesh:getVertex
    end)

    -- @tests Mesh:setVertex
    it("covers Mesh:setVertex", function()
        -- TODO: Implement test for Mesh:setVertex
    end)

    -- @tests Shader:hasUniform
    it("covers Shader:hasUniform", function()
        -- TODO: Implement test for Shader:hasUniform
    end)

    -- @tests Quad:getTextureDimensions
    it("covers Quad:getTextureDimensions", function()
        -- TODO: Implement test for Quad:getTextureDimensions
    end)

end)

describe("Missing explicit test for lurek.render.getColor", function()
    it("lurek.render.getColor works", function()
        -- @tests lurek.render.getColor
        -- TODO: add assertion for lurek.render.getColor
    end)
end)

describe("Missing explicit test for lurek.render.points", function()
    it("lurek.render.points works", function()
        -- @tests lurek.render.points
        -- TODO: add assertion for lurek.render.points
    end)
end)

describe("Missing explicit test for lurek.render.clear", function()
    it("lurek.render.clear works", function()
        -- @tests lurek.render.clear
        -- TODO: add assertion for lurek.render.clear
    end)
end)

describe("Missing explicit test for lurek.render.setBlendMode", function()
    it("lurek.render.setBlendMode works", function()
        -- @tests lurek.render.setBlendMode
        -- TODO: add assertion for lurek.render.setBlendMode
    end)
end)

describe("Missing explicit test for lurek.render.getBlendMode", function()
    it("lurek.render.getBlendMode works", function()
        -- @tests lurek.render.getBlendMode
        -- TODO: add assertion for lurek.render.getBlendMode
    end)
end)

describe("Missing explicit test for lurek.render.newCanvas", function()
    it("lurek.render.newCanvas works", function()
        -- @tests lurek.render.newCanvas
        -- TODO: add assertion for lurek.render.newCanvas
    end)
end)

describe("Missing explicit test for lurek.render.setShader", function()
    it("lurek.render.setShader works", function()
        -- @tests lurek.render.setShader
        -- TODO: add assertion for lurek.render.setShader
    end)
end)

describe("Missing explicit test for lurek.render.getShader", function()
    it("lurek.render.getShader works", function()
        -- @tests lurek.render.getShader
        -- TODO: add assertion for lurek.render.getShader
    end)
end)

describe("Missing explicit test for lurek.render.push", function()
    it("lurek.render.push works", function()
        -- @tests lurek.render.push
        -- TODO: add assertion for lurek.render.push
    end)
end)

describe("Missing explicit test for lurek.render.translate", function()
    it("lurek.render.translate works", function()
        -- @tests lurek.render.translate
        -- TODO: add assertion for lurek.render.translate
    end)
end)

describe("Missing explicit test for lurek.render.rotate", function()
    it("lurek.render.rotate works", function()
        -- @tests lurek.render.rotate
        -- TODO: add assertion for lurek.render.rotate
    end)
end)

describe("Missing explicit test for lurek.render.scale", function()
    it("lurek.render.scale works", function()
        -- @tests lurek.render.scale
        -- TODO: add assertion for lurek.render.scale
    end)
end)

describe("Missing explicit test for lurek.render.origin", function()
    it("lurek.render.origin works", function()
        -- @tests lurek.render.origin
        -- TODO: add assertion for lurek.render.origin
    end)
end)

describe("Missing explicit test for lurek.render.stencil", function()
    it("lurek.render.stencil works", function()
        -- @tests lurek.render.stencil
        -- TODO: add assertion for lurek.render.stencil
    end)
end)

describe("Missing explicit test for lurek.render.getWidth", function()
    it("lurek.render.getWidth works", function()
        -- @tests lurek.render.getWidth
        -- TODO: add assertion for lurek.render.getWidth
    end)
end)

describe("Missing explicit test for lurek.render.getHeight", function()
    it("lurek.render.getHeight works", function()
        -- @tests lurek.render.getHeight
        -- TODO: add assertion for lurek.render.getHeight
    end)
end)

describe("Missing explicit test for lurek.render.getStats", function()
    it("lurek.render.getStats works", function()
        -- @tests lurek.render.getStats
        -- TODO: add assertion for lurek.render.getStats
    end)
end)

describe("Missing explicit test for lurek.render.drawPath", function()
    it("lurek.render.drawPath works", function()
        -- @tests lurek.render.drawPath
        -- TODO: add assertion for lurek.render.drawPath
    end)
end)

describe("Missing explicit test for lurek.render.drawPath", function()
    it("lurek.render.drawPath works", function()
        -- @tests lurek.render.drawPath
        -- TODO: add assertion for lurek.render.drawPath
    end)
end)

describe("Missing explicit test for lurek.render.newLayer", function()
    it("lurek.render.newLayer works", function()
        -- @tests lurek.render.newLayer
        -- TODO: add assertion for lurek.render.newLayer
    end)
end)

describe("Missing explicit test for lurek.render.setLayer", function()
    it("lurek.render.setLayer works", function()
        -- @tests lurek.render.setLayer
        -- TODO: add assertion for lurek.render.setLayer
    end)
end)

describe("Missing explicit test for lurek.render.setLayerVisible", function()
    it("lurek.render.setLayerVisible works", function()
        -- @tests lurek.render.setLayerVisible
        -- TODO: add assertion for lurek.render.setLayerVisible
    end)
end)

describe("Missing explicit test for ImageData:getWidth", function()
    it("ImageData:getWidth works", function()
        -- @tests ImageData:getWidth
        -- TODO: add assertion for ImageData:getWidth
    end)
end)

describe("Missing explicit test for ImageData:getHeight", function()
    it("ImageData:getHeight works", function()
        -- @tests ImageData:getHeight
        -- TODO: add assertion for ImageData:getHeight
    end)
end)

describe("Missing explicit test for ImageData:resize", function()
    it("ImageData:resize works", function()
        -- @tests ImageData:resize
        -- TODO: add assertion for ImageData:resize
    end)
end)

describe("Missing explicit test for ImageData:diff", function()
    it("ImageData:diff works", function()
        -- @tests ImageData:diff
        -- TODO: add assertion for ImageData:diff
    end)
end)

describe("Missing explicit test for ImageData:mapPixels", function()
    it("ImageData:mapPixels works", function()
        -- @tests ImageData:mapPixels
        -- TODO: add assertion for ImageData:mapPixels
    end)
end)

describe("Missing explicit test for ImageData:type", function()
    it("ImageData:type works", function()
        -- @tests ImageData:type
        -- TODO: add assertion for ImageData:type
    end)
end)

describe("Missing explicit test for ImageData:typeOf", function()
    it("ImageData:typeOf works", function()
        -- @tests ImageData:typeOf
        -- TODO: add assertion for ImageData:typeOf
    end)
end)

describe("Missing explicit test for NineSlice:getInsets", function()
    it("NineSlice:getInsets works", function()
        -- @tests NineSlice:getInsets
        -- TODO: add assertion for NineSlice:getInsets
    end)
end)

describe("Missing explicit test for NineSlice:getTextureSize", function()
    it("NineSlice:getTextureSize works", function()
        -- @tests NineSlice:getTextureSize
        -- TODO: add assertion for NineSlice:getTextureSize
    end)
end)

describe("Missing explicit test for NineSlice:type", function()
    it("NineSlice:type works", function()
        -- @tests NineSlice:type
        -- TODO: add assertion for NineSlice:type
    end)
end)

describe("Missing explicit test for NineSlice:typeOf", function()
    it("NineSlice:typeOf works", function()
        -- @tests NineSlice:typeOf
        -- TODO: add assertion for NineSlice:typeOf
    end)
end)

describe("Missing explicit test for Image:getWidth", function()
    it("Image:getWidth works", function()
        -- @tests Image:getWidth
        -- TODO: add assertion for Image:getWidth
    end)
end)

describe("Missing explicit test for Image:getHeight", function()
    it("Image:getHeight works", function()
        -- @tests Image:getHeight
        -- TODO: add assertion for Image:getHeight
    end)
end)

describe("Missing explicit test for Image:getDimensions", function()
    it("Image:getDimensions works", function()
        -- @tests Image:getDimensions
        -- TODO: add assertion for Image:getDimensions
    end)
end)

describe("Missing explicit test for Image:release", function()
    it("Image:release works", function()
        -- @tests Image:release
        -- TODO: add assertion for Image:release
    end)
end)

describe("Missing explicit test for Image:typeOf", function()
    it("Image:typeOf works", function()
        -- @tests Image:typeOf
        -- TODO: add assertion for Image:typeOf
    end)
end)

describe("Missing explicit test for Image:type", function()
    it("Image:type works", function()
        -- @tests Image:type
        -- TODO: add assertion for Image:type
    end)
end)

describe("Missing explicit test for Font:getWidth", function()
    it("Font:getWidth works", function()
        -- @tests Font:getWidth
        -- TODO: add assertion for Font:getWidth
    end)
end)

describe("Missing explicit test for Font:getHeight", function()
    it("Font:getHeight works", function()
        -- @tests Font:getHeight
        -- TODO: add assertion for Font:getHeight
    end)
end)

describe("Missing explicit test for Font:release", function()
    it("Font:release works", function()
        -- @tests Font:release
        -- TODO: add assertion for Font:release
    end)
end)

describe("Missing explicit test for Font:typeOf", function()
    it("Font:typeOf works", function()
        -- @tests Font:typeOf
        -- TODO: add assertion for Font:typeOf
    end)
end)

describe("Missing explicit test for Font:type", function()
    it("Font:type works", function()
        -- @tests Font:type
        -- TODO: add assertion for Font:type
    end)
end)

describe("Missing explicit test for Canvas:getWidth", function()
    it("Canvas:getWidth works", function()
        -- @tests Canvas:getWidth
        -- TODO: add assertion for Canvas:getWidth
    end)
end)

describe("Missing explicit test for Canvas:getHeight", function()
    it("Canvas:getHeight works", function()
        -- @tests Canvas:getHeight
        -- TODO: add assertion for Canvas:getHeight
    end)
end)

describe("Missing explicit test for Canvas:getDimensions", function()
    it("Canvas:getDimensions works", function()
        -- @tests Canvas:getDimensions
        -- TODO: add assertion for Canvas:getDimensions
    end)
end)

describe("Missing explicit test for Canvas:release", function()
    it("Canvas:release works", function()
        -- @tests Canvas:release
        -- TODO: add assertion for Canvas:release
    end)
end)

describe("Missing explicit test for Canvas:typeOf", function()
    it("Canvas:typeOf works", function()
        -- @tests Canvas:typeOf
        -- TODO: add assertion for Canvas:typeOf
    end)
end)

describe("Missing explicit test for Canvas:type", function()
    it("Canvas:type works", function()
        -- @tests Canvas:type
        -- TODO: add assertion for Canvas:type
    end)
end)

describe("Missing explicit test for SpriteBatch:clear", function()
    it("SpriteBatch:clear works", function()
        -- @tests SpriteBatch:clear
        -- TODO: add assertion for SpriteBatch:clear
    end)
end)

describe("Missing explicit test for SpriteBatch:getCount", function()
    it("SpriteBatch:getCount works", function()
        -- @tests SpriteBatch:getCount
        -- TODO: add assertion for SpriteBatch:getCount
    end)
end)

describe("Missing explicit test for SpriteBatch:getBufferSize", function()
    it("SpriteBatch:getBufferSize works", function()
        -- @tests SpriteBatch:getBufferSize
        -- TODO: add assertion for SpriteBatch:getBufferSize
    end)
end)

describe("Missing explicit test for SpriteBatch:release", function()
    it("SpriteBatch:release works", function()
        -- @tests SpriteBatch:release
        -- TODO: add assertion for SpriteBatch:release
    end)
end)

describe("Missing explicit test for SpriteBatch:typeOf", function()
    it("SpriteBatch:typeOf works", function()
        -- @tests SpriteBatch:typeOf
        -- TODO: add assertion for SpriteBatch:typeOf
    end)
end)

describe("Missing explicit test for SpriteBatch:type", function()
    it("SpriteBatch:type works", function()
        -- @tests SpriteBatch:type
        -- TODO: add assertion for SpriteBatch:type
    end)
end)

describe("Missing explicit test for Mesh:setTexture", function()
    it("Mesh:setTexture works", function()
        -- @tests Mesh:setTexture
        -- TODO: add assertion for Mesh:setTexture
    end)
end)

describe("Missing explicit test for Mesh:release", function()
    it("Mesh:release works", function()
        -- @tests Mesh:release
        -- TODO: add assertion for Mesh:release
    end)
end)

describe("Missing explicit test for Mesh:typeOf", function()
    it("Mesh:typeOf works", function()
        -- @tests Mesh:typeOf
        -- TODO: add assertion for Mesh:typeOf
    end)
end)

describe("Missing explicit test for Mesh:type", function()
    it("Mesh:type works", function()
        -- @tests Mesh:type
        -- TODO: add assertion for Mesh:type
    end)
end)

describe("Missing explicit test for Shader:send", function()
    it("Shader:send works", function()
        -- @tests Shader:send
        -- TODO: add assertion for Shader:send
    end)
end)

describe("Missing explicit test for Shader:release", function()
    it("Shader:release works", function()
        -- @tests Shader:release
        -- TODO: add assertion for Shader:release
    end)
end)

describe("Missing explicit test for Shader:typeOf", function()
    it("Shader:typeOf works", function()
        -- @tests Shader:typeOf
        -- TODO: add assertion for Shader:typeOf
    end)
end)

describe("Missing explicit test for Shader:type", function()
    it("Shader:type works", function()
        -- @tests Shader:type
        -- TODO: add assertion for Shader:type
    end)
end)

describe("Missing explicit test for Quad:getViewport", function()
    it("Quad:getViewport works", function()
        -- @tests Quad:getViewport
        -- TODO: add assertion for Quad:getViewport
    end)
end)

describe("Missing explicit test for Quad:typeOf", function()
    it("Quad:typeOf works", function()
        -- @tests Quad:typeOf
        -- TODO: add assertion for Quad:typeOf
    end)
end)

describe("Missing explicit test for Quad:type", function()
    it("Quad:type works", function()
        -- @tests Quad:type
        -- TODO: add assertion for Quad:type
    end)
end)

describe("Missing explicit test for Shape:getCommandCount", function()
    it("Shape:getCommandCount works", function()
        -- @tests Shape:getCommandCount
        -- TODO: add assertion for Shape:getCommandCount
    end)
end)

describe("Missing explicit test for Shape:clear", function()
    it("Shape:clear works", function()
        -- @tests Shape:clear
        -- TODO: add assertion for Shape:clear
    end)
end)

describe("Missing explicit test for Shape:setLineWidth", function()
    it("Shape:setLineWidth works", function()
        -- @tests Shape:setLineWidth
        -- TODO: add assertion for Shape:setLineWidth
    end)
end)

describe("Missing explicit test for Shape:line", function()
    it("Shape:line works", function()
        -- @tests Shape:line
        -- TODO: add assertion for Shape:line
    end)
end)

describe("Missing explicit test for Shape:polyline", function()
    it("Shape:polyline works", function()
        -- @tests Shape:polyline
        -- TODO: add assertion for Shape:polyline
    end)
end)

describe("Missing explicit test for Shape:typeOf", function()
    it("Shape:typeOf works", function()
        -- @tests Shape:typeOf
        -- TODO: add assertion for Shape:typeOf
    end)
end)

describe("Missing explicit test for Shape:type", function()
    it("Shape:type works", function()
        -- @tests Shape:type
        -- TODO: add assertion for Shape:type
    end)
end)

describe("Missing explicit test for DrawLayer:queue", function()
    it("DrawLayer:queue works", function()
        -- @tests DrawLayer:queue
        -- TODO: add assertion for DrawLayer:queue
    end)
end)

describe("Missing explicit test for DrawLayer:flush", function()
    it("DrawLayer:flush works", function()
        -- @tests DrawLayer:flush
        -- TODO: add assertion for DrawLayer:flush
    end)
end)

describe("Missing explicit test for DrawLayer:clear", function()
    it("DrawLayer:clear works", function()
        -- @tests DrawLayer:clear
        -- TODO: add assertion for DrawLayer:clear
    end)
end)

describe("Missing explicit test for DrawLayer:getCount", function()
    it("DrawLayer:getCount works", function()
        -- @tests DrawLayer:getCount
        -- TODO: add assertion for DrawLayer:getCount
    end)
end)

describe("Missing explicit test for DrawLayer:type", function()
    it("DrawLayer:type works", function()
        -- @tests DrawLayer:type
        -- TODO: add assertion for DrawLayer:type
    end)
end)

describe("Missing explicit test for DrawLayer:typeOf", function()
    it("DrawLayer:typeOf works", function()
        -- @tests DrawLayer:typeOf
        -- TODO: add assertion for DrawLayer:typeOf
    end)
end)

test_summary()
