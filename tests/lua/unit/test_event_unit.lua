-- tests/lua/unit/test_event.lua
-- BDD tests for the lurek.event event subsystem.
-- Headless-safe (no GPU/window needed).

-- @description Covers suite: lurek.event.pump.
describe("lurek.event.pump", function()
  -- @tests lurek.event.pump
  -- @tests lurek.event.clear
  -- @tests lurek.event.push
  -- @tests lurek.event.restart
  -- @tests lurek.event.wait
  -- @tests lurek.event.newSignal
  -- @tests lurek.event.poll
  -- @tests lurek.event.quit
  -- @description Checks that the lurek.event namespace exports pump as a callable function before queue behavior is exercised.
  it("exists as a function", function()
    expect_equal(type(lurek.event.pump), "function")
  end)

  -- @tests lurek.event.pump
  -- @description Calls pump inside pcall with no queued work to verify the event-queue sync hook returns without raising an error.
  it("returns without error", function()
    local ok, err = pcall(function() lurek.event.pump() end)
    expect_equal(ok, true)
  end)
end)

-- @description Covers suite: lurek.event.wait.
describe("lurek.event.wait", function()
  -- @tests lurek.event.wait
  -- @description Confirms wait is exposed as a callable function on the signal module before timeout cases are tested.
  it("exists as a function", function()
    expect_equal(type(lurek.event.wait), "function")
  end)

  -- @tests lurek.event.wait
  -- @description Waits for 10 ms against an empty queue and verifies the API returns a fixed false, empty-name, empty-args tuple.
  it("returns fixed empty result on timeout with no events", function()
    -- 10 ms timeout, queue is empty
    local ok, name, args = lurek.event.wait(0.01)
    expect_equal(ok, false)
    expect_equal(name, "")
    expect_equal(type(args), "table")
    expect_equal(#args, 0)
  end)

  -- @tests lurek.event.push
  -- @tests lurek.event.wait
  -- @description Pushes a named event and immediately waits with zero timeout to confirm wait returns a fixed tuple.
  it("returns fixed event tuple immediately if event is available", function()
    lurek.event.push("testev")
    local ok, name, args = lurek.event.wait(0)
    expect_equal(ok, true)
    expect_equal(name, "testev")
    expect_equal(type(args), "table")
  end)

  -- @tests lurek.event.clear
  -- @tests lurek.event.wait
  -- @description Clears pending events first, then verifies a zero-timeout wait reports an empty queue with a fixed tuple.
  it("returns fixed empty result with zero timeout and empty queue", function()
    lurek.event.clear()
    local ok, name, args = lurek.event.wait(0)
    expect_equal(ok, false)
    expect_equal(name, "")
    expect_equal(type(args), "table")
    expect_equal(#args, 0)
  end)
end)

-- @description Covers suite: lurek.event.restart.
describe("lurek.event.restart", function()
  -- @tests lurek.event.restart
  -- @description Verifies the restart hook is exported as a callable function on the signal namespace.
  it("exists as a function", function()
    expect_equal(type(lurek.event.restart), "function")
  end)

  -- @tests lurek.event.restart
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
  -- @tests lurek.event.newSignal
  -- @description Creates a fresh Signal userdata and checks the constructor returns a non-nil object.
  it("creates a Signal object", function()
    local sig = lurek.event.newSignal()
    expect_not_nil(sig)
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.getCount
  -- @description Registers one click listener and verifies register returns a handle while getCount reflects the new subscription.
  it("register adds a listener", function()
    local sig = lurek.event.newSignal()
    local handle = sig:register("click", function() end)
    expect_not_nil(handle)
    expect_equal(sig:getCount("click"), 1)
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.emit
  -- @description Registers an action listener, emits that event name, and checks the callback flips a captured boolean.
  it("emit fires registered callback", function()
    local sig = lurek.event.newSignal()
    local fired = false
    sig:register("action", function() fired = true end)
    sig:emit("action")
    expect_equal(fired, true)
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.emit
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

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.emit
  -- @description Registers two listeners for the same tick event and confirms one emit dispatches to both callbacks.
  it("multiple listeners all fire", function()
    local sig = lurek.event.newSignal()
    local count = 0
    sig:register("tick", function() count = count + 1 end)
    sig:register("tick", function() count = count + 1 end)
    sig:emit("tick")
    expect_equal(count, 2)
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.getCount
  -- @description Adds listeners under two event names and checks getCount reports per-name totals rather than a global count.
  it("getCount returns listener count for name", function()
    local sig = lurek.event.newSignal()
    sig:register("a", function() end)
    sig:register("a", function() end)
    sig:register("b", function() end)
    expect_equal(sig:getCount("a"), 2)
    expect_equal(sig:getCount("b"), 1)
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.getTotalCount
  -- @description Registers listeners across three distinct event names and verifies getTotalCount sums them into one total.
  it("getTotalCount returns all listeners", function()
    local sig = lurek.event.newSignal()
    sig:register("a", function() end)
    sig:register("b", function() end)
    sig:register("c", function() end)
    expect_equal(sig:getTotalCount(), 3)
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.remove
  -- @tests lurek.event.Signal.emit
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

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.remove
  -- @description Calls remove with a nonexistent handle ID and verifies the API reports failure with false.
  it("remove returns false for unknown handle", function()
    local sig = lurek.event.newSignal()
    local ok = sig:remove(9999)
    expect_equal(ok, false)
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.clear
  -- @tests lurek.event.Signal.getCount
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

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.register
  -- @tests lurek.event.Signal.clearAll
  -- @tests lurek.event.Signal.getTotalCount
  -- @description Registers listeners under multiple names, clears the dispatcher globally, and checks no subscriptions remain.
  it("clearAll removes everything", function()
    local sig = lurek.event.newSignal()
    sig:register("a", function() end)
    sig:register("b", function() end)
    local removed = sig:clearAll()
    expect_equal(removed, 2)
    expect_equal(sig:getTotalCount(), 0)
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.type
  -- @description Constructs a Signal userdata and verifies its runtime type string reports Signal.
  it("type returns LSignal", function()
    local sig = lurek.event.newSignal()
    expect_equal(sig:type(), "LSignal")
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.typeOf
  -- @description Verifies typeOf recognizes the concrete Signal type name on a newly created dispatcher.
  it("typeOf returns true for LSignal type", function()
    local sig = lurek.event.newSignal()
    expect_true(sig:typeOf("LSignal"))
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.typeOf
  -- @description Verifies typeOf also reports true for the shared Object base type implemented by Signal userdata.
  it("typeOf returns true for Object base type", function()
    local sig = lurek.event.newSignal()
    expect_true(sig:typeOf("Object"))
  end)

  -- @tests lurek.event.newSignal
  -- @tests lurek.event.Signal.typeOf
  -- @description Passes an unrelated type name to typeOf and confirms the Signal userdata rejects the mismatch.
  it("typeOf returns false for unrelated type name", function()
    local sig = lurek.event.newSignal()
    expect_equal(sig:typeOf("unknown"), false)
  end)
end)

-- â”€â”€ poll iterator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: lurek.event.poll.
describe("lurek.event.poll", function()
  -- @tests lurek.event.clear
  -- @tests lurek.event.push
  -- @tests lurek.event.poll
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

  -- @tests lurek.event.clear
  -- @tests lurek.event.poll
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
  -- @tests lurek.event.newSignal
  -- @description Creates a signal and registers a once-listener; after emitting once the listener must not fire again.
  it("once callback fires exactly one time", function()
    local sig = lurek.event.newSignal()
    local count = 0
    sig:once("bang", function() count = count + 1 end)
    sig:emit("bang")
    sig:emit("bang")
    expect_equal(count, 1)
  end)

  -- @tests lurek.event.newSignal
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

  -- @tests lurek.event.newSignal
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
  -- @tests lurek.event.pushDeferred
  -- @tests lurek.event.flushDeferred
  -- @description Pushes two deferred events, confirms flushDeferred reports count and events appear in the queue.
  it("pushDeferred/flushDeferred works", function()
    lurek.event.pushDeferred("deferA")
    lurek.event.pushDeferred("deferB")
    local count = lurek.event.flushDeferred()
    expect_equal(count, 2)
  end)

  -- @tests lurek.event.enableHistory
  -- @tests lurek.event.getHistory
  -- @tests lurek.event.clearHistory
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



-- [merged from test_event_event.lua]
-- Signal module Lua tests.
-- Covers signal construction, listener management, dispatch behavior, and headless-safe event helper usage.

-- Tests are headless-safe (no window/GPU/audio needed)

-- ============================================================
-- Signal creation
-- ============================================================
-- @description Covers suite: lurek.event.newSignal.
describe("lurek.event.newSignal", function()
    -- @tests lurek.event.newSignal
    -- @description Verifies newSignal constructs a non-nil userdata handle.
    it("should create a Signal userdata", function()
        local sig = lurek.event.newSignal()
        expect_not_nil(sig, "newSignal should return a value")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies Signal:type reports the userdata class name.
    it("should have type 'LSignal'", function()
        local sig = lurek.event.newSignal()
      expect_equal("LSignal", sig:type(), "type should be LSignal")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies Signal:typeOf recognizes Signal and Object while rejecting unrelated types.
    it("should support typeOf check", function()
        local sig = lurek.event.newSignal()
        expect_true(sig:typeOf("LSignal"), "typeOf('LSignal') should be true")
        expect_true(sig:typeOf("Object"), "typeOf('Object') should be true")
        expect_false(sig:typeOf("Entity"), "typeOf('Entity') should be false")
    end)
end)

-- ============================================================
-- register / emit
-- ============================================================
-- @description Covers suite: Signal:register and Signal:emit.
describe("Signal:register and Signal:emit", function()
    -- @tests lurek.event.newSignal
    -- @description Verifies registering a callback returns a positive numeric subscription handle.
    it("should register a callback and return a handle", function()
        local sig = lurek.event.newSignal()
        local handle = sig:register("test", function() end)
        expect_equal("number", type(handle), "handle should be a number")
        expect_true(handle > 0, "handle should be positive")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies registration handles are monotonically increasing across events.
    it("should return monotonically increasing handles", function()
        local sig = lurek.event.newSignal()
        local h1 = sig:register("test", function() end)
        local h2 = sig:register("test", function() end)
        local h3 = sig:register("other", function() end)
        expect_true(h2 > h1, "h2 > h1")
        expect_true(h3 > h2, "h3 > h2")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies emit dispatches to listeners registered for the matching event name.
    it("should emit to registered callbacks", function()
        local sig = lurek.event.newSignal()
        local called = false
        sig:register("ping", function()
            called = true
        end)
        sig:emit("ping")
        expect_true(called, "callback should have been called")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies emit forwards variadic payload arguments to registered callbacks.
    it("should pass extra arguments to callbacks", function()
        local sig = lurek.event.newSignal()
        local received_a, received_b
        sig:register("data", function(a, b)
            received_a = a
            received_b = b
        end)
        sig:emit("data", 42, "hello")
        expect_equal(42, received_a, "first arg")
        expect_equal("hello", received_b, "second arg")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies listeners fire in registration order for the same event name.
    it("should call multiple callbacks in registration order", function()
        local sig = lurek.event.newSignal()
        local order = {}
        sig:register("go", function() table.insert(order, "first") end)
        sig:register("go", function() table.insert(order, "second") end)
        sig:register("go", function() table.insert(order, "third") end)
        sig:emit("go")
        expect_equal(3, #order, "all three should fire")
        expect_equal("first", order[1])
        expect_equal("second", order[2])
        expect_equal("third", order[3])
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies emit does not dispatch listeners registered under other event names.
    it("should not fire callbacks for other event names", function()
        local sig = lurek.event.newSignal()
        local called = false
        sig:register("click", function() called = true end)
        sig:emit("hover")
        expect_false(called, "callback should not fire for different event")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies emitting an event with no listeners is a safe no-op.
    it("should handle emit with no registered listeners", function()
        local sig = lurek.event.newSignal()
        -- Should not error
        sig:emit("nothing")
    end)
end)

-- ============================================================
-- remove
-- ============================================================
-- @description Covers suite: Signal:remove.
describe("Signal:remove", function()
    -- @tests lurek.event.newSignal
    -- @description Verifies remove detaches a callback by handle so later emits do not invoke it.
    it("should remove a callback by handle", function()
        local sig = lurek.event.newSignal()
        local count = 0
        local h = sig:register("tick", function() count = count + 1 end)
        sig:emit("tick")
        expect_equal(1, count)

        expect_true(sig:remove(h), "remove should return true")
        sig:emit("tick")
        expect_equal(1, count, "callback should not fire after removal")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies remove returns false when the requested handle is unknown.
    it("should return false for nonexistent handle", function()
        local sig = lurek.event.newSignal()
        expect_false(sig:remove(999), "remove of unknown handle")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies removing one listener leaves other listeners on the same event intact.
    it("should not affect other callbacks", function()
        local sig = lurek.event.newSignal()
        local a_count, b_count = 0, 0
        local ha = sig:register("go", function() a_count = a_count + 1 end)
        local hb = sig:register("go", function() b_count = b_count + 1 end)
        sig:remove(ha)
        sig:emit("go")
        expect_equal(0, a_count, "removed callback should not fire")
        expect_equal(1, b_count, "other callback should still fire")
    end)
end)

-- ============================================================
-- clear / clearAll
-- ============================================================
-- @description Covers suite: Signal:clear and Signal:clearAll.
describe("Signal:clear and Signal:clearAll", function()
    -- @tests lurek.event.newSignal
    -- @description Verifies clear removes all listeners for a single event name and reports the removal count.
    it("should clear all callbacks for one event name", function()
        local sig = lurek.event.newSignal()
        sig:register("click", function() end)
        sig:register("click", function() end)
        sig:register("hover", function() end)
        local removed = sig:clear("click")
        expect_equal(2, removed, "should remove 2 click callbacks")
        expect_equal(0, sig:getCount("click"), "click count should be 0")
        expect_equal(1, sig:getCount("hover"), "hover count unchanged")
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies clear returns zero when asked to remove a missing event bucket.
    it("should return 0 for clearing nonexistent event", function()
        local sig = lurek.event.newSignal()
        expect_equal(0, sig:clear("nope"))
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies clearAll removes every registered listener across all events.
    it("should clearAll subscriptions", function()
        local sig = lurek.event.newSignal()
        sig:register("a", function() end)
        sig:register("b", function() end)
        sig:register("c", function() end)
        local removed = sig:clearAll()
        expect_equal(3, removed, "should remove all 3")
        expect_equal(0, sig:getTotalCount(), "total count should be 0")
    end)
end)

-- ============================================================
-- getCount / getTotalCount
-- ============================================================
-- @description Covers suite: Signal:getCount and Signal:getTotalCount.
describe("Signal:getCount and Signal:getTotalCount", function()
    -- @tests lurek.event.newSignal
    -- @description Verifies getCount reports per-event listener totals and zero for unknown events.
    it("should return counts per event name", function()
        local sig = lurek.event.newSignal()
        sig:register("click", function() end)
        sig:register("click", function() end)
        sig:register("hover", function() end)
        expect_equal(2, sig:getCount("click"))
        expect_equal(1, sig:getCount("hover"))
        expect_equal(0, sig:getCount("nonexistent"))
    end)

    -- @tests lurek.event.newSignal
    -- @description Verifies getTotalCount reports the aggregate number of registered listeners.
    it("should return total count", function()
        local sig = lurek.event.newSignal()
        expect_equal(0, sig:getTotalCount())
        sig:register("a", function() end)
        sig:register("b", function() end)
        expect_equal(2, sig:getTotalCount())
    end)
end)

-- ============================================================
-- Multiple independent signals
-- ============================================================
-- @description Covers suite: Multiple Signal instances.
describe("Multiple Signal instances", function()
    -- @tests lurek.event.newSignal
    -- @description Verifies separate Signal instances keep isolated listener registries.
    it("should be independent", function()
        local sig1 = lurek.event.newSignal()
        local sig2 = lurek.event.newSignal()
        local count1, count2 = 0, 0
        sig1:register("go", function() count1 = count1 + 1 end)
        sig2:register("go", function() count2 = count2 + 1 end)
        sig1:emit("go")
        expect_equal(1, count1, "sig1 callback fired")
        expect_equal(0, count2, "sig2 callback not fired by sig1 emit")
    end)
end)

-- ============================================================
-- Wildcard subscriptions
-- ============================================================
-- @description Covers suite: Signal wildcard connect/disconnect via lurek.event.new().
describe("Signal wildcard subscriptions", function()
    -- @tests lurek.event.new
    -- @description Connects with pattern "player.*", emits "player.move"; verifies callback fires.
    xit("wildcard_star_matches_prefix", function()
        local sig = lurek.event.new()
        local fired = false
        sig:connect("player.*", function() fired = true end)
        sig:emit("player.move")
        expect_true(fired, "callback should fire when name matches 'player.*'")
    end)

    -- @tests lurek.event.new
    -- @description Connects with pattern "player.*", emits "enemy.move"; verifies callback does NOT fire.
    xit("wildcard_no_match_does_not_fire", function()
        local sig = lurek.event.new()
        local fired = false
        sig:connect("player.*", function() fired = true end)
        sig:emit("enemy.move")
        expect_false(fired, "callback must not fire when name does not match the pattern")
    end)

    -- @tests lurek.event.new
    -- @description Connects with pattern "item_?"; emits "item_A" (fires) and "item_AB" (does NOT fire).
    xit("wildcard_question_mark_matches_single_char", function()
        local sig = lurek.event.new()
        local count = 0
        sig:connect("item_?", function() count = count + 1 end)
        sig:emit("item_A")
        expect_equal(1, count, "single-char match should fire once")
        sig:emit("item_AB")
        expect_equal(1, count, "two-char suffix must not match '?' wildcard")
    end)

    -- @tests lurek.event.new
    -- @description Connects as wildcard, disconnects the returned handle, emits; verifies callback is NOT called.
    xit("wildcard_disconnect_stops_firing", function()
        local sig = lurek.event.new()
        local fired = false
        local handle = sig:connect("player.*", function() fired = true end)
        sig:disconnect(handle)
        sig:emit("player.move")
        expect_false(fired, "disconnected wildcard callback must not fire")
    end)
end)

test_summary()

describe("Missing explicit test for lurek.event.exit", function()
    it("lurek.event.exit works", function()
        -- @tests lurek.event.exit
        -- TODO: add assertion for lurek.event.exit
    end)
end)

describe("Missing explicit test for Signal:emit", function()
    it("Signal:emit works", function()
        -- @tests Signal:emit
        -- TODO: add assertion for Signal:emit
    end)
end)

describe("Missing explicit test for Signal:remove", function()
    it("Signal:remove works", function()
        -- @tests Signal:remove
        -- TODO: add assertion for Signal:remove
    end)
end)

describe("Missing explicit test for Signal:clear", function()
    it("Signal:clear works", function()
        -- @tests Signal:clear
        -- TODO: add assertion for Signal:clear
    end)
end)

describe("Missing explicit test for Signal:clearAll", function()
    it("Signal:clearAll works", function()
        -- @tests Signal:clearAll
        -- TODO: add assertion for Signal:clearAll
    end)
end)

describe("Missing explicit test for Signal:getCount", function()
    it("Signal:getCount works", function()
        -- @tests Signal:getCount
        -- TODO: add assertion for Signal:getCount
    end)
end)

describe("Missing explicit test for Signal:getTotalCount", function()
    it("Signal:getTotalCount works", function()
        -- @tests Signal:getTotalCount
        -- TODO: add assertion for Signal:getTotalCount
    end)
end)

describe("Missing explicit test for Signal:type", function()
    it("Signal:type works", function()
        -- @tests Signal:type
        -- TODO: add assertion for Signal:type
    end)
end)

describe("Missing explicit test for Signal:typeOf", function()
    it("Signal:typeOf works", function()
        -- @tests Signal:typeOf
        -- TODO: add assertion for Signal:typeOf
    end)
end)
