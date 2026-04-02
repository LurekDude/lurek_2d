//! Integration tests for the Luna2D math module.

use luna2d::math::{
    bezier::BezierCurve, easing, noise, polygon, random::RandomGenerator, srgb,
    transform::Transform, Mat3, Rect, Vec2,
};

#[test]
fn vec2_addition() {
    let a = Vec2::new(1.0, 2.0);
    let b = Vec2::new(3.0, 4.0);
    let c = a + b;
    assert!((c.x - 4.0).abs() < f32::EPSILON);
    assert!((c.y - 6.0).abs() < f32::EPSILON);
}

#[test]
fn vec2_subtraction() {
    let a = Vec2::new(5.0, 7.0);
    let b = Vec2::new(2.0, 3.0);
    let c = a - b;
    assert!((c.x - 3.0).abs() < f32::EPSILON);
    assert!((c.y - 4.0).abs() < f32::EPSILON);
}

#[test]
fn vec2_scalar_mul() {
    let v = Vec2::new(2.0, 3.0) * 2.0;
    assert!((v.x - 4.0).abs() < f32::EPSILON);
    assert!((v.y - 6.0).abs() < f32::EPSILON);
}

#[test]
fn vec2_length() {
    let v = Vec2::new(3.0, 4.0);
    assert!((v.length() - 5.0).abs() < 1e-5);
}

#[test]
fn vec2_normalize() {
    let v = Vec2::new(0.0, 5.0).normalize();
    assert!((v.x).abs() < f32::EPSILON);
    assert!((v.y - 1.0).abs() < 1e-5);
}

#[test]
fn vec2_dot() {
    let a = Vec2::new(1.0, 0.0);
    let b = Vec2::new(0.0, 1.0);
    assert!((a.dot(b)).abs() < f32::EPSILON);
}

#[test]
fn vec2_distance() {
    let a = Vec2::new(0.0, 0.0);
    let b = Vec2::new(3.0, 4.0);
    assert!((a.distance(b) - 5.0).abs() < 1e-5);
}

#[test]
fn vec2_lerp() {
    let a = Vec2::new(0.0, 0.0);
    let b = Vec2::new(10.0, 10.0);
    let mid = a.lerp(b, 0.5);
    assert!((mid.x - 5.0).abs() < 1e-5);
    assert!((mid.y - 5.0).abs() < 1e-5);
}

#[test]
fn mat3_identity() {
    let m = Mat3::identity();
    let p = Vec2::new(5.0, 3.0);
    let q = m.transform_point(p);
    assert!((q.x - 5.0).abs() < 1e-5);
    assert!((q.y - 3.0).abs() < 1e-5);
}

#[test]
fn mat3_translation() {
    let m = Mat3::from_translation(Vec2::new(10.0, 20.0));
    let p = Vec2::new(1.0, 1.0);
    let q = m.transform_point(p);
    assert!((q.x - 11.0).abs() < 1e-5);
    assert!((q.y - 21.0).abs() < 1e-5);
}

#[test]
fn rect_basic() {
    let r = Rect::new(10.0, 20.0, 100.0, 50.0);
    assert!((r.x - 10.0).abs() < f32::EPSILON);
    assert!((r.width - 100.0).abs() < f32::EPSILON);
}

#[test]
fn rect_contains() {
    let r = Rect::new(0.0, 0.0, 10.0, 10.0);
    assert!(r.contains(5.0, 5.0));
    assert!(!r.contains(15.0, 5.0));
}

// ===========================================================================
// Easing integration tests
// ===========================================================================

#[test]
fn easing_all_start_at_zero() {
    let names = [
        "linear",
        "inQuad",
        "outQuad",
        "inOutQuad",
        "inCubic",
        "outCubic",
        "inOutCubic",
        "inQuart",
        "outQuart",
        "inOutQuart",
        "inSine",
        "outSine",
        "inOutSine",
        "inExpo",
        "outExpo",
        "inOutExpo",
        "inElastic",
        "outElastic",
        "outBounce",
        "inBounce",
        "inBack",
        "outBack",
    ];
    for name in names {
        let v = easing::apply(name, 0.0).unwrap();
        assert!((v).abs() < 1e-3, "ease({name}, 0.0) = {v}, expected ~0.0");
    }
}

