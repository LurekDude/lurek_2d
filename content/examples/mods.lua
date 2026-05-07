-- content/examples/mods.lua
-- Hand-written coverage of the lurek.mods API (40 items).
--
-- The lurek.mods namespace builds and arranges Mod metadata records
-- (id, version, dependencies, priority, capabilities, config schema,
-- hooks) and exposes a ModManager that resolves load order, validates
-- dependency graphs, and tracks a hot-reload queue. Everything below
-- runs against in-memory metadata; no Lua chunks are executed by the
-- mod loader itself.
--
-- Run: cargo run -- content/examples/mods.lua

-- â”€â”€ lurek.mods.* functions â”€â”€

--@api-stub: lurek.mods.newMod
-- Creates a new Mod from an info table with at least an `id` field.
-- Build the Mod once at load time and stash it on a registry table; reuse the same userdata when registering with a manager.
-- if false then -- lurek.mods.newMod
--   local hud_mod = lurek.mods.newMod({
--     id = "core.hud",
--     name = "Core HUD",
--     version = "1.2.0",
--     author = "studio",
--     priority = 10,
--     dependencies = {"core.input"},
--   })
--   lurek.log.info("built mod " .. hud_mod:getId() .. " v" .. hud_mod:getVersion(), "mods")
-- end

--@api-stub: lurek.mods.newModManager
-- Creates a new empty ModManager.
-- Create exactly one ModManager per game and keep it on a module-level local so every system shares the same registry.
-- if false then -- lurek.mods.newModManager
--   local manager = lurek.mods.newModManager()
--   lurek.log.info("manager initialised, " .. manager:getModCount() .. " mods", "mods")
-- end

--@api-stub: lurek.mods.checkApiVersion
-- Checks whether a mod's required `api_version` is compatible with the given `host_version`.
-- Call before registerMod when loading third-party content; reject the mod when ok is false and surface the message to the user.
-- if false then -- lurek.mods.checkApiVersion
--   local probe = lurek.mods.newMod({id = "fan.skins", api_version = "1.4.0"})
--   local ok, msg = lurek.mods.checkApiVersion(probe, "1.6.2")
--   if not ok then
--     lurek.log.warn("incompatible mod: " .. (msg or "unknown"), "mods")
--   end
-- end

-- â”€â”€ Mod methods â”€â”€

--@api-stub: LMod:getId
-- Returns the unique mod identifier.
-- Use the id as the key when storing per-mod state in your own tables; it is guaranteed stable across restarts.
-- if false then -- Mod:getId
--   local m = lurek.mods.newMod({id = "core.audio"})
--   local registry = {}
--   registry[m:getId()] = {volume = 0.8}
-- end

--@api-stub: LMod:getName
-- Returns the localized or human-readable display name of the mod.
-- Show getName() in the mod-list UI; falls back to an empty string when the manifest omits the field.
-- if false then -- Mod:getName
--   local m = lurek.mods.newMod({id = "ui.theme.dark", name = "Dark Theme"})
--   local label = m:getName()
--   if label == "" then label = m:getId() end
--   lurek.log.info("listing: " .. label, "ui")
-- end

--@api-stub: LMod:getVersion
-- Returns the version string.
-- Compare against an expected version string when validating save-file compatibility before loading mod-owned data.
-- if false then -- Mod:getVersion
--   local m = lurek.mods.newMod({id = "core.physics", version = "2.1.0"})
--   if m:getVersion() ~= "2.1.0" then
--     lurek.log.warn("save was written by " .. m:getVersion(), "save")
--   end
-- end

--@api-stub: LMod:getAuthor
-- Returns the author name string from this mod's metadata manifest.
-- Display in credits and "report bug" dialogs so players know who to contact about a misbehaving mod.
-- if false then -- Mod:getAuthor
--   local m = lurek.mods.newMod({id = "fan.maps", author = "alice"})
--   local credit = m:getAuthor()
--   lurek.log.info("map pack by " .. credit, "credits")
-- end

--@api-stub: LMod:getDescription
-- Returns the mod description.
-- Render as a tooltip or detail-panel paragraph; treat as untrusted user text and avoid embedding in HTML/markup directly.
-- if false then -- Mod:getDescription
--   local m = lurek.mods.newMod({id = "ui.minimap", description = "Adds a corner minimap with fog-of-war."})
--   local detail = m:getDescription()
--   lurek.log.info("about: " .. detail, "ui")
-- end

