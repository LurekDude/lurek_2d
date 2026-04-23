-- Cooking Sim — Lurek2D
-- Category: simulation
-- A kitchen cooking simulation with recipes, customers, and day management.

------------------------------------------------------------
-- Constants
------------------------------------------------------------
local SCREEN_W = 800
local SCREEN_H = 600

local STATES = { TITLE = "TITLE", PLAYING = "PLAYING", DAY_END = "DAY_END", GAME_OVER = "GAME_OVER" }
local state = STATES.TITLE

local STATION_NAMES = { "Prep Station", "Stove", "Oven", "Serving Counter" }
local STATION_COLORS = {
    { 0.3, 0.6, 0.3 },
    { 0.7, 0.3, 0.2 },
    { 0.6, 0.4, 0.1 },
    { 0.2, 0.4, 0.7 },
}
local STATION_W = 160
local STATION_H = 120
local STATION_Y = 280
local STATION_GAP = 20
local STATION_START_X = (SCREEN_W - (4 * STATION_W + 3 * STATION_GAP)) / 2

local INGREDIENTS = { "tomato", "cheese", "bread", "meat", "lettuce" }

local RECIPES = {
    { name = "Sandwich", ingredients = { "bread", "meat", "lettuce" },   station = "Prep Station", cook_station = nil,              price = 15 },
    { name = "Pizza",    ingredients = { "bread", "cheese", "tomato" },  station = "Prep Station", cook_station = "Oven",           price = 25 },
    { name = "Burger",   ingredients = { "bread", "meat", "cheese" },    station = "Prep Station", cook_station = "Stove",          price = 20 },
    { name = "Salad",    ingredients = { "tomato", "lettuce", "cheese" },station = "Prep Station", cook_station = nil,              price = 10 },
}

local COOK_TIME_STOVE = 5.0
local COOK_TIME_OVEN  = 8.0
local BURN_EXTRA      = 3.0
local CUSTOMER_PATIENCE = 30.0
local DAY_LENGTH      = 120.0
local INGREDIENT_PACK_COST = 5

------------------------------------------------------------
-- Game State
------------------------------------------------------------
local current_station = 1
local inventory = {}
local selected_ingredient = 1
local placed_ingredients = {}
local cooking = { active = false, timer = 0, max_time = 0, station_name = "", dish_name = "" }
local cooked_dish = nil

local customers = {}
local gold = 0
local day = 1
local day_timer = 0
local day_earnings = 0
local satisfaction = 100

local particles = {}
local tweens_list = {}

local title_blink = 0
local gold_display = 0

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function reset_inventory()
    inventory = {}
    for _, name in ipairs(INGREDIENTS) do
        inventory[name] = 5
    end
end

local function spawn_customer()
    local recipe = RECIPES[math.random(1, #RECIPES)]
    return { dish = recipe.name, patience = CUSTOMER_PATIENCE, max_patience = CUSTOMER_PATIENCE }
end

local function fill_customer_queue()
    customers = {}
    for i = 1, 3 do
        customers[i] = spawn_customer()
    end
end

local function station_x(index)
    return STATION_START_X + (index - 1) * (STATION_W + STATION_GAP)
end

local function add_particle(x, y, kind)
    local count = 6
    if kind == "steam" then count = 8 end
    if kind == "smoke" then count = 10 end
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local speed = 20 + math.random() * 40
        local life = 0.6 + math.random() * 0.8
        local r, g, b = 1, 1, 1
        if kind == "steam" then r, g, b = 0.8, 0.85, 0.9 end
        if kind == "smoke" then r, g, b = 0.3, 0.3, 0.3 end
        if kind == "sparkle" then r, g, b = 1.0, 0.9, 0.3 end
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 30,
            life = life, max_life = life,
            r = r, g = g, b = b,
            size = 3 + math.random() * 3,
        })
    end
end

local function add_tween(target, field, from, to, duration)
    table.insert(tweens_list, { target = target, field = field, from = from, to = to, duration = duration, elapsed = 0 })
end

local function ingredients_match(placed, recipe_ingredients)
    if #placed ~= #recipe_ingredients then return false end
    local copy = {}
    for _, v in ipairs(recipe_ingredients) do copy[v] = (copy[v] or 0) + 1 end
    for _, v in ipairs(placed) do
        if not copy[v] or copy[v] <= 0 then return false end
        copy[v] = copy[v] - 1
    end
    return true
end

