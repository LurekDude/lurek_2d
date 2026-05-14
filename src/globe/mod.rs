//! Globe domain modules for topology, projection, drawing, and registry state.
//!
//! Re-exports the public globe surface used by higher-level systems.
//! The actual loading, projection, and rendering logic lives in sibling files.

/// Globe composition helpers.
pub mod composition;
/// Globe drawing helpers.
pub mod draw;
/// Globe export helpers.
pub mod export;
/// Fog overlay helpers.
pub mod fog;
/// Globe label helpers.
pub mod label;
/// Globe layer helpers.
pub mod layer;
/// Globe lighting helpers.
pub mod lighting;
/// Globe loading helpers.
pub mod loader;
/// Globe marker helpers.
pub mod marker;
/// Globe picking helpers.
pub mod picking;
/// Globe camera projection helpers.
pub mod projection;
/// Province adapter helpers.
pub mod province_adapter;
/// Globe registry state.
pub mod registry;
/// Globe synchronization helpers.
pub mod sync;
/// Globe topology helpers.
pub mod topology;
/// Globe shared value types.
pub mod types;
/// Fog state and mask types.
pub use fog::{FogMask, FogStore};
/// Picking result type.
pub use picking::PickResult;
/// Orbit camera type used for globe projection.
pub use projection::OrbitCamera;
/// Globe registry types.
pub use registry::{Globe, GlobeRegistry};
/// Synchronization channel and snapshot types.
pub use sync::{GlobeSyncChannel, GlobeSyncSnapshot};
/// Shared globe value types.
pub use types::{
    FogState, GlobeError, GlobeSpec, HeatLayer, Label, LabelStyle, Layer, LodTier, Marker,
    MarkerShape, MarkerStyle, Province, ProvinceId, MAX_PROVINCES,
};
