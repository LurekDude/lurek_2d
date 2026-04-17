-- Debug Bridge Demo
-- Demonstrates the lurek.debugbridge TCP debug server API
-- Connect with: telnet 127.0.0.1 19740
-- or netcat: nc 127.0.0.1 19740
-- Then send: {"id":1,"method":"ping"}
-- Run with: cargo run -- content/demos/showcase/debugbridge_demo

if not lurek.debugbridge then
    function lurek.init()
        lurek.render.setBackgroundColor(0.08, 0.08, 0.12)
    end
    function lurek.render()
        lurek.render.setColor(1, 0.6, 0.2)
        lurek.render.print("Debug Bridge Demo", 20, 20)
        lurek.render.setColor(0.7, 0.7, 0.7)
        lurek.render.print("lurek.debugbridge is not available in this build.", 20, 60)
        lurek.render.print("(API not yet implemented)", 20, 85)
    end
    return
end

local db = lurek.debugbridge
local frame_count = 0
local server_started = false

function lurek.init()
    lurek.render.setBackgroundColor(0.08, 0.08, 0.12)

    -- Start the debug bridge server
    server_started = db.start(19740)
    if server_started then
        db.capturePrint("Debug bridge started on port 19740")
    end
end

function lurek.process(dt)
    frame_count = frame_count + 1

    -- Poll for pending TCP requests (required each frame).
    -- poll() automatically records frame time via lurek.time.getDelta().
    db.poll()

    -- Log a message every 60 frames
    if frame_count % 60 == 0 then
        db.capturePrint("Frame " .. frame_count, "main.lua", 0)
    end
end

function lurek.render()
    local y = 20

    lurek.render.setColor(1, 1, 0.6)
    lurek.render.print("Debug Bridge Demo", 20, y)
    y = y + 30

    -- Server status
    lurek.render.setColor(0.7, 1, 0.7)
    lurek.render.print("Server running: " .. tostring(db.isRunning()), 20, y)
    y = y + 20
    lurek.render.print("Port: " .. db.getPort(), 20, y)
    y = y + 20
    lurek.render.print("Connected clients: " .. db.getClientCount(), 20, y)
    y = y + 30

    -- Performance
    local perf = db.getPerformance()
    lurek.render.setColor(0.7, 0.8, 1)
    lurek.render.print(string.format("FPS: %.1f  |  avg dt: %.3fms", perf.fps or 0, (perf.avgDt or 0) * 1000), 20, y)
    y = y + 30

    -- Print history (last 5)
    lurek.render.setColor(1, 0.8, 0.6)
    lurek.render.print("Print history (last 5):", 20, y)
    y = y + 20

    local history = db.getPrintHistory(5)
    for i = 1, #history do
        lurek.render.setColor(0.8, 0.8, 0.8)
        lurek.render.print(history[i].message, 30, y)
        y = y + 16
    end
    y = y + 20

    -- Instructions
    lurek.render.setColor(0.5, 0.6, 0.5)
    lurek.render.print("Connect via TCP to interact:", 20, y)
    y = y + 18
    lurek.render.print('  {"id":1,"method":"ping"}', 30, y)
    y = y + 18
    lurek.render.print('  {"id":2,"method":"eval","params":{"code":"return 2+2"}}', 30, y)
    y = y + 18
    lurek.render.print('  {"id":3,"method":"getPerformance"}', 30, y)
    y = y + 30

    lurek.render.setColor(0.5, 0.5, 0.5)
    lurek.render.print("Press ESC to quit", 20, y)
end

function lurek.keypressed(key)
    if key == "escape" then
        db.stop()
        lurek.signal.quit()
    end
end