local function find_matching_recipe()
    for _, recipe in ipairs(RECIPES) do
        if ingredients_match(placed_ingredients, recipe.ingredients) then
            return recipe
        end
    end
    return nil
end

local function start_day()
    state = STATES.PLAYING
    day_timer = DAY_LENGTH
    day_earnings = 0
    placed_ingredients = {}
    cooking = { active = false, timer = 0, max_time = 0, station_name = "", dish_name = "" }
    cooked_dish = nil
    current_station = 1
    fill_customer_queue()
end

local function end_day()
    state = STATES.DAY_END
end

------------------------------------------------------------
-- Input Bindings
------------------------------------------------------------
lurek.input.bind("left", "left")
lurek.input.bind("right", "right")
lurek.input.bind("up", "up")
lurek.input.bind("down", "down")
lurek.input.bind("space", "action")
lurek.input.bind("return", "place")
lurek.input.bind("escape", "quit")

------------------------------------------------------------
-- Callbacks
------------------------------------------------------------

function lurek.init()
    lurek.window.setTitle("Cooking Sim — Lurek2D")
    lurek.render.setBackgroundColor(0.15, 0.1, 0.05)
    lurek.camera.setPosition(0, 0)
    reset_inventory()
    fill_customer_queue()
end

local function _ready_setup()
    gold = 0
    day = 1
    satisfaction = 100
    gold_display = 0
end

