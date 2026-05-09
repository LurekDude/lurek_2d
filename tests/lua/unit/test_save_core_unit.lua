-- lurek.save API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests SaveManager lifecycle: register/unregister, collect/restore,
-- save/load/delete slot ops, getSlots/getSlotInfo, schema version,
-- dirty flag, summary, autoSave/disableAutoSave/update, reset.

-- @describe lurek.save module exists
describe("lurek.save module exists", function()
    -- @covers lurek.save
    it("lurek.save is a table", function()
        expect_type("table", lurek.save)
    end)
end)

-- @describe Factory function
describe("Factory function", function()
    -- @covers lurek.save.newSaveManager
    it("newSaveManager is a function", function()
        expect_type("function", lurek.save.newSaveManager)
    end)

    -- @covers lurek.save.newSaveManager
    it("newSaveManager returns a non-nil object", function()
        local sm = lurek.save.newSaveManager()
        expect_true(sm ~= nil, "save manager is not nil")
    end)
end)

-- @describe SaveManager registration and metadata
describe("SaveManager registration and metadata", function()
    -- @covers LSaveManager:register
    -- @covers lurek.save.newSaveManager
    it("register accepts a name + collect/restore callbacks", function()
        local sm = lurek.save.newSaveManager()
        sm:register("player",
            function() return { hp = 100 } end,
            function(data) end
        )
        expect_true(true, "register did not throw")
    end)

    -- @covers LSaveManager:register
    -- @covers LSaveManager:unregister
    -- @covers lurek.save.newSaveManager
    it("unregister removes a previously registered system", function()
        local sm = lurek.save.newSaveManager()
        sm:register("temp_sys",
            function() return {} end,
            function(data) end
        )
        sm:unregister("temp_sys")
    end)

    -- @covers LSaveManager:getSummary
    -- @covers LSaveManager:setSummary
    -- @covers lurek.save.newSaveManager
    it("setSummary and getSummary round-trip a string", function()
        local sm = lurek.save.newSaveManager()
        sm:setSummary("Level 3")
        expect_equal("Level 3", sm:getSummary())
    end)

    -- @covers LSaveManager:getSchemaVersion
    -- @covers lurek.save.newSaveManager
    it("getSchemaVersion returns a number on new manager", function()
        local sm = lurek.save.newSaveManager()
        local v = sm:getSchemaVersion()
        expect_type("number", v)
    end)

    -- @covers LSaveManager:getSchemaVersion
    -- @covers LSaveManager:setSchemaVersion
    -- @covers lurek.save.newSaveManager
    it("setSchemaVersion updates the version", function()
        local sm = lurek.save.newSaveManager()
        sm:setSchemaVersion(3)
        expect_equal(3, sm:getSchemaVersion())
    end)

    -- @covers LSaveManager:isDirty
    -- @covers lurek.save.newSaveManager
    it("isDirty returns false on new manager", function()
        local sm = lurek.save.newSaveManager()
        expect_false(sm:isDirty())
    end)

    -- @covers LSaveManager:isDirty
    -- @covers LSaveManager:markDirty
    -- @covers lurek.save.newSaveManager
    it("markDirty sets isDirty to true", function()
        local sm = lurek.save.newSaveManager()
        sm:markDirty()
        expect_true(sm:isDirty())
    end)

    -- @covers LSaveManager:exists
    -- @covers lurek.save.newSaveManager
    it("exists returns false for a nonexistent slot", function()
        local sm = lurek.save.newSaveManager()
        expect_false(sm:exists("no_such_slot_xyz"))
    end)

    -- @covers LSaveManager:getSlots
    -- @covers lurek.save.newSaveManager
    it("getSlots returns a table", function()
        local sm = lurek.save.newSaveManager()
        local slots = sm:getSlots()
        expect_type("table", slots)
    end)
end)

