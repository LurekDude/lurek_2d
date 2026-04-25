---@diagnostic disable: undefined-global
-- BAD: O(N) draw calls — one per sprite
for _, e in ipairs(entities) do
    lurek.render.draw(e.image)   -- 1 draw call each
end

-- GOOD: 1 draw call for all sprites using the same texture
local batch = lurek.render.newSpriteBatch(atlas_image, 1000)
function lurek.process(dt)
    batch:clear()
    for _, e in ipairs(entities) do
        batch:add(e.x, e.y)
    end
end
function lurek.draw()
    lurek.render.draw(batch)  -- 1 draw call
end
