-- Lurek2D Stress Test: Patterns Module Operations
-- Measures observer, state machine, and command queue throughput.
-- @stress lurek.patterns.newObserver
-- @stress lurek.patterns.newStateMachine
-- @stress lurek.patterns.newCommandQueue

describe("stress: patterns observer throughput", function()
    it("1000 observers × 100 notifications: <10s", function()
        local obs   = lurek.patterns.newObserver()
        local SUBS  = 1000
        local NOTIF = 100
        local count = 0

        for _ = 1, SUBS do
            obs:subscribe(function() count = count + 1 end)
        end

        local start = os.clock()
        for _ = 1, NOTIF do
            obs:notify()
        end
        local elapsed = os.clock() - start
        local expected = SUBS * NOTIF
        print(string.format("[STRESS] %d observer notifications in %.4fs (%.0f/sec)",
            expected, elapsed, expected / elapsed))

        expect_true(elapsed < 10.0, "observer budget: " .. elapsed .. "s")
        expect_equal(expected, count, "all notifications delivered")
    end)
end)

describe("stress: patterns command queue throughput", function()
    it("10000 commands enqueued and executed: <10s", function()
        local queue = lurek.patterns.newCommandQueue()
        local COUNT = 10000
        local done  = 0

        for _ = 1, COUNT do
            queue:push(function() done = done + 1 end)
        end

        local start = os.clock()
        queue:executeAll()
        local elapsed = os.clock() - start
        print(string.format("[STRESS] %d commands executed in %.4fs (%.0f/sec)",
            COUNT, elapsed, COUNT / elapsed))

        expect_true(elapsed < 10.0, "command queue budget: " .. elapsed .. "s")
        expect_equal(COUNT, done, "all commands executed")
    end)
end)

describe("stress: patterns state machine throughput", function()
    it("5000 state transitions in <10s", function()
        local sm    = lurek.patterns.newStateMachine()
        local COUNT = 5000

        sm:addState("A", { onEnter = function() end, onExit = function() end })
        sm:addState("B", { onEnter = function() end, onExit = function() end })

        local elapsed = measure("pattern SM transition x" .. COUNT, COUNT, function()
            local cur = sm:getState()
            sm:setState(cur == "A" and "B" or "A")
        end)

        expect_true(elapsed < 10.0, "SM transition budget: " .. elapsed .. "s")
    end)
end)

test_summary()
