-- CORRECT
lurek.gfx.setColor(1.0, 0.0, 0.0, 1.0)    -- red, full opacity
lurek.gfx.setColor(0.5, 0.5, 0.5, 1.0)    -- mid-gray

-- WRONG
lurek.gfx.setColor(255, 0, 0, 255)         -- byte range, not float
