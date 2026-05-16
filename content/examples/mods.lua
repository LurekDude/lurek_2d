-- content/examples/mods.lua
-- lurek.mods API examples.
-- Run: cargo run -- content/examples/mods.lua

--@api-stub: lurek.mods.newMod
-- Creates a mod metadata handle from a Lua table
do
  local hud_mod = lurek.mods.newMod({
    id = "core.hud",
    name = "Core HUD",
    version = "1.2.0",
    author = "studio",
    priority = 10,
    dependencies = {"core.input"},
  })
  lurek.log.info("built mod " .. hud_mod:getId() .. " v" .. hud_mod:getVersion(), "mods")
end

--@api-stub: lurek.mods.newModManager
-- Creates an empty mod manager
do
  local manager = lurek.mods.newModManager()
  lurek.log.info("manager initialised, " .. manager:getModCount() .. " mods", "mods")
end

--@api-stub: lurek.mods.checkApiVersion
-- Checks whether a mod API version is compatible with a host version
do
  local probe = lurek.mods.newMod({id = "fan.skins", api_version = "1.4.0"})
  local ok, msg = lurek.mods.checkApiVersion(probe, "1.6.2")
  if not ok then
    lurek.log.warn("incompatible mod: " .. (msg or "unknown"), "mods")
  end
end

-- Mod methods

--@api-stub: Mod:getId
-- Returns the id of this mod.
do
  local m = lurek.mods.newMod({id = "core.audio"})
  local registry = {}
  registry[m:getId()] = {volume = 0.8}
end

--@api-stub: Mod:getName
-- Returns the name of this mod.
do
  local m = lurek.mods.newMod({id = "ui.theme.dark", name = "Dark Theme"})
  local label = m:getName()
  if label == "" then label = m:getId() end
  lurek.log.info("listing: " .. label, "ui")
end

--@api-stub: Mod:getVersion
-- Returns the version of this mod.
do
  local m = lurek.mods.newMod({id = "core.physics", version = "2.1.0"})
  if m:getVersion() ~= "2.1.0" then
    lurek.log.warn("save was written by " .. m:getVersion(), "save")
  end
end

--@api-stub: Mod:getAuthor
-- Returns the author of this mod.
do
  local m = lurek.mods.newMod({id = "fan.maps", author = "alice"})
  local credit = m:getAuthor()
  lurek.log.info("map pack by " .. credit, "credits")
end

--@api-stub: Mod:getDescription
-- Returns the description of this mod.
do
  local m = lurek.mods.newMod({id = "ui.minimap", description = "Adds a corner minimap with fog-of-war."})
  local detail = m:getDescription()
  lurek.log.info("about: " .. detail, "ui")
end

--@api-stub: Mod:getDependencies
-- Returns the dependencies of this mod.
do
  local m = lurek.mods.newMod({id = "fan.weapons", dependencies = {"core.combat", "core.audio"}})
  for _, dep in ipairs(m:getDependencies()) do
    lurek.log.debug("requires " .. dep, "mods")
  end
end

--@api-stub: Mod:getPriority
-- Returns the priority of this mod.
do
  local a = lurek.mods.newMod({id = "core.base", priority = 100})
  local b = lurek.mods.newMod({id = "fan.tweak", priority = 5})
  if a:getPriority() > b:getPriority() then
    lurek.log.info(a:getId() .. " loads before " .. b:getId(), "mods")
  end
end

--@api-stub: Mod:isEnabled
-- Returns true if this mod is currently enabled.
do
  local m = lurek.mods.newMod({id = "fan.cheats"})
  if m:isEnabled() then
    lurek.log.debug(m:getId() .. " is active", "mods")
  end
end

--@api-stub: Mod:setEnabled
-- Sets whether this mod is enabled and accepts input.
do
  local m = lurek.mods.newMod({id = "fan.skins"})
  local user_choice = false
  m:setEnabled(user_choice)
  lurek.log.info(m:getId() .. " enabled=" .. tostring(m:isEnabled()), "mods")
end

--@api-stub: Mod:isLoaded
-- Returns true if this mod loaded.
do
  local m = lurek.mods.newMod({id = "core.input"})
  if not m:isLoaded() then
    lurek.log.debug("pending: " .. m:getId(), "mods")
  end
end

