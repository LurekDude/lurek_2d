# mods

## General Info

- Module group: `Feature Systems`
- Source path: `src/mods/`
- Lua API path(s): `src/lua_api/mods_api.rs`
- Primary Lua namespace: `lurek.mods`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Summary

The `mods` module is documented from the current source tree and existing module reference data.

This module primarily collaborates with `runtime`. Its responsibility should stay inside the Feature Systems group rather than absorb behavior owned by those neighbors.

## Files

- `mod.rs`: Declares the mod-management surface and re-exports the manager implementation.
- `mod_manager.rs`: Implements mod discovery, manifest parsing, dependency validation, custom load ordering, and queued reload tracking.

## Types

- `ModInfo` (`struct`, `mod_manager.rs`): One parsed mod manifest plus runtime status fields such as enabled, loaded, priority, dependencies, and filesystem path.
- `ModManager` (`struct`, `mod_manager.rs`): The central registry for discovered mods. It owns the mod list, optional custom load order, dependency checks, and pending reload bookkeeping.

## Functions

- `ModInfo::new` (`mod_manager.rs`): Create a new ModInfo with the given ID and sensible defaults.
- `ModInfo::from_parts` (`mod_manager.rs`): Creates a `ModInfo` from its constituent parts, applying optional overrides over the defaults from [`ModInfo::new`].
- `ModManager::new` (`mod_manager.rs`): Create a new empty ModManager.
- `ModManager::register_mod` (`mod_manager.rs`): Register a mod with the manager.
- `ModManager::unregister_mod` (`mod_manager.rs`): Removes a mod from the registry by its assigned ID.
- `ModManager::get_mod` (`mod_manager.rs`): Get a reference to a mod by ID.
- `ModManager::get_mod_mut` (`mod_manager.rs`): Get a mutable reference to a mod by ID.
- `ModManager::has_mod` (`mod_manager.rs`): Check if a mod is registered.
- `ModManager::mod_count` (`mod_manager.rs`): Returns the count of all currently registered mods.
- `ModManager::all_mods` (`mod_manager.rs`): Returns a slice of all registered mod metadata records.
- `ModManager::load_order` (`mod_manager.rs`): Get mods in their effective load order.
- `ModManager::set_load_order` (`mod_manager.rs`): Set an explicit load order by providing a list of mod IDs.
- `ModManager::clear_load_order` (`mod_manager.rs`): Clear any custom load order, reverting to priority-based sorting.
- `ModManager::get_custom_load_order` (`mod_manager.rs`): Returns a reference to the current custom load order, if any.
- `ModManager::scan_folder` (`mod_manager.rs`): Scan a directory for mods and register them.
- `ModManager::mark_for_reload` (`mod_manager.rs`): Marks a registered mod as requiring hot-reload on the next update tick.
- `ModManager::get_reload_queue` (`mod_manager.rs`): Returns the current reload queue (mod IDs pending hot-reload).
- `ModManager::clear_reload_queue` (`mod_manager.rs`): Clear the reload queue without reloading anything.
- `ModManager::validate_dependencies` (`mod_manager.rs`): List mod IDs whose dependencies are missing.
- `ModManager::has_circular_dependencies` (`mod_manager.rs`): Check for circular dependency cycles.

## Lua API Reference

- Binding path(s): `src/lua_api/mods_api.rs`
- Namespace: `lurek.mods`

### Module Functions
- `lurek.mods.newMod`: Creates a new Mod from an info table with at least an `id` field.
- `lurek.mods.newModManager`: Creates a new empty ModManager.
- `lurek.mods.newRegistry`: Creates a new empty ContentRegistry for mod-contributed assets.
- `lurek.mods.checkApiVersion`: Checks whether a mod's required `api_version` is compatible with the given `host_version`.

### `LContentRegistry` Methods
- `LContentRegistry:registerType`: Registers a new content type.
- `LContentRegistry:register`: Registers a content entry.
- `LContentRegistry:get`: Retrieves a content entry.
- `LContentRegistry:getAll`: Returns all entries for a type.
- `LContentRegistry:getTypes`: Returns all registered type names.
- `LContentRegistry:type`: Returns the type name of this object.
- `LContentRegistry:typeOf`: Returns true if this object is of the given type.

### `LMod` Methods
- `LMod:getId`: Returns the unique mod identifier.
- `LMod:getName`: Returns the localized or human-readable display name of the mod.
- `LMod:getVersion`: Returns the version string.
- `LMod:getAuthor`: Returns the author name string from this mod's metadata manifest.
- `LMod:getDescription`: Returns the mod description.
- `LMod:getDependencies`: Returns the list of required mod IDs.
- `LMod:getPriority`: Returns the load-order priority.
- `LMod:isEnabled`: Returns whether the mod is enabled.
- `LMod:setEnabled`: Enables or disables this mod.
- `LMod:isLoaded`: Returns whether the mod has been loaded.
- `LMod:getApiVersion`: Returns the required engine API version string when one is set.
- `LMod:setApiVersion`: Sets the required engine API version string.
- `LMod:getCapabilities`: Returns an array of declared capability flags.
- `LMod:setCapabilities`: Replaces the capability list with the given array of strings.
- `LMod:getConfigSchema`: Returns the config schema as an array of `{key, type, default}` tables.
- `LMod:setConfigSchema`: Replaces the config schema with the given array of `{key, type, default}` tables.
- `LMod:setHook`: Registers a named hook callback, replacing any existing one.
- `LMod:getHook`: Returns the hook function for the given name.
- `LMod:hasHook`: Returns whether a hook with the given name exists.
- `LMod:getHookNames`: Returns an array of registered hook names.
- `LMod:setConfig`: Stores an arbitrary config value for this mod.
- `LMod:getConfig`: Returns the stored config value.
- `LMod:releaseRefs`: Releases all hook and config registry references.
- `LMod:type`: Returns the type name of this object.
- `LMod:typeOf`: Returns true if this object is of the given type.

### `LModManager` Methods
- `LModManager:registerMod`: Registers a mod from its mod userdata.
- `LModManager:unregisterMod`: Removes a mod by ID and returns whether it was found.
- `LModManager:hasMod`: Returns whether a mod with the given ID is registered.
- `LModManager:getModCount`: Returns the number of registered mods.
- `LModManager:getAllMods`: Returns an array of info tables for all registered mods.
- `LModManager:getLoadOrder`: Returns an array of info tables in effective load order.
- `LModManager:validateDependencies`: Returns an array of mod IDs with missing dependencies.
- `LModManager:hasCircularDependencies`: Returns whether any circular dependency cycles exist.
- `LModManager:setLoadOrder`: Sets an explicit load order from an array of mod ID strings.
- `LModManager:clearLoadOrder`: Clears the custom load order.
- `LModManager:scanFolder`: Scans a directory for mods with `mod.toml` and registers them.
- `LModManager:getModPath`: Returns the filesystem path of a registered mod.
- `LModManager:markForReload`: Marks a registered mod for hot-reload.
- `LModManager:getReloadQueue`: Returns the array of mod IDs pending hot-reload.
- `LModManager:clearReloadQueue`: Clears the reload queue without reloading.
- `LModManager:type`: Returns the type name of this object.
- `LModManager:typeOf`: Returns true if this object is of the given type.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/mods/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
