//! Tests for the math module.

// ── aabb_tree ─────────────────────────────────────────────────────────────────

mod aabb_tree_tests {
    use lurek2d::math::AabbTree;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn new_tree_is_empty() {
        let tree = AabbTree::new();
        assert!(tree.is_empty());
        assert_eq!(tree.len(), 0);
    }

    // ── Insert ────────────────────────────────────────────────────────────────

    #[test]
    fn insert_single_item() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        assert_eq!(tree.len(), 1);
        assert!(tree.contains(1));
    }

    #[test]
    fn insert_multiple_items() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        tree.insert(2, 20.0, 20.0, 30.0, 30.0);
        tree.insert(3, 5.0, 5.0, 15.0, 15.0);
        assert_eq!(tree.len(), 3);
    }

    #[test]
    fn insert_duplicate_id_replaces() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        tree.insert(1, 50.0, 50.0, 60.0, 60.0);
        assert_eq!(tree.len(), 1);
        // Query at old location should miss
        let hits = tree.query(0.0, 0.0, 10.0, 10.0);
        assert!(!hits.contains(&1));
        // Query at new location should hit
        let hits = tree.query(50.0, 50.0, 60.0, 60.0);
        assert!(hits.contains(&1));
    }

    // ── Remove ────────────────────────────────────────────────────────────────

    #[test]
    fn remove_existing_returns_true() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        assert!(tree.remove(1));
        assert!(tree.is_empty());
    }

    #[test]
    fn remove_nonexistent_returns_false() {
        let mut tree = AabbTree::new();
        assert!(!tree.remove(999));
    }

    #[test]
    fn remove_middle_item_preserves_others() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 5.0, 5.0);
        tree.insert(2, 10.0, 10.0, 15.0, 15.0);
        tree.insert(3, 20.0, 20.0, 25.0, 25.0);
        tree.remove(2);
        assert_eq!(tree.len(), 2);
        assert!(tree.contains(1));
        assert!(!tree.contains(2));
        assert!(tree.contains(3));
    }

    // ── Query ─────────────────────────────────────────────────────────────────

    #[test]
    fn query_finds_overlapping() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        tree.insert(2, 20.0, 20.0, 30.0, 30.0);
        let hits = tree.query(5.0, 5.0, 15.0, 15.0);
        assert!(hits.contains(&1));
        assert!(!hits.contains(&2));
    }

    #[test]
    fn query_empty_tree_returns_empty() {
        let tree = AabbTree::new();
        let hits = tree.query(0.0, 0.0, 100.0, 100.0);
        assert!(hits.is_empty());
    }

    #[test]
    fn query_no_overlap_returns_empty() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 5.0, 5.0);
        let hits = tree.query(100.0, 100.0, 200.0, 200.0);
        assert!(hits.is_empty());
    }

    #[test]
    fn query_touching_edges_counts_as_overlap() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        // Query AABB that touches at (10, 10) — touching edges count
        let hits = tree.query(10.0, 10.0, 20.0, 20.0);
        assert!(hits.contains(&1));
    }

    // ── Query point ───────────────────────────────────────────────────────────

    #[test]
    fn query_point_inside() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        let hits = tree.query_point(5.0, 5.0);
        assert!(hits.contains(&1));
    }

    #[test]
    fn query_point_outside() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        let hits = tree.query_point(50.0, 50.0);
        assert!(hits.is_empty());
    }

    // ── Update ────────────────────────────────────────────────────────────────

    #[test]
    fn update_moves_item() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 10.0, 10.0);
        tree.update(1, 100.0, 100.0, 110.0, 110.0);
        // Old location: miss
        let hits = tree.query(0.0, 0.0, 10.0, 10.0);
        assert!(!hits.contains(&1));
        // New location: hit
        let hits = tree.query(100.0, 100.0, 110.0, 110.0);
        assert!(hits.contains(&1));
    }

    #[test]
    fn update_nonexistent_returns_false() {
        let mut tree = AabbTree::new();
        assert!(!tree.update(999, 0.0, 0.0, 1.0, 1.0));
    }

    // ── Clear ─────────────────────────────────────────────────────────────────

    #[test]
    fn clear_empties_tree() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 5.0, 5.0);
        tree.insert(2, 10.0, 10.0, 15.0, 15.0);
        tree.clear();
        assert!(tree.is_empty());
        assert_eq!(tree.len(), 0);
    }

    // ── Stress / many items ───────────────────────────────────────────────────

    #[test]
    fn many_items_query_correctness() {
        let mut tree = AabbTree::new();
        // Insert 100 non-overlapping items in a grid
        for i in 0..10 {
            for j in 0..10 {
                let id = (i * 10 + j) as u64;
                let x = i as f32 * 20.0;
                let y = j as f32 * 20.0;
                tree.insert(id, x, y, x + 10.0, y + 10.0);
            }
        }
        assert_eq!(tree.len(), 100);

        // Query a small region that should only hit item at (0,0)
        let hits = tree.query(0.0, 0.0, 5.0, 5.0);
        assert!(hits.contains(&0));
        // Should not contain items far away
        assert!(!hits.contains(&99));
    }

    #[test]
    fn insert_remove_all_leaves_empty() {
        let mut tree = AabbTree::new();
        for id in 0..20u64 {
            tree.insert(id, id as f32, id as f32, id as f32 + 5.0, id as f32 + 5.0);
        }
        for id in 0..20u64 {
            tree.remove(id);
        }
        assert!(tree.is_empty());
    }
}

// ── bezier ────────────────────────────────────────────────────────────────────

mod bezier_tests {
    use lurek2d::math::{BezierCurve, Vec2};

    // ── Endpoints ────────────────────────────────────────────────────────────

    #[test]
    fn evaluate_t0_is_first_control_point() {
        let curve = BezierCurve::new(vec![Vec2::new(1.0, 2.0), Vec2::new(3.0, 4.0)]);
        let p = curve.evaluate(0.0);
        assert!((p.x - 1.0).abs() < 1e-5);
        assert!((p.y - 2.0).abs() < 1e-5);
    }

    #[test]
    fn evaluate_t1_is_last_control_point() {
        let curve = BezierCurve::new(vec![Vec2::new(1.0, 2.0), Vec2::new(3.0, 4.0)]);
        let p = curve.evaluate(1.0);
        assert!((p.x - 3.0).abs() < 1e-5);
        assert!((p.y - 4.0).abs() < 1e-5);
    }

    // ── Midpoint ─────────────────────────────────────────────────────────────

    #[test]
    fn linear_midpoint_is_average() {
        let curve = BezierCurve::new(vec![Vec2::new(0.0, 0.0), Vec2::new(4.0, 2.0)]);
        let p = curve.evaluate(0.5);
        assert!((p.x - 2.0).abs() < 1e-5);
        assert!((p.y - 1.0).abs() < 1e-5);
    }

    // ── Render ────────────────────────────────────────────────────────────────

    #[test]
    fn render_produces_segments_plus_one_points() {
        let curve = BezierCurve::new(vec![Vec2::ZERO, Vec2::ONE]);
        let points = curve.render(4);
        assert_eq!(points.len(), 5);
    }

    #[test]
    fn render_first_point_is_start() {
        let start = Vec2::new(1.0, 2.0);
        let curve = BezierCurve::new(vec![start, Vec2::new(5.0, 6.0)]);
        let points = curve.render(8);
        assert!((points[0].x - start.x).abs() < 1e-5);
        assert!((points[0].y - start.y).abs() < 1e-5);
    }

