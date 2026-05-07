# docs

## General Info

- Module group: `Edge/Integration`
- Source path: `src/docs/`
- Lua API path(s): `src/lua_api/docs_api.rs`
- Primary Lua namespace: `lurek.docs`
- Rust test path(s): tests/rust/unit/docs_tests.rs
- Lua test path(s): tests/lua/unit/test_docs.lua

## Summary

The `docs` module is Lurek2D's in-engine API documentation catalog and data-validation schema system — a Foundations tier module with no rendering, audio, or physics dependencies. It serves two distinct but closely related purposes: providing a structured, queryable database of `lurek.*` API metadata at runtime for IDE tooling and Lua introspection, and offering a lightweight schema validation mechanism for arbitrary structured game data such as config files, save data, and mod manifests.

**Documentation catalog.** The catalog side is built around three core types. `DocEntry` is the canonical description of one documented API item — function, method, value, or type — carrying its fully-qualified name, module name, kind tag (`function`/`method`/`value`/`type`), a human-readable description, ordered `ParamInfo` parameter records (name, type hint, description), and `ReturnInfo` return descriptors. A `Catalog` is an in-memory collection of `DocEntry` records with query methods: `add(entry)`, `modules()` (sorted unique list), `all_entries()`, `entries_for_module(name)`, `get_entry(qualified_name)`, `search(query)` (case-insensitive substring over name and description), `filter_by_kind(kind)`, `clear()`.

**Population and use.** The catalog is populated at engine boot by iterating over the registered `lurek.*` API surface and constructing `DocEntry` records from the Rust binding metadata. It serves three downstream consumers: the VS Code extension's IntelliSense completions (via `export_completions`), hover information (via `export_hover`), and signature help (via `export_signatures`); the debug bridge's real-time hover queries over the TCP protocol; and the `lurek.docs` Lua API that lets game code query the API at runtime (useful for in-game help screens and mod-documentation generators).

**Quality reporting.** `QualityReport` computes a completeness score for each module's documentation: it identifies entries with missing prose descriptions, missing parameter type hints, missing return descriptions, and empty example lists, and produces a per-module quality percentage. `ValidationReport` compares the catalog against an expected API surface and lists phantom entries (in catalog, not in source) and missing entries (in source, not in catalog). These are used by `tools/audit/docstring_audit.py` and `tools/audit/lua_api_test_coverage.py`.

**Export formats.** `export.rs` converts the catalog into editor-facing payloads written to JSON files:
- `export_completions(catalog, path)` → VS Code completion item array.
- `export_hover(catalog, path)` → map of qualified name → hover markdown.
- `export_signatures(catalog, path)` → map of qualified name → signature help.
These outputs are consumed by the VS Code extension at extension activation time.

**Schema validation.** `schema.rs` provides a lightweight data contract system independent of the documentation catalog. A `Schema` is a map of field names to `FieldRule` entries; each rule specifies: required vs optional presence, a `FieldType` constraint (Number, Text, Bool, Table, Any), and an optional default value. `schema.validate_pairs(pairs)` checks a sequence of key-value pairs and returns a `SchemaResult` listing any `SchemaError` entries (missing required fields, type mismatches). Game code uses this for validating plugin manifests, `conf.lua` sections, and structured save-data before trusting values deeper in the engine.

**Lua surface.** `lurek.docs.catalog()` returns a snapshot of the runtime catalog as a Lua table. `lurek.docs.query(name)` looks up a single entry. `lurek.docs.search(query)` returns matching entries. `lurek.docs.modules()` lists module names. Schema: `lurek.docs.newSchema(rules)` → `Schema` userdata; `schema:validate(table)` → `{ok, errors}`.

**Scope boundary.** Foundations tier. No engine module imports. Lua bridge in `src/lua_api/docs_api.rs`.

## Files

