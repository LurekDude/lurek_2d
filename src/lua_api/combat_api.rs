//! Lua bindings for `luna.combat.*`.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::combat::{CombatAction, CombatBattle, Combatant, StatusEffect};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ─────────────────────────────────────────────────────────────────────────────
// LuaStatusEffect
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaStatusEffect(pub Rc<RefCell<StatusEffect>>);

impl LunaType for LuaStatusEffect {
    const TYPE_NAME: &'static str = "StatusEffect";
    const TYPE_HIERARCHY: &'static [&'static str] = &["StatusEffect"];
}

impl LuaUserData for LuaStatusEffect {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the status effect's name identifier (e.g. `'poison'`, `'burn'`).
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the remaining duration in turns.
        ///
        /// # Returns
        /// `integer` — turns remaining.
        methods.add_method("getDuration", |_, this, ()| Ok(this.0.borrow().duration));
        /// Sets the remaining duration in turns.
        ///
        /// # Parameters
        /// - `turns` — `integer`: New duration.
        methods.add_method("setDuration", |_, this, v: i32| { this.0.borrow_mut().duration = v; Ok(()) });
        /// Returns the current stack count of this status effect.
        ///
        /// # Returns
        /// `integer` — stack count.
        methods.add_method("getStacks", |_, this, ()| Ok(this.0.borrow().stacks));
        /// Sets the stack count directly.
        ///
        /// # Parameters
        /// - `stacks` — `integer`: New stack count.
        methods.add_method("setStacks", |_, this, v: u32| { this.0.borrow_mut().stacks = v; Ok(()) });
        /// Returns `true` if this effect's duration has reached zero.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isExpired", |_, this, ()| Ok(this.0.borrow().is_expired()));
        /// Decrements the duration by 1 and removes the effect if it expires.
        methods.add_method("tickTurn", |_, this, ()| Ok(this.0.borrow_mut().tick_turn()));
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCombatAction
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaCombatAction(pub Rc<RefCell<CombatAction>>);

impl LunaType for LuaCombatAction {
    const TYPE_NAME: &'static str = "CombatAction";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CombatAction"];
}

impl LuaUserData for LuaCombatAction {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the action's name identifier.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the base damage dealt by this action before modifiers.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getBaseDamage", |_, this, ()| Ok(this.0.borrow().base_damage));
        /// Sets the base damage for this action.
        ///
        /// # Parameters
        /// - `damage` — `number`: New base damage value.
        methods.add_method("setBaseDamage", |_, this, v: f64| { this.0.borrow_mut().base_damage = v; Ok(()) });
        /// Returns the damage type string (e.g. `'physical'`, `'fire'`).
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getDamageType", |_, this, ()| Ok(this.0.borrow().damage_type.clone()));
        /// Sets the damage type.
        ///
        /// # Parameters
        /// - `dtype` — `string`: Damage type string.
        methods.add_method("setDamageType", |_, this, v: String| { this.0.borrow_mut().damage_type = v; Ok(()) });
        /// Returns the hit chance as a percentage (0–100).
        ///
        /// # Returns
        /// `number` — accuracy percentage.
        methods.add_method("getAccuracy", |_, this, ()| Ok(this.0.borrow().accuracy));
        /// Sets the hit chance percentage.
        ///
        /// # Parameters
        /// - `accuracy` — `number`: Hit chance (0–100).
        methods.add_method("setAccuracy", |_, this, v: f64| { this.0.borrow_mut().accuracy = v.clamp(0.0, 1.0); Ok(()) });
        /// Returns the maximum cooldown in turns before this action can be used again.
        ///
        /// # Returns
        /// `integer` — max cooldown turns.
        methods.add_method("getCooldown", |_, this, ()| Ok(this.0.borrow().cooldown));
        /// Sets the maximum cooldown for this action.
        ///
        /// # Parameters
        /// - `turns` — `integer`: Cooldown in turns.
        methods.add_method("setCooldown", |_, this, v: u32| { this.0.borrow_mut().cooldown = v; Ok(()) });
        /// Returns the remaining cooldown turns until this action is ready.
        ///
        /// # Returns
        /// `integer` — turns remaining.
        methods.add_method("getCurrentCooldown", |_, this, ()| Ok(this.0.borrow().current_cooldown));
        /// Returns `true` if the current cooldown has reached zero.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isReady", |_, this, ()| Ok(this.0.borrow().is_ready()));
        /// Decrements the current cooldown by 1 (minimum 0).
        methods.add_method("tickCooldown", |_, this, ()| { this.0.borrow_mut().tick_cooldown(); Ok(()) });
        /// Returns the MP cost to use this action.
        ///
        /// # Returns
        /// `integer` — MP cost.
        methods.add_method("getCostMp", |_, this, ()| Ok(this.0.borrow().cost_mp));
        /// Sets the MP cost for this action.
        ///
        /// # Parameters
        /// - `cost` — `integer`: New MP cost.
        methods.add_method("setCostMp", |_, this, v: f64| { this.0.borrow_mut().cost_mp = v; Ok(()) });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCombatant
// ─────────────────────────────────────────────────────────────────────────────

#[derive(Clone)]
pub struct LuaCombatant(pub Rc<RefCell<Combatant>>);

impl LunaType for LuaCombatant {
    const TYPE_NAME: &'static str = "Combatant";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Combatant"];
}

impl LuaUserData for LuaCombatant {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the combatant's display name.
        ///
        /// # Returns
        /// `string`.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the team identifier for this combatant.
        ///
        /// # Returns
        /// `string` — team name.
        methods.add_method("getTeam", |_, this, ()| Ok(this.0.borrow().team.clone()));
        /// Assigns this combatant to a team.
        ///
        /// # Parameters
        /// - `team` — `string`: Team identifier.
        methods.add_method("setTeam", |_, this, v: String| { this.0.borrow_mut().team = v; Ok(()) });
        /// Returns current HP.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getHp", |_, this, ()| Ok(this.0.borrow().hp));
        /// Sets current HP, clamped to [0, maxHp].
        ///
        /// # Parameters
        /// - `hp` — `number`: New HP value.
        methods.add_method("setHp", |_, this, v: f64| { this.0.borrow_mut().hp = v; Ok(()) });
        /// Returns maximum HP.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getMaxHp", |_, this, ()| Ok(this.0.borrow().max_hp));
        /// Sets the maximum HP and clamps current HP if needed.
        ///
        /// # Parameters
        /// - `max_hp` — `number`: New max HP.
        methods.add_method("setMaxHp", |_, this, v: f64| { this.0.borrow_mut().max_hp = v; Ok(()) });
        /// Returns current MP.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getMp", |_, this, ()| Ok(this.0.borrow().mp));
        /// Sets current MP, clamped to [0, maxMp].
        ///
        /// # Parameters
        /// - `mp` — `number`: New MP value.
        methods.add_method("setMp", |_, this, v: f64| { this.0.borrow_mut().mp = v; Ok(()) });
        /// Returns maximum MP.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getMaxMp", |_, this, ()| Ok(this.0.borrow().max_mp));
        /// Sets the maximum MP.
        ///
        /// # Parameters
        /// - `max_mp` — `number`: New max MP.
        methods.add_method("setMaxMp", |_, this, v: f64| { this.0.borrow_mut().max_mp = v; Ok(()) });
        /// Returns the initiative speed value used to determine turn order.
        ///
        /// # Returns
        /// `number`.
        methods.add_method("getSpeed", |_, this, ()| Ok(this.0.borrow().speed));
        /// Sets the initiative speed value.
        ///
        /// # Parameters
        /// - `speed` — `number`: New speed value.
        methods.add_method("setSpeed", |_, this, v: f64| { this.0.borrow_mut().speed = v; Ok(()) });
        /// Returns the combatant's experience level.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        /// Returns `true` if current HP is greater than zero.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isAlive", |_, this, ()| Ok(this.0.borrow().is_alive()));

