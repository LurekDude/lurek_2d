//! Integration tests for the entity module: Universe ECS with entity lifecycle,
//! string tags, bitmap tags, layers, components, blueprints, and systems.

use lurek2d::ecs::Universe;

fn make_lua() -> mlua::Lua {
    mlua::Lua::new()
}

// ============================================================
// Entity Lifecycle — Pure Rust
// ============================================================

#[test]
fn test_spawn_sequential_ids() {
    let mut u = Universe::new();
    assert_eq!(u.spawn(), 1);
    assert_eq!(u.spawn(), 2);
    assert_eq!(u.spawn(), 3);
}

#[test]
fn test_spawn_recycled_lifo() {
    let lua = make_lua();
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    assert_eq!(a, 1);
    assert_eq!(b, 2);
    u.kill(b, &lua).unwrap();
    u.kill(a, &lua).unwrap();
    // LIFO — same SLOT is recycled, but generation increments so packed IDs differ
    let c = u.spawn();
    assert_eq!(
        c & 0x00FF_FFFF,
        a & 0x00FF_FFFF,
        "same slot recycled (LIFO)"
    );
    assert_ne!(c, a, "packed ID must differ after gen increment");
    let d = u.spawn();
    assert_eq!(
        d & 0x00FF_FFFF,
        b & 0x00FF_FFFF,
        "same slot recycled (LIFO)"
    );
    assert_ne!(d, b, "packed ID must differ after gen increment");
}

#[test]
fn test_is_alive() {
    let lua = make_lua();
    let mut u = Universe::new();
    assert!(!u.is_alive(1), "entity 1 not yet spawned");
    assert!(!u.is_alive(999), "entity 999 never created");
    let id = u.spawn();
    assert!(u.is_alive(id), "entity alive after spawn");
    u.kill(id, &lua).unwrap();
    assert!(!u.is_alive(id), "entity dead after kill");
}

#[test]
fn test_entity_count() {
    let lua = make_lua();
    let mut u = Universe::new();
    assert_eq!(u.get_entity_count(), 0);
    let a = u.spawn();
    assert_eq!(u.get_entity_count(), 1);
    u.spawn();
    assert_eq!(u.get_entity_count(), 2);
    u.kill(a, &lua).unwrap();
    assert_eq!(u.get_entity_count(), 1);
}

#[test]
fn test_get_entities_returns_alive_ids() {
    let lua = make_lua();
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    let c = u.spawn();
    u.kill(b, &lua).unwrap();
    let mut entities = u.get_entities();
    entities.sort();
    assert_eq!(entities, vec![a, c]);
}

#[test]
fn test_kill_idempotent() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();
    u.kill(id, &lua).unwrap();
    // Killing again should not error
    u.kill(id, &lua).unwrap();
    assert_eq!(u.get_entity_count(), 0);
}

// ============================================================
// String Tags — Pure Rust
// ============================================================

#[test]
fn test_string_tags_add_remove_has_get() {
    let mut u = Universe::new();
    let id = u.spawn();

    assert!(!u.has_tag(id, "enemy"));
    assert!(u.get_tags(id).is_empty());

    u.add_tag(id, "enemy");
    assert!(u.has_tag(id, "enemy"));
    assert!(!u.has_tag(id, "player"));

    u.add_tag(id, "strong");
    let tags = u.get_tags(id);
    assert_eq!(tags.len(), 2);
    assert!(tags.contains(&"enemy".to_string()));
    assert!(tags.contains(&"strong".to_string()));

    u.remove_tag(id, "enemy");
    assert!(!u.has_tag(id, "enemy"));
    assert!(u.has_tag(id, "strong"));
}

#[test]
fn test_string_tags_duplicate_add_ignored() {
    let mut u = Universe::new();
    let id = u.spawn();
    u.add_tag(id, "x");
    u.add_tag(id, "x");
    assert_eq!(u.get_tags(id).len(), 1);
}