--@api-stub: LMod:getDependencies
-- Returns the list of required mod IDs.
-- Iterate the result to ensure every dependency is registered before activating this mod's hooks.
-- if false then -- Mod:getDependencies
--   local m = lurek.mods.newMod({id = "fan.weapons", dependencies = {"core.combat", "core.audio"}})
--   for _, dep in ipairs(m:getDependencies()) do
--     lurek.log.debug("requires " .. dep, "mods")
--   end
-- end

--@api-stub: LMod:getPriority
-- Returns the load-order priority.
-- Higher priority mods load first; use it to sort a mod-list UI so foundational mods appear at the top.
-- if false then -- Mod:getPriority
--   local a = lurek.mods.newMod({id = "core.base", priority = 100})
--   local b = lurek.mods.newMod({id = "fan.tweak", priority = 5})
--   if a:getPriority() > b:getPriority() then
--     lurek.log.info(a:getId() .. " loads before " .. b:getId(), "mods")
--   end
-- end

--@api-stub: LMod:isEnabled
-- Returns whether the mod is enabled.
-- Skip rendering and hook dispatch for disabled mods; default is true unless the manifest explicitly disables it.
-- if false then -- Mod:isEnabled
--   local m = lurek.mods.newMod({id = "fan.cheats"})
--   if m:isEnabled() then
--     lurek.log.debug(m:getId() .. " is active", "mods")
--   end
-- end

--@api-stub: LMod:setEnabled
-- Enables or disables this mod; disabled mods are skipped during loading.
-- Call when the user toggles a checkbox in the mod-manager UI; persist the result so the choice survives restarts.
-- if false then -- Mod:setEnabled
--   local m = lurek.mods.newMod({id = "fan.skins"})
--   local user_choice = false
--   m:setEnabled(user_choice)
--   lurek.log.info(m:getId() .. " enabled=" .. tostring(m:isEnabled()), "mods")
-- end

--@api-stub: LMod:isLoaded
-- Returns whether the mod has been loaded.
-- Use to short-circuit re-registration logic and to drive a "loaded/unloaded" badge in the mod list.
-- if false then -- Mod:isLoaded
--   local m = lurek.mods.newMod({id = "core.input"})
--   if not m:isLoaded() then
--     lurek.log.debug("pending: " .. m:getId(), "mods")
--   end
-- end

--@api-stub: LMod:getApiVersion
-- Returns the required engine API version string, or nil if not set.
-- Branch on nil to treat absent api_version as "any version"; otherwise gate loading on a semver comparison.
-- if false then -- Mod:getApiVersion
--   local m = lurek.mods.newMod({id = "fan.maps", api_version = "1.5.0"})
--   local req = m:getApiVersion()
--   if req then
--     lurek.log.info(m:getId() .. " requires engine >= " .. req, "mods")
--   end
-- end

--@api-stub: LMod:setApiVersion
-- Sets the required engine API version string.
-- Use during programmatic mod construction (tests, scripted manifests) to declare the engine surface the mod was authored against.
-- if false then -- Mod:setApiVersion
--   local m = lurek.mods.newMod({id = "test.fixture"})
--   m:setApiVersion("1.6.0")
--   lurek.log.debug("fixture api_version=" .. m:getApiVersion(), "test")
-- end

--@api-stub: LMod:getCapabilities
-- Returns an array of declared capability flags.
-- Treat capabilities as a permissions list; check membership before letting a mod register network or filesystem hooks.
-- if false then -- Mod:getCapabilities
--   local m = lurek.mods.newMod({id = "fan.online", capabilities = {"network", "filesystem"}})
--   for _, cap in ipairs(m:getCapabilities()) do
--     lurek.log.debug(m:getId() .. " uses " .. cap, "mods")
--   end
-- end

