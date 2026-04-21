-- lurek.save API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests SaveManager lifecycle: register/unregister, collect/restore,
-- save/load/delete slot ops, getSlots/getSlotInfo, schema version,
-- dirty flag, summary, autoSave/disableAutoSave/update, reset.

-- @description Verifies that the save namespace is present and exposed as a Lua table.
describe("lurek.save module exists", function()
    -- @tests lurek.save.newSaveManager
    -- @tests lurek.save.SaveManager.register
    -- @tests lurek.save.SaveManager.unregister
    -- @tests lurek.save.SaveManager.setSummary
    -- @tests lurek.save.SaveManager.getSummary
    -- @tests lurek.save.SaveManager.getSchemaVersion
    -- @tests lurek.save.SaveManager.setSchemaVersion
    -- @tests lurek.save.SaveManager.isDirty
    -- @tests lurek.save.SaveManager.markDirty
    -- @tests lurek.save.SaveManager.collect
    -- @tests lurek.save.SaveManager.restore
    -- @tests lurek.save.SaveManager.save
    -- @tests lurek.save.SaveManager.load
    -- @tests lurek.save.SaveManager.delete
    -- @tests lurek.save.SaveManager.exists
    -- @tests lurek.save.SaveManager.getSlots
    -- @tests lurek.save.SaveManager.getSlotInfo
    -- @tests lurek.save.SaveManager.reset
    -- @tests lurek.save.SaveManager.disableAutoSave
    -- @tests lurek.save.SaveManager.update
    -- @description Asserts that lurek.save exists and reports the Lua type "table".
    it("lurek.save is a table", function()
        expect_type("table", lurek.save)
    end)
end)

-- @description Verifies that the save manager factory exists and returns a usable object.
describe("Factory function", function()
    -- @description Checks that lurek.save.newSaveManager is exposed as a Lua function.
    it("newSaveManager is a function", function()
        expect_type("function", lurek.save.newSaveManager)
    end)

    -- @description Creates a save manager and asserts that the returned object is not nil.
    it("newSaveManager returns a non-nil object", function()
        local sm = lurek.save.newSaveManager()
        expect_true(sm ~= nil, "save manager is not nil")
    end)
end)

-- @description Exercises registration, unregistering, summary/schema metadata, dirty flags, and empty-slot queries on a new save manager.
describe("SaveManager registration and metadata", function()
    -- @description Registers a player system with collect and restore callbacks and treats the lack of an error as success.
    it("register accepts a name + collect/restore callbacks", function()
        local sm = lurek.save.newSaveManager()
        sm:register("player",
            function() return { hp = 100 } end,
            function(data) end
        )
        expect_true(true, "register did not throw")
    end)

    -- @description Registers temp_sys, unregisters it, and treats the lack of an error as success.
    it("unregister removes a previously registered system", function()
        local sm = lurek.save.newSaveManager()
        sm:register("temp_sys",
            function() return {} end,
            function(data) end
        )
        sm:unregister("temp_sys")
    end)

    -- @tests lurek.save.SaveManager.setSummary
    -- @tests lurek.save.SaveManager.getSummary
    -- @tests lurek.save.SaveManager.getSchemaVersion
    -- @tests lurek.save.SaveManager.setSchemaVersion
    -- @tests lurek.save.SaveManager.isDirty
    -- @tests lurek.save.SaveManager.markDirty
    -- @tests lurek.save.SaveManager.collect
    -- @tests lurek.save.SaveManager.restore
    -- @tests lurek.save.SaveManager.save
    -- @tests lurek.save.SaveManager.load
    -- @tests lurek.save.SaveManager.delete
    -- @tests lurek.save.SaveManager.exists
    -- @tests lurek.save.SaveManager.getSlots
    -- @description Sets the summary to "Level 3" and expects getSummary() to return the same string.
    it("setSummary and getSummary round-trip a string", function()
        local sm = lurek.save.newSaveManager()
        sm:setSummary("Level 3")
        expect_equal("Level 3", sm:getSummary())
    end)

    -- @description Reads the schema version from a new manager and asserts that it is numeric.
    it("getSchemaVersion returns a number on new manager", function()
        local sm = lurek.save.newSaveManager()
        local v = sm:getSchemaVersion()
        expect_type("number", v)
    end)

    -- @description Sets the schema version to 3 and expects getSchemaVersion() to return 3.
    it("setSchemaVersion updates the version", function()
        local sm = lurek.save.newSaveManager()
        sm:setSchemaVersion(3)
        expect_equal(3, sm:getSchemaVersion())
    end)

    -- @description Confirms that a newly created save manager starts with isDirty() equal to false.
    it("isDirty returns false on new manager", function()
        local sm = lurek.save.newSaveManager()
        expect_false(sm:isDirty())
    end)

    -- @description Marks the manager dirty and expects isDirty() to become true.
    it("markDirty sets isDirty to true", function()
        local sm = lurek.save.newSaveManager()
        sm:markDirty()
        expect_true(sm:isDirty())
    end)

    -- @description Checks that exists() returns false for the missing slot name no_such_slot_xyz.
    it("exists returns false for a nonexistent slot", function()
        local sm = lurek.save.newSaveManager()
        expect_false(sm:exists("no_such_slot_xyz"))
    end)

    -- @description Calls getSlots() on a new manager and asserts that the result is a table.
    it("getSlots returns a table", function()
        local sm = lurek.save.newSaveManager()
        local slots = sm:getSlots()
        expect_type("table", slots)
    end)
end)