#[test]
fn test_get_entities_by_tag() {
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    let c = u.spawn();
    u.add_tag(a, "enemy");
    u.add_tag(b, "enemy");
    u.add_tag(c, "ally");

    let enemies = u.get_entities_by_tag("enemy");
    assert_eq!(enemies, vec![a, b]);

    let allies = u.get_entities_by_tag("ally");
    assert_eq!(allies, vec![c]);

    let none = u.get_entities_by_tag("ghost");
    assert!(none.is_empty());
}

#[test]
fn test_string_tags_dead_entity_noop() {
    let mut u = Universe::new();
    // Adding tag to non-alive entity should be no-op
    u.add_tag(99, "foo");
    assert!(!u.has_tag(99, "foo"));
}

// ============================================================
// Bitmap Tags — Pure Rust
// ============================================================

#[test]
fn test_bitmap_tag_define_sequential_bits() {
    let mut u = Universe::new();
    let b0 = u.define_tag("fast").unwrap();
    let b1 = u.define_tag("strong").unwrap();
    let b2 = u.define_tag("flying").unwrap();
    assert_eq!(b0, 0);
    assert_eq!(b1, 1);
    assert_eq!(b2, 2);
}

#[test]
fn test_bitmap_tag_define_idempotent() {
    let mut u = Universe::new();
    let b0 = u.define_tag("fast").unwrap();
    let b0_again = u.define_tag("fast").unwrap();
    assert_eq!(b0, b0_again);
}

#[test]
fn test_bitmap_tag_set_query() {
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    u.bitmap_tag(a, "fast").unwrap();
    u.bitmap_tag(b, "fast").unwrap();
    u.bitmap_tag(a, "strong").unwrap();

    let fast = u.query_bitmap_tag("fast");
    assert_eq!(fast, vec![a, b]);

    let strong = u.query_bitmap_tag("strong");
    assert_eq!(strong, vec![a]);
}

#[test]
fn test_bitmap_tag_all_query() {
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    u.bitmap_tag(a, "fast").unwrap();
    u.bitmap_tag(a, "strong").unwrap();
    u.bitmap_tag(b, "fast").unwrap();

    let both = u.query_bitmap_all(&["fast".into(), "strong".into()]);
    assert_eq!(both, vec![a]);
}

#[test]
fn test_bitmap_tag_any_query() {
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    let c = u.spawn();
    u.bitmap_tag(a, "fast").unwrap();
    u.bitmap_tag(b, "strong").unwrap();

    let any = u.query_bitmap_any(&["fast".into(), "strong".into()]);
    assert_eq!(any, vec![a, b]);

    // c has no tags, should not appear
    assert!(!any.contains(&c));
}

#[test]
fn test_bitmap_tag_limit_63_ok_64th_errors() {
    let mut u = Universe::new();
    for i in 0..63 {
        u.define_tag(&format!("tag_{}", i)).unwrap();
    }
    // 64th should error
    let result = u.define_tag("tag_63");
    assert!(result.is_err());
}

#[test]
fn test_bitmap_tag_untag() {
    let mut u = Universe::new();
    let id = u.spawn();
    u.bitmap_tag(id, "fast").unwrap();
    assert!(u.has_bitmap_tag(id, "fast"));
    u.bitmap_untag(id, "fast");
    assert!(!u.has_bitmap_tag(id, "fast"));
}

#[test]
fn test_bitmap_tag_get_bit() {
    let mut u = Universe::new();
    assert_eq!(u.get_bitmap_tag_bit("unknown"), None);
    u.define_tag("known").unwrap();
    assert_eq!(u.get_bitmap_tag_bit("known"), Some(0));
}

#[test]
fn test_bitmap_tag_query_undefined_tag_returns_empty() {
    let u = Universe::new();
    assert!(u.query_bitmap_tag("nonexistent").is_empty());
}

#[test]
fn test_bitmap_tag_all_undefined_tag_returns_empty() {
    let mut u = Universe::new();
    let id = u.spawn();
    u.bitmap_tag(id, "a").unwrap();
    let result = u.query_bitmap_all(&["a".into(), "nonexistent".into()]);
    assert!(result.is_empty());
}

// ============================================================
// Layers — Pure Rust
// ============================================================

