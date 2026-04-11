# docs

## Module Info
- Module name: docs
- Module group: Edge/Integration
- Spec path: docs/specs/docs.md
- Lua API path(s): src/lua_api/docs_api.rs
- Rust test path(s): tests/rust/unit/docs_tests.rs
- Lua test path(s): tests/lua/unit/test_docs.lua

## Module Purpose

The docs module provides runtime documentation and schema data structures for the lurek.* API surface. It exists so the engine, VS Code extension, documentation generators, and Lua-side tooling can work from a structured catalog of API entries, quality metrics, and lightweight validation rules instead of relying only on free-form markdown.

At the center of the module is DocEntry metadata collected into a Catalog, along with reporting helpers that measure completeness and quality. The schema layer complements that by validating Lua data against explicit field rules, which makes the module useful for config, manifest, and documentation-related tooling as well as reflection.

This module does not parse Rust source files directly and it does not replace the generated docs pipeline under tools and docs/. It provides the runtime-facing structures and export helpers that other systems can populate, query, validate, and serialize.

## Files
- mod.rs: Module root that re-exports documentation, reporting, schema, and export helpers. It gives the rest of the codebase one place to import the runtime docs surface.
- entry.rs: Defines DocEntry, ParamInfo, and ReturnInfo. This file owns the shape of one documented API item and the metadata needed to describe its parameters and return values.
- catalog.rs: Defines Catalog, the in-memory collection of DocEntry values. It is the lookup and search layer for module-based queries, kind filtering, and direct entry retrieval.
- report.rs: Defines ValidationReport, QualityReport, and the scoring helpers that evaluate doc completeness. This is where documentation metadata becomes measurable quality data.
- schema.rs: Defines Schema, FieldRule, FieldType, SchemaError, and SchemaResult for runtime validation of structured Lua data. It is the module boundary between reflective documentation metadata and enforceable data rules.
- export.rs: Converts catalogs into editor-facing export formats such as completion, hover, and signature payloads. This file is the bridge from internal doc metadata to downstream tooling output.

## Key Types
- DocEntry: Canonical description of one documented API item, including identity, module, kind, prose, parameters, returns, examples, and metadata. It is the most important type in the module because nearly every other piece of functionality builds on it.
- ParamInfo: Structured parameter metadata attached to a DocEntry. It keeps function signatures machine-readable instead of burying argument details in prose.
- ReturnInfo: Structured return-value metadata attached to a DocEntry. It exists for the same reason as ParamInfo, but for outputs.
- Catalog: In-memory store for DocEntry values with search and filtering helpers. It is the first place to inspect when tools cannot find entries they expect.
- ValidationReport: Comparison result between the catalog and some observed or expected API surface. It is useful when auditing missing, phantom, or incomplete docs.
- QualityReport: Aggregate scoring output for doc quality at entry and module level. It exists so tooling can quantify documentation quality instead of only reporting raw missing fields.
- Schema: Named set of validation rules for structured Lua-side data. It gives the module a second role beyond pure documentation: validating data contracts.
- FieldRule and FieldType: The rule and type vocabulary used by Schema. These are the types to inspect when data validation becomes too permissive or too strict.