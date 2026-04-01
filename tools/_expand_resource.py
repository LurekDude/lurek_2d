"""Expand resource module with convenience methods:
Domain: percent(name), isFull(name), isEmpty(name), canAffordAll(needs), spendAll(needs)
API: getPercent, isFull, isEmpty, canAffordAll({name=amount}), spendAll({name=amount})
Tests: 5 new tests
"""

MOD = r"src\resource\mod.rs"
with open(MOD, "r", encoding="utf-8") as f:
    dom = f.read()

# Find end of ResourceManager impl to append new methods
# The reset() method is the last one - find it and insert after
extra_domain = """
    /// Returns value as a percentage of capacity (0.0–100.0). Returns 0 if capacity <= 0.
    pub fn percent(&self, name: &str) -> f64 {
        if let Some(r) = self.resources.get(name) {
            if r.capacity <= 0.0 { return 0.0; }
            (r.value / r.capacity * 100.0).clamp(0.0, 100.0)
        } else { 0.0 }
    }

    /// Returns true when the named resource value has reached its capacity.
    pub fn is_full(&self, name: &str) -> bool {
        self.resources.get(name).map(|r| r.value >= r.capacity).unwrap_or(false)
    }

    /// Returns true when the named resource value is at or below its minimum.
    pub fn is_empty(&self, name: &str) -> bool {
        self.resources.get(name).map(|r| r.value <= r.minimum).unwrap_or(true)
    }

    /// Returns true only if every (name, amount) pair can be afforded simultaneously.
    pub fn can_afford_all(&self, needs: &[(&str, f64)]) -> bool {
        needs.iter().all(|(name, amount)| {
            self.resources.get(*name).map(|r| r.can_afford(*amount)).unwrap_or(false)
        })
    }

    /// Atomically spends all listed amounts. Does nothing and returns false if any
    /// resource cannot afford its portion.
    pub fn spend_all(&mut self, needs: &[(&str, f64)]) -> bool {
        let ok = needs.iter().all(|(name, amount)| {
            self.resources.get(*name).map(|r| r.can_afford(*amount)).unwrap_or(false)
        });
        if !ok { return false; }
        for (name, amount) in needs {
            if let Some(r) = self.resources.get_mut(*name) {
                r.spend(*amount);
            }
        }
        true
    }
"""

# Insert before the last `}` that closes the ResourceManager impl
# The `reset` method is the last one in that impl
# Find "    pub fn reset..." and its closing brace, then after `    }\n}` (two consecutive close braces)
# We look for `    pub fn reset(` and capture the rest
dom = dom.replace(
    "\n    pub fn reset(&mut self) {",
    extra_domain + "\n    pub fn reset(&mut self) {",
    1
)

with open(MOD, "w", encoding="utf-8") as f:
    f.write(dom)
print("resource/mod.rs updated")

# ---- Lua API ----------------------------------------------------------------
API = r"src\lua_api\resource_api.rs"
with open(API, "r", encoding="utf-8") as f:
    api = f.read()

extra_api = '''        methods.add_method("getPercent", |_, this, name: String| {
            Ok(this.0.borrow().percent(&name))
        });
        methods.add_method("isFull", |_, this, name: String| {
            Ok(this.0.borrow().is_full(&name))
        });
        methods.add_method("isEmpty", |_, this, name: String| {
            Ok(this.0.borrow().is_empty(&name))
        });
        methods.add_method("canAffordAll", |_, this, tbl: LuaTable| {
            let mut needs: Vec<(String, f64)> = Vec::new();
            for pair in tbl.pairs::<String, f64>() {
                let (k, v) = pair.map_err(LuaError::external)?;
                needs.push((k, v));
            }
            let refs: Vec<(&str, f64)> = needs.iter().map(|(k, v)| (k.as_str(), *v)).collect();
            Ok(this.0.borrow().can_afford_all(&refs))
        });
        methods.add_method("spendAll", |_, this, tbl: LuaTable| {
            let mut needs: Vec<(String, f64)> = Vec::new();
            for pair in tbl.pairs::<String, f64>() {
                let (k, v) = pair.map_err(LuaError::external)?;
                needs.push((k, v));
            }
            let refs: Vec<(&str, f64)> = needs.iter().map(|(k, v)| (k.as_str(), *v)).collect();
            Ok(this.0.borrow_mut().spend_all(&refs))
        });
'''

