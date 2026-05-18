-- content/examples/thread.lua
-- lurek.thread API examples: worker threads, channels, pools, and promises.
-- Run: cargo run -- content/examples/thread.lua

-- =============================================================================
-- Module-level functions
-- =============================================================================

--@api-stub: lurek.thread.newThread
-- Creates a new worker thread that executes a Lua code string on a dedicated OS thread.
do
  -- Use newThread for long-running background tasks like level generation.
  -- The code string runs in a separate VM with access to lurek.thread channels.
  local generator = lurek.thread.newThread([[
    local out = lurek.thread.getChannel("chunks")
    for i = 1, 16 do
      out:push({ chunk_id = i, tiles = {} })
    end
  ]])
  generator:start()
end

--@api-stub: lurek.thread.newChannel
-- Creates a new unbounded channel for sending typed values between threads.
do
  -- Unbounded channels grow as needed — useful for event queues where
  -- you never want producers to block.
  local events = lurek.thread.newChannel()
  events:push({ kind = "enemy_spawned", x = 120, y = 80 })
  events:push({ kind = "pickup_collected", item = "health_potion" })
  local msg = events:pop()
  if msg then
    lurek.log.info("event: " .. msg.kind, "thread")
  end
end

--@api-stub: lurek.thread.newBoundedChannel
-- Creates a bounded channel with a fixed capacity; pushes block when full.
do
  -- Use bounded channels for backpressure: if the consumer is slow,
  -- producers pause instead of flooding memory.
  local render_queue = lurek.thread.newBoundedChannel(8)
  render_queue:tryPush({ cmd = "draw_sprite", id = 1 })
  render_queue:tryPush({ cmd = "draw_sprite", id = 2 })
  local accepted = render_queue:tryPush({ cmd = "draw_sprite", id = 3 })
  lurek.log.info("queued ok=" .. tostring(accepted), "thread")
end

--@api-stub: lurek.thread.getChannel
-- Returns a named shared channel, creating it on first access; same name = same channel.
do
  -- Named channels let unrelated code communicate without passing references.
  -- Workers and the main thread use the same name to share data.
  local jobs = lurek.thread.getChannel("pathfind_requests")
  jobs:push({ from = { x = 0, y = 0 }, to = { x = 50, y = 30 } })
  jobs:push({ from = { x = 10, y = 5 }, to = { x = 60, y = 40 } })
  lurek.log.info("queued " .. jobs:getCount() .. " pathfind jobs", "thread")
end

--@api-stub: lurek.thread.newPool
-- Creates a fixed-size thread pool; workers share an input channel and write to an output channel.
do
  -- Pools are ideal for parallel map generation, AI batch updates, or
  -- any work that splits into independent units.
  local pool = lurek.thread.newPool(4, [[
    local inp = lurek.thread.getChannel("__pool_input")
    local out = lurek.thread.getChannel("__pool_output")
    while true do
      local task = inp:demand()
      if not task then break end
      out:push({ id = task.id, result = task.x * task.x + task.y * task.y })
    end
  ]])
  pool:submit({ id = 1, x = 3, y = 4 })
  pool:submit({ id = 2, x = 5, y = 12 })
end

--@api-stub: lurek.thread.async
-- Runs code or a dumped function asynchronously, returning a promise for the result.
do
  -- Use async for one-shot background computations whose result you poll later.
  local promise = lurek.thread.async([[
    local total = 0
    for i = 1, 1000000 do total = total + i end
    lurek.thread.getChannel("__promise_result"):push(total)
  ]])
  lurek.log.info("async dispatched, done=" .. tostring(promise:isDone()), "thread")

  -- Function form: pass a dumpable function plus arguments
  local fn_promise = lurek.thread.async(function(a, b)
    return (a or 0) + (b or 0)
  end, 20, 22)
  lurek.log.info("fn async dispatched, done=" .. tostring(fn_promise:isDone()), "thread")
end

--@api-stub: lurek.thread.getWorkerCapabilities
-- Returns a list of lurek.* module names available inside worker VMs.
do
  -- Check which engine subsystems workers can access before dispatching work.
  local caps = lurek.thread.getWorkerCapabilities()
  for i = 1, #caps do
    lurek.log.debug("worker capability: " .. caps[i], "thread")
  end
end

-- =============================================================================
-- LThread methods
-- =============================================================================

