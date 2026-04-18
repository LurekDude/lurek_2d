-- @covers lurek.physics.newWorld
-- @covers lurek.physics.newBody
describe("lurek.physics world creation", function()
    it("creates a world", function()
        local world = lurek.physics.newWorld(0, 980)
        expect_not_nil(world)
    end)
end)

-- @covers Body:getPosition
-- @covers Body:applyForce
describe("Body methods", function()
    it("gets position after force", function()
        -- ...
    end)
end)
