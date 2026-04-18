-- CORRECT
lurek.gfx.rectangle("fill", x, y, w, h)
lurek.gfx.rectangle("line", x, y, w, h)

-- WRONG
lurek.gfx.rectangle(true, x, y, w, h)   -- boolean does not work
