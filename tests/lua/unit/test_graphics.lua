-- Lurek2D Graphics API Tests (headless — tests lurek.graphic API existence and behaviour)
-- @covers lurek.graphic.captureScreenshot
-- @covers lurek.graphic.circle
-- @covers lurek.graphic.clearStencil
-- @covers lurek.graphic.draw
-- @covers lurek.graphic.drawNineSlice
-- @covers lurek.graphic.ellipse
-- @covers lurek.graphic.getDepthMode
-- @covers lurek.graphic.getDimensions
-- @covers lurek.graphic.getFontAscent
-- @covers lurek.graphic.getFontDescent
-- @covers lurek.graphic.getFontLineHeight
-- @covers lurek.graphic.getLineWidth
-- @covers lurek.graphic.getStencilMode
-- @covers lurek.graphic.line
-- @covers lurek.graphic.newImage
-- @covers lurek.graphic.newNineSlice
-- @covers lurek.graphic.polygon
-- @covers lurek.graphic.print
-- @covers lurek.graphic.rectangle
-- @covers lurek.graphic.saveScreenshot
-- @covers lurek.graphic.setBackgroundColor
-- @covers lurek.graphic.setColor
-- @covers lurek.graphic.setDepthMode
-- @covers lurek.graphic.setFontLineHeight
-- @covers lurek.graphic.setLineWidth
-- @covers lurek.graphic.setStencilMode
-- @covers lurek.graphic.triangle


describe("lurek.graphic module exists", function()
    it("lurek.graphic is a table", function()
        expect_type("table", lurek.graphic)
    end)
end)

describe("lurek.graphic color functions", function()
    it("setColor is a function", function()
        expect_type("function", lurek.graphic.setColor)
    end)

    it("setColor accepts 3 args", function()
        expect_no_error(function()
            lurek.graphic.setColor(1, 0, 0)
        end)
    end)

    it("setColor accepts 4 args", function()
        expect_no_error(function()
            lurek.graphic.setColor(1, 0, 0, 0.5)
        end)
    end)

    it("setBackgroundColor is a function", function()
        expect_type("function", lurek.graphic.setBackgroundColor)
    end)

    it("setBackgroundColor accepts 3 args", function()
        expect_no_error(function()
            lurek.graphic.setBackgroundColor(0.1, 0.1, 0.1)
        end)
    end)
end)

describe("lurek.graphic shape functions", function()
    it("rectangle is a function", function()
        expect_type("function", lurek.graphic.rectangle)
    end)

    it("rectangle fill mode", function()
        expect_no_error(function()
            lurek.graphic.rectangle("fill", 10, 10, 100, 50)
        end)
    end)

    it("rectangle line mode", function()
        expect_no_error(function()
            lurek.graphic.rectangle("line", 10, 10, 100, 50)
        end)
    end)

    it("circle is a function", function()
        expect_type("function", lurek.graphic.circle)
    end)

    it("circle fill mode", function()
        expect_no_error(function()
            lurek.graphic.circle("fill", 50, 50, 25)
        end)
    end)

    it("line is a function", function()
        expect_type("function", lurek.graphic.line)
    end)

    it("line accepts 4 args", function()
        expect_no_error(function()
            lurek.graphic.line(0, 0, 100, 100)
        end)
    end)
end)

describe("lurek.graphic text functions", function()
    it("print is a function", function()
        expect_type("function", lurek.graphic.print)
    end)

    it("print accepts text and position", function()
        expect_no_error(function()
            lurek.graphic.print("Hello", 10, 10)
        end)
    end)
end)

describe("lurek.graphic image functions", function()
    it("newImage is a function", function()
        expect_type("function", lurek.graphic.newImage)
    end)

    it("draw is a function", function()
        expect_type("function", lurek.graphic.draw)
    end)
end)

