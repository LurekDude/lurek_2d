//! Universe — a self-contained ECS world. Entities are u32 IDs starting at 1.
//!
//! This module is part of Lurek2D's `entity` subsystem and provides the implementation
//! details for universe-related operations and data management.
//! Key types exported from this module: `Universe`.
//! Primary functions: `new()`, `get_system_store()`, `spawn()`, `kill()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use super::relationships::RelationshipManager;
use crate::log_msg;
use crate::runtime::log_messages::{EN01_UNIVERSE_INIT, EN02_ENTITY_SPAWN};
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
/// - `generations` — `HashMap<u32, u8>`: per-slot generation counter.
/// - `tag_index` — `HashMap<String, Vec<u32>>`: inverted tag → packed entity IDs.
/// - `parents` — `HashMap<u32, u32>`: child slot → parent slot.
/// - `children` — `HashMap<u32, Vec<u32>>`: parent slot → child slots.
/// - `component_store` — `Option<RegistryKey>`.
/// - `blueprint_store` — `Option<RegistryKey>`.
/// - `system_store` — `Option<RegistryKey>`.
pub struct Universe {
    next_id: u32,
    free_list: Vec<u32>,
    /// Slot-indexed set of alive entity slots (not packed IDs).
    alive: HashSet<u32>,
    /// Per-slot generation counter; slot absent means generation 0.
    generations: HashMap<u32, u8>,
    string_tags: HashMap<u32, Vec<String>>,
    /// Inverted tag → packed entity IDs index for O(1) tag queries.
    tag_index: HashMap<String, Vec<u32>>,
    bitmap_tag_names: Vec<String>,
    bitmap_masks: HashMap<u32, u64>,
    layers: HashMap<u32, i32>,
    parents: HashMap<u32, u32>,
    children: HashMap<u32, Vec<u32>>,
    component_store: Option<RegistryKey>,
    blueprint_store: Option<RegistryKey>,
    system_store: Option<RegistryKey>,
    /// Priority values parallel to the system_store table (1-based indices).
    system_priorities: Vec<i32>,
    /// Pending component-added events for observer dispatch.
    add_events: Vec<(u32, String)>,
    /// Pending component-removed events for observer dispatch.
    remove_events: Vec<(u32, String)>,
    /// Directed named relationship links between entities.
    pub relationships: RelationshipManager,
}

impl Universe {
    /// Creates a new empty Universe. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        log_msg!(debug, EN01_UNIVERSE_INIT);
        Self {
            next_id: 1,
            free_list: Vec::new(),
            alive: HashSet::new(),
            generations: HashMap::new(),
            string_tags: HashMap::new(),
            tag_index: HashMap::new(),
            bitmap_tag_names: Vec::new(),
            bitmap_masks: HashMap::new(),
            layers: HashMap::new(),
            parents: HashMap::new(),
            children: HashMap::new(),
            component_store: None,
            blueprint_store: None,
            system_store: None,
            system_priorities: Vec::new(),
            add_events: Vec::new(),
            remove_events: Vec::new(),
            relationships: RelationshipManager::new(),
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

    // === Generational ID Helpers ===

    /// Packs a slot and generation counter into a single entity ID.
    /// Upper 8 bits = generation, lower 24 bits = slot index.
    ///
    /// # Parameters
    /// - `slot` — `u32`.
    /// - `gen` — `u8`.
    ///
    /// # Returns
    /// `u32`.
    #[inline]
    pub fn pack_id(slot: u32, gen: u8) -> u32 {
        ((gen as u32) << 24) | (slot & 0x00FF_FFFF)
    }

    /// Extracts the slot index from a packed entity ID.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `u32`.
    #[inline]
    pub fn unpack_slot(id: u32) -> u32 {
        id & 0x00FF_FFFF
    }

    /// Extracts the generation counter from a packed entity ID.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    ///
    /// # Returns
    /// `u8`.
    #[inline]
    pub fn unpack_gen(id: u32) -> u8 {
        (id >> 24) as u8
    }

    /// Returns the current generation for a slot (0 if never used).
    ///
    /// # Parameters
    /// - `slot` — `u32`.
    ///
    /// # Returns
    /// `u8`.
    #[inline]
    fn current_gen(&self, slot: u32) -> u8 {
        *self.generations.get(&slot).unwrap_or(&0)
    }

    // === Entity Lifecycle ===

    /// Spawns a new entity and returns its ID. Recycles from the free list when possible.
    ///
    /// # Returns
    /// `u32`.
    pub fn spawn(&mut self) -> u32 {
        log_msg!(debug, EN02_ENTITY_SPAWN);
        let slot = if let Some(recycled) = self.free_list.pop() {
            recycled
        } else {
            let s = self.next_id;
            self.next_id += 1;
            s
        };
        self.alive.insert(slot);
        Self::pack_id(slot, self.current_gen(slot))
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
        let slot = Self::unpack_slot(id);
        let gen = Self::unpack_gen(id);
        // Reject stale handles — generation mismatch means entity already dead/recycled
        if !self.alive.contains(&slot) || self.current_gen(slot) != gen {
            return Ok(());
        }
        self.alive.remove(&slot);
        // Clean up component data (stored by slot)
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            store.set(slot, LuaValue::Nil)?;
        }
        // Clean up inverted tag index before removing string_tags
        if let Some(tags) = self.string_tags.remove(&slot) {
            for tag in &tags {
                if let Some(entries) = self.tag_index.get_mut(tag) {
                    entries.retain(|&tid| tid != id);
                }
            }
        }
        self.bitmap_masks.remove(&slot);
        self.layers.remove(&slot);
        // Detach from parent (maps use slots)
        if let Some(parent_slot) = self.parents.remove(&slot) {
            if let Some(siblings) = self.children.get_mut(&parent_slot) {
                siblings.retain(|&c| c != slot);
            }
        }
        // Orphan children (they survive, just become root entities)
        if let Some(child_slots) = self.children.remove(&slot) {
            for cs in child_slots {
                self.parents.remove(&cs);
            }
        }
        // Increment generation so old packed IDs are invalidated
        *self.generations.entry(slot).or_insert(0) += 1;
        self.free_list.push(slot);
        Ok(())
    }

