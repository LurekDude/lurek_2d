-- examples/docs.lua
-- Demonstrates luna.docs — the Luna2D API introspection and documentation quality
-- system.  Scans the live engine to build an ApiCatalog, lets you annotate
-- entries programmatically, validates missing coverage, and produces quality
-- reports for CI dashboards or in-game help screens.
-- Run with: cargo run -- examples/docs

-- ─────────────────────────────────────────────────────────────────────────────
-- SCANNING — build a catalog from the live engine
-- ─────────────────────────────────────────────────────────────────────────────

-- Scan ALL registered luna.* modules — returns an ApiCatalog userdata
local catalog = luna.docs.scan()
luna.log.info("scanned entries: " .. catalog:entryCount())

-- Scan options let you refine scope and toggle what metadata is collected
local full = luna.docs.scan({
    include_internal = false,   -- skip private / underscore-prefixed entries
    include_deprecated = true,  -- keep deprecated items in the catalog
    modules = { "math", "timer", "input" },  -- restrict to these modules only
})
luna.log.debug("filtered entry count: " .. full:entryCount())

-- Scan a single named module — useful for per-module quality gates
local math_catalog = luna.docs.scanModule("math")
luna.log.info("math entries: " .. math_catalog:entryCount())

-- ─────────────────────────────────────────────────────────────────────────────
-- LOADING FROM TOML / DIRECTORY
-- When engine modules register docs via TOML annotation files, load them here.
-- ─────────────────────────────────────────────────────────────────────────────

-- Load a TOML annotation file (path relative to GameFS root)
-- local toml_catalog = luna.docs.loadToml("docs/api/timer.toml")

-- Load every *.toml in a directory tree — merges into a single catalog
-- local dir_catalog  = luna.docs.loadAll("docs/api/")

-- ─────────────────────────────────────────────────────────────────────────────
-- GETTING CATALOG ENTRIES
-- ─────────────────────────────────────────────────────────────────────────────

