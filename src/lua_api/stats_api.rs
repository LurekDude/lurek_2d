//! Lua API bindings for the `luna.stats` RPG character sheet system.
//!
//! Exposes [`Sheet`] and a global [`StatsRegistry`] as `luna.stats.*` Lua values.

use std::cell::RefCell;
use std::rc::Rc;
use mlua::prelude::*;
use crate::lua_api::lua_types::{add_type_methods, LunaType};
use crate::stats::{ActionPoints, LevelThresholds, Morale, Sheet, Skill, Perk, StatsRegistry};

// ─── Lua wrapper for SheetSheet ──────────────────────────────────────────────

/// Lua-visible wrapper for a character [`Sheet`].
#[derive(Clone)]
pub(crate) struct LuaSheet {
    inner: Rc<RefCell<Sheet>>,
    /// Registry reference for trait/race/class lookups.
    registry: Rc<RefCell<StatsRegistry>>,
}

impl LunaType for LuaSheet {
    const TYPE_NAME: &'static str = "Sheet";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Object"];
}

impl LuaUserData for LuaSheet {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // ─── Attribute definition ──────────────────────────────────────────

        /// `sheet:define(name, base [, opts])` – define a stat attribute.
        methods.add_method("define", |_, this, (name, base, opts): (String, f64, Option<LuaTable>)| {
            let mut s = this.inner.borrow_mut();
            s.define(&name, base);
            if let Some(opts) = opts {
                if let Some(attr) = s.attributes.get_mut(&name) {
                    if let Some(min) = opts.get::<_, f64>("min").ok() { attr.min = min; }
                    if let Some(max) = opts.get::<_, f64>("max").ok() { attr.max = Some(max); }
                    if let Some(regen) = opts.get::<_, f64>("regen").ok() { attr.regen = regen; }
                    if let Some(growth) = opts.get::<_, f64>("growth").ok() { attr.growth = growth; }
                }
            }
            Ok(())
        });

        /// `sheet:get(name)` – get effective value (buffs applied, clamped).
        methods.add_method("get", |_, this, name: String| {
            Ok(this.inner.borrow().get(&name))
        });

        /// `sheet:getBase(name)` – get raw base value.
        methods.add_method("getBase", |_, this, name: String| {
            Ok(this.inner.borrow().get_base(&name))
        });

        /// `sheet:setBase(name, value)` – set the base value.
        methods.add_method("setBase", |_, this, (name, value): (String, f64)| {
            let ok = this.inner.borrow_mut().set_base(&name, value);
            if !ok {
                return Err(LuaError::RuntimeError(format!("sheet:setBase: unknown stat '{}'", name)));
            }
            Ok(())
        });

