-- @covers lurek.physics.newWorld
-- @covers lurek.physics.newBody
-- @covers Body:applyForce
describe("lurek.physics world creation", function()
    it("creates a world with gravity", function()
        local world = lurek.physics.newWorld(0, 980)
        expect_not_nil(world)
    end)
end)
