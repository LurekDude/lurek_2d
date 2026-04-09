-- examples/automation.lua
-- lurek.simulator — Scripted input automation / replay system.
-- Load named automation scripts, play them back step by step, and integrate with
-- the game loop for deterministic testing or demo playback.

-- ── Script Format ─────────────────────────────────────────────────────────────
-- An automation script is a Lua table with:
meta?  = { description = "human-readable string" }
steps  = array of step tables
--
-- Each step can be:
{ action="keypress",    key="space", scancode=?, isRepeat=false }
{ action="keyrelease",  key="space" }
{ action="mousemove",   x=400, y=300, dx=0, dy=0 }
{ action="mousepress",  x=400, y=300, button="1", clicks=1 }
{ action="mouserelease",x=400, y=300, button="1", clicks=1 }
{ action="mousewheel",  x=0, y=-1 }
{ action="textinput",   text="Hello" }
{ action="wait",        time=0.5 }   -- pause for N seconds before next step

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

-- lurek.simulator.load(name, script_data)  — register an automation script by name
lurek.simulator.load("menu_demo", demo_script)

local script = lurek.simulator.hasScript(name)
local exists = lurek.simulator.hasScript("menu_demo")   -- true

local scripts = lurek.simulator.getScripts()
local all_scripts = lurek.simulator.getScripts()
for _, name in ipairs(all_scripts) do
    print("Loaded script:", name)
end

-- lurek.simulator.unload(name) → boolean  — unregister and return true if found
lurek.simulator.unload("menu_demo")

-- ── Playback Control ─────────────────────────────────────────────────────────

-- lurek.simulator.start(name)  — begin playback of a loaded script
lurek.simulator.start("menu_demo")

local running = lurek.simulator.isRunning()
local paused = lurek.simulator.isPaused()
local complete = lurek.simulator.isComplete()

lurek.simulator.pause()  -- freeze playback at the current step
lurek.simulator.resume()  -- continue after pause

lurek.simulator.stop()  -- halt and reset the current playback

-- ── Advancing Playback ────────────────────────────────────────────────────────

lurek.simulator.update(dt)
-- Must be called once per frame inside lurek.process(dt).
-- Advances time-based steps and issues synthesized input events.

local function run_once_each_frame(dt)
    lurek.simulator.update(dt)

    if lurek.simulator.isComplete() then
        print("Automation complete.")
    end
end

-- ── Inspecting State ─────────────────────────────────────────────────────────

-- getCurrentStep() → integer   — 1-based index of the step currently executing
local step_idx = lurek.simulator.getCurrentStep()

-- getStepCount() → integer     — total number of steps in the active script
local total = lurek.simulator.getStepCount()

-- getCurrentScript() → string?  — name of the active script, or nil if idle
local active = lurek.simulator.getCurrentScript()

-- getElapsedTime() → number    — time in seconds since start() was called
local elapsed = lurek.simulator.getElapsedTime()

print(("Step %d / %d  [%s]  elapsed: %.2fs")
    :format(step_idx, total, active or "none", elapsed))

-- ── Typical Usage Inside lurek.process ─────────────────────────────────────────

--[[
function lurek.init()
    local script = { meta={description="CI smoke test"}, steps={
        { action="wait", time=0.1 },
        { action="keypress",   key="space" },
        { action="keyrelease", key="space" },
        { action="wait", time=0.1 },
    }}
    lurek.simulator.load("smoke", script)
    lurek.simulator.start("smoke")
end

function lurek.process(dt)
    lurek.simulator.update(dt)
    if lurek.simulator.isComplete() then
        print("Smoke test passed — quitting")
        lurek.signal.quit()
    end
end
]]


-- ─── lurek.simulator ────────────────────────────────────────────────────────────
lurek.simulator.loadFromToml("physics_config", raw_toml_string)  -- Parses a TOML string and registers it as a named script
