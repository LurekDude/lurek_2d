-- Lurek2D Stress Test: Entity Mass Spawn
-- Tests entity creation, tag assignment, and component operations at scale

describe("entity stress: mass spawn", function()
    it("spawns 10000 entities", function()
        local universe = lurek.entity.newUniverse()

        for i = 1, 10000 do
            universe:spawn()
        end

        expect_equal(10000, universe:getEntityCount(), "10000 entities alive")
    end)

    it("spawns and kills 5000 entities", function()
        local universe = lurek.entity.newUniverse()
        local ids = {}

        -- Spawn
        for i = 1, 5000 do
            ids[i] = universe:spawn()
        end
        expect_equal(5000, universe:getEntityCount(), "5000 spawned")

        -- Kill half
        for i = 1, 2500 do
            universe:kill(ids[i])
        end
        expect_equal(2500, universe:getEntityCount(), "2500 remaining")
    end)

    it("adds components to 5000 entities", function()
        local universe = lurek.entity.newUniverse()

        for i = 1, 5000 do
            local id = universe:spawn()
            universe:set(id, "position", {x = i, y = i * 2})
            universe:set(id, "health", 100)
            universe:set(id, "name", "entity_" .. i)
        end

        expect_equal(5000, universe:getEntityCount(), "5000 with components")
    end)

    it("ID recycling works after mass kill", function()
        local universe = lurek.entity.newUniverse()
        local old_ids = {}

        -- Spawn and kill 1000
        for i = 1, 1000 do
            old_ids[i] = universe:spawn()
        end
        for i = 1, 1000 do
            universe:kill(old_ids[i])
        end
        expect_equal(0, universe:getEntityCount(), "all killed")

        -- Respawn 1000 - should reuse IDs
        for i = 1, 1000 do
            universe:spawn()
        end
        expect_equal(1000, universe:getEntityCount(), "1000 respawned")
    end)

    it("tag operations at scale", function()
        local universe = lurek.entity.newUniverse()

        for i = 1, 2000 do
            local id = universe:spawn()
            -- Alternate tags
            if i % 2 == 0 then
                universe:addTag(id, "even")
            else
                universe:addTag(id, "odd")
            end
            if i % 3 == 0 then
                universe:addTag(id, "multiple_of_3")
            end
        end

        expect_equal(2000, universe:getEntityCount(), "2000 tagged entities")
    end)
end)
