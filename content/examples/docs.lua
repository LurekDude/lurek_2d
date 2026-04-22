-- content/examples/docs.lua
-- Practical usage examples for the lurek.docs API (75 items).
--
-- Each --@api-stub: block is an independent, copy-pastable snippet that
-- demonstrates one API entry. Calls are wrapped in pcall(...) so the file
-- loads even when the underlying subsystem (GPU, audio device, filesystem,
-- physics world, …) is not yet initialised — but the canonical call form
-- (e.g. `lurek.docs.foo(arg)` or `instance:method(arg)`) is right there
-- in the snippet so you can lift it straight into your game code.
--
-- Run: cargo run -- content/examples/docs.lua

print("[example] lurek.docs — 75 API entries")

-- ── lurek.docs.* free functions ──

--@api-stub: lurek.docs.scan
-- Scan the lurek.* namespace to build an API catalog from live bindings.
-- Call when you need to invoke scan.
local ok, result = pcall(function() return lurek.docs.scan({}) end)
if ok then print("lurek.docs.scan ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.scanModule
-- Scan a single module's bindings.
-- Call when you need to invoke scan module.
local ok, result = pcall(function() return lurek.docs.scanModule("module_name") end)
if ok then print("lurek.docs.scanModule ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.loadToml
-- Load a TOML doc file into an ApiCatalog.
-- Call when you need to load toml.
local ok, obj = pcall(function() return lurek.docs.loadToml("path") end)
if ok and obj then print("created:", obj) end
print("lurek.docs.loadToml ok=", ok)

--@api-stub: lurek.docs.loadAll
-- Load all .toml files in a directory and merge into a single ApiCatalog.
-- Call when you need to load all.
local ok, obj = pcall(function() return lurek.docs.loadAll("directory") end)
if ok and obj then print("created:", obj) end
print("lurek.docs.loadAll ok=", ok)

--@api-stub: lurek.docs.describe
-- Inject or update a description for a named API entry.
-- Call when you need to invoke describe.
local ok, result = pcall(function() return lurek.docs.describe("qualified_name", nil) end)
if ok then print("lurek.docs.describe ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.setParamInfo
-- Set the parameter metadata for a catalog entry.
-- Call when you need to assign param info.
local ok, err = pcall(function() lurek.docs.setParamInfo("qualified_name", {}) end)
if not ok then print("set skipped:", err) end
print("lurek.docs.setParamInfo applied=", ok)

--@api-stub: lurek.docs.setReturnInfo
-- Set the return type metadata for a catalog entry.
-- Call when you need to assign return info.
local ok, err = pcall(function() lurek.docs.setReturnInfo("qualified_name", nil) end)
if not ok then print("set skipped:", err) end
print("lurek.docs.setReturnInfo applied=", ok)

--@api-stub: lurek.docs.getCatalog
-- Return the current internal catalog as an ApiCatalog userdata.
-- Call when you need to read catalog.
local ok, value = pcall(function() return lurek.docs.getCatalog() end)
local v = ok and value or "(unavailable)"
print("lurek.docs.getCatalog ->", v)

--@api-stub: lurek.docs.resetCatalog
-- Clear all entries from the internal catalog.
-- Call when you need to invoke reset catalog.
local ok, err = pcall(function() lurek.docs.resetCatalog() end)
if not ok then print("skipped:", err) end
print("lurek.docs.resetCatalog cleared=", ok)

--@api-stub: lurek.docs.validate
-- Validate catalog completeness against the live lurek.* bindings.
-- Call when you need to invoke validate.
local ok, result = pcall(function() return lurek.docs.validate(nil) end)
if ok then print("lurek.docs.validate ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.validateModule
-- Validate a single module against the live lurek.<module>.* bindings.
-- Call when you need to invoke validate module.
local ok, result = pcall(function() return lurek.docs.validateModule("module_name", nil) end)
if ok then print("lurek.docs.validateModule ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.checkStaleness
-- Compare catalog entries against source files in a directory for staleness.
-- Call when you need to invoke check staleness.
local ok, result = pcall(function() return lurek.docs.checkStaleness(nil, "source_dir") end)
if ok then print("lurek.docs.checkStaleness ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.quality
-- Calculate quality metrics for a catalog or the internal catalog.
-- Call when you need to invoke quality.
local ok, result = pcall(function() return lurek.docs.quality(nil) end)
if ok then print("lurek.docs.quality ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.qualityModule
-- Calculate quality metrics for a single module.
-- Call when you need to invoke quality module.
local ok, result = pcall(function() return lurek.docs.qualityModule("module_name", nil) end)
if ok then print("lurek.docs.qualityModule ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.coverage
-- Return (documented_count, total_live_count) coverage tuple.
-- Call when you need to invoke coverage.
local ok, result = pcall(function() return lurek.docs.coverage(nil) end)
if ok then print("lurek.docs.coverage ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.coverageModule
-- Return (documented_count, total_live_count) for a single module.
-- Call when you need to invoke coverage module.
local ok, result = pcall(function() return lurek.docs.coverageModule("module_name", nil) end)
if ok then print("lurek.docs.coverageModule ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.exportCompletions
-- Export VS Code IntelliSense completions JSON to a file.
-- Call when you need to invoke export completions.
local ok, obj = pcall(function() return lurek.docs.exportCompletions(nil, "path") end)
if ok and obj then print("created:", obj) end
print("lurek.docs.exportCompletions ok=", ok)

--@api-stub: lurek.docs.exportHover
-- Export VS Code hover JSON to a file.
-- Call when you need to invoke export hover.
local ok, obj = pcall(function() return lurek.docs.exportHover(nil, "path") end)
if ok and obj then print("created:", obj) end
print("lurek.docs.exportHover ok=", ok)

--@api-stub: lurek.docs.exportSignatures
-- Export VS Code signature-help JSON to a file.
-- Call when you need to invoke export signatures.
local ok, obj = pcall(function() return lurek.docs.exportSignatures(nil, "path") end)
if ok and obj then print("created:", obj) end
print("lurek.docs.exportSignatures ok=", ok)

--@api-stub: lurek.docs.exportAll
-- Export completions.json, hover.json, and signatures.json to a directory.
-- Call when you need to invoke export all.
local ok, obj = pcall(function() return lurek.docs.exportAll(nil, "output_dir") end)
if ok and obj then print("created:", obj) end
print("lurek.docs.exportAll ok=", ok)

--@api-stub: lurek.docs.exportMarkdown
-- Export a Markdown API reference file.
-- Call when you need to invoke export markdown.
local ok, obj = pcall(function() return lurek.docs.exportMarkdown(nil, "path") end)
if ok and obj then print("created:", obj) end
print("lurek.docs.exportMarkdown ok=", ok)

--@api-stub: lurek.docs.exportCheatsheet
-- Export a one-line-per-function plain-text cheatsheet.
-- Call when you need to invoke export cheatsheet.
local ok, obj = pcall(function() return lurek.docs.exportCheatsheet(nil, "path") end)
if ok and obj then print("created:", obj) end
print("lurek.docs.exportCheatsheet ok=", ok)

--@api-stub: lurek.docs.schema
-- Creates a Schema validator from a rules table.
-- Call when you need to invoke schema.
local ok, result = pcall(function() return lurek.docs.schema(nil, "name") end)
if ok then print("lurek.docs.schema ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.reflectLive
-- Walks the live lurek.* Lua table and returns a structured reflection of all.
-- Call when you need to invoke reflect live.
local ok, result = pcall(function() return lurek.docs.reflectLive(nil) end)
if ok then print("lurek.docs.reflectLive ->", result)
else print("unavailable:", result) end

--@api-stub: lurek.docs.reflectTable
-- Reflects any Lua table, returning a structure describing its keys,.
-- Call when you need to invoke reflect table.
local ok, result = pcall(function() return lurek.docs.reflectTable(nil, "name") end)
if ok then print("lurek.docs.reflectTable ->", result)
else print("unavailable:", result) end

-- ── Schema methods ──

--@api-stub: Schema:validate
-- Validates a Lua table against the schema.
-- Call when you need to invoke validate.
-- Build a Schema via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newSchema(...)
if instance then
  local ok, result = pcall(function() return instance:validate({}) end)
  print("Schema:validate ->", ok, result)
end

--@api-stub: Schema:check
-- Returns true when the data passes all schema rules.
-- Call when you need to invoke check.
-- Build a Schema via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newSchema(...)
if instance then
  local ok, result = pcall(function() return instance:check({}) end)
  print("Schema:check ->", ok, result)
end

--@api-stub: Schema:assert
-- Validates data and throws a Lua error on failure with all error messages joined.
-- Call when you need to invoke assert.
-- Build a Schema via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newSchema(...)
if instance then
  local ok, result = pcall(function() return instance:assert({}) end)
  print("Schema:assert ->", ok, result)
end

--@api-stub: Schema:getName
-- Returns the name identifier of this API schema group.
-- Call when you need to read name.
-- Build a Schema via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newSchema(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("Schema:getName ->", ok, result)
end

--@api-stub: Schema:getFields
-- Returns a table of declared field names.
-- Call when you need to read fields.
-- Build a Schema via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newSchema(...)
if instance then
  local ok, result = pcall(function() return instance:getFields() end)
  print("Schema:getFields ->", ok, result)
end

-- ── DocEntry methods ──

--@api-stub: DocEntry:getName
-- Returns the symbol name for this documentation entry.
-- Call when you need to read name.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getName() end)
  print("DocEntry:getName ->", ok, result)
end

--@api-stub: DocEntry:getQualifiedName
-- Returns the qualified name.
-- Call when you need to read qualified name.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getQualifiedName() end)
  print("DocEntry:getQualifiedName ->", ok, result)
end

--@api-stub: DocEntry:getModule
-- Returns the Lua module name this entry belongs to (e.g.
-- `'lurek.math'`).
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getModule() end)
  print("DocEntry:getModule ->", ok, result)
end

--@api-stub: DocEntry:getKind
-- Returns the kind tag for this entry (e.g.
-- `'function'`, `'method'`, `'class'`).
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getKind() end)
  print("DocEntry:getKind ->", ok, result)
end

--@api-stub: DocEntry:getDescription
-- Returns the human-readable description text for this documentation entry.
-- Call when you need to read description.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getDescription() end)
  print("DocEntry:getDescription ->", ok, result)
end

--@api-stub: DocEntry:getParameters
-- Returns the parameters as a table of `{name, type, description, optional, default?}` records.
-- Call when you need to read parameters.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getParameters() end)
  print("DocEntry:getParameters ->", ok, result)
end

--@api-stub: DocEntry:getReturns
-- Returns the return values as a table of `{type, description}` records.
-- Call when you need to read returns.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getReturns() end)
  print("DocEntry:getReturns ->", ok, result)
end

--@api-stub: DocEntry:getExample
-- Returns the example snippet, or nil.
-- Call when you need to read example.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getExample() end)
  print("DocEntry:getExample ->", ok, result)
end

--@api-stub: DocEntry:getSince
-- Returns the since version string, or nil.
-- Call when you need to read since.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getSince() end)
  print("DocEntry:getSince ->", ok, result)
end

--@api-stub: DocEntry:getDeprecated
-- Returns the deprecation message, or nil.
-- Call when you need to read deprecated.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getDeprecated() end)
  print("DocEntry:getDeprecated ->", ok, result)
end

--@api-stub: DocEntry:getScore
-- Returns the quality score in [0,1].
-- Call when you need to read score.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:getScore() end)
  print("DocEntry:getScore ->", ok, result)
end

--@api-stub: DocEntry:hasDescription
-- Returns true when the entry has a non-empty description.
-- Call when you need to check has description.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:hasDescription() end)
  print("DocEntry:hasDescription ->", ok, result)
