-- content/examples/mods.lua
-- Practical usage examples for the lurek.mods API (40 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.mods.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/mods.lua

print("[example] lurek.mods — 40 API entries")

-- ── lurek.mods.* free functions ──

--@api-stub: lurek.mods.newMod
-- Creates a new Mod from an info table with at least an `id` field.
-- Call when you need to create a new mod.
local ok, obj = pcall(function() return lurek.mods.newMod(nil) end)
if ok and obj then print("created:", obj) end
print("lurek.mods.newMod ok=", ok)

--@api-stub: lurek.mods.newModManager
-- Creates a new empty ModManager.
-- Call when you need to create a new mod manager.
local ok, obj = pcall(function() return lurek.mods.newModManager() end)
if ok and obj then print("created:", obj) end
print("lurek.mods.newModManager ok=", ok)

--@api-stub: lurek.mods.checkApiVersion
-- Checks whether a mod's required `api_version` is compatible with the given `host_version`.
-- Call when you need to invoke check api version.
local ok, result = pcall(function() return lurek.mods.checkApiVersion(nil, nil) end)
if ok then print("lurek.mods.checkApiVersion ->", result)
else print("unavailable:", result) end

-- ── Mod methods ──

--@api-stub: Mod:getId
-- Returns the unique mod identifier.
-- Call when you need to read id.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getId() end)
  print("Mod:getId ->", ok, result)
end

--@api-stub: Mod:getName
-- Returns the localized or human-readable display name of the mod.
-- Call when you need to read name.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("Mod:getName ->", ok, result)
end

--@api-stub: Mod:getVersion
-- Returns the version string.
-- Call when you need to read version.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getVersion() end)
  print("Mod:getVersion ->", ok, result)
end

--@api-stub: Mod:getAuthor
-- Returns the author name string from this mod's metadata manifest.
-- Call when you need to read author.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getAuthor() end)
  print("Mod:getAuthor ->", ok, result)
end

--@api-stub: Mod:getDescription
-- Returns the mod description.
-- Call when you need to read description.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getDescription() end)
  print("Mod:getDescription ->", ok, result)
end

--@api-stub: Mod:getDependencies
-- Returns the list of required mod IDs.
-- Call when you need to read dependencies.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getDependencies() end)
  print("Mod:getDependencies ->", ok, result)
end

--@api-stub: Mod:getPriority
-- Returns the load-order priority.
-- Call when you need to read priority.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getPriority() end)
  print("Mod:getPriority ->", ok, result)
end

--@api-stub: Mod:isEnabled
-- Returns whether the mod is enabled.
-- Call when you need to check is enabled.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:isEnabled() end)
  print("Mod:isEnabled ->", ok, result)
end

--@api-stub: Mod:setEnabled
-- Enables or disables this mod; disabled mods are skipped during loading.
-- Call when you need to assign enabled.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:setEnabled(nil) end)
  print("Mod:setEnabled ->", ok, result)
end

--@api-stub: Mod:isLoaded
-- Returns whether the mod has been loaded.
-- Call when you need to check is loaded.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:isLoaded() end)
  print("Mod:isLoaded ->", ok, result)
end

--@api-stub: Mod:getApiVersion
-- Returns the required engine API version string, or nil if not set.
-- Call when you need to read api version.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getApiVersion() end)
  print("Mod:getApiVersion ->", ok, result)
end

--@api-stub: Mod:setApiVersion
-- Sets the required engine API version string.
-- Call when you need to assign api version.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:setApiVersion(nil) end)
  print("Mod:setApiVersion ->", ok, result)
end

--@api-stub: Mod:getCapabilities
-- Returns an array of declared capability flags.
-- Call when you need to read capabilities.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getCapabilities() end)
  print("Mod:getCapabilities ->", ok, result)
end

--@api-stub: Mod:setCapabilities
-- Replaces the capability list with the given array of strings.
-- Call when you need to assign capabilities.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:setCapabilities(nil) end)
  print("Mod:setCapabilities ->", ok, result)
end

--@api-stub: Mod:getConfigSchema
-- Returns the config schema as an array of `{key, type, default}` tables.
-- Call when you need to read config schema.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getConfigSchema() end)
  print("Mod:getConfigSchema ->", ok, result)
end

--@api-stub: Mod:setConfigSchema
-- Replaces the config schema with the given array of `{key, type, default}` tables.
-- Call when you need to assign config schema.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:setConfigSchema(nil) end)
  print("Mod:setConfigSchema ->", ok, result)
end

--@api-stub: Mod:getHook
-- Returns the hook function for the given name, or nil.
-- Call when you need to read hook.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getHook("name") end)
  print("Mod:getHook ->", ok, result)
end

