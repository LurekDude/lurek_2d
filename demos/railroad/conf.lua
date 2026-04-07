-- conf.lua — engine configuration for the Railroad demo
function luna.conf(t)
    t.window.title  = "Railroad"
    t.window.width  = 800
    t.window.height = 608

    -- Grid is 25×19 cells of 32 px each = 800×608; the header bar sits in the
    -- top margin provided by the 8 extra pixels above the first row.
    t.performance.target_fps = 60
end
