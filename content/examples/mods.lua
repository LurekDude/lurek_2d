-- content/examples/mods.lua
-- lurek.mods API examples: mod metadata, mod manager, content registry, hooks, and version checks.
-- Run: cargo run -- content/examples/mods.lua

--@api-stub: lurek.mods.newMod
-- Creates a mod metadata handle from a Lua table
do
  -- newMod() takes a table with mod metadata fields.
  -- Required: "id" (unique string identifier using dot-notation).
  -- Optional: name, version, author, description, priority, dependencies,
  --           api_version, capabilities, config_schema, assets, signature.
  local hud_mod = lurek.mods.newMod({
    id = "core.hud",
    name = "Core HUD",
    version = "1.2.0",
    author = "studio",
    description = "Provides health bars, minimap, and status icons.",
    priority = 10,                              -- higher priority = loaded earlier
    dependencies = {"core.input"},              -- must be loaded before this mod
    capabilities = {"ui", "render"},            -- declares what subsystems it touches
    api_version = "1.0.0",                      -- minimum engine API version required
    config_schema = {                           -- declares user-facing settings
      {key = "show_minimap", type = "boolean", default = "true"},
      {key = "opacity",      type = "number",  default = "0.9"},
    },
  })
  -- The returned handle (LMod) exposes getters/setters for all fields.
  lurek.log.info("built mod " .. hud_mod:getId() .. " v" .. hud_mod:getVersion(), "mods")
end

--@api-stub: lurek.mods.newModManager
-- Creates an empty mod manager
do
  -- The mod manager handles registration, dependency validation, load order,
  -- hot-reload queues, and folder scanning. Create one per game session.
  local manager = lurek.mods.newModManager()
  -- Initially empty — use registerMod() or scanFolder() to populate it.
  lurek.log.info("manager initialised, " .. manager:getModCount() .. " mods", "mods")
end

--@api-stub: lurek.mods.checkApiVersion
-- Checks whether a mod API version is compatible with a host version
do
  -- Use this during mod loading to reject mods built for a newer engine API.
  -- The check uses semver: mod's major must equal host's, mod's minor <= host's.
  local probe = lurek.mods.newMod({id = "fan.skins", api_version = "1.4.0"})
  local host_api = "1.6.2"   -- current engine version
  local ok, msg = lurek.mods.checkApiVersion(probe, host_api)
  if ok then
    -- Compatible: mod requires 1.4.x and host is 1.6.x (same major, higher minor).
    lurek.log.info("mod is compatible with host " .. host_api, "mods")
  else
    -- Incompatible: returns false + human-readable error message.
    lurek.log.warn("incompatible mod: " .. (msg or "unknown"), "mods")
  end

  -- Example of incompatibility: mod requires major version 2 but host is 1.x
  local future_mod = lurek.mods.newMod({id = "fan.future", api_version = "2.0.0"})
  local ok2, msg2 = lurek.mods.checkApiVersion(future_mod, "1.6.2")
  if not ok2 then
    lurek.log.warn("rejected: " .. (msg2 or "major mismatch"), "mods")
  end
end

-- Mod methods

--@api-stub: Mod:getId
-- Returns the id of this mod.
do
  -- getId() returns the unique dot-notation identifier set at creation.
  -- Use it as a registry key, save-file tag, or dependency reference.
  local m = lurek.mods.newMod({id = "core.audio"})
  local registry = {}
  registry[m:getId()] = {volume = 0.8, muted = false}
  -- "core.audio" is now a key in our settings table.
  lurek.log.info("stored settings for " .. m:getId(), "mods")
end

--@api-stub: Mod:getName
-- Returns the name of this mod.
do
  -- getName() returns the human-friendly display name.
  -- Falls back to empty string if no name was provided at creation.
  local m = lurek.mods.newMod({id = "ui.theme.dark", name = "Dark Theme"})
  local label = m:getName()
  if label == "" then label = m:getId() end   -- fallback for unnamed mods
  lurek.log.info("listing: " .. label, "ui")
end

--@api-stub: Mod:getVersion
-- Returns the version of this mod.
do
  -- getVersion() returns the semver string. Use it for save compatibility
  -- checks or to display in a mod browser UI.
  local m = lurek.mods.newMod({id = "core.physics", version = "2.1.0"})
  local save_version = "2.0.0"
  if m:getVersion() ~= save_version then
    -- Warn the player that save data was written by a different mod version.
    lurek.log.warn("save was written by v" .. save_version .. ", running v" .. m:getVersion(), "save")
  end
end

--@api-stub: Mod:getAuthor
-- Returns the author of this mod.
do
  -- getAuthor() returns the mod creator's name for credits or mod browser.
  local m = lurek.mods.newMod({id = "fan.maps", author = "alice"})
  local credit = m:getAuthor()
  lurek.log.info("map pack by " .. credit, "credits")
