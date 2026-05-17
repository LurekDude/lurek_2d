-- content/examples/docs.lua
-- lurek.docs API examples: live reflection, catalog management, validation, quality scoring, schema, and export.
-- Run: cargo run -- content/examples/docs.lua

--@api-stub: lurek.docs.scan
-- Reflects the live `lurek` table and builds a catalog of callable APIs
do
  -- scan() walks the entire lurek.* table tree at runtime, discovering every
  -- registered function and sub-table. This is ideal for building help systems
  -- or runtime introspection tools that adapt to the current engine version.
  local catalog = lurek.docs.scan()
  local count = catalog:entryCount()
  lurek.log.info("docs", "scanned " .. count .. " live API entries")

  -- The returned LApiCatalog is a snapshot — if modules are added later,
  -- you need to scan() again to see them.
end

--@api-stub: lurek.docs.scanModule
-- Reflects one live `lurek.<module>` table and builds a catalog for that module
do
  -- scanModule() is faster than scan() when you only need one module.
  -- Useful for per-module help panels or targeted documentation audits.
  local audio_cat = lurek.docs.scanModule("audio")
  for _, entry in ipairs(audio_cat:getEntries()) do
    -- getQualifiedName() returns the full dotted path, e.g. "lurek.audio.play"
    lurek.log.debug("audio-api", entry:getQualifiedName())
  end
end

--@api-stub: lurek.docs.loadToml
-- Loads a TOML documentation catalog file and converts its entries into an API catalog
do
  -- TOML catalogs store authored documentation (descriptions, params, returns)
  -- that augments the bare reflection data. Each module has its own .toml file.
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    if catalog:entryCount() == 0 then
      lurek.log.warn("docs", "audio.toml had no entries — file may be empty")
    else
      lurek.log.info("docs", "loaded " .. catalog:entryCount() .. " authored audio docs")
    end
  end
end

