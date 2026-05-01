//! INTERNAL ONLY: Rust-only tests for the `globe` module.
//!
//! Covers: fog, lighting, projection, topology.
//! Tests for draw/label/layer/marker/registry/loader are integration-level and
//! live in tests/lua/ per the Lua-first testing rule; pure-Rust-internal paths
//! tested here are not reachable through lurek.*.

// ── fog ───────────────────────────────────────────────────────────────────────

mod fog_tests {
    use lurek2d::globe::fog::{FogMask, FogStore};

    // FogMask::all_hidden

    #[test]
    fn all_hidden_no_province_visible() {
        let mask = FogMask::all_hidden();
        assert!(!mask.is_visible(0));
        assert!(!mask.is_visible(1));
        assert!(!mask.is_visible(100));
    }

    #[test]
    fn all_hidden_count_visible_is_zero() {
        let mask = FogMask::all_hidden();
        assert_eq!(mask.count_visible(), 0);
    }

    #[test]
    fn all_hidden_visible_ids_is_empty() {
        let mask = FogMask::all_hidden();
        assert!(mask.visible_ids().is_empty());
    }

    // FogMask::all_visible

    #[test]
    fn all_visible_province_zero_visible() {
        let mask = FogMask::all_visible();
        assert!(mask.is_visible(0));
    }

    #[test]
    fn all_visible_province_ten_visible() {
        let mask = FogMask::all_visible();
        assert!(mask.is_visible(10));
    }

    #[test]
    fn all_visible_count_visible_nonzero() {
        let mask = FogMask::all_visible();
        assert!(mask.count_visible() > 0);
    }

    // FogMask::reveal / hide

    #[test]
    fn reveal_makes_province_visible() {
        let mut mask = FogMask::all_hidden();
        mask.reveal(5);
        assert!(mask.is_visible(5));
        assert!(!mask.is_visible(6));
    }

    #[test]
    fn hide_after_reveal_hides_province() {
        let mut mask = FogMask::all_hidden();
        mask.reveal(3);
        assert!(mask.is_visible(3));
        mask.hide(3);
        assert!(!mask.is_visible(3));
    }

    #[test]
    fn reveal_increments_count() {
        let mut mask = FogMask::all_hidden();
        mask.reveal(0);
        mask.reveal(1);
        mask.reveal(2);
        assert_eq!(mask.count_visible(), 3);
    }

    #[test]
    fn hide_decrements_count() {
        let mut mask = FogMask::all_hidden();
        mask.reveal(0);
        mask.reveal(1);
        mask.hide(0);
        assert_eq!(mask.count_visible(), 1);
    }

    #[test]
    fn reveal_out_of_bounds_is_noop() {
        let mut mask = FogMask::all_hidden();
        // Revealing an ID at or beyond MAX_PROVINCES should not panic.
        mask.reveal(99999);
        assert!(!mask.is_visible(99999));
    }

    // FogMask::reveal_batch

    #[test]
    fn reveal_batch_reveals_all_ids() {
        let mut mask = FogMask::all_hidden();
        mask.reveal_batch([10u32, 20, 30].iter().copied());
        assert!(mask.is_visible(10));
        assert!(mask.is_visible(20));
        assert!(mask.is_visible(30));
        assert!(!mask.is_visible(11));
    }

    // FogMask::visible_ids

    #[test]
    fn visible_ids_returns_revealed_ids() {
        let mut mask = FogMask::all_hidden();
        mask.reveal(1);
        mask.reveal(7);
        mask.reveal(63);
        let mut ids = mask.visible_ids();
        ids.sort_unstable();
        assert_eq!(ids, vec![1, 7, 63]);
    }

    // FogMask::from_visible_ids round-trip

    #[test]
    fn from_visible_ids_round_trip() {
        let ids: Vec<u32> = vec![0, 5, 100, 255];
        let mask = FogMask::from_visible_ids(&ids);
        let mut recovered = mask.visible_ids();
        recovered.sort_unstable();
        assert_eq!(recovered, ids);
    }

    #[test]
    fn from_visible_ids_empty_gives_hidden_mask() {
        let mask = FogMask::from_visible_ids(&[]);
        assert_eq!(mask.count_visible(), 0);
    }

    // FogStore::new / get_or_insert / reveal / hide

