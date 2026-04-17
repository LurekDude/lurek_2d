-- Loot RPG Demo -- Lurek2D item + inventory integration
-- Run with: cargo run -- content/demos/rpg/loot_rpg_demo

local item      = require("library.item")
local inventory = require("library.inventory")

--[[
  loot_rpg_demo — Item System + Inventory Integration Example
  ─────────────────────────────────────────────────────────────
  Demonstrates how lurek.item and lurek.inventory work together in a
  dungeon-crawler style RPG:

    • Item type catalog       (item.defineType)
    • Random loot pool        (item.newItemPool)
    • Gear loadout builder    (item.newStackBuilder)
    • Pickup journal          (item.newHistory)
    • Weight-limited backpack (inventory.newContainer with weight limit)
    • Equipment slots         (inventory.newInventory)
    • Shop with StackManager  (item.newStackManager)

  Press SPACE to clear a new dungeon room (new loot drop).
  Press E to auto-equip best gear from your backpack.
  Press B to buy 1 potion from the shop (costs 5 coins).
  Press H to cheat +50 HP via a free potion.
--]]

local BAG_WEIGHT_LIMIT = 20.0
local SHOP_STOCK       = 5

-- ── 1. Item type catalog ──────────────────────────────────────────────────
item.clearTypes()
item.defineType("sword",    { category = "weapon",    base_stats = { dmg = 12, weight = 3.5 }, base_tags = {"equippable","weapon"} })
item.defineType("dagger",   { category = "weapon",    base_stats = { dmg =  7, weight = 1.0 }, base_tags = {"equippable","weapon"} })
item.defineType("shield",   { category = "armor",     base_stats = { def =  8, weight = 5.0 }, base_tags = {"equippable","armor"} })
item.defineType("helmet",   { category = "armor",     base_stats = { def =  4, weight = 2.0 }, base_tags = {"equippable","armor"} })
item.defineType("potion",   { category = "consumable",base_stats = { hp  = 50, weight = 0.5 }, base_tags = {"consumable"} })
item.defineType("arrow",    { category = "ammo",      base_stats = { dmg =  3, weight = 0.1 }, base_tags = {"ammo","stackable"} })
item.defineType("coin",     { category = "currency",  base_stats = { value=  1, weight = 0.01},base_tags = {"currency","stackable"} })

-- ── 2. Loot pool for dungeon rooms ────────────────────────────────────────
local loot_pool = item.newItemPool()
loot_pool:addType("coin",    20)
loot_pool:addType("arrow",   15)
loot_pool:addType("potion",   8)
loot_pool:addType("dagger",   4)
loot_pool:addType("helmet",   3)
loot_pool:addType("sword",    2)
loot_pool:addType("shield",   1)

-- ── 3. Starter loadout from StackBuilder ──────────────────────────────────
local starter_builder = item.newStackBuilder()
starter_builder:add("dagger", 1)
starter_builder:add("potion", 2)
starter_builder:add("coin",   10)
local starter_gear = starter_builder:build("starter")

-- ── 4. Pickup journal ─────────────────────────────────────────────────────
local pickup_log = item.newStackHistory(20)

-- ── 5. Player inventory ───────────────────────────────────────────────────
local player_inv  = inventory.newInventory()
local player_bag  = inventory.newContainer("bag", "dynamic", 30)
player_bag:setWeightLimit(BAG_WEIGHT_LIMIT)
player_inv:addContainer("bag", player_bag)

-- Equipment slots (each holds one item of the given type)
local weapon_slot = inventory.newSlot("weapon", "active")
local armor_slot  = inventory.newSlot("armor",  "active")

-- ── 6. Shop (StackManager) ────────────────────────────────────────────────
local shop = item.newStackManager()
local shop_potions = item.newStack("shop_potions")
for i = 1, SHOP_STOCK do
    shop_potions:push(item.newItem("potion"))
end
shop:addStack("potions", shop_potions)

-- ── 7. Player stats ───────────────────────────────────────────────────────
local player = { hp = 100, max_hp = 100, equipped_dmg = 0, equipped_def = 0, coins = 0 }

-- ── Helpers ───────────────────────────────────────────────────────────────
local function add_to_bag(item_obj)
    local inv_item = inventory.newItem(item_obj:getType())
    local weight   = item_obj:getStat("weight")
    inv_item:setWeight(weight)

    local ok, err = pcall(function() player_bag:addItem(inv_item) end)
    if ok then
        local bag_stack = item.newStack("journal_temp")
        bag_stack:push(item_obj)
        pickup_log:recordCustom("bag", "picked_up_"..item_obj:getType(), bag_stack:size())
    end
    return ok
end

local function load_starter()
    local n = starter_gear:size()
    for i = 1, n do
        local it = starter_gear:popTop()
        if it then
            if it:getType() == "coin" then
                player.coins = player.coins + 1
            else
                add_to_bag(it)
            end
        end
    end
end

local function clear_room()
    local drops = math.random(3, 6)
    for i = 1, drops do
        local it = loot_pool:draw()
        if it:getType() == "coin" then
            player.coins = player.coins + 1
        else
            add_to_bag(it)
        end
    end
end

local function auto_equip()
    -- Collect all equippable items from the bag
    local slots_list = player_bag:getSlots()
    local weapons, armors = {}, {}
    for _, slot in ipairs(slots_list) do
        if not slot:isEmpty() then
            local st = slot:getStack()
            if st then
                local it_type = st:getItem():getType()
                local ref_item = item.newItem(it_type)
                if ref_item:hasTag("weapon") then
                    table.insert(weapons, ref_item)
                elseif ref_item:hasTag("armor") then
                    table.insert(armors, ref_item)
                end
            end
        end
    end

    -- Pick best weapon by dmg
    if #weapons > 0 then
        local best = item.findNOfStat(weapons, "dmg", 1)
        if best and best[1] then
            player.equipped_dmg = weapons[best[1]+1]:getStat("dmg")
        end
    end
    -- Pick best armor by def
    if #armors > 0 then
        local best = item.findNOfStat(armors, "def", 1)
        if best and best[1] then
            player.equipped_def = armors[best[1]+1]:getStat("def")
        end
    end
