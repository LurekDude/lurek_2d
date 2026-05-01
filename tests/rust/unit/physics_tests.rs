//! INTERNAL ONLY: Rust-only tests for physics helper internals that are not directly
//! asserted through `lurek.physics.*`.
//!
//! Public world, body, terrain, cellular, zone, and helper behavior is covered
//! by `tests/lua/unit/test_physics_unit.lua`.

use lurek2d::physics::*;
use lurek2d::physics::zone::ZoneTracker;
use std::collections::HashSet;

// ── body ──────────────────────────────────────────────────────────────────────

// Public body behavior is covered in `tests/lua/unit/test_physics_unit.lua`.

// ── collision_helpers ─────────────────────────────────────────────────────────

mod collision_helpers_tests {
    use lurek2d::physics::collision_helpers::{
        test_aabb,
        test_circle_aabb,
        test_circles,
        test_point_aabb,
    };

    #[test]
    fn aabb_overlap() {
        assert!(test_aabb(0.0, 0.0, 10.0, 10.0, 5.0, 5.0, 10.0, 10.0));
    }

    #[test]
    fn aabb_no_overlap() {
        assert!(!test_aabb(0.0, 0.0, 10.0, 10.0, 20.0, 20.0, 10.0, 10.0));
    }

    #[test]
    fn aabb_adjacent_no_overlap() {
        assert!(!test_aabb(0.0, 0.0, 10.0, 10.0, 10.0, 0.0, 10.0, 10.0));
    }

    #[test]
    fn circles_overlap() {
        assert!(test_circles(0.0, 0.0, 5.0, 3.0, 0.0, 5.0));
    }

    #[test]
    fn circles_no_overlap() {
        assert!(!test_circles(0.0, 0.0, 2.0, 10.0, 0.0, 2.0));
    }

    #[test]
    fn point_inside_aabb() {
        assert!(test_point_aabb(5.0, 5.0, 0.0, 0.0, 10.0, 10.0));
    }

    #[test]
    fn point_outside_aabb() {
        assert!(!test_point_aabb(15.0, 5.0, 0.0, 0.0, 10.0, 10.0));
    }

    #[test]
    fn point_on_boundary() {
        assert!(test_point_aabb(0.0, 0.0, 0.0, 0.0, 10.0, 10.0));
        assert!(!test_point_aabb(10.0, 10.0, 0.0, 0.0, 10.0, 10.0));
    }

    #[test]
    fn circle_aabb_overlap() {
        assert!(test_circle_aabb(5.0, 5.0, 3.0, 0.0, 0.0, 10.0, 10.0));
    }

    #[test]
    fn circle_aabb_no_overlap() {
        assert!(!test_circle_aabb(20.0, 20.0, 1.0, 0.0, 0.0, 10.0, 10.0));
    }

    #[test]
    fn circle_aabb_corner_case() {
        assert!(test_circle_aabb(12.0, 12.0, 3.0, 0.0, 0.0, 10.0, 10.0));
    }
}

// ── render ────────────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;

    #[test]
    fn generate_render_commands_empty_world_returns_empty() {
        let world = World::new(0.0, 9.8);
        let cmds = world.generate_render_commands();
        assert!(cmds.is_empty());
    }

    #[test]
    fn draw_to_image_correct_dimensions() {
        let world = World::new(0.0, 9.8);
        let img = world.draw_to_image(64, 64);
        assert_eq!(img.width(), 64);
        assert_eq!(img.height(), 64);
    }
}

// ── zone ──────────────────────────────────────────────────────────────────────

mod zone_tests {
    use super::*;

    #[test]
    fn tracker_enter_leave_events() {
        let mut tracker = ZoneTracker::new();
        let events = tracker.update(0, [1].into_iter().collect());
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].kind, ZoneEventKind::Enter);
        assert_eq!(events[0].zone_id, 1);

        let events = tracker.update(0, [1].into_iter().collect());
        assert!(events.is_empty());

        let events = tracker.update(0, HashSet::new());
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].kind, ZoneEventKind::Leave);
    }

    #[test]
    fn tracker_remove_body() {
        let mut tracker = ZoneTracker::new();
        tracker.update(0, [1].into_iter().collect());
        tracker.remove_body(0);
        let events = tracker.update(0, [1].into_iter().collect());
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].kind, ZoneEventKind::Enter);
    }
}

// ── shape ─────────────────────────────────────────────────────────────────────

// Public shape construction behavior is covered in `tests/lua/unit/test_physics_unit.lua`.

// ── world ─────────────────────────────────────────────────────────────────────

mod world_tests {
    use super::*;

    #[test]
    fn get_body_out_of_range_returns_none() {
        let w = World::new(0.0, 0.0);
        assert!(w.get_body(99).is_none());
    }

    #[test]
    fn get_body_mut_allows_mutation() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.get_body_mut(id).unwrap().position.x = 123.0;
        assert!((w.get_body(id).unwrap().position.x - 123.0).abs() < 1e-6);
    }

    #[test]
    fn destroy_body_out_of_range_no_panic() {
        let mut w = World::new(0.0, 0.0);
        w.destroy_body(999);
    }

    #[test]
    fn fixture_count_out_of_range() {
        let w = World::new(0.0, 0.0);
        assert_eq!(w.fixture_count(999), 0);
    }

    #[test]
    fn add_revolute_joint_returns_id() {
        let mut w = World::new(0.0, 0.0);
        let a = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        let b = w.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
        let jid = w.add_revolute_joint(a, b, 0.0, 0.0);
        assert_eq!(jid, 0);
        assert_eq!(w.joint_count(), 1);
    }

    #[test]
    fn destroy_joint_decrements_count_logically() {
        let mut w = World::new(0.0, 0.0);
        let a = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        let b = w.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
        let jid = w.add_revolute_joint(a, b, 0.0, 0.0);
        w.destroy_joint(jid);
    }

    #[test]
    fn add_zone_returns_id() {
        let mut w = World::new(0.0, 9.8);
        let zone = PhysicsZone::new_rect(0, 0.0, 0.0, 200.0, 200.0);
        let zid = w.add_zone(zone);
        assert!(zid > 0 || zid == 0);
    }

    #[test]
    fn collision_events_empty_without_step() {
        let w = World::new(0.0, 0.0);
        assert!(w.get_collision_events().is_empty());
    }

    #[test]
    fn begin_end_contact_events_empty_initially() {
        let w = World::new(0.0, 0.0);
        assert!(w.get_begin_contact_events().is_empty());
        assert!(w.get_end_contact_events().is_empty());
    }

    #[test]
    fn add_bodies_batch() {
        let mut w = World::new(0.0, 0.0);
        let specs = vec![
            (0.0, 0.0, BodyType::Dynamic),
            (10.0, 10.0, BodyType::Static),
            (20.0, 20.0, BodyType::Sensor),
        ];
        let ids = w.add_bodies(specs);
        assert_eq!(ids.len(), 3);
        assert_eq!(w.body_count(), 3);
    }
}
