-- Evidence test: physics debug drawing
-- Produces: draw_debug.png showing bouncing bodies after simulation
-- @evidence file
-- @covers lurek.physics.newWorld
-- @covers lurek.physics.newRectShape
-- @covers lurek.physics.newCircleShape
-- @covers World:drawDebug

describe("evidence: physics debug drawing", function()
    it("creates draw_debug.png from simulated world", function()
        ensure_evidence_dir("physics")
        local path = evidence_output_dir("physics") .. "draw_debug.png"

        local img = lurek.image.newImageData(256, 256)
        img:fill(20, 20, 40, 255)

        local world = lurek.physics.newWorld(0, 50)

        -- ground
        local ground = world:newBody("STATIC", 128, 200)
        local rect = lurek.physics.newRectShape(200, 20)
        ground:setShape(rect)

        -- circle
        local ball = world:newBody("DYNAMIC", 100, 50)
        local circle = lurek.physics.newCircleShape(15)
        ball:setShape(circle)
        ball:setRestitution(0.8)

        -- box
        local box = world:newBody("DYNAMIC", 150, 50)
        local box_shape = lurek.physics.newRectShape(20, 20)
        box:setShape(box_shape)
        box:setRestitution(0.3)

        -- run physics
        for i = 1, 60 do
            world:step()
        end

        -- draw the world to the image
        world:drawDebug(img, 255, 0, 255, 255)
        img:savePNG(path)

        expect_evidence_created(path)
    end)
end)

test_summary()
