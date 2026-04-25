-- content/examples/save.lua
-- Hand-written coverage of the lurek.save API (22 items).
--
-- A SaveManager owns per-module collector/restorer callbacks plus
-- schema versioning, optional LZ4 compression, and auto-save timing.
-- Slot data is written under "save/slot_<name>.sav" inside the game
-- directory, so all I/O is wrapped in lurek.init / lurek.quit so the
-- file loads cleanly without a runtime in static-analysis contexts.
--
-- Run: cargo run -- content/examples/save.lua

-- ── lurek.save.* functions ──

--@api-stub: lurek.save.newSaveManager
-- Creates a new SaveManager for slot-based save/load operations.
-- Build one manager per game and register every persistent subsystem against it at startup.
do  -- lurek.save.newSaveManager
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(1)
  mgr:register("player",
    function() return { hp = 100, x = 32, y = 64 } end,
    function(t) lurek.log.info("restored player hp=" .. (t and t.hp or 0), "save") end)
end

-- ── SaveManager methods ──

--@api-stub: SaveManager:unregister
-- Removes a named module and its callbacks.
-- Call when a subsystem shuts down mid-game (e.g. minigame ends) so its data is no longer collected.
do  -- SaveManager:unregister
  local mgr = lurek.save.newSaveManager()
  mgr:register("minigame",
    function() return { score = 0 } end,
    function(_) end)
  mgr:unregister("minigame")
end

--@api-stub: SaveManager:setSchemaVersion
-- Sets the current schema version for new saves.
-- Bump this whenever the persisted shape changes and add a matching migration via addMigration.
do  -- SaveManager:setSchemaVersion
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(3)
  lurek.log.info("save schema is now v" .. mgr:getSchemaVersion(), "save")
end

--@api-stub: SaveManager:getSchemaVersion
-- Returns the current schema version.
-- Use during boot to log the active version or to gate compatibility checks against older slots.
do  -- SaveManager:getSchemaVersion
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(2)
  local ver = mgr:getSchemaVersion()
  if ver < 2 then lurek.log.warn("schema older than expected", "save") end
end

--@api-stub: SaveManager:collect
-- Collects data from all registered collectors into a table with metadata.
-- Use to snapshot game state without writing to disk — handy for in-memory checkpoints or replays.
do  -- SaveManager:collect
  local mgr = lurek.save.newSaveManager()
  mgr:register("inventory",
    function() return { gold = 250, potions = 3 } end,
    function(_) end)
  local snapshot = mgr:collect()
  lurek.log.info("snapshot has " .. tostring(snapshot.inventory.gold) .. " gold", "save")
end

--@api-stub: SaveManager:restore
-- Restores data from a table, applying migrations and calling restorers.
-- Use to roll back to a checkpoint table previously returned by collect().
do  -- SaveManager:restore
  local mgr = lurek.save.newSaveManager()
  local checkpoint
  mgr:register("hp",
    function() return 100 end,
    function(v) lurek.log.info("hp restored to " .. tostring(v), "save") end)
  checkpoint = mgr:collect()
  mgr:restore(checkpoint)
end

--@api-stub: SaveManager:markDirty
-- Marks data as modified since the last save or load.
-- Call from gameplay events (item picked up, level cleared) so auto-save knows there is work to do.
do  -- SaveManager:markDirty
  local mgr = lurek.save.newSaveManager()
  local function on_item_picked_up()
    mgr:markDirty()
  end
  on_item_picked_up()
end

--@api-stub: SaveManager:isDirty
-- Returns whether data has been modified since the last save or load.
-- Branch on this before showing a "save now?" prompt or quitting to disk.
do  -- SaveManager:isDirty
  local mgr = lurek.save.newSaveManager()
  mgr:markDirty()
  if mgr:isDirty() then
    lurek.log.info("unsaved changes pending", "save")
  end
end

--@api-stub: SaveManager:disableAutoSave
-- Disables automatic periodic saving; manual `write()` calls still work.
-- Call before cutscenes or boss fights to prevent the auto-save tick from interrupting flow.
do  -- SaveManager:disableAutoSave
  local mgr = lurek.save.newSaveManager()
  mgr:enableAutoSave(60.0, "auto")
  mgr:disableAutoSave()
  lurek.log.info("auto-save paused for cutscene", "save")
