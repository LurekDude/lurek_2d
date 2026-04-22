-- content/examples/docs.lua
-- Scaffolded coverage of the lurek.docs API (75 items).
--
-- Every --@api-stub: block below is a SCAFFOLD. The body must be
-- replaced by hand with a 3-6 line real usage snippet showing how to
-- call the API in real game context, written by reading:
--   * src/lua_api/docs_api.rs   (Lua binding, arg types, return shape)
--   * src/docs/                 (semantics, side effects)
--   * docs/specs/docs.md        (canonical reference)
--
-- Snippet rules (love2d-wiki style):
--   * NO `return` at top-level (breaks the file).
--   * NO `pcall` defensive wrappers, NO `if false then`.
--   * Wrap GPU / audio / physics calls inside
--     `function lurek.render() ... end` or
--     `function lurek.update(dt) ... end` callbacks so the file loads.
--   * Use REAL values: paths like "sfx/jump.ogg", keys like "space",
--     colours like {1, 0.5, 0, 1}.
--   * Keep the two `--` comment lines: 1) what the API does (use the
--     existing description), 2) one line of practical advice.
--
-- Run: cargo run -- content/examples/docs.lua

-- ── lurek.docs.* functions ──

--@api-stub: lurek.docs.scan
-- Scan the lurek.* namespace to build an API catalog from live bindings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.scan
  local _todo = "TODO: write a real lurek.docs.scan usage example"
  print(_todo)
end

--@api-stub: lurek.docs.scanModule
-- Scan a single module's bindings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.scanModule
  local _todo = "TODO: write a real lurek.docs.scanModule usage example"
  print(_todo)
end

--@api-stub: lurek.docs.loadToml
-- Load a TOML doc file into an ApiCatalog.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.loadToml
  local _todo = "TODO: write a real lurek.docs.loadToml usage example"
  print(_todo)
end

--@api-stub: lurek.docs.loadAll
-- Load all .toml files in a directory and merge into a single ApiCatalog.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.loadAll
  local _todo = "TODO: write a real lurek.docs.loadAll usage example"
  print(_todo)
end

--@api-stub: lurek.docs.describe
-- Inject or update a description for a named API entry.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.describe
  local _todo = "TODO: write a real lurek.docs.describe usage example"
  print(_todo)
end

--@api-stub: lurek.docs.setParamInfo
-- Set the parameter metadata for a catalog entry.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.setParamInfo
  local _todo = "TODO: write a real lurek.docs.setParamInfo usage example"
  print(_todo)
end

--@api-stub: lurek.docs.setReturnInfo
-- Set the return type metadata for a catalog entry.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.setReturnInfo
  local _todo = "TODO: write a real lurek.docs.setReturnInfo usage example"
  print(_todo)
end

--@api-stub: lurek.docs.getCatalog
-- Return the current internal catalog as an ApiCatalog userdata.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.getCatalog
  local _todo = "TODO: write a real lurek.docs.getCatalog usage example"
  print(_todo)
end

--@api-stub: lurek.docs.resetCatalog
-- Clear all entries from the internal catalog.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.resetCatalog
  local _todo = "TODO: write a real lurek.docs.resetCatalog usage example"
  print(_todo)
end

--@api-stub: lurek.docs.validate
-- Validate catalog completeness against the live lurek.* bindings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.validate
  local _todo = "TODO: write a real lurek.docs.validate usage example"
  print(_todo)
end

--@api-stub: lurek.docs.validateModule
-- Validate a single module against the live lurek.<module>.* bindings.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.validateModule
  local _todo = "TODO: write a real lurek.docs.validateModule usage example"
  print(_todo)
end

--@api-stub: lurek.docs.checkStaleness
-- Compare catalog entries against source files in a directory for staleness.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.checkStaleness
  local _todo = "TODO: write a real lurek.docs.checkStaleness usage example"
  print(_todo)
end

--@api-stub: lurek.docs.quality
-- Calculate quality metrics for a catalog or the internal catalog.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.quality
  local _todo = "TODO: write a real lurek.docs.quality usage example"
  print(_todo)
end

--@api-stub: lurek.docs.qualityModule
-- Calculate quality metrics for a single module.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.qualityModule
  local _todo = "TODO: write a real lurek.docs.qualityModule usage example"
  print(_todo)
