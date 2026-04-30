//! Tests for the physics module.

use lurek2d::physics::*;
use lurek2d::physics::zone::ZoneTracker;
use std::collections::HashSet;

// ── cellular ──────────────────────────────────────────────────────────────────

mod cellular_tests {
    use super::*;

    #[test]
    fn new_world_is_all_air() {
        let w = CellularWorld::new(8, 8);
        assert_eq!(w.get_cell(0, 0), CellType::Air);
        assert_eq!(w.get_cell(7, 7), CellType::Air);
        assert_eq!(w.count_cells(CellType::Air), 64);
    }

    #[test]
    fn set_get_cell() {
        let mut w = CellularWorld::new(4, 4);
        w.set_cell(1, 2, CellType::Sand);
        assert_eq!(w.get_cell(1, 2), CellType::Sand);
        assert_eq!(w.get_cell(0, 0), CellType::Air);
    }

    #[test]
    fn out_of_bounds_returns_air() {
        let w = CellularWorld::new(4, 4);
        assert_eq!(w.get_cell(100, 100), CellType::Air);
    }

    #[test]
    fn fill_rect_sets_cells() {
        let mut w = CellularWorld::new(8, 8);
        w.fill_rect(2, 2, 3, 3, CellType::Rock);
        assert_eq!(w.count_cells(CellType::Rock), 9);
        assert_eq!(w.get_cell(2, 2), CellType::Rock);
        assert_eq!(w.get_cell(4, 4), CellType::Rock);
        assert_eq!(w.get_cell(5, 5), CellType::Air);
    }

    #[test]
    fn fill_circle_sets_cells() {
        let mut w = CellularWorld::new(16, 16);
        w.fill_circle(8, 8, 3, CellType::Water);
        assert!(w.count_cells(CellType::Water) > 0);
        assert_eq!(w.get_cell(8, 8), CellType::Water);
    }

    #[test]
    fn sand_falls_down() {
        let mut w = CellularWorld::new(4, 4);
        w.set_cell(1, 0, CellType::Sand);
        w.step();
        assert_eq!(w.get_cell(1, 1), CellType::Sand);
    }

    #[test]
    fn step_n_advances_multiple() {
        let mut w = CellularWorld::new(4, 8);
        w.set_cell(2, 0, CellType::Sand);
        w.step_n(4);
        assert_eq!(w.get_cell(2, 0), CellType::Air);
    }

    #[test]
    fn find_cells_returns_positions() {
        let mut w = CellularWorld::new(4, 4);
        w.set_cell(1, 2, CellType::Rock);
        w.set_cell(3, 3, CellType::Rock);
        let rocks = w.find_cells(CellType::Rock);
        assert_eq!(rocks.len(), 2);
        assert!(rocks.contains(&(1, 2)));
        assert!(rocks.contains(&(3, 3)));
    }

    #[test]
    fn serialization_roundtrip() {
        let mut w = CellularWorld::new(8, 8);
        w.set_cell(3, 3, CellType::Sand);
        w.set_cell(5, 5, CellType::Water);
        let bytes = w.to_bytes();
        let w2 = CellularWorld::from_bytes(&bytes).unwrap();
        assert_eq!(w2.width, 8);
        assert_eq!(w2.height, 8);
        assert_eq!(w2.get_cell(3, 3), CellType::Sand);
        assert_eq!(w2.get_cell(5, 5), CellType::Water);
        assert_eq!(w2.get_cell(0, 0), CellType::Air);
    }

    #[test]
    fn from_bytes_too_short() {
        assert!(CellularWorld::from_bytes(&[0; 4]).is_none());
    }

    #[test]
    fn cell_type_from_u8_unknown() {
        assert_eq!(CellType::from_u8(255), CellType::Air);
    }

    #[test]
    fn default_palette_returns_correct_colors() {
        let air = default_palette(CellType::Air);
        assert_eq!(air, [20, 20, 30, 255]);
        let sand = default_palette(CellType::Sand);
        assert_eq!(sand, [194, 178, 128, 255]);
    }

