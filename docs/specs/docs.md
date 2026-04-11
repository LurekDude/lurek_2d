# `docs` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Edge/Integration |
| **Status** | Implemented |
| **Lua API** | `lurek.docs` |
| **Source** | `src/docs/` |
| **Rust Tests** | tests/rust/unit/docs_tests.rs |
| **Lua Tests** | tests/lua/unit/test_docs.lua |
| **Architecture** | `docs/architecture/engine-architecture.md § Edge / Integration` |

---

## Summary

The docs module provides runtime documentation and schema data structures for the lurek.* API surface. It exists so the engine, VS Code extension, documentation generators, and Lua-side tooling can work from a structured catalog of API entries, quality metrics, and lightweight validation rules instead of relying only on free-form markdown.

At the center of the module is DocEntry metadata collected into a Catalog, along with reporting helpers that measure completeness and quality. The schema layer complements that by validating Lua data against explicit field rules, which makes the module useful for config, manifest, and documentation-related tooling as well as reflection.

This module does not parse Rust source files directly and it does not replace the generated docs pipeline under tools and docs/. It provides the runtime-facing structures and export helpers that other systems can populate, query, validate, and serialize.

**Scope boundary**: This module currently acts as a mostly self-contained part of the Edge/Integration layer. Cross-module behavior should remain anchored to the top-level source files and Lua bindings listed below.

---

## Architecture

```
lurek.docs.* (Lua API — src/lua_api/docs_api.rs)
    |
    v
src/docs/mod.rs
    |- catalog.rs - catalog
    |- entry.rs - entry
    |- export.rs - export
    |- report.rs - report
    |- schema.rs - schema
```

---

## Source Files

| File | Purpose |
|------|---------|
| `catalog.rs` | Defines Catalog, the in-memory collection of DocEntry values. It is the lookup and search layer for module-based queries, kind filtering, and direct entry retrieval. |
| `entry.rs` | Defines DocEntry, ParamInfo, and ReturnInfo. This file owns the shape of one documented API item and the metadata needed to describe its parameters and return values. |
| `export.rs` | Converts catalogs into editor-facing export formats such as completion, hover, and signature payloads. This file is the bridge from internal doc metadata to downstream tooling output. |
| `mod.rs` | Module root that re-exports documentation, reporting, schema, and export helpers. It gives the rest of the codebase one place to import the runtime docs surface. |
| `report.rs` | Defines ValidationReport, QualityReport, and the scoring helpers that evaluate doc completeness. This is where documentation metadata becomes measurable quality data. |
| `schema.rs` | Defines Schema, FieldRule, FieldType, SchemaError, and SchemaResult for runtime validation of structured Lua data. It is the module boundary between reflective documentation metadata and enforceable data rules. |

---

## Submodules

### `docs::catalog`

Defines Catalog, the in-memory collection of DocEntry values. It is the lookup and search layer for module-based queries, kind filtering, and direct entry retrieval.

- **`Catalog`** (struct): In-memory registry of all documented Lurek2D API entries.

### `docs::entry`

Defines DocEntry, ParamInfo, and ReturnInfo. This file owns the shape of one documented API item and the metadata needed to describe its parameters and return values.

- **`ParamInfo`** (struct): Metadata about a single parameter in an API function.
- **`ReturnInfo`** (struct): Metadata about a single return value.
- **`DocEntry`** (struct): A single documented API entry (function, method, value, or type).

### `docs::export`

Converts catalogs into editor-facing export formats such as completion, hover, and signature payloads. This file is the bridge from internal doc metadata to downstream tooling output.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `docs::report`

Defines ValidationReport, QualityReport, and the scoring helpers that evaluate doc completeness. This is where documentation metadata becomes measurable quality data.

- **`ValidationReport`** (struct): A report comparing a known API surface against catalog coverage.
- **`QualityReport`** (struct): A quality report computed from all entries in a catalog.

### `docs::schema`

Defines Schema, FieldRule, FieldType, SchemaError, and SchemaResult for runtime validation of structured Lua data. It is the module boundary between reflective documentation metadata and enforceable data rules.

