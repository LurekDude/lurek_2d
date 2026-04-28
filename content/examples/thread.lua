-- content/examples/thread.lua
-- Hand-written coverage of the lurek.thread API (37 items).
--
-- Threads run in isolated Lua VMs and cannot share upvalues, so all
-- cross-VM communication goes through Channels: pass a Lua source
-- string to newThread/newPool/async, then push/pop work and results
-- through named channels (lurek.thread.getChannel("queue_name")).
--
-- Run: cargo run -- content/examples/thread.lua

-- ── lurek.thread.* functions ──

--@api-stub: lurek.thread.newThread
-- Creates a new background thread from a Lua code string.
-- Pair with :start() to launch; the code string runs in a fresh VM with no access to main-thread state.
do  -- lurek.thread.newThread
  local worker = lurek.thread.newThread([[
    local q = lurek.thread.getChannel("work_queue")
    q:push("hello from worker")
  ]])
  worker:start()
end

--@api-stub: lurek.thread.newChannel
-- Creates an unnamed thread-safe channel for inter-thread communication.
-- Use unnamed channels when you want the channel scoped to a single thread group; pass it via :start() args.
do  -- lurek.thread.newChannel
  local ch = lurek.thread.newChannel()
  ch:push({ event = "spawn", x = 100, y = 50 })
  local msg = ch:pop()
  lurek.log.info("event=" .. msg.event, "thread") ---@diagnostic disable-line: undefined-field
end

--@api-stub: lurek.thread.getChannel
-- Gets or creates a named global channel shared across threads.
-- Same name returns the same channel anywhere; this is how a worker VM finds the main thread's queue.
do  -- lurek.thread.getChannel
  local jobs = lurek.thread.getChannel("work_queue")
  jobs:push({ task = "load_chunk", id = 42 })
  jobs:push({ task = "load_chunk", id = 43 })
end

--@api-stub: lurek.thread.newPool
-- Creates a thread pool of N workers all running the same Lua code.
-- Workers pull from getChannel("__pool_input") and push to getChannel("__pool_output"); use pool:submit/:collect from main.
do  -- lurek.thread.newPool
  local pool = lurek.thread.newPool(4, [[
    local inp = lurek.thread.getChannel("__pool_input")
    local out = lurek.thread.getChannel("__pool_output")
    while true do local n = inp:demand(); out:push(n * n) end
  ]])
  pool:submit(7)
end

--@api-stub: lurek.thread.async
-- Starts a one-shot background computation and returns a Promise.
-- Use for fire-and-forget jobs whose single result you'll poll for next frame; the worker pushes via "__promise_result".
do  -- lurek.thread.async
  local promise = lurek.thread.async([[
    local total = 0
    for i = 1, 1000000 do total = total + i end
    lurek.thread.getChannel("__promise_result"):push(total)
  ]])
  lurek.log.info("checksum job dispatched", "thread")
end

-- ── ThreadHandle methods ──

--@api-stub: ThreadHandle:type
-- Returns the type name of this object.
-- Useful for runtime polymorphism when a function might receive a Thread, Channel, or Promise.
do  -- ThreadHandle:type
  local t = lurek.thread.newThread("-- noop")
  if t:type() == "LThread" then
    lurek.log.debug("got a thread handle", "thread")
  end
end

--@api-stub: ThreadHandle:typeOf
-- Returns whether this object is of the given type.
-- Accepts "LThread", the legacy alias, or "Object"; use to validate args in helper functions that wrap thread management.
do  -- ThreadHandle:typeOf
  local t = lurek.thread.newThread("-- noop")
  assert(t:typeOf("LThread"))
  assert(t:typeOf("Object"))
end

--@api-stub: ThreadHandle:start
-- Launches the background thread, passing optional arguments via varargs.
-- Args go through the channel-value conversion (numbers/strings/booleans/tables only); use ... in worker code to read them.
do  -- ThreadHandle:start
  local t = lurek.thread.newThread([[
    local seed, count = ...
    lurek.thread.getChannel("results"):push(seed + count)
  ]])
  t:start(100, 25)
end

--@api-stub: ThreadHandle:wait
-- Blocks the calling thread until the background thread finishes.
-- Avoid calling wait() in lurek.process — it stalls the frame; reserve for shutdown or once-per-level loads.
do  -- ThreadHandle:wait
  local loader = lurek.thread.newThread([[
    lurek.thread.getChannel("level_data"):push("ready")
  ]])
  loader:start()
  loader:wait()
end