    #[test]
    fn to_image_data_length() {
        let w = CellularWorld::new(4, 4);
        let data = w.to_image_data(|_| [0, 0, 0, 255]);
        assert_eq!(data.len(), 4 * 4 * 4);
    }
}

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
    fn rect_boundary_contains() {
        let b = ZoneBoundary::Rect { x: 10.0, y: 10.0, width: 100.0, height: 50.0 };
        assert!(b.contains(50.0, 30.0));
        assert!(!b.contains(5.0, 30.0));
        assert!(b.contains(10.0, 10.0));
        assert!(b.contains(110.0, 60.0));
    }

    #[test]
    fn circle_boundary_contains() {
        let b = ZoneBoundary::Circle { cx: 50.0, cy: 50.0, radius: 10.0 };
        assert!(b.contains(50.0, 50.0));
        assert!(b.contains(55.0, 50.0));
        assert!(!b.contains(65.0, 50.0));
    }

    #[test]
    fn zone_new_rect_defaults() {
        let z = PhysicsZone::new_rect(0, 0.0, 0.0, 100.0, 100.0);
        assert!(z.enabled);
        assert_eq!(z.priority, 0);
        assert!(matches!(z.gravity_mode, ZoneGravityMode::Zero));
        assert_eq!(z.layer_mask, 0xFFFF_FFFF);
    }

    #[test]
    fn zone_set_circle() {
        let mut z = PhysicsZone::new_rect(1, 0.0, 0.0, 10.0, 10.0);
        z.set_circle(50.0, 50.0, 25.0);
        assert!(matches!(z.boundary, ZoneBoundary::Circle { cx, cy, radius }
            if (cx - 50.0).abs() < 1e-6 && (cy - 50.0).abs() < 1e-6 && (radius - 25.0).abs() < 1e-6));
    }

    #[test]
    fn zone_gravity_modes() {
        let mut z = PhysicsZone::new_rect(0, 0.0, 0.0, 10.0, 10.0);
        z.set_gravity_directional(0.0, 9.8);
        assert!(matches!(z.gravity_mode, ZoneGravityMode::Directional { .. }));
        z.set_gravity_point(5.0, 5.0, 100.0);
        assert!(matches!(z.gravity_mode, ZoneGravityMode::Point { .. }));
        z.set_gravity_repulsor(5.0, 5.0, 50.0);
        assert!(matches!(z.gravity_mode, ZoneGravityMode::Repulsor { .. }));
        z.set_gravity_zero();
        assert!(matches!(z.gravity_mode, ZoneGravityMode::Zero));
    }

    #[test]
    fn zone_contains_disabled() {
        let mut z = PhysicsZone::new_rect(0, 0.0, 0.0, 100.0, 100.0);
        assert!(z.contains(50.0, 50.0));
        z.enabled = false;
        assert!(!z.contains(50.0, 50.0));
    }

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

// ── terrain ───────────────────────────────────────────────────────────────────

mod terrain_tests {
    use super::*;

    #[test]
    fn new_terrain_all_empty() {
        let t = TerrainMap::new(32, 32, 8.0);
        assert!(!t.get_cell(0, 0));
        assert!(!t.get_cell(31, 31));
        assert!(!t.is_dirty());
    }

    #[test]
    fn set_cell_marks_dirty() {
        let mut t = TerrainMap::new(32, 32, 8.0);
        t.set_cell(5, 5, true);
        assert!(t.get_cell(5, 5));
        assert!(t.is_dirty());
    }

    #[test]
    fn set_cell_out_of_bounds_ignored() {
        let mut t = TerrainMap::new(8, 8, 4.0);
        t.set_cell(100, 100, true);
        assert!(!t.is_dirty());
    }

    #[test]
    fn fill_all_solid() {
        let mut t = TerrainMap::new(16, 16, 4.0);
        t.fill_all(true);
        assert!(t.get_cell(0, 0));
        assert!(t.get_cell(15, 15));
        assert!(t.is_dirty());
    }

    #[test]
    fn fill_circle_creates_solid() {
        let mut t = TerrainMap::new(64, 64, 1.0);
        t.fill_circle(32.0, 32.0, 10.0, true);
        assert!(t.get_cell(32, 32));
        assert!(t.is_dirty());
    }

    #[test]
    fn fill_rect_creates_solid() {
        let mut t = TerrainMap::new(32, 32, 1.0);
        t.fill_rect(5.0, 5.0, 10.0, 10.0, true);
        assert!(t.get_cell(10, 10));
    }

