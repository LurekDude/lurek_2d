-- Lurek2D Lua BDD tests for lurek.tween
-- Headless: no GPU, no audio, no window.
-- Tests property tweening: table field animation, sequences, parallels, callbacks.

describe("lurek.tween", function()
    describe("module interface", function()
        it("exposes tween factory", function()
            expect_type("function", lurek.tween.tween)
        end)

        it("exposes sequence factory", function()
            expect_type("function", lurek.tween.sequence)
        end)

        it("exposes parallel factory", function()
            expect_type("function", lurek.tween.parallel)
        end)

        it("exposes delay factory", function()
            expect_type("function", lurek.tween.delay)
        end)

        it("exposes update", function()
            expect_type("function", lurek.tween.update)
        end)

        it("exposes cancelAll", function()
            expect_type("function", lurek.tween.cancelAll)
        end)

        it("exposes getActiveCount", function()
            expect_type("function", lurek.tween.getActiveCount)
        end)

        it("exposes registerEasing", function()
            expect_type("function", lurek.tween.registerEasing)
        end)

        it("exposes getEasingNames", function()
            expect_type("function", lurek.tween.getEasingNames)
        end)
    end)

    describe("tween()", function()
        it("returns a userdata handle", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            expect_type("userdata", t)
        end)

        it("isActive returns true after creation", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            expect_equal(true, t:isActive())
        end)

        it("interpolates single field to midpoint", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            lurek.tween.tween(2.0, obj, { x = 100 }, "linear")
            lurek.tween.update(1.0)
            expect_near(50.0, obj.x, 1.0)
        end)

        it("interpolates multiple fields simultaneously", function()
            lurek.tween.cancelAll()
            local obj = { x = 0, y = 0 }
            lurek.tween.tween(2.0, obj, { x = 100, y = 200 }, "linear")
            lurek.tween.update(2.0)
            expect_near(100.0, obj.x, 0.5)
            expect_near(200.0, obj.y, 0.5)
        end)

        it("isActive returns false after completion", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 10 })
            lurek.tween.update(1.5)
            expect_equal(false, t:isActive())
        end)

        it("captures start values lazily from table at first tick", function()
            lurek.tween.cancelAll()
            local obj = { x = 50 }
            lurek.tween.tween(2.0, obj, { x = 150 }, "linear")
            lurek.tween.update(1.0)
            expect_near(100.0, obj.x, 1.0)
        end)

        it("getProgress returns 0 before first update", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(2.0, obj, { x = 100 })
            expect_near(0.0, t:getProgress(), 0.01)
        end)
    end)

    describe("pause and resume", function()
        it("pause stops interpolation", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local t = lurek.tween.tween(2.0, obj, { x = 100 }, "linear")
            lurek.tween.update(0.5)
            local before = obj.x
            t:pause()
            lurek.tween.update(1.0)
            expect_near(before, obj.x, 0.5)
        end)
    end)

    describe("cancel", function()
        it("cancel makes tween inactive", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(2.0, obj, { x = 100 })
            t:cancel()
            expect_equal(false, t:isActive())
        end)

        it("onCancel fires when cancelled", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local fired = false
            local t = lurek.tween.tween(2.0, obj, { x = 100 })
            t:onCancel(function() fired = true end)
            t:cancel()
            expect_equal(true, fired)
        end)
    end)

    describe("callbacks", function()
        it("onComplete fires when tween finishes", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local finished = false
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            t:onComplete(function() finished = true end)
            lurek.tween.update(1.0)
            expect_equal(true, finished)
        end)

        it("onUpdate fires each tick", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local last_t = -1
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            t:onUpdate(function(t_val) last_t = t_val end)
            lurek.tween.update(0.5)
            assert(last_t >= 0.0 and last_t <= 1.5,
                "onUpdate t out of expected range: " .. tostring(last_t))
        end)

        it("onComplete returns tween for chaining", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            local chained = t:onComplete(function() end)
            expect_type("userdata", chained)
        end)
    end)

    describe("repeat and yoyo", function()
        it("setRepeat(1) plays tween twice", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local complete_count = 0
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            t:setRepeat(1)
            t:onComplete(function() complete_count = complete_count + 1 end)
            lurek.tween.update(2.5)
            expect_equal(1, complete_count)
        end)

        it("setYoyo does not error", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            t:setRepeat(2)
            t:setYoyo(true)
            lurek.tween.update(4.0)
        end)
    end)

    describe("cancelAll()", function()
        it("removes all active objects from tracking", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            lurek.tween.tween(5.0, obj, { x = 100 })
            lurek.tween.tween(5.0, obj, { x = 200 })
            lurek.tween.cancelAll()
            expect_equal(0, lurek.tween.getActiveCount())
        end)
    end)

    describe("getActiveCount()", function()
        it("counts tracked tweens", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            lurek.tween.tween(5.0, obj, { x = 100 })
            local count = lurek.tween.getActiveCount()
            assert(count >= 1, "expected count >= 1, got " .. count)
        end)
    end)

    describe("sequence()", function()
        it("returns a userdata", function()
            local seq = lurek.tween.sequence()
            expect_type("userdata", seq)
        end)

        it("isActive returns false before start()", function()
            local seq = lurek.tween.sequence()
            expect_equal(false, seq:isActive())
        end)

        it("start() activates sequence", function()
            local seq = lurek.tween.sequence()
            seq:start()
            expect_equal(true, seq:isActive())
        end)

        it("tween step animates target table", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            lurek.tween.sequence()
                :tween(2.0, obj, { x = 100 }, "linear")
                :start()
            lurek.tween.update(2.0)
            expect_near(100.0, obj.x, 0.5)
        end)

        it("callback steps run in order", function()
            lurek.tween.cancelAll()
            local order = {}
            lurek.tween.sequence()
                :callback(function() order[#order+1] = 1 end)
                :callback(function() order[#order+1] = 2 end)
                :callback(function() order[#order+1] = 3 end)
                :start()
            lurek.tween.update(0.01)
            expect_equal(3, #order)
            expect_equal(1, order[1])
            expect_equal(3, order[3])
        end)

        it("onComplete fires when all steps done", function()
            lurek.tween.cancelAll()
            local done = false
            lurek.tween.sequence()
                :delay(0.5)
                :onComplete(function() done = true end)
                :start()
            lurek.tween.update(1.0)
            expect_equal(true, done)
        end)

        it("delay step pauses execution", function()
            lurek.tween.cancelAll()
            local fired = false
            lurek.tween.sequence()
                :delay(1.0)
                :callback(function() fired = true end)
                :start()
            lurek.tween.update(0.5)
            expect_equal(false, fired)
            lurek.tween.update(0.6)
            expect_equal(true, fired)
        end)

        it("cancel() stops sequence", function()
            local seq = lurek.tween.sequence()
                :delay(10.0)
                :start()
            seq:cancel()
            expect_equal(false, seq:isActive())
        end)
    end)

    describe("parallel()", function()
        it("returns a userdata", function()
            local par = lurek.tween.parallel()
            expect_type("userdata", par)
        end)

        it("animates children simultaneously", function()
            lurek.tween.cancelAll()
            local obj1 = { x = 0 }
            local obj2 = { y = 0 }
            lurek.tween.parallel()
                :tween(2.0, obj1, { x = 100 }, "linear")
                :tween(2.0, obj2, { y = 200 }, "linear")
                :start()
            lurek.tween.update(1.0)
            expect_near(50.0, obj1.x, 2.0)
            expect_near(100.0, obj2.y, 2.0)
        end)

        it("onComplete fires when all entries done", function()
            lurek.tween.cancelAll()
            local done = false
            local obj = { x = 0 }
            lurek.tween.parallel()
                :tween(1.0, obj, { x = 100 })
                :onComplete(function() done = true end)
                :start()
            lurek.tween.update(1.5)
            expect_equal(true, done)
        end)

        it("cancel() stops parallel", function()
            local par = lurek.tween.parallel()
            par:cancel()
            expect_equal(false, par:isActive())
        end)
    end)

    describe("delay()", function()
        it("fires callback after duration", function()
            lurek.tween.cancelAll()
            local fired = false
            lurek.tween.delay(1.0, function() fired = true end)
            lurek.tween.update(0.5)
            expect_equal(false, fired)
            lurek.tween.update(0.6)
            expect_equal(true, fired)
        end)

        it("works without callback", function()
            lurek.tween.cancelAll()
            lurek.tween.delay(0.5)
            lurek.tween.update(1.0)
        end)
    end)

    describe("getEasingNames()", function()
        it("returns a table with entries", function()
            local names = lurek.tween.getEasingNames()
            expect_type("table", names)
            assert(#names > 0, "easing names should not be empty")
        end)

        it("includes linear", function()
            local names = lurek.tween.getEasingNames()
            local found = false
            for _, n in ipairs(names) do
                if n == "linear" then found = true end
            end
            expect_equal(true, found)
        end)
    end)

    describe("registerEasing()", function()
        it("custom easing appears in getEasingNames()", function()
            lurek.tween.registerEasing("myCustomEasing", function(t) return t * t end)
            local names = lurek.tween.getEasingNames()
            local found = false
            for _, n in ipairs(names) do
                if n == "myCustomEasing" then found = true end
            end
            expect_equal(true, found)
        end)
    end)
end)

test_summary()
