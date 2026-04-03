//! Lua bindings for the `luna.battle.*` turn-based battle API.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for battle api-related operations and data management.
//! Key types exported from this module: `LuaStatusEffect`, `LuaCombatAction`, `LuaCombatant`, `LuaCombatBattle`.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::battle::{CombatAction, CombatBattle, Combatant, StatusEffect};
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::lua_api::SharedState;

/// Lua wrapper for [`StatusEffect`]. Consult the module-level documentation for the broader usage context and preconditions.
#[derive(Clone)]
pub struct LuaStatusEffect(pub Rc<RefCell<StatusEffect>>);

impl LunaType for LuaStatusEffect {
    const TYPE_NAME: &'static str = "StatusEffect";
    const TYPE_HIERARCHY: &'static [&'static str] = &["StatusEffect"];
}

impl LuaUserData for LuaStatusEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name.
        ///
        /// @return any
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the duration.
        ///
        /// @return any
        methods.add_method("getDuration", |_, this, ()| Ok(this.0.borrow().duration));
        /// Sets the duration.
        ///
        /// @param value : integer
        methods.add_method("setDuration", |_, this, value: i32| {
            this.0.borrow_mut().duration = value;
            Ok(())
        });
        /// Returns the stacks.
        ///
        /// @return any
        methods.add_method("getStacks", |_, this, ()| Ok(this.0.borrow().stacks));
        /// Sets the stacks.
        ///
        /// @param value : integer
        methods.add_method("setStacks", |_, this, value: u32| {
            this.0.borrow_mut().stacks = value;
            Ok(())
        });
        /// Returns true if expired.
        ///
        /// @return any
        methods.add_method("isExpired", |_, this, ()| Ok(this.0.borrow().is_expired()));
        /// Tick turn.
        ///
        /// @return any
        methods.add_method("tickTurn", |_, this, ()| Ok(this.0.borrow_mut().tick_turn()));
    }
}

/// Lua wrapper for [`CombatAction`]. Consult the module-level documentation for the broader usage context and preconditions.
#[derive(Clone)]
pub struct LuaCombatAction(pub Rc<RefCell<CombatAction>>);

impl LunaType for LuaCombatAction {
    const TYPE_NAME: &'static str = "CombatAction";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CombatAction"];
}

impl LuaUserData for LuaCombatAction {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name.
        ///
        /// @return any
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the base damage.
        ///
        /// @return any
        methods.add_method("getBaseDamage", |_, this, ()| Ok(this.0.borrow().base_damage));
        /// Sets the base damage.
        ///
        /// @param value : number
        methods.add_method("setBaseDamage", |_, this, value: f64| {
            this.0.borrow_mut().base_damage = value;
            Ok(())
        });
        /// Returns the damage type.
        ///
        /// @return any
        methods.add_method("getDamageType", |_, this, ()| Ok(this.0.borrow().damage_type.clone()));
        /// Sets the damage type.
        ///
        /// @param value : string
        methods.add_method("setDamageType", |_, this, value: String| {
            this.0.borrow_mut().damage_type = value;
            Ok(())
        });
        /// Returns the accuracy.
        ///
        /// @return any
        methods.add_method("getAccuracy", |_, this, ()| Ok(this.0.borrow().accuracy));
        /// Sets the accuracy.
        ///
        /// @param value : number
        methods.add_method("setAccuracy", |_, this, value: f64| {
            this.0.borrow_mut().accuracy = value.clamp(0.0, 1.0);
            Ok(())
        });
        /// Returns the cooldown.
        ///
        /// @return any
        methods.add_method("getCooldown", |_, this, ()| Ok(this.0.borrow().cooldown));
        /// Sets the cooldown.
        ///
        /// @param value : integer
        methods.add_method("setCooldown", |_, this, value: u32| {
            this.0.borrow_mut().cooldown = value;
            Ok(())
        });
        /// Returns the current cooldown.
        ///
        /// @return any
        methods.add_method("getCurrentCooldown", |_, this, ()| {
            Ok(this.0.borrow().current_cooldown)
        });
        /// Returns true if ready.
        ///
        /// @return any
        methods.add_method("isReady", |_, this, ()| Ok(this.0.borrow().is_ready()));
        /// Tick cooldown.
        ///
        methods.add_method("tickCooldown", |_, this, ()| {
            this.0.borrow_mut().tick_cooldown();
            Ok(())
        });
        /// Returns the cost mp.
        ///
        /// @return any
        methods.add_method("getCostMp", |_, this, ()| Ok(this.0.borrow().cost_mp));
        /// Sets the cost mp.
        ///
        /// @param value : number
        methods.add_method("setCostMp", |_, this, value: f64| {
            this.0.borrow_mut().cost_mp = value;
            Ok(())
        });
    }
}

