-- ============================================================================
-- Alchemy Lab — Lurek2D
-- Category: rpg
-- A potion crafting simulation with elemental ingredients, temperature
-- mechanics, recipe discovery, and a shop system.
--
-- Controls:
--   1-6     — Select / add ingredient
--   G       — Grind ingredients in mortar
--   H       — Heat cauldron
--   J       — Cool cauldron
--   B       — Bottle the brew
--   S       — Toggle shop
--   Enter   — Start / confirm
--   Escape  — Quit
-- ============================================================================

-- ── State ───────────────────────────────────────────────────────────────────

local STATE_TITLE     = 1
local STATE_CRAFTING  = 2
local STATE_SHOP      = 3
local STATE_DISCOVERY = 4

local state = STATE_TITLE
local dt    = 0

-- ── Ingredients ─────────────────────────────────────────────────────────────

local ingredients = {
local _cam = lurek.camera.new()  -- injected by fix_games.py
    { name = "Sunpetal",    fire = 2, water = 0, earth = 1, air = 0, cost = 8,  color = {1.0, 0.8, 0.2} },
    { name = "Moonmoss",    fire = 0, water = 2, earth = 0, air = 1, cost = 8,  color = {0.5, 0.7, 1.0} },
    { name = "Ironite",     fire = 1, water = 0, earth = 2, air = 0, cost = 10, color = {0.6, 0.5, 0.4} },
    { name = "Windleaf",    fire = 0, water = 0, earth = 1, air = 2, cost = 8,  color = {0.6, 1.0, 0.7} },
    { name = "Blazeroot",   fire = 3, water = 0, earth = 0, air = 0, cost = 15, color = {1.0, 0.3, 0.1} },
    { name = "Crystaldew",  fire = 0, water = 3, earth = 0, air = 0, cost = 15, color = {0.3, 0.6, 1.0} },
}

-- ── Recipes ─────────────────────────────────────────────────────────────────

local recipes = {
    { name = "Healing Potion",     check = function(e) return e.water >= 4 end,                                          color = {0.2, 0.9, 0.3}, value = 30 },
    { name = "Fire Resist Potion", check = function(e) return e.fire >= 4 end,                                           color = {0.9, 0.2, 0.1}, value = 25 },
    { name = "Speed Potion",       check = function(e) return e.air >= 3 end,                                            color = {1.0, 0.9, 0.2}, value = 35 },
    { name = "Shield Potion",      check = function(e) return e.earth >= 4 end,                                          color = {0.6, 0.4, 0.2}, value = 20 },
    { name = "Philosopher's Stone",check = function(e) return e.fire >= 2 and e.water >= 2 and e.earth >= 2 and e.air >= 2 end, color = {1.0, 0.85, 0.0}, value = 100 },
}

-- ── Player / workbench state ────────────────────────────────────────────────

local gold       = 50
local stock      = { 3, 3, 2, 3, 1, 1 }   -- starting ingredient counts
local inventory  = {}                       -- brewed potions
local discovered = {}                       -- recipe names discovered

local mortar     = {}   -- ingredients in mortar (list of indices)
local ground     = {}   -- ground result: {fire,water,earth,air} or nil
local cauldron   = nil  -- elemental totals in cauldron or nil
local temperature = 50  -- 0-100 gauge
local brewing_done = false

local grind_timer    = 0
local grind_duration = 1.0
local is_grinding    = false

local message      = ""
local message_timer = 0

local discovery_name  = ""
local discovery_timer = 0
local discovery_color = {1,1,1}

local title_blink = 0

local shop_scroll = 0

-- ── Particles ───────────────────────────────────────────────────────────────

local particles = {}

local function spawn_particles(x, y, count, r, g, b, life, speed)
    for i = 1, count do
        local angle = math.random() * math.pi * 2
        local spd   = (math.random() * 0.5 + 0.5) * (speed or 60)
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * spd,
            vy = math.sin(angle) * spd,
            life = life or 1.0,
            max_life = life or 1.0,
            r = r, g = g, b = b,
        })
    end
end

