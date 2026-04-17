-- Alchemy / Potion Mixing Demo
-- Drag ingredients, grind, heat, brew potions, discover recipes, sell for gold
-- Run with: cargo run -- content/demos/rpg/alchemy

local function clamp(v, mn, mx) return math.max(mn, math.min(mx, v)) end

local ingredients = {}
local mortar = { items = {}, ground = false, grinding = 0 }
local cauldron = { items = {}, temperature = 0, heating = false, result = nil }
local bottle = { potion = nil }
local recipes = {}
local discovered = {}
local gold = 50
local shop_open = false
local message = ""
local message_timer = 0
local selected_ingredient = nil
local potion_inventory = {}

local MORTAR_X, MORTAR_Y = 200, 300
local CAULDRON_X, CAULDRON_Y = 350, 300
local BOTTLE_X, BOTTLE_Y = 500, 300
local SHELF_X, SHELF_Y = 30, 80

function lurek.init()
    ingredients = {
        { name = "Sunpetal",   color = {1,0.8,0},   fire = 2, water = 0, earth = 1, air = 0, cost = 5,  owned = 5 },
        { name = "Moonmoss",   color = {0.4,0.8,1}, fire = 0, water = 2, earth = 0, air = 1, cost = 5,  owned = 5 },
        { name = "Ironite",    color = {0.6,0.6,0.6}, fire = 1, water = 0, earth = 2, air = 0, cost = 8, owned = 3 },
        { name = "Windleaf",   color = {0.7,1,0.7}, fire = 0, water = 0, earth = 1, air = 2, cost = 5,  owned = 5 },
        { name = "Emberite",   color = {1,0.3,0},   fire = 3, water = 0, earth = 0, air = 0, cost = 10, owned = 2 },
        { name = "Dewdrop",    color = {0.3,0.5,1}, fire = 0, water = 3, earth = 0, air = 0, cost = 10, owned = 2 },
        { name = "Stonebloom", color = {0.8,0.6,0.3}, fire = 0, water = 0, earth = 3, air = 0, cost = 10, owned = 2 },
        { name = "Zephyrdust", color = {0.9,0.9,1}, fire = 0, water = 0, earth = 0, air = 3, cost = 12, owned = 1 },
    }
    recipes = {
        { name = "Health Potion",   fire = {0,2}, water = {2,5}, earth = {1,3}, air = {0,2}, temp = {40,60}, color = {1,0.2,0.3}, value = 20 },
        { name = "Speed Potion",    fire = {0,1}, water = {0,2}, earth = {0,1}, air = {3,6}, temp = {30,50}, color = {0.5,1,0.8}, value = 25 },
        { name = "Strength Potion", fire = {2,4}, water = {0,1}, earth = {2,5}, air = {0,1}, temp = {50,70}, color = {1,0.6,0},   value = 25 },
        { name = "Poison",          fire = {3,6}, water = {0,1}, earth = {0,1}, air = {0,1}, temp = {70,100},color = {0.3,0.8,0},  value = 15 },
        { name = "Shield Elixir",   fire = {0,1}, water = {1,3}, earth = {3,6}, air = {0,1}, temp = {40,60}, color = {0.4,0.4,0.8}, value = 30 },
        { name = "Invisibility",    fire = {0,1}, water = {1,2}, earth = {0,1}, air = {3,6}, temp = {20,40}, color = {0.8,0.8,1},  value = 40 },
        { name = "Fire Resist",     fire = {3,6}, water = {2,4}, earth = {0,2}, air = {0,1}, temp = {60,80}, color = {1,0.5,0.2},  value = 30 },
        { name = "Frost Bomb",      fire = {0,1}, water = {4,8}, earth = {0,2}, air = {1,3}, temp = {10,30}, color = {0.2,0.6,1},  value = 35 },
        { name = "Earth Ward",      fire = {0,1}, water = {0,2}, earth = {4,8}, air = {0,1}, temp = {50,70}, color = {0.6,0.4,0.2}, value = 30 },
        { name = "Gale Tonic",      fire = {1,2}, water = {0,1}, earth = {0,1}, air = {4,8}, temp = {30,50}, color = {0.7,1,1},    value = 35 },
        { name = "Berserker Brew",  fire = {4,8}, water = {0,1}, earth = {1,3}, air = {0,1}, temp = {70,90}, color = {0.8,0,0},    value = 40 },
        { name = "Panacea",         fire = {1,3}, water = {1,3}, earth = {1,3}, air = {1,3}, temp = {45,55}, color = {1,1,0.6},    value = 60 },
    }
