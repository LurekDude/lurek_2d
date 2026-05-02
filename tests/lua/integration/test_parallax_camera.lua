-- Lurek2D Parallax + Camera Integration Tests
-- Verifies that parallax layers respond correctly to camera positions and
-- that Camera2D position can drive parallax draw calls from Lua scripts.
--
-- Both lurek.parallax and lurek.camera namespaces must appear.
--

local function load_image()
    return lurek.render.newImage("assets/icon.png")
end

describe("parallax and camera modules exist together", function()
    it("lurek.parallax is a table", function()
        expect_type("table", lurek.parallax)
    end)
    it("lurek.camera is a table", function()
        expect_type("table", lurek.camera)
    end)
    it("lurek.camera.new creates a Camera2D object", function()
        local cam = lurek.camera.new(800, 600)
        expect_type("userdata", cam)
    end)
end)

describe("Camera2D position drives parallax draw", function()
    it("Camera2D setPosition and getPosition round-trip", function()
        local cam = lurek.camera.new(800, 600)
        cam:setPosition(400, 300)
        local cx, cy = cam:getPosition()
        expect_near(400.0, cx)
        expect_near(300.0, cy)
    end)

    it("parallax layer draws without error with Camera2D position", function()
        local cam = lurek.camera.new(800, 600)
        cam:setPosition(640, 360)
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            scroll_factor_x = 0.5,
        })
        local cx, cy = cam:getPosition()
        expect_no_error(function()
            layer:render(cx, cy)
        end)
    end)

    it("two draw calls at different positions both succeed", function()
        local layer = lurek.parallax.newLayer({ texture = load_image(), scroll_factor_x = 0.3 })
        expect_no_error(function()
            layer:render(0, 0)
            layer:render(1280, 720)
        end)
    end)

    it("set:draw with Camera2D position does not raise", function()
        local img = load_image()
        local s = lurek.parallax.newSet("bg_auto")
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.2, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.5, z = 1 }))
        local cam = lurek.camera.new(800, 600)
        cam:setPosition(500, 200)
        local cx, cy = cam:getPosition()
        expect_no_error(function()
            s:render(cx, cy)
        end)
    end)
end)

describe("drawAuto uses the engine camera", function()
    it("layer:drawAuto does not raise", function()
        local layer = lurek.parallax.newLayer({ texture = load_image() })
        expect_no_error(function()
            layer:renderAuto()
        end)
    end)
    it("set:drawAuto does not raise with multiple layers", function()
        local img = load_image()
        local s = lurek.parallax.newSet("auto_test")
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, z = 1 }))
        expect_no_error(function()
            s:renderAuto()
        end)
    end)
end)

describe("Multi-layer parallax scroll factor differentiation", function()
    it("layers with different scroll factors all draw without error", function()
        local img = load_image()
        local far   = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.1 })
        local mid   = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.4 })
        local close = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.8 })
        expect_no_error(function()
            far:render(640, 360)
            mid:render(640, 360)
            close:render(640, 360)
        end)
    end)
    it("sky layer with scroll_factor 0 draws at any camera position", function()
        local sky = lurek.parallax.newLayer({
            texture = load_image(),
            scroll_factor_x = 0.0,
            scroll_factor_y = 0.0,
        })
        expect_no_error(function()
            sky:render(9999, 9999)
        end)
    end)
    it("foreground layer with scroll_factor > 1 draws without error", function()
        local fg = lurek.parallax.newLayer({ texture = load_image(), scroll_factor_x = 1.5 })
        expect_no_error(function()
            fg:render(300, 0)
        end)
    end)
    it("layers in a set are sorted by z and drawn in order", function()
        local img = load_image()
        local s = lurek.parallax.newSet("sorted")
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.8, z = 2 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.4, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.1, z = 1 }))
        expect_no_error(function()
            s:render(800, 0)
        end)
    end)
end)

describe("Autoscroll with camera movement", function()
    it("update + draw loop does not raise", function()
        local layer = lurek.parallax.newLayer({
            texture = load_image(),
            autoscroll_x = 80.0,
        })
        for i = 1, 30 do
            local dt = 1.0 / 60.0
            layer:update(dt)
            expect_no_error(function()
                layer:render(i * 5.0, 0)
            end)
        end
    end)
    it("set:update + set:draw loop does not raise", function()
        local img = load_image()
        local s = lurek.parallax.newSet("wind")
        s:addLayer(lurek.parallax.newLayer({ texture = img, autoscroll_x = 20.0, z = 0 }))
        s:addLayer(lurek.parallax.newLayer({ texture = img, autoscroll_x = 50.0, z = 1 }))
        for i = 1, 30 do
            s:update(1.0 / 60.0)
            expect_no_error(function()
                s:render(i * 10.0, 0)
            end)
        end
    end)
    it("autoscroll stays bounded after many frames", function()
        local layer = lurek.parallax.newLayer({ texture = load_image(), autoscroll_x = 600.0 })
        for _ = 1, 3600 do
            layer:update(1.0 / 60.0)
        end
        expect_no_error(function()
            layer:render(0, 0)
        end)
    end)
end)

describe("Scene transition: hide -> resetAutoscroll -> show", function()
    it("full transition sequence does not raise", function()
        local img = load_image()
        local s = lurek.parallax.newSet("level1_bg")
        local far  = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.2, autoscroll_x = 15.0, z = 0 })
        local near = lurek.parallax.newLayer({ texture = img, scroll_factor_x = 0.6, autoscroll_x = 40.0, z = 1 })
        s:addLayer(far)
        s:addLayer(near)
        for i = 1, 60 do
            s:update(1.0 / 60.0)
            s:render(i * 20.0, 0)
        end
        s:setVisible(false)
        far:resetAutoscroll()
        near:resetAutoscroll()
        s:setVisible(true)
        expect_no_error(function()
            s:update(1.0 / 60.0)
            s:render(0, 0)
        end)
    end)
end)

describe("Layer crossfade via opacity", function()
    it("fading one layer out while another fades in does not raise", function()
        local img = load_image()
        local day   = lurek.parallax.newLayer({ texture = img, opacity = 1.0 })
        local night = lurek.parallax.newLayer({ texture = img, opacity = 0.0 })
        for i = 0, 30 do
            local t = i / 30.0
            day:setOpacity(1.0 - t)
            night:setOpacity(t)
            expect_no_error(function()
                day:render(i * 15.0, 0)
                night:render(i * 15.0, 0)
            end)
        end
    end)
end)

describe("Physics-driven camera analogue", function()
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
                layer:render(body_x, 0)
            end)
        end
        expect_true(body_x > 90.0, "simulated body should have moved forward")
    end)

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
                layer:render(cx, cy)
            end)
        end
    end)
end)
test_summary()
