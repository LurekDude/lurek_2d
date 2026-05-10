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
use crate::ecs::generational_id::GenerationalId;
use crate::ecs::lua_table::deep_copy_table;
use crate::log_msg;
use crate::runtime::log_messages::{EN01_UNIVERSE_INIT, EN02_ENTITY_SPAWN};
use mlua::{Function, Lua, RegistryKey, Result as LuaResult, Table, Value as LuaValue};
use std::collections::{HashMap, HashSet};

#[path = "universe_ext.rs"]
mod ext;

/// Maximum number of bitmap tag definitions per Universe.
const MAX_BITMAP_TAGS: usize = 63;

/// A self-contained ECS world. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Manages entities (u32 IDs with recycling), components (stored in Lua registry tables),
/// string and bitmap tags, layers, blueprints, systems, and system phases.
///
/// # System phases
/// Systems can be assigned a named phase when added (`addSystem` `opts.phase`).
/// Built-in phase order: `"pre_update"` → `"update"` → `"post_update"`.
/// Call `world:update(dt)` to run the `"update"` phase.
/// Call `world:updatePhase(phase, dt)` to run any specific phase.
/// Unknown custom phases run after the built-in three if dispatched directly.
///
/// # Fields
/// - `next_id` — `u32`.
/// - `free_list` — `Vec<u32>`.
/// - `alive` — `HashSet<u32>`.
/// - `string_tags` — `HashMap<u32, Vec<String>>`.
/// - `bitmap_tag_names` — `Vec<String>`.
/// - `bitmap_masks` — `HashMap<u32, u64>`.
/// - `layers` — `HashMap<u32, i32>`.
/// - `generations` — `HashMap<u32, u8>`: per-slot generation counter.
/// - `tag_index` — `HashMap<String, Vec<u32>>`: inverted tag → packed entity IDs.
/// - `parents` — `HashMap<u32, u32>`: child slot → parent slot.
/// - `children` — `HashMap<u32, Vec<u32>>`: parent slot → child slots.
/// - `component_store` — `Option<RegistryKey>`.
/// - `blueprint_store` — `Option<RegistryKey>`.
/// - `system_store` — `Option<RegistryKey>`.
/// - `dirty_set` — `HashSet<u32>`: packed IDs of entities whose components changed since the last `flushObservers`.
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
    /// Optional sparse-set index: component name -> entity slots containing that component.
    #[cfg(feature = "ecs-archetype")]
    component_index: HashMap<String, HashSet<u32>>,
    blueprint_store: Option<RegistryKey>,
    system_store: Option<RegistryKey>,
    /// Priority values parallel to the system_store table (1-based indices).
    system_priorities: Vec<i32>,
    /// Phase name parallel to the system_store table.  Empty string means `"update"`.
    system_phases: Vec<String>,
    /// Pending component-added events for observer dispatch.
    add_events: Vec<(u32, String)>,
    /// Pending component-removed events for observer dispatch.
    remove_events: Vec<(u32, String)>,
    /// Packed entity IDs whose components changed since the last `take_component_events` call.
    dirty_set: HashSet<u32>,
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
            #[cfg(feature = "ecs-archetype")]
            component_index: HashMap::new(),
            blueprint_store: None,
            system_store: None,
            system_priorities: Vec::new(),
            system_phases: Vec::new(),
            add_events: Vec::new(),
            remove_events: Vec::new(),
            dirty_set: HashSet::new(),
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
        GenerationalId::pack(slot, gen)
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
        GenerationalId::unpack_slot(id)
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
        GenerationalId::unpack_gen(id)
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

    /// Rebuild the sparse index entries for one component row.
    #[cfg(feature = "ecs-archetype")]
    fn reindex_component_row(&mut self, slot: u32, row: &Table) -> LuaResult<()> {
        for pair in row.clone().pairs::<String, LuaValue>() {
            let (name, value) = pair?;
            if !value.is_nil() {
                self.component_index.entry(name).or_default().insert(slot);
            }
        }
        Ok(())
    }

    /// Returns candidate slots that have all requested component names.
    ///
    /// With `ecs-archetype` enabled this intersects sparse indexes first;
    /// otherwise it falls back to scanning all alive slots.
    fn candidate_slots_for_all(&self, names: &[String]) -> Vec<u32> {
        if names.is_empty() {
            return self.alive.iter().copied().collect();
        }

        #[cfg(feature = "ecs-archetype")]
        {
            let mut base: Option<HashSet<u32>> = None;
            for name in names {
                let Some(slots) = self.component_index.get(name) else {
                    return Vec::new();
                };
                if let Some(ref mut set) = base {
                    set.retain(|slot| slots.contains(slot));
                    if set.is_empty() {
                        return Vec::new();
                    }
                } else {
                    base = Some(slots.clone());
                }
            }
            return base
                .unwrap_or_default()
                .into_iter()
                .filter(|slot| self.alive.contains(slot))
                .collect();
        }

        #[cfg(not(feature = "ecs-archetype"))]
        {
            self.alive.iter().copied().collect()
        }
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
        #[cfg(feature = "ecs-archetype")]
        {
            for slots in self.component_index.values_mut() {
                slots.remove(&slot);
            }
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
        #[cfg(feature = "ecs-archetype")]
        self.component_index
            .entry(name.to_string())
            .or_default()
            .insert(slot);
        self.add_events.push((id, name.to_string()));
        self.dirty_set.insert(id);
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
                    #[cfg(feature = "ecs-archetype")]
                    if let Some(slots) = self.component_index.get_mut(name) {
                        slots.remove(&slot);
                    }
                    self.remove_events.push((id, name.to_string()));
                    self.dirty_set.insert(id);
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
            for slot in self.candidate_slots_for_all(names) {
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
        // O(1) lookup via inverted index; avoid cloning the full backing vec first.
        let mut result: Vec<u32> = self
            .iter_entities_by_tag(tag)
            .filter(|&id| self.is_alive(id))
            .collect();
        result.sort();
        result
    }

    /// Iterates entity IDs for a string tag from the internal inverted index.
    ///
    /// Returned IDs may include stale handles if callers bypass cleanup; use `is_alive` when needed.
    pub fn iter_entities_by_tag<'a>(&'a self, tag: &'a str) -> impl Iterator<Item = u32> + 'a {
        self.tag_index
            .get(tag)
            .into_iter()
            .flat_map(|entries| entries.iter().copied())
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
        let slot = Self::unpack_slot(id);
        #[cfg(feature = "ecs-archetype")]
        self.reindex_component_row(slot, &entity_comps)?;
        store.set(slot, entity_comps)?;
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
    /// The optional `phase` string assigns the system to a named execution phase.
    /// An empty string is treated as `"update"`.
    ///
    /// # Parameters
    /// - `lua` — `&Lua`.
    /// - `system` — `Table`.
    /// - `priority` — `i32`.
    /// - `phase` — `String`: phase name (`""` means `"update"`).
    ///
    /// # Returns
    /// `LuaResult<()>`.
    pub fn add_system(
        &mut self,
        lua: &Lua,
        system: Table,
        priority: i32,
        phase: String,
    ) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let store = self.get_system_store(lua)?;
        let len = store.raw_len();
        store.set(len + 1, system)?;
        self.system_priorities.push(priority);
        self.system_phases.push(phase);
        Ok(())
    }

    /// Returns all 1-based system store indices sorted by ascending priority across all phases.
    /// Used by `emit` which broadcasts to every registered system regardless of phase.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn get_sorted_system_indices_all(&self) -> Vec<usize> {
        let count = self.system_priorities.len();
        let mut order: Vec<usize> = (1..=count).collect();
        order.sort_by_key(|&i| self.system_priorities[i - 1]);
        order
    }

    /// Returns 1-based system store indices sorted by ascending priority, filtered to the given phase.
    ///
    /// Backward-compatibility rule:
    /// Systems registered with no explicit phase (empty phase string) are treated as
    /// default systems and run in both `"update"` and `"render"` dispatches.
    ///
    /// # Parameters
    /// - `phase` — `&str`: empty string matches `"update"`.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn get_sorted_system_indices_for_phase(&self, phase: &str) -> Vec<usize> {
        let target = if phase.is_empty() { "update" } else { phase };
        let count = self.system_priorities.len();
        let mut order: Vec<usize> = (1..=count)
            .filter(|&i| {
                let p = &self.system_phases[i - 1];
                if p.is_empty() {
                    // Legacy behavior: systems without an explicit phase are active in
                    // both update() and render().
                    target == "update" || target == "render"
                } else {
                    p == target
                }
            })
            .collect();
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
                // Remove the parallel priority + phase entries (i is 1-based, vec is 0-based)
                if i <= self.system_priorities.len() {
                    self.system_priorities.remove(i - 1);
                }
                if i <= self.system_phases.len() {
                    self.system_phases.remove(i - 1);
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
        self.system_phases.clear();
        self.add_events.clear();
        self.remove_events.clear();
        self.dirty_set.clear();
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
        #[cfg(feature = "ecs-archetype")]
        self.component_index.clear();
        // NOTE: blueprints are preserved
        Ok(())
    }

    // === Observer Events ===

    /// Takes and clears all pending component-add and component-remove events.
    /// Also drains the dirty-entity set so callers receive the full change batch.
    ///
    /// # Returns
    /// `(Vec<(u32, String)>, Vec<(u32, String)>)` — (add_events, remove_events).
    #[allow(clippy::type_complexity)]
    pub fn take_component_events(&mut self) -> (Vec<(u32, String)>, Vec<(u32, String)>) {
        let adds = std::mem::take(&mut self.add_events);
        let removes = std::mem::take(&mut self.remove_events);
        self.dirty_set.clear();
        (adds, removes)
    }

    /// Returns all entity IDs whose components changed since the last `take_component_events` call.
    ///
    /// Entities are returned sorted. The set is cleared by `take_component_events` (or `flushObservers`).
    ///
    /// # Returns
    /// `Vec<u32>`.
    pub fn get_dirty_entities(&self) -> Vec<u32> {
        let mut ids: Vec<u32> = self.dirty_set.iter().copied().collect();
        ids.sort();
        ids
    }
}

impl Default for Universe {
    fn default() -> Self {
        Self::new()
    }
}
