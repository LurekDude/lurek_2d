-- lurek.thread API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the factory functions and Channel primitives; does not launch background VMs.

describe("lurek.thread module exists", function()
    it("lurek.thread is a table", function()
        expect_type("table", lurek.thread)
    end)
end)

describe("Factory functions", function()
    it("newThread is a function", function()
        expect_type("function", lurek.thread.newThread)
    end)

    it("newChannel is a function", function()
        expect_type("function", lurek.thread.newChannel)
    end)

    it("getChannel is a function", function()
        expect_type("function", lurek.thread.getChannel)
    end)
end)

describe("Channel creation and messaging", function()
    it("newChannel returns a non-nil object", function()
        local ch = lurek.thread.newChannel()
        expect_true(ch ~= nil, "channel is not nil")
    end)

    it("newChannel accepts an optional name", function()
        local ch = lurek.thread.newChannel("test_ch")
        expect_true(ch ~= nil, "named channel is not nil")
    end)

    it("getChannel returns a channel object (creates if not found)", function()
        -- getChannel creates-or-gets a named channel
        local ch = lurek.thread.getChannel("test_get_or_create_ch")
        expect_true(ch ~= nil, "returns a channel object")
    end)

    it("getChannel finds a previously created named channel", function()
        lurek.thread.newChannel("test_lookup_ch")
        local ch = lurek.thread.getChannel("test_lookup_ch")
        expect_true(ch ~= nil, "found named channel via getChannel")
    end)

    it("channel push and pop round-trip a string", function()
        local ch = lurek.thread.newChannel()
        ch:push("hello")
        local v = ch:pop()
        expect_equal("hello", v)
    end)

    it("channel pop on empty channel returns nil", function()
        local ch = lurek.thread.newChannel()
        local v = ch:pop()
        expect_equal(nil, v)
    end)

    it("channel push and pop round-trip a number", function()
        local ch = lurek.thread.newChannel()
        ch:push(42)
        local v = ch:pop()
        expect_equal(42, v)
    end)

    it("channel push and pop round-trip a boolean", function()
        local ch = lurek.thread.newChannel()
        ch:push(true)
        local v = ch:pop()
        expect_equal(true, v)
    end)

    it("channel peek returns value without removing it", function()
        local ch = lurek.thread.newChannel()
        ch:push("peek_me")
        local peeked = ch:peek()
        expect_equal("peek_me", peeked)
        -- value should still be there
        local popped = ch:pop()
        expect_equal("peek_me", popped)
    end)

    it("channel getCount returns correct count", function()
        local ch = lurek.thread.newChannel()
        expect_equal(0, ch:getCount())
        ch:push("a")
        expect_equal(1, ch:getCount())
        ch:push("b")
        expect_equal(2, ch:getCount())
        ch:pop()
        expect_equal(1, ch:getCount())
    end)

    it("channel clear empties the channel", function()
        local ch = lurek.thread.newChannel()
        ch:push("x")
        ch:push("y")
        ch:clear()
        expect_equal(0, ch:getCount())
        expect_equal(nil, ch:pop())
    end)
end)

describe("Thread handle creation", function()
    it("newThread returns a non-nil object", function()
        -- Use a trivial inline script snippet; thread is not started here.
        local t = lurek.thread.newThread("return")
        expect_true(t ~= nil, "thread handle is not nil")
    end)

    it("newThread isRunning returns false before start", function()
        local t = lurek.thread.newThread("return")
        expect_false(t:isRunning())
    end)

    it("newThread getError returns nil before start", function()
        local t = lurek.thread.newThread("return")
        expect_equal(nil, t:getError())
    end)
end)

test_summary()