--@api-stub: lurek.docs.loadAll
-- Loads all TOML documentation catalog files from a directory and combines their entries
do
  -- loadAll() scans a directory for every .toml file and merges them into one
  -- catalog. This is the standard way to load the full authored documentation set.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local mods = catalog:getModules()
    lurek.log.info("docs", "loaded " .. #mods .. " documented modules from docs/api/")
  end
end

--@api-stub: lurek.docs.describe
-- Adds or updates the description for one editable catalog entry
do
  -- The editable in-memory catalog lets you build documentation at runtime.
  -- describe() creates or updates an entry's description text.
  -- First scan to populate the catalog, then annotate entries programmatically.
  lurek.docs.scan()
  lurek.docs.describe("lurek.audio.play", "Play a sound source by name or handle.")
  lurek.docs.describe("lurek.audio.stop", "Stop a currently playing source immediately.")

  -- This pattern is useful for auto-documentation tools that read annotations
  -- from game source files and inject them into the runtime catalog.
end

--@api-stub: lurek.docs.setParamInfo
-- Replaces parameter metadata for one editable catalog entry
do
  -- setParamInfo() attaches typed parameter documentation to a catalog entry.
  -- Each param row has: name, type, description, optional (bool), default (optional).
  lurek.docs.scan()
  lurek.docs.setParamInfo("lurek.audio.play", {
    { name = "name", type = "string", description = "Sound asset name or path", optional = false },
    { name = "loop", type = "boolean", description = "Whether to loop playback", optional = true, default = false },
  })

  -- After setting param info, the entry shows typed signatures in help output
  -- and exported editor artifacts (completions, hover, signatures).
end

--@api-stub: lurek.docs.setReturnInfo
-- Replaces return-value metadata for one editable catalog entry
do
  -- setReturnInfo() documents what a function returns. Each row has type + description.
  lurek.docs.scan()
  lurek.docs.setReturnInfo("lurek.audio.play", {
    { type = "LSource", description = "Handle to the playing audio source" },
  })
end

--@api-stub: lurek.docs.getCatalog
-- Returns the editable in-memory documentation catalog
do
  -- getCatalog() retrieves the shared mutable catalog that describe/setParamInfo/
  -- setReturnInfo write into. Use it to inspect or export your runtime annotations.
  lurek.docs.scan()
  local cat = lurek.docs.getCatalog()
  lurek.log.info("docs", "editable catalog has " .. cat:entryCount() .. " entries")
end

--@api-stub: lurek.docs.resetCatalog
-- Clears the editable in-memory documentation catalog
do
  -- resetCatalog() wipes all editable entries. Useful before rebuilding
  -- the catalog from scratch to avoid stale data accumulation.
  lurek.docs.scan()
  lurek.docs.resetCatalog()
  assert(lurek.docs.getCatalog():entryCount() == 0, "catalog should be empty after reset")
end

--@api-stub: LSchema:validate
-- Compares a documentation catalog with the live reflected `lurek` API table
do
  -- validate() checks whether your authored docs cover the real API.
  -- It returns a report with: missing (live but undocumented), phantom (documented
  -- but not live), and incomplete (documented but lacking description/params/returns).
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    if not report:isValid() then
      lurek.log.error("docs", "missing " .. report:missingCount() .. " entries from docs")
    else
      lurek.log.info("docs", "all live APIs are documented")
    end
  end
end

--@api-stub: lurek.docs.validateModule
-- Compares one module's documentation catalog entries with the live reflected module table
do
  -- validateModule() narrows validation to one module — faster feedback when
  -- iterating on a single module's documentation.
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
  -- checkStaleness() scans source files and compares against catalog entries
  -- to detect which docs may be outdated. Returns tables of stale, current,
  -- and missing files.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local result = lurek.docs.checkStaleness(catalog, "src/lua_api")
    lurek.log.info("docs", "scanned " .. #result.current .. " current source files")
    if result.stale and #result.stale > 0 then
      lurek.log.warn("docs", #result.stale .. " source files have stale documentation")
    end
  end
end

--@api-stub: lurek.docs.quality
-- Computes documentation quality for a supplied catalog or the editable in-memory catalog
do
  -- quality() scores every entry based on description completeness, param coverage,
  -- return types, and examples. Returns a LQualityReport with grades A-F.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    lurek.log.info("docs", string.format("overall %.0f%% (grade %s)", q:getOverallScore() * 100, q:getGrade()))
  end
end

--@api-stub: lurek.docs.qualityModule
-- Computes documentation quality for entries belonging to one module
do
  -- qualityModule() filters to one module before scoring — ideal for targeted
  -- improvements when a module's docs fall below the quality gate threshold.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.qualityModule("audio", catalog)
    lurek.log.info("audio-docs", "audio module grade: " .. q:getGrade())
  end
end

--@api-stub: lurek.docs.coverage
-- Returns documented and live API counts for the full `lurek` table
do
  -- coverage() returns two numbers: documented count and total live API count.
  -- Use it to compute coverage percentage for CI gates.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local documented, total = lurek.docs.coverage(catalog)
    local pct = total > 0 and (documented / total * 100) or 0
    lurek.log.info("docs", string.format("coverage %d/%d (%.0f%%)", documented, total, pct))
  end
end

--@api-stub: lurek.docs.coverageModule
-- Returns documented and live API counts for one module
do
  -- coverageModule() works like coverage() but scoped to a single module.
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local documented, total = lurek.docs.coverageModule("audio", catalog)
    lurek.log.info("audio-docs", string.format("audio %d/%d documented", documented, total))
  end
end

--@api-stub: lurek.docs.exportCompletions
-- Exports catalog completion metadata to a file
do
  -- exportCompletions() writes JSON completion data suitable for editor extensions.
  -- The VS Code extension uses this to offer lurek.* autocompletions.
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportCompletions, catalog, "build/vscode/completions.json")
  lurek.log.info("docs", "wrote completions.json for editor autocomplete")
end

--@api-stub: lurek.docs.exportHover
-- Exports catalog hover metadata to a file
do
  -- exportHover() writes JSON hover info (descriptions, params, returns) that
  -- editors display when the user hovers over a lurek.* symbol.
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportHover, catalog, "build/vscode/hover.json")
  lurek.log.info("docs", "wrote hover.json for editor tooltips")
end

--@api-stub: lurek.docs.exportSignatures
-- Exports catalog signature metadata to a file
do
  -- exportSignatures() writes parameter signature data used by editors
  -- for function signature help (the popup showing param names as you type).
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportSignatures, catalog, "build/vscode/signatures.json")
  lurek.log.info("docs", "wrote signatures.json for signature help")
end

--@api-stub: lurek.docs.exportAll
-- Exports all editor documentation artifacts for a catalog into a directory
do
  -- exportAll() is a convenience that writes completions, hover, and signatures
  -- in one call. Use it in build scripts to regenerate the full editor bundle.
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportAll, catalog, "build/vscode")
  lurek.log.info("docs", "wrote full editor documentation bundle to build/vscode/")
end