        /// Applies `amount` damage of `dtype`, reduced by resistances, and returns net damage dealt.
        ///
        /// # Parameters
        /// - `amount` — `number`: Incoming damage before resistance.
        /// - `dtype` — `string`: Damage type (e.g. `'fire'`, `'physical'`).
        ///
        /// # Returns
        /// `number` — net damage after resistance.
        methods.add_method("takeDamage", |_, this, (amount, dtype): (f64, Option<String>)| {
            let dtype = dtype.unwrap_or_else(|| "physical".to_string());
            Ok(this.0.borrow_mut().take_damage(amount, &dtype))
        });
        /// Increases current HP by `amount`, clamped at maxHp.
        ///
        /// # Parameters
        /// - `amount` — `number`: Amount to heal.
        ///
        /// # Returns
        /// `number` — actual HP restored.
        methods.add_method("heal", |_, this, amount: f64| {
            Ok(this.0.borrow_mut().heal(amount))
        });

        /// Returns the value of a named stat (e.g. `'strength'`, `'agility'`).
        ///
        /// # Parameters
        /// - `key` — `string`: Stat name.
        ///
        /// # Returns
        /// `number` — stat value, or `0` if not set.
        methods.add_method("getStat", |_, this, name: String| Ok(this.0.borrow().get_stat(&name)));
        /// Sets a named stat value.
        ///
        /// # Parameters
        /// - `key` — `string`: Stat name.
        /// - `value` — `number`: New value.
        methods.add_method("setStat", |_, this, (name, v): (String, f64)| {
            this.0.borrow_mut().set_stat(name, v); Ok(())
        });
        /// Returns the resistance percentage for `dtype` (0–100). `100` means immune.
        ///
        /// # Parameters
        /// - `dtype` — `string`: Damage type.
        ///
        /// # Returns
        /// `number` — resistance percentage.
        methods.add_method("getResistance", |_, this, dtype: String| {
            Ok(*this.0.borrow().resistances.get(&dtype).unwrap_or(&1.0))
        });
        /// Sets resistance for a damage type.
        ///
        /// # Parameters
        /// - `dtype` — `string`: Damage type.
        /// - `pct` — `number`: Resistance percentage (0–100).
        methods.add_method("setResistance", |_, this, (dtype, v): (String, f64)| {
            this.0.borrow_mut().resistances.insert(dtype, v); Ok(())
        });