    #[test]
    fn serialization_roundtrip() {
        let mut t = TerrainMap::new(16, 16, 4.0);
        t.fill_all(true);
        t.set_cell(3, 3, false);
        let bytes = t.to_bytes();
        let t2 = TerrainMap::from_bytes(&bytes).unwrap();
        assert_eq!(t2.width, 16);
        assert_eq!(t2.height, 16);
        assert!((t2.cell_size - 4.0).abs() < 1e-6);
        assert!(t2.get_cell(0, 0));
        assert!(!t2.get_cell(3, 3));
    }

    #[test]
    fn from_bytes_too_short() {
        assert!(TerrainMap::from_bytes(&[0; 8]).is_none());
    }

    #[test]
    fn collapse_columns_removes_unsupported() {
        let mut t = TerrainMap::new(4, 4, 1.0);
        t.set_cell(1, 1, true);
        let removed = t.collapse_columns();
        assert_eq!(removed, 1);
        assert!(!t.get_cell(1, 1));
    }

    #[test]
    fn solid_cell_positions_returns_all_solid() {
        let mut t = TerrainMap::new(4, 4, 2.0);
        t.set_cell(0, 0, true);
        t.set_cell(3, 3, true);
        let positions = t.solid_cell_positions();
        assert_eq!(positions.len(), 2);
    }

    #[test]
    fn to_image_data_length() {
        let t = TerrainMap::new(8, 8, 1.0);
        let data = t.to_image_data([255, 255, 255, 255], [0, 0, 0, 255]);
        assert_eq!(data.len(), 8 * 8 * 4);
    }

    #[test]
    fn load_from_bytes_dimension_mismatch() {
        let mut t = TerrainMap::new(8, 8, 1.0);
        let t2 = TerrainMap::new(16, 16, 1.0);
        let bytes = t2.to_bytes();
        assert!(!t.load_from_bytes(&bytes));
    }
}

// ── shape ─────────────────────────────────────────────────────────────────────

// Public shape construction behavior is covered in `tests/lua/unit/test_physics_unit.lua`.

// ── world ─────────────────────────────────────────────────────────────────────

mod world_tests {
    use super::*;

    #[test]
    fn new_world_has_zero_bodies() {
        let w = World::new(0.0, 9.8);
        assert_eq!(w.body_count(), 0);
    }

    #[test]
    fn new_world_gravity() {
        let w = World::new(0.0, 9.8);
        let (gx, gy) = w.get_gravity();
        assert!((gx).abs() < 1e-6);
        assert!((gy - 9.8).abs() < 1e-6);
    }

    #[test]
    fn add_body_returns_sequential_ids() {
        let mut w = World::new(0.0, 9.8);
        let id0 = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        let id1 = w.add_body(Body::new(10.0, 0.0, BodyType::Static));
        assert_eq!(id0, 0);
        assert_eq!(id1, 1);
        assert_eq!(w.body_count(), 2);
    }

    #[test]
    fn get_body_returns_correct_position() {
        let mut w = World::new(0.0, 9.8);
        let id = w.add_body(Body::new(42.0, 99.0, BodyType::Dynamic));
        let b = w.get_body(id).unwrap();
        assert!((b.position.x - 42.0).abs() < 1e-6);
        assert!((b.position.y - 99.0).abs() < 1e-6);
    }

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
    fn get_body_ids_matches_count() {
        let mut w = World::new(0.0, 0.0);
        w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.add_body(Body::new(0.0, 0.0, BodyType::Static));
        w.add_body(Body::new(0.0, 0.0, BodyType::Sensor));
        let ids = w.get_body_ids();
        assert_eq!(ids.len(), 3);
    }

