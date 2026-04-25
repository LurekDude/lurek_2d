---@diagnostic disable: undefined-global, param-type-mismatch
-- CORRECT
lurek.render.rectangle("fill", x, y, w, h)
lurek.render.rectangle("line", x, y, w, h)

-- WRONG
lurek.render.rectangle(true, x, y, w, h)   -- boolean does not work
