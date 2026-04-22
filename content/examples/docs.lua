-- content/examples/docs.lua
-- Hand-written coverage of the lurek.docs API (75 items).
--
-- The lurek.docs namespace builds, validates, and exports an API catalog
-- by reflecting the live lurek.* tables and merging in TOML doc files.
-- Most calls return userdata (ApiCatalog / ValidationReport / QualityReport
-- / Schema / DocEntry) whose methods are demonstrated below.
--
-- Run: cargo run -- content/examples/docs.lua

-- ── lurek.docs.* functions ──

--@api-stub: lurek.docs.scan
-- Scan the lurek.* namespace to build an API catalog from live bindings.
-- Call this once at startup or from an editor tool to snapshot the runtime API surface.
do  -- lurek.docs.scan
  local catalog = lurek.docs.scan()
  local count = catalog:entryCount()
  lurek.log.info("docs", "scanned " .. count .. " live API entries")
end

--@api-stub: lurek.docs.scanModule
-- Scan a single module's bindings.
-- Use when you only need one namespace (faster than scan() and easier to validate).
do  -- lurek.docs.scanModule
  local audio_cat = lurek.docs.scanModule("audio")
  for _, entry in ipairs(audio_cat:getEntries()) do
    lurek.log.debug("audio-api", entry:getQualifiedName())
  end
end

--@api-stub: lurek.docs.loadToml
-- Load a TOML doc file into an ApiCatalog.
-- Hand-authored TOML is the canonical doc source; load it before validate() to merge.
do  -- lurek.docs.loadToml
  local catalog = lurek.docs.loadToml("docs/api/audio.toml")
  if catalog:entryCount() == 0 then
    lurek.log.warn("docs", "audio.toml had no entries")
  end
end