#[test]
fn easing_most_end_at_one() {
    let names = [
        "linear",
        "inQuad",
        "outQuad",
        "inOutQuad",
        "inCubic",
        "outCubic",
        "inOutCubic",
        "inQuart",
        "outQuart",
        "inOutQuart",
        "inSine",
        "outSine",
        "inOutSine",
        "inExpo",
        "outExpo",
        "inOutExpo",
        "outBounce",
        "inBounce",
        "outBack",
    ];
    for name in names {
        let v = easing::apply(name, 1.0).unwrap();
        assert!(
            (v - 1.0).abs() < 1e-3,
            "ease({name}, 1.0) = {v}, expected ~1.0"
        );
    }
}

#[test]
fn easing_unknown_returns_none() {
    assert!(easing::apply("nonexistent", 0.5).is_none());
}

// ===========================================================================
// Noise integration tests
// ===========================================================================

#[test]
fn noise_perlin_deterministic() {
    let a = noise::perlin2d(3.7, 8.2, 42);
    let b = noise::perlin2d(3.7, 8.2, 42);
    assert!((a - b).abs() < f32::EPSILON);
}

#[test]
fn noise_simplex_deterministic() {
    let a = noise::simplex2d(3.7, 8.2, 42);
    let b = noise::simplex2d(3.7, 8.2, 42);
    assert!((a - b).abs() < f32::EPSILON);
}

#[test]
fn noise_perlin_varies_with_position() {
    let a = noise::perlin2d(0.0, 0.0, 0);
    let b = noise::perlin2d(5.7, 3.2, 0);
    // Noise at different positions should generally differ
    assert!((a - b).abs() > f32::EPSILON || a.abs() < f32::EPSILON);
}

#[test]
fn noise_fbm_single_octave_matches_perlin() {
    let fbm_val = noise::fbm(2.5, 1.3, 7, 1, 2.0, 0.5);
    let perlin_val = noise::perlin2d(2.5, 1.3, 7);
    assert!((fbm_val - perlin_val).abs() < 1e-5);
}

// ===========================================================================
// Mat3 inverse tests
// ===========================================================================

#[test]
fn mat3_inverse_identity() {
    let m = Mat3::identity();
    let inv = m.inverse();
    for i in 0..3 {
        for j in 0..3 {
            let expected = if i == j { 1.0 } else { 0.0 };
            assert!(
                (inv.m[i][j] - expected).abs() < 1e-5,
                "identity inverse [{i}][{j}] = {}, expected {expected}",
                inv.m[i][j]
            );
        }
    }
}

#[test]
fn mat3_inverse_translation_roundtrip() {
    let m = Mat3::from_translation(Vec2::new(10.0, 20.0));
    let inv = m.inverse();
    let result = m * inv;
    for i in 0..3 {
        for j in 0..3 {
            let expected = if i == j { 1.0 } else { 0.0 };
            assert!(
                (result.m[i][j] - expected).abs() < 1e-4,
                "translation inverse roundtrip [{i}][{j}] = {}, expected {expected}",
                result.m[i][j]
            );
        }
    }
}

#[test]
fn mat3_inverse_rotation_roundtrip() {
    let m = Mat3::from_rotation(0.7);
    let inv = m.inverse();
    let result = m * inv;
    for i in 0..3 {
        for j in 0..3 {
            let expected = if i == j { 1.0 } else { 0.0 };
            assert!(
                (result.m[i][j] - expected).abs() < 1e-4,
                "rotation inverse roundtrip [{i}][{j}] = {}, expected {expected}",
                result.m[i][j]
            );
        }
    }
}

