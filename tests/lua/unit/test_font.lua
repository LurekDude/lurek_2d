-- Lurek2D font tests for lurek.graphic font functions.
-- @covers lurek.graphic.getFont
-- @covers lurek.graphic.getFontHeight
-- @covers lurek.graphic.getFontWidth
-- @covers lurek.graphic.newFont
-- @covers lurek.graphic.setFont


describe("lurek.graphic font functions", function()
  it("newFont is a function", function()
    expect_type("function", lurek.graphic.newFont)
  end)

  it("setFont is a function", function()
    expect_type("function", lurek.graphic.setFont)
  end)

  it("getFont is a function", function()
    expect_type("function", lurek.graphic.getFont)
  end)

  it("getFontWidth is a function", function()
    expect_type("function", lurek.graphic.getFontWidth)
  end)

  it("getFontHeight is a function", function()
    expect_type("function", lurek.graphic.getFontHeight)
  end)

  it("loads a built-in bitmap font by size", function()
    local font = lurek.graphic.newFont(14)
    expect_type("userdata", font)
  end)

  it("setFont and getFont round-trip to a non-nil font", function()
    local font = lurek.graphic.newFont(14)
    lurek.graphic.setFont(font)
    local current = lurek.graphic.getFont()
    expect_type("userdata", current)
  end)

  it("reports positive width and height for a loaded font", function()
    local font = lurek.graphic.newFont(14)
    expect_true(lurek.graphic.getFontWidth(font, "Hello") > 0)
    expect_true(lurek.graphic.getFontHeight(font) > 0)
  end)

  it("newFont errors when file does not exist", function()
    expect_error(function()
      lurek.graphic.newFont("nonexistent_font.png")
    end)
  end)
end)

test_summary()