--@api-stub: lurek.docs.loadAll
-- Load all .toml files in a directory and merge into a single ApiCatalog.
-- Use this in a CI doc-build step to gather every per-module TOML at once.
do  -- lurek.docs.loadAll
  local catalog = lurek.docs.loadAll("docs/api")
  local mods = catalog:getModules()
  lurek.log.info("docs", "loaded " .. #mods .. " documented modules")
end

--@api-stub: lurek.docs.describe
-- Inject or update a description for a named API entry.
-- Use to patch missing descriptions in the internal catalog before exporting.
do  -- lurek.docs.describe
  lurek.docs.scan()
  lurek.docs.describe("lurek.audio.play", "Play a sound source by name.")
  lurek.docs.describe("lurek.audio.stop", "Stop a currently playing source.")
end

--@api-stub: lurek.docs.setParamInfo
-- Set the parameter metadata for a catalog entry.
-- Pair with describe() so editor tooltips show parameter names and types.
do  -- lurek.docs.setParamInfo
  lurek.docs.scan()
  lurek.docs.setParamInfo("lurek.audio.play", {
    { name = "name", type = "string", description = "source id", optional = false },
    { name = "loop", type = "boolean", description = "loop on end", optional = true, default = false },
  })
end

--@api-stub: lurek.docs.setReturnInfo
-- Set the return type metadata for a catalog entry.
-- Required for IntelliSense to suggest method chains on the returned value.
do  -- lurek.docs.setReturnInfo
  lurek.docs.scan()
  lurek.docs.setReturnInfo("lurek.audio.play", {
    { type = "Source", description = "the playing audio source" },
  })
end

--@api-stub: lurek.docs.getCatalog
-- Return the current internal catalog as an ApiCatalog userdata.
-- Use after describe()/setParamInfo() to read back the merged result.
do  -- lurek.docs.getCatalog
  lurek.docs.scan()
  local cat = lurek.docs.getCatalog()
  lurek.log.info("docs", "internal catalog has " .. cat:entryCount() .. " entries")
end

--@api-stub: lurek.docs.resetCatalog
-- Clear all entries from the internal catalog.
-- Call between independent doc-generation runs to avoid stale leftovers.
do  -- lurek.docs.resetCatalog
  lurek.docs.scan()
  lurek.docs.resetCatalog()
  assert(lurek.docs.getCatalog():entryCount() == 0, "catalog should be empty")
end

--@api-stub: lurek.docs.validate
-- Validate catalog completeness against the live lurek.* bindings.
-- Run as a CI gate to fail the build when docs drift from the engine.
do  -- lurek.docs.validate
  local catalog = lurek.docs.loadAll("docs/api")
  local report = lurek.docs.validate(catalog)
  if not report:isValid() then
    lurek.log.error("docs", "missing " .. report:missingCount() .. " entries")
  end
end

--@api-stub: lurek.docs.validateModule
-- Validate a single module against the live lurek.<module>.* bindings.
-- Faster than full validate() while iterating on one module's docs.
do  -- lurek.docs.validateModule
  local catalog = lurek.docs.loadToml("docs/api/audio.toml")
  local report = lurek.docs.validateModule("audio", catalog)
  for _, name in ipairs(report:getMissing()) do
    lurek.log.warn("audio-docs", "undocumented: " .. name)
  end
end

--@api-stub: lurek.docs.checkStaleness
-- Compare catalog entries against source files in a directory for staleness.
-- Use to flag TOML entries whose backing Rust file has changed since last export.
do  -- lurek.docs.checkStaleness
  local catalog = lurek.docs.loadAll("docs/api")
  local result = lurek.docs.checkStaleness(catalog, "src/lua_api")
  lurek.log.info("docs", "scanned " .. #result.current .. " source files")
end

--@api-stub: lurek.docs.quality
-- Calculate quality metrics for a catalog or the internal catalog.
-- Use the score to gate releases on a minimum API documentation grade.
do  -- lurek.docs.quality
  local catalog = lurek.docs.loadAll("docs/api")
  local q = lurek.docs.quality(catalog)
  lurek.log.info("docs", string.format("overall %.2f (%s)", q:getOverallScore(), q:getGrade()))
end

--@api-stub: lurek.docs.qualityModule
-- Calculate quality metrics for a single module.
-- Useful for per-team dashboards where each owner only cares about their module.
do  -- lurek.docs.qualityModule
  local catalog = lurek.docs.loadAll("docs/api")
  local q = lurek.docs.qualityModule("audio", catalog)
  lurek.log.info("audio-docs", "audio module grade: " .. q:getGrade())
end

--@api-stub: lurek.docs.coverage
-- Return (documented_count, total_live_count) coverage tuple.
-- Cheap progress signal during incremental doc-writing sessions.
do  -- lurek.docs.coverage
  local catalog = lurek.docs.loadAll("docs/api")
  local documented, total = lurek.docs.coverage(catalog)
  lurek.log.info("docs", string.format("coverage %d/%d", documented, total))
end

--@api-stub: lurek.docs.coverageModule
-- Return (documented_count, total_live_count) for a single module.
-- Lets writers track one module without re-scanning the whole engine surface.
do  -- lurek.docs.coverageModule
  local catalog = lurek.docs.loadToml("docs/api/audio.toml")
  local documented, total = lurek.docs.coverageModule("audio", catalog)
  lurek.log.info("audio-docs", string.format("audio %d/%d", documented, total))
end

--@api-stub: lurek.docs.exportCompletions
-- Export VS Code IntelliSense completions JSON to a file.
-- The VS Code extension reads this file at activation to populate suggestions.
do  -- lurek.docs.exportCompletions
  local catalog = lurek.docs.scan()
  lurek.docs.exportCompletions(catalog, "build/vscode/completions.json")
  lurek.log.info("docs", "wrote completions.json")
end

--@api-stub: lurek.docs.exportHover
-- Export VS Code hover JSON to a file.
-- Pair with exportCompletions for full editor tooltip support.
do  -- lurek.docs.exportHover
  local catalog = lurek.docs.scan()
  lurek.docs.exportHover(catalog, "build/vscode/hover.json")
  lurek.log.info("docs", "wrote hover.json")
end

--@api-stub: lurek.docs.exportSignatures
-- Export VS Code signature-help JSON to a file.
-- Powers the parameter-hint popup that appears after typing the opening paren.
do  -- lurek.docs.exportSignatures
  local catalog = lurek.docs.scan()
  lurek.docs.exportSignatures(catalog, "build/vscode/signatures.json")
  lurek.log.info("docs", "wrote signatures.json")
end

--@api-stub: lurek.docs.exportAll
-- Export completions.json, hover.json, and signatures.json to a directory.
-- One-call shortcut for the full editor-support bundle.
do  -- lurek.docs.exportAll
  local catalog = lurek.docs.scan()
  lurek.docs.exportAll(catalog, "build/vscode")
  lurek.log.info("docs", "wrote full editor bundle")
end

--@api-stub: lurek.docs.exportMarkdown
-- Export a Markdown API reference file.
-- Drop into docs/API/ for the user-facing reference shipped with the engine.
do  -- lurek.docs.exportMarkdown
  local catalog = lurek.docs.loadAll("docs/api")
  lurek.docs.exportMarkdown(catalog, "docs/API/lua-api.md")
  lurek.log.info("docs", "regenerated lua-api.md")
end

--@api-stub: lurek.docs.exportCheatsheet
-- Export a one-line-per-function plain-text cheatsheet.
-- Handy for grep-able offline reference; ships in dist alongside the binary.
do  -- lurek.docs.exportCheatsheet
  local catalog = lurek.docs.scan()
  lurek.docs.exportCheatsheet(catalog, "build/cheatsheet.txt")
  lurek.log.info("docs", "wrote cheatsheet.txt")
end

--@api-stub: lurek.docs.schema
-- Creates a Schema validator from a rules table.
-- Use to validate game config or save-data tables before consuming them.
do  -- lurek.docs.schema
  local schema = lurek.docs.schema({
    name  = { type = "string", required = true, minLen = 1 },
    level = { type = "integer", required = true, min = 1, max = 99 },
    class = { type = "string", enum = { "warrior", "mage", "rogue" } },
  }, "PlayerSave")
  schema:assert({ name = "Hero", level = 1, class = "warrior" })
end

--@api-stub: lurek.docs.reflectLive
-- Walks the live lurek.* Lua table and returns a structured reflection of all.
-- Use for editor tooling that needs the runtime API shape without TOML metadata.
do  -- lurek.docs.reflectLive
  local audio_only = lurek.docs.reflectLive("audio")
  for _, item in ipairs(audio_only.audio or {}) do
    lurek.log.debug("reflect", item.name .. " (" .. item.type .. ")")
  end
end

--@api-stub: lurek.docs.reflectTable
-- Reflects any Lua table, returning a structure describing its keys,.
-- Useful for inspecting plain Lua modules (not just lurek.*) at runtime.
do  -- lurek.docs.reflectTable
  local mod = { greet = function(_) end, version = "1.0", count = 3 }
  local items = lurek.docs.reflectTable(mod, "mymod")
  for _, it in ipairs(items) do
    lurek.log.debug("reflect", it.qualifiedName .. " : " .. it.type)
  end
end

-- ── Schema methods ──

--@api-stub: Schema:validate
-- Validates a Lua table against the schema.
-- Returns a list of error tables; empty list means data is valid.
do  -- Schema:validate
  local schema = lurek.docs.schema({ hp = { type = "integer", required = true, min = 0 } }, "Stats")
  local errors = schema:validate({ hp = -5 })
  if #errors > 0 then
    lurek.log.warn("schema", "got " .. #errors .. " validation errors")
  end
end

--@api-stub: Schema:check
-- Returns true when the data passes all schema rules.
-- Cheaper than validate() when you only need a yes/no gate.
do  -- Schema:check
  local schema = lurek.docs.schema({ port = { type = "integer", min = 1, max = 65535 } }, "Net")
  if not schema:check({ port = 8080 }) then
    lurek.log.error("net", "invalid network config")
  end
end

--@api-stub: Schema:assert
-- Validates data and throws a Lua error on failure with all error messages joined.
-- Best for startup-time configuration where invalid data should halt the game.
do  -- Schema:assert
  local schema = lurek.docs.schema({ width = { type = "integer", required = true, min = 1 } }, "Window")
  schema:assert({ width = 1280 })
  lurek.log.info("config", "window config validated")
end

--@api-stub: Schema:getName
-- Returns the name identifier of this API schema group.
-- Use in error messages to identify which schema rejected the data.
do  -- Schema:getName
  local schema = lurek.docs.schema({ x = { type = "number" } }, "Point")
  local label = schema:getName()
  lurek.log.debug("schema", "loaded schema: " .. label)
end

--@api-stub: Schema:getFields
-- Returns a table of declared field names.
-- Use to drive UI form generation or report which fields a schema covers.
do  -- Schema:getFields
  local schema = lurek.docs.schema({ a = { type = "string" }, b = { type = "number" } }, "AB")
  for _, field in ipairs(schema:getFields()) do
    lurek.log.debug("schema", "field: " .. field)
  end
end

-- ── DocEntry methods ──

--@api-stub: DocEntry:getName
-- Returns the symbol name for this documentation entry.
-- The leaf identifier (e.g. "play") without the lurek.<module>. prefix.
do  -- DocEntry:getName
  local catalog = lurek.docs.scanModule("audio")
  local entry = catalog:getEntries()[1]
  if entry then lurek.log.debug("docs", "first audio entry: " .. entry:getName()) end
end

--@api-stub: DocEntry:getQualifiedName
-- Returns the qualified name.
-- Use when joining catalogs or pointing users to the canonical lurek.* path.
do  -- DocEntry:getQualifiedName
  local catalog = lurek.docs.scan()
  for _, e in ipairs(catalog:getEntries()) do
    if e:getName() == "info" then lurek.log.debug("docs", e:getQualifiedName()) end
  end
end

--@api-stub: DocEntry:getModule
-- Returns the Lua module name this entry belongs to (e.g.
-- Group entries by module to render per-namespace doc pages.
do  -- DocEntry:getModule
  local catalog = lurek.docs.scan()
  local first = catalog:getEntries()[1]
  if first then lurek.log.debug("docs", "module: " .. first:getModule()) end
end

--@api-stub: DocEntry:getKind
-- Returns the kind tag for this entry (e.g.
-- Distinguishes "function" / "value" / "type" / "method" for doc renderers.
do  -- DocEntry:getKind
  local catalog = lurek.docs.scan()
  for _, e in ipairs(catalog:getEntries()) do
    if e:getKind() == "type" then lurek.log.debug("docs", "type: " .. e:getQualifiedName()) end
  end
end

--@api-stub: DocEntry:getDescription
-- Returns the human-readable description text for this documentation entry.
-- Use to render hover tooltips or one-line summaries in editor UIs.
do  -- DocEntry:getDescription
  local catalog = lurek.docs.loadToml("docs/api/audio.toml")
  local entry = catalog:getEntry("lurek.audio.play")
  if entry then lurek.log.info("docs", entry:getDescription()) end
end

--@api-stub: DocEntry:getParameters
-- Returns the parameters as a table of `{name, type, description, optional, default?}` records.
-- Drive parameter-hint popups or validate caller arguments by type.
do  -- DocEntry:getParameters
  local catalog = lurek.docs.loadToml("docs/api/audio.toml")
  local entry = catalog:getEntry("lurek.audio.play")
  if entry then
    for _, p in ipairs(entry:getParameters()) do
      lurek.log.debug("docs", p.name .. " : " .. p.type)
    end
  end
end

--@api-stub: DocEntry:getReturns
-- Returns the return values as a table of `{type, description}` records.
-- Lets editor tooling chain method calls on the documented return type.
do  -- DocEntry:getReturns
  local catalog = lurek.docs.loadToml("docs/api/audio.toml")
  local entry = catalog:getEntry("lurek.audio.play")
  if entry then
    for _, r in ipairs(entry:getReturns()) do
      lurek.log.debug("docs", "returns " .. r.type)
    end
  end
end

--@api-stub: DocEntry:getExample
-- Returns the example snippet, or nil.
-- Display in hover tooltips and on generated reference pages.
do  -- DocEntry:getExample
  local catalog = lurek.docs.loadAll("docs/api")
  local entry = catalog:getEntry("lurek.audio.play")
  local snippet = entry and entry:getExample()
  if snippet then lurek.log.info("docs", "example:\n" .. snippet) end
end

--@api-stub: DocEntry:getSince
-- Returns the since version string, or nil.
-- Use to mark new APIs in the changelog or hide them from older docs builds.
do  -- DocEntry:getSince
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    local v = e:getSince()
    if v == "0.6.0" then lurek.log.info("docs", "new in 0.6: " .. e:getQualifiedName()) end
  end
end

--@api-stub: DocEntry:getDeprecated
-- Returns the deprecation message, or nil.
-- Surface deprecation warnings in the IDE or at startup for older games.
do  -- DocEntry:getDeprecated
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    local msg = e:getDeprecated()
    if msg then lurek.log.warn("deprecated", e:getQualifiedName() .. " — " .. msg) end
  end
end

--@api-stub: DocEntry:getScore
-- Returns the quality score in [0,1].
-- Combine with the entry list to surface the worst-documented APIs first.
do  -- DocEntry:getScore
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    if e:getScore() < 0.5 then lurek.log.warn("docs", "low score: " .. e:getQualifiedName()) end
  end
end

--@api-stub: DocEntry:hasDescription
-- Returns true when the entry has a non-empty description.
-- Filter undocumented entries before exporting public reference pages.
do  -- DocEntry:hasDescription
  local catalog = lurek.docs.scan()
  local missing = 0
  for _, e in ipairs(catalog:getEntries()) do
    if not e:hasDescription() then missing = missing + 1 end
  end
  lurek.log.info("docs", missing .. " entries missing descriptions")
end

--@api-stub: DocEntry:hasParameters
-- Returns true when the entry has at least one parameter.
-- Useful when generating signature-help only for callable entries with parameters.
do  -- DocEntry:hasParameters
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    if e:getKind() == "function" and not e:hasParameters() then
      lurek.log.debug("docs", "no params: " .. e:getQualifiedName())
    end
  end
end

--@api-stub: DocEntry:hasReturnType
-- Returns true when the entry declares at least one return type.
-- Helps flag functions whose return shape was never documented.
do  -- DocEntry:hasReturnType
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    if e:getKind() == "function" and not e:hasReturnType() then
      lurek.log.debug("docs", "no return info: " .. e:getQualifiedName())
    end
  end
end

--@api-stub: DocEntry:hasExample
-- Returns true when the entry has an example snippet.
-- Use to ensure every public API ships with a runnable usage snippet.
do  -- DocEntry:hasExample
  local catalog = lurek.docs.loadAll("docs/api")
  local without = 0
  for _, e in ipairs(catalog:getEntries()) do
    if not e:hasExample() then without = without + 1 end
  end
  lurek.log.info("docs", without .. " entries lack examples")
end

-- ── ApiCatalog methods ──

--@api-stub: ApiCatalog:getModules
-- Returns a sorted list of module names present in the catalog.
-- Iterate the result to render a per-module table of contents.
do  -- ApiCatalog:getModules
  local catalog = lurek.docs.scan()
  for _, name in ipairs(catalog:getModules()) do
    lurek.log.debug("docs", "module: " .. name)
  end
end

--@api-stub: ApiCatalog:getEntries
-- Returns all entries, optionally filtered to a single module.
-- Pass a module name to scope output when generating per-namespace pages.
do  -- ApiCatalog:getEntries
  local catalog = lurek.docs.scan()
  local audio_entries = catalog:getEntries("audio")
  lurek.log.info("docs", "audio has " .. #audio_entries .. " entries")
end

--@api-stub: ApiCatalog:getEntry
-- Returns a single entry by qualified name, or nil.
-- Use when you already know the API path and need its metadata.
do  -- ApiCatalog:getEntry
  local catalog = lurek.docs.scan()
  local entry = catalog:getEntry("lurek.audio.play")
  if entry then lurek.log.info("docs", "found: " .. entry:getQualifiedName()) end
end

--@api-stub: ApiCatalog:getTypes
-- Returns the names of all entries with kind "type" in the given module.
-- Useful for generating "Types" sections in module reference pages.
do  -- ApiCatalog:getTypes
  local catalog = lurek.docs.loadAll("docs/api")
  for _, t in ipairs(catalog:getTypes("audio")) do
    lurek.log.debug("docs", "audio type: " .. t)
  end
end

--@api-stub: ApiCatalog:getTypeMethods
-- Returns entries that are methods of the given type qualified name.
-- Pair with getTypes() to render full per-type method lists.
do  -- ApiCatalog:getTypeMethods
  local catalog = lurek.docs.loadAll("docs/api")
  for _, m in ipairs(catalog:getTypeMethods("lurek.audio.Source")) do
    lurek.log.debug("docs", "Source method: " .. m:getName())
  end
end

--@api-stub: ApiCatalog:entryCount
-- Returns the number of entries, optionally scoped to a module.
-- Quick sanity check after scan() or loadAll() to confirm population.
do  -- ApiCatalog:entryCount
  local catalog = lurek.docs.scan()
  local total = catalog:entryCount()
  local audio = catalog:entryCount("audio")
  lurek.log.info("docs", string.format("total %d, audio %d", total, audio))
end

--@api-stub: ApiCatalog:merge
-- Returns a new catalog that is the union of this and another catalog, with other overriding duplicates.
-- Layer hand-authored TOML on top of a reflected scan to fill in missing metadata.
do  -- ApiCatalog:merge
  local live = lurek.docs.scan()
  local toml = lurek.docs.loadAll("docs/api")
  local merged = live:merge(toml)
  lurek.log.info("docs", "merged " .. merged:entryCount() .. " entries")
end

--@api-stub: ApiCatalog:filter
-- Returns a new catalog containing only entries for which predicate returns true.
-- Use to extract subsets like "all deprecated APIs" or "all functions over 5 params".
do  -- ApiCatalog:filter
  local catalog = lurek.docs.loadAll("docs/api")
  local deprecated = catalog:filter(function(e) return e:getDeprecated() ~= nil end)
  lurek.log.info("docs", deprecated:entryCount() .. " deprecated entries")
end

--@api-stub: ApiCatalog:search
-- Returns a table of entries whose name, qualified name, or description contains query.
-- Powers in-editor "find API by keyword" features.
do  -- ApiCatalog:search
  local catalog = lurek.docs.scan()
  for _, e in ipairs(catalog:search("play")) do
    lurek.log.debug("docs", "match: " .. e:getQualifiedName())
  end
end

--@api-stub: ApiCatalog:toTable
-- Converts the catalog to a plain Lua table array.
-- Use when feeding the catalog into other Lua tools that expect raw tables.
do  -- ApiCatalog:toTable
  local catalog = lurek.docs.scan()
  local raw = catalog:toTable()
  lurek.log.info("docs", "raw catalog has " .. #raw .. " rows")
end

--@api-stub: ApiCatalog:toJSON
-- Serialises the catalog to a pretty-printed JSON string.
-- Drop directly into a build artifact for downstream tooling consumption.
do  -- ApiCatalog:toJSON
  local catalog = lurek.docs.scan()
  local json = catalog:toJSON()
  lurek.fs.write("build/api-catalog.json", json)
end

-- ── ValidationReport methods ──

--@api-stub: ValidationReport:isValid
-- Returns true when the report has no missing entries.
-- Use as the binary CI gate for the docs build.
do  -- ValidationReport:isValid
  local catalog = lurek.docs.loadAll("docs/api")
  local report = lurek.docs.validate(catalog)
  if not report:isValid() then lurek.log.error("docs", "validation failed") end
end

--@api-stub: ValidationReport:getMissing
-- Returns the list of qualified names present in the live API but missing from the catalog.
-- Iterate to print actionable TODO lines for the doc writer.
do  -- ValidationReport:getMissing
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  for _, name in ipairs(report:getMissing()) do
    lurek.log.warn("docs", "TODO: document " .. name)
  end
end

--@api-stub: ValidationReport:getPhantom
-- Returns the list of qualified names in the catalog that are not present in the live API.
-- Phantom entries point to deleted or renamed APIs that need TOML cleanup.
do  -- ValidationReport:getPhantom
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  for _, name in ipairs(report:getPhantom()) do
    lurek.log.warn("docs", "remove stale doc: " .. name)
  end
end

--@api-stub: ValidationReport:getIncomplete
-- Returns the list of qualified names whose catalog entry is incomplete.
-- Incomplete = empty description or no parameter/return info on a function.
do  -- ValidationReport:getIncomplete
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  for _, name in ipairs(report:getIncomplete()) do
    lurek.log.info("docs", "needs more detail: " .. name)
  end
end

--@api-stub: ValidationReport:missingCount
-- Returns the count of missing entries.
-- Use as a numeric metric in build dashboards.
do  -- ValidationReport:missingCount
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  if report:missingCount() > 0 then
    lurek.log.error("docs", "missing " .. report:missingCount() .. " doc entries")
  end
end

--@api-stub: ValidationReport:phantomCount
-- Returns the count of phantom entries.
-- Track this across builds to ensure doc cleanup keeps pace with API removals.
do  -- ValidationReport:phantomCount
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", report:phantomCount() .. " phantom doc entries")
end

--@api-stub: ValidationReport:incompleteCount
-- Returns the count of incomplete entries.
-- Pair with missing/phantom counts for a single-line summary line.
do  -- ValidationReport:incompleteCount
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", report:incompleteCount() .. " incomplete doc entries")
end

--@api-stub: ValidationReport:getSummary
-- Returns a single-line summary of the validation results.
-- Ideal for printing at the end of a CI step or to stdout.
do  -- ValidationReport:getSummary
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", report:getSummary())
end

--@api-stub: ValidationReport:toTable
-- Converts the report to a plain Lua table.
-- Use when feeding the report into custom dashboards or filters.
do  -- ValidationReport:toTable
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  local data = report:toTable()
  lurek.log.info("docs", "missing rows: " .. #(data.missing or {}))
end

--@api-stub: ValidationReport:toJSON
-- Serialises the report to a pretty-printed JSON string.
-- Persist for build artifacts or upload to an external dashboard.
do  -- ValidationReport:toJSON
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  lurek.fs.write("build/docs-validation.json", report:toJSON())
end

-- ── QualityReport methods ──

--@api-stub: QualityReport:getOverallScore
-- Returns the overall quality score in [0,1].
-- Use as a numeric gate (e.g. fail builds below 0.8).
do  -- QualityReport:getOverallScore
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  if q:getOverallScore() < 0.8 then lurek.log.warn("docs", "quality below threshold") end
end

--@api-stub: QualityReport:getGrade
-- Returns the letter grade for the overall score.
-- Friendlier than the raw score for status badges and CI logs.
do  -- QualityReport:getGrade
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", "docs grade: " .. q:getGrade())
end

--@api-stub: QualityReport:getModuleScores
-- Returns a table mapping module name to its average quality score.
-- Surface per-module scores in a dashboard so each owner can target their weakest area.
do  -- QualityReport:getModuleScores
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  for module, score in pairs(q:getModuleScores()) do
    lurek.log.debug("docs", string.format("%s : %.2f", module, score))
  end
end

--@api-stub: QualityReport:getWorst
-- Returns up to count entries with the lowest quality scores.
-- The natural input to a "fix-me-first" doc-writing queue.
do  -- QualityReport:getWorst
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  for _, e in ipairs(q:getWorst(10)) do
    lurek.log.warn("docs", "worst: " .. e:getQualifiedName())
  end
end

--@api-stub: QualityReport:getBest
-- Returns up to count entries with the highest quality scores.
-- Use the top entries as templates when filling in lower-scoring ones.
do  -- QualityReport:getBest
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  for _, e in ipairs(q:getBest(5)) do
    lurek.log.info("docs", "exemplar: " .. e:getQualifiedName())
  end
end

--@api-stub: QualityReport:getByGrade
-- Returns entries whose grade exactly matches the given letter grade.
-- Use to drill into all "C" entries when targeting one tier of improvement.
do  -- QualityReport:getByGrade
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  for _, e in ipairs(q:getByGrade("C")) do
    lurek.log.info("docs", "grade C: " .. e:getQualifiedName())
  end
end

--@api-stub: QualityReport:getSummary
-- Returns a multi-line human-readable summary of quality by module.
-- Print at the end of a docs build to give writers a friendly recap.
do  -- QualityReport:getSummary
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", q:getSummary())
end

--@api-stub: QualityReport:toTable
-- Converts the quality report to a plain Lua table.
-- Use when piping into bespoke Lua post-processing or reporting code.
do  -- QualityReport:toTable
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  local data = q:toTable()
  lurek.log.info("docs", "table overall: " .. tostring(data.overall_score))
end

--@api-stub: QualityReport:toJSON
-- Serialises the quality report to a pretty-printed JSON string.
-- Persist as a build artifact for the docs dashboard to consume.
do  -- QualityReport:toJSON
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  lurek.fs.write("build/docs-quality.json", q:toJSON())
end

