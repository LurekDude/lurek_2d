-- Luna2D Lua BDD tests for luna.tween
-- Headless: no GPU, no audio, no window.
-- Tests property tweening: table field animation, sequences, parallels, callbacks.

describe("luna.tween", function()
    describe("module interface", function()
        it("exposes tween factory", function()
            expect_type("function", luna.tween.tween)
        end)

        it("exposes sequence factory", function()
            expect_type("function", luna.tween.sequence)
        end)

        it("exposes parallel factory", function()
            expect_type("function", luna.tween.parallel)
        end)

        it("exposes delay factory", function()
            expect_type("function", luna.tween.delay)
        end)

        it("exposes update", function()
            expect_type("function", luna.tween.update)
        end)

        it("exposes cancelAll", function()
            expect_type("function", luna.tween.cancelAll)
        end)

        it("exposes getActiveCount", function()
            expect_type("function", luna.tween.getActiveCount)
        end)

        it("exposes registerEasing", function()
            expect_type("function", luna.tween.registerEasing)
        end)

        it("exposes getEasingNames", function()
            expect_type("function", luna.tween.getEasingNames)
        end)
    end)

    describe("tween()", function()
        it("returns a userdata handle", function()
            local obj = { x = 0 }
            local t = luna.tween.tween(1.0, obj, { x = 100 })
            expect_type("userdata", t)
        end)

        it("isActive returns true after creation", function()
            local obj = { x = 0 }
            local t = luna.tween.tween(1.0, obj, { x = 100 })
            expect_equal(true, t:isActive())
        end)

        it("interpolates single field to midpoint", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            luna.tween.tween(2.0, obj, { x = 100 }, "linear")
            luna.tween.update(1.0)
            expect_near(50.0, obj.x, 1.0)
        end)

        it("interpolates multiple fields simultaneously", function()
            luna.tween.cancelAll()
            local obj = { x = 0, y = 0 }
            luna.tween.tween(2.0, obj, { x = 100, y = 200 }, "linear")
            luna.tween.update(2.0)
            expect_near(100.0, obj.x, 0.5)
            expect_near(200.0, obj.y, 0.5)
        end)

        it("isActive returns false after completion", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            local t = luna.tween.tween(1.0, obj, { x = 10 })
            luna.tween.update(1.5)
            expect_equal(false, t:isActive())
        end)

        it("captures start values lazily from table at first tick", function()
            luna.tween.cancelAll()
            local obj = { x = 50 }
            luna.tween.tween(2.0, obj, { x = 150 }, "linear")
            luna.tween.update(1.0)
            expect_near(100.0, obj.x, 1.0)
        end)

        it("getProgress returns 0 before first update", function()
            local obj = { x = 0 }
            local t = luna.tween.tween(2.0, obj, { x = 100 })
            expect_near(0.0, t:getProgress(), 0.01)
        end)
    end)

    describe("pause and resume", function()
        it("pause stops interpolation", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            local t = luna.tween.tween(2.0, obj, { x = 100 }, "linear")
            luna.tween.update(0.5)
            local before = obj.x
            t:pause()
            luna.tween.update(1.0)
            expect_near(before, obj.x, 0.5)
        end)
    end)

    describe("cancel", function()
        it("cancel makes tween inactive", function()
            local obj = { x = 0 }
            local t = luna.tween.tween(2.0, obj, { x = 100 })
            t:cancel()
            expect_equal(false, t:isActive())
        end)

        it("onCancel fires when cancelled", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            local fired = false
            local t = luna.tween.tween(2.0, obj, { x = 100 })
            t:onCancel(function() fired = true end)
            t:cancel()
            expect_equal(true, fired)
        end)
    end)

    describe("callbacks", function()
        it("onComplete fires when tween finishes", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            local finished = false
            local t = luna.tween.tween(1.0, obj, { x = 100 })
            t:onComplete(function() finished = true end)
            luna.tween.update(1.0)
            expect_equal(true, finished)
        end)

        it("onUpdate fires each tick", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            local last_t = -1
            local t = luna.tween.tween(1.0, obj, { x = 100 })
            t:onUpdate(function(t_val) last_t = t_val end)
            luna.tween.update(0.5)
            assert(last_t >= 0.0 and last_t <= 1.5,
                "onUpdate t out of expected range: " .. tostring(last_t))
        end)

        it("onComplete returns tween for chaining", function()
            local obj = { x = 0 }
            local t = luna.tween.tween(1.0, obj, { x = 100 })
            local chained = t:onComplete(function() end)
            expect_type("userdata", chained)
        end)
    end)

    describe("repeat and yoyo", function()
        it("setRepeat(1) plays tween twice", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            local complete_count = 0
            local t = luna.tween.tween(1.0, obj, { x = 100 })
            t:setRepeat(1)
            t:onComplete(function() complete_count = complete_count + 1 end)
            luna.tween.update(2.5)
            expect_equal(1, complete_count)
        end)

        it("setYoyo does not error", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            local t = luna.tween.tween(1.0, obj, { x = 100 })
            t:setRepeat(2)
            t:setYoyo(true)
            luna.tween.update(4.0)
        end)
    end)

    describe("cancelAll()", function()
        it("removes all active objects from tracking", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            luna.tween.tween(5.0, obj, { x = 100 })
            luna.tween.tween(5.0, obj, { x = 200 })
            luna.tween.cancelAll()
            expect_equal(0, luna.tween.getActiveCount())
        end)
    end)

    describe("getActiveCount()", function()
        it("counts tracked tweens", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            luna.tween.tween(5.0, obj, { x = 100 })
            local count = luna.tween.getActiveCount()
            assert(count >= 1, "expected count >= 1, got " .. count)
        end)
    end)

    describe("sequence()", function()
        it("returns a userdata", function()
            local seq = luna.tween.sequence()
            expect_type("userdata", seq)
        end)

        it("isActive returns false before start()", function()
            local seq = luna.tween.sequence()
            expect_equal(false, seq:isActive())
        end)

        it("start() activates sequence", function()
            local seq = luna.tween.sequence()
            seq:start()
            expect_equal(true, seq:isActive())
        end)

        it("tween step animates target table", function()
            luna.tween.cancelAll()
            local obj = { x = 0 }
            luna.tween.sequence()
                :tween(2.0, obj, { x = 100 }, "linear")
                :start()
            luna.tween.update(2.0)
            expect_near(100.0, obj.x, 0.5)
        end)

        it("callback steps run in order", function()
            luna.tween.cancelAll()
            local order = {}
            luna.tween.sequence()
                :callback(function() order[#order+1] = 1 end)
                :callback(function() order[#order+1] = 2 end)
                :callback(function() order[#order+1] = 3 end)
                :start()
            luna.tween.update(0.01)
            expect_equal(3, #order)
            expect_equal(1, order[1])
            expect_equal(3, order[3])
        end)

        it("onComplete fires when all steps done", function()
            luna.tween.cancelAll()
            local done = false
            luna.tween.sequence()
                :delay(0.5)
                :onComplete(function() done = true end)
                :start()
            luna.tween.update(1.0)
            expect_equal(true, done)
        end)

        it("delay step pauses execution", function()
            luna.tween.cancelAll()
            local fired = false
            luna.tween.sequence()
                :delay(1.0)
                :callback(function() fired = true end)
                :start()
            luna.tween.update(0.5)
            expect_equal(false, fired)
            luna.tween.update(0.6)
            expect_equal(true, fired)
        end)

        it("cancel() stops sequence", function()
            local seq = luna.tween.sequence()
                :delay(10.0)
                :start()
            seq:cancel()
            expect_equal(false, seq:isActive())
        end)
    end)

    describe("parallel()", function()
        it("returns a userdata", function()
            local par = luna.tween.parallel()
            expect_type("userdata", par)
        end)

        it("animates children simultaneously", function()
            luna.tween.cancelAll()
            local obj1 = { x = 0 }
            local obj2 = { y = 0 }
            luna.tween.parallel()
                :tween(2.0, obj1, { x = 100 }, "linear")
                :tween(2.0, obj2, { y = 200 }, "linear")
                :start()
            luna.tween.update(1.0)
            expect_near(50.0, obj1.x, 2.0)
            expect_near(100.0, obj2.y, 2.0)
        end)

        it("onComplete fires when all entries done", function()
            luna.tween.cancelAll()
            local done = false
            local obj = { x = 0 }
            luna.tween.parallel()
                :tween(1.0, obj, { x = 100 })
                :onComplete(function() done = true end)
                :start()
            luna.tween.update(1.5)
            expect_equal(true, done)
        end)

        it("cancel() stops parallel", function()
            local par = luna.tween.parallel()
            par:cancel()
            expect_equal(false, par:isActive())
        end)
    end)

    describe("delay()", function()
        it("fires callback after duration", function()
            luna.tween.cancelAll()
            local fired = false
            luna.tween.delay(1.0, function() fired = true end)
            luna.tween.update(0.5)
            expect_equal(false, fired)
            luna.tween.update(0.6)
            expect_equal(true, fired)
        end)

        it("works without callback", function()
            luna.tween.cancelAll()
            luna.tween.delay(0.5)
            luna.tween.update(1.0)
        end)
    end)

    describe("getEasingNames()", function()
        it("returns a table with entries", function()
            local names = luna.tween.getEasingNames()
            expect_type("table", names)
            assert(#names > 0, "easing names should not be empty")
        end)

        it("includes linear", function()
            local names = luna.tween.getEasingNames()
            local found = false
            for _, n in ipairs(names) do
                if n == "linear" then found = true end
            end
            expect_equal(true, found)
        end)
    end)

    describe("registerEasing()", function()
        it("custom easing appears in getEasingNames()", function()
            luna.tween.registerEasing("myCustomEasing", function(t) return t * t end)
            local names = luna.tween.getEasingNames()
            local found = false
            for _, n in ipairs(names) do
                if n == "myCustomEasing" then found = true end
            end
            expect_equal(true, found)
        end)
    end)
end)

test_summary()