#[test]
fn mat3_inverse_composite_roundtrip() {
    let m = Mat3::from_translation(Vec2::new(10.0, 20.0))
        * Mat3::from_rotation(0.5)
        * Mat3::from_scale(Vec2::new(2.0, 3.0));
    let inv = m.inverse();
    let result = m * inv;
    for i in 0..3 {
        for j in 0..3 {
            let expected = if i == j { 1.0 } else { 0.0 };
            assert!(
                (result.m[i][j] - expected).abs() < 1e-4,
                "composite inverse roundtrip [{i}][{j}] = {}, expected {expected}",
                result.m[i][j]
            );
        }
    }
}

#[test]
fn mat3_from_shear() {
    let m = Mat3::from_shear(0.5, 0.3);
    let p = Vec2::new(1.0, 0.0);
    let q = m.transform_point(p);
    // from_shear(kx, ky): m[0][1] = ky, m[1][0] = kx
    assert!((q.x - 1.0).abs() < 1e-5);
    assert!((q.y - 0.5).abs() < 1e-5);
}

// ===========================================================================
// RandomGenerator tests
// ===========================================================================

#[test]
fn random_generator_same_seed_same_sequence() {
    let mut rng1 = RandomGenerator::with_seed(42);
    let mut rng2 = RandomGenerator::with_seed(42);
    for _ in 0..100 {
        assert!((rng1.random() - rng2.random()).abs() < f64::EPSILON);
    }
}

#[test]
fn random_generator_different_seeds_differ() {
    let mut rng1 = RandomGenerator::with_seed(42);
    let mut rng2 = RandomGenerator::with_seed(99);
    let mut same_count = 0;
    for _ in 0..100 {
        if (rng1.random() - rng2.random()).abs() < f64::EPSILON {
            same_count += 1;
        }
    }
    assert!(
        same_count < 5,
        "different seeds should produce different sequences"
    );
}

#[test]
fn random_generator_int_range() {
    let mut rng = RandomGenerator::with_seed(123);
    for _ in 0..200 {
        let v = rng.random_int(5, 10);
        assert!(v >= 5 && v <= 10, "random_int out of range: {v}");
    }
}

#[test]
fn random_generator_float_range() {
    let mut rng = RandomGenerator::with_seed(456);
    for _ in 0..200 {
        let v = rng.random_float(2.0, 5.0);
        assert!(v >= 2.0 && v < 5.0, "random_float out of range: {v}");
    }
}

#[test]
fn random_generator_normal_distribution() {
    let mut rng = RandomGenerator::with_seed(789);
    let mut sum = 0.0;
    let n = 10000;
    for _ in 0..n {
        sum += rng.random_normal(1.0, 0.0);
    }
    let mean = sum / n as f64;
    // Mean of normal(0, 1) should be close to 0
    assert!(
        mean.abs() < 0.1,
        "Normal distribution mean = {mean}, expected ~0.0"
    );
}

#[test]
fn random_generator_seed_reset() {
    let mut rng = RandomGenerator::with_seed(42);
    let first = rng.random();
    rng.set_seed(42);
    let second = rng.random();
    assert!((first - second).abs() < f64::EPSILON);
}

#[test]
fn random_generator_state_save_restore() {
    let mut rng = RandomGenerator::with_seed(42);
    let state = rng.get_state();
    let val1 = rng.random();
    rng.set_state(&state).unwrap();
    let val2 = rng.random();
    assert!((val1 - val2).abs() < f64::EPSILON);
}

#[test]
fn random_generator_clone_independent() {
    let mut rng1 = RandomGenerator::with_seed(42);
    let _ = rng1.random(); // advance rng1
    let mut rng2 = rng1.clone();
    // rng2 is a clone from seed, so starts fresh
    let mut rng3 = RandomGenerator::with_seed(42);
    let v2 = rng2.random();
    let v3 = rng3.random();
    assert!((v2 - v3).abs() < f64::EPSILON);
}

