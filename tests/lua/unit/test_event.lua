-- tests/lua/unit/test_event.lua
-- BDD tests for the lurek.signal event subsystem.
-- Headless-safe (no GPU/window needed).
-- @covers lurek.signal.clear
-- @covers lurek.signal.pump
-- @covers lurek.signal.push
-- @covers lurek.signal.restart
-- @covers lurek.signal.wait
-- @covers lurek.signal.newSignal
-- @covers lurek.signal.poll
-- @covers lurek.signal.quit

describe("lurek.signal.pump", function()
  it("exists as a function", function()
    expect_equal(type(lurek.signal.pump), "function")
  end)

  it("returns without error", function()
    local ok, err = pcall(function() lurek.signal.pump() end)
    expect_equal(ok, true)
  end)
end)

describe("lurek.signal.wait", function()
  it("exists as a function", function()
    expect_equal(type(lurek.signal.wait), "function")
  end)

  it("returns nil on timeout with no events", function()
    -- 10 ms timeout, queue is empty
    local name = lurek.signal.wait(0.01)
    expect_equal(name, nil)
  end)

  it("returns event name immediately if event is available", function()
    lurek.signal.push("testev")
    local name = lurek.signal.wait(0)
    expect_equal(name, "testev")
  end)

  it("returns nil with zero timeout and empty queue", function()
    lurek.signal.clear()
    local name = lurek.signal.wait(0)
    expect_equal(name, nil)
  end)
end)

describe("lurek.signal.restart", function()
  it("exists as a function", function()
    expect_equal(type(lurek.signal.restart), "function")
  end)

  it("does not throw an error when called", function()
    -- NOTE: calling restart sets a flag; it does not actually reboot the VM here.
    local ok, err = pcall(function() lurek.signal.restart() end)
    expect_equal(ok, true)
  end)
end)

-- ── Signal UserData ──────────────────────────────────────────────────────────

describe("lurek.signal.newSignal", function()
  it("creates a Signal object", function()
    local sig = lurek.signal.newSignal()
    expect_not_nil(sig)
  end)

  it("register adds a listener", function()
    local sig = lurek.signal.newSignal()
    local handle = sig:register("click", function() end)
    expect_not_nil(handle)
    expect_equal(sig:getCount("click"), 1)
  end)

  it("emit fires registered callback", function()
    local sig = lurek.signal.newSignal()
    local fired = false
    sig:register("action", function() fired = true end)
    sig:emit("action")
    expect_equal(fired, true)
  end)

  it("emit passes arguments to callback", function()
    local sig = lurek.signal.newSignal()
    local received = {}
    sig:register("data", function(a, b, c)
      received = { a, b, c }
    end)
    sig:emit("data", "hello", 42, true)
    expect_equal(received[1], "hello")
    expect_equal(received[2], 42)
    expect_equal(received[3], true)
  end)

  it("multiple listeners all fire", function()
    local sig = lurek.signal.newSignal()
    local count = 0
    sig:register("tick", function() count = count + 1 end)
    sig:register("tick", function() count = count + 1 end)
    sig:emit("tick")
    expect_equal(count, 2)
  end)

  it("getCount returns listener count for name", function()
    local sig = lurek.signal.newSignal()
    sig:register("a", function() end)
    sig:register("a", function() end)
    sig:register("b", function() end)
    expect_equal(sig:getCount("a"), 2)
    expect_equal(sig:getCount("b"), 1)
  end)

  it("getTotalCount returns all listeners", function()
    local sig = lurek.signal.newSignal()
    sig:register("a", function() end)
    sig:register("b", function() end)
    sig:register("c", function() end)
    expect_equal(sig:getTotalCount(), 3)
  end)

  it("remove unsubscribes a listener", function()
    local sig = lurek.signal.newSignal()
    local fired = false
    local handle = sig:register("test", function() fired = true end)
    local ok = sig:remove(handle)
    expect_true(ok)
    sig:emit("test")
    expect_equal(fired, false)
  end)

  it("remove returns false for unknown handle", function()
    local sig = lurek.signal.newSignal()
    local ok = sig:remove(9999)
    expect_equal(ok, false)
  end)

  it("clear removes all listeners for a name", function()
    local sig = lurek.signal.newSignal()
    sig:register("click", function() end)
    sig:register("click", function() end)
    sig:register("hover", function() end)
    local removed = sig:clear("click")
    expect_equal(removed, 2)
    expect_equal(sig:getCount("click"), 0)
    expect_equal(sig:getCount("hover"), 1)
  end)

  it("clearAll removes everything", function()
    local sig = lurek.signal.newSignal()
    sig:register("a", function() end)
    sig:register("b", function() end)
    local removed = sig:clearAll()
    expect_equal(removed, 2)
    expect_equal(sig:getTotalCount(), 0)
  end)

  it("type returns Signal", function()
    local sig = lurek.signal.newSignal()
    expect_equal(sig:type(), "Signal")
  end)

  it("typeOf returns true for Signal type", function()
    local sig = lurek.signal.newSignal()
    expect_true(sig:typeOf("Signal"))
  end)

  it("typeOf returns true for Object base type", function()
    local sig = lurek.signal.newSignal()
    expect_true(sig:typeOf("Object"))
  end)

  it("typeOf returns false for unrelated type name", function()
    local sig = lurek.signal.newSignal()
    expect_equal(sig:typeOf("unknown"), false)
  end)
end)

-- ── poll iterator ────────────────────────────────────────────────────────────

describe("lurek.signal.poll", function()
  it("iterates queued events", function()
    lurek.signal.clear()
    lurek.signal.push("ev1")
    lurek.signal.push("ev2")
    local names = {}
    for name in lurek.signal.poll() do
      table.insert(names, name)
    end
    expect_equal(#names, 2)
    expect_equal(names[1], "ev1")
    expect_equal(names[2], "ev2")
  end)

  it("returns nothing when queue is empty", function()
    lurek.signal.clear()
    local count = 0
    for name in lurek.signal.poll() do
      count = count + 1
    end
    expect_equal(count, 0)
  end)
end)

test_summary()
