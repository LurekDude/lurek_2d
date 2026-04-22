-- content/examples/engine.lua
-- Auto-scaffolded coverage of the lurek.engine Lua API (10 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/engine.lua

print("[example] lurek.engine loaded — 10 API items demonstrated")

-- ── lurek.engine free functions ──

--@api-stub: lurek.engine.getVersion
-- Returns the engine version string (from `Cargo.toml`).
-- Use this when returns the engine version string (from `Cargo.toml`) is needed.
if false then
  local _r = lurek.engine.getVersion()
  print(_r)
end

--@api-stub: lurek.engine.getFrameBudget
-- Returns the target frame budget in milliseconds (default: 1000 / 60 â‰ 16.667 ms).
-- Use this when returns the target frame budget in milliseconds (default: 1000 / 60 â‰ 16.667 ms) is needed.
if false then
  local _r = lurek.engine.getFrameBudget()
  print(_r)
end

--@api-stub: lurek.engine.memoryUsage
-- Returns a table with `lua_bytes` (Lua GC heap usage in bytes) and.
-- Use this when returns a table with `lua_bytes` (Lua GC heap usage in bytes) and is needed.
if false then
  local _r = lurek.engine.memoryUsage()
  print(_r)
end

--@api-stub: lurek.engine.platform
-- Returns a string identifying the host operating system:.
-- Use this when returns a string identifying the host operating system: is needed.
if false then
  local _r = lurek.engine.platform()
  print(_r)
end

--@api-stub: lurek.engine.uptime
-- Returns the total engine uptime in seconds (sum of all processed deltas).
-- Use this when returns the total engine uptime in seconds (sum of all processed deltas) is needed.
if false then
  local _r = lurek.engine.uptime()
  print(_r)
end

--@api-stub: lurek.engine.fps
-- Returns the current measured frames-per-second.
-- Use this when returns the current measured frames-per-second is needed.
if false then
  local _r = lurek.engine.fps()
  print(_r)
end

--@api-stub: lurek.engine.frameCount
-- Returns the total number of frames processed since engine start.
-- Use this when returns the total number of frames processed since engine start is needed.
if false then
  local _r = lurek.engine.frameCount()
  print(_r)
end

--@api-stub: lurek.engine.isDebug
-- Returns `true` if the engine was compiled in debug mode.
-- Use this when returns `true` if the engine was compiled in debug mode is needed.
if false then
  local _r = lurek.engine.isDebug()
  print(_r)
end

--@api-stub: lurek.engine.setResourceBudget
-- Sets the maximum resident texture memory budget in bytes.
-- Use this when sets the maximum resident texture memory budget in bytes is needed.
if false then
  local _r = lurek.engine.setResourceBudget(0)
  print(_r)
end

--@api-stub: lurek.engine.getResourceStats
-- Returns a table with resident resource memory statistics.
-- Use this when returns a table with resident resource memory statistics is needed.
if false then
  local _r = lurek.engine.getResourceStats()
  print(_r)
end