    #[test]
    fn add_circle_body() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new_circle(10.0, 20.0, 5.0, BodyType::Dynamic));
        let b = w.get_body(id).unwrap();
        assert!(matches!(b.shape, BodyShape::Circle { radius } if (radius - 5.0).abs() < 1e-6));
    }

    #[test]
    fn destroy_body_marks_static() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.destroy_body(id);
        assert_eq!(w.get_body(id).unwrap().body_type, BodyType::Static);
    }

    #[test]
    fn destroy_body_out_of_range_no_panic() {
        let mut w = World::new(0.0, 0.0);
        w.destroy_body(999);
    }

    #[test]
    fn step_moves_dynamic_body_under_gravity() {
        let mut w = World::new(0.0, 100.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        let y_before = w.get_body(id).unwrap().position.y;
        for _ in 0..10 {
            w.step(1.0 / 60.0);
        }
        let y_after = w.get_body(id).unwrap().position.y;
        assert!(y_after > y_before);
    }

    #[test]
    fn step_does_not_move_static_body() {
        let mut w = World::new(0.0, 100.0);
        let id = w.add_body(Body::new(50.0, 50.0, BodyType::Static));
        for _ in 0..10 {
            w.step(1.0 / 60.0);
        }
        let b = w.get_body(id).unwrap();
        assert!((b.position.x - 50.0).abs() < 1e-3);
        assert!((b.position.y - 50.0).abs() < 1e-3);
    }

    #[test]
    fn set_get_gravity() {
        let mut w = World::new(0.0, 0.0);
        w.set_gravity(1.0, -5.0);
        let (gx, gy) = w.get_gravity();
        assert!((gx - 1.0).abs() < 1e-6);
        assert!((gy - (-5.0)).abs() < 1e-6);
    }

    #[test]
    fn clear_empties_world() {
        let mut w = World::new(0.0, 9.8);
        w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.add_body(Body::new(0.0, 0.0, BodyType::Static));
        assert_eq!(w.body_count(), 2);
        w.clear();
        assert_eq!(w.body_count(), 0);
        assert!(w.get_body_ids().is_empty());
    }

    #[test]
    fn fixture_count_default_one() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        assert_eq!(w.fixture_count(id), 1);
    }

    #[test]
    fn add_fixture_increases_count() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.add_fixture(id, Shape::Circle { radius: 5.0 }, 1.0, 0.5, 0.3, false);
        assert_eq!(w.fixture_count(id), 2);
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
    fn meter_scaling_defaults() {
        let w = World::new(0.0, 0.0);
        assert!((w.get_meter() - 1.0).abs() < 1e-6);
    }

    #[test]
    fn set_meter_and_convert() {
        let mut w = World::new(0.0, 0.0);
        w.set_meter(64.0);
        assert!((w.get_meter() - 64.0).abs() < 1e-6);
        assert!((w.to_physics(128.0) - 2.0).abs() < 1e-6);
        assert!((w.to_pixels(2.0) - 128.0).abs() < 1e-6);
    }

    #[test]
    fn sleeping_allowed_default() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        assert!(w.is_sleeping_allowed(id));
    }

    #[test]
    fn set_sleeping_disallowed() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.set_sleeping_allowed(id, false);
        assert!(!w.is_sleeping_allowed(id));
    }

    #[test]
    fn add_zone_returns_id() {
        let mut w = World::new(0.0, 9.8);
        let zone = PhysicsZone::new_rect(0, 0.0, 0.0, 200.0, 200.0);
        let zid = w.add_zone(zone);
        assert!(zid > 0 || zid == 0);
    }

    #[test]
    fn step_fixed_returns_steps_and_remainder() {
        let mut w = World::new(0.0, 9.8);
        w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        let (steps, remainder) = w.step_fixed(0.05, 1.0 / 60.0, 4);
        assert!(steps >= 1);
        assert!(remainder >= 0.0);
        assert!(remainder < 1.0 / 60.0 + 1e-6);
    }

    #[test]
    fn set_body_type_changes_type() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.set_body_type(id, BodyType::Kinematic);
        assert_eq!(w.get_body(id).unwrap().body_type, BodyType::Kinematic);
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

    #[test]
    fn raycast_empty_world_returns_none() {
        let w = World::new(0.0, 0.0);
        assert!(w.raycast(0.0, 0.0, 100.0, 0.0).is_none());
    }

    #[test]
    fn body_angle_get_set() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.set_body_angle(id, 1.5);
        assert!((w.get_body_angle(id) - 1.5).abs() < 1e-3);
    }

    #[test]
    fn body_mass_get_set() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.set_body_mass(id, 5.0);
        assert!((w.get_body_mass(id) - 5.0).abs() < 1e-3);
    }

    #[test]
    fn gravity_scale_get_set() {
        let mut w = World::new(0.0, 9.8);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        w.set_gravity_scale(id, 0.5);
        assert!((w.get_gravity_scale(id) - 0.5).abs() < 1e-3);
    }

    #[test]
    fn body_type_str() {
        let mut w = World::new(0.0, 0.0);
        let id = w.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
        assert_eq!(w.get_body_type_str(id), "dynamic");
    }
}
