--- BDD tests for library.crafting
--- Matches coverage of src/crafting/ Rust tests.

require("tests.lua.init")
local C = require("library.crafting")

-- â”€â”€ Quality â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Checks quality tier constants and string parsing for valid and invalid quality names.
describe("Quality", function()
    -- @covers library.crafting.Quality
    -- @covers library.crafting.qualityFromStr
    -- @description Checks the exported quality enum includes the expected lowest and highest tier constants.
    it("has six tiers", function()
        expect_equal(C.Quality.Normal, "normal")
        expect_equal(C.Quality.Legendary, "legendary")
    end)

    -- @covers library.crafting.qualityFromStr
    -- @description Verifies quality strings round-trip for valid inputs and return nil for unknown names.
    it("fromStr round-trips", function()
        expect_equal(C.qualityFromStr("fine"), "fine")
        expect_equal(C.qualityFromStr("nope"), nil)
    end)
end)

-- â”€â”€ Ingredient â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies direct item ingredients and tag-based ingredients preserve quantity, consumed flags, and tag detection semantics.
describe("Ingredient", function()
    -- @covers library.crafting.newIngredient
    -- @covers library.crafting.newIngredientTag
    -- @description Confirms item-based ingredients keep the supplied item type, quantity, consumed flag, and non-tag classification.
    it("by item type", function()
        local ing = C.newIngredient("wood", 3)
        expect_equal(ing.item_type, "wood")
        expect_equal(ing.quantity, 3)
        expect_equal(ing.consumed, true)
        expect_equal(ing:isTag(), false)
    end)

    -- @covers library.crafting.newIngredientTag
    -- @description Confirms tag-based ingredients store the tag name and report themselves as tag selectors.
    it("by tag", function()
        local ing = C.newIngredientTag("metal", 2)
        expect_equal(ing.tag, "metal")
        expect_equal(ing:isTag(), true)
    end)
end)

-- â”€â”€ RecipeOutput â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers crafted output defaults, optional chance-based outputs, and chance clamping for overlarge probabilities.
describe("RecipeOutput", function()
    -- @covers library.crafting.newRecipeOutput
    -- @covers library.crafting.newRecipeOutputWithChance
    -- @description Checks default recipe outputs seed type, quantity, normal quality, full chance, and non-byproduct state.
    it("default output", function()
        local o = C.newRecipeOutput("sword", 1)
        expect_equal(o.item_type, "sword")
        expect_equal(o.quantity, 1)
        expect_equal(o.quality, C.Quality.Normal)
        expect_near(o.chance, 1.0, 0.01)
        expect_equal(o.is_byproduct, false)
    end)

    -- @covers library.crafting.newRecipeOutputWithChance
    -- @description Verifies chance-based outputs preserve an in-range probability value when one is provided explicitly.
    it("with chance", function()
        local o = C.newRecipeOutputWithChance("gem", 1, 0.5)
        expect_near(o.chance, 0.5, 0.01)
    end)

    -- @covers library.crafting.newRecipeOutputWithChance
    -- @description Ensures chance-based outputs clamp oversized probabilities back to the supported 0 to 1 range.
    it("clamps chance to 0..1", function()
        local o = C.newRecipeOutputWithChance("gem", 1, 2.5)
        expect_near(o.chance, 1.0, 0.01)
    end)
end)

