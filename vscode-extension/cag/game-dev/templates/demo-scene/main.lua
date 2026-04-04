local scenes = {
    require("scenes.01_sprites"),
    require("scenes.02_shapes"),
    require("scenes.03_particles"),
}

local current = 1

function luna.load()
    for _, s in ipairs(scenes) do
        if s.load then s.load() end
    end
end

function luna.update(dt)
    local s = scenes[current]
    if s and s.update then s.update(dt) end
end

function luna.draw()
    luna.graphics.clear(0.08, 0.08, 0.12)
    local s = scenes[current]
    if s and s.draw then s.draw() end
    -- Scene indicator
    luna.graphics.setColor(0.6, 0.6, 0.6, 1)
    luna.graphics.print("Scene " .. current .. "/" .. #scenes .. " — Press 1-" .. #scenes .. " to switch", 10, 580)
    luna.graphics.setColor(1, 1, 1, 1)
end

function luna.keypressed(key)
    if key == "escape" then luna.event.quit() end
    local n = tonumber(key)
    if n and n >= 1 and n <= #scenes then
        current = n
    end
end
