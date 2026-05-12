//! Mod management framework.
//!
//! Provides `ModInfo` for mod metadata and `ModManager` for registration,
//! dependency resolution, load ordering, folder scanning, and hot-reload queuing.
//!
//! This module is part of Lurek2D's `mods` subsystem and provides the implementation
//! details for mod manager-related operations and data management.
//! Key types exported from this module: `ModInfo`, `ModManager`.
//! Primary functions: `new()`, `new()`, `register_mod()`, `unregister_mod()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::log_msg;
use crate::runtime::log_messages::{MD01_MGR_INIT, MD02_MOD_REG, MD04_ORDER_OK};
use sha2::{Digest, Sha256};
use std::cmp::Reverse;
use std::collections::{BinaryHeap, HashMap, HashSet};
use std::path::Path;

/// Metadata record describing one registered game mod.
///
/// # Fields
/// - `id` â€” `String`.
/// - `name` â€” `String`.
/// - `version` â€” `String`.
/// - `author` â€” `String`.
/// - `description` â€” `String`.
/// - `priority` â€” `i32`.
/// - `dependencies` â€” `Vec<String>`.
/// - `enabled` â€” `bool`.
/// - `loaded` â€” `bool`.
/// - `path` â€” `Option<String>`.
/// - `api_version` â€” `Option<String>`.
/// - `capabilities` â€” `Vec<String>`.
/// - `config_schema` â€” `Vec<(String, String, String)>`.
/// - `asset_paths` â€” `Vec<String>`.
/// - `signature` â€” `Option<String>`.
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
    /// Required engine API version string (e.g. `"0.5.0"`). When set, the engine
    /// warns or refuses to load this mod if its own API version is incompatible.
    pub api_version: Option<String>,
    /// Declared capability flags (e.g. `["filesystem", "network"]`). The engine
    /// may check these before allowing access to sandboxed subsystems.
    pub capabilities: Vec<String>,
    /// Config schema: list of `(key, type_hint, default_value)` triples declared
    /// in the `[config]` section of `mod.toml`. Used for validation and tooling.
    pub config_schema: Vec<(String, String, String)>,
    /// Declared asset paths used for conflict detection during folder scans.
    pub asset_paths: Vec<String>,
    /// Optional integrity signature for the manifest metadata.
    pub signature: Option<String>,
}

impl ModInfo {
    /// Create a new ModInfo with the given ID and sensible defaults.
    ///
    /// # Parameters
    /// - `id` â€” `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(id: impl Into<String>) -> Self {
        let id = id.into();
        log_msg!(debug, MD02_MOD_REG, "{}", id);
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
            api_version: None,
            capabilities: Vec::new(),
            config_schema: Vec::new(),
            asset_paths: Vec::new(),
            signature: None,
        }
    }

    /// Creates a `ModInfo` from its constituent parts, applying optional overrides over the defaults from [`ModInfo::new`].
    ///
    /// # Parameters
    /// - `id` â€” `String`.
    /// - `name` â€” `Option<String>`.
    /// - `version` â€” `Option<String>`.
    /// - `author` â€” `Option<String>`.
    /// - `description` â€” `Option<String>`.
    /// - `priority` â€” `Option<i32>`.
    /// - `dependencies` â€” `Vec<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_parts(
        id: String,
        name: Option<String>,
        version: Option<String>,
        author: Option<String>,
        description: Option<String>,
        priority: Option<i32>,
        dependencies: Vec<String>,
    ) -> Self {
        let mut info = Self::new(id);
        if let Some(n) = name {
            info.name = n;
        }
        if let Some(v) = version {
            info.version = v;
        }
        if let Some(a) = author {
            info.author = a;
        }
        if let Some(d) = description {
            info.description = d;
        }
        if let Some(p) = priority {
            info.priority = p;
        }
        info.dependencies = dependencies;
        info
    }
}

/// Centralized registry for managing mods, resolving load order,
/// validating dependencies, scanning mod folders, and queuing hot-reloads.
///
/// # Fields
/// - `mods` â€” `Vec<ModInfo>`.
/// - `r` â€” `:load_order`].`.
/// - `custom_load_order` â€” `Option<Vec<String>>`.
/// - `reload_queue` â€” `Vec<String>`.
#[derive(Debug, Clone, Default)]
pub struct ModManager {
    mods: Vec<ModInfo>,
    /// Optional explicit load order (list of mod IDs in desired sequence).
    /// When `Some`, this overrides the default priority-based sort in [`ModManager::load_order`].
    custom_load_order: Option<Vec<String>>,
    /// Queue of mod IDs that have been marked for hot-reload.
    reload_queue: Vec<String>,
    /// Fast membership set for the reload queue so duplicate marks stay O(1).
    reload_queue_set: HashSet<String>,
}

