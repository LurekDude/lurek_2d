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
fn main() {
    lurek2d::lurek_run();
}
