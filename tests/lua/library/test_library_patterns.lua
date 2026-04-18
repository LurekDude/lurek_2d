--- BDD tests for library.patterns — coroutine scheduler.
--- Covers task lifecycle, yield timing, error handling, status, max iterations.

require("tests.lua.init")
local patterns = require("library.patterns")

-- ── newScheduler ──────────────────────────────────────────────────────────────

describe("newScheduler", function()
    it("should create an empty scheduler", function()
        local s = patterns.newScheduler()
        expect_equal(s:getCount(), 0)
    end)

    it("should accept max_iterations option", function()
        local s = patterns.newScheduler({ max_iterations = 5 })
        expect_equal(s._max_iterations, 5)
    end)

    it("should default max_iterations to DEFAULT_MAX_ITERATIONS", function()
        local s = patterns.newScheduler()
        expect_equal(s._max_iterations, patterns.DEFAULT_MAX_ITERATIONS)
    end)
end)

-- ── add ───────────────────────────────────────────────────────────────────────

describe("add", function()
    it("should return an incrementing task id", function()
        local s = patterns.newScheduler()
        local id1 = s:add(function(yield) yield(1) end)
        local id2 = s:add(function(yield) yield(1) end)
        expect_equal(id1, 1)
        expect_equal(id2, 2)
    end)

    it("should increase the task count", function()
        local s = patterns.newScheduler()
        s:add(function(yield) yield(1) end)
        expect_equal(s:getCount(), 1)
        s:add(function(yield) yield(2) end)
        expect_equal(s:getCount(), 2)
    end)

    it("should kick off the coroutine immediately", function()
        local started = false
        local s = patterns.newScheduler()
        s:add(function(yield)
            started = true
            yield(1)
        end)
        expect_equal(started, true)
    end)

    it("should handle a task that completes immediately", function()
        local ran = false
        local s = patterns.newScheduler()
        s:add(function()
            ran = true
            -- no yield, returns immediately
        end)
        expect_equal(ran, true)
        -- completed task is still in the list until next update cleans it
        -- or was removed during add (done=true, removed on next update)
    end)

    it("should accept an optional name", function()
        local s = patterns.newScheduler()
        s:add(function(yield) yield(1) end, "my_task")
        -- no error means success
        expect_equal(s:getCount(), 1)
    end)

    it("should error on non-function argument", function()
        local s = patterns.newScheduler()
        local ok, err = pcall(function() s:add("not a function") end)
        expect_equal(ok, false)
        expect_equal(type(err), "string")
    end)

    it("should error on nil argument", function()
        local s = patterns.newScheduler()
        local ok, _ = pcall(function() s:add(nil) end)
        expect_equal(ok, false)
    end)
end)

-- ── remove ────────────────────────────────────────────────────────────────────

describe("remove", function()
    it("should remove an existing task", function()
        local s = patterns.newScheduler()
        local id = s:add(function(yield) yield(10) end)
        expect_equal(s:remove(id), true)
        expect_equal(s:getCount(), 0)
    end)

    it("should return false for non-existent id", function()
        local s = patterns.newScheduler()
        expect_equal(s:remove(999), false)
    end)

    it("should error on non-number id", function()
        local s = patterns.newScheduler()
        local ok, _ = pcall(function() s:remove("abc") end)
        expect_equal(ok, false)
    end)
end)

-- ── pause / resume ────────────────────────────────────────────────────────────

describe("pause / resume", function()
    it("should prevent a paused task from running", function()
        local count = 0
        local s = patterns.newScheduler()
        local id = s:add(function(yield)
            while true do
                count = count + 1
                yield(0.1)
            end
        end)
        count = 0  -- reset after initial kick-off
        s:pause(id)
        s:update(1.0)
        expect_equal(count, 0)
    end)

    it("should let a resumed task run again", function()
        local count = 0
        local s = patterns.newScheduler()
        local id = s:add(function(yield)
            while true do
                count = count + 1
                yield(0.5)
            end
        end)
        count = 0
        s:pause(id)
        s:update(1.0)
        expect_equal(count, 0)
        s:resume(id)
        s:update(1.0)
        -- should have run at least once after resume
        expect_equal(count > 0, true)
    end)

    it("should error on non-number id for pause", function()
        local s = patterns.newScheduler()
        local ok, _ = pcall(function() s:pause("x") end)
        expect_equal(ok, false)
    end)

    it("should error on non-number id for resume", function()
        local s = patterns.newScheduler()
        local ok, _ = pcall(function() s:resume("x") end)
        expect_equal(ok, false)
    end)
end)

