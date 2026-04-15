-- tests/lua/unit/test_data_ring_buffer.lua
-- BDD tests for lurek.data.newRingBuffer

-- @description Verifies the ring buffer factory and all its methods.

-- @description Factory and type checks.
describe("lurek.data.newRingBuffer factory", function()
  -- @covers lurek.data.newRingBuffer
  it("newRingBuffer is a function", function()
    expect_type("function", lurek.data.newRingBuffer)
  end)

  -- @description Creates a ring buffer and confirms the returned object is a userdata.
  it("returns a userdata", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_type("userdata", rb)
  end)

  -- @description Confirms that capacity() reflects the size passed to newRingBuffer.
  it("capacity matches constructor argument", function()
    local rb = lurek.data.newRingBuffer(8)
    expect_equal(rb:capacity(), 8)
  end)

  -- @description A freshly created buffer must report length 0.
  it("new buffer has len 0", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:len(), 0)
  end)

  -- @description A freshly created buffer must report isEmpty true.
  it("new buffer isEmpty is true", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:isEmpty(), true)
  end)

  -- @description A freshly created buffer must report isFull false.
  it("new buffer isFull is false", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:isFull(), false)
  end)

  -- @description Requesting capacity 0 must raise a Lua error.
  it("capacity 0 raises an error", function()
    expect_error(function() lurek.data.newRingBuffer(0) end)
  end)
end)

-- @description Push and pop semantics.
describe("RingBuffer push/pop", function()
  -- @covers lurek.data.newRingBuffer
  -- @description push returns false (no overwrite) when there is space.
  it("push returns false when space available", function()
    local rb = lurek.data.newRingBuffer(4)
    local overwrote = rb:push(42)
    expect_equal(overwrote, false)
  end)

  -- @description push returns true (overwrote oldest) when the buffer is full.
  it("push returns true when buffer is full", function()
    local rb = lurek.data.newRingBuffer(2)
    rb:push(1)
    rb:push(2)
    local overwrote = rb:push(3)
    expect_equal(overwrote, true)
  end)

  -- @description After one push, len should be 1.
  it("len increments after push", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("hello")
    expect_equal(rb:len(), 1)
  end)

  -- @description Pop on an empty buffer returns nil.
  it("pop on empty returns nil", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:pop(), nil)
  end)

  -- @description Single push then pop returns the pushed value.
  it("pop returns the pushed value", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(99)
    expect_equal(rb:pop(), 99)
  end)

  -- @description Pop removes the element: subsequent len should be 0.
  it("len decrements after pop", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(1)
    rb:pop()
    expect_equal(rb:len(), 0)
  end)

  -- @description Pop follows FIFO order: oldest element is returned first.
  it("pop follows FIFO order", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(10)
    rb:push(20)
    rb:push(30)
    expect_equal(rb:pop(), 10)
    expect_equal(rb:pop(), 20)
    expect_equal(rb:pop(), 30)
  end)

  -- @description When full, push overwrites the oldest and pop returns the second-oldest.
  it("overwrite preserves FIFO after wrap", function()
    local rb = lurek.data.newRingBuffer(3)
    rb:push("a")
    rb:push("b")
    rb:push("c")  -- full
    rb:push("d")  -- overwrites "a"
    expect_equal(rb:pop(), "b")
    expect_equal(rb:pop(), "c")
    expect_equal(rb:pop(), "d")
    expect_equal(rb:pop(), nil)
  end)
end)