------------------------------------------------------------
-- Process
------------------------------------------------------------
function lurek.process(dt)
    local fps = lurek.timer.getFPS()
    lurek.window.setTitle(string.format("Cooking Sim — Day %d | Gold: %d | FPS: %d", day, gold, fps))

    -- Update particles
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end

    -- Update tweens
    local j = 1
    while j <= #tweens_list do
        local tw = tweens_list[j]
        tw.elapsed = tw.elapsed + dt
        local t = math.min(tw.elapsed / tw.duration, 1.0)
        -- ease out quad
        local eased = 1 - (1 - t) * (1 - t)
        tw.target[tw.field] = tw.from + (tw.to - tw.from) * eased
        if t >= 1.0 then
            tw.target[tw.field] = tw.to
            table.remove(tweens_list, j)
        else
            j = j + 1
        end
    end

    if state == STATES.TITLE then
        title_blink = title_blink + dt
        if lurek.input.wasActionPressed("action") then
            start_day()
        end
        if lurek.input.wasActionPressed("quit") then
            lurek.event.quit()
        end
        return
    end

    if state == STATES.DAY_END then
        if lurek.input.wasActionPressed("action") then
            -- Buy ingredients
            if gold >= INGREDIENT_PACK_COST then
                gold = gold - INGREDIENT_PACK_COST
                for _, name in ipairs(INGREDIENTS) do
                    inventory[name] = inventory[name] + 2
                end
            end
        end
        if lurek.input.wasActionPressed("place") then
            day = day + 1
            if satisfaction <= 0 then
                state = STATES.GAME_OVER
            else
                start_day()
            end
        end
        if lurek.input.wasActionPressed("quit") then
            lurek.event.quit()
        end
        return
    end

    if state == STATES.GAME_OVER then
        if lurek.input.wasActionPressed("action") or lurek.input.wasActionPressed("place") then
            gold = 0
            day = 1
            satisfaction = 100
            gold_display = 0
            reset_inventory()
            state = STATES.TITLE
        end
        if lurek.input.wasActionPressed("quit") then
            lurek.event.quit()
        end
        return
    end

    -- PLAYING state
    day_timer = day_timer - dt
    if day_timer <= 0 then
        day_timer = 0
        end_day()
        return
    end

    -- Station navigation
    if lurek.input.wasActionPressed("left") then
        current_station = math.max(1, current_station - 1)
    end
    if lurek.input.wasActionPressed("right") then
        current_station = math.min(4, current_station + 1)
    end

    -- Ingredient browsing
    if lurek.input.wasActionPressed("up") then
        selected_ingredient = selected_ingredient - 1
        if selected_ingredient < 1 then selected_ingredient = #INGREDIENTS end
    end
    if lurek.input.wasActionPressed("down") then
        selected_ingredient = selected_ingredient + 1
        if selected_ingredient > #INGREDIENTS then selected_ingredient = 1 end
    end

    -- Place ingredient at Prep Station
    if lurek.input.wasActionPressed("place") and current_station == 1 then
        local ingr = INGREDIENTS[selected_ingredient]
        if inventory[ingr] and inventory[ingr] > 0 and #placed_ingredients < 3 then
            inventory[ingr] = inventory[ingr] - 1
            table.insert(placed_ingredients, ingr)
            local sx = station_x(1) + STATION_W / 2
            add_particle(sx, STATION_Y + STATION_H / 2, "sparkle")
        end
    end

    -- Action at stations
    if lurek.input.wasActionPressed("action") then
        local sname = STATION_NAMES[current_station]

        if sname == "Prep Station" then
            -- Try to match a recipe
            local recipe = find_matching_recipe()
            if recipe then
                if recipe.cook_station == nil then
                    -- Direct serve recipe (Sandwich, Salad)
                    cooked_dish = recipe.name
                    placed_ingredients = {}
                    local sx = station_x(1) + STATION_W / 2
                    add_particle(sx, STATION_Y + 20, "sparkle")
                elseif recipe.cook_station == "Stove" and not cooking.active then
                    cooking = { active = true, timer = 0, max_time = COOK_TIME_STOVE, station_name = "Stove", dish_name = recipe.name }
                    placed_ingredients = {}
                elseif recipe.cook_station == "Oven" and not cooking.active then
                    cooking = { active = true, timer = 0, max_time = COOK_TIME_OVEN, station_name = "Oven", dish_name = recipe.name }
                    placed_ingredients = {}
                end
            end

        elseif sname == "Stove" or sname == "Oven" then
            -- Collect cooked dish
            if cooking.active and cooking.station_name == sname and cooking.timer >= cooking.max_time then
                if cooking.timer >= cooking.max_time + BURN_EXTRA then
                    cooked_dish = "Burned"
                    add_particle(station_x(current_station) + STATION_W / 2, STATION_Y + 20, "smoke")
                else
                    cooked_dish = cooking.dish_name
                    add_particle(station_x(current_station) + STATION_W / 2, STATION_Y + 20, "sparkle")
                end
                cooking = { active = false, timer = 0, max_time = 0, station_name = "", dish_name = "" }
            end

        elseif sname == "Serving Counter" then
            -- Serve dish to first customer
            if cooked_dish and #customers > 0 then
                local cust = customers[1]
                local sx = station_x(4) + STATION_W / 2
                if cooked_dish == "Burned" then
                    satisfaction = satisfaction - 10
                    add_particle(sx, STATION_Y + 20, "smoke")
                elseif cooked_dish == cust.dish then
                    local earned = 0
                    for _, r in ipairs(RECIPES) do
                        if r.name == cooked_dish then earned = r.price break end
                    end
                    gold = gold + earned
                    day_earnings = day_earnings + earned
                    add_tween({ value = gold_display }, "value", gold_display, gold, 0.5)
                    satisfaction = math.min(100, satisfaction + 5)
                    add_particle(sx, STATION_Y + 20, "sparkle")
                else
                    satisfaction = satisfaction - 5
                    add_particle(sx, STATION_Y + 20, "smoke")
                end
                table.remove(customers, 1)
                table.insert(customers, spawn_customer())
                cooked_dish = nil
            end
        end
    end

    -- Update cooking timer
    if cooking.active then
        cooking.timer = cooking.timer + dt
        local cook_idx = cooking.station_name == "Stove" and 2 or 3
        local sx = station_x(cook_idx) + STATION_W / 2
        if math.random() < 0.3 then
            add_particle(sx, STATION_Y + 10, "steam")
        end
    end

    -- Update customer patience
    for ci = 1, #customers do
        customers[ci].patience = customers[ci].patience - dt
        if customers[ci].patience <= 0 then
            satisfaction = satisfaction - 15
            customers[ci] = spawn_customer()
        end
    end

    if satisfaction <= 0 then
        satisfaction = 0
        end_day()
    end

    -- Tween gold display
    gold_display = gold_display + (gold - gold_display) * dt * 4
end

