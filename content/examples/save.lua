-- content/examples/save.lua
-- lurek.save API examples: persistent game state management with SaveManager.
-- Run: cargo run -- content/examples/save.lua

--@api-stub: lurek.save.newSaveManager
-- Create a new SaveManager for managing persistent game saves
do
  -- newSaveManager() returns a fresh manager with no registered sections.
  -- You typically create one per game and keep it in a local or module variable.
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(1)
  mgr:register("player",
    function() return { hp = 100, x = 32, y = 64, name = "Hero" } end,
    function(data)
      -- This restorer runs when loading a save; apply data back to game state
      lurek.log.info("restored player: " .. data.name .. " hp=" .. data.hp, "save")
    end)
end

--@api-stub: LSaveManager:register
-- Register a named data section with collector and restorer function pair
do
  -- register(name, collectFn, restoreFn) links a key to save/load behavior.
  -- collectFn: called during save to gather current state into a table.
  -- restoreFn: called during load to apply saved data back into your game.
  local mgr = lurek.save.newSaveManager()

  -- Register player position and stats
  local player = { x = 200, y = 300, hp = 80, gold = 1500 }
  mgr:register("player_state",
    function()
      return { x = player.x, y = player.y, hp = player.hp, gold = player.gold }
    end,
    function(data)
      player.x = data.x
      player.y = data.y
      player.hp = data.hp
      player.gold = data.gold
      lurek.log.info("player restored at (" .. data.x .. "," .. data.y .. ")", "save")
    end)

  -- Register world state separately for clean separation
  mgr:register("world",
    function() return { day = 7, weather = "rain" } end,
    function(data)
      lurek.log.info("world day " .. data.day .. ", weather: " .. data.weather, "save")
    end)
end

--@api-stub: LSaveManager:unregister
-- Remove a previously registered section by name
do
  -- Use unregister when a subsystem is destroyed (e.g. minigame ended).
  -- After unregister, the section is excluded from future save/load cycles.
  local mgr = lurek.save.newSaveManager()
  mgr:register("minigame_progress",
    function() return { score = 450, wave = 3 } end,
    function(data) lurek.log.info("minigame score=" .. data.score, "save") end)

  -- Player exits the minigame; no longer need to track its state
  mgr:unregister("minigame_progress")
  lurek.log.info("minigame section removed from save cycle", "save")
end

--@api-stub: LSaveManager:setSchemaVersion
-- Set the schema version for saves produced by this game build
do
  -- Increment the version whenever save data format changes between releases.
  -- This version is embedded in save files so migrations know which path to take.
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(3)
  lurek.log.info("save format v3 (added inventory slots)", "save")
end

--@api-stub: LSaveManager:getSchemaVersion
-- Return the current schema version number
do
  -- Use this to verify the manager version matches what your game expects.
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(2)
  local ver = mgr:getSchemaVersion()
  if ver < 3 then
    lurek.log.info("running schema v" .. ver .. " (pre-inventory update)", "save")
  end
end

--@api-stub: LSaveManager:collect
-- Invoke all collectors and return the assembled save-data table
do
  -- collect() calls every registered collectFn and bundles results into one table.
  -- The returned table includes __schema_version, __timestamp, and __summary metadata.
  -- Useful for preview UI or checkpoint logic without writing to disk.
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(1)
  mgr:register("inventory",
    function() return { gold = 250, potions = 3, keys = 1 } end,
    function(_) end)
  mgr:register("quest_log",
    function() return { active = "rescue_princess", completed = 4 } end,
    function(_) end)

  local snapshot = mgr:collect()
  lurek.log.info("collected: " .. snapshot.inventory.gold .. " gold, "
    .. snapshot.quest_log.completed .. " quests done", "save")
end