- `catalog.rs`: Defines Catalog, the in-memory collection of DocEntry values. It is the lookup and search layer for module-based queries, kind filtering, and direct entry retrieval.
- `entry.rs`: Defines DocEntry, ParamInfo, and ReturnInfo. This file owns the shape of one documented API item and the metadata needed to describe its parameters and return values.
- `export.rs`: Converts catalogs into editor-facing export formats such as completion, hover, and signature payloads. This file is the bridge from internal doc metadata to downstream tooling output.
- `mod.rs`: Module root that re-exports documentation, reporting, schema, and export helpers. It gives the rest of the codebase one place to import the runtime docs surface.
- `report.rs`: Defines ValidationReport, QualityReport, and the scoring helpers that evaluate doc completeness. This is where documentation metadata becomes measurable quality data.
- `schema.rs`: Defines Schema, FieldRule, FieldType, SchemaError, and SchemaResult for runtime validation of structured Lua data. It is the module boundary between reflective documentation metadata and enforceable data rules.

## Types

- `Catalog` (`struct`, `catalog.rs`): In-memory store for DocEntry values with search and filtering helpers. It is the first place to inspect when tools cannot find entries they expect.
- `ParamInfo` (`struct`, `entry.rs`): Structured parameter metadata attached to a DocEntry. It keeps function signatures machine-readable instead of burying argument details in prose.
- `ReturnInfo` (`struct`, `entry.rs`): Structured return-value metadata attached to a DocEntry. It exists for the same reason as ParamInfo, but for outputs.
- `DocEntry` (`struct`, `entry.rs`): Canonical description of one documented API item, including identity, module, kind, prose, parameters, returns, examples, and metadata. It is the most important type in the module because nearly every other piece of functionality builds on it.
- `ValidationReport` (`struct`, `report.rs`): Comparison result between the catalog and some observed or expected API surface. It is useful when auditing missing, phantom, or incomplete docs.
- `QualityReport` (`struct`, `report.rs`): Aggregate scoring output for doc quality at entry and module level. It exists so tooling can quantify documentation quality instead of only reporting raw missing fields.
- `FieldType` (`enum`, `schema.rs`): Accepted type for a schema field.
- `FieldRule` (`struct`, `schema.rs`): Validation rule for a single schema field.
- `SchemaError` (`struct`, `schema.rs`): A single validation failure.
- `SchemaResult` (`struct`, `schema.rs`): Result returned by [`Schema::validate_pairs`].
- `Schema` (`struct`, `schema.rs`): Named set of validation rules for structured Lua-side data. It gives the module a second role beyond pure documentation: validating data contracts.

## Functions