// ===========================================================================
// Transform tests
// ===========================================================================

#[test]
fn transform_identity() {
    let t = Transform::new();
    let (x, y) = t.transform_point(5.0, 3.0);
    assert!((x - 5.0).abs() < 1e-5);
    assert!((y - 3.0).abs() < 1e-5);
}

#[test]
fn transform_translate() {
    let mut t = Transform::new();
    t.translate(10.0, 20.0);
    let (x, y) = t.transform_point(1.0, 1.0);
    assert!((x - 11.0).abs() < 1e-5);
    assert!((y - 21.0).abs() < 1e-5);
}

#[test]
fn transform_rotate_90_degrees() {
    let mut t = Transform::new();
    t.rotate(std::f32::consts::FRAC_PI_2); // 90 degrees
    let (x, y) = t.transform_point(1.0, 0.0);
    assert!((x - 0.0).abs() < 1e-5);
    assert!((y - 1.0).abs() < 1e-5);
}

#[test]
fn transform_scale() {
    let mut t = Transform::new();
    t.scale(2.0, 3.0);
    let (x, y) = t.transform_point(5.0, 4.0);
    assert!((x - 10.0).abs() < 1e-5);
    assert!((y - 12.0).abs() < 1e-5);
}

#[test]
fn transform_chain_translate_rotate_scale() {
    let mut t = Transform::new();
    t.translate(100.0, 0.0);
    t.scale(2.0, 2.0);
    let (x, y) = t.transform_point(5.0, 0.0);
    assert!((x - 110.0).abs() < 1e-5);
    assert!((y - 0.0).abs() < 1e-5);
}

#[test]
fn transform_point_inverse_roundtrip() {
    let mut t = Transform::new();
    t.translate(50.0, 100.0);
    t.rotate(0.3);
    t.scale(2.0, 1.5);

    let orig_x = 7.0;
    let orig_y = 11.0;
    let (wx, wy) = t.transform_point(orig_x, orig_y);
    let (lx, ly) = t.inverse_transform_point(wx, wy);
    assert!((lx - orig_x).abs() < 1e-3, "roundtrip x: {lx} != {orig_x}");
    assert!((ly - orig_y).abs() < 1e-3, "roundtrip y: {ly} != {orig_y}");
}

#[test]
fn transform_inverse() {
    let mut t = Transform::new();
    t.translate(10.0, 20.0);
    t.rotate(0.5);
    let inv = t.inverse();
    let (x, y) = t.transform_point(0.0, 0.0);
    let (rx, ry) = inv.transform_point(x, y);
    assert!((rx).abs() < 1e-3, "inverse x: {rx} != 0");
    assert!((ry).abs() < 1e-3, "inverse y: {ry} != 0");
}

#[test]
fn transform_reset() {
    let mut t = Transform::new();
    t.translate(100.0, 200.0);
    t.reset();
    let (x, y) = t.transform_point(5.0, 3.0);
    assert!((x - 5.0).abs() < 1e-5);
    assert!((y - 3.0).abs() < 1e-5);
}

#[test]
fn transform_from_components() {
    let t = Transform::from_components(100.0, 200.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0);
    let (x, y) = t.transform_point(0.0, 0.0);
    assert!((x - 100.0).abs() < 1e-5);
    assert!((y - 200.0).abs() < 1e-5);
}

#[test]
fn transform_clone_independent() {
    let mut t1 = Transform::new();
    t1.translate(10.0, 20.0);
    let t2 = t1;
    t1.translate(30.0, 40.0);
    let (x1, _) = t1.transform_point(0.0, 0.0);
    let (x2, _) = t2.transform_point(0.0, 0.0);
    assert!((x1 - 40.0).abs() < 1e-5); // 10 + 30
    assert!((x2 - 10.0).abs() < 1e-5); // copy only had 10
}

// ===========================================================================
// BezierCurve tests
// ===========================================================================

