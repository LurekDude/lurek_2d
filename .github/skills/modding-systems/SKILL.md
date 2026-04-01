---
name: modding-systems
description: "Load this skill when implementing mod support in Luna2D: ModManager registration, dependency resolution, load ordering, hot-reload, or folder scanning. Skip it for core engine modules, asset loading, or Lua sandboxing."
---

# Modding Systems — Luna2D Engine

## Load When

- Registering mods via `luna.modding.*` API
- Resolving mod dependencies and load order
- Implementing hot-reload for mod development
- Scanning folders for available mods
- Designing mod metadata (ModInfo) schemas

## Owns

- `src/modding/` module — ModManager and ModInfo
- `src/lua_api/modding_api.rs` — `luna.modding.*` Lua bindings
- Mod registration and lifecycle patterns
- Dependency resolution and circular dependency detection
- Load ordering rules

## Does Not Cover

- Lua sandbox security → use `lua-sandbox-design` skill
- Filesystem access → use `asset-pipeline` skill
- Scene management → use `scene-management` skill

## Live Repository Contracts

- `src/modding/mod_manager.rs` — `ModManager`, `ModInfo`
- `src/lua_api/modding_api.rs` — Lua bindings
- `tests/modding_tests.rs` — registration, ordering, circular dependency detection

## Decision Rules

- **ModManager replaces on re-register** — registering a mod with an existing name overwrites it
- **Load order is deterministic** — same-priority mods sort alphabetically by name
- **Circular dependencies are detected** — the resolver rejects dependency cycles
- **Hot-reload is queued** — reload requests are batched, not applied immediately
- **Folder scanning is file-system based** — mods are folders with metadata and Lua scripts
- **Dependencies are by name** — mods declare dependencies as string arrays of mod names

## Best Practices

- Validate mod metadata at registration — catch issues early (missing name, version)
- Use dependency arrays for explicit ordering — don't rely on alphabetical order for correctness
- Queue hot-reloads — batch multiple file changes into one reload cycle
- Test circular dependency detection — ensure mod graphs don't deadlock

## Anti-Patterns

- **Implicit ordering**: Relying on registration order instead of explicit dependencies
- **Unchecked re-register**: Overwriting mods without logging — can hide configuration errors
- **Immediate hot-reload**: Reloading on every file change — causes flickering during multi-file edits
