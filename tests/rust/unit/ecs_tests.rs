//! Tests for the ecs module.

use lurek2d::ecs::relationships::{RelationType, RelationshipManager};
use lurek2d::ecs::universe::Universe;

// ── universe — generational ID packing ───────────────────────────────────────

mod universe_tests {
    use super::*;

    #[test]
    fn pack_unpack_roundtrip() {
        let slot = 42u32;
        let gen = 7u8;
        let id = Universe::pack_id(slot, gen);
        assert_eq!(Universe::unpack_slot(id), slot);
        assert_eq!(Universe::unpack_gen(id), gen);
    }

    #[test]
    fn pack_id_zero_gen() {
        let id = Universe::pack_id(1, 0);
        assert_eq!(Universe::unpack_slot(id), 1);
        assert_eq!(Universe::unpack_gen(id), 0);
    }

    #[test]
    fn pack_id_max_slot() {
        let max_slot = 0x00FF_FFFFu32;
        let id = Universe::pack_id(max_slot, 255);
        assert_eq!(Universe::unpack_slot(id), max_slot);
        assert_eq!(Universe::unpack_gen(id), 255);
    }

    // ── Entity spawn ─────────────────────────────────────────────────────────

}

// ── relationships ────────────────────────────────────────────────────────────

mod relationships_tests {
    use super::*;

    // ── RelationType ─────────────────────────────────────────────────────────

    #[test]
    fn relation_type_has_level_returns_true_for_valid() {
        let rt = RelationType::new("diplomacy", vec!["war".into(), "peace".into()], "peace");
        assert!(rt.has_level("war"));
        assert!(rt.has_level("peace"));
    }

    #[test]
    fn relation_type_has_level_returns_false_for_unknown() {
        let rt = RelationType::new("diplomacy", vec!["war".into(), "peace".into()], "peace");
        assert!(!rt.has_level("neutral"));
    }

    // ── RelationshipManager — types ──────────────────────────────────────────

    #[test]
    fn define_and_get_type() {
        let mut mgr = RelationshipManager::new();
        mgr.define_type("trade", vec!["open".into(), "embargo".into()], "open");
        let t = mgr.get_type("trade").unwrap();
        assert_eq!(t.name, "trade");
        assert_eq!(t.default_level, "open");
    }

    #[test]
    fn type_names_returns_all_defined() {
        let mut mgr = RelationshipManager::new();
        mgr.define_type("a", vec!["x".into()], "x");
        mgr.define_type("b", vec!["y".into()], "y");
        let mut names = mgr.type_names();
        names.sort();
        assert_eq!(names, vec!["a", "b"]);
    }

    #[test]
    fn remove_type_cleans_levels() {
        let mut mgr = RelationshipManager::new();
        mgr.define_type("mood", vec!["happy".into(), "sad".into()], "happy");
        mgr.set_level(1, 2, "mood", "sad");
        assert!(mgr.remove_type("mood"));
        assert!(mgr.get_type("mood").is_none());
    }

    // ── RelationshipManager — values ─────────────────────────────────────────

    #[test]
    fn get_value_default_is_zero() {
        let mgr = RelationshipManager::new();
        assert!((mgr.get_value(1, 2)).abs() < f64::EPSILON);
    }

    #[test]
    fn set_and_get_value() {
        let mut mgr = RelationshipManager::new();
        mgr.set_value(1, 2, 50.0);
        assert!((mgr.get_value(1, 2) - 50.0).abs() < f64::EPSILON);
        // Symmetric — order should not matter
        assert!((mgr.get_value(2, 1) - 50.0).abs() < f64::EPSILON);
    }

    #[test]
    fn adjust_value_adds_delta() {
        let mut mgr = RelationshipManager::new();
        mgr.set_value(3, 4, 10.0);
        mgr.adjust_value(3, 4, -25.0);
        assert!((mgr.get_value(3, 4) - (-15.0)).abs() < f64::EPSILON);
    }

    // ── RelationshipManager — levels ─────────────────────────────────────────