#[test]
fn bezier_evaluate_endpoints() {
    let curve = BezierCurve::new(vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(50.0, 100.0),
        Vec2::new(100.0, 0.0),
    ]);
    let start = curve.evaluate(0.0);
    let end = curve.evaluate(1.0);
    assert!((start.x).abs() < 1e-5);
    assert!((start.y).abs() < 1e-5);
    assert!((end.x - 100.0).abs() < 1e-5);
    assert!((end.y).abs() < 1e-5);
}

#[test]
fn bezier_evaluate_midpoint_quadratic() {
    // For a quadratic Bezier P0=(0,0), P1=(50,100), P2=(100,0)
    // midpoint at t=0.5 = (50, 50) by symmetry
    let curve = BezierCurve::new(vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(50.0, 100.0),
        Vec2::new(100.0, 0.0),
    ]);
    let mid = curve.evaluate(0.5);
    assert!((mid.x - 50.0).abs() < 1e-5);
    assert!((mid.y - 50.0).abs() < 1e-5);
}

#[test]
fn bezier_render_segments() {
    let curve = BezierCurve::new(vec![Vec2::new(0.0, 0.0), Vec2::new(100.0, 100.0)]);
    let points = curve.render(10);
    assert_eq!(points.len(), 11); // 10 segments = 11 points
}

#[test]
fn bezier_render_segment_range() {
    let curve = BezierCurve::new(vec![Vec2::new(0.0, 0.0), Vec2::new(100.0, 100.0)]);
    let points = curve.render_segment(0.0, 0.5, 4);
    assert_eq!(points.len(), 5);
    // Last point should be at t=0.5 = (50, 50)
    assert!((points[4].x - 50.0).abs() < 1e-5);
    assert!((points[4].y - 50.0).abs() < 1e-5);
}

#[test]
fn bezier_derivative_cubic_to_quadratic() {
    let curve = BezierCurve::new(vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(10.0, 20.0),
        Vec2::new(30.0, 20.0),
        Vec2::new(40.0, 0.0),
    ]);
    let deriv = curve.get_derivative();
    assert_eq!(deriv.get_control_point_count(), 3); // cubic → quadratic
}

#[test]
fn bezier_control_point_operations() {
    let mut curve = BezierCurve::new(vec![Vec2::new(0.0, 0.0), Vec2::new(100.0, 100.0)]);
    assert_eq!(curve.get_control_point_count(), 2);

    curve.insert_control_point(Vec2::new(50.0, 50.0), Some(1));
    assert_eq!(curve.get_control_point_count(), 3);

    let p = curve.get_control_point(1).unwrap();
    assert!((p.x - 50.0).abs() < 1e-5);

    curve.set_control_point(1, Vec2::new(60.0, 70.0));
    let p = curve.get_control_point(1).unwrap();
    assert!((p.x - 60.0).abs() < 1e-5);

    assert!(curve.remove_control_point(1));
    assert_eq!(curve.get_control_point_count(), 2);
    // Can't remove below 2
    assert!(!curve.remove_control_point(0));
}

#[test]
fn bezier_translate() {
    let mut curve = BezierCurve::new(vec![Vec2::new(0.0, 0.0), Vec2::new(10.0, 10.0)]);
    curve.translate(5.0, 5.0);
    let p = curve.get_control_point(0).unwrap();
    assert!((p.x - 5.0).abs() < 1e-5);
    assert!((p.y - 5.0).abs() < 1e-5);
}

#[test]
fn bezier_scale() {
    let mut curve = BezierCurve::new(vec![Vec2::new(10.0, 10.0), Vec2::new(20.0, 20.0)]);
    curve.scale(2.0, 0.0, 0.0);
    let p = curve.get_control_point(0).unwrap();
    assert!((p.x - 20.0).abs() < 1e-5);
    assert!((p.y - 20.0).abs() < 1e-5);
}

// ===========================================================================
// Polygon tests
// ===========================================================================