end

--@api-stub: Mod:getDescription
-- Returns the description of this mod.
do
  -- getDescription() provides a longer text for tooltips or mod detail panels.
  local m = lurek.mods.newMod({id = "ui.minimap", description = "Adds a corner minimap with fog-of-war."})
  local detail = m:getDescription()
  lurek.log.info("about: " .. detail, "ui")
end

--@api-stub: Mod:getDependencies
-- Returns the dependencies of this mod.
do
  -- getDependencies() returns an array of mod ids that must be loaded first.
  -- The mod manager uses this for topological sort and cycle detection.
  local m = lurek.mods.newMod({id = "fan.weapons", dependencies = {"core.combat", "core.audio"}})
  for _, dep in ipairs(m:getDependencies()) do
    lurek.log.debug("requires " .. dep, "mods")
  end
end

--@api-stub: Mod:getPriority
-- Returns the priority of this mod.
do
  -- getPriority() returns an integer. Higher priority = loaded earlier.
  -- Use priority to control which mods override shared content.
  local a = lurek.mods.newMod({id = "core.base", priority = 100})
  local b = lurek.mods.newMod({id = "fan.tweak", priority = 5})
  if a:getPriority() > b:getPriority() then
    -- core.base loads before fan.tweak, so fan.tweak can override its content.
    lurek.log.info(a:getId() .. " loads before " .. b:getId(), "mods")
  end
end

--@api-stub: Mod:isEnabled
-- Returns true if this mod is currently enabled.
do
  -- isEnabled() reflects user preference. Disabled mods stay registered but
  -- are skipped during load-order resolution and hook invocation.
  local m = lurek.mods.newMod({id = "fan.cheats"})
  if m:isEnabled() then
    lurek.log.debug(m:getId() .. " is active", "mods")
  else
    lurek.log.debug(m:getId() .. " is disabled (default for new mods)", "mods")
  end
end

--@api-stub: Mod:setEnabled
-- Sets whether this mod is enabled and accepts input.
do
  -- setEnabled(bool) toggles the mod on/off without unregistering it.
  -- Call this from a settings UI or a mod-manager screen.
  local m = lurek.mods.newMod({id = "fan.skins"})
  local user_choice = false   -- user unchecked the mod in the UI
  m:setEnabled(user_choice)
  lurek.log.info(m:getId() .. " enabled=" .. tostring(m:isEnabled()), "mods")
end

--@api-stub: Mod:isLoaded
-- Returns true if this mod loaded.
do
  -- isLoaded() indicates whether the mod's init script ran successfully.
  -- Newly created mods are not loaded until the manager processes them.
  local m = lurek.mods.newMod({id = "core.input"})
  if not m:isLoaded() then
    lurek.log.debug("pending: " .. m:getId() .. " (not yet initialised)", "mods")
  end
end

--@api-stub: Mod:getApiVersion
-- Returns the api version of this mod.
do
  -- getApiVersion() returns the minimum engine API version this mod requires.
  -- Returns nil if the mod has no version requirement (always compatible).
  local m = lurek.mods.newMod({id = "fan.maps", api_version = "1.5.0"})
  local req = m:getApiVersion()
  if req then
    lurek.log.info(m:getId() .. " requires engine >= " .. req, "mods")
  else
    lurek.log.info(m:getId() .. " works with any engine version", "mods")
  end
end

--@api-stub: Mod:setApiVersion
-- Sets the api version of this mod.
do
  -- setApiVersion(str) can be used to programmatically patch a mod's requirement
  -- during testing or development.
  local m = lurek.mods.newMod({id = "test.fixture"})
  m:setApiVersion("1.6.0")
  lurek.log.debug("fixture api_version=" .. m:getApiVersion(), "test")
end

--@api-stub: Mod:getCapabilities
-- Returns the capabilities of this mod.
do
  -- getCapabilities() returns an array of subsystem names the mod accesses.
  -- Use this for sandboxing: restrict filesystem/network unless declared.
  local m = lurek.mods.newMod({id = "fan.online", capabilities = {"network", "filesystem"}})
  for _, cap in ipairs(m:getCapabilities()) do
    lurek.log.debug(m:getId() .. " uses " .. cap, "mods")
  end
end

