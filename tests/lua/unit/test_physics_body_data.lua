-- @module lurek.physics
-- @description Unit tests for physics body data attachment (setBodyData / getBodyData / clearBodyData).

describe("physics body data", function()

  -- @covers lurek.physics.World:setBodyData
  -- @covers lurek.physics.World:getBodyData
  -- @description Stored table data survives a round-trip.
  it("setBodyData and getBodyData round-trip table", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    w:setBodyData(id, { name = "ground", kind = "platform" })
    local d = w:getBodyData(id)
    expect_equal(d.name, "ground")
    expect_equal(d.kind, "platform")
  end)

  -- @covers lurek.physics.World:getBodyData
  -- @description Reading data for a body that was never given data returns nil.
  it("getBodyData returns nil for unset body", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    local d = w:getBodyData(id)
    expect_equal(d, nil)
  end)

  -- @covers lurek.physics.World:clearBodyData
  -- @description clearBodyData removes previously stored data.
  it("clearBodyData removes data", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "static")
    local id = body:getId()
    w:setBodyData(id, "some data")
    w:clearBodyData(id)
    expect_equal(w:getBodyData(id), nil)
  end)

  -- @covers lurek.physics.World:setBodyData
  -- @description Overwriting data with setBodyData replaces the old value.
  it("setBodyData overwrites previous value", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local body = w:newBody(0, 0, "dynamic")
    local id = body:getId()
    w:setBodyData(id, "first")
    w:setBodyData(id, "second")
    expect_equal(w:getBodyData(id), "second")
  end)

  -- @covers lurek.physics.World:setBodyData
  -- @description Data for multiple bodies is stored independently.
  it("body data is per-body, not shared", function()
    local w = lurek.physics.newWorld(0, 9.81)
    local b1 = w:newBody(0, 0, "static")
    local b2 = w:newBody(100, 100, "dynamic")
    local id1 = b1:getId()
    local id2 = b2:getId()
    w:setBodyData(id1, "bodyA")
    w:setBodyData(id2, "bodyB")
    expect_equal(w:getBodyData(id1), "bodyA")
    expect_equal(w:getBodyData(id2), "bodyB")
  end)

end)

test_summary()