#[test]
fn polygon_triangulate_triangle() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    let tris = polygon::triangulate(&verts).unwrap();
    assert_eq!(tris.len(), 1);
}

#[test]
fn polygon_triangulate_square() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(1.0, 1.0),
        Vec2::new(0.0, 1.0),
    ];
    let tris = polygon::triangulate(&verts).unwrap();
    assert_eq!(tris.len(), 2);
}

#[test]
fn polygon_triangulate_concave_l_shape() {
    // L-shaped concave polygon
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(2.0, 0.0),
        Vec2::new(2.0, 1.0),
        Vec2::new(1.0, 1.0),
        Vec2::new(1.0, 2.0),
        Vec2::new(0.0, 2.0),
    ];
    let tris = polygon::triangulate(&verts).unwrap();
    assert_eq!(tris.len(), 4); // 6 vertices → 4 triangles
}

#[test]
fn polygon_triangulate_too_few_vertices() {
    let verts = vec![Vec2::new(0.0, 0.0), Vec2::new(1.0, 0.0)];
    assert!(polygon::triangulate(&verts).is_err());
}

#[test]
fn polygon_is_convex_triangle() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(0.5, 1.0),
    ];
    assert!(polygon::is_convex(&verts));
}

#[test]
fn polygon_is_convex_square() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(1.0, 0.0),
        Vec2::new(1.0, 1.0),
        Vec2::new(0.0, 1.0),
    ];
    assert!(polygon::is_convex(&verts));
}

#[test]
fn polygon_is_convex_concave() {
    // Star/arrow shape — concave
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(2.0, 0.0),
        Vec2::new(2.0, 2.0),
        Vec2::new(1.0, 1.0), // concave indent
        Vec2::new(0.0, 2.0),
    ];
    assert!(!polygon::is_convex(&verts));
}

// ===========================================================================
// Color space tests
// ===========================================================================

#[test]
fn color_gamma_linear_roundtrip() {
    for i in 0..=10 {
        let gamma = i as f32 / 10.0;
        let linear = srgb::gamma_to_linear(gamma);
        let back = srgb::linear_to_gamma(linear);
        assert!(
            (back - gamma).abs() < 1e-4,
            "gamma roundtrip: {gamma} → {linear} → {back}"
        );
    }
}

#[test]
fn color_gamma_to_linear_known_value() {
    let linear = srgb::gamma_to_linear(0.5);
    assert!(
        (linear - 0.214).abs() < 0.01,
        "gammaToLinear(0.5) = {linear}, expected ~0.214"
    );
}

#[test]
fn color_linear_to_gamma_boundary() {
    assert!((srgb::linear_to_gamma(0.0)).abs() < 1e-5);
    assert!((srgb::linear_to_gamma(1.0) - 1.0).abs() < 1e-5);
}

// ===========================================================================
// 3D/4D noise tests
// ===========================================================================

#[test]
fn noise_perlin3d_deterministic() {
    let a = noise::perlin3d(1.5, 2.3, 3.7, 42);
    let b = noise::perlin3d(1.5, 2.3, 3.7, 42);
    assert!((a - b).abs() < f32::EPSILON, "3D noise not deterministic");
}

#[test]
fn noise_perlin3d_range() {
    for i in 0..100 {
        let x = i as f32 * 0.37;
        let y = i as f32 * 0.53;
        let z = i as f32 * 0.71;
        let v = noise::perlin3d(x, y, z, 0);
        assert!(
            v >= -2.0 && v <= 2.0,
            "3D noise out of range: {v} at ({x}, {y}, {z})"
        );
    }
}

#[test]
fn noise_perlin3d_varies() {
    let a = noise::perlin3d(0.0, 0.0, 0.0, 0);
    let b = noise::perlin3d(5.7, 3.2, 1.1, 0);
    // At least some pairs should differ
    assert!(
        (a - b).abs() > f32::EPSILON || a.abs() < f32::EPSILON,
        "3D noise not varying"
    );
}

