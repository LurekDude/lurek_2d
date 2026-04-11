//! Skeletal animation — bone hierarchies, slots, and world-transform propagation.
//!
//! The spine module provides a hierarchical bone system for 2D skeletal animation.
//! Bones form a parent-child tree; calling `Skeleton::update_world_transforms()`
//! propagates local transforms down the hierarchy to produce world-space positions
//! for rendering.

/// Bone hierarchy node: local transform (translation, rotation, scale), parent pointer, and child list.
pub mod bone;
/// GPU render-command generation for skeletal animation skeletons.
pub mod render;
/// `Skeleton` root type: manages the bone tree and calls `update_world_transforms()` to compute world-space positions.
pub mod skeleton;
/// Attachment slot that links a bone to a displayable resource (sprite, mesh, or point attachment).
pub mod slot;

pub use bone::Bone;
pub use skeleton::{BoneParams, Skeleton};
pub use slot::Slot;
