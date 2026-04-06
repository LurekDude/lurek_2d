-- Debug Bridge Demo
-- Demonstrates the luna.debugbridge TCP debug server API
-- Connect with: telnet 127.0.0.1 19740
-- or netcat: nc 127.0.0.1 19740
-- Then send: {"id":1,"method":"ping"}\n

local db = luna.debugbridge
local frame_count = 0
local server_started = false

function luna.load()
    luna.graphics.setBackgroundColor(0.08, 0.08, 0.12)

    -- Start the debug bridge server
    server_started = db.start(19740)
    if server_started then
        db.capturePrint("Debug bridge started on port 19740")
    end
end

function luna.update(dt)
    frame_count = frame_count + 1

    -- Poll for pending TCP requests (required each frame)
    db.poll()

    -- Record frame time for performance tracking
    db.recordFrame(dt)

    -- Log a message every 60 frames
    if frame_count % 60 == 0 then
        db.capturePrint("Frame " .. frame_count, "main.lua", 0)
    end
end

function luna.draw()
    local y = 20

    luna.graphics.setColor(1, 1, 0.6)
    luna.graphics.print("Debug Bridge Demo", 20, y)
    y = y + 30

    -- Server status
    luna.graphics.setColor(0.7, 1, 0.7)
    luna.graphics.print("Server running: " .. tostring(db.isRunning()), 20, y)
    y = y + 20
    luna.graphics.print("Port: " .. db.getPort(), 20, y)
    y = y + 20
    luna.graphics.print("Connected clients: " .. db.getClientCount(), 20, y)
    y = y + 30

    -- Performance
    local perf = db.getPerformance()
    luna.graphics.setColor(0.7, 0.8, 1)
    luna.graphics.print(string.format("FPS: %.1f  |  avg dt: %.3fms", perf.fps or 0, (perf.avgDt or 0) * 1000), 20, y)
    y = y + 30

    -- Print history (last 5)
    luna.graphics.setColor(1, 0.8, 0.6)
    luna.graphics.print("Print history (last 5):", 20, y)
    y = y + 20

    local history = db.getPrintHistory(5)
    for i = 1, #history do
        luna.graphics.setColor(0.8, 0.8, 0.8)
        luna.graphics.print(history[i].message, 30, y)
        y = y + 16
    end
    y = y + 20

    -- Instructions
    luna.graphics.setColor(0.5, 0.6, 0.5)
    luna.graphics.print("Connect via TCP to interact:", 20, y)
    y = y + 18
    luna.graphics.print('  {"id":1,"method":"ping"}', 30, y)
    y = y + 18
    luna.graphics.print('  {"id":2,"method":"eval","params":{"code":"return 2+2"}}', 30, y)
    y = y + 18
    luna.graphics.print('  {"id":3,"method":"getPerformance"}', 30, y)
    y = y + 30

    luna.graphics.setColor(0.5, 0.5, 0.5)
    luna.graphics.print("Press ESC to quit", 20, y)
end

function luna.keypressed(key)
    if key == "escape" then
        db.stop()
        luna.event.quit()
    end
end
