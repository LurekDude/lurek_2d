-- conf.lua — engine configuration for the Vertical Climber demo
function luna.conf(t)
    t.window.title  = "Vertical Climber"
    t.window.width  = 400
    t.window.height = 600

    -- Narrow portrait window matches the classic vertical-climber feel.
    -- 400 px wide with horizontal wrapping keeps the gameplay centred.
    t.performance.target_fps = 60
end
