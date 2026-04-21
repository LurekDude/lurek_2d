# IDEA — `src/serial/`

> **This file is forward-looking.** It records ideas, not commitments. Nothing here is
> implemented in the same session that produces it. Implementation is gated by a separate
> roadmap decision.

---

## 1. Header

- **Module**: `serial`
- **Owner module path**: `src/serial/`
- **Last reviewed**: 2026-04-18 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy**: `CORE-KEEP`
- **LOC (rust only)**: ~1091 · **Public Lua surface**: `lurek.serial` — 10 fns / 0 userdata
- **Inbound non-`lua_api` callers**: `save` (toml round-trip), `data` (CsvOptions)
- **Heavy dependencies**: `serde_json`, `toml`, `csv`, `rmp-serde`, `roxmltree`, `serde_yml` (dead), `indexmap`

## 2. Mission Summary

The `serial` module provides Lurek2D's format-agnostic text serialization and deserialization,
centred on the `SerialValue` recursive enum that all format drivers convert to and from.
It serves EngDev (Rust callers) and GameDev/Modder (via `lurek.serial.*`). It deliberately
performs no file I/O — callers supply strings and receive strings back. It is NOT a game-save
system (`save` owns persistence) nor a binary asset packer.

## 3. Existing Strengths

- Clean `SerialValue` IR decouples format drivers from each other and from Lua bridging (`lua_table.rs`).
- Five active format drivers (JSON, TOML, CSV, MessagePack, XML) with consistent encode/decode API shapes.
- Built-in declarative schema validation (`schema.rs`) — no external schema crate needed.
- All pub functions return `Result<_, String>` with descriptive error messages including format context.
- Zero file I/O — clear Foundations-tier boundary; no coupling to `filesystem` or `window`.
- Comprehensive Lua bridge surface (10 functions) covering all active formats plus schema validation.

## 4. Gap List

1. **[P2][GAP]** `Dead YAML code` — `yaml.rs` exists and compiles but is commented out in `mod.rs`. The `serde_yml` dependency remains in `Cargo.toml`, adding ~80 KB to binary.
   - Why: dead code bloats binary and confuses contributors.
2. **[P2][GAP]** `No streaming CSV parsing` — `from_csv` loads the entire string into memory before parsing.
   - Why: large datasets (e.g. leaderboard imports, tile-attribute tables) may exceed reasonable memory.
3. **[P3][GAP]** `No format auto-detection` — callers must know the format ahead of time.
   - Why: GameDev loading user-dropped config files cannot auto-detect JSON vs TOML.

## 5. Feature Ideas

1. **[P2][FEAT]** `Unified codec dispatch` — A single `lurek.serial.encode(tbl, "json")` / `lurek.serial.decode(str, "json")` entry point alongside the format-specific functions. Easier to switch formats at runtime.
   - Rationale: GameDev can pass format as a config value instead of branching in Lua.
   - Effort: S · Risk: low.
   - Competitor inspiration: LÖVE's `love.data.encode/decode` uses a single entry point with format param — [love2d.org/wiki/love.data.encode](https://love2d.org/wiki/love.data.encode).
2. **[P3][FEAT]** `Schema defaults` — Extend `schema.rs` to fill missing fields with schema-provided default values, returning a patched `SerialValue`.
   - Rationale: simplifies GameDev config loading — declare schema once, get sensible defaults.
   - Effort: M · Risk: low.
3. **[P3][FEAT]** `INI format driver` — Lightweight read-only parser for legacy `.ini` config files.
   - Rationale: Modders porting content from other engines often have `.ini` config.
   - Effort: S · Risk: low.
   - Competitor inspiration: Godot's `ConfigFile` class reads INI-style data — [docs.godotengine.org/en/stable/classes/class_configfile](https://docs.godotengine.org/en/stable/classes/class_configfile.html).

## 6. Performance / Reliability / Quality Ideas

- **[P2][QUAL]** `Remove dead yaml.rs` — Delete `yaml.rs` and drop `serde_yml` from `Cargo.toml` to honour B-05 cleanly. If a future fallback is needed, feature-gate it behind `cfg(feature = "yaml")`.
- **[P3][PERF]** `Avoid intermediate MsgValue allocation` — `msgpack.rs` converts SerialValue→MsgValue→bytes. A direct `SerialValue` serde impl (or manual rmp writes) would halve allocations on the encode path.
  - Hot path: `msgpack.rs:serial_to_msg` + `encode`.
  - Verification: criterion bench on 10 KB nested map.
- **[P3][QUAL]** `Consolidate CSV field stringification` — `serial_value_to_csv_field` in `csv.rs` duplicates variant-to-string logic that could be a `Display` impl on `SerialValue`.

## 7. Test Coverage Gaps

- **[P1][TEST-RUST]** Add Rust unit tests for `lua_table.rs` to/from Lua round-trips — DONE this session (11 tests).
- **[P1][TEST-RUST]** Add Rust unit tests for `msgpack.rs` encode/decode — DONE this session (8 tests).
- **[P1][TEST-RUST]** Add Rust unit tests for `schema.rs` validate — DONE this session (12 tests).
- **[P1][TEST-RUST]** Add Rust unit tests for `xml.rs` decode — DONE this session (6 tests).
- **[P2][TEST-FUZZ]** Fuzz target candidate: `from_json`, `from_toml`, `decode` (xml) with arbitrary byte inputs.

## 8. TODO(dedup): Cross-Module Overlap

```text
TODO(dedup): save::toml — save module re-implements TOML round-trip via serial::from_toml/to_toml; confirm no parallel serialization code exists in save.
TODO(dedup): data::csv — data module may have its own CSV parsing separate from serial::CsvOptions; verify single implementation.
TODO(dedup): data::msgpack — P2 overlap prescan flagged msgpack encoding in both serial and data; confirm data delegates to serial or deduplicate.
```

## 9. TODO(helper): Engine-Level Helper Candidates

```text
TODO(helper): codec_auto_detect — game authors manually branch on file extension to pick format; a helper that sniffs content or extension and calls the right decoder would reduce boilerplate — citation: content/library/ pattern grep needed.
```

## 10. TODO(plugin): Plugin Candidacy Proposal

```text
TODO(plugin): CORE-KEEP — serialization is foundational infrastructure used by save, data, config loading, and the Lua bridge. No extraction benefit; all 5 format drivers share SerialValue.
```

- **Extraction blockers**: `save` and `data` import serial types directly; `lua_api/serial_api.rs` bridges all formats.
- **Heavy dep impact if extracted**: n/a (CORE-KEEP).
- **Lua surface stability**: stable.
- **Migration step**: n/a.

## 11. References

- Module spec: [docs/specs/serial.md](../../../docs/specs/serial.md)
- Lua API reference: [docs/API/lua-api.md#codec](../../../docs/API/lua-api.md)
- Philosophy constraints touched: `B-05` (TOML preferred, no YAML) — see [philosophy.md](../../../docs/architecture/philosophy.md)
- Plugin doc tier table: [plugins.md §5](../../../docs/architecture/plugins.md#5-candidate-modules)
- Competitor links cited above: LÖVE `love.data.encode`, Godot `ConfigFile`
- Authoring guide: [IDEA_AUTHORING.md](../../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
- Session plan: [PLAN.md](../../../work/src-module-review-20260418/reports/PLAN.md) · Session decisions: [DECISIONS.md](../../../work/src-module-review-20260418/reports/DECISIONS.md)