#[test]
fn test_layers_default_zero() {
    let mut u = Universe::new();
    let id = u.spawn();
    assert_eq!(u.get_layer(id), 0);
}

#[test]
fn test_set_get_layer() {
    let mut u = Universe::new();
    let id = u.spawn();
    u.set_layer(id, 5);
    assert_eq!(u.get_layer(id), 5);
    u.set_layer(id, -3);
    assert_eq!(u.get_layer(id), -3);
}

#[test]
fn test_entities_by_layer() {
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    let c = u.spawn();
    u.set_layer(a, 1);
    u.set_layer(b, 2);
    u.set_layer(c, 1);

    let layer1 = u.get_entities_by_layer(1);
    assert_eq!(layer1, vec![a, c]);

    let layer2 = u.get_entities_by_layer(2);
    assert_eq!(layer2, vec![b]);

    // Default layer 0 — no entities set to 0 explicitly but that's default
    let layer0 = u.get_entities_by_layer(0);
    assert!(layer0.is_empty());
}

#[test]
fn test_entities_sorted_by_layer_then_id() {
    let mut u = Universe::new();
    let a = u.spawn(); // 1
    let b = u.spawn(); // 2
    let c = u.spawn(); // 3
    u.set_layer(a, 2);
    u.set_layer(b, 0);
    u.set_layer(c, 2);

    let sorted = u.get_entities_sorted();
    // b (layer 0) < a (layer 2, id 1) < c (layer 2, id 3)
    assert_eq!(sorted, vec![b, a, c]);
}

#[test]
fn test_set_layer_dead_entity_noop() {
    let mut u = Universe::new();
    u.set_layer(999, 5);
    // Should not have stored anything for a dead entity
    assert_eq!(u.get_layer(999), 0);
}

// ============================================================
// Components — Lua Required
// ============================================================

#[test]
fn test_component_set_get_integer() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();
    u.set_component(&lua, id, "hp", mlua::Value::Integer(100))
        .unwrap();
    let val = u.get_component(&lua, id, "hp").unwrap();
    assert_eq!(val, mlua::Value::Integer(100));
}

#[test]
fn test_component_set_get_string() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();
    let s = lua.create_string("Hero").unwrap();
    u.set_component(&lua, id, "name", mlua::Value::String(s))
        .unwrap();
    let val = u.get_component(&lua, id, "name").unwrap();
    match val {
        mlua::Value::String(s) => assert_eq!(s.to_str().unwrap(), "Hero"),
        _ => panic!("expected string component"),
    }
}

#[test]
fn test_component_has_remove() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();

    assert!(!u.has_component(&lua, id, "hp").unwrap());

    u.set_component(&lua, id, "hp", mlua::Value::Integer(50))
        .unwrap();
    assert!(u.has_component(&lua, id, "hp").unwrap());

    u.remove_component(&lua, id, "hp").unwrap();
    assert!(!u.has_component(&lua, id, "hp").unwrap());

    let val = u.get_component(&lua, id, "hp").unwrap();
    assert!(val.is_nil());
}

#[test]
fn test_component_names() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();
    u.set_component(&lua, id, "hp", mlua::Value::Integer(10))
        .unwrap();
    u.set_component(&lua, id, "speed", mlua::Value::Number(3.5))
        .unwrap();

    let mut names = u.get_component_names(&lua, id).unwrap();
    names.sort();
    assert_eq!(names, vec!["hp".to_string(), "speed".to_string()]);
}

#[test]
fn test_query_components() {
    let lua = make_lua();
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    let c = u.spawn();

    u.set_component(&lua, a, "hp", mlua::Value::Integer(10))
        .unwrap();
    u.set_component(&lua, a, "speed", mlua::Value::Integer(5))
        .unwrap();
    u.set_component(&lua, b, "hp", mlua::Value::Integer(20))
        .unwrap();
    u.set_component(&lua, c, "speed", mlua::Value::Integer(8))
        .unwrap();

    // Query entities with both hp and speed
    let both = u
        .query(&lua, &["hp".to_string(), "speed".to_string()])
        .unwrap();
    assert_eq!(both, vec![a]);

    // Query entities with hp only
    let hp_only = u.query(&lua, &["hp".to_string()]).unwrap();
    assert_eq!(hp_only, vec![a, b]);

    // Empty query returns all
    let all = u.query(&lua, &[]).unwrap();
    let mut all_sorted = all;
    all_sorted.sort();
    assert_eq!(all_sorted, vec![a, b, c]);
}

