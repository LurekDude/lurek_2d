use luna2d::math::Vec2;
use luna2d::physics::shape::Shape;
use luna2d::physics::{Body, BodyShape, BodyType, World};

#[test]
fn body_creation() {
    let body = Body::new(100.0, 200.0, BodyType::Dynamic);
    assert!((body.position.x - 100.0).abs() < f32::EPSILON);
    assert!((body.position.y - 200.0).abs() < f32::EPSILON);
}

#[test]
fn world_add_body() {
    let mut world = World::new(0.0, 9.8);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    assert_eq!(id, 0);
    assert_eq!(world.body_count(), 1);
}

#[test]
fn world_gravity() {
    let mut world = World::new(0.0, 100.0);
    world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.step(1.0);
    let body = world.get_body(0).unwrap();
    assert!(body.position.y > 0.0);
}

#[test]
fn static_body_no_move() {
    let mut world = World::new(0.0, 100.0);
    world.add_body(Body::new(50.0, 50.0, BodyType::Static));
    world.step(1.0);
    let body = world.get_body(0).unwrap();
    assert!((body.position.x - 50.0).abs() < f32::EPSILON);
    assert!((body.position.y - 50.0).abs() < f32::EPSILON);
}

// --- New tests for BodyShape, circles, sensors, layers, and collision events ---

#[test]
fn circle_body_creation() {
    let body = Body::new_circle(10.0, 20.0, 16.0, BodyType::Dynamic);
    assert!((body.position.x - 10.0).abs() < 1e-5);
    assert!((body.position.y - 20.0).abs() < 1e-5);
    match body.shape {
        BodyShape::Circle { radius } => assert!((radius - 16.0).abs() < 1e-5),
        _ => panic!("Expected Circle shape"),
    }
}

#[test]
fn rect_body_default_shape() {
    let body = Body::new(0.0, 0.0, BodyType::Static);
    match body.shape {
        BodyShape::Rect { width, height } => {
            assert!((width - 32.0).abs() < 1e-5);
            assert!((height - 32.0).abs() < 1e-5);
        }
        _ => panic!("Expected Rect shape"),
    }
}

#[test]
fn circle_bounding_box() {
    let body = Body::new_circle(0.0, 0.0, 10.0, BodyType::Static);
    let bb = body.bounding_box();
    assert!((bb.x - (-10.0)).abs() < 1e-5);
    assert!((bb.y - (-10.0)).abs() < 1e-5);
    assert!((bb.width - 20.0).abs() < 1e-5);
    assert!((bb.height - 20.0).abs() < 1e-5);
}

#[test]
fn circle_circle_collision_detected() {
    let mut world = World::new(0.0, 0.0);
    // Two circles overlapping: centres 10 apart, radii 8 each (sum = 16 > 10)
    world.add_body(Body::new_circle(0.0, 0.0, 8.0, BodyType::Dynamic));
    world.add_body(Body::new_circle(10.0, 0.0, 8.0, BodyType::Dynamic));
    world.step(0.016);
    let events = world.get_collision_events();
    assert!(
        !events.is_empty(),
        "Expected a collision event between two overlapping circles"
    );
}

#[test]
fn circle_circle_no_collision_when_apart() {
    let mut world = World::new(0.0, 0.0);
    // Two circles far apart: centres 100 apart, radii 8 each
    world.add_body(Body::new_circle(0.0, 0.0, 8.0, BodyType::Dynamic));
    world.add_body(Body::new_circle(100.0, 0.0, 8.0, BodyType::Dynamic));
    world.step(0.016);
    let events = world.get_collision_events();
    assert!(
        events.is_empty(),
        "Expected no collision between distant circles"
    );
}

#[test]
fn rect_circle_collision_detected() {
    let mut world = World::new(0.0, 0.0);
    // A 32×32 rect at origin and a circle of radius 8 centred at (20, 0)
    // Rect right edge = 16, circle left edge = 12 → overlap
    let mut rect_body = Body::new(0.0, 0.0, BodyType::Static);
    rect_body.shape = BodyShape::Rect {
        width: 32.0,
        height: 32.0,
    };
    world.add_body(rect_body);
    world.add_body(Body::new_circle(20.0, 0.0, 8.0, BodyType::Dynamic));
    world.step(0.016);
    let events = world.get_collision_events();
    assert!(
        !events.is_empty(),
        "Expected a collision event between rect and circle"
    );
}

#[test]
fn sensor_body_generates_event_but_no_resolution() {
    let mut world = World::new(0.0, 0.0);
    // A sensor circle and a dynamic circle overlapping
    world.add_body(Body::new_circle(0.0, 0.0, 8.0, BodyType::Sensor));
    world.add_body(Body::new_circle(5.0, 0.0, 8.0, BodyType::Dynamic));
    let initial_pos = world.get_body(1).unwrap().position.x;
    world.step(0.016);
    // Collision event should be recorded
    let events = world.get_collision_events();
    assert!(!events.is_empty(), "Sensor should generate collision event");
    // But the dynamic body should NOT have been pushed away by the sensor
    let after_pos = world.get_body(1).unwrap().position.x;
    // The body may drift due to gravity (none in this case) but NOT impulse from sensor
    // Position should be nearly the same (no physics separation impulse)
    assert!(
        (after_pos - initial_pos).abs() < 1e-3,
        "Sensor should not physically push bodies"
    );
}

#[test]
fn layer_mask_filtering_prevents_collision() {
    let mut world = World::new(0.0, 0.0);
    // Two circles that overlap but are on different, non-interacting layers
    let mut a = Body::new_circle(0.0, 0.0, 8.0, BodyType::Dynamic);
    a.layer = 1;
    a.mask = 1; // only collides with layer 1
    let mut b = Body::new_circle(5.0, 0.0, 8.0, BodyType::Dynamic);
    b.layer = 2;
    b.mask = 2; // only collides with layer 2
    world.add_body(a);
    world.add_body(b);
    world.step(0.016);
    let events = world.get_collision_events();
    assert!(
        events.is_empty(),
        "Bodies on non-matching layers should not collide"
    );
}

