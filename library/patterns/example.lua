-- @module library.patterns (deprecated — use library.scheduler)
-- Example: migrating from library.patterns to library.scheduler.
-- This library is a deprecated proxy; all APIs live in library.scheduler.

-- Old usage (still works via forwarding stub):
-- local scheduler = require("library.patterns")

-- Preferred usage going forward:
local scheduler = require("library.scheduler")

local tasks_done = 0

local s = scheduler.new()

s:after(0.1, function()
    tasks_done = tasks_done + 1
    print("[patterns example] task 1 completed via scheduler")
end)

s:after(0.2, function()
    tasks_done = tasks_done + 1
    print("[patterns example] task 2 completed — tasks_done=" .. tasks_done)
end)

-- Advance the scheduler manually (no lurek.timer dependency needed)
s:update(0.25)

assert(tasks_done == 2, "expected 2 tasks to have run")
print("[patterns example] OK")
