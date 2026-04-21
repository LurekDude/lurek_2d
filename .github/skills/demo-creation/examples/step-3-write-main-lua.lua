-- content/demos/<name>/main.lua
-- <Demo Title> — <one-sentence description of what it demonstrates>
-- Controls: <brief key list>
-- Run with: cargo run -- content/demos/<name>

-- ── state ─────────────────────────────────────────────────────
-- (module-level locals: tables, IDs, constants)

-- ── helpers ───────────────────────────────────────────────────
-- (utility functions: generators, collision, math helpers)

-- ── load ──────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("<Demo Title>")
    lurek.render.setBackgroundColor(0.08, 0.08, 0.12)
    -- resource creation, world setup, initial state
end

-- ── update ────────────────────────────────────────────────────
function lurek.process(dt)
    -- input polling, simulation step, game logic
    -- always present, even if body is empty
end

-- ── draw ──────────────────────────────────────────────────────
function lurek.render()
    -- all rendering; HUD drawn last, unaffected by camera transforms
end

-- ── keypressed ────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
    -- discrete events: jump, restart, action
end
