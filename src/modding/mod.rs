//! Mod management framework.
//!
//! Provides `ModInfo` for mod metadata and `ModManager` for registration,
//! dependency resolution, load ordering, folder scanning, and hot-reload queuing.

pub mod mod_manager;
pub use mod_manager::*;