-- @description Peek methods.
describe("RingBuffer peek / peekNewest", function()
  -- @covers lurek.data.newRingBuffer
  -- @description peek on an empty buffer returns nil.
  it("peek on empty returns nil", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:peek(), nil)
  end)

  -- @description peekNewest on an empty buffer returns nil.
  it("peekNewest on empty returns nil", function()
    local rb = lurek.data.newRingBuffer(4)
    expect_equal(rb:peekNewest(), nil)
  end)

  -- @description peek returns the oldest element without removing it.
  it("peek returns oldest without removing", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(1)
    rb:push(2)
    expect_equal(rb:peek(), 1)
    expect_equal(rb:len(), 2) -- unchanged
  end)

  -- @description peekNewest returns the most recently pushed element.
  it("peekNewest returns newest", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(1)
    rb:push(2)
    rb:push(3)
    expect_equal(rb:peekNewest(), 3)
    expect_equal(rb:len(), 3) -- unchanged
  end)
end)

-- @description isFull / isEmpty state transitions.
describe("RingBuffer isFull / isEmpty", function()
  -- @covers lurek.data.newRingBuffer
  -- @description A buffer filling to capacity should report isFull true.
  it("isFull true when capacity reached", function()
    local rb = lurek.data.newRingBuffer(3)
    rb:push(1); rb:push(2); rb:push(3)
    expect_equal(rb:isFull(), true)
  end)

  -- @description A buffer with one element should not report isEmpty.
  it("isEmpty false after one push", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("x")
    expect_equal(rb:isEmpty(), false)
  end)

  -- @description After popping the last element the buffer reports isEmpty true.
  it("isEmpty true after all elements popped", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("x")
    rb:pop()
    expect_equal(rb:isEmpty(), true)
  end)
end)

-- @description clear method.
describe("RingBuffer clear", function()
  -- @covers lurek.data.newRingBuffer
  -- @description After clear, len is 0 and isEmpty is true.
  it("clear resets len to 0", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push(1); rb:push(2); rb:push(3)
    rb:clear()
    expect_equal(rb:len(), 0)
    expect_equal(rb:isEmpty(), true)
  end)

  -- @description After clear, pop returns nil.
  it("pop after clear returns nil", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("a")
    rb:clear()
    expect_equal(rb:pop(), nil)
  end)
end)

-- @description toTable method.
describe("RingBuffer toTable", function()
  -- @covers lurek.data.newRingBuffer
  -- @description toTable on an empty buffer returns an empty table.
  it("toTable on empty returns empty table", function()
    local rb = lurek.data.newRingBuffer(4)
    local t = rb:toTable()
    expect_type("table", t)
    expect_equal(#t, 0)
  end)

  -- @description toTable returns elements in oldest-first order.
  it("toTable returns oldest-first", function()
    local rb = lurek.data.newRingBuffer(4)
    rb:push("x"); rb:push("y"); rb:push("z")
    local t = rb:toTable()
    expect_equal(#t, 3)
    expect_equal(t[1], "x")
    expect_equal(t[2], "y")
    expect_equal(t[3], "z")
  end)

  -- @description During a wrapped state toTable still reflects FIFO order.
  it("toTable correct after wrap", function()
    local rb = lurek.data.newRingBuffer(3)
    rb:push(1); rb:push(2); rb:push(3); rb:push(4) -- overwrites 1
    local t = rb:toTable()
    expect_equal(#t, 3)
    expect_equal(t[1], 2)
    expect_equal(t[2], 3)
    expect_equal(t[3], 4)
  end)
end)

-- @description Mixed Lua value types.
describe("RingBuffer mixed value types", function()
  -- @covers lurek.data.newRingBuffer
  -- @description The buffer can hold numbers, strings, booleans, and tables.
  it("stores and retrieves different Lua types", function()
    local rb = lurek.data.newRingBuffer(8)
    rb:push(42)
    rb:push("hello")
    rb:push(true)
    rb:push({key = "value"})
    expect_equal(rb:len(), 4)
    local n = rb:pop()
    expect_equal(n, 42)
    local s = rb:pop()
    expect_equal(s, "hello")
    local b = rb:pop()
    expect_equal(b, true)
    local tbl = rb:pop()
    expect_type("table", tbl)
    expect_equal(tbl.key, "value")
  end)
end)

test_summary()