end

--@api-stub: SaveManager:update
-- Advances the auto-save timer, returning the slot name if a save should trigger.
-- Drive from lurek.process(dt) — when it returns a slot name, call save(slot) on that frame.
do  -- SaveManager:update
  local mgr = lurek.save.newSaveManager()
  mgr:enableAutoSave(30.0, "auto")
  function lurek.process(dt)
    local slot = mgr:update(dt)
    if slot then mgr:save(slot) end
  end
end

--@api-stub: SaveManager:setSummary
-- Sets the summary string included in save metadata.
-- Refresh on level/area change so the load-game UI can show a friendly "Forest — 12:30" line per slot.
do  -- SaveManager:setSummary
  local mgr = lurek.save.newSaveManager()
  local area, playtime = "Forest", "12:30"
  mgr:setSummary(area .. " — " .. playtime)
end

--@api-stub: SaveManager:getSummary
-- Returns the current summary string.
-- Useful for echoing the active summary into HUD overlays or debug panels.
do  -- SaveManager:getSummary
  local mgr = lurek.save.newSaveManager()
  mgr:setSummary("Chapter 2 — Boss")
  local label = mgr:getSummary()
  lurek.log.info("current summary: " .. label, "save")
end

--@api-stub: SaveManager:reset
-- Resets all state, removing callbacks and clearing the manager.
-- Call when returning to the main menu so a fresh New Game starts with no stale registrations.
do  -- SaveManager:reset
  local mgr = lurek.save.newSaveManager()
  mgr:register("player", function() return {} end, function(_) end)
  mgr:reset()
  lurek.log.info("save manager cleared for main menu", "save")
end

--@api-stub: SaveManager:setCompress
-- Enables or disables LZ4 compression for saved data.
-- Turn on for large worlds or many slots — base64 + LZ4 trades a little CPU for much smaller files.
do  -- SaveManager:setCompress
  local mgr = lurek.save.newSaveManager()
  mgr:setCompress(true)
  lurek.log.info("compressed saves enabled", "save")
end

--@api-stub: SaveManager:isCompressed
-- Returns whether compression is currently enabled.
-- Useful for diagnostics screens or for tests that assert the configured save format.
do  -- SaveManager:isCompressed
  local mgr = lurek.save.newSaveManager()
  mgr:setCompress(true)
  if mgr:isCompressed() then
    lurek.log.info("save format: lz4+base64", "save")
  end
end

--@api-stub: SaveManager:onBeforeSave
-- Registers a callback that fires before every save operation.
-- Use to refresh the summary, flush in-flight buffers, or stamp a final timestamp into game state.
do  -- SaveManager:onBeforeSave
  local mgr = lurek.save.newSaveManager()
  mgr:onBeforeSave(function(slot)
    mgr:setSummary("Saved to " .. slot)
    lurek.log.info("about to write slot " .. slot, "save")
  end)
end

--@api-stub: SaveManager:onAfterLoad
-- Registers a callback that fires after every successful load operation.
-- Use to rebuild derived state (cached lookups, scene graph) once all restorers have finished.
do  -- SaveManager:onAfterLoad
  local mgr = lurek.save.newSaveManager()
  mgr:onAfterLoad(function(slot)
    lurek.log.info("loaded slot " .. slot .. ", rebuilding scene", "save")
  end)
end

--@api-stub: SaveManager:save
-- Collects data and writes it to a slot file.
-- Call from a player-driven action (menu Save button, F5 hotkey) on a manager registered at startup.
do  -- SaveManager:save
  local mgr
  function lurek.init()
    mgr = lurek.save.newSaveManager()
    mgr:register("world",
      function() return { seed = 12345, day = 7 } end,
      function(_) end)
    mgr:save("slot1")
  end
end

