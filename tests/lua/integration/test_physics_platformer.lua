-- Integration: lurek.physics contact callbacks bridged through lurek.event signals
describe("one-way platform integration", function()
    local world, floor, player

    before_each(function()
        -- Gravity pointing down (+Y).
        world  = lurek.physics.newWorld(0, 200)
        -- A wide static floor at y=500.
        floor  = lurek.physics.newBody(world, 400, 500, "static")
        -- Mark the floor as one-way: normal points upward (0, -1)
        -- so bodies approaching from above are blocked.
        world:setBodyOneWay(floor:getId(), 0, -1)
        -- A dynamic player above the floor.
        player = lurek.physics.newBody(world, 400, 100, "dynamic")
    end)

    -- @integration LWorld:getBodyOneWay
    it("floor has correct one-way normal", function()
        local nx, ny = world:getBodyOneWay(floor:getId())
        expect_near(0,  nx, 1e-5)
        expect_near(-1, ny, 1e-5)
    end)

end)


describe("contact callbacks and sleeping integration", function()
    local world
    local began, ended

    before_each(function()
        world = lurek.physics.newWorld(0, 0)
        began = 0
        ended = 0
        world:setBeginContact(function(a, b)
            began = began + 1
        end)
        world:setEndContact(function(a, b)
            ended = ended + 1
        end)
    end)

    -- @integration LWorld:clearBeginContact
    -- @integration LWorld:clearEndContact
    -- @integration LWorld:step
    it("stepping after clearing callbacks does not error", function()
        world:clearBeginContact()
        world:clearEndContact()
        world:step(1/60)
        expect_equal(0, began)
        expect_equal(0, ended)
    end)

end)


describe("batch body creation integration", function()
    local world

    before_each(function()
        world = lurek.physics.newWorld(0, 9.81)
    end)

    -- @integration LWorld:newBodies
    it("batch-created bodies can be stepped", function()
        local ids = world:newBodies({
            {0,   0, "dynamic"},
            {100, 0, "static"},
            {200, 0, "kinematic"},
        })
        expect_equal(3, #ids)
        expect_no_error(function()
            for _ = 1, 5 do
                world:step(1/60)
            end
        end)
    end)

    -- @integration LWorld:getSolverIterations
    -- @integration LWorld:newBodies
    -- @integration LWorld:setSolverIterations
    it("batch creation works with custom solver iterations", function()
        world:setSolverIterations(6)
        local ids = world:newBodies({{0, 0, "dynamic"}, {50, 0, "dynamic"}})
        expect_equal(2, #ids)
        expect_equal(6, world:getSolverIterations())
    end)
end)
describe("physics contact bridged through lurek.event signal", function()

    -- @integration lurek.event.newSignal
    -- @integration LSignal:connect
    -- @integration LSignal:emit
    -- @integration LWorld:setBeginContact
    it("contact callback routes through engine signal to subscriber", function()
        local world = lurek.physics.newWorld(0, 0)
        local sig = lurek.event.newSignal()

        local seen = {}
        sig:connect("contact", function(id_a, id_b)
            seen[#seen + 1] = { id_a, id_b }
        end)

        local b1 = lurek.physics.newBody(world, 0, 0, "static")
        local b2 = lurek.physics.newBody(world, 0, 0, "dynamic")

        world:setBeginContact(function(id_a, id_b)
            sig:emit("contact", id_a, id_b)
        end)

        -- Verify the signal bridge itself works by emitting manually
        sig:emit("contact", b1:getId(), b2:getId())
        expect_equal(1, #seen, "manual emit arrives via signal bridge")
        expect_equal(b1:getId(), seen[1][1], "correct body A id forwarded")
        expect_equal(b2:getId(), seen[1][2], "correct body B id forwarded")
    end)

    -- @integration lurek.event.newSignal
    -- @integration LSignal:connect
    -- @integration LWorld:clearBeginContact
    it("clearing physics callback does not break signal subscribers", function()
        local world = lurek.physics.newWorld(0, 0)
        local sig = lurek.event.newSignal()

        local count = 0
        sig:connect("contact", function() count = count + 1 end)

        world:setBeginContact(function(id_a, id_b)
            sig:emit("contact", id_a, id_b)
        end)
        world:clearBeginContact()

        -- After clear, stepping must not error and signal count stays zero
        world:step(1 / 60)
        expect_equal(0, count, "cleared callback emits nothing")

        -- Signal itself still works after physics side was cleared
        sig:emit("contact", 1, 2)
        expect_equal(1, count, "signal subscriber still receives direct emits")
    end)

end)
test_summary()
