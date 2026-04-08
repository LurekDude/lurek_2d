# `docs` — Full Specification

| Property         | Value                                                  |
|------------------|--------------------------------------------------------|
| **Tier**         | Tier 1 — Core Engine Subsystems                        |
| **Status**       | Implemented — Full                                     |
| **Lua API**      | `luna.docs`                                            |
| **Source**       | `src/docs/`                                            |
| **Rust Tests**   | —                                                      |
| **Lua Tests**    | `tests/lua/unit/test_docs.lua`                         |
| **Architecture** | —                                                      |

## Summary

The `docs` module provides a structured API documentation catalog for the `luna.*` Lua API surface. It is the data layer that backs the VS Code extension IntelliSense, the MCP server tool descriptions, and the `tools/docs/` generators.

The module defines three pure-Rust data types: `DocEntry` (one entry per API function, method, value, or type), `ParamInfo` (one record per parameter), and `ReturnInfo` (one record per return value). An in-memory `Catalog` aggregates `DocEntry` values and provides sorted module listing, qualified-name lookup, keyword search, and kind filtering. `ValidationReport` compares a catalog against the live `luna.*` bindings discovered at runtime to surface missing entries, phantom entries (in catalog but not live), and incomplete entries. `QualityReport` scores every entry against five criteria (description, qualified name, params/returns, example, since version) and reports per-module averages.

The Lua API at `luna.docs.*` is the primary consumption point. It can scan live bindings via reflection (`scan`, `scanModule`), load entries from TOML doc files (`loadToml`, `loadAll`), mutate an internal catalog (`describe`, `setParamInfo`, `setReturnInfo`), run validation (`validate`, `validateModule`), compute coverage ratios and quality metrics, and export editor-ready JSON files for VS Code IntelliSense (`exportCompletions`, `exportHover`, `exportSignatures`, `exportAll`) or Markdown/text formats (`exportMarkdown`, `exportCheatsheet`).

This module intentionally does **not** provide:
- Persistent doc storage — entries exist only in-memory until exported
- Source parsing of Rust `///` comments — that is a Python tool responsibility
- A registry of live entry counts — `scan()` counts at call time by traversing `luna.*`

## Architecture

```
src/docs/
├── mod.rs         Re-exports DocEntry, ParamInfo, ReturnInfo, Catalog,
│                  ValidationReport, QualityReport, quality_score, quality_grade
├── entry.rs       DocEntry, ParamInfo, ReturnInfo — plain data structs, no mlua
├── catalog.rs     Catalog — in-memory Vec<DocEntry> with search/filter methods
└── report.rs      ValidationReport, QualityReport, quality_score(), quality_grade()

src/lua_api/
└── docs_api.rs    Lua UserData: DocEntry, ApiCatalog, ValidationReport, QualityReport
                   Top-level: scan, scanModule, loadToml, loadAll, describe,
                   setParamInfo, setReturnInfo, getCatalog, resetCatalog,
                   validate, validateModule, checkStaleness, quality, qualityModule,
                   coverage, coverageModule, exportCompletions, exportHover,
                   exportSignatures, exportAll, exportMarkdown, exportCheatsheet

Data flow:
  Lua script → luna.docs.scan()      → ApiCatalog userdata
  Lua script → luna.docs.loadToml()  → ApiCatalog userdata
  ApiCatalog → luna.docs.validate()  → ValidationReport userdata
  ApiCatalog → luna.docs.quality()   → QualityReport userdata
  ApiCatalog → luna.docs.exportAll() → completions.json + hover.json + signatures.json
```

## Source Files

| File           | Purpose                                                                          |
|----------------|----------------------------------------------------------------------------------|
| `entry.rs`     | `DocEntry`, `ParamInfo`, `ReturnInfo` — data types for a single API entry        |
| `catalog.rs`   | `Catalog` — in-memory registry with search, filter, and query helpers            |
| `report.rs`    | `ValidationReport`, `QualityReport`, `quality_score()`, `quality_grade()`        |
| `mod.rs`       | Re-exports all public types                                                       |

## Submodules

### `docs::entry`

- `ParamInfo`: `name: String`, `type_name: String`, `description: String`, `optional: bool`, `default: Option<String>`
- `ReturnInfo`: `type_name: String`, `description: String`
- `DocEntry`: See Key Types below.

