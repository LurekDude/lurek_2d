/// Sandboxed virtual filesystem that restricts I/O to the game directory.
pub mod vfs;

/// File handle with buffered read/write and sandboxed path resolution.
pub mod file_handle;

/// Background asset-loading worker that reads files off the main thread.
pub mod async_loader;

pub use async_loader::{AsyncLoader, LoadHandle, LoadResult, LoadStatus};
pub use file_handle::{FileHandle, FileMode};
pub use vfs::{FileInfo, FileType, GameFS};
