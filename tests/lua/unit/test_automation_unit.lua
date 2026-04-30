-- Lua BDD tests for lurek.automation (automation module)

-- @description Verifies the simulator namespace is exposed and that every documented loader, lifecycle, query, and TOML helper entry point is registered on the Lua side.
describe("lurek.automation - namespace", function()
    -- @tests lurek.automation.getCurrentScript
    -- @tests lurek.automation.getCurrentStep
    -- @tests lurek.automation.getElapsedTime
    -- @tests lurek.automation.getScripts
    -- @tests lurek.automation.getStepCount
    -- @tests lurek.automation.hasScript
    -- @tests lurek.automation.isComplete
    -- @tests lurek.automation.isPaused
    -- @tests lurek.automation.isRunning
    -- @tests lurek.automation.load
    -- @tests lurek.automation.loadFromToml
    -- @tests lurek.automation.pause
    -- @tests lurek.automation.resume
    -- @tests lurek.automation.start
    -- @tests lurek.automation.stop
    -- @tests lurek.automation.unload
    -- @tests lurek.automation.update
    -- @description Confirms the simulator namespace is registered as a Lua table.
    it("should exist as a table", function()
        expect_type("table", lurek.automation)
    end)

    -- @description Checks the scripted automation loader is exported for table-based script definitions.
    it("should have load function", function()
        expect_type("function", lurek.automation.load)
    end)

    -- @description Checks the unload entry point is exported for removing previously loaded scripts.
    it("should have unload function", function()
        expect_type("function", lurek.automation.unload)
    end)

    -- @description Verifies the namespace exposes the script-existence query helper.
    it("should have hasScript function", function()
        expect_type("function", lurek.automation.hasScript)
    end)

    -- @description Verifies the namespace exposes the loaded-script listing helper.
    it("should have getScripts function", function()
        expect_type("function", lurek.automation.getScripts)
    end)

    -- @description Confirms playback can be started through the exported start function.
    it("should have start function", function()
        expect_type("function", lurek.automation.start)
    end)

    -- @description Confirms playback can be stopped through the exported stop function.
    it("should have stop function", function()
        expect_type("function", lurek.automation.stop)
    end)

    -- @description Confirms the pause control is available on the namespace.
    it("should have pause function", function()
        expect_type("function", lurek.automation.pause)
    end)

    -- @description Confirms the resume control is available on the namespace.
    it("should have resume function", function()
        expect_type("function", lurek.automation.resume)
    end)

    -- @description Verifies the time-step update entry point is exported for dispatching queued steps.
    it("should have update function", function()
        expect_type("function", lurek.automation.update)
    end)

    -- @description Checks the running-state query exists so callers can detect active playback.
    it("should have isRunning function", function()
        expect_type("function", lurek.automation.isRunning)
    end)

    -- @description Checks the paused-state query exists so callers can detect paused playback.
    it("should have isPaused function", function()
        expect_type("function", lurek.automation.isPaused)
    end)

    -- @description Checks the completion-state query exists so callers can detect fully consumed scripts.
    it("should have isComplete function", function()
        expect_type("function", lurek.automation.isComplete)
    end)

    -- @description Verifies the current-step query helper is exported.
    it("should have getCurrentStep function", function()
        expect_type("function", lurek.automation.getCurrentStep)
    end)

    -- @description Verifies the total-step-count query helper is exported.
    it("should have getStepCount function", function()
        expect_type("function", lurek.automation.getStepCount)
    end)

    -- @description Verifies the current-script query helper is exported.
    it("should have getCurrentScript function", function()
        expect_type("function", lurek.automation.getCurrentScript)
    end)

    -- @description Verifies the elapsed-time query helper is exported.
    it("should have getElapsedTime function", function()
        expect_type("function", lurek.automation.getElapsedTime)
    end)

    -- @description Confirms TOML-based loading is available alongside table-based loading.
    it("should have loadFromToml function", function()
        expect_type("function", lurek.automation.loadFromToml)
    end)
end)

