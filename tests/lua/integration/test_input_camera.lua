-- Lurek2D Integration Test: Input + Camera
-- Tests screen-to-world coordinate transforms via camera.

describe("integration: input coordinates mapped through camera", function()
    it("camera at origin: screen coords equal world coords", function()
        local cam = lurek.camera.newCamera()
        cam:setPosition(0, 0)
        cam:setZoom(1.0)

        -- With camera at origin, zoom 1.0          world pos equals screen pos
        local screen_x, screen_y = 320.0, 240.0
        local cx, cy = cam:getPosition()
        local zoom   = cam:getZoom()

        -- Manual screen-to-world formula: world = screen / zoom + cam_pos - screen_center/zoom
        -- Here we just verify zoom is 1.0 and cam is at origin
        expect_near(1.0, zoom,   0.001, "zoom is 1")
        expect_near(0.0, cx,     0.001, "cam at origin x")
        expect_near(0.0, cy,     0.001, "cam at origin y")
        -- At zoom=1 and cam=(0,0), a click at screen (320,240) maps to world (320,240)
        local world_x = screen_x / zoom + cx
        local world_y = screen_y / zoom + cy
        expect_near(320.0, world_x, 0.001, "world x matches screen x")
        expect_near(240.0, world_y, 0.001, "world y matches screen y")
    end)

    it("camera panned: world coords offset from screen", function()
        local cam = lurek.camera.newCamera()
        cam:setPosition(100, 50)
        cam:setZoom(1.0)

        local screen_x, screen_y = 0.0, 0.0
        local cx, cy = cam:getPosition()
        local zoom   = cam:getZoom()

        local world_x = screen_x / zoom + cx
        local world_y = screen_y / zoom + cy

        expect_near(100.0, world_x, 0.001, "world x offset by cam pan")
        expect_near(50.0,  world_y, 0.001, "world y offset by cam pan")
    end)

    it("camera zoomed 2x: world coords halved relative to screen", function()
        local cam = lurek.camera.newCamera()
        cam:setPosition(0, 0)
        cam:setZoom(2.0)

        local screen_x = 200.0
        local zoom     = cam:getZoom()
        local world_x  = screen_x / zoom

        expect_near(100.0, world_x, 0.001, "zoom 2x halves screen x to world x")
    end)

    it("getMousePosition returns two numbers", function()
        expect_no_error(function()
            local mx, my = lurek.input.mouse.getPosition()
            expect_type("number", mx, "mouse x is number")
            expect_type("number", my, "mouse y is number")
        end)
    end)
end)
test_summary()