/// Lua wrapper for [`Combatant`]. Consult the module-level documentation for the broader usage context and preconditions.
#[derive(Clone)]
pub struct LuaCombatant(pub Rc<RefCell<Combatant>>);

impl LunaType for LuaCombatant {
    const TYPE_NAME: &'static str = "Combatant";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Combatant"];
}

impl LuaUserData for LuaCombatant {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name.
        ///
        /// @return any
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the team.
        ///
        /// @return any
        methods.add_method("getTeam", |_, this, ()| Ok(this.0.borrow().team.clone()));
        /// Sets the team.
        ///
        /// @param value : string
        methods.add_method("setTeam", |_, this, value: String| {
            this.0.borrow_mut().team = value;
            Ok(())
        });
        /// Returns the hp.
        ///
        /// @return any
        methods.add_method("getHp", |_, this, ()| Ok(this.0.borrow().hp));
        /// Sets the hp.
        ///
        /// @param value : number
        methods.add_method("setHp", |_, this, value: f64| {
            this.0.borrow_mut().hp = value;
            Ok(())
        });
        /// Returns the max hp.
        ///
        /// @return any
        methods.add_method("getMaxHp", |_, this, ()| Ok(this.0.borrow().max_hp));
        /// Sets the max hp.
        ///
        /// @param value : number
        methods.add_method("setMaxHp", |_, this, value: f64| {
            this.0.borrow_mut().max_hp = value;
            Ok(())
        });
        /// Returns the mp.
        ///
        /// @return any
        methods.add_method("getMp", |_, this, ()| Ok(this.0.borrow().mp));
        /// Sets the mp.
        ///
        /// @param value : number
        methods.add_method("setMp", |_, this, value: f64| {
            this.0.borrow_mut().mp = value;
            Ok(())
        });
        /// Returns the max mp.
        ///
        /// @return any
        methods.add_method("getMaxMp", |_, this, ()| Ok(this.0.borrow().max_mp));
        /// Sets the max mp.
        ///
        /// @param value : number
        methods.add_method("setMaxMp", |_, this, value: f64| {
            this.0.borrow_mut().max_mp = value;
            Ok(())
        });
        /// Returns the speed.
        ///
        /// @return any
        methods.add_method("getSpeed", |_, this, ()| Ok(this.0.borrow().speed));
        /// Sets the speed.
        ///
        /// @param value : number
        methods.add_method("setSpeed", |_, this, value: f64| {
            this.0.borrow_mut().speed = value;
            Ok(())
        });
        /// Returns the level.
        ///
        /// @return any
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        /// Returns true if alive.
        ///
        /// @return any
        methods.add_method("isAlive", |_, this, ()| Ok(this.0.borrow().is_alive()));
        /// Take damage.
        ///
        /// @param amount : number
        /// @param dtype : string?
        /// @return any
        methods.add_method("takeDamage", |_, this, (amount, dtype): (f64, Option<String>)| {
            let dtype = dtype.unwrap_or_else(|| "physical".to_string());
            Ok(this.0.borrow_mut().take_damage(amount, &dtype))
        });
        /// Heal.
        ///
        /// @param amount : number
        /// @return any
        methods.add_method("heal", |_, this, amount: f64| Ok(this.0.borrow_mut().heal(amount)));
        /// Returns the stat.
        ///
        /// @param name : string
        /// @return any
        methods.add_method("getStat", |_, this, name: String| Ok(this.0.borrow().get_stat(&name)));
        /// Sets the stat.
        ///
        /// @param name : string
        /// @param value : number
        methods.add_method("setStat", |_, this, (name, value): (String, f64)| {
            this.0.borrow_mut().set_stat(name, value);
            Ok(())
        });
        /// Returns the resistance.
        ///
        /// @param dtype : string
        /// @return any
        methods.add_method("getResistance", |_, this, dtype: String| {
            Ok(*this.0.borrow().resistances.get(&dtype).unwrap_or(&1.0))
        });
        /// Sets the resistance.
        ///
        /// @param dtype : string
        /// @param value : number
        methods.add_method("setResistance", |_, this, (dtype, value): (String, f64)| {
            this.0.borrow_mut().resistances.insert(dtype, value);
            Ok(())
        });
        /// Adds status.
        ///
        /// @param name : string
        /// @param duration : integer?
        methods.add_method("addStatus", |_, this, (name, duration): (String, Option<i32>)| {
            let effect = StatusEffect::new(name, duration.unwrap_or(-1));
            this.0.borrow_mut().add_status(effect);
            Ok(())
        });
        /// Removes status.
        ///
        /// @param name : string
        methods.add_method("removeStatus", |_, this, name: String| {
            this.0.borrow_mut().remove_status(&name);
            Ok(())
        });
        /// Returns true if status.
        ///
        /// @param name : string
        /// @return any
        methods.add_method("hasStatus", |_, this, name: String| Ok(this.0.borrow().has_status(&name)));
        /// Tick statuses.
        ///
        methods.add_method("tickStatuses", |lua, this, ()| {
            let expired = this.0.borrow_mut().tick_statuses();
            lua.create_sequence_from(expired)
        });
        /// Returns the statuses.
        ///
        /// @return any
        methods.add_method("getStatuses", |lua, this, ()| {
            let table = lua.create_table()?;
            for (index, effect) in this.0.borrow().status_effects.iter().enumerate() {
                let status = lua.create_table()?;
                status.set("name", effect.name.clone())?;
                status.set("duration", effect.duration)?;
                status.set("stacks", effect.stacks)?;
                table.set(index + 1, status)?;
            }
            Ok(table)
        });
        /// Adds action.
        ///
        /// @param action : CombatAction
        methods.add_method("addAction", |_, this, action: LuaAnyUserData| {
            let action_clone = action.borrow::<LuaCombatAction>()?.0.borrow().clone();
            this.0.borrow_mut().add_action(action_clone);
            Ok(())
        });
        /// Returns true if action.
        ///
        /// @param name : string
        /// @return boolean
        methods.add_method("hasAction", |_, this, name: String| {
            Ok(this.0.borrow().get_action(&name).is_some())
        });
        /// Tick cooldowns.
        ///
        methods.add_method("tickCooldowns", |_, this, ()| {
            let mut borrow = this.0.borrow_mut();
            for action in &mut borrow.actions {
                action.tick_cooldown();
            }
            Ok(())
        });
        /// Returns the meta.
        ///
        /// @param key : string
        /// @return any
        methods.add_method("getMeta", |_, this, key: String| {
            Ok(this.0.borrow().metadata.get(&key).cloned())
        });
        /// Sets the meta.
        ///
        /// @param key : string
        /// @param value : string
        methods.add_method("setMeta", |_, this, (key, value): (String, String)| {
            this.0.borrow_mut().metadata.insert(key, value);
            Ok(())
        });
        /// Returns the hp percent.
        ///
        /// @return any
        methods.add_method("getHpPercent", |_, this, ()| Ok(this.0.borrow().hp_percent()));
        /// Returns the mp percent.
        ///
        /// @return any
        methods.add_method("getMpPercent", |_, this, ()| Ok(this.0.borrow().mp_percent()));
        /// Returns the action names.
        ///
        methods.add_method("getActionNames", |lua, this, ()| {
            lua.create_sequence_from(this.0.borrow().action_names())
        });
        /// Returns the status names.
        ///
        methods.add_method("getStatusNames", |lua, this, ()| {
            lua.create_sequence_from(this.0.borrow().status_names())
        });
    }
}