    /// Sets or clears the parent of `entity`. Pass `Some(parent_id)` to attach, `None` to detach.
    ///
    /// # Parameters
    /// - `entity` — `u32`.
    /// - `parent` — `Option<u32>`.
    pub fn set_parent(&mut self, entity: u32, parent: Option<u32>) {
        let entity_slot = Self::unpack_slot(entity);
        // Remove from old parent's children list
        if let Some(old_parent_slot) = self.parents.remove(&entity_slot) {
            if let Some(siblings) = self.children.get_mut(&old_parent_slot) {
                siblings.retain(|&c| c != entity_slot);
            }
        }
        // Attach to new parent
        if let Some(new_parent) = parent {
            let parent_slot = Self::unpack_slot(new_parent);
            self.parents.insert(entity_slot, parent_slot);
            self.children
                .entry(parent_slot)
                .or_default()
                .push(entity_slot);
        }
    }

    /// Returns the parent of `entity`, or `None` if unparented.
    ///
    /// # Parameters
    /// - `entity` — `u32`.
    ///
    /// # Returns
    /// `Option<u32>`.
    pub fn get_parent(&self, entity: u32) -> Option<u32> {
        let entity_slot = Self::unpack_slot(entity);
        self.parents
            .get(&entity_slot)
            .copied()
            .map(|parent_slot| Self::pack_id(parent_slot, self.current_gen(parent_slot)))
    }

