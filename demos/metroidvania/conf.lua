-- conf.lua — engine configuration for the Metroidvania demo
function luna.conf(t)
    t.window.title  = "Metroidvania"
    t.window.width  = 640
    t.window.height = 480

    -- Each room is 20×15 tiles at 16 px each = 320×240 px displayed at 2× scale.
    -- 640×480 gives the correct scaled viewport for one room at a time.
    t.performance.target_fps = 60
end
