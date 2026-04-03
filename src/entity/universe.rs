//! Universe — a self-contained ECS world. Entities are u32 IDs starting at 1.
//!
//! This module is part of Luna2D's `entity` subsystem and provides the implementation
//! details for universe-related operations and data management.
//! Key types exported from this module: `Universe`.
//! Primary functions: `new()`, `get_system_store()`, `spawn()`, `kill()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use mlua::{Function, Lua, RegistryKey, Result as LuaResult, Table, Value as LuaValue};
use std::collections::{HashMap, HashSet};

/// Maximum number of bitmap tag definitions per Universe.
const MAX_BITMAP_TAGS: usize = 63;

/// A self-contained ECS world. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Manages entities (u32 IDs with recycling), components (stored in Lua registry tables),
/// string and bitmap tags, layers, blueprints, and systems.
///
/// # Fields
/// - `next_id` — `u32`.
/// - `free_list` — `Vec<u32>`.
/// - `alive` — `HashSet<u32>`.
/// - `string_tags` — `HashMap<u32`.
/// - `bitmap_tag_names` — `Vec<String>`.
/// - `bitmap_masks` — `HashMap<u32`.
/// - `layers` — `HashMap<u32`.
/// - `component_store` — `Option<RegistryKey>`.
/// - `blueprint_store` — `Option<RegistryKey>`.
/// - `system_store` — `Option<RegistryKey>`.
pub struct Universe {
    next_id: u32,
    free_list: Vec<u32>,
    alive: HashSet<u32>,
    string_tags: HashMap<u32, Vec<String>>,
    bitmap_tag_names: Vec<String>,
    bitmap_masks: HashMap<u32, u64>,
    layers: HashMap<u32, i32>,
    component_store: Option<RegistryKey>,
    blueprint_store: Option<RegistryKey>,
    system_store: Option<RegistryKey>,
}

