-- tests/lua/test_devtools.lua
-- BDD-style integration tests for luna.devtools module

-- ===================================================================
-- Logger
-- ===================================================================
describe("luna.devtools logger", function()
    it("exists as a table", function()
        expect_not_nil(luna.devtools)
    end)

    it("defaults log level to info", function()
        expect_equal("info", luna.devtools.getLogLevel())
    end)

    it("can set and get log level", function()
        luna.devtools.setLogLevel("warn")
        expect_equal("warn", luna.devtools.getLogLevel())
        luna.devtools.setLogLevel("info")
    end)

    it("defaults log console to true", function()
        expect_equal(true, luna.devtools.getLogConsole())
    end)

    it("can toggle console logging", function()
        luna.devtools.setLogConsole(false)
        expect_equal(false, luna.devtools.getLogConsole())
        luna.devtools.setLogConsole(true)
    end)

    it("can set and get log file path", function()
        luna.devtools.setLogFile("test.log")
        expect_equal("test.log", luna.devtools.getLogFile())
        luna.devtools.setLogFile("")
    end)

    it("records log entries", function()
        luna.devtools.clearLog()
        luna.devtools.setLogConsole(false) -- suppress stderr noise
        luna.devtools.info("test message")
        local history = luna.devtools.getLogHistory()
        expect_true(#history >= 1)
        expect_equal("info", history[#history].level)
        expect_equal("test message", history[#history].message)
        luna.devtools.setLogConsole(true)
    end)

    it("filters below minimum level", function()
        luna.devtools.clearLog()
        luna.devtools.setLogConsole(false)
        luna.devtools.setLogLevel("error")
        luna.devtools.info("should be ignored")
        local history = luna.devtools.getLogHistory()
        expect_equal(0, #history)
        luna.devtools.setLogLevel("info")
        luna.devtools.setLogConsole(true)
    end)

    it("clearLog empties history", function()
        luna.devtools.setLogConsole(false)
        luna.devtools.info("will be cleared")
        luna.devtools.clearLog()
        expect_equal(0, #luna.devtools.getLogHistory())
        luna.devtools.setLogConsole(true)
    end)

    it("getLogHistory respects count", function()
        luna.devtools.clearLog()
        luna.devtools.setLogConsole(false)
        luna.devtools.info("a")
        luna.devtools.info("b")
        luna.devtools.info("c")
        local last2 = luna.devtools.getLogHistory(2)
        expect_equal(2, #last2)
        expect_equal("b", last2[1].message)
        expect_equal("c", last2[2].message)
        luna.devtools.setLogConsole(true)
    end)
end)

-- ===================================================================
-- Frame Statistics
-- ===================================================================
describe("luna.devtools frame stats", function()
    it("defaults frame history size to 300", function()
        expect_equal(300, luna.devtools.getFrameHistorySize())
    end)

    it("can record and retrieve frame times", function()
        luna.devtools.recordFrameTime(0.016)
        luna.devtools.recordFrameTime(0.017)
        local history = luna.devtools.getFrameHistory()
        expect_true(#history >= 2)
    end)

    it("computes frame stats", function()
        -- Record some known values
        for i = 1, 10 do
            luna.devtools.recordFrameTime(0.016)
        end
        local stats = luna.devtools.getFrameStats()
        expect_not_nil(stats.fps)
        expect_not_nil(stats.avg)
        expect_not_nil(stats.min)
        expect_not_nil(stats.max)
        expect_not_nil(stats.p50)
        expect_not_nil(stats.p95)
        expect_not_nil(stats.p99)
    end)

    it("can change frame history size", function()
        luna.devtools.setFrameHistorySize(50)
        expect_equal(50, luna.devtools.getFrameHistorySize())
        luna.devtools.setFrameHistorySize(300) -- restore
    end)

    it("clamps history size", function()
        luna.devtools.setFrameHistorySize(1)
        expect_equal(10, luna.devtools.getFrameHistorySize())
        luna.devtools.setFrameHistorySize(300)
    end)
end)

-- ===================================================================
-- Profiler
-- ===================================================================
describe("luna.devtools profiler", function()
    it("defaults profiling to disabled", function()
        expect_equal(false, luna.devtools.isProfilingEnabled())
    end)

    it("can enable profiling", function()
        luna.devtools.setProfilingEnabled(true)
        expect_equal(true, luna.devtools.isProfilingEnabled())
        luna.devtools.setProfilingEnabled(false)
    end)

    it("records and retrieves profile zones", function()
        luna.devtools.setProfilingEnabled(true)
        luna.devtools.profilePush("render")
        luna.devtools.profilePush("sprites")
        luna.devtools.profilePop()
        luna.devtools.profilePop()
        luna.devtools.profileFrame()
        expect_true(luna.devtools.getProfileFrameCount() >= 1)
        local data = luna.devtools.getProfileData()
        expect_true(#data >= 1)
        expect_equal("render", data[1].name)
        luna.devtools.resetProfile()
        luna.devtools.setProfilingEnabled(false)
    end)

    it("resetProfile clears all data", function()
        luna.devtools.setProfilingEnabled(true)
        luna.devtools.profilePush("test")
        luna.devtools.profilePop()
        luna.devtools.profileFrame()
        luna.devtools.resetProfile()
        expect_equal(0, luna.devtools.getProfileFrameCount())
        luna.devtools.setProfilingEnabled(false)
    end)
end)

-- ===================================================================
-- File Watcher
-- ===================================================================
describe("luna.devtools file watcher", function()
    it("starts with no watched paths", function()
        luna.devtools.clearWatches()
        expect_equal(0, #luna.devtools.getWatchedPaths())
    end)

    it("defaults watch interval to 0.5", function()
        local interval = luna.devtools.getWatchInterval()
        expect_true(math.abs(interval - 0.5) < 0.01)
    end)

    it("can set watch interval", function()
        luna.devtools.setWatchInterval(1.0)
        expect_true(math.abs(luna.devtools.getWatchInterval() - 1.0) < 0.01)
        luna.devtools.setWatchInterval(0.5)
    end)

    it("can watch and unwatch paths", function()
        luna.devtools.clearWatches()
        local added = luna.devtools.watch("nonexistent_test_file.txt")
        expect_true(added)
        expect_equal(1, #luna.devtools.getWatchedPaths())
        local removed = luna.devtools.unwatch("nonexistent_test_file.txt")
        expect_true(removed)
        expect_equal(0, #luna.devtools.getWatchedPaths())
    end)

    it("watch returns false if already watched", function()
        luna.devtools.clearWatches()
        luna.devtools.watch("test.txt")
        local second = luna.devtools.watch("test.txt")
        expect_equal(false, second)
        luna.devtools.clearWatches()
    end)
end)

-- ===================================================================
-- Debug Bridge
-- ===================================================================
describe("luna.devtools debug bridge", function()
    it("getCallStack returns a table", function()
        local stack = luna.devtools.getCallStack()
        expect_not_nil(stack)
    end)

    it("eval succeeds with valid code", function()
        local ok, result = luna.devtools.eval("return 1 + 2")
        expect_true(ok)
        expect_equal(3, result)
    end)

    it("eval fails with invalid code", function()
        local ok, err = luna.devtools.eval("invalid code here %%%")
        expect_equal(false, ok)
        expect_not_nil(err)
    end)
end)

-- ===================================================================
-- Console
-- ===================================================================
describe("luna.devtools console", function()
    it("defaults console to not open", function()
        expect_equal(false, luna.devtools.isConsoleOpen())
    end)

    it("openConsole marks it as open", function()
        luna.devtools.openConsole()
        expect_equal(true, luna.devtools.isConsoleOpen())
    end)
end)

test_summary()
