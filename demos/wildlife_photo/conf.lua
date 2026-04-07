-- conf.lua — engine configuration for the Wildlife Photography demo
function luna.conf(t)
    t.window.title  = "Wildlife Photography"
    t.window.width  = 800
    t.window.height = 600

    -- The game world is 1600×1200; the 800×600 viewport scrolls over it.
    -- Standard size gives comfortable peripheral vision while panning.
    t.performance.target_fps = 60
end
