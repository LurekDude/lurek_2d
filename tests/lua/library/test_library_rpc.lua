--- BDD tests for library.rpc
--- Uses mock host/network objects to test pure-Lua RPC logic without
--- requiring a real lurek.network connection.

---------------------------------------------------------------------------
-- Mock infrastructure
---------------------------------------------------------------------------

-- Mock lurek.network.pack/unpack using identity (tables pass through)
if not lurek then lurek = {} end
if not lurek.network then
    lurek.network = {
        MAX_PEERS = 4096,
        DEFAULT_PEERS = 166,
        MAX_CHANNELS = 255,
        DEFAULT_CHANNELS = 2,
    }
end
if not lurek.log then
    lurek.log = { debug = function() end }
end

lurek.network.pack = function(t) return t end
lurek.network.unpack = function(t) return t end

-- Mock lurek.serial so the library's _encode/_decode use identity too
if not lurek.serial then lurek.serial = {} end
lurek.serial.toJson = function(t) return t end
lurek.serial.fromJson = function(t) return t end

--- MockHost simulates a network host for testing.
local MockHost = {}
MockHost.__index = MockHost

function MockHost.new()
    local self = setmetatable({}, MockHost)
    self.sent = {}       -- array of {peer_id, channel, msg, reliable}
    self.broadcasts = {} -- array of {channel, msg, reliable}
    self._inbox = {}     -- array of {type="receive", peer=N, data=table}
    return self
end

function MockHost:send(peer_id, channel, msg, reliable)
    self.sent[#self.sent + 1] = {
        peer_id  = peer_id,
        channel  = channel,
        msg      = msg,
        reliable = reliable,
    }
end

function MockHost:broadcast(channel, msg, reliable)
    self.broadcasts[#self.broadcasts + 1] = {
        channel  = channel,
        msg      = msg,
        reliable = reliable,
    }
end

function MockHost:service()
    if #self._inbox > 0 then
        return table.remove(self._inbox, 1)
    end
    return nil
end

function MockHost:inject(peer_id, data)
    self._inbox[#self._inbox + 1] = {
        type = "receive",
        peer = peer_id,
        data = data,
    }
end

---------------------------------------------------------------------------
local rpc_mod = require("library.rpc")

---------------------------------------------------------------------------
-- Construction & Basics
---------------------------------------------------------------------------

describe("RPC Construction", function()
    it("creates with defaults", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        expect_equal(R:getHandlerCount(), 0)
        expect_equal(R:getPendingCount(), 0)
        expect_equal(R:getNextId(), 1)
    end)

    it("accepts custom channel and timeout", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 3, 60)
        expect_equal(R._channel, 3)
        expect_equal(R._timeout, 60)
    end)

    it("rejects negative timeout", function()
        local host = MockHost.new()
        local ok, err = pcall(rpc_mod.new, host, 0, -5)
        expect_equal(ok, false)
    end)

    it("rejects non-number timeout", function()
        local host = MockHost.new()
        local ok, err = pcall(rpc_mod.new, host, 0, "bad")
        expect_equal(ok, false)
    end)
end)

---------------------------------------------------------------------------
-- Register / Unregister
---------------------------------------------------------------------------

describe("RPC Register/Unregister", function()
    it("registers a handler", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:register("add", function(pid, a, b) return a + b end)
        expect_equal(R:getHandlerCount(), 1)
    end)

    it("unregisters a handler", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:register("add", function() end)
        R:unregister("add")
        expect_equal(R:getHandlerCount(), 0)
    end)

    it("rejects empty name", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:register("", function() end) end)
        expect_equal(ok, false)
    end)

    it("rejects non-function handler", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:register("foo", 42) end)
        expect_equal(ok, false)
    end)

    it("rejects non-string name", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:register(123, function() end) end)
        expect_equal(ok, false)
    end)
end)

---------------------------------------------------------------------------
-- Call (request/response)
---------------------------------------------------------------------------