end

local function show_msg(txt)
    message = txt
    message_timer = 2
end

local function in_rect(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

-- Average the RGB values of all ingredients to produce a blended colour for
-- the mortar and cauldron liquids. This gives visual feedback without textures.
local function mix_color(items)
    local r, g, b, n = 0, 0, 0, #items
    if n == 0 then return {0.5, 0.5, 0.5} end
    for _, it in ipairs(items) do
        r = r + it.color[1]
        g = g + it.color[2]
        b = b + it.color[3]
    end
    return { r / n, g / n, b / n }
end

local function sum_elements(items)
    local f, w, e, a = 0, 0, 0, 0
    for _, it in ipairs(items) do
        f = f + it.fire
        w = w + it.water
        e = e + it.earth
        a = a + it.air
    end
    return f, w, e, a
end

local function in_range(v, r) return v >= r[1] and v <= r[2] end

-- Core recipe-matching function. Sums the four elemental values across all
-- cauldron ingredients and checks each recipe's range tables. First match wins.
-- Fallback results (Toxic Sludge / Murky Water / Failed Mixture) handle all non-
-- matching combinations so the player always gets feedback.
local function try_brew()
    if #cauldron.items == 0 then return end
    local f, w, e, a = sum_elements(cauldron.items)
    local t = cauldron.temperature
    for _, recipe in ipairs(recipes) do
        if in_range(f, recipe.fire) and in_range(w, recipe.water)
           and in_range(e, recipe.earth) and in_range(a, recipe.air)
           and in_range(t, recipe.temp) then
            cauldron.result = recipe
            discovered[recipe.name] = true
            show_msg("Brewed: " .. recipe.name .. "!")
            return
        end
    end
    if t > 80 then
        cauldron.result = { name = "Toxic Sludge", color = {0.3, 0.2, 0}, value = 2 }
        show_msg("Too hot! Toxic sludge...")
    elseif t < 20 then
        cauldron.result = { name = "Murky Water", color = {0.4, 0.4, 0.3}, value = 1 }
        show_msg("Too cold! Murky water...")
    else
        cauldron.result = { name = "Failed Mixture", color = mix_color(cauldron.items), value = 3 }
        show_msg("Unknown combination...")
    end
end

function lurek.process(dt)
    if message_timer > 0 then message_timer = message_timer - dt end
    if mortar.grinding > 0 then
        mortar.grinding = mortar.grinding - dt
        if mortar.grinding <= 0 then
            mortar.ground = true
            show_msg("Ingredients ground!")
        end
    end
    if cauldron.heating and #cauldron.items > 0 then
        -- temperature managed by keys
    end
end

function lurek.keypressed(key)
    if key == "up" and #cauldron.items > 0 and not cauldron.result then
        cauldron.temperature = clamp(cauldron.temperature + 5, 0, 100)
    elseif key == "down" and #cauldron.items > 0 and not cauldron.result then
        cauldron.temperature = clamp(cauldron.temperature - 5, 0, 100)
    elseif key == "b" then
        if cauldron.result and not bottle.potion then
            bottle.potion = cauldron.result
            cauldron.result = nil
            cauldron.items = {}
            cauldron.temperature = 0
            show_msg("Bottled: " .. bottle.potion.name)
        end
    elseif key == "s" then
        if bottle.potion then
            gold = gold + bottle.potion.value
            show_msg("Sold " .. bottle.potion.name .. " for " .. bottle.potion.value .. " gold!")
            bottle.potion = nil
        end
    elseif key == "space" and #cauldron.items > 0 and not cauldron.result then
        try_brew()
    elseif key == "r" then
        mortar.items = {}
        mortar.ground = false
        mortar.grinding = 0
        cauldron.items = {}
        cauldron.temperature = 0
        cauldron.result = nil
        bottle.potion = nil
        show_msg("Workbench cleared")
    elseif key == "escape" then
        lurek.signal.quit()
    end
end

function lurek.mousepressed(mx, my, btn)
    if btn == 1 then
        -- Click ingredient on shelf
        for i, ing in ipairs(ingredients) do
            local ix = SHELF_X
            local iy = SHELF_Y + (i - 1) * 30
            if in_rect(mx, my, ix, iy, 120, 24) and ing.owned > 0 then
                if #mortar.items < 3 and not mortar.ground then
                    ing.owned = ing.owned - 1
                    mortar.items[#mortar.items + 1] = ing
                    show_msg("Added " .. ing.name .. " to mortar")
                    return
                end
            end
        end
        -- Click mortar to grind
        if in_rect(mx, my, MORTAR_X - 30, MORTAR_Y - 30, 60, 60) then
            if #mortar.items > 0 and not mortar.ground and mortar.grinding <= 0 then
                mortar.grinding = 1.5
                show_msg("Grinding...")
            end
        end
        -- Click cauldron to transfer ground ingredients
        if in_rect(mx, my, CAULDRON_X - 35, CAULDRON_Y - 35, 70, 70) then
            if mortar.ground and #mortar.items > 0 then
                for _, it in ipairs(mortar.items) do
                    cauldron.items[#cauldron.items + 1] = it
                end
                mortar.items = {}
                mortar.ground = false
                show_msg("Moved to cauldron. Up/Down=heat, Space=brew")
            end
        end
        -- Click bottle to bottle result
        if in_rect(mx, my, BOTTLE_X - 15, BOTTLE_Y - 40, 30, 60) then
            if cauldron.result and not bottle.potion then
                bottle.potion = cauldron.result
                cauldron.result = nil
                cauldron.items = {}
                cauldron.temperature = 0
                show_msg("Bottled! Press S to sell")
            end
        end
    end
end

function lurek.render()
    lurek.render.setBackgroundColor(0.12, 0.1, 0.15)

    -- Title and gold
    lurek.render.setColor(1, 0.85, 0.4, 1)
    lurek.render.print("~ Alchemy Workshop ~", 220, 10, 1.3)
    lurek.render.setColor(1, 1, 0.5, 1)
    lurek.render.print("Gold: " .. gold, 620, 15, 1)

    -- Ingredient shelf
    lurek.render.setColor(0.7, 0.6, 0.4, 1)
    lurek.render.print("Ingredients:", SHELF_X, SHELF_Y - 20, 1)
    for i, ing in ipairs(ingredients) do
        local iy = SHELF_Y + (i - 1) * 30
        local c = ing.color
        lurek.render.setColor(c[1], c[2], c[3], 1)
        lurek.render.rectangle("fill", SHELF_X, iy, 14, 14)
        lurek.render.setColor(0.9, 0.9, 0.8, 1)
        lurek.render.print(ing.name .. " x" .. ing.owned, SHELF_X + 20, iy, 0.8)
    end

    -- Mortar
    lurek.render.setColor(0.5, 0.4, 0.3, 1)
    lurek.render.rectangle("fill", MORTAR_X - 30, MORTAR_Y - 20, 60, 40)
    lurek.render.setColor(0.3, 0.25, 0.2, 1)
    lurek.render.rectangle("fill", MORTAR_X - 25, MORTAR_Y - 15, 50, 30)
    lurek.render.setColor(0.9, 0.85, 0.7, 1)
    lurek.render.print("Mortar", MORTAR_X - 20, MORTAR_Y - 40, 0.8)
    if #mortar.items > 0 then
        local mc = mix_color(mortar.items)
        lurek.render.setColor(mc[1], mc[2], mc[3], 1)
        local sz = mortar.ground and 20 or 12
        lurek.render.circle("fill", MORTAR_X, MORTAR_Y, sz)
        if mortar.grinding > 0 then
            lurek.render.setColor(1, 1, 1, 0.7)
            lurek.render.print("Grinding...", MORTAR_X - 25, MORTAR_Y + 25, 0.7)
        elseif mortar.ground then
            lurek.render.setColor(0.5, 1, 0.5, 1)
            lurek.render.print("Ground!", MORTAR_X - 20, MORTAR_Y + 25, 0.7)
        end
    end

    -- Cauldron
    lurek.render.setColor(0.3, 0.3, 0.35, 1)
    lurek.render.circle("fill", CAULDRON_X, CAULDRON_Y, 38)
    lurek.render.setColor(0.15, 0.15, 0.2, 1)
    lurek.render.circle("fill", CAULDRON_X, CAULDRON_Y, 30)
    lurek.render.setColor(0.9, 0.85, 0.7, 1)
    lurek.render.print("Cauldron", CAULDRON_X - 25, CAULDRON_Y - 55, 0.8)
    if #cauldron.items > 0 then
        local cc = cauldron.result and cauldron.result.color or mix_color(cauldron.items)
        lurek.render.setColor(cc[1], cc[2], cc[3], 0.8)
        lurek.render.circle("fill", CAULDRON_X, CAULDRON_Y, 25)
    end
    -- Temperature bar
    if #cauldron.items > 0 then
        lurek.render.setColor(0.3, 0.3, 0.3, 1)
        lurek.render.rectangle("fill", CAULDRON_X - 5, CAULDRON_Y + 42, 70, 12)
        local tr = cauldron.temperature / 100
        local tg = 1 - tr
        lurek.render.setColor(tr, tg, 0.1, 1)
        lurek.render.rectangle("fill", CAULDRON_X - 5, CAULDRON_Y + 42, 70 * (cauldron.temperature / 100), 12)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print(cauldron.temperature .. "C", CAULDRON_X + 68, CAULDRON_Y + 42, 0.7)
    end

    -- Bottle
    lurek.render.setColor(0.6, 0.8, 0.9, 0.5)
    lurek.render.rectangle("fill", BOTTLE_X - 12, BOTTLE_Y - 35, 24, 50)
    lurek.render.rectangle("fill", BOTTLE_X - 5, BOTTLE_Y - 42, 10, 10)
    lurek.render.setColor(0.9, 0.85, 0.7, 1)
    lurek.render.print("Bottle", BOTTLE_X - 18, BOTTLE_Y - 58, 0.8)
    if bottle.potion then
        local pc = bottle.potion.color
        lurek.render.setColor(pc[1], pc[2], pc[3], 0.9)
        lurek.render.rectangle("fill", BOTTLE_X - 10, BOTTLE_Y - 20, 20, 30)
        lurek.render.setColor(1, 1, 1, 1)
        lurek.render.print(bottle.potion.name, BOTTLE_X - 40, BOTTLE_Y + 20, 0.7)
    end

    -- Recipe book
    lurek.render.setColor(0.8, 0.7, 0.5, 1)
    lurek.render.print("Recipes:", 600, 80, 1)
    for i, recipe in ipairs(recipes) do
        local ry = 105 + (i - 1) * 22
        if discovered[recipe.name] then
            local rc = recipe.color
            lurek.render.setColor(rc[1], rc[2], rc[3], 1)
            lurek.render.rectangle("fill", 600, ry + 2, 10, 10)
            lurek.render.setColor(0.9, 0.9, 0.8, 1)
            lurek.render.print(recipe.name .. " (" .. recipe.value .. "g)", 615, ry, 0.7)
        else
            lurek.render.setColor(0.4, 0.4, 0.4, 1)
            lurek.render.print("???", 615, ry, 0.7)
        end
    end

    -- Controls
    lurek.render.setColor(0.6, 0.6, 0.5, 1)
    lurek.render.print("Click shelf=add | Click mortar=grind | Click cauldron=transfer", 30, 420, 0.65)
    lurek.render.print("Up/Down=heat | Space=brew | B=bottle | S=sell | R=reset | Esc=quit", 30, 438, 0.65)

    -- Message
    if message_timer > 0 then
        lurek.render.setColor(1, 1, 0.7, message_timer)
        lurek.render.print(message, 200, 460, 1)
    end

    lurek.render.setColor(0.5, 0.5, 0.5, 1)
    lurek.render.print("FPS: " .. lurek.time.getFPS(), 5, 5, 0.6)
end
