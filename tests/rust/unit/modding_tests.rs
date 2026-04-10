//! Integration tests for the modding module.

use lurek2d::mods::{ModInfo, ModManager};

// ─── Rust unit-level integration tests ───

#[test]
fn mod_info_custom_fields() {
    let mut info = ModInfo::new("my-mod");
    info.name = "My Mod".to_string();
    info.version = "2.0.0".to_string();
    info.author = "Alice".to_string();
    info.description = "A test mod".to_string();
    info.priority = 5;
    info.dependencies = vec!["core".to_string()];
    assert_eq!(info.id, "my-mod");
    assert_eq!(info.name, "My Mod");
    assert_eq!(info.version, "2.0.0");
    assert_eq!(info.author, "Alice");
    assert_eq!(info.priority, 5);
    assert_eq!(info.dependencies.len(), 1);
}

#[test]
fn manager_register_replaces_existing() {
    let mut mgr = ModManager::new();
    let mut a1 = ModInfo::new("mod-a");
    a1.version = "1.0.0".to_string();
    mgr.register_mod(a1);
    let mut a2 = ModInfo::new("mod-a");
    a2.version = "2.0.0".to_string();
    mgr.register_mod(a2);
    assert_eq!(mgr.mod_count(), 1);
    assert_eq!(mgr.get_mod("mod-a").unwrap().version, "2.0.0");
}

#[test]
fn manager_get_mod_mut() {
    let mut mgr = ModManager::new();
    mgr.register_mod(ModInfo::new("x"));
    let m = mgr.get_mod_mut("x").unwrap();
    m.enabled = false;
    assert!(!mgr.get_mod("x").unwrap().enabled);
}

#[test]
fn load_order_alphabetical_for_same_priority() {
    let mut mgr = ModManager::new();
    mgr.register_mod(ModInfo::new("z-mod"));
    mgr.register_mod(ModInfo::new("a-mod"));
    let order = mgr.load_order();
    assert_eq!(order[0].id, "a-mod");
    assert_eq!(order[1].id, "z-mod");
}

#[test]
fn circular_deps_three_way() {
    let mut mgr = ModManager::new();
    let mut a = ModInfo::new("a");
    a.dependencies = vec!["b".to_string()];
    let mut b = ModInfo::new("b");
    b.dependencies = vec!["c".to_string()];
    let mut c = ModInfo::new("c");
    c.dependencies = vec!["a".to_string()];
    mgr.register_mod(a);
    mgr.register_mod(b);
    mgr.register_mod(c);
    assert!(mgr.has_circular_dependencies());
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
fn test_lua_new_mod_basic() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local m = lurek.modding.newMod({ id = "my-mod" })
        assert(m:getId() == "my-mod")
        assert(m:getName() == "my-mod")
        assert(m:getVersion() == "1.0.0")
        assert(m:getAuthor() == "")
        assert(m:getPriority() == 0)
        assert(m:isEnabled() == true)
        assert(m:isLoaded() == false)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_new_mod_with_fields() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local m = lurek.modding.newMod({
            id = "adv",
            name = "Adventure",
            version = "3.1.0",
            author = "Bob",
            description = "An adventure mod",
            priority = 10,
            dependencies = {"core", "utils"}
        })
        assert(m:getName() == "Adventure")
        assert(m:getVersion() == "3.1.0")
        assert(m:getAuthor() == "Bob")
        assert(m:getDescription() == "An adventure mod")
        assert(m:getPriority() == 10)
        local deps = m:getDependencies()
        assert(#deps == 2)
        assert(deps[1] == "core")
        assert(deps[2] == "utils")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_enable_disable() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local m = lurek.modding.newMod({ id = "toggle" })
        assert(m:isEnabled() == true)
        m:setEnabled(false)
        assert(m:isEnabled() == false)
        m:setEnabled(true)
        assert(m:isEnabled() == true)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_hooks() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local m = lurek.modding.newMod({ id = "hooked" })
        assert(m:hasHook("init") == false)
        local called = false
        m:setHook("init", function() called = true end)
        assert(m:hasHook("init") == true)
        local names = m:getHookNames()
        assert(#names == 1)
        assert(names[1] == "init")
        local fn_ref = m:getHook("init")
        assert(fn_ref ~= nil)
        fn_ref()
        assert(called == true)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_config() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local m = lurek.modding.newMod({ id = "cfg" })
        assert(m:getConfig() == nil)
        m:setConfig({ volume = 0.8, fullscreen = true })
        local c = m:getConfig()
        assert(c.volume == 0.8)
        assert(c.fullscreen == true)
        m:setConfig("simple")
        assert(m:getConfig() == "simple")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_release_refs() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local m = lurek.modding.newMod({ id = "cleanup" })
        m:setHook("a", function() end)
        m:setHook("b", function() end)
        m:setConfig({ x = 1 })
        m:releaseRefs()
        assert(m:hasHook("a") == false)
        assert(m:hasHook("b") == false)
        assert(m:getConfig() == nil)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_manager_basic() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local mgr = lurek.modding.newModManager()
        assert(mgr:getModCount() == 0)
        local m = lurek.modding.newMod({ id = "test" })
        mgr:registerMod(m)
        assert(mgr:getModCount() == 1)
        assert(mgr:hasMod("test") == true)
        assert(mgr:hasMod("other") == false)
        mgr:unregisterMod("test")
        assert(mgr:getModCount() == 0)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_manager_load_order() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local mgr = lurek.modding.newModManager()
        mgr:registerMod(lurek.modding.newMod({ id = "z", priority = 10 }))
        mgr:registerMod(lurek.modding.newMod({ id = "a", priority = 1 }))
        mgr:registerMod(lurek.modding.newMod({ id = "m", priority = 5 }))
        local order = mgr:getLoadOrder()
        assert(#order == 3)
        assert(order[1].id == "a")
        assert(order[2].id == "m")
        assert(order[3].id == "z")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_manager_validate_deps() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local mgr = lurek.modding.newModManager()
        mgr:registerMod(lurek.modding.newMod({ id = "a", dependencies = {"missing"} }))
        local missing = mgr:validateDependencies()
        assert(#missing == 1)
        assert(missing[1] == "missing")
        mgr:registerMod(lurek.modding.newMod({ id = "missing" }))
        local missing2 = mgr:validateDependencies()
        assert(#missing2 == 0)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_manager_circular_deps() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local mgr = lurek.modding.newModManager()
        mgr:registerMod(lurek.modding.newMod({ id = "a", dependencies = {"b"} }))
        mgr:registerMod(lurek.modding.newMod({ id = "b", dependencies = {"a"} }))
        assert(mgr:hasCircularDependencies() == true)

        local mgr2 = lurek.modding.newModManager()
        mgr2:registerMod(lurek.modding.newMod({ id = "x", dependencies = {"y"} }))
        mgr2:registerMod(lurek.modding.newMod({ id = "y" }))
        assert(mgr2:hasCircularDependencies() == false)
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_mod_manager_get_all_mods() {
    let (_state, lua) = make_vm();
    lua.load(
        r#"
        local mgr = lurek.modding.newModManager()
        mgr:registerMod(lurek.modding.newMod({ id = "alpha" }))
        mgr:registerMod(lurek.modding.newMod({ id = "beta" }))
        local all = mgr:getAllMods()
        assert(#all == 2)
        assert(all[1].id == "alpha")
        assert(all[2].id == "beta")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_lua_new_mod_requires_id() {
    let (_state, lua) = make_vm();
    let result = lua
        .load(r#"lurek.modding.newMod({ name = "no-id" })"#)
        .exec();
    assert!(result.is_err());
}
