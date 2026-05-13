//! Runtime foundation types shared across app loop, Lua bridge, and subsystem modules.
//! Exposes config loading, message catalog, error model, resource keys, and shared frame state.

/// Runtime configuration model loaded from `conf.toml`.
pub mod config;
/// Engine-wide error types and snapshot helpers.
pub mod error;
/// Log message identifiers and log-level override helpers.
pub mod log_messages;
/// Message catalog loader and lookup API.
pub mod messages;
/// Slot-map key types used by runtime-owned resources.
pub mod resource_keys;
/// Shared mutable runtime state consumed by app and Lua callbacks.
pub mod shared_state;
pub use config::Config;
pub use error::{EngineError, EngineResult, ErrorCategory, ErrorSnapshot};
pub use messages::MessageCatalog;
pub use shared_state::{
    ErrorInfo, FrameProfile, FullscreenType, PhysicsRunConfig, RendererStats, ResourceMemoryStats,
    ScreenshotRequest, SharedState, WindowState,
};
