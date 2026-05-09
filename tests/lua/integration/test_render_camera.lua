-- Integration: render draw commands combined with camera transform state
describe("graphics + camera integration", function()
    -- @integration LCamera:getPosition
    -- @integration LCamera:setPosition
    -- @integration lurek.camera.newCamera
    -- @integration lurek.render.rectangle
    -- @integration lurek.render.setColor
    it("camera transforms affect draw command coordinates", function()
        local cam = lurek.camera.newCamera()
        cam:setPosition(100, 200)

        -- Verify camera position stored
        local cx, cy = cam:getPosition()
        expect_near(100, cx, 0.01, "camera x")
        expect_near(200, cy, 0.01, "camera y")

        -- Draw commands should still work
        local ok = pcall(function()
            lurek.render.setColor(1, 0, 0, 1)
            lurek.render.rectangle("fill", 10, 10, 50, 50)
        end)
        expect_true(ok, "render calls accept scene state after camera position update")
    end)

    -- @integration LCamera:getZoom
    -- @integration LCamera:setZoom
    -- @integration lurek.camera.newCamera
    -- @integration lurek.render.circle
    it("camera zoom scales the viewport", function()
        local cam = lurek.camera.newCamera()
        cam:setZoom(2.0)

        local zoom = cam:getZoom()
        expect_near(2.0, zoom, 0.01, "zoom is 2x")

        -- Drawing at zoom should not error
        local ok = pcall(function()
            lurek.render.circle("fill", 100, 100, 25)
        end)
        expect_true(ok, "circle draw accepts scene state after camera zoom update")
    end)

    -- @integration LCamera:getRotation
    -- @integration LCamera:setRotation
    -- @integration lurek.camera.newCamera
    -- @integration lurek.render.line
    it("camera rotation combines with graphics transforms", function()
        local cam = lurek.camera.newCamera()
        cam:setRotation(math.pi / 4)

        local rot = cam:getRotation()
        expect_near(math.pi / 4, rot, 0.001, "camera rotated 45 degrees")

        -- Draw with camera rotation applied
        local ok = pcall(function()
            lurek.render.line(0, 0, 100, 100)
        end)
        expect_true(ok, "line draw accepts scene state after camera rotation update")
    end)

    -- @integration LCamera:getPosition
    -- @integration LCamera:getZoom
    -- @integration LCamera:setPosition
    -- @integration LCamera:setZoom
    -- @integration lurek.camera.newCamera
    -- @integration lurek.render.rectangle
    it("camera position and zoom state remains coherent for subsequent draw", function()
        local cam = lurek.camera.newCamera()
        cam:setPosition(200, 150)
        cam:setZoom(1.5)

        local cx, cy = cam:getPosition()
        local zoom = cam:getZoom()
        expect_near(200, cx, 0.01, "camera x")
        expect_near(150, cy, 0.01, "camera y")
        expect_near(1.5, zoom, 0.01, "camera zoom")

        local ok = pcall(function()
            lurek.render.rectangle("line", cx, cy, 20 * zoom, 10 * zoom)
        end)
        expect_true(ok, "draw command accepts camera-derived coordinates and size")
    end)
end)
test_summary()