--@api-stub: Mod:hasHook
-- Returns whether a hook with the given name exists.
-- Call when you need to check has hook.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:hasHook("name") end)
  print("Mod:hasHook ->", ok, result)
end

--@api-stub: Mod:getHookNames
-- Returns an array of registered hook names.
-- Call when you need to read hook names.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getHookNames() end)
  print("Mod:getHookNames ->", ok, result)
end

--@api-stub: Mod:setConfig
-- Stores an arbitrary config value for this mod.
-- Call when you need to assign config.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:setConfig(nil) end)
  print("Mod:setConfig ->", ok, result)
end

--@api-stub: Mod:getConfig
-- Returns the stored config value, or nil.
-- Call when you need to read config.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:getConfig() end)
  print("Mod:getConfig ->", ok, result)
end

--@api-stub: Mod:releaseRefs
-- Releases all hook and config registry references.
-- Call when you need to invoke release refs.
-- Build a Mod via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newMod(...)
if instance then
  local ok, result = pcall(function() return instance:releaseRefs() end)
  print("Mod:releaseRefs ->", ok, result)
end

-- ── ModManager methods ──

--@api-stub: ModManager:registerMod
-- Registers a mod from its Mod userdata.
-- Call when you need to invoke register mod.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:registerMod(nil) end)
  print("ModManager:registerMod ->", ok, result)
end

--@api-stub: ModManager:unregisterMod
-- Removes a mod by ID and returns whether it was found.
-- Call when you need to invoke unregister mod.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:unregisterMod(1) end)
  print("ModManager:unregisterMod ->", ok, result)
end

--@api-stub: ModManager:hasMod
-- Returns whether a mod with the given ID is registered.
-- Call when you need to check has mod.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:hasMod(1) end)
  print("ModManager:hasMod ->", ok, result)
end

--@api-stub: ModManager:getModCount
-- Returns the number of registered mods.
-- Call when you need to read mod count.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:getModCount() end)
  print("ModManager:getModCount ->", ok, result)
end

--@api-stub: ModManager:getAllMods
-- Returns an array of info tables for all registered mods.
-- Call when you need to read all mods.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:getAllMods() end)
  print("ModManager:getAllMods ->", ok, result)
end

--@api-stub: ModManager:getLoadOrder
-- Returns an array of info tables in effective load order.
-- Call when you need to read load order.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:getLoadOrder() end)
  print("ModManager:getLoadOrder ->", ok, result)
end

--@api-stub: ModManager:validateDependencies
-- Returns an array of mod IDs with missing dependencies.
-- Call when you need to invoke validate dependencies.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:validateDependencies() end)
  print("ModManager:validateDependencies ->", ok, result)
end

--@api-stub: ModManager:hasCircularDependencies
-- Returns whether any circular dependency cycles exist.
-- Call when you need to check has circular dependencies.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:hasCircularDependencies() end)
  print("ModManager:hasCircularDependencies ->", ok, result)
end

--@api-stub: ModManager:setLoadOrder
-- Sets an explicit load order from an array of mod ID strings.
-- Call when you need to assign load order.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:setLoadOrder({}) end)
  print("ModManager:setLoadOrder ->", ok, result)
end

--@api-stub: ModManager:clearLoadOrder
-- Clears the custom load order, reverting to priority-based sorting.
-- Call when you need to invoke clear load order.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:clearLoadOrder() end)
  print("ModManager:clearLoadOrder ->", ok, result)
end

--@api-stub: ModManager:scanFolder
-- Scans a directory for mods with mod.toml and registers them.
-- Call when you need to invoke scan folder.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:scanFolder("path") end)
  print("ModManager:scanFolder ->", ok, result)
end

--@api-stub: ModManager:getModPath
-- Returns the filesystem path of a registered mod, or nil.
-- Call when you need to read mod path.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:getModPath(1) end)
  print("ModManager:getModPath ->", ok, result)
end

--@api-stub: ModManager:markForReload
-- Marks a registered mod for hot-reload.
-- Call when you need to invoke mark for reload.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:markForReload(1) end)
  print("ModManager:markForReload ->", ok, result)
end

--@api-stub: ModManager:getReloadQueue
-- Returns the array of mod IDs pending hot-reload.
-- Call when you need to read reload queue.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:getReloadQueue() end)
  print("ModManager:getReloadQueue ->", ok, result)
end

--@api-stub: ModManager:clearReloadQueue
-- Clears the reload queue without reloading.
-- Call when you need to invoke clear reload queue.
-- Build a ModManager via the appropriate lurek.mods.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.mods.newModManager(...)
if instance then
  local ok, result = pcall(function() return instance:clearReloadQueue() end)
  print("ModManager:clearReloadQueue ->", ok, result)
end

