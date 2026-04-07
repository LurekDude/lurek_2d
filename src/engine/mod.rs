//! Core engine lifecycle: application loop, configuration, error handling, and diagnostics.
//!
//! This module owns the highest-level runtime structures in the Luna2D engine.
//! [`App`] drives the winit event loop, fires `luna.load/update/draw/keypressed/…` Lua
//! callbacks at the right moments, and holds every domain subsystem inside a
//! `Rc<RefCell<SharedState>>` that is shared with the Lua VM.
//!
//! # Module overview
//!
//! - [`app`] — [`App`] struct that implements `winit::ApplicationHandler`.  It creates the
//!   window and renderer, initialises every subsystem, executes `main.lua`, and routes
//!   window events to their corresponding Lua callbacks.
//! - [`config`] — [`Config`], [`WindowConfig`], [`ModulesConfig`], and [`PerformanceConfig`]
//!   structs loaded from `conf.lua` at startup.
//! - [`debug_overlay`] — on-screen FPS and draw-call counter drawn in the bottom-right
//!   corner of the window during development.
//! - [`error`] — [`EngineError`] enum and [`EngineResult`] type alias used throughout the
//!   codebase for structured, recoverable error propagation.
//! - [`error_screen`] — fallback render path that displays a human-readable Lua or engine
//!   error on screen instead of crashing silently.
//! - [`log_messages`] — structured, stable-ID log message constants used by `log::info!`
//!   macros across the engine so message IDs remain consistent between builds.
//! - [`resource_keys`] — typed newtype keys (`SoundKey`, `TextureKey`, `ShaderId`, …) for
//!   all slot-map resource pools in the engine.

/// Entry point for the Luna2D engine lifecycle and game loop.
pub mod app;
/// Engine and window configuration structs (Config, WindowConfig, etc.).
pub mod config;
/// Debug overlay for FPS and draw-call statistics.
pub mod debug_overlay;
/// EngineError enum and EngineResult type alias for engine-level errors.
pub mod error;
/// Visual error screen for Lua and engine errors.
pub mod error_screen;
/// Structured logging with stable message IDs.
pub mod log_messages;
/// TOML-backed human-readable message catalog for all engine log messages.
pub mod messages;
/// Typed resource keys for generational ID-based resource pools.
pub mod resource_keys;
/// Central shared runtime state: SharedState, WindowState, FullscreenType, ErrorInfo.
pub mod shared_state;

pub use app::App;
pub use config::Config;
pub use debug_overlay::DebugOverlay;
pub use error::{EngineError, EngineResult, ErrorCategory};
pub use error_screen::ErrorScreen;
pub use messages::MessageCatalog;
pub use shared_state::{ErrorInfo, FullscreenType, RendererStats, ScreenshotRequest, SharedState, WindowState};
