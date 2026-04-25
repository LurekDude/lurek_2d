-- Half-resolution bloom canvas
local w, h = lurek.window.getWidth(), lurek.window.getHeight()
local bloomCanvas = lurek.render.newCanvas(math.floor(w / 2), math.floor(h / 2))
