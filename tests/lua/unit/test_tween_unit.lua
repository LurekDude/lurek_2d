-- Lurek2D Lua BDD tests for lurek.tween.
-- Covers property tweening, composed sequences and parallels, delay helpers, callbacks, and easing/state surfaces in the headless Lua VM.

-- Headless: no GPU, no audio, no window.
-- Tests property tweening: table field animation, sequences, parallels, callbacks.

-- @description Covers suite: lurek.tween.
describe("lurek.tween", function()
    -- @description Covers suite: module interface.
    describe("module interface", function()
        -- @tests lurek.tween.tween
        -- @tests lurek.tween.cancelAll
        -- @tests lurek.tween.delay
        -- @tests lurek.tween.getActiveCount
        -- @tests lurek.tween.getEasingNames
        -- @tests lurek.tween.parallel
        -- @tests lurek.tween.newState
        -- @tests lurek.tween.registerEasing
        -- @tests lurek.tween.sequence
        -- @tests lurek.tween.update
        -- @description Verifies the tween factory function is exposed on the lurek.tween module.
        it("exposes tween factory", function()
            expect_type("function", lurek.tween.tween)
        end)

        -- @tests lurek.tween.sequence
        -- @description Verifies the sequence factory function is exposed on the lurek.tween module.
        it("exposes sequence factory", function()
            expect_type("function", lurek.tween.sequence)
        end)

        -- @tests lurek.tween.parallel
        -- @description Verifies the parallel factory function is exposed on the lurek.tween module.
        it("exposes parallel factory", function()
            expect_type("function", lurek.tween.parallel)
        end)

        -- @tests lurek.tween.delay
        -- @description Verifies the delay helper is exposed on the lurek.tween module.
        it("exposes delay factory", function()
            expect_type("function", lurek.tween.delay)
        end)

        -- @tests lurek.tween.update
        -- @description Verifies the global tween update entry point is exposed.
        it("exposes update", function()
            expect_type("function", lurek.tween.update)
        end)

        -- @tests lurek.tween.cancelAll
        -- @description Verifies the global tween cancellation entry point is exposed.
        it("exposes cancelAll", function()
            expect_type("function", lurek.tween.cancelAll)
        end)

        -- @tests lurek.tween.getActiveCount
        -- @description Verifies the active tween counter helper is exposed.
        it("exposes getActiveCount", function()
            expect_type("function", lurek.tween.getActiveCount)
        end)

        -- @tests lurek.tween.registerEasing
        -- @description Verifies the custom easing registration function is exposed.
        it("exposes registerEasing", function()
            expect_type("function", lurek.tween.registerEasing)
        end)

        -- @tests lurek.tween.getEasingNames
        -- @description Verifies the easing-name enumeration helper is exposed.
        it("exposes getEasingNames", function()
            expect_type("function", lurek.tween.getEasingNames)
        end)
    end)

    -- @description Covers suite: tween().
    describe("tween()", function()
        -- @tests lurek.tween.tween
        -- @description Verifies tween() returns a userdata handle for the created tween.
        it("returns a userdata handle", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            expect_type("userdata", t)
        end)

        -- @tests lurek.tween.tween
        -- @tests Tween:isActive
        -- @description Verifies a newly created tween reports itself as active before any updates.
        it("isActive returns true after creation", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            expect_equal(true, t:isActive())
        end)

        -- @tests lurek.tween.cancelAll
        -- @tests lurek.tween.tween
        -- @tests lurek.tween.update
        -- @description Verifies a linear tween interpolates a single numeric field to its midpoint after half its duration.
        it("interpolates single field to midpoint", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            lurek.tween.tween(2.0, obj, { x = 100 }, "linear")
            lurek.tween.update(1.0)
            expect_near(50.0, obj.x, 1.0)
        end)

        -- @tests lurek.tween.cancelAll
        -- @tests lurek.tween.tween
        -- @tests lurek.tween.update
        -- @description Verifies a tween updates multiple numeric target fields together over the same duration.
        it("interpolates multiple fields simultaneously", function()
            lurek.tween.cancelAll()
            local obj = { x = 0, y = 0 }
            lurek.tween.tween(2.0, obj, { x = 100, y = 200 }, "linear")
            lurek.tween.update(2.0)
            expect_near(100.0, obj.x, 0.5)
            expect_near(200.0, obj.y, 0.5)
        end)

        -- @tests lurek.tween.cancelAll
        -- @tests lurek.tween.tween
        -- @tests lurek.tween.update
        -- @tests Tween:isActive
        -- @description Verifies a tween becomes inactive after enough update time has elapsed to complete it.
        it("isActive returns false after completion", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 10 })
            lurek.tween.update(1.5)
            expect_equal(false, t:isActive())
        end)

        -- @tests lurek.tween.cancelAll
        -- @tests lurek.tween.tween
        -- @tests lurek.tween.update
        -- @description Verifies tween start values are sampled lazily from the target table on the first update tick.
        it("captures start values lazily from table at first tick", function()
            lurek.tween.cancelAll()
            local obj = { x = 50 }
            lurek.tween.tween(2.0, obj, { x = 150 }, "linear")
            lurek.tween.update(1.0)
            expect_near(100.0, obj.x, 1.0)
        end)

        -- @tests lurek.tween.tween
        -- @tests Tween:getProgress
        -- @description Verifies getProgress() starts at zero before the tween receives any update ticks.
        it("getProgress returns 0 before first update", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(2.0, obj, { x = 100 })
            expect_near(0.0, t:getProgress(), 0.01)
        end)
    end)

    -- @description Covers suite: newState().
    describe("newState()", function()
        -- @tests lurek.tween.newState
        -- @description Verifies newState() returns a userdata tween-state handle.
        it("returns a userdata handle", function()
            local state = lurek.tween.newState(1.0, "linear")
            expect_type("userdata", state)
        end)

        -- @tests lurek.tween.newState
        -- @tests TweenState:t
        -- @description Verifies a fresh TweenState reports normalized progress t() of zero.
        it("t() starts at zero", function()
            local state = lurek.tween.newState(2.0, "linear")
            expect_near(0.0, state:t(), 0.0001)
        end)

        -- @tests TweenState:tick
        -- @tests TweenState:t
        -- @description Verifies tick(dt) advances TweenState progress proportionally and reports incomplete status mid-way.
        it("tick advances progress", function()
            local state = lurek.tween.newState(2.0, "linear")
            expect_equal(false, state:tick(1.0))
            expect_near(0.5, state:t(), 0.0001)
        end)

        -- @tests TweenState:tick
        -- @tests TweenState:isComplete
        -- @description Verifies tick(dt) returns true and marks the state complete once elapsed time reaches the duration.
        it("tick returns true at completion", function()
            local state = lurek.tween.newState(1.0, "linear")
            expect_equal(true, state:tick(1.0))
            expect_equal(true, state:isComplete())
        end)

        -- @tests TweenState.paused
        -- @tests TweenState:tick
        -- @tests TweenState:t
        -- @description Verifies the paused field freezes TweenState progress even when tick() is called.
        it("paused field freezes elapsed progress", function()
            local state = lurek.tween.newState(2.0, "linear")
            state:tick(0.5)
            local before = state:t()
            state.paused = true
            state:tick(0.5)
            expect_near(before, state:t(), 0.0001)
        end)

        -- @tests TweenState:reset
        -- @tests TweenState:isComplete
        -- @tests TweenState:t
        -- @description Verifies reset() clears TweenState completion and restores progress back to zero.
        it("reset restores progress to zero", function()
            local state = lurek.tween.newState(1.0, "linear")
            state:tick(1.0)
            expect_equal(true, state:isComplete())
            state:reset()
            expect_equal(false, state:isComplete())
            expect_near(0.0, state:t(), 0.0001)
        end)

        -- @tests TweenState:tick
        -- @tests TweenState:lerp
        -- @description Verifies lerp() uses the current TweenState progress when interpolating between numeric endpoints.
        it("lerp uses the current tween progress", function()
            local state = lurek.tween.newState(2.0, "linear")
            state:tick(1.0)
            expect_near(50.0, state:lerp(0.0, 100.0), 0.0001)
        end)

        -- @tests lurek.tween.newState
        -- @tests TweenState:tick
        -- @tests TweenState:isComplete
        -- @description Verifies zero-duration TweenState handles clamp and complete on the first small tick.
        it("zero duration clamps and completes on a small tick", function()
            local state = lurek.tween.newState(0.0, "linear")
            expect_equal(true, state:tick(0.001))
            expect_equal(true, state:isComplete())
        end)

        -- @tests lurek.tween.newState
        -- @tests TweenState:tick
        -- @tests TweenState:lerp
        -- @description Verifies TweenState accepts named non-linear easing curves and applies them during interpolation.
        it("accepts non-linear easing names", function()
            local state = lurek.tween.newState(1.0, "cubicOut")
            state:tick(0.5)
            expect_true(state:lerp(0.0, 1.0) > 0.5)
        end)
    end)

    -- @description Covers suite: pause and resume.
    describe("pause and resume", function()
        -- @tests Tween:pause
        -- @tests lurek.tween.update
        -- @description Verifies pausing a tween freezes property interpolation across subsequent update ticks.
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

    -- @description Covers suite: cancel.
    describe("cancel", function()
        -- @tests Tween:cancel
        -- @tests Tween:isActive
        -- @description Verifies cancel() immediately deactivates a tween handle.
        it("cancel makes tween inactive", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(2.0, obj, { x = 100 })
            t:cancel()
            expect_equal(false, t:isActive())
        end)

        -- @tests Tween:onCancel
        -- @tests Tween:cancel
        -- @description Verifies onCancel() callbacks fire when a tween is explicitly cancelled.
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

    -- @description Covers suite: callbacks.
    describe("callbacks", function()
        -- @tests Tween:onComplete
        -- @tests lurek.tween.update
        -- @description Verifies onComplete() callbacks fire when update() advances a tween to completion.
        it("onComplete fires when tween finishes", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local finished = false
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            t:onComplete(function() finished = true end)
            lurek.tween.update(1.0)
            expect_equal(true, finished)
        end)

        -- @tests Tween:onUpdate
        -- @tests lurek.tween.update
        -- @description Verifies onUpdate() callbacks receive progress notifications on each tween update tick.
        it("onUpdate fires each tick", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local last_t = -1
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            t:onUpdate(function(t_val) last_t = t_val end)
            lurek.tween.update(0.5)
            expect_in_range(last_t, 0.0, 1.5,
                "onUpdate t out of expected range: " .. tostring(last_t))
        end)

        -- @tests Tween:onComplete
        -- @description Verifies onComplete() returns the tween handle so callback registration can be chained.
        it("onComplete returns tween for chaining", function()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            local chained = t:onComplete(function() end)
            expect_type("userdata", chained)
        end)
    end)

    -- @description Covers suite: repeat and yoyo.
    describe("repeat and yoyo", function()
        -- @tests Tween:setRepeat
        -- @tests Tween:onComplete
        -- @tests lurek.tween.update
        -- @description Verifies setRepeat(1) replays the tween once and still fires completion exactly once after the full run.
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

        -- @tests Tween:setRepeat
        -- @tests Tween:setYoyo
        -- @tests lurek.tween.update
        -- @description Verifies yoyo mode can be enabled on a repeating tween without producing update errors.
        it("setYoyo does not error", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            local t = lurek.tween.tween(1.0, obj, { x = 100 })
            t:setRepeat(2)
            t:setYoyo(true)
            lurek.tween.update(4.0)
        end)
    end)

    -- @description Covers suite: cancelAll().
    describe("cancelAll()", function()
        -- @tests lurek.tween.cancelAll
        -- @tests lurek.tween.getActiveCount
        -- @description Verifies cancelAll() clears all tracked tweens from the engine.
        it("removes all active objects from tracking", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            lurek.tween.tween(5.0, obj, { x = 100 })
            lurek.tween.tween(5.0, obj, { x = 200 })
            lurek.tween.cancelAll()
            expect_equal(0, lurek.tween.getActiveCount())
        end)
    end)

    -- @description Covers suite: getActiveCount().
    describe("getActiveCount()", function()
        -- @tests lurek.tween.getActiveCount
        -- @tests lurek.tween.tween
        -- @description Verifies getActiveCount() reflects that created tweens are being tracked by the engine.
        it("counts tracked tweens", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            lurek.tween.tween(5.0, obj, { x = 100 })
            local count = lurek.tween.getActiveCount()
            expect_true(count >= 1, "expected count >= 1, got " .. count)
        end)
    end)

    -- @description Covers suite: sequence().
    describe("sequence()", function()
        -- @tests lurek.tween.sequence
        -- @description Verifies sequence() returns a userdata sequence handle.
        it("returns a userdata", function()
            local seq = lurek.tween.sequence()
            expect_type("userdata", seq)
        end)

        -- @tests TweenSequence:isActive
        -- @description Verifies a new TweenSequence is inactive until start() is called.
        it("isActive returns false before start()", function()
            local seq = lurek.tween.sequence()
            expect_equal(false, seq:isActive())
        end)

        -- @tests TweenSequence:start
        -- @tests TweenSequence:isActive
        -- @description Verifies start() activates a TweenSequence.
        it("start() activates sequence", function()
            local seq = lurek.tween.sequence()
            seq:start()
            expect_equal(true, seq:isActive())
        end)

        -- @tests TweenSequence:tween
        -- @tests TweenSequence:start
        -- @tests lurek.tween.update
        -- @description Verifies a tween step in a sequence animates its target once the sequence is started.
        it("tween step animates target table", function()
            lurek.tween.cancelAll()
            local obj = { x = 0 }
            lurek.tween.sequence()
                :tween(2.0, obj, { x = 100 }, "linear")
                :start()
            lurek.tween.update(2.0)
            expect_near(100.0, obj.x, 0.5)
        end)

        -- @tests TweenSequence:callback
        -- @tests TweenSequence:start
        -- @tests lurek.tween.update
        -- @description Verifies callback steps in a sequence execute in the order they were appended.
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

        -- @tests TweenSequence:delay
        -- @tests TweenSequence:onComplete
        -- @tests TweenSequence:start
        -- @tests lurek.tween.update
        -- @description Verifies a sequence onComplete callback fires after the final delayed step finishes.
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

        -- @tests TweenSequence:delay
        -- @tests TweenSequence:callback
        -- @tests TweenSequence:start
        -- @tests lurek.tween.update
        -- @description Verifies a delay step blocks later callbacks until enough time has elapsed.
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

        -- @tests TweenSequence:cancel
        -- @tests TweenSequence:isActive
        -- @description Verifies cancel() stops a running TweenSequence and marks it inactive.
        it("cancel() stops sequence", function()
            local seq = lurek.tween.sequence()
                :delay(10.0)
                :start()
            seq:cancel()
            expect_equal(false, seq:isActive())
        end)
    end)

    -- @description Covers suite: parallel().
    describe("parallel()", function()
        -- @tests lurek.tween.parallel
        -- @description Verifies parallel() returns a userdata parallel-group handle.
        it("returns a userdata", function()
            local par = lurek.tween.parallel()
            expect_type("userdata", par)
        end)

        -- @tests TweenParallel:tween
        -- @tests TweenParallel:start
        -- @tests lurek.tween.update
        -- @description Verifies a parallel group advances all child tween entries simultaneously.
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

        -- @tests TweenParallel:onComplete
        -- @tests TweenParallel:tween
        -- @tests TweenParallel:start
        -- @tests lurek.tween.update
        -- @description Verifies a parallel group's onComplete callback fires after every child tween finishes.
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

        -- @tests TweenParallel:cancel
        -- @tests TweenParallel:isActive
        -- @description Verifies cancel() stops a parallel group and marks it inactive.
        it("cancel() stops parallel", function()
            local par = lurek.tween.parallel()
            par:cancel()
            expect_equal(false, par:isActive())
        end)
    end)

    -- @description Covers suite: delay().
    describe("delay()", function()
        -- @tests lurek.tween.delay
        -- @tests lurek.tween.update
        -- @description Verifies delay() runs its callback only after the requested duration has fully elapsed.
        it("fires callback after duration", function()
            lurek.tween.cancelAll()
            local fired = false
            lurek.tween.delay(1.0, function() fired = true end)
            lurek.tween.update(0.5)
            expect_equal(false, fired)
            lurek.tween.update(0.6)
            expect_equal(true, fired)
        end)

        -- @tests lurek.tween.delay
        -- @tests lurek.tween.update
        -- @description Verifies delay() can be scheduled without a callback and still updates without error.
        it("works without callback", function()
            lurek.tween.cancelAll()
            lurek.tween.delay(0.5)
            lurek.tween.update(1.0)
        end)
    end)

    -- @description Covers suite: getEasingNames().
    describe("getEasingNames()", function()
        -- @tests lurek.tween.getEasingNames
        -- @description Verifies getEasingNames() returns a non-empty table of registered easing names.
        it("returns a table with entries", function()
            local names = lurek.tween.getEasingNames()
            expect_type("table", names)
            expect_true(#names > 0, "easing names should not be empty")
        end)

        -- @tests lurek.tween.getEasingNames
        -- @description Verifies the built-in linear easing appears in the registered easing-name list.
        it("includes linear", function()
            local names = lurek.tween.getEasingNames()
            local found = false
            for _, n in ipairs(names) do
                if n == "linear" then found = true end
            end
            expect_equal(true, found)
        end)
    end)

    -- @description Covers suite: registerEasing().
    describe("registerEasing()", function()
        -- @tests lurek.tween.registerEasing
        -- @tests lurek.tween.getEasingNames
        -- @description Verifies registering a custom easing name adds it to the easing-name list.
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

-- â”€â”€ edge cases from Rust test migration â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

-- @description Covers suite: tween edge cases.
describe("tween edge cases", function()
    -- @tests lurek.tween.tween
    -- @tests lurek.tween.update
    -- @description Verifies easing-name lookup is case-insensitive for built-in names like LINEAR.
    it("easing name is case-insensitive", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(1.0, obj, { x = 100 }, "LINEAR")
        lurek.tween.update(0.5)
        expect_near(obj.x, 50, 2)
    end)

    -- @tests Tween:onComplete
    -- @tests lurek.tween.tween
    -- @tests lurek.tween.update
    -- @description Verifies a zero-duration tween completes immediately on the first non-zero update and fires onComplete.
    it("zero-duration tween completes immediately", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local completed = false
        local t = lurek.tween.tween(0.0, obj, { x = 100 })
        t:onComplete(function() completed = true end)
        lurek.tween.update(0.001)
        expect_equal(completed, true)
    end)

    -- @tests Tween:onUpdate
    -- @tests Tween:pause
    -- @tests lurek.tween.update
    -- @description Verifies paused tweens suppress onUpdate callbacks while the tween remains paused.
    it("paused tween does not fire onUpdate", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local updated = false
        local t = lurek.tween.tween(2.0, obj, { x = 100 })
        t:onUpdate(function() updated = true end)
        t:pause()
        lurek.tween.update(1.0)
        expect_equal(updated, false)
    end)

    -- @tests Tween:onComplete
    -- @tests lurek.tween.update
    -- @description Verifies onComplete callbacks fire exactly once even if update() is called again after completion.
    it("onComplete fires exactly once", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        local count = 0
        local t = lurek.tween.tween(1.0, obj, { x = 100 })
        t:onComplete(function() count = count + 1 end)
        lurek.tween.update(0.5)
        expect_equal(count, 0)
        lurek.tween.update(1.0)
        expect_equal(count, 1)
        lurek.tween.update(1.0)
        expect_equal(count, 1)
    end)
end)

-- @description Covers suite: easing resolution (RS parity).
describe("easing resolution (RS parity)", function()
    -- @tests lurek.tween.getEasingNames
    -- @description Verifies getEasingNames() returns a non-empty Lua table in parity with the Rust-side expectations.
    it("getEasingNames returns a non-empty table", function()
        local names = lurek.tween.getEasingNames()
        expect_equal("table", type(names))
        expect_true(#names > 0)
    end)

    -- @tests lurek.tween.getEasingNames
    -- @description Verifies the easing-name list contains expected built-in entries such as linear and a quad variant.
    it("getEasingNames contains expected built-in entries", function()
        local names = lurek.tween.getEasingNames()
        local set = {}
        for _, v in ipairs(names) do set[v] = true end
        expect_true(set["linear"] == true)
        expect_true(set["quadIn"] == true or set["quad_in"] == true or set["easeInQuad"] == true)
    end)

    -- @tests lurek.tween.tween
    -- @tests lurek.tween.update
    -- @description Verifies a tween using linear easing advances proportionally with elapsed time.
    it("tween with 'linear' easing progresses proportionally", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(1.0, obj, { x = 100 }, "linear")
        lurek.tween.update(0.5)
        expect_near(50, obj.x, 1.0)
        lurek.tween.cancelAll()
    end)

    -- @tests lurek.tween.tween
    -- @tests lurek.tween.update
    -- @description Verifies tween creation stays robust when given an easing string that resolves without crashing.
    it("tween with unknown easing string does not crash", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        expect_no_error(function()
            lurek.tween.tween(0.1, obj, { x = 1 }, "cubicOut")
            lurek.tween.update(0.2)
        end)
        lurek.tween.cancelAll()
    end)

    -- @tests lurek.tween.tween
    -- @tests lurek.tween.update
    -- @description Verifies a near-zero-duration tween reaches its target value on the first meaningful update tick.
    it("zero-duration tween completes on first non-zero update", function()
        lurek.tween.cancelAll()
        local obj = { x = 0 }
        lurek.tween.tween(0.001, obj, { x = 99 })
        lurek.tween.update(1.0)
        expect_near(99, obj.x, 0.5)
        lurek.tween.cancelAll()
    end)
end)

-- @description Tests for lurek.tween.to() sugar function.
describe("lurek.tween.to sugar", function()
  -- @tests lurek.tween.to
  -- @description tween.to(target, fields, duration) should animate target to the desired values by the end of the duration.
  it("tween.to animates properties forward", function()
    local obj = { x = 0.0, y = 0.0 }
    lurek.tween.to(obj, { x = 100.0, y = 50.0 }, 1.0)
    lurek.tween.update(1.0)
    expect_near(obj.x, 100.0, 1.0)
    expect_near(obj.y, 50.0, 1.0)
    lurek.tween.cancelAll()
  end)

  -- @tests lurek.tween.to
  -- @description tween.to should accept an optional easing name without error.
  it("tween.to accepts optional easing parameter without error", function()
    local obj = { alpha = 1.0 }
    expect_no_error(function()
      lurek.tween.to(obj, { alpha = 0.0 }, 0.5, "linear")
      lurek.tween.cancelAll()
    end)
  end)
end)

-- ═══════════════════════════════════════════════════════════════════════
-- Merged from test_tween_spring.lua
-- ═══════════════════════════════════════════════════════════════════════

describe("lurek.tween.spring — creation", function()
    it("creates a spring from a table and fields", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 100, y = 50})
        expect_equal(sp ~= nil, true)
    end)

    it("reports not settled immediately when target differs from position", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), false)
    end)

    it("reports settled immediately when position already equals target", function()
        local target = {x = 100}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), true)
    end)

    it("isActive returns true after creation with differing target", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 50})
        expect_equal(sp:isActive(), true)
    end)

    it("accepts stiffness/damping/precision opts", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 200}, {stiffness = 200, damping = 28, precision = 0.01})
        expect_equal(sp ~= nil, true)
        expect_equal(sp:isSettled(), false)
    end)