end

--@api-stub: DocEntry:hasParameters
-- Returns true when the entry has at least one parameter.
-- Call when you need to check has parameters.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:hasParameters() end)
  print("DocEntry:hasParameters ->", ok, result)
end

--@api-stub: DocEntry:hasReturnType
-- Returns true when the entry declares at least one return type.
-- Call when you need to check has return type.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:hasReturnType() end)
  print("DocEntry:hasReturnType ->", ok, result)
end

--@api-stub: DocEntry:hasExample
-- Returns true when the entry has an example snippet.
-- Call when you need to check has example.
-- Build a DocEntry via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newDocEntry(...)
if instance then
  local ok, result = pcall(function() return instance:hasExample() end)
  print("DocEntry:hasExample ->", ok, result)
end

-- ── ApiCatalog methods ──

--@api-stub: ApiCatalog:getModules
-- Returns a sorted list of module names present in the catalog.
-- Call when you need to read modules.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:getModules() end)
  print("ApiCatalog:getModules ->", ok, result)
end

--@api-stub: ApiCatalog:getEntries
-- Returns all entries, optionally filtered to a single module.
-- Call when you need to read entries.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:getEntries(nil) end)
  print("ApiCatalog:getEntries ->", ok, result)
end

--@api-stub: ApiCatalog:getEntry
-- Returns a single entry by qualified name, or nil.
-- Call when you need to read entry.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:getEntry("qualified_name") end)
  print("ApiCatalog:getEntry ->", ok, result)