impl Universe {
    /// Creates a new empty Universe. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            next_id: 1,
            free_list: Vec::new(),
            alive: HashSet::new(),
            string_tags: HashMap::new(),
            bitmap_tag_names: Vec::new(),
            bitmap_masks: HashMap::new(),
            layers: HashMap::new(),
            component_store: None,
            blueprint_store: None,
            system_store: None,
        }
    }

    /// Lazily initializes the Lua registry stores for components, blueprints, and systems.
    fn ensure_stores(&mut self, lua: &Lua) -> LuaResult<()> {
        if self.component_store.is_none() {
            self.component_store = Some(lua.create_registry_value(lua.create_table()?)?);
        }
        if self.blueprint_store.is_none() {
            self.blueprint_store = Some(lua.create_registry_value(lua.create_table()?)?);
        }
        if self.system_store.is_none() {
            self.system_store = Some(lua.create_registry_value(lua.create_table()?)?);
        }
        Ok(())
    }

    fn get_component_store<'lua>(&self, lua: &'lua Lua) -> LuaResult<Table<'lua>> {
        let key = self
            .component_store
            .as_ref()
            .ok_or_else(|| mlua::Error::runtime("Universe not initialized"))?;
        lua.registry_value::<Table>(key)
    }

    fn get_blueprint_store<'lua>(&self, lua: &'lua Lua) -> LuaResult<Table<'lua>> {
        let key = self
            .blueprint_store
            .as_ref()
            .ok_or_else(|| mlua::Error::runtime("Universe not initialized"))?;
        lua.registry_value::<Table>(key)
    }

    /// get_system_store. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `lua` — `&'lua Lua`.
    ///
    /// # Returns
    /// `LuaResult<Table<'lua>>`.
    pub fn get_system_store<'lua>(&self, lua: &'lua Lua) -> LuaResult<Table<'lua>> {
        let key = self
            .system_store
            .as_ref()
            .ok_or_else(|| mlua::Error::runtime("Universe not initialized"))?;
        lua.registry_value::<Table>(key)
    }

    // === Entity Lifecycle ===

    /// Spawns a new entity and returns its ID. Recycles from the free list when possible.
    ///
    /// # Returns
    /// `u32`.
    pub fn spawn(&mut self) -> u32 {
        let id = if let Some(recycled) = self.free_list.pop() {
            recycled
        } else {
            let id = self.next_id;
            self.next_id += 1;
            id
        };
        self.alive.insert(id);
        id
    }

    /// Kills an entity, cleaning up all associated data and recycling the ID.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `lua` — `&Lua`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn kill(&mut self, id: u32, lua: &Lua) -> LuaResult<()> {
        if !self.alive.remove(&id) {
            return Ok(());
        }
        // Clean up component data
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            store.set(id, LuaValue::Nil)?;
        }
        // Clean up tags and layers
        self.string_tags.remove(&id);
        self.bitmap_masks.remove(&id);
        self.layers.remove(&id);
        // Recycle
        self.free_list.push(id);
        Ok(())
    }

    /// Returns whether an entity ID is currently alive.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_alive(&self, id: u32) -> bool {
        self.alive.contains(&id)
    }

    /// Returns the number of alive entities. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `usize`.
    pub fn get_entity_count(&self) -> usize {
        self.alive.len()
    }

    /// Returns all alive entity IDs (unordered).
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn get_entities(&self) -> Vec<u32> {
        self.alive.iter().copied().collect()
    }

    // === Component Operations ===

    /// Sets a component value on an entity. Replaces the current component value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `id` — `u32`.
    /// - `name` — `&str`.
    /// - `value` — `LuaValue`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn set_component(
        &mut self,
        lua: &Lua,
        id: u32,
        name: &str,
        value: LuaValue,
    ) -> LuaResult<()> {
        if !self.is_alive(id) {
            return Err(mlua::Error::runtime(format!("Entity {} is not alive", id)));
        }
        self.ensure_stores(lua)?;
        let store = self.get_component_store(lua)?;
        let entity_table: Table = match store.get::<_, Table>(id) {
            Ok(t) => t,
            Err(_) => {
                let t = lua.create_table()?;
                store.set(id, t.clone())?;
                t
            }
        };
        entity_table.set(name, value)?;
        Ok(())
    }

    /// Gets a component value from an entity (returns Nil if missing or dead).
    ///
    /// # Parameters
    /// - `lua` — `&'lua Lua`.
    /// - `id` — `u32`.
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `LuaResult<LuaValue<'lua>>`.
    pub fn get_component<'lua>(
        &self,
        lua: &'lua Lua,
        id: u32,
        name: &str,
    ) -> LuaResult<LuaValue<'lua>> {
        if !self.is_alive(id) {
            return Ok(LuaValue::Nil);
        }
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(entity_table) = store.get::<_, Table>(id) {
                return entity_table.get::<_, LuaValue>(name);
            }
        }
        Ok(LuaValue::Nil)
    }

    /// Returns whether an entity has a named component.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `id` — `u32`.
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `LuaResult<bool>`.
    pub fn has_component(&self, lua: &Lua, id: u32, name: &str) -> LuaResult<bool> {
        if !self.is_alive(id) {
            return Ok(false);
        }
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(entity_table) = store.get::<_, Table>(id) {
                let val: LuaValue = entity_table.get(name)?;
                return Ok(!val.is_nil());
            }
        }
        Ok(false)
    }

    /// Removes a component from an entity. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `id` — `u32`.
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn remove_component(&self, lua: &Lua, id: u32, name: &str) -> LuaResult<()> {
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(entity_table) = store.get::<_, Table>(id) {
                entity_table.set(name, LuaValue::Nil)?;
            }
        }
        Ok(())
    }

    /// Returns all component names for an entity.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `LuaResult<Vec<String>>`.
    pub fn get_component_names(&self, lua: &Lua, id: u32) -> LuaResult<Vec<String>> {
        let mut names = Vec::new();
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(entity_table) = store.get::<_, Table>(id) {
                for pair in entity_table.pairs::<String, LuaValue>() {
                    let (k, _) = pair?;
                    names.push(k);
                }
            }
        }
        Ok(names)
    }

    /// Returns all alive entities that have ALL listed component names.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `names` — `&[String]`.
    ///
    /// # Returns
    /// `LuaResult<Vec<u32>>`.
    pub fn query(&self, lua: &Lua, names: &[String]) -> LuaResult<Vec<u32>> {
        let mut result = Vec::new();
        if names.is_empty() {
            return Ok(self.get_entities());
        }
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            for &id in &self.alive {
                if let Ok(entity_table) = store.get::<_, Table>(id) {
                    let mut all = true;
                    for name in names {
                        let val: LuaValue = entity_table.get(name.as_str())?;
                        if val.is_nil() {
                            all = false;
                            break;
                        }
                    }
                    if all {
                        result.push(id);
                    }
                }
            }
        }
        result.sort();
        Ok(result)
    }

    /// Calls `callback(id, value)` for every alive entity that has the named component.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `name` — `&str`.
    /// - `callback` — `Function`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn each(&self, lua: &Lua, name: &str, callback: Function) -> LuaResult<()> {
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            let mut ids: Vec<u32> = self.alive.iter().copied().collect();
            ids.sort();
            for id in ids {
                if let Ok(entity_table) = store.get::<_, Table>(id) {
                    let val: LuaValue = entity_table.get(name)?;
                    if !val.is_nil() {
                        callback.call::<_, ()>((id, val))?;
                    }
                }
            }
        }
        Ok(())
    }

    // === String Tags ===

    /// Adds a string tag to an entity (no-op if already present or entity is dead).
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `tag` — `&str`.
    pub fn add_tag(&mut self, id: u32, tag: &str) {
        if !self.is_alive(id) {
            return;
        }
        let tags = self.string_tags.entry(id).or_default();
        let tag_str = tag.to_string();
        if !tags.contains(&tag_str) {
            tags.push(tag_str);
        }
    }

    /// Removes a string tag from an entity. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `tag` — `&str`.
    pub fn remove_tag(&mut self, id: u32, tag: &str) {
        if let Some(tags) = self.string_tags.get_mut(&id) {
            tags.retain(|t| t != tag);
        }
    }

    /// Returns whether an entity has a specific string tag.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `tag` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_tag(&self, id: u32, tag: &str) -> bool {
        self.string_tags
            .get(&id)
            .map(|tags| tags.iter().any(|t| t == tag))
            .unwrap_or(false)
    }

    /// Returns all string tags for an entity. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn get_tags(&self, id: u32) -> Vec<String> {
        self.string_tags.get(&id).cloned().unwrap_or_default()
    }

    /// Returns all alive entities that have the given string tag.
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn get_entities_by_tag(&self, tag: &str) -> Vec<u32> {
        let mut result: Vec<u32> = self
            .alive
            .iter()
            .filter(|&&id| self.has_tag(id, tag))
            .copied()
            .collect();
        result.sort();
        result
    }

    // === Bitmap Tags ===

    fn get_or_define_tag_bit(&mut self, name: &str) -> LuaResult<u8> {
        if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
            return Ok(pos as u8);
        }
        if self.bitmap_tag_names.len() >= MAX_BITMAP_TAGS {
            return Err(mlua::Error::runtime(format!(
                "Maximum of {} bitmap tags reached",
                MAX_BITMAP_TAGS
            )));
        }
        let bit = self.bitmap_tag_names.len() as u8;
        self.bitmap_tag_names.push(name.to_string());
        Ok(bit)
    }

    /// Defines a bitmap tag name, returning its bit index.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `LuaResult<u8>`.
    pub fn define_tag(&mut self, name: &str) -> LuaResult<u8> {
        self.get_or_define_tag_bit(name)
    }

    /// Adds a bitmap tag to an entity (auto-defines the tag if needed).
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn bitmap_tag(&mut self, id: u32, name: &str) -> LuaResult<()> {
        if !self.is_alive(id) {
            return Ok(());
        }
        let bit = self.get_or_define_tag_bit(name)?;
        let mask = self.bitmap_masks.entry(id).or_insert(0);
        *mask |= 1u64 << bit;
        Ok(())
    }

    /// Removes a bitmap tag from an entity. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `name` — `&str`.
    pub fn bitmap_untag(&mut self, id: u32, name: &str) {
        if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
            if let Some(mask) = self.bitmap_masks.get_mut(&id) {
                *mask &= !(1u64 << pos);
            }
        }
    }

    /// Returns whether an entity has a specific bitmap tag.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_bitmap_tag(&self, id: u32, name: &str) -> bool {
        if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
            if let Some(mask) = self.bitmap_masks.get(&id) {
                return (*mask & (1u64 << pos)) != 0;
            }
        }
        false
    }

    /// Returns all alive entities with the given bitmap tag.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn query_bitmap_tag(&self, name: &str) -> Vec<u32> {
        if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
            let bit = 1u64 << pos;
            let mut result: Vec<u32> = self
                .alive
                .iter()
                .filter(|&&id| {
                    self.bitmap_masks
                        .get(&id)
                        .map(|m| m & bit != 0)
                        .unwrap_or(false)
                })
                .copied()
                .collect();
            result.sort();
            result
        } else {
            Vec::new()
        }
    }

    /// Returns all alive entities that have ANY of the listed bitmap tags.
    ///
    /// # Parameters
    /// - `names` — `&[String]`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn query_bitmap_any(&self, names: &[String]) -> Vec<u32> {
        let mut combined = 0u64;
        for name in names {
            if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
                combined |= 1u64 << pos;
            }
        }
        if combined == 0 {
            return Vec::new();
        }
        let mut result: Vec<u32> = self
            .alive
            .iter()
            .filter(|&&id| {
                self.bitmap_masks
                    .get(&id)
                    .map(|m| m & combined != 0)
                    .unwrap_or(false)
            })
            .copied()
            .collect();
        result.sort();
        result
    }

    /// Returns all alive entities that have ALL of the listed bitmap tags.
    ///
    /// # Parameters
    /// - `names` — `&[String]`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn query_bitmap_all(&self, names: &[String]) -> Vec<u32> {
        let mut combined = 0u64;
        for name in names {
            if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
                combined |= 1u64 << pos;
            } else {
                return Vec::new(); // tag not defined → no entities can match
            }
        }
        if combined == 0 {
            return Vec::new();
        }
        let mut result: Vec<u32> = self
            .alive
            .iter()
            .filter(|&&id| {
                self.bitmap_masks
                    .get(&id)
                    .map(|m| m & combined == combined)
                    .unwrap_or(false)
            })
            .copied()
            .collect();
        result.sort();
        result
    }

    /// Returns the bit index for a bitmap tag name, if defined.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<u8>`.
    pub fn get_bitmap_tag_bit(&self, name: &str) -> Option<u8> {
        self.bitmap_tag_names
            .iter()
            .position(|n| n == name)
            .map(|p| p as u8)
    }

    // === Layer System ===

    /// Sets the layer for an entity (default layer is 0).
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `layer` — `i32`.
    pub fn set_layer(&mut self, id: u32, layer: i32) {
        if self.is_alive(id) {
            self.layers.insert(id, layer);
        }
    }

    /// Returns the layer for an entity (defaults to 0).
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `i32`.
    pub fn get_layer(&self, id: u32) -> i32 {
        self.layers.get(&id).copied().unwrap_or(0)
    }

    /// Returns all alive entities on a specific layer.
    ///
    /// # Parameters
    /// - `layer` — `i32`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn get_entities_by_layer(&self, layer: i32) -> Vec<u32> {
        let mut result: Vec<u32> = self
            .alive
            .iter()
            .filter(|&&id| self.get_layer(id) == layer)
            .copied()
            .collect();
        result.sort();
        result
    }

    /// Returns all alive entities sorted by layer (ascending), then by ID.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn get_entities_sorted(&self) -> Vec<u32> {
        let mut entities: Vec<u32> = self.alive.iter().copied().collect();
        entities.sort_by(|a, b| {
            let la = self.get_layer(*a);
            let lb = self.get_layer(*b);
            la.cmp(&lb).then(a.cmp(b))
        });
        entities
    }

    // === Blueprints ===

    /// Defines a blueprint by deep-copying the given component table.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `name` — `&str`.
    /// - `components` — `Table`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn define_blueprint(&mut self, lua: &Lua, name: &str, components: Table) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let bp_store = self.get_blueprint_store(lua)?;
        let copy = deep_copy_table(lua, &components)?;
        bp_store.set(name, copy)?;
        Ok(())
    }

    /// Defines a blueprint by extending a parent blueprint with overrides.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `name` — `&str`.
    /// - `parent` — `&str`.
    /// - `overrides` — `Table`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn extend_blueprint(
        &mut self,
        lua: &Lua,
        name: &str,
        parent: &str,
        overrides: Table,
    ) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let bp_store = self.get_blueprint_store(lua)?;
        let parent_table: Table = bp_store.get(parent).map_err(|_| {
            mlua::Error::runtime(format!("Parent blueprint '{}' not found", parent))
        })?;
        // Deep copy parent
        let merged = deep_copy_table(lua, &parent_table)?;
        // Shallow merge overrides
        for pair in overrides.pairs::<LuaValue, LuaValue>() {
            let (k, v) = pair?;
            merged.set(k, v)?;
        }
        bp_store.set(name, merged)?;
        Ok(())
    }

    /// Spawns an entity from a blueprint, applying optional overrides.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `name` — `&str`.
    /// - `overrides` — `Option<Table>`.
    ///
    /// # Returns
    /// `LuaResult<u32>`.
    pub fn spawn_blueprint(
        &mut self,
        lua: &Lua,
        name: &str,
        overrides: Option<Table>,
    ) -> LuaResult<u32> {
        self.ensure_stores(lua)?;
        let bp_store = self.get_blueprint_store(lua)?;
        let bp_table: Table = bp_store
            .get(name)
            .map_err(|_| mlua::Error::runtime(format!("Blueprint '{}' not defined", name)))?;
        let id = self.spawn();
        let store = self.get_component_store(lua)?;
        let entity_comps = deep_copy_table(lua, &bp_table)?;
        // Apply overrides (shallow merge)
        if let Some(ov) = overrides {
            for pair in ov.pairs::<LuaValue, LuaValue>() {
                let (k, v) = pair?;
                entity_comps.set(k, v)?;
            }
        }
        store.set(id, entity_comps)?;
        Ok(id)
    }

    /// Returns whether a blueprint with the given name exists.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `LuaResult<bool>`.
    pub fn has_blueprint(&self, lua: &Lua, name: &str) -> LuaResult<bool> {
        if let Some(ref key) = self.blueprint_store {
            let store: Table = lua.registry_value(key)?;
            let val: LuaValue = store.get(name)?;
            Ok(!val.is_nil())
        } else {
            Ok(false)
        }
    }

    /// Removes a blueprint definition. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn remove_blueprint(&self, lua: &Lua, name: &str) -> LuaResult<()> {
        if let Some(ref key) = self.blueprint_store {
            let store: Table = lua.registry_value(key)?;
            store.set(name, LuaValue::Nil)?;
        }
        Ok(())
    }

    /// Lists all defined blueprint names. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    ///
    /// # Returns
    /// `LuaResult<Vec<String>>`.
    pub fn list_blueprints(&self, lua: &Lua) -> LuaResult<Vec<String>> {
        let mut names = Vec::new();
        if let Some(ref key) = self.blueprint_store {
            let store: Table = lua.registry_value(key)?;
            for pair in store.pairs::<String, LuaValue>() {
                let (k, _) = pair?;
                names.push(k);
            }
        }
        Ok(names)
    }

    /// Returns a deep copy of a blueprint's component table, or Nil if not found.
    ///
    /// # Parameters
    /// - `lua` — `&'lua Lua`.
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `LuaResult<LuaValue<'lua>>`.
    pub fn get_blueprint_components<'lua>(
        &self,
        lua: &'lua Lua,
        name: &str,
    ) -> LuaResult<LuaValue<'lua>> {
        if let Some(ref key) = self.blueprint_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(bp) = store.get::<_, Table>(name) {
                return Ok(LuaValue::Table(deep_copy_table(lua, &bp)?));
            }
        }
        Ok(LuaValue::Nil)
    }

    // === Systems ===

    /// Adds a system (Lua table) to the system list.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `system` — `Table`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn add_system(&mut self, lua: &Lua, system: Table) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let store = self.get_system_store(lua)?;
        let len = store.raw_len();
        store.set(len + 1, system)?;
        Ok(())
    }

    /// Removes a system by pointer identity from the system list.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `system` — `Table`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn remove_system(&mut self, lua: &Lua, system: Table) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let store = self.get_system_store(lua)?;
        let len = store.raw_len();
        let target_ptr = system.to_pointer();
        for i in 1..=len {
            let s: Table = store.get(i)?;
            if s.to_pointer() == target_ptr {
                // Shift remaining down
                for j in i..len {
                    let next: LuaValue = store.get(j + 1)?;
                    store.set(j, next)?;
                }
                store.set(len, LuaValue::Nil)?;
                return Ok(());
            }
        }
        Err(mlua::Error::runtime("System not registered"))
    }

    /// Returns the number of registered systems.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    ///
    /// # Returns
    /// `LuaResult<usize>`.
    pub fn get_system_count(&self, lua: &Lua) -> LuaResult<usize> {
        if let Some(ref key) = self.system_store {
            let store: Table = lua.registry_value(key)?;
            Ok(store.raw_len())
        } else {
            Ok(0)
        }
    }

    // === Lifecycle ===

    /// Clears all entities, components, tags, layers, and systems. Blueprints are preserved.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn clear(&mut self, lua: &Lua) -> LuaResult<()> {
        self.alive.clear();
        self.free_list.clear();
        self.next_id = 1;
        self.string_tags.clear();
        self.bitmap_masks.clear();
        self.layers.clear();
        // Clear component store
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            let keys: Vec<u32> = store
                .clone()
                .pairs::<u32, LuaValue>()
                .filter_map(|p| p.ok().map(|(k, _)| k))
                .collect();
            for k in keys {
                store.set(k, LuaValue::Nil)?;
            }
        }
        // Clear systems
        if let Some(ref key) = self.system_store {
            let store: Table = lua.registry_value(key)?;
            let len = store.raw_len();
            for i in 1..=len {
                store.set(i, LuaValue::Nil)?;
            }
        }
        // NOTE: blueprints are preserved
        Ok(())
    }
}

impl Default for Universe {
    fn default() -> Self {
        Self::new()
    }
}

/// Deep-copies a Lua table recursively. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Parameters
/// - `lua` — `&'lua Lua`.
/// - `t` — `&Table<'lua>`.
///
/// # Returns
/// `LuaResult<Table<'lua>>`.
pub fn deep_copy_table<'lua>(lua: &'lua Lua, t: &Table<'lua>) -> LuaResult<Table<'lua>> {
    let copy = lua.create_table()?;
    for pair in t.clone().pairs::<LuaValue, LuaValue>() {
        let (k, v) = pair?;
        let v_copy = match v {
            LuaValue::Table(ref inner) => LuaValue::Table(deep_copy_table(lua, inner)?),
            other => other,
        };
        copy.set(k, v_copy)?;
    }
    Ok(copy)
}