    // ── Control points ────────────────────────────────────────────────────────

    #[test]
    fn get_set_control_point_roundtrip() {
        let mut curve = BezierCurve::new(vec![Vec2::ZERO, Vec2::ONE]);
        let new_pt = Vec2::new(9.0, 8.0);
        let ok = curve.set_control_point(0, new_pt);
        assert!(ok);
        let got = curve.get_control_point(0).expect("get_control_point returns Some for a valid index");
        assert!((got.x - 9.0).abs() < 1e-5);
        assert!((got.y - 8.0).abs() < 1e-5);
    }

    #[test]
    fn get_control_point_out_of_bounds_returns_none() {
        let curve = BezierCurve::new(vec![Vec2::ZERO, Vec2::ONE]);
        assert!(curve.get_control_point(99).is_none());
    }
}

// ── color ─────────────────────────────────────────────────────────────────────

mod color_tests {
    use lurek2d::math::{Color, gamma_to_linear, linear_to_gamma};

    // ── Constants ─────────────────────────────────────────────────────────────

    #[test]
    fn white_constant_all_channels_one() {
        let c = Color::WHITE;
        assert!((c.r - 1.0).abs() < 1e-5);
        assert!((c.g - 1.0).abs() < 1e-5);
        assert!((c.b - 1.0).abs() < 1e-5);
        assert!((c.a - 1.0).abs() < 1e-5);
    }

    #[test]
    fn black_constant_rgb_zero_alpha_one() {
        let c = Color::BLACK;
        assert!((c.r).abs() < 1e-5);
        assert!((c.g).abs() < 1e-5);
        assert!((c.b).abs() < 1e-5);
        assert!((c.a - 1.0).abs() < 1e-5);
    }

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn from_u8_red_correct() {
        let c = Color::from_u8(255, 0, 0, 255);
        assert!((c.r - 1.0).abs() < 1e-5);
        assert!((c.g).abs() < 1e-5);
        assert!((c.b).abs() < 1e-5);
        assert!((c.a - 1.0).abs() < 1e-5);
    }

    #[test]
    fn from_u8_zero_gives_transparent_black() {
        let c = Color::from_u8(0, 0, 0, 0);
        assert!((c.r).abs() < 1e-5);
        assert!((c.a).abs() < 1e-5);
    }

    // ── Conversion ────────────────────────────────────────────────────────────

    #[test]
    fn to_u8_white_gives_255() {
        let (r, g, b, a) = Color::WHITE.to_u8();
        assert_eq!(r, 255);
        assert_eq!(g, 255);
        assert_eq!(b, 255);
        assert_eq!(a, 255);
    }

    #[test]
    fn to_rgb_u32_red_expected_value() {
        let v = Color::RED.to_rgb_u32();
        assert_eq!(v, 0x00FF_0000u32);
    }

    #[test]
    fn to_rgb_u32_blue_expected_value() {
        let v = Color::BLUE.to_rgb_u32();
        assert_eq!(v, 0x0000_00FFu32);
    }

    #[test]
    fn default_is_white() {
        let c = Color::default();
        assert!((c.r - 1.0).abs() < 1e-5);
        assert!((c.a - 1.0).abs() < 1e-5);
    }

    // ── Gamma / linear ────────────────────────────────────────────────────────

    #[test]
    fn gamma_to_linear_zero_is_zero() {
        assert!((gamma_to_linear(0.0)).abs() < 1e-5);
    }

    #[test]
    fn linear_to_gamma_zero_is_zero() {
        assert!((linear_to_gamma(0.0)).abs() < 1e-5);
    }

    #[test]
    fn gamma_linear_roundtrip() {
        let original = 0.5f32;
        let linear = gamma_to_linear(original);
        let back = linear_to_gamma(linear);
        assert!((back - original).abs() < 1e-4);
    }
}

// ── easing ────────────────────────────────────────────────────────────────────

mod easing_tests {
    use lurek2d::math::easing::*;

    fn approx(a: f32, b: f32) -> bool {
        (a - b).abs() < 1e-5
    }

    #[test]
    fn test_easing_boundaries_start_at_zero() {
        let funcs: Vec<(&str, fn(f32) -> f32)> = vec![
            ("linear", linear),
            ("ease_in_quad", ease_in_quad),
            ("ease_out_quad", ease_out_quad),
            ("ease_in_out_quad", ease_in_out_quad),
            ("ease_in_cubic", ease_in_cubic),
            ("ease_out_cubic", ease_out_cubic),
            ("ease_in_out_cubic", ease_in_out_cubic),
            ("ease_in_quart", ease_in_quart),
            ("ease_out_quart", ease_out_quart),
            ("ease_in_out_quart", ease_in_out_quart),
            ("ease_in_sine", ease_in_sine),
            ("ease_out_sine", ease_out_sine),
            ("ease_in_out_sine", ease_in_out_sine),
            ("ease_in_expo", ease_in_expo),
            ("ease_out_expo", ease_out_expo),
            ("ease_in_out_expo", ease_in_out_expo),
            ("ease_out_bounce", ease_out_bounce),
            ("ease_in_bounce", ease_in_bounce),
            ("ease_in_back", ease_in_back),
            ("ease_out_back", ease_out_back),
        ];
        for (name, f) in &funcs {
            assert!(
                approx(f(0.0), 0.0),
                "{name} did not start at 0.0: {}",
                f(0.0)
            );
        }
    }

    #[test]
    fn test_easing_boundaries_end_at_one() {
        let funcs: Vec<(&str, fn(f32) -> f32)> = vec![
            ("linear", linear),
            ("ease_in_quad", ease_in_quad),
            ("ease_out_quad", ease_out_quad),
            ("ease_in_out_quad", ease_in_out_quad),
            ("ease_in_cubic", ease_in_cubic),
            ("ease_out_cubic", ease_out_cubic),
            ("ease_in_out_cubic", ease_in_out_cubic),
            ("ease_in_quart", ease_in_quart),
            ("ease_out_quart", ease_out_quart),
            ("ease_in_out_quart", ease_in_out_quart),
            ("ease_in_sine", ease_in_sine),
            ("ease_out_sine", ease_out_sine),
            ("ease_in_out_sine", ease_in_out_sine),
            ("ease_in_expo", ease_in_expo),
            ("ease_out_expo", ease_out_expo),
            ("ease_in_out_expo", ease_in_out_expo),
            ("ease_out_bounce", ease_out_bounce),
            ("ease_in_bounce", ease_in_bounce),
            ("ease_out_back", ease_out_back),
        ];
        for (name, f) in &funcs {
            assert!(approx(f(1.0), 1.0), "{name} did not end at 1.0: {}", f(1.0));
        }
    }

    #[test]
    fn test_easing_midpoints() {
        assert!(approx(linear(0.5), 0.5));
        assert!(approx(ease_in_out_quad(0.5), 0.5));
        assert!(approx(ease_in_out_cubic(0.5), 0.5));
        assert!(approx(ease_in_out_sine(0.5), 0.5));
    }

    #[test]
    fn test_apply_lookup() {
        assert!(approx(apply("inQuad", 0.5).expect("inQuad is a known easing name"), ease_in_quad(0.5)));
        assert!(approx(apply("outCubic", 0.5).expect("outCubic is a known easing name"), ease_out_cubic(0.5)));
        assert!(approx(apply("linear", 1.0).expect("linear is a known easing name"), 1.0));
        assert!(apply("nonexistent", 0.5).is_none());
    }

