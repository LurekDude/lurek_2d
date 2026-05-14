use std::collections::HashMap;
use std::io::Read;
use std::path::{Path, PathBuf};
/// ZIP-backed virtual mount with a cached virtual-path index.
pub struct ZipMount {
    /// Archive file path on disk.
    pub archive_path: PathBuf,
    /// Virtual path prefix applied to indexed entries.
    pub prefix: String,
    /// Normalized virtual path to archive entry name mapping.
    index: HashMap<String, String>,
}
impl ZipMount {
    /// Build a ZIP mount index or return an error on archive open or parse failure.
    pub fn new<P: AsRef<Path>>(archive_path: P, prefix: &str) -> Result<Self, String> {
        let path = archive_path.as_ref().to_path_buf();
        let file = std::fs::File::open(&path)
            .map_err(|e| format!("ZipMount: cannot open '{}': {}", path.display(), e))?;
        let archive = zip::ZipArchive::new(file)
            .map_err(|e| format!("ZipMount: invalid ZIP '{}': {}", path.display(), e))?;
        let clean_prefix = prefix.trim_matches('/').to_string();
        let mut index = HashMap::new();
        for i in 0..archive.len() {
            let file2 = std::fs::File::open(&path)
                .map_err(|e| format!("ZipMount: re-open failed: {}", e))?;
            let mut arc2 = zip::ZipArchive::new(file2)
                .map_err(|e| format!("ZipMount: re-open parse failed: {}", e))?;
            let entry = arc2
                .by_index(i)
                .map_err(|e| format!("ZipMount: index {}: {}", i, e))?;
            let entry_name = entry.name().to_string();
            if entry.is_file() {
                let virtual_path = if clean_prefix.is_empty() {
                    entry_name.clone()
                } else {
                    format!("{}/{}", clean_prefix, entry_name)
                };
                index.insert(normalise(&virtual_path), entry_name);
            }
        }
        Ok(Self {
            archive_path: path,
            prefix: clean_prefix,
            index,
        })
    }
    /// Read a virtual file from the archive or return an error when missing or invalid.
    pub fn read_file(&self, virtual_path: &str) -> Result<Vec<u8>, String> {
        let norm = normalise(virtual_path);
        if is_traversal(&norm) {
            return Err(format!(
                "ZipMount: path traversal rejected: '{}'",
                virtual_path
            ));
        }
        let entry_name = self
            .index
            .get(&norm)
            .ok_or_else(|| format!("ZipMount: file not found: '{}'", virtual_path))?
            .clone();
        let file = std::fs::File::open(&self.archive_path)
            .map_err(|e| format!("ZipMount: cannot open archive: {}", e))?;
        let mut archive =
            zip::ZipArchive::new(file).map_err(|e| format!("ZipMount: parse error: {}", e))?;
        let mut entry = archive
            .by_name(&entry_name)
            .map_err(|e| format!("ZipMount: entry '{}' not found: {}", entry_name, e))?;
        let mut buf = Vec::with_capacity(entry.size() as usize);
        entry
            .read_to_end(&mut buf)
            .map_err(|e| format!("ZipMount: read error: {}", e))?;
        Ok(buf)
    }
    /// Return true when the virtual path is indexed in the archive.
    pub fn contains(&self, virtual_path: &str) -> bool {
        let norm = normalise(virtual_path);
        self.index.contains_key(&norm)
    }
    /// Return all indexed virtual paths in sorted order.
    pub fn list_files(&self) -> Vec<String> {
        let mut paths: Vec<String> = self.index.keys().cloned().collect();
        paths.sort();
        paths
    }
}
/// Normalize a path to forward slashes and remove empty segments.
pub fn normalise(path: &str) -> String {
    let cleaned = path.replace('\\', "/");
    let parts: Vec<&str> = cleaned.split('/').filter(|s| !s.is_empty()).collect();
    parts.join("/")
}
/// Return true when a path contains traversal or absolute-path markers.
pub fn is_traversal(path: &str) -> bool {
    path.contains("..") || path.starts_with('/') || (path.len() >= 2 && path.as_bytes()[1] == b':')
}
