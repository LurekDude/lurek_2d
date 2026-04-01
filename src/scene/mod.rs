//! Scene stack module for managing game scene lifecycle, transitions, and depth-sorted rendering.
//!
//! Provides a LIFO stack of Lua scene tables with lifecycle callbacks (`enter`, `leave`,
//! `pause`, `resume`, `update`, `draw`), animated transitions (fade, slide), a named
//! scene registry, inter-scene data passing, and a `DepthSorter` for z-ordered draw batching.

/// depth_sorter.
pub mod depth_sorter;
/// stack.
pub mod stack;
/// transition.
pub mod transition;

pub use depth_sorter::DepthSorter;
pub use stack::SceneStack;
pub use transition::{ActiveTransition, TransitionType};
