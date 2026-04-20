//! Two-bone IK constraint using the law-of-cosines analytic solver.
//!
//! An [`IKConstraint`] stores a chain of exactly two bone indices and a world-space
//! target position. Call [`solve`](IKConstraint::solve) after each update to compute
//! the bone rotations required to reach the target.

use super::bone::Bone;

/// Two-bone IK constraint: positions two chained bones to reach a world-space target.
///
/// The solver uses the law of cosines to find the angle at the elbow bone, then sets
/// local rotations for both the root and the middle bone.
///
/// # Fields
/// - `name` — `String`. Constraint identifier.
/// - `bone_chain` — `Vec<usize>`. Exactly two bone indices: `[root, elbow]`.
/// - `target_x` — `f32`. World-space X of the end-effector target.
/// - `target_y` — `f32`. World-space Y of the end-effector target.
/// - `bend_positive` — `bool`. Preferred bend direction.
#[derive(Debug, Clone)]
pub struct IKConstraint {
    /// Human-readable constraint name.
    pub name: String,
    /// Bone index chain: exactly two entries `[root_idx, elbow_idx]`.
    pub bone_chain: Vec<usize>,
    /// World-space X coordinate of the IK target.
    pub target_x: f32,
    /// World-space Y coordinate of the IK target.
    pub target_y: f32,
    /// Bend direction: `true` = positive (counter-clockwise elbow), `false` = negative.
    pub bend_positive: bool,
}

impl IKConstraint {
    /// Creates a new two-bone IK constraint.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`. Constraint identifier.
    /// - `bone_chain` — `Vec<usize>`. Exactly two bone indices `[root, elbow]`.
    /// - `bend_positive` — `bool`. Preferred elbow bend direction.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>, bone_chain: Vec<usize>, bend_positive: bool) -> Self {
        Self {
            name: name.into(),
            bone_chain,
            target_x: 0.0,
            target_y: 0.0,
            bend_positive,
        }
    }

    /// Sets the world-space target position for this constraint.
    ///
    /// # Parameters
    /// - `x` — `f32`. Target X.
    /// - `y` — `f32`. Target Y.
    pub fn set_target(&mut self, x: f32, y: f32) {
        self.target_x = x;
        self.target_y = y;
    }

    /// Solves the two-bone IK and writes the resulting local rotations into the
    /// bone array.
    ///
    /// Uses law-of-cosines to find the elbow angle, then computes the root bone
    /// rotation to aim the chain toward the target. Only writes to valid bone
    /// indices. If the target is unreachable (too close or too far), the chain
    /// is straightened toward the target.
    ///
    /// # Parameters
    /// - `bones` — `&mut Vec<Bone>`. The skeleton's bone array (modified in place).
    pub fn solve(&self, bones: &mut Vec<Bone>) {
        if self.bone_chain.len() < 2 {
            return;
        }
        let root_idx = self.bone_chain[0];
        let elbow_idx = self.bone_chain[1];

        if root_idx >= bones.len() || elbow_idx >= bones.len() {
            return;
        }

        // Upper arm length: root → elbow (world positions after last update)
        let (root_wx, root_wy) = {
            let r = &bones[root_idx];
            (r.world_x, r.world_y)
        };
        let (elbow_wx, elbow_wy) = {
            let e = &bones[elbow_idx];
            (e.world_x, e.world_y)
        };

        let upper_len = {
            let dx = elbow_wx - root_wx;
            let dy = elbow_wy - root_wy;
            (dx * dx + dy * dy).sqrt()
        };

        // Lower arm length: estimated from elbow local offset.
        let lower_len = {
            let e = &bones[elbow_idx];
            let dx = e.local_x;
            let dy = e.local_y;
            (dx * dx + dy * dy).sqrt().max(1.0)
        };

        let upper_len = upper_len.max(1.0);

        // Distance from root to target.
        let dx = self.target_x - root_wx;
        let dy = self.target_y - root_wy;
        let dist = (dx * dx + dy * dy).sqrt();

        // Angle from root to target.
        let angle_to_target = dy.atan2(dx);

        // Law of cosines: cos(A) = (a²+c²-b²) / (2ac)
        // c = upper_len (known), b = lower_len, a = dist
        let cos_a = {
            let num = dist * dist + upper_len * upper_len - lower_len * lower_len;
            let den = 2.0 * dist * upper_len;
            if den.abs() < f32::EPSILON {
                1.0f32
            } else {
                (num / den).clamp(-1.0, 1.0)
            }
        };

        let angle_a = cos_a.acos();

        // Choose bend direction.
        let root_rotation = if self.bend_positive {
            angle_to_target - angle_a
        } else {
            angle_to_target + angle_a
        };

        // Elbow angle: law of cosines for the elbow joint.
        let cos_b = {
            let num = upper_len * upper_len + lower_len * lower_len - dist * dist;
            let den = 2.0 * upper_len * lower_len;
            if den.abs() < f32::EPSILON {
                1.0f32
            } else {
                (num / den).clamp(-1.0, 1.0)
            }
        };
        let angle_b = cos_b.acos();
        let elbow_rotation = if self.bend_positive {
            std::f32::consts::PI - angle_b
        } else {
            -(std::f32::consts::PI - angle_b)
        };

        // Write local rotations.
        bones[root_idx].local_rotation = root_rotation;
        bones[elbow_idx].local_rotation = elbow_rotation;
    }
}

