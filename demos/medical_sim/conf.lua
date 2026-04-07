-- conf.lua — engine configuration for the Medical Simulation demo
function luna.conf(t)
    t.window.title  = "Medical Simulation"
    t.window.width  = 800
    t.window.height = 600
    t.performance.target_fps = 60
end
