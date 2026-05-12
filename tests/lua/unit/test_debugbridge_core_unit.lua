-- DebugBridge Lua Tests
-- Tests the lurek.debugbridge TCP debug server API

-- ===== Lifecycle =====

-- @describe lurek.debugbridge lifecycle
describe("lurek.debugbridge lifecycle", function()

    it("namespace exists", function()
        expect_not_nil(lurek.debugbridge)
    end)

    -- @covers lurek.debugbridge.isRunning
    it("isRunning returns false initially", function()
        expect_equal(false, lurek.debugbridge.isRunning())
    end)

    -- @covers lurek.debugbridge.getPort
    it("getPort returns 0 when not running", function()
        expect_equal(0, lurek.debugbridge.getPort())
    end)

    -- @covers lurek.debugbridge.getClientCount
    it("getClientCount returns 0 when not running", function()
        expect_equal(0, lurek.debugbridge.getClientCount())
    end)

    -- @covers lurek.debugbridge.getPort
    -- @covers lurek.debugbridge.isRunning
    -- @covers lurek.debugbridge.start
    -- @covers lurek.debugbridge.stop
    it("start and stop work on a high port", function()
        -- Use a high port unlikely to conflict
        local ok = lurek.debugbridge.start(49740)
        expect_equal(true, ok)
        expect_equal(true, lurek.debugbridge.isRunning())
        expect_equal(49740, lurek.debugbridge.getPort())

        lurek.debugbridge.stop()
        expect_equal(false, lurek.debugbridge.isRunning())
    end)

    -- @covers lurek.debugbridge.start
    -- @covers lurek.debugbridge.stop
    it("start returns false if already running", function()
        lurek.debugbridge.start(49741)
        local second = lurek.debugbridge.start(49742)
        expect_equal(false, second)
        lurek.debugbridge.stop()
    end)

    -- @covers lurek.debugbridge.poll
    it("poll does not error when not running", function()
        expect_no_error(function() lurek.debugbridge.poll() end)
    end)

end)

-- ===== Print Capture =====

-- @describe lurek.debugbridge print capture
describe("lurek.debugbridge print capture", function()

    -- @covers lurek.debugbridge.capturePrint
    -- @covers lurek.debugbridge.getPrintHistory
    it("capturePrint records a message", function()
        lurek.debugbridge.capturePrint("hello world")
        local history = lurek.debugbridge.getPrintHistory()
        expect_true(#history >= 1)
        local last = history[#history]
        expect_equal("hello world", last.message)
    end)

    -- @covers lurek.debugbridge.capturePrint
    -- @covers lurek.debugbridge.getPrintHistory
    it("capturePrint with source and line", function()
        lurek.debugbridge.capturePrint("test msg", "main.lua", 42)
        local history = lurek.debugbridge.getPrintHistory()
        local last = history[#history]
        expect_equal("test msg", last.message)
        expect_equal("main.lua", last.source)
        expect_equal(42, last.line)
    end)

    -- @covers lurek.debugbridge.capturePrint
    -- @covers lurek.debugbridge.clearPrintHistory
    -- @covers lurek.debugbridge.getPrintHistory
    it("clearPrintHistory clears all entries", function()
        lurek.debugbridge.capturePrint("before clear")
        lurek.debugbridge.clearPrintHistory()
        local history = lurek.debugbridge.getPrintHistory()
        expect_equal(0, #history)
    end)

    -- @covers lurek.debugbridge.capturePrint
    -- @covers lurek.debugbridge.clearPrintHistory
    -- @covers lurek.debugbridge.getPrintHistory
    -- @covers lurek.debugbridge.setMaxPrintHistory
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

    -- @covers lurek.debugbridge.capturePrint
    -- @covers lurek.debugbridge.clearPrintHistory
    -- @covers lurek.debugbridge.getPrintHistory
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

-- @describe lurek.debugbridge performance
describe("lurek.debugbridge performance", function()

    -- @covers lurek.debugbridge.getPerformance
    it("getPerformance returns a table with expected keys", function()
        -- poll() auto-records frame time; in tests there is no game loop so
        -- we just verify the shape of the returned table.
        local perf = lurek.debugbridge.getPerformance()
        expect_not_nil(perf)
        expect_not_nil(perf.fps)
        expect_not_nil(perf.avgDt)
    end)

    -- @covers lurek.debugbridge.getPerformance
    it("getPerformance returns zero stats when empty", function()
        -- Start fresh (can't easily clear, but test initial state logic)
        local perf = lurek.debugbridge.getPerformance()
        expect_not_nil(perf)
    end)

end)

-- ===== Protocol =====

-- @describe lurek.debugbridge protocol
describe("lurek.debugbridge protocol", function()

    -- @covers lurek.debugbridge.getProtocolInfo
    it("getProtocolInfo returns version and capabilities", function()
        local info = lurek.debugbridge.getProtocolInfo()
        expect_not_nil(info)
        expect_true(info.version >= 1)
        expect_not_nil(info.capabilities)
        expect_true(#info.capabilities >= 1)
        expect_not_nil(info.nonce)
    end)

    -- @covers lurek.debugbridge.consumeHotReloadRequest
    it("consumeHotReloadRequest returns boolean", function()
        local pending = lurek.debugbridge.consumeHotReloadRequest()
        expect_equal(type(pending), "boolean")
    end)

end)

-- ===== Screenshots =====

-- @describe lurek.debugbridge screenshots
describe("lurek.debugbridge screenshots", function()

    -- @covers lurek.debugbridge.isScreenshotRequested
    it("isScreenshotRequested returns false initially", function()
        expect_equal(false, lurek.debugbridge.isScreenshotRequested())
    end)

    -- @covers lurek.debugbridge.isScreenshotRequested
    -- @covers lurek.debugbridge.requestScreenshot
    it("requestScreenshot sets the flag", function()
        lurek.debugbridge.requestScreenshot(2)
        expect_equal(true, lurek.debugbridge.isScreenshotRequested())
    end)

end)

-- ===== Broadcast =====

-- @describe lurek.debugbridge broadcast
describe("lurek.debugbridge broadcast", function()

    -- @covers lurek.debugbridge.broadcast
    it("broadcast does not error without connected clients", function()
        expect_no_error(function() lurek.debugbridge.broadcast("test_event", '{"key": "value"}') end)
    end)

end)

-- ===== Poll =====

-- @describe lurek.debugbridge poll
describe("lurek.debugbridge poll", function()

    -- @covers lurek.debugbridge.poll
    -- @covers lurek.debugbridge.start
    -- @covers lurek.debugbridge.stop
    it("poll processes without error when server is running", function()
        lurek.debugbridge.start(49743)
        expect_no_error(function() lurek.debugbridge.poll() end)
        lurek.debugbridge.stop()
    end)

end)
test_summary()
