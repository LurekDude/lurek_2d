-- content/examples/event.lua
-- Scaffolded coverage of the lurek.event API (22 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/event_api.rs   (Lua binding, arg types, return shape)
--   * src/event/                 (semantics, side effects)
--   * docs/specs/event.md        (canonical reference)
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
-- Run: cargo run -- content/examples/event.lua

-- ── lurek.event.* functions ──

--@api-stub: lurek.event.exit
-- Pushes an exit event, requesting the engine to stop.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.exit
  local _todo = "TODO: write a real lurek.event.exit usage example"
  print(_todo)
end

--@api-stub: lurek.event.poll
-- Returns an iterator function that pops events from the queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.poll
  local _todo = "TODO: write a real lurek.event.poll usage example"
  print(_todo)
end

--@api-stub: lurek.event.clear
-- Discards all pending events in the queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.clear
  local _todo = "TODO: write a real lurek.event.clear usage example"
  print(_todo)
end

--@api-stub: lurek.event.newSignal
-- Creates a new pub-sub Signal dispatcher.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.newSignal
  local _todo = "TODO: write a real lurek.event.newSignal usage example"
  print(_todo)
end

--@api-stub: lurek.event.pump
-- Syncs OS-level events into the queue (no-op in Lurek2D push model).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.pump
  local _todo = "TODO: write a real lurek.event.pump usage example"
  print(_todo)
end

--@api-stub: lurek.event.wait
-- Blocks until the next event arrives or the optional timeout elapses.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.wait
  local _todo = "TODO: write a real lurek.event.wait usage example"
  print(_todo)
end

--@api-stub: lurek.event.restart
-- Requests that the engine restart at the beginning of the next frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.restart
  local _todo = "TODO: write a real lurek.event.restart usage example"
  print(_todo)
end

--@api-stub: lurek.event.quit
-- Alias for `exit()` â€” requests the engine to stop at the end of the current frame.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.quit
  local _todo = "TODO: write a real lurek.event.quit usage example"
  print(_todo)
end

--@api-stub: lurek.event.pushDeferred
-- Pushes a named event to the deferred buffer; it will not reach the main queue.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.pushDeferred
  local _todo = "TODO: write a real lurek.event.pushDeferred usage example"
  print(_todo)
end

--@api-stub: lurek.event.flushDeferred
-- Moves all buffered deferred events into the main event queue and clears the buffer.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.flushDeferred
  local _todo = "TODO: write a real lurek.event.flushDeferred usage example"
  print(_todo)
end

--@api-stub: lurek.event.enableHistory
-- Enables event history recording, keeping the last `capacity` pushed events.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.enableHistory
  local _todo = "TODO: write a real lurek.event.enableHistory usage example"
  print(_todo)
end

--@api-stub: lurek.event.getHistory
-- Returns an array of recent events as `{name, args}` tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.getHistory
  local _todo = "TODO: write a real lurek.event.getHistory usage example"
  print(_todo)
end

--@api-stub: lurek.event.clearHistory
-- Clears all recorded event history.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.clearHistory
  local _todo = "TODO: write a real lurek.event.clearHistory usage example"
  print(_todo)
end

--@api-stub: lurek.event.push
-- Adds an event item to the end of the event queue for processing.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: lurek.event.push
  local _todo = "TODO: write a real lurek.event.push usage example"
  print(_todo)
end

-- ── Signal methods ──

--@api-stub: Signal:emit
-- Emits the named event, calling all registered callbacks with extra arguments.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: Signal:emit
  local _todo = "TODO: write a real Signal:emit usage example"
  print(_todo)
end

--@api-stub: Signal:remove
-- Removes a subscription by handle ID.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: Signal:remove
  local _todo = "TODO: write a real Signal:remove usage example"
  print(_todo)
end

--@api-stub: Signal:clear
-- Removes all callbacks for the named event.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: Signal:clear
  local _todo = "TODO: write a real Signal:clear usage example"
  print(_todo)
end

--@api-stub: Signal:clearAll
-- Removes all callbacks across all events.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: Signal:clearAll
  local _todo = "TODO: write a real Signal:clearAll usage example"
  print(_todo)
end

--@api-stub: Signal:getCount
-- Returns the callback count for the named event.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: Signal:getCount
  local _todo = "TODO: write a real Signal:getCount usage example"
  print(_todo)
end

--@api-stub: Signal:getTotalCount
-- Returns the total callback count across all events.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: Signal:getTotalCount
  local _todo = "TODO: write a real Signal:getTotalCount usage example"
  print(_todo)
end

--@api-stub: Signal:type
-- Returns the type name of this object.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: Signal:type
  local _todo = "TODO: write a real Signal:type usage example"
  print(_todo)
end

--@api-stub: Signal:typeOf
-- Returns true if the given type name matches this object's type or any parent type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/event_api.rs and docs/specs/event.md).
do  -- TODO: Signal:typeOf
  local _todo = "TODO: write a real Signal:typeOf usage example"
  print(_todo)
end