    #[test]
    fn set_level_returns_false_for_unknown_type() {
        let mut mgr = RelationshipManager::new();
        assert!(!mgr.set_level(1, 2, "nonexistent", "x"));
    }

    #[test]
    fn set_level_returns_false_for_invalid_level() {
        let mut mgr = RelationshipManager::new();
        mgr.define_type("d", vec!["war".into(), "peace".into()], "peace");
        assert!(!mgr.set_level(1, 2, "d", "neutral"));
    }

    #[test]
    fn get_level_returns_default_when_unset() {
        let mut mgr = RelationshipManager::new();
        mgr.define_type("d", vec!["war".into(), "peace".into()], "peace");
        assert_eq!(mgr.get_level(1, 2, "d"), Some("peace".into()));
    }

    #[test]
    fn set_and_get_level() {
        let mut mgr = RelationshipManager::new();
        mgr.define_type("d", vec!["war".into(), "peace".into()], "peace");
        assert!(mgr.set_level(1, 2, "d", "war"));
        assert_eq!(mgr.get_level(1, 2, "d"), Some("war".into()));
    }

    // ── RelationshipManager — queries ────────────────────────────────────────

    #[test]
    fn has_relation_false_when_none_set() {
        let mgr = RelationshipManager::new();
        assert!(!mgr.has_relation(1, 2));
    }

    #[test]
    fn has_relation_true_after_set_value() {
        let mut mgr = RelationshipManager::new();
        mgr.set_value(5, 6, 1.0);
        assert!(mgr.has_relation(5, 6));
        assert!(mgr.has_relation(6, 5));
    }

    #[test]
    fn remove_relation_clears_record() {
        let mut mgr = RelationshipManager::new();
        mgr.set_value(1, 2, 10.0);
        assert!(mgr.remove_relation(1, 2));
        assert!(!mgr.has_relation(1, 2));
    }

    #[test]
    fn all_relations_for_filters_correctly() {
        let mut mgr = RelationshipManager::new();
        mgr.set_value(1, 2, 1.0);
        mgr.set_value(1, 3, 2.0);
        mgr.set_value(4, 5, 3.0);
        let rels = mgr.all_relations_for(1);
        assert_eq!(rels.len(), 2);
    }

    #[test]
    fn relation_count_tracks_records() {
        let mut mgr = RelationshipManager::new();
        assert_eq!(mgr.relation_count(), 0);
        mgr.set_value(1, 2, 1.0);
        assert_eq!(mgr.relation_count(), 1);
    }

    // ── RelationshipManager — directed links ─────────────────────────────────

    #[test]
    fn add_and_get_link() {
        let mut mgr = RelationshipManager::new();
        mgr.add_link(1, "owns", 2);
        assert_eq!(mgr.get_links(1, "owns"), &[2]);
    }

    #[test]
    fn add_link_deduplicates() {
        let mut mgr = RelationshipManager::new();
        mgr.add_link(1, "owns", 2);
        mgr.add_link(1, "owns", 2);
        assert_eq!(mgr.get_links(1, "owns"), &[2]);
    }

    #[test]
    fn has_link_works() {
        let mut mgr = RelationshipManager::new();
        mgr.add_link(1, "parent", 2);
        assert!(mgr.has_link(1, "parent", 2));
        assert!(!mgr.has_link(2, "parent", 1)); // directed
    }

    #[test]
    fn remove_link_drops_single_target() {
        let mut mgr = RelationshipManager::new();
        mgr.add_link(1, "r", 2);
        mgr.add_link(1, "r", 3);
        mgr.remove_link(1, "r", 2);
        assert!(!mgr.has_link(1, "r", 2));
        assert!(mgr.has_link(1, "r", 3));
    }

    #[test]
    fn clear_links_removes_all_for_name() {
        let mut mgr = RelationshipManager::new();
        mgr.add_link(1, "r", 2);
        mgr.add_link(1, "r", 3);
        mgr.clear_links(1, "r");
        assert_eq!(mgr.get_links(1, "r"), &[] as &[u32]);
    }
}
