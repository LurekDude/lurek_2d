# `mods` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Feature Systems |
| **Status** | Implemented |
| **Lua API** | `lurek.mods` |
| **Source** | `src/mods/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Feature Systems` |

---

## Summary

The `mods` module provides the metadata and load-order layer for user-created modifications. It discovers mod manifests, parses their metadata, validates dependency relationships, and computes deterministic ordering so the rest of the engine can decide what to mount or reload.

It exists to keep mod discovery and dependency reasoning out of filesystem code, asset loading, and script execution. By centralizing manifest parsing and ordering here, the engine has one consistent place to answer which mods exist, which are enabled, and which should load first.

It intentionally does not execute mod scripts, mount assets into the virtual filesystem, or enforce sandboxing. Those responsibilities belong in higher integration layers; this module is the registry and ordering layer.

**Scope boundary**: This module currently depends on `runtime`. It stays within the Feature Systems responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.mods.* (Lua API — src/lua_api/mods_api.rs)
    |
    v
src/mods/mod.rs
    |- mod_manager.rs - mod_manager
```

---

## Source Files

| File | Purpose |
|------|---------|
| `mod.rs` | Declares the mod-management surface and re-exports the manager implementation. |
| `mod_manager.rs` | Implements mod discovery, manifest parsing, dependency validation, custom load ordering, and queued reload tracking. |

---

## Submodules

### `mods::mod_manager`

Implements mod discovery, manifest parsing, dependency validation, custom load ordering, and queued reload tracking.

- **`ModInfo`** (struct): Metadata record describing one registered game mod.
- **`ModManager`** (struct): Centralized registry for managing mods, resolving load order, validating dependencies, scanning mod folders, and queuing hot-reloads.

---

## Key Types

### Public Types

#### `ModManager`

The central registry for discovered mods.

#### `ModInfo`

One parsed mod manifest plus runtime status fields such as enabled, loaded, priority, dependencies, and filesystem path.

---

## Lua API

Exposed under `lurek.mods.*` by `src/lua_api/mods_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.mods.newMod` | Creates a new Mod from an info table with at least an `id` field. |
| `lurek.mods.newModManager` | Creates a new empty ModManager. |

### `Mod` Methods

| Method | Description |
|--------|-------------|
| `mod:getId(...)` | Returns the unique mod identifier. |
| `mod:getName(...)` | Returns the display name. |
| `mod:getVersion(...)` | Returns the version string. |
| `mod:getAuthor(...)` | Returns the author name. |
| `mod:getDescription(...)` | Returns the mod description. |
| `mod:getDependencies(...)` | Returns the list of required mod IDs. |
| `mod:getPriority(...)` | Returns the load-order priority. |
| `mod:isEnabled(...)` | Returns whether the mod is enabled. |
| `mod:setEnabled(...)` | Sets the enabled state. |
| `mod:isLoaded(...)` | Returns whether the mod has been loaded. |
| `mod:getHook(...)` | Returns the hook function for the given name, or nil. |
| `mod:hasHook(...)` | Returns whether a hook with the given name exists. |
| `mod:getHookNames(...)` | Returns an array of registered hook names. |
| `mod:setConfig(...)` | Stores an arbitrary config value for this mod. |
| `mod:getConfig(...)` | Returns the stored config value, or nil. |
| `mod:releaseRefs(...)` | Releases all hook and config registry references. |

### `ModManager` Methods

| Method | Description |
|--------|-------------|
| `modmanager:registerMod(...)` | Registers a mod from its Mod userdata. |
| `modmanager:unregisterMod(...)` | Removes a mod by ID and returns whether it was found. |
| `modmanager:hasMod(...)` | Returns whether a mod with the given ID is registered. |
| `modmanager:getModCount(...)` | Returns the number of registered mods. |
| `modmanager:getAllMods(...)` | Returns an array of info tables for all registered mods. |
| `modmanager:getLoadOrder(...)` | Returns an array of info tables in effective load order. |
| `modmanager:validateDependencies(...)` | Returns an array of mod IDs with missing dependencies. |
| `modmanager:hasCircularDependencies(...)` | Returns whether any circular dependency cycles exist. |
| `modmanager:setLoadOrder(...)` | Sets an explicit load order from an array of mod ID strings. |
| `modmanager:clearLoadOrder(...)` | Clears the custom load order, reverting to priority-based sorting. |
| `modmanager:scanFolder(...)` | Scans a directory for mods with mod.toml and registers them. |
| `modmanager:getModPath(...)` | Returns the filesystem path of a registered mod, or nil. |
| `modmanager:markForReload(...)` | Marks a registered mod for hot-reload. |
| `modmanager:getReloadQueue(...)` | Returns the array of mod IDs pending hot-reload. |
| `modmanager:clearReloadQueue(...)` | Clears the reload queue without reloading. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.mods.
if lurek.mods then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 2 |
| `enum` | 0 |
| `fn` (Lua API) | 33 |
| **Total** | **35** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Feature Systems to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/mods/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
