-- Lurek2D Stress Test: Camera Transform Throughput
-- Measures camera position, zoom, and rotation update performance.
-- @stress lurek.camera.newCamera

describe("stress: camera position updates", function()
    it("100000 camera setPosition calls in <5s", function()
        local cam   = lurek.camera.newCamera()
        local COUNT = 100000

        local elapsed = measure("camera:setPosition x" .. COUNT, COUNT, function()
            cam:setPosition(math.random() * 1920, math.random() * 1080)
        end)

        expect_true(elapsed < 5.0, "camera position budget: " .. elapsed .. "s")
    end)

    it("100000 camera zoom updates in <5s", function()
        local cam   = lurek.camera.newCamera()
        local COUNT = 100000

        local elapsed = measure("camera:setZoom x" .. COUNT, COUNT, function()
            cam:setZoom(0.5 + math.random())
        end)

        expect_true(elapsed < 5.0, "camera zoom budget: " .. elapsed .. "s")
    end)

    it("100 cameras × 1000 updates each in <5s", function()
        local CAMS    = 100
        local UPDATES = 1000
        local cams    = {}

        for _ = 1, CAMS do
            cams[#cams + 1] = lurek.camera.newCamera()
        end

        local start = os.clock()
        for _ = 1, UPDATES do
            for _, cam in ipairs(cams) do
                cam:setPosition(math.random() * 1920, math.random() * 1080)
                cam:setZoom(0.5 + math.random())
            end
        end
        local elapsed = os.clock() - start
        print(string.format("[STRESS] 100 cameras × 1000 updates: %.4fs (%.0f updates/sec)",
            elapsed, (CAMS * UPDATES) / elapsed))

        expect_true(elapsed < 5.0, "multi-camera budget: " .. elapsed .. "s")
    end)
end)

test_summary()
