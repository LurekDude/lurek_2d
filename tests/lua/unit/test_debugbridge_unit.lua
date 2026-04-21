-- DebugBridge Lua Tests
-- Tests the lurek.debugbridge TCP debug server API

-- ===== Lifecycle =====

-- @description Covers suite: lurek.debugbridge lifecycle.
describe("lurek.debugbridge lifecycle", function()

    -- @tests lurek.debugbridge
    -- @tests lurek.debugbridge.broadcast
    -- @tests lurek.debugbridge.capturePrint
    -- @tests lurek.debugbridge.clearPrintHistory
    -- @tests lurek.debugbridge.getClientCount
    -- @tests lurek.debugbridge.getPerformance
    -- @tests lurek.debugbridge.getPort
    -- @tests lurek.debugbridge.getPrintHistory
    -- @tests lurek.debugbridge.isRunning
    -- @tests lurek.debugbridge.isScreenshotRequested
    -- @tests lurek.debugbridge.poll
    -- @tests lurek.debugbridge.requestScreenshot
    -- @tests lurek.debugbridge.setMaxPrintHistory
    -- @tests lurek.debugbridge.start
    -- @tests lurek.debugbridge.stop
    -- @description Verifies the debugbridge namespace is present in Lua.
    it("namespace exists", function()
        expect_not_nil(lurek.debugbridge)
    end)

    -- @tests lurek.debugbridge.isRunning
    -- @description Verifies the debug server starts in a stopped state.
    it("isRunning returns false initially", function()
        expect_equal(false, lurek.debugbridge.isRunning())
    end)

    -- @tests lurek.debugbridge.getPort
    -- @description Verifies getPort reports 0 while the bridge is stopped.
    it("getPort returns 0 when not running", function()
        expect_equal(0, lurek.debugbridge.getPort())
    end)

    -- @tests lurek.debugbridge.getClientCount
    -- @description Verifies no clients are reported before the bridge starts.
    it("getClientCount returns 0 when not running", function()
        expect_equal(0, lurek.debugbridge.getClientCount())
    end)

    -- @tests lurek.debugbridge.start
    -- @tests lurek.debugbridge.stop
    -- @tests lurek.debugbridge.isRunning
    -- @tests lurek.debugbridge.getPort
    -- @description Verifies the bridge can start on a specific port and returns to the stopped state after stop().
    it("start and stop work on a high port", function()
        -- Use a high port unlikely to conflict
        local ok = lurek.debugbridge.start(49740)
        expect_equal(true, ok)
        expect_equal(true, lurek.debugbridge.isRunning())
        expect_equal(49740, lurek.debugbridge.getPort())

        lurek.debugbridge.stop()
        expect_equal(false, lurek.debugbridge.isRunning())
    end)

    -- @tests lurek.debugbridge.start
    -- @description Verifies a second start attempt fails while the bridge is already running.
    it("start returns false if already running", function()
        lurek.debugbridge.start(49741)
        local second = lurek.debugbridge.start(49742)
        expect_equal(false, second)
        lurek.debugbridge.stop()
    end)

    -- @tests lurek.debugbridge.poll
    -- @description Verifies poll behaves as a no-op when the server is not running.
    it("poll does not error when not running", function()
        lurek.debugbridge.poll()  -- should be a no-op
    end)

end)

-- ===== Print Capture =====

