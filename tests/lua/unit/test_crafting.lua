-- Lua BDD tests for lurek.crafting.*
-- @covers lurek.crafting.CraftQueue
-- @covers lurek.crafting.CraftSkill
-- @covers lurek.crafting.ModifierPool
-- @covers lurek.crafting.Recipe
-- @covers lurek.crafting.RecipeGroup
-- @covers lurek.crafting.RecipeKnowledge
-- @covers lurek.crafting.RecipeRegistry
-- @covers lurek.crafting.Station
-- @covers lurek.crafting.UpgradeTree
-- @covers lurek.crafting.newCraftQueue
-- @covers lurek.crafting.newCraftSkill
-- @covers lurek.crafting.newModifierPool
-- @covers lurek.crafting.newRecipe
-- @covers lurek.crafting.newRecipeGroup
-- @covers lurek.crafting.newRecipeKnowledge
-- @covers lurek.crafting.newRegistry
-- @covers lurek.crafting.newStation
-- @covers lurek.crafting.newUpgradeTree


describe("lurek.crafting.Recipe", function()
    it("creates a recipe with id and type", function()
        local r = lurek.crafting.newRecipe("sword", "shaped")
        expect_equal(r:getId(), "sword")
        expect_equal(r:getType(), "shaped")
        expect_equal(r:type(), "Recipe")
    end)

    it("supports category, cooldown, hand_craftable", function()
        local r = lurek.crafting.newRecipe("potion")
        expect_equal(r:getCategory(), "")
        r:setCategory("alchemy")
        expect_equal(r:getCategory(), "alchemy")

        expect_near(r:getCooldown(), 0, 0.001)
        r:setCooldown(3.5)
        expect_near(r:getCooldown(), 3.5, 0.001)

        expect_equal(r:isHandCraftable(), true)
        r:setHandCraftable(false)
        expect_equal(r:isHandCraftable(), false)
    end)

    it("can add and clear ingredients", function()
        local r = lurek.crafting.newRecipe("test")
        r:addIngredient("iron", 3)
        r:addIngredient("wood", 2)
        expect_equal(#r:getIngredients(), 2)
        r:clearIngredients()
        expect_equal(#r:getIngredients(), 0)
    end)

    it("can add and clear outputs", function()
        local r = lurek.crafting.newRecipe("test")
        r:addOutput("sword", 1)
        r:addOutput("scrap", 2)
        expect_equal(#r:getOutputs(), 2)
        r:clearOutputs()
        expect_equal(#r:getOutputs(), 0)
    end)

    it("supports tags", function()
        local r = lurek.crafting.newRecipe("test")
        r:addTag("weapon")
        r:addTag("metal")
        expect_equal(r:hasTag("weapon"), true)
        expect_equal(r:hasTag("food"), false)
        expect_equal(#r:getTags(), 2)
    end)

    it("supports byproducts conditions and progression metadata", function()
        local r = lurek.crafting.newRecipe("elixir")
        r:addOutput("elixir", 1, "excellent")
        r:addByproduct("glass_shard", 2, 0.25)
        r:addCondition("weather", "rain")
        r:addCondition("biome", "swamp")
        r:setOutputQualityScaling(true)
        r:setRandomModifierPool("alchemy_affixes")
        r:setSkillUpCurve("quadratic")

        local outputs = r:getOutputs()
        expect_equal(2, #outputs)
        expect_equal("glass_shard", outputs[2].itemType)
        expect_equal(2, outputs[2].quantity)
        expect_equal("normal", outputs[2].quality)

        local conditions = r:getConditions()
        expect_equal(2, #conditions)
        expect_equal("weather", conditions[1].condType)
        expect_equal("rain", conditions[1].value)
        expect_equal("biome", conditions[2].condType)
        expect_equal("swamp", conditions[2].value)

        expect_equal(true, r:isOutputQualityScaling())
        expect_equal("alchemy_affixes", r:getRandomModifierPool())
        expect_equal("quadratic", r:getSkillUpCurve())
    end)
end)

describe("lurek.crafting.RecipeRegistry", function()
    it("supports register unregister and query helpers", function()
        local reg = lurek.crafting.newRegistry()

        local sword = lurek.crafting.newRecipe("iron_sword")
        sword:setCategory("weapons")
        sword:addIngredient("iron_ingot", 2)

        local soup = lurek.crafting.newRecipe("herb_soup")
        soup:setCategory("food")
        soup:addIngredient("herb", 3)

        reg:register(sword)
        reg:register(soup)

        local by_ingredient = reg:findByIngredient("iron_ingot")
        expect_equal(1, #by_ingredient)
        expect_equal("iron_sword", by_ingredient[1])

        local weapons = reg:getByCategory("weapons")
        expect_equal(1, #weapons)
        expect_equal("iron_sword", weapons[1])

        local all = reg:getAll()
        expect_equal(2, #all)
        expect_equal("Recipe", all[1]:type())
        expect_equal("iron_sword", all[1]:getId())

        expect_equal(true, reg:unregister("iron_sword"))
        expect_equal(nil, reg:get("iron_sword"))
        expect_equal(1, reg:count())
    end)
end)

describe("lurek.crafting.Station", function()
    it("creates with type and level", function()
        local s = lurek.crafting.newStation("forge", 2)
        expect_equal(s:getType(), "forge")
        expect_equal(s:getLevel(), 2)
        expect_equal(s:type(), "Station")
    end)

    it("supports upgrade with max level", function()
        local s = lurek.crafting.newStation("forge", 1)
        s:setMaxLevel(3)
        expect_equal(s:upgrade(), true)
        expect_equal(s:getLevel(), 2)
        expect_equal(s:upgrade(), true)
        expect_equal(s:upgrade(), false) -- at max
        expect_equal(s:getLevel(), 3)
    end)

    it("supports position and proximity", function()
        local s = lurek.crafting.newStation("anvil", 1)
        s:setPosition(50, 50)
        local x, y = s:getPosition()
        expect_near(x, 50, 0.001)
        expect_near(y, 50, 0.001)
        s:setProximityRadius(10)
        expect_equal(s:isInRange(55, 55), true)
        expect_equal(s:isInRange(100, 100), false)
    end)

    it("supports fuel", function()
        local s = lurek.crafting.newStation("furnace", 1)
        s:setFuelCapacity(80)
        expect_near(s:getFuelLevel(), 0, 0.001)
        s:addFuel(50)
        expect_near(s:getFuelLevel(), 50, 0.001)
        s:addFuel(50) -- clamped
        expect_near(s:getFuelLevel(), 80, 0.001)
        expect_equal(s:consumeFuel(30), true)
        expect_near(s:getFuelLevel(), 50, 0.001)
        expect_equal(s:consumeFuel(60), false) -- insufficient
    end)

    it("supports quality bonus and output multiplier", function()
        local s = lurek.crafting.newStation("bench", 1)
        s:setQualityBonus(0.25)
        expect_near(s:getQualityBonus(), 0.25, 0.001)
        s:setOutputMultiplier(2.0)
        expect_near(s:getOutputMultiplier(), 2.0, 0.001)
    end)

    it("supports metadata", function()
        local s = lurek.crafting.newStation("kiln", 1)
        expect_equal(s:getMetadata("color"), nil)
        s:setMetadata("color", "red")
        expect_equal(s:getMetadata("color"), "red")
    end)
end)

describe("lurek.crafting.RecipeKnowledge", function()
    it("creates empty", function()
        local k = lurek.crafting.newRecipeKnowledge()
        expect_equal(k:type(), "RecipeKnowledge")
        expect_equal(k:count(), 0)
    end)

    it("discovers and forgets recipes", function()
        local k = lurek.crafting.newRecipeKnowledge()
        k:discover("sword", "scroll")
        expect_equal(k:isKnown("sword"), true)
        expect_equal(k:getSource("sword"), "scroll")
        expect_equal(k:count(), 1)
        expect_equal(k:forget("sword"), true)
        expect_equal(k:isKnown("sword"), false)
    end)

    it("supports auto discover", function()
        local k = lurek.crafting.newRecipeKnowledge()
        k:setAutoDiscover(true)
        expect_equal(k:isKnown("anything"), true)
        k:setAutoDiscover(false)
        expect_equal(k:isKnown("anything"), false)
    end)

    it("clears all knowledge", function()
        local k = lurek.crafting.newRecipeKnowledge()
        k:discover("a")
        k:discover("b")
        k:clear()
        expect_equal(k:count(), 0)
    end)

    it("supports prototype and research helpers", function()
        local k = lurek.crafting.newRecipeKnowledge()
        expect_equal(true, k:prototype("campfire"))
        expect_equal(false, k:prototype("campfire"))
        expect_equal(true, k:isPrototyped("campfire"))
        expect_equal("prototype", k:getSource("campfire"))

        k:setResearchCost("steel_sword", 120)
        expect_near(120, k:getResearchCost("steel_sword"), 0.001)
        expect_equal(false, k:research("steel_sword", 100))
        expect_equal(false, k:isKnown("steel_sword"))
        expect_equal(true, k:research("steel_sword", 120))
        expect_equal(true, k:isKnown("steel_sword"))
        expect_equal("research", k:getSource("steel_sword"))
    end)
end)

describe("lurek.crafting.RecipeGroup", function()
    it("creates with name", function()
        local g = lurek.crafting.newRecipeGroup("Weapons")
        expect_equal(g:type(), "RecipeGroup")
        expect_equal(g:getName(), "Weapons")
    end)

    it("adds and removes recipes", function()
        local g = lurek.crafting.newRecipeGroup("Swords")
        g:addRecipe("iron_sword")
        g:addRecipe("steel_sword")
        g:addRecipe("iron_sword") -- dup
        expect_equal(g:count(), 2)
        expect_equal(g:contains("iron_sword"), true)
        expect_equal(g:removeRecipe("iron_sword"), true)
        expect_equal(g:contains("iron_sword"), false)
    end)

    it("manages icon and order", function()
        local g = lurek.crafting.newRecipeGroup("Armor")
        g:setIcon("shield.png")
        g:setOrder(3)
        expect_equal(g:getIcon(), "shield.png")
        expect_equal(g:getOrder(), 3)
    end)
end)

describe("lurek.crafting.CraftQueue", function()
    it("enqueues, updates, and collects completed jobs", function()
        local q = lurek.crafting.newCraftQueue(5)
        local id = q:enqueue("plank", 2.0, 1)
        expect_equal(q:count(), 1)
        q:update(3.0) -- finish
        local done = q:collectCompleted()
        expect_equal(#done, 1)
        expect_equal(done[1], id)
        expect_equal(q:count(), 0)
    end)

    it("supports pausing jobs and listing queue state", function()
        local q = lurek.crafting.newCraftQueue(3)
        local id = q:enqueue("ingot", 2.0, 2)

        q:setJobPaused(id, true)
        q:update(1.0)

        local job = q:getJob(id)
        expect_equal(true, job.paused)
        expect_near(0, job.progress, 0.001)

        local jobs = q:getAllJobs()
        expect_equal(1, #jobs)
        expect_equal(true, jobs[1].paused)

        q:setJobPaused(id, false)
        local done = q:update(2.1)
        expect_equal(1, #done)
        expect_equal(id, done[1])

        local collected = q:collectCompleted()
        expect_equal(1, #collected)
        expect_equal(0, q:count())
    end)
end)

describe("lurek.crafting.CraftSkill", function()
    it("tracks xp and levels up", function()
        local s = lurek.crafting.newCraftSkill("smithing")
        expect_equal(s:getName(), "smithing")
        expect_equal(s:getLevel(), 1)
        s:addXp(250) -- threshold for level 2 is 200
        expect_equal(s:getLevel(), 2)
    end)

    it("supports specializations perks bonuses and recipe helpers", function()
        local s = lurek.crafting.newCraftSkill("smithing")
        s:addSpecialization("armorsmith")
        s:addSpecialization("weaponsmith")

        expect_equal(true, s:chooseSpecialization("armorsmith"))
        expect_equal("armorsmith", s:getSpecialization())
        expect_equal(false, s:chooseSpecialization("weaponsmith"))

        s:addPerk("novice", 1)
        s:addPerk("expert", 5, {"novice"})
        expect_equal(true, s:unlockPerk("novice"))
        expect_equal(true, s:hasPerk("novice"))

        s:setLevel(10)
        local available = s:getAvailablePerks()
        local found_expert = false
        for _, perk_id in ipairs(available) do
            if perk_id == "expert" then
                found_expert = true
            end
        end
        expect_equal(true, found_expert)
        expect_equal(true, s:unlockPerk("expert"))

        expect_near(0.045, s:getSpeedBonus(), 0.0001)
        expect_near(0.045, s:getQualityBonus(), 0.0001)
        expect_near(0.018, s:getYieldBonus(), 0.0001)

        local recipe = lurek.crafting.newRecipe("blade")
        expect_equal("grey", s:getRecipeColor(recipe))
        expect_near(0.0, s:skillUpChance(recipe), 0.0001)
    end)
end)

describe("lurek.crafting.UpgradeTree", function()
    it("manages nodes and prerequisites", function()
        local tree = lurek.crafting.newUpgradeTree("weapons")
        tree:addNode("basic", "Basic Forge")
        tree:addNode("adv", "Advanced Forge", {"basic"})
        expect_equal(tree:canUnlock("basic"), true)
        expect_equal(tree:canUnlock("adv"), false) -- prereq not met
        tree:unlock("basic")
        expect_equal(tree:canUnlock("adv"), true)
    end)

    it("supports graph queries and node listing", function()
        local tree = lurek.crafting.newUpgradeTree("weapons")
        tree:addNode("basic", "Basic Forge")
        tree:addNode("tempered", "Tempered Forge", {"basic"})
        tree:addNode("master", "Master Forge", {"tempered"})
        tree:addEdge("basic", "tempered")
        tree:addEdge("tempered", "master")

        local roots = tree:getRootNodes()
        expect_equal(1, #roots)
        expect_equal("basic", roots[1])

        local children = tree:getChildren("basic")
        expect_equal(1, #children)
        expect_equal("tempered", children[1])

        expect_equal("basic", tree:getParent("tempered"))

        local path = tree:getPath("basic", "master")
        expect_equal(3, #path)
        expect_equal("basic", path[1])
        expect_equal("tempered", path[2])
        expect_equal("master", path[3])

        local all_nodes = tree:getAllNodes()
        expect_equal(3, #all_nodes)
        expect_equal("Tempered Forge", tree:getNode("tempered").name)
    end)
end)

describe("lurek.crafting.ModifierPool", function()
    it("tracks modifiers and rolls deterministically", function()
        local pool = lurek.crafting.newModifierPool("rare_affixes")
        pool:addModifier("keen", 2.0, {critChance = 0.1})
        pool:addModifier("heavy", 1.0, {damage = 5})

        expect_equal("rare_affixes", pool:getName())
        expect_equal(2, pool:count())
        expect_near(3.0, pool:getTotalWeight(), 0.0001)

        local modifiers = pool:getModifiers()
        expect_equal(2, #modifiers)
        expect_equal("keen", modifiers[1].name)
        expect_near(0.1, modifiers[1].effects.critChance, 0.0001)

        local roll_a = pool:roll(12345)
        local roll_b = pool:roll(12345)
        expect_not_nil(roll_a)
        expect_not_nil(roll_b)
        expect_equal(roll_a.name, roll_b.name)

        expect_equal(true, pool:removeModifier("heavy"))
        expect_equal(1, pool:count())
    end)
end)

test_summary()
