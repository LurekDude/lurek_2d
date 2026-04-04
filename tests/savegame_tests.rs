//! Integration tests for the savegame module.

use luna2d::savegame::{SaveManager, SaveValue};
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
    let s = luna2d::savegame::serialize_table(&outer, 0).unwrap();
    assert!(s.contains("player ="));
    assert!(s.contains("hp = 100"));
}

#[test]
fn serialize_special_string_key() {
    let mut data = HashMap::new();
    data.insert("with space".to_string(), SaveValue::Bool(true));
    let s = luna2d::savegame::serialize_table(&data, 0).unwrap();
    assert!(s.contains("[\"with space\"]"));
}

#[test]
fn serialize_nil_value() {
    let s = luna2d::savegame::serialize_value(&SaveValue::Nil, 0).unwrap();
    assert_eq!(s, "nil");
}

// ─── Lua integration tests ───

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone()).unwrap();
    (state, lua)
}

/// Create a VM with a temp directory as game_dir for slot file I/O tests.
fn make_vm_with_tmpdir() -> (Rc<RefCell<SharedState>>, mlua::Lua, tempfile::TempDir) {
    let tmp = tempfile::tempdir().expect("Failed to create temp dir");
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "test",
        tmp.path().to_path_buf(),
    )));
    let lua = create_lua_vm(state.clone()).unwrap();
    (state, lua, tmp)
}

#[test]
fn test_lua_new_save_manager() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
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
        local sm = luna.savegame.newSaveManager()
        sm:register("mod1", function() return { x = 1 } end, function(d) end)
        sm:unregister("mod1")
        local data = sm:collect()
        assert(data.mod1 == nil)
    "#,
    )
    .exec()
    .unwrap();
}

// ─── Slot File I/O tests ───

#[test]
fn test_lua_save_and_load_slot() {
    let (_state, lua, _tmp) = make_vm_with_tmpdir();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
        local score = 42
        sm:register("game",
            function() return { score = score } end,
            function(data) score = data.score end
        )
        sm:setSummary("Level 1")
        sm:save("test1")
        score = 0
        local ok, err = sm:load("test1")
        assert(ok == true, "load should succeed: " .. tostring(err))
        assert(score == 42, "restored score should be 42")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_slot_exists() {
    let (_state, lua, _tmp) = make_vm_with_tmpdir();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
        sm:register("data", function() return { x = 1 } end, function(d) end)
        assert(sm:exists("slot_a") == false)
        sm:save("slot_a")
        assert(sm:exists("slot_a") == true)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_slot_delete() {
    let (_state, lua, _tmp) = make_vm_with_tmpdir();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
        sm:register("data", function() return { x = 1 } end, function(d) end)
        sm:save("del_me")
        assert(sm:exists("del_me") == true)
        sm:delete("del_me")
        assert(sm:exists("del_me") == false)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_slot_load_missing_returns_false() {
    let (_state, lua, _tmp) = make_vm_with_tmpdir();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
        local ok, err = sm:load("nonexistent")
        assert(ok == false, "loading missing slot should return false")
        assert(type(err) == "string", "should return error message")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_get_slots() {
    let (_state, lua, _tmp) = make_vm_with_tmpdir();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
        sm:register("data", function() return { n = 1 } end, function(d) end)
        sm:setSummary("first")
        sm:save("alpha")
        sm:setSummary("second")
        sm:save("beta")
        local slots = sm:getSlots()
        assert(#slots == 2, "should have 2 slots, got " .. #slots)
        -- Slots should have metadata
        local found = {}
        for _, s in ipairs(slots) do
            found[s.slot] = s
        end
        assert(found["alpha"] ~= nil)
        assert(found["beta"] ~= nil)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_get_slot_info() {
    let (_state, lua, _tmp) = make_vm_with_tmpdir();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
        sm:setSchemaVersion(3)
        sm:register("data", function() return { y = 9 } end, function(d) end)
        sm:setSummary("My Save")
        sm:save("info_test")
        local info = sm:getSlotInfo("info_test")
        assert(info ~= nil, "slot info should be returned")
        assert(info.slot == "info_test")
        assert(info.version == 3)
        assert(info.summary == "My Save")
        assert(type(info.timestamp) == "number")
        -- Missing slot returns nil
        local missing = sm:getSlotInfo("nope")
        assert(missing == nil)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_save_clears_dirty() {
    let (_state, lua, _tmp) = make_vm_with_tmpdir();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
        sm:register("data", function() return {} end, function(d) end)
        sm:markDirty()
        assert(sm:isDirty() == true)
        sm:save("clean")
        assert(sm:isDirty() == false)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_save_load_with_migration() {
    let (_state, lua, _tmp) = make_vm_with_tmpdir();
    lua.load(
        r#"
        local sm = luna.savegame.newSaveManager()
        local val = 10
        sm:setSchemaVersion(1)
        sm:register("data",
            function() return { value = val } end,
            function(d) val = d.value end
        )
        sm:save("migr")
        -- Upgrade schema and add migration
        sm:setSchemaVersion(2)
        sm:addMigration(1, function(d)
            d.data.value = d.data.value * 2
            d.__schema_version = 2
            return d
        end)
        val = 0
        local ok = sm:load("migr")
        assert(ok == true)
        assert(val == 20, "migrated value should be doubled")
    "#,
    )
    .exec()
    .unwrap();
}
