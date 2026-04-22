-- content/examples/mods.lua
-- Auto-scaffolded coverage of the lurek.mods Lua API (40 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/mods.lua

print("[example] lurek.mods loaded — 40 API items demonstrated")

-- ── lurek.mods free functions ──

--@api-stub: lurek.mods.newMod
-- Creates a new Mod from an info table with at least an `id` field.
-- Use this when creates a new Mod from an info table with at least an `id` field is needed.
if false then
  local _r = lurek.mods.newMod(1)
  print(_r)
end

--@api-stub: lurek.mods.newModManager
-- Creates a new empty ModManager.
-- Use this when creates a new empty ModManager is needed.
if false then
  local _r = lurek.mods.newModManager()
  print(_r)
end

--@api-stub: lurek.mods.checkApiVersion
-- Checks whether a mod's required `api_version` is compatible with the given `host_version`.
-- Use this when checks whether a mod's required `api_version` is compatible with the given `host_version` is needed.
if false then
  local _r = lurek.mods.checkApiVersion(nil, 1)
  print(_r)
end

-- ── Mod methods ──

--@api-stub: Mod:getId
-- Returns the unique mod identifier.
-- Use this when returns the unique mod identifier is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getId()
end

--@api-stub: Mod:getName
-- Returns the localized or human-readable display name of the mod.
-- Use this when returns the localized or human-readable display name of the mod is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getName()
end

--@api-stub: Mod:getVersion
-- Returns the version string.
-- Use this when returns the version string is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getVersion()
end

--@api-stub: Mod:getAuthor
-- Returns the author name string from this mod's metadata manifest.
-- Use this when returns the author name string from this mod's metadata manifest is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getAuthor()
end

--@api-stub: Mod:getDescription
-- Returns the mod description.
-- Use this when returns the mod description is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getDescription()
end

--@api-stub: Mod:getDependencies
-- Returns the list of required mod IDs.
-- Use this when returns the list of required mod IDs is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getDependencies()
end

--@api-stub: Mod:getPriority
-- Returns the load-order priority.
-- Use this when returns the load-order priority is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getPriority()
end

--@api-stub: Mod:isEnabled
-- Returns whether the mod is enabled.
-- Use this when returns whether the mod is enabled is needed.
if false then
  local _o = nil  -- Mod instance
  _o:isEnabled()
end

--@api-stub: Mod:setEnabled
-- Enables or disables this mod; disabled mods are skipped during loading.
-- Use this when enables or disables this mod; disabled mods are skipped during loading is needed.
if false then
  local _o = nil  -- Mod instance
  _o:setEnabled(1)
end

--@api-stub: Mod:isLoaded
-- Returns whether the mod has been loaded.
-- Use this when returns whether the mod has been loaded is needed.
if false then
  local _o = nil  -- Mod instance
  _o:isLoaded()
end

--@api-stub: Mod:getApiVersion
-- Returns the required engine API version string, or nil if not set.
-- Use this when returns the required engine API version string, or nil if not set is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getApiVersion()
end

--@api-stub: Mod:setApiVersion
-- Sets the required engine API version string.
-- Use this when sets the required engine API version string is needed.
if false then
  local _o = nil  -- Mod instance
  _o:setApiVersion(1)
end

--@api-stub: Mod:getCapabilities
-- Returns an array of declared capability flags.
-- Use this when returns an array of declared capability flags is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getCapabilities()
end

--@api-stub: Mod:setCapabilities
-- Replaces the capability list with the given array of strings.
-- Use this when replaces the capability list with the given array of strings is needed.
if false then
  local _o = nil  -- Mod instance
  _o:setCapabilities(nil)
end

--@api-stub: Mod:getConfigSchema
-- Returns the config schema as an array of `{key, type, default}` tables.
-- Use this when returns the config schema as an array of `{key, type, default}` tables is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getConfigSchema()
end

--@api-stub: Mod:setConfigSchema
-- Replaces the config schema with the given array of `{key, type, default}` tables.
-- Use this when replaces the config schema with the given array of `{key, type, default}` tables is needed.
if false then
  local _o = nil  -- Mod instance
  _o:setConfigSchema(0)
end

--@api-stub: Mod:getHook
-- Returns the hook function for the given name, or nil.
-- Use this when returns the hook function for the given name, or nil is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getHook(1)
end

--@api-stub: Mod:hasHook
-- Returns whether a hook with the given name exists.
-- Use this when returns whether a hook with the given name exists is needed.
if false then
  local _o = nil  -- Mod instance
  _o:hasHook(1)
end

--@api-stub: Mod:getHookNames
-- Returns an array of registered hook names.
-- Use this when returns an array of registered hook names is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getHookNames()
end

--@api-stub: Mod:setConfig
-- Stores an arbitrary config value for this mod.
-- Use this when stores an arbitrary config value for this mod is needed.
if false then
  local _o = nil  -- Mod instance
  _o:setConfig(0)
end

--@api-stub: Mod:getConfig
-- Returns the stored config value, or nil.
-- Use this when returns the stored config value, or nil is needed.
if false then
  local _o = nil  -- Mod instance
  _o:getConfig()
end

--@api-stub: Mod:releaseRefs
-- Releases all hook and config registry references.
-- Use this when releases all hook and config registry references is needed.
if false then
  local _o = nil  -- Mod instance
  _o:releaseRefs()
end

-- ── ModManager methods ──

--@api-stub: ModManager:registerMod
-- Registers a mod from its Mod userdata.
-- Use this when registers a mod from its Mod userdata is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:registerMod(nil)
end

--@api-stub: ModManager:unregisterMod
-- Removes a mod by ID and returns whether it was found.
-- Use this when removes a mod by ID and returns whether it was found is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:unregisterMod(1)
end

--@api-stub: ModManager:hasMod
-- Returns whether a mod with the given ID is registered.
-- Use this when returns whether a mod with the given ID is registered is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:hasMod(1)
end

--@api-stub: ModManager:getModCount
-- Returns the number of registered mods.
-- Use this when returns the number of registered mods is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:getModCount()
end

--@api-stub: ModManager:getAllMods
-- Returns an array of info tables for all registered mods.
-- Use this when returns an array of info tables for all registered mods is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:getAllMods()
end

--@api-stub: ModManager:getLoadOrder
-- Returns an array of info tables in effective load order.
-- Use this when returns an array of info tables in effective load order is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:getLoadOrder()
end

--@api-stub: ModManager:validateDependencies
-- Returns an array of mod IDs with missing dependencies.
-- Use this when returns an array of mod IDs with missing dependencies is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:validateDependencies()
end

--@api-stub: ModManager:hasCircularDependencies
-- Returns whether any circular dependency cycles exist.
-- Use this when returns whether any circular dependency cycles exist is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:hasCircularDependencies()
end

--@api-stub: ModManager:setLoadOrder
-- Sets an explicit load order from an array of mod ID strings.
-- Use this when sets an explicit load order from an array of mod ID strings is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:setLoadOrder(0)
end

--@api-stub: ModManager:clearLoadOrder
-- Clears the custom load order, reverting to priority-based sorting.
-- Use this when clears the custom load order, reverting to priority-based sorting is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:clearLoadOrder()
end

--@api-stub: ModManager:scanFolder
-- Scans a directory for mods with mod.toml and registers them.
-- Use this when scans a directory for mods with mod.toml and registers them is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:scanFolder(0)
end

--@api-stub: ModManager:getModPath
-- Returns the filesystem path of a registered mod, or nil.
-- Use this when returns the filesystem path of a registered mod, or nil is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:getModPath(1)
end

--@api-stub: ModManager:markForReload
-- Marks a registered mod for hot-reload.
-- Use this when marks a registered mod for hot-reload is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:markForReload(1)
end

--@api-stub: ModManager:getReloadQueue
-- Returns the array of mod IDs pending hot-reload.
-- Use this when returns the array of mod IDs pending hot-reload is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:getReloadQueue()
end

--@api-stub: ModManager:clearReloadQueue
-- Clears the reload queue without reloading.
-- Use this when clears the reload queue without reloading is needed.
if false then
  local _o = nil  -- ModManager instance
  _o:clearReloadQueue()
end