--@api-stub: Mod:getApiVersion
-- Returns the api version of this mod.
do
  local m = lurek.mods.newMod({id = "fan.maps", api_version = "1.5.0"})
  local req = m:getApiVersion()
  if req then
    lurek.log.info(m:getId() .. " requires engine >= " .. req, "mods")
  end
end

--@api-stub: Mod:setApiVersion
-- Sets the api version of this mod.
do
  local m = lurek.mods.newMod({id = "test.fixture"})
  m:setApiVersion("1.6.0")
  lurek.log.debug("fixture api_version=" .. m:getApiVersion(), "test")
end

--@api-stub: Mod:getCapabilities
-- Returns the capabilities of this mod.
do
  local m = lurek.mods.newMod({id = "fan.online", capabilities = {"network", "filesystem"}})
  for _, cap in ipairs(m:getCapabilities()) do
    lurek.log.debug(m:getId() .. " uses " .. cap, "mods")
  end
end

--@api-stub: Mod:setCapabilities
-- Sets the capabilities of this mod.
do
  local m = lurek.mods.newMod({id = "fan.tools"})
  local caps = m:getCapabilities()
  caps[#caps + 1] = "filesystem"
  m:setCapabilities(caps)
end

--@api-stub: Mod:getConfigSchema
-- Returns the config schema of this mod.
do
  local m = lurek.mods.newMod({id = "ui.theme", config_schema = {
    {key = "accent", type = "string", default = "#ff8800"},
  }})
  for _, entry in ipairs(m:getConfigSchema()) do
    lurek.log.debug("setting " .. entry.key .. " (" .. entry.type .. ")", "ui")
  end
end

--@api-stub: Mod:setConfigSchema
-- Sets the config schema of this mod.
do
  local m = lurek.mods.newMod({id = "fan.audio"})
  m:setConfigSchema({
    {key = "music_vol", type = "number", default = "0.8"},
    {key = "sfx_vol",   type = "number", default = "1.0"},
  })
end

--@api-stub: Mod:getHook
-- Returns the hook of this mod.
do
  local m = lurek.mods.newMod({id = "fan.combat"})
  m:setHook("on_damage", function(amount) return amount * 2 end)
  local fn = m:getHook("on_damage")
  if fn then lurek.log.debug("doubled: " .. fn(10), "combat") end
end

--@api-stub: Mod:hasHook
-- Returns true if this mod has a hook.
do
  local m = lurek.mods.newMod({id = "fan.input"})
  m:setHook("on_jump", function() end)
  if m:hasHook("on_jump") then
    lurek.log.debug(m:getId() .. " handles jump", "input")
  end
end

--@api-stub: Mod:getHookNames
-- Returns the hook names of this mod.
do
  local m = lurek.mods.newMod({id = "fan.events"})
  m:setHook("on_load", function() end)
  m:setHook("on_quit", function() end)
  for _, name in ipairs(m:getHookNames()) do
    lurek.log.debug(m:getId() .. " hook: " .. name, "mods")
  end
end

--@api-stub: Mod:setConfig
-- Sets the config of this mod.
do
  local m = lurek.mods.newMod({id = "fan.audio"})
  m:setConfig({music_vol = 0.6, sfx_vol = 1.0, mute = false})
end

--@api-stub: Mod:getConfig
-- Returns the config of this mod.
do
  local m = lurek.mods.newMod({id = "fan.audio"})
  m:setConfig({music_vol = 0.5})
  local cfg = m:getConfig() or {music_vol = 1.0}
  lurek.log.debug("music vol=" .. cfg.music_vol, "audio")
end

--@api-stub: Mod:releaseRefs
-- Performs the release refs operation on this mod.
do
  local m = lurek.mods.newMod({id = "scratch.tmp"})
  m:setHook("on_tick", function() end)
  m:setConfig({foo = 1})
  m:releaseRefs()
end

-- ModManager methods

--@api-stub: ModManager:registerMod
-- Performs the register mod operation on this mod manager.
do
  local mgr = lurek.mods.newModManager()
  local m = lurek.mods.newMod({id = "core.hud", priority = 50})
  mgr:registerMod(m)
  lurek.log.info("registered " .. mgr:getModCount() .. " mods", "mods")
end

--@api-stub: ModManager:unregisterMod
-- Performs the unregister mod operation on this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "fan.skins"}))
  local removed = mgr:unregisterMod("fan.skins")
  lurek.log.info("removed=" .. tostring(removed), "mods")
end

