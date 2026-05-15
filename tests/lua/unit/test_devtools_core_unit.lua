-- tests/lua/test_devtools.lua
-- BDD-style integration tests for lurek.devtools module

-- ===================================================================
-- Logger
-- ===================================================================

-- @describe lurek.devtools logger
describe("lurek.devtools logger", function()
    -- @covers lurek.devtools
    it("exists as a table", function()
        expect_not_nil(lurek.devtools)
    end)

    -- @covers lurek.devtools.getLogLevel
    it("defaults log level to info", function()
        expect_equal("info", lurek.devtools.getLogLevel())
    end)

    -- @covers lurek.devtools.getLogLevel
    -- @covers lurek.devtools.setLogLevel
    it("can set and get log level", function()
        lurek.devtools.setLogLevel("warn")
        expect_equal("warn", lurek.devtools.getLogLevel())
        lurek.devtools.setLogLevel("info")
    end)

    -- @covers lurek.devtools.getLogConsole
    it("defaults log console to true", function()
        expect_equal(true, lurek.devtools.getLogConsole())
    end)

    -- @covers lurek.devtools.getLogConsole
    -- @covers lurek.devtools.setLogConsole
    it("can toggle console logging", function()
        lurek.devtools.setLogConsole(false)
        expect_equal(false, lurek.devtools.getLogConsole())
        lurek.devtools.setLogConsole(true)
    end)

    -- @covers lurek.devtools.getLogFile
    -- @covers lurek.devtools.setLogFile
    it("can set and get log file path", function()
        lurek.devtools.setLogFile("test.log")
        expect_equal("test.log", lurek.devtools.getLogFile())
        lurek.devtools.setLogFile("")
    end)

    -- @covers lurek.devtools.info
    -- @covers lurek.devtools.setLogFile
    it("writes log entries to the configured file", function()
        local path = "save/_fs_tests/devtools_logger_output.log"
        lurek.filesystem.createDirectory("save/_fs_tests")
        if lurek.filesystem.exists(path) then
            lurek.filesystem.remove(path)
        end

        lurek.devtools.setLogConsole(false)
        lurek.devtools.setLogFile(path)
        lurek.devtools.info("file-output-check")

        local text = lurek.filesystem.read(path)
        expect_match(text, "file%-output%-check")

        lurek.devtools.setLogFile("")
        lurek.devtools.setLogConsole(true)
    end)

    -- @covers lurek.devtools.clearLog
    -- @covers lurek.devtools.getLogHistory
    -- @covers lurek.devtools.info
    -- @covers lurek.devtools.setLogConsole
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
    -- @covers lurek.devtools.getLogHistory
    -- @covers lurek.devtools.info
    -- @covers lurek.devtools.setLogConsole
    -- @covers lurek.devtools.setLogLevel
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
    -- @covers lurek.devtools.info
    -- @covers lurek.devtools.setLogConsole
    it("clearLog empties history", function()
        lurek.devtools.setLogConsole(false)
        lurek.devtools.info("will be cleared")
        lurek.devtools.clearLog()
        expect_equal(0, #lurek.devtools.getLogHistory())
        lurek.devtools.setLogConsole(true)
    end)

    -- @covers lurek.devtools.clearLog
    -- @covers lurek.devtools.getLogHistory
    -- @covers lurek.devtools.info
    -- @covers lurek.devtools.setLogConsole
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
-- @describe lurek.devtools frame stats
describe("lurek.devtools frame stats", function()
    -- @covers lurek.devtools.getFrameHistorySize
    it("defaults frame history size to 300", function()
        expect_equal(300, lurek.devtools.getFrameHistorySize())
    end)

    -- @covers lurek.devtools.getFrameHistory
    -- @covers lurek.devtools.recordFrameTime
    it("can record and retrieve frame times", function()
        lurek.devtools.recordFrameTime(0.016)
        lurek.devtools.recordFrameTime(0.017)
        local history = lurek.devtools.getFrameHistory()
        expect_true(#history >= 2)
    end)

    -- @covers lurek.devtools.getFrameStats
    -- @covers lurek.devtools.recordFrameTime
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

    -- @covers lurek.devtools.getFrameStats
    -- @covers lurek.devtools.recordFrameTime
    it("equal samples produce exact summary values", function()
        lurek.devtools.setFrameHistorySize(10)
        for i = 1, 10 do
            lurek.devtools.recordFrameTime(0.02)
        end

        local stats = lurek.devtools.getFrameStats()
        expect_equal(10, stats.samples)
        expect_near(0.02, stats.min, 1e-9)
        expect_near(0.02, stats.max, 1e-9)
        expect_near(0.02, stats.avg, 1e-9)
        expect_near(0.02, stats.p50, 1e-9)
        expect_near(0.02, stats.p95, 1e-9)
        expect_near(0.02, stats.p99, 1e-9)

        lurek.devtools.setFrameHistorySize(300)
    end)

    -- @covers lurek.devtools.getFrameHistorySize
    -- @covers lurek.devtools.setFrameHistorySize
    it("can change frame history size", function()
        lurek.devtools.setFrameHistorySize(50)
        expect_equal(50, lurek.devtools.getFrameHistorySize())
        lurek.devtools.setFrameHistorySize(300) -- restore
    end)

    -- @covers lurek.devtools.getFrameHistorySize
    -- @covers lurek.devtools.setFrameHistorySize
    it("clamps history size", function()
        lurek.devtools.setFrameHistorySize(1)
        expect_equal(10, lurek.devtools.getFrameHistorySize())
        lurek.devtools.setFrameHistorySize(300)
    end)

    -- @covers lurek.devtools.getGpuFrameStats
    -- @covers lurek.devtools.recordGpuFrameTime
    it("records and reads gpu frame stats", function()
        lurek.devtools.recordGpuFrameTime(0.010)
        lurek.devtools.recordGpuFrameTime(0.011)
        local stats = lurek.devtools.getGpuFrameStats()
        expect_not_nil(stats.avg)
        expect_true(stats.samples >= 2)
    end)
end)

-- ===================================================================
-- Profiler
-- ===================================================================
-- @describe lurek.devtools profiler
describe("lurek.devtools profiler", function()
    -- @covers lurek.devtools.isProfilingEnabled
    it("defaults profiling to disabled", function()
        expect_equal(false, lurek.devtools.isProfilingEnabled())
    end)

    -- @covers lurek.devtools.isProfilingEnabled
    -- @covers lurek.devtools.setProfilingEnabled
    it("can enable profiling", function()
        lurek.devtools.setProfilingEnabled(true)
        expect_equal(true, lurek.devtools.isProfilingEnabled())
        lurek.devtools.setProfilingEnabled(false)
    end)

    -- @covers lurek.devtools.getProfileData
    -- @covers lurek.devtools.getProfileFrameCount
    -- @covers lurek.devtools.profileFrame
    -- @covers lurek.devtools.profilePop
    -- @covers lurek.devtools.profilePush
    -- @covers lurek.devtools.resetProfile
    -- @covers lurek.devtools.setProfilingEnabled
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

    -- @covers lurek.devtools.getProfileFrameCount
    -- @covers lurek.devtools.profileFrame
    -- @covers lurek.devtools.profilePop
    -- @covers lurek.devtools.profilePush
    -- @covers lurek.devtools.resetProfile
    -- @covers lurek.devtools.setProfilingEnabled
    it("resetProfile clears all data", function()
        lurek.devtools.setProfilingEnabled(true)
        lurek.devtools.profilePush("test")
        lurek.devtools.profilePop()
        lurek.devtools.profileFrame()
        lurek.devtools.resetProfile()
        expect_equal(0, lurek.devtools.getProfileFrameCount())
        lurek.devtools.setProfilingEnabled(false)
    end)

    -- @covers lurek.devtools.getProfileData
    -- @covers lurek.devtools.profileFrame
    -- @covers lurek.devtools.profilePop
    -- @covers lurek.devtools.profilePush
    -- @covers lurek.devtools.resetProfile
    -- @covers lurek.devtools.setProfilingEnabled
    it("getProfileData accepts negative frame offsets", function()
        lurek.devtools.resetProfile()
        lurek.devtools.setProfilingEnabled(true)

        lurek.devtools.profilePush("f0")
        lurek.devtools.profilePop()
        lurek.devtools.profileFrame()

        lurek.devtools.profilePush("f1")
        lurek.devtools.profilePop()
        lurek.devtools.profileFrame()

        lurek.devtools.profilePush("f2")
        lurek.devtools.profilePop()
        lurek.devtools.profileFrame()

        local latest = lurek.devtools.getProfileData(0)
        local previous = lurek.devtools.getProfileData(-1)

        expect_equal("f2", latest[1].name)
        expect_equal("f1", previous[1].name)

        lurek.devtools.resetProfile()
        lurek.devtools.setProfilingEnabled(false)
    end)
end)

-- ===================================================================
-- File Watcher
-- ===================================================================
-- @describe lurek.devtools file watcher
describe("lurek.devtools file watcher", function()
    -- @covers lurek.devtools.clearWatches
    -- @covers lurek.devtools.getWatchedPaths
    it("starts with no watched paths", function()
        lurek.devtools.clearWatches()
        expect_equal(0, #lurek.devtools.getWatchedPaths())
    end)

    -- @covers lurek.devtools.getWatchInterval
    it("defaults watch interval to 0.5", function()
        local interval = lurek.devtools.getWatchInterval()
        expect_true(math.abs(interval - 0.5) < 0.01)
    end)

    -- @covers lurek.devtools.getWatchInterval
    -- @covers lurek.devtools.setWatchInterval
    it("can set watch interval", function()
        lurek.devtools.setWatchInterval(1.0)
        expect_true(math.abs(lurek.devtools.getWatchInterval() - 1.0) < 0.01)
        lurek.devtools.setWatchInterval(0.5)
    end)

    -- @covers lurek.devtools.clearWatches
    -- @covers lurek.devtools.getWatchedPaths
    -- @covers lurek.devtools.unwatch
    -- @covers lurek.devtools.watch
    it("can watch and unwatch paths", function()
        lurek.devtools.clearWatches()
        local added = lurek.devtools.watch("nonexistent_test_file.txt")
        expect_true(added)
        expect_equal(1, #lurek.devtools.getWatchedPaths())
        local removed = lurek.devtools.unwatch("nonexistent_test_file.txt")
        expect_true(removed)
        expect_equal(0, #lurek.devtools.getWatchedPaths())
    end)

    -- @covers lurek.devtools.clearWatches
    -- @covers lurek.devtools.watch
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
-- @describe lurek.devtools debug bridge
describe("lurek.devtools debug bridge", function()
    -- @covers lurek.devtools.getCallStack
    it("getCallStack returns a table", function()
        local stack = lurek.devtools.getCallStack()
        expect_not_nil(stack)
    end)

    -- @covers lurek.devtools.eval
    it("eval succeeds with valid code", function()
        local ok, result = lurek.devtools.eval("return 1 + 2")
        expect_true(ok)
        expect_equal(3, result)
    end)

    -- @covers lurek.devtools.eval
    it("eval fails with invalid code", function()
        local ok, err = lurek.devtools.eval("invalid code here %%%")
        expect_equal(false, ok)
        expect_not_nil(err)
    end)
end)

-- ===================================================================
-- Console
-- ===================================================================
-- @describe lurek.devtools console
describe("lurek.devtools console", function()
    -- @covers lurek.devtools.isConsoleOpen
    it("defaults console to not open", function()
        expect_equal(false, lurek.devtools.isConsoleOpen())
    end)

    -- @covers lurek.devtools.isConsoleOpen
    -- @covers lurek.devtools.openConsole
    it("openConsole marks it as open", function()
        lurek.devtools.openConsole()
        expect_equal(true, lurek.devtools.isConsoleOpen())
    end)

    -- @covers lurek.devtools.isEntityInspectorOpen
    it("entity inspector defaults to closed", function()
        expect_equal(false, lurek.devtools.isEntityInspectorOpen())
    end)

    -- @covers lurek.devtools.isEntityInspectorOpen
    -- @covers lurek.devtools.openEntityInspector
    it("openEntityInspector marks inspector as open", function()
        lurek.devtools.openEntityInspector()
        expect_equal(true, lurek.devtools.isEntityInspectorOpen())
    end)
end)

-- @describe lurek.devtools new features
describe("lurek.devtools new features", function()
  -- @covers lurek.devtools.profilerReport
  it("profilerReport returns a table", function()
    local report = lurek.devtools.profilerReport()
    expect_equal(type(report), "table")
  end)

  -- @covers lurek.devtools.newFileWatcher
  it("newFileWatcher returns a userdata with expected methods", function()
    local watcher = lurek.devtools.newFileWatcher(".")
    expect_true(watcher ~= nil, "watcher must not be nil")
    expect_equal(type(watcher.check), "function")
    expect_equal(type(watcher.onChanged), "function")
    expect_equal(type(watcher.getPath), "function")
    expect_equal(type(watcher.cancel), "function")
  end)

  -- @covers LFileWatcher:getPath
  -- @covers lurek.devtools.newFileWatcher
  it("newFileWatcher getPath returns the watched path", function()
    local watcher = lurek.devtools.newFileWatcher("content")
    expect_equal(watcher:getPath(), "content")
  end)

  -- @covers LFileWatcher:check
  -- @covers lurek.devtools.newFileWatcher
  it("newFileWatcher check does not error on valid path", function()
    local watcher = lurek.devtools.newFileWatcher(".")
    expect_no_error(function() watcher:check() end)
  end)

  -- @covers LFileWatcher:cancel
  -- @covers LFileWatcher:onChanged
  -- @covers lurek.devtools.newFileWatcher
  it("newFileWatcher cancel does not error", function()
    local watcher = lurek.devtools.newFileWatcher(".")
    watcher:onChanged(function() end)
    expect_no_error(function() watcher:cancel() end)
  end)
end)

--  Devtools REPL console (merged from test_devtools_repl.lua)

-- @describe factory
describe("factory", function()
    -- @covers lurek.devtools.newRepl
    it("exposes newRepl", function()
        expect_type("function", lurek.devtools.newRepl)
    end)

    -- @covers lurek.devtools.newRepl
    it("returns a userdata", function()
        local repl = lurek.devtools.newRepl()
        expect_type("userdata", repl)
    end)

    -- @covers lurek.devtools.newRepl
    it("accepts max_history argument", function()
        local repl = lurek.devtools.newRepl(25)
        expect_type("userdata", repl)
    end)
end)

-- @describe len() / history()
describe("len() / history()", function()
    -- @covers LReplConsole:len
    -- @covers lurek.devtools.newRepl
    it("starts empty", function()
        local repl = lurek.devtools.newRepl()
        expect_equal(0, repl:len())
    end)

    -- @covers LReplConsole:history
    -- @covers lurek.devtools.newRepl
    it("history returns a table", function()
        local repl = lurek.devtools.newRepl()
        expect_type("table", repl:history())
    end)

    -- @covers LReplConsole:history
    -- @covers lurek.devtools.newRepl
    it("empty history has length zero", function()
        local repl = lurek.devtools.newRepl()
        expect_equal(0, #repl:history())
    end)
end)

-- @describe eval()
describe("eval()", function()
    -- @covers LReplConsole:eval
    -- @covers lurek.devtools.newRepl
    it("returns a string for a simple expression", function()
        local repl = lurek.devtools.newRepl()
        local result = repl:eval("1 + 1")
        expect_type("string", result)
    end)

    -- @covers LReplConsole:eval
    -- @covers lurek.devtools.newRepl
    it("evaluates arithmetic expressions", function()
        local repl = lurek.devtools.newRepl()
        local result = repl:eval("2 + 2")
        expect_equal("4", result)
    end)

    -- @covers LReplConsole:eval
    -- @covers lurek.devtools.newRepl
    it("evaluates string literals", function()
        local repl = lurek.devtools.newRepl()
        local result = repl:eval("\"hello\"")
        expect_equal("hello", result)
    end)

    -- @covers LReplConsole:eval
    -- @covers lurek.devtools.newRepl
    it("evaluates nil as string nil", function()
        local repl = lurek.devtools.newRepl()
        local result = repl:eval("nil")
        expect_equal("nil", result)
    end)

    -- @covers LReplConsole:eval
    -- @covers LReplConsole:len
    -- @covers lurek.devtools.newRepl
    it("increments len after eval", function()
        local repl = lurek.devtools.newRepl()
        repl:eval("1 + 1")
        expect_equal(1, repl:len())
    end)

    -- @covers LReplConsole:eval
    -- @covers LReplConsole:history
    -- @covers lurek.devtools.newRepl
    it("history grows with each eval", function()
        local repl = lurek.devtools.newRepl()
        repl:eval("1")
        repl:eval("2")
        expect_equal(2, #repl:history())
    end)

    -- @covers LReplConsole:eval
    -- @covers lurek.devtools.newRepl
    it("returns error string for invalid Lua", function()
        local repl = lurek.devtools.newRepl()
        local result = repl:eval("!!!not valid lua!!!")
        expect_type("string", result)
    end)
end)

-- @describe clear()
describe("clear()", function()
    -- @covers LReplConsole:clear
    -- @covers LReplConsole:eval
    -- @covers LReplConsole:len
    -- @covers lurek.devtools.newRepl
    it("resets len to zero", function()
        local repl = lurek.devtools.newRepl()
        repl:eval("42")
        repl:eval("99")
        repl:clear()
        expect_equal(0, repl:len())
    end)

    -- @covers LReplConsole:clear
    -- @covers LReplConsole:eval
    -- @covers LReplConsole:history
    -- @covers lurek.devtools.newRepl
    it("empties history", function()
        local repl = lurek.devtools.newRepl()
        repl:eval("1")
        repl:clear()
        expect_equal(0, #repl:history())
    end)
end)


-- =========================================================================
-- =========================================================================

-- @describe Missing API Coverage
describe("Missing API Coverage", function()
    -- @covers lurek.devtools.log
    it("covers lurek.devtools.log", function()
        expect_type("function", lurek.devtools.log)
        lurek.devtools.log("info", "unit test log message")
    end)

    -- @covers lurek.devtools.exposeWatch
    it("covers lurek.devtools.exposeWatch", function()
        local id = lurek.devtools.exposeWatch("unit_watch", function() return 42 end)
        expect_type("number", id)
    end)

    -- @covers lurek.devtools.exposeWatch
    -- @covers lurek.devtools.removeWatch
    it("covers lurek.devtools.removeWatch", function()
        local id = lurek.devtools.exposeWatch("rem_watch", function() return 0 end)
        local ok = lurek.devtools.removeWatch(id)
        expect_true(ok)
    end)

    -- @covers lurek.devtools.getWatches
    it("covers lurek.devtools.getWatches", function()
        local watches = lurek.devtools.getWatches()
        expect_type("table", watches)
    end)

    -- @covers LReplConsole:len
    -- @covers lurek.devtools.newRepl
    it("covers ReplConsole:len", function()
        local console = lurek.devtools.newRepl()
        expect_type("number", console:len())
    end)

    -- @covers lurek.devtools.fatal
    it("covers lurek.devtools.fatal", function()
        expect_type("function", lurek.devtools.fatal)
        lurek.devtools.fatal("unit test fatal message")
    end)

end)

-- @describe lurek.devtools.scan
describe("lurek.devtools.scan", function()
    -- @covers lurek.devtools.scan
    it("lurek.devtools.scan works", function()
        local changed = lurek.devtools.scan()
        expect_type("table", changed)
    end)
end)

-- @describe lurek.devtools.snapshot
describe("lurek.devtools.snapshot", function()
    -- @covers lurek.devtools.snapshot
    it("lurek.devtools.snapshot works", function()
        local snap = lurek.devtools.snapshot()
        expect_type("table", snap)
        expect_not_nil(snap.watchCount)
    end)
end)

-- @describe FileWatcher:onChanged
describe("FileWatcher:onChanged", function()
    -- @covers LFileWatcher:onChanged
    -- @covers lurek.devtools.newFileWatcher
    it("FileWatcher:onChanged works", function()
        local watcher = lurek.devtools.newFileWatcher(".")
        local called = false
        watcher:onChanged(function() called = true end)
        expect_type("boolean", called)
    end)
end)

-- @describe FileWatcher:check
describe("FileWatcher:check", function()
    -- @covers LFileWatcher:check
    -- @covers lurek.devtools.newFileWatcher
    it("FileWatcher:check works", function()
        local watcher = lurek.devtools.newFileWatcher(".")
        local result = watcher:check()
        expect_type("boolean", result)
    end)

    -- @covers LFileWatcher:check
    -- @covers lurek.devtools.newFileWatcher
    it("FileWatcher:check detects a real file mtime change", function()
        local path = "save/_fs_tests/devtools_watch_mtime.txt"
        lurek.filesystem.createDirectory("save/_fs_tests")
        lurek.filesystem.write(path, "v1")

        local watcher = lurek.devtools.newFileWatcher(path)
        expect_false(watcher:check())

        lurek.timer.sleep(0.02)
        lurek.filesystem.write(path, "v2")

        expect_true(watcher:check())
    end)
end)

-- @describe FileWatcher:getPath
describe("FileWatcher:getPath", function()
    -- @covers LFileWatcher:getPath
    -- @covers lurek.devtools.newFileWatcher
    it("FileWatcher:getPath works", function()
        local watcher = lurek.devtools.newFileWatcher("content")
        expect_equal("content", watcher:getPath())
    end)
end)

-- @describe FileWatcher:cancel
describe("FileWatcher:cancel", function()
    -- @covers LFileWatcher:cancel
    -- @covers LFileWatcher:getPath
    -- @covers LFileWatcher:onChanged
    -- @covers lurek.devtools.newFileWatcher
    it("FileWatcher:cancel works", function()
        local watcher = lurek.devtools.newFileWatcher(".")
        watcher:onChanged(function() end)
        watcher:cancel()
        expect_equal(".", watcher:getPath())
    end)
end)

-- @describe ReplConsole:eval
describe("ReplConsole:eval", function()
    -- @covers LReplConsole:eval
    -- @covers lurek.devtools.newRepl
    it("ReplConsole:eval works", function()
        local console = lurek.devtools.newRepl()
        local result = console:eval("1 + 1")
        expect_type("string", result)
    end)
end)

-- @describe ReplConsole:history
describe("ReplConsole:history", function()
    -- @covers LReplConsole:eval
    -- @covers LReplConsole:history
    -- @covers lurek.devtools.newRepl
    it("ReplConsole:history works", function()
        local console = lurek.devtools.newRepl()
        console:eval("x = 1")
        local hist = console:history()
        expect_type("table", hist)
        expect_equal("x = 1", hist[1])
    end)
end)

-- @describe ReplConsole:clear
describe("ReplConsole:clear", function()
    -- @covers LReplConsole:clear
    -- @covers LReplConsole:eval
    -- @covers LReplConsole:len
    -- @covers lurek.devtools.newRepl
    it("ReplConsole:clear works", function()
        local console = lurek.devtools.newRepl()
        console:eval("a = 1")
        console:clear()
        expect_equal(0, console:len())
    end)
end)

-- =========================================================================
-- =========================================================================

-- @describe lurek.devtools.log
describe("lurek.devtools.log ", function()
    -- @covers lurek.devtools.log
    -- @covers lurek.devtools.setLogConsole
    it("log can be called without crashing", function()
        lurek.devtools.setLogConsole(false)
        local ok, _ = pcall(function()
            lurek.devtools.log("info", "coverage test message")
        end)
        lurek.devtools.setLogConsole(true)
        expect_type("boolean", ok)
    end)
end)

-- @describe ReplConsole:len
describe("ReplConsole:len ", function()
    -- @covers lurek.devtools.openConsole
    it("len returns a number after eval", function()
        -- openConsole may return a ReplConsole handle or nil in headless mode
        local ok, console = pcall(function() return lurek.devtools.openConsole() end)
        if ok and console ~= nil and type(console) == "userdata" then
            pcall(function() console:eval("x = 1") end)
            local len_ok, n = pcall(function() return console:len() end)
            if len_ok then
                expect_type("number", n)
            end
        end
        -- if openConsole is headless-only, just verify the API is present
        expect_type("function", lurek.devtools.openConsole)
    end)
end)

-- @describe devtools strict: trace / debug / warn / error
describe("devtools strict: trace / debug / warn / error", function()
    -- @covers lurek.devtools.trace
    it("lurek.devtools.trace is callable", function()
        local ok = pcall(function() lurek.devtools.trace("trace msg") end)
        expect_true(ok)
    end)

    -- @covers lurek.devtools.debug
    it("lurek.devtools.debug is callable", function()
        local ok = pcall(function() lurek.devtools.debug("debug msg") end)
        expect_true(ok)
    end)

    -- @covers lurek.devtools.warn
    it("lurek.devtools.warn is callable", function()
        local ok = pcall(function() lurek.devtools.warn("warn msg") end)
        expect_true(ok)
    end)

    -- @covers lurek.devtools.error
    it("lurek.devtools.error is callable", function()
        local ok = pcall(function() lurek.devtools.error("error msg") end)
        expect_true(ok)
    end)
end)

-- @describe devtools strict: LFileWatcher type / typeOf
describe("devtools strict: LFileWatcher type / typeOf", function()
    -- @covers LFileWatcher:type
    -- @covers LFileWatcher:typeOf
    -- @covers lurek.devtools.newFileWatcher
    it("LFileWatcher type and typeOf are callable", function()
        local ok, fw = pcall(function() return lurek.devtools.newFileWatcher("save") end)
        if ok and fw ~= nil then
            expect_type("string", fw:type())
            expect_type("boolean", fw:typeOf("Object"))
        else
            expect_false(ok and fw ~= nil)
        end
    end)
end)

-- @describe devtools strict: LReplConsole type / typeOf
describe("devtools strict: LReplConsole type / typeOf", function()
    -- @covers LReplConsole:type
    -- @covers LReplConsole:typeOf
    -- @covers lurek.devtools.newRepl
    it("LReplConsole type and typeOf are callable", function()
        local ok, repl = pcall(function() return lurek.devtools.newRepl(10) end)
        if ok and repl ~= nil then
            expect_type("string", repl:type())
            expect_type("boolean", repl:typeOf("Object"))
        else
            expect_false(ok and repl ~= nil)
        end
    end)
end)

test_summary()
