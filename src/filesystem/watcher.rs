//! - Poll-based file watcher that detects modification-time changes on registered paths.
//! - Maintains a path→mtime cache and reports diffs on each poll cycle.
//! - Supports watch/unwatch, forced invalidation, and empty-state queries.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::time::SystemTime;
/// Tracks a set of file paths and their last known modification times.
pub struct FileWatcher {
    /// Watched path keyed by its string form and cached modification time.
    paths: HashMap<String, Option<SystemTime>>,
}
impl FileWatcher {
    /// Create an empty file watcher.
    pub fn new() -> Self {
        Self {
            paths: HashMap::new(),
        }
    }
    /// Start watching a path and cache its current modification time.
    pub fn watch<P: AsRef<Path>>(&mut self, path: P) {
        let key = path.as_ref().to_string_lossy().into_owned();
        let mtime = read_mtime(Path::new(&key));
        self.paths.insert(key, mtime);
    }
    /// Stop watching a path if it is present.
    pub fn unwatch<P: AsRef<Path>>(&mut self, path: P) {
        let key = path.as_ref().to_string_lossy().into_owned();
        self.paths.remove(&key);
    }
    /// Return true when the watcher contains the path.
    pub fn is_watching<P: AsRef<Path>>(&self, path: P) -> bool {
        let key = path.as_ref().to_string_lossy().into_owned();
        self.paths.contains_key(&key)
    }
    /// Poll all watched paths and return the ones whose modification time changed.
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
    /// Return the number of watched paths.
    pub fn len(&self) -> usize {
        self.paths.len()
    }
    /// Return true when no paths are watched.
    pub fn is_empty(&self) -> bool {
        self.paths.is_empty()
    }
    /// Force all watched paths to report a change on the next poll.
    pub fn force_changed(&mut self) {
        for last in self.paths.values_mut() {
            *last = Some(std::time::UNIX_EPOCH);
        }
    }
}
impl Default for FileWatcher {
    /// Construct a default file watcher with no watched paths.
    fn default() -> Self {
        Self::new()
    }
}
/// Read the last modification time for a path or return None on metadata failure.
pub fn read_mtime(path: &Path) -> Option<SystemTime> {
    std::fs::metadata(path).ok()?.modified().ok()
}
