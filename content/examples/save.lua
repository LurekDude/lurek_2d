-- content/examples/save.lua
-- lurek.save API examples.
-- Run: cargo run -- content/examples/save.lua

--@api-stub: lurek.save.newSaveManager
-- Create a new SaveManager instance for managing persistent game saves
do
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(1)
  mgr:register("player",
    function() return { hp = 100, x = 32, y = 64 } end,
    function(t) lurek.log.info("restored player hp=" .. (t and t.hp or 0), "save") end)
end

-- SaveManager methods

--@api-stub: SaveManager:unregister
-- Performs the unregister operation on this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:register("minigame",
    function() return { score = 0 } end,
    function(_) end)
  mgr:unregister("minigame")
end

--@api-stub: SaveManager:setSchemaVersion
-- Sets the schema version of this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(3)
  lurek.log.info("save schema is now v" .. mgr:getSchemaVersion(), "save")
end

--@api-stub: SaveManager:getSchemaVersion
-- Returns the schema version of this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:setSchemaVersion(2)
  local ver = mgr:getSchemaVersion()
  if ver < 2 then lurek.log.warn("schema older than expected", "save") end
end

--@api-stub: SaveManager:collect
-- Collects and returns all completed task results from this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:register("inventory",
    function() return { gold = 250, potions = 3 } end,
    function(_) end)
  local snapshot = mgr:collect()
  lurek.log.info("snapshot has " .. tostring(snapshot.inventory.gold) .. " gold", "save")
end

--@api-stub: SaveManager:restore
-- Performs the restore operation on this save manager.
do
  local mgr = lurek.save.newSaveManager()
  local checkpoint
  mgr:register("hp",
    function() return 100 end,
    function(v) lurek.log.info("hp restored to " .. tostring(v), "save") end)
  checkpoint = mgr:collect()
  mgr:restore(checkpoint)
end

--@api-stub: SaveManager:markDirty
-- Performs the mark dirty operation on this save manager.
do
  local mgr = lurek.save.newSaveManager()
  local function on_item_picked_up()
    mgr:markDirty()
  end
  on_item_picked_up()
end

--@api-stub: SaveManager:isDirty
-- Returns true if this save manager dirty.
do
  local mgr = lurek.save.newSaveManager()
  mgr:markDirty()
  if mgr:isDirty() then
    lurek.log.info("unsaved changes pending", "save")
  end
end

--@api-stub: SaveManager:disableAutoSave
-- Performs the disable auto save operation on this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:enableAutoSave(60.0, "auto")
  mgr:disableAutoSave()
  lurek.log.info("auto-save paused for cutscene", "save")
end

--@api-stub: SaveManager:update
-- Advances this save manager by the given delta time.
do
  local mgr = lurek.save.newSaveManager()
  mgr:enableAutoSave(30.0, "auto")
  function lurek.process(dt)
    local slot = mgr:update(dt)
    if slot then mgr:save(slot) end
  end
end

--@api-stub: SaveManager:setSummary
-- Sets the summary of this save manager.
do
  local mgr = lurek.save.newSaveManager()
  local area, playtime = "Forest", "12:30"
  mgr:setSummary(area .. " â€” " .. playtime)
end

--@api-stub: SaveManager:getSummary
-- Returns the summary of this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:setSummary("Chapter 2 â€” Boss")
  local label = mgr:getSummary()
  lurek.log.info("current summary: " .. label, "save")
end

--@api-stub: SaveManager:reset
-- Resets this save manager to its default state.
do
  local mgr = lurek.save.newSaveManager()
  mgr:register("player", function() return {} end, function(_) end)
  mgr:reset()
  lurek.log.info("save manager cleared for main menu", "save")
end

--@api-stub: SaveManager:setCompress
-- Sets the compress of this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:setCompress(true)
  lurek.log.info("compressed saves enabled", "save")
end