--@api-stub: LSaveManager:restore
-- Apply a save-data table back into game state via all registered restorers
do
  -- restore(data) takes a table (from collect() or loaded from disk) and calls
  -- every registered restoreFn with the matching section data.
  local mgr = lurek.save.newSaveManager()
  local current_hp = 50

  mgr:register("hp",
    function() return current_hp end,
    function(v)
      current_hp = v
      lurek.log.info("hp restored to " .. tostring(v), "save")
    end)

  -- Simulate checkpoint: capture state, then restore it later
  local checkpoint = mgr:collect()
  current_hp = 10  -- player takes damage after checkpoint
  mgr:restore(checkpoint)  -- reverts hp back to 50
end

--@api-stub: LSaveManager:markDirty
-- Mark the save state as having unsaved changes
do
  -- Call markDirty() whenever game state changes in a way that should be persisted.
  -- The auto-save system checks isDirty() to know when to write.
  local mgr = lurek.save.newSaveManager()
  mgr:register("score", function() return 999 end, function(_) end)

  -- Typical pattern: mark dirty on gameplay events
  local function on_enemy_killed()
    mgr:markDirty()
  end

  on_enemy_killed()
  lurek.log.info("state marked dirty after kill", "save")
end

--@api-stub: LSaveManager:isDirty
-- Check whether unsaved changes exist since last save or load
do
  -- isDirty() returns true if markDirty() was called since the last save/load.
  -- Use it to show "unsaved" indicators or confirm-quit dialogs.
  local mgr = lurek.save.newSaveManager()
  mgr:markDirty()

  if mgr:isDirty() then
    lurek.log.info("WARNING: unsaved progress exists!", "save")
    -- In a real game: show "Save before quitting?" dialog
  end
end

--@api-stub: LSaveManager:save
-- Persist all registered data sections to a named slot file on disk
do
  -- save(slot) writes to save/slot_<name>.sav on disk.
  -- Calls onBeforeSave hook, runs all collectors, serializes, then writes.
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(1)
  mgr:register("game_state",
    function() return { level = 5, score = 12400, lives = 2 } end,
    function(_) end)
  mgr:setSummary("Level 5 - Score 12400")

  mgr:save("slot1")
  lurek.log.info("game saved to slot1", "save")
end

--@api-stub: LSaveManager:load
-- Load game state from a named slot file
do
  -- load(slot) returns (true, nil) on success or (false, error_message) on failure.
  -- It decompresses if needed, applies migrations, calls all restorers, then fires onAfterLoad.
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(1)
  mgr:register("game_state",
    function() return {} end,
    function(data)
      lurek.log.info("loaded level " .. tostring(data.level), "save")
    end)

  local ok, err = mgr:load("slot1")
  if not ok then
    lurek.log.warn("load failed: " .. tostring(err) .. " - starting new game", "save")
  end
end

--@api-stub: LSaveManager:delete
-- Permanently delete a save slot file from disk
do
  -- delete(slot) removes the file. Cannot be undone.
  -- Use for "delete save" menu option or clearing temporary autosave slots.
  local mgr = lurek.save.newSaveManager()

  -- Clean up temporary quicksave slot when player reaches a proper checkpoint
  if mgr:exists("quicksave_temp") then
    mgr:delete("quicksave_temp")
    lurek.log.info("temporary quicksave cleaned up", "save")
  else
    lurek.log.info("no quicksave_temp slot to clean up", "save")
  end
end

--@api-stub: LSaveManager:exists
-- Check whether a save slot file exists on disk
do
  -- exists(slot) checks the filesystem without reading file contents.
  -- Use to grey out "Load" buttons or show slot previews conditionally.
  local mgr = lurek.save.newSaveManager()

  if mgr:exists("slot1") then
    lurek.log.info("slot1 found - Continue button enabled", "save")
  else
    lurek.log.info("no save found - showing New Game only", "save")
  end
end

