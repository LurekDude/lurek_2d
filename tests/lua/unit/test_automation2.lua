-- Lua BDD tests for luna.simulator (automation module)

describe("luna.simulator - namespace", function()
    it("should exist as a table", function()
        expect_type("table", luna.simulator)
    end)

    it("should have load function", function()
        expect_type("function", luna.simulator.load)
    end)

    it("should have unload function", function()
        expect_type("function", luna.simulator.unload)
    end)

    it("should have hasScript function", function()
        expect_type("function", luna.simulator.hasScript)
    end)

    it("should have getScripts function", function()
        expect_type("function", luna.simulator.getScripts)
    end)

    it("should have start function", function()
        expect_type("function", luna.simulator.start)
    end)

    it("should have stop function", function()
        expect_type("function", luna.simulator.stop)
    end)

    it("should have pause function", function()
        expect_type("function", luna.simulator.pause)
    end)

    it("should have resume function", function()
        expect_type("function", luna.simulator.resume)
    end)

    it("should have update function", function()
        expect_type("function", luna.simulator.update)
    end)

    it("should have isRunning function", function()
        expect_type("function", luna.simulator.isRunning)
    end)

    it("should have isPaused function", function()
        expect_type("function", luna.simulator.isPaused)
    end)

    it("should have isComplete function", function()
        expect_type("function", luna.simulator.isComplete)
    end)

    it("should have getCurrentStep function", function()
        expect_type("function", luna.simulator.getCurrentStep)
    end)

    it("should have getStepCount function", function()
        expect_type("function", luna.simulator.getStepCount)
    end)

    it("should have getCurrentScript function", function()
        expect_type("function", luna.simulator.getCurrentScript)
    end)

    it("should have getElapsedTime function", function()
        expect_type("function", luna.simulator.getElapsedTime)
    end)

    it("should have loadFromToml function", function()
        expect_type("function", luna.simulator.loadFromToml)
    end)
end)

