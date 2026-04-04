//! Integration tests for the resource economy system (`luna.resource`).

use luna2d::lua_api::{create_lua_vm, SharedState};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state).unwrap()
}

#[test]
fn resource_new_manager() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        assert(mgr ~= nil, "manager should not be nil")
        assert(mgr:type() == "ResourceManager", "type should be ResourceManager, got " .. mgr:type())
        assert(mgr:typeOf("Object"), "should typeOf 'Object'")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_create_and_query() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        assert(mgr:hasResource("gold"), "should have gold")
        assert(not mgr:hasResource("silver"), "should not have silver")
        local names = mgr:getResourceNames()
        assert(#names == 1, "should have 1 resource name, got " .. #names)
        assert(names[1] == "gold", "name should be gold")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_value_initial() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        local v = mgr:getValue("gold")
        assert(math.abs(v) < 0.001, "initial value should be 0, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_set_value() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("wood", 200)
        mgr:setValue("wood", 50)
        local v = mgr:getValue("wood")
        assert(math.abs(v - 50) < 0.001, "value should be 50, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_capacity() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("stone", 100)
        local cap = mgr:getCapacity("stone")
        assert(math.abs(cap - 100) < 0.001, "capacity should be 100, got " .. cap)
        mgr:setCapacity("stone", 250)
        cap = mgr:getCapacity("stone")
        assert(math.abs(cap - 250) < 0.001, "capacity should be 250, got " .. cap)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_minimum() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("health", 100)
        mgr:setMinimum("health", 10)
        local min = mgr:getMinimum("health")
        assert(math.abs(min - 10) < 0.001, "minimum should be 10, got " .. min)
        -- Setting below minimum should clamp
        mgr:setValue("health", 5)
        local v = mgr:getValue("health")
        assert(v >= 10 - 0.001, "value should not go below minimum")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_add_and_spend() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        mgr:add("gold", 50)
        assert(math.abs(mgr:getValue("gold") - 50) < 0.001, "should have 50 gold")
        local success = mgr:spend("gold", 20)
        assert(success, "spend should succeed")
        assert(math.abs(mgr:getValue("gold") - 30) < 0.001, "should have 30 gold")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_spend_insufficient() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        mgr:add("gold", 10)
        local success = mgr:spend("gold", 50)
        assert(not success, "spend should fail when insufficient")
        assert(math.abs(mgr:getValue("gold") - 10) < 0.001, "gold should be unchanged at 10")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_can_afford() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("mana", 100)
        mgr:add("mana", 40)
        assert(mgr:canAfford("mana", 40), "should afford exactly 40")
        assert(mgr:canAfford("mana", 20), "should afford 20")
        assert(not mgr:canAfford("mana", 50), "should not afford 50")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_reserve_and_available() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        mgr:add("gold", 80)
        mgr:reserve("gold", 20)
        local av = mgr:getAvailable("gold")
        assert(math.abs(av - 60) < 0.001, "available should be 60, got " .. av)
        mgr:unreserve("gold", 10)
        av = mgr:getAvailable("gold")
        assert(math.abs(av - 70) < 0.001, "available should be 70 after unreserve")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_flow_rate_tick() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("energy", 100)
        mgr:setFlowRate("energy", 10)
        mgr:tick(1.0)
        local v = mgr:getValue("energy")
        assert(math.abs(v - 10) < 0.01, "after 1s tick, energy should be 10, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_decay_rate_tick() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("food", 100)
        mgr:setValue("food", 50)
        mgr:setDecayRate("food", 5)
        mgr:tick(1.0)
        local v = mgr:getValue("food")
        assert(math.abs(v - 45) < 0.01, "after 1s tick, food should be 45, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_upkeep_turn() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        mgr:setValue("gold", 60)
        mgr:setUpkeep("gold", 10)
        mgr:turn()
        local v = mgr:getValue("gold")
        assert(math.abs(v - 50) < 0.01, "after turn, gold should be 50, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_group_total() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 200)
        mgr:newResource("silver", 200)
        mgr:newResource("wood", 200)
        mgr:setGroup("gold", "currency")
        mgr:setGroup("silver", "currency")
        mgr:setGroup("wood", "materials")
        mgr:setValue("gold", 50)
        mgr:setValue("silver", 30)
        mgr:setValue("wood", 100)
        local total = mgr:totalByGroup("currency")
        assert(math.abs(total - 80) < 0.001, "currency total should be 80, got " .. total)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_overflow_clamp() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        mgr:setOverflow("gold", "clamp")
        mgr:add("gold", 150)
        local v = mgr:getValue("gold")
        assert(math.abs(v - 100) < 0.001, "clamp overflow: value should be capped at 100, got " .. v)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_overflow_lose() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        mgr:setOverflow("gold", "lose")
        mgr:add("gold", 50)
        -- Trying to add 80 more would push to 130 > 100, so with 'lose' policy the amount is lost
        local returned = mgr:add("gold", 80)
        local v = mgr:getValue("gold")
        -- With 'lose', overflow is discarded and nothing is added
        assert(math.abs(v - 50) < 0.001, "lose overflow: value should stay at 50 (overflow lost), got " .. v)
        assert(returned > 0, "lose overflow: returned value should be positive (overflow amount)")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_enabled_flag() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("wood", 100)
        assert(mgr:isEnabled("wood"), "should be enabled by default")
        mgr:setEnabled("wood", false)
        assert(not mgr:isEnabled("wood"), "should be disabled after setEnabled(false)")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_visible_flag() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("wood", 100)
        assert(mgr:isVisible("wood"), "should be visible by default")
        mgr:setVisible("wood", false)
        assert(not mgr:isVisible("wood"), "should be hidden after setVisible(false)")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_locked_flag() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        assert(not mgr:isLocked("gold"), "should be unlocked by default")
        mgr:setLocked("gold", true)
        assert(mgr:isLocked("gold"), "should be locked after setLocked(true)")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_conversion_rule() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("wood", 200)
        mgr:newResource("planks", 200)
        mgr:setValue("wood", 100)
        -- addConversionRule(from, to, rate) where rate = output per unit input
        mgr:addConversionRule("wood", "planks", 0.8)  -- 1 wood -> 0.8 planks
        -- convert(from, to, amount) - spend 5 wood to get 4 planks
        local ok = mgr:convert("wood", "planks", 5)
        assert(ok, "conversion should succeed")
        local w = mgr:getValue("wood")
        local p = mgr:getValue("planks")
        assert(math.abs(w - 95) < 0.001, "wood should be 95, got " .. w)
        assert(math.abs(p - 4) < 0.001, "planks should be 4, got " .. p)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_convert_insufficient() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("wood", 200)
        mgr:newResource("planks", 200)
        mgr:setValue("wood", 2)
        mgr:addConversionRule("wood", "planks", 0.8)
        local ok = mgr:convert("wood", "planks", 5)  -- need 5, only have 2
        assert(not ok, "conversion should fail when insufficient wood")
        local w = mgr:getValue("wood")
        assert(math.abs(w - 2) < 0.001, "wood should be unchanged at 2, got " .. w)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_remove_resource() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("temp", 100)
        assert(mgr:hasResource("temp"), "should have temp")
        mgr:removeResource("temp")
        assert(not mgr:hasResource("temp"), "should not have temp after removal")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_reset() {
    let lua = make_vm();
    lua.load(
        r#"
        local mgr = luna.resource.newManager()
        mgr:newResource("gold", 100)
        mgr:setValue("gold", 75)
        -- reset() clears the entire manager (all resources)
        mgr:reset()
        -- After reset, gold no longer exists
        assert(not mgr:hasResource("gold"), "after reset(), manager should have no resources")
        local names = mgr:getResourceNames()
        assert(#names == 0, "after reset(), should have 0 resources, got " .. #names)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_error_unknown_resource() {
    let lua = make_vm();
    let result = lua
        .load(
            r#"
        local mgr = luna.resource.newManager()
        mgr:getValue("nonexistent")
        "#,
        )
        .exec();
    assert!(result.is_err(), "accessing unknown resource should error");
}

#[test]
fn resource_manager_get_percent() {
    let lua = make_vm();
    lua.load(
        r#"
        local rm = luna.resource.newManager()
        rm:newResource("mana", 100.0)
        rm:setValue("mana", 75.0)
        local p = rm:getPercent("mana")
        assert(math.abs(p - 75.0) < 0.01, "75% mana")
        rm:setValue("mana", 0.0)
        assert(math.abs(rm:getPercent("mana") - 0.0) < 0.01, "0%")
        rm:setValue("mana", 100.0)
        assert(math.abs(rm:getPercent("mana") - 100.0) < 0.01, "100%")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_manager_is_full_empty() {
    let lua = make_vm();
    lua.load(
        r#"
        local rm = luna.resource.newManager()
        rm:newResource("stamina", 50.0)
        rm:setValue("stamina", 50.0)
        assert(rm:isFull("stamina"), "full at max")
        rm:setValue("stamina", 0.0)
        assert(rm:isEmpty("stamina"), "empty at min")
        rm:setValue("stamina", 25.0)
        assert(not rm:isFull("stamina"), "not full at 50%")
        assert(not rm:isEmpty("stamina"), "not empty at 50%")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_manager_can_afford_all() {
    let lua = make_vm();
    lua.load(
        r#"
        local rm = luna.resource.newManager()
        rm:newResource("gold", 100.0)
        rm:newResource("wood", 50.0)
        rm:setValue("gold", 80.0)
        rm:setValue("wood", 30.0)
        assert(rm:canAffordAll({gold=50, wood=20}), "can afford both")
        assert(not rm:canAffordAll({gold=90, wood=20}), "cannot afford gold")
        assert(not rm:canAffordAll({gold=50, wood=40}), "cannot afford wood")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_manager_spend_all() {
    let lua = make_vm();
    lua.load(
        r#"
        local rm = luna.resource.newManager()
        rm:newResource("gold", 100.0)
        rm:newResource("iron", 50.0)
        rm:setValue("gold", 60.0)
        rm:setValue("iron", 30.0)
        local ok = rm:spendAll({gold=30, iron=20})
        assert(ok, "spend succeeded")
        assert(math.abs(rm:getValue("gold") - 30.0) < 0.01, "gold spent")
        assert(math.abs(rm:getValue("iron") - 10.0) < 0.01, "iron spent")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn resource_manager_spend_all_rollback() {
    let lua = make_vm();
    lua.load(
        r#"
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
    "#,
    )
    .exec()
    .unwrap();
}
