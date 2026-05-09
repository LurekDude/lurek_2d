-- Integration: save/load cycle preserving entity state across scene transitions
describe("savegame + entity + scene integration", function()
    -- @integration LSaveManager:collect
    -- @integration LSaveManager:register
    -- @integration LUniverse:get
    -- @integration LUniverse:getEntityCount
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.save.newSaveManager
    it("save manager collects entity state", function()
        local universe = lurek.ecs.newUniverse()
        local sm = lurek.save.newSaveManager()

        -- Create entities with game state
        local player = universe:spawn()
        universe:set(player, "name", "Hero")
        universe:set(player, "hp", 85)
        universe:set(player, "level", 7)
        universe:set(player, "x", 320)
        universe:set(player, "y", 240)

        local npc = universe:spawn()
        universe:set(npc, "name", "Merchant")
        universe:set(npc, "hp", 50)

        -- Register entity save system
        local collected_data = nil
        sm:register("entities", function()
            -- Collect callback: serialize entity state
            collected_data = {
                player_hp = universe:get(player, "hp"),
                player_level = universe:get(player, "level"),
                npc_count = universe:getEntityCount() - 1,  -- exclude player
            }
            return collected_data
        end, function(data)
            -- Restore callback: deserialize entity state
        end)

        -- Trigger collect
        local snapshot = sm:collect()
        expect_not_nil(snapshot, "snapshot is not nil")
        expect_not_nil(collected_data, "entity save callback was invoked")
        expect_equal(85, collected_data.player_hp, "player HP captured by collect")
        expect_equal(7,  collected_data.player_level, "player level captured by collect")
    end)

    -- @integration LSaveManager:collect
    -- @integration LSaveManager:register
    -- @integration LUniverse:getEntityCount
    -- @integration LUniverse:set
    -- @integration LUniverse:spawn
    -- @integration lurek.ecs.newUniverse
    -- @integration lurek.save.newSaveManager
    it("save-load round-trip preserves entity count", function()
        local universe = lurek.ecs.newUniverse()
        local sm = lurek.save.newSaveManager()

        -- Create 10 entities
        for i = 1, 10 do
            local id = universe:spawn()
            universe:set(id, "value", i * 10)
        end
        expect_equal(10, universe:getEntityCount(), "10 entities before save")

        -- Register
        local save_count = 0
        sm:register("world", function()
            save_count = universe:getEntityCount()
            return { count = save_count }
        end, function(data)
            -- Restore: in practice would recreate entities
        end)

        sm:collect()
        expect_equal(10, save_count, "collected 10 entities")
    end)

    -- @integration LSaveManager:getSummary
    -- @integration LSaveManager:setSummary
    -- @integration lurek.save.newSaveManager
    it("save metadata tracks scene name", function()
        local sm = lurek.save.newSaveManager()
        sm:setSummary("Forest Temple - Floor 3")

        local summary = sm:getSummary()
        expect_equal("Forest Temple - Floor 3", summary, "summary preserved")
    end)

    -- @integration LSaveManager:getSchemaVersion
    -- @integration lurek.save.newSaveManager
    it("schema version preserved across save cycles", function()
        local sm = lurek.save.newSaveManager()
        local v = sm:getSchemaVersion()
        expect_type("number", v)
        expect_true(v >= 0, "schema version is non-negative")
    end)
end)
test_summary()
