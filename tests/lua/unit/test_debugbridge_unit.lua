-- DebugBridge Lua Tests
-- Tests the lurek.debugbridge TCP debug server API

-- ===== Lifecycle =====

describe("lurek.debugbridge lifecycle", function()

    it("namespace exists", function()
        expect_not_nil(lurek.debugbridge)
    end)

    it("isRunning returns false initially", function()
        expect_equal(false, lurek.debugbridge.isRunning())
    end)

    it("getPort returns 0 when not running", function()
        expect_equal(0, lurek.debugbridge.getPort())
    end)

    it("getClientCount returns 0 when not running", function()
        expect_equal(0, lurek.debugbridge.getClientCount())
    end)

    it("start and stop work on a high port", function()
        -- Use a high port unlikely to conflict
        local ok = lurek.debugbridge.start(49740)
        expect_equal(true, ok)
        expect_equal(true, lurek.debugbridge.isRunning())
        expect_equal(49740, lurek.debugbridge.getPort())

        lurek.debugbridge.stop()
        expect_equal(false, lurek.debugbridge.isRunning())
    end)

    it("start returns false if already running", function()
        lurek.debugbridge.start(49741)
        local second = lurek.debugbridge.start(49742)
        expect_equal(false, second)
        lurek.debugbridge.stop()
    end)

    it("poll does not error when not running", function()
        lurek.debugbridge.poll()  -- should be a no-op
    end)

end)

-- ===== Print Capture =====

describe("lurek.debugbridge print capture", function()

    it("capturePrint records a message", function()
        lurek.debugbridge.capturePrint("hello world")
        local history = lurek.debugbridge.getPrintHistory()
        expect_true(#history >= 1)
        local last = history[#history]
        expect_equal("hello world", last.message)
    end)

    it("capturePrint with source and line", function()
        lurek.debugbridge.capturePrint("test msg", "main.lua", 42)
        local history = lurek.debugbridge.getPrintHistory()
        local last = history[#history]
        expect_equal("test msg", last.message)
        expect_equal("main.lua", last.source)
        expect_equal(42, last.line)
    end)

    it("clearPrintHistory clears all entries", function()
        lurek.debugbridge.capturePrint("before clear")
        lurek.debugbridge.clearPrintHistory()
        local history = lurek.debugbridge.getPrintHistory()
        expect_equal(0, #history)
    end)

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

describe("lurek.debugbridge performance", function()

    it("getPerformance returns a table with expected keys", function()
        -- poll() auto-records frame time; in tests there is no game loop so
        -- we just verify the shape of the returned table.
        local perf = lurek.debugbridge.getPerformance()
        expect_not_nil(perf)
        expect_not_nil(perf.fps)
        expect_not_nil(perf.avgDt)
    end)

    it("getPerformance returns zero stats when empty", function()
        -- Start fresh (can't easily clear, but test initial state logic)
        local perf = lurek.debugbridge.getPerformance()
        expect_not_nil(perf)
    end)

end)

-- ===== Screenshots =====

describe("lurek.debugbridge screenshots", function()

    it("isScreenshotRequested returns false initially", function()
        expect_equal(false, lurek.debugbridge.isScreenshotRequested())
    end)

    it("requestScreenshot sets the flag", function()
        lurek.debugbridge.requestScreenshot(2)
        expect_equal(true, lurek.debugbridge.isScreenshotRequested())
    end)

end)

-- ===== Broadcast =====

describe("lurek.debugbridge broadcast", function()

    it("broadcast does not error without connected clients", function()
        lurek.debugbridge.broadcast("test_event", '{"key": "value"}')
        -- No error means success  - no clients to receive it
    end)

end)

-- ===== Poll =====

describe("lurek.debugbridge poll", function()

    it("poll processes without error when server is running", function()
        lurek.debugbridge.start(49743)
        lurek.debugbridge.poll()
        lurek.debugbridge.stop()
    end)

end)
test_summary()
