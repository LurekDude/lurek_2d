-- Lurek2D Golden Test: Tilemap Queries
-- Tests tilemap operations return deterministic results on fixed maps.
-- @golden lurek.tilemap.newTilemap
-- @golden lurek.tilemap.setTile
-- @golden lurek.tilemap.getTile

describe("golden: tilemap tile read-back matches write", function()
    it("tiles written then read back exactly", function()
        local tm = lurek.tilemap.newTilemap(10, 10, 16, 16)

        local expected = {
            {x=0, y=0, id=1},
            {x=3, y=2, id=5},
            {x=9, y=9, id=3},
            {x=5, y=0, id=7},
        }

        for _, e in ipairs(expected) do
            tm:setTile(e.x, e.y, e.id)
        end

        for _, e in ipairs(expected) do
            local got = tm:getTile(e.x, e.y)
            expect_equal(e.id, got, string.format("tile (%d,%d) = %d", e.x, e.y, e.id))
        end
    end)

    it("unset tiles return 0 or nil", function()
        local tm = lurek.tilemap.newTilemap(5, 5, 32, 32)
        -- No tiles set
        local t = tm:getTile(2, 2)
        expect_true(t == 0 or t == nil or t == false,
            "unset tile returns 0, nil, or false")
    end)
end)

describe("golden: tilemap checkerboard pattern", function()
    it("alternating tiles read back correctly", function()
        local tm = lurek.tilemap.newTilemap(4, 4, 16, 16)

        for y = 0, 3 do
            for x = 0, 3 do
                local id = ((x + y) % 2 == 0) and 1 or 2
                tm:setTile(x, y, id)
            end
        end

        -- Spot-check corners and center
        expect_equal(1, tm:getTile(0, 0), "top-left = 1 (0+0 even)")
        expect_equal(2, tm:getTile(1, 0), "top(1,0) = 2 (1+0 odd)")
        expect_equal(2, tm:getTile(0, 1), "left(0,1) = 2 (0+1 odd)")
        expect_equal(1, tm:getTile(1, 1), "center(1,1) = 1 (1+1 even)")
        expect_equal(1, tm:getTile(3, 3), "bottom-right = 1 (3+3 even)")
    end)
end)

describe("golden: tilemap overwrite", function()
    it("overwritten tile reflects new value", function()
        local tm = lurek.tilemap.newTilemap(5, 5, 16, 16)
        tm:setTile(2, 2, 1)
        expect_equal(1, tm:getTile(2, 2), "initial tile = 1")

        tm:setTile(2, 2, 99)
        expect_equal(99, tm:getTile(2, 2), "overwritten tile = 99")
    end)
end)

describe("golden: large tilemap fill and row sum", function()
    it("20x20 tilemap filled with ascending id: row 0 columns sum correctly", function()
        local tm    = lurek.tilemap.newTilemap(20, 20, 8, 8)
        local total = 0

        for y = 0, 19 do
            for x = 0, 19 do
                tm:setTile(x, y, x + 1)  -- column x → id x+1
            end
        end

        -- Row 0 sum: 1+2+...+20 = 210
        for x = 0, 19 do
            total = total + tm:getTile(x, 0)
        end
        expect_equal(210, total, "row 0 sum = 1+2+...+20 = 210")
    end)
end)

test_summary()
