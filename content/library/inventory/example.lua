--- Example usage for library.inventory.
-- Run from project root with: lua content/library/inventory/example.lua
-- @module example.inventory

package.path = "content/?.lua;content/?/init.lua;" .. package.path
local inventory = require("library.inventory")

print("[example.inventory] === Scenario 1: define items with weight & tags ===")

local potion = inventory.newItem("potion_of_healing")
potion:setWeight(0.2); potion:setStackLimit(20)
potion:addTag("consumable"); potion:addTag("magical")
potion:setProperty("heal", 25)

local sword  = inventory.newItem("iron_sword")
sword:setWeight(4.0); sword:setSize(1, 1); sword:setStackLimit(1)
sword:addTag("weapon"); sword:addTag("melee")

local arrow  = inventory.newItem("arrow")
arrow:setWeight(0.05); arrow:setStackLimit(99)
arrow:addTag("ammo")

print(string.format("  potion tags=%s heal=%d, sword w=%.1fkg",
    table.concat(potion:getTags(), ","),
    potion:getProperty("heal"),
    sword:getWeight()))

print("[example.inventory] === Scenario 2: container add/count/remove ===")

local backpack = inventory.newContainer("Backpack", "expandable", 8, 16)
backpack:setWeightLimit(20)

local p_ok = backpack:addItem(potion, 5)
local a_ok = backpack:addItem(arrow, 50)
local s_ok = backpack:addItem(sword, 1)
print(string.format("  added: potion(5)=%s arrow(50)=%s sword(1)=%s",
    tostring(p_ok), tostring(a_ok), tostring(s_ok)))
print(string.format("  totals: potion=%d arrow=%d sword=%d, weight=%.2f/%.0f",
    backpack:countItem("potion_of_healing"),
    backpack:countItem("arrow"),
    backpack:countItem("iron_sword"),
    backpack:getCurrentWeight(), backpack:getWeightLimit()))

backpack:removeItem("potion_of_healing", 2)
print(string.format("  after consuming 2 potions: %d left",
    backpack:countItem("potion_of_healing")))

print("[example.inventory] === Scenario 3: tag-search ===")

local found = backpack:findByTag("ammo")
print(string.format("  ammo-tagged item types: %d", #found))
for _, item in ipairs(found) do
    print(string.format("    %s (weight=%.2f, stack_limit=%d)",
        item:getType(), item:getWeight(), item:getStackLimit()))
end

print("[example.inventory] === Scenario 4: top-level Inventory + equip slots ===")

local inv = inventory.newInventory()
inv:addContainer("backpack", backpack)
inv:addEquipSlot("main_hand", inventory.newSlot("weapon", inventory.SlotState.Active))

-- Equip a freshly-built stack of the sword into the main_hand slot.
local sword_stack = inventory.newItemStack(sword, 1, 1)
local equipped = inv:equip("main_hand", sword_stack)
print(string.format("  equipped sword in main_hand: %s", tostring(equipped)))
print(string.format("  total iron_sword across inventory: %d", inv:countItem("iron_sword")))

print("[example.inventory] === Scenario 5: optional event bus (lurek.patterns) ===")

local bus = inv:getEventBus()
if bus then
    bus:on("loot_picked", function(item, qty)
        print(string.format("  [bus] looted %dx %s", qty, item))
    end)
    bus:emit("loot_picked", "arrow", 12)
else
    print("  no lurek.patterns.newEventBus — bus mode disabled (pure-Lua run)")
end

print("[example.inventory] === Scenario 6: codec round-trip of stack snapshot ===")

local ok_codec, codec = pcall(require, "lurek.serial")
if ok_codec and codec and codec.toJson then
    local snap = {
        potions = backpack:countItem("potion_of_healing"),
        arrows  = backpack:countItem("arrow"),
        weight  = backpack:getCurrentWeight(),
    }
    local s = codec.toJson(snap)
    print("  codec.toJson: " .. s)
    if codec.fromJson then
        local t = codec.fromJson(s)
        print(string.format("  fromJson.potions=%s arrows=%s",
            tostring(t.potions), tostring(t.arrows)))
    end
else
    print(string.format("  no lurek.serial — snapshot: potions=%d arrows=%d weight=%.2f",
        backpack:countItem("potion_of_healing"),
        backpack:countItem("arrow"),
        backpack:getCurrentWeight()))
end

print("[example.inventory] done.")