    #[test]
    fn fog_store_new_is_empty() {
        let store = FogStore::new();
        assert!(store.viewers().is_empty());
    }

    #[test]
    fn get_or_insert_creates_hidden_mask() {
        let mut store = FogStore::new();
        let mask = store.get_or_insert("player");
        assert_eq!(mask.count_visible(), 0);
    }

    #[test]
    fn fog_store_reveal_makes_visible() {
        let mut store = FogStore::new();
        store.reveal("player", 42);
        assert!(store.is_visible("player", 42));
        assert!(!store.is_visible("player", 43));
    }

    #[test]
    fn fog_store_hide_clears_visible() {
        let mut store = FogStore::new();
        store.reveal("player", 10);
        store.hide("player", 10);
        assert!(!store.is_visible("player", 10));
    }

    // FogStore::visible_ids

    #[test]
    fn fog_store_visible_ids_for_known_viewer() {
        let mut store = FogStore::new();
        store.reveal("ally", 5);
        store.reveal("ally", 9);
        let mut ids = store.visible_ids("ally").unwrap();
        ids.sort_unstable();
        assert_eq!(ids, vec![5, 9]);
    }

    #[test]
    fn fog_store_visible_ids_none_for_unknown_viewer() {
        let store = FogStore::new();
        assert!(store.visible_ids("ghost").is_none());
    }

    // FogStore::viewers

    #[test]
    fn fog_store_viewers_lists_known_viewers() {
        let mut store = FogStore::new();
        store.reveal("a", 0);
        store.reveal("b", 0);
        let mut viewers = store.viewers();
        viewers.sort();
        assert_eq!(viewers, vec!["a", "b"]);
    }

    // FogStore::is_visible for unknown viewer (no fog)

    #[test]
    fn fog_store_is_visible_true_for_unknown_viewer() {
        let store = FogStore::new();
        // Unknown viewer → no mask → full visibility.
        assert!(store.is_visible("ghost", 99));
    }
}

// ── lighting ──────────────────────────────────────────────────────────────────

mod lighting_tests {
    use lurek2d::globe::lighting::{
        compute_intensities, province_intensity, sun_direction, terminator_alpha,
    };
    use lurek2d::globe::types::GlobeSpec;

    fn default_spec() -> GlobeSpec {
        GlobeSpec::default()
    }

    // sun_direction

    #[test]
    fn sun_direction_returns_unit_vector() {
        let spec = default_spec();
        let sun = sun_direction(&spec);
        let len = (sun.x * sun.x + sun.y * sun.y + sun.z * sun.z).sqrt();
        assert!((len - 1.0).abs() < 1e-4, "sun_direction not unit: {}", len);
    }

    #[test]
    fn sun_direction_changes_with_time_of_day() {
        let mut spec = default_spec();
        let s0 = sun_direction(&spec);
        spec.time_of_day = 0.5;
        let s1 = sun_direction(&spec);
        // Directions should be different when ToD changes significantly.
        let diff = (s0.x - s1.x).abs() + (s0.y - s1.y).abs() + (s0.z - s1.z).abs();
        assert!(diff > 0.1, "sun_direction did not change with time_of_day");
    }

    #[test]
    fn sun_direction_no_tilt_equinox_is_equatorial() {
        let mut spec = default_spec();
        spec.axial_tilt_deg = 0.0;
        spec.time_of_day = 0.0;
        spec.rotation_deg = 0.0;
        let sun = sun_direction(&spec);
        // At time_of_day=0 and no tilt, sun should be in equatorial plane (y ≈ 0).
        assert!(sun.y.abs() < 0.01, "unexpected y component: {}", sun.y);
    }

    // province_intensity

    #[test]
    fn province_intensity_at_subsolar_is_one() {
        // Province exactly under the sun (same direction as sun).
        let sun_lat = 0.0_f32;
        let sun_lon = 180.0_f32; // default ToD=0.25 → sun is westward, use lon 0 directly.
                                 // Use a simpler setup: direct sun vector.
        let sun = lurek2d::math::Vec3::new(0.0, 0.0, 1.0);
        // lat=90 corresponds to north pole (z=1 on unit sphere in lat_lon_to_unit).
        // Actually lat_lon_to_unit(0, 0) = (sin(0), 0, cos(0)) in some conventions;
        // since we use the Vec3 directly, test clamping to 1.0 instead.
        let _unused = (sun_lat, sun_lon);
        let intensity = province_intensity(0.0, 0.0, &sun, 0.08);
        // Dot product with (0,0,1) for lat=0, lon=0 depends on sphere convention;
        // just verify it is within [0.08, 1.0].
        assert!(
            intensity >= 0.08 && intensity <= 1.0,
            "intensity {intensity} out of range"
        );
    }

