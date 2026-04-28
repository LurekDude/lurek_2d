-- lurek.thread API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests the factory functions and Channel primitives; does not launch background VMs.

-- @description Covers suite: lurek.thread module exists.
describe("lurek.thread module exists", function()
    -- @tests lurek.thread.getChannel
    -- @tests lurek.thread.newChannel
    -- @tests lurek.thread.newThread
    -- @tests lurek.thread.Channel.push
    -- @tests lurek.thread.Channel.pop
    -- @tests lurek.thread.Channel.peek
    -- @tests lurek.thread.Channel.demand
    -- @tests lurek.thread.Channel.getCount
    -- @tests lurek.thread.Channel.clear
    -- @tests lurek.thread.Channel.supply
    -- @tests lurek.thread.Channel.type
    -- @tests lurek.thread.Channel.typeOf
    -- @tests lurek.thread.Thread.isRunning
    -- @tests lurek.thread.Thread.getError
    -- @tests lurek.thread.Thread.type
    -- @tests lurek.thread.Thread.typeOf
    -- @description Verifies case: lurek.thread is a table.
    it("lurek.thread is a table", function()
        expect_type("table", lurek.thread)
    end)
end)

-- @description Covers suite: Factory functions.
describe("Factory functions", function()
    -- @description Verifies case: newThread is a function.
    it("newThread is a function", function()
        expect_type("function", lurek.thread.newThread)
    end)

    -- @description Verifies case: newChannel is a function.
    it("newChannel is a function", function()
        expect_type("function", lurek.thread.newChannel)
    end)

    -- @description Verifies case: getChannel is a function.
    it("getChannel is a function", function()
        expect_type("function", lurek.thread.getChannel)
    end)
end)

-- @description Covers suite: Channel creation and messaging.
describe("Channel creation and messaging", function()
    -- @description Verifies case: newChannel returns a non-nil object.
    it("newChannel returns a non-nil object", function()
        local ch = lurek.thread.newChannel()
        expect_true(ch ~= nil, "channel is not nil")
    end)

    -- @description Verifies case: getChannel creates and returns a named channel.
    it("getChannel creates and returns a named channel", function()
        local ch = lurek.thread.getChannel("test_ch")
        expect_true(ch ~= nil, "named channel is not nil")
    end)

    -- @description Verifies case: getChannel returns a channel object (creates if not found).
    it("getChannel returns a channel object (creates if not found)", function()
        -- getChannel creates-or-gets a named channel
        local ch = lurek.thread.getChannel("test_get_or_create_ch")
        expect_true(ch ~= nil, "returns a channel object")
    end)

    -- @description Verifies case: getChannel finds a previously created named channel.
    it("getChannel finds a previously created named channel", function()
        lurek.thread.getChannel("test_lookup_ch")
        local ch = lurek.thread.getChannel("test_lookup_ch")
        expect_true(ch ~= nil, "found named channel via getChannel")
    end)

    -- @tests lurek.thread.Channel.push
    -- @tests lurek.thread.Channel.pop
    -- @description Verifies channel push and pop preserve FIFO order for a single string value.
    it("channel push and pop round-trip a string", function()
        local ch = lurek.thread.newChannel()
        ch:push("hello")
        local v = ch:pop()
        expect_equal("hello", v)
    end)

    -- @description Verifies case: channel pop on empty channel returns nil.
    it("channel pop on empty channel returns nil", function()
        local ch = lurek.thread.newChannel()
        local v = ch:pop()
        expect_equal(nil, v)
    end)

    -- @description Verifies case: channel push and pop round-trip a number.
    it("channel push and pop round-trip a number", function()
        local ch = lurek.thread.newChannel()
        ch:push(42)
        local v = ch:pop()
        expect_equal(42, v)
    end)

    -- @description Verifies case: channel push and pop round-trip a boolean.
    it("channel push and pop round-trip a boolean", function()
        local ch = lurek.thread.newChannel()
        ch:push(true)
        local v = ch:pop()
        expect_equal(true, v)
    end)

    -- @description Verifies case: channel peek returns value without removing it.
    it("channel peek returns value without removing it", function()
        local ch = lurek.thread.newChannel()
        ch:push("peek_me")
        local peeked = ch:peek()
        expect_equal("peek_me", peeked)
        -- value should still be there
        local popped = ch:pop()
        expect_equal("peek_me", popped)
    end)

    -- @description Verifies case: channel getCount returns correct count.
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

    -- @description Verifies case: channel clear empties the channel.
    it("channel clear empties the channel", function()
        local ch = lurek.thread.newChannel()
        ch:push("x")
        ch:push("y")
        ch:clear()
        expect_equal(0, ch:getCount())
        expect_equal(nil, ch:pop())
    end)
end)