describe("luna.simulator - script management", function()
    it("should load a script with a single keypress step", function()
        luna.simulator.load("single_key", {
            steps = {
                { action = "keypress", key = "a", time = 0.5 }
            }
        })
        expect_equal(luna.simulator.hasScript("single_key"), true)
        luna.simulator.unload("single_key")
    end)

    it("should load a script with multiple step types", function()
        luna.simulator.load("multi", {
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
        expect_equal(luna.simulator.hasScript("multi"), true)
        luna.simulator.unload("multi")
    end)

    it("should load a script with meta description", function()
        luna.simulator.load("described", {
            steps = { { action = "wait", time = 0.0 } },
            meta = { description = "A test script with description" }
        })
        expect_equal(luna.simulator.hasScript("described"), true)
        luna.simulator.unload("described")
    end)

    it("should report hasScript false for unknown scripts", function()
        expect_equal(luna.simulator.hasScript("nonexistent"), false)
    end)

    it("should unload a loaded script", function()
        luna.simulator.load("to_remove", {
            steps = { { action = "wait", time = 0.0 } }
        })
        local result = luna.simulator.unload("to_remove")
        expect_equal(result, true)
        expect_equal(luna.simulator.hasScript("to_remove"), false)
    end)

    it("should return false when unloading nonexistent script", function()
        local result = luna.simulator.unload("does_not_exist")
        expect_equal(result, false)
    end)

    it("should list loaded scripts via getScripts", function()
        luna.simulator.load("alpha", {
            steps = { { action = "wait", time = 0.0 } }
        })
        luna.simulator.load("beta", {
            steps = { { action = "wait", time = 0.0 } }
        })
        local names = luna.simulator.getScripts()
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
        luna.simulator.unload("alpha")
        luna.simulator.unload("beta")
    end)

    it("should return empty table when no scripts loaded", function()
        -- Clean state
        for _, name in ipairs(luna.simulator.getScripts()) do
            luna.simulator.unload(name)
        end
        local names = luna.simulator.getScripts()
        expect_equal(#names, 0)
    end)

    it("should replace script when loading same name twice", function()
        luna.simulator.load("dup", {
            steps = { { action = "wait", time = 0.0 } }
        })
        luna.simulator.load("dup", {
            steps = {
                { action = "wait", time = 0.0 },
                { action = "wait", time = 1.0 },
            }
        })
        expect_equal(luna.simulator.hasScript("dup"), true)
        -- Start to check step count reflects the second load
        luna.simulator.start("dup")
        expect_equal(luna.simulator.getStepCount(), 2)
        luna.simulator.stop()
        luna.simulator.unload("dup")
    end)
end)

describe("luna.simulator - playback control", function()
    it("should start playback of a loaded script", function()
        luna.simulator.load("play", {
            steps = { { action = "wait", time = 1.0 } }
        })
        luna.simulator.start("play")
        expect_equal(luna.simulator.isRunning(), true)
        expect_equal(luna.simulator.getCurrentScript(), "play")
        luna.simulator.stop()
        luna.simulator.unload("play")
    end)

    it("should error when starting nonexistent script", function()
        expect_error(function()
            luna.simulator.start("nonexistent_script")
        end)
    end)

    it("should stop playback and reset state", function()
        luna.simulator.load("stop_test", {
            steps = { { action = "wait", time = 1.0 } }
        })
        luna.simulator.start("stop_test")
        luna.simulator.stop()
        expect_equal(luna.simulator.isRunning(), false)
        expect_equal(luna.simulator.getCurrentScript(), nil)
        expect_equal(luna.simulator.getCurrentStep(), 0)
        luna.simulator.unload("stop_test")
    end)

    it("should pause running playback", function()
        luna.simulator.load("pause_test", {
            steps = { { action = "wait", time = 1.0 } }
        })
        luna.simulator.start("pause_test")
        luna.simulator.pause()
        expect_equal(luna.simulator.isPaused(), true)
        expect_equal(luna.simulator.isRunning(), false)
        luna.simulator.stop()
        luna.simulator.unload("pause_test")
    end)

    it("should resume paused playback", function()
        luna.simulator.load("resume_test", {
            steps = { { action = "wait", time = 1.0 } }
        })
        luna.simulator.start("resume_test")
        luna.simulator.pause()
        luna.simulator.resume()
        expect_equal(luna.simulator.isRunning(), true)
        expect_equal(luna.simulator.isPaused(), false)
        luna.simulator.stop()
        luna.simulator.unload("resume_test")
    end)

    it("should be safe to pause when idle", function()
        luna.simulator.pause()
        expect_equal(luna.simulator.isPaused(), false)
    end)

    it("should be safe to stop when idle", function()
        luna.simulator.stop()
        expect_equal(luna.simulator.isRunning(), false)
    end)

    it("should be safe to resume when not paused", function()
        luna.simulator.load("resume_noop", {
            steps = { { action = "wait", time = 1.0 } }
        })
        luna.simulator.start("resume_noop")
        luna.simulator.resume() -- already running, should be noop
        expect_equal(luna.simulator.isRunning(), true)
        luna.simulator.stop()
        luna.simulator.unload("resume_noop")
    end)
end)

describe("luna.simulator - state queries", function()
    it("should report not running when idle", function()
        expect_equal(luna.simulator.isRunning(), false)
    end)

    it("should report not paused when idle", function()
        expect_equal(luna.simulator.isPaused(), false)
    end)

    it("should report not complete when idle", function()
        expect_equal(luna.simulator.isComplete(), false)
    end)

    it("should report zero elapsed time when idle", function()
        expect_near(luna.simulator.getElapsedTime(), 0.0, 0.001)
    end)

    it("should report zero current step when idle", function()
        expect_equal(luna.simulator.getCurrentStep(), 0)
    end)

    it("should report zero step count when idle", function()
        expect_equal(luna.simulator.getStepCount(), 0)
    end)

    it("should report nil current script when idle", function()
        expect_equal(luna.simulator.getCurrentScript(), nil)
    end)
end)

describe("luna.simulator - update and completion", function()
    it("should advance elapsed time on update", function()
        luna.simulator.load("time_test", {
            steps = { { action = "wait", time = 10.0 } }
        })
        luna.simulator.start("time_test")
        luna.simulator.update(0.5)
        expect_near(luna.simulator.getElapsedTime(), 0.5, 0.001)
        luna.simulator.update(0.3)
        expect_near(luna.simulator.getElapsedTime(), 0.8, 0.001)
        luna.simulator.stop()
        luna.simulator.unload("time_test")
    end)

    it("should complete after all steps pass", function()
        luna.simulator.load("complete_test", {
            steps = {
                { action = "wait", time = 0.0 },
                { action = "wait", time = 0.1 },
            }
        })
        luna.simulator.start("complete_test")
        luna.simulator.update(0.5) -- advance past all steps
        expect_equal(luna.simulator.isComplete(), true)
        expect_equal(luna.simulator.isRunning(), false)
        luna.simulator.stop()
        luna.simulator.unload("complete_test")
    end)

    it("should advance current step as steps are dispatched", function()
        luna.simulator.load("step_advance", {
            steps = {
                { action = "wait", time = 0.0 },
                { action = "wait", time = 0.5 },
                { action = "wait", time = 1.0 },
            }
        })
        luna.simulator.start("step_advance")
        expect_equal(luna.simulator.getStepCount(), 3)

        luna.simulator.update(0.1) -- step 0 fires (time 0.0)
        expect_equal(luna.simulator.getCurrentStep(), 1)

        luna.simulator.update(0.5) -- step 1 fires (time 0.5, elapsed 0.6)
        expect_equal(luna.simulator.getCurrentStep(), 2)

        luna.simulator.stop()
        luna.simulator.unload("step_advance")
    end)

    it("should not advance when paused", function()
        luna.simulator.load("pause_hold", {
            steps = { { action = "wait", time = 0.0 } }
        })
        luna.simulator.start("pause_hold")
        luna.simulator.pause()
        luna.simulator.update(1.0)
        expect_equal(luna.simulator.getCurrentStep(), 0)
        expect_near(luna.simulator.getElapsedTime(), 0.0, 0.001)
        luna.simulator.stop()
        luna.simulator.unload("pause_hold")
    end)

    it("should dispatch keypress events via update", function()
        luna.simulator.load("key_test", {
            steps = {
                { action = "keypress", key = "a", time = 0.0 },
                { action = "keyrelease", key = "a", time = 0.1 },
            }
        })
        luna.simulator.start("key_test")
        luna.simulator.update(0.2)
        expect_equal(luna.simulator.isComplete(), true)
        luna.simulator.stop()
        luna.simulator.unload("key_test")
    end)

    it("should dispatch mouse events via update", function()
        luna.simulator.load("mouse_test", {
            steps = {
                { action = "mousemove", x = 100, y = 200, dx = 0, dy = 0, time = 0.0 },
                { action = "mousepress", x = 100, y = 200, button = 1, time = 0.1 },
                { action = "mouserelease", x = 100, y = 200, button = 1, time = 0.2 },
                { action = "mousewheel", x = 0, y = 3, time = 0.3 },
            }
        })
        luna.simulator.start("mouse_test")
        luna.simulator.update(0.5)
        expect_equal(luna.simulator.isComplete(), true)
        luna.simulator.stop()
        luna.simulator.unload("mouse_test")
    end)

    it("should dispatch textinput events via update", function()
        luna.simulator.load("text_test", {
            steps = { { action = "textinput", text = "hello world", time = 0.0 } }
        })
        luna.simulator.start("text_test")
        luna.simulator.update(0.1)
        expect_equal(luna.simulator.isComplete(), true)
        luna.simulator.stop()
        luna.simulator.unload("text_test")
    end)

    it("should handle empty script gracefully", function()
        luna.simulator.load("empty", { steps = {} })
        luna.simulator.start("empty")
        luna.simulator.update(0.1)
        expect_equal(luna.simulator.isComplete(), true)
        luna.simulator.stop()
        luna.simulator.unload("empty")
    end)
end)

describe("luna.simulator - error handling", function()
    it("should error on load with missing steps", function()
        expect_error(function()
            luna.simulator.load("bad", {})
        end)
    end)

    it("should error on load with unknown action", function()
        expect_error(function()
            luna.simulator.load("bad_action", {
                steps = { { action = "explode", time = 0.0 } }
            })
        end)
    end)

    it("should error on load with missing action field", function()
        expect_error(function()
            luna.simulator.load("no_action", {
                steps = { { time = 0.5 } }
            })
        end)
    end)
end)

describe("luna.simulator - TOML loading", function()
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
        luna.simulator.loadFromToml("toml_demo", toml)
        expect_equal(luna.simulator.hasScript("toml_demo"), true)
        luna.simulator.start("toml_demo")
        expect_equal(luna.simulator.getStepCount(), 2)
        luna.simulator.stop()
        luna.simulator.unload("toml_demo")
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
        luna.simulator.loadFromToml("mouse_toml", toml)
        expect_equal(luna.simulator.hasScript("mouse_toml"), true)
        luna.simulator.start("mouse_toml")
        expect_equal(luna.simulator.getStepCount(), 2)
        luna.simulator.stop()
        luna.simulator.unload("mouse_toml")
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
        luna.simulator.loadFromToml("wait_toml", toml)
        expect_equal(luna.simulator.hasScript("wait_toml"), true)
        luna.simulator.start("wait_toml")
        expect_equal(luna.simulator.getStepCount(), 3)
        luna.simulator.stop()
        luna.simulator.unload("wait_toml")
    end)
end)

describe("luna.simulator - complex scenarios", function()
    it("should handle rapid start/stop cycling", function()
        luna.simulator.load("cycle", {
            steps = { { action = "wait", time = 1.0 } }
        })
        for i = 1, 10 do
            luna.simulator.start("cycle")
            expect_equal(luna.simulator.isRunning(), true)
            luna.simulator.stop()
            expect_equal(luna.simulator.isRunning(), false)
        end
        luna.simulator.unload("cycle")
    end)

    it("should handle load/unload cycling", function()
        for i = 1, 10 do
            local name = "cycle_" .. i
            luna.simulator.load(name, {
                steps = { { action = "wait", time = 0.0 } }
            })
            expect_equal(luna.simulator.hasScript(name), true)
            luna.simulator.unload(name)
            expect_equal(luna.simulator.hasScript(name), false)
        end
    end)

    it("should handle multiple scripts loaded simultaneously", function()
        for i = 1, 5 do
            luna.simulator.load("multi_" .. i, {
                steps = { { action = "wait", time = 0.0 } }
            })
        end
        local scripts = luna.simulator.getScripts()
        expect_equal(#scripts, 5)
        for i = 1, 5 do
            luna.simulator.unload("multi_" .. i)
        end
    end)

    it("should handle switching between scripts", function()
        luna.simulator.load("script_a", {
            steps = { { action = "keypress", key = "a", time = 0.0 } }
        })
        luna.simulator.load("script_b", {
            steps = { { action = "keypress", key = "b", time = 0.0 } }
        })

        luna.simulator.start("script_a")
        expect_equal(luna.simulator.getCurrentScript(), "script_a")

        luna.simulator.start("script_b")
        expect_equal(luna.simulator.getCurrentScript(), "script_b")

        luna.simulator.stop()
        luna.simulator.unload("script_a")
        luna.simulator.unload("script_b")
    end)

    it("should run a complete automation sequence", function()
        luna.simulator.load("full_sequence", {
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

        luna.simulator.start("full_sequence")
        expect_equal(luna.simulator.isRunning(), true)
        expect_equal(luna.simulator.getStepCount(), 7)

        -- Run through the entire script
        luna.simulator.update(2.0)
        expect_equal(luna.simulator.isComplete(), true)
        expect_equal(luna.simulator.getCurrentStep(), 7)

        luna.simulator.stop()
        luna.simulator.unload("full_sequence")
    end)

    it("should handle default time of zero", function()
        luna.simulator.load("no_time", {
            steps = {
                { action = "keypress", key = "x" },
            }
        })
        luna.simulator.start("no_time")
        luna.simulator.update(0.01)
        expect_equal(luna.simulator.isComplete(), true)
        luna.simulator.stop()
        luna.simulator.unload("no_time")
    end)
end)

test_summary()
