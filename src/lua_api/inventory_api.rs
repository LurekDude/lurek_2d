//! Lua API bindings for the `luna.inventory.*` slot-based inventory module.
//!
//! Provides `Item`, `ItemStack`, `Slot`, `Container`, `ItemSet`, and `Inventory`
//! UserData objects for building RPG-style inventory systems in Lua.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::inventory::{
    Container, ContainerMode, Inventory, Item, ItemSet, ItemStack, SetRequirement, Slot, SlotState,
    SubsystemFlags,
};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ────────────────────────────────────────────────────────────────────────────
// LuaItem
// ────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for a single item definition.
#[derive(Clone)]
pub(crate) struct LuaItem(Rc<RefCell<Item>>);

impl LunaType for LuaItem {
    const TYPE_NAME: &'static str = "Item";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaItem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method("getType", |_, this, ()| {
            Ok(this.0.borrow().item_type.clone())
        });

        methods.add_method("setType", |_, this, t: String| {
            this.0.borrow_mut().item_type = t;
            Ok(())
        });

        methods.add_method("getWeight", |_, this, ()| Ok(this.0.borrow().weight));

        methods.add_method("setWeight", |_, this, w: f64| {
            this.0.borrow_mut().weight = w;
            Ok(())
        });

        methods.add_method("getSize", |_, this, ()| {
            let it = this.0.borrow();
            Ok((it.size_w, it.size_h))
        });

        methods.add_method("setSize", |_, this, (w, h): (u32, u32)| {
            let mut it = this.0.borrow_mut();
            it.size_w = w;
            it.size_h = h;
            Ok(())
        });

        methods.add_method("getStackLimit", |_, this, ()| {
            Ok(this.0.borrow().stack_limit)
        });

        methods.add_method("setStackLimit", |_, this, n: u32| {
            this.0.borrow_mut().stack_limit = n.max(1);
            Ok(())
        });

        methods.add_method("addTag", |_, this, tag: String| {
            this.0.borrow_mut().add_tag(tag);
            Ok(())
        });

        methods.add_method("removeTag", |_, this, tag: String| {
            Ok(this.0.borrow_mut().remove_tag(&tag))
        });

        methods.add_method("hasTag", |_, this, tag: String| {
            Ok(this.0.borrow().has_tag(&tag))
        });

        methods.add_method("getTags", |lua, this, ()| {
            let it = this.0.borrow();
            let tbl = lua.create_table()?;
            for (i, tag) in it.tags.iter().enumerate() {
                tbl.set(i + 1, tag.clone())?;
            }
            Ok(tbl)
        });

        methods.add_method("clone", |_, this, ()| {
            Ok(LuaItem(Rc::new(RefCell::new(this.0.borrow().clone()))))
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

        methods.add_method("getItem", |_, this, ()| {
            let stack = this.0.borrow();
            Ok(LuaItem(Rc::new(RefCell::new(stack.item.clone()))))
        });

        methods.add_method("getQuantity", |_, this, ()| {
            Ok(this.0.borrow().quantity)
        });

        methods.add_method("setQuantity", |_, this, n: u32| {
            let mut s = this.0.borrow_mut();
            s.quantity = n.min(s.max_quantity);
            Ok(())
        });

        methods.add_method("getMaxQuantity", |_, this, ()| {
            Ok(this.0.borrow().max_quantity)
        });

        methods.add_method("isFull", |_, this, ()| {
            Ok(this.0.borrow().is_full())
        });

        methods.add_method("add", |_, this, n: u32| {
            Ok(this.0.borrow_mut().add(n))
        });

        methods.add_method("remove", |_, this, n: u32| {
            Ok(this.0.borrow_mut().remove(n))
        });

        methods.add_method("split", |_, this, n: u32| {
            let split = this.0.borrow_mut().split(n);
            match split {
                Some(s) => Ok(Some(LuaItemStack(Rc::new(RefCell::new(s))))),
                None => Ok(None),
            }
        });

        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_stack = other.borrow::<LuaItemStack>()?;
            let leftover = this.0.borrow_mut().merge(&mut other_stack.0.borrow_mut());
            Ok(leftover)
        });

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

        methods.add_method("getType", |_, this, ()| {
            Ok(this.0.borrow().slot_type.clone())
        });

        methods.add_method("setType", |_, this, t: String| {
            this.0.borrow_mut().slot_type = t;
            Ok(())
        });

        methods.add_method("getState", |_, this, ()| {
            Ok(this.0.borrow().state.as_str().to_string())
        });

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

        methods.add_method("isEmpty", |_, this, ()| {
            Ok(this.0.borrow().is_empty())
        });

        methods.add_method("getStack", |_, this, ()| {
            let slot = this.0.borrow();
            match &slot.stack {
                Some(s) => Ok(Some(LuaItemStack(Rc::new(RefCell::new(s.clone()))))),
                None => Ok(None),
            }
        });

        methods.add_method("setStack", |_, this, stack_ud: LuaAnyUserData| {
            let stack = stack_ud.borrow::<LuaItemStack>()?;
            let placed = this.0.borrow_mut().set_stack(stack.0.borrow().clone());
            Ok(placed)
        });

        methods.add_method("clear", |_, this, ()| {
            this.0.borrow_mut().clear();
            Ok(())
        });

        methods.add_method("canAccept", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaItem>()?;
            let item_ref = item.0.borrow();
            Ok(this.0.borrow().can_accept(&*item_ref))
        });

        methods.add_method("getCapacity", |_, this, ()| {
            let s = this.0.borrow();
            Ok((s.capacity_w, s.capacity_h))
        });

        methods.add_method("setCapacity", |_, this, (w, h): (u32, u32)| {
            let mut s = this.0.borrow_mut();
            s.capacity_w = w;
            s.capacity_h = h;
            Ok(())
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

        methods.add_method("getName", |_, this, ()| {
            Ok(this.0.borrow().name.clone())
        });

        methods.add_method("getMode", |_, this, ()| {
            Ok(this.0.borrow().mode.as_str().to_string())
        });

        methods.add_method("getSlotCount", |_, this, ()| {
            Ok(this.0.borrow().slot_count())
        });

        methods.add_method("getMaxSlots", |_, this, ()| {
            Ok(this.0.borrow().max_slots)
        });

        methods.add_method("setMaxSlots", |_, this, n: u32| {
            this.0.borrow_mut().max_slots = n;
            Ok(())
        });

        methods.add_method("getWeightLimit", |_, this, ()| {
            Ok(this.0.borrow().weight_limit)
        });

        methods.add_method("setWeightLimit", |_, this, w: f64| {
            this.0.borrow_mut().weight_limit = w;
            Ok(())
        });

        methods.add_method("getCurrentWeight", |_, this, ()| {
            Ok(this.0.borrow().current_weight())
        });

        /// Get a slot by 1-based index (Lua convention).
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

        methods.add_method("removeSlot", |_, this, index: usize| {
            if index < 1 {
                return Err(LuaError::RuntimeError(
                    "luna.inventory: slot index must be >= 1".into(),
                ));
            }
            this.0.borrow_mut().remove_slot(index - 1);
            Ok(())
        });

        methods.add_method("expand", |_, this, n: u32| {
            Ok(this.0.borrow_mut().expand(n))
        });

        methods.add_method("addItem", |_, this, (item_ud, qty): (LuaAnyUserData, Option<u32>)| {
            let item = item_ud.borrow::<LuaItem>()?;
            let item_clone = item.0.borrow().clone();
            let quantity = qty.unwrap_or(1);
            Ok(this.0.borrow_mut().add_item(item_clone, quantity))
        });

        methods.add_method("hasItem", |_, this, (item_type, qty): (String, Option<u32>)| {
            Ok(this.0.borrow().has_item(&item_type, qty.unwrap_or(1)))
        });
        methods.add_method("countItem", |_, this, item_type: String| {
            Ok(this.0.borrow().count_item(&item_type))
        });
        methods.add_method("removeItem", |_, this, (item_type, qty): (String, u32)| {
            Ok(this.0.borrow_mut().remove_item(&item_type, qty))
        });
        methods.add_method("toList", |lua, this, ()| {
            let items = this.0.borrow().to_item_list();
            let t = lua.create_table()?;
            for (i, (item_type, qty)) in items.into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("itemType", item_type)?;
                entry.set("quantity", qty)?;
                t.set(i + 1, entry)?;
            }
            Ok(t)
        });
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
#[derive(Clone)]
pub(crate) struct LuaItemSet(Rc<RefCell<ItemSet>>);

impl LunaType for LuaItemSet {
    const TYPE_NAME: &'static str = "ItemSet";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaItemSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        methods.add_method("getName", |_, this, ()| {
            Ok(this.0.borrow().name.clone())
        });

        methods.add_method(
            "addRequirement",
            |_, this, (tag, slot_filter): (String, Option<String>)| {
                let filter = slot_filter.unwrap_or_default();
                this.0.borrow_mut().add_requirement(tag, filter);
                Ok(())
            },
        );

        methods.add_method("getRequirements", |lua, this, ()| {
            let set = this.0.borrow();
            let tbl = lua.create_table()?;
            for (i, req) in set.requirements.iter().enumerate() {
                let r = lua.create_table()?;
                r.set("tag", req.tag.clone())?;
                r.set("slotFilter", req.slot_filter.clone())?;
                tbl.set(i + 1, r)?;
            }
            Ok(tbl)
        });
    }
}