describe("lurek.graphic advanced shapes", function()
    it("ellipse is a function", function()
        expect_type("function", lurek.graphic.ellipse)
    end)

    it("ellipse fill mode", function()
        expect_no_error(function()
            lurek.graphic.ellipse("fill", 100, 100, 50, 30)
        end)
    end)

    it("polygon is a function", function()
        expect_type("function", lurek.graphic.polygon)
    end)

    it("polygon fill mode with vertices", function()
        expect_no_error(function()
            lurek.graphic.polygon("fill", 0, 0, 100, 0, 50, 100)
        end)
    end)

    it("triangle is a function", function()
        expect_type("function", lurek.graphic.triangle)
    end)

    it("triangle fill mode", function()
        expect_no_error(function()
            lurek.graphic.triangle("fill", 0, 0, 100, 0, 50, 80)
        end)
    end)

    it("setLineWidth is a function", function()
        expect_type("function", lurek.graphic.setLineWidth)
    end)

    it("getLineWidth is a function", function()
        expect_type("function", lurek.graphic.getLineWidth)
    end)

    it("setLineWidth and getLineWidth roundtrip", function()
        lurek.graphic.setLineWidth(3.0)
        expect_near(3.0, lurek.graphic.getLineWidth())
        lurek.graphic.setLineWidth(1.0) -- reset
    end)

    it("getDimensions returns two numbers", function()
        local w, h = lurek.graphic.getDimensions()
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
        expect_type("function", lurek.graphic.getFontLineHeight)
    end)

    it("setFontLineHeight is a function", function()
        expect_type("function", lurek.graphic.setFontLineHeight)
    end)

    it("getFontAscent is a function", function()
        expect_type("function", lurek.graphic.getFontAscent)
    end)

    it("getFontDescent is a function", function()
        expect_type("function", lurek.graphic.getFontDescent)
    end)
end)

-- ── Nine-Slice Tests ────────────────────────────────────────────────────

describe("lurek.graphic nine-slice", function()
    it("newNineSlice is a function", function()
        expect_type("function", lurek.graphic.newNineSlice)
    end)

    it("drawNineSlice is a function", function()
        expect_type("function", lurek.graphic.drawNineSlice)
    end)

    it("creates a NineSlice from an image", function()
        local img = lurek.graphic.newImage("assets/icon.png")
        local ns = lurek.graphic.newNineSlice(img, 10, 10, 10, 10)
        expect_type("userdata", ns)
    end)

    it("NineSlice:getInsets returns correct values", function()
        local img = lurek.graphic.newImage("assets/icon.png")
        local ns = lurek.graphic.newNineSlice(img, 12, 8, 15, 6)
        local t, r, b, l = ns:getInsets()
        expect_near(12, t)
        expect_near(8, r)
        expect_near(15, b)
        expect_near(6, l)
    end)

    it("NineSlice:getTextureSize returns image dimensions", function()
        local img = lurek.graphic.newImage("assets/icon.png")
        local ns = lurek.graphic.newNineSlice(img, 5, 5, 5, 5)
        local w, h = ns:getTextureSize()
        assert(w > 0, "texture width should be positive")
        assert(h > 0, "texture height should be positive")
    end)

    it("drawNineSlice accepts NineSlice and rect", function()
        local img = lurek.graphic.newImage("assets/icon.png")
        local ns = lurek.graphic.newNineSlice(img, 10, 10, 10, 10)
        expect_no_error(function()
            lurek.graphic.drawNineSlice(ns, 50, 50, 300, 200)
        end)
    end)

    it("NineSlice:draw method works", function()
        local img = lurek.graphic.newImage("assets/icon.png")
        local ns = lurek.graphic.newNineSlice(img, 5, 5, 5, 5)
        expect_no_error(function()
            ns:draw(10, 20, 400, 300)
        end)
    end)

    it("NineSlice:typeOf returns NineSlice", function()
        local img = lurek.graphic.newImage("assets/icon.png")
        local ns = lurek.graphic.newNineSlice(img, 5, 5, 5, 5)
        assert(ns:typeOf("NineSlice"), "should be NineSlice type")
        assert(ns:typeOf("Object"), "should be Object type")
    end)

    it("rejects negative border insets", function()
        local img = lurek.graphic.newImage("assets/icon.png")
        local ok = pcall(function()
            lurek.graphic.newNineSlice(img, -5, 10, 10, 10)
        end)
        assert(not ok, "negative insets should error")
    end)
end)