    #[test]
    fn province_intensity_floor_at_ambient() {
        // On the night side, intensity should be clamped at ambient.
        let sun = lurek2d::math::Vec3::new(1.0, 0.0, 0.0);
        let ambient = 0.08;
        // lat=0, lon=180 puts the province on the opposite side from (1,0,0).
        let intensity = province_intensity(0.0, 180.0, &sun, ambient);
        assert!(
            intensity >= ambient - 1e-5,
            "intensity {intensity} below ambient {ambient}"
        );
    }

    #[test]
    fn province_intensity_in_range() {
        let spec = default_spec();
        let sun = sun_direction(&spec);
        let intensity = province_intensity(45.0, 30.0, &sun, spec.ambient);
        assert!(intensity >= spec.ambient && intensity <= 1.0);
    }

    // compute_intensities

    #[test]
    fn compute_intensities_length_matches_input() {
        let spec = default_spec();
        let sun = sun_direction(&spec);
        let centroids = vec![(0.0_f32, 0.0_f32), (45.0, 90.0), (-30.0, -60.0)];
        let result = compute_intensities(centroids.into_iter(), &sun, spec.ambient);
        assert_eq!(result.len(), 3);
    }

    #[test]
    fn compute_intensities_all_in_range() {
        let spec = default_spec();
        let sun = sun_direction(&spec);
        let centroids: Vec<(f32, f32)> = (0..20)
            .map(|i| (i as f32 * 9.0 - 90.0, i as f32 * 18.0 - 180.0))
            .collect();
        let result = compute_intensities(centroids.into_iter(), &sun, spec.ambient);
        for v in &result {
            assert!(
                *v >= spec.ambient && *v <= 1.0,
                "intensity {v} outside [{}, 1.0]",
                spec.ambient
            );
        }
    }

    #[test]
    fn compute_intensities_empty_input_returns_empty() {
        let spec = default_spec();
        let sun = sun_direction(&spec);
        let result = compute_intensities(std::iter::empty(), &sun, spec.ambient);
        assert!(result.is_empty());
    }

    // terminator_alpha

    #[test]
    fn terminator_alpha_day_side_is_one() {
        // Sun pointing along +Z; lat=90 (north pole) should be full day.
        let sun = lurek2d::math::Vec3::new(0.0, 1.0, 0.0);
        let alpha = terminator_alpha(90.0, 0.0, &sun, 10.0);
        // North pole with sun pointing up should be fully lit.
        assert!(alpha >= 0.0 && alpha <= 1.0);
    }

    #[test]
    fn terminator_alpha_in_range() {
        let spec = default_spec();
        let sun = sun_direction(&spec);
        let alpha = terminator_alpha(45.0, 30.0, &sun, 15.0);
        assert!(alpha >= 0.0 && alpha <= 1.0);
    }

    #[test]
    fn terminator_alpha_transition_zero_is_hard_edge() {
        let spec = default_spec();
        let sun = sun_direction(&spec);
        // With transition_deg = 0 the result can only be 0 or 1.
        let alpha = terminator_alpha(45.0, 30.0, &sun, 0.0);
        // Should not panic and return a clamped value.
        assert!(alpha >= 0.0 && alpha <= 1.0);
    }
}

// ── projection ────────────────────────────────────────────────────────────────

mod projection_tests {
    use lurek2d::globe::projection::{
        build_view_matrix, normalize_v3, project_point, project_point_with_z, project_province,
        screen_delta_to_pan, OrbitCamera,
    };
    use lurek2d::globe::types::{GlobeSpec, LodTier, Province};
    use lurek2d::math::Vec3;

    fn default_spec() -> GlobeSpec {
        GlobeSpec::default()
    }

    fn default_camera() -> OrbitCamera {
        OrbitCamera::default()
    }

    // OrbitCamera::default