// ────────────────────────────────────────────────────────────────────────────
// LuaInventory
// ────────────────────────────────────────────────────────────────────────────

/// Lua UserData wrapper for the top-level inventory.
#[derive(Clone)]
pub(crate) struct LuaInventory(Rc<RefCell<Inventory>>);

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
                this.0
                    .borrow_mut()
                    .add_container(&name, c.0.borrow().clone());
                Ok(())
            },
        );

        methods.add_method("getContainer", |_, this, name: String| {
            let inv = this.0.borrow();
            match inv.get_container(&name) {
                Some(c) => Ok(Some(LuaContainer(Rc::new(RefCell::new(c.clone()))))),
                None => Ok(None),
            }
        });

        methods.add_method("removeContainer", |_, this, name: String| {
            Ok(this.0.borrow_mut().remove_container(&name))
        });

        methods.add_method("getContainerNames", |lua, this, ()| {
            let inv = this.0.borrow();
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
                this.0
                    .borrow_mut()
                    .add_equip_slot(&name, slot.0.borrow().clone());
                Ok(())
            },
        );

        methods.add_method("getEquipSlot", |_, this, name: String| {
            let inv = this.0.borrow();
            match inv.get_equip_slot(&name) {
                Some(s) => Ok(Some(LuaSlot(Rc::new(RefCell::new(s.clone()))))),
                None => Ok(None),
            }
        });

        methods.add_method("removeEquipSlot", |_, this, name: String| {
            Ok(this.0.borrow_mut().remove_equip_slot(&name))
        });

        methods.add_method("getEquipSlotNames", |lua, this, ()| {
            let inv = this.0.borrow();
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
                Ok(this.0.borrow_mut().equip(&slot_name, stack_clone))
            },
        );

        methods.add_method("unequip", |_, this, slot_name: String| {
            let item = this.0.borrow_mut().unequip(&slot_name);
            match item {
                Some(it) => Ok(Some(LuaItem(Rc::new(RefCell::new(it))))),
                None => Ok(None),
            }
        });

        methods.add_method("getEquipped", |_, this, slot_name: String| {
            let inv = this.0.borrow();
            match inv.get_equip_slot(&slot_name) {
                Some(s) => match s.get_item() {
                    Some(it) => Ok(Some(LuaItem(Rc::new(RefCell::new(it.clone()))))),
                    None => Ok(None),
                },
                None => Ok(None),
            }
        });

        // ── Item sets ─────────────────────────────────────────────────────

        methods.add_method("addItemSet", |_, this, set_ud: LuaAnyUserData| {
            let set = set_ud.borrow::<LuaItemSet>()?;
            this.0.borrow_mut().add_item_set(set.0.borrow().clone());
            Ok(())
        });

        methods.add_method("getActiveSets", |lua, this, ()| {
            let inv = this.0.borrow();
            let active = inv.get_active_sets();
            let tbl = lua.create_table()?;
            for (i, s) in active.iter().enumerate() {
                tbl.set(i + 1, s.name.clone())?;
            }
            Ok(tbl)
        });

        methods.add_method("getItemSetNames", |lua, this, ()| {
            let inv = this.0.borrow();
            let tbl = lua.create_table()?;
            for (i, s) in inv.item_sets.iter().enumerate() {
                tbl.set(i + 1, s.name.clone())?;
            }
            Ok(tbl)
        });

        // ── Subsystems ────────────────────────────────────────────────────

        methods.add_method("hasItem", |_, this, (item_type, qty): (String, Option<u32>)| {
            Ok(this.0.borrow().has_item(&item_type, qty.unwrap_or(1)))
        });
        methods.add_method("countItem", |_, this, item_type: String| {
            Ok(this.0.borrow().count_item(&item_type))
        });
        methods.add_method("removeFromAny", |_, this, (item_type, qty): (String, u32)| {
            Ok(this.0.borrow_mut().remove_from_any(&item_type, qty))
        });
        methods.add_method("enableSubsystem", |_, this, name: String| {
            this.0.borrow_mut().enable_subsystem(&name);
            Ok(())
        });

        methods.add_method("disableSubsystem", |_, this, name: String| {
            this.0.borrow_mut().disable_subsystem(&name);
            Ok(())
        });

        methods.add_method("isSubsystemEnabled", |_, this, name: String| {
            Ok(this.0.borrow().is_subsystem_enabled(&name))
        });

        // ── Transfer / Swap ───────────────────────────────────────────────

        methods.add_method(
            "transfer",
            |_,
             this,
             (from_c, from_s, to_c, to_s): (String, usize, String, usize)| {
                if from_s < 1 || to_s < 1 {
                    return Err(LuaError::RuntimeError(
                        "luna.inventory: slot indices must be >= 1".into(),
                    ));
                }
                Ok(this.0.borrow_mut().transfer(&from_c, from_s - 1, &to_c, to_s - 1))
            },
        );

        methods.add_method(
            "swap",
            |_,
             this,
             (ca, sa, cb, sb): (String, usize, String, usize)| {
                if sa < 1 || sb < 1 {
                    return Err(LuaError::RuntimeError(
                        "luna.inventory: slot indices must be >= 1".into(),
                    ));
                }
                Ok(this.0.borrow_mut().swap(&ca, sa - 1, &cb, sb - 1))
            },
        );
    }
}

