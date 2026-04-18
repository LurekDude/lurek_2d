--- BDD tests for library.inventory
-- @module tests.lua.library.test_library_inventory

local inventory = require("library.inventory")

-- ─── InvItem ──────────────────────────────────────────────────────────────────

-- @description Verifies inventory item defaults plus stat, tag, weight, slot-type, and metadata behaviors on standalone items.
describe("InvItem", function()
    -- @covers library.inventory.newItem
    -- @description Verifies case: creates item with type.
    it("creates item with type", function()
        local it = inventory.newItem("sword")
        expect_equal(it:getType(), "sword")
    end)

    -- @description Verifies case: default weight is 0.
    it("default weight is 0", function()
        local it = inventory.newItem("sword")
        expect_equal(it:getWeight(), 0.0)
    end)

    -- @description Verifies case: setWeight/getWeight round-trip.
    it("setWeight/getWeight round-trip", function()
        local it = inventory.newItem("sword")
        it:setWeight(3.5)
        expect_near(it:getWeight(), 3.5, 1e-9)
    end)

    -- @description Verifies case: default stack limit is 1.
    it("default stack limit is 1", function()
        local it = inventory.newItem("potion")
        expect_equal(it:getStackLimit(), 1)
    end)

    -- @description Verifies case: setStackLimit clamps to 1 minimum.
    it("setStackLimit clamps to 1 minimum", function()
        local it = inventory.newItem("potion")
        it:setStackLimit(0)
        expect_equal(it:getStackLimit(), 1)
    end)

    -- @description Verifies case: addTag / hasTag.
    it("addTag / hasTag", function()
        local it = inventory.newItem("sword")
        it:addTag("equippable")
        expect_equal(it:hasTag("equippable"), true)
        expect_equal(it:hasTag("consumable"), false)
    end)

    -- @description Verifies case: removeTag returns true when present.
    it("removeTag returns true when present", function()
        local it = inventory.newItem("sword")
        it:addTag("cursed")
        expect_equal(it:removeTag("cursed"), true)
        expect_equal(it:hasTag("cursed"), false)
    end)

    -- @description Verifies case: removeTag returns false when absent.
    it("removeTag returns false when absent", function()
        local it = inventory.newItem("sword")
        expect_equal(it:removeTag("cursed"), false)
    end)

    -- @description Verifies case: getTags returns sorted array.
    it("getTags returns sorted array", function()
        local it = inventory.newItem("sword")
        it:addTag("z_tag")
        it:addTag("a_tag")
        local tags = it:getTags()
        expect_equal(tags[1], "a_tag")
        expect_equal(tags[2], "z_tag")
    end)

    -- @description Verifies case: setProperty / getProperty.
    it("setProperty / getProperty", function()
        local it = inventory.newItem("sword")
        it:setProperty("durability", 100)
        expect_equal(it:getProperty("durability"), 100)
    end)

    -- @description Verifies case: clone creates independent copy.
    it("clone creates independent copy", function()
        local it = inventory.newItem("sword")
        it:setWeight(5.0)
        it:addTag("magic")
        it:setProperty("level", 3)
        local c = it:clone()
        expect_equal(c:getType(), "sword")
        expect_near(c:getWeight(), 5.0, 1e-9)
        expect_equal(c:hasTag("magic"), true)
        expect_equal(c:getProperty("level"), 3)
        -- mutations to original don't affect clone
        it:setWeight(1.0)
        expect_near(c:getWeight(), 5.0, 1e-9)
    end)
end)

-- ─── ItemStack ────────────────────────────────────────────────────────────────

