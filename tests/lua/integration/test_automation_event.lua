-- Integration: automation script replay + event queue

local automation = lurek.automation

describe("automation + event integration", function()
    -- @integration lurek.automation.load
    -- @integration lurek.automation.start
    -- @integration lurek.automation.stop
    -- @integration lurek.automation.unload
    -- @integration lurek.automation.update
    -- @integration lurek.event.clear
    -- @integration lurek.event.wait
    it("dispatches queued key events with expected payload", function()
        lurek.event.clear()
        lurek.automation.load("evt_payload", {
            steps = {
                { action = "keypress", key = "a", scancode = "KeyA", isRepeat = true, time = 0.0 },
                { action = "keyrelease", key = "a", scancode = "KeyA", time = 0.01 },
            }
        })

        lurek.automation.start("evt_payload")
        lurek.automation.update(0.02)

        local ok1, name1, args1 = lurek.event.wait(0)
        expect_equal(ok1, true)
        expect_equal(name1, "keypressed")
        expect_equal(args1[1], "a")
        expect_equal(args1[2], "KeyA")
        expect_equal(args1[3], true)

        local ok2, name2, args2 = lurek.event.wait(0)
        expect_equal(ok2, true)
        expect_equal(name2, "keyreleased")
        expect_equal(args2[1], "a")
        expect_equal(args2[2], "KeyA")

        lurek.automation.stop()
        lurek.automation.unload("evt_payload")
        lurek.event.clear()
    end)

    -- @integration lurek.automation.load
    -- @integration lurek.automation.start
    -- @integration lurek.automation.stop
    -- @integration lurek.automation.unload
    -- @integration lurek.automation.update
    -- @integration lurek.event.clear
    -- @integration lurek.event.wait
    it("defaults keypress scancode to key and repeat to false", function()
        lurek.event.clear()
        lurek.automation.load("key_defaults", {
            steps = {
                { action = "keypress", key = "a", time = 0.0 },
            }
        })
        lurek.automation.start("key_defaults")
        lurek.automation.update(0.01)

        local ok, name, args = lurek.event.wait(0)
        expect_equal(ok, true)
        expect_equal(name, "keypressed")
        expect_equal(args[1], "a")
        expect_equal(args[2], "a")
        expect_equal(args[3], false)

        lurek.automation.stop()
        lurek.automation.unload("key_defaults")
        lurek.event.clear()
    end)

    -- @integration lurek.automation.load
    -- @integration lurek.automation.start
    -- @integration lurek.automation.stop
    -- @integration lurek.automation.unload
    -- @integration lurek.automation.update
    -- @integration lurek.event.clear
    -- @integration lurek.event.wait
    it("prefers explicit scancode in queued keypress events", function()
        lurek.event.clear()
        lurek.automation.load("key_scancode", {
            steps = {
                { action = "keypress", key = "a", scancode = "KeyA", time = 0.0 },
            }
        })
        lurek.automation.start("key_scancode")
        lurek.automation.update(0.01)

        local ok, name, args = lurek.event.wait(0)
        expect_equal(ok, true)
        expect_equal(name, "keypressed")
        expect_equal(args[1], "a")
        expect_equal(args[2], "KeyA")
        expect_equal(args[3], false)

        lurek.automation.stop()
        lurek.automation.unload("key_scancode")
        lurek.event.clear()
    end)

    -- @integration lurek.automation.isFailed
    -- @integration lurek.automation.load
    -- @integration lurek.automation.start
    -- @integration lurek.automation.stop
    -- @integration lurek.automation.unload
    -- @integration lurek.automation.update
    -- @integration lurek.image.newImageData
    -- @integration lurek.image.savePNG
    it("passes visualassert action on identical images", function()
        local img = lurek.image.newImageData(2, 2)
        img:setPixel(0, 0, 255, 0, 0, 255)
        img:setPixel(1, 0, 255, 0, 0, 255)
        img:setPixel(0, 1, 255, 0, 0, 255)
        img:setPixel(1, 1, 255, 0, 0, 255)

        lurek.image.savePNG(img, "save/automation/base.png")
        lurek.image.savePNG(img, "save/automation/actual.png")

        lurek.automation.load("visual_ok", {
            steps = {
                {
                    action = "visualassert",
                    baseline = "save/automation/base.png",
                    actual = "save/automation/actual.png",
                    maxDiff = 0,
                    time = 0.0,
                },
            }
        })

        automation.start("visual_ok")
        automation.update(0.01)
        expect_equal(automation.isFailed(), false)

        automation.stop()
        automation.unload("visual_ok")
    end)
end)

test_summary()