--@api-stub: ThreadHandle:isRunning
-- Returns whether the thread is currently executing.
-- Poll once per frame from lurek.process to drive a non-blocking "loading" state without :wait().
do  -- ThreadHandle:isRunning
  local job = lurek.thread.newThread("-- background work")
  job:start()
  if job:isRunning() then
    lurek.log.debug("still loading...", "thread")
  end
end

--@api-stub: ThreadHandle:getError
-- Returns the error message if the thread failed, or nil.
-- Always check after :wait() or once isRunning() turns false; worker errors are silent otherwise.
do  -- ThreadHandle:getError
  local job = lurek.thread.newThread("error('boom')")
  job:start()
  job:wait()
  local err = job:getError()
  if err then lurek.log.error("worker failed: " .. err, "thread") end
end

-- ── ThreadPool methods ──

--@api-stub: LThreadPool:type
-- Returns the type name of this object.
-- Returns "ThreadPool"; handy in generic dispatchers that handle several lurek.thread userdata kinds.
do  -- ThreadPool:type
  local pool = lurek.thread.newPool(2, "-- noop")
  if pool:type() == "ThreadPool" then
    lurek.log.debug("pool ready", "thread")
  end
end

--@api-stub: LThreadPool:typeOf
-- Returns whether this object is of the given type.
-- Use to guard helpers that only accept pools (vs single Thread handles) before calling :submit.
do  -- ThreadPool:typeOf
  local pool = lurek.thread.newPool(2, "-- noop")
  assert(pool:typeOf("ThreadPool"))
end

--@api-stub: LThreadPool:submit
-- Submits a value to the pool's input channel for processing by a worker.
-- One value per call; pack multiple fields into a table when a job needs structured input.
do  -- ThreadPool:submit
  local pool = lurek.thread.newPool(4, [[
    local inp = lurek.thread.getChannel("__pool_input")
    local out = lurek.thread.getChannel("__pool_output")
    while true do out:push(inp:demand() * 2) end
  ]])
  pool:submit({ id = 1, payload = "tile_chunk_a" })
  pool:submit({ id = 2, payload = "tile_chunk_b" })
end

--@api-stub: LThreadPool:collect
-- Retrieves the next result from the pool's output channel (non-blocking).
-- Drain in a loop from lurek.process — collect returns nil when the queue is empty so the frame never stalls.
do  -- ThreadPool:collect
  local pool = lurek.thread.newPool(2, "-- worker")
  function lurek.process(_)
    local result = pool:collect()
    while result do
      lurek.log.debug("got result", "thread")
      result = pool:collect()
    end
  end
end

--@api-stub: LThreadPool:size
-- Returns the number of workers in this pool.
-- Useful for sizing back-pressure: don't submit more in-flight jobs than 4× the worker count.
do  -- ThreadPool:size
  local pool = lurek.thread.newPool(8, "-- worker")
  local max_inflight = pool:size() * 4
  lurek.log.info("backpressure cap = " .. max_inflight, "thread")
end

--@api-stub: LThreadPool:join
-- Blocks until all workers in the pool have finished execution.
-- Call only on shutdown — workers in busy loops never finish on their own; push a sentinel value first if needed.
do  -- ThreadPool:join
  local pool = lurek.thread.newPool(2, [[
    local n = lurek.thread.getChannel("__pool_input"):pop()
    if n then lurek.thread.getChannel("__pool_output"):push(n) end
  ]])
  pool:submit(1); pool:submit(2)
  pool:join()
end

--@api-stub: LThreadPool:getInputChannel
-- Returns the shared input Channel (main → workers).
-- Grab the raw channel when you want to push many items at once or use :supply() for back-pressure.
do  -- ThreadPool:getInputChannel
  local pool = lurek.thread.newPool(4, "-- worker")
  local input = pool:getInputChannel()
  for i = 1, 100 do input:push(i) end
end

--@api-stub: LThreadPool:getOutputChannel
-- Returns the shared output Channel (workers → main).
-- Inspect getCount() on it to monitor worker throughput, or use demand(timeout) in a sync drain.
do  -- ThreadPool:getOutputChannel
  local pool = lurek.thread.newPool(4, "-- worker")
  local out = pool:getOutputChannel()
  lurek.log.debug("pending results: " .. out:getCount(), "thread")
end

-- ── Promise methods ──

--@api-stub: LPromise:type
-- Returns the type name of this object.
-- Returns "Promise"; useful in generic awaiter helpers.
do  -- Promise:type
  local p = lurek.thread.async("-- noop")
  if p:type() == "Promise" then
    lurek.log.debug("promise dispatched", "thread")
  end
end

--@api-stub: LPromise:typeOf
-- Returns whether this object is of the given type.
-- Accepts "Promise" or "Object"; guards generic dispatch over thread userdata.
do  -- Promise:typeOf
  local p = lurek.thread.async("-- noop")
  assert(p:typeOf("Promise"))
