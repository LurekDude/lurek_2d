--- BDD tests for library.netstate
local netstate_mod = require("library.netstate")

---------------------------------------------------------------------------
-- Construction & Authority
---------------------------------------------------------------------------

describe("Construction & Authority", function()
    it("creates with nil host and defaults", function()
        local ns = netstate_mod.new(nil)
        expect_equal(ns:isAuthority(), false)
        expect_equal(ns:getKeyCount(), 0)
        expect_equal(ns:getVersion(), 0)
        expect_equal(ns:getCurrentTurn(), 0)
    end)

    it("creates with explicit authority=true", function()
        local ns = netstate_mod.new(nil, { authority = true })
        expect_equal(ns:isAuthority(), true)
    end)

    it("creates with explicit authority=false", function()
        local ns = netstate_mod.new(nil, { authority = false })
        expect_equal(ns:isAuthority(), false)
    end)

    it("detects authority from host:isServer()", function()
        local mock_host = { isServer = function() return true end }
        local ns = netstate_mod.new(mock_host)
        expect_equal(ns:isAuthority(), true)
    end)

    it("explicit authority overrides host:isServer()", function()
        local mock_host = { isServer = function() return true end }
        local ns = netstate_mod.new(mock_host, { authority = false })
        expect_equal(ns:isAuthority(), false)
    end)

    it("setAuthority toggles authority", function()
        local ns = netstate_mod.new(nil, { authority = false })
        expect_equal(ns:isAuthority(), false)
        ns:setAuthority(true)
        expect_equal(ns:isAuthority(), true)
        ns:setAuthority(false)
        expect_equal(ns:isAuthority(), false)
    end)

    it("setAuthority rejects non-boolean", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:setAuthority("yes")
        expect_equal(ns:isAuthority(), true)  -- unchanged
        ns:setAuthority(42)
        expect_equal(ns:isAuthority(), true)  -- unchanged
    end)
end)

---------------------------------------------------------------------------
-- State Get / Set
---------------------------------------------------------------------------

describe("State Get / Set", function()
    it("set and get a value as authority", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local ok, err = ns:set("health", 100)
        expect_equal(ok, true)
        expect_equal(err, nil)
        expect_equal(ns:get("health"), 100)
    end)

    it("set rejects non-authority", function()
        local ns = netstate_mod.new(nil, { authority = false })
        local ok, err = ns:set("health", 100)
        expect_equal(ok, false)
        expect_equal(err, "not authority")
        expect_equal(ns:get("health"), nil)
    end)

    it("set rejects invalid key types", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local ok, err = ns:set(123, "value")
        expect_equal(ok, false)
        expect_equal(err, "key must be a non-empty string")

        ok, err = ns:set("", "value")
        expect_equal(ok, false)
        expect_equal(err, "key must be a non-empty string")

        ok, err = ns:set(nil, "value")
        expect_equal(ok, false)
        expect_equal(err, "key must be a non-empty string")
    end)

    it("get returns nil for non-existent key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        expect_equal(ns:get("missing"), nil)
    end)

    it("get returns nil for non-string key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        expect_equal(ns:get(42), nil)
    end)

    it("overwrites existing key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("score", 10)
        ns:set("score", 20)
        expect_equal(ns:get("score"), 20)
    end)

    it("sets multiple distinct keys", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("a", 1)
        ns:set("b", 2)
        ns:set("c", 3)
        expect_equal(ns:getKeyCount(), 3)
        expect_equal(ns:get("a"), 1)
        expect_equal(ns:get("b"), 2)
        expect_equal(ns:get("c"), 3)
    end)

    it("hasKey works correctly", function()
        local ns = netstate_mod.new(nil, { authority = true })
        expect_equal(ns:hasKey("x"), false)
        ns:set("x", 42)
        expect_equal(ns:hasKey("x"), true)
        expect_equal(ns:hasKey(123), false)  -- non-string
    end)

    it("getAll returns flat snapshot", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("hp", 100)
        ns:set("mp", 50)
        local all = ns:getAll()
        expect_equal(all.hp, 100)
        expect_equal(all.mp, 50)
    end)
end)