        // Status effects
        /// Applies a named status effect, optionally stacking on an existing one.
        ///
        /// # Parameters
        /// - `name` — `string`: Status effect name.
        /// - `duration` — `integer`: Duration in turns.
        /// - `stacks` — `integer`: Stack count (optional, default `1`).
        methods.add_method("addStatus", |_, this, (name, duration): (String, Option<i32>)| {
            let effect = StatusEffect::new(name, duration.unwrap_or(-1));
            this.0.borrow_mut().add_status(effect);
            Ok(())
        });
        /// Removes the status effect with the given name.
        ///
        /// # Parameters
        /// - `name` — `string`: Status effect name to remove.
        methods.add_method("removeStatus", |_, this, name: String| {
            this.0.borrow_mut().remove_status(&name); Ok(())
        });
        /// Returns `true` if this combatant is affected by the named status.
        ///
        /// # Parameters
        /// - `name` — `string`: Status name to check.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasStatus", |_, this, name: String| {
            Ok(this.0.borrow().has_status(&name))
        });
        /// Decrements all active status effect durations by one turn and removes any that expire.
        methods.add_method("tickStatuses", |lua, this, ()| {
            let expired = this.0.borrow_mut().tick_statuses();
            let t = lua.create_sequence_from(expired.into_iter())?;
            Ok(t)
        });
        /// Returns a list of all active `StatusEffect` objects on this combatant.
        ///
        /// # Returns
        /// `table` of `StatusEffect` objects.
        methods.add_method("getStatuses", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, e) in borrow.status_effects.iter().enumerate() {
                let st = lua.create_table()?;
                /// Name on this Combatant.
                ///
                /// # Returns
                /// The result.
                st.set("name", e.name.clone())?;
                /// Duration on this Combatant.
                ///
                /// # Returns
                /// The result.
                st.set("duration", e.duration)?;
                /// Stacks on this Combatant.
                ///
                /// # Parameters
                /// - `action` — `userdata`.
                st.set("stacks", e.stacks)?;
                t.set(i + 1, st)?;
            }
            Ok(t)
        });

        // Actions
        /// Registers a `CombatAction` that this combatant can use in battle.
        ///
        /// # Parameters
        /// - `action` — `CombatAction`: Action to add.
        methods.add_method("addAction", |_, this, action: LuaAnyUserData| {
            let action_clone = action.borrow::<LuaCombatAction>()?.0.borrow().clone();
            this.0.borrow_mut().add_action(action_clone);
            Ok(())
        });
        /// Returns `true` if this combatant has an action with the given name.
        ///
        /// # Parameters
        /// - `name` — `string`: Action name.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasAction", |_, this, name: String| {
            Ok(this.0.borrow().get_action(&name).is_some())
        });
        /// Decrements all active action cooldowns by one turn.
        methods.add_method("tickCooldowns", |_, this, ()| {
            let mut borrow = this.0.borrow_mut();
            for action in &mut borrow.actions { action.tick_cooldown(); }
            Ok(())
        });

        /// Returns metadata value for `key`, or `nil` if not set.
        ///
        /// # Parameters
        /// - `key` — `string`: Metadata key.
        ///
        /// # Returns
        /// The stored value or `nil`.
        methods.add_method("getMeta", |_, this, key: String| {
            let borrow = this.0.borrow();
            let val = borrow.metadata.get(&key).cloned();
            drop(borrow);
            Ok(val)
        });
        /// Stores an arbitrary metadata value on this combatant.
        ///
        /// # Parameters
        /// - `key` — `string`: Key.
        /// - `value` — `any`: Value.
        methods.add_method("setMeta", |_, this, (k, v): (String, String)| {
            this.0.borrow_mut().metadata.insert(k, v); Ok(())
        });
        /// Returns hp as a fraction of max hp (0.0..=1.0).
        methods.add_method("getHpPercent", |_, this, ()| Ok(this.0.borrow().hp_percent()));
        /// Returns mp as a fraction of max mp (0.0..=1.0).
        methods.add_method("getMpPercent", |_, this, ()| Ok(this.0.borrow().mp_percent()));
        /// Returns a list of action names owned by this combatant.
        methods.add_method("getActionNames", |lua, this, ()| {
            let names = this.0.borrow().action_names();
            lua.create_sequence_from(names)
        });
        /// Returns a list of active status effect names on this combatant.
        methods.add_method("getStatusNames", |lua, this, ()| {
            let names = this.0.borrow().status_names();
            lua.create_sequence_from(names)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCombatBattle
// ─────────────────────────────────────────────────────────────────────────────

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
        /// # Parameters
        /// - `combatant` — `userdata`.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the count.
        ///
        /// # Parameters
        /// - `combatant` — `userdata`.
        ///
        /// # Returns
        /// The current count.
        methods.add_method("getCount", |_, this, ()| Ok(this.0.borrow().count()));
        /// Returns the turn count.
        ///
        /// # Parameters
        /// - `combatant` — `userdata`.
        ///
        /// # Returns
        /// The current turn count.
        methods.add_method("getTurnCount", |_, this, ()| Ok(this.0.borrow().turn_count));
        /// Returns `true` if over.
        ///
        /// # Parameters
        /// - `combatant` — `userdata`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isOver", |_, this, ()| Ok(this.0.borrow().is_over()));
        /// Returns the winner.
        ///
        /// # Parameters
        /// - `combatant` — `userdata`.
        ///
        /// # Returns
        /// The current winner.
        methods.add_method("getWinner", |_, this, ()| Ok(this.0.borrow().winner_team.clone()));

        /// Adds combatant to the collection.
        ///
        /// # Parameters
        /// - `combatant` — `userdata`.
        methods.add_method("addCombatant", |_, this, combatant: LuaAnyUserData| {
            let c = combatant.borrow::<LuaCombatant>()?.0.borrow().clone();
            this.0.borrow_mut().add_combatant(c);
            Ok(())
        });

        /// Returns the combatant.
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current combatant.
        methods.add_method("getCombatant", |_, this, name: String| {
            let borrow = this.0.borrow();
            let c = borrow.get_combatant(&name).cloned();
            drop(borrow);
            Ok(c.map(|c| LuaCombatant(Rc::new(RefCell::new(c)))))
        });

        /// Sort initiative on this CombatBattle.
        ///
        /// # Returns
        /// The result.
        methods.add_method("sortInitiative", |_, this, ()| {
            this.0.borrow_mut().sort_initiative(); Ok(())
        });

        /// Returns the current combatant.
        ///
        /// # Returns
        /// The current current combatant.
        methods.add_method("getCurrentCombatant", |_, this, ()| {
            let borrow = this.0.borrow();
            let c = borrow.current_combatant().cloned();
            drop(borrow);
            Ok(c.map(|c| LuaCombatant(Rc::new(RefCell::new(c)))))
        });

        /// Next turn on this CombatBattle.
        ///
        /// # Parameters
        /// - `attacker` — `string`.
        /// - `action` — `string`.
        /// - `target` — `string`.
        methods.add_method("nextTurn", |_, this, ()| {
            Ok(this.0.borrow_mut().next_turn())
        });

        /// Attack on this CombatBattle.
        ///
        /// # Parameters
        /// - `attacker` — `string`.
        /// - `action` — `string`.
        /// - `target` — `string`.
        methods.add_method("attack", |lua, this, (attacker, action, target): (String, String, String)| {
            let result = this.0.borrow_mut().attack(&attacker, &action, &target);
            if let Some(r) = result {
                let t = lua.create_table()?;
                /// Attacker on this CombatBattle.
                ///
                /// # Returns
                /// The result.
                t.set("attacker", r.attacker)?;
                /// Target on this CombatBattle.
                ///
                /// # Returns
                /// The result.
                t.set("target", r.target)?;
                /// Action on this CombatBattle.
                ///
                /// # Returns
                /// The result.
                t.set("action", r.action)?;
                /// Hit on this CombatBattle.
                ///
                /// # Returns
                /// The result.
                t.set("hit", r.hit)?;
                /// Damage on this CombatBattle.
                ///
                /// # Returns
                /// The result.
                t.set("damage", r.damage)?;
                /// Damage type on this CombatBattle.
                ///
                /// # Returns
                /// The result.
                t.set("damageType", r.damage_type)?;
                /// Target died on this CombatBattle.
                ///
                /// # Returns
                /// The result.
                t.set("targetDied", r.target_died)?;
                /// Message on this CombatBattle.
                ///
                /// # Returns
                /// The result.
                t.set("message", r.message)?;
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });

        /// Returns the alive names.
        ///
        /// # Returns
        /// The current alive names.
        methods.add_method("getAliveNames", |lua, this, ()| {
            let names = this.0.borrow().alive_names();
            let t = lua.create_sequence_from(names.into_iter())?;
            Ok(t)
        });

        /// Returns the log.
        ///
        /// # Parameters
        /// - `msg` — `string`.
        ///
        /// # Returns
        /// The current log.
        methods.add_method("getLog", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, msg) in this.0.borrow().log.iter().enumerate() {
                t.set(i + 1, msg.clone())?;
            }
            Ok(t)
        });
        /// Adds to log to the collection.
        ///
        /// # Parameters
        /// - `msg` — `string`.
        methods.add_method("addToLog", |_, this, msg: String| {
            this.0.borrow_mut().push_log(msg);
            Ok(())
        });
        /// Removes combatant from the collection.
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("removeCombatant", |_, this, name: String| {
            Ok(this.0.borrow_mut().remove_combatant(&name))
        });
        /// Force end on this CombatBattle.
        ///
        /// # Parameters
        /// - `winner` — `string` optional.
        methods.add_method("forceEnd", |_, this, winner: Option<String>| {
            this.0.borrow_mut().force_end(winner);
            Ok(())
        });
        /// Returns all combatant names in the battle (alive and dead).
        methods.add_method("getAllNames", |lua, this, ()| {
            let names = this.0.borrow().get_all_names();
            let t = lua.create_sequence_from(names.into_iter())?;
            Ok(t)
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Register
// ─────────────────────────────────────────────────────────────────────────────

/// Register the `luna.combat.*` table.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let module = lua.create_table()?;

    /// Creates a new combatant instance.
    ///
    /// # Parameters
    /// - `name` — `string`.
    module.set("newCombatant", lua.create_function(|_, name: String| {
        Ok(LuaCombatant(Rc::new(RefCell::new(Combatant::new(name)))))
    })?)?;

    /// Creates a new action instance.
    ///
    /// # Parameters
    /// - `name` — `string`.
    /// - `duration` — `integer` optional.
    module.set("newAction", lua.create_function(|_, name: String| {
        Ok(LuaCombatAction(Rc::new(RefCell::new(CombatAction::new(name)))))
    })?)?;

    /// Creates a new status effect instance.
    ///
    /// # Parameters
    /// - `name` — `string`.
    /// - `duration` — `integer` optional.
    module.set("newStatusEffect", lua.create_function(|_, (name, duration): (String, Option<i32>)| {
        Ok(LuaStatusEffect(Rc::new(RefCell::new(StatusEffect::new(name, duration.unwrap_or(-1))))))
    })?)?;

    /// Creates a new battle instance.
    ///
    /// # Parameters
    /// - `name` — `string` optional.
    module.set("newBattle", lua.create_function(|_, name: Option<String>| {
        Ok(LuaCombatBattle(Rc::new(RefCell::new(CombatBattle::new(name.unwrap_or_default())))))
    })?)?;

    /// Combat on this CombatBattle.
    ///
    /// # Returns
    /// The result.
    luna.set("combat", module)?;
    Ok(())
}