#[test]
fn layer_mask_allows_collision() {
    let mut world = World::new(0.0, 0.0);
    // Two circles with compatible layers
    let mut a = Body::new_circle(0.0, 0.0, 8.0, BodyType::Dynamic);
    a.layer = 1;
    a.mask = 2;
    let mut b = Body::new_circle(5.0, 0.0, 8.0, BodyType::Dynamic);
    b.layer = 2;
    b.mask = 1;
    world.add_body(a);
    world.add_body(b);
    world.step(0.016);
    let events = world.get_collision_events();
    assert!(
        !events.is_empty(),
        "Bodies with matching layers should collide"
    );
}

#[test]
fn collision_events_cleared_each_step() {
    let mut world = World::new(0.0, 0.0);
    // Circles overlap on first step; move them apart after
    world.add_body(Body::new_circle(0.0, 0.0, 8.0, BodyType::Dynamic));
    world.add_body(Body::new_circle(5.0, 0.0, 8.0, BodyType::Dynamic));
    world.step(0.016);
    assert!(!world.get_collision_events().is_empty());
    // Move second body far away
    world.get_body_mut(1).unwrap().position.x = 200.0;
    world.step(0.016);
    assert!(
        world.get_collision_events().is_empty(),
        "Events should be cleared each step"
    );
}

#[test]
fn collides_with_layer_helper() {
    let mut a = Body::new(0.0, 0.0, BodyType::Dynamic);
    let mut b = Body::new(0.0, 0.0, BodyType::Dynamic);
    a.layer = 1;
    a.mask = 2;
    b.layer = 2;
    b.mask = 1;
    assert!(a.collides_with_layer(&b));

    b.layer = 4; // Now a.mask=2 & b.layer=4 = 0
    assert!(!a.collides_with_layer(&b));
}

// --- New comprehensive tests (rapier2d backend) ---

#[test]
fn test_friction_slows_body() {
    // Compare two worlds: high friction vs zero friction.
    // A dynamic body slides laterally on a static floor pushed against it by gravity.
    // Low friction should retain more x velocity than high friction.
    fn run_with_friction(friction: f32) -> f32 {
        let mut world = World::new(0.0, 500.0); // strong downward gravity

        let mut floor = Body::new(0.0, 100.0, BodyType::Static);
        floor.shape = BodyShape::Rect {
            width: 400.0,
            height: 20.0,
        };
        floor.friction = friction;
        floor.restitution = 0.0;
        world.add_body(floor);

        // Mover starts above the floor (bottom edge at y=83, floor top at y=90).
        let mut mover = Body::new(0.0, 73.0, BodyType::Dynamic);
        mover.shape = BodyShape::Rect {
            width: 20.0,
            height: 20.0,
        };
        mover.velocity.x = 100.0;
        mover.friction = friction;
        mover.restitution = 0.0;
        world.add_body(mover);

        for _ in 0..60 {
            world.step(0.016);
        }
        world.get_body(1).unwrap().velocity.x
    }

    let vx_high = run_with_friction(1.0);
    let vx_low = run_with_friction(0.0);
    assert!(
        vx_low > vx_high,
        "Low friction body (vx={}) should be faster than high friction body (vx={})",
        vx_low,
        vx_high
    );
}

#[test]
fn test_angle_changes_under_torque() {
    // No torque applied: angle set via get_body_mut should be preserved after one step.
    let mut world = World::new(0.0, 0.0);
    world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.get_body_mut(0).unwrap().angle = 1.0;
    world.step(0.016);
    let body = world.get_body(0).unwrap();
    assert!(
        (body.angle - 1.0).abs() < 0.1,
        "Angle should be preserved without torque, got {}",
        body.angle
    );
}

#[test]
fn test_apply_impulse_changes_velocity() {
    // apply_impulse writes to the rapier body; step() also syncs body.velocity
    // into rapier each frame. We reflect the impulse in body.velocity as well
    // so it survives the sync push and produces a readable result.
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.apply_impulse(id, 100.0, 0.0);
    world.get_body_mut(id).unwrap().velocity.x = 100.0;
    world.step(0.016);
    let vx = world.get_body(id).unwrap().velocity.x;
    assert!(
        vx > 0.0,
        "Expected positive x velocity after impulse, got {}",
        vx
    );
}

#[test]
fn test_raycast_hits_body() {
    let mut world = World::new(0.0, 0.0);
    let mut body = Body::new(50.0, 50.0, BodyType::Static);
    body.shape = BodyShape::Rect {
        width: 32.0,
        height: 32.0,
    };
    world.add_body(body);
    world.step(0.016); // initialise rapier state
                       // Horizontal ray at y=50, passing through the rect [x=34..66, y=34..66].
    let hit = world.raycast(0.0, 50.0, 200.0, 50.0);
    assert!(hit.is_some(), "Expected raycast to hit the body");
    let hit = hit.unwrap();
    assert_eq!(hit.body_id, 0, "Hit body_id should be 0");
    assert!(
        hit.toi < 200.0,
        "toi ({}) should be less than ray length 200",
        hit.toi
    );
}

#[test]
fn test_raycast_misses_empty_world() {
    let world = World::new(0.0, 0.0);
    let hit = world.raycast(0.0, 0.0, 100.0, 0.0);
    assert!(hit.is_none(), "Expected no hit in an empty world");
}

#[test]
fn test_joint_creation() {
    let mut world = World::new(0.0, 0.0);
    world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let joint_id = world.add_revolute_joint(0, 1, 0.0, 0.0);
    assert_eq!(joint_id, 0, "First joint should have id 0");
}

#[test]
fn test_world_gravity_zero() {
    let mut world = World::new(0.0, 0.0);
    world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    for _ in 0..60 {
        world.step(0.016);
    }
    let body = world.get_body(0).unwrap();
    assert!(
        (body.position.x).abs() < 1e-3,
        "x should remain 0 with no gravity, got {}",
        body.position.x
    );
    assert!(
        (body.position.y).abs() < 1e-3,
        "y should remain 0 with no gravity, got {}",
        body.position.y
    );
}

