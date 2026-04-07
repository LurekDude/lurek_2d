-- conf.lua — engine configuration for the Zoo Tycoon demo
function luna.conf(t)
    t.window.title  = "Zoo Tycoon"
    t.window.width  = 580
    t.window.height = 480

    -- Grid is 20×15 tiles at 28 px = 560×420 px, plus 10 px margins.
    -- The 50 px top area accommodates the toolbar and day/gold HUD.
    t.performance.target_fps = 60
end