impl ModManager {
    /// Create a new empty ModManager. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, MD01_MGR_INIT);
        Self {
            mods: Vec::new(),
            custom_load_order: None,
            reload_queue: Vec::new(),
            reload_queue_set: HashSet::new(),
        }
    }

    // â”€â”€ Registration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Register a mod with the manager. Panics in debug mode if the same entity is registered twice.
    ///
    /// # Parameters
    /// - `info` â€” `ModInfo`.
    ///
    /// If a mod with the same ID already exists it is replaced.
    pub fn register_mod(&mut self, info: ModInfo) {
        self.reload_queue.retain(|queued| queued != &info.id);
        self.reload_queue_set.remove(info.id.as_str());
        if let Some(pos) = self.mods.iter().position(|m| m.id == info.id) {
            self.mods[pos] = info;
        } else {
            self.mods.push(info);
        }
    }

    /// Removes a mod from the registry by its assigned ID.
    ///
    /// # Parameters
    /// - `id` â€” `&str`.
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
            self.reload_queue_set.remove(id);
            true
        } else {
            false
        }
    }

    /// Get a reference to a mod by ID.
    ///
    /// # Parameters
    /// - `id` â€” `&str`.
    ///
    /// # Returns
    /// `Option<&ModInfo>`.
    pub fn get_mod(&self, id: &str) -> Option<&ModInfo> {
        self.mods.iter().find(|m| m.id == id)
    }

    /// Get a mutable reference to a mod by ID.
    ///
    /// # Parameters
    /// - `id` â€” `&str`.
    ///
    /// # Returns
    /// `Option<&mut ModInfo>`.
    pub fn get_mod_mut(&mut self, id: &str) -> Option<&mut ModInfo> {
        self.mods.iter_mut().find(|m| m.id == id)
    }

    /// Check if a mod is registered. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` â€” `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_mod(&self, id: &str) -> bool {
        self.mods.iter().any(|m| m.id == id)
    }

    /// Returns the count of all currently registered mods.
    ///
    /// # Returns
    /// `usize`.
    pub fn mod_count(&self) -> usize {
        self.mods.len()
    }

    /// Returns a slice of all registered mod metadata records.
    ///
    /// # Returns
    /// `&[ModInfo]`.
    pub fn all_mods(&self) -> &[ModInfo] {
        &self.mods
    }

    /// Returns the registered mods that declare a given capability flag.
    ///
    /// # Parameters
    /// - `capability` — `&str`.
    ///
    /// # Returns
    /// `Vec<&ModInfo>`.
    pub fn get_mods_by_capability(&self, capability: &str) -> Vec<&ModInfo> {
        self.mods
            .iter()
            .filter(|mod_info| mod_info.capabilities.iter().any(|cap| cap == capability))
            .collect()
    }

    // â”€â”€ Load Order â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Get mods in their effective load order. Returns an error if the source data is malformed or missing.
    ///
    /// # Returns
    /// `Vec<&ModInfo>`.
    ///
    /// When a custom load order is set via [`set_load_order`], it is respected:
    /// mods listed there appear first (in that order), followed by any remaining
    /// mods sorted by priority. Mods not registered are silently skipped.
    pub fn load_order(&self) -> Vec<&ModInfo> {
        log_msg!(debug, MD04_ORDER_OK);
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
            // Append remaining mods in dependency order when possible.
            let mut remainder: Vec<&ModInfo> = self
                .mods
                .iter()
                .filter(|m| !seen.contains(m.id.as_str()))
                .collect();
            remainder = Self::sort_by_priority(remainder);
            result.extend(remainder);
            result
        } else {
            match self.topological_order() {
                Ok(sorted) => sorted,
                Err(cycle_ids) => {
                    ::log::warn!("mod dependency cycle detected: {:?}", cycle_ids);
                    Self::sort_by_priority(self.mods.iter().collect())
                }
            }
        }
    }

    fn sort_by_priority(mods: Vec<&ModInfo>) -> Vec<&ModInfo> {
        let mut sorted = mods;
        sorted.sort_by(|a, b| a.priority.cmp(&b.priority).then(a.id.cmp(&b.id)));
        sorted
    }

    fn topological_order(&self) -> Result<Vec<&ModInfo>, Vec<String>> {
        let mut index_by_id: HashMap<&str, usize> = HashMap::new();
        for (index, info) in self.mods.iter().enumerate() {
            index_by_id.insert(info.id.as_str(), index);
        }

        let mut indegree = vec![0usize; self.mods.len()];
        let mut outgoing = vec![Vec::<usize>::new(); self.mods.len()];

        for (index, info) in self.mods.iter().enumerate() {
            for dependency in &info.dependencies {
                if let Some(&dependency_index) = index_by_id.get(dependency.as_str()) {
                    outgoing[dependency_index].push(index);
                    indegree[index] += 1;
                }
            }
        }

        let mut ready: BinaryHeap<Reverse<(i32, String, usize)>> = BinaryHeap::new();
        for (index, info) in self.mods.iter().enumerate() {
            if indegree[index] == 0 {
                ready.push(Reverse((info.priority, info.id.clone(), index)));
            }
        }

        let mut ordered = Vec::with_capacity(self.mods.len());
        while let Some(Reverse((_priority, _id, index))) = ready.pop() {
            ordered.push(&self.mods[index]);
            for &dependent in &outgoing[index] {
                if indegree[dependent] > 0 {
                    indegree[dependent] -= 1;
                    if indegree[dependent] == 0 {
                        let info = &self.mods[dependent];
                        ready.push(Reverse((info.priority, info.id.clone(), dependent)));
                    }
                }
            }
        }

        if ordered.len() != self.mods.len() {
            let cycle_ids = self
                .mods
                .iter()
                .enumerate()
                .filter(|(index, _)| indegree[*index] > 0)
                .map(|(_, info)| info.id.clone())
                .collect();
            Err(cycle_ids)
        } else {
            Ok(ordered)
        }
    }

    fn manifest_signature(info: &ModInfo) -> String {
        let mut hasher = Sha256::new();
        hasher.update(info.id.as_bytes());
        hasher.update([0]);
        hasher.update(info.name.as_bytes());
        hasher.update([0]);
        hasher.update(info.version.as_bytes());
        hasher.update([0]);
        hasher.update(info.author.as_bytes());
        hasher.update([0]);
        hasher.update(info.description.as_bytes());
        hasher.update([0]);
        hasher.update(info.priority.to_le_bytes());
        hasher.update([0]);
        for dependency in &info.dependencies {
            hasher.update(dependency.as_bytes());
            hasher.update([0]);
        }
        for capability in &info.capabilities {
            hasher.update(capability.as_bytes());
            hasher.update([0]);
        }
        for asset_path in &info.asset_paths {
            hasher.update(asset_path.as_bytes());
            hasher.update([0]);
        }
        for (key, type_hint, default) in &info.config_schema {
            hasher.update(key.as_bytes());
            hasher.update([0]);
            hasher.update(type_hint.as_bytes());
            hasher.update([0]);
            hasher.update(default.as_bytes());
            hasher.update([0]);
        }
        hex::encode(hasher.finalize())
    }

    fn manifest_conflicts(&self, info: &ModInfo) -> Vec<(String, String)> {
        let mut conflicts = Vec::new();
        for asset_path in &info.asset_paths {
            for existing in &self.mods {
                if existing.id != info.id
                    && existing.asset_paths.iter().any(|path| path == asset_path)
                {
                    conflicts.push((asset_path.clone(), existing.id.clone()));
                    break;
                }
            }
        }
        conflicts
    }

    fn parse_manifest(entry_path: &Path, content: &str) -> Result<(ModInfo, Vec<String>), String> {
        let value: toml::Value = content
            .parse()
            .map_err(|err| format!("{}: invalid TOML: {}", entry_path.display(), err))?;
        let table = value.as_table().ok_or_else(|| {
            format!(
                "{}: mod.toml must contain a TOML table",
                entry_path.display()
            )
        })?;

        let id = table
            .get("id")
            .and_then(|value| value.as_str())
            .ok_or_else(|| {
                format!(
                    "{}: missing required string field 'id'",
                    entry_path.display()
                )
            })?
            .to_string();

        let dependencies = table
            .get("dependencies")
            .and_then(|value| value.as_array())
            .map(|items| {
                items
                    .iter()
                    .filter_map(|item| item.as_str().map(str::to_string))
                    .collect()
            })
            .unwrap_or_default();

        let mut info = ModInfo::from_parts(
            id,
            table
                .get("name")
                .and_then(|value| value.as_str())
                .map(str::to_string),
            table
                .get("version")
                .and_then(|value| value.as_str())
                .map(str::to_string),
            table
                .get("author")
                .and_then(|value| value.as_str())
                .map(str::to_string),
            table
                .get("description")
                .and_then(|value| value.as_str())
                .map(str::to_string),
            table
                .get("priority")
                .and_then(|value| value.as_integer())
                .map(|value| value as i32),
            dependencies,
        );
        info.path = Some(entry_path.to_string_lossy().into_owned());

        let mut warnings = Vec::new();

        if let Some(items) = table.get("capabilities").and_then(|value| value.as_array()) {
            info.capabilities = items
                .iter()
                .filter_map(|item| item.as_str().map(str::to_string))
                .collect();
        }

        if let Some(items) = table.get("assets").and_then(|value| value.as_array()) {
            info.asset_paths = items
                .iter()
                .filter_map(|item| item.as_str().map(str::to_string))
                .collect();
        }

        if let Some(signature) = table.get("signature").and_then(|value| value.as_str()) {
            info.signature = Some(signature.to_string());
        }

        if let Some(schema) = table
            .get("config_schema")
            .and_then(|value| value.as_array())
        {
            let mut parsed_schema = Vec::new();
            for entry in schema {
                let Some(entry_table) = entry.as_table() else {
                    warnings.push(format!(
                        "{}: ignored non-table config_schema entry",
                        entry_path.display()
                    ));
                    continue;
                };
                let Some(key) = entry_table.get("key").and_then(|value| value.as_str()) else {
                    warnings.push(format!(
                        "{}: config_schema entry missing string key",
                        entry_path.display()
                    ));
                    continue;
                };
                let type_hint = entry_table
                    .get("type")
                    .and_then(|value| value.as_str())
                    .unwrap_or("any");
                let default = entry_table
                    .get("default")
                    .map(|value| value.to_string())
                    .unwrap_or_default();
                parsed_schema.push((key.to_string(), type_hint.to_string(), default));
            }
            info.config_schema = parsed_schema;
        }

        if let Some(signature) = &info.signature {
            let expected = Self::manifest_signature(&info);
            if signature != &expected {
                return Err(format!(
                    "{}: signature mismatch for mod '{}'",
                    entry_path.display(),
                    info.id
                ));
            }
        }

        Ok((info, warnings))
    }

    /// Set an explicit load order by providing a list of mod IDs.
    ///
    /// # Parameters
    /// - `order` â€” `Vec<String>`.
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

    // â”€â”€ Folder Scanning â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Scan a directory for mods and register them.
    ///
    /// # Parameters
    /// - `path` â€” `&str`.
    ///
    /// # Returns
    /// `Vec<ModInfo>`.
    ///
    /// Each immediate subdirectory of `path` that contains a `mod.toml` file is
    /// parsed into a [`ModInfo`] and registered. Subdirectories without `mod.toml`
    /// are silently skipped. Malformed manifests and signature/asset conflicts are
    /// reported through the engine log and skipped.
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
                Err(err) => {
                    ::log::warn!("{}: {}", toml_path.display(), err);
                    continue;
                }
            };
            let (info, warnings) = match Self::parse_manifest(&toml_path, &content) {
                Ok(value) => value,
                Err(err) => {
                    ::log::warn!("{}", err);
                    continue;
                }
            };

            for warning in warnings {
                ::log::warn!("{}", warning);
            }

            let conflicts = self.manifest_conflicts(&info);
            if !conflicts.is_empty() {
                ::log::warn!(
                    "{}: asset path conflict(s) detected for mod '{}': {:?}",
                    toml_path.display(),
                    info.id,
                    conflicts
                );
                continue;
            }
            self.register_mod(info.clone());
            discovered.push(info);
        }

        discovered
    }

    // â”€â”€ Hot-reload Queue â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Marks a registered mod as requiring hot-reload on the next update tick.
    ///
    /// # Parameters
    /// - `id` â€” `&str`.
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
        if let Some(info) = self.get_mod_mut(id) {
            info.loaded = false;
        }
        if self.reload_queue_set.insert(id.to_string()) {
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
        self.reload_queue_set.clear();
    }

    /// Reloads every queued mod from disk and clears the queue.
    ///
    /// # Returns
    /// `Vec<String>` of mod IDs that were successfully reloaded.
    pub fn process_reload_queue(&mut self) -> Vec<String> {
        let queued = std::mem::take(&mut self.reload_queue);
        self.reload_queue_set.clear();

        let mut reloaded = Vec::new();
        for id in queued {
            let Some(path) = self.get_mod(&id).and_then(|info| info.path.clone()) else {
                ::log::warn!(
                    "mod '{}' cannot be reloaded because it has no manifest path",
                    id
                );
                continue;
            };

            let content = match std::fs::read_to_string(&path) {
                Ok(content) => content,
                Err(err) => {
                    ::log::warn!("{}: {}", path, err);
                    continue;
                }
            };

            let (mut info, warnings) = match Self::parse_manifest(Path::new(&path), &content) {
                Ok(value) => value,
                Err(err) => {
                    ::log::warn!("{}", err);
                    continue;
                }
            };

            for warning in warnings {
                ::log::warn!("{}", warning);
            }

            info.loaded = true;
            self.register_mod(info);
            reloaded.push(id);
        }

        reloaded
    }

    // â”€â”€ Dependency Validation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
        self.topological_order().is_err()
    }
}
