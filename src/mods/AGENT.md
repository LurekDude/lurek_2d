# mods

## Module Info
- Module name: `mods`
- Module group: `Feature Systems`
- Spec path: `docs/specs/mods.md`
- Lua API path(s): `src/lua_api/mods_api.rs`
- Rust test path(s): none found in the workspace
- Lua test path(s): none found in the workspace

## Module Purpose
The `mods` module provides the metadata and load-order layer for user-created modifications. It discovers mod manifests, parses their metadata, validates dependency relationships, and computes deterministic ordering so the rest of the engine can decide what to mount or reload.

It exists to keep mod discovery and dependency reasoning out of filesystem code, asset loading, and script execution. By centralizing manifest parsing and ordering here, the engine has one consistent place to answer which mods exist, which are enabled, and which should load first.

It intentionally does not execute mod scripts, mount assets into the virtual filesystem, or enforce sandboxing. Those responsibilities belong in higher integration layers; this module is the registry and ordering layer.

## Files
- `mod.rs` - Declares the mod-management surface and re-exports the manager implementation.
- `mod_manager.rs` - Implements mod discovery, manifest parsing, dependency validation, custom load ordering, and queued reload tracking.

## Key Types
- `ModManager` - The central registry for discovered mods. It owns the mod list, optional custom load order, dependency checks, and pending reload bookkeeping.
- `ModInfo` - One parsed mod manifest plus runtime status fields such as enabled, loaded, priority, dependencies, and filesystem path.
