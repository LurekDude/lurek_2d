//! Integration tests for the savegame module.

use lurek2d::savegame::{SaveManager, SaveValue};
use std::collections::HashMap;

// ─── Rust integration tests ───

#[test]
fn save_manager_register_duplicate_idempotent() {
    let mut sm = SaveManager::new();
    sm.register("player");
    sm.register("player");
    assert_eq!(sm.registered_names().len(), 1);
}

#[test]
fn auto_save_disable_stops_trigger() {
    let mut sm = SaveManager::new();
    sm.enable_auto_save(1.0, "slot");
    sm.mark_dirty();
    sm.disable_auto_save();
    assert!(sm.update(5.0).is_none());
}

#[test]
fn serialize_nested_table() {
    let mut inner = HashMap::new();
    inner.insert("hp".to_string(), SaveValue::Number(100.0));
    let mut outer = HashMap::new();
    outer.insert("player".to_string(), SaveValue::Table(inner));
    let s = lurek2d::savegame::serialize_table(&outer, 0).unwrap();
    assert!(s.contains("player ="));
    assert!(s.contains("hp = 100"));
}

#[test]
fn serialize_special_string_key() {
    let mut data = HashMap::new();
    data.insert("with space".to_string(), SaveValue::Bool(true));
    let s = lurek2d::savegame::serialize_table(&data, 0).unwrap();
    assert!(s.contains("[\"with space\"]"));
}

#[test]
fn serialize_nil_value() {
    let s = lurek2d::savegame::serialize_value(&SaveValue::Nil, 0).unwrap();
    assert_eq!(s, "nil");
}

// ─── Lua integration tests ───

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use lurek2d::runtime::config::Config;
use lurek2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone(), &Config::default().modules).unwrap();
    (state, lua)
}

#[test]
fn test_lua_new_save_manager() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        assert(sm:getSchemaVersion() == 0)
        assert(sm:isDirty() == false)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_register_collect() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        local player_hp = 100
        sm:register("player",
            function() return { hp = player_hp } end,
            function(data) player_hp = data.hp end
        )
        local data = sm:collect()
        assert(data.player.hp == 100)
        assert(data.__schema_version == 0)
        assert(type(data.__timestamp) == "number")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_collect_restore_roundtrip() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        local score = 42
        sm:register("game",
            function() return { score = score } end,
            function(data) score = data.score end
        )
        local data = sm:collect()
        score = 0
        sm:restore(data)
        assert(score == 42)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_dirty_tracking() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        assert(sm:isDirty() == false)
        sm:markDirty()
        assert(sm:isDirty() == true)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_schema_version() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        sm:setSchemaVersion(5)
        assert(sm:getSchemaVersion() == 5)
        local data = sm:collect()
        assert(data.__schema_version == 5)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_migration() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        sm:setSchemaVersion(3)
        local migrated = false
        sm:addMigration(1, function(data)
            migrated = true
            data.upgraded = true
            return data
        end)

        -- Simulate loading data from schema version 1
        local old_data = { __schema_version = 1 }
        sm:restore(old_data)
        assert(migrated == true)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_auto_save_update() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        sm:enableAutoSave(2.0, "quicksave")
        sm:markDirty()
        local slot = sm:update(1.0)
        assert(slot == nil) -- not enough time
        slot = sm:update(1.5)
        assert(slot == "quicksave") -- triggered
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_summary() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        sm:setSummary("Level 3, 100 coins")
        assert(sm:getSummary() == "Level 3, 100 coins")
        local data = sm:collect()
        assert(data.__summary == "Level 3, 100 coins")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_reset() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        sm:register("mod1", function() return {} end, function(d) end)
        sm:setSchemaVersion(5)
        sm:markDirty()
        sm:reset()
        assert(sm:getSchemaVersion() == 0)
        assert(sm:isDirty() == false)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_unregister() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = lurek.savegame.newSaveManager()
        sm:register("mod1", function() return { x = 1 } end, function(d) end)
        sm:unregister("mod1")
        local data = sm:collect()
        assert(data.mod1 == nil)
    "#,
    )
    .exec()
    .unwrap();
}
