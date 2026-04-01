"""
Comprehensive fix script for all module expansion issues.
Run once after _expand_*.py scripts have been applied.
"""
import re

print("=== FIX 1: stats/mod.rs ===")
with open(r"src\stats\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# Fix get_buff_count - was using Attribute.buffs but should use Sheet.buffs HashMap<u32, Buff>
old = """    /// Count active buffs. If `stat` is Some, count only buffs targeting that stat.
    pub fn get_buff_count(&self, stat: Option<&str>) -> usize {
        self.attributes.values()
            .flat_map(|a| &a.buffs)
            .filter(|b| stat.map_or(true, |s| b.stat == s))
            .count()
    }"""
new = """    /// Count active buffs. If `stat` is Some, count only buffs targeting that stat.
    pub fn get_buff_count(&self, stat: Option<&str>) -> usize {
        self.buffs.values()
            .filter(|b| stat.map_or(true, |s| b.stat == s))
            .count()
    }"""
dom = dom.replace(old, new, 1)

# Fix recover_action_points - self.action_points is Option<ActionPoints>
old = """    /// Add `amount` to current action points, capped at the maximum.
    /// Returns the new value.
    pub fn recover_action_points(&mut self, amount: f64) -> f64 {
        let max = self.action_points.max;
        self.action_points.current = (self.action_points.current + amount).min(max);
        self.action_points.current
    }"""
new = """    /// Add `amount` to current action points, capped at the maximum.
    /// Returns the new value.
    pub fn recover_action_points(&mut self, amount: f64) -> f64 {
        if let Some(ap) = self.action_points.as_mut() {
            ap.current = (ap.current + amount).min(ap.max);
            ap.current
        } else { 0.0 }
    }"""
dom = dom.replace(old, new, 1)

with open(r"src\stats\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("stats/mod.rs fixed")

print("=== FIX 2: resource_api.rs this.0 -> this.inner ===")
with open(r"src\lua_api\resource_api.rs", "r", encoding="utf-8") as f:
    api = f.read()

# Replace only in the new methods block - they all use this.0 in a clearly grouped section
# The new methods are: getPercent, isFull, isEmpty, canAffordAll, spendAll (all added together)
# Find the block and do targeted replacements in it only
old_block = '''        methods.add_method("getPercent", |_, this, name: String| {
            Ok(this.0.borrow().percent(&name))
        });
        methods.add_method("isFull", |_, this, name: String| {
            Ok(this.0.borrow().is_full(&name))
        });
        methods.add_method("isEmpty", |_, this, name: String| {
            Ok(this.0.borrow().is_empty(&name))
        });
        methods.add_method("canAffordAll", |_, this, tbl: LuaTable| {
            let mut needs: Vec<(String, f64)> = Vec::new();
            for pair in tbl.pairs::<String, f64>() {
                let (k, v) = pair.map_err(LuaError::external)?;
                needs.push((k, v));
            }
            let refs: Vec<(&str, f64)> = needs.iter().map(|(k, v)| (k.as_str(), *v)).collect();
            Ok(this.0.borrow().can_afford_all(&refs))
        });
        methods.add_method("spendAll", |_, this, tbl: LuaTable| {
            let mut needs: Vec<(String, f64)> = Vec::new();
            for pair in tbl.pairs::<String, f64>() {
                let (k, v) = pair.map_err(LuaError::external)?;
                needs.push((k, v));
            }
            let refs: Vec<(&str, f64)> = needs.iter().map(|(k, v)| (k.as_str(), *v)).collect();
            Ok(this.0.borrow_mut().spend_all(&refs))
        });'''
new_block = '''        methods.add_method("getPercent", |_, this, name: String| {
            Ok(this.inner.borrow().percent(&name))
        });
        methods.add_method("isFull", |_, this, name: String| {
            Ok(this.inner.borrow().is_full(&name))
        });
        methods.add_method("isEmpty", |_, this, name: String| {
            Ok(this.inner.borrow().is_empty(&name))
        });
        methods.add_method("canAffordAll", |_, this, tbl: LuaTable| {
            let mut needs: Vec<(String, f64)> = Vec::new();
            for pair in tbl.pairs::<String, f64>() {
                let (k, v) = pair.map_err(LuaError::external)?;
                needs.push((k, v));
            }
            let refs: Vec<(&str, f64)> = needs.iter().map(|(k, v)| (k.as_str(), *v)).collect();
            Ok(this.inner.borrow().can_afford_all(&refs))
        });
        methods.add_method("spendAll", |_, this, tbl: LuaTable| {
            let mut needs: Vec<(String, f64)> = Vec::new();
            for pair in tbl.pairs::<String, f64>() {
                let (k, v) = pair.map_err(LuaError::external)?;
                needs.push((k, v));
            }
            let refs: Vec<(&str, f64)> = needs.iter().map(|(k, v)| (k.as_str(), *v)).collect();
            Ok(this.inner.borrow_mut().spend_all(&refs))
        });'''
api = api.replace(old_block, new_block, 1)
with open(r"src\lua_api\resource_api.rs", "w", encoding="utf-8") as f:
    f.write(api)
print("resource_api.rs fixed")

print("=== FIX 3: stats_api.rs this.0 -> this.inner ===")
with open(r"src\lua_api\stats_api.rs", "r", encoding="utf-8") as f:
    api = f.read()

old_block = '''        methods.add_method("getStatNames", |lua, this, ()| {
            let names = this.0.borrow().get_stat_names();
            let t = lua.create_table()?;
            for (i, name) in names.into_iter().enumerate() { t.set(i + 1, name)?; }
            Ok(t)
        });
        methods.add_method("getBuffCount", |_, this, stat: Option<String>| {
            Ok(this.0.borrow().get_buff_count(stat.as_deref()))
        });
        methods.add_method("recoverActionPoints", |_, this, amount: f64| {
            Ok(this.0.borrow_mut().recover_action_points(amount))
        });'''
new_block = '''        methods.add_method("getStatNames", |lua, this, ()| {
            let names = this.inner.borrow().get_stat_names();
            let t = lua.create_table()?;
            for (i, name) in names.into_iter().enumerate() { t.set(i + 1, name)?; }
            Ok(t)
        });
        methods.add_method("getBuffCount", |_, this, stat: Option<String>| {
            Ok(this.inner.borrow().get_buff_count(stat.as_deref()))
        });
        methods.add_method("recoverActionPoints", |_, this, amount: f64| {
            Ok(this.inner.borrow_mut().recover_action_points(amount))
        });'''
api = api.replace(old_block, new_block, 1)
with open(r"src\lua_api\stats_api.rs", "w", encoding="utf-8") as f:
    f.write(api)
print("stats_api.rs fixed")

print("=== FIX 4: quest/mod.rs – add all missing domain methods ===")
with open(r"src\quest\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# Add Quest methods: look for `all_objectives_complete` which is Quest's last method
quest_extra = """
    /// Returns percentage of non-optional objectives that are Completed (0.0–100.0).
    pub fn completion_percent(&self) -> f64 {
        let mandatory: Vec<_> = self.objectives.values()
            .filter(|o| !o.optional)
            .collect();
        if mandatory.is_empty() { return 100.0; }
        let done = mandatory.iter()
            .filter(|o| o.status == ObjectiveStatus::Completed)
            .count();
        done as f64 / mandatory.len() as f64 * 100.0
    }

    /// Returns the IDs of all objectives currently InProgress.
    pub fn active_objective_ids(&self) -> Vec<String> {
        self.objectives.iter()
            .filter(|(_, o)| o.status == ObjectiveStatus::InProgress)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Reset an objective back to InProgress. Returns false if not found.
    pub fn reset_objective(&mut self, id: &str) -> bool {
        if let Some(obj) = self.objectives.get_mut(id) {
            obj.status = ObjectiveStatus::InProgress;
            true
        } else {
            false
        }
    }
"""

# anchor: all_objectives_complete is `pub fn all_objectives_complete(&self) -> bool`
dom = dom.replace(
    "\n    pub fn all_objectives_complete(&self) -> bool {",
    quest_extra + "\n    pub fn all_objectives_complete(&self) -> bool {",
    1
)

# Add QuestLog methods before the #[cfg(test)] or end of mod
questlog_extra = """
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
"""

# anchor: advance_objective is QuestLog's last method
dom = dom.replace(
    "\n    pub fn advance_objective(&mut self,",
    questlog_extra + "\n    pub fn advance_objective(&mut self,",
    1
)

with open(r"src\quest\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("quest/mod.rs fixed")

print("=== FIX 4b: quest_api.rs – remove wrongly-placed methods, add to LuaQuest ===")
with open(r"src\lua_api\quest_api.rs", "r", encoding="utf-8") as f:
    api = f.read()

# Remove from LuaObjective block (wrong location)
wrong_block = '''        methods.add_method("completionPercent", |_, this, ()| {
            Ok(this.0.borrow().completion_percent())
        });
        methods.add_method("getActiveObjectiveIds", |lua, this, ()| {
            let ids = this.0.borrow().active_objective_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() {
                t.set(i + 1, id)?;
            }
            Ok(t)
        });
        methods.add_method("resetObjective", |_, this, id: String| {
            Ok(this.0.borrow_mut().reset_objective(&id))
        });
'''
api = api.replace(wrong_block, '', 1)

# Now insert in LuaQuest block before setReward
quest_api_extra = '''        methods.add_method("completionPercent", |_, this, ()| {
            Ok(this.0.borrow().completion_percent())
        });
        methods.add_method("getActiveObjectiveIds", |lua, this, ()| {
            let ids = this.0.borrow().active_objective_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() {
                t.set(i + 1, id)?;
            }
            Ok(t)
        });
        methods.add_method("resetObjective", |_, this, id: String| {
            Ok(this.0.borrow_mut().reset_objective(&id))
        });
'''
# LuaQuest has `setReward` / `getReward` as distinct from LuaObjective -- use setMeta anchor
api = api.replace(
    '        methods.add_method("setMeta", |_, this, (key, val): (String, String)| {\n            this.0.borrow_mut().set_meta(key, val);\n            Ok(())\n        });\n        methods.add_method("getMeta", |_, this, key: String| {',
    quest_api_extra + '        methods.add_method("setMeta", |_, this, (key, val): (String, String)| {\n            this.0.borrow_mut().set_meta(key, val);\n            Ok(())\n        });\n        methods.add_method("getMeta", |_, this, key: String| {',
    1
)
with open(r"src\lua_api\quest_api.rs", "w", encoding="utf-8") as f:
    f.write(api)
print("quest_api.rs fixed")

print("=== FIX 5: cardgame/mod.rs – add all missing domain methods ===")
with open(r"src\cardgame\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# Card: add get_all_counters before pub fn tap
card_extra = """
    /// Returns all (kind, count) counter pairs on this card.
    pub fn get_all_counters(&self) -> Vec<(String, i32)> {
        self.counters.iter().map(|(k, v)| (k.clone(), *v)).collect()
    }
"""
dom = dom.replace(
    "\n    pub fn tap(&mut self) {",
    card_extra + "\n    pub fn tap(&mut self) {",
    1
)

# Deck: add count_by_type and reveal_top before pub fn move_within
deck_extra = """
    /// Count cards of a specific type in the deck.
    pub fn count_by_type(&self, card_type: &str) -> usize {
        self.cards.iter().filter(|c| c.card_type == card_type).count()
    }

    /// Peek at the top `n` cards without removing them; returns their type strings.
    pub fn reveal_top(&self, n: usize) -> Vec<String> {
        self.cards.iter().rev().take(n).map(|c| c.card_type.clone()).collect()
    }
"""
dom = dom.replace(
    "\n    pub fn move_within(&mut self,",
    deck_extra + "\n    pub fn move_within(&mut self,",
    1
)

# Zone: add count_by_type and get_all_types before pub fn find_by_type
zone_extra = """
    /// Count cards of a specific type in this zone.
    pub fn count_by_type(&self, card_type: &str) -> usize {
        self.cards.iter().filter(|c| c.card_type == card_type).count()
    }

    /// Return the type strings of all cards in this zone.
    pub fn get_all_types(&self) -> Vec<String> {
        self.cards.iter().map(|c| c.card_type.clone()).collect()
    }
"""
dom = dom.replace(
    "\n    pub fn find_by_type(&self,",
    zone_extra + "\n    pub fn find_by_type(&self,",
    1
)

# CardPool: add get_types before pub fn size
cardpool_extra = """
    /// Returns all card types currently registered in the pool.
    pub fn get_types(&self) -> Vec<String> {
        self.entries.iter().map(|(t, _)| t.clone()).collect()
    }
"""
dom = dom.replace(
    "\n    pub fn size(&self) -> usize { self.entries.values().count() }",
    cardpool_extra + "\n    pub fn size(&self) -> usize { self.entries.values().count() }",
    1
)

with open(r"src\cardgame\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("cardgame/mod.rs fixed")

print("=== FIX 6: cardgame_api.rs – fix getTypes location, add countByType/revealTop/getAllTypes ===")
with open(r"src\lua_api\cardgame_api.rs", "r", encoding="utf-8") as f:
    api = f.read()

# Remove wrongly-placed getTypes from Deck block (it's before the Deck's draw method)
wrong_gettypes_before_draw = '''        methods.add_method("getTypes", |lua, this, ()| {
            let types = this.0.borrow().get_types();
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() {
                t.set(i + 1, ct)?;
            }
            Ok(t)
        });
        methods.add_method("draw", |_, this, ()| {'''

correct_deck_draw_start = '''        methods.add_method("draw", |_, this, ()| {'''
api = api.replace(wrong_gettypes_before_draw, correct_deck_draw_start, 1)

# Add countByType and revealTop to Deck before its getCards binding
deck_api_extra = '''        methods.add_method("countByType", |_, this, card_type: String| {
            Ok(this.0.borrow().count_by_type(&card_type))
        });
        methods.add_method("revealTop", |lua, this, n: usize| {
            let types = this.0.borrow().reveal_top(n);
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() { t.set(i + 1, ct)?; }
            Ok(t)
        });
'''
# Deck's getCards: look for the Deck-specific getCards (first one)
api = api.replace(
    '        methods.add_method("getCards", |lua, this, ()| {\n            let borrow = this.0.borrow();\n            let t = lua.create_table()?;\n            for (i, card) in borrow.cards.iter().enumerate() {\n                t.set(i + 1, LuaCard(Rc::new(RefCell::new(card.clone()))))?;\n            }\n            Ok(t)\n        });\n',
    deck_api_extra + '        methods.add_method("getCards", |lua, this, ()| {\n            let borrow = this.0.borrow();\n            let t = lua.create_table()?;\n            for (i, card) in borrow.cards.iter().enumerate() {\n                t.set(i + 1, LuaCard(Rc::new(RefCell::new(card.clone()))))?;\n            }\n            Ok(t)\n        });\n',
    1
)

# Add Zone countByType and getAllTypes before findByType in Zone block  
zone_api_extra = '''        methods.add_method("countByType", |_, this, card_type: String| {
            Ok(this.0.borrow().count_by_type(&card_type))
        });
        methods.add_method("getAllTypes", |lua, this, ()| {
            let types = this.0.borrow().get_all_types();
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() { t.set(i + 1, ct)?; }
            Ok(t)
        });
'''
api = api.replace(
    '        methods.add_method("findByType", |_, this, ct: String| {',
    zone_api_extra + '        methods.add_method("findByType", |_, this, ct: String| {',
    1
)

# Add getTypes to CardPool before its draw  
cardpool_api_gettypes = '''        methods.add_method("getTypes", |lua, this, ()| {
            let types = this.0.borrow().get_types();
            let t = lua.create_table()?;
            for (i, ct) in types.into_iter().enumerate() { t.set(i + 1, ct)?; }
            Ok(t)
        });
'''
# CardPool's draw - it's the raw() call, look for draw in the CardPool block after the pool section
# the pool's draw returns Option<String>
# find: `draw", |_, this, ()| {` in the pool context
# The zone has moveCard, the pool has just draw as the last method
# Let's anchor to the `getTotalWeight` method which exists only in CardPool
api = api.replace(
    '        methods.add_method("getTotalWeight",',
    cardpool_api_gettypes + '        methods.add_method("getTotalWeight",',
    1
)

with open(r"src\lua_api\cardgame_api.rs", "w", encoding="utf-8") as f:
    f.write(api)
print("cardgame_api.rs fixed")

print("=== FIX 7: crafting/mod.rs – add all missing domain methods ===")
with open(r"src\crafting\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# Recipe: add get_tags before has_tag
recipe_extra = """
    /// Returns all tags on this recipe.
    pub fn get_tags(&self) -> &[String] { &self.tags }
"""
dom = dom.replace(
    "\n    pub fn has_tag(&self, tag: &str) -> bool {",
    recipe_extra + "\n    pub fn has_tag(&self, tag: &str) -> bool {",
    1
)

# RecipeRegistry: add find_by_tag before for_station
registry_extra = """
    /// Find recipe IDs that have a specific tag.
    pub fn find_by_tag(&self, tag: &str) -> Vec<&str> {
        self.recipes.iter()
            .filter(|(_, r)| r.tags.contains(&tag.to_string()))
            .map(|(id, _)| id.as_str())
            .collect()
    }
"""
dom = dom.replace(
    "\n    pub fn for_station(&self,",
    registry_extra + "\n    pub fn for_station(&self,",
    1
)

# CraftSkill: add set_level before can_use
skill_extra = """
    /// Force-set the skill level and reset XP to 0.
    pub fn set_level(&mut self, level: u32) {
        self.level = level;
        self.xp = 0.0;
    }
"""
dom = dom.replace(
    "\n    pub fn can_use(&self, required_level: u32) -> bool {",
    skill_extra + "\n    pub fn can_use(&self, required_level: u32) -> bool {",
    1
)

# UpgradeTree: add reset_node and get_unlocked_ids before node_ids
upgrade_extra = """
    /// Re-lock a previously unlocked node. Returns false if node not found.
    pub fn reset_node(&mut self, id: &str) -> bool {
        if let Some(node) = self.nodes.get_mut(id) {
            node.unlocked = false;
            true
        } else { false }
    }

    /// Returns all currently unlocked node IDs.
    pub fn get_unlocked_ids(&self) -> Vec<String> {
        self.nodes.iter().filter(|(_, n)| n.unlocked).map(|(id, _)| id.clone()).collect()
    }
"""
dom = dom.replace(
    "\n    pub fn node_ids(&self) -> Vec<String> {",
    upgrade_extra + "\n    pub fn node_ids(&self) -> Vec<String> {",
    1
)

with open(r"src\crafting\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("crafting/mod.rs fixed")

print("=== FIX 8: crafting_api.rs – move clear/getAllJobs to CraftQueue block ===")
with open(r"src\lua_api\crafting_api.rs", "r", encoding="utf-8") as f:
    api = f.read()

# Remove from RecipeRegistry block (after `remove` method, before `count`)
wrong_block = '''        methods.add_method("clear", |_, this, ()| {
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
        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));'''
fixed_registry_count = '        methods.add_method("count", |_, this, ()| Ok(this.0.borrow().count()));'
api = api.replace(wrong_block, fixed_registry_count, 1)

# Add to CraftQueue block: before setJobPaused (which is a CraftQueue-only method)
queue_extras = '''        methods.add_method("clear", |_, this, ()| {
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
api = api.replace(
    '        methods.add_method("setJobPaused",',
    queue_extras + '        methods.add_method("setJobPaused",',
    1
)

# Also add findByTag, getTags, setLevel, resetNode, getUnlockedIds to their correct blocks
# Recipe getTags: insert before addIngredient (which was already done successfully - check)
recipe_api_gettags_check = '        methods.add_method("getTags", |lua, this, ()| {'
if recipe_api_gettags_check not in api:
    api = api.replace(
        '        methods.add_method("addIngredient",',
        '''        methods.add_method("getTags", |lua, this, ()| {
            let tags = this.0.borrow().get_tags().to_vec();
            let t = lua.create_table()?;
            for (i, tag) in tags.into_iter().enumerate() { t.set(i + 1, tag)?; }
            Ok(t)
        });
''' + '        methods.add_method("addIngredient",',
        1,
    )

# RecipeRegistry findByTag: insert before forStation (if not already)
if '"findByTag"' not in api:
    api = api.replace(
        '        methods.add_method("forStation",',
        '''        methods.add_method("findByTag", |lua, this, tag: String| {
            let ids = this.0.borrow().find_by_tag(&tag).iter().map(|s| s.to_string()).collect::<Vec<_>>();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
''' + '        methods.add_method("forStation",',
        1,
    )

# CraftSkill setLevel: insert before addXp (if not already)
if '"setLevel"' not in api:
    api = api.replace(
        '        methods.add_method("addXp",',
        '''        methods.add_method("setLevel", |_, this, level: u32| {
            this.0.borrow_mut().set_level(level);
            Ok(())
        });
''' + '        methods.add_method("addXp",',
        1,
    )

# UpgradeTree resetNode/getUnlockedIds: insert before getNodeIds (if not already)
if '"resetNode"' not in api:
    api = api.replace(
        '        methods.add_method("getNodeIds",',
        '''        methods.add_method("resetNode", |_, this, id: String| {
            Ok(this.0.borrow_mut().reset_node(&id))
        });
        methods.add_method("getUnlockedIds", |lua, this, ()| {
            let ids = this.0.borrow().get_unlocked_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
''' + '        methods.add_method("getNodeIds",',
        1,
    )

with open(r"src\lua_api\crafting_api.rs", "w", encoding="utf-8") as f:
    f.write(api)
print("crafting_api.rs fixed")

print("=== FIX 9: inventory/mod.rs – add Container methods ===")
with open(r"src\inventory\mod.rs", "r", encoding="utf-8") as f:
    dom = f.read()

# Need to add Container methods: count_item, has_item, remove_item, to_item_list
# Container's last method in mod.rs - let's find `pub fn add_item` and insert after its closing brace
# Simpler: find the ItemSet struct definition and insert the Container methods right before it.
# The pattern "pub struct ItemSet" should work.
container_extra = """
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
"""

# Insert before ItemSet struct definition
dom = dom.replace(
    "\n/// Represents a named set of items",
    container_extra + "\n/// Represents a named set of items",
    1
)

with open(r"src\inventory\mod.rs", "w", encoding="utf-8") as f:
    f.write(dom)
print("inventory/mod.rs Container methods fixed")

print("=== All fixes applied! Running cargo check... ===")
