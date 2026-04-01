"""Write the correct quest_api.rs with proper mlua patterns."""
import os

content = r"""//! Lua API bindings for `luna.quest.*`.
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

        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        methods.add_method("getDescription", |_, this, ()| Ok(this.0.borrow().description.clone()));
        methods.add_method("setDescription", |_, this, desc: String| {
            this.0.borrow_mut().description = desc;
            Ok(())
        });
        methods.add_method("getCurrent", |_, this, ()| Ok(this.0.borrow().current));
        methods.add_method("getRequired", |_, this, ()| Ok(this.0.borrow().required));
        methods.add_method("advance", |_, this, amount: u32| Ok(this.0.borrow_mut().advance(amount)));
        methods.add_method("setProgress", |_, this, value: u32| {
            this.0.borrow_mut().set_progress(value);
            Ok(())
        });
        methods.add_method("getStatus", |_, this, ()| {
            Ok(this.0.borrow().status.as_str().to_string())
        });
        methods.add_method("setStatus", |_, this, s: String| {
            let status = ObjectiveStatus::from_str(&s)
                .ok_or_else(|| LuaError::external(format!("invalid objective status: {}", s)))?;
            this.0.borrow_mut().status = status;
            Ok(())
        });
        methods.add_method("isMandatory", |_, this, ()| Ok(this.0.borrow().mandatory));
        methods.add_method("setMandatory", |_, this, v: bool| {
            this.0.borrow_mut().mandatory = v;
            Ok(())
        });
        methods.add_method("isVisible", |_, this, ()| Ok(this.0.borrow().visible));
        methods.add_method("setVisible", |_, this, v: bool| {
            this.0.borrow_mut().visible = v;
            Ok(())
        });
        methods.add_method("isComplete", |_, this, ()| Ok(this.0.borrow().is_complete()));
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().add_tag(tag);
            Ok(())
        });
        methods.add_method("hasTag", |_, this, tag: String| Ok(this.0.borrow().has_tag(&tag)));
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

        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("setName", |_, this, name: String| {
            this.0.borrow_mut().name = name;
            Ok(())
        });
        methods.add_method("addObjective", |_, this, obj: LuaAnyUserData| {
            let lua_obj = obj.borrow::<LuaObjective>()?;
            let cloned = lua_obj.0.borrow().clone();
            this.0.borrow_mut().add_objective(cloned);
            Ok(())
        });
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
        methods.add_method("isComplete", |_, this, ()| Ok(this.0.borrow().is_complete()));
        methods.add_method("getObjectiveCount", |_, this, ()| {
            Ok(this.0.borrow().objectives.len() as u32)
        });
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

        methods.add_method("getId", |_, this, ()| Ok(this.0.borrow().id.clone()));
        methods.add_method("getTitle", |_, this, ()| Ok(this.0.borrow().title.clone()));
        methods.add_method("setTitle", |_, this, t: String| {
            this.0.borrow_mut().title = t;
            Ok(())
        });
        methods.add_method("getDescription", |_, this, ()| Ok(this.0.borrow().description.clone()));
        methods.add_method("setDescription", |_, this, d: String| {
            this.0.borrow_mut().description = d;
            Ok(())
        });
        methods.add_method("getStatus", |_, this, ()| {
            Ok(this.0.borrow().status.as_str().to_string())
        });
        methods.add_method("setStatus", |_, this, s: String| {
            let status = QuestStatus::from_str(&s)
                .ok_or_else(|| LuaError::external(format!("invalid quest status: {}", s)))?;
            this.0.borrow_mut().status = status;
            Ok(())
        });
        methods.add_method("start", |_, this, ()| { this.0.borrow_mut().start(); Ok(()) });
        methods.add_method("complete", |_, this, ()| { this.0.borrow_mut().complete(); Ok(()) });
        methods.add_method("fail", |_, this, ()| { this.0.borrow_mut().fail(); Ok(()) });
        methods.add_method("addStage", |_, this, stage: LuaAnyUserData| {
            let lua_stage = stage.borrow::<LuaQuestStage>()?;
            let cloned = lua_stage.0.borrow().clone();
            this.0.borrow_mut().add_stage(cloned);
            Ok(())
        });
        methods.add_method("getCurrentStageIndex", |_, this, ()| {
            Ok(this.0.borrow().current_stage as u32 + 1)
        });
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
        methods.add_method("nextStage", |_, this, ()| Ok(this.0.borrow_mut().next_stage()));
        methods.add_method("gotoStage", |_, this, id: String| {
            Ok(this.0.borrow_mut().goto_stage(&id))
        });
        methods.add_method("getStageCount", |_, this, ()| {
            Ok(this.0.borrow().stages.len() as u32)
        });
        methods.add_method("getStageIds", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, s) in this.0.borrow().stages.iter().enumerate() {
                t.raw_set(i as i64 + 1, s.id.clone())?;
            }
            Ok(t)
        });
        methods.add_method("advanceObjective", |_, this, (id, amount): (String, u32)| {
            Ok(this.0.borrow_mut().advance_objective(&id, amount))
        });
        methods.add_method("setObjectiveStatus", |_, this, (id, s): (String, String)| {
            let status = ObjectiveStatus::from_str(&s)
                .ok_or_else(|| LuaError::external(format!("invalid objective status: {}", s)))?;
            Ok(this.0.borrow_mut().set_objective_status(&id, status))
        });
        methods.add_method("allObjectivesComplete", |_, this, ()| {
            Ok(this.0.borrow().all_objectives_complete())
        });
        methods.add_method("addJournalEntry", |_, this, (text, tag): (String, Option<String>)| {
            let tag = tag.unwrap_or_default();
            Ok(this.0.borrow_mut().add_journal_entry(text, tag))
        });
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
        methods.add_method("setMeta", |_, this, (key, value): (String, String)| {
            this.0.borrow_mut().set_meta(key, value);
            Ok(())
        });
        methods.add_method("getMeta", |_, this, key: String| {
            Ok(this.0.borrow().get_meta(&key).map(String::from))
        });
        methods.add_method("getReward", |_, this, ()| Ok(this.0.borrow().reward.clone()));
        methods.add_method("setReward", |_, this, r: String| {
            this.0.borrow_mut().reward = r;
            Ok(())
        });
        methods.add_method("isVisible", |_, this, ()| Ok(this.0.borrow().visible));
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

        methods.add_method("addQuest", |_, this, quest: LuaAnyUserData| {
            let lua_quest = quest.borrow::<LuaQuest>()?;
            let cloned = lua_quest.0.borrow().clone();
            this.0.borrow_mut().add_quest(cloned);
            Ok(())
        });
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
        methods.add_method("removeQuest", |_, this, id: String| {
            Ok(this.0.borrow_mut().remove_quest(&id))
        });
        methods.add_method("getQuestCount", |_, this, ()| {
            Ok(this.0.borrow().quest_count() as u32)
        });
        methods.add_method("getQuestIds", |lua, this, ()| {
            let t = lua.create_table()?;
            let borrow = this.0.borrow();
            for (i, id) in borrow.quest_ids().iter().enumerate() {
                t.raw_set(i as i64 + 1, id.clone())?;
            }
            Ok(t)
        });
        methods.add_method("startQuest", |_, this, id: String| {
            Ok(this.0.borrow_mut().start_quest(&id))
        });
        methods.add_method("completeQuest", |_, this, id: String| {
            Ok(this.0.borrow_mut().complete_quest(&id))
        });
        methods.add_method("failQuest", |_, this, id: String| {
            Ok(this.0.borrow_mut().fail_quest(&id))
        });
        methods.add_method("advanceObjective", |_, this, (quest_id, obj_id, amount): (String, String, u32)| {
            Ok(this.0.borrow_mut().advance_objective(&quest_id, &obj_id, amount))
        });
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

    luna.set("quest", module)?;
    Ok(())
}
"""

with open('src/lua_api/quest_api.rs', 'w', encoding='utf-8') as f:
    f.write(content)
print('quest_api.rs written successfully')
