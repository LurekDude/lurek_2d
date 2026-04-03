//! Lua API bindings for the `luna.economy.*` named resource economy module.
//!
//! Provides `ResourceManager` UserData for managing named resources with
//! capacity, flow rates, decay, interest, conversions, and overflow policies.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::economy::{ConversionRule, OverflowPolicy, ResourceManager};

// ---------------------------------------------------------------------------
// LuaResourceManager
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for a resource economy manager.
///
/// # Fields
/// - `inner` — `Rc<RefCell<ResourceManager>>`.
#[derive(Clone)]
pub(crate) struct LuaResourceManager {
    inner: Rc<RefCell<ResourceManager>>,
}

impl LunaType for LuaResourceManager {
    const TYPE_NAME: &'static str = "ResourceManager";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaResourceManager {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods::<Self>(methods);

        // ── Resource CRUD ──

        /// Creates a new resource instance.
        /// @param name : string
        /// @param capacity : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `capacity` — `number`.
        methods.add_method("newResource", |_, this, (name, capacity): (String, f64)| {
            this.inner.borrow_mut().new_resource(&name, capacity);
            Ok(())
        });

        /// Returns `true` if resource.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasResource", |_, this, name: String| {
            Ok(this.inner.borrow().has_resource(&name))
        });

        /// Removes resource from the collection.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("removeResource", |_, this, name: String| {
            this.inner.borrow_mut().remove_resource(&name);
            Ok(())
        });

        /// Returns the resource names.
        /// @return table
        ///
        /// # Returns
        /// The current resource names.
        methods.add_method("getResourceNames", |lua, this, ()| {
            let mgr = this.inner.borrow();
            let names = mgr.resource_names();
            let tbl = lua.create_table()?;
            for (i, n) in names.iter().enumerate() {
                tbl.set(i + 1, n.to_string())?;
            }
            Ok(tbl)
        });

        // ── Resource value get/set ──

        /// Returns the value.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current value.
        methods.add_method("getValue", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.value()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the value.
        /// @param name : string
        /// @param value : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `value` — `number`.
        methods.add_method("setValue", |_, this, (name, value): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_value(value);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the capacity.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current capacity.
        methods.add_method("getCapacity", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.capacity()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the capacity.
        /// @param name : string
        /// @param cap : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `cap` — `number`.
        methods.add_method("setCapacity", |_, this, (name, cap): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_capacity(cap);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the minimum.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current minimum.
        methods.add_method("getMinimum", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.minimum()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the minimum.
        /// @param name : string
        /// @param min : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `min` — `number`.
        methods.add_method("setMinimum", |_, this, (name, min): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_minimum(min);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        // ── Flow and rate accessors ──

        /// Returns the flow rate.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current flow rate.
        methods.add_method("getFlowRate", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.flow_rate()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the flow rate.
        /// @param name : string
        /// @param rate : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `rate` — `number`.
        methods.add_method("setFlowRate", |_, this, (name, rate): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_flow_rate(rate);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the decay rate.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current decay rate.
        methods.add_method("getDecayRate", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.decay_rate()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the decay rate.
        /// @param name : string
        /// @param rate : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `rate` — `number`.
        methods.add_method("setDecayRate", |_, this, (name, rate): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_decay_rate(rate);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the decay percent.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current decay percent.
        methods.add_method("getDecayPercent", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.decay_percent()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the decay percent.
        /// @param name : string
        /// @param pct : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `pct` — `number`.
        methods.add_method("setDecayPercent", |_, this, (name, pct): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_decay_percent(pct);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the interest rate.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current interest rate.
        methods.add_method("getInterestRate", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.interest_rate()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the interest rate.
        /// @param name : string
        /// @param rate : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `rate` — `number`.
        methods.add_method("setInterestRate", |_, this, (name, rate): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_interest_rate(rate);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the upkeep.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current upkeep.
        methods.add_method("getUpkeep", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.upkeep()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the upkeep.
        /// @param name : string
        /// @param upkeep : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `upkeep` — `number`.
        methods.add_method("setUpkeep", |_, this, (name, upkeep): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_upkeep(upkeep);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the net rate.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current net rate.
        methods.add_method("getNetRate", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.net_rate()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        // ── Overflow policy ──

        /// Returns the overflow.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current overflow.
        methods.add_method("getOverflow", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.overflow().as_str().to_string()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        methods.add_method(
            "setOverflow",
            |_, this, (name, policy): (String, String)| {
                let mut mgr = this.inner.borrow_mut();
                match mgr.get_resource_mut(&name) {
                    Some(r) => {
                        r.set_overflow(OverflowPolicy::from_str(&policy));
                        Ok(())
                    }
                    None => Err(LuaError::RuntimeError(format!(
                        "luna.resource: no resource '{name}'"
                    ))),
                }
            },
        );

        // ── Group ──

        /// Returns the group.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current group.
        methods.add_method("getGroup", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.group().to_string()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the group.
        /// @param name : string
        /// @param group : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `group` — `string`.
        methods.add_method("setGroup", |_, this, (name, group): (String, String)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_group(&group);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        // ── Flags ──

        /// Returns `true` if enabled.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEnabled", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.is_enabled()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the enabled.
        /// @param name : string
        /// @param v : boolean
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `v` — `boolean`.
        methods.add_method("setEnabled", |_, this, (name, v): (String, bool)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_enabled(v);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns `true` if visible.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isVisible", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.is_visible()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the visible.
        /// @param name : string
        /// @param v : boolean
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `v` — `boolean`.
        methods.add_method("setVisible", |_, this, (name, v): (String, bool)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_visible(v);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns `true` if locked.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isLocked", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.is_locked()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Sets the locked.
        /// @param name : string
        /// @param v : boolean
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `v` — `boolean`.
        methods.add_method("setLocked", |_, this, (name, v): (String, bool)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.set_locked(v);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        // ── Operations ──

        /// Adds an entry to the collection.
        /// @param name : string
        /// @param amount : number
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `amount` — `number`.
        methods.add_method("add", |_, this, (name, amount): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => Ok(r.add(amount)),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Spend on this ResourceManager.
        /// @param name : string
        /// @param amount : number
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `amount` — `number`.
        methods.add_method("spend", |_, this, (name, amount): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => Ok(r.spend(amount)),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns `true` if afford.
        /// @param name : string
        /// @param amount : number
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `amount` — `number`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canAfford", |_, this, (name, amount): (String, f64)| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.can_afford(amount)),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the available.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current available.
        methods.add_method("getAvailable", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.available()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Reserve on this ResourceManager.
        /// @param name : string
        /// @param amount : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `amount` — `number`.
        methods.add_method("reserve", |_, this, (name, amount): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.reserve(amount);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Unreserve on this ResourceManager.
        /// @param name : string
        /// @param amount : number
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `amount` — `number`.
        methods.add_method("unreserve", |_, this, (name, amount): (String, f64)| {
            let mut mgr = this.inner.borrow_mut();
            match mgr.get_resource_mut(&name) {
                Some(r) => {
                    r.unreserve(amount);
                    Ok(())
                }
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        /// Returns the reserved.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current reserved.
        methods.add_method("getReserved", |_, this, name: String| {
            let mgr = this.inner.borrow();
            match mgr.get_resource(&name) {
                Some(r) => Ok(r.reserved()),
                None => Err(LuaError::RuntimeError(format!(
                    "luna.resource: no resource '{name}'"
                ))),
            }
        });

        // ── Tick / Turn ──

        /// Advances internal state by one logic tick.
        /// @param dt : number
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("tick", |_, this, dt: f64| {
            this.inner.borrow_mut().tick(dt);
            Ok(())
        });

        /// Turn on this ResourceManager.
        ///
        /// # Returns
        /// The result.
        methods.add_method("turn", |_, this, ()| {
            this.inner.borrow_mut().turn();
            Ok(())
        });

        // ── Conversions ──

        methods.add_method(
            "addConversionRule",
            |_, this, (from, to, rate): (String, String, f64)| {
                this.inner
                    .borrow_mut()
                    .add_conversion_rule(ConversionRule::new(&from, &to, rate));
                Ok(())
            },
        );

        methods.add_method(
            "convert",
            |_, this, (from, to, amount): (String, String, f64)| {
                Ok(this.inner.borrow_mut().convert(&from, &to, amount))
            },
        );

        // ── Group queries ──

        /// Total by group on this ResourceManager.
        /// @param group : string
        /// @return any
        ///
        /// # Parameters
        /// - `group` — `string`.
        methods.add_method("totalByGroup", |_, this, group: String| {
            Ok(this.inner.borrow().total_by_group(&group))
        });

        // ── Reset ──

        /// Returns the percent.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current percent.
        methods.add_method("getPercent", |_, this, name: String| {
            Ok(this.inner.borrow().percent(&name))
        });
        /// Returns `true` if full.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isFull", |_, this, name: String| {
            Ok(this.inner.borrow().is_full(&name))
        });
        /// Returns `true` if empty.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isEmpty", |_, this, name: String| {
            Ok(this.inner.borrow().is_empty(&name))
        });
        /// Returns `true` if afford all.
        /// @param tbl : table
        /// @return any
        ///
        /// # Parameters
        /// - `tbl` — `table`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canAffordAll", |_, this, tbl: LuaTable| {
            let mut needs: Vec<(String, f64)> = Vec::new();
            for pair in tbl.pairs::<String, f64>() {
                let (k, v) = pair.map_err(LuaError::external)?;
                needs.push((k, v));
            }
            let refs: Vec<(&str, f64)> = needs.iter().map(|(k, v)| (k.as_str(), *v)).collect();
            Ok(this.inner.borrow().can_afford_all(&refs))
        });
        /// Spend all on this ResourceManager.
        /// @param tbl : table
        /// @return any
        ///
        /// # Parameters
        /// - `tbl` — `table`.
        methods.add_method("spendAll", |_, this, tbl: LuaTable| {
            let mut needs: Vec<(String, f64)> = Vec::new();
            for pair in tbl.pairs::<String, f64>() {
                let (k, v) = pair.map_err(LuaError::external)?;
                needs.push((k, v));
            }
            let refs: Vec<(&str, f64)> = needs.iter().map(|(k, v)| (k.as_str(), *v)).collect();
            Ok(this.inner.borrow_mut().spend_all(&refs))
        });
        /// Resets state to initial values.
        ///
        /// # Returns
        /// The result.
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.resource` module with the Lua VM.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    /// New manager.
    ///
    /// @return any
    module.set(
        "newManager",
        lua.create_function(|_, ()| {
            Ok(LuaResourceManager {
                inner: Rc::new(RefCell::new(ResourceManager::new())),
            })
        })?,
    )?;

    /// Resource on this ResourceManager.
    ///
    /// # Returns
    /// The result.
    luna.set("resource", module)?;
    Ok(())
}