### `docs::catalog`

- `Catalog`: `entries: Vec<DocEntry>`
- Methods: `new()`, `add(entry)`, `modules()→Vec<&str>`, `all_entries()→&[DocEntry]`, `entries_for_module(module)→Vec<&DocEntry>`, `get_entry(qualified_name)→Option<&DocEntry>`, `entry_count()→usize`, `search(query)→Vec<&DocEntry>`, `filter_by_kind(kind)→Vec<&DocEntry>`, `clear()`

### `docs::report`

- `ValidationReport`: `missing: Vec<String>`, `phantom: Vec<String>`, `incomplete: Vec<String>`
- `QualityReport`: `entries: Vec<DocEntry>`, `module_scores: HashMap<String, f64>`, `overall_score: f64`
- Free functions: `quality_score(entry)→f64`, `quality_grade(score)→&'static str`

## Key Types

### Structs

#### `docs::entry::DocEntry`
A single documented API entry. Fields:
- `name: String` — short unqualified name (e.g., `"play"`)
- `qualified_name: String` — fully qualified (e.g., `"luna.audio.play"`)
- `module: String` — owning module (e.g., `"audio"`)
- `kind: String` — one of `"function"`, `"method"`, `"value"`, `"type"`
- `description: String` — one-sentence or short-paragraph description
- `parameters: Vec<ParamInfo>` — ordered parameter metadata
- `returns: Vec<ReturnInfo>` — ordered return value metadata
- `example: Option<String>` — Lua usage snippet
- `since: Option<String>` — version string when introduced (e.g., `"0.4.0"`)
- `deprecated: Option<String>` — migration advice if deprecated
- `tags: Vec<String>` — free-form filter tags (e.g., `["async", "render"]`)
- `extra: HashMap<String, String>` — tool-specific extension data
- `DocEntry::new(name, module, kind)→Self` — builds with auto-populated `qualified_name`
- `is_complete()→bool` — `true` when description is non-empty and (for non-value kinds) params or returns are present
- `missing_fields()→Vec<&'static str>` — names of empty required fields

#### `docs::entry::ParamInfo`
Metadata for a single parameter: `name`, `type_name`, `description`, `optional`, `default`.

#### `docs::entry::ReturnInfo`
Metadata for a single return value: `type_name`, `description`.

#### `docs::catalog::Catalog`
In-memory `Vec<DocEntry>` registry. `search(query)` matches case-insensitively against `name` and `description`. `modules()` returns a sorted, deduplicated list of module names.

#### `docs::report::ValidationReport`
Comparison result. `missing` — live API names absent from catalog. `phantom` — catalog names absent from live API. `incomplete` — entries where `description` is empty or (for non-value kinds) both `parameters` and `returns` are empty. `is_clean()→bool`, `total_issues()→usize`.

#### `docs::report::QualityReport`
Quality snapshot. `compute(catalog)→Self` scores every entry via `quality_score()` and aggregates per-module averages. `overall_score` is the weighted mean across all entries.

### Enums

No public enums.

## Lua API

The Lua API is registered in `src/lua_api/docs_api.rs` under `luna.docs.*`. All catalog and report values cross the Lua boundary as opaque UserData objects with named methods.

### Top-Level Functions

