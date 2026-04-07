-- conf.lua — engine configuration for the Bridge Builder demo
function luna.conf(t)
    t.window.title  = "Bridge Builder"
    t.window.width  = 800
    t.window.height = 600

    t.performance.target_fps = 60
end
