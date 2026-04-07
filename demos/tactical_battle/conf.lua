-- conf.lua — engine configuration for the Tactical Battle demo
function luna.conf(t)
    t.window.title  = "Tactical Battle"
    t.window.width  = 800
    t.window.height = 680

    -- Grid is 8×8 tiles at 64 px with 80px left/right and 60px top margins.
    -- Total grid area: 512×512. Extra height allows a combat-log panel below.
    t.performance.target_fps = 60
end
