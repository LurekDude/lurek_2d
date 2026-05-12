//! INTERNAL ONLY: Rust-only tests for math helpers that are not directly asserted through the
//! Lua-facing API surface.
//!
//! Public `lurek.math.*` behaviour is covered by `tests/lua/unit/test_math_unit.lua`.
//! The remaining Rust tests keep low-level color/matrix/geometry helper
//! invariants that are easier to validate directly in Rust.

mod color_tests {
    use lurek2d::math::{gamma_to_linear, linear_to_gamma, Color};

    #[test]
    fn white_constant_all_channels_one() {
        let color = Color::WHITE;
        assert!((color.r - 1.0).abs() < 1e-5);
        assert!((color.g - 1.0).abs() < 1e-5);
        assert!((color.b - 1.0).abs() < 1e-5);
        assert!((color.a - 1.0).abs() < 1e-5);
    }

    #[test]
    fn black_constant_rgb_zero_alpha_one() {
        let color = Color::BLACK;
        assert!((color.r).abs() < 1e-5);
        assert!((color.g).abs() < 1e-5);
        assert!((color.b).abs() < 1e-5);
        assert!((color.a - 1.0).abs() < 1e-5);
    }

    #[test]
    fn from_u8_red_correct() {
        let color = Color::from_u8(255, 0, 0, 255);
        assert!((color.r - 1.0).abs() < 1e-5);
        assert!((color.g).abs() < 1e-5);
        assert!((color.b).abs() < 1e-5);
        assert!((color.a - 1.0).abs() < 1e-5);
    }

    #[test]
    fn from_u8_zero_gives_transparent_black() {
        let color = Color::from_u8(0, 0, 0, 0);
        assert!((color.r).abs() < 1e-5);
        assert!((color.a).abs() < 1e-5);
    }

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
        assert_eq!(Color::RED.to_rgb_u32(), 0x00FF_0000u32);
    }

    #[test]
    fn to_rgb_u32_blue_expected_value() {
        assert_eq!(Color::BLUE.to_rgb_u32(), 0x0000_00FFu32);
    }

    #[test]
    fn default_is_white() {
        let color = Color::default();
        assert!((color.r - 1.0).abs() < 1e-5);
        assert!((color.a - 1.0).abs() < 1e-5);
    }

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

mod mat3_tests {
    use lurek2d::math::{Mat3, Vec2};

    #[test]
    fn identity_diagonal_ones() {
        let matrix = Mat3::identity();
        assert!((matrix.m[0][0] - 1.0).abs() < 1e-5);
        assert!((matrix.m[1][1] - 1.0).abs() < 1e-5);
        assert!((matrix.m[2][2] - 1.0).abs() < 1e-5);
        assert!((matrix.m[0][1]).abs() < 1e-5);
        assert!((matrix.m[1][0]).abs() < 1e-5);
    }

    #[test]
    fn identity_transforms_point_unchanged() {
        let matrix = Mat3::identity();
        let point = matrix.transform_point(Vec2::new(3.0, 7.0));
        assert!((point.x - 3.0).abs() < 1e-5);
        assert!((point.y - 7.0).abs() < 1e-5);
    }

    #[test]
    fn from_translation_offsets_point() {
        let matrix = Mat3::from_translation(Vec2::new(5.0, 3.0));
        let point = matrix.transform_point(Vec2::new(1.0, 2.0));
        assert!((point.x - 6.0).abs() < 1e-5);
        assert!((point.y - 5.0).abs() < 1e-5);
    }

    #[test]
    fn from_scale_scales_point() {
        let matrix = Mat3::from_scale(Vec2::new(2.0, 3.0));
        let point = matrix.transform_point(Vec2::new(4.0, 5.0));
        assert!((point.x - 8.0).abs() < 1e-5);
        assert!((point.y - 15.0).abs() < 1e-5);
    }

    #[test]
    fn from_rotation_90deg_right_becomes_down() {
        let matrix = Mat3::from_rotation(std::f32::consts::FRAC_PI_2);
        let point = matrix.transform_point(Vec2::new(1.0, 0.0));
        assert!((point.x).abs() < 1e-5);
        assert!((point.y - 1.0).abs() < 1e-5);
    }

