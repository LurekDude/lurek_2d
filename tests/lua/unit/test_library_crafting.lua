--- BDD tests for library.crafting
--- Matches coverage of src/crafting/ Rust tests.

require("tests.lua.init")
local C = require("library.crafting")

-- ── Quality ───────────────────────────────────────────────────────────────

describe("Quality", function()
    it("has six tiers", function()
        expect_equal(C.Quality.Normal, "normal")
        expect_equal(C.Quality.Legendary, "legendary")
    end)

    it("fromStr round-trips", function()
        expect_equal(C.qualityFromStr("fine"), "fine")
        expect_equal(C.qualityFromStr("nope"), nil)
    end)
end)

-- ── Ingredient ────────────────────────────────────────────────────────────

describe("Ingredient", function()
    it("by item type", function()
        local ing = C.newIngredient("wood", 3)
        expect_equal(ing.item_type, "wood")
        expect_equal(ing.quantity, 3)
        expect_equal(ing.consumed, true)
        expect_equal(ing:isTag(), false)
    end)

    it("by tag", function()
        local ing = C.newIngredientTag("metal", 2)
        expect_equal(ing.tag, "metal")
        expect_equal(ing:isTag(), true)
    end)
end)

-- ── RecipeOutput ──────────────────────────────────────────────────────────

describe("RecipeOutput", function()
    it("default output", function()
        local o = C.newRecipeOutput("sword", 1)
        expect_equal(o.item_type, "sword")
        expect_equal(o.quantity, 1)
        expect_equal(o.quality, C.Quality.Normal)
        expect_near(o.chance, 1.0, 0.01)
        expect_equal(o.is_byproduct, false)
    end)

    it("with chance", function()
        local o = C.newRecipeOutputWithChance("gem", 1, 0.5)
        expect_near(o.chance, 0.5, 0.01)
    end)

    it("clamps chance to 0..1", function()
        local o = C.newRecipeOutputWithChance("gem", 1, 2.5)
        expect_near(o.chance, 1.0, 0.01)
    end)
end)

-- ── Recipe ────────────────────────────────────────────────────────────────