    /// Returns the direct children of `entity`. Returns an empty `Vec` if none.
    ///
    /// # Parameters
    /// - `entity` — `u32`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn get_children(&self, entity: u32) -> Vec<u32> {
        let entity_slot = Self::unpack_slot(entity);
        self.children
            .get(&entity_slot)
            .map(|slots| {
                slots
                    .iter()
                    .filter(|&&s| self.alive.contains(&s))
                    .map(|&s| Self::pack_id(s, self.current_gen(s)))
                    .collect()
            })
            .unwrap_or_default()
    }

    /// Kills `root` and all of its descendants recursively.
    ///
    /// # Parameters
    /// - `root` — `u32`.
    /// - `lua` — `&Lua`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn kill_recursive(&mut self, root: u32, lua: &Lua) -> LuaResult<()> {
        // Collect all descendants first to avoid borrow-during-mutate.
        // children are keyed by slot; re-pack them so kill() receives valid packed IDs.
        let mut to_kill: Vec<u32> = Vec::new();
        let mut stack: Vec<u32> = vec![root];
        while let Some(id) = stack.pop() {
            to_kill.push(id);
            let slot = Self::unpack_slot(id);
            if let Some(child_slots) = self.children.get(&slot) {
                for &cs in child_slots {
                    stack.push(Self::pack_id(cs, self.current_gen(cs)));
                }
            }
        }
        for id in to_kill {
            self.kill(id, lua)?;
        }
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
        let slot = Self::unpack_slot(id);
        let gen = Self::unpack_gen(id);
        self.alive.contains(&slot) && self.current_gen(slot) == gen
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
        let mut ids: Vec<u32> = self
            .alive
            .iter()
            .map(|&slot| Self::pack_id(slot, self.current_gen(slot)))
            .collect();
        ids.sort();
        ids
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
        let slot = Self::unpack_slot(id);
        let entity_table: Table = match store.get::<_, Table>(slot) {
            Ok(t) => t,
            Err(_) => {
                let t = lua.create_table()?;
                store.set(slot, t.clone())?;
                t
            }
        };
        entity_table.set(name, value.clone())?;
        self.add_events.push((id, name.to_string()));
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
        let slot = Self::unpack_slot(id);
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(entity_table) = store.get::<_, Table>(slot) {
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
        let slot = Self::unpack_slot(id);
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(entity_table) = store.get::<_, Table>(slot) {
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
    pub fn remove_component(&mut self, lua: &Lua, id: u32, name: &str) -> LuaResult<()> {
        let slot = Self::unpack_slot(id);
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(entity_table) = store.get::<_, Table>(slot) {
                let had: LuaValue = entity_table.get(name)?;
                if !had.is_nil() {
                    entity_table.set(name, LuaValue::Nil)?;
                    self.remove_events.push((id, name.to_string()));
                }
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
        let slot = Self::unpack_slot(id);
        let mut names = Vec::new();
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            if let Ok(entity_table) = store.get::<_, Table>(slot) {
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
            for &slot in &self.alive {
                if let Ok(entity_table) = store.get::<_, Table>(slot) {
                    let mut all = true;
                    for name in names {
                        let val: LuaValue = entity_table.get(name.as_str())?;
                        if val.is_nil() {
                            all = false;
                            break;
                        }
                    }
                    if all {
                        result.push(Self::pack_id(slot, self.current_gen(slot)));
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
            let mut slots: Vec<u32> = self.alive.iter().copied().collect();
            slots.sort();
            for slot in slots {
                if let Ok(entity_table) = store.get::<_, Table>(slot) {
                    let val: LuaValue = entity_table.get(name)?;
                    if !val.is_nil() {
                        callback
                            .call::<_, ()>((Self::pack_id(slot, self.current_gen(slot)), val))?;
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
        let slot = Self::unpack_slot(id);
        let tag_str = tag.to_string();
        let tags = self.string_tags.entry(slot).or_default();
        if !tags.contains(&tag_str) {
            tags.push(tag_str.clone());
            // Maintain inverted index with the current packed id
            self.tag_index.entry(tag_str).or_default().push(id);
        }
    }

    /// Removes a string tag from an entity. Returns the removed value if present, or `None` when the key did not exist.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `tag` — `&str`.
    pub fn remove_tag(&mut self, id: u32, tag: &str) {
        let slot = Self::unpack_slot(id);
        if let Some(tags) = self.string_tags.get_mut(&slot) {
            tags.retain(|t| t != tag);
        }
        // Keep inverted index consistent
        if let Some(entries) = self.tag_index.get_mut(tag) {
            entries.retain(|&tid| tid != id);
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
        let slot = Self::unpack_slot(id);
        self.string_tags
            .get(&slot)
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
        let slot = Self::unpack_slot(id);
        self.string_tags.get(&slot).cloned().unwrap_or_default()
    }

    /// Returns all alive entities that have the given string tag.
    ///
    /// # Parameters
    /// - `tag` — `&str`.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn get_entities_by_tag(&self, tag: &str) -> Vec<u32> {
        // O(1) lookup via inverted index; filter out any stale entries for safety
        let mut result = self.tag_index.get(tag).cloned().unwrap_or_default();
        result.retain(|&id| self.is_alive(id));
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
        let slot = Self::unpack_slot(id);
        let bit = self.get_or_define_tag_bit(name)?;
        let mask = self.bitmap_masks.entry(slot).or_insert(0);
        *mask |= 1u64 << bit;
        Ok(())
    }

    /// Removes a bitmap tag from an entity. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id` — `u32`.
    /// - `name` — `&str`.
    pub fn bitmap_untag(&mut self, id: u32, name: &str) {
        let slot = Self::unpack_slot(id);
        if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
            if let Some(mask) = self.bitmap_masks.get_mut(&slot) {
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
        let slot = Self::unpack_slot(id);
        if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
            if let Some(mask) = self.bitmap_masks.get(&slot) {
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
                .filter(|&&slot| {
                    self.bitmap_masks
                        .get(&slot)
                        .map(|m| m & bit != 0)
                        .unwrap_or(false)
                })
                .map(|&slot| Self::pack_id(slot, self.current_gen(slot)))
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
            .filter(|&&slot| {
                self.bitmap_masks
                    .get(&slot)
                    .map(|m| m & combined != 0)
                    .unwrap_or(false)
            })
            .map(|&slot| Self::pack_id(slot, self.current_gen(slot)))
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
            .filter(|&&slot| {
                self.bitmap_masks
                    .get(&slot)
                    .map(|m| m & combined == combined)
                    .unwrap_or(false)
            })
            .map(|&slot| Self::pack_id(slot, self.current_gen(slot)))
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
            self.layers.insert(Self::unpack_slot(id), layer);
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
        self.layers
            .get(&Self::unpack_slot(id))
            .copied()
            .unwrap_or(0)
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
            .filter(|&&slot| self.get_layer(slot) == layer)
            .map(|&slot| Self::pack_id(slot, self.current_gen(slot)))
            .collect();
        result.sort();
        result
    }

    /// Returns all alive entities sorted by layer (ascending), then by ID.
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn get_entities_sorted(&self) -> Vec<u32> {
        let mut entities: Vec<u32> = self
            .alive
            .iter()
            .map(|&slot| Self::pack_id(slot, self.current_gen(slot)))
            .collect();
        entities.sort_by(|a, b| {
            let la = self.get_layer(*a);
            let lb = self.get_layer(*b);
            la.cmp(&lb)
                .then(Self::unpack_slot(*a).cmp(&Self::unpack_slot(*b)))
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
        store.set(Self::unpack_slot(id), entity_comps)?;
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

    /// Adds a system (Lua table) to the system list at the given priority (lower = first).
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `system` — `Table`.
    /// - `priority` — `i32`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn add_system(&mut self, lua: &Lua, system: Table, priority: i32) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let store = self.get_system_store(lua)?;
        let len = store.raw_len();
        store.set(len + 1, system)?;
        self.system_priorities.push(priority);
        Ok(())
    }

    /// Returns 1-based system store indices sorted by ascending priority.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn get_sorted_system_indices(&self) -> Vec<usize> {
        let count = self.system_priorities.len();
        let mut order: Vec<usize> = (1..=count).collect();
        order.sort_by_key(|&i| self.system_priorities[i - 1]);
        order
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
                // Remove the parallel priority entry (i is 1-based, vec is 0-based)
                if i <= self.system_priorities.len() {
                    self.system_priorities.remove(i - 1);
                }
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
        self.tag_index.clear();
        self.generations.clear();
        self.bitmap_masks.clear();
        self.layers.clear();
        self.parents.clear();
        self.children.clear();
        self.system_priorities.clear();
        self.add_events.clear();
        self.remove_events.clear();
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

    // === Observer Events ===

    /// Takes and clears all pending component-add and component-remove events.
    ///
    /// # Returns
    /// `(Vec<(u32, String)>, Vec<(u32, String)>)` — (add_events, remove_events).
    #[allow(clippy::type_complexity)]
    pub fn take_component_events(&mut self) -> (Vec<(u32, String)>, Vec<(u32, String)>) {
        let adds = std::mem::take(&mut self.add_events);
        let removes = std::mem::take(&mut self.remove_events);
        (adds, removes)
    }

    // === Query Extensions ===

    /// Returns alive entities that have ALL `with` components and NONE of the `without` components.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `with_names` — `&[String]`.
    /// - `without_names` — `&[String]`.
    ///
    /// # Returns
    /// `LuaResult<Vec<u32>>`.
    pub fn query_not(
        &self,
        lua: &Lua,
        with_names: &[String],
        without_names: &[String],
    ) -> LuaResult<Vec<u32>> {
        let mut result = Vec::new();
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            for &slot in &self.alive {
                if let Ok(entity_table) = store.get::<_, Table>(slot) {
                    let mut has_all = true;
                    for name in with_names {
                        let val: LuaValue = entity_table.get(name.as_str())?;
                        if val.is_nil() {
                            has_all = false;
                            break;
                        }
                    }
                    if !has_all {
                        continue;
                    }
                    let mut has_excluded = false;
                    for name in without_names {
                        let val: LuaValue = entity_table.get(name.as_str())?;
                        if !val.is_nil() {
                            has_excluded = true;
                            break;
                        }
                    }
                    if !has_excluded {
                        result.push(Self::pack_id(slot, self.current_gen(slot)));
                    }
                } else if with_names.is_empty() {
                    // Entity with no components passes if no `with` filter
                    result.push(Self::pack_id(slot, self.current_gen(slot)));
                }
            }
        } else if with_names.is_empty() {
            // No component store initialised — return all entities if no `with` filter
            result = self.get_entities();
        }
        result.sort();
        Ok(result)
    }

    // === Bulk Spawning ===

    /// Spawns `count` entities from a blueprint, applying the same optional overrides to each.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `name` — `&str`.
    /// - `count` — `usize`.
    /// - `overrides` — `Option<Table>`.
    ///
    /// # Returns
    /// `LuaResult<Vec<u32>>`.
    pub fn spawn_bulk(
        &mut self,
        lua: &Lua,
        name: &str,
        count: usize,
        overrides: Option<Table>,
    ) -> LuaResult<Vec<u32>> {
        let mut ids = Vec::with_capacity(count);
        for _ in 0..count {
            let ov_copy = if let Some(ref ov) = overrides {
                Some(deep_copy_table(lua, ov)?)
            } else {
                None
            };
            ids.push(self.spawn_blueprint(lua, name, ov_copy)?);
        }
        Ok(ids)
    }

    // === Serialization ===

    /// Serializes all alive entities to a Lua table snapshot.
    ///
    /// Snapshot layout: `{ entities = [{id, slot, gen, components, tags, bitmap, layer, parent?}...], bitmap_tags = ["name"...] }`
    ///
    /// # Parameters
    /// - `lua` — `&'lua Lua`.
    ///
    /// # Returns
    /// `LuaResult<Table<'lua>>`.
    pub fn serialize_to_table<'lua>(&self, lua: &'lua Lua) -> LuaResult<Table<'lua>> {
        let snapshot = lua.create_table()?;

        let entities_arr = lua.create_table()?;
        let mut sorted_slots: Vec<u32> = self.alive.iter().copied().collect();
        sorted_slots.sort();

        for (i, slot) in sorted_slots.iter().enumerate() {
            let slot = *slot;
            let gen = self.current_gen(slot);
            let id = Self::pack_id(slot, gen);
            let entry = lua.create_table()?;
            entry.set("id", id)?;
            entry.set("slot", slot)?;
            entry.set("gen", gen)?;

            // Components
            let components = lua.create_table()?;
            if let Some(ref key) = self.component_store {
                let store: Table = lua.registry_value(key)?;
                if let Ok(comp_row) = store.get::<_, Table>(slot) {
                    for pair in comp_row.clone().pairs::<String, LuaValue>() {
                        let (k, v) = pair?;
                        let v_copy = match v {
                            LuaValue::Table(ref t) => LuaValue::Table(deep_copy_table(lua, t)?),
                            other => other,
                        };
                        components.set(k, v_copy)?;
                    }
                }
            }
            entry.set("components", components)?;

            // String tags
            let tags = lua.create_table()?;
            if let Some(tag_list) = self.string_tags.get(&slot) {
                for (j, t) in tag_list.iter().enumerate() {
                    tags.set(j + 1, t.as_str())?;
                }
            }
            entry.set("tags", tags)?;

            // Layer
            entry.set("layer", self.layers.get(&slot).copied().unwrap_or(0))?;

            // Bitmap mask
            entry.set(
                "bitmap",
                self.bitmap_masks.get(&slot).copied().unwrap_or(0u64) as i64,
            )?;

            // Parent (pack as valid ID)
            if let Some(&parent_slot) = self.parents.get(&slot) {
                if self.alive.contains(&parent_slot) {
                    entry.set(
                        "parent",
                        Self::pack_id(parent_slot, self.current_gen(parent_slot)),
                    )?;
                }
            }

            entities_arr.set(i + 1, entry)?;
        }
        snapshot.set("entities", entities_arr)?;

        // Bitmap tag names
        let btnames = lua.create_table()?;
        for (j, name) in self.bitmap_tag_names.iter().enumerate() {
            btnames.set(j + 1, name.as_str())?;
        }
        snapshot.set("bitmap_tags", btnames)?;

        Ok(snapshot)
    }

    /// Restores entity state from a snapshot produced by `serialize_to_table`.
    ///
    /// Clears all entities; blueprints and systems are preserved.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `snapshot` — `Table`.
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn deserialize_from_table(&mut self, lua: &Lua, snapshot: Table) -> LuaResult<()> {
        // Clear entities only; preserve blueprints + systems
        self.alive.clear();
        self.free_list.clear();
        self.next_id = 1;
        self.string_tags.clear();
        self.tag_index.clear();
        self.generations.clear();
        self.bitmap_masks.clear();
        self.layers.clear();
        self.parents.clear();
        self.children.clear();
        self.add_events.clear();
        self.remove_events.clear();
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            let ks: Vec<u32> = store
                .clone()
                .pairs::<u32, LuaValue>()
                .filter_map(|p| p.ok().map(|(k, _)| k))
                .collect();
            for k in ks {
                store.set(k, LuaValue::Nil)?;
            }
        }
        self.ensure_stores(lua)?;
        let comp_store = self.get_component_store(lua)?;

        // Restore bitmap tag names
        if let Ok(btnames) = snapshot.get::<_, Table>("bitmap_tags") {
            for name in btnames.clone().sequence_values::<String>() {
                let name = name?;
                if !self.bitmap_tag_names.contains(&name) {
                    self.bitmap_tag_names.push(name);
                }
            }
        }

        // First pass: restore entities
        let entities: Table = snapshot.get("entities")?;
        let mut parent_data: Vec<(u32, u32)> = Vec::new(); // (child_slot, parent_id)
        for entry_val in entities.clone().sequence_values::<Table>() {
            let entry = entry_val?;
            let id: u32 = entry.get("id")?;
            let slot = Self::unpack_slot(id);
            let gen: u8 = entry.get("gen").unwrap_or(0);

            self.alive.insert(slot);
            *self.generations.entry(slot).or_insert(0) = gen;
            if slot >= self.next_id {
                self.next_id = slot + 1;
            }

            // Components
            let comp_row = lua.create_table()?;
            if let Ok(components) = entry.get::<_, Table>("components") {
                for pair in components.clone().pairs::<LuaValue, LuaValue>() {
                    let (k, v) = pair?;
                    comp_row.set(k, v)?;
                }
            }
            comp_store.set(slot, comp_row)?;

            // String tags
            if let Ok(tags) = entry.get::<_, Table>("tags") {
                let mut tag_list = Vec::new();
                for t in tags.sequence_values::<String>() {
                    let t = t?;
                    self.tag_index.entry(t.clone()).or_default().push(id);
                    tag_list.push(t);
                }
                if !tag_list.is_empty() {
                    self.string_tags.insert(slot, tag_list);
                }
            }

            // Layer
            let layer: i32 = entry.get("layer").unwrap_or(0);
            if layer != 0 {
                self.layers.insert(slot, layer);
            }

            // Bitmap mask
            let bitmap: i64 = entry.get("bitmap").unwrap_or(0);
            if bitmap != 0 {
                self.bitmap_masks.insert(slot, bitmap as u64);
            }

            // Queue parent for second pass
            if let Ok(parent_id) = entry.get::<_, u32>("parent") {
                parent_data.push((slot, parent_id));
            }
        }

        // Second pass: restore hierarchy
        for (child_slot, parent_id) in parent_data {
            let parent_slot = Self::unpack_slot(parent_id);
            if self.alive.contains(&parent_slot) {
                self.parents.insert(child_slot, parent_slot);
                self.children
                    .entry(parent_slot)
                    .or_default()
                    .push(child_slot);
            }
        }

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
