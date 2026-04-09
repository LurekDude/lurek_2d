-- Culinary / Cooking Simulation Demo
-- Pick up ingredients, chop/cook them, assemble orders for customers
-- Run with: cargo run -- content/demos/simulation/cooking_sim

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local W, H = 800, 600

-- Chef
local chef = {x = 400, y = 400, speed = 180, holding = nil, size = 20}

-- Stations
local stations = {
    {x = 50, y = 150, w = 80, h = 60, type = "shelf",  label = "Shelf"},
    {x = 200, y = 100, w = 80, h = 60, type = "chop",  label = "Chop"},
    {x = 350, y = 100, w = 80, h = 60, type = "stove", label = "Stove"},
    {x = 500, y = 100, w = 80, h = 60, type = "plate", label = "Plate"},
    {x = 650, y = 100, w = 100, h = 60, type = "serve", label = "Serve"},
}

-- Ingredients available from shelf
local INGREDIENTS = {"tomato", "meat", "bread", "cheese", "fish", "onion"}
local INGR_COLORS = {
    tomato = {1, 0.2, 0.1},
    meat   = {0.6, 0.2, 0.1},
    bread  = {0.9, 0.8, 0.4},
    cheese = {1, 0.9, 0.2},
    fish   = {0.3, 0.6, 0.9},
    onion  = {0.9, 0.8, 0.7},
}

-- Recipes: name -> required ingredients (chopped/cooked states)
local RECIPES = {
    {name = "Burger", ingredients = {"bread_raw", "meat_cooked", "cheese_raw"}, reward = 30},
    {name = "Salad",  ingredients = {"tomato_chopped", "onion_chopped"}, reward = 20},
    {name = "Fish Plate", ingredients = {"fish_cooked", "tomato_chopped"}, reward = 35},
    {name = "Toast",  ingredients = {"bread_cooked", "cheese_raw"}, reward = 15},
}

local plate = {} -- ingredients on the plate
local orders = {} -- active customer orders
local score = 0
local money = 0
local chopProgress = 0
local stoveItem = nil
local stoveTimer = 0
local COOK_TIME = 3
local BURN_TIME = 6
local orderTimer = 0
local ORDER_INTERVAL = 12
local message = ""
local msgTimer = 0
local shelfSelect = 1

local function showMsg(text)
    message = text
    msgTimer = 2
end