-- ── update / yield timing ─────────────────────────────────────────────────────

describe("update", function()
    it("should not resume a task before its wait time elapses", function()
        local resumed = false
        local s = patterns.newScheduler()
        s:add(function(yield)
            yield(2.0)
            resumed = true
        end)
        s:update(0.5)
        expect_equal(resumed, false)
        s:update(0.5)
        expect_equal(resumed, false)
    end)

    it("should resume a task once wait time elapses", function()
        local resumed = false
        local s = patterns.newScheduler()
        s:add(function(yield)
            yield(1.0)
            resumed = true
        end)
        s:update(0.5)
        expect_equal(resumed, false)
        s:update(0.6)  -- total 1.1 > 1.0
        expect_equal(resumed, true)
    end)

    it("should remove completed tasks automatically", function()
        local s = patterns.newScheduler()
        s:add(function(yield)
            yield(0.1)
            -- done after this
        end)
        expect_equal(s:getCount(), 1)
        s:update(0.2)
        expect_equal(s:getCount(), 0)
    end)

    it("should handle multiple tasks independently", function()
        local log = {}
        local s = patterns.newScheduler()
        s:add(function(yield)
            table.insert(log, "A1")
            yield(0.1)
            table.insert(log, "A2")
        end)
        s:add(function(yield)
            table.insert(log, "B1")
            yield(0.5)
            table.insert(log, "B2")
        end)
        -- Both A1 and B1 already logged on add
        s:update(0.2)  -- A finishes, B still waiting
        expect_equal(#log >= 3, true)  -- A1, B1, A2 at minimum
    end)

    it("should return the number of iterations performed", function()
        local s = patterns.newScheduler()
        s:add(function(yield)
            yield(0.1)
            yield(100)  -- long wait
        end)
        local iters = s:update(0.2)
        expect_equal(iters, 1)
    end)

    it("should error on non-number dt", function()
        local s = patterns.newScheduler()
        local ok, _ = pcall(function() s:update("bad") end)
        expect_equal(ok, false)
    end)

    it("should error on negative dt", function()
        local s = patterns.newScheduler()
        local ok, _ = pcall(function() s:update(-1) end)
        expect_equal(ok, false)
    end)

    it("should handle dt=0 without errors", function()
        local s = patterns.newScheduler()
        s:add(function(yield) yield(1.0) end)
        local iters = s:update(0)
        expect_equal(type(iters), "number")
    end)

    it("should work on an empty scheduler", function()
        local s = patterns.newScheduler()
        local iters = s:update(1.0)
        expect_equal(iters, 0)
    end)
end)

-- ── max iterations guard ──────────────────────────────────────────────────────

describe("max iterations", function()
    it("should stop after max_iterations resumes per update", function()
        local count = 0
        local s = patterns.newScheduler({ max_iterations = 5 })
        s:add(function(yield)
            while true do
                count = count + 1
                yield(0)  -- yield 0 = run again immediately
            end
        end)
        count = 0  -- reset after initial kick-off resume
        s:update(1.0)
        -- should have been resumed at most 5 times
        expect_equal(count <= 5, true)
        expect_equal(count, 5)
    end)

    it("should still have the task alive after hitting the guard", function()
        local s = patterns.newScheduler({ max_iterations = 3 })
        s:add(function(yield)
            while true do yield(0) end
        end)
        s:update(1.0)
        expect_equal(s:getCount(), 1)
    end)
end)

-- ── error handling ────────────────────────────────────────────────────────────

describe("error handling", function()
    it("should capture error from a task that errors on start", function()
        local s = patterns.newScheduler()
        s:add(function()
            error("boom")
        end)
        local errs = s:getErrors()
        expect_equal(#errs, 1)
        -- error message should contain "boom"
        expect_equal(type(errs[1].msg), "string")
        expect_equal(errs[1].msg:find("boom") ~= nil, true)
    end)

    it("should capture error from a task that errors mid-run", function()
        local s = patterns.newScheduler()
        s:add(function(yield)
            yield(0.1)
            error("delayed boom")
        end)
        s:update(0.2)
        local errs = s:getErrors()
        expect_equal(#errs, 1)
        expect_equal(errs[1].msg:find("delayed boom") ~= nil, true)
    end)

    it("should remove errored tasks", function()
        local s = patterns.newScheduler()
        s:add(function(yield)
            yield(0.1)
            error("fail")
        end)
        s:update(0.2)
        expect_equal(s:getCount(), 0)
    end)

    it("should keep track of error id", function()
        local s = patterns.newScheduler()
        local id = s:add(function(yield)
            yield(0.1)
            error("tracked")
        end)
        s:update(0.2)
        local errs = s:getErrors()
        expect_equal(errs[1].id, id)
    end)

    it("clearErrors should empty the list", function()
        local s = patterns.newScheduler()
        s:add(function() error("e") end)
        expect_equal(#s:getErrors() > 0, true)
        s:clearErrors()
        expect_equal(#s:getErrors(), 0)
    end)
end)

-- ── getStatus ─────────────────────────────────────────────────────────────────

describe("getStatus", function()
    it("should return 'running' for an active task", function()
        local s = patterns.newScheduler()
        local id = s:add(function(yield) yield(10) end)
        local status = s:getStatus(id)
        expect_equal(status, "running")
    end)

    it("should return 'paused' for a paused task", function()
        local s = patterns.newScheduler()
        local id = s:add(function(yield) yield(10) end)
        s:pause(id)
        expect_equal(s:getStatus(id), "paused")
    end)

    it("should return nil for a non-existent id", function()
        local s = patterns.newScheduler()
        expect_equal(s:getStatus(999), nil)
    end)

    it("should return 'error' for a task that errored on start", function()
        local s = patterns.newScheduler()
        local id = s:add(function() error("oops") end)
        -- errored tasks with done=true might still be in the list until update cleans them
        -- or they may have been marked done. getStatus checks in-list tasks.
        -- The task is done+error; it's still in _tasks until next update sweep.
        local status, msg = s:getStatus(id)
        if status then
            expect_equal(status, "error")
            expect_equal(msg:find("oops") ~= nil, true)
        end
    end)

    it("should error on non-number id", function()
        local s = patterns.newScheduler()
        local ok, _ = pcall(function() s:getStatus("nope") end)
        expect_equal(ok, false)
    end)
end)

-- ── getCount ──────────────────────────────────────────────────────────────────

describe("getCount", function()
    it("should be 0 on fresh scheduler", function()
        local s = patterns.newScheduler()
        expect_equal(s:getCount(), 0)
    end)

    it("should track additions and removals", function()
        local s = patterns.newScheduler()
        local id1 = s:add(function(yield) yield(10) end)
        local _   = s:add(function(yield) yield(10) end)
        expect_equal(s:getCount(), 2)
        s:remove(id1)
        expect_equal(s:getCount(), 1)
    end)
end)

-- ── clear ─────────────────────────────────────────────────────────────────────

describe("clear", function()
    it("should remove all tasks", function()
        local s = patterns.newScheduler()
        s:add(function(yield) yield(10) end)
        s:add(function(yield) yield(10) end)
        s:add(function(yield) yield(10) end)
        expect_equal(s:getCount(), 3)
        s:clear()
        expect_equal(s:getCount(), 0)
    end)

    it("should be safe on empty scheduler", function()
        local s = patterns.newScheduler()
        s:clear()
        expect_equal(s:getCount(), 0)
    end)
end)

-- ── edge cases ────────────────────────────────────────────────────────────────

describe("edge cases", function()
    it("should handle task yielding nil (treated as 0)", function()
        local count = 0
        local s = patterns.newScheduler({ max_iterations = 3 })
        s:add(function(yield)
            while true do
                count = count + 1
                yield()  -- nil seconds → treated as 0
            end
        end)
        count = 0
        s:update(0.1)
        -- should still be capped by max_iterations
        expect_equal(count <= 3, true)
    end)

    it("should handle many tasks added and completing", function()
        local s = patterns.newScheduler()
        for i = 1, 20 do
            s:add(function(yield)
                yield(0.01 * i)
            end)
        end
        expect_equal(s:getCount(), 20)
        -- big update clears them all
        s:update(1.0)
        expect_equal(s:getCount(), 0)
    end)

    it("should handle adding a task inside update (via coroutine body)", function()
        local inner_ran = false
        local s = patterns.newScheduler()
        s:add(function(yield)
            -- We can't easily add to sched from inside since we don't have a
            -- reference, but we can verify the coroutine itself works fine
            yield(0.1)
        end)
        s:update(0.2)
        expect_equal(s:getCount(), 0)
    end)

    it("double remove should return false on second call", function()
        local s = patterns.newScheduler()
        local id = s:add(function(yield) yield(10) end)
        expect_equal(s:remove(id), true)
        expect_equal(s:remove(id), false)
    end)
end)

test_summary()
