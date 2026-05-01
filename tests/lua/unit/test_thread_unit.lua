-- lurek.thread API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the factory functions and Channel primitives; does not launch background VMs.

describe("lurek.thread module exists", function()
    -- @covers lurek.thread.getChannel
    -- @covers lurek.thread.newChannel
    -- @covers lurek.thread.newThread
    -- @covers lurek.thread.Channel.push
    -- @covers lurek.thread.Channel.pop
    -- @covers lurek.thread.Channel.peek
    -- @covers lurek.thread.Channel.demand
    -- @covers lurek.thread.Channel.getCount
    -- @covers lurek.thread.Channel.clear
    -- @covers lurek.thread.Channel.supply
    -- @covers lurek.thread.Channel.type
    -- @covers lurek.thread.Channel.typeOf
    -- @covers lurek.thread.Thread.isRunning
    -- @covers lurek.thread.Thread.getError
    -- @covers lurek.thread.Thread.type
    -- @covers lurek.thread.Thread.typeOf
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

    it("getChannel creates and returns a named channel", function()
        local ch = lurek.thread.getChannel("test_ch")
        expect_true(ch ~= nil, "named channel is not nil")
    end)

    it("getChannel returns a channel object (creates if not found)", function()
        -- getChannel creates-or-gets a named channel
        local ch = lurek.thread.getChannel("test_get_or_create_ch")
        expect_true(ch ~= nil, "returns a channel object")
    end)

    it("getChannel finds a previously created named channel", function()
        lurek.thread.getChannel("test_lookup_ch")
        local ch = lurek.thread.getChannel("test_lookup_ch")
        expect_true(ch ~= nil, "found named channel via getChannel")
    end)

    -- @covers lurek.thread.Channel.push
    -- @covers lurek.thread.Channel.pop
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

-- Channel type/typeOf

describe("Channel type and typeOf", function()
    it("type returns LChannel", function()
        local ch = lurek.thread.newChannel()
        expect_equal("LChannel", ch:type())
    end)

    it("typeOf with correct L-name returns true", function()
        local ch = lurek.thread.newChannel()
        expect_true(ch:typeOf("LChannel"))
    end)

    it("typeOf with wrong name returns false", function()
        local ch = lurek.thread.newChannel()
        expect_false(ch:typeOf("Thread"))
    end)
end)

-- Thread type/typeOf

describe("Thread type and typeOf", function()
    it("type returns LThread", function()
        local t = lurek.thread.newThread("return")
        expect_equal("LThread", t:type())
    end)

    it("typeOf with correct L-name returns true", function()
        local t = lurek.thread.newThread("return")
        expect_true(t:typeOf("LThread"))
    end)

    it("typeOf with wrong name returns false", function()
        local t = lurek.thread.newThread("return")
        expect_false(t:typeOf("Channel"))
    end)
end)

-- Channel supply

describe("Channel supply", function()
    it("supply pushes value only if channel is empty", function()
        local ch = lurek.thread.newChannel()
        local ok = ch:supply("first")
        expect_true(ok)
        expect_equal(1, ch:getCount())
    end)

    it("supply fails if channel already has items", function()
        local ch = lurek.thread.newChannel()
        ch:push("existing")
        local ok = ch:supply("second")
        expect_false(ok)
        expect_equal(1, ch:getCount())
        expect_equal("existing", ch:pop())
    end)
end)

-- Channel demand

describe("Channel demand", function()
    it("demand returns immediate value if present", function()
        local ch = lurek.thread.newChannel()
        ch:push("ready")
        local v = ch:demand(0.0)
        expect_equal("ready", v)
    end)

    it("demand with timeout 0 on empty returns nil", function()
        local ch = lurek.thread.newChannel()
        local v = ch:demand(0.0)
        expect_equal(nil, v)
    end)
end)

-- Named channels

describe("Named channels", function()
    it("getChannel retrieves same channel by name", function()
        local ch1 = lurek.thread.newChannel()
        -- There's no named channel API for anonymous channels;
        -- test getChannel with a name that was passed to newChannel
        local named = lurek.thread.getChannel("test_named_ch")
        expect_not_nil(named)
        local named2 = lurek.thread.getChannel("test_named_ch")
        -- same name returns same channel
        named:push("via_name")
        local v = named2:pop()
        expect_equal("via_name", v)
    end)
end)

-- Multiple value types

describe("Channel value types", function()
    it("nil value round-trips as nil", function()
        local ch = lurek.thread.newChannel()
        ch:push(nil)
        -- pushing nil is a no-op in most implementations; pop should return nil
        local v = ch:pop()
        expect_equal(nil, v)
    end)

    it("multiple values maintain FIFO order", function()
        local ch = lurek.thread.newChannel()
        ch:push(1)
        ch:push(2)
        ch:push(3)
        expect_equal(1, ch:pop())
        expect_equal(2, ch:pop())
        expect_equal(3, ch:pop())
    end)
end)

-- ============================================================
-- Merged from test_thread_new_features.lua
-- ============================================================

describe("Channel table serialization", function()
    it("pushTable is a function", function()
        local ch = lurek.thread.newChannel()
        expect_type("function", ch.pushTable)
    end)

    it("popTable is a function", function()
        local ch = lurek.thread.newChannel()
        expect_type("function", ch.popTable)
    end)

    it("flat table round-trips through pushTable/popTable", function()
        local ch = lurek.thread.newChannel()
        ch:pushTable({x = 10, y = 20})
        local t = ch:popTable()
        expect_not_nil(t)
        expect_equal(10, t.x)
        expect_equal(20, t.y)
    end)

    it("sequence table preserves FIFO order", function()
        local ch = lurek.thread.newChannel()
        ch:pushTable({10, 20, 30})
        local t = ch:popTable()
        expect_not_nil(t)
        expect_equal(10, t[1])
        expect_equal(20, t[2])
        expect_equal(30, t[3])
    end)

    it("getCount increments after pushTable", function()
        local ch = lurek.thread.newChannel()
        ch:pushTable({a = 1})
        expect_equal(1, ch:getCount())
    end)

    it("popTable on empty channel returns nil", function()
        local ch = lurek.thread.newChannel()
        local t = ch:popTable()
        expect_equal(nil, t)
    end)
end)

describe("Channel bytes serialization", function()
    it("pushBytes is a function", function()
        local ch = lurek.thread.newChannel()
        expect_type("function", ch.pushBytes)
    end)

    it("popBytes is a function", function()
        local ch = lurek.thread.newChannel()
        expect_type("function", ch.popBytes)
    end)

    it("byte string round-trips through pushBytes/popBytes", function()
        local ch = lurek.thread.newChannel()
        local original = "binary\0data\255"
        ch:pushBytes(original)
        local result = ch:popBytes()
        expect_not_nil(result)
        expect_equal(#original, #result)
    end)

    it("getCount increments after pushBytes", function()
        local ch = lurek.thread.newChannel()
        ch:pushBytes("hello")
        expect_equal(1, ch:getCount())
    end)

    it("popBytes on empty channel returns nil", function()
        local ch = lurek.thread.newChannel()
        local v = ch:popBytes()
        expect_equal(nil, v)
    end)
end)

describe("Thread pool factory", function()
    it("newPool is a function", function()
        expect_type("function", lurek.thread.newPool)
    end)

    it("newPool returns a non-nil object", function()
        local pool = lurek.thread.newPool(1, "return")
        expect_not_nil(pool)
    end)

    it("ThreadPool:size() matches constructor argument", function()
        local pool = lurek.thread.newPool(3, "return")
        expect_equal(3, pool:size())
    end)

    it("ThreadPool has submit method", function()
        local pool = lurek.thread.newPool(1, "return")
        expect_type("function", pool.submit)
    end)

    it("ThreadPool has collect method", function()
        local pool = lurek.thread.newPool(1, "return")
        expect_type("function", pool.collect)
    end)

    it("ThreadPool has join method", function()
        local pool = lurek.thread.newPool(1, "return")
        expect_type("function", pool.join)
    end)

    it("ThreadPool getInputChannel returns a channel", function()
        local pool = lurek.thread.newPool(1, "return")
        local ch = pool:getInputChannel()
        expect_not_nil(ch)
    end)

    it("ThreadPool getOutputChannel returns a channel", function()
        local pool = lurek.thread.newPool(1, "return")
        local ch = pool:getOutputChannel()
        expect_not_nil(ch)
    end)
end)

describe("Async / Promise", function()
    it("async is a function", function()
        expect_type("function", lurek.thread.async)
    end)

    it("async returns a non-nil promise", function()
        local p = lurek.thread.async("return 42")
        expect_not_nil(p)
    end)

    it("Promise has isDone method", function()
        local p = lurek.thread.async("return 42")
        expect_type("function", p.isDone)
    end)

    it("Promise has result method", function()
        local p = lurek.thread.async("return 42")
        expect_type("function", p.result)
    end)

    it("Promise has getError method", function()
        local p = lurek.thread.async("return 42")
        expect_type("function", p.getError)
    end)

    it("isDone returns a boolean value", function()
        local p = lurek.thread.async("return 42")
        local done = p:isDone()
        expect_true(done == true or done == false)
    end)
end)

describe("Lua API coverage", function()
    -- @covers Channel:pop
    it("covers Channel:pop", function()
        local ch = lurek.thread.newChannel()
        ch:push("queued_value")
        expect_equal("queued_value", ch:pop())
        expect_equal(nil, ch:pop())  -- empty channel returns nil
    end)

end)

test_summary()