local function newOrder()
    local recipe = RECIPES[math.random(1, #RECIPES)]
    table.insert(orders, {
        recipe = recipe,
        timer = 30 + #recipe.ingredients * 10,
    })
end

local function inRect(px, py, s)
    return px >= s.x and px <= s.x + s.w and py >= s.y and py <= s.y + s.h
end

local function interact()
    for _, s in ipairs(stations) do
        if inRect(chef.x, chef.y, s) then
            if s.type == "shelf" and not chef.holding then
                local name = INGREDIENTS[shelfSelect]
                chef.holding = {name = name, state = "raw"}
                showMsg("Picked up " .. name)
                return
            elseif s.type == "chop" and chef.holding and chef.holding.state == "raw" then
                chopProgress = chopProgress + 0.25
                if chopProgress >= 1 then
                    chef.holding.state = "chopped"
                    chopProgress = 0
                    showMsg(chef.holding.name .. " chopped!")
                end
                return
            elseif s.type == "stove" and not stoveItem and chef.holding then
                stoveItem = chef.holding
                stoveTimer = 0
                chef.holding = nil
                showMsg("Placed " .. stoveItem.name .. " on stove")
                return
            elseif s.type == "stove" and stoveItem and not chef.holding then
                chef.holding = stoveItem
                stoveItem = nil
                stoveTimer = 0
                showMsg("Took " .. chef.holding.name .. " from stove")
                return
            elseif s.type == "plate" and chef.holding then
                table.insert(plate, chef.holding.name .. "_" .. chef.holding.state)
                showMsg("Added " .. chef.holding.name .. " (" .. chef.holding.state .. ") to plate")
                chef.holding = nil
                return
            elseif s.type == "plate" and not chef.holding and #plate > 0 then
                plate = {}
                showMsg("Cleared plate")
                return
            elseif s.type == "serve" and #plate > 0 then
                -- Order matching: plate must contain every required ingredient token
                local served = false
                for i, order in ipairs(orders) do
                    local match = true
                    local needed = {}
                    for _, ing in ipairs(order.recipe.ingredients) do
                        needed[ing] = (needed[ing] or 0) + 1
                    end
                    local have = {}
                    for _, ing in ipairs(plate) do
                        have[ing] = (have[ing] or 0) + 1
                    end
                    for k, v in pairs(needed) do
                        if not have[k] or have[k] < v then match = false; break end
                    end
                    if match then
                        money = money + order.recipe.reward
                        score = score + 1
                        showMsg("Served " .. order.recipe.name .. "! +$" .. order.recipe.reward)
                        table.remove(orders, i)
                        plate = {}
                        served = true
                        break
                    end
                end
                if not served then showMsg("No matching order!") end
                return
            end
        end
    end
end

function lurek.init()
    lurek.gfx.setBackgroundColor(0.2, 0.18, 0.15)
    newOrder()
    newOrder()
end

function lurek.process(dt)
    -- Chef movement
    local dx, dy = 0, 0
    if lurek.keyboard.isDown("w") or lurek.keyboard.isDown("up") then dy = -1 end
    if lurek.keyboard.isDown("s") or lurek.keyboard.isDown("down") then dy = 1 end
    if lurek.keyboard.isDown("a") or lurek.keyboard.isDown("left") then dx = -1 end
    if lurek.keyboard.isDown("d") or lurek.keyboard.isDown("right") then dx = 1 end
    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.707; dy = dy * 0.707
    end
    chef.x = clamp(chef.x + dx * chef.speed * dt, 20, W - 20)
    chef.y = clamp(chef.y + dy * chef.speed * dt, 80, H - 20)

    -- Stove cooking: items progress raw -> cooked -> burnt based on elapsed time
    if stoveItem then
        stoveTimer = stoveTimer + dt
        if stoveTimer >= BURN_TIME then
            stoveItem.state = "burnt"
        elseif stoveTimer >= COOK_TIME then
            stoveItem.state = "cooked"
        end
    end

    -- Order timers
    for i = #orders, 1, -1 do
        orders[i].timer = orders[i].timer - dt
        if orders[i].timer <= 0 then
            showMsg("Order expired: " .. orders[i].recipe.name)
            table.remove(orders, i)
        end
    end

    -- Spawn new orders
    orderTimer = orderTimer + dt
    if orderTimer >= ORDER_INTERVAL and #orders < 4 then
        newOrder()
        orderTimer = 0
    end

    if msgTimer > 0 then msgTimer = msgTimer - dt end
end

function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    if key == "space" then interact() end
    if key == "e" then interact() end
    -- Shelf ingredient selection
    for i = 1, #INGREDIENTS do
        if key == tostring(i) then shelfSelect = i end
    end
end

function lurek.mousepressed(mx, my, button)
    if button == 1 then interact() end
end

local function drawStation(s)
    local colors = {
        shelf = {0.5, 0.4, 0.3},
        chop  = {0.6, 0.5, 0.3},
        stove = {0.7, 0.2, 0.1},
        plate = {0.8, 0.8, 0.8},
        serve = {0.2, 0.7, 0.3},
    }
    local c = colors[s.type]
    lurek.gfx.setColor(c[1], c[2], c[3], 1)
    lurek.gfx.rectangle("fill", s.x, s.y, s.w, s.h)
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.rectangle("line", s.x, s.y, s.w, s.h)
    lurek.gfx.print(s.label, s.x + 5, s.y + s.h + 4, 0.8)
end

function lurek.render()
    -- Draw stations
    for _, s in ipairs(stations) do drawStation(s) end

    -- Shelf ingredient list
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Ingredients (1-" .. #INGREDIENTS .. "):", 10, 220, 0.8)
    for i, name in ipairs(INGREDIENTS) do
        local c = INGR_COLORS[name]
        if i == shelfSelect then
            lurek.gfx.setColor(1, 1, 0, 1)
            lurek.gfx.print("> ", 10, 240 + (i - 1) * 18, 0.8)
        end
        lurek.gfx.setColor(c[1], c[2], c[3], 1)
        lurek.gfx.print(i .. ". " .. name, 25, 240 + (i - 1) * 18, 0.8)
    end

    -- Stove item
    if stoveItem then
        local sx = stations[3].x + 10
        local sy = stations[3].y + 10
        local c = INGR_COLORS[stoveItem.name] or {1, 1, 1}
        lurek.gfx.setColor(c[1], c[2], c[3], 1)
        lurek.gfx.circle("fill", sx + 20, sy + 15, 12)
        lurek.gfx.setColor(1, 1, 1, 1)
        local pct = clamp(stoveTimer / COOK_TIME, 0, 1)
        lurek.gfx.rectangle("fill", sx, sy + 35, pct * 60, 6)
        if stoveItem.state == "burnt" then
            lurek.gfx.setColor(1, 0, 0, 1)
            lurek.gfx.print("BURNT!", sx, sy + 44, 0.7)
        elseif stoveItem.state == "cooked" then
            lurek.gfx.setColor(0, 1, 0, 1)
            lurek.gfx.print("DONE!", sx, sy + 44, 0.7)
        end
    end

    -- Chop progress
    if chopProgress > 0 then
        local cx = stations[2].x
        lurek.gfx.setColor(0, 1, 0, 1)
        lurek.gfx.rectangle("fill", cx, stations[2].y - 10, chopProgress * 80, 6)
    end

    -- Plate contents
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Plate:", stations[4].x, stations[4].y + stations[4].h + 20, 0.7)
    for i, item in ipairs(plate) do
        lurek.gfx.print("- " .. item, stations[4].x, stations[4].y + stations[4].h + 35 + (i - 1) * 14, 0.65)
    end

    -- Chef
    lurek.gfx.setColor(1, 0.9, 0.7, 1)
    lurek.gfx.circle("fill", chef.x, chef.y, chef.size)
    lurek.gfx.setColor(0.3, 0.3, 0.8, 1)
    lurek.gfx.rectangle("fill", chef.x - 12, chef.y - 5, 24, 20)
    -- Holding indicator
    if chef.holding then
        local c = INGR_COLORS[chef.holding.name] or {1, 1, 1}
        lurek.gfx.setColor(c[1], c[2], c[3], 1)
        lurek.gfx.circle("fill", chef.x, chef.y - 30, 8)
        lurek.gfx.setColor(1, 1, 1, 1)
        lurek.gfx.print(chef.holding.name .. "(" .. chef.holding.state .. ")", chef.x - 30, chef.y - 48, 0.6)
    end

    -- Orders
    lurek.gfx.setColor(0, 0, 0, 0.8)
    lurek.gfx.rectangle("fill", 0, 0, W, 70)
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("ORDERS:", 10, 5, 1)
    for i, order in ipairs(orders) do
        local ox = 10 + (i - 1) * 195
        local urgency = order.timer < 10 and {1, 0.3, 0.3} or {1, 1, 1}
        lurek.gfx.setColor(urgency[1], urgency[2], urgency[3], 1)
        lurek.gfx.print(order.recipe.name .. " ($" .. order.recipe.reward .. ")", ox, 25, 0.8)
        lurek.gfx.setColor(0.7, 0.7, 0.7, 1)
        local ingStr = table.concat(order.recipe.ingredients, ", ")
        lurek.gfx.print(ingStr, ox, 40, 0.55)
        lurek.gfx.setColor(1, 0.8, 0, 1)
        lurek.gfx.print(math.floor(order.timer) .. "s", ox + 150, 25, 0.7)
    end

    -- HUD
    lurek.gfx.setColor(0, 0, 0, 0.7)
    lurek.gfx.rectangle("fill", 0, H - 30, W, 30)
    lurek.gfx.setColor(1, 1, 1, 1)
    lurek.gfx.print("Score: " .. score .. "  Money: $" .. money .. "  |  WASD move, Space/E interact, 1-6 select ingredient", 10, H - 25, 0.8)

    -- Message
    if msgTimer > 0 then
        lurek.gfx.setColor(1, 1, 0, clamp(msgTimer, 0, 1))
        lurek.gfx.print(message, W / 2 - 80, H / 2, 1.2)
    end
end


