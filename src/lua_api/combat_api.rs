//! Lua bindings for `luna.combat.*`.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::combat::{
    CombatAction, CombatBattle, Combatant, StatusEffect,
    CollisionGroupSet, Chassis, MountSlot,
    Turret, Weapon, ProjectileType,
    Projectile, ProjectilePool, CombatWorld,
};
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
// ProjectileType helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Parses a string into a `ProjectileType`, defaulting to `Ballistic`.
fn projectile_type_from_str(s: &str) -> ProjectileType {
    match s {
        "homing" => ProjectileType::Homing,
        "ray" => ProjectileType::Ray,
        "area" => ProjectileType::Area,
        "beam" => ProjectileType::Beam,
        _ => ProjectileType::Ballistic,
    }
}

/// Returns the string representation of a `ProjectileType`.
fn projectile_type_to_str(t: ProjectileType) -> &'static str {
    match t {
        ProjectileType::Ballistic => "ballistic",
        ProjectileType::Homing => "homing",
        ProjectileType::Ray => "ray",
        ProjectileType::Area => "area",
        ProjectileType::Beam => "beam",
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCollisionGroupSet
// ─────────────────────────────────────────────────────────────────────────────

/// Lua wrapper for `CollisionGroupSet`.
#[derive(Clone)]
pub struct LuaCollisionGroupSet(pub Rc<RefCell<CollisionGroupSet>>);

impl LunaType for LuaCollisionGroupSet {
    const TYPE_NAME: &'static str = "CollisionGroupSet";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CollisionGroupSet"];
}

impl LuaUserData for LuaCollisionGroupSet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Defines a new named collision group and returns its category bit.
        methods.add_method("defineGroup", |_, this, name: String| {
            this.0.borrow_mut().define_group(&name).map_err(LuaError::external)
        });
        /// Returns the category bit for a named group, or nil.
        methods.add_method("getGroupBit", |_, this, name: String| {
            Ok(this.0.borrow().get_group_bit(&name))
        });
        /// Sets whether two named groups should collide.
        methods.add_method("setCollides", |_, this, (a, b, collides): (String, String, bool)| {
            this.0.borrow_mut().set_collides(&a, &b, collides).map_err(LuaError::external)
        });
        /// Returns whether two named groups collide.
        methods.add_method("getCollides", |_, this, (a, b): (String, String)| {
            Ok(this.0.borrow().get_collides(&a, &b))
        });
        /// Computes the collision mask bits for a named group.
        methods.add_method("computeMask", |_, this, group: String| {
            Ok(this.0.borrow().compute_mask(&group))
        });
        /// Returns the number of defined groups.
        methods.add_method("getGroupCount", |_, this, ()| {
            Ok(this.0.borrow().group_count())
        });
        /// Returns a sequence of all defined group names.
        methods.add_method("getGroupNames", |lua, this, ()| {
            let names = this.0.borrow().group_names();
            lua.create_sequence_from(names)
        });
        /// Resets all groups and collision rules.
        methods.add_method("reset", |_, this, ()| {
            this.0.borrow_mut().reset();
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaChassis
// ─────────────────────────────────────────────────────────────────────────────

/// Lua wrapper for `Chassis`.
#[derive(Clone)]
pub struct LuaChassis(pub Rc<RefCell<Chassis>>);

impl LunaType for LuaChassis {
    const TYPE_NAME: &'static str = "Chassis";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Chassis"];
}

impl LuaUserData for LuaChassis {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the physics body ID for this chassis.
        methods.add_method("getBodyId", |_, this, ()| Ok(this.0.borrow().body_id));
        /// Returns the team identifier.
        methods.add_method("getTeam", |_, this, ()| Ok(this.0.borrow().team.clone()));
        /// Sets the team identifier.
        methods.add_method("setTeam", |_, this, v: String| { this.0.borrow_mut().team = v; Ok(()) });
        /// Returns current HP.
        methods.add_method("getHp", |_, this, ()| Ok(this.0.borrow().hp));
        /// Sets current HP, clamped to [0, maxHp].
        methods.add_method("setHp", |_, this, v: f32| {
            let mut b = this.0.borrow_mut();
            b.hp = v.clamp(0.0, b.max_hp);
            Ok(())
        });
        /// Returns maximum HP.
        methods.add_method("getMaxHp", |_, this, ()| Ok(this.0.borrow().max_hp));
        /// Sets maximum HP.
        methods.add_method("setMaxHp", |_, this, v: f32| { this.0.borrow_mut().max_hp = v; Ok(()) });
        /// Returns `true` if the chassis is dead (HP ≤ 0).
        methods.add_method("isDead", |_, this, ()| Ok(this.0.borrow().is_dead()));
        /// Returns `true` if the chassis has been destroyed.
        methods.add_method("isDestroyed", |_, this, ()| Ok(this.0.borrow().destroyed));
        /// Applies damage and returns the actual amount dealt.
        methods.add_method("takeDamage", |_, this, amount: f32| {
            Ok(this.0.borrow_mut().take_damage(amount))
        });
        /// Heals the chassis and returns the actual amount healed.
        methods.add_method("heal", |_, this, amount: f32| {
            Ok(this.0.borrow_mut().heal(amount))
        });
        /// Returns the armor value for a named zone.
        methods.add_method("getArmor", |_, this, zone: String| {
            Ok(this.0.borrow().get_armor(&zone))
        });
        /// Sets the armor value for a named zone.
        methods.add_method("setArmor", |_, this, (zone, value): (String, f32)| {
            this.0.borrow_mut().set_armor(&zone, value);
            Ok(())
        });
        /// Returns a sequence of mount slot tables.
        methods.add_method("getSlots", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, slot) in borrow.slots.iter().enumerate() {
                let st = lua.create_table()?;
                st.set("id", slot.id.clone())?;
                st.set("x", slot.x)?;
                st.set("y", slot.y)?;
                st.set("sizeClass", slot.size_class.clone())?;
                st.set("arcMin", slot.arc_min)?;
                st.set("arcMax", slot.arc_max)?;
                t.set(i + 1, st)?;
            }
            Ok(t)
        });
        /// Adds a mount slot from a Lua table with fields id, x, y, sizeClass, arcMin, arcMax.
        methods.add_method("addSlot", |_, this, tbl: LuaTable| {
            let slot = MountSlot {
                id: tbl.get::<_, String>("id")?,
                x: tbl.get::<_, f32>("x").unwrap_or(0.0),
                y: tbl.get::<_, f32>("y").unwrap_or(0.0),
                size_class: tbl.get::<_, String>("sizeClass").unwrap_or_else(|_| "medium".to_string()),
                arc_min: tbl.get::<_, f32>("arcMin").unwrap_or(-std::f32::consts::PI),
                arc_max: tbl.get::<_, f32>("arcMax").unwrap_or(std::f32::consts::PI),
            };
            this.0.borrow_mut().add_slot(slot);
            Ok(())
        });
        /// Returns the optional user data string, or nil.
        methods.add_method("getUserData", |_, this, ()| {
            Ok(this.0.borrow().user_data.clone())
        });
        /// Sets the user data string.
        methods.add_method("setUserData", |_, this, data: String| {
            this.0.borrow_mut().user_data = Some(data);
            Ok(())
        });
        /// Destroys the chassis, setting HP to 0 and destroyed to true.
        methods.add_method("destroy", |_, this, ()| {
            let mut b = this.0.borrow_mut();
            b.destroyed = true;
            b.hp = 0.0;
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaTurret
// ─────────────────────────────────────────────────────────────────────────────

/// Lua wrapper for `Turret`.
#[derive(Clone)]
pub struct LuaTurret(pub Rc<RefCell<Turret>>);

impl LunaType for LuaTurret {
    const TYPE_NAME: &'static str = "Turret";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Turret"];
}

impl LuaUserData for LuaTurret {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the physics body ID.
        methods.add_method("getBodyId", |_, this, ()| Ok(this.0.borrow().body_id));
        /// Returns the revolute joint ID.
        methods.add_method("getJointId", |_, this, ()| Ok(this.0.borrow().joint_id));
        /// Returns the turn speed in radians per second.
        methods.add_method("getTurnSpeed", |_, this, ()| Ok(this.0.borrow().turn_speed));
        /// Sets the turn speed in radians per second.
        methods.add_method("setTurnSpeed", |_, this, v: f32| { this.0.borrow_mut().turn_speed = v; Ok(()) });
        /// Returns the minimum arc angle in radians.
        methods.add_method("getArcMin", |_, this, ()| Ok(this.0.borrow().arc_min));
        /// Sets the minimum arc angle in radians.
        methods.add_method("setArcMin", |_, this, v: f32| { this.0.borrow_mut().arc_min = v; Ok(()) });
        /// Returns the maximum arc angle in radians.
        methods.add_method("getArcMax", |_, this, ()| Ok(this.0.borrow().arc_max));
        /// Sets the maximum arc angle in radians.
        methods.add_method("setArcMax", |_, this, v: f32| { this.0.borrow_mut().arc_max = v; Ok(()) });
        /// Sets the desired target angle for the turret to aim at.
        methods.add_method("aimAtAngle", |_, this, angle: f32| {
            this.0.borrow_mut().aim_at_angle(angle);
            Ok(())
        });
        /// Returns `true` if the turret is aimed within tolerance of its target.
        methods.add_method("isAimed", |_, this, tolerance: Option<f32>| {
            Ok(this.0.borrow().is_aimed(tolerance.unwrap_or(0.05)))
        });
        /// Returns the size class string.
        methods.add_method("getSizeClass", |_, this, ()| Ok(this.0.borrow().size_class.clone()));
        /// Sets the size class string.
        methods.add_method("setSizeClass", |_, this, v: String| { this.0.borrow_mut().size_class = v; Ok(()) });
        /// Returns `true` if the turret has been destroyed.
        methods.add_method("isDestroyed", |_, this, ()| Ok(this.0.borrow().destroyed));
        /// Destroys the turret.
        methods.add_method("destroy", |_, this, ()| { this.0.borrow_mut().destroyed = true; Ok(()) });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaWeapon
// ─────────────────────────────────────────────────────────────────────────────

/// Lua wrapper for fire-rate-based `Weapon`.
#[derive(Clone)]
pub struct LuaWeapon(pub Rc<RefCell<Weapon>>);

impl LunaType for LuaWeapon {
    const TYPE_NAME: &'static str = "Weapon";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Weapon"];
}

impl LuaUserData for LuaWeapon {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the weapon display name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        /// Returns the fire rate in rounds per second.
        methods.add_method("getFireRate", |_, this, ()| Ok(this.0.borrow().fire_rate));
        /// Sets the fire rate in rounds per second.
        methods.add_method("setFireRate", |_, this, v: f32| { this.0.borrow_mut().fire_rate = v; Ok(()) });
        /// Returns `true` if the weapon is ready to fire.
        methods.add_method("canFire", |_, this, ()| Ok(this.0.borrow().can_fire()));
        /// Attempts to fire the weapon. Returns `true` if a shot was produced.
        methods.add_method("fire", |_, this, dt: Option<f32>| {
            Ok(this.0.borrow_mut().fire(dt.unwrap_or(0.016)))
        });
        /// Starts continuous firing mode.
        methods.add_method("startFiring", |_, this, ()| { this.0.borrow_mut().start_firing(); Ok(()) });
        /// Stops continuous firing mode.
        methods.add_method("stopFiring", |_, this, ()| { this.0.borrow_mut().stop_firing(); Ok(()) });
        /// Returns `true` if the weapon is in firing mode.
        methods.add_method("isFiring", |_, this, ()| Ok(this.0.borrow().is_firing()));
        /// Returns current ammo count (-1 = infinite).
        methods.add_method("getAmmo", |_, this, ()| Ok(this.0.borrow().ammo));
        /// Sets current ammo count.
        methods.add_method("setAmmo", |_, this, v: i32| { this.0.borrow_mut().ammo = v; Ok(()) });
        /// Returns the maximum ammo capacity.
        methods.add_method("getMaxAmmo", |_, this, ()| Ok(this.0.borrow().max_ammo));
        /// Sets the maximum ammo capacity.
        methods.add_method("setMaxAmmo", |_, this, v: i32| { this.0.borrow_mut().max_ammo = v; Ok(()) });
        /// Reloads ammo. If amount is nil, refills to max.
        methods.add_method("reload", |_, this, amount: Option<i32>| {
            this.0.borrow_mut().reload(amount);
            Ok(())
        });
        /// Returns `true` if the weapon has exhausted its ammo.
        methods.add_method("isOutOfAmmo", |_, this, ()| Ok(this.0.borrow().is_out_of_ammo()));
        /// Returns the burst size.
        methods.add_method("getBurstSize", |_, this, ()| Ok(this.0.borrow().burst_size));
        /// Sets the burst size.
        methods.add_method("setBurstSize", |_, this, v: u32| { this.0.borrow_mut().burst_size = v; Ok(()) });
        /// Returns the burst delay in seconds.
        methods.add_method("getBurstDelay", |_, this, ()| Ok(this.0.borrow().burst_delay));
        /// Sets the burst delay in seconds.
        methods.add_method("setBurstDelay", |_, this, v: f32| { this.0.borrow_mut().burst_delay = v; Ok(()) });
        /// Returns the angular spread in radians.
        methods.add_method("getSpread", |_, this, ()| Ok(this.0.borrow().spread));
        /// Sets the angular spread in radians.
        methods.add_method("setSpread", |_, this, v: f32| { this.0.borrow_mut().spread = v; Ok(()) });
        /// Returns damage per hit.
        methods.add_method("getDamage", |_, this, ()| Ok(this.0.borrow().damage_amount));
        /// Sets damage per hit.
        methods.add_method("setDamage", |_, this, v: f32| { this.0.borrow_mut().damage_amount = v; Ok(()) });
        /// Returns the damage type string.
        methods.add_method("getDamageType", |_, this, ()| Ok(this.0.borrow().damage_type.clone()));
        /// Sets the damage type string.
        methods.add_method("setDamageType", |_, this, v: String| { this.0.borrow_mut().damage_type = v; Ok(()) });
        /// Returns the armor penetration value.
        methods.add_method("getPenetration", |_, this, ()| Ok(this.0.borrow().penetration));
        /// Sets the armor penetration value.
        methods.add_method("setPenetration", |_, this, v: f32| { this.0.borrow_mut().penetration = v; Ok(()) });
        /// Returns the maximum range in world units.
        methods.add_method("getRange", |_, this, ()| Ok(this.0.borrow().range));
        /// Sets the maximum range in world units.
        methods.add_method("setRange", |_, this, v: f32| { this.0.borrow_mut().range = v; Ok(()) });
        /// Returns the projectile travel speed.
        methods.add_method("getProjectileSpeed", |_, this, ()| Ok(this.0.borrow().projectile_speed));
        /// Sets the projectile travel speed.
        methods.add_method("setProjectileSpeed", |_, this, v: f32| { this.0.borrow_mut().projectile_speed = v; Ok(()) });
        /// Returns the projectile type as a string.
        methods.add_method("getProjectileType", |_, this, ()| {
            Ok(projectile_type_to_str(this.0.borrow().projectile_type).to_string())
        });
        /// Sets the projectile type from a string.
        methods.add_method("setProjectileType", |_, this, v: String| {
            this.0.borrow_mut().projectile_type = projectile_type_from_str(&v);
            Ok(())
        });
        /// Returns the remaining cooldown in seconds.
        methods.add_method("getCooldown", |_, this, ()| Ok(this.0.borrow().cooldown_remaining));
        /// Updates the cooldown timer by dt seconds.
        methods.add_method("updateCooldown", |_, this, dt: f32| {
            this.0.borrow_mut().update_cooldown(dt);
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaProjectile
// ─────────────────────────────────────────────────────────────────────────────

/// Lua wrapper for `Projectile`.
#[derive(Clone)]
pub struct LuaProjectile(pub Rc<RefCell<Projectile>>);

impl LunaType for LuaProjectile {
    const TYPE_NAME: &'static str = "Projectile";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Projectile"];
}

impl LuaUserData for LuaProjectile {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Returns the physics body ID.
        methods.add_method("getBodyId", |_, this, ()| Ok(this.0.borrow().body_id));
        /// Returns `true` if this projectile is currently active.
        methods.add_method("isActive", |_, this, ()| Ok(this.0.borrow().active));
        /// Returns the time this projectile has been alive in seconds.
        methods.add_method("getLifetime", |_, this, ()| Ok(this.0.borrow().lifetime));
        /// Returns total distance traveled in world units.
        methods.add_method("getDistanceTraveled", |_, this, ()| Ok(this.0.borrow().distance_traveled));
        /// Returns the travel speed.
        methods.add_method("getSpeed", |_, this, ()| Ok(this.0.borrow().speed));
        /// Returns the damage value.
        methods.add_method("getDamage", |_, this, ()| Ok(this.0.borrow().damage_amount));
        /// Returns the damage type string.
        methods.add_method("getDamageType", |_, this, ()| Ok(this.0.borrow().damage_type.clone()));
        /// Returns the name of the weapon that fired this projectile.
        methods.add_method("getSourceWeapon", |_, this, ()| Ok(this.0.borrow().source_weapon_name.clone()));
        /// Sets the homing target position.
        methods.add_method("setTarget", |_, this, (x, y): (f32, f32)| {
            this.0.borrow_mut().target_pos = Some((x, y));
            Ok(())
        });
        /// Sets the homing target body ID.
        methods.add_method("setTargetBody", |_, this, body_id: usize| {
            this.0.borrow_mut().target_body = Some(body_id);
            Ok(())
        });
        /// Deactivates this projectile.
        methods.add_method("release", |_, this, ()| {
            this.0.borrow_mut().active = false;
            Ok(())
        });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaProjectilePool
// ─────────────────────────────────────────────────────────────────────────────

/// Lua wrapper for `ProjectilePool`.
#[derive(Clone)]
pub struct LuaProjectilePool(pub Rc<RefCell<ProjectilePool>>);

impl LunaType for LuaProjectilePool {
    const TYPE_NAME: &'static str = "ProjectilePool";
    const TYPE_HIERARCHY: &'static [&'static str] = &["ProjectilePool"];
}

impl LuaUserData for LuaProjectilePool {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Spawns a projectile from the pool. Returns the index or nil if exhausted.
        #[allow(clippy::too_many_arguments)]
        methods.add_method("spawn", |_, this, (x, y, angle, speed, damage, damage_type, range): (f32, f32, f32, f32, f32, String, f32)| {
            Ok(this.0.borrow_mut().spawn(x, y, angle, speed, damage, &damage_type, range))
        });
        /// Releases a projectile back to the pool by index.
        methods.add_method("release", |_, this, index: usize| {
            this.0.borrow_mut().release(index);
            Ok(())
        });
        /// Returns the number of active projectiles.
        methods.add_method("getActiveCount", |_, this, ()| Ok(this.0.borrow().active_count()));
        /// Returns the number of free slots.
        methods.add_method("getFreeCount", |_, this, ()| Ok(this.0.borrow().free_count()));
        /// Returns the total pool capacity.
        methods.add_method("getPoolSize", |_, this, ()| Ok(this.0.borrow().pool_size));
        /// Resets all projectiles to inactive.
        methods.add_method("reset", |_, this, ()| { this.0.borrow_mut().reset(); Ok(()) });
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LuaCombatWorld
// ─────────────────────────────────────────────────────────────────────────────

/// Lua wrapper for `CombatWorld`.
#[derive(Clone)]
pub struct LuaCombatWorld(pub Rc<RefCell<CombatWorld>>);

impl LunaType for LuaCombatWorld {
    const TYPE_NAME: &'static str = "CombatWorld";
    const TYPE_HIERARCHY: &'static [&'static str] = &["CombatWorld"];
}

impl LuaUserData for LuaCombatWorld {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        /// Adds a chassis to the world and returns its index.
        methods.add_method("addChassis", |_, this, ud: LuaAnyUserData| {
            let chassis = ud.borrow::<LuaChassis>()?.0.borrow().clone();
            Ok(this.0.borrow_mut().add_chassis(chassis))
        });
        /// Returns the chassis at the given index, or nil.
        methods.add_method("getChassis", |_, this, index: usize| {
            let borrow = this.0.borrow();
            Ok(borrow.get_chassis(index).cloned().map(|c| LuaChassis(Rc::new(RefCell::new(c)))))
        });
        /// Adds a turret to the world and returns its index.
        methods.add_method("addTurret", |_, this, ud: LuaAnyUserData| {
            let turret = ud.borrow::<LuaTurret>()?.0.borrow().clone();
            Ok(this.0.borrow_mut().add_turret(turret))
        });
        /// Returns the turret at the given index, or nil.
        methods.add_method("getTurret", |_, this, index: usize| {
            let borrow = this.0.borrow();
            Ok(borrow.get_turret(index).cloned().map(|t| LuaTurret(Rc::new(RefCell::new(t)))))
        });
        /// Adds a weapon to the world and returns its index.
        methods.add_method("addWeapon", |_, this, ud: LuaAnyUserData| {
            let weapon = ud.borrow::<LuaWeapon>()?.0.borrow().clone();
            Ok(this.0.borrow_mut().add_weapon(weapon))
        });
        /// Returns the weapon at the given index, or nil.
        methods.add_method("getWeapon", |_, this, index: usize| {
            let borrow = this.0.borrow();
            Ok(borrow.get_weapon(index).cloned().map(|w| LuaWeapon(Rc::new(RefCell::new(w)))))
        });
        /// Adds a projectile pool to the world and returns its index.
        methods.add_method("addPool", |_, this, ud: LuaAnyUserData| {
            let pool = ud.borrow::<LuaProjectilePool>()?.0.borrow().clone();
            Ok(this.0.borrow_mut().add_pool(pool))
        });
        /// Returns the projectile pool at the given index, or nil.
        methods.add_method("getPool", |_, this, index: usize| {
            let borrow = this.0.borrow();
            Ok(borrow.get_pool(index).cloned().map(|p| LuaProjectilePool(Rc::new(RefCell::new(p)))))
        });
        /// Returns the total number of active projectiles across all pools.
        methods.add_method("getActiveProjectileCount", |_, this, ()| {
            Ok(this.0.borrow().active_projectile_count())
        });
        /// Returns the number of non-destroyed chassis.
        methods.add_method("getActiveChassisCount", |_, this, ()| {
            Ok(this.0.borrow().active_chassis_count())
        });
        /// Updates all weapon cooldowns by dt seconds.
        methods.add_method("update", |_, this, dt: f32| {
            this.0.borrow_mut().update(dt);
            Ok(())
        });
        /// Clears all entities and collision groups.
        methods.add_method("reset", |_, this, ()| { this.0.borrow_mut().reset(); Ok(()) });
        /// Removes destroyed chassis (invalidates indices).
        methods.add_method("cleanup", |_, this, ()| { this.0.borrow_mut().cleanup(); Ok(()) });
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

    /// Creates a new `CollisionGroupSet`.
    module.set("newCollisionGroupSet", lua.create_function(|_, ()| {
        Ok(LuaCollisionGroupSet(Rc::new(RefCell::new(CollisionGroupSet::new()))))
    })?)?;

    /// Creates a new `Chassis` with the given body ID and max HP.
    ///
    /// # Parameters
    /// - `body_id` — `integer`: Physics body ID.
    /// - `max_hp` — `number`: Maximum hit points.
    module.set("newChassis", lua.create_function(|_, (body_id, max_hp): (usize, f32)| {
        Ok(LuaChassis(Rc::new(RefCell::new(Chassis::new(body_id, max_hp)))))
    })?)?;

    /// Creates a new `Turret` with the given body and joint IDs.
    ///
    /// # Parameters
    /// - `body_id` — `integer`: Physics body ID.
    /// - `joint_id` — `integer`: Revolute joint ID.
    module.set("newTurret", lua.create_function(|_, (body_id, joint_id): (usize, usize)| {
        Ok(LuaTurret(Rc::new(RefCell::new(Turret::new(body_id, joint_id)))))
    })?)?;

    /// Creates a new fire-rate `Weapon` with the given name.
    ///
    /// # Parameters
    /// - `name` — `string`: Weapon display name.
    module.set("newWeapon", lua.create_function(|_, name: String| {
        Ok(LuaWeapon(Rc::new(RefCell::new(Weapon::new(name)))))
    })?)?;

    /// Creates a new `ProjectilePool` with the given capacity.
    ///
    /// # Parameters
    /// - `size` — `integer`: Pool capacity.
    /// - `proj_type` — `string` optional: Projectile type (default `"ballistic"`).
    module.set("newProjectilePool", lua.create_function(|_, (size, proj_type): (usize, Option<String>)| {
        let pt = proj_type.map(|s| projectile_type_from_str(&s)).unwrap_or(ProjectileType::Ballistic);
        Ok(LuaProjectilePool(Rc::new(RefCell::new(ProjectilePool::new(size, pt)))))
    })?)?;

    /// Creates a new empty `CombatWorld`.
    module.set("newCombatWorld", lua.create_function(|_, ()| {
        Ok(LuaCombatWorld(Rc::new(RefCell::new(CombatWorld::new()))))
    })?)?;

    luna.set("combat", module)?;
    Ok(())
}