end

--@api-stub: ApiCatalog:getTypes
-- Returns the names of all entries with kind "type" in the given module.
-- Call when you need to read types.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:getTypes("module_name") end)
  print("ApiCatalog:getTypes ->", ok, result)
end

--@api-stub: ApiCatalog:getTypeMethods
-- Returns entries that are methods of the given type qualified name.
-- Call when you need to read type methods.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:getTypeMethods("qualified_name") end)
  print("ApiCatalog:getTypeMethods ->", ok, result)
end

--@api-stub: ApiCatalog:entryCount
-- Returns the number of entries, optionally scoped to a module.
-- Call when you need to invoke entry count.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:entryCount(nil) end)
  print("ApiCatalog:entryCount ->", ok, result)
end

--@api-stub: ApiCatalog:merge
-- Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
-- Call when you need to invoke merge.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:merge(nil) end)
  print("ApiCatalog:merge ->", ok, result)
end

--@api-stub: ApiCatalog:filter
-- Returns a new catalog containing only entries for which predicate returns true.
-- Call when you need to invoke filter.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:filter(nil) end)
  print("ApiCatalog:filter ->", ok, result)
end

--@api-stub: ApiCatalog:search
-- Returns a table of entries whose name, qualified name, or description contains query.
-- Call when you need to invoke search.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:search(nil) end)
  print("ApiCatalog:search ->", ok, result)
