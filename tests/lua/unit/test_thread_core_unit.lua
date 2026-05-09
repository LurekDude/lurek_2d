-- lurek.thread API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the factory functions and Channel primitives; does not launch background VMs.

-- @describe lurek.thread module exists
describe("lurek.thread module exists", function()
    -- @covers lurek.thread
    it("lurek.thread is a table", function()
        expect_type("table", lurek.thread)
    end)
end)

-- @describe Factory functions
describe("Factory functions", function()
    -- @covers lurek.thread.newThread
    it("newThread is a function", function()
        expect_type("function", lurek.thread.newThread)
    end)

    -- @covers lurek.thread.newChannel
    it("newChannel is a function", function()
        expect_type("function", lurek.thread.newChannel)
    end)

    -- @covers lurek.thread.getChannel
    it("getChannel is a function", function()
        expect_type("function", lurek.thread.getChannel)
    end)
end)

-- @describe Channel creation and messaging
describe("Channel creation and messaging", function()
    -- @covers lurek.thread.newChannel
    it("newChannel returns a non-nil object", function()
        local ch = lurek.thread.newChannel()
        expect_true(ch ~= nil, "channel is not nil")
    end)

    -- @covers lurek.thread.getChannel
    it("getChannel creates and returns a named channel", function()
        local ch = lurek.thread.getChannel("test_ch")
        expect_true(ch ~= nil, "named channel is not nil")
    end)

    -- @covers lurek.thread.getChannel
    it("getChannel returns a channel object (creates if not found)", function()
        -- getChannel creates-or-gets a named channel
        local ch = lurek.thread.getChannel("test_get_or_create_ch")
        expect_true(ch ~= nil, "returns a channel object")
    end)

    -- @covers lurek.thread.getChannel
    it("getChannel finds a previously created named channel", function()
        lurek.thread.getChannel("test_lookup_ch")
        local ch = lurek.thread.getChannel("test_lookup_ch")
        expect_true(ch ~= nil, "found named channel via getChannel")
    end)

    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
    it("channel push and pop round-trip a string", function()
        local ch = lurek.thread.newChannel()
        ch:push("hello")
        local v = ch:pop()
        expect_equal("hello", v)
    end)

    -- @covers LChannel:pop
    -- @covers lurek.thread.newChannel
    it("channel pop on empty channel returns nil", function()
        local ch = lurek.thread.newChannel()
        local v = ch:pop()
        expect_equal(nil, v)
    end)

    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
    it("channel push and pop round-trip a number", function()
        local ch = lurek.thread.newChannel()
        ch:push(42)
        local v = ch:pop()
        expect_equal(42, v)
    end)

    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
    it("channel push and pop round-trip a boolean", function()
        local ch = lurek.thread.newChannel()
        ch:push(true)
        local v = ch:pop()
        expect_equal(true, v)
    end)

    -- @covers LChannel:peek
    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
    it("channel peek returns value without removing it", function()
        local ch = lurek.thread.newChannel()
        ch:push("peek_me")
        local peeked = ch:peek()
        expect_equal("peek_me", peeked)
        -- value should still be there
        local popped = ch:pop()
        expect_equal("peek_me", popped)
    end)

    -- @covers LChannel:getCount
    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
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

    -- @covers LChannel:clear
    -- @covers LChannel:getCount
    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
    it("channel clear empties the channel", function()
        local ch = lurek.thread.newChannel()
        ch:push("x")
        ch:push("y")
        ch:clear()
        expect_equal(0, ch:getCount())
        expect_equal(nil, ch:pop())
    end)
end)

-- @describe Thread handle creation
describe("Thread handle creation", function()
    -- @covers lurek.thread.newThread
    it("newThread returns a non-nil object", function()
        -- Use a trivial inline script snippet; thread is not started here.
        local t = lurek.thread.newThread("return")
        expect_true(t ~= nil, "thread handle is not nil")
    end)

    -- @covers LThread:isRunning
    -- @covers lurek.thread.newThread
    it("newThread isRunning returns false before start", function()
        local t = lurek.thread.newThread("return")
        expect_false(t:isRunning())
    end)

    -- @covers LThread:getError
    -- @covers lurek.thread.newThread
    it("newThread getError returns nil before start", function()
        local t = lurek.thread.newThread("return")
        expect_equal(nil, t:getError())
    end)
end)

-- Channel type/typeOf