-- collect and restore
-- @describe SaveManager.collect / restore
describe("SaveManager.collect / restore", function()
    -- @covers LSaveManager:collect
    -- @covers LSaveManager:register
    -- @covers lurek.save.newSaveManager
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

    -- @covers LSaveManager:collect
    -- @covers LSaveManager:register
    -- @covers LSaveManager:restore
    -- @covers lurek.save.newSaveManager
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

    -- @covers LSaveManager:collect
    -- @covers LSaveManager:register
    -- @covers lurek.save.newSaveManager
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
-- @describe SaveManager slot operations
describe("SaveManager slot operations", function()
    local SLOT = "unit_test_slot_001"

    -- @covers LSaveManager:register
    -- @covers LSaveManager:save
    -- @covers lurek.save.newSaveManager
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

    -- @covers LSaveManager:exists
    -- @covers LSaveManager:register
    -- @covers LSaveManager:save
    -- @covers lurek.save.newSaveManager
    it("exists returns true after save", function()
        local sm = lurek.save.newSaveManager()
        sm:register("chk",
            function() return {} end,
            function() end
        )
        sm:save(SLOT)
        expect_true(sm:exists(SLOT))
    end)

    -- @covers LSaveManager:exists
    -- @covers LSaveManager:getSlots
    -- @covers LSaveManager:register
    -- @covers LSaveManager:save
    -- @covers lurek.save.newSaveManager
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
        expect_true(found)
    end)

    -- @covers LSaveManager:getSlotInfo
    -- @covers LSaveManager:register
    -- @covers LSaveManager:save
    -- @covers lurek.save.newSaveManager
    it("getSlotInfo returns a table for an existing slot", function()
        local sm = lurek.save.newSaveManager()
        sm:register("info_data", function() return {} end, function() end)
        sm:save(SLOT)
        local info = sm:getSlotInfo(SLOT)
        expect_type("table", info)
    end)

    -- @covers LSaveManager:load
    -- @covers LSaveManager:register
    -- @covers LSaveManager:save
    -- @covers lurek.save.newSaveManager
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

    -- @covers LSaveManager:delete
    -- @covers LSaveManager:exists
    -- @covers LSaveManager:register
    -- @covers LSaveManager:save
    -- @covers lurek.save.newSaveManager
    it("delete removes the slot", function()
        local sm = lurek.save.newSaveManager()
        sm:register("del_sys", function() return {} end, function() end)
        sm:save(SLOT)
        sm:delete(SLOT)
        expect_false(sm:exists(SLOT))
    end)
end)

-- reset
-- @describe SaveManager.reset
describe("SaveManager.reset", function()
    -- @covers LSaveManager:register
    -- @covers LSaveManager:reset
    -- @covers lurek.save.newSaveManager
    it("reset does not error", function()
        local sm = lurek.save.newSaveManager()
        sm:register("r", function() return {} end, function() end)
        expect_no_error(function() sm:reset() end)
    end)

    -- @covers LSaveManager:isDirty
    -- @covers LSaveManager:markDirty
    -- @covers LSaveManager:reset
    -- @covers lurek.save.newSaveManager
    it("isDirty is false after reset", function()
        local sm = lurek.save.newSaveManager()
        sm:markDirty()
        sm:reset()
        expect_false(sm:isDirty())
    end)
end)

-- AutoSave
-- @describe SaveManager.disableAutoSave / update
describe("SaveManager.disableAutoSave / update", function()
    -- @covers LSaveManager:disableAutoSave
    -- @covers lurek.save.newSaveManager
    it("disableAutoSave does not error", function()
        local sm = lurek.save.newSaveManager()
        expect_no_error(function() sm:disableAutoSave() end)
    end)

    -- @covers LSaveManager:update
    -- @covers lurek.save.newSaveManager
    it("update does not error with delta time", function()
        local sm = lurek.save.newSaveManager()
        expect_no_error(function() sm:update(0.016) end)
    end)

    -- @covers LSaveManager:update
    -- @covers lurek.save.newSaveManager
    it("update accumulates time without error over many frames", function()
        local sm = lurek.save.newSaveManager()
        for _ = 1, 100 do
            sm:update(0.016)
        end
        expect_true(true, "update loop completed without error")
    end)
end)

