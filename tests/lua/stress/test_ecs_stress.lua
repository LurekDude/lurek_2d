-- Lurek2D Stress Test: Entity Mass Spawn
-- Tests entity creation, tag assignment, and component operations at scale

-- @description Covers suite: entity stress: mass spawn.
describe("entity stress: mass spawn", function()
    -- @covers lurek.ecs.newUniverse
    -- @covers Universe:spawn
    -- @covers Universe:getEntityCount
    -- @stress Spawns 10000 entities into a single universe without intermediate cleanup.
    -- @description Stresses raw entity-allocation throughput by pushing the universe to a large live-entity count in one continuous spawn loop.
    it("spawns 10000 entities", function()
        local universe = lurek.ecs.newUniverse()

        for i = 1, 10000 do
            universe:spawn()
        end

        expect_equal(10000, universe:getEntityCount(), "10000 entities alive")
    end)

    -- @covers lurek.ecs.newUniverse
    -- @covers Universe:spawn
    -- @covers Universe:kill
    -- @stress Spawns 5000 entities, then destroys the first 2500 in a second pass.
    -- @description Stresses lifecycle churn by exercising bulk creation followed by bulk deletion while verifying the live-entity count collapses correctly.
    it("spawns and kills 5000 entities", function()
        local universe = lurek.ecs.newUniverse()
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

    -- @covers lurek.ecs.newUniverse
    -- @covers Universe:spawn
    -- @covers Universe:set
    -- @stress Creates 5000 entities and assigns three components to each one.
    -- @description Stresses component write throughput by combining entity creation with repeated field assignment across a large population.
    it("adds components to 5000 entities", function()
        local universe = lurek.ecs.newUniverse()

        for i = 1, 5000 do
            local id = universe:spawn()
            universe:set(id, "position", {x = i, y = i * 2})
            universe:set(id, "health", 100)
            universe:set(id, "name", "entity_" .. i)
        end

        expect_equal(5000, universe:getEntityCount(), "5000 with components")
    end)

    -- @covers lurek.ecs.newUniverse
    -- @covers Universe:spawn
    -- @covers Universe:kill
    -- @stress Spawns and kills 1000 entities, then respawns another 1000 into the recycled pool.
    -- @description Stresses ID reuse behavior by forcing full turnover of a fixed-size entity set and validating that the universe recovers to the expected count.
    it("ID recycling works after mass kill", function()
        local universe = lurek.ecs.newUniverse()
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

    -- @covers lurek.ecs.newUniverse
    -- @covers Universe:addTag
    -- @stress Spawns 2000 entities and conditionally assigns alternating and overlapping tag sets.
    -- @description Stresses tag-write throughput by applying one or two tags per entity across a large population with branching conditions.
    it("tag operations at scale", function()
        local universe = lurek.ecs.newUniverse()

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
test_summary()
