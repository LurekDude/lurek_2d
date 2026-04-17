--[[
-- Run with: cargo run -- content/demos/rpg/merchant_demo
  merchant_demo — Item System + Inventory: Shop / Trading Game
  ─────────────────────────────────────────────────────────────
  Demonstrates how lurek.item and lurek.inventory model a merchant's
  shop-keep simulation:

    • Item catalog with base prices (lurek.item.defineType base_stats)
    • Merchant stock as StackManager keyed by category
    • Player purse (coin tracking) + purchase bag (inventory container)
    • Group-by-category view of the merchant shelf
    • findNOfStat to auto-buy the highest-value item the player can afford
    • StackHistory as a sales ledger

  Controls:
    [1-6]  Buy the corresponding item from the shelf
    [A]    Auto-buy the most valuable item you can afford
    [S]    Show sales ledger summary in console (RUST_LOG=debug)
    [R]    Restock the merchant (refills all stacks)
--]]

-- Polyfill: map lurek.item and lurek.inventory to library modules
lurek.item      = require("library.item")
lurek.inventory = require("library.inventory")


-- ── Item catalog ──────────────────────────────────────────────────────────
lurek.item.clearTypes()
lurek.item.defineType("iron_sword",   { category="weapon",    base_stats={ price=30, dmg=10, weight=3.0 }, base_tags={"weapon","equippable"} })
lurek.item.defineType("steel_sword",  { category="weapon",    base_stats={ price=80, dmg=18, weight=3.5 }, base_tags={"weapon","equippable"} })
lurek.item.defineType("leather_helm", { category="armor",     base_stats={ price=20, def= 3, weight=1.5 }, base_tags={"armor","equippable"} })
lurek.item.defineType("chain_helm",   { category="armor",     base_stats={ price=60, def= 7, weight=3.0 }, base_tags={"armor","equippable"} })
lurek.item.defineType("health_potion",{ category="consumable",base_stats={ price=15, hp =50, weight=0.5 }, base_tags={"consumable"} })
lurek.item.defineType("mana_potion",  { category="consumable",base_stats={ price=20, mp =40, weight=0.5 }, base_tags={"consumable"} })

local SHELF_ITEMS = {
    "iron_sword", "steel_sword",
    "leather_helm", "chain_helm",
    "health_potion", "mana_potion",
}

-- ── Merchant stock as StackManager ────────────────────────────────────────
local merchant   = lurek.item.newStackManager()
local sales_log  = lurek.item.newStackHistory(50)   -- sales ledger

local function restock()
    for _, type_name in ipairs(SHELF_ITEMS) do
        local stack_name = "shelf_"..type_name
        -- Create or clear the stack
        local existing = merchant:getStack(stack_name)
        if not existing then
            merchant:addStack(stack_name, lurek.item.newStack(stack_name))
        else
            existing:clear()
        end
        local s = merchant:getStack(stack_name)
        for i = 1, math.random(2, 5) do
            s:push(lurek.item.newItem(type_name))
        end
    end
end

-- ── Player state ──────────────────────────────────────────────────────────
local player_gold = 120
local player_bag  = lurek.inventory.newContainer("bag", "dynamic", 20)
player_bag:setWeightLimit(30.0)

-- ── Price lookup helper ───────────────────────────────────────────────────
local function item_price(type_name)
    local def = lurek.item.getType(type_name)
    if def and def.base_stats then
        return def.base_stats.price or 0
    end
    return 0
end

-- ── Buy one item by type name ─────────────────────────────────────────────
local message = ""
local message_timer = 0

local function try_buy(type_name)
    local price = item_price(type_name)
    if player_gold < price then
        message = "Not enough gold! Need "..price.."g"
        message_timer = 2.0
        return
    end

    local stack = merchant:getStack("shelf_"..type_name)
    if not stack or stack:size() == 0 then
        message = type_name.." is out of stock!"
        message_timer = 2.0
        return
    end

    -- Check weight room
    local def = lurek.item.getType(type_name)
    local item_weight = (def and def.base_stats and def.base_stats.weight) or 0
    if player_bag:getCurrentWeight() + item_weight > 30.0 then
        message = "Bag too heavy to carry "..type_name
        message_timer = 2.0
        return
    end

    -- Deduct gold, take item
    local it = stack:pop()
    player_gold = player_gold - price

    -- Add to inventory container
    local inv_item = lurek.inventory.newItem(it:getType())
    inv_item:setWeight(item_weight)
    player_bag:addItem(inv_item)

    -- Record sale
    local temp = lurek.item.newStack("tmp")
    temp:push(it)
    sales_log:recordCustom(type_name, "sold_"..type_name, stack:size())

    message = "Bought "..type_name.." for "..price.."g"
    message_timer = 2.0
end

-- ── Auto-buy most valuable affordable item ────────────────────────────────
local function auto_buy()
    -- Gather all in-stock items into a flat list for findNOfStat
    local candidates = {}
    local candidate_types = {}
    for _, type_name in ipairs(SHELF_ITEMS) do
        local s = merchant:getStack("shelf_"..type_name)
        if s and s:size() > 0 then
            local price = item_price(type_name)
            if price <= player_gold then
                local it = lurek.item.newItem(type_name)
                it:setStat("price", price)
                table.insert(candidates, it)
                table.insert(candidate_types, type_name)
            end
        end
    end

    if #candidates == 0 then
        message = "Nothing affordable in stock!"
        message_timer = 2.0
        return
    end

    -- findNOfStat returns 0-based indices of the top-1 by price
    local best = lurek.item.findNOfStat(candidates, "price", 1)
    if best and best[1] then
        local chosen = candidate_types[best[1] + 1]
        try_buy(chosen)
    end