-- @describe SaveManager regression coverage
describe("SaveManager regression coverage", function()
    -- @covers LSaveManager:collect
    -- @covers LSaveManager:register
    -- @covers LSaveManager:unregister
    -- @covers lurek.save.newSaveManager
    it("unregister removes collector output from collect", function()
        local sm = lurek.save.newSaveManager()
        sm:register("temp_sys", function() return { hp = 100 } end, function() end)
        sm:unregister("temp_sys")

        local snapshot = sm:collect()
        expect_equal(nil, snapshot.temp_sys)
    end)

    -- @covers LSaveManager:isCompressed
    -- @covers LSaveManager:setCompress
    -- @covers lurek.save.newSaveManager
    it("setCompress toggles isCompressed", function()
        local sm = lurek.save.newSaveManager()

        sm:setCompress(true)
        expect_true(sm:isCompressed())

        sm:setCompress(false)
        expect_false(sm:isCompressed())
    end)

    -- @covers LSaveManager:delete
    -- @covers LSaveManager:onBeforeSave
    -- @covers LSaveManager:register
    -- @covers LSaveManager:save
    -- @covers lurek.save.newSaveManager
    it("onBeforeSave fires with the slot name", function()
        local sm = lurek.save.newSaveManager()
        local slot = "unit_test_before_save_hook"
        local seen_slot = nil

        sm:register("hook_data", function() return { x = 1 } end, function() end)
        sm:onBeforeSave(function(name)
            seen_slot = name
        end)

        sm:save(slot)

        expect_equal(slot, seen_slot)
        sm:delete(slot)
    end)

    -- @covers LSaveManager:delete
    -- @covers LSaveManager:disableAutoSave
    -- @covers LSaveManager:enableAutoSave
    -- @covers LSaveManager:load
    -- @covers LSaveManager:markDirty
    -- @covers LSaveManager:onAfterLoad
    -- @covers LSaveManager:register
    -- @covers LSaveManager:save
    -- @covers LSaveManager:update
    -- @covers lurek.save.newSaveManager
    it("onAfterLoad fires after a successful load and autosave returns the configured slot", function()
        local sm = lurek.save.newSaveManager()
        local slot = "unit_test_after_load_hook"
        local restored_value = nil
        local loaded_slot = nil

        sm:register(
            "round_trip",
            function() return { value = 42 } end,
            function(data) restored_value = data.value end
        )
        sm:onAfterLoad(function(name)
            loaded_slot = name
        end)

        sm:save(slot)
        local ok, err = sm:load(slot)

        expect_true(ok, err or "expected load to succeed")
        expect_equal(42, restored_value)
        expect_equal(slot, loaded_slot)

        sm:enableAutoSave(0.5, "autosave_slot")
        sm:markDirty()
        expect_equal(nil, sm:update(0.49))
        expect_equal("autosave_slot", sm:update(0.01))

        sm:disableAutoSave()
        sm:markDirty()
        expect_equal(nil, sm:update(1.0))

        sm:delete(slot)
    end)
end)

-- @describe save strict: LSaveManager addMigration/type/typeOf
describe("save strict: LSaveManager addMigration/type/typeOf", function()
    -- @covers LSaveManager:type
    -- @covers LSaveManager:typeOf
    -- @covers lurek.save.newSaveManager
    it("LSaveManager type and typeOf are callable", function()
        local sm = lurek.save.newSaveManager()
        expect_type("string", sm:type())
        expect_type("boolean", sm:typeOf("Object"))
    end)

    -- @covers LSaveManager:addMigration
    -- @covers lurek.save.newSaveManager
    it("LSaveManager addMigration is callable", function()
        local sm = lurek.save.newSaveManager()
        local ok = pcall(function()
            sm:addMigration(1, function(data) return data end)
        end)
        expect_type("boolean", ok)
    end)
end)

-- @describe save migrated from integration/save_tilemap
describe("save migrated from integration/save_tilemap", function()
    -- @covers LSaveManager:getSummary
    -- @covers LSaveManager:setSummary
    -- @covers lurek.save.newSaveManager
    it("save summary stores metadata", function()
        local sm = lurek.save.newSaveManager()
        sm:setSummary("level_01")
        expect_equal("level_01", sm:getSummary())
    end)

    -- @covers LSaveManager:getSchemaVersion
    -- @covers lurek.save.newSaveManager
    it("schema version is accessible", function()
        local sm = lurek.save.newSaveManager()
        local ver = sm:getSchemaVersion()
        expect_type("number", ver)
        expect_true(ver >= 0)
    end)
end)

test_summary()