--@api-stub: SaveManager:isCompressed
-- Returns true if this save manager compressed.
do
  local mgr = lurek.save.newSaveManager()
  mgr:setCompress(true)
  if mgr:isCompressed() then
    lurek.log.info("save format: lz4+base64", "save")
  end
end

--@api-stub: SaveManager:onBeforeSave
-- Fires the callback registered for the before save event on this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:onBeforeSave(function(slot)
    mgr:setSummary("Saved to " .. slot)
    lurek.log.info("about to write slot " .. slot, "save")
  end)
end

--@api-stub: SaveManager:onAfterLoad
-- Fires the callback registered for the after load event on this save manager.
do
  local mgr = lurek.save.newSaveManager()
  mgr:onAfterLoad(function(slot)
    lurek.log.info("loaded slot " .. slot .. ", rebuilding scene", "save")
  end)
end

--@api-stub: SaveManager:save
-- Saves the current state of this save manager.
do
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
-- Loads into this save manager.
do
  local mgr
  function lurek.init()
    mgr = lurek.save.newSaveManager()
    mgr:register("world", function() return {} end, function(_) end)
    local ok, err = mgr:load("slot1")
    if not ok then lurek.log.warn("load failed: " .. tostring(err), "save") end
  end
end

--@api-stub: SaveManager:delete
-- Deletes the  from this save manager.
do
  local mgr
  function lurek.quit()
    mgr = lurek.save.newSaveManager()
    mgr:delete("slot_temp")
    lurek.log.info("scratch slot removed on quit", "save")
  end
end

--@api-stub: SaveManager:getSlots
-- Returns the slots of this save manager.
do
  local mgr
  function lurek.init()
    mgr = lurek.save.newSaveManager()
    for _, info in ipairs(mgr:getSlots()) do
      lurek.log.info("slot " .. info.slot .. " â€” " .. info.summary, "save")
    end
  end
end

--@api-stub: SaveManager:getSlotInfo
-- Returns the slot info of this save manager.
do
  local mgr
  function lurek.init()
    mgr = lurek.save.newSaveManager()
    local info = mgr:getSlotInfo("slot1")
    if info then lurek.log.info("preview: " .. info.summary, "save") end
  end
end

--@api-stub: SaveManager:addMigration
-- Adds a migration to this save manager.
do
  local sm = lurek.save.newSaveManager()
  sm:setSchemaVersion(2)
  sm:addMigration(1, function(data)
    data.score = data.score or 0
    return data
  end)
  lurek.log.info("migration registered", "save")
end

--@api-stub: SaveManager:enableAutoSave
-- Performs the enable auto save operation on this save manager.
do
  local sm = lurek.save.newSaveManager()
  sm:register("state", function() return {score=0} end, function(d) end)
  sm:enableAutoSave(5.0, "slot1")
  lurek.log.info("auto-save enabled", "save")
end

--@api-stub: SaveManager:exists
-- Performs the exists operation on this save manager.
do
  local sm = lurek.save.newSaveManager()
  local present = sm:exists("slot1")
  lurek.log.info("slot1 exists: " .. tostring(present), "save")
end

--@api-stub: SaveManager:register
-- Performs the register operation on this save manager.
do
  local sm = lurek.save.newSaveManager()
  sm:register("player_state",
    function() return {x=200, y=300, hp=100} end,
    function(d) lurek.log.info("restored hp=" .. d.hp, "save") end
  )
  lurek.log.info("component registered", "save")
end

-- -----------------------------------------------------------------------------
-- SaveManager methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LSaveManager methods
-- -----------------------------------------------------------------------------


--@api-stub: LSaveManager:type
-- Returns the Lua-visible type name string for this save manager handle.
do
  local sm = lurek.save.manager()
  lurek.log.info(sm:type(), "save")
end

--@api-stub: LSaveManager:typeOf
-- Returns true if this save manager handle matches the given type name string.
do
  local sm = lurek.save.manager()
  lurek.log.info(tostring(sm:typeOf("LSaveManager")), "save")
end