# Insert before `methods.add_method("reset",`
api = api.replace(
    '        methods.add_method("reset",',
    extra_api + '        methods.add_method("reset",',
    1,
)

with open(API, "w", encoding="utf-8") as f:
    f.write(api)
print("resource_api.rs updated")

# ---- Tests ----------------------------------------------------------------
TEST = r"tests\resource_tests.rs"
with open(TEST, "r", encoding="utf-8") as f:
    tst = f.read()

new_tests = r'''
#[test]
fn resource_manager_get_percent() {
    let lua = make_vm();
    lua.load(r#"
        local rm = luna.resource.newManager()
        rm:newResource("mana", 100.0)
        rm:setValue("mana", 75.0)
        local p = rm:getPercent("mana")
        assert(math.abs(p - 75.0) < 0.01, "75% mana")
        rm:setValue("mana", 0.0)
        assert(math.abs(rm:getPercent("mana") - 0.0) < 0.01, "0%")
        rm:setValue("mana", 100.0)
        assert(math.abs(rm:getPercent("mana") - 100.0) < 0.01, "100%")
    "#).exec().unwrap();
}

#[test]
fn resource_manager_is_full_empty() {
    let lua = make_vm();
    lua.load(r#"
        local rm = luna.resource.newManager()
        rm:newResource("stamina", 50.0)
        rm:setValue("stamina", 50.0)
        assert(rm:isFull("stamina"), "full at max")
        rm:setValue("stamina", 0.0)
        assert(rm:isEmpty("stamina"), "empty at min")
        rm:setValue("stamina", 25.0)
        assert(not rm:isFull("stamina"), "not full at 50%")
        assert(not rm:isEmpty("stamina"), "not empty at 50%")
    "#).exec().unwrap();
}

#[test]
fn resource_manager_can_afford_all() {
    let lua = make_vm();
    lua.load(r#"
        local rm = luna.resource.newManager()
        rm:newResource("gold", 100.0)
        rm:newResource("wood", 50.0)
        rm:setValue("gold", 80.0)
        rm:setValue("wood", 30.0)
        assert(rm:canAffordAll({gold=50, wood=20}), "can afford both")
        assert(not rm:canAffordAll({gold=90, wood=20}), "cannot afford gold")
        assert(not rm:canAffordAll({gold=50, wood=40}), "cannot afford wood")
    "#).exec().unwrap();
}

#[test]
fn resource_manager_spend_all() {
    let lua = make_vm();
    lua.load(r#"
        local rm = luna.resource.newManager()
        rm:newResource("gold", 100.0)
        rm:newResource("iron", 50.0)
        rm:setValue("gold", 60.0)
        rm:setValue("iron", 30.0)
        local ok = rm:spendAll({gold=30, iron=20})
        assert(ok, "spend succeeded")
        assert(math.abs(rm:getValue("gold") - 30.0) < 0.01, "gold spent")
        assert(math.abs(rm:getValue("iron") - 10.0) < 0.01, "iron spent")
    "#).exec().unwrap();
}

#[test]
fn resource_manager_spend_all_rollback() {
    let lua = make_vm();
    lua.load(r#"
        local rm = luna.resource.newManager()
        rm:newResource("gold", 100.0)
        rm:newResource("iron", 10.0)
        rm:setValue("gold", 60.0)
        rm:setValue("iron", 5.0)
        -- iron cannot afford 20, so entire spend should fail atomically
        local ok = rm:spendAll({gold=30, iron=20})
        assert(not ok, "spend failed")
        assert(math.abs(rm:getValue("gold") - 60.0) < 0.01, "gold unchanged")
        assert(math.abs(rm:getValue("iron") - 5.0) < 0.01, "iron unchanged")
    "#).exec().unwrap();
}
'''

tst = tst.rstrip() + "\n" + new_tests
with open(TEST, "w", encoding="utf-8") as f:
    f.write(tst)
print("resource_tests.rs updated")
print("Done - resource module expanded")
