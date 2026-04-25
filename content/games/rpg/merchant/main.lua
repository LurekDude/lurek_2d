-- ============================================================================
-- Merchant — Lurek2D
-- ============================================================================
-- Category : rpg
-- Source   : content/games/rpg/merchant/main.lua
-- Run with : cargo run -- content/games/rpg/merchant
-- ============================================================================
-- Medieval trading shop simulation. Buy low, sell high, manage inventory,
-- serve customers, build reputation, and maximise gold over five days.
-- Controls: 1-8 buy/sell, A auto-buy, S sell mode, R restock, L ledger, Esc quit
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------
local SCREEN_W, SCREEN_H = 800, 600

local STATE = { TITLE = 1, TRADING = 2, CUSTOMER = 3, LEDGER = 4, GAME_OVER = 5 }
local current_state = STATE.TITLE

local STARTING_GOLD    = 200
local MAX_STOCK        = 5
local SELL_RATIO       = 0.75
local CUSTOMER_SELL    = 1.20
local CUSTOMER_INTERVAL = 5.0
local DAY_LENGTH       = 60.0
local TOTAL_DAYS       = 5
local BASE_REPUTATION  = 1.0
local REP_GAIN         = 0.02
local REP_LOSS         = 0.03

-- ---------------------------------------------------------------------------
-- Item catalog
-- ---------------------------------------------------------------------------
local CATEGORIES = { "Weapons", "Armor", "Potions" }

local ITEMS = {
    { id = 1, name = "Iron Sword",   cat = "Weapons", cost = 30,  stat = "dmg 10", color = {0.7,0.7,0.8} },
    { id = 2, name = "Steel Sword",  cat = "Weapons", cost = 80,  stat = "dmg 18", color = {0.8,0.8,0.9} },
    { id = 3, name = "Magic Staff",  cat = "Weapons", cost = 120, stat = "dmg 25", color = {0.6,0.4,0.9} },
    { id = 4, name = "Leather Armor",cat = "Armor",   cost = 20,  stat = "def 5",  color = {0.6,0.4,0.2} },
    { id = 5, name = "Chainmail",    cat = "Armor",   cost = 60,  stat = "def 12", color = {0.5,0.5,0.5} },
    { id = 6, name = "Plate Armor",  cat = "Armor",   cost = 100, stat = "def 20", color = {0.8,0.7,0.3} },
    { id = 7, name = "Health Potion",cat = "Potions", cost = 10,  stat = "heal",   color = {0.9,0.2,0.2} },
    { id = 8, name = "Mana Potion",  cat = "Potions", cost = 15,  stat = "mana",   color = {0.2,0.3,0.9} },
}

-- ---------------------------------------------------------------------------
-- Game state
-- ---------------------------------------------------------------------------
local gold           = STARTING_GOLD
local gold_display   = STARTING_GOLD
local gold_display_tween_target = STARTING_GOLD
local total_earned   = 0
local reputation     = BASE_REPUTATION
local inventory      = {}   -- id -> count
local shelf_stock    = {}   -- id -> count
local sell_mode      = false
local day            = 1
local day_timer      = 0

local customer          = nil  -- { item_id, name, timer, x, target_x }
local customer_timer    = 0
local customer_served   = 0
local customer_missed   = 0

local ledger         = {}   -- { text, time }
local messages       = {}   -- { text, timer, color }

-- Particles
local particles      = {}
-- Tweens
local tweens         = {}

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function add_message(text, r, g, b)
    table.insert(messages, { text = text, timer = 2.5, color = {r or 1, g or 1, b or 1} })
end

local function add_ledger(text)
    table.insert(ledger, { text = text, time = string.format("Day %d", day) })
end

local function spawn_particles(x, y, r, g, b, count)
    for i = 1, (count or 8) do
        local angle = math.random() * math.pi * 2
        local speed = 40 + math.random() * 80
        table.insert(particles, {
            x = x, y = y,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 0.6 + math.random() * 0.4,
            max_life = 1.0,
            r = r, g = g, b = b,
            size = 2 + math.random() * 3,
        })
    end
end

local function add_tween(target, field, from, to, duration)
    table.insert(tweens, {
        target = target, field = field,
        from = from, to = to,
        elapsed = 0, duration = duration,
    })
end

local function sell_price(item)
    return math.floor(item.cost * SELL_RATIO)
end

local function customer_price(item)
    return math.floor(item.cost * CUSTOMER_SELL * reputation)
