-- Signal module Lua tests.
-- Covers signal construction, listener management, dispatch behavior, and headless-safe event helper usage.

-- Tests are headless-safe (no window/GPU/audio needed)

-- ============================================================
-- Signal creation
-- ============================================================
-- @description Covers suite: lurek.signal.newSignal.
describe("lurek.signal.newSignal", function()
    -- @covers lurek.signal.newSignal
    -- @description Verifies newSignal constructs a non-nil userdata handle.
    it("should create a Signal userdata", function()
        local sig = lurek.signal.newSignal()
        expect_not_nil(sig, "newSignal should return a value")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies Signal:type reports the userdata class name.
    it("should have type 'Signal'", function()
        local sig = lurek.signal.newSignal()
        expect_equal("Signal", sig:type(), "type should be Signal")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies Signal:typeOf recognizes Signal and Object while rejecting unrelated types.
    it("should support typeOf check", function()
        local sig = lurek.signal.newSignal()
        expect_true(sig:typeOf("Signal"), "typeOf('Signal') should be true")
        expect_true(sig:typeOf("Object"), "typeOf('Object') should be true")
        expect_false(sig:typeOf("Entity"), "typeOf('Entity') should be false")
    end)
end)

-- ============================================================
-- register / emit
-- ============================================================
-- @description Covers suite: Signal:register and Signal:emit.
describe("Signal:register and Signal:emit", function()
    -- @covers lurek.signal.newSignal
    -- @description Verifies registering a callback returns a positive numeric subscription handle.
    it("should register a callback and return a handle", function()
        local sig = lurek.signal.newSignal()
        local handle = sig:register("test", function() end)
        expect_equal("number", type(handle), "handle should be a number")
        expect_true(handle > 0, "handle should be positive")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies registration handles are monotonically increasing across events.
    it("should return monotonically increasing handles", function()
        local sig = lurek.signal.newSignal()
        local h1 = sig:register("test", function() end)
        local h2 = sig:register("test", function() end)
        local h3 = sig:register("other", function() end)
        expect_true(h2 > h1, "h2 > h1")
        expect_true(h3 > h2, "h3 > h2")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies emit dispatches to listeners registered for the matching event name.
    it("should emit to registered callbacks", function()
        local sig = lurek.signal.newSignal()
        local called = false
        sig:register("ping", function()
            called = true
        end)
        sig:emit("ping")
        expect_true(called, "callback should have been called")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies emit forwards variadic payload arguments to registered callbacks.
    it("should pass extra arguments to callbacks", function()
        local sig = lurek.signal.newSignal()
        local received_a, received_b
        sig:register("data", function(a, b)
            received_a = a
            received_b = b
        end)
        sig:emit("data", 42, "hello")
        expect_equal(42, received_a, "first arg")
        expect_equal("hello", received_b, "second arg")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies listeners fire in registration order for the same event name.
    it("should call multiple callbacks in registration order", function()
        local sig = lurek.signal.newSignal()
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

    -- @covers lurek.signal.newSignal
    -- @description Verifies emit does not dispatch listeners registered under other event names.
    it("should not fire callbacks for other event names", function()
        local sig = lurek.signal.newSignal()
        local called = false
        sig:register("click", function() called = true end)
        sig:emit("hover")
        expect_false(called, "callback should not fire for different event")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies emitting an event with no listeners is a safe no-op.
    it("should handle emit with no registered listeners", function()
        local sig = lurek.signal.newSignal()
        -- Should not error
        sig:emit("nothing")
    end)
end)

-- ============================================================
-- remove
-- ============================================================
-- @description Covers suite: Signal:remove.
describe("Signal:remove", function()
    -- @covers lurek.signal.newSignal
    -- @description Verifies remove detaches a callback by handle so later emits do not invoke it.
    it("should remove a callback by handle", function()
        local sig = lurek.signal.newSignal()
        local count = 0
        local h = sig:register("tick", function() count = count + 1 end)
        sig:emit("tick")
        expect_equal(1, count)

        expect_true(sig:remove(h), "remove should return true")
        sig:emit("tick")
        expect_equal(1, count, "callback should not fire after removal")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies remove returns false when the requested handle is unknown.
    it("should return false for nonexistent handle", function()
        local sig = lurek.signal.newSignal()
        expect_false(sig:remove(999), "remove of unknown handle")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies removing one listener leaves other listeners on the same event intact.
    it("should not affect other callbacks", function()
        local sig = lurek.signal.newSignal()
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
    -- @covers lurek.signal.newSignal
    -- @description Verifies clear removes all listeners for a single event name and reports the removal count.
    it("should clear all callbacks for one event name", function()
        local sig = lurek.signal.newSignal()
        sig:register("click", function() end)
        sig:register("click", function() end)
        sig:register("hover", function() end)
        local removed = sig:clear("click")
        expect_equal(2, removed, "should remove 2 click callbacks")
        expect_equal(0, sig:getCount("click"), "click count should be 0")
        expect_equal(1, sig:getCount("hover"), "hover count unchanged")
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies clear returns zero when asked to remove a missing event bucket.
    it("should return 0 for clearing nonexistent event", function()
        local sig = lurek.signal.newSignal()
        expect_equal(0, sig:clear("nope"))
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies clearAll removes every registered listener across all events.
    it("should clearAll subscriptions", function()
        local sig = lurek.signal.newSignal()
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
    -- @covers lurek.signal.newSignal
    -- @description Verifies getCount reports per-event listener totals and zero for unknown events.
    it("should return counts per event name", function()
        local sig = lurek.signal.newSignal()
        sig:register("click", function() end)
        sig:register("click", function() end)
        sig:register("hover", function() end)
        expect_equal(2, sig:getCount("click"))
        expect_equal(1, sig:getCount("hover"))
        expect_equal(0, sig:getCount("nonexistent"))
    end)

    -- @covers lurek.signal.newSignal
    -- @description Verifies getTotalCount reports the aggregate number of registered listeners.
    it("should return total count", function()
        local sig = lurek.signal.newSignal()
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
    -- @covers lurek.signal.newSignal
    -- @description Verifies separate Signal instances keep isolated listener registries.
    it("should be independent", function()
        local sig1 = lurek.signal.newSignal()
        local sig2 = lurek.signal.newSignal()
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
-- @description Covers suite: Signal wildcard connect/disconnect via lurek.signal.new().
describe("Signal wildcard subscriptions", function()
    -- @covers lurek.signal.new
    -- @description Connects with pattern "player.*", emits "player.move"; verifies callback fires.
    it("wildcard_star_matches_prefix", function()
        local sig = lurek.signal.new()
        local fired = false
        sig:connect("player.*", function() fired = true end)
        sig:emit("player.move")
        expect_true(fired, "callback should fire when name matches 'player.*'")
    end)

    -- @covers lurek.signal.new
    -- @description Connects with pattern "player.*", emits "enemy.move"; verifies callback does NOT fire.
    it("wildcard_no_match_does_not_fire", function()
        local sig = lurek.signal.new()
        local fired = false
        sig:connect("player.*", function() fired = true end)
        sig:emit("enemy.move")
        expect_false(fired, "callback must not fire when name does not match the pattern")
    end)

    -- @covers lurek.signal.new
    -- @description Connects with pattern "item_?"; emits "item_A" (fires) and "item_AB" (does NOT fire).
    it("wildcard_question_mark_matches_single_char", function()
        local sig = lurek.signal.new()
        local count = 0
        sig:connect("item_?", function() count = count + 1 end)
        sig:emit("item_A")
        expect_equal(1, count, "single-char match should fire once")
        sig:emit("item_AB")
        expect_equal(1, count, "two-char suffix must not match '?' wildcard")
    end)

    -- @covers lurek.signal.new
    -- @description Connects as wildcard, disconnects the returned handle, emits; verifies callback is NOT called.
    it("wildcard_disconnect_stops_firing", function()
        local sig = lurek.signal.new()
        local fired = false
        local handle = sig:connect("player.*", function() fired = true end)
        sig:disconnect(handle)
        sig:emit("player.move")
        expect_false(fired, "disconnected wildcard callback must not fire")
    end)
end)

test_summary()