    #[test]
    fn test_apply_case_insensitive() {
        assert!(approx(apply("INQUAD", 0.5).expect("INQUAD matched case-insensitively"), ease_in_quad(0.5)));
        assert!(approx(apply("OutBounce", 1.0).expect("OutBounce matched case-insensitively"), 1.0));
    }

    #[test]
    fn test_elastic_boundaries() {
        assert!(approx(ease_in_elastic(0.0), 0.0));
        assert!(approx(ease_in_elastic(1.0), 1.0));
        assert!(approx(ease_out_elastic(0.0), 0.0));
        assert!(approx(ease_out_elastic(1.0), 1.0));
    }
}

// ── geometry ──────────────────────────────────────────────────────────────────

mod geometry_tests {
    use lurek2d::math::*;
    use std::f32::consts::PI;

    #[test]
    fn test_angle_between() {
        let a = angle_between(0.0, 0.0, 1.0, 0.0);
        assert!((a - 0.0).abs() < 1e-5);
        let a = angle_between(0.0, 0.0, 0.0, 1.0);
        assert!((a - PI / 2.0).abs() < 1e-5);
    }

    #[test]
    fn test_circle_contains_point() {
        assert!(circle_contains_point(0.0, 0.0, 5.0, 3.0, 4.0));
        assert!(!circle_contains_point(0.0, 0.0, 5.0, 4.0, 4.0));
    }

    #[test]
    fn test_circle_intersects_circle() {
        assert!(circle_intersects_circle(0.0, 0.0, 3.0, 4.0, 0.0, 3.0));
        assert!(!circle_intersects_circle(0.0, 0.0, 1.0, 10.0, 0.0, 1.0));
    }

    #[test]
    fn test_segment_intersection() {
        let (hit, pt) = segment_intersects_segment(0.0, 0.0, 2.0, 2.0, 0.0, 2.0, 2.0, 0.0);
        assert!(hit);
        let (ix, iy) = pt.expect("intersection exists after hit=true");
        assert!((ix - 1.0).abs() < 1e-5);
        assert!((iy - 1.0).abs() < 1e-5);
    }

    #[test]
    fn test_point_in_polygon() {
        // Square: (0,0), (4,0), (4,4), (0,4)
        let verts = [0.0, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0];
        assert!(point_in_polygon(&verts, 2.0, 2.0));
        assert!(!point_in_polygon(&verts, 5.0, 5.0));
    }

    #[test]
    fn test_polygon_area() {
        // Unit square
        let verts = [0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0];
        let area = polygon_area(&verts);
        assert!((area.abs() - 1.0).abs() < 1e-5);
    }

    #[test]
    fn test_bresenham() {
        let pts = bresenham(0, 0, 3, 0);
        assert_eq!(pts, vec![(0, 0), (1, 0), (2, 0), (3, 0)]);
    }

    #[test]
    fn test_closest_point_on_segment() {
        let (cx, cy) = closest_point_on_segment(1.0, 2.0, 0.0, 0.0, 2.0, 0.0);
        assert!((cx - 1.0).abs() < 1e-5);
        assert!((cy - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_convex_hull() {
        // Square with center point — hull should be the square
        let pts = [0.0, 0.0, 4.0, 0.0, 4.0, 4.0, 0.0, 4.0, 2.0, 2.0];
        let hull = convex_hull(&pts);
        assert_eq!(hull.len() / 2, 4); // 4 vertices
    }

    #[test]
    fn test_line_intersect() {
        let pt = line_intersect(0.0, 0.0, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0);
        assert!(pt.is_some());
        let (x, y) = pt.expect("closest point exists");
        assert!((x - 0.5).abs() < 1e-5);
        assert!((y - 0.5).abs() < 1e-5);
    }

    #[test]
    fn test_circle_intersects_line() {
        let (hit, p1, p2) = circle_intersects_line(0.0, 0.0, 1.0, -2.0, 0.0, 2.0, 0.0);
        assert!(hit);
        assert!(p1.is_some());
        assert!(p2.is_some());
        let (x1, _) = p1.expect("intersection point exists");
        let (x2, _) = p2.expect("intersection point exists");
        assert!((x1.abs() - 1.0).abs() < 1e-5);
        assert!((x2.abs() - 1.0).abs() < 1e-5);
    }
}

// ── mat3 ──────────────────────────────────────────────────────────────────────

mod mat3_tests {
    use lurek2d::math::{Mat3, Vec2};

    // ── Identity ─────────────────────────────────────────────────────────────

    #[test]
    fn identity_diagonal_ones() {
        let m = Mat3::identity();
        assert!((m.m[0][0] - 1.0).abs() < 1e-5);
        assert!((m.m[1][1] - 1.0).abs() < 1e-5);
        assert!((m.m[2][2] - 1.0).abs() < 1e-5);
        assert!((m.m[0][1]).abs() < 1e-5);
        assert!((m.m[1][0]).abs() < 1e-5);
    }

    #[test]
    fn identity_transforms_point_unchanged() {
        let m = Mat3::identity();
        let p = m.transform_point(Vec2::new(3.0, 7.0));
        assert!((p.x - 3.0).abs() < 1e-5);
        assert!((p.y - 7.0).abs() < 1e-5);
    }

    // ── Translation ─────────────────────────────────────────────────────────

    #[test]
    fn from_translation_offsets_point() {
        let m = Mat3::from_translation(Vec2::new(5.0, 3.0));
        let p = m.transform_point(Vec2::new(1.0, 2.0));
        assert!((p.x - 6.0).abs() < 1e-5);
        assert!((p.y - 5.0).abs() < 1e-5);
    }

    // ── Scale ─────────────────────────────────────────────────────────────────

    #[test]
    fn from_scale_scales_point() {
        let m = Mat3::from_scale(Vec2::new(2.0, 3.0));
        let p = m.transform_point(Vec2::new(4.0, 5.0));
        assert!((p.x - 8.0).abs() < 1e-5);
        assert!((p.y - 15.0).abs() < 1e-5);
    }

    // ── Rotation ───────────────────────────────────────────────────────────────

    #[test]
    fn from_rotation_90deg_right_becomes_down() {
        let m = Mat3::from_rotation(std::f32::consts::FRAC_PI_2);
        let p = m.transform_point(Vec2::new(1.0, 0.0));
        assert!((p.x).abs() < 1e-5);
        assert!((p.y - 1.0).abs() < 1e-5);
    }

    // ── Multiplication ───────────────────────────────────────────────────────────

    #[test]
    fn multiply_by_identity_unchanged() {
        let m = Mat3::from_translation(Vec2::new(5.0, 3.0));
        let result = m * Mat3::identity();
        let p = result.transform_point(Vec2::new(1.0, 2.0));
        assert!((p.x - 6.0).abs() < 1e-5);
        assert!((p.y - 5.0).abs() < 1e-5);
    }

    // ── Inverse ────────────────────────────────────────────────────────────────

    #[test]
    fn inverse_of_identity_is_identity() {
        let inv = Mat3::identity().inverse();
        let p = inv.transform_point(Vec2::new(3.0, 4.0));
        assert!((p.x - 3.0).abs() < 1e-5);
        assert!((p.y - 4.0).abs() < 1e-5);
    }

    #[test]
    fn inverse_undoes_translation() {
        let m = Mat3::from_translation(Vec2::new(10.0, 5.0));
        let inv = m.inverse();
        let p = inv.transform_point(Vec2::new(15.0, 8.0));
        assert!((p.x - 5.0).abs() < 1e-5);
        assert!((p.y - 3.0).abs() < 1e-5);
    }
}

// ── mod (lerp, remap) ─────────────────────────────────────────────────────────

mod math_mod_tests {
    use lurek2d::math::*;

    // ── lerp ─────────────────────────────────────────────────────────────

    #[test]
    fn lerp_at_zero_returns_a() {
        assert!((lerp(10.0, 20.0, 0.0) - 10.0).abs() < 1e-5);
    }

    #[test]
    fn lerp_at_one_returns_b() {
        assert!((lerp(10.0, 20.0, 1.0) - 20.0).abs() < 1e-5);
    }

    #[test]
    fn lerp_at_half_returns_midpoint() {
        assert!((lerp(0.0, 100.0, 0.5) - 50.0).abs() < 1e-5);
    }

    #[test]
    fn lerp_negative_values() {
        assert!((lerp(-10.0, 10.0, 0.5) - 0.0).abs() < 1e-5);
    }

    // ── remap ────────────────────────────────────────────────────────────

    #[test]
    fn remap_identity_range() {
        assert!((remap(0.5, 0.0, 1.0, 0.0, 1.0) - 0.5).abs() < 1e-5);
    }

    #[test]
    fn remap_scales_range() {
        // 5 in [0,10] → 0.5 in [0,1]
        assert!((remap(5.0, 0.0, 10.0, 0.0, 1.0) - 0.5).abs() < 1e-5);
    }

    #[test]
    fn remap_inverts_range() {
        // 0 in [0,10] → 100 in [100,0]
        assert!((remap(0.0, 0.0, 10.0, 100.0, 0.0) - 100.0).abs() < 1e-5);
    }

    #[test]
    fn remap_degenerate_input_range_returns_out_min() {
        // When in_min == in_max, t = 0 → returns out_min
        assert!((remap(5.0, 5.0, 5.0, 0.0, 100.0) - 0.0).abs() < 1e-5);
    }
}

// ── polygon ───────────────────────────────────────────────────────────────────

mod polygon_tests {
    use lurek2d::math::Vec2;
    use lurek2d::math::polygon::*;

    // ── Triangulate ─────────────────────────────────────────────────────────

    #[test]
    fn triangulate_triangle_gives_one_result() {
        let pts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(0.0, 1.0),
        ];
        let tris = triangulate(&pts).expect("valid polygon triangulates without error");
        assert_eq!(tris.len(), 1);
    }

    #[test]
    fn triangulate_square_gives_two_triangles() {
        let pts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(1.0, 1.0),
            Vec2::new(0.0, 1.0),
        ];
        let tris = triangulate(&pts).expect("valid polygon triangulates without error");
        assert_eq!(tris.len(), 2);
    }

    #[test]
    fn triangulate_too_few_points_returns_err() {
        let pts = vec![Vec2::new(0.0, 0.0), Vec2::new(1.0, 0.0)];
        assert!(triangulate(&pts).is_err());
    }

    // ── Convexity ────────────────────────────────────────────────────────────

    #[test]
    fn is_convex_square_true() {
        let pts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(1.0, 1.0),
            Vec2::new(0.0, 1.0),
        ];
        assert!(is_convex(&pts));
    }

