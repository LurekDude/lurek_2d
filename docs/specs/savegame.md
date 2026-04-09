# `savegame` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extensions                           |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.savegame`                                      |
| **Source**     | `src/savegame/`                                      |
| **Rust Tests** | `tests/rust/unit/savegame_tests.rs`                  |
| **Lua Tests**  | `tests/lua/unit/test_savegame.lua`                   |

## Summary

The savegame module provides a pure-data save manager for slot-based game save/load
with schema versioning, dirty-state tracking, auto-save timers, and Lua-literal
serialisation.  `SaveManager` is the central struct that tracks named collector
modules, migration version chains, and an auto-save timer that only fires when
the in-memory state is dirty.  The serialisation subsystem converts a `HashMap<String,
SaveValue>` tree into a `return { key = value, ... }` Lua-literal string that
`loadfile()` can deserialise without any custom parser — no JSON, no MessagePack,
just valid Lua source.

The module deliberately separates concerns: `SaveManager` owns the bookkeeping
(registration, versioning, dirty flag, auto-save timer), while actual filesystem
I/O is delegated to the `GameFS` subsystem and invoked from the Lua API layer.
This makes the Rust core fully unit-testable without touching the filesystem.

Save files live under `save/slot_<name>.sav` inside the game directory.  Each file
embeds metadata fields (`__schema_version`, `__timestamp`, `__summary`) alongside
the game data so that `getSlotInfo` and `getSlots` can read metadata without a full
restore.  Schema versioning lets games register migration callbacks keyed by
version number; when a save from version N is loaded against schema version M > N,
all registered migrations in [N, M) are applied in ascending order.

The Lua API exposes `SaveManager` as a UserData object created via
`luna.savegame.newSaveManager()`.  Games register per-module collector/restorer
callback pairs, then call `save(slot)` and `load(slot)` for full round-trip
persistence.  The auto-save timer is advanced by calling `update(dt)` each frame;
it returns the slot name when a save should trigger, but only if data is dirty.

Scope boundaries: this module does NOT provide binary serialisation (see `data`),
save-file encryption, cloud save synchronisation, or undo/redo history.  It is a
pure-Lua-literal persistence layer with schema migration support.

## Architecture

```
luna.savegame.newSaveManager()
          │
          ▼
   LuaSaveManager (UserData)
     ├── manager: SaveManager (Rust bookkeeping)
     │     ├── schema_version: i32
     │     ├── registered: Vec<String>
     │     ├── dirty: bool
     │     ├── auto_save: Option<(f64, String)>
     │     ├── auto_save_elapsed: f64
     │     ├── migration_versions: Vec<i32>
     │     └── summary: String
     │
     ├── collectors: HashMap<String, RegistryKey>   (Lua fn → data table)
     ├── restorers:  HashMap<String, RegistryKey>   (data table → game state)
     ├── migrations: HashMap<i32, RegistryKey>      (version → transform fn)
     └── state: Rc<RefCell<SharedState>>            (for GameFS access)

Save flow:
  sm:save("slot1")
    → collect_data()   → calls each collector fn → builds data table
    → serialize_table() → produces "return { ... }" string
    → GameFS::write_string("save/slot_slot1.sav")
    → clear_dirty()

Load flow:
  sm:load("slot1")
    → GameFS::read_string("save/slot_slot1.sav")
    → eval_save_content() → Lua loadstring → data table
    → apply_migrations()  → walks migration_versions in [saved, current)
    → call_restorers()    → feeds each restorer its subtable
    → clear_dirty()

Serialisation (Rust-side):
  SaveValue enum ──► serialize_value() ──► Lua literal string
  HashMap<String, SaveValue> ──► serialize_table() ──► "return { ... }\n"
  Depth limit: 32 levels of nesting (returns Err if exceeded)
```

## Source Files

