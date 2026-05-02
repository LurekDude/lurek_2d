-- test_network.lua
-- Canonical file. Merged from multiple sources.

require("tests/lua/init")

describe("lurek.network security", function()
    it("should reject empty address string", function()
        expect_error(function()
            lurek.network.newHost({ addr = "" })
        end)
    end)

    it("should reject garbage address string", function()
        expect_error(function()
            lurek.network.newHost({ addr = "not_an_address" })
        end)
    end)

    it("should reject server with port 0", function()
        -- Port 0 is ephemeral     should still create but bind to random port
        -- This is NOT an error; verify it works
        local server = lurek.network.newServer({ port = 0 })
        expect_equal(server:isServer(), true)
        server:destroy()
    end)

    it("should handle pack of unsupported types gracefully", function()
        -- Functions cannot be serialized
        expect_error(function()
            lurek.network.pack(print)
        end)
    end)

    it("should handle unpack of empty string", function()
        expect_error(function()
            lurek.network.unpack("")
        end)
    end)

    it("should handle unpack of garbage data", function()
        expect_error(function()
            lurek.network.unpack("\xff\xfe\xfd\xfc\xfb\xfa")
        end)
    end)

    it("should handle newServer without required port", function()
        expect_error(function()
            lurek.network.newServer({})
        end)
    end)

    it("should handle newClient without required addr", function()
        expect_error(function()
            lurek.network.newClient({})
        end)
    end)

    it("should handle destroyed host methods gracefully", function()
        local host = lurek.network.newHost({ addr = "0.0.0.0:0" })
        host:destroy()
        expect_equal(host:isDestroyed(), true)
        -- Methods on destroyed host should error
        expect_error(function()
            host:service()
        end)
    end)

    it("should not crash on rapid create/destroy cycle", function()
        for i = 1, 10 do
            local h = lurek.network.newHost({ addr = "0.0.0.0:0" })
            h:destroy()
        end
        -- If we get here without crash, test passes
        expect_equal(true, true)
    end)

    it("should handle runtime shutdown idempotently", function()
        local rt = lurek.network.newRuntime()
        rt:shutdown()
        -- Second shutdown should not crash
        rt:shutdown()
        expect_equal(true, true)
    end)

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
        expect_equal(unpacked.value, 1)
        expect_equal(unpacked.child.value, 2)
    end)
end)
test_summary()
