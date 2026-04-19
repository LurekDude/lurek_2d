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

pub mod types;
pub mod topology;
pub mod projection;
pub mod picking;
pub mod lighting;
pub mod fog;
pub mod loader;
pub mod marker;
pub mod label;
pub mod layer;
pub mod draw;
pub mod registry;

// ── Re-exports ───────────────────────────────────────────────────────────────
pub use registry::{Globe, GlobeRegistry};
pub use types::{
    Province, ProvinceId, GlobeSpec, GlobeError, LodTier, MAX_PROVINCES,
    Marker, MarkerStyle, MarkerShape, Label, LabelStyle, Layer,
};
pub use projection::OrbitCamera;
pub use picking::PickResult;
pub use fog::{FogMask, FogStore};
