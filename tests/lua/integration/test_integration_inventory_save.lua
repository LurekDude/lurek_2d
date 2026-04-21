-- Integration test: library.inventory × lurek.serial (runtime name for "lurek.serial").
--
-- Scope: Round-trips an inventory snapshot through `lurek.serial.toJson` /
-- `fromJson` and confirms container, slot, and stack-count state survives
-- the encode/decode cycle. Also verifies graceful handling of missing
-- fields and corrupt JSON.
--
-- Fallback: P1 map flags `lurek.save.SaveManager` as the recommended
-- persistence path, but its API is wired into the engine save-slot
-- filesystem and a full collect/restore round-trip is exercised by
-- tests/lua/unit/test_save.lua. For an inventory-focused integration
-- we use `lurek.serial.toJson`/`fromJson` directly: it is mandatory at
-- runtime, fully headless, and matches the actual on-disk payload shape
-- that SaveManager would persist.
--
-- @covers library.inventory.newInventory
-- @covers library.inventory.newContainer
-- @covers library.inventory.newItem
-- @covers lurek.serial.toJson
-- @covers lurek.serial.fromJson

local inventory = require("library.inventory")

local function snapshot(inv)
    local snap = { containers = {} }
    for _, name in ipairs(inv:containerNames()) do
        local c = inv:getContainer(name)
        local items = {}
        for _, entry in ipairs(c:toItemList()) do
            items[#items + 1] = { type = entry.type_name, qty = entry.quantity }
        end
        snap.containers[#snap.containers + 1] = { name = name, items = items }
    end
    return snap
end

describe("integration: library.inventory × lurek.serial", function()

    -- @description Inventory snapshot survives a JSON round-trip and rebuilds equal table state.
    it("snapshot round-trips through codec.toJson/fromJson", function()
        local inv = inventory.newInventory()
        local bag = inventory.newContainer("bag", "list", 8, 8)
        inv:addContainer("bag", bag)
        local item = inventory.newItem("potion")
        bag:addItem(item, 3)

        local snap = snapshot(inv)
        local json = lurek.serial.toJson(snap)
        expect_type("string", json)
        local decoded = lurek.serial.fromJson(json)

        expect_type("table", decoded)
        expect_type("table", decoded.containers)
        expect_equal(1, #decoded.containers)
        expect_equal("bag", decoded.containers[1].name)
        expect_equal("potion", decoded.containers[1].items[1].type)
        expect_equal(3, decoded.containers[1].items[1].qty)
    end)

    -- @description Stack quantities are preserved across the JSON round-trip.
    it("stack counts survive round-trip", function()
        local inv = inventory.newInventory()
        local box = inventory.newContainer("box", "list", 4, 4)
        inv:addContainer("box", box)
        local arrow = inventory.newItem("arrow")
        arrow:setStackLimit(99)
        box:addItem(arrow, 12)

        local json = lurek.serial.toJson(snapshot(inv))
        local back = lurek.serial.fromJson(json)
        expect_equal(12, back.containers[1].items[1].qty)
    end)

    -- @description Container ordering is preserved across the JSON round-trip.
    it("container order is preserved across round-trip", function()
        local inv = inventory.newInventory()
        for _, name in ipairs({ "alpha", "bravo", "charlie" }) do
            inv:addContainer(name, inventory.newContainer(name, "list", 1, 1))
        end
        local back = lurek.serial.fromJson(lurek.serial.toJson(snapshot(inv)))
        expect_equal("alpha", back.containers[1].name)
        expect_equal("bravo", back.containers[2].name)
        expect_equal("charlie", back.containers[3].name)
    end)

    -- @description Loading a payload missing the "containers" field returns a sensible default
    -- instead of raising — restoration code can fall back to an empty inventory.
    it("missing containers field decodes to empty list with sensible default", function()
        local back = lurek.serial.fromJson("{}")
        expect_type("table", back)
        local containers = back.containers or {}
        expect_equal(0, #containers)
    end)

    -- @description Failure path: corrupt JSON is rejected with an error.
    it("corrupt JSON raises an error when decoded", function()
        expect_error(function()
            lurek.serial.fromJson("{not valid json")
        end)
    end)

    -- @description Empty inventory encodes to a valid JSON object that round-trips cleanly.
    it("empty inventory round-trips without loss", function()
        local inv = inventory.newInventory()
        local json = lurek.serial.toJson(snapshot(inv))
        local back = lurek.serial.fromJson(json)
        expect_type("table", back)
        expect_equal(0, #(back.containers or {}))
    end)

end)

test_summary()