--@api-stub: lurek.docs.exportMarkdown
-- Writes a Markdown API reference from catalog entries
do
  -- exportMarkdown() generates a human-readable API reference document.
  -- Combine loadAll (for authored docs) with scan (for live coverage) via merge
  -- to get the most complete output.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    pcall(lurek.docs.exportMarkdown, catalog, "build/lua-api.md")
    lurek.log.info("docs", "regenerated lua-api.md reference")
  end
end

--@api-stub: lurek.docs.exportCheatsheet
-- Writes a compact text cheatsheet from catalog entries
do
  -- exportCheatsheet() produces a condensed one-liner-per-function text file
  -- that fits on a printed page or in a terminal quick-reference.
  local catalog = lurek.docs.scan()
  pcall(lurek.docs.exportCheatsheet, catalog, "build/cheatsheet.txt")
  lurek.log.info("docs", "wrote cheatsheet.txt")
end

--@api-stub: lurek.docs.schema
-- Builds a schema validator from Lua table rules
do
  -- schema() creates a reusable validator from a rules table. Each field rule
  -- specifies type, required, min/max (for numbers), minLen/maxLen (for strings),
  -- and enum (allowed values). The optional second arg is the schema name.
  local schema = lurek.docs.schema({
    name  = { type = "string", required = true, minLen = 1 },
    level = { type = "integer", required = true, min = 1, max = 99 },
    class = { type = "string", enum = { "warrior", "mage", "rogue" } },
  }, "PlayerSave")

  -- assert() raises a Lua error if validation fails — ideal for config loading.
  schema:assert({ name = "Hero", level = 1, class = "warrior" })
  lurek.log.info("docs", "PlayerSave schema validated successfully")
end

--@api-stub: lurek.docs.schemaFromToml
-- Builds a schema validator from TOML schema text
do
  -- schemaFromToml() parses schema rules from TOML text, useful when schemas
  -- are stored in external config files rather than inline Lua tables.
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
  -- validate against a simple table
  schema:assert({ level = 10 })
  lurek.log.info("docs", "TOML-based schema validated level=10")
end

--@api-stub: lurek.docs.reflectLive
-- Reflects live `lurek` module tables into plain name and type rows
do
  -- reflectLive() returns raw reflection data (name + Lua type) without building
  -- a full catalog. Pass a module name to reflect one module, or omit to reflect all.
  -- Useful for quick runtime inspection or custom help formatters.
  local audio_only = lurek.docs.reflectLive("audio")
  for _, item in ipairs(audio_only.audio or {}) do
    lurek.log.debug("reflect", item.name .. " (" .. item.type .. ")")
  end
end

--@api-stub: lurek.docs.reflectTable
-- Reflects an arbitrary Lua table into name, qualifiedName, and type rows
do
  -- reflectTable() works on any Lua table — not just lurek.*. Useful for
  -- documenting your own game modules or plugin tables at runtime.
  local mod = { greet = function(_) end, version = "1.0", count = 3 }
  local items = lurek.docs.reflectTable(mod, "mymod")
  for _, it in ipairs(items) do
    -- Each row has qualifiedName (e.g. "mymod.greet") and type ("function", "string", etc.)
    lurek.log.debug("reflect", it.qualifiedName .. " : " .. it.type)
  end
end

-- Schema methods

--@api-stub: LSchema:validate
-- Validates a table and returns success flag plus structured error details
do
  -- validate() returns two values: a boolean (pass/fail) and an array of error
  -- tables, each with field and message keys. Use this when you need detailed
  -- error feedback rather than just pass/fail.
  local schema = lurek.docs.schema({
    hp = { type = "integer", required = true, min = 0 },
  }, "Stats")
  local ok, errors = schema:validate({ hp = -5 })
  if not ok then
    for _, err in ipairs(errors) do
      lurek.log.warn("schema", err.field .. ": " .. err.message)
    end
  end
end

--@api-stub: LSchema:check
-- Validates a table and returns only the boolean result
do
  -- check() is the lightweight alternative to validate() — returns just true/false.
  -- Use it in hot paths where you only need a pass/fail gate.
  local schema = lurek.docs.schema({ port = { type = "integer", min = 1, max = 65535 } }, "Net")
  if not schema:check({ port = 8080 }) then
    lurek.log.error("net", "invalid network config")
  else
    lurek.log.info("net", "port 8080 is valid")
  end
end

--@api-stub: LSchema:assert
-- Validates a table and raises a Lua error if validation fails
do
  -- assert() is the strictest mode — on failure it raises a Lua error with
  -- all violation messages joined. Ideal for config loading where invalid data
  -- should halt execution immediately.
  local schema = lurek.docs.schema({ width = { type = "integer", required = true, min = 1 } }, "Window")
  schema:assert({ width = 1280 })
  lurek.log.info("config", "window config validated via assert")
