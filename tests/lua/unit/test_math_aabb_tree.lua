-- tests/lua/unit/test_math_aabb_tree.lua
-- BDD tests for lurek.math.aabbTree

-- @description Verifies the AABB tree factory, insertion, removal, and query behaviour.

-- @description Factory and type checks.
describe("lurek.math.aabbTree factory", function()
  -- @covers lurek.math.aabbTree
  it("aabbTree is a function", function()
    expect_type("function", lurek.math.aabbTree)
  end)

  -- @description Creates an AABB tree and confirms the returned value is userdata.
  it("returns a userdata", function()
    local t = lurek.math.aabbTree()
    expect_type("userdata", t)
  end)

  -- @description A freshly created tree has len 0.
  it("new tree len is 0", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:len(), 0)
  end)

  -- @description A freshly created tree reports isEmpty true.
  it("new tree isEmpty is true", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:isEmpty(), true)
  end)
end)

-- @description Insert and contains.
describe("AabbTree insert / contains", function()
  -- @covers lurek.math.aabbTree
  -- @description After inserting one entry, len should be 1.
  it("len increments after insert", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    expect_equal(t:len(), 1)
  end)

  -- @description contains returns true for a known id, false for unknown.
  it("contains returns true for inserted id", function()
    local t = lurek.math.aabbTree()
    t:insert(42, 0, 0, 5, 5)
    expect_equal(t:contains(42), true)
  end)

  -- @description contains returns false for an id that was never inserted.
  it("contains returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:contains(999), false)
  end)

  -- @description Inserting multiple entries updates len correctly.
  it("len reflects multiple inserts", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:insert(3, 10, 10, 20, 20)
    expect_equal(t:len(), 3)
  end)

  -- @description Inserting an id that already exists acts as an upsert (len stays the same).
  it("inserting duplicate id does not increase len", function()
    local t = lurek.math.aabbTree()
    t:insert(7, 0, 0, 10, 10)
    t:insert(7, 5, 5, 15, 15)  -- upsert
    expect_equal(t:len(), 1)
  end)
end)

-- @description Remove.
describe("AabbTree remove", function()
  -- @covers lurek.math.aabbTree
  -- @description remove returns true for a known id.
  it("remove returns true for known id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    expect_equal(t:remove(1), true)
  end)

  -- @description remove returns false for an unknown id.
  it("remove returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:remove(999), false)
  end)

  -- @description After removing, contains returns false.
  it("contains false after remove", function()
    local t = lurek.math.aabbTree()
    t:insert(5, 0, 0, 10, 10)
    t:remove(5)
    expect_equal(t:contains(5), false)
  end)

  -- @description After removing, len decrements.
  it("len decrements after remove", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:remove(1)
    expect_equal(t:len(), 1)
  end)
end)

-- @description query rectangle overlap.
describe("AabbTree query", function()
  -- @covers lurek.math.aabbTree
  -- @description A query that overlaps a single entry returns that id.
  it("query returns overlapping id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    t:insert(2, 20, 20, 30, 30)
    local ids = t:query(5, 5, 15, 15)
    expect_type("table", ids)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 1)
  end)

  -- @description A query that misses all entries returns an empty table.
  it("query returns empty table on miss", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    local ids = t:query(100, 100, 200, 200)
    expect_equal(#ids, 0)
  end)

  -- @description A query that covers all entries returns all ids.
  it("query returns all ids when rect covers all", function()
    local t = lurek.math.aabbTree()
    t:insert(10, 0, 0, 1, 1)
    t:insert(20, 5, 5, 6, 6)
    t:insert(30, 9, 9, 10, 10)
    local ids = t:query(-1, -1, 100, 100)
    expect_equal(#ids, 3)
  end)

  -- @description A query on an empty tree returns an empty table.
  it("query on empty tree returns empty table", function()
    local t = lurek.math.aabbTree()
    local ids = t:query(0, 0, 100, 100)
    expect_equal(#ids, 0)
  end)
end)

-- @description queryPoint.
describe("AabbTree queryPoint", function()
  -- @covers lurek.math.aabbTree
  -- @description A point inside an AABB returns that entry's id.
  it("queryPoint finds containing entry", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(5, 5)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 1)
  end)

  -- @description A point outside all AABBs returns an empty table.
  it("queryPoint returns empty for exterior point", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(50, 50)
    expect_equal(#ids, 0)
  end)

  -- @description A point on the edge of an AABB is considered inside.
  it("queryPoint on edge counts as inside", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 10, 10)
    local ids = t:queryPoint(10, 10)
    expect_equal(#ids, 1)
  end)
end)

-- @description update.
describe("AabbTree update", function()
  -- @covers lurek.math.aabbTree
  -- @description update returns false for an unknown id.
  it("update returns false for unknown id", function()
    local t = lurek.math.aabbTree()
    expect_equal(t:update(99, 0, 0, 1, 1), false)
  end)

  -- @description update returns true for an existing id.
  it("update returns true for known id", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    expect_equal(t:update(1, 10, 10, 20, 20), true)
  end)

  -- @description After update, the old position no longer matches and new position does.
  it("update moves the bounding box", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 5, 5)
    t:update(1, 50, 50, 60, 60)
    local old_ids = t:query(0, 0, 5, 5)
    local new_ids = t:query(50, 50, 60, 60)
    expect_equal(#old_ids, 0)
    expect_equal(#new_ids, 1)
    expect_equal(new_ids[1], 1)
  end)
end)

-- @description clear.
describe("AabbTree clear", function()
  -- @covers lurek.math.aabbTree
  -- @description After clear, len is 0 and isEmpty is true.
  it("clear resets len to 0", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 1, 1)
    t:insert(2, 2, 2, 3, 3)
    t:clear()
    expect_equal(t:len(), 0)
    expect_equal(t:isEmpty(), true)
  end)

  -- @description After clear, queries return empty tables.
  it("query after clear returns empty", function()
    local t = lurek.math.aabbTree()
    t:insert(1, 0, 0, 100, 100)
    t:clear()
    local ids = t:query(0, 0, 100, 100)
    expect_equal(#ids, 0)
  end)
end)

-- @description Edge cases and stress.
describe("AabbTree edge cases", function()
  -- @covers lurek.math.aabbTree
  -- @description Single-entry tree: query with the exact AABB returns the id.
  it("single entry exact AABB match", function()
    local t = lurek.math.aabbTree()
    t:insert(7, 3, 3, 7, 7)
    local ids = t:query(3, 3, 7, 7)
    expect_equal(#ids, 1)
    expect_equal(ids[1], 7)
  end)

  -- @description Many inserts and removals leave the tree in a consistent state.
  it("many inserts then removes yields empty tree", function()
    local t = lurek.math.aabbTree()
    for i = 1, 20 do
      t:insert(i, i * 2, i * 2, i * 2 + 1, i * 2 + 1)
    end
    expect_equal(t:len(), 20)
    for i = 1, 20 do
      t:remove(i)
    end
    expect_equal(t:len(), 0)
    expect_equal(t:isEmpty(), true)
    local ids = t:query(-1000, -1000, 1000, 1000)
    expect_equal(#ids, 0)
  end)
end)

test_summary()
