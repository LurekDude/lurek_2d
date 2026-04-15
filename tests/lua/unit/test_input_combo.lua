-- tests/lua/unit/test_input_combo.lua
-- BDD tests for lurek.input.newCombo() — combo / sequence detection.
-- No GPU, audio, or window API calls.

describe("lurek.input.newCombo — basic construction", function()

    it("creates a combo with the correct total step count (string steps)", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        expect_equal(combo:totalSteps(), 3)
    end)

    it("creates a combo with table steps", function()
        local combo = lurek.input.newCombo(
            {{key="down", gap=300}, {key="right", gap=300}, {key="a", gap=300}}
        )
        expect_equal(combo:totalSteps(), 3)
    end)

    it("starts with progress 0 and not in progress", function()
        local combo = lurek.input.newCombo({"x", "y"})
        expect_equal(combo:progress(), 0)
        expect_equal(combo:isInProgress(), false)
    end)

    it("getStep returns correct key for 1-based index", function()
        local combo = lurek.input.newCombo({"down", "right", "a"})
        local s1 = combo:getStep(1)
        local s2 = combo:getStep(2)
        expect_equal(s1.key, "down")
        expect_equal(s2.key, "right")
    end)

    it("getStep returns nil for out-of-range index", function()
        local combo = lurek.input.newCombo({"a"})
        expect_equal(combo:getStep(0), nil)
        expect_equal(combo:getStep(2), nil)
    end)

    it("getStep respects custom gap from table step", function()
        local combo = lurek.input.newCombo({{key="space", gap=750}})
        local s = combo:getStep(1)
        expect_equal(s.gap_ms, 750)
    end)

    it("getStep default gap is 500 ms for string step", function()
        local combo = lurek.input.newCombo({"space"})
        local s = combo:getStep(1)
        expect_equal(s.gap_ms, 500)
    end)

end)

describe("lurek.input.newCombo — feed() advancement", function()

    it("returns 'idle' when wrong first key is fed", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        local result = combo:feed("x")
        expect_equal(result, "idle")
        expect_equal(combo:progress(), 0)
    end)

    it("returns 'advanced' when correct first key is fed", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        local result = combo:feed("a")
        expect_equal(result, "advanced")
        expect_equal(combo:progress(), 1)
        expect_equal(combo:isInProgress(), true)
    end)

    it("returns 'advanced' through each intermediate step", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        combo:feed("a")
        local r2 = combo:feed("b")
        expect_equal(r2, "advanced")
        expect_equal(combo:progress(), 2)
    end)

    it("returns 'completed' on final step", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        combo:feed("a")
        combo:feed("b")
        local r = combo:feed("c")
        expect_equal(r, "completed")
    end)

    it("resets to idle after completion", function()
        local combo = lurek.input.newCombo({"a", "b"})
        combo:feed("a")
        combo:feed("b")
        expect_equal(combo:progress(), 0)
        expect_equal(combo:isInProgress(), false)
    end)

    it("returns 'broken' when wrong key mid-sequence", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        combo:feed("a")
        local r = combo:feed("x")
        expect_equal(r, "broken")
        expect_equal(combo:progress(), 0)
        expect_equal(combo:isInProgress(), false)
    end)

    it("is idle again after a broken sequence", function()
        local combo = lurek.input.newCombo({"a", "b"})
        combo:feed("a")
        combo:feed("x")  -- break
        local r = combo:feed("a")  -- restart
        expect_equal(r, "advanced")
    end)

    it("single-step combo completes immediately on correct key", function()
        local combo = lurek.input.newCombo({"space"})
        local r = combo:feed("space")
        expect_equal(r, "completed")
    end)

end)

describe("lurek.input.newCombo — tick() timeout", function()

    it("tick returns 'idle' when no combo is in progress", function()
        local combo = lurek.input.newCombo({"a", "b"}, {total_gap=2000})
        local r = combo:tick(0.1)
        expect_equal(r, "idle")
    end)

    it("tick returns 'in_progress' while within time budget", function()
        local combo = lurek.input.newCombo({{key="a", gap=1000}, {key="b", gap=1000}}, {total_gap=2000})
        combo:feed("a")
        -- 0.3 s elapsed — well within 1000 ms gap
        local r = combo:tick(0.3)
        expect_equal(r, "in_progress")
    end)

    it("tick returns 'expired' when per-step gap exceeded", function()
        local combo = lurek.input.newCombo({{key="a", gap=200}, {key="b", gap=200}}, {total_gap=2000})
        combo:feed("a")
        -- 0.3 s = 300 ms > 200 ms gap
        local r = combo:tick(0.3)
        expect_equal(r, "expired")
    end)

    it("detector is idle after tick expiry", function()
        local combo = lurek.input.newCombo({{key="a", gap=100}, {key="b", gap=100}}, {total_gap=2000})
        combo:feed("a")
        combo:tick(0.2)  -- expire
        expect_equal(combo:isInProgress(), false)
        expect_equal(combo:progress(), 0)
    end)

    it("tick returns 'expired' when total gap exceeded", function()
        -- per-step gap is high, but total budget is tiny
        local combo = lurek.input.newCombo(
            {{key="a", gap=5000}, {key="b", gap=5000}},
            {total_gap=100}
        )
        combo:feed("a")
        -- 0.2 s = 200 ms > 100 ms total_gap
        local r = combo:tick(0.2)
        expect_equal(r, "expired")
    end)

end)

describe("lurek.input.newCombo — reset()", function()

    it("reset cancels an in-progress combo", function()
        local combo = lurek.input.newCombo({"a", "b", "c"})
        combo:feed("a")
        combo:feed("b")
        combo:reset()
        expect_equal(combo:progress(), 0)
        expect_equal(combo:isInProgress(), false)
    end)

    it("reset allows restarting the same combo", function()
        local combo = lurek.input.newCombo({"a", "b"})
        combo:feed("a")
        combo:reset()
        combo:feed("a")
        local r = combo:feed("b")
        expect_equal(r, "completed")
    end)

end)

describe("lurek.input.newCombo — opts.total_gap", function()

    it("custom total_gap is respected", function()
        local combo = lurek.input.newCombo(
            {{key="x", gap=5000}, {key="y", gap=5000}},
            {total_gap=50}
        )
        combo:feed("x")
        -- 0.1 s = 100 ms > 50 ms total budget
        local r = combo:tick(0.1)
        expect_equal(r, "expired")
    end)

end)

describe("lurek.input.newCombo — error cases", function()

    it("raises error for empty steps table", function()
        expect_error(function()
            lurek.input.newCombo({})
        end)
    end)

    it("raises error when step table has no 'key' field", function()
        expect_error(function()
            lurek.input.newCombo({{gap=300}})
        end)
    end)

end)

test_summary()
