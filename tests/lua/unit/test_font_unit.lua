-- Lurek2D font tests for lurek.render font functions.

describe("lurek.render font functions", function()
  -- @covers lurek.render.newFont
  -- @covers lurek.render.getFont
  -- @covers lurek.render.getFontHeight
  -- @covers lurek.render.getFontWidth
  -- @covers lurek.render.setFont
  it("newFont is a function", function()
    expect_type("function", lurek.render.newFont)
  end)

  -- @covers lurek.render.setFont
  it("setFont is a function", function()
    expect_type("function", lurek.render.setFont)
  end)

  -- @covers lurek.render.getFont
  it("getFont is a function", function()
    expect_type("function", lurek.render.getFont)
  end)

  -- @covers lurek.render.getFontWidth
  it("getFontWidth is a function", function()
    expect_type("function", lurek.render.getFontWidth)
  end)

  -- @covers lurek.render.getFontHeight
  it("getFontHeight is a function", function()
    expect_type("function", lurek.render.getFontHeight)
  end)

  -- @covers lurek.render.newFont
  it("loads a built-in bitmap font by size", function()
    local font = lurek.render.newFont(14)
    expect_type("userdata", font)
  end)

  -- @covers lurek.render.newFont
  -- @covers lurek.render.setFont
  -- @covers lurek.render.getFont
  it("setFont and getFont round-trip to a non-nil font", function()
    local font = lurek.render.newFont(14)
    lurek.render.setFont(font)
    local current = lurek.render.getFont()
    expect_type("userdata", current)
  end)

  -- @covers lurek.render.newFont
  -- @covers lurek.render.getFontWidth
  -- @covers lurek.render.getFontHeight
  it("reports positive width and height for a loaded font", function()
    local font = lurek.render.newFont(14)
    expect_true(lurek.render.getFontWidth(font, "Hello") > 0)
    expect_true(lurek.render.getFontHeight(font) > 0)
  end)

  -- @covers lurek.render.newFont
  it("newFont errors when file does not exist", function()
    expect_error(function()
      lurek.render.newFont("nonexistent_font.png")
    end)
  end)
end)



-- ================================================================
-- Merged from: test_font.lua
-- ================================================================

-- Lurek2D font tests for lurek.render font functions.

describe("lurek.render font functions", function()
  -- @covers lurek.render.newFont
  -- @covers lurek.render.getFont
  -- @covers lurek.render.getFontHeight
  -- @covers lurek.render.getFontWidth
  -- @covers lurek.render.setFont
  it("newFont is a function", function()
    expect_type("function", lurek.render.newFont)
  end)

  -- @covers lurek.render.setFont
  it("setFont is a function", function()
    expect_type("function", lurek.render.setFont)
  end)

  -- @covers lurek.render.getFont
  it("getFont is a function", function()
    expect_type("function", lurek.render.getFont)
  end)

  -- @covers lurek.render.getFontWidth
  it("getFontWidth is a function", function()
    expect_type("function", lurek.render.getFontWidth)
  end)

  -- @covers lurek.render.getFontHeight
  it("getFontHeight is a function", function()
    expect_type("function", lurek.render.getFontHeight)
  end)

  -- @covers lurek.render.newFont
  it("loads a built-in bitmap font by size", function()
    local font = lurek.render.newFont(14)
    expect_type("userdata", font)
  end)

  -- @covers lurek.render.newFont
  -- @covers lurek.render.setFont
  -- @covers lurek.render.getFont
  it("setFont and getFont round-trip to a non-nil font", function()
    local font = lurek.render.newFont(14)
    lurek.render.setFont(font)
    local current = lurek.render.getFont()
    expect_type("userdata", current)
  end)

  -- @covers lurek.render.newFont
  -- @covers lurek.render.getFontWidth
  -- @covers lurek.render.getFontHeight
  it("reports positive width and height for a loaded font", function()
    local font = lurek.render.newFont(14)
    expect_true(lurek.render.getFontWidth(font, "Hello") > 0)
    expect_true(lurek.render.getFontHeight(font) > 0)
  end)

  -- @covers lurek.render.newFont
  it("newFont errors when file does not exist", function()
    expect_error(function()
      lurek.render.newFont("nonexistent_font.png")
    end)
  end)
end)

test_summary()