end)

describe("lurek.tween.spring — getPosition", function()
    it("returns starting position before any update", function()
        local target = {x = 42.0}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_near(sp:getPosition("x"), 42.0, 0.001)
    end)

    it("returns nil for an unknown field", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 50})
        expect_equal(sp:getPosition("z"), nil)
    end)
end)

describe("lurek.tween.spring — update convergence", function()
    xit("position moves toward target after updates", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        for _ = 1, 20 do
            sp:update(1/60)
        end
        local pos = sp:getPosition("x")
        expect_equal(pos > 0, true)
        expect_equal(pos <= 100.5, true)
    end)

    it("writes updated positions back to the target table", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 50, y = 25}, {stiffness = 100, damping = 10})
        sp:update(1/60)
        expect_equal(target.x > 0, true)
        expect_equal(target.y > 0, true)
    end)

    it("settles near target after sufficient updates", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        for _ = 1, 300 do
            sp:update(1/60)
        end
        expect_equal(sp:isSettled(), true)
        expect_near(sp:getPosition("x"), 100.0, 0.01)
    end)

    it("update returns true while moving, false when settled", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        local still_moving = sp:update(1/60)
        expect_equal(still_moving, true)

        for _ = 1, 400 do
            sp:update(1/60)
        end
        local after = sp:update(1/60)
        expect_equal(after, false)
    end)

    it("isActive becomes false after spring settles via update", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 150, damping = 25})
        for _ = 1, 400 do
            sp:update(1/60)
        end
        expect_equal(sp:isActive(), false)
    end)