------------------------------------------------------------
-- Render — kitchen scene
------------------------------------------------------------
function lurek.draw()
    if state ~= STATES.PLAYING then return end

    -- Draw stations
    for i = 1, 4 do
        local sx = station_x(i)
        local c = STATION_COLORS[i]
        local alpha = (i == current_station) and 1.0 or 0.5

        lurek.render.rectangle(sx, STATION_Y, STATION_W, STATION_H, c[1], c[2], c[3], alpha)
        lurek.render.rectangleLines(sx, STATION_Y, STATION_W, STATION_H, 1, 1, 1, alpha, 2)
        lurek.render.print(STATION_NAMES[i], sx + 8, STATION_Y + 8, 14, 1, 1, 1, alpha)

        -- Selection arrow
        if i == current_station then
            lurek.render.print("v", sx + STATION_W / 2 - 4, STATION_Y - 24, 20, 1, 1, 0.3, 1)
        end
    end

    -- Draw placed ingredients on Prep Station
    if #placed_ingredients > 0 then
        for pi, ingr in ipairs(placed_ingredients) do
            local px = station_x(1) + 10 + (pi - 1) * 50
            lurek.render.rectangle(px, STATION_Y + 50, 44, 20, 0.9, 0.8, 0.5, 0.9)
            lurek.render.print(ingr, px + 2, STATION_Y + 53, 11, 0.1, 0.1, 0.1, 1)
        end
    end

    -- Draw cooking progress
    if cooking.active then
        local cook_idx = cooking.station_name == "Stove" and 2 or 3
        local sx = station_x(cook_idx)
        local progress = math.min(cooking.timer / cooking.max_time, 1.0)
        local bar_w = STATION_W - 16
        local burned = cooking.timer >= cooking.max_time + BURN_EXTRA

        lurek.render.rectangle(sx + 8, STATION_Y + STATION_H - 30, bar_w, 12, 0.2, 0.2, 0.2, 1)
        local br, bg = 0.2, 0.8
        if burned then br, bg = 0.9, 0.1 end
        lurek.render.rectangle(sx + 8, STATION_Y + STATION_H - 30, bar_w * math.min(progress, 1.0), 12, br, bg, 0.2, 1)
        lurek.render.print(cooking.dish_name, sx + 8, STATION_Y + 40, 12, 1, 1, 1, 1)
        if progress >= 1.0 and not burned then
            lurek.render.print("READY!", sx + 8, STATION_Y + 56, 13, 0.2, 1, 0.2, 1)
        elseif burned then
            lurek.render.print("BURNED!", sx + 8, STATION_Y + 56, 13, 1, 0.2, 0.2, 1)
        end
    end

    -- Draw cooked dish indicator at serving counter
    if cooked_dish then
        local sx = station_x(4)
        local color_r = cooked_dish == "Burned" and 0.5 or 0.2
        local color_g = cooked_dish == "Burned" and 0.2 or 0.7
        lurek.render.rectangle(sx + 20, STATION_Y + 45, STATION_W - 40, 28, color_r, color_g, 0.2, 0.9)
        lurek.render.print(cooked_dish, sx + 30, STATION_Y + 49, 13, 1, 1, 1, 1)
    end

    -- Draw particles
    for _, p in ipairs(particles) do
        local alpha = p.life / p.max_life
        lurek.render.rectangle(p.x - p.size / 2, p.y - p.size / 2, p.size, p.size, p.r, p.g, p.b, alpha * 0.8)
    end
end

