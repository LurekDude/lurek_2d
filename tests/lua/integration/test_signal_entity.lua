-- Lurek2D Integration Test: Signal + Entity
-- Tests entities emitting and receiving signals.
-- @covers lurek.entity.newUniverse
-- @covers lurek.signal.new

describe("integration: entity events via signal", function()
    it("entity creation triggers signal", function()
        local universe    = lurek.entity.newUniverse()
        local on_spawn    = lurek.signal.new()
        local spawn_count = 0

        on_spawn:connect(function(id)
            spawn_count = spawn_count + 1
        end)

        -- Simulate spawn + emit
        for _ = 1, 5 do
            local id = universe:spawn()
            on_spawn:emit(id)
        end

        expect_equal(5, spawn_count, "spawn signal emitted 5 times")
    end)

    it("entity kill triggers destroy signal", function()
        local universe     = lurek.entity.newUniverse()
        local on_destroy   = lurek.signal.new()
        local destroy_log  = {}

        on_destroy:connect(function(id)
            destroy_log[#destroy_log + 1] = id
        end)

        local ids = {}
        for i = 1, 3 do
            local id = universe:spawn()
            universe:set(id, "index", i)
            ids[i] = id
        end

        for _, id in ipairs(ids) do
            universe:kill(id)
            on_destroy:emit(id)
        end

        expect_equal(3, #destroy_log, "destroy signal emitted for each entity")
    end)

    it("signal listener receives entity component data", function()
        local universe   = lurek.entity.newUniverse()
        local on_damaged = lurek.signal.new()
        local last_dmg   = 0

        on_damaged:connect(function(dmg)
            last_dmg = last_dmg + dmg
        end)

        local id = universe:spawn()
        universe:set(id, "hp", 100)

        -- Entity takes 3 hits
        for _, dmg in ipairs({10, 20, 15}) do
            universe:set(id, "hp", universe:get(id, "hp") - dmg)
            on_damaged:emit(dmg)
        end

        expect_equal(45, last_dmg, "total damage accumulated via signal")
        expect_equal(55, universe:get(id, "hp"), "entity hp reduced correctly")
    end)

    it("disconnected signal listener not called", function()
        local sig   = lurek.signal.new()
        local count = 0

        local conn = sig:connect(function()
            count = count + 1
        end)

        sig:emit()
        expect_equal(1, count, "listener called once before disconnect")

        conn:disconnect()
        sig:emit()
        expect_equal(1, count, "listener not called after disconnect")
    end)
end)

test_summary()
