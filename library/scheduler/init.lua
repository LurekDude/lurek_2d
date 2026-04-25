--- Lurek2D coroutine scheduler — a pure-Lua cooperative task runner.
--
-- A pure-Lua coroutine scheduler that integrates with the engine's update loop.
-- No engine dependencies; works in headless test VMs.
--
-- Tasks are coroutine bodies that receive a `yield(seconds)` helper. Calling
-- `yield(n)` suspends the task for `n` seconds of game time. When the wait
-- elapses the scheduler resumes the coroutine. Tasks that return (or error)
-- are automatically removed on the next `update()`.
--
-- This is a **coroutine-frame** scheduler: timing is measured in units of `dt`
-- you pass to `:update(dt)`. For wall-clock one-shots / repeats use the engine
-- `lurek.timer.Scheduler` userdata (`:after`, `:every`, `:cancel`) instead.
--
-- Usage:
--   local scheduler = require("library.scheduler")
--   local sched = scheduler.newScheduler()
--   sched:add(function(yield)
--       print("start")
--       yield(1.0)    -- pause for 1 second of game time
--       print("after 1 second")
--   end)
--   -- each frame:
--   sched:update(dt)
--
-- @module library.scheduler
-- @status full
-- @see lurek.timer.Scheduler

local M = {}

--- Default maximum coroutine resumes per single `update()` call.
-- Prevents an infinite loop when a task yields 0 repeatedly.
M.DEFAULT_MAX_ITERATIONS = 1000

-- ── Optional logging ──────────────────────────────────────────────────────────

--- @local
--- Try to load lurek.log; falls back to a no-op if unavailable (headless tests).
local log_ok, _log = pcall(function()
    return lurek and lurek.log
end)
if not log_ok or not _log then
    _log = {
        debug = function() end,
        warn  = function() end,
        error = function() end,
    }
end

-- ── Internal helpers ──────────────────────────────────────────────────────────

--- @local
--- Wrap a callable into a task descriptor.
-- @tparam function fn  Coroutine body.
-- @treturn table  Task record.
local function wrap_task(fn)
    local co = coroutine.create(fn)
    return {
        co      = co,
        wait    = 0.0,
        paused  = false,
        done    = false,
        started = false,        -- true after the first resume
        id      = nil,          -- assigned by scheduler
        error   = nil,          -- captured error message (if any)
    }
end

-- ── Scheduler ─────────────────────────────────────────────────────────────────