end

--@api-stub: LPromise:isDone
-- Returns true if the promise has a result or has errored (non-blocking).
-- Poll from lurek.process to avoid blocking the frame; pair with :result() once true.
do  -- Promise:isDone
  local p = lurek.thread.async([[
    lurek.thread.getChannel("__promise_result"):push(42)
  ]])
  if p:isDone() then
    lurek.log.info("promise ready", "thread")
  end
end

--@api-stub: LPromise:result
-- Pops and returns the promise result, or nil if not yet ready.
-- Returns the value the worker pushed into "__promise_result"; check :getError() if nil persists.
do  -- Promise:result
  local p = lurek.thread.async([[
    lurek.thread.getChannel("__promise_result"):push({ score = 999 })
  ]])
  function lurek.process(_)
    local r = p:result()
    if r then lurek.log.info("score=" .. r.score, "thread") end
  end
end

--@api-stub: LPromise:getError
-- Returns the worker error string if the promise failed, otherwise nil.
-- Inspect after :isDone() returns true and :result() returns nil — that combination signals a worker crash.
do  -- Promise:getError
  local p = lurek.thread.async("error('worker died')")
  function lurek.process(_)
    if p:isDone() and not p:result() then
      lurek.log.error("async failed: " .. (p:getError() or "?"), "thread")
    end
  end
end

-- ── Channel methods ──

--@api-stub: LChannel:type
-- Returns the type of the object.
-- Returns "LChannel"; useful for runtime checks in generic message routers.
do  -- Channel:type
  local ch = lurek.thread.newChannel()
  if ch:type() == "LChannel" then
    lurek.log.debug("got a channel", "thread")
  end
end

--@api-stub: LChannel:typeOf
-- Checks if the object is of the specified type.
-- Accepts "LChannel", the legacy alias, or "Object"; guards helpers that wrap channel send/receive.
do  -- Channel:typeOf
  local ch = lurek.thread.newChannel()
  assert(ch:typeOf("LChannel"))
end

--@api-stub: LChannel:push
-- Pushes a value to the channel.
-- Non-blocking; returns the message id. Values are deep-copied across the VM boundary so mutating after push is safe.
do  -- Channel:push
  local events = lurek.thread.getChannel("game_events")
  events:push({ kind = "enemy_killed", id = 17 })
  events:push({ kind = "score_delta", value = 100 })
end

--@api-stub: LChannel:pop
-- Retrieves and removes a value from the channel.
-- Non-blocking; returns nil when empty. Drain in a while loop each frame to process all pending messages.
do  -- Channel:pop
  local events = lurek.thread.getChannel("game_events")
  function lurek.process(_)
    local ev = events:pop()
    while ev do ev = events:pop() end
  end
end

--@api-stub: LChannel:peek
-- Retrieves the value from the channel without removing it.
-- Use to look at the next message without consuming it — handy for priority routing before committing to handle.
do  -- Channel:peek
  local jobs = lurek.thread.getChannel("work_queue")
  jobs:push({ priority = "high", task = "save" })
  local next_job = jobs:peek()
  if next_job and next_job.priority == "high" then ---@diagnostic disable-line: undefined-field
    lurek.log.info("high-priority job pending", "thread")
  end
end

--@api-stub: LChannel:demand
-- Blocks until a value is available or the timeout expires, then removes and returns it.
-- Pass a timeout in seconds (or nil to block forever); used inside worker loops, never on the main frame thread.
do  -- Channel:demand
  local worker = lurek.thread.newThread([[
    local inbox = lurek.thread.getChannel("worker_inbox")
    local msg = inbox:demand(1.0)
    if msg then lurek.thread.getChannel("results"):push("ack") end
  ]])
  worker:start()
end

--@api-stub: LChannel:getCount
-- Returns the number of items in the channel.
-- Use for back-pressure: stop submitting new jobs once the queue exceeds a budget.
do  -- Channel:getCount
  local jobs = lurek.thread.getChannel("work_queue")
  if jobs:getCount() < 64 then
    jobs:push({ task = "stream_chunk" })
  end
end

--@api-stub: LChannel:clear
-- Clears all items from the channel.
-- Useful between levels or after cancelling a long-running batch — drops every pending message at once.
do  -- Channel:clear
  local stale = lurek.thread.getChannel("level_events")
  stale:push({ kind = "old" })
  stale:clear()
  assert(stale:getCount() == 0)
end

