//! Save/load slot system with collectors, schema versioning, dirty tracking,
//! and auto-save.
//!
//! [`SaveManager`] is the primary type: it coordinates named collector callbacks
//! (Lua functions that gather/restore game state), tracks a schema version integer,
//! maintains a dirty flag, and drives optional auto-save on a configurable interval.
//! [`SlotMeta`] describes one save slot's metadata (name, timestamp, schema version,
//! summary string). [`SaveValue`] is the enum of serializable primitive types.
//!
//! Serialization of actual save data is delegated to `crate::serial` (TOML format).
//! File I/O is delegated to `crate::filesystem::GameFS`.
//!
//! Lua bridge: `src/lua_api/save_api.rs` as `lurek.save.*`.


mod save_manager;

pub use save_manager::{SlotMeta, SaveManager, SaveValue, serialize_table, serialize_value};