--@api-stub: LChannel:type
-- Returns the type name string for this thread handle (always "LThread").
do
  local t = lurek.thread.newThread("-- noop")
  lurek.log.info("type = " .. t:type(), "thread")
end

--@api-stub: LChannel:typeOf
-- Checks whether this thread handle matches a given type name.
do
  local t = lurek.thread.newThread("-- noop")
  assert(t:typeOf("LThread"))
  assert(t:typeOf("Object"))
  assert(not t:typeOf("LChannel"))
end

--@api-stub: LThread:start
-- Launches the worker thread; optional arguments become the worker's varargs.
do
  -- Pass initialization data to the worker as varargs.
  -- Inside the worker, access them via `...` or the `arg` table.
  local t = lurek.thread.newThread([[
    local seed, chunk_count = ...
    local out = lurek.thread.getChannel("gen_results")
    for i = 1, chunk_count do
      out:push({ chunk = i, seed = seed + i })
    end
  ]])
  t:start(12345, 8)
end

--@api-stub: LThread:wait
-- Blocks the calling thread until the worker finishes execution.
do
  -- Use wait when you need the result before proceeding (e.g., loading screen).
  local loader = lurek.thread.newThread([[
    lurek.thread.getChannel("level_data"):push({ loaded = true })
  ]])
  loader:start()
  loader:wait()
  lurek.log.info("level data ready", "thread")
end

--@api-stub: LThread:isRunning
-- Returns true if the worker thread is still executing.
do
  -- Poll isRunning in your game loop to show a loading indicator.
  local job = lurek.thread.newThread([[
    -- simulate work
  ]])
  lurek.log.info("before start: running=" .. tostring(job:isRunning()), "thread")
  job:start()
  lurek.log.info("after start: running=" .. tostring(job:isRunning()), "thread")
  job:wait()
  lurek.log.info("after wait: running=" .. tostring(job:isRunning()), "thread")
end

--@api-stub: LPromise:getError
-- Returns the error message if the worker terminated with an error, or nil.
do
  -- Always check getError after wait to handle worker failures gracefully.
  local risky = lurek.thread.newThread([[
    error("out of memory in chunk generator")
  ]])
  risky:start()
  risky:wait()
  local err = risky:getError()
  if err then
    lurek.log.error("worker failed: " .. err, "thread")
  end
end

-- =============================================================================
-- LThreadPool methods
-- =============================================================================

--@api-stub: LChannel:type
-- Returns the type name string for this pool handle (always "LThreadPool").
do
  local pool = lurek.thread.newPool(2, "-- noop")
  lurek.log.info("pool type = " .. pool:type(), "thread")
end

--@api-stub: LChannel:typeOf
-- Checks whether this pool handle matches a given type name.
do
  local pool = lurek.thread.newPool(2, "-- noop")
  assert(pool:typeOf("ThreadPool"))
  assert(pool:typeOf("Object"))
  assert(not pool:typeOf("LChannel"))
end

--@api-stub: LThreadPool:submit
-- Pushes a value into the pool's input channel for processing by a worker.
do
  -- Submit game tasks as tables with an id so you can match results later.
  local pool = lurek.thread.newPool(4, [[
    local inp = lurek.thread.getChannel("__pool_input")
    local out = lurek.thread.getChannel("__pool_output")
    while true do
      local task = inp:demand()
      if task then out:push({ id = task.id, dist = math.sqrt(task.x^2 + task.y^2) }) end
    end
  ]])
  pool:submit({ id = 1, x = 3, y = 4 })
  pool:submit({ id = 2, x = 6, y = 8 })
end

--@api-stub: LThreadPool:collect
-- Pops and returns the next result from the pool's output channel, or nil.
do
  -- Call collect each frame to drain finished results without blocking.
  local pool = lurek.thread.newPool(2, [[
    local inp = lurek.thread.getChannel("__pool_input")
    local out = lurek.thread.getChannel("__pool_output")
    while true do local v = inp:demand(); if v then out:push(v * 2) end end
  ]])
  pool:submit(5)
  pool:submit(10)
  -- In a real game loop you would poll collect every frame:
  local result = pool:collect()
  if result then
    lurek.log.info("pool result: " .. tostring(result), "thread")
  end
end

--@api-stub: LThreadPool:size
-- Returns the number of worker threads in the pool.
do
  -- Use size to calculate backpressure limits or partition work.
  local pool = lurek.thread.newPool(8, "-- worker")
  local inflight_cap = pool:size() * 4
  lurek.log.info("pool has " .. pool:size() .. " workers, cap=" .. inflight_cap, "thread")
