-- conf.lua — engine configuration for the Hotel Manager demo
function luna.conf(t)
    t.window.title  = "Hotel Manager"
    t.window.width  = 800
    t.window.height = 600
    t.performance.target_fps = 60
end