--@api-stub: LMod:setCapabilities
-- Replaces the capability list with the given array of strings.
-- Replaces the entire list â€” read getCapabilities() first if you only want to add one entry.
-- if false then -- Mod:setCapabilities
--   local m = lurek.mods.newMod({id = "fan.tools"})
--   local caps = m:getCapabilities()
--   caps[#caps + 1] = "filesystem"
--   m:setCapabilities(caps)
-- end

--@api-stub: LMod:getConfigSchema
-- Returns the config schema as an array of `{key, type, default}` tables.
-- Walk the schema to generate a settings UI dynamically â€” one row per entry with the right widget for the type.
-- if false then -- Mod:getConfigSchema
--   local m = lurek.mods.newMod({id = "ui.theme", config_schema = {
--     {key = "accent", type = "string", default = "#ff8800"},
--   }})
--   for _, entry in ipairs(m:getConfigSchema()) do
--     lurek.log.debug("setting " .. entry.key .. " (" .. entry.type .. ")", "ui")
--   end
-- end

--@api-stub: LMod:setConfigSchema
-- Replaces the config schema with the given array of `{key, type, default}` tables.
-- Use when the schema is computed at runtime (e.g. derived from a TOML manifest) instead of supplied to newMod.
-- if false then -- Mod:setConfigSchema
--   local m = lurek.mods.newMod({id = "fan.audio"})
--   m:setConfigSchema({
--     {key = "music_vol", type = "number", default = "0.8"},
--     {key = "sfx_vol",   type = "number", default = "1.0"},
--   })
-- end

--@api-stub: LMod:getHook
-- Returns the hook function for the given name, or nil.
-- Returns nil when the hook is not registered, so always check before invoking â€” calling nil panics the script.
-- if false then -- Mod:getHook
--   local m = lurek.mods.newMod({id = "fan.combat"})
--   m:setHook("on_damage", function(amount) return amount * 2 end)
--   local fn = m:getHook("on_damage")
--   if fn then lurek.log.debug("doubled: " .. fn(10), "combat") end
-- end

--@api-stub: LMod:hasHook
-- Returns whether a hook with the given name exists.
-- Cheaper than getHook() when you only need to know whether to dispatch; avoids the registry-value clone.
-- if false then -- Mod:hasHook
--   local m = lurek.mods.newMod({id = "fan.input"})
--   m:setHook("on_jump", function() end)
--   if m:hasHook("on_jump") then
--     lurek.log.debug(m:getId() .. " handles jump", "input")
--   end
-- end

--@api-stub: LMod:getHookNames
-- Returns an array of registered hook names.
-- Iterate to dispatch every named callback during a global event, or to print a debug summary of a mod's surface.
-- if false then -- Mod:getHookNames
--   local m = lurek.mods.newMod({id = "fan.events"})
--   m:setHook("on_load", function() end)
--   m:setHook("on_quit", function() end)
--   for _, name in ipairs(m:getHookNames()) do
--     lurek.log.debug(m:getId() .. " hook: " .. name, "mods")
--   end
-- end

--@api-stub: LMod:setConfig
-- Stores an arbitrary config value for this mod.
-- Persist the user's runtime choices (a table) here so the mod itself owns the state â€” no global config table needed.
-- if false then -- Mod:setConfig
--   local m = lurek.mods.newMod({id = "fan.audio"})
--   m:setConfig({music_vol = 0.6, sfx_vol = 1.0, mute = false})
-- end

--@api-stub: LMod:getConfig
-- Returns the stored config value, or nil.
-- Returns nil before setConfig has been called; default to a safe fallback rather than indexing nil.
-- if false then -- Mod:getConfig
--   local m = lurek.mods.newMod({id = "fan.audio"})
--   m:setConfig({music_vol = 0.5})
--   local cfg = m:getConfig() or {music_vol = 1.0}
--   lurek.log.debug("music vol=" .. cfg.music_vol, "audio")
-- end

--@api-stub: LMod:releaseRefs
-- Releases all hook and config registry references.
-- Call before discarding a mod userdata to free its Lua-registry slots; otherwise the GC keeps the closures alive.
-- if false then -- Mod:releaseRefs
--   local m = lurek.mods.newMod({id = "scratch.tmp"})
--   m:setHook("on_tick", function() end)
--   m:setConfig({foo = 1})
--   m:releaseRefs()
-- end

-- â”€â”€ ModManager methods â”€â”€

--@api-stub: LModManager:registerMod
-- Registers a mod from its Mod userdata.
-- The manager copies the underlying ModInfo, so further edits to the Mod userdata won't show up â€” register last.
-- if false then -- ModManager:registerMod
--   local mgr = lurek.mods.newModManager()
--   local m = lurek.mods.newMod({id = "core.hud", priority = 50})
--   mgr:registerMod(m)
--   lurek.log.info("registered " .. mgr:getModCount() .. " mods", "mods")
-- end

--@api-stub: LModManager:unregisterMod
-- Removes a mod by ID and returns whether it was found.
-- Returns false when the id was not registered; useful for idempotent cleanup in a "disable mod" flow.
-- if false then -- ModManager:unregisterMod
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "fan.skins"}))
--   local removed = mgr:unregisterMod("fan.skins")
--   lurek.log.info("removed=" .. tostring(removed), "mods")
-- end

