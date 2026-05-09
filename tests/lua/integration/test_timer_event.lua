-- Integration: timer scheduler callbacks emitting event signals
describe("timer + event integration", function()

    -- @integration LScheduler:after
    -- @integration LScheduler:update
    -- @integration LSignal:connect
    -- @integration LSignal:emit
    -- @integration lurek.event.newSignal
    -- @integration lurek.timer.newScheduler
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