end

--@api-stub: LThreadPool:join
-- Blocks until all workers finish or the optional timeout expires.
do
  -- join with a timeout lets you show progress while waiting.
  local pool = lurek.thread.newPool(2, [[
    local n = lurek.thread.getChannel("__pool_input"):demand(0.1)
    if n then lurek.thread.getChannel("__pool_output"):push(n) end
  ]])
  pool:submit(1)
  pool:submit(2)
  local finished = pool:join(1.0)
  lurek.log.info("pool join result: " .. tostring(finished), "thread")
end

--@api-stub: LThreadPool:getInputChannel
-- Returns the pool's shared input channel for direct access.
do
  -- Direct channel access is useful for bulk-enqueue without per-item submit calls.
  local pool = lurek.thread.newPool(4, [[
    local inp = lurek.thread.getChannel("__pool_input")
    local out = lurek.thread.getChannel("__pool_output")
    while true do local v = inp:demand(); if v then out:push(v) end end
  ]])
  local input = pool:getInputChannel()
  for i = 1, 100 do
    input:push(i)
  end
  lurek.log.info("bulk-queued 100 items", "thread")
end

--@api-stub: LThreadPool:getOutputChannel
-- Returns the pool's shared output channel for direct access.
do
  -- Read output channel directly when you want getCount or peek.
  local pool = lurek.thread.newPool(4, "-- worker")
  local out = pool:getOutputChannel()
  lurek.log.info("pending results: " .. out:getCount(), "thread")
end

-- =============================================================================
-- LPromise methods
-- =============================================================================

--@api-stub: LChannel:type
-- Returns the type name string for this promise (always "LPromise").
do
  local p = lurek.thread.async("-- noop")
  lurek.log.info("promise type = " .. p:type(), "thread")
end

--@api-stub: LChannel:typeOf
-- Checks whether this promise matches a given type name.
do
  local p = lurek.thread.async("-- noop")
  assert(p:typeOf("Promise"))
  assert(p:typeOf("Object"))
  assert(not p:typeOf("LChannel"))
end

--@api-stub: LPromise:isDone
-- Returns true if the async computation has completed (success or error).
do
  -- Poll isDone each frame to know when the result is available.
  local p = lurek.thread.async([[
    lurek.thread.getChannel("__promise_result"):push(42)
  ]])
  lurek.log.info("promise done=" .. tostring(p:isDone()), "thread")
end

--@api-stub: LPromise:result
-- Returns the computed result value, or nil if not yet done.
do
  -- Retrieve the result once isDone is true.
  local p = lurek.thread.async([[
    lurek.thread.getChannel("__promise_result"):push({ score = 999 })
  ]])
  -- In a real game loop, poll each frame:
  local r = p:result()
  if r then
    lurek.log.info("async result received", "thread")
  end
end

--@api-stub: LPromise:getError
-- Returns the error string if the promise failed, or nil on success.
do
  -- Always check getError if result returns nil after isDone.
  local p = lurek.thread.async("error('worker crashed')")
  -- After some time:
  if p:isDone() and not p:result() then
    local err = p:getError()
    if err then lurek.log.error("async error: " .. err, "thread") end
  end
end

--@api-stub: LPromise:chain
-- Creates a new promise that runs after this promise resolves, receiving its result.
do
  -- Chain lets you build async pipelines: load -> parse -> apply.
  -- Note: chain() requires the parent promise to be completed (isDone() true).
  -- This example demonstrates the API shape only.
  local load_promise = lurek.thread.async([[return "level_data_bytes"]])
  -- chain() would be called once load_promise:isDone() is true:
  -- local parse_promise = load_promise:chain([[ local result = ... ]])
  lurek.log.info("chain: parent promise created, done=" .. tostring(load_promise:isDone()), "thread")
end

-- =============================================================================
-- LChannel methods
-- =============================================================================

--@api-stub: LChannel:type
-- Returns the type name string for this channel (always "LChannel").
do
  local ch = lurek.thread.newChannel()
  lurek.log.info("channel type = " .. ch:type(), "thread")
end

--@api-stub: LChannel:typeOf
-- Checks whether this channel matches a given type name.
do
  local ch = lurek.thread.newChannel()
  assert(ch:typeOf("LChannel"))
  assert(ch:typeOf("Object"))
  assert(not ch:typeOf("LThread"))
