-- Lurek2D Integration Test: Scene + Entity
-- Tests composing entities into scene graph hierarchies.

describe("integration: scene + entity hierarchy", function()
    it("creates scene and populates with entities", function()
        local universe = lurek.ecs.newUniverse()

        -- Spawn parent and children
        local parent = universe:spawn()
        universe:set(parent, "name", "parent")
        universe:set(parent, "x", 0.0)
        universe:set(parent, "y", 0.0)

        local children = {}
        for i = 1, 5 do
            local child = universe:spawn()
            universe:set(child, "name", "child_" .. i)
            universe:set(child, "parent_id", parent)
            universe:set(child, "x", i * 10.0)
            universe:set(child, "y", i * 10.0)
            children[i] = child
        end

        -- Verify parent-child relationships
        for i, child in ipairs(children) do
            local pid = universe:get(child, "parent_id")
            expect_equal(parent, pid, "child " .. i .. " references parent")
        end
    end)

    it("killing parent entity is tracked", function()
        local universe = lurek.ecs.newUniverse()

        local parent = universe:spawn()
        local child  = universe:spawn()
        universe:set(child, "parent_id", parent)

        universe:kill(parent)
        -- After kill, child still exists (orphan is the game engine's responsibility)
        local pid = universe:get(child, "parent_id")
        expect_equal(parent, pid, "orphan child still stores old parent id")
    end)

    it("large entity population in scene does not error", function()
        local universe = lurek.ecs.newUniverse()
        local ids = {}

        for i = 1, 200 do
            local id = universe:spawn()
            universe:set(id, "index", i)
            ids[i] = id
        end

        -- Verify a sample
        expect_equal(1,   universe:get(ids[1],   "index"), "first entity")
        expect_equal(200, universe:get(ids[200], "index"), "last entity")

        -- Kill all
        for _, id in ipairs(ids) do
            universe:kill(id)
        end
        expect_true(true, "bulk create + kill did not crash")
    end)
end)
test_summary()