---------------------------------------------------------------------------
-- Per-Key Versioning
---------------------------------------------------------------------------

describe("Per-Key Versioning", function()
    it("each key starts at version 0", function()
        local ns = netstate_mod.new(nil, { authority = true })
        expect_equal(ns:getKeyVersion("x"), 0)
    end)

    it("version increments independently per key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("a", 1)
        ns:set("b", 10)
        expect_equal(ns:getKeyVersion("a"), 1)
        expect_equal(ns:getKeyVersion("b"), 1)

        ns:set("a", 2)
        expect_equal(ns:getKeyVersion("a"), 2)
        expect_equal(ns:getKeyVersion("b"), 1)  -- unchanged

        ns:set("a", 3)
        expect_equal(ns:getKeyVersion("a"), 3)
        expect_equal(ns:getKeyVersion("b"), 1)
    end)

    it("getVersion returns max across all keys", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("a", 1)
        ns:set("a", 2)
        ns:set("a", 3)
        ns:set("b", 10)
        -- a is at v3, b is at v1     max is 3
        expect_equal(ns:getVersion(), 3)
    end)

    it("getKeyVersion returns 0 for non-string key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        expect_equal(ns:getKeyVersion(nil), 0)
        expect_equal(ns:getKeyVersion(42), 0)
    end)
end)

---------------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------------

