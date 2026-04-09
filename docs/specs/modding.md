# `modding` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.modding`                                       |
| **Source**     | `src/modding/`                                       |
| **Rust Tests** | `tests/rust/unit/modding_tests.rs`                   |
| **Lua Tests**  | `tests/lua/unit/test_modding.lua`                    |
| **Architecture** | —                                                  |

## Summary

The modding module provides infrastructure for player-created mods — the
ability for end users to add, replace, or extend game content without modifying
the original game files. It is a Tier 2 engine extension that depends only on
Baseline (`engine`, `math`) and uses the `toml` crate for manifest parsing and
`std::fs` for directory scanning. No Tier 1 runtime modules are imported.

The module centres on two types: `ModInfo` (per-mod metadata record) and
`ModManager` (centralised registry). `ModManager` handles mod registration,
lookup, priority-based load ordering with optional custom overrides, dependency
validation (missing and circular), filesystem folder scanning with `mod.toml`
parsing, and a hot-reload queue for marking mods that need re-execution at
runtime.

Mods are discovered by scanning a designated directory (typically `mods/`).
Each immediate subdirectory that contains a `mod.toml` file is parsed into a
`ModInfo` and registered automatically. The `mod.toml` format uses TOML with
fields: `id` (required), `name`, `version`, `author`, `description`,
`priority`, and `dependencies`. Subdirectories without `mod.toml` are silently
skipped.

Load ordering is deterministic: mods are sorted by ascending `priority` value
(lower loads first), with alphabetical ID as a tiebreaker. A custom explicit
load order can override this via `set_load_order()`, in which case custom-
ordered mods appear first, followed by any remaining mods in priority order.

Circular dependency detection uses iterative DFS with a visiting/visited set
model. `validate_dependencies()` reports mod IDs whose declared dependencies
are not registered, enabling pre-load validation.

The Lua API is exposed via two UserData types: `LuaMod` (wrapping `ModInfo`
with hook and config storage) and `LuaModManager` (wrapping `ModManager`).
Factory functions `lurek.modding.newMod(info)` and `lurek.modding.newModManager()`
create these objects. `LuaMod` supports per-mod named hook callbacks stored in
the Lua registry and an arbitrary config value, both releasable via
`releaseRefs()`.

Scope boundary: this module handles mod discovery, metadata, ordering, and
dependency validation. It does **not** execute mod Lua scripts, mount mod
assets into `GameFS` / `VirtualFS`, or provide a mod sandboxing layer — those
responsibilities belong to the game's `lurek.load()` orchestration and the
`filesystem` module.

## Architecture

```
lurek.modding.newMod(info)         lurek.modding.newModManager()
        │                                    │
        ▼                                    ▼
   ┌──────────┐                      ┌───────────────┐
   │  LuaMod  │◄─── registerMod ────│ LuaModManager  │
   │ (UserData)│                     │  (UserData)    │
   ├──────────┤                      ├───────────────┤
   │ ModInfo  │                      │  ModManager   │
   │ hooks    │                      │   mods: Vec   │
   │ config   │                      │   custom_order│
   └──────────┘                      │   reload_queue│
                                     └───────┬───────┘
                                             │
                              ┌──────────────┼──────────────┐
                              ▼              ▼              ▼
                       Registration     Load Order     Validation
                       ┌──────────┐   ┌───────────┐  ┌────────────┐
                       │register  │   │ priority  │  │ missing    │
                       │unregister│   │ custom    │  │ circular   │
                       │has/get/  │   │ ordering  │  │ DFS cycle  │
                       │count/all │   └───────────┘  └────────────┘
                       └──────────┘
                              │
                              ▼
                     Folder Scanning        Hot-Reload
                     ┌─────────────┐       ┌───────────┐
                     │ scan_folder │       │ mark      │
                     │ parse TOML  │       │ get queue │
                     │ auto-register│      │ clear     │
                     └─────────────┘       └───────────┘
```

## Source Files

| File              | Purpose                                                       |
|-------------------|---------------------------------------------------------------|
| `mod.rs`          | Module root — re-exports `mod_manager` submodule              |
| `mod_manager.rs`  | `ModInfo` struct and `ModManager` registry with all operations |

## Submodules

### `modding::mod_manager`

Core implementation of the mod management framework.

- **`ModInfo`** (struct) — Per-mod metadata record: id, name, version, author, description, priority, dependencies, enabled/loaded state, and filesystem path.
- **`ModManager`** (struct) — Centralised registry that stores `Vec<ModInfo>`, an optional custom load order, and a hot-reload queue. Provides registration, lookup, priority-based load ordering, folder scanning with TOML parsing, dependency validation, and reload queueing.

## Key Types

### Structs

#### `modding::mod_manager::ModInfo`

Metadata describing a single mod. All fields are public. The `id` field is the
unique identifier and the only required field when constructing via `ModInfo::new()`.
Defaults: `version` = `"1.0.0"`, `priority` = `0`, `enabled` = `true`, `loaded` = `false`,
`path` = `None`, `dependencies` = empty vec.

