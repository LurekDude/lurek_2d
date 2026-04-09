-- examples/thread.lua
-- luna.thread — Background worker threads and inter-thread Channel communication.
-- All luna.thread API methods demonstrated with code and comments.
--
-- Threading model:
--   The main thread runs the Lua game loop with the full luna.* API.
--   Worker threads get a separate, isolated Lua VM — they cannot share Lua state.
--   All communication goes through typed Channel objects (MPMC queues).
--   Channel values: nil, booleans, numbers, and strings only.

-- ── Creating a Thread ─────────────────────────────────────────────────────────

-- newThread(code) → Thread
-- Creates a background thread from a Lua source string.
-- The worker VM has access to luna.math, luna.data, luna.thread, luna.fs,
-- luna.time, and luna.platform — but NOT luna.gfx, luna.audio, or luna.physics.
local worker = luna.thread.newThread([[
    local input_ch  = luna.thread.getChannel("work_in")
    local output_ch = luna.thread.getChannel("work_out")

    while true do
        local job = input_ch:demand()  -- block until a job arrives
        if job == "quit" then break end

        -- Heavy computation (safe to do on a worker thread)
        local result = 0
        for i = 1, tonumber(job) do
            result = result + luna.math.sin(i * 0.001)
        end

        output_ch:push(result)
    end
]])

-- ── Thread Lifecycle ──────────────────────────────────────────────────────────

-- start(...) — launch the thread; optional varargs become the worker's "..."
worker:start()            -- no arguments
-- worker:start(1, 2, 3) — pass initial values accessible in worker as "..."

-- isRunning() → boolean
local running = worker:isRunning()

-- wait() — block the main thread until the worker finishes
worker:wait()

-- getError() → string? — nil if no error; error message if the worker crashed
local err = worker:getError()
if err then
    print("Thread failed: " .. err)
end

-- ── Named Channels ────────────────────────────────────────────────────────────

-- getChannel(name) → Channel
-- Named channels are global across all threads; any thread with the same name
-- accesses the same underlying queue.
local work_in  = luna.thread.getChannel("work_in")
local work_out = luna.thread.getChannel("work_out")

-- ── Unnamed (local) Channels ──────────────────────────────────────────────────

-- newChannel() → Channel
-- Creates a fresh unnamed MPMC channel.  Must be passed to workers manually
-- (channels created after newThread('...') won't be visible to the worker).
-- Prefer named channels (getChannel) for most use cases.
local local_ch = luna.thread.newChannel()

-- ── Channel Operations ────────────────────────────────────────────────────────

-- push(value) — enqueue a value; valid types: nil, boolean, number, string
work_in:push("1000000")   -- send a job to the worker
work_in:push(42)          -- a number
work_in:push(true)        -- a boolean
work_in:push(nil)         -- nil is a valid sentinel / empty slot

-- pop() → value? — dequeue the front value; returns nil immediately if empty
local response = work_out:pop()
if response ~= nil then
    print("Worker result: " .. tostring(response))
end

-- peek() → value? — read front value without removing it
local preview = work_out:peek()

-- demand(timeout_seconds?) → value
-- Blocking pop: waits until an item is available.
-- Optional timeout (seconds); returns nil on timeout.
local result = work_out:demand(5.0)   -- wait up to 5 seconds
local result2 = work_out:demand()      -- wait forever

-- supply(value) — push only if the channel is EMPTY (no-op if already has items)
local_ch:supply(42)  -- set a "latest reading" pattern

-- getCount() → integer — number of queued items
local count = work_out:getCount()

-- clear() — discard all queued items
work_out:clear()

-- ── Typical Usage — main game loop with worker ────────────────────────────────

--[[
local result_ch
local compute_worker

function luna.init()
    result_ch = luna.thread.getChannel("results")
    compute_worker = luna.thread.newThread([[
        local jobs = luna.thread.getChannel("jobs")
        local out  = luna.thread.getChannel("results")
        while true do
            local n = jobs:demand()
            if n == -1 then break end
            -- Expensive work
            local sum = 0
            for i = 1, n do sum = sum + luna.math.sqrt(i) end
            out:push(sum)
        end
    ]])
    compute_worker:start()

    -- send the first batch of jobs
    local jobs = luna.thread.getChannel("jobs")
    jobs:push(100000)
    jobs:push(200000)
    jobs:push(-1)  -- sentinel: tell worker to exit
end

local result_text = "Computing..."

function luna.process(dt)
    local r = result_ch:pop()
    if r then
        result_text = "Result: " .. tostring(r)
    end
end

function luna.render()
    luna.gfx.print(result_text, 10, 10)
end
]]

-- ─── ThreadHandle ──────────────────────────────────────────────────────────────

local threadhandle_type = threadhandle:type()  -- "ThreadHandle"
local threadhandle_is_type = threadhandle:typeOf("ThreadHandle")  -- Returns whether this object is of the given type
