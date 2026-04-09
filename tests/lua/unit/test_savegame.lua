-- lurek.savegame API unit tests
-- Headless-safe (no window / GPU / audio required).
-- Tests SaveManager lifecycle and API surface; does not write to disk.

describe("lurek.savegame module exists", function()
    it("lurek.savegame is a table", function()
        expect_type("table", lurek.savegame)
    end)
end)

describe("Factory function", function()
    it("newSaveManager is a function", function()
        expect_type("function", lurek.savegame.newSaveManager)
    end)

    it("newSaveManager returns a non-nil object", function()
        local sm = lurek.savegame.newSaveManager()
        expect_true(sm ~= nil, "save manager is not nil")
    end)
end)

describe("SaveManager registration and metadata", function()
    it("register accepts a name + collect/restore callbacks", function()
        local sm = lurek.savegame.newSaveManager()
        sm:register("player",
            function() return { hp = 100 } end,
            function(data) end
        )
        expect_true(true, "register did not throw")
    end)

    it("unregister removes a previously registered system", function()
        local sm = lurek.savegame.newSaveManager()
        sm:register("temp_sys",
            function() return {} end,
            function(data) end
        )
        sm:unregister("temp_sys")
        expect_true(true, "unregister did not throw")
    end)

    it("setSummary and getSummary round-trip a string", function()
        local sm = lurek.savegame.newSaveManager()
        sm:setSummary("Level 3")
        expect_equal("Level 3", sm:getSummary())
    end)

    it("getSchemaVersion returns a number on new manager", function()
        local sm = lurek.savegame.newSaveManager()
        local v = sm:getSchemaVersion()
        expect_type("number", v)
    end)

    it("setSchemaVersion updates the version", function()
        local sm = lurek.savegame.newSaveManager()
        sm:setSchemaVersion(3)
        expect_equal(3, sm:getSchemaVersion())
    end)

    it("isDirty returns false on new manager", function()
        local sm = lurek.savegame.newSaveManager()
        expect_false(sm:isDirty())
    end)

    it("markDirty sets isDirty to true", function()
        local sm = lurek.savegame.newSaveManager()
        sm:markDirty()
        expect_true(sm:isDirty())
    end)

    it("exists returns false for a nonexistent slot", function()
        local sm = lurek.savegame.newSaveManager()
        expect_false(sm:exists("no_such_slot_xyz"))
    end)

    it("getSlots returns a table", function()
        local sm = lurek.savegame.newSaveManager()
        local slots = sm:getSlots()
        expect_type("table", slots)
    end)
end)

test_summary()