**Fields:**
- `id: String` — Unique mod identifier (required).
- `name: String` — Human-readable display name (defaults to `id`).
- `version: String` — Semantic version string.
- `author: String` — Author name.
- `description: String` — Mod description text.
- `priority: i32` — Load order priority (lower = loaded first).
- `dependencies: Vec<String>` — List of required mod IDs.
- `enabled: bool` — Whether the mod is enabled.
- `loaded: bool` — Whether the mod has been loaded.
- `path: Option<String>` — Filesystem path to the mod root folder.

**Public functions:**
- `new(id: impl Into<String>) -> Self` — Creates a `ModInfo` with sensible defaults.
- `from_parts(id, name, version, author, description, priority, dependencies) -> Self` — Creates a fully-populated `ModInfo` in one call; used by `lurek.modding.register` Lua API binding.

#### `modding::mod_manager::ModManager`

Centralised registry for managing mods. Stores mods in a `Vec<ModInfo>`,
an optional custom load order (`Option<Vec<String>>`), and a hot-reload
queue (`Vec<String>`). Implements `Default`.

**Public functions:**
- `new() -> Self` — Creates an empty manager.
- `register_mod(&mut self, info: ModInfo)` — Registers or replaces a mod by ID.
- `unregister_mod(&mut self, id: &str) -> bool` — Removes a mod; also removes it from the reload queue.
- `get_mod(&self, id: &str) -> Option<&ModInfo>` — Lookup by ID.
- `get_mod_mut(&mut self, id: &str) -> Option<&mut ModInfo>` — Mutable lookup by ID.
- `has_mod(&self, id: &str) -> bool` — Existence check.
- `mod_count(&self) -> usize` — Number of registered mods.
- `all_mods(&self) -> &[ModInfo]` — Slice of all registered mods.
- `load_order(&self) -> Vec<&ModInfo>` — Mods in effective load order (custom or priority-based).
- `set_load_order(&mut self, order: Vec<String>)` — Sets explicit load order by mod IDs.
- `clear_load_order(&mut self)` — Reverts to priority-based sorting.
- `get_custom_load_order(&self) -> Option<&[String]>` — Returns the current custom order, if any.
- `scan_folder(&mut self, path: &str) -> Vec<ModInfo>` — Scans a directory for `mod.toml` files and auto-registers discovered mods.
- `mark_for_reload(&mut self, id: &str) -> bool` — Adds a registered mod to the reload queue (deduplicated).
- `get_reload_queue(&self) -> &[String]` — Current reload queue.
- `clear_reload_queue(&mut self)` — Clears the reload queue.
- `validate_dependencies(&self) -> Vec<String>` — Returns mod IDs whose dependencies are missing.
- `has_circular_dependencies(&self) -> bool` — DFS cycle detection across the dependency graph.

### Enums

No public enums in this module.

## Lua API

Exposed under `lurek.modding.*` by `src/lua_api/modding_api.rs`. The API surface consists of two factory functions and two UserData types.

