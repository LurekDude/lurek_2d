//! Core engine runtime: configuration, error handling, shared state, and resource management.
//!
//! This module owns the foundational types that every other module in the engine imports.
//! It provides [`SharedState`], [`Config`], [`EngineError`], typed resource keys, and the
//! structured log message catalog.

/// Engine and window configuration structs (Config, WindowConfig, etc.).
pub mod config;
/// EngineError enum and EngineResult type alias for engine-level errors.
pub mod error;
/// Structured logging with stable message IDs.
pub mod log_messages;
/// TOML-backed human-readable message catalog for all engine log messages.
pub mod messages;
/// Typed resource keys for generational ID-based resource pools.
pub mod resource_keys;
/// Central shared runtime state: SharedState, WindowState, FullscreenType, ErrorInfo.
pub mod shared_state;

pub use config::Config;
pub use error::{EngineError, EngineResult, ErrorCategory};
pub use messages::MessageCatalog;
pub use shared_state::{ErrorInfo, FullscreenType, RendererStats, ScreenshotRequest, SharedState, WindowState};
