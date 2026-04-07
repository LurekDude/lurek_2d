-- conf.lua — engine configuration for the Mining demo
function luna.conf(t)
    t.window.title  = "Mining"
    t.window.width  = 800
    t.window.height = 600

    -- The world is 50×80 tiles at 16 px. The viewport scrolls vertically;
    -- 800×600 shows 50×37 tiles at a time — enough to see context above and below.
    t.performance.target_fps = 60
end
