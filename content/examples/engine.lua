-- content/examples/engine.lua
-- Scaffolded coverage of the lurek.engine API (10 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/engine_api.rs   (Lua binding, arg types, return shape)
--   * src/engine/                 (semantics, side effects)
--   * docs/specs/engine.md        (canonical reference)
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
-- Run: cargo run -- content/examples/engine.lua

-- ── lurek.engine.* functions ──

--@api-stub: lurek.engine.getVersion
-- Returns the engine version string (from `Cargo.toml`).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.getVersion
  local _todo = "TODO: write a real lurek.engine.getVersion usage example"
  print(_todo)
end

--@api-stub: lurek.engine.getFrameBudget
-- Returns the target frame budget in milliseconds (default: 1000 / 60 â‰ 16.667 ms).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.getFrameBudget
  local _todo = "TODO: write a real lurek.engine.getFrameBudget usage example"
  print(_todo)
end

--@api-stub: lurek.engine.memoryUsage
-- Returns a table with `lua_bytes` (Lua GC heap usage in bytes) and.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.memoryUsage
  local _todo = "TODO: write a real lurek.engine.memoryUsage usage example"
  print(_todo)
end

--@api-stub: lurek.engine.platform
-- Returns a string identifying the host operating system:.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.platform
  local _todo = "TODO: write a real lurek.engine.platform usage example"
  print(_todo)
end

--@api-stub: lurek.engine.uptime
-- Returns the total engine uptime in seconds (sum of all processed deltas).
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.uptime
  local _todo = "TODO: write a real lurek.engine.uptime usage example"
  print(_todo)
end

--@api-stub: lurek.engine.fps
-- Returns the current measured frames-per-second.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.fps
  local _todo = "TODO: write a real lurek.engine.fps usage example"
  print(_todo)
end

--@api-stub: lurek.engine.frameCount
-- Returns the total number of frames processed since engine start.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.frameCount
  local _todo = "TODO: write a real lurek.engine.frameCount usage example"
  print(_todo)
end

--@api-stub: lurek.engine.isDebug
-- Returns `true` if the engine was compiled in debug mode.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.isDebug
  local _todo = "TODO: write a real lurek.engine.isDebug usage example"
  print(_todo)
end

--@api-stub: lurek.engine.setResourceBudget
-- Sets the maximum resident texture memory budget in bytes.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.setResourceBudget
  local _todo = "TODO: write a real lurek.engine.setResourceBudget usage example"
  print(_todo)
end

--@api-stub: lurek.engine.getResourceStats
-- Returns a table with resident resource memory statistics.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/engine_api.rs and docs/specs/engine.md).
do  -- TODO: lurek.engine.getResourceStats
  local _todo = "TODO: write a real lurek.engine.getResourceStats usage example"
  print(_todo)
end