end

--@api-stub: ApiCatalog:toTable
-- Converts the catalog to a plain Lua table array.
-- Call when you need to invoke to table.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:toTable() end)
  print("ApiCatalog:toTable ->", ok, result)
end

--@api-stub: ApiCatalog:toJSON
-- Serialises the catalog to a pretty-printed JSON string.
-- Call when you need to invoke to j s o n.
-- Build a ApiCatalog via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newApiCatalog(...)
if instance then
  local ok, result = pcall(function() return instance:toJSON() end)
  print("ApiCatalog:toJSON ->", ok, result)
end

-- ── ValidationReport methods ──

--@api-stub: ValidationReport:isValid
-- Returns true when the report has no missing entries.
-- Call when you need to check is valid.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:isValid() end)
  print("ValidationReport:isValid ->", ok, result)
end

--@api-stub: ValidationReport:getMissing
-- Returns the list of qualified names present in the live API but missing from the catalog.
-- Call when you need to read missing.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:getMissing() end)
  print("ValidationReport:getMissing ->", ok, result)
end

--@api-stub: ValidationReport:getPhantom
-- Returns the list of qualified names in the catalog that are not present in the live API.
-- Call when you need to read phantom.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:getPhantom() end)
  print("ValidationReport:getPhantom ->", ok, result)