-- List all modules present in the catalog
local modules = catalog:getModules()   -- { "math", "timer", "input", ... }
luna.log.info("modules in catalog: " .. #modules)

-- Get every entry across all modules
local all_entries = catalog:getEntries()   -- array of DocEntry userdata

-- Get entries for a specific module
local timer_entries = catalog:getEntries("timer")

-- Look up a single entry by its qualified name (module.name or type:method)
local entry = catalog:getEntry("timer.after")
if entry then
    luna.log.info("found: " .. entry:getQualifiedName())
end

-- Iterate entries and inspect metadata
for _, e in ipairs(timer_entries) do
    -- e:getName()           — "after", "every", "cancel", etc.
    -- e:getQualifiedName()  — "timer.after"
    -- e:getModule()         — "timer"
    -- e:getKind()           — "function" | "type" | "method" | "constant" | "event"
    -- e:getDescription()    — summary string (may be empty)
    -- e:getParameters()     — array of {name, type_name, description} tables
    -- e:getReturns()        — array of {type_name, description} tables
    -- e:getExample()        — example code snippet (may be empty string)
    -- e:getSince()          — "0.4.0" or "" if not set
    -- e:getDeprecated()     — deprecation notice or "" if current
    -- e:getScore()          — 0.0–1.0 documentation completeness score

    local has_desc   = e:hasDescription()
    local has_params = e:hasParameters()
    local has_ret    = e:hasReturnType()
    local has_ex     = e:hasExample()

    if not has_desc or not has_params then
        luna.log.debug(string.format("  missing docs: %s  score=%.2f",
            e:getQualifiedName(), e:getScore()))
    end
    _ = has_ret ; _ = has_ex   -- suppress unused warnings
end

-- ─────────────────────────────────────────────────────────────────────────────
-- TYPE AND METHOD INSPECTION
-- ─────────────────────────────────────────────────────────────────────────────

-- List all documented types (classes / userdata) in a module
local types = catalog:getTypes("graphics")
for _, type_name in ipairs(types) do
    luna.log.debug("type: " .. type_name)

    -- Get methods documented for that type
    local methods = catalog:getTypeMethods(type_name)
    for _, method in ipairs(methods) do
        -- method is a DocEntry with getKind() == "method"
        luna.log.debug("  method: " .. method:getQualifiedName())
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ADDING ANNOTATIONS PROGRAMMATICALLY
-- Use these APIs in conf.lua or main.lua to supplement auto-scanned docs
-- with hand-written descriptions, parameter types, and return info.
-- ─────────────────────────────────────────────────────────────────────────────

-- Describe a function by its qualified name
luna.docs.describe("math.lerp",
    "Linearly interpolates between `a` and `b` by factor `t` (0.0–1.0). " ..
    "Result is clamped to [a, b] when t is outside [0, 1].")

-- Annotate parameters
luna.docs.setParamInfo("math.lerp", {
    { name = "a", type_name = "number", description = "Start value." },
    { name = "b", type_name = "number", description = "End value." },
    { name = "t", type_name = "number", description = "Interpolation factor in [0, 1]." },
})

-- Annotate return type(s)
luna.docs.setReturnInfo("math.lerp", {
    { type_name = "number", description = "The interpolated value." },
})

-- ─────────────────────────────────────────────────────────────────────────────
-- CATALOG OPERATIONS — merge, filter, search
-- ─────────────────────────────────────────────────────────────────────────────

-- Merge two catalogs (annotations in `other` override matching entries)
local annotated = luna.docs.getCatalog()   -- global annotations written above
catalog:merge(annotated)

-- Filter returns a NEW catalog with only the matching entries
local undocumented = catalog:filter(function(entry)
    return not entry:hasDescription()       -- keep only undocumented entries
end)
luna.log.info("undocumented entries: " .. undocumented:entryCount())

-- Search performs a fuzzy text match against names and descriptions
local matches = catalog:search("lerp")
for _, e in ipairs(matches) do
    luna.log.debug("search hit: " .. e:getQualifiedName())
end

-- ─────────────────────────────────────────────────────────────────────────────
-- VALIDATION — missing, phantom, incomplete
-- luna.docs.validate() compares the live engine surface against the catalog
-- to find gaps: entries in the engine but not documented (missing), entries
-- in the catalog but absent from the engine (phantom), and entries present
-- but with low-quality docs (incomplete).
-- ─────────────────────────────────────────────────────────────────────────────

-- Validate the globally-annotated catalog
local report = luna.docs.validate()

-- Validate an ad-hoc catalog to diff it against the live engine
local report2 = luna.docs.validate(math_catalog)
_ = report2

-- Inspect the report
if report:isValid() then
    luna.log.info("docs validation PASSED — no gaps")
else
    luna.log.warn(string.format(
        "docs validation: missing=%d phantom=%d incomplete=%d",
        report:missingCount(), report:phantomCount(), report:incompleteCount()))
end

-- Missing = live engine functions with no catalog entry
local missing = report:getMissing()   -- array of qualified-name strings
if #missing > 0 then
    for _, name in ipairs(missing) do
        luna.log.warn("  missing: " .. name)
    end
end

-- Phantom = catalog entries that no longer exist in the engine (stale)
local phantom = report:getPhantom()
for _, name in ipairs(phantom) do
    luna.log.warn("  phantom (stale): " .. name)
end

-- Incomplete = present but score below threshold (description/params/returns empty)
local incomplete = report:getIncomplete()
for _, name in ipairs(incomplete) do
    luna.log.debug("  incomplete: " .. name)
end

-- Human-readable oneliner for CI output
luna.log.info("validation summary: " .. report:getSummary())

-- Serialise to Lua table or JSON for external consumption
local report_table = report:toTable()
local report_json  = report:toJSON()
_ = report_table ; _ = report_json

-- ─────────────────────────────────────────────────────────────────────────────
-- SERIALISATION — export catalog for external tools
-- ─────────────────────────────────────────────────────────────────────────────

-- Export as Lua table (nested: modules → entries → fields)
local tbl = catalog:toTable()
luna.log.debug("catalog table key count: " .. #tbl)

-- Export as JSON string — useful for saving to disk or sending to a dashboard
local json = catalog:toJSON()
luna.log.debug("catalog JSON length: " .. #json)

-- ─────────────────────────────────────────────────────────────────────────────
-- GLOBAL CATALOG STATE
-- luna.docs maintains a process-lifetime catalog fed by all describe() /
-- setParamInfo() / setReturnInfo() calls.  getCatalog() returns a snapshot.
-- resetCatalog() clears all programmatic annotations (does NOT affect disk-loaded
-- catalogs; those must be re-loaded with loadToml / loadAll).
-- ─────────────────────────────────────────────────────────────────────────────

local global_catalog = luna.docs.getCatalog()
luna.log.info("global catalog entries: " .. global_catalog:entryCount())

luna.docs.resetCatalog()   -- wipes all programmatic annotations
local empty = luna.docs.getCatalog()
luna.log.debug("after reset: " .. empty:entryCount() .. " entries")  -- 0

-- ─────────────────────────────────────────────────────────────────────────────
-- COMPLETE QUALITY-GATE PATTERN
-- Use this block in a CI test or in-game dev overlay to surface gaps quickly.
-- ─────────────────────────────────────────────────────────────────────────────

do
    local c = luna.docs.scan({ include_internal = false })
    local total = c:entryCount()
    local undoc_count = c:filter(function(e) return not e:hasDescription() end):entryCount()
    local coverage = 1.0 - (undoc_count / math.max(1, total))

    luna.log.info(string.format(
        "doc coverage: %.1f%%  (%d / %d entries documented)",
        coverage * 100, total - undoc_count, total))

    if coverage < 0.8 then
        luna.log.warn("doc coverage below 80% — run 'python tools/docs/collect_docs.py --report-missing'")
    end
end

luna.log.info("[docs.lua] example complete")

-- ─────────────────────────────────────────────────────────────────────────────
-- SCHEMA VALIDATION — luna.docs.schema()
-- A lightweight runtime data-validator for game config, save-data, mod manifests.
-- Define field rules, then call schema:validate(data) to check any Lua table.
-- ─────────────────────────────────────────────────────────────────────────────

-- Build a schema from a rules table.
-- Each key is a field name; the value is a rule table.
local player_schema = luna.docs.schema({
    name  = { type = "string",  required = true, minLen = 2, maxLen = 32 },
    level = { type = "integer", required = true, min = 1, max = 100 },
    class = { type = "string",  required = true, enum = { "warrior", "mage", "rogue" } },
    coins = { type = "integer", min = 0 },
    alive = { type = "boolean" },
}, "PlayerData")

-- Valid data — passes all rules.
local ok, errors = player_schema:validate({
    name  = "Aiden",
    level = 7,
    class = "mage",
    coins = 250,
    alive = true,
})
assert(ok, "expected valid player data to pass")

-- Invalid data — several rule violations.
local bad_ok, bad_errors = player_schema:validate({
    name  = "X",        -- too short (minLen = 2)
    level = 150,        -- exceeds max 100
    class = "wizard",   -- not in enum
})
assert(not bad_ok, "expected invalid data to fail")
for _, e in ipairs(bad_errors) do
    -- Each error: { field = "...", message = "..." }
    luna.log.warn("validation error: " .. e.field .. " — " .. e.message)
end

-- schema:check() returns a plain boolean.
assert(not player_schema:check({ name = "ok", level = 999, class = "rogue" }))

-- schema:assert() throws a Lua error on failure — use in tests or loaders.
local success = pcall(function()
    player_schema:assert({ name = "", level = 5, class = "warrior" })
end)
assert(not success, "assert should throw on invalid data")

-- Inspect declared field names.
local fields = player_schema:getFields()
luna.log.info("schema fields: " .. table.concat(fields, ", "))

-- Shorthand: type-only rule using a string value.
local simple_schema = luna.docs.schema({
    health = "integer",
    label  = "string",
})
assert(simple_schema:check({ health = 100, label = "hero" }))

-- ─────────────────────────────────────────────────────────────────────────────
-- LIVE API REFLECTION — luna.docs.reflectLive()
-- Walks the live luna.* table and returns a structured description of every
-- registered namespace and its members. Useful for runtime IntelliSense, debug
-- overlays, or verifying that all expected APIs are loaded.
-- ─────────────────────────────────────────────────────────────────────────────

-- Reflect all namespaces.
local all_ns = luna.docs.reflectLive()
for ns_name, items in pairs(all_ns) do
    luna.log.debug(string.format("  ns=%s  members=%d", ns_name, #items))
end

-- Reflect just one namespace.
local math_ns = luna.docs.reflectLive("math")
for _, item in ipairs(math_ns.math or {}) do
    -- item: { name, type }
    luna.log.debug(string.format("    luna.math.%s  type=%s", item.name, item.type))
end

-- Count functions in luna.log.
local log_ns = luna.docs.reflectLive("log")
local fn_count = 0
for _, item in ipairs(log_ns.log or {}) do
    if item.type == "function" then fn_count = fn_count + 1 end
end
luna.log.info("luna.log exposes " .. tostring(fn_count) .. " functions")

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE REFLECTION — luna.docs.reflectTable()
-- Reflects any arbitrary Lua table (not just luna.*). Returns an array of
-- { name, qualifiedName, type } items.  Useful for mod manifests, save tables,
-- or debugging unknown data blobs.
-- ─────────────────────────────────────────────────────────────────────────────

local my_api = {
    greet   = function(name) return "Hello " .. name end,
    MAX_HP  = 100,
    version = "1.0",
    config  = { volume = 0.8 },
}

local reflection = luna.docs.reflectTable(my_api, "my_api")
for _, item in ipairs(reflection) do
    luna.log.debug(string.format("  %s : %s", item.qualifiedName, item.type))
end

luna.log.info("[docs.lua (schema+reflect)] complete")

-- ─────────────────────────────────────────────────────────────────────────────
-- SCHEMA VALIDATION — luna.docs.schema()
-- A lightweight runtime data-validator for game config, save-data, mod manifests.
-- Define field rules, then call schema:validate(data) to check any Lua table.
-- ─────────────────────────────────────────────────────────────────────────────

-- Build a schema from a rules table.
-- Each key is a field name; the value is a rule table.
local player_schema = luna.docs.schema({
    name  = { type = "string",  required = true, minLen = 2, maxLen = 32 },
    level = { type = "integer", required = true, min = 1, max = 100 },
    class = { type = "string",  required = true, enum = { "warrior", "mage", "rogue" } },
    coins = { type = "integer", min = 0 },
    alive = { type = "boolean" },
}, "PlayerData")

-- Valid data — passes all rules.
local ok, errors = player_schema:validate({
    name  = "Aiden",
    level = 7,
    class = "mage",
    coins = 250,
    alive = true,
})
assert(ok, "expected valid player data to pass")

-- Invalid data — several rule violations.
local bad_ok, bad_errors = player_schema:validate({
    name  = "X",        -- too short (minLen = 2)
    level = 150,        -- exceeds max 100
    class = "wizard",   -- not in enum
})
assert(not bad_ok, "expected invalid data to fail")
for _, e in ipairs(bad_errors) do
    -- Each error: { field = "...", message = "..." }
    luna.log.warn("validation error: " .. e.field .. " — " .. e.message)
end

-- schema:check() returns a plain boolean.
assert(not player_schema:check({ name = "ok", level = 999, class = "rogue" }))

-- schema:assert() throws a Lua error on failure — use in tests or loaders.
local success = pcall(function()
    player_schema:assert({ name = "", level = 5, class = "warrior" })
end)
assert(not success, "assert should throw on invalid data")

-- Inspect declared field names.
local fields = player_schema:getFields()
luna.log.info("schema fields: " .. table.concat(fields, ", "))

-- Shorthand: type-only rule using a string value.
local simple_schema = luna.docs.schema({
    health = "integer",
    label  = "string",
})
assert(simple_schema:check({ health = 100, label = "hero" }))

-- ─────────────────────────────────────────────────────────────────────────────
-- LIVE API REFLECTION — luna.docs.reflectLive()
-- Walks the live luna.* table and returns a structured description of every
-- registered namespace and its members. Useful for runtime IntelliSense, debug
-- overlays, or verifying that all expected APIs are loaded.
-- ─────────────────────────────────────────────────────────────────────────────

-- Reflect all namespaces.
local all_ns = luna.docs.reflectLive()
for ns_name, items in pairs(all_ns) do
    luna.log.debug(string.format("  ns=%s  members=%d", ns_name, #items))
end

-- Reflect just one namespace.
local math_ns = luna.docs.reflectLive("math")
for _, item in ipairs(math_ns.math or {}) do
    -- item: { name, type }
    luna.log.debug(string.format("    luna.math.%s  type=%s", item.name, item.type))
end

-- Count functions in luna.log.
local log_ns = luna.docs.reflectLive("log")
local fn_count = 0
for _, item in ipairs(log_ns.log or {}) do
    if item.type == "function" then fn_count = fn_count + 1 end
end
luna.log.info("luna.log exposes " .. tostring(fn_count) .. " functions")

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLE REFLECTION — luna.docs.reflectTable()
-- Reflects any arbitrary Lua table (not just luna.*). Returns an array of
-- { name, qualifiedName, type } items.  Useful for mod manifests, save tables,
-- or debugging unknown data blobs.
-- ─────────────────────────────────────────────────────────────────────────────

local my_api = {
    greet   = function(name) return "Hello " .. name end,
    MAX_HP  = 100,
    version = "1.0",
    config  = { volume = 0.8 },
}

local reflection = luna.docs.reflectTable(my_api, "my_api")
for _, item in ipairs(reflection) do
    luna.log.debug(string.format("  %s : %s", item.qualifiedName, item.type))
end

luna.log.info("[docs.lua (schema+reflect)] complete")

-- ─── QualityReport ─────────────────────────────────────────────────────────────

local best = qualityreport:getBest()  -- Returns up to count entries with the highest quality scores
local by_grade = qualityreport:getByGrade("A")        -- Returns entries whose grade exactly matcheshe given letter grade
local grade = qualityreport:getGrade()  -- Returns the letter grade for the overall score
local module_scores = qualityreport:getModuleScores()  -- Returns a table mapping module name to its average quality score
local overall_score = qualityreport:getOverallScore()  -- Returns the overall quality score in [0,1]
local worst = qualityreport:getWorst()  -- Returns up to count entries with the lowest quality scores

-- ─── luna.docs ─────────────────────────────────────────────────────────────────
local check_staleness = luna.docs.checkStaleness(ud, "graphics")  -- Compare catalog entries against source files in a directory for staleness
luna.docs.coverage()  -- Return (documented_count, total_live_count) coverage tuple
luna.docs.coverageModule("name")  -- Return (documented_count, total_live_count) for a single module
luna.docs.exportAll(ud, "docs/api/")  -- Export completions.json, hover.json, and signatures.jsonto a directory
luna.docs.exportCheatsheet(userdata, "path/to/file")  -- Export a one-line-per-function plain-text cheatsheet
luna.docs.exportCompletions(userdata, "path/to/file")  -- Export VS Code IntelliSense completions JSON to a file
luna.docs.exportHover(userdata, "path/to/file")  -- Export VS Code hover JSON to a file
luna.docs.exportMarkdown(userdata, "path/to/file")  -- Export a Markdown API reference file
luna.docs.exportSignatures(userdata, "path/to/file")  -- Export VS Code signature-help JSON to a file
luna.docs.quality()  -- Calculate quality metrics for a catalog or the internal catalog
luna.docs.qualityModule("name")  -- Calculate quality metrics for a single module
luna.docs.validateModule("name")  -- Validate a single module against the live luna.<module>.* bindings