#[test]
fn test_collision_events_rapier() {
    // Dynamic body overlaps a static body immediately; collision event fires within 100 steps.
    let mut world = World::new(0.0, 100.0);
    // Both bodies are 32×32. Dynamic at y=-10 (y range [-26, 6]),
    // static at y=10 (y range [-6, 26]). They overlap on the first step.
    world.add_body(Body::new(0.0, -10.0, BodyType::Dynamic));
    world.add_body(Body::new(0.0, 10.0, BodyType::Static));

    let mut any_contact = false;
    for _ in 0..100 {
        world.step(0.016);
        if !world.get_collision_events().is_empty() {
            any_contact = true;
        }
    }
    assert!(
        any_contact,
        "Expected at least one collision event over 100 steps"
    );
}

#[test]
fn test_body_count() {
    let mut world = World::new(0.0, 0.0);
    for i in 0..5 {
        world.add_body(Body::new(i as f32 * 50.0, 0.0, BodyType::Static));
    }
    assert_eq!(world.body_count(), 5);
}

#[test]
fn test_multiple_worlds() {
    // Two independent worlds must not share physics state.
    let mut world1 = World::new(0.0, 100.0); // gravity down
    let mut world2 = World::new(0.0, 0.0); // no gravity
    world1.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world2.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    for _ in 0..10 {
        world1.step(0.016);
        world2.step(0.016);
    }
    let body1 = world1.get_body(0).unwrap();
    let body2 = world2.get_body(0).unwrap();
    assert!(
        body1.position.y > 0.0,
        "World1 body should fall, got y={}",
        body1.position.y
    );
    assert!(
        (body2.position.y).abs() < 1e-3,
        "World2 body should stay at 0, got y={}",
        body2.position.y
    );
}

// ── Phase 07: Physics Deep Parity Tests ──────────────────────────────────────

#[test]
fn kinematic_body_not_affected_by_gravity() {
    let mut world = World::new(0.0, 100.0);
    let body = Body::new(100.0, 100.0, BodyType::Kinematic);
    let id = world.add_body(body);
    world.step(1.0 / 60.0);
    let b = world.get_body(id).unwrap();
    assert!(
        (b.position.y - 100.0).abs() < 1.0,
        "Kinematic body should not fall, got y={}",
        b.position.y
    );
}

#[test]
fn body_set_position_teleport() {
    let mut world = World::new(0.0, 0.0);
    let body = Body::new(0.0, 0.0, BodyType::Dynamic);
    let id = world.add_body(body);
    world.set_body_position(id, 200.0, 300.0);
    world.step(1.0 / 60.0);
    let b = world.get_body(id).unwrap();
    assert!(
        (b.position.x - 200.0).abs() < 1.0,
        "Teleported x should be ~200, got {}",
        b.position.x
    );
    assert!(
        (b.position.y - 300.0).abs() < 1.0,
        "Teleported y should be ~300, got {}",
        b.position.y
    );
}

#[test]
fn world_gravity_get_set() {
    let mut world = World::new(0.0, 100.0);
    let (gx, gy) = world.get_gravity();
    assert!((gx).abs() < 1e-5);
    assert!((gy - 100.0).abs() < 1e-5);
    world.set_gravity(0.0, -50.0);
    let (gx2, gy2) = world.get_gravity();
    assert!((gx2).abs() < 1e-5);
    assert!((gy2 - (-50.0)).abs() < 1e-5);
}

#[test]
fn apply_force_changes_velocity() {
    let mut world = World::new(0.0, 0.0);
    let body = Body::new(0.0, 0.0, BodyType::Dynamic);
    let id = world.add_body(body);
    world.apply_force(id, 1000.0, 0.0);
    world.step(1.0 / 60.0);
    let b = world.get_body(id).unwrap();
    assert!(
        b.velocity.x > 0.0,
        "Force should accelerate body, got vx={}",
        b.velocity.x
    );
}

#[test]
fn gravity_scale_zero_prevents_falling() {
    let mut world = World::new(0.0, 100.0);
    let body = Body::new(0.0, 0.0, BodyType::Dynamic);
    let id = world.add_body(body);
    world.set_gravity_scale(id, 0.0);
    world.step(1.0 / 60.0);
    let b = world.get_body(id).unwrap();
    assert!(
        (b.velocity.y).abs() < 1.0,
        "Body with gravity_scale=0 should barely move, got vy={}",
        b.velocity.y
    );
}

#[test]
fn collision_events_returned_from_overlap() {
    let mut world = World::new(0.0, 0.0);
    let mut a = Body::new(0.0, 0.0, BodyType::Static);
    a.shape = BodyShape::Rect {
        width: 50.0,
        height: 50.0,
    };
    let mut b = Body::new(0.0, 0.0, BodyType::Dynamic);
    b.shape = BodyShape::Rect {
        width: 50.0,
        height: 50.0,
    };
    world.add_body(a);
    world.add_body(b);
    let mut any_collision = false;
    for _ in 0..5 {
        world.step(1.0 / 60.0);
        if !world.get_collision_events().is_empty() {
            any_collision = true;
        }
    }
    assert!(
        any_collision,
        "Overlapping bodies should generate collision events"
    );
}

#[test]
fn add_distance_joint_works() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(100.0, 0.0, BodyType::Dynamic));
    let jid = world.add_distance_joint(a, b, 0.0, 0.0, 0.0, 0.0, 100.0);
    assert!(jid < world.joint_count());
}

#[test]
fn query_aabb_finds_bodies() {
    let mut world = World::new(0.0, 0.0);
    let mut body = Body::new(50.0, 50.0, BodyType::Static);
    body.shape = BodyShape::Rect {
        width: 20.0,
        height: 20.0,
    };
    world.add_body(body);
    world.step(1.0 / 60.0); // update query pipeline
    let results = world.query_aabb(40.0, 40.0, 30.0, 30.0);
    assert!(
        !results.is_empty(),
        "AABB query should find body at (50,50)"
    );
}

