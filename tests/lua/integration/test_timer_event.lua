-- tests/lua/integration/test_timer_event.lua
-- Integration: lurek.timer scheduler callbacks interact with lurek.event signals.

describe("timer + event integration", function()
    it("timer fires once after update accumulates enough dt", function()
        local sched = lurek.timer.newScheduler()
        local fired = false

        sched:after(0.1, function()
            fired = true
        end)

        sched:update(0.05)
        expect_true(not fired, "not yet fired at 0.05 s")

        sched:update(0.06)
        expect_true(fired, "fired after 0.11 s total")
    end)

    it("timer count decrements after firing once", function()
        local sched = lurek.timer.newScheduler()
        sched:after(0.01, function() end)
        expect_equal(sched:getCount(), 1, "1 scheduled timer")
        sched:update(0.02)
        expect_equal(sched:getCount(), 0, "0 timers after firing")
    end)

    it("event signal emits and receives value", function()
        local sig = lurek.event.newSignal()
        local received = nil

        -- connect(event_name, fn)     name is required
        sig:connect("value", function(v)
            received = v
        end)

        sig:emit("value", 42)
        expect_equal(received, 42, "signal delivers value to listener")
    end)

    it("timer callback can emit a signal", function()
        local sched = lurek.timer.newScheduler()
        local sig = lurek.event.newSignal()
        local received = nil

        sig:connect("msg", function(v) received = v end)

        sched:after(0.01, function()
            sig:emit("msg", "hello")
        end)

        sched:update(0.02)
        expect_equal(received, "hello", "timer callback emits signal correctly")
    end)
end)
test_summary()
