---
applyTo: "src/savegame/**"
---

# Savegame Module Instructions

Rules for working on `src/savegame/` — save/load system.

## Module Rules

- SaveManager handles save slot registration, autosave, and schema versioning
- SaveValue is a recursive enum: `Nil`, `Bool(bool)`, `Num(f64)`, `Str(String)`, `Table(HashMap<String, SaveValue>)`
- Registration is **idempotent** — registering the same slot twice doesn't increase the count
- Serialize `LuaTable` → `SaveValue::Table` for storage; deserialize back to Lua tables for loading

## Key Types

- `SaveManager` — slot management, autosave scheduling, schema version tracking
- `SaveValue` — recursive serializable value type (mirrors Lua types)
- `serialize_table()` — converts Lua table to SaveValue recursively
- `serialize_value()` — converts single Lua value to SaveValue

## Dependency Direction

- `savegame` depends on `math` (versioning comparisons) and `serde` (serialization)
- `savegame` must NOT depend on `graphics`, `physics`, `audio`, or `engine`
- `lua_api/savegame_api.rs` bridges save types to Lua

## Schema Versioning

- Save data includes `__schema_version` field
- Version mismatch triggers migration logic, not silent data loss
- Autosave can be enabled/disabled independently of manual saves

## Testing

- Tests in `tests/savegame_tests.rs`
- Test helper: `make_vm()` returns `(state, lua)` tuple
- Test slot registration (idempotent), count tracking
- Test SaveValue round-trip (all variants)
- Test autosave enable/disable