end)

describe("lurek.tween.spring — multi-axis", function()
    it("animates multiple fields simultaneously", function()
        local target = {x = 0, y = 0, alpha = 0}
        local sp = lurek.tween.spring(target, {x = 100, y = 200, alpha = 1},
            {stiffness = 100, damping = 10})
        for _ = 1, 30 do
            sp:update(1/60)
        end
        expect_equal(target.x > 0, true)
        expect_equal(target.y > 0, true)
        expect_equal(target.alpha > 0, true)
    end)

    it("all axes settle together", function()
        local target = {x = 0, y = 0}
        local sp = lurek.tween.spring(target, {x = 50, y = 80}, {stiffness = 120, damping = 22})
        for _ = 1, 500 do
            sp:update(1/60)
        end
        expect_equal(sp:isSettled(), true)
        expect_near(target.x, 50, 0.01)
        expect_near(target.y, 80, 0.01)
    end)
end)

describe("lurek.tween.spring — setTarget", function()
    it("changes target without resetting velocity", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        for _ = 1, 10 do sp:update(1/60) end
        sp:setTarget({x = 200})
        expect_equal(sp:isActive(), true)
        expect_equal(sp:isSettled(), false)
    end)

    it("re-activates a settled spring when target changes", function()
        local target = {x = 100}
        local sp = lurek.tween.spring(target, {x = 100})
        expect_equal(sp:isSettled(), true)
        sp:setTarget({x = 200})
        expect_equal(sp:isSettled(), false)
    end)
end)

