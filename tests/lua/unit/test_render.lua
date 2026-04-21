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