| File           | Purpose                                                                                 |
|----------------|-----------------------------------------------------------------------------------------|
| `mod.rs`       | Module root: `SlotMeta`, `SaveManager`, `SaveValue` enum, `serialize_table`/`serialize_value` functions, private Lua-string helpers, inline unit tests |
| `save_data.rs` | Alternate copy of save data types (orphaned — not declared via `mod save_data;` in `mod.rs`) |

## Submodules

### `savegame` (root — `mod.rs`)

All public types and functions live directly in the module root.

- **`SlotMeta`** (struct): Metadata extracted from a save slot — slot name, unix timestamp, schema version, summary string.
- **`SaveManager`** (struct): Pure-data save manager providing registration of named collectors, schema versioning, dirty-state tracking, auto-save timer, and slot file path generation.
- **`SaveValue`** (enum): Simple value type matching the serialisable Lua subset — Nil, Bool, Number, Str, Table.
- **`serialize_table`** (fn): Converts a `HashMap<String, SaveValue>` into a `return { ... }` Lua-literal string with indentation, respecting a depth limit of 32.
- **`serialize_value`** (fn): Converts a single `SaveValue` into its Lua-literal string representation.

## Key Types

### Structs

#### `savegame::SlotMeta`

Metadata extracted from a save slot.  Contains four public fields:

- `slot: String` — the slot name identifier.
- `timestamp: f64` — unix epoch timestamp when the save was written.
- `version: i32` — the schema version at save time.
- `summary: String` — an optional human-readable summary string.

Implements `Debug`, `Clone`, `Default`.

#### `savegame::SaveManager`

Pure-data save manager providing registration of named collectors, schema
versioning, dirty-state tracking, and auto-save timer.  All fields are private;
access is through methods.

Key methods:

| Method                        | Signature                                          | Purpose                                                 |
|-------------------------------|----------------------------------------------------|---------------------------------------------------------|
| `new()`                       | `() → Self`                                        | Creates an empty manager with all defaults               |
| `register(name)`             | `(impl Into<String>)`                              | Registers a named collector module (idempotent)          |
| `unregister(name)`           | `(&str)`                                           | Removes a collector by name                              |
| `registered_names()`         | `() → &[String]`                                   | Returns the list of registered module names              |
| `set_schema_version(v)`      | `(i32)`                                            | Sets the current schema version                          |
| `schema_version()`           | `() → i32`                                         | Returns the current schema version                       |
| `add_migration(from)`        | `(i32)`                                            | Records a migration version key (kept sorted)            |
| `applicable_migrations(from)`| `(i32) → Vec<i32>`                                 | Returns migration versions in [from, current)            |
| `mark_dirty()`               | `()`                                               | Marks data as modified                                   |
| `is_dirty()`                 | `() → bool`                                        | Whether data has been modified since last save/load      |
| `clear_dirty()`              | `()`                                               | Clears the dirty flag                                    |
| `enable_auto_save(interval, slot)` | `(f64, impl Into<String>)`                  | Enables auto-save with interval and target slot          |
| `disable_auto_save()`        | `()`                                               | Disables auto-save                                       |
| `update(dt)`                 | `(f64) → Option<String>`                           | Advances timer; returns slot name if save should trigger |
| `reset()`                    | `()`                                               | Resets all state to construction defaults                 |
| `slot_path(slot)`            | `(&str) → String`                                  | Builds `save/slot_<name>.sav` file path                  |
| `set_summary(summary)`       | `(String)`                                         | Sets summary string for save metadata                    |
| `summary()`                  | `() → &str`                                        | Returns the current summary string                       |

### Enums

#### `savegame::SaveValue`

A simple value type matching the Lua subset the module can serialise.

| Variant                            | Payload                         | Lua Equivalent |
|------------------------------------|---------------------------------|----------------|
| `Nil`                              | —                               | `nil`          |
| `Bool(bool)`                       | `bool`                          | `true`/`false` |
| `Number(f64)`                      | `f64`                           | number literal |
| `Str(String)`                      | `String`                        | `"string"`     |
| `Table(HashMap<String, SaveValue>)`| `HashMap<String, SaveValue>`    | `{ k = v }`    |

