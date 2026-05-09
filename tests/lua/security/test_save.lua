-- test_save.lua
-- Canonical file. Merged from multiple sources.

-- Lurek2D Validation Test: SaveManager Edge Cases
-- Tests save/load with corrupted data, missing fields, and edge cases

-- @describe validation: savegame edge cases
describe("validation: savegame edge cases", function()
    -- @security lurek.save.newSaveManager
    it("creates save manager without crash", function()
        expect_no_error(function()
            local mgr = lurek.save.newSaveManager()
            expect_not_nil(mgr, "save manager created")
        end)
    end)

    -- @security LSaveManager:register
    -- @security LSaveManager:unregister
    -- @security lurek.save.newSaveManager
    it("register and unregister collectors", function()
        local mgr = lurek.save.newSaveManager()
        mgr:register("player", function() return {hp = 100} end, function(data) end)
        mgr:register("inventory", function() return {} end, function(data) end)

        -- Unregister should not crash
        expect_no_error(function()
            mgr:unregister("player")
        end)
    end)

    -- @security LSaveManager:unregister
    -- @security lurek.save.newSaveManager
    it("unregister nonexistent collector does not crash", function()
        local mgr = lurek.save.newSaveManager()
        expect_no_error(function()
            mgr:unregister("nonexistent")
        end, "unregister nonexistent should not crash")
    end)

    -- @security LSaveManager:getSchemaVersion
    -- @security LSaveManager:setSchemaVersion
    -- @security lurek.save.newSaveManager
    it("schema versioning works", function()
        local mgr = lurek.save.newSaveManager()
        mgr:setSchemaVersion(5)
        expect_equal(5, mgr:getSchemaVersion(), "version set correctly")
    end)

    -- @security LSaveManager:isDirty
    -- @security LSaveManager:markDirty
    -- @security lurek.save.newSaveManager
    it("dirty tracking works", function()
        local mgr = lurek.save.newSaveManager()
        expect_false(mgr:isDirty(), "initially not dirty")
        mgr:markDirty()
        expect_true(mgr:isDirty(), "dirty after mark")
    end)

    -- @security LSaveManager:disableAutoSave
    -- @security LSaveManager:enableAutoSave
    -- @security LSaveManager:update
    -- @security lurek.save.newSaveManager
    it("auto-save configuration", function()
        local mgr = lurek.save.newSaveManager()
        mgr:enableAutoSave(30.0, "auto")

        -- update returns whether autosave triggered
        local triggered = mgr:update(1.0)
        -- Not enough time elapsed, so should not trigger
        expect_false(triggered, "not ready after 1 second")

        mgr:disableAutoSave()
    end)

    -- @security LSaveManager:getSummary
    -- @security LSaveManager:setSummary
    -- @security lurek.save.newSaveManager
    it("summary get/set", function()
        local mgr = lurek.save.newSaveManager()
        mgr:setSummary("Test save game")
        expect_equal("Test save game", mgr:getSummary(), "summary preserved")
    end)

    -- @security LSaveManager:isDirty
    -- @security LSaveManager:markDirty
    -- @security LSaveManager:register
    -- @security LSaveManager:reset
    -- @security LSaveManager:setSummary
    -- @security lurek.save.newSaveManager
    it("reset clears state", function()
        local mgr = lurek.save.newSaveManager()
        mgr:register("test", function() return {} end, function(data) end)
        mgr:markDirty()
        mgr:setSummary("to be cleared")
        mgr:reset()
        expect_false(mgr:isDirty(), "not dirty after reset")
    end)
end)

-- @describe validation: savegame migration
describe("validation: savegame migration", function()
    -- @security LSaveManager:addMigration
    -- @security lurek.save.newSaveManager
    it("adds migration functions", function()
        local mgr = lurek.save.newSaveManager()
        mgr:addMigration(1, function(data) return data end)
        mgr:addMigration(2, function(data) return data end)
        -- Should not crash
        expect_true(true, "migrations added")
    end)

    -- @security LSaveManager:addMigration
    -- @security lurek.save.newSaveManager
    it("rejects migration with non-function callback", function()
        local mgr = lurek.save.newSaveManager()
        ---@type any
        local bad_migration = "not_a_function"
        expect_error(function()
            mgr:addMigration(3, bad_migration)
        end)
    end)

    -- @security LSaveManager:register
    -- @security lurek.save.newSaveManager
    it("rejects register with non-function collector", function()
        local mgr = lurek.save.newSaveManager()
        ---@type any
        local bad_collector = "bad_collector"
        expect_error(function()
            mgr:register("player", bad_collector, function(_) end)
        end)
    end)
end)
test_summary()