--@api-stub: ModManager:hasMod
-- Returns true if this mod manager has a mod.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.combat"}))
  if mgr:hasMod("core.combat") then
    lurek.log.debug("combat available", "ui")
  end
end

--@api-stub: ModManager:getModCount
-- Returns the number of mod items in this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "a"}))
  mgr:registerMod(lurek.mods.newMod({id = "b"}))
  lurek.log.info("loaded " .. mgr:getModCount() .. " mods", "boot")
end

--@api-stub: ModManager:getAllMods
-- Returns all mods values associated with this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.hud", name = "HUD"}))
  for _, info in ipairs(mgr:getAllMods()) do
    lurek.log.debug(info.id .. " priority=" .. info.priority, "mods")
  end
end

--@api-stub: ModManager:getLoadOrder
-- Returns the load order of this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.base", priority = 100}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.ui",   priority = 10, dependencies = {"core.base"}}))
  for i, info in ipairs(mgr:getLoadOrder()) do
    lurek.log.info(i .. ": " .. info.id, "mods")
  end
end

--@api-stub: ModManager:getModsByCapability
-- Returns the mods by capability of this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "fan.audio", capabilities = {"audio"}}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.ui", capabilities = {"ui"}}))
  for _, info in ipairs(mgr:getModsByCapability("audio")) do
    lurek.log.info("audio-capable: " .. info.id, "mods")
  end
end

--@api-stub: ModManager:validateDependencies
-- Performs the validate dependencies operation on this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "fan.weapons", dependencies = {"core.combat"}}))
  for _, broken_id in ipairs(mgr:validateDependencies()) do
    lurek.log.error("missing deps for " .. broken_id, "mods")
  end
end

--@api-stub: ModManager:hasCircularDependencies
-- Returns true if this mod manager has a circular dependencies.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "a", dependencies = {"b"}}))
  mgr:registerMod(lurek.mods.newMod({id = "b", dependencies = {"a"}}))
  if mgr:hasCircularDependencies() then
    lurek.log.error("dependency cycle detected", "mods")
  end
end

--@api-stub: ModManager:setLoadOrder
-- Sets the load order of this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.base"}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.ui"}))
  mgr:setLoadOrder({"core.base", "fan.ui"})
end

--@api-stub: ModManager:clearLoadOrder
-- Clears all load order items from this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:setLoadOrder({"a", "b", "c"})
  mgr:clearLoadOrder()
  lurek.log.info("load order reset to priority", "mods")
end

--@api-stub: ModManager:scanFolder
-- Performs the scan folder operation on this mod manager.
do
  local mgr = lurek.mods.newModManager()
  local discovered = mgr:scanFolder("content/plugins")
  lurek.log.info("auto-registered " .. #discovered .. " mods", "mods")
end

--@api-stub: ModManager:getModPath
-- Returns the mod path of this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "fan.skins"}))
  local path = mgr:getModPath("fan.skins")
  if path then lurek.log.debug("on-disk at " .. path, "mods") end
end

--@api-stub: ModManager:markForReload
-- Performs the mark for reload operation on this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.hud"}))
  local queued = mgr:markForReload("core.hud")
  lurek.log.debug("queued for reload=" .. tostring(queued), "mods")
end

--@api-stub: ModManager:getReloadQueue
-- Returns the reload queue of this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "ui.theme"}))
  mgr:markForReload("ui.theme")
  for _, id in ipairs(mgr:getReloadQueue()) do
    lurek.log.info("reload pending: " .. id, "mods")
  end
end