- **`FieldType`** (enum): Accepted type for a schema field.
- **`FieldRule`** (struct): Validation rule for a single schema field.
- **`SchemaError`** (struct): A single validation failure.
- **`SchemaResult`** (struct): Result returned by [`Schema::validate_pairs`].
- **`Schema`** (struct): A named collection of [`FieldRule`]s that can validate Lua table data.

---

## Key Types

### Public Types

#### `DocEntry`

Canonical description of one documented API item, including identity, module, kind, prose, parameters, returns, examples, and metadata.

#### `ParamInfo`

Structured parameter metadata attached to a DocEntry.

#### `ReturnInfo`

Structured return-value metadata attached to a DocEntry.

#### `Catalog`

In-memory store for DocEntry values with search and filtering helpers.

#### `ValidationReport`

Comparison result between the catalog and some observed or expected API surface.

#### `QualityReport`

Aggregate scoring output for doc quality at entry and module level.

#### `Schema`

Named set of validation rules for structured Lua-side data.

#### `FieldRule and FieldType`

The rule and type vocabulary used by Schema.

---

## Lua API

Exposed under `lurek.docs.*` by `src/lua_api/docs_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.docs.scan` | Scan the lurek.* namespace to build an API catalog from live bindings. |
| `lurek.docs.scanModule` | Scan a single module's bindings. |
| `lurek.docs.loadToml` | Load a TOML doc file into an ApiCatalog. |
| `lurek.docs.loadAll` | Load all .toml files in a directory and merge into a single ApiCatalog. |
| `lurek.docs.describe` | Inject or update a description for a named API entry. |
| `lurek.docs.setParamInfo` | Set the parameter metadata for a catalog entry. |
| `lurek.docs.setReturnInfo` | Set the return type metadata for a catalog entry. |
| `lurek.docs.getCatalog` | Return the current internal catalog as an ApiCatalog userdata. |
| `lurek.docs.resetCatalog` | Clear all entries from the internal catalog. |
| `lurek.docs.validate` | Validate catalog completeness against the live lurek.* bindings. |
| `lurek.docs.validateModule` | Validate a single module against the live lurek.<module>.* bindings. |
| `lurek.docs.checkStaleness` | Compare catalog entries against source files in a directory for staleness. |
| `lurek.docs.quality` | Calculate quality metrics for a catalog or the internal catalog. |
| `lurek.docs.qualityModule` | Calculate quality metrics for a single module. |
| `lurek.docs.coverage` | Return (documented_count, total_live_count) coverage tuple. |
| `lurek.docs.coverageModule` | Return (documented_count, total_live_count) for a single module. |
| `lurek.docs.exportCompletions` | Export VS Code IntelliSense completions JSON to a file. |
| `lurek.docs.exportHover` | Export VS Code hover JSON to a file. |
| `lurek.docs.exportSignatures` | Export VS Code signature-help JSON to a file. |
| `lurek.docs.exportAll` | Export completions.json, hover.json, and signatures.json to a directory. |
| `lurek.docs.exportMarkdown` | Export a Markdown API reference file. |
| `lurek.docs.exportCheatsheet` | Export a one-line-per-function plain-text cheatsheet. |
| `lurek.docs.schema` | Creates a Schema validator from a rules table. |
| `lurek.docs.reflectLive` | Walks the live lurek.* Lua table and returns a structured reflection of all |
| `lurek.docs.reflectTable` | Reflects any Lua table, returning a structure describing its keys, |

### `ApiCatalog` Methods

| Method | Description |
|--------|-------------|
| `apicatalog:getModules(...)` | Returns a sorted list of module names present in the catalog. |
| `apicatalog:getEntries(...)` | Returns all entries, optionally filtered to a single module. |
| `apicatalog:getEntry(...)` | Returns a single entry by qualified name, or nil. |
| `apicatalog:getTypes(...)` | Returns the names of all entries with kind "type" in the given module. |
| `apicatalog:getTypeMethods(...)` | Returns entries that are methods of the given type qualified name. |
| `apicatalog:entryCount(...)` | Returns the number of entries, optionally scoped to a module. |
| `apicatalog:merge(...)` | Returns a new catalog that is the union of this and another catalog, with other overriding duplicates. |
| `apicatalog:filter(...)` | Returns a new catalog containing only entries for which predicate returns true. |
| `apicatalog:search(...)` | Returns a table of entries whose name, qualified name, or description contains query. |
| `apicatalog:toTable(...)` | Converts the catalog to a plain Lua table array. |
| `apicatalog:toJSON(...)` | Serialises the catalog to a pretty-printed JSON string. |

