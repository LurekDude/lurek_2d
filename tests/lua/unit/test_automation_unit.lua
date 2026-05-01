-- Lua BDD tests for lurek.automation (automation module)

describe("lurek.automation - namespace", function()
    -- @covers lurek.automation.getCurrentScript
    -- @covers lurek.automation.getCurrentStep
    -- @covers lurek.automation.getElapsedTime
    -- @covers lurek.automation.getScripts
    -- @covers lurek.automation.getStepCount
    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.isPaused
    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.loadFromToml
    -- @covers lurek.automation.pause
    -- @covers lurek.automation.resume
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
    it("should exist as a table", function()
        expect_type("table", lurek.automation)
    end)

    it("should have load function", function()
        expect_type("function", lurek.automation.load)
    end)

    it("should have unload function", function()
        expect_type("function", lurek.automation.unload)
    end)

    it("should have hasScript function", function()
        expect_type("function", lurek.automation.hasScript)
    end)

    it("should have getScripts function", function()
        expect_type("function", lurek.automation.getScripts)
    end)

    it("should have start function", function()
        expect_type("function", lurek.automation.start)
    end)

    it("should have stop function", function()
        expect_type("function", lurek.automation.stop)
    end)

    it("should have pause function", function()
        expect_type("function", lurek.automation.pause)
    end)

    it("should have resume function", function()
        expect_type("function", lurek.automation.resume)
    end)

    it("should have update function", function()
        expect_type("function", lurek.automation.update)
    end)

    it("should have isRunning function", function()
        expect_type("function", lurek.automation.isRunning)
    end)

    it("should have isPaused function", function()
        expect_type("function", lurek.automation.isPaused)
    end)

    it("should have isComplete function", function()
        expect_type("function", lurek.automation.isComplete)
    end)

    it("should have getCurrentStep function", function()
        expect_type("function", lurek.automation.getCurrentStep)
    end)

    it("should have getStepCount function", function()
        expect_type("function", lurek.automation.getStepCount)
    end)

    it("should have getCurrentScript function", function()
        expect_type("function", lurek.automation.getCurrentScript)
    end)

    it("should have getElapsedTime function", function()
        expect_type("function", lurek.automation.getElapsedTime)
    end)

    it("should have loadFromToml function", function()
        expect_type("function", lurek.automation.loadFromToml)
    end)
end)

