-- content/examples/save.lua
-- Scaffolded coverage of the lurek.save API (22 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/save_api.rs   (Lua binding, arg types, return shape)
--   * src/save/                 (semantics, side effects)
--   * docs/specs/save.md        (canonical reference)
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
-- Run: cargo run -- content/examples/save.lua

-- ── lurek.save.* functions ──

--@api-stub: lurek.save.newSaveManager
-- Creates a new SaveManager for slot-based save/load operations.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: lurek.save.newSaveManager
  local _todo = "TODO: write a real lurek.save.newSaveManager usage example"
  print(_todo)
end

-- ── SaveManager methods ──

--@api-stub: SaveManager:unregister
-- Removes a named module and its callbacks.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:unregister
  local _todo = "TODO: write a real SaveManager:unregister usage example"
  print(_todo)
end

--@api-stub: SaveManager:setSchemaVersion
-- Sets the current schema version for new saves.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:setSchemaVersion
  local _todo = "TODO: write a real SaveManager:setSchemaVersion usage example"
  print(_todo)
end

--@api-stub: SaveManager:getSchemaVersion
-- Returns the current schema version.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:getSchemaVersion
  local _todo = "TODO: write a real SaveManager:getSchemaVersion usage example"
  print(_todo)
end

--@api-stub: SaveManager:collect
-- Collects data from all registered collectors into a table with metadata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:collect
  local _todo = "TODO: write a real SaveManager:collect usage example"
  print(_todo)
end

--@api-stub: SaveManager:restore
-- Restores data from a table, applying migrations and calling restorers.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:restore
  local _todo = "TODO: write a real SaveManager:restore usage example"
  print(_todo)
end

--@api-stub: SaveManager:markDirty
-- Marks data as modified since the last save or load.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:markDirty
  local _todo = "TODO: write a real SaveManager:markDirty usage example"
  print(_todo)
end

--@api-stub: SaveManager:isDirty
-- Returns whether data has been modified since the last save or load.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:isDirty
  local _todo = "TODO: write a real SaveManager:isDirty usage example"
  print(_todo)
end

--@api-stub: SaveManager:disableAutoSave
-- Disables automatic periodic saving; manual `write()` calls still work.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:disableAutoSave
  local _todo = "TODO: write a real SaveManager:disableAutoSave usage example"
  print(_todo)
end

--@api-stub: SaveManager:update
-- Advances the auto-save timer, returning the slot name if a save should trigger.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:update
  local _todo = "TODO: write a real SaveManager:update usage example"
  print(_todo)
end

--@api-stub: SaveManager:setSummary
-- Sets the summary string included in save metadata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:setSummary
  local _todo = "TODO: write a real SaveManager:setSummary usage example"
  print(_todo)
end

--@api-stub: SaveManager:getSummary
-- Returns the current summary string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:getSummary
  local _todo = "TODO: write a real SaveManager:getSummary usage example"
  print(_todo)
end

--@api-stub: SaveManager:reset
-- Resets all state, removing callbacks and clearing the manager.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:reset
  local _todo = "TODO: write a real SaveManager:reset usage example"
  print(_todo)
end

--@api-stub: SaveManager:setCompress
-- Enables or disables LZ4 compression for saved data.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:setCompress
  local _todo = "TODO: write a real SaveManager:setCompress usage example"
  print(_todo)
end

--@api-stub: SaveManager:isCompressed
-- Returns whether compression is currently enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:isCompressed
  local _todo = "TODO: write a real SaveManager:isCompressed usage example"
  print(_todo)
end

--@api-stub: SaveManager:onBeforeSave
-- Registers a callback that fires before every save operation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:onBeforeSave
  local _todo = "TODO: write a real SaveManager:onBeforeSave usage example"
  print(_todo)
end

--@api-stub: SaveManager:onAfterLoad
-- Registers a callback that fires after every successful load operation.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:onAfterLoad
  local _todo = "TODO: write a real SaveManager:onAfterLoad usage example"
  print(_todo)
end

--@api-stub: SaveManager:save
-- Collects data and writes it to a slot file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:save
  local _todo = "TODO: write a real SaveManager:save usage example"
  print(_todo)
end

--@api-stub: SaveManager:load
-- Loads data from a slot file, applies migrations, and restores.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:load
  local _todo = "TODO: write a real SaveManager:load usage example"
  print(_todo)
end

--@api-stub: SaveManager:delete
-- Deletes a save file for the given slot.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:delete
  local _todo = "TODO: write a real SaveManager:delete usage example"
  print(_todo)
end

--@api-stub: SaveManager:getSlots
-- Returns a list of all save slots with metadata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:getSlots
  local _todo = "TODO: write a real SaveManager:getSlots usage example"
  print(_todo)
end

--@api-stub: SaveManager:getSlotInfo
-- Returns metadata for a single slot, or nil if not found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/save_api.rs and docs/specs/save.md).
do  -- TODO: SaveManager:getSlotInfo
  local _todo = "TODO: write a real SaveManager:getSlotInfo usage example"
  print(_todo)
end

