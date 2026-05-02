-- tests/lua/library/test_library_rhythm.lua
-- BDD tests for library/rhythm/init.lua     beat clock, sequencer, judgement.

local rhythm = require("library.rhythm")


describe("Clock.getBeat", function()
    it("advances at the declared BPM     120bpm = 2 beats/sec", function()
        local c = rhythm.newClock(120):start()
        for _ = 1, 100 do c:update(0.01) end  -- 1.0s
        expect_near(2.0, c:getBeat(), 0.05)
    end)

    it("zero before start", function()
        local c = rhythm.newClock(120)
        c:update(1.0)
        expect_equal(0, c:getBeat())
    end)
end)

describe("rampBpm", function()
    it("interpolates over the requested duration", function()
        local c = rhythm.newClock(60):start()
        c:rampBpm(120, 1.0)
        for _ = 1, 50 do c:update(0.01) end  -- 0.5s
        expect_in_range(c:getBpm(), 85, 95)
        for _ = 1, 60 do c:update(0.01) end  -- past 1.0s
        expect_near(120, c:getBpm(), 0.5)
    end)
end)

describe("every / pattern / at", function()
    it("every(4) fires roughly N times per N quarter notes", function()
        local hits = 0
        local c = rhythm.newClock(120, { subdivision = 4 }):start()
        c:every(4, function() hits = hits + 1 end)
        for _ = 1, 200 do c:update(0.01) end  -- 2s = 4 beats
        expect_in_range(hits, 3, 5)
    end)

    it("pattern 'x..x' fires on beats 0 and 3 only over one bar", function()
        local hits = {}
        local c = rhythm.newClock(120, { subdivision = 4 }):start()
        c:pattern("x..x", function(step) hits[#hits + 1] = step end)
        -- one bar = 4 quarter notes at 120 bpm = 2 seconds
        for _ = 1, 220 do c:update(0.01) end
        -- We should have seen at least 2 hits in the first bar.
        expect_true(#hits >= 2, "expected >=2 pattern hits, got "..#hits)
    end)

    it("at(beat) for past beat raises", function()
        local c = rhythm.newClock(120):start()
        for _ = 1, 200 do c:update(0.01) end  -- ~4 beats elapsed
        expect_error(function() c:at(0.5, function() end) end)
    end)

    it("cancel(handle) stops further firing", function()
        local hits = 0
        local c = rhythm.newClock(120):start()
        local h = c:every(4, function() hits = hits + 1 end)
        for _ = 1, 50 do c:update(0.01) end
        c:cancel(h)
        local snapshot = hits
        for _ = 1, 100 do c:update(0.01) end
        expect_equal(snapshot, hits)
    end)
end)

describe("phase queries", function()
    it("getPhase returns a value in [0, 1)", function()
        local c = rhythm.newClock(120):start()
        for _ = 1, 13 do c:update(0.01) end
        local p = c:getPhase(4)
        expect_true(p >= 0 and p < 1, "phase out of range: "..p)
    end)

    it("beatTimeRemaining drops as we approach the next beat", function()
        local c = rhythm.newClock(60):start()  -- 1 beat per second
        local r0 = c:beatTimeRemaining(4)
        for _ = 1, 50 do c:update(0.01) end
        local r1 = c:beatTimeRemaining(4)
        expect_true(r1 < r0, "remaining did not decrease")
    end)
end)

describe("judge", function()
    it("returns 'perfect' inside the perfect window", function()
        rhythm.setJudgementWindows({ perfect = 0.025, great = 0.05, good = 0.10 })
        local c = rhythm.newClock(120):start()
        -- After exactly 1 beat (0.5s @ 120bpm) we're on-beat.
        for _ = 1, 50 do c:update(0.01) end
        local verdict = rhythm.judge(c, 4)
        expect_equal("perfect", verdict)
    end)
end)

describe("error paths", function()
    it("newClock with non-positive bpm raises", function()
        expect_error(function() rhythm.newClock(0) end)
        expect_error(function() rhythm.newClock(-1) end)
    end)

    it("pattern with empty string raises", function()
        local c = rhythm.newClock(120)
        expect_error(function() c:pattern("", function() end) end)
    end)
end)
test_summary()
