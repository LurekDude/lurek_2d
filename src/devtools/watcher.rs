use crate::filesystem::watcher::read_mtime;
#[cfg(feature = "devtools-plugin")]
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
#[cfg(feature = "devtools-plugin")]
use std::sync::mpsc::{channel, Receiver};
use std::time::SystemTime;
#[derive(Debug, Default)]
pub struct FileWatcher {
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
    pub fn watch(&mut self, path: &str) {
        let p = PathBuf::from(path);
        #[cfg(feature = "devtools-plugin")]
        if let Some(native) = self.native.as_mut() {
            let _ = native.watcher.watch(&p, RecursiveMode::NonRecursive);
        }
        self.paths.entry(p).or_insert(None);
    }
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
    pub fn watched_paths(&self) -> Vec<String> {
        self.paths
            .keys()
            .map(|p| p.to_string_lossy().into_owned())
            .collect()
    }
    pub fn poll(&mut self) -> Vec<String> {
        let mut changed = std::collections::BTreeSet::new();
        #[cfg(feature = "devtools-plugin")]
        self.drain_native_events(&mut changed);
        for (path, last) in &mut self.paths {
            let current_mtime = read_mtime(path.as_path());
            match (&*last, current_mtime) {
                (None, new) => {
                    *last = new;
                }
                (Some(prev), Some(cur)) if cur != *prev => {
                    changed.insert(path.to_string_lossy().into_owned());
                    *last = Some(cur);
                }
                (Some(_), None) => {
                    changed.insert(path.to_string_lossy().into_owned());
                    *last = None;
                }
                _ => {}
            }
        }
        changed.into_iter().collect()
    }
    pub fn clear(&mut self) {
        #[cfg(feature = "devtools-plugin")]
        if let Some(native) = self.native.as_mut() {
            for path in self.paths.keys() {
                let _ = native.watcher.unwatch(path.as_path());
            }
        }
        self.paths.clear();
    }
    pub fn force_changed(&mut self) {
        for last in self.paths.values_mut() {
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
