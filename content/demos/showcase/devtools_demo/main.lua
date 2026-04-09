-- Module availability guard (added by fix_nil_module_demos.py)
-- Run with: cargo run -- content/demos/showcase/devtools_demo
if not lurek.devtools then
    function lurek.init()
        lurek.gfx.setBackgroundColor(0.08, 0.08, 0.12)
        lurek.gfx.print("lurek.devtools is not available in this build", 180, 270)
    end
    return
end

-- Devtools Demo
-- Demonstrates the lurek.devtools runtime diagnostics API

local dt = lurek.devtools
local frame_count = 0

function lurek.init()
    -- Configure logger
    dt.setLogLevel("debug")
    dt.setLogConsole(false)  -- suppress stderr in demo

    dt.info("Devtools demo starting")
    dt.debug("Debug-level message")
    dt.warn("Example warning")

    -- Enable profiler
    dt.setProfilingEnabled(true)

    -- Frame stats
    dt.setFrameHistorySize(120)

    lurek.gfx.setBackgroundColor(0.1, 0.1, 0.15)
end

function lurek.process(delta)
    frame_count = frame_count + 1

    -- Profile the update phase
    dt.profilePush("update")

    -- Record frame time
    dt.recordFrameTime(delta)

    -- Simulate work
    dt.profilePush("physics")
    local sum = 0
    for i = 1, 1000 do sum = sum + i end
    dt.profilePop()

    dt.profilePush("ai")
    local s = ""
    for i = 1, 100 do s = s .. "x" end
    dt.profilePop()

    dt.profilePop()  -- end "update"
    dt.profileFrame()

    -- Log every 120 frames
    if frame_count % 120 == 0 then
        dt.info("Frame " .. frame_count)
    end
end

function lurek.render()
    local y = 20

    lurek.gfx.setColor(1, 1, 0.6)
    lurek.gfx.print("Devtools Demo", 20, y)
    y = y + 30

    -- Frame stats
    local stats = dt.getFrameStats()
    lurek.gfx.setColor(0.7, 1, 0.7)
    lurek.gfx.print(string.format("FPS: %.1f  |  dt: %.3fms", stats.fps or 0, (stats.avg or 0) * 1000), 20, y)
    y = y + 20
    lurek.gfx.print(string.format("p50: %.3fms  p95: %.3fms  p99: %.3fms", (stats.p50 or 0) * 1000, (stats.p95 or 0) * 1000, (stats.p99 or 0) * 1000), 20, y)
    y = y + 30

    -- Profile data (most recent frame)
    lurek.gfx.setColor(0.7, 0.8, 1)
    lurek.gfx.print("Profile (last frame):", 20, y)
    y = y + 20

    local zones = dt.getProfileData()
    if zones then
        for i = 1, #zones do
            local z = zones[i]
            lurek.gfx.setColor(0.9, 0.9, 0.9)
            lurek.gfx.print(string.format("  %s: %.3fms (self: %.3fms)", z.name, z.time * 1000, z.selfTime * 1000), 20, y)
            y = y + 18
            -- Children
            if z.children then
                for j = 1, #z.children do
                    local c = z.children[j]
                    lurek.gfx.setColor(0.7, 0.7, 0.7)
                    lurek.gfx.print(string.format("    %s: %.3fms", c.name, c.time * 1000), 20, y)
                    y = y + 18
                end
            end
        end
    end
    y = y + 10

    -- Log history (last 5)
    lurek.gfx.setColor(1, 0.8, 0.6)
    lurek.gfx.print("Recent logs:", 20, y)
    y = y + 20

    local history = dt.getLogHistory(5)
    for i = 1, #history do
        local entry = history[i]
        lurek.gfx.setColor(0.8, 0.8, 0.8)
        lurek.gfx.print(string.format("[%s] %s", entry.level, entry.message), 30, y)
        y = y + 16
    end
    y = y + 20

    -- Eval demo
    lurek.gfx.setColor(0.6, 1, 0.9)
    local ok, result = dt.eval("return 2 + 2")
    lurek.gfx.print(string.format("eval('return 2+2') = %s (ok=%s)", tostring(result), tostring(ok)), 20, y)
    y = y + 20

    lurek.gfx.setColor(0.5, 0.5, 0.5)
    lurek.gfx.print("Press ESC to quit", 20, y)
end

function lurek.keypressed(key)
    if key == "escape" then
        lurek.signal.quit()
    end
end