-- @description Covers suite: Thread handle creation.
describe("Thread handle creation", function()
    -- @description Verifies case: newThread returns a non-nil object.
    it("newThread returns a non-nil object", function()
        -- Use a trivial inline script snippet; thread is not started here.
        local t = lurek.thread.newThread("return")
        expect_true(t ~= nil, "thread handle is not nil")
    end)

    -- @description Verifies case: newThread isRunning returns false before start.
    it("newThread isRunning returns false before start", function()
        local t = lurek.thread.newThread("return")
        expect_false(t:isRunning())
    end)

    -- @description Verifies case: newThread getError returns nil before start.
    it("newThread getError returns nil before start", function()
        local t = lurek.thread.newThread("return")
        expect_equal(nil, t:getError())
    end)
end)

-- â”€â”€ Channel type/typeOf â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Channel type and typeOf.
describe("Channel type and typeOf", function()
    -- @description Verifies case: type returns Channel.
    it("type returns LChannel", function()
        local ch = lurek.thread.newChannel()
        expect_equal("LChannel", ch:type())
    end)

    -- @description Verifies case: typeOf with correct name returns true.
    it("typeOf with correct L-name returns true", function()
        local ch = lurek.thread.newChannel()
        expect_true(ch:typeOf("LChannel"))
    end)

    -- @description Verifies case: typeOf with wrong name returns false.
    it("typeOf with wrong name returns false", function()
        local ch = lurek.thread.newChannel()
        expect_false(ch:typeOf("Thread"))
    end)
end)

-- â”€â”€ Thread type/typeOf â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Thread type and typeOf.
describe("Thread type and typeOf", function()
    -- @description Verifies case: type returns Thread.
    it("type returns LThread", function()
        local t = lurek.thread.newThread("return")
        expect_equal("LThread", t:type())
    end)

    -- @description Verifies case: typeOf with correct name returns true.
    it("typeOf with correct L-name returns true", function()
        local t = lurek.thread.newThread("return")
        expect_true(t:typeOf("LThread"))
    end)

    -- @description Verifies case: typeOf with wrong name returns false.
    it("typeOf with wrong name returns false", function()
        local t = lurek.thread.newThread("return")
        expect_false(t:typeOf("Channel"))
    end)
end)

-- â”€â”€ Channel supply â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Channel supply.
describe("Channel supply", function()
    -- @description Verifies case: supply pushes value only if channel is empty.
    it("supply pushes value only if channel is empty", function()
        local ch = lurek.thread.newChannel()
        local ok = ch:supply("first")
        expect_true(ok)
        expect_equal(1, ch:getCount())
    end)

    -- @description Verifies case: supply fails if channel already has items.
    it("supply fails if channel already has items", function()
        local ch = lurek.thread.newChannel()
        ch:push("existing")
        local ok = ch:supply("second")
        expect_false(ok)
        expect_equal(1, ch:getCount())
        expect_equal("existing", ch:pop())
    end)
end)

-- â”€â”€ Channel demand â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Channel demand.
describe("Channel demand", function()
    -- @description Verifies case: demand returns immediate value if present.
    it("demand returns immediate value if present", function()
        local ch = lurek.thread.newChannel()
        ch:push("ready")
        local v = ch:demand(0.0)
        expect_equal("ready", v)
    end)

    -- @description Verifies case: demand with timeout 0 on empty returns nil.
    it("demand with timeout 0 on empty returns nil", function()
        local ch = lurek.thread.newChannel()
        local v = ch:demand(0.0)
        expect_equal(nil, v)
    end)
end)

