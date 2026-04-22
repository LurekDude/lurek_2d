-- content/examples/event.lua
-- Practical usage examples for the lurek.event API (22 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.event.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/event.lua

print("[example] lurek.event — 22 API entries")

-- ── lurek.event.* free functions ──

--@api-stub: lurek.event.exit
-- Pushes an exit event, requesting the engine to stop.
-- Call when you need to invoke exit.
local ok, result = pcall(function() return lurek.event.exit(nil) end)
if ok then print("lurek.event.exit ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.event.poll
-- Returns an iterator function that pops events from the queue.
-- Call when you need to invoke poll.
local ok, result = pcall(function() return lurek.event.poll() end)
if ok then print("lurek.event.poll ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.event.clear
-- Discards all pending events in the queue.
-- Call when you need to invoke clear.
local ok, err = pcall(function() lurek.event.clear() end)
if not ok then print("skipped:", err) end
print("lurek.event.clear cleared=", ok)

--@api-stub: lurek.event.newSignal
-- Creates a new pub-sub Signal dispatcher.
-- Call when you need to create a new signal.
local ok, obj = pcall(function() return lurek.event.newSignal() end)
if ok and obj then print("created:", obj) end
print("lurek.event.newSignal ok=", ok)

--@api-stub: lurek.event.pump
-- Syncs OS-level events into the queue (no-op in Lurek2D push model).
-- Call when you need to invoke pump.
local ok, result = pcall(function() return lurek.event.pump() end)
if ok then print("lurek.event.pump ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.event.wait
-- Blocks until the next event arrives or the optional timeout elapses.
-- Call when you need to invoke wait.
local ok, result = pcall(function() return lurek.event.wait(nil) end)
if ok then print("lurek.event.wait ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.event.restart
-- Requests that the engine restart at the beginning of the next frame.
-- Call when you need to invoke restart.
local ok, result = pcall(function() return lurek.event.restart() end)
if ok then print("lurek.event.restart ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.event.quit
-- Alias for `exit()` â€” requests the engine to stop at the end of the current frame.
-- Call when you need to invoke quit.
local ok, result = pcall(function() return lurek.event.quit() end)
if ok then print("lurek.event.quit ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.event.pushDeferred
-- Pushes a named event to the deferred buffer; it will not reach the main queue.
-- Call when you need to invoke push deferred.
local ok, err = pcall(function() lurek.event.pushDeferred({}) end)
if not ok then print("mutator skipped:", err) end
print("lurek.event.pushDeferred done=", ok)

--@api-stub: lurek.event.flushDeferred
-- Moves all buffered deferred events into the main event queue and clears the buffer.
-- Call when you need to invoke flush deferred.
local ok, result = pcall(function() return lurek.event.flushDeferred() end)
if ok then print("lurek.event.flushDeferred ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.event.enableHistory
-- Enables event history recording, keeping the last `capacity` pushed events.
-- Call when you need to invoke enable history.
local ok, result = pcall(function() return lurek.event.enableHistory(nil) end)
if ok then print("lurek.event.enableHistory ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.event.getHistory
-- Returns an array of recent events as `{name, args}` tables.
-- Call when you need to read history.
local ok, value = pcall(function() return lurek.event.getHistory() end)
local v = ok and value or "(unavailable)"
print("lurek.event.getHistory ->", v)

--@api-stub: lurek.event.clearHistory
-- Clears all recorded event history.
-- Call when you need to invoke clear history.
local ok, err = pcall(function() lurek.event.clearHistory() end)
if not ok then print("skipped:", err) end
print("lurek.event.clearHistory cleared=", ok)

--@api-stub: lurek.event.push
-- Adds an event item to the end of the event queue for processing.
-- Call when you need to invoke push.
local ok, err = pcall(function() lurek.event.push({}) end)
if not ok then print("mutator skipped:", err) end
print("lurek.event.push done=", ok)

-- ── Signal methods ──

--@api-stub: Signal:emit
-- Emits the named event, calling all registered callbacks with extra arguments.
-- Call when you need to invoke emit.
-- Build a Signal via the appropriate lurek.event.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.event.newSignal(...)
if instance then
  local ok, result = pcall(function() return instance:emit({}) end)
  print("Signal:emit ->", ok, result)
end

--@api-stub: Signal:remove
-- Removes a subscription by handle ID.
-- Call when you need to invoke remove.
-- Build a Signal via the appropriate lurek.event.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.event.newSignal(...)
if instance then
  local ok, result = pcall(function() return instance:remove(nil) end)
  print("Signal:remove ->", ok, result)
end

--@api-stub: Signal:clear
-- Removes all callbacks for the named event.
-- Call when you need to invoke clear.
-- Build a Signal via the appropriate lurek.event.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.event.newSignal(...)
if instance then
  local ok, result = pcall(function() return instance:clear("name") end)
  print("Signal:clear ->", ok, result)
end

--@api-stub: Signal:clearAll
-- Removes all callbacks across all events.
-- Call when you need to invoke clear all.
-- Build a Signal via the appropriate lurek.event.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.event.newSignal(...)
if instance then
  local ok, result = pcall(function() return instance:clearAll() end)
  print("Signal:clearAll ->", ok, result)
end

--@api-stub: Signal:getCount
-- Returns the callback count for the named event.
-- Call when you need to read count.
-- Build a Signal via the appropriate lurek.event.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.event.newSignal(...)
if instance then
  local ok, result = pcall(function() return instance:getCount("name") end)
  print("Signal:getCount ->", ok, result)
end

--@api-stub: Signal:getTotalCount
-- Returns the total callback count across all events.
-- Call when you need to read total count.
-- Build a Signal via the appropriate lurek.event.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.event.newSignal(...)
if instance then
  local ok, result = pcall(function() return instance:getTotalCount() end)
  print("Signal:getTotalCount ->", ok, result)
end

--@api-stub: Signal:type
-- Returns the type name of this object.
-- Call when you need to invoke type.
-- Build a Signal via the appropriate lurek.event.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.event.newSignal(...)
if instance then
  local ok, result = pcall(function() return instance:type() end)
  print("Signal:type ->", ok, result)
end

--@api-stub: Signal:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- Call when you need to invoke type of.
-- Build a Signal via the appropriate lurek.event.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.event.newSignal(...)
if instance then
  local ok, result = pcall(function() return instance:typeOf("name") end)
  print("Signal:typeOf ->", ok, result)
end

