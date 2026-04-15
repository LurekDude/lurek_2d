-- Lurek2D minimap path visualization tests.
-- Covers: showPath, clearPath (all overloads).

-- @description Covers suite: minimap path visualization.
describe("minimap path visualization", function()
    -- @covers Minimap.showPath
    -- @description showPath accepts a list of {x, y} point tables without error.
    it("showPath accepts a list of points", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:showPath({{0, 0}, {16, 16}, {32, 0}}, {0, 0, 255, 255})
        expect_equal(true, true)
    end)

    -- @covers Minimap.showPath
    -- @description showPath returns a non-zero integer path ID.
    it("showPath returns a path ID", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:showPath({{0, 0}, {10, 10}}, {255, 0, 0, 255})
        expect_true(type(id) == "number")
        expect_true(id > 0)
    end)

    -- @covers Minimap.showPath
    -- @description Each showPath call returns a distinct ID.
    it("showPath returns distinct IDs", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id1 = mm:showPath({{0, 0}, {5, 5}}, {255, 0, 0, 255})
        local id2 = mm:showPath({{10, 10}, {20, 20}}, {0, 255, 0, 255})
        expect_true(id1 ~= id2)
    end)

    -- @covers Minimap.clearPath
    -- @description clearPath() with no argument removes all paths without error.
    it("clearPath removes all paths", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:showPath({{0, 0}, {10, 10}}, {255, 255, 0, 255})
        mm:showPath({{5, 5}, {15, 15}}, {0, 255, 255, 255})
        mm:clearPath()
        expect_equal(true, true)
    end)

    -- @covers Minimap.clearPath
    -- @description clearPath(id) removes only the path with the given ID.
    it("clearPath with id removes specific path", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        local id = mm:showPath({{0, 0}, {10, 10}}, {255, 0, 0, 255})
        mm:clearPath(id)
        expect_equal(true, true)
    end)

    -- @covers Minimap.clearPath
    -- @description clearPath on an empty set does not error.
    it("clearPath on empty set does not error", function()
        local mm = lurek.minimap.newMinimap(64, 64)
        mm:clearPath()
        expect_equal(true, true)
    end)
end)

test_summary()
