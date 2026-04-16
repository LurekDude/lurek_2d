//! Mod management framework.
//!
//! Provides `ModInfo` for mod metadata and `ModManager` for registration,
//! dependency resolution, load ordering, folder scanning, and hot-reload queuing.
//!
//! This module is part of Lurek2D's `modding` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

/// Mod Manager: discovers, loads, and manages runtime extension mods.
pub mod mod_manager;
pub use mod_manager::*;
