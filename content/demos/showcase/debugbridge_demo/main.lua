-- Debug Bridge Demo
-- Demonstrates the luna.debugbridge TCP debug server API
-- Connect with: telnet 127.0.0.1 19740
-- or netcat: nc 127.0.0.1 19740
-- Then send: {"id":1,"method":"ping"}
-- Run with: cargo run -- demos/showcase/debugbridge_demo

if not luna.debugbridge then
    function luna.init()
        luna.gfx.setBackgroundColor(0.08, 0.08, 0.12)
    end
    function luna.render()
        luna.gfx.setColor(1, 0.6, 0.2)
        luna.gfx.print("Debug Bridge Demo", 20, 20)
        luna.gfx.setColor(0.7, 0.7, 0.7)
        luna.gfx.print("luna.debugbridge is not available in this build.", 20, 60)
        luna.gfx.print("(API not yet implemented)", 20, 85)
    end
    return
end

local db = luna.debugbridge
local frame_count = 0
local server_started = false

function luna.init()
    luna.gfx.setBackgroundColor(0.08, 0.08, 0.12)

    -- Start the debug bridge server
    server_started = db.start(19740)
    if server_started then
        db.capturePrint("Debug bridge started on port 19740")
    end
end

function luna.process(dt)
    frame_count = frame_count + 1

    -- Poll for pending TCP requests (required each frame).
    -- poll() automatically records frame time via luna.time.getDelta().
    db.poll()

    -- Log a message every 60 frames
    if frame_count % 60 == 0 then
        db.capturePrint("Frame " .. frame_count, "main.lua", 0)
    end
end

function luna.render()
    local y = 20

    luna.gfx.setColor(1, 1, 0.6)
    luna.gfx.print("Debug Bridge Demo", 20, y)
    y = y + 30

    -- Server status
    luna.gfx.setColor(0.7, 1, 0.7)
    luna.gfx.print("Server running: " .. tostring(db.isRunning()), 20, y)
    y = y + 20
    luna.gfx.print("Port: " .. db.getPort(), 20, y)
    y = y + 20
    luna.gfx.print("Connected clients: " .. db.getClientCount(), 20, y)
    y = y + 30

    -- Performance
    local perf = db.getPerformance()
    luna.gfx.setColor(0.7, 0.8, 1)
    luna.gfx.print(string.format("FPS: %.1f  |  avg dt: %.3fms", perf.fps or 0, (perf.avgDt or 0) * 1000), 20, y)
    y = y + 30

    -- Print history (last 5)
    luna.gfx.setColor(1, 0.8, 0.6)
    luna.gfx.print("Print history (last 5):", 20, y)
    y = y + 20

    local history = db.getPrintHistory(5)
    for i = 1, #history do
        luna.gfx.setColor(0.8, 0.8, 0.8)
        luna.gfx.print(history[i].message, 30, y)
        y = y + 16
    end
    y = y + 20

    -- Instructions
    luna.gfx.setColor(0.5, 0.6, 0.5)
    luna.gfx.print("Connect via TCP to interact:", 20, y)
    y = y + 18
    luna.gfx.print('  {"id":1,"method":"ping"}', 30, y)
    y = y + 18
    luna.gfx.print('  {"id":2,"method":"eval","params":{"code":"return 2+2"}}', 30, y)
    y = y + 18
    luna.gfx.print('  {"id":3,"method":"getPerformance"}', 30, y)
    y = y + 30

    luna.gfx.setColor(0.5, 0.5, 0.5)
    luna.gfx.print("Press ESC to quit", 20, y)
end

function luna.keypressed(key)
    if key == "escape" then
        db.stop()
        luna.signal.quit()
    end
end