--@api-stub: ModManager:clearReloadQueue
-- Clears all reload queue items from this mod manager.
do
  local mgr = lurek.mods.newModManager()
  mgr:markForReload("core.hud")
  mgr:clearReloadQueue()
  lurek.log.debug("queue size=" .. #mgr:getReloadQueue(), "mods")
end
--@api-stub: ModManager:processReloadQueue
-- Performs the process reload queue operation on this mod manager.
do
  local mgr = lurek.mods.newModManager()
  ---@diagnostic disable-next-line: undefined-field
  local reloaded = mgr:processReloadQueue()
  lurek.log.debug("reloaded count=" .. #reloaded, "mods")
end
-- Content Registry

--@api-stub: lurek.mods.newRegistry
-- Creates an empty content registry
do
  local reg = lurek.mods.newRegistry()
  lurek.log.debug("registry created", "mods")
end

--@api-stub: ContentRegistry:registerType
-- Performs the register type operation on this content registry.
do
  local reg = lurek.mods.newRegistry()
  reg:registerType("weapon")
  lurek.log.debug("registered type 'weapon'", "mods")
end

--@api-stub: ContentRegistry:register
-- Performs the register operation on this content registry.
do
  local reg = lurek.mods.newRegistry()
  reg:registerType("weapon")
  reg:register("weapon", "iron_sword", { name = "Iron Sword", damage = 12 })
  lurek.log.debug("registered iron_sword", "mods")
end

--@api-stub: ContentRegistry:get
-- Returns the  of this content registry.
do
  local reg = lurek.mods.newRegistry()
  reg:registerType("spell")
  reg:register("spell", "fireball", { cost = 10 })
  local s = reg:get("spell", "fireball")
  lurek.log.debug("spell cost=" .. (s and s.cost or "nil"), "mods") ---@diagnostic disable-line:undefined-field
end

--@api-stub: ContentRegistry:getAll
-- Returns all  values associated with this content registry.
do
  local reg = lurek.mods.newRegistry()
  reg:registerType("item")
  reg:register("item", "potion", { name = "Potion" })
  local all = reg:getAll("item")
  lurek.log.debug("item count=" .. (all.potion and 1 or 0), "mods") ---@diagnostic disable-line:undefined-field
end

--@api-stub: ContentRegistry:getTypes
-- Returns the types of this content registry.
do
  local reg = lurek.mods.newRegistry()
  reg:registerType("creature")
  reg:registerType("item")
  local types = reg:getTypes()
  lurek.log.debug("type count=" .. #types, "mods")
end

--@api-stub: Mod:setHook
-- Sets the hook of this mod.
do
  local mod = lurek.mods.newMod({id="example_mod", name="Example", version="1.0"})
  mod:setHook("on_save", function(ctx)
    lurek.log.info("mod saving extra data", "mods")
  end)
  lurek.log.info("hook registered: " .. tostring(mod:hasHook("on_save")), "mods")
end

-- -----------------------------------------------------------------------------
-- ModManager methods
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- LContentRegistry methods
-- -----------------------------------------------------------------------------

--@api-stub: LContentRegistry:type
-- Returns the Lua-visible type name for this content registry handle
do
  local content_registry_obj = lurek.mods.newRegistry()
  local t = content_registry_obj:type()
  lurek.log.info("LContentRegistry:type = " .. t, "mods")
end
--@api-stub: LContentRegistry:typeOf
-- Returns whether this content registry handle matches a supported type name
do
  local content_registry_obj = lurek.mods.newRegistry()
  lurek.log.info("is LContentRegistry: " .. tostring(content_registry_obj:typeOf("LContentRegistry")), "mods")
  lurek.log.info("is wrong: " .. tostring(content_registry_obj:typeOf("Unknown")), "mods")
end
--@api-stub: LMod:type
-- Returns the Lua-visible type name for this mod handle
do
  local ok ---@type boolean
  local mod_obj ---@type LMod?
  ok, mod_obj = pcall(lurek.mods.newMod, "testmod")
  if not ok then mod_obj = nil end
  local t = mod_obj and mod_obj:type() or "LMod"
  lurek.log.info("LMod:type = " .. t, "mods")
end
--@api-stub: LMod:typeOf
-- Returns whether this mod handle matches a supported type name
do
  local ok2 ---@type boolean
  local mod_obj2 ---@type LMod?
  ok2, mod_obj2 = pcall(lurek.mods.newMod, "testmod")
  if not ok2 then mod_obj2 = nil end
  lurek.log.info("is LMod: " .. tostring(mod_obj2 and mod_obj2:typeOf("LMod") or false), "mods")
  lurek.log.info("is wrong: " .. tostring(mod_obj2 and mod_obj2:typeOf("Unknown") or false), "mods")
end
--@api-stub: LModManager:type
-- Returns the Lua-visible type name for this mod manager handle
do
  local mod_manager_obj = lurek.mods.newModManager()
  local t = mod_manager_obj:type()
  lurek.log.info("LModManager:type = " .. t, "mods")
end
--@api-stub: LModManager:typeOf
-- Returns whether this mod manager handle matches a supported type name
do
  local mod_manager_obj = lurek.mods.newModManager()
  lurek.log.info("is LModManager: " .. tostring(mod_manager_obj:typeOf("LModManager")), "mods")
  lurek.log.info("is wrong: " .. tostring(mod_manager_obj:typeOf("Unknown")), "mods")
end


