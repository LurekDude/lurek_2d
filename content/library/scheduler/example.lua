--- Example usage for library.scheduler.
-- Run with: lua content/library/scheduler/example.lua
-- Demonstrates the coroutine-frame scheduler: spawning tasks that yield,
-- driving them with update(dt), pausing/resuming, and observing status
-- and errors. This is a pure-Lua scheduler measured in dt units; for
-- wall-clock one-shots use lurek.timer.Scheduler instead.
-- @module example.scheduler

local M = require("library.scheduler")

-- ── 1. Build a scheduler ──────────────────────────────────────────────────────
local sched = M.newScheduler()
print(string.format("[example.scheduler] created, max iterations=%d",
    M.DEFAULT_MAX_ITERATIONS))

local log = {}
local function note(msg) log[#log + 1] = msg end

-- ── 2. A multi-step task that yields between phases ───────────────────────────
local id_quest = sched:add(function(yield)
    note("quest: travel to forest")
    yield(2.0)
    note("quest: fight wolf")
    yield(1.0)
    note("quest: return to town")
end, "quest")

-- ── 3. A repeating-style task implemented with a loop ─────────────────────────
local ticks = 0
local id_ticker = sched:add(function(yield)
    while ticks < 4 do
        ticks = ticks + 1
        note(string.format("tick #%d", ticks))
        yield(0.5)
    end
end, "ticker")

-- ── 4. A short task that finishes in the same frame as its add ────────────────
sched:add(function(_yield)
    note("greeter: hello!")
    -- no yield -> finishes during add()
end, "greeter")

print(string.format("[example.scheduler] active tasks after add=%d", sched:getCount()))
print(string.format("[example.scheduler] greeter status=%s",
    tostring(select(1, sched:getStatus(3)))))  -- 3rd id assigned was greeter

-- ── 5. Drive the scheduler in 0.5s steps ──────────────────────────────────────
local function step(dt, label)
    local resumes = sched:update(dt)
    note(string.format("step %s dt=%.1f resumes=%d active=%d", label, dt, resumes, sched:getCount()))
end

step(0.5, "A")  -- ticker fires #1
step(0.5, "B")  -- ticker #2
step(0.5, "C")  -- ticker #3

-- ── 6. Pause the ticker, advance, then resume ─────────────────────────────────
sched:pause(id_ticker)
print(string.format("[example.scheduler] ticker paused, status=%s",
    tostring(select(1, sched:getStatus(id_ticker)))))

step(0.5, "D")  -- ticker frozen, quest still waiting
sched:resume(id_ticker)
step(0.5, "E")  -- ticker fires #4 (last), then completes
step(0.5, "F")  -- quest completes its 2.0s wait, runs to next yield
step(1.0, "G")  -- quest finishes

-- ── 7. Errors are captured, never thrown ──────────────────────────────────────
sched:add(function(_yield)
    error("simulated task crash")
end, "crasher")

local errs = sched:getErrors()
print(string.format("[example.scheduler] error count=%d, first msg='%s'",
    #errs, errs[1] and errs[1].msg or "<none>"))

print(string.format("[example.scheduler] final quest status=%s",
    tostring(select(1, sched:getStatus(id_quest)) or "removed")))

for _, line in ipairs(log) do
    print("[example.scheduler]   " .. line)
end

print("[example.scheduler] done.")
