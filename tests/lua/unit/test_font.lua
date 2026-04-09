-- Lurek2D Font Module Tests (headless — tests API existence and basic behaviour)

describe("lurek.font module", function()
  it("lurek.font is a table", function()
    expect_equal(type(lurek.font), "table")
  end)

  it("newRasterizer is a function", function()
    expect_type("function", lurek.font.newRasterizer)
  end)

  it("newTrueTypeRasterizer is a function", function()
    expect_type("function", lurek.font.newTrueTypeRasterizer)
  end)

  it("newBMFontRasterizer is a function", function()
    expect_type("function", lurek.font.newBMFontRasterizer)
  end)

  it("newGlyphData is a function", function()
    expect_type("function", lurek.font.newGlyphData)
  end)

  it("newBMFontRasterizer errors with a clear message", function()
    expect_error(function()
      lurek.font.newBMFontRasterizer("dummy.png", {})
    end)
  end)

  it("newRasterizer errors when file does not exist", function()
    expect_error(function()
      lurek.font.newRasterizer("nonexistent_font.ttf")
    end)
  end)

  it("newTrueTypeRasterizer errors when file does not exist", function()
    expect_error(function()
      lurek.font.newTrueTypeRasterizer("nonexistent_font.ttf", 16)
    end)
  end)
end)

test_summary()
