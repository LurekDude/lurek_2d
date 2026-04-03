//! Mod management framework.
//!
//! Provides `ModInfo` for mod metadata and `ModManager` for registration,
//! dependency resolution, load ordering, folder scanning, and hot-reload queuing.
//!
//! This module is part of Luna2D's `modding` subsystem and provides the implementation
//! details for mod manager-related operations and data management.
//! Key types exported from this module: `ModInfo`, `ModManager`.
//! Primary functions: `new()`, `new()`, `register_mod()`, `unregister_mod()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::{HashMap, HashSet};

/// Metadata describing a mod. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `id` — `String`.
/// - `name` — `String`.
/// - `version` — `String`.
/// - `author` — `String`.
/// - `description` — `String`.
/// - `priority` — `i32`.
/// - `dependencies` — `Vec<String>`.
/// - `enabled` — `bool`.
/// - `loaded` — `bool`.
/// - `path` — `Option<String>`.
#[derive(Debug, Clone)]
pub struct ModInfo {
    /// Unique mod identifier.
    pub id: String,
    /// Human-readable display name.
    pub name: String,
    /// Version string (e.g. "1.0.0").
    pub version: String,
    /// Author name.
    pub author: String,
    /// Mod description.
    pub description: String,
    /// Load order priority (lower = loaded first).
    pub priority: i32,
    /// List of required mod IDs.
    pub dependencies: Vec<String>,
    /// Whether the mod is enabled.
    pub enabled: bool,
    /// Whether the mod has been loaded.
    pub loaded: bool,
    /// Filesystem path to the mod root folder, if known.
    pub path: Option<String>,
}

impl ModInfo {
    /// Create a new ModInfo with the given ID and sensible defaults.
    ///
    /// # Parameters
    /// - `id` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(id: impl Into<String>) -> Self {
        let id = id.into();
        Self {
            name: id.clone(),
            id,
            version: "1.0.0".to_string(),
            author: String::new(),
            description: String::new(),
            priority: 0,
            dependencies: Vec::new(),
            enabled: true,
            loaded: false,
            path: None,
        }
    }
}

/// Centralized registry for managing mods, resolving load order,
/// validating dependencies, scanning mod folders, and queuing hot-reloads.
///
/// # Fields
/// - `mods` — `Vec<ModInfo>`.
/// - `r` — `:load_order`].`.
/// - `custom_load_order` — `Option<Vec<String>>`.
/// - `reload_queue` — `Vec<String>`.
#[derive(Debug, Clone, Default)]
pub struct ModManager {
    mods: Vec<ModInfo>,
    /// Optional explicit load order (list of mod IDs in desired sequence).
    /// When `Some`, this overrides the default priority-based sort in [`ModManager::load_order`].
    custom_load_order: Option<Vec<String>>,
    /// Queue of mod IDs that have been marked for hot-reload.
    reload_queue: Vec<String>,
}