--@api-stub: Mod:setCapabilities
-- Sets the capabilities of this mod.
do
  -- setCapabilities(table) replaces the entire capability list.
  -- Use this to grant additional permissions after user consent.
  local m = lurek.mods.newMod({id = "fan.tools"})
  local caps = m:getCapabilities()               -- current: empty
  caps[#caps + 1] = "filesystem"                  -- grant filesystem access
  m:setCapabilities(caps)
  lurek.log.debug(m:getId() .. " caps=" .. #m:getCapabilities(), "mods")
end

--@api-stub: Mod:getConfigSchema
-- Returns the config schema of this mod.
do
  -- getConfigSchema() returns an array of {key, type, default} entries.
  -- Use it to build a settings UI for the mod automatically.
  local m = lurek.mods.newMod({id = "ui.theme", config_schema = {
    {key = "accent",    type = "string",  default = "#ff8800"},
    {key = "font_size", type = "number",  default = "14"},
    {key = "dark_mode", type = "boolean", default = "true"},
  }})
  for _, entry in ipairs(m:getConfigSchema()) do
    -- Each entry has .key, .type, and .default fields.
    lurek.log.debug("setting " .. entry.key .. " (" .. entry.type .. ") = " .. entry.default, "ui")
  end
end

--@api-stub: Mod:setConfigSchema
-- Sets the config schema of this mod.
do
  -- setConfigSchema(table) replaces the schema. Each entry needs at least "key".
  -- "type" defaults to "any", "default" defaults to "".
  local m = lurek.mods.newMod({id = "fan.audio"})
  m:setConfigSchema({
    {key = "music_vol", type = "number", default = "0.8"},
    {key = "sfx_vol",   type = "number", default = "1.0"},
    {key = "mute",      type = "boolean", default = "false"},
  })
  lurek.log.debug("schema entries=" .. #m:getConfigSchema(), "mods")
end

--@api-stub: Mod:getHook
-- Returns the hook of this mod.
do
  -- getHook(name) retrieves a previously registered callback function.
  -- Returns nil if no hook is set for that name.
  local m = lurek.mods.newMod({id = "fan.combat"})
  m:setHook("on_damage", function(amount) return amount * 2 end)
  local fn = m:getHook("on_damage")
  if fn then
    -- Invoke the hook: here a damage multiplier mod doubles incoming damage.
    local result = fn(10)
    lurek.log.debug("doubled: " .. result, "combat")
  end
  -- Non-existent hooks return nil safely.
  local missing = m:getHook("on_heal")
  assert(missing == nil)
end

--@api-stub: Mod:hasHook
-- Returns true if this mod has a hook.
do
  -- hasHook(name) checks existence without retrieving the function.
  -- Useful for fast filtering: only call getHook on mods that declare it.
  local m = lurek.mods.newMod({id = "fan.input"})
  m:setHook("on_jump", function() end)
  if m:hasHook("on_jump") then
    lurek.log.debug(m:getId() .. " handles jump", "input")
  end
  assert(not m:hasHook("on_crouch"))
end

--@api-stub: Mod:getHookNames
-- Returns the hook names of this mod.
do
  -- getHookNames() returns an array of all registered hook names.
  -- Use this for debugging or building a hook dispatch table.
  local m = lurek.mods.newMod({id = "fan.events"})
  m:setHook("on_load", function() end)
  m:setHook("on_quit", function() end)
  m:setHook("on_save", function() end)
  for _, name in ipairs(m:getHookNames()) do
    lurek.log.debug(m:getId() .. " hook: " .. name, "mods")
  end
end

--@api-stub: Mod:setConfig
-- Sets the config of this mod.
do
  -- setConfig(value) stores any Lua value as the mod's runtime configuration.
  -- Typically a table matching the config_schema keys.
  local m = lurek.mods.newMod({id = "fan.audio"})
  m:setConfig({music_vol = 0.6, sfx_vol = 1.0, mute = false})
  -- The config persists on the mod handle until releaseRefs() or game shutdown.
end

--@api-stub: Mod:getConfig
-- Returns the config of this mod.
do
  -- getConfig() retrieves the stored config value. Returns nil if never set.
  -- Combine with config_schema defaults for a full settings table.
  local m = lurek.mods.newMod({id = "fan.audio"})
  m:setConfig({music_vol = 0.5})
  local cfg = m:getConfig() or {music_vol = 1.0}
  lurek.log.debug("music vol=" .. cfg.music_vol, "audio")
end

--@api-stub: Mod:releaseRefs
-- Performs the release refs operation on this mod.
do
  -- releaseRefs() drops all Lua registry references (hooks + config).
  -- Call this when unloading a mod to avoid leaking Lua objects.
  local m = lurek.mods.newMod({id = "scratch.tmp"})
  m:setHook("on_tick", function() end)
  m:setConfig({foo = 1})
  -- After releaseRefs, getHook returns nil and getConfig returns nil.
  m:releaseRefs()
  assert(m:getHook("on_tick") == nil)
  assert(m:getConfig() == nil)
end

-- ModManager methods

--@api-stub: ModManager:registerMod
-- Performs the register mod operation on this mod manager.
do
  -- registerMod(mod) adds a mod handle to the manager's registry.
  -- The manager uses the mod's id as a unique key; registering the same id
  -- again overwrites the previous entry.
  local mgr = lurek.mods.newModManager()
  local m = lurek.mods.newMod({id = "core.hud", priority = 50})
  mgr:registerMod(m)
  lurek.log.info("registered " .. mgr:getModCount() .. " mods", "mods")
end

--@api-stub: ModManager:unregisterMod
-- Performs the unregister mod operation on this mod manager.
do
  -- unregisterMod(id) removes a mod from the manager.
  -- Returns true if a mod was actually removed, false if id was not found.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "fan.skins"}))
  local removed = mgr:unregisterMod("fan.skins")
  lurek.log.info("removed=" .. tostring(removed), "mods")
  -- Removing a non-existent mod is safe and returns false.
  local noop = mgr:unregisterMod("nonexistent.mod")
  assert(noop == false)
