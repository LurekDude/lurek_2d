-- conf.lua — engine configuration for the Adventure demo
function luna.conf(t)
    t.window.title  = "Point-and-Click Adventure"
    t.window.width  = 800
    t.window.height = 600

    -- Target 60 fps; the demo is input-driven so a high cap adds no benefit.
    t.performance.target_fps = 60
end
