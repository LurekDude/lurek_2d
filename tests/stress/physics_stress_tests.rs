//! Stress tests for the physics module — mass body creation, simulation, and determinism.

use luna2d::physics::{Body, BodyType, World};

#[test]
fn stress_create_1000_bodies() {
    let mut world = World::new(0.0, 100.0);
    let mut ids = Vec::new();
    for i in 0..1000 {
        let x = (i % 50) as f32 * 10.0;
        let y = (i / 50) as f32 * 10.0;
        let id = world.add_body(Body::new(x, y, BodyType::Dynamic));
        ids.push(id);
    }
    assert_eq!(world.body_count(), 1000);
    for &id in &ids {
        assert!(world.get_body(id).is_some());
    }
}

#[test]
fn stress_step_1000_bodies_60_frames() {
    let mut world = World::new(0.0, 100.0);
    for i in 0..1000 {
        let x = (i % 50) as f32 * 10.0;
        let y = (i / 50) as f32 * 10.0;
        world.add_body(Body::new(x, y, BodyType::Dynamic));
    }
    // Simulate 60 frames (1 second at 60fps)
    for _ in 0..60 {
        world.step(1.0 / 60.0);
    }
    assert_eq!(world.body_count(), 1000, "all bodies survive simulation");
}

#[test]
fn stress_mixed_body_types() {
    let mut world = World::new(0.0, 200.0);
    // Static ground
    for i in 0..20 {
        let mut body = Body::new(i as f32 * 32.0, 500.0, BodyType::Static);
        body.width = 32.0;
        body.height = 32.0;
        world.add_body(body);
    }
    // Dynamic falling bodies
    for i in 0..500 {
        let x = (i % 20) as f32 * 32.0 + 16.0;
        let y = -(i as f32) * 10.0;
        world.add_body(Body::new(x, y, BodyType::Dynamic));
    }
    assert_eq!(world.body_count(), 520);

    // Step 120 frames
    for _ in 0..120 {
        world.step(1.0 / 60.0);
    }
    assert_eq!(
        world.body_count(),
        520,
        "all bodies survive after 120 steps"
    );
}

#[test]
fn stress_physics_determinism() {
    fn run_sim() -> (f32, f32) {
        let mut world = World::new(0.0, 100.0);
        let id = world.add_body(Body::new(100.0, 0.0, BodyType::Dynamic));
        for _ in 0..60 {
            world.step(1.0 / 60.0);
        }
        let body = world.get_body(id).unwrap();
        (body.position.x, body.position.y)
    }

    let (x1, y1) = run_sim();
    let (x2, y2) = run_sim();
    assert!((x1 - x2).abs() < 1e-5, "X deterministic: {} vs {}", x1, x2);
    assert!((y1 - y2).abs() < 1e-5, "Y deterministic: {} vs {}", y1, y2);
}

#[test]
fn stress_circle_bodies() {
    let mut world = World::new(0.0, 50.0);
    for i in 0..200 {
        let body = Body::new_circle(
            (i % 20) as f32 * 15.0 + 50.0,
            (i / 20) as f32 * 15.0,
            5.0,
            BodyType::Dynamic,
        );
        world.add_body(body);
    }
    for _ in 0..180 {
        world.step(1.0 / 60.0);
    }
    assert_eq!(world.body_count(), 200, "circle bodies survive simulation");
}

#[test]
fn stress_collision_events_collected() {
    let mut world = World::new(0.0, 100.0);
    // Two bodies that will collide
    let mut a = Body::new(100.0, 0.0, BodyType::Dynamic);
    a.velocity.x = 50.0;
    let mut b = Body::new(200.0, 0.0, BodyType::Dynamic);
    b.velocity.x = -50.0;
    world.add_body(a);
    world.add_body(b);

    for _ in 0..120 {
        world.step(1.0 / 60.0);
        // Exercise collision event collection
        let _ = world.get_collision_events();
    }
    // Simulation completes; collision detection is exercised
    assert_eq!(world.body_count(), 2);
}
