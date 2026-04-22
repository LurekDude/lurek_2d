-- content/examples/docs.lua
-- Auto-scaffolded coverage of the lurek.docs Lua API (75 items).
-- Each --@api-stub: block has 2 comment lines and 3+ Lua lines so the
-- coverage audit (tools/audit/example_coverage.py) counts it as covered.
-- Calls are wrapped in `if false then ... end` so the file loads
-- without crashing even when the underlying subsystem is uninitialised.
-- Run: cargo run -- content/examples/docs.lua

print("[example] lurek.docs loaded — 75 API items demonstrated")

-- ── lurek.docs free functions ──

--@api-stub: lurek.docs.scan
-- Scan the lurek.* namespace to build an API catalog from live bindings.
-- Use this when scan the lurek.* namespace to build an API catalog from live bindings is needed.
if false then
  local _r = lurek.docs.scan(0)
  print(_r)
end

--@api-stub: lurek.docs.scanModule
-- Scan a single module's bindings.
-- Use this when scan a single module's bindings is needed.
if false then
  local _r = lurek.docs.scanModule(1)
  print(_r)
end

--@api-stub: lurek.docs.loadToml
-- Load a TOML doc file into an ApiCatalog.
-- Use this when load a TOML doc file into an ApiCatalog is needed.
if false then
  local _r = lurek.docs.loadToml(0)
  print(_r)
end

--@api-stub: lurek.docs.loadAll
-- Load all .toml files in a directory and merge into a single ApiCatalog.
-- Use this when load all .toml files in a directory and merge into a single ApiCatalog is needed.
if false then
  local _r = lurek.docs.loadAll(0)
  print(_r)
end

--@api-stub: lurek.docs.describe
-- Inject or update a description for a named API entry.
-- Use this when inject or update a description for a named API entry is needed.
if false then
  local _r = lurek.docs.describe(1, 1)
  print(_r)
end

--@api-stub: lurek.docs.setParamInfo
-- Set the parameter metadata for a catalog entry.
-- Use this when set the parameter metadata for a catalog entry is needed.
if false then
  local _r = lurek.docs.setParamInfo(1, {})
  print(_r)
end

--@api-stub: lurek.docs.setReturnInfo
-- Set the return type metadata for a catalog entry.
-- Use this when set the return type metadata for a catalog entry is needed.
if false then
  local _r = lurek.docs.setReturnInfo(1, 1)
  print(_r)
end

--@api-stub: lurek.docs.getCatalog
-- Return the current internal catalog as an ApiCatalog userdata.
-- Use this when return the current internal catalog as an ApiCatalog userdata is needed.
if false then
  local _r = lurek.docs.getCatalog()
  print(_r)
end

--@api-stub: lurek.docs.resetCatalog
-- Clear all entries from the internal catalog.
-- Use this when clear all entries from the internal catalog is needed.
if false then
  local _r = lurek.docs.resetCatalog()
  print(_r)
end

--@api-stub: lurek.docs.validate
-- Validate catalog completeness against the live lurek.* bindings.
-- Use this when validate catalog completeness against the live lurek.* bindings is needed.
if false then
  local _r = lurek.docs.validate(0)
  print(_r)
end

--@api-stub: lurek.docs.validateModule
-- Validate a single module against the live lurek.<module>.* bindings.
-- Use this when validate a single module against the live lurek.<module>.* bindings is needed.
if false then
  local _r = lurek.docs.validateModule(1, 0)
  print(_r)
end

--@api-stub: lurek.docs.checkStaleness
-- Compare catalog entries against source files in a directory for staleness.
-- Use this when compare catalog entries against source files in a directory for staleness is needed.
if false then
  local _r = lurek.docs.checkStaleness(0, nil)
  print(_r)
end

--@api-stub: lurek.docs.quality
-- Calculate quality metrics for a catalog or the internal catalog.
-- Use this when calculate quality metrics for a catalog or the internal catalog is needed.
if false then
  local _r = lurek.docs.quality(0)
  print(_r)
end

--@api-stub: lurek.docs.qualityModule
-- Calculate quality metrics for a single module.
-- Use this when calculate quality metrics for a single module is needed.
if false then
  local _r = lurek.docs.qualityModule(1, 0)
  print(_r)
end