    #[test]
    fn multiply_by_identity_unchanged() {
        let matrix = Mat3::from_translation(Vec2::new(5.0, 3.0));
        let result = matrix * Mat3::identity();
        let point = result.transform_point(Vec2::new(1.0, 2.0));
        assert!((point.x - 6.0).abs() < 1e-5);
        assert!((point.y - 5.0).abs() < 1e-5);
    }

    #[test]
    fn inverse_of_identity_is_identity() {
        let inverse = Mat3::identity().inverse();
        let point = inverse.transform_point(Vec2::new(3.0, 4.0));
        assert!((point.x - 3.0).abs() < 1e-5);
        assert!((point.y - 4.0).abs() < 1e-5);
    }

    #[test]
    fn inverse_undoes_translation() {
        let matrix = Mat3::from_translation(Vec2::new(10.0, 5.0));
        let inverse = matrix.inverse();
        let point = inverse.transform_point(Vec2::new(15.0, 8.0));
        assert!((point.x - 5.0).abs() < 1e-5);
        assert!((point.y - 3.0).abs() < 1e-5);
    }
}

mod rect_tests {
    use lurek2d::math::Rect;

    #[test]
    fn new_fields_correct() {
        let rect = Rect::new(10.0, 20.0, 100.0, 50.0);
        assert!((rect.x - 10.0).abs() < 1e-5);
        assert!((rect.y - 20.0).abs() < 1e-5);
        assert!((rect.width - 100.0).abs() < 1e-5);
        assert!((rect.height - 50.0).abs() < 1e-5);
    }

    #[test]
    fn center_midpoint_correct() {
        let rect = Rect::new(10.0, 20.0, 100.0, 50.0);
        let center = rect.center();
        assert!((center.x - 60.0).abs() < 1e-5);
        assert!((center.y - 45.0).abs() < 1e-5);
    }

    #[test]
    fn area_product_correct() {
        let rect = Rect::new(0.0, 0.0, 100.0, 50.0);
        assert!((rect.area() - 5000.0).abs() < 1e-5);
    }

    #[test]
    fn zero_area_rect_area_zero() {
        let rect = Rect::new(5.0, 5.0, 0.0, 0.0);
        assert!((rect.area()).abs() < 1e-5);
    }

    #[test]
    fn contains_inside_true() {
        let rect = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(rect.contains(50.0, 50.0));
    }

    #[test]
    fn contains_outside_false() {
        let rect = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(!rect.contains(200.0, 200.0));
    }

    #[test]
    fn contains_on_edge_true() {
        let rect = Rect::new(0.0, 0.0, 100.0, 100.0);
        assert!(rect.contains(0.0, 0.0));
        assert!(rect.contains(100.0, 100.0));
    }

    #[test]
    fn intersects_overlapping_true() {
        let left = Rect::new(0.0, 0.0, 10.0, 10.0);
        let right = Rect::new(5.0, 5.0, 10.0, 10.0);
        assert!(left.intersects(&right));
    }

    #[test]
    fn intersects_non_overlapping_false() {
        let left = Rect::new(0.0, 0.0, 10.0, 10.0);
        let right = Rect::new(20.0, 20.0, 10.0, 10.0);
        assert!(!left.intersects(&right));
    }

    #[test]
    fn intersect_overlap_area_correct() {
        let left = Rect::new(0.0, 0.0, 10.0, 10.0);
        let right = Rect::new(5.0, 5.0, 10.0, 10.0);
        let overlap = left.intersect(&right);
        assert!((overlap.x - 5.0).abs() < 1e-5);
        assert!((overlap.y - 5.0).abs() < 1e-5);
        assert!((overlap.width - 5.0).abs() < 1e-5);
        assert!((overlap.height - 5.0).abs() < 1e-5);
    }

    #[test]
    fn intersect_non_overlapping_returns_zero_rect() {
        let left = Rect::new(0.0, 0.0, 5.0, 5.0);
        let right = Rect::new(10.0, 10.0, 5.0, 5.0);
        let overlap = left.intersect(&right);
        assert!((overlap.area()).abs() < 1e-5);
    }
}

