-- examples/automation.lua
-- luna.simulator — Scripted input automation / replay system.
-- Load named automation scripts, play them back step by step, and integrate with
-- the game loop for deterministic testing or demo playback.
-- All luna.simulator API methods demonstrated with code and comments.
-- This file is documentation code, not a runnable game.

-- ── Script Format ─────────────────────────────────────────────────────────────
-- An automation script is a Lua table with:
--   meta?  = { description = "human-readable string" }
--   steps  = array of step tables
--
-- Each step can be:
--   { action="keypress",    key="space", scancode=?, isRepeat=false }
--   { action="keyrelease",  key="space" }
--   { action="mousemove",   x=400, y=300, dx=0, dy=0 }
--   { action="mousepress",  x=400, y=300, button="1", clicks=1 }
--   { action="mouserelease",x=400, y=300, button="1", clicks=1 }
--   { action="mousewheel",  x=0, y=-1 }
--   { action="textinput",   text="Hello" }
--   { action="wait",        time=0.5 }   -- pause for N seconds before next step

local demo_script = {
    meta = { description = "Menu navigation demo" },
    steps = {
        { action = "wait",        time  = 0.2 },
        { action = "keypress",    key   = "down" },
        { action = "keyrelease",  key   = "down" },
        { action = "wait",        time  = 0.1 },
        { action = "keypress",    key   = "return" },
        { action = "keyrelease",  key   = "return" },
        { action = "mousemove",   x = 640, y = 360, dx = 0, dy = 0 },
        { action = "mousepress",  x = 640, y = 360, button = "1", clicks = 1 },
        { action = "mouserelease",x = 640, y = 360, button = "1", clicks = 1 },
        { action = "textinput",   text  = "Player1" },
        { action = "wait",        time  = 0.5 },
    }
}

-- ── Loading / Unloading Scripts ───────────────────────────────────────────────

-- luna.simulator.load(name, script_data)  — register an automation script by name
luna.simulator.load("menu_demo", demo_script)

-- luna.simulator.hasScript(name) → boolean
local exists = luna.simulator.hasScript("menu_demo")   -- true

-- luna.simulator.getScripts() → table (array of name strings)
local all_scripts = luna.simulator.getScripts()
for _, name in ipairs(all_scripts) do
    print("Loaded script:", name)
end

-- luna.simulator.unload(name) → boolean  — unregister and return true if found
-- luna.simulator.unload("menu_demo")

-- ── Playback Control ─────────────────────────────────────────────────────────

-- luna.simulator.start(name)  — begin playback of a loaded script
luna.simulator.start("menu_demo")

-- luna.simulator.isRunning() → boolean
-- luna.simulator.isPaused() → boolean
-- luna.simulator.isComplete() → boolean

-- luna.simulator.pause()   — freeze playback at the current step
-- luna.simulator.resume()  — continue after pause

-- luna.simulator.stop()    — halt and reset the current playback

-- ── Advancing Playback ────────────────────────────────────────────────────────

-- luna.simulator.update(dt)
-- Must be called once per frame inside luna.process(dt).
-- Advances time-based steps and issues synthesized input events.

local function run_once_each_frame(dt)
    luna.simulator.update(dt)

    if luna.simulator.isComplete() then
        print("Automation complete.")
    end
end

-- ── Inspecting State ─────────────────────────────────────────────────────────

-- getCurrentStep() → integer   — 1-based index of the step currently executing
local step_idx = luna.simulator.getCurrentStep()

-- getStepCount() → integer     — total number of steps in the active script
local total = luna.simulator.getStepCount()

-- getCurrentScript() → string?  — name of the active script, or nil if idle
local active = luna.simulator.getCurrentScript()

-- getElapsedTime() → number    — time in seconds since start() was called
local elapsed = luna.simulator.getElapsedTime()

print(("Step %d / %d  [%s]  elapsed: %.2fs")
    :format(step_idx, total, active or "none", elapsed))

-- ── Typical Usage Inside luna.process ─────────────────────────────────────────

--[[
function luna.init()
    local script = { meta={description="CI smoke test"}, steps={
        { action="wait", time=0.1 },
        { action="keypress",   key="space" },
        { action="keyrelease", key="space" },
        { action="wait", time=0.1 },
    }}
    luna.simulator.load("smoke", script)
    luna.simulator.start("smoke")
end

function luna.process(dt)
    luna.simulator.update(dt)
    if luna.simulator.isComplete() then
        print("Smoke test passed — quitting")
        luna.signal.quit()
    end
end
]]


-- ─── luna.simulator ────────────────────────────────────────────────────────────
luna.simulator.loadFromToml("physics_config", raw_toml_string)  -- Parses a TOML string and registers it as a named script