    #[test]
    fn is_convex_triangle_true() {
        let pts = vec![
            Vec2::new(0.0, 0.0),
            Vec2::new(2.0, 0.0),
            Vec2::new(1.0, 2.0),
        ];
        assert!(is_convex(&pts));
    }

    #[test]
    fn is_convex_less_than_three_false() {
        let pts = vec![Vec2::new(0.0, 0.0), Vec2::new(1.0, 0.0)];
        assert!(!is_convex(&pts));
    }

    // ── polygon_clip (Sutherland-Hodgman) ────────────────────────────────────

    #[test]
    fn polygon_clip_square_full_inside_unchanged() {
        // Unit square, clip plane y >= -1 (plane below everything)
        let sq = [(0.0f32, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];
        let clipped = polygon_clip(&sq, 0.0, 1.0, -1.0);
        assert_eq!(clipped.len(), 4);
    }

    #[test]
    fn polygon_clip_square_fully_outside_empty() {
        // Unit square in [0,1]×[0,1], clip plane y >= 2.0 (no vertex qualifies)
        let sq = [(0.0f32, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];
        let clipped = polygon_clip(&sq, 0.0, 1.0, 2.0);
        assert!(clipped.is_empty());
    }

    #[test]
    fn polygon_clip_square_half_produces_correct_vertex_count() {
        // Unit square, clip plane y >= 0.5 — result is a rectangle with 4 vertices
        let sq = [(0.0f32, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)];
        let clipped = polygon_clip(&sq, 0.0, 1.0, 0.5);
        assert_eq!(clipped.len(), 4);
        for (_, y) in &clipped {
            assert!(*y >= 0.5 - 1e-5, "y={y} should be >= 0.5");
        }
    }

    #[test]
    fn polygon_clip_empty_input_returns_empty() {
        let clipped = polygon_clip(&[], 1.0, 0.0, 0.0);
        assert!(clipped.is_empty());
    }
}

// ── random ────────────────────────────────────────────────────────────────────

mod random_tests {
    use lurek2d::math::RandomGenerator;

    // ── Seeded determinism ──────────────────────────────────────────────────────

    #[test]
    fn same_seed_same_first_value() {
        let mut r1 = RandomGenerator::with_seed(42);
        let mut r2 = RandomGenerator::with_seed(42);
        let v1 = r1.random();
        let v2 = r2.random();
        assert!((v1 - v2).abs() < f64::EPSILON);
    }

    #[test]
    fn get_seed_returns_stored_seed() {
        let r = RandomGenerator::with_seed(1234);
        assert_eq!(r.get_seed(), 1234);
    }

    #[test]
    fn set_seed_resets_sequence() {
        let mut r = RandomGenerator::with_seed(99);
        let first = r.random();
        r.set_seed(99);
        let again = r.random();
        assert!((first - again).abs() < f64::EPSILON);
    }

    // ── Float range ────────────────────────────────────────────────────────────

    #[test]
    fn random_float_in_range_never_below_min() {
        let mut r = RandomGenerator::with_seed(7);
        for _ in 0..1000 {
            let v = r.random_float(0.0, 1.0);
            assert!(v >= 0.0);
        }
    }

    #[test]
    fn random_float_in_range_never_above_max() {
        let mut r = RandomGenerator::with_seed(7);
        for _ in 0..1000 {
            let v = r.random_float(0.0, 1.0);
            assert!(v < 1.0);
        }
    }

    // ── Int range ──────────────────────────────────────────────────────────────

    #[test]
    fn random_int_never_below_min() {
        let mut r = RandomGenerator::with_seed(3);
        for _ in 0..1000 {
            let v = r.random_int(0, 9);
            assert!(v >= 0);
        }
    }

    #[test]
    fn random_int_never_above_max_inclusive() {
        let mut r = RandomGenerator::with_seed(3);
        for _ in 0..1000 {
            let v = r.random_int(0, 9);
            assert!(v <= 9);
        }
    }

    #[test]
    fn random_int_min_equals_max_returns_min() {
        let mut r = RandomGenerator::with_seed(1);
        let v = r.random_int(5, 5);
        assert_eq!(v, 5);
    }
}

// ── rect ──────────────────────────────────────────────────────────────────────

mod rect_tests {
    use lurek2d::math::Rect;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn new_fields_correct() {
        let r = Rect::new(10.0, 20.0, 100.0, 50.0);
        assert!((r.x - 10.0).abs() < 1e-5);
        assert!((r.y - 20.0).abs() < 1e-5);
        assert!((r.width - 100.0).abs() < 1e-5);
        assert!((r.height - 50.0).abs() < 1e-5);
    }

    // ── Geometry ──────────────────────────────────────────────────────────────

    #[test]
    fn center_midpoint_correct() {
        let r = Rect::new(10.0, 20.0, 100.0, 50.0);
        let c = r.center();
        assert!((c.x - 60.0).abs() < 1e-5);
        assert!((c.y - 45.0).abs() < 1e-5);
    }

    #[test]
    fn area_product_correct() {
        let r = Rect::new(0.0, 0.0, 100.0, 50.0);
        assert!((r.area() - 5000.0).abs() < 1e-5);
    }

    #[test]
    fn zero_area_rect_area_zero() {
        let r = Rect::new(5.0, 5.0, 0.0, 0.0);
        assert!((r.area()).abs() < 1e-5);
    }

    // ── Contains ─────────────────────────────────────────────────────────────

    #[test]
    fn contains_inside_true() {
        let r = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(r.contains(50.0, 50.0));
    }

    #[test]
    fn contains_outside_false() {
        let r = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(!r.contains(200.0, 200.0));
    }

    #[test]
    fn contains_on_edge_true() {
        let r = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(r.contains(0.0, 0.0));
        assert!(r.contains(100.0, 100.0));
    }

    // ── Intersects ───────────────────────────────────────────────────────────

    #[test]
    fn intersects_overlapping_true() {
        let a = Rect::new(0.0, 0.0, 10.0, 10.0);
        let b = Rect::new(5.0, 5.0, 10.0, 10.0);
        assert!(a.intersects(&b));
    }

    #[test]
    fn intersects_non_overlapping_false() {
        let a = Rect::new(0.0, 0.0, 10.0, 10.0);
        let b = Rect::new(20.0, 20.0, 10.0, 10.0);
        assert!(!a.intersects(&b));
    }

    #[test]
    fn intersect_overlap_area_correct() {
        let a = Rect::new(0.0, 0.0, 10.0, 10.0);
        let b = Rect::new(5.0, 5.0, 10.0, 10.0);
        let overlap = a.intersect(&b);
        assert!((overlap.x - 5.0).abs() < 1e-5);
        assert!((overlap.y - 5.0).abs() < 1e-5);
        assert!((overlap.width - 5.0).abs() < 1e-5);
        assert!((overlap.height - 5.0).abs() < 1e-5);
    }

    #[test]
    fn intersect_non_overlapping_returns_zero_rect() {
        let a = Rect::new(0.0, 0.0, 5.0, 5.0);
        let b = Rect::new(10.0, 10.0, 5.0, 5.0);
        let overlap = a.intersect(&b);
        assert!((overlap.area()).abs() < 1e-5);
    }
}

// ── spatial_hash ──────────────────────────────────────────────────────────────

mod spatial_hash_tests {
    use lurek2d::math::SpatialHash;

    #[test]
    fn insert_and_query_rect() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 10.0, 10.0, 20.0, 20.0);
        let hits = sh.query_rect(5.0, 5.0, 30.0, 30.0);
        assert!(hits.contains(&"a".to_string()));
    }

