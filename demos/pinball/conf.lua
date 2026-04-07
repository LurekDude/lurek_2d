-- conf.lua — engine configuration for the Pinball demo
function luna.conf(t)
    t.window.title  = "Pinball"
    t.window.width  = 500
    t.window.height = 700

    -- Portrait 500×700 matches the classic tall pinball cabinet aspect ratio.
    -- The full table (bumpers, flippers, gutters) is designed for exactly this viewport.
    t.performance.target_fps = 60
end
