-- Lurek2D Integration Test: Thread + Data
-- Tests passing data between threads via Channel.
-- @covers lurek.thread.newChannel
-- @covers lurek.data.encode
-- @covers lurek.data.decode

describe("integration: thread channel with serialized data", function()
    it("pushes and pops plain value via channel", function()
        local ch = lurek.thread.newChannel()
        expect_not_nil(ch, "channel created")

        ch:push(42)
        local val = ch:tryPop()
        expect_equal(42, val, "integer round-tripped through channel")
    end)

    it("pushes JSON-encoded table and receives raw string", function()
        local ch      = lurek.thread.newChannel()
        local payload = {x = 10, y = 20, label = "pos"}

        local encoded = lurek.data.encode("json", payload)
        ch:push(encoded)

        local raw = ch:tryPop()
        expect_type("string", raw, "received encoded string from channel")

        local decoded = lurek.data.decode("json", raw)
        expect_equal(10,    decoded.x,     "x round-tripped through channel")
        expect_equal(20,    decoded.y,     "y round-tripped through channel")
        expect_equal("pos", decoded.label, "label round-tripped through channel")
    end)

    it("channel is FIFO for multiple pushes", function()
        local ch = lurek.thread.newChannel()

        ch:push(1)
        ch:push(2)
        ch:push(3)

        expect_equal(1, ch:tryPop(), "first out is 1")
        expect_equal(2, ch:tryPop(), "second out is 2")
        expect_equal(3, ch:tryPop(), "third out is 3")
    end)

    it("tryPop on empty channel returns nil", function()
        local ch  = lurek.thread.newChannel()
        local val = ch:tryPop()
        expect_nil(val, "empty channel returns nil")
    end)

    it("large payload round-trips via channel", function()
        local ch = lurek.thread.newChannel()
        local big = {}
        for i = 1, 1000 do big[i] = i * 2 end

        local encoded = lurek.data.encode("json", big)
        ch:push(encoded)

        local raw     = ch:tryPop()
        local decoded = lurek.data.decode("json", raw)
        expect_equal(1000, #decoded,     "1000-element array round-tripped")
        expect_equal(2000, decoded[1000], "last element correct")
    end)
end)

test_summary()
