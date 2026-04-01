"""Write src/lua_api/combat_api.rs"""

content = r"""//! Lua bindings for `luna.combat.*`.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::combat::{
    CombatAction, CombatBattle, CombatResult, Combatant, StatusEffect,
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

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("getDuration", |_, this, ()| Ok(this.0.borrow().duration));
        methods.add_method("setDuration", |_, this, v: i32| { this.0.borrow_mut().duration = v; Ok(()) });
        methods.add_method("getStacks", |_, this, ()| Ok(this.0.borrow().stacks));
        methods.add_method("setStacks", |_, this, v: u32| { this.0.borrow_mut().stacks = v; Ok(()) });
        methods.add_method("isExpired", |_, this, ()| Ok(this.0.borrow().is_expired()));
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

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("getBaseDamage", |_, this, ()| Ok(this.0.borrow().base_damage));
        methods.add_method("setBaseDamage", |_, this, v: f64| { this.0.borrow_mut().base_damage = v; Ok(()) });
        methods.add_method("getDamageType", |_, this, ()| Ok(this.0.borrow().damage_type.clone()));
        methods.add_method("setDamageType", |_, this, v: String| { this.0.borrow_mut().damage_type = v; Ok(()) });
        methods.add_method("getAccuracy", |_, this, ()| Ok(this.0.borrow().accuracy));
        methods.add_method("setAccuracy", |_, this, v: f64| { this.0.borrow_mut().accuracy = v.clamp(0.0, 1.0); Ok(()) });
        methods.add_method("getCooldown", |_, this, ()| Ok(this.0.borrow().cooldown));
        methods.add_method("setCooldown", |_, this, v: u32| { this.0.borrow_mut().cooldown = v; Ok(()) });
        methods.add_method("getCurrentCooldown", |_, this, ()| Ok(this.0.borrow().current_cooldown));
        methods.add_method("isReady", |_, this, ()| Ok(this.0.borrow().is_ready()));
        methods.add_method("tickCooldown", |_, this, ()| { this.0.borrow_mut().tick_cooldown(); Ok(()) });
        methods.add_method("getCostMp", |_, this, ()| Ok(this.0.borrow().cost_mp));
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

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("getTeam", |_, this, ()| Ok(this.0.borrow().team.clone()));
        methods.add_method("setTeam", |_, this, v: String| { this.0.borrow_mut().team = v; Ok(()) });
        methods.add_method("getHp", |_, this, ()| Ok(this.0.borrow().hp));
        methods.add_method("setHp", |_, this, v: f64| { this.0.borrow_mut().hp = v; Ok(()) });
        methods.add_method("getMaxHp", |_, this, ()| Ok(this.0.borrow().max_hp));
        methods.add_method("setMaxHp", |_, this, v: f64| { this.0.borrow_mut().max_hp = v; Ok(()) });
        methods.add_method("getMp", |_, this, ()| Ok(this.0.borrow().mp));
        methods.add_method("setMp", |_, this, v: f64| { this.0.borrow_mut().mp = v; Ok(()) });
        methods.add_method("getMaxMp", |_, this, ()| Ok(this.0.borrow().max_mp));
        methods.add_method("setMaxMp", |_, this, v: f64| { this.0.borrow_mut().max_mp = v; Ok(()) });
        methods.add_method("getSpeed", |_, this, ()| Ok(this.0.borrow().speed));
        methods.add_method("setSpeed", |_, this, v: f64| { this.0.borrow_mut().speed = v; Ok(()) });
        methods.add_method("getLevel", |_, this, ()| Ok(this.0.borrow().level));
        methods.add_method("isAlive", |_, this, ()| Ok(this.0.borrow().is_alive()));

        methods.add_method("takeDamage", |_, this, (amount, dtype): (f64, Option<String>)| {
            let dtype = dtype.unwrap_or_else(|| "physical".to_string());
            Ok(this.0.borrow_mut().take_damage(amount, &dtype))
        });
        methods.add_method("heal", |_, this, amount: f64| {
            Ok(this.0.borrow_mut().heal(amount))
        });

        methods.add_method("getStat", |_, this, name: String| Ok(this.0.borrow().get_stat(&name)));
        methods.add_method("setStat", |_, this, (name, v): (String, f64)| {
            this.0.borrow_mut().set_stat(name, v); Ok(())
        });
        methods.add_method("getResistance", |_, this, dtype: String| {
            Ok(*this.0.borrow().resistances.get(&dtype).unwrap_or(&1.0))
        });
        methods.add_method("setResistance", |_, this, (dtype, v): (String, f64)| {
            this.0.borrow_mut().resistances.insert(dtype, v); Ok(())
        });

        // Status effects
        methods.add_method("addStatus", |_, this, (name, duration): (String, Option<i32>)| {
            let effect = StatusEffect::new(name, duration.unwrap_or(-1));
            this.0.borrow_mut().add_status(effect);
            Ok(())
        });
        methods.add_method("removeStatus", |_, this, name: String| {
            this.0.borrow_mut().remove_status(&name); Ok(())
        });
        methods.add_method("hasStatus", |_, this, name: String| {
            Ok(this.0.borrow().has_status(&name))
        });
        methods.add_method("tickStatuses", |lua, this, ()| {
            let expired = this.0.borrow_mut().tick_statuses();
            let t = lua.create_sequence_from(expired.into_iter())?;
            Ok(t)
        });
        methods.add_method("getStatuses", |lua, this, ()| {
            let borrow = this.0.borrow();
            let t = lua.create_table()?;
            for (i, e) in borrow.status_effects.iter().enumerate() {
                let st = lua.create_table()?;
                st.set("name", e.name.clone())?;
                st.set("duration", e.duration)?;
                st.set("stacks", e.stacks)?;
                t.set(i + 1, st)?;
            }
            Ok(t)
        });

        // Actions
        methods.add_method("addAction", |_, this, action: LuaAnyUserData| {
            let action_clone = action.borrow::<LuaCombatAction>()?.0.borrow().clone();
            this.0.borrow_mut().add_action(action_clone);
            Ok(())
        });
        methods.add_method("hasAction", |_, this, name: String| {
            Ok(this.0.borrow().get_action(&name).is_some())
        });
        methods.add_method("tickCooldowns", |_, this, ()| {
            let mut borrow = this.0.borrow_mut();
            for action in &mut borrow.actions { action.tick_cooldown(); }
            Ok(())
        });

        methods.add_method("getMeta", |_, this, key: String| {
            let borrow = this.0.borrow();
            let val = borrow.metadata.get(&key).cloned();
            drop(borrow);
            Ok(val)
        });
        methods.add_method("setMeta", |_, this, (k, v): (String, String)| {
            this.0.borrow_mut().metadata.insert(k, v); Ok(())
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

        methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));
        methods.add_method("getCount", |_, this, ()| Ok(this.0.borrow().count()));
        methods.add_method("getTurnCount", |_, this, ()| Ok(this.0.borrow().turn_count));
        methods.add_method("isOver", |_, this, ()| Ok(this.0.borrow().is_over()));
        methods.add_method("getWinner", |_, this, ()| Ok(this.0.borrow().winner_team.clone()));

        methods.add_method("addCombatant", |_, this, combatant: LuaAnyUserData| {
            let c = combatant.borrow::<LuaCombatant>()?.0.borrow().clone();
            this.0.borrow_mut().add_combatant(c);
            Ok(())
        });

        methods.add_method("getCombatant", |_, this, name: String| {
            let borrow = this.0.borrow();
            let c = borrow.get_combatant(&name).cloned();
            drop(borrow);
            Ok(c.map(|c| LuaCombatant(Rc::new(RefCell::new(c)))))
        });

        methods.add_method("sortInitiative", |_, this, ()| {
            this.0.borrow_mut().sort_initiative(); Ok(())
        });

        methods.add_method("getCurrentCombatant", |_, this, ()| {
            let borrow = this.0.borrow();
            let c = borrow.current_combatant().cloned();
            drop(borrow);
            Ok(c.map(|c| LuaCombatant(Rc::new(RefCell::new(c)))))
        });

        methods.add_method("nextTurn", |_, this, ()| {
            Ok(this.0.borrow_mut().next_turn())
        });

        methods.add_method("attack", |lua, this, (attacker, action, target): (String, String, String)| {
            let result = this.0.borrow_mut().attack(&attacker, &action, &target);
            if let Some(r) = result {
                let t = lua.create_table()?;
                t.set("attacker", r.attacker)?;
                t.set("target", r.target)?;
                t.set("action", r.action)?;
                t.set("hit", r.hit)?;
                t.set("damage", r.damage)?;
                t.set("damageType", r.damage_type)?;
                t.set("targetDied", r.target_died)?;
                t.set("message", r.message)?;
                Ok(LuaValue::Table(t))
            } else {
                Ok(LuaValue::Nil)
            }
        });

        methods.add_method("getAliveNames", |lua, this, ()| {
            let names = this.0.borrow().alive_names();
            let t = lua.create_sequence_from(names.into_iter())?;
            Ok(t)
        });

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

    module.set("newCombatant", lua.create_function(|_, name: String| {
        Ok(LuaCombatant(Rc::new(RefCell::new(Combatant::new(name)))))
    })?)?;

    module.set("newAction", lua.create_function(|_, name: String| {
        Ok(LuaCombatAction(Rc::new(RefCell::new(CombatAction::new(name)))))
    })?)?;

    module.set("newStatusEffect", lua.create_function(|_, (name, duration): (String, Option<i32>)| {
        Ok(LuaStatusEffect(Rc::new(RefCell::new(StatusEffect::new(name, duration.unwrap_or(-1))))))
    })?)?;

    module.set("newBattle", lua.create_function(|_, name: Option<String>| {
        Ok(LuaCombatBattle(Rc::new(RefCell::new(CombatBattle::new(name.unwrap_or_default())))))
    })?)?;

    luna.set("combat", module)?;
    Ok(())
}
"""

with open('src/lua_api/combat_api.rs', 'w', encoding='utf-8') as f:
    f.write(content)
print('combat_api.rs written')