------------------------------------------------------------
-- Render UI — HUD, orders, inventory, overlays
------------------------------------------------------------
function lurek.draw_ui()
    if state == STATES.TITLE then
        local alpha = 0.7 + 0.3 * math.sin(title_blink * 3)
        lurek.render.print("COOKING SIM", SCREEN_W / 2 - 100, 160, 36, 1, 0.85, 0.3, 1)
        lurek.render.print("SERVE DELICIOUS FOOD", SCREEN_W / 2 - 120, 210, 18, 0.9, 0.8, 0.6, 0.9)
        lurek.render.print("Press SPACE to start", SCREEN_W / 2 - 90, 320, 16, 1, 1, 1, alpha)
        lurek.render.print("Arrow keys: navigate | Enter: place | Space: action", SCREEN_W / 2 - 200, 370, 13, 0.6, 0.6, 0.6, 0.8)
        return
    end

    if state == STATES.GAME_OVER then
        lurek.render.print("GAME OVER", SCREEN_W / 2 - 80, 180, 32, 1, 0.3, 0.3, 1)
        lurek.render.print(string.format("Total Gold Earned: %d", gold), SCREEN_W / 2 - 100, 240, 18, 1, 0.9, 0.4, 1)
        lurek.render.print(string.format("Days Survived: %d", day), SCREEN_W / 2 - 80, 270, 16, 0.8, 0.8, 0.8, 1)
        lurek.render.print("Press SPACE to restart", SCREEN_W / 2 - 100, 340, 16, 1, 1, 1, 0.8)
        return
    end

    if state == STATES.DAY_END then
        lurek.render.print(string.format("Day %d Complete!", day), SCREEN_W / 2 - 90, 150, 28, 1, 0.9, 0.4, 1)
        lurek.render.print(string.format("Earnings: %d gold", day_earnings), SCREEN_W / 2 - 80, 200, 18, 0.9, 0.85, 0.5, 1)
        lurek.render.print(string.format("Total Gold: %d", gold), SCREEN_W / 2 - 70, 230, 16, 0.8, 0.8, 0.8, 1)
        lurek.render.print(string.format("Satisfaction: %d%%", satisfaction), SCREEN_W / 2 - 70, 260, 16, 0.7, 0.9, 0.7, 1)
        lurek.render.print(string.format("Press SPACE to buy ingredients (%d gold)", INGREDIENT_PACK_COST), SCREEN_W / 2 - 170, 320, 14, 0.6, 0.8, 1, 0.9)
        lurek.render.print("Press ENTER to start next day", SCREEN_W / 2 - 120, 350, 14, 1, 1, 1, 0.8)
        return
    end

    -- HUD top bar
    lurek.render.rectangle(0, 0, SCREEN_W, 40, 0.1, 0.08, 0.04, 0.9)
    lurek.render.print(string.format("Day %d", day), 16, 10, 18, 1, 0.9, 0.5, 1)
    lurek.render.print(string.format("Gold: %d", math.floor(gold_display + 0.5)), 140, 10, 18, 1, 0.85, 0.2, 1)
    lurek.render.print(string.format("Satisfaction: %d%%", satisfaction), 320, 10, 16, 0.6, 0.9, 0.6, 1)

    -- Day timer bar
    local timer_frac = day_timer / DAY_LENGTH
    lurek.render.rectangle(520, 12, 200, 16, 0.2, 0.2, 0.2, 0.8)
    lurek.render.rectangle(520, 12, 200 * timer_frac, 16, 0.3, 0.7, 0.9, 0.9)
    lurek.render.print(string.format("%.0fs", day_timer), 730, 12, 14, 0.8, 0.8, 0.8, 1)

    -- Customer orders panel
    lurek.render.rectangle(10, 440, 500, 150, 0.12, 0.1, 0.08, 0.85)
    lurek.render.print("ORDERS", 20, 448, 16, 1, 0.8, 0.4, 1)
    for ci = 1, #customers do
        local cust = customers[ci]
        local cy = 470 + (ci - 1) * 38
        lurek.render.print(string.format("#%d: %s", ci, cust.dish), 20, cy, 14, 1, 1, 1, 0.9)
        -- Patience bar
        local pat_frac = cust.patience / cust.max_patience
        local pr = pat_frac < 0.3 and 1.0 or 0.3
        local pg = pat_frac < 0.3 and 0.3 or 0.8
        lurek.render.rectangle(160, cy + 2, 120, 10, 0.2, 0.2, 0.2, 0.7)
        lurek.render.rectangle(160, cy + 2, 120 * pat_frac, 10, pr, pg, 0.2, 0.9)
        lurek.render.print(string.format("%.0fs", cust.patience), 290, cy, 12, 0.7, 0.7, 0.7, 0.8)
    end

    -- Inventory panel
    lurek.render.rectangle(540, 440, 250, 150, 0.12, 0.1, 0.08, 0.85)
    lurek.render.print("INVENTORY", 550, 448, 16, 1, 0.8, 0.4, 1)
    for ii, name in ipairs(INGREDIENTS) do
        local iy = 470 + (ii - 1) * 24
        local sel = (ii == selected_ingredient)
        local prefix = sel and "> " or "  "
        local alpha = sel and 1.0 or 0.6
        local count = inventory[name] or 0
        lurek.render.print(string.format("%s%s: %d", prefix, name, count), 555, iy, 14, 0.9, 0.9, 0.8, alpha)
    end

    -- Current action hint
    local hint = ""
    local sname = STATION_NAMES[current_station]
    if sname == "Prep Station" then
        if #placed_ingredients < 3 then
            hint = "Up/Down: select ingredient | Enter: place | Space: prep recipe"
        else
            hint = "Space: prep recipe"
        end
    elseif sname == "Stove" or sname == "Oven" then
        if cooking.active and cooking.station_name == sname then
            hint = "Space: collect dish when ready"
        else
            hint = "Prep ingredients first at Prep Station"
        end
    elseif sname == "Serving Counter" then
        if cooked_dish then
            hint = "Space: serve " .. cooked_dish .. " to customer"
        else
            hint = "No dish ready to serve"
        end
    end
    lurek.render.print(hint, 16, SCREEN_H - 24, 12, 0.6, 0.6, 0.6, 0.8)
end