end

--@api-stub: LDocEntry:getName
-- Returns the display name of this schema
do
  -- getName() returns the name passed as the second arg to schema() or "schema" by default.
  local schema = lurek.docs.schema({ x = { type = "number" } }, "Point")
  local label = schema:getName()
  lurek.log.debug("schema", "loaded schema: " .. label) -- prints "Point"
end

--@api-stub: LSchema:getFields
-- Returns the field names declared by this schema
do
  -- getFields() returns a sorted array of declared field names. Useful for
  -- generating config templates or displaying expected fields in help output.
  local schema = lurek.docs.schema({ a = { type = "string" }, b = { type = "number" } }, "AB")
  for _, field in ipairs(schema:getFields()) do
    lurek.log.debug("schema", "declared field: " .. field)
  end
end

-- DocEntry methods

--@api-stub: LDocEntry:getName
-- Returns the short name of this entry (without module prefix)
do
  local catalog = lurek.docs.scanModule("audio")
  local entry = catalog:getEntries()[1]
  if entry then
    -- getName() returns just the function name, e.g. "play" not "lurek.audio.play"
    lurek.log.debug("docs", "first audio entry: " .. entry:getName())
  end
end

--@api-stub: LDocEntry:getQualifiedName
-- Returns the full dotted API name of this entry
do
  local catalog = lurek.docs.scan()
  for _, e in ipairs(catalog:getEntries()) do
    -- getQualifiedName() returns paths like "lurek.log.info", "lurek.audio.play"
    if e:getName() == "info" then
      lurek.log.debug("docs", "qualified: " .. e:getQualifiedName())
    end
  end
end

--@api-stub: LDocEntry:getModule
-- Returns the module name this entry belongs to
do
  local catalog = lurek.docs.scan()
  local first = catalog:getEntries()[1]
  if first then
    -- getModule() returns the module portion, e.g. "audio", "log", "math"
    lurek.log.debug("docs", "module: " .. first:getModule())
  end
end

--@api-stub: LDocEntry:getKind
-- Returns the documentation kind: "function", "method", "type", or "value"
do
  -- Use getKind() to filter entries by type when building help displays
  local catalog = lurek.docs.scan()
  local type_count = 0
  for _, e in ipairs(catalog:getEntries()) do
    if e:getKind() == "type" then type_count = type_count + 1 end
  end
  lurek.log.debug("docs", "found " .. type_count .. " type entries")
end

--@api-stub: LDocEntry:getDescription
-- Returns the prose description text for this entry
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local entry = catalog:getEntry("lurek.audio.play")
    if entry then
      -- getDescription() returns the authored doc text from the TOML catalog
      lurek.log.info("docs", "audio.play: " .. entry:getDescription())
    end
  end
end

--@api-stub: LDocEntry:getParameters
-- Returns parameter metadata as an array of {name, type, description, optional, default}
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local entry = catalog:getEntry("lurek.audio.play")
    if entry then
      -- Each param row is a table: { name="x", type="number", description="...",
      -- optional=false, default=nil }
      for _, p in ipairs(entry:getParameters()) do
        local opt = p.optional and " (optional)" or ""
        lurek.log.debug("docs", "  " .. p.name .. " : " .. p.type .. opt)
      end
    end
  end
end

--@api-stub: LDocEntry:getReturns
-- Returns return-value metadata as an array of {type, description}
do
  local ok, catalog = pcall(lurek.docs.loadToml, "docs/api/audio.toml")
  if ok then
    local entry = catalog:getEntry("lurek.audio.play")
    if entry then
      for _, r in ipairs(entry:getReturns()) do
        lurek.log.debug("docs", "  returns " .. r.type .. " — " .. r.description)
      end
    end
  end
end

--@api-stub: LDocEntry:getExample
-- Returns the example code snippet if one was recorded, or nil
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local entry = catalog:getEntry("lurek.audio.play")
    local snippet = entry and entry:getExample()
    if snippet then
      lurek.log.info("docs", "example:\n" .. snippet)
    end
  end
end

--@api-stub: LDocEntry:getSince
-- Returns the version this entry was introduced, or nil
do
  -- getSince() is useful for filtering "what's new in version X" help panels
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    for _, e in ipairs(catalog:getEntries()) do
      local v = e:getSince()
      if v == "0.6.0" then
        lurek.log.info("docs", "new in 0.6: " .. e:getQualifiedName())
      end
    end
  end
end