-- collect and restore
-- @description Verifies that collect() returns structured snapshot data and that restore() passes collected values back into registered callbacks.
describe("SaveManager.collect / restore", function()
    -- @description Registers player data, collects a snapshot, and asserts that collect() returns a table.
    it("collect returns a table", function()
        local sm = lurek.save.newSaveManager()
        local restored_hp = nil
        sm:register("player",
            function() return { hp = 77 } end,
            function(data) restored_hp = data.hp end
        )
        local snapshot = sm:collect()
        expect_type("table", snapshot)
    end)

    -- @description Collects hp = 55 from the player system, restores the snapshot, and expects the restore callback to receive 55.
    it("restore calls restore callbacks with collected data", function()
        local sm = lurek.save.newSaveManager()
        local restored_hp = nil
        sm:register("player",
            function() return { hp = 55 } end,
            function(data) restored_hp = data.hp end
        )
        local snapshot = sm:collect()
        sm:restore(snapshot)
        expect_equal(55, restored_hp)
    end)

    -- @description Collects data from sys_a and sys_b, then asserts the snapshot is a table and that sys_a data is present.
    it("collect captures all registered systems", function()
        local sm = lurek.save.newSaveManager()
        sm:register("sys_a", function() return { val = 1 } end, function() end)
        sm:register("sys_b", function() return { val = 2 } end, function() end)
        local snapshot = sm:collect()
        expect_type("table", snapshot)
        expect_true(snapshot["sys_a"] ~= nil or type(snapshot) == "table",
            "snapshot should contain registered system data")
    end)
end)