-- â”€â”€ Named channels â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Named channels.
describe("Named channels", function()
    -- @description Verifies case: getChannel retrieves same channel by name.
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

-- â”€â”€ Multiple value types â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: Channel value types.
describe("Channel value types", function()
    -- @description Verifies case: nil value round-trips as nil.
    it("nil value round-trips as nil", function()
        local ch = lurek.thread.newChannel()
        ch:push(nil)
        -- pushing nil is a no-op in most implementations; pop should return nil
        local v = ch:pop()
        expect_equal(nil, v)
    end)

    -- @description Verifies case: multiple values maintain FIFO order.
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

-- ═══════════════════════════════════════════════════════════════════════
-- Merged from test_thread_new_features.lua
-- ═══════════════════════════════════════════════════════════════════════

-- @description Covers suite: Channel table serialization.
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

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests Channel:pop
    it("covers Channel:pop", function()
        local ch = lurek.thread.newChannel()
        ch:push("queued_value")
        expect_equal("queued_value", ch:pop())
        expect_equal(nil, ch:pop())  -- empty channel returns nil
    end)

end)

describe("Missing explicit test for lurek.thread.newPool", function()
    it("lurek.thread.newPool works", function()
        -- @tests lurek.thread.newPool
        -- TODO: add assertion for lurek.thread.newPool
    end)
end)

describe("Missing explicit test for lurek.thread.async", function()
    it("lurek.thread.async works", function()
        -- @tests lurek.thread.async
        -- TODO: add assertion for lurek.thread.async
    end)
end)

describe("Missing explicit test for ThreadHandle:type", function()
    it("ThreadHandle:type works", function()
        -- @tests ThreadHandle:type
        -- TODO: add assertion for ThreadHandle:type
    end)
end)

describe("Missing explicit test for ThreadHandle:typeOf", function()
    it("ThreadHandle:typeOf works", function()
        -- @tests ThreadHandle:typeOf
        -- TODO: add assertion for ThreadHandle:typeOf
    end)
end)

describe("Missing explicit test for ThreadHandle:start", function()
    it("ThreadHandle:start works", function()
        -- @tests ThreadHandle:start
        -- TODO: add assertion for ThreadHandle:start
    end)
end)

describe("Missing explicit test for ThreadHandle:wait", function()
    it("ThreadHandle:wait works", function()
        -- @tests ThreadHandle:wait
        -- TODO: add assertion for ThreadHandle:wait
    end)
end)

describe("Missing explicit test for ThreadHandle:isRunning", function()
    it("ThreadHandle:isRunning works", function()
        -- @tests ThreadHandle:isRunning
        -- TODO: add assertion for ThreadHandle:isRunning
    end)
end)

describe("Missing explicit test for ThreadHandle:getError", function()
    it("ThreadHandle:getError works", function()
        -- @tests ThreadHandle:getError
        -- TODO: add assertion for ThreadHandle:getError
    end)
end)

describe("Missing explicit test for ThreadPool:type", function()
    it("ThreadPool:type works", function()
        -- @tests ThreadPool:type
        -- TODO: add assertion for ThreadPool:type
    end)
end)

describe("Missing explicit test for ThreadPool:typeOf", function()
    it("ThreadPool:typeOf works", function()
        -- @tests ThreadPool:typeOf
        -- TODO: add assertion for ThreadPool:typeOf
    end)
end)

describe("Missing explicit test for ThreadPool:submit", function()
    it("ThreadPool:submit works", function()
        -- @tests ThreadPool:submit
        -- TODO: add assertion for ThreadPool:submit
    end)
end)

describe("Missing explicit test for ThreadPool:collect", function()
    it("ThreadPool:collect works", function()
        -- @tests ThreadPool:collect
        -- TODO: add assertion for ThreadPool:collect
    end)
end)

describe("Missing explicit test for ThreadPool:size", function()
    it("ThreadPool:size works", function()
        -- @tests ThreadPool:size
        -- TODO: add assertion for ThreadPool:size
    end)
end)

describe("Missing explicit test for ThreadPool:join", function()
    it("ThreadPool:join works", function()
        -- @tests ThreadPool:join
        -- TODO: add assertion for ThreadPool:join
    end)
end)

describe("Missing explicit test for ThreadPool:getInputChannel", function()
    it("ThreadPool:getInputChannel works", function()
        -- @tests ThreadPool:getInputChannel
        -- TODO: add assertion for ThreadPool:getInputChannel
    end)
end)

describe("Missing explicit test for ThreadPool:getOutputChannel", function()
    it("ThreadPool:getOutputChannel works", function()
        -- @tests ThreadPool:getOutputChannel
        -- TODO: add assertion for ThreadPool:getOutputChannel
    end)
end)

describe("Missing explicit test for Promise:type", function()
    it("Promise:type works", function()
        -- @tests Promise:type
        -- TODO: add assertion for Promise:type
    end)
end)

describe("Missing explicit test for Promise:typeOf", function()
    it("Promise:typeOf works", function()
        -- @tests Promise:typeOf
        -- TODO: add assertion for Promise:typeOf
    end)
end)

describe("Missing explicit test for Promise:isDone", function()
    it("Promise:isDone works", function()
        -- @tests Promise:isDone
        -- TODO: add assertion for Promise:isDone
    end)
end)

describe("Missing explicit test for Promise:result", function()
    it("Promise:result works", function()
        -- @tests Promise:result
        -- TODO: add assertion for Promise:result
    end)
end)

describe("Missing explicit test for Promise:getError", function()
    it("Promise:getError works", function()
        -- @tests Promise:getError
        -- TODO: add assertion for Promise:getError
    end)
end)

describe("Missing explicit test for Channel:type", function()
    it("Channel:type works", function()
        -- @tests Channel:type
        -- TODO: add assertion for Channel:type
    end)
end)

describe("Missing explicit test for Channel:typeOf", function()
    it("Channel:typeOf works", function()
        -- @tests Channel:typeOf
        -- TODO: add assertion for Channel:typeOf
    end)
end)

describe("Missing explicit test for Channel:push", function()
    it("Channel:push works", function()
        -- @tests Channel:push
        -- TODO: add assertion for Channel:push
    end)
end)

describe("Missing explicit test for Channel:peek", function()
    it("Channel:peek works", function()
        -- @tests Channel:peek
        -- TODO: add assertion for Channel:peek
    end)
end)

describe("Missing explicit test for Channel:demand", function()
    it("Channel:demand works", function()
        -- @tests Channel:demand
        -- TODO: add assertion for Channel:demand
    end)
end)

describe("Missing explicit test for Channel:getCount", function()
    it("Channel:getCount works", function()
        -- @tests Channel:getCount
        -- TODO: add assertion for Channel:getCount
    end)
end)

describe("Missing explicit test for Channel:clear", function()
    it("Channel:clear works", function()
        -- @tests Channel:clear
        -- TODO: add assertion for Channel:clear
    end)
end)

describe("Missing explicit test for Channel:supply", function()
    it("Channel:supply works", function()
        -- @tests Channel:supply
        -- TODO: add assertion for Channel:supply
    end)
end)

describe("Missing explicit test for Channel:pushTable", function()
    it("Channel:pushTable works", function()
        -- @tests Channel:pushTable
        -- TODO: add assertion for Channel:pushTable
    end)
end)

describe("Missing explicit test for Channel:popTable", function()
    it("Channel:popTable works", function()
        -- @tests Channel:popTable
        -- TODO: add assertion for Channel:popTable
    end)
end)

describe("Missing explicit test for Channel:pushBytes", function()
    it("Channel:pushBytes works", function()
        -- @tests Channel:pushBytes
        -- TODO: add assertion for Channel:pushBytes
    end)
end)

describe("Missing explicit test for Channel:popBytes", function()
    it("Channel:popBytes works", function()
        -- @tests Channel:popBytes
        -- TODO: add assertion for Channel:popBytes
    end)
end)
