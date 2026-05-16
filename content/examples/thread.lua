-- content/examples/thread.lua
-- lurek.thread API examples.
-- Run: cargo run -- content/examples/thread.lua

--@api-stub: lurek.thread.newThread
-- Creates a new worker thread that will execute the given Lua code string when started
do
  local worker = lurek.thread.newThread([[
    local q = lurek.thread.getChannel("work_queue")
    q:push("hello from worker")
  ]])
  worker:start()
end

--@api-stub: lurek.thread.newChannel
-- Creates a new unbounded channel for sending typed values between threads
do
  local ch = lurek.thread.newChannel()
  ch:push({ event = "spawn", x = 100, y = 50 })
  local msg = ch:pop()
  lurek.log.info("event=" .. msg.event, "thread") ---@diagnostic disable-line: undefined-field
end

--@api-stub: lurek.thread.newBoundedChannel
-- Creates a new bounded channel with a fixed capacity, blocking pushes when full
do
  local new_bounded = lurek.thread["newBoundedChannel"]
  local ch = new_bounded(2)
  ch:tryPush("a")
  ch:tryPush("b")
  local pushed = ch:tryPush("c")
  lurek.log.info("bounded push accepted=" .. tostring(pushed), "thread")
end

--@api-stub: lurek.thread.getChannel
-- Returns a named shared channel, creating it on first access
do
  local jobs = lurek.thread.getChannel("work_queue")
  jobs:push({ task = "load_chunk", id = 42 })
  jobs:push({ task = "load_chunk", id = 43 })
end

--@api-stub: lurek.thread.newPool
-- Creates a fixed-size thread pool where each worker runs the same Lua code and consumes items from a shared input channel
do
  local pool = lurek.thread.newPool(4, [[
    local inp = lurek.thread.getChannel("__pool_input")
    local out = lurek.thread.getChannel("__pool_output")
    while true do local n = inp:demand(); out:push(n * n) end
  ]])
  pool:submit(7)
end

--@api-stub: lurek.thread.async
-- Runs a Lua code string or dumped function asynchronously on a new worker thread, returning a promise for the result
do
  local promise = lurek.thread.async([[
    local total = 0
    for i = 1, 1000000 do total = total + i end
    lurek.thread.getChannel("__promise_result"):push(total)
  ]])
  lurek.log.info("checksum job dispatched", "thread")

  -- Function form: async(fn, ...)
  local async_any = lurek.thread["async"] --[[@as any]]
  local promise_fn = async_any(function(a, b)
    return (a or 0) + (b or 0)
  end, 20, 22)
  lurek.log.info("function async dispatched: " .. tostring(promise_fn:isDone()), "thread")
end

