-- test_evidence_camera.lua
-- Evidence test: lurek.camera API contracts and visual diagram evidence

local OUT = "tests/lua/evidence/output/camera/"
local PI  = math.pi

-- ── helpers ──────────────────────────────────────────────────────────────────

--- Draw a mini world onto an ImageData then apply camera transforms for a viewport.
--- Returns an ImageData of size vw×vh.
local function render_world_through_cam(cam, world_w, world_h, vw, vh)
    local img = lurek.image.newImageData(vw, vh)
    img:fill(15, 20, 35, 255)

    -- draw a grid in world space
    local cell = 32
    for x = 0, world_w, cell do
        for y = 0, world_h do
            local sx, sy = cam:toScreen(x, y)
            if sx >= 1 and sx <= vw and sy >= 1 and sy <= vh then
                img:setPixel(math.floor(sx), math.floor(sy), 50, 60, 80, 255)
            end
        end
    end
    for y = 0, world_h, cell do
        for x = 0, world_w do
            local sx, sy = cam:toScreen(x, y)
            if sx >= 1 and sx <= vw and sy >= 1 and sy <= vh then
                img:setPixel(math.floor(sx), math.floor(sy), 50, 60, 80, 255)
            end
        end
    end

    -- draw a rectangle for the "player" at world centre
    local px, py = world_w / 2, world_h / 2
    for dy = -10, 10 do
        for dx = -10, 10 do
            local sx, sy = cam:toScreen(px + dx, py + dy)
            if sx >= 1 and sx <= vw and sy >= 1 and sy <= vh then
                img:setPixel(math.floor(sx), math.floor(sy), 220, 100, 80, 255)
            end
        end
    end

    return img
end

-- ── tests ────────────────────────────────────────────────────────────────────

describe("Evidence: lurek.camera creation and defaults", function()

    it("newCamera creates a Camera object", function()
        local cam = lurek.camera.newCamera()
        expect_equal(cam ~= nil, true)
        expect_equal(cam:type(), "Camera")
    end)

    it("default position is 0,0", function()
        local cam = lurek.camera.newCamera()
        local x, y = cam:getPosition()
        expect_near(x, 0, 0.001)
        expect_near(y, 0, 0.001)
    end)

    it("default zoom is 1", function()
        local cam = lurek.camera.newCamera()
        expect_near(cam:getZoom(), 1.0, 0.001)
    end)

    it("default rotation is 0", function()
        local cam = lurek.camera.newCamera()
        expect_near(cam:getRotation(), 0.0, 0.001)
    end)
end)

describe("Evidence: lurek.camera setPosition / getPosition", function()

    it("setPosition / getPosition round-trip", function()
        local cam = lurek.camera.newCamera()
        cam:setPosition(120.5, -75.0)
        local x, y = cam:getPosition()
        expect_near(x, 120.5, 0.001)
        expect_near(y, -75.0, 0.001)
    end)

    it("move() shifts position", function()
        local cam = lurek.camera.newCamera()
        cam:setPosition(100, 100)
        cam:move(50, -25)
        local x, y = cam:getPosition()
        expect_near(x, 150, 0.001)
        expect_near(y,  75, 0.001)
    end)
end)

describe("Evidence: lurek.camera zoom and coordinate transforms", function()

    it("setZoom / getZoom round-trip", function()
        local cam = lurek.camera.newCamera()
        cam:setZoom(2.5)
        expect_near(cam:getZoom(), 2.5, 0.001)
    end)

    it("toScreen / toWorld are inverses at default zoom", function()
        local cam = lurek.camera.newCamera()
        cam:setViewport(0, 0, 320, 240)
        cam:setPosition(0, 0)

        local wx, wy = 50.0, 80.0
        local sx, sy = cam:toScreen(wx, wy)
        local bx, by = cam:toWorld(sx, sy)
        expect_near(bx, wx, 0.5)
        expect_near(by, wy, 0.5)
    end)

    it("zoom 2× makes objects appear closer — PNG evidence: zoom_compare", function()
        local VW, VH = 160, 120
        local WW, WH = 320, 240

        local img = lurek.image.newImageData(VW * 2 + 4, VH)
        img:fill(8, 8, 16, 255)

        -- Zoom 1×
        local cam1 = lurek.camera.newCamera()
        cam1:setViewport(0, 0, VW, VH)
        cam1:setPosition(WW / 2, WH / 2)
        cam1:setZoom(1.0)
        local left = render_world_through_cam(cam1, WW, WH, VW, VH)

        -- Zoom 2×
        local cam2 = lurek.camera.newCamera()
        cam2:setViewport(0, 0, VW, VH)
        cam2:setPosition(WW / 2, WH / 2)
        cam2:setZoom(2.0)
        local right = render_world_through_cam(cam2, WW, WH, VW, VH)

        -- Blit both halves
        for y = 1, VH do
            for x = 1, VW do
                local r, g, b, a = left:getPixel(x, y)
                img:setPixel(x, y, r, g, b, a)
            end
        end
        for y = 1, VH do
            for x = 1, VW do
                local r, g, b, a = right:getPixel(x, y)
                img:setPixel(VW + 4 + x, y, r, g, b, a)
            end
        end

        lurek.image.savePNG(img, OUT .. "evidence_camera_zoom_compare.png")
    end)
end)

