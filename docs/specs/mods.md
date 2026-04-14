# mods

## General Info

- Module group: `Feature Systems`
- Source path: `src/mods/`
- Lua API path(s): `src/lua_api/mods_api.rs`
- Primary Lua namespace: `lurek.mods`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Summary

The `mods` module provides Lurek2D's mod-loading framework — the system by which user-created content packages can extend or replace a base game without modifying its source. It is a Feature Systems tier module that integrates with `filesystem` for virtual filesystem mounting and with `runtime` for configuration.

The core type is `ModManager`, which handles the full mod lifecycle: scanning configured mod search paths for `mod.toml` manifest files; parsing manifests into `ModInfo` records (unique string ID, display name, version semver, author, description, dependency list); resolving load order via topological sort over the dependency graph; detecting circular dependencies and missing dependencies; enabling/disabling individual mods; mounting enabled mod folders into `GameFS` as overlay `MountLayer` entries; and polling mtime for hot-reload detection.

Each mod folder must contain a `mod.toml` with at minimum an `id`, `name`, and `version` field. Assets in a mod folder override base game assets at the same virtual path; new assets are simply added to the virtual filesystem. Dependency ordering ensures that if mod B depends on mod A, mod A's assets are mounted first so mod B's overrides take precedence.

Hot-reload queuing works by recording the mtime of each mounted mod folder at load time and comparing on each `tick()` call. When a change is detected, the mod is queued for reload notification to the Lua callback registered via `lurek.mods.onReload(fn)`.

**Scope boundary**: Feature Systems tier. Depends on `filesystem`, `runtime`. Lua bridge in `src/lua_api/mods_api.rs`.

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

### `Mod` Methods
- `Mod:getId`: Returns the unique mod identifier.
- `Mod:getName`: Returns the display name.
- `Mod:getVersion`: Returns the version string.
- `Mod:getAuthor`: Returns the author name.
- `Mod:getDescription`: Returns the mod description.
- `Mod:getDependencies`: Returns the list of required mod IDs.
- `Mod:getPriority`: Returns the load-order priority.
- `Mod:isEnabled`: Returns whether the mod is enabled.
- `Mod:setEnabled`: Sets the enabled state.
- `Mod:isLoaded`: Returns whether the mod has been loaded.
- `Mod:getHook`: Returns the hook function for the given name, or nil.
- `Mod:hasHook`: Returns whether a hook with the given name exists.
- `Mod:getHookNames`: Returns an array of registered hook names.
- `Mod:setConfig`: Stores an arbitrary config value for this mod.
- `Mod:getConfig`: Returns the stored config value, or nil.
- `Mod:releaseRefs`: Releases all hook and config registry references.

### `ModManager` Methods
- `ModManager:registerMod`: Registers a mod from its Mod userdata.
- `ModManager:unregisterMod`: Removes a mod by ID and returns whether it was found.
- `ModManager:hasMod`: Returns whether a mod with the given ID is registered.
- `ModManager:getModCount`: Returns the number of registered mods.
- `ModManager:getAllMods`: Returns an array of info tables for all registered mods.
- `ModManager:getLoadOrder`: Returns an array of info tables in effective load order.
- `ModManager:validateDependencies`: Returns an array of mod IDs with missing dependencies.
- `ModManager:hasCircularDependencies`: Returns whether any circular dependency cycles exist.
- `ModManager:setLoadOrder`: Sets an explicit load order from an array of mod ID strings.
- `ModManager:clearLoadOrder`: Clears the custom load order, reverting to priority-based sorting.
- `ModManager:scanFolder`: Scans a directory for mods with mod.toml and registers them.
- `ModManager:getModPath`: Returns the filesystem path of a registered mod, or nil.
- `ModManager:markForReload`: Marks a registered mod for hot-reload.
- `ModManager:getReloadQueue`: Returns the array of mod IDs pending hot-reload.
- `ModManager:clearReloadQueue`: Clears the reload queue without reloading.

## References

- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/mods/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
