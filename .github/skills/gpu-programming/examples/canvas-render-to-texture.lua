-- Lua usage:
local c = lurek.gfx.newCanvas(512, 512)
lurek.gfx.setCanvas(c)
-- ... draw calls render to canvas texture ...
lurek.gfx.setCanvas()               -- back to screen
lurek.gfx.draw(c, 0, 0)