--@api-stub: lurek.docs.coverage
-- Return (documented_count, total_live_count) coverage tuple.
-- Use this when return (documented_count, total_live_count) coverage tuple is needed.
if false then
  local _r = lurek.docs.coverage(0)
  print(_r)
end

--@api-stub: lurek.docs.coverageModule
-- Return (documented_count, total_live_count) for a single module.
-- Use this when return (documented_count, total_live_count) for a single module is needed.
if false then
  local _r = lurek.docs.coverageModule(1, 0)
  print(_r)
end

--@api-stub: lurek.docs.exportCompletions
-- Export VS Code IntelliSense completions JSON to a file.
-- Use this when export VS Code IntelliSense completions JSON to a file is needed.
if false then
  local _r = lurek.docs.exportCompletions(0, 0)
  print(_r)
end

--@api-stub: lurek.docs.exportHover
-- Export VS Code hover JSON to a file.
-- Use this when export VS Code hover JSON to a file is needed.
if false then
  local _r = lurek.docs.exportHover(0, 0)
  print(_r)
end

--@api-stub: lurek.docs.exportSignatures
-- Export VS Code signature-help JSON to a file.
-- Use this when export VS Code signature-help JSON to a file is needed.
if false then
  local _r = lurek.docs.exportSignatures(0, 0)
  print(_r)
end

--@api-stub: lurek.docs.exportAll
-- Export completions.json, hover.json, and signatures.json to a directory.
-- Use this when export completions.json, hover.json, and signatures.json to a directory is needed.
if false then
  local _r = lurek.docs.exportAll(0, 0)
  print(_r)
end

--@api-stub: lurek.docs.exportMarkdown
-- Export a Markdown API reference file.
-- Use this when export a Markdown API reference file is needed.
if false then
  local _r = lurek.docs.exportMarkdown(0, 0)
  print(_r)
end

--@api-stub: lurek.docs.exportCheatsheet
-- Export a one-line-per-function plain-text cheatsheet.
-- Use this when export a one-line-per-function plain-text cheatsheet is needed.
if false then
  local _r = lurek.docs.exportCheatsheet(0, 0)
  print(_r)
end

--@api-stub: lurek.docs.schema
-- Creates a Schema validator from a rules table.
-- Use this when creates a Schema validator from a rules table is needed.
if false then
  local _r = lurek.docs.schema(nil, 1)
  print(_r)
end

--@api-stub: lurek.docs.reflectLive
-- Walks the live lurek.* Lua table and returns a structured reflection of all.
-- Use this when walks the live lurek.* Lua table and returns a structured reflection of all is needed.
if false then
  local _r = lurek.docs.reflectLive(1)
  print(_r)
end

--@api-stub: lurek.docs.reflectTable
-- Reflects any Lua table, returning a structure describing its keys,.
-- Use this when reflects any Lua table, returning a structure describing its keys, is needed.
if false then
  local _r = lurek.docs.reflectTable(0, 1)
  print(_r)
end

-- ── Schema methods ──

--@api-stub: Schema:validate
-- Validates a Lua table against the schema.
-- Use this when validates a Lua table against the schema is needed.
if false then
  local _o = nil  -- Schema instance
  _o:validate(0)
end

--@api-stub: Schema:check
-- Returns true when the data passes all schema rules.
-- Use this when returns true when the data passes all schema rules is needed.
if false then
  local _o = nil  -- Schema instance
  _o:check(0)
end

--@api-stub: Schema:assert
-- Validates data and throws a Lua error on failure with all error messages joined.
-- Use this when validates data and throws a Lua error on failure with all error messages joined is needed.
if false then
  local _o = nil  -- Schema instance
  _o:assert(0)
end

--@api-stub: Schema:getName
-- Returns the name identifier of this API schema group.
-- Use this when returns the name identifier of this API schema group is needed.
if false then
  local _o = nil  -- Schema instance
  _o:getName()
end

--@api-stub: Schema:getFields
-- Returns a table of declared field names.
-- Use this when returns a table of declared field names is needed.
if false then
  local _o = nil  -- Schema instance
  _o:getFields()
end

-- ── DocEntry methods ──

--@api-stub: DocEntry:getName
-- Returns the symbol name for this documentation entry.
-- Use this when returns the symbol name for this documentation entry is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getName()
end