--@api-stub: LSaveManager:getSlots
-- List all save slots found on disk with their metadata
do
  -- getSlots() returns an array of info tables, each with:
  -- slot (string), version (number), timestamp (number), summary (string)
  -- Use this to build a save/load slot selection screen.
  local mgr = lurek.save.newSaveManager()
  local slots = mgr:getSlots()

  if #slots == 0 then
    lurek.log.info("no existing saves found", "save")
  else
    for i, info in ipairs(slots) do
      lurek.log.info("[" .. i .. "] " .. info.slot .. " - " .. info.summary
        .. " (v" .. info.version .. ")", "save")
    end
  end
end

--@api-stub: LSaveManager:getSlotInfo
-- Read metadata for a single save slot without loading full game state
do
  -- getSlotInfo(slot) returns an info table or nil if the slot doesn't exist.
  -- Lighter than load() when you only need preview data for a UI.
  local mgr = lurek.save.newSaveManager()
  local info = mgr:getSlotInfo("slot1")

  if info then
    lurek.log.info("slot1 preview: " .. info.summary
      .. " | saved at " .. tostring(info.timestamp), "save")
  else
    lurek.log.info("slot1 is empty", "save")
  end
end

--@api-stub: LSaveManager:setSummary
-- Set a human-readable summary embedded in the next save
do
  -- The summary is stored alongside save metadata for slot selection UI.
  -- Update it whenever meaningful progress happens (new area, boss defeated, etc).
  local mgr = lurek.save.newSaveManager()

  local area_name = "Crystal Caves"
  local play_hours = 4
  local play_minutes = 32
  mgr:setSummary(area_name .. " - " .. play_hours .. "h " .. play_minutes .. "m")
  lurek.log.info("summary updated for next save", "save")
end

--@api-stub: LSaveManager:getSummary
-- Get the current summary string that will be embedded in the next save
do
  -- Returns the summary set by setSummary, or empty string if none was set.
  local mgr = lurek.save.newSaveManager()
  mgr:setSummary("Chapter 3 - The Fortress")
  local label = mgr:getSummary()
  lurek.log.info("current summary: " .. label, "save")
end

--@api-stub: LSaveManager:setCompress
-- Enable or disable LZ4 compression for save files
do
  -- Compressed saves are smaller on disk but slightly slower to write/read.
  -- Recommended for large save states (open worlds, inventories with many items).
  local mgr = lurek.save.newSaveManager()
  mgr:setCompress(true)
  lurek.log.info("saves will be LZ4-compressed from now on", "save")
end

--@api-stub: LSaveManager:isCompressed
-- Check whether save compression is currently enabled
do
  local mgr = lurek.save.newSaveManager()
  mgr:setCompress(true)

  if mgr:isCompressed() then
    lurek.log.info("compression: ON (smaller files, slightly slower)", "save")
  else
    lurek.log.info("compression: OFF (faster writes, larger files)", "save")
  end
end

--@api-stub: LSaveManager:enableAutoSave
-- Enable periodic auto-saving on a timer
do
  -- enableAutoSave(interval, slot) checks isDirty() every interval seconds.
  -- If dirty, it triggers save(slot) automatically.
  -- You must call update(dt) each frame for the timer to advance.
  local mgr = lurek.save.newSaveManager()
  mgr:register("progress",
    function() return { checkpoint = "bridge", enemies_left = 4 } end,
    function(_) end)

  -- Auto-save every 60 seconds into the "autosave" slot
  mgr:enableAutoSave(60.0, "autosave")
  lurek.log.info("auto-save armed: every 60s -> autosave slot", "save")
end

--@api-stub: LSaveManager:disableAutoSave
-- Disable the periodic auto-save timer
do
  -- Use during cutscenes, boss fights, or menus where auto-save would be disruptive.
  -- Manual saves via save() still work while auto-save is disabled.
  local mgr = lurek.save.newSaveManager()
  mgr:enableAutoSave(30.0, "autosave")

  -- Entering a cutscene: pause auto-save
  mgr:disableAutoSave()
  lurek.log.info("auto-save paused for cutscene", "save")
end

