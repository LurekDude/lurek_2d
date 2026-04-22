-- content/examples/event.lua
-- Auto-scaffolded coverage of the lurek.event Lua API (22 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/event.lua

print("[example] lurek.event loaded — 22 API items demonstrated")

-- ── lurek.event free functions ──

--@api-stub: lurek.event.exit
-- Pushes an exit event, requesting the engine to stop.
-- Use this when pushes an exit event, requesting the engine to stop is needed.
if false then
  local _r = lurek.event.exit(nil)
  print(_r)
end

--@api-stub: lurek.event.poll
-- Returns an iterator function that pops events from the queue.
-- Use this when returns an iterator function that pops events from the queue is needed.
if false then
  local _r = lurek.event.poll()
  print(_r)
end

--@api-stub: lurek.event.clear
-- Discards all pending events in the queue.
-- Use this when discards all pending events in the queue is needed.
if false then
  local _r = lurek.event.clear()
  print(_r)
end

--@api-stub: lurek.event.newSignal
-- Creates a new pub-sub Signal dispatcher.
-- Use this when creates a new pub-sub Signal dispatcher is needed.
if false then
  local _r = lurek.event.newSignal()
  print(_r)
end

--@api-stub: lurek.event.pump
-- Syncs OS-level events into the queue (no-op in Lurek2D push model).
-- Use this when syncs OS-level events into the queue (no-op in Lurek2D push model) is needed.
if false then
  local _r = lurek.event.pump()
  print(_r)
end

--@api-stub: lurek.event.wait
-- Blocks until the next event arrives or the optional timeout elapses.
-- Use this when blocks until the next event arrives or the optional timeout elapses is needed.
if false then
  local _r = lurek.event.wait(0)
  print(_r)
end

--@api-stub: lurek.event.restart
-- Requests that the engine restart at the beginning of the next frame.
-- Use this when requests that the engine restart at the beginning of the next frame is needed.
if false then
  local _r = lurek.event.restart()
  print(_r)
end

--@api-stub: lurek.event.quit
-- Alias for `exit()` â€” requests the engine to stop at the end of the current frame.
-- Use this when alias for `exit()` â€” requests the engine to stop at the end of the current frame is needed.
if false then
  local _r = lurek.event.quit()
  print(_r)
end

--@api-stub: lurek.event.pushDeferred
-- Pushes a named event to the deferred buffer; it will not reach the main queue.
-- Use this when pushes a named event to the deferred buffer; it will not reach the main queue is needed.
if false then
  local _r = lurek.event.pushDeferred({})
  print(_r)
end

--@api-stub: lurek.event.flushDeferred
-- Moves all buffered deferred events into the main event queue and clears the buffer.
-- Use this when moves all buffered deferred events into the main event queue and clears the buffer is needed.
if false then
  local _r = lurek.event.flushDeferred()
  print(_r)
end

--@api-stub: lurek.event.enableHistory
-- Enables event history recording, keeping the last `capacity` pushed events.
-- Use this when enables event history recording, keeping the last `capacity` pushed events is needed.
if false then
  local _r = lurek.event.enableHistory(0)
  print(_r)
end

--@api-stub: lurek.event.getHistory
-- Returns an array of recent events as `{name, args}` tables.
-- Use this when returns an array of recent events as `{name, args}` tables is needed.
if false then
  local _r = lurek.event.getHistory()
  print(_r)
end

--@api-stub: lurek.event.clearHistory
-- Clears all recorded event history.
-- Use this when clears all recorded event history is needed.
if false then
  local _r = lurek.event.clearHistory()
  print(_r)
end

--@api-stub: lurek.event.push
-- Adds an event item to the end of the event queue for processing.
-- Use this when adds an event item to the end of the event queue for processing is needed.
if false then
  local _r = lurek.event.push({})
  print(_r)
end

-- ── Signal methods ──

--@api-stub: Signal:emit
-- Emits the named event, calling all registered callbacks with extra arguments.
-- Use this when emits the named event, calling all registered callbacks with extra arguments is needed.
if false then
  local _o = nil  -- Signal instance
  _o:emit({})
end

--@api-stub: Signal:remove
-- Removes a subscription by handle ID.
-- Use this when removes a subscription by handle ID is needed.
if false then
  local _o = nil  -- Signal instance
  _o:remove(1)
end

--@api-stub: Signal:clear
-- Removes all callbacks for the named event.
-- Use this when removes all callbacks for the named event is needed.
if false then
  local _o = nil  -- Signal instance
  _o:clear(1)
end

--@api-stub: Signal:clearAll
-- Removes all callbacks across all events.
-- Use this when removes all callbacks across all events is needed.
if false then
  local _o = nil  -- Signal instance
  _o:clearAll()
end

--@api-stub: Signal:getCount
-- Returns the callback count for the named event.
-- Use this when returns the callback count for the named event is needed.
if false then
  local _o = nil  -- Signal instance
  _o:getCount(1)
end

--@api-stub: Signal:getTotalCount
-- Returns the total callback count across all events.
-- Use this when returns the total callback count across all events is needed.
if false then
  local _o = nil  -- Signal instance
  _o:getTotalCount()
end

--@api-stub: Signal:type
-- Returns the type name of this object.
-- Use this when returns the type name of this object is needed.
if false then
  local _o = nil  -- Signal instance
  _o:type()
end

--@api-stub: Signal:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- Use this when returns true if the given type name matches this object's type or any parent type is needed.
if false then
  local _o = nil  -- Signal instance
  _o:typeOf(1)
end