describe("RPC Call", function()
    it("sends an rpc_call message", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local id = R:call(1, "add", function() end, 10, 20)
        expect_equal(id, 1)
        expect_equal(#host.sent, 1)
        expect_equal(host.sent[1].msg.type, "rpc_call")
        expect_equal(host.sent[1].msg.name, "add")
        expect_equal(host.sent[1].msg.args[1], 10)
        expect_equal(host.sent[1].msg.args[2], 20)
    end)

    it("increments request IDs", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local id1 = R:call(1, "a", function() end)
        local id2 = R:call(1, "b", function() end)
        expect_equal(id1, 1)
        expect_equal(id2, 2)
    end)

    it("stores pending callback", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:call(1, "fn", function() end)
        expect_equal(R:getPendingCount(), 1)
    end)

    it("rejects empty method name", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:call(1, "", function() end) end)
        expect_equal(ok, false)
    end)

    it("rejects non-function callback", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:call(1, "fn", "not_a_fn") end)
        expect_equal(ok, false)
    end)
end)

---------------------------------------------------------------------------
-- Response Matching
---------------------------------------------------------------------------

describe("RPC Response Matching", function()
    it("matches response to pending callback by ID", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0) -- no timeout
        local got_success, got_result
        local id = R:call(1, "add", function(s, r)
            got_success = s
            got_result = r
        end)
        -- Simulate a response arriving
        host:inject(1, {
            type    = "rpc_response",
            id      = id,
            success = true,
            result  = { 42 },
        })
        local responses = R:poll()
        expect_equal(got_success, true)
        expect_equal(got_result[1], 42)
        expect_equal(R:getPendingCount(), 0)
        expect_equal(#responses, 1)
        expect_equal(responses[1].id, id)
    end)

    it("ignores response with unknown ID", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0)
        host:inject(1, {
            type    = "rpc_response",
            id      = 999,
            success = true,
            result  = {},
        })
        local responses = R:poll()
        -- Still collected in responses array, but no callback invoked
        expect_equal(#responses, 1)
        expect_equal(R:getPendingCount(), 0)
    end)
end)

---------------------------------------------------------------------------
-- Notify
---------------------------------------------------------------------------

describe("RPC Notify", function()
    it("sends an rpc_notify with peer_id context", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:notify(5, "ping", "hello")
        expect_equal(#host.sent, 1)
        local msg = host.sent[1].msg
        expect_equal(msg.type, "rpc_notify")
        expect_equal(msg.name, "ping")
        expect_equal(msg.peer_id, 5)
        expect_equal(msg.args[1], "hello")
    end)

    it("rejects empty method name", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:notify(1, "") end)
        expect_equal(ok, false)
    end)
end)

---------------------------------------------------------------------------
-- Broadcast
---------------------------------------------------------------------------

describe("RPC Broadcast", function()
    it("broadcasts rpc_notify with peer_id=0", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:broadcast("sync", "state_data")
        expect_equal(#host.broadcasts, 1)
        local msg = host.broadcasts[1].msg
        expect_equal(msg.type, "rpc_notify")
        expect_equal(msg.name, "sync")
        expect_equal(msg.peer_id, 0)
        expect_equal(msg.args[1], "state_data")
    end)

    it("rejects empty method name", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:broadcast("") end)
        expect_equal(ok, false)
    end)
end)

---------------------------------------------------------------------------
-- Dispatch (incoming calls)
---------------------------------------------------------------------------

