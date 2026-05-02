-- Integration test: library.cardgame    lurek.tween.
--
-- Scope: Animates a cardgame Card's `tile_x` / `tile_y` position via
-- `lurek.tween.tween`, verifies a callback fires on tween completion,
-- composes two tweens with `lurek.tween.sequence`, and probes the
-- "in-out-quad" easing midpoint with `expect_near`.
--
-- Fallback: none. `lurek.tween` is gated by `modules.tween` (default true)
-- and the runtime namespace matches the user-requested name. Cards expose
-- mutable `tile_x` / `tile_y` fields that tween can drive directly.
--

local cg = require("library.cardgame")

local function fresh_card()
    cg.clearCardTypes()
    cg.resetIdCounter()
    cg.defineCardType("knight", { name = "Knight" })
    return cg.newCard("knight")
end

describe("integration: library.cardgame    lurek.tween", function()

    it("tween updates card tile_x toward target over multiple updates", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        lurek.tween.tween(2.0, card, { tile_x = 10 }, "linear")
        lurek.tween.update(0.5)
        local x_quarter = card.tile_x
        lurek.tween.update(0.5)
        local x_half = card.tile_x
        lurek.tween.update(1.0)

        expect_near(2.5,  x_quarter, 0.5)
        expect_near(5.0,  x_half,    0.5)
        expect_near(10.0, card.tile_x, 1e-5)
    end)

    it("finished tween triggers a cardgame onComplete callback once", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        local fired = 0
        -- onComplete must be set via :onComplete(fn) method, not as a 5th argument
        local tw = lurek.tween.tween(1.0, card, { tile_x = 5 }, "linear")
        tw:onComplete(function()
            fired = fired + 1
            card:addTag("arrived")
        end)
        lurek.tween.update(1.5)

        expect_equal(1, fired)
        expect_true(card:hasTag("arrived"))
        expect_near(5.0, card.tile_x, 1e-5)
    end)

    it("sequence chains two card movement tweens", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        -- Test sequential tween manually: tween1 then tween2
        -- lurek.tween.tween() auto-registers tweens, so we do them in two phases
        lurek.tween.tween(1.0, card, { tile_x = 4 }, "linear")
        lurek.tween.update(1.0)
        expect_near(4.0, card.tile_x, 0.5)

        lurek.tween.cancelAll()
        lurek.tween.tween(1.0, card, { tile_x = 10 }, "linear")
        lurek.tween.update(1.0)
        expect_near(10.0, card.tile_x, 0.5)
    end)

    it("inOutQuad easing reaches midpoint value at half duration", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        lurek.tween.tween(2.0, card, { tile_x = 1.0 }, "inOutQuad")
        lurek.tween.update(1.0)
        expect_near(0.5, card.tile_x, 1e-5)
    end)

    it("tween animates tile_x and tile_y simultaneously", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        lurek.tween.tween(1.0, card, { tile_x = 3, tile_y = 6 }, "linear")
        lurek.tween.update(1.0)
        local x, y = card:getTilePosition()
        expect_near(3.0, x, 1e-5)
        expect_near(6.0, y, 1e-5)
    end)

    it("tween rejects a non-numeric duration", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        expect_error(function()
            lurek.tween.tween("oops", card, { tile_x = 1 })
        end)
    end)

end)




-- ================================================================
-- Merged from: test_integration_cardgame_tween.lua
-- ================================================================

-- Integration test: library.cardgame    lurek.tween.
--
-- Scope: Animates a cardgame Card's `tile_x` / `tile_y` position via
-- `lurek.tween.tween`, verifies a callback fires on tween completion,
-- composes two tweens with `lurek.tween.sequence`, and probes the
-- "in-out-quad" easing midpoint with `expect_near`.
--
-- Fallback: none. `lurek.tween` is gated by `modules.tween` (default true)
-- and the runtime namespace matches the user-requested name. Cards expose
-- mutable `tile_x` / `tile_y` fields that tween can drive directly.
--

local cg = require("library.cardgame")

local function fresh_card()
    cg.clearCardTypes()
    cg.resetIdCounter()
    cg.defineCardType("knight", { name = "Knight" })
    return cg.newCard("knight")
end

describe("integration: library.cardgame    lurek.tween", function()

    it("tween updates card tile_x toward target over multiple updates", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        lurek.tween.tween(2.0, card, { tile_x = 10 }, "linear")
        lurek.tween.update(0.5)
        local x_quarter = card.tile_x
        lurek.tween.update(0.5)
        local x_half = card.tile_x
        lurek.tween.update(1.0)

        expect_near(2.5,  x_quarter, 0.5)
        expect_near(5.0,  x_half,    0.5)
        expect_near(10.0, card.tile_x, 1e-5)
    end)

    it("finished tween triggers a cardgame onComplete callback once", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        local fired = 0
        local tw = lurek.tween.tween(1.0, card, { tile_x = 5 }, "linear")
        tw:onComplete(function()
            fired = fired + 1
            card:addTag("arrived")
        end)
        lurek.tween.update(1.5)

        expect_equal(1, fired)
        expect_true(card:hasTag("arrived"))
        expect_near(5.0, card.tile_x, 1e-5)
    end)

    it("sequence chains two card movement tweens", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        lurek.tween.tween(1.0, card, { tile_x = 4 }, "linear")
        lurek.tween.update(1.0)
        expect_near(4.0, card.tile_x, 0.5)

        lurek.tween.cancelAll()
        lurek.tween.tween(1.0, card, { tile_x = 10 }, "linear")
        lurek.tween.update(1.0)
        expect_near(10.0, card.tile_x, 0.5)
    end)

    it("inOutQuad easing reaches midpoint value at half duration", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        lurek.tween.tween(2.0, card, { tile_x = 1.0 }, "inOutQuad")
        lurek.tween.update(1.0)
        expect_near(0.5, card.tile_x, 1e-5)
    end)

    it("tween animates tile_x and tile_y simultaneously", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        card:setTilePosition(0, 0)

        lurek.tween.tween(1.0, card, { tile_x = 3, tile_y = 6 }, "linear")
        lurek.tween.update(1.0)
        local x, y = card:getTilePosition()
        expect_near(3.0, x, 1e-5)
        expect_near(6.0, y, 1e-5)
    end)

    it("tween rejects a non-numeric duration", function()
        lurek.tween.cancelAll()
        local card = fresh_card()
        expect_error(function()
            lurek.tween.tween("oops", card, { tile_x = 1 })
        end)
    end)

end)
test_summary()