    #[test]
    fn query_misses_non_overlapping() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 10.0, 10.0, 20.0, 20.0);
        let hits = sh.query_rect(100.0, 100.0, 10.0, 10.0);
        assert!(hits.is_empty());
    }

    #[test]
    fn remove_then_query_empty() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 10.0, 10.0, 20.0, 20.0);
        sh.remove("a");
        let hits = sh.query_rect(5.0, 5.0, 30.0, 30.0);
        assert!(hits.is_empty());
        assert_eq!(sh.item_count(), 0);
    }

    #[test]
    fn query_circle_filters_by_distance() {
        let mut sh = SpatialHash::new(64.0);
        // Item at corner — just outside the circle
        sh.insert("far".into(), 90.0, 90.0, 10.0, 10.0);
        // Item near centre
        sh.insert("near".into(), 48.0, 48.0, 4.0, 4.0);
        let hits = sh.query_circle(50.0, 50.0, 10.0);
        assert!(hits.contains(&"near".to_string()));
        assert!(!hits.contains(&"far".to_string()));
    }

    #[test]
    fn multiple_items_same_cell() {
        let mut sh = SpatialHash::new(100.0);
        sh.insert("a".into(), 1.0, 1.0, 5.0, 5.0);
        sh.insert("b".into(), 2.0, 2.0, 5.0, 5.0);
        sh.insert("c".into(), 3.0, 3.0, 5.0, 5.0);
        assert_eq!(sh.item_count(), 3);
        let hits = sh.query_rect(0.0, 0.0, 10.0, 10.0);
        assert_eq!(hits.len(), 3);
    }

    #[test]
    fn update_moves_item() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 10.0, 10.0, 5.0, 5.0);
        sh.update("a".into(), 200.0, 200.0, 5.0, 5.0);
        // Old location should miss
        assert!(sh.query_rect(5.0, 5.0, 20.0, 20.0).is_empty());
        // New location should hit
        assert!(sh
            .query_rect(195.0, 195.0, 20.0, 20.0)
            .contains(&"a".to_string()));
    }

    #[test]
    fn query_segment_hits() {
        let mut sh = SpatialHash::new(64.0);
        sh.insert("a".into(), 50.0, 50.0, 10.0, 10.0);
        let hits = sh.query_segment(0.0, 55.0, 100.0, 55.0);
        assert!(hits.contains(&"a".to_string()));
    }
}

// ── spline ────────────────────────────────────────────────────────────────────

mod spline_tests {
    use lurek2d::math::{CatmullRomSpline, HermiteSpline};

    // ── CatmullRomSpline ─────────────────────────────────────────────────────

    #[test]
    fn catmull_rom_endpoints_match_interior_points() {
        // With 4 points, the spline interpolates points[1] at t≈0.33 and points[2] at t≈0.66
        let spline = CatmullRomSpline::new(vec![
            (0.0, 0.0),
            (1.0, 1.0),
            (2.0, 0.0),
            (3.0, 1.0),
        ]);
        // At segment boundaries the spline passes through the control points
        let (x, y) = spline.sample_segment(0, 1.0);
        assert!((x - 1.0).abs() < 1e-3, "x at seg 0 end: {x}");
        assert!((y - 1.0).abs() < 1e-3, "y at seg 0 end: {y}");
    }

    #[test]
    fn catmull_rom_sample_segment_start() {
        let spline = CatmullRomSpline::new(vec![
            (0.0, 0.0),
            (1.0, 2.0),
            (3.0, 1.0),
            (4.0, 3.0),
        ]);
        let (x, y) = spline.sample_segment(1, 0.0);
        assert!((x - 1.0).abs() < 1e-3);
        assert!((y - 2.0).abs() < 1e-3);
    }

    #[test]
    fn catmull_rom_len_and_is_empty() {
        let spline = CatmullRomSpline::new(vec![(0.0, 0.0), (1.0, 1.0)]);
        assert_eq!(spline.len(), 2);
        assert!(!spline.is_empty());

        let empty = CatmullRomSpline::new(vec![]);
        assert!(empty.is_empty());
    }