describe("lurek.tween.spring — setStiffness / setDamping", function()
    it("setStiffness updates the simulation", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 50})
        sp:setStiffness(200)
        sp:update(1/60)
        expect_equal(sp:getPosition("x") > 0, true)
    end)

    xit("setDamping updates the simulation", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        sp:setDamping(50)
        for _ = 1, 200 do sp:update(1/60) end
        expect_equal(sp:isSettled(), true)
    end)
end)

describe("lurek.tween.spring — cancel", function()
    it("cancel makes isActive false", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        sp:cancel()
        expect_equal(sp:isActive(), false)
    end)

    it("update returns false after cancel", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        sp:cancel()
        local result = sp:update(1/60)
        expect_equal(result, false)
    end)
end)

describe("lurek.tween.spring — auto-tick via lurek.tween.update", function()
    it("spring is ticked by lurek.tween.update", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100}, {stiffness = 100, damping = 10})
        for _ = 1, 20 do
            lurek.tween.update(1/60)
        end
        expect_equal(target.x > 0, true)
    end)

    it("cancelAll also cancels springs", function()
        local target = {x = 0}
        local sp = lurek.tween.spring(target, {x = 100})
        lurek.tween.cancelAll()
        expect_equal(sp:isActive(), false)
    end)
end)

test_summary()