impl ModManager {
    /// Create a new empty ModManager. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            mods: Vec::new(),
            custom_load_order: None,
            reload_queue: Vec::new(),
        }
    }

    // ── Registration ──────────────────────────────────────────────────────

    /// Register a mod with the manager. Panics in debug mode if the same entity is registered twice.
    ///
    /// # Parameters
    /// - `info` — `ModInfo`.
    ///
    /// If a mod with the same ID already exists it is replaced.
    pub fn register_mod(&mut self, info: ModInfo) {
        if let Some(pos) = self.mods.iter().position(|m| m.id == info.id) {
            self.mods[pos] = info;
        } else {
            self.mods.push(info);
        }
    }

    /// Remove a mod by ID. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// Also removes the mod from the reload queue if present.
    /// Returns `true` if found.
    pub fn unregister_mod(&mut self, id: &str) -> bool {
        if let Some(pos) = self.mods.iter().position(|m| m.id == id) {
            self.mods.remove(pos);
            self.reload_queue.retain(|q| q != id);
            true
        } else {
            false
        }
    }

    /// Get a reference to a mod by ID.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&ModInfo>`.
    pub fn get_mod(&self, id: &str) -> Option<&ModInfo> {
        self.mods.iter().find(|m| m.id == id)
    }

    /// Get a mutable reference to a mod by ID.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut ModInfo>`.
    pub fn get_mod_mut(&mut self, id: &str) -> Option<&mut ModInfo> {
        self.mods.iter_mut().find(|m| m.id == id)
    }

    /// Check if a mod is registered. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_mod(&self, id: &str) -> bool {
        self.mods.iter().any(|m| m.id == id)
    }

    /// Get the number of registered mods. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `usize`.
    pub fn mod_count(&self) -> usize {
        self.mods.len()
    }

    /// Get all registered mods. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&[ModInfo]`.
    pub fn all_mods(&self) -> &[ModInfo] {
        &self.mods
    }

    // ── Load Order ────────────────────────────────────────────────────────

    /// Get mods in their effective load order. Returns an error if the source data is malformed or missing.
    ///
    /// # Returns
    /// `Vec<&ModInfo>`.
    ///
    /// When a custom load order is set via [`set_load_order`], it is respected:
    /// mods listed there appear first (in that order), followed by any remaining
    /// mods sorted by priority. Mods not registered are silently skipped.
    pub fn load_order(&self) -> Vec<&ModInfo> {
        if let Some(order) = &self.custom_load_order {
            let mut result: Vec<&ModInfo> = Vec::new();
            let mut seen: HashSet<&str> = HashSet::new();
            // Add mods in custom order first
            for id in order {
                if let Some(m) = self.mods.iter().find(|m| &m.id == id) {
                    result.push(m);
                    seen.insert(m.id.as_str());
                }
            }
            // Append remaining mods sorted by priority
            let mut remainder: Vec<&ModInfo> = self
                .mods
                .iter()
                .filter(|m| !seen.contains(m.id.as_str()))
                .collect();
            remainder.sort_by(|a, b| a.priority.cmp(&b.priority).then(a.id.cmp(&b.id)));
            result.extend(remainder);
            result
        } else {
            let mut sorted: Vec<&ModInfo> = self.mods.iter().collect();
            sorted.sort_by(|a, b| a.priority.cmp(&b.priority).then(a.id.cmp(&b.id)));
            sorted
        }
    }

    /// Set an explicit load order by providing a list of mod IDs.
    ///
    /// # Parameters
    /// - `order` — `Vec<String>`.
    ///
    /// Mods listed first load earliest. Mods not in the list are appended
    /// after the custom entries, sorted by priority.
    pub fn set_load_order(&mut self, order: Vec<String>) {
        self.custom_load_order = Some(order);
    }

    /// Clear any custom load order, reverting to priority-based sorting.
    pub fn clear_load_order(&mut self) {
        self.custom_load_order = None;
    }

    /// Returns a reference to the current custom load order, if any.
    ///
    /// # Returns
    /// `Option<&[String]>`.
    pub fn get_custom_load_order(&self) -> Option<&[String]> {
        self.custom_load_order.as_deref()
    }

    // ── Folder Scanning ───────────────────────────────────────────────────

    /// Scan a directory for mods and register them.
    ///
    /// # Parameters
    /// - `path` — `&str`.
    ///
    /// # Returns
    /// `Vec<ModInfo>`.
    ///
    /// Each immediate subdirectory of `path` that contains a `mod.toml` file is
    /// parsed into a [`ModInfo`] and registered. Subdirectories without `mod.toml`
    /// are silently skipped.
    ///
    /// Expected `mod.toml` fields (all optional except `id`):
    /// ```toml
    /// id          = "my-mod"
    /// name        = "My Mod"
    /// version     = "1.2.0"
    /// author      = "Author Name"
    /// description = "What this mod does"
    /// priority    = 10
    /// dependencies = ["other-mod"]
    /// ```
    ///
    /// Returns the list of `ModInfo` objects that were discovered and registered.
    /// Returns an empty list if `path` does not exist or cannot be read.
    pub fn scan_folder(&mut self, path: &str) -> Vec<ModInfo> {
        let mut discovered = Vec::new();

        let dir_iter = match std::fs::read_dir(path) {
            Ok(iter) => iter,
            Err(_) => return discovered,
        };

        for entry in dir_iter.flatten() {
            let entry_path = entry.path();
            if !entry_path.is_dir() {
                continue;
            }
            let toml_path = entry_path.join("mod.toml");
            if !toml_path.exists() {
                continue;
            }
            let content = match std::fs::read_to_string(&toml_path) {
                Ok(c) => c,
                Err(_) => continue,
            };
            let value: toml::Value = match content.parse() {
                Ok(v) => v,
                Err(_) => continue,
            };
            let table = match value.as_table() {
                Some(t) => t,
                None => continue,
            };
            let id = match table.get("id").and_then(|v| v.as_str()) {
                Some(s) => s.to_string(),
                None => continue, // id is required
            };
            let mut info = ModInfo::new(id);
            info.path = Some(entry_path.to_string_lossy().into_owned());
            if let Some(v) = table.get("name").and_then(|v| v.as_str()) {
                info.name = v.to_string();
            }
            if let Some(v) = table.get("version").and_then(|v| v.as_str()) {
                info.version = v.to_string();
            }
            if let Some(v) = table.get("author").and_then(|v| v.as_str()) {
                info.author = v.to_string();
            }
            if let Some(v) = table.get("description").and_then(|v| v.as_str()) {
                info.description = v.to_string();
            }
            if let Some(v) = table.get("priority").and_then(|v| v.as_integer()) {
                info.priority = v as i32;
            }
            if let Some(arr) = table.get("dependencies").and_then(|v| v.as_array()) {
                info.dependencies = arr
                    .iter()
                    .filter_map(|v| v.as_str().map(str::to_string))
                    .collect();
            }
            self.register_mod(info.clone());
            discovered.push(info);
        }

        discovered
    }

    // ── Hot-reload Queue ──────────────────────────────────────────────────

    /// Mark a registered mod for hot-reload. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    ///
    /// The mod ID is added to the reload queue (deduplicated).
    /// Returns `true` if the mod exists and was added to the queue.
    pub fn mark_for_reload(&mut self, id: &str) -> bool {
        if !self.has_mod(id) {
            return false;
        }
        if !self.reload_queue.contains(&id.to_string()) {
            self.reload_queue.push(id.to_string());
        }
        true
    }

    /// Returns the current reload queue (mod IDs pending hot-reload).
    ///
    /// # Returns
    /// `&[String]`.
    pub fn get_reload_queue(&self) -> &[String] {
        &self.reload_queue
    }

    /// Clear the reload queue without reloading anything.
    pub fn clear_reload_queue(&mut self) {
        self.reload_queue.clear();
    }

    // ── Dependency Validation ─────────────────────────────────────────────

    /// List mod IDs whose dependencies are missing.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn validate_dependencies(&self) -> Vec<String> {
        let ids: HashSet<&str> = self.mods.iter().map(|m| m.id.as_str()).collect();
        let mut missing = Vec::new();
        for m in &self.mods {
            for dep in &m.dependencies {
                if !ids.contains(dep.as_str()) && !missing.contains(dep) {
                    missing.push(dep.clone());
                }
            }
        }
        missing
    }

    /// Check for circular dependency cycles. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_circular_dependencies(&self) -> bool {
        let dep_map: HashMap<&str, Vec<&str>> = self
            .mods
            .iter()
            .map(|m| {
                (
                    m.id.as_str(),
                    m.dependencies.iter().map(|d| d.as_str()).collect(),
                )
            })
            .collect();

        let mut visited = HashSet::new();
        let mut visiting = HashSet::new();

        for m in &self.mods {
            if self.visit_cycle(m.id.as_str(), &dep_map, &mut visiting, &mut visited) {
                return true;
            }
        }
        false
    }

    fn visit_cycle<'a>(
        &self,
        id: &'a str,
        dep_map: &HashMap<&str, Vec<&'a str>>,
        visiting: &mut HashSet<&'a str>,
        visited: &mut HashSet<&'a str>,
    ) -> bool {
        if visiting.contains(id) {
            return true;
        }
        if visited.contains(id) {
            return false;
        }
        visiting.insert(id);
        if let Some(deps) = dep_map.get(id) {
            for &dep in deps {
                if self.visit_cycle(dep, dep_map, visiting, visited) {
                    return true;
                }
            }
        }
        visiting.remove(id);
        visited.insert(id);
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_mod_info_defaults() {
        let info = ModInfo::new("test-mod");
        assert_eq!(info.id, "test-mod");
        assert_eq!(info.name, "test-mod");
        assert_eq!(info.version, "1.0.0");
        assert!(info.enabled);
        assert!(!info.loaded);
        assert!(info.path.is_none());
    }

    #[test]
    fn register_and_lookup() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("mod-a"));
        assert!(mgr.has_mod("mod-a"));
        assert!(!mgr.has_mod("mod-b"));
        assert_eq!(mgr.mod_count(), 1);
    }

    #[test]
    fn unregister_mod() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("mod-a"));
        assert!(mgr.unregister_mod("mod-a"));
        assert!(!mgr.has_mod("mod-a"));
        assert!(!mgr.unregister_mod("mod-a"));
    }

    #[test]
    fn load_order_by_priority() {
        let mut mgr = ModManager::new();
        let mut b = ModInfo::new("mod-b");
        b.priority = 10;
        let mut a = ModInfo::new("mod-a");
        a.priority = 5;
        mgr.register_mod(b);
        mgr.register_mod(a);
        let order = mgr.load_order();
        assert_eq!(order[0].id, "mod-a");
        assert_eq!(order[1].id, "mod-b");
    }

    #[test]
    fn validate_deps_reports_missing() {
        let mut mgr = ModManager::new();
        let mut info = ModInfo::new("mod-a");
        info.dependencies = vec!["mod-b".to_string()];
        mgr.register_mod(info);
        let missing = mgr.validate_dependencies();
        assert_eq!(missing, vec!["mod-b"]);
    }

    #[test]
    fn validate_deps_ok_when_satisfied() {
        let mut mgr = ModManager::new();
        let mut a = ModInfo::new("mod-a");
        a.dependencies = vec!["mod-b".to_string()];
        mgr.register_mod(a);
        mgr.register_mod(ModInfo::new("mod-b"));
        let missing = mgr.validate_dependencies();
        assert!(missing.is_empty());
    }

    #[test]
    fn detect_circular_deps() {
        let mut mgr = ModManager::new();
        let mut a = ModInfo::new("a");
        a.dependencies = vec!["b".to_string()];
        let mut b = ModInfo::new("b");
        b.dependencies = vec!["a".to_string()];
        mgr.register_mod(a);
        mgr.register_mod(b);
        assert!(mgr.has_circular_dependencies());
    }

    #[test]
    fn no_circular_deps() {
        let mut mgr = ModManager::new();
        let mut a = ModInfo::new("a");
        a.dependencies = vec!["b".to_string()];
        mgr.register_mod(a);
        mgr.register_mod(ModInfo::new("b"));
        assert!(!mgr.has_circular_dependencies());
    }

    // ── New feature tests ─────────────────────────────────────────────────

    #[test]
    fn custom_load_order_respected() {
        let mut mgr = ModManager::new();
        let mut a = ModInfo::new("a");
        a.priority = 5;
        let mut b = ModInfo::new("b");
        b.priority = 1;
        mgr.register_mod(a);
        mgr.register_mod(b);
        // Without custom order, b (priority 1) would load first
        assert_eq!(mgr.load_order()[0].id, "b");
        // With custom order, a goes first
        mgr.set_load_order(vec!["a".to_string(), "b".to_string()]);
        assert_eq!(mgr.load_order()[0].id, "a");
        assert_eq!(mgr.load_order()[1].id, "b");
    }

    #[test]
    fn clear_load_order_reverts_to_priority() {
        let mut mgr = ModManager::new();
        let mut a = ModInfo::new("a");
        a.priority = 10;
        let mut b = ModInfo::new("b");
        b.priority = 1;
        mgr.register_mod(a);
        mgr.register_mod(b);
        mgr.set_load_order(vec!["a".to_string()]);
        mgr.clear_load_order();
        assert_eq!(mgr.load_order()[0].id, "b");
    }

    #[test]
    fn mark_for_reload_queues_mod() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("mod-a"));
        assert!(mgr.mark_for_reload("mod-a"));
        assert_eq!(mgr.get_reload_queue(), &["mod-a"]);
    }

    #[test]
    fn mark_for_reload_deduplicates() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("mod-a"));
        mgr.mark_for_reload("mod-a");
        mgr.mark_for_reload("mod-a");
        assert_eq!(mgr.get_reload_queue().len(), 1);
    }

    #[test]
    fn mark_for_reload_returns_false_for_missing() {
        let mut mgr = ModManager::new();
        assert!(!mgr.mark_for_reload("nonexistent"));
        assert!(mgr.get_reload_queue().is_empty());
    }

    #[test]
    fn clear_reload_queue_empties_it() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("a"));
        mgr.mark_for_reload("a");
        mgr.clear_reload_queue();
        assert!(mgr.get_reload_queue().is_empty());
    }

    #[test]
    fn unregister_removes_from_reload_queue() {
        let mut mgr = ModManager::new();
        mgr.register_mod(ModInfo::new("a"));
        mgr.mark_for_reload("a");
        mgr.unregister_mod("a");
        assert!(mgr.get_reload_queue().is_empty());
    }

    #[test]
    fn scan_folder_returns_empty_for_missing_path() {
        let mut mgr = ModManager::new();
        let found = mgr.scan_folder("/nonexistent/path/that/does/not/exist");
        assert!(found.is_empty());
    }

    #[test]
    fn scan_folder_registers_mods_from_disk() {
        use std::io::Write;
        let tmpdir = std::env::temp_dir().join("luna2d_scan_test");
        let _ = std::fs::remove_dir_all(&tmpdir);
        let mod_dir = tmpdir.join("my-mod");
        std::fs::create_dir_all(&mod_dir).unwrap();
        let toml_path = mod_dir.join("mod.toml");
        let mut f = std::fs::File::create(&toml_path).unwrap();
        writeln!(f, r#"id = "my-mod""#).unwrap();
        writeln!(f, r#"name = "My Mod""#).unwrap();
        writeln!(f, r#"version = "2.0.0""#).unwrap();
        writeln!(f, r#"priority = 5"#).unwrap();
        drop(f);

        let mut mgr = ModManager::new();
        let found = mgr.scan_folder(tmpdir.to_str().unwrap());
        assert_eq!(found.len(), 1);
        assert_eq!(found[0].id, "my-mod");
        assert_eq!(found[0].version, "2.0.0");
        assert_eq!(found[0].priority, 5);
        assert!(found[0].path.is_some());
        assert!(mgr.has_mod("my-mod"));

        // Clean up
        let _ = std::fs::remove_dir_all(&tmpdir);
    }
}
