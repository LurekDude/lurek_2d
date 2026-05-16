-- content/examples/docs.lua
-- lurek.docs API examples.
-- Run: cargo run -- content/examples/docs.lua

--@api-stub: lurek.docs.scan
-- Reflects the live `lurek` table and builds a catalog of callable APIs
do
  local catalog = lurek.docs.scan()
  local count = catalog:entryCount()
  lurek.log.info("docs", "scanned " .. count .. " live API entries")
end

--@api-stub: lurek.docs.scanModule
-- Reflects one live `lurek
do
  local audio_cat = lurek.docs.scanModule("audio")
  for _, entry in ipairs(audio_cat:getEntries()) do
    lurek.log.debug("audio-api", entry:getQualifiedName())
  end
end

--@api-stub: lurek.docs.loadToml
-- Loads a TOML documentation catalog file and converts its entries into an API catalog
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok and catalog:entryCount() == 0 then
    lurek.log.warn("docs", "audio.toml had no entries")
  end
end

--@api-stub: lurek.docs.loadAll
-- Loads all TOML documentation catalog files from a directory and combines their entries
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local mods = catalog:getModules()
    lurek.log.info("docs", "loaded " .. #mods .. " documented modules")
  end
end

--@api-stub: lurek.docs.describe
-- Adds or updates the description for one editable catalog entry
do
  lurek.docs.scan()
  lurek.docs.describe("lurek.audio.play", "Play a sound source by name.")
  lurek.docs.describe("lurek.audio.stop", "Stop a currently playing source.")
end

--@api-stub: lurek.docs.setParamInfo
-- Replaces parameter metadata for one editable catalog entry
do
  lurek.docs.scan()
  lurek.docs.setParamInfo("lurek.audio.play", {
    { name = "name", type = "string", description = "source id", optional = false },
    { name = "loop", type = "boolean", description = "loop on end", optional = true, default = false },
  })
end

--@api-stub: lurek.docs.setReturnInfo
-- Replaces return-value metadata for one editable catalog entry
do
  lurek.docs.scan()
  lurek.docs.setReturnInfo("lurek.audio.play", {
    { type = "Source", description = "the playing audio source" },
  })
end

--@api-stub: lurek.docs.getCatalog
-- Returns the editable in-memory documentation catalog
do
  lurek.docs.scan()
  local cat = lurek.docs.getCatalog()
  lurek.log.info("docs", "internal catalog has " .. cat:entryCount() .. " entries")
end

--@api-stub: lurek.docs.resetCatalog
-- Clears the editable in-memory documentation catalog
do
  lurek.docs.scan()
  lurek.docs.resetCatalog()
  assert(lurek.docs.getCatalog():entryCount() == 0, "catalog should be empty")
end

--@api-stub: lurek.docs.validate
-- Compares a documentation catalog with the live reflected `lurek` API table
do
  local catalog = lurek.docs.loadAll("docs/api")
  local report = lurek.docs.validate(catalog)
  if not report:isValid() then
    lurek.log.error("docs", "missing " .. report:missingCount() .. " entries")
  end
end

--@api-stub: lurek.docs.validateModule
-- Compares one module's documentation catalog entries with the live reflected module table
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local report = lurek.docs.validateModule("audio", catalog)
    for _, name in ipairs(report:getMissing()) do
      lurek.log.warn("audio-docs", "undocumented: " .. name)
    end
  end
end

--@api-stub: lurek.docs.checkStaleness
-- Lists source files in a directory for simple documentation staleness checks
do
  local catalog = lurek.docs.loadAll("docs/api")
  local result = lurek.docs.checkStaleness(catalog, "src/lua_api")
  lurek.log.info("docs", "scanned " .. #result.current .. " source files")
end

--@api-stub: lurek.docs.quality
-- Computes documentation quality for a supplied catalog or the editable in-memory catalog
do
  local catalog = lurek.docs.loadAll("docs/api")
  local q = lurek.docs.quality(catalog)
  lurek.log.info("docs", string.format("overall %.2f (%s)", q:getOverallScore(), q:getGrade()))
end

--@api-stub: lurek.docs.qualityModule
-- Computes documentation quality for entries belonging to one module
do
  local catalog = lurek.docs.loadAll("docs/api")
  local q = lurek.docs.qualityModule("audio", catalog)
  lurek.log.info("audio-docs", "audio module grade: " .. q:getGrade())
end

--@api-stub: lurek.docs.coverage
-- Returns documented and live API counts for the full `lurek` table
do
  local catalog = lurek.docs.loadAll("docs/api")
  local documented, total = lurek.docs.coverage(catalog)
  lurek.log.info("docs", string.format("coverage %d/%d", documented, total))
end

--@api-stub: lurek.docs.coverageModule
-- Returns documented and live API counts for one module
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local documented, total = lurek.docs.coverageModule("audio", catalog)
    lurek.log.info("audio-docs", string.format("audio %d/%d", documented, total))
  end
end

--@api-stub: lurek.docs.exportCompletions
-- Exports catalog completion metadata to a file
do
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportCompletions, catalog, "build/vscode/completions.json")
  lurek.log.info("docs", "wrote completions.json")
end

--@api-stub: lurek.docs.exportHover
-- Exports catalog hover metadata to a file
do
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportHover, catalog, "build/vscode/hover.json")
  lurek.log.info("docs", "wrote hover.json")
end

--@api-stub: lurek.docs.exportSignatures
-- Exports catalog signature metadata to a file
do
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportSignatures, catalog, "build/vscode/signatures.json")
  lurek.log.info("docs", "wrote signatures.json")
end

--@api-stub: lurek.docs.exportAll
-- Exports all editor documentation artifacts for a catalog into a directory
do
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportAll, catalog, "build/vscode")
  lurek.log.info("docs", "wrote full editor bundle")
end

--@api-stub: lurek.docs.exportMarkdown
-- Writes a Markdown API reference from catalog entries
do
  local catalog = lurek.docs.loadAll("docs/api")
  pcall(lurek.docs.exportMarkdown, catalog, "build/lua-api.md")
  lurek.log.info("docs", "regenerated lua-api.md")
end

--@api-stub: lurek.docs.exportCheatsheet
-- Writes a compact text cheatsheet from catalog entries
do
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportCheatsheet, catalog, "build/cheatsheet.txt")
  lurek.log.info("docs", "wrote cheatsheet.txt")
end

--@api-stub: lurek.docs.schema
-- Builds a schema validator from Lua table rules
do
  local schema = lurek.docs.schema({
    name  = { type = "string", required = true, minLen = 1 },
    level = { type = "integer", required = true, min = 1, max = 99 },
    class = { type = "string", enum = { "warrior", "mage", "rogue" } },
  }, "PlayerSave")
  schema:assert({ name = "Hero", level = 1, class = "warrior" })
end

--@api-stub: lurek.docs.schemaFromToml
-- Builds a schema validator from TOML schema text
do
  local schema_toml = [[
name = "PlayerSave"
strict = true

[rules.level]
type = "integer"
required = true
min = 1
max = 99
  ]]
  local schema = lurek.docs.schemaFromToml(schema_toml)
  schema:assert({ level = 10 })
end

--@api-stub: lurek.docs.reflectLive
-- Reflects live `lurek` module tables into plain name and type rows
do
  local audio_only = lurek.docs.reflectLive("audio")
  for _, item in ipairs(audio_only.audio or {}) do
    lurek.log.debug("reflect", item.name .. " (" .. item.type .. ")")
  end
end

--@api-stub: lurek.docs.reflectTable
-- Reflects an arbitrary Lua table into name, qualifiedName, and type rows
do
  local mod = { greet = function(_) end, version = "1.0", count = 3 }
  local items = lurek.docs.reflectTable(mod, "mymod")
  for _, it in ipairs(items) do
    lurek.log.debug("reflect", it.qualifiedName .. " : " .. it.type)
  end
end

-- Schema methods

--@api-stub: Schema:validate
-- Performs the validate operation on this schema.
do
  local schema = lurek.docs.schema({ hp = { type = "integer", required = true, min = 0 } }, "Stats")
  local result = schema:validate({ hp = -5 })
  local count = (type(result) == "table") and #result or (result and 0 or 1)
  if count > 0 then
    lurek.log.warn("schema", "got " .. count .. " validation errors")
  end
end

--@api-stub: Schema:check
-- Checks  on this schema and returns the result.
do
  local schema = lurek.docs.schema({ port = { type = "integer", min = 1, max = 65535 } }, "Net")
  if not schema:check({ port = 8080 }) then
    lurek.log.error("net", "invalid network config")
  end
end

--@api-stub: Schema:assert
-- Performs the assert operation on this schema.
do
  local schema = lurek.docs.schema({ width = { type = "integer", required = true, min = 1 } }, "Window")
  schema:assert({ width = 1280 })
  lurek.log.info("config", "window config validated")
end

--@api-stub: Schema:getName
-- Returns the name of this schema.
do
  local schema = lurek.docs.schema({ x = { type = "number" } }, "Point")
  local label = schema:getName()
  lurek.log.debug("schema", "loaded schema: " .. label)
end

--@api-stub: Schema:getFields
-- Returns the fields of this schema.
do
  local schema = lurek.docs.schema({ a = { type = "string" }, b = { type = "number" } }, "AB")
  for _, field in ipairs(schema:getFields()) do
    lurek.log.debug("schema", "field: " .. field)
  end
end

-- DocEntry methods

--@api-stub: DocEntry:getName
-- Returns the name of this doc entry.
do
  local catalog = lurek.docs.scanModule("audio")
  local entry = catalog:getEntries()[1]
  if entry then lurek.log.debug("docs", "first audio entry: " .. entry:getName()) end
end

--@api-stub: DocEntry:getQualifiedName
-- Returns the qualified name of this doc entry.
do
  local catalog = lurek.docs.scan()
  for _, e in ipairs(catalog:getEntries()) do
    if e:getName() == "info" then lurek.log.debug("docs", e:getQualifiedName()) end
  end
end

--@api-stub: DocEntry:getModule
-- Returns the module of this doc entry.
do
  local catalog = lurek.docs.scan()
  local first = catalog:getEntries()[1]
  if first then lurek.log.debug("docs", "module: " .. first:getModule()) end
end

--@api-stub: DocEntry:getKind
-- Returns the kind of this doc entry.
do
  local catalog = lurek.docs.scan()
  for _, e in ipairs(catalog:getEntries()) do
    if e:getKind() == "type" then lurek.log.debug("docs", "type: " .. e:getQualifiedName()) end
  end
end

--@api-stub: DocEntry:getDescription
-- Returns the description of this doc entry.
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local entry = catalog:getEntry("lurek.audio.play")
    if entry then lurek.log.info("docs", entry:getDescription()) end
  end
end

--@api-stub: DocEntry:getParameters
-- Returns the parameters of this doc entry.
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local entry = catalog:getEntry("lurek.audio.play")
    if entry then
      for _, p in ipairs(entry:getParameters()) do
        lurek.log.debug("docs", p.name .. " : " .. p.type)
      end
    end
  end
end

--@api-stub: DocEntry:getReturns
-- Returns the returns of this doc entry.
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local entry = catalog:getEntry("lurek.audio.play")
    if entry then
      for _, r in ipairs(entry:getReturns()) do
        lurek.log.debug("docs", "returns " .. r.type)
      end
    end
  end
end

--@api-stub: DocEntry:getExample
-- Returns the example of this doc entry.
do
  local catalog = lurek.docs.loadAll("docs/api")
  local entry = catalog:getEntry("lurek.audio.play")
  local snippet = entry and entry:getExample()
  if snippet then lurek.log.info("docs", "example:\n" .. snippet) end
end

--@api-stub: DocEntry:getSince
-- Returns the since of this doc entry.
do
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    local v = e:getSince()
    if v == "0.6.0" then lurek.log.info("docs", "new in 0.6: " .. e:getQualifiedName()) end
  end
end

--@api-stub: DocEntry:getDeprecated
-- Returns the deprecated of this doc entry.
do
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    local msg = e:getDeprecated()
    if msg then lurek.log.warn("deprecated", e:getQualifiedName() .. " â€” " .. msg) end
  end
end

--@api-stub: DocEntry:getScore
-- Returns the score of this doc entry.
do
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    if e:getScore() < 0.5 then lurek.log.warn("docs", "low score: " .. e:getQualifiedName()) end
  end
end

--@api-stub: DocEntry:hasDescription
-- Returns true if this doc entry has a description.
do
  local catalog = lurek.docs.scan()
  local missing = 0
  for _, e in ipairs(catalog:getEntries()) do
    if not e:hasDescription() then missing = missing + 1 end
  end
  lurek.log.info("docs", missing .. " entries missing descriptions")
end

--@api-stub: DocEntry:hasParameters
-- Returns true if this doc entry has a parameters.
do
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    if e:getKind() == "function" and not e:hasParameters() then
      lurek.log.debug("docs", "no params: " .. e:getQualifiedName())
    end
  end
end

--@api-stub: DocEntry:hasReturnType
-- Returns true if this doc entry has a return type.
do
  local catalog = lurek.docs.loadAll("docs/api")
  for _, e in ipairs(catalog:getEntries()) do
    if e:getKind() == "function" and not e:hasReturnType() then
      lurek.log.debug("docs", "no return info: " .. e:getQualifiedName())
    end
  end
end

--@api-stub: DocEntry:hasExample
-- Returns true if this doc entry has a example.
do
  local catalog = lurek.docs.loadAll("docs/api")
  local without = 0
  for _, e in ipairs(catalog:getEntries()) do
    if not e:hasExample() then without = without + 1 end
  end
  lurek.log.info("docs", without .. " entries lack examples")
end

-- ApiCatalog methods

--@api-stub: ApiCatalog:getModules
-- Returns the modules of this api catalog.
do
  local catalog = lurek.docs.scan()
  for _, name in ipairs(catalog:getModules()) do
    lurek.log.debug("docs", "module: " .. name)
  end
end

--@api-stub: ApiCatalog:getEntries
-- Returns the entries of this api catalog.
do
  local catalog = lurek.docs.scan()
  local audio_entries = catalog:getEntries("audio")
  lurek.log.info("docs", "audio has " .. #audio_entries .. " entries")
end

--@api-stub: ApiCatalog:getEntry
-- Returns the entry of this api catalog.
do
  local catalog = lurek.docs.scan()
  local entry = catalog:getEntry("lurek.audio.play")
  if entry then lurek.log.info("docs", "found: " .. entry:getQualifiedName()) end
end

--@api-stub: ApiCatalog:getTypes
-- Returns the types of this api catalog.
do
  local catalog = lurek.docs.loadAll("docs/api")
  for _, t in ipairs(catalog:getTypes("audio")) do
    lurek.log.debug("docs", "audio type: " .. t)
  end
end

--@api-stub: ApiCatalog:getTypeMethods
-- Returns the type methods of this api catalog.
do
  local catalog = lurek.docs.loadAll("docs/api")
  for _, m in ipairs(catalog:getTypeMethods("lurek.audio.Source")) do
    lurek.log.debug("docs", "Source method: " .. m:getName())
  end
end

--@api-stub: ApiCatalog:entryCount
-- Performs the entry count operation on this api catalog.
do
  local catalog = lurek.docs.scan()
  local total = catalog:entryCount()
  local audio = catalog:entryCount("audio")
  lurek.log.info("docs", string.format("total %d, audio %d", total, audio))
end

--@api-stub: ApiCatalog:merge
-- Performs the merge operation on this api catalog.
do
  local live = lurek.docs.scan()
  local toml = lurek.docs.loadAll("docs/api")
  local merged = live:merge(toml)
  lurek.log.info("docs", "merged " .. merged:entryCount() .. " entries")
end

--@api-stub: ApiCatalog:filter
-- Performs the filter operation on this api catalog.
do
  local catalog = lurek.docs.loadAll("docs/api")
  local deprecated = catalog:filter(function(e) return e:getDeprecated() ~= nil end)
  lurek.log.info("docs", deprecated:entryCount() .. " deprecated entries")
end

--@api-stub: ApiCatalog:search
-- Performs the search operation on this api catalog.
do
  local catalog = lurek.docs.scan()
  for _, e in ipairs(catalog:search("play")) do
    lurek.log.debug("docs", "match: " .. e:getQualifiedName())
  end
end

--@api-stub: ApiCatalog:toTable
-- Performs the to table operation on this api catalog.
do
  local catalog = lurek.docs.scan()
  local raw = catalog:toTable()
  lurek.log.info("docs", "raw catalog has " .. #raw .. " rows")
end

--@api-stub: ApiCatalog:toJSON
-- Performs the to json operation on this api catalog.
do
  local catalog = lurek.docs.scan()
  local json = catalog:toJSON()
  pcall(function() lurek.fs.write("build/api-catalog.json", json) end)
end

-- ValidationReport methods

--@api-stub: ValidationReport:isValid
-- Returns true if this validation report valid.
do
  local catalog = lurek.docs.loadAll("docs/api")
  local report = lurek.docs.validate(catalog)
  if not report:isValid() then lurek.log.error("docs", "validation failed") end
end

--@api-stub: ValidationReport:getMissing
-- Returns the missing of this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  for _, name in ipairs(report:getMissing()) do
    lurek.log.warn("docs", "missing docs: " .. name)
  end
end

--@api-stub: ValidationReport:getPhantom
-- Returns the phantom of this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  for _, name in ipairs(report:getPhantom()) do
    lurek.log.warn("docs", "remove stale doc: " .. name)
  end
end

--@api-stub: ValidationReport:getIncomplete
-- Returns the incomplete of this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  for _, name in ipairs(report:getIncomplete()) do
    lurek.log.info("docs", "needs more detail: " .. name)
  end
end

--@api-stub: ValidationReport:missingCount
-- Performs the missing count operation on this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  if report:missingCount() > 0 then
    lurek.log.error("docs", "missing " .. report:missingCount() .. " doc entries")
  end
end

--@api-stub: ValidationReport:phantomCount
-- Performs the phantom count operation on this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", report:phantomCount() .. " phantom doc entries")
end

--@api-stub: ValidationReport:incompleteCount
-- Performs the incomplete count operation on this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", report:incompleteCount() .. " incomplete doc entries")
end

--@api-stub: ValidationReport:getSummary
-- Returns the summary of this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", report:getSummary())
end

--@api-stub: ValidationReport:toTable
-- Performs the to table operation on this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  local data = report:toTable()
  lurek.log.info("docs", "missing rows: " .. #(data.missing or {}))
end

--@api-stub: ValidationReport:toJSON
-- Performs the to json operation on this validation report.
do
  local report = lurek.docs.validate(lurek.docs.loadAll("docs/api"))
  pcall(function() lurek.fs.write("build/docs-validation.json", report:toJSON()) end)
end

-- QualityReport methods

--@api-stub: QualityReport:getOverallScore
-- Returns the overall score of this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  if q:getOverallScore() < 0.8 then lurek.log.warn("docs", "quality below threshold") end
end

--@api-stub: QualityReport:getGrade
-- Returns the grade of this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", "docs grade: " .. q:getGrade())
end

--@api-stub: QualityReport:getModuleScores
-- Returns the module scores of this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  for module, score in pairs(q:getModuleScores()) do
    lurek.log.debug("docs", string.format("%s : %.2f", module, score))
  end
end

--@api-stub: QualityReport:getWorst
-- Returns the worst of this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  for _, e in ipairs(q:getWorst(10)) do
    lurek.log.warn("docs", "worst: " .. e:getQualifiedName())
  end
end

--@api-stub: QualityReport:getBest
-- Returns the best of this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  for _, e in ipairs(q:getBest(5)) do
    lurek.log.info("docs", "exemplar: " .. e:getQualifiedName())
  end
end

--@api-stub: QualityReport:getByGrade
-- Returns the by grade of this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  for _, e in ipairs(q:getByGrade("C")) do
    lurek.log.info("docs", "grade C: " .. e:getQualifiedName())
  end
end

--@api-stub: QualityReport:getSummary
-- Returns the summary of this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  lurek.log.info("docs", q:getSummary())
end

--@api-stub: QualityReport:toTable
-- Performs the to table operation on this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  local data = q:toTable()
  lurek.log.info("docs", "table overall: " .. tostring(data.overall_score))
end

--@api-stub: QualityReport:toJSON
-- Performs the to json operation on this quality report.
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  pcall(function() lurek.fs.write("build/docs-quality.json", q:toJSON()) end)
end

--@api-stub: LApiCatalog:type
-- Returns the Lua-visible type name for this API catalog handle
do
  local api_catalog_obj = lurek.docs.scan(nil)
  local t = api_catalog_obj:type()
  lurek.log.info("LApiCatalog:type = " .. t, "docs")
end
--@api-stub: LApiCatalog:typeOf
-- Returns whether this API catalog handle matches a supported type name
do
  local api_catalog_obj = lurek.docs.scan(nil)
  lurek.log.info("is LApiCatalog: " .. tostring(api_catalog_obj:typeOf("LApiCatalog")), "docs")
  lurek.log.info("is wrong: " .. tostring(api_catalog_obj:typeOf("Unknown")), "docs")
end
--@api-stub: LDocEntry:type
-- Returns the Lua-visible type name for this documentation entry handle
do
  local catalog = lurek.docs.scanModule("audio")
    local entry = catalog:getEntries()[1]
  local t = catalog:type()
  lurek.log.info("LDocEntry:type = " .. t, "docs")
end
--@api-stub: LDocEntry:typeOf
-- Returns whether this documentation entry handle matches a supported type name
do
  local catalog = lurek.docs.scanModule("audio")
    local entry = catalog:getEntries()[1]
  lurek.log.info("is LDocEntry: " .. tostring(catalog:typeOf("LDocEntry")), "docs")
  lurek.log.info("is wrong: " .. tostring(catalog:typeOf("Unknown")), "docs")
end
--@api-stub: LQualityReport:type
-- Returns the Lua-visible type name for this quality report handle
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  local t = q:type()
  lurek.log.info("LQualityReport:type = " .. t, "docs")
end
--@api-stub: LQualityReport:typeOf
-- Returns whether this quality report handle matches a supported type name
do
  local q = lurek.docs.quality(lurek.docs.loadAll("docs/api"))
  lurek.log.info("is LQualityReport: " .. tostring(q:typeOf("LQualityReport")), "docs")
  lurek.log.info("is wrong: " .. tostring(q:typeOf("Unknown")), "docs")
end
--@api-stub: LSchema:type
-- Returns the Lua-visible type name for this schema handle
do
  local schema = lurek.docs.schema({ hp = { type = "integer", required = true, min = 0 } }, "Stats")
  local result = schema:validate({ hp = -5 })
  local count = (type(result) == "table") and #result or (result and 0 or 1)
  if count > 0 then
    lurek.log.info("validation errors: " .. count, "docs")
  end
  local t = schema:type()
  lurek.log.info("LSchema:type = " .. t, "docs")
end
--@api-stub: LSchema:typeOf
-- Returns whether this schema handle matches a supported type name
do
  local schema = lurek.docs.schema({ hp = { type = "integer", required = true, min = 0 } }, "Stats")
  local result = schema:validate({ hp = -5 })
  local count = (type(result) == "table") and #result or (result and 0 or 1)
  if count > 0 then
    lurek.log.info("validation errors: " .. count, "docs")
  end
  lurek.log.info("is LSchema: " .. tostring(schema:typeOf("LSchema")), "docs")
  lurek.log.info("is wrong: " .. tostring(schema:typeOf("Unknown")), "docs")
end
--@api-stub: LValidationReport:type
-- Returns the Lua-visible type name for this validation report handle
do
  local validation_report_obj = lurek.docs.validate(nil)
  local t = validation_report_obj:type()
  lurek.log.info("LValidationReport:type = " .. t, "docs")
end
--@api-stub: LValidationReport:typeOf
-- Returns whether this validation report handle matches a supported type name
do
  local validation_report_obj = lurek.docs.validate(nil)
  lurek.log.info("is LValidationReport: " .. tostring(validation_report_obj:typeOf("LValidationReport")), "docs")
  lurek.log.info("is wrong: " .. tostring(validation_report_obj:typeOf("Unknown")), "docs")
end


