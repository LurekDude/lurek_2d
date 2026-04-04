//! Lua API bindings for the `luna.inventory.*` slot-based inventory module.
//!
//! Provides `Item`, `ItemStack`, `Slot`, `Container`, `ItemSet`, and `Inventory`
//! UserData objects for building RPG-style inventory systems in Lua.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

use crate::inventory::{
    Container, ContainerMode, Inventory, InventoryEntry, ItemSet, ItemStack, Slot, SlotState,
};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ────────────────────────────────────────────────────────────────────────────
// LuaItem
// ────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a single item definition.
///
/// # Fields
/// - `inner` — `Rc<RefCell<InventoryEntry>>`.
/// - `resource_ref` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
/// - `user_data_ref` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
#[derive(Clone)]
pub(crate) struct LuaItem {
    inner: Rc<RefCell<InventoryEntry>>,
    resource_ref: Rc<RefCell<Option<LuaRegistryKey>>>,
    user_data_ref: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LuaItem {
    fn wrap(entry: InventoryEntry) -> Self {
        Self {
            inner: Rc::new(RefCell::new(entry)),
            resource_ref: Rc::new(RefCell::new(None)),
            user_data_ref: Rc::new(RefCell::new(None)),
        }
    }
}

impl LunaType for LuaItem {
    const TYPE_NAME: &'static str = "Item";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaItem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the type.
        /// @return any
        ///
        /// # Parameters
        /// - `t` — `string`.
        ///
        /// # Returns
        /// The current type.
        methods.add_method("getType", |_, this, ()| {
            Ok(this.inner.borrow().item_type.clone())
        });

        /// Sets the type.
        /// @param t : string
        ///
        /// # Parameters
        /// - `t` — `string`.
        methods.add_method("setType", |_, this, t: String| {
            this.inner.borrow_mut().item_type = t;
            Ok(())
        });

        /// Returns the weight.
        /// @return any
        ///
        /// # Parameters
        /// - `w` — `number`.
        ///
        /// # Returns
        /// The current weight.
        methods.add_method("getWeight", |_, this, ()| Ok(this.inner.borrow().weight));

        /// Sets the weight.
        /// @param w : number
        ///
        /// # Parameters
        /// - `w` — `number`.
        methods.add_method("setWeight", |_, this, w: f64| {
            this.inner.borrow_mut().weight = w;
            Ok(())
        });

        /// Returns the size.
        /// @return any
        ///
        /// # Parameters
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        ///
        /// # Returns
        /// The current size.
        methods.add_method("getSize", |_, this, ()| {
            let it = this.inner.borrow();
            Ok((it.size_w, it.size_h))
        });

        /// Sets the size.
        /// @param w : integer
        /// @param h : integer
        ///
        /// # Parameters
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        methods.add_method("setSize", |_, this, (w, h): (u32, u32)| {
            let mut it = this.inner.borrow_mut();
            it.size_w = w;
            it.size_h = h;
            Ok(())
        });