local function update_particles(delta)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * delta
        p.y = p.y + p.vy * delta
        p.vy = p.vy + 30 * delta
        p.life = p.life - delta
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function draw_particles()
    for _, p in ipairs(particles) do
        local a = p.life / p.max_life
        local sz = 3 + 4 * a
        lurek.render.setColor(p.r, p.g, p.b, a)
        lurek.render.rectangle("fill", p.x - sz/2, p.y - sz/2, sz, sz)
    end
end

-- ── Tween helpers ───────────────────────────────────────────────────────────

local tweens = {}

local function tween_to(target, key, goal, dur)
    table.insert(tweens, { target = target, key = key, start = target[key], goal = goal, dur = dur, t = 0 })
end

local function update_tweens(delta)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.t = tw.t + delta
        local frac = math.min(tw.t / tw.dur, 1)
        -- ease out quad
        local e = 1 - (1 - frac) * (1 - frac)
        tw.target[tw.key] = tw.start + (tw.goal - tw.start) * e
        if frac >= 1 then
            tw.target[tw.key] = tw.goal
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end
end

-- ── Tween-animated values ───────────────────────────────────────────────────

local anim = {
    temp_display = 50,
    grind_bar    = 0,
    disc_scale   = 0,
}

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function set_message(msg, dur)
    message = msg
    message_timer = dur or 2.0
end

local function total_elements()
    local e = { fire = 0, water = 0, earth = 0, air = 0 }
    if cauldron then
        e.fire  = cauldron.fire
        e.water = cauldron.water
        e.earth = cauldron.earth
        e.air   = cauldron.air
    end
    return e
end

local function clear_workbench()
    mortar = {}
    ground = nil
    cauldron = nil
    temperature = 50
    anim.temp_display = 50
    brewing_done = false
    is_grinding = false
    grind_timer = 0
    anim.grind_bar = 0
end

