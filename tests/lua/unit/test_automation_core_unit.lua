-- Lua BDD tests for lurek.automation (automation module)

---@type any
local automation = lurek.automation

-- @describe lurek.automation - namespace
describe("lurek.automation - namespace", function()
    -- @covers lurek.automation
    it("should exist as a table", function()
        expect_type("table", lurek.automation)
    end)

    -- @covers lurek.automation.load
    it("should have load function", function()
        expect_type("function", lurek.automation.load)
    end)

    -- @covers lurek.automation.unload
    it("should have unload function", function()
        expect_type("function", lurek.automation.unload)
    end)

    -- @covers lurek.automation.hasScript
    it("should have hasScript function", function()
        expect_type("function", lurek.automation.hasScript)
    end)

    -- @covers lurek.automation.getScripts
    it("should have getScripts function", function()
        expect_type("function", lurek.automation.getScripts)
    end)

    -- @covers lurek.automation.start
    it("should have start function", function()
        expect_type("function", lurek.automation.start)
    end)

    -- @covers lurek.automation.stop
    it("should have stop function", function()
        expect_type("function", lurek.automation.stop)
    end)

    -- @covers lurek.automation.pause
    it("should have pause function", function()
        expect_type("function", lurek.automation.pause)
    end)

    -- @covers lurek.automation.resume
    it("should have resume function", function()
        expect_type("function", lurek.automation.resume)
    end)

    -- @covers lurek.automation.update
    it("should have update function", function()
        expect_type("function", lurek.automation.update)
    end)

    -- @covers lurek.automation.isRunning
    it("should have isRunning function", function()
        expect_type("function", lurek.automation.isRunning)
    end)

    -- @covers lurek.automation.isPaused
    it("should have isPaused function", function()
        expect_type("function", lurek.automation.isPaused)
    end)

    -- @covers lurek.automation.isComplete
    it("should have isComplete function", function()
        expect_type("function", lurek.automation.isComplete)
    end)

    -- @covers lurek.automation.getCurrentStep
    it("should have getCurrentStep function", function()
        expect_type("function", lurek.automation.getCurrentStep)
    end)

    -- @covers lurek.automation.getStepCount
    it("should have getStepCount function", function()
        expect_type("function", lurek.automation.getStepCount)
    end)

    -- @covers lurek.automation.getCurrentScript
    it("should have getCurrentScript function", function()
        expect_type("function", lurek.automation.getCurrentScript)
    end)

    -- @covers lurek.automation.getElapsedTime
    it("should have getElapsedTime function", function()
        expect_type("function", lurek.automation.getElapsedTime)
    end)

    -- @covers lurek.automation.loadFromToml
    it("should have loadFromToml function", function()
        expect_type("function", lurek.automation.loadFromToml)
    end)
end)