end

local function buy_potion()
    if player.coins < 5 then return false, "not enough coins" end
    local potion = shop:getStack("potions"):pop()
    if not potion then return false, "shop out of stock" end
    player.coins = player.coins - 5
    add_to_bag(potion)
    return true
end

local function use_potion()
    if not player_bag:hasItem("potion") then return false end
    player_bag:removeItem("potion", 1)
    player.hp = math.min(player.max_hp, player.hp + 50)
    return true
end

-- ── lurek.init ─────────────────────────────────────────────────────────────
function lurek.init()
    load_starter()
    lurek.window.setTitle("Loot RPG Demo — item + inventory integration")
end

-- ── lurek.keypressed ───────────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "space" then
        clear_room()
    elseif key == "e" then
        auto_equip()
    elseif key == "b" then
        buy_potion()
    elseif key == "h" then
        use_potion()
    end
end

-- ── lurek.render ─────────────────────────────────────────────────────────────
local function draw_panel(x, y, w, h, title)
    lurek.render.setColor(0.15, 0.12, 0.30, 0.9)
    lurek.render.rectangle("fill", x, y, w, h)
    lurek.render.setColor(0.6, 0.5, 0.9, 1)
    lurek.render.rectangle("line", x, y, w, h)
    lurek.render.setColor(0.9, 0.85, 1.0, 1)
    lurek.render.print(title, x + 8, y + 6)
end

function lurek.render()
    lurek.render.setColor(0.08, 0.06, 0.15, 1)
    lurek.render.rectangle("fill", 0, 0, 800, 600)

    -- ── Player stats panel ────────────────────────────────────────────────
    draw_panel(20, 20, 220, 130, "PLAYER")
    lurek.render.setColor(0.8, 1.0, 0.8, 1)
    lurek.render.print(string.format("HP:  %d / %d", player.hp, player.max_hp),     30, 48)
    lurek.render.print(string.format("ATK: %d  DEF: %d", player.equipped_dmg, player.equipped_def), 30, 68)
    lurek.render.print(string.format("Coins: %d", player.coins),                    30, 88)
    lurek.render.setColor(0.6, 0.6, 0.6, 1)
    lurek.render.print("Bag weight: "..string.format("%.1f", player_bag:getCurrentWeight()).." / "..BAG_WEIGHT_LIMIT, 30, 108)

    -- ── Inventory panel ───────────────────────────────────────────────────
    draw_panel(260, 20, 250, 200, "BACKPACK")
    local slots = player_bag:getSlots()
    lurek.render.setColor(0.85, 0.85, 0.85, 1)
    local y_off = 48
    local shown = 0
    for _, slot in ipairs(slots) do
        if not slot:isEmpty() and shown < 7 then
            local st = slot:getStack()
            if st then
                lurek.render.print("• "..st:getItem():getType(), 270, y_off)
                y_off  = y_off + 20
                shown  = shown + 1
            end
        end
    end
    if shown == 0 then
        lurek.render.setColor(0.5, 0.5, 0.5, 1)
        lurek.render.print("(empty)", 270, 48)
    end

    -- ── Shop panel ────────────────────────────────────────────────────────
    draw_panel(530, 20, 240, 80, "SHOP")
    local remaining = shop:getStack("potions"):size()
    lurek.render.setColor(0.85, 0.85, 0.85, 1)
    lurek.render.print(string.format("Potion x%d  (5 coins)", remaining), 540, 48)
    lurek.render.setColor(0.5, 0.5, 0.5, 1)
    lurek.render.print("[B] buy  [H] use potion", 540, 68)

    -- ── Pickup log panel ──────────────────────────────────────────────────
    draw_panel(20, 170, 720, 150, "RECENT PICKUPS")
    local entries = pickup_log:entries()
    local start   = math.max(1, #entries - 5)
    lurek.render.setColor(0.75, 0.95, 0.75, 1)
    local log_y = 196
    for i = start, #entries do
        local e = entries[i]
        if e then
            lurek.render.print(string.format("[%d] %s  (bag size: %d)", i, e.label, e.size_after), 30, log_y)
            log_y = log_y + 20
        end
    end

    -- ── Controls ──────────────────────────────────────────────────────────
    draw_panel(20, 340, 760, 60, "CONTROLS")
    lurek.render.setColor(0.7, 0.7, 0.9, 1)
    lurek.render.print("[SPACE] clear room  [E] auto-equip best gear  [B] buy potion (5c)  [H] use potion", 30, 366)

    -- ── Item type catalog panel ───────────────────────────────────────────
    draw_panel(20, 420, 760, 160, "ITEM CATALOG  (item.getTypeNames)")
    local names = item.getTypeNames()
    local col_x = 30
    local cat_y = 446
    for i, name in ipairs(names) do
        local def = item.getType(name)
        if def then
            local stats_str = ""
            for k, v in pairs(def.base_stats or {}) do
                stats_str = stats_str..k.."="..tostring(v).." "
            end
            lurek.render.setColor(0.9, 0.85, 0.6, 1)
            lurek.render.print(name, col_x, cat_y)
            lurek.render.setColor(0.6, 0.75, 0.6, 1)
            lurek.render.print(stats_str, col_x + 80, cat_y)
            cat_y = cat_y + 20
            if i == 4 then col_x = 400; cat_y = 446 end
        end
    end
end

