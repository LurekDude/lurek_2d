-- Lurek2D Stress Test: Thread/Channel Communication
-- Tests thread channel message throughput

local function pop_msg(ch)
    if type(ch.tryPop) == "function" then
        return ch:tryPop()
    end
    if type(ch.pop) == "function" then
        return ch:pop()
    end
    return nil
end

describe("thread stress: channel creation", function()
    it("creates 100 channels", function()
        local channels = {}
        for i = 1, 100 do
            channels[i] = lurek.thread.newChannel()
        end
        expect_equal(100, #channels, "100 channels created")
    end)

    it("single channel handles 10000 messages", function()
        local ch = lurek.thread.newChannel()

        -- Push 10000 messages
        for i = 1, 10000 do
            ch:push(i)
        end

        -- Pop all
        local count = 0
        for _ = 1, 10000 do
            local val = pop_msg(ch)
            if val ~= nil then
                count = count + 1
            end
        end

        expect_equal(10000, count, "10000 messages round-tripped")
    end)
end)

describe("thread stress: mixed message types", function()
    it("channel handles mixed types", function()
        local ch = lurek.thread.newChannel()

        -- Push different types
        for i = 1, 1000 do
            if i % 4 == 0 then
                ch:push(i)              -- number
            elseif i % 4 == 1 then
                ch:push("msg_" .. i)    -- string
            elseif i % 4 == 2 then
                ch:push(true)           -- boolean
            else
                ch:push(i * 0.5)        -- float
            end
        end

        local count = 0
        for _ = 1, 1000 do
            local val = pop_msg(ch)
            if val ~= nil then
                count = count + 1
            end
        end

        expect_equal(1000, count, "1000 mixed messages")
    end)
end)

describe("thread stress: multi-channel fanout", function()
    it("broadcast to 10 channels", function()
        local channels = {}
        for i = 1, 10 do
            channels[i] = lurek.thread.newChannel()
        end

        -- Broadcast 100 messages to all channels
        for msg = 1, 100 do
            for _, ch in ipairs(channels) do
                ch:push(msg)
            end
        end

        -- Each channel should have 100 messages
        for i, ch in ipairs(channels) do
            local count = 0
            for _ = 1, 100 do
                if pop_msg(ch) ~= nil then
                    count = count + 1
                end
            end
            expect_equal(100, count, "channel " .. i .. " had 100 messages")
        end
    end)
end)
test_summary()
