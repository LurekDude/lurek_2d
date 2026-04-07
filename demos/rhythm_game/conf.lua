-- conf.lua — engine configuration for the Rhythm Game demo
function luna.conf(t)
    t.window.title  = "Rhythm Game"
    t.window.width  = 800
    t.window.height = 600

    -- 60 fps is critical: timing windows (Perfect < 30 ms) depend on a stable
    -- frame budget. At 30 fps each frame is 33 ms, making Perfect windows impossible.
    t.performance.target_fps = 60
end