#[test]
fn test_set_component_dead_entity_errors() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();
    u.kill(id, &lua).unwrap();

    let result = u.set_component(&lua, id, "hp", mlua::Value::Integer(10));
    assert!(result.is_err());
}

#[test]
fn test_get_component_dead_entity_returns_nil() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();
    u.set_component(&lua, id, "hp", mlua::Value::Integer(10))
        .unwrap();
    u.kill(id, &lua).unwrap();

    let val = u.get_component(&lua, id, "hp").unwrap();
    assert!(val.is_nil());
}

#[test]
fn test_kill_removes_components() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();
    u.set_component(&lua, id, "hp", mlua::Value::Integer(100))
        .unwrap();
    u.set_component(&lua, id, "name", mlua::Value::Integer(42))
        .unwrap();

    u.kill(id, &lua).unwrap();
    // Respawn reuses the same slot but with incremented generation
    let id2 = u.spawn();
    assert_eq!(
        id2 & 0x00FF_FFFF,
        id & 0x00FF_FFFF,
        "same slot should be recycled"
    );
    assert_ne!(id2, id, "generation must differ for recycled slot");
    // Components should not carry over to the new entity at the same slot
    let val = u.get_component(&lua, id2, "hp").unwrap();
    assert!(val.is_nil());
}

#[test]
fn test_kill_clears_tags_and_layers() {
    let lua = make_lua();
    let mut u = Universe::new();
    let id = u.spawn();
    u.add_tag(id, "enemy");
    u.bitmap_tag(id, "fast").unwrap();
    u.set_layer(id, 5);

    u.kill(id, &lua).unwrap();
    // All metadata should be cleaned up
    assert!(!u.has_tag(id, "enemy"));
    assert!(!u.has_bitmap_tag(id, "fast"));
    // After respawn, same slot is reused (different gen), layer defaults to 0
    let id2 = u.spawn();
    assert_eq!(
        id2 & 0x00FF_FFFF,
        id & 0x00FF_FFFF,
        "same slot should be recycled"
    );
    assert_ne!(id2, id, "generation must differ for recycled slot");
    assert_eq!(u.get_layer(id2), 0);
}

// ============================================================
// Blueprints — Lua Required
// ============================================================

#[test]
fn test_blueprint_define_spawn() {
    let lua = make_lua();
    let mut u = Universe::new();

    let comps = lua.create_table().unwrap();
    comps.set("hp", 30).unwrap();
    comps.set("speed", 100).unwrap();
    u.define_blueprint(&lua, "goblin", comps).unwrap();

    assert!(u.has_blueprint(&lua, "goblin").unwrap());

    let id = u.spawn_blueprint(&lua, "goblin", None).unwrap();
    assert!(u.is_alive(id));

    let hp = u.get_component(&lua, id, "hp").unwrap();
    assert_eq!(hp, mlua::Value::Integer(30));
    let speed = u.get_component(&lua, id, "speed").unwrap();
    assert_eq!(speed, mlua::Value::Integer(100));
}

#[test]
fn test_blueprint_deep_copy_isolation() {
    let lua = make_lua();
    let mut u = Universe::new();

    let comps = lua.create_table().unwrap();
    comps.set("hp", 30).unwrap();
    u.define_blueprint(&lua, "goblin", comps).unwrap();

    let g1 = u.spawn_blueprint(&lua, "goblin", None).unwrap();
    u.set_component(&lua, g1, "hp", mlua::Value::Integer(999))
        .unwrap();

    let g2 = u.spawn_blueprint(&lua, "goblin", None).unwrap();
    let hp2 = u.get_component(&lua, g2, "hp").unwrap();
    assert_eq!(
        hp2,
        mlua::Value::Integer(30),
        "blueprint isolation: second spawn unaffected"
    );
}

