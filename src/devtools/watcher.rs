//! Scope: File-system modification detection by polling mtime.
//! This file defines FileWatcher and change detection with optional native watcher.
//! It owns path registration, polling interval, and modification snapshots.

use crate::filesystem::watcher::read_mtime;
#[cfg(feature = "devtools-plugin")]
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
#[cfg(feature = "devtools-plugin")]
use std::sync::mpsc::{channel, Receiver};
use std::time::SystemTime;

// ── FileWatcher ────────────────────────────────────────────────────────────

/// Polling-based file-modification watcher.
///
/// # Fields
/// - `paths` — `HashMap<PathBuf, Option<SystemTime>>`.
#[derive(Debug, Default)]
pub struct FileWatcher {
    /// Map from watched path to last-known mtime (None = newly added, not yet polled).
    pub paths: HashMap<PathBuf, Option<SystemTime>>,
    #[cfg(feature = "devtools-plugin")]
    native: Option<NativeWatcher>,
}

#[cfg(feature = "devtools-plugin")]
#[derive(Debug)]
struct NativeWatcher {
    watcher: RecommendedWatcher,
    rx: Receiver<notify::Result<Event>>,
}

impl FileWatcher {
    /// Creates a new empty watcher.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        #[cfg(feature = "devtools-plugin")]
        {
            let native = Self::build_native();
            Self {
                paths: HashMap::new(),
                native,
            }
        }
        #[cfg(not(feature = "devtools-plugin"))]
        {
            Self::default()
        }
    }

    /// Adds a path to the watch list.  Accepts both files and directories.
    ///
    /// # Parameters
    /// - `path` — `&str`.
    pub fn watch(&mut self, path: &str) {
        let p = PathBuf::from(path);
        #[cfg(feature = "devtools-plugin")]
        if let Some(native) = self.native.as_mut() {
            let _ = native.watcher.watch(&p, RecursiveMode::NonRecursive);
        }
        self.paths.entry(p).or_insert(None);
    }

    /// Removes a path from the watch list.
    ///
    /// # Parameters
    /// - `path` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn unwatch(&mut self, path: &str) -> bool {
        let removed = self.paths.remove(Path::new(path)).is_some();
        #[cfg(feature = "devtools-plugin")]
        if removed {
            if let Some(native) = self.native.as_mut() {
                let _ = native.watcher.unwatch(Path::new(path));
            }
        }
        removed
    }

    /// Returns all currently watched paths.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn watched_paths(&self) -> Vec<String> {
        self.paths
            .keys()
            .map(|p| p.to_string_lossy().into_owned())
            .collect()
    }

    /// Polls all watched paths and returns paths that have changed since the
    /// last call to `poll`.
    ///
    /// # Returns
    /// `Vec<String>` of paths whose mtime changed.
    pub fn poll(&mut self) -> Vec<String> {
        let mut changed = std::collections::BTreeSet::new();

        #[cfg(feature = "devtools-plugin")]
        self.drain_native_events(&mut changed);

        for (path, last) in &mut self.paths {
            let current_mtime = read_mtime(path.as_path());
            match (&*last, current_mtime) {
                (None, new) => {
                    // First poll — record baseline without marking as changed.
                    *last = new;
                }
                (Some(prev), Some(cur)) if cur != *prev => {
                    changed.insert(path.to_string_lossy().into_owned());
                    *last = Some(cur);
                }
                (Some(_), None) => {
                    // File disappeared — treat as changed.
                    changed.insert(path.to_string_lossy().into_owned());
                    *last = None;
                }
                _ => {}
            }
        }
        changed.into_iter().collect()
    }

    /// Clears all watched paths.
    pub fn clear(&mut self) {
        #[cfg(feature = "devtools-plugin")]
        if let Some(native) = self.native.as_mut() {
            for path in self.paths.keys() {
                let _ = native.watcher.unwatch(path.as_path());
            }
        }
        self.paths.clear();
    }

    /// Marks all watched paths as changed so the next [`poll`][Self::poll] call
    /// reports them as modified regardless of the actual mtime on disk.
    ///
    /// Useful for programmatic reload triggers (e.g. `lurek.runtime.reloadConfig()`).
    pub fn force_changed(&mut self) {
        for last in self.paths.values_mut() {
            // Setting the mtime to `None` (newly added sentinel) means `poll`
            // will record the current mtime as a baseline on the next call —
            // which is indistinguishable from a first-seen path.  Instead we
            // corrupt the timestamp so the `cur != *prev` branch fires.
            *last = Some(std::time::UNIX_EPOCH);
        }
    }

    #[cfg(feature = "devtools-plugin")]
    fn build_native() -> Option<NativeWatcher> {
        let (tx, rx) = channel();
        let watcher = RecommendedWatcher::new(
            move |res| {
                let _ = tx.send(res);
            },
            Config::default(),
        )
        .ok()?;
        Some(NativeWatcher { watcher, rx })
    }

    #[cfg(feature = "devtools-plugin")]
    fn drain_native_events(&mut self, changed: &mut std::collections::BTreeSet<String>) {
        let Some(native) = self.native.as_mut() else {
            return;
        };

        while let Ok(event) = native.rx.try_recv() {
            let Ok(event) = event else {
                continue;
            };

            for event_path in event.paths {
                for watched in self.paths.keys() {
                    if event_path == *watched || event_path.starts_with(watched) {
                        changed.insert(watched.to_string_lossy().into_owned());
                    }
                }
            }
        }
    }
}