-- @description Covers stack quantity math, capacity checks, split or merge flows, and the relationship between an item stack and its underlying item.
describe("ItemStack", function()
    -- @covers library.inventory.newItemStack
    -- @description Verifies case: creates stack with quantity.
    it("creates stack with quantity", function()
        local it = inventory.newItem("arrow")
        it:setStackLimit(20)
        local s = inventory.newItemStack(it, 5, 20)
        expect_equal(s:getQuantity(), 5)
        expect_equal(s:getStackLimit(), 20)
    end)

    -- @description Verifies case: isFull when at max.
    it("isFull when at max", function()
        local it = inventory.newItem("coin")
        it:setStackLimit(10)
        local s = inventory.newItemStack(it, 10, 10)
        expect_equal(s:isFull(), true)
    end)

    -- @description Verifies case: isEmpty when quantity 0.
    it("isEmpty when quantity 0", function()
        local it = inventory.newItem("coin")
        local s = inventory.newItemStack(it, 0, 10)
        expect_equal(s:isEmpty(), true)
    end)

    -- @description Verifies case: add returns overflow.
    it("add returns overflow", function()
        local it = inventory.newItem("arrow")
        it:setStackLimit(10)
        local s = inventory.newItemStack(it, 8, 10)
        local overflow = s:add(5)
        expect_equal(overflow, 3)
        expect_equal(s:getQuantity(), 10)
    end)

    -- @description Verifies case: remove returns count removed.
    it("remove returns count removed", function()
        local it = inventory.newItem("arrow")
        local s = inventory.newItemStack(it, 8, 10)
        local removed = s:remove(3)
        expect_equal(removed, 3)
        expect_equal(s:getQuantity(), 5)
    end)

    -- @description Verifies case: split creates new stack.
    it("split creates new stack", function()
        local it = inventory.newItem("arrow")
        local s = inventory.newItemStack(it, 10, 10)
        local split = s:split(4)
        expect_equal(split:getQuantity(), 4)
        expect_equal(s:getQuantity(), 6)
    end)

    -- @description Verifies case: split returns nil for invalid n.
    it("split returns nil for invalid n", function()
        local it = inventory.newItem("arrow")
        local s = inventory.newItemStack(it, 10, 10)
        expect_equal(s:split(0), nil)
        expect_equal(s:split(11), nil)
    end)

    -- @description Verifies case: merge absorbs other stack.
    it("merge absorbs other stack", function()
        local it = inventory.newItem("coin")
        local a = inventory.newItemStack(it, 5, 10)
        local b = inventory.newItemStack(it, 3, 10)
        local leftover = a:merge(b)
        expect_equal(leftover, 0)
        expect_equal(a:getQuantity(), 8)
        expect_equal(b:getQuantity(), 0)
    end)

    -- @description Verifies case: merge returns leftover when overflow.
    it("merge returns leftover when overflow", function()
        local it = inventory.newItem("coin")
        local a = inventory.newItemStack(it, 8, 10)
        local b = inventory.newItemStack(it, 5, 10)
        local leftover = a:merge(b)
        expect_equal(leftover, 3)
        expect_equal(a:getQuantity(), 10)
        expect_equal(b:getQuantity(), 3)
    end)
end)

-- ─── Slot ─────────────────────────────────────────────────────────────────────

-- @description Tests equipment and container slots for acceptance rules, set or clear flows, occupancy checks, and slot-level metadata.
describe("Slot", function()
    -- @covers library.inventory.newSlot
    -- @description Verifies case: starts empty.
    it("starts empty", function()
        local sl = inventory.newSlot("any", inventory.SlotState.Active)
        expect_equal(sl:isEmpty(), true)
    end)

    -- @description Verifies case: can accept any-typed item.
    it("can accept any-typed item", function()
        local sl = inventory.newSlot("any", inventory.SlotState.Active)
        local it = inventory.newItem("sword")
        expect_equal(sl:canAccept(it), true)
    end)

    -- @description Verifies case: type filter rejects non-matching item.
    it("type filter rejects non-matching item", function()
        local sl = inventory.newSlot("weapon", inventory.SlotState.Active)
        local it = inventory.newItem("potion")
        expect_equal(sl:canAccept(it), false)
    end)

    -- @description Verifies case: type filter accepts item with matching tag.
    it("type filter accepts item with matching tag", function()
        local sl = inventory.newSlot("weapon", inventory.SlotState.Active)
        local it = inventory.newItem("special_blade")
        it:addTag("weapon")
        expect_equal(sl:canAccept(it), true)
    end)

    -- @description Verifies case: setStack/getStack round-trip.
    it("setStack/getStack round-trip", function()
        local sl = inventory.newSlot("any", inventory.SlotState.Active)
        local it = inventory.newItem("sword")
        local st = inventory.newItemStack(it, 1, 1)
        sl:setStack(st)
        expect_equal(sl:isEmpty(), false)
        expect_equal(sl:getItem():getType(), "sword")
    end)

    -- @description Verifies case: takeStack empties slot.
    it("takeStack empties slot", function()
        local sl = inventory.newSlot("any", inventory.SlotState.Active)
        local it = inventory.newItem("sword")
        sl:setStack(inventory.newItemStack(it, 1, 1))
        local taken = sl:takeStack()
        expect_equal(sl:isEmpty(), true)
        expect_equal(taken:getItem():getType(), "sword")
    end)

    -- @description Verifies case: clear empties slot.
    it("clear empties slot", function()
        local sl = inventory.newSlot("any", inventory.SlotState.Active)
        local it = inventory.newItem("sword")
        sl:setStack(inventory.newItemStack(it, 1, 1))
        sl:clear()
        expect_equal(sl:isEmpty(), true)
    end)
end)

-- ─── Container ────────────────────────────────────────────────────────────────

