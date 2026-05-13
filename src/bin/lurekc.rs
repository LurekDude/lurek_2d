//! Release binary entry point that forwards startup to the engine crate.
//! Keeps launcher logic minimal and delegates runtime setup to `lurek2d::lurek_run`.
#![cfg_attr(windows, windows_subsystem = "windows")]
/// Start the engine using the default runtime bootstrap path.
fn main() {
    lurek2d::lurek_run();
}
