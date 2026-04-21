-- BAD: O(N) draw calls — one per sprite
for _, e in ipairs(entities) do
    lurek.render.draw(e.image, e.x, e.y)   -- 1 draw call each
end

-- GOOD: 1 draw call for all sprites using the same texture
local batch = lurek.render.newSpriteBatch(atlas_image, 1000)
function lurek.process(dt)
    batch:clear()
    for _, e in ipairs(entities) do
        batch:add(e.quad, e.x, e.y)
    end
end
function lurek.render()
    lurek.render.draw(batch, 0, 0)  -- 1 draw call
end