| Function | Signature | Description |
|---|---|---|
| `luna.docs.scan(opts?)` | `→ ApiCatalog` | Scan all live `luna.*` bindings by table reflection |
| `luna.docs.scanModule(module_name)` | `→ ApiCatalog` | Scan one module's bindings |
| `luna.docs.loadToml(path)` | `→ ApiCatalog` | Load a TOML doc file via `luna.data.parseToml` |
| `luna.docs.loadAll(directory)` | `→ ApiCatalog` | Load all `.toml` files in a directory and merge |
| `luna.docs.describe(qualified_name, description)` | — | Inject or update a description in the internal catalog |
| `luna.docs.setParamInfo(qualified_name, params)` | — | Set parameter metadata for an entry (`{name,type,description,optional,default?}[]`) |
| `luna.docs.setReturnInfo(qualified_name, returns)` | — | Set return metadata for an entry (`{type,description}[]`) |
| `luna.docs.getCatalog()` | `→ ApiCatalog` | Return the internal catalog as an `ApiCatalog` |
| `luna.docs.resetCatalog()` | — | Clear all entries from the internal catalog |
| `luna.docs.validate(catalog?)` | `→ ValidationReport` | Validate catalog against live `luna.*` bindings |
| `luna.docs.validateModule(module_name, catalog?)` | `→ ValidationReport` | Validate one module |
| `luna.docs.checkStaleness(catalog, source_dir)` | `→ table` | Check file-level staleness; returns `{stale, current, missing}` |
| `luna.docs.quality(catalog?)` | `→ QualityReport` | Compute quality metrics for the catalog |
| `luna.docs.qualityModule(module_name, catalog?)` | `→ QualityReport` | Quality metrics for one module |
| `luna.docs.coverage(catalog?)` | `→ (integer, integer)` | `(documented_count, total_live_count)` |
| `luna.docs.coverageModule(module_name, catalog?)` | `→ (integer, integer)` | Coverage for one module |
| `luna.docs.exportCompletions(catalog, path)` | — | Write VS Code completion items JSON |
| `luna.docs.exportHover(catalog, path)` | — | Write VS Code hover JSON keyed by qualified name |
| `luna.docs.exportSignatures(catalog, path)` | — | Write VS Code signature-help JSON |
| `luna.docs.exportAll(catalog, output_dir)` | — | Write `completions.json`, `hover.json`, `signatures.json` |
| `luna.docs.exportMarkdown(catalog, path)` | — | Write a Markdown API reference file |
| `luna.docs.exportCheatsheet(catalog, path)` | — | Write a one-line-per-function plain-text cheatsheet |

### `ApiCatalog` Methods

| Method | Signature | Description |
|---|---|---|
| `getModules()` | `→ table` | Sorted list of module names |
| `getEntries(module?)` | `→ table` | All entries, optionally filtered by module |
| `getEntry(qualified_name)` | `→ DocEntry?` | Lookup by fully qualified name |
| `getTypes(module_name)` | `→ table` | Names of entries with `kind == "type"` in a module |
| `getTypeMethods(qualified_name)` | `→ table` | Methods belonging to a type |
| `entryCount(module?)` | `→ integer` | Total entry count, optionally scoped |
| `merge(other)` | `→ ApiCatalog` | Union with `other` overriding duplicates |
| `filter(predicate)` | `→ ApiCatalog` | Filtered copy using a Lua predicate function |
| `search(query)` | `→ table` | Entries matching query in name, qualified name, or description |
| `toTable()` | `→ table` | Flat Lua-table representation |
| `toJSON()` | `→ string` | Pretty-printed JSON |

### `DocEntry` Methods

| Method | Signature | Description |
|---|---|---|
| `getName()` | `→ string` | Short unqualified name |
| `getQualifiedName()` | `→ string` | Fully qualified name |
| `getModule()` | `→ string` | Owning module |
| `getKind()` | `→ string` | `"function"`, `"method"`, `"value"`, or `"type"` |
| `getDescription()` | `→ string` | Human-readable description |
| `getParameters()` | `→ table` | `{name,type,description,optional,default?}` records |
| `getReturns()` | `→ table` | `{type,description}` records |
| `getExample()` | `→ string?` | Usage snippet or nil |
| `getSince()` | `→ string?` | Version string or nil |
| `getDeprecated()` | `→ string?` | Deprecation message or nil |
| `getScore()` | `→ number` | Quality score in `[0, 1]` |
| `hasDescription()` | `→ boolean` | True when description is non-empty |
| `hasParameters()` | `→ boolean` | True when at least one parameter is present |
| `hasReturnType()` | `→ boolean` | True when at least one return type is present |
| `hasExample()` | `→ boolean` | True when an example snippet is present |

### `ValidationReport` Methods