end

--@api-stub: ValidationReport:getIncomplete
-- Returns the list of qualified names whose catalog entry is incomplete.
-- Call when you need to read incomplete.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:getIncomplete() end)
  print("ValidationReport:getIncomplete ->", ok, result)
end

--@api-stub: ValidationReport:missingCount
-- Returns the count of missing entries.
-- Call when you need to invoke missing count.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:missingCount() end)
  print("ValidationReport:missingCount ->", ok, result)
end

--@api-stub: ValidationReport:phantomCount
-- Returns the count of phantom entries.
-- Call when you need to invoke phantom count.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:phantomCount() end)
  print("ValidationReport:phantomCount ->", ok, result)
end

--@api-stub: ValidationReport:incompleteCount
-- Returns the count of incomplete entries.
-- Call when you need to invoke incomplete count.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:incompleteCount() end)
  print("ValidationReport:incompleteCount ->", ok, result)
end

--@api-stub: ValidationReport:getSummary
-- Returns a single-line summary of the validation results.
-- Call when you need to read summary.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:getSummary() end)
  print("ValidationReport:getSummary ->", ok, result)
end

--@api-stub: ValidationReport:toTable
-- Converts the report to a plain Lua table.
-- Call when you need to invoke to table.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:toTable() end)
  print("ValidationReport:toTable ->", ok, result)
end

--@api-stub: ValidationReport:toJSON
-- Serialises the report to a pretty-printed JSON string.
-- Call when you need to invoke to j s o n.
-- Build a ValidationReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newValidationReport(...)
if instance then
  local ok, result = pcall(function() return instance:toJSON() end)
  print("ValidationReport:toJSON ->", ok, result)
end

-- ── QualityReport methods ──

--@api-stub: QualityReport:getOverallScore
-- Returns the overall quality score in [0,1].
-- Call when you need to read overall score.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:getOverallScore() end)
  print("QualityReport:getOverallScore ->", ok, result)
end

--@api-stub: QualityReport:getGrade
-- Returns the letter grade for the overall score.
-- Call when you need to read grade.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:getGrade() end)
  print("QualityReport:getGrade ->", ok, result)
end

--@api-stub: QualityReport:getModuleScores
-- Returns a table mapping module name to its average quality score.
-- Call when you need to read module scores.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:getModuleScores() end)
  print("QualityReport:getModuleScores ->", ok, result)
end

--@api-stub: QualityReport:getWorst
-- Returns up to count entries with the lowest quality scores.
-- Call when you need to read worst.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:getWorst(10) end)
  print("QualityReport:getWorst ->", ok, result)
end

--@api-stub: QualityReport:getBest
-- Returns up to count entries with the highest quality scores.
-- Call when you need to read best.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:getBest(10) end)
  print("QualityReport:getBest ->", ok, result)
end

--@api-stub: QualityReport:getByGrade
-- Returns entries whose grade exactly matches the given letter grade.
-- Call when you need to read by grade.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:getByGrade(nil) end)
  print("QualityReport:getByGrade ->", ok, result)
end

--@api-stub: QualityReport:getSummary
-- Returns a multi-line human-readable summary of quality by module.
-- Call when you need to read summary.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:getSummary() end)
  print("QualityReport:getSummary ->", ok, result)
end

--@api-stub: QualityReport:toTable
-- Converts the quality report to a plain Lua table.
-- Call when you need to invoke to table.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:toTable() end)
  print("QualityReport:toTable ->", ok, result)
end

--@api-stub: QualityReport:toJSON
-- Serialises the quality report to a pretty-printed JSON string.
-- Call when you need to invoke to j s o n.
-- Build a QualityReport via the appropriate lurek.docs.new* constructor first.
local instance = nil  -- e.g. local instance = lurek.docs.newQualityReport(...)
if instance then
  local ok, result = pcall(function() return instance:toJSON() end)
  print("QualityReport:toJSON ->", ok, result)
end

