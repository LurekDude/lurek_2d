//! Sandboxed virtual filesystem for Lurek2D.
//!
//! Provides [`vfs::GameFS`] — the central filesystem abstraction that sandboxes all
//! file I/O to the game's base directory. Every path is checked against a canonical path
//! traversal guard before the OS is asked to open the file, preventing Lua scripts from
//! escaping the sandbox via `..`, absolute paths, or symbolic links.
//!
//! ## Subsystem inventory
//! - [`vfs`] — [`GameFS`]: sandboxed read/write with virtual mount-point overlay
//! - [`file_handle`] — [`FileHandle`]: open-file session with cursored read/write
//! - [`async_loader`] — background asset-loading worker (off main thread)
//! - [`file_data`] — [`FileData`]: raw byte buffer returned from VFS reads
//!
//! ## Sandbox rules
//! - Reads: base game folder + all mounted mod layers
//! - Writes: save-data directory only (configured separately from the read-only game folder)
//! - Any path that resolves outside the base after canonicalization → `EngineError::FsPathTraversal`
//!
//! All public items are documented. Lua bridge: `src/lua_api/filesystem_api.rs`.

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
