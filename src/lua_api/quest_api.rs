//! Lua API bindings for `luna.quest.*`.
//!
//! Exposes quest creation, stage management, objective tracking, and journal
//! entries through the `luna.quest` table.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::quest::{Objective, ObjectiveStatus, Quest, QuestLog, QuestStage, QuestStatus};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ─────────────────────────────────────────────────────────────────────────────
// LuaObjective
// ─────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a quest objective.
#[derive(Clone)]
pub(crate) struct LuaObjective(pub(crate) Rc<RefCell<Objective>>);

impl LunaType for LuaObjective {
    const TYPE_NAME: &'static str = "Objective";
    const TYPE_HIERARCHY: &'static [&'static str] = &[];
}

impl LuaUserData for LuaObjective {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the id.
        ///
        /// # Parameters
        /// - `desc` — `string`.
        ///
        /// # Returns
        /// The current id.
        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        /// Returns the description.
        ///
        /// # Parameters
        /// - `desc` — `string`.
        ///
        /// # Returns
        /// The current description.
        methods.add_method("getDescription", |_, this, ()| Ok(this.0.borrow().description.clone()));
        /// Sets the description.
        ///
        /// # Parameters
        /// - `desc` — `string`.
        methods.add_method("setDescription", |_, this, desc: String| {
            this.0.borrow_mut().description = desc;
            Ok(())
        });
        /// Returns the current.
        ///
        /// # Parameters
        /// - `amount` — `integer`.
        ///
        /// # Returns
        /// The current current.
        methods.add_method("getCurrent", |_, this, ()| Ok(this.0.borrow().current));
        /// Returns the required.
        ///
        /// # Parameters
        /// - `amount` — `integer`.
        ///
        /// # Returns
        /// The current required.
        methods.add_method("getRequired", |_, this, ()| Ok(this.0.borrow().required));
        /// Advances to the next item.
        ///
        /// # Parameters
        /// - `amount` — `integer`.
        methods.add_method("advance", |_, this, amount: u32| Ok(this.0.borrow_mut().advance(amount)));
        /// Sets the progress.
        ///
        /// # Parameters
        /// - `value` — `integer`.
        methods.add_method("setProgress", |_, this, value: u32| {
            this.0.borrow_mut().set_progress(value);
            Ok(())
        });
        /// Returns the status.
        ///
        /// # Parameters
        /// - `s` — `string`.
        ///
        /// # Returns
        /// The current status.
        methods.add_method("getStatus", |_, this, ()| {
            Ok(this.0.borrow().status.as_str().to_string())
        });
        /// Sets the status.
        ///
        /// # Parameters
        /// - `s` — `string`.
        methods.add_method("setStatus", |_, this, s: String| {
            let status = ObjectiveStatus::from_str(&s)
                .ok_or_else(|| LuaError::external(format!("invalid objective status: {}", s)))?;
            this.0.borrow_mut().status = status;
            Ok(())
        });
        /// Returns `true` if mandatory.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isMandatory", |_, this, ()| Ok(this.0.borrow().mandatory));
        /// Sets the mandatory.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        methods.add_method("setMandatory", |_, this, v: bool| {
            this.0.borrow_mut().mandatory = v;
            Ok(())
        });
        /// Returns `true` if visible.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isVisible", |_, this, ()| Ok(this.0.borrow().visible));
        /// Sets the visible.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        methods.add_method("setVisible", |_, this, v: bool| {
            this.0.borrow_mut().visible = v;
            Ok(())
        });
        /// Returns `true` if complete.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isComplete", |_, this, ()| Ok(this.0.borrow().is_complete()));
        /// Adds tag to the collection.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().add_tag(tag);
            Ok(())
        });
        /// Returns `true` if tag.
        ///
        /// # Parameters
        /// - `tag` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, tag: String| Ok(this.0.borrow().has_tag(&tag)));
        /// Returns the tags.
        ///
        /// # Returns
        /// The current tags.
        methods.add_method("getTags", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, tag) in this.0.borrow().tags.iter().enumerate() {
                t.raw_set(i as i64 + 1, tag.clone())?;
            }
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaQuestStage
// ─────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a quest stage.
#[derive(Clone)]
pub(crate) struct LuaQuestStage(pub(crate) Rc<RefCell<QuestStage>>);

