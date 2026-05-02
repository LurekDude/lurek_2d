//! INTERNAL ONLY: Rust-only tests for mods internals not exposed as `lurek.mods.*`.

mod mod_manager_tests {
    use lurek2d::mods::{ModInfo, ModManager};

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
}
