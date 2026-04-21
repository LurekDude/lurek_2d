-- Lurek2D Integration Test: Save + Entity
-- Tests saving and restoring entity state

-- @description Covers suite: integration: save entity world state.
describe("integration: save entity world state", function()
    -- @covers lurek.ecs.Universe.get
    -- @covers lurek.save
    -- @covers lurek.data.parseToml
    -- @covers lurek.ecs.newUniverse
    -- @covers lurek.save.newSaveManager
    -- @description Verifies entity state can be collected into a save-friendly data structure without losing key fields.
    it("collects entity data for save", function()
        local universe = lurek.ecs.newUniverse()

        -- Create game entities
        local player = universe:spawn()
        universe:set(player, "name", "Hero")
        universe:set(player, "health", 85)
        universe:set(player, "position", {x = 100, y = 200})

        local enemy1 = universe:spawn()
        universe:set(enemy1, "name", "Goblin")
        universe:set(enemy1, "health", 30)

        local enemy2 = universe:spawn()
        universe:set(enemy2, "name", "Dragon")
        universe:set(enemy2, "health", 500)

        -- Collect state as save data
        local save_data = {}
        local ids = {player, enemy1, enemy2}
        for _, id in ipairs(ids) do
            if universe:isAlive(id) then
                save_data[#save_data + 1] = {
                    name = universe:get(id, "name"),
                    health = universe:get(id, "health"),
                }
            end
        end

        expect_equal(3, #save_data, "3 entities collected")
        expect_equal("Hero", save_data[1].name, "player name preserved")
        expect_equal(85, save_data[1].health, "player health preserved")
        expect_equal("Dragon", save_data[3].name, "dragon name preserved")
    end)

    -- @covers lurek.save.SaveManager.markDirty
    -- @covers lurek.ecs.Universe.set
    -- @description Verifies entity mutation can mark the save manager dirty so the world is known to need saving.
    it("save manager tracks entity dirty state", function()
        local mgr = lurek.save.newSaveManager()
        local universe = lurek.ecs.newUniverse()

        mgr:register("entities", function() return {} end, function(_data) end)
        expect_false(mgr:isDirty(), "initially clean")

        -- Modify entities
        local id = universe:spawn()
        universe:set(id, "modified", true)
        mgr:markDirty()

        expect_true(mgr:isDirty(), "dirty after entity modification")
    end)
end)

-- @description Covers suite: integration: TOML config for entities.
describe("integration: TOML config for entities", function()
    -- @covers lurek.data.parseToml
    -- @covers lurek.ecs.Universe.spawn
    -- @description Verifies entity blueprints defined in TOML can be parsed and instantiated into live entities.
    it("entity blueprints from TOML", function()
        local toml_str = [[
            [player]
            health = 100
            speed = 5.0
            name = "Hero"

            [goblin]
            health = 30
            speed = 3.0
            name = "Goblin"

            [dragon]
            health = 500
            speed = 2.0
            name = "Dragon"
        ]]

        local config = lurek.data.parseToml(toml_str)

        local universe = lurek.ecs.newUniverse()

        -- Create entities from TOML config
        local entities = {}
        for entity_type, props in pairs(config) do
            local id = universe:spawn()
            if type(props) == "table" then
                for key, value in pairs(props) do
                    universe:set(id, key, value)
                end
                universe:set(id, "type", entity_type)
                entities[entity_type] = id
            end
        end

        -- Verify entities created from config
        expect_true(universe:getEntityCount() >= 3, "at least 3 entities from TOML")

        -- Check one entity
        if entities["player"] then
            local name = universe:get(entities["player"], "name")
            expect_equal("Hero", name, "player name from TOML")
        end
    end)
end)
test_summary()