end

--@api-stub: ModManager:hasMod
-- Returns true if this mod manager has a mod.
do
  -- hasMod(id) checks whether a mod id is currently registered.
  -- Use this before accessing mod features or optional integrations.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.combat"}))
  if mgr:hasMod("core.combat") then
    lurek.log.debug("combat system available — enabling PvP UI", "ui")
  end
  if not mgr:hasMod("fan.multiplayer") then
    lurek.log.debug("multiplayer mod not installed — hiding lobby button", "ui")
  end
end

--@api-stub: ModManager:getModCount
-- Returns the number of mod items in this mod manager.
do
  -- getModCount() returns the total number of registered mods.
  -- Useful for splash screens ("Loading 12 mods...").
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "a"}))
  mgr:registerMod(lurek.mods.newMod({id = "b"}))
  mgr:registerMod(lurek.mods.newMod({id = "c"}))
  lurek.log.info("loaded " .. mgr:getModCount() .. " mods", "boot")
end

--@api-stub: ModManager:getAllMods
-- Returns all mods values associated with this mod manager.
do
  -- getAllMods() returns an array of mod metadata tables (not LMod handles).
  -- Each entry has: id, name, version, author, priority, enabled, loaded, etc.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.hud", name = "HUD", priority = 50}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.skins", name = "Skin Pack", priority = 5}))
  for _, info in ipairs(mgr:getAllMods()) do
    lurek.log.debug(info.id .. " priority=" .. info.priority, "mods")
  end
end

--@api-stub: ModManager:getLoadOrder
-- Returns the load order of this mod manager.
do
  -- getLoadOrder() returns mods sorted by: explicit order > dependencies > priority.
  -- Higher priority mods come first; dependencies are always satisfied before dependents.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.base", priority = 100}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.ui", priority = 10, dependencies = {"core.base"}}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.audio", priority = 20}))
  -- Result: core.base (dep+priority), fan.audio (priority 20), fan.ui (priority 10, after core.base).
  for i, info in ipairs(mgr:getLoadOrder()) do
    lurek.log.info(i .. ": " .. info.id .. " (priority " .. info.priority .. ")", "mods")
  end
end

--@api-stub: ModManager:getModsByCapability
-- Returns the mods by capability of this mod manager.
do
  -- getModsByCapability(name) filters registered mods by declared capability.
  -- Use this to find all mods that touch a specific subsystem.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "fan.audio",  capabilities = {"audio"}}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.ui",     capabilities = {"ui", "render"}}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.mixer",  capabilities = {"audio", "ui"}}))
  -- Find all mods that declare "audio" capability.
  for _, info in ipairs(mgr:getModsByCapability("audio")) do
    lurek.log.info("audio-capable: " .. info.id, "mods")
  end
end

--@api-stub: ModManager:validateDependencies
-- Performs the validate dependencies operation on this mod manager.
do
  -- validateDependencies() returns an array of error messages for mods
  -- whose dependencies are not satisfied (missing from the manager).
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "fan.weapons", dependencies = {"core.combat"}}))
  -- "core.combat" is not registered, so validation will report it.
  local errors = mgr:validateDependencies()
  for _, msg in ipairs(errors) do
    lurek.log.error("missing deps: " .. msg, "mods")
  end
  -- Fix: register the missing dependency, then re-validate.
  mgr:registerMod(lurek.mods.newMod({id = "core.combat"}))
  local errors2 = mgr:validateDependencies()
  lurek.log.info("after fix: " .. #errors2 .. " errors", "mods")
end

--@api-stub: ModManager:hasCircularDependencies
-- Returns true if this mod manager has a circular dependencies.
do
  -- hasCircularDependencies() detects cycles in the dependency graph.
  -- Always check this before computing load order to avoid infinite loops.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "a", dependencies = {"b"}}))
  mgr:registerMod(lurek.mods.newMod({id = "b", dependencies = {"a"}}))
  if mgr:hasCircularDependencies() then
    lurek.log.error("dependency cycle detected — cannot compute load order", "mods")
  end
end

