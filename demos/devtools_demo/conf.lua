-- conf.lua — engine configuration for devtools_demo
function luna.conf(t)
    t.window.title  = "Dev Tools Demo"
    t.window.width  = 1024
    t.window.height = 768
    t.performance.target_fps = 60
end
