//! Save/load slot system with collectors, schema versioning, dirty tracking,
//! and auto-save.

mod save_manager;

pub use save_manager::{SlotMeta, SaveManager, SaveValue, serialize_table, serialize_value};