    #[test]
    fn catmull_rom_single_point_returns_that_point() {
        let spline = CatmullRomSpline::new(vec![(5.0, 7.0)]);
        let (x, y) = spline.sample(0.5);
        assert!((x - 5.0).abs() < 1e-5);
        assert!((y - 7.0).abs() < 1e-5);
    }

    #[test]
    fn catmull_rom_global_sample_boundaries() {
        let spline = CatmullRomSpline::new(vec![
            (0.0, 0.0),
            (1.0, 1.0),
            (2.0, 0.0),
            (3.0, 1.0),
        ]);
        let (x0, _) = spline.sample(0.0);
        let (x1, _) = spline.sample(1.0);
        // t=0 → first segment start, t=1 → last segment end
        assert!(x0 >= -0.5, "start x: {x0}");
        assert!(x1 <= 3.5, "end x: {x1}");
    }

    // ── HermiteSpline ────────────────────────────────────────────────────────

    #[test]
    fn hermite_at_zero_returns_p0() {
        let spline = HermiteSpline::new((0.0, 0.0), (10.0, 10.0), (1.0, 0.0), (1.0, 0.0));
        let (x, y) = spline.sample(0.0);
        assert!((x).abs() < 1e-5);
        assert!((y).abs() < 1e-5);
    }

    #[test]
    fn hermite_at_one_returns_p1() {
        let spline = HermiteSpline::new((0.0, 0.0), (10.0, 5.0), (1.0, 0.0), (1.0, 0.0));
        let (x, y) = spline.sample(1.0);
        assert!((x - 10.0).abs() < 1e-5);
        assert!((y - 5.0).abs() < 1e-5);
    }

    #[test]
    fn hermite_midpoint_with_zero_tangents_is_average() {
        // Zero tangents → linear interpolation
        let spline = HermiteSpline::new((0.0, 0.0), (10.0, 10.0), (0.0, 0.0), (0.0, 0.0));
        let (x, y) = spline.sample(0.5);
        assert!((x - 5.0).abs() < 1e-3);
        assert!((y - 5.0).abs() < 1e-3);
    }
}

// ── transform ─────────────────────────────────────────────────────────────────

mod transform_tests {
    use lurek2d::math::Transform;

    // ── Identity ─────────────────────────────────────────────────────────────

    #[test]
    fn new_is_identity_transform() {
        let t = Transform::new();
        let (x, y) = t.transform_point(3.0, 5.0);
        assert!((x - 3.0).abs() < 1e-5);
        assert!((y - 5.0).abs() < 1e-5);
    }

    #[test]
    fn default_is_identity_transform() {
        let t = Transform::default();
        let (x, y) = t.transform_point(1.0, 2.0);
        assert!((x - 1.0).abs() < 1e-5);
        assert!((y - 2.0).abs() < 1e-5);
    }

    // ── Translate ────────────────────────────────────────────────────────────

    #[test]
    fn translate_offsets_point() {
        let mut t = Transform::new();
        t.translate(10.0, 5.0);
        let (x, y) = t.transform_point(1.0, 2.0);
        assert!((x - 11.0).abs() < 1e-5);
        assert!((y - 7.0).abs() < 1e-5);
    }

    // ── Scale ─────────────────────────────────────────────────────────────────

    #[test]
    fn scale_scales_point() {
        let mut t = Transform::new();
        t.scale(2.0, 3.0);
        let (x, y) = t.transform_point(4.0, 5.0);
        assert!((x - 8.0).abs() < 1e-5);
        assert!((y - 15.0).abs() < 1e-5);
    }

    // ── Rotate ────────────────────────────────────────────────────────────────

    #[test]
    fn rotate_90deg_right_becomes_down() {
        let mut t = Transform::new();
        t.rotate(std::f32::consts::FRAC_PI_2);
        let (x, y) = t.transform_point(1.0, 0.0);
        assert!((x).abs() < 1e-5);
        assert!((y - 1.0).abs() < 1e-5);
    }

    // ── Reset ─────────────────────────────────────────────────────────────────

    #[test]
    fn reset_returns_to_identity() {
        let mut t = Transform::new();
        t.translate(100.0, 100.0);
        t.reset();
        let (x, y) = t.transform_point(1.0, 2.0);
        assert!((x - 1.0).abs() < 1e-5);
        assert!((y - 2.0).abs() < 1e-5);
    }

    // ── Round-trip ────────────────────────────────────────────────────────────

    #[test]
    fn inverse_undoes_translation() {
        let mut t = Transform::new();
        t.translate(7.0, 3.0);
        let (tx, ty) = t.transform_point(2.0, 1.0);
        let (rx, ry) = t.inverse_transform_point(tx, ty);
        assert!((rx - 2.0).abs() < 1e-4);
        assert!((ry - 1.0).abs() < 1e-4);
    }
}

// ── tween ─────────────────────────────────────────────────────────────────────

mod tween_tests {
    use lurek2d::math::Tween;

    #[test]
    fn test_linear_tween() {
        let mut tw = Tween::new(1.0, "linear");
        tw.add_value(0.0, 100.0);
        tw.set_time(0.5);
        let v = tw.get_value(0);
        assert!((v - 50.0).abs() < 1e-3);
    }

    #[test]
    fn test_tween_complete() {
        let mut tw = Tween::new(2.0, "linear");
        tw.add_value(0.0, 10.0);
        assert!(!tw.is_complete());
        tw.update(1.0);
        assert!(!tw.is_complete());
        tw.update(1.5);
        assert!(tw.is_complete());
    }

    #[test]
    fn test_tween_reset() {
        let mut tw = Tween::new(1.0, "linear");
        tw.add_value(0.0, 100.0);
        tw.update(1.0);
        assert!(tw.is_complete());
        tw.reset();
        assert!(!tw.is_complete());
        assert!((tw.get_value(0) - 0.0).abs() < 1e-5);
    }

    #[test]
    fn test_easing_quad() {
        let mut tw = Tween::new(1.0, "inQuad");
        tw.add_value(0.0, 100.0);
        tw.set_time(0.5);
        // ease_in_quad(0.5) = 0.25
        let v = tw.get_value(0);
        assert!((v - 25.0).abs() < 1e-3);
    }

    #[test]
    fn test_multiple_values() {
        let mut tw = Tween::new(1.0, "linear");
        let i0 = tw.add_value(0.0, 100.0);
        let i1 = tw.add_value(50.0, 150.0);
        tw.set_time(0.5);
        assert!((tw.get_value(i0) - 50.0).abs() < 1e-3);
        assert!((tw.get_value(i1) - 100.0).abs() < 1e-3);
    }

    #[test]
    fn test_get_all_values() {
        let mut tw = Tween::new(1.0, "linear");
        tw.add_value(0.0, 10.0);
        tw.add_value(100.0, 200.0);
        tw.set_time(1.0);
        let vals = tw.get_all_values();
        assert_eq!(vals.len(), 2);
        assert!((vals[0] - 10.0).abs() < 1e-3);
        assert!((vals[1] - 200.0).abs() < 1e-3);
    }

    #[test]
    fn test_unknown_easing_fallback() {
        let mut tw = Tween::new(1.0, "nonexistent");
        tw.add_value(0.0, 100.0);
        tw.set_time(0.5);
        // Falls back to linear
        assert!((tw.get_value(0) - 50.0).abs() < 1e-3);
    }
}

// ── vec2 ──────────────────────────────────────────────────────────────────────

