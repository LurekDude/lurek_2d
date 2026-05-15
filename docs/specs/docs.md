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

## Functions

- `Catalog::new` (`catalog.rs`): Create an empty catalog and return it for entry aggregation.
- `Catalog::from_entries` (`catalog.rs`): Build a catalog from a slice and return a cloned copy of each entry.
- `Catalog::add` (`catalog.rs`): Append one entry to the catalog and return unit.
- `Catalog::modules` (`catalog.rs`): Return sorted unique module names referenced by all stored entries.
- `Catalog::all_entries` (`catalog.rs`): Return an immutable slice of all entries in insertion order.
- `Catalog::entries_for_module` (`catalog.rs`): Return all entries that belong to the requested module name.
- `Catalog::get_entry` (`catalog.rs`): Return the entry matching a fully qualified name or None when missing.
- `Catalog::entry_count` (`catalog.rs`): Return the number of stored entries.
- `Catalog::search` (`catalog.rs`): Return entries whose lowercase name or description contains the query.
- `Catalog::filter_by_kind` (`catalog.rs`): Return entries with a kind exactly equal to the provided value.
- `Catalog::merge` (`catalog.rs`): Merge this catalog with another and return de-duplicated entries by qualified name.
- `Catalog::clear` (`catalog.rs`): Remove all stored entries and return unit.
- `DocEntry::new` (`entry.rs`): Create an entry shell and return it with a computed qualified name.
- `DocEntry::is_complete` (`entry.rs`): Return true when required fields are present for this kind, else false.
- `DocEntry::missing_fields` (`entry.rs`): Return symbolic names of missing required fields for this entry.
- `export_completions` (`export.rs`): Writes a VS Code completions JSON array to `path`.
- `export_hover` (`export.rs`): Writes a VS Code hover JSON map to `path`.
- `export_signatures` (`export.rs`): Writes a VS Code signature-help JSON map to `path`.
- `export_all` (`export.rs`): Writes `completions.json`, `hover.json`, and `signatures.json` to `output_dir`.
- `quality_score` (`report.rs`): Computes a quality score in `[0.0, 1.0]` for a single doc entry.
- `quality_grade` (`report.rs`): Converts a quality score into a letter grade.
- `ValidationReport::new` (`report.rs`): Create an empty validation report and return it.
- `ValidationReport::is_clean` (`report.rs`): Return true when no issue buckets contain any item.
- `ValidationReport::total_issues` (`report.rs`): Return the total number of aggregated issues across all buckets.
- `QualityReport::compute` (`report.rs`): Compute report metrics from a catalog and return the report.
- `QualityReport::module_grade` (`report.rs`): Return the letter grade for one module score or F when missing.
- `QualityReport::from_entries` (`report.rs`): Build a temporary catalog from entries and return a computed report.

## Lua API Reference

- Binding path(s): `src/lua_api/docs_api.rs`
- Namespace: `lurek.docs`

### Module Functions
- `lurek.docs.scan`: Reflects the live `lurek` table and builds a catalog of callable APIs.
- `lurek.docs.scanModule`: Reflects one live `lurek.<module>` table and builds a catalog for that module.
- `lurek.docs.loadToml`: Loads a TOML documentation catalog file and converts its entries into an API catalog.
- `lurek.docs.loadAll`: Loads all TOML documentation catalog files from a directory and combines their entries.
- `lurek.docs.describe`: Adds or updates the description for one editable catalog entry.
- `lurek.docs.setParamInfo`: Replaces parameter metadata for one editable catalog entry.
- `lurek.docs.setReturnInfo`: Replaces return-value metadata for one editable catalog entry.
- `lurek.docs.getCatalog`: Returns the editable in-memory documentation catalog.
- `lurek.docs.resetCatalog`: Clears the editable in-memory documentation catalog.
- `lurek.docs.validate`: Compares a documentation catalog with the live reflected `lurek` API table.
- `lurek.docs.validateModule`: Compares one module's documentation catalog entries with the live reflected module table.
- `lurek.docs.checkStaleness`: Lists source files in a directory for simple documentation staleness checks.
- `lurek.docs.quality`: Computes documentation quality for a supplied catalog or the editable in-memory catalog.
- `lurek.docs.qualityModule`: Computes documentation quality for entries belonging to one module.
- `lurek.docs.coverage`: Returns documented and live API counts for the full `lurek` table.
- `lurek.docs.coverageModule`: Returns documented and live API counts for one module.
- `lurek.docs.exportCompletions`: Exports catalog completion metadata to a file.
- `lurek.docs.exportHover`: Exports catalog hover metadata to a file.
- `lurek.docs.exportSignatures`: Exports catalog signature metadata to a file.
- `lurek.docs.exportAll`: Exports all editor documentation artifacts for a catalog into a directory.
- `lurek.docs.exportMarkdown`: Writes a Markdown API reference from catalog entries.
- `lurek.docs.exportCheatsheet`: Writes a compact text cheatsheet from catalog entries.
- `lurek.docs.schema`: Builds a schema validator from Lua table rules.
- `lurek.docs.schemaFromToml`: Builds a schema validator from TOML schema text.
- `lurek.docs.reflectLive`: Reflects live `lurek` module tables into plain name and type rows.
- `lurek.docs.reflectTable`: Reflects an arbitrary Lua table into name, qualifiedName, and type rows.