local function try_brew()
    if not cauldron then return nil end
    if temperature < 40 then return "weak" end
    if temperature > 85 then return "explode" end
    local e = total_elements()
    -- check recipes in reverse priority (philosopher's stone first if matched)
    for i = #recipes, 1, -1 do
        if recipes[i].check(e) then
            return recipes[i]
        end
    end
    return "failed"
end

-- ── Callbacks ───────────────────────────────────────────────────────────────

function lurek.init()
    lurek.window.setTitle("Alchemy Lab — Lurek2D")
    lurek.render.setBackgroundColor(0.12, 0.08, 0.06)
    _cam:reset()
end

local function _ready_setup()
    set_message("Welcome to the Alchemy Lab!", 3)
end

-- ── Process ─────────────────────────────────────────────────────────────────

function lurek.process(delta)
    dt = delta
    title_blink = title_blink + delta

    update_particles(delta)
    update_tweens(delta)

    if message_timer > 0 then
        message_timer = message_timer - delta
    end

    -- ── Title ───────────────────────────────────────────────────────────
    if state == STATE_TITLE then
        if lurek.input.wasActionPressed("enter") then
            state = STATE_CRAFTING
            set_message("Select ingredients with 1-6", 3)
        end
        if lurek.input.wasActionPressed("escape") then
            lurek.event.quit()
        end
        return
    end

    -- ── Discovery overlay ───────────────────────────────────────────────
    if state == STATE_DISCOVERY then
        discovery_timer = discovery_timer - delta
        spawn_particles(400, 300, 1, discovery_color[1], discovery_color[2], discovery_color[3], 0.8, 100)
        if discovery_timer <= 0 then
            state = STATE_CRAFTING
        end
        return
    end

    -- ── Shop ────────────────────────────────────────────────────────────
    if state == STATE_SHOP then
        if lurek.input.wasActionPressed("escape") or lurek.input.wasActionPressed("shop") then
            state = STATE_CRAFTING
            return
        end
        -- buy ingredients 1-6
        for i = 1, 6 do
            if lurek.input.wasActionPressed("ingredient" .. i) then
                local ing = ingredients[i]
                if gold >= ing.cost then
                    gold = gold - ing.cost
                    stock[i] = stock[i] + 1
                    set_message("Bought " .. ing.name .. " (-" .. ing.cost .. "g)", 1.5)
                else
                    set_message("Not enough gold!", 1.5)
                end
            end
        end
        -- sell potions: use 7,8,9,0 mapped or just cycle through
        if lurek.input.wasActionPressed("bottle") and #inventory > 0 then
            local potion = table.remove(inventory, 1)
            gold = gold + potion.value
            set_message("Sold " .. potion.name .. " (+" .. potion.value .. "g)", 1.5)
            spawn_particles(400, 300, 15, 1, 0.85, 0, 0.6, 50)
        end
        return
    end

    -- ── Crafting ────────────────────────────────────────────────────────

    if lurek.input.wasActionPressed("escape") then
        lurek.event.quit()
    end

    if lurek.input.wasActionPressed("shop") then
        state = STATE_SHOP
        set_message("SHOP — 1-6 buy, B sell potion, S/Esc close", 3)
        return
    end

    -- add ingredient to mortar
    for i = 1, 6 do
        if lurek.input.wasActionPressed("ingredient" .. i) then
            if stock[i] > 0 and #mortar < 3 and not is_grinding and not ground then
                stock[i] = stock[i] - 1
                table.insert(mortar, i)
                set_message("Added " .. ingredients[i].name .. " to mortar", 1.5)
                spawn_particles(200, 400, 8, ingredients[i].color[1], ingredients[i].color[2], ingredients[i].color[3], 0.5, 40)
            elseif stock[i] <= 0 then
                set_message("Out of " .. ingredients[i].name .. "! Visit shop (S)", 2)
            elseif #mortar >= 3 then
                set_message("Mortar full! Grind first (G)", 1.5)
            end
        end
    end

    -- grind
    if lurek.input.wasActionPressed("grind") and #mortar > 0 and not is_grinding and not ground then
        is_grinding = true
        grind_timer = 0
        tween_to(anim, "grind_bar", 1, grind_duration)
        set_message("Grinding...", grind_duration)
    end

    if is_grinding then
        grind_timer = grind_timer + delta
        spawn_particles(200, 400, 1, 0.8, 0.7, 0.5, 0.4, 30)
        if grind_timer >= grind_duration then
            is_grinding = false
            local g = { fire = 0, water = 0, earth = 0, air = 0 }
            for _, idx in ipairs(mortar) do
                g.fire  = g.fire  + ingredients[idx].fire
                g.water = g.water + ingredients[idx].water
                g.earth = g.earth + ingredients[idx].earth
                g.air   = g.air   + ingredients[idx].air
            end
            ground = g
            mortar = {}
            anim.grind_bar = 0
            set_message("Ground! Add to cauldron (press G again)", 2)
            spawn_particles(200, 400, 20, 0.9, 0.8, 0.5, 0.7, 60)
        end
    end

    -- add ground to cauldron
    if lurek.input.wasActionPressed("grind") and ground and not is_grinding then
        if not cauldron then
            cauldron = { fire = 0, water = 0, earth = 0, air = 0 }
        end
        cauldron.fire  = cauldron.fire  + ground.fire
        cauldron.water = cauldron.water + ground.water
        cauldron.earth = cauldron.earth + ground.earth
        cauldron.air   = cauldron.air   + ground.air
        ground = nil
        brewing_done = false
        set_message("Added to cauldron! Heat (H) or cool (J)", 2)
        spawn_particles(400, 380, 15, 0.4, 0.6, 1.0, 0.6, 50)
    end

    -- heat / cool
    if lurek.input.wasActionPressed("heat") and cauldron then
        temperature = math.min(temperature + 10, 100)
        tween_to(anim, "temp_display", temperature, 0.3)
        if temperature > 85 then
            set_message("WARNING: Temperature critical!", 1.5)
        else
            set_message("Heating... " .. temperature .. "°", 1)
        end
        spawn_particles(400, 420, 5, 1.0, 0.4, 0.1, 0.5, 40)
    end

    if lurek.input.wasActionPressed("cool") and cauldron then
        temperature = math.max(temperature - 10, 0)
        tween_to(anim, "temp_display", temperature, 0.3)
        set_message("Cooling... " .. temperature .. "°", 1)
        spawn_particles(400, 420, 5, 0.3, 0.5, 1.0, 0.5, 40)
    end

    -- cauldron bubbles
    if cauldron and not brewing_done then
        local bubble_rate = temperature / 100
        if math.random() < bubble_rate * delta * 5 then
            spawn_particles(400 + math.random(-30,30), 380, 1, 0.5, 0.5, 0.8, 0.8, 20)
        end
    end

    -- bottle
    if lurek.input.wasActionPressed("bottle") and cauldron and not brewing_done then
        local result = try_brew()
        if result == "weak" then
            -- still produces but half value — pick best match or generic
            local e = total_elements()
            local best = nil
            for i = #recipes, 1, -1 do
                if recipes[i].check(e) then best = recipes[i]; break end
            end
            if best then
                local potion = { name = "Weak " .. best.name, value = math.floor(best.value / 2), color = best.color }
                table.insert(inventory, potion)
                set_message("Weak brew! " .. potion.name .. " (half value)", 2)
                spawn_particles(600, 400, 10, best.color[1], best.color[2], best.color[3], 0.6, 40)
            else
                set_message("Weak failed brew... ingredients lost", 2)
            end
            clear_workbench()
        elseif result == "explode" then
            set_message("BOOM! Too hot — ingredients destroyed!", 2.5)
            spawn_particles(400, 380, 40, 1.0, 0.4, 0.0, 1.0, 120)
            spawn_particles(400, 380, 20, 0.3, 0.3, 0.3, 1.2, 80)
            clear_workbench()
        elseif result == "failed" then
            set_message("No recipe matched... ingredients lost", 2)
            spawn_particles(400, 380, 10, 0.4, 0.4, 0.4, 0.6, 30)
            clear_workbench()
        elseif type(result) == "table" then
            local potion = { name = result.name, value = result.value, color = result.color }
            table.insert(inventory, potion)
            set_message("Brewed: " .. result.name .. "!", 2)
            spawn_particles(600, 400, 20, result.color[1], result.color[2], result.color[3], 0.8, 60)

            -- discovery check
            local found = false
            for _, d in ipairs(discovered) do
                if d == result.name then found = true; break end
            end
            if not found then
                table.insert(discovered, result.name)
                discovery_name  = result.name
                discovery_color = result.color
                discovery_timer = 2.5
                anim.disc_scale = 0
                tween_to(anim, "disc_scale", 1, 0.6)
                state = STATE_DISCOVERY
                spawn_particles(400, 280, 30, result.color[1], result.color[2], result.color[3], 1.2, 100)
            end
            clear_workbench()
        end
    end
end

-- ── Render (world) ──────────────────────────────────────────────────────────

function lurek.draw()
    if state == STATE_TITLE then
        -- dark background vignette
        lurek.render.setColor(0.18, 0.12, 0.08, 1)
        lurek.render.rectangle("fill", 0, 0, 800, 600)

        -- title
        local pulse = 0.7 + 0.3 * math.abs(math.sin(title_blink * 1.5))
        lurek.render.setColor(1.0, 0.85, 0.0, pulse)
        lurek.render.print("ALCHEMY LAB", 200, 180, 48)

        lurek.render.setColor(0.8, 0.6, 0.3, 1)
        lurek.render.print("Brew potions, discover recipes, earn gold", 190, 260, 16)

        if math.floor(title_blink * 2) % 2 == 0 then
            lurek.render.setColor(1, 1, 1, 0.9)
            lurek.render.print("PRESS ENTER", 320, 380, 20)
        end

        draw_particles()
        return
    end

    -- ── Workbench background ────────────────────────────────────────────
    -- table surface
    lurek.render.setColor(0.22, 0.15, 0.10, 1)
    lurek.render.rectangle("fill", 0, 340, 800, 260)
    lurek.render.setColor(0.28, 0.18, 0.12, 1)
    lurek.render.rectangle("fill", 0, 340, 800, 4)

    -- wall
    lurek.render.setColor(0.16, 0.11, 0.08, 1)
    lurek.render.rectangle("fill", 0, 0, 800, 340)

    -- shelf
    lurek.render.setColor(0.35, 0.22, 0.12, 1)
    lurek.render.rectangle("fill", 20, 80, 760, 8)

    -- ── Ingredient shelf ────────────────────────────────────────────────
    for i = 1, 6 do
        local x = 40 + (i-1) * 120
        local y = 40
        local ing = ingredients[i]
        local r, g, b = ing.color[1], ing.color[2], ing.color[3]

        -- jar
        lurek.render.setColor(0.3, 0.3, 0.3, 0.4)
        lurek.render.rectangle("fill", x, y, 30, 40)
        lurek.render.setColor(r, g, b, stock[i] > 0 and 0.9 or 0.2)
        lurek.render.rectangle("fill", x+4, y+10, 22, 26)

        -- label
        lurek.render.setColor(1, 1, 1, stock[i] > 0 and 1 or 0.3)
        lurek.render.print(i .. ":" .. ing.name, x - 10, y + 44, 10)
        lurek.render.print("x" .. stock[i], x + 8, y + 56, 10)
    end

    -- ── Mortar (left station) ───────────────────────────────────────────
    lurek.render.setColor(0.5, 0.45, 0.4, 1)
    lurek.render.rectangle("fill", 150, 380, 100, 70)
    lurek.render.setColor(0.4, 0.35, 0.3, 1)
    lurek.render.rectangle("fill", 160, 370, 80, 20)
    lurek.render.setColor(1, 1, 1, 0.8)
    lurek.render.print("MORTAR", 168, 355, 12)

    -- mortar contents
    for j, idx in ipairs(mortar) do
        local c = ingredients[idx].color
        lurek.render.setColor(c[1], c[2], c[3], 0.8)
        lurek.render.rectangle("fill", 165 + (j-1)*22, 395, 18, 18)
    end

    -- grind progress bar
    if is_grinding then
        lurek.render.setColor(0.3, 0.3, 0.3, 0.6)
        lurek.render.rectangle("fill", 155, 460, 90, 8)
        lurek.render.setColor(0.9, 0.8, 0.3, 1)
        lurek.render.rectangle("fill", 155, 460, 90 * anim.grind_bar, 8)
    end

    -- ground indicator
    if ground then
        lurek.render.setColor(0.9, 0.8, 0.4, 1)
        lurek.render.print("GROUND READY", 152, 475, 10)
        lurek.render.print("Press G → cauldron", 148, 488, 9)
    end

    -- ── Cauldron (center station) ───────────────────────────────────────
    lurek.render.setColor(0.3, 0.3, 0.35, 1)
    lurek.render.rectangle("fill", 340, 370, 120, 90)
    lurek.render.setColor(0.25, 0.25, 0.3, 1)
    lurek.render.rectangle("fill", 350, 360, 100, 18)
    lurek.render.setColor(1, 1, 1, 0.8)
    lurek.render.print("CAULDRON", 362, 346, 12)

    -- liquid
    if cauldron then
        local intensity = temperature / 100
        lurek.render.setColor(0.2 + intensity * 0.5, 0.3 - intensity * 0.2, 0.8 - intensity * 0.6, 0.7)
        lurek.render.rectangle("fill", 355, 385, 90, 55)
    end

    -- temperature gauge
    lurek.render.setColor(0.2, 0.2, 0.2, 0.8)
    lurek.render.rectangle("fill", 475, 370, 12, 90)
    local temp_h = (anim.temp_display / 100) * 80
    local temp_r = anim.temp_display / 100
    lurek.render.setColor(temp_r, 0.2, 1.0 - temp_r, 1)
    lurek.render.rectangle("fill", 477, 375 + (80 - temp_h), 8, temp_h)
    lurek.render.setColor(1, 1, 1, 0.7)
    lurek.render.print(math.floor(anim.temp_display) .. "°", 470, 462, 10)

    -- safe zone markers
    lurek.render.setColor(0, 1, 0, 0.3)
    local safe_top = 375 + 80 * (1 - 85/100)
    local safe_bot = 375 + 80 * (1 - 40/100)
    lurek.render.rectangle("fill", 490, safe_top, 4, safe_bot - safe_top)

    -- ── Bottle station (right) ──────────────────────────────────────────
    lurek.render.setColor(0.4, 0.35, 0.4, 1)
    lurek.render.rectangle("fill", 570, 380, 80, 70)
    lurek.render.setColor(0.35, 0.3, 0.35, 1)
    lurek.render.rectangle("fill", 575, 370, 70, 18)
    lurek.render.setColor(1, 1, 1, 0.8)
    lurek.render.print("BOTTLE", 585, 355, 12)

    -- show last potions in bottles
    for j = 1, math.min(#inventory, 3) do
        local pot = inventory[#inventory - j + 1]
        lurek.render.setColor(0.6, 0.6, 0.6, 0.5)
        lurek.render.rectangle("fill", 578 + (j-1)*22, 395, 16, 30)
        lurek.render.setColor(pot.color[1], pot.color[2], pot.color[3], 0.9)
        lurek.render.rectangle("fill", 580 + (j-1)*22, 405, 12, 18)
    end

    draw_particles()
end

-- ── Render UI (HUD / overlays) ──────────────────────────────────────────────

function lurek.draw_ui()
    -- FPS
    lurek.render.setColor(1, 1, 1, 0.4)
    lurek.render.print("FPS: " .. lurek.timer.getFPS(), 720, 8, 10)

    if state == STATE_TITLE then return end

    -- ── Gold ────────────────────────────────────────────────────────────
    lurek.render.setColor(1, 0.85, 0, 1)
    lurek.render.print("Gold: " .. gold, 20, 8, 16)

    -- ── Inventory count ─────────────────────────────────────────────────
    lurek.render.setColor(0.8, 0.8, 0.8, 1)
    lurek.render.print("Potions: " .. #inventory, 160, 8, 14)

    -- ── Discoveries ─────────────────────────────────────────────────────
    lurek.render.setColor(0.7, 0.7, 0.4, 1)
    lurek.render.print("Discovered: " .. #discovered .. "/5", 300, 8, 14)

    -- ── Elemental readout ───────────────────────────────────────────────
    if cauldron then
        local y = 100
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.print("Cauldron Elements:", 640, y, 11)
        y = y + 16
        lurek.render.setColor(1, 0.3, 0.1, 1)
        lurek.render.print("Fire:  " .. cauldron.fire,  650, y, 11); y = y + 14
        lurek.render.setColor(0.3, 0.5, 1.0, 1)
        lurek.render.print("Water: " .. cauldron.water, 650, y, 11); y = y + 14
        lurek.render.setColor(0.6, 0.4, 0.2, 1)
        lurek.render.print("Earth: " .. cauldron.earth, 650, y, 11); y = y + 14
        lurek.render.setColor(0.5, 0.9, 0.6, 1)
        lurek.render.print("Air:   " .. cauldron.air,   650, y, 11)
    end

    -- ── Recipe book (right side) ────────────────────────────────────────
    lurek.render.setColor(0.7, 0.6, 0.4, 0.9)
    lurek.render.print("Recipe Book:", 640, 200, 12)
    for i, rec in ipairs(recipes) do
        local found = false
        for _, d in ipairs(discovered) do
            if d == rec.name then found = true; break end
        end
        if found then
            lurek.render.setColor(rec.color[1], rec.color[2], rec.color[3], 1)
            lurek.render.print(rec.name, 645, 218 + (i-1)*16, 10)
        else
            lurek.render.setColor(0.4, 0.4, 0.4, 0.6)
            lurek.render.print("??? Unknown ???", 645, 218 + (i-1)*16, 10)
        end
    end

    -- ── Message ─────────────────────────────────────────────────────────
    if message_timer > 0 then
        local a = math.min(message_timer, 1)
        lurek.render.setColor(0, 0, 0, 0.6 * a)
        lurek.render.rectangle("fill", 150, 560, 500, 30)
        lurek.render.setColor(1, 1, 1, a)
        lurek.render.print(message, 170, 567, 13)
    end

    -- ── Controls hint ───────────────────────────────────────────────────
    lurek.render.setColor(0.6, 0.5, 0.4, 0.6)
    lurek.render.print("1-6:Add  G:Grind  H:Heat  J:Cool  B:Bottle  S:Shop  Esc:Quit", 140, 585, 10)

    -- ── Shop overlay ────────────────────────────────────────────────────
    if state == STATE_SHOP then
        lurek.render.setColor(0, 0, 0, 0.75)
        lurek.render.rectangle("fill", 100, 60, 600, 480)

        lurek.render.setColor(1, 0.85, 0, 1)
        lurek.render.print("~ ALCHEMIST'S SHOP ~", 280, 80, 22)
        lurek.render.setColor(1, 1, 1, 0.8)
        lurek.render.print("Gold: " .. gold, 350, 115, 16)

        -- buy section
        lurek.render.setColor(0.8, 0.7, 0.5, 1)
        lurek.render.print("BUY INGREDIENTS (press 1-6):", 180, 150, 14)

        for i = 1, 6 do
            local ing = ingredients[i]
            local y = 175 + (i-1) * 36
            local r, g, b = ing.color[1], ing.color[2], ing.color[3]

            lurek.render.setColor(r, g, b, 0.8)
            lurek.render.rectangle("fill", 180, y, 20, 20)

            lurek.render.setColor(1, 1, 1, 1)
            lurek.render.print(i .. ". " .. ing.name, 210, y + 2, 13)

            lurek.render.setColor(0.8, 0.8, 0.3, 1)
            lurek.render.print(ing.cost .. "g", 420, y + 2, 13)

            lurek.render.setColor(0.6, 0.6, 0.6, 1)
            local props = ""
            if ing.fire > 0 then props = props .. "F" .. ing.fire .. " " end
            if ing.water > 0 then props = props .. "W" .. ing.water .. " " end
            if ing.earth > 0 then props = props .. "E" .. ing.earth .. " " end
            if ing.air > 0 then props = props .. "A" .. ing.air .. " " end
            lurek.render.print(props, 480, y + 2, 11)

            lurek.render.print("stock:" .. stock[i], 570, y + 2, 11)
        end

        -- sell section
        lurek.render.setColor(0.8, 0.7, 0.5, 1)
        lurek.render.print("SELL POTIONS (press B):", 180, 400, 14)

        if #inventory == 0 then
            lurek.render.setColor(0.5, 0.5, 0.5, 0.6)
            lurek.render.print("No potions to sell", 220, 425, 12)
        else
            for j = 1, math.min(#inventory, 4) do
                local pot = inventory[j]
                local y = 420 + (j-1) * 24
                lurek.render.setColor(pot.color[1], pot.color[2], pot.color[3], 1)
                lurek.render.rectangle("fill", 200, y, 14, 14)
                lurek.render.setColor(1, 1, 1, 1)
                lurek.render.print(pot.name .. " — " .. pot.value .. "g", 224, y, 12)
            end
        end

        lurek.render.setColor(0.6, 0.6, 0.6, 0.8)
        lurek.render.print("Press S or Esc to close shop", 270, 520, 12)
    end

    -- ── Discovery overlay ───────────────────────────────────────────────
    if state == STATE_DISCOVERY then
        lurek.render.setColor(0, 0, 0, 0.7)
        lurek.render.rectangle("fill", 0, 0, 800, 600)

        local s = anim.disc_scale
        local r, g, b = discovery_color[1], discovery_color[2], discovery_color[3]

        lurek.render.setColor(r, g, b, 0.3 * s)
        lurek.render.rectangle("fill", 200, 200, 400 * s, 200 * s)

        lurek.render.setColor(1, 0.9, 0.2, s)
        lurek.render.print("NEW DISCOVERY!", 260, 230, math.floor(28 * s))

        lurek.render.setColor(r, g, b, s)
        lurek.render.print(discovery_name, 280, 300, math.floor(22 * s))

        lurek.render.setColor(1, 1, 1, 0.6 * s)
        lurek.render.print(#discovered .. " / 5 recipes found", 310, 350, 14)
    end
end