--@api-stub: SaveManager:load
-- Loads data from a slot file, applies migrations, and restores.
-- Returns ok, err — branch on the failure path to show the player a "corrupt save" message.
do  -- SaveManager:load
  local mgr
  function lurek.init()
    mgr = lurek.save.newSaveManager()
    mgr:register("world", function() return {} end, function(_) end)
    local ok, err = mgr:load("slot1")
    if not ok then lurek.log.warn("load failed: " .. tostring(err), "save") end
  end
end

--@api-stub: SaveManager:delete
-- Deletes a save file for the given slot.
-- Wire to a "Delete slot" UI button after a confirmation prompt — the file is removed immediately.
do  -- SaveManager:delete
  local mgr
  function lurek.quit()
    mgr = lurek.save.newSaveManager()
    mgr:delete("slot_temp")
    lurek.log.info("scratch slot removed on quit", "save")
  end
end

--@api-stub: SaveManager:getSlots
-- Returns a list of all save slots with metadata.
-- Iterate the result to populate a load-game menu showing slot name, summary, and timestamp.
do  -- SaveManager:getSlots
  local mgr
  function lurek.init()
    mgr = lurek.save.newSaveManager()
    for _, info in ipairs(mgr:getSlots()) do
      lurek.log.info("slot " .. info.slot .. " — " .. info.summary, "save")
    end
  end
end

--@api-stub: SaveManager:getSlotInfo
-- Returns metadata for a single slot, or nil if not found.
-- Use to preview a slot's summary/version on hover before the player commits to loading it.
do  -- SaveManager:getSlotInfo
  local mgr
  function lurek.init()
    mgr = lurek.save.newSaveManager()
    local info = mgr:getSlotInfo("slot1")
    if info then lurek.log.info("preview: " .. info.summary, "save") end
  end
end

--@api-stub: SaveManager:addMigration
-- Registers a migration function for upgrading save data from an older schema version.
-- Migrations run in version order on load; use to add/rename/remove fields safely.
do  -- SaveManager:addMigration
  local sm = lurek.save.newSaveManager()
  sm:setSchemaVersion(2)
  sm:addMigration(1, function(data)
    data.score = data.score or 0
    return data
  end)
  lurek.log.info("migration registered", "save")
end

--@api-stub: SaveManager:enableAutoSave
-- Enables automatic saving after every markDirty() call, with an optional cooldown.
-- cooldown_secs prevents thrashing; 0 saves immediately on every dirty event.
do  -- SaveManager:enableAutoSave
  local sm = lurek.save.newSaveManager()
  sm:register("state", function() return {score=0} end, function(d) end)
  sm:enableAutoSave(5.0, "slot1")
  lurek.log.info("auto-save enabled", "save")
end

--@api-stub: SaveManager:exists
-- Returns true if a save file exists for the given slot name.
-- Use before loading to provide appropriate UI (New Game vs Continue).
do  -- SaveManager:exists
  local sm = lurek.save.newSaveManager()
  local present = sm:exists("slot1")
  lurek.log.info("slot1 exists: " .. tostring(present), "save")
end

--@api-stub: SaveManager:register
-- Registers a named serializable component with collect and restore callbacks.
-- collect() returns the data table; restore(data) applies it to the game state.
do  -- SaveManager:register
  local sm = lurek.save.newSaveManager()
  sm:register("player_state",
    function() return {x=200, y=300, hp=100} end,
    function(d) lurek.log.info("restored hp=" .. d.hp, "save") end
  )
  lurek.log.info("component registered", "save")
end

-- =============================================================================
-- STUBS: 2 uncovered lurek.save API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- SaveManager methods
-- -----------------------------------------------------------------------------

-- ---- Stub: SaveManager:type ----------------------------------------------
--@api-stub: SaveManager:type
-- Returns the type name of this object.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- saveManager_stub:type()  -- -> string
-- (replace saveManager_stub with your real SaveManager instance above)

-- ---- Stub: SaveManager:typeOf --------------------------------------------
--@api-stub: SaveManager:typeOf
-- Returns true if this object is of the given type.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- saveManager_stub:typeOf("hero")  -- -> boolean
-- (replace saveManager_stub with your real SaveManager instance above)