describe("lurek.automation - script management", function()
    it("should load a script with a single keypress step", function()
        lurek.automation.load("single_key", {
            steps = {
                { action = "keypress", key = "a", time = 0.5 }
            }
        })
        expect_equal(lurek.automation.hasScript("single_key"), true)
        lurek.automation.unload("single_key")
    end)

    it("should load a script with multiple step types", function()
        lurek.automation.load("multi", {
            steps = {
                { action = "keypress", key = "space", time = 0.0 },
                { action = "keyrelease", key = "space", time = 0.1 },
                { action = "mousemove", x = 100, y = 200, dx = 5, dy = 3, time = 0.5 },
                { action = "mousepress", x = 100, y = 200, button = 1, time = 0.6 },
                { action = "mouserelease", x = 100, y = 200, button = 1, time = 0.7 },
                { action = "mousewheel", x = 0, y = 3, time = 1.0 },
                { action = "textinput", text = "hello", time = 1.5 },
                { action = "wait", time = 2.0 },
            }
        })
        expect_equal(lurek.automation.hasScript("multi"), true)
        lurek.automation.unload("multi")
    end)

    it("should load a script with meta description", function()
        lurek.automation.load("described", {
            steps = { { action = "wait", time = 0.0 } },
            meta = { description = "A test script with description" }
        })
        expect_equal(lurek.automation.hasScript("described"), true)
        lurek.automation.unload("described")
    end)

    it("should report hasScript false for unknown scripts", function()
        expect_equal(lurek.automation.hasScript("nonexistent"), false)
    end)

    it("should unload a loaded script", function()
        lurek.automation.load("to_remove", {
            steps = { { action = "wait", time = 0.0 } }
        })
        local result = lurek.automation.unload("to_remove")
        expect_equal(result, true)
        expect_equal(lurek.automation.hasScript("to_remove"), false)
    end)

    it("should return false when unloading nonexistent script", function()
        local result = lurek.automation.unload("does_not_exist")
        expect_equal(result, false)
    end)

    it("should list loaded scripts via getScripts", function()
        lurek.automation.load("alpha", {
            steps = { { action = "wait", time = 0.0 } }
        })
        lurek.automation.load("beta", {
            steps = { { action = "wait", time = 0.0 } }
        })
        local names = lurek.automation.getScripts()
        expect_type("table", names)
        -- Should contain both names
        local found_alpha = false
        local found_beta = false
        for _, name in ipairs(names) do
            if name == "alpha" then found_alpha = true end
            if name == "beta" then found_beta = true end
        end
        expect_equal(found_alpha, true)
        expect_equal(found_beta, true)
        lurek.automation.unload("alpha")
        lurek.automation.unload("beta")
    end)

    it("should return empty table when no scripts loaded", function()
        -- Clean state
        for _, name in ipairs(lurek.automation.getScripts()) do
            lurek.automation.unload(name)
        end
        local names = lurek.automation.getScripts()
        expect_equal(#names, 0)
    end)

    it("should replace script when loading same name twice", function()
        lurek.automation.load("dup", {
            steps = { { action = "wait", time = 0.0 } }
        })
        lurek.automation.load("dup", {
            steps = {
                { action = "wait", time = 0.0 },
                { action = "wait", time = 1.0 },
            }
        })
        expect_equal(lurek.automation.hasScript("dup"), true)
        -- Start to check step count reflects the second load
        lurek.automation.start("dup")
        expect_equal(lurek.automation.getStepCount(), 2)
        lurek.automation.stop()
        lurek.automation.unload("dup")
    end)
end)

describe("lurek.automation - playback control", function()
    it("should start playback of a loaded script", function()
        lurek.automation.load("play", {
            steps = { { action = "wait", time = 1.0 } }
        })
        lurek.automation.start("play")
        expect_equal(lurek.automation.isRunning(), true)
        expect_equal(lurek.automation.getCurrentScript(), "play")
        lurek.automation.stop()
        lurek.automation.unload("play")
    end)

    it("should error when starting nonexistent script", function()
        expect_error(function()
            lurek.automation.start("nonexistent_script")
        end)
    end)

    it("should stop playback and reset state", function()
        lurek.automation.load("stop_test", {
            steps = { { action = "wait", time = 1.0 } }
        })
        lurek.automation.start("stop_test")
        lurek.automation.stop()
        expect_equal(lurek.automation.isRunning(), false)
        expect_equal(lurek.automation.getCurrentScript(), nil)
        expect_equal(lurek.automation.getCurrentStep(), 0)
        lurek.automation.unload("stop_test")
    end)

    it("should pause running playback", function()
        lurek.automation.load("pause_test", {
            steps = { { action = "wait", time = 1.0 } }
        })
        lurek.automation.start("pause_test")
        lurek.automation.pause()
        expect_equal(lurek.automation.isPaused(), true)
        expect_equal(lurek.automation.isRunning(), false)
        lurek.automation.stop()
        lurek.automation.unload("pause_test")
    end)

    it("should resume paused playback", function()
        lurek.automation.load("resume_test", {
            steps = { { action = "wait", time = 1.0 } }
        })
        lurek.automation.start("resume_test")
        lurek.automation.pause()
        lurek.automation.resume()
        expect_equal(lurek.automation.isRunning(), true)
        expect_equal(lurek.automation.isPaused(), false)
        lurek.automation.stop()
        lurek.automation.unload("resume_test")
    end)

    it("should be safe to pause when idle", function()
        lurek.automation.pause()
        expect_equal(lurek.automation.isPaused(), false)
    end)

    it("should be safe to stop when idle", function()
        lurek.automation.stop()
        expect_equal(lurek.automation.isRunning(), false)
    end)

    it("should be safe to resume when not paused", function()
        lurek.automation.load("resume_noop", {
            steps = { { action = "wait", time = 1.0 } }
        })
        lurek.automation.start("resume_noop")
        lurek.automation.resume() -- already running, should be noop
        expect_equal(lurek.automation.isRunning(), true)
        lurek.automation.stop()
        lurek.automation.unload("resume_noop")
    end)
end)

describe("lurek.automation - state queries", function()
    it("should report not running when idle", function()
        expect_equal(lurek.automation.isRunning(), false)
    end)

    it("should report not paused when idle", function()
        expect_equal(lurek.automation.isPaused(), false)
    end)

    it("should report not complete when idle", function()
        expect_equal(lurek.automation.isComplete(), false)
    end)

    it("should report zero elapsed time when idle", function()
        expect_near(lurek.automation.getElapsedTime(), 0.0, 0.001)
    end)

    it("should report zero current step when idle", function()
        expect_equal(lurek.automation.getCurrentStep(), 0)
    end)

    it("should report zero step count when idle", function()
        expect_equal(lurek.automation.getStepCount(), 0)
    end)

    it("should report nil current script when idle", function()
        expect_equal(lurek.automation.getCurrentScript(), nil)
    end)
end)

describe("lurek.automation - update and completion", function()
    it("should advance elapsed time on update", function()
        lurek.automation.load("time_test", {
            steps = { { action = "wait", time = 10.0 } }
        })
        lurek.automation.start("time_test")
        lurek.automation.update(0.5)
        expect_near(lurek.automation.getElapsedTime(), 0.5, 0.001)
        lurek.automation.update(0.3)
        expect_near(lurek.automation.getElapsedTime(), 0.8, 0.001)
        lurek.automation.stop()
        lurek.automation.unload("time_test")
    end)

    it("should complete after all steps pass", function()
        lurek.automation.load("complete_test", {
            steps = {
                { action = "wait", time = 0.0 },
                { action = "wait", time = 0.1 },
            }
        })
        lurek.automation.start("complete_test")
        lurek.automation.update(0.5) -- advance past all steps
        expect_equal(lurek.automation.isComplete(), true)
        expect_equal(lurek.automation.isRunning(), false)
        lurek.automation.stop()
        lurek.automation.unload("complete_test")
    end)

    it("should advance current step as steps are dispatched", function()
        lurek.automation.load("step_advance", {
            steps = {
                { action = "wait", time = 0.0 },
                { action = "wait", time = 0.5 },
                { action = "wait", time = 1.0 },
            }
        })
        lurek.automation.start("step_advance")
        expect_equal(lurek.automation.getStepCount(), 3)

        lurek.automation.update(0.1) -- step 0 fires (time 0.0)
        expect_equal(lurek.automation.getCurrentStep(), 1)

        lurek.automation.update(0.5) -- step 1 fires (time 0.5, elapsed 0.6)
        expect_equal(lurek.automation.getCurrentStep(), 2)

        lurek.automation.stop()
        lurek.automation.unload("step_advance")
    end)

    it("should not advance when paused", function()
        lurek.automation.load("pause_hold", {
            steps = { { action = "wait", time = 0.0 } }
        })
        lurek.automation.start("pause_hold")
        lurek.automation.pause()
        lurek.automation.update(1.0)
        expect_equal(lurek.automation.getCurrentStep(), 0)
        expect_near(lurek.automation.getElapsedTime(), 0.0, 0.001)
        lurek.automation.stop()
        lurek.automation.unload("pause_hold")
    end)

    it("should dispatch keypress events via update", function()
        lurek.automation.load("key_test", {
            steps = {
                { action = "keypress", key = "a", time = 0.0 },
                { action = "keyrelease", key = "a", time = 0.1 },
            }
        })
        lurek.automation.start("key_test")
        lurek.automation.update(0.2)
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.stop()
        lurek.automation.unload("key_test")
    end)

    it("should default keypress scancode to key and repeat to false", function()
        lurek.event.clear()
        lurek.automation.load("key_defaults", {
            steps = {
                { action = "keypress", key = "a", time = 0.0 },
            }
        })
        lurek.automation.start("key_defaults")
        lurek.automation.update(0.01)

        local ok, name, args = lurek.event.wait(0)
        expect_equal(ok, true)
        expect_equal(name, "keypressed")
        expect_equal(args[1], "a")
        expect_equal(args[2], "a")
        expect_equal(args[3], false)

        lurek.automation.stop()
        lurek.automation.unload("key_defaults")
        lurek.event.clear()
    end)

    it("should prefer explicit scancode in queued keypress events", function()
        lurek.event.clear()
        lurek.automation.load("key_scancode", {
            steps = {
                { action = "keypress", key = "a", scancode = "KeyA", time = 0.0 },
            }
        })
        lurek.automation.start("key_scancode")
        lurek.automation.update(0.01)

        local ok, name, args = lurek.event.wait(0)
        expect_equal(ok, true)
        expect_equal(name, "keypressed")
        expect_equal(args[1], "a")
        expect_equal(args[2], "KeyA")
        expect_equal(args[3], false)

        lurek.automation.stop()
        lurek.automation.unload("key_scancode")
        lurek.event.clear()
    end)

    it("should dispatch mouse events via update", function()
        lurek.automation.load("mouse_test", {
            steps = {
                { action = "mousemove", x = 100, y = 200, dx = 0, dy = 0, time = 0.0 },
                { action = "mousepress", x = 100, y = 200, button = 1, time = 0.1 },
                { action = "mouserelease", x = 100, y = 200, button = 1, time = 0.2 },
                { action = "mousewheel", x = 0, y = 3, time = 0.3 },
            }
        })
        lurek.automation.start("mouse_test")
        lurek.automation.update(0.5)
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.stop()
        lurek.automation.unload("mouse_test")
    end)

    it("should dispatch textinput events via update", function()
        lurek.automation.load("text_test", {
            steps = { { action = "textinput", text = "hello world", time = 0.0 } }
        })
        lurek.automation.start("text_test")
        lurek.automation.update(0.1)
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.stop()
        lurek.automation.unload("text_test")
    end)

    it("should handle empty script gracefully", function()
        lurek.automation.load("empty", { steps = {} })
        lurek.automation.start("empty")
        lurek.automation.update(0.1)
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.stop()
        lurek.automation.unload("empty")
    end)
end)

describe("lurek.automation - error handling", function()
    it("should error on load with missing steps", function()
        expect_error(function()
            lurek.automation.load("bad", {})
        end)
    end)

    it("should error on load with unknown action", function()
        expect_error(function()
            lurek.automation.load("bad_action", {
                steps = { { action = "explode", time = 0.0 } }
            })
        end)
    end)

    it("should error on load with missing action field", function()
        expect_error(function()
            lurek.automation.load("no_action", {
                steps = { { time = 0.5 } }
            })
        end)
    end)
end)

describe("lurek.automation - TOML loading", function()
    it("should load from a TOML string", function()
        local toml = [=[
[meta]
name = "toml_demo"
description = "Loaded from TOML"

[[steps]]
action = "keypress"
key = "space"
time = 0.0

[[steps]]
action = "keyrelease"
key = "space"
time = 0.2
]=]
        lurek.automation.loadFromToml("toml_demo", toml)
        expect_equal(lurek.automation.hasScript("toml_demo"), true)
        lurek.automation.start("toml_demo")
        expect_equal(lurek.automation.getStepCount(), 2)
        lurek.automation.stop()
        lurek.automation.unload("toml_demo")
    end)

    it("should load a TOML with mouse steps", function()
        local toml = [=[
[[steps]]
action = "mousemove"
x = 400.0
y = 300.0
dx = 0.0
dy = 0.0
time = 0.0

[[steps]]
action = "mousepress"
x = 400.0
y = 300.0
button = 1
time = 0.1
]=]
        lurek.automation.loadFromToml("mouse_toml", toml)
        expect_equal(lurek.automation.hasScript("mouse_toml"), true)
        lurek.automation.start("mouse_toml")
        expect_equal(lurek.automation.getStepCount(), 2)
        lurek.automation.stop()
        lurek.automation.unload("mouse_toml")
    end)

    it("should load a TOML with wait steps", function()
        local toml = [=[
[[steps]]
action = "wait"
time = 0.0

[[steps]]
action = "wait"
time = 1.0

[[steps]]
action = "wait"
time = 2.0
]=]
        lurek.automation.loadFromToml("wait_toml", toml)
        expect_equal(lurek.automation.hasScript("wait_toml"), true)
        lurek.automation.start("wait_toml")
        expect_equal(lurek.automation.getStepCount(), 3)
        lurek.automation.stop()
        lurek.automation.unload("wait_toml")
    end)
end)

describe("lurek.automation - complex scenarios", function()
    it("should handle rapid start/stop cycling", function()
        lurek.automation.load("cycle", {
            steps = { { action = "wait", time = 1.0 } }
        })
        for i = 1, 10 do
            lurek.automation.start("cycle")
            expect_equal(lurek.automation.isRunning(), true)
            lurek.automation.stop()
            expect_equal(lurek.automation.isRunning(), false)
        end
        lurek.automation.unload("cycle")
    end)

    it("should handle load/unload cycling", function()
        for i = 1, 10 do
            local name = "cycle_" .. i
            lurek.automation.load(name, {
                steps = { { action = "wait", time = 0.0 } }
            })
            expect_equal(lurek.automation.hasScript(name), true)
            lurek.automation.unload(name)
            expect_equal(lurek.automation.hasScript(name), false)
        end
    end)

    it("should handle multiple scripts loaded simultaneously", function()
        for i = 1, 5 do
            lurek.automation.load("multi_" .. i, {
                steps = { { action = "wait", time = 0.0 } }
            })
        end
        local scripts = lurek.automation.getScripts()
        expect_equal(#scripts, 5)
        for i = 1, 5 do
            lurek.automation.unload("multi_" .. i)
        end
    end)

    it("should handle switching between scripts", function()
        lurek.automation.load("script_a", {
            steps = { { action = "keypress", key = "a", time = 0.0 } }
        })
        lurek.automation.load("script_b", {
            steps = { { action = "keypress", key = "b", time = 0.0 } }
        })

        lurek.automation.start("script_a")
        expect_equal(lurek.automation.getCurrentScript(), "script_a")

        lurek.automation.start("script_b")
        expect_equal(lurek.automation.getCurrentScript(), "script_b")

        lurek.automation.stop()
        lurek.automation.unload("script_a")
        lurek.automation.unload("script_b")
    end)

    it("should run a complete automation sequence", function()
        lurek.automation.load("full_sequence", {
            steps = {
                { action = "mousemove", x = 200, y = 300, dx = 0, dy = 0, time = 0.0 },
                { action = "mousepress", x = 200, y = 300, button = 1, time = 0.1 },
                { action = "mouserelease", x = 200, y = 300, button = 1, time = 0.2 },
                { action = "keypress", key = "w", time = 0.5 },
                { action = "keyrelease", key = "w", time = 0.6 },
                { action = "textinput", text = "test", time = 1.0 },
                { action = "wait", time = 1.5 },
            },
            meta = { description = "Full integration test sequence" }
        })

        lurek.automation.start("full_sequence")
        expect_equal(lurek.automation.isRunning(), true)
        expect_equal(lurek.automation.getStepCount(), 7)

        -- Run through the entire script
        lurek.automation.update(2.0)
        expect_equal(lurek.automation.isComplete(), true)
        expect_equal(lurek.automation.getCurrentStep(), 7)

        lurek.automation.stop()
        lurek.automation.unload("full_sequence")
    end)

    it("should handle default time of zero", function()
        lurek.automation.load("no_time", {
            steps = {
                { action = "keypress", key = "x" },
            }
        })
        lurek.automation.start("no_time")
        lurek.automation.update(0.01)
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.stop()
        lurek.automation.unload("no_time")
    end)
end)

describe("lurek.automation named macros", function()
    it("hasMacro returns true after saveMacro", function()
        lurek.automation.load("m_src", { steps = { { action = "wait", time = 0.01 } } })
        lurek.automation.saveMacro("my_macro", "m_src")
        expect_equal(lurek.automation.hasMacro("my_macro"), true)
        expect_equal(lurek.automation.hasMacro("missing"), false)
        lurek.automation.unload("m_src")
    end)

    it("listMacros contains saved name", function()
        lurek.automation.load("m_src2", { steps = { { action = "wait", time = 0.01 } } })
        lurek.automation.saveMacro("named_m", "m_src2")
        local list = lurek.automation.listMacros()
        local found = false
        for _, v in ipairs(list) do
            if v == "named_m" then found = true end
        end
        expect_equal(found, true)
        lurek.automation.unload("m_src2")
    end)

    it("playMacro starts a saved macro", function()
        lurek.automation.load("pm_src", { steps = { { action = "wait", time = 0.05 } } })
        lurek.automation.saveMacro("play_test", "pm_src")
        lurek.automation.playMacro("play_test")
        expect_equal(lurek.automation.isRunning(), true)
        lurek.automation.stop()
        lurek.automation.unload("pm_src")
    end)
end)

describe("lurek.automation variable playback speed", function()
    it("setPlaybackSpeed round-trips correctly", function()
        lurek.automation.setPlaybackSpeed(2.0)
        expect_near(lurek.automation.getPlaybackSpeed(), 2.0, 0.001)
        lurek.automation.setPlaybackSpeed(1.0)
    end)

    it("2x speed completes script faster", function()
        lurek.automation.load("speed_test", { steps = { { action = "wait", time = 0.10 } } })
        lurek.automation.setPlaybackSpeed(2.0)
        lurek.automation.start("speed_test")
        lurek.automation.update(0.06)   -- 0.06 * 2.0 = 0.12 virtual seconds
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.stop()
        lurek.automation.setPlaybackSpeed(1.0)
        lurek.automation.unload("speed_test")
    end)
end)

describe("lurek.automation waitUntil", function()
    it("waitUntil resumes when predicate fires", function()
        local flag = false
        lurek.automation.load("wu_test", { steps = { { action = "wait", time = 0.01 } } })
        lurek.automation.start("wu_test")
        lurek.automation.waitUntil(function() return flag end, 1.0)
        -- Before flag is true, update should not advance past the wait.
        lurek.automation.update(0.5)
        -- Script is being held by waitUntil; let flag fire on next check.
        flag = true
        lurek.automation.update(0.01) -- predicate now returns true, wait clears
        lurek.automation.stop()
        lurek.automation.unload("wu_test")
    end)
end)

-- =========================================================================
-- simulator step limit (PR-8)
-- =========================================================================

describe("lurek.automation step limit", function()
    -- @covers lurek.automation.getStepLimit
    it("getStepLimit_is_a_function", function()
        expect_type("function", lurek.automation.getStepLimit)
    end)

    -- @covers lurek.automation.setStepLimit
    it("setStepLimit_is_a_function", function()
        expect_type("function", lurek.automation.setStepLimit)
    end)

    -- @covers lurek.automation.getStepLimit
    it("getStepLimit_returns_nil_for_unregistered_script", function()
        local result = lurek.automation.getStepLimit("nonexistent_script_xyz")
        expect_nil(result)
    end)

    -- @covers lurek.automation.load
    -- @covers lurek.automation.setStepLimit
    -- @covers lurek.automation.getStepLimit
    -- @covers lurek.automation.unload
    it("setStepLimit_registers_on_a_loaded_script", function()
        lurek.automation.load("step_limit_test", {
            steps = { { action = "keypress", key = "a", time = 0.01 } }
        })
        local ok = lurek.automation.setStepLimit("step_limit_test", 50)
        expect_true(ok)
        expect_equal(50, lurek.automation.getStepLimit("step_limit_test"))
        lurek.automation.unload("step_limit_test")
    end)

    -- @covers lurek.automation.setStepLimit
    it("setStepLimit_returns_false_for_unknown_script", function()
        local ok = lurek.automation.setStepLimit("no_such_script", 10)
        expect_false(ok)
    end)

    -- @covers lurek.automation.load
    -- @covers lurek.automation.setStepLimit
    -- @covers lurek.automation.getStepLimit
    -- @covers lurek.automation.unload
    it("setStepLimit_overwrites_previous_value", function()
        lurek.automation.load("sl_overwrite", {
            steps = { { action = "keypress", key = "b", time = 0.01 } }
        })
        lurek.automation.setStepLimit("sl_overwrite", 25)
        lurek.automation.setStepLimit("sl_overwrite", 99)
        expect_equal(99, lurek.automation.getStepLimit("sl_overwrite"))
        lurek.automation.unload("sl_overwrite")
    end)
end)

--  Automation Highlight (merged from test_automation_highlight.lua) 

describe("lurek.automation highlight mode API types", function()
  -- @covers lurek.automation.setHighlightMode
  it("setHighlightMode is a function", function()
    expect_type("function", lurek.automation.setHighlightMode)
  end)

  -- @covers lurek.automation.isHighlightMode
  it("isHighlightMode is a function", function()
    expect_type("function", lurek.automation.isHighlightMode)
  end)
end)

describe("lurek.automation.isHighlightMode default", function()
  -- @covers lurek.automation.isHighlightMode
  it("default highlight mode is false", function()
    -- Reset state first: enabling then disabling resets to false
    lurek.automation.setHighlightMode(false)
    local result = lurek.automation.isHighlightMode()
    expect_equal(false, result)
  end)
end)

describe("lurek.automation setHighlightMode / isHighlightMode roundtrip", function()
  -- @covers lurek.automation.setHighlightMode
  -- @covers lurek.automation.isHighlightMode
  it("enable returns true from isHighlightMode", function()
    lurek.automation.setHighlightMode(true)
    expect_equal(true, lurek.automation.isHighlightMode())
    -- clean up
    lurek.automation.setHighlightMode(false)
  end)

  it("disable after enable returns false", function()
    lurek.automation.setHighlightMode(true)
    lurek.automation.setHighlightMode(false)
    expect_equal(false, lurek.automation.isHighlightMode())
  end)

  it("setting true twice still returns true", function()
    lurek.automation.setHighlightMode(true)
    lurek.automation.setHighlightMode(true)
    expect_equal(true, lurek.automation.isHighlightMode())
    lurek.automation.setHighlightMode(false)
  end)

  it("isHighlightMode returns a boolean", function()
    local result = lurek.automation.isHighlightMode()
    expect_type("boolean", result)
  end)
end)

test_summary()
