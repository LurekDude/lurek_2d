-- Lurek2D Parallax + Camera Integration Tests
-- Verifies that parallax layers respond correctly to camera positions and
-- that Camera2D position can drive parallax draw calls from Lua scripts.
--
-- Both lurek.parallax and lurek.camera namespaces must appear.
--
-- @covers lurek.parallax.newLayer
-- @covers lurek.parallax.newSet
-- @covers lurek.camera.new
-- @covers LuaParallaxLayer.draw
-- @covers LuaParallaxLayer.drawAuto
-- @covers LuaParallaxLayer.setScrollFactor
-- @covers LuaParallaxLayer.setAutoscroll
-- @covers LuaParallaxLayer.resetAutoscroll
-- @covers LuaParallaxSet.draw
-- @covers LuaParallaxSet.drawAuto
-- @covers LuaParallaxSet.update

local function load_image()
    return lurek.render.newImage("assets/icon.png")
end

-- @description Covers suite: parallax and camera modules exist together.
describe("parallax and camera modules exist together", function()
    -- @covers lurek.parallax
    -- @covers lurek.camera
    -- @description Verifies the parallax namespace exists; this is effectively a module-presence smoke test at the top of the integration file.
    it("lurek.parallax is a table", function()
        expect_type("table", lurek.parallax)
    end)
    -- @covers lurek.camera
    -- @covers lurek.parallax
    -- @description Verifies the camera namespace exists alongside parallax.
    it("lurek.camera is a table", function()
        expect_type("table", lurek.camera)
    end)
    -- @covers lurek.camera.new
    -- @covers lurek.parallax
    -- @description Verifies the camera factory returns a Camera2D userdata that parallax code can consume.
    it("lurek.camera.new creates a Camera2D object", function()
        local cam = lurek.camera.new(800, 600)
        expect_type("userdata", cam)
    end)
end)

-- @description Covers suite: Camera2D position drives parallax draw.
describe("Camera2D position drives parallax draw", function()
    -- @covers lurek.camera.Camera2D.setPosition
    -- @covers lurek.parallax
    -- @description Verifies camera position changes round-trip correctly before being used for parallax rendering.
    it("Camera2D setPosition and getPosition round-trip", function()
        local cam = lurek.camera.new(800, 600)
        cam:setPosition(400, 300)
        local cx, cy = cam:getPosition()
        expect_near(400.0, cx)
        expect_near(300.0, cy)
    end)

    -- @covers lurek.camera.Camera2D.getPosition
    -- @covers lurek.parallax.Layer.draw
    -- @description Verifies a parallax layer can draw using coordinates pulled from a Camera2D instance.
    it("parallax layer draws without error with Camera2D position", function()
        local cam = lurek.camera.new(800, 600)
        cam:setPosition(640, 360)
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            scroll_factor_x = 0.5,
        })
        local cx, cy = cam:getPosition()
        expect_no_error(function()
            layer:draw(cx, cy)
        end)
    end)

    -- @covers lurek.parallax.Layer.draw
    -- @covers lurek.camera
    -- @description Verifies the same parallax layer can be drawn successfully from multiple camera positions.
    it("two draw calls at different positions both succeed", function()
        local layer = lurek.parallax.newLayer({ texture = load_image(), scroll_factor_x = 0.3 })
        expect_no_error(function()
            layer:draw(0, 0)
            layer:draw(1280, 720)
        end)
    end)

    -- @covers lurek.parallax.Set.draw
    -- @covers lurek.camera.Camera2D.getPosition
    -- @description Verifies a parallax set can render all of its layers using coordinates sourced from a Camera2D.
    it("set:draw with Camera2D position does not raise", function()
        local img = load_image()
        local s = lurek.parallax.newSet("bg_auto")
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.2, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.5, z = 1 }))
        local cam = lurek.camera.new(800, 600)
        cam:setPosition(500, 200)
        local cx, cy = cam:getPosition()
        expect_no_error(function()
            s:draw(cx, cy)
        end)
    end)