mod vec2_tests {
    use lurek2d::math::Vec2;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn new_fields_correct() {
        let v = Vec2::new(3.0, 4.0);
        assert!((v.x - 3.0).abs() < 1e-5);
        assert!((v.y - 4.0).abs() < 1e-5);
    }

    #[test]
    fn zero_constant_both_zero() {
        assert!((Vec2::ZERO.x).abs() < 1e-5);
        assert!((Vec2::ZERO.y).abs() < 1e-5);
    }

    #[test]
    fn splat_components_equal() {
        let v = Vec2::splat(5.0);
        assert!((v.x - 5.0).abs() < 1e-5);
        assert!((v.y - 5.0).abs() < 1e-5);
    }

    // ── Dot product ───────────────────────────────────────────────────────────

    #[test]
    fn dot_perpendicular_is_zero() {
        assert!((Vec2::RIGHT.dot(Vec2::UP)).abs() < 1e-5);
    }

    #[test]
    fn dot_parallel_is_one() {
        assert!((Vec2::RIGHT.dot(Vec2::RIGHT) - 1.0).abs() < 1e-5);
    }

    // ── Length / normalize ────────────────────────────────────────────────────

    #[test]
    fn length_three_four_five() {
        let v = Vec2::new(3.0, 4.0);
        assert!((v.length() - 5.0).abs() < 1e-5);
    }

    #[test]
    fn length_squared_correct() {
        let v = Vec2::new(3.0, 4.0);
        assert!((v.length_squared() - 25.0).abs() < 1e-5);
    }

    #[test]
    fn normalize_gives_unit_length() {
        let v = Vec2::new(3.0, 4.0).normalize();
        assert!((v.length() - 1.0).abs() < 1e-5);
    }

    #[test]
    fn normalize_zero_vector_returns_zero() {
        let v = Vec2::ZERO.normalize();
        assert!((v.x).abs() < 1e-5);
        assert!((v.y).abs() < 1e-5);
    }

    // ── Lerp / distance ───────────────────────────────────────────────────────

    #[test]
    fn lerp_midpoint_is_half() {
        let v = Vec2::ZERO.lerp(Vec2::ONE, 0.5);
        assert!((v.x - 0.5).abs() < 1e-5);
        assert!((v.y - 0.5).abs() < 1e-5);
    }

    #[test]
    fn distance_three_four_five() {
        let d = Vec2::ZERO.distance(Vec2::new(3.0, 4.0));
        assert!((d - 5.0).abs() < 1e-5);
    }

    // ── Arithmetic ────────────────────────────────────────────────────────────

    #[test]
    fn add_components() {
        let r = Vec2::new(1.0, 2.0) + Vec2::new(3.0, 4.0);
        assert!((r.x - 4.0).abs() < 1e-5);
        assert!((r.y - 6.0).abs() < 1e-5);
    }

    #[test]
    fn sub_components() {
        let r = Vec2::new(5.0, 3.0) - Vec2::new(2.0, 1.0);
        assert!((r.x - 3.0).abs() < 1e-5);
        assert!((r.y - 2.0).abs() < 1e-5);
    }

    #[test]
    fn neg_flips_sign() {
        let r = -Vec2::new(1.0, -1.0);
        assert!((r.x - (-1.0)).abs() < 1e-5);
        assert!((r.y - 1.0).abs() < 1e-5);
    }

    #[test]
    fn mul_scalar() {
        let r = Vec2::new(2.0, 3.0) * 4.0;
        assert!((r.x - 8.0).abs() < 1e-5);
        assert!((r.y - 12.0).abs() < 1e-5);
    }

    // ── Perpendicular / cross ─────────────────────────────────────────────────

    #[test]
    fn perpendicular_rotates_ccw() {
        let v = Vec2::new(1.0, 0.0).perpendicular();
        assert!((v.x - 0.0).abs() < 1e-5);
        assert!((v.y - 1.0).abs() < 1e-5);
    }

    #[test]
    fn cross_known_value() {
        let a = Vec2::new(1.0, 0.0);
        let b = Vec2::new(0.0, 1.0);
        assert!((a.cross(b) - 1.0).abs() < 1e-5);
    }
}

// ── vec3 ──────────────────────────────────────────────────────────────────────

mod vec3_tests {
    use lurek2d::math::Vec3;

    // ── Construction ──────────────────────────────────────────────────────────

    #[test]
    fn new_fields_correct() {
        let v = Vec3::new(1.0, 2.0, 3.0);
        assert!((v.x - 1.0).abs() < 1e-5);
        assert!((v.y - 2.0).abs() < 1e-5);
        assert!((v.z - 3.0).abs() < 1e-5);
    }

    #[test]
    fn zero_all_components_zero() {
        let v = Vec3::zero();
        assert!((v.x).abs() < 1e-5);
        assert!((v.y).abs() < 1e-5);
        assert!((v.z).abs() < 1e-5);
    }

    #[test]
    fn one_all_components_one() {
        let v = Vec3::one();
        assert!((v.x - 1.0).abs() < 1e-5);
        assert!((v.y - 1.0).abs() < 1e-5);
        assert!((v.z - 1.0).abs() < 1e-5);
    }

    // ── Dot product ───────────────────────────────────────────────────────────

    #[test]
    fn dot_perpendicular_is_zero() {
        let a = Vec3::new(1.0, 0.0, 0.0);
        let b = Vec3::new(0.0, 1.0, 0.0);
        assert!((a.dot(b)).abs() < 1e-5);
    }

    #[test]
    fn dot_parallel_is_one() {
        let a = Vec3::new(1.0, 0.0, 0.0);
        assert!((a.dot(a) - 1.0).abs() < 1e-5);
    }

    // ── Cross product ─────────────────────────────────────────────────────────

    #[test]
    fn cross_x_cross_y_is_z() {
        let x = Vec3::new(1.0, 0.0, 0.0);
        let y = Vec3::new(0.0, 1.0, 0.0);
        let z = x.cross(y);
        assert!((z.x).abs() < 1e-5);
        assert!((z.y).abs() < 1e-5);
        assert!((z.z - 1.0).abs() < 1e-5);
    }

    #[test]
    fn cross_self_is_zero() {
        let v = Vec3::new(1.0, 2.0, 3.0);
        let c = v.cross(v);
        assert!((c.length()).abs() < 1e-5);
    }

    // ── Length ─────────────────────────────────────────────────────────────────

    #[test]
    fn length_unit_vector() {
        let v = Vec3::new(1.0, 0.0, 0.0);
        assert!((v.length() - 1.0).abs() < 1e-5);
    }

    #[test]
    fn length_3_4_0_is_5() {
        let v = Vec3::new(3.0, 4.0, 0.0);
        assert!((v.length() - 5.0).abs() < 1e-5);
    }

    #[test]
    fn length_squared_avoids_sqrt() {
        let v = Vec3::new(3.0, 4.0, 0.0);
        assert!((v.length_squared() - 25.0).abs() < 1e-5);
    }

    // ── Normalize ─────────────────────────────────────────────────────────────

    #[test]
    fn normalize_unit_length() {
        let v = Vec3::new(3.0, 4.0, 0.0).normalize();
        assert!((v.length() - 1.0).abs() < 1e-5);
    }

    #[test]
    fn normalize_zero_returns_zero() {
        let v = Vec3::zero().normalize();
        assert!((v.length()).abs() < 1e-5);
    }

    // ── Lerp ──────────────────────────────────────────────────────────────────