-- @description Exercises loading, replacing, listing, and unloading simulator scripts built from step tables and optional metadata.
describe("lurek.automation - script management", function()
    -- @description Loads a minimal one-step keypress script and verifies it is registered under the requested name.
    it("should load a script with a single keypress step", function()
        lurek.automation.load("single_key", {
            steps = {
                { action = "keypress", key = "a", time = 0.5 }
            }
        })
        expect_equal(lurek.automation.hasScript("single_key"), true)
        lurek.automation.unload("single_key")
    end)

    -- @description Loads a mixed-action script covering keyboard, mouse, text, and wait steps to verify the parser accepts every supported step shape.
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

    -- @description Confirms script metadata can accompany the step list without preventing registration.
    it("should load a script with meta description", function()
        lurek.automation.load("described", {
            steps = { { action = "wait", time = 0.0 } },
            meta = { description = "A test script with description" }
        })
        expect_equal(lurek.automation.hasScript("described"), true)
        lurek.automation.unload("described")
    end)

    -- @description Verifies unknown script names are reported as absent rather than raising errors.
    it("should report hasScript false for unknown scripts", function()
        expect_equal(lurek.automation.hasScript("nonexistent"), false)
    end)

    -- @description Loads and unloads a script, then checks the removal call returns success and clears the registry entry.
    it("should unload a loaded script", function()
        lurek.automation.load("to_remove", {
            steps = { { action = "wait", time = 0.0 } }
        })
        local result = lurek.automation.unload("to_remove")
        expect_equal(result, true)
        expect_equal(lurek.automation.hasScript("to_remove"), false)
    end)

    -- @description Verifies unloading a missing script is a harmless false result instead of an exception.
    it("should return false when unloading nonexistent script", function()
        local result = lurek.automation.unload("does_not_exist")
        expect_equal(result, false)
    end)

    -- @description Confirms the loaded-script listing includes every registered name when multiple scripts coexist.
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

    -- @description Clears any existing state and verifies the script listing becomes an empty table when nothing is loaded.
    it("should return empty table when no scripts loaded", function()
        -- Clean state
        for _, name in ipairs(lurek.automation.getScripts()) do
            lurek.automation.unload(name)
        end
        local names = lurek.automation.getScripts()
        expect_equal(#names, 0)
    end)

    -- @description Loads the same script name twice and verifies the second definition replaces the first, including its step count.
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

-- @description Covers simulator playback lifecycle transitions including starting, stopping, pausing, resuming, and no-op control calls when idle.
describe("lurek.automation - playback control", function()
    -- @description Starts a loaded script and checks that running-state and current-script queries reflect the active playback.
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

    -- @description Verifies attempting to start an unknown script raises an error instead of entering an invalid running state.
    it("should error when starting nonexistent script", function()
        expect_error(function()
            lurek.automation.start("nonexistent_script")
        end)
    end)

    -- @description Stops an active script and verifies the runtime resets its running flag, current script, and current step index.
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

    -- @description Pauses a running script and verifies the paused and running state flags flip appropriately.
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

    -- @description Resumes a paused script and verifies playback returns to the running state while clearing the paused flag.
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

    -- @description Ensures calling pause while idle is a safe no-op that does not manufacture a paused state.
    it("should be safe to pause when idle", function()
        lurek.automation.pause()
        expect_equal(lurek.automation.isPaused(), false)
    end)

    -- @description Ensures calling stop while idle is a safe no-op that leaves the simulator non-running.
    it("should be safe to stop when idle", function()
        lurek.automation.stop()
        expect_equal(lurek.automation.isRunning(), false)
    end)

    -- @description Verifies resume is idempotent when playback is already running and does not disrupt the active script.
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

-- @description Verifies the simulator exposes stable default query values while idle with no script loaded or running.
describe("lurek.automation - state queries", function()
    -- @description Checks the running-state query reports false before playback begins.
    it("should report not running when idle", function()
        expect_equal(lurek.automation.isRunning(), false)
    end)

    -- @description Checks the paused-state query reports false in idle state.
    it("should report not paused when idle", function()
        expect_equal(lurek.automation.isPaused(), false)
    end)

    -- @description Checks the completion-state query reports false when no script has been executed.
    it("should report not complete when idle", function()
        expect_equal(lurek.automation.isComplete(), false)
    end)

    -- @description Checks the elapsed-time counter starts at zero before any updates are processed.
    it("should report zero elapsed time when idle", function()
        expect_near(lurek.automation.getElapsedTime(), 0.0, 0.001)
    end)

    -- @description Checks the current-step query starts at zero before playback begins.
    it("should report zero current step when idle", function()
        expect_equal(lurek.automation.getCurrentStep(), 0)
    end)

    -- @description Checks the total-step-count query reports zero when no active script is selected.
    it("should report zero step count when idle", function()
        expect_equal(lurek.automation.getStepCount(), 0)
    end)

    -- @description Checks the current-script query returns nil when the simulator is idle.
    it("should report nil current script when idle", function()
        expect_equal(lurek.automation.getCurrentScript(), nil)
    end)
end)

-- @description Exercises runtime advancement, event dispatch, completion handling, and paused behavior while simulator time is updated.
describe("lurek.automation - update and completion", function()
    -- @description Advances a running script in two updates and verifies elapsed time accumulates exactly across calls.
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

    -- @description Runs past the timestamps of every step in a short script and verifies the simulator marks playback complete and stops running.
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

    -- @description Verifies current-step tracking increments as timed wait steps become eligible for dispatch over multiple updates.
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

    -- @description Pauses playback before updating and verifies neither elapsed time nor current-step state advances while paused.
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

    -- @description Dispatches a keypress and keyrelease sequence through update and verifies the script completes after both keyboard events are processed.
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

    -- @description Dispatches mouse movement, press, release, and wheel steps and verifies the scripted mouse sequence completes in one update window.
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

    -- @description Dispatches a text-input step and verifies the single-step script reaches completion.
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

    -- @description Starts a script with no steps and verifies the simulator treats it as immediately complete without errors.
    it("should handle empty script gracefully", function()
        lurek.automation.load("empty", { steps = {} })
        lurek.automation.start("empty")
        lurek.automation.update(0.1)
        expect_equal(lurek.automation.isComplete(), true)
        lurek.automation.stop()
        lurek.automation.unload("empty")
    end)
end)

-- @description Verifies invalid simulator script definitions fail fast with descriptive errors instead of registering broken playback data.
describe("lurek.automation - error handling", function()
    -- @description Rejects script loads that omit the required steps array entirely.
    it("should error on load with missing steps", function()
        expect_error(function()
            lurek.automation.load("bad", {})
        end)
    end)

    -- @description Rejects steps whose action name is not part of the supported simulator action set.
    it("should error on load with unknown action", function()
        expect_error(function()
            lurek.automation.load("bad_action", {
                steps = { { action = "explode", time = 0.0 } }
            })
        end)
    end)

    -- @description Rejects step tables that omit the mandatory action field.
    it("should error on load with missing action field", function()
        expect_error(function()
            lurek.automation.load("no_action", {
                steps = { { time = 0.5 } }
            })
        end)
    end)
end)

-- @description Exercises parsing automation scripts from TOML strings for keyboard, mouse, and wait-only step sequences.
describe("lurek.automation - TOML loading", function()
    -- @description Loads a TOML document containing keypress and keyrelease steps and verifies the resulting script can be started with the expected step count.
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

    -- @description Loads a TOML document containing mouse movement and press steps and verifies both steps are parsed into the runtime script.
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

    -- @description Loads a TOML document composed only of timed wait steps and verifies all three entries are present after parsing.
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

-- @description Stress-tests repeated lifecycle operations, multi-script registry behavior, script switching, and full mixed-input automation sequences.
describe("lurek.automation - complex scenarios", function()
    -- @description Repeats start and stop operations on the same script to verify lifecycle state stays consistent through rapid cycling.
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

    -- @description Repeats load and unload operations with unique script names to verify registry cleanup remains stable over multiple cycles.
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

    -- @description Loads several scripts side by side and verifies the registry can hold all of them simultaneously before cleanup.
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

    -- @description Starts one script, then another, to verify the active script pointer switches cleanly between loaded scripts.
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

    -- @description Runs a mixed mouse, keyboard, text, and wait script end-to-end and verifies the simulator reaches completion with every step counted.
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

    -- @description Verifies steps without an explicit time default to zero and are dispatched immediately on the first update.
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
    -- @description saveMacro then hasMacro returns true.
    it("hasMacro returns true after saveMacro", function()
        lurek.automation.load("m_src", { steps = { { action = "wait", time = 0.01 } } })
        lurek.automation.saveMacro("my_macro", "m_src")
        expect_equal(lurek.automation.hasMacro("my_macro"), true)
        expect_equal(lurek.automation.hasMacro("missing"), false)
        lurek.automation.unload("m_src")
    end)

    -- @description listMacros returns a table containing saved macro names.
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

    -- @description playMacro starts a previously saved macro.
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
    -- @description setPlaybackSpeed stores the value and getPlaybackSpeed returns it.
    it("setPlaybackSpeed round-trips correctly", function()
        lurek.automation.setPlaybackSpeed(2.0)
        expect_near(lurek.automation.getPlaybackSpeed(), 2.0, 0.001)
        lurek.automation.setPlaybackSpeed(1.0)
    end)

    -- @description At 2x speed, a 0.1s step completes in 0.05s real update time.
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
    -- @description waitUntil(fn, timeout) freezes the clock until predicate returns true.
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

-- @description Covers suite: lurek.automation step limit configurability.
describe("lurek.automation step limit", function()
    -- @tests lurek.automation.getStepLimit
    -- @description Verifies getStepLimit is exported as a callable function on the simulator namespace.
    it("getStepLimit_is_a_function", function()
        expect_type("function", lurek.automation.getStepLimit)
    end)

    -- @tests lurek.automation.setStepLimit
    -- @description Verifies setStepLimit is exported as a callable function on the simulator namespace.
    it("setStepLimit_is_a_function", function()
        expect_type("function", lurek.automation.setStepLimit)
    end)

    -- @tests lurek.automation.getStepLimit
    -- @description Returns nil for a script name that has not been registered.
    it("getStepLimit_returns_nil_for_unregistered_script", function()
        local result = lurek.automation.getStepLimit("nonexistent_script_xyz")
        expect_nil(result)
    end)

    -- @tests lurek.automation.load
    -- @tests lurek.automation.setStepLimit
    -- @tests lurek.automation.getStepLimit
    -- @tests lurek.automation.unload
    -- @description Loads a script, sets its step limit, and reads it back to verify round-trip fidelity.
    it("setStepLimit_registers_on_a_loaded_script", function()
        lurek.automation.load("step_limit_test", {
            steps = { { action = "keypress", key = "a", time = 0.01 } }
        })
        local ok = lurek.automation.setStepLimit("step_limit_test", 50)
        expect_true(ok)
        expect_equal(50, lurek.automation.getStepLimit("step_limit_test"))
        lurek.automation.unload("step_limit_test")
    end)

    -- @tests lurek.automation.setStepLimit
    -- @description Returns false when the named script is not found.
    it("setStepLimit_returns_false_for_unknown_script", function()
        local ok = lurek.automation.setStepLimit("no_such_script", 10)
        expect_false(ok)
    end)

    -- @tests lurek.automation.load
    -- @tests lurek.automation.setStepLimit
    -- @tests lurek.automation.getStepLimit
    -- @tests lurek.automation.unload
    -- @description Overwrites an existing step limit with a new value and verifies the stored value updates.
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

-- ── Automation Highlight (merged from test_automation_highlight.lua) ──

describe("lurek.automation highlight mode API types", function()
  -- @tests lurek.automation.setHighlightMode
  it("setHighlightMode is a function", function()
    expect_type("function", lurek.automation.setHighlightMode)
  end)

  -- @tests lurek.automation.isHighlightMode
  it("isHighlightMode is a function", function()
    expect_type("function", lurek.automation.isHighlightMode)
  end)
end)

describe("lurek.automation.isHighlightMode default", function()
  -- @tests lurek.automation.isHighlightMode
  it("default highlight mode is false", function()
    -- Reset state first: enabling then disabling resets to false
    lurek.automation.setHighlightMode(false)
    local result = lurek.automation.isHighlightMode()
    expect_equal(false, result)
  end)
end)

describe("lurek.automation setHighlightMode / isHighlightMode roundtrip", function()
  -- @tests lurek.automation.setHighlightMode
  -- @tests lurek.automation.isHighlightMode
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
