#[allow(clippy::module_inception)]
/// Core application runtime: event loop bridge, frame lifecycle, and orchestration.
pub mod app;
/// Debug HUD overlay rendered on top of game output.
pub mod debug_overlay;
/// User-facing fatal error rendering and formatting helpers.
pub mod error_screen;
/// Frame profile formatting helpers.
pub mod frame_profile;
/// Lua callback invocation wrappers with optional instruction timeout guard.
pub mod lua_callbacks;
/// Splash branding asset loading and splash render-command generation.
pub mod splash_screen;
pub use app::App;
pub use debug_overlay::DebugOverlay;
pub use error_screen::ErrorScreen;
