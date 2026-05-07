//! Lurek2D engine binary entry point.
//!
//! This crate is a thin wrapper around the `lurek2d` library crate. Its only job is to call
//! [`lurek2d::lurek_run`], which installs the panic hook, parses the command-line game-directory
//! argument, loads `conf.lua`, and enters the main engine loop.
//!
//! Two binary crates share the same source via `Cargo.toml` feature flags:
//!   - `lurek`   â€” console-attached binary (default, used during development)
//!   - `lurekc`  â€” no-console binary (Windows release build, no terminal window)
//!
//! To run a game pass the path to the game directory as the first CLI argument:
//!
//! ```text
//! lurek path/to/my_game
//! ```
//!
//! If no argument is given, the engine looks for `main.lua` in the current working directory
//! and falls back to the splash screen if none is found.
#[cfg(target_os = "windows")]
fn set_windows_timer_resolution() {
    // Windows default timer resolution is ~15 ms.
    // winit ControlFlow::WaitUntil uses WaitableTimer which respects this granularity,
    // capping the effective frame rate at ~7 fps even when rendering is trivially fast.
    // timeBeginPeriod(1) raises resolution to 1 ms for the lifetime of this process.
    unsafe {
        windows_sys::Win32::Media::timeBeginPeriod(1);
    }
}

fn main() {
    #[cfg(target_os = "windows")]
    set_windows_timer_resolution();

    lurek2d::lurek_run();
}
