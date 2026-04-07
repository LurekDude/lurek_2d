-- conf.lua — engine configuration for the Maze Defense demo
function luna.conf(t)
    t.window.title  = "Maze Defense"
    t.window.width  = 800
    t.window.height = 610

    -- Grid is 20×15 cells of 38 px plus 20 px margins on each side.
    -- 610 px height keeps the gold/lives HUD below the grid.
    t.performance.target_fps = 60
end