#[test]
fn test_blueprint_extend() {
    let lua = make_lua();
    let mut u = Universe::new();

    let base = lua.create_table().unwrap();
    base.set("hp", 30).unwrap();
    base.set("speed", 100).unwrap();
    u.define_blueprint(&lua, "goblin", base).unwrap();

    let overrides = lua.create_table().unwrap();
    overrides.set("hp", 200).unwrap();
    overrides.set("boss", true).unwrap();
    u.extend_blueprint(&lua, "boss_goblin", "goblin", overrides)
        .unwrap();

    let bg = u.spawn_blueprint(&lua, "boss_goblin", None).unwrap();
    let hp = u.get_component(&lua, bg, "hp").unwrap();
    assert_eq!(hp, mlua::Value::Integer(200), "override hp");

    let speed = u.get_component(&lua, bg, "speed").unwrap();
    assert_eq!(speed, mlua::Value::Integer(100), "inherited speed");

    let boss = u.get_component(&lua, bg, "boss").unwrap();
    assert_eq!(boss, mlua::Value::Boolean(true), "new field");
}

#[test]
fn test_blueprint_spawn_with_overrides() {
    let lua = make_lua();
    let mut u = Universe::new();

    let comps = lua.create_table().unwrap();
    comps.set("hp", 30).unwrap();
    comps.set("speed", 100).unwrap();
    u.define_blueprint(&lua, "goblin", comps).unwrap();

    let ov = lua.create_table().unwrap();
    ov.set("hp", 50).unwrap();
    let id = u.spawn_blueprint(&lua, "goblin", Some(ov)).unwrap();

    let hp = u.get_component(&lua, id, "hp").unwrap();
    assert_eq!(hp, mlua::Value::Integer(50), "override applied");
    let speed = u.get_component(&lua, id, "speed").unwrap();
    assert_eq!(speed, mlua::Value::Integer(100), "non-overridden preserved");
}

#[test]
fn test_blueprint_list_has_remove() {
    let lua = make_lua();
    let mut u = Universe::new();

    let comps = lua.create_table().unwrap();
    comps.set("a", 1).unwrap();
    u.define_blueprint(&lua, "alpha", comps.clone()).unwrap();
    u.define_blueprint(&lua, "beta", comps).unwrap();

    assert!(u.has_blueprint(&lua, "alpha").unwrap());
    assert!(u.has_blueprint(&lua, "beta").unwrap());

    let mut list = u.list_blueprints(&lua).unwrap();
    list.sort();
    assert_eq!(list, vec!["alpha".to_string(), "beta".to_string()]);

    u.remove_blueprint(&lua, "alpha").unwrap();
    assert!(!u.has_blueprint(&lua, "alpha").unwrap());
    assert!(u.has_blueprint(&lua, "beta").unwrap());
}

#[test]
fn test_blueprint_get_components() {
    let lua = make_lua();
    let mut u = Universe::new();

    let comps = lua.create_table().unwrap();
    comps.set("hp", 30).unwrap();
    u.define_blueprint(&lua, "goblin", comps).unwrap();

    let bp_val = u.get_blueprint_components(&lua, "goblin").unwrap();
    match bp_val {
        mlua::Value::Table(t) => {
            let hp: i32 = t.get("hp").unwrap();
            assert_eq!(hp, 30);
        }
        _ => panic!("expected table from get_blueprint_components"),
    }

    // Non-existent blueprint returns nil
    let missing = u.get_blueprint_components(&lua, "nonexistent").unwrap();
    assert!(missing.is_nil());
}

#[test]
fn test_blueprint_spawn_undefined_errors() {
    let lua = make_lua();
    let mut u = Universe::new();
    let result = u.spawn_blueprint(&lua, "nonexistent", None);
    assert!(result.is_err());
}