Implements `Debug`, `Clone`.

## Lua API

Exposed under `luna.savegame.*` by `src/lua_api/savegame_api.rs`.

The module registers a single factory function on the `luna.savegame` table.
All save operations are methods on the `SaveManager` UserData object.

### Factory Function

| Function                      | Returns         | Description                                     |
|-------------------------------|-----------------|-------------------------------------------------|
| `luna.savegame.newSaveManager()` | `SaveManager` | Creates a new empty save manager UserData object |

### SaveManager Methods

| Method                                        | Returns          | Description                                                                 |
|-----------------------------------------------|------------------|-----------------------------------------------------------------------------|
| `sm:register(name, collector, restorer)`      | —                | Registers a named module with collector and restorer Lua callbacks           |
| `sm:unregister(name)`                         | —                | Removes a named module and its callbacks                                     |
| `sm:setSchemaVersion(version)`                | —                | Sets the current schema version for new saves                                |
| `sm:getSchemaVersion()`                       | `integer`        | Returns the current schema version                                           |
| `sm:addMigration(from_version, func)`         | —                | Registers a migration function for upgrading from a version                  |
| `sm:collect()`                                | `table`          | Calls all collectors and returns a data table with metadata                  |
| `sm:restore(data)`                            | —                | Restores data from a table, applying migrations and calling restorers        |
| `sm:markDirty()`                              | —                | Marks data as modified since the last save or load                           |
| `sm:isDirty()`                                | `boolean`        | Returns whether data has been modified                                       |
| `sm:enableAutoSave(interval, slot)`           | —                | Enables auto-save with interval (seconds) and target slot name               |
| `sm:disableAutoSave()`                        | —                | Disables auto-save                                                           |
| `sm:update(dt)`                               | `string?`        | Advances auto-save timer; returns slot name if a save should trigger         |
| `sm:setSummary(summary)`                      | —                | Sets a summary string included in save metadata                              |
| `sm:getSummary()`                             | `string`         | Returns the current summary string                                           |
| `sm:reset()`                                  | —                | Resets all state, removing callbacks and clearing the manager                 |
| `sm:save(slot)`                               | —                | Collects data from all collectors and writes to `save/slot_<name>.sav`       |
| `sm:load(slot)`                               | `boolean, string?` | Loads from a slot file, applies migrations, restores; returns success + error |
| `sm:delete(slot)`                             | —                | Deletes a save file for the given slot                                       |
| `sm:exists(slot)`                             | `boolean`        | Returns whether a save file exists for the given slot                        |
| `sm:getSlots()`                               | `table`          | Returns an array of all save slots with metadata tables                      |
| `sm:getSlotInfo(slot)`                        | `table?`         | Returns metadata for a single slot, or nil if not found                      |

### Metadata Table Fields (from `getSlotInfo` / `getSlots`)

| Field       | Type      | Description                        |
|-------------|-----------|------------------------------------|
| `slot`      | `string`  | Slot name                          |
| `version`   | `integer` | Schema version at save time        |
| `timestamp` | `number`  | Unix epoch timestamp               |
| `summary`   | `string`  | Summary string (may be empty)      |

## Lua Examples

