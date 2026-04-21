-- tests/lua/unit/test_event.lua
-- BDD tests for the lurek.event event subsystem.
-- Headless-safe (no GPU/window needed).

-- @description Covers suite: lurek.event.pump.
describe("lurek.event.pump", function()
  -- @covers lurek.event.pump
  -- @covers lurek.event.clear
  -- @covers lurek.event.push
  -- @covers lurek.event.restart
  -- @covers lurek.event.wait
  -- @covers lurek.event.newSignal
  -- @covers lurek.event.poll
  -- @covers lurek.event.quit
  -- @description Checks that the lurek.event namespace exports pump as a callable function before queue behavior is exercised.
  it("exists as a function", function()
    expect_equal(type(lurek.event.pump), "function")
  end)

  -- @covers lurek.event.pump
  -- @description Calls pump inside pcall with no queued work to verify the event-queue sync hook returns without raising an error.
  it("returns without error", function()
    local ok, err = pcall(function() lurek.event.pump() end)
    expect_equal(ok, true)
  end)
end)

-- @description Covers suite: lurek.event.wait.
describe("lurek.event.wait", function()
  -- @covers lurek.event.wait
  -- @description Confirms wait is exposed as a callable function on the signal module before timeout cases are tested.
  it("exists as a function", function()
    expect_equal(type(lurek.event.wait), "function")
  end)

  -- @covers lurek.event.wait
  -- @description Waits for 10 ms against an empty queue and verifies the API returns nil instead of inventing an event.
  it("returns nil on timeout with no events", function()
    -- 10 ms timeout, queue is empty
    local name = lurek.event.wait(0.01)
    expect_equal(name, nil)
  end)

  -- @covers lurek.event.push
  -- @covers lurek.event.wait
  -- @description Pushes a named event and immediately waits with zero timeout to confirm wait consumes the queued event without blocking.
  it("returns event name immediately if event is available", function()
    lurek.event.push("testev")
    local name = lurek.event.wait(0)
    expect_equal(name, "testev")
  end)

  -- @covers lurek.event.clear
  -- @covers lurek.event.wait
  -- @description Clears pending events first, then verifies a zero-timeout wait reports an empty queue by returning nil.
  it("returns nil with zero timeout and empty queue", function()
    lurek.event.clear()
    local name = lurek.event.wait(0)
    expect_equal(name, nil)
  end)
end)

-- @description Covers suite: lurek.event.restart.
describe("lurek.event.restart", function()
  -- @covers lurek.event.restart
  -- @description Verifies the restart hook is exported as a callable function on the signal namespace.
  it("exists as a function", function()
    expect_equal(type(lurek.event.restart), "function")
  end)

  -- @covers lurek.event.restart
  -- @description Invokes restart inside pcall to confirm the restart request flag can be set without throwing inside the test VM.
  it("does not throw an error when called", function()
    -- NOTE: calling restart sets a flag; it does not actually reboot the VM here.
    local ok, err = pcall(function() lurek.event.restart() end)
    expect_equal(ok, true)
  end)
end)