end

--@api-stub: LChannel:push
-- Pushes a value onto the channel; blocks on bounded channels if full.
do
  -- Push game events for workers to process.
  -- Returns a sequence ID you can use for ordering or acknowledgment.
  local events = lurek.thread.getChannel("game_events")
  local seq1 = events:push({ kind = "enemy_killed", id = 17 })
  local seq2 = events:push({ kind = "score_delta", value = 100 })
  lurek.log.info("pushed seq " .. seq1 .. " and " .. seq2, "thread")
end

--@api-stub: LChannel:pop
-- Removes and returns the next value without blocking; returns nil if empty.
do
  -- Drain the channel each frame to process all pending messages.
  local events = lurek.thread.getChannel("game_events")
  events:push({ kind = "test" })
  local ev = events:pop()
  while ev do
    lurek.log.debug("processing: " .. ev.kind, "thread")
    ev = events:pop()
  end
end

--@api-stub: LChannel:peek
-- Returns the front value without removing it; nil if empty.
do
  -- Peek lets you inspect the next item before deciding to consume it.
  local jobs = lurek.thread.getChannel("priority_jobs")
  jobs:push({ priority = "high", task = "save_game" })
  ---@type {priority:string, task:string}?
  local next_job = jobs:peek()
  if next_job and next_job.priority == "high" then
    lurek.log.info("high-priority job waiting", "thread")
  end
end

--@api-stub: LChannel:demand
-- Blocks until a value is available or the optional timeout expires.
do
  -- demand is used inside workers to wait for incoming tasks.
  -- With a timeout, workers can gracefully exit when idle.
  local worker = lurek.thread.newThread([[
    local inbox = lurek.thread.getChannel("worker_inbox")
    local msg = inbox:demand(1.0)
    if msg then
      lurek.thread.getChannel("worker_results"):push("processed: " .. tostring(msg))
    end
  ]])
  lurek.thread.getChannel("worker_inbox"):push("hello")
  worker:start()
end

--@api-stub: LChannel:getCount
-- Returns the number of values currently queued in the channel.
do
  -- Use getCount for backpressure: stop submitting when the queue is deep.
  local jobs = lurek.thread.getChannel("ai_requests")
  jobs:push({ entity = 1 })
  jobs:push({ entity = 2 })
  if jobs:getCount() < 64 then
    jobs:push({ entity = 3 })
  end
  lurek.log.info("queued: " .. jobs:getCount(), "thread")
end

--@api-stub: LChannel:getCapacity
-- Returns the max capacity of a bounded channel, or nil for unbounded.
do
  local bounded = lurek.thread.newBoundedChannel(16)
  local unbounded = lurek.thread.newChannel()
  lurek.log.info("bounded cap=" .. tostring(bounded:getCapacity()), "thread")
  lurek.log.info("unbounded cap=" .. tostring(unbounded:getCapacity()), "thread")
end

--@api-stub: LChannel:isBounded
-- Returns true if this channel has a fixed capacity limit.
do
  local a = lurek.thread.newChannel()
  local b = lurek.thread.newBoundedChannel(4)
  lurek.log.info("unbounded: " .. tostring(a:isBounded()), "thread")
  lurek.log.info("bounded: " .. tostring(b:isBounded()), "thread")
end

--@api-stub: LChannel:tryPush
-- Attempts to push without blocking; returns false if the bounded channel is full.
do
  -- tryPush is non-blocking — use it on the main thread to avoid stalls.
  local bounded = lurek.thread.newBoundedChannel(2)
  bounded:tryPush("frame_1")
  bounded:tryPush("frame_2")
  local ok = bounded:tryPush("frame_3")
  lurek.log.info("3rd push accepted=" .. tostring(ok), "thread")
end

--@api-stub: LChannel:clear
-- Removes all pending values from the channel.
do
  -- Clear stale messages when transitioning scenes.
  local stale = lurek.thread.getChannel("scene_events")
  stale:push({ kind = "old_scene_event" })
  stale:push({ kind = "another_old_event" })
  stale:clear()
  assert(stale:getCount() == 0)
  lurek.log.info("channel cleared for new scene", "thread")
end

