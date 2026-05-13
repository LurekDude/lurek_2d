//! Windows-silent entry point for Lurek2D game distribution.
//! Sets `windows_subsystem = "windows"` to suppress the console window on Windows.
//! Behavior is identical to the main `lurek2d` binary on all platforms.
//! Not part of any module group; this is a thin launcher shim with no engine logic.

#![cfg_attr(windows, windows_subsystem = "windows")]

fn main() {
    lurek2d::lurek_run();
}