| Method | Signature | Description |
|---|---|---|
| `isValid()` | `→ boolean` | True when `missing` list is empty |
| `getMissing()` | `→ table` | Live API names absent from catalog |
| `getPhantom()` | `→ table` | Catalog names absent from live API |
| `getIncomplete()` | `→ table` | Catalog entries that are incomplete |
| `missingCount()` | `→ integer` | Count of missing entries |
| `phantomCount()` | `→ integer` | Count of phantom entries |
| `incompleteCount()` | `→ integer` | Count of incomplete entries |
| `getSummary()` | `→ string` | One-line summary |
| `toTable()` | `→ table` | Lua-table representation with `missing`, `phantom`, `incomplete` keys |
| `toJSON()` | `→ string` | Pretty-printed JSON |

### `QualityReport` Methods

| Method | Signature | Description |
|---|---|---|
| `getOverallScore()` | `→ number` | Weighted average quality score in `[0, 1]` |
| `getGrade()` | `→ string` | Letter grade: A ≥ 0.9, B ≥ 0.7, C ≥ 0.5, D ≥ 0.3, F < 0.3 |
| `getModuleScores()` | `→ table` | Module name → average score mapping |
| `getWorst(count?)` | `→ table` | Up to `count` entries with the lowest scores |
| `getBest(count?)` | `→ table` | Up to `count` entries with the highest scores |
| `getByGrade(grade)` | `→ table` | Entries matching a specific letter grade |
| `getSummary()` | `→ string` | Multi-line human-readable quality summary |
| `toTable()` | `→ table` | Lua-table with `overallScore`, `grade`, `moduleScores` |
| `toJSON()` | `→ string` | Pretty-printed JSON |

## Lua Examples

```lua
-- === Scan live bindings and check coverage ===
local catalog = luna.docs.scan()
local documented, total = luna.docs.coverage(catalog)
print(string.format("Coverage: %d / %d (%.0f%%)", documented, total, documented/total*100))

-- === Load TOML docs and validate ===
local toml_cat = luna.docs.loadAll("docs/api_catalog/")
local report = luna.docs.validate(toml_cat)
if not report:isValid() then
    print("Missing:", report:missingCount())
    for _, name in ipairs(report:getMissing()) do
        print("  MISSING:", name)
    end
end

-- === Quality check ===
local quality = luna.docs.quality(toml_cat)
print("Overall grade:", quality:getGrade())
print(quality:getSummary())

-- === Export VS Code IntelliSense JSON ===
local cat = luna.docs.scan()
luna.docs.exportAll(cat, "vscode-extension/data/")

-- === Manually describe an entry ===
luna.docs.describe("luna.audio.play", "Play a loaded audio source by key.")
luna.docs.setParamInfo("luna.audio.play", {
    { name = "key",    type = "string",  description = "Audio source key." },
    { name = "volume", type = "number?", description = "Volume 0–1.", optional = true },
})

-- === Inspect one entry ===
local cat = luna.docs.scan()
local entry = cat:getEntry("luna.timer.after")
if entry then
    print(entry:getQualifiedName(), entry:getScore())
end
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 5     |
| `enum`    | 0     |
| `fn`      | 22+   |
| **Total** | **27+** |

## References

| Module       | Relationship | Notes                                                           |
|--------------|--------------|-----------------------------------------------------------------|
| `engine`     | —            | `docs_api.rs` receives no `SharedState`; uses only Lua globals  |
| `data`       | Uses (Lua)   | `loadToml` delegates to `luna.data.parseToml` at runtime        |
| `lua_api`    | Imported by  | `docs_api.rs` registers the `luna.docs.*` surface               |
| `vscode-extension` | Consumer | Consumes `exportAll` JSON for completions, hover, and signatures |

## Notes

- `scan()` and `validate()` work by traversing the `luna.*` Lua table at call time — they reflect the current registered bindings, not a compile-time list.
- `loadToml` requires `luna.data` to be registered (it calls `luna.data.parseToml` internally). Do not call it before the Lua VM is fully initialised.
- The internal catalog (used by `describe`, `setParamInfo`, `setReturnInfo`, `getCatalog`, `resetCatalog`) is per-VM state stored in a `Rc<RefCell<DocsState>>`. It is independent of exported `ApiCatalog` userdata objects.
- `quality_score` checks five conditions. A `"value"` kind skips the params/returns check (only 4 conditions apply), so a fully described value entry scores 4/4 = 1.0 even without parameters.
- `exportAll` creates the output directory with `fs::create_dir_all` — it is safe to target a non-existent path.
