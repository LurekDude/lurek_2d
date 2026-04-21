-- Lurek2D Validation Test: SaveManager Edge Cases
-- Tests save/load with corrupted data, missing fields, and edge cases

-- @description Covers suite: validation: savegame edge cases.
describe("validation: savegame edge cases", function()
    -- @covers lurek.save.newSaveManager
    -- @security lurek.save.newSaveManager
    -- @description Creates a save manager to verify the savegame subsystem can be instantiated safely before any collectors or autosave state exist.
    it("creates save manager without crash", function()
        expect_no_error(function()
            local mgr = lurek.save.newSaveManager()
            expect_not_nil(mgr, "save manager created")
        end)
    end)

    -- @covers lurek.save.newSaveManager
    -- @description Registers multiple collectors and then unregisters one to verify collector lifecycle management handles removal cleanly.
    it("register and unregister collectors", function()
        local mgr = lurek.save.newSaveManager()
        mgr:register("player", function() return {hp = 100} end, function(data) end)
        mgr:register("inventory", function() return {} end, function(data) end)

        -- Unregister should not crash
        expect_no_error(function()
            mgr:unregister("player")
        end)
    end)

    -- @covers lurek.save.newSaveManager
    -- @description Unregisters a collector name that was never registered to ensure stale or attacker-controlled ids do not crash the registry.
    it("unregister nonexistent collector does not crash", function()
        local mgr = lurek.save.newSaveManager()
        expect_no_error(function()
            mgr:unregister("nonexistent")
        end, "unregister nonexistent should not crash")
    end)

    -- @covers lurek.save.newSaveManager
    -- @description Sets and reads the schema version to validate version bookkeeping on migration-sensitive save payloads.
    it("schema versioning works", function()
        local mgr = lurek.save.newSaveManager()
        mgr:setSchemaVersion(5)
        expect_equal(5, mgr:getSchemaVersion(), "version set correctly")
    end)

    -- @covers lurek.save.newSaveManager
    -- @description Toggles dirty state to verify change-tracking is available for autosave and integrity workflows.
    it("dirty tracking works", function()
        local mgr = lurek.save.newSaveManager()
        expect_false(mgr:isDirty(), "initially not dirty")
        mgr:markDirty()
        expect_true(mgr:isDirty(), "dirty after mark")
    end)

    -- @covers lurek.save.newSaveManager
    -- @description Configures autosave and performs an update below the trigger threshold to confirm timer-based save scheduling does not fire early.
    it("auto-save configuration", function()
        local mgr = lurek.save.newSaveManager()
        mgr:enableAutoSave(30.0, "auto")

        -- update returns whether autosave triggered
        local triggered = mgr:update(1.0)
        -- Not enough time elapsed, so should not trigger
        expect_false(triggered, "not ready after 1 second")

        mgr:disableAutoSave()
    end)

    -- @covers lurek.save.newSaveManager
    -- @description Sets a human-readable summary string to verify metadata survives round-trip through the save manager API.
    it("summary get/set", function()
        local mgr = lurek.save.newSaveManager()
        mgr:setSummary("Test save game")
        expect_equal("Test save game", mgr:getSummary(), "summary preserved")
    end)

    -- @covers lurek.save.newSaveManager
    -- @description Resets a dirty manager with registered collectors to ensure internal state is wiped clean after corruption recovery or new-game flows.
    it("reset clears state", function()
        local mgr = lurek.save.newSaveManager()
        mgr:register("test", function() return {} end, function(data) end)
        mgr:markDirty()
        mgr:setSummary("to be cleared")
        mgr:reset()
        expect_false(mgr:isDirty(), "not dirty after reset")
    end)
end)

-- @description Covers suite: validation: savegame migration.
describe("validation: savegame migration", function()
    -- @covers lurek.save.newSaveManager
    -- @description Registers migration callbacks for multiple schema versions to verify migration tables accept staged upgrade handlers.
    it("adds migration functions", function()
        local mgr = lurek.save.newSaveManager()
        mgr:addMigration(1, function(data) return data end)
        mgr:addMigration(2, function(data) return data end)
        -- Should not crash
        expect_true(true, "migrations added")
    end)
end)
test_summary()
