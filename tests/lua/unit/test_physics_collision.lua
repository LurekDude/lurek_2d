-- @module lurek.physics
-- @description Unit tests for stateless geometric collision helpers.
-- All helpers are pure math; no physics world is required.

describe("lurek.physics helpers", function()

  -- ── testAABB ────────────────────────────────────────────────────────────

  -- @covers lurek.physics.testAABB
  -- @description Overlapping AABBs return true.
  it("testAABB detects overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 5, 5, 10, 10), true)
  end)

  -- @covers lurek.physics.testAABB
  -- @description Non-overlapping AABBs return false.
  it("testAABB detects no overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 20, 20, 10, 10), false)
  end)

  -- @covers lurek.physics.testAABB
  -- @description Edge-touching AABBs do not overlap (open interval).
  it("testAABB touching edges do not overlap", function()
    expect_equal(lurek.physics.testAABB(0, 0, 10, 10, 10, 0, 10, 10), false)
  end)

  -- ── testCircles ─────────────────────────────────────────────────────────

  -- @covers lurek.physics.testCircles
  -- @description Overlapping circles return true.
  it("testCircles detects overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 5, 3, 0, 5), true)
  end)

  -- @covers lurek.physics.testCircles
  -- @description Non-overlapping circles return false.
  it("testCircles detects no overlap", function()
    expect_equal(lurek.physics.testCircles(0, 0, 1, 10, 0, 1), false)
  end)

  -- @covers lurek.physics.testCircles
  -- @description Same-centre circles always overlap.
  it("testCircles same centre always overlaps", function()
    expect_equal(lurek.physics.testCircles(5, 5, 1, 5, 5, 1), true)
  end)

  -- ── testPoint ───────────────────────────────────────────────────────────

  -- @covers lurek.physics.testPoint
  -- @description Point inside the AABB returns true.
  it("testPoint inside AABB", function()
    expect_equal(lurek.physics.testPoint(5, 5, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testPoint
  -- @description Point outside the AABB returns false.
  it("testPoint outside AABB", function()
    expect_equal(lurek.physics.testPoint(15, 5, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testPoint
  -- @description Point on the right edge (exclusive) returns false.
  it("testPoint on right edge returns false", function()
    expect_equal(lurek.physics.testPoint(10, 5, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testPoint
  -- @description Point at origin (inclusive) returns true.
  it("testPoint at origin is inside", function()
    expect_equal(lurek.physics.testPoint(0, 0, 0, 0, 10, 10), true)
  end)

  -- ── testCircleAABB ───────────────────────────────────────────────────────

  -- @covers lurek.physics.testCircleAABB
  -- @description Circle centred inside the AABB overlaps.
  it("testCircleAABB circle centre inside box", function()
    expect_equal(lurek.physics.testCircleAABB(5, 5, 3, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testCircleAABB
  -- @description Far circle does not overlap.
  it("testCircleAABB non-overlapping", function()
    expect_equal(lurek.physics.testCircleAABB(20, 20, 1, 0, 0, 10, 10), false)
  end)

  -- @covers lurek.physics.testCircleAABB
  -- @description Circle overlapping a corner of the AABB.
  it("testCircleAABB overlapping corner", function()
    -- Circle at (12, 12) with radius 3 — corner (10,10) is at distance sqrt(8) ≈ 2.83
    expect_equal(lurek.physics.testCircleAABB(12, 12, 3, 0, 0, 10, 10), true)
  end)

  -- @covers lurek.physics.testCircleAABB
  -- @description Circle just beyond a corner does not overlap.
  it("testCircleAABB just outside corner", function()
    -- Circle at (13, 13) with radius 1 — corner (10,10) is at distance sqrt(18) ≈ 4.24
    expect_equal(lurek.physics.testCircleAABB(13, 13, 1, 0, 0, 10, 10), false)
  end)

end)

test_summary()