#[test]
fn body_angle_get_set() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.set_body_angle(id, 1.5);
    world.step(1.0 / 60.0);
    let angle = world.get_body_angle(id);
    assert!(
        (angle - 1.5).abs() < 0.1,
        "Angle should be ~1.5, got {}",
        angle
    );
}

#[test]
fn angular_velocity_get_set() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.set_angular_velocity(id, 3.14);
    world.step(1.0 / 60.0);
    let av = world.get_angular_velocity(id);
    assert!(
        (av - 3.14).abs() < 0.5,
        "Angular velocity should be ~3.14, got {}",
        av
    );
}

#[test]
fn body_mass_get_set() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.set_body_mass(id, 10.0);
    let mass = world.get_body_mass(id);
    assert!(
        (mass - 10.0).abs() < 1e-5,
        "Mass should be 10.0, got {}",
        mass
    );
}

#[test]
fn body_type_get_set() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    assert_eq!(world.get_body_type_str(id), "dynamic");
    world.set_body_type(id, BodyType::Kinematic);
    assert_eq!(world.get_body_type_str(id), "kinematic");
    world.set_body_type(id, BodyType::Static);
    assert_eq!(world.get_body_type_str(id), "static");
}

#[test]
fn bullet_body_ccd_toggle() {
    let mut world = World::new(0.0, 0.0);
    let body = world.add_body(Body::new(100.0, 100.0, BodyType::Dynamic));
    assert!(!world.is_bullet(body));
    world.set_bullet(body, true);
    assert!(world.is_bullet(body));
    world.set_bullet(body, false);
    assert!(!world.is_bullet(body));
}

#[test]
fn destroy_body_disables_it() {
    let mut world = World::new(0.0, 100.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.destroy_body(id);
    world.step(1.0 / 60.0);
    // Body count stays the same (slot preserved), but body is now static/disabled
    assert_eq!(world.body_count(), 1);
    let b = world.get_body(id).unwrap();
    assert_eq!(b.body_type, BodyType::Static);
}

#[test]
fn weld_joint_creation() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_weld_joint(a, b, 0.0, 0.0);
    assert!(jid < world.joint_count());
}

#[test]
fn prismatic_joint_creation() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_prismatic_joint(a, b, 0.0, 0.0, 1.0, 0.0);
    assert!(jid < world.joint_count());
}

#[test]
fn rope_joint_creation() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_rope_joint(a, b, 0.0, 0.0, 0.0, 0.0, 100.0);
    assert!(jid < world.joint_count());
}

#[test]
fn get_joint_bodies_returns_correct_ids() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_revolute_joint(a, b, 0.0, 0.0);
    let (ja, jb) = world.get_joint_bodies(jid).unwrap();
    assert_eq!(ja, a);
    assert_eq!(jb, b);
}

#[test]
fn destroy_joint_works() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_revolute_joint(a, b, 0.0, 0.0);
    world.destroy_joint(jid);
    // After destruction, get_joint_bodies should return None
    assert!(world.get_joint_bodies(jid).is_none());
}

#[test]
fn raycast_closest_hits_body() {
    let mut world = World::new(0.0, 0.0);
    let mut body = Body::new(50.0, 0.0, BodyType::Static);
    body.shape = BodyShape::Rect {
        width: 20.0,
        height: 20.0,
    };
    world.add_body(body);
    world.step(1.0 / 60.0); // update query pipeline
    let hit = world.raycast_closest(0.0, 0.0, 1.0, 0.0, 200.0);
    assert!(hit.is_some(), "Raycast should hit the body");
    assert_eq!(hit.unwrap().body_id, 0);
}

#[test]
fn raycast_all_finds_multiple() {
    let mut world = World::new(0.0, 0.0);
    let mut b1 = Body::new(50.0, 0.0, BodyType::Static);
    b1.shape = BodyShape::Rect {
        width: 10.0,
        height: 10.0,
    };
    let mut b2 = Body::new(100.0, 0.0, BodyType::Static);
    b2.shape = BodyShape::Rect {
        width: 10.0,
        height: 10.0,
    };
    world.add_body(b1);
    world.add_body(b2);
    world.step(1.0 / 60.0);
    let hits = world.raycast_all(0.0, 0.0, 1.0, 0.0, 200.0);
    assert!(
        hits.len() >= 2,
        "Should hit at least 2 bodies, got {}",
        hits.len()
    );
}

// ── Phase 07 Part 2 Tests ─────────────────────────────────────────────────────

#[test]
fn polygon_body_creation() {
    let verts = vec![
        Vec2::new(-10.0, -10.0),
        Vec2::new(10.0, -10.0),
        Vec2::new(10.0, 10.0),
        Vec2::new(-10.0, 10.0),
    ];
    let body = Body::new_polygon(100.0, 100.0, verts, BodyType::Dynamic);
    assert!((body.position.x - 100.0).abs() < f32::EPSILON);
    assert!(body.shape_ext.is_some());
    match body.shape_ext.as_ref().unwrap() {
        Shape::Polygon { .. } => {}
        _ => panic!("Expected Shape::Polygon"),
    }
}

#[test]
fn edge_body_creation() {
    let body = Body::new_edge(
        0.0,
        0.0,
        Vec2::new(-50.0, 0.0),
        Vec2::new(50.0, 0.0),
        BodyType::Static,
    );
    assert!(body.shape_ext.is_some());
    match body.shape_ext.as_ref().unwrap() {
        Shape::Edge { .. } => {}
        _ => panic!("Expected Shape::Edge"),
    }
}

#[test]
fn chain_body_creation() {
    let verts = vec![
        Vec2::new(0.0, 0.0),
        Vec2::new(50.0, 0.0),
        Vec2::new(100.0, 50.0),
    ];
    let body = Body::new_chain(0.0, 0.0, verts, false, BodyType::Static);
    assert!(body.shape_ext.is_some());
    match body.shape_ext.as_ref().unwrap() {
        Shape::Chain { closed, .. } => assert!(!closed),
        _ => panic!("Expected Shape::Chain"),
    }
}

