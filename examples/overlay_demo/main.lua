-- examples/overlay_demo/main.lua
-- Demonstrates luna.graphics.newDrawLayer() for z-ordered rendering.
-- Press UP/DOWN to change selected layer's z-order.
-- Press 1/2/3 to select a rectangle.
-- Press R to reset z-orders.

local layer
local items = {}
local selected = 1

function luna.load()
    layer = luna.graphics.newDrawLayer()
    items = {
        { label = "Red",   color = {0.9, 0.2, 0.2, 0.9}, x = 100, y = 150, z = 1 },
        { label = "Green", color = {0.2, 0.8, 0.2, 0.9}, x = 200, y = 200, z = 2 },
        { label = "Blue",  color = {0.2, 0.3, 0.9, 0.9}, x = 150, y = 250, z = 3 },
    }
end

function luna.update(dt)
    -- Re-queue every frame with current z-orders
    layer:clear()
    for i, item in ipairs(items) do
        local it = item -- capture
        local sel = (i == selected)
        layer:queue(it.z, function()
            luna.graphics.setColor(it.color[1], it.color[2], it.color[3], it.color[4])
            luna.graphics.rectangle("fill", it.x, it.y, 200, 150)
            -- Draw border if selected
            if sel then
                luna.graphics.setColor(1, 1, 0, 1)
                luna.graphics.rectangle("line", it.x, it.y, 200, 150)
            end
            -- Label
            luna.graphics.setColor(1, 1, 1, 1)
            luna.graphics.print(it.label .. " (z=" .. it.z .. ")", it.x + 10, it.y + 10)
        end)
    end
end

function luna.draw()
    -- Draw title
    luna.graphics.setColor(1, 1, 1, 1)
    luna.graphics.print("DrawLayer Demo — Z-Ordered Rendering", 20, 20)
    luna.graphics.print("Press 1/2/3 to select   UP/DOWN to change z   R to reset", 20, 45)
    luna.graphics.print("Selected: " .. items[selected].label, 20, 70)
    luna.graphics.print("Queued entries: " .. layer:getCount(), 20, 95)

    -- Flush draws all callbacks sorted by z-order
    layer:flush()
end

function luna.keypressed(key)
    if key == "1" then selected = 1
    elseif key == "2" then selected = 2
    elseif key == "3" then selected = 3
    elseif key == "up" then
        items[selected].z = items[selected].z + 1
    elseif key == "down" then
        items[selected].z = items[selected].z - 1
    elseif key == "r" then
        items[1].z = 1
        items[2].z = 2
        items[3].z = 3
    elseif key == "escape" then
        luna.event.quit()
    end
end
