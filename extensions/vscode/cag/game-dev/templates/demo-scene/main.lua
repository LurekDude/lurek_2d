local scenes = {
    require("scenes.01_sprites"),
    require("scenes.02_shapes"),
    require("scenes.03_particles"),
}

local current = 1

function lurek.init()
    for _, s in ipairs(scenes) do
        if s.load then s.load() end
    end
end

function lurek.process(dt)
    local s = scenes[current]
    if s and s.update then s.update(dt) end
end

function lurek.render()
    lurek.render.clear(0.08, 0.08, 0.12)
    local s = scenes[current]
    if s and s.draw then s.draw() end
    -- Scene indicator
    lurek.render.setColor(0.6, 0.6, 0.6, 1)
    lurek.render.print("Scene " .. current .. "/" .. #scenes .. " — Press 1-" .. #scenes .. " to switch", 10, 580)
    lurek.render.setColor(1, 1, 1, 1)
end

function lurek.keypressed(key)
    if key == "escape" then lurek.event.quit() end
    local n = tonumber(key)
    if n and n >= 1 and n <= #scenes then
        current = n
    end
end
