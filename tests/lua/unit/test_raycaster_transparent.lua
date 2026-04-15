-- tests/lua/unit/test_raycaster_transparent.lua
-- BDD tests for lurek.raycaster transparent / translucent wall support.

describe("raycaster transparent walls", function()
  it("setWallAlpha and getWallAlpha round-trip correctly", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(3, 0.5)
    expect_near(m:getWallAlpha(3), 0.5, 0.001)
  end)

  it("getWallAlpha returns 1.0 for unregistered tile type", function()
    local m = lurek.raycaster.newMap(32, 32)
    expect_near(m:getWallAlpha(99), 1.0, 0.001)
  end)

  it("alpha above 1.0 is clamped to 1.0", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, 1.5)
    expect_near(m:getWallAlpha(1), 1.0, 0.001)
  end)

  it("alpha below 0.0 is clamped to 0.0", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, -0.5)
    expect_near(m:getWallAlpha(1), 0.0, 0.001)
  end)

  it("multiple tile types store independent alpha values", function()
    local m = lurek.raycaster.newMap(32, 32)
    m:setWallAlpha(1, 0.25)
    m:setWallAlpha(2, 0.75)
    expect_near(m:getWallAlpha(1), 0.25, 0.001)
    expect_near(m:getWallAlpha(2), 0.75, 0.001)
    -- unset tile still defaults
    expect_near(m:getWallAlpha(3), 1.0, 0.001)
  end)

  it("castRayMulti returns a table", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hits = m:castRayMulti(8.5, 8.5, -math.pi / 2, 20.0)
    expect_equal(type(hits), "table")
  end)

  it("castRayMulti hit table contains alpha field", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hits = m:castRayMulti(8.5, 8.5, -math.pi / 2, 20.0)
    if #hits > 0 then
      expect_equal(type(hits[1].alpha), "number")
    end
  end)

  it("castRay hit table contains alpha field", function()
    local m = lurek.raycaster.newMap(16, 16)
    m:setCell(8, 4, 1)
    local hit = m:castRay(8.5, 8.5, -math.pi / 2, 20.0)
    if hit then
      expect_equal(type(hit.alpha), "number")
    end
  end)
end)

test_summary()