#[test]
fn test_blueprint_extend_undefined_parent_errors() {
    let lua = make_lua();
    let mut u = Universe::new();
    let overrides = lua.create_table().unwrap();
    overrides.set("x", 1).unwrap();
    let result = u.extend_blueprint(&lua, "child", "nonexistent", overrides);
    assert!(result.is_err());
}

// ============================================================
// Clear — Lua Required
// ============================================================

#[test]
fn test_clear_resets_entities_preserves_blueprints() {
    let lua = make_lua();
    let mut u = Universe::new();

    let comps = lua.create_table().unwrap();
    comps.set("val", 1).unwrap();
    u.define_blueprint(&lua, "preserved", comps).unwrap();

    let id = u.spawn();
    u.set_component(&lua, id, "hp", mlua::Value::Integer(10))
        .unwrap();
    u.add_tag(id, "x");

    u.clear(&lua).unwrap();

    assert_eq!(u.get_entity_count(), 0);
    assert!(!u.is_alive(id));
    assert!(u.has_blueprint(&lua, "preserved").unwrap());

    // IDs reset to 1
    let new_id = u.spawn();
    assert_eq!(new_id, 1);
}

// ============================================================
// Systems — Lua Required
// ============================================================

#[test]
fn test_system_add_count() {
    let lua = make_lua();
    let mut u = Universe::new();

    assert_eq!(u.get_system_count(&lua).unwrap(), 0);

    let sys = lua.create_table().unwrap();
    u.add_system(&lua, sys).unwrap();
    assert_eq!(u.get_system_count(&lua).unwrap(), 1);

    let sys2 = lua.create_table().unwrap();
    u.add_system(&lua, sys2).unwrap();
    assert_eq!(u.get_system_count(&lua).unwrap(), 2);
}

#[test]
fn test_system_remove() {
    let lua = make_lua();
    let mut u = Universe::new();

    let sys1 = lua.create_table().unwrap();
    let sys2 = lua.create_table().unwrap();
    u.add_system(&lua, sys1.clone()).unwrap();
    u.add_system(&lua, sys2).unwrap();
    assert_eq!(u.get_system_count(&lua).unwrap(), 2);

    u.remove_system(&lua, sys1).unwrap();
    assert_eq!(u.get_system_count(&lua).unwrap(), 1);
}

#[test]
fn test_system_remove_not_registered_errors() {
    let lua = make_lua();
    let mut u = Universe::new();

    let sys = lua.create_table().unwrap();
    u.add_system(&lua, lua.create_table().unwrap()).unwrap();

    let result = u.remove_system(&lua, sys);
    assert!(result.is_err());
}

#[test]
fn test_clear_resets_systems() {
    let lua = make_lua();
    let mut u = Universe::new();

    let sys = lua.create_table().unwrap();
    u.add_system(&lua, sys).unwrap();
    assert_eq!(u.get_system_count(&lua).unwrap(), 1);

    u.clear(&lua).unwrap();
    assert_eq!(u.get_system_count(&lua).unwrap(), 0);
}

// ============================================================
// [RED] Generational IDs — NOT yet implemented
// These tests compile but FAIL until generation packing lands.
// ============================================================

#[test]
fn test_stale_id_after_recycle_detects_as_dead() {
    // After kill + re-spawn of same slot, old packed ID must report is_alive=false.
    // Requires: generation packing in spawn() — not yet implemented.
    let lua = make_lua();
    let mut u = Universe::new();
    let old_id = u.spawn();
    u.kill(old_id, &lua).unwrap();
    let new_id = u.spawn(); // recycles same slot with incremented generation
                            // The OLD id (stale generation) must not be alive.
                            // This test PASSES only when generational IDs are implemented.
    assert!(!u.is_alive(old_id), "old ID must be dead after recycle");
    assert!(u.is_alive(new_id), "new ID must be alive");
    // The two IDs must be different once generations are tracked.
    assert_ne!(
        old_id, new_id,
        "recycled slot must produce different packed ID"
    );
}