/// Lua wrapper for [`CombatBattle`]. Consult the module-level documentation for the broader usage context and preconditions.
#[derive(Clone)]
pub struct LuaCombatBattle(pub Rc<RefCell<CombatBattle>>);

impl LunaType for LuaCombatBattle {
    const TYPE_NAME: &'static str = "CombatBattle";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CombatBattle"];
}

impl LuaUserData for LuaCombatBattle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the name.
        ///
        /// @return any
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the count.
        ///
        /// @return integer
        methods.add_method("getCount", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns the turn count.
        ///
        /// @return any
        methods.add_method("getTurnCount", |_, this, ()| Ok(this.0.borrow().turn_count));
        /// Returns true if over.
        ///
        /// @return any
        methods.add_method("isOver", |_, this, ()| Ok(this.0.borrow().is_over()));
        /// Returns the winner.
        ///
        /// @return any
        methods.add_method("getWinner", |_, this, ()| Ok(this.0.borrow().winner_team.clone()));
        /// Adds combatant.
        ///
        /// @param combatant : Combatant
        methods.add_method("addCombatant", |_, this, combatant: LuaAnyUserData| {
            let combatant_clone = combatant.borrow::<LuaCombatant>()?.0.borrow().clone();
            this.0.borrow_mut().add_combatant(combatant_clone);
            Ok(())
        });
        /// Returns the combatant.
        ///
        /// @param name : string
        /// @return any
        methods.add_method("getCombatant", |_, this, name: String| {
            Ok(this
                .0
                .borrow()
                .get_combatant(&name)
                .cloned()
                .map(|combatant| LuaCombatant(Rc::new(RefCell::new(combatant)))))
        });
        /// Sort initiative.
        ///
        methods.add_method("sortInitiative", |_, this, ()| {
            this.0.borrow_mut().sort_initiative();
            Ok(())
        });
        /// Returns the current combatant.
        ///
        /// @return any
        methods.add_method("getCurrentCombatant", |_, this, ()| {
            Ok(this
                .0
                .borrow()
                .current_combatant()
                .cloned()
                .map(|combatant| LuaCombatant(Rc::new(RefCell::new(combatant)))))
        });
        /// Next turn.
        ///
        /// @return any
        methods.add_method("nextTurn", |_, this, ()| Ok(this.0.borrow_mut().next_turn()));
        methods.add_method(
            "attack",
            |lua, this, (attacker, action, target): (String, String, String)| {
                if let Some(result) = this.0.borrow_mut().attack(&attacker, &action, &target) {
                    let table = lua.create_table()?;
                    table.set("attacker", result.attacker)?;
                    table.set("target", result.target)?;
                    table.set("action", result.action)?;
                    table.set("hit", result.hit)?;
                    table.set("damage", result.damage)?;
                    table.set("damageType", result.damage_type)?;
                    table.set("targetDied", result.target_died)?;
                    table.set("message", result.message)?;
                    Ok(LuaValue::Table(table))
                } else {
                    Ok(LuaValue::Nil)
                }
            },
        );
        /// Returns the alive names.
        ///
        methods.add_method("getAliveNames", |lua, this, ()| {
            lua.create_sequence_from(this.0.borrow().alive_names())
        });
        /// Returns the log.
        ///
        /// @return any
        methods.add_method("getLog", |lua, this, ()| {
            let table = lua.create_table()?;
            for (index, msg) in this.0.borrow().log.iter().enumerate() {
                table.set(index + 1, msg.clone())?;
            }
            Ok(table)
        });
        /// Adds to log.
        ///
        /// @param msg : string
        methods.add_method("addToLog", |_, this, msg: String| {
            this.0.borrow_mut().push_log(msg);
            Ok(())
        });
        /// Removes combatant.
        ///
        /// @param name : string
        /// @return any
        methods.add_method("removeCombatant", |_, this, name: String| {
            Ok(this.0.borrow_mut().remove_combatant(&name))
        });
        /// Force end.
        ///
        /// @param winner : string?
        methods.add_method("forceEnd", |_, this, winner: Option<String>| {
            this.0.borrow_mut().force_end(winner);
            Ok(())
        });
        /// Returns the all names.
        ///
        methods.add_method("getAllNames", |lua, this, ()| {
            lua.create_sequence_from(this.0.borrow().get_all_names())
        });
    }
}

