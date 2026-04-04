//! Skeletal animation — bone hierarchies, slots, and world-transform propagation.
//!
//! The spine module provides a hierarchical bone system for 2D skeletal animation.
//! Bones form a parent-child tree; calling `Skeleton::update_world_transforms()`
//! propagates local transforms down the hierarchy to produce world-space positions
//! for rendering.

pub mod bone;
pub mod skeleton;
pub mod slot;

pub use bone::Bone;
pub use skeleton::Skeleton;
pub use slot::Slot;