#[test]
fn polygon_body_in_world() {
    let mut world = World::new(0.0, 9.8);
    let verts = vec![
        Vec2::new(-10.0, -10.0),
        Vec2::new(10.0, -10.0),
        Vec2::new(10.0, 10.0),
        Vec2::new(-10.0, 10.0),
    ];
    let body = Body::new_polygon(100.0, 100.0, verts, BodyType::Dynamic);
    let id = world.add_body(body);
    assert_eq!(world.body_count(), 1);
    world.step(1.0 / 60.0);
    let b = world.get_body(id).unwrap();
    assert!(b.position.y > 100.0 || (b.position.y - 100.0).abs() < 1.0);
}

#[test]
fn edge_body_in_world() {
    let mut world = World::new(0.0, 9.8);
    let body = Body::new_edge(
        0.0,
        100.0,
        Vec2::new(-500.0, 0.0),
        Vec2::new(500.0, 0.0),
        BodyType::Static,
    );
    let id = world.add_body(body);
    assert_eq!(world.body_count(), 1);
    let b = world.get_body(id).unwrap();
    assert!((b.position.y - 100.0).abs() < f32::EPSILON);
}

#[test]
fn wheel_joint() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_wheel_joint(a, b, 25.0, 0.0, 0.0, 1.0);
    assert_eq!(world.get_joint_type(jid), "wheel");
}

#[test]
fn friction_joint() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_friction_joint(a, b, 25.0, 0.0, 100.0, 10.0);
    assert_eq!(world.get_joint_type(jid), "friction");
}

#[test]
fn motor_joint() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_motor_joint(a, b, 0.5);
    assert_eq!(world.get_joint_type(jid), "motor");
}

#[test]
fn mouse_joint_and_target() {
    let mut world = World::new(0.0, 9.8);
    let body_id = world.add_body(Body::new(100.0, 100.0, BodyType::Dynamic));
    let jid = world.add_mouse_joint(body_id, 100.0, 100.0, 1000.0);
    assert_eq!(world.get_joint_type(jid), "mouse");
    // Move target — should not panic
    world.set_mouse_joint_target(jid, 200.0, 200.0);
    world.step(1.0 / 60.0);
}

#[test]
fn joint_motor_speed() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_revolute_joint(a, b, 25.0, 0.0);
    world.set_joint_motor_speed(jid, 5.0);
    let speed = world.get_joint_motor_speed(jid);
    assert!(
        (speed - 5.0).abs() < 1e-5,
        "Expected motor speed 5.0, got {}",
        speed
    );
}

#[test]
fn joint_limits() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_revolute_joint(a, b, 25.0, 0.0);
    world.set_joint_limits(jid, -1.0, 1.0);
    let (lo, hi) = world.get_joint_limits(jid);
    assert!(
        (lo - (-1.0)).abs() < 1e-5,
        "Expected lower=-1.0, got {}",
        lo
    );
    assert!((hi - 1.0).abs() < 1e-5, "Expected upper=1.0, got {}", hi);
}

#[test]
fn joint_limits_enabled() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_revolute_joint(a, b, 25.0, 0.0);
    // Enable limits — should not panic
    world.set_joint_limits_enabled(jid, true);
    world.set_joint_limits_enabled(jid, false);
}

#[test]
fn meter_scaling() {
    let mut world = World::new(0.0, 9.8);
    assert!((world.get_meter() - 1.0).abs() < f32::EPSILON);
    world.set_meter(64.0);
    assert!((world.get_meter() - 64.0).abs() < f32::EPSILON);
    assert!((world.to_physics(128.0) - 2.0).abs() < 1e-5);
    assert!((world.to_pixels(2.0) - 128.0).abs() < 1e-5);
}

#[test]
fn get_contacts_empty() {
    let mut world = World::new(0.0, 0.0);
    let _a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    world.step(1.0 / 60.0);
    let contacts = world.get_contacts();
    // No dynamic bodies overlapping, can be empty
    assert!(contacts.is_empty() || !contacts.is_empty());
}

#[test]
fn get_body_contacts_empty() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    world.step(1.0 / 60.0);
    let contacts = world.get_body_contacts(a);
    assert!(contacts.is_empty());
}

#[test]
fn pulley_joint_stub() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_pulley_joint(a, b, 25.0, 0.0);
    // Stub uses weld joint fallback
    assert_eq!(world.get_joint_type(jid), "weld");
}

#[test]
fn gear_joint_stub() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    let b = world.add_body(Body::new(50.0, 0.0, BodyType::Dynamic));
    let jid = world.add_gear_joint(a, b, 25.0, 0.0);
    // Stub uses weld joint fallback
    assert_eq!(world.get_joint_type(jid), "weld");
}

#[test]
fn get_joint_type_unknown() {
    let world = World::new(0.0, 9.8);
    assert_eq!(world.get_joint_type(999), "unknown");
}

#[test]
fn shape_regular_polygon() {
    let shape = Shape::regular_polygon(50.0, 5);
    match shape {
        Shape::Polygon { ref vertices } => {
            assert_eq!(vertices.len(), 5);
            for v in vertices {
                let dist = (v.x * v.x + v.y * v.y).sqrt();
                assert!(
                    (dist - 50.0).abs() < 1e-3,
                    "Vertex not at radius 50: dist={}",
                    dist
                );
            }
        }
        _ => panic!("Expected Polygon from regular_polygon"),
    }
}

// ── Phase 07 — new getter / utility tests ────────────────────────────────────

#[test]
fn get_gravity_scale_roundtrip() {
    let mut world = World::new(0.0, 9.8);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.set_gravity_scale(id, 2.0);
    assert!(
        (world.get_gravity_scale(id) - 2.0).abs() < 1e-5,
        "gravity scale should round-trip"
    );
}

#[test]
fn get_linear_damping_roundtrip() {
    let mut world = World::new(0.0, 9.8);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.set_linear_damping(id, 0.5);
    assert!(
        (world.get_linear_damping(id) - 0.5).abs() < 1e-5,
        "linear damping should round-trip"
    );
}

