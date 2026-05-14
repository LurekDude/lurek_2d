//! rapier2d-backed 2D physics world: bodies, joints, raycasting, zones, and one-way platforms.
//! `World` owns the full simulation state and is the only entry point for the physics Lua bindings.
//! Raw rapier handles never leave this module; callers use opaque `usize` body/joint ids.

use super::body::{Body, BodyShape, BodyType};
use super::shape::Shape;
use super::zone::{PhysicsZone, ZoneEvent, ZoneGravityMode, ZoneTracker};
#[allow(unused_imports)]
use crate::log_msg;
use crate::runtime::log_messages::{P001_PULLEY_JOINT_FALLBACK, P002_GEAR_JOINT_FALLBACK};
use rapier2d::prelude::*;
use std::collections::HashMap;
use std::sync::Mutex;

/// Internal rapier event sink forwarding collision events through a mutex.
struct LocalEventCollector {
    /// Buffered collision events awaiting drain.
    events: Mutex<Vec<CollisionEvent>>,
}
/// `LocalEventCollector` construction and drain.
impl LocalEventCollector {
    /// Create an empty event collector.
    fn new() -> Self {
        Self {
            events: Mutex::new(Vec::new()),
        }
    }
    /// Drain all buffered events and return them.
    fn drain(&self) -> Vec<CollisionEvent> {
        self.events
            .lock()
            .expect("event mutex not poisoned")
            .drain(..)
            .collect()
    }
}
/// Satisfies rapier `EventHandler` by storing events in the mutex.
impl EventHandler for LocalEventCollector {
    /// Push the collision event into the buffer.
    fn handle_collision_event(
        &self,
        _bodies: &RigidBodySet,
        _colliders: &ColliderSet,
        event: CollisionEvent,
        _contact_pair: Option<&ContactPair>,
    ) {
        self.events
            .lock()
            .expect("event mutex not poisoned")
            .push(event);
    }
    /// No-op; contact force events are not used.
    fn handle_contact_force_event(
        &self,
        _dt: f32,
        _bodies: &RigidBodySet,
        _colliders: &ColliderSet,
        _contact_pair: &ContactPair,
        _total_force_magnitude: f32,
    ) {
    }
}
/// A pair of body ids that have started or are overlapping.
pub struct BodyContact {
    /// First body id.
    pub body_a: usize,
    /// Second body id.
    pub body_b: usize,
}
/// The closest raycast intersection result.
#[derive(Debug, Clone, Copy)]
pub struct RaycastHit {
    /// Body id that was hit.
    pub body_id: usize,
    /// World-space hit point.
    pub point: (f32, f32),
    /// Outward surface normal at the hit point.
    pub normal: (f32, f32),
    /// Parametric distance along the ray.
    pub toi: f32,
}
/// Contact information between two bodies.
#[derive(Debug, Clone)]
pub struct ContactInfo {
    /// First body id.
    pub body_a: usize,
    /// Second body id.
    pub body_b: usize,
    /// Contact normal x component.
    pub normal_x: f32,
    /// Contact normal y component.
    pub normal_y: f32,
    /// True when the bodies are currently touching.
    pub is_touching: bool,
}
/// Snapshot of a physics shape used for debug rendering.
pub struct PhysicsShapeSnapshot {
    /// World-space x centre.
    pub x: f32,
    /// World-space y centre.
    pub y: f32,
    /// Half-width for AABB shapes.
    pub half_w: f32,
    /// Half-height for AABB shapes.
    pub half_h: f32,
    /// Rotation in radians.
    pub angle: f32,
    /// True when the body is static.
    pub is_static: bool,
    /// True when the body is sleeping.
    pub is_sleeping: bool,
    /// True when the collider is a sensor.
    pub is_sensor: bool,
    /// True when the shape is a circle.
    pub is_circle: bool,
    /// Convex hull vertices for polygon shapes.
    pub hull_verts: Vec<[f32; 2]>,
}
/// Full rapier2d-backed simulation world.
pub struct World {
    /// Mirror of rapier rigid bodies for Lua-readable state.
    bodies: Vec<Body>,
    /// Rapier handles corresponding to each `bodies` entry.
    body_handles: Vec<RigidBodyHandle>,
    /// Primary collider handle per body.
    collider_handles: Vec<ColliderHandle>,
    /// Additional collider handles per body (multi-fixture).
    extra_collider_handles: Vec<Vec<ColliderHandle>>,
    /// Reverse map from collider handle to body id.
    collider_to_body: HashMap<ColliderHandle, usize>,
    /// Cached shape discriminants used for collision filtering.
    cached_shapes: Vec<BodyShape>,
    /// Cached restitution values per body.
    cached_restitutions: Vec<f32>,
    /// Cached `(layer, mask)` pairs per body.
    cached_layers: Vec<(u32, u32)>,
    /// Cached friction values per body.
    cached_frictions: Vec<f32>,
    /// rapier pipeline — runs the simulation substep.
    pipeline: PhysicsPipeline,
    /// Gravity vector applied to dynamic bodies each step.
    gravity: Vector,
    /// rapier integration tuning parameters.
    params: IntegrationParameters,
    /// rapier island manager for sleeping bodies.
    islands: IslandManager,
    /// rapier broad-phase BVH accelerator.
    broad_phase: BroadPhaseBvh,
    /// rapier narrow-phase contact generator.
    narrow_phase: NarrowPhase,
    /// rapier rigid body storage.
    rbodies: RigidBodySet,
    /// rapier collider storage.
    rcolliders: ColliderSet,
    /// rapier impulse joint storage.
    impulse_joints: ImpulseJointSet,
    /// rapier multibody joint storage (unused but required by pipeline).
    multibody_joints: MultibodyJointSet,
    /// rapier CCD solver.
    ccd_solver: CCDSolver,
    /// rapier joint handles indexed by joint id.
    joint_handles: Vec<ImpulseJointHandle>,
    /// Overlap/touching events emitted last step.
    collision_events: Vec<BodyContact>,
    /// Pairs that started touching last step.
    begin_contact_events: Vec<(usize, usize)>,
    /// Pairs that stopped touching last step.
    end_contact_events: Vec<(usize, usize)>,
    /// Joint type string per joint id.
    joint_types: Vec<&'static str>,
    /// Anchor body id per mouse-joint id.
    mouse_joint_anchors: HashMap<usize, usize>,
    /// Pixels-to-meter conversion factor.
    pixels_per_meter: f32,
    /// Max force before auto-breaking per joint id.
    joint_break_forces: HashMap<usize, f32>,
    /// One-way platform normal per body id; `None` means standard two-way.
    one_way_normals: Vec<Option<(f32, f32)>>,
    /// Active trigger zones.
    zones: Vec<PhysicsZone>,
    /// Monotonically increasing id for zones.
    zone_id_counter: usize,
    /// Tracks which bodies are inside each zone.
    zone_tracker: ZoneTracker,
    /// Zone enter/exit events emitted last step.
    zone_events: Vec<ZoneEvent>,
}
impl World {
    /// Draw all body outlines onto an RGBA `ImageData` using the given colour.
    pub fn draw_debug_to_image(
        &self,
        img: &mut crate::image::ImageData,
        r: u8,
        g: u8,
        b: u8,
        a: u8,
    ) {
        for body in self.bodies.iter() {
            let cx = body.position.x as i32;
            let cy = body.position.y as i32;
            let angle = body.angle;
            if let Some(ref ext) = body.shape_ext {
                match ext {
                    crate::physics::shape::Shape::Rect { width, height } => {
                        let hw = *width / 2.0;
                        let hh = *height / 2.0;
                        let p0 = crate::math::Vec2 { x: -hw, y: -hh }.rotate(angle) + body.position;
                        let p1 = crate::math::Vec2 { x: hw, y: -hh }.rotate(angle) + body.position;
                        let p2 = crate::math::Vec2 { x: hw, y: hh }.rotate(angle) + body.position;
                        let p3 = crate::math::Vec2 { x: -hw, y: hh }.rotate(angle) + body.position;
                        img.draw_line(
                            p0.x.round() as i32,
                            p0.y.round() as i32,
                            p1.x.round() as i32,
                            p1.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                        img.draw_line(
                            p1.x.round() as i32,
                            p1.y.round() as i32,
                            p2.x.round() as i32,
                            p2.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                        img.draw_line(
                            p2.x.round() as i32,
                            p2.y.round() as i32,
                            p3.x.round() as i32,
                            p3.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                        img.draw_line(
                            p3.x.round() as i32,
                            p3.y.round() as i32,
                            p0.x.round() as i32,
                            p0.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                    }
                    crate::physics::shape::Shape::Circle { radius } => {
                        img.draw_circle(cx, cy, *radius as u32, r, g, b, a);
                        let ex = cx + (angle.cos() * radius) as i32;
                        let ey = cy + (angle.sin() * radius) as i32;
                        img.draw_line(cx, cy, ex, ey, r, g, b, a);
                    }
                    crate::physics::shape::Shape::Polygon { vertices } => {
                        for i in 0..vertices.len() {
                            let p0 = vertices[i].rotate(angle) + body.position;
                            let p1 =
                                vertices[(i + 1) % vertices.len()].rotate(angle) + body.position;
                            img.draw_line(
                                p0.x.round() as i32,
                                p0.y.round() as i32,
                                p1.x.round() as i32,
                                p1.y.round() as i32,
                                r,
                                g,
                                b,
                                a,
                            );
                        }
                    }
                    crate::physics::shape::Shape::Edge { v1, v2 } => {
                        let p0 = v1.rotate(angle) + body.position;
                        let p1 = v2.rotate(angle) + body.position;
                        img.draw_line(
                            p0.x.round() as i32,
                            p0.y.round() as i32,
                            p1.x.round() as i32,
                            p1.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                    }
                    crate::physics::shape::Shape::Chain { vertices, closed } => {
                        for i in 0..vertices.len() - 1 {
                            let p0 = vertices[i].rotate(angle) + body.position;
                            let p1 = vertices[i + 1].rotate(angle) + body.position;
                            img.draw_line(
                                p0.x.round() as i32,
                                p0.y.round() as i32,
                                p1.x.round() as i32,
                                p1.y.round() as i32,
                                r,
                                g,
                                b,
                                a,
                            );
                        }
                        if *closed && vertices.len() > 2 {
                            let p0 = vertices[vertices.len() - 1].rotate(angle) + body.position;
                            let p1 = vertices[0].rotate(angle) + body.position;
                            img.draw_line(
                                p0.x.round() as i32,
                                p0.y.round() as i32,
                                p1.x.round() as i32,
                                p1.y.round() as i32,
                                r,
                                g,
                                b,
                                a,
                            );
                        }
                    }
                }
            } else {
                match body.shape {
                    super::body::BodyShape::Rect { width, height } => {
                        let hw = width / 2.0;
                        let hh = height / 2.0;
                        let p0 = crate::math::Vec2 { x: -hw, y: -hh }.rotate(angle) + body.position;
                        let p1 = crate::math::Vec2 { x: hw, y: -hh }.rotate(angle) + body.position;
                        let p2 = crate::math::Vec2 { x: hw, y: hh }.rotate(angle) + body.position;
                        let p3 = crate::math::Vec2 { x: -hw, y: hh }.rotate(angle) + body.position;
                        img.draw_line(
                            p0.x.round() as i32,
                            p0.y.round() as i32,
                            p1.x.round() as i32,
                            p1.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                        img.draw_line(
                            p1.x.round() as i32,
                            p1.y.round() as i32,
                            p2.x.round() as i32,
                            p2.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                        img.draw_line(
                            p2.x.round() as i32,
                            p2.y.round() as i32,
                            p3.x.round() as i32,
                            p3.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                        img.draw_line(
                            p3.x.round() as i32,
                            p3.y.round() as i32,
                            p0.x.round() as i32,
                            p0.y.round() as i32,
                            r,
                            g,
                            b,
                            a,
                        );
                    }
                    super::body::BodyShape::Circle { radius } => {
                        img.draw_circle(cx, cy, radius as u32, r, g, b, a);
                        let ex = cx + (angle.cos() * radius) as i32;
                        let ey = cy + (angle.sin() * radius) as i32;
                        img.draw_line(cx, cy, ex, ey, r, g, b, a);
                    }
                }
            }
        }
    }
    /// Return a snapshot of all body shapes suitable for debug rendering.
    pub fn extract_shape_snapshots(&self) -> Vec<PhysicsShapeSnapshot> {
        let mut out = Vec::with_capacity(self.bodies.len());
        for (idx, body) in self.bodies.iter().enumerate() {
            let is_sleeping = self
                .body_handles
                .get(idx)
                .and_then(|h| self.rbodies.get(*h))
                .map(|rb| rb.is_sleeping())
                .unwrap_or(false);
            let is_static = matches!(
                body.body_type,
                crate::physics::body::BodyType::Static | crate::physics::body::BodyType::Kinematic
            );
            let is_sensor = body.body_type == crate::physics::body::BodyType::Sensor;
            let angle = body.angle;
            let (is_circle, half_w, half_h, hull_verts) = if let Some(ref ext) = body.shape_ext {
                match ext {
                    crate::physics::shape::Shape::Circle { radius } => {
                        (true, *radius, *radius, vec![])
                    }
                    crate::physics::shape::Shape::Rect { width, height } => {
                        (false, width / 2.0, height / 2.0, vec![])
                    }
                    crate::physics::shape::Shape::Polygon { vertices }
                    | crate::physics::shape::Shape::Chain { vertices, .. } => {
                        let verts = vertices
                            .iter()
                            .map(|v| [v.x, v.y])
                            .collect::<Vec<[f32; 2]>>();
                        let (hw, hh) = if verts.is_empty() {
                            (8.0, 8.0)
                        } else {
                            let max_x = verts.iter().map(|v| v[0].abs()).fold(0.0_f32, f32::max);
                            let max_y = verts.iter().map(|v| v[1].abs()).fold(0.0_f32, f32::max);
                            (max_x, max_y)
                        };
                        (false, hw, hh, verts)
                    }
                    crate::physics::shape::Shape::Edge { v1, v2 } => {
                        let hw = ((v2.x - v1.x).abs() / 2.0).max(1.0);
                        let hh = ((v2.y - v1.y).abs() / 2.0).max(1.0);
                        let verts = vec![[v1.x, v1.y], [v2.x, v2.y]];
                        (false, hw, hh, verts)
                    }
                }
            } else {
                match body.shape {
                    super::body::BodyShape::Rect { width, height } => {
                        (false, width / 2.0, height / 2.0, vec![])
                    }
                    super::body::BodyShape::Circle { radius } => (true, radius, radius, vec![]),
                }
            };
            out.push(PhysicsShapeSnapshot {
                x: body.position.x,
                y: body.position.y,
                half_w,
                half_h,
                angle,
                is_static,
                is_sleeping,
                is_sensor,
                is_circle,
                hull_verts,
            });
        }
        out
    }
    /// Create a world with gravity `(gx, gy)` in pixels/s².
    pub fn new(gx: f32, gy: f32) -> Self {
        World {
            bodies: Vec::new(),
            body_handles: Vec::new(),
            collider_handles: Vec::new(),
            extra_collider_handles: Vec::new(),
            collider_to_body: HashMap::new(),
            cached_shapes: Vec::new(),
            cached_restitutions: Vec::new(),
            cached_layers: Vec::new(),
            cached_frictions: Vec::new(),
            pipeline: PhysicsPipeline::new(),
            gravity: Vector::new(gx, gy),
            params: IntegrationParameters::default(),
            islands: IslandManager::new(),
            broad_phase: BroadPhaseBvh::new(),
            narrow_phase: NarrowPhase::new(),
            rbodies: RigidBodySet::new(),
            rcolliders: ColliderSet::new(),
            impulse_joints: ImpulseJointSet::new(),
            multibody_joints: MultibodyJointSet::new(),
            ccd_solver: CCDSolver::new(),
            joint_handles: Vec::new(),
            collision_events: Vec::new(),
            begin_contact_events: Vec::new(),
            end_contact_events: Vec::new(),
            joint_types: Vec::new(),
            mouse_joint_anchors: HashMap::new(),
            pixels_per_meter: 1.0,
            joint_break_forces: HashMap::new(),
            one_way_normals: Vec::new(),
            zones: Vec::new(),
            zone_id_counter: 0,
            zone_tracker: ZoneTracker::new(),
            zone_events: Vec::new(),
        }
    }
    /// Map `BodyType` to the equivalent rapier `RigidBodyType`.
    fn rapier_body_type(bt: BodyType) -> RigidBodyType {
        match bt {
            BodyType::Static | BodyType::Sensor => RigidBodyType::Fixed,
            BodyType::Dynamic => RigidBodyType::Dynamic,
            BodyType::Kinematic => RigidBodyType::KinematicPositionBased,
        }
    }
    /// Build a rapier `Collider` from a body's shape and filter settings.
    fn make_collider(body: &Body) -> Collider {
        let is_sensor = body.body_type == BodyType::Sensor;
        let memberships = Group::from_bits_truncate(body.layer);
        let filters = Group::from_bits_truncate(body.mask);
        let groups = InteractionGroups::new(memberships, filters, InteractionTestMode::And);
        let builder = if let Some(ref shape_ext) = body.shape_ext {
            shape_ext
                .to_rapier_collider()
                .unwrap_or_else(|| match body.shape {
                    BodyShape::Rect { width, height } => {
                        ColliderBuilder::cuboid(width / 2.0, height / 2.0)
                    }
                    BodyShape::Circle { radius } => ColliderBuilder::ball(radius),
                })
        } else {
            match body.shape {
                BodyShape::Rect { width, height } => {
                    ColliderBuilder::cuboid(width / 2.0, height / 2.0)
                }
                BodyShape::Circle { radius } => ColliderBuilder::ball(radius),
            }
        };
        builder
            .sensor(is_sensor)
            .restitution(body.restitution)
            .friction(body.friction)
            .collision_groups(groups)
            .active_events(ActiveEvents::COLLISION_EVENTS)
            .build()
    }
    /// Recreate the primary collider for `id` from the current body state.
    fn rebuild_collider(&mut self, id: usize) {
        let old_handle = self.collider_handles[id];
        let body_handle = self.body_handles[id];
        let (shape, shape_ext, restitution, friction, layer, mask, is_sensor) = {
            let b = &self.bodies[id];
            (
                b.shape,
                b.shape_ext.clone(),
                b.restitution,
                b.friction,
                b.layer,
                b.mask,
                b.body_type == BodyType::Sensor,
            )
        };
        self.rcolliders
            .remove(old_handle, &mut self.islands, &mut self.rbodies, true);
        let memberships = Group::from_bits_truncate(layer);
        let filters = Group::from_bits_truncate(mask);
        let groups = InteractionGroups::new(memberships, filters, InteractionTestMode::And);
        let builder = if let Some(ref ext) = shape_ext {
            ext.to_rapier_collider().unwrap_or_else(|| match shape {
                BodyShape::Rect { width, height } => {
                    ColliderBuilder::cuboid(width / 2.0, height / 2.0)
                }
                BodyShape::Circle { radius } => ColliderBuilder::ball(radius),
            })
        } else {
            match shape {
                BodyShape::Rect { width, height } => {
                    ColliderBuilder::cuboid(width / 2.0, height / 2.0)
                }
                BodyShape::Circle { radius } => ColliderBuilder::ball(radius),
            }
        };
        let collider = builder
            .sensor(is_sensor)
            .restitution(restitution)
            .friction(friction)
            .collision_groups(groups)
            .active_events(ActiveEvents::COLLISION_EVENTS)
            .build();
        let new_handle =
            self.rcolliders
                .insert_with_parent(collider, body_handle, &mut self.rbodies);
        self.collider_to_body.remove(&old_handle);
        self.collider_to_body.insert(new_handle, id);
        self.collider_handles[id] = new_handle;
        self.cached_shapes[id] = shape;
        self.cached_restitutions[id] = restitution;
        self.cached_frictions[id] = friction;
        self.cached_layers[id] = (layer, mask);
    }
    /// Look up the body id that owns `handle`.
    fn body_for_collider(&self, handle: ColliderHandle) -> Option<usize> {
        self.collider_to_body.get(&handle).copied()
    }
    /// Insert a body into the world and return its id.
    pub fn add_body(&mut self, body: Body) -> usize {
        let id = self.bodies.len();
        let rb = RigidBodyBuilder::new(Self::rapier_body_type(body.body_type))
            .translation(Vector::new(body.position.x, body.position.y))
            .linvel(Vector::new(body.velocity.x, body.velocity.y))
            .build();
        let body_handle = self.rbodies.insert(rb);
        let collider = Self::make_collider(&body);
        let collider_handle =
            self.rcolliders
                .insert_with_parent(collider, body_handle, &mut self.rbodies);
        self.cached_shapes.push(body.shape);
        self.cached_restitutions.push(body.restitution);
        self.cached_frictions.push(body.friction);
        self.cached_layers.push((body.layer, body.mask));
        self.body_handles.push(body_handle);
        self.collider_handles.push(collider_handle);
        self.extra_collider_handles.push(Vec::new());
        self.collider_to_body.insert(collider_handle, id);
        self.bodies.push(body);
        self.one_way_normals.push(None);
        id
    }
    /// Add an extra collider shape to an existing body; returns the fixture index.
    pub fn add_fixture(
        &mut self,
        body_id: usize,
        shape: Shape,
        density: f32,
        friction: f32,
        restitution: f32,
        sensor: bool,
    ) -> usize {
        let body_handle = match self.body_handles.get(body_id).copied() {
            Some(h) => h,
            None => return 0,
        };
        let builder = shape
            .to_rapier_collider()
            .unwrap_or_else(|| ColliderBuilder::cuboid(0.5, 0.5));
        let collider = builder
            .density(density)
            .friction(friction)
            .restitution(restitution)
            .sensor(sensor)
            .active_events(ActiveEvents::COLLISION_EVENTS)
            .build();
        let handle = self
            .rcolliders
            .insert_with_parent(collider, body_handle, &mut self.rbodies);
        self.collider_to_body.insert(handle, body_id);
        let extras = &mut self.extra_collider_handles[body_id];
        extras.push(handle);
        extras.len()
    }
    /// Return the number of colliders attached to `body_id`.
    pub fn fixture_count(&self, body_id: usize) -> usize {
        if body_id >= self.bodies.len() {
            return 0;
        }
        1 + self.extra_collider_handles[body_id].len()
    }
    /// Set friction on a specific fixture of `body_id`.
    pub fn set_fixture_friction(&mut self, body_id: usize, fixture_idx: usize, friction: f32) {
        let handle = if fixture_idx == 0 {
            self.collider_handles.get(body_id).copied()
        } else {
            self.extra_collider_handles
                .get(body_id)
                .and_then(|v| v.get(fixture_idx - 1))
                .copied()
        };
        if let Some(h) = handle {
            if let Some(col) = self.rcolliders.get_mut(h) {
                col.set_friction(friction);
            }
        }
    }
    /// Set restitution (bounciness) on a specific fixture of `body_id`.
    pub fn set_fixture_restitution(
        &mut self,
        body_id: usize,
        fixture_idx: usize,
        restitution: f32,
    ) {
        let handle = if fixture_idx == 0 {
            self.collider_handles.get(body_id).copied()
        } else {
            self.extra_collider_handles
                .get(body_id)
                .and_then(|v| v.get(fixture_idx - 1))
                .copied()
        };
        if let Some(h) = handle {
            if let Some(col) = self.rcolliders.get_mut(h) {
                col.set_restitution(restitution);
            }
        }
    }
    /// Enable or disable the sensor flag on a specific fixture of `body_id`.
    pub fn set_fixture_sensor(&mut self, body_id: usize, fixture_idx: usize, sensor: bool) {
        let handle = if fixture_idx == 0 {
            self.collider_handles.get(body_id).copied()
        } else {
            self.extra_collider_handles
                .get(body_id)
                .and_then(|v| v.get(fixture_idx - 1))
                .copied()
        };
        if let Some(h) = handle {
            if let Some(col) = self.rcolliders.get_mut(h) {
                col.set_sensor(sensor);
            }
        }
    }
    /// Return a shared reference to body `id`, or `None` if out of range.
    pub fn get_body(&self, id: usize) -> Option<&Body> {
        self.bodies.get(id)
    }
    /// Return a mutable reference to body `id`, or `None` if out of range.
    pub fn get_body_mut(&mut self, id: usize) -> Option<&mut Body> {
        self.bodies.get_mut(id)
    }
    /// Return the total number of bodies in the world.
    pub fn body_count(&self) -> usize {
        self.bodies.len()
    }
    /// Add a revolute joint between two bodies at the given local anchor; return joint id.
    pub fn add_revolute_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        anchor_x: f32,
        anchor_y: f32,
    ) -> usize {
        let ha = match self.body_handles.get(body_a).copied() {
            Some(h) => h,
            None => return 0,
        };
        let hb = match self.body_handles.get(body_b).copied() {
            Some(h) => h,
            None => return 0,
        };
        let joint = RevoluteJointBuilder::new()
            .local_anchor1(Vector::new(anchor_x, anchor_y))
            .local_anchor2(Vector::new(0.0_f32, 0.0_f32))
            .build();
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let id = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("revolute");
        id
    }
    /// Cast a ray from `(x1,y1)` to `(x2,y2)` and return the first hit, or `None`.
    pub fn raycast(&self, x1: f32, y1: f32, x2: f32, y2: f32) -> Option<RaycastHit> {
        let dir = Vector::new(x2 - x1, y2 - y1);
        let max_toi = dir.length();
        if max_toi < 1e-6 {
            return None;
        }
        let unit_dir = dir / max_toi;
        let ray = Ray::new(Vector::new(x1, y1), unit_dir);
        let mut best_toi = max_toi;
        let mut best_hit: Option<RaycastHit> = None;
        for (i, &col_handle) in self.collider_handles.iter().enumerate() {
            if let Some(col) = self.rcolliders.get(col_handle) {
                if let Some(ri) =
                    col.shape()
                        .cast_ray_and_get_normal(col.position(), &ray, best_toi, true)
                {
                    let toi = ri.time_of_impact;
                    let pt_x = ray.origin.x + ray.dir.x * toi;
                    let pt_y = ray.origin.y + ray.dir.y * toi;
                    best_toi = toi;
                    best_hit = Some(RaycastHit {
                        body_id: i,
                        point: (pt_x, pt_y),
                        normal: (ri.normal.x, ri.normal.y),
                        toi,
                    });
                }
            }
        }
        best_hit
    }
    /// Step the simulation by `dt` seconds; synchronises body state with rapier.
    pub fn step(&mut self, dt: f32) {
        self.params.dt = dt;
        self.collision_events.clear();
        self.begin_contact_events.clear();
        self.end_contact_events.clear();
        let n = self.bodies.len();
        let rebuild_ids: Vec<usize> = (0..n)
            .filter(|&i| {
                let b = &self.bodies[i];
                b.shape != self.cached_shapes[i]
                    || (b.restitution - self.cached_restitutions[i]).abs() > 1e-6
                    || (b.friction - self.cached_frictions[i]).abs() > 1e-6
                    || (b.layer, b.mask) != self.cached_layers[i]
            })
            .collect();
        for i in rebuild_ids {
            self.rebuild_collider(i);
        }
        let sync: Vec<(f32, f32, f32, f32, f32, f32, BodyType)> = self
            .bodies
            .iter()
            .map(|b| {
                (
                    b.position.x,
                    b.position.y,
                    b.velocity.x,
                    b.velocity.y,
                    b.angle,
                    b.angular_velocity,
                    b.body_type,
                )
            })
            .collect();
        for (i, &(px, py, vx, vy, angle, angvel, bt)) in sync.iter().enumerate() {
            let handle = self.body_handles[i];
            if let Some(rb) = self.rbodies.get_mut(handle) {
                match bt {
                    BodyType::Dynamic => {
                        rb.set_translation(Vector::new(px, py), true);
                        rb.set_rotation(Rotation::new(angle), true);
                        rb.set_linvel(Vector::new(vx, vy), true);
                        rb.set_angvel(angvel, true);
                    }
                    BodyType::Kinematic => {
                        rb.set_next_kinematic_translation(Vector::new(px, py));
                        rb.set_next_kinematic_rotation(Rotation::new(angle));
                    }
                    _ => {
                        rb.set_translation(Vector::new(px, py), true);
                        rb.set_rotation(Rotation::new(angle), true);
                    }
                }
            }
        }
        self.apply_zone_forces(dt);
        let event_col = LocalEventCollector::new();
        self.pipeline.step(
            self.gravity,
            &self.params,
            &mut self.islands,
            &mut self.broad_phase,
            &mut self.narrow_phase,
            &mut self.rbodies,
            &mut self.rcolliders,
            &mut self.impulse_joints,
            &mut self.multibody_joints,
            &mut self.ccd_solver,
            &(),
            &event_col,
        );
        for i in 0..n {
            let bt = self.bodies[i].body_type;
            if bt != BodyType::Dynamic && bt != BodyType::Kinematic {
                continue;
            }
            let handle = self.body_handles[i];
            let (tx, ty, vx, vy, angle, angvel) = match self.rbodies.get(handle) {
                Some(rb) => {
                    let t = rb.translation();
                    let v = rb.linvel();
                    (t.x, t.y, v.x, v.y, rb.rotation().angle(), rb.angvel())
                }
                None => continue,
            };
            self.bodies[i].position.x = tx;
            self.bodies[i].position.y = ty;
            self.bodies[i].velocity.x = vx;
            self.bodies[i].velocity.y = vy;
            self.bodies[i].angle = angle;
            self.bodies[i].angular_velocity = angvel;
        }
        for event in event_col.drain() {
            let ca = event.collider1();
            let cb = event.collider2();
            let id_a = self.body_for_collider(ca);
            let id_b = self.body_for_collider(cb);
            if let (Some(a), Some(b)) = (id_a, id_b) {
                if event.started() {
                    self.collision_events.push(BodyContact {
                        body_a: a,
                        body_b: b,
                    });
                    self.begin_contact_events.push((a, b));
                } else {
                    self.end_contact_events.push((a, b));
                }
            }
        }
        if !self.joint_break_forces.is_empty() {
            let breakable: Vec<(usize, ImpulseJointHandle, f32)> = self
                .joint_handles
                .iter()
                .enumerate()
                .filter_map(|(jid, &handle)| {
                    let &limit = self.joint_break_forces.get(&jid)?;
                    Some((jid, handle, limit))
                })
                .collect();
            let to_break: Vec<usize> = breakable
                .into_iter()
                .filter_map(|(jid, handle, limit)| {
                    let joint = self.impulse_joints.get(handle)?;
                    let rb1 = self.rbodies.get(joint.body1)?;
                    let rb2 = self.rbodies.get(joint.body2)?;
                    let v1 = rb1.linvel();
                    let v2 = rb2.linvel();
                    let dvx = v1.x - v2.x;
                    let dvy = v1.y - v2.y;
                    let rel_mag = (dvx * dvx + dvy * dvy).sqrt();
                    if rel_mag > limit {
                        Some(jid)
                    } else {
                        None
                    }
                })
                .collect();
            for jid in to_break {
                if let Some(&handle) = self.joint_handles.get(jid) {
                    self.impulse_joints.remove(handle, true);
                }
                self.joint_break_forces.remove(&jid);
            }
        }
        let contact_pairs: Vec<(usize, usize)> = self.begin_contact_events.clone();
        for (a, b) in contact_pairs {
            for (platform_id, mover_id) in [(a, b), (b, a)] {
                if let Some(&Some((nx, ny))) = self.one_way_normals.get(platform_id) {
                    if let Some(&handle) = self.body_handles.get(mover_id) {
                        if let Some(rb) = self.rbodies.get_mut(handle) {
                            let cv = rb.linvel();
                            let cdot = cv.x * nx + cv.y * ny;
                            if cdot < 0.0 {
                                rb.set_linvel(
                                    Vector::new(cv.x - cdot * nx, cv.y - cdot * ny),
                                    true,
                                );
                                if let Some(body_mut) = self.bodies.get_mut(mover_id) {
                                    let rv = body_mut.velocity.x * nx + body_mut.velocity.y * ny;
                                    if rv < 0.0 {
                                        body_mut.velocity.x -= rv * nx;
                                        body_mut.velocity.y -= rv * ny;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    /// Apply a linear impulse `(ix, iy)` to body `id`.
    pub fn apply_impulse(&mut self, id: usize, ix: f32, iy: f32) {
        if let Some(body) = self.bodies.get_mut(id) {
            if body.body_type == BodyType::Dynamic {
                let inv_mass = if body.mass > 0.0 {
                    1.0 / body.mass
                } else {
                    0.0
                };
                body.velocity.x += ix * inv_mass;
                body.velocity.y += iy * inv_mass;
            }
        }
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.apply_impulse(Vector::new(ix, iy), true);
            }
        }
    }
    /// Return overlap events collected during the last `step`.
    pub fn get_collision_events(&self) -> &[BodyContact] {
        &self.collision_events
    }
    /// Return body-pair ids that began touching during the last `step`.
    pub fn get_begin_contact_events(&self) -> &[(usize, usize)] {
        &self.begin_contact_events
    }
    /// Return body-pair ids that stopped touching during the last `step`.
    pub fn get_end_contact_events(&self) -> &[(usize, usize)] {
        &self.end_contact_events
    }
    /// Register a trigger zone and return its id.
    pub fn add_zone(&mut self, mut zone: PhysicsZone) -> usize {
        let id = self.zone_id_counter;
        self.zone_id_counter += 1;
        zone.id = id;
        self.zones.push(zone);
        id
    }
    /// Remove the zone with the given id.
    pub fn remove_zone(&mut self, id: usize) {
        self.zones.retain(|z| z.id != id);
    }
    /// Return a mutable reference to zone `id`, or `None` if not found.
    pub fn zone_mut(&mut self, id: usize) -> Option<&mut PhysicsZone> {
        self.zones.iter_mut().find(|z| z.id == id)
    }
    /// Return zone enter/exit events from the last `step`.
    pub fn get_zone_events(&self) -> &[ZoneEvent] {
        &self.zone_events
    }
    /// Apply per-zone gravity/damping overrides to all bodies; updates zone enter/exit events.
    pub fn apply_zone_forces(&mut self, dt: f32) {
        if self.zones.is_empty() {
            return;
        }
        self.zone_events.clear();
        let mut sorted_indices: Vec<usize> = (0..self.zones.len()).collect();
        sorted_indices.sort_by(|&a, &b| self.zones[b].priority.cmp(&self.zones[a].priority));
        let n = self.bodies.len();
        for body_id in 0..n {
            let body = &self.bodies[body_id];
            if body.body_type != BodyType::Dynamic {
                continue;
            }
            let px = body.position.x;
            let py = body.position.y;
            let layer = body.layer;
            let mut current_zones = std::collections::HashSet::new();
            let mut gravity_applied = false;
            for &zi in &sorted_indices {
                let zone = &self.zones[zi];
                if !zone.enabled {
                    continue;
                }
                if zone.layer_mask & layer == 0 {
                    continue;
                }
                if !zone.boundary.contains(px, py) {
                    continue;
                }
                current_zones.insert(zone.id);
                if !gravity_applied {
                    gravity_applied = true;
                    let handle = self.body_handles[body_id];
                    if let Some(rb) = self.rbodies.get_mut(handle) {
                        match zone.gravity_mode {
                            ZoneGravityMode::Zero => {
                                let gx = -self.gravity.x * dt;
                                let gy = -self.gravity.y * dt;
                                rb.set_gravity_scale(0.0, true);
                                let _ = (gx, gy);
                            }
                            ZoneGravityMode::Directional { gx, gy } => {
                                rb.set_gravity_scale(0.0, true);
                                rb.add_force(Vector::new(rb.mass() * gx, rb.mass() * gy), true);
                            }
                            ZoneGravityMode::Point { cx, cy, strength } => {
                                let dx = cx - px;
                                let dy = cy - py;
                                let dist2 = (dx * dx + dy * dy).max(1.0);
                                let dist = dist2.sqrt();
                                let force = strength / dist2;
                                rb.set_gravity_scale(0.0, true);
                                rb.add_force(
                                    Vector::new(
                                        rb.mass() * force * dx / dist,
                                        rb.mass() * force * dy / dist,
                                    ),
                                    true,
                                );
                            }
                            ZoneGravityMode::Repulsor { cx, cy, strength } => {
                                let dx = px - cx;
                                let dy = py - cy;
                                let dist2 = (dx * dx + dy * dy).max(1.0);
                                let dist = dist2.sqrt();
                                let force = strength / dist2;
                                rb.set_gravity_scale(0.0, true);
                                rb.add_force(
                                    Vector::new(
                                        rb.mass() * force * dx / dist,
                                        rb.mass() * force * dy / dist,
                                    ),
                                    true,
                                );
                            }
                        }
                    }
                }
                let handle = self.body_handles[body_id];
                if let Some(rb) = self.rbodies.get_mut(handle) {
                    if let Some(ld) = zone.linear_damping_override {
                        rb.set_linear_damping(ld);
                    }
                    if let Some(ad) = zone.angular_damping_override {
                        rb.set_angular_damping(ad);
                    }
                }
            }
            if !gravity_applied {
                let handle = self.body_handles[body_id];
                if let Some(rb) = self.rbodies.get_mut(handle) {
                    if (rb.gravity_scale() - 1.0).abs() > 1e-4 {
                        rb.set_gravity_scale(1.0, true);
                    }
                }
            }
            let events = self.zone_tracker.update(body_id, current_zones);
            self.zone_events.extend(events);
        }
    }
    /// Run up to `max_steps` fixed substeps using `step_dt`; return steps taken and leftover dt.
    pub fn step_fixed(&mut self, accumulated_dt: f32, step_dt: f32, max_steps: u32) -> (u32, f32) {
        if step_dt <= 0.0 {
            return (0, accumulated_dt);
        }
        let steps = ((accumulated_dt / step_dt) as u32).min(max_steps);
        for _ in 0..steps {
            self.step(step_dt);
        }
        let remainder = accumulated_dt - steps as f32 * step_dt;
        (steps, remainder.max(0.0))
    }
    /// Teleport body `id` to world position `(x, y)`.
    pub fn set_body_position(&mut self, id: usize, x: f32, y: f32) {
        if let Some(body) = self.bodies.get_mut(id) {
            body.position.x = x;
            body.position.y = y;
        }
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_translation(Vector::new(x, y), true);
            }
        }
    }
    /// Apply a continuous force `(fx, fy)` to body `id` this step.
    pub fn apply_force(&mut self, id: usize, fx: f32, fy: f32) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.add_force(Vector::new(fx, fy), true);
            }
        }
    }
    /// Apply a torque to body `id` this step.
    pub fn apply_torque(&mut self, id: usize, torque: f32) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.add_torque(torque, true);
            }
        }
    }
    /// Set angular velocity of body `id` in radians/second.
    pub fn set_angular_velocity(&mut self, id: usize, omega: f32) {
        if let Some(body) = self.bodies.get_mut(id) {
            body.angular_velocity = omega;
        }
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_angvel(omega, true);
            }
        }
    }
    /// Return angular velocity of body `id` in radians/second; returns 0 if out of range.
    pub fn get_angular_velocity(&self, id: usize) -> f32 {
        self.bodies.get(id).map_or(0.0, |b| b.angular_velocity)
    }
    /// Return rotation angle of body `id` in radians; returns 0 if out of range.
    pub fn get_body_angle(&self, id: usize) -> f32 {
        self.bodies.get(id).map_or(0.0, |b| b.angle)
    }
    /// Set the rotation angle of body `id` in radians.
    pub fn set_body_angle(&mut self, id: usize, angle: f32) {
        if let Some(body) = self.bodies.get_mut(id) {
            body.angle = angle;
        }
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_rotation(Rotation::new(angle), true);
            }
        }
    }
    /// Return the mass of body `id`; returns 0 if out of range.
    pub fn get_body_mass(&self, id: usize) -> f32 {
        self.bodies.get(id).map_or(0.0, |b| b.mass)
    }
    /// Override mass of body `id`.
    pub fn set_body_mass(&mut self, id: usize, mass: f32) {
        if let Some(body) = self.bodies.get_mut(id) {
            body.mass = mass;
        }
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                let props = rb.mass_properties();
                rb.set_additional_mass(mass - props.local_mprops.mass(), true);
            }
        }
    }
    /// Set gravity scale multiplier on body `id`.
    pub fn set_gravity_scale(&mut self, id: usize, scale: f32) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_gravity_scale(scale, true);
            }
        }
    }
    /// Lock or unlock rotation for body `id`.
    pub fn set_fixed_rotation(&mut self, id: usize, fixed: bool) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_enabled_rotations(false, false, !fixed, true);
            }
        }
    }
    /// Set linear damping coefficient on body `id`.
    pub fn set_linear_damping(&mut self, id: usize, damping: f32) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_linear_damping(damping);
            }
        }
    }
    /// Set angular damping coefficient on body `id`.
    pub fn set_angular_damping(&mut self, id: usize, damping: f32) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_angular_damping(damping);
            }
        }
    }
    /// Return gravity scale of body `id`; returns 1.0 if out of range.
    pub fn get_gravity_scale(&self, id: usize) -> f32 {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get(handle) {
                return rb.gravity_scale();
            }
        }
        1.0
    }
    /// Return true if rotation is locked on body `id`.
    pub fn is_fixed_rotation(&self, id: usize) -> bool {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get(handle) {
                return rb.is_rotation_locked();
            }
        }
        false
    }
    /// Return linear damping of body `id`; returns 0 if out of range.
    pub fn get_linear_damping(&self, id: usize) -> f32 {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get(handle) {
                return rb.linear_damping();
            }
        }
        0.0
    }
    /// Return angular damping of body `id`; returns 0 if out of range.
    pub fn get_angular_damping(&self, id: usize) -> f32 {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get(handle) {
                return rb.angular_damping();
            }
        }
        0.0
    }
    /// Enable or disable CCD (continuous collision detection) on body `id`.
    pub fn set_bullet(&mut self, id: usize, bullet: bool) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.enable_ccd(bullet);
            }
        }
    }
    /// Return true if CCD is enabled on body `id`.
    pub fn is_bullet(&self, id: usize) -> bool {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get(handle) {
                return rb.is_ccd_enabled();
            }
        }
        false
    }
    /// Apply force `(fx, fy)` at world point `(px, py)` on body `id`.
    pub fn apply_force_at_point(&mut self, id: usize, fx: f32, fy: f32, px: f32, py: f32) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.add_force_at_point(Vector::new(fx, fy), Vector::new(px, py), true);
            }
        }
    }
    /// Apply an angular impulse to body `id`.
    pub fn apply_angular_impulse(&mut self, id: usize, impulse: f32) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.apply_torque_impulse(impulse, true);
                let new_angvel = rb.angvel();
                if let Some(body) = self.bodies.get_mut(id) {
                    body.angular_velocity = new_angvel;
                }
            }
        }
    }
    /// Return all valid body ids as a `Vec`.
    pub fn get_body_ids(&self) -> Vec<usize> {
        (0..self.bodies.len()).collect()
    }
    /// Return all valid joint ids as a `Vec`.
    pub fn get_joint_ids(&self) -> Vec<usize> {
        (0..self.joint_handles.len()).collect()
    }
    /// Return the body-type string of `id`; returns "dynamic" if out of range.
    pub fn get_body_type_str(&self, id: usize) -> &'static str {
        self.bodies
            .get(id)
            .map_or("dynamic", |b| match b.body_type {
                BodyType::Static => "static",
                BodyType::Dynamic => "dynamic",
                BodyType::Kinematic => "kinematic",
                BodyType::Sensor => "sensor",
            })
    }
    /// Change the body type of `id` and rebuild its collider.
    pub fn set_body_type(&mut self, id: usize, bt: BodyType) {
        if let Some(body) = self.bodies.get_mut(id) {
            body.body_type = bt;
        }
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_body_type(Self::rapier_body_type(bt), true);
            }
        }
        if id < self.bodies.len() {
            self.rebuild_collider(id);
        }
    }
    /// Return world gravity as `(gx, gy)`.
    pub fn get_gravity(&self) -> (f32, f32) {
        (self.gravity.x, self.gravity.y)
    }
    /// Set world gravity to `(gx, gy)`.
    pub fn set_gravity(&mut self, gx: f32, gy: f32) {
        self.gravity = Vector::new(gx, gy);
    }
    /// Remove all bodies, joints, and zones; reset rapier sets.
    pub fn clear(&mut self) {
        self.bodies.clear();
        self.body_handles.clear();
        self.collider_handles.clear();
        self.extra_collider_handles.clear();
        self.collider_to_body.clear();
        self.cached_shapes.clear();
        self.cached_restitutions.clear();
        self.cached_layers.clear();
        self.cached_frictions.clear();
        self.joint_handles.clear();
        self.joint_types.clear();
        self.mouse_joint_anchors.clear();
        self.collision_events.clear();
        self.begin_contact_events.clear();
        self.end_contact_events.clear();
        self.rbodies = RigidBodySet::new();
        self.rcolliders = ColliderSet::new();
        self.impulse_joints = ImpulseJointSet::new();
        self.multibody_joints = MultibodyJointSet::new();
        self.islands = IslandManager::new();
        self.broad_phase = BroadPhaseBvh::new();
        self.narrow_phase = NarrowPhase::new();
        self.joint_break_forces.clear();
        self.one_way_normals.clear();
    }
    /// Allow or permanently prevent sleeping for body `id`.
    pub fn set_sleeping_allowed(&mut self, id: usize, allowed: bool) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                if allowed {
                    *rb.activation_mut() = RigidBodyActivation::default();
                } else {
                    *rb.activation_mut() = RigidBodyActivation::cannot_sleep();
                    rb.wake_up(true);
                }
            }
        }
    }
    /// Return true if body `id` is permitted to sleep.
    pub fn is_sleeping_allowed(&self, id: usize) -> bool {
        self.body_handles
            .get(id)
            .and_then(|&h| self.rbodies.get(h))
            .map(|rb| rb.activation().angular_threshold >= 0.0)
            .unwrap_or(true)
    }
    /// Disable body `id`; it will no longer participate in simulation.
    pub fn destroy_body(&mut self, id: usize) {
        if id >= self.bodies.len() {
            return;
        }
        if let Some(extras) = self.extra_collider_handles.get(id) {
            let extra_handles: Vec<ColliderHandle> = extras.clone();
            for h in extra_handles {
                self.rcolliders
                    .remove(h, &mut self.islands, &mut self.rbodies, true);
                self.collider_to_body.remove(&h);
            }
        }
        if id < self.extra_collider_handles.len() {
            self.extra_collider_handles[id].clear();
        }
        if let Some(&primary) = self.collider_handles.get(id) {
            self.collider_to_body.remove(&primary);
        }
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.set_enabled(false);
            }
        }
        self.bodies[id].body_type = BodyType::Static;
    }
    /// Return the number of registered joints.
    pub fn joint_count(&self) -> usize {
        self.joint_handles.len()
    }
    /// Add a distance (rope) joint between two bodies; return joint id.
    #[allow(clippy::too_many_arguments)]
    pub fn add_distance_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        ax1: f32,
        ay1: f32,
        ax2: f32,
        ay2: f32,
        length: f32,
    ) -> usize {
        let ha = match self.body_handles.get(body_a).copied() {
            Some(h) => h,
            None => return 0,
        };
        let hb = match self.body_handles.get(body_b).copied() {
            Some(h) => h,
            None => return 0,
        };
        let joint = RopeJointBuilder::new(length)
            .local_anchor1(Vector::new(ax1, ay1))
            .local_anchor2(Vector::new(ax2, ay2))
            .build();
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let jid = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("distance");
        jid
    }
    /// Add a prismatic (slide-axis) joint between two bodies; return joint id.
    pub fn add_prismatic_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        anchor_x: f32,
        anchor_y: f32,
        axis_x: f32,
        axis_y: f32,
    ) -> usize {
        let ha = match self.body_handles.get(body_a).copied() {
            Some(h) => h,
            None => return 0,
        };
        let hb = match self.body_handles.get(body_b).copied() {
            Some(h) => h,
            None => return 0,
        };
        let axis = Vector::new(axis_x, axis_y);
        let joint = PrismaticJointBuilder::new(axis)
            .local_anchor1(Vector::new(anchor_x, anchor_y))
            .local_anchor2(Vector::new(0.0, 0.0))
            .build();
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let jid = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("prismatic");
        jid
    }
    /// Add a weld (fixed) joint between two bodies; return joint id.
    pub fn add_weld_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        anchor_x: f32,
        anchor_y: f32,
    ) -> usize {
        let ha = match self.body_handles.get(body_a).copied() {
            Some(h) => h,
            None => return 0,
        };
        let hb = match self.body_handles.get(body_b).copied() {
            Some(h) => h,
            None => return 0,
        };
        let joint = FixedJointBuilder::new()
            .local_anchor1(Vector::new(anchor_x, anchor_y))
            .local_anchor2(Vector::new(0.0, 0.0))
            .build();
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let jid = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("weld");
        jid
    }
    /// Add a rope joint with a maximum length; return joint id.
    #[allow(clippy::too_many_arguments)]
    pub fn add_rope_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        ax1: f32,
        ay1: f32,
        ax2: f32,
        ay2: f32,
        max_length: f32,
    ) -> usize {
        let ha = match self.body_handles.get(body_a).copied() {
            Some(h) => h,
            None => return 0,
        };
        let hb = match self.body_handles.get(body_b).copied() {
            Some(h) => h,
            None => return 0,
        };
        let joint = RopeJointBuilder::new(max_length)
            .local_anchor1(Vector::new(ax1, ay1))
            .local_anchor2(Vector::new(ax2, ay2))
            .build();
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let jid = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("rope");
        jid
    }
    /// Return the two body ids connected by `joint_id`, or `None` if not found.
    pub fn get_joint_bodies(&self, joint_id: usize) -> Option<(usize, usize)> {
        let &handle = self.joint_handles.get(joint_id)?;
        let joint = self.impulse_joints.get(handle)?;
        let id_a = self.body_handles.iter().position(|&h| h == joint.body1)?;
        let id_b = self.body_handles.iter().position(|&h| h == joint.body2)?;
        Some((id_a, id_b))
    }
    /// Remove joint `joint_id` from the simulation.
    pub fn destroy_joint(&mut self, joint_id: usize) {
        if let Some(&handle) = self.joint_handles.get(joint_id) {
            self.impulse_joints.remove(handle, true);
        }
        self.joint_break_forces.remove(&joint_id);
    }
    /// Build a `QueryPipeline` view over the current broad+narrow phase.
    fn query_pipeline(&self) -> QueryPipeline<'_> {
        self.broad_phase.as_query_pipeline(
            self.narrow_phase.query_dispatcher(),
            &self.rbodies,
            &self.rcolliders,
            QueryFilter::default(),
        )
    }
    /// Cast a ray from `(x1,y1)` in direction `(dx,dy)` up to `max_dist`; return closest hit.
    pub fn raycast_closest(
        &self,
        x1: f32,
        y1: f32,
        dx: f32,
        dy: f32,
        max_dist: f32,
    ) -> Option<RaycastHit> {
        let dir_len = (dx * dx + dy * dy).sqrt();
        if dir_len < 1e-6 {
            return None;
        }
        let unit_dir = Vector::new(dx / dir_len, dy / dir_len);
        let ray = Ray::new(Vector::new(x1, y1), unit_dir);
        let qp = self.query_pipeline();
        let (col_handle, toi_result) = qp.cast_ray_and_get_normal(&ray, max_dist, true)?;
        let body_id = self
            .collider_handles
            .iter()
            .position(|&h| h == col_handle)?;
        let pt_x = x1 + unit_dir.x * toi_result.time_of_impact;
        let pt_y = y1 + unit_dir.y * toi_result.time_of_impact;
        Some(RaycastHit {
            body_id,
            point: (pt_x, pt_y),
            normal: (toi_result.normal.x, toi_result.normal.y),
            toi: toi_result.time_of_impact,
        })
    }
    /// Cast a ray from `(x1,y1)` in direction `(dx,dy)` and return all hits up to `max_dist`.
    pub fn raycast_all(
        &self,
        x1: f32,
        y1: f32,
        dx: f32,
        dy: f32,
        max_dist: f32,
    ) -> Vec<RaycastHit> {
        let dir_len = (dx * dx + dy * dy).sqrt();
        if dir_len < 1e-6 {
            return Vec::new();
        }
        let unit_dir = Vector::new(dx / dir_len, dy / dir_len);
        let ray = Ray::new(Vector::new(x1, y1), unit_dir);
        let qp = self.query_pipeline();
        let mut hits = Vec::new();
        for (col_handle, _co, ri) in qp.intersect_ray(ray, max_dist, true) {
            if let Some(body_id) = self.body_for_collider(col_handle) {
                let pt_x = x1 + unit_dir.x * ri.time_of_impact;
                let pt_y = y1 + unit_dir.y * ri.time_of_impact;
                hits.push(RaycastHit {
                    body_id,
                    point: (pt_x, pt_y),
                    normal: (ri.normal.x, ri.normal.y),
                    toi: ri.time_of_impact,
                });
            }
        }
        hits
    }
    /// Return all body ids whose AABB overlaps the query rectangle.
    pub fn query_aabb(&self, x: f32, y: f32, w: f32, h: f32) -> Vec<usize> {
        let aabb = Aabb {
            mins: Vector::new(x, y),
            maxs: Vector::new(x + w, y + h),
        };
        let qp = self.query_pipeline();
        let mut results = Vec::new();
        for (col_handle, _co) in qp.intersect_aabb_conservative(aabb) {
            if let Some(body_id) = self.body_for_collider(col_handle) {
                results.push(body_id);
            }
        }
        results
    }
    /// Return the first body id whose AABB contains point `(x, y)`, or `None`.
    pub fn get_body_at_point(&self, x: f32, y: f32) -> Option<usize> {
        let epsilon = 0.01;
        let aabb = Aabb {
            mins: Vector::new(x - epsilon, y - epsilon),
            maxs: Vector::new(x + epsilon, y + epsilon),
        };
        let qp = self.query_pipeline();
        for (col_handle, _co) in qp.intersect_aabb_conservative(aabb) {
            if let Some(body_id) = self.body_for_collider(col_handle) {
                return Some(body_id);
            }
        }
        None
    }
    /// Add a wheel-style prismatic joint; return joint id.
    #[allow(clippy::too_many_arguments)]
    pub fn add_wheel_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        anchor_x: f32,
        anchor_y: f32,
        axis_x: f32,
        axis_y: f32,
    ) -> usize {
        let ha = match self.body_handles.get(body_a).copied() {
            Some(h) => h,
            None => return 0,
        };
        let hb = match self.body_handles.get(body_b).copied() {
            Some(h) => h,
            None => return 0,
        };
        let axis = Vector::new(axis_x, axis_y);
        let mut joint = PrismaticJointBuilder::new(axis)
            .local_anchor1(Vector::new(anchor_x, anchor_y))
            .local_anchor2(Vector::new(0.0, 0.0))
            .build();
        joint.data.locked_axes = JointAxesMask::LIN_Y;
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let jid = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("wheel");
        jid
    }
    /// Add a friction joint limiting linear and angular impulses; return joint id.
    #[allow(clippy::too_many_arguments)]
    pub fn add_friction_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        anchor_x: f32,
        anchor_y: f32,
        max_force: f32,
        max_torque: f32,
    ) -> usize {
        let ha = match self.body_handles.get(body_a).copied() {
            Some(h) => h,
            None => return 0,
        };
        let hb = match self.body_handles.get(body_b).copied() {
            Some(h) => h,
            None => return 0,
        };
        let mut joint = FixedJointBuilder::new()
            .local_anchor1(Vector::new(anchor_x, anchor_y))
            .local_anchor2(Vector::new(0.0, 0.0))
            .build();
        joint
            .data
            .set_motor(JointAxis::LinX, 0.0, 0.0, 0.0, max_force);
        joint
            .data
            .set_motor(JointAxis::LinY, 0.0, 0.0, 0.0, max_force);
        joint
            .data
            .set_motor(JointAxis::AngX, 0.0, 0.0, 0.0, max_torque);
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let jid = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("friction");
        jid
    }
    /// Add a spring-motor joint for position correction; return joint id.
    pub fn add_motor_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        correction_factor: f32,
    ) -> usize {
        let ha = match self.body_handles.get(body_a).copied() {
            Some(h) => h,
            None => return 0,
        };
        let hb = match self.body_handles.get(body_b).copied() {
            Some(h) => h,
            None => return 0,
        };
        let mut joint = FixedJointBuilder::new()
            .local_anchor1(Vector::new(0.0, 0.0))
            .local_anchor2(Vector::new(0.0, 0.0))
            .build();
        joint
            .data
            .set_motor(JointAxis::LinX, 0.0, 0.0, correction_factor, 1.0);
        joint
            .data
            .set_motor(JointAxis::LinY, 0.0, 0.0, correction_factor, 1.0);
        joint
            .data
            .set_motor(JointAxis::AngX, 0.0, 0.0, correction_factor, 1.0);
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let jid = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("motor");
        jid
    }
    /// Create a kinematic anchor and a spring joint targeting `(target_x, target_y)`; return joint id.
    pub fn add_mouse_joint(
        &mut self,
        body_id: usize,
        target_x: f32,
        target_y: f32,
        max_force: f32,
    ) -> usize {
        let mut anchor = Body::new(target_x, target_y, BodyType::Kinematic);
        anchor.shape = BodyShape::Circle { radius: 0.1 };
        anchor.width = 0.2;
        anchor.height = 0.2;
        let anchor_id = self.add_body(anchor);
        let ha = self.body_handles[body_id];
        let hb = self.body_handles[anchor_id];
        let stiffness = max_force;
        let damping = max_force * 0.7;
        let joint = SpringJointBuilder::new(0.0, stiffness, damping)
            .local_anchor1(Vector::new(0.0, 0.0))
            .local_anchor2(Vector::new(0.0, 0.0))
            .build();
        let handle = self.impulse_joints.insert(ha, hb, joint, true);
        let jid = self.joint_handles.len();
        self.joint_handles.push(handle);
        self.joint_types.push("mouse");
        self.mouse_joint_anchors.insert(jid, anchor_id);
        jid
    }
    /// Reposition the kinematic anchor of mouse joint `joint_id` to `(x, y)`.
    pub fn set_mouse_joint_target(&mut self, joint_id: usize, x: f32, y: f32) {
        if let Some(&anchor_id) = self.mouse_joint_anchors.get(&joint_id) {
            self.set_body_position(anchor_id, x, y);
        }
    }
    /// Add a pulley joint (falls back to weld; logs a warning); return joint id.
    pub fn add_pulley_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        anchor_x: f32,
        anchor_y: f32,
    ) -> usize {
        log_msg!(warn, P001_PULLEY_JOINT_FALLBACK);
        self.add_weld_joint(body_a, body_b, anchor_x, anchor_y)
    }
    /// Add a gear joint (falls back to weld; logs a warning); return joint id.
    pub fn add_gear_joint(
        &mut self,
        body_a: usize,
        body_b: usize,
        anchor_x: f32,
        anchor_y: f32,
    ) -> usize {
        log_msg!(warn, P002_GEAR_JOINT_FALLBACK);
        self.add_weld_joint(body_a, body_b, anchor_x, anchor_y)
    }
    /// Set angular motor target speed on joint `joint_id`.
    pub fn set_joint_motor_speed(&mut self, joint_id: usize, speed: f32) {
        if let Some(&handle) = self.joint_handles.get(joint_id) {
            if let Some(joint) = self.impulse_joints.get_mut(handle, true) {
                joint.data.set_motor(JointAxis::AngX, 0.0, speed, 0.0, 1e6);
            }
        }
    }
    /// Return angular motor target speed on joint `joint_id`; returns 0 if not set.
    pub fn get_joint_motor_speed(&self, joint_id: usize) -> f32 {
        if let Some(&handle) = self.joint_handles.get(joint_id) {
            if let Some(joint) = self.impulse_joints.get(handle) {
                if let Some(motor) = joint.data.motor(JointAxis::AngX) {
                    return motor.target_vel;
                }
            }
        }
        0.0
    }
    /// Enable or disable angular limits on joint `joint_id`.
    pub fn set_joint_limits_enabled(&mut self, joint_id: usize, enabled: bool) {
        if let Some(&handle) = self.joint_handles.get(joint_id) {
            if let Some(joint) = self.impulse_joints.get_mut(handle, true) {
                if enabled {
                    let limits = joint
                        .data
                        .limits(JointAxis::AngX)
                        .map_or([-std::f32::consts::PI, std::f32::consts::PI], |l| {
                            [l.min, l.max]
                        });
                    joint.data.set_limits(JointAxis::AngX, limits);
                } else {
                    joint.data.set_limits(JointAxis::AngX, [-1e10, 1e10]);
                }
            }
        }
    }
    /// Set `[lower, upper]` angular limits on joint `joint_id`.
    pub fn set_joint_limits(&mut self, joint_id: usize, lower: f32, upper: f32) {
        if let Some(&handle) = self.joint_handles.get(joint_id) {
            if let Some(joint) = self.impulse_joints.get_mut(handle, true) {
                joint.data.set_limits(JointAxis::AngX, [lower, upper]);
            }
        }
    }
    /// Return `(lower, upper)` angular limits on joint `joint_id`; returns `(0,0)` if not set.
    pub fn get_joint_limits(&self, joint_id: usize) -> (f32, f32) {
        if let Some(&handle) = self.joint_handles.get(joint_id) {
            if let Some(joint) = self.impulse_joints.get(handle) {
                if let Some(limits) = joint.data.limits(JointAxis::AngX) {
                    return (limits.min, limits.max);
                }
            }
        }
        (0.0, 0.0)
    }
    /// Return the type string of joint `joint_id`; returns "unknown" if out of range.
    pub fn get_joint_type(&self, joint_id: usize) -> &'static str {
        self.joint_types.get(joint_id).copied().unwrap_or("unknown")
    }
    /// Set the pixels-per-meter conversion ratio.
    pub fn set_meter(&mut self, ppm: f32) {
        self.pixels_per_meter = ppm;
    }
    /// Return the current pixels-per-meter ratio.
    pub fn get_meter(&self) -> f32 {
        self.pixels_per_meter
    }
    /// Convert a pixel distance to physics-space metres.
    pub fn to_physics(&self, px: f32) -> f32 {
        if self.pixels_per_meter > 0.0 {
            px / self.pixels_per_meter
        } else {
            px
        }
    }
    /// Convert a physics-space metre distance to pixels.
    pub fn to_pixels(&self, m: f32) -> f32 {
        m * self.pixels_per_meter
    }
    /// Return all active contact pairs with normals and touch state.
    pub fn get_contacts(&self) -> Vec<ContactInfo> {
        let mut contacts = Vec::new();
        for pair in self.narrow_phase.contact_pairs() {
            let id_a = self
                .collider_handles
                .iter()
                .position(|&h| h == pair.collider1);
            let id_b = self
                .collider_handles
                .iter()
                .position(|&h| h == pair.collider2);
            if let (Some(a), Some(b)) = (id_a, id_b) {
                let is_touching = pair.has_any_active_contact();
                let (nx, ny) = pair
                    .manifolds
                    .first()
                    .map(|m| (m.local_n1.x, m.local_n1.y))
                    .unwrap_or((0.0, 0.0));
                contacts.push(ContactInfo {
                    body_a: a,
                    body_b: b,
                    normal_x: nx,
                    normal_y: ny,
                    is_touching,
                });
            }
        }
        contacts
    }
    /// Return contacts involving body `body_id` filtered from `get_contacts`.
    pub fn get_body_contacts(&self, body_id: usize) -> Vec<ContactInfo> {
        self.get_contacts()
            .into_iter()
            .filter(|c| c.body_a == body_id || c.body_b == body_id)
            .collect()
    }
    /// Enable one-way platform behaviour: only accept collisions with a normal aligned to `(nx,ny)`.
    pub fn set_body_one_way(&mut self, id: usize, nx: f32, ny: f32) {
        if let Some(v) = self.one_way_normals.get_mut(id) {
            *v = Some((nx, ny));
        }
    }
    /// Remove the one-way constraint from body `id`.
    pub fn clear_body_one_way(&mut self, id: usize) {
        if let Some(v) = self.one_way_normals.get_mut(id) {
            *v = None;
        }
    }
    /// Return the one-way normal for body `id`, or `None` if not set.
    pub fn get_body_one_way(&self, id: usize) -> Option<(f32, f32)> {
        self.one_way_normals.get(id).copied().flatten()
    }
    /// Register a break force threshold for joint `jid`.
    pub fn set_joint_break_force(&mut self, jid: usize, max_force: f32) {
        self.joint_break_forces.insert(jid, max_force);
    }
    /// Return the break-force threshold for joint `jid`, or `None` if not set.
    pub fn get_joint_break_force(&self, jid: usize) -> Option<f32> {
        self.joint_break_forces.get(&jid).copied()
    }
    /// Return true if body `id` is currently asleep.
    pub fn is_body_sleeping(&self, id: usize) -> bool {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get(handle) {
                return rb.is_sleeping();
            }
        }
        false
    }
    /// Wake up body `id` from sleep.
    pub fn wake_up_body(&mut self, id: usize) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.wake_up(true);
            }
        }
    }
    /// Force body `id` to sleep immediately.
    pub fn sleep_body(&mut self, id: usize) {
        if let Some(&handle) = self.body_handles.get(id) {
            if let Some(rb) = self.rbodies.get_mut(handle) {
                rb.sleep();
            }
        }
    }
    /// Set the number of solver iterations (minimum 1).
    pub fn set_solver_iterations(&mut self, n: usize) {
        self.params.num_solver_iterations = n.max(1);
    }
    /// Return the current number of solver iterations.
    pub fn get_solver_iterations(&self) -> usize {
        self.params.num_solver_iterations
    }
    /// Batch-create bodies from a list of `(x, y, BodyType)` tuples; return their ids.
    pub fn add_bodies(&mut self, specs: Vec<(f32, f32, BodyType)>) -> Vec<usize> {
        specs
            .into_iter()
            .map(|(x, y, bt)| self.add_body(Body::new(x, y, bt)))
            .collect()
    }
}