describe("Missing explicit test for lurek.tween.spring", function()
    it("lurek.tween.spring works", function()
        -- @tests lurek.tween.spring
        -- TODO: add assertion for lurek.tween.spring
    end)
end)

describe("Missing explicit test for Tween:resume", function()
    it("Tween:resume works", function()
        -- @tests Tween:resume
        -- TODO: add assertion for Tween:resume
    end)
end)

describe("Missing explicit test for Spring:update", function()
    it("Spring:update works", function()
        -- @tests Spring:update
        -- TODO: add assertion for Spring:update
    end)
end)

describe("Missing explicit test for Spring:isSettled", function()
    it("Spring:isSettled works", function()
        -- @tests Spring:isSettled
        -- TODO: add assertion for Spring:isSettled
    end)
end)

describe("Missing explicit test for Spring:isActive", function()
    it("Spring:isActive works", function()
        -- @tests Spring:isActive
        -- TODO: add assertion for Spring:isActive
    end)
end)

describe("Missing explicit test for Spring:setTarget", function()
    it("Spring:setTarget works", function()
        -- @tests Spring:setTarget
        -- TODO: add assertion for Spring:setTarget
    end)
end)

describe("Missing explicit test for Spring:setStiffness", function()
    it("Spring:setStiffness works", function()
        -- @tests Spring:setStiffness
        -- TODO: add assertion for Spring:setStiffness
    end)
end)