mod aabb_tree_query_tests {
    use lurek2d::math::AabbTree;

    #[test]
    fn query_circle_finds_overlapping_entry() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 4.0, 4.0);
        let hits = tree.query_circle(2.0, 2.0, 3.0);
        assert!(hits.contains(&1));
    }

    #[test]
    fn query_circle_misses_distant_entry() {
        let mut tree = AabbTree::new();
        tree.insert(1, 10.0, 10.0, 20.0, 20.0);
        let hits = tree.query_circle(0.0, 0.0, 3.0);
        assert!(!hits.contains(&1));
    }

    #[test]
    fn query_segment_finds_crossed_entry() {
        let mut tree = AabbTree::new();
        tree.insert(1, 0.0, 0.0, 4.0, 4.0);
        let hits = tree.query_segment(2.0, -1.0, 2.0, 5.0);
        assert!(hits.contains(&1));
    }

    #[test]
    fn query_segment_misses_parallel_segment() {
        let mut tree = AabbTree::new();
        tree.insert(1, 10.0, 10.0, 20.0, 20.0);
        let hits = tree.query_segment(0.0, 0.0, 5.0, 5.0);
        assert!(!hits.contains(&1));
    }
}

mod sphere_tests {
    use lurek2d::math::sphere::{
        great_circle_distance, great_circle_path, lat_lon_to_unit, ray_sphere_intersect, rot_y,
        unit_to_lat_lon, Mat3x3,
    };
    use lurek2d::math::Vec3;

    fn approx(left: f32, right: f32, epsilon: f32) -> bool {
        (left - right).abs() < epsilon
    }

    #[test]
    fn lat_lon_round_trip_origin() {
        let vector = lat_lon_to_unit(0.0, 0.0);
        assert!(approx(vector.x, 1.0, 1e-5));
        assert!(approx(vector.y, 0.0, 1e-5));
        assert!(approx(vector.z, 0.0, 1e-5));
        let (lat, lon) = unit_to_lat_lon(vector);
        assert!(approx(lat, 0.0, 1e-3));
        assert!(approx(lon, 0.0, 1e-3));
    }

    #[test]
    fn lat_lon_north_pole() {
        let vector = lat_lon_to_unit(90.0, 0.0);
        assert!(approx(vector.y, 1.0, 1e-5));
        assert!(approx(vector.x, 0.0, 1e-5));
        assert!(approx(vector.z, 0.0, 1e-5));
    }

    #[test]
    fn great_circle_self_distance_is_zero() {
        let distance = great_circle_distance(45.0, -10.0, 45.0, -10.0);
        assert!(distance < 1e-5);
    }

    #[test]
    fn great_circle_quarter_turn_is_pi_over_two() {
        let distance = great_circle_distance(0.0, 0.0, 0.0, 90.0);
        assert!(approx(distance, std::f32::consts::FRAC_PI_2, 1e-4));
    }

    #[test]
    fn great_circle_path_endpoints_match() {
        let points = great_circle_path(45.0, -45.0, 30.0, 60.0, 5);
        assert_eq!(points.len(), 5);
        assert!(approx(points[0].0, 45.0, 1e-3));
        assert!(approx(points[0].1, -45.0, 1e-3));
        assert!(approx(points[4].0, 30.0, 1e-3));
        assert!(approx(points[4].1, 60.0, 1e-3));
    }

    #[test]
    fn ray_sphere_hit_from_outside() {
        let hit = ray_sphere_intersect(Vec3::new(5.0, 0.0, 0.0), Vec3::new(-1.0, 0.0, 0.0), 1.0);
        assert!(hit.is_some());
        assert!(approx(hit.unwrap(), 4.0, 1e-4));
    }

    #[test]
    fn ray_sphere_miss() {
        let hit = ray_sphere_intersect(Vec3::new(0.0, 5.0, 0.0), Vec3::new(0.0, 1.0, 0.0), 1.0);
        assert!(hit.is_none());
    }

