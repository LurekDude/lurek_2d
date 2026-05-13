//! Polling-based file watcher for development hot-reload workflows.
//!
//! [`FileWatcher`] tracks a set of paths (files or directories) and, when polled,
//! reports which paths have changed since the last poll by comparing
//! [`std::fs::Metadata::modified`] timestamps.
//!
//! No OS-native notification APIs are used (avoids `inotify`/`ReadDirectoryChangesW`
//! platform coupling).  The polling interval is controlled by the caller — typically
//! once per second during development.
//!
//! ## Usage
//! ```text
//! let mut watcher = FileWatcher::new();
//! watcher.watch("scripts/main.lua");
//! // ... later, in a slow update tick:
//! let changed = watcher.poll();  // returns paths that were modified
//! ```

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::time::SystemTime;

/// Polling file watcher that detects modification-time changes.
pub struct FileWatcher {
    /// Map from normalised path string → last known modification time.
    ///
    /// `None` means the file was missing on the last poll.
    paths: HashMap<String, Option<SystemTime>>,
}

impl FileWatcher {
    /// Creates an empty [`FileWatcher`] with no watched paths.
    pub fn new() -> Self {
        Self {
            paths: HashMap::new(),
        }
    }

    /// Adds `path` to the watch list.
    ///
    /// The path is recorded with its current modification time (or `None` if it
    /// does not exist yet), so the *next* `poll()` will only fire if the file
    /// changes *after* the `watch()` call.
    pub fn watch<P: AsRef<Path>>(&mut self, path: P) {
        let key = path.as_ref().to_string_lossy().into_owned();
        let mtime = read_mtime(Path::new(&key));
        self.paths.insert(key, mtime);
    }

    /// Removes `path` from the watch list.  No-op if the path was not watched.
    pub fn unwatch<P: AsRef<Path>>(&mut self, path: P) {
        let key = path.as_ref().to_string_lossy().into_owned();
        self.paths.remove(&key);
    }

    /// Returns `true` if `path` is currently on the watch list.
    pub fn is_watching<P: AsRef<Path>>(&self, path: P) -> bool {
        let key = path.as_ref().to_string_lossy().into_owned();
        self.paths.contains_key(&key)
    }

    /// Polls all watched paths and returns a sorted list of paths whose
    /// modification time has changed since the last call to `poll()` (or since
    /// `watch()` for newly added paths).
    ///
    /// Changed entries are updated in place so that the *next* `poll()` compares
    /// against the most recent modification time.
    pub fn poll(&mut self) -> Vec<PathBuf> {
        let mut changed = Vec::new();
        for (key, last) in &mut self.paths {
            let current = read_mtime(Path::new(key));
            if current != *last {
                *last = current;
                changed.push(PathBuf::from(key.clone()));
            }
        }
        changed.sort();
        changed
    }

    /// Returns the number of paths currently being watched.
    pub fn len(&self) -> usize {
        self.paths.len()
    }

    /// Returns `true` if no paths are being watched.
    pub fn is_empty(&self) -> bool {
        self.paths.is_empty()
    }

    /// Marks all watched paths as changed so the next [`poll`][Self::poll] call
    /// reports them regardless of the actual mtime on disk.
    ///
    /// Useful for programmatic reload triggers such as `lurek.runtime.reloadConfig()`.
    pub fn force_changed(&mut self) {
        // Corrupt stored mtimes to `UNIX_EPOCH` so the `current != *last` branch fires.
        for last in self.paths.values_mut() {
            *last = Some(std::time::UNIX_EPOCH);
        }
    }
}

impl Default for FileWatcher {
    fn default() -> Self {
        Self::new()
    }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

/// Read modification time for `path`.  Returns `None` if the file does not
/// exist or metadata cannot be obtained (permissions, etc.).
pub fn read_mtime(path: &Path) -> Option<SystemTime> {
    std::fs::metadata(path).ok()?.modified().ok()
}
