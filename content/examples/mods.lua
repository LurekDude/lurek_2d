-- content/examples/mods.lua
-- Scaffolded coverage of the lurek.mods API (40 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/mods_api.rs   (Lua binding, arg types, return shape)
--   * src/mods/                 (semantics, side effects)
--   * docs/specs/mods.md        (canonical reference)
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
-- Run: cargo run -- content/examples/mods.lua

-- ── lurek.mods.* functions ──

--@api-stub: lurek.mods.newMod
-- Creates a new Mod from an info table with at least an `id` field.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: lurek.mods.newMod
  local _todo = "TODO: write a real lurek.mods.newMod usage example"
  print(_todo)
end

--@api-stub: lurek.mods.newModManager
-- Creates a new empty ModManager.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: lurek.mods.newModManager
  local _todo = "TODO: write a real lurek.mods.newModManager usage example"
  print(_todo)
end

--@api-stub: lurek.mods.checkApiVersion
-- Checks whether a mod's required `api_version` is compatible with the given `host_version`.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: lurek.mods.checkApiVersion
  local _todo = "TODO: write a real lurek.mods.checkApiVersion usage example"
  print(_todo)
end

-- ── Mod methods ──

--@api-stub: Mod:getId
-- Returns the unique mod identifier.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getId
  local _todo = "TODO: write a real Mod:getId usage example"
  print(_todo)
end

--@api-stub: Mod:getName
-- Returns the localized or human-readable display name of the mod.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getName
  local _todo = "TODO: write a real Mod:getName usage example"
  print(_todo)
end

--@api-stub: Mod:getVersion
-- Returns the version string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getVersion
  local _todo = "TODO: write a real Mod:getVersion usage example"
  print(_todo)
end

--@api-stub: Mod:getAuthor
-- Returns the author name string from this mod's metadata manifest.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getAuthor
  local _todo = "TODO: write a real Mod:getAuthor usage example"
  print(_todo)
end

--@api-stub: Mod:getDescription
-- Returns the mod description.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getDescription
  local _todo = "TODO: write a real Mod:getDescription usage example"
  print(_todo)
end

--@api-stub: Mod:getDependencies
-- Returns the list of required mod IDs.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getDependencies
  local _todo = "TODO: write a real Mod:getDependencies usage example"
  print(_todo)
end

--@api-stub: Mod:getPriority
-- Returns the load-order priority.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getPriority
  local _todo = "TODO: write a real Mod:getPriority usage example"
  print(_todo)
end

--@api-stub: Mod:isEnabled
-- Returns whether the mod is enabled.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:isEnabled
  local _todo = "TODO: write a real Mod:isEnabled usage example"
  print(_todo)
end

--@api-stub: Mod:setEnabled
-- Enables or disables this mod; disabled mods are skipped during loading.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:setEnabled
  local _todo = "TODO: write a real Mod:setEnabled usage example"
  print(_todo)
end

--@api-stub: Mod:isLoaded
-- Returns whether the mod has been loaded.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:isLoaded
  local _todo = "TODO: write a real Mod:isLoaded usage example"
  print(_todo)
end

--@api-stub: Mod:getApiVersion
-- Returns the required engine API version string, or nil if not set.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getApiVersion
  local _todo = "TODO: write a real Mod:getApiVersion usage example"
  print(_todo)
end

--@api-stub: Mod:setApiVersion
-- Sets the required engine API version string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:setApiVersion
  local _todo = "TODO: write a real Mod:setApiVersion usage example"
  print(_todo)
end

--@api-stub: Mod:getCapabilities
-- Returns an array of declared capability flags.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getCapabilities
  local _todo = "TODO: write a real Mod:getCapabilities usage example"
  print(_todo)
end

--@api-stub: Mod:setCapabilities
-- Replaces the capability list with the given array of strings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:setCapabilities
  local _todo = "TODO: write a real Mod:setCapabilities usage example"
  print(_todo)
end

--@api-stub: Mod:getConfigSchema
-- Returns the config schema as an array of `{key, type, default}` tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getConfigSchema
  local _todo = "TODO: write a real Mod:getConfigSchema usage example"
  print(_todo)
end

--@api-stub: Mod:setConfigSchema
-- Replaces the config schema with the given array of `{key, type, default}` tables.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:setConfigSchema
  local _todo = "TODO: write a real Mod:setConfigSchema usage example"
  print(_todo)
end

--@api-stub: Mod:getHook
-- Returns the hook function for the given name, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getHook
  local _todo = "TODO: write a real Mod:getHook usage example"
  print(_todo)
end

--@api-stub: Mod:hasHook
-- Returns whether a hook with the given name exists.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:hasHook
  local _todo = "TODO: write a real Mod:hasHook usage example"
  print(_todo)
end

--@api-stub: Mod:getHookNames
-- Returns an array of registered hook names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getHookNames
  local _todo = "TODO: write a real Mod:getHookNames usage example"
  print(_todo)
end

--@api-stub: Mod:setConfig
-- Stores an arbitrary config value for this mod.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:setConfig
  local _todo = "TODO: write a real Mod:setConfig usage example"
  print(_todo)
end

--@api-stub: Mod:getConfig
-- Returns the stored config value, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:getConfig
  local _todo = "TODO: write a real Mod:getConfig usage example"
  print(_todo)
end

--@api-stub: Mod:releaseRefs
-- Releases all hook and config registry references.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: Mod:releaseRefs
  local _todo = "TODO: write a real Mod:releaseRefs usage example"
  print(_todo)
end

-- ── ModManager methods ──

--@api-stub: ModManager:registerMod
-- Registers a mod from its Mod userdata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:registerMod
  local _todo = "TODO: write a real ModManager:registerMod usage example"
  print(_todo)
end

--@api-stub: ModManager:unregisterMod
-- Removes a mod by ID and returns whether it was found.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:unregisterMod
  local _todo = "TODO: write a real ModManager:unregisterMod usage example"
  print(_todo)
end

--@api-stub: ModManager:hasMod
-- Returns whether a mod with the given ID is registered.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:hasMod
  local _todo = "TODO: write a real ModManager:hasMod usage example"
  print(_todo)
end

--@api-stub: ModManager:getModCount
-- Returns the number of registered mods.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:getModCount
  local _todo = "TODO: write a real ModManager:getModCount usage example"
  print(_todo)
end

--@api-stub: ModManager:getAllMods
-- Returns an array of info tables for all registered mods.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:getAllMods
  local _todo = "TODO: write a real ModManager:getAllMods usage example"
  print(_todo)
end

--@api-stub: ModManager:getLoadOrder
-- Returns an array of info tables in effective load order.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:getLoadOrder
  local _todo = "TODO: write a real ModManager:getLoadOrder usage example"
  print(_todo)
end

--@api-stub: ModManager:validateDependencies
-- Returns an array of mod IDs with missing dependencies.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:validateDependencies
  local _todo = "TODO: write a real ModManager:validateDependencies usage example"
  print(_todo)
end

--@api-stub: ModManager:hasCircularDependencies
-- Returns whether any circular dependency cycles exist.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:hasCircularDependencies
  local _todo = "TODO: write a real ModManager:hasCircularDependencies usage example"
  print(_todo)
end

--@api-stub: ModManager:setLoadOrder
-- Sets an explicit load order from an array of mod ID strings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:setLoadOrder
  local _todo = "TODO: write a real ModManager:setLoadOrder usage example"
  print(_todo)
end

--@api-stub: ModManager:clearLoadOrder
-- Clears the custom load order, reverting to priority-based sorting.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:clearLoadOrder
  local _todo = "TODO: write a real ModManager:clearLoadOrder usage example"
  print(_todo)
end

--@api-stub: ModManager:scanFolder
-- Scans a directory for mods with mod.toml and registers them.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:scanFolder
  local _todo = "TODO: write a real ModManager:scanFolder usage example"
  print(_todo)
end

--@api-stub: ModManager:getModPath
-- Returns the filesystem path of a registered mod, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:getModPath
  local _todo = "TODO: write a real ModManager:getModPath usage example"
  print(_todo)
end

--@api-stub: ModManager:markForReload
-- Marks a registered mod for hot-reload.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:markForReload
  local _todo = "TODO: write a real ModManager:markForReload usage example"
  print(_todo)
end

--@api-stub: ModManager:getReloadQueue
-- Returns the array of mod IDs pending hot-reload.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:getReloadQueue
  local _todo = "TODO: write a real ModManager:getReloadQueue usage example"
  print(_todo)
end

--@api-stub: ModManager:clearReloadQueue
-- Clears the reload queue without reloading.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/mods_api.rs and docs/specs/mods.md).
do  -- TODO: ModManager:clearReloadQueue
  local _todo = "TODO: write a real ModManager:clearReloadQueue usage example"
  print(_todo)
end