    #[test]
    fn rot_y_90_maps_x_to_minus_z() {
        let matrix = rot_y(90.0);
        let vector = matrix.mul_vec(Vec3::new(1.0, 0.0, 0.0));
        assert!(approx(vector.x, 0.0, 1e-5));
        assert!(approx(vector.z, -1.0, 1e-5));
    }

    #[test]
    fn mat3x3_identity_round_trip() {
        let matrix = Mat3x3::identity();
        let vector = matrix.mul_vec(Vec3::new(2.0, 3.0, 4.0));
        assert!(approx(vector.x, 2.0, 1e-6));
        assert!(approx(vector.y, 3.0, 1e-6));
        assert!(approx(vector.z, 4.0, 1e-6));
    }
}

mod noise_edge_case_tests {
    use lurek2d::math::{MapGenOptions, NoiseGenerator};

    #[test]
    fn generate_map_zero_octaves_returns_zeros() {
        let ng = NoiseGenerator::new(123);
        let opts = MapGenOptions {
            octaves: 0,
            ..MapGenOptions::default()
        };
        let map = ng.generate_map(8, 8, &opts);
        assert_eq!(map.len(), 64);
        assert!(map.iter().all(|v| v.abs() < 1e-9));
    }

    #[test]
    fn generate_map_negative_persistence_is_stable() {
        let ng = NoiseGenerator::new(123);
        let opts = MapGenOptions {
            persistence: -0.75,
            ..MapGenOptions::default()
        };
        let map = ng.generate_map(4, 4, &opts);
        assert_eq!(map.len(), 16);
        assert!(map.iter().all(|v| v.is_finite()));
    }
}

mod geometry_collinear_tests {
    use lurek2d::math::geometry;

    #[test]
    fn convex_hull_all_collinear_returns_endpoints() {
        let points = vec![0.0, 0.0, 1.0, 0.0, 2.0, 0.0, 3.0, 0.0];
        let hull = geometry::convex_hull(&points);
        assert_eq!(hull.len(), 4);
        assert_eq!(hull[0], 0.0);
        assert_eq!(hull[1], 0.0);
        assert_eq!(hull[2], 3.0);
        assert_eq!(hull[3], 0.0);
    }

    #[test]
    fn delaunay_collinear_input_returns_empty() {
        let points = vec![(0.0, 0.0), (1.0, 0.0), (2.0, 0.0), (3.0, 0.0)];
        let tris = geometry::delaunay_triangulate(&points);
        assert!(tris.is_empty());
    }
}

mod rect_packer_tests {
    use lurek2d::math::RectPacker;

    #[test]
    fn shelf_packer_places_rectangles_and_reports_occupancy() {
        let mut packer = RectPacker::new(32, 32, 1);
        let a = packer.pack(8, 8, Some("a".to_string()));
        let b = packer.pack(8, 8, Some("b".to_string()));
        assert!(a.is_some());
        assert!(b.is_some());
        assert!(packer.occupancy() > 0.0);
    }
}

mod noise_api_dedup_tests {
    use lurek2d::math::{noise_functions, NoiseGenerator};

    fn approx_eq(a: f32, b: f32, eps: f32) -> bool {
        (a - b).abs() <= eps
    }

    #[test]
    fn free_perlin2d_matches_noise_generator_path() {
        let seed = 1337u32;
        let (x, y) = (1.25f32, -0.75f32);
        let legacy = noise_functions::perlin2d(x, y, seed);
        let direct = NoiseGenerator::new(seed as u64).perlin_2d(x as f64, y as f64) as f32;
        assert!(approx_eq(legacy, direct, 1e-6));
    }

    #[test]
    fn free_simplex2d_matches_noise_generator_path() {
        let seed = 7u32;
        let (x, y) = (-3.5f32, 2.0f32);
        let legacy = noise_functions::simplex2d(x, y, seed);
        let direct = NoiseGenerator::new(seed as u64).simplex_2d(x as f64, y as f64) as f32;
        assert!(approx_eq(legacy, direct, 1e-6));
    }
}
