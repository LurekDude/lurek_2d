
use super::relationships::RelationshipManager;
use crate::ecs::generational_id::GenerationalId;
use crate::ecs::lua_table::deep_copy_table;
use crate::log_msg;
use crate::runtime::log_messages::{EN01_UNIVERSE_INIT, EN02_ENTITY_SPAWN};
use mlua::{Function, Lua, RegistryKey, Result as LuaResult, Table, Value as LuaValue};
use std::collections::{HashMap, HashSet};
#[path = "universe_ext.rs"]
mod ext;
#[path = "universe_systems.rs"]
mod systems;
const MAX_BITMAP_TAGS: usize = 63;
#[derive(Debug, Default, Clone)]
/// Captures component and entity changes accumulated since the previous diff read.
pub struct SnapshotDiff {
    /// Component additions recorded as `(entity_id, component_name)` pairs.
    pub added_components: Vec<(u32, String)>,
    /// Component removals recorded as `(entity_id, component_name)` pairs.
    pub removed_components: Vec<(u32, String)>,
    /// Packed entity ids deleted since the previous diff read.
    pub deleted_entities: Vec<u32>,
    /// Packed entity ids whose component sets changed since the previous diff read.
    pub dirty_entities: Vec<u32>,
}
/// Owns all ECS entity state, component rows, tags, systems, and relationship data.
pub struct Universe {
    /// Next fresh slot id used when no recycled slots are available.
    next_id: u32,
    /// Recycled slot ids available for reuse.
    free_list: Vec<u32>,
    /// Live entity slots currently allocated in the universe.
    alive: HashSet<u32>,
    /// Generation counters keyed by entity slot.
    generations: HashMap<u32, u8>,
    /// Per-entity string tags keyed by slot.
    string_tags: HashMap<u32, Vec<String>>,
    /// Reverse index from tag name to packed entity ids.
    tag_index: HashMap<String, Vec<u32>>,
    /// Registered bitmap tag names ordered by bit position.
    bitmap_tag_names: Vec<String>,
    /// Per-entity bitmap tag masks keyed by slot.
    bitmap_masks: HashMap<u32, u64>,
    /// Per-entity layer values keyed by slot.
    layers: HashMap<u32, i32>,
    /// Parent slot for each child slot in the entity hierarchy.
    parents: HashMap<u32, u32>,
    /// Child slots grouped by parent slot.
    children: HashMap<u32, Vec<u32>>,
    /// Lua registry table containing per-entity component rows.
    component_store: Option<RegistryKey>,
    #[cfg(feature = "ecs-archetype")]
    /// Component-name index used to accelerate archetype-style queries.
    component_index: HashMap<String, HashSet<u32>>,
    /// Lua registry table containing blueprint component templates.
    blueprint_store: Option<RegistryKey>,
    /// Lua registry table containing registered system tables.
    system_store: Option<RegistryKey>,
    /// Sort priority per registered system.
    system_priorities: Vec<i32>,
    /// Execution phase name per registered system.
    system_phases: Vec<String>,
    /// Stable name per registered system.
    system_names: Vec<String>,
    /// Dependency name list per registered system.
    system_deps: Vec<Vec<String>>,
    /// Buffered component-add notifications.
    add_events: Vec<(u32, String)>,
    /// Buffered component-remove notifications.
    remove_events: Vec<(u32, String)>,
    /// Entities whose component rows changed since the last event drain.
    dirty_set: HashSet<u32>,
    /// Buffered entity deletions since the last diff drain.
    deleted_entities: Vec<u32>,
    /// Relationship graph and directed link state associated with this universe.
    pub relationships: RelationshipManager,
}
impl Universe {
    /// Creates an empty universe with fresh stores and counters.
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
            system_names: Vec::new(),
            system_deps: Vec::new(),
            add_events: Vec::new(),
            remove_events: Vec::new(),
            dirty_set: HashSet::new(),
            deleted_entities: Vec::new(),
            relationships: RelationshipManager::new(),
        }
    }
    /// Lazily allocates the Lua registry tables backing components, blueprints, and systems.
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
    /// Fetches the Lua component store table, failing if the universe is not initialized.
    fn get_component_store<'lua>(&self, lua: &'lua Lua) -> LuaResult<Table<'lua>> {
        let key = self
            .component_store
            .as_ref()
            .ok_or_else(|| mlua::Error::runtime("Universe not initialized"))?;
        lua.registry_value::<Table>(key)
    }
    /// Fetches the Lua blueprint store table, failing if the universe is not initialized.
    fn get_blueprint_store<'lua>(&self, lua: &'lua Lua) -> LuaResult<Table<'lua>> {
        let key = self
            .blueprint_store
            .as_ref()
            .ok_or_else(|| mlua::Error::runtime("Universe not initialized"))?;
        lua.registry_value::<Table>(key)
    }
    /// Fetches the Lua system store table, failing if the universe is not initialized.
    pub fn get_system_store<'lua>(&self, lua: &'lua Lua) -> LuaResult<Table<'lua>> {
        let key = self
            .system_store
            .as_ref()
            .ok_or_else(|| mlua::Error::runtime("Universe not initialized"))?;
        lua.registry_value::<Table>(key)
    }
    #[inline]
    /// Packs a slot and generation into the public entity id format.
    pub fn pack_id(slot: u32, gen: u8) -> u32 {
        GenerationalId::pack(slot, gen)
    }
    #[inline]
    /// Extracts the slot portion from a packed entity id.
    pub fn unpack_slot(id: u32) -> u32 {
        GenerationalId::unpack_slot(id)
    }
    #[inline]
    /// Extracts the generation portion from a packed entity id.
    pub fn unpack_gen(id: u32) -> u8 {
        GenerationalId::unpack_gen(id)
    }
    #[inline]
    /// Returns the current generation counter for a slot.
    fn current_gen(&self, slot: u32) -> u8 {
        *self.generations.get(&slot).unwrap_or(&0)
    }
    #[cfg(feature = "ecs-archetype")]
    /// Rebuilds archetype query indices from one entity component row.
    fn reindex_component_row(&mut self, slot: u32, row: &Table) -> LuaResult<()> {
        for pair in row.clone().pairs::<String, LuaValue>() {
            let (name, value) = pair?;
            if !value.is_nil() {
                self.component_index.entry(name).or_default().insert(slot);
            }
        }
        Ok(())
    }
    /// Produces candidate slots that may contain all requested component names.
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
    /// Allocates a live entity id, reusing a recycled slot when available.
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
    /// Deletes one entity, clears its stored state, and recycles its slot.
    pub fn kill(&mut self, id: u32, lua: &Lua) -> LuaResult<()> {
        let slot = Self::unpack_slot(id);
        let gen = Self::unpack_gen(id);
        if !self.alive.contains(&slot) || self.current_gen(slot) != gen {
            return Ok(());
        }
        self.alive.remove(&slot);
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
        if let Some(tags) = self.string_tags.remove(&slot) {
            for tag in &tags {
                if let Some(entries) = self.tag_index.get_mut(tag) {
                    if let Some(pos) = entries.iter().position(|&tid| tid == id) {
                        entries.swap_remove(pos);
                    }
                }
            }
        }
        self.bitmap_masks.remove(&slot);
        self.layers.remove(&slot);
        if let Some(parent_slot) = self.parents.remove(&slot) {
            if let Some(siblings) = self.children.get_mut(&parent_slot) {
                siblings.retain(|&c| c != slot);
            }
        }
        if let Some(child_slots) = self.children.remove(&slot) {
            for cs in child_slots {
                self.parents.remove(&cs);
            }
        }
        *self.generations.entry(slot).or_insert(0) += 1;
        self.free_list.push(slot);
        self.deleted_entities.push(id);
        Ok(())
    }
    /// Reassigns the parent of an entity within the hierarchy graph.
    pub fn set_parent(&mut self, entity: u32, parent: Option<u32>) {
        let entity_slot = Self::unpack_slot(entity);
        if let Some(old_parent_slot) = self.parents.remove(&entity_slot) {
            if let Some(siblings) = self.children.get_mut(&old_parent_slot) {
                siblings.retain(|&c| c != entity_slot);
            }
        }
        if let Some(new_parent) = parent {
            let parent_slot = Self::unpack_slot(new_parent);
            self.parents.insert(entity_slot, parent_slot);
            self.children
                .entry(parent_slot)
                .or_default()
                .push(entity_slot);
        }
    }
    /// Returns the packed parent id for an entity when one is assigned.
    pub fn get_parent(&self, entity: u32) -> Option<u32> {
        let entity_slot = Self::unpack_slot(entity);
        self.parents
            .get(&entity_slot)
            .copied()
            .map(|parent_slot| Self::pack_id(parent_slot, self.current_gen(parent_slot)))
    }
    /// Returns the live packed child ids for an entity.
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
    /// Deletes an entity and every descendant reachable through the hierarchy.
    pub fn kill_recursive(&mut self, root: u32, lua: &Lua) -> LuaResult<()> {
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
    /// Returns whether a packed entity id still refers to a live slot and generation.
    pub fn is_alive(&self, id: u32) -> bool {
        let slot = Self::unpack_slot(id);
        let gen = Self::unpack_gen(id);
        self.alive.contains(&slot) && self.current_gen(slot) == gen
    }
    /// Returns the number of live entities.
    pub fn get_entity_count(&self) -> usize {
        self.alive.len()
    }
    /// Returns all live entity ids in ascending order.
    pub fn get_entities(&self) -> Vec<u32> {
        let mut ids: Vec<u32> = self
            .alive
            .iter()
            .map(|&slot| Self::pack_id(slot, self.current_gen(slot)))
            .collect();
        ids.sort();
        ids
    }
    /// Writes one component value into an entity row and records the change.
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
    /// Reads one component value from an entity row, yielding `nil` when absent.
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
    /// Returns whether an entity row contains a non-`nil` value for the component name.
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
    /// Removes one component from an entity row and records the change when present.
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
    /// Lists the component names currently stored on an entity row.
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
    /// Returns entity ids whose rows contain every requested component name.
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
    /// Calls a Lua callback for each live entity that owns the named component.
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
    /// Attaches a string tag to a live entity and updates the reverse index.
    pub fn add_tag(&mut self, id: u32, tag: &str) {
        if !self.is_alive(id) {
            return;
        }
        let slot = Self::unpack_slot(id);
        let tag_str = tag.to_string();
        let tags = self.string_tags.entry(slot).or_default();
        if !tags.contains(&tag_str) {
            tags.push(tag_str.clone());
            self.tag_index.entry(tag_str).or_default().push(id);
        }
    }
    /// Removes a string tag from an entity and the reverse tag index.
    pub fn remove_tag(&mut self, id: u32, tag: &str) {
        let slot = Self::unpack_slot(id);
        if let Some(tags) = self.string_tags.get_mut(&slot) {
            tags.retain(|t| t != tag);
        }
        if let Some(entries) = self.tag_index.get_mut(tag) {
            entries.retain(|&tid| tid != id);
        }
    }
    /// Returns whether an entity currently owns the given string tag.
    pub fn has_tag(&self, id: u32, tag: &str) -> bool {
        let slot = Self::unpack_slot(id);
        self.string_tags
            .get(&slot)
            .map(|tags| tags.iter().any(|t| t == tag))
            .unwrap_or(false)
    }
    /// Returns all string tags currently attached to an entity.
    pub fn get_tags(&self, id: u32) -> Vec<String> {
        let slot = Self::unpack_slot(id);
        self.string_tags.get(&slot).cloned().unwrap_or_default()
    }
    /// Returns all live entities currently indexed under the given string tag.
    pub fn get_entities_by_tag(&self, tag: &str) -> Vec<u32> {
        let mut result: Vec<u32> = self
            .iter_entities_by_tag(tag)
            .filter(|&id| self.is_alive(id))
            .collect();
        result.sort();
        result
    }
    /// Iterates over entity ids indexed under the given string tag.
    pub fn iter_entities_by_tag<'a>(&'a self, tag: &'a str) -> impl Iterator<Item = u32> + 'a {
        self.tag_index
            .get(tag)
            .into_iter()
            .flat_map(|entries| entries.iter().copied())
    }
    /// Resolves or allocates the bitmap bit position for a tag name.
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
    /// Reserves and returns the bitmap bit position for a tag name.
    pub fn define_tag(&mut self, name: &str) -> LuaResult<u8> {
        self.get_or_define_tag_bit(name)
    }
    /// Sets one bitmap tag bit on a live entity.
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
    /// Clears one bitmap tag bit on an entity when the tag exists.
    pub fn bitmap_untag(&mut self, id: u32, name: &str) {
        let slot = Self::unpack_slot(id);
        if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
            if let Some(mask) = self.bitmap_masks.get_mut(&slot) {
                *mask &= !(1u64 << pos);
            }
        }
    }
    /// Returns whether an entity currently has the named bitmap tag bit set.
    pub fn has_bitmap_tag(&self, id: u32, name: &str) -> bool {
        let slot = Self::unpack_slot(id);
        if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
            if let Some(mask) = self.bitmap_masks.get(&slot) {
                return (*mask & (1u64 << pos)) != 0;
            }
        }
        false
    }
    /// Returns live entities whose bitmap mask includes the named tag bit.
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
    /// Returns live entities whose bitmap mask contains any requested tag bit.
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
    /// Returns live entities whose bitmap mask contains every requested tag bit.
    pub fn query_bitmap_all(&self, names: &[String]) -> Vec<u32> {
        let mut combined = 0u64;
        for name in names {
            if let Some(pos) = self.bitmap_tag_names.iter().position(|n| n == name) {
                combined |= 1u64 << pos;
            } else {
                return Vec::new();
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
    /// Returns the bit position assigned to a bitmap tag name.
    pub fn get_bitmap_tag_bit(&self, name: &str) -> Option<u8> {
        self.bitmap_tag_names
            .iter()
            .position(|n| n == name)
            .map(|p| p as u8)
    }
    /// Writes the layer value for a live entity.
    pub fn set_layer(&mut self, id: u32, layer: i32) {
        if self.is_alive(id) {
            self.layers.insert(Self::unpack_slot(id), layer);
        }
    }
    /// Returns the stored layer value for an entity, defaulting to zero.
    pub fn get_layer(&self, id: u32) -> i32 {
        self.layers
            .get(&Self::unpack_slot(id))
            .copied()
            .unwrap_or(0)
    }
    /// Returns live entities whose stored layer equals the requested value.
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
    /// Returns live entities sorted by layer and then by slot id.
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
    /// Stores a blueprint template under a name after deep-copying its Lua table.
    pub fn define_blueprint(&mut self, lua: &Lua, name: &str, components: Table) -> LuaResult<()> {
        self.ensure_stores(lua)?;
        let bp_store = self.get_blueprint_store(lua)?;
        let copy = deep_copy_table(lua, &components)?;
        bp_store.set(name, copy)?;
        Ok(())
    }
    /// Builds a child blueprint by copying a parent template and applying overrides.
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
        let merged = deep_copy_table(lua, &parent_table)?;
        for pair in overrides.pairs::<LuaValue, LuaValue>() {
            let (k, v) = pair?;
            merged.set(k, v)?;
        }
        bp_store.set(name, merged)?;
        Ok(())
    }
    /// Spawns an entity from a named blueprint and optional override table.
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
    /// Returns whether a blueprint name is present in the blueprint store.
    pub fn has_blueprint(&self, lua: &Lua, name: &str) -> LuaResult<bool> {
        if let Some(ref key) = self.blueprint_store {
            let store: Table = lua.registry_value(key)?;
            let val: LuaValue = store.get(name)?;
            Ok(!val.is_nil())
        } else {
            Ok(false)
        }
    }
    /// Removes one named blueprint from the blueprint store.
    pub fn remove_blueprint(&self, lua: &Lua, name: &str) -> LuaResult<()> {
        if let Some(ref key) = self.blueprint_store {
            let store: Table = lua.registry_value(key)?;
            store.set(name, LuaValue::Nil)?;
        }
        Ok(())
    }
    /// Returns the names of all stored blueprints.
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
    /// Returns a deep-copied Lua table containing one blueprint's component template.
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
    /// Resets the universe to an empty state and clears its Lua-backed stores.
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
        self.system_names.clear();
        self.system_deps.clear();
        self.add_events.clear();
        self.remove_events.clear();
        self.dirty_set.clear();
        self.deleted_entities.clear();
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
        if let Some(ref key) = self.system_store {
            let store: Table = lua.registry_value(key)?;
            let len = store.raw_len();
            for i in 1..=len {
                store.set(i, LuaValue::Nil)?;
            }
        }
        #[cfg(feature = "ecs-archetype")]
        self.component_index.clear();
        Ok(())
    }
    #[allow(clippy::type_complexity)]
    /// Drains buffered component add and remove notifications.
    pub fn take_component_events(&mut self) -> (Vec<(u32, String)>, Vec<(u32, String)>) {
        let adds = std::mem::take(&mut self.add_events);
        let removes = std::mem::take(&mut self.remove_events);
        self.dirty_set.clear();
        (adds, removes)
    }
    /// Returns the sorted set of entities marked dirty by component changes.
    pub fn get_dirty_entities(&self) -> Vec<u32> {
        let mut ids: Vec<u32> = self.dirty_set.iter().copied().collect();
        ids.sort();
        ids
    }
    /// Drains buffered component and entity changes into a snapshot diff.
    pub fn take_snapshot_diff(&mut self) -> SnapshotDiff {
        let dirty_entities = self.get_dirty_entities();
        let (added_components, removed_components) = self.take_component_events();
        let deleted_entities = std::mem::take(&mut self.deleted_entities);
        SnapshotDiff {
            added_components,
            removed_components,
            deleted_entities,
            dirty_entities,
        }
    }
}
impl Default for Universe {
    /// Creates an empty universe with default storage state.
    fn default() -> Self {
        Self::new()
    }
}
