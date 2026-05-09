-- test_network.lua
-- Canonical file. Merged from multiple sources.

require("tests/lua/init")

-- @describe lurek.network security
describe("lurek.network security", function()
    -- @security lurek.network.newHost
    it("should reject empty address string", function()
        expect_error(function()
            lurek.network.newHost({ addr = "" })
        end)
    end)

    -- @security lurek.network.newHost
    it("should reject garbage address string", function()
        expect_error(function()
            lurek.network.newHost({ addr = "not_an_address" })
        end)
    end)

    -- @security LNetworkHost:destroy
    -- @security LNetworkHost:isServer
    -- @security lurek.network.newServer
    it("should reject server with port 0", function()
        -- Port 0 is ephemeral     should still create but bind to random port
        -- This is NOT an error; verify it works
        local server = lurek.network.newServer({ port = 0 })
        expect_equal(server:isServer(), true)
        server:destroy()
    end)

    -- @security lurek.network.pack
    it("should handle pack of unsupported types gracefully", function()
        -- Functions cannot be serialized
        expect_error(function()
            lurek.network.pack(print)
        end)
    end)

    -- @security lurek.network.unpack
    it("should handle unpack of empty string", function()
        expect_error(function()
            lurek.network.unpack("")
        end)
    end)

    -- @security lurek.network.unpack
    it("should handle unpack of garbage data", function()
        expect_error(function()
            lurek.network.unpack("\xff\xfe\xfd\xfc\xfb\xfa")
        end)
    end)

    -- @security lurek.network.newServer
    it("should handle newServer without required port", function()
        expect_error(function()
            lurek.network.newServer({})
        end)
    end)

    -- @security lurek.network.newClient
    it("should handle newClient without required addr", function()
        expect_error(function()
            lurek.network.newClient({})
        end)
    end)

    -- @security lurek.network.newServer
    it("should reject negative server port", function()
        expect_error(function()
            lurek.network.newServer({ port = -1 })
        end)
    end)

    -- @security lurek.network.newServer
    it("should reject port above max uint16", function()
        expect_error(function()
            lurek.network.newServer({ port = 70000 })
        end)
    end)

    -- @security LNetworkHost:destroy
    -- @security LNetworkHost:isDestroyed
    -- @security LNetworkHost:service
    -- @security lurek.network.newHost
    it("should handle destroyed host methods gracefully", function()
        local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
        host:destroy()
        expect_equal(host:isDestroyed(), true)
        -- Methods on destroyed host should error
        expect_error(function()
            host:service()
        end)
    end)

    -- @security LNetworkHost:destroy
    -- @security lurek.network.newHost
    it("should not crash on rapid create/destroy cycle", function()
        local completed = 0
        for i = 1, 10 do
            local h = lurek.network.newHost({ addr = "0.0.0.0:0" })
            h:destroy()
            completed = completed + 1
        end
        expect_equal(10, completed)
    end)

    -- @security LNetworkRuntime:shutdown
    -- @security lurek.network.newRuntime
    it("should handle runtime shutdown idempotently", function()
        local rt = lurek.network.newRuntime()
        rt:shutdown()
        -- Second shutdown should not crash
        local ok = pcall(function()
            rt:shutdown()
        end)
        expect_true(ok)
    end)

    -- @security lurek.network.pack
    -- @security lurek.network.unpack
    it("should handle pack of deeply nested table", function()
        -- Build a moderately deep table (not absurdly deep to avoid stack overflow)
        local t = { value = 1 }
        local current = t
        for i = 1, 20 do
            current.child = { value = i + 1 }
            current = current.child
        end
        local packed = lurek.network.pack(t)
        local unpacked = lurek.network.unpack(packed)
        if unpacked == nil then error("expected unpacked table") end
        if unpacked.child == nil then error("expected unpacked.child") end
        expect_equal(unpacked.value, 1)
        expect_equal(unpacked.child.value, 2)
    end)

    -- @security lurek.network.pack
    -- @security lurek.network.unpack
    it("should reject truncated payload", function()
        local payload = lurek.network.pack({ ok = true, count = 3 })
        local truncated = string.sub(payload, 1, math.max(1, #payload - 1))
        expect_error(function()
            lurek.network.unpack(truncated)
        end)
    end)

end)
test_summary()