        /// Returns the stack limit.
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer`.
        ///
        /// # Returns
        /// The current stack limit.
        methods.add_method("getStackLimit", |_, this, ()| {
            Ok(this.inner.borrow().stack_limit)
        });

        /// Sets the stack limit.
        /// @param n : integer
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("setStackLimit", |_, this, n: u32| {
            this.inner.borrow_mut().stack_limit = n.max(1);
            Ok(())
        });

        /// Adds tag to the collection.
        /// @param tag : string
        ///
        /// # Parameters
        /// - `tag` — `string`.
        methods.add_method("addTag", |_, this, tag: String| {
            this.inner.borrow_mut().add_tag(tag);
            Ok(())
        });

        /// Removes tag from the collection.
        /// @param tag : string
        /// @return any
        ///
        /// # Parameters
        /// - `tag` — `string`.
        methods.add_method("removeTag", |_, this, tag: String| {
            Ok(this.inner.borrow_mut().remove_tag(&tag))
        });

        /// Returns `true` if tag.
        /// @param tag : string
        /// @return any
        ///
        /// # Parameters
        /// - `tag` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTag", |_, this, tag: String| {
            Ok(this.inner.borrow().has_tag(&tag))
        });

        /// Returns the tags.
        /// @return table
        ///
        /// # Returns
        /// The current tags.
        methods.add_method("getTags", |lua, this, ()| {
            let it = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, tag) in it.tags.iter().enumerate() {
                tbl.set(i + 1, tag.clone())?;
            }
            Ok(tbl)
        });

        /// Returns a deep copy of this object.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("clone", |_, this, ()| {
            Ok(LuaItem::wrap(this.inner.borrow().clone()))
        });

        /// Store any Lua value as a resource reference (e.g. a texture or sprite).
        /// @param value : any
        ///
        /// # Parameters
        /// - `value` — any Lua value to store.
        methods.add_method("setResourceRef", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            *this.resource_ref.borrow_mut() = Some(key);
            Ok(())
        });

        /// Get the stored resource reference, or nil if none set.
        /// @return any
        ///
        /// # Returns
        /// The stored Lua value, or `nil`.
        methods.add_method("getResourceRef", |lua, this, ()| {
            match &*this.resource_ref.borrow() {
                Some(key) => Ok(lua.registry_value::<LuaValue>(key)?),
                None => Ok(LuaValue::Nil),
            }
        });

        /// Store any Lua value as user data on this item.
        /// @param value : any
        ///
        /// # Parameters
        /// - `value` — any Lua value to store.
        methods.add_method("setUserData", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            *this.user_data_ref.borrow_mut() = Some(key);
            Ok(())
        });

        /// Get the stored user data, or nil if none set.
        /// @return any
        ///
        /// # Returns
        /// The stored Lua value, or `nil`.
        methods.add_method("getUserData", |lua, this, ()| {
            match &*this.user_data_ref.borrow() {
                Some(key) => Ok(lua.registry_value::<LuaValue>(key)?),
                None => Ok(LuaValue::Nil),
            }
        });
    }
}

// ────────────────────────────────────────────────────────────────────────────
// LuaItemStack
// ────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a counted stack of items.
#[derive(Clone)]
pub(crate) struct LuaItemStack(Rc<RefCell<ItemStack>>);

impl LunaType for LuaItemStack {
    const TYPE_NAME: &'static str = "ItemStack";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaItemStack {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the item.
        /// @return any
        ///
        /// # Returns
        /// The current item.
        methods.add_method("getItem", |_, this, ()| {
            let stack = this.0.borrow();
            Ok(LuaItem::wrap(stack.item.clone()))
        });

        /// Returns the quantity.
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer`.
        ///
        /// # Returns
        /// The current quantity.
        methods.add_method("getQuantity", |_, this, ()| Ok(this.0.borrow().quantity));

        /// Sets the quantity.
        /// @param n : integer
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("setQuantity", |_, this, n: u32| {
            let mut s = this.0.borrow_mut();
            s.quantity = n.min(s.max_quantity);
            Ok(())
        });

        /// Returns the max quantity.
        /// @return any
        ///
        /// # Returns
        /// The current max quantity.
        methods.add_method("getMaxQuantity", |_, this, ()| {
            Ok(this.0.borrow().max_quantity)
        });

        /// Returns `true` if full.
        /// @return boolean
        ///
        /// # Parameters
        /// - `n` — `integer`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isFull", |_, this, ()| Ok(this.0.borrow().is_full()));

        /// Adds an entry to the collection.
        /// @param n : integer
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("add", |_, this, n: u32| Ok(this.0.borrow_mut().add(n)));

        /// Removes the entry from the collection.
        /// @param n : integer
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("remove", |_, this, n: u32| {
            Ok(this.0.borrow_mut().remove(n))
        });

        /// Split on this ItemStack.
        /// @param n : integer
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("split", |_, this, n: u32| {
            let split = this.0.borrow_mut().split(n);
            match split {
                Some(s) => Ok(Some(LuaItemStack(Rc::new(RefCell::new(s))))),
                None => Ok(None),
            }
        });

        /// Merge on this ItemStack.
        /// @param other : ItemStack
        /// @return any
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_stack = other.borrow::<LuaItemStack>()?;
            let leftover = this.0.borrow_mut().merge(&mut other_stack.0.borrow_mut());
            Ok(leftover)
        });

        /// Returns a deep copy of this object.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("clone", |_, this, ()| {
            Ok(LuaItemStack(Rc::new(RefCell::new(this.0.borrow().clone()))))
        });
    }
}

// ────────────────────────────────────────────────────────────────────────────
// LuaSlot
// ────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a single inventory slot.
#[derive(Clone)]
pub(crate) struct LuaSlot(Rc<RefCell<Slot>>);

impl LunaType for LuaSlot {
    const TYPE_NAME: &'static str = "Slot";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaSlot {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the type.
        /// @return any
        ///
        /// # Parameters
        /// - `t` — `string`.
        ///
        /// # Returns
        /// The current type.
        methods.add_method("getType", |_, this, ()| {
            Ok(this.0.borrow().slot_type.clone())
        });

        /// Sets the type.
        /// @param t : string
        ///
        /// # Parameters
        /// - `t` — `string`.
        methods.add_method("setType", |_, this, t: String| {
            this.0.borrow_mut().slot_type = t;
            Ok(())
        });

