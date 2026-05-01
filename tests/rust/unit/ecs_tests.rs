//! INTERNAL ONLY: Rust-only tests for ECS internals that are not directly asserted through
//! `lurek.ecs.*`.
//!
//! Public ECS-facing behaviour is covered by `tests/lua/unit/test_ecs_unit.lua`.
//! The remaining Rust tests keep ID packing and relationship-manager internals.

use lurek2d::ecs::relationships::RelationshipManager;
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
}

// ── relationships ────────────────────────────────────────────────────────────

mod relationships_tests {
    use super::*;

    #[test]
    fn define_and_get_type() {
        let mut mgr = RelationshipManager::new();
        mgr.define_type("trade", vec!["open".into(), "embargo".into()], "open");
        let t = mgr.get_type("trade").unwrap();
        assert_eq!(t.name, "trade");
        assert_eq!(t.default_level, "open");
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
}
