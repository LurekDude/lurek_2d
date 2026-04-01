"""Expand quest module with:
Domain: Quest::completion_percent(), active_objective_ids(), reset_objective()
         QuestLog::active_ids(), completed_ids(), failed_ids()
API: Quest.completionPercent, getActiveObjectiveIds, resetObjective
     QuestLog: getActiveQuestIds, getCompletedQuestIds, getFailedQuestIds
Tests: 5 new tests
"""

MOD = r"src\quest\mod.rs"
with open(MOD, "r", encoding="utf-8") as f:
    dom = f.read()

quest_extra = """
    /// Returns percentage of mandatory (non-optional) objectives that are completed (0.0–100.0).
    pub fn completion_percent(&self) -> f64 {
        let mandatory: Vec<_> = self.objectives.values()
            .filter(|o| !o.optional)
            .collect();
        if mandatory.is_empty() { return 100.0; }
        let done = mandatory.iter().filter(|o| o.status == ObjectiveStatus::Completed).count();
        done as f64 / mandatory.len() as f64 * 100.0
    }

    /// Returns the IDs of all objectives currently in progress.
    pub fn active_objective_ids(&self) -> Vec<String> {
        self.objectives.iter()
            .filter(|(_, o)| o.status == ObjectiveStatus::InProgress)
            .map(|(id, _)| id.clone())
            .collect()
    }

    /// Reset an objective back to InProgress status. Returns false if not found.
    pub fn reset_objective(&mut self, id: &str) -> bool {
        if let Some(obj) = self.objectives.get_mut(id) {
            obj.status = ObjectiveStatus::InProgress;
            true
        } else {
            false
        }
    }
"""

questlog_extra = """
    /// Convenience: returns IDs of all active quests.
    pub fn active_ids(&self) -> Vec<String> {
        self.quests_with_status(QuestStatus::Active)
    }

    /// Convenience: returns IDs of all completed quests.
    pub fn completed_ids(&self) -> Vec<String> {
        self.quests_with_status(QuestStatus::Completed)
    }

    /// Convenience: returns IDs of all failed quests.
    pub fn failed_ids(&self) -> Vec<String> {
        self.quests_with_status(QuestStatus::Failed)
    }
"""

# Find the Quest::all_objectives_complete (or last domain method) and insert before #[cfg(test)] or QuestLog
# Look for the Quest impl closing brace (before the QuestLog struct or separator comment)
# Insert after all_objectives_complete closure
dom = dom.replace(
    "\n    pub fn is_visible(&self) -> bool { self.visible }\n    pub fn set_visible(&mut self, v: bool) { self.visible = v; }",
    "\n    pub fn is_visible(&self) -> bool { self.visible }\n    pub fn set_visible(&mut self, v: bool) { self.visible = v; }" + quest_extra,
    1,
)

# Find QuestLog impl and find its last method to insert after it
# The last QuestLog method should be advance_objective or quests_with_status
dom = dom.replace(
    "\n    pub fn quests_with_status(&self, status: QuestStatus) -> Vec<String> {",
    questlog_extra + "\n    pub fn quests_with_status(&self, status: QuestStatus) -> Vec<String> {",
    1,
)

with open(MOD, "w", encoding="utf-8") as f:
    f.write(dom)
print("quest/mod.rs updated")

# ---- Lua API ----------------------------------------------------------------
API = r"src\lua_api\quest_api.rs"
with open(API, "r", encoding="utf-8") as f:
    api = f.read()

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

questlog_api_extra = '''        methods.add_method("getActiveQuestIds", |lua, this, ()| {
            let ids = this.0.borrow().active_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        methods.add_method("getCompletedQuestIds", |lua, this, ()| {
            let ids = this.0.borrow().completed_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        methods.add_method("getFailedQuestIds", |lua, this, ()| {
            let ids = this.0.borrow().failed_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
'''