--@api-stub: LModManager:hasMod
-- Returns whether a mod with the given ID is registered.
-- Use to gate dependency-aware features ("if combat mod present, show advanced HUD").
-- if false then -- ModManager:hasMod
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "core.combat"}))
--   if mgr:hasMod("core.combat") then
--     lurek.log.debug("combat available", "ui")
--   end
-- end

--@api-stub: LModManager:getModCount
-- Returns the number of registered mods.
-- Useful as a quick "mods detected: N" line in the title screen or a load-time summary log.
-- if false then -- ModManager:getModCount
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "a"}))
--   mgr:registerMod(lurek.mods.newMod({id = "b"}))
--   lurek.log.info("loaded " .. mgr:getModCount() .. " mods", "boot")
-- end

--@api-stub: LModManager:getAllMods
-- Returns an array of info tables for all registered mods.
-- Returns plain Lua tables (snapshots), not live Mod userdata; safe to filter, sort, and serialise for UI rows.
-- if false then -- ModManager:getAllMods
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "core.hud", name = "HUD"}))
--   for _, info in ipairs(mgr:getAllMods()) do
--     lurek.log.debug(info.id .. " priority=" .. info.priority, "mods")
--   end
-- end

--@api-stub: LModManager:getLoadOrder
-- Returns an array of info tables in effective load order.
-- Iterate this (not getAllMods) when running per-mod init code, so dependency order is respected.
-- if false then -- ModManager:getLoadOrder
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "core.base", priority = 100}))
--   mgr:registerMod(lurek.mods.newMod({id = "fan.ui",   priority = 10, dependencies = {"core.base"}}))
--   for i, info in ipairs(mgr:getLoadOrder()) do
--     lurek.log.info(i .. ": " .. info.id, "mods")
--   end
-- end

--@api-stub: LModManager:validateDependencies
-- Returns an array of mod IDs with missing dependencies.
-- An empty result means the graph is satisfied; a non-empty list should be surfaced to the user before launching the game.
-- if false then -- ModManager:validateDependencies
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "fan.weapons", dependencies = {"core.combat"}}))
--   for _, broken_id in ipairs(mgr:validateDependencies()) do
--     lurek.log.error("missing deps for " .. broken_id, "mods")
--   end
-- end

--@api-stub: LModManager:hasCircularDependencies
-- Returns whether any circular dependency cycles exist.
-- Refuse to call getLoadOrder when this is true; the resulting order would be undefined.
-- if false then -- ModManager:hasCircularDependencies
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "a", dependencies = {"b"}}))
--   mgr:registerMod(lurek.mods.newMod({id = "b", dependencies = {"a"}}))
--   if mgr:hasCircularDependencies() then
--     lurek.log.error("dependency cycle detected", "mods")
--   end
-- end

--@api-stub: LModManager:setLoadOrder
-- Sets an explicit load order from an array of mod ID strings.
-- Use to honour a user-saved order from a previous session; IDs not in the array fall back to priority sorting.
-- if false then -- ModManager:setLoadOrder
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "core.base"}))
--   mgr:registerMod(lurek.mods.newMod({id = "fan.ui"}))
--   mgr:setLoadOrder({"core.base", "fan.ui"})
-- end

