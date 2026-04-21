-- Lua BDD tests for lurek.crafting.*

-- @description Covers suite: lurek.crafting.Recipe.
describe("lurek.crafting.Recipe", function()
    -- @tests lurek.crafting.newRecipe
    -- @tests lurek.crafting.Recipe.getId
    -- @tests lurek.crafting.Recipe.getType
    -- @tests lurek.crafting.Recipe.type
    -- @tests lurek.crafting.CraftQueue
    -- @tests lurek.crafting.CraftSkill
    -- @tests lurek.crafting.ModifierPool
    -- @tests lurek.crafting.Recipe
    -- @tests lurek.crafting.RecipeGroup
    -- @tests lurek.crafting.RecipeKnowledge
    -- @tests lurek.crafting.RecipeRegistry
    -- @tests lurek.crafting.Station
    -- @tests lurek.crafting.UpgradeTree
    -- @tests lurek.crafting.newCraftQueue
    -- @tests lurek.crafting.newCraftSkill
    -- @tests lurek.crafting.newModifierPool
    -- @tests lurek.crafting.newRecipeGroup
    -- @tests lurek.crafting.newRecipeKnowledge
    -- @tests lurek.crafting.newRegistry
    -- @tests lurek.crafting.newStation
    -- @tests lurek.crafting.newUpgradeTree
    -- @description Verifies newRecipe() initializes recipe identity, recipe type, and userdata type metadata.
    it("creates a recipe with id and type", function()
        local r = lurek.crafting.newRecipe("sword", "shaped")
        expect_equal(r:getId(), "sword")
        expect_equal(r:getType(), "shaped")
        expect_equal(r:type(), "Recipe")
    end)

    -- @tests lurek.crafting.newRecipe
    -- @tests lurek.crafting.Recipe.getCategory
    -- @tests lurek.crafting.Recipe.setCategory
    -- @tests lurek.crafting.Recipe.getCooldown
    -- @tests lurek.crafting.Recipe.setCooldown
    -- @tests lurek.crafting.Recipe.isHandCraftable
    -- @tests lurek.crafting.Recipe.setHandCraftable
    -- @description Confirms recipe category, cooldown, and hand-craftable flags round-trip through their accessors.
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

    -- @tests lurek.crafting.newRecipe
    -- @tests lurek.crafting.Recipe.addIngredient
    -- @tests lurek.crafting.Recipe.getIngredients
    -- @tests lurek.crafting.Recipe.clearIngredients
    -- @description Verifies ingredient entries can be added and then cleared from a recipe.
    it("can add and clear ingredients", function()
        local r = lurek.crafting.newRecipe("test")
        r:addIngredient("iron", 3)
        r:addIngredient("wood", 2)
        expect_equal(#r:getIngredients(), 2)
        r:clearIngredients()
        expect_equal(#r:getIngredients(), 0)
    end)

    -- @tests lurek.crafting.newRecipe
    -- @tests lurek.crafting.Recipe.addOutput
    -- @tests lurek.crafting.Recipe.getOutputs
    -- @tests lurek.crafting.Recipe.clearOutputs
    -- @description Verifies output entries can be added and then cleared from a recipe.
    it("can add and clear outputs", function()
        local r = lurek.crafting.newRecipe("test")
        r:addOutput("sword", 1)
        r:addOutput("scrap", 2)
        expect_equal(#r:getOutputs(), 2)
        r:clearOutputs()
        expect_equal(#r:getOutputs(), 0)
    end)

    -- @tests lurek.crafting.newRecipe
    -- @tests lurek.crafting.Recipe.addTag
    -- @tests lurek.crafting.Recipe.hasTag
    -- @tests lurek.crafting.Recipe.getTags
    -- @description Confirms recipe tags can be stored, queried, and listed.
    it("supports tags", function()
        local r = lurek.crafting.newRecipe("test")
        r:addTag("weapon")
        r:addTag("metal")
        expect_equal(r:hasTag("weapon"), true)
        expect_equal(r:hasTag("food"), false)
        expect_equal(#r:getTags(), 2)
    end)

    -- @tests lurek.crafting.newRecipe
    -- @tests lurek.crafting.Recipe.addOutput
    -- @tests lurek.crafting.Recipe.addByproduct
    -- @tests lurek.crafting.Recipe.addCondition
    -- @tests lurek.crafting.Recipe.setOutputQualityScaling
    -- @tests lurek.crafting.Recipe.isOutputQualityScaling
    -- @tests lurek.crafting.Recipe.setRandomModifierPool
    -- @tests lurek.crafting.Recipe.getRandomModifierPool
    -- @tests lurek.crafting.Recipe.setSkillUpCurve
    -- @tests lurek.crafting.Recipe.getSkillUpCurve
    -- @tests lurek.crafting.Recipe.getOutputs
    -- @tests lurek.crafting.Recipe.getConditions
    -- @description Verifies advanced recipe metadata including byproducts, conditions, quality scaling, modifier pools, and skill-up curves.
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

-- @description Covers suite: lurek.crafting.RecipeRegistry.
describe("lurek.crafting.RecipeRegistry", function()
    -- @tests lurek.crafting.newRegistry
    -- @tests lurek.crafting.newRecipe
    -- @tests lurek.crafting.Recipe.setCategory
    -- @tests lurek.crafting.Recipe.addIngredient
    -- @tests lurek.crafting.RecipeRegistry.register
    -- @tests lurek.crafting.RecipeRegistry.findByIngredient
    -- @tests lurek.crafting.RecipeRegistry.getByCategory
    -- @tests lurek.crafting.RecipeRegistry.getAll
    -- @tests lurek.crafting.RecipeRegistry.unregister
    -- @tests lurek.crafting.RecipeRegistry.get
    -- @tests lurek.crafting.RecipeRegistry.count
    -- @description Confirms the recipe registry can register recipes, query them by ingredient and category, and unregister them cleanly.
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

-- @description Covers suite: lurek.crafting.Station.
describe("lurek.crafting.Station", function()
    -- @tests lurek.crafting.newStation
    -- @tests lurek.crafting.Station.getType
    -- @tests lurek.crafting.Station.getLevel
    -- @tests lurek.crafting.Station.type
    -- @description Verifies newStation() stores its station type, starting level, and userdata type name.
    it("creates with type and level", function()
        local s = lurek.crafting.newStation("forge", 2)
        expect_equal(s:getType(), "forge")
        expect_equal(s:getLevel(), 2)
        expect_equal(s:type(), "Station")
    end)

    -- @tests lurek.crafting.newStation
    -- @tests lurek.crafting.Station.setMaxLevel
    -- @tests lurek.crafting.Station.upgrade
    -- @tests lurek.crafting.Station.getLevel
    -- @description Confirms station upgrades stop once the configured maximum level is reached.
    it("supports upgrade with max level", function()
        local s = lurek.crafting.newStation("forge", 1)
        s:setMaxLevel(3)
        expect_equal(s:upgrade(), true)
        expect_equal(s:getLevel(), 2)
        expect_equal(s:upgrade(), true)
        expect_equal(s:upgrade(), false) -- at max
        expect_equal(s:getLevel(), 3)
    end)

    -- @tests lurek.crafting.newStation
    -- @tests lurek.crafting.Station.setPosition
    -- @tests lurek.crafting.Station.getPosition
    -- @tests lurek.crafting.Station.setProximityRadius
    -- @tests lurek.crafting.Station.isInRange
    -- @description Verifies station position and proximity radius drive range checks correctly.
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

    -- @tests lurek.crafting.newStation
    -- @tests lurek.crafting.Station.setFuelCapacity
    -- @tests lurek.crafting.Station.getFuelLevel
    -- @tests lurek.crafting.Station.addFuel
    -- @tests lurek.crafting.Station.consumeFuel
    -- @description Confirms station fuel storage clamps to capacity and prevents over-consumption.
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

    -- @tests lurek.crafting.newStation
    -- @tests lurek.crafting.Station.setQualityBonus
    -- @tests lurek.crafting.Station.getQualityBonus
    -- @tests lurek.crafting.Station.setOutputMultiplier
    -- @tests lurek.crafting.Station.getOutputMultiplier
    -- @description Verifies station quality and output multipliers round-trip through their accessors.
    it("supports quality bonus and output multiplier", function()
        local s = lurek.crafting.newStation("bench", 1)
        s:setQualityBonus(0.25)
        expect_near(s:getQualityBonus(), 0.25, 0.001)
        s:setOutputMultiplier(2.0)
        expect_near(s:getOutputMultiplier(), 2.0, 0.001)
    end)

    -- @tests lurek.crafting.newStation
    -- @tests lurek.crafting.Station.getMetadata
    -- @tests lurek.crafting.Station.setMetadata
    -- @description Confirms arbitrary station metadata keys can be stored and retrieved.
    it("supports metadata", function()
        local s = lurek.crafting.newStation("kiln", 1)
        expect_equal(s:getMetadata("color"), nil)
        s:setMetadata("color", "red")
        expect_equal(s:getMetadata("color"), "red")
    end)
end)

-- @description Covers suite: lurek.crafting.RecipeKnowledge.
describe("lurek.crafting.RecipeKnowledge", function()
    -- @tests lurek.crafting.newRecipeKnowledge
    -- @tests lurek.crafting.RecipeKnowledge.type
    -- @tests lurek.crafting.RecipeKnowledge.count
    -- @description Verifies a new recipe knowledge store starts empty and reports its userdata type.
    it("creates empty", function()
        local k = lurek.crafting.newRecipeKnowledge()
        expect_equal(k:type(), "RecipeKnowledge")
        expect_equal(k:count(), 0)
    end)

    -- @tests lurek.crafting.newRecipeKnowledge
    -- @tests lurek.crafting.RecipeKnowledge.discover
    -- @tests lurek.crafting.RecipeKnowledge.isKnown
    -- @tests lurek.crafting.RecipeKnowledge.getSource
    -- @tests lurek.crafting.RecipeKnowledge.count
    -- @tests lurek.crafting.RecipeKnowledge.forget
    -- @description Confirms recipe discovery stores the source and can later be forgotten.
    it("discovers and forgets recipes", function()
        local k = lurek.crafting.newRecipeKnowledge()
        k:discover("sword", "scroll")
        expect_equal(k:isKnown("sword"), true)
        expect_equal(k:getSource("sword"), "scroll")
        expect_equal(k:count(), 1)
        expect_equal(k:forget("sword"), true)
        expect_equal(k:isKnown("sword"), false)
    end)

    -- @tests lurek.crafting.newRecipeKnowledge
    -- @tests lurek.crafting.RecipeKnowledge.setAutoDiscover
    -- @tests lurek.crafting.RecipeKnowledge.isKnown
    -- @description Verifies auto-discovery mode makes any recipe appear known until it is disabled again.
    it("supports auto discover", function()
        local k = lurek.crafting.newRecipeKnowledge()
        k:setAutoDiscover(true)
        expect_equal(k:isKnown("anything"), true)
        k:setAutoDiscover(false)
        expect_equal(k:isKnown("anything"), false)
    end)

    -- @tests lurek.crafting.newRecipeKnowledge
    -- @tests lurek.crafting.RecipeKnowledge.discover
    -- @tests lurek.crafting.RecipeKnowledge.clear
    -- @tests lurek.crafting.RecipeKnowledge.count
    -- @description Confirms clear() removes all remembered recipe knowledge entries.
    it("clears all knowledge", function()
        local k = lurek.crafting.newRecipeKnowledge()
        k:discover("a")
        k:discover("b")
        k:clear()
        expect_equal(k:count(), 0)
    end)

    -- @tests lurek.crafting.newRecipeKnowledge
    -- @tests lurek.crafting.RecipeKnowledge.prototype
    -- @tests lurek.crafting.RecipeKnowledge.isPrototyped
    -- @tests lurek.crafting.RecipeKnowledge.getSource
    -- @tests lurek.crafting.RecipeKnowledge.setResearchCost
    -- @tests lurek.crafting.RecipeKnowledge.getResearchCost
    -- @tests lurek.crafting.RecipeKnowledge.research
    -- @tests lurek.crafting.RecipeKnowledge.isKnown
    -- @description Verifies prototype tracking and research-cost progression both unlock recipes through the knowledge store.
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

-- @description Covers suite: lurek.crafting.RecipeGroup.
describe("lurek.crafting.RecipeGroup", function()
    -- @tests lurek.crafting.newRecipeGroup
    -- @tests lurek.crafting.RecipeGroup.type
    -- @tests lurek.crafting.RecipeGroup.getName
    -- @description Verifies newRecipeGroup() stores the group name and exposes the expected userdata type.
    it("creates with name", function()
        local g = lurek.crafting.newRecipeGroup("Weapons")
        expect_equal(g:type(), "RecipeGroup")
        expect_equal(g:getName(), "Weapons")
    end)

    -- @tests lurek.crafting.newRecipeGroup
    -- @tests lurek.crafting.RecipeGroup.addRecipe
    -- @tests lurek.crafting.RecipeGroup.count
    -- @tests lurek.crafting.RecipeGroup.contains
    -- @tests lurek.crafting.RecipeGroup.removeRecipe
    -- @description Confirms recipe groups de-duplicate entries, report membership, and allow removal.
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

    -- @tests lurek.crafting.newRecipeGroup
    -- @tests lurek.crafting.RecipeGroup.setIcon
    -- @tests lurek.crafting.RecipeGroup.getIcon
    -- @tests lurek.crafting.RecipeGroup.setOrder
    -- @tests lurek.crafting.RecipeGroup.getOrder
    -- @description Verifies recipe group icon and ordering metadata round-trip through their accessors.
    it("manages icon and order", function()
        local g = lurek.crafting.newRecipeGroup("Armor")
        g:setIcon("shield.png")
        g:setOrder(3)
        expect_equal(g:getIcon(), "shield.png")
        expect_equal(g:getOrder(), 3)
    end)
end)

-- @description Covers suite: lurek.crafting.CraftQueue.
describe("lurek.crafting.CraftQueue", function()
    -- @tests lurek.crafting.newCraftQueue
    -- @tests lurek.crafting.CraftQueue.enqueue
    -- @tests lurek.crafting.CraftQueue.count
    -- @tests lurek.crafting.CraftQueue.update
    -- @tests lurek.crafting.CraftQueue.collectCompleted
    -- @description Confirms craft queue jobs complete after enough simulated time and can be collected from the finished list.
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

    -- @tests lurek.crafting.newCraftQueue
    -- @tests lurek.crafting.CraftQueue.enqueue
    -- @tests lurek.crafting.CraftQueue.setJobPaused
    -- @tests lurek.crafting.CraftQueue.update
    -- @tests lurek.crafting.CraftQueue.getJob
    -- @tests lurek.crafting.CraftQueue.getAllJobs
    -- @tests lurek.crafting.CraftQueue.collectCompleted
    -- @tests lurek.crafting.CraftQueue.count
    -- @description Verifies pausing a craft job halts progress, and resuming it allows completion and collection.
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

-- @description Covers suite: lurek.crafting.CraftSkill.
describe("lurek.crafting.CraftSkill", function()
    -- @tests lurek.crafting.newCraftSkill
    -- @tests lurek.crafting.CraftSkill.getName
    -- @tests lurek.crafting.CraftSkill.getLevel
    -- @tests lurek.crafting.CraftSkill.addXp
    -- @description Confirms craft skills track XP and level up once they cross the configured threshold.
    it("tracks xp and levels up", function()
        local s = lurek.crafting.newCraftSkill("smithing")
        expect_equal(s:getName(), "smithing")
        expect_equal(s:getLevel(), 1)
        s:addXp(250) -- threshold for level 2 is 200
        expect_equal(s:getLevel(), 2)
    end)

    -- @tests lurek.crafting.newCraftSkill
    -- @tests lurek.crafting.CraftSkill.addSpecialization
    -- @tests lurek.crafting.CraftSkill.chooseSpecialization
    -- @tests lurek.crafting.CraftSkill.getSpecialization
    -- @tests lurek.crafting.CraftSkill.addPerk
    -- @tests lurek.crafting.CraftSkill.unlockPerk
    -- @tests lurek.crafting.CraftSkill.hasPerk
    -- @tests lurek.crafting.CraftSkill.setLevel
    -- @tests lurek.crafting.CraftSkill.getAvailablePerks
    -- @tests lurek.crafting.CraftSkill.getSpeedBonus
    -- @tests lurek.crafting.CraftSkill.getQualityBonus
    -- @tests lurek.crafting.CraftSkill.getYieldBonus
    -- @tests lurek.crafting.newRecipe
    -- @tests lurek.crafting.CraftSkill.getRecipeColor
    -- @tests lurek.crafting.CraftSkill.skillUpChance
    -- @description Verifies craft skills enforce specialization locking, perk prerequisites, derived bonuses, and recipe helper queries.
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

-- @description Covers suite: lurek.crafting.UpgradeTree.
describe("lurek.crafting.UpgradeTree", function()
    -- @tests lurek.crafting.newUpgradeTree
    -- @tests lurek.crafting.UpgradeTree.addNode
    -- @tests lurek.crafting.UpgradeTree.canUnlock
    -- @tests lurek.crafting.UpgradeTree.unlock
    -- @description Confirms upgrade tree prerequisites gate node unlocks until their required nodes are unlocked.
    it("manages nodes and prerequisites", function()
        local tree = lurek.crafting.newUpgradeTree("weapons")
        tree:addNode("basic", "Basic Forge")
        tree:addNode("adv", "Advanced Forge", {"basic"})
        expect_equal(tree:canUnlock("basic"), true)
        expect_equal(tree:canUnlock("adv"), false) -- prereq not met
        tree:unlock("basic")
        expect_equal(tree:canUnlock("adv"), true)
    end)

    -- @tests lurek.crafting.newUpgradeTree
    -- @tests lurek.crafting.UpgradeTree.addNode
    -- @tests lurek.crafting.UpgradeTree.addEdge
    -- @tests lurek.crafting.UpgradeTree.getRootNodes
    -- @tests lurek.crafting.UpgradeTree.getChildren
    -- @tests lurek.crafting.UpgradeTree.getParent
    -- @tests lurek.crafting.UpgradeTree.getPath
    -- @tests lurek.crafting.UpgradeTree.getAllNodes
    -- @tests lurek.crafting.UpgradeTree.getNode
    -- @description Verifies upgrade tree graph traversal helpers expose roots, children, parents, paths, and stored node metadata.
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

-- @description Covers suite: lurek.crafting.ModifierPool.
describe("lurek.crafting.ModifierPool", function()
    -- @tests lurek.crafting.newModifierPool
    -- @tests lurek.crafting.ModifierPool.addModifier
    -- @tests lurek.crafting.ModifierPool.getName
    -- @tests lurek.crafting.ModifierPool.count
    -- @tests lurek.crafting.ModifierPool.getTotalWeight
    -- @tests lurek.crafting.ModifierPool.getModifiers
    -- @tests lurek.crafting.ModifierPool.roll
    -- @tests lurek.crafting.ModifierPool.removeModifier
    -- @description Verifies modifier pools track weights, expose modifier data, roll deterministically with a seed, and support removal.
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