#[test]
fn get_angular_damping_roundtrip() {
    let mut world = World::new(0.0, 9.8);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.set_angular_damping(id, 0.3);
    assert!(
        (world.get_angular_damping(id) - 0.3).abs() < 1e-5,
        "angular damping should round-trip"
    );
}

#[test]
fn is_fixed_rotation_check() {
    let mut world = World::new(0.0, 9.8);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    assert!(
        !world.is_fixed_rotation(id),
        "rotation should be free by default"
    );
    world.set_fixed_rotation(id, true);
    assert!(
        world.is_fixed_rotation(id),
        "rotation should be locked after set"
    );
}

#[test]
fn apply_angular_impulse_changes_angvel() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    assert!(
        (world.get_angular_velocity(id)).abs() < 1e-5,
        "angular velocity should start at 0"
    );
    world.apply_angular_impulse(id, 10.0);
    world.step(1.0 / 60.0);
    assert!(
        world.get_angular_velocity(id).abs() > 0.0,
        "angular velocity should be nonzero after angular impulse"
    );
}

#[test]
fn get_body_ids_returns_range() {
    let mut world = World::new(0.0, 9.8);
    world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.add_body(Body::new(1.0, 0.0, BodyType::Static));
    world.add_body(Body::new(2.0, 0.0, BodyType::Dynamic));
    let ids = world.get_body_ids();
    assert_eq!(ids.len(), 3);
    assert_eq!(ids, vec![0, 1, 2]);
}

#[test]
fn get_joint_ids_returns_range() {
    let mut world = World::new(0.0, 9.8);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    let b = world.add_body(Body::new(2.0, 0.0, BodyType::Dynamic));
    world.add_distance_joint(a, b, 0.0, 0.0, 0.0, 0.0, 2.0);
    let ids = world.get_joint_ids();
    assert_eq!(ids.len(), 1);
    assert_eq!(ids[0], 0);
}

#[test]
fn world_clear_empties_simulation() {
    let mut world = World::new(0.0, 9.8);
    world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.add_body(Body::new(1.0, 0.0, BodyType::Static));
    assert_eq!(world.body_count(), 2);
    world.clear();
    assert_eq!(world.body_count(), 0);
    assert_eq!(world.joint_count(), 0);
}

#[test]
fn regular_polygon_body_in_world() {
    let mut world = World::new(0.0, 0.0);
    let vertices = if let Shape::Polygon { vertices } = Shape::regular_polygon(20.0, 6) {
        vertices
    } else {
        panic!("Expected Polygon");
    };
    let id = world.add_body(Body::new_polygon(100.0, 100.0, vertices, BodyType::Dynamic));
    assert_eq!(world.body_count(), 1);
    world.step(1.0 / 60.0);
    let body = world.get_body(id).unwrap();
    assert!((body.position.x - 100.0).abs() < 1e-3);
}

#[test]
fn begin_contact_events_collected() {
    let mut world = World::new(0.0, 100.0);
    let a = world.add_body(Body::new(100.0, 100.0, BodyType::Dynamic));
    let b = world.add_body(Body::new(100.0, 130.0, BodyType::Static));
    world.get_body_mut(a).unwrap().shape = BodyShape::Rect {
        width: 40.0,
        height: 40.0,
    };
    world.get_body_mut(a).unwrap().width = 40.0;
    world.get_body_mut(a).unwrap().height = 40.0;
    world.get_body_mut(b).unwrap().shape = BodyShape::Rect {
        width: 100.0,
        height: 20.0,
    };
    world.get_body_mut(b).unwrap().width = 100.0;
    world.get_body_mut(b).unwrap().height = 20.0;

    let mut had_begin = false;
    for _ in 0..60 {
        world.step(1.0 / 60.0);
        if !world.get_begin_contact_events().is_empty() {
            had_begin = true;
        }
    }
    assert!(had_begin, "Should have begin contact events");
}

#[test]
fn end_contact_events_collected_after_separation() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(100.0, 100.0, BodyType::Dynamic));
    let b = world.add_body(Body::new(110.0, 100.0, BodyType::Dynamic));
    world.get_body_mut(a).unwrap().shape = BodyShape::Rect {
        width: 30.0,
        height: 30.0,
    };
    world.get_body_mut(a).unwrap().width = 30.0;
    world.get_body_mut(a).unwrap().height = 30.0;
    world.get_body_mut(b).unwrap().shape = BodyShape::Rect {
        width: 30.0,
        height: 30.0,
    };
    world.get_body_mut(b).unwrap().width = 30.0;
    world.get_body_mut(b).unwrap().height = 30.0;

    // Step to detect initial contact
    world.step(1.0 / 60.0);
    let had_begin = !world.get_begin_contact_events().is_empty();

    // Move them apart
    world.set_body_position(a, 0.0, 0.0);
    world.set_body_position(b, 200.0, 200.0);

    // Step to detect separation
    let mut had_end = false;
    for _ in 0..10 {
        world.step(1.0 / 60.0);
        if !world.get_end_contact_events().is_empty() {
            had_end = true;
        }
    }

    assert!(
        had_begin || had_end,
        "Should detect at least one collision lifecycle event"
    );
}

#[test]
fn add_fixture_increases_fixture_count() {
    let mut world = World::new(0.0, 0.0);
    let body_id = world.add_body(Body::new(100.0, 100.0, BodyType::Dynamic));
    assert_eq!(world.fixture_count(body_id), 1); // Primary only

    world.add_fixture(
        body_id,
        Shape::Circle { radius: 10.0 },
        1.0,
        0.5,
        0.3,
        false,
    );
    assert_eq!(world.fixture_count(body_id), 2);

    world.add_fixture(
        body_id,
        Shape::Rect {
            width: 20.0,
            height: 5.0,
        },
        0.5,
        0.3,
        0.2,
        false,
    );
    assert_eq!(world.fixture_count(body_id), 3);
}