end

--@api-stub: lurek.docs.coverage
-- Return (documented_count, total_live_count) coverage tuple.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.coverage
  local _todo = "TODO: write a real lurek.docs.coverage usage example"
  print(_todo)
end

--@api-stub: lurek.docs.coverageModule
-- Return (documented_count, total_live_count) for a single module.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.coverageModule
  local _todo = "TODO: write a real lurek.docs.coverageModule usage example"
  print(_todo)
end

--@api-stub: lurek.docs.exportCompletions
-- Export VS Code IntelliSense completions JSON to a file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.exportCompletions
  local _todo = "TODO: write a real lurek.docs.exportCompletions usage example"
  print(_todo)
end

--@api-stub: lurek.docs.exportHover
-- Export VS Code hover JSON to a file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.exportHover
  local _todo = "TODO: write a real lurek.docs.exportHover usage example"
  print(_todo)
end

--@api-stub: lurek.docs.exportSignatures
-- Export VS Code signature-help JSON to a file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.exportSignatures
  local _todo = "TODO: write a real lurek.docs.exportSignatures usage example"
  print(_todo)
end

--@api-stub: lurek.docs.exportAll
-- Export completions.json, hover.json, and signatures.json to a directory.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.exportAll
  local _todo = "TODO: write a real lurek.docs.exportAll usage example"
  print(_todo)
end

--@api-stub: lurek.docs.exportMarkdown
-- Export a Markdown API reference file.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.exportMarkdown
  local _todo = "TODO: write a real lurek.docs.exportMarkdown usage example"
  print(_todo)
end

--@api-stub: lurek.docs.exportCheatsheet
-- Export a one-line-per-function plain-text cheatsheet.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.exportCheatsheet
  local _todo = "TODO: write a real lurek.docs.exportCheatsheet usage example"
  print(_todo)
end

--@api-stub: lurek.docs.schema
-- Creates a Schema validator from a rules table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.schema
  local _todo = "TODO: write a real lurek.docs.schema usage example"
  print(_todo)
end

--@api-stub: lurek.docs.reflectLive
-- Walks the live lurek.* Lua table and returns a structured reflection of all.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.reflectLive
  local _todo = "TODO: write a real lurek.docs.reflectLive usage example"
  print(_todo)
end

--@api-stub: lurek.docs.reflectTable
-- Reflects any Lua table, returning a structure describing its keys,.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: lurek.docs.reflectTable
  local _todo = "TODO: write a real lurek.docs.reflectTable usage example"
  print(_todo)
end

-- ── Schema methods ──

--@api-stub: Schema:validate
-- Validates a Lua table against the schema.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: Schema:validate
  local _todo = "TODO: write a real Schema:validate usage example"
  print(_todo)
end

--@api-stub: Schema:check
-- Returns true when the data passes all schema rules.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: Schema:check
  local _todo = "TODO: write a real Schema:check usage example"
  print(_todo)
end

--@api-stub: Schema:assert
-- Validates data and throws a Lua error on failure with all error messages joined.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: Schema:assert
  local _todo = "TODO: write a real Schema:assert usage example"
  print(_todo)
end

--@api-stub: Schema:getName
-- Returns the name identifier of this API schema group.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: Schema:getName
  local _todo = "TODO: write a real Schema:getName usage example"
  print(_todo)
end

--@api-stub: Schema:getFields
-- Returns a table of declared field names.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: Schema:getFields
  local _todo = "TODO: write a real Schema:getFields usage example"
  print(_todo)
end

-- ── DocEntry methods ──

--@api-stub: DocEntry:getName
-- Returns the symbol name for this documentation entry.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getName
  local _todo = "TODO: write a real DocEntry:getName usage example"
  print(_todo)
end

--@api-stub: DocEntry:getQualifiedName
-- Returns the qualified name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getQualifiedName
  local _todo = "TODO: write a real DocEntry:getQualifiedName usage example"
  print(_todo)
end