impl LunaType for LuaQuestStage {
    const TYPE_NAME: &'static str = "QuestStage";
    const TYPE_HIERARCHY: &'static [&'static str] = &[];
}

impl LuaUserData for LuaQuestStage {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the id.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current id.
        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        /// Returns the name.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Sets the name.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("setName", |_, this, name: String| {
            this.0.borrow_mut().name = name;
            Ok(())
        });
        /// Adds objective to the collection.
        ///
        /// # Parameters
        /// - `obj` — `userdata`.
        methods.add_method("addObjective", |_, this, obj: LuaAnyUserData| {
            let lua_obj = obj.borrow::<LuaObjective>()?;
            let cloned = lua_obj.0.borrow().clone();
            this.0.borrow_mut().add_objective(cloned);
            Ok(())
        });
        /// Returns the objective.
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// The current objective.
        methods.add_method("getObjective", |_, this, id: String| {
            let borrow = this.0.borrow();
            if let Some(obj) = borrow.get_objective(&id) {
                let cloned = obj.clone();
                drop(borrow);
                Ok(Some(LuaObjective(Rc::new(RefCell::new(cloned)))))
            } else {
                Ok(None)
            }
        });
        /// Returns `true` if complete.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isComplete", |_, this, ()| Ok(this.0.borrow().is_complete()));
        /// Returns the objective count.
        ///
        /// # Returns
        /// The current objective count.
        methods.add_method("getObjectiveCount", |_, this, ()| {
            Ok(this.0.borrow().objectives.len() as u32)
        });
        /// Returns the objective ids.
        ///
        /// # Returns
        /// The current objective ids.
        methods.add_method("getObjectiveIds", |lua, this, ()| {
            let t = lua.create_table()?;
            let borrow = this.0.borrow();
            for (i, obj) in borrow.objectives.iter().enumerate() {
                t.raw_set(i as i64 + 1, obj.id.clone())?;
            }
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaQuest
// ─────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a quest.
#[derive(Clone)]
pub(crate) struct LuaQuest(pub(crate) Rc<RefCell<Quest>>);

impl LunaType for LuaQuest {
    const TYPE_NAME: &'static str = "Quest";
    const TYPE_HIERARCHY: &'static [&'static str] = &[];
}

impl LuaUserData for LuaQuest {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the id.
        ///
        /// # Parameters
        /// - `t` — `string`.
        ///
        /// # Returns
        /// The current id.
        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        /// Returns the title.
        ///
        /// # Parameters
        /// - `t` — `string`.
        ///
        /// # Returns
        /// The current title.
        methods.add_method("getTitle", |_, this, ()| Ok(this.0.borrow().title.clone()));
        /// Sets the title.
        ///
        /// # Parameters
        /// - `t` — `string`.
        methods.add_method("setTitle", |_, this, t: String| {
            this.0.borrow_mut().title = t;
            Ok(())
        });
        /// Returns the description.
        ///
        /// # Parameters
        /// - `d` — `string`.
        ///
        /// # Returns
        /// The current description.
        methods.add_method("getDescription", |_, this, ()| Ok(this.0.borrow().description.clone()));
        /// Sets the description.
        ///
        /// # Parameters
        /// - `d` — `string`.
        methods.add_method("setDescription", |_, this, d: String| {
            this.0.borrow_mut().description = d;
            Ok(())
        });
        /// Returns the status.
        ///
        /// # Parameters
        /// - `s` — `string`.
        ///
        /// # Returns
        /// The current status.
        methods.add_method("getStatus", |_, this, ()| {
            Ok(this.0.borrow().status.as_str().to_string())
        });
        /// Sets the status.
        ///
        /// # Parameters
        /// - `s` — `string`.
        methods.add_method("setStatus", |_, this, s: String| {
            let status = QuestStatus::from_str(&s)
                .ok_or_else(|| LuaError::external(format!("invalid quest status: {}", s)))?;
            this.0.borrow_mut().status = status;
            Ok(())
        });
        /// Begins execution.
        ///
        /// # Parameters
        /// - `stage` — `userdata`.
        methods.add_method("start", |_, this, ()| { this.0.borrow_mut().start(); Ok(()) });
        /// Marks the current task as complete.
        ///
        /// # Parameters
        /// - `stage` — `userdata`.
        methods.add_method("complete", |_, this, ()| { this.0.borrow_mut().complete(); Ok(()) });
        /// Marks the current task as failed.
        ///
        /// # Parameters
        /// - `stage` — `userdata`.
        methods.add_method("fail", |_, this, ()| { this.0.borrow_mut().fail(); Ok(()) });
        /// Adds stage to the collection.
        ///
        /// # Parameters
        /// - `stage` — `userdata`.
        methods.add_method("addStage", |_, this, stage: LuaAnyUserData| {
            let lua_stage = stage.borrow::<LuaQuestStage>()?;
            let cloned = lua_stage.0.borrow().clone();
            this.0.borrow_mut().add_stage(cloned);
            Ok(())
        });
        /// Returns the current stage index.
        ///
        /// # Returns
        /// The current current stage index.
        methods.add_method("getCurrentStageIndex", |_, this, ()| {
            Ok(this.0.borrow().current_stage as u32 + 1)
        });
        /// Returns the current stage.
        ///
        /// # Returns
        /// The current current stage.
        methods.add_method("getCurrentStage", |_, this, ()| {
            let borrow = this.0.borrow();
            if let Some(s) = borrow.get_current_stage() {
                let cloned = s.clone();
                drop(borrow);
                Ok(Some(LuaQuestStage(Rc::new(RefCell::new(cloned)))))
            } else {
                Ok(None)
            }
        });
        /// Returns the stage.
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// The current stage.
        methods.add_method("getStage", |_, this, id: String| {
            let borrow = this.0.borrow();
            if let Some(s) = borrow.get_stage(&id) {
                let cloned = s.clone();
                drop(borrow);
                Ok(Some(LuaQuestStage(Rc::new(RefCell::new(cloned)))))
            } else {
                Ok(None)
            }
        });
        /// Next stage on this Quest.
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("nextStage", |_, this, ()| Ok(this.0.borrow_mut().next_stage()));
        /// Goto stage on this Quest.
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("gotoStage", |_, this, id: String| {
            Ok(this.0.borrow_mut().goto_stage(&id))
        });
        /// Returns the stage count.
        ///
        /// # Returns
        /// The current stage count.
        methods.add_method("getStageCount", |_, this, ()| {
            Ok(this.0.borrow().stages.len() as u32)
        });
        /// Returns the stage ids.
        ///
        /// # Parameters
        /// - `id` — `string`.
        /// - `amount` — `integer`.
        ///
        /// # Returns
        /// The current stage ids.
        methods.add_method("getStageIds", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, s) in this.0.borrow().stages.iter().enumerate() {
                t.raw_set(i as i64 + 1, s.id.clone())?;
            }
            Ok(t)
        });
        /// Advance objective on this Quest.
        ///
        /// # Parameters
        /// - `id` — `string`.
        /// - `amount` — `integer`.
        methods.add_method("advanceObjective", |_, this, (id, amount): (String, u32)| {
            Ok(this.0.borrow_mut().advance_objective(&id, amount))
        });
        /// Sets the objective status.
        ///
        /// # Parameters
        /// - `id` — `string`.
        /// - `s` — `string`.
        methods.add_method("setObjectiveStatus", |_, this, (id, s): (String, String)| {
            let status = ObjectiveStatus::from_str(&s)
                .ok_or_else(|| LuaError::external(format!("invalid objective status: {}", s)))?;
            Ok(this.0.borrow_mut().set_objective_status(&id, status))
        });
        /// All objectives complete on this Quest.
        ///
        /// # Parameters
        /// - `text` — `string`.
        /// - `tag` — `string` optional.
        methods.add_method("allObjectivesComplete", |_, this, ()| {
            Ok(this.0.borrow().all_objectives_complete())
        });
        /// Adds journal entry to the collection.
        ///
        /// # Parameters
        /// - `text` — `string`.
        /// - `tag` — `string` optional.
        methods.add_method("addJournalEntry", |_, this, (text, tag): (String, Option<String>)| {
            let tag = tag.unwrap_or_default();
            Ok(this.0.borrow_mut().add_journal_entry(text, tag))
        });
        /// Returns the journal.
        ///
        /// # Returns
        /// The current journal.
        methods.add_method("getJournal", |lua, this, ()| {
            let t = lua.create_table()?;
            let borrow = this.0.borrow();
            for (i, entry) in borrow.journal.iter().enumerate() {
                let e = lua.create_table()?;
                e.raw_set("index", entry.index)?;
                e.raw_set("text", entry.text.clone())?;
                e.raw_set("tag", entry.tag.clone())?;
                t.raw_set(i as i64 + 1, e)?;
            }
            Ok(t)
        });
        /// Sets the meta.
        ///
        /// # Parameters
        /// - `key` — `string`.
        /// - `value` — `string`.
        methods.add_method("setMeta", |_, this, (key, value): (String, String)| {
            this.0.borrow_mut().set_meta(key, value);
            Ok(())
        });
        /// Returns the meta.
        ///
        /// # Parameters
        /// - `key` — `string`.
        ///
        /// # Returns
        /// The current meta.
        methods.add_method("getMeta", |_, this, key: String| {
            Ok(this.0.borrow().get_meta(&key).map(String::from))
        });
        /// Returns the reward.
        ///
        /// # Parameters
        /// - `r` — `string`.
        ///
        /// # Returns
        /// The current reward.
        methods.add_method("getReward", |_, this, ()| Ok(this.0.borrow().reward.clone()));
        /// Sets the reward.
        ///
        /// # Parameters
        /// - `r` — `string`.
        methods.add_method("setReward", |_, this, r: String| {
            this.0.borrow_mut().reward = r;
            Ok(())
        });
        /// Returns `true` if visible.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isVisible", |_, this, ()| Ok(this.0.borrow().visible));
        /// Sets the visible.
        ///
        /// # Parameters
        /// - `v` — `boolean`.
        methods.add_method("setVisible", |_, this, v: bool| {
            this.0.borrow_mut().visible = v;
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaQuestLog
// ─────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a quest log.
#[derive(Clone)]
pub(crate) struct LuaQuestLog(pub(crate) Rc<RefCell<QuestLog>>);

impl LunaType for LuaQuestLog {
    const TYPE_NAME: &'static str = "QuestLog";
    const TYPE_HIERARCHY: &'static [&'static str] = &[];
}

impl LuaUserData for LuaQuestLog {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Adds quest to the collection.
        ///
        /// # Parameters
        /// - `quest` — `userdata`.
        methods.add_method("addQuest", |_, this, quest: LuaAnyUserData| {
            let lua_quest = quest.borrow::<LuaQuest>()?;
            let cloned = lua_quest.0.borrow().clone();
            this.0.borrow_mut().add_quest(cloned);
            Ok(())
        });
        /// Returns the quest.
        ///
        /// # Parameters
        /// - `id` — `string`.
        ///
        /// # Returns
        /// The current quest.
        methods.add_method("getQuest", |_, this, id: String| {
            let borrow = this.0.borrow();
            if let Some(q) = borrow.get_quest(&id) {
                let cloned = q.clone();
                drop(borrow);
                Ok(Some(LuaQuest(Rc::new(RefCell::new(cloned)))))
            } else {
                Ok(None)
            }
        });
        /// Removes quest from the collection.
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("removeQuest", |_, this, id: String| {
            Ok(this.0.borrow_mut().remove_quest(&id))
        });
        /// Returns the quest count.
        ///
        /// # Returns
        /// The current quest count.
        methods.add_method("getQuestCount", |_, this, ()| {
            Ok(this.0.borrow().quest_count() as u32)
        });
        /// Returns the quest ids.
        ///
        /// # Returns
        /// The current quest ids.
        methods.add_method("getQuestIds", |lua, this, ()| {
            let t = lua.create_table()?;
            let borrow = this.0.borrow();
            for (i, id) in borrow.quest_ids().iter().enumerate() {
                t.raw_set(i as i64 + 1, id.clone())?;
            }
            Ok(t)
        });
        /// Start quest on this QuestLog.
        ///
        /// # Parameters
        /// - `id` — `string`.
        methods.add_method("startQuest", |_, this, id: String| {
            Ok(this.0.borrow_mut().start_quest(&id))
        });
        /// Complete quest on this QuestLog.
        ///
        /// # Parameters
        /// - `quest_id` — `string`.
        /// - `obj_id` — `string`.
        /// - `amount` — `integer`.
        methods.add_method("completeQuest", |_, this, id: String| {
            Ok(this.0.borrow_mut().complete_quest(&id))
        });
        /// Fail quest on this QuestLog.
        ///
        /// # Parameters
        /// - `quest_id` — `string`.
        /// - `obj_id` — `string`.
        /// - `amount` — `integer`.
        methods.add_method("failQuest", |_, this, id: String| {
            Ok(this.0.borrow_mut().fail_quest(&id))
        });
        /// Advance objective on this QuestLog.
        ///
        /// # Parameters
        /// - `quest_id` — `string`.
        /// - `obj_id` — `string`.
        /// - `amount` — `integer`.
        methods.add_method("advanceObjective", |_, this, (quest_id, obj_id, amount): (String, String, u32)| {
            Ok(this.0.borrow_mut().advance_objective(&quest_id, &obj_id, amount))
        });
        /// Returns the active quest ids.
        ///
        /// # Returns
        /// The current active quest ids.
        methods.add_method("getActiveQuestIds", |lua, this, ()| {
            let ids = this.0.borrow().active_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        /// Returns the completed quest ids.
        ///
        /// # Returns
        /// The current completed quest ids.
        methods.add_method("getCompletedQuestIds", |lua, this, ()| {
            let ids = this.0.borrow().completed_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        /// Returns the failed quest ids.
        ///
        /// # Parameters
        /// - `status` — `string`.
        ///
        /// # Returns
        /// The current failed quest ids.
        methods.add_method("getFailedQuestIds", |lua, this, ()| {
            let ids = this.0.borrow().failed_ids();
            let t = lua.create_table()?;
            for (i, id) in ids.into_iter().enumerate() { t.set(i + 1, id)?; }
            Ok(t)
        });
        /// Returns the quests with status.
        ///
        /// # Parameters
        /// - `status` — `string`.
        ///
        /// # Returns
        /// The current quests with status.
        methods.add_method("getQuestsWithStatus", |lua, this, status: String| {
            let st = QuestStatus::from_str(&status)
                .ok_or_else(|| LuaError::external(format!("invalid quest status: {}", status)))?;
            let borrow = this.0.borrow();
            let ids = borrow.quests_with_status(&st);
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.raw_set(i as i64 + 1, id.to_string())?;
            }
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register
// ─────────────────────────────────────────────────────────────────────────────

/// Register `luna.quest.*` API with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    module.set(
        "newObjective",
        lua.create_function(|_, (id, desc, required): (String, String, u32)| {
            Ok(LuaObjective(Rc::new(RefCell::new(Objective::new(id, desc, required)))))
        })?,
    )?;

    module.set(
        "newStage",
        lua.create_function(|_, (id, name): (String, String)| {
            Ok(LuaQuestStage(Rc::new(RefCell::new(QuestStage::new(id, name)))))
        })?,
    )?;

    module.set(
        "newQuest",
        lua.create_function(|_, (id, title): (String, String)| {
            Ok(LuaQuest(Rc::new(RefCell::new(Quest::new(id, title)))))
        })?,
    )?;

    module.set(
        "newQuestLog",
        lua.create_function(|_, ()| {
            Ok(LuaQuestLog(Rc::new(RefCell::new(QuestLog::new()))))
        })?,
    )?;

    /// Quest on this QuestLog.
    ///
    /// # Returns
    /// The result.
    luna.set("quest", module)?;
    Ok(())
}
