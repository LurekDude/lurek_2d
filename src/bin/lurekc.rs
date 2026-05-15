//! - Default engine binary entry point with Windows subsystem attribute.
//! - Delegates to lurek2d::lurek_run() for full runtime bootstrap.
//! - Suppresses console window on Windows release builds.

#![cfg_attr(windows, windows_subsystem = "windows")]
/// Start the engine using the default runtime bootstrap path.
fn main() {
    lurek2d::lurek_run();
}