```lua
-- Basic save/load with schema versioning and auto-save

local sm

function luna.init()
    sm = luna.savegame.newSaveManager()
    sm:setSchemaVersion(2)

    -- Register a collector/restorer pair for the "player" system
    sm:register("player",
        function()
            -- Collector: return data to save
            return { hp = player_hp, gold = player_gold, level = player_level }
        end,
        function(data)
            -- Restorer: apply loaded data
            if data then
                player_hp    = data.hp    or 100
                player_gold  = data.gold  or 0
                player_level = data.level or 1
            end
        end
    )

    -- Register a migration from version 1 → 2
    sm:addMigration(1, function(data)
        -- Old saves had "score" instead of "gold"
        if data.player then
            data.player.gold = data.player.score or 0
            data.player.score = nil
        end
        return data
    end)

    -- Enable auto-save every 60 seconds to the "auto" slot
    sm:enableAutoSave(60, "auto")

    -- Try loading an existing save
    local ok, err = sm:load("slot1")
    if not ok then
        -- No save found or corrupt — start fresh
        player_hp    = 100
        player_gold  = 0
        player_level = 1
    end
end

function luna.process(dt)
    -- Advance auto-save timer (fires only when dirty)
    local slot = sm:update(dt)
    if slot then
        sm:save(slot)
    end

    -- Game logic that modifies state
    if gained_gold then
        player_gold = player_gold + 10
        sm:markDirty()
    end
end

function luna.keypressed(key)
    if key == "f5" then
        sm:setSummary("Level " .. player_level)
        sm:save("slot1")
    elseif key == "f9" then
        sm:load("slot1")
    end
end
```

```lua
-- Listing and inspecting save slots

function show_save_menu()
    local sm = luna.savegame.newSaveManager()
    local slots = sm:getSlots()

    for i, info in ipairs(slots) do
        print(string.format("Slot: %s  Version: %d  Time: %.0f  Summary: %s",
            info.slot, info.version, info.timestamp, info.summary))
    end

    -- Check a specific slot
    local info = sm:getSlotInfo("slot1")
    if info then
        print("Slot1 exists, version " .. info.version)
    end

    -- Delete a slot
    if sm:exists("old_save") then
        sm:delete("old_save")
    end
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 2     |
| `enum`     | 1     |
| `fn`       | 20    |
| **Total**  | **23**|

## References

| Module       | Relationship  | Notes                                                             |
|--------------|---------------|-------------------------------------------------------------------|
| `engine`     | Imports from  | Uses `SharedState`, log message constants (`SV01`–`SV04`)         |
| `filesystem` | Imports from  | `GameFS` for sandboxed `read_string`/`write_string`/`remove`/`list`/`exists` |
| `data`       | Related       | `data` handles binary serialisation (ByteData, compression, hashing); `savegame` provides Lua-literal text serialisation with schema versioning |
| `lua_api`    | Imported by   | `src/lua_api/savegame_api.rs` registers `luna.savegame.*` and defines `LuaSaveManager` UserData |
| `math`       | Not imported  | No direct dependency on math types                                |

## Notes

- Save files are Lua source (`return { ... }`) — human-readable and `loadfile()`-compatible. No JSON, no binary format.
- The `__schema_version`, `__timestamp`, and `__summary` keys are reserved metadata injected by `collect_data()`. Games must not use keys prefixed with `__` in their collector data.
- The depth limit for `serialize_table` is 32 levels. Deeper nesting returns an error string, not a panic.
- `save_data.rs` exists in the directory but is not declared as a submodule in `mod.rs` — it is an orphaned file and is not compiled.
- Auto-save only triggers when `is_dirty()` is true. Calling `update(dt)` on clean data never produces a slot name, regardless of elapsed time.
- `slot_path()` generates `save/slot_<name>.sav` — all slot files live under a `save/` subdirectory relative to the game directory.
- `LuaSaveManager` in the Lua API layer stores collector, restorer, and migration callbacks as `LuaRegistryKey` entries. `reset()` properly drains and removes all registry keys to avoid leaks.
- Do not save resource keys (`TextureKey`, `FontKey`, etc.) — they are runtime-only generational IDs. Save logical identifiers (asset paths, names) instead.
- `serialize_value` and `serialize_table` are public free functions in the module root, usable from Rust without going through the Lua API.
- The `load()` method returns `(boolean, string?)` — the second value is an error message on failure, nil on success. Games should check both values.
