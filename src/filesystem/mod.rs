//! - Virtual filesystem with layered mounts (directory, ZIP archive).
//! - Async file loading queue with handle-based status polling.
//! - Buffered file I/O with read, write, and append modes.
//! - File modification watcher for hot-reload workflows.

/// Async file request queue and result tracking.
pub mod async_loader;
/// Cached file payload helper.
pub mod file_data;
/// Buffered file handle and file mode helpers.
pub mod file_handle;
/// Virtual filesystem and mount management.
pub mod vfs;
/// File modification watcher.
pub mod watcher;
/// ZIP archive overlay mount.
pub mod zip_mount;
/// Async file request queue and result tracking.
pub use async_loader::{AsyncLoader, LoadHandle, LoadResult, LoadStatus, WriteResult, WriteStatus};
/// Cached file payload helper.
pub use file_data::FileData;
/// Buffered file handle and file mode helpers.
pub use file_handle::{FileHandle, FileMode};
/// Virtual filesystem metadata and mount types.
pub use vfs::{FileInfo, FileType, GameFS, MountLayer};
