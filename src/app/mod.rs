//! Application lifecycle: game loop, window management, and diagnostics.
//!
//! This module owns the [`App`] struct that drives the winit event loop, fires Lua
//! callbacks, and coordinates rendering. It also provides the debug overlay and error screen.

/// Entry point for the Lurek2D engine lifecycle and game loop.
pub mod app;
/// Debug overlay for FPS and draw-call statistics.
pub mod debug_overlay;
/// Visual error screen for Lua and engine errors.
pub mod error_screen;

pub use app::App;
pub use debug_overlay::DebugOverlay;
pub use error_screen::ErrorScreen;