--@api-stub: ModManager:setLoadOrder
-- Sets the load order of this mod manager.
do
  -- setLoadOrder(ids) overrides the automatic priority-based order.
  -- Use this when the player manually reorders mods in a UI.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.base"}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.ui"}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.audio"}))
  -- Force a specific order regardless of priority values.
  mgr:setLoadOrder({"core.base", "fan.audio", "fan.ui"})
  for i, info in ipairs(mgr:getLoadOrder()) do
    lurek.log.debug(i .. ": " .. info.id, "mods")
  end
end

--@api-stub: ModManager:clearLoadOrder
-- Clears all load order items from this mod manager.
do
  -- clearLoadOrder() removes explicit ordering and reverts to automatic
  -- resolution based on priority and dependency topology.
  local mgr = lurek.mods.newModManager()
  mgr:setLoadOrder({"a", "b", "c"})
  mgr:clearLoadOrder()
  lurek.log.info("load order reset to priority-based", "mods")
end

--@api-stub: ModManager:scanFolder
-- Performs the scan folder operation on this mod manager.
do
  -- scanFolder(path) discovers mod metadata files in subdirectories.
  -- Each subfolder should contain a mod.toml or mod descriptor.
  -- Returns an array of metadata tables for discovered mods.
  local mgr = lurek.mods.newModManager()
  local discovered = mgr:scanFolder("content/plugins")
  lurek.log.info("auto-registered " .. #discovered .. " mods from content/plugins", "mods")
  -- Discovered mods are automatically registered with the manager.
end

--@api-stub: ModManager:getModPath
-- Returns the mod path of this mod manager.
do
  -- getModPath(id) returns the filesystem path for a registered mod.
  -- Returns nil if the mod has no associated path (created inline, not scanned).
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "fan.skins"}))
  local path = mgr:getModPath("fan.skins")
  if path then
    lurek.log.debug("on-disk at " .. path, "mods")
  else
    lurek.log.debug("fan.skins has no disk path (created programmatically)", "mods")
  end
end

--@api-stub: ModManager:markForReload
-- Performs the mark for reload operation on this mod manager.
do
  -- markForReload(id) queues a mod for hot-reload on the next processReloadQueue().
  -- Returns true if the mod was found and queued, false otherwise.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.hud"}))
  local queued = mgr:markForReload("core.hud")
  lurek.log.debug("queued for reload=" .. tostring(queued), "mods")
  -- Marking a non-existent mod is safe and returns false.
  local nope = mgr:markForReload("nonexistent")
  assert(nope == false)
end

--@api-stub: ModManager:getReloadQueue
-- Returns the reload queue of this mod manager.
do
  -- getReloadQueue() returns an array of mod ids pending reload.
  -- Inspect this before processing to show a "reloading..." screen.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "ui.theme"}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.audio"}))
  mgr:markForReload("ui.theme")
  mgr:markForReload("fan.audio")
  for _, id in ipairs(mgr:getReloadQueue()) do
    lurek.log.info("reload pending: " .. id, "mods")
  end
end

