-- tests/lua/test_devtools.lua
-- BDD-style integration tests for lurek.devtools module

-- ===================================================================
-- Logger
-- ===================================================================

-- @description Covers suite: lurek.devtools logger.
describe("lurek.devtools logger", function()
    -- @covers lurek.devtools
    -- @covers lurek.devtools.clearLog
    -- @covers lurek.devtools.clearWatches
    -- @covers lurek.devtools.eval
    -- @covers lurek.devtools.getCallStack
    -- @covers lurek.devtools.getFrameHistory
    -- @covers lurek.devtools.getFrameHistorySize
    -- @covers lurek.devtools.getFrameStats
    -- @covers lurek.devtools.getLogConsole
    -- @covers lurek.devtools.getLogFile
    -- @covers lurek.devtools.getLogHistory
    -- @covers lurek.devtools.getLogLevel
    -- @covers lurek.devtools.getProfileData
    -- @covers lurek.devtools.getProfileFrameCount
    -- @covers lurek.devtools.getWatchInterval
    -- @covers lurek.devtools.getWatchedPaths
    -- @covers lurek.devtools.info
    -- @covers lurek.devtools.isConsoleOpen
    -- @covers lurek.devtools.isProfilingEnabled
    -- @covers lurek.devtools.openConsole
    -- @covers lurek.devtools.profileFrame
    -- @covers lurek.devtools.profilePop
    -- @covers lurek.devtools.profilePush
    -- @covers lurek.devtools.recordFrameTime
    -- @covers lurek.devtools.resetProfile
    -- @covers lurek.devtools.setFrameHistorySize
    -- @covers lurek.devtools.setLogConsole
    -- @covers lurek.devtools.setLogFile
    -- @covers lurek.devtools.setLogLevel
    -- @covers lurek.devtools.setProfilingEnabled
    -- @covers lurek.devtools.setWatchInterval
    -- @covers lurek.devtools.unwatch
    -- @covers lurek.devtools.watch
    -- @description Verifies the devtools namespace is registered.
    it("exists as a table", function()
        expect_not_nil(lurek.devtools)
    end)

    -- @covers lurek.devtools.getLogLevel
    -- @description Verifies the default log threshold starts at info.
    it("defaults log level to info", function()
        expect_equal("info", lurek.devtools.getLogLevel())
    end)

    -- @covers lurek.devtools.setLogLevel
    -- @covers lurek.devtools.getLogLevel
    -- @description Verifies log level changes round-trip through the setter/getter pair.
    it("can set and get log level", function()
        lurek.devtools.setLogLevel("warn")
        expect_equal("warn", lurek.devtools.getLogLevel())
        lurek.devtools.setLogLevel("info")
    end)

    -- @covers lurek.devtools.getLogConsole
    -- @description Verifies console logging is enabled by default.
    it("defaults log console to true", function()
        expect_equal(true, lurek.devtools.getLogConsole())
    end)

    -- @covers lurek.devtools.setLogConsole
    -- @covers lurek.devtools.getLogConsole
    -- @description Verifies console logging can be toggled off and back on.
    it("can toggle console logging", function()
        lurek.devtools.setLogConsole(false)
        expect_equal(false, lurek.devtools.getLogConsole())
        lurek.devtools.setLogConsole(true)
    end)

    -- @covers lurek.devtools.setLogFile
    -- @covers lurek.devtools.getLogFile
    -- @description Verifies the log file path round-trips through the devtools logger state.
    it("can set and get log file path", function()
        lurek.devtools.setLogFile("test.log")
        expect_equal("test.log", lurek.devtools.getLogFile())
        lurek.devtools.setLogFile("")
    end)

    -- @covers lurek.devtools.clearLog
    -- @covers lurek.devtools.info
    -- @covers lurek.devtools.getLogHistory
    -- @description Verifies info messages are recorded with level and message fields in the in-memory log history.
    it("records log entries", function()
        lurek.devtools.clearLog()
        lurek.devtools.setLogConsole(false) -- suppress stderr noise
        lurek.devtools.info("test message")
        local history = lurek.devtools.getLogHistory()
        expect_true(#history >= 1)
        expect_equal("info", history[#history].level)
        expect_equal("test message", history[#history].message)
        lurek.devtools.setLogConsole(true)
    end)

    -- @covers lurek.devtools.clearLog
    -- @covers lurek.devtools.setLogLevel
    -- @covers lurek.devtools.info
    -- @covers lurek.devtools.getLogHistory
    -- @description Verifies messages below the active log level are excluded from stored history.
    it("filters below minimum level", function()
        lurek.devtools.clearLog()
        lurek.devtools.setLogConsole(false)
        lurek.devtools.setLogLevel("error")
        lurek.devtools.info("should be ignored")
        local history = lurek.devtools.getLogHistory()
        expect_equal(0, #history)
        lurek.devtools.setLogLevel("info")
        lurek.devtools.setLogConsole(true)
    end)

    -- @covers lurek.devtools.clearLog
    -- @covers lurek.devtools.getLogHistory
    -- @description Verifies clearLog empties the accumulated logger history.
    it("clearLog empties history", function()
        lurek.devtools.setLogConsole(false)
        lurek.devtools.info("will be cleared")
        lurek.devtools.clearLog()
        expect_equal(0, #lurek.devtools.getLogHistory())
        lurek.devtools.setLogConsole(true)
    end)

    -- @covers lurek.devtools.getLogHistory
    -- @description Verifies getLogHistory(count) returns only the trailing entries.
    it("getLogHistory respects count", function()
        lurek.devtools.clearLog()
        lurek.devtools.setLogConsole(false)
        lurek.devtools.info("a")
        lurek.devtools.info("b")
        lurek.devtools.info("c")
        local last2 = lurek.devtools.getLogHistory(2)
        expect_equal(2, #last2)
        expect_equal("b", last2[1].message)
        expect_equal("c", last2[2].message)
        lurek.devtools.setLogConsole(true)
    end)
end)

-- ===================================================================
-- Frame Statistics
-- ===================================================================
-- @description Covers suite: lurek.devtools frame stats.
describe("lurek.devtools frame stats", function()
    -- @covers lurek.devtools.getFrameHistorySize
    -- @description Verifies the frame history buffer starts at the default size.
    it("defaults frame history size to 300", function()
        expect_equal(300, lurek.devtools.getFrameHistorySize())
    end)

    -- @covers lurek.devtools.recordFrameTime
    -- @covers lurek.devtools.getFrameHistory
    -- @description Verifies recorded frame times are appended to the history buffer.
    it("can record and retrieve frame times", function()
        lurek.devtools.recordFrameTime(0.016)
        lurek.devtools.recordFrameTime(0.017)
        local history = lurek.devtools.getFrameHistory()
        expect_true(#history >= 2)
    end)

    -- @covers lurek.devtools.recordFrameTime
    -- @covers lurek.devtools.getFrameStats
    -- @description Verifies computed frame statistics include aggregate fields like fps and percentiles.
    it("computes frame stats", function()
        -- Record some known values
        for i = 1, 10 do
            lurek.devtools.recordFrameTime(0.016)
        end
        local stats = lurek.devtools.getFrameStats()
        expect_not_nil(stats.fps)
        expect_not_nil(stats.avg)
        expect_not_nil(stats.min)
        expect_not_nil(stats.max)
        expect_not_nil(stats.p50)
        expect_not_nil(stats.p95)
        expect_not_nil(stats.p99)
    end)

    -- @covers lurek.devtools.setFrameHistorySize
    -- @covers lurek.devtools.getFrameHistorySize
    -- @description Verifies the frame history capacity can be changed and retrieved.
    it("can change frame history size", function()
        lurek.devtools.setFrameHistorySize(50)
        expect_equal(50, lurek.devtools.getFrameHistorySize())
        lurek.devtools.setFrameHistorySize(300) -- restore
    end)

    -- @covers lurek.devtools.setFrameHistorySize
    -- @covers lurek.devtools.getFrameHistorySize
    -- @description Verifies history size requests are clamped to the module minimum.
    it("clamps history size", function()
        lurek.devtools.setFrameHistorySize(1)
        expect_equal(10, lurek.devtools.getFrameHistorySize())
        lurek.devtools.setFrameHistorySize(300)
    end)
end)

-- ===================================================================
-- Profiler
-- ===================================================================
-- @description Covers suite: lurek.devtools profiler.
describe("lurek.devtools profiler", function()
    -- @covers lurek.devtools.isProfilingEnabled
    -- @description Verifies profiling starts disabled.
    it("defaults profiling to disabled", function()
        expect_equal(false, lurek.devtools.isProfilingEnabled())
    end)

    -- @covers lurek.devtools.setProfilingEnabled
    -- @covers lurek.devtools.isProfilingEnabled
    -- @description Verifies profiling can be toggled on and observed through the query API.
    it("can enable profiling", function()
        lurek.devtools.setProfilingEnabled(true)
        expect_equal(true, lurek.devtools.isProfilingEnabled())
        lurek.devtools.setProfilingEnabled(false)
    end)

    -- @covers lurek.devtools.profilePush
    -- @covers lurek.devtools.profilePop
    -- @covers lurek.devtools.profileFrame
    -- @covers lurek.devtools.getProfileFrameCount
    -- @covers lurek.devtools.getProfileData
    -- @description Verifies nested profile zones are recorded into a completed profile frame.
    it("records and retrieves profile zones", function()
        lurek.devtools.setProfilingEnabled(true)
        lurek.devtools.profilePush("render")
        lurek.devtools.profilePush("sprites")
        lurek.devtools.profilePop()
        lurek.devtools.profilePop()
        lurek.devtools.profileFrame()
        expect_true(lurek.devtools.getProfileFrameCount() >= 1)
        local data = lurek.devtools.getProfileData()
        expect_true(#data >= 1)
        expect_equal("render", data[1].name)
        lurek.devtools.resetProfile()
        lurek.devtools.setProfilingEnabled(false)
    end)

    -- @covers lurek.devtools.resetProfile
    -- @covers lurek.devtools.getProfileFrameCount
    -- @description Verifies resetProfile clears accumulated profiler frames.
    it("resetProfile clears all data", function()
        lurek.devtools.setProfilingEnabled(true)
        lurek.devtools.profilePush("test")
        lurek.devtools.profilePop()
        lurek.devtools.profileFrame()
        lurek.devtools.resetProfile()
        expect_equal(0, lurek.devtools.getProfileFrameCount())
        lurek.devtools.setProfilingEnabled(false)
    end)
end)

-- ===================================================================
-- File Watcher
-- ===================================================================
-- @description Covers suite: lurek.devtools file watcher.
describe("lurek.devtools file watcher", function()
    -- @covers lurek.devtools.clearWatches
    -- @covers lurek.devtools.getWatchedPaths
    -- @description Verifies the watcher registry can be reset to an empty state.
    it("starts with no watched paths", function()
        lurek.devtools.clearWatches()
        expect_equal(0, #lurek.devtools.getWatchedPaths())
    end)

    -- @covers lurek.devtools.getWatchInterval
    -- @description Verifies the watch polling interval starts at the default half-second value.
    it("defaults watch interval to 0.5", function()
        local interval = lurek.devtools.getWatchInterval()
        expect_true(math.abs(interval - 0.5) < 0.01)
    end)

    -- @covers lurek.devtools.setWatchInterval
    -- @covers lurek.devtools.getWatchInterval
    -- @description Verifies the watch polling interval can be updated and read back.
    it("can set watch interval", function()
        lurek.devtools.setWatchInterval(1.0)
        expect_true(math.abs(lurek.devtools.getWatchInterval() - 1.0) < 0.01)
        lurek.devtools.setWatchInterval(0.5)
    end)

    -- @covers lurek.devtools.watch
    -- @covers lurek.devtools.unwatch
    -- @covers lurek.devtools.getWatchedPaths
    -- @description Verifies watching and unwatching a path updates the watched-path registry.
    it("can watch and unwatch paths", function()
        lurek.devtools.clearWatches()
        local added = lurek.devtools.watch("nonexistent_test_file.txt")
        expect_true(added)
        expect_equal(1, #lurek.devtools.getWatchedPaths())
        local removed = lurek.devtools.unwatch("nonexistent_test_file.txt")
        expect_true(removed)
        expect_equal(0, #lurek.devtools.getWatchedPaths())
    end)

    -- @covers lurek.devtools.watch
    -- @description Verifies duplicate watch registration requests are rejected.
    it("watch returns false if already watched", function()
        lurek.devtools.clearWatches()
        lurek.devtools.watch("test.txt")
        local second = lurek.devtools.watch("test.txt")
        expect_equal(false, second)
        lurek.devtools.clearWatches()
    end)
end)

-- ===================================================================
-- Debug Bridge
-- ===================================================================
-- @description Covers suite: lurek.devtools debug bridge.
describe("lurek.devtools debug bridge", function()
    -- @covers lurek.devtools.getCallStack
    -- @description Verifies getCallStack returns a table-shaped stack snapshot.
    it("getCallStack returns a table", function()
        local stack = lurek.devtools.getCallStack()
        expect_not_nil(stack)
    end)

    -- @covers lurek.devtools.eval
    -- @description Verifies eval executes valid Lua code and returns a success flag with the computed result.
    it("eval succeeds with valid code", function()
        local ok, result = lurek.devtools.eval("return 1 + 2")
        expect_true(ok)
        expect_equal(3, result)
    end)

    -- @covers lurek.devtools.eval
    -- @description Verifies eval reports syntax errors without throwing.
    it("eval fails with invalid code", function()
        local ok, err = lurek.devtools.eval("invalid code here %%%")
        expect_equal(false, ok)
        expect_not_nil(err)
    end)
end)

-- ===================================================================
-- Console
-- ===================================================================
-- @description Covers suite: lurek.devtools console.
describe("lurek.devtools console", function()
    -- @covers lurek.devtools.isConsoleOpen
    -- @description Verifies the debug console starts closed.
    it("defaults console to not open", function()
        expect_equal(false, lurek.devtools.isConsoleOpen())
    end)

    -- @covers lurek.devtools.openConsole
    -- @covers lurek.devtools.isConsoleOpen
    -- @description Verifies opening the console flips the console-open query state.
    it("openConsole marks it as open", function()
        lurek.devtools.openConsole()
        expect_equal(true, lurek.devtools.isConsoleOpen())
    end)
end)

-- @description Tests for new devtools features: profilerReport and newFileWatcher.
describe("lurek.devtools new features", function()
  -- @covers lurek.devtools.profilerReport
  -- @description profilerReport returns a table (may be empty if no frames recorded).
  it("profilerReport returns a table", function()
    local report = lurek.devtools.profilerReport()
    expect_equal(type(report), "table")
  end)

  -- @covers lurek.devtools.newFileWatcher
  -- @description newFileWatcher returns a userdata with check(), onChanged() and getPath() methods.
  it("newFileWatcher returns a userdata with expected methods", function()
    local watcher = lurek.devtools.newFileWatcher(".")
    expect_true(watcher ~= nil, "watcher must not be nil")
    expect_equal(type(watcher.check), "function")
    expect_equal(type(watcher.onChanged), "function")
    expect_equal(type(watcher.getPath), "function")
    expect_equal(type(watcher.cancel), "function")
  end)

  -- @covers lurek.devtools.newFileWatcher
  -- @description getPath returns the path passed to newFileWatcher.
  it("newFileWatcher getPath returns the watched path", function()
    local watcher = lurek.devtools.newFileWatcher("content")
    expect_equal(watcher:getPath(), "content")
  end)

  -- @covers lurek.devtools.newFileWatcher
  -- @description check() runs without error on a valid path.
  it("newFileWatcher check does not error on valid path", function()
    local watcher = lurek.devtools.newFileWatcher(".")
    expect_no_error(function() watcher:check() end)
  end)

  -- @covers lurek.devtools.newFileWatcher
  -- @description cancel() removes the callback without error.
  it("newFileWatcher cancel does not error", function()
    local watcher = lurek.devtools.newFileWatcher(".")
    watcher:onChanged(function() end)
    expect_no_error(function() watcher:cancel() end)
  end)
end)

test_summary()