--@api-stub: LSaveManager:update
-- Advance the auto-save timer by dt seconds (call once per frame)
do
  -- update(dt) returns true if an auto-save was triggered this frame.
  -- Only meaningful when enableAutoSave is active and state is dirty.
  local mgr = lurek.save.newSaveManager()
  mgr:register("state", function() return { wave = 3 } end, function(_) end)
  mgr:enableAutoSave(30.0, "autosave")
  mgr:markDirty()

  -- In your game loop:
  local dt = 1.0 / 60.0  -- simulated frame delta
  local triggered = mgr:update(dt)
  if triggered then
    lurek.log.info("auto-save fired this frame", "save")
  end
end

--@api-stub: LSaveManager:onBeforeSave
-- Set a hook called immediately before each save operation
do
  -- The callback receives the slot name. Use it to finalize state, update summary,
  -- or log save events. Pass nil to clear the hook.
  local mgr = lurek.save.newSaveManager()

  mgr:onBeforeSave(function(slot)
    -- Update summary with current timestamp before writing
    mgr:setSummary("Saved at frame " .. tostring(lurek.timer.getTime()))
    lurek.log.info("preparing save to slot: " .. slot, "save")
  end)
end

--@api-stub: LSaveManager:onAfterLoad
-- Set a hook called after a save file is loaded and all restorers have run
do
  -- The callback receives the slot name. Use it to rebuild caches, refresh UI,
  -- or log load events. Pass nil to clear the hook.
  local mgr = lurek.save.newSaveManager()

  mgr:onAfterLoad(function(slot)
    lurek.log.info("loaded from " .. slot .. " - rebuilding sprite cache", "save")
    -- In a real game: invalidate texture caches, rebuild spatial index, etc.
  end)
end

--@api-stub: LSaveManager:addMigration
-- Register a migration function for upgrading save data between schema versions
do
  -- addMigration(fromVersion, func) registers a transformer that converts
  -- save data from fromVersion to fromVersion+1.
  -- Chain multiple migrations to handle multi-version jumps automatically.
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(3)

  -- v1 -> v2: added inventory.max_slots field
  mgr:addMigration(1, function(data)
    if data.inventory then
      data.inventory.max_slots = data.inventory.max_slots or 20
    end
    return data
  end)

  -- v2 -> v3: renamed "hp" to "health" in player section
  mgr:addMigration(2, function(data)
    if data.player and data.player.hp then
      data.player.health = data.player.hp
      data.player.hp = nil
    end
    return data
  end)

  lurek.log.info("migrations registered: v1->v2, v2->v3", "save")
end

--@api-stub: LSaveManager:reset
-- Reset the save manager: unregister all sections, clear migrations and hooks
do
  -- reset() returns the manager to its freshly-created state.
  -- Use when returning to main menu or switching player profiles.
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(2)
  mgr:register("player", function() return {} end, function(_) end)
  mgr:register("world", function() return {} end, function(_) end)
  mgr:setCompress(true)

  -- Player returns to title screen
  mgr:reset()
  lurek.log.info("save manager fully reset for main menu", "save")
end

--@api-stub: LSaveManager:type
-- Return the type name string for this userdata object
do
  -- type() always returns "LSaveManager". Useful for generic type checking.
  local mgr = lurek.save.newSaveManager()
  local t = mgr:type()
  lurek.log.info("object type: " .. t, "save")  -- prints "LSaveManager"
end

--@api-stub: LSaveManager:typeOf
-- Check whether this object matches a given type name
do
  -- typeOf(name) accepts "LSaveManager" or "Object".
  -- Use for duck-typing checks when passing objects between systems.
  local mgr = lurek.save.newSaveManager()
  lurek.log.info("is LSaveManager: " .. tostring(mgr:typeOf("LSaveManager")), "save")
  lurek.log.info("is Object: " .. tostring(mgr:typeOf("Object")), "save")
  lurek.log.info("is LSource: " .. tostring(mgr:typeOf("LSource")), "save")
end

print("content/examples/save.lua")
