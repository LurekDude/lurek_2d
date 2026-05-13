//! Engine entry point: window, event loop, Lua callbacks, and frame rendering.
//! Coordinates subsystems via [`App::run()`]; only module at top of dependency graph.

/// Application state and main loop orchestration.
#[allow(clippy::module_inception)]
pub mod app;
/// Frame timing statistics formatting.
pub mod frame_profile;
/// Lua callback invocation with timeout control.
pub mod lua_callbacks;
/// Splash-screen branding asset loading and rendering.
pub mod splash_screen;
/// Frame rate and draw-call diagnostic overlay.
pub mod debug_overlay;
/// Fallback error display for runtime and Lua failures.
pub mod error_screen;

pub use app::App;
pub use debug_overlay::DebugOverlay;
pub use error_screen::ErrorScreen;
