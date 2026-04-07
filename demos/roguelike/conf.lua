-- conf.lua — engine configuration for the Roguelike demo
function luna.conf(t)
    t.window.title  = "Roguelike"
    t.window.width  = 800
    t.window.height = 640

    -- Map is 30×24 tiles at 24 px = 720×576. The extra height accommodates
    -- the message log and HUD bar below the map.
    t.performance.target_fps = 60
end