# Insert quest extras before the `isVisible` binding (last quest method)
api = api.replace(
    '        methods.add_method("isVisible",',
    quest_api_extra + '        methods.add_method("isVisible",',
    1,
)

# Insert questlog extras before `getQuestsWithStatus`
api = api.replace(
    '        methods.add_method("getQuestsWithStatus",',
    questlog_api_extra + '        methods.add_method("getQuestsWithStatus",',
    1,
)

with open(API, "w", encoding="utf-8") as f:
    f.write(api)
print("quest_api.rs updated")

# ---- Tests ----------------------------------------------------------------
TEST = r"tests\quest_tests.rs"
with open(TEST, "r", encoding="utf-8") as f:
    tst = f.read()

new_tests = r'''
#[test]
fn quest_completion_percent() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.quest.newQuest("main_q")
        q:addObjective("o1", "kill 5 enemies", 5)
        q:addObjective("o2", "collect loot", 1)
        -- none complete yet
        assert(math.abs(q:completionPercent() - 0.0) < 0.01, "0% initially")
        q:advanceObjective("o1", 5)
        -- one of two done -> 50%
        assert(math.abs(q:completionPercent() - 50.0) < 0.01, "50% after first objective")
        q:advanceObjective("o2", 1)
        assert(math.abs(q:completionPercent() - 100.0) < 0.01, "100% both done")
    "#).exec().unwrap();
}

#[test]
fn quest_active_objective_ids() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.quest.newQuest("side_q")
        q:addObjective("a", "find key", 1)
        q:addObjective("b", "unlock door", 1)
        q:advanceObjective("a", 1)
        local active = q:getActiveObjectiveIds()
        assert(#active == 1, "1 still active")
        assert(active[1] == "b", "b is active")
    "#).exec().unwrap();
}

#[test]
fn quest_reset_objective() {
    let lua = make_vm();
    lua.load(r#"
        local q = luna.quest.newQuest("retry_q")
        q:addObjective("task1", "do thing", 3)
        q:advanceObjective("task1", 3)
        local pct = q:completionPercent()
        assert(math.abs(pct - 100.0) < 0.01, "100% done")
        local ok = q:resetObjective("task1")
        assert(ok, "reset ok")
        local pct2 = q:completionPercent()
        assert(math.abs(pct2 - 0.0) < 0.01, "0% after reset")
    "#).exec().unwrap();
}

#[test]
fn questlog_status_filters() {
    let lua = make_vm();
    lua.load(r#"
        local ql = luna.quest.newQuestLog()
        local q1 = luna.quest.newQuest("hero_quest")
        local q2 = luna.quest.newQuest("side_quest")
        local q3 = luna.quest.newQuest("failed_quest")
        ql:addQuest(q1)
        ql:addQuest(q2)
        ql:addQuest(q3)
        ql:startQuest("hero_quest")
        ql:startQuest("side_quest")
        ql:startQuest("failed_quest")
        ql:completeQuest("hero_quest")
        ql:failQuest("failed_quest")
        local active = ql:getActiveQuestIds()
        local completed = ql:getCompletedQuestIds()
        local failed = ql:getFailedQuestIds()
        assert(#active == 1 and active[1] == "side_quest", "1 active quest")
        assert(#completed == 1 and completed[1] == "hero_quest", "1 completed")
        assert(#failed == 1 and failed[1] == "failed_quest", "1 failed")
    "#).exec().unwrap();
}

#[test]
fn questlog_empty_status_filters() {
    let lua = make_vm();
    lua.load(r#"
        local ql = luna.quest.newQuestLog()
        assert(#ql:getActiveQuestIds() == 0, "no active")
        assert(#ql:getCompletedQuestIds() == 0, "no completed")
        assert(#ql:getFailedQuestIds() == 0, "no failed")
    "#).exec().unwrap();
}
'''

tst = tst.rstrip() + "\n" + new_tests
with open(TEST, "w", encoding="utf-8") as f:
    f.write(tst)
print("quest_tests.rs updated")
print("Done - quest module expanded")