end

local function restock_shelf()
    for _, item in ipairs(ITEMS) do
        shelf_stock[item.id] = MAX_STOCK
    end
    add_message("Merchant restocked all items!", 0.4, 0.9, 0.4)
end

local function reset_game()
    gold = STARTING_GOLD
    gold_display = STARTING_GOLD
    total_earned = 0
    reputation = BASE_REPUTATION
    inventory = {}
    ledger = {}
    messages = {}
    particles = {}
    tweens = {}
    sell_mode = false
    day = 1
    day_timer = 0
    customer = nil
    customer_timer = 0
    customer_served = 0
    customer_missed = 0
    for _, item in ipairs(ITEMS) do
        inventory[item.id] = 0
    end
    restock_shelf()
end

-- ---------------------------------------------------------------------------
-- Buy / Sell logic
-- ---------------------------------------------------------------------------
local function buy_item(idx)
    local item = ITEMS[idx]
    if not item then return end
    if shelf_stock[item.id] <= 0 then
        add_message("Out of stock: " .. item.name, 0.9, 0.4, 0.4)
        return
    end
    if gold < item.cost then
        add_message("Not enough gold for " .. item.name, 0.9, 0.4, 0.4)
        return
    end
    gold = gold - item.cost
    add_tween({ gold_display_tween_target = gold_display }, "gold_display_tween_target", gold_display, gold, 0.3)
    gold_display_tween_target = gold
    shelf_stock[item.id] = shelf_stock[item.id] - 1
    inventory[item.id] = (inventory[item.id] or 0) + 1
    add_message("Bought " .. item.name .. " (-" .. item.cost .. "g)", 0.3, 0.8, 1.0)
    add_ledger("BUY  " .. item.name .. " for " .. item.cost .. "g")
    spawn_particles(400, 300, item.color[1], item.color[2], item.color[3], 6)
end

local function sell_item(idx)
    local item = ITEMS[idx]
    if not item then return end
    if (inventory[item.id] or 0) <= 0 then
        add_message("You don't have " .. item.name, 0.9, 0.4, 0.4)
        return
    end
    local price = sell_price(item)
    gold = gold + price
    total_earned = total_earned + price
    add_tween({ gold_display_tween_target = gold_display }, "gold_display_tween_target", gold_display, gold, 0.3)
    gold_display_tween_target = gold
    inventory[item.id] = inventory[item.id] - 1
    add_message("Sold " .. item.name .. " (+" .. price .. "g)", 1.0, 0.9, 0.3)
    add_ledger("SELL " .. item.name .. " for " .. price .. "g")
    spawn_particles(400, 300, 1.0, 0.85, 0.2, 10)
end

local function auto_buy()
    local best_idx = nil
    local best_cost = 0
    for i, item in ipairs(ITEMS) do
        if shelf_stock[item.id] > 0 and item.cost <= gold and item.cost > best_cost then
            best_cost = item.cost
            best_idx = i
        end
    end
    if best_idx then
        buy_item(best_idx)
    else
        add_message("Nothing affordable to buy!", 0.9, 0.6, 0.3)
    end
end

-- ---------------------------------------------------------------------------
-- Customer logic
-- ---------------------------------------------------------------------------
local CUSTOMER_NAMES = { "Aldric", "Brenna", "Cedric", "Doreth", "Elwin", "Fiona", "Gareth", "Helga" }

