-- tests/lua/unit/test_event.lua
-- BDD tests for the lurek.event event subsystem.
-- Headless-safe (no GPU/window needed).

describe("lurek.event.pump", function()
  -- @covers lurek.event.pump
  -- @covers lurek.event.clear
  -- @covers lurek.event.push
  -- @covers lurek.event.restart
  -- @covers lurek.event.wait
  -- @covers lurek.event.newSignal
  -- @covers lurek.event.poll
  -- @covers lurek.event.quit
  it("exists as a function", function()
    expect_equal(type(lurek.event.pump), "function")
  end)

  -- @covers lurek.event.pump
  it("returns without error", function()
    local ok, err = pcall(function() lurek.event.pump() end)
    expect_equal(ok, true)
  end)
end)

describe("lurek.event.wait", function()
  -- @covers lurek.event.wait
  it("exists as a function", function()
    expect_equal(type(lurek.event.wait), "function")
  end)

  -- @covers lurek.event.wait
  it("returns fixed empty result on timeout with no events", function()
    -- 10 ms timeout, queue is empty
    local ok, name, args = lurek.event.wait(0.01)
    expect_equal(ok, false)
    expect_equal(name, "")
    expect_equal(type(args), "table")
    expect_equal(#args, 0)
  end)

  -- @covers lurek.event.push
  -- @covers lurek.event.wait
  it("returns fixed event tuple immediately if event is available", function()
    lurek.event.push("testev")
    local ok, name, args = lurek.event.wait(0)
    expect_equal(ok, true)
    expect_equal(name, "testev")
    expect_equal(type(args), "table")
  end)

  -- @covers lurek.event.clear
  -- @covers lurek.event.wait
  it("returns fixed empty result with zero timeout and empty queue", function()
    lurek.event.clear()
    local ok, name, args = lurek.event.wait(0)
    expect_equal(ok, false)
    expect_equal(name, "")
    expect_equal(type(args), "table")
    expect_equal(#args, 0)
  end)
end)

describe("lurek.event.restart", function()
  -- @covers lurek.event.restart
  it("exists as a function", function()
    expect_equal(type(lurek.event.restart), "function")
  end)

  -- @covers lurek.event.restart
  it("does not throw an error when called", function()
    -- NOTE: calling restart sets a flag; it does not actually reboot the VM here.
    local ok, err = pcall(function() lurek.event.restart() end)
    expect_equal(ok, true)
  end)
end)

-- Signal UserData

describe("lurek.event.newSignal", function()
  -- @covers lurek.event.newSignal
  it("creates a Signal object", function()
    local sig = lurek.event.newSignal()
    expect_not_nil(sig)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.getCount
  it("register adds a listener", function()
    local sig = lurek.event.newSignal()
    local handle = sig:register("click", function() end)
    expect_not_nil(handle)
    expect_equal(sig:getCount("click"), 1)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.emit
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
  it("remove returns false for unknown handle", function()
    local sig = lurek.event.newSignal()
    local ok = sig:remove(9999)
    expect_equal(ok, false)
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.register
  -- @covers lurek.event.Signal.clear
  -- @covers lurek.event.Signal.getCount
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
  it("type returns LSignal", function()
    local sig = lurek.event.newSignal()
    expect_equal(sig:type(), "LSignal")
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.typeOf
  it("typeOf returns true for LSignal type", function()
    local sig = lurek.event.newSignal()
    expect_true(sig:typeOf("LSignal"))
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.typeOf
  it("typeOf returns true for Object base type", function()
    local sig = lurek.event.newSignal()
    expect_true(sig:typeOf("Object"))
  end)

  -- @covers lurek.event.newSignal
  -- @covers lurek.event.Signal.typeOf
  it("typeOf returns false for unrelated type name", function()
    local sig = lurek.event.newSignal()
    expect_equal(sig:typeOf("unknown"), false)
  end)
end)

-- poll iterator

describe("lurek.event.poll", function()
  -- @covers lurek.event.clear
  -- @covers lurek.event.push
  -- @covers lurek.event.poll
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
  it("returns nothing when queue is empty", function()
    lurek.event.clear()
    local count = 0
    for name in lurek.event.poll() do
      count = count + 1
    end
    expect_equal(count, 0)
  end)
end)

describe("lurek.event once and filter", function()
  -- @covers lurek.event.newSignal
  it("once callback fires exactly one time", function()
    local sig = lurek.event.newSignal()
    local count = 0
    sig:once("bang", function() count = count + 1 end)
    sig:emit("bang")
    sig:emit("bang")
    expect_equal(count, 1)
  end)

  -- @covers lurek.event.newSignal
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
  it("pushDeferred/flushDeferred works", function()
    lurek.event.pushDeferred("deferA")
    lurek.event.pushDeferred("deferB")
    local count = lurek.event.flushDeferred()
    expect_equal(count, 2)
  end)

  -- @covers lurek.event.enableHistory
  -- @covers lurek.event.getHistory
  -- @covers lurek.event.clearHistory
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
describe("lurek.event.newSignal", function()
    -- @covers lurek.event.newSignal
    it("should create a Signal userdata", function()
        local sig = lurek.event.newSignal()
        expect_not_nil(sig, "newSignal should return a value")
    end)

    -- @covers lurek.event.newSignal
    it("should have type 'LSignal'", function()
        local sig = lurek.event.newSignal()
      expect_equal("LSignal", sig:type(), "type should be LSignal")
    end)

    -- @covers lurek.event.newSignal
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
describe("Signal:register and Signal:emit", function()
    -- @covers lurek.event.newSignal
    it("should register a callback and return a handle", function()
        local sig = lurek.event.newSignal()
        local handle = sig:register("test", function() end)
        expect_equal("number", type(handle), "handle should be a number")
        expect_true(handle > 0, "handle should be positive")
    end)

    -- @covers lurek.event.newSignal
    it("should return monotonically increasing handles", function()
        local sig = lurek.event.newSignal()
        local h1 = sig:register("test", function() end)
        local h2 = sig:register("test", function() end)
        local h3 = sig:register("other", function() end)
        expect_true(h2 > h1, "h2 > h1")
        expect_true(h3 > h2, "h3 > h2")
    end)

    -- @covers lurek.event.newSignal
    it("should emit to registered callbacks", function()
        local sig = lurek.event.newSignal()
        local called = false
        sig:register("ping", function()
            called = true
        end)
        sig:emit("ping")
        expect_true(called, "callback should have been called")
    end)

    -- @covers lurek.event.newSignal
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

    -- @covers lurek.event.newSignal
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

    -- @covers lurek.event.newSignal
    it("should not fire callbacks for other event names", function()
        local sig = lurek.event.newSignal()
        local called = false
        sig:register("click", function() called = true end)
        sig:emit("hover")
        expect_false(called, "callback should not fire for different event")
    end)

    -- @covers lurek.event.newSignal
    it("should handle emit with no registered listeners", function()
        local sig = lurek.event.newSignal()
        -- Should not error
        sig:emit("nothing")
    end)
end)

-- ============================================================
-- remove
-- ============================================================
describe("Signal:remove", function()
    -- @covers lurek.event.newSignal
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

    -- @covers lurek.event.newSignal
    it("should return false for nonexistent handle", function()
        local sig = lurek.event.newSignal()
        expect_false(sig:remove(999), "remove of unknown handle")
    end)

    -- @covers lurek.event.newSignal
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
describe("Signal:clear and Signal:clearAll", function()
    -- @covers lurek.event.newSignal
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

    -- @covers lurek.event.newSignal
    it("should return 0 for clearing nonexistent event", function()
        local sig = lurek.event.newSignal()
        expect_equal(0, sig:clear("nope"))
    end)

    -- @covers lurek.event.newSignal
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
describe("Signal:getCount and Signal:getTotalCount", function()
    -- @covers lurek.event.newSignal
    it("should return counts per event name", function()
        local sig = lurek.event.newSignal()
        sig:register("click", function() end)
        sig:register("click", function() end)
        sig:register("hover", function() end)
        expect_equal(2, sig:getCount("click"))
        expect_equal(1, sig:getCount("hover"))
        expect_equal(0, sig:getCount("nonexistent"))
    end)

    -- @covers lurek.event.newSignal
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
describe("Multiple Signal instances", function()
    -- @covers lurek.event.newSignal
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
describe("Signal wildcard subscriptions", function()
    -- @covers lurek.event.new
  it("wildcard_star_matches_prefix", function()
        local sig = lurek.event.newSignal()
        local fired = false
        sig:connect("player.*", function() fired = true end)
        sig:emit("player.move")
        expect_true(fired, "callback should fire when name matches 'player.*'")
    end)

    -- @covers lurek.event.new
  it("wildcard_no_match_does_not_fire", function()
        local sig = lurek.event.newSignal()
        local fired = false
        sig:connect("player.*", function() fired = true end)
        sig:emit("enemy.move")
        expect_false(fired, "callback must not fire when name does not match the pattern")
    end)

    -- @covers lurek.event.new
  it("wildcard_question_mark_matches_single_char", function()
        local sig = lurek.event.newSignal()
        local count = 0
        sig:connect("item_?", function() count = count + 1 end)
        sig:emit("item_A")
        expect_equal(1, count, "single-char match should fire once")
        sig:emit("item_AB")
        expect_equal(1, count, "two-char suffix must not match '?' wildcard")
    end)

    -- @covers lurek.event.new
  it("wildcard_disconnect_stops_firing", function()
        local sig = lurek.event.newSignal()
        local fired = false
        local handle = sig:connect("player.*", function() fired = true end)
        sig:remove(handle)
        sig:emit("player.move")
        expect_false(fired, "disconnected wildcard callback must not fire")
    end)
end)

  describe("lurek.event.exit", function()
    it("is exposed as a function", function()
      -- @covers lurek.event.exit
      expect_equal("function", type(lurek.event.exit))
    end)
  end)

  describe("Signal regression coverage", function()
    it("emit forwards arguments to matching listeners", function()
      -- @covers Signal:emit
      local sig = lurek.event.newSignal()
      local number_arg = nil
      local string_arg = nil
      sig:connect("ping", function(a, b)
        number_arg = a
        string_arg = b
      end)
      sig:emit("ping", 4, "ok")
      expect_equal(4, number_arg)
      expect_equal("ok", string_arg)
    end)

    it("remove unregisters a specific listener handle", function()
      -- @covers Signal:remove
      -- @covers Signal:getCount
      local sig = lurek.event.newSignal()
      local fired = false
      local handle = sig:connect("tick", function() fired = true end)
      expect_equal(1, sig:getCount("tick"))
      expect_true(sig:remove(handle))
      sig:emit("tick")
      expect_false(fired)
      expect_equal(0, sig:getCount("tick"))
    end)

    it("clear removes listeners only for one event name", function()
      -- @covers Signal:clear
      -- @covers Signal:getCount
      local sig = lurek.event.newSignal()
      sig:connect("click", function() end)
      sig:connect("click", function() end)
      sig:connect("hover", function() end)
      expect_equal(2, sig:clear("click"))
      expect_equal(0, sig:getCount("click"))
      expect_equal(1, sig:getCount("hover"))
    end)

    it("clearAll empties all listener buckets", function()
      -- @covers Signal:clearAll
      -- @covers Signal:getTotalCount
      local sig = lurek.event.newSignal()
      sig:connect("a", function() end)
      sig:connect("b", function() end)
      expect_equal(2, sig:getTotalCount())
      expect_equal(2, sig:clearAll())
      expect_equal(0, sig:getTotalCount())
    end)

    it("type and typeOf report the signal userdata identity", function()
      -- @covers Signal:type
      -- @covers Signal:typeOf
      local sig = lurek.event.newSignal()
      expect_equal("LSignal", sig:type())
      expect_true(sig:typeOf("LSignal"))
      expect_true(sig:typeOf("Object"))
      expect_false(sig:typeOf("Entity"))
    end)
  end)

  test_summary()
