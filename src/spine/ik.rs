//! Inverse-kinematics constraint for 2-bone chains in the spine skeleton system.
//! Owns IKConstraint: stores chain indices and target, solves root and elbow rotations via law-of-cosines.
//! Does not own world-space accumulation — callers must re-run pose update after solve().

use super::bone::Bone;

/// 2-bone IK constraint that drives root and elbow rotations toward a world-space target.
#[derive(Debug, Clone)]
pub struct IKConstraint {
    /// Identifier for this constraint within the skeleton.
    pub name: String,
    /// Indices into the skeleton bone array; index 0 = root, index 1 = elbow (2-bone limit).
    pub bone_chain: Vec<usize>,
    /// World-space target X position that the chain tip should reach.
    pub target_x: f32,
    /// World-space target Y position that the chain tip should reach.
    pub target_y: f32,
    /// When true, elbow bends in the positive (counter-clockwise) direction.
    pub bend_positive: bool,
}

/// Constructor and solve methods for IKConstraint.
impl IKConstraint {
    /// Create a new IKConstraint with the given chain indices and bend direction; target defaults to (0, 0).
    pub fn new(name: impl Into<String>, bone_chain: Vec<usize>, bend_positive: bool) -> Self {
        Self {
            name: name.into(),
            bone_chain,
            target_x: 0.0,
            target_y: 0.0,
            bend_positive,
        }
    }
    /// Update the world-space target position for this constraint.
    pub fn set_target(&mut self, x: f32, y: f32) {
        self.target_x = x;
        self.target_y = y;
    }
    /// Solve root and elbow local_rotation angles using law-of-cosines 2-bone IK; no-op when chain length < 2 or indices out of bounds.
    #[allow(clippy::ptr_arg)]
    pub fn solve(&self, bones: &mut Vec<Bone>) {
        if self.bone_chain.len() < 2 {
            return;
        }
        let root_idx = self.bone_chain[0];
        let elbow_idx = self.bone_chain[1];
        if root_idx >= bones.len() || elbow_idx >= bones.len() {
            return;
        }
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
        let lower_len = {
            let e = &bones[elbow_idx];
            let dx = e.local_x;
            let dy = e.local_y;
            (dx * dx + dy * dy).sqrt().max(1.0)
        };
        let upper_len = upper_len.max(1.0);
        let dx = self.target_x - root_wx;
        let dy = self.target_y - root_wy;
        let dist = (dx * dx + dy * dy).sqrt();
        let angle_to_target = dy.atan2(dx);
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
        let root_rotation = if self.bend_positive {
            angle_to_target - angle_a
        } else {
            angle_to_target + angle_a
        };
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
        bones[root_idx].local_rotation = root_rotation;
        bones[elbow_idx].local_rotation = elbow_rotation;
    }
}