--@api-stub: LDocEntry:getDeprecated
-- Returns the deprecation notice if the entry is deprecated, or nil
do
  -- getDeprecated() lets you warn users about soon-to-be-removed APIs
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    for _, e in ipairs(catalog:getEntries()) do
      local msg = e:getDeprecated()
      if msg then
        lurek.log.warn("deprecated", e:getQualifiedName() .. " — " .. msg)
      end
    end
  end
end

--@api-stub: LDocEntry:getScore
-- Returns the documentation quality score for this entry (0.0 to 1.0)
do
  -- getScore() rates how complete a single entry's documentation is.
  -- Low scores indicate missing description, params, or return info.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    for _, e in ipairs(catalog:getEntries()) do
      if e:getScore() < 0.5 then
        lurek.log.warn("docs", "low score: " .. e:getQualifiedName())
      end
    end
  end
end

--@api-stub: LDocEntry:hasDescription
-- Returns true if this entry has a non-empty description
do
  local catalog = lurek.docs.scan()
  local missing = 0
  for _, e in ipairs(catalog:getEntries()) do
    if not e:hasDescription() then missing = missing + 1 end
  end
  -- Live-scanned entries have no authored descriptions — only TOML catalogs do.
  lurek.log.info("docs", missing .. " entries missing descriptions (expected for live scan)")
end

--@api-stub: LDocEntry:hasParameters
-- Returns true if this entry has at least one parameter documented
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local undocumented = 0
    for _, e in ipairs(catalog:getEntries()) do
      if e:getKind() == "function" and not e:hasParameters() then
        undocumented = undocumented + 1
      end
    end
    lurek.log.debug("docs", undocumented .. " functions lack param documentation")
  end
end

--@api-stub: LDocEntry:hasReturnType
-- Returns true if this entry has at least one return type documented
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local undocumented = 0
    for _, e in ipairs(catalog:getEntries()) do
      if e:getKind() == "function" and not e:hasReturnType() then
        undocumented = undocumented + 1
      end
    end
    lurek.log.debug("docs", undocumented .. " functions lack return type documentation")
  end
end

--@api-stub: LDocEntry:hasExample
-- Returns true if this entry has example code recorded
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local without = 0
    for _, e in ipairs(catalog:getEntries()) do
      if not e:hasExample() then without = without + 1 end
    end
    lurek.log.info("docs", without .. " entries lack usage examples")
  end
end

-- ApiCatalog methods

