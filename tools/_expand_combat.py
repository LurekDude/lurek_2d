"""Expand combat module with:
Domain (mod.rs):
  - CombatBattle: add `log: Vec<String>` field, push_log(), get_log(), remove_combatant(), force_end()
  - Combatant: action_names(), status_names(), hp_percent(), mp_percent()
API (combat_api.rs):
  - LuaCombatant: getActionNames, getStatusNames, getHpPercent, getMpPercent
  - LuaCombatBattle: getLog, addToLog, removeCombatant, forceEnd
Tests (combat_tests.rs):
  - tests for all new methods
"""
import re

# ---- Domain ----------------------------------------------------------------
MOD = r"src\combat\mod.rs"
with open(MOD, "r", encoding="utf-8") as f:
    dom = f.read()

# 1) Add log field to CombatBattle struct
dom = dom.replace(
    "    pub over: bool,\n    pub winner_team: Option<String>,\n}",
    "    pub over: bool,\n    pub winner_team: Option<String>,\n    pub log: Vec<String>,\n}",
    1
)

# 2) Initialize log field in CombatBattle::new()
dom = dom.replace(
    "            over: false,\n            winner_team: None,\n        }\n    }\n\n    pub fn add_combatant",
    "            over: false,\n            winner_team: None,\n            log: Vec::new(),\n        }\n    }\n\n    pub fn add_combatant",
    1
)

# 3) Add new Combatant methods before the separator comment
combatant_extra = """
    /// Returns the names of all loaded combat actions.
    pub fn action_names(&self) -> Vec<String> {
        self.actions.iter().map(|a| a.name.clone()).collect()
    }

    /// Returns the names of all active status effects.
    pub fn status_names(&self) -> Vec<String> {
        self.status_effects.iter().map(|s| s.name.clone()).collect()
    }

    /// Returns HP as a percentage 0..=100.
    pub fn hp_percent(&self) -> f64 {
        if self.max_hp <= 0.0 { return 0.0; }
        (self.hp / self.max_hp * 100.0).clamp(0.0, 100.0)
    }

    /// Returns MP as a percentage 0..=100.
    pub fn mp_percent(&self) -> f64 {
        if self.max_mp <= 0.0 { return 0.0; }
        (self.mp / self.max_mp * 100.0).clamp(0.0, 100.0)
    }
"""

dom = dom.replace(
    "    pub fn set_stat(&mut self, name: String, value: f64) {\n        self.stats.insert(name, value);\n    }\n}",
    "    pub fn set_stat(&mut self, name: String, value: f64) {\n        self.stats.insert(name, value);\n    }\n" + combatant_extra + "\n}",
    1
)

# 4) Add CombatBattle methods before #[cfg(test)]
battle_extra = """
    /// Append a message to the combat log.
    pub fn push_log(&mut self, msg: impl Into<String>) {
        self.log.push(msg.into());
    }

    /// Return all combat log messages.
    pub fn get_log(&self) -> &[String] {
        &self.log
    }

    /// Remove a combatant by name. Returns true if found and removed.
    pub fn remove_combatant(&mut self, name: &str) -> bool {
        if let Some(pos) = self.combatants.iter().position(|c| c.name == name) {
            self.combatants.remove(pos);
            true
        } else {
            false
        }
    }

    /// Manually end the battle with an optional winning team.
    pub fn force_end(&mut self, winner: Option<String>) {
        self.over = true;
        self.winner_team = winner;
    }
"""

dom = dom.replace(
    "    pub fn get_all_names(&self) -> Vec<String> {\n        self.combatants.iter().map(|c| c.name.clone()).collect()\n    }\n}",
    "    pub fn get_all_names(&self) -> Vec<String> {\n        self.combatants.iter().map(|c| c.name.clone()).collect()\n    }\n" + battle_extra + "\n}",
    1
)

with open(MOD, "w", encoding="utf-8") as f:
    f.write(dom)
print("combat/mod.rs updated")

# ---- Lua API ----------------------------------------------------------------
API = r"src\lua_api\combat_api.rs"
with open(API, "r", encoding="utf-8") as f:
    api = f.read()

# Add to LuaCombatant add_methods block - insert after `tickCooldowns` method
combatant_api_extra = '''        methods.add_method("getActionNames", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, name) in this.0.borrow().action_names().into_iter().enumerate() {
                t.set(i + 1, name)?;
            }
            Ok(t)
        });
        methods.add_method("getStatusNames", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, name) in this.0.borrow().status_names().into_iter().enumerate() {
                t.set(i + 1, name)?;
            }
            Ok(t)
        });
        methods.add_method("getHpPercent", |_, this, ()| {
            Ok(this.0.borrow().hp_percent())
        });
        methods.add_method("getMpPercent", |_, this, ()| {
            Ok(this.0.borrow().mp_percent())
        });
'''

# Find the LuaCombatant add_methods block end (before LuaCombatBattle add_methods)
# Insert before: `methods.add_method("getName", |_, this, ()| Ok(this.0.borrow().name.clone()));`  (the last getName which belongs to Battle)
# We'll insert after the last combatant method (tickCooldowns or setMeta) and before the Battle type decl

# Insert after `getMeta` / `setMeta` block for LuaCombatant
# The combatant's setMeta is: `methods.add_method("setMeta", ...` then `});` then close brace `}`
# Then there's `// LuaCombatBattle` or similar
# Let's find the MutexGuard pattern - setCooldowns is last combatant method
# Actually let's look for: the closing of the Combatant impl (there's a specific pattern)

# The safest way: insert our new combatant methods right before the LuaCombatBattle type definition
# Search for: `\nstruct LuaCombatBattle`
api = api.replace(
    "\nstruct LuaCombatBattle(",
    combatant_api_extra + "\nstruct LuaCombatBattle(",
    1,
)