-- â”€â”€ Recipe â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests recipe construction, ingredient and output mutation, tags, grid slots, byproducts, and condition attachment helpers.
describe("Recipe", function()
    -- @covers library.crafting.newRecipe
    -- @description Verifies newly created recipes expose the expected identifiers, enabled flags, hand-crafting setting, and default craft time.
    it("creates with defaults", function()
        local r = C.newRecipe("iron_sword")
        expect_equal(r.id, "iron_sword")
        expect_equal(r.name, "iron_sword")
        expect_equal(r.enabled, true)
        expect_equal(r.hand_craftable, true)
        expect_near(r.time, 1.0, 0.01)
    end)

    -- @covers library.crafting.newRecipe
    -- @description Checks recipes can accumulate multiple ingredients and then clear the ingredient list completely.
    it("add/clear ingredients", function()
        local r = C.newRecipe("blade")
        r:addIngredient(C.newIngredient("iron", 2))
        r:addIngredient(C.newIngredient("wood", 1))
        expect_equal(#r.ingredients, 2)
        r:clearIngredients()
        expect_equal(#r.ingredients, 0)
    end)

    -- @covers library.crafting.newRecipe
    -- @description Confirms recipes can add outputs and later remove all outputs through the clear helper.
    it("add/clear outputs", function()
        local r = C.newRecipe("blade")
        r:addOutput(C.newRecipeOutput("sword", 1))
        expect_equal(#r.outputs, 1)
        r:clearOutputs()
        expect_equal(#r.outputs, 0)
    end)

    -- @covers library.crafting.newRecipe
    -- @description Verifies recipe tag membership checks and tag enumeration return the expected stored values.
    it("tags", function()
        local r = C.newRecipe("blade")
        r.tags = { "weapon", "melee" }
        expect_equal(r:hasTag("weapon"), true)
        expect_equal(r:hasTag("ranged"), false)
        expect_equal(#r:getTags(), 2)
    end)

    -- @covers library.crafting.newRecipe
    -- @description Confirms shaped recipes can assign item types into specific grid slots.
    it("grid slots", function()
        local r = C.newRecipe("shaped")
        r.grid_width = 3
        r.grid_height = 3
        r:setGridSlot(1, 0, "iron")
        expect_equal(r.grid_slots[1], "iron")
    end)

    -- @covers library.crafting.newRecipe
    -- @description Checks recipes can append byproducts with byproduct flags and custom drop chances.
    it("add byproduct", function()
        local r = C.newRecipe("smelt")
        r:addByproduct("slag", 1, 0.3)
        expect_equal(#r.outputs, 1)
        expect_equal(r.outputs[1].is_byproduct, true)
        expect_near(r.outputs[1].chance, 0.3, 0.01)
    end)

    -- @covers library.crafting.newRecipe
    -- @description Verifies recipes can store structured crafting conditions and return them through getConditions.
    it("conditions", function()
        local r = C.newRecipe("enchant")
        r:addCondition("time_of_day", "night")
        local conds = r:getConditions()
        expect_equal(#conds, 1)
        expect_equal(conds[1].type, "time_of_day")
        expect_equal(conds[1].value, "night")
    end)
end)

-- â”€â”€ RecipeRegistry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates recipe registry search paths including outputs, ingredients, tags, stations, categories, skills, and hand-craftable filters.
describe("RecipeRegistry", function()
    local function make_registry()
        local reg = C.newRecipeRegistry()
        local r1 = C.newRecipe("sword")
        r1.station_type = "forge"
        r1.category = "weapons"
        r1.skill = "smithing"
        r1.skill_level = 1
        r1.tags = { "melee" }
        r1:addIngredient(C.newIngredient("iron", 2))
        r1:addOutput(C.newRecipeOutput("iron_sword", 1))
        reg:add(r1)

        local r2 = C.newRecipe("potion")
        r2.station_type = "alchemy_table"
        r2.category = "consumables"
        r2.skill = "alchemy"
        r2.skill_level = 3
        r2.hand_craftable = false
        r2:addIngredient(C.newIngredient("herb", 3))
        r2:addOutput(C.newRecipeOutput("health_potion", 1))
        reg:add(r2)

        return reg
    end

    -- @covers library.crafting.newRecipeRegistry
    -- @description Verifies the recipe registry tracks inserted recipes, total counts, and direct lookup by id.
    it("add/get/count", function()
        local reg = make_registry()
        expect_equal(reg:count(), 2)
        expect_equal(reg:get("sword").id, "sword")
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Confirms registry removal succeeds once, updates counts, and reports false for repeated removals.
    it("remove", function()
        local reg = make_registry()
        expect_equal(reg:remove("sword"), true)
        expect_equal(reg:count(), 1)
        expect_equal(reg:remove("sword"), false)
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Checks the registry returns the full set of stored recipe ids.
    it("ids", function()
        local reg = make_registry()
        local ids = reg:ids()
        expect_equal(#ids, 2)
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Verifies registry searches can find recipes that produce a requested output item.
    it("findByOutput", function()
        local reg = make_registry()
        local found = reg:findByOutput("iron_sword")
        expect_equal(#found, 1)
        expect_equal(found[1].id, "sword")
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Verifies registry searches can find recipes that consume a requested ingredient item.
    it("findByIngredient", function()
        local reg = make_registry()
        local found = reg:findByIngredient("iron")
        expect_equal(#found, 1)
        expect_equal(found[1].id, "sword")
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Confirms tag-based registry filtering returns only recipes carrying the requested recipe tag.
    it("findByTag", function()
        local reg = make_registry()
        local found = reg:findByTag("melee")
        expect_equal(#found, 1)
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Checks station filtering returns only recipes assigned to the requested crafting station.
    it("forStation", function()
        local reg = make_registry()
        local found = reg:forStation("forge")
        expect_equal(#found, 1)
        expect_equal(found[1].id, "sword")
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Verifies category filtering returns only recipes in the requested category.
    it("findByCategory", function()
        local reg = make_registry()
        local found = reg:findByCategory("consumables")
        expect_equal(#found, 1)
        expect_equal(found[1].id, "potion")
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Confirms skill-based registry filtering returns recipes gated by the requested skill.
    it("findBySkill", function()
        local reg = make_registry()
        local found = reg:findBySkill("smithing")
        expect_equal(#found, 1)
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Ensures skill filtering respects an optional maximum skill-level cutoff.
    it("findBySkill with max_level filter", function()
        local reg = make_registry()
        local found = reg:findBySkill("alchemy", 2)
        expect_equal(#found, 0) -- potion needs level 3
    end)

    -- @covers library.crafting.newRecipeRegistry
    -- @description Verifies hand-craftable filtering excludes recipes that explicitly require a crafting station.
    it("findHandCraftable", function()
        local reg = make_registry()
        local found = reg:findHandCraftable()
        expect_equal(#found, 1)
        expect_equal(found[1].id, "sword")
    end)
end)

-- â”€â”€ CraftJob â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises craft job progress tracking, completion thresholds, percentage reporting, and paused-job behavior.
describe("CraftJob", function()
    -- @covers library.crafting.newCraftJob
    -- @description Checks craft jobs track progress, completion state, and percentage updates as work advances past completion.
    it("create and advance", function()
        local job = C.newCraftJob(1, "sword", 5, 1)
        expect_equal(job.completed, false)
        expect_near(job:percent(), 0, 0.01)

        job:advance(3)
        expect_near(job:percent(), 0.6, 0.01)
        expect_equal(job.completed, false)

        local done = job:advance(3)
        expect_equal(done, true)
        expect_equal(job.completed, true)
        expect_near(job:percent(), 1.0, 0.01)
    end)

    -- @covers library.crafting.newCraftJob
    -- @description Verifies paused craft jobs ignore further progress updates until unpaused.
    it("paused job does not advance", function()
        local job = C.newCraftJob(1, "sword", 5, 1)
        job.paused = true
        job:advance(10)
        expect_near(job.progress, 0, 0.01)
    end)
end)

-- â”€â”€ CraftQueue â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers queue capacity, concurrent processing limits, cancellation, lookup, completion collection, and max-job reporting.
describe("CraftQueue", function()
    -- @covers library.crafting.newCraftQueue
    -- @description Verifies queues can enqueue jobs, update them over time, and report completed job ids.
    it("enqueue and update", function()
        local q = C.newCraftQueue(5)
        local id = q:enqueue("sword", 3, 1)
        expect_equal(id ~= nil, true)
        expect_equal(q:count(), 1)

        local completed = q:update(4)
        expect_equal(#completed, 1)
        expect_equal(completed[1], id)
    end)

    -- @covers library.crafting.newCraftQueue
    -- @description Confirms queue capacity limits reject new jobs once the configured maximum job count is reached.
    it("respects max_jobs", function()
        local q = C.newCraftQueue(2)
        q:enqueue("a", 1, 1)
        q:enqueue("b", 1, 1)
        local id3 = q:enqueue("c", 1, 1)
        expect_equal(id3, nil)
        expect_equal(q:isFull(), true)
    end)

    -- @covers library.crafting.newCraftQueue
    -- @description Ensures the queue honors its max-concurrent setting by completing jobs in batches instead of all at once.
    it("max_concurrent limits parallel jobs", function()
        local q = C.newCraftQueue(10)
        q:setMaxConcurrent(1)
        q:enqueue("a", 2, 1)
        q:enqueue("b", 2, 1)

        q:update(3) -- only first should complete
        local done = q:collectCompleted()
        expect_equal(#done, 1)

        q:update(3) -- now second completes
        done = q:collectCompleted()
        expect_equal(#done, 1)
    end)

    -- @covers library.crafting.newCraftQueue
    -- @description Verifies job cancellation removes active jobs and reports false when the id no longer exists.
    it("cancel job", function()
        local q = C.newCraftQueue(5)
        local id = q:enqueue("x", 10, 1)
        expect_equal(q:cancel(id), true)
        expect_equal(q:count(), 0)
        expect_equal(q:cancel(id), false)
    end)

    -- @covers library.crafting.newCraftQueue
    -- @description Confirms queued jobs can be retrieved later by their generated job id.
    it("getJob", function()
        local q = C.newCraftQueue(5)
        local id = q:enqueue("y", 5, 1)
        local job = q:getJob(id)
        expect_equal(job.recipe_id, "y")
    end)

    -- @description Verifies case: clear.
    it("clear", function()
        local q = C.newCraftQueue(5)
        q:enqueue("a", 1, 1)
        q:enqueue("b", 1, 1)
        q:clear()
        expect_equal(q:count(), 0)
    end)

    -- @description Verifies case: maxJobs accessor.
    it("maxJobs accessor", function()
        local q = C.newCraftQueue(7)
        expect_equal(q:maxJobs(), 7)
    end)
end)

-- â”€â”€ Station â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies station defaults, fuel flow, modules, attachments, stat storage, level upgrades, and efficiency clamping.
describe("Station", function()
    -- @covers library.crafting.newStation
    -- @description Verifies case: create with defaults.
    it("create with defaults", function()
        local s = C.newStation("Anvil", "forge")
        expect_equal(s.name, "Anvil")
        expect_equal(s.station_type, "forge")
        expect_equal(s.level, 1)
        expect_equal(s.max_level, 10)
    end)

    -- @description Verifies case: fuel management.
    it("fuel management", function()
        local s = C.newStation("Oven", "furnace")
        s:addFuel(50)
        expect_equal(s.fuel, 50)
        expect_equal(s:hasFuel(30), true)
        expect_equal(s:consumeFuel(30), true)
        expect_equal(s.fuel, 20)
        expect_equal(s:consumeFuel(30), false)
        expect_near(s:fuelPercent(), 0.2, 0.01)
    end)

    -- @description Verifies case: fuel clamped to max.
    it("fuel clamped to max", function()
        local s = C.newStation("Oven", "furnace")
        s:addFuel(200)
        expect_equal(s.fuel, 100)
    end)

    -- @description Verifies case: modules.
    it("modules", function()
        local s = C.newStation("Bench", "workbench")
        expect_equal(s:addModule("speed_pulley"), true)
        expect_equal(s:hasModule("speed_pulley"), true)
        expect_equal(s:addModule("speed_pulley"), false) -- duplicate
        expect_equal(s:removeModule("speed_pulley"), true)
        expect_equal(s:hasModule("speed_pulley"), false)
    end)

    -- @description Verifies case: module limit.
    it("module limit", function()
        local s = C.newStation("Bench", "workbench")
        s.module_limit = 2
        s:addModule("a")
        s:addModule("b")
        expect_equal(s:addModule("c"), false)
    end)

    -- @description Verifies case: attachments.
    it("attachments", function()
        local s = C.newStation("Bench", "workbench")
        expect_equal(s:addAttachment("lamp"), true)
        expect_equal(s:hasAttachment("lamp"), true)
        expect_equal(s:removeAttachment("lamp"), true)
    end)

    -- @description Verifies case: stats.
    it("stats", function()
        local s = C.newStation("Forge", "forge")
        s:setStat("heat", 500)
        expect_equal(s:getStat("heat"), 500)
        expect_equal(s:getStat("cold"), 0)
    end)

    -- @description Verifies case: upgrade.
    it("upgrade", function()
        local s = C.newStation("Forge", "forge")
        s.max_level = 3
        expect_equal(s:canUpgrade(), true)
        expect_equal(s:upgrade(), true)
        expect_equal(s.level, 2)
        s:upgrade()
        expect_equal(s:canUpgrade(), false)
        expect_equal(s:upgrade(), false)
    end)

    -- @description Verifies case: efficiency.
    it("efficiency", function()
        local s = C.newStation("Forge", "forge")
        s:setEfficiency(1.5)
        expect_near(s.efficiency, 1.5, 0.01)
        s:setEfficiency(-1)
        expect_near(s.efficiency, 0, 0.01)
    end)
end)

-- â”€â”€ CraftSkill â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises skill leveling, perk spending, specialization choices, recipe difficulty colour, and aggregate bonuses from unlocked perks.
describe("CraftSkill", function()
    -- @covers library.crafting.newCraftSkill
    -- @description Verifies case: create and getLevel.
    it("create and getLevel", function()
        local sk = C.newCraftSkill("smithing")
        expect_equal(sk:getLevel(), 1)
        expect_equal(sk:getXP(), 0)
    end)

    -- @description Verifies case: addXP gains levels.
    it("addXP gains levels", function()
        local sk = C.newCraftSkill("smithing")
        -- Level 1 requires 100 XP (linear: level * 100)
        local gained = sk:addXP(250)
        expect_equal(gained, 1)  -- 100 xp for level 1â†’2, 150 remaining < 200
        expect_equal(sk:getLevel(), 2)
    end)

    -- @description Verifies case: perk points.
    it("perk points", function()
        local sk = C.newCraftSkill("smithing")
        sk:grantPerkPoint()
        expect_equal(sk.perk_points, 1)
        expect_equal(sk:spendPerkPoint("sharp_edge"), true)
        expect_equal(sk:hasPerk("sharp_edge"), true)
        expect_equal(sk.perk_points, 0)
    end)

    -- @description Verifies case: cannot spend without points.
    it("cannot spend without points", function()
        local sk = C.newCraftSkill("smithing")
        expect_equal(sk:spendPerkPoint("x"), false)
    end)

    -- @description Verifies case: perk tree integration.
    it("perk tree integration", function()
        local sk = C.newCraftSkill("smithing")
        local node = C.newPerkNode("sharp_edge")
        node.required_level = 3
        sk:addPerkToTree(node)

        sk:grantPerkPoint()
        -- level 1 < required 3
        expect_equal(sk:spendPerkPoint("sharp_edge"), false)

        sk.level = 5
        expect_equal(sk:spendPerkPoint("sharp_edge"), true)
    end)
end)

-- â”€â”€ PerkNode â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests perk node defaults, prerequisite and level gating, and unlock state transitions.
describe("PerkNode", function()
    -- @covers library.crafting.newPerkNode
    -- @description Verifies case: create with defaults.
    it("create with defaults", function()
        local p = C.newPerkNode("forge_mastery")
        expect_equal(p.name, "forge_mastery")
        expect_equal(p.unlocked, false)
        expect_equal(p.required_level, 0)
    end)

    -- @description Verifies case: canUnlock checks prerequisites.
    it("canUnlock checks prerequisites", function()
        local p = C.newPerkNode("advanced")
        p.prerequisites = { "basic" }
        expect_equal(p:canUnlock(10, {}), false)
        expect_equal(p:canUnlock(10, { "basic" }), true)
    end)

    -- @description Verifies case: canUnlock checks level.
    it("canUnlock checks level", function()
        local p = C.newPerkNode("elite")
        p.required_level = 10
        expect_equal(p:canUnlock(5, {}), false)
        expect_equal(p:canUnlock(10, {}), true)
    end)

    -- @description Verifies case: unlock sets flag.
    it("unlock sets flag", function()
        local p = C.newPerkNode("x")
        p:unlock()
        expect_equal(p.unlocked, true)
        expect_equal(p:canUnlock(99, {}), false) -- already unlocked
    end)
end)

-- â”€â”€ UpgradeTree â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers upgrade tree node storage, availability filtering, and full-node enumeration order.
describe("UpgradeTree", function()
    -- @covers library.crafting.newUpgradeTree
    -- @description Verifies case: add and get nodes.
    it("add and get nodes", function()
        local tree = C.newUpgradeTree("root")
        local n1 = C.newUpgradeNode("root")
        local n2 = C.newUpgradeNode("branch_a")
        n2.required_level = 3
        tree:addNode(n1)
        tree:addNode(n2)
        expect_equal(tree:getNode("root").id, "root")
        expect_equal(tree:getNode("branch_a").id, "branch_a")
    end)

    -- @description Verifies case: availableUpgrades filters by level and unlocked.
    it("availableUpgrades filters by level and unlocked", function()
        local tree = C.newUpgradeTree("root")
        tree:addNode(C.newUpgradeNode("a"))
        local b = C.newUpgradeNode("b")
        b.required_level = 5
        tree:addNode(b)

        local avail = tree:availableUpgrades({}, 3)
        expect_equal(#avail, 1)
        expect_equal(avail[1].id, "a")

        avail = tree:availableUpgrades({ a = true }, 5)
        expect_equal(#avail, 1)
        expect_equal(avail[1].id, "b")
    end)
end)

-- â”€â”€ ModifierPool â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates modifier pool rolling, draw alias behavior, weight aggregation, removal, naming, and modifier listing.
describe("ModifierPool", function()
    -- @covers library.crafting.newModifierPool
    -- @description Verifies case: empty pool rolls nil.
    it("empty pool rolls nil", function()
        local pool = C.newModifierPool()
        expect_equal(pool:roll(), nil)
    end)

    -- @description Verifies case: single entry always rolls.
    it("single entry always rolls", function()
        local pool = C.newModifierPool()
        pool:add(C.newModifierEntry("sharp", 1))
        local result = pool:roll()
        expect_equal(result.name, "sharp")
    end)
end)

-- â”€â”€ RecipeKnowledge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises recipe discovery state, grouping, progress tracking, forgetting, auto-discovery toggles, and clearing known recipes.
describe("RecipeKnowledge", function()
    -- @covers library.crafting.newRecipeKnowledge
    -- @description Verifies case: discover and isKnown.
    it("discover and isKnown", function()
        local rk = C.newRecipeKnowledge()
        expect_equal(rk:isKnown("sword"), false)
        expect_equal(rk:discover("sword"), true)
        expect_equal(rk:isKnown("sword"), true)
        expect_equal(rk:discover("sword"), false) -- already known
    end)

    -- @description Verifies case: knownCount and knownIds.
    it("knownCount and knownIds", function()
        local rk = C.newRecipeKnowledge()
        rk:discover("a")
        rk:discover("b")
        rk:discover("c")
        expect_equal(rk:knownCount(), 3)
        local ids = rk:knownIds()
        expect_equal(#ids, 3)
    end)

    -- @description Verifies case: groups and progress.
    it("groups and progress", function()
        local rk = C.newRecipeKnowledge()
        rk:addGroup("swords", { "iron_sword", "steel_sword", "mithril_sword" })
        rk:discover("iron_sword")
        rk:discover("steel_sword")
        local known, total = rk:groupProgress("swords")
        expect_equal(known, 2)
        expect_equal(total, 3)
    end)

    -- @description Verifies case: getGroup.
    it("getGroup", function()
        local rk = C.newRecipeKnowledge()
        rk:addGroup("bows", { "longbow", "shortbow" })
        local g = rk:getGroup("bows")
        expect_equal(#g, 2)
        expect_equal(rk:getGroup("nope"), nil)
    end)
end)

-- â”€â”€ RecipeGroup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies recipe group construction plus add, remove, contains, icon, order, and count helpers.
describe("RecipeGroup", function()
    -- @covers library.crafting.newRecipeGroup
    -- @description Verifies case: create.
    it("create", function()
        local rg = C.newRecipeGroup("potions", { "heal", "mana", "speed" })
        expect_equal(rg.name, "potions")
        expect_equal(#rg.ids, 3)
    end)
end)

-- â”€â”€ CraftSkill (extended coverage) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Focuses on specialization selection, level forcing, and derived bonus getters for crafted speed, quality, and yield.
describe("CraftSkill specializations", function()
    -- @covers library.crafting.newCraftSkill
    -- @description Verifies case: register and choose a specialization.
    it("register and choose a specialization", function()
        local sk = C.newCraftSkill("smithing")
        sk:addSpecialization("armorsmith")
        sk:addSpecialization("weaponsmith")
        expect_equal(true, sk:chooseSpecialization("armorsmith"))
        expect_equal("armorsmith", sk:getSpecialization())
    end)

    -- @description Verifies case: second chooseSpecialization returns false.
    it("second chooseSpecialization returns false", function()
        local sk = C.newCraftSkill("smithing")
        sk:addSpecialization("armorsmith")
        sk:chooseSpecialization("armorsmith")
        expect_equal(false, sk:chooseSpecialization("armorsmith"))
    end)

    -- @description Verifies case: setLevel force-sets level and resets XP to 0.
    it("setLevel force-sets level and resets XP to 0", function()
        local sk = C.newCraftSkill("smithing")
        sk:addXP(150)  -- gains at least 1 level
        sk:setLevel(10)
        expect_equal(10, sk:getLevel())
        expect_equal(0, sk:getXP())
    end)

    -- @description Verifies case: getSpeedBonus, getQualityBonus, getYieldBonus from unlocked perks.
    it("getSpeedBonus, getQualityBonus, getYieldBonus from unlocked perks", function()
        local sk = C.newCraftSkill("smithing")
        local node = C.newPerkNode("mastery")
        node.speed_bonus   = 0.1
        node.quality_bonus = 0.05
        node.yield_bonus   = 0.02
        sk:addPerkToTree(node)
        sk:grantPerkPoint()
        sk:spendPerkPoint("mastery")
        expect_near(0.1,  sk:getSpeedBonus(),  0.001)
        expect_near(0.05, sk:getQualityBonus(), 0.001)
        expect_near(0.02, sk:getYieldBonus(),   0.001)
    end)

    -- @description Verifies case: recipeColor returns grey for recipe with no thresholds.
    it("recipeColor returns grey for recipe with no thresholds", function()
        local sk = C.newCraftSkill("smithing")
        sk:setLevel(1)
        local recipe = {}
        expect_equal("grey", sk:recipeColor(recipe))
        expect_near(0.0, sk:skillUpChance(recipe), 0.001)
    end)

    -- @description Verifies case: recipeColor returns orange and skillUpChance is 1.0 for hard recipe.
    it("recipeColor returns orange and skillUpChance is 1.0 for hard recipe", function()
        local sk = C.newCraftSkill("smithing")
        sk:setLevel(1)
        local hard = { orange_threshold = 5 }
        expect_equal("orange", sk:recipeColor(hard))
        expect_near(1.0, sk:skillUpChance(hard), 0.001)
    end)
end)

-- â”€â”€ RecipeKnowledge mutations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers mutation-oriented recipe knowledge operations including forgetting, auto-discover flags, and full resets.
describe("RecipeKnowledge mutations", function()
    -- @covers library.crafting.newRecipeKnowledge
    -- @description Verifies case: forget removes a known recipe.
    it("forget removes a known recipe", function()
        local rk = C.newRecipeKnowledge()
        rk:discover("sword")
        expect_equal(true, rk:isKnown("sword"))
        expect_equal(true, rk:forget("sword"))
        expect_equal(false, rk:isKnown("sword"))
        expect_equal(false, rk:forget("sword"))  -- already unknown
    end)

    -- @description Verifies case: setAutoDiscover and isAutoDiscover.
    it("setAutoDiscover and isAutoDiscover", function()
        local rk = C.newRecipeKnowledge()
        expect_equal(false, rk:isAutoDiscover())
        rk:setAutoDiscover(true)
        expect_equal(true, rk:isAutoDiscover())
        rk:setAutoDiscover(false)
        expect_equal(false, rk:isAutoDiscover())
    end)

    -- @description Verifies case: clear wipes all known recipes.
    it("clear wipes all known recipes", function()
        local rk = C.newRecipeKnowledge()
        rk:discover("a")
        rk:discover("b")
        expect_equal(2, rk:knownCount())
        rk:clear()
        expect_equal(0, rk:knownCount())
        expect_equal(false, rk:isKnown("a"))
    end)
end)

-- â”€â”€ RecipeGroup operations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Exercises the mutating recipe-group helpers for managing recipe ids and display metadata.
describe("RecipeGroup operations", function()
    -- @covers library.crafting.newRecipeGroup
    -- @description Verifies case: addRecipe, removeRecipe, contains, count.
    it("addRecipe, removeRecipe, contains, count", function()
        local rg = C.newRecipeGroup("weapons", {})
        rg:addRecipe("sword")
        rg:addRecipe("axe")
        rg:addRecipe("sword")  -- duplicate, ignored
        expect_equal(2, rg:count())
        expect_equal(true, rg:contains("sword"))
        expect_equal(false, rg:contains("bow"))
        expect_equal(true, rg:removeRecipe("sword"))
        expect_equal(false, rg:removeRecipe("sword"))  -- already removed
        expect_equal(1, rg:count())
    end)

    -- @description Verifies case: setIcon/getIcon and setOrder/getOrder.
    it("setIcon/getIcon and setOrder/getOrder", function()
        local rg = C.newRecipeGroup("shields", {})
        rg:setIcon("shield.png")
        expect_equal("shield.png", rg:getIcon())
        rg:setOrder(3)
        expect_equal(3, rg:getOrder())
    end)
end)

-- â”€â”€ ModifierPool operations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Adds extended coverage for modifier pool counts, total weight, enumerated modifiers, removal, and naming helpers.
describe("ModifierPool operations", function()
    -- @covers library.crafting.newModifierPool
    -- @description Verifies case: count and getTotalWeight after adding entries.
    it("count and getTotalWeight after adding entries", function()
        local pool = C.newModifierPool()
        pool:add(C.newModifierEntry("heavy", 2))
        pool:add(C.newModifierEntry("sharp", 1))
        expect_equal(2, pool:count())
        expect_near(3.0, pool:getTotalWeight(), 0.001)
    end)

    -- @description Verifies case: getModifiers returns all entries with names.
    it("getModifiers returns all entries with names", function()
        local pool = C.newModifierPool()
        pool:add(C.newModifierEntry("sturdy", 1))
        pool:add(C.newModifierEntry("keen", 1))
        local mods = pool:getModifiers()
        expect_equal(2, #mods)
        expect_equal("sturdy", mods[1].name)
        expect_equal("keen", mods[2].name)
    end)

    -- @description Verifies case: remove modifier returns true then false.
    it("remove modifier returns true then false", function()
        local pool = C.newModifierPool()
        pool:add(C.newModifierEntry("heavy", 2))
        pool:add(C.newModifierEntry("sharp", 1))
        expect_equal(true, pool:remove("heavy"))
        expect_equal(1, pool:count())
        expect_equal(false, pool:remove("heavy"))
    end)

    -- @description Verifies case: getName and setName.
    it("getName and setName", function()
        local pool = C.newModifierPool()
        pool:setName("rare_affixes")
        expect_equal("rare_affixes", pool:getName())
    end)
end)

-- â”€â”€ UpgradeTree getAllNodes â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies getAllNodes returns upgrade nodes in insertion order for deterministic UI or progression rendering.
describe("UpgradeTree getAllNodes", function()
    -- @covers library.crafting.newUpgradeTree
    -- @description Verifies case: returns all nodes in insertion order.
    it("returns all nodes in insertion order", function()
        local tree = C.newUpgradeTree("weapons")
        tree:addNode(C.newUpgradeNode("basic"))
        tree:addNode(C.newUpgradeNode("tempered"))
        tree:addNode(C.newUpgradeNode("masterwork"))
        local all = tree:getAllNodes()
        expect_equal(3, #all)
        expect_equal("basic",      all[1].id)
        expect_equal("tempered",   all[2].id)
        expect_equal("masterwork", all[3].id)
    end)
end)

-- â”€â”€ Station proximity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests station proximity checks to ensure range calculations distinguish nearby and distant work positions.
describe("Station isInRange", function()
    -- @covers library.crafting.newStation
    -- @description Verifies case: returns true when within proximity_radius and false when outside.
    it("returns true when within proximity_radius and false when outside", function()
        local s = C.newStation("Anvil", "forge")
        s.x = 50
        s.y = 50
        s.proximity_radius = 10
        expect_equal(true,  s:isInRange(55, 55))    -- dist ~7.07 < 10
        expect_equal(false, s:isInRange(100, 100))  -- dist ~70.7 > 10
    end)
end)

-- â”€â”€ Station new fields (active / requires_cover / has_cover) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers activation state and cover-requirement flags that gate whether a station may process a given recipe.
describe("Station active and cover flags", function()
    -- @covers library.crafting.newStation
    -- @description Verifies case: station is active by default.
    it("station is active by default", function()
        local s = C.newStation("Forge", "forge")
        expect_equal(s.active, true)
    end)

    -- @description Verifies case: inactive station cannot process any recipe.
    it("inactive station cannot process any recipe", function()
        local s = C.newStation("Forge", "forge")
        s.active = false
        local r = C.newRecipe("blade")
        r.station_type = "forge"
        expect_equal(false, s:canProcess(r))
    end)

    -- @description Verifies case: requires_cover defaults to false, has_cover defaults to false.
    it("requires_cover defaults to false, has_cover defaults to false", function()
        local s = C.newStation("Cauldron", "alchemy")
        expect_equal(s.requires_cover, false)
        expect_equal(s.has_cover, false)
        s.requires_cover = true
        s.has_cover = true
        expect_equal(s.requires_cover, true)
        expect_equal(s.has_cover, true)
    end)
end)

-- â”€â”€ UpgradeNode new fields (required_level / description / prerequisites) â”€

-- @description Confirms newly created upgrade nodes expose the expected default requirement, description, and prerequisite fields.
describe("UpgradeNode fields", function()
    -- @covers library.crafting.newUpgradeNode
    -- @description Verifies case: required_level defaults to 0.
    it("required_level defaults to 0", function()
        local n = C.newUpgradeNode("basic")
        expect_equal(n.required_level, 0)
    end)

    -- @description Verifies case: description defaults to empty string.
    it("description defaults to empty string", function()
        local n = C.newUpgradeNode("basic")
        expect_equal(n.description, "")
    end)

    -- @description Verifies case: prerequisites defaults to empty table.
    it("prerequisites defaults to empty table", function()
        local n = C.newUpgradeNode("advanced")
        expect_equal(type(n.prerequisites), "table")
        expect_equal(#n.prerequisites, 0)
    end)
end)

-- â”€â”€ CraftSkillRarity enum â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Validates exported craft skill rarity constants for the four named rarity tiers.
describe("CraftSkillRarity", function()
    -- @covers library.crafting.CraftSkillRarity
    -- @description Verifies case: has four tiers with correct string values.
    it("has four tiers with correct string values", function()
        expect_equal(C.CraftSkillRarity.COMMON,   "common")
        expect_equal(C.CraftSkillRarity.UNCOMMON, "uncommon")
        expect_equal(C.CraftSkillRarity.RARE,     "rare")
        expect_equal(C.CraftSkillRarity.EPIC,     "epic")
    end)
end)

-- â”€â”€ ModifierPool:draw() alias â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Verifies the draw alias mirrors roll behavior for populated pools and returns nil for empty ones.
describe("ModifierPool draw", function()
    -- @covers library.crafting.newModifierPool
    -- @description Verifies case: draw is equivalent to roll.
    it("draw is equivalent to roll", function()
        local pool = C.newModifierPool()
        pool:add(C.newModifierEntry("brutal", 1))
        local via_draw = pool:draw()
        expect_equal(type(via_draw), "table")
        if via_draw then
            expect_equal(via_draw.name, "brutal")
        end
    end)

    -- @description Verifies case: draw returns nil for empty pool.
    it("draw returns nil for empty pool", function()
        local pool = C.newModifierPool()
        expect_equal(pool:draw(), nil)
    end)
end)

-- â”€â”€ RecipeKnowledge auto-discover integration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Tests how auto-discovery changes the isKnown query so unknown recipes appear known only while the flag is enabled.
describe("RecipeKnowledge auto-discover isKnown", function()
    -- @covers library.crafting.newRecipeKnowledge
    -- @description Verifies case: isKnown returns true for any id when auto-discover is on.
    it("isKnown returns true for any id when auto-discover is on", function()
        local rk = C.newRecipeKnowledge()
        rk:setAutoDiscover(true)
        expect_equal(true, rk:isKnown("anything_at_all"))
        expect_equal(true, rk:isKnown("unknown_recipe"))
    end)

    -- @description Verifies case: isKnown obeys auto-discover toggle.
    it("isKnown obeys auto-discover toggle", function()
        local rk = C.newRecipeKnowledge()
        rk:setAutoDiscover(true)
        expect_equal(true, rk:isKnown("x"))
        rk:setAutoDiscover(false)
        expect_equal(false, rk:isKnown("x"))
    end)
end)

-- ── Grid slot bounds checking ────────────────────────────────────────────

-- @description Tests that setGridSlot validates coordinates against grid dimensions.
describe("Recipe grid slot bounds", function()
    -- @covers library.crafting.newRecipe
    -- @description Verifies setGridSlot rejects out-of-bounds coordinates.
    it("rejects out-of-bounds x", function()
        local r = C.newRecipe("shaped")
        r.grid_width = 3
        r.grid_height = 3
        expect_equal(r:setGridSlot(5, 0, "iron"), false)
    end)

    -- @description Verifies setGridSlot rejects negative coordinates.
    it("rejects negative y", function()
        local r = C.newRecipe("shaped")
        r.grid_width = 3
        r.grid_height = 3
        expect_equal(r:setGridSlot(0, -1, "iron"), false)
    end)

    -- @description Verifies setGridSlot rejects when grid dimensions are zero.
    it("rejects when grid not configured", function()
        local r = C.newRecipe("shaped")
        -- grid_width/grid_height default to 0
        expect_equal(r:setGridSlot(0, 0, "iron"), false)
    end)

    -- @description Verifies setGridSlot accepts valid coordinates.
    it("accepts valid coordinates", function()
        local r = C.newRecipe("shaped")
        r.grid_width = 3
        r.grid_height = 3
        expect_equal(r:setGridSlot(2, 2, "iron"), true)
        expect_equal(r.grid_slots[2 * 3 + 2], "iron")
    end)

    -- @description Verifies setGridSlot boundary: max valid index.
    it("accepts boundary coordinates", function()
        local r = C.newRecipe("shaped")
        r.grid_width = 2
        r.grid_height = 2
        expect_equal(r:setGridSlot(0, 0, "a"), true)
        expect_equal(r:setGridSlot(1, 1, "b"), true)
        expect_equal(r:setGridSlot(2, 0, "c"), false) -- x == grid_width
    end)
end)

-- ── Ingredient tag precedence ────────────────────────────────────────────

-- @description Tests ingredient tag vs item_type precedence behavior.
describe("Ingredient tag precedence", function()
    -- @covers library.crafting.newIngredient
    -- @description Verifies item-type ingredient has empty tag.
    it("item-type ingredient has empty tag", function()
        local ing = C.newIngredient("wood", 3)
        expect_equal(ing.tag, "")
        expect_equal(ing:isTag(), false)
    end)

    -- @description Verifies tag ingredient has empty item_type.
    it("tag ingredient has empty item_type", function()
        local ing = C.newIngredientTag("metal", 2)
        expect_equal(ing.item_type, "")
        expect_equal(ing:isTag(), true)
    end)

    -- @description When both are set manually, isTag() returns true (tag takes precedence).
    it("tag takes precedence when both set", function()
        local ing = C.newIngredient("wood", 1)
        ing.tag = "organic"  -- manually set both
        expect_equal(ing:isTag(), true) -- tag wins
    end)

    -- @description Verifies invalid quantity defaults to 1.
    it("invalid quantity defaults to 1", function()
        local ing = C.newIngredient("wood", -5)
        expect_equal(ing.quantity, 1)
        local ing2 = C.newIngredientTag("metal", 0)
        expect_equal(ing2.quantity, 1)
    end)
end)

-- ── CraftQueue auto-collect ──────────────────────────────────────────────

-- @description Tests that CraftQueue:update() auto-removes completed jobs.
describe("CraftQueue auto-collect", function()
    -- @covers library.crafting.newCraftQueue
    -- @description Verifies update() removes completed jobs automatically.
    it("update auto-removes completed jobs from count", function()
        local q = C.newCraftQueue(5)
        q:enqueue("sword", 2, 1)
        q:enqueue("shield", 10, 1)
        -- Complete first job
        q:update(3)
        -- Only the in-progress job should remain
        expect_equal(q:count(), 1)
    end)

    -- @description Verifies completed IDs are still available via collectCompleted().
    it("collectCompleted still returns IDs after auto-remove", function()
        local q = C.newCraftQueue(5)
        local id = q:enqueue("sword", 2, 1)
        q:update(3)
        local done = q:collectCompleted()
        expect_equal(#done, 1)
        expect_equal(done[1], id)
    end)

    -- @description Verifies queue slot is freed after auto-remove.
    it("queue slot freed after auto-remove", function()
        local q = C.newCraftQueue(2)
        q:enqueue("a", 1, 1)
        q:enqueue("b", 1, 1)
        expect_equal(q:isFull(), true)
        q:update(2) -- complete both
        expect_equal(q:isFull(), false)
        -- Can enqueue again
        local id3 = q:enqueue("c", 1, 1)
        expect_equal(id3 ~= nil, true)
    end)

    -- @description Verifies getJob returns nil for completed and removed jobs.
    it("getJob returns nil for completed jobs", function()
        local q = C.newCraftQueue(5)
        local id = q:enqueue("sword", 1, 1)
        q:update(2)
        expect_equal(q:getJob(id), nil)
    end)
end)

-- ── Station fuel edge cases ──────────────────────────────────────────────

-- @description Tests Station fuel validation for negative and invalid inputs.
describe("Station fuel edge cases", function()
    -- @covers library.crafting.newStation
    -- @description Verifies addFuel ignores negative amounts.
    it("addFuel ignores negative amounts", function()
        local s = C.newStation("Forge", "forge")
        s:addFuel(50)
        local result = s:addFuel(-30)
        expect_equal(s.fuel, 50) -- unchanged
        expect_equal(result, 50)
    end)

    -- @description Verifies consumeFuel rejects negative amounts.
    it("consumeFuel rejects negative amounts", function()
        local s = C.newStation("Forge", "forge")
        s:addFuel(50)
        expect_equal(s:consumeFuel(-10), false)
        expect_equal(s.fuel, 50) -- unchanged
    end)

    -- @description Verifies consumeFuel returns false for zero fuel.
    it("consumeFuel fails gracefully at zero fuel", function()
        local s = C.newStation("Forge", "forge")
        expect_equal(s.fuel, 0)
        expect_equal(s:consumeFuel(1), false)
    end)

    -- @description Verifies consuming exactly all fuel works.
    it("consume exact fuel succeeds", function()
        local s = C.newStation("Forge", "forge")
        s:addFuel(50)
        expect_equal(s:consumeFuel(50), true)
        expect_equal(s.fuel, 0)
    end)

    -- @description Verifies addFuel with zero is harmless.
    it("addFuel with zero is no-op", function()
        local s = C.newStation("Forge", "forge")
        s:addFuel(0)
        expect_equal(s.fuel, 0)
    end)
end)

-- ── RecipeOutput quantity validation ─────────────────────────────────────

-- @description Tests that RecipeOutput constructors validate quantity.
describe("RecipeOutput quantity validation", function()
    -- @covers library.crafting.newRecipeOutput
    -- @description Verifies invalid quantity defaults to 1.
    it("negative quantity defaults to 1", function()
        local o = C.newRecipeOutput("sword", -3)
        expect_equal(o.quantity, 1)
    end)

    -- @description Verifies zero quantity defaults to 1.
    it("zero quantity defaults to 1", function()
        local o = C.newRecipeOutput("sword", 0)
        expect_equal(o.quantity, 1)
    end)
end)

test_summary()