--@api-stub: DocEntry:getModule
-- Returns the Lua module name this entry belongs to (e.g.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getModule
  local _todo = "TODO: write a real DocEntry:getModule usage example"
  print(_todo)
end

--@api-stub: DocEntry:getKind
-- Returns the kind tag for this entry (e.g.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getKind
  local _todo = "TODO: write a real DocEntry:getKind usage example"
  print(_todo)
end

--@api-stub: DocEntry:getDescription
-- Returns the human-readable description text for this documentation entry.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getDescription
  local _todo = "TODO: write a real DocEntry:getDescription usage example"
  print(_todo)
end

--@api-stub: DocEntry:getParameters
-- Returns the parameters as a table of `{name, type, description, optional, default?}` records.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getParameters
  local _todo = "TODO: write a real DocEntry:getParameters usage example"
  print(_todo)
end

--@api-stub: DocEntry:getReturns
-- Returns the return values as a table of `{type, description}` records.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getReturns
  local _todo = "TODO: write a real DocEntry:getReturns usage example"
  print(_todo)
end

--@api-stub: DocEntry:getExample
-- Returns the example snippet, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getExample
  local _todo = "TODO: write a real DocEntry:getExample usage example"
  print(_todo)
end

--@api-stub: DocEntry:getSince
-- Returns the since version string, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getSince
  local _todo = "TODO: write a real DocEntry:getSince usage example"
  print(_todo)
end

--@api-stub: DocEntry:getDeprecated
-- Returns the deprecation message, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getDeprecated
  local _todo = "TODO: write a real DocEntry:getDeprecated usage example"
  print(_todo)
end

--@api-stub: DocEntry:getScore
-- Returns the quality score in [0,1].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:getScore
  local _todo = "TODO: write a real DocEntry:getScore usage example"
  print(_todo)
end

--@api-stub: DocEntry:hasDescription
-- Returns true when the entry has a non-empty description.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:hasDescription
  local _todo = "TODO: write a real DocEntry:hasDescription usage example"
  print(_todo)
end

--@api-stub: DocEntry:hasParameters
-- Returns true when the entry has at least one parameter.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:hasParameters
  local _todo = "TODO: write a real DocEntry:hasParameters usage example"
  print(_todo)
end

--@api-stub: DocEntry:hasReturnType
-- Returns true when the entry declares at least one return type.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:hasReturnType
  local _todo = "TODO: write a real DocEntry:hasReturnType usage example"
  print(_todo)
end

--@api-stub: DocEntry:hasExample
-- Returns true when the entry has an example snippet.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: DocEntry:hasExample
  local _todo = "TODO: write a real DocEntry:hasExample usage example"
  print(_todo)
end

-- ── ApiCatalog methods ──

--@api-stub: ApiCatalog:getModules
-- Returns a sorted list of module names present in the catalog.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:getModules
  local _todo = "TODO: write a real ApiCatalog:getModules usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:getEntries
-- Returns all entries, optionally filtered to a single module.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:getEntries
  local _todo = "TODO: write a real ApiCatalog:getEntries usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:getEntry
-- Returns a single entry by qualified name, or nil.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:getEntry
  local _todo = "TODO: write a real ApiCatalog:getEntry usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:getTypes
-- Returns the names of all entries with kind "type" in the given module.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:getTypes
  local _todo = "TODO: write a real ApiCatalog:getTypes usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:getTypeMethods
-- Returns entries that are methods of the given type qualified name.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:getTypeMethods
  local _todo = "TODO: write a real ApiCatalog:getTypeMethods usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:entryCount
-- Returns the number of entries, optionally scoped to a module.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:entryCount
  local _todo = "TODO: write a real ApiCatalog:entryCount usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:merge
-- Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:merge
  local _todo = "TODO: write a real ApiCatalog:merge usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:filter
-- Returns a new catalog containing only entries for which predicate returns true.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:filter
  local _todo = "TODO: write a real ApiCatalog:filter usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:search
-- Returns a table of entries whose name, qualified name, or description contains query.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:search
  local _todo = "TODO: write a real ApiCatalog:search usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:toTable
-- Converts the catalog to a plain Lua table array.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:toTable
  local _todo = "TODO: write a real ApiCatalog:toTable usage example"
  print(_todo)
end

--@api-stub: ApiCatalog:toJSON
-- Serialises the catalog to a pretty-printed JSON string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ApiCatalog:toJSON
  local _todo = "TODO: write a real ApiCatalog:toJSON usage example"
  print(_todo)
end

-- ── ValidationReport methods ──

--@api-stub: ValidationReport:isValid
-- Returns true when the report has no missing entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:isValid
  local _todo = "TODO: write a real ValidationReport:isValid usage example"
  print(_todo)
end

--@api-stub: ValidationReport:getMissing
-- Returns the list of qualified names present in the live API but missing from the catalog.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:getMissing
  local _todo = "TODO: write a real ValidationReport:getMissing usage example"
  print(_todo)
end

--@api-stub: ValidationReport:getPhantom
-- Returns the list of qualified names in the catalog that are not present in the live API.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:getPhantom
  local _todo = "TODO: write a real ValidationReport:getPhantom usage example"
  print(_todo)
end

--@api-stub: ValidationReport:getIncomplete
-- Returns the list of qualified names whose catalog entry is incomplete.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:getIncomplete
  local _todo = "TODO: write a real ValidationReport:getIncomplete usage example"
  print(_todo)
end

--@api-stub: ValidationReport:missingCount
-- Returns the count of missing entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:missingCount
  local _todo = "TODO: write a real ValidationReport:missingCount usage example"
  print(_todo)
end

--@api-stub: ValidationReport:phantomCount
-- Returns the count of phantom entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:phantomCount
  local _todo = "TODO: write a real ValidationReport:phantomCount usage example"
  print(_todo)
end

--@api-stub: ValidationReport:incompleteCount
-- Returns the count of incomplete entries.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:incompleteCount
  local _todo = "TODO: write a real ValidationReport:incompleteCount usage example"
  print(_todo)
end

--@api-stub: ValidationReport:getSummary
-- Returns a single-line summary of the validation results.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:getSummary
  local _todo = "TODO: write a real ValidationReport:getSummary usage example"
  print(_todo)
end

--@api-stub: ValidationReport:toTable
-- Converts the report to a plain Lua table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:toTable
  local _todo = "TODO: write a real ValidationReport:toTable usage example"
  print(_todo)
end

--@api-stub: ValidationReport:toJSON
-- Serialises the report to a pretty-printed JSON string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: ValidationReport:toJSON
  local _todo = "TODO: write a real ValidationReport:toJSON usage example"
  print(_todo)
end

-- ── QualityReport methods ──

--@api-stub: QualityReport:getOverallScore
-- Returns the overall quality score in [0,1].
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:getOverallScore
  local _todo = "TODO: write a real QualityReport:getOverallScore usage example"
  print(_todo)
end

--@api-stub: QualityReport:getGrade
-- Returns the letter grade for the overall score.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:getGrade
  local _todo = "TODO: write a real QualityReport:getGrade usage example"
  print(_todo)
end

--@api-stub: QualityReport:getModuleScores
-- Returns a table mapping module name to its average quality score.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:getModuleScores
  local _todo = "TODO: write a real QualityReport:getModuleScores usage example"
  print(_todo)
end

--@api-stub: QualityReport:getWorst
-- Returns up to count entries with the lowest quality scores.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:getWorst
  local _todo = "TODO: write a real QualityReport:getWorst usage example"
  print(_todo)
end

--@api-stub: QualityReport:getBest
-- Returns up to count entries with the highest quality scores.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:getBest
  local _todo = "TODO: write a real QualityReport:getBest usage example"
  print(_todo)
end

--@api-stub: QualityReport:getByGrade
-- Returns entries whose grade exactly matches the given letter grade.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:getByGrade
  local _todo = "TODO: write a real QualityReport:getByGrade usage example"
  print(_todo)
end

--@api-stub: QualityReport:getSummary
-- Returns a multi-line human-readable summary of quality by module.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:getSummary
  local _todo = "TODO: write a real QualityReport:getSummary usage example"
  print(_todo)
end

--@api-stub: QualityReport:toTable
-- Converts the quality report to a plain Lua table.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:toTable
  local _todo = "TODO: write a real QualityReport:toTable usage example"
  print(_todo)
end

--@api-stub: QualityReport:toJSON
-- Serialises the quality report to a pretty-printed JSON string.
-- TODO: replace this scaffold with a real usage snippet (see src/lua_api/docs_api.rs and docs/specs/docs.md).
do  -- TODO: QualityReport:toJSON
  local _todo = "TODO: write a real QualityReport:toJSON usage example"
  print(_todo)
end