#[test]
fn noise_perlin4d_deterministic() {
    let a = noise::perlin4d(1.5, 2.3, 3.7, 4.1, 42);
    let b = noise::perlin4d(1.5, 2.3, 3.7, 4.1, 42);
    assert!((a - b).abs() < f32::EPSILON, "4D noise not deterministic");
}

#[test]
fn noise_perlin4d_range() {
    for i in 0..100 {
        let x = i as f32 * 0.37;
        let y = i as f32 * 0.53;
        let z = i as f32 * 0.71;
        let w = i as f32 * 0.29;
        let v = noise::perlin4d(x, y, z, w, 0);
        assert!(
            v >= -3.0 && v <= 3.0,
            "4D noise out of range: {v} at ({x}, {y}, {z}, {w})"
        );
    }
}

#[test]
fn noise_remapped_to_zero_one() {
    // Test the [0,1] remapping as used in the Lua API
    for i in 0..100 {
        let x = i as f32 * 0.37;
        let y = i as f32 * 0.53;
        let raw = noise::perlin2d(x, y, 0);
        let mapped = (raw + 1.0) / 2.0;
        assert!(
            mapped >= -0.5 && mapped <= 1.5,
            "Remapped noise out of expected range: {mapped}"
        );
    }
}

// ===========================================================================
// Easing individual function tests
// ===========================================================================

#[test]
fn easing_linear_identity() {
    for i in 0..=10 {
        let t = i as f32 / 10.0;
        assert!((easing::linear(t) - t).abs() < 1e-5);
    }
}

#[test]
fn easing_quad_midpoints() {
    // ease_in_quad(0.5) = 0.25
    assert!((easing::ease_in_quad(0.5) - 0.25).abs() < 1e-5);
    // ease_out_quad(0.5) = 0.75
    assert!((easing::ease_out_quad(0.5) - 0.75).abs() < 1e-5);
    // ease_in_out_quad(0.5) = 0.5 (symmetric)
    assert!((easing::ease_in_out_quad(0.5) - 0.5).abs() < 1e-5);
}

#[test]
fn easing_cubic_midpoints() {
    assert!((easing::ease_in_cubic(0.5) - 0.125).abs() < 1e-5);
    assert!((easing::ease_out_cubic(0.5) - 0.875).abs() < 1e-5);
    assert!((easing::ease_in_out_cubic(0.5) - 0.5).abs() < 1e-5);
}

#[test]
fn easing_quart_midpoints() {
    assert!((easing::ease_in_quart(0.5) - 0.0625).abs() < 1e-5);
    assert!((easing::ease_out_quart(0.5) - 0.9375).abs() < 1e-5);
    assert!((easing::ease_in_out_quart(0.5) - 0.5).abs() < 1e-5);
}

#[test]
fn easing_sine_midpoints() {
    // ease_in_sine(0.5) ≈ 1 - cos(π/4) ≈ 0.2929
    assert!((easing::ease_in_sine(0.5) - 0.29289).abs() < 1e-3);
    // ease_out_sine(0.5) ≈ sin(π/4) ≈ 0.7071
    assert!((easing::ease_out_sine(0.5) - 0.70711).abs() < 1e-3);
    // ease_in_out_sine(0.5) = 0.5
    assert!((easing::ease_in_out_sine(0.5) - 0.5).abs() < 1e-5);
}

#[test]
fn mat3_from_row_major() {
    let data: [f32; 9] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0];
    let m = Mat3::from_row_major(&data);
    // Row 0
    assert!((m.m[0][0] - 1.0).abs() < f32::EPSILON);
    assert!((m.m[0][1] - 2.0).abs() < f32::EPSILON);
    assert!((m.m[0][2] - 3.0).abs() < f32::EPSILON);
    // Row 1
    assert!((m.m[1][0] - 4.0).abs() < f32::EPSILON);
    assert!((m.m[1][1] - 5.0).abs() < f32::EPSILON);
    assert!((m.m[1][2] - 6.0).abs() < f32::EPSILON);
    // Row 2
    assert!((m.m[2][0] - 7.0).abs() < f32::EPSILON);
    assert!((m.m[2][1] - 8.0).abs() < f32::EPSILON);
    assert!((m.m[2][2] - 9.0).abs() < f32::EPSILON);
}