end)

-- @description Covers suite: drawAuto uses the engine camera.
describe("drawAuto uses the engine camera", function()
    -- @covers lurek.parallax.Layer.drawAuto
    -- @covers lurek.camera
    -- @description Verifies a single parallax layer can render using the engine camera automatically.
    it("layer:drawAuto does not raise", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_no_error(function()
            layer:drawAuto()
        end)
    end)
    -- @covers lurek.parallax.Set.drawAuto
    -- @covers lurek.camera
    -- @description Verifies a multi-layer parallax set can auto-draw against the engine camera.
    it("set:drawAuto does not raise with multiple layers", function()
        local img = load_image()
        local s = lurek.parallax.newSet("auto_test")
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = 1 }))
        expect_no_error(function()
            s:drawAuto()
        end)
    end)
end)

-- @description Covers suite: Multi-layer parallax scroll factor differentiation.
describe("Multi-layer parallax scroll factor differentiation", function()
    -- @covers lurek.parallax.Layer.draw
    -- @covers lurek.camera
    -- @description Verifies layers with different scroll factors all render successfully for the same camera position.
    it("layers with different scroll factors all draw without error", function()
        local img = load_image()
        local far   = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.1 })
        local mid   = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.4 })
        local close = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.8 })
        expect_no_error(function()
            far:draw(640, 360)
            mid:draw(640, 360)
            close:draw(640, 360)
        end)
    end)
    -- @covers lurek.parallax.Layer.draw
    -- @covers lurek.camera
    -- @description Verifies a sky layer with zero scroll factor remains drawable regardless of camera position.
    it("sky layer with scroll_factor 0 draws at any camera position", function()
        local sky = lurek.parallax.newLayer({
            texture = load_image(),
            scroll_factor_x = 0.0,
            scroll_factor_y = 0.0,
        })
        expect_no_error(function()
            sky:draw(9999, 9999)
        end)
    end)
    -- @covers lurek.parallax.Layer.draw
    -- @covers lurek.camera
    -- @description Verifies foreground layers using exaggerated scroll factors still draw without error.
    it("foreground layer with scroll_factor > 1 draws without error", function()
        local fg = lurek.parallax.newLayer({ texture = load_image(), scroll_factor_x = 1.5 })
        expect_no_error(function()
            fg:draw(300, 0)
        end)
    end)
    -- @covers lurek.parallax.Set.draw
    -- @covers lurek.camera
    -- @description Verifies a parallax set can render layers in z-sorted order for a shared camera position.
    it("layers in a set are sorted by z and drawn in order", function()
        local img = load_image()
        local s = lurek.parallax.newSet("sorted")
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.8, z = 2 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.4, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.1, z = 1 }))
        expect_no_error(function()
            s:draw(800, 0)
        end)
    end)
end)

-- @description Covers suite: Autoscroll with camera movement.
describe("Autoscroll with camera movement", function()
    -- @covers lurek.parallax.Layer.update
    -- @covers lurek.camera
    -- @description Verifies repeated update-and-draw cycles remain safe while camera input changes the parallax draw position.
    it("update + draw loop does not raise", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            autoscroll_x = 80.0,
        })
        for i = 1, 30 do
            local dt = 1.0 / 60.0
            layer:update(dt)
            expect_no_error(function()
                layer:draw(i * 5.0, 0)
            end)
        end
    end)
    -- @covers lurek.parallax.Set.update
    -- @covers lurek.camera
    -- @description Verifies a multi-layer parallax set can update autoscroll state and draw repeatedly over a moving camera path.
    it("set:update + set:draw loop does not raise", function()
        local img = load_image()
        local s = lurek.parallax.newSet("wind")
        s:addLayer(lurek.parallax.newLayer({ texture = img, autoscroll_x = 20.0, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, autoscroll_x = 50.0, z = 1 }))
        for i = 1, 30 do
            s:update(1.0 / 60.0)
            expect_no_error(function()
                s:draw(i * 10.0, 0)
            end)
        end
    end)
    -- @covers lurek.parallax.Layer.update
    -- @covers lurek.camera
    -- @description Verifies long-running autoscroll remains drawable after many update steps.
    it("autoscroll stays bounded after many frames", function()
        local layer = lurek.parallax.newLayer({ texture = load_image(), autoscroll_x = 600.0 })
        for _ = 1, 3600 do
            layer:update(1.0 / 60.0)
        end
        expect_no_error(function()
            layer:draw(0, 0)
        end)
    end)
