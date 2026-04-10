-- tests/lua/unit/test_fx.lua
-- Focused smoke tests for the lurek.effect stack API.
-- Complements test_postfx.lua which provides comprehensive coverage.
-- Headless-safe (no GPU/window needed).
-- @covers lurek.effect.getEffectTypes
-- @covers lurek.effect.newPass
-- @covers lurek.effect.newStack


describe("fx module API surface", function()
  it("getEffectTypes returns a table", function()
    local types = lurek.effect.getEffectTypes()
    expect_equal(type(types), "table")
  end)

  it("getEffectTypes contains at least one entry", function()
    local types = lurek.effect.getEffectTypes()
    local count = 0
    for _ in pairs(types) do count = count + 1 end
    expect_equal(count > 0, true)
  end)
end)

describe("fx postfx stack", function()
  it("newStack creates a stack object", function()
    local stack = lurek.effect.newStack()
    expect_equal(type(stack), "userdata")
  end)

  it("stack:count returns zero for empty stack", function()
    local stack = lurek.effect.newStack()
    expect_equal(stack:count(), 0)
  end)

  it("newPass returns an effect userdata", function()
    local eff = lurek.effect.newPass("pixelate", { size = 4 })
    expect_equal(type(eff), "userdata")
  end)

  it("stack:add and count increment", function()
    local stack = lurek.effect.newStack()
    local eff = lurek.effect.newPass("pixelate", { size = 2 })
    stack:add(eff)
    expect_equal(stack:count(), 1)
  end)

  it("stack:remove decrements count", function()
    local stack = lurek.effect.newStack()
    local eff = lurek.effect.newPass("pixelate", { size = 2 })
    stack:add(eff)
    stack:remove(eff)
    expect_equal(stack:count(), 0)
  end)
end)

test_summary()