--@api-stub: ModManager:clearReloadQueue
-- Clears all reload queue items from this mod manager.
do
  -- clearReloadQueue() discards all pending reloads without processing them.
  -- Use this if the user cancels a reload operation.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.hud"}))
  mgr:markForReload("core.hud")
  mgr:clearReloadQueue()
  lurek.log.debug("queue size=" .. #mgr:getReloadQueue(), "mods")   -- 0
end

--@api-stub: ModManager:processReloadQueue
-- Performs the process reload queue operation on this mod manager.
do
  -- processReloadQueue() processes all queued reloads and returns the ids
  -- that were reloaded. The queue is empty after this call.
  local mgr = lurek.mods.newModManager()
  mgr:registerMod(lurek.mods.newMod({id = "core.hud"}))
  mgr:registerMod(lurek.mods.newMod({id = "fan.ui"}))
  mgr:markForReload("core.hud")
  mgr:markForReload("fan.ui")
  local reloaded = mgr:processReloadQueue()
  lurek.log.debug("reloaded count=" .. #reloaded, "mods")
  -- Queue is now empty.
  assert(#mgr:getReloadQueue() == 0)
end

-- Content Registry

--@api-stub: lurek.mods.newRegistry
-- Creates an empty content registry
do
  -- The content registry is a typed key-value store for mod-contributed content.
  -- Mods register types (categories) and then register entries under those types.
  -- Use it to let mods add weapons, spells, creatures, etc. without code changes.
  local reg = lurek.mods.newRegistry()
  lurek.log.debug("registry created with " .. #reg:getTypes() .. " types", "mods")
end

--@api-stub: ContentRegistry:registerType
-- Performs the register type operation on this content registry.
do
  -- registerType(name) declares a content category.
  -- Must be called before register() can store entries of that type.
  local reg = lurek.mods.newRegistry()
  reg:registerType("weapon")
  reg:registerType("armor")
  reg:registerType("consumable")
  lurek.log.debug("registered " .. #reg:getTypes() .. " content types", "mods")
end

--@api-stub: ContentRegistry:register
-- Performs the register operation on this content registry.
do
  -- register(type, id, value) stores any Lua value under a type+id pair.
  -- The type must be registered first. Value can be a table, string, number, etc.
  local reg = lurek.mods.newRegistry()
  reg:registerType("weapon")
  reg:register("weapon", "iron_sword", {name = "Iron Sword", damage = 12, weight = 3.5})
  reg:register("weapon", "fire_staff", {name = "Fire Staff", damage = 8, element = "fire"})
  -- Attempting to register under an unknown type raises an error.
  -- reg:register("potion", "heal", {}) -- ERROR: content type 'potion' not registered
  lurek.log.debug("registered 2 weapons", "mods")
end

--@api-stub: ContentRegistry:get
-- Returns the  of this content registry.
do
  -- get(type, id) retrieves a single entry. Returns nil if not found.
  local reg = lurek.mods.newRegistry()
  reg:registerType("spell")
  reg:register("spell", "fireball", {cost = 10, radius = 3.0, element = "fire"})
  reg:register("spell", "heal", {cost = 5, radius = 0, element = "holy"})
  local s = reg:get("spell", "fireball")
  if s then
    lurek.log.debug("fireball cost=" .. s.cost .. " radius=" .. s.radius, "mods")
  end
  -- Missing entries return nil safely.
  local missing = reg:get("spell", "nonexistent")
  assert(missing == nil)
end

--@api-stub: ContentRegistry:getAll
-- Returns all  values associated with this content registry.
do
  -- getAll(type) returns a table keyed by id with all entries of that type.
  -- Use this to iterate all mod-contributed content for a category.
  local reg = lurek.mods.newRegistry()
  reg:registerType("item")
  reg:register("item", "potion", {name = "Potion", heal = 50})
  reg:register("item", "elixir", {name = "Elixir", heal = 200})
  reg:register("item", "antidote", {name = "Antidote", cure = "poison"})
  local all = reg:getAll("item")
  -- "all" is a table: {potion = {...}, elixir = {...}, antidote = {...}}
  local count = 0
  for _ in pairs(all) do count = count + 1 end
  lurek.log.debug("item count=" .. count, "mods")
end

--@api-stub: ContentRegistry:getTypes
-- Returns the types of this content registry.
do
  -- getTypes() returns an array of all registered type names.
  -- Use this to discover what content categories are available.
  local reg = lurek.mods.newRegistry()
  reg:registerType("creature")
  reg:registerType("item")
  reg:registerType("quest")
  local types = reg:getTypes()
  lurek.log.debug("type count=" .. #types, "mods")
end

--@api-stub: Mod:setHook
-- Sets the hook of this mod.
do
  -- setHook(name, func) registers a named callback on the mod.
  -- Hooks allow mods to intercept or extend game behavior without
  -- modifying engine code. Common hook names: on_load, on_save, on_damage, etc.
  local mod = lurek.mods.newMod({id = "example_mod", name = "Example", version = "1.0"})
  mod:setHook("on_save", function(ctx)
    -- Called when the game saves — mod can persist its own data.
    lurek.log.info("mod saving extra data", "mods")
  end)
  mod:setHook("on_damage", function(amount, source)
    -- Return modified damage for a "damage reduction" mod.
    return math.max(0, amount - 5)
  end)
  lurek.log.info("hooks registered: " .. #mod:getHookNames(), "mods")
end

-- Type introspection methods

--@api-stub: LContentRegistry:type
-- Returns the Lua-visible type name for this content registry handle
do
  -- type() returns "LContentRegistry" for content registry handles.
  local reg = lurek.mods.newRegistry()
  local t = reg:type()
  assert(t == "LContentRegistry")
  lurek.log.info("LContentRegistry:type = " .. t, "mods")
end

--@api-stub: LContentRegistry:typeOf
-- Returns whether this content registry handle matches a supported type name
do
  -- typeOf(name) returns true for "LContentRegistry" and "Object".
  local reg = lurek.mods.newRegistry()
  assert(reg:typeOf("LContentRegistry") == true)
  assert(reg:typeOf("Object") == true)
  assert(reg:typeOf("Unknown") == false)
  lurek.log.info("is LContentRegistry: " .. tostring(reg:typeOf("LContentRegistry")), "mods")
end

--@api-stub: LMod:type
-- Returns the Lua-visible type name for this mod handle
do
  -- type() returns "LMod" for mod handles.
  local m = lurek.mods.newMod({id = "test.type"})
  local t = m:type()
  assert(t == "LMod")
  lurek.log.info("LMod:type = " .. t, "mods")
end

--@api-stub: LMod:typeOf
-- Returns whether this mod handle matches a supported type name
do
  -- typeOf(name) returns true for "LMod" and "Object".
  local m = lurek.mods.newMod({id = "test.typeof"})
  assert(m:typeOf("LMod") == true)
  assert(m:typeOf("Object") == true)
  assert(m:typeOf("Unknown") == false)
  lurek.log.info("is LMod: " .. tostring(m:typeOf("LMod")), "mods")
end

--@api-stub: LModManager:type
-- Returns the Lua-visible type name for this mod manager handle
do
  -- type() returns "LModManager" for mod manager handles.
  local mgr = lurek.mods.newModManager()
  local t = mgr:type()
  assert(t == "LModManager")
  lurek.log.info("LModManager:type = " .. t, "mods")
end

--@api-stub: LModManager:typeOf
-- Returns whether this mod manager handle matches a supported type name
do
  -- typeOf(name) returns true for "LModManager" and "Object".
  local mgr = lurek.mods.newModManager()
  assert(mgr:typeOf("LModManager") == true)
  assert(mgr:typeOf("Object") == true)
  assert(mgr:typeOf("Unknown") == false)
  lurek.log.info("is LModManager: " .. tostring(mgr:typeOf("LModManager")), "mods")
end

print("content/examples/mods.lua")

-- =============================================================================
-- STUBS: 45 uncovered lurek.mods API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LContentRegistry methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LContentRegistry:registerType ---------------------------------
--@api-stub: LContentRegistry:registerType
-- Registers a content type name. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContentRegistry_stub:registerType(type_name)
-- (replace lContentRegistry_stub with your real LContentRegistry instance above)

-- ---- Stub: LContentRegistry:register -------------------------------------
--@api-stub: LContentRegistry:register
-- Stores a Lua value under a registered content type and id.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContentRegistry_stub:register(type_name, 1, obj)
-- (replace lContentRegistry_stub with your real LContentRegistry instance above)

-- ---- Stub: LContentRegistry:get ------------------------------------------
--@api-stub: LContentRegistry:get
-- Returns one stored value by content type and id.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContentRegistry_stub:get(type_name, 1)  -- -> LuaValue
-- (replace lContentRegistry_stub with your real LContentRegistry instance above)

-- ---- Stub: LContentRegistry:getAll ---------------------------------------
--@api-stub: LContentRegistry:getAll
-- Returns all stored values for a content type keyed by id.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContentRegistry_stub:getAll(type_name)  -- -> table
-- (replace lContentRegistry_stub with your real LContentRegistry instance above)

-- ---- Stub: LContentRegistry:getTypes -------------------------------------
--@api-stub: LContentRegistry:getTypes
-- Returns registered content type names.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lContentRegistry_stub:getTypes()  -- -> table
-- (replace lContentRegistry_stub with your real LContentRegistry instance above)

-- -----------------------------------------------------------------------------
-- LMod methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LMod:getId ----------------------------------------------------
--@api-stub: LMod:getId
-- Returns the mod id. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getId()  -- -> string
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getName --------------------------------------------------
--@api-stub: LMod:getName
-- Returns the mod display name. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getName()  -- -> string
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getVersion -----------------------------------------------
--@api-stub: LMod:getVersion
-- Returns the mod version. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getVersion()  -- -> string
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getAuthor ------------------------------------------------
--@api-stub: LMod:getAuthor
-- Returns the mod author. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getAuthor()  -- -> string
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getDescription -------------------------------------------
--@api-stub: LMod:getDescription
-- Returns the mod description. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getDescription()  -- -> string
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getDependencies ------------------------------------------
--@api-stub: LMod:getDependencies
-- Returns mod dependency ids. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getDependencies()  -- -> table
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getPriority ----------------------------------------------
--@api-stub: LMod:getPriority
-- Returns the mod priority. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getPriority()  -- -> integer
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:isEnabled ------------------------------------------------
--@api-stub: LMod:isEnabled
-- Returns whether the mod is enabled.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:isEnabled()  -- -> boolean
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:setEnabled -----------------------------------------------
--@api-stub: LMod:setEnabled
-- Sets whether the mod is enabled. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:setEnabled(true)
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:isLoaded -------------------------------------------------
--@api-stub: LMod:isLoaded
-- Returns whether the mod is loaded. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:isLoaded()  -- -> boolean
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getApiVersion --------------------------------------------
--@api-stub: LMod:getApiVersion
-- Returns the optional required API version.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getApiVersion()  -- -> string
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:setApiVersion --------------------------------------------
--@api-stub: LMod:setApiVersion
-- Sets the required API version string.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:setApiVersion(api_version)
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getCapabilities ------------------------------------------
--@api-stub: LMod:getCapabilities
-- Returns capability names declared by the mod.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getCapabilities()  -- -> table
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:setCapabilities ------------------------------------------
--@api-stub: LMod:setCapabilities
-- Sets capability names from an array table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:setCapabilities(caps)
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getConfigSchema ------------------------------------------
--@api-stub: LMod:getConfigSchema
-- Returns config schema entries. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getConfigSchema()  -- -> table
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:setConfigSchema ------------------------------------------
--@api-stub: LMod:setConfigSchema
-- Sets config schema entries from a Lua table.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:setConfigSchema(schema)
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:setHook --------------------------------------------------
--@api-stub: LMod:setHook
-- Stores a Lua hook function by name. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:setHook("hero", func)
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getHook --------------------------------------------------
--@api-stub: LMod:getHook
-- Returns a stored hook function by name.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getHook("hero")  -- -> function
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:hasHook --------------------------------------------------
--@api-stub: LMod:hasHook
-- Returns whether a hook name is registered.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:hasHook("hero")  -- -> boolean
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getHookNames ---------------------------------------------
--@api-stub: LMod:getHookNames
-- Returns registered hook names. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getHookNames()  -- -> table
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:setConfig ------------------------------------------------
--@api-stub: LMod:setConfig
-- Stores a Lua config value for this mod.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:setConfig(42)
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:getConfig ------------------------------------------------
--@api-stub: LMod:getConfig
-- Returns the stored Lua config value.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:getConfig()  -- -> LuaValue
-- (replace lMod_stub with your real LMod instance above)

-- ---- Stub: LMod:releaseRefs ----------------------------------------------
--@api-stub: LMod:releaseRefs
-- Releases stored Lua registry references for hooks and config.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lMod_stub:releaseRefs()
-- (replace lMod_stub with your real LMod instance above)

-- -----------------------------------------------------------------------------
-- LModManager methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LModManager:registerMod ---------------------------------------
--@api-stub: LModManager:registerMod
-- Registers a mod with the manager. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:registerMod(ud)
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:unregisterMod -------------------------------------
--@api-stub: LModManager:unregisterMod
-- Unregisters a mod by id. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:unregisterMod(mod_id)  -- -> boolean
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:hasMod --------------------------------------------
--@api-stub: LModManager:hasMod
-- Returns whether a mod id is registered.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:hasMod(mod_id)  -- -> boolean
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:getModCount ---------------------------------------
--@api-stub: LModManager:getModCount
-- Returns the number of registered mods.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:getModCount()  -- -> integer
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:getAllMods ----------------------------------------
--@api-stub: LModManager:getAllMods
-- Returns metadata for all registered mods.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:getAllMods()  -- -> table
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:getModsByCapability -------------------------------
--@api-stub: LModManager:getModsByCapability
-- Returns metadata for mods declaring a capability.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:getModsByCapability(capability)  -- -> table
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:getLoadOrder --------------------------------------
--@api-stub: LModManager:getLoadOrder
-- Returns the resolved load order. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:getLoadOrder()  -- -> table
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:validateDependencies ------------------------------
--@api-stub: LModManager:validateDependencies
-- Returns dependency validation messages.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:validateDependencies()  -- -> table
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:hasCircularDependencies ---------------------------
--@api-stub: LModManager:hasCircularDependencies
-- Returns whether registered mods have circular dependencies.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:hasCircularDependencies()  -- -> boolean
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:setLoadOrder --------------------------------------
--@api-stub: LModManager:setLoadOrder
-- Sets explicit load order from an array of mod ids.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:setLoadOrder(order_table)
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:clearLoadOrder ------------------------------------
--@api-stub: LModManager:clearLoadOrder
-- Clears explicit load order. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:clearLoadOrder()
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:scanFolder ----------------------------------------
--@api-stub: LModManager:scanFolder
-- Scans a folder for mod metadata. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:scanFolder("assets/hero.png")  -- -> table
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:getModPath ----------------------------------------
--@api-stub: LModManager:getModPath
-- Returns the filesystem path for a registered mod.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:getModPath(mod_id)  -- -> string
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:markForReload -------------------------------------
--@api-stub: LModManager:markForReload
-- Marks a mod id for reload. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:markForReload(mod_id)  -- -> boolean
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:getReloadQueue ------------------------------------
--@api-stub: LModManager:getReloadQueue
-- Returns mod ids waiting for reload.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:getReloadQueue()  -- -> table
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:clearReloadQueue ----------------------------------
--@api-stub: LModManager:clearReloadQueue
-- Clears the reload queue. This method is available to Lua scripts.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:clearReloadQueue()
-- (replace lModManager_stub with your real LModManager instance above)

-- ---- Stub: LModManager:processReloadQueue --------------------------------
--@api-stub: LModManager:processReloadQueue
-- Processes and clears the reload queue.
-- TODO: replace this stub with a real scenario. See flesh-out-example.prompt.md
-- lModManager_stub:processReloadQueue()  -- -> table
-- (replace lModManager_stub with your real LModManager instance above)
