//! - Submodule declarations for all visualization categories.
//! - Wildcard re-exports providing a flat public API.
//! - Shared facade helpers scoped to crate visibility.

/// Animation visualizations.
pub mod animation;
/// Audio visualizations.
pub mod audio;
/// Camera visualizations.
pub mod camera;
/// Easing visualizations.
pub mod easing;
/// Shared visualization helpers.
pub mod facade;
/// Geometry visualizations.
pub mod geometry;
/// Graph visualizations.
pub mod graph;
/// Image-operation visualizations.
pub mod image_ops;
/// Noise visualizations.
pub mod noise;
/// Procedural-generation visualizations.
pub mod procgen;
/// UI visualizations.
pub mod ui;
/// Re-export animation visualization entry points.
pub use animation::*;
/// Re-export audio visualization entry points.
pub use audio::*;
/// Re-export camera visualization entry points.
pub use camera::*;
/// Re-export easing visualization entry points.
pub use easing::*;
/// Re-export shared visualization helpers within the module.
pub(crate) use facade::*;
/// Re-export geometry visualization entry points.
pub use geometry::*;
/// Re-export graph visualization entry points.
pub use graph::*;
/// Re-export image-operation visualization entry points.
pub use image_ops::*;
/// Re-export noise visualization entry points.
pub use noise::*;
/// Re-export procedural-generation visualization entry points.
pub use procgen::*;
/// Re-export UI visualization entry points.
pub use ui::*;
