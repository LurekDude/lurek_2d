-- conf.lua — engine configuration for the Restaurant Tycoon demo
function luna.conf(t)
    t.window.title  = "Restaurant Tycoon"
    t.window.width  = 620
    t.window.height = 530

    -- Grid is 15×12 tiles at 40 px = 600×480 px.
    -- 620×530 adds margins for the toolbar and the revenue/satisfaction HUD.
    t.performance.target_fps = 60
end
