-- BDD tests for luna.event.pump, luna.event.wait, and luna.event.restart

describe("event.pump", function()
  it("exists as a function", function()
    expect_equal(type(luna.event.pump), "function")
  end)

  it("returns without error", function()
    local ok, err = pcall(function() luna.event.pump() end)
    expect_equal(ok, true)
  end)
end)

describe("event.wait", function()
  it("exists as a function", function()
    expect_equal(type(luna.event.wait), "function")
  end)

  it("returns nil on timeout with no events", function()
    -- 10 ms timeout, queue is empty
    local name = luna.event.wait(0.01)
    expect_equal(name, nil)
  end)

  it("returns event name immediately if event is available", function()
    luna.event.push("testev")
    local name = luna.event.wait(0)
    expect_equal(name, "testev")
  end)

  it("returns nil with zero timeout and empty queue", function()
    luna.event.clear()
    local name = luna.event.wait(0)
    expect_equal(name, nil)
  end)
end)

describe("event.restart", function()
  it("exists as a function", function()
    expect_equal(type(luna.event.restart), "function")
  end)

  it("does not throw an error when called", function()
    -- NOTE: calling restart sets a flag; it does not actually reboot the VM here.
    local ok, err = pcall(function() luna.event.restart() end)
    expect_equal(ok, true)
  end)
end)

test_summary()