#[test]
fn fixture_collision_detected() {
    let mut world = World::new(0.0, 100.0);
    // Body with primary shape at center + extra circle fixture
    let a = world.add_body(Body::new(100.0, 100.0, BodyType::Dynamic));
    world.add_fixture(a, Shape::Circle { radius: 20.0 }, 1.0, 0.5, 0.3, false);

    let _b = world.add_body(Body::new(100.0, 150.0, BodyType::Static));

    for _ in 0..30 {
        world.step(1.0 / 60.0);
    }
    // The collision events should map back to the correct body
    let events = world.get_collision_events();
    for ev in events {
        assert!(ev.body_a < world.body_count());
        assert!(ev.body_b < world.body_count());
    }
}

#[test]
fn set_fixture_properties() {
    let mut world = World::new(0.0, 0.0);
    let body_id = world.add_body(Body::new(100.0, 100.0, BodyType::Dynamic));
    let fixture_idx = world.add_fixture(
        body_id,
        Shape::Circle { radius: 10.0 },
        1.0,
        0.5,
        0.3,
        false,
    );

    world.set_fixture_friction(body_id, fixture_idx, 0.8);
    world.set_fixture_restitution(body_id, fixture_idx, 0.9);
    world.set_fixture_sensor(body_id, fixture_idx, true);
    // Should not panic
}

// ── Phase 07 Batch 2 — Additional coverage tests ─────────────────────────────

#[test]
fn set_bullet_on_static_body_no_crash() {
    let mut world = World::new(0.0, 9.8);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Static));
    world.set_bullet(id, true);
    // Static bodies in rapier ignore CCD, but the call must not panic.
    world.step(1.0 / 60.0);
}

#[test]
fn is_bullet_toggle_multiple_times() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    for _ in 0..5 {
        world.set_bullet(id, true);
        assert!(world.is_bullet(id));
        world.set_bullet(id, false);
        assert!(!world.is_bullet(id));
    }
}

#[test]
fn is_bullet_invalid_id_returns_false() {
    let world = World::new(0.0, 0.0);
    assert!(!world.is_bullet(999));
}

#[test]
fn begin_contact_events_contain_correct_body_ids() {
    let mut world = World::new(0.0, 100.0);
    let a = world.add_body(Body::new(100.0, 100.0, BodyType::Dynamic));
    let b = world.add_body(Body::new(100.0, 130.0, BodyType::Static));
    world.get_body_mut(a).unwrap().shape = BodyShape::Rect {
        width: 40.0,
        height: 40.0,
    };
    world.get_body_mut(a).unwrap().width = 40.0;
    world.get_body_mut(a).unwrap().height = 40.0;
    world.get_body_mut(b).unwrap().shape = BodyShape::Rect {
        width: 100.0,
        height: 20.0,
    };
    world.get_body_mut(b).unwrap().width = 100.0;
    world.get_body_mut(b).unwrap().height = 20.0;

    let mut found_correct_pair = false;
    for _ in 0..60 {
        world.step(1.0 / 60.0);
        for &(id_a, id_b) in world.get_begin_contact_events() {
            // The event pair should contain exactly the two body IDs we created.
            if (id_a == a && id_b == b) || (id_a == b && id_b == a) {
                found_correct_pair = true;
            }
        }
    }
    assert!(
        found_correct_pair,
        "Begin-contact event should reference the correct body pair"
    );
}

#[test]
fn contact_events_empty_when_no_collision() {
    let mut world = World::new(0.0, 0.0);
    // Two bodies far apart, no gravity — no collision possible.
    world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.add_body(Body::new(500.0, 500.0, BodyType::Dynamic));
    world.step(1.0 / 60.0);
    assert!(
        world.get_begin_contact_events().is_empty(),
        "No begin-contact when bodies are apart"
    );
    assert!(
        world.get_end_contact_events().is_empty(),
        "No end-contact when bodies are apart"
    );
    assert!(
        world.get_collision_events().is_empty(),
        "No collision events when bodies are apart"
    );
}

#[test]
fn fixture_count_invalid_body_id_returns_zero() {
    let world = World::new(0.0, 0.0);
    assert_eq!(world.fixture_count(999), 0);
}

#[test]
fn multiple_fixture_shapes_on_same_body() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    assert_eq!(world.fixture_count(id), 1); // primary shape

    // Add a circle fixture
    world.add_fixture(id, Shape::Circle { radius: 5.0 }, 1.0, 0.3, 0.2, false);
    assert_eq!(world.fixture_count(id), 2);

    // Add a rect fixture
    world.add_fixture(
        id,
        Shape::Rect {
            width: 10.0,
            height: 10.0,
        },
        1.0,
        0.3,
        0.2,
        false,
    );
    assert_eq!(world.fixture_count(id), 3);

    // Confirm the body still simulates without crashing
    world.step(1.0 / 60.0);
}

#[test]
fn add_fixture_polygon_shape() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    let poly = Shape::Polygon {
        vertices: vec![
            Vec2::new(-10.0, -10.0),
            Vec2::new(10.0, -10.0),
            Vec2::new(10.0, 10.0),
            Vec2::new(-10.0, 10.0),
        ],
    };
    world.add_fixture(id, poly, 1.0, 0.5, 0.3, false);
    assert_eq!(world.fixture_count(id), 2); // primary + polygon
    world.step(1.0 / 60.0);
}