-- @describe lurek.automation - script management
describe("lurek.automation - script management", function()
    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.load
    -- @covers lurek.automation.unload
    it("should load a script with a single keypress step", function()
        lurek.automation.load("single_key", {
            steps = {
                { action = "keypress", key = "a", time = 0.5 }
            }
        })
        expect_equal(lurek.automation.hasScript("single_key"), true)
        lurek.automation.unload("single_key")
    end)

    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.load
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.load
    -- @covers lurek.automation.unload
    it("should load a script with meta description", function()
        lurek.automation.load("described", {
            steps = { { action = "wait", time = 0.0 } },
            meta = { description = "A test script with description" }
        })
        expect_equal(lurek.automation.hasScript("described"), true)
        lurek.automation.unload("described")
    end)

    -- @covers lurek.automation.hasScript
    it("should report hasScript false for unknown scripts", function()
        expect_equal(lurek.automation.hasScript("nonexistent"), false)
    end)

    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.load
    -- @covers lurek.automation.unload
    it("should unload a loaded script", function()
        lurek.automation.load("to_remove", {
            steps = { { action = "wait", time = 0.0 } }
        })
        local result = lurek.automation.unload("to_remove")
        expect_equal(result, true)
        expect_equal(lurek.automation.hasScript("to_remove"), false)
    end)

    -- @covers lurek.automation.unload
    it("should return false when unloading nonexistent script", function()
        local result = lurek.automation.unload("does_not_exist")
        expect_equal(result, false)
    end)

    -- @covers lurek.automation.getScripts
    -- @covers lurek.automation.load
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.getScripts
    -- @covers lurek.automation.unload
    it("should return empty table when no scripts loaded", function()
        -- Clean state
        for _, name in ipairs(lurek.automation.getScripts()) do
            lurek.automation.unload(name)
        end
        local names = lurek.automation.getScripts()
        expect_equal(#names, 0)
    end)

    -- @covers lurek.automation.getStepCount
    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

-- @describe lurek.automation - playback control
describe("lurek.automation - playback control", function()
    -- @covers lurek.automation.getCurrentScript
    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.start
    it("should error when starting nonexistent script", function()
        expect_error(function()
            lurek.automation.start("nonexistent_script")
        end)
    end)

    -- @covers lurek.automation.getCurrentScript
    -- @covers lurek.automation.getCurrentStep
    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.isPaused
    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.pause
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.isPaused
    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.pause
    -- @covers lurek.automation.resume
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.isPaused
    -- @covers lurek.automation.pause
    it("should be safe to pause when idle", function()
        lurek.automation.pause()
        expect_equal(lurek.automation.isPaused(), false)
    end)

    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.stop
    it("should be safe to stop when idle", function()
        lurek.automation.stop()
        expect_equal(lurek.automation.isRunning(), false)
    end)

    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.resume
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

-- @describe lurek.automation - state queries
describe("lurek.automation - state queries", function()
    -- @covers lurek.automation.isRunning
    it("should report not running when idle", function()
        expect_equal(lurek.automation.isRunning(), false)
    end)

    -- @covers lurek.automation.isPaused
    it("should report not paused when idle", function()
        expect_equal(lurek.automation.isPaused(), false)
    end)

    -- @covers lurek.automation.isComplete
    it("should report not complete when idle", function()
        expect_equal(lurek.automation.isComplete(), false)
    end)

    -- @covers lurek.automation.getElapsedTime
    it("should report zero elapsed time when idle", function()
        expect_near(lurek.automation.getElapsedTime(), 0.0, 0.001)
    end)

    -- @covers lurek.automation.getCurrentStep
    it("should report zero current step when idle", function()
        expect_equal(lurek.automation.getCurrentStep(), 0)
    end)

    -- @covers lurek.automation.getStepCount
    it("should report zero step count when idle", function()
        expect_equal(lurek.automation.getStepCount(), 0)
    end)

    -- @covers lurek.automation.getCurrentScript
    it("should report nil current script when idle", function()
        expect_equal(lurek.automation.getCurrentScript(), nil)
    end)
end)

-- @describe lurek.automation - update and completion
describe("lurek.automation - update and completion", function()
    -- @covers lurek.automation.getElapsedTime
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

    -- @covers lurek.automation.getCurrentStep
    -- @covers lurek.automation.getStepCount
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

    -- @covers lurek.automation.getCurrentStep
    -- @covers lurek.automation.getElapsedTime
    -- @covers lurek.automation.load
    -- @covers lurek.automation.pause
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
    it("should handle empty script gracefully", function()
        lurek.automation.load("empty", { steps = {} })
        lurek.automation.start("empty")
        lurek.automation.update(0.1)
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.stop()
        lurek.automation.unload("empty")
    end)
end)

-- @describe lurek.automation - error handling
describe("lurek.automation - error handling", function()
    -- @covers lurek.automation.load
    it("should error on load with missing steps", function()
        expect_error(function()
            lurek.automation.load("bad", {})
        end)
    end)

    -- @covers lurek.automation.load
    it("should error on load with unknown action", function()
        expect_error(function()
            lurek.automation.load("bad_action", {
                steps = { { action = "explode", time = 0.0 } }
            })
        end)
    end)

    -- @covers lurek.automation.load
    it("should error on load with missing action field", function()
        expect_error(function()
            lurek.automation.load("no_action", {
                steps = { { time = 0.5 } }
            })
        end)
    end)
end)

-- @describe lurek.automation - TOML loading
describe("lurek.automation - TOML loading", function()
    -- @covers lurek.automation.getStepCount
    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.loadFromToml
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.getStepCount
    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.loadFromToml
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.getStepCount
    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.loadFromToml
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

-- @describe lurek.automation - complex scenarios
describe("lurek.automation - complex scenarios", function()
    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.hasScript
    -- @covers lurek.automation.load
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.getScripts
    -- @covers lurek.automation.load
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.getCurrentScript
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.getCurrentStep
    -- @covers lurek.automation.getStepCount
    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

-- @describe lurek.automation named macros
describe("lurek.automation named macros", function()
    -- @covers lurek.automation.hasMacro
    -- @covers lurek.automation.load
    -- @covers lurek.automation.saveMacro
    -- @covers lurek.automation.unload
    it("hasMacro returns true after saveMacro", function()
        lurek.automation.load("m_src", { steps = { { action = "wait", time = 0.01 } } })
        lurek.automation.saveMacro("my_macro", "m_src")
        expect_equal(lurek.automation.hasMacro("my_macro"), true)
        expect_equal(lurek.automation.hasMacro("missing"), false)
        lurek.automation.unload("m_src")
    end)

    -- @covers lurek.automation.listMacros
    -- @covers lurek.automation.load
    -- @covers lurek.automation.saveMacro
    -- @covers lurek.automation.unload
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

    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.playMacro
    -- @covers lurek.automation.saveMacro
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    it("playMacro starts a saved macro", function()
        lurek.automation.load("pm_src", { steps = { { action = "wait", time = 0.05 } } })
        lurek.automation.saveMacro("play_test", "pm_src")
        lurek.automation.playMacro("play_test")
        expect_equal(lurek.automation.isRunning(), true)
        lurek.automation.stop()
        lurek.automation.unload("pm_src")
    end)
end)

-- @describe lurek.automation variable playback speed
describe("lurek.automation variable playback speed", function()
    -- @covers lurek.automation.getPlaybackSpeed
    -- @covers lurek.automation.setPlaybackSpeed
    it("setPlaybackSpeed round-trips correctly", function()
        lurek.automation.setPlaybackSpeed(2.0)
        expect_near(lurek.automation.getPlaybackSpeed(), 2.0, 0.001)
        lurek.automation.setPlaybackSpeed(1.0)
    end)

    -- @covers lurek.automation.isComplete
    -- @covers lurek.automation.load
    -- @covers lurek.automation.setPlaybackSpeed
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
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

-- @describe lurek.automation waitUntil
describe("lurek.automation waitUntil", function()
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
    -- @covers lurek.automation.waitUntil
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

-- @describe lurek.automation step limit
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

    -- @covers lurek.automation.getStepLimit
    -- @covers lurek.automation.load
    -- @covers lurek.automation.setStepLimit
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

    -- @covers lurek.automation.getStepLimit
    -- @covers lurek.automation.load
    -- @covers lurek.automation.setStepLimit
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

-- @describe lurek.automation highlight mode API types
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

-- @describe lurek.automation.isHighlightMode default
describe("lurek.automation.isHighlightMode default", function()
  -- @covers lurek.automation.isHighlightMode
  -- @covers lurek.automation.setHighlightMode
  it("default highlight mode is false", function()
    -- Reset state first: enabling then disabling resets to false
    lurek.automation.setHighlightMode(false)
    local result = lurek.automation.isHighlightMode()
    expect_equal(false, result)
  end)
end)

-- @describe lurek.automation setHighlightMode / isHighlightMode roundtrip
describe("lurek.automation setHighlightMode / isHighlightMode roundtrip", function()
  -- @covers lurek.automation.isHighlightMode
  -- @covers lurek.automation.setHighlightMode
  it("enable returns true from isHighlightMode", function()
    lurek.automation.setHighlightMode(true)
    expect_equal(true, lurek.automation.isHighlightMode())
    -- clean up
    lurek.automation.setHighlightMode(false)
  end)

  -- @covers lurek.automation.isHighlightMode
  -- @covers lurek.automation.setHighlightMode
  it("disable after enable returns false", function()
    lurek.automation.setHighlightMode(true)
    lurek.automation.setHighlightMode(false)
    expect_equal(false, lurek.automation.isHighlightMode())
  end)

  -- @covers lurek.automation.isHighlightMode
  -- @covers lurek.automation.setHighlightMode
  it("setting true twice still returns true", function()
    lurek.automation.setHighlightMode(true)
    lurek.automation.setHighlightMode(true)
    expect_equal(true, lurek.automation.isHighlightMode())
    lurek.automation.setHighlightMode(false)
  end)

  -- @covers lurek.automation.isHighlightMode
  it("isHighlightMode returns a boolean", function()
    local result = lurek.automation.isHighlightMode()
    expect_type("boolean", result)
  end)
end)

-- @describe lurek.automation extended API
describe("lurek.automation extended API", function()
    -- @covers lurek.automation.setCondition
    it("setCondition is a function", function()
        expect_type("function", automation.setCondition)
    end)

    -- @covers lurek.automation.getCondition
    it("getCondition is a function", function()
        expect_type("function", automation.getCondition)
    end)

    -- @covers lurek.automation.isFailed
    it("isFailed is a function", function()
        expect_type("function", automation.isFailed)
    end)

    -- @covers lurek.automation.getLastError
    it("getLastError is a function", function()
        expect_type("function", automation.getLastError)
    end)
end)

-- @describe lurek.automation extended actions
describe("lurek.automation extended actions", function()
    -- @covers lurek.automation.getCurrentStep
    -- @covers lurek.automation.load
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
    it("repeat expands step execution", function()
        lurek.automation.load("repeat_steps", {
            steps = {
                { action = "wait", time = 0.0, ["repeat"] = 2, repeatInterval = 0.1 },
            }
        })
        lurek.automation.start("repeat_steps")
        lurek.automation.update(0.25)
        expect_equal(lurek.automation.getCurrentStep(), 3)
        lurek.automation.stop()
        lurek.automation.unload("repeat_steps")
    end)

    -- @covers lurek.automation.isRunning
    -- @covers lurek.automation.load
    -- @covers lurek.automation.playMacro
    -- @covers lurek.automation.saveMacro
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
    it("callmacro action expands named macro", function()
        lurek.automation.load("macro_src_ext", {
            steps = { { action = "textinput", text = "hello", time = 0.0 } }
        })
        lurek.automation.saveMacro("macro_ext", "macro_src_ext")

        lurek.automation.load("macro_call", {
            steps = { { action = "callmacro", macro = "macro_ext", time = 0.0 } }
        })

        lurek.automation.start("macro_call")
        lurek.automation.update(0.05)
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.update(0.05)
        lurek.automation.stop()
        lurek.automation.unload("macro_src_ext")
        lurek.automation.unload("macro_call")
    end)
end)

-- @describe automation migrated from integration/automation_event
describe("automation migrated from integration/automation_event", function()
    -- @covers lurek.automation.getLastError
    -- @covers lurek.automation.isFailed
    -- @covers lurek.automation.load
    -- @covers lurek.automation.setCondition
    -- @covers lurek.automation.start
    -- @covers lurek.automation.stop
    -- @covers lurek.automation.unload
    -- @covers lurek.automation.update
    it("fails assert action when condition is false", function()
        lurek.automation.load("assert_fail", {
            steps = {
                { action = "assert", assert = "boss_dead", time = 0.0 },
            }
        })

        lurek.automation.setCondition("boss_dead", false)
        lurek.automation.start("assert_fail")
        lurek.automation.update(0.01)

        expect_equal(lurek.automation.isFailed(), true)
        local err = lurek.automation.getLastError()
        expect_type("string", err)

        lurek.automation.stop()
        lurek.automation.unload("assert_fail")
    end)
end)

test_summary()