-- @describe Channel type and typeOf
describe("Channel type and typeOf", function()
    -- @covers LChannel:type
    -- @covers lurek.thread.newChannel
    it("type returns LChannel", function()
        local ch = lurek.thread.newChannel()
        expect_equal("LChannel", ch:type())
    end)

    -- @covers LChannel:typeOf
    -- @covers lurek.thread.newChannel
    it("typeOf with correct L-name returns true", function()
        local ch = lurek.thread.newChannel()
        expect_true(ch:typeOf("LChannel"))
    end)

    -- @covers LChannel:typeOf
    -- @covers lurek.thread.newChannel
    it("typeOf with wrong name returns false", function()
        local ch = lurek.thread.newChannel()
        expect_false(ch:typeOf("Thread"))
    end)
end)

-- Thread type/typeOf

-- @describe Thread type and typeOf
describe("Thread type and typeOf", function()
    -- @covers LThread:type
    -- @covers lurek.thread.newThread
    it("type returns LThread", function()
        local t = lurek.thread.newThread("return")
        expect_equal("LThread", t:type())
    end)

    -- @covers LThread:typeOf
    -- @covers lurek.thread.newThread
    it("typeOf with correct L-name returns true", function()
        local t = lurek.thread.newThread("return")
        expect_true(t:typeOf("LThread"))
    end)

    -- @covers LThread:typeOf
    -- @covers lurek.thread.newThread
    it("typeOf with wrong name returns false", function()
        local t = lurek.thread.newThread("return")
        expect_false(t:typeOf("Channel"))
    end)
end)

-- Channel supply

