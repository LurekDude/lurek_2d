-- Lua usage:
local c = lurek.render.newCanvas(512, 512)
lurek.render.setCanvas(c)
-- ... draw calls render to canvas texture ...
lurek.render.setCanvas()               -- back to screen
lurek.render.draw(c, 0, 0)
