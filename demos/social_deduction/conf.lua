-- conf.lua — engine configuration for the Social Deduction demo
function luna.conf(t)
    t.window.title  = "Social Deduction"
    t.window.width  = 800
    t.window.height = 600
    t.performance.target_fps = 60
end