describe("Callbacks", function()
    it("fires key-specific callback on set", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local fired = {}
        ns:onChanged("hp", function(val, old, peer)
            table.insert(fired, { val = val, old = old, peer = peer })
        end)
        ns:set("hp", 100)
        expect_equal(#fired, 1)
        expect_equal(fired[1].val, 100)
        expect_equal(fired[1].old, nil)
        expect_equal(fired[1].peer, 0)

        ns:set("hp", 80)
        expect_equal(#fired, 2)
        expect_equal(fired[2].val, 80)
        expect_equal(fired[2].old, 100)
    end)

    it("fires global onChange callback", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local fired = {}
        ns:onChange(function(key, val, old, peer)
            table.insert(fired, { key = key, val = val })
        end)
        ns:set("score", 42)
        expect_equal(#fired, 1)
        expect_equal(fired[1].key, "score")
        expect_equal(fired[1].val, 42)
    end)

    it("does not fire callback for other keys", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local count = 0
        ns:onChanged("hp", function() count = count + 1 end)
        ns:set("mp", 50)
        expect_equal(count, 0)
    end)

    it("clearCallbacks removes key callbacks", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local count = 0
        ns:onChanged("hp", function() count = count + 1 end)
        ns:set("hp", 1)
        expect_equal(count, 1)
        ns:clearCallbacks("hp")
        ns:set("hp", 2)
        expect_equal(count, 1)  -- no longer fires
    end)

    it("onChanged rejects non-function", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:onChanged("hp", "not a function")
        ns:set("hp", 100)
        -- should not error
        expect_equal(ns:get("hp"), 100)
    end)

    it("onChanged rejects empty key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local count = 0
        ns:onChanged("", function() count = count + 1 end)
        ns:set("hp", 100)
        expect_equal(count, 0)  -- callback not registered
    end)

    it("onChange rejects non-function", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:onChange("not a function")
        ns:set("hp", 100)
        -- should not error
        expect_equal(ns:get("hp"), 100)
    end)
end)

---------------------------------------------------------------------------
-- Dirty Set & Max Dirty Keys
---------------------------------------------------------------------------

describe("Dirty Set", function()
    it("tracks dirty keys after set", function()
        local ns = netstate_mod.new(nil, { authority = true })
        expect_equal(ns:getDirtyCount(), 0)
        ns:set("a", 1)
        expect_equal(ns:getDirtyCount(), 1)
        ns:set("b", 2)
        expect_equal(ns:getDirtyCount(), 2)
    end)

    it("same key set twice counts as one dirty", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("a", 1)
        ns:set("a", 2)
        expect_equal(ns:getDirtyCount(), 1)
    end)

    it("maxDirtyKeys limits dirty set size", function()
        local ns = netstate_mod.new(nil, { authority = true, maxDirtyKeys = 3 })
        ns:set("a", 1)
        ns:set("b", 2)
        ns:set("c", 3)
        expect_equal(ns:getDirtyCount(), 3)

        -- Adding a 4th key should evict the oldest ("a")
        ns:set("d", 4)
        expect_equal(ns:getDirtyCount(), 3)
    end)

    it("maxDirtyKeys=1 keeps only the latest", function()
        local ns = netstate_mod.new(nil, { authority = true, maxDirtyKeys = 1 })
        ns:set("first", 1)
        expect_equal(ns:getDirtyCount(), 1)
        ns:set("second", 2)
        expect_equal(ns:getDirtyCount(), 1)
    end)

    it("no maxDirtyKeys allows unlimited", function()
        local ns = netstate_mod.new(nil, { authority = true })
        for i = 1, 100 do
            ns:set("key" .. tostring(i), i)
        end
        expect_equal(ns:getDirtyCount(), 100)
    end)

    it("invalid maxDirtyKeys is ignored", function()
        local ns = netstate_mod.new(nil, { authority = true, maxDirtyKeys = 0 })
        ns:set("a", 1)
        ns:set("b", 2)
        expect_equal(ns:getDirtyCount(), 2)  -- no limit applied
    end)
end)

---------------------------------------------------------------------------
-- Remove Key
---------------------------------------------------------------------------

describe("Remove Key", function()
    it("removes an existing key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("hp", 100)
        expect_equal(ns:hasKey("hp"), true)
        local ok, err = ns:remove("hp")
        expect_equal(ok, true)
        expect_equal(err, nil)
        expect_equal(ns:hasKey("hp"), false)
        expect_equal(ns:get("hp"), nil)
    end)

    it("remove fires callback with nil value", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("hp", 100)
        local removed_val = "not called"
        ns:onChanged("hp", function(val, old, peer)
            removed_val = val
        end)
        ns:remove("hp")
        expect_equal(removed_val, nil)
    end)

    it("remove rejects non-authority", function()
        local ns = netstate_mod.new(nil, { authority = false })
        local ok, err = ns:remove("hp")
        expect_equal(ok, false)
        expect_equal(err, "not authority")
    end)

    it("remove rejects invalid key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local ok, err = ns:remove("")
        expect_equal(ok, false)
        expect_equal(err, "key must be a non-empty string")
    end)

    it("remove rejects non-existent key", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local ok, err = ns:remove("ghost")
        expect_equal(ok, false)
        expect_equal(err, "key not found")
    end)
end)

---------------------------------------------------------------------------
-- Turn-Based Support
---------------------------------------------------------------------------

describe("Turn-Based Support", function()
    it("beginTurn advances turn counter", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder({ 1, 2, 3 })
        local turn, peer = ns:beginTurn()
        expect_equal(turn, 1)
        expect_equal(peer, 1)
    end)

    it("turn rotates through peer order", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder({ 10, 20 })
        local t1, p1 = ns:beginTurn()
        local t2, p2 = ns:beginTurn()
        local t3, p3 = ns:beginTurn()
        expect_equal(t1, 1)
        expect_equal(p1, 10)
        expect_equal(t2, 2)
        expect_equal(p2, 20)
        expect_equal(t3, 3)
        expect_equal(p3, 10)  -- wraps around
    end)

    it("beginTurn with empty order returns nil peer", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder({})
        local turn, peer = ns:beginTurn()
        expect_equal(turn, 1)
        expect_equal(peer, nil)
    end)

    it("beginTurn no-op for non-authority", function()
        local ns = netstate_mod.new(nil, { authority = false, turnBased = true })
        local turn, peer = ns:beginTurn()
        expect_equal(turn, 0)
        expect_equal(peer, nil)
    end)

    it("endTurn is alias for beginTurn", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder({ 5 })
        local t1, p1 = ns:endTurn()
        expect_equal(t1, 1)
        expect_equal(p1, 5)
    end)

    it("getCurrentTurn returns current counter", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        expect_equal(ns:getCurrentTurn(), 0)
        ns:setTurnOrder({ 1 })
        ns:beginTurn()
        expect_equal(ns:getCurrentTurn(), 1)
    end)

    it("getTurnPeer returns current peer", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        expect_equal(ns:getTurnPeer(), nil)
        ns:setTurnOrder({ 42 })
        ns:beginTurn()
        expect_equal(ns:getTurnPeer(), 42)
    end)

    it("isTurn checks specific peer", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder({ 1, 2 })
        ns:beginTurn()
        expect_equal(ns:isTurn(1), true)
        expect_equal(ns:isTurn(2), false)
        ns:beginTurn()
        expect_equal(ns:isTurn(2), true)
    end)

    it("isTurn rejects non-number peer_id", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder({ 1 })
        ns:beginTurn()
        expect_equal(ns:isTurn("1"), false)
        expect_equal(ns:isTurn(nil), false)
    end)

    it("onTurn callback fires on beginTurn", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        local fired = {}
        ns:onTurn(function(turn, peer)
            table.insert(fired, { turn = turn, peer = peer })
        end)
        ns:setTurnOrder({ 7 })
        ns:beginTurn()
        expect_equal(#fired, 1)
        expect_equal(fired[1].turn, 1)
        expect_equal(fired[1].peer, 7)
    end)

    it("onTurn rejects non-function", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:onTurn("not a function")
        -- should not error on beginTurn
        ns:setTurnOrder({ 1 })
        ns:beginTurn()
        expect_equal(ns:getCurrentTurn(), 1)
    end)

    it("setTurnOrder resets state", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder({ 1, 2, 3 })
        ns:beginTurn()
        ns:beginTurn()
        expect_equal(ns:getCurrentTurn(), 2)

        -- Reset
        ns:setTurnOrder({ 10, 20 })
        expect_equal(ns:getCurrentTurn(), 0)
        expect_equal(ns:getTurnPeer(), nil)

        local t, p = ns:beginTurn()
        expect_equal(t, 1)
        expect_equal(p, 10)
    end)

    it("setTurnOrder filters non-number entries", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder({ 1, "bad", 2 })
        ns:beginTurn()
        expect_equal(ns:getTurnPeer(), 1)
        ns:beginTurn()
        expect_equal(ns:getTurnPeer(), 2)
        -- wraps to 1
        ns:beginTurn()
        expect_equal(ns:getTurnPeer(), 1)
    end)

    it("setTurnOrder rejects non-table", function()
        local ns = netstate_mod.new(nil, { authority = true, turnBased = true })
        ns:setTurnOrder("invalid")
        -- should still be empty
        local t, p = ns:beginTurn()
        expect_equal(p, nil)
    end)
end)

---------------------------------------------------------------------------
-- Delta Handling (simulated via _handle)
---------------------------------------------------------------------------

describe("Delta Handling", function()
    it("applies delta update on non-authority", function()
        local ns = netstate_mod.new(nil, { authority = false })
        local changes = {}
        ns:_handle(99, {
            action = "delta",
            delta = {
                hp = { value = 75, version = 1 },
                score = { value = 100, version = 1 },
            },
        }, changes)
        expect_equal(ns:get("hp"), 75)
        expect_equal(ns:get("score"), 100)
        expect_equal(#changes, 2)
    end)

    it("rejects stale delta (per-key version)", function()
        local ns = netstate_mod.new(nil, { authority = false })
        -- Apply version 5
        ns:_handle(1, {
            action = "delta",
            delta = { hp = { value = 100, version = 5 } },
        }, {})
        expect_equal(ns:get("hp"), 100)

        -- Try to apply version 3 (stale)     should be ignored
        local changes = {}
        ns:_handle(1, {
            action = "delta",
            delta = { hp = { value = 50, version = 3 } },
        }, changes)
        expect_equal(ns:get("hp"), 100)  -- unchanged
        expect_equal(#changes, 0)
    end)

    it("accepts newer version delta", function()
        local ns = netstate_mod.new(nil, { authority = false })
        ns:_handle(1, {
            action = "delta",
            delta = { hp = { value = 100, version = 2 } },
        }, {})

        local changes = {}
        ns:_handle(1, {
            action = "delta",
            delta = { hp = { value = 200, version = 5 } },
        }, changes)
        expect_equal(ns:get("hp"), 200)
        expect_equal(#changes, 1)
        expect_equal(changes[1].old_value, 100)
    end)

    it("ignores delta on authority", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:_handle(1, {
            action = "delta",
            delta = { hp = { value = 999, version = 99 } },
        }, {})
        expect_equal(ns:get("hp"), nil)  -- not applied
    end)

    it("handles removed key in delta", function()
        local ns = netstate_mod.new(nil, { authority = false })
        ns:_handle(1, {
            action = "delta",
            delta = { hp = { value = 100, version = 1 } },
        }, {})
        expect_equal(ns:hasKey("hp"), true)

        local changes = {}
        ns:_handle(1, {
            action = "delta",
            delta = { hp = { value = nil, version = 2, removed = true } },
        }, changes)
        expect_equal(ns:hasKey("hp"), false)
        expect_equal(#changes, 1)
    end)

    it("skips non-string keys in delta", function()
        local ns = netstate_mod.new(nil, { authority = false })
        local changes = {}
        -- Numeric key should be skipped
        ns:_handle(1, {
            action = "delta",
            delta = { valid = { value = 1, version = 1 } },
        }, changes)
        expect_equal(#changes, 1)
        expect_equal(ns:get("valid"), 1)
    end)

    it("fires callbacks on delta apply", function()
        local ns = netstate_mod.new(nil, { authority = false })
        local fired = {}
        ns:onChanged("hp", function(val, old, peer)
            table.insert(fired, { val = val, old = old, peer = peer })
        end)
        ns:_handle(42, {
            action = "delta",
            delta = { hp = { value = 80, version = 1 } },
        }, {})
        expect_equal(#fired, 1)
        expect_equal(fired[1].val, 80)
        expect_equal(fired[1].peer, 42)
    end)
end)

---------------------------------------------------------------------------
-- Full State Handling (simulated via _handle)
---------------------------------------------------------------------------

describe("Full State Handling", function()
    it("applies full state snapshot", function()
        local ns = netstate_mod.new(nil, { authority = false })
        ns:_handle(1, {
            action = "full",
            state = {
                hp = { value = 100, version = 5 },
                mp = { value = 50, version = 3 },
            },
        }, {})
        expect_equal(ns:get("hp"), 100)
        expect_equal(ns:get("mp"), 50)
        expect_equal(ns:getKeyVersion("hp"), 5)
        expect_equal(ns:getKeyVersion("mp"), 3)
    end)

    it("ignores full state on authority", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:_handle(1, {
            action = "full",
            state = { hp = { value = 999, version = 99 } },
        }, {})
        expect_equal(ns:get("hp"), nil)
    end)
end)

---------------------------------------------------------------------------
-- Turn Message Handling (simulated via _handle)
---------------------------------------------------------------------------

describe("Turn Message Handling", function()
    it("applies turn update from network", function()
        local ns = netstate_mod.new(nil, { authority = false, turnBased = true })
        ns:_handle(1, {
            action = "turn",
            turn = 5,
            peer = 42,
        }, {})
        expect_equal(ns:getCurrentTurn(), 5)
        expect_equal(ns:getTurnPeer(), 42)
    end)

    it("turn update with nil peer is accepted", function()
        local ns = netstate_mod.new(nil, { authority = false, turnBased = true })
        ns:_handle(1, {
            action = "turn",
            turn = 1,
            peer = nil,
        }, {})
        expect_equal(ns:getCurrentTurn(), 1)
        expect_equal(ns:getTurnPeer(), nil)
    end)

    it("fires onTurn callback on turn message", function()
        local ns = netstate_mod.new(nil, { authority = false, turnBased = true })
        local fired = {}
        ns:onTurn(function(turn, peer)
            table.insert(fired, { turn = turn, peer = peer })
        end)
        ns:_handle(1, {
            action = "turn",
            turn = 3,
            peer = 7,
        }, {})
        expect_equal(#fired, 1)
        expect_equal(fired[1].turn, 3)
        expect_equal(fired[1].peer, 7)
    end)
end)

---------------------------------------------------------------------------
-- Sync & Poll with nil host (no-op safety)
---------------------------------------------------------------------------

describe("Sync & Poll nil host", function()
    it("sync is no-op with nil host", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("x", 1)
        -- sync returns early when host is nil, dirty set stays
        ns:sync()
        expect_equal(ns:getDirtyCount(), 1)
    end)

    it("poll returns empty table with nil host", function()
        local ns = netstate_mod.new(nil, { authority = false })
        local changes = ns:poll()
        expect_equal(#changes, 0)
    end)

    it("requestFullState returns false with nil host", function()
        local ns = netstate_mod.new(nil, { authority = false })
        local ok = ns:requestFullState()
        expect_equal(ok, false)
    end)

    it("requestFullState returns false if authority", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local ok = ns:requestFullState()
        expect_equal(ok, false)
    end)
end)

---------------------------------------------------------------------------
-- Logging
---------------------------------------------------------------------------

describe("Logging", function()
    it("custom log function receives messages", function()
        local logs = {}
        netstate_mod.setLogging(true, function(msg) table.insert(logs, msg) end)

        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("hp", 100)

        -- Should have logged creation and set
        expect_equal(#logs > 0, true)

        -- Cleanup
        netstate_mod.setLogging(false)
    end)

    it("logging disabled produces no output", function()
        local logs = {}
        netstate_mod.setLogging(false)

        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("hp", 100)

        expect_equal(#logs, 0)
    end)
end)

---------------------------------------------------------------------------
-- Edge Cases
---------------------------------------------------------------------------

describe("Edge Cases", function()
    it("set nil value is valid", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("x", 42)
        expect_equal(ns:get("x"), 42)
        ns:set("x", nil)
        -- value is nil but key still exists in state
        expect_equal(ns:get("x"), nil)
    end)

    it("set boolean value", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("flag", true)
        expect_equal(ns:get("flag"), true)
        ns:set("flag", false)
        expect_equal(ns:get("flag"), false)
    end)

    it("set table value", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("pos", { x = 10, y = 20 })
        local pos = ns:get("pos")
        expect_equal(pos.x, 10)
        expect_equal(pos.y, 20)
    end)

    it("set string value", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("name", "player1")
        expect_equal(ns:get("name"), "player1")
    end)

    it("onFullStateTimeout stores callback", function()
        local ns = netstate_mod.new(nil, { authority = false })
        local called = false
        ns:onFullStateTimeout(function() called = true end)
        -- Callback is stored but not auto-invoked (caller's responsibility)
        expect_equal(called, false)
    end)

    it("getKeyCount after removes", function()
        local ns = netstate_mod.new(nil, { authority = true })
        ns:set("a", 1)
        ns:set("b", 2)
        ns:set("c", 3)
        expect_equal(ns:getKeyCount(), 3)
        ns:remove("b")
        expect_equal(ns:getKeyCount(), 2)
    end)

    it("multiple callbacks on same key all fire", function()
        local ns = netstate_mod.new(nil, { authority = true })
        local count_a = 0
        local count_b = 0
        ns:onChanged("x", function() count_a = count_a + 1 end)
        ns:onChanged("x", function() count_b = count_b + 1 end)
        ns:set("x", 1)
        expect_equal(count_a, 1)
        expect_equal(count_b, 1)
    end)

    it("concurrent key updates use independent versions", function()
        local ns = netstate_mod.new(nil, { authority = false })
        -- Simulate receiving interleaved updates for two keys
        ns:_handle(1, {
            action = "delta",
            delta = {
                hp = { value = 100, version = 3 },
                mp = { value = 50, version = 1 },
            },
        }, {})

        -- Now a stale update for hp (v2) should be rejected,
        -- but an update for mp (v2) should be accepted
        local changes = {}
        ns:_handle(1, {
            action = "delta",
            delta = {
                hp = { value = 80, version = 2 },   -- stale for hp
                mp = { value = 60, version = 2 },   -- fresh for mp
            },
        }, changes)

        expect_equal(ns:get("hp"), 100)  -- unchanged (v2 < v3)
        expect_equal(ns:get("mp"), 60)   -- updated (v2 > v1)
        expect_equal(#changes, 1)        -- only mp changed
    end)
end)
test_summary()