--@api-stub: lurek.thread.getWorkerCapabilities
-- Returns a list of capability names available inside worker VMs (e
do
  local caps = lurek.thread["getWorkerCapabilities"]()
  for i = 1, #caps do
    lurek.log.debug("worker api: " .. caps[i], "thread")
  end
end

-- ThreadHandle methods

--@api-stub: ThreadHandle:type
-- Returns the Lua-visible type name string for this thread handle handle.
do
  local t = lurek.thread.newThread("-- noop")
  if t:type() == "LThread" then
    lurek.log.debug("got a thread handle", "thread")
  end
end

--@api-stub: ThreadHandle:typeOf
-- Returns true if this thread handle handle matches the given type name string.
do
  local t = lurek.thread.newThread("-- noop")
  assert(t:typeOf("LThread"))
  assert(t:typeOf("Object"))
end

--@api-stub: ThreadHandle:start
-- Starts the operation managed by this thread handle.
do
  local t = lurek.thread.newThread([[
    local seed, count = ...
    lurek.thread.getChannel("results"):push(seed + count)
  ]])
  t:start(100, 25)
end

--@api-stub: ThreadHandle:wait
-- Blocks until this thread handle finishes its current operation.
do
  local loader = lurek.thread.newThread([[
    lurek.thread.getChannel("level_data"):push("ready")
  ]])
  loader:start()
  loader:wait()
end

--@api-stub: ThreadHandle:isRunning
-- Returns true if this thread handle is currently running.
do
  local job = lurek.thread.newThread("-- background work")
  job:start()
  if job:isRunning() then
    lurek.log.debug("still loading...", "thread")
  end
end

--@api-stub: ThreadHandle:getError
-- Returns the error of this thread handle.
do
  local job = lurek.thread.newThread("error('boom')")
  job:start()
  job:wait()
  local err = job:getError()
  if err then lurek.log.error("worker failed: " .. err, "thread") end
end

-- ThreadPool methods

--@api-stub: ThreadPool:type
-- Returns the Lua-visible type name string for this thread pool handle.
do
  local pool = lurek.thread.newPool(2, "-- noop")
  if pool:type() == "ThreadPool" then
    lurek.log.debug("pool ready", "thread")
  end
end

--@api-stub: ThreadPool:typeOf
-- Returns true if this thread pool handle matches the given type name string.
do
  local pool = lurek.thread.newPool(2, "-- noop")
  assert(pool:typeOf("ThreadPool"))
end

--@api-stub: ThreadPool:submit
-- Submits a task for execution by this thread pool.
do
  local pool = lurek.thread.newPool(4, [[
    local inp = lurek.thread.getChannel("__pool_input")
    local out = lurek.thread.getChannel("__pool_output")
    while true do out:push(inp:demand() * 2) end
  ]])
  pool:submit({ id = 1, payload = "tile_chunk_a" })
  pool:submit({ id = 2, payload = "tile_chunk_b" })
end

--@api-stub: ThreadPool:collect
-- Collects and returns all completed task results from this thread pool.
do
  local pool = lurek.thread.newPool(2, "-- worker")
  function lurek.process(_)
    local result = pool:collect()
    while result do
      lurek.log.debug("got result", "thread")
      result = pool:collect()
    end
  end
end

--@api-stub: ThreadPool:size
-- Returns the current size of this thread pool.
do
  local pool = lurek.thread.newPool(8, "-- worker")
  local max_inflight = pool:size() * 4
  lurek.log.info("backpressure cap = " .. max_inflight, "thread")
end

--@api-stub: ThreadPool:join
-- Blocks until this thread pool finishes its current operation.
do
  local pool = lurek.thread.newPool(2, [[
    local n = lurek.thread.getChannel("__pool_input"):pop()
    if n then lurek.thread.getChannel("__pool_output"):push(n) end
  ]])
  pool:submit(1); pool:submit(2)
  local join_any = pool["join"] --[[@as any]]
  local done = join_any(pool, 0.25)
  lurek.log.info("pool joined=" .. tostring(done), "thread")
end

--@api-stub: ThreadPool:getInputChannel
-- Returns the input channel of this thread pool.
do
  local pool = lurek.thread.newPool(4, "-- worker")
  local input = pool:getInputChannel()
  for i = 1, 100 do input:push(i) end
end

--@api-stub: ThreadPool:getOutputChannel
-- Returns the output channel of this thread pool.
do
  local pool = lurek.thread.newPool(4, "-- worker")
  local out = pool:getOutputChannel()
  lurek.log.debug("pending results: " .. out:getCount(), "thread")
end

-- Promise methods

--@api-stub: Promise:type
-- Returns the Lua-visible type name string for this promise handle.
do
  local p = lurek.thread.async("-- noop")
  if p:type() == "Promise" then
    lurek.log.debug("promise dispatched", "thread")
  end
end

--@api-stub: Promise:typeOf
-- Returns true if this promise handle matches the given type name string.
do
  local p = lurek.thread.async("-- noop")
  assert(p:typeOf("Promise"))
end

--@api-stub: Promise:isDone
-- Returns true if this promise has completed its task.
do
  local p = lurek.thread.async([[
    lurek.thread.getChannel("__promise_result"):push(42)
  ]])
  if p:isDone() then
    lurek.log.info("promise ready", "thread")
  end
end

--@api-stub: Promise:result
-- Performs the result operation on this promise.
do
  local p = lurek.thread.async([[
    lurek.thread.getChannel("__promise_result"):push({ score = 999 })
  ]])
  function lurek.process(_)
    local r = p:result()
    if r then lurek.log.info("score=" .. r.score, "thread") end
  end
end

--@api-stub: Promise:getError
-- Returns the error of this promise.
do
  local p = lurek.thread.async("error('worker died')")
  function lurek.process(_)
    if p:isDone() and not p:result() then
      lurek.log.error("async failed: " .. (p:getError() or "?"), "thread")
    end
  end
end

--@api-stub: Promise:chain
-- Chains a callback to run after this promise promise resolves.
do
  local p1 = lurek.thread.async([[lurek.thread.getChannel("__promise_result"):push(10)]])
  function lurek.process(_)
    if p1:isDone() then
      local p2 = p1["chain"](p1, [[lurek.thread.getChannel("__promise_result"):push((arg[1] or 0) + 5)]])
      lurek.log.info("chained promise active=" .. tostring(not p2:isDone()), "thread")
    end
  end
end

-- Channel methods

--@api-stub: Channel:type
-- Returns the Lua-visible type name string for this channel handle.
do
  local ch = lurek.thread.newChannel()
  if ch:type() == "LChannel" then
    lurek.log.debug("got a channel", "thread")
  end
end

--@api-stub: Channel:typeOf
-- Returns true if this channel handle matches the given type name string.
do
  local ch = lurek.thread.newChannel()
  assert(ch:typeOf("LChannel"))
end

--@api-stub: Channel:push
-- Pushes a value onto this channel channel or queue.
do
  local events = lurek.thread.getChannel("game_events")
  events:push({ kind = "enemy_killed", id = 17 })
  events:push({ kind = "score_delta", value = 100 })
end

--@api-stub: Channel:pop
-- Pops and returns the next value from this channel channel or queue.
do
  local events = lurek.thread.getChannel("game_events")
  function lurek.process(_)
    local ev = events:pop()
    while ev do ev = events:pop() end
  end
end

--@api-stub: Channel:peek
-- Returns the next value from this channel without removing it.
do
  local jobs = lurek.thread.getChannel("work_queue")
  jobs:push({ priority = "high", task = "save" })
  local next_job = jobs:peek()
  if next_job and next_job.priority == "high" then ---@diagnostic disable-line: undefined-field
    lurek.log.info("high-priority job pending", "thread")
  end
end

--@api-stub: Channel:demand
-- Blocks until a value is available and returns it from this channel.
do
  local worker = lurek.thread.newThread([[
    local inbox = lurek.thread.getChannel("worker_inbox")
    local msg = inbox:demand(1.0)
    if msg then lurek.thread.getChannel("results"):push("ack") end
  ]])
  worker:start()
end

--@api-stub: Channel:getCount
-- Returns the total count of items held by this channel.
do
  local jobs = lurek.thread.getChannel("work_queue")
  if jobs:getCount() < 64 then
    jobs:push({ task = "stream_chunk" })
  end
end

--@api-stub: Channel:getCapacity
-- Returns the capacity of this channel.
do
  local bounded = lurek.thread["newBoundedChannel"](4)
  lurek.log.debug("capacity=" .. tostring(bounded["getCapacity"](bounded)), "thread")
end

--@api-stub: Channel:isBounded
-- Returns true if this channel bounded.
do
  local a = lurek.thread.newChannel()
  local b = lurek.thread["newBoundedChannel"](2)
  lurek.log.debug("a bounded=" .. tostring(a["isBounded"](a)) .. " b bounded=" .. tostring(b["isBounded"](b)), "thread")
end

--@api-stub: Channel:tryPush
-- Performs the try push operation on this channel.
do
  local bounded = lurek.thread["newBoundedChannel"](1)
  bounded["tryPush"](bounded, "first")
  local ok = bounded["tryPush"](bounded, "second")
  lurek.log.debug("second push accepted=" .. tostring(ok), "thread")
end

--@api-stub: Channel:clear
-- Clears all items from this channel.
do
  local stale = lurek.thread.getChannel("level_events")
  stale:push({ kind = "old" })
  stale:clear()
  assert(stale:getCount() == 0)
end

--@api-stub: Channel:supply
-- Pushes a value and blocks until a consumer takes it from this channel.
do
  local out = lurek.thread.getChannel("worker_results")
  out:supply({ tile = 1, ok = true })
  out:supply({ tile = 2, ok = true })
end

--@api-stub: Channel:pushTable
-- Performs the push table operation on this channel.
do
  local ch = lurek.thread.getChannel("packets")
  ch:pushTable({ op = "spawn", x = 64, y = 32, kind = "goblin" })
end

--@api-stub: Channel:popTable
-- Performs the pop table operation on this channel.
do
  local ch = lurek.thread.getChannel("packets")
  ch:pushTable({ op = "spawn", id = 7 })
  local pkt = ch:popTable()
  if pkt then lurek.log.info("op=" .. pkt.op, "thread") end
end

--@api-stub: Channel:pushBytes
-- Performs the push bytes operation on this channel.
do
  local stream = lurek.thread.getChannel("net_out")
  local payload = string.char(0xDE, 0xAD, 0xBE, 0xEF)
  stream:pushBytes(payload)
end

--@api-stub: Channel:popBytes
-- Performs the pop bytes operation on this channel.
do
  local stream = lurek.thread.getChannel("net_in")
  stream:pushBytes("\x01\x02\x03")
  local bytes = stream:popBytes()
  if bytes then lurek.log.debug("got " .. #bytes .. " bytes", "thread") end
end

-- -----------------------------------------------------------------------------
-- LThread methods
-- -----------------------------------------------------------------------------

--@api-stub: LThread:type
-- Returns the type name of this object
do
  local thread_obj = lurek.thread.newThread("worker")
  local t = thread_obj:type()
  lurek.log.info("LThread:type = " .. t, "thread")
end
--@api-stub: LThread:typeOf
-- Checks whether this object matches the given type name
do
  local thread_obj2 = lurek.thread.newThread("worker")
  lurek.log.info("is LThread: " .. tostring(thread_obj2 and thread_obj2:typeOf("LThread") or false), "thread")
  lurek.log.info("is wrong: " .. tostring(thread_obj2 and thread_obj2:typeOf("Unknown") or false), "thread")
end
--@api-stub: LThread:start
-- Launches the worker thread, executing the Lua code string supplied at creation time
do
  local t = lurek.thread.newThread([[
    local ch = lurek.thread.getChannel("result")
    ch:push(42)
  ]])
  t:start()
  lurek.log.info("thread started, running=" .. tostring(t:isRunning()), "thread")
  t:wait()
end
--@api-stub: LThread:wait
-- Blocks the calling thread until the worker thread finishes execution
do
  local t = lurek.thread.newThread([[
    -- lightweight worker
  ]])
  t:start()
  t:wait()   -- block until done
  lurek.log.info("thread finished, err=" .. tostring(t:getError()), "thread")
end
--@api-stub: LThread:isRunning
-- Checks whether the worker thread is still executing
do
  local t = lurek.thread.newThread([[
    -- minimal worker
  ]])
  lurek.log.info("before start: " .. tostring(t:isRunning()), "thread")
  t:start()
  lurek.log.info("after start: " .. tostring(t:isRunning()), "thread")
  t:wait()
end
--@api-stub: LThread:getError
-- Returns the error message from the worker thread, if it terminated with an error
do
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