end

-- ── lurek.init ─────────────────────────────────────────────────────────────
function lurek.init()
    restock()
    lurek.window.setTitle("Merchant Demo — item + inventory shop system")
end

-- ── lurek.keypressed ───────────────────────────────────────────────────────
function lurek.keypressed(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= #SHELF_ITEMS then
        try_buy(SHELF_ITEMS[num])
    elseif key == "a" then
        auto_buy()
    elseif key == "r" then
        restock()
        message = "Merchant restocked!"
        message_timer = 2.0
    end
end

-- ── lurek.process ───────────────────────────────────────────────────────────
function lurek.process(dt)
    if message_timer > 0 then
        message_timer = message_timer - dt
    end
end

-- ── lurek.render ─────────────────────────────────────────────────────────────
local function panel(x, y, w, h, title)
    lurek.render.setColor(0.10, 0.08, 0.20, 0.92)
    lurek.render.rectangle("fill", x, y, w, h)
    lurek.render.setColor(0.55, 0.45, 0.80, 1)
    lurek.render.rectangle("line", x, y, w, h)
    lurek.render.setColor(0.95, 0.90, 1.00, 1)
    lurek.render.print(title, x + 8, y + 6)
end

function lurek.render()
    -- Background
    lurek.render.setColor(0.06, 0.04, 0.12, 1)
    lurek.render.rectangle("fill", 0, 0, 800, 600)

    -- ── Gold + weight ─────────────────────────────────────────────────────
    panel(20, 20, 220, 80, "PLAYER")
    lurek.render.setColor(1.0, 0.85, 0.2, 1)
    lurek.render.print(string.format("Gold: %dg", player_gold), 30, 48)
    lurek.render.setColor(0.6, 0.8, 0.6, 1)
    lurek.render.print(string.format("Bag: %.1f / 30.0 kg", player_bag:getCurrentWeight()), 30, 68)

    -- ── Shelf ─────────────────────────────────────────────────────────────
    panel(260, 20, 520, 220, "MERCHANT SHELF  [1-6] to buy")
    local sy = 46
    for i, type_name in ipairs(SHELF_ITEMS) do
        local stack = merchant:getStack("shelf_"..type_name)
        local qty   = stack and stack:size() or 0
        local price = item_price(type_name)
        local def   = lurek.item.getType(type_name)
        local stats = ""
        if def and def.base_stats then
            for k, v in pairs(def.base_stats) do
                if k ~= "price" and k ~= "weight" then
                    stats = stats..k.."="..tostring(v).." "
                end
            end
        end
        if qty > 0 then
            lurek.render.setColor(0.9, 0.85, 0.5, 1)
        else
            lurek.render.setColor(0.4, 0.4, 0.4, 1)
        end
        lurek.render.print(string.format("[%d] %-16s  %3dg  x%d   %s", i, type_name, price, qty, stats), 270, sy)
        sy = sy + 28
    end

    -- ── Player bag items ──────────────────────────────────────────────────
    panel(20, 120, 220, 200, "YOUR BAG")
    local slots = player_bag:getSlots()
    local bag_y = 146
    local shown = 0
    for _, slot in ipairs(slots) do
        if not slot:isEmpty() and shown < 6 then
            local st = slot:getStack()
            if st then
                lurek.render.setColor(0.85, 0.85, 0.85, 1)
                lurek.render.print("• "..st:getItem():getType(), 30, bag_y)
                bag_y = bag_y + 20
                shown = shown + 1
            end
        end
    end
    if shown == 0 then
        lurek.render.setColor(0.4, 0.4, 0.4, 1)
        lurek.render.print("(empty)", 30, 146)
    end

    -- ── Sales ledger ──────────────────────────────────────────────────────
    panel(20, 340, 760, 140, "SALES LEDGER  (last 5 transactions)")
    local entries = sales_log:entries()
    local log_y = 366
    local start = math.max(1, #entries - 4)
    for i = start, #entries do
        local e = entries[i]
        if e then
            lurek.render.setColor(0.7, 0.9, 0.7, 1)
            lurek.render.print(string.format("#%d  sold %s  (remaining: %d)", i, e.label, e.size_after), 30, log_y)
            log_y = log_y + 24
        end
    end

    -- ── Controls hint ─────────────────────────────────────────────────────
    panel(20, 496, 760, 40, "")
    lurek.render.setColor(0.6, 0.6, 0.8, 1)
    lurek.render.print("[1-6] buy item   [A] auto-buy best value   [R] restock merchant", 30, 506)

    -- ── Flash message ─────────────────────────────────────────────────────
    if message_timer > 0 then
        local alpha = math.min(1.0, message_timer / 0.4)
        lurek.render.setColor(1.0, 0.9, 0.3, alpha)
        lurek.render.print(message, 260, 256)
    end
end
