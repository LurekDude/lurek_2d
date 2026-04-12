use lurek2d::spine::{Bone, Skeleton, Slot};

// ── Bone ──

#[test]
fn bone_new_defaults() {
    let b = Bone::new("root");
    assert_eq!(b.name, "root");
    assert!(b.parent_index.is_none());
    assert!((b.local_x).abs() < 1e-5);
    assert!((b.local_y).abs() < 1e-5);
    assert!((b.local_rotation).abs() < 1e-5);
    assert!((b.local_scale_x - 1.0).abs() < 1e-5);
    assert!((b.local_scale_y - 1.0).abs() < 1e-5);
}

#[test]
fn bone_with_parent() {
    let b = Bone::with_parent("arm", 0, 10.0, 5.0);
    assert_eq!(b.name, "arm");
    assert_eq!(b.parent_index, Some(0));
    assert!((b.local_x - 10.0).abs() < 1e-5);
    assert!((b.local_y - 5.0).abs() < 1e-5);
}

// ── Slot ──

#[test]
fn slot_new_defaults() {
    let s = Slot::new("body", 0);
    assert_eq!(s.name, "body");
    assert_eq!(s.bone_index, 0);
    assert!((s.color_r - 1.0).abs() < 1e-5);
    assert!((s.color_g - 1.0).abs() < 1e-5);
    assert!((s.color_b - 1.0).abs() < 1e-5);
    assert!((s.color_a - 1.0).abs() < 1e-5);
    assert!(s.attachment_name.is_none());
    assert_eq!(s.draw_order, 0);
}

// ── Skeleton basics ──

#[test]
fn skeleton_new_empty() {
    let sk = Skeleton::new("hero");
    assert_eq!(sk.name, "hero");
    assert!(sk.bones.is_empty());
    assert!(sk.slots.is_empty());
    assert!((sk.x).abs() < 1e-5);
    assert!((sk.y).abs() < 1e-5);
    assert!((sk.scale_x - 1.0).abs() < 1e-5);
    assert!((sk.scale_y - 1.0).abs() < 1e-5);
}

#[test]
fn skeleton_add_bone_returns_index() {
    let mut sk = Skeleton::new("test");
    let i0 = sk.add_bone(Bone::new("root"));
    let i1 = sk.add_bone(Bone::with_parent("child", 0, 1.0, 0.0));
    assert_eq!(i0, 0);
    assert_eq!(i1, 1);
    assert_eq!(sk.bones.len(), 2);
}

#[test]
fn skeleton_add_slot_returns_index() {
    let mut sk = Skeleton::new("test");
    sk.add_bone(Bone::new("root"));
    let si = sk.add_slot(Slot::new("body", 0));
    assert_eq!(si, 0);
    assert_eq!(sk.slots.len(), 1);
}

#[test]
fn skeleton_find_bone_by_name() {
    let mut sk = Skeleton::new("test");
    sk.add_bone(Bone::new("root"));
    sk.add_bone(Bone::with_parent("arm", 0, 1.0, 0.0));
    assert_eq!(sk.find_bone("arm"), Some(1));
    assert_eq!(sk.find_bone("missing"), None);
}

#[test]
fn skeleton_find_slot_by_name() {
    let mut sk = Skeleton::new("test");
    sk.add_bone(Bone::new("root"));
    sk.add_slot(Slot::new("body", 0));
    assert_eq!(sk.find_slot("body"), Some(0));
    assert_eq!(sk.find_slot("missing"), None);
}

// ── World transform propagation ──

#[test]
fn update_world_transforms_single_root() {
    let mut sk = Skeleton::new("test");
    sk.x = 100.0;
    sk.y = 200.0;
    let mut root = Bone::new("root");
    root.local_x = 10.0;
    root.local_y = 20.0;
    sk.add_bone(root);

    sk.update_world_transforms();

    assert!((sk.bones[0].world_x - 110.0).abs() < 1e-5);
    assert!((sk.bones[0].world_y - 220.0).abs() < 1e-5);
}

#[test]
fn update_world_transforms_parent_child_offset() {
    let mut sk = Skeleton::new("test");
    sk.x = 0.0;
    sk.y = 0.0;
    sk.add_bone(Bone::new("root"));
    sk.add_bone(Bone::with_parent("child", 0, 50.0, 30.0));

    sk.update_world_transforms();

    // Root at origin
    assert!((sk.bones[0].world_x).abs() < 1e-5);
    assert!((sk.bones[0].world_y).abs() < 1e-5);
    // Child translated
    assert!((sk.bones[1].world_x - 50.0).abs() < 1e-5);
    assert!((sk.bones[1].world_y - 30.0).abs() < 1e-5);
}

#[test]
fn update_world_transforms_parent_rotated_90() {
    let mut sk = Skeleton::new("test");
    let mut root = Bone::new("root");
    root.local_rotation = std::f32::consts::FRAC_PI_2; // 90 degrees
    sk.add_bone(root);
    sk.add_bone(Bone::with_parent("child", 0, 10.0, 0.0));

    sk.update_world_transforms();

    // Child at (10,0) local should end up at approximately (0,10) world
    assert!((sk.bones[1].world_x).abs() < 1e-4);
    assert!((sk.bones[1].world_y - 10.0).abs() < 1e-4);
}

#[test]
fn update_world_transforms_scale_propagation() {
    let mut sk = Skeleton::new("test");
    sk.scale_x = 2.0;
    sk.scale_y = 3.0;
    sk.add_bone(Bone::new("root"));
    sk.add_bone(Bone::with_parent("child", 0, 10.0, 10.0));

    sk.update_world_transforms();

    // Root: scale applied
    assert!((sk.bones[0].world_scale_x - 2.0).abs() < 1e-5);
    assert!((sk.bones[0].world_scale_y - 3.0).abs() < 1e-5);
    // Child inherits parent scale
    assert!((sk.bones[1].world_scale_x - 2.0).abs() < 1e-5);
    assert!((sk.bones[1].world_scale_y - 3.0).abs() < 1e-5);
    // Child position affected by parent scale
    assert!((sk.bones[1].world_x - 20.0).abs() < 1e-5); // 10 * 2
    assert!((sk.bones[1].world_y - 30.0).abs() < 1e-5); // 10 * 3
}

#[test]
fn update_world_transforms_chain_of_three() {
    let mut sk = Skeleton::new("test");
    sk.add_bone(Bone::new("root"));
    sk.add_bone(Bone::with_parent("mid", 0, 10.0, 0.0));
    sk.add_bone(Bone::with_parent("tip", 1, 5.0, 0.0));

    sk.update_world_transforms();

    assert!((sk.bones[0].world_x).abs() < 1e-5);
    assert!((sk.bones[1].world_x - 10.0).abs() < 1e-5);
    assert!((sk.bones[2].world_x - 15.0).abs() < 1e-5);
}