### `DocEntry` Methods

| Method | Description |
|--------|-------------|
| `docentry:getName(...)` | Returns the name. |
| `docentry:getQualifiedName(...)` | Returns the qualified name. |
| `docentry:getModule(...)` | Returns the module. |
| `docentry:getKind(...)` | Returns the kind. |
| `docentry:getDescription(...)` | Returns the description. |
| `docentry:getParameters(...)` | Returns the parameters as a table of `{name, type, description, optional, default?}` records. |
| `docentry:getReturns(...)` | Returns the return values as a table of `{type, description}` records. |
| `docentry:getExample(...)` | Returns the example snippet, or nil. |
| `docentry:getSince(...)` | Returns the since version string, or nil. |
| `docentry:getDeprecated(...)` | Returns the deprecation message, or nil. |
| `docentry:getScore(...)` | Returns the quality score in [0,1]. |
| `docentry:hasDescription(...)` | Returns true when the entry has a non-empty description. |
| `docentry:hasParameters(...)` | Returns true when the entry has at least one parameter. |
| `docentry:hasReturnType(...)` | Returns true when the entry declares at least one return type. |
| `docentry:hasExample(...)` | Returns true when the entry has an example snippet. |

### `QualityReport` Methods

| Method | Description |
|--------|-------------|
| `qualityreport:getOverallScore(...)` | Returns the overall quality score in [0,1]. |
| `qualityreport:getGrade(...)` | Returns the letter grade for the overall score. |
| `qualityreport:getModuleScores(...)` | Returns a table mapping module name to its average quality score. |
| `qualityreport:getWorst(...)` | Returns up to count entries with the lowest quality scores. |
| `qualityreport:getBest(...)` | Returns up to count entries with the highest quality scores. |
| `qualityreport:getByGrade(...)` | Returns entries whose grade exactly matches the given letter grade. |
| `qualityreport:getSummary(...)` | Returns a multi-line human-readable summary of quality by module. |
| `qualityreport:toTable(...)` | Converts the quality report to a plain Lua table. |
| `qualityreport:toJSON(...)` | Serialises the quality report to a pretty-printed JSON string. |

### `Schema` Methods

| Method | Description |
|--------|-------------|
| `schema:validate(...)` | Validates a Lua table against the schema. |
| `schema:check(...)` | Returns true when the data passes all schema rules. |
| `schema:assert(...)` | Validates data and throws a Lua error on failure with all error messages joined. |
| `schema:getName(...)` | Returns the schema name. |
| `schema:getFields(...)` | Returns a table of declared field names. |

### `ValidationReport` Methods

| Method | Description |
|--------|-------------|
| `validationreport:isValid(...)` | Returns true when the report has no missing entries. |
| `validationreport:getMissing(...)` | Returns the list of qualified names present in the live API but missing from the catalog. |
| `validationreport:getPhantom(...)` | Returns the list of qualified names in the catalog that are not present in the live API. |
| `validationreport:getIncomplete(...)` | Returns the list of qualified names whose catalog entry is incomplete. |
| `validationreport:missingCount(...)` | Returns the count of missing entries. |
| `validationreport:phantomCount(...)` | Returns the count of phantom entries. |
| `validationreport:incompleteCount(...)` | Returns the count of incomplete entries. |
| `validationreport:getSummary(...)` | Returns a single-line summary of the validation results. |
| `validationreport:toTable(...)` | Converts the report to a plain Lua table. |
| `validationreport:toJSON(...)` | Serialises the report to a pretty-printed JSON string. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.docs.
if lurek.docs then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 10 |
| `enum` | 1 |
| `fn` (Lua API) | 75 |
| **Total** | **86** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| — | No top-level `crate::<module>` imports were detected in this module's source files. | Keep the source files as the primary dependency reference. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/docs/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
