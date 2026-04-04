//! Lua bindings for `luna.item.*`.
//!
//! Exposes Item, Stack, StackBuilder, StackManager, ItemPool, Slot, StackHistory,
//! and group-analysis utilities to Lua scripts via the `luna.item` namespace.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::item::{
    Item, ItemTypeDef, Stack, StackBuilder, BuildEntry, StackManager,
    ItemPool, Slot, StackHistory,
    define_item_type, get_item_type, get_item_type_names, clear_item_types,
    group_by_stat, group_by_category, group_by_tag_prefix,
    find_n_of_stat, find_at_least_n_of_stat, find_sequences, find_tag_groups,
};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ─────────────────────────────────────────────────────────────────────────────
// LuaItem
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Item` userdata.
#[derive(Clone)]
pub struct LuaItem(pub Rc<RefCell<Item>>);

impl LunaType for LuaItem {
    const TYPE_NAME: &'static str = "Item";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Item"];
}

impl LuaUserData for LuaItem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the type identifier string for this item.
        methods.add_method("getItemType", |_, this, ()| {
            Ok(this.0.borrow().item_type.clone())
        });
        /// Returns the display name of this item.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.0.borrow().name.clone())
        });
        /// Sets the item's display name.
        methods.add_method("setName", |_, this, name: String| {
            this.0.borrow_mut().name = name; Ok(())
        });
        /// Returns the category string.
        methods.add_method("getCategory", |_, this, ()| {
            Ok(this.0.borrow().category.clone())
        });
        /// Sets the category string.
        methods.add_method("setCategory", |_, this, cat: String| {
            this.0.borrow_mut().category = cat; Ok(())
        });
        /// Returns the owner identifier.
        methods.add_method("getOwner", |_, this, ()| {
            Ok(this.0.borrow().owner.clone())
        });
        /// Sets the owner identifier.
        methods.add_method("setOwner", |_, this, owner: String| {
            this.0.borrow_mut().owner = owner; Ok(())
        });
        /// Returns the current slot identifier.
        methods.add_method("getSlot", |_, this, ()| {
            Ok(this.0.borrow().slot.clone())
        });
        /// Sets the current slot identifier.
        methods.add_method("setSlot", |_, this, slot: String| {
            this.0.borrow_mut().slot = slot; Ok(())
        });

        // ── Stats ──────────────────────────────────────────────────────────
        /// Returns the value of a named numeric stat (0 if absent).
        methods.add_method("getStat", |_, this, name: String| {
            Ok(this.0.borrow().get_stat(&name))
        });
        /// Sets a named numeric stat.
        methods.add_method("setStat", |_, this, (name, value): (String, f64)| {
            this.0.borrow_mut().set_stat(name, value); Ok(())
        });
        /// Adds `delta` to a named stat (creates it at `delta` if absent).
        methods.add_method("addStat", |_, this, (name, delta): (String, f64)| {
            this.0.borrow_mut().add_stat(&name, delta); Ok(())
        });
        /// Returns all stats as a `{key=value}` table.
        methods.add_method("getStats", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in &this.0.borrow().stats { tbl.set(k.clone(), *v)?; }
            Ok(tbl)
        });

        // ── Tags ───────────────────────────────────────────────────────────
        /// Returns `true` if the item has the given tag.
        methods.add_method("hasTag", |_, this, tag: String| {
            Ok(this.0.borrow().has_tag(&tag))
        });
        /// Adds a tag if not already present.
        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().add_tag(tag); Ok(())
        });
        /// Removes a tag.
        methods.add_method("removeTag", |_, this, tag: String| {
            this.0.borrow_mut().remove_tag(&tag); Ok(())
        });
        /// Returns all tags as an array table.
        methods.add_method("getTags", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, t) in this.0.borrow().tags.iter().enumerate() {
                tbl.set(i + 1, t.clone())?;
            }
            Ok(tbl)
        });

        // ── Counters ───────────────────────────────────────────────────────
        /// Returns an integer counter (0 if absent).
        methods.add_method("getCounter", |_, this, name: String| {
            Ok(this.0.borrow().get_counter(&name))
        });
        /// Sets an integer counter.
        methods.add_method("setCounter", |_, this, (name, value): (String, i32)| {
            this.0.borrow_mut().set_counter(name, value); Ok(())
        });
        /// Adds `delta` to a counter.
        methods.add_method("addCounter", |_, this, (name, delta): (String, i32)| {
            this.0.borrow_mut().add_counter(&name, delta); Ok(())
        });

        // ── Metadata ──────────────────────────────────────────────────────
        /// Returns a metadata string value (empty string if absent).
        methods.add_method("getMeta", |_, this, key: String| {
            Ok(this.0.borrow().get_meta(&key).unwrap_or_default().to_string())
        });
        /// Sets a metadata string value.
        methods.add_method("setMeta", |_, this, (key, value): (String, String)| {
            this.0.borrow_mut().set_meta(key, value); Ok(())
        });
        /// Returns all metadata as a `{key=value}` table.
        methods.add_method("getAllMeta", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in &this.0.borrow().metadata { tbl.set(k.clone(), v.clone())?; }
            Ok(tbl)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStack
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Stack` userdata.
#[derive(Clone)]
pub struct LuaStack(pub Rc<RefCell<Stack>>);

