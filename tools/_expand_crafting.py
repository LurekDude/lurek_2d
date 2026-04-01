"""Expand crafting module with:
Domain: RecipeRegistry::find_by_tag; Recipe::get_tags; CraftSkill::set_level;
         UpgradeTree::reset_node, get_unlocked_ids; CraftQueue::clear, get_all_jobs
API: RecipeRegistry.findByTag; Recipe.getTags; CraftSkill.setLevel;
     UpgradeTree.resetNode, getUnlockedIds; CraftQueue.clear, getAllJobs
Tests: 6 new tests
"""

MOD = r"src\crafting\mod.rs"
with open(MOD, "r", encoding="utf-8") as f:
    dom = f.read()

# RecipeRegistry: add find_by_tag before #[cfg(test)]
registry_extra = """
    /// Find recipe IDs whose tag list contains `tag`.
    pub fn find_by_tag<'a>(&'a self, tag: &str) -> Vec<&'a str> {
        self.recipes.iter()
            .filter(|(_, r)| r.tags.contains(&tag.to_string()))
            .map(|(id, _)| id.as_str())
            .collect()
    }
"""

# Insert before `pub fn for_station`
dom = dom.replace(
    "\n    pub fn for_station<'a>(&'a self, station_type: &str) -> Vec<&'a str> {",
    registry_extra + "\n    pub fn for_station<'a>(&'a self, station_type: &str) -> Vec<&'a str> {",
    1,
)

# Recipe: add get_tags method
recipe_extra = """
    /// Returns all tags on this recipe.
    pub fn get_tags(&self) -> &[String] {
        &self.tags
    }
"""

# Insert at end of Recipe impl before the RecipeRegistry section
dom = dom.replace(
    "\n    pub fn add_output(&mut self, item_type: impl Into<String>, qty: u32) {",
    recipe_extra + "\n    pub fn add_output(&mut self, item_type: impl Into<String>, qty: u32) {",
    1,
)

# CraftSkill: add set_level
skill_extra = """
    /// Force-set the skill level (and reset current XP to start of that level).
    pub fn set_level(&mut self, level: u32) {
        self.level = level;
        self.xp = 0.0;
    }
"""

# Insert into CraftSkill impl — before add_xp
dom = dom.replace(
    "\n    pub fn add_xp(&mut self, amount: f64) {",
    skill_extra + "\n    pub fn add_xp(&mut self, amount: f64) {",
    1,
)

# UpgradeTree: add reset_node, get_unlocked_ids
upgrade_extra = """
    /// Re-lock a previously unlocked node. Returns false if node does not exist.
    pub fn reset_node(&mut self, id: &str) -> bool {
        if let Some(node) = self.nodes.get_mut(id) {
            node.unlocked = false;
            true
        } else {
            false
        }
    }

    /// Returns a list of all currently unlocked node IDs.
    pub fn get_unlocked_ids(&self) -> Vec<String> {
        self.nodes.iter().filter(|(_, n)| n.unlocked).map(|(id, _)| id.clone()).collect()
    }
"""

# Insert before `pub fn get_node_ids`
dom = dom.replace(
    "\n    pub fn get_node_ids(&self) -> Vec<String> {",
    upgrade_extra + "\n    pub fn get_node_ids(&self) -> Vec<String> {",
    1,
)

# CraftQueue: add clear, get_all_jobs
queue_extra = """
    /// Cancel all jobs in the queue.
    pub fn clear(&mut self) {
        self.jobs.clear();
    }

    /// Return all job summaries as (id, recipe_id, quantity, progress, paused) tuples.
    pub fn all_jobs(&self) -> Vec<(String, String, u32, f64, bool)> {
        self.jobs.values()
            .map(|j| (j.id.clone(), j.recipe_id.clone(), j.quantity, j.progress, j.paused))
            .collect()
    }
"""

# Insert before `pub fn count`
dom = dom.replace(
    "\n    pub fn count(&self) -> usize { self.jobs.len() }",
    queue_extra + "\n    pub fn count(&self) -> usize { self.jobs.len() }",
    1,
)

with open(MOD, "w", encoding="utf-8") as f:
    f.write(dom)
print("crafting/mod.rs updated")

# ---- Lua API ----------------------------------------------------------------
API = r"src\lua_api\crafting_api.rs"
with open(API, "r", encoding="utf-8") as f:
    api = f.read()

registry_api_extra = '''        methods.add_method("findByTag", |lua, this, tag: String| {
            let ids = this.0.borrow().find_by_tag(&tag).iter().map(|s| s.to_string()).collect::<Vec<_>>();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
'''

recipe_api_extra = '''        methods.add_method("getTags", |lua, this, ()| {
            let tags = this.0.borrow().get_tags().to_vec();
            let t = lua.create_table()?;
            for (i, tag) in tags.into_iter().enumerate() { t.set(i + 1, tag)?; }
            Ok(t)
        });
'''

skill_api_extra = '''        methods.add_method("setLevel", |_, this, level: u32| {
            this.0.borrow_mut().set_level(level);
            Ok(())
        });
'''

upgrade_api_extra = '''        methods.add_method("resetNode", |_, this, id: String| {
            Ok(this.0.borrow_mut().reset_node(&id))
        });
        methods.add_method("getUnlockedIds", |lua, this, ()| {
            let ids = this.0.borrow().get_unlocked_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
'''