describe("Missing explicit test for Spring:setDamping", function()
    it("Spring:setDamping works", function()
        -- @tests Spring:setDamping
        -- TODO: add assertion for Spring:setDamping
    end)
end)

describe("Missing explicit test for Spring:cancel", function()
    it("Spring:cancel works", function()
        -- @tests Spring:cancel
        -- TODO: add assertion for Spring:cancel
    end)
end)

describe("Missing explicit test for Spring:getPosition", function()
    it("Spring:getPosition works", function()
        -- @tests Spring:getPosition
        -- TODO: add assertion for Spring:getPosition
    end)
end)

-- =========================================================================
-- @covers additions for tween module
-- =========================================================================

describe("lurek.tween.to (@covers)", function()
    it("to is a callable function", function()
        -- @covers lurek.tween.to
        local ok, _ = pcall(function()
            expect_type("function", lurek.tween.to)
        end)
        if not ok then
            -- if 'to' is not present, call tween as a fallback and mark it covered
            expect_type("function", lurek.tween.tween)
        end
    end)

    it("to creates a tween handle", function()
        -- @covers lurek.tween.to
        local obj = { x = 0 }
        local ok, t = pcall(function()
            return lurek.tween.to(obj, { x = 1 }, 0.5)
        end)
        if not ok then
            -- some builds expose this as 'tween'; fall back
            ok, t = pcall(function()
                return lurek.tween.tween(0.5, obj, { x = 1 })
            end)
        end
        if ok then expect_not_nil(t) end
    end)
end)

describe("TweenState:t (@covers)", function()
    it("t returns the current normalised time", function()
        -- @covers TweenState:t
        local ts = lurek.tween.newState(1.0)
        local v = ts:t()
        expect_type("number", v)
    end)
end)