        /// Returns the state.
        /// @return any
        ///
        /// # Parameters
        /// - `s` — `string`.
        ///
        /// # Returns
        /// The current state.
        methods.add_method("getState", |_, this, ()| {
            Ok(this.0.borrow().state.as_str().to_string())
        });

        /// Sets the state.
        /// @param s : string
        ///
        /// # Parameters
        /// - `s` — `string`.
        methods.add_method("setState", |_, this, s: String| {
            if let Some(st) = SlotState::from_str(&s) {
                this.0.borrow_mut().state = st;
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!(
                    "luna.inventory: invalid slot state '{s}'. Use 'active', 'passive', or 'idle'"
                )))
            }
        });

        /// Returns `true` if empty.
        /// @return boolean
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.0.borrow().is_empty()));

        /// Returns the stack.
        /// @return any
        ///
        /// # Returns
        /// The current stack.
        methods.add_method("getStack", |_, this, ()| {
            let slot = this.0.borrow();
            match &slot.stack {
                Some(s) => Ok(Some(LuaItemStack(Rc::new(RefCell::new(s.clone()))))),
                None => Ok(None),
            }
        });

        /// Sets the stack.
        /// @param stack_ud : ItemStack
        /// @return any
        ///
        /// # Parameters
        /// - `stack_ud` — `userdata`.
        methods.add_method("setStack", |_, this, stack_ud: LuaAnyUserData| {
            let stack = stack_ud.borrow::<LuaItemStack>()?;
            let placed = this.0.borrow_mut().set_stack(stack.0.borrow().clone());
            Ok(placed)
        });

        /// Removes all entries.
        ///
        /// # Parameters
        /// - `item_ud` — `userdata`.
        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });

        /// Returns `true` if accept.
        /// @param item_ud : Item
        /// @return any
        ///
        /// # Parameters
        /// - `item_ud` — `userdata`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canAccept", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaItem>()?;
            let item_ref = item.inner.borrow();
            Ok(this.0.borrow().can_accept(&item_ref))
        });

        /// Returns the capacity.
        /// @return any
        ///
        /// # Parameters
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        ///
        /// # Returns
        /// The current capacity.
        methods.add_method("getCapacity", |_, this, ()| {
            let s = this.0.borrow();
            Ok((s.capacity_w, s.capacity_h))
        });

        /// Sets the capacity.
        /// @param w : integer
        /// @param h : integer
        ///
        /// # Parameters
        /// - `w` — `integer`.
        /// - `h` — `integer`.
        methods.add_method("setCapacity", |_, this, (w, h): (u32, u32)| {
            let mut s = this.0.borrow_mut();
            s.capacity_w = w;
            s.capacity_h = h;
            Ok(())
        });

        /// Shortcut: get the item from the held stack, or nil if empty.
        /// @return any
        ///
        /// # Returns
        /// `Item` or `nil`.
        methods.add_method("getItem", |_, this, ()| {
            let slot = this.0.borrow();
            match slot.get_item() {
                Some(it) => Ok(Some(LuaItem::wrap(it.clone()))),
                None => Ok(None),
            }
        });
    }
}

// ────────────────────────────────────────────────────────────────────────────
// LuaContainer
// ────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a named collection of slots.
#[derive(Clone)]
pub(crate) struct LuaContainer(Rc<RefCell<Container>>);

