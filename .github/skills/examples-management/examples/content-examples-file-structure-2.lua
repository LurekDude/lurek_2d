-- content/examples/timer.lua
-- Demonstrates lurek.timer API: basic delta time, FPS, sleep.
-- Run with: cargo run -- content/examples/timer

-- ── load ──────────────────────────────────────────────────────
function lurek.init()
    elapsed = 0
    font = lurek.render.getDefaultFont()
end

-- ── update ────────────────────────────────────────────────────
function lurek.process(dt)
    elapsed = elapsed + dt
end

-- ── draw ──────────────────────────────────────────────────────
function lurek.draw()
    lurek.render.print("FPS: " .. lurek.timer.getFPS(), 10, 10)
    lurek.render.print("Elapsed: " .. string.format("%.2f", elapsed), 10, 30)
end