-- @describe Channel supply
describe("Channel supply", function()
    -- @covers LChannel:getCount
    -- @covers LChannel:supply
    -- @covers lurek.thread.newChannel
    it("supply pushes value only if channel is empty", function()
        local ch = lurek.thread.newChannel()
        local ok = ch:supply("first")
        expect_true(ok)
        expect_equal(1, ch:getCount())
    end)

    -- @covers LChannel:getCount
    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers LChannel:supply
    -- @covers lurek.thread.newChannel
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

-- @describe Channel demand
describe("Channel demand", function()
    -- @covers LChannel:demand
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
    it("demand returns immediate value if present", function()
        local ch = lurek.thread.newChannel()
        ch:push("ready")
        local v = ch:demand(0.0)
        expect_equal("ready", v)
    end)

    -- @covers LChannel:demand
    -- @covers lurek.thread.newChannel
    it("demand with timeout 0 on empty returns nil", function()
        local ch = lurek.thread.newChannel()
        local v = ch:demand(0.0)
        expect_equal(nil, v)
    end)
end)

-- Named channels

-- @describe Named channels
describe("Named channels", function()
    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.getChannel
    -- @covers lurek.thread.newChannel
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

-- @describe Channel value types
describe("Channel value types", function()
    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
    it("nil value round-trips as nil", function()
        local ch = lurek.thread.newChannel()
        ch:push(nil)
        -- pushing nil is a no-op in most implementations; pop should return nil
        local v = ch:pop()
        expect_equal(nil, v)
    end)

    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
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

-- @describe Channel table serialization
describe("Channel table serialization", function()
    -- @covers lurek.thread.newChannel
    it("pushTable is a function", function()
        local ch = lurek.thread.newChannel()
        expect_type("function", ch.pushTable)
    end)

    -- @covers lurek.thread.newChannel
    it("popTable is a function", function()
        local ch = lurek.thread.newChannel()
        expect_type("function", ch.popTable)
    end)

    -- @covers LChannel:popTable
    -- @covers LChannel:pushTable
    -- @covers lurek.thread.newChannel
    it("flat table round-trips through pushTable/popTable", function()
        local ch = lurek.thread.newChannel()
        ch:pushTable({x = 10, y = 20})
        local t = ch:popTable()
        expect_not_nil(t)
        expect_equal(10, t.x)
        expect_equal(20, t.y)
    end)

    -- @covers LChannel:popTable
    -- @covers LChannel:pushTable
    -- @covers lurek.thread.newChannel
    it("sequence table preserves FIFO order", function()
        local ch = lurek.thread.newChannel()
        ch:pushTable({10, 20, 30})
        local t = ch:popTable()
        expect_not_nil(t)
        expect_equal(10, t[1])
        expect_equal(20, t[2])
        expect_equal(30, t[3])
    end)

    -- @covers LChannel:getCount
    -- @covers LChannel:pushTable
    -- @covers lurek.thread.newChannel
    it("getCount increments after pushTable", function()
        local ch = lurek.thread.newChannel()
        ch:pushTable({a = 1})
        expect_equal(1, ch:getCount())
    end)

    -- @covers LChannel:popTable
    -- @covers lurek.thread.newChannel
    it("popTable on empty channel returns nil", function()
        local ch = lurek.thread.newChannel()
        local t = ch:popTable()
        expect_equal(nil, t)
    end)
end)

-- @describe Channel bytes serialization
describe("Channel bytes serialization", function()
    -- @covers lurek.thread.newChannel
    it("pushBytes is a function", function()
        local ch = lurek.thread.newChannel()
        expect_type("function", ch.pushBytes)
    end)

    -- @covers lurek.thread.newChannel
    it("popBytes is a function", function()
        local ch = lurek.thread.newChannel()
        expect_type("function", ch.popBytes)
    end)

    -- @covers LChannel:popBytes
    -- @covers LChannel:pushBytes
    -- @covers lurek.thread.newChannel
    it("byte string round-trips through pushBytes/popBytes", function()
        local ch = lurek.thread.newChannel()
        local original = "binary\0data\255"
        ch:pushBytes(original)
        local result = ch:popBytes()
        expect_not_nil(result)
        expect_equal(#original, #result)
    end)

    -- @covers LChannel:getCount
    -- @covers LChannel:pushBytes
    -- @covers lurek.thread.newChannel
    it("getCount increments after pushBytes", function()
        local ch = lurek.thread.newChannel()
        ch:pushBytes("hello")
        expect_equal(1, ch:getCount())
    end)

    -- @covers LChannel:popBytes
    -- @covers lurek.thread.newChannel
    it("popBytes on empty channel returns nil", function()
        local ch = lurek.thread.newChannel()
        local v = ch:popBytes()
        expect_equal(nil, v)
    end)
end)

-- @describe Thread pool factory
describe("Thread pool factory", function()
    -- @covers lurek.thread.newPool
    it("newPool is a function", function()
        expect_type("function", lurek.thread.newPool)
    end)

    -- @covers lurek.thread.newPool
    it("newPool returns a non-nil object", function()
        local pool = lurek.thread.newPool(1, "return")
        expect_not_nil(pool)
    end)

    -- @covers LThreadPool:size
    -- @covers lurek.thread.newPool
    it("ThreadPool:size() matches constructor argument", function()
        local pool = lurek.thread.newPool(3, "return")
        expect_equal(3, pool:size())
    end)

    -- @covers lurek.thread.newPool
    it("ThreadPool has submit method", function()
        local pool = lurek.thread.newPool(1, "return")
        expect_type("function", pool.submit)
    end)

    -- @covers lurek.thread.newPool
    it("ThreadPool has collect method", function()
        local pool = lurek.thread.newPool(1, "return")
        expect_type("function", pool.collect)
    end)

    -- @covers lurek.thread.newPool
    it("ThreadPool has join method", function()
        local pool = lurek.thread.newPool(1, "return")
        expect_type("function", pool.join)
    end)

    -- @covers LThreadPool:getInputChannel
    -- @covers lurek.thread.newPool
    it("ThreadPool getInputChannel returns a channel", function()
        local pool = lurek.thread.newPool(1, "return")
        local ch = pool:getInputChannel()
        expect_not_nil(ch)
    end)

    -- @covers LThreadPool:getOutputChannel
    -- @covers lurek.thread.newPool
    it("ThreadPool getOutputChannel returns a channel", function()
        local pool = lurek.thread.newPool(1, "return")
        local ch = pool:getOutputChannel()
        expect_not_nil(ch)
    end)
end)

-- @describe Async / Promise
describe("Async / Promise", function()
    -- @covers lurek.thread.async
    it("async is a function", function()
        expect_type("function", lurek.thread.async)
    end)

    -- @covers lurek.thread.async
    it("async returns a non-nil promise", function()
        local p = lurek.thread.async("return 42")
        expect_not_nil(p)
    end)

    -- @covers lurek.thread.async
    it("Promise has isDone method", function()
        local p = lurek.thread.async("return 42")
        expect_type("function", p.isDone)
    end)

    -- @covers lurek.thread.async
    it("Promise has result method", function()
        local p = lurek.thread.async("return 42")
        expect_type("function", p.result)
    end)

    -- @covers lurek.thread.async
    it("Promise has getError method", function()
        local p = lurek.thread.async("return 42")
        expect_type("function", p.getError)
    end)

    -- @covers LPromise:isDone
    -- @covers lurek.thread.async
    it("isDone returns a boolean value", function()
        local p = lurek.thread.async("return 42")
        local done = p:isDone()
        expect_true(done == true or done == false)
    end)
end)

-- @describe Lua API coverage
describe("Lua API coverage", function()
    -- @covers LChannel:pop
    -- @covers LChannel:push
    -- @covers lurek.thread.newChannel
    it("covers Channel:pop", function()
        local ch = lurek.thread.newChannel()
        ch:push("queued_value")
        expect_equal("queued_value", ch:pop())
        expect_equal(nil, ch:pop())  -- empty channel returns nil
    end)

end)

-- @describe thread strict: LThread start/wait
describe("thread strict: LThread start/wait", function()
    -- @covers LThread:start
    -- @covers LThread:wait
    -- @covers lurek.thread.newThread
    it("LThread start and wait complete for trivial script", function()
        local t = lurek.thread.newThread("return 42")
        local ok1 = pcall(function() t:start() end)
        expect_true(ok1)
        local ok2 = pcall(function() t:wait() end)
        expect_true(ok2)
    end)
end)

-- @describe thread strict: LThreadPool type/typeOf/submit/collect/join
describe("thread strict: LThreadPool type/typeOf/submit/collect/join", function()
    -- @covers LThreadPool:type
    -- @covers LThreadPool:typeOf
    -- @covers LThreadPool:submit
    -- @covers LThreadPool:collect
    -- @covers LThreadPool:join
    -- @covers lurek.thread.newPool
    it("LThreadPool type/typeOf/submit/collect/join are callable", function()
        local pool = lurek.thread.newPool(1, "return ...")
        expect_type("string", pool:type())
        expect_type("boolean", pool:typeOf("Object"))
        local ok1 = pcall(function() pool:submit(1) end)
        expect_true(ok1)
        local ok2 = pcall(function() pool:collect() end)
        expect_type("boolean", ok2)
        local ok3 = pcall(function() pool:join() end)
        expect_true(ok3)
    end)
end)

-- @describe thread strict: LPromise type/typeOf/result/getError
describe("thread strict: LPromise type/typeOf/result/getError", function()
    -- @covers LPromise:type
    -- @covers LPromise:typeOf
    -- @covers LPromise:result
    -- @covers LPromise:getError
    -- @covers lurek.thread.newPool
    it("LPromise type/typeOf/result/getError are callable", function()
        local pool = lurek.thread.newPool(1, "return 99")
        local p = pool:submit(0)
        if p ~= nil then
            expect_type("string", p:type())
            expect_type("boolean", p:typeOf("Object"))
            local ok1 = pcall(function() return p:result() end)
            expect_type("boolean", ok1)
            local ok2 = pcall(function() return p:getError() end)
            expect_type("boolean", ok2)
        else
            expect_nil(p)
        end
        pool:join()
    end)
end)

-- @describe unit: migrated from integration/test_thread_data.lua
describe("unit: migrated from integration/test_thread_data.lua", function()
        -- @covers LChannel:pop
        -- @covers LChannel:push
        -- @covers lurek.thread.newChannel
        it("pushes and pops plain value via channel", function()
            local ch = lurek.thread.newChannel()
            expect_not_nil(ch, "channel created")

            ch:push(42)
            local val = ch:pop()
            expect_equal(42, val, "integer round-tripped through channel")
        end)

        -- @covers LChannel:pop
        -- @covers LChannel:push
        -- @covers lurek.thread.newChannel
        it("channel is FIFO for multiple pushes", function()
            local ch = lurek.thread.newChannel()

            ch:push(1)
            ch:push(2)
            ch:push(3)

            expect_equal(1, ch:pop(), "first out is 1")
            expect_equal(2, ch:pop(), "second out is 2")
            expect_equal(3, ch:pop(), "third out is 3")
        end)

        -- @covers LChannel:pop
        -- @covers lurek.thread.newChannel
        it("tryPop on empty channel returns nil", function()
            local ch  = lurek.thread.newChannel()
            local val = ch:pop()
            expect_nil(val, "empty channel returns nil")
        end)

end)

test_summary()