-- ── Polymorphic draw() dispatch ─────────────────────────────────────────

describe("lurek.graphic.draw polymorphic dispatch", function()
    it("draw() rejects nil with an error", function()
        expect_error(function()
            lurek.graphic.draw(nil, 0, 0)
        end, "nil")
    end)

    it("draw() rejects a non-drawable string with an error", function()
        expect_error(function()
            lurek.graphic.draw("not_a_drawable", 0, 0)
        end, "drawable")
    end)

    it("draw() is a function", function()
        expect_type("function", lurek.graphic.draw)
    end)
end)

describe("lurek.graphic.captureScreenshot", function()
  it("accepts a callback without error", function()
    local ok, err = pcall(lurek.graphic.captureScreenshot, function(img)
      -- callback fires synchronously in stub mode; img is ImageData userdata
    end)
    expect_equal(ok, true)
  end)

  it("callback receives an ImageData userdata", function()
    local received_type = nil
    lurek.graphic.captureScreenshot(function(img)
      received_type = type(img)
    end)
    expect_equal(received_type, "userdata")
  end)
end)

describe("lurek.graphic.saveScreenshot", function()
    it("accepts a save-relative path without error", function()
        local ok = pcall(lurek.graphic.saveScreenshot, "save/test_graphics.png")
        expect_equal(ok, true)
    end)

    it("rejects paths outside save", function()
        expect_error(function()
            lurek.graphic.saveScreenshot("test_graphics.png")
        end, "save/")
    end)
end)

describe("lurek.graphic stencil mode", function()
  it("setStencilMode and getStencilMode round-trip correctly", function()
    lurek.graphic.setStencilMode("replace", "always", 1)
    local action, compare, value = lurek.graphic.getStencilMode()
    expect_equal(action, "replace")
    expect_equal(compare, "always")
    expect_equal(value, 1)
  end)

  it("clearStencil resets to keep/always/0", function()
    lurek.graphic.setStencilMode("invert", "equal", 5)
    lurek.graphic.clearStencil()
    local action, compare, value = lurek.graphic.getStencilMode()
    expect_equal(action, "keep")
    expect_equal(compare, "always")
    expect_equal(value, 0)
  end)

  it("setStencilMode defaults compare to always when omitted", function()
    lurek.graphic.setStencilMode("zero")
    local action, compare, value = lurek.graphic.getStencilMode()
    expect_equal(action, "zero")
    expect_equal(compare, "always")
    expect_equal(value, 0)
  end)

  it("setStencilMode errors on unknown action", function()
    expect_error(function()
      lurek.graphic.setStencilMode("explode")
    end)
  end)

  it("setStencilMode is a function", function()
    expect_type("function", lurek.graphic.setStencilMode)
  end)

  it("getStencilMode is a function", function()
    expect_type("function", lurek.graphic.getStencilMode)
  end)

  it("clearStencil is a function", function()
    expect_type("function", lurek.graphic.clearStencil)
  end)
end)

describe("lurek.graphic depth mode", function()
  it("setDepthMode and getDepthMode round-trip correctly", function()
    lurek.graphic.setDepthMode("less", true)
    local mode, write = lurek.graphic.getDepthMode()
    expect_equal(mode, "less")
    expect_equal(write, true)
  end)

  it("setDepthMode write defaults to false", function()
    lurek.graphic.setDepthMode("always")
    local mode, write = lurek.graphic.getDepthMode()
    expect_equal(mode, "always")
    expect_equal(write, false)
  end)

  it("setDepthMode errors on unknown mode", function()
    expect_error(function()
      lurek.graphic.setDepthMode("turbo")
    end)
  end)

  it("setDepthMode is a function", function()
    expect_type("function", lurek.graphic.setDepthMode)
  end)

  it("getDepthMode is a function", function()
    expect_type("function", lurek.graphic.getDepthMode)
  end)
end)

test_summary()
