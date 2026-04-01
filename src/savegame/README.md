# `src/savegame/` — Save Data Management

## Purpose

The savegame module handles the lifecycle management of game save data: naming
and registering save slots, tracking whether the current in-memory state is
dirty (modified since the last write to disk), firing auto-save at configurable
intervals (for example every 60 seconds of real time), and serialising Lua
tables to a `return { ... }` Lua-literal format that `loadfile()` can
deserialise without any custom parser.  The module deliberately does not
perform file I/O — serialised strings are passed to `luna.filesystem.write()`
by the caller so the I/O boundary is explicit and the module is fully
unit-testable without touching the filesystem.

Schema versioning allows save files to carry a version number so that older
saves can be migrated to newer formats.  Games register migration steps with
`add_migration(from_version)` and call `applicable_migrations(loaded_version)`
at load time to determine which migration steps to apply.  Dirty tracking
prevents excessive disk writes: the auto-save timer only fires when `is_dirty()`
is true, so repeated calls to `update(dt)` on an unchanged state produce no
I/O at all.

## Architecture

```
SaveManager (save state tracker)
  │
  ├── Schema versioning
  │     ├── schema_version: u32
  │     └── migration_versions: Vec<u32> (upgrade history)
  │
  ├── Slot registration
  │     ├── registered: Vec<String> (named save slots)
  │     └── register / unregister
  │
  ├── Auto-save
  │     ├── enable_auto_save(interval, slot_name)
  │     ├── disable_auto_save()
  │     └── update(dt) → Option<String> (fires when interval elapses)
  │
  ├── Dirty tracking
  │     ├── mark_dirty() / is_dirty() / clear_dirty()
  │     └── Auto-save only fires if dirty
  │
  └── Serialization
        ├── serialize_table(lua_table) → String
        ├── serialize_value(value) → String
        └── Output: `return { key = value, ... }` format
```

### How It Works

The `return { ... }` serialisation format produces valid Lua source code that
any standard Lua interpreter (or `load()` with a string) can evaluate.  Table
keys that are valid identifiers are emitted bare (`score = 100`); keys
requiring quoting use `["key"] = value` form.  String values escape
backslashes, newlines, tabs, null bytes, and quote characters.  Numbers are
formatted with full precision via Rust's `f64` formatter to avoid
precision loss in floating-point game values.

Auto-save follows a pull model: `update(dt)` returns `Option<String>` — the
slot name to write, or `None`.  The game or engine shell calls `update(dt)`
every frame and responds to a returned slot name by performing the actual
filesystem write.  This means the savegame module has zero knowledge of the
filesystem and can be tested with a harness that simply records which slot
names were returned.

### Dependency Direction

```
savegame/ ──────► (none)
```

**Leaf module** — no Luna2D dependencies. Pure save management logic.

---

## File-by-File Analysis

### `mod.rs` — Complete Save Manager (Single File Module)

**~256 lines** | Full save management implementation.

#### Struct: `SlotMeta`

```rust
pub struct SlotMeta {
    pub slot: String,
    pub timestamp: Option<String>,
    pub version: u32,
    pub summary: Option<String>,
}
```

#### Enum: `SaveValue`

`Nil | Bool(bool) | Number(f64) | Str(String) | Table(Vec<(SaveValue, SaveValue)>)`

#### Struct: `SaveManager`

```rust
pub struct SaveManager {
    schema_version: u32,
    registered: Vec<String>,
    dirty: bool,
    auto_save: Option<(f64, String)>,   // (interval_secs, slot_name)
    auto_save_elapsed: f64,
    migration_versions: Vec<u32>,
}
```

#### Methods

| Method | Purpose |
|--------|---------|
| `new()` | Create manager |
| `register(name)` / `unregister(name)` | Manage save slots |
| `registered_names()` | List all slots |
| `set/get_schema_version(v)` | Schema versioning |
| `add_migration(version)` | Register migration version |
| `applicable_migrations(from_v)` | Get migrations needed |
| `mark_dirty()` / `is_dirty()` / `clear_dirty()` | Change tracking |
| `enable_auto_save(interval, slot)` | Start auto-save timer |
| `disable_auto_save()` | Stop auto-save |
| `update(dt)` → `Option<String>` | Tick timer, returns slot name when due |
| `reset()` | Clear all state |

#### Serialization Functions (free)

| Function | Purpose |
|----------|---------|
| `serialize_table(table)` | Lua table → `return { ... }` string |
| `serialize_value(value)` | Single value → Lua literal |

Helpers: `is_lua_identifier(s)`, `escape_lua_str(s)`.

**Design**: Produces Lua-loadable strings using `return { ... }` format. Tables
are serialized recursively. String escaping handles special characters.
Auto-save only triggers when `dirty` is true.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/savegame_api.rs` (~200 lines), exposing
save management under `luna.savegame.*`.

### Usage from Lua

```lua
-- Register save slots
luna.savegame.register("autosave")
luna.savegame.register("manual")

-- Enable auto-save every 60 seconds
luna.savegame.enableAutoSave(60, "autosave")

-- Save game data
local data = { level = 5, score = 1200, inventory = {"sword", "shield"} }
local serialized = luna.savegame.serialize(data)
luna.filesystem.write("save/autosave.lua", serialized)

-- Load game data
local content = luna.filesystem.read("save/autosave.lua")
local loaded = luna.savegame.deserialize(content)
```