# Add to LuaCombatBattle add_methods - insert before closing of battle's add_methods
battle_api_extra = '''        methods.add_method("getLog", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, msg) in this.0.borrow().log.iter().enumerate() {
                t.set(i + 1, msg.clone())?;
            }
            Ok(t)
        });
        methods.add_method("addToLog", |_, this, msg: String| {
            this.0.borrow_mut().push_log(msg);
            Ok(())
        });
        methods.add_method("removeCombatant", |_, this, name: String| {
            Ok(this.0.borrow_mut().remove_combatant(&name))
        });
        methods.add_method("forceEnd", |_, this, winner: Option<String>| {
            this.0.borrow_mut().force_end(winner);
            Ok(())
        });
'''

# Insert before the last closing of the battle impl block
# We look for `getAllNames` closing pattern, then the register fn
api = api.replace(
    '        methods.add_method("getAllNames", |lua, this, ()| {',
    battle_api_extra + '        methods.add_method("getAllNames", |lua, this, ()| {',
    1,
)

with open(API, "w", encoding="utf-8") as f:
    f.write(api)
print("combat_api.rs updated")

# ---- Tests ----------------------------------------------------------------
TEST = r"tests\combat_tests.rs"
with open(TEST, "r", encoding="utf-8") as f:
    tst = f.read()

new_tests = r'''
#[test]
fn combatant_hp_mp_percent() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.combat.newCombatant("hero")
        c:setHp(50.0)
        c:setMaxHp(200.0)
        c:setMp(25.0)
        c:setMaxMp(100.0)
        assert(math.abs(c:getHpPercent() - 25.0) < 0.01, "hp 25%")
        assert(math.abs(c:getMpPercent() - 25.0) < 0.01, "mp 25%")
    "#).exec().unwrap();
}

#[test]
fn combatant_action_names() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.combat.newCombatant("knight")
        local a1 = luna.combat.newAction("slash")
        local a2 = luna.combat.newAction("shield_bash")
        c:addAction(a1)
        c:addAction(a2)
        local names = c:getActionNames()
        assert(#names == 2, "2 actions")
        local found = {}
        for _, n in ipairs(names) do found[n] = true end
        assert(found["slash"], "slash present")
        assert(found["shield_bash"], "shield_bash present")
    "#).exec().unwrap();
}

#[test]
fn combatant_status_names() {
    let lua = make_vm();
    lua.load(r#"
        local c = luna.combat.newCombatant("enemy")
        c:addStatus("poison", 3)
        c:addStatus("slow", 2)
        local names = c:getStatusNames()
        assert(#names == 2, "2 statuses")
        local found = {}
        for _, n in ipairs(names) do found[n] = true end
        assert(found["poison"], "poison present")
        assert(found["slow"], "slow present")
    "#).exec().unwrap();
}

#[test]
fn battle_combat_log() {
    let lua = make_vm();
    lua.load(r#"
        local b = luna.combat.newBattle("log_test")
        b:addToLog("battle started")
        b:addToLog("hero attacks goblin")
        local log = b:getLog()
        assert(#log == 2, "2 log entries")
        assert(log[1] == "battle started", "first message")
        assert(log[2] == "hero attacks goblin", "second message")
    "#).exec().unwrap();
}

#[test]
fn battle_remove_combatant() {
    let lua = make_vm();
    lua.load(r#"
        local b = luna.combat.newBattle()
        local c1 = luna.combat.newCombatant("hero")
        local c2 = luna.combat.newCombatant("goblin")
        b:addCombatant(c1)
        b:addCombatant(c2)
        assert(b:getCount() == 2, "2 combatants")
        local ok = b:removeCombatant("goblin")
        assert(ok, "removed ok")
        assert(b:getCount() == 1, "1 after remove")
        local ok2 = b:removeCombatant("orc")
        assert(not ok2, "false for nonexistent")
    "#).exec().unwrap();
}

#[test]
fn battle_force_end() {
    let lua = make_vm();
    lua.load(r#"
        local b = luna.combat.newBattle()
        assert(not b:isOver(), "not over initially")
        b:forceEnd("heroes")
        assert(b:isOver(), "over after forceEnd")
        assert(b:getWinner() == "heroes", "winner correct")
    "#).exec().unwrap();
}

#[test]
fn battle_force_end_no_winner() {
    let lua = make_vm();
    lua.load(r#"
        local b = luna.combat.newBattle()
        b:forceEnd(nil)
        assert(b:isOver(), "over")
        assert(b:getWinner() == nil, "no winner")
    "#).exec().unwrap();
}

#[test]
fn battle_log_from_attack() {
    let lua = make_vm();
    lua.load(r#"
        local b = luna.combat.newBattle()
        local hero = luna.combat.newCombatant("hero")
        local goblin = luna.combat.newCombatant("goblin")
        goblin:setTeam("enemy")
        local atk = luna.combat.newAction("strike")
        atk:setAccuracy(1.0)
        hero:addAction(atk)
        b:addCombatant(hero)
        b:addCombatant(goblin)
        b:addToLog("combat begin")
        local result = b:attack("hero", "strike", "goblin")
        assert(result ~= nil, "attack returned result")
        local log = b:getLog()
        assert(#log >= 1, "log has entries")
        assert(log[1] == "combat begin", "first entry preserved")
    "#).exec().unwrap();
}
'''

# Append before final closing
tst = tst.rstrip()
tst += "\n" + new_tests

with open(TEST, "w", encoding="utf-8") as f:
    f.write(tst)
print("combat_tests.rs updated")
print("Done - combat module expanded")
