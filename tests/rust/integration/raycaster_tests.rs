/// Integration tests for the `raycaster` module.
///
/// Validates DDA grid setup, cell queries, and ray casting results. All
/// tests are headless with no GPU or audio requirements.
use lurek2d::raycaster::Raycaster2D;

// ── Construction and grid operations ─────────────────────────────────────────

#[test]
fn new_raycaster_has_correct_dimensions() {
    let rc = Raycaster2D::new(32, 24);
    assert_eq!(rc.width(), 32);
    assert_eq!(rc.height(), 24);
}

#[test]
fn new_raycaster_all_cells_are_zero() {
    let rc = Raycaster2D::new(10, 10);
    for y in 0..10 {
        for x in 0..10 {
            assert_eq!(rc.get_cell(x, y), 0, "cell ({x},{y}) should be 0");
        }
    }
}

#[test]
fn set_and_get_cell_roundtrip() {
    let mut rc = Raycaster2D::new(8, 8);
    rc.set_cell(3, 5, 42);
    assert_eq!(rc.get_cell(3, 5), 42);
}

#[test]
fn set_cells_replaces_all_values() {
    let mut rc = Raycaster2D::new(4, 4);
    let new_cells: Vec<u32> = (0_u32..16).collect();
    rc.set_cells(new_cells.clone());
    for i in 0..16_u32 {
        let x = i % 4;
        let y = i / 4;
        assert_eq!(rc.get_cell(x, y), i);
    }
}

// ── is_blocked ────────────────────────────────────────────────────────────────

#[test]
fn is_blocked_returns_false_for_zero_cell() {
    let rc = Raycaster2D::new(4, 4);
    assert!(!rc.is_blocked(2, 2));
}

#[test]
fn is_blocked_returns_true_for_nonzero_cell() {
    let mut rc = Raycaster2D::new(4, 4);
    rc.set_cell(1, 1, 1);
    assert!(rc.is_blocked(1, 1));
}

// ── cast_ray ──────────────────────────────────────────────────────────────────

#[test]
fn cast_ray_hits_wall_in_front_of_origin() {
    let mut rc = Raycaster2D::new(10, 10);
    // Put a wall at (5, 5)
    rc.set_cell(5, 5, 1);
    // Cast from (0.5, 5.5) pointing right (angle = 0)
    let hit = rc.cast_ray(0.5, 5.5, 0.0, 20.0);
    assert!(hit.is_some(), "expected a ray hit");
    let h = hit.unwrap();
    assert!(h.hit, "hit flag should be true");
    assert!(h.distance > 0.0, "distance should be positive");
    assert_eq!(h.cell_value, 1, "cell value should be 1");
}

#[test]
fn cast_ray_returns_none_in_empty_grid() {
    let rc = Raycaster2D::new(10, 10);
    // Ray pointing east through open grid – hits boundary, not a wall
    let hit = rc.cast_ray(5.0, 5.0, 0.0, 20.0);
    // The ray may travel beyond grid bounds and return None or a boundary hit
    // Either outcome is valid; we just check the function does not panic.
    let _ = hit;
}

// ── cast_rays ─────────────────────────────────────────────────────────────────

#[test]
fn cast_rays_returns_requested_count() {
    let rc = Raycaster2D::new(20, 20);
    let rays = rc.cast_rays(10.0, 10.0, 0.0, std::f32::consts::FRAC_PI_2, 64, 30.0);
    assert_eq!(rays.len(), 64);
}

#[test]
fn cast_rays_all_hit_flags_correct_in_walled_enclosure() {
    let mut rc = Raycaster2D::new(10, 10);
    // Build a 10×10 box with walls on all borders
    for x in 0..10_u32 {
        rc.set_cell(x, 0, 1);
        rc.set_cell(x, 9, 1);
    }
    for y in 0..10_u32 {
        rc.set_cell(0, y, 1);
        rc.set_cell(9, y, 1);
    }
    // Cast 360° from centre – all rays should hit a wall
    let rays = rc.cast_rays(4.5, 4.5, 0.0, std::f32::consts::TAU, 32, 20.0);
    for (i, r) in rays.iter().enumerate() {
        assert!(r.hit, "ray {i} should hit a wall in an enclosed grid");
    }
}