impl LunaType for LuaContainer {
    const TYPE_NAME: &'static str = "Container";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaContainer {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the name.
        /// @return any
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));

        /// Returns the mode.
        /// @return any
        ///
        /// # Returns
        /// The current mode.
        methods.add_method("getMode", |_, this, ()| {
            Ok(this.0.borrow().mode.as_str().to_string())
        });

        /// Returns the slot count.
        /// @return any
        ///
        /// # Returns
        /// The current slot count.
        methods.add_method("getSlotCount", |_, this, ()| {
            Ok(this.0.borrow().slot_count())
        });

        /// Returns the max slots.
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer`.
        ///
        /// # Returns
        /// The current max slots.
        methods.add_method("getMaxSlots", |_, this, ()| Ok(this.0.borrow().max_slots));

        /// Sets the max slots.
        /// @param n : integer
        ///
        /// # Parameters
        /// - `n` — `integer`.
        methods.add_method("setMaxSlots", |_, this, n: u32| {
            this.0.borrow_mut().max_slots = n;
            Ok(())
        });

        /// Returns the weight limit.
        /// @return any
        ///
        /// # Parameters
        /// - `w` — `number`.
        ///
        /// # Returns
        /// The current weight limit.
        methods.add_method("getWeightLimit", |_, this, ()| {
            Ok(this.0.borrow().weight_limit)
        });

        /// Sets the weight limit.
        /// @param w : number
        ///
        /// # Parameters
        /// - `w` — `number`.
        methods.add_method("setWeightLimit", |_, this, w: f64| {
            this.0.borrow_mut().weight_limit = w;
            Ok(())
        });

        /// Returns the current weight.
        /// @return any
        ///
        /// # Parameters
        /// - `index` — `integer`.
        ///
        /// # Returns
        /// The current current weight.
        methods.add_method("getCurrentWeight", |_, this, ()| {
            Ok(this.0.borrow().current_weight())
        });

        /// Get a slot by 1-based index (Lua convention).
        /// @param index : integer
        /// @return any
        methods.add_method("getSlot", |_, this, index: usize| {
            if index < 1 {
                return Err(LuaError::RuntimeError(
                    "luna.inventory: slot index must be >= 1".into(),
                ));
            }
            let c = this.0.borrow();
            match c.get_slot(index - 1) {
                Some(s) => Ok(Some(LuaSlot(Rc::new(RefCell::new(s.clone()))))),
                None => Ok(None),
            }
        });

        /// Adds slot to the collection.
        /// @param opts : table?
        /// @return any
        ///
        /// # Parameters
        /// - `opts` — `table` optional.
        methods.add_method("addSlot", |_, this, opts: Option<LuaTable>| {
            let (slot_type, state_str) = if let Some(t) = opts {
                let st: String = t.get::<_, String>("type").unwrap_or_else(|_| "any".into());
                let ss: String = t
                    .get::<_, String>("state")
                    .unwrap_or_else(|_| "active".into());
                (st, ss)
            } else {
                ("any".into(), "active".into())
            };
            let state = SlotState::from_str(&state_str).unwrap_or(SlotState::Active);
            this.0.borrow_mut().add_slot(Slot::new(slot_type, state));
            Ok(this.0.borrow().slot_count())
        });

        /// Removes slot from the collection.
        /// @param index : integer
        ///
        /// # Parameters
        /// - `index` — `integer`.
        methods.add_method("removeSlot", |_, this, index: usize| {
            if index < 1 {
                return Err(LuaError::RuntimeError(
                    "luna.inventory: slot index must be >= 1".into(),
                ));
            }
            this.0.borrow_mut().remove_slot(index - 1);
            Ok(())
        });

        /// Expand on this Container.
        /// @param n : integer
        /// @return any
        ///
        /// # Parameters
        /// - `item_ud` — `userdata`.
        /// - `qty` — `integer` optional.
        methods.add_method("expand", |_, this, n: u32| {
            Ok(this.0.borrow_mut().expand(n))
        });

        /// Adds item to the collection.
        ///
        /// # Parameters
        /// - `item_ud` — `userdata`.
        /// - `qty` — `integer` optional.
        methods.add_method(
            "addItem",
            |_, this, (item_ud, qty): (LuaAnyUserData, Option<u32>)| {
                let item = item_ud.borrow::<LuaItem>()?;
                let item_clone = item.inner.borrow().clone();
                let quantity = qty.unwrap_or(1);
                Ok(this.0.borrow_mut().add_item(item_clone, quantity))
            },
        );

        /// Returns `true` if item.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        /// - `qty` — `integer` optional.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method(
            "hasItem",
            |_, this, (item_type, qty): (String, Option<u32>)| {
                Ok(this.0.borrow().has_item(&item_type, qty.unwrap_or(1)))
            },
        );
        /// Returns the number of item.
        /// @param item_type : string
        /// @return any
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        /// - `qty` — `integer`.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("countItem", |_, this, item_type: String| {
            Ok(this.0.borrow().count_item(&item_type))
        });
        /// Removes item from the collection.
        /// @param item_type : string
        /// @param qty : integer
        /// @return any
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        /// - `qty` — `integer`.
        methods.add_method("removeItem", |_, this, (item_type, qty): (String, u32)| {
            Ok(this.0.borrow_mut().remove_item(&item_type, qty))
        });
        /// To list on this Container.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("toList", |lua, this, ()| {
            let items = this.0.borrow().to_item_list();
            let t = lua.create_table()?;
            for (i, (item_type, qty)) in items.into_iter().enumerate() {
                let entry = lua.create_table()?;
                /// Item type on this Container.
                ///
                /// # Returns
                /// The result.
                entry.set("itemType", item_type)?;
                /// Quantity on this Container.
                ///
                /// # Returns
                /// The result.
                entry.set("quantity", qty)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
        /// Returns the slots.
        /// @return table
        ///
        /// # Returns
        /// The current slots.
        methods.add_method("getSlots", |lua, this, ()| {
            let tbl = lua.create_table()?;
            let c = this.0.borrow();
            for (i, slot) in c.slots.iter().enumerate() {
                tbl.set(i + 1, LuaSlot(Rc::new(RefCell::new(slot.clone()))))?;
            }
            Ok(tbl)
        });
    }
}

// ────────────────────────────────────────────────────────────────────────────
// LuaItemSet
// ────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a named item set with requirements.
///
/// # Fields
/// - `inner` — `Rc<RefCell<ItemSet>>`.
/// - `bonus_ref` — `Rc<RefCell<Option<LuaRegistryKey>>>`.
#[derive(Clone)]
pub(crate) struct LuaItemSet {
    inner: Rc<RefCell<ItemSet>>,
    bonus_ref: Rc<RefCell<Option<LuaRegistryKey>>>,
}

impl LuaItemSet {
    fn wrap(set: ItemSet) -> Self {
        Self {
            inner: Rc::new(RefCell::new(set)),
            bonus_ref: Rc::new(RefCell::new(None)),
        }
    }
}

impl LunaType for LuaItemSet {
    const TYPE_NAME: &'static str = "ItemSet";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaItemSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        /// Returns the name.
        /// @return any
        ///
        /// # Parameters
        /// - `tag` — `string`.
        /// - `slot_filter` — `string` optional.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| {
            Ok(this.inner.borrow().name.clone())
        });

        methods.add_method(
            "addRequirement",
            |_, this, (tag, slot_filter): (String, Option<String>)| {
                let filter = slot_filter.unwrap_or_default();
                this.inner.borrow_mut().add_requirement(tag, filter);
                Ok(())
            },
        );

        /// Returns the requirements.
        /// @return table
        ///
        /// # Returns
        /// The current requirements.
        methods.add_method("getRequirements", |lua, this, ()| {
            let set = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, req) in set.requirements.iter().enumerate() {
                let r = lua.create_table()?;
                /// Tag on this ItemSet.
                ///
                /// # Returns
                /// The result.
                r.set("tag", req.tag.clone())?;
                /// Slot filter on this ItemSet.
                ///
                /// # Returns
                /// The result.
                r.set("slotFilter", req.slot_filter.clone())?;
                tbl.set(i + 1, r)?;
            }
            Ok(tbl)
        });

        /// Returns the number of requirements in this set.
        /// @return integer
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getRequirementCount", |_, this, ()| {
            Ok(this.inner.borrow().requirements.len())
        });

        /// Check if all requirements of this set are met by the inventory.
        /// @param inv_ud : Inventory
        /// @return any
        ///
        /// # Parameters
        /// - `inventory` — `Inventory` userdata.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isActive", |_, this, inv_ud: LuaAnyUserData| {
            let inv = inv_ud.borrow::<LuaInventory>()?;
            let inv_ref = inv.inner.borrow();
            let set = this.inner.borrow();
            Ok(set.is_active(&inv_ref.equip_slots))
        });

        /// Store bonus data (any Lua value) on this item set.
        /// @param value : any
        ///
        /// # Parameters
        /// - `value` — any Lua value (e.g. a stats table).
        methods.add_method("setBonusRef", |lua, this, value: LuaValue| {
            let key = lua.create_registry_value(value)?;
            *this.bonus_ref.borrow_mut() = Some(key);
            Ok(())
        });

        /// Get the stored bonus data, or nil if none set.
        /// @return any
        ///
        /// # Returns
        /// The stored Lua value, or `nil`.
        methods.add_method("getBonusRef", |lua, this, ()| {
            match &*this.bonus_ref.borrow() {
                Some(key) => Ok(lua.registry_value::<LuaValue>(key)?),
                None => Ok(LuaValue::Nil),
            }
        });
    }
}

// ────────────────────────────────────────────────────────────────────────────
// LuaInventory
// ────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for the top-level inventory.
///
/// # Fields
/// - `inner` — `Rc<RefCell<Inventory>>`.
/// - `callbacks` — `Rc<RefCell<HashMap<String`.
#[derive(Clone)]
pub(crate) struct LuaInventory {
    inner: Rc<RefCell<Inventory>>,
    callbacks: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}

impl LuaInventory {
    fn wrap(inv: Inventory) -> Self {
        Self {
            inner: Rc::new(RefCell::new(inv)),
            callbacks: Rc::new(RefCell::new(HashMap::new())),
        }
    }
}

impl LunaType for LuaInventory {
    const TYPE_NAME: &'static str = "Inventory";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaInventory {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // ── Containers ───────────────────────────────────────────────────

        methods.add_method(
            "addContainer",
            |_, this, (name, container_ud): (String, LuaAnyUserData)| {
                let c = container_ud.borrow::<LuaContainer>()?;
                this.inner
                    .borrow_mut()
                    .add_container(&name, c.0.borrow().clone());
                Ok(())
            },
        );

        /// Returns the container.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current container.
        methods.add_method("getContainer", |_, this, name: String| {
            let inv = this.inner.borrow();
            match inv.get_container(&name) {
                Some(c) => Ok(Some(LuaContainer(Rc::new(RefCell::new(c.clone()))))),
                None => Ok(None),
            }
        });

        /// Removes container from the collection.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("removeContainer", |_, this, name: String| {
            Ok(this.inner.borrow_mut().remove_container(&name))
        });

        /// Returns the container names.
        /// @return table
        ///
        /// # Returns
        /// The current container names.
        methods.add_method("getContainerNames", |lua, this, ()| {
            let inv = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, n) in inv.container_names().iter().enumerate() {
                tbl.set(i + 1, n.clone())?;
            }
            Ok(tbl)
        });

        // ── Equipment slots ───────────────────────────────────────────────

        methods.add_method(
            "addEquipSlot",
            |_, this, (name, slot_ud): (String, LuaAnyUserData)| {
                let slot = slot_ud.borrow::<LuaSlot>()?;
                this.inner
                    .borrow_mut()
                    .add_equip_slot(&name, slot.0.borrow().clone());
                Ok(())
            },
        );

        /// Returns the equip slot.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current equip slot.
        methods.add_method("getEquipSlot", |_, this, name: String| {
            let inv = this.inner.borrow();
            match inv.get_equip_slot(&name) {
                Some(s) => Ok(Some(LuaSlot(Rc::new(RefCell::new(s.clone()))))),
                None => Ok(None),
            }
        });

        /// Removes equip slot from the collection.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("removeEquipSlot", |_, this, name: String| {
            Ok(this.inner.borrow_mut().remove_equip_slot(&name))
        });

        /// Returns the equip slot names.
        /// @return table
        ///
        /// # Returns
        /// The current equip slot names.
        methods.add_method("getEquipSlotNames", |lua, this, ()| {
            let inv = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, n) in inv.equip_slot_names().iter().enumerate() {
                tbl.set(i + 1, n.clone())?;
            }
            Ok(tbl)
        });

        methods.add_method(
            "equip",
            |_, this, (slot_name, stack_ud): (String, LuaAnyUserData)| {
                let stack = stack_ud.borrow::<LuaItemStack>()?;
                let stack_clone = stack.0.borrow().clone();
                Ok(this.inner.borrow_mut().equip(&slot_name, stack_clone))
            },
        );

        /// Unequip on this Inventory.
        /// @param slot_name : string
        /// @return any
        ///
        /// # Parameters
        /// - `slot_name` — `string`.
        methods.add_method("unequip", |_, this, slot_name: String| {
            let item = this.inner.borrow_mut().unequip(&slot_name);
            match item {
                Some(it) => Ok(Some(LuaItem::wrap(it))),
                None => Ok(None),
            }
        });

        /// Returns the equipped.
        /// @param slot_name : string
        /// @return any
        ///
        /// # Parameters
        /// - `slot_name` — `string`.
        ///
        /// # Returns
        /// The current equipped.
        methods.add_method("getEquipped", |_, this, slot_name: String| {
            let inv = this.inner.borrow();
            match inv.get_equip_slot(&slot_name) {
                Some(s) => match s.get_item() {
                    Some(it) => Ok(Some(LuaItem::wrap(it.clone()))),
                    None => Ok(None),
                },
                None => Ok(None),
            }
        });

        // ── Item sets ─────────────────────────────────────────────────────

        /// Adds item set to the collection.
        /// @param set_ud : ItemSet
        ///
        /// # Parameters
        /// - `set_ud` — `userdata`.
        methods.add_method("addItemSet", |_, this, set_ud: LuaAnyUserData| {
            let set = set_ud.borrow::<LuaItemSet>()?;
            this.inner
                .borrow_mut()
                .add_item_set(set.inner.borrow().clone());
            Ok(())
        });

        /// Returns the active sets.
        /// @return table
        ///
        /// # Returns
        /// The current active sets.
        methods.add_method("getActiveSets", |lua, this, ()| {
            let inv = this.inner.borrow();
            let active = inv.get_active_sets();
            let tbl = lua.create_table()?;
            for (i, s) in active.iter().enumerate() {
                tbl.set(i + 1, s.name.clone())?;
            }
            Ok(tbl)
        });

        /// Returns the item set names.
        /// @return table
        ///
        /// # Returns
        /// The current item set names.
        methods.add_method("getItemSetNames", |lua, this, ()| {
            let inv = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, s) in inv.item_sets.iter().enumerate() {
                tbl.set(i + 1, s.name.clone())?;
            }
            Ok(tbl)
        });

        // ── Subsystems ────────────────────────────────────────────────────

        /// Returns `true` if at least one unit of `id` is in this inventory.
        ///
        /// # Parameters
        /// - `id` — `string`: Item identifier to test.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method(
            "hasItem",
            |_, this, (item_type, qty): (String, Option<u32>)| {
                Ok(this.inner.borrow().has_item(&item_type, qty.unwrap_or(1)))
            },
        );
        /// Returns the number of item.
        /// @param item_type : string
        /// @return any
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        /// - `qty` — `integer`.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("countItem", |_, this, item_type: String| {
            Ok(this.inner.borrow().count_item(&item_type))
        });
        /// Removes from any from the collection.
        ///
        /// # Parameters
        /// - `item_type` — `string`.
        /// - `qty` — `integer`.
        methods.add_method(
            "removeFromAny",
            |_, this, (item_type, qty): (String, u32)| {
                Ok(this.inner.borrow_mut().remove_from_any(&item_type, qty))
            },
        );
        /// Enable subsystem on this Inventory.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("enableSubsystem", |_, this, name: String| {
            this.inner.borrow_mut().enable_subsystem(&name);
            Ok(())
        });

        /// Disable subsystem on this Inventory.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("disableSubsystem", |_, this, name: String| {
            this.inner.borrow_mut().disable_subsystem(&name);
            Ok(())
        });

        /// Returns `true` if subsystem enabled.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isSubsystemEnabled", |_, this, name: String| {
            Ok(this.inner.borrow().is_subsystem_enabled(&name))
        });

        // ── Transfer / Swap ───────────────────────────────────────────────

        methods.add_method(
            "transfer",
            |_, this, (from_c, from_s, to_c, to_s): (String, usize, String, usize)| {
                if from_s < 1 || to_s < 1 {
                    return Err(LuaError::RuntimeError(
                        "luna.inventory: slot indices must be >= 1".into(),
                    ));
                }
                Ok(this
                    .inner
                    .borrow_mut()
                    .transfer(&from_c, from_s - 1, &to_c, to_s - 1))
            },
        );

        methods.add_method(
            "swap",
            |_, this, (ca, sa, cb, sb): (String, usize, String, usize)| {
                if sa < 1 || sb < 1 {
                    return Err(LuaError::RuntimeError(
                        "luna.inventory: slot indices must be >= 1".into(),
                    ));
                }
                Ok(this.inner.borrow_mut().swap(&ca, sa - 1, &cb, sb - 1))
            },
        );

        /// Split items off a stack at the given slot into the next empty slot.
        ///
        /// # Parameters
        /// - `container` — `string`: container name.
        /// - `slotIdx` — `integer`: 1-based slot index.
        /// - `quantity` — `integer`: number of items to split off.
        ///
        /// # Returns
        /// `boolean` — `true` if split succeeded.
        methods.add_method(
            "splitStack",
            |_, this, (container, slot_idx, quantity): (String, usize, u32)| {
                if slot_idx < 1 {
                    return Err(LuaError::RuntimeError(
                        "luna.inventory: slot index must be >= 1".into(),
                    ));
                }
                Ok(this
                    .inner
                    .borrow_mut()
                    .split_stack(&container, slot_idx - 1, quantity))
            },
        );

        /// Merge the stack at fromSlot into toSlot within the same container.
        ///
        /// # Parameters
        /// - `container` — `string`: container name.
        /// - `fromSlot` — `integer`: 1-based source slot index.
        /// - `toSlot` — `integer`: 1-based destination slot index.
        ///
        /// # Returns
        /// `boolean` — `true` if any items were merged.
        methods.add_method(
            "mergeStacks",
            |_, this, (container, from_slot, to_slot): (String, usize, usize)| {
                if from_slot < 1 || to_slot < 1 {
                    return Err(LuaError::RuntimeError(
                        "luna.inventory: slot indices must be >= 1".into(),
                    ));
                }
                Ok(this
                    .inner
                    .borrow_mut()
                    .merge_stacks(&container, from_slot - 1, to_slot - 1))
            },
        );

        /// Returns all registered item sets as ItemSet objects.
        /// @return any
        ///
        /// # Returns
        /// `table` of `ItemSet` userdata objects.
        methods.add_method("getItemSets", |_, this, ()| {
            let inv = this.inner.borrow();
            let mut result = Vec::new();
            for s in &inv.item_sets {
                result.push(LuaItemSet::wrap(s.clone()));
            }
            Ok(result)
        });

        // ── Callbacks ─────────────────────────────────────────────────────

        /// Register a callback for an inventory event. Replaces any existing.
        ///
        /// # Parameters
        /// - `event` — `string`: event name (e.g. `"on_equip"`, `"on_add"`).
        /// - `func` — `function`: the callback function.
        methods.add_method(
            "setCallback",
            |lua, this, (event, func): (String, LuaFunction)| {
                let key = lua.create_registry_value(func)?;
                this.callbacks.borrow_mut().insert(event, key);
                Ok(())
            },
        );

        /// Remove the callback for an inventory event.
        /// @param event : string
        ///
        /// # Parameters
        /// - `event` — `string`: event name.
        methods.add_method("removeCallback", |_, this, event: String| {
            this.callbacks.borrow_mut().remove(&event);
            Ok(())
        });

        /// Fire a callback. Passes all extra arguments to the callback function.
        ///
        /// # Parameters
        /// - `event` — `string`: event name.
        /// - `...` — variadic arguments forwarded to the callback.
        ///
        /// # Returns
        /// The callback's return value(s), or nil if no callback registered.
        methods.add_method(
            "fireCallback",
            |lua, this, (event, args): (String, LuaMultiValue)| {
                let cbs = this.callbacks.borrow();
                match cbs.get(&event) {
                    Some(key) => {
                        let func: LuaFunction = lua.registry_value(key)?;
                        func.call::<LuaMultiValue, LuaMultiValue>(args)
                    }
                    None => Ok(LuaMultiValue::new()),
                }
            },
        );
    }
}

// ────────────────────────────────────────────────────────────────────────────
// register
// ────────────────────────────────────────────────────────────────────────────

/// Register the `luna.inventory` module. Panics in debug mode if the same entity is registered twice.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    // ── Factory functions ─────────────────────────────────────────────────

    /// New item.
    ///
    /// @param item_type : string?
    /// @return any
    module.set(
        "newItem",
        lua.create_function(|_, item_type: Option<String>| {
            let t = item_type.unwrap_or_else(|| "item".into());
            Ok(LuaItem::wrap(InventoryEntry::new(t)))
        })?,
    )?;

    /// New item stack.
    ///
    /// @param item_ud : Item
    /// @param qty : integer?
    /// @param max_qty : integer?
    /// @return any
    module.set(
        "newItemStack",
        lua.create_function(
            |_, (item_ud, qty, max_qty): (LuaAnyUserData, Option<u32>, Option<u32>)| {
                let item = item_ud.borrow::<LuaItem>()?;
                let (item_clone, stack_limit) = {
                    let b = item.inner.borrow();
                    (b.clone(), b.stack_limit)
                };
                let quantity = qty.unwrap_or(1);
                let max_quantity = max_qty.unwrap_or(stack_limit);
                Ok(LuaItemStack(Rc::new(RefCell::new(ItemStack::new(
                    item_clone,
                    quantity,
                    max_quantity,
                )))))
            },
        )?,
    )?;

    /// New slot.
    ///
    /// @param slot_type : string?
    /// @param state : string?
    /// @return any
    module.set(
        "newSlot",
        lua.create_function(|_, (slot_type, state): (Option<String>, Option<String>)| {
            let t = slot_type.unwrap_or_else(|| "any".into());
            let s = state
                .as_deref()
                .and_then(SlotState::from_str)
                .unwrap_or(SlotState::Active);
            Ok(LuaSlot(Rc::new(RefCell::new(Slot::new(t, s)))))
        })?,
    )?;

    /// New container.
    ///
    /// @param name : string
    /// @param mode_str : string?
    /// @param slot_count : integer?
    /// @return any
    module.set(
        "newContainer",
        lua.create_function(
            |_, (name, mode_str, slot_count): (String, Option<String>, Option<u32>)| {
                let mode = mode_str
                    .as_deref()
                    .and_then(ContainerMode::from_str)
                    .unwrap_or(ContainerMode::Fixed);
                let count = slot_count.unwrap_or(10);
                Ok(LuaContainer(Rc::new(RefCell::new(Container::new(
                    name, mode, count,
                )))))
            },
        )?,
    )?;

    /// New inventory.
    ///
    module.set(
        "newInventory",
        lua.create_function(|_, ()| Ok(LuaInventory::wrap(Inventory::new())))?,
    )?;

    /// New item set.
    ///
    /// @param name : string
    module.set(
        "newItemSet",
        lua.create_function(|_, name: String| Ok(LuaItemSet::wrap(ItemSet::new(name))))?,
    )?;

    /// Inventory on this Inventory.
    ///
    /// # Returns
    /// The result.
    luna.set("inventory", module)?;
    Ok(())
}