-- @description Exercises fixed-size containers including slot access, add or remove flows, transfers, counting, and structural constraints.
describe("Container.fixed", function()
    -- @covers library.inventory.newContainer
    -- @description Verifies case: creates fixed container with correct slot count.
    it("creates fixed container with correct slot count", function()
        local c = inventory.newContainer("bag", "fixed", 5)
        expect_equal(c:slotCount(), 5)
        expect_equal(c:getMode(), "fixed")
    end)

    -- @description Verifies case: addItem places item in empty slot.
    it("addItem places item in empty slot", function()
        local c = inventory.newContainer("bag", "fixed", 5)
        local it = inventory.newItem("potion")
        it:setStackLimit(5)
        expect_equal(c:addItem(it, 3), true)
        expect_equal(c:countItem("potion"), 3)
    end)

    -- @description Verifies case: addItem merges into existing stack.
    it("addItem merges into existing stack", function()
        local c = inventory.newContainer("bag", "fixed", 5)
        local it = inventory.newItem("arrow")
        it:setStackLimit(20)
        c:addItem(it, 10)
        c:addItem(it, 5)
        expect_equal(c:countItem("arrow"), 15)
    end)

    -- @description Verifies case: hasItem returns true when quantity met.
    it("hasItem returns true when quantity met", function()
        local c = inventory.newContainer("bag", "fixed", 5)
        local it = inventory.newItem("coin")
        it:setStackLimit(100)
        c:addItem(it, 50)
        expect_equal(c:hasItem("coin", 50), true)
        expect_equal(c:hasItem("coin", 51), false)
    end)

    -- @description Verifies case: removeItem reduces count.
    it("removeItem reduces count", function()
        local c = inventory.newContainer("bag", "fixed", 5)
        local it = inventory.newItem("herb")
        it:setStackLimit(10)
        c:addItem(it, 8)
        local removed = c:removeItem("herb", 3)
        expect_equal(removed, 3)
        expect_equal(c:countItem("herb"), 5)
    end)

    -- @description Verifies case: findByTag returns matching items.
    it("findByTag returns matching items", function()
        local c = inventory.newContainer("bag", "fixed", 10)
        local sword = inventory.newItem("sword")
        sword:addTag("sharp")
        local potion = inventory.newItem("potion")
        c:addItem(sword, 1)
        c:addItem(potion, 1)
        local found = c:findByTag("sharp")
        expect_equal(#found, 1)
        expect_equal(found[1]:getType(), "sword")
    end)

    -- @description Verifies case: toItemList aggregates types.
    it("toItemList aggregates types", function()
        local c = inventory.newContainer("bag", "fixed", 10)
        local arrow = inventory.newItem("arrow")
        arrow:setStackLimit(10)
        c:addItem(arrow, 3)
        c:addItem(arrow, 2)
        local list = c:toItemList()
        expect_equal(list[1].type_name, "arrow")
        expect_equal(list[1].quantity, 5)
    end)

    -- @description Verifies case: isFull when all slots occupied.
    it("isFull when all slots occupied", function()
        local c = inventory.newContainer("bag", "fixed", 2)
        local it = inventory.newItem("coin")
        c:addItem(it, 1)
        c:addItem(it, 1)
        expect_equal(c:isFull(), true)
    end)

    -- @description Verifies case: returns false when addItem into full container.
    it("returns false when addItem into full container", function()
        local c = inventory.newContainer("bag", "fixed", 1)
        local it = inventory.newItem("sword")
        c:addItem(it, 1)
        expect_equal(c:addItem(inventory.newItem("shield"), 1), false)
    end)
end)

-- @description Verifies expandable containers can grow when items are inserted beyond the current slot count.
describe("Container.expandable", function()
    -- @covers library.inventory.newContainer
    -- @description Verifies case: expand adds slots in expandable mode.
    it("expand adds slots in expandable mode", function()
        local c = inventory.newContainer("bag", "expandable", 2)
        expect_equal(c:slotCount(), 2)
        c:expand(3)
        expect_equal(c:slotCount(), 5)
    end)

    -- @description Verifies case: expand returns false in fixed mode.
    it("expand returns false in fixed mode", function()
        local c = inventory.newContainer("bag", "fixed", 5)
        expect_equal(c:expand(2), false)
    end)
end)

-- @description Covers unlimited-mode containers that accept arbitrary growth without fixed-slot limits.
describe("Container.unlimited", function()
    -- @covers library.inventory.newContainer
    -- @description Verifies case: auto-grows on addItem.
    it("auto-grows on addItem", function()
        local c = inventory.newContainer("bag", "unlimited", 0)
        for i = 1, 20 do
            local it = inventory.newItem("item_"..i)
            c:addItem(it, 1)
        end
        expect_equal(c:slotCount(), 20)
    end)

    -- @description Verifies case: weight limit respected.
    it("weight limit respected", function()
        local c = inventory.newContainer("heavy", "unlimited", 0)
        c:setWeightLimit(5.0)
        local heavy = inventory.newItem("boulder")
        heavy:setWeight(3.0)
        c:addItem(heavy, 1)
        expect_near(c:getCurrentWeight(), 3.0, 1e-9)
    end)
end)

-- ─── ItemSet ──────────────────────────────────────────────────────────────────

-- @description Tests item-set requirements, activation checks, and bookkeeping for named equipment collections.
describe("ItemSet", function()
    -- @covers library.inventory.newItemSet
    -- @description Verifies case: isSatisfied when all tags equipped.
    it("isSatisfied when all tags equipped", function()
        local iset = inventory.newItemSet("knight_set")
        iset:addRequirement("plate", "")
        iset:addRequirement("heavy", "")

        local sword = inventory.newItem("longsword")
        sword:addTag("plate")
        sword:addTag("heavy")

        local equip = {}
        local sl = inventory.newSlot("any", inventory.SlotState.Active)
        sl:setStack(inventory.newItemStack(sword, 1, 1))
        equip["main_hand"] = sl

        expect_equal(iset:isSatisfied(equip), true)
    end)

    -- @description Verifies case: not satisfied when tag missing.
    it("not satisfied when tag missing", function()
        local iset = inventory.newItemSet("mage_set")
        iset:addRequirement("arcane", "")

        local equip = {}
        local sword = inventory.newItem("sword")
        local sl = inventory.newSlot("any", inventory.SlotState.Active)
        sl:setStack(inventory.newItemStack(sword, 1, 1))
        equip["main_hand"] = sl

        expect_equal(iset:isSatisfied(equip), false)
    end)

    -- @description Verifies case: getRequirements returns array.
    it("getRequirements returns array", function()
        local iset = inventory.newItemSet("test")
        iset:addRequirement("fire", "ring_slot")
        local reqs = iset:getRequirements()
        expect_equal(#reqs, 1)
        expect_equal(reqs[1].tag, "fire")
        expect_equal(reqs[1].slot_filter, "ring_slot")
    end)
end)

-- ─── Inventory ────────────────────────────────────────────────────────────────

-- @description Validates whole-inventory orchestration across containers, equipment slots, item counts, transfers, stack operations, and subsystem toggles.
describe("Inventory", function()
    -- @covers library.inventory.newInventory
    -- @description Verifies case: addContainer / getContainer round-trip.
    it("addContainer / getContainer round-trip", function()
        local inv = inventory.newInventory()
        local c   = inventory.newContainer("bag", "unlimited", 0)
        inv:addContainer("bag", c)
        expect_equal(inv:getContainer("bag"), c)
    end)

    -- @description Verifies case: containerNames returns insertion order.
    it("containerNames returns insertion order", function()
        local inv = inventory.newInventory()
        inv:addContainer("bag", inventory.newContainer("bag", "unlimited", 0))
        inv:addContainer("pouch", inventory.newContainer("pouch", "unlimited", 0))
        local names = inv:containerNames()
        expect_equal(names[1], "bag")
        expect_equal(names[2], "pouch")
    end)

    -- @description Verifies case: removeContainer returns true.
    it("removeContainer returns true", function()
        local inv = inventory.newInventory()
        inv:addContainer("bag", inventory.newContainer("bag", "unlimited", 0))
        expect_equal(inv:removeContainer("bag"), true)
        expect_equal(inv:getContainer("bag"), nil)
    end)

    -- @description Verifies case: countItem aggregates across containers.
    it("countItem aggregates across containers", function()
        local inv = inventory.newInventory()
        local c1  = inventory.newContainer("bag1", "unlimited", 0)
        local c2  = inventory.newContainer("bag2", "unlimited", 0)
        local it  = inventory.newItem("coin")
        it:setStackLimit(100)
        c1:addItem(it, 10)
        c2:addItem(it, 15)
        inv:addContainer("bag1", c1)
        inv:addContainer("bag2", c2)
        expect_equal(inv:countItem("coin"), 25)
    end)

    -- @description Verifies case: hasItem checks across containers.
    it("hasItem checks across containers", function()
        local inv = inventory.newInventory()
        local c   = inventory.newContainer("bag", "unlimited", 0)
        local it  = inventory.newItem("gem")
        it:setStackLimit(10)
        c:addItem(it, 5)
        inv:addContainer("bag", c)
        expect_equal(inv:hasItem("gem", 5), true)
        expect_equal(inv:hasItem("gem", 6), false)
    end)

    -- @description Verifies case: removeFromAny removes across containers.
    it("removeFromAny removes across containers", function()
        local inv = inventory.newInventory()
        local c1  = inventory.newContainer("bag1", "unlimited", 0)
        local c2  = inventory.newContainer("bag2", "unlimited", 0)
        local it  = inventory.newItem("wood")
        it:setStackLimit(100)
        c1:addItem(it, 5)
        c2:addItem(it, 10)
        inv:addContainer("bag1", c1)
        inv:addContainer("bag2", c2)
        expect_equal(inv:removeFromAny("wood", 12), true)
        expect_equal(inv:countItem("wood"), 3)
    end)

    -- @description Verifies case: removeFromAny returns false when not enough.
    it("removeFromAny returns false when not enough", function()
        local inv = inventory.newInventory()
        local c   = inventory.newContainer("bag", "unlimited", 0)
        local it  = inventory.newItem("gem")
        it:setStackLimit(10)
        c:addItem(it, 3)
        inv:addContainer("bag", c)
        expect_equal(inv:removeFromAny("gem", 10), false)
    end)

    -- @description Verifies case: equip/unequip round-trip.
    it("equip/unequip round-trip", function()
        local inv = inventory.newInventory()
        local sl  = inventory.newSlot("any", inventory.SlotState.Active)
        inv:addEquipSlot("main_hand", sl)
        local sword = inventory.newItem("longsword")
        local st    = inventory.newItemStack(sword, 1, 1)
        expect_equal(inv:equip("main_hand", st), true)
        expect_equal(inv:getEquipSlot("main_hand"):isEmpty(), false)
        local returned = inv:unequip("main_hand")
        expect_equal(returned:getType(), "longsword")
        expect_equal(inv:getEquipSlot("main_hand"):isEmpty(), true)
    end)

    -- @description Verifies case: equip returns false for missing slot.
    it("equip returns false for missing slot", function()
        local inv = inventory.newInventory()
        local sword = inventory.newItem("sword")
        expect_equal(inv:equip("missing", inventory.newItemStack(sword, 1, 1)), false)
    end)

    -- @description Verifies case: equipSlotNames insertion order.
    it("equipSlotNames insertion order", function()
        local inv = inventory.newInventory()
        inv:addEquipSlot("head", inventory.newSlot("any", inventory.SlotState.Active))
        inv:addEquipSlot("chest", inventory.newSlot("any", inventory.SlotState.Active))
        local names = inv:equipSlotNames()
        expect_equal(names[1], "head")
        expect_equal(names[2], "chest")
    end)

    -- @description Verifies case: subsystem enable/disable/check.
    it("subsystem enable/disable/check", function()
        local inv = inventory.newInventory()
        expect_equal(inv:isSubsystemEnabled("weight"), false)
        inv:enableSubsystem("weight")
        expect_equal(inv:isSubsystemEnabled("weight"), true)
        inv:disableSubsystem("weight")
        expect_equal(inv:isSubsystemEnabled("weight"), false)
    end)

    -- @description Verifies case: addItemSet / getActiveSets.
    it("addItemSet / getActiveSets", function()
        local inv  = inventory.newInventory()
        local iset = inventory.newItemSet("warrior_set")
        iset:addRequirement("warrior", "")
        inv:addItemSet(iset)

        local sl    = inventory.newSlot("any", inventory.SlotState.Active)
        local sword = inventory.newItem("greatsword")
        sword:addTag("warrior")
        sl:setStack(inventory.newItemStack(sword, 1, 1))
        inv:addEquipSlot("main_hand", sl)

        local active = inv:getActiveSets()
        expect_equal(#active, 1)
        expect_equal(active[1]:getName(), "warrior_set")
    end)

    -- @description Verifies case: transfer between container slots.
    it("transfer between container slots", function()
        local inv = inventory.newInventory()
        local c1  = inventory.newContainer("src",  "fixed", 2)
        local c2  = inventory.newContainer("dest", "fixed", 2)
        local it  = inventory.newItem("gem")
        c1:addItem(it, 1)
        inv:addContainer("src",  c1)
        inv:addContainer("dest", c2)
        expect_equal(inv:transfer("src", 1, "dest", 1), true)
        expect_equal(c1:countItem("gem"), 0)
        expect_equal(c2:countItem("gem"), 1)
    end)

    -- @description Verifies case: getItemSets returns all registered sets.
    it("getItemSets returns all registered sets", function()
        local inv  = inventory.newInventory()
        local s1   = inventory.newItemSet("set_a")
        local s2   = inventory.newItemSet("set_b")
        inv:addItemSet(s1)
        inv:addItemSet(s2)
        local sets = inv:getItemSets()
        expect_equal(#sets, 2)
        expect_equal(sets[1]:getName(), "set_a")
        expect_equal(sets[2]:getName(), "set_b")
    end)

    -- @description Verifies case: removeEquipSlot removes and returns true.
    it("removeEquipSlot removes and returns true", function()
        local inv = inventory.newInventory()
        inv:addEquipSlot("ring", inventory.newSlot("any", inventory.SlotState.Active))
        expect_equal(inv:removeEquipSlot("ring"), true)
        expect_equal(inv:getEquipSlot("ring"), nil)
        expect_equal(inv:removeEquipSlot("ring"), false)
    end)

    -- @description Verifies case: splitStack splits into next empty slot in same container.
    it("splitStack splits into next empty slot in same container", function()
        local inv = inventory.newInventory()
        local c   = inventory.newContainer("bag", "fixed", 3)
        local it  = inventory.newItem("arrow")
        it:setStackLimit(20)
        c:addItem(it, 10)
        inv:addContainer("bag", c)
        expect_equal(inv:splitStack("bag", 1, 4), true)
        expect_equal(c:countItem("arrow"), 10)  -- total unchanged
        expect_equal(c:getSlot(1):getStack():getQuantity(), 6)
        expect_equal(c:getSlot(2):getStack():getQuantity(), 4)
    end)

    -- @description Verifies case: splitStack returns false when not enough items.
    it("splitStack returns false when not enough items", function()
        local inv = inventory.newInventory()
        local c   = inventory.newContainer("bag", "fixed", 3)
        local it  = inventory.newItem("gem")
        it:setStackLimit(5)
        c:addItem(it, 2)
        inv:addContainer("bag", c)
        expect_equal(inv:splitStack("bag", 1, 5), false)
        expect_equal(c:getSlot(1):getStack():getQuantity(), 2)  -- unchanged
    end)

    -- @description Verifies case: mergeStacks merges two same-type stacks in same container.
    it("mergeStacks merges two same-type stacks in same container", function()
        local inv = inventory.newInventory()
        local c   = inventory.newContainer("bag", "fixed", 3)
        local coin = inventory.newItem("coin")
        coin:setStackLimit(20)
        -- Place stacks directly so they land in separate slots
        c:getSlot(1):setStack(inventory.newItemStack(coin, 5, 20))
        c:getSlot(2):setStack(inventory.newItemStack(coin, 3, 20))
        inv:addContainer("bag", c)
        expect_equal(inv:mergeStacks("bag", 2, 1), true)
        expect_equal(c:getSlot(1):getStack():getQuantity(), 8)
        expect_equal(c:getSlot(2):isEmpty(), true)
    end)

    -- @description Verifies case: mergeStacks returns false for type mismatch.
    it("mergeStacks returns false for type mismatch", function()
        local inv  = inventory.newInventory()
        local c    = inventory.newContainer("bag", "fixed", 3)
        local sword = inventory.newItem("sword")
        local axe   = inventory.newItem("axe")
        c:getSlot(1):setStack(inventory.newItemStack(sword, 1, 1))
        c:getSlot(2):setStack(inventory.newItemStack(axe,   1, 1))
        inv:addContainer("bag", c)
        expect_equal(inv:mergeStacks("bag", 1, 2), false)
    end)

    -- @description Verifies case: swap exchanges items between two container slots.
    it("swap exchanges items between two container slots", function()
        local inv = inventory.newInventory()
        local c1  = inventory.newContainer("bag1", "fixed", 2)
        local c2  = inventory.newContainer("bag2", "fixed", 2)
        local sword  = inventory.newItem("sword")
        local potion = inventory.newItem("potion")
        c1:getSlot(1):setStack(inventory.newItemStack(sword,  1, 1))
        c2:getSlot(1):setStack(inventory.newItemStack(potion, 1, 1))
        inv:addContainer("bag1", c1)
        inv:addContainer("bag2", c2)
        expect_equal(inv:swap("bag1", 1, "bag2", 1), true)
        expect_equal(c1:getSlot(1):getItem():getType(), "potion")
        expect_equal(c2:getSlot(1):getItem():getType(), "sword")
    end)

    -- @description Verifies case: swap within same container.
    it("swap within same container", function()
        local inv = inventory.newInventory()
        local c   = inventory.newContainer("bag", "fixed", 3)
        local sword = inventory.newItem("sword")
        local arrow = inventory.newItem("arrow")
        arrow:setStackLimit(10)
        c:getSlot(1):setStack(inventory.newItemStack(sword, 1, 1))
        c:getSlot(2):setStack(inventory.newItemStack(arrow, 5, 10))
        inv:addContainer("bag", c)
        expect_equal(inv:swap("bag", 1, "bag", 2), true)
        expect_equal(c:getSlot(1):getItem():getType(), "arrow")
        expect_equal(c:getSlot(2):getItem():getType(), "sword")
    end)
end)

-- ─── Container.removeSlot ─────────────────────────────────────────────────────

-- @description Focuses on removing container slots safely, including index validation and post-removal slot compaction.
describe("Container.removeSlot", function()
    -- @covers library.inventory.newContainer
    -- @description Verifies case: removes a slot by 1-based index and reduces count.
    it("removes a slot by 1-based index and reduces count", function()
        local c = inventory.newContainer("bag", "fixed", 3)
        local it = inventory.newItem("herb")
        c:addItem(it, 1)  -- goes into slot 1
        expect_equal(c:slotCount(), 3)
        expect_equal(c:removeSlot(1), true)
        expect_equal(c:slotCount(), 2)
        -- The herb is gone; slot 1 is now the old slot 2
        expect_equal(c:getSlot(1):isEmpty(), true)
    end)

    -- @description Verifies case: returns false for out-of-range index.
    it("returns false for out-of-range index", function()
        local c = inventory.newContainer("bag", "fixed", 2)
        expect_equal(c:removeSlot(0),  false)
        expect_equal(c:removeSlot(3),  false)
    end)
end)

-- ─── Slot.setState / getState / getSlotType / SlotState constants ─────────────

-- @description Confirms slot state getters and setters and the exported slot-state enum string values.
describe("Slot.state", function()
    -- @covers library.inventory.newSlot
    -- @covers library.inventory.SlotState
    -- @description Verifies case: getState returns initial state.
    it("getState returns initial state", function()
        local sl = inventory.newSlot("weapon", inventory.SlotState.Passive)
        expect_equal(sl:getState(), inventory.SlotState.Passive)
    end)

    -- @description Verifies case: setState changes state.
    it("setState changes state", function()
        local sl = inventory.newSlot("any", inventory.SlotState.Active)
        sl:setState(inventory.SlotState.Idle)
        expect_equal(sl:getState(), inventory.SlotState.Idle)
    end)

    -- @description Verifies case: getSlotType returns the type filter.
    it("getSlotType returns the type filter", function()
        local sl = inventory.newSlot("helmet", inventory.SlotState.Active)
        expect_equal(sl:getSlotType(), "helmet")
    end)

    -- @description Verifies case: SlotState constants are correct strings.
    it("SlotState constants are correct strings", function()
        expect_equal(inventory.SlotState.Active,  "active")
        expect_equal(inventory.SlotState.Passive, "passive")
        expect_equal(inventory.SlotState.Idle,    "idle")
    end)
end)

-- ─── ContainerMode enum ───────────────────────────────────────────────────────

-- @description Verifies container mode constants and confirms they can be passed directly into container construction.
describe("ContainerMode", function()
    -- @covers library.inventory.ContainerMode
    -- @covers library.inventory.newContainer
    -- @description Verifies case: enum has correct string values.
    it("enum has correct string values", function()
        expect_equal(inventory.ContainerMode.fixed,      "fixed")
        expect_equal(inventory.ContainerMode.unlimited,  "unlimited")
        expect_equal(inventory.ContainerMode.expandable, "expandable")
    end)

    -- @description Verifies case: can be used directly with newContainer.
    it("can be used directly with newContainer", function()
        local c = inventory.newContainer("bag", inventory.ContainerMode.fixed, 4)
        expect_equal(c:getMode(), "fixed")
        expect_equal(c:slotCount(), 4)
    end)
end)

-- ─── Bug fix: expandable overflow ──────────────────────────────────────────────

-- @description Validates that expandable containers respect the max_slots cap.
describe("Container.expandable.bounds", function()
    -- @description Verifies case: expand stops at max_slots.
    it("expand stops at max_slots", function()
        -- Start with 2 slots, max 4
        local c = inventory.newContainer("pouch", "expandable", 2, 4)
        expect_equal(c:slotCount(), 2)
        expect_equal(c:getCapacity(), 4)
        -- Expand by 5 — only 2 should be added (capped at 4 total)
        local ok = c:expand(5)
        expect_equal(ok, true)
        expect_equal(c:slotCount(), 4)
        -- Another expand should fail — already at cap
        expect_equal(c:expand(1), false)
        expect_equal(c:slotCount(), 4)
    end)

    -- @description Verifies case: setCapacity adjusts max for expandable.
    it("setCapacity adjusts max for expandable", function()
        local c = inventory.newContainer("pouch", "expandable", 2, 3)
        expect_equal(c:getCapacity(), 3)
        c:setCapacity(6)
        expect_equal(c:getCapacity(), 6)
        c:expand(4)
        expect_equal(c:slotCount(), 6) -- capped at new max
    end)

    -- @description Verifies case: setCapacity cannot shrink below current count.
    it("setCapacity cannot shrink below current count", function()
        local c = inventory.newContainer("pouch", "expandable", 3, 5)
        c:setCapacity(1) -- 3 slots already exist, so clamps to 3
        expect_equal(c:getCapacity(), 3)
    end)

    -- @description Verifies case: addSlot respects max_slots in expandable mode.
    it("addSlot respects max_slots in expandable mode", function()
        local c = inventory.newContainer("pouch", "expandable", 2, 3)
        c:addSlot(inventory.newSlot("any", inventory.SlotState.Active)) -- 3rd slot OK
        expect_equal(c:slotCount(), 3)
        c:addSlot(inventory.newSlot("any", inventory.SlotState.Active)) -- 4th blocked
        expect_equal(c:slotCount(), 3)
    end)

    -- @description Verifies case: default max_slots equals initial slot_count.
    it("default max_slots equals initial slot_count when no max given", function()
        local c = inventory.newContainer("pouch", "expandable", 3)
        expect_equal(c:getCapacity(), 3)
        expect_equal(c:expand(1), false) -- already at cap
    end)
end)

-- ─── Bug fix: multi-stack merge ─────────────────────────────────────────────

-- @description Validates that addItem merges into ALL matching partial stacks.
describe("Container.addItem.merge", function()
    -- @description Verifies case: merges across multiple partial stacks.
    it("merges across multiple partial stacks", function()
        local c = inventory.newContainer("bag", "fixed", 3)
        local arrow = inventory.newItem("arrow")
        arrow:setStackLimit(10)
        -- Manually place two partial stacks
        c:getSlot(1):setStack(inventory.newItemStack(arrow, 7, 10))
        c:getSlot(2):setStack(inventory.newItemStack(arrow, 6, 10))
        -- Adding 5 should fill slot 1 (3 more) then slot 2 (2 more)
        expect_equal(c:addItem(arrow, 5), true)
        expect_equal(c:getSlot(1):getStack():getQuantity(), 10) -- filled
        expect_equal(c:getSlot(2):getStack():getQuantity(), 8)  -- received 2
        expect_equal(c:countItem("arrow"), 18) -- 7+6+5 = 18
    end)

    -- @description Verifies case: overflow goes into empty slot after filling stacks.
    it("overflow goes into empty slot after filling stacks", function()
        local c = inventory.newContainer("bag", "fixed", 3)
        local coin = inventory.newItem("coin")
        coin:setStackLimit(5)
        c:getSlot(1):setStack(inventory.newItemStack(coin, 4, 5))
        -- Add 8: 1 fills slot 1 (to 5), 5 goes to slot 2, 2 goes to slot 3
        expect_equal(c:addItem(coin, 8), true)
        expect_equal(c:getSlot(1):getStack():getQuantity(), 5)
        expect_equal(c:getSlot(2):getStack():getQuantity(), 5)
        expect_equal(c:getSlot(3):getStack():getQuantity(), 2)
    end)
end)

-- ─── Tag-based slot filtering in containers ─────────────────────────────────

-- @description Validates that tagged slots correctly accept/reject items via canAccept.
describe("Container.tagFiltering", function()
    -- @description Verifies case: typed slot in container accepts item with matching tag.
    it("typed slot in container accepts item with matching tag via addItem", function()
        -- Container with a "weapon" slot — item type is "magic_blade" but has "weapon" tag
        local c = inventory.newContainer("equip", "fixed", 0)
        local weapon_slot = inventory.newSlot("weapon", inventory.SlotState.Active)
        c:addSlot(weapon_slot)

        local blade = inventory.newItem("magic_blade")
        blade:addTag("weapon")
        expect_equal(c:addItem(blade, 1), true)
        expect_equal(c:countItem("magic_blade"), 1)
    end)

    -- @description Verifies case: typed slot rejects item without matching type or tag.
    it("typed slot rejects item without matching type or tag", function()
        local c = inventory.newContainer("equip", "fixed", 0)
        c:addSlot(inventory.newSlot("weapon", inventory.SlotState.Active))

        local potion = inventory.newItem("potion")
        expect_equal(c:addItem(potion, 1), false)
        expect_equal(c:countItem("potion"), 0)
    end)

    -- @description Verifies case: item type match overrides tag check.
    it("item type match satisfies slot type without needing tag", function()
        local c = inventory.newContainer("equip", "fixed", 0)
        c:addSlot(inventory.newSlot("sword", inventory.SlotState.Active))

        local sword = inventory.newItem("sword")
        expect_equal(c:addItem(sword, 1), true)
    end)
end)

-- ─── Input validation ─────────────────────────────────────────────────────────

-- @description Validates that input validation catches bad arguments early.
describe("InputValidation", function()
    -- @description Verifies case: newItem rejects empty string.
    it("newItem rejects empty string", function()
        expect_error(function() inventory.newItem("") end)
    end)

    -- @description Verifies case: newItem rejects nil.
    it("newItem rejects nil", function()
        expect_error(function() inventory.newItem(nil) end)
    end)

    -- @description Verifies case: setWeight rejects negative.
    it("setWeight rejects negative", function()
        local it = inventory.newItem("gem")
        expect_error(function() it:setWeight(-1) end)
    end)

    -- @description Verifies case: addItem rejects zero quantity.
    it("addItem rejects zero quantity", function()
        local c = inventory.newContainer("bag", "unlimited", 0)
        local it = inventory.newItem("coin")
        expect_error(function() c:addItem(it, 0) end)
    end)

    -- @description Verifies case: addItem rejects negative quantity.
    it("addItem rejects negative quantity", function()
        local c = inventory.newContainer("bag", "unlimited", 0)
        local it = inventory.newItem("coin")
        expect_error(function() c:addItem(it, -5) end)
    end)

    -- @description Verifies case: removeItem rejects zero quantity.
    it("removeItem rejects zero quantity", function()
        local c = inventory.newContainer("bag", "unlimited", 0)
        expect_error(function() c:removeItem("coin", 0) end)
    end)

    -- @description Verifies case: newContainer rejects invalid mode.
    it("newContainer rejects invalid mode", function()
        expect_error(function() inventory.newContainer("bag", "broken", 5) end)
    end)

    -- @description Verifies case: setWeightLimit rejects negative.
    it("setWeightLimit rejects negative", function()
        local c = inventory.newContainer("bag", "unlimited", 0)
        expect_error(function() c:setWeightLimit(-1) end)
    end)
end)

test_summary()
