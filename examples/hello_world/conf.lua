-- conf.lua — engine configuration loaded before luna.load()
-- All fields are optional; shown values are the defaults.
function luna.conf(t)
    t.window.title  = "Hello World"
    t.window.width  = 800
    t.window.height = 600

    -- performance.target_fps: frame rate cap (frames per second).
    -- Lower values reduce CPU/GPU usage at idle.
    -- Use 0 for unlimited (vsync still applies when enabled).
    t.performance.target_fps = 60
end
