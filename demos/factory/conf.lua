-- conf.lua — engine configuration for the Factory demo
function luna.conf(t)
    t.window.title  = "Factory Automation"
    t.window.width  = 800
    t.window.height = 576   -- 25×18 tiles at 32px each
    t.performance.target_fps = 60
end