### Factory Functions

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.modding.newMod` | `(info: table) -> Mod` | Creates a `Mod` from an info table. Requires an `id` field; optional: `name`, `version`, `author`, `description`, `priority`, `dependencies`. |
| `lurek.modding.newModManager` | `() -> ModManager` | Creates a new empty `ModManager`. |

### Mod UserData Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `mod:getId()` | `string` | Unique mod identifier. |
| `mod:getName()` | `string` | Display name. |
| `mod:getVersion()` | `string` | Version string. |
| `mod:getAuthor()` | `string` | Author name. |
| `mod:getDescription()` | `string` | Mod description. |
| `mod:getDependencies()` | `table` | Array of required mod IDs. |
| `mod:getPriority()` | `integer` | Load-order priority. |
| `mod:isEnabled()` | `boolean` | Whether the mod is enabled. |
| `mod:setEnabled(enabled)` | `nil` | Sets the enabled state. |
| `mod:isLoaded()` | `boolean` | Whether the mod has been loaded. |
| `mod:setHook(name, func)` | `nil` | Registers a named hook callback (replaces existing). |
| `mod:getHook(name)` | `function?` | Returns the hook function or nil. |
| `mod:hasHook(name)` | `boolean` | Whether a hook with the given name exists. |
| `mod:getHookNames()` | `table` | Array of registered hook names. |
| `mod:setConfig(value)` | `nil` | Stores an arbitrary config value. |
| `mod:getConfig()` | `any?` | Returns the stored config value or nil. |
| `mod:releaseRefs()` | `nil` | Releases all hook and config Lua registry references. |

### ModManager UserData Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `mgr:registerMod(mod)` | `nil` | Registers a Mod userdata. |
| `mgr:unregisterMod(id)` | `boolean` | Removes a mod by ID. |
| `mgr:hasMod(id)` | `boolean` | Whether a mod is registered. |
| `mgr:getModCount()` | `integer` | Number of registered mods. |
| `mgr:getAllMods()` | `table` | Array of info tables for all mods. |
| `mgr:getLoadOrder()` | `table` | Array of info tables in effective load order. |
| `mgr:setLoadOrder(order)` | `nil` | Sets explicit load order from string array. |
| `mgr:clearLoadOrder()` | `nil` | Reverts to priority-based sorting. |
| `mgr:scanFolder(path)` | `table` | Scans directory for mods and registers them. |
| `mgr:getModPath(id)` | `string?` | Filesystem path of a registered mod. |
| `mgr:validateDependencies()` | `table` | Array of mod IDs with missing deps. |
| `mgr:hasCircularDependencies()` | `boolean` | Whether circular dependency cycles exist. |
| `mgr:markForReload(id)` | `boolean` | Marks a mod for hot-reload. |
| `mgr:getReloadQueue()` | `table` | Array of mod IDs pending reload. |
| `mgr:clearReloadQueue()` | `nil` | Clears the reload queue. |

## Lua Examples

```lua
function lurek.init()
    -- Create a mod manager
    local mgr = lurek.modding.newModManager()

    -- Scan the mods/ directory for mod.toml files
    local found = mgr:scanFolder("mods/")
    print("Discovered " .. #found .. " mods")

    -- Validate dependencies before loading
    local missing = mgr:validateDependencies()
    if #missing > 0 then
        print("Missing dependencies: " .. table.concat(missing, ", "))
        return
    end

    -- Check for circular dependencies
    if mgr:hasCircularDependencies() then
        print("Circular dependency detected!")
        return
    end

    -- Get the resolved load order
    local order = mgr:getLoadOrder()
    for i, info in ipairs(order) do
        print(i .. ". " .. info.name .. " v" .. info.version)
    end
end
```

```lua
-- Creating mods programmatically with hooks
local m = lurek.modding.newMod({
    id       = "weather-fx",
    name     = "Weather Effects",
    version  = "1.0.0",
    author   = "Luna",
    priority = 10,
    dependencies = { "core-utils" },
})

-- Register a named hook
m:setHook("onWeatherChange", function(weather_type)
    print("Weather changed to: " .. weather_type)
end)

-- Store per-mod config
m:setConfig({ rain_intensity = 0.8, snow = false })

-- Later, retrieve and invoke
if m:hasHook("onWeatherChange") then
    local fn = m:getHook("onWeatherChange")
    fn("rain")
end

local cfg = m:getConfig()
print("Rain intensity: " .. cfg.rain_intensity)
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 2     |
| `enum`    | 0     |
| `fn`      | 19    |
| **Total** | **21**|

## References

| Module       | Relationship  | Notes                                                      |
|--------------|---------------|------------------------------------------------------------|
| `engine`     | Imports from  | Uses `log_messages` constants (`MD01_MGR_INIT`, `MD02_MOD_REG`, `MD04_ORDER_OK`) via `log_msg!` macro |
| `math`       | —             | Not imported (no geometry or colour needed)                 |
| `filesystem` | Related       | Mods may declare asset overrides that `GameFS`/`VirtualFS` resolves; modding itself does not import filesystem |
| `lua_api`    | Imported by   | `src/lua_api/modding_api.rs` registers `lurek.modding.*`, wraps `ModInfo` as `LuaMod` and `ModManager` as `LuaModManager` |

**Similar modules:**
- `savegame` — Also Tier 2, also manages user-side data. Modding handles content discovery and ordering; savegame handles persistence and schema versioning.

## Notes

- **TOML is the manifest format.** Mod metadata is parsed from `mod.toml` files using the `toml` crate. JSON and YAML are not accepted. This follows constraint B-05.
- **`id` is the only required TOML field.** All other fields (`name`, `version`, `author`, `description`, `priority`, `dependencies`) are optional and have sensible defaults.
- **Load order is deterministic.** Priority ascending, then alphabetical ID. Custom order overrides via `set_load_order()` take precedence for listed mods; unlisted mods are appended in priority order.
- **Circular dependency detection** uses a three-set DFS (unvisited, visiting, visited). A `true` return from `has_circular_dependencies()` means at least one cycle exists but does not identify which mods are involved.
- **`scan_folder` does real filesystem I/O** via `std::fs::read_dir`. It is not sandboxed through `GameFS`. This is intentional — mod discovery happens before the game's virtual filesystem is fully mounted.
- **Hot-reload queue is a notification mechanism only.** `mark_for_reload()` adds a mod ID to a queue; the module does not perform the actual reload. The game's main loop is responsible for polling `get_reload_queue()` and re-executing mod scripts.
- **Lua hook storage** uses `LuaRegistryKey`. Call `releaseRefs()` when discarding a `LuaMod` to prevent registry leaks.
- **Re-registering a mod replaces it.** If `register_mod()` is called with a `ModInfo` whose `id` already exists, the old entry is overwritten in place. This is by design for mod updates.
- **No SlotMap keys.** Unlike graphics/audio resources, mods are stored in a plain `Vec<ModInfo>` with linear ID lookup. This is adequate because mod counts are small (typically < 100).
- **Breaking change surface:** Renaming `mod.toml` fields or changing the `ModInfo` field names would break existing mod manifests and any game code that reads info tables from `getAllMods()` / `getLoadOrder()`.