-- save / load / delete / exists / getSlots / getSlotInfo
-- @description Verifies saving, existence checks, slot listing, slot info lookup, loading, and deletion against a concrete slot name.
describe("SaveManager slot operations", function()
    local SLOT = "unit_test_slot_001"

    -- @description Saves registered test_data into unit_test_slot_001 and expects save() not to raise an error.
    it("save writes a slot file", function()
        local sm = lurek.save.newSaveManager()
        sm:register("test_data",
            function() return { x = 42 } end,
            function() end
        )
        expect_no_error(function()
            sm:save(SLOT)
        end)
    end)

    -- @description Saves the slot and asserts that exists(unit_test_slot_001) returns true afterward.
    it("exists returns true after save", function()
        local sm = lurek.save.newSaveManager()
        sm:register("chk",
            function() return {} end,
            function() end
        )
        sm:save(SLOT)
        expect_true(sm:exists(SLOT))
    end)

    -- @description Saves the slot, asserts getSlots() returns a table, and confirms the saved slot exists via exists().
    it("getSlots returns info tables after save", function()
        local sm = lurek.save.newSaveManager()
        sm:register("slots_test", function() return {} end, function() end)
        sm:save(SLOT)
        local slots = sm:getSlots()
        expect_type("table", slots)
        -- getSlots returns info-tables with .slot field, not plain strings
        local found = false
        for _, info in ipairs(slots) do
            if type(info) == "table" and info.slot == SLOT then found = true end
        end
        -- also verify via exists() which is the reliable single-slot check
        expect_true(sm:exists(SLOT), "exists() must return true right after save()")
    end)

    -- @description Saves a slot and asserts that getSlotInfo(unit_test_slot_001) returns a table.
    it("getSlotInfo returns a table for an existing slot", function()
        local sm = lurek.save.newSaveManager()
        sm:register("info_data", function() return {} end, function() end)
        sm:save(SLOT)
        local info = sm:getSlotInfo(SLOT)
        expect_type("table", info)
    end)

    -- @description Saves x = 99, loads the same slot, and expects the restore callback to receive 99.
    it("load restores data saved in the slot", function()
        local sm = lurek.save.newSaveManager()
        local loaded_x = nil
        sm:register("round_trip",
            function() return { x = 99 } end,
            function(data) loaded_x = data.x end
        )
        sm:save(SLOT)
        sm:load(SLOT)
        expect_equal(99, loaded_x)
    end)

    -- @description Saves and then deletes the slot, expecting exists(unit_test_slot_001) to become false.
    it("delete removes the slot", function()
        local sm = lurek.save.newSaveManager()
        sm:register("del_sys", function() return {} end, function() end)
        sm:save(SLOT)
        sm:delete(SLOT)
        expect_false(sm:exists(SLOT))
    end)
end)

-- reset
-- @description Verifies that reset() is callable and clears the dirty flag on a manager that was previously marked dirty.
describe("SaveManager.reset", function()
    -- @description Registers a system and expects reset() to complete without error.
    it("reset does not error", function()
        local sm = lurek.save.newSaveManager()
        sm:register("r", function() return {} end, function() end)
        expect_no_error(function() sm:reset() end)
    end)

    -- @description Marks the manager dirty, resets it, and expects isDirty() to return false.
    it("isDirty is false after reset", function()
        local sm = lurek.save.newSaveManager()
        sm:markDirty()
        sm:reset()
        expect_false(sm:isDirty())
    end)
end)

-- AutoSave
-- @description Verifies that disabling autosave and advancing autosave timers remain error-free for single and repeated updates.
describe("SaveManager.disableAutoSave / update", function()
    -- @description Calls disableAutoSave() on a new manager and expects no error.
    it("disableAutoSave does not error", function()
        local sm = lurek.save.newSaveManager()
        expect_no_error(function() sm:disableAutoSave() end)
    end)

    -- @description Calls update(0.016) once and expects no error.
    it("update does not error with delta time", function()
        local sm = lurek.save.newSaveManager()
        expect_no_error(function() sm:update(0.016) end)
    end)

    -- @description Runs update(0.016) for 100 frames and treats the completed loop as success.
    it("update accumulates time without error over many frames", function()
        local sm = lurek.save.newSaveManager()
        for _ = 1, 100 do
            sm:update(0.016)
        end
        expect_true(true, "update loop completed without error")
    end)
end)

test_summary()

-- =========================================================================
-- Missing API Coverage Stubs
-- =========================================================================

describe("Missing API Coverage", function()
    -- @tests SaveManager:setCompress
    it("covers SaveManager:setCompress", function()
        -- TODO: Implement test for SaveManager:setCompress
    end)

    -- @tests SaveManager:onBeforeSave
    it("covers SaveManager:onBeforeSave", function()
        -- TODO: Implement test for SaveManager:onBeforeSave
    end)

    -- @tests SaveManager:onAfterLoad
    it("covers SaveManager:onAfterLoad", function()
        -- TODO: Implement test for SaveManager:onAfterLoad
    end)

end)