--@api-stub: LModManager:clearLoadOrder
-- Clears the custom load order, reverting to priority-based sorting.
-- Call when the user clicks "reset order" in the mod-manager UI to undo a manual reorder.
-- if false then -- ModManager:clearLoadOrder
--   local mgr = lurek.mods.newModManager()
--   mgr:setLoadOrder({"a", "b", "c"})
--   mgr:clearLoadOrder()
--   lurek.log.info("load order reset to priority", "mods")
-- end

--@api-stub: LModManager:scanFolder
-- Scans a directory for mods with mod.toml and registers them.
-- Returns info tables for everything it found and registered; pass an absolute or game-relative folder path.
-- if false then -- ModManager:scanFolder
--   local mgr = lurek.mods.newModManager()
--   local discovered = mgr:scanFolder("content/plugins")
--   lurek.log.info("auto-registered " .. #discovered .. " mods", "mods")
-- end

--@api-stub: LModManager:getModPath
-- Returns the filesystem path of a registered mod, or nil.
-- Returns nil for in-memory mods that were not loaded from disk; use to locate a mod's assets folder.
-- if false then -- ModManager:getModPath
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "fan.skins"}))
--   local path = mgr:getModPath("fan.skins")
--   if path then lurek.log.debug("on-disk at " .. path, "mods") end
-- end

--@api-stub: LModManager:markForReload
-- Marks a registered mod for hot-reload.
-- Returns true when the mod was queued; false when the id is unknown. Watch for file changes and call this from a dev tool.
-- if false then -- ModManager:markForReload
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "core.hud"}))
--   local queued = mgr:markForReload("core.hud")
--   lurek.log.debug("queued for reload=" .. tostring(queued), "mods")
-- end

--@api-stub: LModManager:getReloadQueue
-- Returns the array of mod IDs pending hot-reload.
-- Drain this in your dev-tool reload step, then call clearReloadQueue once the actual reloads are applied.
-- if false then -- ModManager:getReloadQueue
--   local mgr = lurek.mods.newModManager()
--   mgr:registerMod(lurek.mods.newMod({id = "ui.theme"}))
--   mgr:markForReload("ui.theme")
--   for _, id in ipairs(mgr:getReloadQueue()) do
--     lurek.log.info("reload pending: " .. id, "mods")
--   end
-- end