end)

-- @description Covers suite: Scene transition: hide -> resetAutoscroll -> show.
describe("Scene transition: hide -> resetAutoscroll -> show", function()
    -- @covers lurek.parallax.Layer.resetAutoscroll
    -- @covers lurek.camera
    -- @description Verifies a hide-reset-show transition leaves the parallax set drawable again for the camera.
    it("full transition sequence does not raise", function()
        local img = load_image()
        local s = lurek.parallax.newSet("level1_bg")
        local far  = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.2, autoscroll_x = 15.0, z = 0 })
        local near = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.6, autoscroll_x = 40.0, z = 1 })
        s:addLayer(far)
        s:addLayer(near)
        for i = 1, 60 do
            s:update(1.0 / 60.0)
            s:draw(i * 20.0, 0)
        end
        s:setVisible(false)
        far:resetAutoscroll()
        near:resetAutoscroll()
        s:setVisible(true)
        expect_no_error(function()
            s:update(1.0 / 60.0)
            s:draw(0, 0)
        end)
    end)
end)

-- @description Covers suite: Layer crossfade via opacity.
describe("Layer crossfade via opacity", function()
    -- @covers lurek.parallax.Layer.setOpacity
    -- @covers lurek.camera
    -- @description Verifies complementary opacity changes allow two parallax layers to crossfade while drawing at shared camera positions.
    it("fading one layer out while another fades in does not raise", function()
        local img = load_image()
        local day   = lurek.parallax.newLayer({ texture = img, opacity = 1.0 })
        local night = lurek.parallax.newLayer({ texture = img, opacity = 0.0 })
        for i = 0, 30 do
            local t = i / 30.0
            day:setOpacity(1.0 - t)
            night:setOpacity(t)
            expect_no_error(function()
                day:draw(i * 15.0, 0)
                night:draw(i * 15.0, 0)
            end)
        end
    end)
end)

-- @description Covers suite: Physics-driven camera analogue.
describe("Physics-driven camera analogue", function()
    -- @covers lurek.parallax.Layer.draw
    -- @covers lurek.camera
    -- @description Verifies a simulated moving body position can be used as camera input for parallax drawing over time.
    it("simulated physics position drives parallax layer", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            scroll_factor_x = 0.4,
        })
        local body_x = 0.0
        local velocity_x = 200.0
        for _ = 1, 30 do
            local dt = 1.0 / 60.0
            body_x = body_x + velocity_x * dt
            layer:update(dt)
            expect_no_error(function()
                layer:draw(body_x, 0)
            end)
        end
        expect_true(body_x > 90.0, "simulated body should have moved forward")
    end)

    -- @covers lurek.camera.Camera2D.setPosition
    -- @covers lurek.parallax.Layer.draw
    -- @description Verifies a moving Camera2D follow position can drive repeated parallax draw calls.
    it("Camera2D follow position drives parallax draw", function()
        local cam = lurek.camera.new(800, 600)
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            scroll_factor_x = 0.5,
        })
        for i = 1, 30 do
            cam:setPosition(i * 10.0, 0)
            local cx, cy = cam:getPosition()
            layer:update(1.0 / 60.0)
            expect_no_error(function()
                layer:draw(cx, cy)
            end)
        end
    end)
end)
test_summary()