// ────────────────────────────────────────────────────────────────────────────
// register
// ────────────────────────────────────────────────────────────────────────────

/// Register the `luna.inventory` module.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    // ── Factory functions ─────────────────────────────────────────────────

    module.set(
        "newItem",
        lua.create_function(|_, item_type: Option<String>| {
            let t = item_type.unwrap_or_else(|| "item".into());
            Ok(LuaItem(Rc::new(RefCell::new(Item::new(t)))))
        })?,
    )?;

    module.set(
        "newItemStack",
        lua.create_function(|_, (item_ud, qty, max_qty): (LuaAnyUserData, Option<u32>, Option<u32>)| {
            let item = item_ud.borrow::<LuaItem>()?;
            let (item_clone, stack_limit) = {
                let b = item.0.borrow();
                (b.clone(), b.stack_limit)
            };
            let quantity = qty.unwrap_or(1);
            let max_quantity = max_qty.unwrap_or(stack_limit);
            Ok(LuaItemStack(Rc::new(RefCell::new(ItemStack::new(
                item_clone,
                quantity,
                max_quantity,
            )))))
        })?,
    )?;;

    module.set(
        "newSlot",
        lua.create_function(|_, (slot_type, state): (Option<String>, Option<String>)| {
            let t = slot_type.unwrap_or_else(|| "any".into());
            let s = state.as_deref().and_then(SlotState::from_str).unwrap_or(SlotState::Active);
            Ok(LuaSlot(Rc::new(RefCell::new(Slot::new(t, s)))))
        })?,
    )?;

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

    module.set(
        "newInventory",
        lua.create_function(|_, ()| {
            Ok(LuaInventory(Rc::new(RefCell::new(Inventory::new()))))
        })?,
    )?;

    module.set(
        "newItemSet",
        lua.create_function(|_, name: String| {
            Ok(LuaItemSet(Rc::new(RefCell::new(ItemSet::new(name)))))
        })?,
    )?;

    luna.set("inventory", module)?;
    Ok(())
}