--@api-stub: LChannel:supply
-- Pushes a value and blocks until a consumer pops it (synchronous handoff).
do
  -- supply guarantees the consumer received the value before you continue.
  -- Useful for request-reply patterns between threads.
  local handoff = lurek.thread.getChannel("handoff_demo")
  -- In a real scenario, a worker would be waiting to pop from this channel.
  -- supply blocks until that pop happens:
  -- handoff:supply({ request = "generate_chunk", id = 5 })
  lurek.log.info("supply: use for synchronous handoff to a waiting consumer", "thread")
end

--@api-stub: LChannel:pushTable
-- Pushes a table value, raising an error if the value is not a table.
do
  -- pushTable is a type-safe alternative to push when you know the value is a table.
  local ch = lurek.thread.getChannel("net_packets")
  ch:pushTable({ op = "spawn", x = 64, y = 32, entity = "goblin" })
  ch:pushTable({ op = "move", id = 7, dx = 1, dy = 0 })
end

--@api-stub: LChannel:popTable
-- Pops the next value only if it is a table; discards non-table values.
do
  -- popTable filters out non-table noise from a mixed channel.
  local ch = lurek.thread.getChannel("net_packets")
  ch:pushTable({ op = "attack", target = 3 })
  local pkt = ch:popTable()
  if pkt then
    lurek.log.info("got packet op=" .. pkt.op, "thread")
  end
end

--@api-stub: LChannel:pushBytes
-- Pushes raw binary data onto the channel as a byte blob.
do
  -- pushBytes is efficient for serialized network frames or compressed data.
  local net_out = lurek.thread.getChannel("net_out")
  local header = string.char(0x01, 0x00, 0x00, 0x10)
  local payload = string.rep("\0", 16)
  net_out:pushBytes(header .. payload)
  lurek.log.info("sent " .. #(header .. payload) .. " bytes", "thread")
end

--@api-stub: LChannel:popBytes
-- Pops the next value only if it is a byte blob; discards non-bytes values.
do
  -- popBytes pairs with pushBytes for binary protocol channels.
  local net_in = lurek.thread.getChannel("net_in")
  net_in:pushBytes("\xDE\xAD\xBE\xEF")
  local bytes = net_in:popBytes()
  if bytes then
    lurek.log.info("received " .. #bytes .. " bytes", "thread")
  end
end

print("content/examples/thread.lua")

-- =============================================================================
-- STUBS: 7 uncovered lurek.thread API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LPromise methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LPromise:type -------------------------------------------------
--@api-stub: LPromise:type
-- Returns the type name of this object.
do
  local obj = lurek.thread.async(function() return 42 end)
  lurek.log.debug("type: " .. obj:type(), "example") -- "LPromise"
end

-- ---- Stub: LPromise:typeOf -----------------------------------------------
--@api-stub: LPromise:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.thread.async(function() return 42 end)
  lurek.log.debug("typeOf LPromise: " .. tostring(obj:typeOf("LPromise")), "example") -- true
end

-- -----------------------------------------------------------------------------
-- LThread methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LThread:type --------------------------------------------------
--@api-stub: LThread:type
-- Returns the type name of this object.
do
  local obj = lurek.thread.newThread("return 42")
  lurek.log.debug("type: " .. obj:type(), "example") -- "LThread"
end

-- ---- Stub: LThread:typeOf ------------------------------------------------
--@api-stub: LThread:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.thread.newThread("return 42")
  lurek.log.debug("typeOf LThread: " .. tostring(obj:typeOf("LThread")), "example") -- true
end

-- ---- Stub: LThread:getError ----------------------------------------------
--@api-stub: LThread:getError
-- Returns the error message from the worker thread, if it terminated with an error.
do
  local t = lurek.thread.newThread("error('intentional test error')")
  t:start()
  t:wait()
  local err = t:getError()
  lurek.log.debug("thread error: " .. tostring(err), "thread")
end

-- -----------------------------------------------------------------------------
-- LThreadPool methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LThreadPool:type ----------------------------------------------
--@api-stub: LThreadPool:type
-- Returns the type name of this object.
do
  local obj = lurek.thread.newPool(2, "worker")
  lurek.log.debug("type: " .. obj:type(), "example") -- "LThreadPool"
end

-- ---- Stub: LThreadPool:typeOf --------------------------------------------
--@api-stub: LThreadPool:typeOf
-- Checks whether this object matches the given type name.
do
  local obj = lurek.thread.newPool(2, "worker")
  lurek.log.debug("typeOf LThreadPool: " .. tostring(obj:typeOf("LThreadPool")), "example") -- true
end
