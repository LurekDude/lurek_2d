-- content/examples/thread.lua
-- Scaffolded coverage of the lurek.thread API (37 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/thread_api.rs   (Lua binding, arg types, return shape)
--   * src/thread/                 (semantics, side effects)
--   * docs/specs/thread.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/thread.lua

-- ── lurek.thread.* functions ──

--@api-stub: lurek.thread.newThread
-- Creates a new background thread from a Lua code string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: lurek.thread.newThread
  local _todo = "TODO: write a real lurek.thread.newThread usage example"
  print(_todo)
end

--@api-stub: lurek.thread.newChannel
-- Creates an unnamed thread-safe channel for inter-thread communication.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: lurek.thread.newChannel
  local _todo = "TODO: write a real lurek.thread.newChannel usage example"
  print(_todo)
end

--@api-stub: lurek.thread.getChannel
-- Gets or creates a named global channel shared across threads.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: lurek.thread.getChannel
  local _todo = "TODO: write a real lurek.thread.getChannel usage example"
  print(_todo)
end

--@api-stub: lurek.thread.newPool
-- Creates a thread pool of N workers all running the same Lua code.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: lurek.thread.newPool
  local _todo = "TODO: write a real lurek.thread.newPool usage example"
  print(_todo)
end

--@api-stub: lurek.thread.async
-- Starts a one-shot background computation and returns a Promise.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: lurek.thread.async
  local _todo = "TODO: write a real lurek.thread.async usage example"
  print(_todo)
end

-- ── ThreadHandle methods ──

--@api-stub: ThreadHandle:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadHandle:type
  local _todo = "TODO: write a real ThreadHandle:type usage example"
  print(_todo)
end

--@api-stub: ThreadHandle:typeOf
-- Returns whether this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadHandle:typeOf
  local _todo = "TODO: write a real ThreadHandle:typeOf usage example"
  print(_todo)
end

--@api-stub: ThreadHandle:start
-- Launches the background thread, passing optional arguments via varargs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadHandle:start
  local _todo = "TODO: write a real ThreadHandle:start usage example"
  print(_todo)
end

--@api-stub: ThreadHandle:wait
-- Blocks the calling thread until the background thread finishes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadHandle:wait
  local _todo = "TODO: write a real ThreadHandle:wait usage example"
  print(_todo)
end

--@api-stub: ThreadHandle:isRunning
-- Returns whether the thread is currently executing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadHandle:isRunning
  local _todo = "TODO: write a real ThreadHandle:isRunning usage example"
  print(_todo)
end

--@api-stub: ThreadHandle:getError
-- Returns the error message if the thread failed, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadHandle:getError
  local _todo = "TODO: write a real ThreadHandle:getError usage example"
  print(_todo)
end

-- ── ThreadPool methods ──

--@api-stub: ThreadPool:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadPool:type
  local _todo = "TODO: write a real ThreadPool:type usage example"
  print(_todo)
end

--@api-stub: ThreadPool:typeOf
-- Returns whether this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadPool:typeOf
  local _todo = "TODO: write a real ThreadPool:typeOf usage example"
  print(_todo)
end

--@api-stub: ThreadPool:submit
-- Submits a value to the pool's input channel for processing by a worker.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadPool:submit
  local _todo = "TODO: write a real ThreadPool:submit usage example"
  print(_todo)
end

--@api-stub: ThreadPool:collect
-- Retrieves the next result from the pool's output channel (non-blocking).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadPool:collect
  local _todo = "TODO: write a real ThreadPool:collect usage example"
  print(_todo)
end

--@api-stub: ThreadPool:size
-- Returns the number of workers in this pool.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadPool:size
  local _todo = "TODO: write a real ThreadPool:size usage example"
  print(_todo)
end

--@api-stub: ThreadPool:join
-- Blocks until all workers in the pool have finished execution.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadPool:join
  local _todo = "TODO: write a real ThreadPool:join usage example"
  print(_todo)
end

--@api-stub: ThreadPool:getInputChannel
-- Returns the shared input Channel (main â†’ workers).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadPool:getInputChannel
  local _todo = "TODO: write a real ThreadPool:getInputChannel usage example"
  print(_todo)
end

--@api-stub: ThreadPool:getOutputChannel
-- Returns the shared output Channel (workers â†’ main).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: ThreadPool:getOutputChannel
  local _todo = "TODO: write a real ThreadPool:getOutputChannel usage example"
  print(_todo)
end

-- ── Promise methods ──

--@api-stub: Promise:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Promise:type
  local _todo = "TODO: write a real Promise:type usage example"
  print(_todo)
end

--@api-stub: Promise:typeOf
-- Returns whether this object is of the given type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Promise:typeOf
  local _todo = "TODO: write a real Promise:typeOf usage example"
  print(_todo)
end

--@api-stub: Promise:isDone
-- Returns true if the promise has a result or has errored (non-blocking).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Promise:isDone
  local _todo = "TODO: write a real Promise:isDone usage example"
  print(_todo)
end

--@api-stub: Promise:result
-- Pops and returns the promise result, or nil if not yet ready.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Promise:result
  local _todo = "TODO: write a real Promise:result usage example"
  print(_todo)
end

--@api-stub: Promise:getError
-- Returns the worker error string if the promise failed, otherwise nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Promise:getError
  local _todo = "TODO: write a real Promise:getError usage example"
  print(_todo)
end

-- ── Channel methods ──

--@api-stub: Channel:type
-- Returns the type of the object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:type
  local _todo = "TODO: write a real Channel:type usage example"
  print(_todo)
end

--@api-stub: Channel:typeOf
-- Checks if the object is of the specified type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:typeOf
  local _todo = "TODO: write a real Channel:typeOf usage example"
  print(_todo)
end

--@api-stub: Channel:push
-- Pushes a value to the channel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:push
  local _todo = "TODO: write a real Channel:push usage example"
  print(_todo)
end

--@api-stub: Channel:pop
-- Retrieves and removes a value from the channel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:pop
  local _todo = "TODO: write a real Channel:pop usage example"
  print(_todo)
end

--@api-stub: Channel:peek
-- Retrieves the value from the channel without removing it.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:peek
  local _todo = "TODO: write a real Channel:peek usage example"
  print(_todo)
end

--@api-stub: Channel:demand
-- Blocks until a value is available or the timeout expires, then removes and returns it.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:demand
  local _todo = "TODO: write a real Channel:demand usage example"
  print(_todo)
end

--@api-stub: Channel:getCount
-- Returns the number of items in the channel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:getCount
  local _todo = "TODO: write a real Channel:getCount usage example"
  print(_todo)
end

--@api-stub: Channel:clear
-- Clears all items from the channel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:clear
  local _todo = "TODO: write a real Channel:clear usage example"
  print(_todo)
end

--@api-stub: Channel:supply
-- Blocks until the channel has space, then adds the value.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:supply
  local _todo = "TODO: write a real Channel:supply usage example"
  print(_todo)
end

--@api-stub: Channel:pushTable
-- Serializes a Lua table and pushes it to the channel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:pushTable
  local _todo = "TODO: write a real Channel:pushTable usage example"
  print(_todo)
end

--@api-stub: Channel:popTable
-- Pops a value from the channel expecting a table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:popTable
  local _todo = "TODO: write a real Channel:popTable usage example"
  print(_todo)
end

--@api-stub: Channel:pushBytes
-- Pushes raw binary data (a Lua string treated as a byte array) to the channel.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:pushBytes
  local _todo = "TODO: write a real Channel:pushBytes usage example"
  print(_todo)
end

--@api-stub: Channel:popBytes
-- Pops a bytes value from the channel and returns it as a Lua string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/thread_api.rs and docs/specs/thread.md).
do  -- TODO: Channel:popBytes
  local _todo = "TODO: write a real Channel:popBytes usage example"
  print(_todo)
end

