"""Expand inventory module with convenience methods:
Domain: Container::has_item, count_item, remove_item, to_item_list
         Inventory::has_item, count_item, remove_from_any
API: Container.hasItem, countItem, removeItem, toList
     Inventory: hasItem, countItem, removeFromAny
Tests: 6 new tests
"""

MOD = r"src\inventory\mod.rs"
with open(MOD, "r", encoding="utf-8") as f:
    dom = f.read()

# We need to find the end of Container impl block to append new methods.
# The Container impl has `getSlots` / `addItem` / `getSlots` as last methods.
# Search for the `addItem` method and the following `getSlots` then the closing `}`
# of Container impl.

# The Container addItem is the last method before getSlots in the impl.
# Let's find "    pub fn add_item" in Container context and look for the following struct/impl boundary.

container_extra = """
    /// Returns the total count of items (all stacks summed) of a specific type.
    pub fn count_item(&self, item_type: &str) -> u32 {
        self.slots.iter()
            .filter_map(|s| {
                if !s.is_empty() {
                    s.stack.as_ref().and_then(|st| {
                        if st.item.item_type == item_type { Some(st.quantity) } else { None }
                    })
                } else { None }
            })
            .sum()
    }

    /// Returns true when the container holds at least `qty` of `item_type`.
    pub fn has_item(&self, item_type: &str, qty: u32) -> bool {
        self.count_item(item_type) >= qty
    }

    /// Remove up to `qty` items of `item_type` from this container.
    /// Returns true if the full amount was removed.
    pub fn remove_item(&mut self, item_type: &str, qty: u32) -> bool {
        if !self.has_item(item_type, qty) { return false; }
        let mut remaining = qty;
        for slot in &mut self.slots {
            if remaining == 0 { break; }
            if let Some(stack) = slot.stack.as_mut() {
                if stack.item.item_type == item_type {
                    let take = stack.quantity.min(remaining);
                    stack.quantity -= take;
                    remaining -= take;
                    if stack.quantity == 0 {
                        slot.stack = None;
                        slot.state = "empty".to_string();
                    }
                }
            }
        }
        remaining == 0
    }

    /// Returns a list of (item_type, quantity) pairs for all occupied slots.
    pub fn to_item_list(&self) -> Vec<(String, u32)> {
        self.slots.iter()
            .filter_map(|s| s.stack.as_ref().map(|st| (st.item.item_type.clone(), st.quantity)))
            .collect()
    }
"""

# Find the Container's getSlots method to insert before it
dom = dom.replace(
    "\n    pub fn get_slots(&self) -> &[Slot] { &self.slots }\n",
    container_extra + "\n    pub fn get_slots(&self) -> &[Slot] { &self.slots }\n",
    1,
)

# Add Inventory convenience methods
inventory_extra = """
    /// Count total items of `item_type` across all containers.
    pub fn count_item(&self, item_type: &str) -> u32 {
        self.containers.values().map(|c| c.count_item(item_type)).sum()
    }

    /// Returns true if the inventory holds at least `qty` of `item_type` across all containers.
    pub fn has_item(&self, item_type: &str, qty: u32) -> bool {
        self.count_item(item_type) >= qty
    }

    /// Remove up to `qty` of `item_type` from whichever containers have it.
    /// Returns true if the full amount was consumed.
    pub fn remove_from_any(&mut self, item_type: &str, qty: u32) -> bool {
        if !self.has_item(item_type, qty) { return false; }
        let mut remaining = qty;
        for container in self.containers.values_mut() {
            if remaining == 0 { break; }
            let available = container.count_item(item_type);
            if available > 0 {
                let take = available.min(remaining);
                container.remove_item(item_type, take);
                remaining -= take;
            }
        }
        remaining == 0
    }
"""

# Find end of Inventory impl by looking for enableSubsystem (last method)
dom = dom.replace(
    "\n    pub fn enable_subsystem(&mut self, name: &str) {",
    inventory_extra + "\n    pub fn enable_subsystem(&mut self, name: &str) {",
    1,
)

with open(MOD, "w", encoding="utf-8") as f:
    f.write(dom)
print("inventory/mod.rs updated")

# ---- Lua API ----------------------------------------------------------------
API = r"src\lua_api\inventory_api.rs"
with open(API, "r", encoding="utf-8") as f:
    api = f.read()

