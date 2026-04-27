//! Application lifecycle: game loop, window management, and diagnostics.
//!
//! This module owns the [`App`] struct that drives the winit event loop, fires Lua
//! callbacks, and coordinates rendering. It also provides the debug overlay and error screen.
//!
//! # Module group
//!
//! `Edge/Integration` — sits at the top of the dependency graph. Nothing in the
//! engine imports from `app`; it orchestrates every other subsystem.
//!
//! # Key types
//!
//! - [`App`] — public entry point: call [`App::run()`] to start the engine.
//! - [`DebugOverlay`] — lightweight FPS / draw-call counter (toggled via F12).
//! - [`ErrorScreen`] — structured blue error screen for Lua and engine failures.

/// Entry point for the Lurek2D engine lifecycle and game loop.
#[allow(clippy::module_inception)]
pub mod app;
/// Debug overlay for FPS and draw-call statistics.
pub mod debug_overlay;
/// Visual error screen for Lua and engine errors.
pub mod error_screen;

pub use app::App;
pub use debug_overlay::DebugOverlay;
pub use error_screen::ErrorScreen;
