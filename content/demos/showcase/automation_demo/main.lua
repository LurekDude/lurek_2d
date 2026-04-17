-- Automation Demo
-- Demonstrates the lurek.simulator input automation system.
-- The simulator replays scripted input events (key presses, mouse moves, etc.)
-- into the engine's event queue, useful for testing, replays, and tutorials.
-- Run with: cargo run -- content/demos/showcase/automation_demo

local status = "idle"
local log = {}
local maxLog = 20
local prev_mx, prev_my = 0, 0   -- for detecting mouse movement in process()

-- Helper to add a log entry
local function addLog(msg)
    table.insert(log, msg)
    if #log > maxLog then
        table.remove(log, 1)
    end
end

function lurek.init()
    lurek.render.setBackgroundColor(0.15, 0.15, 0.2)

    -- Load a demo script with mixed input events
    lurek.simulator.load("demo_sequence", {
        steps = {
            { action = "keypress",     key = "w",     time = 0.5 },
            { action = "keyrelease",   key = "w",     time = 0.7 },
            { action = "mousemove",    x = 400, y = 300, dx = 10, dy = 5, time = 1.0 },
            { action = "mousepress",   x = 400, y = 300, button = 1, time = 1.5 },
            { action = "mouserelease", x = 400, y = 300, button = 1, time = 1.6 },
            { action = "textinput",    text = "Hello from simulator!", time = 2.0 },
            { action = "mousewheel",   x = 0, y = 3, time = 2.5 },
            { action = "keypress",     key = "escape", time = 3.0 },
            { action = "keyrelease",   key = "escape", time = 3.1 },
            { action = "wait",         time = 3.5 },
        },
        meta = { description = "A demo sequence showing all input event types" }
    })

    -- Load a simple script using the standard table format
    lurek.simulator.load("toml_script", {
        steps = {
            { action = "keypress",   key = "space", time = 0.0 },
            { action = "keyrelease", key = "space", time = 0.2 },
            { action = "keypress",   key = "a",     time = 0.5 },
            { action = "keyrelease", key = "a",     time = 0.7 },
        },
        meta = { name = "toml_script", description = "Second demo sequence" }
    })

    addLog("Loaded 2 scripts: demo_sequence, toml_script")
    addLog("Press 1 to play demo_sequence")
    addLog("Press 2 to play toml_script")
    addLog("Press P to pause/resume, S to stop")
end

function lurek.process(dt)
    -- Update the simulator (dispatches events into the engine queue)
    lurek.simulator.update(dt)

    -- Poll mouse position and log significant moves (lurek.mousemoved is not an engine callback)
    local mx, my = lurek.mouse.getPosition()
    local dx, dy = mx - prev_mx, my - prev_my
    if math.abs(dx) > 5 or math.abs(dy) > 5 then
        addLog(string.format("Mouse move: (%d,%d) d=(%d,%d)", mx, my, math.floor(dx), math.floor(dy)))
        prev_mx, prev_my = mx, my
    end

    -- Update status display
    if lurek.simulator.isRunning() then
        local name = lurek.simulator.getCurrentScript() or "?"
        local step = lurek.simulator.getCurrentStep()
        local total = lurek.simulator.getStepCount()
        local elapsed = lurek.simulator.getElapsedTime()
        status = string.format("Running: %s [step %d/%d] %.1fs", name, step, total, elapsed)
    elseif lurek.simulator.isPaused() then
        status = "Paused"
    elseif lurek.simulator.isComplete() then
        status = "Complete"
    else
        status = "Idle"
    end
end

function lurek.render()
    -- Title
    lurek.render.setColor(1, 1, 0.6)
    lurek.render.print("Automation Demo", 20, 20)

    -- Status
    lurek.render.setColor(0.6, 1, 0.6)
    lurek.render.print("Status: " .. status, 20, 50)

    -- Scripts loaded
    lurek.render.setColor(0.8, 0.8, 0.8)
    local scripts = lurek.simulator.getScripts()
    lurek.render.print("Scripts loaded: " .. #scripts, 20, 80)
    for i, name in ipairs(scripts) do
        lurek.render.print("  " .. i .. ". " .. name, 30, 80 + i * 20)
    end

    -- Controls
    lurek.render.setColor(0.6, 0.8, 1)
    local y = 180
    lurek.render.print("Controls:", 20, y)
    lurek.render.print("  1 = Play demo_sequence", 30, y + 20)
    lurek.render.print("  2 = Play toml_script", 30, y + 40)
    lurek.render.print("  P = Pause / Resume", 30, y + 60)
    lurek.render.print("  S = Stop", 30, y + 80)

    -- Log
    lurek.render.setColor(0.7, 0.7, 0.7)
    local logY = y + 120
    lurek.render.print("Log:", 20, logY)
    for i, entry in ipairs(log) do
        lurek.render.print(entry, 30, logY + i * 18)
    end
end

function lurek.keypressed(key)
    if key == "1" then
        lurek.simulator.start("demo_sequence")
        addLog("Started demo_sequence")
    elseif key == "2" then
        lurek.simulator.start("toml_script")
        addLog("Started toml_script")
    elseif key == "p" then
        if lurek.simulator.isPaused() then
            lurek.simulator.resume()
            addLog("Resumed")
        elseif lurek.simulator.isRunning() then
            lurek.simulator.pause()
            addLog("Paused")
        end
    elseif key == "s" then
        lurek.simulator.stop()
        addLog("Stopped")
    else
        addLog("Key: " .. key .. " (simulated or real)")
    end
end

function lurek.mousepressed(x, y, button)
    addLog(string.format("Mouse press: (%d,%d) btn=%d", x, y, button))
end

function lurek.mousereleased(x, y, button)
    addLog(string.format("Mouse release: (%d,%d) btn=%d", x, y, button))
end

function lurek.textinput(text)
    addLog("Text input: " .. text)
end

function lurek.wheelmoved(x, y)
    addLog(string.format("Wheel: (%d,%d)", x, y))
end
