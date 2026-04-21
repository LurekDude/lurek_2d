# `library.scheduler`

Lurek2D coroutine scheduler — a pure-Lua cooperative task runner.

A pure-Lua coroutine scheduler that integrates with the engine's update loop.
No engine dependencies; works in headless test VMs.

Tasks are coroutine bodies that receive a `yield(seconds)` helper. Calling
`yield(n)` suspends the task for `n` seconds of game time. When the wait
elapses the scheduler resumes the coroutine. Tasks that return (or error)
are automatically removed on the next `update()`.

This is a **coroutine-frame** scheduler: timing is measured in units of `dt`
you pass to `:update(dt)`. For wall-clock one-shots / repeats use the engine
`lurek.timer.Scheduler` userdata (`:after`, `:every`, `:cancel`) instead.

Usage:
local scheduler = require("library.scheduler")
local sched = scheduler.newScheduler()
sched:add(function(yield)
print("start")
yield(1.0)    -- pause for 1 second of game time
print("after 1 second")
end)
-- each frame:
sched:update(dt)

*11 functions, 0 module fields documented.*

See: [`lurek.timer.Scheduler`](../lua-api.md#lurektimescheduler)

## Functions

### `newScheduler(opts)`

Create a new coroutine scheduler. Manages a pool of coroutine tasks; each task can `yield(seconds)` to pause itself. Completed, errored, and removed tasks are cleaned up automatically.

**Parameters**

- `opts` *table* — Options table.
- `opts.max_iterations` *number* — Max coroutine resumes per `update()`.

**Returns**

- *Scheduler* — A new scheduler handle.

See: [`lurek.timer.Scheduler`](../lua-api.md#lurektimescheduler)

### `add(fn, name)`

Add a new task function to the scheduler. The task receives a `yield` function as its first argument. Call `yield(seconds)` inside the task to pause for that many seconds.

**Parameters**

- `fn` *function* — Coroutine body: `function(yield) ... end`.
- `name` *string* — Optional human-readable name for logging.

**Returns**

- *number* — Task id.

### `remove(id)`

Remove a task by id.

**Parameters**

- `id` *number* — Task id returned by `add()`.

**Returns**

- *boolean* — True if a task was removed.

### `pause(id)`

Pause a task by id.  Paused tasks keep their remaining wait time but are not ticked until resumed.

**Parameters**

- `id` *number* — Task id.

### `resume(id)`

Resume a paused task by id.

**Parameters**

- `id` *number* — Task id.

### `getStatus(id)`

Return the status of a task.

**Parameters**

- `id` *number* — Task id.

**Returns**

- *string|nil* — One of `"running"`, `"paused"`, `"done"`, `"error"`, or `nil` if not found.
- *string|nil* — Error message if status is `"error"`.

### `update(dt)`

Step all active tasks by dt seconds. Tasks whose wait time has elapsed are resumed. A per-call iteration guard prevents infinite loops when a task yields 0 repeatedly.

**Parameters**

- `dt` *number* — Delta time in seconds (must be >= 0).

**Returns**

- *number* — Number of coroutine resumes performed this call.

See: [`lurek.timer.getDelta`](../lua-api.md#lurektimegetdelta)

### `getCount()`

Return the number of active (non-done) tasks.

**Returns**

- *number* — Count of tasks still in the scheduler.

### `getErrors()`

Return the list of errors captured since creation (or last `clearErrors()`). Each entry is `{ id = number, msg = string }`.

**Returns**

- *table* — Array of error records.

### `clearErrors()`

Clear the captured error list.

### `clear()`

Remove all tasks immediately.