container_api_extra = '''        methods.add_method("hasItem", |_, this, (item_type, qty): (String, Option<u32>)| {
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
'''

# Insert before Container's getSlots binding
api = api.replace(
    '        methods.add_method("getSlots",',
    container_api_extra + '        methods.add_method("getSlots",',
    1,
)

inventory_api_extra = '''        methods.add_method("hasItem", |_, this, (item_type, qty): (String, Option<u32>)| {
            Ok(this.0.borrow().has_item(&item_type, qty.unwrap_or(1)))
        });
        methods.add_method("countItem", |_, this, item_type: String| {
            Ok(this.0.borrow().count_item(&item_type))
        });
        methods.add_method("removeFromAny", |_, this, (item_type, qty): (String, u32)| {
            Ok(this.0.borrow_mut().remove_from_any(&item_type, qty))
        });
'''

# Insert before enableSubsystem in Inventory API
api = api.replace(
    '        methods.add_method("enableSubsystem",',
    inventory_api_extra + '        methods.add_method("enableSubsystem",',
    1,
)

with open(API, "w", encoding="utf-8") as f:
    f.write(api)
print("inventory_api.rs updated")

# ---- Tests ----------------------------------------------------------------
TEST = r"tests\inventory_tests.rs"
with open(TEST, "r", encoding="utf-8") as f:
    tst = f.read()

new_tests = r'''
#[test]
fn container_count_item() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory("pack")
        inv:getContainer("main"):addItem(luna.inventory.newItem("sword"), 3)
        local c = inv:getContainer("main")
        assert(c:countItem("sword") == 3, "count 3 swords")
        assert(c:countItem("shield") == 0, "0 shields")
    "#).exec().unwrap();
}

#[test]
fn container_has_item() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory("pack")
        inv:getContainer("main"):addItem(luna.inventory.newItem("potion"), 5)
        local c = inv:getContainer("main")
        assert(c:hasItem("potion"), "has at least 1")
        assert(c:hasItem("potion", 5), "has 5")
        assert(not c:hasItem("potion", 6), "doesn't have 6")
    "#).exec().unwrap();
}

#[test]
fn container_remove_item() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory("pack")
        inv:getContainer("main"):addItem(luna.inventory.newItem("arrow"), 10)
        local c = inv:getContainer("main")
        local ok = c:removeItem("arrow", 4)
        assert(ok, "remove 4 ok")
        assert(c:countItem("arrow") == 6, "6 arrows left")
        local fail = c:removeItem("arrow", 100)
        assert(not fail, "cannot remove 100")
        assert(c:countItem("arrow") == 6, "still 6 after failed remove")
    "#).exec().unwrap();
}

#[test]
fn container_to_list() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory("pack")
        local c = inv:getContainer("main")
        c:addItem(luna.inventory.newItem("gem"), 2)
        c:addItem(luna.inventory.newItem("herb"), 7)
        local list = c:toList()
        assert(#list == 2, "2 item entries")
        local found = {}
        for _, entry in ipairs(list) do
            found[entry.itemType] = entry.quantity
        end
        assert(found["gem"] == 2, "gem qty")
        assert(found["herb"] == 7, "herb qty")
    "#).exec().unwrap();
}

#[test]
fn inventory_has_item_cross_container() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory("full")
        local c1 = inv:getContainer("main")
        c1:addItem(luna.inventory.newItem("coin"), 50)
        assert(inv:hasItem("coin", 50), "has 50 coins")
        assert(not inv:hasItem("coin", 51), "not 51")
    "#).exec().unwrap();
}

#[test]
fn inventory_remove_from_any() {
    let lua = make_vm();
    lua.load(r#"
        local inv = luna.inventory.newInventory("full")
        inv:getContainer("main"):addItem(luna.inventory.newItem("grain"), 8)
        assert(inv:countItem("grain") == 8, "8 grain")
        local ok = inv:removeFromAny("grain", 5)
        assert(ok, "remove ok")
        assert(inv:countItem("grain") == 3, "3 left")
        local fail = inv:removeFromAny("grain", 10)
        assert(not fail, "cannot remove 10 from 3")
        assert(inv:countItem("grain") == 3, "still 3")
    "#).exec().unwrap();
}
'''

tst = tst.rstrip() + "\n" + new_tests
with open(TEST, "w", encoding="utf-8") as f:
    f.write(tst)
print("inventory_tests.rs updated")
print("Done - inventory module expanded")