### `LApiCatalog` Methods
- `LApiCatalog:getModules`: Returns every module represented in this catalog.
- `LApiCatalog:getEntries`: Returns catalog entries, optionally limited to one module.
- `LApiCatalog:getEntry`: Returns one catalog entry by qualified API name.
- `LApiCatalog:getTypes`: Returns type names documented for one module.
- `LApiCatalog:getTypeMethods`: Returns method entries associated with a qualified type name.
- `LApiCatalog:entryCount`: Counts entries in the catalog, optionally for one module.
- `LApiCatalog:merge`: Merges another catalog into this catalog and returns a new catalog value.
- `LApiCatalog:filter`: Builds a new catalog containing entries accepted by a Lua predicate.
- `LApiCatalog:search`: Searches names, qualified names, and descriptions with a case-insensitive substring query.
- `LApiCatalog:toTable`: Converts this catalog into plain Lua tables for lightweight inspection.
- `LApiCatalog:toJSON`: Serializes this catalog to formatted JSON.
- `LApiCatalog:type`: Returns the Lua-visible type name for this API catalog handle.
- `LApiCatalog:typeOf`: Returns whether this API catalog handle matches a supported type name.

### `LDocEntry` Methods
- `LDocEntry:getName`: Returns the short API name stored by this documentation entry.
- `LDocEntry:getQualifiedName`: Returns the full dotted API name stored by this documentation entry.
- `LDocEntry:getModule`: Returns the module name associated with this documentation entry.
- `LDocEntry:getKind`: Returns the documentation kind recorded for this entry.
- `LDocEntry:getDescription`: Returns the prose description recorded for this entry.
- `LDocEntry:getParameters`: Returns parameter metadata recorded for this entry.
- `LDocEntry:getReturns`: Returns return-value metadata recorded for this entry.
- `LDocEntry:getExample`: Returns this entry's example text when one was recorded.
- `LDocEntry:getSince`: Returns this entry's since-version text when one was recorded.
- `LDocEntry:getDeprecated`: Returns this entry's deprecation text when one was recorded.
- `LDocEntry:getScore`: Returns the documentation quality score calculated for this entry.
- `LDocEntry:hasDescription`: Returns whether this entry has non-empty description text.
- `LDocEntry:hasParameters`: Returns whether this entry has parameter metadata.
- `LDocEntry:hasReturnType`: Returns whether this entry has return-value metadata.
- `LDocEntry:hasExample`: Returns whether this entry has example text.
- `LDocEntry:type`: Returns the Lua-visible type name for this documentation entry handle.
- `LDocEntry:typeOf`: Returns whether this documentation entry handle matches a supported type name.

### `LQualityReport` Methods
- `LQualityReport:getOverallScore`: Returns the aggregate documentation quality score.
- `LQualityReport:getGrade`: Returns the letter grade derived from the aggregate documentation score.
- `LQualityReport:getModuleScores`: Returns per-module documentation quality scores.
- `LQualityReport:getWorst`: Returns the lowest-scoring documentation entries.
- `LQualityReport:getBest`: Returns the highest-scoring documentation entries.
- `LQualityReport:getByGrade`: Returns documentation entries whose calculated grade matches a grade string.
- `LQualityReport:getSummary`: Returns a human-readable summary of overall and per-module quality scores.
- `LQualityReport:toTable`: Converts this quality report into a plain Lua table.
- `LQualityReport:toJSON`: Serializes this quality report to formatted JSON.
- `LQualityReport:type`: Returns the Lua-visible type name for this quality report handle.
- `LQualityReport:typeOf`: Returns whether this quality report handle matches a supported type name.

### `LSchema` Methods
- `LSchema:validate`: Validates a Lua table and returns a success flag plus structured error rows.
- `LSchema:check`: Validates a Lua table and returns only the boolean result.
- `LSchema:assert`: Validates a Lua table and raises a Lua error when schema checks fail.
- `LSchema:getName`: Returns this schema's display name.
- `LSchema:getFields`: Returns the field names declared by this schema.
- `LSchema:type`: Returns the Lua-visible type name for this schema handle.
- `LSchema:typeOf`: Returns whether this schema handle matches a supported type name.

### `LValidationReport` Methods
- `LValidationReport:isValid`: Returns whether the validation report has no missing live APIs.
- `LValidationReport:getMissing`: Returns live APIs that were missing from the checked catalog.
- `LValidationReport:getPhantom`: Returns catalog APIs that were not present in the live Lua table.
- `LValidationReport:getIncomplete`: Returns catalog APIs whose documentation was incomplete.
- `LValidationReport:missingCount`: Returns the number of live APIs missing from the catalog.
- `LValidationReport:phantomCount`: Returns the number of catalog APIs absent from live reflection.
- `LValidationReport:incompleteCount`: Returns the number of catalog APIs with incomplete documentation.
- `LValidationReport:getSummary`: Returns a compact text summary of missing, phantom, and incomplete counts.
- `LValidationReport:toTable`: Converts this validation report into a plain Lua table.
- `LValidationReport:toJSON`: Serializes this validation report to formatted JSON.
- `LValidationReport:type`: Returns the Lua-visible type name for this validation report handle.
- `LValidationReport:typeOf`: Returns whether this validation report handle matches a supported type name.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/docs/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
