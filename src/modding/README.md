# `src/modding/` — Mod Management System

## Purpose

The modding module provides the infrastructure for player-created mods — the
ability for end users to add, replace, or extend game content without modifying
the original game files.  It scans a designated `mods/` directory for
subdirectories, reads each subdirectory's `mod.toml` manifest (name, version,
description, author, load-order priority, dependency declarations), resolves
the dependency graph to produce a deterministic load order, and executes each
mod's Lua entry script and asset-override declarations within the existing
sandbox rules.

Mods declare asset overrides in their manifest — for example replacing
`sprites/hero.png` with the mod's own version.  These virtual-path overrides
are registered in `GameFS` before any game script runs, so the mod asset is
found first without special-casing in the reader code.  Two mods overriding
the same asset are resolved by load-order priority declared in their
manifests.  A mod can also extend the `luna.*` Lua surface by defining new
functions in its entry Lua file, provided they do not shadow core Luna2D
names.

## Architecture

```
ModManager (mod registry)
  │
  ├── ModInfo ── per-mod metadata
  │     ├── id, name, version, author, description
  │     ├── priority (for load order)
  │     ├── dependencies (list of required mod IDs)
  │     ├── enabled / loaded flags
  │     └── path (filesystem location)
  │
  ├── Load order resolution
  │     ├── Priority-based default ordering
  │     └── Custom load order override
  │
  ├── Folder scanning
  │     └── scan_folder(path) → discovers mods via TOML metadata
  │
  ├── Dependency validation
  │     ├── validate_dependencies() → checks all deps satisfied
  │     └── has_circular_dependencies() → DFS cycle detection
  │
  └── Hot-reload queue
        ├── mark_for_reload(mod_id)
        └── get/clear_reload_queue()
```

### How It Works

Mod discovery uses `std::fs::read_dir()` over the `mods/` directory.  Invalid
or missing `mod.toml` files are logged and the subdirectory is skipped — a
broken mod does not prevent other mods or the base game from loading.
Dependency cycles are detected via a topological sort (Kahn's algorithm) of
the load-order graph before any Lua is executed; a cycle produces an error
listing all participating mod names.

Asset override resolution is a thin virtual-path table checked by
`GameFS::resolve_read_path()` before normal path resolution.  Overrides still
route through the same canonicalisation and prefix-check sandbox rules — a mod
cannot use override paths to escape the game directory.  Removing a mod at
runtime without restarting the game is not supported; mods are loaded once
at game start.

### Dependency Direction

```
modding/ ──────► (none — uses toml crate for parsing)
```

**Leaf module** — no Luna2D dependencies. Pure mod management logic.

---

## File-by-File Analysis

### `mod.rs` — Complete Mod Manager (Single File Module)

**~458 lines** | Full mod management implementation with 16 inline tests.

#### Struct: `ModInfo`

```rust
pub struct ModInfo {
    pub id: String,
    pub name: String,
    pub version: String,
    pub author: String,
    pub description: String,
    pub priority: i32,
    pub dependencies: Vec<String>,
    pub enabled: bool,
    pub loaded: bool,
    pub path: PathBuf,
}
```

#### Struct: `ModManager`

```rust
pub struct ModManager {
    mods: Vec<ModInfo>,
    custom_load_order: Option<Vec<String>>,
    reload_queue: Vec<String>,
}
```

#### Methods

| Method | Purpose |
|--------|---------|
| `register_mod(info)` | Add mod to registry |
| `unregister_mod(id)` | Remove mod |
| `get_mod(id)` / `get_mod_mut(id)` | Lookup by ID |
| `has_mod(id)` | Existence check |
| `mod_count()` | Total registered mods |
| `all_mods()` | All mod references |
| `load_order()` | Priority-sorted or custom order |
| `set_load_order(ids)` | Override default ordering |
| `clear_load_order()` | Revert to priority-based |
| `scan_folder(path)` | Discover mods from filesystem |
| `mark_for_reload(id)` | Queue for hot-reload |
| `get_reload_queue()` / `clear_reload_queue()` | Manage reload queue |
| `validate_dependencies()` | Check all deps satisfied |
| `has_circular_dependencies()` | DFS cycle detection |

**Design**: TOML parsing for mod metadata is lenient — missing optional fields
default to empty strings. `scan_folder` discovers mods by looking for `mod.toml`
files in subdirectories. DFS cycle detection walks the dependency graph.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/modding_api.rs` (~150 lines), exposing
mod management under `luna.modding.*`.

### Usage from Lua

```lua
-- Scan for mods
luna.modding.scanFolder("mods/")

-- Check mod availability
if luna.modding.hasMod("extended-weapons") then
    -- load mod content
end

-- Get load order
local order = luna.modding.getLoadOrder()
for _, mod_id in ipairs(order) do
    print("Loading: " .. mod_id)
end
```
