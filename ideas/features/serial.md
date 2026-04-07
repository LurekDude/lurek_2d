# serial — Feature Analysis

**Tier**: 1 (Core)
**Spec**: `specs/serial.md`
**Files**: Format-neutral structured data serialization

## Purpose

Format-neutral serialization to/from Lua tables: JSON, TOML, CSV. Operates purely on strings — no filesystem I/O. The filesystem module handles reading/writing files; serial handles encoding/decoding.

## Current Feature Summary

- `luna.serial.encodeJson(tbl, pretty?)` / `luna.serial.decodeJson(str)` — JSON round-trip
- `luna.serial.encodeToml(tbl, pretty?)` / `luna.serial.decodeToml(str)` — TOML round-trip
- `luna.serial.encodeCsv(rows, headers?)` / `luna.serial.decodeCsv(str, headers?)` — CSV with optional headers
- Pretty-printing for JSON and TOML (human-readable output)
- All functions are pure: string in → table out, table in → string out
- TOML is the primary human-authored format (per B-05 constraint)
- JSON for external interop only

## Feature Gaps

1. **No MessagePack**: Compact binary serialization. Popular for save data, network packets, and large datasets. Smaller and faster than JSON.
2. **No binary/custom format**: No way to serialize structured data into a compact binary format. MessagePack covers many use cases but a custom format would allow user-defined schemas.
3. **No XML**: While TOML replaces XML for config, XML is still used for importing third-party data (Tiled maps use TMX/XML, many game asset tools export XML).
4. **No INI**: Simple key=value format used by some legacy tools.
5. **No validation/schema**: No way to validate decoded data against a schema (expected keys, types, ranges).
6. **No streaming decode**: Can't decode large files incrementally. Must load entire string first.

## Structural Issues

- **Clean separation from filesystem**: Correct. Serial handles format, filesystem handles I/O. This is good architecture.
- **TOML overlap with engine config**: The engine's `Config::load_from_conf_lua()` parses TOML internally. Serial provides TOML for game scripts. No conflict — different consumers.
- **Well-scoped**: Three formats, pure functions, no state. This is one of the cleanest modules.
- **No Tier 1 dependencies**: Correct as a leaf-like core module.

## Suggestions

1. **Add MessagePack**: `luna.serial.encodeMsgPack(tbl)` / `luna.serial.decodeMsgPack(str)` — binary-compact serialization. High value for network payloads and save data.
2. **Add XML decode (read-only)**: `luna.serial.decodeXml(str)` — parse XML into Lua tables. Needed for Tiled TMX import and third-party data. Encoding XML is less important.
3. **Add schema validation**: `luna.serial.validate(tbl, schema)` — check that a decoded table matches expected structure. Useful for save file migration and network protocol validation.
4. **Consider `encode`/`decode` with format parameter**: Instead of format-specific functions, offer `luna.serial.encode(tbl, "json")` / `luna.serial.decode(str, "json")`. Makes it easy to switch formats.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Bevy |
|---|---|---|---|---|
| JSON | ✅ | ❌ (plugin) | ✅ | ✅ (serde) |
| TOML | ✅ | ❌ | ❌ | ✅ (serde) |
| CSV | ✅ | ❌ | ❌ | ❌ |
| MessagePack | ❌ | ❌ | ❌ | ✅ (serde) |
| XML | ❌ | ❌ | ✅ | ✅ (serde) |
| Schema validation | ❌ | ❌ | ❌ | ✅ (reflect) |

Luna2D's built-in serial module with 3 formats is good. Adding MessagePack and XML read would cover nearly all game development serialization needs.

## Priority

**MEDIUM** — MessagePack is the highest-value addition (enables compact save data and network packets). XML decode enables Tiled import and external tool interop. The module is already well-designed and functional.
