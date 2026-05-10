use super::Universe;
use crate::ecs::lua_table::deep_copy_table;
use mlua::{Function, Lua, Result as LuaResult, Table, Value as LuaValue};

impl Universe {
    /// Returns alive entities that have ALL `with` components and NONE of the `without` components.
    pub fn query_not(
        &self,
        lua: &Lua,
        with_names: &[String],
        without_names: &[String],
    ) -> LuaResult<Vec<u32>> {
        let mut result = Vec::new();
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            for slot in self.candidate_slots_for_all(with_names) {
                if let Ok(entity_table) = store.get::<_, Table>(slot) {
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
                    // Entity with no components passes if no `with` filter.
                    result.push(Self::pack_id(slot, self.current_gen(slot)));
                }
            }
        } else if with_names.is_empty() {
            result = self.get_entities();
        }
        result.sort();
        Ok(result)
    }

    /// Calls `callback(id, comp1, comp2, …)` for every alive entity that has ALL listed components.
    pub fn query_multi(&self, lua: &Lua, names: &[String], callback: Function) -> LuaResult<()> {
        if names.is_empty() {
            return Ok(());
        }
        if let Some(ref key) = self.component_store {
            let store: Table = lua.registry_value(key)?;
            let mut slots = self.candidate_slots_for_all(names);
            slots.sort();
            for slot in slots {
                if let Ok(entity_table) = store.get::<_, Table>(slot) {
                    let mut vals: Vec<LuaValue> = Vec::with_capacity(names.len());
                    let mut all = true;
                    for name in names {
                        let v: LuaValue = entity_table.get(name.as_str())?;
                        if v.is_nil() {
                            all = false;
                            break;
                        }
                        vals.push(v);
                    }
                    if all {
                        let id = Self::pack_id(slot, self.current_gen(slot));
                        let mut args = Vec::with_capacity(1 + vals.len());
                        args.push(LuaValue::Integer(id as i64));
                        args.extend(vals);
                        callback.call::<_, ()>(mlua::MultiValue::from_vec(args))?;
                    }
                }
            }
        }
        Ok(())
    }

    /// Spawns `count` entities from a blueprint, applying the same optional overrides to each.
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

    /// Serializes all alive entities to a Lua table snapshot.
    pub fn serialize_to_table<'lua>(&self, lua: &'lua Lua) -> LuaResult<Table<'lua>> {
        let snapshot = lua.create_table()?;

        let entities_arr = lua.create_table()?;
        let mut sorted_slots: Vec<u32> = self.alive.iter().copied().collect();
        sorted_slots.sort();

        for (i, slot) in sorted_slots.iter().enumerate() {
            let slot = *slot;
            let generation = self.current_gen(slot);
            let id = Self::pack_id(slot, generation);
            let entry = lua.create_table()?;
            entry.set("id", id)?;
            entry.set("slot", slot)?;
            entry.set("gen", generation)?;

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

            let tags = lua.create_table()?;
            if let Some(tag_list) = self.string_tags.get(&slot) {
                for (j, t) in tag_list.iter().enumerate() {
                    tags.set(j + 1, t.as_str())?;
                }
            }
            entry.set("tags", tags)?;

            entry.set("layer", self.layers.get(&slot).copied().unwrap_or(0))?;

            entry.set(
                "bitmap",
                self.bitmap_masks.get(&slot).copied().unwrap_or(0u64) as i64,
            )?;

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

        let btnames = lua.create_table()?;
        for (j, name) in self.bitmap_tag_names.iter().enumerate() {
            btnames.set(j + 1, name.as_str())?;
        }
        snapshot.set("bitmap_tags", btnames)?;

        Ok(snapshot)
    }

    /// Restores entity state from a snapshot produced by `serialize_to_table`.
    pub fn deserialize_from_table(&mut self, lua: &Lua, snapshot: Table) -> LuaResult<()> {
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
        self.dirty_set.clear();
        #[cfg(feature = "ecs-archetype")]
        self.component_index.clear();
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

        if let Ok(btnames) = snapshot.get::<_, Table>("bitmap_tags") {
            for name in btnames.clone().sequence_values::<String>() {
                let name = name?;
                if !self.bitmap_tag_names.contains(&name) {
                    self.bitmap_tag_names.push(name);
                }
            }
        }

        let entities: Table = snapshot.get("entities")?;
        let mut parent_data: Vec<(u32, u32)> = Vec::new();
        for entry_val in entities.clone().sequence_values::<Table>() {
            let entry = entry_val?;
            let id: u32 = entry.get("id")?;
            let slot = Self::unpack_slot(id);
            let generation: u8 = entry.get("gen").unwrap_or(0);

            self.alive.insert(slot);
            *self.generations.entry(slot).or_insert(0) = generation;
            if slot >= self.next_id {
                self.next_id = slot + 1;
            }

            let comp_row = lua.create_table()?;
            if let Ok(components) = entry.get::<_, Table>("components") {
                for pair in components.clone().pairs::<LuaValue, LuaValue>() {
                    let (k, v) = pair?;
                    comp_row.set(k, v)?;
                }
            }
            comp_store.set(slot, comp_row.clone())?;
            #[cfg(feature = "ecs-archetype")]
            self.reindex_component_row(slot, &comp_row)?;

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

            let layer: i32 = entry.get("layer").unwrap_or(0);
            if layer != 0 {
                self.layers.insert(slot, layer);
            }

            let bitmap: i64 = entry.get("bitmap").unwrap_or(0);
            if bitmap != 0 {
                self.bitmap_masks.insert(slot, bitmap as u64);
            }

            if let Ok(parent_id) = entry.get::<_, u32>("parent") {
                parent_data.push((slot, parent_id));
            }
        }

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

