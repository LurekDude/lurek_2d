//! # lunec — Console-less Luna2D Launcher
//!
//! This is an alternative binary entry point for Luna2D that suppresses the
//! console window on Windows by setting the `windows_subsystem = "windows"`
//! attribute. Behavior is otherwise identical to the main `luna2d` binary.
//!
//! ## Purpose
//!
//! When distributing a game to end users on Windows, running via `lunec.exe`
//! prevents the black terminal window from appearing alongside the game window.
//! This provides a polished, professional feel for released games.
//!
//! ## Usage
//!
//! ```sh
//! lunec path/to/my_game     # Launch game without console window
//! lunec                     # Splash screen, no console
//! ```
//!
//! ## Platform Notes
//!
//! - **Windows**: `windows_subsystem = "windows"` hides the console.
//! - **Linux/macOS**: No behavioral difference from the standard binary;
//!   the attribute is ignored on non-Windows platforms.

#![cfg_attr(windows, windows_subsystem = "windows")]

fn main() {
    luna2d::luna_run();
}