#[test]
fn test_stale_id_component_access_errors() {
    // Accessing a stale (recycled) entity for component ops must return error/nil.
    // Requires: generation packing in spawn() — not yet implemented.
    let lua = make_lua();
    let mut u = Universe::new();
    let old_id = u.spawn();
    u.kill(old_id, &lua).unwrap();
    let _new_id = u.spawn(); // recycles slot
                             // Getting a component on the stale ID should not return data from the new entity.
                             // (returns nil is acceptable — must not return new entity's data)
    let result = u.get_component(&lua, old_id, "health");
    // Should be Ok(Nil) or Err — must not panic.
    assert!(result.is_ok() || result.is_err(), "should not panic");
    if let Ok(val) = result {
        assert!(
            val.is_nil(),
            "stale ID must not see new entity's components"
        );
    }
}

// ============================================================
// [RED/GREEN] Inverted Tag Index — guards against regression
// These compile and currently pass — guards against future regression.
// ============================================================

#[test]
fn test_inverted_tag_index_remove_on_kill() {
    // After kill, entity is removed from inverted index — not just from alive set.
    // passes today — guards against regression
    let lua = make_lua();
    let mut u = Universe::new();
    let a = u.spawn();
    let b = u.spawn();
    u.add_tag(a, "enemy");
    u.add_tag(b, "enemy");
    u.kill(a, &lua).unwrap();
    // After kill, a must NOT appear in tag results.
    let enemies = u.get_entities_by_tag("enemy");
    assert!(
        !enemies.contains(&a),
        "dead entity must not appear in tag query"
    );
    assert!(enemies.contains(&b), "alive entity must still appear");
}

#[test]
fn test_inverted_tag_index_consistent_after_tag_remove() {
    // Removing a tag must update the inverted index.
    // passes today — guards against regression
    let mut u = Universe::new();
    let a = u.spawn();
    u.add_tag(a, "visible");
    u.remove_tag(a, "visible");
    let visible = u.get_entities_by_tag("visible");
    assert!(
        !visible.contains(&a),
        "entity must leave inverted index after tag removal"
    );
}

// ============================================================
// [RED] Parent-Child Hierarchy — NOT yet implemented
// These tests WILL NOT COMPILE until set_parent/get_parent/
// get_children/kill_recursive are added to Universe.
// Add them now; they will be red until Phase 3 lands.
// ============================================================

#[test]
fn test_parent_set_and_get() {
    let _lua = make_lua();
    let mut u = Universe::new();
    let parent = u.spawn();
    let child = u.spawn();
    u.set_parent(child, Some(parent));
    assert_eq!(u.get_parent(child), Some(parent));
    // detach
    u.set_parent(child, None);
    assert_eq!(u.get_parent(child), None);
}

#[test]
fn test_get_children_returns_direct_children() {
    let mut u = Universe::new();
    let parent = u.spawn();
    let c1 = u.spawn();
    let c2 = u.spawn();
    let other = u.spawn();
    u.set_parent(c1, Some(parent));
    u.set_parent(c2, Some(parent));
    let children = u.get_children(parent);
    assert!(children.contains(&c1));
    assert!(children.contains(&c2));
    assert!(!children.contains(&other));
}

#[test]
fn test_kill_recursive_kills_all_descendants() {
    let lua = make_lua();
    let mut u = Universe::new();
    let root = u.spawn();
    let child = u.spawn();
    let grandchild = u.spawn();
    u.set_parent(child, Some(root));
    u.set_parent(grandchild, Some(child));
    u.kill_recursive(root, &lua).unwrap();
    assert!(!u.is_alive(root));
    assert!(!u.is_alive(child));
    assert!(!u.is_alive(grandchild));
}

#[test]
fn test_kill_parent_detaches_children() {
    let lua = make_lua();
    let mut u = Universe::new();
    let parent = u.spawn();
    let child = u.spawn();
    u.set_parent(child, Some(parent));
    // Regular kill (not recursive) should detach child but not kill it.
    u.kill(parent, &lua).unwrap();
    assert!(!u.is_alive(parent));
    assert!(
        u.is_alive(child),
        "child must survive non-recursive kill of parent"
    );
    assert_eq!(
        u.get_parent(child),
        None,
        "child must be detached after parent dies"
    );
}
