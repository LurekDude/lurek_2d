//! INTERNAL ONLY: Rust-only tests for mods internals not exposed as `lurek.mods.*`.

mod mod_manager_tests {
    use lurek2d::mods::{ModInfo, ModManager};
    use std::fs;
    use tempfile::tempdir;

    fn write_mod_manifest(dir: &std::path::Path, manifest: &str) {
        fs::create_dir_all(dir).unwrap();
        fs::write(dir.join("mod.toml"), manifest).unwrap();
    }

    #[test]
    fn empty_manager_has_zero_mods() {
        let mgr = ModManager::new();
        assert_eq!(mgr.mod_count(), 0);
    }

    #[test]
    fn register_mod_increases_count() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("test_mod"));
        assert_eq!(mgr.mod_count(), 1);
    }

    #[test]
    fn has_mod_returns_true_after_register() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("my_mod"));
        assert!(mgr.has_mod("my_mod"));
    }

    #[test]
    fn unregister_mod_removes_it() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("rem_mod"));
        assert!(mgr.unregister_mod("rem_mod"));
        assert!(!mgr.has_mod("rem_mod"));
    }

    #[test]
    fn get_mods_by_capability_filters_matching_mods() {
        let mut mgr = ModManager::new();
        let mut save_mod = ModInfo::new("save_mod");
        save_mod.capabilities = vec!["save".to_string(), "ui".to_string()];
        mgr.register_mod(save_mod);

        let mut audio_mod = ModInfo::new("audio_mod");
        audio_mod.capabilities = vec!["audio".to_string()];
        mgr.register_mod(audio_mod);

        let matches = mgr.get_mods_by_capability("save");
        assert_eq!(matches.len(), 1);
        assert_eq!(matches[0].id, "save_mod");
    }

    #[test]
    fn load_order_respects_dependencies_before_priority() {
        let mut mgr = ModManager::new();

        let mut base = ModInfo::new("base_mod");
        base.priority = 50;
        mgr.register_mod(base);

        let mut child = ModInfo::new("child_mod");
        child.priority = -10;
        child.dependencies = vec!["base_mod".to_string()];
        mgr.register_mod(child);

        let order = mgr.load_order();
        assert_eq!(order[0].id, "base_mod");
        assert_eq!(order[1].id, "child_mod");
    }

    #[test]
    fn mark_for_reload_marks_loaded_false_and_dedupes_queue() {
        let mut mgr = ModManager::new();
        let mut info = ModInfo::new("reload_mod");
        info.loaded = true;
        mgr.register_mod(info);

        assert!(mgr.mark_for_reload("reload_mod"));
        assert!(mgr.mark_for_reload("reload_mod"));
        assert_eq!(mgr.get_reload_queue().len(), 1);
        assert!(!mgr.get_mod("reload_mod").unwrap().loaded);
    }

    #[test]
    fn from_parts_applies_optional_overrides() {
        let info = ModInfo::from_parts(
            "mod_a".to_string(),
            Some("Mod A".to_string()),
            Some("2.0.0".to_string()),
            Some("Author".to_string()),
            Some("Desc".to_string()),
            Some(7),
            vec!["dep_one".to_string(), "dep_two".to_string()],
        );

        assert_eq!(info.id, "mod_a");
        assert_eq!(info.name, "Mod A");
        assert_eq!(info.version, "2.0.0");
        assert_eq!(info.author, "Author");
        assert_eq!(info.description, "Desc");
        assert_eq!(info.priority, 7);
        assert_eq!(info.dependencies, ["dep_one", "dep_two"]);
    }

    #[test]
    fn get_mod_mut_updates_entry_in_place() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("edit_mod"));

        let info = mgr.get_mod_mut("edit_mod").unwrap();
        info.name = "Edited".to_string();
        info.priority = 42;

        let reread = mgr.get_mod("edit_mod").unwrap();
        assert_eq!(reread.name, "Edited");
        assert_eq!(reread.priority, 42);
    }

    #[test]
    fn get_custom_load_order_returns_explicit_order() {
        let mut mgr = ModManager::new();
        mgr.set_load_order(vec!["first".to_string(), "second".to_string()]);

        assert_eq!(mgr.get_custom_load_order().unwrap(), ["first", "second"]);

        mgr.clear_load_order();
        assert!(mgr.get_custom_load_order().is_none());
    }

    #[test]
    fn process_reload_queue_reloads_from_disk() {
        let temp_dir = tempdir().unwrap();
        let mod_dir = temp_dir.path().join("reload_mod");
        write_mod_manifest(
            &mod_dir,
            r#"
id = "reload_mod"
version = "1.0.0"
"#,
        );

        let mut mgr = ModManager::new();
        mgr.scan_folder(temp_dir.path().to_str().unwrap());
        assert!(mgr.mark_for_reload("reload_mod"));
        assert!(!mgr.get_mod("reload_mod").unwrap().loaded);

        write_mod_manifest(
            &mod_dir,
            r#"
id = "reload_mod"
version = "2.0.0"
"#,
        );

        let reloaded = mgr.process_reload_queue();
        assert_eq!(reloaded, ["reload_mod"]);
        assert!(mgr.get_reload_queue().is_empty());
        assert!(mgr.get_mod("reload_mod").unwrap().loaded);
        assert_eq!(mgr.get_mod("reload_mod").unwrap().version, "2.0.0");
    }

    #[test]
    fn scan_folder_skips_invalid_manifest() {
        let temp_dir = tempdir().unwrap();
        let mod_dir = temp_dir.path().join("broken_mod");
        write_mod_manifest(&mod_dir, "this is not valid toml");

        let mut mgr = ModManager::new();
        let discovered = mgr.scan_folder(temp_dir.path().to_str().unwrap());

        assert!(discovered.is_empty());
        assert_eq!(mgr.mod_count(), 0);
    }

    #[test]
    fn scan_folder_skips_missing_id_field() {
        let temp_dir = tempdir().unwrap();
        let mod_dir = temp_dir.path().join("missing_id_mod");
        write_mod_manifest(
            &mod_dir,
            r#"
name = "No ID"
"#,
        );

        let mut mgr = ModManager::new();
        let discovered = mgr.scan_folder(temp_dir.path().to_str().unwrap());

        assert!(discovered.is_empty());
        assert_eq!(mgr.mod_count(), 0);
    }

    #[test]
    fn scan_folder_skips_wrong_type_fields() {
        let temp_dir = tempdir().unwrap();
        let mod_dir = temp_dir.path().join("wrong_type_mod");
        write_mod_manifest(
            &mod_dir,
            r#"
id = "wrong_type_mod"
priority = "high"
"#,
        );

        let mut mgr = ModManager::new();
        let discovered = mgr.scan_folder(temp_dir.path().to_str().unwrap());

        assert_eq!(discovered.len(), 1);
        assert_eq!(discovered[0].priority, 0);
        assert!(mgr.has_mod("wrong_type_mod"));
    }

    #[test]
    fn scan_folder_skips_asset_conflicts() {
        let temp_dir = tempdir().unwrap();
        let first_dir = temp_dir.path().join("first_mod");
        let second_dir = temp_dir.path().join("second_mod");

        write_mod_manifest(
            &first_dir,
            r#"
id = "first_mod"
assets = ["shared/asset.png"]
"#,
        );
        write_mod_manifest(
            &second_dir,
            r#"
id = "second_mod"
assets = ["shared/asset.png"]
"#,
        );

        let mut mgr = ModManager::new();
        let discovered = mgr.scan_folder(temp_dir.path().to_str().unwrap());

        assert_eq!(discovered.len(), 1);
        assert_eq!(discovered[0].id, "first_mod");
        assert!(mgr.has_mod("first_mod"));
        assert!(!mgr.has_mod("second_mod"));
    }
}