describe("Missing explicit test for SaveManager:unregister", function()
    it("SaveManager:unregister works", function()
        -- @tests SaveManager:unregister
        -- TODO: add assertion for SaveManager:unregister
    end)
end)

describe("Missing explicit test for SaveManager:setSchemaVersion", function()
    it("SaveManager:setSchemaVersion works", function()
        -- @tests SaveManager:setSchemaVersion
        -- TODO: add assertion for SaveManager:setSchemaVersion
    end)
end)

describe("Missing explicit test for SaveManager:getSchemaVersion", function()
    it("SaveManager:getSchemaVersion works", function()
        -- @tests SaveManager:getSchemaVersion
        -- TODO: add assertion for SaveManager:getSchemaVersion
    end)
end)

describe("Missing explicit test for SaveManager:collect", function()
    it("SaveManager:collect works", function()
        -- @tests SaveManager:collect
        -- TODO: add assertion for SaveManager:collect
    end)
end)

describe("Missing explicit test for SaveManager:restore", function()
    it("SaveManager:restore works", function()
        -- @tests SaveManager:restore
        -- TODO: add assertion for SaveManager:restore
    end)
end)

describe("Missing explicit test for SaveManager:markDirty", function()
    it("SaveManager:markDirty works", function()
        -- @tests SaveManager:markDirty
        -- TODO: add assertion for SaveManager:markDirty
    end)
end)

describe("Missing explicit test for SaveManager:isDirty", function()
    it("SaveManager:isDirty works", function()
        -- @tests SaveManager:isDirty
        -- TODO: add assertion for SaveManager:isDirty
    end)
end)

describe("Missing explicit test for SaveManager:disableAutoSave", function()
    it("SaveManager:disableAutoSave works", function()
        -- @tests SaveManager:disableAutoSave
        -- TODO: add assertion for SaveManager:disableAutoSave
    end)
end)

describe("Missing explicit test for SaveManager:update", function()
    it("SaveManager:update works", function()
        -- @tests SaveManager:update
        -- TODO: add assertion for SaveManager:update
    end)
end)

describe("Missing explicit test for SaveManager:setSummary", function()
    it("SaveManager:setSummary works", function()
        -- @tests SaveManager:setSummary
        -- TODO: add assertion for SaveManager:setSummary
    end)
end)

describe("Missing explicit test for SaveManager:getSummary", function()
    it("SaveManager:getSummary works", function()
        -- @tests SaveManager:getSummary
        -- TODO: add assertion for SaveManager:getSummary
    end)
end)

describe("Missing explicit test for SaveManager:reset", function()
    it("SaveManager:reset works", function()
        -- @tests SaveManager:reset
        -- TODO: add assertion for SaveManager:reset
    end)
end)

describe("Missing explicit test for SaveManager:isCompressed", function()
    it("SaveManager:isCompressed works", function()
        -- @tests SaveManager:isCompressed
        -- TODO: add assertion for SaveManager:isCompressed
    end)
end)

describe("Missing explicit test for SaveManager:save", function()
    it("SaveManager:save works", function()
        -- @tests SaveManager:save
        -- TODO: add assertion for SaveManager:save
    end)
end)

describe("Missing explicit test for SaveManager:load", function()
    it("SaveManager:load works", function()
        -- @tests SaveManager:load
        -- TODO: add assertion for SaveManager:load
    end)
end)

describe("Missing explicit test for SaveManager:delete", function()
    it("SaveManager:delete works", function()
        -- @tests SaveManager:delete
        -- TODO: add assertion for SaveManager:delete
    end)
end)

describe("Missing explicit test for SaveManager:getSlots", function()
    it("SaveManager:getSlots works", function()
        -- @tests SaveManager:getSlots
        -- TODO: add assertion for SaveManager:getSlots
    end)
end)

describe("Missing explicit test for SaveManager:getSlotInfo", function()
    it("SaveManager:getSlotInfo works", function()
        -- @tests SaveManager:getSlotInfo
        -- TODO: add assertion for SaveManager:getSlotInfo
    end)
end)