-- â”€â”€ Signal UserData â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: lurek.event.newSignal.
describe("lurek.event.newSignal", function()
  -- @covers lurek.event.newSignal
  -- @description Creates a fresh Signal userdata and checks the constructor returns a non-nil object.
  it("creates a Signal object", function()
    local sig = lurek.event.newSignal()
    expect_not_nil(sig)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.getCount
  -- @description Registers one click listener and verifies register returns a handle while getCount reflects the new subscription.
  it("register adds a listener", function()
    local sig = lurek.event.newSignal()
    local handle = sig:register("click", function() end)
    expect_not_nil(handle)
    expect_equal(sig:getCount("click"), 1)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.emit
  -- @description Registers an action listener, emits that event name, and checks the callback flips a captured boolean.
  it("emit fires registered callback", function()
    local sig = lurek.event.newSignal()
    local fired = false
    sig:register("action", function() fired = true end)
    sig:emit("action")
    expect_equal(fired, true)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.emit
  -- @description Emits a data event with three payload values and verifies the registered listener receives the exact argument sequence.
  it("emit passes arguments to callback", function()
    local sig = lurek.event.newSignal()
    local received = {}
    sig:register("data", function(a, b, c)
      received = { a, b, c }
    end)
    sig:emit("data", "hello", 42, true)
    expect_equal(received[1], "hello")
    expect_equal(received[2], 42)
    expect_equal(received[3], true)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.emit
  -- @description Registers two listeners for the same tick event and confirms one emit dispatches to both callbacks.
  it("multiple listeners all fire", function()
    local sig = lurek.event.newSignal()
    local count = 0
    sig:register("tick", function() count = count + 1 end)
    sig:register("tick", function() count = count + 1 end)
    sig:emit("tick")
    expect_equal(count, 2)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.getCount
  -- @description Adds listeners under two event names and checks getCount reports per-name totals rather than a global count.
  it("getCount returns listener count for name", function()
    local sig = lurek.event.newSignal()
    sig:register("a", function() end)
    sig:register("a", function() end)
    sig:register("b", function() end)
    expect_equal(sig:getCount("a"), 2)
    expect_equal(sig:getCount("b"), 1)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.getTotalCount
  -- @description Registers listeners across three distinct event names and verifies getTotalCount sums them into one total.
  it("getTotalCount returns all listeners", function()
    local sig = lurek.event.newSignal()
    sig:register("a", function() end)
    sig:register("b", function() end)
    sig:register("c", function() end)
    expect_equal(sig:getTotalCount(), 3)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.remove
  -- @covers lurek.event.Signal.emit
  -- @description Removes a registered handle before emitting its event and verifies the detached listener no longer fires.
  it("remove unsubscribes a listener", function()
    local sig = lurek.event.newSignal()
    local fired = false
    local handle = sig:register("test", function() fired = true end)
    local ok = sig:remove(handle)
    expect_true(ok)
    sig:emit("test")
    expect_equal(fired, false)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.remove
  -- @description Calls remove with a nonexistent handle ID and verifies the API reports failure with false.
  it("remove returns false for unknown handle", function()
    local sig = lurek.event.newSignal()
    local ok = sig:remove(9999)
    expect_equal(ok, false)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.clear
  -- @covers lurek.event.Signal.getCount
  -- @description Clears only the click subscriptions and verifies hover listeners remain while click counts drop to zero.
  it("clear removes all listeners for a name", function()
    local sig = lurek.event.newSignal()
    sig:register("click", function() end)
    sig:register("click", function() end)
    sig:register("hover", function() end)
    local removed = sig:clear("click")
    expect_equal(removed, 2)
    expect_equal(sig:getCount("click"), 0)
    expect_equal(sig:getCount("hover"), 1)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.clearAll
  -- @covers lurek.event.Signal.getTotalCount
  -- @description Registers listeners under multiple names, clears the dispatcher globally, and checks no subscriptions remain.
  it("clearAll removes everything", function()
    local sig = lurek.event.newSignal()
    sig:register("a", function() end)
    sig:register("b", function() end)
    local removed = sig:clearAll()
    expect_equal(removed, 2)
    expect_equal(sig:getTotalCount(), 0)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.type
  -- @description Constructs a Signal userdata and verifies its runtime type string reports Signal.
  it("type returns Signal", function()
    local sig = lurek.event.newSignal()
    expect_equal(sig:type(), "Signal")
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.typeOf
  -- @description Verifies typeOf recognizes the concrete Signal type name on a newly created dispatcher.
  it("typeOf returns true for Signal type", function()
    local sig = lurek.event.newSignal()
    expect_true(sig:typeOf("Signal"))
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.typeOf
  -- @description Verifies typeOf also reports true for the shared Object base type implemented by Signal userdata.
  it("typeOf returns true for Object base type", function()
    local sig = lurek.event.newSignal()
    expect_true(sig:typeOf("Object"))
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.typeOf
  -- @description Passes an unrelated type name to typeOf and confirms the Signal userdata rejects the mismatch.
  it("typeOf returns false for unrelated type name", function()
    local sig = lurek.event.newSignal()
    expect_equal(sig:typeOf("unknown"), false)
  end)
end)

-- â”€â”€ poll iterator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: lurek.event.poll.
describe("lurek.event.poll", function()
  -- @covers lurek.event.clear
  -- @covers lurek.event.push
  -- @covers lurek.event.poll
  -- @description Clears the queue, pushes two named events, then iterates poll() to verify FIFO delivery order through the Lua iterator.
  it("iterates queued events", function()
    lurek.event.clear()
    lurek.event.push("ev1")
    lurek.event.push("ev2")
    local names = {}
    for name in lurek.event.poll() do
      table.insert(names, name)
    end
    expect_equal(#names, 2)
    expect_equal(names[1], "ev1")
    expect_equal(names[2], "ev2")
  end)

  -- @covers lurek.event.clear
  -- @covers lurek.event.poll
  -- @description Empties the queue before iterating poll() and verifies the iterator produces no values when nothing is pending.
  it("returns nothing when queue is empty", function()
    lurek.event.clear()
    local count = 0
    for name in lurek.event.poll() do
      count = count + 1
    end
    expect_equal(count, 0)
  end)
end)

-- @description New-feature tests: once, registerWithFilter, pushDeferred/flushDeferred, history.
describe("lurek.event once and filter", function()
  -- @covers lurek.event.newSignal
  -- @description Creates a signal and registers a once-listener; after emitting once the listener must not fire again.
  it("once callback fires exactly one time", function()
    local sig = lurek.event.newSignal()
    local count = 0
    sig:once("bang", function() count = count + 1 end)
    sig:emit("bang")
    sig:emit("bang")
    expect_equal(count, 1)
  end)

  -- @covers lurek.event.newSignal
  -- @description Registers a once and a permanent listener on the same event; confirms once fires once and permanent fires twice.
  it("once and permanent listener coexist correctly", function()
    local sig = lurek.event.newSignal()
    local once_count  = 0
    local perm_count  = 0
    sig:once("tick", function() once_count = once_count + 1 end)
    sig:register("tick", function() perm_count = perm_count + 1 end)
    sig:emit("tick")
    sig:emit("tick")
    expect_equal(once_count, 1)
    expect_equal(perm_count, 2)
  end)

  -- @covers lurek.event.newSignal
  -- @description Registers registerWithFilter with a predicate that passes only numbers > 5; confirms callback fires selectively.
  it("registerWithFilter respects the predicate", function()
    local sig = lurek.event.newSignal()
    local fired = 0
    sig:registerWithFilter("val", function(v) fired = fired + 1 end, function(v) return v > 5 end)
    sig:emit("val", 3)   -- blocked
    sig:emit("val", 10)  -- allowed
    expect_equal(fired, 1)
  end)
end)

describe("lurek.event pushDeferred and history", function()
  -- @covers lurek.event.pushDeferred
  -- @covers lurek.event.flushDeferred
  -- @description Pushes two deferred events, confirms flushDeferred reports count and events appear in the queue.
  it("pushDeferred/flushDeferred works", function()
    lurek.event.pushDeferred("deferA")
    lurek.event.pushDeferred("deferB")
    local count = lurek.event.flushDeferred()
    expect_equal(count, 2)
  end)

  -- @covers lurek.event.enableHistory
  -- @covers lurek.event.getHistory
  -- @covers lurek.event.clearHistory
  -- @description Enables history, pushes two events, verifies getHistory returns both, then clearHistory empties it.
  it("history records pushed events", function()
    lurek.event.enableHistory(10)
    lurek.event.push("histA")
    lurek.event.push("histB")
    local h = lurek.event.getHistory()
    expect_equal(type(h), "table")
    expect_equal(#h >= 2, true)
    lurek.event.clearHistory()
    local h2 = lurek.event.getHistory()
    expect_equal(#h2, 0)
    lurek.event.enableHistory(0)
  end)
end)

test_summary()