--@api-stub: LChannel:supply
-- Blocks until the channel has space, then adds the value.
-- Currently unbounded, so behaves like push(); prefer it for code paths that may later add capacity limits.
do  -- Channel:supply
  local out = lurek.thread.getChannel("worker_results")
  out:supply({ tile = 1, ok = true })
  out:supply({ tile = 2, ok = true })
end

--@api-stub: LChannel:pushTable
-- Serializes a Lua table and pushes it to the channel.
-- Same as push() for tables but errors loudly if the value isn't a table — use to enforce a structured-message contract.
do  -- Channel:pushTable
  local ch = lurek.thread.getChannel("packets")
  ch:pushTable({ op = "spawn", x = 64, y = 32, kind = "goblin" })
end

--@api-stub: LChannel:popTable
-- Pops a value from the channel expecting a table.
-- Returns nil if the next item isn't a table — non-table messages are dropped silently, so use only on table-only channels.
do  -- Channel:popTable
  local ch = lurek.thread.getChannel("packets")
  ch:pushTable({ op = "spawn", id = 7 })
  local pkt = ch:popTable()
  if pkt then lurek.log.info("op=" .. pkt.op, "thread") end
end

--@api-stub: LChannel:pushBytes
-- Pushes raw binary data (a Lua string treated as a byte array) to the channel.
-- Use for serialised buffers (image data, save blobs) where you don't want Lua-string interning churn on the worker side.
do  -- Channel:pushBytes
  local stream = lurek.thread.getChannel("net_out")
  local payload = string.char(0xDE, 0xAD, 0xBE, 0xEF)
  stream:pushBytes(payload)
end

--@api-stub: LChannel:popBytes
-- Pops a bytes value from the channel and returns it as a Lua string.
-- Returns nil if the next item isn't bytes; pair with pushBytes on the producer side and treat the result as opaque.
do  -- Channel:popBytes
  local stream = lurek.thread.getChannel("net_in")
  stream:pushBytes("\x01\x02\x03")
  local bytes = stream:popBytes()
  if bytes then lurek.log.debug("got " .. #bytes .. " bytes", "thread") end
end

-- =============================================================================
-- STUBS: 32 uncovered lurek.thread API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- LThread methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LThread:type --------------------------------------------------
--@api-stub: LThread:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
do  -- LThread:type
  local thread_obj = lurek.thread.newThread("worker")
  local t = thread_obj:type()
  lurek.log.info("LThread:type = " .. t, "thread")
end
--@api-stub: LThread:typeOf
-- Returns whether this object is of the given type.
-- Use for runtime type checks.
do  -- LThread:typeOf
  local thread_obj2 = lurek.thread.newThread("worker")
  lurek.log.info("is LThread: " .. tostring(thread_obj2 and thread_obj2:typeOf("LThread") or false), "thread")
  lurek.log.info("is wrong: " .. tostring(thread_obj2 and thread_obj2:typeOf("Unknown") or false), "thread")
end
--@api-stub: LThread:start
-- Launches the background thread, passing optional arguments via varargs.
-- Use to offload CPU-heavy work (path-find, PCG) off the main game loop thread.
do  -- LThread:start
  local t = lurek.thread.newThread([[
    local ch = lurek.thread.getChannel("result")
    ch:push(42)
  ]])
  t:start()
  lurek.log.info("thread started, running=" .. tostring(t:isRunning()), "thread")
  t:wait()
end
--@api-stub: LThread:wait
-- Blocks the calling thread until the background thread finishes.
-- Use after start() to synchronise results before reading shared state.
do  -- LThread:wait
  local t = lurek.thread.newThread([[
    -- lightweight worker
  ]])
  t:start()
  t:wait()   -- block until done
  lurek.log.info("thread finished, err=" .. tostring(t:getError()), "thread")
end
--@api-stub: LThread:isRunning
-- Returns whether the thread is currently executing.
-- Poll this instead of blocking when you want a non-blocking status check.
do  -- LThread:isRunning
  local t = lurek.thread.newThread([[
    -- minimal worker
  ]])
  lurek.log.info("before start: " .. tostring(t:isRunning()), "thread")
  t:start()
  lurek.log.info("after start: " .. tostring(t:isRunning()), "thread")
  t:wait()
end
--@api-stub: LThread:getError
-- Returns the error message if the thread failed, or nil.
-- Always check this after wait() to detect worker-side runtime errors.
do  -- LThread:getError
  local t = lurek.thread.newThread([[
    -- safe worker; no error expected
  ]])
  t:start()
  t:wait()
  local err = t:getError()
  if err then
    lurek.log.info("thread error: " .. err, "thread")
  else
    lurek.log.info("thread completed cleanly", "thread")
  end
end
