"""
Fix round 2: correct the remaining compilation errors.
"""

print("=== FIX A: crafting/mod.rs ===")
with open(r"src\crafting\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# Fix all_jobs: .values() → .iter(), and id is u32 (copy) not String
old_alljobs = '''    /// Return all job summaries as (id, recipe_id, quantity, progress, paused) tuples.
    pub fn all_jobs(&self) -> Vec<(String, String, u32, f64, bool)> {
        self.jobs.values()
            .map(|j| (j.id.clone(), j.recipe_id.clone(), j.quantity, j.progress, j.paused))
            .collect()
    }'''
new_alljobs = '''    /// Return all job summaries as (id, recipe_id, quantity, progress, paused) tuples.
    pub fn all_jobs(&self) -> Vec<(u32, String, u32, f64, bool)> {
        self.jobs.iter()
            .map(|j| (j.id, j.recipe_id.clone(), j.quantity, j.progress, j.paused))
            .collect()
    }'''
dom = dom.replace(old_alljobs, new_alljobs, 1)

# Fix set_level anchor: actual can_use signature is `recipe: &Recipe`
dom = dom.replace(
    "\n    pub fn can_use(&self, recipe: &Recipe) -> bool {",
    "\n    /// Force-set the skill level and reset XP to 0.\n    pub fn set_level(&mut self, level: u32) {\n        self.level = level;\n        self.xp = 0.0;\n    }\n\n    pub fn can_use(&self, recipe: &Recipe) -> bool {",
    1
)

# Fix reset_node / get_unlocked_ids: actual node_ids returns &[String]
dom = dom.replace(
    "\n    pub fn node_ids(&self) -> &[String] { &self.order }",
    "\n    /// Re-lock a previously unlocked node. Returns false if node not found.\n    pub fn reset_node(&mut self, id: &str) -> bool {\n        if let Some(node) = self.nodes.get_mut(id) {\n            node.unlocked = false;\n            true\n        } else { false }\n    }\n\n    /// Returns all currently unlocked node IDs.\n    pub fn get_unlocked_ids(&self) -> Vec<String> {\n        self.nodes.iter().filter(|(_, n)| n.unlocked).map(|(id, _)| id.clone()).collect()\n    }\n\n    pub fn node_ids(&self) -> &[String] { &self.order }",
    1
)

with open(r"src\crafting\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("crafting/mod.rs fixed")

# Fix crafting_api.rs: getAllJobs reads u32 id now
with open(r"src\lua_api\crafting_api.rs", "r", encoding="utf-8") as f:
    api = f.read()
old_getall = '''            for (i, (id, recipe_id, qty, progress, paused)) in jobs.into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("id", id)?;'''
new_getall = '''            for (i, (id, recipe_id, qty, progress, paused)) in jobs.into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("id", id as u64)?;'''
api = api.replace(old_getall, new_getall)
with open(r"src\lua_api\crafting_api.rs", "w", encoding="utf-8") as f:
    f.write(api)
print("crafting_api.rs getAllJobs id type fixed")

print("=== FIX B: cardgame/mod.rs – CardPool.get_types ===")
with open(r"src\cardgame\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# CardPool.size() is multi-line, use the comment before it as anchor
dom = dom.replace(
    "    /// Number of entries.\n    pub fn size(&self) -> usize {\n        self.entries.len()\n    }\n}",
    "    /// Number of entries.\n    pub fn size(&self) -> usize {\n        self.entries.len()\n    }\n\n    /// Returns all card types currently registered in the pool.\n    pub fn get_types(&self) -> Vec<String> {\n        self.entries.iter().map(|e| e.card_type.clone()).collect()\n    }\n}",
    1  # Only the LAST occurrence (CardPool's)
)

with open(r"src\cardgame\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("cardgame/mod.rs CardPool.get_types fixed")

print("=== FIX C: quest/mod.rs – fix Quest methods and move QuestLog methods ===")
with open(r"src\quest\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# Remove wrongly-inserted QuestLog methods from Quest impl block
# (they reference self.quests which doesn't exist on Quest)
wrong_quest_ids = '''
    /// Convenience: IDs of all active quests.
    pub fn active_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Active)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Convenience: IDs of all completed quests.
    pub fn completed_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Completed)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Convenience: IDs of all failed quests.
    pub fn failed_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Failed)
            .map(|(id, _)| id.clone())
            .collect()
    }
'''
dom = dom.replace(wrong_quest_ids, '', 1)

# Fix completion_percent: Quest uses stages not objectives, Done not Completed
old_cp = '''    /// Returns percentage of non-optional objectives that are Completed (0.0–100.0).
    pub fn completion_percent(&self) -> f64 {
        let mandatory: Vec<_> = self.objectives.values()
            .filter(|o| !o.optional)
            .collect();
        if mandatory.is_empty() { return 100.0; }
        let done = mandatory.iter()
            .filter(|o| o.status == ObjectiveStatus::Completed)
            .count();
        done as f64 / mandatory.len() as f64 * 100.0
    }'''
new_cp = '''    /// Returns percentage of mandatory objectives that are Done across all stages (0.0–100.0).
    pub fn completion_percent(&self) -> f64 {
        let all_objs: Vec<_> = self.stages.iter()
            .flat_map(|s| s.objectives.iter())
            .filter(|o| o.mandatory)
            .collect();
        if all_objs.is_empty() { return 100.0; }
        let done = all_objs.iter().filter(|o| o.status == ObjectiveStatus::Done).count();
        done as f64 / all_objs.len() as f64 * 100.0
    }'''
dom = dom.replace(old_cp, new_cp, 1)

# Fix active_objective_ids: uses stages, Active not InProgress
old_aoi = '''    /// Returns the IDs of all objectives currently InProgress.
    pub fn active_objective_ids(&self) -> Vec<String> {
        self.objectives.iter()
            .filter(|(_, o)| o.status == ObjectiveStatus::InProgress)
            .map(|(id, _)| id.clone())
            .collect()
    }'''
new_aoi = '''    /// Returns the IDs of all objectives currently Active across all stages.
    pub fn active_objective_ids(&self) -> Vec<String> {
        self.stages.iter()
            .flat_map(|s| s.objectives.iter())
            .filter(|o| o.status == ObjectiveStatus::Active)
            .map(|o| o.id.clone())
            .collect()
    }'''
dom = dom.replace(old_aoi, new_aoi, 1)

# Fix reset_objective: uses stages, Active not InProgress
old_ro = '''    /// Reset an objective back to InProgress. Returns false if not found.
    pub fn reset_objective(&mut self, id: &str) -> bool {
        if let Some(obj) = self.objectives.get_mut(id) {
            obj.status = ObjectiveStatus::InProgress;
            true
        } else {
            false
        }
    }'''
new_ro = '''    /// Reset an objective back to Active (in progress). Returns false if not found.
    pub fn reset_objective(&mut self, id: &str) -> bool {
        for stage in &mut self.stages {
            if let Some(obj) = stage.objectives.iter_mut().find(|o| o.id == id) {
                obj.status = ObjectiveStatus::Active;
                return true;
            }
        }
        false
    }'''
dom = dom.replace(old_ro, new_ro, 1)

# Now add QuestLog methods before QuestLog's advance_objective
# QuestLog::advance_objective has `quest_id` and `obj_id` parameters
questlog_ids = '''
    /// Convenience: IDs of all active quests.
    pub fn active_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Active)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Convenience: IDs of all completed quests.
    pub fn completed_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Completed)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Convenience: IDs of all failed quests.
    pub fn failed_ids(&self) -> Vec<String> {
        self.quests.iter()
            .filter(|(_, q)| q.status == QuestStatus::Failed)
            .map(|(id, _)| id.clone())
            .collect()
    }
'''
# QuestLog::advance_objective has (quest_id, obj_id, amount) - use this unique signature
dom = dom.replace(
    "\n    pub fn advance_objective(&mut self, quest_id: &str, obj_id: &str, amount: u32) -> bool {",
    questlog_ids + "\n    pub fn advance_objective(&mut self, quest_id: &str, obj_id: &str, amount: u32) -> bool {",
    1
)

with open(r"src\quest\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("quest/mod.rs fixed")

print("=== FIX D: inventory/mod.rs – Container methods ===")
with open(r"src\inventory\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# Insert before the ItemSet section divider (box-drawing chars ─)
# The Container impl block ends with `}\n\n// ─── ItemSet`
container_extra = '''
    /// Count all items of `item_type` across all slots in this container.
    pub fn count_item(&self, item_type: &str) -> u32 {
        self.slots.iter()
            .filter_map(|s| s.stack.as_ref())
            .filter(|st| st.item.item_type == item_type)
            .map(|st| st.quantity)
            .sum()
    }

    /// Returns true if this container holds at least `qty` of `item_type`.
    pub fn has_item(&self, item_type: &str, qty: u32) -> bool {
        self.count_item(item_type) >= qty
    }

    /// Remove up to `qty` items of `item_type`. Returns true if the full amount was removed.
    pub fn remove_item(&mut self, item_type: &str, qty: u32) -> bool {
        if !self.has_item(item_type, qty) { return false; }
        let mut remaining = qty;
        for slot in &mut self.slots {
            if remaining == 0 { break; }
            if let Some(stack) = slot.stack.as_mut() {
                if stack.item.item_type == item_type {
                    let take = stack.quantity.min(remaining);
                    stack.quantity -= take;
                    remaining -= take;
                    if stack.quantity == 0 {
                        slot.stack = None;
                    }
                }
            }
        }
        remaining == 0
    }

    /// Returns a summary of all occupied slots as (item_type, quantity) pairs.
    pub fn to_item_list(&self) -> Vec<(String, u32)> {
        self.slots.iter()
            .filter_map(|s| s.stack.as_ref())
            .map(|st| (st.item.item_type.clone(), st.quantity))
            .collect()
    }
'''

# Use end of add_item's closing brace before the section divider
old_end = "        true\n    }\n}\n"
new_end = "        true\n    }\n" + container_extra + "}\n"
# Replace only the first occurrence which is in the Container impl block
dom = dom.replace(old_end, new_end, 1)

with open(r"src\inventory\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("inventory/mod.rs Container methods fixed")

print("=== All round-2 fixes applied! ===")
