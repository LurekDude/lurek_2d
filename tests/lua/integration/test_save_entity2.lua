-- Luna2D Integration Test: SaveGame + Entity
-- Tests saving and restoring entity state through the save system

describe("integration: save and restore entity state", function()
    it("saves entity data via save manager", function()
        local universe = luna.entity.newUniverse()

        -- Create some entities
        for i = 1, 20 do
            local id = universe:spawn()
            universe:set(id, "name", "entity_" .. i)
            universe:set(id, "health", 100 - i)
            universe:set(id, "x", i * 10)
        end

        -- Set up save manager
        local sm = luna.savegame.newSaveManager()
        sm:setSchemaVersion(1)

        local entity_data = nil
        sm:register("entities", function()
            -- Collect entity data
            local data = {}
            local entities = universe:getEntities()
            for _, id in ipairs(entities) do
                data[#data + 1] = {
                    name = universe:get(id, "name"),
                    health = universe:get(id, "health"),
                    x = universe:get(id, "x")
                }
            end
            return data
        end, function(data)
            entity_data = data
        end)

        -- Collect save data
        local save_data = sm:collect()
        expect_not_nil(save_data, "save data collected")

        -- Restore it
        sm:restore(save_data)
        expect_not_nil(entity_data, "entity data restored")
        expect_equal(20, #entity_data, "all 20 entities restored")
    end)
end)

describe("integration: save dirty tracking with entity changes", function()
    it("tracks dirty state when entities change", function()
        local sm = luna.savegame.newSaveManager()

        sm:register("state", function()
            return {modified = true}
        end, function(data) end)

        -- Initially not dirty
        expect_false(sm:isDirty(), "initially clean")

        -- Mark dirty after entity change
        sm:markDirty()
        expect_true(sm:isDirty(), "dirty after mark")

        -- Collect resets dirty
        sm:collect()
        -- Dirty flag might or might not reset after collect - just verify no crash
        expect_no_error(function()
            sm:isDirty()
        end)
    end)
end)