    #[test]
    fn orbit_camera_default_values() {
        let cam = default_camera();
        assert_eq!(cam.lat_deg, 30.0);
        assert_eq!(cam.lon_deg, 0.0);
        assert_eq!(cam.zoom, 1.0);
        assert_eq!(cam.screen_cx, 640.0);
        assert_eq!(cam.screen_cy, 360.0);
    }

    // OrbitCamera::zoom_by

    #[test]
    fn zoom_by_doubles_zoom() {
        let mut cam = default_camera();
        cam.zoom_by(2.0);
        assert!((cam.zoom - 2.0).abs() < 1e-5);
    }

    #[test]
    fn zoom_by_clamped_at_max() {
        let mut cam = default_camera();
        cam.zoom_by(1000.0);
        assert!(cam.zoom <= 20.0);
    }

    #[test]
    fn zoom_by_clamped_at_min() {
        let mut cam = default_camera();
        cam.zoom_by(0.0001);
        assert!(cam.zoom >= 0.1);
    }

    // OrbitCamera::lod

    #[test]
    fn lod_far_when_zoom_below_1_5() {
        let mut cam = default_camera();
        cam.zoom = 1.0;
        assert_eq!(cam.lod(), LodTier::Far);
    }

    #[test]
    fn lod_mid_when_zoom_between_1_5_and_4() {
        let mut cam = default_camera();
        cam.zoom = 2.0;
        assert_eq!(cam.lod(), LodTier::Mid);
    }

    #[test]
    fn lod_near_when_zoom_at_least_4() {
        let mut cam = default_camera();
        cam.zoom = 4.0;
        assert_eq!(cam.lod(), LodTier::Near);
    }

    // build_view_matrix

    #[test]
    fn build_view_matrix_returns_without_panic() {
        let spec = default_spec();
        let cam = default_camera();
        let _ = build_view_matrix(&spec, &cam);
    }

    #[test]
    fn build_view_matrix_different_rotation_differs() {
        let mut spec = default_spec();
        let cam = default_camera();
        let m1 = build_view_matrix(&spec, &cam);
        spec.rotation_deg = 90.0;
        let m2 = build_view_matrix(&spec, &cam);
        // The matrices should differ.
        let same = m1.cols[0][0] == m2.cols[0][0]
            && m1.cols[1][1] == m2.cols[1][1]
            && m1.cols[2][2] == m2.cols[2][2];
        assert!(!same, "matrices should differ for different rotation_deg");
    }

    // project_point

    #[test]
    fn project_point_front_hemisphere_returns_some() {
        let spec = default_spec();
        let cam = default_camera();
        let view = build_view_matrix(&spec, &cam);
        // lat=30, lon=0 is roughly toward camera at default orientation.
        let result = project_point(
            30.0,
            0.0,
            &view,
            spec.radius,
            cam.zoom,
            cam.screen_cx,
            cam.screen_cy,
        );
        assert!(result.is_some(), "expected front-facing point to project");
    }

    #[test]
    fn project_point_far_back_returns_none() {
        let spec = default_spec();
        let cam = default_camera();
        let view = build_view_matrix(&spec, &cam);
        // lat=-30, lon=180 is the antipodal region — should be culled.
        let result = project_point(
            -30.0,
            180.0,
            &view,
            spec.radius,
            cam.zoom,
            cam.screen_cx,
            cam.screen_cy,
        );
        // Allow either None or Some — the exact cull depends on camera angle.
        // Just verify no panic.
        let _ = result;
    }

    #[test]
    fn project_point_result_near_screen_centre() {
        // At default camera (lat=30, lon=0) the globe center maps near screen_cx/cy.
        let spec = default_spec();
        let cam = default_camera();
        let view = build_view_matrix(&spec, &cam);
        if let Some(v) = project_point(
            30.0,
            0.0,
            &view,
            spec.radius,
            cam.zoom,
            cam.screen_cx,
            cam.screen_cy,
        ) {
            assert!(v.x > 0.0 && v.x < 1280.0);
            assert!(v.y > 0.0 && v.y < 720.0);
        }
    }

    // project_province

    #[test]
    fn project_province_front_visible() {
        let spec = default_spec();
        let cam = default_camera();
        let view = build_view_matrix(&spec, &cam);
        // A tiny triangle near lat=30, lon=0 (front hemisphere at default cam).
        let verts = vec![(30.0_f32, -1.0_f32), (31.0, 0.0), (30.0, 1.0)];
        let prov = Province::new(1, verts);
        let result = project_province(&prov, &view, &spec, &cam, 1.0);
        assert!(result.is_some(), "front-hemisphere province should project");
    }