        /// `sheet:setMin(name, min)` – set the attribute minimum.
        methods.add_method("setMin", |_, this, (name, min): (String, f64)| {
            let mut s = this.inner.borrow_mut();
            if let Some(attr) = s.attributes.get_mut(&name) {
                attr.min = min;
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!("sheet:setMin: unknown stat '{}'", name)))
            }
        });

        /// `sheet:setMax(name, max)` – set the attribute maximum.
        methods.add_method("setMax", |_, this, (name, max): (String, f64)| {
            let mut s = this.inner.borrow_mut();
            if let Some(attr) = s.attributes.get_mut(&name) {
                attr.max = Some(max);
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!("sheet:setMax: unknown stat '{}'", name)))
            }
        });

        /// `sheet:getMin(name)` – get the attribute minimum.
        methods.add_method("getMin", |_, this, name: String| {
            let s = this.inner.borrow();
            s.attributes.get(&name).map(|a| a.min).ok_or_else(|| {
                LuaError::RuntimeError(format!("sheet:getMin: unknown stat '{}'", name))
            })
        });

        /// `sheet:getMax(name)` – get the attribute maximum (nil if unset).
        methods.add_method("getMax", |_, this, name: String| {
            let s = this.inner.borrow();
            match s.attributes.get(&name) {
                Some(a) => Ok(a.max),
                None => Err(LuaError::RuntimeError(format!("sheet:getMax: unknown stat '{}'", name))),
            }
        });

        /// `sheet:setRegen(name, regen)` – set regen rate per second.
        methods.add_method("setRegen", |_, this, (name, regen): (String, f64)| {
            let mut s = this.inner.borrow_mut();
            if let Some(attr) = s.attributes.get_mut(&name) {
                attr.regen = regen;
                Ok(())
            } else {
                Err(LuaError::RuntimeError(format!("sheet:setRegen: unknown stat '{}'", name)))
            }
        });

        /// `sheet:getRegen(name)` – get regen rate.
        methods.add_method("getRegen", |_, this, name: String| {
            let s = this.inner.borrow();
            s.attributes.get(&name).map(|a| a.regen).ok_or_else(|| {
                LuaError::RuntimeError(format!("sheet:getRegen: unknown stat '{}'", name))
            })
        });

        // ─── Buff API ──────────────────────────────────────────────────────

        /// `sheet:addBuff(stat, add, mul, duration, source?)` – returns integer handle.
        methods.add_method("addBuff", |_, this, (stat, add, mul, duration, source): (String, f64, f64, f64, Option<String>)| {
            let handle = this.inner.borrow_mut().add_buff(&stat, add, mul, duration, source.as_deref().unwrap_or(""));
            Ok(handle)
        });

        /// `sheet:removeBuff(handle)` – remove a buff by handle; returns true if found.
        methods.add_method("removeBuff", |_, this, handle: u32| {
            Ok(this.inner.borrow_mut().remove_buff(handle))
        });

        /// `sheet:clearBuffs(stat?)` – remove all buffs, or just those for the given stat.
        methods.add_method("clearBuffs", |_, this, stat: Option<String>| {
            this.inner.borrow_mut().clear_buffs(stat.as_deref());
            Ok(())
        });

        /// `sheet:getBuffs(stat?)` – return an array of buff info tables.
        methods.add_method("getBuffs", |lua, this, stat: Option<String>| {
            let s = this.inner.borrow();
            let tbl = lua.create_table()?;
            let mut i = 1;
            for (handle, buff) in &s.buffs {
                if let Some(ref st) = stat {
                    if &buff.stat != st {
                        continue;
                    }
                }
                let entry = lua.create_table()?;
                entry.set("handle", *handle)?;
                entry.set("stat", buff.stat.clone())?;
                entry.set("add", buff.add)?;
                entry.set("mul", buff.mul)?;
                entry.set("duration", buff.duration)?;
                entry.set("remaining", buff.remaining)?;
                entry.set("source", buff.source.clone())?;
                tbl.set(i, entry)?;
                i += 1;
            }
            Ok(tbl)
        });

        // ─── Trait API ─────────────────────────────────────────────────────

        /// `sheet:addTrait(name)` – apply a globally-defined trait.
        methods.add_method("addTrait", |_, this, name: String| {
            let reg = this.registry.borrow();
            let trait_def = reg.traits.get(&name).ok_or_else(|| {
                LuaError::RuntimeError(format!("sheet:addTrait: unknown trait '{}'", name))
            })?.clone();
            drop(reg);
            let mut s = this.inner.borrow_mut();
            let handles = s.apply_trait_buffs(&name, &trait_def);
            s.active_traits.entry(name).or_default().extend(handles);
            Ok(())
        });

        /// `sheet:removeTrait(name)` – remove a trait's buffs; returns true if found.
        methods.add_method("removeTrait", |_, this, name: String| {
            Ok(this.inner.borrow_mut().remove_trait_buffs(&name))
        });

        /// `sheet:hasTrait(name)` – check if a trait is currently active.
        methods.add_method("hasTrait", |_, this, name: String| {
            Ok(this.inner.borrow().active_traits.contains_key(&name))
        });

        /// `sheet:getActiveTraits()` – list all active trait names.
        methods.add_method("getActiveTraits", |lua, this, ()| {
            let s = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, name) in s.active_traits.keys().enumerate() {
                tbl.set(i + 1, name.clone())?;
            }
            Ok(tbl)
        });

        // ─── Skill API ─────────────────────────────────────────────────────

        /// `sheet:defineSkill(name, opts)` – opts: {maxLevel?, resource?, cost?, cooldown?}
        methods.add_method("defineSkill", |_, this, (name, opts): (String, Option<LuaTable>)| {
            let mut s = this.inner.borrow_mut();
            let mut skill = Skill::new(10, "", 0.0, 0.0);
            if let Some(opts) = opts {
                if let Ok(v) = opts.get::<_, u32>("maxLevel") { skill.max_level = v; }
                if let Ok(v) = opts.get::<_, String>("resource") { skill.resource = v; }
                if let Ok(v) = opts.get::<_, f64>("cost") { skill.cost = v; }
                if let Ok(v) = opts.get::<_, f64>("cooldown") { skill.cooldown = v; }
            }
            s.skills.insert(name, skill);
            Ok(())
        });

        /// `sheet:learnSkill(name)` – unlock / increment skill level.
        methods.add_method("learnSkill", |_, this, name: String| {
            let mut s = this.inner.borrow_mut();
            let skill = s.skills.get_mut(&name).ok_or_else(|| {
                LuaError::RuntimeError(format!("sheet:learnSkill: unknown skill '{}'", name))
            })?;
            if skill.level < skill.max_level {
                skill.level += 1;
            }
            Ok(skill.level)
        });

        /// `sheet:useSkill(name)` – reduce cooldown counter. Returns remaining cooldown.
        methods.add_method("useSkill", |_, this, name: String| {
            let mut s = this.inner.borrow_mut();
            let skill = s.skills.get_mut(&name).ok_or_else(|| {
                LuaError::RuntimeError(format!("sheet:useSkill: unknown skill '{}'", name))
            })?;
            if skill.cooldown_remaining > 0.0 {
                return Err(LuaError::RuntimeError(format!(
                    "sheet:useSkill: '{}' on cooldown ({:.2}s remaining)",
                    name, skill.cooldown_remaining
                )));
            }
            skill.cooldown_remaining = skill.cooldown;
            Ok(skill.cooldown_remaining)
        });

        /// `sheet:getSkillLevel(name)` – get current skill level.
        methods.add_method("getSkillLevel", |_, this, name: String| {
            let s = this.inner.borrow();
            s.skills.get(&name).map(|sk| sk.level).ok_or_else(|| {
                LuaError::RuntimeError(format!("sheet:getSkillLevel: unknown skill '{}'", name))
            })
        });

        /// `sheet:getCooldownRemaining(name)` – get remaining skill cooldown in seconds.
        methods.add_method("getCooldownRemaining", |_, this, name: String| {
            let s = this.inner.borrow();
            s.skills.get(&name).map(|sk| sk.cooldown_remaining).ok_or_else(|| {
                LuaError::RuntimeError(format!("sheet:getCooldownRemaining: unknown skill '{}'", name))
            })
        });

        // ─── Perk API ──────────────────────────────────────────────────────

        /// `sheet:definePerk(name, opts)` – opts: {requireLevel?, traitName?}
        methods.add_method("definePerk", |_, this, (name, opts): (String, Option<LuaTable>)| {
            let require_level = opts.as_ref().and_then(|o| o.get::<_, u32>("requireLevel").ok()).unwrap_or(0);
            let trait_name = opts.as_ref().and_then(|o| o.get::<_, String>("traitName").ok());
            let perk = Perk::new(require_level, trait_name);
            this.inner.borrow_mut().perks.insert(name, perk);
            Ok(())
        });

        /// `sheet:acquirePerk(name)` – acquire the perk if level requirement is met.
        methods.add_method("acquirePerk", |_, this, name: String| {
            let mut s = this.inner.borrow_mut();
            let level = s.level;
            let perk = s.perks.get_mut(&name).ok_or_else(|| {
                LuaError::RuntimeError(format!("sheet:acquirePerk: unknown perk '{}'", name))
            })?;
            if perk.acquired {
                return Err(LuaError::RuntimeError(format!("sheet:acquirePerk: '{}' already acquired", name)));
            }
            if level < perk.require_level {
                return Err(LuaError::RuntimeError(format!(
                    "sheet:acquirePerk: '{}' requires level {} (currently {})",
                    name, perk.require_level, level
                )));
            }
            perk.acquired = true;
            Ok(())
        });

        /// `sheet:hasPerk(name)` – check if perk is acquired.
        methods.add_method("hasPerk", |_, this, name: String| {
            Ok(this.inner.borrow().perks.get(&name).map(|p| p.acquired).unwrap_or(false))
        });

        // ─── Flags ─────────────────────────────────────────────────────────

        /// `sheet:setFlag(name)` – set a boolean flag.
        methods.add_method("setFlag", |_, this, name: String| {
            this.inner.borrow_mut().set_flag(&name);
            Ok(())
        });

        /// `sheet:clearFlag(name)` – clear a flag.
        methods.add_method("clearFlag", |_, this, name: String| {
            this.inner.borrow_mut().clear_flag(&name);
            Ok(())
        });

        /// `sheet:hasFlag(name)` – check if a flag is set.
        methods.add_method("hasFlag", |_, this, name: String| {
            Ok(this.inner.borrow().has_flag(&name))
        });

        /// `sheet:getFlags()` – list all set flag names.
        methods.add_method("getFlags", |lua, this, ()| {
            let tbl = lua.create_table()?;
            let flags = this.inner.borrow().get_flags();
            for (i, f) in flags.into_iter().enumerate() {
                tbl.set(i + 1, f)?;
            }
            Ok(tbl)
        });

        // ─── XP / Level ────────────────────────────────────────────────────

        /// `sheet:addXP(amount)` – add XP, auto-levels up. Returns levels gained.
        methods.add_method("addXP", |_, this, amount: f64| {
            Ok(this.inner.borrow_mut().add_xp(amount))
        });

        /// `sheet:getXP()` – current XP in the current level.
        methods.add_method("getXP", |_, this, ()| {
            Ok(this.inner.borrow().xp)
        });

        /// `sheet:setXP(amount)` – force-set XP (no level-up triggered).
        methods.add_method("setXP", |_, this, amount: f64| {
            this.inner.borrow_mut().xp = amount;
            Ok(())
        });

        /// `sheet:getLevel()` – current character level.
        methods.add_method("getLevel", |_, this, ()| {
            Ok(this.inner.borrow().level)
        });

        /// `sheet:setLevel(n)` – force-set character level.
        methods.add_method("setLevel", |_, this, n: u32| {
            this.inner.borrow_mut().level = n;
            Ok(())
        });

        /// `sheet:setLevelThresholds(t)` – t is an array of XP thresholds OR table with base/increment.
        methods.add_method("setLevelThresholds", |_, this, t: LuaTable| {
            // Detect linear vs table
            let maybe_base = t.get::<_, f64>("base");
            if let Ok(base) = maybe_base {
                let increment: f64 = t.get("increment").unwrap_or(base);
                this.inner.borrow_mut().level_thresholds = LevelThresholds::Linear { base, increment };
            } else {
                let mut thresholds = Vec::new();
                let mut i = 1;
                while let Ok(v) = t.get::<_, f64>(i) {
                    thresholds.push(v);
                    i += 1;
                }
                this.inner.borrow_mut().level_thresholds = LevelThresholds::Table(thresholds);
            }
            Ok(())
        });

        // ─── Use tracking ──────────────────────────────────────────────────

        /// `sheet:recordUse(name)` – record a use for use-based growth.
        methods.add_method("recordUse", |_, this, name: String| {
            this.inner.borrow_mut().record_use(&name);
            Ok(())
        });

        /// `sheet:getUseCount(name)` – number of times a stat was used.
        methods.add_method("getUseCount", |_, this, name: String| {
            Ok(this.inner.borrow().use_counts.get(&name).copied().unwrap_or(0))
        });

        // ─── Action Points ─────────────────────────────────────────────────

        /// `sheet:setActionPoints(max)` – initialise / reset action points.
        methods.add_method("setActionPoints", |_, this, max: f64| {
            this.inner.borrow_mut().action_points = Some(ActionPoints::new(max));
            Ok(())
        });

        /// `sheet:getActionPoints()` – returns current, max.
        methods.add_method("getActionPoints", |_, this, ()| {
            let s = this.inner.borrow();
            if let Some(ap) = &s.action_points {
                Ok((ap.current, ap.max))
            } else {
                Ok((0.0, 0.0))
            }
        });

        /// `sheet:spendActionPoints(n)` – spend n action points; errors if insufficient.
        methods.add_method("spendActionPoints", |_, this, n: f64| {
            let mut s = this.inner.borrow_mut();
            let ap = s.action_points.as_mut().ok_or_else(|| {
                LuaError::RuntimeError("sheet:spendActionPoints: action points not initialised".to_string())
            })?;
            if ap.current < n {
                return Err(LuaError::RuntimeError(format!(
                    "sheet:spendActionPoints: not enough AP ({:.1} < {:.1})", ap.current, n
                )));
            }
            ap.current -= n;
            Ok(ap.current)
        });

        /// `sheet:beginTurn()` – restore action points to max.
        methods.add_method("beginTurn", |_, this, ()| {
            let mut s = this.inner.borrow_mut();
            if let Some(ap) = s.action_points.as_mut() {
                ap.current = ap.max;
            }
            Ok(())
        });

        // ─── Morale ────────────────────────────────────────────────────────

        /// `sheet:setMorale(max)` – initialise morale with the given max.
        methods.add_method("setMorale", |_, this, max: f64| {
            this.inner.borrow_mut().morale = Some(Morale::new(max));
            Ok(())
        });

        /// `sheet:getMorale()` – returns current, max.
        methods.add_method("getMorale", |_, this, ()| {
            let s = this.inner.borrow();
            if let Some(m) = &s.morale {
                Ok((m.current, m.max))
            } else {
                Ok((0.0, 0.0))
            }
        });

        /// `sheet:adjustMorale(delta)` – add delta to current morale (clamped 0..max).
        methods.add_method("adjustMorale", |_, this, delta: f64| {
            let mut s = this.inner.borrow_mut();
            let m = s.morale.as_mut().ok_or_else(|| {
                LuaError::RuntimeError("sheet:adjustMorale: morale not initialised".to_string())
            })?;
            m.current = (m.current + delta).clamp(0.0, m.max);
            Ok(m.current)
        });

        /// `sheet:setPanicThreshold(val)` – set the morale level below which the unit panics.
        methods.add_method("setPanicThreshold", |_, this, val: f64| {
            let mut s = this.inner.borrow_mut();
            let m = s.morale.as_mut().ok_or_else(|| {
                LuaError::RuntimeError("sheet:setPanicThreshold: morale not initialised".to_string())
            })?;
            m.panic_threshold = val;
            Ok(())
        });

        /// `sheet:setBerserkThreshold(val)` – set the morale level below which the unit goes berserk.
        methods.add_method("setBerserkThreshold", |_, this, val: f64| {
            let mut s = this.inner.borrow_mut();
            let m = s.morale.as_mut().ok_or_else(|| {
                LuaError::RuntimeError("sheet:setBerserkThreshold: morale not initialised".to_string())
            })?;
            m.berserk_threshold = val;
            Ok(())
        });

        /// `sheet:checkMorale()` – returns "panic", "berserk", or nil.
        methods.add_method("checkMorale", |_, this, ()| {
            Ok(this.inner.borrow_mut().check_morale())
        });

        // ─── Resistances / Damage ──────────────────────────────────────────

        /// `sheet:setResistance(damageType, value)` – set a resistance (0.0..1.0).
        methods.add_method("setResistance", |_, this, (dtype, val): (String, f64)| {
            this.inner.borrow_mut().resistances.insert(dtype, val.clamp(0.0, 1.0));
            Ok(())
        });

        /// `sheet:getResistance(damageType)` – get resistance value.
        methods.add_method("getResistance", |_, this, dtype: String| {
            Ok(this.inner.borrow().resistances.get(&dtype).copied().unwrap_or(0.0))
        });

        /// `sheet:applyDamage(stat, amount, damageType?)` – apply resistance-reduced damage.
        methods.add_method("applyDamage", |_, this, (stat, amount, dtype): (String, f64, Option<String>)| {
            let actual = this.inner.borrow_mut().apply_damage(&stat, amount, dtype.as_deref());
            Ok(actual)
        });

        // ─── Encumbrance ───────────────────────────────────────────────────

        /// `sheet:setEncumbrance(current, max)` – set encumbrance values.
        methods.add_method("setEncumbrance", |_, this, (current, max): (f64, f64)| {
            this.inner.borrow_mut().encumbrance = Some((current, max));
            Ok(())
        });

        /// `sheet:getEncumbrance()` – returns current, max.
        methods.add_method("getEncumbrance", |_, this, ()| {
            let s = this.inner.borrow();
            if let Some((c, m)) = s.encumbrance {
                Ok((c, m))
            } else {
                Ok((0.0, 0.0))
            }
        });

        /// `sheet:isEncumbered()` – returns true if current > max.
        methods.add_method("isEncumbered", |_, this, ()| {
            let s = this.inner.borrow();
            Ok(s.encumbrance.map(|(c, m)| c > m).unwrap_or(false))
        });

        // ─── Initiative ────────────────────────────────────────────────────

        /// `sheet:setInitiative(val)` – set base initiative.
        methods.add_method("setInitiative", |_, this, val: f64| {
            this.inner.borrow_mut().initiative = val;
            Ok(())
        });

        /// `sheet:getInitiative()` – get base initiative.
        methods.add_method("getInitiative", |_, this, ()| {
            Ok(this.inner.borrow().initiative)
        });

        // ─── Update / Loop ─────────────────────────────────────────────────

        /// `sheet:update(dt)` – tick buff durations, skill cooldowns, and regen.
        methods.add_method("getStatNames", |lua, this, ()| {
            let names = this.inner.borrow().get_stat_names();
            let t = lua.create_table()?;
            for (i, name) in names.into_iter().enumerate() { t.set(i + 1, name)?; }
            Ok(t)
        });
        methods.add_method("getBuffCount", |_, this, stat: Option<String>| {
            Ok(this.inner.borrow().get_buff_count(stat.as_deref()))
        });
        methods.add_method("recoverActionPoints", |_, this, amount: f64| {
            Ok(this.inner.borrow_mut().recover_action_points(amount))
        });
        methods.add_method("update", |_, this, dt: f64| {
            this.inner.borrow_mut().update(dt);
            Ok(())
        });

        // ─── Snapshot / Restore ────────────────────────────────────────────

        /// `sheet:snapshot()` – return a serialisable Lua table of all sheet state.
        methods.add_method("snapshot", |lua, this, ()| {
            let s = this.inner.borrow();
            let snap = lua.create_table()?;

            // Attributes
            let attrs = lua.create_table()?;
            for (i, (name, base, min, max, regen, growth)) in s.snapshot_attributes().into_iter().enumerate() {
                let entry = lua.create_table()?;
                entry.set("name", name)?;
                entry.set("base", base)?;
                entry.set("min", min)?;
                if let Some(mx) = max { entry.set("max", mx)?; }
                entry.set("regen", regen)?;
                entry.set("growth", growth)?;
                attrs.set(i + 1, entry)?;
            }
            snap.set("attributes", attrs)?;

            snap.set("xp", s.xp)?;
            snap.set("level", s.level)?;

            // Flags
            let flags = lua.create_table()?;
            for (i, f) in s.get_flags().into_iter().enumerate() {
                flags.set(i + 1, f)?;
            }
            snap.set("flags", flags)?;

            // Action Points
            if let Some(ap) = &s.action_points {
                let t = lua.create_table()?;
                t.set("current", ap.current)?;
                t.set("max", ap.max)?;
                snap.set("actionPoints", t)?;
            }

            // Morale
            if let Some(m) = &s.morale {
                let t = lua.create_table()?;
                t.set("current", m.current)?;
                t.set("max", m.max)?;
                t.set("panic_threshold", m.panic_threshold)?;
                t.set("berserk_threshold", m.berserk_threshold)?;
                snap.set("morale", t)?;
            }

            // Resistances
            let res = lua.create_table()?;
            for (k, v) in &s.resistances {
                res.set(k.clone(), *v)?;
            }
            snap.set("resistances", res)?;

            Ok(snap)
        });

        /// `sheet:restore(snapshot)` – restore from a snapshot table (attributes, xp, level, flags).
        methods.add_method("restore", |_, this, snap: LuaTable| {
            let mut s = this.inner.borrow_mut();
            if let Ok(attrs) = snap.get::<_, LuaTable>("attributes") {
                for entry in attrs.sequence_values::<LuaTable>() {
                    if let Ok(entry) = entry {
                        let name: String = entry.get("name")?;
                        let base: f64 = entry.get("base")?;
                        s.define(&name, base);
                        if let Some(attr) = s.attributes.get_mut(&name) {
                            if let Ok(min) = entry.get::<_, f64>("min") { attr.min = min; }
                            if let Ok(max) = entry.get::<_, f64>("max") { attr.max = Some(max); }
                            if let Ok(regen) = entry.get::<_, f64>("regen") { attr.regen = regen; }
                            if let Ok(growth) = entry.get::<_, f64>("growth") { attr.growth = growth; }
                        }
                    }
                }
            }
            if let Ok(xp) = snap.get::<_, f64>("xp") { s.xp = xp; }
            if let Ok(lvl) = snap.get::<_, u32>("level") { s.level = lvl; }
            if let Ok(flags) = snap.get::<_, LuaTable>("flags") {
                s.flags.clear();
                for f in flags.sequence_values::<String>() {
                    if let Ok(name) = f { s.set_flag(&name); }
                }
            }
            if let Ok(ap) = snap.get::<_, LuaTable>("actionPoints") {
                let max: f64 = ap.get("max").unwrap_or(0.0);
                let current: f64 = ap.get("current").unwrap_or(max);
                let ap_ref = s.action_points.get_or_insert(ActionPoints::new(max));
                ap_ref.max = max;
                ap_ref.current = current;
            }
            if let Ok(m) = snap.get::<_, LuaTable>("morale") {
                let max: f64 = m.get("max").unwrap_or(100.0);
                let current: f64 = m.get("current").unwrap_or(max);
                let panic_threshold: f64 = m.get("panic_threshold").unwrap_or(25.0);
                let berserk_threshold: f64 = m.get("berserk_threshold").unwrap_or(10.0);
                let morale_ref = s.morale.get_or_insert(Morale::new(max));
                morale_ref.max = max;
                morale_ref.current = current;
                morale_ref.panic_threshold = panic_threshold;
                morale_ref.berserk_threshold = berserk_threshold;
            }
            if let Ok(res) = snap.get::<_, LuaTable>("resistances") {
                s.resistances.clear();
                for pair in res.pairs::<String, f64>() {
                    if let Ok((k, v)) = pair { s.resistances.insert(k, v); }
                }
            }
            Ok(())
        });
    }
}