impl LunaType for LuaStack {
    const TYPE_NAME: &'static str = "ItemStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ItemStack"];
}

impl LuaUserData for LuaStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("size", |_, this, ()| Ok(this.0.borrow().size()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        methods.add_method("isFull", |_, this, ()| Ok(this.0.borrow().is_full()));
        methods.add_method("capacity", |_, this, ()| {
            Ok(this.0.borrow().capacity().map(|c| c as u64))
        });
        /// Pushes a `LuaItem` onto the top of the stack.
        methods.add_method("push", |_, this, item: LuaAnyUserData| {
            let item_inner = item.borrow::<LuaItem>()?.0.borrow().clone();
            if !this.0.borrow_mut().push_top(item_inner) {
                Err(LuaError::runtime("stack is full"))
            } else { Ok(()) }
        });
        /// Pushes a `LuaItem` to the bottom of the stack.
        methods.add_method("pushBottom", |_, this, item: LuaAnyUserData| {
            let item_inner = item.borrow::<LuaItem>()?.0.borrow().clone();
            if !this.0.borrow_mut().push_bottom(item_inner) {
                Err(LuaError::runtime("stack is full"))
            } else { Ok(()) }
        });
        /// Pops the top item; returns `nil` if empty.
        methods.add_method("pop", |_, this, ()| {
            match this.0.borrow_mut().pop_top() {
                Some(item) => Ok(Some(LuaItem(Rc::new(RefCell::new(item))))),
                None => Ok(None),
            }
        });
        /// Pops the bottom item; returns `nil` if empty.
        methods.add_method("popBottom", |_, this, ()| {
            match this.0.borrow_mut().pop_bottom() {
                Some(item) => Ok(Some(LuaItem(Rc::new(RefCell::new(item))))),
                None => Ok(None),
            }
        });
        /// Pops `n` items from the top; returns an array table.
        methods.add_method("popMany", |lua, this, n: usize| {
            let items = this.0.borrow_mut().pop_many(n);
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() {
                tbl.set(i + 1, LuaItem(Rc::new(RefCell::new(item))))?;
            }
            Ok(tbl)
        });
        /// Peeks at the top item without removing it; returns `nil` if empty.
        methods.add_method("peek", |_, this, ()| {
            match this.0.borrow().peek_top() {
                Some(item) => Ok(Some(LuaItem(Rc::new(RefCell::new(item.clone()))))),
                None => Ok(None),
            }
        });
        /// Peeks at item at 1-based position from the top without removing it.
        methods.add_method("peekAt", |_, this, pos: usize| {
            match this.0.borrow().peek_at(pos.saturating_sub(1)) {
                Some(item) => Ok(Some(LuaItem(Rc::new(RefCell::new(item.clone()))))),
                None => Ok(None),
            }
        });
        /// Shuffles the stack in place.
        methods.add_method("shuffle", |_, this, ()| {
            this.0.borrow_mut().shuffle(); Ok(())
        });
        /// Sorts ascending by a named stat.
        methods.add_method("sortByStat", |_, this, stat: String| {
            this.0.borrow_mut().sort_by_stat(&stat); Ok(())
        });
        /// Sorts descending by a named stat.
        methods.add_method("sortByStatDesc", |_, this, stat: String| {
            this.0.borrow_mut().sort_by_stat_desc(&stat); Ok(())
        });
        /// Sorts alphabetically by category.
        methods.add_method("sortByCategory", |_, this, ()| {
            this.0.borrow_mut().sort_by_category(); Ok(())
        });
        /// Returns an array table of all items (top is last).
        methods.add_method("items", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, item) in this.0.borrow().items().iter().enumerate() {
                tbl.set(i + 1, LuaItem(Rc::new(RefCell::new(item.clone()))))?;
            }
            Ok(tbl)
        });
        /// Removes item at 1-based index; returns the item or `nil`.
        methods.add_method("removeAt", |_, this, idx: usize| {
            match this.0.borrow_mut().remove_at(idx.saturating_sub(1)) {
                Some(item) => Ok(Some(LuaItem(Rc::new(RefCell::new(item))))),
                None => Ok(None),
            }
        });
        /// Inserts an item at 1-based index.
        methods.add_method("insertAt", |_, this, (idx, item): (usize, LuaAnyUserData)| {
            let item_inner = item.borrow::<LuaItem>()?.0.borrow().clone();
            if !this.0.borrow_mut().insert_at(idx.saturating_sub(1), item_inner) {
                Err(LuaError::runtime("stack is full"))
            } else { Ok(()) }
        });
        /// Clears all items from the stack.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear(); Ok(())
        });
        /// Returns the count of items with a given type name.
        methods.add_method("countByType", |_, this, type_name: String| {
            Ok(this.0.borrow().count_by_type(&type_name))
        });
        /// Returns the count of items with a given category.
        methods.add_method("countByCategory", |_, this, cat: String| {
            Ok(this.0.borrow().count_by_category(&cat))
        });
        /// Returns the count of items with a given tag.
        methods.add_method("countByTag", |_, this, tag: String| {
            Ok(this.0.borrow().count_by_tag(&tag))
        });
        /// Returns the index (1-based) of the first item with the given type name, or `nil`.
        methods.add_method("findByType", |_, this, type_name: String| {
            Ok(this.0.borrow().find_by_type(&type_name).map(|i| i + 1))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStackBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `StackBuilder` userdata.
#[derive(Clone)]
pub struct LuaStackBuilder(pub Rc<RefCell<StackBuilder>>);

impl LunaType for LuaStackBuilder {
    const TYPE_NAME: &'static str = "StackBuilder";
    const TYPE_HIERARCHY: &'static [&'static str] = &["StackBuilder"];
}

impl LuaUserData for LuaStackBuilder {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Adds `count` copies of `type_name` to the build list.
        methods.add_method("add", |_, this, (type_name, count): (String, usize)| {
            this.0.borrow_mut().add(type_name, count); Ok(())
        });
        /// Adds `count` copies with per-entry overrides supplied as a table.
        ///
        /// The override table may have: `stats = {key=val}`, `tags = {str, ...}`,
        /// `meta = {key=val}`.
        methods.add_method("addWith", |_, this, (type_name, count, overrides): (String, usize, LuaTable)| {
            let mut entry = BuildEntry { type_name, count, ..Default::default() };
            if let Ok(stats) = overrides.get::<_, LuaTable>("stats") {
                for pair in stats.pairs::<String, f64>() {
                    let (k, v) = pair?;
                    entry.stat_overrides.insert(k, v);
                }
            }
            if let Ok(tags) = overrides.get::<_, LuaTable>("tags") {
                for v in tags.sequence_values::<String>() { entry.extra_tags.push(v?); }
            }
            if let Ok(meta) = overrides.get::<_, LuaTable>("meta") {
                for pair in meta.pairs::<String, String>() {
                    let (k, v) = pair?;
                    entry.extra_metadata.insert(k, v);
                }
            }
            this.0.borrow_mut().entries.push(entry);
            Ok(())
        });
        /// Marks a type as required (must appear in any validated stack).
        methods.add_method("requireType", |_, this, type_name: String| {
            this.0.borrow_mut().require_type(type_name); Ok(())
        });
        /// Marks a type as banned (must not appear).
        methods.add_method("banType", |_, this, type_name: String| {
            this.0.borrow_mut().ban_type(type_name); Ok(())
        });
        /// Sets shuffle-on-build flag.
        methods.add_method("setShuffleOnBuild", |_, this, flag: bool| {
            this.0.borrow_mut().shuffle_on_build = flag; Ok(())
        });
        /// Sets the minimum stack size for validation.
        methods.add_method("setMinSize", |_, this, n: usize| {
            this.0.borrow_mut().min_size = n; Ok(())
        });
        /// Sets the maximum stack size for validation (0 = unlimited).
        methods.add_method("setMaxSize", |_, this, n: usize| {
            this.0.borrow_mut().max_size = n; Ok(())
        });
        /// Sets the maximum number of copies of any single type.
        methods.add_method("setMaxCopies", |_, this, n: usize| {
            this.0.borrow_mut().max_copies = n; Ok(())
        });
        /// Validates the current build entries.  Returns an array table of error strings.
        methods.add_method("validateEntries", |lua, this, ()| {
            let errors = this.0.borrow().validate_entries();
            let tbl = lua.create_table()?;
            for (i, e) in errors.iter().enumerate() { tbl.set(i + 1, e.clone())?; }
            Ok(tbl)
        });
        /// Validates an existing `ItemStack` against the builder's constraints.
        methods.add_method("validateStack", |lua, this, stack: LuaAnyUserData| {
            let stack_ref = stack.borrow::<LuaStack>()?;
            let errors = this.0.borrow().validate_stack(&stack_ref.0.borrow());
            let tbl = lua.create_table()?;
            for (i, e) in errors.iter().enumerate() { tbl.set(i + 1, e.clone())?; }
            Ok(tbl)
        });
        /// Builds and returns an `ItemStack`.  Errors if entry types are unknown.
        methods.add_method("build", |_, this, name: Option<String>| {
            let name_str = name.unwrap_or_default();
            let stack = this.0.borrow().build_named(&name_str);
            Ok(LuaStack(Rc::new(RefCell::new(stack))))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaStackManager
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `StackManager` userdata.
#[derive(Clone)]
pub struct LuaStackManager(pub Rc<RefCell<StackManager>>);

impl LunaType for LuaStackManager {
    const TYPE_NAME: &'static str = "ItemStackManager";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ItemStackManager"];
}

impl LuaUserData for LuaStackManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Creates an empty, unbounded stack with the given name.
        methods.add_method("createStack", |_, this, name: String| {
            this.0.borrow_mut().create_stack(name); Ok(())
        });
        /// Creates an empty stack with a capacity cap.
        methods.add_method("createStackCapped", |_, this, (name, cap): (String, usize)| {
            this.0.borrow_mut().create_stack_capped(name, cap); Ok(())
        });
        /// Adds an externally-created `ItemStack` into the manager.
        methods.add_method("addStack", |_, this, (name, stack): (String, LuaAnyUserData)| {
            let inner = stack.borrow::<LuaStack>()?.0.borrow().clone();
            this.0.borrow_mut().add_stack(name, inner); Ok(())
        });
        /// Removes a stack by name.
        methods.add_method("removeStack", |_, this, name: String| {
            this.0.borrow_mut().remove_stack(&name); Ok(())
        });
        /// Returns `true` if a stack with this name exists.
        methods.add_method("hasStack", |_, this, name: String| {
            Ok(this.0.borrow().has_stack(&name))
        });
        /// Returns a snapshot of the named stack as a `LuaStack`.
        methods.add_method("getStack", |_, this, name: String| {
            match this.0.borrow().get_stack(&name) {
                Some(s) => Ok(Some(LuaStack(Rc::new(RefCell::new(s.clone()))))),
                None => Ok(None),
            }
        });
        /// Returns a list of all stack names.
        methods.add_method("stackNames", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, n) in this.0.borrow().stack_names().into_iter().enumerate() {
                tbl.set(i + 1, n)?;
            }
            Ok(tbl)
        });
        /// Total items across all stacks.
        methods.add_method("totalItems", |_, this, ()| {
            Ok(this.0.borrow().total_items())
        });
        /// Moves the item at 1-based `index` from `from_stack` to the top of `to_stack`.
        methods.add_method("moveItem", |_, this, (from, idx, to): (String, usize, String)| {
            this.0.borrow_mut().move_item(&from, idx.saturating_sub(1), &to)
                .map(|_| ())
                .map_err(LuaError::runtime)
        });
        /// Moves the first item of `type_name` from `from_stack` to `to_stack`.
        methods.add_method("moveItemByType", |_, this, (from, type_name, to): (String, String, String)| {
            this.0.borrow_mut().move_item_by_type(&from, &type_name, &to)
                .map(|_| ())
                .map_err(LuaError::runtime)
        });
        /// Moves the top item of `from_stack` to the top of `to_stack`.
        methods.add_method("moveTop", |_, this, (from, to): (String, String)| {
            this.0.borrow_mut().move_top(&from, &to)
                .map(|_| ())
                .map_err(LuaError::runtime)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaItemPool
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `ItemPool` userdata.
#[derive(Clone)]
pub struct LuaItemPool(pub Rc<RefCell<ItemPool>>);

impl LunaType for LuaItemPool {
    const TYPE_NAME: &'static str = "ItemPool";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ItemPool"];
}

impl LuaUserData for LuaItemPool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Adds a type with the given weight.
        methods.add_method("add", |_, this, (type_name, weight): (String, u32)| {
            this.0.borrow_mut().add(type_name, weight); Ok(())
        });
        /// Removes a type from the pool.
        methods.add_method("remove", |_, this, type_name: String| {
            this.0.borrow_mut().remove(&type_name); Ok(())
        });
        /// Sets the weight for an existing entry.
        methods.add_method("setWeight", |_, this, (type_name, weight): (String, u32)| {
            this.0.borrow_mut().set_weight(&type_name, weight); Ok(())
        });
        methods.add_method("size", |_, this, ()| Ok(this.0.borrow().size()));
        methods.add_method("totalWeight", |_, this, ()| Ok(this.0.borrow().total_weight()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        /// Draws `n` type-name strings (with replacement); returns an array table.
        methods.add_method("drawTypes", |lua, this, n: usize| {
            let types = this.0.borrow().draw_types(n);
            let tbl = lua.create_table()?;
            for (i, t) in types.iter().enumerate() { tbl.set(i + 1, t.clone())?; }
            Ok(tbl)
        });
        /// Draws up to `n` unique type-name strings; returns an array table.
        methods.add_method("drawUniqueTypes", |lua, this, n: usize| {
            let types = this.0.borrow().draw_unique_types(n);
            let tbl = lua.create_table()?;
            for (i, t) in types.iter().enumerate() { tbl.set(i + 1, t.clone())?; }
            Ok(tbl)
        });
        /// Draws `n` items (with replacement) as `LuaItem` values; returns an array table.
        methods.add_method("drawItems", |lua, this, n: usize| {
            let items = this.0.borrow().draw_items(n);
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() {
                tbl.set(i + 1, LuaItem(Rc::new(RefCell::new(item))))?;
            }
            Ok(tbl)
        });
        /// Draws up to `n` unique items; returns an array table.
        methods.add_method("drawUniqueItems", |lua, this, n: usize| {
            let items = this.0.borrow().draw_unique_items(n);
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() {
                tbl.set(i + 1, LuaItem(Rc::new(RefCell::new(item))))?;
            }
            Ok(tbl)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaSlot
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `Slot` userdata.
#[derive(Clone)]
pub struct LuaSlot(pub Rc<RefCell<Slot>>);

impl LunaType for LuaSlot {
    const TYPE_NAME: &'static str = "ItemSlot";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ItemSlot"];
}

impl LuaUserData for LuaSlot {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("size", |_, this, ()| Ok(this.0.borrow().size()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        methods.add_method("isFull", |_, this, ()| Ok(this.0.borrow().is_full()));
        methods.add_method("capacity", |_, this, ()| {
            Ok(this.0.borrow().capacity())
        });
        /// Sets the capacity (pass 0 for unlimited).
        methods.add_method("setCapacity", |_, this, cap: usize| {
            this.0.borrow_mut().set_capacity(if cap == 0 { None } else { Some(cap) }); Ok(())
        });
        /// Pushes an item into the slot.
        methods.add_method("push", |_, this, item: LuaAnyUserData| {
            let inner = item.borrow::<LuaItem>()?.0.borrow().clone();
            this.0.borrow_mut().push(inner).map_err(LuaError::runtime)
        });
        /// Pops an item from the slot.
        methods.add_method("pop", |_, this, ()| {
            match this.0.borrow_mut().pop() {
                Some(item) => Ok(Some(LuaItem(Rc::new(RefCell::new(item))))),
                None => Ok(None),
            }
        });
        /// Peeks at the top item without removing it.
        methods.add_method("peek", |_, this, ()| {
            match this.0.borrow().peek() {
                Some(item) => Ok(Some(LuaItem(Rc::new(RefCell::new(item.clone()))))),
                None => Ok(None),
            }
        });
        /// Returns all items as an array table.
        methods.add_method("items", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, item) in this.0.borrow().items().iter().enumerate() {
                tbl.set(i + 1, LuaItem(Rc::new(RefCell::new(item.clone()))))?;
            }
            Ok(tbl)
        });
        /// Clears the slot; returns the items as an array table.
        methods.add_method("clear", |lua, this, ()| {
            let items = this.0.borrow_mut().clear();
            let tbl = lua.create_table()?;
            for (i, item) in items.into_iter().enumerate() {
                tbl.set(i + 1, LuaItem(Rc::new(RefCell::new(item))))?;
            }
            Ok(tbl)
        });
        methods.add_method("hasItemWithTag", |_, this, tag: String| {
            Ok(this.0.borrow().has_item_with_tag(&tag))
        });
        methods.add_method("hasItemOfType", |_, this, type_name: String| {
            Ok(this.0.borrow().has_item_of_type(&type_name))
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaHistory
// ─────────────────────────────────────────────────────────────────────────────

/// Lua-facing `StackHistory` userdata.
#[derive(Clone)]
pub struct LuaHistory(pub Rc<RefCell<StackHistory>>);

impl LunaType for LuaHistory {
    const TYPE_NAME: &'static str = "StackHistory";
    const TYPE_HIERARCHY: &'static [&'static str] = &["StackHistory"];
}

impl LuaUserData for LuaHistory {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method("len", |_, this, ()| Ok(this.0.borrow().len()));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));
        methods.add_method("clear", |_, this, ()| { this.0.borrow_mut().clear(); Ok(()) });
        /// Records a custom event label for a named stack.
        methods.add_method("recordCustom", |_, this, (stack_name, label, size_after): (String, String, usize)| {
            this.0.borrow_mut().record_custom(stack_name, label, size_after); Ok(())
        });
        /// Returns the last entry as a table `{seq, stack, action, sizeAfter}`, or `nil`.
        methods.add_method("last", |lua, this, ()| {
            match this.0.borrow().last() {
                None => Ok(LuaValue::Nil),
                Some(e) => {
                    let tbl = lua.create_table()?;
                    tbl.set("seq", e.seq)?;
                    tbl.set("stack", e.stack_name.clone())?;
                    tbl.set("action", format!("{:?}", e.action))?;
                    tbl.set("sizeAfter", e.size_after)?;
                    Ok(LuaValue::Table(tbl))
                }
            }
        });
        /// Returns all entries as an array of `{seq, stack, action, sizeAfter}` tables.
        methods.add_method("entries", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, e) in this.0.borrow().entries().enumerate() {
                let row = lua.create_table()?;
                row.set("seq", e.seq)?;
                row.set("stack", e.stack_name.clone())?;
                row.set("action", format!("{:?}", e.action))?;
                row.set("sizeAfter", e.size_after)?;
                tbl.set(i + 1, row)?;
            }
            Ok(tbl)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: extract Item slice from a Lua array table
// ─────────────────────────────────────────────────────────────────────────────

fn items_from_lua_table(tbl: LuaTable) -> LuaResult<Vec<Item>> {
    let mut items = Vec::new();
    for v in tbl.sequence_values::<LuaAnyUserData>() {
        items.push(v?.borrow::<LuaItem>()?.0.borrow().clone());
    }
    Ok(items)
}

// ─────────────────────────────────────────────────────────────────────────────
// register
// ─────────────────────────────────────────────────────────────────────────────

/// Registers the `luna.item.*` API.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let item_table = lua.create_table()?;

    // ── Type registry ──────────────────────────────────────────────────────

    /// Defines an item type in the global registry.
    ///
    /// ```lua
    /// luna.item.defineType("sword", {
    ///   category = "weapon",
    ///   stats    = { damage = 10, weight = 5 },
    ///   tags     = { "metal", "sharp" },
    ///   meta     = { rarity = "common" },
    /// })
    /// ```
    item_table.set("defineType", lua.create_function(|_, (name, def_tbl): (String, LuaTable)| {
        let mut def = ItemTypeDef {
            name: name.clone(),
            ..Default::default()
        };
        if let Ok(cat) = def_tbl.get::<_, String>("category") { def.category = cat; }
        if let Ok(stats) = def_tbl.get::<_, LuaTable>("stats") {
            for pair in stats.pairs::<String, f64>() {
                let (k, v) = pair?; def.base_stats.insert(k, v);
            }
        }
        if let Ok(tags) = def_tbl.get::<_, LuaTable>("tags") {
            for v in tags.sequence_values::<String>() { def.base_tags.push(v?); }
        }
        if let Ok(meta) = def_tbl.get::<_, LuaTable>("meta") {
            for pair in meta.pairs::<String, String>() {
                let (k, v) = pair?; def.metadata.insert(k, v);
            }
        }
        define_item_type(name, def);
        Ok(())
    })?)?;

    /// Returns the definition table for a registered type, or `nil` if not found.
    item_table.set("getType", lua.create_function(|lua, name: String| {
        match get_item_type(&name) {
            None => Ok(LuaValue::Nil),
            Some(def) => {
                let tbl = lua.create_table()?;
                tbl.set("name", def.name)?;
                tbl.set("category", def.category)?;
                let stats = lua.create_table()?;
                for (k, v) in &def.base_stats { stats.set(k.clone(), *v)?; }
                tbl.set("stats", stats)?;
                let tags = lua.create_table()?;
                for (i, t) in def.base_tags.iter().enumerate() { tags.set(i + 1, t.clone())?; }
                tbl.set("tags", tags)?;
                Ok(LuaValue::Table(tbl))
            }
        }
    })?)?;

    /// Returns an array table of all registered type names.
    item_table.set("getTypeNames", lua.create_function(|lua, ()| {
        let tbl = lua.create_table()?;
        for (i, n) in get_item_type_names().iter().enumerate() { tbl.set(i + 1, n.clone())?; }
        Ok(tbl)
    })?)?;

    /// Clears all registered item types.
    item_table.set("clearTypes", lua.create_function(|_, ()| {
        clear_item_types(); Ok(())
    })?)?;

    // ── Constructors ───────────────────────────────────────────────────────

    /// Creates a new item by seeding from the registered type.
    ///
    /// ```lua
    /// local sword = luna.item.newItem("sword")
    /// sword:setStat("damage", 15)
    /// ```
    item_table.set("newItem", lua.create_function(|_, type_name: String| {
        Ok(LuaItem(Rc::new(RefCell::new(Item::new(&type_name)))))
    })?)?;

    /// Creates a new empty stack.
    ///
    /// ```lua
    /// local hand = luna.item.newStack("hand")
    /// local deck = luna.item.newStack("deck", 60)   -- capped at 60
    /// ```
    item_table.set("newStack", lua.create_function(|_, (name, cap): (String, Option<usize>)| {
        let stack = match cap {
            Some(c) => Stack::with_capacity(name, c),
            None => Stack::new(name),
        };
        Ok(LuaStack(Rc::new(RefCell::new(stack))))
    })?)?;

    /// Creates a new `StackBuilder`.
    item_table.set("newStackBuilder", lua.create_function(|_, name: Option<String>| {
        Ok(LuaStackBuilder(Rc::new(RefCell::new(StackBuilder::new(name.unwrap_or_default())))))
    })?)?;

    /// Creates a new `StackManager`.
    item_table.set("newStackManager", lua.create_function(|_, ()| {
        Ok(LuaStackManager(Rc::new(RefCell::new(StackManager::new()))))
    })?)?;

    /// Creates a new `ItemPool`.
    item_table.set("newItemPool", lua.create_function(|_, name: Option<String>| {
        Ok(LuaItemPool(Rc::new(RefCell::new(ItemPool::new(name.unwrap_or_default())))))
    })?)?;

    /// Creates a new `Slot`.
    ///
    /// ```lua
    /// local slot = luna.item.newSlot("weapon_slot", 1)  -- holds 1 item
    /// ```
    item_table.set("newSlot", lua.create_function(|_, (name, cap): (String, Option<usize>)| {
        let slot = match cap {
            Some(c) => Slot::with_capacity(name, c),
            None => Slot::new(name),
        };
        Ok(LuaSlot(Rc::new(RefCell::new(slot))))
    })?)?;

    /// Creates a new `StackHistory`.
    ///
    /// ```lua
    /// local h = luna.item.newHistory()
    /// local h = luna.item.newHistory(100)  -- keeps last 100 events
    /// ```
    item_table.set("newHistory", lua.create_function(|_, max_size: Option<usize>| {
        let history = match max_size {
            Some(n) => StackHistory::with_max_size(n),
            None => StackHistory::new(),
        };
        Ok(LuaHistory(Rc::new(RefCell::new(history))))
    })?)?;

    // ── Group / analysis functions ─────────────────────────────────────────

    /// Groups items in an array table by the integer part of a stat.
    ///
    /// Returns `{ [stat_value] = {LuaItem, …}, … }`.
    item_table.set("groupByStat", lua.create_function(|lua, (items_tbl, stat): (LuaTable, String)| {
        let items = items_from_lua_table(items_tbl)?;
        let groups = group_by_stat(&items, &stat);
        let result = lua.create_table()?;
        for (val, indices) in groups {
            let inner = lua.create_table()?;
            for (i, idx) in indices.iter().enumerate() {
                inner.set(i + 1, LuaItem(Rc::new(RefCell::new(items[*idx].clone()))))?;
            }
            result.set(val, inner)?;
        }
        Ok(result)
    })?)?;

    /// Groups items by category.  Returns `{ [category] = {LuaItem, …}, … }`.
    item_table.set("groupByCategory", lua.create_function(|lua, items_tbl: LuaTable| {
        let items = items_from_lua_table(items_tbl)?;
        let groups = group_by_category(&items);
        let result = lua.create_table()?;
        for (cat, indices) in groups {
            let inner = lua.create_table()?;
            for (i, idx) in indices.iter().enumerate() {
                inner.set(i + 1, LuaItem(Rc::new(RefCell::new(items[*idx].clone()))))?;
            }
            result.set(cat, inner)?;
        }
        Ok(result)
    })?)?;

    /// Groups items by a tag prefix such as `"suit"`.
    ///
    /// Returns `{ [value] = {LuaItem, …}, … }` where `value` is the part after the `:`.
    item_table.set("groupByTagPrefix", lua.create_function(|lua, (items_tbl, prefix): (LuaTable, String)| {
        let items = items_from_lua_table(items_tbl)?;
        let groups = group_by_tag_prefix(&items, &prefix);
        let result = lua.create_table()?;
        for (val, indices) in groups {
            let inner = lua.create_table()?;
            for (i, idx) in indices.iter().enumerate() {
                inner.set(i + 1, LuaItem(Rc::new(RefCell::new(items[*idx].clone()))))?;
            }
            result.set(val, inner)?;
        }
        Ok(result)
    })?)?;

    /// Finds groups where exactly `n` items share the same stat integer value.
    ///
    /// Returns an array of `{label, score, items}` tables.
    item_table.set("findNOfStat", lua.create_function(|lua, (items_tbl, stat, n): (LuaTable, String, usize)| {
        let items = items_from_lua_table(items_tbl)?;
        let groups = find_n_of_stat(&items, &stat, n);
        let result = lua.create_table()?;
        for (gi, g) in groups.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("label", g.label.clone())?;
            row.set("score", g.score)?;
            let inner = lua.create_table()?;
            for (i, &idx) in g.indices.iter().enumerate() {
                inner.set(i + 1, LuaItem(Rc::new(RefCell::new(items[idx].clone()))))?;
            }
            row.set("items", inner)?;
            result.set(gi + 1, row)?;
        }
        Ok(result)
    })?)?;

    /// Finds groups where at least `n` items share the same stat integer value.
    item_table.set("findAtLeastNOfStat", lua.create_function(|lua, (items_tbl, stat, n): (LuaTable, String, usize)| {
        let items = items_from_lua_table(items_tbl)?;
        let groups = find_at_least_n_of_stat(&items, &stat, n);
        let result = lua.create_table()?;
        for (gi, g) in groups.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("label", g.label.clone())?;
            row.set("score", g.score)?;
            let inner = lua.create_table()?;
            for (i, &idx) in g.indices.iter().enumerate() {
                inner.set(i + 1, LuaItem(Rc::new(RefCell::new(items[idx].clone()))))?;
            }
            row.set("items", inner)?;
            result.set(gi + 1, row)?;
        }
        Ok(result)
    })?)?;

    /// Finds consecutive integer stat sequences of length ≥ `min_run`.
    ///
    /// Returns an array of `{label, score, items}` tables.
    item_table.set("findSequences", lua.create_function(|lua, (items_tbl, stat, min_run): (LuaTable, String, usize)| {
        let items = items_from_lua_table(items_tbl)?;
        let groups = find_sequences(&items, &stat, min_run);
        let result = lua.create_table()?;
        for (gi, g) in groups.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("label", g.label.clone())?;
            row.set("score", g.score)?;
            let inner = lua.create_table()?;
            for (i, &idx) in g.indices.iter().enumerate() {
                inner.set(i + 1, LuaItem(Rc::new(RefCell::new(items[idx].clone()))))?;
            }
            row.set("items", inner)?;
            result.set(gi + 1, row)?;
        }
        Ok(result)
    })?)?;

    /// Finds groups of items sharing a tag-prefix value (flush-style), min size `min_size`.
    item_table.set("findTagGroups", lua.create_function(|lua, (items_tbl, prefix, min_size): (LuaTable, String, usize)| {
        let items = items_from_lua_table(items_tbl)?;
        let groups = find_tag_groups(&items, &prefix, min_size);
        let result = lua.create_table()?;
        for (gi, g) in groups.iter().enumerate() {
            let row = lua.create_table()?;
            row.set("label", g.label.clone())?;
            row.set("score", g.score)?;
            let inner = lua.create_table()?;
            for (i, &idx) in g.indices.iter().enumerate() {
                inner.set(i + 1, LuaItem(Rc::new(RefCell::new(items[idx].clone()))))?;
            }
            row.set("items", inner)?;
            result.set(gi + 1, row)?;
        }
        Ok(result)
    })?)?;

    luna.set("item", item_table)?;
    Ok(())
}
