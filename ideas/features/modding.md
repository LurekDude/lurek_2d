# modding — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/modding.md`
**Files**: Mod loading, sandboxing, registry

## Purpose

Modding framework: load, validate, and apply content mods. Mod manifest validation, load order, sandboxed execution, mod registry.

## Current Feature Summary

- Mod manifest files (`mod.toml` or `mod.lua`) with metadata
- Mod load order with dependency resolution
- Mod registry: list, enable, disable, query mods
- Sandboxed mod execution (separate Lua environment)
- Content overrides: mods can replace assets and scripts
- Event hooks: mods register callbacks into game events
- Mod versioning and compatibility checking
- File path remapping for mod content
- Mod conflict detection

## Feature Gaps

1. **No mod workshop/distribution**: No built-in mechanism for discovering or downloading mods. Must manually copy mod folders.
2. **No mod API versioning**: Mods break when engine API changes. No `mod_api_version` concept to gate compatibility.
3. **No mod capabilities/permissions**: No fine-grained control over what a mod can access (e.g., "this mod can read files but not write" or "this mod can't access network").
4. **No lua-level API for modders**: No `luna.mod.registerHook("onEntitySpawn", fn)` — modders must know internal event names.
5. **No mod configuration UI**: No way for mods to declare configurable options that get auto-generated UI.
6. **No mod hot reload**: Can't reload a mod without restarting the game.
7. **No mod templates/scaffolding**: No `luna mod init` CLI command to create a mod skeleton.

## Structural Issues

- **Correct scope**: Modding is clearly a Tier 2 extension that layers on filesystem and event.
- **Sandboxing quality**: How robust is the mod sandbox? If mods run in isolated Lua environments, can they access `luna.filesystem` to write arbitrary paths? Security concern.
- **Integration with savegame**: Do save files track which mods were active? Loading a save with missing mods could corrupt state.

## Suggestions

1. **Add mod API version**: `mod.toml` declares `api_version = "0.4"`. Engine warns or rejects mods targeting different API versions.
2. **Add mod capabilities**: `mod.toml` declares `capabilities = ["read_files", "add_entities"]`. Engine enforces at sandbox level.
3. **Add mod config schema**: `mod.toml` declares `[config]` section with typed fields. Engine auto-generates settings UI.
4. **Track mods in save files**: Save files record active mod list + versions. Warn on load if mods are missing or version-mismatched.
5. **Add mod hot reload**: `luna.modding.reloadMod(name)` — re-execute mod scripts without restart. Pairs with file watcher.
6. **Add mod scaffolding**: CLI tool `luna mod init <name>` creates `mod.toml` template + folder structure.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| Mod system | ✅ (built-in) | ❌ | ❌ | ❌ (plugins) |
| Mod manifests | ✅ | N/A | N/A | N/A |
| Sandbox | ✅ | N/A | N/A | N/A |
| Load order | ✅ | N/A | N/A | N/A |
| Mod workshop | ❌ | N/A | N/A | N/A |
| Capabilities | ❌ | N/A | N/A | N/A |

Built-in modding support is a genuine differentiator. No other 2D Lua engine has it.

## Priority

**MEDIUM** — Mod API versioning and capabilities are important for stability and security. Mod config schema would reduce mod developer boilerplate.