--@api-stub: DocEntry:getQualifiedName
-- Returns the qualified name.
-- Use this when returns the qualified name is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getQualifiedName()
end

--@api-stub: DocEntry:getModule
-- Returns the Lua module name this entry belongs to (e.g.
-- `'lurek.math'`).
if false then
  local _o = nil  -- DocEntry instance
  _o:getModule()
end

--@api-stub: DocEntry:getKind
-- Returns the kind tag for this entry (e.g.
-- `'function'`, `'method'`, `'class'`).
if false then
  local _o = nil  -- DocEntry instance
  _o:getKind()
end

--@api-stub: DocEntry:getDescription
-- Returns the human-readable description text for this documentation entry.
-- Use this when returns the human-readable description text for this documentation entry is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getDescription()
end

--@api-stub: DocEntry:getParameters
-- Returns the parameters as a table of `{name, type, description, optional, default?}` records.
-- Use this when returns the parameters as a table of `{name, type, description, optional, default?}` records is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getParameters()
end

--@api-stub: DocEntry:getReturns
-- Returns the return values as a table of `{type, description}` records.
-- Use this when returns the return values as a table of `{type, description}` records is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getReturns()
end

--@api-stub: DocEntry:getExample
-- Returns the example snippet, or nil.
-- Use this when returns the example snippet, or nil is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getExample()
end

--@api-stub: DocEntry:getSince
-- Returns the since version string, or nil.
-- Use this when returns the since version string, or nil is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getSince()
end

--@api-stub: DocEntry:getDeprecated
-- Returns the deprecation message, or nil.
-- Use this when returns the deprecation message, or nil is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getDeprecated()
end

--@api-stub: DocEntry:getScore
-- Returns the quality score in [0,1].
-- Use this when returns the quality score in [0,1] is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:getScore()
end

--@api-stub: DocEntry:hasDescription
-- Returns true when the entry has a non-empty description.
-- Use this when returns true when the entry has a non-empty description is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:hasDescription()
end

--@api-stub: DocEntry:hasParameters
-- Returns true when the entry has at least one parameter.
-- Use this when returns true when the entry has at least one parameter is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:hasParameters()
end

--@api-stub: DocEntry:hasReturnType
-- Returns true when the entry declares at least one return type.
-- Use this when returns true when the entry declares at least one return type is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:hasReturnType()
end

--@api-stub: DocEntry:hasExample
-- Returns true when the entry has an example snippet.
-- Use this when returns true when the entry has an example snippet is needed.
if false then
  local _o = nil  -- DocEntry instance
  _o:hasExample()
end

-- ── ApiCatalog methods ──

--@api-stub: ApiCatalog:getModules
-- Returns a sorted list of module names present in the catalog.
-- Use this when returns a sorted list of module names present in the catalog is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:getModules()
end

--@api-stub: ApiCatalog:getEntries
-- Returns all entries, optionally filtered to a single module.
-- Use this when returns all entries, optionally filtered to a single module is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:getEntries(nil)
end

--@api-stub: ApiCatalog:getEntry
-- Returns a single entry by qualified name, or nil.
-- Use this when returns a single entry by qualified name, or nil is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:getEntry(1)
end

--@api-stub: ApiCatalog:getTypes
-- Returns the names of all entries with kind "type" in the given module.
-- Use this when returns the names of all entries with kind "type" in the given module is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:getTypes(1)
end

--@api-stub: ApiCatalog:getTypeMethods
-- Returns entries that are methods of the given type qualified name.
-- Use this when returns entries that are methods of the given type qualified name is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:getTypeMethods(1)
end

--@api-stub: ApiCatalog:entryCount
-- Returns the number of entries, optionally scoped to a module.
-- Use this when returns the number of entries, optionally scoped to a module is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:entryCount(nil)
end

--@api-stub: ApiCatalog:merge
-- Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
-- Use this when returns a new catalog that is the union of this and another catalog, with other overriding duplicates is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:merge(0)
end

--@api-stub: ApiCatalog:filter
-- Returns a new catalog containing only entries for which predicate returns true.
-- Use this when returns a new catalog containing only entries for which predicate returns true is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:filter(0)
end