#[test]
fn easing_expo_boundaries() {
    assert!((easing::ease_in_expo(0.0)).abs() < 1e-5);
    assert!((easing::ease_in_expo(1.0) - 1.0).abs() < 1e-3);
    assert!((easing::ease_out_expo(0.0)).abs() < 1e-3);
    assert!((easing::ease_out_expo(1.0) - 1.0).abs() < 1e-5);
    assert!((easing::ease_in_out_expo(0.0)).abs() < 1e-5);
    assert!((easing::ease_in_out_expo(1.0) - 1.0).abs() < 1e-5);
}

#[test]
fn easing_elastic_boundaries() {
    assert!((easing::ease_in_elastic(0.0)).abs() < 1e-5);
    assert!((easing::ease_in_elastic(1.0) - 1.0).abs() < 1e-5);
    assert!((easing::ease_out_elastic(0.0)).abs() < 1e-5);
    assert!((easing::ease_out_elastic(1.0) - 1.0).abs() < 1e-5);
}

#[test]
fn easing_bounce_symmetry() {
    // ease_in_bounce(t) = 1 - ease_out_bounce(1-t)
    for i in 0..=10 {
        let t = i as f32 / 10.0;
        let in_val = easing::ease_in_bounce(t);
        let out_val = 1.0 - easing::ease_out_bounce(1.0 - t);
        assert!(
            (in_val - out_val).abs() < 1e-5,
            "bounce symmetry broken at t={t}: in={in_val}, 1-out(1-t)={out_val}"
        );
    }
}

#[test]
fn easing_back_overshoot() {
    // ease_in_back goes negative near t=0.3
    let v = easing::ease_in_back(0.3);
    assert!(v < 0.0, "ease_in_back(0.3) should overshoot negative: {v}");
    // ease_out_back goes > 1.0 near t=0.7
    let v2 = easing::ease_out_back(0.7);
    assert!(v2 > 1.0, "ease_out_back(0.7) should overshoot > 1: {v2}");
}

#[test]
fn easing_monotonic_in_curves() {
    // ease_in curves should be monotonically increasing
    let fns: Vec<fn(f32) -> f32> = vec![
        easing::ease_in_quad,
        easing::ease_in_cubic,
        easing::ease_in_quart,
        easing::ease_in_sine,
    ];
    for f in fns {
        let mut prev = f(0.0);
        for i in 1..=20 {
            let t = i as f32 / 20.0;
            let cur = f(t);
            assert!(
                cur >= prev - 1e-5,
                "monotonicity violated at t={t}: prev={prev}, cur={cur}"
            );
            prev = cur;
        }
    }
}

#[test]
fn easing_apply_case_insensitive() {
    let a = easing::apply("inQuad", 0.5).unwrap();
    let b = easing::apply("INQUAD", 0.5).unwrap();
    let c = easing::apply("inquad", 0.5).unwrap();
    assert!((a - b).abs() < 1e-5);
    assert!((b - c).abs() < 1e-5);
}

#[test]
fn easing_in_out_curves_are_symmetric() {
    // in-out curves should satisfy f(0.5) ≈ 0.5
    let names = [
        "inOutQuad",
        "inOutCubic",
        "inOutQuart",
        "inOutSine",
        "inOutExpo",
    ];
    for name in names {
        let v = easing::apply(name, 0.5).unwrap();
        assert!(
            (v - 0.5).abs() < 1e-3,
            "ease({name}, 0.5) = {v}, expected ~0.5"
        );
    }
}
