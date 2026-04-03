//! Save/load slot system with collectors, schema versioning, dirty tracking,
//! and auto-save.
//!
//! This module is part of Luna2D's `savegame` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Save Data sub-module.
pub mod save_data;
pub use save_data::*;
