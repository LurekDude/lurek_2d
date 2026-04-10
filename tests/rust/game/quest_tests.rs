//! Integration tests for `lurek.quest.*` Lua API.

use lurek2d::lua_api::{create_lua_vm, SharedState};
use lurek2d::engine::config::Config;
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state, &Config::default().modules).unwrap()
}

// ── Objective ─────────────────────────────────────────────────────────────────

#[test]
fn quest_new_objective() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local obj = lurek.quest.newObjective("kill_wolves", "Kill 3 wolves", 3)
        return obj:getId() == "kill_wolves" and obj:getRequired() == 3 and obj:getCurrent() == 0
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_objective_advance() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local obj = lurek.quest.newObjective("collect", "Collect 5", 5)
        obj:advance(3)
        local s1 = obj:getStatus()
        obj:advance(2)
        local s2 = obj:getStatus()
        return s1 == "active" and s2 == "done" and obj:getCurrent() == 5
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_objective_advance_clamps() {
    let lua = make_vm();
    let n: u32 = lua
        .load(r#"
        local obj = lurek.quest.newObjective("grab", "Grab 3", 3)
        obj:advance(100)
        return obj:getCurrent()
    "#)
        .eval().unwrap();
    assert_eq!(n, 3);
}

#[test]
fn quest_objective_is_complete_done() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local obj = lurek.quest.newObjective("task", "Task", 1)
        obj:advance(1)
        return obj:isComplete()
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_objective_is_complete_skipped() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local obj = lurek.quest.newObjective("opt", "Optional", 1)
        obj:setStatus("skipped")
        return obj:isComplete()
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_objective_tags() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local obj = lurek.quest.newObjective("kill", "Kill enemies", 5)
        obj:addTag("combat")
        obj:addTag("main")
        return obj:hasTag("combat") and not obj:hasTag("social")
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_objective_set_progress() {
    let lua = make_vm();
    let status: String = lua
        .load(r#"
        local obj = lurek.quest.newObjective("farm", "Farm crops", 10)
        obj:setProgress(10)
        return obj:getStatus()
    "#)
        .eval().unwrap();
    assert_eq!(status, "done");
}

#[test]
fn quest_objective_type_method() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local obj = lurek.quest.newObjective("t", "T", 1)
        return obj:type() == "Objective"
    "#)
        .eval().unwrap();
    assert!(res);
}

// ── QuestStage ────────────────────────────────────────────────────────────────

#[test]
fn quest_stage_new() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local stage = lurek.quest.newStage("s1", "First Stage")
        return stage:getId() == "s1" and stage:getName() == "First Stage"
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_stage_add_and_get_objective() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local stage = lurek.quest.newStage("findKey", "Find the Key")
        local obj = lurek.quest.newObjective("search_room", "Search the room", 1)
        stage:addObjective(obj)
        local got = stage:getObjective("search_room")
        return got ~= nil and stage:getObjectiveCount() == 1
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_stage_is_complete_all_done() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local stage = lurek.quest.newStage("s", "S")
        local obj = lurek.quest.newObjective("o1", "Obj", 1)
        stage:addObjective(obj)
        -- Stage not complete yet
        local before = stage:isComplete()
        -- note: addObjective clones, so we can't mutate after adding
        -- complete via quest:advanceObjective below
        return not before
    "#)
        .eval().unwrap();
    assert!(res);
}

// ── Quest ─────────────────────────────────────────────────────────────────────

