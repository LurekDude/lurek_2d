--- Example usage for library.item.
-- Run with: lua content/library/item/example.lua
-- Demonstrates item type registration, item instances, stacks, builders,
-- weighted pools, cloning, and history tracking.
-- @module example.item

local M = require("library.item")

-- ── 1. Register item types ────────────────────────────────────────────────────
M.clearTypes()

M.defineType("sword", {
    category   = "weapon",
    base_stats = { attack = 10, weight = 3 },
    base_tags  = { "metal", "edged" },
})
M.defineType("potion", {
    category   = "consumable",
    base_stats = { heal = 25, weight = 1 },
    base_tags  = { "magic" },
})
M.defineType("shield", {
    category   = "armor",
    base_stats = { defense = 8, weight = 5 },
    base_tags  = { "metal" },
})

print(string.format("[example.item] registered %d types: %s",
    #M.getTypeNames(), table.concat(M.getTypeNames(), ", ")))

-- ── 2. Create item instances and tweak stats/tags ─────────────────────────────
local sword = M.newItem("sword")
sword:setStat("attack", sword:getStat("attack") + 5)  -- enchanted +5
sword:addTag("enchanted")
sword:setName("Flameblade")

print(string.format("[example.item] %s attack=%d tags=[%s]",
    sword:getName(), sword:getStat("attack"), table.concat(sword:getTags(), ",")))

-- ── 3. Clone an item ──────────────────────────────────────────────────────────
local twin = sword:clone()
twin:setName("Frostblade")
twin:removeTag("enchanted")
print(string.format("[example.item] clone -> %s tags=[%s]",
    twin:getName(), table.concat(twin:getTags(), ",")))

-- ── 4. Stack: push / peek / pop / sort ────────────────────────────────────────
local backpack = M.newStack("backpack", 8)
backpack:push(sword)
backpack:push(M.newItem("potion"))
backpack:push(M.newItem("shield"))
backpack:push(M.newItem("potion"))

print(string.format("[example.item] backpack size=%d capacity=%d",
    backpack:size(), backpack:getCapacity()))
print(string.format("[example.item] potions in backpack: %d",
    backpack:countByType("potion")))

backpack:sortByName()
local top = backpack:peek()
print(string.format("[example.item] after sortByName, top item type='%s'",
    top:getType()))

-- ── 5. StackBuilder: declarative stack construction ───────────────────────────
local builder = M.newStackBuilder()
builder:add("sword", 1)
builder:add("potion", 3)
builder:add("shield", 2)
builder:setShuffleOnBuild(false)
local loadout = builder:build("loadout")
print(string.format("[example.item] builder produced stack '%s' with %d items",
    loadout:getName(), loadout:size()))

-- ── 6. Weighted item pool ─────────────────────────────────────────────────────
math.randomseed(42)  -- deterministic for the demo
local pool = M.newItemPool()
pool:addType("sword",  1)
pool:addType("potion", 5)
pool:addType("shield", 2)

local rolls = {}
for i = 1, 10 do
    rolls[i] = pool:draw()
end
print(string.format("[example.item] pool total weight=%d, 10 draws: %s",
    pool:totalWeight(), table.concat(rolls, ",")))

-- ── 7. Stack history tracking ─────────────────────────────────────────────────
local hist = M.newStackHistory(20)
hist:recordPush("backpack", "sword",  1)
hist:recordPush("backpack", "potion", 2)
hist:recordPop ("backpack", "potion", 1)
print(string.format("[example.item] history actions known: %s",
    table.concat({ M.HistoryAction.Push, M.HistoryAction.Pop, M.HistoryAction.Clear }, ",")))
print(string.format("[example.item] history entries=%d, last action=%s",
    hist:count(), hist:last().action))

print("[example.item] done.")