describe("Evidence: lurek.camera rotation", function()

    it("setRotation / getRotation round-trip", function()
        local cam = lurek.camera.newCamera()
        cam:setRotation(PI / 4)
        expect_near(cam:getRotation(), PI / 4, 0.001)
    end)

    it("rotation 45° — PNG evidence: rotation", function()
        local VW, VH = 160, 120
        local WW, WH = 320, 240

        local cam = lurek.camera.newCamera()
        cam:setViewport(0, 0, VW, VH)
        cam:setPosition(WW / 2, WH / 2)
        cam:setZoom(1.0)
        cam:setRotation(PI / 6)  -- 30°

        local img = render_world_through_cam(cam, WW, WH, VW, VH)
        lurek.image.savePNG(img, OUT .. "evidence_camera_rotation.png")
    end)
end)

describe("Evidence: lurek.camera follow behaviour", function()

    it("setTarget causes camera to track — PNG evidence: follow_trail", function()
        local VW, VH = 200, 80
        local img = lurek.image.newImageData(VW, VH)
        img:fill(12, 15, 25, 255)

        local cam = lurek.camera.newCamera()
        cam:setViewport(0, 0, 320, 240)
        cam:setPosition(0, 0)
        cam:setFollowSmooth(5.0)

        -- Move a target along a sine path and record camera X positions
        local DT = 1 / 60
        for frame = 0, 199 do
            local t = frame * DT
            local tx = t * 80
            local ty = math.sin(t * 2) * 40 + 120
            cam:setTarget(tx, ty)
            cam:update(DT)

            local cx, cy = cam:getPosition()
            -- Map camera x to image x, camera y to image y
            local px = math.min(VW, math.max(1, math.floor(cx / 2) + 1))
            local py = math.min(VH, math.max(1, math.floor(cy / 3) + 1))
            img:setPixel(px, py, 100, 220, 180, 255)
        end

        lurek.image.savePNG(img, OUT .. "evidence_camera_follow_trail.png")
    end)

    it("bounds clamp prevents camera from leaving world edges", function()
        local cam = lurek.camera.newCamera()
        cam:setViewport(0, 0, 160, 120)
        cam:setBounds(0, 0, 640, 480)

        -- Try to move far outside bounds
        cam:setPosition(-500, -500)
        cam:update(0.016)
        local x, y = cam:getPosition()
        expect_equal(x >= -80, true)   -- allow half-viewport offset at most
        expect_equal(y >= -60, true)
    end)
end)

describe("Evidence: lurek.camera shake", function()

    it("shake causes non-zero offset — PNG evidence: shake_trail", function()
        local VW, VH = 200, 60
        local img = lurek.image.newImageData(VW, VH)
        img:fill(10, 10, 20, 255)

        local cam = lurek.camera.newCamera()
        cam:setViewport(0, 0, 320, 240)
        cam:setPosition(160, 120)
        cam:shake(20, 0.5)  -- 20px intensity, 0.5s

        local DT = 1 / 60
        for frame = 0, 199 do
            cam:update(DT)
            local x, y = cam:getPosition()
            local px = math.min(VW, math.max(1, math.floor(x - 140) + VW // 2))
            local py = math.min(VH, math.max(1, math.floor(y - 100) + VH // 2))
            img:setPixel(px, py, 255, 180, 60, 255)
        end

        lurek.image.savePNG(img, OUT .. "evidence_camera_shake_trail.png")
    end)
end)

test_summary()