--@api-stub: LModManager:clearReloadQueue
-- Clears the reload queue without reloading.
-- Call after you've actually performed the reloads, or to abandon a queued batch when the user cancels.
-- if false then -- ModManager:clearReloadQueue
--   local mgr = lurek.mods.newModManager()
--   mgr:markForReload("core.hud")
--   mgr:clearReloadQueue()
--   lurek.log.debug("queue size=" .. #mgr:getReloadQueue(), "mods")
-- end

-- â”€â”€ Content Registry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

--@api-stub: lurek.mods.newRegistry
-- Create a new typed content registry for mod-contributed assets and objects.
-- Registries are standalone â€” attach them to a mod or keep them global.
-- if false then -- lurek.mods.newRegistry
--   local reg = lurek.mods.newRegistry()
--   lurek.log.debug("registry created", "mods")
-- end

--@api-stub: LContentRegistry:registerType
-- Register a new content type before inserting entries.
-- All entries must be registered under a declared type.
-- if false then -- ContentRegistry:registerType
--   local reg = lurek.mods.newRegistry()
--   reg:registerType("weapon")
--   lurek.log.debug("registered type 'weapon'", "mods")
-- end

--@api-stub: LContentRegistry:register
-- Insert a content entry under a previously registered type.
-- @param type_name string, @param id string, @param obj any
-- if false then -- ContentRegistry:register
--   local reg = lurek.mods.newRegistry()
--   reg:registerType("weapon")
--   reg:register("weapon", "iron_sword", { name = "Iron Sword", damage = 12 })
--   lurek.log.debug("registered iron_sword", "mods")
-- end

--@api-stub: LContentRegistry:get
-- Retrieve a content entry by type and id.
-- Returns nil if not found.
-- if false then -- ContentRegistry:get
--   local reg = lurek.mods.newRegistry()
--   reg:registerType("spell")
--   reg:register("spell", "fireball", { cost = 10 })
--   local s = reg:get("spell", "fireball")
--   lurek.log.debug("spell cost=" .. (s and s.cost or "nil"), "mods") ---@diagnostic disable-line:undefined-field
-- end

--@api-stub: LContentRegistry:getAll
-- Return a table of all entries for a type as {id: obj} map.
-- Keys are the entry ids; values are the registered objects.
-- if false then -- ContentRegistry:getAll
--   local reg = lurek.mods.newRegistry()
--   reg:registerType("item")
--   reg:register("item", "potion", { name = "Potion" })
--   local all = reg:getAll("item")
--   lurek.log.debug("item count=" .. (all.potion and 1 or 0), "mods") ---@diagnostic disable-line:undefined-field
-- end

--@api-stub: LContentRegistry:getTypes
-- Return an array of all registered type names in this registry.
-- Useful for mod inspection UIs and validation passes.
-- if false then -- ContentRegistry:getTypes
--   local reg = lurek.mods.newRegistry()
--   reg:registerType("creature")
--   reg:registerType("item")
--   local types = reg:getTypes()
--   lurek.log.debug("type count=" .. #types, "mods")
-- end

--@api-stub: LMod:setHook
-- Registers a callback for a named engine hook point on this mod.
-- Hooks let mods intercept engine events (on_save, on_load, on_entity_spawn, etc.).
-- if false then -- Mod:setHook
--   local mod = lurek.mods.newMod({id="example_mod", name="Example", version="1.0"})
--   mod:setHook("on_save", function(ctx)
--     lurek.log.info("mod saving extra data", "mods")
--   end)
--   lurek.log.info("hook registered: " .. tostring(mod:hasHook("on_save")), "mods")
-- end

-- =============================================================================
-- STUBS: 4 uncovered lurek.mods API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- ModManager methods
-- -----------------------------------------------------------------------------

-- =============================================================================
-- STUBS: 6 uncovered lurek.mods API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LContentRegistry methods
-- -----------------------------------------------------------------------------

-- ---- Stub: LContentRegistry:type -----------------------------------------
--@api-stub: LContentRegistry:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LContentRegistry:type
--   local content_registry_obj = lurek.mods.newRegistry()
--   local t = content_registry_obj:type()
--   lurek.log.info("LContentRegistry:type = " .. t, "mods")
-- end
--@api-stub: LContentRegistry:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LContentRegistry:typeOf
--   local content_registry_obj = lurek.mods.newRegistry()
--   lurek.log.info("is LContentRegistry: " .. tostring(content_registry_obj:typeOf("LContentRegistry")), "mods")
--   lurek.log.info("is wrong: " .. tostring(content_registry_obj:typeOf("Unknown")), "mods")
-- end
--@api-stub: LMod:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LMod:type
--   local ok, mod_obj = pcall(lurek.mods.newMod, "testmod")
--   if not ok then mod_obj = nil end ---@diagnostic disable-line: cast-local-type
--   local t = mod_obj and mod_obj:type() or "LMod"
--   lurek.log.info("LMod:type = " .. t, "mods")
-- end
--@api-stub: LMod:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LMod:typeOf
--   local ok2, mod_obj2 = pcall(lurek.mods.newMod, "testmod")
--   if not ok2 then mod_obj2 = nil end ---@diagnostic disable-line: cast-local-type
--   lurek.log.info("is LMod: " .. tostring(mod_obj2 and mod_obj2:typeOf("LMod") or false), "mods")
--   lurek.log.info("is wrong: " .. tostring(mod_obj2 and mod_obj2:typeOf("Unknown") or false), "mods")
-- end
--@api-stub: LModManager:type
-- Returns the type name of this object.
-- Useful for runtime type inspection.
-- if false then -- LModManager:type
--   local mod_manager_obj = lurek.mods.newModManager()
--   local t = mod_manager_obj:type()
--   lurek.log.info("LModManager:type = " .. t, "mods")
-- end
--@api-stub: LModManager:typeOf
-- Returns true if this object is of the given type.
-- Use for runtime type checks.
-- if false then -- LModManager:typeOf
--   local mod_manager_obj = lurek.mods.newModManager()
--   lurek.log.info("is LModManager: " .. tostring(mod_manager_obj:typeOf("LModManager")), "mods")
--   lurek.log.info("is wrong: " .. tostring(mod_manager_obj:typeOf("Unknown")), "mods")
-- end
--@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================


