-- Signal module Lua tests
-- Tests are headless-safe (no window/GPU/audio needed)

-- ============================================================
-- Signal creation
-- ============================================================
describe("lurek.signal.newSignal", function()
    it("should create a Signal userdata", function()
        local sig = lurek.signal.newSignal()
        expect_not_nil(sig, "newSignal should return a value")
    end)

    it("should have type 'Signal'", function()
        local sig = lurek.signal.newSignal()
        expect_equal("Signal", sig:type(), "type should be Signal")
    end)

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
describe("Signal:register and Signal:emit", function()
    it("should register a callback and return a handle", function()
        local sig = lurek.signal.newSignal()
        local handle = sig:register("test", function() end)
        expect_equal("number", type(handle), "handle should be a number")
        expect_true(handle > 0, "handle should be positive")
    end)

    it("should return monotonically increasing handles", function()
        local sig = lurek.signal.newSignal()
        local h1 = sig:register("test", function() end)
        local h2 = sig:register("test", function() end)
        local h3 = sig:register("other", function() end)
        expect_true(h2 > h1, "h2 > h1")
        expect_true(h3 > h2, "h3 > h2")
    end)

    it("should emit to registered callbacks", function()
        local sig = lurek.signal.newSignal()
        local called = false
        sig:register("ping", function()
            called = true
        end)
        sig:emit("ping")
        expect_true(called, "callback should have been called")
    end)

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

    it("should not fire callbacks for other event names", function()
        local sig = lurek.signal.newSignal()
        local called = false
        sig:register("click", function() called = true end)
        sig:emit("hover")
        expect_false(called, "callback should not fire for different event")
    end)

    it("should handle emit with no registered listeners", function()
        local sig = lurek.signal.newSignal()
        -- Should not error
        sig:emit("nothing")
    end)
end)

-- ============================================================
-- remove
-- ============================================================
describe("Signal:remove", function()
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

    it("should return false for nonexistent handle", function()
        local sig = lurek.signal.newSignal()
        expect_false(sig:remove(999), "remove of unknown handle")
    end)

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
describe("Signal:clear and Signal:clearAll", function()
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

    it("should return 0 for clearing nonexistent event", function()
        local sig = lurek.signal.newSignal()
        expect_equal(0, sig:clear("nope"))
    end)

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
describe("Signal:getCount and Signal:getTotalCount", function()
    it("should return counts per event name", function()
        local sig = lurek.signal.newSignal()
        sig:register("click", function() end)
        sig:register("click", function() end)
        sig:register("hover", function() end)
        expect_equal(2, sig:getCount("click"))
        expect_equal(1, sig:getCount("hover"))
        expect_equal(0, sig:getCount("nonexistent"))
    end)

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
describe("Multiple Signal instances", function()
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

test_summary()
