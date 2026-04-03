//! Mod implementation for the `filesystem` subsystem.
//!
//! This module is part of Luna2D's `filesystem` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
/// Sandboxed virtual filesystem that restricts I/O to the game directory.
pub mod vfs;

/// File handle with buffered read/write and sandboxed path resolution.
pub mod file_handle;

/// Background asset-loading worker that reads files off the main thread.
pub mod async_loader;

/// Raw file data buffer loaded from the VFS.
pub mod file_data;

pub use async_loader::{AsyncLoader, LoadHandle, LoadResult, LoadStatus};
pub use file_data::FileData;
pub use file_handle::{FileHandle, FileMode};
pub use vfs::{FileInfo, FileType, GameFS, MountLayer};
