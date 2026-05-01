//! INTERNAL ONLY: public `lurek.save.SaveManager` behavior is covered by the Lua-first suites in
//! `tests/lua/unit/test_save_unit.lua` and `tests/lua/security/test_save.lua`.
//!
//! The Rust-only coverage that remains here is limited to helpers and internal
//! state that are not directly observable through the Lua API:
//! - migration bookkeeping helpers such as `applicable_migrations`
//! - serializer/parser helpers like `serialize_table`, `serialize_value`, and
//!   `parse_save_string`
//! - private metadata defaults and path formatting helpers

use lurek2d::save::*;
use std::collections::HashMap;

// ── save_manager tests ───────────────────────────────────────────────────────

mod save_manager_tests {
    use super::*;

    #[test]
    fn migrations() {
        let mut sm = SaveManager::new();
        sm.set_schema_version(5);
        sm.add_migration(1);
        sm.add_migration(3);
        sm.add_migration(7); // above current
        let applicable = sm.applicable_migrations(2);
        assert_eq!(applicable, vec![3]);
    }

    #[test]
    fn serialize_simple() {
        let mut data = HashMap::new();
        data.insert("name".to_string(), SaveValue::Str("hero".to_string()));
        data.insert("level".to_string(), SaveValue::Number(5.0));
        data.insert("active".to_string(), SaveValue::Bool(true));
        let s = serialize_table(&data, 0).unwrap();
        assert!(s.contains("name = \"hero\""));
        assert!(s.contains("level = 5"));
        assert!(s.contains("active = true"));
    }

    #[test]
    fn serialize_depth_limit() {
        let inner = HashMap::new();
        let mut current = SaveValue::Table(inner);
        for _ in 0..35 {
            let mut t = HashMap::new();
            t.insert("nested".to_string(), current);
            current = SaveValue::Table(t);
        }
        if let SaveValue::Table(t) = current {
            let result = serialize_table(&t, 0);
            assert!(result.is_err());
        }
    }

    #[test]
    fn slot_path_format() {
        assert_eq!(SaveManager::slot_path("quick"), "save/slot_quick.sav");
        assert_eq!(SaveManager::slot_path("1"), "save/slot_1.sav");
    }

    #[test]
    fn parse_save_string_rejects_empty() {
        assert!(SaveManager::parse_save_string("").is_err());
        assert!(SaveManager::parse_save_string("   \n  ").is_err());
    }

    #[test]
    fn parse_save_string_accepts_content() {
        let result = SaveManager::parse_save_string("return { hp = 10 }");
        assert!(result.is_ok());
        assert_eq!(result.unwrap(), "return { hp = 10 }");
    }

    #[test]
    fn serialize_nil_and_bool() {
        assert_eq!(serialize_value(&SaveValue::Nil, 0).unwrap(), "nil");
        assert_eq!(serialize_value(&SaveValue::Bool(true), 0).unwrap(), "true");
        assert_eq!(
            serialize_value(&SaveValue::Bool(false), 0).unwrap(),
            "false"
        );
    }

    #[test]
    fn serialize_string_escapes() {
        let val = SaveValue::Str("line1\nline2".to_string());
        let s = serialize_value(&val, 0).unwrap();
        assert_eq!(s, "\"line1\\nline2\"");
    }

    #[test]
    fn serialize_nested_table() {
        let mut inner = HashMap::new();
        inner.insert("x".to_string(), SaveValue::Number(1.0));
        let mut outer = HashMap::new();
        outer.insert("pos".to_string(), SaveValue::Table(inner));
        let s = serialize_table(&outer, 0).unwrap();
        assert!(s.contains("pos = {"));
        assert!(s.contains("x = 1"));
    }

    #[test]
    fn add_migration_deduplicates_and_sorts() {
        let mut sm = SaveManager::new();
        sm.set_schema_version(10);
        sm.add_migration(5);
        sm.add_migration(3);
        sm.add_migration(5); // duplicate
        sm.add_migration(1);
        let migrations = sm.applicable_migrations(0);
        assert_eq!(migrations, vec![1, 3, 5]);
    }

    #[test]
    fn serialize_special_key_needs_bracket() {
        let mut data = HashMap::new();
        data.insert("has space".to_string(), SaveValue::Number(1.0));
        let s = serialize_table(&data, 0).unwrap();
        assert!(s.contains("[\"has space\"] = 1"));
    }

    #[test]
    fn slot_meta_default() {
        let meta = SlotMeta::default();
        assert_eq!(meta.slot, "");
        assert_eq!(meta.timestamp, 0.0);
        assert_eq!(meta.version, 0);
        assert_eq!(meta.summary, "");
    }
}