queue_api_extra = '''        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("getAllJobs", |lua, this, ()| {
            let jobs = this.0.borrow().all_jobs();
            let t = lua.create_table()?;
            for (i, (id, recipe_id, qty, progress, paused)) in jobs.into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("id", id)?;
                entry.set("recipeId", recipe_id)?;
                entry.set("quantity", qty)?;
                entry.set("progress", progress)?;
                entry.set("paused", paused)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
'''

# RecipeRegistry: insert before forStation binding
api = api.replace(
    '        methods.add_method("forStation",',
    registry_api_extra + '        methods.add_method("forStation",',
    1,
)

# Recipe: insert before addIngredient
api = api.replace(
    '        methods.add_method("addIngredient",',
    recipe_api_extra + '        methods.add_method("addIngredient",',
    1,
)

# CraftSkill: insert before addXp
api = api.replace(
    '        methods.add_method("addXp",',
    skill_api_extra + '        methods.add_method("addXp",',
    1,
)

# UpgradeTree: insert before getNodeIds
api = api.replace(
    '        methods.add_method("getNodeIds",',
    upgrade_api_extra + '        methods.add_method("getNodeIds",',
    1,
)

# CraftQueue: insert before count binding
api = api.replace(
    '        methods.add_method("count",',
    queue_api_extra + '        methods.add_method("count",',
    1,
)

with open(API, "w", encoding="utf-8") as f:
    f.write(api)
print("crafting_api.rs updated")

# ---- Tests ----------------------------------------------------------------
TEST = r"tests\crafting_tests.rs"
with open(TEST, "r", encoding="utf-8") as f:
    tst = f.read()

new_tests = r'''
#[test]
fn recipe_get_tags() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r = luna.crafting.newRecipe("sword")
        r:addTag("weapon")
        r:addTag("metal")
        reg:add(r)
        local tags = reg:get("sword"):getTags()
        assert(#tags == 2, "2 tags")
        local found = {}
        for _, tag in ipairs(tags) do found[tag] = true end
        assert(found["weapon"], "weapon tag")
        assert(found["metal"], "metal tag")
    "#).exec().unwrap();
}

#[test]
fn registry_find_by_tag() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r1 = luna.crafting.newRecipe("sword"); r1:addTag("weapon"); reg:add(r1)
        local r2 = luna.crafting.newRecipe("axe"); r2:addTag("weapon"); reg:add(r2)
        local r3 = luna.crafting.newRecipe("potion"); r3:addTag("consumable"); reg:add(r3)
        local weapons = reg:findByTag("weapon")
        assert(#weapons == 2, "2 weapons")
        local consumables = reg:findByTag("consumable")
        assert(#consumables == 1, "1 consumable")
    "#).exec().unwrap();
}

#[test]
fn craftskill_set_level() {
    let lua = make_vm();
    lua.load(r#"
        local skill = luna.crafting.newCraftSkill("smithing")
        skill:addXp(900.0)
        local lvl_before = skill:getLevel()
        skill:setLevel(1)
        assert(skill:getLevel() == 1, "level set to 1")
        assert(skill:getXp() == 0.0, "xp reset to 0")
    "#).exec().unwrap();
}

#[test]
fn upgrade_tree_reset_node() {
    let lua = make_vm();
    lua.load(r#"
        local tree = luna.crafting.newUpgradeTree("tech")
        tree:addNode("forge", 5)
        tree:unlock("forge")
        assert(tree:isUnlocked("forge"), "forge unlocked")
        local ok = tree:resetNode("forge")
        assert(ok, "reset ok")
        assert(not tree:isUnlocked("forge"), "forge re-locked")
        local unlocked = tree:getUnlockedIds()
        assert(#unlocked == 0, "no unlocked nodes")
    "#).exec().unwrap();
}

#[test]
fn craft_queue_clear() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r = luna.crafting.newRecipe("plank")
        r:setTime(10.0)
        reg:add(r)
        local station = luna.crafting.newStation("sawmill")
        local q = luna.crafting.newQueue(3)
        q:enqueue(reg, "plank", station)
        q:enqueue(reg, "plank", station)
        assert(q:count() == 2, "2 jobs")
        q:clear()
        assert(q:count() == 0, "0 after clear")
    "#).exec().unwrap();
}

#[test]
fn craft_queue_get_all_jobs() {
    let lua = make_vm();
    lua.load(r#"
        local reg = luna.crafting.newRegistry()
        local r1 = luna.crafting.newRecipe("bolt"); r1:setTime(5.0); reg:add(r1)
        local r2 = luna.crafting.newRecipe("nut"); r2:setTime(3.0); reg:add(r2)
        local station = luna.crafting.newStation("workshop")
        local q = luna.crafting.newQueue(5)
        q:enqueue(reg, "bolt", station)
        q:enqueue(reg, "nut", station)
        local jobs = q:getAllJobs()
        assert(#jobs == 2, "2 jobs in getAllJobs")
        local recipes = {}
        for _, j in ipairs(jobs) do
            recipes[j.recipeId] = true
            assert(j.id ~= nil, "job has id")
            assert(j.quantity >= 1, "job has quantity")
        end
        assert(recipes["bolt"], "bolt job present")
        assert(recipes["nut"], "nut job present")
    "#).exec().unwrap();
}
'''

tst = tst.rstrip() + "\n" + new_tests
with open(TEST, "w", encoding="utf-8") as f:
    f.write(tst)
print("crafting_tests.rs updated")
print("Done - crafting module expanded")
