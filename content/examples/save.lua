-- content/examples/save.lua
-- Practical usage examples for the lurek.save API (22 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.save.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/save.lua

print("[example] lurek.save — 22 API entries")

-- ── lurek.save.* free functions ──

--@api-stub: lurek.save.newSaveManager
-- Creates a new SaveManager for slot-based save/load operations.
-- Call when you need to create a new save manager.
local ok, obj = pcall(function() return lurek.save.newSaveManager() end)
if ok and obj then print("created:", obj) end
print("lurek.save.newSaveManager ok=", ok)

-- ── SaveManager methods ──

--@api-stub: SaveManager:unregister
-- Removes a named module and its callbacks.
-- Call when you need to invoke unregister.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:unregister("name") end)
  print("SaveManager:unregister ->", ok, result)
end

--@api-stub: SaveManager:setSchemaVersion
-- Sets the current schema version for new saves.
-- Call when you need to assign schema version.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:setSchemaVersion(nil) end)
  print("SaveManager:setSchemaVersion ->", ok, result)
end

--@api-stub: SaveManager:getSchemaVersion
-- Returns the current schema version.
-- Call when you need to read schema version.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:getSchemaVersion() end)
  print("SaveManager:getSchemaVersion ->", ok, result)
end

--@api-stub: SaveManager:collect
-- Collects data from all registered collectors into a table with metadata.
-- Call when you need to invoke collect.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:collect() end)
  print("SaveManager:collect ->", ok, result)
end

--@api-stub: SaveManager:restore
-- Restores data from a table, applying migrations and calling restorers.
-- Call when you need to invoke restore.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:restore({}) end)
  print("SaveManager:restore ->", ok, result)
end

--@api-stub: SaveManager:markDirty
-- Marks data as modified since the last save or load.
-- Call when you need to invoke mark dirty.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:markDirty() end)
  print("SaveManager:markDirty ->", ok, result)
end

--@api-stub: SaveManager:isDirty
-- Returns whether data has been modified since the last save or load.
-- Call when you need to check is dirty.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:isDirty() end)
  print("SaveManager:isDirty ->", ok, result)
end

--@api-stub: SaveManager:disableAutoSave
-- Disables automatic periodic saving; manual `write()` calls still work.
-- Call when you need to invoke disable auto save.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:disableAutoSave() end)
  print("SaveManager:disableAutoSave ->", ok, result)
end

--@api-stub: SaveManager:update
-- Advances the auto-save timer, returning the slot name if a save should trigger.
-- Call when you need to invoke update.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:update(1.0) end)
  print("SaveManager:update ->", ok, result)
end

--@api-stub: SaveManager:setSummary
-- Sets the summary string included in save metadata.
-- Call when you need to assign summary.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:setSummary(nil) end)
  print("SaveManager:setSummary ->", ok, result)
end

--@api-stub: SaveManager:getSummary
-- Returns the current summary string.
-- Call when you need to read summary.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:getSummary() end)
  print("SaveManager:getSummary ->", ok, result)
end

--@api-stub: SaveManager:reset
-- Resets all state, removing callbacks and clearing the manager.
-- Call when you need to invoke reset.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:reset() end)
  print("SaveManager:reset ->", ok, result)
end

--@api-stub: SaveManager:setCompress
-- Enables or disables LZ4 compression for saved data.
-- Call when you need to assign compress.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:setCompress(nil) end)
  print("SaveManager:setCompress ->", ok, result)
end

--@api-stub: SaveManager:isCompressed
-- Returns whether compression is currently enabled.
-- Call when you need to check is compressed.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:isCompressed() end)
  print("SaveManager:isCompressed ->", ok, result)
end

--@api-stub: SaveManager:onBeforeSave
-- Registers a callback that fires before every save operation.
-- Call when you need to invoke on before save.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:onBeforeSave(function() end) end)
  print("SaveManager:onBeforeSave ->", ok, result)
end

--@api-stub: SaveManager:onAfterLoad
-- Registers a callback that fires after every successful load operation.
-- Call when you need to invoke on after load.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:onAfterLoad(function() end) end)
  print("SaveManager:onAfterLoad ->", ok, result)
end

--@api-stub: SaveManager:save
-- Collects data and writes it to a slot file.
-- Call when you need to invoke save.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:save(nil) end)
  print("SaveManager:save ->", ok, result)
end

--@api-stub: SaveManager:load
-- Loads data from a slot file, applies migrations, and restores.
-- Call when you need to invoke load.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:load(nil) end)
  print("SaveManager:load ->", ok, result)
end

--@api-stub: SaveManager:delete
-- Deletes a save file for the given slot.
-- Call when you need to invoke delete.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:delete(nil) end)
  print("SaveManager:delete ->", ok, result)
end

--@api-stub: SaveManager:getSlots
-- Returns a list of all save slots with metadata.
-- Call when you need to read slots.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:getSlots() end)
  print("SaveManager:getSlots ->", ok, result)
end

--@api-stub: SaveManager:getSlotInfo
-- Returns metadata for a single slot, or nil if not found.
-- Call when you need to read slot info.
-- Build a SaveManager via the appropriate lurek.save.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.save.newSaveManager(...)
if instance then
  local ok, result = pcall(function() return instance:getSlotInfo(nil) end)
  print("SaveManager:getSlotInfo ->", ok, result)
end

