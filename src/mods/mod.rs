//! Mod loading subsystem: discovers, validates, and activates content mods at runtime.
//! Owns the mod manager and re-exports its public API for the rest of the engine.
//! Does not own filesystem access or Lua execution; those are delegated to `GameFS` and `mlua`.

/// Mod lifecycle management: discovery, enable/disable, and Lua integration.
pub mod mod_manager;
pub use mod_manager::*;
