-- conf.lua — engine configuration for the Bullet Hell demo
function luna.conf(t)
    t.window.title  = "Bullet Hell"
    t.window.width  = 800
    t.window.height = 600

    -- 60 fps is the target; fast-moving bullets need a stable frame budget.
    t.performance.target_fps = 60
end