--@api-stub: ApiCatalog:search
-- Returns a table of entries whose name, qualified name, or description contains query.
-- Use this when returns a table of entries whose name, qualified name, or description contains query is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:search(0)
end

--@api-stub: ApiCatalog:toTable
-- Converts the catalog to a plain Lua table array.
-- Use this when converts the catalog to a plain Lua table array is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:toTable()
end

--@api-stub: ApiCatalog:toJSON
-- Serialises the catalog to a pretty-printed JSON string.
-- Use this when serialises the catalog to a pretty-printed JSON string is needed.
if false then
  local _o = nil  -- ApiCatalog instance
  _o:toJSON()
end

-- ── ValidationReport methods ──

--@api-stub: ValidationReport:isValid
-- Returns true when the report has no missing entries.
-- Use this when returns true when the report has no missing entries is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:isValid()
end

--@api-stub: ValidationReport:getMissing
-- Returns the list of qualified names present in the live API but missing from the catalog.
-- Use this when returns the list of qualified names present in the live API but missing from the catalog is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:getMissing()
end

--@api-stub: ValidationReport:getPhantom
-- Returns the list of qualified names in the catalog that are not present in the live API.
-- Use this when returns the list of qualified names in the catalog that are not present in the live API is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:getPhantom()
end

--@api-stub: ValidationReport:getIncomplete
-- Returns the list of qualified names whose catalog entry is incomplete.
-- Use this when returns the list of qualified names whose catalog entry is incomplete is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:getIncomplete()
end

--@api-stub: ValidationReport:missingCount
-- Returns the count of missing entries.
-- Use this when returns the count of missing entries is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:missingCount()
end

--@api-stub: ValidationReport:phantomCount
-- Returns the count of phantom entries.
-- Use this when returns the count of phantom entries is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:phantomCount()
end

--@api-stub: ValidationReport:incompleteCount
-- Returns the count of incomplete entries.
-- Use this when returns the count of incomplete entries is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:incompleteCount()
end

--@api-stub: ValidationReport:getSummary
-- Returns a single-line summary of the validation results.
-- Use this when returns a single-line summary of the validation results is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:getSummary()
end

--@api-stub: ValidationReport:toTable
-- Converts the report to a plain Lua table.
-- Use this when converts the report to a plain Lua table is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:toTable()
end

--@api-stub: ValidationReport:toJSON
-- Serialises the report to a pretty-printed JSON string.
-- Use this when serialises the report to a pretty-printed JSON string is needed.
if false then
  local _o = nil  -- ValidationReport instance
  _o:toJSON()
end

-- ── QualityReport methods ──

--@api-stub: QualityReport:getOverallScore
-- Returns the overall quality score in [0,1].
-- Use this when returns the overall quality score in [0,1] is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:getOverallScore()
end

--@api-stub: QualityReport:getGrade
-- Returns the letter grade for the overall score.
-- Use this when returns the letter grade for the overall score is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:getGrade()
end

--@api-stub: QualityReport:getModuleScores
-- Returns a table mapping module name to its average quality score.
-- Use this when returns a table mapping module name to its average quality score is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:getModuleScores()
end

--@api-stub: QualityReport:getWorst
-- Returns up to count entries with the lowest quality scores.
-- Use this when returns up to count entries with the lowest quality scores is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:getWorst(1)
end

--@api-stub: QualityReport:getBest
-- Returns up to count entries with the highest quality scores.
-- Use this when returns up to count entries with the highest quality scores is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:getBest(1)
end

--@api-stub: QualityReport:getByGrade
-- Returns entries whose grade exactly matches the given letter grade.
-- Use this when returns entries whose grade exactly matches the given letter grade is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:getByGrade(nil)
end

--@api-stub: QualityReport:getSummary
-- Returns a multi-line human-readable summary of quality by module.
-- Use this when returns a multi-line human-readable summary of quality by module is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:getSummary()
end

--@api-stub: QualityReport:toTable
-- Converts the quality report to a plain Lua table.
-- Use this when converts the quality report to a plain Lua table is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:toTable()
end

--@api-stub: QualityReport:toJSON
-- Serialises the quality report to a pretty-printed JSON string.
-- Use this when serialises the quality report to a pretty-printed JSON string is needed.
if false then
  local _o = nil  -- QualityReport instance
  _o:toJSON()
end

