-- tests/lua/unit/test_event.lua
-- BDD tests for the lurek.signal event subsystem (pump/wait/restart API).
-- Headless-safe (no GPU/window needed).
-- @covers lurek.signal.clear
-- @covers lurek.signal.pump
-- @covers lurek.signal.push
-- @covers lurek.signal.restart
-- @covers lurek.signal.wait

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

test_summary()