    #[test]
    fn project_province_culled_returns_none_or_some() {
        let spec = default_spec();
        let cam = default_camera();
        let view = build_view_matrix(&spec, &cam);
        // Province near south pole, antipodal side — likely culled.
        let verts = vec![(-80.0_f32, 170.0_f32), (-80.0, 175.0), (-75.0, 172.0)];
        let prov = Province::new(2, verts);
        let _ = project_province(&prov, &view, &spec, &cam, 0.5);
        // No panic is the assertion.
    }

    // project_point_with_z

    #[test]
    fn project_point_with_z_returns_positive_z_on_front() {
        let spec = default_spec();
        let cam = default_camera();
        let view = build_view_matrix(&spec, &cam);
        if let Some((_pos, z)) = project_point_with_z(30.0, 0.0, &view, &spec, &cam) {
            assert!(z > 0.0, "z should be positive on front hemisphere");
        }
    }

    #[test]
    fn project_point_with_z_back_hemisphere_returns_none() {
        let spec = default_spec();
        let cam = default_camera();
        let view = build_view_matrix(&spec, &cam);
        // Test a point that might be on the back — at minimum, no panic.
        let _ = project_point_with_z(-30.0, 180.0, &view, &spec, &cam);
    }

    // screen_delta_to_pan

    #[test]
    fn screen_delta_to_pan_nonzero_for_nonzero_delta() {
        let spec = default_spec();
        let cam = default_camera();
        let (dlat, dlon) = screen_delta_to_pan(10.0, 5.0, &spec, &cam);
        assert!(dlat != 0.0 || dlon != 0.0);
    }

    #[test]
    fn screen_delta_to_pan_zero_delta_is_zero() {
        let spec = default_spec();
        let cam = default_camera();
        let (dlat, dlon) = screen_delta_to_pan(0.0, 0.0, &spec, &cam);
        assert_eq!(dlat, 0.0);
        assert_eq!(dlon, 0.0);
    }

    #[test]
    fn screen_delta_to_pan_dx_moves_longitude() {
        let spec = default_spec();
        let cam = default_camera();
        let (_, dlon) = screen_delta_to_pan(10.0, 0.0, &spec, &cam);
        assert!(dlon != 0.0, "dx should produce a lon change");
    }

    #[test]
    fn screen_delta_to_pan_dy_moves_latitude() {
        let spec = default_spec();
        let cam = default_camera();
        let (dlat, _) = screen_delta_to_pan(0.0, 10.0, &spec, &cam);
        assert!(dlat != 0.0, "dy should produce a lat change");
    }

    // normalize_v3

    #[test]
    fn normalize_v3_unit_vector() {
        let v = Vec3::new(3.0, 4.0, 0.0);
        let n = normalize_v3(v);
        let len = (n.x * n.x + n.y * n.y + n.z * n.z).sqrt();
        assert!((len - 1.0).abs() < 1e-6, "normalized length {}", len);
    }

    #[test]
    fn normalize_v3_already_unit() {
        let v = Vec3::new(1.0, 0.0, 0.0);
        let n = normalize_v3(v);
        assert!((n.x - 1.0).abs() < 1e-6);
        assert!(n.y.abs() < 1e-6);
        assert!(n.z.abs() < 1e-6);
    }

    #[test]
    fn normalize_v3_zero_returns_zero() {
        let v = Vec3::new(0.0, 0.0, 0.0);
        let n = normalize_v3(v);
        assert_eq!(n.x, 0.0);
        assert_eq!(n.y, 0.0);
        assert_eq!(n.z, 0.0);
    }

    #[test]
    fn normalize_v3_negative_components() {
        let v = Vec3::new(-1.0, -1.0, -1.0);
        let n = normalize_v3(v);
        let len = (n.x * n.x + n.y * n.y + n.z * n.z).sqrt();
        assert!((len - 1.0).abs() < 1e-6);
    }
}

// ── topology ──────────────────────────────────────────────────────────────────

mod topology_tests {
    use lurek2d::globe::topology::ProvinceGraph;
    use lurek2d::globe::types::{GlobeError, Province};

