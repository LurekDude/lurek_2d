"""Expand stats module with:
Domain: Sheet::get_stat_names(), get_buff_count(stat?), recover_action_points(amount)
API: LuaSheet: getStatNames, getBuffCount, recoverActionPoints
Tests: 3 new tests
"""

MOD = r"src\stats\mod.rs"
with open(MOD, "r", encoding="utf-8") as f:
    dom = f.read()

stats_extra = """
    /// Returns the names of all defined attributes on this sheet.
    pub fn get_stat_names(&self) -> Vec<String> {
        self.attributes.keys().cloned().collect()
    }

    /// Count active buffs. If `stat` is Some, count only buffs targeting that stat.
    pub fn get_buff_count(&self, stat: Option<&str>) -> usize {
        self.attributes.values()
            .flat_map(|a| &a.buffs)
            .filter(|b| stat.map_or(true, |s| b.stat == s))
            .count()
    }

    /// Add `amount` to current action points, capped at the maximum.
    /// Returns the new value.
    pub fn recover_action_points(&mut self, amount: f64) -> f64 {
        let max = self.action_points.max;
        self.action_points.current = (self.action_points.current + amount).min(max);
        self.action_points.current
    }
"""

# Insert before `pub fn update(&mut self, dt: f64)`
dom = dom.replace(
    "\n    pub fn update(&mut self, dt: f64) {",
    stats_extra + "\n    pub fn update(&mut self, dt: f64) {",
    1,
)

with open(MOD, "w", encoding="utf-8") as f:
    f.write(dom)
print("stats/mod.rs updated")

# ---- Lua API ----------------------------------------------------------------
API = r"src\lua_api\stats_api.rs"
with open(API, "r", encoding="utf-8") as f:
    api = f.read()

api_extra = '''        methods.add_method("getStatNames", |lua, this, ()| {
            let names = this.0.borrow().get_stat_names();
            let t = lua.create_table()?;
            for (i, name) in names.into_iter().enumerate() { t.set(i + 1, name)?; }
            Ok(t)
        });
        methods.add_method("getBuffCount", |_, this, stat: Option<String>| {
            Ok(this.0.borrow().get_buff_count(stat.as_deref()))
        });
        methods.add_method("recoverActionPoints", |_, this, amount: f64| {
            Ok(this.0.borrow_mut().recover_action_points(amount))
        });
'''

# Insert before `update` binding
api = api.replace(
    '        methods.add_method("update", |_, this, dt: f64| {',
    api_extra + '        methods.add_method("update", |_, this, dt: f64| {',
    1,
)

with open(API, "w", encoding="utf-8") as f:
    f.write(api)
print("stats_api.rs updated")

# ---- Tests ----------------------------------------------------------------
TEST = r"tests\stats_tests.rs"
with open(TEST, "r", encoding="utf-8") as f:
    tst = f.read()

new_tests = r'''
#[test]
fn sheet_get_stat_names() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = luna.stats.newSheet()
        sheet:define("strength", 10.0)
        sheet:define("agility", 8.0)
        sheet:define("wisdom", 12.0)
        local names = sheet:getStatNames()
        assert(#names == 3, "3 stat names")
        local found = {}
        for _, n in ipairs(names) do found[n] = true end
        assert(found["strength"], "strength present")
        assert(found["agility"], "agility present")
        assert(found["wisdom"], "wisdom present")
    "#).exec().unwrap();
}

#[test]
fn sheet_get_buff_count() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = luna.stats.newSheet()
        sheet:define("attack", 10.0)
        sheet:define("defense", 5.0)
        sheet:addBuff("attack", 2.0, "flat", 3)
        sheet:addBuff("attack", 1.5, "flat", 2)
        sheet:addBuff("defense", 1.0, "flat", 5)
        local total = sheet:getBuffCount(nil)
        assert(total == 3, "3 total buffs")
        local atk_buffs = sheet:getBuffCount("attack")
        assert(atk_buffs == 2, "2 attack buffs")
        local def_buffs = sheet:getBuffCount("defense")
        assert(def_buffs == 1, "1 defense buff")
    "#).exec().unwrap();
}

#[test]
fn sheet_recover_action_points() {
    let lua = make_vm();
    lua.load(r#"
        local sheet = luna.stats.newSheet()
        sheet:setActionPoints(10.0)
        sheet:spendActionPoints(7.0)
        local current = sheet:getActionPoints()
        assert(math.abs(current - 3.0) < 0.01, "3 AP remaining")
        local new_val = sheet:recoverActionPoints(4.0)
        assert(math.abs(new_val - 7.0) < 0.01, "recovered to 7")
        -- recovery capped at max
        local capped = sheet:recoverActionPoints(100.0)
        assert(math.abs(capped - 10.0) < 0.01, "capped at max 10")
    "#).exec().unwrap();
}
'''

tst = tst.rstrip() + "\n" + new_tests
with open(TEST, "w", encoding="utf-8") as f:
    f.write(tst)
print("stats_tests.rs updated")
print("Done - stats module expanded")
