-- content/examples/thread.lua
-- Practical usage examples for the lurek.thread API (37 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.thread.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/thread.lua

print("[example] lurek.thread — 37 API entries")

-- ── lurek.thread.* free functions ──

--@api-stub: lurek.thread.newThread
-- Creates a new background thread from a Lua code string.
-- Call when you need to create a new thread.
local ok, obj = pcall(function() return lurek.thread.newThread(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.thread.newThread ok=", ok)

--@api-stub: lurek.thread.newChannel
-- Creates an unnamed thread-safe channel for inter-thread communication.
-- Call when you need to create a new channel.
local ok, obj = pcall(function() return lurek.thread.newChannel() end)
if ok and obj then print("created:", obj) end
print("lurek.thread.newChannel ok=", ok)

--@api-stub: lurek.thread.getChannel
-- Gets or creates a named global channel shared across threads.
-- Call when you need to read channel.
local ok, value = pcall(function() return lurek.thread.getChannel("name") end)
local v = ok and value or "(unavailable)"
print("lurek.thread.getChannel ->", v)

--@api-stub: lurek.thread.newPool
-- Creates a thread pool of N workers all running the same Lua code.
-- Call when you need to create a new pool.
local ok, obj = pcall(function() return lurek.thread.newPool(10, nil) end)
if ok and obj then print("created:", obj) end
print("lurek.thread.newPool ok=", ok)

--@api-stub: lurek.thread.async
-- Starts a one-shot background computation and returns a Promise.
-- Call when you need to invoke async.
local ok, result = pcall(function() return lurek.thread.async(nil, {}) end)
if ok then print("lurek.thread.async ->", result)
else print("unavailable:", result) end

-- ── ThreadHandle methods ──

--@api-stub: ThreadHandle:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a ThreadHandle via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadHandle(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("ThreadHandle:type ->", ok, result)
end

--@api-stub: ThreadHandle:typeOf
-- Returns whether this object is of the given type.
-- Call when you need to invoke type of.
-- Build a ThreadHandle via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadHandle(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("ThreadHandle:typeOf ->", ok, result)
end

--@api-stub: ThreadHandle:start
-- Launches the background thread, passing optional arguments via varargs.
-- Call when you need to invoke start.
-- Build a ThreadHandle via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadHandle(...)
if instance then
  local ok, result = pcall(function() return instance:start({}) end)
  print("ThreadHandle:start ->", ok, result)
end

--@api-stub: ThreadHandle:wait
-- Blocks the calling thread until the background thread finishes.
-- Call when you need to invoke wait.
-- Build a ThreadHandle via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadHandle(...)
if instance then
  local ok, result = pcall(function() return instance:wait() end)
  print("ThreadHandle:wait ->", ok, result)
end

--@api-stub: ThreadHandle:isRunning
-- Returns whether the thread is currently executing.
-- Call when you need to check is running.
-- Build a ThreadHandle via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadHandle(...)
if instance then
  local ok, result = pcall(function() return instance:isRunning() end)
  print("ThreadHandle:isRunning ->", ok, result)
end

--@api-stub: ThreadHandle:getError
-- Returns the error message if the thread failed, or nil.
-- Call when you need to read error.
-- Build a ThreadHandle via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadHandle(...)
if instance then
  local ok, result = pcall(function() return instance:getError() end)
  print("ThreadHandle:getError ->", ok, result)
end

-- ── ThreadPool methods ──

--@api-stub: ThreadPool:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a ThreadPool via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadPool(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("ThreadPool:type ->", ok, result)
end

--@api-stub: ThreadPool:typeOf
-- Returns whether this object is of the given type.
-- Call when you need to invoke type of.
-- Build a ThreadPool via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadPool(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("ThreadPool:typeOf ->", ok, result)
end

--@api-stub: ThreadPool:submit
-- Submits a value to the pool's input channel for processing by a worker.
-- Call when you need to invoke submit.
-- Build a ThreadPool via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadPool(...)
if instance then
  local ok, result = pcall(function() return instance:submit(nil) end)
  print("ThreadPool:submit ->", ok, result)
end

--@api-stub: ThreadPool:collect
-- Retrieves the next result from the pool's output channel (non-blocking).
-- Call when you need to invoke collect.
-- Build a ThreadPool via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadPool(...)
if instance then
  local ok, result = pcall(function() return instance:collect() end)
  print("ThreadPool:collect ->", ok, result)
end

--@api-stub: ThreadPool:size
-- Returns the number of workers in this pool.
-- Call when you need to invoke size.
-- Build a ThreadPool via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadPool(...)
if instance then
  local ok, result = pcall(function() return instance:size() end)
  print("ThreadPool:size ->", ok, result)
end

--@api-stub: ThreadPool:join
-- Blocks until all workers in the pool have finished execution.
-- Call when you need to invoke join.
-- Build a ThreadPool via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadPool(...)
if instance then
  local ok, result = pcall(function() return instance:join() end)
  print("ThreadPool:join ->", ok, result)
end

--@api-stub: ThreadPool:getInputChannel
-- Returns the shared input Channel (main â†’ workers).
-- Call when you need to read input channel.
-- Build a ThreadPool via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadPool(...)
if instance then
  local ok, result = pcall(function() return instance:getInputChannel() end)
  print("ThreadPool:getInputChannel ->", ok, result)
end

--@api-stub: ThreadPool:getOutputChannel
-- Returns the shared output Channel (workers â†’ main).
-- Call when you need to read output channel.
-- Build a ThreadPool via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newThreadPool(...)
if instance then
  local ok, result = pcall(function() return instance:getOutputChannel() end)
  print("ThreadPool:getOutputChannel ->", ok, result)
end

-- ── Promise methods ──

--@api-stub: Promise:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Promise via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newPromise(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Promise:type ->", ok, result)
end

--@api-stub: Promise:typeOf
-- Returns whether this object is of the given type.
-- Call when you need to invoke type of.
-- Build a Promise via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newPromise(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Promise:typeOf ->", ok, result)
end

--@api-stub: Promise:isDone
-- Returns true if the promise has a result or has errored (non-blocking).
-- Call when you need to check is done.
-- Build a Promise via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newPromise(...)
if instance then
  local ok, result = pcall(function() return instance:isDone() end)
  print("Promise:isDone ->", ok, result)
end

--@api-stub: Promise:result
-- Pops and returns the promise result, or nil if not yet ready.
-- Call when you need to invoke result.
-- Build a Promise via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newPromise(...)
if instance then
  local ok, result = pcall(function() return instance:result() end)
  print("Promise:result ->", ok, result)
end

--@api-stub: Promise:getError
-- Returns the worker error string if the promise failed, otherwise nil.
-- Call when you need to read error.
-- Build a Promise via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newPromise(...)
if instance then
  local ok, result = pcall(function() return instance:getError() end)
  print("Promise:getError ->", ok, result)
end

-- ── Channel methods ──

--@api-stub: Channel:type
-- Returns the type of the object.
-- Call when you need to invoke type.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Channel:type ->", ok, result)
end

--@api-stub: Channel:typeOf
-- Checks if the object is of the specified type.
-- Call when you need to invoke type of.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Channel:typeOf ->", ok, result)
end

--@api-stub: Channel:push
-- Pushes a value to the channel.
-- Call when you need to invoke push.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:push(nil) end)
  print("Channel:push ->", ok, result)
end

--@api-stub: Channel:pop
-- Retrieves and removes a value from the channel.
-- Call when you need to invoke pop.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:pop() end)
  print("Channel:pop ->", ok, result)
end

--@api-stub: Channel:peek
-- Retrieves the value from the channel without removing it.
-- Call when you need to invoke peek.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:peek() end)
  print("Channel:peek ->", ok, result)
end

--@api-stub: Channel:demand
-- Blocks until a value is available or the timeout expires, then removes and returns it.
-- Call when you need to invoke demand.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:demand(nil) end)
  print("Channel:demand ->", ok, result)
end

--@api-stub: Channel:getCount
-- Returns the number of items in the channel.
-- Call when you need to read count.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:getCount() end)
  print("Channel:getCount ->", ok, result)
end

--@api-stub: Channel:clear
-- Clears all items from the channel.
-- Call when you need to invoke clear.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:clear() end)
  print("Channel:clear ->", ok, result)
end

--@api-stub: Channel:supply
-- Blocks until the channel has space, then adds the value.
-- Call when you need to invoke supply.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:supply(nil) end)
  print("Channel:supply ->", ok, result)
end

--@api-stub: Channel:pushTable
-- Serializes a Lua table and pushes it to the channel.
-- Call when you need to invoke push table.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:pushTable(nil) end)
  print("Channel:pushTable ->", ok, result)
end

--@api-stub: Channel:popTable
-- Pops a value from the channel expecting a table.
-- Call when you need to invoke pop table.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:popTable() end)
  print("Channel:popTable ->", ok, result)
end

--@api-stub: Channel:pushBytes
-- Pushes raw binary data (a Lua string treated as a byte array) to the channel.
-- Call when you need to invoke push bytes.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:pushBytes({}) end)
  print("Channel:pushBytes ->", ok, result)
end

--@api-stub: Channel:popBytes
-- Pops a bytes value from the channel and returns it as a Lua string.
-- Call when you need to invoke pop bytes.
-- Build a Channel via the appropriate lurek.thread.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.thread.newChannel(...)
if instance then
  local ok, result = pcall(function() return instance:popBytes() end)
  print("Channel:popBytes ->", ok, result)
end