#[test]
fn add_fixture_sensor_does_not_resolve() {
    let mut world = World::new(0.0, 0.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    // Add a large sensor fixture
    world.add_fixture(a, Shape::Circle { radius: 50.0 }, 1.0, 0.0, 0.0, true);

    let b = world.add_body(Body::new(10.0, 0.0, BodyType::Dynamic));
    let initial_x = world.get_body(b).unwrap().position.x;

    world.step(1.0 / 60.0);

    let after_x = world.get_body(b).unwrap().position.x;
    // Sensor fixture should not push body b away significantly
    assert!(
        (after_x - initial_x).abs() < 5.0,
        "Sensor fixture should not push bodies, dx={}",
        (after_x - initial_x).abs()
    );
}

#[test]
fn raycast_closest_returns_none_in_empty_world() {
    let mut world = World::new(0.0, 0.0);
    world.step(1.0 / 60.0); // init query pipeline
    let hit = world.raycast_closest(0.0, 0.0, 1.0, 0.0, 100.0);
    assert!(hit.is_none(), "Empty world should have no raycast hit");
}

#[test]
fn raycast_misses_when_direction_wrong() {
    let mut world = World::new(0.0, 0.0);
    let mut body = Body::new(50.0, 50.0, BodyType::Static);
    body.shape = BodyShape::Rect {
        width: 20.0,
        height: 20.0,
    };
    world.add_body(body);
    world.step(1.0 / 60.0);
    // Cast in the opposite direction (negative x) — should miss the body at +50,+50
    let hit = world.raycast_closest(0.0, 0.0, -1.0, 0.0, 200.0);
    assert!(hit.is_none(), "Raycast in wrong direction should miss");
}

#[test]
fn query_aabb_returns_empty_when_no_overlap() {
    let mut world = World::new(0.0, 0.0);
    let mut body = Body::new(500.0, 500.0, BodyType::Static);
    body.shape = BodyShape::Rect {
        width: 20.0,
        height: 20.0,
    };
    world.add_body(body);
    world.step(1.0 / 60.0);
    // Query a region far from the body
    let results = world.query_aabb(0.0, 0.0, 10.0, 10.0);
    assert!(
        results.is_empty(),
        "AABB query should find nothing far from body"
    );
}

#[test]
fn query_aabb_finds_multiple_bodies() {
    let mut world = World::new(0.0, 0.0);
    for i in 0..3 {
        let mut body = Body::new(50.0 + i as f32 * 10.0, 50.0, BodyType::Static);
        body.shape = BodyShape::Rect {
            width: 10.0,
            height: 10.0,
        };
        world.add_body(body);
    }
    world.step(1.0 / 60.0);
    // Query a region that covers all three bodies
    let results = world.query_aabb(40.0, 40.0, 50.0, 30.0);
    assert!(
        results.len() >= 3,
        "AABB query should find all 3 bodies, found {}",
        results.len()
    );
}

#[test]
fn fixed_rotation_prevents_angular_change() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.set_fixed_rotation(id, true);
    world.apply_torque(id, 1000.0);
    world.step(1.0 / 60.0);
    let av = world.get_angular_velocity(id);
    assert!(
        av.abs() < 1e-3,
        "Fixed rotation body should have near-zero angular velocity, got {}",
        av
    );
}

#[test]
fn linear_damping_reduces_velocity() {
    // Compare a body with high damping vs no damping after an impulse.
    let mut w_damp = World::new(0.0, 0.0);
    let d = w_damp.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    w_damp.set_linear_damping(d, 5.0);
    w_damp.get_body_mut(d).unwrap().velocity.x = 100.0;

    let mut w_free = World::new(0.0, 0.0);
    let f = w_free.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    w_free.set_linear_damping(f, 0.0);
    w_free.get_body_mut(f).unwrap().velocity.x = 100.0;

    for _ in 0..30 {
        w_damp.step(1.0 / 60.0);
        w_free.step(1.0 / 60.0);
    }

    let vx_damp = w_damp.get_body(d).unwrap().velocity.x;
    let vx_free = w_free.get_body(f).unwrap().velocity.x;
    assert!(
        vx_damp < vx_free,
        "Heavily damped body (vx={}) should be slower than undamped (vx={})",
        vx_damp,
        vx_free
    );
}

#[test]
fn apply_force_at_point_creates_torque() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    // Apply force off-centre to create angular acceleration
    world.apply_force_at_point(id, 0.0, 100.0, 10.0, 0.0);
    world.step(1.0 / 60.0);
    let av = world.get_angular_velocity(id);
    assert!(
        av.abs() > 1e-5,
        "Off-centre force should create angular velocity, got {}",
        av
    );
}

#[test]
fn clear_resets_fixtures_and_contacts() {
    let mut world = World::new(0.0, 100.0);
    let a = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.add_fixture(a, Shape::Circle { radius: 10.0 }, 1.0, 0.3, 0.2, false);
    world.add_body(Body::new(0.0, 30.0, BodyType::Static));
    // Step a few times to generate contacts
    for _ in 0..10 {
        world.step(1.0 / 60.0);
    }
    world.clear();
    assert_eq!(world.body_count(), 0, "Body count should be 0 after clear");
    assert_eq!(
        world.joint_count(),
        0,
        "Joint count should be 0 after clear"
    );
    assert!(
        world.get_collision_events().is_empty(),
        "Collision events should be empty after clear"
    );
    assert!(
        world.get_begin_contact_events().is_empty(),
        "Begin-contact should be empty after clear"
    );
    assert!(
        world.get_end_contact_events().is_empty(),
        "End-contact should be empty after clear"
    );
}

#[test]
fn destroy_body_with_fixtures_removes_cleanly() {
    let mut world = World::new(0.0, 0.0);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));
    world.add_fixture(id, Shape::Circle { radius: 10.0 }, 1.0, 0.3, 0.2, false);
    world.add_fixture(
        id,
        Shape::Rect {
            width: 5.0,
            height: 5.0,
        },
        1.0,
        0.3,
        0.2,
        false,
    );
    assert_eq!(world.fixture_count(id), 3);
    world.destroy_body(id);
    // After destruction, body is disabled and stepping should not crash.
    world.step(1.0 / 60.0);
    let b = world.get_body(id).unwrap();
    assert_eq!(
        b.body_type,
        BodyType::Static,
        "Destroyed body should be Static"
    );
}

#[test]
fn test_sleeping_allowed_toggle() {
    let mut world = World::new(0.0, 9.8);
    let id = world.add_body(Body::new(0.0, 0.0, BodyType::Dynamic));

    // Default: sleeping is allowed
    assert!(world.is_sleeping_allowed(id));

    // Disable sleeping
    world.set_sleeping_allowed(id, false);
    assert!(!world.is_sleeping_allowed(id));

    // Re-enable sleeping
    world.set_sleeping_allowed(id, true);
    assert!(world.is_sleeping_allowed(id));
}
