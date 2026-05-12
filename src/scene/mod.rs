//! Scene stack module for managing game scene lifecycle, transitions, and depth-sorted rendering.
//!
//! Provides a LIFO stack of Lua scene tables with lifecycle callbacks (`enter`, `leave`,
//! `pause`, `resume`, `update`, `draw`), animated transitions (fade, slide), a named
//! scene registry, inter-scene data passing, and a `DepthSorter` for z-ordered draw batching.

/// Z-order depth sorter for draw-call batching; groups scene objects by depth layer before rendering.
pub mod depth_sorter;
/// Internal easing helpers used by transition curves.
pub(crate) mod easing;
/// Render-command generation and CPU drawing for the scene module.
pub mod render;
/// LIFO scene stack with lifecycle callbacks (`enter`, `leave`, `pause`, `resume`, `update`, `draw`) and a named scene registry.
pub mod stack;
/// Animated scene transitions with configurable types (fade, slide) and easing, plus inter-scene data passing.
pub mod transition;

pub use depth_sorter::DepthSorter;
pub use stack::{SceneId, SceneStack};
pub use transition::{ActiveTransition, EasingType, TransitionType};
