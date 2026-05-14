//! Save system entry point. Owns slot-based game-state persistence via `SaveManager`,
//! serialization of Lua values to human-readable Lua table strings, and optional
//! LZ4+Base64 compressed save files. Does not own file I/O; callers derive paths
//! through `slot_path()`. Key dependencies: `data::compress`, mlua, base64.

mod save_manager;
pub use save_manager::{
    compress_save_content, decompress_save_content, serialize_table, serialize_value, SaveManager,
    SaveValue, SlotMeta,
};
