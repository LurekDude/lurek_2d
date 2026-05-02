-- Lurek2D font tests for lurek.render font functions.

describe("lurek.render font functions", function()
  it("newFont is a function", function()
    expect_type("function", lurek.render.newFont)
  end)

  it("setFont is a function", function()
    expect_type("function", lurek.render.setFont)
  end)

  it("getFont is a function", function()
    expect_type("function", lurek.render.getFont)
  end)

  it("getFontWidth is a function", function()
    expect_type("function", lurek.render.getFontWidth)
  end)

  it("getFontHeight is a function", function()
    expect_type("function", lurek.render.getFontHeight)
  end)

  it("loads a built-in bitmap font by size", function()
    local font = lurek.render.newFont(14)
    expect_type("userdata", font)
  end)

  it("setFont and getFont round-trip to a non-nil font", function()
    local font = lurek.render.newFont(14)
    lurek.render.setFont(font)
    local current = lurek.render.getFont()
    expect_type("userdata", current)
  end)

  it("reports positive width and height for a loaded font", function()
    local font = lurek.render.newFont(14)
    expect_true(lurek.render.getFontWidth(font, "Hello") > 0)
    expect_true(lurek.render.getFontHeight(font) > 0)
  end)

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
  it("newFont is a function", function()
    expect_type("function", lurek.render.newFont)
  end)

  it("setFont is a function", function()
    expect_type("function", lurek.render.setFont)
  end)

  it("getFont is a function", function()
    expect_type("function", lurek.render.getFont)
  end)

  it("getFontWidth is a function", function()
    expect_type("function", lurek.render.getFontWidth)
  end)

  it("getFontHeight is a function", function()
    expect_type("function", lurek.render.getFontHeight)
  end)

  it("loads a built-in bitmap font by size", function()
    local font = lurek.render.newFont(14)
    expect_type("userdata", font)
  end)

  it("setFont and getFont round-trip to a non-nil font", function()
    local font = lurek.render.newFont(14)
    lurek.render.setFont(font)
    local current = lurek.render.getFont()
    expect_type("userdata", current)
  end)

  it("reports positive width and height for a loaded font", function()
    local font = lurek.render.newFont(14)
    expect_true(lurek.render.getFontWidth(font, "Hello") > 0)
    expect_true(lurek.render.getFontHeight(font) > 0)
  end)

  it("newFont errors when file does not exist", function()
    expect_error(function()
      lurek.render.newFont("nonexistent_font.png")
    end)
  end)
end)
test_summary()
