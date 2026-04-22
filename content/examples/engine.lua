-- content/examples/engine.lua
-- Practical usage examples for the lurek.engine API (10 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.engine.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/engine.lua

print("[example] lurek.engine — 10 API entries")

-- ── lurek.engine.* free functions ──

--@api-stub: lurek.engine.getVersion
-- Returns the engine version string (from `Cargo.toml`).
-- Call when you need to read version.
local ok, value = pcall(function() return lurek.engine.getVersion() end)
local v = ok and value or "(unavailable)"
print("lurek.engine.getVersion ->", v)

--@api-stub: lurek.engine.getFrameBudget
-- Returns the target frame budget in milliseconds (default: 1000 / 60 â‰ 16.667 ms).
-- Call when you need to read frame budget.
local ok, value = pcall(function() return lurek.engine.getFrameBudget() end)
local v = ok and value or "(unavailable)"
print("lurek.engine.getFrameBudget ->", v)

--@api-stub: lurek.engine.memoryUsage
-- Returns a table with `lua_bytes` (Lua GC heap usage in bytes) and.
-- Call when you need to invoke memory usage.
local ok, result = pcall(function() return lurek.engine.memoryUsage() end)
if ok then print("lurek.engine.memoryUsage ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.engine.platform
-- Returns a string identifying the host operating system:.
-- Call when you need to invoke platform.
local ok, result = pcall(function() return lurek.engine.platform() end)
if ok then print("lurek.engine.platform ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.engine.uptime
-- Returns the total engine uptime in seconds (sum of all processed deltas).
-- Call when you need to invoke uptime.
local ok, result = pcall(function() return lurek.engine.uptime() end)
if ok then print("lurek.engine.uptime ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.engine.fps
-- Returns the current measured frames-per-second.
-- Call when you need to invoke fps.
local ok, result = pcall(function() return lurek.engine.fps() end)
if ok then print("lurek.engine.fps ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.engine.frameCount
-- Returns the total number of frames processed since engine start.
-- Call when you need to invoke frame count.
local ok, result = pcall(function() return lurek.engine.frameCount() end)
if ok then print("lurek.engine.frameCount ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.engine.isDebug
-- Returns `true` if the engine was compiled in debug mode.
-- Call when you need to check is debug.
local ok, result = pcall(function() return lurek.engine.isDebug() end)
if ok and result then print("yes") else print("no or unavailable") end
print("lurek.engine.isDebug ok=", ok)

--@api-stub: lurek.engine.setResourceBudget
-- Sets the maximum resident texture memory budget in bytes.
-- Call when you need to assign resource budget.
local ok, err = pcall(function() lurek.engine.setResourceBudget(nil) end)
if not ok then print("set skipped:", err) end
print("lurek.engine.setResourceBudget applied=", ok)

--@api-stub: lurek.engine.getResourceStats
-- Returns a table with resident resource memory statistics.
-- Call when you need to read resource stats.
local ok, value = pcall(function() return lurek.engine.getResourceStats() end)
local v = ok and value or "(unavailable)"
print("lurek.engine.getResourceStats ->", v)