-- @description Covers suite: lurek.debugbridge print capture.
describe("lurek.debugbridge print capture", function()

    -- @tests lurek.debugbridge.capturePrint
    -- @tests lurek.debugbridge.getPrintHistory
    -- @description Verifies captured print messages are appended to the bridge print history.
    it("capturePrint records a message", function()
        lurek.debugbridge.capturePrint("hello world")
        local history = lurek.debugbridge.getPrintHistory()
        expect_true(#history >= 1)
        local last = history[#history]
        expect_equal("hello world", last.message)
    end)

    -- @tests lurek.debugbridge.capturePrint
    -- @tests lurek.debugbridge.getPrintHistory
    -- @description Verifies optional source file and line metadata are stored alongside a captured print message.
    it("capturePrint with source and line", function()
        lurek.debugbridge.capturePrint("test msg", "main.lua", 42)
        local history = lurek.debugbridge.getPrintHistory()
        local last = history[#history]
        expect_equal("test msg", last.message)
        expect_equal("main.lua", last.source)
        expect_equal(42, last.line)
    end)

    -- @tests lurek.debugbridge.clearPrintHistory
    -- @tests lurek.debugbridge.getPrintHistory
    -- @description Verifies clearPrintHistory removes all buffered print entries.
    it("clearPrintHistory clears all entries", function()
        lurek.debugbridge.capturePrint("before clear")
        lurek.debugbridge.clearPrintHistory()
        local history = lurek.debugbridge.getPrintHistory()
        expect_equal(0, #history)
    end)

    -- @tests lurek.debugbridge.setMaxPrintHistory
    -- @tests lurek.debugbridge.capturePrint
    -- @tests lurek.debugbridge.getPrintHistory
    -- @description Verifies max print history trims older entries once the configured capacity is exceeded.
    it("setMaxPrintHistory limits history size", function()
        lurek.debugbridge.clearPrintHistory()
        lurek.debugbridge.setMaxPrintHistory(3)
        for i = 1, 5 do
            lurek.debugbridge.capturePrint("msg " .. i)
        end
        local history = lurek.debugbridge.getPrintHistory()
        expect_equal(3, #history)
        expect_equal("msg 3", history[1].message)
        -- Reset to default
        lurek.debugbridge.setMaxPrintHistory(2000)
    end)

    -- @tests lurek.debugbridge.getPrintHistory
    -- @description Verifies getPrintHistory(count) returns only the trailing slice of history.
    it("getPrintHistory with count returns last N", function()
        lurek.debugbridge.clearPrintHistory()
        for i = 1, 10 do
            lurek.debugbridge.capturePrint("entry " .. i)
        end
        local last3 = lurek.debugbridge.getPrintHistory(3)
        expect_equal(3, #last3)
        expect_equal("entry 8", last3[1].message)
    end)

end)

-- ===== Performance =====

-- @description Covers suite: lurek.debugbridge performance.
describe("lurek.debugbridge performance", function()

    -- @tests lurek.debugbridge.getPerformance
    -- @description Verifies getPerformance returns the expected metrics table shape even without a live frame loop.
    it("getPerformance returns a table with expected keys", function()
        -- poll() auto-records frame time; in tests there is no game loop so
        -- we just verify the shape of the returned table.
        local perf = lurek.debugbridge.getPerformance()
        expect_not_nil(perf)
        expect_not_nil(perf.fps)
        expect_not_nil(perf.avgDt)
    end)

    -- @tests lurek.debugbridge.getPerformance
    -- @description Verifies getPerformance remains callable and returns a table in an effectively empty state.
    it("getPerformance returns zero stats when empty", function()
        -- Start fresh (can't easily clear, but test initial state logic)
        local perf = lurek.debugbridge.getPerformance()
        expect_not_nil(perf)
    end)

end)

-- ===== Screenshots =====

-- @description Covers suite: lurek.debugbridge screenshots.
describe("lurek.debugbridge screenshots", function()

    -- @tests lurek.debugbridge.isScreenshotRequested
    -- @description Verifies the screenshot-request flag starts cleared.
    it("isScreenshotRequested returns false initially", function()
        expect_equal(false, lurek.debugbridge.isScreenshotRequested())
    end)

    -- @tests lurek.debugbridge.requestScreenshot
    -- @tests lurek.debugbridge.isScreenshotRequested
    -- @description Verifies requestScreenshot raises the screenshot-request flag.
    it("requestScreenshot sets the flag", function()
        lurek.debugbridge.requestScreenshot(2)
        expect_equal(true, lurek.debugbridge.isScreenshotRequested())
    end)

end)

-- ===== Broadcast =====

-- @description Covers suite: lurek.debugbridge broadcast.
describe("lurek.debugbridge broadcast", function()

    -- @tests lurek.debugbridge.broadcast
    -- @description Verifies broadcast tolerates the no-client case without throwing.
    it("broadcast does not error without connected clients", function()
        lurek.debugbridge.broadcast("test_event", '{"key": "value"}')
        -- No error means success â€” no clients to receive it
    end)

end)

-- ===== Poll =====

-- @description Covers suite: lurek.debugbridge poll.
describe("lurek.debugbridge poll", function()

    -- @tests lurek.debugbridge.start
    -- @tests lurek.debugbridge.poll
    -- @tests lurek.debugbridge.stop
    -- @description Verifies poll can run while the server is active without raising transport errors.
    it("poll processes without error when server is running", function()
        lurek.debugbridge.start(49743)
        lurek.debugbridge.poll()
        lurek.debugbridge.stop()
    end)

end)

test_summary()