describe("RPC Incoming Call Dispatch", function()
    it("dispatches an incoming rpc_call and sends response", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:register("add", function(pid, a, b) return a + b end)
        host:inject(42, {
            type = "rpc_call",
            id   = 1,
            name = "add",
            args = { 3, 7 },
        })
        R:poll()
        -- The handler should have sent a response
        expect_equal(#host.sent, 1)
        local resp = host.sent[1].msg
        expect_equal(resp.type, "rpc_response")
        expect_equal(resp.id, 1)
        expect_equal(resp.success, true)
        expect_equal(resp.result[1], 10)
    end)

    it("catches handler errors and sends failure response", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:register("bad", function() error("boom") end)
        host:inject(1, {
            type = "rpc_call",
            id   = 1,
            name = "bad",
            args = {},
        })
        R:poll()
        expect_equal(#host.sent, 1)
        expect_equal(host.sent[1].msg.success, false)
    end)

    it("fires error callback for missing handler", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local err_msg = nil
        R:onError(function(e) err_msg = e end)
        host:inject(1, {
            type = "rpc_call",
            id   = 1,
            name = "nonexistent",
            args = {},
        })
        R:poll()
        expect_equal(type(err_msg), "string")
        -- Error message should include the method name
        local found = string.find(tostring(err_msg), "nonexistent")
        expect_equal(found ~= nil, true)
    end)

    it("dispatches incoming rpc_notify", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local received_args = nil
        local received_peer = nil
        R:register("ping", function(pid, msg)
            received_peer = pid
            received_args = msg
        end)
        host:inject(7, {
            type    = "rpc_notify",
            name    = "ping",
            args    = { "hello" },
            peer_id = 7,
        })
        R:poll()
        expect_equal(received_peer, 7)
        expect_equal(received_args, "hello")
    end)

    it("fires error callback on notify handler failure with method name", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local err_msg = nil
        R:onError(function(e) err_msg = e end)
        R:register("crashy", function() error("oops") end)
        host:inject(1, {
            type = "rpc_notify",
            name = "crashy",
            args = {},
        })
        R:poll()
        expect_equal(type(err_msg), "string")
        -- Error message should include the method name
        local found = string.find(tostring(err_msg), "crashy")
        expect_equal(found ~= nil, true)
    end)
end)

---------------------------------------------------------------------------
-- Unpack Failure
---------------------------------------------------------------------------

describe("RPC Unpack Failure", function()
    it("fires error callback with peer context on unpack failure", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local err_msg = nil
        R:onError(function(e) err_msg = e end)

        -- Override lurek.network.unpack to fail
        local orig = lurek.network.unpack
        lurek.network.unpack = function() error("bad data") end

        host:inject(99, "garbage_data")
        R:poll()

        lurek.network.unpack = orig

        expect_equal(type(err_msg), "string")
        -- Error should mention the peer
        local found = string.find(tostring(err_msg), "99")
        expect_equal(found ~= nil, true)
    end)
end)

---------------------------------------------------------------------------
-- Timeout
---------------------------------------------------------------------------

describe("RPC Timeout", function()
    it("expires pending calls after timeout", function()
        local host = MockHost.new()
        -- Use a very short timeout so os.clock() + 0 is already expired
        local R = rpc_mod.new(host, 0, 0.001) -- 1ms timeout
        local timed_out = false
        local timeout_result = nil
        R:call(1, "slow_fn", function(s, r)
            timed_out = not s
            timeout_result = r
        end)
        expect_equal(R:getPendingCount(), 1)

        -- Mock os.clock to return a value past the deadline
        local orig_clock = os.clock
        os.clock = function() return orig_clock() + 10 end

        R:poll()

        os.clock = orig_clock

        expect_equal(timed_out, true)
        expect_equal(R:getPendingCount(), 0)
        -- timeout result should contain method name
        expect_equal(type(timeout_result), "table")
        local timeout_msg = (timeout_result and timeout_result[1]) or ""
        local found = string.find(tostring(timeout_msg), "slow_fn")
        expect_equal(found ~= nil, true)
    end)

    it("does not expire when timeout is 0", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0) -- no timeout
        R:call(1, "fn", function() end)

        local orig_clock = os.clock
        os.clock = function() return orig_clock() + 9999 end

        R:poll()

        os.clock = orig_clock

        -- Should still be pending
        expect_equal(R:getPendingCount(), 1)
    end)

    it("setTimeout changes timeout for future calls", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0)
        R:setTimeout(5)
        expect_equal(R._timeout, 5)
    end)

    it("setTimeout rejects negative values", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:setTimeout(-1) end)
        expect_equal(ok, false)
    end)