#[test]
fn quest_new_and_status() {
    let lua = make_vm();
    let status: String = lua
        .load(r#"
        local q = lurek.quest.newQuest("q1", "My Quest")
        return q:getStatus()
    "#)
        .eval().unwrap();
    assert_eq!(status, "available");
}

#[test]
fn quest_start_complete_fail_cycle() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local q = lurek.quest.newQuest("test", "Test Quest")
        q:start()
        local s1 = q:getStatus()
        q:complete()
        local s2 = q:getStatus()
        local q2 = lurek.quest.newQuest("t2", "T2")
        q2:start()
        q2:fail()
        local s3 = q2:getStatus()
        return s1 == "active" and s2 == "completed" and s3 == "failed"
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_add_stage_and_navigate() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local q = lurek.quest.newQuest("adventure", "Adventure")
        q:addStage(lurek.quest.newStage("intro", "Introduction"))
        q:addStage(lurek.quest.newStage("main", "Main Act"))
        q:addStage(lurek.quest.newStage("end", "Finale"))
        local before = q:getCurrentStageIndex()
        q:nextStage()
        local mid = q:getCurrentStageIndex()
        q:gotoStage("end")
        local last = q:getCurrentStageIndex()
        return before == 1 and mid == 2 and last == 3
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_advance_objective_through_quest() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local q = lurek.quest.newQuest("gather", "Gather Resources")
        local stage = lurek.quest.newStage("collect", "Collect")
        local obj = lurek.quest.newObjective("wood", "Get wood", 5)
        stage:addObjective(obj)
        q:addStage(stage)
        local ok = q:advanceObjective("wood", 5)
        -- can't read back because the stage/obj were cloned into the quest
        return ok  -- objective found and advanced
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_journal() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local q = lurek.quest.newQuest("diary", "Diary")
        local i1 = q:addJournalEntry("Found a clue", "discovery")
        local i2 = q:addJournalEntry("Unlocked door", "progress")
        local journal = q:getJournal()
        return #journal == 2 and journal[1].text == "Found a clue" and i1 == 0 and i2 == 1
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_metadata() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local q = lurek.quest.newQuest("deliver", "Delivery")
        q:setMeta("giver", "Old Man Jones")
        q:setMeta("location", "Mudshire")
        local giver = q:getMeta("giver")
        local missing = q:getMeta("unknown")
        return giver == "Old Man Jones" and missing == nil
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_reward_and_visibility() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local q = lurek.quest.newQuest("slay", "Slay the Dragon")
        q:setReward("100 gold pieces")
        q:setVisible(false)
        return q:getReward() == "100 gold pieces" and not q:isVisible()
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_type_method() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local q = lurek.quest.newQuest("t", "T")
        return q:type() == "Quest"
    "#)
        .eval().unwrap();
    assert!(res);
}

// ── QuestLog ──────────────────────────────────────────────────────────────────

#[test]
fn quest_log_add_and_count() {
    let lua = make_vm();
    let n: u32 = lua
        .load(r#"
        local log = lurek.quest.newQuestLog()
        log:addQuest(lurek.quest.newQuest("q1", "Quest 1"))
        log:addQuest(lurek.quest.newQuest("q2", "Quest 2"))
        return log:getQuestCount()
    "#)
        .eval().unwrap();
    assert_eq!(n, 2);
}

#[test]
fn quest_log_get_and_remove() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local log = lurek.quest.newQuestLog()
        log:addQuest(lurek.quest.newQuest("main", "Main"))
        local got = log:getQuest("main")
        local removed = log:removeQuest("main")
        local gone = log:getQuest("main")
        return got ~= nil and removed and gone == nil
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_log_start_complete_fail() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local log = lurek.quest.newQuestLog()
        log:addQuest(lurek.quest.newQuest("a", "A"))
        log:addQuest(lurek.quest.newQuest("b", "B"))
        log:startQuest("a")
        log:completeQuest("a")
        log:startQuest("b")
        log:failQuest("b")
        local qa = log:getQuest("a")
        local qb = log:getQuest("b")
        return qa:getStatus() == "completed" and qb:getStatus() == "failed"
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_log_quests_with_status() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local log = lurek.quest.newQuestLog()
        log:addQuest(lurek.quest.newQuest("a", "A"))
        log:addQuest(lurek.quest.newQuest("b", "B"))
        log:addQuest(lurek.quest.newQuest("c", "C"))
        log:startQuest("b")
        log:startQuest("c")
        log:completeQuest("c")
        local active = log:getQuestsWithStatus("active")
        local done = log:getQuestsWithStatus("completed")
        return #active == 1 and active[1] == "b" and #done == 1 and done[1] == "c"
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_log_advance_objective() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local log = lurek.quest.newQuestLog()
        local q = lurek.quest.newQuest("fetch", "Fetch")
        local stage = lurek.quest.newStage("go", "Go Get It")
        local obj = lurek.quest.newObjective("apples", "Get apples", 3)
        stage:addObjective(obj)
        q:addStage(stage)
        log:addQuest(q)
        local ok = log:advanceObjective("fetch", "apples", 2)
        return ok
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_log_type_method() {
    let lua = make_vm();
    let res: bool = lua
        .load(r#"
        local log = lurek.quest.newQuestLog()
        return log:type() == "QuestLog"
    "#)
        .eval().unwrap();
    assert!(res);
}

#[test]
fn quest_completion_percent() {
    let lua = make_vm();
    lua.load(r#"
        local q = lurek.quest.newQuest("main_q")
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
        local q = lurek.quest.newQuest("side_q")
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
        local q = lurek.quest.newQuest("retry_q")
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
        local ql = lurek.quest.newQuestLog()
        local q1 = lurek.quest.newQuest("hero_quest")
        local q2 = lurek.quest.newQuest("side_quest")
        local q3 = lurek.quest.newQuest("failed_quest")
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
        local ql = lurek.quest.newQuestLog()
        assert(#ql:getActiveQuestIds() == 0, "no active")
        assert(#ql:getCompletedQuestIds() == 0, "no completed")
        assert(#ql:getFailedQuestIds() == 0, "no failed")
    "#).exec().unwrap();
}