--@api-stub: LApiCatalog:getModules
-- Returns sorted array of module names present in this catalog
do
  -- getModules() lists all distinct modules — use it to build navigation menus
  local catalog = lurek.docs.scan()
  local modules = catalog:getModules()
  lurek.log.debug("docs", "discovered " .. #modules .. " modules")
  for _, name in ipairs(modules) do
    lurek.log.debug("docs", "  module: " .. name)
  end
end

--@api-stub: LApiCatalog:getEntries
-- Returns entry array, optionally filtered to one module
do
  -- Pass a module name to getEntries() to retrieve only that module's entries.
  -- Omit the argument to get all entries in the catalog.
  local catalog = lurek.docs.scan()
  local audio_entries = catalog:getEntries("audio")
  lurek.log.info("docs", "audio has " .. #audio_entries .. " entries in live scan")
end

--@api-stub: LApiCatalog:getEntry
-- Returns one entry by qualified name, or nil if not found
do
  -- getEntry() does an exact qualified-name lookup — O(n) scan of the catalog.
  local catalog = lurek.docs.scan()
  local entry = catalog:getEntry("lurek.audio.play")
  if entry then
    lurek.log.info("docs", "found: " .. entry:getQualifiedName())
  else
    lurek.log.debug("docs", "lurek.audio.play not in live catalog (normal if no audio module)")
  end
end

--@api-stub: LApiCatalog:getTypes
-- Returns documented type names for one module
do
  -- getTypes() filters entries where kind == "type" for a given module.
  -- Use it to list user-facing types like LSource, LBody, etc.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    for _, t in ipairs(catalog:getTypes("audio")) do
      lurek.log.debug("docs", "audio type: " .. t)
    end
  end
end

--@api-stub: LApiCatalog:getTypeMethods
-- Returns method entries associated with a qualified type name
do
  -- getTypeMethods() finds entries whose qualified name starts with the type prefix.
  -- Useful for building per-type method documentation panels.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    for _, m in ipairs(catalog:getTypeMethods("lurek.audio.Source")) do
      lurek.log.debug("docs", "Source method: " .. m:getName())
    end
  end
end

--@api-stub: LApiCatalog:entryCount
-- Returns entry count, optionally scoped to one module
do
  -- entryCount() with no arg returns total entries; with a module name, only that module.
  local catalog = lurek.docs.scan()
  local total = catalog:entryCount()
  local audio = catalog:entryCount("audio")
  lurek.log.info("docs", string.format("total %d, audio %d", total, audio))
end

--@api-stub: LApiCatalog:merge
-- Merges another catalog into this one, returning a new combined catalog
do
  -- merge() combines live reflection (all names, no descriptions) with authored
  -- TOML docs (descriptions, params, returns). Entries in the second catalog
  -- replace matching entries from the first by qualified name.
  local live = lurek.docs.scan()
  local ok, toml = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local merged = live:merge(toml)
    lurek.log.info("docs", "merged catalog: " .. merged:entryCount() .. " entries")
  end
end

--@api-stub: LApiCatalog:filter
-- Builds a new catalog containing only entries accepted by a predicate function
do
  -- filter() takes a function(entry) -> bool predicate. The returned catalog
  -- contains only entries where the predicate returned truthy.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local deprecated = catalog:filter(function(e) return e:getDeprecated() ~= nil end)
    lurek.log.info("docs", deprecated:entryCount() .. " deprecated entries found")
  end
end

--@api-stub: LApiCatalog:search
-- Case-insensitive substring search across names, qualified names, and descriptions
do
  -- search() is the basis for help-system search bars. It matches against
  -- entry name, qualified name, and description text simultaneously.
  local catalog = lurek.docs.scan()
  local results = catalog:search("play")
  for _, e in ipairs(results) do
    lurek.log.debug("docs", "search hit: " .. e:getQualifiedName())
  end
end

--@api-stub: LQualityReport:toTable
-- Converts catalog to plain Lua tables for lightweight inspection
do
  -- toTable() returns an array of plain tables with name, qualifiedName, module,
  -- kind, description, and score fields — no userdata, easy to serialize.
  local catalog = lurek.docs.scan()
  local raw = catalog:toTable()
  lurek.log.info("docs", "raw catalog has " .. #raw .. " rows")
  if #raw > 0 then
    lurek.log.debug("docs", "first: " .. raw[1].qualifiedName)
  end
end

--@api-stub: LQualityReport:toJSON
-- Serializes catalog to pretty-printed JSON
do
  -- toJSON() produces a JSON array of all entries with full metadata.
  -- Useful for feeding catalog data to external tools or web UIs.
  local catalog = lurek.docs.scan()
  local json = catalog:toJSON()
  pcall(function() lurek.fs.write("build/api-catalog.json", json) end)
  lurek.log.info("docs", "exported catalog JSON (" .. #json .. " bytes)")
end

-- ValidationReport methods

--@api-stub: LValidationReport:isValid
-- Returns true if no live APIs are missing from the catalog
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    if report:isValid() then
      lurek.log.info("docs", "validation passed — no missing entries")
    else
      lurek.log.error("docs", "validation failed — docs are incomplete")
    end
  end
end

--@api-stub: LValidationReport:getMissing
-- Returns array of qualified names that exist live but are not documented
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    -- These are APIs that exist in the engine but have no documentation entry
    for _, name in ipairs(report:getMissing()) do
      lurek.log.warn("docs", "missing docs: " .. name)
    end
  end
end

--@api-stub: LValidationReport:getPhantom
-- Returns array of qualified names documented but not present in live reflection
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    -- Phantoms are documented entries that no longer exist — possibly removed APIs
    for _, name in ipairs(report:getPhantom()) do
      lurek.log.warn("docs", "phantom (remove stale doc): " .. name)
    end
  end
end

--@api-stub: LValidationReport:getIncomplete
-- Returns array of qualified names with incomplete documentation
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    -- Incomplete entries exist but lack description, params, or return info
    for _, name in ipairs(report:getIncomplete()) do
      lurek.log.info("docs", "needs more detail: " .. name)
    end
  end
end

--@api-stub: LValidationReport:missingCount
-- Returns count of live APIs missing from the catalog
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    if report:missingCount() > 0 then
      lurek.log.error("docs", report:missingCount() .. " APIs need documentation")
    end
  end
end

--@api-stub: LValidationReport:phantomCount
-- Returns count of documented APIs absent from live reflection
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    lurek.log.info("docs", report:phantomCount() .. " phantom (stale) doc entries")
  end
end

--@api-stub: LValidationReport:incompleteCount
-- Returns count of entries with incomplete documentation
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    lurek.log.info("docs", report:incompleteCount() .. " entries need more detail")
  end
end

--@api-stub: LQualityReport:getSummary
-- Returns a compact human-readable text summary of the validation result
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    -- getSummary() produces "Missing: N, Phantom: N, Incomplete: N"
    lurek.log.info("docs", report:getSummary())
  end
end

--@api-stub: LQualityReport:toTable
-- Converts the report to a plain Lua table with missing, phantom, incomplete arrays
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    local data = report:toTable()
    lurek.log.info("docs", "missing: " .. #(data.missing or {}) .. ", phantom: " .. #(data.phantom or {}))
  end
end

--@api-stub: LQualityReport:toJSON
-- Serializes the validation report to pretty-printed JSON
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    -- toJSON() is useful for CI pipelines that parse validation results
    pcall(function() lurek.fs.write("build/docs-validation.json", report:toJSON()) end)
    lurek.log.info("docs", "wrote validation report JSON")
  end
end

-- QualityReport methods

--@api-stub: LQualityReport:getOverallScore
-- Returns the aggregate quality score (0.0 to 1.0)
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    -- Scores below 0.8 may indicate the module needs documentation work
    if q:getOverallScore() < 0.8 then
      lurek.log.warn("docs", string.format("quality %.0f%% — below 80%% threshold", q:getOverallScore() * 100))
    end
  end
end

--@api-stub: LQualityReport:getGrade
-- Returns the letter grade (A, B, C, D, F) derived from the overall score
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    lurek.log.info("docs", "documentation grade: " .. q:getGrade())
  end
end

--@api-stub: LQualityReport:getModuleScores
-- Returns a table mapping module names to their individual quality scores
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    -- getModuleScores() lets you identify which modules need the most attention
    for module, score in pairs(q:getModuleScores()) do
      lurek.log.debug("docs", string.format("  %s: %.0f%%", module, score * 100))
    end
  end
end

--@api-stub: LQualityReport:getWorst
-- Returns the N lowest-scoring entries (default 10)
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    -- getWorst() helps prioritize documentation improvements
    for _, e in ipairs(q:getWorst(5)) do
      lurek.log.warn("docs", string.format("worst: %s (%.0f%%)", e:getQualifiedName(), e:getScore() * 100))
    end
  end
end

--@api-stub: LQualityReport:getBest
-- Returns the N highest-scoring entries (default 10)
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    -- getBest() shows exemplar entries that others should aspire to
    for _, e in ipairs(q:getBest(5)) do
      lurek.log.info("docs", "exemplar: " .. e:getQualifiedName())
    end
  end
end

--@api-stub: LQualityReport:getByGrade
-- Returns entries matching a specific grade letter
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    -- getByGrade() filters entries to one quality tier — useful for batch fixes
    local c_entries = q:getByGrade("C")
    lurek.log.info("docs", #c_entries .. " entries at grade C (need improvement)")
  end
end

--@api-stub: LQualityReport:getSummary
-- Returns a multiline human-readable quality summary with per-module breakdown
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    -- getSummary() is formatted for direct terminal/log output
    lurek.log.info("docs", "\n" .. q:getSummary())
  end
end

--@api-stub: LQualityReport:toTable
-- Converts the quality report to a plain Lua table
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    local data = q:toTable()
    -- data has overallScore (number), grade (string), moduleScores (table)
    lurek.log.info("docs", "overall: " .. string.format("%.0f%%", (data.overallScore or 0) * 100))
  end
end

--@api-stub: LQualityReport:toJSON
-- Serializes the quality report to pretty-printed JSON
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    pcall(function() lurek.fs.write("build/docs-quality.json", q:toJSON()) end)
    lurek.log.info("docs", "wrote quality report JSON")
  end
end

--@api-stub: LQualityReport:type
-- Returns the Lua-visible type name for this API catalog handle
do
  local catalog = lurek.docs.scan()
  -- type() returns the string "LApiCatalog" for catalog handles
  local t = catalog:type()
  assert(t == "LApiCatalog", "expected LApiCatalog, got " .. t)
end

--@api-stub: LQualityReport:typeOf
-- Returns whether this API catalog handle matches a supported type name
do
  local catalog = lurek.docs.scan()
  -- typeOf() checks against "LApiCatalog" and "Object" (the base type)
  assert(catalog:typeOf("LApiCatalog") == true)
  assert(catalog:typeOf("Object") == true)
  assert(catalog:typeOf("Unknown") == false)
end

--@api-stub: LQualityReport:type
-- Returns the Lua-visible type name for this documentation entry handle
do
  local catalog = lurek.docs.scanModule("audio")
  local entry = catalog:getEntries()[1]
  if entry then
    -- type() returns "LDocEntry" for documentation entry handles
    assert(entry:type() == "LDocEntry")
  end
end

--@api-stub: LQualityReport:typeOf
-- Returns whether this documentation entry handle matches a supported type name
do
  local catalog = lurek.docs.scanModule("audio")
  local entry = catalog:getEntries()[1]
  if entry then
    assert(entry:typeOf("LDocEntry") == true)
    assert(entry:typeOf("Object") == true)
    assert(entry:typeOf("Unknown") == false)
  end
end

--@api-stub: LQualityReport:type
-- Returns the Lua-visible type name for this quality report handle
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    assert(q:type() == "LQualityReport")
  end
end

--@api-stub: LQualityReport:typeOf
-- Returns whether this quality report handle matches a supported type name
do
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local q = lurek.docs.quality(catalog)
    assert(q:typeOf("LQualityReport") == true)
    assert(q:typeOf("Object") == true)
    assert(q:typeOf("Unknown") == false)
  end
end

--@api-stub: LQualityReport:type
-- Returns the Lua-visible type name for this schema handle
do
  local schema = lurek.docs.schema({ hp = { type = "integer", required = true } }, "Stats")
  assert(schema:type() == "LSchema")
end

--@api-stub: LQualityReport:typeOf
-- Returns whether this schema handle matches a supported type name
do
  local schema = lurek.docs.schema({ hp = { type = "integer", required = true } }, "Stats")
  assert(schema:typeOf("LSchema") == true)
  assert(schema:typeOf("Object") == true)
  assert(schema:typeOf("Unknown") == false)
end

--@api-stub: LQualityReport:type
-- Returns the Lua-visible type name for this validation report handle
do
  local report = lurek.docs.validate(nil)
  assert(report:type() == "LValidationReport")
end

--@api-stub: LQualityReport:typeOf
-- Returns whether this validation report handle matches a supported type name
do
  local report = lurek.docs.validate(nil)
  assert(report:typeOf("LValidationReport") == true)
  assert(report:typeOf("Object") == true)
  assert(report:typeOf("Unknown") == false)
end

print("content/examples/docs.lua")

-- =============================================================================
-- STUBS: 50 uncovered lurek.docs API item(s)
-- Generated by tools/audit/example_add_missing.py
-- REQUIRED: replace every --@api-stub: block below with a real scenario.
-- Run .github/prompts/flesh-out-example.prompt.md for instructions.
-- The final committed file must contain ZERO --@api-stub: lines.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- LApiCatalog methods
-- -----------------------------------------------------------------------------

--@api-stub: LApiCatalog:toTable
-- Converts this catalog into plain Lua tables for lightweight inspection.
do
  -- toTable returns a plain Lua table for custom processing or serialization.
  local catalog = lurek.docs.scan()
  local tbl = catalog:toTable()
  lurek.log.info("docs", "catalog table has " .. #tbl .. " entries")
end

--@api-stub: LApiCatalog:toJSON
-- Serializes this catalog to formatted JSON.
do
  -- toJSON exports the catalog as a JSON string for external tools or CI checks.
  local catalog = lurek.docs.scan()
  local json = catalog:toJSON()
  lurek.log.info("docs", "JSON export length: " .. #json .. " chars")
end

-- -----------------------------------------------------------------------------
-- LDocEntry methods
-- -----------------------------------------------------------------------------

--@api-stub: LSchema:getName
-- Returns this schema's display name.
do
  -- getName retrieves the label assigned at schema creation for logging or UI.
  local schema = lurek.docs.schema({ hp = { type = "integer" } }, "EntityStats")
  lurek.log.info("docs", "schema name: " .. schema:getName())
end

--@api-stub: LValidationReport:getSummary
-- Returns a compact text summary of missing, phantom, and incomplete counts.
do
  -- getSummary gives a one-line overview ideal for CI output or log messages.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    lurek.log.info("docs", "validation: " .. report:getSummary())
  end
end

--@api-stub: LValidationReport:toTable
-- Converts this validation report into a plain Lua table.
do
  -- toTable returns structured data for custom processing or display.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    local tbl = report:toTable()
    lurek.log.info("docs", "report fields: missing=" .. tostring(tbl.missing_count))
  end
end

--@api-stub: LValidationReport:toJSON
-- Serializes this validation report to formatted JSON.
do
  -- toJSON exports the validation report for external dashboards or CI artifacts.
  local ok, catalog = pcall(lurek.docs.loadAll, "docs/api")
  if ok then
    local report = lurek.docs.validate(catalog)
    local json = report:toJSON()
    lurek.log.info("docs", "validation JSON length: " .. #json .. " chars")
  end
end