local function spawn_customer()
    local item_id = math.random(1, #ITEMS)
    local name = CUSTOMER_NAMES[math.random(1, #CUSTOMER_NAMES)]
    customer = {
        item_id = item_id,
        name = name,
        timer = 4.0,
        x = -60,
        target_x = 150,
    }
    add_tween(customer, "x", -60, 150, 0.6)
    spawn_particles(150, 420, 0.8, 0.7, 0.5, 8)
    current_state = STATE.CUSTOMER
end

local function serve_customer()
    if not customer then return end
    local item = ITEMS[customer.item_id]
    if (inventory[item.id] or 0) > 0 then
        local price = customer_price(item)
        gold = gold + price
        total_earned = total_earned + price
        add_tween({ gold_display_tween_target = gold_display }, "gold_display_tween_target", gold_display, gold, 0.4)
        gold_display_tween_target = gold
        inventory[item.id] = inventory[item.id] - 1
        reputation = reputation + REP_GAIN
        customer_served = customer_served + 1
        add_message(customer.name .. " bought " .. item.name .. " (+" .. price .. "g)", 0.2, 1.0, 0.4)
        add_ledger("CUST " .. customer.name .. " bought " .. item.name .. " for " .. price .. "g")
        spawn_particles(200, 400, 1.0, 0.9, 0.2, 12)
    else
        reputation = clamp(reputation - REP_LOSS, 0.5, 2.0)
        customer_missed = customer_missed + 1
        add_message(customer.name .. " left disappointed (no " .. item.name .. ")", 0.9, 0.3, 0.3)
        add_ledger("MISS " .. customer.name .. " wanted " .. item.name)
    end
    customer = nil
    current_state = STATE.TRADING
end

-- ---------------------------------------------------------------------------
-- Update
-- ---------------------------------------------------------------------------
local function update_particles(dt)
    local i = 1
    while i <= #particles do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 120 * dt
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(particles, i)
        else
            i = i + 1
        end
    end
end

local function update_tweens(dt)
    local i = 1
    while i <= #tweens do
        local tw = tweens[i]
        tw.elapsed = tw.elapsed + dt
        local t = clamp(tw.elapsed / tw.duration, 0, 1)
        -- ease out quad
        local val = tw.from + (tw.to - tw.from) * (1 - (1 - t) * (1 - t))
        if tw.target and tw.field then
            tw.target[tw.field] = val
        end
        if t >= 1 then
            table.remove(tweens, i)
        else
            i = i + 1
        end
    end
    -- gold display tween
    if gold_display_tween_target then
        gold_display = math.floor(gold_display_tween_target)
    else
        gold_display = gold
    end
end

local function update_messages(dt)
    local i = 1
    while i <= #messages do
        messages[i].timer = messages[i].timer - dt
        if messages[i].timer <= 0 then
            table.remove(messages, i)
        else
            i = i + 1
        end
    end
end

-- ---------------------------------------------------------------------------
-- Engine callbacks
-- ---------------------------------------------------------------------------

-- Universal render helpers (handles all legacy and current call signatures)
local _gfx = lurek.render
local function _sc(c)
    if type(c) == "table" then
        local col = c.color or c
        if type(col) == "table" then
            _gfx.setColor(col[1] or 1, col[2] or 1, col[3] or 1, col[4] or 1)
        end
    end
end
local function rect(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        _gfx.rectangle(a, b, c, d, e)
    elseif type(e) == "table" then
        _sc(e); _gfx.rectangle(e.mode or "fill", a, b, c, d)
    elseif type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1); _gfx.rectangle("fill", a, b, c, d)
    else
        _gfx.rectangle("fill", a, b, c, d)
    end
end
local function circ(a, b, c, d, e, f, g, h)
    if type(a) == "string" then
        if type(e) == "table" then _sc(e)
        elseif type(e) == "number" then _gfx.setColor(e or 1, f or 1, g or 1, h or 1) end
        _gfx.circle(a, b, c, d)
    elseif type(d) == "table" then
        _sc(d); _gfx.circle("fill", a, b, c)
    elseif type(d) == "number" then
        _gfx.setColor(d or 1, e or 1, f or 1, g or 1); _gfx.circle("fill", a, b, c)
    else
        _gfx.circle("fill", a, b, c)
    end
end
local function text_(a, b, c, d, e, f, g, h)
    if type(d) == "table" then
        _sc(d)
    elseif type(d) == "number" and type(e) == "number" then
        _gfx.setColor(e or 1, f or 1, g or 1, h or 1)
    end
    _gfx.print(tostring(a), b, c)
end
local function ln(x1, y1, x2, y2, c)
    if type(c) == "table" then _sc(c) end
    _gfx.line(x1, y1, x2, y2)
end

local _cam = nil ---@type any

function lurek.init()
    _cam = lurek.camera.new()
    lurek.window.setTitle("Merchant — Lurek2D")
    lurek.render.setBackgroundColor(0.15, 0.12, 0.08)
    lurek.input.bind("confirm", {"return", "space"})
    lurek.input.bind("quit", {"escape"})
    lurek.input.bind("ledger", {"l"})
    lurek.input.bind("toggle_sell", {"s"})
    lurek.input.bind("auto_buy", {"a"})
    lurek.input.bind("restock", {"r"})
    for i = 1, 8 do
        lurek.input.bind("item_" .. i, { tostring(i) })
    end
    -- [removed: lurek.timer.setTargetFPS has no equivalent]
    reset_game()
end

local function _ready_setup()
    current_state = STATE.TITLE
end

function lurek.process(dt)
    -- Title screen
    if current_state == STATE.TITLE then
        if lurek.input.wasActionPressed("confirm") then
            current_state = STATE.TRADING
        end
        if lurek.input.wasActionPressed("quit") then
            lurek.event.push("quit")
        end
        return
    end

    -- Game over
    if current_state == STATE.GAME_OVER then
        if lurek.input.wasActionPressed("confirm") then
            reset_game()
            current_state = STATE.TITLE
        end
        if lurek.input.wasActionPressed("quit") then
            lurek.event.push("quit")
        end
        return
    end

    -- Ledger view
    if current_state == STATE.LEDGER then
        if lurek.input.wasActionPressed("ledger") or lurek.input.wasActionPressed("quit") then
            current_state = STATE.TRADING
        end
        return
    end

    -- Day timer
    day_timer = day_timer + dt
    if day_timer >= DAY_LENGTH then
        day_timer = 0
        day = day + 1
        if day > TOTAL_DAYS then
            current_state = STATE.GAME_OVER
            return
        end
        add_message("Day " .. day .. " begins!", 1.0, 0.9, 0.5)
        restock_shelf()
    end

    -- Customer arrival
    if current_state == STATE.TRADING then
        customer_timer = customer_timer + dt
        if customer_timer >= CUSTOMER_INTERVAL then
            customer_timer = 0
            spawn_customer()
        end
    end

    -- Customer timeout
    if current_state == STATE.CUSTOMER and customer then
        customer.timer = customer.timer - dt
        if customer.timer <= 0 then
            serve_customer()
        end
    end

    -- Input: trading
    if current_state == STATE.TRADING or current_state == STATE.CUSTOMER then
        -- Toggle sell mode
        if lurek.input.wasActionPressed("toggle_sell") then
            sell_mode = not sell_mode
            if sell_mode then
                add_message("SELL MODE — press 1-8 to sell", 1.0, 0.7, 0.2)
            else
                add_message("BUY MODE — press 1-8 to buy", 0.3, 0.8, 1.0)
            end
        end

        -- Buy/sell items 1-8
        for i = 1, 8 do
            if lurek.input.wasActionPressed("item_" .. i) then
                if sell_mode then
                    sell_item(i)
                else
                    buy_item(i)
                end
            end
        end

        -- Auto-buy
        if lurek.input.wasActionPressed("auto_buy") then
            auto_buy()
        end

        -- Restock
        if lurek.input.wasActionPressed("restock") then
            restock_shelf()
        end

        -- Ledger
        if lurek.input.wasActionPressed("ledger") then
            current_state = STATE.LEDGER
        end

        -- Quit
        if lurek.input.wasActionPressed("quit") then
            lurek.event.push("quit")
        end
    end

    -- Update systems
    update_particles(dt)
    update_tweens(dt)
    update_messages(dt)
end

-- ---------------------------------------------------------------------------
-- Render — shop scene background
-- ---------------------------------------------------------------------------
function lurek.draw()
    if current_state == STATE.TITLE or current_state == STATE.GAME_OVER or current_state == STATE.LEDGER then
        return
    end

    local cam = _cam:getPosition()

    -- Shop floor
    rect(0, 450, SCREEN_W, 150, 0.25, 0.18, 0.12, 1)
    -- Counter
    rect(60, 380, 300, 70, 0.35, 0.25, 0.15, 1)
    rect(60, 375, 300, 8, 0.45, 0.35, 0.20, 1)
    -- Shelves background
    rect(420, 100, 350, 340, 0.20, 0.15, 0.10, 1)
    -- Shelf planks
    for row = 0, 2 do
        local sy = 140 + row * 110
        rect(425, sy, 340, 6, 0.4, 0.3, 0.18, 1)
    end

    -- Customer approach area
    if current_state == STATE.CUSTOMER and customer then
        local cx = customer.x or 150
        -- Customer body
        rect(cx, 400, 30, 50, 0.65, 0.55, 0.40, 1)
        -- Customer head
        circ(cx + 15, 390, 12, 0.75, 0.65, 0.50, 1)
    end

    -- Particles (world-space)
    for _, p in ipairs(particles) do
        local alpha = clamp(p.life / p.max_life, 0, 1)
        circ(p.x, p.y, p.size, p.r, p.g, p.b, alpha)
    end
end

-- ---------------------------------------------------------------------------
-- Render UI — HUD, shelf, inventory, messages
-- ---------------------------------------------------------------------------
function lurek.draw_ui()
    -- ===== TITLE SCREEN =====
    if current_state == STATE.TITLE then
        rect(0, 0, SCREEN_W, SCREEN_H, 0.12, 0.09, 0.06, 1)
        text_("THE MERCHANT", SCREEN_W / 2 - 140, 160, 36, 0.95, 0.85, 0.5, 1)
        text_("BUY LOW, SELL HIGH", SCREEN_W / 2 - 120, 220, 20, 0.7, 0.6, 0.4, 1)
        text_("Trade goods, serve customers, build your fortune", SCREEN_W / 2 - 210, 280, 14, 0.6, 0.5, 0.35, 1)
        text_("Press ENTER to start", SCREEN_W / 2 - 90, 400, 16, 0.8, 0.7, 0.4, 1)
        text_("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12, 0.4, 0.4, 0.4, 1)
        return
    end

    -- ===== GAME OVER =====
    if current_state == STATE.GAME_OVER then
        rect(0, 0, SCREEN_W, SCREEN_H, 0.08, 0.05, 0.03, 1)
        text_("GAME OVER", SCREEN_W / 2 - 100, 140, 36, 0.9, 0.3, 0.2, 1)
        text_("Final Gold: " .. gold .. "g", SCREEN_W / 2 - 80, 220, 22, 1.0, 0.9, 0.3, 1)
        text_("Total Earned: " .. total_earned .. "g", SCREEN_W / 2 - 90, 260, 18, 0.8, 0.7, 0.3, 1)
        text_("Customers Served: " .. customer_served, SCREEN_W / 2 - 100, 300, 16, 0.5, 0.8, 0.5, 1)
        text_("Customers Missed: " .. customer_missed, SCREEN_W / 2 - 100, 325, 16, 0.8, 0.4, 0.4, 1)
        text_("Reputation: " .. string.format("%.0f%%", reputation * 100), SCREEN_W / 2 - 70, 365, 16, 0.7, 0.6, 0.9, 1)
        text_("Press ENTER to restart", SCREEN_W / 2 - 100, 430, 16, 0.6, 0.5, 0.4, 1)
        text_("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12, 0.4, 0.4, 0.4, 1)
        return
    end

    -- ===== LEDGER =====
    if current_state == STATE.LEDGER then
        rect(0, 0, SCREEN_W, SCREEN_H, 0.10, 0.08, 0.05, 1)
        text_("SALES LEDGER", SCREEN_W / 2 - 80, 30, 24, 0.95, 0.85, 0.5, 1)
        text_("Press L or ESC to close", SCREEN_W / 2 - 100, 60, 12, 0.5, 0.5, 0.4, 1)
        local y = 100
        local start = math.max(1, #ledger - 18)
        for i = start, #ledger do
            local entry = ledger[i]
            local cr, cg, cb = 0.7, 0.7, 0.6
            if string.sub(entry.text, 1, 4) == "BUY " then cr, cg, cb = 0.4, 0.7, 1.0 end
            if string.sub(entry.text, 1, 4) == "SELL" then cr, cg, cb = 1.0, 0.9, 0.3 end
            if string.sub(entry.text, 1, 4) == "CUST" then cr, cg, cb = 0.3, 1.0, 0.5 end
            if string.sub(entry.text, 1, 4) == "MISS" then cr, cg, cb = 0.9, 0.4, 0.3 end
            text_("[" .. entry.time .. "] " .. entry.text, 60, y, 14, cr, cg, cb, 1)
            y = y + 22
        end
        text_("FPS: " .. lurek.timer.getFPS(), 10, SCREEN_H - 20, 12, 0.4, 0.4, 0.4, 1)
        return
    end

    -- ===== TRADING / CUSTOMER HUD =====

    -- Top bar
    rect(0, 0, SCREEN_W, 40, 0.1, 0.08, 0.05, 0.9)
    text_("Gold: " .. math.floor(gold_display) .. "g", 15, 10, 18, 1.0, 0.9, 0.3, 1)
    text_("Day " .. day .. "/" .. TOTAL_DAYS, 200, 12, 16, 0.7, 0.6, 0.4, 1)
    -- Day progress bar
    local prog = day_timer / DAY_LENGTH
    rect(320, 14, 150, 12, 0.2, 0.15, 0.1, 1)
    rect(320, 14, 150 * prog, 12, 0.6, 0.5, 0.2, 1)
    text_("Rep: " .. string.format("%.0f%%", reputation * 100), 500, 12, 14, 0.7, 0.6, 0.9, 1)
    local mode_text = sell_mode and "SELL MODE (S)" or "BUY MODE (S)"
    local mode_r = sell_mode and 1.0 or 0.3
    local mode_g = sell_mode and 0.6 or 0.8
    local mode_b = sell_mode and 0.2 or 1.0
    text_(mode_text, 640, 12, 14, mode_r, mode_g, mode_b, 1)

    -- Shelf: items grouped by category
    local sx, sy = 420, 55
    local slot = 1
    for _, cat in ipairs(CATEGORIES) do
        text_(cat, sx, sy, 14, 0.8, 0.7, 0.5, 1)
        sy = sy + 20
        for _, item in ipairs(ITEMS) do
            if item.cat == cat then
                local stock = shelf_stock[item.id] or 0
                local alpha = stock > 0 and 1.0 or 0.3
                -- Item color swatch
                rect(sx, sy, 10, 10, item.color[1], item.color[2], item.color[3], alpha)
                local label = string.format("[%d] %s  %dg  stk:%d  %s",
                    slot, item.name, item.cost, stock, item.stat)
                text_(label, sx + 16, sy, 12, 0.8, 0.8, 0.7, alpha)
                sy = sy + 18
                slot = slot + 1
            end
        end
        sy = sy + 8
    end

    -- Inventory panel
    rect(10, 460, 380, 130, 0.12, 0.10, 0.07, 0.9)
    text_("YOUR INVENTORY", 20, 465, 14, 0.8, 0.7, 0.5, 1)
    local ix, iy = 20, 485
    local has_items = false
    for _, item in ipairs(ITEMS) do
        local count = inventory[item.id] or 0
        if count > 0 then
            has_items = true
            local sp = sell_price(item)
            rect(ix, iy + 2, 8, 8, item.color[1], item.color[2], item.color[3], 1)
            text_(item.name .. " x" .. count .. " (sell:" .. sp .. "g)", ix + 14, iy, 12, 0.7, 0.7, 0.6, 1)
            iy = iy + 16
        end
    end
    if not has_items then
        text_("Empty — buy items from the shelf!", 20, 490, 12, 0.5, 0.4, 0.3, 1)
    end

    -- Customer panel
    if current_state == STATE.CUSTOMER and customer then
        rect(10, 340, 380, 110, 0.18, 0.12, 0.08, 0.95)
        text_("CUSTOMER: " .. customer.name, 20, 348, 16, 0.9, 0.8, 0.5, 1)
        local wanted = ITEMS[customer.item_id]
        text_("Wants: " .. wanted.name, 20, 370, 14, 0.8, 0.7, 0.5, 1)
        local cp = customer_price(wanted)
        text_("Will pay: " .. cp .. "g", 20, 390, 14, 0.3, 0.9, 0.3, 1)
        local have = (inventory[wanted.id] or 0) > 0
        if have then
            text_("You have it! Auto-selling...", 20, 412, 12, 0.4, 1.0, 0.5, 1)
        else
            text_("You don't have it!", 20, 412, 12, 0.9, 0.3, 0.3, 1)
        end
        -- Timer bar
        local tp = clamp(customer.timer / 4.0, 0, 1)
        rect(20, 432, 200, 8, 0.2, 0.15, 0.1, 1)
        rect(20, 432, 200 * tp, 8, 0.9, 0.6, 0.1, 1)
    end

    -- Messages
    local my = 50
    for _, msg in ipairs(messages) do
        local alpha = clamp(msg.timer / 1.0, 0, 1)
        text_(msg.text, 15, my, 13, msg.color[1], msg.color[2], msg.color[3], alpha)
        my = my + 18
    end

    -- Controls hint
    text_("[1-8] Buy/Sell  [A] Auto-buy  [S] Mode  [R] Restock  [L] Ledger  [ESC] Quit",
        10, SCREEN_H - 18, 11, 0.4, 0.35, 0.3, 1)

    -- FPS
    text_("FPS: " .. lurek.timer.getFPS(), SCREEN_W - 80, SCREEN_H - 18, 11, 0.4, 0.4, 0.4, 1)
end
