use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::time::SystemTime;
pub struct FileWatcher {
    paths: HashMap<String, Option<SystemTime>>,
}
impl FileWatcher {
    pub fn new() -> Self {
        Self {
            paths: HashMap::new(),
        }
    }
    pub fn watch<P: AsRef<Path>>(&mut self, path: P) {
        let key = path.as_ref().to_string_lossy().into_owned();
        let mtime = read_mtime(Path::new(&key));
        self.paths.insert(key, mtime);
    }
    pub fn unwatch<P: AsRef<Path>>(&mut self, path: P) {
        let key = path.as_ref().to_string_lossy().into_owned();
        self.paths.remove(&key);
    }
    pub fn is_watching<P: AsRef<Path>>(&self, path: P) -> bool {
        let key = path.as_ref().to_string_lossy().into_owned();
        self.paths.contains_key(&key)
    }
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
    pub fn len(&self) -> usize {
        self.paths.len()
    }
    pub fn is_empty(&self) -> bool {
        self.paths.is_empty()
    }
    pub fn force_changed(&mut self) {
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
pub fn read_mtime(path: &Path) -> Option<SystemTime> {
    std::fs::metadata(path).ok()?.modified().ok()
}