end)

---------------------------------------------------------------------------
-- ID Counter Management
---------------------------------------------------------------------------

describe("RPC ID Counter", function()
    it("resetIdCounter resets to 1", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0)
        R:call(1, "a", function() end)
        R:call(1, "b", function() end)
        expect_equal(R:getNextId(), 3)
        R:resetIdCounter()
        expect_equal(R:getNextId(), 1)
    end)

    it("getNextId returns current counter", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0)
        expect_equal(R:getNextId(), 1)
        R:call(1, "x", function() end)
        expect_equal(R:getNextId(), 2)
    end)
end)

---------------------------------------------------------------------------
-- Error Handler Validation
---------------------------------------------------------------------------

describe("RPC onError Validation", function()
    it("accepts a function", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:onError(function() end)
        -- no error
        expect_equal(true, true)
    end)

    it("accepts nil to clear", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:onError(function() end)
        R:onError(nil)
        expect_equal(true, true)
    end)

    it("rejects non-function", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local ok = pcall(function() R:onError("bad") end)
        expect_equal(ok, false)
    end)
end)

---------------------------------------------------------------------------
-- Logging
---------------------------------------------------------------------------

describe("RPC Logging", function()
    it("setLogging toggles log flag", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        expect_equal(R._log, false)
        R:setLogging(true)
        expect_equal(R._log, true)
        R:setLogging(false)
        expect_equal(R._log, false)
    end)

    it("logging does not crash during call/poll cycle", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0)
        R:setLogging(true)
        R:register("echo", function(pid, v) return v end)
        R:call(1, "echo", function() end, "test")
        R:notify(1, "echo", "test")
        R:broadcast("echo", "test")

        host:inject(1, {
            type = "rpc_call",
            id   = 100,
            name = "echo",
            args = { "hi" },
        })
        host:inject(1, {
            type    = "rpc_response",
            id      = 1,
            success = true,
            result  = { "test" },
        })
        R:poll()
        -- No crash = pass
        expect_equal(true, true)
    end)
end)

---------------------------------------------------------------------------
-- Edge Cases
---------------------------------------------------------------------------

describe("RPC Edge Cases", function()
    it("poll returns empty table when no messages", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        local responses = R:poll()
        expect_equal(type(responses), "table")
        expect_equal(#responses, 0)
    end)

    it("handles call with no arguments", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0)
        local id = R:call(1, "noop", function() end)
        expect_equal(id, 1)
        expect_equal(#host.sent[1].msg.args, 0)
    end)

    it("handles notify with no arguments", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:notify(1, "noop")
        expect_equal(#host.sent[1].msg.args, 0)
    end)

    it("handles multiple concurrent pending calls", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host, 0, 0)
        local results = {}
        R:call(1, "a", function(s, r) results.a = r end)
        R:call(1, "b", function(s, r) results.b = r end)
        R:call(1, "c", function(s, r) results.c = r end)
        expect_equal(R:getPendingCount(), 3)

        -- Respond out of order
        host:inject(1, { type = "rpc_response", id = 3, success = true, result = { "C" } })
        host:inject(1, { type = "rpc_response", id = 1, success = true, result = { "A" } })
        host:inject(1, { type = "rpc_response", id = 2, success = true, result = { "B" } })
        R:poll()

        expect_equal(results.a[1], "A")
        expect_equal(results.b[1], "B")
        expect_equal(results.c[1], "C")
        expect_equal(R:getPendingCount(), 0)
    end)

    it("getHandlerCount after multiple register/unregister", function()
        local host = MockHost.new()
        local R = rpc_mod.new(host)
        R:register("a", function() end)
        R:register("b", function() end)
        R:register("c", function() end)
        expect_equal(R:getHandlerCount(), 3)
        R:unregister("b")
        expect_equal(R:getHandlerCount(), 2)
    end)
end)

---------------------------------------------------------------------------
test_summary()