describe("Recipe", function()
    it("creates with defaults", function()
        local r = C.newRecipe("iron_sword")
        expect_equal(r.id, "iron_sword")
        expect_equal(r.name, "iron_sword")
        expect_equal(r.enabled, true)
        expect_equal(r.hand_craftable, true)
        expect_near(r.time, 1.0, 0.01)
    end)

    it("add/clear ingredients", function()
        local r = C.newRecipe("blade")
        r:addIngredient(C.newIngredient("iron", 2))
        r:addIngredient(C.newIngredient("wood", 1))
        expect_equal(#r.ingredients, 2)
        r:clearIngredients()
        expect_equal(#r.ingredients, 0)
    end)

    it("add/clear outputs", function()
        local r = C.newRecipe("blade")
        r:addOutput(C.newRecipeOutput("sword", 1))
        expect_equal(#r.outputs, 1)
        r:clearOutputs()
        expect_equal(#r.outputs, 0)
    end)

    it("tags", function()
        local r = C.newRecipe("blade")
        r.tags = { "weapon", "melee" }
        expect_equal(r:hasTag("weapon"), true)
        expect_equal(r:hasTag("ranged"), false)
        expect_equal(#r:getTags(), 2)
    end)

    it("grid slots", function()
        local r = C.newRecipe("shaped")
        r.grid_width = 3
        r.grid_height = 3
        r:setGridSlot(1, 0, "iron")
        expect_equal(r.grid_slots[1], "iron")
    end)

    it("add byproduct", function()
        local r = C.newRecipe("smelt")
        r:addByproduct("slag", 1, 0.3)
        expect_equal(#r.outputs, 1)
        expect_equal(r.outputs[1].is_byproduct, true)
        expect_near(r.outputs[1].chance, 0.3, 0.01)
    end)

    it("conditions", function()
        local r = C.newRecipe("enchant")
        r:addCondition("time_of_day", "night")
        local conds = r:getConditions()
        expect_equal(#conds, 1)
        expect_equal(conds[1].type, "time_of_day")
        expect_equal(conds[1].value, "night")
    end)
end)

-- ── RecipeRegistry ────────────────────────────────────────────────────────

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

    it("add/get/count", function()
        local reg = make_registry()
        expect_equal(reg:count(), 2)
        expect_equal(reg:get("sword").id, "sword")
    end)

    it("remove", function()
        local reg = make_registry()
        expect_equal(reg:remove("sword"), true)
        expect_equal(reg:count(), 1)
        expect_equal(reg:remove("sword"), false)
    end)

    it("ids", function()
        local reg = make_registry()
        local ids = reg:ids()
        expect_equal(#ids, 2)
    end)

    it("findByOutput", function()
        local reg = make_registry()
        local found = reg:findByOutput("iron_sword")
        expect_equal(#found, 1)
        expect_equal(found[1].id, "sword")
    end)

    it("findByIngredient", function()
        local reg = make_registry()
        local found = reg:findByIngredient("iron")
        expect_equal(#found, 1)
        expect_equal(found[1].id, "sword")
    end)

    it("findByTag", function()
        local reg = make_registry()
        local found = reg:findByTag("melee")
        expect_equal(#found, 1)
    end)

    it("forStation", function()
        local reg = make_registry()
        local found = reg:forStation("forge")
        expect_equal(#found, 1)
        expect_equal(found[1].id, "sword")
    end)

    it("findByCategory", function()
        local reg = make_registry()
        local found = reg:findByCategory("consumables")
        expect_equal(#found, 1)
        expect_equal(found[1].id, "potion")
    end)

    it("findBySkill", function()
        local reg = make_registry()
        local found = reg:findBySkill("smithing")
        expect_equal(#found, 1)
    end)

    it("findBySkill with max_level filter", function()
        local reg = make_registry()
        local found = reg:findBySkill("alchemy", 2)
        expect_equal(#found, 0) -- potion needs level 3
    end)

    it("findHandCraftable", function()
        local reg = make_registry()
        local found = reg:findHandCraftable()
        expect_equal(#found, 1)
        expect_equal(found[1].id, "sword")
    end)
end)

-- ── CraftJob ──────────────────────────────────────────────────────────────

describe("CraftJob", function()
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

    it("paused job does not advance", function()
        local job = C.newCraftJob(1, "sword", 5, 1)
        job.paused = true
        job:advance(10)
        expect_near(job.progress, 0, 0.01)
    end)
end)

-- ── CraftQueue ────────────────────────────────────────────────────────────

describe("CraftQueue", function()
    it("enqueue and update", function()
        local q = C.newCraftQueue(5)
        local id = q:enqueue("sword", 3, 1)
        expect_equal(id ~= nil, true)
        expect_equal(q:count(), 1)

        local completed = q:update(4)
        expect_equal(#completed, 1)
        expect_equal(completed[1], id)
    end)

    it("respects max_jobs", function()
        local q = C.newCraftQueue(2)
        q:enqueue("a", 1, 1)
        q:enqueue("b", 1, 1)
        local id3 = q:enqueue("c", 1, 1)
        expect_equal(id3, nil)
        expect_equal(q:isFull(), true)
    end)

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

    it("cancel job", function()
        local q = C.newCraftQueue(5)
        local id = q:enqueue("x", 10, 1)
        expect_equal(q:cancel(id), true)
        expect_equal(q:count(), 0)
        expect_equal(q:cancel(id), false)
    end)

    it("getJob", function()
        local q = C.newCraftQueue(5)
        local id = q:enqueue("y", 5, 1)
        local job = q:getJob(id)
        expect_equal(job.recipe_id, "y")
    end)

    it("clear", function()
        local q = C.newCraftQueue(5)
        q:enqueue("a", 1, 1)
        q:enqueue("b", 1, 1)
        q:clear()
        expect_equal(q:count(), 0)
    end)

    it("maxJobs accessor", function()
        local q = C.newCraftQueue(7)
        expect_equal(q:maxJobs(), 7)
    end)
end)

-- ── Station ───────────────────────────────────────────────────────────────

describe("Station", function()
    it("create with defaults", function()
        local s = C.newStation("Anvil", "forge")
        expect_equal(s.name, "Anvil")
        expect_equal(s.station_type, "forge")
        expect_equal(s.level, 1)
        expect_equal(s.max_level, 10)
    end)

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

    it("fuel clamped to max", function()
        local s = C.newStation("Oven", "furnace")
        s:addFuel(200)
        expect_equal(s.fuel, 100)
    end)

    it("modules", function()
        local s = C.newStation("Bench", "workbench")
        expect_equal(s:addModule("speed_pulley"), true)
        expect_equal(s:hasModule("speed_pulley"), true)
        expect_equal(s:addModule("speed_pulley"), false) -- duplicate
        expect_equal(s:removeModule("speed_pulley"), true)
        expect_equal(s:hasModule("speed_pulley"), false)
    end)

    it("module limit", function()
        local s = C.newStation("Bench", "workbench")
        s.module_limit = 2
        s:addModule("a")
        s:addModule("b")
        expect_equal(s:addModule("c"), false)
    end)

    it("attachments", function()
        local s = C.newStation("Bench", "workbench")
        expect_equal(s:addAttachment("lamp"), true)
        expect_equal(s:hasAttachment("lamp"), true)
        expect_equal(s:removeAttachment("lamp"), true)
    end)

    it("stats", function()
        local s = C.newStation("Forge", "forge")
        s:setStat("heat", 500)
        expect_equal(s:getStat("heat"), 500)
        expect_equal(s:getStat("cold"), 0)
    end)

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

    it("efficiency", function()
        local s = C.newStation("Forge", "forge")
        s:setEfficiency(1.5)
        expect_near(s.efficiency, 1.5, 0.01)
        s:setEfficiency(-1)
        expect_near(s.efficiency, 0, 0.01)
    end)
end)

-- ── CraftSkill ────────────────────────────────────────────────────────────

describe("CraftSkill", function()
    it("create and getLevel", function()
        local sk = C.newCraftSkill("smithing")
        expect_equal(sk:getLevel(), 1)
        expect_equal(sk:getXP(), 0)
    end)

    it("addXP gains levels", function()
        local sk = C.newCraftSkill("smithing")
        -- Level 1 requires 100 XP (linear: level * 100)
        local gained = sk:addXP(250)
        expect_equal(gained, 1)  -- 100 xp for level 1→2, 150 remaining < 200
        expect_equal(sk:getLevel(), 2)
    end)

    it("perk points", function()
        local sk = C.newCraftSkill("smithing")
        sk:grantPerkPoint()
        expect_equal(sk.perk_points, 1)
        expect_equal(sk:spendPerkPoint("sharp_edge"), true)
        expect_equal(sk:hasPerk("sharp_edge"), true)
        expect_equal(sk.perk_points, 0)
    end)

    it("cannot spend without points", function()
        local sk = C.newCraftSkill("smithing")
        expect_equal(sk:spendPerkPoint("x"), false)
    end)

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

-- ── PerkNode ──────────────────────────────────────────────────────────────

describe("PerkNode", function()
    it("create with defaults", function()
        local p = C.newPerkNode("forge_mastery")
        expect_equal(p.name, "forge_mastery")
        expect_equal(p.unlocked, false)
        expect_equal(p.required_level, 0)
    end)

    it("canUnlock checks prerequisites", function()
        local p = C.newPerkNode("advanced")
        p.prerequisites = { "basic" }
        expect_equal(p:canUnlock(10, {}), false)
        expect_equal(p:canUnlock(10, { "basic" }), true)
    end)

    it("canUnlock checks level", function()
        local p = C.newPerkNode("elite")
        p.required_level = 10
        expect_equal(p:canUnlock(5, {}), false)
        expect_equal(p:canUnlock(10, {}), true)
    end)

    it("unlock sets flag", function()
        local p = C.newPerkNode("x")
        p:unlock()
        expect_equal(p.unlocked, true)
        expect_equal(p:canUnlock(99, {}), false) -- already unlocked
    end)
end)

-- ── UpgradeTree ───────────────────────────────────────────────────────────

describe("UpgradeTree", function()
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

-- ── ModifierPool ──────────────────────────────────────────────────────────

describe("ModifierPool", function()
    it("empty pool rolls nil", function()
        local pool = C.newModifierPool()
        expect_equal(pool:roll(), nil)
    end)

    it("single entry always rolls", function()
        local pool = C.newModifierPool()
        pool:add(C.newModifierEntry("sharp", 1))
        local result = pool:roll()
        expect_equal(result.name, "sharp")
    end)
end)

-- ── RecipeKnowledge ───────────────────────────────────────────────────────

describe("RecipeKnowledge", function()
    it("discover and isKnown", function()
        local rk = C.newRecipeKnowledge()
        expect_equal(rk:isKnown("sword"), false)
        expect_equal(rk:discover("sword"), true)
        expect_equal(rk:isKnown("sword"), true)
        expect_equal(rk:discover("sword"), false) -- already known
    end)

    it("knownCount and knownIds", function()
        local rk = C.newRecipeKnowledge()
        rk:discover("a")
        rk:discover("b")
        rk:discover("c")
        expect_equal(rk:knownCount(), 3)
        local ids = rk:knownIds()
        expect_equal(#ids, 3)
    end)

    it("groups and progress", function()
        local rk = C.newRecipeKnowledge()
        rk:addGroup("swords", { "iron_sword", "steel_sword", "mithril_sword" })
        rk:discover("iron_sword")
        rk:discover("steel_sword")
        local known, total = rk:groupProgress("swords")
        expect_equal(known, 2)
        expect_equal(total, 3)
    end)

    it("getGroup", function()
        local rk = C.newRecipeKnowledge()
        rk:addGroup("bows", { "longbow", "shortbow" })
        local g = rk:getGroup("bows")
        expect_equal(#g, 2)
        expect_equal(rk:getGroup("nope"), nil)
    end)
end)

-- ── RecipeGroup ───────────────────────────────────────────────────────────

describe("RecipeGroup", function()
    it("create", function()
        local rg = C.newRecipeGroup("potions", { "heal", "mana", "speed" })
        expect_equal(rg.name, "potions")
        expect_equal(#rg.ids, 3)
    end)
end)

test_summary()
