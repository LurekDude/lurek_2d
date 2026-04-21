--- Example usage for library.crafting.
-- Run from project root with: lua content/library/crafting/example.lua
-- @module example.crafting

package.path = "content/?.lua;content/?/init.lua;" .. package.path
local crafting = require("library.crafting")

print("[example.crafting] === Scenario 1: build recipes & ingredients ===")

local sword = crafting.newRecipe("iron_sword")
sword.name        = "Iron Sword"
sword.category    = "weapon"
sword.station_type = "anvil"
sword.station_level = 1
sword.skill        = "smithing"
sword.skill_level  = 5
sword.skill_xp     = 25
sword.time         = 4.0
sword:addIngredient(crafting.newIngredient("iron_ingot", 2))
sword:addIngredient(crafting.newIngredient("wood",       1))
sword:addOutput(crafting.newRecipeOutput("iron_sword", 1))
sword:addByproduct("iron_scrap", 1, 0.25)
sword.tags[#sword.tags+1] = "starter"

local stew = crafting.newRecipe("hearty_stew")
stew.station_type = "campfire"
stew.time         = 6.0
stew:addIngredient(crafting.newIngredientTag("meat", 2))   -- any meat works
stew:addIngredient(crafting.newIngredient("herb", 1))
stew:addOutput(crafting.newRecipeOutputWithChance("hearty_stew", 1, 1.0))
stew.tags[#stew.tags+1] = "food"

print(string.format("  sword has %d ingredients, %d outputs (1 byproduct)",
    #sword.ingredients, #sword.outputs))

print("[example.crafting] === Scenario 2: registry lookup ===")

local registry = crafting.newRecipeRegistry()
registry:add(sword)
registry:add(stew)
print(string.format("  registry count=%d", registry:count()))

local anvil_recipes = registry:forStation("anvil")
print(string.format("  recipes craftable at anvil: %d", #anvil_recipes))

local food_recipes = registry:findByTag("food")
print(string.format("  food-tagged: %d  (%s)",
    #food_recipes, food_recipes[1] and food_recipes[1].id or "none"))

local uses_iron = registry:findByIngredient("iron_ingot")
print(string.format("  recipes that use iron_ingot: %d", #uses_iron))

print("[example.crafting] === Scenario 3: station with fuel & modules ===")

local forge = crafting.newStation("Old Forge", "anvil")
forge:addFuel(60)
forge:addModule("bellows")
forge:addModule("anvil_block")
forge:setStat("heat", 1200)
print(string.format("  fuel=%d/%d (%.0f%%), modules=%d, heat=%d",
    forge.fuel, forge.max_fuel, forge:fuelPercent() * 100,
    #forge.modules, forge:getStat("heat")))

if forge:consumeFuel(15) then
    print(string.format("  consumed 15 fuel, remaining=%d", forge.fuel))
end

print("[example.crafting] === Scenario 4: skill xp & level up ===")

local smithing = crafting.newCraftSkill("smithing")
smithing.xp_curve = "linear"
print(string.format("  start: lv=%d xp=%d", smithing.level, smithing.xp))

-- Add xp through several "crafts"
for _ = 1, 5 do
    smithing.xp = smithing.xp + sword.skill_xp
end
print(string.format("  after 5 crafts: lv=%d xp=%d perks=%d",
    smithing.level, smithing.xp, smithing.perk_points))

print("[example.crafting] === Scenario 5: shaped grid recipe ===")

local axe = crafting.newRecipe("stone_axe")
axe.grid_width  = 3
axe.grid_height = 3
axe:setGridSlot(0, 0, "stone")
axe:setGridSlot(1, 0, "stone")
axe:setGridSlot(1, 1, "stick")
axe:setGridSlot(1, 2, "stick")
axe:addOutput(crafting.newRecipeOutput("stone_axe", 1))
print(string.format("  shaped axe grid=%dx%d slots=%d",
    axe.grid_width, axe.grid_height,
    (function() local n = 0 for _ in pairs(axe.grid_slots) do n = n + 1 end return n end)()))

print("[example.crafting] === Scenario 6: serialise registry to JSON if codec is loadable ===")

local ok_codec, codec = pcall(require, "lurek.serial")
if ok_codec and codec and codec.toJson then
    local minimal = { ids = registry:ids(), count = registry:count() }
    print("  codec.toJson: " .. codec.toJson(minimal))
else
    print(string.format("  no lurek.serial — registry ids: %s",
        table.concat(registry:ids(), ", ")))
end

print("[example.crafting] done.")
