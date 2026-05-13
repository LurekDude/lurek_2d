use crate::log_msg;
use crate::runtime::log_messages::{MD01_MGR_INIT, MD02_MOD_REG, MD04_ORDER_OK};
use sha2::{Digest, Sha256};
use std::cmp::Reverse;
use std::collections::{BinaryHeap, HashMap, HashSet};
use std::path::Path;
#[derive(Debug, Clone)]
pub struct ModInfo {
    pub id: String,
    pub name: String,
    pub version: String,
    pub author: String,
    pub description: String,
    pub priority: i32,
    pub dependencies: Vec<String>,
    pub enabled: bool,
    pub loaded: bool,
    pub path: Option<String>,
    pub api_version: Option<String>,
    pub capabilities: Vec<String>,
    pub config_schema: Vec<(String, String, String)>,
    pub asset_paths: Vec<String>,
    pub signature: Option<String>,
}
impl ModInfo {
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
#[derive(Debug, Clone, Default)]
pub struct ModManager {
    mods: Vec<ModInfo>,
    custom_load_order: Option<Vec<String>>,
    reload_queue: Vec<String>,
    reload_queue_set: HashSet<String>,
}
impl ModManager {
    pub fn new() -> Self {
        log_msg!(debug, MD01_MGR_INIT);
        Self {
            mods: Vec::new(),
            custom_load_order: None,
            reload_queue: Vec::new(),
            reload_queue_set: HashSet::new(),
        }
    }
    pub fn register_mod(&mut self, info: ModInfo) {
        self.reload_queue.retain(|queued| queued != &info.id);
        self.reload_queue_set.remove(info.id.as_str());
        if let Some(pos) = self.mods.iter().position(|m| m.id == info.id) {
            self.mods[pos] = info;
        } else {
            self.mods.push(info);
        }
    }
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
    pub fn get_mod(&self, id: &str) -> Option<&ModInfo> {
        self.mods.iter().find(|m| m.id == id)
    }
    pub fn get_mod_mut(&mut self, id: &str) -> Option<&mut ModInfo> {
        self.mods.iter_mut().find(|m| m.id == id)
    }
    pub fn has_mod(&self, id: &str) -> bool {
        self.mods.iter().any(|m| m.id == id)
    }
    pub fn mod_count(&self) -> usize {
        self.mods.len()
    }
    pub fn all_mods(&self) -> &[ModInfo] {
        &self.mods
    }
    pub fn get_mods_by_capability(&self, capability: &str) -> Vec<&ModInfo> {
        self.mods
            .iter()
            .filter(|mod_info| mod_info.capabilities.iter().any(|cap| cap == capability))
            .collect()
    }
    pub fn load_order(&self) -> Vec<&ModInfo> {
        log_msg!(debug, MD04_ORDER_OK);
        if let Some(order) = &self.custom_load_order {
            let mut result: Vec<&ModInfo> = Vec::new();
            let mut seen: HashSet<&str> = HashSet::new();
            for id in order {
                if let Some(m) = self.mods.iter().find(|m| &m.id == id) {
                    result.push(m);
                    seen.insert(m.id.as_str());
                }
            }
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
    pub fn set_load_order(&mut self, order: Vec<String>) {
        self.custom_load_order = Some(order);
    }
    pub fn clear_load_order(&mut self) {
        self.custom_load_order = None;
    }
    pub fn get_custom_load_order(&self) -> Option<&[String]> {
        self.custom_load_order.as_deref()
    }
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
    pub fn get_reload_queue(&self) -> &[String] {
        &self.reload_queue
    }
    pub fn clear_reload_queue(&mut self) {
        self.reload_queue.clear();
        self.reload_queue_set.clear();
    }
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
    pub fn has_circular_dependencies(&self) -> bool {
        self.topological_order().is_err()
    }
}
