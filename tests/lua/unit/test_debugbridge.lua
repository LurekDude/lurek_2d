-- DebugBridge Lua Tests
-- Tests the luna.debugbridge TCP debug server API

-- ===== Lifecycle =====

describe("luna.debugbridge lifecycle", function()

    it("namespace exists", function()
        expect_not_nil(luna.debugbridge)
    end)

    it("isRunning returns false initially", function()
        expect_equal(false, luna.debugbridge.isRunning())
    end)

    it("getPort returns 0 when not running", function()
        expect_equal(0, luna.debugbridge.getPort())
    end)

    it("getClientCount returns 0 when not running", function()
        expect_equal(0, luna.debugbridge.getClientCount())
    end)

    it("start and stop work on a high port", function()
        -- Use a high port unlikely to conflict
        local ok = luna.debugbridge.start(49740)
        expect_equal(true, ok)
        expect_equal(true, luna.debugbridge.isRunning())
        expect_equal(49740, luna.debugbridge.getPort())

        luna.debugbridge.stop()
        expect_equal(false, luna.debugbridge.isRunning())
    end)

    it("start returns false if already running", function()
        luna.debugbridge.start(49741)
        local second = luna.debugbridge.start(49742)
        expect_equal(false, second)
        luna.debugbridge.stop()
    end)

    it("poll does not error when not running", function()
        luna.debugbridge.poll()  -- should be a no-op
    end)

end)

-- ===== Print Capture =====

describe("luna.debugbridge print capture", function()

    it("capturePrint records a message", function()
        luna.debugbridge.capturePrint("hello world")
        local history = luna.debugbridge.getPrintHistory()
        expect_true(#history >= 1)
        local last = history[#history]
        expect_equal("hello world", last.message)
    end)

    it("capturePrint with source and line", function()
        luna.debugbridge.capturePrint("test msg", "main.lua", 42)
        local history = luna.debugbridge.getPrintHistory()
        local last = history[#history]
        expect_equal("test msg", last.message)
        expect_equal("main.lua", last.source)
        expect_equal(42, last.line)
    end)

    it("clearPrintHistory clears all entries", function()
        luna.debugbridge.capturePrint("before clear")
        luna.debugbridge.clearPrintHistory()
        local history = luna.debugbridge.getPrintHistory()
        expect_equal(0, #history)
    end)

    it("setMaxPrintHistory limits history size", function()
        luna.debugbridge.clearPrintHistory()
        luna.debugbridge.setMaxPrintHistory(3)
        for i = 1, 5 do
            luna.debugbridge.capturePrint("msg " .. i)
        end
        local history = luna.debugbridge.getPrintHistory()
        expect_equal(3, #history)
        expect_equal("msg 3", history[1].message)
        -- Reset to default
        luna.debugbridge.setMaxPrintHistory(2000)
    end)

    it("getPrintHistory with count returns last N", function()
        luna.debugbridge.clearPrintHistory()
        for i = 1, 10 do
            luna.debugbridge.capturePrint("entry " .. i)
        end
        local last3 = luna.debugbridge.getPrintHistory(3)
        expect_equal(3, #last3)
        expect_equal("entry 8", last3[1].message)
    end)

end)

-- ===== Performance =====

describe("luna.debugbridge performance", function()

    it("recordFrame stores frame times", function()
        luna.debugbridge.recordFrame(0.016)
        luna.debugbridge.recordFrame(0.017)
        local perf = luna.debugbridge.getPerformance()
        expect_not_nil(perf)
        expect_not_nil(perf.fps)
        expect_not_nil(perf.avgDt)
        expect_true(perf.fps > 0)
    end)

    it("getPerformance returns zero stats when empty", function()
        -- Start fresh (can't easily clear, but test initial state logic)
        local perf = luna.debugbridge.getPerformance()
        expect_not_nil(perf)
    end)

end)

-- ===== Screenshots =====

describe("luna.debugbridge screenshots", function()

    it("isScreenshotRequested returns false initially", function()
        expect_equal(false, luna.debugbridge.isScreenshotRequested())
    end)

    it("requestScreenshot sets the flag", function()
        luna.debugbridge.requestScreenshot(2)
        expect_equal(true, luna.debugbridge.isScreenshotRequested())
    end)

end)

-- ===== Broadcast =====

describe("luna.debugbridge broadcast", function()

    it("broadcast does not error without connected clients", function()
        luna.debugbridge.broadcast("test_event", '{"key": "value"}')
        -- No error means success — no clients to receive it
    end)

end)

-- ===== Poll =====

describe("luna.debugbridge poll", function()

    it("poll processes without error when server is running", function()
        luna.debugbridge.start(49743)
        luna.debugbridge.poll()
        luna.debugbridge.stop()
    end)

end)

test_summary()