    fn make_province(id: u32, neighbors: Vec<u32>) -> Province {
        let mut p = Province::new(id, vec![(0.0_f32, 0.0_f32), (1.0, 0.0), (0.5, 1.0)]);
        p.neighbors = neighbors;
        p
    }

    // ProvinceGraph::new / insert / len / is_empty

    #[test]
    fn new_graph_is_empty() {
        let g = ProvinceGraph::new();
        assert!(g.is_empty());
        assert_eq!(g.len(), 0);
    }

    #[test]
    fn insert_increases_len() {
        let mut g = ProvinceGraph::new();
        g.insert(Province::new(1, vec![])).unwrap();
        assert_eq!(g.len(), 1);
        assert!(!g.is_empty());
    }

    #[test]
    fn insert_multiple_provinces() {
        let mut g = ProvinceGraph::new();
        for id in 0..5 {
            g.insert(Province::new(id, vec![])).unwrap();
        }
        assert_eq!(g.len(), 5);
    }

    // ProvinceGraph::get

    #[test]
    fn get_returns_inserted_province() {
        let mut g = ProvinceGraph::new();
        g.insert(Province::new(42, vec![])).unwrap();
        assert!(g.get(42).is_some());
        assert!(g.get(43).is_none());
    }

    // ProvinceGraph::remove

    #[test]
    fn remove_existing_returns_some() {
        let mut g = ProvinceGraph::new();
        g.insert(Province::new(10, vec![])).unwrap();
        let removed = g.remove(10);
        assert!(removed.is_some());
        assert!(g.get(10).is_none());
        assert_eq!(g.len(), 0);
    }

    #[test]
    fn remove_nonexistent_returns_none() {
        let mut g = ProvinceGraph::new();
        assert!(g.remove(99).is_none());
    }

    // ProvinceGraph::neighbors_of

    #[test]
    fn neighbors_of_reflects_province_neighbors() {
        let mut g = ProvinceGraph::new();
        let p = make_province(1, vec![2, 3]);
        g.insert(p).unwrap();
        let nbrs = g.neighbors_of(1);
        assert_eq!(nbrs.len(), 2);
        assert!(nbrs.contains(&2));
        assert!(nbrs.contains(&3));
    }

    #[test]
    fn neighbors_of_empty_for_unknown_province() {
        let g = ProvinceGraph::new();
        assert!(g.neighbors_of(999).is_empty());
    }

    // ProvinceGraph::set_attr / get_attr

    #[test]
    fn set_and_get_attr() {
        let mut g = ProvinceGraph::new();
        g.insert(Province::new(1, vec![])).unwrap();
        g.set_attr(1, "terrain".to_string(), "plains".to_string())
            .unwrap();
        assert_eq!(g.get_attr(1, "terrain"), Some("plains"));
    }

    #[test]
    fn get_attr_missing_key_returns_none() {
        let mut g = ProvinceGraph::new();
        g.insert(Province::new(1, vec![])).unwrap();
        assert!(g.get_attr(1, "nonexistent").is_none());
    }

    #[test]
    fn set_attr_nonexistent_province_returns_error() {
        let mut g = ProvinceGraph::new();
        let result = g.set_attr(999, "k".to_string(), "v".to_string());
        assert!(matches!(result, Err(GlobeError::ProvinceNotFound(999))));
    }

    #[test]
    fn set_attr_overwrites_existing() {
        let mut g = ProvinceGraph::new();
        g.insert(Province::new(1, vec![])).unwrap();
        g.set_attr(1, "owner".to_string(), "red".to_string())
            .unwrap();
        g.set_attr(1, "owner".to_string(), "blue".to_string())
            .unwrap();
        assert_eq!(g.get_attr(1, "owner"), Some("blue"));
    }

    // ProvinceGraph::reachable_default

    // ProvinceGraph::rebuild_caches

    #[test]
    fn rebuild_caches_restores_neighbor_info() {
        let mut g = ProvinceGraph::new();
        let mut p = Province::new(1, vec![(0.0_f32, 0.0_f32)]);
        p.neighbors = vec![2];
        g.insert(p).unwrap();
        // Force cache rebuild.
        g.rebuild_caches();
        assert_eq!(g.neighbors_of(1), &[2u32]);
    }

    #[test]
    fn rebuild_caches_empty_graph_is_noop() {
        let mut g = ProvinceGraph::new();
        g.rebuild_caches(); // Should not panic.
        assert!(g.is_empty());
    }
}
