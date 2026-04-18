-- content/examples/timer.lua
-- Demonstrates lurek.time API: basic delta time, FPS, sleep.
-- Run with: cargo run -- content/examples/timer

-- ── load ──────────────────────────────────────────────────────
function lurek.init()
    elapsed = 0
    font = lurek.gfx.getDefaultFont()
end

-- ── update ────────────────────────────────────────────────────
function lurek.process(dt)
    elapsed = elapsed + dt
end

-- ── draw ──────────────────────────────────────────────────────
function lurek.render()
    lurek.gfx.print("FPS: " .. lurek.time.getFPS(), 10, 10)
    lurek.gfx.print("Elapsed: " .. string.format("%.2f", elapsed), 10, 30)
end
