-- Evidence test: physics simulation â€” body positions after stepping
-- Produces: physics_sim.png showing colored dots at body positions

-- @description Covers suite: evidence: physics simulation.
describe("evidence: physics simulation", function()
    -- @covers lurek.physics.newWorld
    -- @covers World:newBody
    -- @covers lurek.physics.newRectangleShape
    -- @covers lurek.physics.newCircleShape
    -- @covers lurek.physics.attachShape
    -- @covers World:step
    -- @covers Body:getPosition
    -- @covers lurek.image.savePNG
    -- @evidence file
    -- @description Simulates a small physics scene for one second and saves a PNG showing the final body positions.
    it("simulates bodies and writes position evidence image", function()
        ensure_evidence_dir("physics")
        local path = evidence_output_dir("physics") .. "physics_sim.png"

        local world = lurek.physics.newWorld(0, 50)

        -- ground (static)
        local ground = world:newBody(128, 200, "static")
        local rect = lurek.physics.newRectangleShape(200, 20)
        lurek.physics.attachShape(ground, rect)

        -- circle (dynamic â€” should fall under gravity)
        local ball = world:newBody(100, 20, "dynamic")
        local circle = lurek.physics.newCircleShape(10)
        circle:setRestitution(0.5)
        lurek.physics.attachShape(ball, circle)

        -- box (dynamic)
        local box = world:newBody(160, 20, "dynamic")
        local box_shape = lurek.physics.newRectangleShape(16, 16)
        box_shape:setRestitution(0.2)
        lurek.physics.attachShape(box, box_shape)

        -- run physics for 60 steps at 1/60 s each (1 second of sim)
        for i = 1, 60 do
            world:step(1/60)
        end

        -- paint evidence image from body positions
        local img = lurek.image.newImageData(256, 256)
        img:fill(20, 20, 40, 255)

        -- ground â€” white bar
        for px = 28, 228 do
            for py = 190, 210 do
                img:setPixel(px, py, 200, 200, 200, 255)
            end
        end

        -- ball position (yellow dot)
        local bx, by = ball:getPosition()
        bx = math.floor(bx); by = math.floor(by)
        for dx = -4, 4 do
            for dy = -4, 4 do
                local px = bx + dx; local py = by + dy
                if px >= 0 and px < 256 and py >= 0 and py < 256 then
                    img:setPixel(px, py, 255, 220, 0, 255)
                end
            end
        end

        -- box position (cyan dot)
        local bx2, by2 = box:getPosition()
        bx2 = math.floor(bx2); by2 = math.floor(by2)
        for dx = -4, 4 do
            for dy = -4, 4 do
                local px = bx2 + dx; local py = by2 + dy
                if px >= 0 and px < 256 and py >= 0 and py < 256 then
                    img:setPixel(px, py, 0, 220, 255, 255)
                end
            end
        end

        lurek.image.savePNG(img, path)
        expect_evidence_created(path)
    end)
end)
test_summary()