/// Registers the `luna.battle.*` table. Panics in debug mode if the same entity is registered twice.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
/// - `_state` — `Rc<RefCell<SharedState>>`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &LuaTable,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let module = lua.create_table()?;

    /// New combatant.
    ///
    /// @param name : string
    /// @return any
    module.set("newCombatant", lua.create_function(|_, name: String| {
        Ok(LuaCombatant(Rc::new(RefCell::new(Combatant::new(name)))))
    })?)?;
    /// New action.
    ///
    /// @param name : string
    /// @return any
    module.set("newAction", lua.create_function(|_, name: String| {
        Ok(LuaCombatAction(Rc::new(RefCell::new(CombatAction::new(name)))))
    })?)?;
    /// New status effect.
    ///
    /// @param name : string
    /// @param duration : integer?
    /// @return any
    module.set(
        "newStatusEffect",
        lua.create_function(|_, (name, duration): (String, Option<i32>)| {
            Ok(LuaStatusEffect(Rc::new(RefCell::new(StatusEffect::new(
                name,
                duration.unwrap_or(-1),
            )))))
        })?,
    )?;
    /// New battle.
    ///
    /// @param name : string?
    /// @return any
    module.set("newBattle", lua.create_function(|_, name: Option<String>| {
        Ok(LuaCombatBattle(Rc::new(RefCell::new(CombatBattle::new(
            name.unwrap_or_default(),
        )))))
    })?)?;

    luna.set("turnbattle", module)?;
    Ok(())
}