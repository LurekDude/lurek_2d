//! Globe module — XCOM-style Geoscape / Europa Universalis sphere.
//!
//! Provides a data-driven, projection-correct 2D view of a unit sphere divided
//! into named provinces. Exposes province topology, orbit camera, great-circle
//! arithmetic, fog-of-war, markers, labels, layers, and a frame emitter.
//!
//! # Quick start
//! ```rust,no_run
//! use lurek2d::globe::registry::{Globe, GlobeRegistry};
//! use lurek2d::globe::types::GlobeSpec;
//! let mut reg = GlobeRegistry::new();
//! let globe = reg.create("world", GlobeSpec::default());
//! let _cmds = globe.emit_frame(None);
//! ```
//!
//! # Module layout
//! | Sub-module       | Contents |
//! |------------------|----------|
//! `types`            | Core types: `Province`, `GlobeSpec`, `Marker`, `Label`, `Layer`, `LodTier`, `GlobeError` |
//! `topology`         | `ProvinceGraph` — adjacency, path-finding, attribute storage |
//! `projection`       | `OrbitCamera`, `build_view_matrix`, `project_province/point` |
//! `picking`          | Screen → province hit-test |
//! `lighting`         | Per-province sun intensity, terminator |
//! `fog`              | `FogMask` / `FogStore` bit-vector fog-of-war |
//! `loader`           | TOML / PNG province map loaders |
//! `marker`           | `MarkerStore` |
//! `label`            | `LabelStore` |
//! `layer`            | `LayerStore` |
//! `draw`             | `emit_globe_frame` → `Vec<RenderCommand>` |
//! `registry`         | `Globe` + `GlobeRegistry` |

/// Globe rendering and frame emitting operations.
pub mod draw;
/// Fog of war subsystem for the globe.
pub mod fog;
/// Text labels plotted on the globe surface.
pub mod label;
/// Configurable texture overlay boundaries.
pub mod layer;
/// Real-time shading and day/night terminator computation.
pub mod lighting;
/// Province deserialization from PNGs and TOML files.
pub mod loader;
/// World-space coordinate markers and icons.
pub mod marker;
/// Subsystem to hit-test screen coordinates against provinces.
pub mod picking;
/// 3D spherical rendering pipeline mapping.
pub mod projection;
/// Optional adapter translating province snapshots into globe state.
pub mod province_adapter;
/// Storage and instantiation of individual globes.
pub mod registry;
/// Mathematical neighborhood graph of connected regions.
pub mod topology;
/// Foundational data definitions for the globe.
pub mod types;

// ── Re-exports ───────────────────────────────────────────────────────────────
pub use fog::{FogMask, FogStore};
pub use picking::PickResult;
pub use projection::OrbitCamera;
pub use registry::{Globe, GlobeRegistry};
pub use types::{
    GlobeError, GlobeSpec, Label, LabelStyle, Layer, LodTier, Marker, MarkerShape, MarkerStyle,
    Province, ProvinceId, MAX_PROVINCES,
};