--- Create a new coroutine scheduler.
-- Manages a pool of coroutine tasks; each task can `yield(seconds)` to pause
-- itself. Completed, errored, and removed tasks are cleaned up automatically.
--
-- @tparam[opt] table opts  Options table.
-- @tparam[opt=1000] number opts.max_iterations  Max coroutine resumes per `update()`.
-- @treturn Scheduler  A new scheduler handle.
-- @see lurek.timer.Scheduler
function M.newScheduler(opts)
    opts = opts or {}

    ---@class LScheduler
    local sched = {
        _tasks          = {},
        _next_id        = 1,
        _max_iterations = opts.max_iterations or M.DEFAULT_MAX_ITERATIONS,
        _errors         = {},   -- list of {id=, msg=} for tasks that errored
    }

    --- Add a new task function to the scheduler.
    -- The task receives a `yield` function as its first argument.
    -- Call `yield(seconds)` inside the task to pause for that many seconds.
    --
    -- @tparam function fn  Coroutine body: `function(yield) ... end`.
    -- @tparam[opt] string name  Optional human-readable name for logging.
    -- @treturn number  Task id.
    function sched:add(fn, name)
        if type(fn) ~= "function" then
            error("scheduler.Scheduler:add() — first argument must be a function, got " .. type(fn), 2)
        end

        local task = wrap_task(fn)
        task.id   = self._next_id
        task.name = name or ("task_" .. tostring(task.id))
        self._next_id = self._next_id + 1
        table.insert(self._tasks, task)

        _log.debug("[scheduler] add task #" .. tostring(task.id) .. " '" .. task.name .. "'")

        -- Kick off: run until the first yield or return.
        local yield_fn = function(seconds)
            coroutine.yield(seconds or 0)
        end
        local ok, wait_or_err = coroutine.resume(task.co, yield_fn)
        task.started = true
        if not ok then
            task.done  = true
            task.error = tostring(wait_or_err)
            _log.error("[scheduler] task #" .. tostring(task.id) .. " error on start: " .. task.error)
            table.insert(self._errors, { id = task.id, msg = task.error })
        elseif coroutine.status(task.co) == "dead" then
            task.done = true
            _log.debug("[scheduler] task #" .. tostring(task.id) .. " completed immediately")
        else
            task.wait = type(wait_or_err) == "number" and wait_or_err or 0
        end
        return task.id
    end

    --- Remove a task by id.
    -- @tparam number id  Task id returned by `add()`.
    -- @treturn boolean  True if a task was removed.
    function sched:remove(id)
        if type(id) ~= "number" then
            error("scheduler.Scheduler:remove() — id must be a number, got " .. type(id), 2)
        end
        for i, t in ipairs(self._tasks) do
            if t.id == id then
                table.remove(self._tasks, i)
                _log.debug("[scheduler] removed task #" .. tostring(id))
                return true
            end
        end
        return false
    end

    --- Pause a task by id.  Paused tasks keep their remaining wait time but are
    -- not ticked until resumed.
    -- @tparam number id  Task id.
    function sched:pause(id)
        if type(id) ~= "number" then
            error("scheduler.Scheduler:pause() — id must be a number, got " .. type(id), 2)
        end
        for _, t in ipairs(self._tasks) do
            if t.id == id then
                t.paused = true
                return
            end
        end
    end

    --- Resume a paused task by id.
    -- @tparam number id  Task id.
    function sched:resume(id)
        if type(id) ~= "number" then
            error("scheduler.Scheduler:resume() — id must be a number, got " .. type(id), 2)
        end
        for _, t in ipairs(self._tasks) do
            if t.id == id then
                t.paused = false
                return
            end
        end
    end

    --- Return the status of a task.
    -- @tparam number id  Task id.
    -- @treturn string|nil  One of `"running"`, `"paused"`, `"done"`, `"error"`, or `nil` if not found.
    -- @treturn string|nil  Error message if status is `"error"`.
    function sched:getStatus(id)
        if type(id) ~= "number" then
            error("scheduler.Scheduler:getStatus() — id must be a number, got " .. type(id), 2)
        end
        for _, t in ipairs(self._tasks) do
            if t.id == id then
                if t.error then
                    return "error", t.error
                elseif t.done then
                    return "done"
                elseif t.paused then
                    return "paused"
                else
                    return "running"
                end
            end
        end
        return nil
    end

    --- Step all active tasks by dt seconds.
    -- Tasks whose wait time has elapsed are resumed. A per-call iteration guard
    -- prevents infinite loops when a task yields 0 repeatedly.
    --
    -- @tparam number dt  Delta time in seconds (must be >= 0).
    -- @treturn number  Number of coroutine resumes performed this call.
    -- @see lurek.timer.getDelta
    function sched:update(dt)
        if type(dt) ~= "number" then
            error("scheduler.Scheduler:update() — dt must be a number, got " .. type(dt), 2)
        end
        if dt < 0 then
            error("scheduler.Scheduler:update() — dt must be >= 0, got " .. tostring(dt), 2)
        end

        local iterations = 0
        local max_iter   = self._max_iterations
        local i = 1
        while i <= #self._tasks do
            if iterations >= max_iter then
                _log.warn("[scheduler] update() hit max iterations (" .. tostring(max_iter) .. "), breaking")
                break
            end

            local t = self._tasks[i]
            if t.done then
                table.remove(self._tasks, i)
                -- do not increment i
            elseif not t.paused then
                t.wait = t.wait - dt
                if t.wait <= 0 then
                    iterations = iterations + 1
                    local ok, wait_or_err = coroutine.resume(t.co)
                    if not ok then
                        t.done  = true
                        t.error = tostring(wait_or_err)
                        _log.error("[scheduler] task #" .. tostring(t.id) .. " error: " .. t.error)
                        table.insert(self._errors, { id = t.id, msg = t.error })
                        table.remove(self._tasks, i)
                        -- do not increment i
                    elseif coroutine.status(t.co) == "dead" then
                        t.done = true
                        _log.debug("[scheduler] task #" .. tostring(t.id) .. " completed")
                        table.remove(self._tasks, i)
                        -- do not increment i
                    else
                        t.wait = type(wait_or_err) == "number" and wait_or_err or 0
                        i = i + 1
                    end
                else
                    i = i + 1
                end
            else
                i = i + 1
            end
        end
        return iterations
    end

    --- Return the number of active (non-done) tasks.
    -- @treturn number  Count of tasks still in the scheduler.
    function sched:getCount()
        return #self._tasks
    end

    --- Return the list of errors captured since creation (or last `clearErrors()`).
    -- Each entry is `{ id = number, msg = string }`.
    -- @treturn table  Array of error records.
    function sched:getErrors()
        return self._errors
    end

    --- Clear the captured error list.
    function sched:clearErrors()
        self._errors = {}
    end

    --- Remove all tasks immediately.
    function sched:clear()
        self._tasks = {}
        _log.debug("[scheduler] cleared all tasks")
    end

    return sched
end

return M