// ─── Registration ─────────────────────────────────────────────────────────────

/// Register the `luna.stats` module into the Lua state.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let registry = Rc::new(RefCell::new(StatsRegistry::new()));

    let module = lua.create_table()?;

    // luna.stats.newSheet()
    {
        let registry = Rc::clone(&registry);
        module.set(
            "newSheet",
            lua.create_function(move |_, ()| {
                Ok(LuaSheet {
                    inner: Rc::new(RefCell::new(Sheet::new())),
                    registry: Rc::clone(&registry),
                })
            })?,
        )?;
    }

    // luna.stats.defineTrait(name, opts)
    // opts = {buffs = [ {stat, add?, mul?}, ... ]}
    {
        let registry = Rc::clone(&registry);
        module.set(
            "defineTrait",
            lua.create_function(move |_, (name, opts): (String, LuaTable)| {
                let mut buffs_vec = Vec::new();
                if let Ok(buffs_tbl) = opts.get::<_, LuaTable>("buffs") {
                    for entry in buffs_tbl.sequence_values::<LuaTable>() {
                        if let Ok(entry) = entry {
                            let stat: String = entry.get("stat")?;
                            let add: f64 = entry.get("add").unwrap_or(0.0);
                            let mul: f64 = entry.get("mul").unwrap_or(1.0);
                            buffs_vec.push((stat, add, mul));
                        }
                    }
                }
                registry.borrow_mut().define_trait(&name, buffs_vec);
                Ok(())
            })?,
        )?;
    }

    // luna.stats.defineRace(name, opts)
    {
        let registry = Rc::clone(&registry);
        module.set(
            "defineRace",
            lua.create_function(move |_, (name, opts): (String, LuaTable)| {
                let mut bases = std::collections::HashMap::new();
                if let Ok(btbl) = opts.get::<_, LuaTable>("bases") {
                    for pair in btbl.pairs::<String, f64>() {
                        if let Ok((k, v)) = pair { bases.insert(k, v); }
                    }
                }
                let mut trait_names = Vec::new();
                if let Ok(ttbl) = opts.get::<_, LuaTable>("traits") {
                    for t in ttbl.sequence_values::<String>() {
                        if let Ok(tn) = t { trait_names.push(tn); }
                    }
                }
                registry.borrow_mut().define_race(&name, bases, trait_names);
                Ok(())
            })?,
        )?;
    }

    // luna.stats.defineClass(name, opts)
    {
        let registry = Rc::clone(&registry);
        module.set(
            "defineClass",
            lua.create_function(move |_, (name, opts): (String, LuaTable)| {
                let mut bases = std::collections::HashMap::new();
                if let Ok(btbl) = opts.get::<_, LuaTable>("bases") {
                    for pair in btbl.pairs::<String, f64>() {
                        if let Ok((k, v)) = pair { bases.insert(k, v); }
                    }
                }
                let mut trait_names = Vec::new();
                if let Ok(ttbl) = opts.get::<_, LuaTable>("traits") {
                    for t in ttbl.sequence_values::<String>() {
                        if let Ok(tn) = t { trait_names.push(tn); }
                    }
                }
                registry.borrow_mut().define_class(&name, bases, trait_names);
                Ok(())
            })?,
        )?;
    }

    // luna.stats.getTraitNames()
    {
        let registry = Rc::clone(&registry);
        module.set(
            "getTraitNames",
            lua.create_function(move |lua, ()| {
                let t = lua.create_table()?;
                for (i, name) in registry.borrow().traits.keys().enumerate() {
                    t.set(i + 1, name.clone())?;
                }
                Ok(t)
            })?,
        )?;
    }

    // luna.stats.getRaceNames()
    {
        let registry = Rc::clone(&registry);
        module.set(
            "getRaceNames",
            lua.create_function(move |lua, ()| {
                let t = lua.create_table()?;
                for (i, name) in registry.borrow().races.keys().enumerate() {
                    t.set(i + 1, name.clone())?;
                }
                Ok(t)
            })?,
        )?;
    }

    // luna.stats.getClassNames()
    {
        let registry = Rc::clone(&registry);
        module.set(
            "getClassNames",
            lua.create_function(move |lua, ()| {
                let t = lua.create_table()?;
                for (i, name) in registry.borrow().classes.keys().enumerate() {
                    t.set(i + 1, name.clone())?;
                }
                Ok(t)
            })?,
        )?;
    }

    // luna.stats.applyArchetypes(sheet, race, class)
    {
        let registry = Rc::clone(&registry);
        module.set(
            "applyArchetypes",
            lua.create_function(move |_, (sheet_ud, race, class): (LuaAnyUserData, Option<String>, Option<String>)| {
                let sheet = sheet_ud.borrow::<LuaSheet>()?;
                let reg = registry.borrow();
                reg.apply_archetypes(
                    &mut sheet.inner.borrow_mut(),
                    race.as_deref(),
                    class.as_deref(),
                );
                Ok(())
            })?,
        )?;
    }

    luna.set("stats", module)?;
    Ok(())
}