- `Catalog::new` (`catalog.rs`): Creates an empty catalog.
- `Catalog::from_entries` (`catalog.rs`): Creates a catalog pre-populated from a slice of entries.
- `Catalog::add` (`catalog.rs`): Inserts a doc entry into the catalog.
- `Catalog::modules` (`catalog.rs`): Returns a sorted, deduplicated list of module names present in the catalog.
- `Catalog::all_entries` (`catalog.rs`): Returns a slice over all entries in insertion order.
- `Catalog::entries_for_module` (`catalog.rs`): Returns all entries belonging to the given module.
- `Catalog::get_entry` (`catalog.rs`): Looks up an entry by its fully qualified name (e.g.
- `Catalog::entry_count` (`catalog.rs`): Returns the total number of entries in the catalog.
- `Catalog::search` (`catalog.rs`): Returns entries whose name or description contains `query` (case-insensitive).
- `Catalog::filter_by_kind` (`catalog.rs`): Returns entries of the given kind (e.g.
- `Catalog::clear` (`catalog.rs`): Removes all entries from the catalog.
- `DocEntry::new` (`entry.rs`): Creates a minimal entry with the given name, module, and kind.
- `DocEntry::is_complete` (`entry.rs`): Returns `true` when the entry has enough information for documentation generation.
- `DocEntry::missing_fields` (`entry.rs`): Returns the names of fields that are missing or empty.
- `export_completions` (`export.rs`): Writes a VS Code completions JSON array to `path`.
- `export_hover` (`export.rs`): Writes a VS Code hover JSON map to `path`.
- `export_signatures` (`export.rs`): Writes a VS Code signature-help JSON map to `path`.
- `export_all` (`export.rs`): Writes `completions.json`, `hover.json`, and `signatures.json` to `output_dir`.
- `quality_score` (`report.rs`): Computes a quality score in `[0.0, 1.0]` for a single doc entry.
- `quality_grade` (`report.rs`): Converts a quality score into a letter grade.
- `ValidationReport::new` (`report.rs`): Creates an empty validation report.
- `ValidationReport::is_clean` (`report.rs`): Returns `true` when the report has no issues.
- `ValidationReport::total_issues` (`report.rs`): Returns the total count of issues across all categories.
- `QualityReport::compute` (`report.rs`): Computes quality scores for every entry in `catalog`.
- `QualityReport::module_grade` (`report.rs`): Returns the letter grade for the given module.
- `QualityReport::from_entries` (`report.rs`): Convenience constructor: builds a temporary [`Catalog`] from `entries` then calls [`Self::compute`].
- `FieldType::from_str` (`schema.rs`): Parses a type name string.
- `FieldType::as_str` (`schema.rs`): Returns the display name.
- `SchemaResult::pass` (`schema.rs`): Creates a passing result.
- `Schema::new` (`schema.rs`): Creates a new schema.
- `Schema::add_rule` (`schema.rs`): Adds a field rule.
- `Schema::validate_pairs` (`schema.rs`): Validates a set of `(field, value_type, value_str)` pairs.

## Lua API Reference

- Binding path(s): `src/lua_api/docs_api.rs`
- Namespace: `lurek.docs`

### Module Functions
- `lurek.docs.scan`: Scan the lurek.* namespace to build an API catalog from live bindings.
- `lurek.docs.scanModule`: Scan a single module's bindings.
- `lurek.docs.loadToml`: Load a TOML doc file into an ApiCatalog.
- `lurek.docs.loadAll`: Load all .toml files in a directory and merge into a single ApiCatalog.
- `lurek.docs.describe`: Inject or update a description for a named API entry.
- `lurek.docs.setParamInfo`: Set the parameter metadata for a catalog entry.
- `lurek.docs.setReturnInfo`: Set the return type metadata for a catalog entry.
- `lurek.docs.getCatalog`: Return the current internal catalog as an ApiCatalog userdata.
- `lurek.docs.resetCatalog`: Clear all entries from the internal catalog.
- `lurek.docs.validate`: Validate catalog completeness against the live lurek.* bindings.
- `lurek.docs.validateModule`: Validate a single module against the live lurek.<module>.* bindings.
- `lurek.docs.checkStaleness`: Compare catalog entries against source files in a directory for staleness.
- `lurek.docs.quality`: Calculate quality metrics for a catalog or the internal catalog.
- `lurek.docs.qualityModule`: Calculate quality metrics for a single module.
- `lurek.docs.coverage`: Return (documented_count, total_live_count) coverage tuple.
- `lurek.docs.coverageModule`: Return (documented_count, total_live_count) for a single module.
- `lurek.docs.exportCompletions`: Export VS Code IntelliSense completions JSON to a file.
- `lurek.docs.exportHover`: Export VS Code hover JSON to a file.
- `lurek.docs.exportSignatures`: Export VS Code signature-help JSON to a file.
- `lurek.docs.exportAll`: Export completions.json, hover.json, and signatures.json to a directory.
- `lurek.docs.exportMarkdown`: Export a Markdown API reference file.
- `lurek.docs.exportCheatsheet`: Export a one-line-per-function plain-text cheatsheet.
- `lurek.docs.schema`: Creates a schema validator from a rules table.
- `lurek.docs.reflectLive`: Walks the live lurek.* Lua table and returns a structured reflection table.
- `lurek.docs.reflectTable`: Reflects any Lua table and returns a structure describing its keys and value types.

### `LApiCatalog` Methods
- `LApiCatalog:getModules`: Returns a sorted list of module names present in the catalog.
- `LApiCatalog:getEntries`: Returns all entries, optionally filtered to a single module.
- `LApiCatalog:getEntry`: Returns a single entry by qualified name, or nil.
- `LApiCatalog:getTypes`: Returns the names of all entries with kind "type" in the given module.
- `LApiCatalog:getTypeMethods`: Returns entries that are methods of the given type qualified name.
- `LApiCatalog:entryCount`: Returns the number of entries, optionally scoped to a module.
- `LApiCatalog:merge`: Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
- `LApiCatalog:filter`: Returns a new catalog containing only entries for which predicate returns true.
- `LApiCatalog:search`: Returns a table of entries whose name, qualified name, or description contains query.
- `LApiCatalog:toTable`: Converts the catalog to a plain Lua table array.
- `LApiCatalog:toJSON`: Serialises the catalog to a pretty-printed JSON string.
- `LApiCatalog:type`: Returns the type name of this object.
- `LApiCatalog:typeOf`: Returns true if this object is of the given type.

### `LDocEntry` Methods
- `LDocEntry:getName`: Returns the symbol name for this documentation entry.
- `LDocEntry:getQualifiedName`: Returns the qualified name.
- `LDocEntry:getModule`: Returns the Lua module name this entry belongs to (e.g. `'lurek.math'`).
- `LDocEntry:getKind`: Returns the kind tag for this entry (e.g. `'function'`, `'method'`, `'class'`).
- `LDocEntry:getDescription`: Returns the human-readable description text for this documentation entry.
- `LDocEntry:getParameters`: Returns the parameters as a table of `{name, type, description, optional, default?}` records.
- `LDocEntry:getReturns`: Returns the return values as a table of `{type, description}` records.
- `LDocEntry:getExample`: Returns the example snippet, or nil.
- `LDocEntry:getSince`: Returns the since version string, or nil.
- `LDocEntry:getDeprecated`: Returns the deprecation message, or nil.
- `LDocEntry:getScore`: Returns the quality score in [0,1].
- `LDocEntry:hasDescription`: Returns true when the entry has a non-empty description.
- `LDocEntry:hasParameters`: Returns true when the entry has at least one parameter.
- `LDocEntry:hasReturnType`: Returns true when the entry declares at least one return type.
- `LDocEntry:hasExample`: Returns true when the entry has an example snippet.
- `LDocEntry:type`: Returns the type name of this object.
- `LDocEntry:typeOf`: Returns true if this object is of the given type.

### `LQualityReport` Methods
- `LQualityReport:getOverallScore`: Returns the overall quality score in [0,1].
- `LQualityReport:getGrade`: Returns the letter grade for the overall score.
- `LQualityReport:getModuleScores`: Returns a table mapping module name to its average quality score.
- `LQualityReport:getWorst`: Returns up to count entries with the lowest quality scores.
- `LQualityReport:getBest`: Returns up to count entries with the highest quality scores.
- `LQualityReport:getByGrade`: Returns entries whose grade exactly matches the given letter grade.
- `LQualityReport:getSummary`: Returns a multi-line human-readable summary of quality by module.
- `LQualityReport:toTable`: Converts the quality report to a plain Lua table.
- `LQualityReport:toJSON`: Serialises the quality report to a pretty-printed JSON string.
- `LQualityReport:type`: Returns the type name of this object.
- `LQualityReport:typeOf`: Returns true if this object is of the given type.

### `LSchema` Methods
- `LSchema:validate`: Validates a Lua table against the schema.
- `LSchema:check`: Returns true when the data passes all schema rules.
- `LSchema:assert`: Validates data and throws a Lua error on failure with all error messages joined.
- `LSchema:getName`: Returns the name identifier of this API schema group.
- `LSchema:getFields`: Returns a table of declared field names.
- `LSchema:type`: Returns the type name of this object.
- `LSchema:typeOf`: Returns true if this object is of the given type.

### `LValidationReport` Methods
- `LValidationReport:isValid`: Returns true when the report has no missing entries.
- `LValidationReport:getMissing`: Returns the list of qualified names present in the live API but missing from the catalog.
- `LValidationReport:getPhantom`: Returns the list of qualified names in the catalog that are not present in the live API.
- `LValidationReport:getIncomplete`: Returns the list of qualified names whose catalog entry is incomplete.
- `LValidationReport:missingCount`: Returns the count of missing entries.
- `LValidationReport:phantomCount`: Returns the count of phantom entries.
- `LValidationReport:incompleteCount`: Returns the count of incomplete entries.
- `LValidationReport:getSummary`: Returns a single-line summary of the validation results.
- `LValidationReport:toTable`: Converts the report to a plain Lua table.
- `LValidationReport:toJSON`: Serialises the report to a pretty-printed JSON string.
- `LValidationReport:type`: Returns the type name of this object.
- `LValidationReport:typeOf`: Returns true if this object is of the given type.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/docs/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