    #[test]
    fn lerp_at_zero_returns_self() {
        let a = Vec3::new(1.0, 2.0, 3.0);
        let b = Vec3::new(4.0, 5.0, 6.0);
        let r = a.lerp(b, 0.0);
        assert!((r.x - 1.0).abs() < 1e-5);
        assert!((r.y - 2.0).abs() < 1e-5);
    }

    #[test]
    fn lerp_at_one_returns_other() {
        let a = Vec3::zero();
        let b = Vec3::new(10.0, 20.0, 30.0);
        let r = a.lerp(b, 1.0);
        assert!((r.x - 10.0).abs() < 1e-5);
    }

    // ── Distance ──────────────────────────────────────────────────────────────

    #[test]
    fn distance_same_point_is_zero() {
        let v = Vec3::new(5.0, 5.0, 5.0);
        assert!((v.distance(v)).abs() < 1e-5);
    }

    // ── Project ───────────────────────────────────────────────────────────────

    #[test]
    fn project_onto_axis() {
        let v = Vec3::new(3.0, 4.0, 0.0);
        let axis = Vec3::new(1.0, 0.0, 0.0);
        let p = v.project(axis);
        assert!((p.x - 3.0).abs() < 1e-5);
        assert!((p.y).abs() < 1e-5);
    }

    // ── Reflect ───────────────────────────────────────────────────────────────

    #[test]
    fn reflect_horizontal_normal() {
        let v = Vec3::new(1.0, -1.0, 0.0);
        let n = Vec3::new(0.0, 1.0, 0.0);
        let r = v.reflect(n);
        assert!((r.x - 1.0).abs() < 1e-5);
        assert!((r.y - 1.0).abs() < 1e-5);
    }

    // ── Arithmetic operators ──────────────────────────────────────────────────

    #[test]
    fn add_components() {
        let a = Vec3::new(1.0, 2.0, 3.0);
        let b = Vec3::new(4.0, 5.0, 6.0);
        let r = a + b;
        assert!((r.x - 5.0).abs() < 1e-5);
        assert!((r.y - 7.0).abs() < 1e-5);
        assert!((r.z - 9.0).abs() < 1e-5);
    }

    #[test]
    fn neg_flips_signs() {
        let v = Vec3::new(1.0, -2.0, 3.0);
        let n = -v;
        assert!((n.x + 1.0).abs() < 1e-5);
        assert!((n.y - 2.0).abs() < 1e-5);
        assert!((n.z + 3.0).abs() < 1e-5);
    }

    // ── Display ───────────────────────────────────────────────────────────────

    #[test]
    fn display_format() {
        let v = Vec3::new(1.0, 2.0, 3.0);
        let s = format!("{}", v);
        assert!(s.contains("1"));
        assert!(s.contains("2"));
        assert!(s.contains("3"));
    }
}

// ── voronoi ───────────────────────────────────────────────────────────────────

mod voronoi_tests {
    use lurek2d::math::voronoi_from_points;

    #[test]
    fn voronoi_empty_returns_empty() {
        assert!(voronoi_from_points(&[]).is_empty());
    }

    #[test]
    fn voronoi_single_site_has_no_vertices() {
        let cells = voronoi_from_points(&[(0.0, 0.0)]);
        assert_eq!(cells.len(), 1);
        assert!(cells[0].vertices.is_empty());
    }

    #[test]
    fn voronoi_four_sites_has_correct_count() {
        let pts = [(0.0, 0.0), (1.0, 0.0), (0.5, 1.0), (0.5, 0.5)];
        let cells = voronoi_from_points(&pts);
        assert_eq!(cells.len(), 4, "one cell per site");
    }

    #[test]
    fn voronoi_deduplicates_near_coincident_points() {
        // Two points almost on top of each other should produce a single cell.
        let pts = [(0.0, 0.0), (0.0, 0.0_f32 + 1e-7), (1.0, 0.0), (0.5, 1.0)];
        let cells = voronoi_from_points(&pts);
        assert!(cells.len() < pts.len(), "near-duplicate should be merged");
    }
}

// -- sphere ---------------------------------------------------------------

mod sphere_tests {
    use lurek2d::math::sphere::{
        great_circle_distance, great_circle_path, lat_lon_to_unit, ray_sphere_intersect, rot_y,
        unit_to_lat_lon, Mat3x3,
    };
    use lurek2d::math::Vec3;

    fn approx(a: f32, b: f32, eps: f32) -> bool {
        (a - b).abs() < eps
    }

    #[test]
    fn lat_lon_round_trip_origin() {
        let v = lat_lon_to_unit(0.0, 0.0);
        assert!(approx(v.x, 1.0, 1e-5));
        assert!(approx(v.y, 0.0, 1e-5));
        assert!(approx(v.z, 0.0, 1e-5));
        let (lat, lon) = unit_to_lat_lon(v);
        assert!(approx(lat, 0.0, 1e-3));
        assert!(approx(lon, 0.0, 1e-3));
    }

    #[test]
    fn lat_lon_north_pole() {
        let v = lat_lon_to_unit(90.0, 0.0);
        assert!(approx(v.y, 1.0, 1e-5));
        assert!(approx(v.x, 0.0, 1e-5));
        assert!(approx(v.z, 0.0, 1e-5));
    }

    #[test]
    fn great_circle_self_distance_is_zero() {
        let d = great_circle_distance(45.0, -10.0, 45.0, -10.0);
        assert!(d < 1e-5);
    }

    #[test]
    fn great_circle_quarter_turn_is_pi_over_two() {
        // Equator from (0,0) to (0,90) is a quarter great circle = π/2.
        let d = great_circle_distance(0.0, 0.0, 0.0, 90.0);
        assert!(approx(d, std::f32::consts::FRAC_PI_2, 1e-4));
    }

    #[test]
    fn great_circle_path_endpoints_match() {
        let pts = great_circle_path(45.0, -45.0, 30.0, 60.0, 5);
        assert_eq!(pts.len(), 5);
        assert!(approx(pts[0].0, 45.0, 1e-3));
        assert!(approx(pts[0].1, -45.0, 1e-3));
        assert!(approx(pts[4].0, 30.0, 1e-3));
        assert!(approx(pts[4].1, 60.0, 1e-3));
    }

    #[test]
    fn ray_sphere_hit_from_outside() {
        // Ray from (5, 0, 0) toward -X hits unit sphere at t = 4.
        let t = ray_sphere_intersect(Vec3::new(5.0, 0.0, 0.0), Vec3::new(-1.0, 0.0, 0.0), 1.0);
        assert!(t.is_some());
        assert!(approx(t.unwrap(), 4.0, 1e-4));
    }

    #[test]
    fn ray_sphere_miss() {
        let t = ray_sphere_intersect(Vec3::new(0.0, 5.0, 0.0), Vec3::new(0.0, 1.0, 0.0), 1.0);
        assert!(t.is_none());
    }

    #[test]
    fn rot_y_90_maps_x_to_minus_z() {
        let m = rot_y(90.0);
        let v = m.mul_vec(Vec3::new(1.0, 0.0, 0.0));
        assert!(approx(v.x, 0.0, 1e-5));
        assert!(approx(v.z, -1.0, 1e-5));
    }

    #[test]
    fn mat3x3_identity_round_trip() {
        let i = Mat3x3::identity();
        let v = i.mul_vec(Vec3::new(2.0, 3.0, 4.0));
        assert!(approx(v.x, 2.0, 1e-6));
        assert!(approx(v.y, 3.0, 1e-6));
        assert!(approx(v.z, 4.0, 1e-6));
    }
}
