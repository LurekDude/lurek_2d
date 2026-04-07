-- conf.lua — engine configuration for the Survival Crafting demo
function luna.conf(t)
    t.window.title  = "Survival Crafting"
    t.window.width  = 800
    t.window.height = 576

    -- Grid is 25×18 tiles at 32 px = 800×576.
    -- The HUD sits above the grid in the remaining window area.
    t.performance.target_fps = 60
end
