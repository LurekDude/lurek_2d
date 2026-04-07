-- conf.lua — engine configuration for docs_demo
function luna.conf(t)
    t.window.title  = "Docs API Demo"
    t.window.width  = 800
    t.window.height = 600
    t.performance.target_fps = 60
    t.modules.debug = true
end
