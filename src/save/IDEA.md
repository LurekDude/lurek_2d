# IDEA.md — `save` module

| Field           | Value       |
| --------------- | ----------- |
| **Module**      | `save`      |
| **Path**        | `src/save/` |
| **Date**        | 2026-04-18  |
| **Plugin Tier** | CORE-KEEP   |

---

## Mission Summary

The `save` module provides Lurek2D's game save/load orchestration system. It coordinates named collector callbacks (Lua functions that gather/restore game state), tracks a schema version integer for save-file format upgrades, maintains a dirty flag, drives optional auto-save on a configurable interval, and provides Lua-compatible value serialization. Exposed to Lua as `lurek.save.*`.

## Existing Strengths

- Clean collector pattern — game modules register independently, SaveManager orchestrates.
- Schema versioning with ordered migration support — enables forward-compatible save files.
- Auto-save timer with dirty-flag gating — no unnecessary writes.
- `SaveValue` enum covers the full Lua primitive subset (nil, bool, number, string, table).
- Depth-limited serialization prevents stack overflow on circular/deep structures.
- `SlotMeta` separates metadata from payload — enables listing slots without loading full data.
- `slot_path()` enforces a predictable naming convention (`save/slot_<name>.sav`).

## Gap List

1. **Dead file**: `save_data.rs` is NOT declared in `mod.rs` — it is dead code duplicating `save_manager.rs`. Contains an older copy of `SaveManager`, `SaveValue`, `serialize_table`, etc. without the `summary`, `slot_path`, `parse_save_string`, or `SaveValue::from_lua` additions.
2. No LZ4/zstd compression at the Rust level — compression flag exists in the Lua API but is implemented in Lua.
3. No screenshot/thumbnail attachment for save slots.
4. No incremental/delta save support.
5. No save-file integrity check (checksum or signature).
6. `serialize_table` output order is non-deterministic (`HashMap` iteration) — save files may diff unnecessarily.

## Feature Ideas

1. **Save-file checksum** — Append a CRC32 or SHA256 hash to detect corruption or tampering. *Citation*: Godot's `ResourceSaver` includes format versioning and checksum; Defold's save system uses SHA1 for integrity.
2. **Deterministic serialization** — Sort keys before writing so save files are reproducible. *Citation*: LÖVE2D's `bitser` library and Defold's `sys.save()` produce deterministic output.
3. **Entity serialization bridge** — `lurek.save.collectEntity(entity)` auto-serializes ECS components. Deferred pending `lurek.ecs` stabilization. *Citation*: Bevy's `DynamicScene` serializes entities and components automatically.

## Perf/Quality Ideas

- `serialize_table` uses `format!` for each line — consider pre-allocating the output buffer based on entry count.
- `is_lua_identifier` is called per-key during serialization — could be cached for repeated saves of the same schema.
- `migration_versions.contains()` is O(n) — acceptable for small migration lists but could use a `HashSet` if >50 versions.

## Test Coverage Gaps

- `save_manager.rs` has 21 tests covering defaults, register/unregister, dirty tracking, auto-save, migrations, serialization (nil/bool/string/nested), depth limit, reset, slot_path, summary, parse_save_string, deduplication, special keys, and SlotMeta default.
- Inline comments expanded in `serialize_table` (key formatting, depth guard) and `SaveValue::from_lua` (recursive conversion, integer vs float).
- `save_data.rs` has 9 tests but is dead code (not compiled via `mod.rs`).
- No tests for `SaveValue::from_lua` (requires `mlua` context — Lua-level test needed).

## TODO(dedup): Entries

- `TODO(dedup): save_data.rs — Dead file duplicating save_manager.rs. Should be deleted or consolidated. Contains ~290 lines of code identical to save_manager.rs minus the from_lua, summary, slot_path, and parse_save_string additions.`
- `TODO(dedup): serial::to_toml — SaveManager's serialize_table/serialize_value produce a Lua-syntax string, not TOML. The spec says "serialization delegated to crate::serial" but the actual implementation is self-contained Lua-syntax serializer. Clarify the contract or unify with serial module.`
- `TODO(dedup): filesystem::GameFS — save_api.rs does file I/O in the Lua layer. Consider pulling slot file read/write into SaveManager using GameFS for sandbox enforcement.`

## TODO(helper): Entries

- `TODO(helper): save-utils — A content/library/ helper providing common save patterns: auto-slot-rotation (keep last N saves), save-file browser UI, import/export to clipboard.`

## TODO(plugin): Entry

- `TODO(plugin): CORE-KEEP — Save/load is a fundamental game feature needed by nearly all games. The module is lightweight (~450 lines in save_manager.rs), has no heavy crate dependencies, and the collector pattern is tightly integrated with the engine lifecycle. No benefit to extracting as a plugin.`

## References

- `src/lua_api/save_api.rs` — Lua binding layer
- `src/serial/` — Serialization module (TOML/JSON)
- `src/filesystem/` — GameFS sandbox
- `docs/specs/save.md` — Module specification
